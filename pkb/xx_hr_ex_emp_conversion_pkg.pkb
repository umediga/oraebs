DROP PACKAGE BODY APPS.XX_HR_EX_EMP_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_EX_EMP_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : Vasavi Chaikam
 Creation Date  : 09-Mar-07
 File Name      : XX_HR_EX_EMP_CNV.pkb
 Description    : This script creates the body of the package xx_hr_emp_conversion_pkg

COMMON GUIDELINES REGARDING EMF

-------------------------------

1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED

 Change History:

  Date          Name                 Remarks
 -----------   ------------          ---------------------------------------
 01-Nov-07     IBM Development    Initial development.
 09-Mar-2012   Vasavi Chaikam    Changed as per Integra
 27-Mar-2012 Vasavi             Change implemented for Final_process_date
 */
----------------------------------------------------------------------

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS

----------------------------------------------------------------------
--------------------------< set_cnv_env >--------------------------
----------------------------------------------------------------------
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
--------------------------< mark_records_for_processing >--------------------------
----------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2,
      p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- If the override is set records should not be purged from the pre-interface tables

      fnd_file.put_line (fnd_file.LOG,
                            'mark_records_for_processing  p_restart_flag = '
                         || p_restart_flag
                        );

      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN

            -- purge from pre-interface tables and oracle standard tables

            DELETE FROM xx_hr_ex_emp_pre
                  WHERE batch_id = g_batch_id;

            UPDATE xx_hr_ex_emp_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;

            fnd_file.put_line
                         (fnd_file.LOG,
                             'mark_records_for_processing  p_override_flag = '
                          || p_override_flag
                         );
         ELSE
            UPDATE xx_hr_ex_emp_pre
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;

            fnd_file.put_line
                         (fnd_file.LOG,
                             'mark_records_for_processing  p_override_flag = '
                          || p_override_flag
                         );
         END IF;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_hr_ex_emp_stg
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

         UPDATE xx_hr_ex_emp_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_hr_ex_emp_pre
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_hr_ex_emp_pre
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage

         UPDATE xx_hr_ex_emp_pre
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

         UPDATE xx_hr_ex_emp_pre
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

         UPDATE xx_hr_ex_emp_pre
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

         UPDATE xx_hr_ex_emp_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err);
      END IF;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                            'mark_records_for_processing  After Commit '
                         || SQL%ROWCOUNT
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (1, ' Message:' || SQLERRM);
   END;

----------------------------------------------------------------------
--------------------------< set_stage >--------------------------
----------------------------------------------------------------------
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
      UPDATE xx_hr_ex_emp_stg
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

   ----------------------------------------------------------------------
--------------------------< main >--------------------------
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
      x_pre_std_hdr_table   g_xx_hr_ex_cnv_pre_tab_type;
      x_update_rec_process_status NUMBER := 0; -- For updation of the report counts

      -- CURSOR FOR VARIOUS STAGES

      CURSOR c_xx_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   business_group_name, business_group_id, employee_number,
                  period_of_service_id, person_id, person_type_id,
                  leaving_reason, leaving_reason_code,
                  actual_termination_date, notified_termination_date,final_process_date,
                  object_version_number, user_person_type, person_type,
                  unique_id, first_name, last_name, term_user_status,
                  attribute1, assignment_status_type_id, batch_id,
                  record_number, process_code, ERROR_CODE, request_id
             FROM xx_hr_ex_emp_pre hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              --AND error_code   IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN) -- Changed by Rohit J
              AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

----------------------------------------------------------------------
--------------------------< update_record_status >--------------------------
----------------------------------------------------------------------
      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_hr_ex_cnv_pre_rec_type,
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
               xx_hr_ex_emp_cnv_validate_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.cn_success
                                          )
                                     );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
      END update_record_status;

----------------------------------------------------------------------
--------------------------< mark_records_complete >--------------------------
----------------------------------------------------------------------
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN

         UPDATE xx_hr_ex_emp_pre
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

