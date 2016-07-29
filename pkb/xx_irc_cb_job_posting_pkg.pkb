DROP PACKAGE BODY APPS.XX_IRC_CB_JOB_POSTING_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_IRC_CB_JOB_POSTING_PKG" 
AS
/* $Header: XX_IRC_CB_JOB_POSTING_PKG.pkb 1.0.0 2012/05/23 700:00:00 riqbal noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Raquib Iqbal
 Creation Date  : 23-MAY-2012
 Filename       : XX_IRC_CB_JOB_POSTING_PKG.pks
 Description    : This package is used to post job to external sites using Web-Service

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 23-May-2012   1.0       Raquib Iqbal        Initial development.
 23-Mar-2013   1.1       Raquib Iqbal        Ticket# 2011
 */
--------------------------------------------------------------------------------
   g_enable_flag   VARCHAR2 (3)
      := xx_emf_pkg.get_paramater_value ('XX_H2R_CAREER_BUILDER_INT_006',
                                         'ENABLE_FLAG'
                                        );

--**********************************************************************
 ----Procedure to set environment.
--**********************************************************************
   PROCEDURE set_cnv_env (p_required_flag VARCHAR2
            DEFAULT xx_emf_cn_pkg.cn_yes)
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside set_cnv_env...');
      -- Set the environment
      x_error_code :=
         xx_emf_pkg.set_env
                           (p_process_name      => 'XX_H2R_CAREER_BUILDER_INT_006');

      IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

--**********************************************************************
 ----Procedure to send email notification for posting error.
--**********************************************************************
   PROCEDURE xx_irc_send_notification (
      p_recruitment_activity_id   IN   VARCHAR2,
      p_status                    IN   VARCHAR2
   )
   IS
      x_email_status    NUMBER          := NULL;
      x_email_address   VARCHAR2 (360)  := NULL;
      x_first_name      VARCHAR2 (360)  := NULL;
      x_vacancy_name    VARCHAR2 (360)  := NULL;
      x_job_title       VARCHAR2 (1000) := NULL;
   BEGIN
      BEGIN
         SELECT ppf.first_name, ppf.email_address, pav.NAME, pcv.job_title
           INTO x_first_name, x_email_address, x_vacancy_name, x_job_title
           FROM per_all_vacancies pav,
                per_recruitment_activities pra,
                per_people_f ppf,
                irc_posting_contents_vl pcv
          WHERE pav.primary_posting_id = pra.posting_content_id
            AND ppf.person_id = pav.recruiter_id
            AND pcv.posting_content_id = pra.posting_content_id
            AND pra.recruitment_activity_id = p_recruitment_activity_id
            AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (ppf.effective_start_date,
                                                    SYSDATE
                                                   )
                                              )
                                    AND TRUNC (NVL (ppf.effective_end_date,
                                                    SYSDATE
                                                   )
                                              );
      --Added effectivity date validation
      EXCEPTION
         WHEN OTHERS
         THEN
            x_email_address := NULL;
            x_first_name := NULL;
            x_vacancy_name := NULL;
            x_job_title := NULL;
            fnd_file.put_line (fnd_file.LOG,
                                  'Recruiter Email Id and others not defined'
                               || SQLERRM
                              );
      END;

-----------
      BEGIN
         IF x_email_address IS NULL
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Email ID not defined');
         ELSE
            x_email_status :=
               irc_notification_helper_pkg.send_notification
                  (p_email_address      => x_email_address,
                   p_subject            =>    'ACTION REQUIRED: Posting Error '
                                           || x_vacancy_name
                                           || ' '
                                           || x_job_title,
                   p_text_body          =>    ' Hi '
                                           || x_first_name
                                           || ' ,'
                                           || x_vacancy_name
                                           || 'posted to the CareerBuilder errored with following Error message..'
                                           || p_status
                                           || 'Please repost the vacancy'
                  );
            fnd_file.put_line (fnd_file.LOG,
                                  'Email Notfication ID for Posting Error:'
                               || x_email_status
                              );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Error occured while sending email' || SQLERRM
                              );
      END;
   END xx_irc_send_notification;

