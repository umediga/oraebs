DROP VIEW APPS.XX_HR_TODAYS_NEW_HIRE_V;

/* Formatted on 6/6/2016 4:58:30 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_TODAYS_NEW_HIRE_V
(
   EMPLOYEE_NUMBER,
   FIRST_NAME,
   LAST_NAME,
   DATE_START,
   USER_PERSON_TYPE
)
AS
   SELECT employee_number,
          first_name,
          last_name,
          date_start,
          user_person_type
     FROM apps.per_all_people_f papf,
          apps.per_periods_of_service ppos,
          apps.per_person_types ppt,
          apps.per_person_type_usages_f pptuf
    WHERE     papf.person_id = ppos.person_id
          AND ppos.period_of_service_id =
                 (SELECT MAX (period_of_service_id)
                    FROM per_periods_of_service
                   WHERE     date_start <= TRUNC (SYSDATE)
                         AND person_id = papf.person_id)
          AND ppt.person_type_id = pptuf.person_type_id
          AND pptuf.person_id = papf.person_id
          AND date_start >= TRUNC (SYSDATE)   --to_date(SYSDATE,'DD-MON-YYYY')
          AND TRUNC (date_start) BETWEEN papf.effective_start_date
                                     AND papf.effective_end_date
          AND TRUNC (date_start) BETWEEN pptuf.effective_start_date
                                     AND pptuf.effective_end_date
          AND ppt.system_person_type LIKE 'EMP'
   UNION
   SELECT npw_number,
          first_name,
          last_name,
          date_start,
          user_person_type
     FROM apps.per_all_people_f papf,
          apps.per_periods_of_placement ppos,
          apps.per_person_types ppt,
          apps.per_person_type_usages_f pptuf
    WHERE     papf.person_id = ppos.person_id
          AND ppos.period_of_placement_id =
                 (SELECT MAX (period_of_placement_id)
                    FROM per_periods_of_placement
                   WHERE     date_start <= TRUNC (SYSDATE)
                         AND person_id = papf.person_id)
          AND ppt.person_type_id = pptuf.person_type_id
          AND pptuf.person_id = papf.person_id
          AND date_start >= TRUNC (SYSDATE)   --to_date(SYSDATE,'DD-MON-YYYY')
          AND TRUNC (date_start) BETWEEN papf.effective_start_date
                                     AND papf.effective_end_date
          AND TRUNC (date_start) BETWEEN pptuf.effective_start_date
                                     AND pptuf.effective_end_date;
