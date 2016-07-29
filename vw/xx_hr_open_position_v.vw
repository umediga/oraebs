DROP VIEW APPS.XX_HR_OPEN_POSITION_V;

/* Formatted on 6/6/2016 4:58:33 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_OPEN_POSITION_V
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
   JOB,
   JOB_TITLE,
   POSITION_TITLE,
   NO_OF_POSITION,
   EFFECTIVE_START_DATE,
   HR_REP_NUMBER,
   HR_REP_NAME
)
AS
   SELECT (SELECT NVL (employee_number, npw_number)
             FROM per_all_people_f
            WHERE     person_id = pap.supervisor_id
                  AND SYSDATE BETWEEN effective_start_date
                                  AND EFFECTIVE_END_DATE --and CURRENT_EMPLOYEE_FLAG = 'Y' -- Commented for 2733
                                                        )
             supervisor_emp_number,
          (SELECT full_name
             FROM per_all_people_f
            WHERE     person_id = pap.supervisor_id
                  AND SYSDATE BETWEEN effective_start_date
                                  AND EFFECTIVE_END_DATE --AND current_employee_flag = 'Y' -- Commented for 2733
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
          pj.name job,
          jod.segment2 job_title,
          pap.name position_title,
          pap.max_persons no_of_position,
          pap.effective_start_date,
          (SELECT papf2.employee_number
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
                  AND pp1.position_id = pap.attribute5
                  AND papf2.current_employee_flag = 'Y'
                  AND paaf1.assignment_type = 'E'
                  AND paaf1.primary_flag = 'Y'
                  AND ROWNUM = 1)
             hr_rep_number,
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
                  AND pp1.position_id = pap.attribute5
                  AND papf2.current_employee_flag = 'Y'
                  AND paaf1.assignment_type = 'E'
                  AND paaf1.primary_flag = 'Y'
                  AND ROWNUM = 1)
             hr_rep_name
     FROM hr_all_positions_f pap,
          hr_all_organization_units haou,
          per_position_definitions pjd,
          hr_locations loc,
          pay_cost_allocation_keyflex cflx,
          per_jobs pj,
          per_job_definitions jod
    WHERE     pap.organization_id = haou.organization_id
          AND pap.position_definition_id = pjd.position_definition_id(+)
          AND haou.cost_allocation_keyflex_id =
                 cflx.cost_allocation_keyflex_id
          AND pap.location_id = loc.location_id
          AND pap.job_id = pj.job_id(+)
          AND pj.job_definition_id = jod.job_definition_id(+)
          AND SYSDATE BETWEEN pap.effective_start_date
                          AND pap.effective_end_date
          AND pap.position_id NOT IN
                 (SELECT position_id
                    FROM per_all_vacancies
                   WHERE     status <> 'CLOSED'
                         AND SYSDATE BETWEEN date_from
                                         AND NVL (date_to, SYSDATE + 1))
          AND pap.position_id NOT IN
                 (SELECT pp1.position_id
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
                         AND papf2.current_employee_flag = 'Y'
                         AND paaf1.assignment_type = 'E');


GRANT SELECT ON APPS.XX_HR_OPEN_POSITION_V TO XXAPPSHRRO;
