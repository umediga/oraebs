DROP PACKAGE BODY APPS.XX_HR_EMP_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_EMP_CONVERSION_PKG" 
AS
-----------------------------------------------------------------------------------------------------
/*
 Created By     : IBM Development
 Creation Date  : 01-Nov-07
 File Name      : XXHREMPCNV.pkb
 Description    : This script creates the body of the package xx_hr_emp_conversion_pkg
COMMON GUIDELINES REGARDING EMF
-------------------------------
1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED
 Change History:
  Date          Name               Remarks
 -----------   ------------        ---------------------------------------
 01-Nov-07     IBM Development     Initial development.
 06-Jan-2012    Deepika Jain       Changes for Integra
 10-May-2012    MuthuKumar         Changed error code to warning inside the procedures for creation
                                   and updation of eit data during Mock Conv
 15-Jun-2012   Arjun K.            Variable re-initialization post CRP3.
*/
----------------------------------------------------------------------------------------------------
   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS
------------------------------------------------------------------
-------------------------< set_cnv_env >--------------------------
------------------------------------------------------------------
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_batch_id := p_batch_id;
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;

      IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env;

----------------------------------------------------------------------
-------------------------< mark_records_for_processing >--------------
----------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2,
      p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables
      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_hr_emp_pre
                  WHERE batch_id = g_batch_id;

            UPDATE xx_hr_emp_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_hr_emp_pre
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_hr_emp_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id
               AND (   process_code = xx_emf_cn_pkg.cn_new
                    OR (    process_code = xx_emf_cn_pkg.cn_preval
                        AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                               (xx_emf_cn_pkg.cn_rec_warn,
                                xx_emf_cn_pkg.cn_rec_err
                               )
                       )
                   );
         END IF;

         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_hr_emp_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_hr_emp_pre
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_hr_emp_pre
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_hr_emp_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_preval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 3 Data Derivation Stage
         UPDATE xx_hr_emp_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_derive
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_derive
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 4 Post Validation Stage
         UPDATE xx_hr_emp_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_postval
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 5 Process Data Stage
         UPDATE xx_hr_emp_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err);
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END;

----------------------------------------------------------------------
-------------------------< set_stage >--------------------------
----------------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE            := SYSDATE;
      x_last_updated_by     NUMBER          := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      l_sqlerrm             VARCHAR2 (2000);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_hr_emp_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_sqlerrm := SQLERRM;
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                           xx_emf_cn_pkg.cn_tech_error,
                           'While update_staging_record proc:' || l_sqlerrm
                          );
   END update_staging_records;

   -- END RESTRICTIONS
   ----------------------------------------------------------------------
-------------------------< main >--------------------------
----------------------------------------------------------------------
   PROCEDURE main (
      errbuf                OUT NOCOPY      VARCHAR2,
      retcode               OUT NOCOPY      VARCHAR2,
      p_batch_id            IN              VARCHAR2,
      p_restart_flag        IN              VARCHAR2,
      p_override_flag       IN              VARCHAR2,
      p_validate_and_load   IN              VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_pre_std_hdr_table   g_xx_hr_cnv_pre_tab_type;
      x_business_group_id   NUMBER;

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   batch_id, country, business_group_name, rehire_flag,
                  user_person_type, employee_number, npw_number,
                  national_identifier, title, first_name, middle_names,
                  last_name, full_name, pre_name_adjunct, suffix,
                  previous_last_name, known_as, sex, date_of_birth,
                  marital_status, nationality, town_of_birth,
                  region_of_birth, country_of_birth, hire_date,
                  adjusted_svc_date, termination_date, termination_reason,
                  final_processing_date, original_date_of_hire,
                  registered_disabled_flag, email_address, mailstop,
                  office_number, correspondence_language, student_status,
                  on_military_service, ethnic_origin, i9_status,
                  i9_expiration_date, vets_100, vets_100a, new_hire_status,
                  reason_for_exclusion, child_support_obligation,
                  opted_for_medicare, ethnicity_disclosed, sex_entered_by,
                  ethnic_origin_entered_by, work_per_num, work_per_stat,
                  work_per_end_dt, rfc_id, federal_govt_affiliation_id,
                  soc_sec_id, mil_ser_id, soc_sec_med_cen, mat_last_name,
                  maiden_name, date_first_entry_france, military_status,
                  cpam_name, level_of_education,
                  date_last_school_certificate, school_name,
                  provisional_number, personal_email_id, ethnic_origin_gb,
                  director, pensioner, work_per_num_gb,
                  additional_pensionable_years,
                  additional_pensionable_months, additional_pensionable_days,
                  ni_multiple_assignments, paye_agg_assignments,
                  dss_link_letter_end_date, mother_maiden_name,
                  ethnic_origin_ie, professional_title, hereditary_title,
                  last_name_at_birth, hereditary_title_at_birth,
                  prefix_at_birth, date_of_marriage, previous_prefix,
                  eu_soc_insurance_num, second_nationality, prefix,
                  eighteen_years_below, prev_employment_end_date,
                  child_allowance_reg, holiday_insurance_reg, pension_reg,
                  id_number, school_leaver, payroll_tax_state,
                  exclude_from_payroll_tax, work_per_num_nz,
                  work_per_expiry_date, ethnic_origin_nz, tribal_group,
                  district_of_origin, stat_nz_emp_cat, stat_nz_working_time,
                  business_group_id, person_type_id, person_id,
                  global_person_id, period_of_service_id,
                  object_version_number, attribute_category, attribute1,
                  attribute2, attribute3, attribute4, attribute5, attribute6,
                  attribute7, attribute8, attribute9, attribute10,
                  eit_information_type, eit_information_category, eit1, eit2,
                  eit3, eit4, eit5, eit6, eit7, eit8, record_number,
                  process_code, ERROR_CODE, request_id, last_update_date,
                  last_updated_by, last_update_login, created_by,
                  creation_date, program_application_id, program_id,
                  program_update_date
             FROM xx_hr_emp_pre hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              --AND error_code   IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN) -- Changed by Rohit J
              AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

----------------------------------------------------------------------
-------------------------< update_record_status >---------------------
----------------------------------------------------------------------
      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT NOCOPY   g_xx_hr_cnv_pre_rec_type,
         p_error_code             IN              VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_hr_emp_cnv_validations_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.cn_success
                                          )
                                     );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

