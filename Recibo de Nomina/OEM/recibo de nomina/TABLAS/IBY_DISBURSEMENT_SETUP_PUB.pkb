CREATE OR REPLACE PACKAGE BODY APPS.IBY_DISBURSEMENT_SETUP_PUB AS
/*$Header: ibyfdstb.pls 120.5.12010000.29 2013/04/02 05:32:36 yiyu ship $*/

--
-- Declare Global variables
--

G_CURRENT_RUNTIME_LEVEL      CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_STATEMENT            CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;
-- User Defined Exceptions
g_abort_program EXCEPTION;

--
-- Forward Declarations
--

PROCEDURE print_debuginfo(p_module IN VARCHAR2,
                          p_debug_text IN VARCHAR2)
IS
BEGIN
  -- Writing debug text to the concurrent manager log file.
  iby_build_utils_pkg.print_debuginfo(p_module, p_debug_text);
  -- dbms_output.put_line(p_module || ': ' || p_debug_text);

END print_debuginfo;

Procedure insert_payee_row(ext_payee_id IN NUMBER,
                           ext_payee_rec IN External_Payee_Rec_Type,
                           x_return_status OUT NOCOPY VARCHAR2 )
is
    l_module_name VARCHAR2(100) := G_PKG_NAME || 'insert_payee_row';

    --bug 10374184

    l_remit_advice_delivery_method IBY_EXTERNAL_PAYEES_ALL.remit_advice_delivery_method%TYPE;
    l_remit_advice_email   IBY_EXTERNAL_PAYEES_ALL.remit_advice_email%TYPE;
    l_remit_advice_fax     IBY_EXTERNAL_PAYEES_ALL.REMIT_ADVICE_FAX%TYPE;

     CURSOR ar_refund_payee_csr(p_payee_party_id NUMBER,
                                p_party_site_id  NUMBER,
                                p_payer_org_id NUMBER,
                                p_payer_org_type VARCHAR2)
     IS
           SELECT payer.DEBIT_ADVICE_DELIVERY_METHOD,
	      payer.DEBIT_ADVICE_EMAIL, payer.DEBIT_ADVICE_FAX
	      FROM iby_external_payers_all payer,hz_cust_accounts acct, hz_cust_acct_sites_all hzcustacct, HZ_CUST_SITE_USES_ALL siteuses
            WHERE payer.PARTY_ID = p_payee_party_id
	      AND nvl(payer.ORG_ID,-1) =  nvl(p_payer_org_id,-1)
	      AND nvl(payer.ORG_TYPE,-1) = nvl(p_payer_org_type,-1)
              AND nvl(payer.acct_site_use_id,-1) = nvl(siteuses.site_use_id,-1)
              AND acct.party_id = payer.PARTY_ID
              AND  acct.cust_account_id = payer.cust_account_id
              AND acct.cust_account_id = hzcustacct.cust_account_id(+)
              AND hzcustacct.cust_acct_site_id   = siteuses.cust_acct_site_id(+)
              AND hzcustacct.party_site_id(+) = nvl(p_party_site_id,-1)
              AND siteuses.site_use_code(+) = 'BILL_TO' ;
begin

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    print_debuginfo(l_module_name, 'ENTER');
    END IF;

    IF (ext_payee_rec.Payment_Function = 'AR_CUSTOMER_REFUNDS') THEN

                IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name, 'Payment_Function is ' || ext_payee_rec.Payment_Function);
		END IF;

		OPEN ar_refund_payee_csr(ext_payee_rec.Payee_Party_Id,
                                         ext_payee_rec.Payee_Party_Site_Id,
                                         ext_payee_rec.Payer_Org_Id,
                                         ext_payee_rec.Payer_Org_Type);
		FETCH ar_refund_payee_csr INTO l_remit_advice_delivery_method,
					       l_remit_advice_email, l_remit_advice_fax;
		CLOSE ar_refund_payee_csr;

		IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
		print_debuginfo(l_module_name, 'Remit_advice_delivery_method is ' || l_remit_advice_delivery_method);
                print_debuginfo(l_module_name, 'Remit_advice_email is ' || l_remit_advice_email);
	        print_debuginfo(l_module_name, 'remit_advice_fax is ' || l_remit_advice_fax);
		END IF;

    ELSE
		l_remit_advice_delivery_method	:= ext_payee_rec.REMIT_ADVICE_DELIVERY_METHOD;
		l_remit_advice_email		:= ext_payee_rec.REMIT_ADVICE_EMAIL;
		l_remit_advice_fax		:= ext_payee_rec.remit_advice_fax;

		IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
		print_debuginfo(l_module_name, 'Remit_advice_delivery_method is ' || l_remit_advice_delivery_method);
                print_debuginfo(l_module_name, 'Remit_advice_email is ' || l_remit_advice_email);
	        print_debuginfo(l_module_name, 'remit_advice_fax is ' || l_remit_advice_fax);
		END IF;

    END IF;

    x_return_status := FND_API.G_RET_STS_SUCCESS;

    insert into IBY_EXTERNAL_PAYEES_ALL (
    EXT_PAYEE_ID,
    PAYEE_PARTY_ID,
    PAYMENT_FUNCTION,
    EXCLUSIVE_PAYMENT_FLAG,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATE_LOGIN,
    OBJECT_VERSION_NUMBER,
    PARTY_SITE_ID,
    SUPPLIER_SITE_ID,
    ORG_ID,
    ORG_TYPE,
    DEFAULT_PAYMENT_METHOD_CODE,
    ECE_TP_LOCATION_CODE,
    BANK_CHARGE_BEARER,
    BANK_INSTRUCTION1_CODE,
    BANK_INSTRUCTION2_CODE,
    BANK_INSTRUCTION_DETAILS,
    PAYMENT_REASON_CODE,
    PAYMENT_REASON_COMMENTS,
    INACTIVE_DATE,
    PAYMENT_TEXT_MESSAGE1,
    PAYMENT_TEXT_MESSAGE2,
    PAYMENT_TEXT_MESSAGE3,
    DELIVERY_CHANNEL_CODE,
    PAYMENT_FORMAT_CODE,
    SETTLEMENT_PRIORITY,
    REMIT_ADVICE_DELIVERY_METHOD,
    REMIT_ADVICE_EMAIL,
    REMIT_ADVICE_FAX)
    values (
    ext_payee_id,
    ext_payee_rec.Payee_Party_Id,
    ext_payee_rec.Payment_Function,
    ext_payee_rec.Exclusive_Pay_Flag,
    fnd_global.user_id,
    SYSDATE,  -- bug 13881024
    fnd_global.user_id,
    SYSDATE,
    fnd_global.user_id,
    1.0,
    ext_payee_rec.Payee_Party_Site_Id,
    ext_payee_rec.Supplier_Site_Id,
    ext_payee_rec.Payer_Org_Id,
    ext_payee_rec.Payer_Org_Type,
    nvl(ext_payee_rec.edi_payment_method,ext_payee_rec.Default_Pmt_method),
    ext_payee_rec.ECE_TP_Loc_Code,
    ext_payee_rec.Bank_Charge_Bearer,
    nvl(ext_payee_rec.edi_payment_format,ext_payee_rec.Bank_Instr1_Code),
    nvl(ext_payee_rec.edi_transaction_handling,ext_payee_rec.Bank_Instr2_Code),
    ext_payee_rec.Bank_Instr_Detail,
    ext_payee_rec.Pay_Reason_Code,
    ext_payee_rec.Pay_Reason_Com,
    ext_payee_rec.Inactive_Date,
    nvl(ext_payee_rec.edi_remittance_instruction,ext_payee_rec.Pay_Message1),
    ext_payee_rec.Pay_Message2,
    ext_payee_rec.Pay_Message3,
    nvl(ext_payee_rec.edi_remittance_method,ext_payee_rec.Delivery_Channel),
    ext_payee_rec.Pmt_Format,
    ext_payee_rec.Settlement_Priority,
    l_remit_advice_delivery_method,
    l_remit_advice_email,
    l_remit_advice_fax
    );

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    print_debuginfo(l_module_name, 'RETURN');

    END IF;
exception
   when others then
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	     print_debuginfo(l_module_name, 'Exception while insertion into iby_external_payees_all. ');
     END IF;
     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

end insert_payee_row;

FUNCTION Exists_Instr(p_instr IN IBY_FNDCPT_SETUP_PUB.PmtInstrument_rec_type) RETURN BOOLEAN
IS
    l_instr_count NUMBER := 0;

    CURSOR c_creditcard(ci_instrid IN iby_creditcard.instrid%TYPE)
    IS
      SELECT COUNT(instrid)
      FROM iby_creditcard
      WHERE (instrid = ci_instrid);

    CURSOR c_bankaccount(ci_instrid IN iby_ext_bank_accounts_v.ext_bank_account_id%TYPE)
    IS
      SELECT COUNT(ext_bank_account_id)
      FROM iby_ext_bank_accounts_v
      WHERE (ext_bank_account_id = ci_instrid);

  BEGIN

    IF (c_creditcard%ISOPEN) THEN
      CLOSE c_creditcard;
    END IF;
    IF (c_bankaccount%ISOPEN) THEN
      CLOSE c_bankaccount;
    END IF;

    IF (p_instr.Instrument_Type = IBY_FNDCPT_COMMON_PUB.G_INSTR_TYPE_CREDITCARD)
    THEN
      OPEN c_creditcard(p_instr.Instrument_Id);
      FETCH c_creditcard INTO l_instr_count;
      CLOSE c_creditcard;
    ELSIF (p_instr.Instrument_Type = IBY_FNDCPT_COMMON_PUB.G_INSTR_TYPE_BANKACCT)
    THEN
      OPEN c_bankaccount(p_instr.Instrument_Id);
      FETCH c_bankaccount INTO l_instr_count;
      CLOSE c_bankaccount;
    END IF;

    IF (l_instr_count < 1) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;

  END Exists_Instr;

FUNCTION Validate_Payee (
  p_payee            IN   PayeeContext_rec_type,
  p_val_level        IN   VARCHAR2
) RETURN VARCHAR2
IS
vendor_type VARCHAR2(50) ;
vendor_site VARCHAR2(100);
l_module_name        CONSTANT VARCHAR2(200)  := G_PKG_NAME || '.Validate_Payee';

  BEGIN

    -- party id and payment function always mandatory
    IF ( (p_payee.Party_Id IS NULL) OR
         (NOT iby_utility_pvt.check_lookup_val(p_payee.Payment_Function,
                                               IBY_FNDCPT_COMMON_PUB.G_LKUP_PMT_FUNCTION))
       )
    THEN
      RETURN G_RC_INVALID_PAYEE;
    END IF;

    IF (p_val_level = FND_API.G_VALID_LEVEL_FULL) THEN
      IF (NOT iby_utility_pvt.validate_party_id(p_payee.Party_Id)) THEN
        RETURN G_RC_INVALID_PAYEE;
      END IF;
    END IF;

    IF (p_payee.Supplier_Site_id IS NOT NULL) AND
       (p_payee.Party_Site_id IS NOT NULL) AND
       (p_payee.Org_Id IS NOT NULL) AND
       (p_payee.Org_Type IS NOT NULL) THEN
       IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	       print_debuginfo(l_module_name , 'Payee level is supplier site');

       END IF;
      RETURN G_PAYEE_LEVEL_SUPP_SITE;
    ELSIF (p_payee.Party_Site_id IS NOT NULL) AND
          (p_payee.Org_Id IS NOT NULL) AND
          (p_payee.Org_Type IS NOT NULL) THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name , 'Payee level is site-org');
      END IF;
      RETURN G_PAYEE_LEVEL_SITE_ORG;
    ELSIF (p_payee.Party_Site_id IS NOT NULL) THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name , 'Payee level is party site');
      END IF;
      RETURN G_PAYEE_LEVEL_SITE;

    ELSIF (p_payee.Supplier_Site_id IS NULL) AND
          (p_payee.Party_Site_id IS NULL) AND
          (p_payee.Org_Id IS NULL) THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name , 'Payee level is party');

      END IF;
      RETURN G_PAYEE_LEVEL_PARTY;
    ELSIF (p_payee.Supplier_Site_id IS NOT NULL) AND
          (p_payee.Party_Site_id IS NULL) AND
          (p_payee.Org_Id IS NOT NULL) THEN


        SELECT nvl(vendor_type_lookup_code,   'NOT EMPLOYEE'),
	       nvl(vendor_site_code,   'NOT EMPLOYEE')
	  INTO vendor_type,
	       vendor_site
	  FROM ap_suppliers aps,
	       ap_supplier_sites_all apss
	 WHERE apss.vendor_site_id = p_payee.supplier_site_id
	   AND aps.party_id = p_payee.party_id
           and aps.vendor_id = apss.vendor_id; /* bug 16521484 */

          IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	          print_debuginfo(l_module_name, 'Validate_Payee' ||'supplier_site_id ='||p_payee.Supplier_Site_id||'party_site_id ='||p_payee.party_site_id||'org_id' ||p_payee.org_id);

          END IF;
	 IF (vendor_type = 'EMPLOYEE') AND
	    (vendor_site ='HOME' or vendor_site='OFFICE') THEN

	  print_debuginfo(l_module_name , 'Payee level is EMPLOYEE SUPPLIER');
          RETURN G_PAYEE_EMP_SITE;
	 ELSE
	  print_debuginfo(l_module_name ,'Invalid payee');
	  RETURN G_RC_INVALID_PAYEE;
	 END IF;
    ELSIF (p_payee.Supplier_Site_id IS NULL) AND
          (p_payee.Party_Site_id IS NULL) AND
          (p_payee.Org_Id IS NOT NULL) AND
          (p_payee.Org_type = 'LEGAL_ENTITY') THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
	      print_debuginfo(l_module_name , 'LE level is party for bank account transfers');
      END IF;
      RETURN G_LE_LEVEL_PARTY;
    ELSE
         IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	         print_debuginfo(l_module_name ,'Invalid payee');
         END IF;
	 RETURN G_RC_INVALID_PAYEE;

    END IF;

  END Validate_Payee;

PROCEDURE Get_Payee_Id (
   p_payee_context	IN PayeeContext_rec_type,
   p_validation_level	IN VARCHAR2,
   x_payee_level	OUT NOCOPY VARCHAR2,
   x_payee_id		OUT NOCOPY iby_external_payees_all.ext_payee_id%TYPE
)
IS

   CURSOR c_payee
          (ci_party_id IN p_payee_context.Party_Id%TYPE,
           ci_party_site_id IN p_payee_context.Party_Site_id%TYPE,
           ci_supplier_site_id IN p_payee_context.Supplier_Site_id%TYPE,
           ci_org_type IN p_payee_context.Org_Type%TYPE,
           ci_org_id IN p_payee_context.Org_Id%TYPE,
           ci_pmt_function IN p_payee_context.Payment_Function%TYPE)
    IS
    SELECT ext_payee_id
      FROM iby_external_payees_all payee
     WHERE payee.PAYEE_PARTY_ID = ci_party_id
       AND payee.PAYMENT_FUNCTION = ci_pmt_function
       AND ((ci_party_site_id is NULL and payee.PARTY_SITE_ID is NULL) OR
            (payee.PARTY_SITE_ID = ci_party_site_id))
       AND ((ci_supplier_site_id is NULL and payee.SUPPLIER_SITE_ID is NULL) OR
            (payee.SUPPLIER_SITE_ID = ci_supplier_site_id))
       AND ((ci_org_id is NULL and payee.ORG_ID is NULL) OR
            (payee.ORG_ID = ci_org_id AND payee.ORG_TYPE = ci_org_type));

  BEGIN

    IF (c_payee%ISOPEN) THEN
      CLOSE c_payee;
    END IF;

    x_payee_level := Validate_Payee(p_payee_context,p_validation_level);

    IF (x_payee_level = G_RC_INVALID_PAYEE) THEN

      x_payee_id := NULL;
      RETURN;
    END IF;

    OPEN c_payee(p_payee_context.Party_Id,
                 p_payee_context.Party_Site_id,
                 p_payee_context.Supplier_Site_id,
                 p_payee_context.Org_Type,
                 p_payee_context.Org_Id,
                 p_payee_context.Payment_Function );
    FETCH c_payee INTO x_payee_id;
    IF c_payee%NOTFOUND THEN x_payee_id := NULL; END IF;
    CLOSE c_payee;
    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    print_debuginfo('Get_Payee_id:', 'Payee_id from Get_Payee_id function-' ||x_payee_id  );
    END IF;
  END Get_Payee_Id;

