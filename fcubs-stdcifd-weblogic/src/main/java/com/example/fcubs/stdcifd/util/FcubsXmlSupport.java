package com.example.fcubs.stdcifd.util;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.ByteArrayInputStream;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;

public final class FcubsXmlSupport {
    private FcubsXmlSupport() { }

    public static ParsedRequest parse(String xml) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setXIncludeAware(false);
        factory.setExpandEntityReferences(false);
        factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
        factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");

        Document document = factory.newDocumentBuilder().parse(
            new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
        Element documentRoot = document.getDocumentElement();
        String rootName = localName(documentRoot);
        boolean soap = "Envelope".equals(rootName);
        String soapNamespace = soap ? documentRoot.getNamespaceURI() : null;
        Element fcubsRoot = documentRoot;

        if (soap) {
            if (!"http://schemas.xmlsoap.org/soap/envelope/".equals(soapNamespace) &&
                !"http://www.w3.org/2003/05/soap-envelope".equals(soapNamespace)) {
                throw new IllegalArgumentException("Only SOAP 1.1 and SOAP 1.2 envelopes are supported.");
            }
            Element body = findDirectChild(documentRoot, "Body");
            if (body == null) throw new IllegalArgumentException("SOAP Body element is missing.");
            fcubsRoot = firstElementChild(body);
            if (fcubsRoot == null) throw new IllegalArgumentException("SOAP Body contains no FCUBS request.");
        }

        Element header = findDirectChild(fcubsRoot, "FCUBS_HEADER");
        Element body = findDirectChild(fcubsRoot, "FCUBS_BODY");
        if (header == null || body == null) {
            throw new IllegalArgumentException("FCUBS_HEADER and FCUBS_BODY are required.");
        }

        String operation = text(header, "OPERATION");
        String pattern = messagePattern(localName(fcubsRoot));
        if (operation == null || operation.trim().isEmpty()) {
            throw new IllegalArgumentException("FCUBS_HEADER/OPERATION is required.");
        }
        Element customerBranchNode = findDescendant(body, "LBRN");
        String customerBranch = customerBranchNode == null ? null : customerBranchNode.getTextContent().trim();
        return new ParsedRequest(
            operation.trim(), pattern, localName(fcubsRoot), text(header, "SERVICE"), text(header, "FUNCTIONID"),
            text(header, "ACTION"), text(header, "USERID"), text(header, "BRANCH"),
            text(header, "MSGID"), text(header, "SOURCE"), customerBranch,
            serialize(fcubsRoot), soap, soapNamespace
        );
    }

    public static String text(Element parent, String name) {
        Element child = findDirectChild(parent, name);
        if (child == null) return null;
        String value = child.getTextContent();
        return value == null ? null : value.trim();
    }

    public static Element findDirectChild(Element parent, String name) {
        if (parent == null) return null;
        NodeList children = parent.getChildNodes();
        for (int i = 0; i < children.getLength(); i++) {
            Node node = children.item(i);
            if (node.getNodeType() == Node.ELEMENT_NODE && name.equals(localName(node))) {
                return (Element) node;
            }
        }
        return null;
    }

    public static Element findDescendant(Element parent, String name) {
        if (parent == null) return null;
        if (name.equals(localName(parent))) return parent;
        NodeList children = parent.getChildNodes();
        for (int i = 0; i < children.getLength(); i++) {
            Node child = children.item(i);
            if (child.getNodeType() == Node.ELEMENT_NODE) {
                Element found = findDescendant((Element) child, name);
                if (found != null) return found;
            }
        }
        return null;
    }

    public static String localName(Node node) {
        String name = node.getLocalName();
        if (name != null) return name;
        String qualified = node.getNodeName();
        int colon = qualified.indexOf(':');
        return colon >= 0 ? qualified.substring(colon + 1) : qualified;
    }

    private static Element firstElementChild(Element parent) {
        NodeList children = parent.getChildNodes();
        for (int i = 0; i < children.getLength(); i++) {
            Node node = children.item(i);
            if (node.getNodeType() == Node.ELEMENT_NODE) return (Element) node;
        }
        return null;
    }

    private static String messagePattern(String rootName) {
        if (rootName == null || !rootName.endsWith("_REQ")) return null;
        int last = rootName.lastIndexOf('_');
        if (last < 0) return null;
        String beforeReq = rootName.substring(0, last);
        int patternStart = beforeReq.lastIndexOf('_');
        return patternStart < 0 ? null : beforeReq.substring(patternStart + 1);
    }

    public static String serialize(Element element) throws Exception {
        TransformerFactory tf = TransformerFactory.newInstance();
        tf.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        try { tf.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, ""); } catch (IllegalArgumentException ignored) { }
        try { tf.setAttribute(XMLConstants.ACCESS_EXTERNAL_STYLESHEET, ""); } catch (IllegalArgumentException ignored) { }
        Transformer transformer = tf.newTransformer();
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
        transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        StringWriter writer = new StringWriter();
        transformer.transform(new DOMSource(element), new StreamResult(writer));
        return writer.toString();
    }

    public static final class ParsedRequest {
        public final String operation;
        public final String pattern;
        public final String rootName;
        public final String service;
        public final String functionId;
        public final String action;
        public final String userId;
        public final String branch;
        public final String messageId;
        public final String source;
        public final String customerBranch;
        public final String fcubsXml;
        public final boolean soapEnvelope;
        public final String soapNamespace;

        public ParsedRequest(String operation, String pattern, String rootName, String service, String functionId,
                             String action, String userId, String branch, String messageId,
                             String source, String customerBranch, String fcubsXml, boolean soapEnvelope, String soapNamespace) {
            this.operation = operation;
            this.pattern = pattern;
            this.rootName = rootName;
            this.service = service;
            this.functionId = functionId;
            this.action = action;
            this.userId = userId;
            this.branch = branch;
            this.messageId = messageId;
            this.source = source;
            this.customerBranch = customerBranch;
            this.fcubsXml = fcubsXml;
            this.soapEnvelope = soapEnvelope;
            this.soapNamespace = soapNamespace;
        }
    }
}