----------------------------------------------------------------------
--------------------------< update_pre_interface_records >--------------------------
----------------------------------------------------------------------
      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_hr_ex_cnv_pre_tab_type
      )
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
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

            UPDATE xx_hr_ex_emp_pre
               SET process_code = p_cnv_pre_std_hdr_table (indx).process_code,
                   ERROR_CODE = p_cnv_pre_std_hdr_table (indx).ERROR_CODE,
                   request_id = p_cnv_pre_std_hdr_table (indx).request_id,
                   business_group_id =
                              p_cnv_pre_std_hdr_table (indx).business_group_id,
                   business_group_name =
                            p_cnv_pre_std_hdr_table (indx).business_group_name,
                   employee_number =
                                p_cnv_pre_std_hdr_table (indx).employee_number,
                   period_of_service_id =
                           p_cnv_pre_std_hdr_table (indx).period_of_service_id,
                   person_id = p_cnv_pre_std_hdr_table (indx).person_id,
                   person_type_id =
                                 p_cnv_pre_std_hdr_table (indx).person_type_id,
                   last_updated_by = x_last_updated_by,
                   last_update_date = x_last_update_date,
                   last_update_login = x_last_update_login,
                   leaving_reason =
                                 p_cnv_pre_std_hdr_table (indx).leaving_reason,
                   leaving_reason_code =
                            p_cnv_pre_std_hdr_table (indx).leaving_reason_code,
                   actual_termination_date =
                        p_cnv_pre_std_hdr_table (indx).actual_termination_date,
                   notified_termination_date =
                      p_cnv_pre_std_hdr_table (indx).notified_termination_date,
                   final_process_date =
                        p_cnv_pre_std_hdr_table (indx).final_process_date,
                   object_version_number =
                          p_cnv_pre_std_hdr_table (indx).object_version_number,
                   assignment_status_type_id =
                      p_cnv_pre_std_hdr_table (indx).assignment_status_type_id
             WHERE record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number
               AND batch_id = g_batch_id;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

----------------------------------------------------------------------
--------------------------< move_rec_pre_standard_table >--------------------------
----------------------------------------------------------------------
      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date           DATE                        := SYSDATE;
         x_created_by              NUMBER               := fnd_global.user_id;
         x_last_update_date        DATE                        := SYSDATE;
         x_last_updated_by         NUMBER               := fnd_global.user_id;
         x_last_update_login       NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_cnv_pre_std_hdr_table   g_xx_hr_ex_cnv_pre_tab_type;
         x_error_code              NUMBER         := xx_emf_cn_pkg.cn_success;
         p                         VARCHAR2 (100);
         q                         VARCHAR2 (100);
         r                         VARCHAR2 (100);
         s                         VARCHAR2 (100);
         x_temp                    NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );

         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table

         INSERT INTO xx_hr_ex_emp_pre
                     (batch_id, record_number, process_code, ERROR_CODE,
                      request_id, business_group_name, employee_number,
                      leaving_reason, actual_termination_date,
                      notified_termination_date,final_process_date,
                      user_person_type, first_name,
                      last_name, unique_id, attribute1, person_type,
                      term_user_status)
            SELECT batch_id, record_number, process_code, ERROR_CODE,
                   request_id, business_group_name, employee_number,
                   leaving_reason, actual_termination_date,
                   notified_termination_date, final_process_date,
                   user_person_type, first_name,
                   last_name, unique_id, attribute1, person_type,
                   term_user_status
              FROM xx_hr_ex_emp_stg
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         x_temp := SQL%ROWCOUNT;
         fnd_file.put_line (fnd_file.LOG,
                            ' No of Record inserted : ' || x_temp
                           );
         COMMIT;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

