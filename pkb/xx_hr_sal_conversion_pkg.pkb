DROP PACKAGE BODY APPS.XX_HR_SAL_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_SAL_CONVERSION_PKG" 
AS
-----------------------------------------------------------------------------------------------------------
/*
 Created By    : Arjun K
 Creation Date : 11-JAN-2012
 File Name     : XXHRSALCNV.pkb
 Description   : This script creates the body of the package xx_hr_sal_conversion_pkg

COMMON GUIDELINES REGARDING EMF

-----------------------------------------------------------------------------------------------------------

1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED

 CHANGE History:

 DATE           NAME                  Remarks
 ------------   ------------------    ---------------------------------------
 11-JAN-2012    Arjun K               INITIAL development.
 11-JAN-2012    Arjun K               Case conversion removed for
                                      xx_sal_rec.proposal_reason in the API call.
 11-JAN-2012    Arjun K               reinitialized x_element_entry_id before api call
 11-JAN-2012    Arjun K               if change_date is less than Date_start then
                                      date_start would be considered as change_date
 11-JAN-2012    Arjun K               Fixed call to xx_cn_trnx_validations_pkg.post_validations
 11-JAN-2012    Arjun K               batch_id filter added while updating the pre interface table.
 11-JAN-2012    Arjun K               Change mad as per Ansell requirement
*/
-----------------------------------------------------------------------------------------------------------

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS

   --------------------------------------------------------------------------------
------------------< set_cnv_env >-----------------------------------------------
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
------------------< mark_records_for_processing >-------------------------------
--------------------------------------------------------------------------------
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
            DELETE FROM xx_hr_pay_prop_pre
                  WHERE batch_id = g_batch_id;

            UPDATE xx_hr_pay_prop_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_hr_pay_prop_pre
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;
      /*DELETE FROM cn_comm_lines_api_all
       WHERE attribute1 = G_BATCH_ID;*/--viswanath
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_hr_pay_prop_stg
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
         UPDATE xx_hr_pay_prop_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_hr_pay_prop_pre
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_hr_pay_prop_pre
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_hr_pay_prop_pre
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
         UPDATE xx_hr_pay_prop_pre
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
         UPDATE xx_hr_pay_prop_pre
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
         UPDATE xx_hr_pay_prop_pre
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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Message:' || SQLERRM);
   END mark_records_for_processing;

--------------------------------------------------------------------------------
------------------< set_stage >-------------------------------------------------
--------------------------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_hr_pay_prop_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;

      COMMIT;
   END update_staging_records;

   -- END RESTRICTIONS

   --------------------------------------------------------------------------------
------------------< main >------------------------------------------------------
--------------------------------------------------------------------------------
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
      x_pre_std_hdr_table   g_xx_hr_cnv_pre_tab_type;               --changed
      x_person_id           NUMBER;
      x_party_id            NUMBER;
      x_parent_table        VARCHAR2 (40);
      x_sqlerrm             VARCHAR2 (2000);

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   pay_proposal_id, assignment_id, person_id,
                  business_group_id, business_group_name, unique_id,
                  employee_number, change_date, next_perf_review_date,
                  next_sal_review_date, performance_rating, proposal_reason,
                  proposed_salary, date_to, attribute_category, approved,
                  multiple_components, forced_ranking, performance_review_id,
                  proposed_salary_n, attribute1, attribute2, attribute3,
                  attribute4, attribute5, attribute6, attribute7, attribute8,
                  attribute9, attribute10, attribute11, attribute12,
                  attribute13, attribute14, attribute15, attribute16,
                  attribute17, attribute18, attribute19, attribute20,
                  attribute21, attribute22, attribute23, attribute24,
                  attribute25, attribute26, attribute27, attribute28,
                  attribute29, attribute30, salary_basis, tax_unit_id,
                  pay_basis_id, batch_id, record_number, process_code,
                  ERROR_CODE, request_id, created_by, creation_date,
                  last_update_date, last_updated_by, last_update_login,
                  program_application_id, program_id, program_update_date
             FROM xx_hr_pay_prop_pre hdr
            WHERE 1 = 1
              AND batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                     (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                                                                          --KP
         ORDER BY employee_number, change_date;

-------------------------------------------------------------------------
-----------< update_record_status >--------------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_hr_cnv_pre_rec_type,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_hr_sal_cnv_validations_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.cn_success
                                          )
                                     );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

