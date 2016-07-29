DROP PACKAGE BODY APPS.XX_IRC_NOTIF_TRG_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IRC_NOTIF_TRG_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Yogesh Rudrasetty
 Creation Date : 05-APR-2012
 File Name     : xx_irc_notif_trg_pkg.pkb
 Description   : This script creates the Body definition of the package
                 xx_irc_notif_trg_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 07-MAY-2012 Yogesh Rudrasetty     Initial Development
 20-JUN-2014 Jaya Maran            Modified for Defect#6843
*/
----------------------------------------------------------------------
/* This Function is called whenever an applicant status is Changed*/

    FUNCTION applicant_status_chg_notif ( p_assignment_id   IN      NUMBER
                         ,p_appl_status     IN      VARCHAR2)

    RETURN VARCHAR2
    IS
       CURSOR c_mail_recipient(p_assnt_id number)
       IS
       SELECT  pas.user_status,
               can.email_address can_email,
               can.full_name applicant_name,
               pav.name irc_name,
               (SELECT  email_address
                  FROM  per_all_people_f rec
                 WHERE  rec.person_id =paf.recruiter_id
                   AND  SYSDATE BETWEEN rec.effective_start_date AND rec.effective_end_date) rec_email,
               (SELECT email_address
                  FROM per_all_people_f rec
                 WHERE rec.person_id =paf.supervisor_id
                   AND SYSDATE BETWEEN rec.effective_start_date AND rec.effective_end_date) mgr_email
         FROM  per_all_assignments_f paf,
               per_all_people_f can,
               per_assignment_status_types pas,
               per_all_vacancies pav
        WHERE  paf.assignment_id = p_assnt_id
          AND  pav.vacancy_id = paf.vacancy_id
          AND  can.person_id = paf.person_id
          AND  SYSDATE BETWEEN can.effective_start_date AND can.effective_end_date
          AND  pas.assignment_status_type_id = paf.assignment_status_type_id
          AND  SYSDATE BETWEEN paf.effective_start_date AND paf.effective_end_date;

       x_cur_rec                   C_MAIL_RECIPIENT%ROWTYPE;

       x_xml_event_data            XMLTYPE;
       x_key                       VARCHAR2(50);
       x_assignment_id             NUMBER;
       x_obj_ver_no                NUMBER;
       x_err_code                  NUMBER;
       x_msg_sub                   VARCHAR2(500);
       x_msg_body                  VARCHAR2(1000);
       x_msg_sender                VARCHAR2(100):='iRecruitment.Notifications@integralife.com';
       x_err_msg                   VARCHAR2(240);

       PRAGMA                      AUTONOMOUS_TRANSACTION;

    BEGIN

       x_err_code := xx_emf_pkg.set_env('XX_IRC_NOTIF_BE_PKG');

       x_assignment_id:=p_assignment_id;
       OPEN c_mail_recipient(x_assignment_id);

       FETCH c_mail_recipient
        INTO x_cur_rec;
       IF c_mail_recipient%NOTFOUND
          THEN
            xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                             ,p_category                 => 'iRrec Trigger Notification'
                             ,p_error_text               => 'APPLICANT STATUS CHANGE-No Assignment Data Found '
                             ,p_record_identifier_1      => x_assignment_id
                             ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                            );
            RETURN 'ERROR';
       END IF;
       CLOSE c_mail_recipient;

       IF p_appl_status = 'Manager Review Complete'
          THEN
            IF x_cur_rec.rec_email IS NOT NULL
               THEN
                 BEGIN
                    /* This will set the langaunge of the message body, based on language preferrence of the recruiter */
                    xx_intg_common_pkg.set_session_language( p_email_id => x_cur_rec.rec_email );

                    x_msg_sub:=xx_intg_common_pkg.set_long_message( 'XX_IRC_MGR_RVCPL_MSG_SUB');
                    x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_MGR_RVCPL_MSG_BODY'
                                                                 ,p_token_value1  =>x_cur_rec.irc_name
                                                                 ,p_token_value2  =>x_cur_rec.applicant_name
                                                                 ,p_no_of_tokens  => 2
                                                                    );
                 EXCEPTION
                    WHEN OTHERS
                       THEN
                         x_err_msg:=substr(SQLERRM,0,230);
                         xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                          ,p_category                 => 'iRrec Trigger Notification'
                                          ,p_error_text               => 'APPLICANT STATUS CHANGE-Cannot Set the Message Subject and Body '
                                          ,p_record_identifier_1      => x_assignment_id
                                          ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                          ,p_record_identifier_6      => x_err_msg
                                         );
                      RETURN 'ERROR';
                 END;

                 BEGIN
                    xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                                ,recipients => x_cur_rec.rec_email
                                                ,subject    => x_msg_sub
                                                ,message    => x_msg_body
                                               );
                 EXCEPTION
                 WHEN OTHERS
                   THEN
                     x_err_msg:=substr(SQLERRM,0,230);
                     xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                      ,p_category                 => 'iRrec Trigger Notification'
                                      ,p_error_text               => 'APPLICANT STATUS CHANGE-Cannot Send Mail - Check Common Mailer Ulitilty '
                                      ,p_record_identifier_1      => x_assignment_id
                                      ,p_record_identifier_2      => 'XX_IRC_NOTIF_TRG_PKG'
                                      ,p_record_identifier_3      => x_cur_rec.rec_email
                                      ,p_record_identifier_4      => p_appl_status
                                      ,p_record_identifier_6      => x_err_msg
                                     );
                     RETURN 'ERROR';
                 END;
                 RETURN 'SUCCESS';
            ElSE
                xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                 ,p_category                 => 'iRrec Trigger Notification'
                                 ,p_error_text               => 'APPLICANT STATUS CHANGE- Recuriter Email is Not Available in PER_ALL_PEOPLE_F'
                                 ,p_record_identifier_1      => x_assignment_id
                                 ,p_record_identifier_2      => 'XX_IRC_NOTIF_TRG_PKG'
                                 ,p_record_identifier_3      => x_cur_rec.rec_email
                                 ,p_record_identifier_4      => p_appl_status
                                );
                RETURN 'ERROR';
            END IF;

       ELSIF p_appl_status = 'Manager Review'
         THEN
            IF x_cur_rec.mgr_email IS NOT NULL
               THEN
                 BEGIN
                    /* This will set the langaunge of the message body, based on language preferrence of the manager */
                    xx_intg_common_pkg.set_session_language( p_email_id => x_cur_rec.mgr_email );

                    x_msg_sub:=xx_intg_common_pkg.set_long_message( 'XX_IRC_MGR_RV_MSG_SUB');

                    x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_MGR_RV_MSG_BODY'
                                                                 ,p_token_value1  =>x_cur_rec.irc_name
                                                                 ,p_token_value2  =>x_cur_rec.applicant_name
                                                                 ,p_no_of_tokens  => 2
                                                                    );
                 EXCEPTION
                    WHEN OTHERS
                       THEN
                         x_err_msg:=substr(SQLERRM,0,230);
                         xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                          ,p_category                 => 'iRrec Trigger Notification'
                                          ,p_error_text               => 'APPLICANT STATUS CHANGE-Cannot Set the Message Subject and Body '
                                          ,p_record_identifier_1      => x_assignment_id
                                          ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                          ,p_record_identifier_6      => x_err_msg
                                         );
                      RETURN 'ERROR';
                 END;

                 BEGIN
                    xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                                ,recipients => x_cur_rec.mgr_email
                                                ,subject    => x_msg_sub
                                                ,message    => x_msg_body
                                               );
                 EXCEPTION
                 WHEN OTHERS
                   THEN
                     x_err_msg:=substr(SQLERRM,0,230);
                     xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                      ,p_category                 => 'iRrec Trigger Notification'
                                      ,p_error_text               => 'APPLICANT STATUS CHANGE-Cannot Send Mail - Check Common Mailer Ulitilty '
                                      ,p_record_identifier_1      => x_assignment_id
                                      ,p_record_identifier_2      => 'XX_IRC_NOTIF_TRG_PKG'
                                      ,p_record_identifier_3      => x_cur_rec.mgr_email
                                      ,p_record_identifier_4      => p_appl_status
                                      ,p_record_identifier_6      => x_err_msg
                                     );
                     RETURN 'ERROR';
                 END;
                 RETURN 'SUCCESS';
            ElSE
                xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                 ,p_category                 => 'iRrec Trigger Notification'
                                 ,p_error_text               => 'APPLICANT STATUS CHANGE- Manager Email is Not Available in PER_ALL_PEOPLE_F'
                                 ,p_record_identifier_1      => x_assignment_id
                                 ,p_record_identifier_2      => 'XX_IRC_NOTIF_TRG_PKG'
                                 ,p_record_identifier_3      => x_cur_rec.mgr_email
                                 ,p_record_identifier_4      => p_appl_status
                                );
                RETURN 'ERROR';
            END IF;
       END IF;
    COMMIT;
    END applicant_status_chg_notif;