----------------------------------------------------------------------------------
   FUNCTION xx_irc_get_recruitment_site (p_recruitment_site_id IN NUMBER)
      RETURN VARCHAR2
   AS
      x_lookup_code   VARCHAR2 (30);
   BEGIN
      SELECT flv.lookup_code
        INTO x_lookup_code
        FROM fnd_lookup_values_vl flv, irc_all_recruiting_sites irs
       WHERE flv.lookup_type = 'REC_TYPE'
         AND flv.meaning = irs.internal_name
         AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (irs.date_from, SYSDATE))
                                 AND TRUNC (NVL (irs.date_to, SYSDATE))
         AND flv.enabled_flag = 'Y'
         AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (flv.start_date_active,
                                                 SYSDATE
                                                )
                                           )
                                 AND TRUNC (NVL (flv.end_date_active, SYSDATE))
         AND irs.recruiting_site_id = p_recruitment_site_id;

      RETURN x_lookup_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_lookup_code := NULL;
         RETURN x_lookup_code;
   END xx_irc_get_recruitment_site;

   PROCEDURE xx_irc_post_job_ws (
      p_xml_data       IN       CLOB,
      p_vacancy_name   IN       VARCHAR2,
      o_transact_id    OUT      VARCHAR2,
      o_status         OUT      VARCHAR2
   )
   IS
      x_http_request              UTL_HTTP.req;
      x_http_response             UTL_HTTP.resp;
      x_buffer_size               NUMBER (10)      := 2000;
      x_string_request            CLOB;                   --VARCHAR2 (32767);
      x_substring_msg             VARCHAR2 (2000);
      x_raw_data                  RAW (32767);
      x_response                  VARCHAR2 (32767);
      x_resp                      XMLTYPE;
      x_cb_web_service_url        VARCHAR2 (1000)  := NULL;
      x_recruitment_activity_id   NUMBER           := NULL;
      x_request_body_length       NUMBER           := NULL;
      x_chunk_offset              NUMBER           := NULL;
      x_buffersize                NUMBER (4)       := 2000;
      x_chunk_length              NUMBER           := NULL;
      x_chunk_buffer              VARCHAR2 (4000)  := NULL;
   BEGIN
      x_string_request :=
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:real="http://dpi.careerbuilder.com/WebServices/RealTimeJobPost">
   <soapenv:Header/>
   <soapenv:Body>
      <real:ProcessJob>
        <real:xmlJob>'
         || p_xml_data
         || '</real:xmlJob>
      </real:ProcessJob>
   </soapenv:Body>
</soapenv:Envelope>';

      SELECT    'http://'
             || xx_emf_pkg.get_paramater_value
                                             ('XX_H2R_CAREER_BUILDER_INT_006',
                                              'CB_JOB_POST_WEB_SERVICE'
                                             )
        INTO x_cb_web_service_url
        FROM DUAL;

      UTL_HTTP.set_transfer_timeout (60);
      x_http_request :=
         UTL_HTTP.begin_request (url               => x_cb_web_service_url,
                                 method            => 'POST',
                                 http_version      => 'HTTP/1.1'
                                );
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               => 'Begin Request completed',
                        p_record_identifier_1      => p_vacancy_name,
                        p_record_identifier_2      => NULL
                       );
      ------Added EMF Log Message end------
      UTL_HTTP.set_body_charset (x_http_request, 'UTF-8');
      UTL_HTTP.set_header (x_http_request,
                           'Content-Type',
                           'text/xml;charset=UTF-8'
                          );
      --Chunked encoding added ticket#2011
      UTL_HTTP.set_header (x_http_request, 'Transfer-Encoding', 'chunked');
      UTL_HTTP.set_header
         (x_http_request,
          'SOAPAction',
          '"http://dpi.careerbuilder.com/WebServices/RealTimeJobPost/ProcessJob"'
         );
      --Commented for ticket# 2011
      /*UTL_HTTP.set_header (x_http_request,
                           'Content-Length',
                           LENGTHB ( x_chunk_buffer)
                          );*/
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               => 'Set Header Completed ',
                        p_record_identifier_1      => p_vacancy_name,
                        p_record_identifier_2      => NULL
                       );
      ------Added EMF Log Message end------
      --Commented for ticket#2011
      /*UTL_HTTP.write_raw (r         => x_http_request,
                          DATA      => UTL_RAW.cast_to_raw (x_string_request)
                         );*/
      --Chunked encoding used ticket# 2011
      -- Start of the code change
      x_request_body_length := DBMS_LOB.getlength (x_string_request);
      x_chunk_offset := 1;

      WHILE (x_chunk_offset < x_request_body_length)
      LOOP
         IF x_chunk_offset + x_buffersize >= x_request_body_length
         THEN
            x_chunk_length := x_request_body_length - x_chunk_offset + 1;
         ELSE
            x_chunk_length := x_buffersize;
         END IF;

         DBMS_LOB.READ (x_string_request,
                        x_chunk_length,
                        x_chunk_offset,
                        x_chunk_buffer
                       );
         UTL_HTTP.write_text (x_http_request, x_chunk_buffer);
         x_chunk_offset := x_chunk_offset + x_chunk_length;
      END LOOP;

           --End of code change
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               => 'Write raw completed ',
                        p_record_identifier_1      => p_vacancy_name,
                        p_record_identifier_2      => NULL
                       );
      ------Added EMF Log Message end------
      x_http_response := UTL_HTTP.get_response (x_http_request);
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               => 'Response completed',
                        p_record_identifier_1      => p_vacancy_name,
                        p_record_identifier_2      => NULL
                       );