procedure raise_biz_event(bank_acc_id NUMBER,
                          party_id    NUMBER,
                          assignment_id NUMBER)
IS
  l_parameter_list wf_parameter_list_t := wf_parameter_list_t();
begin
  wf_event.AddParameterToList(p_name=>'ExternalBankAccountID',
                              p_value=>bank_acc_id,
                              p_parameterlist=>l_parameter_list);
  wf_event.AddParameterToList(p_name=>'PartyID',
                              p_value=>party_id,
                              p_parameterlist=>l_parameter_list);
  wf_event.AddParameterToList(p_name=>'InstrumentAssignmentID',
                              p_value=>assignment_id,
                              p_parameterlist=>l_parameter_list);

  wf_event.raise( p_event_name => 'oracle.apps.iby.bankaccount.assignment_inactivated',
                  p_event_key => 'IBY',
                  p_parameters => l_parameter_list);

  l_parameter_list.DELETE;

end raise_biz_event;


-- Public API

-- Start of comments
--   API name     : Create_External_Payee
--   Type         : Public
--   Pre-reqs     : None
--   Function     : Create payees for records passed in through the payee PL/SQL table
--   Parameters   :
--   IN           :   p_api_version              IN  NUMBER   Required
--                    p_init_msg_list            IN  VARCHAR2 Optional
--                    p_ext_payee_tab            IN  External_Payee_Tab_Type  Required
--   OUT          :   x_return_status            OUT VARCHAR2 Required
--                    x_msg_count                OUT NUMBER   Required
--                    x_msg_data                 OUT VARCHAR2 Required
--                    x_ext_payee_id_tab         OUT Ext_Payee_ID_Tab_Type
--                    x_ext_payee_status_tab     OUT Ext_Payee_Create_Tab_Type Required
--
--   Version   : Current version    1.0
--               Previous version   None
--               Initial version    1.0
-- End of comments

PROCEDURE Create_External_Payee (
     p_api_version           IN   NUMBER,
     p_init_msg_list         IN   VARCHAR2 default FND_API.G_FALSE,
     p_ext_payee_tab         IN   External_Payee_Tab_Type,
     x_return_status         OUT  NOCOPY VARCHAR2,
     x_msg_count             OUT  NOCOPY NUMBER,
     x_msg_data              OUT  NOCOPY VARCHAR2,
     x_ext_payee_id_tab      OUT  NOCOPY Ext_Payee_ID_Tab_Type,
     x_ext_payee_status_tab  OUT  NOCOPY Ext_Payee_Create_Tab_Type
)
IS

     l_api_name           CONSTANT VARCHAR2(30)   := 'Create_External_Payee';
     l_api_version        CONSTANT NUMBER         := 1.0;
     l_module_name        CONSTANT VARCHAR2(200)  := G_PKG_NAME || '.Create_External_Payee';

     l_ext_payee_tab    External_Payee_Tab_Type;


     counter NUMBER;
     l_status VARCHAR2(1);
     l_payee_cnt NUMBER;
     l_payee_id NUMBER;
     l_pm_count NUMBER;
     l_ext_payee_id  NUMBER;
     l_message FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE;

     l_ext_payee_id_rec Ext_Payee_ID_Rec_Type;
     l_ext_payee_crt_rec Ext_Payee_Create_Rec_Type;
     l_payee_crt_status VARCHAR2(30);

     CURSOR external_payee_csr(p_payee_party_id NUMBER,
                               p_party_site_id  NUMBER,
                               p_supplier_site_id NUMBER,
                               p_payer_org_id NUMBER,
                               p_payer_org_type VARCHAR2,
                               p_payment_function VARCHAR2)
     IS
            SELECT count(payee.EXT_PAYEE_ID), max(payee.EXT_PAYEE_ID)
              FROM iby_external_payees_all payee
             WHERE payee.PAYEE_PARTY_ID = p_payee_party_id
               AND payee.PAYMENT_FUNCTION = p_payment_function
               AND ((p_party_site_id is NULL and payee.PARTY_SITE_ID is NULL) OR
                    (payee.PARTY_SITE_ID = p_party_site_id))
               AND ((p_supplier_site_id is NULL and payee.SUPPLIER_SITE_ID is NULL) OR
                    (payee.SUPPLIER_SITE_ID = p_supplier_site_id))
               AND ((p_payer_org_id is NULL and payee.ORG_ID is NULL) OR
                    (payee.ORG_ID = p_payer_org_id AND payee.ORG_TYPE = p_payer_org_type));


BEGIN

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'ENTER');

   END IF;
   -- Standard call to check for call compatibility.
   IF NOT FND_API.Compatible_API_Call(l_api_version,
                                      p_api_version,
                                      l_api_name,
                                      G_PKG_NAME) THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   -- Initialize message list if p_init_msg_list is set to TRUE.
   IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
   END IF;

   --  Initialize API return status to success
   x_return_status := FND_API.G_RET_STS_SUCCESS;

   IF p_ext_payee_tab.COUNT > 0 THEN
      counter := p_ext_payee_tab.FIRST;

      while (counter <= p_ext_payee_tab.LAST)
        loop
          IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	          print_debuginfo(l_module_name, 'Loop thru external payee ' || counter);

          END IF;
          IF p_ext_payee_tab(counter).Payee_Party_Id IS NULL THEN
             IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	             print_debuginfo(l_module_name,'Payee party Id is null.');
             END IF;
             FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
             FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_PAYEE_PARTY_ID_FIELD'));
             FND_MSG_PUB.Add;
	     l_message := fnd_message.get;

             l_ext_payee_id_rec.Ext_Payee_ID := -1;
             l_ext_payee_crt_rec.Payee_Creation_Status := 'E';
             l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;

             x_return_status := FND_API.G_RET_STS_ERROR;
             -- RAISE FND_API.G_EXC_ERROR;
          ELSIF (p_ext_payee_tab(counter).Payment_Function IS NULL) THEN
             IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	             print_debuginfo(l_module_name,'Payment function is null.');
             END IF;
             FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
             FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_FD_PPP_GRP_PMT_T_PF'));
             FND_MSG_PUB.Add;
	     l_message := fnd_message.get;

             l_ext_payee_id_rec.Ext_Payee_ID := -1;
             l_ext_payee_crt_rec.Payee_Creation_Status := 'E';
             l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;

             x_return_status := FND_API.G_RET_STS_ERROR;
             -- RAISE FND_API.G_EXC_ERROR;
              -- orgid is required if supplier site id passed
         ELSIF ((p_ext_payee_tab(counter).Payer_ORG_ID IS NULL) and
                 (p_ext_payee_tab(counter).Supplier_Site_Id IS NOT NULL)) THEN
             IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	             print_debuginfo(l_module_name,'Payer Org Id is null.');
             END IF;
             FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
             FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_PAYER_ORG_ID_FIELD'));
             FND_MSG_PUB.Add;
	     l_message := fnd_message.get;

             l_ext_payee_id_rec.Ext_Payee_ID := -1;
             l_ext_payee_crt_rec.Payee_Creation_Status := 'E';
             l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;
              x_return_status := FND_API.G_RET_STS_ERROR;

     ELSIF ((p_ext_payee_tab(counter).Payer_ORG_ID IS NOT NULL) and
                 (p_ext_payee_tab(counter).Payer_Org_Type IS  NULL)) THEN
             IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	             print_debuginfo(l_module_name,'Payer Org Id is null.');
             END IF;
             FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
             FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_PAYER_ORG_TYPE_FIELD'));
             FND_MSG_PUB.Add;
	     l_message := fnd_message.get;

             l_ext_payee_id_rec.Ext_Payee_ID := -1;
             l_ext_payee_crt_rec.Payee_Creation_Status := 'E';
             l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;
             x_return_status := FND_API.G_RET_STS_ERROR;

     ELSIF ((p_ext_payee_tab(counter).Payer_Org_Type IS NOT NULL) and
           (p_ext_payee_tab(counter).Payer_ORG_ID IS  NULL)) THEN
       IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	       print_debuginfo(l_module_name,'Payer Org Id is null but Org_type is not null.');
       END IF;
       FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
       FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_PAYER_ORG_ID_FIELD'));
             FND_MSG_PUB.Add;
	     l_message := fnd_message.get;

       l_ext_payee_id_rec.Ext_Payee_ID := -1;
       l_ext_payee_crt_rec.Payee_Creation_Status := 'E';
       l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;
       x_return_status := FND_API.G_RET_STS_ERROR;
       -- Payment_Function
     ELSIF (((p_ext_payee_tab(counter).Payer_Org_Type IS NOT NULL) or
             (p_ext_payee_tab(counter).Payer_ORG_ID IS NOT NULL)) and
              (p_ext_payee_tab(counter).Supplier_Site_Id IS NULL  and
              p_ext_payee_tab(counter).Payee_Party_Site_Id IS NULL) and
	      ( p_ext_payee_tab(counter).Payment_Function <> 'CASH_PAYMENT')
           ) THEN
       IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	       print_debuginfo(l_module_name,'Org Id or Org Type is not null but Party_site_id and supplier_site_id are null.');
       END IF;
       FND_MESSAGE.set_name('IBY', 'INVALID_ORG_IN_PAYEE_CONTEXT');
             FND_MSG_PUB.Add;
	     l_message := fnd_message.get;

       l_ext_payee_id_rec.Ext_Payee_ID := -1;
       l_ext_payee_crt_rec.Payee_Creation_Status := 'E';
       l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;
        x_return_status := FND_API.G_RET_STS_ERROR;

      /* Bug: 9139631
         Description: This will no longer be considered as an error.
	 If the value is passed as null , then we derieve the value from
	 IBY_INTERNAL_PAYEES, and if nothing is present we use null as default.
      ELSIF p_ext_payee_tab(counter).Exclusive_Pay_Flag IS NULL THEN
             IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	             print_debuginfo(l_module_name,'Exclusive payment flag is null.');
             END IF;
             FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
             FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_EXCL_PMT_FLAG_FIELD'));
             FND_MSG_PUB.Add;
	     l_message := fnd_message.get;

             l_ext_payee_id_rec.Ext_Payee_ID := -1;
             l_ext_payee_crt_rec.Payee_Creation_Status := 'E';
             l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;

             x_return_status := FND_API.G_RET_STS_ERROR;
        */     -- RAISE FND_API.G_EXC_ERROR;
          ELSE
            l_ext_payee_tab    :=p_ext_payee_tab;

	     -- Bug 9139631.
	     IF p_ext_payee_tab(counter).Exclusive_Pay_Flag IS NULL THEN

	       IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	               print_debuginfo(l_module_name,'Exclusive payment flag is null. Fetching value set at enterprise level');
               END IF;

	       BEGIN

	         SELECT nvl(exclusive_payment_flag,'N')
	         INTO l_ext_payee_tab(counter).Exclusive_Pay_Flag
	         FROM iby_internal_payers_all
                 WHERE ORG_ID IS NULL;

	       EXCEPTION
	        WHEN NO_DATA_FOUND THEN
	          l_ext_payee_tab(counter).Exclusive_Pay_Flag := 'N';
                WHEN OTHERS THEN
                  l_ext_payee_tab(counter).Exclusive_Pay_Flag := 'N';
	       END;

	     END IF;


             OPEN external_payee_csr(p_ext_payee_tab(counter).Payee_Party_Id,
                                     p_ext_payee_tab(counter).Payee_Party_Site_Id,
                                     p_ext_payee_tab(counter).Supplier_Site_Id,
                                     p_ext_payee_tab(counter).Payer_Org_Id,
                                     p_ext_payee_tab(counter).Payer_Org_Type,
                                     p_ext_payee_tab(counter).Payment_Function);
             FETCH external_payee_csr INTO l_payee_cnt, l_payee_id;
             CLOSE external_payee_csr;

             IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	             print_debuginfo(l_module_name, 'Payee count is ' || l_payee_cnt);
	             print_debuginfo(l_module_name, 'Payee Id is ' || l_payee_id);

		     --bug 10374184 for REFUND process
		     print_debuginfo(l_module_name, 'Payment_Function is ' || p_ext_payee_tab(counter).Payment_Function);

             END IF;

             IF l_payee_cnt = 0 THEN
                select IBY_EXTERNAL_PAYEES_ALL_S.nextval into l_ext_payee_id from dual;
                insert_payee_row(l_ext_payee_id,
                                 l_ext_payee_tab(counter),
                                 l_payee_crt_status);

                IF (l_payee_crt_status = FND_API.G_RET_STS_SUCCESS) THEN
                   l_ext_payee_id_rec.Ext_Payee_ID := l_ext_payee_id;
                 -- create the default payment method
                IF(p_ext_payee_tab(counter).Default_Pmt_method is not NULL) THEN
                  select count(1)
                  into l_pm_count
                  from iby_payment_methods_b
                  where payment_method_code=p_ext_payee_tab(counter).Default_Pmt_method;

                IF (l_pm_count>0) then
                  -- insert into the external payment method table
                INSERT INTO IBY_EXT_PARTY_PMT_MTHDS
                (EXT_PARTY_PMT_MTHD_ID,
                  PAYMENT_METHOD_CODE,
                  PAYMENT_FLOW,
                  EXT_PMT_PARTY_ID,
                  PAYMENT_FUNCTION,
                  PRIMARY_FLAG,
                  CREATED_BY,
                 CREATION_DATE,
                 LAST_UPDATED_BY,
                 LAST_UPDATE_DATE,
                 LAST_UPDATE_LOGIN,
                 OBJECT_VERSION_NUMBER
                )
               VALUES
                (
                IBY_EXT_PARTY_PMT_MTHDS_S.nextval,
                p_ext_payee_tab(counter).Default_Pmt_method,--TICKET NSD011860182 DE CAMPOS FALTANTES POR INTERFACE
                 'DISBURSEMENTS',
                 l_ext_payee_id,
                  p_ext_payee_tab(counter).Payment_function,
                 'Y',
                fnd_global.user_id,
                SYSDATE,  -- bug 13881024
                fnd_global.user_id,
                SYSDATE,
                fnd_global.user_id,
                1.0
                );
                 end if;
                end if;

                   l_ext_payee_crt_rec.Payee_Creation_Status := 'S';
                ELSE
                   l_ext_payee_id_rec.Ext_Payee_ID := -1;
                   l_ext_payee_crt_rec.Payee_Creation_Status := 'E';

                   l_message := 'Creating an external payee failed.';
                   l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;
                END IF;
             ELSIF l_payee_cnt > 0 THEN
                l_ext_payee_id_rec.Ext_Payee_ID := -1;
                l_ext_payee_crt_rec.Payee_Creation_Status := 'W';

                FND_MESSAGE.set_name('IBY', 'IBY_DUPLICATE_EXT_PAYEE');
                l_message := fnd_message.get;
                l_ext_payee_crt_rec.Payee_Creation_Msg := l_message;

                -- x_return_status := FND_API.G_RET_STS_SUCCESS;
             END IF;
          END IF;

             IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	             print_debuginfo(l_module_name, 'External payee Id is ' || l_ext_payee_id_rec.Ext_Payee_ID);
	             print_debuginfo(l_module_name, 'Creation status is ' || l_ext_payee_crt_rec.Payee_Creation_Status);
	             print_debuginfo(l_module_name, '------------------------------');

             END IF;
             x_ext_payee_id_tab(counter) := l_ext_payee_id_rec;
             x_ext_payee_status_tab(counter) := l_ext_payee_crt_rec;

             counter := counter + 1;

        end loop;
   END IF;
   -- End of API body.
   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'End of external payee loop.');

   END IF;

   /* Bug Number: 8752267
    */
   -- Standard call to get message count and if count is 1, get message info.
   FND_MSG_PUB.Count_And_Get(p_encoded => fnd_api.g_false, p_count => x_msg_count, p_data  => x_msg_data);


   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'RETURN');

   END IF;
  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;

      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data  => x_msg_data);
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name,'ERROR: Exception occured during call to API ');
	      print_debuginfo(l_module_name,'SQLerr is :'
	                           || substr(SQLERRM, 1, 150));
      END IF;
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data  => x_msg_data);
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name,'ERROR: Exception occured during call to API ');
	      print_debuginfo(l_module_name,'SQLerr is :'
	                           || substr(SQLERRM, 1, 150));
      END IF;
    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

      IF (FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)) THEN
         FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_api_name);
      END IF;
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name,'ERROR: Exception occured during call to API ');
	      print_debuginfo(l_module_name,'SQLerr is :'
	                           || substr(SQLERRM, 1, 150));
      END IF;
      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data  => x_msg_data);