----------------------------------------------------------------------
/* This function is called when an applicant is terminated */

    FUNCTION applicant_asg_terminate_notif( p_assignment_id   IN      NUMBER
                               ,p_appl_status     IN      VARCHAR2)
    RETURN VARCHAR2
    IS
       CURSOR c_mail_recipient(p_assnt_id number)
       IS
       SELECT  can.email_address can_email,
               ipc.job_title,
               pac.name irc_name,
               pac.vacancy_id,
               (SELECT  email_address
                  FROM  per_all_people_f rec
                 WHERE  rec.person_id =paf.recruiter_id
                   AND  SYSDATE BETWEEN rec.effective_start_date AND rec.effective_end_date) rec_email,
               (SELECT  email_address
                  FROM  per_all_people_f rec
                 WHERE  rec.person_id =paf.supervisor_id
                   AND  SYSDATE BETWEEN rec.effective_start_date AND rec.effective_end_date) mgr_email
         FROM  per_all_assignments_f paf,
               per_all_people_f can,
               irc_posting_contents_tl ipc,
               per_all_vacancies pac
        WHERE  paf.assignment_id =p_assnt_id
          AND  ipc.posting_content_id = pac.primary_posting_id
          AND  ipc.language='US'
          AND  pac.vacancy_id = paf.vacancy_id
          AND  can.person_id = paf.person_id
          AND  can.effective_end_date in ( SELECT MAX(effective_end_date)
                                         FROM per_all_people_f
                                            WHERE person_id = paf.person_id)
          AND  paf.effective_end_date in ( SELECT MAX(effective_end_date)
                                             FROM per_all_assignments_f
                                            WHERE assignment_id = paf.assignment_id)
          AND  paf.assignment_type = 'A';

       x_cur_rec                   C_MAIL_RECIPIENT%ROWTYPE;

       x_xml_event_data            XMLTYPE;
       x_key                       VARCHAR2(50);
       x_assignment_id             NUMBER;
       x_obj_ver_no                NUMBER;
       x_err_code                  NUMBER;
       x_msg_sub                   VARCHAR2(500);
       x_msg_body                  VARCHAR2(2400);
       x_msg_sender                VARCHAR2(100):='iRecruitment.Notifications@integralife.com';
       x_err_msg                   VARCHAR2(240);
       l_count number;

       PRAGMA                      AUTONOMOUS_TRANSACTION;
    BEGIN
       x_err_code := xx_emf_pkg.set_env('XX_IRC_NOTIF_BE_PKG');

       x_assignment_id:=p_assignment_id;


       OPEN c_mail_recipient(x_assignment_id);

       FETCH c_mail_recipient
        INTO x_cur_rec;
       IF c_mail_recipient%NOTFOUND
          THEN
            xx_emf_pkg.error(p_severity                 => xx_emf_cn_pkg.cn_medium
                             ,p_category                 => 'iRrec Trigger Notification'
                             ,p_error_text               => 'APPLICANT ASG TERMINATE-No Assignment Data Found'
                             ,p_record_identifier_1      => x_assignment_id
                             ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                            );
            Commit;
            RETURN 'ERROR';
       END IF;
       CLOSE c_mail_recipient;

       IF x_cur_rec.can_email is null
          THEN
            xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                             ,p_category                 => 'iRrec Trigger Notification'
                             ,p_error_text               => 'APPLICANT ASG TERMINATE-Candidate Email is Not Available'
                             ,p_record_identifier_1      => x_assignment_id
                             ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                            );
            Commit;
            RETURN 'ERROR';
       END IF;

       BEGIN
        select count(*)
        into l_count
        from xxintg_irec_trig_data
        where vacancy_id= x_cur_rec.vacancy_id
        and assignment_id=x_assignment_id
        and application_status = p_appl_status
        and effective_date = trunc(sysdate);
      EXCEPTION
            when others then
              l_count := 0;
      END;




       BEGIN
          IF p_appl_status = 'APPLICATION CLOSED' THEN

              /* This will set the langaunge of the message body, based on language preferrence of the Candidate */
              xx_intg_common_pkg.set_session_language( p_email_id => x_cur_rec.can_email );

              x_msg_sub:=xx_intg_common_pkg.set_long_message( 'XX_IRC_APL_CLOSED_MSG_SUB');

              x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_APL_CLOSED_MSG_BODY'
                                                           ,p_token_value1  =>x_cur_rec.irc_name
                                                           ,p_token_value2  =>x_cur_rec.job_title
                                                           ,p_no_of_tokens  => 2
                                                              );

          ELSIF p_appl_status = 'POSITION CLOSED' THEN

              /* This will set the langaunge of the message body, based on language preferrence of the Candidate */
              xx_intg_common_pkg.set_session_language( p_email_id => x_cur_rec.can_email );

              x_msg_sub:=xx_intg_common_pkg.set_long_message( 'XX_IRC_POS_CLOSED_MSG_SUB');

              x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_POS_CLOSED_MSG_BODY'
                                                           ,p_token_value1  =>x_cur_rec.irc_name
                                                           ,p_token_value2  =>x_cur_rec.job_title
                                                           ,p_no_of_tokens  => 2
                                                              );
          END IF;
       EXCEPTION
          WHEN OTHERS
             THEN
               x_err_msg:=substr(SQLERRM,0,230);
               xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                ,p_category                 => 'iRrec Trigger Notification'
                                ,p_error_text               => 'APPLICANT ASG TERMINATE-Cannot Set the Message Subject and Body '
                                ,p_record_identifier_1      => x_assignment_id
                                ,p_record_identifier_2      => 'XX_IRC_NOTIF_TRG_PKG'
                                ,p_record_identifier_6      => x_err_msg
                               );
            commit;
            RETURN 'ERROR';
       END;

       IF l_count = 0 THEN

       BEGIN
          xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                      ,recipients => x_cur_rec.can_email
                                      ,subject    => x_msg_sub
                                      ,message    => x_msg_body
                                     );

          BEGIN
          insert into xxintg_irec_trig_data values(x_assignment_id,x_cur_rec.vacancy_id,p_appl_status, trunc(sysdate));
          commit;
          EXCEPTION
            WHEN OTHERS THEN
                NULL;
           END;
       EXCEPTION
      WHEN OTHERS
      THEN
        x_err_msg:=substr(SQLERRM,0,230);
        xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                         ,p_category                 => 'iRrec Trigger Notification'
                         ,p_error_text               => 'APPLICANT ASG TERMINATE-Cannot Send Mail - Check Common Mailer Ulitilty '
                         ,p_record_identifier_1      => x_assignment_id
                         ,p_record_identifier_2      => 'XX_IRC_NOTIF_TRG_PKG'
                         ,p_record_identifier_3      => x_cur_rec.can_email
                         ,p_record_identifier_4      => p_appl_status
                         ,p_record_identifier_6      => x_err_msg
                        );
            commit;
            RETURN 'ERROR';
       END;

       END IF;

       Commit;
       RETURN 'SUCCESS';

    END applicant_asg_terminate_notif;