--select *from xx_emf_error_details where record_identifier_1 ='IRC143'

      ------Added EMF Log Message end------

      --100 informational message suppressed
      IF x_http_response.status_code <> 200
      THEN
         o_transact_id := NULL;
         o_status :=
               'Response> status_code: '
            || x_http_response.status_code
            || '  reason_phrase: '
            || x_http_response.reason_phrase;
      ELSE
         BEGIN
            UTL_HTTP.read_text (x_http_response, x_response);
         EXCEPTION
            WHEN UTL_HTTP.end_of_body
            THEN
               UTL_HTTP.end_response (x_http_response);
         END;

         ------Added EMF Log Message start------
         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                           p_category                 => 'Career Builder Interface',
                           p_error_text               => 'Response completed',
                           p_record_identifier_1      => p_vacancy_name,
                           p_record_identifier_2      => NULL
                          );
         ------Added EMF Log Message end------
         x_resp := XMLTYPE.createxml (x_response);
         ------Added EMF Log Message start------
         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                           p_category                 => 'Career Builder Interface',
                           p_error_text               => 'Extracting the response from xml',
                           p_record_identifier_1      => p_vacancy_name,
                           p_record_identifier_2      => NULL
                          );
         ------Added EMF Log Message end------
         x_resp :=
            x_resp.EXTRACT
                     ('soap:Envelope/soap:Body/child::node()',
                      'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"'
                     );

         IF x_resp.EXISTSNODE
               ('ProcessJobResponse/ProcessJobResult/TransactionDID/text()',
                'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobPost'
               ) = 1
         THEN
            o_transact_id :=
               x_resp.EXTRACT
                  ('ProcessJobResponse/ProcessJobResult/TransactionDID/text()',
                   'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobPost'
                  ).getclobval ();
         END IF;

         IF x_resp.EXISTSNODE
               ('ProcessJobResponse/ProcessJobResult/PostStatus/text()',
                'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobPost'
               ) = 1
         THEN
            o_status :=
               x_resp.EXTRACT
                  ('ProcessJobResponse/ProcessJobResult/PostStatus/text()',
                   'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobPost'
                  ).getclobval ();
         END IF;

         IF o_status <> 'Queued' AND o_transact_id IS NULL
         THEN
            o_status :=
                  o_status
               || x_resp.EXTRACT
                     ('ProcessJobResponse/ProcessJobResult/Errors/DPIError[1]/ErrorCode/text()',
                      'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobPost'
                     ).getclobval ();
            o_status :=
                  o_status
               || x_resp.EXTRACT
                     ('ProcessJobResponse/ProcessJobResult/Errors/DPIError[1]/ErrorText/text()',
                      'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobPost'
                     ).getclobval ();
         END IF;
      END IF;

      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               => 'XML extraction completed',
                        p_record_identifier_1      => p_vacancy_name,
                        p_record_identifier_2      => NULL
                       );

      ------Added EMF Log Message end------
      IF x_http_request.private_hndl IS NOT NULL
      THEN
         UTL_HTTP.end_request (x_http_request);
      END IF;

      IF x_http_response.private_hndl IS NOT NULL
      THEN
         UTL_HTTP.end_response (x_http_response);
      END IF;

      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               => 'Process completed..Connection ended',
                        p_record_identifier_1      => p_vacancy_name,
                        p_record_identifier_2      => NULL
                       );
   ------Added EMF Log Message end------
   EXCEPTION
      WHEN OTHERS
      THEN
         IF x_http_request.private_hndl IS NOT NULL
         THEN
            UTL_HTTP.end_request (x_http_request);
         END IF;

         IF x_http_response.private_hndl IS NOT NULL
         THEN
            UTL_HTTP.end_response (x_http_response);
         END IF;

         o_transact_id := NULL;
         o_status := SQLERRM;
         ---------Added to send email notification
         xx_irc_send_notification
             (p_recruitment_activity_id      => TO_CHAR
                                                    (x_recruitment_activity_id),
              p_status                       => o_status
             );
   ---------Added to send email notification
   END xx_irc_post_job_ws;