-------------------------------------------------------------------------
-----------< mark_records_complete >-------------------------------------
-------------------------------------------------------------------------
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_hr_pay_prop_pre
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
                last_updated_by = x_last_updated_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND process_code =
                   DECODE (p_process_code,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.cn_postval,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
      END mark_records_complete;

-------------------------------------------------------------------------
-----------< update_pre_interface_records >------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_hr_cnv_pre_tab_type
      )
      IS
         x_last_update_date         DATE   := SYSDATE;
         x_last_updated_by          NUMBER := fnd_global.user_id;
         x_last_update_login        NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_program_application_id   NUMBER := fnd_global.prog_appl_id;
         x_program_id               NUMBER := fnd_global.conc_program_id;
         x_program_update_date      DATE   := SYSDATE;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
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

            UPDATE xx_hr_pay_prop_pre
               SET pay_proposal_id =
                                p_cnv_pre_std_hdr_table (indx).pay_proposal_id,
                   unique_id = p_cnv_pre_std_hdr_table (indx).unique_id,
                   employee_number =
                                p_cnv_pre_std_hdr_table (indx).employee_number,
                   change_date = p_cnv_pre_std_hdr_table (indx).change_date,
                   next_perf_review_date =
                          p_cnv_pre_std_hdr_table (indx).next_perf_review_date,
                   next_sal_review_date =
                           p_cnv_pre_std_hdr_table (indx).next_sal_review_date,
                   performance_rating =
                             p_cnv_pre_std_hdr_table (indx).performance_rating,
                   proposal_reason =
                                p_cnv_pre_std_hdr_table (indx).proposal_reason,
                   proposed_salary =
                                p_cnv_pre_std_hdr_table (indx).proposed_salary,
                   attribute_category =
                             p_cnv_pre_std_hdr_table (indx).attribute_category,
                   approved = p_cnv_pre_std_hdr_table (indx).approved,
                   multiple_components =
                            p_cnv_pre_std_hdr_table (indx).multiple_components,
                   forced_ranking =
                                 p_cnv_pre_std_hdr_table (indx).forced_ranking,
                   performance_review_id =
                          p_cnv_pre_std_hdr_table (indx).performance_review_id,
                   proposed_salary_n =
                              p_cnv_pre_std_hdr_table (indx).proposed_salary_n,
                   attribute1 = p_cnv_pre_std_hdr_table (indx).attribute1,
                   attribute2 = p_cnv_pre_std_hdr_table (indx).attribute2,
                   attribute3 = p_cnv_pre_std_hdr_table (indx).attribute3,
                   attribute4 = p_cnv_pre_std_hdr_table (indx).attribute4,
                   attribute5 = p_cnv_pre_std_hdr_table (indx).attribute5,
                   salary_basis = p_cnv_pre_std_hdr_table (indx).salary_basis,
                   tax_unit_id = p_cnv_pre_std_hdr_table (indx).tax_unit_id,
                   pay_basis_id = p_cnv_pre_std_hdr_table (indx).pay_basis_id,
                   batch_id = p_cnv_pre_std_hdr_table (indx).batch_id,
                   record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number,
                   process_code = p_cnv_pre_std_hdr_table (indx).process_code,
                   ERROR_CODE = p_cnv_pre_std_hdr_table (indx).ERROR_CODE,
                   request_id = p_cnv_pre_std_hdr_table (indx).request_id,
                   last_updated_by = x_last_updated_by,
                   last_update_date = x_last_update_date,
                   last_update_login = x_last_update_login,
                   program_application_id = x_program_application_id,
                   program_id = x_program_id,
                   program_update_date = x_program_update_date
             WHERE record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number
               AND batch_id = g_batch_id;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

