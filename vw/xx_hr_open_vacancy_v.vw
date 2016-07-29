DROP VIEW APPS.XX_HR_OPEN_VACANCY_V;

/* Formatted on 6/6/2016 4:58:32 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_OPEN_VACANCY_V
(
   SUPERVISOR_EMP_NUMBER,
   SUPERVISOR_NAME,
   COMPANY_NAME,
   DEPARTMENT_NAME,
   ENTITY,
   COST_CENTRE,
   PRODUCT,
   REGION,
   COUNTRY,
   DIVISION_PRODUCT,
   DIVISION_GEO_REGION,
   DIVISION,
   VACANCY_NAME,
   VACANCY_STATUS,
   VACANCY_TYPE,
   JOB,
   JOB_TITLE,
   POSITION_TITLE,
   NUMBER_OF_OPENINGS,
   HR_REP_NUMBER,
   HR_REP_NAME
)
AS
   SELECT (SELECT NVL (employee_number, npw_number)
             FROM per_all_people_f
            WHERE     person_id = pav.manager_id
                  AND SYSDATE BETWEEN effective_start_date
                                  AND effective_end_date --AND current_employee_flag = 'Y' -- Commented for 2733
                                                        )
             supervisor_emp_number,
          (SELECT full_name
             FROM per_all_people_f
            WHERE     person_id = pav.manager_id
                  AND SYSDATE BETWEEN effective_start_date
                                  AND effective_end_date --AND current_employee_flag = 'Y' -- Commented for 2733
                                                        )
             supervisor_name,
          (SELECT ffvv.description
             FROM fnd_flex_values_vl ffvv,
                  fnd_flex_value_sets ffvs,
                  pay_cost_allocation_keyflex pcak
            WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                  AND ffvv.flex_value = pcak.segment1
                  AND pcak.cost_allocation_keyflex_id =
                         haou.cost_allocation_keyflex_id
                  AND ffvs.flex_value_set_name = 'INTG_COMPANY'
                  AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                  AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                   TRUNC (SYSDATE))
                                          AND NVL (ffvv.end_date_active,
                                                   TRUNC (SYSDATE)))
             company_name,
          (SELECT name
             FROM hr_all_organization_units
            WHERE TYPE = 'DPT' AND organization_id = haou.organization_id)
             department_name,
          cflx.segment1 entity,
          cflx.segment2 cost_centre,
          cflx.segment5 product,
          cflx.segment6 region,
          loc.country country,
          (SELECT DISTINCT ffvv.description
             FROM fnd_flex_values_vl ffvv,
                  fnd_flex_value_sets ffvs,
                  gl_code_combinations glc
            WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                  AND flex_value_set_name = 'INTG_DIV_PRODUCT'
                  AND ffvv.flex_value = glc.attribute1
                  AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                  AND    glc.segment1
                      || '.'
                      || glc.segment2
                      || '.'
                      || glc.segment5
                      || '.'
                      || glc.segment6 =
                            cflx.segment1
                         || '.'
                         || cflx.segment2
                         || '.'
                         || cflx.segment5
                         || '.'
                         || cflx.segment6
                  AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                   TRUNC (SYSDATE))
                                          AND NVL (ffvv.end_date_active,
                                                   TRUNC (SYSDATE)))
             division_product,
          (SELECT DISTINCT ffvv.description
             FROM fnd_flex_values_vl ffvv,
                  fnd_flex_value_sets ffvs,
                  gl_code_combinations glc
            WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                  AND flex_value_set_name = 'INTG_DIV_REGION'
                  AND ffvv.flex_value = glc.attribute2
                  AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                  AND    glc.segment1
                      || '.'
                      || glc.segment2
                      || '.'
                      || glc.segment5
                      || '.'
                      || glc.segment6 =
                            cflx.segment1
                         || '.'
                         || cflx.segment2
                         || '.'
                         || cflx.segment5
                         || '.'
                         || cflx.segment6
                  AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                   TRUNC (SYSDATE))
                                          AND NVL (ffvv.end_date_active,
                                                   TRUNC (SYSDATE)))
             division_geo_region,
             (SELECT DISTINCT ffvv.description
                FROM fnd_flex_values_vl ffvv,
                     fnd_flex_value_sets ffvs,
                     gl_code_combinations glc
               WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                     AND flex_value_set_name = 'INTG_DIV_PRODUCT'
                     AND ffvv.flex_value = glc.attribute1
                     AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                     AND    glc.segment1
                         || '.'
                         || glc.segment2
                         || '.'
                         || glc.segment5
                         || '.'
                         || glc.segment6 =
                               cflx.segment1
                            || '.'
                            || cflx.segment2
                            || '.'
                            || cflx.segment5
                            || '.'
                            || cflx.segment6
                     AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                      TRUNC (SYSDATE))
                                             AND NVL (ffvv.end_date_active,
                                                      TRUNC (SYSDATE)))
          || '-'
          || (SELECT DISTINCT ffvv.description
                FROM fnd_flex_values_vl ffvv,
                     fnd_flex_value_sets ffvs,
                     gl_code_combinations glc
               WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                     AND flex_value_set_name = 'INTG_DIV_REGION'
                     AND ffvv.flex_value = glc.attribute2
                     AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                     AND    glc.segment1
                         || '.'
                         || glc.segment2
                         || '.'
                         || glc.segment5
                         || '.'
                         || glc.segment6 =
                               cflx.segment1
                            || '.'
                            || cflx.segment2
                            || '.'
                            || cflx.segment5
                            || '.'
                            || cflx.segment6
                     AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                      TRUNC (SYSDATE))
                                             AND NVL (ffvv.end_date_active,
                                                      TRUNC (SYSDATE)))
             division,
          pav.name vacancy_name,
          pav.status vacancy_status,
          pav.attribute1 vacancy_type,
          pj.name job,
          pjd.segment2 job_title,
          pap.name position_title,
          pav.number_of_openings,
          (SELECT papf2.employee_number
             FROM per_all_people_f papf2,
                  per_all_assignments_f paaf1,
                  hr_all_positions_f pp1
            WHERE     papf2.person_id = paaf1.person_id
                  AND paaf1.position_id = pp1.position_id(+)
                  AND SYSDATE BETWEEN papf2.effective_start_date
                                  AND papf2.effective_end_date
                  AND SYSDATE BETWEEN paaf1.effective_start_date
                                  AND paaf1.effective_end_date
                  AND SYSDATE BETWEEN pp1.effective_start_date
                                  AND pp1.effective_end_date
                  AND pp1.position_id = pp.attribute5
                  AND papf2.current_employee_flag = 'Y'
                  AND paaf1.assignment_type = 'E'
                  AND paaf1.primary_flag = 'Y')
             hr_rep_number,
          (SELECT papf2.full_name
             FROM per_all_people_f papf2,
                  per_all_assignments_f paaf1,
                  hr_all_positions_f pp1
            WHERE     papf2.person_id = paaf1.person_id
                  AND paaf1.position_id = pp1.position_id(+)
                  AND SYSDATE BETWEEN papf2.effective_start_date
                                  AND papf2.effective_end_date
                  AND SYSDATE BETWEEN paaf1.effective_start_date
                                  AND paaf1.effective_end_date
                  AND SYSDATE BETWEEN pp1.effective_start_date
                                  AND pp1.effective_end_date
                  AND pp1.position_id = pp.attribute5
                  AND papf2.current_employee_flag = 'Y'
                  AND paaf1.assignment_type = 'E'
                  AND paaf1.primary_flag = 'Y')
             hr_rep_name
     FROM per_all_vacancies pav,
          hr_all_positions_f pap,
          per_jobs pj,
          per_job_definitions pjd,
          hr_all_organization_units haou,
          pay_cost_allocation_keyflex cflx,
          hr_all_positions_f pp,
          hr_locations loc
    WHERE     pav.position_id(+) = pap.position_id
          AND pav.job_id = pj.job_id(+)
          AND pav.status = 'APPROVED'
          AND pj.job_definition_id = pjd.job_definition_id(+)
          AND pav.organization_id = haou.organization_id(+)
          AND haou.cost_allocation_keyflex_id =
                 cflx.cost_allocation_keyflex_id
          AND pap.position_id = pp.position_id
          AND pav.location_id = loc.location_id
          AND SYSDATE BETWEEN pap.effective_start_date
                          AND pap.effective_end_date;


GRANT SELECT ON APPS.XX_HR_OPEN_VACANCY_V TO XXAPPSHRRO;