END Create_External_Payee;

-- Start of comments
--   API name     : Set_Payee_Instr_Assignment
--   Type         : Public
--   Pre-reqs     : None
--   Function     : Create payee bank account assignment
--   Parameters   :
--   IN           :   p_api_version              IN  NUMBER   Required
--                    p_init_msg_list            IN  VARCHAR2 Optional
--                    p_ext_payee_tab            IN  External_Payee_Tab_Type  Required
--   OUT          :   x_return_status            OUT VARCHAR2 Required
--                    x_msg_count                OUT NUMBER   Required
--                    x_msg_data                 OUT VARCHAR2 Required
--                    x_ext_payee_id_tab         OUT Ext_Payee_ID_Tab_Type
--                    x_ext_payee_status_tab     OUT Ext_Payee_Create_Tab_Type Required
--
--   Version   : Current version    1.0
--               Previous version   None
--               Initial version    1.0
-- End of comments

PROCEDURE Set_Payee_Instr_Assignment (
  p_api_version      IN   NUMBER,
  p_init_msg_list    IN   VARCHAR2  := FND_API.G_FALSE,
  p_commit           IN   VARCHAR2  := FND_API.G_TRUE,
  x_return_status    OUT  NOCOPY VARCHAR2,
  x_msg_count        OUT  NOCOPY NUMBER,
  x_msg_data         OUT  NOCOPY VARCHAR2,
  p_payee            IN   PayeeContext_rec_type,
  p_assignment_attribs IN  IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_rec_type,
  x_assign_id        OUT  NOCOPY NUMBER,
  x_response         OUT  NOCOPY IBY_FNDCPT_COMMON_PUB.Result_rec_type
)
IS
   l_api_version  CONSTANT  NUMBER := 1.0;
   l_module       CONSTANT  VARCHAR2(30) := 'Set_Payee_Instr_Assignment';
   l_prev_msg_count NUMBER;

   l_payee_level  VARCHAR2(30);
   l_payee_id     iby_external_payees_all.ext_payee_id%TYPE;

   l_result       IBY_FNDCPT_COMMON_PUB.Result_rec_type;

   l_assign_id    NUMBER;
   l_instr_id     NUMBER;
   l_priority     NUMBER;

   l_ext_payee_rec	External_Payee_Rec_Type;
   l_payee_crt_status   VARCHAR2(30);

   l_bnkacct_owner_cnt NUMBER;

   l_giv_op       NUMBER;  --Bug 14488642 Variable for given order of preference
   l_cur_op	  NUMBER;  --Variable for current order of preference

    CURSOR c_instr_assignment
           (ci_assign_id IN iby_pmt_instr_uses_all.instrument_payment_use_id%TYPE,
            ci_payee_id IN iby_pmt_instr_uses_all.ext_pmt_party_id%TYPE,
            ci_instr_type IN iby_pmt_instr_uses_all.instrument_type%TYPE,
            ci_instr_id IN iby_pmt_instr_uses_all.instrument_id%TYPE
           )
    IS
      SELECT instrument_payment_use_id
      FROM iby_pmt_instr_uses_all
      WHERE (payment_flow = G_PMT_FLOW_DISBURSE)
        AND ( (instrument_payment_use_id = NVL(ci_assign_id,-1))
              OR (ext_pmt_party_id = ci_payee_id
                  AND instrument_type = ci_instr_type
                  AND instrument_id = ci_instr_id )
            );

    CURSOR c_bnkacct_owner
           (ci_party_id IN iby_pmt_instr_uses_all.ext_pmt_party_id%TYPE,
            ci_instr_id IN iby_pmt_instr_uses_all.instrument_id%TYPE
           )
    IS
      SELECT count(*)
      FROM IBY_ACCOUNT_OWNERS
      WHERE EXT_BANK_ACCOUNT_ID = ci_instr_id
        AND ACCOUNT_OWNER_PARTY_ID = ci_party_id;

  BEGIN

    IF (c_instr_assignment%ISOPEN) THEN
      CLOSE c_instr_assignment;
    END IF;

    IF NOT FND_API.Compatible_API_Call (l_api_version,
                                        p_api_version,
                                        l_module,
                                        G_PKG_NAME)
    THEN
      iby_debug_pub.add(debug_msg => 'Incorrect API Version:=' || p_api_version,
                        debug_level => FND_LOG.LEVEL_ERROR,
                        module => G_DEBUG_MODULE || l_module);
      FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF FND_API.to_Boolean( p_init_msg_list ) THEN
      FND_MSG_PUB.initialize;
    END IF;
    l_prev_msg_count := FND_MSG_PUB.Count_Msg;

    -- Bug# 8470581
    -- Do not allow an assignment if the payee party_id is not a joint
    -- account owner
    IF ((p_assignment_attribs.Assignment_Id IS NULL) AND
           (p_assignment_attribs.Instrument.Instrument_Type = 'BANKACCOUNT')) THEN
      IF(c_bnkacct_owner%ISOPEN) THEN CLOSE c_bnkacct_owner; END IF;
      OPEN c_bnkacct_owner(p_payee.Party_Id, p_assignment_attribs.Instrument.Instrument_Id);
      FETCH c_bnkacct_owner INTO l_bnkacct_owner_cnt;

      IF (l_bnkacct_owner_cnt <= 0) THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module, 'Payee party is not a joint account owner. Aborting..');
        END IF;
        x_response.Result_Code := G_RC_INVALID_PAYEE;
	RETURN;
      END IF;
    END IF;

    Get_Payee_Id(p_payee, FND_API.G_VALID_LEVEL_FULL,l_payee_level, l_payee_id);

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    print_debuginfo(l_module, 'After Get_Payee_Id');
	    print_debuginfo(l_module, 'Payee level is ' || l_payee_level);


    END IF;
    IF (l_payee_level = G_RC_INVALID_PAYEE) THEN
      x_response.Result_Code := G_RC_INVALID_PAYEE;
    ELSIF ( (p_assignment_attribs.Assignment_Id IS NULL) AND
            (NOT Exists_Instr(p_assignment_attribs.Instrument)) ) THEN
      x_response.Result_Code := G_RC_INVALID_INSTRUMENT;
    ELSIF ((p_assignment_attribs.End_Date IS NOT NULL) AND
           (nvl(p_assignment_attribs.Start_Date, sysdate - 1) > p_assignment_attribs.End_Date) ) THEN
      x_response.Result_Code := G_RC_INVALID_DATE_RANGE;
    ELSE
      SAVEPOINT Set_Payee_Instr_Assignment;

      -- create the payee entity if it does not exist
      IF (l_payee_id IS NULL) THEN
        -- Create a default external payee
	print_debuginfo(l_module,'Inside if l_payee_id is null, trying to insert in external_payees_all ');
        select IBY_EXTERNAL_PAYEES_ALL_S.nextval into l_payee_id from dual;

        l_ext_payee_rec.Payee_Party_Id := p_payee.Party_Id;
        l_ext_payee_rec.Payee_Party_Site_Id := p_payee.Party_Site_id;
        l_ext_payee_rec.Supplier_Site_Id := p_payee.Supplier_Site_id;
        l_ext_payee_rec.Payer_Org_Type := p_payee.Org_Type;
        l_ext_payee_rec.Payer_Org_Id := p_payee.Org_Id;
        l_ext_payee_rec.Payment_Function := p_payee.Payment_Function;
        l_ext_payee_rec.Exclusive_Pay_Flag := 'N';

	insert_payee_row(l_payee_id, l_ext_payee_rec, l_payee_crt_status);

        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module, 'After inserting a default payee row.');


        END IF;
        IF (l_payee_crt_status <> FND_API.G_RET_STS_SUCCESS) THEN
          x_response.Result_Code := G_RC_INVALID_PAYEE;
          RETURN;
        END IF;
      END IF;

      -- for the combined query cursor, only 1 query condition should be used,
      -- either the assingment id or the (payer id, instr type, instr id)
      -- combination
      --
      IF (p_assignment_attribs.Assignment_Id IS NOT NULL) THEN
        l_assign_id := p_assignment_attribs.Assignment_Id;
      ELSE
        l_instr_id := p_assignment_attribs.Instrument.Instrument_Id;
      END IF;

      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module, 'Assignment id is ' || l_assign_id);
	      print_debuginfo(l_module, 'Instrument id is ' || l_instr_id);

      END IF;
      OPEN c_instr_assignment(l_assign_id,
                              l_payee_id,
                              p_assignment_attribs.Instrument.Instrument_Type,
                              l_instr_id);
      FETCH c_instr_assignment INTO x_assign_id;
      IF (c_instr_assignment%NOTFOUND) THEN x_assign_id := NULL; END IF;
      CLOSE c_instr_assignment;

      l_priority := GREATEST(NVL(p_assignment_attribs.Priority,1),1);

      l_giv_op := p_assignment_attribs.Priority;  --Bug 14488642
	  IF(x_assign_id IS NOT NULL) THEN
		SELECT order_of_preference
		INTO l_cur_op
		FROM iby_pmt_instr_uses_all
		WHERE instrument_payment_use_id = x_assign_id;
	  END IF;

      -- only need to shift instrument priorities if this is a new instrument
      -- or if this is an update with a non-NULL priority
      IF (x_assign_id IS NULL)
      THEN
	      --Per bug 6851476
	      --Eleminating the expensive CONNECT BY clause
         UPDATE iby_pmt_instr_uses_all
            SET order_of_preference = order_of_preference + 1,
                last_updated_by =  fnd_global.user_id,
                last_update_date = SYSDATE,
                last_update_login = fnd_global.login_id,
                object_version_number = object_version_number + 1
          WHERE ext_pmt_party_id = l_payee_id
            AND payment_flow = G_PMT_FLOW_DISBURSE
            AND order_of_preference >= l_priority;

	 ELSE
	      --Shifting priorities via API
	  		IF(p_assignment_attribs.Priority IS NOT NULL) THEN   --Bug 13827657
				IF(l_cur_op > l_giv_op) THEN
				  UPDATE iby_pmt_instr_uses_all
					SET order_of_preference = order_of_preference + 1,
					    last_updated_by =  fnd_global.user_id,
					    last_update_date = SYSDATE,
					    last_update_login = fnd_global.login_id
				  WHERE ext_pmt_party_id = l_payee_id
					AND payment_flow = G_PMT_FLOW_DISBURSE
					AND order_of_preference < l_cur_op
					AND order_of_preference >= l_giv_op ;
				ELSIF(l_cur_op < l_giv_op) THEN
				  UPDATE iby_pmt_instr_uses_all
					SET order_of_preference = order_of_preference - 1,
					    last_updated_by =  fnd_global.user_id,
					    last_update_date = SYSDATE,
					    last_update_login = fnd_global.login_id
				  WHERE ext_pmt_party_id = l_payee_id
					AND payment_flow = G_PMT_FLOW_DISBURSE
					AND order_of_preference > l_cur_op
					AND order_of_preference <= l_giv_op ;
				END IF;
			END IF;
      END IF;

      IF (x_assign_id IS NULL) THEN
        SELECT iby_pmt_instr_uses_all_s.nextval
        INTO x_assign_id
        FROM DUAL;

        INSERT INTO iby_pmt_instr_uses_all
          (instrument_payment_use_id,
           ext_pmt_party_id,
           instrument_type,
           instrument_id,
           payment_function,
           payment_flow,
           order_of_preference,
           debit_auth_flag,
           debit_auth_method,
           debit_auth_reference,
           debit_auth_begin,
           debit_auth_end,
           start_date,
           end_date,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           last_update_login,
           object_version_number)
        VALUES
          (x_assign_id,
           l_payee_id,
           p_assignment_attribs.Instrument.Instrument_Type,
           p_assignment_attribs.Instrument.Instrument_Id,
           p_payee.Payment_Function,
           G_PMT_FLOW_DISBURSE,
           l_priority,
           null, null, null, null, null,
           NVL(p_assignment_attribs.Start_Date,SYSDATE),
           p_assignment_attribs.End_Date,
           fnd_global.user_id,
           SYSDATE,   -- bug 13881024
           fnd_global.user_id,
           SYSDATE,
           fnd_global.login_id,
           1);
      ELSE
        UPDATE iby_pmt_instr_uses_all
          SET
            order_of_preference =
              NVL(p_assignment_attribs.Priority,order_of_preference),
            start_date = NVL(p_assignment_attribs.Start_Date,start_date),
            end_date = p_assignment_attribs.End_Date,
            last_updated_by =  fnd_global.user_id,
            last_update_date = SYSDATE,
            last_update_login = fnd_global.login_id,
            object_version_number = object_version_number + 1
        WHERE instrument_payment_use_id = x_assign_id;
      END IF;

      x_response.Result_Code := G_RC_SUCCESS;

      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module, 'After access instr uses table.');
      END IF;
    END IF;

/*
    IF p_assignment_attribs.End_Date IS NOT NULL THEN
       raise_biz_event(l_instr_id, l_payee_id, x_assign_id);
    END IF;
*/

    IF FND_API.To_Boolean(p_commit) THEN
      COMMIT;
    END IF;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    print_debuginfo(l_module, 'Before prepare the result.');


    END IF;
    iby_fndcpt_common_pub.Prepare_Result
    (l_prev_msg_count,x_return_status,x_msg_count,x_msg_data,x_response);

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    print_debuginfo(l_module, 'RETURN');

    END IF;
   EXCEPTION

      WHEN FND_API.G_EXC_ERROR THEN
        ROLLBACK TO Set_Payee_Instr_Assignment;
	iby_debug_pub.add(debug_msg => 'In G_EXC_ERROR Exception',
              debug_level => FND_LOG.LEVEL_ERROR,
              module => G_DEBUG_MODULE || l_module);
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        ROLLBACK TO Set_Payee_Instr_Assignment;
	iby_debug_pub.add(debug_msg => 'In G_EXC_UNEXPECTED_ERROR Exception',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || l_module);
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN
        ROLLBACK TO Set_Payee_Instr_Assignment;
        iby_debug_pub.add(debug_msg => 'In OTHERS Exception',
          debug_level => FND_LOG.LEVEL_UNEXPECTED,
          module => G_DEBUG_MODULE || l_module);
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
        IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
          FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_module);
        END IF;

        FND_MSG_PUB.Count_And_Get( p_count  =>  x_msg_count,
                                   p_data   =>  x_msg_data
                                  );
  END Set_Payee_Instr_Assignment;