-------------------------------------------------------------------------
-----------< move_rec_pre_standard_table >-------------------------------
-------------------------------------------------------------------------
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
         INSERT INTO xx_hr_pay_prop_pre
                     (record_number, pay_proposal_id, business_group_name,
                      unique_id, employee_number, change_date,
                      proposal_reason, proposed_salary_n, approved,
                      next_sal_review_date, date_to, attribute_category,
                      attribute1, attribute2, attribute3, attribute4,
                      attribute5, attribute6, attribute7, attribute8,
                      attribute9, attribute10, attribute11, attribute12,
                      attribute13, attribute14, attribute15, attribute16,
                      attribute17, attribute18, attribute19, attribute20,
                      attribute21, attribute22, attribute23, attribute24,
                      attribute25, attribute26, attribute27, attribute28,
                      attribute29, attribute30, salary_basis, tax_unit_id,
                      pay_basis_id, batch_id, process_code, ERROR_CODE,
                      request_id, created_by, creation_date, last_update_date,
                      last_updated_by, last_update_login,
                      program_application_id, program_id, program_update_date)
            SELECT   record_number, NULL, business_group_name, unique_id,
                     employee_number, change_date, proposal_reason,
                     proposed_salary_n, approved, next_sal_review_date,
                     date_to, attribute_category, attribute1, attribute2,
                     attribute3, attribute4, attribute5, attribute6,
                     attribute7, attribute8, attribute9, attribute10,
                     attribute11, attribute12, attribute13, attribute14,
                     attribute15, attribute16, attribute17, attribute18,
                     attribute19, attribute20, attribute21, attribute22,
                     attribute23, attribute24, attribute25, attribute26,
                     attribute27, attribute28, attribute29, attribute30,
                     salary_basis, tax_unit_id, pay_basis_id, batch_id,
                     g_stage, ERROR_CODE, request_id, x_created_by,
                     x_creation_date, x_last_update_date, x_last_updated_by,
                     x_last_update_login, program_application_id, program_id,
                     program_update_date
                FROM xx_hr_pay_prop_stg
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval               --KP
                 AND request_id = xx_emf_pkg.g_request_id                 --KP
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                                                                          --KP
            ORDER BY employee_number, change_date;

         COMMIT;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_tech_error,
                       p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                       p_record_identifier_3      => 'move_rec_pre_standard_table'
                      );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

