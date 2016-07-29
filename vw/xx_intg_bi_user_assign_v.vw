DROP VIEW APPS.XX_INTG_BI_USER_ASSIGN_V;

/* Formatted on 6/6/2016 4:58:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_INTG_BI_USER_ASSIGN_V
(
   USER_NAME,
   EMP_FIRST_NAME,
   EMP_LAST_NAME,
   EMP_FULL_NAME,
   EMPLOYEE_NUMBER,
   COMPANY,
   DEPARTMENT,
   DEPARTMENT_DESCRIPTION,
   ACCOUNT,
   SUB_ACCOUNT,
   PRODUCT,
   REGION,
   INTERCOMPANY,
   FUTURE,
   HR_ORGANIZATION,
   LOCATION_CODE,
   SUPER_FIRST_NAME,
   SUPER_LAST_NAME,
   SUPER_FULL_NAME,
   ROLE,
   ROLE_KEY,
   ROLE_START_DATE,
   ROLE_END_DATE,
   FND_USER_START_DATE,
   FND_USER_END_DATE,
   EMAIL_FROM_FND,
   EMAIL_FROM_HR
)
AS
     SELECT "USER_NAME",
            "EMP_FIRST_NAME",
            "EMP_LAST_NAME",
            "EMP_FULL_NAME",
            "EMPLOYEE_NUMBER",
            "COMPANY",
            "DEPARTMENT",
            "DEPARTMENT_DESCRIPTION",
            "ACCOUNT",
            "SUB_ACCOUNT",
            "PRODUCT",
            "REGION",
            "INTERCOMPANY",
            "FUTURE",
            "HR_ORGANIZATION",
            "LOCATION_CODE",
            "SUPER_FIRST_NAME",
            "SUPER_LAST_NAME",
            "SUPER_FULL_NAME",
            "ROLE",
            role_key,
            "ACTIVE_FROM",
            "ACTIVE_TO",
            start_date,
            end_date,
            email_from_fnd,
            email_from_hr
       FROM (SELECT fu.user_name,
                    a.first_name emp_first_name,
                    a.last_name emp_last_name,
                    a.full_name emp_full_name,
                    a.employee_number,
                    glcc.segment1 company,
                    glcc.segment2 department,
                    (SELECT description
                       FROM apps.fnd_flex_values_vl
                      WHERE     flex_value_set_id = 1015048
                            AND flex_value_meaning = glcc.segment2    --'2003'
                                                                  )
                       department_description,
                    glcc.segment3 ACCOUNT,
                    glcc.segment4 sub_account,
                    glcc.segment5 product,
                    glcc.segment6 region,
                    glcc.segment7 intercompany,
                    glcc.segment8 future,
                    hou.NAME hr_organization,
                    location_code,
                    sup.first_name super_first_name,
                    sup.last_name super_last_name,
                    sup.full_name super_full_name,
                    rassi.display_name ROLE,
                    rassi.ROLE_NAME ROLE_KEY,
                    rassi.active_from,
                    rassi.active_to,
                    fu.start_date,
                    fu.end_date,
                    fu.email_address email_from_fnd,
                    a.email_address email_from_hr
               FROM apps.per_all_people_f a,
                    apps.per_all_assignments_f b,
                    apps.per_assignment_status_types past,
                    apps.hr_all_organization_units hou,
                    apps.hr_locations loc,
                    apps.per_all_people_f sup,
                    apps.gl_code_combinations_kfv glcc,
                    apps.fnd_user fu,
                    apps.umx_role_assignments_v rassi
              WHERE     1 = 1
                    AND a.person_id = b.person_id(+)
                    AND b.assignment_status_type_id =
                           past.assignment_status_type_id(+)
                    AND b.organization_id = hou.organization_id(+)
                    AND b.location_id = loc.location_id(+)
                    AND b.supervisor_id = sup.person_id(+)
                    AND b.primary_flag = 'Y'
                    AND b.default_code_comb_id = glcc.code_combination_id
                    AND fu.employee_id = a.person_id
                    AND rassi.user_name = fu.user_name
                    --                    AND rassi.role_name NOT LIKE 'UMX%'
                    --                    and fu.user_name = 'JACK.MAYNES'
                    --                    AND rassi.status_code = 'APPROVED'
                    --                    AND NVL (fu.end_date, SYSDATE + 1) >= SYSDATE
                    AND SYSDATE BETWEEN TRUNC (a.effective_start_date)
                                    AND NVL (TRUNC (a.effective_end_date),
                                             SYSDATE + 1)
                    AND SYSDATE BETWEEN TRUNC (b.effective_start_date(+))
                                    AND NVL (TRUNC (b.effective_end_date(+)),
                                             SYSDATE + 1)
                    AND SYSDATE BETWEEN TRUNC (sup.effective_start_date(+))
                                    AND NVL (TRUNC (sup.effective_end_date(+)),
                                             SYSDATE + 1)
             UNION
             SELECT fu.user_name,
                    NVL (a.first_name, ' ') emp_first_name,
                    NVL (a.last_name, ' ') emp_last_name,
                    NVL (a.full_name, ' ') emp_full_name,
                    NVL (a.employee_number, ' ') employee_number,
                    NULL AS company,
                    NULL AS department,
                    NULL AS department_description,
                    NULL AS ACCOUNT,
                    NULL AS sub_account,
                    NULL AS product,
                    NULL AS region,
                    NULL AS intercompany,
                    NULL AS future,
                    NULL AS hr_organization,
                    NULL AS location_code,
                    NULL AS super_first_name,
                    NULL AS super_last_name,
                    NULL AS super_full_name,
                    rassi.display_name ROLE,
                    rassi.ROLE_NAME ROLE_KEY,
                    rassi.active_from,
                    rassi.active_to,
                    fu.start_date,
                    fu.end_date,
                    fu.email_address email_from_fnd,
                    a.email_address email_from_hr
               FROM apps.fnd_user fu,
                    apps.umx_role_assignments_v rassi,
                    apps.per_all_people_f a
              WHERE     1 = 1
                    AND fu.user_name = rassi.user_name --                    AND rassi.role_name NOT LIKE 'UMX%'
         --                                   and fu.user_name = 'JACK.MAYNES'
                      --                    AND rassi.status_code = 'APPROVED'
           --                    AND NVL (fu.end_date, SYSDATE + 1) >= SYSDATE
                    AND fu.employee_id = a.person_id(+)
                    AND a.person_id IS NULL)
   ORDER BY user_name, ROLE;
