DROP PACKAGE BODY APPS.XX_ONT_SO_CONFIRM_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_SO_CONFIRM_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-APR-2012
 File Name     : XX_ONT_SO_CONFIRM_PKG.pkb
 Description   : This script creates the body of the package
                 xx_ont_so_confirm_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-APR-2012 Sharath Babu          Initial Development
 04-MAY-2012 Sharath Babu          Modified to add logic to fetch email body text
 02-Aug-2012 Renjith               added parameter p_title as per CR
 14-Aug-2012 Renjith               Added file move prgm
 04-Sep-2012 Renjith               Added file renaming
 09-APR-2013 Sharath Babu          Added param p_out_type as per DCR
 03-MAR-2014 Mou		   Added the function get_avail_revsqty for wave1 change
*/
----------------------------------------------------------------------

PROCEDURE main ( errbuf          OUT  VARCHAR2,
                 retcode         OUT  NUMBER,
                 p_title         IN   VARCHAR2,
                 p_header_id     IN   NUMBER,
                 p_email_send    IN   VARCHAR2,
                 p_email         IN   VARCHAR2,
                 p_language      IN   VARCHAR2,
                 p_out_type      IN   VARCHAR2 )
IS

   CURSOR  c_data_dir(p_dir VARCHAR2)
   IS
   SELECT  directory_path
     FROM  all_directories
    WHERE  directory_name= p_dir;

   x_language         hz_locations.language%TYPE;
   x_ter              fnd_languages.iso_territory%TYPE := 'US';
   x_lang             fnd_languages.iso_language%TYPE := 'en';
   x_application      VARCHAR2(10) := 'XXINTG';
   x_program_name     VARCHAR2(20);
   x_program_desc     VARCHAR2(50);
   x_layout_status    BOOLEAN := FALSE;
   x_user_id          NUMBER := fnd_global.user_id;
   x_resp_id          NUMBER := fnd_global.resp_id;
   x_resp_appl_id     NUMBER := fnd_global.resp_appl_id;
   x_reqid            NUMBER;
   x_phase            VARCHAR2(80);
   x_status           VARCHAR2(80);
   x_devphase         VARCHAR2(80);
   x_devstatus        VARCHAR2(80);
   x_message          VARCHAR2(3000);
   x_check            BOOLEAN;
   x_from_name        VARCHAR2(50);
   x_to_name          VARCHAR2(3000);
   x_cc_name          VARCHAR2(50);
   x_bc_name          VARCHAR2(50);
   x_subject          VARCHAR2(100);
   x_body_msg         VARCHAR2(10000);
   x_oracle_dir       VARCHAR2(100);
   x_bin_file         VARCHAR2(50);
   x_error_code       NUMBER;
   x_order_number     NUMBER;
   x_conc_request_id  NUMBER;
   x_file_flag        VARCHAR2(1);
   x_file_exception   EXCEPTION;
   x_from_path        VARCHAR2(600);
   x_to_path          VARCHAR2(600);
   x_from_dir         VARCHAR2(40);
   x_to_dir           VARCHAR2(40);
   x_tmpl_code        VARCHAR2(40);
   x_output_type      VARCHAR2(40) := 'PDF';
   x_arg1             VARCHAR2(600);
