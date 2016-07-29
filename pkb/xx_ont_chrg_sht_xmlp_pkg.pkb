DROP PACKAGE BODY APPS.XX_ONT_CHRG_SHT_XMLP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_CHRG_SHT_XMLP_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 26-MAR-2013
 File Name     : XXONTCHRGSHTXMLP.pkb
 Description   : This script creates the body of the package
                 xx_ont_chrg_sht_xmlp_pkg to create code for after
                 parameter form trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 26-MAR-2013 Sharath Babu          Initial Development
*/
----------------------------------------------------------------------
--After Parameter Form Trigger
FUNCTION AFTERPFORM RETURN BOOLEAN IS
BEGIN
   P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
   
   IF p_header_id IS NULL AND p_case_num IS NULL THEN
      LP_WHERE := ' AND 1 = 2';
      fnd_file.put_line(fnd_file.log,'Provide Order Num or Case Num Param: LP_WHERE: '||LP_WHERE);
   ELSIF p_case_num IS NOT NULL AND p_header_id IS NULL THEN
      LP_WHERE := ' AND NVL(ooha.attribute12,99) = :p_case_num'; 
   ELSIF p_header_id IS NOT NULL AND p_case_num IS NULL THEN
      LP_WHERE := ' AND ooha.header_id = :p_header_id'; 
   ELSIF p_header_id IS NOT NULL AND p_case_num IS NOT NULL THEN
      LP_WHERE := ' AND ooha.header_id = :p_header_id AND NVL(ooha.attribute12,99) = :p_case_num';
   ELSE
      LP_WHERE := ' ';
   END IF;
   
   IF p_email_send IS NULL THEN
      p_email_send := 'N';
   END IF;
   
   RETURN (TRUE);
END AFTERPFORM; 

--After Report Trigger
FUNCTION AFTERREPORT RETURN BOOLEAN IS
   v_reqid NUMBER;
BEGIN
   IF p_email_send = 'Y' AND NVL(p_email,xx_ont_chrg_sht_xmlp_pkg.get_email_id(p_header_id)) IS NOT NULL THEN
   BEGIN
      v_reqid :=
         fnd_request.submit_request ('XDO',
                                     'XDOBURSTREP',
                                      NULL,
                                      NULL,
                                      FALSE,
                                      'Y',
                                      P_CONC_REQUEST_ID,
                                      'N'
                                     );
      COMMIT;
   EXCEPTION
   WHEN OTHERS THEN
      NULL;
      RETURN (FALSE);
   END;
   END IF;
   RETURN (TRUE);
EXCEPTION
   WHEN OTHERS THEN
   NULL;
   RETURN (FALSE);
END AFTERREPORT;
  
--Function to fetch email Id from customer contact level
FUNCTION get_email_id (p_header_id IN NUMBER) RETURN VARCHAR2
IS     
   --Cursor to fecth email id from customer contact level
   CURSOR c_get_email_id(p_header_id IN NUMBER)
   IS
     SELECT DISTINCT rel_party.email_address email_address       
       FROM hz_contact_points cont_point,
            hz_cust_account_roles acct_role,
            hz_parties party,
            hz_parties rel_party,
            hz_relationships rel,
            hz_cust_accounts role_acct,
            oe_order_headers_all ooha
      WHERE acct_role.party_id = rel.party_id
        AND acct_role.role_type = 'CONTACT'
        AND rel.subject_id = party.party_id
        AND rel_party.party_id = rel.party_id
        AND cont_point.owner_table_id(+) = rel_party.party_id
        AND acct_role.cust_account_id = role_acct.cust_account_id
        AND role_acct.party_id = rel.object_id
        AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
        AND cont_point.contact_point_type = 'EMAIL'
        AND acct_role.cust_account_role_id = ooha.sold_to_contact_id
        AND ooha.header_id = p_header_id;   
                
   x_email_id VARCHAR2(3000);
   x_variable VARCHAR2(10) := NULL;
     
BEGIN
   --Fetch Email Id from header level
   BEGIN
      SELECT attribute4
        INTO x_email_id
        FROM oe_order_headers_all
       WHERE header_id = p_header_id;
        
   EXCEPTION
      WHEN OTHERS THEN
         x_email_id := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while fetching email id from order header');
   END;
     
   IF x_email_id IS NULL THEN 
      --Fetch Email Id from Cust Contact Level
         OPEN c_get_email_id(p_header_id);
         FETCH c_get_email_id
         INTO  x_email_id;
         CLOSE c_get_email_id;
   END IF;

  RETURN x_email_id;
     
 EXCEPTION 
   WHEN OTHERS THEN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error inside get_email_id');
           
END get_email_id;       
  
END XX_ONT_CHRG_SHT_XMLP_PKG; 
/