-----------------------------------------------------------------------------------------------------------------------------------------------
/* This Function is called when an recruiter applies on behalf of candidate*/

FUNCTION recuriter_add_applicant_notif ( p_assignment_id    IN      NUMBER
                                    ,p_person_id        IN      NUMBER
                                        ,p_assignment_type  IN      VARCHAR2
                                        ,p_asst_sts_typ_id  IN      NUMBER
                                        ,p_vacancy_id       IN      NUMBER
                                        ,p_old_vacancy_id   IN      NUMBER
                                        ,p_created_by_id    IN      NUMBER
                                       )
    RETURN VARCHAR2
    IS
       CURSOR c_candidate_details(p_per_id NUMBER)
       IS
       SELECT  ppf.person_id,
               ppf.full_name,
               ppf.email_address
         FROM  per_all_people_f ppf
        WHERE  ppf.person_id = p_per_id
          AND  SYSDATE BETWEEN ppf.effective_start_date AND ppf.effective_end_date;

       CURSOR c_created_by(p_user_id NUMBER)
       IS
          SELECT  pv.vendor_name
        FROM  fnd_profile_option_values pov,
              fnd_application appl,
            fnd_user fu,
            fnd_profile_options pro,
            fnd_profile_options_tl pro1,
            po_vendors pv
       WHERE  pro1.user_profile_option_name like ('IRC: Agency Name')
         AND  pro.profile_option_name = pro1.profile_option_name
         AND  pro.profile_option_id = pov.profile_option_id
         AND  pov.level_value = appl.application_id (+)
         AND  pov.level_value = fu.user_id (+)
         AND  pro1.LANGUAGE = 'US'
         AND  pv.vendor_type_lookup_code = 'IRC_JOB_AGENCY'
         AND  to_char(pv.vendor_id) = pov.profile_option_value
         AND  pov.level_id = 10004   --User Level Profile Value
             AND  fu.user_id = p_user_id;

       CURSOR c_job_title(p_vac_id NUMBER)
       IS
          SELECT  job_title
            FROM  irc_posting_contents_tl ipc,
                  per_all_vacancies pac
           WHERE  ipc.posting_content_id = pac.primary_posting_id
             AND  ipc.language='US'
             AND  pac.vacancy_id = p_vac_id;


       x_cur_rec                   C_CANDIDATE_DETAILS%ROWTYPE;

       x_assignment_id             NUMBER;
       x_obj_ver_no                NUMBER;
       x_err_code                  NUMBER;
       x_msg_sub                   VARCHAR2(500);
       x_msg_body                  VARCHAR2(1000);
       x_msg_sender                VARCHAR2(100):='iRecruitment.Notifications@integralife.com';
       x_assigment_type            VARCHAR2(20);
       x_err_msg                   VARCHAR2(240);
       x_is_applicant               VARCHAR2(5);
       x_agency_name               VARCHAR2(50);
       x_job_title                 VARCHAR2(240);
       x_agn_rec_applied           VARCHAR2(5):='N';

       PRAGMA                      AUTONOMOUS_TRANSACTION;

    BEGIN

       IF p_old_vacancy_id IS NULL AND p_vacancy_id IS NOT NULL
       THEN

          x_err_code := xx_emf_pkg.set_env('XX_IRC_NOTIF_BE_PKG');

          x_assigment_type:=p_assignment_type;
          x_assignment_id:=p_assignment_id;
          BEGIN
             SELECT  'Y'
               INTO  x_is_applicant
               FROM  per_assignment_status_types
              WHERE  assignment_status_type_id = p_asst_sts_typ_id
                AND  user_status = 'Active Application';
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                Commit;
                RETURN 'SUCCESS';
          END;

          BEGIN
             SELECT  'Y'
               INTO  x_agn_rec_applied
               FROM  fnd_profile_option_values pov,
                 fnd_application appl,
                 fnd_user fu,
                 fnd_profile_options pro,
                 fnd_profile_options_tl pro1,
                 po_vendors pv
          WHERE  pro1.user_profile_option_name like ('IRC: Agency Name')
            AND  pro.profile_option_name = pro1.profile_option_name
            AND  pro.profile_option_id = pov.profile_option_id
            AND  pov.level_value = appl.application_id (+)
            AND  pov.level_value = fu.user_id (+)
            AND  pro1.LANGUAGE = 'US'
            AND  pv.vendor_type_lookup_code = 'IRC_JOB_AGENCY'
            AND  to_char(pv.vendor_id) = pov.profile_option_value
            AND  pov.level_id = 10004   --User Level Profile Value
                AND  fu.user_id = p_created_by_id;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                x_agn_rec_applied := 'N';
             WHEN OTHERS THEN
                x_agn_rec_applied := 'N';
          END;

          IF x_agn_rec_applied = 'N'
          THEN
             BEGIN
                SELECT  'Y'
                  INTO  x_agn_rec_applied
                  FROM  per_all_people_f ppf,
                 fnd_user fu,
                 per_all_vacancies pav
          WHERE  fu.user_id = p_created_by_id
            AND  ppf.person_id = fu.employee_id
            AND  SYSDATE BETWEEN ppf.effective_start_date AND ppf.effective_end_date
            AND  pav.recruiter_id = ppf.person_id
                   AND  pav.vacancy_id = p_vacancy_id;
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   Commit;
                   RETURN 'SUCCESS';
                WHEN OTHERS THEN
                   Commit;
                   RETURN 'SUCCESS';
             END;
          END IF;


          OPEN c_created_by(p_created_by_id);

          FETCH c_created_by
          INTO x_agency_name ;

          CLOSE c_created_by;

          OPEN c_job_title(p_vacancy_id);

          FETCH c_job_title
          INTO x_job_title ;

          CLOSE c_job_title;
          IF x_assigment_type = 'A' AND x_agn_rec_applied = 'Y'
           THEN
             OPEN c_candidate_details(p_person_id );

             FETCH c_candidate_details
              INTO x_cur_rec;
             IF c_candidate_details%NOTFOUND
                THEN
                  xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                   ,p_category                 => 'iRrec Trigger Notification'
                                   ,p_error_text               => 'ADD APPLICANT-Candidate details not found'
                                   ,p_record_identifier_1      => x_assignment_id
                                   ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                  );
                  Commit;
                  RETURN 'ERROR';
             END IF;
             CLOSE c_candidate_details;

             BEGIN
                /* This will set the langaunge of the message body, based on language preferrence of the Candidate */
                xx_intg_common_pkg.set_session_language( p_email_id => x_cur_rec.email_address );

                x_msg_sub:=xx_intg_common_pkg.set_long_message( 'XX_IRC_AGN_APLJOB_MSG_SUB');
                x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_AGN_APLJOB_MSG_BODY'
                                                             ,p_token_value1  =>x_agency_name
                                                             ,p_token_value2  =>x_job_title
                                                             ,p_no_of_tokens  => 2
                                                                );
             EXCEPTION
                WHEN OTHERS
                   THEN
                     x_err_msg:=substr(SQLERRM,0,230);
                     xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                      ,p_category                 => 'iRrec Trigger Notification'
                                      ,p_error_text               => 'ADD APPLICANT-Cannot Set the Message Subject and Body '
                                      ,p_record_identifier_1      => x_assignment_id
                                      ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                      ,p_record_identifier_6      =>x_err_msg
                                     );
                  commit;
                  RETURN 'ERROR';
             END;

             BEGIN
                IF x_cur_rec.email_address IS NOT NULL THEN

                   xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                               ,recipients => x_cur_rec.email_address
                                               ,subject    => x_msg_sub
                                               ,message    => x_msg_body
                                              );
                ELSE
                   xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                    ,p_category                 => 'iRrec Trigger Notification'
                                    ,p_error_text               => 'ADD APPLICANT-Cannot Send Mail - Email address is NULL '
                                    ,p_record_identifier_1      => x_assignment_id
                                    ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                    ,p_record_identifier_3      => x_cur_rec.email_address
                                   );
                END IF;
             EXCEPTION
                         WHEN OTHERS
                THEN
                  x_err_msg:=substr(SQLERRM,0,230);
                  xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                   ,p_category                 => 'iRrec Trigger Notification'
                                   ,p_error_text               => 'ADD APPLICANT-Cannot Send Mail - Check Common Mailer Ulitilty '
                                   ,p_record_identifier_1      => x_assignment_id
                                   ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                   ,p_record_identifier_3      => x_cur_rec.email_address
                                   ,p_record_identifier_6      => x_err_msg
                                  );
                  commit;
                  RETURN 'ERROR';
             END;
          END IF;
        END IF;
       RETURN 'SUCCESS';
    END recuriter_add_applicant_notif;