----------------------------------------------------------------------
-------------------------< mark_records_complete >--------------------
----------------------------------------------------------------------
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_hr_emp_pre
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
                last_updated_by = x_last_updated_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE (g_stage,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
      END mark_records_complete;

----------------------------------------------------------------------
-------------------------< update_pre_interface_records >-------------
----< Debashis:  included Batch ID in the WHERE CONDITION  >----------
----------------------------------------------------------------------
      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_hr_cnv_pre_tab_type
      )
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'update_pre_interface_records '
                              );

         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
         LOOP
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'p_cnv_pre_std_hdr_table(indx).process_code '
                             || p_cnv_pre_std_hdr_table (indx).process_code
                            );
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'p_cnv_pre_std_hdr_table(indx).error_code '
                                || p_cnv_pre_std_hdr_table (indx).ERROR_CODE
                               );
            xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'Business Group ID '
                            || p_cnv_pre_std_hdr_table (indx).business_group_id
                            || 'Person Type ID '
                            || p_cnv_pre_std_hdr_table (indx).person_type_id
                            || 'Sex '
                            || p_cnv_pre_std_hdr_table (indx).sex
                           );

            UPDATE xx_hr_emp_pre
               SET country = p_cnv_pre_std_hdr_table (indx).country,
                   business_group_name =
                            p_cnv_pre_std_hdr_table (indx).business_group_name,
                   rehire_flag = p_cnv_pre_std_hdr_table (indx).rehire_flag,
                   user_person_type =
                               p_cnv_pre_std_hdr_table (indx).user_person_type,
                   employee_number =
                                p_cnv_pre_std_hdr_table (indx).employee_number,
                   npw_number = p_cnv_pre_std_hdr_table (indx).npw_number,
                   national_identifier =
                            p_cnv_pre_std_hdr_table (indx).national_identifier,
                   title = p_cnv_pre_std_hdr_table (indx).title,
                   first_name = p_cnv_pre_std_hdr_table (indx).first_name,
                   middle_names = p_cnv_pre_std_hdr_table (indx).middle_names,
                   last_name = p_cnv_pre_std_hdr_table (indx).last_name,
                   full_name = p_cnv_pre_std_hdr_table (indx).full_name,
                   pre_name_adjunct =
                               p_cnv_pre_std_hdr_table (indx).pre_name_adjunct,
                   suffix = p_cnv_pre_std_hdr_table (indx).suffix,
                   previous_last_name =
                             p_cnv_pre_std_hdr_table (indx).previous_last_name,
                   known_as = p_cnv_pre_std_hdr_table (indx).known_as,
                   sex = p_cnv_pre_std_hdr_table (indx).sex,
                   date_of_birth =
                                  p_cnv_pre_std_hdr_table (indx).date_of_birth,
                   marital_status =
                                 p_cnv_pre_std_hdr_table (indx).marital_status,
                   nationality = p_cnv_pre_std_hdr_table (indx).nationality,
                   town_of_birth =
                                  p_cnv_pre_std_hdr_table (indx).town_of_birth,
                   region_of_birth =
                                p_cnv_pre_std_hdr_table (indx).region_of_birth,
                   country_of_birth =
                               p_cnv_pre_std_hdr_table (indx).country_of_birth,
                   hire_date = p_cnv_pre_std_hdr_table (indx).hire_date,
                   adjusted_svc_date =
                              p_cnv_pre_std_hdr_table (indx).adjusted_svc_date,
                   termination_date =
                               p_cnv_pre_std_hdr_table (indx).termination_date,
                   termination_reason =
                             p_cnv_pre_std_hdr_table (indx).termination_reason,
                   final_processing_date =
                          p_cnv_pre_std_hdr_table (indx).final_processing_date,
                   original_date_of_hire =
                          p_cnv_pre_std_hdr_table (indx).original_date_of_hire,
                   registered_disabled_flag =
                       p_cnv_pre_std_hdr_table (indx).registered_disabled_flag,
                   email_address =
                                  p_cnv_pre_std_hdr_table (indx).email_address,
                   mailstop = p_cnv_pre_std_hdr_table (indx).mailstop,
                   office_number =
                                  p_cnv_pre_std_hdr_table (indx).office_number,
                   correspondence_language =
                        p_cnv_pre_std_hdr_table (indx).correspondence_language,
                   student_status =
                                 p_cnv_pre_std_hdr_table (indx).student_status,
                   on_military_service =
                            p_cnv_pre_std_hdr_table (indx).on_military_service,
                   ethnic_origin =
                                  p_cnv_pre_std_hdr_table (indx).ethnic_origin,
                   i9_status = p_cnv_pre_std_hdr_table (indx).i9_status,
                   i9_expiration_date =
                             p_cnv_pre_std_hdr_table (indx).i9_expiration_date,
                   vets_100 = p_cnv_pre_std_hdr_table (indx).vets_100,
                   vets_100a = p_cnv_pre_std_hdr_table (indx).vets_100a,
                   new_hire_status =
                                p_cnv_pre_std_hdr_table (indx).new_hire_status,
                   reason_for_exclusion =
                           p_cnv_pre_std_hdr_table (indx).reason_for_exclusion,
                   child_support_obligation =
                       p_cnv_pre_std_hdr_table (indx).child_support_obligation,
                   opted_for_medicare =
                             p_cnv_pre_std_hdr_table (indx).opted_for_medicare,
                   ethnicity_disclosed =
                            p_cnv_pre_std_hdr_table (indx).ethnicity_disclosed,
                   sex_entered_by =
                                 p_cnv_pre_std_hdr_table (indx).sex_entered_by,
                   ethnic_origin_entered_by =
                       p_cnv_pre_std_hdr_table (indx).ethnic_origin_entered_by,
                   work_per_num = p_cnv_pre_std_hdr_table (indx).work_per_num,
                   work_per_stat =
                                  p_cnv_pre_std_hdr_table (indx).work_per_stat,
                   work_per_end_dt =
                                p_cnv_pre_std_hdr_table (indx).work_per_end_dt,
                   rfc_id = p_cnv_pre_std_hdr_table (indx).rfc_id,
                   federal_govt_affiliation_id =
                      p_cnv_pre_std_hdr_table (indx).federal_govt_affiliation_id,
                   soc_sec_id = p_cnv_pre_std_hdr_table (indx).soc_sec_id,
                   mil_ser_id = p_cnv_pre_std_hdr_table (indx).mil_ser_id,
                   soc_sec_med_cen =
                                p_cnv_pre_std_hdr_table (indx).soc_sec_med_cen,
                   mat_last_name =
                                  p_cnv_pre_std_hdr_table (indx).mat_last_name,
                   maiden_name = p_cnv_pre_std_hdr_table (indx).maiden_name,
                   date_first_entry_france =
                        p_cnv_pre_std_hdr_table (indx).date_first_entry_france,
                   military_status =
                                p_cnv_pre_std_hdr_table (indx).military_status,
                   cpam_name = p_cnv_pre_std_hdr_table (indx).cpam_name,
                   level_of_education =
                             p_cnv_pre_std_hdr_table (indx).level_of_education,
                   date_last_school_certificate =
                      p_cnv_pre_std_hdr_table (indx).date_last_school_certificate,
                   school_name = p_cnv_pre_std_hdr_table (indx).school_name,
                   provisional_number =
                             p_cnv_pre_std_hdr_table (indx).provisional_number,
                   personal_email_id =
                              p_cnv_pre_std_hdr_table (indx).personal_email_id,
                   ethnic_origin_gb =
                               p_cnv_pre_std_hdr_table (indx).ethnic_origin_gb,
                   director = p_cnv_pre_std_hdr_table (indx).director,
                   pensioner = p_cnv_pre_std_hdr_table (indx).pensioner,
                   work_per_num_gb =
                                p_cnv_pre_std_hdr_table (indx).work_per_num_gb,
                   additional_pensionable_years =
                      p_cnv_pre_std_hdr_table (indx).additional_pensionable_years,
                   additional_pensionable_months =
                      p_cnv_pre_std_hdr_table (indx).additional_pensionable_months,
                   additional_pensionable_days =
                      p_cnv_pre_std_hdr_table (indx).additional_pensionable_days,
                   ni_multiple_assignments =
                        p_cnv_pre_std_hdr_table (indx).ni_multiple_assignments,
                   paye_agg_assignments =
                           p_cnv_pre_std_hdr_table (indx).paye_agg_assignments,
                   dss_link_letter_end_date =
                       p_cnv_pre_std_hdr_table (indx).dss_link_letter_end_date,
                   mother_maiden_name =
                             p_cnv_pre_std_hdr_table (indx).mother_maiden_name,
                   ethnic_origin_ie =
                               p_cnv_pre_std_hdr_table (indx).ethnic_origin_ie,
                   professional_title =
                             p_cnv_pre_std_hdr_table (indx).professional_title,
                   hereditary_title =
                               p_cnv_pre_std_hdr_table (indx).hereditary_title,
                   last_name_at_birth =
                             p_cnv_pre_std_hdr_table (indx).last_name_at_birth,
                   hereditary_title_at_birth =
                      p_cnv_pre_std_hdr_table (indx).hereditary_title_at_birth,
                   prefix_at_birth =
                                p_cnv_pre_std_hdr_table (indx).prefix_at_birth,
                   date_of_marriage =
                               p_cnv_pre_std_hdr_table (indx).date_of_marriage,
                   previous_prefix =
                                p_cnv_pre_std_hdr_table (indx).previous_prefix,
                   eu_soc_insurance_num =
                           p_cnv_pre_std_hdr_table (indx).eu_soc_insurance_num,
                   second_nationality =
                             p_cnv_pre_std_hdr_table (indx).second_nationality,
                   prefix = p_cnv_pre_std_hdr_table (indx).prefix,
                   eighteen_years_below =
                           p_cnv_pre_std_hdr_table (indx).eighteen_years_below,
                   prev_employment_end_date =
                       p_cnv_pre_std_hdr_table (indx).prev_employment_end_date,
                   child_allowance_reg =
                            p_cnv_pre_std_hdr_table (indx).child_allowance_reg,
                   holiday_insurance_reg =
                          p_cnv_pre_std_hdr_table (indx).holiday_insurance_reg,
                   pension_reg = p_cnv_pre_std_hdr_table (indx).pension_reg,
                   id_number = p_cnv_pre_std_hdr_table (indx).id_number,
                   school_leaver =
                                  p_cnv_pre_std_hdr_table (indx).school_leaver,
                   payroll_tax_state =
                              p_cnv_pre_std_hdr_table (indx).payroll_tax_state,
                   exclude_from_payroll_tax =
                       p_cnv_pre_std_hdr_table (indx).exclude_from_payroll_tax,
                   work_per_num_nz =
                                p_cnv_pre_std_hdr_table (indx).work_per_num_nz,
                   work_per_expiry_date =
                           p_cnv_pre_std_hdr_table (indx).work_per_expiry_date,
                   ethnic_origin_nz =
                               p_cnv_pre_std_hdr_table (indx).ethnic_origin_nz,
                   tribal_group = p_cnv_pre_std_hdr_table (indx).tribal_group,
                   district_of_origin =
                             p_cnv_pre_std_hdr_table (indx).district_of_origin,
                   stat_nz_emp_cat =
                                p_cnv_pre_std_hdr_table (indx).stat_nz_emp_cat,
                   stat_nz_working_time =
                           p_cnv_pre_std_hdr_table (indx).stat_nz_working_time,
                   business_group_id =
                              p_cnv_pre_std_hdr_table (indx).business_group_id,
                   person_type_id =
                                 p_cnv_pre_std_hdr_table (indx).person_type_id,
                   attribute_category =
                             p_cnv_pre_std_hdr_table (indx).attribute_category,
                   attribute1 = p_cnv_pre_std_hdr_table (indx).attribute1,
                   attribute2 = p_cnv_pre_std_hdr_table (indx).attribute2,
                   attribute3 = p_cnv_pre_std_hdr_table (indx).attribute3,
                   attribute4 = p_cnv_pre_std_hdr_table (indx).attribute4,
                   attribute5 = p_cnv_pre_std_hdr_table (indx).attribute5,
                   attribute6 = p_cnv_pre_std_hdr_table (indx).attribute6,
                   attribute7 = p_cnv_pre_std_hdr_table (indx).attribute7,
                   attribute8 = p_cnv_pre_std_hdr_table (indx).attribute8,
                   attribute9 = p_cnv_pre_std_hdr_table (indx).attribute9,
                   attribute10 = p_cnv_pre_std_hdr_table (indx).attribute10,
                   eit_information_type =
                           p_cnv_pre_std_hdr_table (indx).eit_information_type,
                   eit_information_category =
                       p_cnv_pre_std_hdr_table (indx).eit_information_category,
                   eit1 = p_cnv_pre_std_hdr_table (indx).eit1,
                   eit2 = p_cnv_pre_std_hdr_table (indx).eit2,
                   eit3 = p_cnv_pre_std_hdr_table (indx).eit3,
                   eit4 = p_cnv_pre_std_hdr_table (indx).eit4,
                   eit5 = p_cnv_pre_std_hdr_table (indx).eit5,
                   eit6 = p_cnv_pre_std_hdr_table (indx).eit6,
                   eit7 = p_cnv_pre_std_hdr_table (indx).eit7,
                   eit8 = p_cnv_pre_std_hdr_table (indx).eit8,
                   process_code = p_cnv_pre_std_hdr_table (indx).process_code,
                   ERROR_CODE = p_cnv_pre_std_hdr_table (indx).ERROR_CODE,
                   request_id = p_cnv_pre_std_hdr_table (indx).request_id,
                   last_updated_by = x_last_updated_by,
                   last_update_date = x_last_update_date,
                   last_update_login = x_last_update_login
             WHERE record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number
               AND batch_id = p_cnv_pre_std_hdr_table (indx).batch_id;
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END update_pre_interface_records;

