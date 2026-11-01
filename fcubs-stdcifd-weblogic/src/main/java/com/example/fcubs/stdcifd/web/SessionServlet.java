package com.example.fcubs.stdcifd.web;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.security.SecureRandom;
import java.util.Base64;

public class SessionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final String CSRF_ATTRIBUTE = "STDCIFD_CSRF_TOKEN";
    private final SecureRandom secureRandom = new SecureRandom();
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        if (request.getUserPrincipal() == null || !request.isUserInRole("CIF_USER")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Authentication required\"}");
            return;
        }

        String userId = request.getUserPrincipal().getName();
        String branch = resolveBranch(request, userId);
        HttpSession session = request.getSession(true);
        String csrf = (String) session.getAttribute(CSRF_ATTRIBUTE);
        if (csrf == null) {
            byte[] bytes = new byte[32];
            secureRandom.nextBytes(bytes);
            csrf = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
            session.setAttribute(CSRF_ATTRIBUTE, csrf);
        }

        String json = "{\"userId\":\"" + jsonEscape(userId) +
            "\",\"branchCode\":\"" + jsonEscape(branch) +
            "\",\"csrfToken\":\"" + jsonEscape(csrf) +
            "\",\"maker\":" + request.isUserInRole("CIF_MAKER") +
            ",\"checker\":" + request.isUserInRole("CIF_CHECKER") + "}";
        response.getWriter().write(json);
    }

    static String resolveBranch(HttpServletRequest request, String userId) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            Object branch = session.getAttribute("FCUBS_BRANCH");
            if (branch != null && !branch.toString().trim().isEmpty()) return branch.toString().trim();
        }
        String configured = System.getProperty("fcubs.branch." + userId);
        if (configured != null && !configured.trim().isEmpty()) return configured.trim();
        String fallback = System.getProperty("fcubs.defaultBranch");
        if (fallback != null && !fallback.trim().isEmpty()) return fallback.trim();
        return "007";
    }

    private String jsonEscape(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
            .replace("\r", "\\r").replace("\n", "\\n");
    }
}
