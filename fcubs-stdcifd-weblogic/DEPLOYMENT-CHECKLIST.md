# WebLogic deployment checklist

- [ ] Dedicated clone schema created from the supplied training DDL.
- [ ] `STPKS_STDCIFD_MAIN` specification and body compile VALID.
- [ ] `STPKS_STDCIFD_WS` specification and body compile VALID.
- [ ] `jdbc/FCUBSDS` XA Data Source created, targeted, and connection-tested.
- [ ] WebLogic groups mapped to `CIF_USER`, `CIF_MAKER`, and `CIF_CHECKER`.
- [ ] At least one maker and one different checker test account created.
- [ ] Branch mapping configured for each test user (default `007` only for lab).
- [ ] WAR built with a supported JDK/Maven.
- [ ] WAR deployed to the clone Managed Server over HTTPS.
- [ ] `GET /stdcifd/api/fcubs/session` returns authenticated user, branch, and CSRF token.
- [ ] Create customer tested using SOAP sample / browser UI.
- [ ] Query customer tested from the same branch.
- [ ] Maker cannot authorize own CIF.
- [ ] Different checker can authorize CIF.
- [ ] Query from a different branch is rejected.
- [ ] Unauthorized user cannot call the service.

Do not move to production or a native FLEXCUBE schema with this training adapter.