-----------------------------------------------------------------------------------------------------------------------------------------------
/* This Function is called when an AGENCY applies on behalf of candidate*/

FUNCTION agn_add_applicant_notif ( p_assignment_id    IN      NUMBER
                              ,p_person_id        IN      NUMBER
                                  ,p_assignment_type  IN      VARCHAR2
                                  ,p_asst_sts_typ_id  IN      NUMBER
                                  ,p_vacancy_id       IN      NUMBER
                                  ,p_created_by_id    IN      NUMBER
                                 )
    RETURN VARCHAR2
    IS
       CURSOR c_candidate_details(p_per_id NUMBER)
       IS
       SELECT  ppf.person_id,
               ppf.full_name,
               ppf.email_address
         FROM  per_all_people_f ppf
        WHERE  ppf.person_id = p_per_id
          AND  SYSDATE BETWEEN ppf.effective_start_date AND ppf.effective_end_date;

       CURSOR c_created_by(p_user_id NUMBER)
       IS
          SELECT  pv.vendor_name
        FROM  fnd_profile_option_values pov,
              fnd_application appl,
            fnd_user fu,
            fnd_profile_options pro,
            fnd_profile_options_tl pro1,
            po_vendors pv
       WHERE  pro1.user_profile_option_name like ('IRC: Agency Name')
         AND  pro.profile_option_name = pro1.profile_option_name
         AND  pro.profile_option_id = pov.profile_option_id
         AND  pov.level_value = appl.application_id (+)
         AND  pov.level_value = fu.user_id (+)
         AND  pro1.LANGUAGE = 'US'
         AND  pv.vendor_type_lookup_code = 'IRC_JOB_AGENCY'
         AND  to_char(pv.vendor_id) = pov.profile_option_value
         AND  pov.level_id = 10004   --User Level Profile Value
             AND  fu.user_id = p_user_id;

       CURSOR c_job_title(p_vac_id NUMBER)
       IS
          SELECT  job_title
            FROM  irc_posting_contents_tl ipc,
                  per_all_vacancies pac
           WHERE  ipc.posting_content_id = pac.primary_posting_id
             AND  ipc.language='US'
             AND  pac.vacancy_id = p_vac_id;


       x_cur_rec                   C_CANDIDATE_DETAILS%ROWTYPE;

       x_assignment_id             NUMBER;
       x_obj_ver_no                NUMBER;
       x_err_code                  NUMBER;
       x_msg_sub                   VARCHAR2(500);
       x_msg_body                  VARCHAR2(1000);
       x_msg_sender                VARCHAR2(100):='iRecruitment.Notifications@integralife.com';
       x_assigment_type            VARCHAR2(20);
       x_err_msg                   VARCHAR2(240);
       x_is_applicant               VARCHAR2(5);
       x_agency_name               VARCHAR2(50);
       x_job_title                 VARCHAR2(240);
       x_agn_rec_applied           VARCHAR2(5):='N';

       PRAGMA                      AUTONOMOUS_TRANSACTION;

    BEGIN

          x_err_code := xx_emf_pkg.set_env('XX_IRC_NOTIF_BE_PKG');

          x_assigment_type:=p_assignment_type;
          x_assignment_id:=p_assignment_id;
          BEGIN
             SELECT  'Y'
               INTO  x_is_applicant
               FROM  per_assignment_status_types
              WHERE  assignment_status_type_id = p_asst_sts_typ_id
                AND  user_status = 'Active Application';
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                Commit;
                RETURN 'SUCCESS';
          END;

          IF p_vacancy_id is null
          THEN
             Commit;
         RETURN 'SUCCESS';
          END IF;

          BEGIN
             SELECT  'Y'
               INTO  x_agn_rec_applied
               FROM  fnd_profile_option_values pov,
                 fnd_application appl,
                 fnd_user fu,
                 fnd_profile_options pro,
                 fnd_profile_options_tl pro1,
                 po_vendors pv
          WHERE  pro1.user_profile_option_name like ('IRC: Agency Name')
            AND  pro.profile_option_name = pro1.profile_option_name
            AND  pro.profile_option_id = pov.profile_option_id
            AND  pov.level_value = appl.application_id (+)
            AND  pov.level_value = fu.user_id (+)
            AND  pro1.LANGUAGE = 'US'
            AND  pv.vendor_type_lookup_code = 'IRC_JOB_AGENCY'
            AND  to_char(pv.vendor_id) = pov.profile_option_value
            AND  pov.level_id = 10004   --User Level Profile Value
                AND  fu.user_id = p_created_by_id;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                   Commit;
                   RETURN 'SUCCESS';
             WHEN OTHERS THEN
                   Commit;
                   RETURN 'SUCCESS';
          END;


          OPEN c_created_by(p_created_by_id);

          FETCH c_created_by
          INTO x_agency_name ;

          CLOSE c_created_by;

          OPEN c_job_title(p_vacancy_id);

          FETCH c_job_title
          INTO x_job_title ;

          CLOSE c_job_title;
          IF x_assigment_type = 'A' AND x_agn_rec_applied = 'Y'
           THEN
             OPEN c_candidate_details(p_person_id );

             FETCH c_candidate_details
              INTO x_cur_rec;
             IF c_candidate_details%NOTFOUND
                THEN
                  xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                   ,p_category                 => 'iRrec Trigger Notification'
                                   ,p_error_text               => 'ADD APPLICANT-Candidate details not found'
                                   ,p_record_identifier_1      => x_assignment_id
                                   ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                  );
                  Commit;
                  RETURN 'ERROR';
             END IF;
             CLOSE c_candidate_details;

             BEGIN
                /* This will set the langaunge of the message body, based on language preferrence of the Candidate */
                xx_intg_common_pkg.set_session_language( p_email_id => x_cur_rec.email_address );

                x_msg_sub:=xx_intg_common_pkg.set_long_message( 'XX_IRC_AGN_APLJOB_MSG_SUB');
                x_msg_body:=xx_intg_common_pkg.set_token_message( p_message_name  =>'XX_IRC_AGN_APLJOB_MSG_BODY'
                                                          ,p_token_value1  =>x_agency_name
                                                          ,p_token_value2  =>x_job_title
                                                          ,p_no_of_tokens  => 2
                                                                );
             EXCEPTION
                WHEN OTHERS
                   THEN
                     x_err_msg:=substr(SQLERRM,0,230);
                     xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                      ,p_category                 => 'iRrec Trigger Notification'
                                      ,p_error_text               => 'ADD APPLICANT-Cannot Set the Message Subject and Body '
                                      ,p_record_identifier_1      => x_assignment_id
                                      ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                      ,p_record_identifier_6      =>x_err_msg
                                     );
                  commit;
                  RETURN 'ERROR';
             END;

             BEGIN
                IF x_cur_rec.email_address IS NOT NULL THEN
                   xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                               ,recipients => x_cur_rec.email_address
                                               ,subject    => x_msg_sub
                                               ,message    => x_msg_body
                                              );
                ELSE
                   xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                    ,p_category                 => 'iRrec Trigger Notification'
                                    ,p_error_text               => 'ADD APPLICANT-Cannot Send Mail - Email address is NULL '
                                    ,p_record_identifier_1      => x_assignment_id
                                    ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                    ,p_record_identifier_3      => x_cur_rec.email_address
                                   );
                END IF;
             EXCEPTION
                         WHEN OTHERS
                THEN
                  x_err_msg:=substr(SQLERRM,0,230);
                  xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                   ,p_category                 => 'iRrec Trigger Notification'
                                   ,p_error_text               => 'ADD APPLICANT-Cannot Send Mail - Check Common Mailer Ulitilty '
                                   ,p_record_identifier_1      => x_assignment_id
                                   ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                                   ,p_record_identifier_3      => x_cur_rec.email_address
                                   ,p_record_identifier_6      => x_err_msg
                                  );
                  commit;
                  RETURN 'ERROR';
             END;
          END IF;
       RETURN 'SUCCESS';
    END agn_add_applicant_notif;