----------------------------------------------------------------------
-------------------------< move_rec_pre_standard_table >--------------------------
----------------------------------------------------------------------
      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date           DATE                     := SYSDATE;
         x_created_by              NUMBER               := fnd_global.user_id;
         x_last_update_date        DATE                     := SYSDATE;
         x_last_updated_by         NUMBER               := fnd_global.user_id;
         x_last_update_login       NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_cnv_pre_std_hdr_table   g_xx_hr_cnv_pre_tab_type;
         -- := G_XX_HR_CNV_PRE_REC_TYPE();
         x_error_code              NUMBER         := xx_emf_cn_pkg.cn_success;
         p                         VARCHAR2 (100);
         q                         VARCHAR2 (100);
         r                         VARCHAR2 (100);
         s                         VARCHAR2 (100);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );

         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         INSERT INTO xx_hr_emp_pre
                     (batch_id, country, business_group_name, rehire_flag,
                      user_person_type, employee_number, npw_number,
                      national_identifier, title, first_name, middle_names,
                      last_name, full_name, pre_name_adjunct, suffix,
                      previous_last_name, known_as, sex, date_of_birth,
                      marital_status, nationality, town_of_birth,
                      region_of_birth, country_of_birth, hire_date,
                      adjusted_svc_date, termination_date, termination_reason,
                      final_processing_date, original_date_of_hire,
                      registered_disabled_flag, email_address, mailstop,
                      office_number, correspondence_language, student_status,
                      on_military_service, ethnic_origin, i9_status,
                      i9_expiration_date, vets_100, vets_100a,
                      new_hire_status, reason_for_exclusion,
                      child_support_obligation, opted_for_medicare,
                      ethnicity_disclosed, sex_entered_by,
                      ethnic_origin_entered_by, work_per_num, work_per_stat,
                      work_per_end_dt, rfc_id, federal_govt_affiliation_id,
                      soc_sec_id, mil_ser_id, soc_sec_med_cen, mat_last_name,
                      maiden_name, date_first_entry_france, military_status,
                      cpam_name, level_of_education,
                      date_last_school_certificate, school_name,
                      provisional_number, personal_email_id, ethnic_origin_gb,
                      director, pensioner, work_per_num_gb,
                      additional_pensionable_years,
                      additional_pensionable_months,
                      additional_pensionable_days, ni_multiple_assignments,
                      paye_agg_assignments, dss_link_letter_end_date,
                      mother_maiden_name, ethnic_origin_ie,
                      professional_title, hereditary_title,
                      last_name_at_birth, hereditary_title_at_birth,
                      prefix_at_birth, date_of_marriage, previous_prefix,
                      eu_soc_insurance_num, second_nationality, prefix,
                      eighteen_years_below, prev_employment_end_date,
                      child_allowance_reg, holiday_insurance_reg, pension_reg,
                      id_number, school_leaver, payroll_tax_state,
                      exclude_from_payroll_tax, work_per_num_nz,
                      work_per_expiry_date, ethnic_origin_nz, tribal_group,
                      district_of_origin, stat_nz_emp_cat,
                      stat_nz_working_time, attribute_category, attribute1,
                      attribute2, attribute3, attribute4, attribute5,
                      attribute6, attribute7, attribute8, attribute9,
                      attribute10, eit_information_type,
                      eit_information_category, eit1, eit2, eit3, eit4, eit5,
                      eit6, eit7, eit8, record_number, process_code,
                      ERROR_CODE, request_id, last_update_date,
                      last_updated_by, last_update_login, created_by,
                      creation_date, program_application_id, program_id,
                      program_update_date)
            SELECT batch_id, country, business_group_name, rehire_flag,
                   DECODE (user_person_type,
                           'Employee', 'Employee',
                           'Consultant', 'Contingent Worker',
                           'Independent Contractor', 'Contingent Worker',
                           'Agency Temp', 'Contingent Worker',
                           'Candidate', 'Candidate'
                          ),
                   employee_number, npw_number, national_identifier, title,
                   first_name, middle_names, last_name, full_name,
                   pre_name_adjunct, suffix, previous_last_name, known_as,
                   sex, date_of_birth, marital_status, nationality,
                   town_of_birth, region_of_birth, country_of_birth,
                   hire_date, adjusted_svc_date, termination_date,
                   termination_reason, final_processing_date,
                   original_date_of_hire, registered_disabled_flag,
                   email_address, mailstop, office_number,
                   correspondence_language, student_status,
                   on_military_service, ethnic_origin, i9_status,
                   i9_expiration_date, vets_100, vets_100a, new_hire_status,
                   reason_for_exclusion, child_support_obligation,
                   opted_for_medicare, ethnicity_disclosed, sex_entered_by,
                   ethnic_origin_entered_by, work_per_num, work_per_stat,
                   work_per_end_dt, rfc_id, federal_govt_affiliation_id,
                   soc_sec_id, mil_ser_id, soc_sec_med_cen, mat_last_name,
                   maiden_name, date_first_entry_france, military_status,
                   cpam_name, level_of_education,
                   date_last_school_certificate, school_name,
                   provisional_number, personal_email_id, ethnic_origin_gb,
                   director, pensioner, work_per_num_gb,
                   additional_pensionable_years,
                   additional_pensionable_months, additional_pensionable_days,
                   ni_multiple_assignments, paye_agg_assignments,
                   dss_link_letter_end_date, mother_maiden_name,
                   ethnic_origin_ie, professional_title, hereditary_title,
                   last_name_at_birth, hereditary_title_at_birth,
                   prefix_at_birth, date_of_marriage, previous_prefix,
                   eu_soc_insurance_num, second_nationality, prefix,
                   eighteen_years_below, prev_employment_end_date,
                   child_allowance_reg, holiday_insurance_reg, pension_reg,
                   id_number, school_leaver, payroll_tax_state,
                   exclude_from_payroll_tax, work_per_num_nz,
                   work_per_expiry_date, ethnic_origin_nz, tribal_group,
                   district_of_origin, stat_nz_emp_cat, stat_nz_working_time,
                   attribute_category, attribute1, attribute2, attribute3,
                   attribute4, attribute5, attribute6, attribute7, attribute8,
                   attribute9, attribute10, eit_information_type,
                   eit_information_category, eit1, eit2, eit3, eit4, eit5,
                   eit6, eit7, eit8, record_number, process_code, ERROR_CODE,
                   request_id, last_update_date, last_updated_by,
                   last_update_login, created_by, creation_date,
                   program_application_id, program_id, program_update_date
              FROM xx_hr_emp_stg
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                                                                             --and record_number between 1 and 25  --dupatil testing
         ;

         COMMIT;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'I am here 1');
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'I am here 2');
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

  ----------------------------------------------------------------------
--------------------------< update_eit_data >--------------------------
----------------------------------------------------------------------
      PROCEDURE update_eit_data (
         xx_emp_rec    IN OUT   g_xx_hr_cnv_pre_rec_type,
         x_person_id   IN       NUMBER
      )
      IS
         CURSOR get_person_extra_info_details (p_person_id NUMBER)
         IS
            SELECT person_extra_info_id, object_version_number
              FROM per_people_extra_info
             WHERE person_id = p_person_id;

         x_person_extra_info_id    NUMBER;
         x_object_version_number   NUMBER;
      BEGIN
         -- call API to update EIT data
         OPEN get_person_extra_info_details (x_person_id);

         FETCH get_person_extra_info_details
          INTO x_person_extra_info_id, x_object_version_number;

         CLOSE get_person_extra_info_details;

         IF x_person_extra_info_id IS NOT NULL
         THEN
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                'Before calling hr_person_extra_info_api.update_person_extra_info'
               );
            hr_person_extra_info_api.update_person_extra_info
               (p_validate                      => g_validate_flag,
                p_person_extra_info_id          => x_person_extra_info_id,
                p_object_version_number         => x_object_version_number,
                p_pei_information_category      => xx_emp_rec.eit_information_category,
                p_pei_information1              => xx_emp_rec.eit1,
                p_pei_information2              => xx_emp_rec.eit2,
                p_pei_information3              => xx_emp_rec.eit3,
                p_pei_information4              => xx_emp_rec.eit4,
                p_pei_information5              => xx_emp_rec.eit5,
                p_pei_information6              => xx_emp_rec.eit6,
                p_pei_information7              => xx_emp_rec.eit7,
                p_pei_information8              => xx_emp_rec.eit8
               );
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                'After calling hr_person_extra_info_api.update_person_extra_info'
               );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              SUBSTR (SQLERRM, 1, 800),
                              xx_emp_rec.attribute1,
                              xx_emp_rec.record_number,
                              xx_emp_rec.user_person_type,
                              'Update EIT data API'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_warn; -- modified during mock conversion
            main.retcode := xx_emf_cn_pkg.cn_rec_warn; -- added during mock conversion
            UPDATE xx_hr_emp_pre
               SET ERROR_CODE = x_error_code
             WHERE record_number = xx_emp_rec.record_number
               AND batch_id = g_batch_id;

            COMMIT;
      END update_eit_data;

          ----------------------------------------------------------------------
--------------------------< create_eit_data >--------------------------
----------------------------------------------------------------------
      PROCEDURE create_eit_data (
         xx_emp_rec    IN OUT   g_xx_hr_cnv_pre_rec_type,
         x_person_id   IN       NUMBER
      )
      IS
         x_person_extra_info_id    NUMBER;
         x_object_version_number   NUMBER;
      -- call API to create EIT data
      BEGIN
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
             'Before calling hr_person_extra_info_api.create_person_extra_info'
            );
         hr_person_extra_info_api.create_person_extra_info
            (p_validate                      => g_validate_flag,
             p_person_id                     => x_person_id,
             p_information_type              => xx_emp_rec.eit_information_type,
             p_pei_information_category      => xx_emp_rec.eit_information_category,
             p_pei_information1              => xx_emp_rec.eit1,
             p_pei_information2              => xx_emp_rec.eit2,
             p_pei_information3              => xx_emp_rec.eit3,
             p_pei_information4              => xx_emp_rec.eit4,
             p_pei_information5              => xx_emp_rec.eit5,
             p_pei_information6              => xx_emp_rec.eit6,
             p_pei_information7              => xx_emp_rec.eit7,
             p_pei_information8              => xx_emp_rec.eit8,
             p_person_extra_info_id          => x_person_extra_info_id,
             p_object_version_number         => x_object_version_number
            );
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
             'After calling hr_person_extra_info_api.create_person_extra_info'
            );
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              SUBSTR (SQLERRM, 1, 800),
                              xx_emp_rec.attribute1,
                              xx_emp_rec.record_number,
                              xx_emp_rec.user_person_type,
                              'Create EIT data API'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_warn;     -- modified during mock conversion
            main.retcode := xx_emf_cn_pkg.cn_rec_warn;     -- added during mock conversion

            UPDATE xx_hr_emp_pre
               SET ERROR_CODE = x_error_code
             WHERE record_number = xx_emp_rec.record_number
               AND batch_id = g_batch_id;

            COMMIT;
      END create_eit_data;

  ----------------------------------------------------------------------
--------------------------< terminate_employee >--------------------------
----------------------------------------------------------------------
      FUNCTION terminate_employee (xx_emp_rec IN OUT g_xx_hr_cnv_pre_rec_type)
         RETURN NUMBER
      IS
         x_validate                     BOOLEAN                      := FALSE;
         x_effective_date               DATE                       := SYSDATE;
         x_object_version_number        NUMBER;
         x_assignment_status_type_id    NUMBER             := hr_api.g_number;
         x_atd_new                      NUMBER;
         x_lspd_new                     NUMBER;
         x_emp_attr_context    CONSTANT per_all_people_f.attribute_category%TYPE
                                                    := 'Global Data Elements';
         x_last_std_process_date_out    DATE;
         x_combination_warning          BOOLEAN;
         x_payroll_warning              BOOLEAN;
         x_orig_hire_warning            BOOLEAN;
         x_supervisor_warning           BOOLEAN;
         x_event_warning                BOOLEAN;
         x_interview_warning            BOOLEAN;
         x_review_warning               BOOLEAN;
         x_recruiter_warning            BOOLEAN;
         x_asg_future_changes_warning   BOOLEAN;
         x_entries_changed_warning      VARCHAR2 (1000);
         x_pay_proposal_warning         BOOLEAN;
         x_dod_warning                  BOOLEAN;
         x_alu_change_warning           VARCHAR2 (1000);
         x_org_now_no_manager_warning   BOOLEAN;
         /*x_per_object_version_number     NUMBER;
         x_assignment_id               NUMBER;
         x_asg_object_version_number   NUMBER;
         x_per_effective_start_date    DATE;
         x_per_effective_end_date      DATE;
         x_assignment_sequence         NUMBER;
         x_assignment_number           VARCHAR2 (300);
         x_assign_payroll_warning      BOOLEAN;*/
         l_sqlerrm                      VARCHAR2 (2000);
         x_sqlerrm                      VARCHAR2 (2000);
         x_final_process_date           DATE;
         p_period_of_service_id         NUMBER;
         l_person_id                    NUMBER;
         x_error_code                   NUMBER    := xx_emf_cn_pkg.cn_success;

         CURSOR get_period_of_service_id (
            p_attribute1          VARCHAR2,
            p_country             VARCHAR2,
            p_business_group_id   NUMBER
         )
         IS
            SELECT pps.period_of_service_id, pps.object_version_number,
                   pps.person_id
              FROM per_periods_of_service pps, per_all_people_f papf
             WHERE pps.person_id = papf.person_id
               AND papf.attribute1 = p_attribute1
               AND papf.business_group_id = p_business_group_id
               AND TRUNC (pps.date_start) BETWEEN papf.effective_start_date
                                              AND papf.effective_end_date
               AND pps.actual_termination_date IS NULL;
      /*CURSOR get_object_version_number(p_person_id NUMBER)
      IS
        SELECT ppf.object_version_number
        FROM per_all_people_f ppf,
             per_person_types ppt
        WHERE ppf.person_id = p_person_id
        AND  ppf.person_type_id = ppt.person_type_id
        AND  ppt.system_person_type = g_ex_emp_person_type;*/
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Terminate Employee Start'
                              );

         OPEN get_period_of_service_id (xx_emp_rec.attribute1,
                                        xx_emp_rec.country,
                                        xx_emp_rec.business_group_id
                                       );

         FETCH get_period_of_service_id
          INTO p_period_of_service_id, x_object_version_number, l_person_id;

         CLOSE get_period_of_service_id;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'p_period_of_service_id is'
                               || p_period_of_service_id
                              );

         IF p_period_of_service_id IS NOT NULL
         THEN
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   'The object version number of the record being terminated is '
                || x_object_version_number
               );
            xx_emf_pkg.write_log
                   (xx_emf_cn_pkg.cn_low,
                       'The person type id of the record being terminated is '
                    || xx_emp_rec.person_type_id
                   );
            x_final_process_date := xx_emp_rec.final_processing_date;

            -- terminate the employee before re-hiring
            BEGIN
               hr_ex_employee_api.actual_termination_emp
                  (p_validate                        => g_validate_flag,
                   p_effective_date                  => x_effective_date,
                   p_period_of_service_id            => p_period_of_service_id,
                   p_object_version_number           => x_object_version_number,
                   p_actual_termination_date         => xx_emp_rec.termination_date,
                   p_last_standard_process_date      => x_final_process_date,
                   p_person_type_id                  => hr_api.g_number,
                   p_assignment_status_type_id       => x_assignment_status_type_id,
                   p_leaving_reason                  => xx_emp_rec.termination_reason,
                   p_atd_new                         => x_atd_new,
                   p_lspd_new                        => x_lspd_new,
                   p_supervisor_warning              => x_supervisor_warning,
                   p_event_warning                   => x_event_warning,
                   p_interview_warning               => x_interview_warning,
                   p_review_warning                  => x_review_warning,
                   p_recruiter_warning               => x_recruiter_warning,
                   p_asg_future_changes_warning      => x_asg_future_changes_warning,
                   p_entries_changed_warning         => x_entries_changed_warning,
                   p_pay_proposal_warning            => x_pay_proposal_warning,
                   p_dod_warning                     => x_dod_warning,
                   p_alu_change_warning              => x_alu_change_warning
                  );
               xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                               'API hr_ex_employee_api.ACTUAL_TERMINATION_EMP'
                              );

               IF x_final_process_date IS NOT NULL
               THEN
                  hr_ex_employee_api.final_process_emp
                     (p_validate                        => g_validate_flag,
                      p_period_of_service_id            => p_period_of_service_id,
                      p_object_version_number           => x_object_version_number,
                      p_final_process_date              => x_final_process_date,
                      p_org_now_no_manager_warning      => x_org_now_no_manager_warning,
                      p_asg_future_changes_warning      => x_asg_future_changes_warning,
                      p_entries_changed_warning         => x_entries_changed_warning
                     );
               END IF;

               xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_low,
                                    'API hr_ex_employee_api.FINAL_PROCESS_EMP'
                                   );
               xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'OVN after hr_ex_employee_api.FINAL_PROCESS_EMP '
                          || x_object_version_number
                         );
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_tech_error,
                        p_error_text               => x_sqlerrm,
                        p_record_identifier_2      => xx_emp_rec.record_number,
                        p_record_identifier_3      => xx_emp_rec.user_person_type,
                        p_record_identifier_1      => xx_emp_rec.attribute1,
                        p_record_identifier_4      => 'Termination API'
                       );

                  UPDATE xx_hr_emp_pre
                     SET ERROR_CODE = x_error_code,
                         process_code = xx_emf_cn_pkg.cn_process_data
                   WHERE batch_id = g_batch_id
                     AND record_number = xx_emp_rec.record_number;

                  COMMIT;
            END;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_sqlerrm := SQLERRM;
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_high,
                              xx_emf_cn_pkg.cn_tech_error,
                              l_sqlerrm,
                              xx_emp_rec.attribute1,
                              xx_emp_rec.record_number,
                              xx_emp_rec.user_person_type,
                              'terminate_employee'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END terminate_employee;

    ----------------------------------------------------------------------
