DROP VIEW APPS.XX_EMP_FND_ACCT_DISP_V;

/* Formatted on 6/6/2016 4:58:41 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_EMP_FND_ACCT_DISP_V
(
   STATUS,
   FULL_NAME,
   EFFECTIVE_START_DATE,
   START_DATE,
   EMAIL_IN_HR,
   FND_ACCOUNT,
   EMAIL_ADDRESS,
   EMP_TYPE,
   WORK_LOC_COUNTRY
)
AS
   SELECT 'INVALID_FND_ACCOUNT' status,
          ppf.full_name,
          ppf.effective_start_date,
          ppf.start_date,
          ppf.email_address email_in_hr,
          c.user_name fnd_account,
          c.email_address          --,b.SYSTEM_PERSON_TYPE,b.USER_PERSON_TYPE,
                         ,
          hr_person_type_usage_info.get_user_person_type (
             ppf.effective_start_date,
             ppf.person_id)
             emp_type,
          (SELECT DISTINCT country
             FROM hr_locations loc, per_assignments_x asg
            WHERE     asg.person_id = ppf.person_id
                  AND asg.location_id = loc.location_id)
             work_loc_country
     FROM per_people_x ppf, per_person_types b, fnd_user c --, umx_role_assignments_v d
    WHERE     ppf.person_type_id = b.person_type_id
          AND b.system_person_type IN ('EMP', 'EMP_APL')
          AND ppf.person_id = c.employee_id(+)
          AND c.user_name LIKE '%@%'
   UNION ALL
   SELECT 'NO_FND_ACCOUNT',
          ppf.full_name,
          ppf.effective_start_date,
          ppf.start_date,
          ppf.email_address email_in_hr,
          c.user_name fnd_account,
          c.email_address          --,b.SYSTEM_PERSON_TYPE,b.USER_PERSON_TYPE,
                         ,
          hr_person_type_usage_info.get_user_person_type (
             ppf.effective_start_date,
             ppf.person_id)
             emp_type,
          (SELECT DISTINCT country
             FROM hr_locations loc, per_assignments_x asg
            WHERE     asg.person_id = ppf.person_id
                  AND asg.location_id = loc.location_id)
             work_loc_country
     FROM per_people_x ppf, per_person_types b, fnd_user c --, umx_role_assignments_v d
    WHERE     ppf.person_type_id = b.person_type_id
          AND b.system_person_type IN ('EMP', 'EMP_APL')
          AND ppf.person_id = c.employee_id(+)
          AND c.user_name IS NULL
   UNION ALL
   SELECT 'INVALID_EMAIL_USERNAME',
          ppf.full_name,
          ppf.effective_start_date,
          ppf.start_date,
          ppf.email_address email_in_hr,
          c.user_name fnd_account,
          c.email_address,
          hr_person_type_usage_info.get_user_person_type (
             ppf.effective_start_date,
             ppf.person_id)
             emp_type,
          (SELECT DISTINCT country
             FROM hr_locations loc, per_assignments_x asg
            WHERE     asg.person_id = ppf.person_id
                  AND asg.location_id = loc.location_id)
             work_loc_country
     FROM per_people_x ppf, per_person_types b, fnd_user c --, umx_role_assignments_v d
    WHERE     ppf.person_type_id = b.person_type_id
          AND b.system_person_type IN ('EMP', 'EMP_APL')
          AND ppf.person_id = c.employee_id(+)
          AND UPPER (NVL (ppf.email_address, 'NO_HR_EMAIL')) <>
                 UPPER (NVL (c.email_address, 'NO_FND_EMAIL'))
   --and c.user_name IS NULL
   UNION ALL
   SELECT 'NO_BIRTH_RIGHT_ACCESS' status,
          ppf.full_name,
          ppf.effective_start_date,
          ppf.start_date,
          ppf.email_address email_in_hr,
          c.user_name fnd_account,
          c.email_address,
          hr_person_type_usage_info.get_user_person_type (
             ppf.effective_start_date,
             ppf.person_id)
             emp_type,
          (SELECT country
             FROM hr_locations loc, per_assignments_x asg
            WHERE     asg.person_id = ppf.person_id
                  AND asg.location_id = loc.location_id)
             work_loc_country
     FROM per_people_x ppf, per_person_types b, fnd_user c
    WHERE     NOT EXISTS
                 (SELECT DISTINCT 1
                    FROM umx_role_assignments_v d
                   WHERE     c.user_name = d.user_name
                         AND (   d.role_name = 'UMX|INTG_EMPSS_USHR_R'
                              OR d.role_name = 'UMX|INTG_EMPSS_INTL_R'))
          AND ppf.person_type_id = b.person_type_id
          AND b.system_person_type IN ('EMP', 'EMP_APL')
          AND ppf.person_id = c.employee_id
          AND c.user_name NOT LIKE '%@%';


GRANT SELECT ON APPS.XX_EMP_FND_ACCT_DISP_V TO XXAPPSREAD;