BEGIN

   x_error_code := xx_emf_pkg.set_env;
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);

   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_header_id: '||p_header_id);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_email: '||p_email);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_language: '||p_language);

   IF p_language IS NOT NULL THEN
      x_language := p_language;
      BEGIN
         SELECT LOWER (iso_language)
               ,iso_territory
           INTO x_lang
               ,x_ter
           FROM fnd_languages
          WHERE UPPER(language_code) = UPPER (x_language);
      EXCEPTION
         WHEN OTHERS
         THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in getting Language details '|| SQLERRM);
         x_language := 'US';
         x_lang := 'en';
         x_ter := 'US';
      END;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_lang: '||x_lang);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_ter: '||x_ter);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_language: '||x_language);
   ELSE
      --Get Report language
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Call get_report_language');
      x_language := get_report_language(p_header_id);

      BEGIN
         SELECT LOWER (iso_language)
               ,iso_territory
           INTO x_lang
               ,x_ter
           FROM fnd_languages
          WHERE UPPER(language_code) = UPPER (x_language);
      EXCEPTION
         WHEN OTHERS
         THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in getting Language details '|| SQLERRM);
         x_language := 'US';
         x_lang := 'en';
         x_ter := 'US';
      END;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_lang: '||x_lang);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_ter: '||x_ter);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_language: '||x_language);
   END IF;
   --Check for report type added as per DCR
   IF p_title = 'S' THEN
      x_tmpl_code := 'XXONTSOCNFRM';
      x_program_name := 'XXONTSOCNFRM';
      x_program_desc := 'INTG Sales Order Confirmation Report';
   ELSIF p_title = 'P' THEN
      x_tmpl_code := 'XXONTPRELIMINV';
      x_program_name := 'XXONTPRELIMINV';
      x_program_desc := 'INTG Preliminary Invoice Report';
   END IF;

   IF p_out_type IS NOT NULL THEN
      x_output_type := p_out_type;
   END IF;

   --Add layout
   IF (x_language = 'US')  --English
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code => x_tmpl_code
                                                 ,template_language => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format => x_output_type
                                                );

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Add Layout :'|| SUBSTR (SQLERRM, 1, 2000));

   ELSIF (x_language = 'D')  --German
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code => x_tmpl_code
                                                 ,template_language => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format => x_output_type
                                                );

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Add Layout :'|| SUBSTR (SQLERRM, 1, 2000));

   ELSIF (x_language = 'F')  --French
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code => x_tmpl_code
                                                 ,template_language => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format => x_output_type
                                                );

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Add Layout :'|| SUBSTR (SQLERRM, 1, 2000));

   ELSIF (x_language = 'ESA')  --Spanish
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code => x_tmpl_code
                                                 ,template_language => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format => x_output_type
                                                );

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Add Layout :'|| SUBSTR (SQLERRM, 1, 2000));

   ELSE
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Layout not defined for Language :'|| x_language);
   END IF;

   --Submit request
   IF x_layout_status THEN
      -- Call Submit Request
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Submit Request : '||x_program_desc);
      BEGIN
         Fnd_Global.apps_initialize(x_user_id, --User id
                                    x_resp_id, --responsibility_id
                                    x_resp_appl_id); --application_id
         IF p_title = 'S' THEN
            x_reqid := fnd_request.submit_request(  application     => x_application
                                                   ,program         => x_program_name
                                                   ,description     => x_program_desc
                                                   ,start_time      => SYSDATE
                                                   ,sub_request     => FALSE
                                                   ,argument1       => p_header_id
                                                 );
         ELSIF p_title = 'P' THEN
            x_reqid := fnd_request.submit_request(  application     => x_application
                                                   ,program         => x_program_name
                                                   ,description     => x_program_desc
                                                   ,start_time      => SYSDATE
                                                   ,sub_request     => FALSE
                                                   ,argument1       => p_header_id
                                                   ,argument2       => x_language
                                                 );
         END IF;
         COMMIT;

         IF x_reqid !=0 THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********Request '||x_reqid||' Submitted Successfully to generate report');
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Request Not Submitted due to ' || fnd_message.get);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while submiting request' || ' User id' || fnd_global.user_id|| SQLERRM);
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'**************************************************************');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********The '|| x_program_desc ||' Request Submitted********');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'**************************************************************');

         --Check for completion of the concurrent process
         x_check:=fnd_concurrent.wait_for_request(x_reqid,1,0,x_phase,x_status,x_devphase,x_devstatus,x_message);
         IF (x_devphase='COMPLETE' and x_devstatus='NORMAL') THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********Request '||x_reqid||' Completed Normally for Program:'|| x_program_desc);
         ELSIF (x_devphase='COMPLETE' and x_devstatus='WARNING') THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********Request '||x_reqid||' Completed with Warning for Program:'|| x_program_desc);
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********Request '||x_reqid||' Completed for Program:'|| x_program_desc);
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Exception occured in request submission block');
      END;
   END IF;

   --Send report via email
   IF p_email_send = 'Y' THEN

      -- Added by REN
      -- [
      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSOCNFMMAIN'
                                                 ,p_param_name      => 'OUTFILE_DIRECTORY'
                                                 ,x_param_value     =>  x_from_dir);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'OUTFILE_DIRECTORY ->'||x_from_dir);

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSOCNFMMAIN'
                                                 ,p_param_name      => 'MAIL_DIRECTORY'
                                                 ,x_param_value     =>  x_to_dir);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'MAIL_DIRECTORY ->'||x_to_dir);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********Request '||x_reqid||' Completed for Program:'|| x_program_desc);

      OPEN  c_data_dir(x_from_dir);
      FETCH c_data_dir INTO x_from_path;
      IF c_data_dir%NOTFOUND THEN
        x_from_path := NULL;
      END IF;
      CLOSE c_data_dir;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'FROM Path ->'||x_from_path);

      OPEN  c_data_dir(x_to_dir);
      FETCH c_data_dir INTO x_to_path;
      IF c_data_dir%NOTFOUND THEN
        x_to_path := NULL;
      END IF;
      CLOSE c_data_dir;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'TO Path ->'||x_to_path);
      --Fetch Order Number
      BEGIN
         SELECT ooh.order_number
           INTO x_order_number
           FROM oe_order_headers_all ooh
          WHERE 1 = 1
            AND ooh.header_id = p_header_id;

      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error while fecthing Order Number');
      END;
     --Added as per DCR changes
     IF p_out_type = 'PDF' THEN
        x_arg1 := x_program_name||'_'||x_reqid||'_1.PDF';
        x_bin_file   := 'SalesOrderAck_'||x_order_number||'.PDF';
     ELSIF p_out_type = 'EXCEL' THEN
        x_arg1 := x_program_name||'_'||x_reqid||'_1.EXCEL';
        x_bin_file   := 'SalesOrderAck_'||x_order_number||'.xls';
     END IF;

      BEGIN
           x_conc_request_id := FND_REQUEST.SUBMIT_REQUEST
              ( application    => 'XXINTG'
               ,program        => 'XXINTGFILEMOV'
               ,sub_request    =>  FALSE
               ,argument1      =>  x_arg1
               ,argument2      =>  x_from_path
               ,argument3      =>  x_to_path||'/'||x_bin_file
               ,argument4      => 'No');

           COMMIT;

           IF x_conc_request_id = 0 THEN
              RAISE x_file_exception;
           ELSE
              x_phase := NULL; x_status := NULL; x_devphase := NULL; x_devstatus:= NULL; x_message := NULL;
              x_check:=FND_CONCURRENT.WAIT_FOR_REQUEST(x_conc_request_id,1,0,x_phase,x_status,x_devphase,x_devstatus,x_message);
              IF (x_devphase <> 'COMPLETE' OR x_devstatus <> 'NORMAL') THEN
                  RAISE x_file_exception;
              END IF;
           END IF;
      EXCEPTION WHEN OTHERS THEN
         RAISE x_file_exception;
      END;
      -- ]

      IF p_email IS NOT NULL THEN
         x_to_name := p_email;
      ELSE
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling get_email_id');
         x_to_name := get_email_id(p_header_id);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_name: '||x_to_name);
      END IF;

      --Fetch Email Body Text Message
      BEGIN
         SELECT message_text
           INTO x_message
           FROM fnd_new_messages
          WHERE message_name ='XXONTSOCNFMMSG'
            AND language_code = x_language;

      EXCEPTION
	 WHEN OTHERS THEN
	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error while fetching email body text message');
      END;

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSOCNFMMAIN'
                                                 ,p_param_name      => 'EMAIL_FROM'
                                                 ,x_param_value     =>  x_from_name);


      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSOCNFMMAIN'
                                                 ,p_param_name      => 'EMAIL_BCC'
                                                 ,x_param_value     =>  x_bc_name);


      x_cc_name    := NULL;
      x_subject    := 'Sales Order Acknowledgement of the Order#'||x_order_number;
      --x_bin_file   := x_program_name||'_'||x_reqid||'_1.PDF';

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '**********************************');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from_name: '||x_from_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_name: '||x_to_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_bc_name: '||x_bc_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject: '||x_subject);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_message: '||x_message);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_dir: '||x_to_dir);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_bin_file: '||x_bin_file);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '**********************************');

      IF x_to_name IS NOT NULL THEN
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling xx_intg_mail_util_pkg.send_mail_attach');
            --Call Email procedure
            xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from_name
                                                   ,p_to_name          => x_to_name
                                                   ,p_cc_name          => x_cc_name
                                                   ,p_bc_name          => x_bc_name
                                                   ,p_subject          => x_subject
                                                   ,p_message          => x_message
                                                   ,p_oracle_directory => x_to_dir
                                                   ,p_binary_file      => x_bin_file
                                                  );
         EXCEPTION
            WHEN OTHERS THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error after xx_intg_mail_util_pkg.send_mail_attach');
         END;
      ELSE
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_name is Null , No Email');
      END IF;
   END IF;