--------------------------< rehire_employee >--------------------------
----------------------------------------------------------------------
      FUNCTION rehire_and_update_employee
         RETURN NUMBER
      IS
         x_per_object_version_number   NUMBER;
         x_assignment_id               NUMBER;
         x_asg_object_version_number   NUMBER;
         x_per_effective_start_date    DATE;
         x_per_effective_end_date      DATE;
         x_assignment_sequence         NUMBER;
         x_assignment_number           VARCHAR2 (300);
         x_comment_id                  NUMBER;
         x_full_name                   VARCHAR2 (200);
         x_name_combination_warning    BOOLEAN;
         x_assign_payroll_warning      BOOLEAN;
         x_orig_hire_warning           BOOLEAN;
         l_sqlerrm                     VARCHAR2 (2000);
         x_sqlerrm                     VARCHAR2 (2000);
         l_person_id                   NUMBER;
         x_error_code                  NUMBER     := xx_emf_cn_pkg.cn_success;
         xx_rehire_emp_rec             g_xx_hr_cnv_pre_tab_type;
         x_employee_number             VARCHAR2 (150);
         x_record_number               NUMBER;
         x_person_type                 VARCHAR2 (100);
         x_on_military_service         VARCHAR2 (1);
         x_person_extra_info_id        NUMBER;
         l_count                       NUMBER                   := 0;

         CURSOR get_records_for_rehire
         IS
            SELECT   *
                FROM xx_hr_emp_pre
               WHERE NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                 AND batch_id = g_batch_id
                 AND (    rehire_flag IN ('Yes', 'Y', 'YES')
                      AND termination_date IS NULL
                     )
            ORDER BY hire_date DESC;

         CURSOR get_person_details (
            p_attribute1          VARCHAR2,
            p_business_group_id   NUMBER
         )
         IS
            SELECT papf.person_id, papf.object_version_number,
                   papf.employee_number
              FROM per_all_people_f papf, per_person_types ppt
             WHERE papf.attribute1 = p_attribute1
               AND papf.business_group_id = p_business_group_id
               AND papf.person_type_id = ppt.person_type_id
               AND ppt.system_person_type = g_ex_emp_person_type;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Rehire Employee Start');

         FOR xx_rehire_emp_rec IN get_records_for_rehire
         LOOP
            x_employee_number           := NULL;--Added post CRP3 on 15-JUN-2012 for variable re-initialization
            l_person_id                 := NULL;--Added post CRP3 on 15-JUN-2012 for variable re-initialization
            x_per_object_version_number := NULL;--Added post CRP3 on 15-JUN-2012 for variable re-initialization

            OPEN get_person_details (xx_rehire_emp_rec.attribute1,
                                     xx_rehire_emp_rec.business_group_id
                                    );

            FETCH get_person_details
             INTO l_person_id, x_per_object_version_number, x_employee_number;

            CLOSE get_person_details;

            --populate variables to be used in the exception block
            x_record_number := xx_rehire_emp_rec.record_number;
            x_person_type := xx_rehire_emp_rec.user_person_type;

            -- populate military service
            SELECT DECODE (UPPER (xx_rehire_emp_rec.on_military_service),
                           'YES', 'Y',
                           'Y', 'Y',
                           'NO', 'N',
                           'N', 'N'
                          )
              INTO x_on_military_service
              FROM DUAL;

            xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'The person id of the record being rehired is '
                            || l_person_id
                           );
            xx_emf_pkg.write_log
                (xx_emf_cn_pkg.cn_low,
                    'The object verson number of the record being rehired is '
                 || x_per_object_version_number
                );

            IF l_person_id IS NOT NULL
            THEN
               BEGIN
                  xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                         'Before calling hr_employee_api.re_hire_ex_employee'
                        );
                  hr_employee_api.re_hire_ex_employee
                     (p_validate                       => g_validate_flag,
                      p_hire_date                      => xx_rehire_emp_rec.hire_date,
                      p_person_id                      => l_person_id,
                      p_per_object_version_number      => x_per_object_version_number,
                      p_person_type_id                 => xx_rehire_emp_rec.person_type_id,
                      p_rehire_reason                  => NULL,
                      p_assignment_id                  => x_assignment_id,
                      p_asg_object_version_number      => x_asg_object_version_number,
                      p_per_effective_start_date       => x_per_effective_start_date,
                      p_per_effective_end_date         => x_per_effective_end_date,
                      p_assignment_sequence            => x_assignment_sequence,
                      p_assignment_number              => x_assignment_number,
                      p_assign_payroll_warning         => x_assign_payroll_warning
                     );
                  xx_emf_pkg.write_log
                          (xx_emf_cn_pkg.cn_low,
                           'After calling hr_employee_api.re_hire_ex_employee'
                          );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       l_sqlerrm,
                                       xx_rehire_emp_rec.attribute1,
                                       xx_rehire_emp_rec.record_number,
                                       xx_rehire_emp_rec.user_person_type,
                                       'Rehire API'
                                      );
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;

                     UPDATE xx_hr_emp_pre
                        SET ERROR_CODE = x_error_code
                      WHERE record_number = xx_rehire_emp_rec.record_number
                        AND batch_id = g_batch_id;

                     COMMIT;
               END;

               -- update the person record with latest details
               BEGIN
                  xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                 'Before calling hr_person_api.update_person'
                                );
                  hr_person_api.update_person
                     (p_validate                          => g_validate_flag,
                      p_effective_date                    => SYSDATE,
                      p_datetrack_update_mode             => 'CORRECTION',
                      p_person_id                         => l_person_id,
                      p_object_version_number             => x_per_object_version_number,
                      p_person_type_id                    => xx_rehire_emp_rec.person_type_id,
                      p_last_name                         => xx_rehire_emp_rec.last_name,
                      p_date_of_birth                     => xx_rehire_emp_rec.date_of_birth,
                      p_email_address                     => xx_rehire_emp_rec.email_address,
                      p_employee_number                   => x_employee_number,
                      p_expense_check_send_to_addres      => NULL,
                      p_first_name                        => xx_rehire_emp_rec.first_name,
                      p_known_as                          => xx_rehire_emp_rec.known_as,
                      p_marital_status                    => xx_rehire_emp_rec.marital_status,
                      p_middle_names                      => xx_rehire_emp_rec.middle_names,
                      p_nationality                       => xx_rehire_emp_rec.nationality,
                      p_national_identifier               => xx_rehire_emp_rec.national_identifier,
                      p_previous_last_name                => xx_rehire_emp_rec.previous_last_name,
                      p_registered_disabled_flag          => xx_rehire_emp_rec.registered_disabled_flag,
                      p_sex                               => xx_rehire_emp_rec.sex,
                      p_title                             => xx_rehire_emp_rec.title,
                      p_vendor_id                         => NULL,
                      p_work_telephone                    => NULL,
                      p_attribute_category                => xx_rehire_emp_rec.attribute_category,
                      p_attribute1                        => xx_rehire_emp_rec.attribute1,
                      p_attribute2                        => xx_rehire_emp_rec.attribute2,
                      p_attribute3                        => xx_rehire_emp_rec.attribute3,
                      p_attribute4                        => xx_rehire_emp_rec.attribute4,
                      p_attribute5                        => xx_rehire_emp_rec.attribute5,
                      p_attribute6                        => xx_rehire_emp_rec.attribute6,
                      p_attribute7                        => xx_rehire_emp_rec.attribute7,
                      p_attribute8                        => xx_rehire_emp_rec.attribute8,
                      p_attribute9                        => xx_rehire_emp_rec.attribute9,
                      p_attribute10                       => xx_rehire_emp_rec.attribute10,
                      p_per_information_category          => xx_rehire_emp_rec.country,
                      p_per_information1                  => COALESCE
                                                                (--xx_rehire_emp_rec.ethnic_origin,
                                                                 xx_rehire_emp_rec.work_per_num,
                                                                 xx_rehire_emp_rec.rfc_id,
                                                                 xx_rehire_emp_rec.maiden_name,
                                                                 xx_rehire_emp_rec.ethnic_origin_gb,
                                                                 xx_rehire_emp_rec.mother_maiden_name,
                                                                 xx_rehire_emp_rec.professional_title,
                                                                 xx_rehire_emp_rec.prev_employment_end_date,
                                                                 xx_rehire_emp_rec.payroll_tax_state,
                                                                 xx_rehire_emp_rec.work_per_num_nz
                                                                ),
                      p_per_information2                  => COALESCE
                                                                (xx_rehire_emp_rec.i9_status,
                                                                 xx_rehire_emp_rec.work_per_stat,
                                                                 xx_rehire_emp_rec.federal_govt_affiliation_id,
                                                                 xx_rehire_emp_rec.date_first_entry_france,
                                                                 xx_rehire_emp_rec.director,
                                                                 xx_rehire_emp_rec.ethnic_origin_ie,
                                                                 xx_rehire_emp_rec.hereditary_title,
                                                                 xx_rehire_emp_rec.child_allowance_reg,
                                                                 xx_rehire_emp_rec.exclude_from_payroll_tax,
                                                                 xx_rehire_emp_rec.work_per_expiry_date
                                                                ),
                      p_per_information3                  => COALESCE
                                                                (xx_rehire_emp_rec.i9_expiration_date,
                                                                 xx_rehire_emp_rec.work_per_end_dt,
                                                                 xx_rehire_emp_rec.soc_sec_id,
                                                                 xx_rehire_emp_rec.military_status,
                                                                 xx_rehire_emp_rec.pensioner,
                                                                 xx_rehire_emp_rec.last_name_at_birth,
                                                                 xx_rehire_emp_rec.holiday_insurance_reg,
                                                                 xx_rehire_emp_rec.ethnic_origin_nz
                                                                ),
                      p_per_information4                  => COALESCE
                                                                (xx_rehire_emp_rec.mil_ser_id,
                                                                 xx_rehire_emp_rec.cpam_name,
                                                                 xx_rehire_emp_rec.work_per_num,
                                                                 xx_rehire_emp_rec.hereditary_title_at_birth,
                                                                 xx_rehire_emp_rec.pension_reg,
                                                                 xx_rehire_emp_rec.tribal_group
                                                                ),
                      p_per_information5                  => COALESCE
                                                                (xx_rehire_emp_rec.vets_100,
                                                                 xx_rehire_emp_rec.soc_sec_med_cen,
                                                                 xx_rehire_emp_rec.level_of_education,
                                                                 xx_rehire_emp_rec.additional_pensionable_years,
                                                                 xx_rehire_emp_rec.prefix_at_birth,
                                                                 xx_rehire_emp_rec.id_number,
                                                                 xx_rehire_emp_rec.district_of_origin
                                                                ),
                      p_per_information6                  => COALESCE
                                                                (xx_rehire_emp_rec.mat_last_name,
                                                                 xx_rehire_emp_rec.date_last_school_certificate,
                                                                 xx_rehire_emp_rec.additional_pensionable_months,
                                                                 xx_rehire_emp_rec.date_of_marriage,
                                                                 xx_rehire_emp_rec.school_leaver,
                                                                 xx_rehire_emp_rec.stat_nz_emp_cat
                                                                ),
                      p_per_information7                  => COALESCE
                                                                (xx_rehire_emp_rec.new_hire_status,
                                                                 xx_rehire_emp_rec.school_name,
                                                                 xx_rehire_emp_rec.additional_pensionable_days,
                                                                 xx_rehire_emp_rec.previous_prefix,
                                                                 xx_rehire_emp_rec.stat_nz_working_time
                                                                ),
                      p_per_information8                  => COALESCE
                                                                (xx_rehire_emp_rec.reason_for_exclusion,
                                                                 xx_rehire_emp_rec.provisional_number,
                                                                 xx_rehire_emp_rec.ni_multiple_assignments,
                                                                 xx_rehire_emp_rec.eu_soc_insurance_num
                                                                ),
                      p_per_information9                  => COALESCE
                                                                (xx_rehire_emp_rec.child_support_obligation,
                                                                 xx_rehire_emp_rec.personal_email_id,
                                                                 xx_rehire_emp_rec.paye_agg_assignments,
                                                                 xx_rehire_emp_rec.second_nationality
                                                                ),
                      p_per_information10                 => COALESCE
                                                                (xx_rehire_emp_rec.opted_for_medicare,
                                                                 xx_rehire_emp_rec.dss_link_letter_end_date,
                                                                 xx_rehire_emp_rec.prefix
                                                                ),
                      p_per_information11                 => COALESCE
                                                                (xx_rehire_emp_rec.ethnicity_disclosed,
                                                                 xx_rehire_emp_rec.eighteen_years_below
                                                                ),
                      p_per_information13                 => xx_rehire_emp_rec.sex_entered_by,
                      p_per_information14                 => xx_rehire_emp_rec.ethnic_origin_entered_by,
                      p_per_information25                 => xx_rehire_emp_rec.vets_100a,
                      p_date_of_death                     => NULL,
                      p_background_check_status           => NULL,
                      p_background_date_check             => NULL,
                      p_blood_type                        => NULL,
                      p_correspondence_language           => xx_rehire_emp_rec.correspondence_language,
                      p_fast_path_employee                => NULL,
                      p_fte_capacity                      => NULL,
                      p_hold_applicant_date_until         => NULL,
                      p_honors                            => NULL,
                      p_internal_location                 => NULL,
                      p_last_medical_test_by              => NULL,
                      p_last_medical_test_date            => NULL,
                      p_mailstop                          => xx_rehire_emp_rec.mailstop,
                      p_office_number                     => xx_rehire_emp_rec.office_number,
                      p_on_military_service               => x_on_military_service,
                      p_pre_name_adjunct                  => xx_rehire_emp_rec.pre_name_adjunct,
                      p_projected_start_date              => NULL,
                      p_rehire_authorizor                 => NULL,
                      p_rehire_recommendation             => NULL,
                      p_resume_exists                     => NULL,
                      p_resume_last_updated               => NULL,
                      p_second_passport_exists            => NULL,
                      p_student_status                    => xx_rehire_emp_rec.student_status,
                      p_work_schedule                     => NULL,
                      p_rehire_reason                     => NULL,
                      p_suffix                            => xx_rehire_emp_rec.suffix,
                      p_benefit_group_id                  => NULL,
                      p_receipt_of_death_cert_date        => NULL,
                      p_coord_ben_med_pln_no              => NULL,
                      p_coord_ben_no_cvg_flag             => NULL,
                      p_coord_ben_med_ext_er              => NULL,
                      p_coord_ben_med_pl_name             => NULL,
                      p_coord_ben_med_insr_crr_name       => NULL,
                      p_coord_ben_med_insr_crr_ident      => NULL,
                      p_coord_ben_med_cvg_strt_dt         => NULL,
                      p_coord_ben_med_cvg_end_dt          => NULL,
                      p_uses_tobacco_flag                 => NULL,
                      p_dpdnt_adoption_date               => NULL,
                      p_dpdnt_vlntry_svce_flag            => NULL,
                      p_original_date_of_hire             => xx_rehire_emp_rec.original_date_of_hire,
                      p_adjusted_svc_date                 => xx_rehire_emp_rec.adjusted_svc_date,
                      p_town_of_birth                     => xx_rehire_emp_rec.town_of_birth,
                      p_region_of_birth                   => xx_rehire_emp_rec.region_of_birth,
                      p_country_of_birth                  => xx_rehire_emp_rec.country_of_birth,
                      p_global_person_id                  => NULL,
                      p_party_id                          => NULL,
                      p_npw_number                        => NULL,
                      p_effective_start_date              => x_per_effective_start_date,
                      p_effective_end_date                => x_per_effective_end_date,
                      p_full_name                         => x_full_name,
                      p_comment_id                        => x_comment_id,
                      p_name_combination_warning          => x_name_combination_warning,
                      p_assign_payroll_warning            => x_assign_payroll_warning,
                      p_orig_hire_warning                 => x_orig_hire_warning
                     );
                  xx_emf_pkg.write_log
                                  (xx_emf_cn_pkg.cn_low,
                                   'After calling hr_person_api.update_person'
                                  );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                     xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                       xx_emf_cn_pkg.cn_tech_error,
                                       l_sqlerrm,
                                       xx_rehire_emp_rec.attribute1,
                                       xx_rehire_emp_rec.record_number,
                                       xx_rehire_emp_rec.user_person_type,
                                       'Update Person API'
                                      );
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;

                     UPDATE xx_hr_emp_pre
                        SET ERROR_CODE = x_error_code
                      WHERE record_number = xx_rehire_emp_rec.record_number
                        AND batch_id = g_batch_id;

                     COMMIT;
               END;

               -- handle eit data
               SELECT COUNT (1)
                 INTO l_count
                 FROM per_people_extra_info
                WHERE person_id = l_person_id;

               IF l_count = 0
               THEN
                 IF xx_rehire_emp_rec.eit_information_type IS NOT NULL
                  THEN

                     create_eit_data (xx_rehire_emp_rec, l_person_id);
                  END IF;
               ELSE
                  update_eit_data (xx_rehire_emp_rec, l_person_id);
               END IF;
            END IF;                                -- person id not null check

            COMMIT;
         END LOOP;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_sqlerrm := SQLERRM;
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_high,
                              xx_emf_cn_pkg.cn_tech_error,
                              l_sqlerrm,
                              x_employee_number,
                              x_record_number,
                              x_person_type,
                              'rehire_and_update_employee'
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END rehire_and_update_employee;

