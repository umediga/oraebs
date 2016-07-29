DROP PACKAGE BODY APPS.XX_IREC_INTWFDBK_NOTIF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IREC_INTWFDBK_NOTIF_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxirecintwfdbknotif.pkb
 Description   : This script creates the package body of
                 xx_irec_intw_fdbk_notif_pkg, which will send notifications
                 for interviwers on the pending feedback of interviews
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 10-Apr-2012 Yogesh                Initial Version
 5-Mar-2013  Vishal                Fix for case # 002104
*/
----------------------------------------------------------------------
    FUNCTION get_lang_preference( p_email_id IN VARCHAR2 )
    RETURN VARCHAR2
    IS
       x_pref_lang		   VARCHAR2(20);
    BEGIN
       SELECT DISTINCT wlr.language
         INTO x_pref_lang
         FROM per_all_people_f ppf
             ,fnd_user fu
             ,wf_local_roles wlr
        WHERE ppf.person_id = fu.employee_id
          AND fu.user_name = wlr.name
          AND wlr.status = 'ACTIVE'
          AND ppf.email_address = p_email_id
          AND SYSDATE  BETWEEN ppf.effective_start_date AND NVL(ppf.effective_end_date,SYSDATE)
          AND SYSDATE  BETWEEN fu.start_date AND NVL(fu.end_date,SYSDATE);
       RETURN x_pref_lang;
    EXCEPTION
	     WHEN OTHERS
	     THEN
	     RETURN 'AMERICAN';
    END get_lang_preference;

