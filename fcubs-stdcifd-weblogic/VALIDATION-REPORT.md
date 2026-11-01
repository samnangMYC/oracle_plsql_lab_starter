# Static validation report

Checks performed in the build container:

- Java source syntax compiled with `javac --release 8`, Servlet API 3.1, and temporary Java EE annotation/interface stubs: **PASS**. This validates Java syntax only; it is not a replacement for compiling against the exact WebLogic Java EE libraries.
- Browser JavaScript `node --check`: **PASS**.
- Maven XML, WebLogic descriptors, and sample SOAP/XML files parsed: **PASS**.
- FCUBS request parsing exercised for create, query, and authorize samples: **PASS**.
- Mapping references checked against the public record fields in the included training `STPKS_STDCIFD_MAIN` package: **PASS** (28 customer, 50 personal, and 17 corporate fields referenced; no unknown record fields).

Not performed because this environment does not contain Maven, Oracle Database/SQL*Plus, or a WebLogic domain:

- Maven WAR build.
- Oracle PL/SQL compilation or runtime test.
- WebLogic deployment, JNDI lookup, EJB transaction test, or live SOAP/database test.

The project is a **clone-owned training WebLogic application**, not Oracle-delivered FLEXCUBE source, BranchServlet, or a native FCUBS WSDL deployment. Install only into a dedicated training schema matching the included training DDL and package.