----------------------------------------------------------------------

    FUNCTION applicant_sts_change_notif( p_assignment_id       IN      NUMBER
                                        ,p_assignment_type_id  IN      NUMBER)
    RETURN VARCHAR2
    IS
       CURSOR c_apl_status(p_assnt_type_id NUMBER)
       IS
       SELECT  user_status
         FROM  per_assignment_status_types
        WHERE  assignment_status_type_id = p_assnt_type_id;

       CURSOR c_external_status(p_assnt_type_id NUMBER)
       IS
       SELECT  upper(external_status)
         FROM  per_assignment_status_types_tl
        WHERE  assignment_status_type_id = p_assnt_type_id
          AND  language = 'US';


       x_appl_status               VARCHAR2(250);
       x_ext_status                VARCHAR2(250);
       x_ret_msg                   VARCHAR2(50);

    BEGIN
       OPEN c_apl_status(p_assignment_type_id);

       FETCH c_apl_status
        INTO x_appl_status;

       CLOSE c_apl_status;

       OPEN c_external_status(p_assignment_type_id);

       FETCH c_external_status
        INTO x_ext_status;

       CLOSE c_external_status;


       IF x_appl_status = 'Manager Review Complete' OR x_appl_status = 'Manager Review'
          THEN
            x_ret_msg :=xx_irc_notif_trg_pkg.applicant_status_chg_notif( p_assignment_id
                                                                        ,x_appl_status);
            RETURN x_ret_msg;
       END IF;

       IF x_ext_status = 'APPLICATION CLOSED' OR x_ext_status ='POSITION CLOSED'
          THEN
            x_ret_msg :=xx_irc_notif_trg_pkg.applicant_asg_terminate_notif( p_assignment_id
                                                                           ,x_ext_status);
            RETURN x_ret_msg;
       END IF;
       RETURN 'SUCCESS';
    END applicant_sts_change_notif;

