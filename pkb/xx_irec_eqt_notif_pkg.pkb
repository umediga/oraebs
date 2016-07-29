DROP PACKAGE BODY APPS.XX_IREC_EQT_NOTIF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IREC_EQT_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : Yogesh Rudrasetty
 File Name     : xxirceqtnotif.pkb
 Description   : This script creates the package body of
                 xx_irec_eqt_notif_pkg, which will send notifications
                 for equity Admins.
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 16-Apr-2012 Yogesh                Initial Version
*/
----------------------------------------------------------------------

    PROCEDURE send_eqt_admin_notif( x_error_code    OUT   NUMBER
                                   ,x_error_msg     OUT   VARCHAR2)
    IS
       CURSOR c_benefit_details (p_cpns_category VARCHAR2)
       IS
       SELECT  bpes.prtt_enrt_rslt_id,
               ppf.full_name,
               hou.name department,
               ppf.employee_number,
               bp.name,
               bpes.enrt_cvg_strt_dt,
               enrt_cvg_thru_dt,
               pev.screen_entry_value stock_value,
               enrt_ovridn_flag,
               brv.rt_strt_dt rate_start_date
         FROM  ben_prtt_enrt_rslt_f bpes,
               ben_pl_f bp,
               per_people_f ppf,
               ben_prtt_rt_val brv,
               pay_element_entry_values_f pev,
               per_all_assignments_f paaf,
               hr_all_organization_units hou,
               hr_lookups hl,
               ben_acty_base_rt_f abr
        WHERE  bpes.enrt_cvg_thru_dt > SYSDATE
          AND  SYSDATE BETWEEN bpes.effective_start_date AND bpes.EFFECTIVE_END_DATE
          AND  bpes.sspndd_flag = 'N'
          AND  no_lngr_elig_flag = 'N'
          AND  bpes.pl_id = bp.pl_id
          AND  brv.prtt_enrt_rslt_id = bpes.prtt_enrt_rslt_id
          AND  pev.element_entry_value_id = brv.element_entry_value_id
          AND  hl.lookup_type ='BEN_SUB_ACTY_TYP'
          AND  hl.lookup_code = abr.sub_acty_typ_cd
          AND  hl.enabled_flag = 'Y'
          AND  hl.meaning = p_cpns_category
          AND  SYSDATE BETWEEN abr.effective_start_date and abr.effective_end_date
          AND  bp.name =abr.name
          AND  ppf.person_id = bpes.person_id
          AND  SYSDATE BETWEEN ppf.effective_start_date AND ppf.effective_end_date
          AND  brv.creation_date BETWEEN SYSDATE-1 AND SYSDATE
          AND  paaf.person_id = ppf.person_id
          AND  paaf.primary_flag = 'Y'
          AND  SYSDATE BETWEEN paaf.effective_start_date AND paaf.effective_end_date
          AND  hou.organization_id = paaf.organization_id;

       x_msg_sub                   VARCHAR2(100);
       x_msg_sender                VARCHAR2(200);
       x_msg_body                  VARCHAR2(1500);
       x_msg_recipients            VARCHAR2(500);
       x_cpns_category_name        VARCHAR2(240);

    BEGIN
       xx_intg_common_pkg.get_process_param_value( 'XXIRCEQTNOTIF_CP'
                                        	  ,'MSG_SENDER'
                                        	  ,x_msg_sender
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Sender Not Defined in Process Setput');
       END IF;

       /*xx_intg_common_pkg.get_process_param_value( 'XXIRCEQTNOTIF_CP'
                                        	  ,'MSG_SUB'
                                        	  ,x_msg_sub
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Subject Not Defined in Process Setput');
       END IF;*/

       xx_intg_common_pkg.get_process_param_value( 'XXIRCEQTNOTIF_CP'
                                               	  ,'MSG_RECIPIENT'
                                               	  ,x_msg_recipients
                                 		 );
       IF x_msg_recipients IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Equity Admin Mail Id Not Defined in Process Setup From');
       END IF;

       xx_intg_common_pkg.get_process_param_value( 'XXIRCEQTNOTIF_CP'
                                        	  ,'COMPENSATION_CATEGORY'
                                        	  ,x_cpns_category_name
                                 		 );
       IF x_cpns_category_name IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Benefit Name Not Defined in Process Setput');
       END IF;

       FOR r_benefit_details IN c_benefit_details(x_cpns_category_name) LOOP

           BEGIN
              /* This will set the langaunge of the message body, based on language preferrence of the equity Admin */
              xx_intg_common_pkg.set_session_language( p_email_id => x_msg_recipients );
              x_msg_sub:=xx_intg_common_pkg.set_long_message( p_message_name  =>'XX_IRC_EQT_ADM_MSG_SUB');

              x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_EQT_ADM_MSG'
	                                                       ,p_token_value1  =>r_benefit_details.full_name
	                                                       ,p_token_value2  =>r_benefit_details.employee_number
	                                                       ,p_token_value3  =>r_benefit_details.stock_value
	                                                       ,p_token_value4  =>r_benefit_details.department
	                                                       ,p_token_value5  =>r_benefit_details.rate_start_date
	                                                       ,p_no_of_tokens  => 5
                                                              );
	   EXCEPTION
	     WHEN OTHERS
	     THEN
	        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message' );
	   END;

           BEGIN
              xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
	                                  ,recipients => x_msg_recipients
	                                  ,subject    => x_msg_sub
	                                  ,message    => x_msg_body
                                         );
	   EXCEPTION
	     WHEN OTHERS
	     THEN
	        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Cannot Send Mail - Check Common Mailer Ulitilty' );
	   END;

	   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Mail Recipients :'||x_msg_recipients);
	   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Body:'||x_msg_body);
	   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'----------------------------------------------------');
       END LOOP;

    END send_eqt_admin_notif;

--------------------------------------------------------------------------------------------------------------
    PROCEDURE main_prc( x_error_code    OUT   NUMBER
                       ,x_error_msg     OUT   VARCHAR2)
    IS
       x_err_code                NUMBER;
       x_err_msg                 VARCHAR2(50);
    BEGIN

       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling Procedure to Send Notification to Equity Admin: ');
       send_eqt_admin_notif(x_err_code,x_error_msg);

    END main_prc;

END xx_irec_eqt_notif_pkg;
/