-------------------------------------------------------------------------
-----------< process_data >----------------------------------------------
-------------------------------------------------------------------------
      FUNCTION process_data (
         p_parameter_1   IN   VARCHAR2,
         p_parameter_2   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_return_status                  VARCHAR2 (15)
                                                  := xx_emf_cn_pkg.cn_success;

         /* Cursor Changed by viswanath,Instead of writting all columns should write SELECT* FROM */
         CURSOR xx_sal_cur
         IS
            SELECT   *
                FROM xx_hr_pay_prop_pre
               WHERE 1 = 1
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                 AND batch_id = g_batch_id
            ORDER BY employee_number, change_date;

         --order by person_id;

         -- ******************************************************************************
-- Cursor to fetch code for the meaning of PROPOSAL_REASON lookup type
-- ******************************************************************************
         CURSOR c_get_lookup_code (cp_proposal_reason_meaning VARCHAR2)
         IS
            SELECT lookup_code
              FROM fnd_lookup_values
             WHERE lookup_type = 'PROPOSAL_REASON'
               AND meaning = cp_proposal_reason_meaning
               AND TRUNC (SYSDATE) BETWEEN NVL (start_date_active,
                                                TRUNC (SYSDATE)
                                               )
                                       AND NVL (end_date_active, SYSDATE)
               AND enabled_flag = 'Y';

         l_person_id                      NUMBER;
         x_person_id                      NUMBER;
         x_assignment_id                  NUMBER;
         x_per_object_version_number      NUMBER;
         x_asg_object_version_number      NUMBER;
         x_effective_start_date           DATE;
         x_effective_end_date             DATE;
         x_full_name                      VARCHAR2 (300);
         x_per_comment_id                 NUMBER;
         x_assignment_sequence            NUMBER;
         x_assignment_number              VARCHAR2 (300);
         x_combination_warning            BOOLEAN;
         x_next_sal_date_warning          BOOLEAN;
         x_element_entry_id               NUMBER;
         x_object_version_number          NUMBER;
         x_pay_proposal_id                NUMBER;
         p_proposed_salary_warning        BOOLEAN;
         p_approved_warning               BOOLEAN;
         p_payroll_warning                BOOLEAN;
         x_payroll_warning                BOOLEAN;
         x_orig_hire_warning              BOOLEAN;
         x_proposal_reason                VARCHAR2 (900);
         x_proposal_reason_meaning        VARCHAR2 (900);
         x_validate                       BOOLEAN         := FALSE;
         x_employee_number                VARCHAR2 (40);
         l_sqlerrm                        VARCHAR2 (2000);
         x_date_start                     DATE;
         x_change_date                    DATE;
         l_effective_start_date           DATE;
         l_effective_end_date             DATE;
         x_assignment_id                  NUMBER;
         x_concatenated_segments          VARCHAR2 (2000);
         x_soft_coding_keyflex_id         NUMBER;
         x_comment_id                     NUMBER;
         x_other_manager_warning          BOOLEAN;
         x_hourly_salaried_warning        BOOLEAN;
         x_cagr_grade_def_id              NUMBER;
         x_cagr_concatenated_segments     VARCHAR2 (2000);
         x_gsp_post_process_warning       VARCHAR2 (2000);
         x_tax_district_changed_warning   BOOLEAN;
         x_entries_changed_warning        VARCHAR2 (2000);
         x_spp_delete_warning             BOOLEAN;
         x_org_now_no_manager_warning     BOOLEAN;
         x_speciax_ceiling_step_id        NUMBER          := NULL;
         x_asg_future_changes_warning     BOOLEAN;
         x_special_ceiling_step_id        NUMBER;
         x_people_group_id                NUMBER;
         x_no_managers_warning            BOOLEAN;
         x_group_name                     VARCHAR2 (1000);
         l_object_version_number          NUMBER;
         l_mode                           VARCHAR2 (30);
      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
         FOR xx_sal_rec IN xx_sal_cur
         LOOP
            BEGIN
               --- -- Added on 15-Feb-2013 Start
               x_special_ceiling_step_id := NULL;
               x_people_group_id := NULL;
               x_soft_coding_keyflex_id := NULL;
               x_group_name := NULL;
               x_effective_start_date := NULL;
               x_effective_end_date := NULL;
               x_org_now_no_manager_warning := NULL;
               x_other_manager_warning := NULL;
               x_spp_delete_warning := FALSE;
               x_entries_changed_warning := NULL;
               x_tax_district_changed_warning := FALSE;
               x_concatenated_segments := NULL;
               x_gsp_post_process_warning := NULL;
               -- -- Added on 15-Feb-End
               x_element_entry_id := NULL;

               SELECT MIN (date_start)
                 INTO x_date_start
                 FROM per_periods_of_service
                WHERE person_id = xx_sal_rec.person_id;

               x_change_date := xx_sal_rec.change_date;

               IF x_change_date < x_date_start
               THEN
                  x_change_date := x_date_start;
               END IF;

                     /*
               p_pay_proposal_id A sequential, process-generated primary key value.
                       p_assignment_id Identifies the assignment for which you create the salary proposal record.
                       p_business_group_id Uniquely identifies the business group of the person associated with the salary proposal.
                                             References HR_ALL_ORGANIZATION_UNITS.
                       p_change_date The date on which the proposal takes effect.
                       p_comments Comment text.
                       p_next_sal_review_date The date of the next salary review.
                       p_proposal_reason The proposal reason. Valid values are defined by
                                          lookup type 'PROPOSAL_REASON'.
                       p_proposed_salary_n The proposed salary for the employee.
                       p_forced_ranking The ranking of the person associated with the salary proposal.
                     */
               BEGIN
                  BEGIN
                     SELECT person_id, assignment_number,
                            effective_start_date, effective_end_date,
                            object_version_number
                       INTO x_person_id, x_assignment_number,
                            l_effective_start_date, l_effective_end_date,
                            l_object_version_number
                       FROM per_all_assignments_f
                      WHERE assignment_id = xx_sal_rec.assignment_id
                        AND business_group_id = xx_sal_rec.business_group_id
                        AND (effective_start_date =
                                (SELECT MAX (effective_start_date)
                                   FROM per_all_assignments_f
                                  WHERE assignment_id =
                                                      xx_sal_rec.assignment_id
                                    AND business_group_id =
                                                  xx_sal_rec.business_group_id
                                    AND effective_start_date <= x_change_date)
                            );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        xx_emf_pkg.error
                           (p_severity                 => xx_emf_cn_pkg.cn_medium,
                            p_category                 => xx_emf_cn_pkg.cn_tech_error,
                            p_error_text               =>    'Error while identifying assignment'
                                                          || SQLERRM,
                            p_record_identifier_1      => xx_sal_rec.employee_number,
                            p_record_identifier_2      => xx_sal_rec.business_group_name,
                            p_record_identifier_3      => xx_sal_rec.unique_id
                           );
                        x_error_code := xx_emf_cn_pkg.cn_rec_err;

                        UPDATE xx_hr_pay_prop_pre
                           SET ERROR_CODE = x_error_code,
                               process_code = xx_emf_cn_pkg.cn_process_data
                         WHERE batch_id = g_batch_id
                           AND record_number = xx_sal_rec.record_number;

                        COMMIT;
                  END;

                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Assignment Update'
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'x_assignment_number '
                                        || x_assignment_number
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'l_effective_date '
                                        || l_effective_start_date
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'l_object_version_number '
                                        || l_object_version_number
                                       );

                  IF xx_sal_rec.pay_basis_id IS NOT NULL
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Assignment Criteria Update'
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'x_assignment_number '
                                           || x_assignment_number
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_effective_date '
                                           || l_effective_start_date
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_object_version_number '
                                           || l_object_version_number
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'pay_basis_id '
                                           || xx_sal_rec.pay_basis_id
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'pay_basis_id '
                                           || xx_sal_rec.pay_basis_id
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'x_change_date ' || x_change_date
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_effective_start_date '
                                           || l_effective_start_date
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_effective_end_date '
                                           || l_effective_end_date
                                          );
                     
                     
                     
                     IF l_effective_start_date = x_change_date
                     THEN
                        l_mode := 'CORRECTION';
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_mode ' || l_mode
                                             );
                        per_asg_shd.g_old_rec := NULL; -- Added on 15-Feb-2013                     
                        hr_assignment_api.update_emp_asg_criteria
                           (p_effective_date                    => l_effective_start_date,
                            p_datetrack_update_mode             => l_mode,
                            p_assignment_id                     => xx_sal_rec.assignment_id,
                            p_validate                          => g_validate_flag,
                            p_called_from_mass_update           => FALSE,
                            p_pay_basis_id                      => xx_sal_rec.pay_basis_id,
                            p_object_version_number             => l_object_version_number,
                            p_special_ceiling_step_id           => x_special_ceiling_step_id,
                            p_people_group_id                   => x_people_group_id,
                            p_soft_coding_keyflex_id            => x_soft_coding_keyflex_id,
                            p_group_name                        => x_group_name,
                            p_effective_start_date              => x_effective_start_date,
                            p_effective_end_date                => x_effective_end_date,
                            p_org_now_no_manager_warning        => x_org_now_no_manager_warning,
                            p_other_manager_warning             => x_other_manager_warning,
                            p_spp_delete_warning                => x_spp_delete_warning,
                            p_entries_changed_warning           => x_entries_changed_warning,
                            p_tax_district_changed_warning      => x_tax_district_changed_warning,
                            p_concatenated_segments             => x_concatenated_segments,
                            p_gsp_post_process_warning          => x_gsp_post_process_warning
                           );
                     ELSIF     l_effective_start_date < x_change_date
                           AND l_effective_end_date <>
                                          TO_DATE ('12/31/4712', 'MM/DD/YYYY')
                     THEN
                        l_mode := 'UPDATE_CHANGE_INSERT';
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_mode ' || l_mode
                                             );
                        per_asg_shd.g_old_rec := NULL; -- Added on 15-Feb-2013                     
                        hr_assignment_api.update_emp_asg_criteria
                           (p_effective_date                    => x_change_date,
                            p_datetrack_update_mode             => l_mode,
                            p_assignment_id                     => xx_sal_rec.assignment_id,
                            p_validate                          => g_validate_flag,
                            p_called_from_mass_update           => FALSE,
                            p_pay_basis_id                      => xx_sal_rec.pay_basis_id,
                            p_object_version_number             => l_object_version_number,
                            p_special_ceiling_step_id           => x_special_ceiling_step_id,
                            p_people_group_id                   => x_people_group_id,
                            p_soft_coding_keyflex_id            => x_soft_coding_keyflex_id,
                            p_group_name                        => x_group_name,
                            p_effective_start_date              => x_effective_start_date,
                            p_effective_end_date                => x_effective_end_date,
                            p_org_now_no_manager_warning        => x_org_now_no_manager_warning,
                            p_other_manager_warning             => x_other_manager_warning,
                            p_spp_delete_warning                => x_spp_delete_warning,
                            p_entries_changed_warning           => x_entries_changed_warning,
                            p_tax_district_changed_warning      => x_tax_district_changed_warning,
                            p_concatenated_segments             => x_concatenated_segments,
                            p_gsp_post_process_warning          => x_gsp_post_process_warning
                           );
                     END IF;

                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'x_assignment_number '
                                           || x_assignment_number
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_effective_date '
                                           || l_effective_start_date
                                          );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'l_object_version_number '
                                           || l_object_version_number
                                          );
                     COMMIT;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                     --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_tech_error,
                         p_error_text               => x_sqlerrm,
                         p_record_identifier_1      => xx_sal_rec.employee_number,
                         p_record_identifier_2      => xx_sal_rec.business_group_name,
                         p_record_identifier_3      => 'Create Salary Basis for default assignment record'
                        );

                     UPDATE xx_hr_pay_prop_pre
                        SET ERROR_CODE = x_error_code,
                            process_code = xx_emf_cn_pkg.cn_process_data
                      WHERE batch_id = g_batch_id
                        AND record_number = xx_sal_rec.record_number;

                     COMMIT;
               END;

               IF g_validate_flag = FALSE
               THEN
                  hr_maintain_proposal_api.insert_salary_proposal
                     (p_pay_proposal_id                => x_pay_proposal_id,
                      p_assignment_id                  => xx_sal_rec.assignment_id,
                      p_business_group_id              => xx_sal_rec.business_group_id,
                      p_change_date                    => x_change_date,
                      p_comments                       => NULL,
                      p_next_sal_review_date           => xx_sal_rec.next_sal_review_date,
                      p_proposal_reason                => xx_sal_rec.proposal_reason
                                                           --x_proposal_reason
                                                                                    ,
                      p_proposed_salary_n              => xx_sal_rec.proposed_salary_n,
                      p_forced_ranking                 => NULL,
                      p_performance_review_id          => NULL,
                      p_attribute_category             => NULL,
                      p_attribute1                     => NULL,
                      p_attribute2                     => NULL,
                      p_attribute3                     => NULL,
                      p_attribute4                     => NULL,
                      p_attribute5                     => NULL,
                      p_attribute6                     => NULL,
                      p_attribute7                     => NULL,
                      p_attribute8                     => NULL,
                      p_attribute9                     => NULL,
                      p_attribute10                    => NULL,
                      p_attribute11                    => NULL,
                      p_attribute12                    => NULL,
                      p_attribute13                    => NULL,
                      p_attribute14                    => NULL,
                      p_attribute15                    => NULL,
                      p_attribute16                    => NULL,
                      p_attribute17                    => NULL,
                      p_attribute18                    => NULL,
                      p_attribute19                    => NULL,
                      p_attribute20                    => NULL,
                      p_object_version_number          => x_object_version_number,
                      p_multiple_components            => 'N',
                      p_approved                       => 'Y',
                      p_validate                       => g_validate_flag,
                      p_element_entry_id               => x_element_entry_id,
                      p_inv_next_sal_date_warning      => x_next_sal_date_warning,
                      p_proposed_salary_warning        => p_proposed_salary_warning,
                      p_approved_warning               => p_approved_warning,
                      p_payroll_warning                => p_payroll_warning
                     );
               END IF;