EXCEPTION
   WHEN x_file_exception THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in moving the file for mailing');
      retcode := 1;
   WHEN OTHERS THEN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SUBSTR (SQLERRM, 1, 2000));
      retcode := 2;
END main;

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

   CURSOR c_get_sold_to_emails(p_header_id IN NUMBER)
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
        AND role_acct.cust_account_id = ooha.sold_to_org_id
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
      --Check Order Source
      BEGIN
         SELECT 'X'
           INTO x_variable
           FROM oe_order_headers_all ooh
               ,oe_order_sources oos
          WHERE 1=1
            AND ooh.order_source_id = oos.order_source_id
            AND oos.name like 'IStore%'
            AND ooh.header_id = p_header_id;
      EXCEPTION
         WHEN OTHERS THEN
            x_variable := NULL;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while fetching Order Source');
      END;

      --Fetch Email Id from Cust Contact Level
      IF x_variable IS NOT NULL THEN
         OPEN c_get_email_id(p_header_id);
         FETCH c_get_email_id
         INTO  x_email_id;
         CLOSE c_get_email_id;
      END IF;
   END IF;

   x_variable := NULL;
   --Check Order Source for EDI orders from GHX Mailbox
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM oe_order_headers_all ooh
            ,oe_order_sources oos
       WHERE 1=1
         AND ooh.order_source_id = oos.order_source_id
         AND oos.name like 'EDIGHX'
         AND ooh.header_id = p_header_id;
   EXCEPTION
      WHEN OTHERS THEN
         x_variable := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Order Source is not EDIGHX');
   END;

   --Fetch Email Id from Cust Contact Level
   IF x_variable IS NOT NULL THEN
      x_email_id := NULL;
   END IF;

   x_variable := NULL;
   --Check Order Source for EDI orders from GXS Mailbox
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM oe_order_headers_all ooh
            ,oe_order_sources oos
       WHERE 1=1
         AND ooh.order_source_id = oos.order_source_id
         AND oos.name like 'EDIGXS'
         AND ooh.header_id = p_header_id;
   EXCEPTION
      WHEN OTHERS THEN
         x_variable := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Order Source is not EDIGXS');
   END;

   --Fetch Email Id from Cust Contact Level
   IF x_variable IS NOT NULL THEN
      x_email_id := NULL;
      FOR r_get_sold_to_emails IN c_get_sold_to_emails(p_header_id)
      LOOP
         x_email_id := x_email_id||r_get_sold_to_emails.email_address||';';
      END LOOP;
   END IF;

   RETURN x_email_id;

EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error inside get_email_id');

END get_email_id;

--Function to fetch report language from customer ship to site level
FUNCTION get_report_language(p_header_id IN VARCHAR2) RETURN VARCHAR2
IS
   --Cursor to fetch language if null then English
   CURSOR c_get_language(p_header_id IN VARCHAR2)
   IS
      SELECT NVL(ship_loc.language,'US') lang_print
        FROM apps.oe_order_headers_all            ooha,
             apps.hz_cust_site_uses_all ship_su,
             apps.hz_party_sites ship_ps,
             apps.hz_locations ship_loc,
             apps.hz_cust_acct_sites_all ship_cas
       WHERE ooha.ship_to_org_id = ship_su.site_use_id(+)
         AND ship_su.cust_acct_site_id = ship_cas.cust_acct_site_id(+)
         AND ship_cas.party_site_id = ship_ps.party_site_id(+)
         AND ship_loc.location_id(+) = ship_ps.location_id
         AND ooha.header_id = p_header_id;

   x_language         hz_locations.language%TYPE;

BEGIN
   --Fetch language
   OPEN c_get_language(p_header_id);
   FETCH c_get_language
   INTO  x_language;
   CLOSE c_get_language;

   RETURN x_language;
EXCEPTION
   WHEN OTHERS THEN
      x_language := 'US';
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error inside get_report_language');

