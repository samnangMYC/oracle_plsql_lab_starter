# FCUBS Customer Service mapping notes

## Documented service setup example in ODT/MICON

- Function ID: `STDCIF`
- Function Category: `Maintenance`
- XSD Type Identifier: `Customer`
- Service Name: `FCUBSCustomerService`
- Operation Id: `Customer`
- QUERY -> `QueryCustomer`
- NEW -> `CreateCustomer`
- MODIFY -> `ModifyCustomer`
- AUTHORIZE -> `AuthorizeCustomer`

## Function ID selection

- `STDCIF` is the documented built-in Customer Maintenance Function ID.
- `STDCIFD` is the clone Function ID used in this training project. Its service/gateway mapping and XSD are not automatically inherited from `STDCIF`.

## Exchange patterns used by this UI

| Operation | Request/response pattern | Request element |
|---|---|---|
| CreateCustomer | FSFS | `CREATECUSTOMER_FSFS_REQ` |
| ModifyCustomer | FSFS | `MODIFYCUSTOMER_FSFS_REQ` |
| QueryCustomer | IOFS | `QUERYCUSTOMER_IOFS_REQ` |
| AuthorizeCustomer | IOPK | `AUTHORIZECUSTOMER_IOPK_REQ` |

The selected message patterns are based on the Gateway guide's published message-pattern definitions and on the operation's supported full/input-only request modes. Verify generated request XSD names and schemas from the installed WSDL/XSD before using in a live environment.

## Important: FCUBS XML vs SOAP wire envelope

The XML preview is the FCUBS Gateway message (the operation-specific XML document carrying `FCUBS_HEADER` and `FCUBS_BODY`). A SOAP 1.1/1.2 envelope, service operation wrapper, SOAPAction, endpoint path and authentication are generated/handled by the WSDL-bound server-side SOAP client/proxy. They are not guessed in this browser code.
