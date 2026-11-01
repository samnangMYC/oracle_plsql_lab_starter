/*
 * Clone-owned FLEXCUBE-style STDCIF client.
 * Builds FCUBS Customer Gateway XML requests. It does not call Oracle from the browser.
 * All outbound calls go through a same-origin server-side SOAP/WSDL proxy.
 *
 * Confirm every field against the installed service XSD before production use.
 */
(() => {
  'use strict';

  const NS = 'http://fcubs.ofss.com/service/FCUBSCustomerService';
  const SERVICE = 'FCUBSCustomerService';
  const APP_BASE = new URL('.', window.location.href).pathname;
  const PROXY_DEFAULT = `${APP_BASE}api/fcubs/customer-soap`;
  const $ = (id) => document.getElementById(id);
  const get = (id) => $(id)?.value?.trim() ?? '';
  const set = (id, value) => { if ($(id) && value !== undefined && value !== null) $(id).value = String(value); };
  const check = (id) => Boolean($(id)?.checked);
  const pad = (value, length = 2) => String(value).padStart(length, '0');
  const xmlDoc = document.implementation.createDocument(NS, 'root', null);
  let currentMode = 'NEW';
  let lastRequest = '';
  let lastResponse = '';
  let sessionContext = null;

  const ACTIONS = {
    QUERY: { operation: 'QueryCustomer', action: 'QUERY', pattern: 'IOFS', body: 'Customer-IO' },
    NEW: { operation: 'CreateCustomer', action: 'NEW', pattern: 'FSFS', body: 'Customer-Full' },
    MODIFY: { operation: 'ModifyCustomer', action: 'MODIFY', pattern: 'FSFS', body: 'Customer-Full' },
    AUTHORIZE: { operation: 'AuthorizeCustomer', action: 'AUTHORIZE', pattern: 'IOPK', body: 'Customer-IO' }
  };

  function toast(message, isError = false) {
    const el = $('toast');
    el.textContent = message;
    el.style.background = isError ? '#8b2635' : '#264e7d';
    el.classList.add('show');
    window.clearTimeout(toast.timer);
    toast.timer = window.setTimeout(() => el.classList.remove('show'), 4200);
  }

  function escapeXml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }

  function addNode(doc, parent, name, value) {
    if (value === null || value === undefined || String(value).trim() === '') return;
    const node = doc.createElementNS(NS, name);
    node.appendChild(doc.createTextNode(String(value).trim()));
    parent.appendChild(node);
    return node;
  }

  function id() {
    if (window.crypto?.randomUUID) return `CIF${window.crypto.randomUUID().replaceAll('-', '').slice(0, 22).toUpperCase()}`;
    return `CIF${Date.now()}${Math.floor(Math.random() * 100000)}`;
  }

  function customerType() {
    return document.querySelector('input[name="customerType"]:checked')?.value || 'I';
  }

  function collectMaster() {
    return {
      customerNo: get('customerNo'), customerType: customerType(),
      fullName: get('fullName'), shortName: get('shortName'), branchCode: get('branchCode'),
      customerCategory: get('customerCategory'), privateCustomer: check('privateCustomer') ? 'Y' : 'N',
      addressLine1: get('addressLine1'), addressLine2: get('addressLine2'), addressLine3: get('addressLine3'), addressLine4: get('addressLine4'),
      country: get('country'), pincode: get('pincode'), shortName2: '', nationality: get('nationality'),
      language: get('language'), custGroup: get('custGroup'), custClassification: get('custClassification'),
      accessGroup: get('accessGroup'), kycDetails: get('kycDetails'), kycRefNo: get('kycRefNo'), cifStatus: get('cifStatus'),
      uniqueIdName: get('uniqueIdName'), uniqueIdValue: get('uniqueIdValue'),
      frozen: get('frozen'), deceased: get('deceased'), whereaboutsUnknown: get('whereaboutsUnknown')
    };
  }

  function collectPersonal() {
    return {
      prefix1: get('customerPrefix'), prefix2: get('customerPrefix1'), prefix3: get('customerPrefix2'),
      firstName: get('firstName'), middleName: get('middleName'), lastName: get('lastName'),
      sex: get('sex'), dateOfBirth: get('dateOfBirth'), birthCountry: get('birthCountry'),
      placeOfBirth: get('placeOfBirth'), nationalId: get('pNationalId'), residentStatus: 'R',
      mobileNumber: get('mobileNumber'), mobileIsd: get('mobIsdNo'), language: get('language'),
      passportNo: get('passportNo'), passportIssueDate: get('passportIssueDate'), passportExpiryDate: get('passportExpiryDate'),
      telephone: get('telephone'), workPhoneIsd: get('telIsdNo'), homeTelNo: get('homeTelNo'), homeTelIsd: get('homeTelIsd'),
      fax: get('fax'), faxIsd: get('faxIsdNo'), email: get('eMail'), guardian: get('legalGuardian'), minor: get('minor'),
      dAddress1: get('addressLine1'), dAddress2: get('addressLine2'), dAddress3: get('addressLine3'), dAddress4: get('addressLine4'),
      dCountry: get('country'), dPincode: get('pincode'),
      pAddress1: get('pAddress1'), pAddress2: get('pAddress2'), pAddress3: get('pAddress3'), pAddress4: get('pAddress4'),
      pCountry: get('pCountry'), pPincode: get('pPincode')
    };
  }

  function collectCorporate() {
    return {
      companyType: get('companyType'), businessNature: get('businessNature'), groupName: get('groupName'),
      employeeNumber: get('employeeNumber'), annualTurnover: get('annualTurnover'),
      parentCompanyCountry: get('parentCmpnyCountry'), otherCompanyType: get('otherCompanyType'),
      incorporationNo: get('incorporationNo'), incorporationDate: get('incorporationDate'),
      incorporationCountry: get('incorporationCountry'), registeredAddress1: get('registeredAddress1'),
      registeredAddress2: get('registeredAddress2'), registeredAddress3: get('registeredAddress3'),
      registeredAddress4: get('registeredAddress4'), kycComments: get('corporateKycComments'),
      kycNextReviewDate: get('corpKycNextReviewDate')
    };
  }

  function validate(mode) {
    const m = collectMaster();
    const p = collectPersonal();
    const errors = [];
    document.querySelectorAll('.invalid').forEach((el) => el.classList.remove('invalid'));
    const required = (id, label) => {
      if (!get(id)) { errors.push(`${label} is required.`); $(id)?.classList.add('invalid'); }
    };
    if (mode === 'QUERY' || mode === 'AUTHORIZE') required('customerNo', 'Customer number');
    if (mode === 'NEW' || mode === 'MODIFY') {
      required('customerNo', 'Customer number');
      required('fullName', 'Full name');
      required('shortName', 'Short name');
      required('branchCode', 'Branch code');
      required('customerCategory', 'Customer category');
      required('addressLine1', 'Correspondence address 1');
      required('country', 'Country');
      if (!['I', 'C'].includes(m.customerType)) errors.push('This training package supports Individual or Corporate customers only.');
      if (m.customerNo.length > 9) { errors.push('Customer number cannot exceed 9 characters.'); $('customerNo').classList.add('invalid'); }
      if (m.customerType === 'I' && p.dateOfBirth && p.dateOfBirth > new Date().toISOString().slice(0, 10)) {
        errors.push('Date of birth cannot be in the future.'); $('dateOfBirth').classList.add('invalid');
      }
      if (p.passportIssueDate && p.passportExpiryDate && p.passportExpiryDate < p.passportIssueDate) {
        errors.push('Passport expiry date cannot precede issue date.'); $('passportExpiryDate').classList.add('invalid');
      }
      if (!!m.uniqueIdName !== !!m.uniqueIdValue) errors.push('Unique ID type and value must both be supplied.');
      if (m.customerType === 'C' && !get('companyType')) errors.push('Company type is required for a corporate customer.');
    }
    return errors;
  }

  function xmlTextNode(name, value, parent, doc) {
    return addNode(doc, parent, name, value);
  }

  function buildCustomerPayload(doc, root, mode) {
    const m = collectMaster();
    const p = collectPersonal();
    const bodyNode = doc.createElementNS(NS, 'FCUBS_BODY');
    root.appendChild(bodyNode);
    const record = doc.createElementNS(NS, ACTIONS[mode].body);
    bodyNode.appendChild(record);

    // Master node fields confirmed by a published FCUBS CustomerService CreateCustomer example.
    // The deployed XSD for your exact 14.1 patch remains the final authority.
    xmlTextNode('PRIVATE_CUSTOMER', m.privateCustomer, record, doc);
    xmlTextNode('CUSTNO', m.customerNo, record, doc);
    xmlTextNode('CTYPE', m.customerType, record, doc);
    xmlTextNode('FULLNAME', m.fullName, record, doc);
    xmlTextNode('SNAME', m.shortName, record, doc);
    xmlTextNode('LBRN', m.branchCode, record, doc);
    xmlTextNode('CCATEG', m.customerCategory, record, doc);
    xmlTextNode('ADDRLN1', m.addressLine1, record, doc);
    xmlTextNode('ADDRLN2', m.addressLine2, record, doc);
    xmlTextNode('ADDRLN3', m.addressLine3, record, doc);
    xmlTextNode('ADDRLN4', m.addressLine4, record, doc);
    xmlTextNode('COUNTRY', m.country, record, doc);
    xmlTextNode('NLTY', m.nationality, record, doc);
    xmlTextNode('PINCODE', m.pincode, record, doc);
    xmlTextNode('CUSTGROUP', m.custGroup, record, doc);
    xmlTextNode('CUSTCLASS', m.custClassification, record, doc);
    xmlTextNode('ACCESSGROUP', m.accessGroup, record, doc);
    xmlTextNode('KYCDTLS', m.kycDetails, record, doc);
    xmlTextNode('KYCREFNO', m.kycRefNo, record, doc);
    xmlTextNode('CIFSTATUS', m.cifStatus, record, doc);
    xmlTextNode('IDTYPE', m.uniqueIdName, record, doc);
    xmlTextNode('IDNUMBER', m.uniqueIdValue, record, doc);
    xmlTextNode('FROZEN', m.frozen || 'N', record, doc);
    xmlTextNode('DEAD', m.deceased || 'N', record, doc);
    xmlTextNode('WHRUNKN', m.whereaboutsUnknown || 'N', record, doc);

    if (mode !== 'QUERY' && mode !== 'AUTHORIZE' && m.customerType === 'I') {
      const personal = doc.createElementNS(NS, 'Custpersonal');
      record.appendChild(personal);
      // Gateway-style tags supported by this clone's STPKS_STDCIFD_WS adapter.
      xmlTextNode('FSTNAME', p.firstName, personal, doc);
      xmlTextNode('MIDNAME', p.middleName, personal, doc);
      xmlTextNode('LSTNAME', p.lastName, personal, doc);
      xmlTextNode('DOB', p.dateOfBirth, personal, doc);
      xmlTextNode('GENDR', p.sex, personal, doc);
      xmlTextNode('NATIONID', p.nationalId, personal, doc);
      xmlTextNode('RESSTATUS', p.residentStatus, personal, doc);
      xmlTextNode('MOBNUM', p.mobileNumber, personal, doc);
      xmlTextNode('LANG', p.language, personal, doc);
      xmlTextNode('BIRTHCOUNTRY', p.birthCountry, personal, doc);
      xmlTextNode('PLACEOFBIRTH', p.placeOfBirth, personal, doc);
      xmlTextNode('MOBISDNO', p.mobileIsd, personal, doc);
      xmlTextNode('PASSPORTNO', p.passportNo, personal, doc);
      xmlTextNode('PPTISSDATE', p.passportIssueDate, personal, doc);
      xmlTextNode('PPTEXPDATE', p.passportExpiryDate, personal, doc);
      xmlTextNode('EMAIL', p.email, personal, doc);
      xmlTextNode('WORKPHONE', p.telephone, personal, doc);
      xmlTextNode('WORKPHONEISD', p.workPhoneIsd, personal, doc);
      xmlTextNode('HOMETELNO', p.homeTelNo, personal, doc);
      xmlTextNode('HOMETELISD', p.homeTelIsd, personal, doc);
      xmlTextNode('FAXNO', p.fax, personal, doc);
      xmlTextNode('FAXISD', p.faxIsd, personal, doc);
      xmlTextNode('GUARDIAN', p.guardian, personal, doc);
      xmlTextNode('MINOR', p.minor, personal, doc);
      xmlTextNode('DADDR1', p.dAddress1, personal, doc);
      xmlTextNode('DADDR2', p.dAddress2, personal, doc);
      xmlTextNode('DADDR3', p.dAddress3, personal, doc);
      xmlTextNode('DADDR4', p.dAddress4, personal, doc);
      xmlTextNode('DCOUNTRY', p.dCountry, personal, doc);
      xmlTextNode('DPINCODE', p.dPincode, personal, doc);
      xmlTextNode('PADDR1', p.pAddress1, personal, doc);
      xmlTextNode('PADDR2', p.pAddress2, personal, doc);
      xmlTextNode('PADDR3', p.pAddress3, personal, doc);
      xmlTextNode('PADDR4', p.pAddress4, personal, doc);
      xmlTextNode('PCOUNTRY', p.pCountry, personal, doc);
      xmlTextNode('PPINCODE', p.pPincode, personal, doc);
    }

    if (mode !== 'QUERY' && mode !== 'AUTHORIZE' && m.customerType === 'C') {
      const c = collectCorporate();
      const corporate = doc.createElementNS(NS, 'Custcorporate');
      record.appendChild(corporate);
      // Clone-owned mapping to STTM_CUST_CORPORATE. Confirm against a deployed XSD
      // before registering this custom function with a native FCUBS Gateway.
      xmlTextNode('COMPANYTYPE', c.companyType, corporate, doc);
      xmlTextNode('BUSINESSNATURE', c.businessNature, corporate, doc);
      xmlTextNode('GROUPNAME', c.groupName, corporate, doc);
      xmlTextNode('EMPLOYEENUMBER', c.employeeNumber, corporate, doc);
      xmlTextNode('ANNUALTURNOVER', c.annualTurnover, corporate, doc);
      xmlTextNode('PARENTCMPNYCOUNTRY', c.parentCompanyCountry, corporate, doc);
      xmlTextNode('OTHERCOMPANYTYPE', c.otherCompanyType, corporate, doc);
      xmlTextNode('INCORPORATIONNO', c.incorporationNo, corporate, doc);
      xmlTextNode('INCORPORATIONDATE', c.incorporationDate, corporate, doc);
      xmlTextNode('INCORPORATIONCOUNTRY', c.incorporationCountry, corporate, doc);
      xmlTextNode('REGISTEREDADDRESS1', c.registeredAddress1, corporate, doc);
      xmlTextNode('REGISTEREDADDRESS2', c.registeredAddress2, corporate, doc);
      xmlTextNode('REGISTEREDADDRESS3', c.registeredAddress3, corporate, doc);
      xmlTextNode('REGISTEREDADDRESS4', c.registeredAddress4, corporate, doc);
      xmlTextNode('KYCCOMMENTS', c.kycComments, corporate, doc);
      xmlTextNode('KYCNEXTREVIEWDATE', c.kycNextReviewDate, corporate, doc);
    }

    return bodyNode;
  }

  function buildRequest(mode) {
    if (!ACTIONS[mode]) throw new Error(`Unsupported action ${mode}`);
    const doc = document.implementation.createDocument(NS, `${ACTIONS[mode].operation.toUpperCase()}_${ACTIONS[mode].pattern}_REQ`, null);
    const root = doc.documentElement;

    const header = doc.createElementNS(NS, 'FCUBS_HEADER');
    root.appendChild(header);
    const functionId = get('functionId') || 'STDCIFD';
    const userId = (get('gatewayUser') || sessionContext?.userId || '').trim();
    const branch = (get('gatewayBranch') || sessionContext?.branchCode || '').trim();
    const source = get('sourceSystem') || 'FLEXBRANCH';

    if (!userId) throw new Error('Gateway User ID is required. Configure the authenticated gateway session.');
    if (!branch) throw new Error('Gateway Branch is required.');

    const headerValues = [
      ['SOURCE', source], ['UBSCOMP', 'FCUBS'], ['MSGID', id()],
      ['USERID', userId], ['BRANCH', branch], ['MODULEID', 'ST'],
      ['SERVICE', SERVICE], ['OPERATION', ACTIONS[mode].operation],
      ['DESTINATION', 'FCUBS'], ['FUNCTIONID', functionId], ['ACTION', ACTIONS[mode].action]
    ];
    headerValues.forEach(([name, value]) => addNode(doc, header, name, value));

    if (mode === 'QUERY' || mode === 'AUTHORIZE') {
      const body = doc.createElementNS(NS, 'FCUBS_BODY');
      root.appendChild(body);
      const record = doc.createElementNS(NS, ACTIONS[mode].body);
      body.appendChild(record);
      addNode(doc, record, 'CUSTNO', get('customerNo'));
      if (mode === 'AUTHORIZE') addNode(doc, record, 'FUNCTIONID', functionId);
    } else {
      buildCustomerPayload(doc, root, mode);
    }

    return new XMLSerializer().serializeToString(doc).replace(/></g, '>\n<');
  }

  function setState(mode, note) {
    currentMode = mode;
    const labels = { NEW: 'New', QUERY: 'Query', MODIFY: 'Modify', AUTHORIZE: 'Authorize' };
    $('screenState').textContent = labels[mode] || mode;
    $('actionNote').textContent = note || `${labels[mode]} customer maintenance`;
  }

  function showXml(mode) {
    const errors = validate(mode);
    if (errors.length) { toast(errors.join(' '), true); return null; }
    try {
      lastRequest = buildRequest(mode);
      $('soapPreview').value = lastRequest;
      $('soapStatus').textContent = `${ACTIONS[mode].operation} · ${get('functionId')}`;
      $('soapDrawer').classList.remove('collapsed');
      $('toggleSoap').textContent = 'Hide';
      return lastRequest;
    } catch (e) {
      toast(e.message, true);
      return null;
    }
  }

  function childText(parent, name) {
    if (!parent) return '';
    const node = Array.from(parent.children).find((n) => n.localName === name);
    return node?.textContent?.trim() ?? '';
  }

  function readXmlResponse(xmlText) {
    const doc = new DOMParser().parseFromString(xmlText, 'application/xml');
    if (doc.querySelector('parsererror')) throw new Error('Response is not valid XML.');
    const header = doc.getElementsByTagNameNS('*', 'FCUBS_HEADER')[0] || doc.querySelector('FCUBS_HEADER');
    const body = doc.getElementsByTagNameNS('*', 'FCUBS_BODY')[0] || doc.querySelector('FCUBS_BODY');
    const msgStat = childText(header, 'MSGSTAT');
    const errors = Array.from(doc.getElementsByTagNameNS('*', 'ERROR')).map((e) => {
      const code = childText(e, 'ECODE') || childText(e, 'ERROR_CODE') || childText(e, 'CODE');
      const desc = childText(e, 'EDESC') || childText(e, 'ERROR_DESC') || childText(e, 'DESC');
      return [code, desc].filter(Boolean).join(' — ');
    }).filter(Boolean);
    const warnings = Array.from(doc.getElementsByTagNameNS('*', 'WARNING')).map((w) => {
      const code = childText(w, 'WCODE'); const desc = childText(w, 'WDESC');
      return [code, desc].filter(Boolean).join(' — ');
    }).filter(Boolean);
    const full = doc.getElementsByTagNameNS('*', 'Customer-Full')[0] || doc.querySelector('Customer-Full');
    if (full) {
      set('customerNo', childText(full, 'CUSTNO'));
      set('customerCategory', childText(full, 'CCATEG'));
      set('fullName', childText(full, 'FULLNAME') || childText(full, 'NAME'));
      set('shortName', childText(full, 'SNAME'));
      set('branchCode', childText(full, 'LBRN'));
      set('addressLine1', childText(full, 'ADDRLN1'));
      set('addressLine2', childText(full, 'ADDRLN2'));
      set('addressLine3', childText(full, 'ADDRLN3'));
      set('country', childText(full, 'COUNTRY'));
      set('nationality', childText(full, 'NLTY'));
      set('addressLine4', childText(full, 'ADDRLN4'));
      set('pincode', childText(full, 'PINCODE'));
      set('custGroup', childText(full, 'CUSTGROUP'));
      set('custClassification', childText(full, 'CUSTCLASS'));
      set('accessGroup', childText(full, 'ACCESSGROUP'));
      set('kycDetails', childText(full, 'KYCDTLS'));
      set('kycRefNo', childText(full, 'KYCREFNO'));
      set('cifStatus', childText(full, 'CIFSTATUS'));
      const personal = full.getElementsByTagNameNS('*', 'Custpersonal')[0] || full.querySelector('Custpersonal');
      if (personal) {
        set('firstName', childText(personal, 'FSTNAME'));
        set('middleName', childText(personal, 'MIDNAME'));
        set('lastName', childText(personal, 'LSTNAME'));
        set('dateOfBirth', childText(personal, 'DOB'));
        set('sex', childText(personal, 'GENDR'));
        set('pNationalId', childText(personal, 'NATIONID'));
        set('mobileNumber', childText(personal, 'MOBNUM'));
        set('mobIsdNo', childText(personal, 'MOBISDNO'));
        set('language', childText(personal, 'LANG'));
        set('passportNo', childText(personal, 'PASSPORTNO'));
        set('passportIssueDate', childText(personal, 'PPTISSDATE'));
        set('passportExpiryDate', childText(personal, 'PPTEXPDATE'));
        set('eMail', childText(personal, 'EMAIL'));
        set('addressLine1', childText(personal, 'DADDR1') || childText(full, 'ADDRLN1'));
        set('addressLine2', childText(personal, 'DADDR2') || childText(full, 'ADDRLN2'));
        set('addressLine3', childText(personal, 'DADDR3') || childText(full, 'ADDRLN3'));
        set('addressLine4', childText(personal, 'DADDR4') || childText(full, 'ADDRLN4'));
        set('pAddress1', childText(personal, 'PADDR1'));
        set('pAddress2', childText(personal, 'PADDR2'));
        set('pAddress3', childText(personal, 'PADDR3'));
        set('pAddress4', childText(personal, 'PADDR4'));
        set('pCountry', childText(personal, 'PCOUNTRY'));
        set('pPincode', childText(personal, 'PPINCODE'));
      }
      const corporate = full.getElementsByTagNameNS('*', 'Custcorporate')[0] || full.querySelector('Custcorporate');
      if (corporate) {
        set('companyType', childText(corporate, 'COMPANYTYPE'));
        set('businessNature', childText(corporate, 'BUSINESSNATURE'));
        set('groupName', childText(corporate, 'GROUPNAME'));
        set('employeeNumber', childText(corporate, 'EMPLOYEENUMBER'));
        set('annualTurnover', childText(corporate, 'ANNUALTURNOVER'));
        set('incorporationNo', childText(corporate, 'INCORPORATIONNO'));
        set('incorporationDate', childText(corporate, 'INCORPORATIONDATE'));
        set('incorporationCountry', childText(corporate, 'INCORPORATIONCOUNTRY'));
        set('registeredAddress1', childText(corporate, 'REGISTEREDADDRESS1'));
        set('registeredAddress2', childText(corporate, 'REGISTEREDADDRESS2'));
        set('registeredAddress3', childText(corporate, 'REGISTEREDADDRESS3'));
        set('registeredAddress4', childText(corporate, 'REGISTEREDADDRESS4'));
        set('corporateKycComments', childText(corporate, 'KYCCOMMENTS'));
        set('corpKycNextReviewDate', childText(corporate, 'KYCNEXTREVIEWDATE'));
      }
      set('makerId', childText(full, 'MAKER'));
      $('makerId').textContent = childText(full, 'MAKER') || '—';
      $('checkerId').textContent = childText(full, 'CHECKER') || '—';
      $('modNo').textContent = childText(full, 'MODNO') || '—';
      $('recordStatus').textContent = childText(full, 'TXNSTAT') || '—';
      $('authStatus').textContent = childText(full, 'AUTHSTAT') || '—';
    }
    const summary = [`MSGSTAT: ${msgStat || '(not returned)'}`, ...errors.map((v) => `ERROR: ${v}`), ...warnings.map((v) => `WARNING: ${v}`)].join('\n');
    return { ok: msgStat !== 'FAILURE' && errors.length === 0, msgStat, errors, warnings, summary, xml: xmlText };
  }

  async function send(mode) {
    const requestXml = showXml(mode);
    if (!requestXml) return;
    const endpoint = get('proxyUrl') || PROXY_DEFAULT;
    $('soapStatus').textContent = 'Sending request…';
    $('soapResponse').textContent = '';
    try {
      const headers = { 'Content-Type': 'application/xml; charset=UTF-8', 'Accept': 'application/xml, text/xml' };
      if (sessionContext?.csrfToken) headers['X-CSRF-TOKEN'] = sessionContext.csrfToken;
      const response = await fetch(endpoint, { method: 'POST', headers, credentials: 'same-origin', body: requestXml });
      const responseText = await response.text();
      lastResponse = responseText;
      if (!response.ok) throw new Error(`Proxy returned HTTP ${response.status}: ${responseText.slice(0, 500)}`);
      const parsed = readXmlResponse(responseText);
      $('soapResponse').textContent = parsed.summary + '\n\n' + responseText;
      $('soapStatus').textContent = parsed.ok ? 'Response received' : 'FCUBS returned an error';
      if (parsed.ok) {
        if (mode === 'NEW') setState('QUERY', 'Customer created — query to refresh details');
        else if (mode === 'MODIFY') setState('QUERY', 'Customer modification submitted');
        else if (mode === 'AUTHORIZE') setState('QUERY', 'Authorization completed');
        toast(parsed.warnings[0] || 'FCUBS response received.');
      } else {
        toast(parsed.errors[0] || 'FCUBS reported a failure.', true);
      }
    } catch (e) {
      $('soapStatus').textContent = 'Request failed';
      $('soapResponse').textContent = `${e.message}\n\nRequest XML:\n${requestXml}`;
      toast(e.message, true);
    }
  }

  function resetForm() {
    const preserve = { branchCode: get('branchCode') || '007', customerCategory: get('customerCategory') || 'WALKIN', country: get('country') || 'KHM', nationality: get('nationality') || 'KHM', language: get('language') || 'ENG' };
    document.querySelectorAll('.form-area input:not([type=radio]):not([type=checkbox]), .form-area select, .form-area textarea').forEach((el) => { el.value = ''; el.classList.remove('invalid'); });
    set('branchCode', preserve.branchCode); set('customerCategory', preserve.customerCategory); set('country', preserve.country); set('nationality', preserve.nationality); set('language', preserve.language);
    document.querySelector('input[name="customerType"][value="I"]').checked = true;
    $('privateCustomer').checked = false; $('sameAddress').checked = false;
    $('cifStatus').value = 'A'; $('frozen').value = 'N'; $('deceased').value = 'N'; $('whereaboutsUnknown').value = 'N'; $('kycDetails').value = 'Y'; $('minor').value = 'N';
    ['makerId','checkerId','modNo','recordStatus','authStatus','makerDate','checkerDate'].forEach((x) => { if ($(x)) $(x).textContent = '—'; });
    setState('NEW', 'New customer record');
  }

  function mirrorAddress() {
    const fields = [['addressLine1','pAddress1'],['addressLine2','pAddress2'],['addressLine3','pAddress3'],['addressLine4','pAddress4'],['country','pCountry'],['pincode','pPincode']];
    const copy = () => { if (check('sameAddress')) fields.forEach(([a,b]) => set(b, get(a))); };
    $('sameAddress').addEventListener('change', copy);
    fields.forEach(([a]) => $(a).addEventListener('input', copy));
  }

  function bindTabs() {
    $('mainTabs').addEventListener('click', (e) => {
      const btn = e.target.closest('[data-tab]'); if (!btn) return;
      document.querySelectorAll('.main-tabs .tab').forEach((t) => t.classList.toggle('active', t === btn));
      document.querySelectorAll('.tab-panel').forEach((p) => p.classList.toggle('active', p.id === `panel-${btn.dataset.tab}`));
    });
    $('subsystemTabs').addEventListener('click', (e) => {
      const btn = e.target.closest('[data-sub]'); if (btn) toast(`${btn.dataset.sub}: this subsystem needs its own data block, XSD mapping and service action.`);
    });
  }

  function bindActions() {
    $('newBtn').addEventListener('click', resetForm);
    $('queryBtn').addEventListener('click', () => send('QUERY'));
    $('pickCustomer').addEventListener('click', () => send('QUERY'));
    $('saveBtn').addEventListener('click', () => send(currentMode === 'QUERY' ? 'MODIFY' : 'NEW'));
    $('authorizeBtn').addEventListener('click', () => send('AUTHORIZE'));
    $('generateXml').addEventListener('click', () => showXml(currentMode));
    $('copyXml').addEventListener('click', async () => {
      const value = $('soapPreview').value;
      if (!value) return toast('Generate a request first.', true);
      try { await navigator.clipboard.writeText(value); toast('FCUBS XML copied.'); }
      catch { $('soapPreview').select(); document.execCommand('copy'); toast('FCUBS XML copied.'); }
    });
    $('clearXml').addEventListener('click', () => { $('soapPreview').value = ''; $('soapResponse').textContent = ''; $('soapStatus').textContent = 'Not connected'; });
    $('sendXml').addEventListener('click', () => {
      if (!$('soapPreview').value.trim()) { toast('Generate the request XML first.', true); return; }
      send(currentMode === 'QUERY' ? 'QUERY' : currentMode);
    });
    $('toggleSoap').addEventListener('click', () => {
      $('soapDrawer').classList.toggle('collapsed');
      $('toggleSoap').textContent = $('soapDrawer').classList.contains('collapsed') ? 'Show' : 'Hide';
    });
    $('exitBtn').addEventListener('click', () => toast('Exit is a local demo action. Close this browser tab to leave the clone screen.'));
    $('fullName').addEventListener('input', () => { if (!get('shortName')) set('shortName', get('fullName').toUpperCase().slice(0,20)); if (get('corrName') === 'Walk-in Customer') set('corrName', get('fullName')); });
    $('customerNo').addEventListener('keydown', (e) => { if (e.key === 'Enter') send('QUERY'); });
    $('gatewayBranch').addEventListener('change', () => set('branchCode', get('gatewayBranch')));
    document.querySelectorAll('input[name="customerType"]').forEach((radio) => radio.addEventListener('change', () => {
      const tabName = radio.value === 'C' ? 'corporate' : 'personal';
      const tab = document.querySelector(`[data-tab="${tabName}"]`);
      if (tab) tab.click();
      toast(radio.value === 'C' ? 'Corporate tab selected. Verify the corporate Customer XSD before sending corporate detail nodes.' : 'Customer type updated.');
    }));
  }

  async function loadSession() {
    try {
      const response = await fetch(`${APP_BASE}api/fcubs/session`, { credentials: 'same-origin', headers: { Accept: 'application/json' } });
      if (!response.ok) return;
      sessionContext = await response.json();
      if (sessionContext.userId) set('gatewayUser', sessionContext.userId);
      if (sessionContext.branchCode) { set('gatewayBranch', sessionContext.branchCode); set('branchCode', sessionContext.branchCode); }
      $('newBtn').disabled = !sessionContext.maker;
      $('saveBtn').disabled = !sessionContext.maker;
      $('authorizeBtn').disabled = !sessionContext.checker;
      $('queryBtn').disabled = false;
      if (!sessionContext.maker && !sessionContext.checker) {
        $('actionNote').textContent = 'Inquiry access only';
      }
    } catch {
      ['newBtn','queryBtn','saveBtn','authorizeBtn'].forEach((id) => { $(id).disabled = true; });
      $('actionNote').textContent = 'WebLogic CIF session is not available';
    }
  }

  function loadSampleDefaults() {
    set('gatewayUser', 'TRAINING_USER');
    set('custGroup', ''); set('cifStatus', 'A'); set('frozen', 'N'); set('deceased', 'N'); set('whereaboutsUnknown', 'N');
    $('makerId').textContent = '—'; $('checkerId').textContent = '—'; $('modNo').textContent = '—'; $('recordStatus').textContent = '—'; $('authStatus').textContent = '—';
  }

  document.addEventListener('DOMContentLoaded', async () => {
    bindTabs(); bindActions(); mirrorAddress(); loadSampleDefaults(); setState('NEW', 'New customer maintenance');
    await loadSession();
    // Initial request preview is intentionally not generated until the user chooses an action.
  });
})();