END get_report_language;


--Function to fetch available to reserve quantity ( Added for wave1 change )
FUNCTION get_avail_revsqty(p_organization_id IN NUMBER , p_inventory_item_id IN NUMBER) RETURN NUMBER
IS

   x_return_status         VARCHAR2 (50);
   x_msg_count             VARCHAR2 (50);
   x_msg_data              VARCHAR2 (50);
   l_item_id               NUMBER;
   l_organization_id       NUMBER;
   l_qty_on_hand           NUMBER;
   l_res_qty_on_hand       NUMBER;
   l_avail_to_tnsct        NUMBER;
   l_avail_to_reserve      NUMBER;
   l_qty_reserved          NUMBER;
   l_qty_suggested         NUMBER;
   l_lot_control_code      BOOLEAN;
   l_serial_control_code   BOOLEAN;
BEGIN

   inv_quantity_tree_grp.clear_quantity_cache; -- Clear Quantity cache
   -- Set the variable values
   l_item_id := p_inventory_item_id;
   l_organization_id := p_organization_id;
   l_lot_control_code := FALSE;  --Only When Lot number is passed  TRUE else FALSE
   l_serial_control_code := FALSE;
   -- Call API
   inv_quantity_tree_pub.query_quantities
               (p_api_version_number       => 1.0
               ,p_init_msg_lst             => NULL
               ,x_return_status            => x_return_status
               ,x_msg_count                => x_msg_count
               ,x_msg_data                 => x_msg_data
               ,p_organization_id          => l_organization_id
               ,p_inventory_item_id        => l_item_id
               ,p_tree_mode                => apps.inv_quantity_tree_pub.g_transaction_mode
               ,p_is_revision_control      => FALSE
               ,p_is_lot_control           => l_lot_control_code-- is_lot_control,
               ,p_is_serial_control        => l_serial_control_code
               ,p_revision                 => NULL              -- p_revision,
               ,p_lot_number               => NULL              -- p_lot_number,
               ,p_lot_expiration_date      => SYSDATE
               ,p_subinventory_code        => NULL              -- p_subinventory_code,
               ,p_locator_id               => NULL              -- p_locator_id,
               --,p_cost_group_id            => NULL
               --,p_onhand_source            => NULL
               ,x_qoh                      => l_qty_on_hand     -- Quantity on-hand
               ,x_rqoh                     => l_res_qty_on_hand --reservable quantity on-hand
               ,x_qr                       => l_qty_reserved
               ,x_qs                       => l_qty_suggested
               ,x_att                      => l_avail_to_tnsct  -- available to transact
               ,x_atr                      => l_avail_to_reserve-- available to reserve
               );

RETURN l_avail_to_reserve;

EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line ('ERROR: ' || SQLERRM);

END get_avail_revsqty;


END xx_ont_so_confirm_pkg;
/