--added this exception for same data.
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               => x_sqlerrm,
                      p_record_identifier_1      => xx_sal_rec.employee_number,
                      p_record_identifier_2      => xx_sal_rec.business_group_name,
                      p_record_identifier_3      => 'create_salary' ----------
                     );

                  UPDATE xx_hr_pay_prop_pre
                     SET ERROR_CODE = x_error_code,
                         process_code = xx_emf_cn_pkg.cn_process_data
                   WHERE batch_id = g_batch_id
                     AND record_number = xx_sal_rec.record_number;

                  COMMIT;
            END;

            COMMIT;
         END LOOP;

         RETURN x_return_status;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_sqlerrm := SQLERRM;
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_high,
                   p_category                 => xx_emf_cn_pkg.cn_tech_error,
                   p_error_text               => x_sqlerrm,
                   p_record_identifier_3      => 'Process create_salary proposals'
                  );
            RETURN x_error_code;
      END process_data;

-------------------------------------------------------------------------
-----------< update_record_count >---------------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_hr_pay_prop_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_hr_pay_prop_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_hr_pay_prop_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_hr_pay_prop_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt (c_validate NUMBER)
         IS
            SELECT COUNT (1) succ_count
              FROM xx_hr_pay_prop_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code =
                      DECODE (c_validate,
                              1, process_code,
                              xx_emf_cn_pkg.cn_process_data
                             )
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         x_success_cnt   NUMBER;
         x_validate      NUMBER;
      BEGIN
         IF g_validate_flag = TRUE
         THEN
            x_validate := 1;
         ELSE
            x_validate := 0;
         END IF;

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

         OPEN c_get_success_cnt (x_validate);

         FETCH c_get_success_cnt
          INTO x_success_cnt;

         CLOSE c_get_success_cnt;

         xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                     p_success_recs_cnt      => x_success_cnt,
                                     p_warning_recs_cnt      => x_warn_cnt,
                                     p_error_recs_cnt        => x_error_cnt
                                    );
      END update_record_count;
