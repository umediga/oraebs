DROP PACKAGE BODY APPS.XX_ONT_SO_SHIPPING_CON_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_SO_SHIPPING_CON_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Pawan Kumar
 Creation Date : 23-APR-2012
 File Name     : XX_ONT_SO_SHIPPING_CON_PKG.pkb
 Description   : This script creates the body of the package
                 xx_ont_so_shipping_con_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 23-APR-2012 Pawan Kumar           Initial Development
 16-Aug-2012 Renjith               Added file  copy before mailing
 04-Sep-2012 Renjith               Added file renaming
 07-Nov-2012 Renjith               Changes to DFF, att5 to att4.
 15-Apr-2013 Yogesh                Changes Made as part of DCR
                                    - Parameter Delivery ID has been added
 09-Jul-2013 Renjith               Changes as per Wave1
 07-May-2014 Renjith               Fix as per Case#005894
 08-OCT-2014 Sharath               Modified as per Wave2
*/
----------------------------------------------------------------------

PROCEDURE main ( errbuf          OUT  VARCHAR2,
                 retcode         OUT  NUMBER,
                 p_header_id     IN   NUMBER,
                 p_email_send    IN   VARCHAR2,
                 p_email_address IN   VARCHAR2,
                 p_language      IN   VARCHAR2,
                 p_pri_pen_lines IN   VARCHAR2,
                 p_delivery_id   IN   NUMBER )-- Added as part of DCR
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
   x_program_name     VARCHAR2(20) := 'XXONTSOSHIPPINGCNFRM';
   x_program_desc     VARCHAR2(100) := 'INTG Sales Order Shipping Confirmation Report';
   x_layout_status    BOOLEAN := FALSE;
   x_user_id          NUMBER := fnd_global.user_id;
   x_resp_id          NUMBER := fnd_global.resp_id;
   x_resp_appl_id     NUMBER := fnd_global.resp_appl_id;
   x_reqid            NUMBER;
   x_phase            VARCHAR2(2000);
   x_status           VARCHAR2(80);
   x_devphase         VARCHAR2(80);
   x_devstatus        VARCHAR2(80);
   x_message          VARCHAR2(2000);
   x_check            BOOLEAN;
   x_from_name        VARCHAR2(1000);
   x_to_name          VARCHAR2(1000);
   x_cc_name          VARCHAR2(1000);
   x_bc_name          VARCHAR2(1000);
   x_subject          VARCHAR2(2000);
   x_bin_file         VARCHAR2(1000);
   x_error_code       NUMBER;
   x_email_ids        varchar2(500);
   x_msg              VARCHAR2(5000);
   x_email_id         VARCHAR2(1000);
   x_order_number     NUMBER;
   x_conc_request_id  NUMBER;
   x_file_exception   EXCEPTION;
   x_from_path        VARCHAR2(600);
   x_to_path          VARCHAR2(600);
   x_from_dir         VARCHAR2(40);
   x_to_dir           VARCHAR2(40);
   x_conc_short_name  VARCHAR2(40) := 'XXONTSHIPPINGACKMAIN';
   x_ou_name          VARCHAR2(240);
   x_tmpl_code        VARCHAR2(240);

   x_templ_none_exp   EXCEPTION;
