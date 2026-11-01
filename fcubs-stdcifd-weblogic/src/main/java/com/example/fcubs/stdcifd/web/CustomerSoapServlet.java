package com.example.fcubs.stdcifd.web;

import com.example.fcubs.stdcifd.ejb.CustomerCifServiceLocal;
import com.example.fcubs.stdcifd.model.GatewayResult;
import com.example.fcubs.stdcifd.util.FcubsXmlSupport;
import com.example.fcubs.stdcifd.util.FcubsXmlSupport.ParsedRequest;

import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Clone-owned WebLogic bridge. Accepts either a raw FCUBS-style Gateway XML
 * message at /api/fcubs/customer-soap or a SOAP 1.1/1.2 Envelope whose Body
 * contains that FCUBS message at /soap/STDCIFD.
 */
public class CustomerSoapServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(CustomerSoapServlet.class.getName());
    private static final String FCUBS_NS = "http://fcubs.ofss.com/service/FCUBSCustomerService";
    private static final int MAX_REQUEST_BYTES = 1024 * 1024;
    private static final String CSRF_ATTRIBUTE = "STDCIFD_CSRF_TOKEN";

    @EJB
    private CustomerCifServiceLocal customerService;

    private String expectedFunctionId;
    private String expectedService;

    @Override
    public void init() throws ServletException {
        expectedFunctionId = getServletConfig().getInitParameter("functionId");
        if (expectedFunctionId == null || expectedFunctionId.trim().isEmpty()) expectedFunctionId = "STDCIFD";
        expectedService = getServletConfig().getInitParameter("serviceName");
        if (expectedService == null || expectedService.trim().isEmpty()) expectedService = "FCUBSCustomerService";
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("X-Content-Type-Options", "nosniff");

        String path = request.getServletPath();
        boolean browserProxy = path != null && path.startsWith("/api/");
        if (!authenticate(request, response)) return;
        boolean browserInitiated = browserProxy || request.getHeader("Origin") != null;
        if (browserInitiated && !validCsrf(request)) {
            writePlain(response, HttpServletResponse.SC_FORBIDDEN, "CSRF token missing or invalid.");
            return;
        }

        String rawXml;
        try {
            rawXml = readLimited(request);
        } catch (IllegalArgumentException e) {
            writePlain(response, HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE, e.getMessage());
            return;
        }
        if (rawXml.trim().isEmpty()) {
            writePlain(response, HttpServletResponse.SC_BAD_REQUEST, "Request body is empty.");
            return;
        }
        if (rawXml.toUpperCase(Locale.ROOT).contains("<!DOCTYPE") ||
            rawXml.toUpperCase(Locale.ROOT).contains("<!ENTITY")) {
            writePlain(response, HttpServletResponse.SC_BAD_REQUEST, "DOCTYPE and ENTITY declarations are not accepted.");
            return;
        }

        try {
            ParsedRequest fcubs;
            try {
                fcubs = FcubsXmlSupport.parse(rawXml);
            } catch (Exception parseFailure) {
                throw new IllegalArgumentException("Malformed or unsafe FCUBS/SOAP XML request.", parseFailure);
            }
            if (path != null && path.startsWith("/soap/") && !fcubs.soapEnvelope) {
                throw new IllegalArgumentException("The /soap endpoint requires a SOAP Envelope.");
            }
            validateRequest(request, fcubs);
            String principal = request.getUserPrincipal().getName();
            String trustedBranch = branchFor(request, principal);
            GatewayResult result = customerService.process(fcubs.operation, fcubs.fcubsXml, principal, trustedBranch);
            String responseXml = buildFcubsResponse(fcubs, result, principal, trustedBranch);
            if (fcubs.soapEnvelope) {
                boolean soap12 = fcubs.soapNamespace != null && fcubs.soapNamespace.contains("2003/05/soap-envelope");
                response.setContentType((soap12 ? "application/soap+xml" : "text/xml") + "; charset=UTF-8");
                response.getWriter().write(wrapSoap(responseXml, fcubs.soapNamespace));
            } else {
                response.setContentType("application/xml; charset=UTF-8");
                response.getWriter().write(responseXml);
            }
        } catch (SecurityException e) {
            writePlain(response, HttpServletResponse.SC_FORBIDDEN, e.getMessage());
        } catch (IllegalArgumentException e) {
            writePlain(response, HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "STDCIFD WebLogic request processing failed", e);
            writePlain(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                "WebLogic gateway failed. Check server log for the correlation entry.");
        }
    }

    private boolean authenticate(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (request.getUserPrincipal() == null || !request.isUserInRole("CIF_USER")) {
            writePlain(response, HttpServletResponse.SC_UNAUTHORIZED, "Authenticated CIF_USER role is required.");
            return false;
        }
        String name = request.getUserPrincipal().getName();
        if (name == null || name.trim().isEmpty() || name.trim().length() > 12) {
            writePlain(response, HttpServletResponse.SC_FORBIDDEN,
                "The authenticated user ID must be 1 to 12 characters for this training schema.");
            return false;
        }
        return true;
    }

    private boolean validCsrf(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        String expected = (String) session.getAttribute(CSRF_ATTRIBUTE);
        String supplied = request.getHeader("X-CSRF-TOKEN");
        if (expected == null || supplied == null) return false;
        return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                                     supplied.getBytes(StandardCharsets.UTF_8));
    }

    private void validateRequest(HttpServletRequest request, ParsedRequest message) {
        if (!expectedService.equals(message.service)) {
            throw new IllegalArgumentException("Unsupported SERVICE. Expected " + expectedService + ".");
        }
        if (!expectedFunctionId.equals(message.functionId)) {
            throw new IllegalArgumentException("Unsupported FUNCTIONID. Expected " + expectedFunctionId + ".");
        }
        if (message.source != null && !"FLEXBRANCH".equalsIgnoreCase(message.source)) {
            throw new IllegalArgumentException("Unsupported SOURCE. Expected FLEXBRANCH.");
        }
        if (message.userId == null || message.userId.trim().isEmpty()) {
            throw new IllegalArgumentException("FCUBS_HEADER USERID is required.");
        }
        if (!message.userId.equalsIgnoreCase(request.getUserPrincipal().getName())) {
            throw new SecurityException("FCUBS_HEADER USERID does not match the authenticated WebLogic principal.");
        }
        String branch = SessionServlet.resolveBranch(request, request.getUserPrincipal().getName());
        if (message.branch == null || !message.branch.equals(branch)) {
            throw new SecurityException("FCUBS_HEADER BRANCH does not match the user's server-assigned branch.");
        }
        if ("CreateCustomer".equals(message.operation)) {
            requireAction(message, "NEW");
            requireRole(request, "CIF_MAKER");
            if (message.customerBranch != null && !branch.equals(message.customerBranch)) {
                throw new SecurityException("Customer local branch must match the user's assigned branch.");
            }
        } else if ("ModifyCustomer".equals(message.operation)) {
            requireAction(message, "MODIFY");
            requireRole(request, "CIF_MAKER");
            if (message.customerBranch != null && !branch.equals(message.customerBranch)) {
                throw new SecurityException("Customer local branch must match the user's assigned branch.");
            }
        } else if ("QueryCustomer".equals(message.operation)) {
            requireAction(message, "QUERY");
        } else if ("AuthorizeCustomer".equals(message.operation)) {
            requireAction(message, "AUTHORIZE");
            requireRole(request, "CIF_CHECKER");
        } else {
            throw new IllegalArgumentException("Unsupported Customer operation: " + message.operation);
        }

        String expectedRootPrefix = message.operation.toUpperCase(Locale.ROOT) + "_";
        String requestRoot = message.rootName;
        if (requestRoot == null || !requestRoot.startsWith(expectedRootPrefix) || !requestRoot.endsWith("_REQ")) {
            throw new IllegalArgumentException("Request XML root does not match FCUBS_HEADER/OPERATION.");
        }
        String expectedPattern;
        if ("QueryCustomer".equals(message.operation)) expectedPattern = "IOFS";
        else if ("AuthorizeCustomer".equals(message.operation)) expectedPattern = "IOPK";
        else expectedPattern = "FSFS";
        if (!expectedPattern.equals(message.pattern)) {
            throw new IllegalArgumentException("Unexpected message pattern. Expected " + expectedPattern + ".");
        }
    }

    private void requireAction(ParsedRequest request, String action) {
        if (!action.equalsIgnoreCase(request.action)) {
            throw new IllegalArgumentException("ACTION must be " + action + " for " + request.operation + ".");
        }
    }

    private void requireRole(HttpServletRequest request, String role) {
        if (!request.isUserInRole(role)) {
            throw new SecurityException("The authenticated user does not have the " + role + " role.");
        }
    }

    private String buildFcubsResponse(ParsedRequest request, GatewayResult result, String userId, String branch) {
        String responseRoot = request.operation.toUpperCase(Locale.ROOT) + "_" + request.pattern + "_RES";
        StringBuilder xml = new StringBuilder(2048);
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
           .append('<').append(responseRoot).append(" xmlns=\"").append(FCUBS_NS).append("\">")
           .append("<FCUBS_HEADER>")
           .append(tag("SOURCE", "FCUBS"))
           .append(tag("UBSCOMP", "FCUBS"))
           .append(tag("MSGID", request.messageId == null ? "" : request.messageId))
           .append(tag("USERID", userId))
           .append(tag("BRANCH", branch))
           .append(tag("SERVICE", expectedService))
           .append(tag("OPERATION", request.operation))
           .append(tag("FUNCTIONID", expectedFunctionId))
           .append(tag("ACTION", request.action))
           .append(tag("MSGSTAT", result.isSuccess() ? "SUCCESS" : "FAILURE"))
           .append("</FCUBS_HEADER><FCUBS_BODY>");
        if (result.isSuccess()) {
            String payload = result.getResponseBody();
            if (payload != null) xml.append(payload);
        } else {
            xml.append("<ERROR>")
               .append(tag("ECODE", result.getErrorCode() == null ? "-20000" : result.getErrorCode()))
               .append(tag("EDESC", result.getErrorMessage() == null ? "Customer operation failed." : result.getErrorMessage()))
               .append("</ERROR>");
        }
        xml.append("</FCUBS_BODY></").append(responseRoot).append('>');
        return xml.toString();
    }

    private String branchFor(HttpServletRequest request, String userId) {
        return SessionServlet.resolveBranch(request, userId);
    }

    private String wrapSoap(String responseXml, String namespace) {
        String ns = namespace;
        if (ns == null || ns.trim().isEmpty()) ns = "http://schemas.xmlsoap.org/soap/envelope/";
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<soap:Envelope xmlns:soap=\"" + ns + "\"><soap:Body>" +
            responseXml.replaceFirst("^<\\?xml[^>]*\\?>", "") +
            "</soap:Body></soap:Envelope>";
    }

    private String tag(String name, String value) {
        return "<" + name + ">" + escape(value) + "</" + name + ">";
    }

    private String escape(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&apos;");
    }

    private String readLimited(HttpServletRequest request) throws IOException {
        int contentLength = request.getContentLength();
        if (contentLength > MAX_REQUEST_BYTES) throw new IllegalArgumentException("Request exceeds 1 MB.");
        StringBuilder text = new StringBuilder(Math.max(256, Math.min(contentLength, 8192)));
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(request.getInputStream(), StandardCharsets.UTF_8))) {
            char[] buffer = new char[4096];
            int read;
            int total = 0;
            while ((read = reader.read(buffer)) != -1) {
                total += read;
                if (total > MAX_REQUEST_BYTES) throw new IllegalArgumentException("Request exceeds 1 MB.");
                text.append(buffer, 0, read);
            }
        }
        return text.toString();
    }

    private void writePlain(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("text/plain; charset=UTF-8");
        response.getWriter().write(message == null ? "Request failed." : message);
    }
}