-- Start of comments
--   API name     : Get_Payee_Instr_Assignments
--   Type         : Public
--   Pre-reqs     : None
--   Function     : Create payee bank account assignment
--   Parameters   :
--   IN           :   p_api_version              IN  NUMBER   Required
--                    p_init_msg_list            IN  VARCHAR2 Optional
--                    p_ext_payee_tab            IN  External_Payee_Tab_Type  Required
--   OUT          :   x_return_status            OUT VARCHAR2 Required
--                    x_msg_count                OUT NUMBER   Required
--                    x_msg_data                 OUT VARCHAR2 Required
--                    x_ext_payee_id_tab         OUT Ext_Payee_ID_Tab_Type
--                    x_ext_payee_status_tab     OUT Ext_Payee_Create_Tab_Type Required
--
--   Version   : Current version    1.0
--               Previous version   None
--               Initial version    1.0
-- End of comments

PROCEDURE Get_Payee_Instr_Assignments (
   p_api_version      IN   NUMBER,
   p_init_msg_list    IN   VARCHAR2  := FND_API.G_FALSE,
   x_return_status    OUT  NOCOPY VARCHAR2,
   x_msg_count        OUT  NOCOPY NUMBER,
   x_msg_data         OUT  NOCOPY VARCHAR2,
   p_payee            IN   PayeeContext_rec_type,
   x_assignments      OUT  NOCOPY IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_tbl_type,
   x_response         OUT  NOCOPY IBY_FNDCPT_COMMON_PUB.Result_rec_type
)
IS
    l_api_version  CONSTANT  NUMBER := 1.0;
    l_module       CONSTANT  VARCHAR2(30) := 'Get_Payer_Instr_Assignments';
    l_prev_msg_count NUMBER;

    l_payee_level  VARCHAR2(30);
    l_payee_id     iby_external_payees_all.ext_payee_id%TYPE;

    l_assign_count NUMBER := 0;

    CURSOR c_instr_assignments
           (ci_payee_id IN iby_pmt_instr_uses_all.ext_pmt_party_id%TYPE)
    IS
      SELECT instrument_payment_use_id,
             instrument_type,
             instrument_id,
             order_of_preference,
             start_date,
             end_date
      FROM iby_pmt_instr_uses_all
      WHERE (payment_flow = G_PMT_FLOW_DISBURSE)
        AND (ext_pmt_party_id = ci_payee_id);

  BEGIN

    IF (c_instr_assignments%ISOPEN) THEN
      CLOSE c_instr_assignments;
    END IF;

    IF NOT FND_API.Compatible_API_Call (l_api_version,
                                        p_api_version,
                                        l_module,
                                        G_PKG_NAME)
    THEN
      iby_debug_pub.add(debug_msg => 'Incorrect API Version:=' || p_api_version,
                        debug_level => FND_LOG.LEVEL_ERROR,
                        module => G_DEBUG_MODULE || l_module);
      FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF FND_API.to_Boolean( p_init_msg_list ) THEN
      FND_MSG_PUB.initialize;
    END IF;
    l_prev_msg_count := FND_MSG_PUB.Count_Msg;

    Get_Payee_Id(p_payee,FND_API.G_VALID_LEVEL_FULL,l_payee_level,l_payee_id);

    IF (l_payee_level = IBY_FNDCPT_COMMON_PUB.G_RC_INVALID_PAYER) THEN
      x_response.Result_Code := IBY_FNDCPT_COMMON_PUB.G_RC_INVALID_PAYER;
    ELSE
      l_assign_count := 0;
      FOR assign_rec IN c_instr_assignments(l_payee_id)
      LOOP
        l_assign_count := l_assign_count + 1;

        x_assignments(l_assign_count).Assignment_Id :=
        	assign_rec.instrument_payment_use_id;
        x_assignments(l_assign_count).Instrument.Instrument_Type :=
        	assign_rec.instrument_type;
        x_assignments(l_assign_count).Instrument.Instrument_Id :=
        	assign_rec.instrument_id;
        x_assignments(l_assign_count).Priority := assign_rec.order_of_preference;
        x_assignments(l_assign_count).Start_Date := assign_rec.start_date;
        x_assignments(l_assign_count).End_Date := assign_rec.end_date;
      END LOOP;

      x_response.Result_Code := IBY_FNDCPT_COMMON_PUB.G_RC_SUCCESS;

    END IF;

    iby_fndcpt_common_pub.Prepare_Result
    (l_prev_msg_count,x_return_status,x_msg_count,x_msg_data,x_response);

   EXCEPTION

      WHEN FND_API.G_EXC_ERROR THEN

	iby_debug_pub.add(debug_msg => 'In G_EXC_ERROR Exception',
              debug_level => FND_LOG.LEVEL_ERROR,
              module => G_DEBUG_MODULE || l_module);
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

	iby_debug_pub.add(debug_msg => 'In G_EXC_UNEXPECTED_ERROR Exception',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || l_module);
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN

        iby_debug_pub.add(debug_msg => 'In OTHERS Exception',
          debug_level => FND_LOG.LEVEL_UNEXPECTED,
          module => G_DEBUG_MODULE || l_module);
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
        IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
          FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_module);
        END IF;

        FND_MSG_PUB.Count_And_Get( p_count  =>  x_msg_count,
                                   p_data   =>  x_msg_data
                                  );
  END Get_Payee_Instr_Assignments;

-- Start of comments
--   API name     : Get_Payee_All_Instruments
--   Type         : Public
--   Pre-reqs     : None
--   Function     : Create payee bank account assignment
--   Parameters   :
--   IN           :   p_api_version              IN  NUMBER   Required
--                    p_init_msg_list            IN  VARCHAR2 Optional
--                    p_ext_payee_tab            IN  External_Payee_Tab_Type  Required
--   OUT          :   x_return_status            OUT VARCHAR2 Required
--                    x_msg_count                OUT NUMBER   Required
--                    x_msg_data                 OUT VARCHAR2 Required
--                    x_ext_payee_id_tab         OUT Ext_Payee_ID_Tab_Type
--                    x_ext_payee_status_tab     OUT Ext_Payee_Create_Tab_Type Required
--
--   Version   : Current version    1.0
--               Previous version   None
--               Initial version    1.0
-- End of comments

PROCEDURE Get_Payee_All_Instruments (
   p_api_version      IN   NUMBER,
   p_init_msg_list    IN   VARCHAR2  := FND_API.G_FALSE,
   x_return_status    OUT  NOCOPY VARCHAR2,
   x_msg_count        OUT  NOCOPY NUMBER,
   x_msg_data         OUT  NOCOPY VARCHAR2,
   p_party_id         IN   NUMBER,
   x_instruments      OUT  NOCOPY IBY_FNDCPT_SETUP_PUB.PmtInstrument_tbl_type,
   x_response         OUT  NOCOPY IBY_FNDCPT_COMMON_PUB.Result_rec_type
)
IS
    l_api_version  CONSTANT  NUMBER := 1.0;
    l_module       CONSTANT  VARCHAR2(30) := 'Get_Payer_All_Assignments';
    l_prev_msg_count NUMBER;

    l_instr_count NUMBER := 0;

    CURSOR c_instr_assignments
           (ci_party_id IN iby_external_payees_all.payee_party_id%TYPE)
    IS
      SELECT DISTINCT u.instrument_type, u.instrument_id
      FROM iby_pmt_instr_uses_all u, iby_external_payees_all p
      WHERE (u.payment_flow = G_PMT_FLOW_DISBURSE)
        AND (u.ext_pmt_party_id = p.ext_payee_id)
        AND (p.payee_party_id = ci_party_id);

  BEGIN

    IF (c_instr_assignments%ISOPEN) THEN
      CLOSE c_instr_assignments;
    END IF;

    IF NOT FND_API.Compatible_API_Call (l_api_version,
                                        p_api_version,
                                        l_module,
                                        G_PKG_NAME)
    THEN
      iby_debug_pub.add(debug_msg => 'Incorrect API Version:=' || p_api_version,
                        debug_level => FND_LOG.LEVEL_ERROR,
                        module => G_DEBUG_MODULE || l_module);
      FND_MESSAGE.SET_NAME('IBY', 'IBY_204400_API_VER_MISMATCH');
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF FND_API.to_Boolean( p_init_msg_list ) THEN
      FND_MSG_PUB.initialize;
    END IF;
    l_prev_msg_count := FND_MSG_PUB.Count_Msg;

    l_instr_count := 0;
    FOR assign_rec IN c_instr_assignments(p_party_id) LOOP
      l_instr_count := l_instr_count + 1;

      x_instruments(l_instr_count).Instrument_Type := assign_rec.instrument_type;
      x_instruments(l_instr_count).Instrument_Id := assign_rec.instrument_id;
    END LOOP;

    x_response.Result_Code := IBY_FNDCPT_COMMON_PUB.G_RC_SUCCESS;

    iby_fndcpt_common_pub.Prepare_Result
    (l_prev_msg_count,x_return_status,x_msg_count,x_msg_data,x_response);

   EXCEPTION

      WHEN FND_API.G_EXC_ERROR THEN

	iby_debug_pub.add(debug_msg => 'In G_EXC_ERROR Exception',
              debug_level => FND_LOG.LEVEL_ERROR,
              module => G_DEBUG_MODULE || l_module);
         x_return_status := FND_API.G_RET_STS_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

	iby_debug_pub.add(debug_msg => 'In G_EXC_UNEXPECTED_ERROR Exception',
              debug_level => FND_LOG.LEVEL_UNEXPECTED,
              module => G_DEBUG_MODULE || l_module);
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         FND_MSG_PUB.Count_And_Get ( p_count  =>   x_msg_count,
                                     p_data   =>   x_msg_data
                                   );
      WHEN OTHERS THEN

        iby_debug_pub.add(debug_msg => 'In OTHERS Exception',
          debug_level => FND_LOG.LEVEL_UNEXPECTED,
          module => G_DEBUG_MODULE || l_module);
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
        IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
          FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_module);
        END IF;

        FND_MSG_PUB.Count_And_Get( p_count  =>  x_msg_count,
                                   p_data   =>  x_msg_data
                                  );

        iby_debug_pub.add(debug_msg => 'x_return_status=' || x_return_status,
          debug_level => FND_LOG.LEVEL_UNEXPECTED,
          module => G_DEBUG_MODULE || l_module);
        iby_debug_pub.add(debug_msg => 'Exit Exception',
          debug_level => FND_LOG.LEVEL_UNEXPECTED,
          module => G_DEBUG_MODULE || l_module);
  END Get_Payee_All_Instruments;

   -- CheckInLookup
   --
   --
FUNCTION CheckInLookup(
   p_value VARCHAR2,
   p_loopkup_type VARCHAR2
) RETURN BOOLEAN
IS
    l_count              PLS_INTEGER;

    CURSOR lookup_csr(p_lookup_type IN VARCHAR2,
                      p_lookup_code IN VARCHAR2)
    IS
      SELECT COUNT(LOOKUP_CODE)
       FROM FND_LOOKUPS
       WHERE LOOKUP_TYPE = p_lookup_type
         AND LOOKUP_CODE = p_lookup_code;
BEGIN

    OPEN lookup_csr(p_loopkup_type, p_value);
    FETCH lookup_csr INTO l_count;
    CLOSE lookup_csr;

    IF (l_count = 0) THEN
       FND_MESSAGE.set_name('IBY', 'IBY_LOOKUP_VAL_ERROR');
       FND_MESSAGE.SET_TOKEN('LOOKUPTYPE', p_loopkup_type);
       FND_MESSAGE.SET_TOKEN('VALUE', p_value);
       FND_MSG_PUB.Add;
       RETURN FALSE;
    ELSE
       RETURN TRUE;
    END IF;

END CheckInLookup;

   -- Validate_External_Payee
   --
   --   API name        : Validate_External_Payee
   --   Type            : Public
   --   Pre-reqs        : None
   --   Function        : Validate an External Payee
   --   Current version : 1.0
   --   Previous version: 1.0
   --   Initial version : 1.0

