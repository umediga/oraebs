DROP VIEW APPS.XX_HR_COGNOS_NEW_HIRE_EMP_V;

/* Formatted on 6/6/2016 4:58:36 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_COGNOS_NEW_HIRE_EMP_V
(
   EMPLOYEE_NUMBER,
   FIRST_NAME,
   LAST_NAME,
   ETHNIC_GROUP,
   GENDER,
   SYSTEM_PERSON_TYPE,
   USER_PERSON_TYPE,
   WORK_LOCATION,
   COUNTRY_OF_WORK,
   JOB_FAMILY,
   JOB_TITLE,
   JOB_CODE,
   JOB,
   POSITION_CODE,
   POSITION_TITLE,
   POSITION_NUMBER,
   POSITION,
   POSITION_TYPE,
   VACANCY_NAME,
   HIRE_TYPE,
   SUPERVISOR_NAME,
   SUPERVISOR_EMPLOYEE_NUMBER,
   DEPARTMENT_NAME,
   COST_STRING,
   SEGMENT1,
   SEGMENT2,
   SEGMENT3,
   SEGMENT4,
   SEGMENT5,
   SEGMENT6,
   SEGMENT7,
   SEGMENT8,
   PAYROLL,
   EXEMPT_STATUS,
   EMPLOYMENT_CATEGORY,
   WORKING_HOURS,
   LATEST_HIRE_DATE,
   ORIGINAL_HIRE_DATE,
   ADJUSTED_SERVICE_DATE,
   VETERAN_STATUS,
   EEO1_CATEGORY,
   HR_REPRESENTATIVE_NAME,
   NON_COMPETE_STATUS,
   CONFIDENTIALITY_STATUS,
   HOME_CITY,
   HOME_STATE,
   HOME_COUNTRY,
   ACTUAL_TERMINATION_DATE,
   USER_STATUS,
   SIRS_CODE,
   EMAIL_ADDRESS,
   LEGAL_ENTITY,
   PEOPLE_START_DATE,
   PEOPLE_END_DATE,
   ASSIGNMENT_START_DATE,
   ASSIGNMENT_END_DATE,
   USAGE_START_DATE,
   USAGE_END_DATE,
   PERSON_ID,
   ASSIGNMENT_ID,
   PAYROLL_START_DATE,
   PAYROLL_END_DATE,
   POSITION_START_DATE,
   POSITION_END_DATE
)
AS
     SELECT "EMPLOYEE_NUMBER1",
            "FIRST_NAME",
            "LAST_NAME",
            "ETHNIC_GROUP",
            "GENDER",
            "SYSTEM_PERSON_TYPE",
            "USER_PERSON_TYPE",
            "WORK_LOCATION",
            "COUNTRY_OF_WORK",
            "JOB_FAMILY",
            "JOB_TITLE",
            "JOB_CODE",
            "JOB",
            "POSITION_CODE",
            "POSITION_TITLE",
            "POSITION_NUMBER",
            "POSITION",
            "POSITION_TYPE",
            "VACANCY_NAME",
            "HIRE_TYPE",
            "SUPERVISOR_NAME",
            "SUPERVISOR_EMPLOYEE_NUMBER",
            "DEPARTMENT_NAME",
            "COST_STRING",
            "SEGMENT1",
            "SEGMENT2",
            "SEGMENT3",
            "SEGMENT4",
            "SEGMENT5",
            "SEGMENT6",
            "SEGMENT7",
            "SEGMENT8",
            "PAYROLL",
            "EXEMPT_STATUS",
            "EMPLOYMENT_CATEGORY",
            "WORKING_HOURS",
            "LATEST_HIRE_DATE",
            "ORIGINAL_HIRE_DATE",
            "ADJUSTED_SERVICE_DATE",
            "VETERAN_STATUS",
            "EEO1_CATEGORY",
            "HR_REPRESENTATIVE_NAME",
            "NON_COMPETE_STATUS",
            "CONFIDENTIALITY_STATUS",
            "HOME_CITY",
            "HOME_STATE",
            "HOME_COUNTRY"                                --Added on 31-JUL-13
                          ,
            "ACTUAL_TERMINATION_DATE",
            "USER_STATUS",
            "SIRS_CODE",
            "EMAIL_ADDRESS"                               --Added on 31-JUL-13
                           ,
            "LEGAL_ENTITY"                                --Added on 31-JUL-13
                          ,
            "PEOPLE_START_DATE",
            "PEOPLE_END_DATE",
            "ASSIGNMENT_START_DATE",
            "ASSIGNMENT_END_DATE",
            "USAGE_START_DATE",
            "USAGE_END_DATE",
            "PERSON_ID",
            "ASSIGNMENT_ID",
            "PAYROLL_START_DATE",
            "PAYROLL_END_DATE",
            "POSITION_START_DATE",
            "POSITION_END_DATE"
       FROM (SELECT papf.business_group_id,
                    papf.person_id,
                    papf.person_type_id,
                    papf.full_name person_full_name,
                    papf.last_name,
                    papf.first_name,
                    TO_CHAR (papf.effective_start_date, 'DD-MON-YYYY')
                       people_start_date,
                    TO_CHAR (papf.effective_end_date, 'DD-MON-YYYY')
                       people_end_date,
                    papf.employee_number employee_number1,
                    papf.email_address,
                    hl1.meaning gender,
                    papf.attribute2 non_compete_status,
                    papf.attribute3 confidentiality_status,
                    ppt.system_person_type,
                    ppt.user_person_type,
                    TO_CHAR (pptuf.effective_start_date, 'DD-MON-YYYY')
                       usage_start_date,
                    TO_CHAR (pptuf.effective_end_date, 'DD-MON-YYYY')
                       usage_end_date,
                    --hl.meaning ethnic_group,                   Commented on 31-JUL-13
                    (SELECT col.end_user_column_name
                       FROM fnd_descr_flex_contexts_tl t,
                            fnd_descr_flex_contexts b,
                            fnd_descr_flex_col_usage_vl col
                      WHERE     b.application_id = t.application_id
                            AND b.descriptive_flexfield_name =
                                   t.descriptive_flexfield_name
                            AND b.descriptive_flex_context_code =
                                   t.descriptive_flex_context_code
                            AND b.application_id = col.application_id
                            AND b.descriptive_flexfield_name =
                                   col.descriptive_flexfield_name
                            AND b.descriptive_flex_context_code =
                                   col.descriptive_flex_context_code
                            AND b.descriptive_flex_context_code =
                                   'US_ETHNIC_ORIGIN'
                            AND t.LANGUAGE = USERENV ('LANG')
                            AND application_column_name =
                                   (SELECT t.eo
                                      FROM (SELECT DECODE (
                                                      pei_information7,
                                                      'Y', 'PEI_INFORMATION7',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                            UNION
                                            SELECT DECODE (
                                                      pei_information1,
                                                      'Y', 'PEI_INFORMATION1',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information2,
                                                      'Y', 'PEI_INFORMATION2',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information3,
                                                      'Y', 'PEI_INFORMATION3',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information4,
                                                      'Y', 'PEI_INFORMATION4',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information5,
                                                      'Y', 'PEI_INFORMATION5',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information6,
                                                      'Y', 'PEI_INFORMATION6',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y')
                                           t
                                     WHERE     t.eo IS NOT NULL
                                           AND t.person_id = papf.person_id))
                       ethnic_group,                      --Added on 31-JUL-13
                    pa.region_1 home_city,
                    pa.region_2 home_state,
                    pa.country home_country,              --Added on 31-JUL-13
                    TO_CHAR (paaf.effective_start_date, 'DD-MON-YYYY')
                       assignment_start_date,
                    TO_CHAR (paaf.effective_end_date, 'DD-MON-YYYY')
                       assignment_end_date,
                    paaf.assignment_id,
                    paaf.position_id,
                    paaf.job_id,
                    paaf.payroll_id,
                    paaf.location_id,
                    paaf.supervisor_id,
                    hloc.location_code work_location,
                    hloc.country country_of_work,
                    pjd.segment1 job_family,
                    pjd.segment2 job_title,
                    pjd.segment3 job_code,
                    pj.NAME job,
                    ppod.segment2 position_code,
                    ppod.segment1 position_title,
                    ppod.segment3 position_number,
                    hapf.NAME POSITION,
                    hapf.position_type position_type,
                    TO_CHAR (hapf.effective_start_date, 'DD-MON-YYYY')
                       position_start_date,
                    TO_CHAR (hapf.effective_end_date, 'DD-MON-YYYY')
                       position_end_date,
                    pav.NAME vacancy_name,
                    pav.attribute1 hire_type,
                    papf1.full_name supervisor_name,
                    papf1.employee_number supervisor_employee_number,
                    haou.NAME department_name,
                    pcak.concatenated_segments cost_string,
                    pcak.segment1,
                    pcak.segment2,
                    pcak.segment3,
                    pcak.segment4,
                    pcak.segment5,
                    pcak.segment6,
                    pcak.segment7,
                    pcak.segment8,
                    ppay.payroll_name payroll,
                    TO_CHAR (ptp.start_date, 'DD-MON-YYYY') payroll_start_date,
                    TO_CHAR (ptp.end_date, 'DD-MON-YYYY') payroll_end_date,
                    (SELECT meaning
                       FROM hr_lookups
                      WHERE     lookup_type = 'US_EXEMPT_NON_EXEMPT'
                            AND application_id = 800
                            AND lookup_code = pj.job_information3
                            AND enabled_flag = 'Y'
                            AND TRUNC (SYSDATE) BETWEEN NVL (start_date_active,
                                                             TRUNC (SYSDATE))
                                                    AND NVL (end_date_active,
                                                             TRUNC (SYSDATE)))
                       exempt_status, --ppb.pay_basis exempt_status,  Modified on 31-JUL-13
                    ppb.NAME basis_name,
                    paaf.normal_hours working_hours,
                    (SELECT meaning
                       FROM fnd_lookup_values
                      WHERE     lookup_type(+) = 'EMP_CAT'
                            AND lookup_code(+) = paaf.employment_category
                            AND LANGUAGE(+) = USERENV ('LANG')
                            AND enabled_flag(+) = 'Y')
                       employment_category,
                    ppos.date_start latest_hire_date,
                    TO_CHAR (papf.original_date_of_hire, 'DD-MON-YYYY')
                       original_hire_date,
                    TO_CHAR (ppos.adjusted_svc_date, 'DD-MON-YYYY')
                       adjusted_service_date,
                    TO_CHAR (ppos.actual_termination_date, 'DD-MON-YYYY')
                       actual_termination_date,
                    passt.user_status user_status,
                    hl2.meaning veteran_status,
                    hl3.meaning eeo1_category,
                    (SELECT papf2.full_name
                       FROM per_all_people_f papf2,
                            per_all_assignments_f paaf1,
                            hr_all_positions_f pp1
                      WHERE     papf2.person_id = paaf1.person_id
                            AND paaf1.position_id = pp1.position_id
                            AND SYSDATE BETWEEN papf2.effective_start_date
                                            AND papf2.effective_end_date
                            AND SYSDATE BETWEEN paaf1.effective_start_date
                                            AND paaf1.effective_end_date
                            AND SYSDATE BETWEEN pp1.effective_start_date
                                            AND pp1.effective_end_date
                            AND pp1.position_id = hapf.attribute5
                            AND papf2.current_employee_flag = 'Y'
                            AND paaf1.assignment_type = 'E'
                            AND paaf1.primary_flag = 'Y'
                            AND ROWNUM = 1)
                       hr_representative_name,
                    pj.attribute2 sirs_code /* (select change_date
                                                from per_pay_proposals
                                               where assignment_id = paaf.assignment_id
                                                 and pay_proposal_id = (SELECT MAX(pay_proposal_id)
                                                                          FROM per_pay_proposals
                                                                         WHERE assignment_id = paaf.assignment_id)) pay_period_start_date,
                                             (select date_to
                                                from per_pay_proposals
                                               where assignment_id = paaf.assignment_id
                                                 and pay_proposal_id = (SELECT MAX(pay_proposal_id)
                                                                          FROM per_pay_proposals
                                                                         WHERE assignment_id = paaf.assignment_id)) pay_period_end_date */
                                           ,
                    (SELECT org.name
                       FROM hr_soft_coding_keyflex flx,
                            hr_all_organization_units_tl org
                      WHERE     flx.segment1 = org.organization_id
                            AND org.language = USERENV ('LANG')
                            AND flx.soft_coding_keyflex_id =
                                   paaf.soft_coding_keyflex_id)
                       legal_entity                       --Added on 31-JUL-13
               FROM per_all_people_f papf,
                    per_person_types ppt,
                    per_person_type_usages_f pptuf,
                    hr_lookups hl,
                    hr_lookups hl1,
                    per_addresses pa,
                    per_all_assignments_f paaf,
                    hr_locations hloc,
                    per_jobs pj,
                    per_job_definitions pjd,
                    hr_all_positions_f hapf,
                    per_position_definitions ppod,
                    per_all_vacancies pav,
                    per_all_people_f papf1,
                    hr_all_organization_units haou,
                    pay_cost_allocation_keyflex pcak,
                    pay_all_payrolls_f ppay,
                    per_pay_bases ppb,
                    per_periods_of_service ppos,
                    per_assignment_status_types passt,
                    hr_lookups hl2,
                    hr_lookups hl3,
                    per_time_periods_v ptp
              WHERE     1 = 1
                    AND TRUNC (ppos.date_start) BETWEEN papf.effective_start_date
                                                    AND papf.effective_end_date
                    AND papf.person_id = pptuf.person_id
                    AND pptuf.person_type_id = ppt.person_type_id
                    AND papf.business_group_id = ppt.business_group_id
                    AND TRUNC (ppos.date_start) BETWEEN pptuf.effective_start_date
                                                    AND pptuf.effective_end_date
                    AND ppt.system_person_type IN ('EMP')
                    AND ppt.active_flag = 'Y'
                    AND NVL (papf.attribute5, 'Y') <> 'No' --Added on 31-JUL-13
                    --AND papf.person_type_id = pptuf.person_type_id
                    AND 'US_ETHNIC_GROUP' = hl.lookup_type(+)
                    AND papf.per_information1 = hl.lookup_code(+)
                    AND hl.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl.end_date_active(+),
                                                     TRUNC (SYSDATE))
                    AND 'SEX' = hl1.lookup_type(+)
                    AND papf.sex = hl1.lookup_code(+)
                    AND hl1.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl1.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl1.end_date_active(+),
                                                     TRUNC (SYSDATE))
                    AND pa.person_id(+) = papf.person_id
                    AND pa.business_group_id(+) = papf.business_group_id
                    AND TRUNC (SYSDATE) BETWEEN NVL (pa.date_from(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (pa.date_to(+),
                                                     TRUNC (SYSDATE))
                    AND pa.primary_flag(+) = 'Y'
                    AND TRUNC (ppos.date_start) BETWEEN paaf.effective_start_date
                                                    AND paaf.effective_end_date
                    AND papf.person_id = paaf.person_id
                    AND paaf.primary_flag(+) = 'Y'
                    AND paaf.assignment_type(+) IN ('E')
                    AND papf.business_group_id = paaf.business_group_id
                    AND hloc.location_id(+) = paaf.location_id
                    AND pj.job_id(+) = paaf.job_id
                    AND pj.business_group_id(+) = paaf.business_group_id
                    AND TRUNC (SYSDATE) BETWEEN NVL (pj.date_from(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (pj.date_to(+),
                                                     TRUNC (SYSDATE))
                    AND pj.job_definition_id = pjd.job_definition_id(+)
                    AND pjd.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date(+)
                                            AND hapf.effective_end_date(+)
                    AND hapf.position_id(+) = paaf.position_id
                    AND hapf.business_group_id(+) = paaf.business_group_id
                    AND hapf.position_definition_id =
                           ppod.position_definition_id(+)
                    AND ppod.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (pav.date_from(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (pav.date_to(+),
                                                     TRUNC (SYSDATE))
                    --AND pav.job_id(+) = paaf.job_id
                    --AND pav.position_id(+) = paaf.position_id
                    AND pav.business_group_id(+) = paaf.business_group_id
                    AND pav.vacancy_id(+) = paaf.vacancy_id
                    AND TRUNC (SYSDATE) BETWEEN papf1.effective_start_date(+)
                                            AND papf1.effective_end_date(+)
                    AND papf1.person_id(+) = paaf.supervisor_id
                    AND haou.organization_id(+) = paaf.organization_id
                    AND haou.cost_allocation_keyflex_id =
                           pcak.cost_allocation_keyflex_id(+)
                    AND ppay.payroll_id(+) = paaf.payroll_id
                    AND ptp.payroll_id(+) = paaf.payroll_id
                    AND TRUNC (SYSDATE) BETWEEN ptp.start_date(+)
                                            AND ptp.end_date(+)
                    AND ppay.business_group_id(+) = paaf.business_group_id
                    AND TRUNC (SYSDATE) BETWEEN ppay.effective_start_date(+)
                                            AND ppay.effective_end_date(+)
                    AND ppb.pay_basis_id(+) = paaf.pay_basis_id
                    AND ppb.business_group_id(+) = paaf.business_group_id
                    AND paaf.business_group_id = ppos.business_group_id(+)
                    AND paaf.period_of_service_id =
                           ppos.period_of_service_id(+)
                    AND passt.assignment_status_type_id(+) =
                           paaf.assignment_status_type_id
                    --and  passt.business_group_id(+)         = paaf.business_group_id
                    AND passt.active_flag(+) = 'Y'
                    AND 'US_VETERAN_STATUS_VETS100A' = hl2.lookup_type(+)
                    AND papf.per_information25 = hl2.lookup_code(+) --AND papf.per_information5 = hl2.lookup_code(+)  Modified on 31-JUL-13
                    AND hl2.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl2.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl2.end_date_active(+),
                                                     TRUNC (SYSDATE))
                    AND 'US_EEO1_JOB_CATEGORIES' = hl3.lookup_type(+)
                    AND pj.job_information1 = hl3.lookup_code(+)
                    AND hl3.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl3.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl3.end_date_active(+),
                                                     TRUNC (SYSDATE))
             UNION
             SELECT papf.business_group_id,
                    papf.person_id,
                    papf.person_type_id,
                    papf.full_name person_full_name,
                    papf.last_name,
                    papf.first_name,
                    TO_CHAR (papf.effective_start_date, 'DD-MON-YYYY')
                       people_start_date,
                    TO_CHAR (papf.effective_end_date, 'DD-MON-YYYY')
                       people_end_date,
                    papf.npw_number employee_number1,
                    papf.email_address,
                    hl1.meaning gender,
                    papf.attribute2 non_compete_status,
                    papf.attribute3 confidentiality_status,
                    ppt.system_person_type,
                    ppt.user_person_type,
                    TO_CHAR (pptuf.effective_start_date, 'DD-MON-YYYY')
                       usage_start_date,
                    TO_CHAR (pptuf.effective_end_date, 'DD-MON-YYYY')
                       usage_end_date,
                    --hl.meaning ethnic_group,                   Commented on 31-JUL-13
                    (SELECT col.end_user_column_name
                       FROM fnd_descr_flex_contexts_tl t,
                            fnd_descr_flex_contexts b,
                            fnd_descr_flex_col_usage_vl col
                      WHERE     b.application_id = t.application_id
                            AND b.descriptive_flexfield_name =
                                   t.descriptive_flexfield_name
                            AND b.descriptive_flex_context_code =
                                   t.descriptive_flex_context_code
                            AND b.application_id = col.application_id
                            AND b.descriptive_flexfield_name =
                                   col.descriptive_flexfield_name
                            AND b.descriptive_flex_context_code =
                                   col.descriptive_flex_context_code
                            AND b.descriptive_flex_context_code =
                                   'US_ETHNIC_ORIGIN'
                            AND t.LANGUAGE = USERENV ('LANG')
                            AND application_column_name =
                                   (SELECT t.eo
                                      FROM (SELECT DECODE (
                                                      pei_information7,
                                                      'Y', 'PEI_INFORMATION7',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                            UNION
                                            SELECT DECODE (
                                                      pei_information1,
                                                      'Y', 'PEI_INFORMATION1',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information2,
                                                      'Y', 'PEI_INFORMATION2',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information3,
                                                      'Y', 'PEI_INFORMATION3',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information4,
                                                      'Y', 'PEI_INFORMATION4',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information5,
                                                      'Y', 'PEI_INFORMATION5',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y'
                                            UNION
                                            SELECT DECODE (
                                                      pei_information6,
                                                      'Y', 'PEI_INFORMATION6',
                                                      NULL)
                                                      eo,
                                                   person_id
                                              FROM per_people_extra_info
                                             WHERE     1 = 1
                                                   AND pei_information7 <> 'Y')
                                           t
                                     WHERE     t.eo IS NOT NULL
                                           AND t.person_id = papf.person_id))
                       ethnic_group,                      --Added on 31-JUL-13
                    pa.region_1 home_city,
                    pa.region_2 home_state,
                    pa.country home_country,              --Added on 31-JUL-13
                    TO_CHAR (paaf.effective_start_date, 'DD-MON-YYYY')
                       assignment_start_date,
                    TO_CHAR (paaf.effective_end_date, 'DD-MON-YYYY')
                       assignment_end_date,
                    paaf.assignment_id,
                    paaf.position_id,
                    paaf.job_id,
                    paaf.payroll_id,
                    paaf.location_id,
                    paaf.supervisor_id,
                    hloc.location_code work_location,
                    hloc.country country_of_work,
                    pjd.segment1 job_family,
                    pjd.segment2 job_title,
                    pjd.segment3 job_code,
                    pj.NAME job,
                    ppod.segment2 position_code,
                    ppod.segment1 position_title,
                    ppod.segment3 position_number,
                    hapf.NAME POSITION,
                    hapf.position_type position_type,
                    TO_CHAR (hapf.effective_start_date, 'DD-MON-YYYY')
                       position_start_date,
                    TO_CHAR (hapf.effective_end_date, 'DD-MON-YYYY')
                       position_end_date,
                    pav.NAME vacancy_name,
                    pav.attribute1 hire_type,
                    papf1.full_name supervisor_name,
                    papf1.employee_number supervisor_employee_number,
                    haou.NAME department_name,
                    pcak.concatenated_segments cost_string,
                    pcak.segment1,
                    pcak.segment2,
                    pcak.segment3,
                    pcak.segment4,
                    pcak.segment5,
                    pcak.segment6,
                    pcak.segment7,
                    pcak.segment8,
                    ppay.payroll_name payroll,
                    TO_CHAR (ptp.start_date, 'DD-MON-YYYY') payroll_start_date,
                    TO_CHAR (ptp.end_date, 'DD-MON-YYYY') payroll_end_date,
                    (SELECT meaning
                       FROM hr_lookups
                      WHERE     lookup_type = 'US_EXEMPT_NON_EXEMPT'
                            AND application_id = 800
                            AND lookup_code = pj.job_information3
                            AND enabled_flag = 'Y'
                            AND TRUNC (SYSDATE) BETWEEN NVL (start_date_active,
                                                             TRUNC (SYSDATE))
                                                    AND NVL (end_date_active,
                                                             TRUNC (SYSDATE)))
                       exempt_status, --ppb.pay_basis exempt_status,  Modified on 31-JUL-13
                    ppb.NAME basis_name,
                    paaf.normal_hours working_hours,
                    (SELECT meaning
                       FROM fnd_lookup_values
                      WHERE     lookup_type(+) = 'EMP_CAT'
                            AND lookup_code(+) = paaf.employment_category
                            AND LANGUAGE(+) = USERENV ('LANG')
                            AND enabled_flag(+) = 'Y')
                       employment_category,
                    ppos.date_start latest_hire_date,
                    TO_CHAR (papf.original_date_of_hire, 'DD-MON-YYYY')
                       original_hire_date,
                    NULL adjusted_service_date,
                    TO_CHAR (ppos.actual_termination_date, 'DD-MON-YYYY')
                       actual_termination_date,
                    passt.user_status user_status,
                    hl2.meaning veteran_status,
                    hl3.meaning eeo1_category,
                    (SELECT papf2.full_name
                       FROM per_all_people_f papf2,
                            per_all_assignments_f paaf1,
                            hr_all_positions_f pp1
                      WHERE     papf2.person_id = paaf1.person_id
                            AND paaf1.position_id = pp1.position_id
                            AND SYSDATE BETWEEN papf2.effective_start_date
                                            AND papf2.effective_end_date
                            AND SYSDATE BETWEEN paaf1.effective_start_date
                                            AND paaf1.effective_end_date
                            AND SYSDATE BETWEEN pp1.effective_start_date
                                            AND pp1.effective_end_date
                            AND pp1.position_id = hapf.attribute5
                            AND papf2.current_employee_flag = 'Y'
                            AND paaf1.assignment_type = 'E'
                            AND paaf1.primary_flag = 'Y'
                            AND ROWNUM = 1)
                       hr_representative_name,
                    pj.attribute2 sirs_code /* (select change_date
                                                from per_pay_proposals
                                               where assignment_id = paaf.assignment_id
                                                 and pay_proposal_id = (SELECT MAX(pay_proposal_id)
                                                                          FROM per_pay_proposals
                                                                         WHERE assignment_id = paaf.assignment_id)) pay_period_start_date,
                                             (select date_to
                                                from per_pay_proposals
                                               where assignment_id = paaf.assignment_id
                                                 and pay_proposal_id = (SELECT MAX(pay_proposal_id)
                                                                          FROM per_pay_proposals
                                                                         WHERE assignment_id = paaf.assignment_id)) pay_period_end_date */
                                           ,
                    (SELECT org.name
                       FROM hr_soft_coding_keyflex flx,
                            hr_all_organization_units_tl org
                      WHERE     flx.segment1 = org.organization_id
                            AND org.language = USERENV ('LANG')
                            AND flx.soft_coding_keyflex_id =
                                   paaf.soft_coding_keyflex_id)
                       legal_entity                       --Added on 31-JUL-13
               FROM per_all_people_f papf,
                    per_person_types ppt,
                    per_person_type_usages_f pptuf,
                    hr_lookups hl,
                    hr_lookups hl1,
                    per_addresses pa,
                    per_all_assignments_f paaf,
                    hr_locations hloc,
                    per_jobs pj,
                    per_job_definitions pjd,
                    hr_all_positions_f hapf,
                    per_position_definitions ppod,
                    per_all_vacancies pav,
                    per_all_people_f papf1,
                    hr_all_organization_units haou,
                    pay_cost_allocation_keyflex pcak,
                    pay_all_payrolls_f ppay,
                    per_pay_bases ppb,
                    per_periods_of_placement_v ppos,
                    per_assignment_status_types passt,
                    hr_lookups hl2,
                    hr_lookups hl3,
                    per_time_periods_v ptp
              WHERE     1 = 1
                    AND TRUNC (ppos.date_start) BETWEEN papf.effective_start_date
                                                    AND papf.effective_end_date
                    AND papf.person_id = pptuf.person_id
                    AND pptuf.person_type_id = ppt.person_type_id
                    AND papf.business_group_id = ppt.business_group_id
                    AND TRUNC (ppos.date_start) BETWEEN pptuf.effective_start_date
                                                    AND pptuf.effective_end_date
                    AND ppt.system_person_type IN ('CWK')
                    AND ppt.active_flag = 'Y'
                    AND NVL (papf.attribute5, 'Y') <> 'No' --Added on 31-JUL-13
                    --AND papf.person_type_id = pptuf.person_type_id
                    AND 'US_ETHNIC_GROUP' = hl.lookup_type(+)
                    AND papf.per_information1 = hl.lookup_code(+)
                    AND hl.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl.end_date_active(+),
                                                     TRUNC (SYSDATE))
                    AND 'SEX' = hl1.lookup_type(+)
                    AND papf.sex = hl1.lookup_code(+)
                    AND hl1.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl1.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl1.end_date_active(+),
                                                     TRUNC (SYSDATE))
                    AND pa.person_id(+) = papf.person_id
                    AND pa.business_group_id(+) = papf.business_group_id
                    AND TRUNC (SYSDATE) BETWEEN NVL (pa.date_from(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (pa.date_to(+),
                                                     TRUNC (SYSDATE))
                    AND pa.primary_flag(+) = 'Y'
                    AND TRUNC (ppos.date_start) BETWEEN paaf.effective_start_date
                                                    AND paaf.effective_end_date
                    AND papf.person_id = paaf.person_id
                    AND paaf.primary_flag(+) = 'Y'
                    AND paaf.assignment_type(+) IN ('C')
                    AND papf.business_group_id = paaf.business_group_id
                    AND hloc.location_id(+) = paaf.location_id
                    AND pj.job_id(+) = paaf.job_id
                    AND pj.business_group_id(+) = paaf.business_group_id
                    AND TRUNC (SYSDATE) BETWEEN NVL (pj.date_from(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (pj.date_to(+),
                                                     TRUNC (SYSDATE))
                    AND pj.job_definition_id = pjd.job_definition_id(+)
                    AND pjd.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date(+)
                                            AND hapf.effective_end_date(+)
                    AND hapf.position_id(+) = paaf.position_id
                    AND hapf.business_group_id(+) = paaf.business_group_id
                    AND hapf.position_definition_id =
                           ppod.position_definition_id(+)
                    AND ppod.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (pav.date_from(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (pav.date_to(+),
                                                     TRUNC (SYSDATE))
                    --AND pav.job_id(+) = paaf.job_id
                    --AND pav.position_id(+) = paaf.position_id
                    AND pav.business_group_id(+) = paaf.business_group_id
                    AND pav.vacancy_id(+) = paaf.vacancy_id
                    AND TRUNC (SYSDATE) BETWEEN papf1.effective_start_date(+)
                                            AND papf1.effective_end_date(+)
                    AND papf1.person_id(+) = paaf.supervisor_id
                    AND haou.organization_id(+) = paaf.organization_id
                    AND haou.cost_allocation_keyflex_id =
                           pcak.cost_allocation_keyflex_id(+)
                    AND ptp.payroll_id(+) = paaf.payroll_id
                    AND TRUNC (SYSDATE) BETWEEN ptp.start_date(+)
                                            AND ptp.end_date(+)
                    AND ppay.payroll_id(+) = paaf.payroll_id
                    AND ppay.business_group_id(+) = paaf.business_group_id
                    AND TRUNC (SYSDATE) BETWEEN ppay.effective_start_date(+)
                                            AND ppay.effective_end_date(+)
                    AND ppb.pay_basis_id(+) = paaf.pay_basis_id
                    AND ppb.business_group_id(+) = paaf.business_group_id
                    ---AND paaf.business_group_id = ppos.business_group_id(+)
                    ---AND paaf.period_of_service_id = ppos.period_of_service_id(+)
                    AND papf.business_group_id = ppos.business_group_id(+)
                    AND papf.person_id = ppos.person_id(+)
                    AND passt.assignment_status_type_id(+) =
                           paaf.assignment_status_type_id
                    --and  passt.business_group_id(+)         = paaf.business_group_id
                    AND passt.active_flag(+) = 'Y'
                    AND 'US_VETERAN_STATUS_VETS100A' = hl2.lookup_type(+)
                    AND papf.per_information25 = hl2.lookup_code(+) --AND papf.per_information5 = hl2.lookup_code(+)  Modified on 31-JUL-13
                    AND hl2.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl2.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl2.end_date_active(+),
                                                     TRUNC (SYSDATE))
                    AND 'US_EEO1_JOB_CATEGORIES' = hl3.lookup_type(+)
                    AND pj.job_information1 = hl3.lookup_code(+)
                    AND hl3.enabled_flag(+) = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (hl3.start_date_active(+),
                                                     TRUNC (SYSDATE))
                                            AND NVL (hl3.end_date_active(+),
                                                     TRUNC (SYSDATE)))
   ORDER BY employee_number1;