----------------------------------------------------------------------
-------------------------< process_data >--------------------------
-- Debashis: added the TRUNC fucntion for HIRE_DATE and DATE_OF_BIRTH to avoid no_data_found error in CREATE_EMPLOYEE API -------
----------------------------------------------------------------------
      FUNCTION process_data (
         p_parameter_1   IN   VARCHAR2,
         p_parameter_2   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_return_status               VARCHAR2 (15)
                                                  := xx_emf_cn_pkg.cn_success;

         CURSOR xx_emp_cur
         IS
            SELECT   *
                FROM xx_hr_emp_pre
               WHERE NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                 AND batch_id = g_batch_id
                 AND (   rehire_flag IS NULL
                      OR rehire_flag NOT IN ('Yes', 'Y', 'YES')
                      OR (    rehire_flag IN ('Yes', 'Y', 'YES')
                          AND termination_date IS NOT NULL
                         )
                     )
            ORDER BY hire_date DESC;

         l_person_id                   NUMBER;
         x_person_id                   NUMBER;
         x_re_person_id                NUMBER;
         x_ppos_count                  NUMBER;
         x_assignment_id               NUMBER;
         x_per_object_version_number   NUMBER;
         x_asg_object_version_number   NUMBER;
         x_effective_start_date        DATE;
         x_per_effective_start_date    DATE;
         x_per_effective_end_date      DATE;
         x_effective_end_date          DATE;
         x_full_name                   VARCHAR2 (300);
         x_per_comment_id              NUMBER;
         x_assignment_sequence         NUMBER;
         x_assignment_number           VARCHAR2 (300);
         x_combination_warning         BOOLEAN;
         x_payroll_warning             BOOLEAN;
         x_assign_payroll_warning      BOOLEAN;
         x_orig_hire_warning           BOOLEAN;
         x_validate                    BOOLEAN                        := FALSE;
         x_business_group_id           NUMBER;
         x_employee_number             VARCHAR2 (40);
         l_sqlerrm                     VARCHAR2 (2000);
         x_type_cd                     VARCHAR2 (500);
         x_per_information1            VARCHAR2 (500)                  := NULL;
         x_nationality                 VARCHAR2 (500)                  := NULL;
         x_emp_attr_context   CONSTANT per_all_people_f.attribute_category%TYPE
                                                     := 'Global Data Elements';
         x_marital_status              VARCHAR2 (30);
         x_nationality_ethnic_error    VARCHAR2 (30)                    := 'S';
         l_pdp_object_version_number   NUMBER;
         x_hire_date                   DATE;
         xx_emp_rec                    g_xx_hr_cnv_pre_tab_type;
         x_person_extra_info_id        NUMBER;
         x_object_version_number       NUMBER;
         x_rehire_flag                 VARCHAR2 (1);
         x_on_military_service         VARCHAR2 (1)                    := NULL;

      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Process Data Start');

         FOR xx_emp_rec IN xx_emp_cur
         LOOP
            --Derive on military service
            SELECT DECODE (UPPER (xx_emp_rec.on_military_service),
                           'YES', 'Y',
                           'Y', 'Y',
                           'NO', 'N',
                           'N', 'N'
                          )
              INTO x_on_military_service
              FROM DUAL;

            --populate re-hire flag
            SELECT DECODE (xx_emp_rec.rehire_flag, 'Yes', 'Y', 'Y', 'Y', 'N')
              INTO x_rehire_flag
              FROM DUAL;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_rehire_flag is ' || x_rehire_flag
                                 );

            -- call create employee API -------
            BEGIN
               xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'The user person type id before API call is '
                             || xx_emp_rec.person_type_id
                            );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Business Group ID '
                                     || xx_emp_rec.business_group_id
                                     || ' '
                                     || xx_emp_rec.person_type_id
                                     || ' '
                                     || xx_emp_rec.sex
                                    );

               IF xx_emp_rec.user_person_type = g_emp_person_type
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'The person type is '
                                        || xx_emp_rec.user_person_type
                                       );

                  -- populate the hire date based on rehire flag
                  SELECT DECODE (x_rehire_flag,
                                 'Y', TRUNC (xx_emp_rec.original_date_of_hire),
                                 TRUNC (xx_emp_rec.hire_date)
                                )
                    INTO x_hire_date
                    FROM DUAL;

                  x_employee_number := NULL;--Added post CRP3 on 15-JUN-2012 for variable re-initialization

                  hr_employee_api.create_employee
                     (p_validate                       => g_validate_flag,
                      p_hire_date                      => x_hire_date,
                      p_business_group_id              => xx_emp_rec.business_group_id
                                                                 -- by deepika
                                                                                      ,
                      p_last_name                      => xx_emp_rec.last_name,
                      p_sex                            => xx_emp_rec.sex,
                      p_person_type_id                 => xx_emp_rec.person_type_id,
                      p_date_of_birth                  => TRUNC
                                                             (xx_emp_rec.date_of_birth
                                                             ),
                      p_email_address                  => xx_emp_rec.email_address,
                      p_employee_number                => x_employee_number,--xx_emp_rec.employee_number,-- Changed for crp2 test on 03-MAY-2012
                      p_first_name                     => xx_emp_rec.first_name,
                      p_known_as                       => xx_emp_rec.known_as,
                      p_marital_status                 => xx_emp_rec.marital_status
                                                                 -- by Deepika
                                                                                   ,
                      p_middle_names                   => xx_emp_rec.middle_names,
                      p_nationality                    => xx_emp_rec.nationality,
                      p_national_identifier            => xx_emp_rec.national_identifier,
                      p_previous_last_name             => xx_emp_rec.previous_last_name,
                      p_registered_disabled_flag       => NVL
                                                             (xx_emp_rec.registered_disabled_flag,
                                                              'N'
                                                             ),
                      p_title                          => xx_emp_rec.title,
                      p_attribute_category             => xx_emp_rec.attribute_category,
                      p_attribute1                     => xx_emp_rec.attribute1
--xx_emp_rec.country||'_'||COALESCE(xx_emp_rec.employee_number,xx_emp_rec.npw_number) --CountryCode_LegacyEmployeeNumber
                                                                               ,
                      p_attribute2                     => xx_emp_rec.attribute2
                                                   -- store the legacy_emp_num
                                                                               ,
                      p_attribute3                     => xx_emp_rec.attribute3,
                      p_attribute4                     => xx_emp_rec.attribute4,
                      p_attribute5                     => xx_emp_rec.attribute5,
                      p_attribute6                     => xx_emp_rec.attribute6,
                      p_attribute7                     => xx_emp_rec.attribute7,
                      p_attribute8                     => xx_emp_rec.attribute8,
                      p_attribute9                     => xx_emp_rec.attribute9,
                      p_attribute10                    => xx_emp_rec.attribute10,
                      p_per_information_category       => xx_emp_rec.country,
                      p_per_information1               => COALESCE
                                                             (--xx_emp_rec.ethnic_origin,
                                                              xx_emp_rec.work_per_num,
                                                              xx_emp_rec.rfc_id,
                                                              xx_emp_rec.maiden_name,
                                                              xx_emp_rec.ethnic_origin_gb,
                                                              xx_emp_rec.mother_maiden_name,
                                                              xx_emp_rec.professional_title,
                                                              xx_emp_rec.prev_employment_end_date,
                                                              xx_emp_rec.payroll_tax_state,
                                                              xx_emp_rec.work_per_num_nz
                                                             ),
                      p_per_information2               => COALESCE
                                                             (xx_emp_rec.i9_status,
                                                              xx_emp_rec.work_per_stat,
                                                              xx_emp_rec.federal_govt_affiliation_id,
                                                              xx_emp_rec.date_first_entry_france,
                                                              xx_emp_rec.director,
                                                              xx_emp_rec.ethnic_origin_ie,
                                                              xx_emp_rec.hereditary_title,
                                                              xx_emp_rec.child_allowance_reg,
                                                              xx_emp_rec.exclude_from_payroll_tax,
                                                              xx_emp_rec.work_per_expiry_date
                                                             ),
                      p_per_information3               => COALESCE
                                                             (xx_emp_rec.i9_expiration_date,
                                                              xx_emp_rec.work_per_end_dt,
                                                              xx_emp_rec.soc_sec_id,
                                                              xx_emp_rec.military_status,
                                                              xx_emp_rec.pensioner,
                                                              xx_emp_rec.last_name_at_birth,
                                                              xx_emp_rec.holiday_insurance_reg,
                                                              xx_emp_rec.ethnic_origin_nz
                                                             ),
                      p_per_information4               => COALESCE
                                                             (xx_emp_rec.mil_ser_id,
                                                              xx_emp_rec.cpam_name,
                                                              xx_emp_rec.work_per_num,
                                                              xx_emp_rec.hereditary_title_at_birth,
                                                              xx_emp_rec.pension_reg,
                                                              xx_emp_rec.tribal_group
                                                             ),
                      p_per_information5               => COALESCE
                                                             (xx_emp_rec.vets_100,
                                                              xx_emp_rec.soc_sec_med_cen,
                                                              xx_emp_rec.level_of_education,
                                                              xx_emp_rec.additional_pensionable_years,
                                                              xx_emp_rec.prefix_at_birth,
                                                              xx_emp_rec.id_number,
                                                              xx_emp_rec.district_of_origin
                                                             ),
                      p_per_information6               => COALESCE
                                                             (xx_emp_rec.mat_last_name,
                                                              xx_emp_rec.date_last_school_certificate,
                                                              xx_emp_rec.additional_pensionable_months,
                                                              xx_emp_rec.date_of_marriage,
                                                              xx_emp_rec.school_leaver,
                                                              xx_emp_rec.stat_nz_emp_cat
                                                             ),
                      p_per_information7               => COALESCE
                                                             (xx_emp_rec.new_hire_status,
                                                              xx_emp_rec.school_name,
                                                              xx_emp_rec.additional_pensionable_days,
                                                              xx_emp_rec.previous_prefix,
                                                              xx_emp_rec.stat_nz_working_time
                                                             ),
                      p_per_information8               => COALESCE
                                                             (xx_emp_rec.reason_for_exclusion,
                                                              xx_emp_rec.provisional_number,
                                                              xx_emp_rec.ni_multiple_assignments,
                                                              xx_emp_rec.eu_soc_insurance_num
                                                             ),
                      p_per_information9               => COALESCE
                                                             (xx_emp_rec.child_support_obligation,
                                                              xx_emp_rec.personal_email_id,
                                                              xx_emp_rec.paye_agg_assignments,
                                                              xx_emp_rec.second_nationality
                                                             ),
                      p_per_information10              => COALESCE
                                                             (xx_emp_rec.opted_for_medicare,
                                                              xx_emp_rec.dss_link_letter_end_date,
                                                              xx_emp_rec.prefix
                                                             ),
                      p_per_information11              => COALESCE
                                                             (xx_emp_rec.ethnicity_disclosed,
                                                              xx_emp_rec.eighteen_years_below
                                                             ),
                      p_per_information13              => xx_emp_rec.sex_entered_by,
                      p_per_information14              => xx_emp_rec.ethnic_origin_entered_by,
                      p_per_information25              => xx_emp_rec.vets_100a,
                      p_correspondence_language        => xx_emp_rec.correspondence_language,
                      p_mailstop                       => xx_emp_rec.mailstop
                                                       --As mentioned in FD1.1
                                                                             ,
                      p_office_number                  => xx_emp_rec.office_number,
                      p_on_military_service            => x_on_military_service,
                      p_pre_name_adjunct               => xx_emp_rec.pre_name_adjunct,
                      p_student_status                 => xx_emp_rec.student_status,
                      p_suffix                         => xx_emp_rec.suffix,
                      p_original_date_of_hire          => xx_emp_rec.original_date_of_hire,
                      p_adjusted_svc_date              => xx_emp_rec.adjusted_svc_date,
                      p_town_of_birth                  => xx_emp_rec.town_of_birth,
                      p_region_of_birth                => xx_emp_rec.region_of_birth,
                      p_country_of_birth               => xx_emp_rec.country_of_birth,
                      p_global_person_id               => xx_emp_rec.global_person_id,
                      p_party_id                       => NULL,
                      p_person_id                      => x_person_id,
                      p_assignment_id                  => x_assignment_id,
                      p_per_object_version_number      => x_per_object_version_number,
                      p_asg_object_version_number      => x_asg_object_version_number,
                      p_per_effective_start_date       => x_per_effective_start_date
                                                      --x_effective_start_date
                                                                                    ,
                      p_per_effective_end_date         => x_effective_end_date,
                      p_full_name                      => x_full_name,
                      p_per_comment_id                 => x_per_comment_id,
                      p_assignment_sequence            => x_assignment_sequence,
                      p_assignment_number              => x_assignment_number,
                      p_name_combination_warning       => x_combination_warning,
                      p_assign_payroll_warning         => x_payroll_warning,
                      p_orig_hire_warning              => x_orig_hire_warning
                     );
                  xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_low,
                                       'The person id of the new employee is '
                                    || x_person_id
                                   );

                  -- Terminate the employee if re-hire flag is 'Y'-------
                  IF x_person_id IS NOT NULL AND x_rehire_flag = 'Y'
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Rehire flag is yes'
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Person id is' || x_person_id
                                          );
                     xx_emp_rec.person_id := x_person_id;
                     xx_emp_rec.object_version_number :=
                                                   x_per_object_version_number;
                     x_error_code := terminate_employee (xx_emp_rec);
                     xx_emf_pkg.propagate_error (x_error_code);
                  END IF;                                 -- x_person_id check
               ELSIF xx_emp_rec.user_person_type = g_cwk_person_type
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'The system person type is '
                                        || xx_emp_rec.user_person_type
                                       );
                  -- Function to obtain person type id of the exact user_person_type for CWK system_person_type
                  xx_emp_rec.person_type_id :=
                     xx_hr_cwk_cnv_validations_pkg.get_cwk_orig_per_type_id
                                                 (xx_emp_rec.record_number,
                                                  xx_emp_rec.batch_id,
                                                  xx_emp_rec.business_group_id
                                                 );
                  hr_contingent_worker_api.create_cwk
                     (p_validate                       => g_validate_flag,
                      p_start_date                     => TRUNC
                                                             (xx_emp_rec.hire_date
                                                             ),
                      p_business_group_id              => xx_emp_rec.business_group_id,
                      p_last_name                      => xx_emp_rec.last_name,
                      p_person_type_id                 => xx_emp_rec.person_type_id,
                      p_npw_number                     => xx_emp_rec.npw_number,
                      p_correspondence_language        => xx_emp_rec.correspondence_language,
                      p_country_of_birth               => xx_emp_rec.country_of_birth,
                      p_date_of_birth                  => TRUNC
                                                             (xx_emp_rec.date_of_birth
                                                             ),
                      p_email_address                  => xx_emp_rec.email_address,
                      p_first_name                     => xx_emp_rec.first_name,
                      p_known_as                       => xx_emp_rec.known_as,
                      p_mailstop                       => NULL
                                  -- xx_emp_rec.mailstop As mentioned in FD1.1
                                                              ,
                      p_marital_status                 => xx_emp_rec.marital_status,
                      p_middle_names                   => xx_emp_rec.middle_names,
                      p_national_identifier            => xx_emp_rec.national_identifier
                                              --xx_emp_rec.national_identifier
                                                                                        ,
                      p_nationality                    => xx_emp_rec.nationality
                      --null                          --xx_emp_rec.nationality
                                                                                ,
                      p_office_number                  => xx_emp_rec.office_number,
                      p_on_military_service            => x_on_military_service,
                      p_party_id                       => NULL
                                                         --xx_emp_rec.party_id
                                                              ,
                      p_pre_name_adjunct               => xx_emp_rec.pre_name_adjunct,
                      p_previous_last_name             => xx_emp_rec.previous_last_name,
                      p_region_of_birth                => xx_emp_rec.region_of_birth,
                      p_registered_disabled_flag       => NVL
                                                             (xx_emp_rec.registered_disabled_flag,
                                                              'N'
                                                             ),
                      p_sex                            => xx_emp_rec.sex,
                      p_student_status                 => xx_emp_rec.student_status,
                      p_suffix                         => xx_emp_rec.suffix,
                      p_title                          => xx_emp_rec.title,
                      p_town_of_birth                  => xx_emp_rec.town_of_birth,
                      p_original_date_of_hire          => TRUNC
                                                             (xx_emp_rec.original_date_of_hire
                                                             ),
                      p_attribute_category             => xx_emp_rec.attribute_category,
                      p_attribute1                     => xx_emp_rec.attribute1
--xx_emp_rec.country||'_'||COALESCE(xx_emp_rec.employee_number,xx_emp_rec.npw_number)
                                                                               ,
                      p_attribute2                     => xx_emp_rec.attribute2,
                      p_attribute3                     => xx_emp_rec.attribute3,
                      p_attribute4                     => xx_emp_rec.attribute4,
                      p_attribute5                     => xx_emp_rec.attribute5,
                      p_attribute6                     => xx_emp_rec.attribute6,
                      p_attribute7                     => xx_emp_rec.attribute7,
                      p_attribute8                     => xx_emp_rec.attribute8,
                      p_attribute9                     => xx_emp_rec.attribute9,
                      p_attribute10                    => xx_emp_rec.attribute10,
                      p_per_information_category       => xx_emp_rec.country,
                      p_per_information1               => COALESCE
                                                             (--xx_emp_rec.ethnic_origin,
                                                              xx_emp_rec.work_per_num,
                                                              xx_emp_rec.rfc_id,
                                                              xx_emp_rec.maiden_name,
                                                              xx_emp_rec.ethnic_origin_gb,
                                                              xx_emp_rec.mother_maiden_name,
                                                              xx_emp_rec.professional_title,
                                                              xx_emp_rec.prev_employment_end_date,
                                                              xx_emp_rec.payroll_tax_state,
                                                              xx_emp_rec.work_per_num_nz
                                                             ),
                      p_per_information2               => COALESCE
                                                             (xx_emp_rec.i9_status,
                                                              xx_emp_rec.work_per_stat,
                                                              xx_emp_rec.federal_govt_affiliation_id,
                                                              xx_emp_rec.date_first_entry_france,
                                                              xx_emp_rec.director,
                                                              xx_emp_rec.ethnic_origin_ie,
                                                              xx_emp_rec.hereditary_title,
                                                              xx_emp_rec.child_allowance_reg,
                                                              xx_emp_rec.exclude_from_payroll_tax,
                                                              xx_emp_rec.work_per_expiry_date
                                                             ),
                      p_per_information3               => COALESCE
                                                             (xx_emp_rec.i9_expiration_date,
                                                              xx_emp_rec.work_per_end_dt,
                                                              xx_emp_rec.soc_sec_id,
                                                              xx_emp_rec.military_status,
                                                              xx_emp_rec.pensioner,
                                                              xx_emp_rec.last_name_at_birth,
                                                              xx_emp_rec.holiday_insurance_reg,
                                                              xx_emp_rec.ethnic_origin_nz
                                                             ),
                      p_per_information4               => COALESCE
                                                             (xx_emp_rec.mil_ser_id,
                                                              xx_emp_rec.cpam_name,
                                                              xx_emp_rec.work_per_num,
                                                              xx_emp_rec.hereditary_title_at_birth,
                                                              xx_emp_rec.pension_reg,
                                                              xx_emp_rec.tribal_group
                                                             ),
                      p_per_information5               => COALESCE
                                                             (xx_emp_rec.vets_100,
                                                              xx_emp_rec.soc_sec_med_cen,
                                                              xx_emp_rec.level_of_education,
                                                              xx_emp_rec.additional_pensionable_years,
                                                              xx_emp_rec.prefix_at_birth,
                                                              xx_emp_rec.id_number,
                                                              xx_emp_rec.district_of_origin
                                                             ),
                      p_per_information6               => COALESCE
                                                             (xx_emp_rec.mat_last_name,
                                                              xx_emp_rec.date_last_school_certificate,
                                                              xx_emp_rec.additional_pensionable_months,
                                                              xx_emp_rec.date_of_marriage,
                                                              xx_emp_rec.school_leaver,
                                                              xx_emp_rec.stat_nz_emp_cat
                                                             ),
                      p_per_information7               => COALESCE
                                                             (xx_emp_rec.new_hire_status,
                                                              xx_emp_rec.school_name,
                                                              xx_emp_rec.additional_pensionable_days,
                                                              xx_emp_rec.previous_prefix,
                                                              xx_emp_rec.stat_nz_working_time
                                                             ),
                      p_per_information8               => COALESCE
                                                             (xx_emp_rec.reason_for_exclusion,
                                                              xx_emp_rec.provisional_number,
                                                              xx_emp_rec.ni_multiple_assignments,
                                                              xx_emp_rec.eu_soc_insurance_num
                                                             ),
                      p_per_information9               => COALESCE
                                                             (xx_emp_rec.child_support_obligation,
                                                              xx_emp_rec.personal_email_id,
                                                              xx_emp_rec.paye_agg_assignments,
                                                              xx_emp_rec.second_nationality
                                                             ),
                      p_per_information10              => COALESCE
                                                             (xx_emp_rec.opted_for_medicare,
                                                              xx_emp_rec.dss_link_letter_end_date,
                                                              xx_emp_rec.prefix
                                                             ),
                      p_per_information11              => COALESCE
                                                             (xx_emp_rec.ethnicity_disclosed,
                                                              xx_emp_rec.eighteen_years_below
                                                             ),
                      p_per_information13              => xx_emp_rec.sex_entered_by,
                      p_per_information14              => xx_emp_rec.ethnic_origin_entered_by,
                      p_per_information25              => xx_emp_rec.vets_100a,
                      p_person_id                      => x_person_id,
                      p_per_object_version_number      => x_per_object_version_number,
                      p_per_effective_start_date       => x_per_effective_start_date,
                      p_per_effective_end_date         => x_per_effective_end_date,
                      p_pdp_object_version_number      => l_pdp_object_version_number,
                      p_full_name                      => x_full_name,
                      p_comment_id                     => x_per_comment_id,
                      p_assignment_id                  => x_assignment_id,
                      p_asg_object_version_number      => x_asg_object_version_number,
                      p_assignment_sequence            => x_assignment_sequence,
                      p_assignment_number              => x_assignment_number,
                      p_name_combination_warning       => x_combination_warning
                     );
               ELSIF     xx_emp_rec.user_person_type = g_cdt_person_type
                     AND g_validate_flag = FALSE
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'The person type is '
                                        || xx_emp_rec.user_person_type
                                       );
                  irc_party_api.create_candidate_internal
                     (p_validate                      => g_validate_flag,
                      p_business_group_id             => xx_emp_rec.business_group_id,
                      p_first_name                    => xx_emp_rec.first_name,
                      p_last_name                     => xx_emp_rec.last_name,
                      p_date_of_birth                 => TRUNC
                                                            (xx_emp_rec.date_of_birth
                                                            ),
                      p_email_address                 => xx_emp_rec.email_address,
                      p_title                         => xx_emp_rec.title,
                      p_gender                        => xx_emp_rec.sex,
                      p_marital_status                => xx_emp_rec.marital_status,
                      p_previous_last_name            => xx_emp_rec.previous_last_name,
                      p_middle_name                   => xx_emp_rec.middle_names,
                      p_name_suffix                   => xx_emp_rec.suffix,
                      p_known_as                      => xx_emp_rec.known_as,
                      p_attribute_category            => xx_emp_rec.attribute_category,
                      p_attribute1                    => xx_emp_rec.attribute1
                 -- for candidates, attribute1 will store the applicant number
                                                                              ,
                      p_attribute2                    => xx_emp_rec.attribute2,
                      p_attribute3                    => xx_emp_rec.attribute3,
                      p_attribute4                    => xx_emp_rec.attribute4,
                      p_attribute5                    => xx_emp_rec.attribute5,
                      p_attribute6                    => xx_emp_rec.attribute6,
                      p_attribute7                    => xx_emp_rec.attribute7,
                      p_attribute8                    => xx_emp_rec.attribute8,
                      p_attribute9                    => xx_emp_rec.attribute9,
                      p_attribute10                   => xx_emp_rec.attribute10,
                      p_per_information_category      => xx_emp_rec.country,
                      p_per_information1              => COALESCE
                                                            (--xx_emp_rec.ethnic_origin,
                                                             xx_emp_rec.work_per_num,
                                                             xx_emp_rec.rfc_id,
                                                             xx_emp_rec.maiden_name,
                                                             xx_emp_rec.ethnic_origin_gb,
                                                             xx_emp_rec.mother_maiden_name,
                                                             xx_emp_rec.professional_title,
                                                             xx_emp_rec.prev_employment_end_date,
                                                             xx_emp_rec.payroll_tax_state,
                                                             xx_emp_rec.work_per_num_nz
                                                            ),
                      p_per_information2              => COALESCE
                                                            (xx_emp_rec.i9_status,
                                                             xx_emp_rec.work_per_stat,
                                                             xx_emp_rec.federal_govt_affiliation_id,
                                                             xx_emp_rec.date_first_entry_france,
                                                             xx_emp_rec.director,
                                                             xx_emp_rec.ethnic_origin_ie,
                                                             xx_emp_rec.hereditary_title,
                                                             xx_emp_rec.child_allowance_reg,
                                                             xx_emp_rec.exclude_from_payroll_tax,
                                                             xx_emp_rec.work_per_expiry_date
                                                            ),
                      p_per_information3              => COALESCE
                                                            (xx_emp_rec.i9_expiration_date,
                                                             xx_emp_rec.work_per_end_dt,
                                                             xx_emp_rec.soc_sec_id,
                                                             xx_emp_rec.military_status,
                                                             xx_emp_rec.pensioner,
                                                             xx_emp_rec.last_name_at_birth,
                                                             xx_emp_rec.holiday_insurance_reg,
                                                             xx_emp_rec.ethnic_origin_nz
                                                            ),
                      p_per_information4              => COALESCE
                                                            (xx_emp_rec.mil_ser_id,
                                                             xx_emp_rec.cpam_name,
                                                             xx_emp_rec.work_per_num,
                                                             xx_emp_rec.hereditary_title_at_birth,
                                                             xx_emp_rec.pension_reg,
                                                             xx_emp_rec.tribal_group
                                                            ),
                      p_per_information5              => COALESCE
                                                            (xx_emp_rec.vets_100,
                                                             xx_emp_rec.soc_sec_med_cen,
                                                             xx_emp_rec.level_of_education,
                                                             xx_emp_rec.additional_pensionable_years,
                                                             xx_emp_rec.prefix_at_birth,
                                                             xx_emp_rec.id_number,
                                                             xx_emp_rec.district_of_origin
                                                            ),
                      p_per_information6              => COALESCE
                                                            (xx_emp_rec.mat_last_name,
                                                             xx_emp_rec.date_last_school_certificate,
                                                             xx_emp_rec.additional_pensionable_months,
                                                             xx_emp_rec.date_of_marriage,
                                                             xx_emp_rec.school_leaver,
                                                             xx_emp_rec.stat_nz_emp_cat
                                                            ),
                      p_per_information7              => COALESCE
                                                            (xx_emp_rec.new_hire_status,
                                                             xx_emp_rec.school_name,
                                                             xx_emp_rec.additional_pensionable_days,
                                                             xx_emp_rec.previous_prefix,
                                                             xx_emp_rec.stat_nz_working_time
                                                            ),
                      p_per_information8              => COALESCE
                                                            (xx_emp_rec.reason_for_exclusion,
                                                             xx_emp_rec.provisional_number,
                                                             xx_emp_rec.ni_multiple_assignments,
                                                             xx_emp_rec.eu_soc_insurance_num
                                                            ),
                      p_per_information9              => COALESCE
                                                            (xx_emp_rec.child_support_obligation,
                                                             xx_emp_rec.personal_email_id,
                                                             xx_emp_rec.paye_agg_assignments,
                                                             xx_emp_rec.second_nationality
                                                            ),
                      p_per_information10             => COALESCE
                                                            (xx_emp_rec.opted_for_medicare,
                                                             xx_emp_rec.dss_link_letter_end_date,
                                                             xx_emp_rec.prefix
                                                            ),
                      p_per_information11             => COALESCE
                                                            (xx_emp_rec.ethnicity_disclosed,
                                                             xx_emp_rec.eighteen_years_below
                                                            ),
                      p_per_information13             => xx_emp_rec.sex_entered_by,
                      p_per_information14             => xx_emp_rec.ethnic_origin_entered_by,
                      p_per_information25             => xx_emp_rec.vets_100a,
                      p_nationality                   => xx_emp_rec.nationality,
                      p_national_identifier           => xx_emp_rec.national_identifier,
                      p_town_of_birth                 => xx_emp_rec.town_of_birth,
                      p_region_of_birth               => xx_emp_rec.region_of_birth,
                      p_country_of_birth              => xx_emp_rec.country_of_birth,
                      p_allow_access                  => NULL,
                      p_party_id                      => NULL,
                      p_start_date                    => TRUNC
                                                            (xx_emp_rec.hire_date
                                                            ),
                      p_effective_start_date          => x_effective_start_date,
                      p_effective_end_date            => x_effective_end_date,
                      p_person_id                     => x_person_id
                     );
               END IF;                                   -- person type checkA

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'After create employee API call'
                                    );
            EXCEPTION
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'Inside exception for create employee API calls'
                          || SQLERRM
                          || 'Recno '
                          || xx_emp_rec.record_number
                          || ' Batch ID '
                          || g_batch_id
                         );
                  l_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    l_sqlerrm,
                                    COALESCE (xx_emp_rec.employee_number,
                                              xx_emp_rec.npw_number
                                             ),
                                    xx_emp_rec.record_number,
                                    xx_emp_rec.user_person_type,
                                    'Employee Creation'
                                   );
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;

                  UPDATE xx_hr_emp_pre
                     SET ERROR_CODE = x_error_code
                   WHERE record_number = xx_emp_rec.record_number
                     AND batch_id = g_batch_id;

                  COMMIT;
            END;

            -- handle EIT data

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'x_person_id'||x_person_id);
            IF x_person_id IS NOT NULL
            THEN
                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'eit_information_type'||xx_emp_rec.eit_information_type||'eit_information_category'||xx_emp_rec.eit_information_category);
               IF     xx_emp_rec.eit_information_type IS NOT NULL
                  AND xx_emp_rec.eit_information_category IS NOT NULL
               THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'eit information and category not null');
                  xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                         'The person id for hr_person_extra_info_api.create_person_extra_info is '
                      || x_person_id
                     );
                  create_eit_data (xx_emp_rec, x_person_id);
               END IF;           -- end if for information type not null check
            END IF;                              -- x_person_id not null check

            COMMIT;
         END LOOP;

         -- call rehire funtion to rehire and update employee
         x_error_code := rehire_and_update_employee;
         RETURN x_error_code;
      /* Added by Rohit Jain*/
      EXCEPTION
         WHEN OTHERS
         THEN
            l_sqlerrm := SQLERRM;
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                              l_sqlerrm
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END process_data;

