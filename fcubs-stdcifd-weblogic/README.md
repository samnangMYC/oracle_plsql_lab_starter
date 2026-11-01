# STDCIFD WebLogic Clone Gateway

A clone-owned WebLogic WAR that serves the supplied FLEXCUBE-style customer UI and accepts FCUBS-style Customer XML. The application calls a clone-owned PL/SQL adapter (`STPKS_STDCIFD_WS`), which maps the supported XML fields into the training package `STPKS_STDCIFD_MAIN`.

> **Boundary:** This project is not Oracle FLEXCUBE source code, not the native `BranchServlet`, and not a replacement for Oracle's `FCUBSCustomerService` Gateway deployment. It is a training/clone WebLogic application using the supplied educational `STTM_*` schema and PL/SQL package. Do not deploy it into a production FLEXCUBE schema or use it to bypass native maintenance processing.

## 1. Runtime compatibility

The project uses `javax.*` Java EE APIs and Java 8 source compatibility. This is intended to be portable to WebLogic Server 12.2.1.4 and 14.1.1 installations when using a certified JDK for that WebLogic release. Oracle documents WebLogic 12.2.1.4 with JDK 8 and Servlet 3.1 support; WebLogic 14.1.1 supports JDK 8/11 and Servlet 4.0. Check your exact PSU and platform certification before deployment.

## 2. Architecture

```text
Browser UI (index.html / app.js / app.css)
        |
        | POST /api/fcubs/customer-soap (FCUBS operation XML)
        | or SOAP 1.1/1.2 POST /soap/STDCIFD
        v
CustomerSoapServlet (WebLogic Servlet)
        |
        | WebLogic authenticated principal + CIF role checks
        v
CustomerCifServiceBean (Stateless EJB, CMT)
        |
        | JNDI DataSource jdbc/FCUBSDS
        v
STPKS_STDCIFD_WS.PROCESS_REQUEST
        |
        v
STPKS_STDCIFD_MAIN
        |
        v
Training tables: STTM_CUSTOMER, STTM_CUST_PERSONAL,
STTM_CUST_CORPORATE, STTM_CUST_GROUP, etc.
```

The EJB uses container-managed transactions. The application does not call `commit()` directly; it marks a transaction rollback-only when the PL/SQL adapter reports a business failure.

## 3. Supported operations

| FCUBS operation | Expected action | Message pattern | Package operation |
|---|---|---|---|
| `CreateCustomer` | `NEW` | `FSFS` | `CREATE_CUSTOMER` |
| `ModifyCustomer` | `MODIFY` | `FSFS` | `AMEND_PENDING_CUSTOMER` |
| `QueryCustomer` | `QUERY` | `IOFS` | adapter query against training master/detail tables |
| `AuthorizeCustomer` | `AUTHORIZE` | `IOPK` | `AUTHORIZE_CUSTOMER` |

The request must identify `SERVICE=FCUBSCustomerService` and `FUNCTIONID=STDCIFD`. This is the clone's local dispatch convention. A standard FCUBS Gateway installation will not automatically register `STDCIFD` or these local table mappings.

## 4. Database installation

Run these scripts in a dedicated empty training/clone schema. The first script creates the tables and synthetic sample data:

1. Compile `database/00_training_customer_schema.sql` in a dedicated empty training schema. It is the educational DDL and synthetic seed data supplied for this clone.
2. Compile `database/STPKS_STDCIFD_MAIN-training.sql` (or use the already installed matching training package after comparing it first).
3. Compile `database/STPKS_STDCIFD_WS.sql`.
4. Check package status and errors:

```sql
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME IN ('STPKS_STDCIFD_MAIN', 'STPKS_STDCIFD_WS')
ORDER BY OBJECT_NAME, OBJECT_TYPE;

SELECT NAME, TYPE, LINE, POSITION, TEXT
FROM USER_ERRORS
WHERE NAME IN ('STPKS_STDCIFD_MAIN', 'STPKS_STDCIFD_WS')
ORDER BY NAME, TYPE, SEQUENCE;
```

The wrapper package must be created in the same schema as `STPKS_STDCIFD_MAIN` and the training `STTM_*` tables. It uses public record types from `STPKS_STDCIFD_MAIN` and delegates create/amend/authorize operations to that package.

## 5. WebLogic JDBC DataSource

Create an **XA Data Source** in the WebLogic Administration Console for the clone database. Configure:

- JNDI Name: `jdbc/FCUBSDS`
- Driver: Oracle XA Thin Driver (`oracle.jdbc.xa.client.OracleXADataSource`)
- Database URL: your clone database service URL
- Database user: the dedicated training schema owner (or a least-privilege application owner with `EXECUTE` on the packages and required table access)
- Target: the Managed Server or cluster where this WAR will run

Test the Data Source connection in the console before deploying. The EJB uses a container-managed transaction, so use an XA Data Source for proper transaction enlistment. Do not put database passwords in this project.

The `resource-ref` in `WEB-INF/web.xml` and `resource-description` in `WEB-INF/weblogic.xml` map the component name to `jdbc/FCUBSDS`.

## 6. WebLogic security roles

Create or map these application roles in the WebLogic security realm:

| Application role | Suggested realm group | Permission |
|---|---|---|
| `CIF_USER` | `cif_users` | Customer inquiry and access to screen |
| `CIF_MAKER` | `cif_makers` | Create and modify pending CIFs |
| `CIF_CHECKER` | `cif_checkers` | Authorize CIFs |

