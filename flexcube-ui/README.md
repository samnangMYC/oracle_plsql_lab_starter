# FLEXCUBE-style Customer Maintenance UI + FCUBS Customer Gateway XML

This is a **clone-owned UI implementation** based on the Customer screen screenshot supplied in the conversation. It reproduces the visible layout patterns (title bar, mode label, customer header, tabs, 3-column personal screen, audit footer, subsystem strip) and provides a request console for FCUBS Gateway Customer messages.

It is not Oracle's licensed native RAD XML, JavaScript bundle, WebLogic deployment unit, or exact STDCIF source. The final native screen still must be generated/deployed with the installed FLEXCUBE 14.1 ODT/RAD toolset.

## Run the UI locally

```bash
python -m http.server 8080
```

Open `http://localhost:8080`.

The screen starts in preview mode. It will generate XML locally. The **Send to FCUBS proxy** button posts the request XML to the configured same-origin proxy URL (default `/api/fcubs/customer-soap`). No database or WebLogic credentials are stored in the browser.

## Actual Customer Gateway mapping (confirm in your installation)

The documented Customer service name is `FCUBSCustomerService`. The documented customer operations are:

| UI action | FCUBS operation | Gateway action |
|---|---|---|
| Query | `QueryCustomer` | `QUERY` |
| New | `CreateCustomer` | `NEW` |
| Modify | `ModifyCustomer` | `MODIFY` |
| Authorize | `AuthorizeCustomer` | `AUTHORIZE` |

ODT/MICON documentation shows Function ID `STDCIF`, XSD Type Identifier `Customer`, Service Name `FCUBSCustomerService`, Operation Id `Customer`, with action-to-operation mapping including QUERY/QueryCustomer, NEW/CreateCustomer, MODIFY/ModifyCustomer, AUTHORIZE/AuthorizeCustomer.

The Gateway guide defines operation message roots using `<OPERATION>_<PATTERN>_REQ|RES`. Common patterns include `FSFS` (full-screen request/full-screen response), `IOFS` (input-only request/full-screen response) and `IOPK` (input-only request/primary-key response). The UI therefore builds:

- `CREATECUSTOMER_FSFS_REQ`
- `MODIFYCUSTOMER_FSFS_REQ`
- `QUERYCUSTOMER_IOFS_REQ`
- `AUTHORIZECUSTOMER_IOPK_REQ`

The XML contains `FCUBS_HEADER` and `FCUBS_BODY`. The browser sends the FCUBS operation payload to a server-side adapter. The installed WSDL determines the actual SOAP binding/wrapper/action used on the network; do not invent the SOAPAction or URL.

## STDCIF vs STDCIFD

The screenshot shows the standard Customer Maintenance experience (`STDCIF`). This UI defaults to `STDCIFD` because our clone work has used that new Function ID. **STDCIFD must be registered against `FCUBSCustomerService` and its operations in your Gateway/Service XML configuration before a request using that Function ID can succeed.** If you are testing the stock installation without a clone mapping, select `STDCIF` in the message console.

For ODT Service XML, attach the correct Function ID and confirm the service's generated XSD/WSDL. The Function ID must be maintained in the function/service mapping and the physical RAD XML must exist.

## Payload mapping included

The request builder uses field tags visible in the published Customer Gateway sample, including:

- Master: `CUSTNO`, `CTYPE`, `FULLNAME`, `SNAME`, `LBRN`, `CCATEG`, `ADDRLN1`-`ADDRLN3`, `COUNTRY`, `NLTY`, `IDTYPE`, `IDNUMBER`, `FROZEN`, `DEAD`, `WHRUNKN`, `PRIVATE_CUSTOMER`.
- Individual node `Custpersonal`: `FSTNAME`, `LSTNAME`, `DOB`, `GENDR`, `NATIONID`, `RESSTATUS`, `MOBNUM`, `LANG`, `BIRTHCOUNTRY`, `PLACEOFBIRTH`, `MOBISDNO`.

Some fields visible in the UI (passport details, email, corporate attributes, auxiliary/director/checklist and subsystem tabs) are not emitted until their exact field tags and nesting are checked against the deployed Customer XSD. This avoids sending invented element names to the bank service.

## Proxy contract

The UI sends:

```http
POST /api/fcubs/customer-soap
Content-Type: application/xml; charset=UTF-8
Accept: application/xml, text/xml
```

Body: the XML shown in the message console.

The server-side proxy must:

1. Authenticate the current user and derive `USERID`/`BRANCH` from the server session (the demo header fields are for local test only).
2. Validate that `SERVICE`, `OPERATION`, `FUNCTIONID` and `ACTION` are allowed for that user.
3. Invoke the installed WSDL-generated `FCUBSCustomerService` SOAP client/port using the deployed WSDL binding.
4. Pass the FCUBS operation XML as defined by the XSD; the proxy must build the real SOAP wrapper and SOAPAction from the WSDL, not from a guessed string.
5. Return the FCUBS response XML to the browser.
6. Keep credentials, service URL, TLS trust, session and audit logging on the server.

Optional session endpoint: `GET /api/fcubs/session` returning `{ "userId": "...", "branchCode": "...", "csrfToken": "..." }`.

## Important integration boundary

This Gateway Web Service flow is distinct from the native FLEXCUBE browser's internal `BranchServlet` message route. The internal client uses its own FCUBS request envelope/action/event contract. Do not send a Gateway `CREATECUSTOMER_FSFS_REQ` payload to BranchServlet unless your installation's route explicitly expects it. Likewise, do not send an internal `FCUBS_REQ_ENV` to the generated Customer Gateway SOAP WSDL unless that WSDL defines it.

## Validation performed

- JavaScript syntax checked with Node when available.
- XML templates parsed for well-formedness.
- UI can be served locally and request XML can be previewed without a live FCUBS endpoint.

No connection to your WebLogic/FCUBS instance has been performed. Validate exact namespaces, XSD fields, message patterns, source registration, branch/user permissions, and service URL against your installed 14.1 WSDL/XSD and configuration.
