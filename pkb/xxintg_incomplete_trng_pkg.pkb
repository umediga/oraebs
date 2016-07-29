DROP PACKAGE BODY APPS.XXINTG_INCOMPLETE_TRNG_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_INCOMPLETE_TRNG_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Shekhar Nikam
 Creation Date : 7-MAR-2014
 File Name     : xxintg_incomplete_trng_pkg
 Description   : This script creates the body of the package
                 xxintg_incomplete_trng_pkg
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 07-Mar-2014 Shekhar Nikam             Initial Version
 02-JUL-2014 Shekhar Nikam             Modified for Defect#6730
*/
----------------------------------------------------------------------
   PROCEDURE main (
      p_errbuf        OUT   VARCHAR2,
      p_retcode       OUT   VARCHAR2,
      p_category_id         NUMBER,
      p_course_id           NUMBER,
      p_event_id            NUMBER,
      p_lang                VARCHAR2
   )
   AS
      CURSOR csr_events
      IS
         SELECT   oet.event_id
             FROM ota_events_tl oet,
                  ota_events oe,
                  ota_category_usages_tl ocut,
                  ota_act_cat_inclusions oaci,
                  ota_activity_versions_tl oavt
            WHERE ocut.category_usage_id = oaci.category_usage_id
              AND oaci.activity_version_id = oavt.activity_version_id
              AND oet.event_id = oe.event_id
              AND oe.activity_version_id = oavt.activity_version_id
              AND oet.LANGUAGE = p_lang                               --= 'US'
              AND ocut.LANGUAGE = p_lang                              --= 'US'
              AND oavt.LANGUAGE = p_lang                              --= 'US'
              AND NVL (oe.course_end_date, TRUNC (SYSDATE) + 1) > =
                                                               TRUNC (SYSDATE)
              AND ocut.category_usage_id IN (
                     SELECT     category_usage_id
                           FROM ota_category_usages
                     START WITH category_usage_id =
                                        NVL (p_category_id, category_usage_id)
                     CONNECT BY parent_cat_usage_id = PRIOR category_usage_id)
              AND oavt.activity_version_id =
                                   NVL (p_course_id, oavt.activity_version_id)
              AND oet.event_id = NVL (p_event_id, oet.event_id)
         ORDER BY event_id;

      CURSOR csr_training_details (c_event_id NUMBER)
      IS
         SELECT   oavt.version_name course_name, oft.NAME offering_name,
                  ocuv.CATEGORY delivery_mode
--replace(oet.title,' ','') class_name
                  , oet.title class_name, odbv.date_booking_placed,
                --  odbv.delegate_full_name, odbv.delegate_employee_number,
                  papf.full_name, papf.employee_number, -- Added Jun 2014
                  odbv.event_id, odbv.delegate_person_id
/*,(select  full_name
  from per_all_people_f papf
  ,per_all_assignments_f paaf
  where papf.person_id=paaf.person_id
  and paaf.assignment_type in ('E','C')
  and papf.person_id = (select distinct supervisor_id
                        from per_all_assignments_f paaf1
                        where paaf1.person_id=odbv.delegate_person_id
                        and paaf1.assignment_type in ('E','C')
                        and trunc(sysdate) between paaf1.effective_start_date and paaf1.effective_end_date
                        )
  and trunc(sysdate) between papf.effective_start_date and papf.effective_end_date
  and trunc(sysdate) between paaf.effective_start_date and paaf.effective_end_date
  ) Supervisor_Name*/
                  ,
                  odbv.booking_status_meaning
             FROM ota_delegate_bookings_v odbv,
                  per_all_people_f papf,
                  ota_offerings_tl oft,
                  ota_offerings ofs,
                  ota_category_usages_vl ocuv,
                  ota_category_usages_tl ocut,
                  ota_act_cat_inclusions oaci,
                  ota_activity_versions_tl oavt,
                  ota_events_tl oet,
                  per_person_types ppt,
                  per_person_type_usages_f pptuf
            WHERE odbv.parent_offering_id = oft.offering_id
              AND odbv.delegate_person_id=papf.person_id
              AND oft.offering_id = ofs.offering_id
              AND oavt.activity_version_id = odbv.activity_version_id
              AND oet.event_id = odbv.event_id
              AND ocuv.category_usage_id = ofs.delivery_mode_id
              AND ppt.person_type_id = pptuf.person_type_id
              AND pptuf.person_id = odbv.delegate_person_id
              AND ocut.category_usage_id = oaci.category_usage_id
              AND odbv.activity_version_id = oaci.activity_version_id
              AND ocut.category_usage_id IN (
                     SELECT     category_usage_id
                           FROM ota_category_usages
                     START WITH category_usage_id =
                                        NVL (p_category_id, category_usage_id)
                     CONNECT BY parent_cat_usage_id = PRIOR category_usage_id)
              AND ppt.system_person_type IN ('EMP', 'CWK')
              AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                      AND pptuf.effective_end_date
              AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                      AND papf.effective_end_date
              AND ocut.LANGUAGE = p_lang                     --= 'US'--:p_lang
              AND oft.LANGUAGE = p_lang                      --= 'US'--:p_lang
              AND oavt.LANGUAGE = p_lang                     --='US'-- :p_lang
              AND oet.LANGUAGE = p_lang                      --='US' --:p_lang