BEGIN

   x_error_code := xx_emf_pkg.set_env;
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);

   --Get Report language
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Call get_report_language');
    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_header_id: '||p_header_id);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_email_send: '||p_email_send);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_email_address: '||p_email_address);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_language: '||p_language);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'p_pri_pen_lines: '||p_pri_pen_lines);
 IF p_language IS NOT NULL THEN
    x_language :=p_language;
   BEGIN
      SELECT LOWER (iso_language)
            ,iso_territory
        INTO x_lang
            ,x_ter
        FROM fnd_languages
       WHERE UPPER(language_code) = UPPER (x_language);
   EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in getting Language details '|| SQLERRM);
         x_language := 'US';
         x_lang := 'en';
         x_ter := 'US';
   END;

   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_lang: '||x_lang);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_ter: '||x_ter);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_language: '||x_language);
  ELSE
   --get Report Language
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
   --Fetch OU name Added as per Wave2
   BEGIN
      SELECT hou.name
        INTO x_ou_name
        FROM hr_operating_units hou
            ,oe_order_headers_all ooh
       WHERE hou.organization_id = ooh.org_id
         AND ooh.header_id = p_header_id;
   EXCEPTION
      WHEN OTHERS
      THEN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while fetching OU name '|| SQLERRM);
      x_ou_name := 'OU United States';
   END;
   --Fetch template name
   x_tmpl_code := xx_intg_common_pkg.get_ou_specific_templ(x_ou_name,x_conc_short_name);
   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Template name '||x_tmpl_code);
   --If template defined as none raise exception
   IF UPPER(x_tmpl_code) = 'NONE' THEN
      RAISE x_templ_none_exp;
   END IF;

   IF x_tmpl_code IS NULL THEN
      x_tmpl_code := 'XXONTSOSHIPPINGCNFRM';
   END IF;

   --Add layout
   IF (x_language = 'US')  --English
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code      => x_tmpl_code  --'XXONTSOSHIPPINGCNFRM' As per Wave2
                                                 ,template_language  => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format      => 'PDF'
                                                );

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Add Layout :'|| SUBSTR (SQLERRM, 1, 2000));

   ELSIF (x_language = 'D')  --German
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code      => x_tmpl_code  --'XXONTSOSHIPPINGCNFRM' As per Wave2
                                                 ,template_language  => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format      => 'PDF'
                                                );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Add Layout :'|| SUBSTR (SQLERRM, 1, 2000));

   ELSIF (x_language = 'F')  --French
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code      => x_tmpl_code  --'XXONTSOSHIPPINGCNFRM' As per Wave2
                                                 ,template_language  => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format      => 'PDF'
                                                );

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' Add Layout :'|| SUBSTR (SQLERRM, 1, 2000));

   ELSIF (x_language = 'ESA')  --Spanish
   THEN
      x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                 ,template_code      => x_tmpl_code  --'XXONTSOSHIPPINGCNFRM' As per Wave2
                                                 ,template_language  => x_lang
                                                 ,template_territory => x_ter
                                                 ,output_format      => 'PDF'
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

         x_reqid := fnd_request.submit_request(  application     => x_application
                                                ,program         => x_program_name
                                                ,description     => x_program_desc
                                                ,start_time      => SYSDATE
                                                ,sub_request     => FALSE
                                                ,argument1       => p_header_id
                                                ,argument2       => p_pri_pen_lines
                                                ,argument3       => p_delivery_id    -- Added as part of DCR
                                              );
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
   IF p_email_send ='Y' THEN

      -- Added by REN
      -- [
      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSOCNFMMAIN'
                                                 ,p_param_name      => 'OUTFILE_DIRECTORY'
                                                 ,x_param_value     =>  x_from_dir);

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSOCNFMMAIN'
                                                 ,p_param_name      => 'MAIL_DIRECTORY'
                                                 ,x_param_value     =>  x_to_dir);
      OPEN  c_data_dir(x_from_dir);
      FETCH c_data_dir INTO x_from_path;
      IF c_data_dir%NOTFOUND THEN
        x_from_path := NULL;
      END IF;
      CLOSE c_data_dir;

      OPEN  c_data_dir(x_to_dir);
      FETCH c_data_dir INTO x_to_path;
      IF c_data_dir%NOTFOUND THEN
        x_to_path := NULL;
      END IF;
      CLOSE c_data_dir;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from_path: '||x_from_path);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_path: '||x_to_path);

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

      x_bin_file   := 'ShipConfirmation_'||x_order_number||'.PDF';

      BEGIN
           x_conc_request_id := FND_REQUEST.SUBMIT_REQUEST
              ( application    => 'XXINTG'
               ,program        => 'XXINTGFILEMOV'
               ,sub_request    =>  FALSE
               ,argument1      =>  x_program_name||'_'||x_reqid||'_1.PDF'
               ,argument2      =>  x_from_path||'/'
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

      IF p_email_address IS NOT NULL THEN
         x_to_name := p_email_address;
      ELSE
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling get_email_id');
         x_to_name := get_email_id(p_header_id);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_name: '||x_to_name);
      END IF;
      --Fetch Email Body Text Message
      BEGIN
         SELECT message_text into x_msg
           FROM fnd_new_messages
          WHERE message_name  ='XXONTSOCNFMMSG'
            AND language_code = x_language;
      EXCEPTION
         WHEN OTHERS THEN
             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SUBSTR (SQLERRM, 1, 2000));
      END;

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSHIPPINGACKMAIN'
                                                 ,p_param_name      => 'FROM_EMAIL_ID'
                                                 ,x_param_value     =>  x_from_name);


      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSHIPPINGACKMAIN'
                                                 ,p_param_name      => 'BCC_EMAIL_ID'
                                                 ,x_param_value     =>  x_bc_name);

      xx_intg_common_pkg.get_process_param_value( p_process_name    => 'XXONTSHIPPINGACKMAIN'
                                                 ,p_param_name      => 'SUBJECT'
                                                 ,x_param_value     =>  x_subject);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '**********************************');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from_name: '||x_from_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_name:   '||x_to_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_cc_name:   '||x_cc_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_bc_name:   '||x_bc_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject:   '||x_subject||x_order_number);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_msg:       '||x_msg);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_bin_file:  '||x_bin_file);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '**********************************');
      IF x_to_name IS NOT NULL THEN
        BEGIN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling xx_intg_mail_util_pkg.send_mail_attach');
           --Call Email procedure
           xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from_name
                                                  ,p_to_name          => x_to_name
                                                  ,p_cc_name          => x_cc_name
                                                  ,p_bc_name          => x_bc_name
                                                  ,p_subject          => x_subject||x_order_number
                                                  ,p_message          => x_msg
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
   WHEN x_templ_none_exp THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Template Code is None for '||x_ou_name);
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
     SELECT rel_party.email_address email_address
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

   --x_email_id VARCHAR2(50);
   -- Incresed variable size as per Case#005894
   x_email_id VARCHAR2(3000);
   x_variable VARCHAR2(10) := NULL;

BEGIN
   --Fetch Email Id from header level
   BEGIN
      SELECT attribute4--attribute5
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

END xx_ont_so_shipping_con_pkg;
/
