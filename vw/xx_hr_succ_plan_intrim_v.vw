DROP VIEW APPS.XX_HR_SUCC_PLAN_INTRIM_V;

/* Formatted on 6/6/2016 4:58:30 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_SUCC_PLAN_INTRIM_V
(
   "Parent Box Unique Identifier",
   "Box Unique Identifier",
   "Box Title",
   "Position Type",
   "Person Unique Identifier",
   "Last Name",
   "First Name",
   "Middle Name",
   "Position Title",
   "Position Unique Identifier",
   "Org Unit",
   "Org Unit ID",
   "Business Unit",
   "Division",
   "Department",
   "Job Family",
   "Job Function",
   "Job Title",
   "Employee ID",
   "User ID",
   "Hire Date",
   "Birth Date",
   "Gender",
   "Ethnicity",
   "FLSA Type",
   "Employee Type",
   "Employment Category",
   "Employment Status",
   "Country Code",
   "Location",
   "Email Address",
   "HR Business Partner ID",
   "Succession Candidate",
   "Talent To Watch",
   END,
   USER_PERSON_TYPE
)
AS
   SELECT (SELECT NVL (s_papf.employee_number, s_papf.npw_number)
             FROM apps.per_all_people_f s_papf
            WHERE     s_papf.person_id = paaf.supervisor_id
                  AND TRUNC (SYSDATE) BETWEEN s_papf.effective_start_date
                                          AND s_papf.effective_end_date --paaf.supervisor_id "Parent Box Unique Identifier"
                                                                       )
             "Parent Box Unique Identifier",
          papf.employee_number "Box Unique Identifier" --papf.person_id "Box Unique Identifier"
                                                      ,
          SUBSTR (haou.name,
                    INSTR (haou.name,
                           '-',
                           1,
                           2)
                  + 1,
                  (  INSTR (haou.name,
                            '-',
                            1,
                            3)
                   - INSTR (haou.name,
                            '-',
                            1,
                            2)
                   - 1))
             "Box Title",
          (SELECT DECODE (COUNT (asg.assignment_id), 0, 'E', 'M')
             FROM apps.per_all_assignments_f asg
            WHERE     asg.supervisor_id = papf.person_id
                  AND TRUNC (SYSDATE) BETWEEN asg.effective_start_date
                                          AND asg.effective_end_date)
             "Position Type",
          papf.employee_number "Person Unique Identifier" --papf.person_id "Person Unique Identifier"
                                                         ,
          papf.last_name "Last Name",
          papf.first_name "First Name",
          papf.middle_names "Middle Name",
          hapf.name "Position Title",
          hapf.position_id "Position Unique Identifier",
          haou.name "Org Unit",
          pcak.segment1 "Org Unit ID",
          (SELECT ffvv.description
             FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
            WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                  AND flex_value_set_name = 'INTG_REGION'
                  AND ffvv.flex_value = pcak.segment6
                  AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                  AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                   TRUNC (SYSDATE))
                                          AND NVL (ffvv.end_date_active,
                                                   TRUNC (SYSDATE)))
             "Business Unit",
          SUBSTR (haou.name,
                    INSTR (haou.name,
                           '-',
                           1,
                           2)
                  + 1,
                  (  INSTR (haou.name,
                            '-',
                            1,
                            3)
                   - INSTR (haou.name,
                            '-',
                            1,
                            2)
                   - 1))
             "Division",
          (SELECT ffvv.description
             FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
            WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                  AND flex_value_set_name = 'INTG_DEPARTMENT'
                  AND ffvv.flex_value = pcak.segment2
                  AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                  AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                   TRUNC (SYSDATE))
                                          AND NVL (ffvv.end_date_active,
                                                   TRUNC (SYSDATE)))
             "Department",
          pjd.segment1 "Job Family",
          pjd.segment1 "Job Function",
          pjd.segment2 || '.' || pjd.segment1 "Job Title",
          papf.employee_number "Employee ID"    --papf.person_id "Employee ID"
                                            ,
          fu.user_name "User ID",
          NVL (ppos.ADJUSTED_SVC_DATE, ppos.date_start) "Hire Date",
          papf.date_of_birth "Birth Date",
          papf.sex "Gender",
          DECODE (
             ppei.pei_information1,
             'Y', 'Hispanic',
             DECODE (
                ppei.pei_information2,
                'Y', 'American Indian Alaskan Native',
                DECODE (
                   ppei.pei_information3,
                   'Y', 'Asian',
                   DECODE (
                      ppei.pei_information4,
                      'Y', 'Black or African American',
                      DECODE (
                         ppei.pei_information5,
                         'Y', 'Native Hawaiian or Other Pacif',
                         DECODE (
                            ppei.pei_information6,
                            'Y', 'White',
                            DECODE (ppei.pei_information7,
                                    'Y', 'Two or More Race')))))))
             "Ethnicity" --,hr_general.decode_lookup('US_EXEMPT_NON_EXEMPT',pj.job_information3) "FLSA Type"
                        ,
          hl.meaning "FLSA Type",
          ppt.user_person_type "Employee Type" --,hr_general.decode_lookup('EMP_CAT',paaf.employment_category)"Employment Category"
                                              ,
          hl1.meaning "Employment Category",
          past.user_status "Employment Status",
          hla.country "Country Code",
          hla.location_code "Location",
          papf.email_address "Email Address",
          (SELECT NVL (HRP.employee_number, hrp.npw_number)
             FROM apps.per_all_assignments_f HRA,
                  apps.hr_all_positions_f HRO,
                  apps.per_all_people_f HRP
            WHERE     hrp.person_id = hra.person_id
                  AND HRA.position_id = HRO.position_id
                  AND HRO.position_id = hapf.attribute5
                  AND TRUNC (SYSDATE) BETWEEN HRA.effective_start_date
                                          AND HRA.effective_end_date
                  AND TRUNC (SYSDATE) BETWEEN HRO.effective_start_date
                                          AND HRO.effective_end_date
                  AND TRUNC (SYSDATE) BETWEEN HRP.effective_start_date
                                          AND HRP.effective_end_date
                  AND ROWNUM = 1)
             "HR Business Partner ID",
          DECODE (papf.attribute6, 'Yes', 'Y') "Succession Candidate",
          DECODE (papf.attribute8, 'Yes', 'Y') "Talent To Watch",
          'END' "END",
          ppt.user_person_type
     FROM apps.per_all_assignments_f paaf,
          apps.per_all_people_f papf,
          apps.hr_all_organization_units haou,
          apps.hr_all_positions_f hapf,
          apps.pay_cost_allocation_keyflex pcak,
          apps.per_jobs pj,
          apps.per_job_definitions pjd,
          apps.fnd_user fu,
          apps.per_periods_of_service ppos,
          apps.per_people_extra_info ppei,
          apps.per_person_types ppt,
          apps.per_person_type_usages_f pptuf,
          apps.per_assignment_status_types past,
          apps.hr_locations_all hla,
          apps.hr_lookups hl,
          apps.hr_lookups hl1
    WHERE     paaf.person_id = papf.person_id
          AND paaf.organization_id = haou.organization_id
          AND paaf.position_id = hapf.position_id(+)
          AND haou.cost_allocation_keyflex_id =
                 pcak.cost_allocation_keyflex_id
          AND paaf.job_id = pj.job_id(+)
          AND pj.job_definition_id = pjd.job_definition_id
          AND papf.person_id = fu.employee_id(+)
          AND papf.person_id = ppos.person_id
          AND paaf.period_of_service_id = ppos.period_of_service_id
          AND papf.person_id = ppei.person_id(+)
          AND ppt.person_type_id = pptuf.person_type_id
          AND pptuf.person_id = papf.person_id
          AND past.assignment_status_type_id = paaf.assignment_status_type_id
          AND paaf.location_id = hla.location_id(+)
          AND ppei.information_type(+) LIKE 'US_ETHNIC_ORIGIN'
          AND ppos.period_of_service_id =
                 (SELECT MAX (period_of_service_id)
                    FROM per_periods_of_service
                   WHERE     person_id = papf.person_id
                         AND date_start <= TRUNC (SYSDATE))
          AND paaf.assignment_type = 'E'
          AND ppt.system_person_type LIKE 'EMP'
          --and papf.attribute6 = 'Yes'
          AND ppt.active_flag = 'Y'
          AND pj.job_information3 = hl.lookup_code(+)
          AND hl.lookup_type(+) LIKE 'US_EXEMPT_NON_EXEMPT'
          AND hl.enabled_flag(+) = 'Y'
          AND TRUNC (SYSDATE) BETWEEN NVL (hl.start_date_active(+),
                                           TRUNC (SYSDATE))
                                  AND NVL (hl.end_date_active(+),
                                           TRUNC (SYSDATE))
          AND paaf.employment_category = hl1.lookup_code(+)
          AND hl1.lookup_type(+) LIKE 'EMP_CAT'
          AND hl1.enabled_flag(+) = 'Y'
          AND TRUNC (SYSDATE) BETWEEN NVL (hl1.start_date_active(+),
                                           TRUNC (SYSDATE))
                                  AND NVL (hl1.end_date_active(+),
                                           TRUNC (SYSDATE))
          --and fu.user_name not like '%@%'
          AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                  AND paaf.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                  AND papf.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                  AND pptuf.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                  AND hapf.effective_end_date
   UNION
   SELECT (SELECT NVL (s_papf.employee_number, s_papf.npw_number)
             FROM apps.per_all_people_f s_papf
            WHERE     s_papf.person_id = paaf.supervisor_id
                  AND TRUNC (SYSDATE) BETWEEN s_papf.effective_start_date
                                          AND s_papf.effective_end_date --paaf.supervisor_id "Parent Box Unique Identifier"
                                                                       )
             "Parent Box Unique Identifier",
          NVL (papf.employee_number, papf.npw_number) "Box Unique Identifier" --papf.person_id "Box Unique Identifier"
                                                                             ,
          SUBSTR (haou.name,
                    INSTR (haou.name,
                           '-',
                           1,
                           2)
                  + 1,
                  (  INSTR (haou.name,
                            '-',
                            1,
                            3)
                   - INSTR (haou.name,
                            '-',
                            1,
                            2)
                   - 1))
             "Box Title",
          (SELECT DECODE (COUNT (asg.assignment_id), 0, 'E', 'M')
             FROM apps.per_all_assignments_f asg
            WHERE     asg.supervisor_id = papf.person_id
                  AND TRUNC (SYSDATE) BETWEEN asg.effective_start_date
                                          AND asg.effective_end_date)
             "Position Type",
          NVL (papf.employee_number, papf.npw_number)
             "Person Unique Identifier" --papf.person_id "Person Unique Identifier"
                                       ,
          papf.last_name "Last Name",
          papf.first_name "First Name",
          papf.middle_names "Middle Name",
          hapf.name "Position Title",
          hapf.position_id "Position Unique Identifier",
          haou.name "Org Unit",
          pcak.segment1 "Org Unit ID",
          (SELECT ffvv.description
             FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
            WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                  AND flex_value_set_name = 'INTG_REGION'
                  AND ffvv.flex_value = pcak.segment6
                  AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                  AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                   TRUNC (SYSDATE))
                                          AND NVL (ffvv.end_date_active,
                                                   TRUNC (SYSDATE)))
             "Business Unit",
          SUBSTR (haou.name,
                    INSTR (haou.name,
                           '-',
                           1,
                           2)
                  + 1,
                  (  INSTR (haou.name,
                            '-',
                            1,
                            3)
                   - INSTR (haou.name,
                            '-',
                            1,
                            2)
                   - 1))
             "Division",
          (SELECT ffvv.description
             FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
            WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                  AND flex_value_set_name = 'INTG_DEPARTMENT'
                  AND ffvv.flex_value = pcak.segment2
                  AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                  AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                   TRUNC (SYSDATE))
                                          AND NVL (ffvv.end_date_active,
                                                   TRUNC (SYSDATE)))
             "Department",
          pjd.segment1 "Job Family",
          pjd.segment1 "Job Function",
          pjd.segment2 || '.' || pjd.segment1 "Job Title",
          NVL (papf.employee_number, papf.npw_number) "Employee ID" --papf.person_id "Employee ID"
                                                                   ,
          fu.user_name "User ID",
          ppop.date_start "Hire Date",
          papf.date_of_birth "Birth Date",
          papf.sex "Gender",
          DECODE (
             ppei.pei_information1,
             'Y', 'Hispanic',
             DECODE (
                ppei.pei_information2,
                'Y', 'American Indian Alaskan Native',
                DECODE (
                   ppei.pei_information3,
                   'Y', 'Asian',
                   DECODE (
                      ppei.pei_information4,
                      'Y', 'Black or African American',
                      DECODE (
                         ppei.pei_information5,
                         'Y', 'Native Hawaiian or Other Pacif',
                         DECODE (
                            ppei.pei_information6,
                            'Y', 'White',
                            DECODE (ppei.pei_information7,
                                    'Y', 'Two or More Race')))))))
             "Ethnicity" --,hr_general.decode_lookup('US_EXEMPT_NON_EXEMPT',pj.job_information3) "FLSA Type"
                        ,
          hl.meaning "FLSA Type",
          ppt.user_person_type "Employee Type" --,hr_general.decode_lookup('EMP_CAT',paaf.employment_category)"Employment Category"
                                              ,
          hl1.meaning "Employment Category",
          past.user_status "Employment Status",
          hla.country "Country Code",
          hla.location_code "Location",
          papf.email_address "Email Address",
          (SELECT NVL (HRP.employee_number, hrp.npw_number)
             FROM apps.per_all_assignments_f HRA,
                  apps.hr_all_positions_f HRO,
                  apps.per_all_people_f HRP
            WHERE     hrp.person_id = hra.person_id
                  AND HRA.position_id = HRO.position_id
                  AND HRO.position_id = hapf.attribute5
                  AND TRUNC (SYSDATE) BETWEEN HRA.effective_start_date
                                          AND HRA.effective_end_date
                  AND TRUNC (SYSDATE) BETWEEN HRO.effective_start_date
                                          AND HRO.effective_end_date
                  AND TRUNC (SYSDATE) BETWEEN HRP.effective_start_date
                                          AND HRP.effective_end_date
                  AND ROWNUM = 1)
             "HR Business Partner ID",
          DECODE (papf.attribute6, 'Yes', 'Y') "Succession Candidate",
          DECODE (papf.attribute8, 'Yes', 'Y') "Talent To Watch",
          'END' "END",
          ppt.user_person_type
     FROM apps.per_all_assignments_f paaf,
          apps.per_all_people_f papf,
          apps.hr_all_organization_units haou,
          apps.hr_all_positions_f hapf,
          apps.pay_cost_allocation_keyflex pcak,
          apps.per_jobs pj,
          apps.per_job_definitions pjd,
          apps.fnd_user fu,
          apps.per_periods_of_placement ppop,
          apps.per_people_extra_info ppei,
          apps.per_person_types ppt,
          apps.per_person_type_usages_f pptuf,
          apps.per_assignment_status_types past,
          apps.hr_locations_all hla,
          apps.hr_lookups hl,
          apps.hr_lookups hl1
    WHERE     paaf.person_id = papf.person_id
          AND paaf.organization_id = haou.organization_id
          AND paaf.position_id = hapf.position_id(+)
          AND haou.cost_allocation_keyflex_id =
                 pcak.cost_allocation_keyflex_id
          AND paaf.job_id = pj.job_id(+)
          AND pj.job_definition_id = pjd.job_definition_id
          AND papf.person_id = fu.employee_id(+)
          AND papf.person_id = ppop.person_id
          AND papf.person_id = ppei.person_id(+)
          AND ppt.person_type_id = pptuf.person_type_id
          AND pptuf.person_id = papf.person_id
          AND past.assignment_status_type_id = paaf.assignment_status_type_id
          AND paaf.location_id = hla.location_id(+)
          AND ppei.information_type(+) LIKE 'US_ETHNIC_ORIGIN'
          AND ppop.period_of_placement_id =
                 (SELECT MAX (period_of_placement_id)
                    FROM per_periods_of_placement
                   WHERE     person_id = papf.person_id
                         AND date_start <= TRUNC (SYSDATE))
          AND paaf.assignment_type = 'C'
          AND ppt.system_person_type LIKE 'CWK'
          --and papf.attribute6 = 'Yes'
          AND ppt.active_flag = 'Y'
          AND pj.job_information3 = hl.lookup_code(+)
          AND hl.lookup_type(+) LIKE 'US_EXEMPT_NON_EXEMPT'
          AND hl.enabled_flag(+) = 'Y'
          AND TRUNC (SYSDATE) BETWEEN NVL (hl.start_date_active(+),
                                           TRUNC (SYSDATE))
                                  AND NVL (hl.end_date_active(+),
                                           TRUNC (SYSDATE))
          AND paaf.employment_category = hl1.lookup_code(+)
          AND hl1.lookup_type(+) LIKE 'EMP_CAT'
          AND hl1.enabled_flag(+) = 'Y'
          AND TRUNC (SYSDATE) BETWEEN NVL (hl1.start_date_active(+),
                                           TRUNC (SYSDATE))
                                  AND NVL (hl1.end_date_active(+),
                                           TRUNC (SYSDATE))
          --and fu.user_name not like '%@%'
          AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                  AND paaf.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                  AND papf.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                  AND pptuf.effective_end_date
          AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                  AND hapf.effective_end_date
   ORDER BY 3;


GRANT SELECT ON APPS.XX_HR_SUCC_PLAN_INTRIM_V TO XXAPPSREAD;
