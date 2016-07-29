DROP VIEW APPS.XX_HR_EMPLOYEE_SUPERVISOR_V;

/* Formatted on 6/6/2016 4:58:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_EMPLOYEE_SUPERVISOR_V
(
   EMPLOYEE_NUMBER,
   EMPLOYEE_NAME,
   JOB,
   JOB_TITLE,
   EMPLOYEE_POSITION,
   WORK_LOCATION,
   SUPERVISOR_EMP_NUMBER,
   SUPERVISOR_NAME,
   RECORD_TYPE,
   COMPANY_NAME,
   DEPARTMENT_NAME,
   ENTITY,
   COST_CENTRE,
   PRODUCT,
   REGION,
   WORK_COUNTRY,
   DIVISION_PRODUCT,
   DIVISION_GEO_REGION,
   DIVISION,
   HR_REP_NUMBER,
   HR_REP_NAME
)
AS
     SELECT                                                  --papf.person_id,
            --paaf.organization_id,
            NVL (papf.employee_number, papf.npw_number) employee_number,
            papf.full_name employee_name,
            pj.name job,
            PJD.SEGMENT2 JOB_TITLE,
            PP.NAME,
            loc.location_code work_location       --,pa.town_or_city work_city
                                           ,
            (SELECT NVL (employee_number, npw_number)
               FROM per_all_people_f
              WHERE     person_id = paaf.supervisor_id
                    AND SYSDATE BETWEEN effective_start_date
                                    AND effective_end_date --AND current_employee_flag = 'Y' -- Commented for 2733
                                                          )
               supervisor_emp_number,
            (SELECT full_name
               FROM per_all_people_f
              WHERE     person_id = paaf.supervisor_id
                    AND SYSDATE BETWEEN effective_start_date
                                    AND effective_end_date --AND current_employee_flag = 'Y' -- Commented for 2733
                                                          )
               supervisor_name                       --,ppt.system_person_type
                              --,ppt.user_person_type
            ,
            TRIM (xx_hr_orgpublish_pkg.record_type (papf.person_id,
                                                    pj.name,
                                                    ppt.system_person_type,
                                                    pp.name))
               record_type,
            (SELECT ffvv.description
               FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
              WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                    AND flex_value_set_name = 'INTG_COMPANY'
                    AND ffvv.flex_value = gcc.segment1
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
            loc.country work_country,
            (SELECT ffvv.description
               FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
              WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                    AND flex_value_set_name = 'INTG_DIV_PRODUCT'
                    AND ffvv.flex_value = gcc.attribute1
                    AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                     TRUNC (SYSDATE))
                                            AND NVL (ffvv.end_date_active,
                                                     TRUNC (SYSDATE)))
               division_product,
            (SELECT ffvv.description
               FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
              WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                    AND flex_value_set_name = 'INTG_DIV_REGION'
                    AND ffvv.flex_value = gcc.attribute2
                    AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                    AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                     TRUNC (SYSDATE))
                                            AND NVL (ffvv.end_date_active,
                                                     TRUNC (SYSDATE)))
               division_geo_region,
               (SELECT ffvv.description
                  FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
                 WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                       AND flex_value_set_name = 'INTG_DIV_PRODUCT'
                       AND ffvv.flex_value = gcc.attribute1
                       AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                       AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                        TRUNC (SYSDATE))
                                               AND NVL (ffvv.end_date_active,
                                                        TRUNC (SYSDATE)))
            || '-'
            || (SELECT ffvv.description
                  FROM fnd_flex_values_vl ffvv, fnd_flex_value_sets ffvs
                 WHERE     ffvv.flex_value_set_id = ffvs.flex_value_set_id
                       AND flex_value_set_name = 'INTG_DIV_REGION'
                       AND ffvv.flex_value = gcc.attribute2
                       AND NVL (ffvv.enabled_flag, 'X') = 'Y'
                       AND TRUNC (SYSDATE) BETWEEN NVL (ffvv.start_date_active,
                                                        TRUNC (SYSDATE))
                                               AND NVL (ffvv.end_date_active,
                                                        TRUNC (SYSDATE)))
               division,
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
       FROM per_all_people_f papf,
            per_all_assignments_f paaf,
            per_jobs pj,
            per_job_definitions pjd,
            hr_locations loc,
            hr_all_positions_f pp,
            per_position_definitions ppd,
            hr_all_organization_units haou,
            gl_code_combinations gcc,
            per_person_type_usages_f pptuf,
            per_person_types ppt,
            pay_cost_allocation_keyflex cflx
      WHERE     papf.person_id = paaf.person_id
            AND paaf.job_id = pj.job_id
            --AND papf.current_employee_flag = 'Y'
            AND paaf.primary_flag = 'Y'
            AND paaf.location_id = loc.location_id(+)
            AND paaf.position_id = pp.position_id(+)
            AND pj.job_definition_id = pjd.job_definition_id(+)
            AND pp.position_definition_id = ppd.position_definition_id(+)
            AND gcc.code_combination_id(+) = paaf.default_code_comb_id
            AND haou.organization_id = paaf.organization_id
            AND haou.cost_allocation_keyflex_id =
                   cflx.cost_allocation_keyflex_id(+)
            AND SYSDATE BETWEEN papf.effective_start_date
                            AND papf.effective_end_date
            AND SYSDATE BETWEEN paaf.effective_start_date
                            AND paaf.effective_end_date
            AND SYSDATE BETWEEN pp.effective_start_date
                            AND pp.effective_end_date
            AND papf.person_id = pptuf.person_id(+)
            AND pptuf.person_type_id = ppt.person_type_id(+)
            AND TRUNC (SYSDATE) BETWEEN pptuf.effective_start_date
                                    AND pptuf.effective_end_date
            AND ppt.system_person_type IN ('EMP', 'CWK')
            AND NVL (papf.attribute5, 'X') <> 'No'
   ORDER BY PAPF.PERSON_ID;


GRANT SELECT ON APPS.XX_HR_EMPLOYEE_SUPERVISOR_V TO XXAPPSHRRO;
