DROP VIEW APPS.XX_FND_EMP_WITH_NO_FND_ACCT_V;

/* Formatted on 6/6/2016 4:58:39 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_FND_EMP_WITH_NO_FND_ACCT_V
(
   FULL_NAME,
   EMAIL_IN_HR,
   FND_ACCOUNT,
   EMAIL_ADDRESS,
   EMP_TYPE
)
AS
   SELECT ppf.full_name,
          ppf.email_address email_in_hr,
          c.user_name fnd_account,
          c.email_address          --,b.SYSTEM_PERSON_TYPE,b.USER_PERSON_TYPE,
                         ,
          hr_person_type_usage_info.get_user_person_type (
             ppf.effective_start_date,
             ppf.person_id)
             emp_type
     FROM per_people_x ppf,
          per_person_types b,
          fnd_user c,
          umx_role_assignments_v d
    WHERE     ppf.person_type_id = b.person_type_id
          AND b.SYSTEM_PERSON_TYPE IN ('EMP', 'EMP_APL')
          AND ppf.person_id = c.employee_id(+)
          AND c.user_name = d.user_name(+)
          AND UPPER (NVL (ppf.email_address, 'NO_HR_EMAIL')) <>
                 UPPER (NVL (c.email_address, 'NO_FND_EMAIL'))
          AND c.user_name IS NULL;