-------------------------------------------------------------------------------  /*
   FUNCTION xx_irc_post_jobsto_cb (p_xml_data IN CLOB)
      RETURN VARCHAR2
   IS
      x_modified_xml              CLOB                          := NULL;
      x_recruitment_activity_id   NUMBER                        := NULL;
      x_length1                   NUMBER                        := 0;
      x_length2                   NUMBER                        := 0;
      x_length3                   NUMBER                        := 0;
      x_employee_type             VARCHAR2 (240)                := NULL;
      x_customfield3              VARCHAR2 (240)                := NULL;
      x_conc_request_id           NUMBER                        := NULL;
      x_transact_id               VARCHAR2 (360)                := NULL;
      x_status                    VARCHAR2 (32767)              := NULL;
      x_job_type_code             VARCHAR2 (240)                := NULL;
      x_education                 VARCHAR2 (240)                := NULL;
      x_vacancy_name              per_all_vacancies.NAME%TYPE;
      x_city                      VARCHAR2 (30)                 := NULL;
      x_job_status                VARCHAR2 (30)                 := NULL;
      x_zip                       VARCHAR2 (30)                 := NULL;
      x_err_status                VARCHAR2 (32767)              := NULL;
      ----Added for email notification
      x_ext_career_site           VARCHAR2 (100)                := NULL;
      --Added by Raquib on 11-15-12 to get the site name
      x_recruiting_site_id        NUMBER;
      x_variable_name             VARCHAR2 (360)                := NULL;
      x_variable_value            VARCHAR2 (360)                := NULL;
   BEGIN
      --Set EMF environment
      set_cnv_env;
      --Replace ; with <
      x_modified_xml := REPLACE (p_xml_data, ';', '<');
      x_modified_xml := REPLACE (x_modified_xml, '&', ';');
      x_modified_xml := REPLACE (x_modified_xml, ';gt;', '>');
      x_modified_xml :=
         REPLACE (x_modified_xml,
                  '<?xml version = ''1.0'' encoding = ''UTF-8''?>',
                  ''
                 );
      x_modified_xml :=
         REPLACE (x_modified_xml,
                  '<?xml version = "1.0" encoding="UTF-8" ?>',
                  ''
                 );
      --Get the Recruitment Activity ID
      x_length1 :=
         INSTR (x_modified_xml,
                '<JobPositionPostingId idOwner="careerbuilder.com">'
               );
      --DBMS_OUTPUT.put_line ('x_length1' || x_length1);
      x_length2 := INSTR (x_modified_xml, '</JobPositionPostingId>');
      --DBMS_OUTPUT.put_line ('x_length2' || x_length2);

      --Get the RECRUITMENT_ACTIVITY_ID
      x_recruitment_activity_id :=
         TO_NUMBER (SUBSTR (x_modified_xml,
                            x_length1 + 50,
                            x_length2 - x_length1 - 50
                           )
                   );

      --Translate Education, Job Type Code and EmployeeType from lookups
      --Get Vacancy Name
      BEGIN
         SELECT pav.NAME, pav.status, recruiting_site_id
           INTO x_vacancy_name, x_job_status, x_recruiting_site_id
           FROM per_all_vacancies pav, per_recruitment_activities pra
          WHERE pav.primary_posting_id = pra.posting_content_id
            AND pra.recruitment_activity_id = x_recruitment_activity_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_vacancy_name := NULL;
      END;

      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               => 'Process started..',
                        p_record_identifier_1      => x_vacancy_name
                       );

      ------Added EMF Log Message end------

      --Update the Job Status
      IF x_job_status = 'CLOSED'
      THEN
         x_modified_xml :=
            REPLACE (x_modified_xml,
                     '<JobPositionPosting status="active">',
                     '<JobPositionPosting status="inactive">'
                    );
      END IF;

      --Update the JobID field
      x_modified_xml :=
         REPLACE (x_modified_xml,
                     '<JobPositionPostingId idOwner="careerbuilder.com">'
                  || x_recruitment_activity_id
                  || '</JobPositionPostingId>',
                     '<JobPositionPostingId idOwner="careerbuilder.com">'
                  || x_vacancy_name
                  || '</JobPositionPostingId>'
                 );

      -- Get City
      BEGIN
         SELECT pav.attribute6, hla.postal_code
           INTO x_zip, x_city
           FROM per_all_vacancies pav, hr_locations_all_vl hla
          WHERE hla.location_id = pav.location_id
                AND pav.NAME = x_vacancy_name;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_city := NULL;
            x_zip := NULL;
      END;

      --Update the City field
      IF x_zip IS NOT NULL
      THEN
         x_modified_xml :=
            REPLACE (x_modified_xml,
                     '<City>City</City>',
                     '<PostalCode>' || x_zip || '</PostalCode>'
                    --'<City>' || x_city || '</City>'
                    );
         ------Added EMF Log Message start------
         xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                           p_category                 => 'Career Builder Interface',
                           p_error_text               =>    'New tag added: '
                                                         || '<PostalCode>'
                                                         || x_zip
                                                         || '</PostalCode>',
                           p_record_identifier_1      => x_vacancy_name,
                           p_record_identifier_2      => NULL
                          );
      ------Added EMF Log Message end------
      ELSE
         x_modified_xml :=
            REPLACE (x_modified_xml,
                     '<City>City</City>',
                     '<City>' || x_city || '</City>'
                    );
      END IF;

      --Get Employee Type
      BEGIN
         SELECT flv.lookup_code employee_type
           INTO x_employee_type
           FROM per_all_vacancies pav,
                per_recruitment_activities pra,
                fnd_lookup_values_vl flv
          WHERE pav.primary_posting_id = pra.posting_content_id
            AND flv.lookup_type = 'INTG IRC EMPLOYEE TYPE'
            AND pra.recruitment_activity_id = x_recruitment_activity_id
            AND flv.meaning = pav.attribute10;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_employee_type := NULL;
      END;

      --Update the EmployeeType to XML
      x_modified_xml :=
         REPLACE (x_modified_xml,
                  '<EmployeeType>EmployeeType</EmployeeType>',
                  '<EmployeeType>' || x_employee_type || '</EmployeeType>'
                 );
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               =>    'New tag added: '
                                                      || '<EmployeeType>'
                                                      || x_employee_type
                                                      || '</EmployeeType>',
                        p_record_identifier_1      => x_vacancy_name,
                        p_record_identifier_2      => NULL
                       );

      ------Added EMF Log Message end------

      -- Get Job Type Code and Education
      BEGIN
         SELECT NVL (flvj.description, 'JN010') job_type_code,
                NVL (flvq.lookup_code, 'DRNS') education
           INTO x_job_type_code,
                x_education
           FROM irc_search_criteria vsc,
                hr_lookups hl,
                per_recruitment_activities pra,
                fnd_lookup_values_vl flvj,
                per_all_vacancies pav,
                per_qualification_types_vl quamin,
                fnd_lookup_values_vl flvq
          WHERE pav.vacancy_id = vsc.object_id
            AND vsc.professional_area = hl.lookup_code(+)
            AND hl.lookup_type(+) = 'IRC_PROFESSIONAL_AREA'
            AND pav.primary_posting_id = pra.posting_content_id
            AND pra.recruitment_activity_id = x_recruitment_activity_id
            AND flvj.lookup_type(+) = 'INTG IRC PROFESSIONAL AREA'
            AND flvj.meaning(+) = hl.meaning
            AND quamin.qualification_type_id(+) = vsc.min_qual_level
            AND flvq.lookup_type(+) = 'INTG IRC EDUCATION'
            AND flvq.meaning(+) = quamin.NAME;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_job_type_code := 'JN010';
            x_education := 'DRNS';
      END;

      --Update the JobTypeCode to XML
      x_modified_xml :=
         REPLACE (x_modified_xml,
                  '<JobTypeCode>JobTypeCode</JobTypeCode>',
                  '<JobTypeCode>' || x_job_type_code || '</JobTypeCode>'
                 );
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               =>    'New tag added: '
                                                      || '<JobTypeCode>'
                                                      || x_job_type_code
                                                      || '</JobTypeCode>',
                        p_record_identifier_1      => x_vacancy_name,
                        p_record_identifier_2      => NULL
                       );
      ------Added EMF Log Message end------

      --Update the Education to XML
      x_modified_xml :=
         REPLACE (x_modified_xml,
                  '<Education>Education</Education>',
                  '<Education>' || x_education || '</Education>'
                 );
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               =>    'New tag added: '
                                                      || '<Education>'
                                                      || x_education
                                                      || '</Education>',
                        p_record_identifier_1      => x_vacancy_name,
                        p_record_identifier_2      => NULL
                       );

      ------Added EMF Log Message end------
      BEGIN
         SELECT ipc.attribute1
           INTO x_customfield3
           FROM irc_posting_contents ipc, per_recruitment_activities pra
          WHERE pra.posting_content_id = ipc.posting_content_id
            AND pra.recruitment_activity_id = x_recruitment_activity_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_customfield3 := NULL;
      END;

      --Update the CustomFiled3 to XML
      x_modified_xml :=
         REPLACE (x_modified_xml,
                  '<CustomField3>CustomField3</CustomField3>',
                  '<CustomField3>' || x_customfield3 || '</CustomField3>'
                 );
      ------Added EMF Log Message start------
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => 'Career Builder Interface',
                        p_error_text               =>    'New tag added: '
                                                      || '<CustomField3>'
                                                      || x_customfield3
                                                      || '</CustomField3>',
                        p_record_identifier_1      => x_vacancy_name,
                        p_record_identifier_2      => NULL
                       );
      ------Added EMF Log Message end------

      /*x_modified_xml := REPLACE (x_modified_xml, ';nbsp;', NULL);
      x_modified_xml := REPLACE (x_modified_xml, '<p>', NULL);
      x_modified_xml := REPLACE (x_modified_xml, '</p>', NULL);
      x_modified_xml := REPLACE (x_modified_xml, '<br>', NULL);*/

      --Get the variable name from profile TalentTech Talemetry Session Value
      x_variable_name := fnd_profile.VALUE ('TTC_TALEMETRY_SESSIONVAL');
      --Get the Recruting Site name
      x_variable_value :=
         xx_irc_get_recruitment_site
                                (p_recruitment_site_id      => x_recruiting_site_id);
      --Update the URL field
      x_modified_xml :=
         REPLACE (x_modified_xml,
                  '</URL>',
                     ';'
                  || x_variable_name
                  || '=!'
                  || x_variable_value
                  || '!</URL>'
                 );

      INSERT INTO xxintg.xx_irc_post_job_xml
                  (vacancy_name, xml_data, creation_date
                  )
           VALUES (x_vacancy_name, x_modified_xml, SYSDATE
                  );

      --RETURN length(x_modified_xml);

      --Call WebService to Post the job to Career Builder Site
      xx_irc_post_job_ws (p_xml_data          => x_modified_xml,
                          p_vacancy_name      => x_vacancy_name,
                          o_transact_id       => x_transact_id,
                          o_status            => x_status
                         );

      IF x_transact_id IS NOT NULL
      THEN
         --Submit Concurrent Program
         x_conc_request_id :=
            fnd_request.submit_request
                             (application      => 'XXINTG',
                              program          => 'XXIRCPOSTJOBCB',
                              sub_request      => FALSE,
                              argument1        => TO_CHAR (x_transact_id),
                              argument2        => TO_CHAR
                                                     (x_recruitment_activity_id
                                                     )
                             );
         COMMIT;
         RETURN    'Job is queued, Transaction ID: '
                || x_transact_id
                || ' Concurrent Request: '
                || x_conc_request_id
                || ' submitted to obtain the latest status';
      ELSE
         ---------Added to send email notification
         x_err_status := x_status;
         xx_irc_send_notification
            (p_recruitment_activity_id      => TO_CHAR
                                                    (x_recruitment_activity_id),
             p_status                       => x_err_status
            );
         ---------Added to send email notification
         RETURN 'Error occured:' || x_status;
      END IF;

      ---------Added to send email notification
      x_err_status := SQLERRM;
      xx_irc_send_notification
             (p_recruitment_activity_id      => TO_CHAR
                                                    (x_recruitment_activity_id),
              p_status                       => x_err_status
             );
      ---------Added to send email notification
      RETURN 'Unexpected erroor before Exception' || SQLERRM;
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ---------Added to send email notification
         x_err_status := SQLERRM;
         xx_irc_send_notification
            (p_recruitment_activity_id      => TO_CHAR
                                                    (x_recruitment_activity_id),
             p_status                       => x_err_status
            );
         ---------Added to send email notification
         RETURN 'Unexpected erroor' || SQLERRM;
   END xx_irc_post_jobsto_cb;