PROCEDURE Validate_External_Payee (
     p_api_version           IN   NUMBER,
     p_init_msg_list         IN   VARCHAR2 default FND_API.G_FALSE,
     p_ext_payee_rec         IN   External_Payee_Rec_Type,
     x_return_status         OUT  NOCOPY VARCHAR2,
     x_msg_count             OUT  NOCOPY NUMBER,
     x_msg_data              OUT  NOCOPY VARCHAR2
) IS

  l_api_name           CONSTANT VARCHAR2(30)   := 'Validate_External_Payee';
  l_api_version        CONSTANT NUMBER         := 1.0;
  l_module_name        CONSTANT VARCHAR2(200)  := G_PKG_NAME || '.' || l_api_name;


  l_payee_country      VARCHAR2(30);
  l_valid              BOOLEAN;
  l_temp_valid         BOOLEAN;
  l_count              PLS_INTEGER;

   CURSOR payee_country_csr(p_payee_id IN NUMBER)
    IS
      SELECT country
        FROM HZ_PARTIES
       WHERE party_id = p_payee_id;

   CURSOR payeesite_country_csr(p_payee_id IN NUMBER,
                                 p_payee_site_id IN NUMBER)
    IS
      SELECT locs.country
        FROM HZ_PARTY_SITES sites,
             HZ_LOCATIONS locs
       WHERE sites.party_id = p_payee_id
         AND sites.party_site_id = p_payee_site_id
         AND sites.location_id = locs.location_id;

   CURSOR pmt_reasons_csr(p_pmt_reason_code VARCHAR2)
    IS
      SELECT COUNT(payment_reason_code)
      FROM IBY_PAYMENT_REASONS_VL ibypr
      WHERE ibypr.payment_reason_code = p_pmt_reason_code
      AND   (ibypr.inactive_date is NULL OR ibypr.inactive_date >= trunc(sysdate));

   CURSOR dlv_channels_csr(p_dlv_channel_code VARCHAR2)
   IS
      SELECT COUNT(delivery_channel_code)
       FROM IBY_DELIVERY_CHANNELS_VL ibydlv
       WHERE ibydlv.delivery_channel_code = p_dlv_channel_code
       AND   (ibydlv.inactive_date is NULL OR ibydlv.inactive_date >= trunc(sysdate));

   CURSOR payment_formats_csr(p_payment_format_code VARCHAR2)
   IS
      SELECT COUNT(f.format_code)
      FROM IBY_FORMATS_VL f
      WHERE f.format_code = p_payment_format_code;

   CURSOR pmt_mthds_csr(p_payment_mthd_code VARCHAR2)
   IS
    SELECT COUNT(Payment_Method_Name)
           PAYMENT_METHOD_CODE
        FROM IBY_PAYMENT_METHODS_VL
        WHERE PAYMENT_METHOD_CODE = p_payment_mthd_code;

  BEGIN

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Enter');
   END IF;

    SAVEPOINT Validate_External_Payee_pub;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.Compatible_API_Call(l_api_version,
                                       p_api_version,
                                       l_api_name,
                                       G_PKG_NAME) THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
       FND_MSG_PUB.initialize;
    END IF;

    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Start of API body
    IF (p_ext_payee_rec.Payee_Party_Id IS NOT NULL) THEN
       IF (p_ext_payee_rec.Payee_Party_Site_Id IS NOT NULL) THEN
          -- Fetch Payee Site Country
          OPEN payeesite_country_csr(p_ext_payee_rec.Payee_Party_Id,
                                     p_ext_payee_rec.Payee_Party_Site_Id);
          FETCH payeesite_country_csr INTO l_payee_country;
          CLOSE payeesite_country_csr;
       ELSE
          -- Fetch Payee Country
          OPEN payee_country_csr(p_ext_payee_rec.Payee_Party_Id);
          FETCH payee_country_csr INTO l_payee_country;
          CLOSE payee_country_csr;
       END IF;
    END IF;

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Payment Function');
       print_debuginfo(l_module_name, 'Payment Function::'||p_ext_payee_rec.Payment_Function);
   END IF;
    -- 1. Validate Payment Function (lookup: IBY_PAYMENT_FUNCTIONS)
    -- Payment Function is Mandatory
    l_temp_valid := CheckInLookup(p_ext_payee_rec.Payment_Function,
                                  'IBY_PAYMENT_FUNCTIONS');

    l_valid := l_valid AND l_temp_valid;

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Exclusive Pay Flag');
       print_debuginfo(l_module_name, 'Exclusive Pay Flag::'||p_ext_payee_rec.Exclusive_Pay_Flag);
   END IF;

    -- 2. Validate Exclusive Payment Flag (lookup:)
    -- Exclusive Payment Flag is mandatory
    l_temp_valid := (p_ext_payee_rec.Exclusive_Pay_Flag IN ('Y','N'));

    l_valid := l_valid AND l_temp_valid;

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Default Payment Method');
       print_debuginfo(l_module_name, 'Default Payment Method::'||p_ext_payee_rec.Default_Pmt_method);
   END IF;

    -- 3. Validate Default Payment Method (table: IBY_PAYMENT_METHODS_VL)
    -- is not mandatory
    IF (p_ext_payee_rec.Default_Pmt_method IS NOT NULL) THEN

      OPEN pmt_mthds_csr(p_ext_payee_rec.Default_Pmt_method);
      FETCH pmt_mthds_csr INTO l_count;
      CLOSE pmt_mthds_csr;

      IF (l_count = 0) THEN
			   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
				   print_debuginfo(l_module_name, 'InValid Default Payment Method');
			   END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_TABLE_VAL_ERROR');
        FND_MESSAGE.SET_TOKEN('TABLE', 'IBY_PAYMENT_METHODS_V');
        FND_MESSAGE.SET_TOKEN('VALUE', p_ext_payee_rec.Default_Pmt_method);
        FND_MSG_PUB.Add;
        l_valid := FALSE;
      END IF;
    END IF;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Bank Charge Bearer');
       print_debuginfo(l_module_name, 'Bank Charge Bearer::'||p_ext_payee_rec.Bank_Charge_Bearer);
   END IF;

    -- 4. Validate Bank Charge Bearer (lookup: IBY_BANK_CHARGE_BEARER)
    -- is not mandatory
    IF (p_ext_payee_rec.Bank_Charge_Bearer IS NOT NULL) THEN
      l_temp_valid := CheckInLookup(p_ext_payee_rec.Bank_Charge_Bearer,
                                    'IBY_BANK_CHARGE_BEARER');

      l_valid := l_valid AND l_temp_valid;
    END IF;


    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Payment Reason Code');
       print_debuginfo(l_module_name, 'Payment Reason Code::'||p_ext_payee_rec.Pay_Reason_Code);
   END IF;
    -- 5. Validate Payment Reason Code (table: IBY_PAYMENT_REASONS_VL by country)
    -- is not mandatory
    IF (p_ext_payee_rec.Pay_Reason_Code IS NOT NULL) THEN
      OPEN pmt_reasons_csr(p_ext_payee_rec.Pay_Reason_Code);
      FETCH pmt_reasons_csr INTO l_count;
      CLOSE pmt_reasons_csr;

      IF (l_count = 0) THEN
			   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
				   print_debuginfo(l_module_name, 'InValid Payment Reason Code');
			   END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_TABLE_VAL_ERROR');
        FND_MESSAGE.SET_TOKEN('TABLE', 'IBY_PAYMENT_REASONS_VL');
        FND_MESSAGE.SET_TOKEN('VALUE', p_ext_payee_rec.Pay_Reason_Code);
        FND_MSG_PUB.Add;
        l_valid := FALSE;
      END IF;
    END IF;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Delivery Channel Code');
       print_debuginfo(l_module_name, 'Delivery Channel Code::'||p_ext_payee_rec.Delivery_Channel);
   END IF;

    -- 6. Validate Delivery Channel Code (table: IBY_DELIVERY_CHANNELS_VL by country)
    -- is not mandatory
    IF (p_ext_payee_rec.Delivery_Channel IS NOT NULL) THEN
      OPEN dlv_channels_csr(p_ext_payee_rec.Delivery_Channel);
      FETCH dlv_channels_csr INTO l_count;
      CLOSE dlv_channels_csr;

      IF (l_count = 0) THEN
			   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
				   print_debuginfo(l_module_name, 'InValid Delivery Channel');
			   END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_TABLE_VAL_ERROR');
        FND_MESSAGE.SET_TOKEN('TABLE', 'IBY_DELIVERY_CHANNELS_VL');
        FND_MESSAGE.SET_TOKEN('VALUE', p_ext_payee_rec.Delivery_Channel);
        FND_MSG_PUB.Add;
        l_valid := FALSE;
      END IF;
    END IF;


    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Payment Format Code');
       print_debuginfo(l_module_name, 'Payment Format Code::'||p_ext_payee_rec.Pmt_Format);
   END IF;
    -- 7. Validate Payment Format Code (table: IBY_FORMATS_VL)
    -- is not mandatory
    IF (p_ext_payee_rec.Pmt_Format IS NOT NULL) THEN
     OPEN payment_formats_csr(p_ext_payee_rec.Pmt_Format);
     FETCH payment_formats_csr INTO l_count;
     CLOSE payment_formats_csr;

      IF (l_count = 0) THEN
			   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
				   print_debuginfo(l_module_name, 'InValid Payment Format Code');
			   END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_TABLE_VAL_ERROR');
        FND_MESSAGE.SET_TOKEN('TABLE', 'IBY_FORMATS_VL');
        FND_MESSAGE.SET_TOKEN('VALUE', p_ext_payee_rec.Pmt_Format);
        FND_MSG_PUB.Add;
        l_valid := FALSE;
      END IF;
    END IF;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Validate Settlement Priority');
       print_debuginfo(l_module_name, 'Settlement Priority::'||p_ext_payee_rec.Settlement_Priority);
   END IF;
    -- 8. Validate Settlement Priority (lookup: IBY_SETTLEMENT_PRIORITY)
    -- is not mandatory
    IF (p_ext_payee_rec.Settlement_Priority IS NOT NULL) THEN
      l_temp_valid := CheckInLookup(p_ext_payee_rec.Settlement_Priority,
                                    'IBY_SETTLEMENT_PRIORITY');
      l_valid := l_valid AND l_temp_valid;
    END IF;

    -- Return Error if any validations has failed.
    IF (NOT l_valid) THEN
			 IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
			   print_debuginfo(l_module_name, 'Returning Error Status');
		   END IF;
       x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

    -- End of API body

    -- get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                              p_count => x_msg_count,
                              p_data  => x_msg_data);

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'Exit');
   END IF;
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO Validate_External_Payee_pub;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO Validate_External_Payee_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN OTHERS THEN
      ROLLBACK TO Validate_External_Payee_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_message.set_name('IBY', 'IBY_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


END Validate_External_Payee;


   -- Create_Temp_Ext_Bank_Acct
   --
   --   API name        : Create_Temp_Ext_Bank_Acct
   --   Type            : Public
   --   Pre-reqs        : None
   --   Function        : Create_Temp_Ext_Bank_Acct
   --   Current version : 1.0
   --   Previous version: 1.0
   --   Initial version : 1.0

PROCEDURE Create_Temp_Ext_Bank_Acct (
     p_api_version	IN	NUMBER,
     p_init_msg_list	IN	VARCHAR2 default FND_API.G_FALSE,
     x_return_status	OUT	NOCOPY VARCHAR2,
     x_msg_count	OUT	NOCOPY NUMBER,
     x_msg_data		OUT	NOCOPY VARCHAR2,
     p_temp_ext_acct_id	IN	NUMBER,
     x_bank_acc_id	OUT	NOCOPY Number,
     x_response		OUT	NOCOPY IBY_FNDCPT_COMMON_PUB.Result_rec_type
) IS

  l_api_name           CONSTANT VARCHAR2(30)   := 'Create_Temp_Ext_Bank_Acct';
  l_api_version        CONSTANT NUMBER         := 1.0;
  l_module_name        CONSTANT VARCHAR2(200)  := G_PKG_NAME || '.' || l_api_name;

  CURSOR iby_ext_bank_csr(p_temp_ext_acct_id NUMBER)
  IS
  SELECT
     EXT_BANK_ACCOUNT_ID,
     COUNTRY_CODE,
     BRANCH_ID,
     BANK_ID,
     BANK_NAME,
     BANK_NUMBER,
     BANK_NAME_ALT,
     BANK_INSTITUTION_TYPE,
     BANK_ADDRESS_ID,
     BRANCH_NUMBER,
     BRANCH_TYPE,
     BRANCH_NAME,
     BRANCH_NAME_ALT,
     BIC,
     RFC_IDENTIFIER,
     BANK_CODE,
     BRANCH_ADDRESS_ID,
     ACCOUNT_OWNER_PARTY_ID,
     OWNER_PRIMARY_FLAG,
     BANK_ACCOUNT_NAME,
     BANK_ACCOUNT_NUM,
     CURRENCY_CODE,
     IBAN,
     CHECK_DIGITS,
     BANK_ACCOUNT_NAME_ALT,
     BANK_ACCOUNT_TYPE,
     ACCOUNT_SUFFIX,
     DESCRIPTION,
     AGENCY_LOCATION_CODE,
     PAYMENT_FACTOR_FLAG,
     FOREIGN_PAYMENT_USE_FLAG,
     EXCHANGE_RATE_AGREEMENT_NUM,
     EXCHANGE_RATE_AGREEMENT_TYPE,
     EXCHANGE_RATE,
     START_DATE,
     END_DATE,
     ATTRIBUTE_CATEGORY,
     NOTE,
     NOTE_ALT,
     ATTRIBUTE1,
     ATTRIBUTE2,
     ATTRIBUTE3,
     ATTRIBUTE4,
     ATTRIBUTE5,
     ATTRIBUTE6,
     ATTRIBUTE7,
     ATTRIBUTE8,
     ATTRIBUTE9,
     ATTRIBUTE10,
     ATTRIBUTE11,
     ATTRIBUTE12,
     ATTRIBUTE13,
     ATTRIBUTE14,
     ATTRIBUTE15,
     STATUS,
     LAST_UPDATE_DATE,
     LAST_UPDATED_BY,
     CREATION_DATE,
     CREATED_BY,
     LAST_UPDATE_LOGIN,
     REQUEST_ID,
     PROGRAM_APPLICATION_ID,
     PROGRAM_ID,
     PROGRAM_UPDATE_DATE,
     OBJECT_VERSION_NUMBER,
     CALLING_APP_UNIQUE_REF1,
     CALLING_APP_UNIQUE_REF2,
     EXT_PAYEE_ID
  FROM IBY_TEMP_EXT_BANK_ACCTS
  WHERE TEMP_EXT_BANK_ACCT_ID = p_temp_ext_acct_id;

  temp_ext_bank_acct_rec iby_ext_bank_csr%ROWTYPE;
  ext_bank_acct_rec      IBY_EXT_BANKACCT_PUB.ExtBankAcct_rec_type;

  BEGIN

    SAVEPOINT Create_Temp_Ext_Bank_Acct_pub;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.Compatible_API_Call(l_api_version,
                                       p_api_version,
                                       l_api_name,
                                       G_PKG_NAME) THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
       FND_MSG_PUB.initialize;
    END IF;

    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Start of API body
    OPEN iby_ext_bank_csr(p_temp_ext_acct_id);
    FETCH iby_ext_bank_csr INTO temp_ext_bank_acct_rec;
    CLOSE iby_ext_bank_csr;

    ext_bank_acct_rec.country_code   := temp_ext_bank_acct_rec.COUNTRY_CODE;
    ext_bank_acct_rec.branch_id      := temp_ext_bank_acct_rec.branch_id;
    ext_bank_acct_rec.bank_id        := temp_ext_bank_acct_rec.bank_id;
    ext_bank_acct_rec.acct_owner_party_id := temp_ext_bank_acct_rec.ACCOUNT_OWNER_PARTY_ID;
    ext_bank_acct_rec.bank_account_name   := temp_ext_bank_acct_rec.bank_account_name;
    ext_bank_acct_rec.bank_account_num    := temp_ext_bank_acct_rec.bank_account_num;
    ext_bank_acct_rec.currency            := temp_ext_bank_acct_rec.CURRENCY_CODE;
    ext_bank_acct_rec.iban                := temp_ext_bank_acct_rec.iban;
    ext_bank_acct_rec.check_digits        := temp_ext_bank_acct_rec.check_digits;
    ext_bank_acct_rec.alternate_acct_name := temp_ext_bank_acct_rec.BANK_ACCOUNT_NAME_ALT;
    ext_bank_acct_rec.acct_type           := temp_ext_bank_acct_rec.BANK_ACCOUNT_TYPE;
    ext_bank_acct_rec.acct_suffix         := temp_ext_bank_acct_rec.ACCOUNT_SUFFIX;
    ext_bank_acct_rec.description         := temp_ext_bank_acct_rec.description;
    ext_bank_acct_rec.agency_location_code := temp_ext_bank_acct_rec.agency_location_code;
    ext_bank_acct_rec.foreign_payment_use_flag := temp_ext_bank_acct_rec.foreign_payment_use_flag;
    ext_bank_acct_rec.exchange_rate_agreement_num := temp_ext_bank_acct_rec.exchange_rate_agreement_num;
    ext_bank_acct_rec.exchange_rate_agreement_type := temp_ext_bank_acct_rec.exchange_rate_agreement_type;
    ext_bank_acct_rec.exchange_rate                := temp_ext_bank_acct_rec.exchange_rate;
    ext_bank_acct_rec.payment_factor_flag          := temp_ext_bank_acct_rec.payment_factor_flag;
    ext_bank_acct_rec.end_date                     := temp_ext_bank_acct_rec.end_date;
    ext_bank_acct_rec.START_DATE                   := temp_ext_bank_acct_rec.START_DATE;
    ext_bank_acct_rec.attribute_category           := temp_ext_bank_acct_rec.attribute_category;
    ext_bank_acct_rec.attribute1                   := temp_ext_bank_acct_rec.attribute1;
    ext_bank_acct_rec.attribute2                   := temp_ext_bank_acct_rec.attribute2;
    ext_bank_acct_rec.attribute3                   := temp_ext_bank_acct_rec.attribute3;
    ext_bank_acct_rec.attribute4                   := temp_ext_bank_acct_rec.attribute4;
    ext_bank_acct_rec.attribute5                   := temp_ext_bank_acct_rec.attribute5;
    ext_bank_acct_rec.attribute6                   := temp_ext_bank_acct_rec.attribute6;
    ext_bank_acct_rec.attribute7                   := temp_ext_bank_acct_rec.attribute7;
    ext_bank_acct_rec.attribute8                   := temp_ext_bank_acct_rec.attribute8;
    ext_bank_acct_rec.attribute9                   := temp_ext_bank_acct_rec.attribute9;
    ext_bank_acct_rec.attribute10                  := temp_ext_bank_acct_rec.attribute10;
    ext_bank_acct_rec.attribute11                  := temp_ext_bank_acct_rec.attribute11;
    ext_bank_acct_rec.attribute12                  := temp_ext_bank_acct_rec.attribute12;
    ext_bank_acct_rec.attribute13                  := temp_ext_bank_acct_rec.attribute13;
    ext_bank_acct_rec.attribute14                  := temp_ext_bank_acct_rec.attribute14;
    ext_bank_acct_rec.attribute15                  := temp_ext_bank_acct_rec.attribute15;

    -- Calling to create external bank account
    IBY_EXT_BANKACCT_PUB.create_ext_bank_acct(
      p_api_version               => 1.0,
      p_init_msg_list             => 'F',
      p_ext_bank_acct_rec         => ext_bank_acct_rec,
      x_acct_id			          => x_bank_acc_id,
      x_return_status             => x_return_status,
      x_msg_count                 => x_msg_count,
      x_msg_data                  => x_msg_data,
      x_response                  => x_response
   );



   IF (x_bank_acc_id IS NULL) THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   END IF;
    -- End of API body

    -- get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                              p_count => x_msg_count,
                              p_data  => x_msg_data);


  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO Create_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO Create_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN OTHERS THEN
      ROLLBACK TO Create_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_message.set_name('IBY', 'IBY_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

END Create_Temp_Ext_Bank_Acct;

   --Modified for the bug 6461487
   -- Create_Temp_Ext_Bank_Acct  -- overloaded
   --
   --   API name        : Create_Temp_Ext_Bank_Acct
   --   Type            : Public
   --   Pre-reqs        : None
   --   Function        : Create_Temp_Ext_Bank_Acct
   --   Current version : 1.0
   --   Previous version: 1.0
   --   Initial version : 1.0

PROCEDURE Create_Temp_Ext_Bank_Acct (
     p_api_version	IN	NUMBER,
     p_init_msg_list	IN	VARCHAR2 default FND_API.G_FALSE,
     x_return_status	OUT	NOCOPY VARCHAR2,
     x_msg_count	OUT	NOCOPY NUMBER,
     x_msg_data		OUT	NOCOPY VARCHAR2,
     p_temp_ext_acct_id	IN	NUMBER,
     p_association_level IN VARCHAR2,
     p_supplier_site_id  IN NUMBER,
     p_party_site_id     IN NUMBER,
     p_org_id            IN NUMBER,
     p_org_type          IN VARCHAR2 default NULL,
     x_bank_acc_id	OUT	NOCOPY Number,
     x_response		OUT	NOCOPY IBY_FNDCPT_COMMON_PUB.Result_rec_type
) IS

  l_api_name           CONSTANT VARCHAR2(30)   := 'Create_Temp_Ext_Bank_Acct';
  l_api_version        CONSTANT NUMBER         := 1.0;
  l_module_name        CONSTANT VARCHAR2(200)  := G_PKG_NAME || '.' || l_api_name;
  l_dup_acct_id        number;
  l_acct_owner_id      number;
  l_dup_start_date     date;
  l_dup_end_date       date;
  l_assign_id         NUMBER;
  l_rec      IBY_DISBURSEMENT_SETUP_PUB.PayeeContext_rec_type;
  l_assign   IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_rec_type;



CURSOR iby_ext_bank_csr(p_temp_ext_acct_id NUMBER)
  IS
  SELECT
     EXT_BANK_ACCOUNT_ID,
     COUNTRY_CODE,
     BRANCH_ID,
     BANK_ID,
     BANK_NAME,
     BANK_NUMBER,
     BANK_NAME_ALT,
     BANK_INSTITUTION_TYPE,
     BANK_ADDRESS_ID,
     BRANCH_NUMBER,
     BRANCH_TYPE,
     BRANCH_NAME,
     BRANCH_NAME_ALT,
     BIC,
     RFC_IDENTIFIER,
     BANK_CODE,
     BRANCH_ADDRESS_ID,
     ACCOUNT_OWNER_PARTY_ID,
     OWNER_PRIMARY_FLAG,
     BANK_ACCOUNT_NAME,
     BANK_ACCOUNT_NUM,
     CURRENCY_CODE,
     IBAN,
     CHECK_DIGITS,
     BANK_ACCOUNT_NAME_ALT,
     BANK_ACCOUNT_TYPE,
     ACCOUNT_SUFFIX,
     DESCRIPTION,
     AGENCY_LOCATION_CODE,
     PAYMENT_FACTOR_FLAG,
     FOREIGN_PAYMENT_USE_FLAG,
     EXCHANGE_RATE_AGREEMENT_NUM,
     EXCHANGE_RATE_AGREEMENT_TYPE,
     EXCHANGE_RATE,
     START_DATE,
     END_DATE,
     ATTRIBUTE_CATEGORY,
     NOTE,
     NOTE_ALT,
     ATTRIBUTE1,
     ATTRIBUTE2,
     ATTRIBUTE3,
     ATTRIBUTE4,
     ATTRIBUTE5,
     ATTRIBUTE6,
     ATTRIBUTE7,
     ATTRIBUTE8,
     ATTRIBUTE9,
     ATTRIBUTE10,
     ATTRIBUTE11,
     ATTRIBUTE12,
     ATTRIBUTE13,
     ATTRIBUTE14,
     ATTRIBUTE15,
     STATUS,
     LAST_UPDATE_DATE,
     LAST_UPDATED_BY,
     CREATION_DATE,
     CREATED_BY,
     LAST_UPDATE_LOGIN,
     REQUEST_ID,
     PROGRAM_APPLICATION_ID,
     PROGRAM_ID,
     PROGRAM_UPDATE_DATE,
     OBJECT_VERSION_NUMBER,
     CALLING_APP_UNIQUE_REF1,
     CALLING_APP_UNIQUE_REF2,
     EXT_PAYEE_ID
  FROM IBY_TEMP_EXT_BANK_ACCTS
  WHERE TEMP_EXT_BANK_ACCT_ID = p_temp_ext_acct_id;

  temp_ext_bank_acct_rec iby_ext_bank_csr%ROWTYPE;
  ext_bank_acct_rec      IBY_EXT_BANKACCT_PUB.ExtBankAcct_rec_type;
  -- Bug# 7451534 Begin
    intermediate_bank_acct_rec IBY_EXT_BANKACCT_PUB.IntermediaryAcct_rec_type;
    x_intmediary_bank_acct_id NUMBER;
    x_intermediary_return_status VARCHAR2(100);
    x_intermediary_msg_count NUMBER;
    x_intermediary_msg_data VARCHAR2(100);
    x_intermediary_response IBY_FNDCPT_COMMON_PUB.Result_rec_type;
  -- Bug# 7451534 End

  BEGIN
  IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	  print_debuginfo(l_module_name, 'ENTER');
  END IF;
    SAVEPOINT Create_Temp_Ext_Bank_Acct_pub;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.Compatible_API_Call(l_api_version,
                                       p_api_version,
                                       l_api_name,
                                       G_PKG_NAME) THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
       FND_MSG_PUB.initialize;
    END IF;

    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Start of API body
    OPEN iby_ext_bank_csr(p_temp_ext_acct_id);
    FETCH iby_ext_bank_csr INTO temp_ext_bank_acct_rec;
    CLOSE iby_ext_bank_csr;

    ext_bank_acct_rec.country_code   := temp_ext_bank_acct_rec.COUNTRY_CODE;
    ext_bank_acct_rec.branch_id      := temp_ext_bank_acct_rec.branch_id;
    ext_bank_acct_rec.bank_id        := temp_ext_bank_acct_rec.bank_id;
    ext_bank_acct_rec.acct_owner_party_id := temp_ext_bank_acct_rec.ACCOUNT_OWNER_PARTY_ID;
    ext_bank_acct_rec.bank_account_name   := temp_ext_bank_acct_rec.bank_account_name;
    ext_bank_acct_rec.bank_account_num    := temp_ext_bank_acct_rec.bank_account_num;
    ext_bank_acct_rec.currency            := temp_ext_bank_acct_rec.CURRENCY_CODE;
    ext_bank_acct_rec.iban                := temp_ext_bank_acct_rec.iban;
    ext_bank_acct_rec.check_digits        := temp_ext_bank_acct_rec.check_digits;
    ext_bank_acct_rec.alternate_acct_name := temp_ext_bank_acct_rec.BANK_ACCOUNT_NAME_ALT;
    ext_bank_acct_rec.acct_type           := temp_ext_bank_acct_rec.BANK_ACCOUNT_TYPE;
    ext_bank_acct_rec.acct_suffix         := temp_ext_bank_acct_rec.ACCOUNT_SUFFIX;
    ext_bank_acct_rec.description         := temp_ext_bank_acct_rec.description;
    ext_bank_acct_rec.agency_location_code := temp_ext_bank_acct_rec.agency_location_code;
    ext_bank_acct_rec.foreign_payment_use_flag := temp_ext_bank_acct_rec.foreign_payment_use_flag;
    ext_bank_acct_rec.exchange_rate_agreement_num := temp_ext_bank_acct_rec.exchange_rate_agreement_num;
    ext_bank_acct_rec.exchange_rate_agreement_type := temp_ext_bank_acct_rec.exchange_rate_agreement_type;
    ext_bank_acct_rec.exchange_rate                := temp_ext_bank_acct_rec.exchange_rate;
    ext_bank_acct_rec.payment_factor_flag          := temp_ext_bank_acct_rec.payment_factor_flag;
    ext_bank_acct_rec.end_date                     := temp_ext_bank_acct_rec.end_date;
    ext_bank_acct_rec.START_DATE                   := temp_ext_bank_acct_rec.START_DATE;
    ext_bank_acct_rec.attribute_category           := temp_ext_bank_acct_rec.attribute_category;
    ext_bank_acct_rec.attribute1                   := temp_ext_bank_acct_rec.attribute1;
    ext_bank_acct_rec.attribute2                   := temp_ext_bank_acct_rec.attribute2;
    ext_bank_acct_rec.attribute3                   := temp_ext_bank_acct_rec.attribute3;
    ext_bank_acct_rec.attribute4                   := temp_ext_bank_acct_rec.attribute4;
    ext_bank_acct_rec.attribute5                   := temp_ext_bank_acct_rec.attribute5;
    ext_bank_acct_rec.attribute6                   := temp_ext_bank_acct_rec.attribute6;
    ext_bank_acct_rec.attribute7                   := temp_ext_bank_acct_rec.attribute7;
    ext_bank_acct_rec.attribute8                   := temp_ext_bank_acct_rec.attribute8;
    ext_bank_acct_rec.attribute9                   := temp_ext_bank_acct_rec.attribute9;
    ext_bank_acct_rec.attribute10                  := temp_ext_bank_acct_rec.attribute10;
    ext_bank_acct_rec.attribute11                  := temp_ext_bank_acct_rec.attribute11;
    ext_bank_acct_rec.attribute12                  := temp_ext_bank_acct_rec.attribute12;
    ext_bank_acct_rec.attribute13                  := temp_ext_bank_acct_rec.attribute13;
    ext_bank_acct_rec.attribute14                  := temp_ext_bank_acct_rec.attribute14;
    ext_bank_acct_rec.attribute15                  := temp_ext_bank_acct_rec.attribute15;


    /* CAll to verify if bank account is already created in the application*/
	IBY_EXT_BANKACCT_PUB.check_ext_acct_exist(
	    p_api_version               => 1.0,
	    p_init_msg_list             => 'F',
	    p_ext_bank_acct_rec         => ext_bank_acct_rec,
	    x_acct_id                   => l_dup_acct_id,
	    x_start_date                => l_dup_start_date,
	    x_end_date                  => l_dup_end_date,
	    x_return_status             => x_return_status,
	    x_msg_count                 => x_msg_count,
	    x_msg_data                  => x_msg_data,
	    x_response                  => x_response
	    );
   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'After the call to check_ext_acct_exist');
  	   print_debuginfo(l_module_name, 'X_RETURN_STATUS::'||x_return_status);
	   print_debuginfo(l_module_name, 'Account Id::'||l_dup_acct_id);
   END IF;

    /* If bank account doesn't exist in the application*/
    IF (x_return_status = FND_API.G_RET_STS_SUCCESS and l_dup_acct_id is null) THEN


	    /* Calling Bank Account Validation API */
	  IBY_DISBURSEMENT_SETUP_PUB.Validate_Temp_Ext_Bank_Acct(
	     p_api_version         => 1.0,
	     p_init_msg_list       => FND_API.G_FALSE,
	     x_return_status       => x_return_status,
	     x_msg_count           => x_msg_count,
	     x_msg_data            => x_msg_data,
	     p_temp_ext_acct_id    => p_temp_ext_acct_id);

	   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
		   print_debuginfo(l_module_name, 'After the call to Validate_Temp_Ext_Bank_Acct');
		   print_debuginfo(l_module_name, 'Return Status::'||x_return_status);
	   END IF;

           IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN

		    -- Calling to create external bank account
		    IBY_EXT_BANKACCT_PUB.create_ext_bank_acct(
		      p_api_version               => 1.0,
		      p_init_msg_list             => 'F',
		      p_ext_bank_acct_rec         => ext_bank_acct_rec,
		      p_association_level         => p_association_level,
		      p_supplier_site_id          => p_supplier_site_id ,
		      p_party_site_id             => p_party_site_id ,
		      p_org_id                    => p_org_id ,
		      p_org_type                  => p_org_type,
		      x_acct_id		          => x_bank_acc_id,
		      x_return_status             => x_return_status,
		      x_msg_count                 => x_msg_count,
		      x_msg_data                  => x_msg_data,
		      x_response                  => x_response
		   );

		   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
			   print_debuginfo(l_module_name, 'After the call to create_ext_bank_accout');
			   print_debuginfo(l_module_name, 'Ext Bank Acct Id::'||x_bank_acc_id);
			   print_debuginfo(l_module_name, 'Return Status::'||x_return_status);
		   END IF;

		   IF (x_bank_acc_id IS NULL) THEN
		      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
		   END IF;
           ELSE
		    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
	            FND_MESSAGE.SET_NAME('SQLAP','AP_INVALID_BANK_ACCT_INFO');
                    FND_MSG_PUB.ADD;
                    print_debuginfo(l_module_name, 'Bank Account Validation Failed');
	   END IF;