The sample `weblogic.xml` maps the roles to the suggested group names. Change these mappings to match your realm. Users who create records must be in `CIF_USER` and `CIF_MAKER`. Checkers must be in `CIF_USER` and `CIF_CHECKER`. Use different users for maker and checker; the PL/SQL package also checks this condition.

The example uses HTTP BASIC authentication and marks the API confidential. Use HTTPS. For an enterprise deployment, integrate your actual SSO/WebLogic identity provider and derive user/branch from the authenticated server context. Do not trust the XML `USERID` or `BRANCH` as the source of identity.

Branch resolution order:
1. Server session attribute `FCUBS_BRANCH` (set by your trusted SSO/session integration).
2. WebLogic JVM property `-Dfcubs.branch.<USERID>=<BRANCH>`.
3. WebLogic JVM property `-Dfcubs.defaultBranch=<BRANCH>`.
4. Training default `007`.

The client header's USERID and BRANCH must match the server-derived identity and branch. For create/modify, the `LBRN` field must also match the server branch.

## 7. Build the WAR

Use a JDK/Maven combination supported by your WebLogic installation. With Maven installed:

```bash
mvn clean package
```

Output:

```text
target/stdcifd-weblogic.war
```

This project uses Java 8 language/API compatibility and Java EE 7 `javax.*` APIs for compatibility with WebLogic 12.2.1.4. It should also run on WebLogic 14.1.1 when deployed with the matching supported configuration. Check your installed version and PSU before deployment.

## 8. Deploy

Deploy `target/stdcifd-weblogic.war` through WebLogic Administration Console:

1. Lock & Edit.
2. Deployments → Install.
3. Select the WAR.
4. Target the clone Managed Server/cluster.
5. Choose Install as an application.
6. Activate Changes.
7. Start the application and verify its state is Active.

Context root: `/stdcifd`.

### Optional WLST deployment

A deployment helper is included at `weblogic/wlst/deploy_stdcifd.py`. It expects the following environment variables to be set in the shell running WebLogic WLST: `WLS_ADMIN_URL`, `WLS_USER`, `WLS_PASSWORD`, `WLS_TARGET`, and `WAR_PATH`. `WLS_APP_NAME` is optional and defaults to `stdcifd-weblogic`. The script does not create a DataSource or security realm groups; configure those separately before deployment. Do not place passwords in the script or source control.

Example environment variable names (use your actual values):

```text
WLS_ADMIN_URL=t3s://weblogic-admin.example:9002
WLS_USER=deployment_operator
WLS_PASSWORD=<secret from your vault>
WLS_TARGET=ManagedServer1
WAR_PATH=/absolute/path/target/stdcifd-weblogic.war
```

Run the script with the WLST interpreter from the same WebLogic installation that hosts the target domain.

## 9. Endpoints

- UI: `https://<host>:<https-port>/stdcifd/`
- Session: `GET /stdcifd/api/fcubs/session`
- Browser XML proxy: `POST /stdcifd/api/fcubs/customer-soap`
- SOAP-over-HTTP endpoint: `POST /stdcifd/soap/STDCIFD`

The browser UI posts the FCUBS operation XML to the same-origin proxy route. The SOAP route accepts a SOAP 1.1 or 1.2 Envelope whose SOAP Body contains the FCUBS request document directly. It is a clone-specific SOAP-over-HTTP adapter, not an Oracle-generated WSDL service.

## 10. SOAP example

Use `samples/create-customer-soap11.xml` with a WebLogic SOAP client (replace `REPLACE_WITH_WEBLOGIC_USER`, and authenticate using a user in `CIF_USER` and `CIF_MAKER`). The SOAP endpoint is `/stdcifd/soap/STDCIFD`. The endpoint expects the FCUBS message to be a direct child of `soap:Body`, not a text/CDATA value.

The browser route accepts a raw `CREATECUSTOMER_FSFS_REQ`, `MODIFYCUSTOMER_FSFS_REQ`, `QUERYCUSTOMER_IOFS_REQ`, or `AUTHORIZECUSTOMER_IOPK_REQ` XML document and returns the corresponding FCUBS-style response document.

## 11. Field mapping limits

The SQL adapter maps the field tags generated by this clone UI to the supplied training package records. For individual customers it supports the tags used in `Custpersonal`. For corporate customers it supports the clone-specific `Custcorporate` block added to this UI. Those corporate tags are **not asserted to be native FCUBS XSD names**. Verify against the installed Customer XSD before registering this clone function in any native Gateway.

The training package supports customer types `I` and `C`; the UI's Bank type is not implemented by the supplied PL/SQL validation and must not be used until a bank-customer model is added.

## 12. Operational and security notes

- The servlet rejects DTD/entity declarations and uses secure XML parser settings.
- Request body limit is 1 MB.
- CSRF tokens are required for browser proxy POST requests.
- Server identity is taken from the WebLogic principal; XML USERID/BRANCH values are checked against trusted values.
- Maker/checker roles are checked by the WebLogic layer, and maker/checker inequality is checked again by the PL/SQL package.
- No CORS wildcard is enabled; host the UI and proxy same-origin.
- No production FLEXCUBE tables are modified by deployment. The PL/SQL wrapper is intended only for the clone training schema.

## 13. Validation status

The source files and XML descriptors are included for deployment. This environment does not have Maven, a WebLogic domain, or an Oracle database, so no WAR deployment, Oracle package compilation, or live SOAP/database test has been performed here. Run the database compilation checks and deploy/test in your actual clone environment.