-------------------------------------------------------------------------------  /*
   PROCEDURE xx_irc_post_job (
      o_errbuf                    OUT      VARCHAR2,
      o_retcode                   OUT      NUMBER,
      p_transact_id               IN       VARCHAR2,
      p_recruitment_activity_id   IN       VARCHAR2
   )
   IS
      x_http_request                UTL_HTTP.req;
      x_http_response               UTL_HTTP.resp;
      x_buffer_size                 NUMBER (10)     := 512;
      x_string_request              VARCHAR2 (512);
      x_substring_msg               VARCHAR2 (512);
      x_raw_data                    RAW (512);
      x_clob_response               CLOB;
      x_resp                        XMLTYPE;
      x_cb_status_web_service_url   VARCHAR2 (1000) := NULL;
      x_cb_job_search_url           VARCHAR2 (1000) := NULL;
      x_return_status               VARCHAR2 (2000) := NULL;
      x_job_id                      VARCHAR2 (100)  := NULL;
      x_post_status                 VARCHAR2 (30)   := 'Queued';
      x_error_code                  VARCHAR2 (300)  := NULL;
      x_error_msg                   VARCHAR2 (2000) := NULL;
      x_last_timing                 INTEGER         := NULL;
      x_current_timing              INTEGER         := NULL;
      x_wait_time                   INTEGER         := NULL;
      x_email_id                    VARCHAR2 (360)  := NULL;
      x_email_status                NUMBER          := NULL;
      x_email_address               VARCHAR2 (360)  := NULL;
      x_first_name                  VARCHAR2 (360)  := NULL;
      x_vacancy_name                VARCHAR2 (360)  := NULL;
      x_job_title                   VARCHAR2 (1000) := NULL;
   BEGIN
      x_last_timing := DBMS_UTILITY.get_time;

      BEGIN
         SELECT ppf.first_name, ppf.email_address, pav.NAME, pcv.job_title
           INTO x_first_name, x_email_address, x_vacancy_name, x_job_title
           FROM per_all_vacancies pav,
                per_recruitment_activities pra,
                per_people_f ppf,
                irc_posting_contents_vl pcv
          WHERE pav.primary_posting_id = pra.posting_content_id
            AND ppf.person_id = pav.recruiter_id
            AND pcv.posting_content_id = pra.posting_content_id
            AND pra.recruitment_activity_id = p_recruitment_activity_id
            AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (ppf.effective_start_date,
                                                    SYSDATE
                                                   )
                                              )
                                    AND TRUNC (NVL (ppf.effective_end_date,
                                                    SYSDATE
                                                   )
                                              );
      --Added effectivity date validation
      EXCEPTION
         WHEN OTHERS
         THEN
            x_email_address := NULL;
            x_first_name := NULL;
            x_vacancy_name := NULL;
            x_job_title := NULL;
            fnd_file.put_line (fnd_file.LOG,
                                  'Recruiter Email Id and others not defined'
                               || SQLERRM
                              );
      END;

      SELECT   xx_emf_pkg.get_paramater_value
                                             ('XX_H2R_CAREER_BUILDER_INT_006',
                                              'MAX_WAIT_TIME_IN_MINS'
                                             )
             * 60
        INTO x_wait_time
        FROM DUAL;

      --Get the Responses
      x_string_request :=
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:real="http://dpi.careerbuilder.com/WebServices/RealTimeJobStatus">
   <soapenv:Header/>
   <soapenv:Body>
      <real:GetJobPostStatus>
         <real:sTGDID>'
         || p_transact_id
         || '</real:sTGDID>
      </real:GetJobPostStatus>
   </soapenv:Body>
</soapenv:Envelope>';

      SELECT    'http://'
             || xx_emf_pkg.get_paramater_value
                                             ('XX_H2R_CAREER_BUILDER_INT_006',
                                              'CB_JOB_STATUS_WEB_SERVICE'
                                             )
        INTO x_cb_status_web_service_url
        FROM DUAL;

      WHILE x_job_id IS NULL AND x_post_status = 'Queued'
      LOOP
         --Calling Web Service to get the status
         x_error_code := NULL;
         x_error_msg := NULL;
         x_clob_response := NULL;
         UTL_HTTP.set_transfer_timeout (60);
         x_http_request :=
            UTL_HTTP.begin_request (url               => x_cb_status_web_service_url,
                                    method            => 'POST',
                                    http_version      => 'HTTP/1.1'
                                   );
         UTL_HTTP.set_header (x_http_request,
                              'Content-Type',
                              'text/xml;charset=UTF-8'
                             );
         UTL_HTTP.set_header
            (x_http_request,
             'SOAPAction',
             '"http://dpi.careerbuilder.com/WebServices/RealTimeJobStatus/GetJobPostStatus"'
            );
         UTL_HTTP.set_header (x_http_request,
                              'Content-Length',
                              LENGTH (x_string_request)
                             );

         --Get the status while posting the data
         BEGIN

            <<request_loop>>
            FOR i IN 0 .. CEIL (LENGTH (x_string_request) / x_buffer_size)
                          - 1
            LOOP
               x_substring_msg :=
                  SUBSTR (x_string_request,
                          i * x_buffer_size + 1,
                          x_buffer_size
                         );

               BEGIN
                  x_raw_data := UTL_RAW.cast_to_raw (x_substring_msg);
                  UTL_HTTP.write_raw (r         => x_http_request,
                                      DATA      => x_raw_data);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     EXIT request_loop;
               END;
            END LOOP request_loop;

            x_http_response := UTL_HTTP.get_response (x_http_request);
            fnd_file.put_line (fnd_file.LOG,
                                  'Response> status_code: "'
                               || x_http_response.status_code
                               || '"'
                              );
            fnd_file.put_line (fnd_file.LOG,
                                  'Response> reason_phrase: "'
                               || x_http_response.reason_phrase
                               || '"'
                              );
            fnd_file.put_line (fnd_file.LOG,
                                  'Response> http_version: "'
                               || x_http_response.http_version
                               || '"'
                              );
         EXCEPTION
            WHEN OTHERS
            THEN
               x_return_status :=
                     'First Call: Status code: '
                  || x_http_response.status_code
                  || 'reason_phrase:  '
                  || x_http_response.reason_phrase;
         END;

         --
         BEGIN

            <<response_loop>>
            LOOP
               UTL_HTTP.read_raw (x_http_response, x_raw_data, x_buffer_size);
               x_clob_response :=
                     x_clob_response || UTL_RAW.cast_to_varchar2 (x_raw_data);
            END LOOP response_loop;
         EXCEPTION
            WHEN UTL_HTTP.end_of_body
            THEN
               UTL_HTTP.end_response (x_http_response);
         END;

         x_resp := XMLTYPE.createxml (x_clob_response);
         fnd_file.put_line (fnd_file.LOG, x_resp.getclobval ());
         x_resp :=
            x_resp.EXTRACT
                     ('soap:Envelope/soap:Body/child::node()',
                      'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"'
                     );

         IF x_resp.EXISTSNODE
               ('GetJobPostStatusResponse/GetJobPostStatusResult/JobDID/text()',
                'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobStatus"'
               ) = 1
         THEN
            x_job_id :=
               x_resp.EXTRACT
                  ('GetJobPostStatusResponse/GetJobPostStatusResult/JobDID/text()',
                   'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobStatus"'
                  ).getclobval ();
            fnd_file.put_line (fnd_file.LOG, 'Job DID:' || x_job_id);
         END IF;

         x_post_status :=
            x_resp.EXTRACT
               ('GetJobPostStatusResponse/GetJobPostStatusResult/PostStatus/text()',
                'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobStatus"'
               ).getclobval ();
         fnd_file.put_line (fnd_file.LOG, 'Job Post Status' || x_post_status);
         x_error_code :=
            x_resp.EXTRACT
               ('GetJobPostStatusResponse/GetJobPostStatusResult/Errors/DPIError[1]/ErrorCode/text()',
                'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobStatus'
               ).getclobval ();
         fnd_file.put_line (fnd_file.LOG, 'x_error_code: ' || x_error_code);

         IF x_error_code <> 0
         THEN
            x_error_msg :=
               x_resp.EXTRACT
                  ('GetJobPostStatusResponse/GetJobPostStatusResult/Errors/DPIError[1]/ErrorText/text()',
                   'xmlns="http://dpi.careerbuilder.com/WebServices/RealTimeJobStatus'
                  ).getclobval ();
            fnd_file.put_line (fnd_file.LOG, 'x_error_msg: ' || x_error_msg);
         END IF;

         IF x_http_request.private_hndl IS NOT NULL
         THEN
            UTL_HTTP.end_request (x_http_request);
         END IF;

         IF x_http_response.private_hndl IS NOT NULL
         THEN
            UTL_HTTP.end_response (x_http_response);
         END IF;

         x_current_timing := DBMS_UTILITY.get_time;

         IF (x_current_timing - x_last_timing) / 100 > x_wait_time
         THEN
            --Send email notification and exit from the loop
            BEGIN
               IF x_email_address IS NULL
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'Email ID not defined');
               ELSE
                  x_email_status :=
                     irc_notification_helper_pkg.send_notification
                        (p_email_address      => x_email_address,
                         p_subject            =>    'ACTION REQUIRED: Posting Error '
                                                 || x_vacancy_name
                                                 || ' '
                                                 || x_job_title,
                         p_text_body          =>    ' Hi '
                                                 || x_first_name
                                                 || ' ,'
                                                 || x_vacancy_name
                                                 || ' posted to the CareerBuilder errored with following Error message..Time OUT error.
                                          Please repost the vacancy'
                        );
                  fnd_file.put_line (fnd_file.LOG,
                                     'Email Notfication ID:' || x_email_status
                                    );
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line (fnd_file.LOG,
                                        'Error occured while sending email'
                                     || SQLERRM
                                    );
            END;

            EXIT;
            fnd_file.put_line (fnd_file.LOG,
                               'Exiting from the loop since timer is up'
                              );
         END IF;

         IF x_job_id IS NULL
         THEN
            --Wait for 30 seconds
            fnd_file.put_line
               (fnd_file.LOG,
                'Waiting for 30 seconds before calling the web service again'
               );
            DBMS_LOCK.sleep (30);
         END IF;
      END LOOP;

      --
      IF x_job_id IS NOT NULL
      THEN
         SELECT    'http://'
                || xx_emf_pkg.get_paramater_value
                                             ('XX_H2R_CAREER_BUILDER_INT_006',
                                              'CB_JOB_SERACH_URL'
                                             )
           INTO x_cb_job_search_url
           FROM DUAL;

         x_return_status :=
               'Job posted successfully, URL: '
            || x_cb_job_search_url
            || '='
            || x_job_id;
         x_email_status :=
            irc_notification_helper_pkg.send_notification
                   (p_email_address      => x_email_address,
                    p_subject            =>    'JOB Posted Successfully'
                                            || x_vacancy_name
                                            || ' '
                                            || x_job_title,
                    p_text_body          =>    ' Hi '
                                            || x_first_name
                                            || ' ,'
                                            || x_vacancy_name
                                            || ' posted to the CareerBuilder Successfully'
                   );
         fnd_file.put_line (fnd_file.LOG,
                            'Email Notfication ID:' || x_email_status
                           );
      ELSE
         --Send Email if there is any error
         x_email_status :=
            irc_notification_helper_pkg.send_notification
               (p_email_address      => x_email_address,
                p_subject            =>    'ACTION REQUIRED: Posting Error '
                                        || x_vacancy_name
                                        || ' '
                                        || x_job_title,
                p_text_body          =>    ' Hi '
                                        || x_first_name
                                        || ' ,'
                                        || x_vacancy_name
                                        || ' posted to the CareerBuilder errored with following Error message '
                                        || x_error_msg
                                        || ' Please resolve the error and repost the vacancy'
               );
         fnd_file.put_line (fnd_file.LOG,
                            'Email Notfication ID:' || x_email_status
                           );
         x_return_status :=
               'Job post was not successfull, Error Code: '
            || x_error_code
            || ' Error Message: '
            || x_error_msg;
      END IF;

      UPDATE per_recruitment_activities
         SET recruiting_site_response = x_return_status
       WHERE recruitment_activity_id = p_recruitment_activity_id;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := SQLERRM;

         UPDATE per_recruitment_activities
            SET recruiting_site_response = x_return_status
          WHERE recruitment_activity_id = p_recruitment_activity_id;
   END xx_irc_post_job;
END xx_irc_cb_job_posting_pkg;
/