/* If Bank account is already existing in the application*/
   ELSIF (l_dup_acct_id is not null) THEN
           x_return_status := FND_API.G_RET_STS_SUCCESS;

	   /* API call to find out whether this party is owner of bank account*/
	   IBY_EXT_BANKACCT_PUB.check_bank_acct_owner (
	   p_api_version                => 1.0,
	   p_init_msg_list              => 'F',
	   p_bank_acct_id               => l_dup_acct_id,
	   p_acct_owner_party_id        => ext_bank_acct_rec.acct_owner_party_id,
	   x_return_status              => x_return_status,
	   x_msg_count                  => x_msg_count,
	   x_msg_data                   => x_msg_data,
	   x_response                   => x_response
	   );
	   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
		   print_debuginfo(l_module_name, 'After the call to check_bank_acct_owner');
		   print_debuginfo(l_module_name, 'X_RETURN_STATUS::'||x_return_status);
	   END IF;

           /* If party is not owner of that bank account*/
           IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

			    /* Add Party Id as Joint Account Owner of the Bank Account*/
			     IBY_EXT_BANKACCT_PUB.add_joint_account_owner (
					   p_api_version             => 1.0,
					   p_init_msg_list           => 'F',
					   p_bank_account_id         => l_dup_acct_id,
					   p_acct_owner_party_id     => ext_bank_acct_rec.acct_owner_party_id,
					   x_joint_acct_owner_id	 => l_acct_owner_id,
					   x_return_status           => x_return_status,
					   x_msg_count               => x_msg_count,
					   x_msg_data                => x_msg_data,
					   x_response                => x_response
					  );

			   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
				   print_debuginfo(l_module_name, 'After the call to add_joint_account_owner');
				   print_debuginfo(l_module_name, 'X_RETURN_STATUS::'||x_return_status);
				   print_debuginfo(l_module_name, 'l_acct_owner_id::'||l_acct_owner_id);
			   END IF;

           END IF;

		l_rec.Party_Site_id :=p_party_site_id;
		l_rec.Supplier_Site_id:=p_supplier_site_id;
		l_rec.Org_Id:=p_org_id;
		l_rec.Org_Type:=p_org_type;
		l_rec.Payment_Function :='PAYABLES_DISB';
		l_rec.Party_Id :=ext_bank_acct_rec.acct_owner_party_id;
		l_assign.Instrument.Instrument_Type := 'BANKACCOUNT';
		l_assign.Instrument.Instrument_Id := l_dup_acct_id;

		/* API call to assing the bank account to the Payee*/
                IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment(
		p_api_version            =>   p_api_version,
		p_init_msg_list    	 =>   'F',
		p_commit           	 =>   NULL,
		x_return_status    	 =>   x_return_status,
		x_msg_count        	 =>   x_msg_count,
		x_msg_data         	 =>   x_msg_data,
		p_payee            	 =>   l_rec,
		p_assignment_attribs	 =>   l_assign,
		x_assign_id        	 =>   l_assign_id,
		x_response         	 =>   x_response);

		IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
		   print_debuginfo(l_module_name, 'After the call to Set_Payee_Instr_Assignment');
		   print_debuginfo(l_module_name, 'Assignment Id::'||l_assign_id);
		   print_debuginfo(l_module_name, 'X_RETURN_STATUS::'||x_return_status);
		END IF;

	   /*ELSE
	        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
	            FND_MESSAGE.SET_NAME('IBY','IBY_IMP_SUP_NOT_OWN');
                    FND_MSG_PUB.ADD;
		IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
		   print_debuginfo(l_module_name, 'Party is not owner of the account');
		END IF;

	   END IF;*/
   ELSE
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
	IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'check_ext_acct_exist returned inconsistent data');
	END IF;
   END IF;

   IF( x_return_status = FND_API.G_RET_STS_SUCCESS)     THEN

		   -- Bug# 7451534 begin

		   intermediate_bank_acct_rec.bank_account_id := x_bank_acc_id;
		   intermediate_bank_acct_rec.object_version_number :=1;
		   -- Calling Create_intermediary_acct to create record for Intermediary Bank Account1
		   IBY_EXT_BANKACCT_PUB.create_intermediary_acct (
		      p_api_version               => 1.0,
		      p_init_msg_list             => 'F',
		      p_intermed_acct_rec=>intermediate_bank_acct_rec,
			x_intermediary_acct_id => x_intmediary_bank_acct_id,
			x_return_status        => x_intermediary_return_status,
			x_msg_count            => x_intermediary_msg_count,
			x_msg_data             => x_intermediary_msg_data,
			x_response             => x_intermediary_response
		  );
		  -- Calling Create_intermediary_acct to create record for Intermediary Bank Account2
		  IBY_EXT_BANKACCT_PUB.create_intermediary_acct (
			p_api_version               => 1.0,
			p_init_msg_list             => 'F',
			p_intermed_acct_rec=>intermediate_bank_acct_rec,
			x_intermediary_acct_id => x_intmediary_bank_acct_id,
			x_return_status        => x_intermediary_return_status,
			x_msg_count            => x_intermediary_msg_count,
			x_msg_data             => x_intermediary_msg_data,
			x_response             => x_intermediary_response
		  );
		  -- Bug# 7451534 Online modification to test End
		    -- End of API body
     END IF;

    -- get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                              p_count => x_msg_count,
                              p_data  => x_msg_data);

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	    print_debuginfo(l_module_name, 'EXIT');
    END IF;
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO Create_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO Create_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN OTHERS THEN
      ROLLBACK TO Create_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_message.set_name('IBY', 'IBY_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

END Create_Temp_Ext_Bank_Acct;






   -- Validate_Temp_Ext_Bank_Acct
   --
   --   API name        : Validate_Temp_Ext_Bank_Acct
   --   Type            : Public
   --   Pre-reqs        : None
   --   Function        : Validate_Temp_Ext_Bank_Acct
   --   Current version : 1.0
   --   Previous version: 1.0
   --   Initial version : 1.0

PROCEDURE Validate_Temp_Ext_Bank_Acct (
     p_api_version	    IN	NUMBER,
     p_init_msg_list	IN	VARCHAR2 default FND_API.G_FALSE,
     x_return_status	OUT	NOCOPY VARCHAR2,
     x_msg_count	    OUT	NOCOPY NUMBER,
     x_msg_data		    OUT	NOCOPY VARCHAR2,
     p_temp_ext_acct_id	IN	NUMBER
) IS

  l_api_name           CONSTANT VARCHAR2(30)   := 'Validate_Temp_Ext_Bank_Acct';
  l_api_version        CONSTANT NUMBER         := 1.0;
  l_module_name        CONSTANT VARCHAR2(200)  := G_PKG_NAME || '.' || l_api_name;

  CURSOR ext_bank_acct_csr(p_temp_ext_acct_id NUMBER)
  IS
  SELECT
     EXT_BANK_ACCOUNT_ID,
     COUNTRY_CODE,
     BRANCH_ID,
     BANK_ID,
     BANK_NAME,
     BANK_NUMBER,
     BANK_NAME_ALT,
     BANK_INSTITUTION_TYPE,
     BANK_ADDRESS_ID,
     BRANCH_NUMBER,
     BRANCH_TYPE,
     BRANCH_NAME,
     BRANCH_NAME_ALT,
     BIC,
     RFC_IDENTIFIER,
     BANK_CODE,
     BRANCH_ADDRESS_ID,
     ACCOUNT_OWNER_PARTY_ID,
     OWNER_PRIMARY_FLAG,
     BANK_ACCOUNT_NAME,
     BANK_ACCOUNT_NUM,
     CURRENCY_CODE,
     IBAN,
     CHECK_DIGITS,
     BANK_ACCOUNT_NAME_ALT,
     BANK_ACCOUNT_TYPE,
     ACCOUNT_SUFFIX,
     DESCRIPTION,
     AGENCY_LOCATION_CODE,
     PAYMENT_FACTOR_FLAG,
     FOREIGN_PAYMENT_USE_FLAG,
     EXCHANGE_RATE_AGREEMENT_NUM,
     EXCHANGE_RATE_AGREEMENT_TYPE,
     EXCHANGE_RATE,
     START_DATE,
     END_DATE,
     ATTRIBUTE_CATEGORY,
     NOTE,
     NOTE_ALT,
     ATTRIBUTE1,
     ATTRIBUTE2,
     ATTRIBUTE3,
     ATTRIBUTE4,
     ATTRIBUTE5,
     ATTRIBUTE6,
     ATTRIBUTE7,
     ATTRIBUTE8,
     ATTRIBUTE9,
     ATTRIBUTE10,
     ATTRIBUTE11,
     ATTRIBUTE12,
     ATTRIBUTE13,
     ATTRIBUTE14,
     ATTRIBUTE15,
     STATUS,
     LAST_UPDATE_DATE,
     LAST_UPDATED_BY,
     CREATION_DATE,
     CREATED_BY,
     LAST_UPDATE_LOGIN,
     REQUEST_ID,
     PROGRAM_APPLICATION_ID,
     PROGRAM_ID,
     PROGRAM_UPDATE_DATE,
     OBJECT_VERSION_NUMBER,
     CALLING_APP_UNIQUE_REF1,
     CALLING_APP_UNIQUE_REF2,
     EXT_PAYEE_ID
  FROM IBY_TEMP_EXT_BANK_ACCTS
  WHERE TEMP_EXT_BANK_ACCT_ID = p_temp_ext_acct_id;

  temp_ext_bank_acct_rec ext_bank_acct_csr%ROWTYPE;
  ext_bank_acct_rec      IBY_EXT_BANKACCT_PUB.ExtBankAcct_rec_type;
  ext_bank_rec           IBY_EXT_BANKACCT_PUB.ExtBank_rec_type;
  ext_bank_branch_rec    IBY_EXT_BANKACCT_PUB.ExtBankBranch_rec_type;
  l_response             IBY_FNDCPT_COMMON_PUB.Result_rec_type;

  CURSOR ext_bank_csr(p_bank_id NUMBER)
  IS
     SELECT BANK_PARTY_ID,
            bank_name,
            bank_number,
            BANK_INSTITUTION_TYPE,
            HOME_COUNTRY,
            BANK_NAME_ALT,
            description,
            SHORT_BANK_NAME
       FROM CE_BANKS_V
      WHERE BANK_PARTY_ID = p_bank_id;

   temp_ext_bank_rec    ext_bank_csr%ROWTYPE;

   CURSOR ext_bank_branch_csr(p_bank_id NUMBER,
                              p_bank_branch_id NUMBER)
   IS
     SELECT branch_party_id,
            bank_party_id,
            BANK_BRANCH_NAME,
            branch_number,
	        BANK_BRANCH_TYPE,
            BANK_BRANCH_NAME_ALT
       FROM CE_BANK_BRANCHES_V
      WHERE bank_party_id = p_bank_id
        AND branch_party_id = p_bank_branch_id;

    temp_ext_bank_branch_rec   ext_bank_branch_csr%ROWTYPE;

  BEGIN

    SAVEPOINT Val_Temp_Ext_Bank_Acct_pub;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.Compatible_API_Call(l_api_version,
                                       p_api_version,
                                       l_api_name,
                                       G_PKG_NAME) THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
       FND_MSG_PUB.initialize;
    END IF;

    --  Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Start of API body

    OPEN ext_bank_acct_csr(p_temp_ext_acct_id);
    FETCH ext_bank_acct_csr INTO temp_ext_bank_acct_rec;
    CLOSE ext_bank_acct_csr;

    ext_bank_acct_rec.country_code                 := temp_ext_bank_acct_rec.COUNTRY_CODE;
    ext_bank_acct_rec.branch_id                    := temp_ext_bank_acct_rec.branch_id;
    ext_bank_acct_rec.bank_id                      := temp_ext_bank_acct_rec.bank_id;
    ext_bank_acct_rec.acct_owner_party_id          := temp_ext_bank_acct_rec.ACCOUNT_OWNER_PARTY_ID;
    ext_bank_acct_rec.bank_account_name            := temp_ext_bank_acct_rec.bank_account_name;
    ext_bank_acct_rec.bank_account_num             := temp_ext_bank_acct_rec.bank_account_num;
    ext_bank_acct_rec.currency                     := temp_ext_bank_acct_rec.CURRENCY_CODE;
    ext_bank_acct_rec.iban                         := temp_ext_bank_acct_rec.iban;
    ext_bank_acct_rec.check_digits                 := temp_ext_bank_acct_rec.check_digits;
    ext_bank_acct_rec.alternate_acct_name          := temp_ext_bank_acct_rec.BANK_ACCOUNT_NAME_ALT;
    ext_bank_acct_rec.acct_type                    := temp_ext_bank_acct_rec.BANK_ACCOUNT_TYPE;
    ext_bank_acct_rec.acct_suffix                  := temp_ext_bank_acct_rec.ACCOUNT_SUFFIX;
    ext_bank_acct_rec.description                  := temp_ext_bank_acct_rec.description;
    ext_bank_acct_rec.agency_location_code         := temp_ext_bank_acct_rec.agency_location_code;
    ext_bank_acct_rec.foreign_payment_use_flag     := temp_ext_bank_acct_rec.foreign_payment_use_flag;
    ext_bank_acct_rec.exchange_rate_agreement_num  := temp_ext_bank_acct_rec.exchange_rate_agreement_num;
    ext_bank_acct_rec.exchange_rate_agreement_type := temp_ext_bank_acct_rec.exchange_rate_agreement_type;
    ext_bank_acct_rec.exchange_rate                := temp_ext_bank_acct_rec.exchange_rate;
    ext_bank_acct_rec.payment_factor_flag          := temp_ext_bank_acct_rec.payment_factor_flag;
    ext_bank_acct_rec.end_date                     := temp_ext_bank_acct_rec.end_date;
    ext_bank_acct_rec.START_DATE                   := temp_ext_bank_acct_rec.START_DATE;
    ext_bank_acct_rec.attribute_category           := temp_ext_bank_acct_rec.attribute_category;
    ext_bank_acct_rec.attribute1                   := temp_ext_bank_acct_rec.attribute1;
    ext_bank_acct_rec.attribute2                   := temp_ext_bank_acct_rec.attribute2;
    ext_bank_acct_rec.attribute3                   := temp_ext_bank_acct_rec.attribute3;
    ext_bank_acct_rec.attribute4                   := temp_ext_bank_acct_rec.attribute4;
    ext_bank_acct_rec.attribute5                   := temp_ext_bank_acct_rec.attribute5;
    ext_bank_acct_rec.attribute6                   := temp_ext_bank_acct_rec.attribute6;
    ext_bank_acct_rec.attribute7                   := temp_ext_bank_acct_rec.attribute7;
    ext_bank_acct_rec.attribute8                   := temp_ext_bank_acct_rec.attribute8;
    ext_bank_acct_rec.attribute9                   := temp_ext_bank_acct_rec.attribute9;
    ext_bank_acct_rec.attribute10                  := temp_ext_bank_acct_rec.attribute10;
    ext_bank_acct_rec.attribute11                  := temp_ext_bank_acct_rec.attribute11;
    ext_bank_acct_rec.attribute12                  := temp_ext_bank_acct_rec.attribute12;
    ext_bank_acct_rec.attribute13                  := temp_ext_bank_acct_rec.attribute13;
    ext_bank_acct_rec.attribute14                  := temp_ext_bank_acct_rec.attribute14;
    ext_bank_acct_rec.attribute15                  := temp_ext_bank_acct_rec.attribute15;

    OPEN ext_bank_csr(temp_ext_bank_acct_rec.bank_id);
    FETCH ext_bank_csr INTO temp_ext_bank_rec;
    CLOSE ext_bank_csr;

    -- Populate the external bank branch record
    ext_bank_rec.bank_id                  := temp_ext_bank_rec.BANK_PARTY_ID;
    ext_bank_rec.bank_name                := temp_ext_bank_rec.bank_name;
    ext_bank_rec.bank_number              := temp_ext_bank_rec.bank_number;
    ext_bank_rec.institution_type         := temp_ext_bank_rec.BANK_INSTITUTION_TYPE;
    ext_bank_rec.country_code             := temp_ext_bank_rec.HOME_COUNTRY;
    ext_bank_rec.bank_alt_name            := temp_ext_bank_rec.BANK_NAME_ALT;
    ext_bank_rec.bank_short_name          := temp_ext_bank_rec.SHORT_BANK_NAME;
    ext_bank_rec.description              := temp_ext_bank_rec.description;

    OPEN ext_bank_branch_csr(temp_ext_bank_acct_rec.bank_id,
                             temp_ext_bank_acct_rec.branch_id);
    FETCH ext_bank_branch_csr INTO temp_ext_bank_branch_rec;
    CLOSE ext_bank_branch_csr;

    -- Populate the external bank branch record
    ext_bank_branch_rec.branch_party_id             := temp_ext_bank_branch_rec.branch_party_id;
    ext_bank_branch_rec.bank_party_id               := temp_ext_bank_branch_rec.bank_party_id;
    ext_bank_branch_rec.branch_name                 := temp_ext_bank_branch_rec.BANK_BRANCH_NAME;
    ext_bank_branch_rec.branch_number               := temp_ext_bank_branch_rec.branch_number;
    ext_bank_branch_rec.branch_type                 := temp_ext_bank_branch_rec.BANK_BRANCH_TYPE;
    ext_bank_branch_rec.alternate_branch_name       := temp_ext_bank_branch_rec.BANK_BRANCH_NAME_ALT;


    -- Call Validations
    IBY_EXT_BANKACCT_VALIDATIONS.iby_validate_account(
       p_api_version             => p_api_version,
       p_init_msg_list           => FND_API.G_TRUE,
       p_create_flag             => FND_API.G_TRUE,
       p_ext_bank_rec            => ext_bank_rec,
       p_ext_bank_branch_rec     => ext_bank_branch_rec,
       p_ext_bank_acct_rec       => ext_bank_acct_rec,
       x_return_status           => x_return_status,
       x_msg_count               => x_msg_count,
       x_msg_data                => x_msg_data,
       x_response                => l_response
     );

     IF (fnd_msg_pub.count_msg > 0) THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
     END IF;

    -- End of API body

    -- get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                              p_count => x_msg_count,
                              p_data  => x_msg_data);


  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO Val_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO Val_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);


    WHEN OTHERS THEN
      ROLLBACK TO Val_Temp_Ext_Bank_Acct_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_message.set_name('IBY', 'IBY_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;
      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

END Validate_Temp_Ext_Bank_Acct;

-- Public API

-- Start of comments
--   API name     : Update_External_Payee
--   Type         : Public
--   Pre-reqs     : None
--   Function     : Update payees for records passed in through the payee PL/SQL table
--   Parameters   :
--   IN           :   p_api_version              IN  NUMBER   Required
--                    p_init_msg_list            IN  VARCHAR2 Optional
--                    p_ext_payee_tab            IN  External_Payee_Tab_Type  Required
--   OUT          :   x_return_status            OUT VARCHAR2 Required
--                    x_msg_count                OUT NUMBER   Required
--                    x_msg_data                 OUT VARCHAR2 Required
--                    x_ext_payee_id_tab         OUT Ext_Payee_ID_Tab_Type
--                    x_ext_payee_status_tab     OUT Ext_Payee_Create_Tab_Type Required
--
--   Version   : Current version    1.0
--               Previous version   None
--               Initial version    1.0
-- End of comments

PROCEDURE Update_External_Payee (
     p_api_version           IN   NUMBER,
     p_init_msg_list         IN   VARCHAR2 default FND_API.G_FALSE,
     p_ext_payee_tab         IN   External_Payee_Tab_Type,
     p_ext_payee_id_tab      IN   Ext_Payee_ID_Tab_Type,
     x_return_status         OUT  NOCOPY VARCHAR2,
     x_msg_count             OUT  NOCOPY NUMBER,
     x_msg_data              OUT  NOCOPY VARCHAR2,
     x_ext_payee_status_tab  OUT  NOCOPY Ext_Payee_Update_Tab_Type) IS

  l_api_name           CONSTANT VARCHAR2(30)   := 'Create_External_Payee';
  l_api_version        CONSTANT NUMBER         := 1.0;
  l_module_name        CONSTANT VARCHAR2(200)  := G_PKG_NAME || '.Create_External_Payee';

  counter NUMBER;
  l_payee_cnt NUMBER;
  l_payee_id NUMBER;
  l_pm_count NUMBER;
  l_message FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE;
  l_primary_flag iby_ext_party_pmt_mthds.primary_flag%TYPE;

  l_ext_payee_upd_rec Ext_Payee_Update_Rec_Type;
  l_payee_upd_status VARCHAR2(30);

  CURSOR external_payee_csr(p_payee_party_id NUMBER,
                            p_party_site_id  NUMBER,
                            p_supplier_site_id NUMBER,
                            p_payer_org_id NUMBER,
                            p_payer_org_type VARCHAR2,
                            p_payment_function VARCHAR2)
  IS
      SELECT count(payee.EXT_PAYEE_ID), max(payee.EXT_PAYEE_ID)
        FROM iby_external_payees_all payee
       WHERE payee.PAYEE_PARTY_ID = p_payee_party_id
         AND payee.PAYMENT_FUNCTION = p_payment_function
         AND ((p_party_site_id is NULL and payee.PARTY_SITE_ID is NULL) OR
              (payee.PARTY_SITE_ID = p_party_site_id))
         AND ((p_supplier_site_id is NULL and payee.SUPPLIER_SITE_ID is NULL) OR
              (payee.SUPPLIER_SITE_ID = p_supplier_site_id))
         AND ((p_payer_org_id is NULL and payee.ORG_ID is NULL) OR
              (payee.ORG_ID = p_payer_org_id AND payee.ORG_TYPE = p_payer_org_type));

BEGIN
  IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	  print_debuginfo(l_module_name, 'ENTER');

  END IF;
  -- Standard call to check for call compatibility.
  IF NOT FND_API.Compatible_API_Call(l_api_version,
                                     p_api_version,
                                     l_api_name,
                                     G_PKG_NAME) THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

  -- Initialize message list if p_init_msg_list is set to TRUE.
  IF FND_API.to_Boolean(p_init_msg_list) THEN
    FND_MSG_PUB.initialize;
  END IF;

  --  Initialize API return status to success
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF p_ext_payee_tab.COUNT > 0 THEN
    counter := p_ext_payee_tab.FIRST;

    while (counter <= p_ext_payee_tab.LAST) loop
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name, 'Loop thru external payee ' || counter);

      END IF;
      IF p_ext_payee_id_tab(counter).Ext_Payee_ID IS NULL THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name,'Payee to update does not exist.');
        END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
        FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_EXT_PAYEE_ID'));
        l_message := fnd_message.get;
        FND_MSG_PUB.Add;

        l_ext_payee_upd_rec.Payee_Update_Status := 'E';
        l_ext_payee_upd_rec.Payee_Update_Msg := l_message;

        x_return_status := FND_API.G_RET_STS_ERROR;

      ELSIF p_ext_payee_tab(counter).Payee_Party_Id IS NULL THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name,'Payee party Id is null.');
        END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
        FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_PAYEE_PARTY_ID_FIELD'));
        l_message := fnd_message.get;
        FND_MSG_PUB.Add;

        l_ext_payee_upd_rec.Payee_Update_Status := 'E';
        l_ext_payee_upd_rec.Payee_Update_Msg := l_message;

        x_return_status := FND_API.G_RET_STS_ERROR;

      ELSIF (p_ext_payee_tab(counter).Payment_Function IS NULL) THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name,'Payment function is null.');
        END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
        FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_FD_PPP_GRP_PMT_T_PF'));
        l_message := fnd_message.get;
        FND_MSG_PUB.Add;

        l_ext_payee_upd_rec.Payee_Update_Status := 'E';
        l_ext_payee_upd_rec.Payee_Update_Msg := l_message;

        x_return_status := FND_API.G_RET_STS_ERROR;

      -- orgid is required if supplier site id passed
      ELSIF ((p_ext_payee_tab(counter).Payer_ORG_ID IS NULL) and
             (p_ext_payee_tab(counter).Supplier_Site_Id IS NOT NULL)) THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name,'Payer Org Id is null.');
        END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
        FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_PAYER_ORG_ID_FIELD'));
        l_message := fnd_message.get;
        FND_MSG_PUB.Add;

        l_ext_payee_upd_rec.Payee_Update_Status := 'E';
        l_ext_payee_upd_rec.Payee_Update_Msg := l_message;

      ELSIF ((p_ext_payee_tab(counter).Payer_ORG_ID IS NOT NULL) and
             (p_ext_payee_tab(counter).Payer_Org_Type IS  NULL)) THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name,'Payer Org Id is null.');
        END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
        FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_PAYER_ORG_TYPE_FIELD'));
        l_message := fnd_message.get;
        FND_MSG_PUB.Add;

        l_ext_payee_upd_rec.Payee_Update_Status := 'E';
        l_ext_payee_upd_rec.Payee_Update_Msg := l_message;

      ELSIF p_ext_payee_tab(counter).Exclusive_Pay_Flag IS NULL THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name,'Exclusive payment flag is null.');
        END IF;
        FND_MESSAGE.set_name('IBY', 'IBY_MISSING_MANDATORY_PARAM');
        FND_MESSAGE.SET_TOKEN('PARAM', fnd_message.GET_String('IBY','IBY_EXCL_PMT_FLAG_FIELD'));
        l_message := fnd_message.get;
        FND_MSG_PUB.Add;

        l_ext_payee_upd_rec.Payee_Update_Status := 'E';
        l_ext_payee_upd_rec.Payee_Update_Msg := l_message;

        x_return_status := FND_API.G_RET_STS_ERROR;

      ELSE
        OPEN external_payee_csr(p_ext_payee_tab(counter).Payee_Party_Id,
                                p_ext_payee_tab(counter).Payee_Party_Site_Id,
                                p_ext_payee_tab(counter).Supplier_Site_Id,
                                p_ext_payee_tab(counter).Payer_Org_Id,
                                p_ext_payee_tab(counter).Payer_Org_Type,
                                p_ext_payee_tab(counter).Payment_Function);
        FETCH external_payee_csr INTO l_payee_cnt, l_payee_id;
        CLOSE external_payee_csr;

        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	        print_debuginfo(l_module_name, 'Payee count is ' || l_payee_cnt);
	        print_debuginfo(l_module_name, 'Payee Id is ' || l_payee_id);

        END IF;
        IF (l_payee_cnt = 0 OR l_payee_id <> p_ext_payee_id_tab(counter).ext_payee_id) THEN

          IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	          print_debuginfo(l_module_name,'Payee id does not exist based on parameters or is different from'||
	                          'parameter ext_payee_id');
          END IF;
          FND_MESSAGE.set_name('IBY', 'IBY_EXT_PAYEE_NOT_EXIST');
          FND_MESSAGE.SET_TOKEN('EXT_PAYEE_ID', p_ext_payee_id_tab(counter).ext_payee_id);
          l_message := fnd_message.get;
          FND_MSG_PUB.Add;

          l_ext_payee_upd_rec.Payee_Update_Status := 'E';
          l_ext_payee_upd_rec.Payee_Update_Msg := l_message;

          x_return_status := FND_API.G_RET_STS_ERROR;

        ELSE
          -- update external payee
          UPDATE iby_external_payees_all
             SET exclusive_payment_flag = p_ext_payee_tab(counter).exclusive_pay_flag,
                 last_updated_by = fnd_global.user_id,
                 last_update_date = SYSDATE,   -- bug 13881024
                 last_update_login = fnd_global.user_id,
                 object_version_number = object_version_number+1,
                 default_payment_method_code = p_ext_payee_tab(counter).Default_Pmt_method,
                 ece_tp_location_code = p_ext_payee_tab(counter).ece_tp_loc_code,
                 bank_charge_bearer = p_ext_payee_tab(counter).Bank_Charge_Bearer,
                 bank_instruction1_code = p_ext_payee_tab(counter).Bank_Instr1_Code,
                 bank_instruction2_code = p_ext_payee_tab(counter).Bank_Instr2_Code,
                 bank_instruction_details = p_ext_payee_tab(counter).Bank_Instr_Detail,
                 payment_reason_code = p_ext_payee_tab(counter).Pay_Reason_Code,
                 payment_reason_comments = p_ext_payee_tab(counter).Pay_Reason_Com,
                 inactive_date = p_ext_payee_tab(counter).Inactive_Date,
                 payment_text_message1 = p_ext_payee_tab(counter).Pay_Message1,
                 payment_text_message2 = p_ext_payee_tab(counter).Pay_Message2,
                 payment_text_message3 = p_ext_payee_tab(counter).Pay_Message3,
                 delivery_channel_code = p_ext_payee_tab(counter).Delivery_Channel,
                 payment_format_code = p_ext_payee_tab(counter).Pmt_Format,
                 settlement_priority = p_ext_payee_tab(counter).Settlement_Priority,
		 remit_advice_email = p_ext_payee_tab(counter).Remit_advice_email,
		 remit_advice_delivery_method = p_ext_payee_tab(counter).Remit_advice_delivery_method,
		 remit_advice_fax = p_ext_payee_tab(counter).remit_advice_fax
           WHERE ext_payee_id = p_ext_payee_id_tab(counter).ext_payee_id;

          -- update default payment method
          IF(p_ext_payee_tab(counter).Default_Pmt_method IS NULL) THEN
            BEGIN
              UPDATE iby_ext_party_pmt_mthds
                 SET primary_flag = 'N',
                     last_update_date = SYSDATE,
                     last_updated_by = fnd_global.user_id,
                     last_update_login = fnd_global.user_id,
                     object_version_number = object_version_number+1
               WHERE ext_pmt_party_id = p_ext_payee_id_tab(counter).ext_payee_id
                 AND payment_function = p_ext_payee_tab(counter).payment_function
                 AND primary_flag = 'Y';
            EXCEPTION
              WHEN OTHERS THEN NULL;
            END;

          ELSE
            -- default payment method is not null
            SELECT COUNT(1)
              INTO l_pm_count
              FROM iby_payment_methods_b
             WHERE payment_method_code = p_ext_payee_tab(counter).Default_Pmt_method;

            IF (l_pm_count>0) THEN
              -- payment method exists
              BEGIN
                SELECT primary_flag
                  INTO l_primary_flag
                  FROM iby_ext_party_pmt_mthds
                 WHERE ext_pmt_party_id = p_ext_payee_id_tab(counter).ext_payee_id
                   AND payment_function = p_ext_payee_tab(counter).payment_function
                   AND payment_method_code=p_ext_payee_tab(counter).Default_Pmt_method;

              EXCEPTION
                WHEN no_data_found THEN
                  INSERT INTO IBY_EXT_PARTY_PMT_MTHDS
                    (EXT_PARTY_PMT_MTHD_ID,
                     PAYMENT_METHOD_CODE,
                     PAYMENT_FLOW,
                     EXT_PMT_PARTY_ID,
                     PAYMENT_FUNCTION,
                     PRIMARY_FLAG,
                     CREATED_BY,
                     CREATION_DATE,
                     LAST_UPDATED_BY,
                     LAST_UPDATE_DATE,
                     LAST_UPDATE_LOGIN,
                     OBJECT_VERSION_NUMBER
                   ) VALUES (
                     IBY_EXT_PARTY_PMT_MTHDS_S.nextval,
                     p_ext_payee_tab(counter).Default_Pmt_method,
                     'DISBURSEMENTS',
                     p_ext_payee_id_tab(counter).ext_payee_id,
                     p_ext_payee_tab(counter).Payment_function,
                     'Y',
                     fnd_global.user_id,
                     SYSDATE,  -- bug 13881024
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     1.0
                     );

              END;

              -- update primary_flag for all rows.
              BEGIN
                UPDATE iby_ext_party_pmt_mthds
                   SET primary_flag = DECODE(payment_method_code,
                                             p_ext_payee_tab(counter).Default_Pmt_method, 'Y', 'N'),
                       last_update_date = SYSDATE,     -- bug 13881024
                       last_updated_by = fnd_global.user_id,
                       last_update_login = fnd_global.user_id,
                       object_version_number = object_version_number+1
                 WHERE ext_pmt_party_id = p_ext_payee_id_tab(counter).ext_payee_id
                   AND payment_function = p_ext_payee_tab(counter).payment_function;
              EXCEPTION
                WHEN OTHERS THEN NULL;
              END;
            END IF; --payment method exists

          END IF; -- default payment method is not null
          l_ext_payee_upd_rec.Payee_Update_Status := 'S';

         END IF;
       END IF;

       IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	       print_debuginfo(l_module_name, 'External payee Id is '||p_ext_payee_id_tab(counter).ext_payee_id);
	       print_debuginfo(l_module_name, 'Creation status is ' || l_ext_payee_upd_rec.Payee_Update_Status);
	       print_debuginfo(l_module_name, '------------------------------');

       END IF;
       x_ext_payee_status_tab(counter) := l_ext_payee_upd_rec;

       counter := counter + 1;

     END LOOP;
   END IF;
   -- End of API body.

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'End of external payee loop.');
   END IF;
   -- Standard call to get message count and if count is 1, get message info.
   FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data  => x_msg_data);
   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	   print_debuginfo(l_module_name, 'RETURN');

   END IF;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      x_return_status := FND_API.G_RET_STS_ERROR;

      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data  => x_msg_data);
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name,'ERROR: Exception occured during call to API ');
	      print_debuginfo(l_module_name,'SQLerr is :'|| substr(SQLERRM, 1, 150));

      END IF;
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data  => x_msg_data);
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name,'ERROR: Exception occured during call to API ');
	      print_debuginfo(l_module_name,'SQLerr is :'|| substr(SQLERRM, 1, 150));

      END IF;
    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

      IF (FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)) THEN
         FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_api_name);
      END IF;
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      print_debuginfo(l_module_name,'ERROR: Exception occured during call to API ');
	      print_debuginfo(l_module_name,'SQLerr is :'|| substr(SQLERRM, 1, 150));
      END IF;
      FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data  => x_msg_data);

END Update_External_Payee;



END IBY_DISBURSEMENT_SETUP_PUB;
/
