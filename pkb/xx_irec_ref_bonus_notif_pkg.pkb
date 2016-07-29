DROP PACKAGE BODY APPS.XX_IREC_REF_BONUS_NOTIF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IREC_REF_BONUS_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxirecrefbnsnotif.pkb
 Description   : This script creates the package body of
                 xx_irec_ref_bonus_notif_pkg, which will send notifications
                 to recuiters on 21st and 60th day, regarding the referral
                 bonus when an referral employee is hired
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Mar-2012 Yogesh                Initial Version
 10-Apr-2014 Jaya Jayaraj          Updated as per CC3738 to check attribute7 is not null
 10-Sep-2014 Jaya Jayaraj          Updated as per CC010079
*/
----------------------------------------------------------------------

    PROCEDURE send_refrral_bonus_notif21( x_error_code    OUT   NUMBER
                                         ,x_error_msg     OUT   VARCHAR2)
    IS

       CURSOR c_referral_details(p_no_days NUMBER)
       IS
       SELECT  papf.person_id,
               papf.first_name refferee_first_name,
               papf.last_name refferee_last_name,
               papf.employee_number,
               ref.full_name source_employee,
               papf.original_date_of_hire hire_date,
               recuriter.full_name recuriter,
               recuriter.email_address recuriter_mail_id,
               (SELECT supervisor.full_name
                  FROM per_all_people_f supervisor
                 WHERE supervisor.person_id = paaf.supervisor_id
                   AND SYSDATE BETWEEN supervisor.effective_start_date
                       AND supervisor.effective_END_date) supervisor,
               hro.name department,
               pav.attribute7 bonus_value
         FROM  per_person_type_usages_f pptuf,
               per_person_types ppt,
               per_all_people_f papf,
               per_assignments_f paaf,
               per_all_people_f REF,
               per_recruitment_activities ra,
               per_all_people_f recuriter,
               hr_all_organization_units hro,
               per_all_vacancies pav
        WHERE  pptuf.person_type_id = ppt.person_type_id
          AND  papf.person_id = pptuf.person_id
          AND  papf.person_id = paaf.person_id
          AND  paaf.person_referred_by_id = REF.person_id
          AND  paaf.recruitment_activity_id = ra.recruitment_activity_id(+)
          AND  ppt.user_person_type = 'Employee'
          AND  hro.organization_id= paaf.organization_id
          AND  SYSDATE BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
          AND  SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date
          AND  SYSDATE BETWEEN paaf.effective_start_date AND paaf.effective_end_date
          AND  SYSDATE BETWEEN REF.effective_start_date AND REF.effective_end_date
          AND  papf.original_date_of_hire = trunc(SYSDATE-p_no_days)
          AND  recuriter.person_id = pav.recruiter_id
          AND  SYSDATE BETWEEN recuriter.effective_start_date AND recuriter.effective_END_date
          AND  pav.vacancy_id = paaf.vacancy_id
          --and  to_number(pav.attribute7) >0;  --- Checking if the refferal bonus is declared or not.  Commented for CC3738
          and  pav.attribute7 is not null;  -- Added for CC3738

       x_msg_sender                VARCHAR2(200);
       x_msg_sub                   VARCHAR2(100);
       x_msg_body                  VARCHAR2(2000);
       x_no_of_days                VARCHAR2(100);

    BEGIN
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'First Bonus mail sent to Below Recuiters : ');

       xx_intg_common_pkg.get_process_param_value( 'XXIRCREFBNSNOTIF_CP'
                                              ,'MSG_SENDER'
                                              ,x_msg_sender
                                          );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Sender Not Defined in Process Setput');
       END IF;

       /*xx_intg_common_pkg.get_process_param_value( 'XXIRCREFBNSNOTIF_CP'
                                              ,'MSG_SUB_FIRST'
                                              ,x_msg_sub
                                          );
       IF x_msg_sub IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Subject is Not Defined in Process Setput');
       END IF;     */

       xx_intg_common_pkg.get_process_param_value( 'XXIRCREFBNSNOTIF_CP'
                                              ,'FISRT_NOTIF_DAYS'
                                              ,x_no_of_days
                                          );
       IF x_msg_sub IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'The Number of Days From the Hire Date to Send First Notification not Defined ');
       END IF;


       FOR r_referral_details IN c_referral_details(TO_NUMBER(x_no_of_days)) LOOP

           BEGIN
              /* This will set the langaunge of the message body, based on language preferrence of the recruiter */
              xx_intg_common_pkg.set_session_language( p_email_id => r_referral_details.recuriter_mail_id );

              x_msg_sub:=xx_intg_common_pkg.set_long_message(  p_message_name  =>'XX_IRC_REF_BNS_MSG_SUB1');
              x_msg_body:=xx_intg_common_pkg.set_long_message( 'XX_IRC_REF_BNS_MSG'
                                                              ,r_referral_details.refferee_first_name
                                                              ,r_referral_details.refferee_last_name
                                                              ,r_referral_details.employee_number
                                                              ,r_referral_details.supervisor
                                                              ,r_referral_details.department
                                                              ,r_referral_details.source_employee
                                                              ,r_referral_details.hire_date
                                                              ,r_referral_details.bonus_value
                                                             );
       EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message' );
       END;

           BEGIN
              xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                      ,recipients => r_referral_details.recuriter_mail_id
                                     ,subject    => x_msg_sub
                                     ,message    => x_msg_body
                                     );
       EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Cannot Send Mail - Check Common Mailer Ulitilty' );
       END;

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Recuiter    :'||r_referral_details.recuriter_mail_id);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Body:'||x_msg_body);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'----------------------------------------------------');
       END LOOP;
    END send_refrral_bonus_notif21;

    --------------------------------------------------------------------
    PROCEDURE send_refrral_bonus_notif60( x_error_code    OUT   NUMBER
                                         ,x_error_msg     OUT   VARCHAR2)
    IS

       CURSOR c_referral_details(p_no_days NUMBER)
       IS
       SELECT  papf.person_id,
               papf.first_name refferee_first_name,
               papf.last_name refferee_last_name,
               papf.employee_number,
               ref.full_name source_employee,
               papf.original_date_of_hire hire_date,
               recuriter.full_name recuriter,
               recuriter.email_address recuriter_mail_id,
               (SELECT supervisor.full_name
                  FROM per_all_people_f supervisor
                 WHERE supervisor.person_id = paaf.supervisor_id
                   AND SYSDATE BETWEEN supervisor.effective_start_date
                       AND supervisor.effective_END_date) supervisor,
               hro.name department,
               pav.attribute7 bonus_value
         FROM  per_person_type_usages_f pptuf,
               per_person_types ppt,
               per_all_people_f papf,
               per_assignments_f paaf,
               per_all_people_f REF,
               per_recruitment_activities ra,
               per_all_people_f recuriter,
               hr_all_organization_units hro,
               per_all_vacancies pav
        WHERE  pptuf.person_type_id = ppt.person_type_id
          AND  papf.person_id = pptuf.person_id
          AND  papf.person_id = paaf.person_id
          AND  paaf.person_referred_by_id = REF.person_id
          AND  paaf.recruitment_activity_id = ra.recruitment_activity_id(+)
          AND  ppt.user_person_type = 'Employee'
          AND  hro.organization_id= paaf.organization_id
          AND  SYSDATE BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
          AND  SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date
          AND  SYSDATE BETWEEN paaf.effective_start_date AND paaf.effective_end_date
          AND  SYSDATE BETWEEN REF.effective_start_date AND REF.effective_end_date
          AND  papf.original_date_of_hire = trunc(SYSDATE-p_no_days)
          AND  recuriter.person_id = pav.recruiter_id
          AND  SYSDATE BETWEEN recuriter.effective_start_date AND recuriter.effective_END_date
          AND  pav.vacancy_id = paaf.vacancy_id
          --and  to_number(pav.attribute7) >0;  Commented for CC3738
          and  pav.attribute7 is not null; -- Added for CC3738


       x_msg_sender                VARCHAR2(200);
       x_msg_sub                   VARCHAR2(100);
       x_msg_body                  VARCHAR2(2000);
       x_no_of_days                VARCHAR2(100);


    BEGIN
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Second Bonus mail sent to Below Recuiters : ');

       xx_intg_common_pkg.get_process_param_value( 'XXIRCREFBNSNOTIF_CP'
                                              ,'MSG_SENDER'
                                              ,x_msg_sender
                                          );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Sender Not Defined in Process Setput');
       END IF;

      /* xx_intg_common_pkg.get_process_param_value( 'XXIRCREFBNSNOTIF_CP'
                                              ,'MSG_SUB_SECOND'
                                              ,x_msg_sub
                                          );
       IF x_msg_sub IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Subject is Not Defined in Process Setput');
       END IF;   */

       xx_intg_common_pkg.get_process_param_value( 'XXIRCREFBNSNOTIF_CP'
                                              ,'SECOND_NOTIF_DAYS'
                                              ,x_no_of_days
                                          );
       IF x_msg_sub IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'The Number of Days From the Hire Date to Send Second Notification not Defined');
       END IF;

       FOR r_referral_details IN c_referral_details(TO_NUMBER(x_no_of_days)) LOOP

           BEGIN
              /* This will set the langaunge of the message body, based on language preferrence of the recruiter */
              xx_intg_common_pkg.set_session_language( p_email_id => r_referral_details.recuriter_mail_id );
              x_msg_sub:=xx_intg_common_pkg.set_long_message( p_message_name  =>'XX_IRC_REF_BNS_MSG_SUB2');
              x_msg_body:=xx_intg_common_pkg.set_long_message( 'XX_IRC_REF_BNS_MSG'
                                                              ,r_referral_details.refferee_first_name
                                                              ,r_referral_details.refferee_last_name
                                                              ,r_referral_details.employee_number
                                                              ,r_referral_details.supervisor
                                                              ,r_referral_details.department
                                                              ,r_referral_details.source_employee
                                                              ,r_referral_details.hire_date
                                                              ,r_referral_details.bonus_value
                                                             );
       EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message' );
       END;

           BEGIN
              xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                       ,recipients => r_referral_details.recuriter_mail_id
                                     ,subject    => x_msg_sub
                                     ,message    => x_msg_body
                                     );
       EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Cannot Send Mail - Check Common Mailer Ulitilty' );
       END;

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Recuiter    :'||r_referral_details.recuriter_mail_id);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Body:'||x_msg_body);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'----------------------------------------------------');

       END LOOP;
    END send_refrral_bonus_notif60;

--------------------------------------------------------------------------------------------------------------
    PROCEDURE main_prc( x_error_code    OUT   NUMBER
                       ,x_error_msg     OUT   VARCHAR2)
    IS
       x_err_code                NUMBER;
       x_err_msg                 VARCHAR2(50);
    BEGIN
       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);
        
       -- The 2 lines below have been commented as a part of CC# 10079Sep 2014.
       --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling Procedure to send referal bonus notification for 21st day ');
       --send_refrral_bonus_notif21(x_err_code,x_error_msg);

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling Procedure to send referal bonus notification for 60th day ');
       send_refrral_bonus_notif60(x_err_code,x_error_msg);

    END main_prc;

END xx_irec_ref_bonus_notif_pkg; 
/