--and oft.offering_id = nvl(:p_offering_id,oft.offering_id)
              AND oet.event_id = c_event_id     --nvl(p_event_id,oet.event_id)
              AND oavt.activity_version_id =
                                   NVL (p_course_id, oavt.activity_version_id)
              AND odbv.booking_status_meaning <> 'Completed'
         ORDER BY event_id;

      CURSOR csr_sub_total (x_event_id NUMBER)
      IS
         SELECT (SELECT DISTINCT (COUNT (booking_status_meaning)
                                 )
                            FROM ota_delegate_bookings_v a,
                                 per_all_assignments_f b,
                                 per_person_types ppt,
                                 per_person_type_usages_f pptuf
                           WHERE a.delegate_person_id = b.person_id
                             AND a.delegate_assignment_id = b.assignment_id
                             AND pptuf.person_id = a.delegate_person_id
                             AND ppt.person_type_id = pptuf.person_type_id
                             AND ppt.system_person_type IN ('EMP', 'CWK')
                             AND b.assignment_type IN ('E', 'C')
                             AND event_id = x_event_id
                             AND TRUNC (SYSDATE) BETWEEN b.effective_start_date
                                                     AND b.effective_end_date
                             AND TRUNC (SYSDATE)
                                    BETWEEN pptuf.effective_start_date
                                        AND pptuf.effective_end_date)
                                                            total_enrollments,
                (SELECT DISTINCT (COUNT (booking_status_meaning)
                                 )
                            FROM ota_delegate_bookings_v a,
                                 per_all_assignments_f b,
                                 per_person_types ppt,
                                 per_person_type_usages_f pptuf
                           WHERE a.delegate_person_id = b.person_id
                             AND a.delegate_assignment_id = b.assignment_id
                             AND pptuf.person_id = a.delegate_person_id
                             AND ppt.person_type_id = pptuf.person_type_id
                             AND ppt.system_person_type IN ('EMP', 'CWK')
                             AND b.assignment_type IN ('E', 'C')
                             AND event_id = x_event_id
                             AND TRUNC (SYSDATE) BETWEEN b.effective_start_date
                                                     AND b.effective_end_date
                             AND TRUNC (SYSDATE)
                                    BETWEEN pptuf.effective_start_date
                                        AND pptuf.effective_end_date
                             AND booking_status_meaning <> 'Completed')
                                                             total_incomplete,
                (SELECT DISTINCT event_title
                            FROM ota_delegate_bookings_v
                           WHERE event_id = x_event_id) event_name
           FROM DUAL;

      l_supervisor_id            NUMBER;
      l_sup_name                 VARCHAR2 (100);
      l_percent_incomplete       NUMBER;
      l_master_event_id          NUMBER;
      l_incomplete_enrollments   NUMBER;
      l_total_enrollments        NUMBER;
      l_events                   VARCHAR2 (100);
      l_ultimate_enrollments     NUMBER         := 0;
      l_ult_incmp_enrollments    NUMBER         := 0;
      l_ult_per_incomplete       NUMBER;
      l_class_name               VARCHAR2 (250);
      l_course_name              VARCHAR2 (250);
      l_category_name            VARCHAR2 (250);
      l_delivery_mode            VARCHAR2 (250) := NULL;
   BEGIN
      BEGIN
         SELECT CATEGORY
           INTO l_category_name
           FROM ota_category_usages
          WHERE category_usage_id = p_category_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_category_name := 'ALL';
            fnd_file.put_line (fnd_file.LOG,
                               'Error in getting Category Name');
      END;

      BEGIN
         SELECT version_name
           INTO l_course_name
           FROM ota_activity_versions
          WHERE activity_version_id = p_course_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_course_name := 'ALL';
            fnd_file.put_line (fnd_file.LOG, 'Error in getting Course Name');
      END;

      BEGIN
         SELECT title
           INTO l_class_name
           FROM ota_events
          WHERE event_id = p_event_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_class_name := 'ALL';
            fnd_file.put_line (fnd_file.LOG, 'Error in getting Class Name');
      END;

      fnd_file.put_line (fnd_file.output,
                         '<?xml version="1.0" encoding="windows-1252"?>'
                        );
      fnd_file.put_line (fnd_file.output, '<PERDUMMY2>');
      fnd_file.put_line (fnd_file.output,
                            '<HED_CATEGORY_NAME>'
                         || REPLACE (l_category_name, '&', '&' || 'amp;')
                         || '</HED_CATEGORY_NAME>'
                        );
      fnd_file.put_line (fnd_file.output,
                            '<HED_COURSE_NAME>'
                         || REPLACE (l_course_name, '&', '&' || 'amp;')
                         || '</HED_COURSE_NAME>'
                        );
      fnd_file.put_line (fnd_file.output,
                            '<HED_DELIVERY_MODE>'
                         || REPLACE (l_delivery_mode, '&', '&' || 'amp;')
                         || '</HED_DELIVERY_MODE>'
                        );
      fnd_file.put_line (fnd_file.output,
                            '<HED_CLASS_NAME>'
                         || REPLACE (l_class_name, '&', '&' || 'amp;')
                         || '</HED_CLASS_NAME>'
                        );

      FOR rec_events IN csr_events
      LOOP
         l_master_event_id := NULL;
         l_master_event_id := rec_events.event_id;
         fnd_file.put_line (fnd_file.output, '<PERDUMMY3>');

         FOR rec_training_details IN csr_training_details (l_master_event_id)
         LOOP
            l_supervisor_id := NULL;
            l_sup_name := NULL;

            BEGIN
               SELECT supervisor_id
                 INTO l_supervisor_id
                 FROM per_all_assignments_f paaf
                WHERE person_id = rec_training_details.delegate_person_id
                  AND paaf.assignment_type IN ('E', 'C')
                  AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                          AND paaf.effective_end_date;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_supervisor_id := NULL;
                  fnd_file.put_line (fnd_file.LOG,
                                     'Error in getting Supervisor ID'
                                    );
            END;

            BEGIN
               SELECT full_name
                 INTO l_sup_name
                 FROM per_all_people_f
                WHERE person_id = l_supervisor_id
                  AND TRUNC (SYSDATE) BETWEEN effective_start_date
                                          AND effective_end_date;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_sup_name := NULL;
                  fnd_file.put_line (fnd_file.LOG,
                                     'Error in getting Supervisor Full Name'
                                    );
            END;

            fnd_file.put_line (fnd_file.output, '<INCOMPLETE_TRNG_REPORT>');
            fnd_file.put_line (fnd_file.output,
                                  '<COURSE_NAME>'
                               || REPLACE (rec_training_details.course_name,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</COURSE_NAME>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<OFFERING_NAME>'
                               || REPLACE (rec_training_details.offering_name,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</OFFERING_NAME>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<DELIVERY_MODE>'
                               || REPLACE (rec_training_details.delivery_mode,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</DELIVERY_MODE>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<CLASS_NAME>'
                               || REPLACE (rec_training_details.class_name,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</CLASS_NAME>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<ENROLLMENT_DATE>'
                               || rec_training_details.date_booking_placed
                               || '</ENROLLMENT_DATE>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<PERSON_NAME>'
                               --|| rec_training_details.delegate_full_name
                               || rec_training_details.full_name
                               || '</PERSON_NAME>'
                              );
            fnd_file.put_line
                             (fnd_file.output,
                                 '<EMPLOYEE_NUMBER>'
                              --|| rec_training_details.delegate_employee_number
                              || rec_training_details.employee_number
                              || '</EMPLOYEE_NUMBER>'
                             );
            fnd_file.put_line (fnd_file.output,
                                  '<SUPERVISOR_NAME>'
                               || l_sup_name
                               || '</SUPERVISOR_NAME>'
                              );
            fnd_file.put_line (fnd_file.output, '</INCOMPLETE_TRNG_REPORT>');
         END LOOP;

         --FOR rec_sub_total IN csr_sub_total (l_master_event_id)
         OPEN csr_sub_total (l_master_event_id);

         -- LOOP
         FETCH csr_sub_total
          INTO l_total_enrollments, l_incomplete_enrollments, l_events;

         l_percent_incomplete := NULL;

         IF l_total_enrollments <> 0 OR l_incomplete_enrollments <> 0
         THEN
            l_percent_incomplete :=
               TO_NUMBER (  (l_incomplete_enrollments / l_total_enrollments)
                          * 100
                         );
         ELSE
            l_percent_incomplete := 0;
         END IF;

         IF l_incomplete_enrollments <> 0
         THEN
            fnd_file.put_line (fnd_file.output, '<SUBTOTAL_TRNG_REPORT>');
            fnd_file.put_line (fnd_file.output,
                                  '<TOTAL_ENROLLMENTS>'
                               || l_total_enrollments
                               || '</TOTAL_ENROLLMENTS>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<TOTAL_INCOMPLETE>'
                               || l_incomplete_enrollments
                               || '</TOTAL_INCOMPLETE>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<PERCENT_INCOMPLETE>'
                               || ROUND (l_percent_incomplete, 2)
                               || '</PERCENT_INCOMPLETE>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<EVENT_NAME>'
                               || REPLACE (l_events, '&', '&' || 'amp;')
                               || '</EVENT_NAME>'
                              );
            fnd_file.put_line (fnd_file.output, '</SUBTOTAL_TRNG_REPORT>');
            l_ultimate_enrollments :=
                                  l_ultimate_enrollments + l_total_enrollments;
            l_ult_incmp_enrollments :=
                            l_ult_incmp_enrollments + l_incomplete_enrollments;
         END IF;

         -- END LOOP;
         CLOSE csr_sub_total;

         fnd_file.put_line (fnd_file.output, '</PERDUMMY3>');
      END LOOP;

      IF l_ultimate_enrollments <> 0
      THEN
         l_ult_per_incomplete :=
            TO_NUMBER (  (l_ult_incmp_enrollments / l_ultimate_enrollments)
                       * 100
                      );
      END IF;

      fnd_file.put_line (fnd_file.output,
                            '<ULT_TTL_ENROLLMENTS>'
                         || l_ultimate_enrollments
                         || '</ULT_TTL_ENROLLMENTS>'
                        );
      fnd_file.put_line (fnd_file.output,
                            '<ULT_INC_ENROLLMENTS>'
                         || l_ult_incmp_enrollments
                         || '</ULT_INC_ENROLLMENTS>'
                        );
      fnd_file.put_line (fnd_file.output,
                            '<ULT_INC_PERCENT>'
                         || ROUND (l_ult_per_incomplete, 2)
                         || '</ULT_INC_PERCENT>'
                        );
      fnd_file.put_line (fnd_file.output, '</PERDUMMY2>');
   END main;
END xxintg_incomplete_trng_pkg;
/