----------------------------------------------------------------------
--------------------------< process_data >--------------------------
----------------------------------------------------------------------
      FUNCTION process_data (
         p_parameter_1   IN   VARCHAR2,
         p_parameter_2   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_return_status                 VARCHAR2 (15)
                                                  := xx_emf_cn_pkg.cn_success;

         CURSOR xx_emp_cur
         IS
            SELECT *
              FROM xx_hr_ex_emp_pre
             WHERE ERROR_CODE IN
                       (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
               AND process_code = xx_emf_cn_pkg.cn_postval
               AND request_id = xx_emf_pkg.g_request_id
               AND batch_id = g_batch_id;

         /*x_emp_person_type      CONSTANT per_person_types.user_person_type%TYPE
                                                                 := 'Employee';
         x_ex_emp_person_type   CONSTANT per_person_types.user_person_type%TYPE
                                                              := 'Ex-employee';*/

         x_create_emp                    VARCHAR2 (1)                   := 'Y';
         x_person_id                     NUMBER;
         x_date_start                    DATE;
         x_person_type_id                NUMBER;         --:= hr_api.g_number;
         x_ex_person_type_id             NUMBER;
         x_assignment_id                 NUMBER;
         x_per_object_version_number     NUMBER;
         x_asg_object_version_number     NUMBER;
         x_effective_start_date          DATE;
         x_effective_end_date            DATE;
         x_full_name                     VARCHAR2 (300);
         x_per_comment_id                NUMBER;
         x_assignment_sequence           NUMBER;
         x_assignment_number             VARCHAR2 (300);
         x_combination_warning           BOOLEAN;
         x_payroll_warning               BOOLEAN;
         x_orig_hire_warning             BOOLEAN;
         x_validate_flag                 BOOLEAN                      := FALSE;
         x_employee_number               VARCHAR2 (40);
         l_sqlerrm                       VARCHAR2 (2000);
         x_sqlerrm                       VARCHAR2 (2000);
         x_effective_date                DATE                       := SYSDATE;
         x_period_of_service_id          per_periods_of_service.period_of_service_id%TYPE;
         x_object_version_number         NUMBER;
         x_actual_termination_date       DATE;
         x_last_standard_process_date    DATE                          ;
         x_assignment_status_type_id     NUMBER;        -- := hr_api.g_number;
         x_atd_new                       NUMBER;
         x_lspd_new                      NUMBER;
         x_supervisor_warning            BOOLEAN;
         x_event_warning                 BOOLEAN;
         x_interview_warning             BOOLEAN;
         x_review_warning                BOOLEAN;
         x_recruiter_warning             BOOLEAN;
         x_asg_future_changes_warning    BOOLEAN;
         x_entries_changed_warning       VARCHAR2 (1000);
         x_pay_proposal_warning          BOOLEAN;
         x_dod_warning                   BOOLEAN;
         x_alu_change_warning            VARCHAR2 (1000);
         x_type_cd                       VARCHAR2 (500);
         x_per_information1              VARCHAR2 (500)                := NULL;
         x_nationality                   VARCHAR2 (500)                := NULL;
         x_org_now_no_manager_warning    BOOLEAN;
         x_loc_identify                  VARCHAR2 (30);
         x_final_process_date            DATE                          := NULL;
         x_last_std_process_date_out     DATE;
         x_tem_person_id                 NUMBER;
         --- Gereral Variables
         error_flag                      VARCHAR (30)                   := 'N';
         x_marital_status                VARCHAR2 (30);
         x_nationality_ethnic_error      VARCHAR2 (30)                  := 'S';
         x_addl_rights_warning           BOOLEAN;
         x_person_type_usage_id          NUMBER;
      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.

         FOR xx_emp_rec IN xx_emp_cur
         LOOP
            x_object_version_number := xx_emp_rec.object_version_number;
            fnd_file.put_line (fnd_file.LOG,
                                  'Employee period of services id : '
                               || xx_emp_rec.period_of_service_id
                              );
            fnd_file.put_line (fnd_file.LOG,
                                  'Employee object version : '
                               || xx_emp_rec.object_version_number
                              );
            fnd_file.put_line (fnd_file.LOG,
                               'Employee person id : ' || xx_emp_rec.person_id
                              );
            fnd_file.put_line (fnd_file.LOG,
                                  'Employee person type id : '
                               || xx_emp_rec.person_type_id
                              );

         x_last_standard_process_date   := xx_emp_rec.actual_termination_date;


----------------------------------------------------------------------
--------------------------< Calling API >--------------------------
----------------------------------------------------------------------


            IF xx_emp_rec.employee_number IS NOT NULL
            THEN

               BEGIN
                  hr_ex_employee_api.actual_termination_emp
                     (p_validate                        => x_validate_flag,
                      p_effective_date                  => x_effective_date,
                      p_period_of_service_id            => xx_emp_rec.period_of_service_id,
                      p_object_version_number           => x_object_version_number,
                      p_actual_termination_date         => xx_emp_rec.actual_termination_date,
                      p_last_standard_process_date      => x_last_standard_process_date,
                      p_person_type_id                  => xx_emp_rec.person_type_id,
                      p_assignment_status_type_id       => xx_emp_rec.assignment_status_type_id,
                      p_leaving_reason                  => xx_emp_rec.leaving_reason_code,
                      p_attribute_category              => g_emp_attr_context,
                      p_attribute1                      =>(upper(xx_emp_rec.attribute1)),
                      p_attribute3                    => null,
		      p_attribute4                    => null,
		      p_attribute5                    => null,
		      p_attribute20                   => null,
		      p_pds_information_category      => null,
		      p_pds_information1              => null,
		      p_pds_information2              => null,
		      p_pds_information3              => null,
		      p_pds_information4              => null,
		      p_pds_information5              => null,
		      p_pds_information30             => null,
                      p_last_std_process_date_out     => x_last_std_process_date_out,
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

  /********************************************************/


  hr_ex_employee_api.final_process_emp
                   (p_validate                   => x_validate_flag
                   ,p_period_of_service_id       => xx_emp_rec.period_of_service_id
                   ,p_object_version_number      => x_object_version_number
                   ,p_final_process_date         => xx_emp_rec.final_process_date
                   ,p_org_now_no_manager_warning => x_org_now_no_manager_warning
                   ,p_asg_future_changes_warning => x_asg_future_changes_warning
                   ,p_entries_changed_warning    => x_entries_changed_warning
                   );



 /******************************************************/
                     hr_ex_employee_api.update_term_details_emp
                     (p_validate                         => x_validate_flag,
                      p_effective_date                   => SYSDATE,
                      p_period_of_service_id             => xx_emp_rec.period_of_service_id,
                      p_object_version_number            => x_object_version_number,
                      p_termination_accepted_person      => NULL,
                      p_accepted_termination_date        => NULL,
                      p_comments                         => NULL,
                      p_leaving_reason                   => xx_emp_rec.leaving_reason_code,
                      p_notified_termination_date        => xx_emp_rec.notified_termination_date,
                      p_projected_termination_date       => NULL
                     );
/********************************************************/

                  IF xx_emp_rec.leaving_reason_code = 'R'
                  THEN
                     SELECT pptu.person_type_usage_id,
                            pptu.object_version_number
                       INTO x_person_type_usage_id,
                            x_object_version_number
                       FROM per_all_people_f papf,
                            per_person_type_usages_f pptu
                      WHERE papf.person_id = pptu.person_id
                        AND papf.business_group_id =
                                                  xx_emp_rec.business_group_id
                        AND papf.employee_number = xx_emp_rec.employee_number
                        AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                                AND papf.effective_end_date
                        AND TRUNC (SYSDATE) BETWEEN pptu.effective_start_date
                                                AND pptu.effective_end_date;

                     SELECT ppt.person_type_id
                       INTO x_person_type_id
                       FROM per_person_types ppt
                      WHERE ppt.default_flag = 'Y'
                        AND ppt.active_flag = 'Y'
                        AND ppt.business_group_id =
                                                xx_emp_rec.business_group_id
                        AND ppt.system_person_type = 'RETIREE';

/***************************************************/
                     hr_person_type_usage_api.update_person_type_usage
                          (p_validate                   => FALSE,
                           p_person_type_usage_id       => x_person_type_usage_id,
                           p_effective_date             => TRUNC (SYSDATE),
                           p_datetrack_mode             => 'CORRECTION',
                           p_object_version_number      => x_object_version_number,
                           p_person_type_id             => x_person_type_id,
                           p_effective_start_date       => x_effective_start_date,
                           p_effective_end_date         => x_effective_end_date
                          );
/************************************************************/
                  END IF;

/*******************************************/
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_tech_error,
                         p_error_text               => x_sqlerrm,
                         p_record_identifier_1      => xx_emp_rec.record_number,
                         p_record_identifier_2      => xx_emp_rec.unique_id,
                         p_record_identifier_3      => 'EMP TERM API'
                        );

                     UPDATE xx_hr_ex_emp_pre
                        SET ERROR_CODE = x_error_code,
                            process_code = xx_emf_cn_pkg.cn_process_data
                      WHERE batch_id = g_batch_id
                        AND record_number = xx_emp_rec.record_number;

                     COMMIT;
               END;

            END IF;

            x_org_now_no_manager_warning := NULL;
            x_asg_future_changes_warning := NULL;
            x_entries_changed_warning := NULL;

            COMMIT;
         END LOOP;

         RETURN x_return_status;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_sqlerrm := SQLERRM;
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_high,
                              xx_emf_cn_pkg.cn_tech_error,
                              l_sqlerrm
                             );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            RETURN x_error_code;
      END process_data;

----------------------------------------------------------------------
--------------------------< update_record_count >--------------------------
----------------------------------------------------------------------


      PROCEDURE update_record_count (p_update_rec_process_status IN NUMBER)
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_hr_ex_emp_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_hr_ex_emp_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_hr_ex_emp_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_hr_ex_emp_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_hr_ex_emp_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code = decode(p_update_rec_process_status,1,xx_emf_cn_pkg.cn_process_data,process_code)
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
   --------------------------< MAIN PROCEDURE BEGINS HERE  >--------------------------
   ----------------------------------------------------------------------


   BEGIN
      retcode := xx_emf_cn_pkg.cn_success;
      -- Set environment for EMF (Error Management Framework)
      -- If you want the process to continue even after the emf env not being set
      -- you must make p_required_flag from CN_YES to CN_NO
      -- If you do not pass proper value then it will be considered as CN_YES

      set_cnv_env (p_batch_id           => p_batch_id,
                   p_required_flag      => xx_emf_cn_pkg.cn_yes
                  );

      fnd_file.put_line (fnd_file.LOG,
                         ' After Set CNV ENV : ' || xx_emf_pkg.g_request_id
                        );
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

      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability

      --------------Calling mark_records_for_processing-----------

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
                                  'Before pre-validations X_ERROR_CODE '
                               || x_error_code
                              );

      --------------------- Pre validations procedure invoked-----------------

      x_error_code := xx_hr_ex_emp_cnv_validate_pkg.pre_validations ();

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After pre-validations X_ERROR_CODE '
                               || x_error_code
                              );
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_medium,
                'Before updating staging recors pre-validations X_ERROR_CODE '
             || x_error_code
            );

      --------------------- updating staging records-----------------

         update_staging_records (xx_emf_cn_pkg.cn_success);

         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_medium,
                                'After updating staging records X_ERROR_CODE '
                             || x_error_code
                            );
         xx_emf_pkg.propagate_error (x_error_code);
         xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_medium,
                         'before moving to pre interface tables X_ERROR_CODE '
                      || x_error_code
                     );

         x_error_code := move_rec_pre_standard_table;

         xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_medium,
                          'After moving to pre interface tables X_ERROR_CODE '
                       || x_error_code
                      );

         xx_emf_pkg.propagate_error (x_error_code);

      END IF;



      -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations


      set_stage (xx_emf_cn_pkg.cn_valid);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After move_rec_pre_standard_table'
                           );

      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN

               -- Perform header level Base App Validations

               xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_low,
                          'Before calling the data validations x_error_code '
                       || x_error_code
                      );

 ---------------------- Data validation procude being invoked-----------------------

               x_error_code := xx_hr_ex_emp_cnv_validate_pkg.data_validations
                                                       (x_pre_std_hdr_table (i));

               xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'After calling the data validations x_error_code '
                         || x_error_code
                        );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );

 --------------------- update_record_status -------------------

 update_record_status (x_pre_std_hdr_table (i), x_error_code);

 xx_emf_pkg.propagate_error (x_error_code);


 EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity

               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data Validations'
                                   );

               --------------------- update_pre_interface_records invoked-----------------

               update_pre_interface_records (x_pre_std_hdr_table);

               raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);

               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_pre_std_hdr_table (i).record_number,
                                    x_pre_std_hdr_table (i).unique_id
                                   );
            END;
         END LOOP;


         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
                               || x_pre_std_hdr_table.COUNT
                              );

         --------------------- update_pre_interface_records procedure invoked-----------------

         update_pre_interface_records (x_pre_std_hdr_table);

         x_pre_std_hdr_table.DELETE;

         EXIT WHEN c_xx_pre_std_hdr%NOTFOUND;

      END LOOP;

      xx_emf_pkg.write_log
                (xx_emf_cn_pkg.cn_low,
                 'After Data Validation Call and update_pre_interface_records'
                );


      IF c_xx_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_pre_std_hdr;
      END IF;

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations

      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               fnd_file.put_line (fnd_file.LOG,
                                     'Data Derivation 1 business group id : '
                                  || x_pre_std_hdr_table (i).business_group_id
                                 );

      -------------------------- Perform header level Base App Validations----------
      --------------------- Data derivations procedure invoked-----------------

      x_error_code :=
                  xx_hr_ex_emp_cnv_validate_pkg.data_derivations
                                                       (x_pre_std_hdr_table(i));

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );

      update_record_status (x_pre_std_hdr_table (i), x_error_code);

      xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'After  update record_status x_error_code:'
                                || x_error_code
                               );
               xx_emf_pkg.propagate_error (x_error_code);

      EXCEPTION

               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity

      WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data derivations'
                                   );
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_pre_std_hdr_table (i).record_number,
                                    x_pre_std_hdr_table (i).unique_id
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

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After Data Derivation Call '
                           );



      IF c_xx_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_pre_std_hdr;
      END IF;

      -- Set the stage to Pre Validations

      set_stage (xx_emf_cn_pkg.cn_postval);

      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED


      x_error_code := xx_hr_ex_emp_cnv_validate_pkg.post_validations ();


      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );

      --------------------- Mark records for complete procedure invoked-----------------

      mark_records_complete (xx_emf_cn_pkg.cn_postval);

      xx_emf_pkg.propagate_error (x_error_code);

      IF p_validate_and_load = g_validate_and_load
      THEN

      -- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.cn_process_data);
         x_error_code := process_data (NULL, NULL);

      mark_records_complete (xx_emf_cn_pkg.cn_process_data);

      xx_emf_pkg.propagate_error (x_error_code);
         x_update_rec_process_status := 1;

      END IF;
--------------------- update record count procedure invoked-----------------

      update_record_count(x_update_rec_process_status);

      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         fnd_file.put_line (fnd_file.output, xx_emf_pkg.cn_env_not_set);
         DBMS_OUTPUT.put_line (xx_emf_pkg.cn_env_not_set);
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
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
   END main;
END xx_hr_ex_emp_conversion_pkg;
/
