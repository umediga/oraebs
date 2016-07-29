DROP VIEW APPS.XX_HR_EMPLOYEE_ELEMENTS_V;

/* Formatted on 6/6/2016 4:58:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_EMPLOYEE_ELEMENTS_V
(
   PERSON_ID,
   ORGANIZATION_ID,
   EMPLOYEE_NUMBER,
   LAST_NAME,
   FIRST_NAME,
   MIDDLE_NAMES,
   EMPLOYEE_NAME,
   HIRE_DATE,
   ADJUSTED_SERVICE_DATE,
   WORK_LOCATION,
   WORK_CITY,
   WORK_COUNTRY,
   EMAIL_ADDRESS,
   GRE,
   SUPERVISOR_EMP_NUMBER,
   SUPERVISOR_NAME,
   JOB_TITLE,
   JOB_NAME,
   ASSIGNMENT_STATUS_TYPE_ID,
   USER_STATUS,
   POSITION_ID,
   POSITION_NAME,
   PAYROLL_ID,
   PAYROLL_NAME,
   ELEMENT_NAME,
   ELEMENT_PAY_VALUE,
   EFFECTIVE_START_DATE,
   EFFECTIVE_END_DATE,
   LAST_UPDATE_DATE,
   GREATEST_LAST_UPDATE_DATE,
   PAY_BASIS_ID,
   ASSIGNMENT_ID,
   ELEMENT_TYPE_ID,
   ELEMENT_ENTRY_ID,
   PERIOD_OF_SERVICE_ID
)
AS
   SELECT papf.person_id,
          paaf.organization_id,
          papf.employee_number,
          papf.last_name,
          papf.first_name,
          papf.middle_names,
          papf.full_name employee_name,
          ser.date_start hire_date,
          ser.adjusted_svc_date adjusted_service_date,
          loc.location_code work_location,
          loc.town_or_city work_city,
          loc.country work_country,
          papf.email_address,
          org.name gre,
          papf1.employee_number supervisor_emp_number,
          papf1.full_name supervisor_name,
          pj.name job_title,
          pjd.segment2 job_name,
          paaf.assignment_status_type_id,
          ast.user_status,
          paaf.position_id,
          hr_general.decode_position_latest_name (paaf.position_id)
             position_name,
          paaf.payroll_id,
          pay.payroll_name,
          elt.element_name,
          elv.screen_entry_value element_pay_value,
          -- to_char(ele.effective_start_date,'DD-MON-RRRR') effective_start_date,
          -- to_char(ele.effective_end_date,'DD-MON-RRRR') effective_end_date,
          ele.effective_start_date,
          ele.effective_end_date,
          ele.last_update_date,
          GREATEST (ele.last_update_date, ele.effective_start_date)
             Greatest_Last_Update_date,
          paaf.pay_basis_id,
          paaf.assignment_id,
          elt.element_type_id,
          elv.element_entry_id,
          ser.period_of_service_id
     FROM per_all_people_f papf,
          per_all_assignments_f paaf,
          per_jobs pj,
          per_job_definitions pjd,
          per_all_people_f papf1,
          hr_locations loc,
          hr_positions_f pp,
          per_position_definitions ppd,
          per_assignment_status_types_tl ast,
          pay_payrolls_f pay,
          per_periods_of_service ser,
          per_pay_proposals pro,
          pay_element_entries_f ele,
          pay_element_types_f_tl elt,
          hr_soft_coding_keyflex flx,
          pay_element_entry_values_f elv,
          hr_all_organization_units_tl org
    WHERE     papf.person_id = paaf.person_id(+)                          -- 1
          AND paaf.job_id = pj.job_id(+)
          AND papf1.person_id(+) = paaf.supervisor_id
          AND papf.current_employee_flag = 'Y'
          AND paaf.primary_flag = 'Y'
          AND paaf.location_id = loc.location_id(+)
          AND paaf.position_id = pp.position_id(+)
          AND pj.job_definition_id = pjd.job_definition_id(+)
          AND pp.position_definition_id = ppd.position_definition_id(+)
          AND paaf.assignment_status_type_id =
                 ast.assignment_status_type_id(+)                         -- 2
          AND paaf.payroll_id = pay.payroll_id(+)
          AND papf.person_id = ser.person_id(+)
          AND paaf.assignment_id = pro.assignment_id(+)
          AND paaf.assignment_id = ele.assignment_id(+)                   -- 3
          AND ele.element_type_id = elt.element_type_id
          AND paaf.soft_coding_keyflex_id = flx.soft_coding_keyflex_id(+)
          AND ele.element_entry_id = elv.element_entry_id
          AND elt.language = USERENV ('LANG')
          AND ast.language = USERENV ('LANG')
          AND flx.segment1 = org.organization_id
          AND org.language = USERENV ('LANG')
          AND SYSDATE BETWEEN papf.effective_start_date
                          AND papf.effective_end_date
          AND SYSDATE BETWEEN paaf.effective_start_date
                          AND paaf.effective_end_date
          -- AND SYSDATE BETWEEN ele.effective_start_date
          --               AND ele.effective_end_date
          AND SYSDATE BETWEEN papf1.effective_start_date(+)
                          AND papf1.effective_end_date(+)
          AND SYSDATE BETWEEN pp.effective_start_date(+)
                          AND pp.effective_end_date(+)
          AND SYSDATE BETWEEN ser.date_start
                          AND NVL (ser.actual_termination_date, SYSDATE + 1)
          AND NVL (pro.pay_proposal_id, -99) =
                 NVL ( (SELECT MAX (pay_proposal_id)
                          FROM per_pay_proposals
                         WHERE assignment_id = paaf.assignment_id),
                      -99)
          AND ele.element_type_id NOT IN
                 (SELECT element_type_id
                    FROM pay_input_values_f
                   WHERE input_value_id IN (SELECT input_value_id
                                              FROM per_pay_bases))
          AND DECODE (
                 hr_security.view_all,
                 'Y', 'TRUE',
                 hr_security.show_record ('HR_ALL_ORGANIZATION_UNITS',
                                          org.organization_id,
                                          'Y')) = 'TRUE'
          AND DECODE (hr_security.view_all,
                      'Y', 'TRUE',
                      hr_security.show_record ('PER_ALL_ASSIGNMENTS_F',
                                               paaf.assignment_id,
                                               papf.person_id,
                                               paaf.assignment_type,
                                               'Y')) = 'TRUE'
   --   AND papf.full_name like 'Elfner%Nicole%'--Element%'
   -- ORDER BY papf.person_id
   UNION ALL
   SELECT papf.person_id,
          paaf.organization_id,
          papf.employee_number,
          papf.last_name,
          papf.first_name,
          papf.middle_names,
          papf.full_name employee_name,
          ser.date_start hire_date,
          ser.adjusted_svc_date adjusted_service_date,
          loc.location_code work_location,
          loc.town_or_city work_city,
          loc.country work_country,
          papf.email_address,
          org.name gre,
          papf1.employee_number supervisor_emp_number,
          papf1.full_name supervisor_name,
          pj.name job_title,
          pjd.segment2 job_name,
          paaf.assignment_status_type_id,
          ast.user_status,
          paaf.position_id,
          hr_general.decode_position_latest_name (paaf.position_id)
             position_name,
          paaf.payroll_id,
          pay.payroll_name,
          elt.element_name,
          elv.screen_entry_value element_pay_value,
          --to_char(ele.effective_start_date,'DD-MON-RRRR') effective_start_date,
          --to_char(ele.effective_end_date,'DD-MON-RRRR') effective_end_date,
          ele.effective_start_date,
          ele.effective_end_date,
          ele.last_update_date,
          GREATEST (ele.last_update_date, ele.effective_start_date)
             Greatest_Last_Update_date,
          paaf.pay_basis_id,
          paaf.assignment_id,
          elt.element_type_id,
          elv.element_entry_id,
          ser.period_of_service_id
     FROM per_all_people_f papf,
          per_all_assignments_f paaf,
          per_jobs pj,
          per_job_definitions pjd,
          per_all_people_f papf1,
          hr_locations loc,
          hr_positions_f pp,
          per_position_definitions ppd,
          per_assignment_status_types_tl ast,
          pay_payrolls_f pay,
          per_periods_of_service ser,
          per_pay_proposals pro,
          pay_element_entries_f ele,
          pay_element_types_f_tl elt,
          hr_soft_coding_keyflex flx,
          pay_element_entry_values_f elv,
          hr_all_organization_units_tl org
    WHERE     papf.person_id = paaf.person_id
          AND paaf.job_id = pj.job_id(+)
          AND papf1.person_id(+) = paaf.supervisor_id
          AND NVL (papf.current_employee_flag, 'N') = 'N'
          --AND papf.current_employee_flag = 'Y'
          AND paaf.primary_flag = 'Y'
          AND ast.user_status = 'Terminate Assignment'
          AND paaf.location_id = loc.location_id(+)
          AND paaf.position_id = pp.position_id(+)
          AND pj.job_definition_id = pjd.job_definition_id(+)
          AND pp.position_definition_id = ppd.position_definition_id(+)
          AND paaf.assignment_status_type_id = ast.assignment_status_type_id
          AND paaf.payroll_id = pay.payroll_id(+)
          AND papf.person_id = ser.person_id(+)
          AND paaf.assignment_id = pro.assignment_id(+)
          AND paaf.assignment_id = ele.assignment_id
          AND ele.element_type_id = elt.element_type_id
          AND paaf.soft_coding_keyflex_id = flx.soft_coding_keyflex_id(+)
          AND ele.element_entry_id = elv.element_entry_id
          AND elt.language = USERENV ('LANG')
          AND ast.language = USERENV ('LANG')
          AND flx.segment1 = org.organization_id(+)
          AND org.language = USERENV ('LANG')
          AND SYSDATE BETWEEN papf.effective_start_date
                          AND papf.effective_end_date
          --   AND SYSDATE BETWEEN paaf.effective_start_date
          --                   AND paaf.effective_end_date
          --AND SYSDATE BETWEEN ele.effective_start_date
          --               AND ele.effective_end_date
          AND SYSDATE BETWEEN papf1.effective_start_date(+)
                          AND papf1.effective_end_date(+)
          AND SYSDATE BETWEEN pp.effective_start_date(+)
                          AND pp.effective_end_date(+)
          --  AND SYSDATE BETWEEN ser.date_start             AND NVL(ser.actual_termination_date,SYSDATE+1)
          AND NVL (pro.pay_proposal_id, -99) =
                 NVL ( (SELECT MAX (pay_proposal_id)
                          FROM per_pay_proposals
                         WHERE assignment_id = paaf.assignment_id),
                      -99)
          AND ele.element_type_id NOT IN
                 (SELECT element_type_id
                    FROM pay_input_values_f
                   WHERE input_value_id IN (SELECT input_value_id
                                              FROM per_pay_bases))
          AND DECODE (
                 hr_security.view_all,
                 'Y', 'TRUE',
                 hr_security.show_record ('HR_ALL_ORGANIZATION_UNITS',
                                          org.organization_id,
                                          'Y')) = 'TRUE'
          AND DECODE (hr_security.view_all,
                      'Y', 'TRUE',
                      hr_security.show_record ('PER_ALL_ASSIGNMENTS_F',
                                               paaf.assignment_id,
                                               papf.person_id,
                                               paaf.assignment_type,
                                               'Y')) = 'TRUE';