--------------------------------------------------------------------------------------------------------------

    PROCEDURE send_intwfdbk_pending_notif( x_error_code    OUT   NUMBER
                                          ,x_error_msg     OUT   VARCHAR2)
    IS

       CURSOR c_intvr_details
       IS
       SELECT  iid.CATEGORY,
               ppf.first_name,
               ppf.employee_number,
               ppf.email_address interviewer_id,
               ppfr.email_address recruiter_id,
               paf.assignment_id,
               irtm.vacancy_id,
               ppfc.full_name Applicant,
               (sysdate - to_date( to_char(pr.date_start || ' '|| pr.time_end),'DD-MON-YY HH24:MI') ) no_of_days
         FROM  irc_rec_team_members irtm,
               per_all_assignments_f paf,
               per_all_people_f ppf,
               per_all_people_f ppfc,
               per_all_people_f ppfr,
               irc_interview_details iid,
               per_events pr,
               per_bookings pb,
               per_all_vacancies pav
        WHERE  irtm.vacancy_id = paf.vacancy_id
          AND  SYSDATE BETWEEN paf.effective_start_date AND paf.effective_end_date
          and  PPF.PERSON_ID = IRTM.PERSON_ID
           AND  ppf.person_id = pb.person_id -- Added by Vishal
          AND  (ppf.current_employee_flag = 'Y' OR ppf.current_npw_flag = 'Y')
          AND  iid.status = 'CONFIRMED'
          and  IID.STATUS != 'COMPLETED'
          --AND  iid.start_date < SYSDATE -- Commented by Vishal
          --AND  iid.end_date > SYSDATE -- Commented by Vishal
           and (sysdate - to_date( to_char(pr.date_start || ' '|| pr.time_end),'DD-MON-YY HH24:MI') ) > 1 -- Added by Vishal
          AND  iid.event_id = pr.event_id
          AND  pr.assignment_id = paf.assignment_id
          and  pav.vacancy_id = paf.vacancy_id
          AND  ppfr.person_id = pav.recruiter_id
          AND  SYSDATE  BETWEEN ppf.effective_start_date AND ppf.effective_end_date
          AND  SYSDATE  BETWEEN ppfc.effective_start_date AND ppfc.effective_end_date
          AND  SYSDATE  BETWEEN ppfr.effective_start_date AND ppfr.effective_end_date
          AND  ppfc.person_id = paf.person_id
          AND  pb.event_id = pr.event_id
          AND  pb.primary_interviewer_flag = 'Y';


       x_msg_sub                   VARCHAR2(4000);
       x_msg_sub_rec               VARCHAR2(4000);
       x_msg_sender                VARCHAR2(200);
       x_msg_body                  VARCHAR2(4000);
       x_msg_body_rec              VARCHAR2(4000);
       x_msg_recipients            VARCHAR2(500);
       x_no_of_days                VARCHAR2(100);
       x_intw_pref                 VARCHAR2(50);
       x_recruiter_pref            VARCHAR2(50);
    BEGIN

       xx_intg_common_pkg.get_process_param_value( 'XXIRECINTFBNOTIF_CP'
                                        	  ,'MSG_SENDER'
                                        	  ,x_msg_sender
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Sender Not Defined in Process Setput');
       END IF;

       /*xx_intg_common_pkg.get_process_param_value( 'XXIRECINTFBNOTIF_CP'
                                        	  ,'MSG_SUB'
                                        	  ,x_msg_sub
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Message Subject Not Defined in Process Setput');
       END IF; */

       xx_intg_common_pkg.get_process_param_value( 'XXIRECINTFBNOTIF_CP'
                                        	  ,'ESCALATION_DAYS'
                                        	  ,x_no_of_days
                                 		 );
       IF x_msg_sender IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'No of Days to Send Escalation Mail, Not Defined');
       END IF;


       FOR r_intvr_details IN c_intvr_details LOOP

           x_msg_recipients:= r_intvr_details.interviewer_id;
           x_intw_pref:=get_lang_preference(r_intvr_details.interviewer_id);
           /* This will set the langaunge of the message body, based on language preferrence of the interviewer */
           xx_intg_common_pkg.set_session_language( p_email_id => r_intvr_details.interviewer_id );
           BEGIN

	      x_msg_sub:=xx_intg_common_pkg.set_long_message( p_message_name  =>'XX_IRC_INT_FB_MSG_SUB');
              x_msg_body:=xx_intg_common_pkg.set_long_message( 'XX_IRC_INT_FB_MSG'
                                                              ,r_intvr_details.first_name
                                                              ,r_intvr_details.Applicant
                                                             );
	   EXCEPTION
	     WHEN OTHERS
	     THEN
	        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message' );
	   END;


           IF r_intvr_details.no_of_days > TO_NUMBER(x_no_of_days) THEN
              x_msg_recipients:= r_intvr_details.interviewer_id ||','|| r_intvr_details.recruiter_id;
              x_recruiter_pref:=get_lang_preference(r_intvr_details.recruiter_id);

               IF x_recruiter_pref != x_intw_pref
               THEN
                  /* This will set the langaunge of the message body, based on language preferrence of the recruiter */
                  xx_intg_common_pkg.set_session_language( p_email_id => r_intvr_details.recruiter_id );
                  BEGIN

	             x_msg_sub_rec:=xx_intg_common_pkg.set_long_message( p_message_name  =>'XX_IRC_INT_FB_MSG_SUB');
                     x_msg_body_rec:=xx_intg_common_pkg.set_long_message( 'XX_IRC_INT_FB_MSG'
                                                                     ,r_intvr_details.first_name
                                                                     ,r_intvr_details.Applicant
                                                                    );
	          EXCEPTION
	            WHEN OTHERS
	            THEN
	               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error While Setting the Token Values For Notification Message' );
	          END;
	          x_msg_sub:=x_msg_sub||x_msg_sub_rec;
	          x_msg_body:=x_msg_body||x_msg_body_rec;
	          END IF;
           END IF;

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

    END send_intwfdbk_pending_notif;

--------------------------------------------------------------------------------------------------------------
    PROCEDURE main_prc( x_error_code    OUT   NUMBER
                       ,x_error_msg     OUT   VARCHAR2)
    IS
       x_err_code                NUMBER;
       x_err_msg                 VARCHAR2(50);
    BEGIN
       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling Procedure to send, pending interview feedback notification: ');
       send_intwfdbk_pending_notif(x_err_code,x_error_msg);

    END main_prc;

END xx_irec_intwfdbk_notif_pkg;
/
