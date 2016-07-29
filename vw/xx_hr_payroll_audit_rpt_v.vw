DROP VIEW APPS.XX_HR_PAYROLL_AUDIT_RPT_V;

/* Formatted on 6/6/2016 4:58:31 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_HR_PAYROLL_AUDIT_RPT_V
(
   EMPLOYEE_NUMBER,
   LAST_NAME,
   FIRST_NAME,
   GRE_LE,
   FIELD_CHANGED,
   PREVIOUS_VALUE,
   NEW_VALUE,
   LAST_UPDATED_DATE,
   EFFECTIVE_DATE,
   RECORD_ID,
   REQUEST_ID,
   PERSON_ID,
   COUNTRY,
   COUNTRY_NAME,
   RUN_TYPE,
   PRIOR_REPORT_KEY,
   LOCATION_ID,
   GRE_ID,
   DATE_FROM,
   DATE_TO,
   PAYROLL_ID,
   PAYROLL_NAME,
   CREATED_BY,
   CREATION_DATE,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN
)
AS
   SELECT har.employee_number,
          har.last_name,
          har.first_name,
          (SELECT org.name
             FROM hr_soft_coding_keyflex flx,
                  hr_all_organization_units_tl org
            WHERE     org.organization_id = flx.segment1
                  AND org.language = USERENV ('LANG')
                  AND flx.soft_coding_keyflex_id = har.gre_id)
             gre_le,
          (SELECT flv.description
             FROM fnd_lookup_values flv
            WHERE     flv.lookup_type = 'XX_PAYROLL_AUDIT_REPORT'
                  AND flv.language = USERENV ('LANG')
                  AND flv.meaning = har.field_changed
                  AND NVL (flv.enabled_flag, 'N') = 'Y'
                  AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                 NVL (flv.start_date_active,
                                                      SYSDATE))
                                          AND   TRUNC (
                                                   NVL (flv.end_date_active,
                                                        SYSDATE))
                                              + 1)
             field_changed,
          (CASE har.field_changed
              WHEN 'PER_ALL_ASSIGNMENTS_F.SUPERVISOR_ID_N'
              THEN
                 (SELECT papf.full_name
                    FROM per_all_people_f papf
                   WHERE     papf.person_id = har.previous_value
                         AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                        NVL (
                                                           papf.effective_start_date,
                                                           SYSDATE))
                                                 AND   TRUNC (
                                                          NVL (
                                                             papf.effective_end_date,
                                                             SYSDATE))
                                                     + 1)
              WHEN 'PER_ALL_ASSIGNMENTS_F.POSITION_ID'
              THEN
                 (hr_general.decode_position_latest_name (har.previous_value))
              WHEN 'PER_ALL_ASSIGNMENTS_F.JOB_ID'
              THEN
                 (SELECT pj.name
                    FROM per_jobs pj
                   WHERE pj.job_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.LOCATION_ID'
              THEN
                 (SELECT loc.location_code
                    FROM hr_locations loc
                   WHERE loc.location_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.LOCATION_ID_C'
              THEN
                 (SELECT loc.country
                    FROM hr_locations loc
                   WHERE loc.location_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.ORGANIZATION_ID'
              THEN
                 (SELECT haou.name
                    FROM hr_all_organization_units haou
                   WHERE haou.organization_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.ASSIGNMENT_STATUS_TYPE_ID'
              THEN
                 (SELECT ast.user_status
                    FROM per_assignment_status_types_tl ast
                   WHERE     ast.language = USERENV ('LANG')
                         AND ast.assignment_status_type_id =
                                har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.PAY_BASIS_ID'
              THEN
                 (SELECT ppb.name
                    FROM per_pay_bases ppb
                   WHERE ppb.pay_basis_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.SUPERVISOR_ID'
              THEN
                 (SELECT papf1.employee_number
                    FROM per_all_people_f papf1
                   WHERE     papf1.person_id = har.previous_value
                         AND papf1.current_employee_flag = 'Y'
                         AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                        NVL (
                                                           papf1.effective_start_date,
                                                           SYSDATE))
                                                 AND   TRUNC (
                                                          NVL (
                                                             papf1.effective_end_date,
                                                             SYSDATE))
                                                     + 1)
              WHEN 'PER_ALL_ASSIGNMENTS_F.PAYROLL_ID'
              THEN
                 (SELECT pay.payroll_name
                    FROM pay_payrolls_f pay
                   WHERE pay.payroll_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_R'
              THEN
                 (SELECT gcc.segment6
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_D'
              THEN
                 (SELECT gcc.segment2
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_P'
              THEN
                 (SELECT gcc.segment5
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID'
              THEN
                 (SELECT gcc.segment1
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_T'
              THEN
                 (SELECT peo_tca.list_name
                    FROM hr_soft_coding_keyflex hsk_tca,
                         per_all_workforce_v peo_tca
                   WHERE     peo_tca.person_id = hsk_tca.segment2
                         AND hsk_tca.soft_coding_keyflex_id =
                                har.previous_value
                         AND TRUNC (SYSDATE) BETWEEN NVL (
                                                        peo_tca.effective_start_date,
                                                        TRUNC (SYSDATE))
                                                 AND NVL (
                                                        peo_tca.effective_end_date,
                                                        TRUNC (SYSDATE)))
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_S'
              THEN
                 (SELECT hl_shift.meaning
                    FROM hr_soft_coding_keyflex hsk_shift,
                         hr_lookups hl_shift,
                         fnd_application fa_shift
                   WHERE     hl_shift.lookup_type = 'US_SHIFTS'
                         AND hl_shift.lookup_code = hsk_shift.segment5
                         AND hsk_shift.soft_coding_keyflex_id =
                                har.previous_value
                         AND hl_shift.application_id =
                                fa_shift.application_id
                         AND fa_shift.application_short_name = 'PER')
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID'
              THEN
                 (SELECT org.name
                    FROM hr_soft_coding_keyflex flx,
                         hr_all_organization_units_tl org
                   WHERE     org.organization_id = flx.segment1
                         AND org.language = USERENV ('LANG')
                         AND flx.soft_coding_keyflex_id = har.previous_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_W'
              THEN
                 (SELECT (CASE
                             WHEN LENGTH (NVL (hs.segment8, pjw.wc_code)) < 4
                             THEN
                                0 || NVL (hs.segment8, pjw.wc_code)
                             ELSE
                                NVL (hs.segment8, pjw.wc_code)
                          END)
                    FROM per_all_assignments_f paaf,
                         hr_soft_coding_keyflex hs,
                         pay_job_wc_code_usages pjw,
                         hr_locations_all loc,
                         per_addresses adr
                   WHERE     paaf.job_id = pjw.job_id
                         AND paaf.soft_coding_keyflex_id =
                                hs.soft_coding_keyflex_id
                         AND paaf.location_id = loc.location_id
                         AND paaf.person_id = adr.person_id(+)
                         AND adr.date_to(+) IS NULL
                         AND adr.primary_flag(+) = 'Y'
                         AND paaf.assignment_type = 'E'    -- Added for CC5609
                         AND paaf.primary_flag = 'Y'       -- Added for CC5609
                         AND DECODE (
                                INSTR (loc.location_code, 'Home Office'),
                                0, loc.region_2,
                                adr.region_2) = pjw.state_code
                         AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                 AND paaf.effective_end_date
                         AND paaf.person_id = har.person_id
                         AND hs.soft_coding_keyflex_id = har.previous_value)
              WHEN 'PER_ALL_PEOPLE_F.SEX'
              THEN
                 DECODE (har.previous_value,
                         'M', 'Male',
                         'F', 'Female',
                         'Unknown')
              WHEN 'PER_ALL_PEOPLE_F.MARITAL_STATUS'
              THEN
                 (SELECT hrl.meaning
                    FROM hr_lookups hrl
                   WHERE     hrl.lookup_type = 'MAR_STATUS'
                         AND hrl.lookup_code = har.previous_value
                         AND NVL (hrl.enabled_flag, 'N') = 'Y')
              WHEN 'PER_PAY_PROPOSALS.PROPOSAL_REASON'
              THEN
                 (SELECT hrl.meaning
                    FROM hr_lookups hrl
                   WHERE     hrl.lookup_type = 'PROPOSAL_REASON'
                         AND hrl.lookup_code = har.previous_value
                         AND NVL (hrl.enabled_flag, 'N') = 'Y')
              WHEN 'PER_ALL_ASSIGNMENTS_F.FREQUENCY'
              THEN
                 (SELECT hrl.meaning
                    FROM hr_lookups hrl
                   WHERE     hrl.lookup_type = 'FREQUENCY'
                         AND hrl.lookup_code = har.previous_value
                         AND NVL (hrl.enabled_flag, 'N') = 'Y')
              WHEN 'PER_PAY_PROPOSALS.PROPOSED_SALARY_RATE'
              THEN
                 (SELECT TO_CHAR (
                            ROUND (
                                 DECODE (
                                    bas.pay_basis,
                                    'ANNUAL', har.previous_value,
                                    'HOURLY',   har.previous_value
                                              * paaf.normal_hours
                                              * 52,
                                    'PERIOD',   har.previous_value
                                              * bas.pay_annualization_factor,
                                    har.previous_value)
                               / DECODE (pay.period_type,
                                         'Bi-Week', 26,
                                         'Calendar Month', 12,
                                         'Semi-Month', 24,
                                         'Week', 52,
                                         1),
                               2))
                            ans
                    FROM per_all_assignments_f paaf,
                         per_pay_bases bas,
                         pay_all_payrolls_f pay
                   WHERE     paaf.pay_basis_id = bas.pay_basis_id
                         AND paaf.payroll_id = pay.payroll_id
                         AND paaf.assignment_type = 'E'    -- Added for CC5609
                         AND paaf.primary_flag = 'Y'       -- Added for CC5609
                         AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                 AND paaf.effective_end_date
                         AND paaf.person_id = har.person_id)
              ELSE
                 har.previous_value
           END)
             previous_value              --,har.previous_value previous_value1
                           ,
          (CASE har.field_changed
              WHEN 'PER_ALL_ASSIGNMENTS_F.SUPERVISOR_ID_N'
              THEN
                 (SELECT papf.full_name
                    FROM per_all_people_f papf
                   WHERE     papf.person_id = har.new_value
                         AND SYSDATE BETWEEN papf.effective_start_date
                                         AND papf.effective_end_date)
              WHEN 'PER_ALL_ASSIGNMENTS_F.POSITION_ID'
              THEN
                 (hr_general.decode_position_latest_name (har.new_value))
              WHEN 'PER_ALL_ASSIGNMENTS_F.JOB_ID'
              THEN
                 (SELECT pj.name
                    FROM per_jobs pj
                   WHERE pj.job_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.LOCATION_ID'
              THEN
                 (SELECT loc.location_code
                    FROM hr_locations loc
                   WHERE loc.location_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.LOCATION_ID_C'
              THEN
                 (SELECT loc.country
                    FROM hr_locations loc
                   WHERE loc.location_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.ORGANIZATION_ID'
              THEN
                 (SELECT haou.name
                    FROM hr_all_organization_units haou
                   WHERE haou.organization_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.ASSIGNMENT_STATUS_TYPE_ID'
              THEN
                 (SELECT ast.user_status
                    FROM per_assignment_status_types_tl ast
                   WHERE     ast.language = USERENV ('LANG')
                         AND ast.assignment_status_type_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.PAY_BASIS_ID'
              THEN
                 (SELECT ppb.name
                    FROM per_pay_bases ppb
                   WHERE ppb.pay_basis_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.SUPERVISOR_ID'
              THEN
                 ( (SELECT employee_number
                      FROM per_all_people_f
                     WHERE     person_id = har.new_value
                           AND SYSDATE BETWEEN effective_start_date
                                           AND effective_end_date
                           AND current_employee_flag = 'Y'))
              WHEN 'PER_ALL_ASSIGNMENTS_F.PAYROLL_ID'
              THEN
                 (SELECT pay.payroll_name
                    FROM pay_payrolls_f pay
                   WHERE pay.payroll_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_R'
              THEN
                 (SELECT gcc.segment6
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_D'
              THEN
                 (SELECT gcc.segment2
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID_P'
              THEN
                 (SELECT gcc.segment5
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.DEFAULT_CODE_COMB_ID'
              THEN
                 (SELECT gcc.segment1
                    FROM gl_code_combinations gcc
                   WHERE gcc.code_combination_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_T'
              THEN
                 (SELECT peo_tca.list_name
                    FROM hr_soft_coding_keyflex hsk_tca,
                         per_all_workforce_v peo_tca
                   WHERE     peo_tca.person_id = hsk_tca.segment2
                         AND hsk_tca.soft_coding_keyflex_id = har.new_value
                         AND TRUNC (SYSDATE) BETWEEN NVL (
                                                        peo_tca.effective_start_date,
                                                        TRUNC (SYSDATE))
                                                 AND NVL (
                                                        peo_tca.effective_end_date,
                                                        TRUNC (SYSDATE)))
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_S'
              THEN
                 (SELECT hl_shift.meaning
                    FROM hr_soft_coding_keyflex hsk_shift,
                         hr_lookups hl_shift,
                         fnd_application fa_shift
                   WHERE     hl_shift.lookup_type = 'US_SHIFTS'
                         AND hl_shift.lookup_code = hsk_shift.segment5
                         AND hsk_shift.soft_coding_keyflex_id = har.new_value
                         AND hl_shift.application_id =
                                fa_shift.application_id
                         AND fa_shift.application_short_name = 'PER')
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID'
              THEN
                 (SELECT org.name
                    FROM hr_soft_coding_keyflex flx,
                         hr_all_organization_units_tl org
                   WHERE     org.organization_id = flx.segment1
                         AND org.language = USERENV ('LANG')
                         AND flx.soft_coding_keyflex_id = har.new_value)
              WHEN 'PER_ALL_ASSIGNMENTS_F.SOFT_CODING_KEYFLEX_ID_W'
              THEN
                 (SELECT (CASE
                             WHEN LENGTH (NVL (hs.segment8, pjw.wc_code)) < 4
                             THEN
                                0 || NVL (hs.segment8, pjw.wc_code)
                             ELSE
                                NVL (hs.segment8, pjw.wc_code)
                          END)
                    FROM per_all_assignments_f paaf,
                         hr_soft_coding_keyflex hs,
                         pay_job_wc_code_usages pjw,
                         hr_locations_all loc,
                         per_addresses adr
                   WHERE     paaf.job_id = pjw.job_id
                         AND paaf.soft_coding_keyflex_id =
                                hs.soft_coding_keyflex_id
                         AND paaf.location_id = loc.location_id
                         AND paaf.person_id = adr.person_id(+)
                         AND adr.date_to(+) IS NULL
                         AND adr.primary_flag(+) = 'Y'
                         AND paaf.assignment_type = 'E'    -- Added for CC5609
                         AND paaf.primary_flag = 'Y'       -- Added for CC5609
                         AND DECODE (
                                INSTR (loc.location_code, 'Home Office'),
                                0, loc.region_2,
                                adr.region_2) = pjw.state_code
                         AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                 AND paaf.effective_end_date
                         AND paaf.person_id = har.person_id
                         AND hs.soft_coding_keyflex_id = har.new_value)
              WHEN 'PER_ALL_PEOPLE_F.SEX'
              THEN
                 DECODE (har.new_value,
                         'M', 'Male',
                         'F', 'Female',
                         'Unknown')
              WHEN 'PER_ALL_PEOPLE_F.MARITAL_STATUS'
              THEN
                 (SELECT hrl.meaning
                    FROM hr_lookups hrl
                   WHERE     hrl.lookup_type = 'MAR_STATUS'
                         AND hrl.lookup_code = har.new_value
                         AND NVL (hrl.enabled_flag, 'N') = 'Y')
              WHEN 'PER_PAY_PROPOSALS.PROPOSAL_REASON'
              THEN
                 (SELECT hrl.meaning
                    FROM hr_lookups hrl
                   WHERE     hrl.lookup_type = 'PROPOSAL_REASON'
                         AND hrl.lookup_code = har.new_value
                         AND NVL (hrl.enabled_flag, 'N') = 'Y')
              WHEN 'PER_ALL_ASSIGNMENTS_F.FREQUENCY'
              THEN
                 (SELECT hrl.meaning
                    FROM hr_lookups hrl
                   WHERE     hrl.lookup_type = 'FREQUENCY'
                         AND hrl.lookup_code = har.new_value
                         AND NVL (hrl.enabled_flag, 'N') = 'Y')
              WHEN 'PER_PAY_PROPOSALS.PROPOSED_SALARY_RATE'
              THEN
                 (SELECT TO_CHAR (
                            ROUND (
                                 DECODE (
                                    bas.pay_basis,
                                    'ANNUAL', har.new_value,
                                    'HOURLY',   har.new_value
                                              * paaf.normal_hours
                                              * 52,
                                    'PERIOD',   har.new_value
                                              * bas.pay_annualization_factor,
                                    har.new_value)
                               / DECODE (pay.period_type,
                                         'Bi-Week', 26,
                                         'Calendar Month', 12,
                                         'Semi-Month', 24,
                                         'Week', 52,
                                         1),
                               2))
                            ans
                    FROM per_all_assignments_f paaf,
                         per_pay_bases bas,
                         pay_all_payrolls_f pay
                   WHERE     paaf.pay_basis_id = bas.pay_basis_id
                         AND paaf.payroll_id = pay.payroll_id
                         AND paaf.assignment_type = 'E'    -- Added for CC5609
                         AND paaf.primary_flag = 'Y'       -- Added for CC5609
                         AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                                 AND paaf.effective_end_date
                         AND paaf.person_id = har.person_id)
              ELSE
                 har.new_value
           END)
             new_value                             --,har.new_value new_value1
                      ,
          har.last_updated_date,
          har.effective_date,
          har.record_id,
          har.request_id,
          har.person_id,
          har.country,
          (SELECT ter.territory_short_name
             FROM fnd_territories_tl ter
            WHERE     ter.territory_code = har.country
                  AND ter.language = USERENV ('LANG'))
             country_name,
          DECODE (har.run_type,  'D', 'Draft',  'F', 'Final',  NULL) run_type --,har.run_type
                                                                             ,
          har.prior_report_key,
          har.location_id,
          har.gre_id,
          har.date_from,
          har.date_to,
          har.payroll_id,
          (SELECT pay.payroll_name
             FROM pay_payrolls_f pay
            WHERE pay.payroll_id = har.payroll_id)
             payroll_name,
          har.created_by,
          har.creation_date,
          har.last_update_date,
          har.last_updated_by,
          har.last_update_login
     FROM xx_hr_audit_rpt har;
