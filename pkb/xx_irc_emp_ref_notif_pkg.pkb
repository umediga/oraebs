DROP PACKAGE BODY APPS.XX_IRC_EMP_REF_NOTIF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IRC_EMP_REF_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : Yogesh Rudrasetty
 File Name     : xxircemprefntf.pkb
 Description   : This script creates the package body of   xx_irec_employee_ref_notif_pkg, which will send notifications to an employee referrer, when a referral applicant joins the Organization.

 Change History:
 Date            Name                  Remarks
 -----------    -------------      -----------------------------------
 8-May-2012     Rajeev Rath        Initial Version
*/
----------------------------------------------------------------------
     PROCEDURE send_emp_ref_notif( x_error_code    OUT   NUMBER
                                               ,x_error_msg     OUT   VARCHAR2)
         IS

     CURSOR c_emp_ref
     IS
     SELECT  papf.person_id,
             papf.first_name refree_first_name,
             papf.last_name refree_last_name,
             REF.first_name refferrer_first_name,
             REF.last_name refferrer_last_name,
             REF.email_address refferrer_email,
             papf.original_date_of_hire applicant_hire_date
       FROM  per_person_type_usages_f pptuf,
             per_person_types ppt,
             per_all_people_f papf,
             per_assignments_f paaf,
             per_all_people_f REF,
             per_recruitment_activities ra,
             per_periods_of_service pps
      WHERE  pptuf.person_type_id = ppt.person_type_id
        AND  papf.person_id = pptuf.person_id
        AND  papf.person_id = paaf.person_id
        AND  paaf.person_referred_by_id = REF.person_id
        AND  paaf.recruitment_activity_id = ra.recruitment_activity_id(+)
        AND  ppt.user_person_type = 'Employee'
        AND  SYSDATE BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
        AND  SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date
        AND  SYSDATE BETWEEN paaf.effective_start_date AND paaf.effective_end_date
        AND  SYSDATE BETWEEN REF.effective_start_date AND REF.effective_end_date
        AND  pps.date_start = papf.original_date_of_hire
        AND  pps.person_id = papf.person_id
        AND  SYSDATE BETWEEN pps.date_start AND NVL(pps.actual_termination_date,sysdate+1)
        AND  nvl(pps.attribute20,'N')!='Y'
        AND  pps.date_start <= SYSDATE
        AND  paaf.primary_flag = 'Y';

       x_msg_sub                   VARCHAR2(50);
       x_msg_sender                VARCHAR2(200);
       x_msg_body                  VARCHAR2(1500);
       x_err_msg                   VARCHAR2(500);
       x_err_code                  NUMBER;

    BEGIN

       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);

       xx_intg_common_pkg.get_process_param_value( 'XXIRCEMPREFNTF_CP'
                                        	  ,'MSG_SENDER'
                                        	  ,x_msg_sender
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Sender Not Defined in Process Setput');
       END IF;

       /*xx_intg_common_pkg.get_process_param_value( 'XXIRCEMPREFNTF_CP'
                                                   ,'MSG_SUB'
                                                  ,x_msg_sub
                                                 );
           IF x_msg_sender IS NULL THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Subject Not Defined in Process Set up');
           END IF;  */
          /* Cursor Name is c_emp_ref */
       FOR  emp_ref_rec IN c_emp_ref LOOP

            BEGIN
              /* This will set the langaunge of the message body, based on language preferrence of the refferrer */
              xx_intg_common_pkg.set_session_language( p_email_id => emp_ref_rec.refferrer_email );

              x_msg_sub:=xx_intg_common_pkg.set_long_message( p_message_name  =>'XX_IRC_EMPLOYEE_REF_MSG_SUB');
              x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_EMPLOYEE_REF_MSG'
                                                               ,p_token_value1  =>emp_ref_rec.refree_first_name
                                                               ,p_token_value2  =>emp_ref_rec.refree_last_name
                                                               ,p_no_of_tokens  => 2
                                                             );

           EXCEPTION
           WHEN OTHERS
           THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message' );
           END;

       BEGIN
              xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                          ,recipients => emp_ref_rec.refferrer_email
                                          ,subject    => x_msg_sub
                                          ,message    => x_msg_body
                                         );
        UPDATE per_periods_of_service
           SET attribute20 = 'Y'
         WHERE SYSDATE BETWEEN date_start AND NVL(actual_termination_date,sysdate+1)
           AND person_id = emp_ref_rec.person_id;
       EXCEPTION
         WHEN OTHERS
         THEN
            x_err_msg:=substr(SQLERRM,0,230);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,x_err_msg );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Cannot Send Mail - Check Common Mailer Ulitilty' );
            rollback;
       END;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Mail Recipients :'||emp_ref_rec.refferrer_email);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Body:'||x_msg_body);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'----------------------------------------------------');
       END LOOP;
    END send_emp_ref_notif;


    PROCEDURE main_prc( x_error_code    OUT   NUMBER
                       ,x_error_msg     OUT   VARCHAR2)
    IS
       x_err_code                NUMBER;
       x_err_msg                 VARCHAR2(50);
    BEGIN
       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling Procedure to send notifications to an employee referrer, when a referral applicant joins the Organization :' );
       send_emp_ref_notif(x_err_code,x_error_msg);
    END main_prc;
END xx_irc_emp_ref_notif_pkg;
/
