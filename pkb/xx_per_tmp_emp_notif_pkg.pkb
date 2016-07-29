DROP PACKAGE BODY APPS.XX_PER_TMP_EMP_NOTIF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PER_TMP_EMP_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxpertmpempnotif.pkb
 Description   : This script creates the package body of
                 xx_per_tmp_emp_notif_pkg, which will send notifications
                 for equity Admins.
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 16-Apr-2012 Yogesh                Initial Version
 27-Aug-2012 Yogesh                Changes made to fetch hr_rep details
                                   by comparing position_id with attribute5
 04-Oct-2012 Renjith               added language setting for messages and subject
 06-Nov-2012 Renjith               Added exceptions and increased variable size
 07-Nov-2012 Renjith               Added new conditions for assignments
 07-Nov-2012 Renjith               Added effective date for positions for HR fields
 08-Nov-2012 Renjith               Added effective date for position
*/
----------------------------------------------------------------------
    PROCEDURE send_assnt_end_notif( x_error_code    OUT   NUMBER
                                   ,x_error_msg     OUT   VARCHAR2)
    IS
       CURSOR c_assmt_end_details
       IS
       SELECT  papf1.npw_number,
               ppt.user_person_type,
               papf1.full_name,
               paaf1.vacancy_id,
               paaf1.projected_assignment_end,
               pp.name contractor_position_name,
               (SELECT  papf2.full_name
                  FROM  per_all_people_f papf2,
                        per_all_assignments_f paaf1,
                        hr_all_positions_f pp1
                 WHERE  papf2.person_id = paaf1.person_id
                   AND  paaf1.position_id = pp1.position_id(+)
                   AND  SYSDATE BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                   AND  SYSDATE BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                   AND  SYSDATE BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                   AND  pp1.position_id = pp.attribute5
                   AND  paaf1.assignment_type = 'E'
                   AND  paaf1.primary_flag    = 'Y') hr_rep_name,
               (SELECT  papf2.email_address
                  FROM  per_all_people_f papf2,
                        per_all_assignments_f paaf1,
                        hr_all_positions_f pp1
                 WHERE  papf2.person_id = paaf1.person_id
                   AND  paaf1.position_id = pp1.position_id(+)
                   AND  SYSDATE BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                   AND  SYSDATE BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                   AND  SYSDATE BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                   AND  pp1.position_id = pp.attribute5
                   AND  paaf1.assignment_type = 'E'
                   AND  paaf1.primary_flag    = 'Y') hr_rep_mail,
               paaf1.supervisor_id,
               (SELECT  papfs.last_name
                  FROM  per_all_people_f papfs
                 WHERE  papfs.person_id = paaf1.supervisor_id
                   AND  SYSDATE BETWEEN papfs.effective_start_date AND papfs.effective_end_date) supervisor_name,
               (SELECT  papfs.email_address
                  FROM  per_all_people_f papfs
                 WHERE  papfs.person_id = paaf1.supervisor_id
                   AND  SYSDATE BETWEEN papfs.effective_start_date AND papfs.effective_end_date) supervisor_email,
               pp.name,
               paaf1.projected_assignment_end - trunc(SYSDATE) days_remaining
         FROM  per_person_type_usages_f pptuf,
               per_person_types ppt,
               per_all_people_f papf1,
               per_all_assignments_f paaf1,
               hr_all_positions_f pp
        WHERE  papf1.person_id = pptuf.person_id
          AND  ppt.person_type_id = pptuf.person_type_id
          AND  ppt.user_person_type = 'Agency Temp'
          AND  papf1.person_id = paaf1.person_id
          AND  paaf1.position_id = pp.position_id(+)
          AND  SYSDATE BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
          AND  SYSDATE BETWEEN papf1.effective_start_date AND papf1.effective_end_date
          AND  SYSDATE BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
          AND  SYSDATE BETWEEN pp.effective_start_date    AND pp.effective_end_date
          AND  paaf1.projected_assignment_end = trunc(SYSDATE) + 15
          --AND paaf1.projected_assignment_end is not null
       UNION
       SELECT  papf1.npw_number,
               ppt.user_person_type,
               papf1.full_name,
               paaf1.vacancy_id,
               paaf1.projected_assignment_end,
               pp.NAME contractor_position_name,
               (SELECT  papf2.full_name
                  FROM  per_all_people_f papf2,
                        per_all_assignments_f paaf1,
                        hr_all_positions_f pp1
                 WHERE  papf2.person_id = paaf1.person_id
                   AND  paaf1.position_id = pp1.position_id(+)
                   AND  SYSDATE BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                   AND  SYSDATE BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                   AND  SYSDATE BETWEEN pp1.effective_start_date AND pp1.effective_end_date
                   AND  pp1.position_id = pp.attribute5
                   AND  paaf1.assignment_type = 'E'
                   AND  paaf1.primary_flag    = 'Y') hr_rep_name,
               (SELECT  papf2.email_address
                  FROM  per_all_people_f papf2,
                        per_all_assignments_f paaf1,
                        hr_all_positions_f pp1
                 WHERE  papf2.person_id = paaf1.person_id
                   AND  paaf1.position_id = pp1.position_id(+)
                   AND  SYSDATE BETWEEN papf2.effective_start_date AND papf2.effective_end_date
                   AND  SYSDATE BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
                   AND  SYSDATE BETWEEN pp1.effective_start_date   AND pp1.effective_end_date
                   AND  pp1.position_id = pp.attribute5
                   AND  paaf1.assignment_type = 'E'
                   AND  paaf1.primary_flag    = 'Y') hr_rep_mail,
               paaf1.supervisor_id,
               (SELECT  papfs.last_name
                  FROM  per_all_people_f papfs
                 WHERE  papfs.person_id = paaf1.supervisor_id
                   AND  SYSDATE BETWEEN papfs.effective_start_date AND papfs.effective_end_date) supervisor_name,
               (SELECT  papfs.email_address
                  FROM  per_all_people_f papfs
                 WHERE  papfs.person_id = paaf1.supervisor_id
                   AND  SYSDATE BETWEEN papfs.effective_start_date AND papfs.effective_end_date) supervisor_email,
               pp.name,
               paaf1.projected_assignment_end - trunc(SYSDATE) days_remaining
         FROM  per_person_type_usages_f pptuf,
               per_person_types ppt,
               per_all_people_f papf1,
               per_all_assignments_f paaf1,
               hr_all_positions_f pp
        WHERE  papf1.person_id = pptuf.person_id
          AND  ppt.person_type_id = pptuf.person_type_id
          AND  ppt.user_person_type = 'Agency Temp'
          AND  papf1.person_id = paaf1.person_id
          AND  paaf1.position_id = pp.position_id(+)
          AND  SYSDATE BETWEEN pptuf.effective_start_date AND pptuf.effective_end_date
          AND  SYSDATE BETWEEN papf1.effective_start_date AND papf1.effective_end_date
          AND  SYSDATE BETWEEN paaf1.effective_start_date AND paaf1.effective_end_date
          AND  SYSDATE BETWEEN pp.effective_start_date    AND pp.effective_end_date
          AND  paaf1.projected_assignment_end = trunc(SYSDATE) + 7;

       --x_msg_sub                   VARCHAR2(50);
       x_msg_sub                   VARCHAR2(1000);
       x_next_line                 VARCHAR2(5):=chr(10);

       --x_msg_sender                VARCHAR2(200);
       x_msg_sender                VARCHAR2(2000);
       x_no_days                   NUMBER;
       --x_msg_body                  VARCHAR2(2000);
       x_msg_body                  VARCHAR2(3000);
       --x_msg_recipients            VARCHAR2(500);
       x_msg_recipients            VARCHAR2(2000);
    BEGIN

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Inside send_assnt_end_notif');
       xx_intg_common_pkg.get_process_param_value( 'XXPERTMPEMPNOTIF_CP'
                                        	  ,'MSG_SENDER'
                                        	  ,x_msg_sender
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Sender Not Defined in Process Setput');
       END IF;
/*
       xx_intg_common_pkg.get_process_param_value( 'XXPERTMPEMPNOTIF_CP'
                                        	  ,'MSG_SUB'
                                        	  ,x_msg_sub
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Subject Not Defined in Process Setput');
       END IF;
*/
       FOR r_assmt_end_details IN c_assmt_end_details LOOP
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Inside send_assnt_end_notif loop');
           IF r_assmt_end_details.hr_rep_name IS NULL THEN
              x_msg_recipients:= r_assmt_end_details.supervisor_email;
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'HR Rep not found - Notification sent to temp employee manager' );
           ELSIF r_assmt_end_details.supervisor_name IS NULL THEN
              x_msg_recipients:= r_assmt_end_details.hr_rep_mail;
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Manager not found - Notification sent to temp employees HR Rep' );
           ELSE
              x_msg_recipients:= r_assmt_end_details.supervisor_email || ',' ||r_assmt_end_details.hr_rep_mail;
           END IF;

           IF r_assmt_end_details.supervisor_email IS NOT NULL THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-----------------------------------------------------------------------------------');
              x_msg_sub  := NULL;
              x_msg_body := NULL;

              BEGIN
                 --xx_intg_common_pkg.set_session_language( p_email_id => 'chris.johnson@integralife.com');
                 xx_intg_common_pkg.set_session_language( p_email_id => r_assmt_end_details.supervisor_email);
                 fnd_message.set_name ( 'XXINTG','XX_PER_ASSNT_END_SUBJECT');
                 x_msg_sub:=fnd_message.get;

                 x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  => 'XX_PER_ASSNT_END_MSG'
                                                                  ,p_token_value1  => to_char(r_assmt_end_details.days_remaining)
                                                                  ,p_token_value2  => r_assmt_end_details.full_name
                                                                  ,p_token_value3  => to_char(r_assmt_end_details.vacancy_id)
                                                                  ,p_token_value4  => to_char(r_assmt_end_details.projected_assignment_end)
                                                                  ,p_no_of_tokens  => 4
                                                                 );

              EXCEPTION
	           WHEN OTHERS THEN
	             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message - '||SQLERRM);
	      END;
	      -- -------------------------------------------------------------- --
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' ');
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Sender       ->'||x_msg_sender);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Supervisor   ->'||r_assmt_end_details.supervisor_email);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Subject      ->'||x_msg_sub);
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Body ->'||x_msg_body);
	      -- -------------------------------------------------------------- --
              BEGIN
                 xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
	                                     ,recipients => r_assmt_end_details.supervisor_email
	                                     ,subject    => x_msg_sub
	                                     ,message    => x_msg_body
                                            );
	      EXCEPTION
	         WHEN OTHERS THEN
	            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Cannot Send Mail - Check Common Mailer Ulitilty - '||SQLERRM);
	      END;
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-----------------------------------------------------------------------------------');
           END IF;

           IF r_assmt_end_details.hr_rep_mail IS NOT NULL THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-----------------------------------------------------------------------------------');
              x_msg_sub  := NULL;
              x_msg_body := NULL;

              BEGIN
                 --xx_intg_common_pkg.set_session_language( p_email_id => 'chris.johnson@integralife.com');
                 xx_intg_common_pkg.set_session_language( p_email_id => r_assmt_end_details.hr_rep_mail);
                 fnd_message.set_name ( 'XXINTG','XX_PER_ASSNT_END_SUBJECT');
                 x_msg_sub:=fnd_message.get;

                 x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  => 'XX_PER_ASSNT_END_MSG'
                                                                  ,p_token_value1  => to_char(r_assmt_end_details.days_remaining)
                                                                  ,p_token_value2  => r_assmt_end_details.full_name
                                                                  ,p_token_value3  => to_char(r_assmt_end_details.vacancy_id)
                                                                  ,p_token_value4  => to_char(r_assmt_end_details.projected_assignment_end)
                                                                  ,p_no_of_tokens  => 4
                                                                 );

	      EXCEPTION
	         WHEN OTHERS THEN
	            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message - '||SQLERRM);
	      END;

	      -- -------------------------------------------------------------- --
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,' ');
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Sender       ->'||x_msg_sender);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'HR Rep       ->'||r_assmt_end_details.hr_rep_mail);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Subject      ->'||x_msg_sub);
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Body ->'||x_msg_body);
	      -- -------------------------------------------------------------- --
              BEGIN
                 xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
	                                     ,recipients => r_assmt_end_details.hr_rep_mail
	                                     ,subject    => x_msg_sub
	                                     ,message    => x_msg_body
                                            );
	      EXCEPTION
	         WHEN OTHERS THEN
	            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Cannot Send Mail - Check Common Mailer Ulitilty - '||SQLERRM );
	      END;
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-----------------------------------------------------------------------------------');
           END IF;
       END LOOP;
    EXCEPTION
       WHEN OTHERS THEN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in Procedure send_assnt_end_notif - '||SQLERRM);
    END send_assnt_end_notif;

--------------------------------------------------------------------------------------------------------------
    PROCEDURE main_prc( x_error_code    OUT   NUMBER
                       ,x_error_msg     OUT   VARCHAR2)
    IS
       x_err_code                NUMBER;
       x_err_msg                 VARCHAR2(50);
    BEGIN
       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling Procedure to send, notifications regarding the assignment end date: ');
       send_assnt_end_notif(x_err_code,x_error_msg);

    END main_prc;

END xx_per_tmp_emp_notif_pkg;
/