----------------------------------------------------------------------
/* This function is triggered when a candidate is registered by Agency */

    FUNCTION agn_candidate_reg_notif ( p_created_by_id   IN    NUMBER
                                      ,p_person_id       IN    NUMBER
                                      ,p_person_type_id    IN    NUMBER
                                      ,p_can_name        IN    VARCHAR2
                                      ,p_can_email       IN    VARCHAR2
                                     )
    RETURN VARCHAR2
    IS

       CURSOR c_created_by(p_user_id NUMBER)
       IS
          SELECT  pv.vendor_name
        FROM  fnd_profile_option_values pov,
              fnd_application appl,
            fnd_user fu,
            fnd_profile_options pro,
            fnd_profile_options_tl pro1,
            po_vendors pv
       WHERE  pro1.user_profile_option_name like ('IRC: Agency Name')
         AND  pro.profile_option_name = pro1.profile_option_name
         AND  pro.profile_option_id = pov.profile_option_id
         AND  pov.level_value = appl.application_id (+)
         AND  pov.level_value = fu.user_id (+)
         AND  pro1.LANGUAGE = 'US'
         AND  pv.vendor_type_lookup_code = 'IRC_JOB_AGENCY'
         AND  to_char(pv.vendor_id) = pov.profile_option_value
         AND  pov.level_id = 10004   --User Level Profile Value
             AND  fu.user_id = p_user_id;

       x_key                       VARCHAR2(50);
       x_usr_id                    VARCHAR2(250);
       x_agency_name               VARCHAR2(250);
       x_party_id                  VARCHAR2(250);
       x_can_name                  VARCHAR2(250);
       x_can_email                 VARCHAR2(250);
       x_msg_sub                   VARCHAR2(500);
       x_msg_body                  VARCHAR2(1000);
       x_msg_sender                VARCHAR2(100):='iRecruitment.Notifications@integralife.com';
       x_err_code                  NUMBER;
       x_err_msg                   VARCHAR2(240);
       x_is_candidate              VARCHAR2(5);

       PRAGMA                      AUTONOMOUS_TRANSACTION;
    BEGIN
       x_err_code := xx_emf_pkg.set_env('XX_IRC_NOTIF_BE_PKG');

       OPEN c_created_by(p_created_by_id);

       FETCH c_created_by
        INTO x_agency_name ;

       IF c_created_by%NOTFOUND
          THEN
            commit;
            RETURN 'SUCCESS';
       END IF;

       BEGIN
          SELECT 'Y'
            INTO x_is_candidate
            FROM per_person_types
           WHERE user_person_type = 'Contact'
             AND person_type_id   = p_person_type_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             Commit;
             RETURN 'SUCCESS';
       END;


       CLOSE c_created_by;

       x_can_email:=p_can_email;
       x_can_name:=p_can_name;

       BEGIN
          /* This will set the langaunge of the message body, based on language preferrence of the Candidate */
          xx_intg_common_pkg.set_session_language( p_email_id => x_can_email );

          x_msg_sub:=xx_intg_common_pkg.set_long_message( 'XX_IRC_AGN_CANREG_MSG_SUB'
                                                         ,x_agency_name
                                                        );
          x_msg_body:=xx_intg_common_pkg.set_long_message( 'XX_IRC_AGN_CANREG_MSG_BODY'
                                                          ,x_agency_name
                                                         );
       EXCEPTION
          WHEN OTHERS
             THEN
               x_err_msg:=substr(SQLERRM,0,230);
            xx_emf_pkg.error(p_severity                 => xx_emf_cn_pkg.cn_medium
                    ,p_category                 => 'iRrec Trigger Notification'
                    ,p_error_text               => 'AGENCY CANDIDATE CREATION-Cannot Set the Message Subject and Body '
                    ,p_record_identifier_1      => p_person_id
                    ,p_record_identifier_2      => 'XX_IRC_NOTIF_TRG_PKG'
                    ,p_record_identifier_6      => x_err_msg
                            );
            commit;
            RETURN 'ERROR';
       END;


       IF x_can_email IS NOT NULL AND x_is_candidate = 'Y'
          THEN
            BEGIN
               xx_intg_mail_util_pkg.mail ( sender     => x_msg_sender
                                    ,recipients => x_can_email
                                   ,subject    => x_msg_sub
                                   ,message    => x_msg_body
                                       );
        EXCEPTION
          WHEN OTHERS
          THEN
            x_err_msg:=substr(SQLERRM,0,230);
                xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                         ,p_category                 => 'iRrec Trigger Notification'
                         ,p_error_text               => 'AGENCY CANDIDATE CREATION-Cannot Send Mail - Check Common Mailer Ulitilty '
                         ,p_record_identifier_1      => p_person_id
                         ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                         ,p_record_identifier_3      => x_agency_name
                         ,p_record_identifier_4      => x_can_name
                         ,p_record_identifier_5      => x_can_email
                         ,p_record_identifier_6      => x_err_msg
                                );
                commit;
                RETURN 'ERROR';
        END;

       ELSE
            xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                     ,p_category                 => 'iRrec Trigger Notification'
                     ,p_error_text               => 'AGENCY CANDIDATE CREATION-Candidate Email is Not Available'
                     ,p_record_identifier_1      => p_person_id
                     ,p_record_identifier_2      =>'XX_IRC_NOTIF_TRG_PKG'
                     ,p_record_identifier_3      => x_agency_name
                     ,p_record_identifier_4      => x_can_name
                     ,p_record_identifier_5      => x_can_email
                            );
           commit;
       RETURN 'ERROR';
       END IF;

    END agn_candidate_reg_notif;


END xx_irc_notif_trg_pkg;
/