----------------------------------------------------------------------
-------------------------< update_record_count >--------------------------
----------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_hr_emp_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_hr_emp_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_hr_emp_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_hr_emp_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) success_count
              FROM xx_hr_emp_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         x_success_cnt   NUMBER;
      BEGIN
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
      END update_record_count;
----------------------------------------------------------------------
   --------- begin of procedure MAIN --------
   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      -- Set environment for EMF (Error Management Framework)
      -- If you want the process to continue even after the emf env not being set
      -- you must make p_required_flag from CN_YES to CN_NO
      -- If you do not pass proper value then it will be considered as CN_YES
      set_cnv_env (p_batch_id           => p_batch_id,
                   p_required_flag      => xx_emf_cn_pkg.cn_yes
                  );

      -- include all the parameters to the conversion main here
      -- as medium log messages
      SELECT fnd_profile.VALUE ('per_business_group_id')
        INTO x_business_group_id
        FROM DUAL;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, x_business_group_id);
      xx_emf_pkg.write_log
           (xx_emf_cn_pkg.cn_high,
            'Object and Package Creation Filenames and their latest version  '
           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file1 || ' Version  '
                            || g_file1_ver
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file2 || ' Version  '
                            || g_file2_ver
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file3 || ' Version  '
                            || g_file3_ver
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file4 || ' Version  '
                            || g_file4_ver
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file5 || ' Version  '
                            || g_file5_ver
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file6 || ' Version  '
                            || g_file6_ver
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file7 || ' Version  '
                            || g_file7_ver
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                            'Filename ' || g_file8 || ' Version  '
                            || g_file8_ver
                           );
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_medium,
                         'Starting main process with the following parameters'
                        );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_batch_id ' || p_batch_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_restart_flag ' || p_restart_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_override_flag ' || p_override_flag
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Main:Param - p_validate_and_load '
                            || p_validate_and_load
                           );

      --popluate the global variable for validate flag
      IF p_validate_and_load = g_validate_and_load
      THEN
         g_validate_flag := FALSE;
      ELSE
         g_validate_flag := TRUE;
      END IF;

      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );

      -- Once the records are identified based on the input parameters
      -- Start with pre-validations
      IF NVL (p_override_flag, xx_emf_cn_pkg.cn_no) = xx_emf_cn_pkg.cn_no
      THEN
         -- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.cn_preval);
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After pre-validations X_ERROR_CODE '
                               || x_error_code
                              );
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         update_staging_records (xx_emf_cn_pkg.cn_success);
         xx_emf_pkg.propagate_error (x_error_code);
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;

      -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Data Validation 1'
                                    );

               IF    x_pre_std_hdr_table (i).user_person_type =
                                                             g_emp_person_type
                  OR x_pre_std_hdr_table (i).user_person_type =
                                                             g_cdt_person_type
               THEN
                  x_error_code :=
                     xx_hr_emp_cnv_validations_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      );
               ELSIF x_pre_std_hdr_table (i).user_person_type =
                                                             g_cwk_person_type
               THEN
                  x_error_code :=
                     xx_hr_cwk_cnv_validations_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      );
               END IF;

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Data Validation 2');
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Data Validation 3');
               xx_emf_pkg.propagate_error (x_error_code);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Data Validation 4');
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     x_pre_std_hdr_table (i).process_code
                                    );                         -------- DINESH
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Data Validation 5'
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Data Validation 6'
                                       );
                  xx_emf_pkg.write_log
                                    (xx_emf_cn_pkg.cn_low,
                                     'Process Level Error in Data Validations'
                                    );
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
--Change by rojain on 18-Dec-07
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Data Validation 7'
                                       );
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_pre_std_hdr_table (i).attribute2,
                                       x_pre_std_hdr_table (i).last_name
                                    || ', '
                                    || x_pre_std_hdr_table (i).first_name
                                   );
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  update_record_status (x_pre_std_hdr_table (i), x_error_code);
            END;
         END LOOP;

         xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'x_pre_std_hdr_table.count After Validation '
                              || x_pre_std_hdr_table.COUNT
                             );
         update_pre_interface_records (x_pre_std_hdr_table);
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_pre_std_hdr;
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               fnd_global.conc_request_id
                            || ' : Before Data Derivations'
                           );
      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   'Count of x_pre_std_hdr_table before data derivations is '
                || x_pre_std_hdr_table.COUNT
               );

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               xx_emf_pkg.write_log
                          (xx_emf_cn_pkg.cn_low,
                              'The user person type before data derivations '
                           || x_pre_std_hdr_table (i).user_person_type
                          );

               IF    x_pre_std_hdr_table (i).user_person_type =
                                                             g_emp_person_type
                  OR x_pre_std_hdr_table (i).user_person_type =
                                                             g_cdt_person_type
               THEN
                  xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      'Calling xx_hr_emp_cnv_validations_pkg.data_derivations'
                     );
                  x_error_code :=
                     xx_hr_emp_cnv_validations_pkg.data_derivations
                                                       (x_pre_std_hdr_table
                                                                           (i)
                                                       );
               ELSIF x_pre_std_hdr_table (i).user_person_type =
                                                             g_cwk_person_type
               THEN
                  xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      'Calling xx_hr_emp_cnv_validations_pkg.data_derivations'
                     );
                  x_error_code :=
                     xx_hr_cwk_cnv_validations_pkg.data_derivations
                                                       (x_pre_std_hdr_table
                                                                           (i)
                                                       );
               END IF;

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_low,
                                    'Process Level Error in Data derivations'
                                   );
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    SUBSTR (SQLERRM, 1, 2000),
                                    x_pre_std_hdr_table (i).attribute2,
                                       x_pre_std_hdr_table (i).last_name
                                    || ', '
                                    || x_pre_std_hdr_table (i).first_name
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'x_pre_std_hdr_table.count After Derivation '
                              || x_pre_std_hdr_table.COUNT
                             );
         update_pre_interface_records (x_pre_std_hdr_table);
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_pre_std_hdr;
      END IF;

      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.cn_postval);
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      -- x_error_code := xx_cn_trnx_validations_pkg.post_validations();
      x_error_code := xx_hr_emp_cnv_validations_pkg.post_validations ();
      -- dupatil added on 6dec07
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.cn_process_data);
      x_error_code := process_data (NULL, NULL);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'After Process Data');
      mark_records_complete (xx_emf_cn_pkg.cn_process_data);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After Mark records complete'
                           );
      xx_emf_pkg.propagate_error (x_error_code);
      update_record_count;
      xx_emf_pkg.create_report;
      COMMIT;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               xx_emf_pkg.cn_env_not_set
                              );
--         fnd_file.put_line (fnd_file.output, xx_emf_pkg.cn_env_not_set);
--         DBMS_OUTPUT.put_line (xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
   END main;
END xx_hr_emp_conversion_pkg;
/