-----------------------------------------------------------------------------

   ----  begin of procedure main starts here
   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      -- Set environment for EMF (Error Management Framework)
      -- If you want the process to continue even after the emf env not being set
      -- you must make p_required_flag from CN_YES to CN_NO
      -- If you do not pass proper value then it will be considered as CN_YES
      set_cnv_env (p_batch_id           => p_batch_id,
                   p_required_flag      => xx_emf_cn_pkg.cn_yes
                  );
      xx_emf_pkg.write_log
             (xx_emf_cn_pkg.cn_low,
              'The Versions of various objects used are printed here under...'
             );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Version of Staging Table:   '
                            || cn_xxhrsalstg_tbl
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Version of Staging Table Synonym in APPS:   '
                            || cn_xxhrsalstg_syn
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Version of Pre-Interface Table:   '
                            || cn_xxhrsalpre_tbl
                           );
      xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_low,
                          'Version of Pre-Interface Table Synonym in APPS:   '
                       || cn_xxhrsalpre_syn
                      );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Version of Validation Package Spec:   '
                            || cn_xxhrsalval_pks
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Version of Validation Package Body:   '
                            || cn_xxhrsalval_pkb
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Version of Conversion Package Spec:   '
                            || cn_xxhrsalcnv_pks
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Version of Conversion Package Body:   '
                            || cn_xxhrsalcnv_pkb
                           );
      -- include all the parameters to the conversion main here
      -- as medium log messages
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
------------------------------------------------------
----------( Stage 1: Pre Validations)-----------------
------------------------------------------------------
-- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.cn_preval);
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED

         --x_error_code := xx_hr_emp_cnv_validations_pkg.pre_validations ();
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
   ------------------------------------------------------
   ----------( Stage 2: Data Validations)----------------
   ------------------------------------------------------
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      LOOP                                                  --c_xx_pre_std_hdr
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               x_error_code :=
                  xx_hr_sal_cnv_validations_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      );
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
                                        ' In Exception 1:' || SQLERRM
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' In Exception 2:' || SQLERRM
                                       );
                  xx_emf_pkg.write_log
                                    (xx_emf_cn_pkg.cn_high,
                                     'Process Level Error in Data Validations'
                                    );
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' In Exception 3:' || SQLERRM
                                       );
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                      p_record_identifier_1      => x_pre_std_hdr_table (i).employee_number,
                      p_record_identifier_2      => x_pre_std_hdr_table (i).business_group_name,
                      p_record_identifier_3      => 'Stage 2:Data Validation'
                     );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
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

-- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
--IF p_validate_and_load = g_validate_and_load THEN
   -- Once data-validations are complete the loop through the pre-interface records
   -- and perform data derivations on this table
   -- Set the stage to data derivations
   ------------------------------------------------------
   ----------( Stage 3: Data Derivations)----------------
   ------------------------------------------------------
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Records Count:' || x_pre_std_hdr_table.COUNT
                              );

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               x_error_code :=
                  xx_hr_sal_cnv_validations_pkg.data_derivations
                                                      (x_pre_std_hdr_table (i)
                                                      );
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
                  xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   ' In Exception 1, During data derivation:'
                                || SQLERRM
                               );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   ' In Exception 2, During data derivation:'
                                || SQLERRM
                               );
                  xx_emf_pkg.write_log
                                    (xx_emf_cn_pkg.cn_high,
                                     'Process Level Error in Data derivations'
                                    );
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                      p_record_identifier_1      => x_pre_std_hdr_table (i).employee_number,
                      p_record_identifier_2      => x_pre_std_hdr_table (i).business_group_name,
                      p_record_identifier_3      => 'Stage 3:Data Derivation'
                     );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
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

   ------------------------------------------------------
   ----------( Stage 4: Post Validations)----------------
   ------------------------------------------------------
-- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.cn_postval);
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED

      --x_error_code := xx_cn_trnx_validations_pkg.post_validations();
      x_error_code := xx_hr_sal_cnv_validations_pkg.post_validations ();
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.cn_process_data);
      x_error_code := process_data (NULL, NULL);
      mark_records_complete (xx_emf_cn_pkg.cn_process_data);
      xx_emf_pkg.propagate_error (x_error_code);
      --END IF; -- For validate only flag check
      update_record_count;
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               xx_emf_pkg.cn_env_not_set
                              );
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
END xx_hr_sal_conversion_pkg; 
/
