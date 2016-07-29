DROP PACKAGE BODY APPS.XX_HR_CENSUS_INTERFACE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_CENSUS_INTERFACE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-MAY-2013
 File Name     : XXHREMPCNSINTF.pkb
 Description   : This script creates the body of the package
                 xx_hr_census_interface_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-MAY-2013 Sharath Babu          Initial development.
 12-SEP-2013 Mou Mukherjee         Added logic for Home State
 04-OCT-2013 Sharath Babu          Modified logic for Work State
 09-Apr-2014 Jaya Maran            Added round function to Base Salary to round it to 2 decimal places
 01-Dec-2014 Jaya Maran            Modified for defect#10447
*/
----------------------------------------------------------------------

   --Procedure to process Data into staging table
   PROCEDURE xx_hr_process_data_stg (
                                      p_eff_date            IN       DATE,
                                      p_request_id          IN       NUMBER,
                                      p_file_name           IN       VARCHAR2
                                     )
   IS
      CURSOR c_census_data
      IS
                SELECT company_id,
                       line_business_code,
                       national_identifier employee_ssn,
                       last_name,
                       first_name,
                       middle_names middle_initial,
                       address_line1,
                       address_line2,
                       city,
                       state,
                       zip_postal_code zip,
                       hire_date,
                       termination_date,
                       adjusted_hire_date,
                       NULL plan_eligibility_date,
                       --base_salary, -- Commented for CC005306
                       ROUND(base_salary,2) base_salary, -- added for CC005306
                       NULL additional_salary,
                       NULL filler1,
                       NULL other_compensation1,
                       NULL other_compensation2,
                       NULL other_compensation3,
                       NULL filler2,
                       hours_per_week,
                       emp_category,
                       location_code,
                       date_of_birth,
                       gender,
                       NULL smoker,
                       NULL filler3,
                       NULL months_per_year_worked,
                       NULL union_member,
                       NULL filler4,
                       NULL pin,
                       payroll_mode,
                       NULL payroll_site,
                       NULL department_code,
                       NULL division_code,
                       occupation_code,
                       other_id,
                       marital_status,
                       NULL cobra,
                       phone_number1,
                       phone_number2,
                       NULL tax_filing_status_code,
                       NULL filler5,
                       NULL vacation_days,
                       NULL filler6,
                       NULL user_defined1,
                       NULL user_defined2,
                       user_defined3,
                       user_defined4,
                       user_defined5,
                       user_defined6,
                       user_defined7,
                       user_defined8,
                       NULL user_defined9,
                       NULL user_defined10,
                       NULL user_defined11,
                       NULL user_defined12,
                       NULL user_defined13,
                       NULL user_defined14,
                       NULL user_defined15,
                       NULL user_defined16,
                       NULL user_defined17,
                       NULL user_defined18,
                       user_defined19,
                       NULL user_defined20,
                       NULL user_defined21,
                       NULL user_defined22,
                       NULL user_defined23,
                       NULL user_defined24,
                       work_state,
                       NULL filler7,
                       email_address email_address_work,
                       NULL email_address_home,
                       termination_reason_code,
                       country country_code,
                       xx_hr_cns_rec_num_seq.nextval record_number,
                       'New' process_code,
                       NULL error_code,
                       p_request_id request_id,
                       p_file_name  file_name,
                       fnd_global.user_id created_by,
                       SYSDATE creation_date,
                       SYSDATE last_update_date,
                       fnd_global.user_id last_updated_by,
                       fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id) last_update_login
                FROM
                ( SELECT NVL(xx_emf_pkg.get_paramater_value('XXHREMPCNSINTF','COMPANY_ID'),223270030) company_id,
                        (  SELECT hou.attribute1
                             FROM hr_organization_units_v hou
                                 ,hr_soft_coding_keyflex flx
                            WHERE hou.attribute_category = 'US'
                              AND hou.organization_id = flx.segment1
                              AND flx.soft_coding_keyflex_id = paaf.soft_coding_keyflex_id) line_business_code,
                        papf.national_identifier,
                        papf.last_name,
                        papf.first_name,
                        papf.middle_names,
                        pa.address_line1,
                        pa.address_line2,
                        pa.town_or_city city,
                        pa.region_2 state,
                        --pa.postal_code zip_postal_code, Commented by Shekhar
                        substr(pa.postal_code,1,5) zip_postal_code, -- Added by Shekhar
                        TO_CHAR (papf.original_date_of_hire, 'MMDDYYYY') hire_date,
                        TO_CHAR (pps.actual_termination_date,'MMDDYYYY') termination_date,
                        TO_CHAR (pps.date_start, 'MMDDYYYY') adjusted_hire_date,
                        DECODE (ppb.pay_basis,
                                              'HOURLY', ppp.proposed_salary_n * paaf.normal_hours * 52,
                                              'ANNUAL', ppp.proposed_salary_n
                               ) base_salary,
                        paaf.normal_hours hours_per_week,
                        paaf.employment_category emp_category,
                        /*(SELECT hl9.meaning
                                         FROM hr_lookups hl9
                                        WHERE hl9.lookup_type = 'EMP_CAT'
                                          AND hl9.lookup_code = paaf.employment_category) emp_category,*/
                        ( SELECT SUBSTR(ppst.user_status,1,1)
                            FROM per_assignment_status_types_tl ppst
                           WHERE ppst.assignment_status_type_id = paaf.assignment_status_type_id
                             AND ppst.LANGUAGE = USERENV ('LANG')) location_code,
                        TO_CHAR (papf.date_of_birth, 'MMDDYYYY') date_of_birth,
                        papf.sex gender,
                        ppay.payroll_name payroll_mode,
                        ppb.NAME occupation_code,
                        papf.employee_number other_id,
                        DECODE (papf.marital_status,
                                NULL, NULL,
                                hl2.meaning
                               ) marital_status,
                    hr_general.get_phone_number (papf.person_id,
                                                   'W1',
                                                   p_eff_date
                                                  ) phone_number1,
                    hr_general.get_phone_number (papf.person_id,
                                                   'H1',
                                                   p_eff_date
                                                     ) phone_number2,
                    hl.location_code user_defined3,
                    haou_hr.NAME user_defined4,
                    pjd.segment1 user_defined5,
                    pjd.segment2 user_defined6,
                     ( SELECT papf_hr_rep.employee_number
                     FROM per_all_people_f papf_hr_rep,
                          per_all_assignments_f paaf_hr_rep,
                          per_assignment_status_types_tl ppst_hr_rep,
                          hr_all_positions_f hpos_hr_rep
                    WHERE papf_hr_rep.person_id = paaf_hr_rep.person_id
                      AND paaf_hr_rep.primary_flag = 'Y'
                      AND paaf_hr_rep.position_id = hpos_hr_rep.position_id(+)
                      AND ppst_hr_rep.assignment_status_type_id =
                                                    paaf_hr_rep.assignment_status_type_id
                      AND ppst_hr_rep.LANGUAGE = USERENV ('LANG')
                      AND ppst_hr_rep.user_status NOT IN
                                ('Terminate Assignment', 'Terminate Appointment', 'End')
                      AND p_eff_date BETWEEN papf_hr_rep.effective_start_date
                                          AND papf_hr_rep.effective_end_date
                      AND p_eff_date BETWEEN paaf_hr_rep.effective_start_date
                                          AND paaf_hr_rep.effective_end_date
                      AND p_eff_date BETWEEN hpos_hr_rep.effective_start_date
                                          AND hpos_hr_rep.effective_end_date
                      AND hpos_hr_rep.position_id = hpos.attribute5) user_defined7,
                    pjd.segment3 user_defined8,
                    ROUND((( TRUNC(SYSDATE)-TRUNC(pps.date_start))*12)/365, 2) user_defined19,
                    --    hl.region_2 work_state, -- Commented by Mou on 12-09-2013
            --DECODE(pa.address_type,'H',pa.region_2,DECODE(paaf.work_at_home,'Y',pa.region_2,hl.region_2))work_state, -- Added by Mou on 12-09-2013 for home state logic
                    DECODE(hl.location_code,NVL(xx_emf_pkg.get_paramater_value('XXHREMPCNSINTF','HOME_LOCATION_CODE'),'US-xx-xx-NA-Home Office'),pa.region_2,hl.region_2) work_state,  --Added by Sharath 04-OCT-13
                    papf.email_address,
                    --pps.leaving_reason termination_reason_code,
                    (SELECT hl9.meaning
               FROM hr_lookups hl9
              WHERE hl9.lookup_type = 'LEAV_REAS'
                        AND hl9.lookup_code = pps.leaving_reason) termination_reason_code,
                    DECODE(pa.country,'US',NULL,pa.country) country
                   FROM per_all_people_f papf,
                        hr_lookups hl2,
                        per_periods_of_service pps,
                        per_addresses pa,
                        hr_locations hl,
                        per_all_assignments_f paaf,
                        hr_all_organization_units haou_hr,
                        per_jobs pj,
                        per_job_definitions pjd,
                        hr_all_positions_f hpos,
                        pay_all_payrolls_f ppay,
                        per_pay_proposals ppp,
                        per_pay_bases ppb
                  WHERE 1 = 1
                    AND p_eff_date BETWEEN papf.effective_start_date AND papf.effective_end_date
                    AND papf.business_group_id = fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID')
                    AND NVL(papf.current_employee_flag, 'N') = 'Y'
                    AND NVL (UPPER (papf.attribute5), 'YES') <> 'NO'
                    AND hl2.lookup_type(+) = 'MAR_STATUS'
                    AND hl2.lookup_code(+) = papf.marital_status
                    AND pps.period_of_service_id = paaf.period_of_service_id
                    AND pps.person_id(+) = papf.person_id
                    --AND pps.actual_termination_date(+) IS NULL
                    AND NVL(pps.actual_termination_date(+),TO_DATE ('31/12/4712','DD/MM/RRRR')) > p_eff_date
                    AND p_eff_date BETWEEN pps.date_start(+) AND NVL (pps.actual_termination_date(+),
                                                                       TO_DATE ('31/12/4712',
                                                                                'DD/MM/RRRR'
                                                                               )
                                                                      )
                    AND pa.person_id(+) = papf.person_id
                    AND pa.primary_flag(+) = 'Y'
                    AND p_eff_date BETWEEN pa.date_from(+) AND NVL (pa.date_to(+),
                                                                     TO_DATE ('31/12/4712',
                                                                              'DD/MM/RRRR'
                                                                             )
                                                                    )
                    AND ppay.payroll_id(+) = paaf.payroll_id
                AND p_eff_date BETWEEN ppay.effective_start_date(+) AND ppay.effective_end_date(+)
                AND hpos.position_id(+) = paaf.position_id
                AND p_eff_date BETWEEN hpos.effective_start_date(+) AND hpos.effective_end_date(+)
                    AND paaf.person_id = papf.person_id
                    AND paaf.assignment_type = 'E'
                    AND paaf.primary_flag = 'Y'
                    AND p_eff_date BETWEEN paaf.effective_start_date AND paaf.effective_end_date
                    AND paaf.location_id = hl.location_id(+)
                    AND paaf.employment_category IN ('FR','PR')                    
                    AND hl.country = 'US' 
                    AND pa.country = 'US'  -- Added by Shekhar
                    AND pj.job_id(+) = paaf.job_id
                    AND p_eff_date BETWEEN pj.date_from(+) AND NVL (pj.date_to(+),
                                                                     TO_DATE ('31/12/4712',
                                                                              'DD/MM/RRRR'
                                                                             )
                                                                    )
                    AND pj.job_definition_id = pjd.job_definition_id(+)
                    AND haou_hr.organization_id = paaf.organization_id
                    AND paaf.assignment_id = ppp.assignment_id(+)
                    AND p_eff_date BETWEEN ppp.change_date(+) AND NVL (ppp.date_to(+),
                                                                        TO_DATE ('31/12/4712',
                                                                                 'DD/MM/RRRR'
                                                                                )
                                                                       )
                    AND ppp.approved(+) = 'Y'
                    AND paaf.pay_basis_id = ppb.pay_basis_id(+)
                 UNION
                 SELECT NVL(xx_emf_pkg.get_paramater_value('XXHREMPCNSINTF','COMPANY_ID'),223270030) company_id,
                        (  SELECT hou.attribute1
                             FROM hr_organization_units_v hou
                                 ,hr_soft_coding_keyflex flx
                            WHERE hou.attribute_category = 'US'
                              AND hou.organization_id = flx.segment1
                              AND flx.soft_coding_keyflex_id = paaf.soft_coding_keyflex_id) line_business_code,
                        papf.national_identifier,
                        papf.last_name,
                        papf.first_name,
                        papf.middle_names,
                        pa.address_line1,
                        pa.address_line2,
                        pa.town_or_city city,
                        pa.region_2 state,
                      --pa.postal_code zip_postal_code, Commented by Shekhar
                        substr(pa.postal_code,1,5) zip_postal_code, -- Added by Shekhar
                        TO_CHAR (papf.original_date_of_hire, 'MMDDYYYY') hire_date,
                        TO_CHAR (pps.actual_termination_date,'MMDDYYYY') termination_date,
                        TO_CHAR (pps.date_start, 'MMDDYYYY') adjusted_hire_date,
                        DECODE (ppb.pay_basis,
                                              'HOURLY', ppp.proposed_salary_n * paaf.normal_hours * 52,
                                              'ANNUAL', ppp.proposed_salary_n
                               ) base_salary,
                        paaf.normal_hours hours_per_week,
                        paaf.employment_category emp_category,
                        /*(SELECT hl9.meaning
                                         FROM hr_lookups hl9
                                        WHERE hl9.lookup_type = 'EMP_CAT'
                                          AND hl9.lookup_code = paaf.employment_category) emp_category,*/
                        ( SELECT SUBSTR(ppst.user_status,1,1)
                            FROM per_assignment_status_types_tl ppst
                           WHERE ppst.assignment_status_type_id = paaf.assignment_status_type_id
                             AND ppst.LANGUAGE = USERENV ('LANG')) location_code,
                        TO_CHAR (papf.date_of_birth, 'MMDDYYYY') date_of_birth,
                        papf.sex gender,
                        ppay.payroll_name payroll_mode,
                        ppb.NAME occupation_code,
                        papf.employee_number other_id,
                        DECODE (papf.marital_status,
                                NULL, NULL,
                                hl2.meaning
                               ) marital_status,
                    hr_general.get_phone_number (papf.person_id,
                                                   'W1',
                                                   p_eff_date
                                                  ) phone_number1,
                    hr_general.get_phone_number (papf.person_id,
                                                   'H1',
                                                   p_eff_date
                                                     ) phone_number2,
                    hl.location_code user_defined3,
                    haou_hr.NAME user_defined4,
                    pjd.segment1 user_defined5,
                    pjd.segment2 user_defined6,
                     ( SELECT papf_hr_rep.employee_number
                     FROM per_all_people_f papf_hr_rep,
                          per_all_assignments_f paaf_hr_rep,
                          per_assignment_status_types_tl ppst_hr_rep,
                          hr_all_positions_f hpos_hr_rep
                    WHERE papf_hr_rep.person_id = paaf_hr_rep.person_id
                      AND paaf_hr_rep.primary_flag = 'Y'
                      AND paaf_hr_rep.position_id = hpos_hr_rep.position_id(+)
                      AND ppst_hr_rep.assignment_status_type_id =
                                                    paaf_hr_rep.assignment_status_type_id
                      AND ppst_hr_rep.LANGUAGE = USERENV ('LANG')
                      AND ppst_hr_rep.user_status NOT IN
                                ('Terminate Assignment', 'Terminate Appointment', 'End')
                      AND pps.actual_termination_date BETWEEN papf_hr_rep.effective_start_date
                                          AND papf_hr_rep.effective_end_date
                      AND pps.actual_termination_date BETWEEN paaf_hr_rep.effective_start_date
                                          AND paaf_hr_rep.effective_end_date
                      AND pps.actual_termination_date BETWEEN hpos_hr_rep.effective_start_date
                                          AND hpos_hr_rep.effective_end_date
                      AND hpos_hr_rep.position_id = hpos.attribute5) user_defined7,
                    pjd.segment3 user_defined8,
                    ROUND((( TRUNC(SYSDATE)-TRUNC(pps.date_start))*12)/365, 2) user_defined19,
                  --  hl.region_2 work_state,-- Commented by Mou on 12-09-2013
            --DECODE(pa.address_type,'H',pa.region_2,DECODE(paaf.work_at_home,'Y',pa.region_2,hl.region_2))work_state, -- Added by Mou on 12-09-2013 for home state logic
                    DECODE(hl.location_code,NVL(xx_emf_pkg.get_paramater_value('XXHREMPCNSINTF','HOME_LOCATION_CODE'),'US-xx-xx-NA-Home Office'),pa.region_2,hl.region_2) work_state,  --Added by Sharath 04-OCT-13
                    papf.email_address,
                    --pps.leaving_reason termination_reason_code,
                    (SELECT hl9.meaning
               FROM hr_lookups hl9
              WHERE hl9.lookup_type = 'LEAV_REAS'
                        AND hl9.lookup_code = pps.leaving_reason) termination_reason_code,
                    DECODE(pa.country,'US',NULL,pa.country) country
                    FROM per_all_people_f papf,
                        hr_lookups hl2,
                        per_periods_of_service pps,
                        per_addresses pa,
                        hr_locations hl,
                        per_all_assignments_f paaf,
                        hr_all_organization_units haou_hr,
                        per_jobs pj,
                        per_job_definitions pjd,
                        hr_all_positions_f hpos,
                        pay_all_payrolls_f ppay,
                        per_pay_proposals ppp,
                        per_pay_bases ppb
                  WHERE 1 = 1
                    AND pps.actual_termination_date BETWEEN papf.effective_start_date AND papf.effective_end_date
                    AND papf.business_group_id = fnd_profile.VALUE ('PER_BUSINESS_GROUP_ID')
                    AND NVL (UPPER (papf.attribute5), 'YES') <> 'NO'
                    AND hl2.lookup_type(+) = 'MAR_STATUS'
                    AND hl2.lookup_code(+) = papf.marital_status
                    AND pps.period_of_service_id = paaf.period_of_service_id
                    AND pps.person_id(+) = papf.person_id
                    AND pps.actual_termination_date BETWEEN (p_eff_date)-60 AND p_eff_date
                    AND pa.person_id(+) = papf.person_id
                    AND pa.primary_flag(+) = 'Y'
                    AND pps.actual_termination_date BETWEEN pa.date_from AND NVL (pa.date_to,
                                                                     TO_DATE ('31/12/4712',
                                                                              'DD/MM/RRRR'
                                                                             )
                                                                    )
                    AND ppay.payroll_id(+) = paaf.payroll_id
                AND pps.actual_termination_date BETWEEN ppay.effective_start_date AND ppay.effective_end_date
                AND hpos.position_id(+) = paaf.position_id
                AND pps.actual_termination_date BETWEEN hpos.effective_start_date AND hpos.effective_end_date
                    AND paaf.person_id = papf.person_id
                    AND paaf.primary_flag = 'Y'
                    AND pps.actual_termination_date BETWEEN paaf.effective_start_date AND paaf.effective_end_date
                    AND paaf.location_id = hl.location_id(+)
                    AND paaf.employment_category IN ('FR','PR')
                    AND hl.country = 'US'     
                    AND pa.country = 'US' -- Added by Shekhar
                    AND pj.job_id(+) = paaf.job_id
                    AND pps.actual_termination_date BETWEEN pj.date_from AND NVL (pj.date_to,
                                                                     TO_DATE ('31/12/4712',
                                                                              'DD/MM/RRRR'
                                                                             )
                                                                    )
                    AND pj.job_definition_id = pjd.job_definition_id(+)
                    AND haou_hr.organization_id = paaf.organization_id
                    AND paaf.assignment_id = ppp.assignment_id(+)
                    AND pps.actual_termination_date BETWEEN ppp.change_date AND NVL (ppp.date_to,
                                                                        TO_DATE ('31/12/4712',
                                                                                 'DD/MM/RRRR'
                                                                                )
                                                                       )
                    AND ppp.approved(+) = 'Y'
                    AND paaf.pay_basis_id = ppb.pay_basis_id(+)
            );

      x_census_data  g_census_data_tbl_type;
   BEGIN
      BEGIN
         OPEN c_census_data;
         LOOP
         FETCH c_census_data
         BULK COLLECT INTO x_census_data LIMIT 1000;
         FORALL i IN 1 .. x_census_data.COUNT
        INSERT INTO xx_hr_emp_census_stg
        VALUES x_census_data (i);
        EXIT WHEN c_census_data%NOTFOUND;
     END LOOP;
     CLOSE c_census_data;
         COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_rec_err;
         g_errmsg := 'Error while bulk insert'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                       xx_emf_cn_pkg.cn_tech_error,
                       xx_emf_cn_pkg.cn_exp_unhand,
                          'Unexpected error while bulk insert',
                           SQLERRM);
      END;
      EXCEPTION
      WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_prc_err;
         g_errmsg := 'Error in xx_hr_process_data_stg'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                       xx_emf_cn_pkg.cn_tech_error,
                       xx_emf_cn_pkg.cn_exp_unhand,
                          'Unexpected error in xx_hr_process_data_stg',
                           SQLERRM);
   END xx_hr_process_data_stg;

   --Procedure to appy translation rules
   PROCEDURE xx_hr_trnsln_rules ( p_request_id  IN  NUMBER
                                 )
   IS

   CURSOR c_census_data
   IS
   SELECT stg.*
     FROM xx_hr_emp_census_stg stg
    WHERE request_id = p_request_id;

    x_emp_cat        VARCHAR2(100);
    x_payroll_mode   VARCHAR2(100);
    x_occp_code      VARCHAR2(100);
    x_marital_status VARCHAR2(100);
    x_ter_code       VARCHAR2(100);

   --Function to fetch translation value
   FUNCTION xx_hr_get_trnlsn_value( p_trnsln_type IN VARCHAR2,
                                    p_old_value   IN VARCHAR2,
                                    p_date_effec  IN DATE)
   RETURN VARCHAR2
   AS
      x_new_value   VARCHAR2 (100);
   BEGIN
      SELECT DISTINCT new_value
        INTO x_new_value
        FROM xx_hr_trnsln_rules_tbl
       WHERE trnsln_type = p_trnsln_type
         AND old_value    = p_old_value
         AND p_date_effec BETWEEN NVL(effective_start_date,sysdate) AND nvl(effective_end_date,sysdate+1);

      RETURN x_new_value;

   EXCEPTION
      WHEN NO_DATA_FOUND   THEN
      RETURN p_old_value;
      WHEN OTHERS   THEN
      RETURN p_old_value;
   END xx_hr_get_trnlsn_value;

   BEGIN

      FOR r_census_data IN c_census_data
      LOOP
         x_emp_cat := xx_hr_get_trnlsn_value ('EMPLOYMENT_CATEGORY',
                                              r_census_data.emp_category,
                                              SYSDATE );

         x_payroll_mode := xx_hr_get_trnlsn_value ('PAYROLL_MODE',
                                                    r_census_data.payroll_mode,
                                                    SYSDATE );

         x_occp_code := xx_hr_get_trnlsn_value ('OCCUPATION_CODE',
                                                 r_census_data.occupation_code,
                                                 SYSDATE );

         x_marital_status := xx_hr_get_trnlsn_value ('MARITAL_STATUS',
                                                      r_census_data.marital_status,
                                                      SYSDATE );

         x_ter_code := xx_hr_get_trnlsn_value ('TERM_REASON_CODE',
                                                r_census_data.termination_reason_code,
                                                SYSDATE );
        --Update stg table with translation values
        UPDATE xx_hr_emp_census_stg
           SET emp_category = x_emp_cat
              ,payroll_mode = x_payroll_mode
              ,occupation_code = x_occp_code
              ,marital_status = x_marital_status
              ,termination_reason_code = x_ter_code
        WHERE record_number = r_census_data.record_number
          AND request_id = r_census_data.request_id;

      END LOOP;
      COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_prc_err;
         g_errmsg := 'Error in xx_hr_trnsln_rules'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                       xx_emf_cn_pkg.cn_tech_error,
                       xx_emf_cn_pkg.cn_exp_unhand,
                          'Unexpected error in xx_hr_trnsln_rules',
                           SQLERRM);
   END xx_hr_trnsln_rules;

   --Function to format phone number
   FUNCTION xx_hr_format_phone_num( p_phone_num IN VARCHAR2 )
   RETURN VARCHAR2
   IS
      x_phone_number VARCHAR2(50);
   BEGIN
      IF p_phone_num IS NOT NULL THEN
         x_phone_number := regexp_replace(p_phone_num,'[^[:alnum:]]');
         x_phone_number := SUBSTR(x_phone_number, GREATEST (-10, -length(x_phone_number)), 10);
      ELSE
         x_phone_number := NULL;
      END IF;
      RETURN x_phone_number;
      EXCEPTION
      WHEN OTHERS THEN
          x_phone_number := NULL;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Errror in xx_hr_format_phone_num: ' ||p_phone_num);
          xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                        xx_emf_cn_pkg.cn_tech_error,
                        xx_emf_cn_pkg.cn_exp_unhand,
                        'Unexpected error in xx_hr_format_phone_num',
                            SQLERRM);
          RETURN x_phone_number;
   END xx_hr_format_phone_num;

   --Procedure for file generation
   PROCEDURE xx_hr_file_generation (
                                    p_file_name  IN VARCHAR2,
                                    p_data_dir   IN VARCHAR2,
                                    p_hdr_data   IN VARCHAR2,
                                    p_request_id IN NUMBER
                                   )
   IS

      CURSOR c_census_stg
      IS
      SELECT LPAD(stg.company_id,9,' ')||
             RPAD(NVL(stg.line_business_code,' '),3,' ')||
             RPAD(NVL(REPLACE(stg.employee_ssn,'-',''),' '),9,' ')||
             RPAD(NVL(stg.last_name,' '),20,' ')||
             RPAD(NVL(stg.first_name,' '),20,' ')||
             RPAD(NVL(stg.middle_initial,' '),1,' ')||
             RPAD(NVL(stg.address_line1,' '),30,' ')||
             RPAD(NVL(stg.address_line2,' '),30,' ')||
             RPAD(NVL(stg.city,' '),20,' ')||
             RPAD(NVL(stg.state,' '),2,' ')||
             RPAD(NVL(stg.zip,' '),9,' ')||            
             RPAD(NVL(stg.hire_date,' '),8,' ')||
             RPAD(NVL(stg.termination_date,' '),8,' ')||
             RPAD(NVL(stg.adjusted_hire_date,' '),8,' ')||
             RPAD(NVL(stg.plan_eligibility_date,' '),8,' ')||
             --LPAD(NVL(stg.base_salary,' '),11,' ')||
             DECODE(stg.base_salary,NULL,'00000000000',LPAD(stg.base_salary,11,' '))||
             DECODE(stg.additional_salary,NULL,'           ',LPAD(stg.additional_salary,11,' '))||
             --LPAD(NVL(stg.additional_salary,' '),11,' ')||
             RPAD(NVL(stg.filler1,' '),33,' ')||
             RPAD(NVL(stg.other_compensation1,' '),11,' ')||
             RPAD(NVL(stg.other_compensation2,' '),11,' ')||
             RPAD(NVL(stg.other_compensation3,' '),11,' ')||
             RPAD(NVL(stg.filler2,' '),88,' ')||
             --LPAD(NVL(stg.hours_per_week,' '),5,' ')||
             DECODE(stg.hours_per_week,NULL,'     ',RPAD(stg.hours_per_week,5,' '))||
             RPAD(NVL(stg.emp_category,' '),2,' ')||
             RPAD(NVL(stg.location_code,' '),2,' ')||
             RPAD(NVL(stg.date_of_birth,' '),8,' ')||
             RPAD(NVL(stg.gender,' '),1,' ')||
             RPAD(NVL(stg.smoker,' '),1,' ')||
             RPAD(NVL(stg.filler3,' '),24,' ')||
             RPAD(NVL(stg.months_per_year_worked,' '),2,' ')||
             RPAD(NVL(stg.union_member,' '),1,' ')||
             RPAD(NVL(stg.filler4,' '),12,' ')||
             RPAD(NVL(stg.pin,' '),20,' ')||
             RPAD(NVL(stg.payroll_mode,' '),1,' ')||
             RPAD(NVL(stg.payroll_site,' '),2,' ')||
             RPAD(NVL(stg.department_code,' '),5,' ')||
             RPAD(NVL(stg.division_code,' '),3,' ')||
             RPAD(NVL(stg.occupation_code,' '),2,' ')||
             RPAD(NVL(stg.other_id,' '),10,' ')||
             RPAD(NVL(stg.marital_status,' '),1,' ')||
             RPAD(NVL(stg.cobra,' '),1,' ')||
             RPAD(NVL(xx_hr_census_interface_pkg.xx_hr_format_phone_num(stg.phone_number2),' '),10,' ')|| --RPAD(NVL(REPLACE(REPLACE(stg.phone_number1,'-',''),' ',''),' '),10,' ')||
             RPAD(NVL(xx_hr_census_interface_pkg.xx_hr_format_phone_num(stg.phone_number1),' '),10,' ')|| --RPAD(NVL(REPLACE(REPLACE(stg.phone_number2,'-',''),' ',''),' '),10,' ')||
             RPAD(NVL(stg.tax_filing_status_code,' '),1,' ')||
             RPAD(NVL(stg.filler5,' '),18,' ')||
             RPAD(NVL(stg.vacation_days,' '),3,' ')||
             RPAD(NVL(stg.filler6,' '),8,' ')||
             RPAD(NVL(stg.user_defined1,' '),30,' ')||
             RPAD(NVL(stg.user_defined2,' '),30,' ')||
             RPAD(NVL(stg.user_defined3,' '),30,' ')||
             RPAD(NVL(stg.user_defined4,' '),30,' ')||
             RPAD(NVL(stg.user_defined5,' '),30,' ')||
             RPAD(NVL(stg.user_defined6,' '),30,' ')||
             RPAD(NVL(stg.user_defined7,' '),30,' ')||
             RPAD(NVL(stg.user_defined8,' '),30,' ')||
             RPAD(NVL(stg.user_defined9,' '),30,' ')||
             RPAD(NVL(stg.user_defined10,' '),30,' ')||
             RPAD(NVL(stg.user_defined11,' '),30,' ')||
             RPAD(NVL(stg.user_defined12,' '),30,' ')||
             RPAD(NVL(stg.user_defined13,' '),8,' ')||
             RPAD(NVL(stg.user_defined14,' '),8,' ')||
             RPAD(NVL(stg.user_defined15,' '),8,' ')||
             RPAD(NVL(stg.user_defined16,' '),8,' ')||
             RPAD(NVL(stg.user_defined17,' '),8,' ')||
             RPAD(NVL(stg.user_defined18,' '),8,' ')||
             RPAD(NVL(stg.user_defined19,' '),9,' ')||
             RPAD(NVL(stg.user_defined20,' '),9,' ')||
             RPAD(NVL(stg.user_defined21,' '),9,' ')||
             RPAD(NVL(stg.user_defined22,' '),9,' ')||
             RPAD(NVL(stg.user_defined23,' '),9,' ')||
             RPAD(NVL(stg.user_defined24,' '),9,' ')||
             RPAD(NVL(stg.work_state,' '),2,' ')||
             RPAD(NVL(stg.filler7,' '),148,' ')||
             RPAD(NVL(stg.email_address_work,' '),128,' ')||
             RPAD(NVL(stg.email_address_home,' '),128,' ')||
             RPAD(NVL(stg.termination_reason_code,' '),8,' ')||
             RPAD(NVL(stg.country_code,' '),8,' ') file_data
             ,stg.record_number
             ,stg.request_id
        FROM xx_hr_emp_census_stg stg
       WHERE request_id = p_request_id;

      x_file_type       UTL_FILE.file_type;
      x_data_dir        VARCHAR2(100);
      x_file_name       VARCHAR2 (500);
      x_return_code     NUMBER := 0;
      x_error_msg       VARCHAR2(2000);
      x_rec_count       NUMBER := 0;
      x_exists          BOOLEAN;
      x_file_length     NUMBER;
      x_size            NUMBER;
      x_file_data       VARCHAR2(32767);

   BEGIN
      --Logic for utl file generation
      x_file_name := p_file_name;
      x_data_dir  := p_data_dir;  --'/u10/app/oracle/DEVL/inst/apps/DEVL_usdsapp02/appltmp';

      -- opening the file
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file name: '||x_file_name);
         x_file_type := UTL_FILE.fopen (x_data_dir, x_file_name, 'W', 32767);
      EXCEPTION
         WHEN UTL_FILE.invalid_path THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Invalid Path for File :' || x_file_name;
         WHEN UTL_FILE.invalid_filehandle THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  :=  'File handle is invalid for File :' || x_file_name;
         WHEN UTL_FILE.write_error THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'Unable to write the File :' || x_file_name;
         WHEN UTL_FILE.invalid_operation THEN
                x_return_code := xx_emf_cn_pkg.cn_prc_err;
                x_error_msg  := 'File could not be opened for writting:' || x_file_name;
         WHEN UTL_FILE.invalid_maxlinesize THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'File ' || x_file_name;
         WHEN UTL_FILE.access_denied THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg  := 'Access denied for File :' || x_file_name;
          WHEN OTHERS THEN
                  x_return_code := xx_emf_cn_pkg.cn_prc_err;
                  x_error_msg   := x_file_name || SQLERRM;
      END;
      g_retcode := x_return_code;
      g_errmsg := x_error_msg;

      IF NVL(x_return_code,0) = 0 THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'file opened');
         x_rec_count := 0;
         FOR r_census_stg IN c_census_stg
         LOOP
         BEGIN
            x_file_data :=  r_census_stg.file_data;

            IF x_rec_count = 0 THEN
               --UTL_FILE.put_line (x_file_type, p_hdr_data);
               UTL_FILE.put_line (x_file_type, x_file_data);
               x_rec_count := x_rec_count + 1;
            ELSE
               UTL_FILE.put_line (x_file_type, x_file_data);
               x_rec_count := x_rec_count + 1;
            END IF;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'x_file_data :'||x_file_data);
         EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,'File Write Error',SQLERRM );
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Cannot write the record details to file');
            x_error_msg := SUBSTR(SQLERRM,1,250);
            x_return_code := xx_emf_cn_pkg.CN_PRC_ERR;
            UPDATE xx_hr_emp_census_stg
               SET error_code = xx_emf_cn_pkg.cn_rec_err
                  ,process_code = 'File Writing Error'
             WHERE request_id = r_census_stg.request_id
               AND record_number = r_census_stg.record_number;
            COMMIT;
         END;
         END LOOP;
      END IF;
      UTL_FILE.fgetattr ( x_data_dir
                         ,x_file_name
                         ,x_exists
                         ,x_file_length
                         ,x_size);
      IF x_exists THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_file_name||' File exits in Directory '||x_data_dir);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Total Number of Records :'||x_rec_count);
      ELSE
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'NO File exits in Directory');
      END IF;
      IF UTL_FILE.is_open(x_file_type) THEN
         UTL_FILE.fclose(x_file_type);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_prc_err;
         g_errmsg := 'Error in xx_hr_file_generation'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Writing File: ' ||SQLERRM);
         xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW,
                          xx_emf_cn_pkg.CN_TECH_ERROR,
                          xx_emf_cn_pkg.CN_EXP_UNHAND,
                          'Unexpected error in xx_hr_file_generation',
                           SQLERRM);
         UTL_FILE.fclose(x_file_type);

   END xx_hr_file_generation;
   
   PROCEDURE send_ben_file_email(p_file_name IN VARCHAR2
                           ,p_data_dir   IN VARCHAR2
                           ,x_return_code  OUT  NUMBER
                           ,x_error_msg    OUT  VARCHAR2)                           
    IS                           

        CURSOR   c_mail
    IS
     SELECT  description
       FROM  fnd_lookup_values_vl
      WHERE  lookup_type = 'INTG_MERCER_FILE_EMAIL_LKP'
        AND  NVL(enabled_flag,'X')='Y'
        AND  LOOKUP_CODE=1
        AND  trunc(SYSDATE) BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);
        
     x_to_mail         VARCHAR2(1000);
     x_subject         VARCHAR2(60);
     x_message         VARCHAR2(60);
     x_from            VARCHAR2(60);
     x_bcc_name        VARCHAR2(60);
     x_cc_name         VARCHAR2(60);
        
    BEGIN
        x_subject:='Benefits File'; 
        x_message := 'Please find attached the Benefits file';
        x_from := 'Integralifesciences@integralife.com';
        
        
        FOR mail_rec IN c_mail LOOP
           x_to_mail := x_to_mail ||mail_rec.description;
        END LOOP;
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'------------------- Benefits File Mailing   ------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_from      -> '||x_from);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_mail   -> '||x_to_mail);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_subject   -> '||x_subject);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_message   -> '||x_message);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_to_dir    -> '||p_data_dir);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'x_file_name -> '||p_file_name);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
        
        
         IF x_to_mail IS NOT NULL THEN
           BEGIN
             xx_intg_mail_util_pkg.send_mail_attach( p_from_name        => x_from
                                                    ,p_to_name          => x_to_mail
                                                    ,p_cc_name          => x_cc_name
                                                    ,p_bc_name          => x_bcc_name
                                                    ,p_subject          => x_subject
                                                    ,p_message          => x_message
                                                    ,p_oracle_directory => p_data_dir
                                                    ,p_binary_file      => p_file_name);
           EXCEPTION
              WHEN OTHERS THEN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
              x_return_code := xx_emf_cn_pkg.cn_rec_warn;
              x_error_msg   := 'Error in mailing error file';
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,x_error_msg);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'-------------------------------------------------------');
           END;
        END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                 x_error_msg   := 'Procedure - write_lrn_file ->' || SQLERRM;
                 x_return_code := xx_emf_cn_pkg.cn_prc_err;
      END send_ben_file_email;           

   --Procedure to get record count
   PROCEDURE update_record_count(p_request_id IN NUMBER)
   IS
      CURSOR c_get_total_cnt
      IS
      SELECT COUNT (1) total_count
        FROM xx_hr_emp_census_stg
       WHERE request_id = p_request_id;

      CURSOR c_get_error_cnt
      IS
      SELECT COUNT (1) error_count
        FROM xx_hr_emp_census_stg
       WHERE request_id = p_request_id
         AND error_code = xx_emf_cn_pkg.cn_rec_err;

      CURSOR c_get_warning_cnt
      IS
      SELECT COUNT (1) warn_count
        FROM xx_hr_emp_census_stg
       WHERE request_id = p_request_id
         AND error_code = xx_emf_cn_pkg.cn_rec_warn;

      CURSOR c_get_success_cnt
      IS
      SELECT COUNT (1) success_count
        FROM xx_hr_emp_census_stg
       WHERE request_id = p_request_id
         AND NVL(error_code,xx_emf_cn_pkg.cn_success) = xx_emf_cn_pkg.cn_success;

      x_total_cnt     NUMBER;
      x_error_cnt     NUMBER := 0;
      x_warn_cnt      NUMBER := 0;
      x_success_cnt   NUMBER := 0;

   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,'In update_record_count ');
      OPEN c_get_total_cnt;
      FETCH c_get_total_cnt
      INTO x_total_cnt;
      CLOSE c_get_total_cnt;

      OPEN c_get_error_cnt;
      FETCH c_get_error_cnt
      INTO x_error_cnt;
      CLOSE c_get_error_cnt;

      OPEN c_get_warning_cnt;
      FETCH c_get_warning_cnt
      INTO x_warn_cnt;
      CLOSE c_get_warning_cnt;

      OPEN c_get_success_cnt;
      FETCH c_get_success_cnt
      INTO x_success_cnt;
      CLOSE c_get_success_cnt;

      xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                  p_success_recs_cnt      => x_success_cnt,
                                  p_warning_recs_cnt      => x_warn_cnt,
                                  p_error_recs_cnt        => x_error_cnt
                                 );
   EXCEPTION
      WHEN OTHERS THEN
      g_retcode := xx_emf_cn_pkg.cn_prc_err;
      g_errmsg := 'Error in update_record_count'||SQLERRM;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand,
                           'Unexpected error in update_record_count',
                           SQLERRM
                       );
   END update_record_count;

   --Procedure to fetch process param values
   PROCEDURE xx_hr_get_process_param_val( p_file_prefix OUT VARCHAR2,
                                          p_file        OUT VARCHAR2,
                                          p_utl_dir     OUT VARCHAR2,
                                          p_file_ext    OUT VARCHAR2
                                        )
   IS
      x_process_name VARCHAR2(25) := 'XXHREMPCNSINTF';
   BEGIN
      --Fetch File Pre fix value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'FILE_PREFIX',
                                                  p_file_prefix
                                                );
      --Fetch File name value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'FILE_NAME',
                                                  p_file
                                                );
      --Fetch utl directory value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'UTL_DIRECTORY',
                                                  p_utl_dir
                                                );
      --Fetch File extension value from process setup
      xx_intg_common_pkg.get_process_param_value( x_process_name,
                                                 'FILE_EXTENSION',
                                                  p_file_ext
                                                );

      EXCEPTION
         WHEN OTHERS THEN
         g_retcode := xx_emf_cn_pkg.cn_prc_err;
         g_errmsg := 'Error in xx_hr_get_process_param_val'||SQLERRM;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||g_retcode||' Error: '||g_errmsg);
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand,
                              'Unexpected error in xx_hr_get_process_param_val',
                              SQLERRM
                             );
   END xx_hr_get_process_param_val;

   --Main Procedure
   PROCEDURE main (
                    errbuf                OUT      VARCHAR2,
                    retcode               OUT      VARCHAR2,
                    p_effec_date          IN       VARCHAR2,
                    p_file_name           IN       VARCHAR2,
                    p_file_reprocess      IN       VARCHAR2,
                    p_dummy1              IN       VARCHAR2,
                    p_request_id          IN       NUMBER
                   )
   IS
      x_hdr_data     VARCHAR2(32767);
      x_error_code   NUMBER;
      x_request_id   NUMBER;
      x_utl_dir      VARCHAR2(100);
      x_file_name    VARCHAR2(50);
      x_file         VARCHAR2(50);
      x_file_prefix  VARCHAR2(50);
      x_file_ext     VARCHAR2(10);
      x_effec_date   DATE;
      
      x_ret_code           NUMBER :=0;
      x_err_msg            VARCHAR2(3000);

   BEGIN
     --Main Procedure
      BEGIN
         retcode := xx_emf_cn_pkg.cn_success;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Before Setting Environment');
         -- Set the environment
         x_error_code := xx_emf_pkg.set_env;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE xx_emf_pkg.g_e_env_not_set;
      END;
      g_retcode := xx_emf_cn_pkg.cn_success;
      x_request_id := fnd_global.conc_request_id;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********************Program Parameters****************');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Effective Date: '||p_effec_date);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Name: '||p_file_name);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Reprocess: '||p_file_reprocess);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Reprocess Request Id: '||p_request_id);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'******************************************************');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_request_id: '||x_request_id);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call xx_hr_get_process_param_val');
      --Procedure to fetch process setup values
      xx_hr_get_process_param_val( x_file_prefix
                                  ,x_file
                                  ,x_utl_dir
                                  ,x_file_ext
                                 );
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After Call xx_hr_get_process_param_val');
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'********************Process Setup Entries****************');
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Prefix: '||x_file_prefix);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Name: '||x_file);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'UTL Directory: '||x_utl_dir);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'File Extension: '||x_file_ext);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'******************************************************');

     IF p_file_reprocess = 'N' THEN
        --Generate file name if not provided
        IF p_file_name IS NULL THEN
           IF x_file_prefix IS NOT NULL THEN
              x_file_name := x_file_prefix||'_'||x_file||'_'||TO_CHAR(SYSDATE,'RRRRMMDDHH24MISS')||x_file_ext;
           ELSE
              x_file_name := x_file||'_'||TO_CHAR(SYSDATE,'RRRRMMDDHH24MISS')||x_file_ext;
           END IF;
        ELSE
           x_file_name := p_file_name;
        END IF;
     ELSIF p_file_reprocess = 'Y' THEN
        x_request_id := p_request_id;
        --Fetch file name for reprocess
        BEGIN
           SELECT file_name
             INTO x_file_name
             FROM xx_hr_emp_census_stg
            WHERE request_id = p_request_id
              AND ROWNUM = 1;
        EXCEPTION
           WHEN OTHERS THEN
           x_file_name := NULL;
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while fetching file name for Reprocess');
        END;
     END IF;

     x_effec_date := TRUNC(TO_DATE(p_effec_date,'YYYY-MM-DD HH24:MI:SS'));
     IF p_file_reprocess = 'N' THEN
        --Call procedure to process census data
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call xx_hr_process_data_stg');
        xx_hr_process_data_stg( x_effec_date
                               ,x_request_id
                               ,x_file_name
                              );
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After xx_hr_process_data_stg g_retcode: '||g_retcode);
        xx_emf_pkg.propagate_error (g_retcode);
        --Call procedure to apply translation rules
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call xx_hr_trnsln_rules');
        xx_hr_trnsln_rules( x_request_id
                          );
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After xx_hr_trnsln_rules g_retcode: '||g_retcode);
        xx_emf_pkg.propagate_error (g_retcode);
        --Call procedure to generate file
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call xx_hr_file_generation');
        xx_hr_file_generation (
                                x_file_name
                               ,x_utl_dir
                               ,x_hdr_data
                               ,x_request_id
                              );
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After xx_hr_file_generation g_retcode: '||g_retcode);
        xx_emf_pkg.propagate_error (g_retcode);
     ELSIF p_file_reprocess = 'Y' THEN
        --Call procedure to generate file
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Before Call xx_hr_file_generation');
        xx_hr_file_generation (
                               x_file_name
                              ,x_utl_dir
                              ,x_hdr_data
                              ,x_request_id
                              );
        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'After xx_hr_file_generation g_retcode: '||g_retcode);
        xx_emf_pkg.propagate_error (g_retcode);
     END IF;
     
     -- Send Email to benefits team
     
       send_ben_file_email(x_file_name
                          ,x_utl_dir
                          ,x_ret_code
                          ,x_err_msg);
                            
     --Update error record count
     update_record_count (x_request_id);
     --Generate error report
     xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'xx_emf_pkg.cn_env_not_set: '||xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Procedure Error:retcode: '||g_retcode||' Err Msg: '||g_errmsg);
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
      WHEN OTHERS THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         errbuf := SUBSTR (SQLERRM, 1, 250);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||retcode||' Error: '||errbuf);
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand,
                           'Unexpected error in main',
                           SQLERRM
                          );
   END main;

END xx_hr_census_interface_pkg; 
/
