DROP PACKAGE BODY APPS.XX_HR_ASG_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_ASG_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development
 Creation Date  : 30-Dec-2011
 File Name      : XXHRASGCNV.pkb
 Description    : This script creates the body of the package xx_hr_asg_conversion_pkg
COMMON GUIDELINES REGARDING EMF
-------------------------------
1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED
 Change History:
  Date         Name             Remarks
 -----------   ------------     ---------------------------------------
30-DEC-2011    IBM Development  Initial Development
25-JAN-2012    Deepika Jain     Modified for Integra
23-FEB-2012    Arjun K.         Included update_assignment_mappings proc for Integra
09-MAY-2012    Dinesh           Modified APi parameter assignment number to accept x_assignment_number during mock conv
30-MAY-2012    MuthuKumar       Updated the procedure update_assignment_mappings as per TS post CRP3
01-JUN-2012    Arjun K.         Code was corrected to look at all employee types apart from 'EMPLOYEE' as contingent workers
01-JUN-2012    Arjun K.         x_freq_unit passed to p_frequency for the API hr_assignment_api.update_cwk_asg instead of the
                                staging table value directly
*/
----------------------------------------------------------------------
   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS
--------------------------------------------------------------------------------
---------------------------< set_cnv_env >---------------------------------
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
---------------------------< mark_records_for_processing >---------------------------------
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
            DELETE FROM xx_hr_asg_pre
                  WHERE batch_id = g_batch_id;

            UPDATE xx_hr_asg_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_hr_asg_pre
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;
      /*DELETE FROM cn_comm_lines_api_all
       WHERE attribute1 = G_BATCH_ID;*/--Dipyaman
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_hr_asg_stg
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
         UPDATE xx_hr_asg_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_hr_asg_pre
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_hr_asg_pre
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_hr_asg_pre
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
         UPDATE xx_hr_asg_pre
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
         UPDATE xx_hr_asg_pre
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
         UPDATE xx_hr_asg_pre
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
         fnd_file.put_line (1, ' Message:' || SQLERRM);
   END;

--------------------------------------------------------------------------------
---------------------------< update assignment mapping >------------------------
--------------------------------------------------------------------------------
   PROCEDURE update_assignment_mappings
   IS
      CURSOR xx_asg_cur_trans
      IS
         SELECT *
           FROM xx_hr_asgtrans_stg;
   BEGIN
      FOR xx_asg_rec_trans IN xx_asg_cur_trans
      LOOP
         UPDATE xx_hr_asg_stg
            SET job_name = xx_asg_rec_trans.job_name,
                pos_title = xx_asg_rec_trans.pos_name,
                grade_name = xx_asg_rec_trans.grade_name,
                ORGANIZATION = xx_asg_rec_trans.ORGANIZATION,
                LOCATION = xx_asg_rec_trans.LOCATION,
                gov_rep_entity = xx_asg_rec_trans.government_reporting_entity,
                sob_name = xx_asg_rec_trans.ledger_name,
                acct_seg1 = xx_asg_rec_trans.default_exp_acc_1,
                acct_seg2 = xx_asg_rec_trans.default_exp_acc_2,
                acct_seg3 = xx_asg_rec_trans.default_exp_acc_3,
                acct_seg4 = xx_asg_rec_trans.default_exp_acc_4,
                acct_seg5 = xx_asg_rec_trans.default_exp_acc_5,
                acct_seg6 = xx_asg_rec_trans.default_exp_acc_6,
                acct_seg7 = xx_asg_rec_trans.default_exp_acc_7,
                acct_seg8 = xx_asg_rec_trans.default_exp_acc_8,
                acct_seg9 = xx_asg_rec_trans.default_exp_acc_9,
                shift_us  = xx_asg_rec_trans.shift
          WHERE person_unique_id = xx_asg_rec_trans.unique_id
            AND batch_id = g_batch_id;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (1, ' update_assignment_mappings:' || SQLERRM);
   END;

--------------------------------------------------------------------------------
---------------------------< set_stage >---------------------------------
--------------------------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

--------------------------------------------------------------------------------
---------------------------< update_staging_records >---------------------------
--------------------------------------------------------------------------------
   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_hr_asg_stg
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
         fnd_file.put_line (1, 'update_staging_records:' || SQLERRM);
   END update_staging_records;

   -- END RESTRICTIONS

   --------------------------------------------------------------------------------
   ---------------------------< get_org_mapping_value >----------------------------
   --------------------------------------------------------------------------------
   FUNCTION get_org_mapping_value (
      p_mapping_type   IN   VARCHAR2,
      p_old_value      IN   VARCHAR2,
      p_attribute1     IN   VARCHAR2 DEFAULT NULL,
      p_attribute2     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   AS
      x_new_value   VARCHAR2 (200);
   BEGIN
      -- p_attribute2 is currently not in use --
      SELECT DISTINCT new_value1
                 INTO x_new_value
                 FROM xx_hr_mapping
                WHERE mapping_type = p_mapping_type
                  AND old_value1 = p_old_value
                  -- AND nvl(attribute1,'XXXX')   = nvl(p_attribute1,'XXXX')
                  AND ROWNUM = 1;

      RETURN x_new_value;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            -- if attribute1 is not matching, check the column with null value
            SELECT DISTINCT new_value1
                       INTO x_new_value
                       FROM xx_hr_mapping
                      WHERE mapping_type = p_mapping_type
                        AND old_value1 = p_old_value
                        -- AND attribute1  is null
                        AND ROWNUM = 1;

            RETURN x_new_value;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN p_old_value;
            WHEN OTHERS
            THEN
               RETURN p_old_value;
         END;
      WHEN OTHERS
      THEN
         RETURN p_old_value;
   END get_org_mapping_value;

--------------------------------------------------------------------------------
---------------------------< main >---------------------------------
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
      x_pre_std_hdr_table   g_xx_asg_cnv_pre_tab_type;

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   *
             FROM xx_hr_asg_pre hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
              AND NVL (effective_start_date, SYSDATE) =
                     (SELECT NVL (MAX (pre2.effective_start_date), SYSDATE)
                        FROM xx_hr_asg_pre pre2
                       WHERE pre2.batch_id = g_batch_id
                         AND hdr.record_number = pre2.record_number)
         --  and pre2.assignment_status <> 'Terminate Assignment')-- commented for integra
         ORDER BY record_number;

--------------------------------------------------------------------------------
---------------------------< update_record_status >--------------------------
--------------------------------------------------------------------------------
      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_asg_cnv_pre_rec_type,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' xx_emf_cn_pkg.CN_REC_ERR '
                                  || xx_emf_cn_pkg.cn_rec_err
                                 );
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' p_conv_pre_std_hdr_rec.error_code '
                                  || p_conv_pre_std_hdr_rec.ERROR_CODE
                                 );
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_hr_asg_cnv_validations_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.cn_success
                                          )
                                     );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' p_conv_pre_std_hdr_rec.error_code '
                                  || p_conv_pre_std_hdr_rec.ERROR_CODE
                                 );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' p_conv_pre_std_hdr_rec.process_code '
                               || p_conv_pre_std_hdr_rec.process_code
                              );
      END update_record_status;

--------------------------------------------------------------------------------
---------------------------< mark_records_complete >------------------------
--------------------------------------------------------------------------------
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_error               NUMBER;
      --PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_hr_asg_pre
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
            AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'mark_records_complete Update');
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'mark_records_complete Error');
      END mark_records_complete;

--------------------------------------------------------------------------------
---------------------------< update_pre_interface_records >------------------
--------------------------------------------------------------------------------
      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_asg_cnv_pre_tab_type
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
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'p_cnv_pre_std_hdr_table(indx).record_number '
                             || p_cnv_pre_std_hdr_table (indx).record_number
                            );

            UPDATE xx_hr_asg_pre
               SET business_group_name =
                      p_cnv_pre_std_hdr_table (indx).business_group_name
                                                          -- Added for Integra
                                                                        ,
                   employee_number =
                                p_cnv_pre_std_hdr_table (indx).employee_number,
                   first_name = p_cnv_pre_std_hdr_table (indx).first_name,
                   last_name = p_cnv_pre_std_hdr_table (indx).last_name,
                   hire_date = p_cnv_pre_std_hdr_table (indx).hire_date,
                   assignment_number =
                              p_cnv_pre_std_hdr_table (indx).assignment_number,
                   assignment_status =
                              p_cnv_pre_std_hdr_table (indx).assignment_status,
                   country = p_cnv_pre_std_hdr_table (indx).country,
                   primary_flag = p_cnv_pre_std_hdr_table (indx).primary_flag,
                   assignment_category =
                            p_cnv_pre_std_hdr_table (indx).assignment_category,
                   ORGANIZATION = p_cnv_pre_std_hdr_table (indx).ORGANIZATION,
                   LOCATION = p_cnv_pre_std_hdr_table (indx).LOCATION,
                   work_at_home = p_cnv_pre_std_hdr_table (indx).work_at_home,
                   person_type = p_cnv_pre_std_hdr_table (indx).person_type,
                   manager_flag = p_cnv_pre_std_hdr_table (indx).manager_flag,
                   normal_hours = p_cnv_pre_std_hdr_table (indx).normal_hours,
                   hourly_salaried_code =
                           p_cnv_pre_std_hdr_table (indx).hourly_salaried_code,
                   salary_basis = p_cnv_pre_std_hdr_table (indx).salary_basis,
                   payroll_name = p_cnv_pre_std_hdr_table (indx).payroll_name,
                   job_name = p_cnv_pre_std_hdr_table (indx).job_name,
                   pos_title = p_cnv_pre_std_hdr_table (indx).pos_title,
                   grade_name = p_cnv_pre_std_hdr_table (indx).grade_name,
                   supervisor_unique_id =
                           p_cnv_pre_std_hdr_table (indx).supervisor_unique_id,
                   supervisor_number =
                              p_cnv_pre_std_hdr_table (indx).supervisor_number,
                   supervisor_first_name =
                          p_cnv_pre_std_hdr_table (indx).supervisor_first_name,
                   supervisor_last_name =
                           p_cnv_pre_std_hdr_table (indx).supervisor_last_name,
                   effective_start_date =
                           p_cnv_pre_std_hdr_table (indx).effective_start_date,
                   sob_name = p_cnv_pre_std_hdr_table (indx).sob_name,
                   acct_seg1 = p_cnv_pre_std_hdr_table (indx).acct_seg1,
                   acct_seg2 = p_cnv_pre_std_hdr_table (indx).acct_seg2,
                   acct_seg3 = p_cnv_pre_std_hdr_table (indx).acct_seg3,
                   acct_seg4 = p_cnv_pre_std_hdr_table (indx).acct_seg4,
                   acct_seg5 = p_cnv_pre_std_hdr_table (indx).acct_seg5,
                   acct_seg6 = p_cnv_pre_std_hdr_table (indx).acct_seg6,
                   acct_seg7 = p_cnv_pre_std_hdr_table (indx).acct_seg7,
                   acct_seg8 = p_cnv_pre_std_hdr_table (indx).acct_seg8,
                   acct_seg9 = p_cnv_pre_std_hdr_table (indx).acct_seg9,
                   SOURCE = p_cnv_pre_std_hdr_table (indx).SOURCE,
                   change_reason =
                                  p_cnv_pre_std_hdr_table (indx).change_reason,
                   date_probation_end =
                             p_cnv_pre_std_hdr_table (indx).date_probation_end,
                   frequency = p_cnv_pre_std_hdr_table (indx).frequency,
                   internal_address_line =
                          p_cnv_pre_std_hdr_table (indx).internal_address_line,
                   perf_review_period =
                             p_cnv_pre_std_hdr_table (indx).perf_review_period,
                   perf_review_period_frequency =
                      p_cnv_pre_std_hdr_table (indx).perf_review_period_frequency,
                   probation_period =
                               p_cnv_pre_std_hdr_table (indx).probation_period,
                   probation_unit =
                                 p_cnv_pre_std_hdr_table (indx).probation_unit,
                   sal_review_period =
                              p_cnv_pre_std_hdr_table (indx).sal_review_period,
                   sal_review_period_frequency =
                      p_cnv_pre_std_hdr_table (indx).sal_review_period_frequency,
                   source_type = p_cnv_pre_std_hdr_table (indx).source_type,
                   time_normal_finish =
                             p_cnv_pre_std_hdr_table (indx).time_normal_finish,
                   time_normal_start =
                              p_cnv_pre_std_hdr_table (indx).time_normal_start,
                   bargaining_unit_code =
                           p_cnv_pre_std_hdr_table (indx).bargaining_unit_code,
                   labour_union_member_flag =
                       p_cnv_pre_std_hdr_table (indx).labour_union_member_flag,
                   ass_attribute_category =
                         p_cnv_pre_std_hdr_table (indx).ass_attribute_category,
                   ass_attribute1 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute1,
                   ass_attribute2 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute2,
                   ass_attribute3 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute3,
                   ass_attribute4 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute4,
                   ass_attribute5 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute5,
                   ass_attribute6 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute6,
                   ass_attribute7 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute7,
                   ass_attribute8 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute8,
                   ass_attribute9 =
                                 p_cnv_pre_std_hdr_table (indx).ass_attribute9,
                   ass_attribute10 =
                                p_cnv_pre_std_hdr_table (indx).ass_attribute10,
                   notice_period =
                                  p_cnv_pre_std_hdr_table (indx).notice_period,
                   notice_period_uom =
                              p_cnv_pre_std_hdr_table (indx).notice_period_uom,
                   employee_category =
                              p_cnv_pre_std_hdr_table (indx).employee_category,
                   job_post_source_name =
                           p_cnv_pre_std_hdr_table (indx).job_post_source_name,
                   period_of_placement_date_start =
                      p_cnv_pre_std_hdr_table (indx).period_of_placement_date_start,
                   vendor_employee_number =
                         p_cnv_pre_std_hdr_table (indx).vendor_employee_number,
                   vendor_assignment_number =
                       p_cnv_pre_std_hdr_table (indx).vendor_assignment_number,
                   project_title =
                                  p_cnv_pre_std_hdr_table (indx).project_title,
                   applicant_rank =
                                 p_cnv_pre_std_hdr_table (indx).applicant_rank,
                   segment1 =
                      p_cnv_pre_std_hdr_table (indx).segment1
                                                          -- Added for Integra
                                                             ,
                   segment2 =
                      p_cnv_pre_std_hdr_table (indx).segment2
                                                          -- Added for Integra
                                                             ,
                   segment3 =
                      p_cnv_pre_std_hdr_table (indx).segment3
                                                          -- Added for Integra
                                                             ,
                   segment4 =
                      p_cnv_pre_std_hdr_table (indx).segment4
                                                          -- Added for Integra
                                                             ,
                   segment5 =
                      p_cnv_pre_std_hdr_table (indx).segment5
                                                          -- Added for Integra
                                                             ,
                   segment6 =
                      p_cnv_pre_std_hdr_table (indx).segment6
                                                          -- Added for Integra
                                                             ,
                   segment7 =
                      p_cnv_pre_std_hdr_table (indx).segment7
                                                          -- Added for Integra
                                                             ,
                   segment8 =
                      p_cnv_pre_std_hdr_table (indx).segment8
                                                          -- Added for Integra
                                                             ,
                   segment9 =
                      p_cnv_pre_std_hdr_table (indx).segment9
                                                          -- Added for Integra
                                                             ,
                   segment10 =
                      p_cnv_pre_std_hdr_table (indx).segment10
                                                          -- Added for Integra
                                                              ,
                   actual_start_date =
                              p_cnv_pre_std_hdr_table (indx).actual_start_date,
                   person_unique_id =
                               p_cnv_pre_std_hdr_table (indx).person_unique_id,
                   full_name = p_cnv_pre_std_hdr_table (indx).full_name,
                   assignment_type =
                                p_cnv_pre_std_hdr_table (indx).assignment_type,
                   assignment_sequence =
                            p_cnv_pre_std_hdr_table (indx).assignment_sequence,
                   establishment =
                                  p_cnv_pre_std_hdr_table (indx).establishment,
                   contract = p_cnv_pre_std_hdr_table (indx).contract,
                   vacancy_name = p_cnv_pre_std_hdr_table (indx).vacancy_name,
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
                   eit9 = p_cnv_pre_std_hdr_table (indx).eit9,
                   eit10 = p_cnv_pre_std_hdr_table (indx).eit10,
                   gov_rep_entity =
                                 p_cnv_pre_std_hdr_table (indx).gov_rep_entity,
                   timecard_approver_us =
                           p_cnv_pre_std_hdr_table (indx).timecard_approver_us,
                   timecard_required_us =
                           p_cnv_pre_std_hdr_table (indx).timecard_required_us,
                   work_schedule_us =
                               p_cnv_pre_std_hdr_table (indx).work_schedule_us,
                   shift_us = p_cnv_pre_std_hdr_table (indx).shift_us,
                   spouse_salary =
                                  p_cnv_pre_std_hdr_table (indx).spouse_salary,
                   legal_rep = p_cnv_pre_std_hdr_table (indx).legal_rep,
                   worker_comp_override_code =
                      p_cnv_pre_std_hdr_table (indx).worker_comp_override_code,
                   reporting_estab =
                                p_cnv_pre_std_hdr_table (indx).reporting_estab,
                   seasonal_worker_us =
                             p_cnv_pre_std_hdr_table (indx).seasonal_worker_us,
                   corp_officer_ind =
                               p_cnv_pre_std_hdr_table (indx).corp_officer_ind,
                   corp_officer_code =
                              p_cnv_pre_std_hdr_table (indx).corp_officer_code,
                   area_code = p_cnv_pre_std_hdr_table (indx).area_code,
                   occupational_code =
                              p_cnv_pre_std_hdr_table (indx).occupational_code,
                   wage_plan_code =
                                 p_cnv_pre_std_hdr_table (indx).wage_plan_code,
                   seasonal_code =
                                  p_cnv_pre_std_hdr_table (indx).seasonal_code,
                   tax_loc = p_cnv_pre_std_hdr_table (indx).tax_loc,
                   probationary_code =
                              p_cnv_pre_std_hdr_table (indx).probationary_code,
                   pvt_disability_plan_id =
                         p_cnv_pre_std_hdr_table (indx).pvt_disability_plan_id,
                   family_leave_ins_plan_id =
                       p_cnv_pre_std_hdr_table (indx).family_leave_ins_plan_id,
                   alpha_ind_class_code =
                           p_cnv_pre_std_hdr_table (indx).alpha_ind_class_code,
                   employer_paye_ref_gb =
                           p_cnv_pre_std_hdr_table (indx).employer_paye_ref_gb,
                   unique_id_gb = p_cnv_pre_std_hdr_table (indx).unique_id_gb,
                   econ = p_cnv_pre_std_hdr_table (indx).econ,
                   max_hol_per_adv =
                                p_cnv_pre_std_hdr_table (indx).max_hol_per_adv,
                   bacs_pay_rule =
                                  p_cnv_pre_std_hdr_table (indx).bacs_pay_rule,
                   smp_recovered =
                                  p_cnv_pre_std_hdr_table (indx).smp_recovered,
                   smp_compensation =
                               p_cnv_pre_std_hdr_table (indx).smp_compensation,
                   ssp_recovered =
                                  p_cnv_pre_std_hdr_table (indx).ssp_recovered,
                   sap_recovered =
                                  p_cnv_pre_std_hdr_table (indx).sap_recovered,
                   sap_compensation =
                               p_cnv_pre_std_hdr_table (indx).sap_compensation,
                   spp_recovered =
                                  p_cnv_pre_std_hdr_table (indx).spp_recovered,
                   spp_compensation =
                               p_cnv_pre_std_hdr_table (indx).spp_compensation,
                   govt_rep_entity_t4_rl1 =
                         p_cnv_pre_std_hdr_table (indx).govt_rep_entity_t4_rl1,
                   govt_rep_entity_t4a_rl1 =
                        p_cnv_pre_std_hdr_table (indx).govt_rep_entity_t4a_rl1,
                   govt_rep_entity_t4_rl2 =
                         p_cnv_pre_std_hdr_table (indx).govt_rep_entity_t4_rl2,
                   timecard_approver_ca =
                           p_cnv_pre_std_hdr_table (indx).timecard_approver_ca,
                   timecard_required_ca =
                           p_cnv_pre_std_hdr_table (indx).timecard_required_ca,
                   work_schedule_ca =
                               p_cnv_pre_std_hdr_table (indx).work_schedule_ca,
                   shift_ca = p_cnv_pre_std_hdr_table (indx).shift_ca,
                   naic_override_code =
                             p_cnv_pre_std_hdr_table (indx).naic_override_code,
                   seasonal_worker_ca =
                             p_cnv_pre_std_hdr_table (indx).seasonal_worker_ca,
                   officer_code = p_cnv_pre_std_hdr_table (indx).officer_code,
                   work_comp_acct_num_override =
                      p_cnv_pre_std_hdr_table (indx).work_comp_acct_num_override,
                   work_comp_rate_code_override =
                      p_cnv_pre_std_hdr_table (indx).work_comp_rate_code_override,
                   tax_district_ref =
                               p_cnv_pre_std_hdr_table (indx).tax_district_ref,
                   ie_paypath_info =
                                p_cnv_pre_std_hdr_table (indx).ie_paypath_info,
                   employer_paye_ref_ie =
                           p_cnv_pre_std_hdr_table (indx).employer_paye_ref_ie,
                   legal_employer_ie =
                              p_cnv_pre_std_hdr_table (indx).legal_employer_ie,
                   govt_rep_entity_mx =
                             p_cnv_pre_std_hdr_table (indx).govt_rep_entity_mx,
                   timecard_approver_mx =
                           p_cnv_pre_std_hdr_table (indx).timecard_approver_mx,
                   timecard_required_mx =
                           p_cnv_pre_std_hdr_table (indx).timecard_required_mx,
                   work_schedule_mx =
                               p_cnv_pre_std_hdr_table (indx).work_schedule_mx,
                   govt_emp_sector =
                                p_cnv_pre_std_hdr_table (indx).govt_emp_sector,
                   soc_sec_sal_type =
                               p_cnv_pre_std_hdr_table (indx).soc_sec_sal_type,
                   ss_rehire_rep =
                                  p_cnv_pre_std_hdr_table (indx).ss_rehire_rep,
                   comp_subsidy_emp =
                               p_cnv_pre_std_hdr_table (indx).comp_subsidy_emp,
                   reg_employer = p_cnv_pre_std_hdr_table (indx).reg_employer,
                   holiday_anniv_date =
                             p_cnv_pre_std_hdr_table (indx).holiday_anniv_date,
                   legal_employer_au =
                              p_cnv_pre_std_hdr_table (indx).legal_employer_au,
                   incl_leave_loading =
                             p_cnv_pre_std_hdr_table (indx).incl_leave_loading,
                   grp_cert_issue_date =
                            p_cnv_pre_std_hdr_table (indx).grp_cert_issue_date,
                   hours_sgc_calc =
                                 p_cnv_pre_std_hdr_table (indx).hours_sgc_calc,
                   emp_coding = p_cnv_pre_std_hdr_table (indx).emp_coding,
                   work_schedule_be =
                               p_cnv_pre_std_hdr_table (indx).work_schedule_be,
                   start_reason_be =
                                p_cnv_pre_std_hdr_table (indx).start_reason_be,
                   end_reason_be =
                                  p_cnv_pre_std_hdr_table (indx).end_reason_be,
                   emp_type_be = p_cnv_pre_std_hdr_table (indx).emp_type_be,
                   EXEMPT = p_cnv_pre_std_hdr_table (indx).EXEMPT,
                   liab_ins_provider =
                              p_cnv_pre_std_hdr_table (indx).liab_ins_provider,
                   class_of_risk =
                                  p_cnv_pre_std_hdr_table (indx).class_of_risk,
                   emp_cat_fr = p_cnv_pre_std_hdr_table (indx).emp_cat_fr,
                   start_reason_fr =
                                p_cnv_pre_std_hdr_table (indx).start_reason_fr,
                   end_reason_fr =
                                  p_cnv_pre_std_hdr_table (indx).end_reason_fr,
                   work_pattern = p_cnv_pre_std_hdr_table (indx).work_pattern,
                   urssaf_code = p_cnv_pre_std_hdr_table (indx).urssaf_code,
                   corps = p_cnv_pre_std_hdr_table (indx).corps,
                   stat_position =
                                  p_cnv_pre_std_hdr_table (indx).stat_position,
                   physical_share =
                                 p_cnv_pre_std_hdr_table (indx).physical_share,
                   pub_sector_emp_type =
                            p_cnv_pre_std_hdr_table (indx).pub_sector_emp_type,
                   work_pattern_start_day =
                         p_cnv_pre_std_hdr_table (indx).work_pattern_start_day,
                   work_days_per_yr =
                               p_cnv_pre_std_hdr_table (indx).work_days_per_yr,
                   detache_status =
                                 p_cnv_pre_std_hdr_table (indx).detache_status,
                   address_abroad =
                                 p_cnv_pre_std_hdr_table (indx).address_abroad,
                   border_worker =
                                  p_cnv_pre_std_hdr_table (indx).border_worker,
                   prof_status = p_cnv_pre_std_hdr_table (indx).prof_status,
                   reason_non_titulaire =
                           p_cnv_pre_std_hdr_table (indx).reason_non_titulaire,
                   reason_part_time =
                               p_cnv_pre_std_hdr_table (indx).reason_part_time,
                   comments_fr = p_cnv_pre_std_hdr_table (indx).comments_fr,
                   identifier_fr =
                                  p_cnv_pre_std_hdr_table (indx).identifier_fr,
                   affectation_type =
                               p_cnv_pre_std_hdr_table (indx).affectation_type,
                   percent_affected =
                               p_cnv_pre_std_hdr_table (indx).percent_affected,
                   admin_career_id =
                                p_cnv_pre_std_hdr_table (indx).admin_career_id,
                   primary_affectation =
                            p_cnv_pre_std_hdr_table (indx).primary_affectation,
                   grouping_emp_name =
                              p_cnv_pre_std_hdr_table (indx).grouping_emp_name,
                   assignment_id =
                                  p_cnv_pre_std_hdr_table (indx).assignment_id,
                   business_group_id =
                              p_cnv_pre_std_hdr_table (indx).business_group_id,
                   recruiter_id = p_cnv_pre_std_hdr_table (indx).recruiter_id,
                   grade_id = p_cnv_pre_std_hdr_table (indx).grade_id,
                   position_id = p_cnv_pre_std_hdr_table (indx).position_id,
                   job_id = p_cnv_pre_std_hdr_table (indx).job_id,
                   assignment_status_type_id =
                      p_cnv_pre_std_hdr_table (indx).assignment_status_type_id,
                   payroll_id = p_cnv_pre_std_hdr_table (indx).payroll_id,
                   location_id = p_cnv_pre_std_hdr_table (indx).location_id,
                   person_referred_by_id =
                          p_cnv_pre_std_hdr_table (indx).person_referred_by_id,
                   supervisor_id =
                                  p_cnv_pre_std_hdr_table (indx).supervisor_id,
                   special_ceiling_step_id =
                        p_cnv_pre_std_hdr_table (indx).special_ceiling_step_id,
                   person_id = p_cnv_pre_std_hdr_table (indx).person_id,
                   recruitment_activity_id =
                        p_cnv_pre_std_hdr_table (indx).recruitment_activity_id,
                   source_organization_id =
                         p_cnv_pre_std_hdr_table (indx).source_organization_id,
                   organization_id =
                                p_cnv_pre_std_hdr_table (indx).organization_id,
                   people_group_id =
                                p_cnv_pre_std_hdr_table (indx).people_group_id,
                   soft_coding_keyflex_id =
                         p_cnv_pre_std_hdr_table (indx).soft_coding_keyflex_id,
                   vacancy_id = p_cnv_pre_std_hdr_table (indx).vacancy_id,
                   pay_basis_id = p_cnv_pre_std_hdr_table (indx).pay_basis_id,
                   application_id =
                                 p_cnv_pre_std_hdr_table (indx).application_id,
                   comment_id = p_cnv_pre_std_hdr_table (indx).comment_id,
                   default_code_comb_id =
                           p_cnv_pre_std_hdr_table (indx).default_code_comb_id,
                   employment_category =
                            p_cnv_pre_std_hdr_table (indx).employment_category,
                   period_of_service_id =
                           p_cnv_pre_std_hdr_table (indx).period_of_service_id,
                   asg_request_id =
                                 p_cnv_pre_std_hdr_table (indx).asg_request_id,
                   contract_id = p_cnv_pre_std_hdr_table (indx).contract_id,
                   collective_agreement_id =
                        p_cnv_pre_std_hdr_table (indx).collective_agreement_id,
                   cagr_id_flex_num =
                               p_cnv_pre_std_hdr_table (indx).cagr_id_flex_num,
                   cagr_grade_def_id =
                              p_cnv_pre_std_hdr_table (indx).cagr_grade_def_id,
                   establishment_id =
                               p_cnv_pre_std_hdr_table (indx).establishment_id,
                   vendor_id = p_cnv_pre_std_hdr_table (indx).vendor_id,
                   grade_ladder_pgm_id =
                            p_cnv_pre_std_hdr_table (indx).grade_ladder_pgm_id,
                   supervisor_assignment_id =
                       p_cnv_pre_std_hdr_table (indx).supervisor_assignment_id,
                   extracted_person_id =
                            p_cnv_pre_std_hdr_table (indx).extracted_person_id,
                   extracted_assignment_id =
                        p_cnv_pre_std_hdr_table (indx).extracted_assignment_id,
                   pos_code = p_cnv_pre_std_hdr_table (indx).pos_code,
                   supervisor_start_date =
                          p_cnv_pre_std_hdr_table (indx).supervisor_start_date,
                   tax_unit_id = p_cnv_pre_std_hdr_table (indx).tax_unit_id,
                   npw_number = p_cnv_pre_std_hdr_table (indx).npw_number,
                   concat_segs = p_cnv_pre_std_hdr_table (indx).concat_segs,
                   set_of_books_id =
                                p_cnv_pre_std_hdr_table (indx).set_of_books_id,
                   posting_content_id =
                             p_cnv_pre_std_hdr_table (indx).posting_content_id,
                   hr_rep_id = p_cnv_pre_std_hdr_table (indx).hr_rep_id,
                   hr_director_id =
                                 p_cnv_pre_std_hdr_table (indx).hr_director_id,
                   batch_id = p_cnv_pre_std_hdr_table (indx).batch_id,
                   process_code = p_cnv_pre_std_hdr_table (indx).process_code,
                   ERROR_CODE = p_cnv_pre_std_hdr_table (indx).ERROR_CODE,
                   request_id = p_cnv_pre_std_hdr_table (indx).request_id,
                   object_version_number =
                          p_cnv_pre_std_hdr_table (indx).object_version_number,
                   last_update_date =
                               p_cnv_pre_std_hdr_table (indx).last_update_date,
                   last_updated_by =
                                p_cnv_pre_std_hdr_table (indx).last_updated_by,
                   last_update_login =
                              p_cnv_pre_std_hdr_table (indx).last_update_login,
                   created_by = p_cnv_pre_std_hdr_table (indx).created_by,
                   creation_date =
                                  p_cnv_pre_std_hdr_table (indx).creation_date,
                   program_application_id =
                         p_cnv_pre_std_hdr_table (indx).program_application_id,
                   program_id = p_cnv_pre_std_hdr_table (indx).program_id,
                   program_update_date =
                            p_cnv_pre_std_hdr_table (indx).program_update_date,
                   record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number
             WHERE record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number
               AND batch_id = g_batch_id;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

--------------------------------------------------------------------------------
----------------------< move_rec_pre_standard_table >------------------------
--------------------------------------------------------------------------------
      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date           DATE                      := SYSDATE;
         x_created_by              NUMBER               := fnd_global.user_id;
         x_last_update_date        DATE                      := SYSDATE;
         x_last_updated_by         NUMBER               := fnd_global.user_id;
         x_last_update_login       NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_cnv_pre_std_hdr_table   g_xx_asg_cnv_pre_tab_type;
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
         INSERT INTO xx_hr_asg_pre
                     (business_group_name, employee_number, first_name,
                      last_name, hire_date, assignment_number,
                      assignment_status, country, primary_flag,
                      assignment_category, ORGANIZATION, LOCATION,
                      work_at_home, person_type, manager_flag, normal_hours,
                      hourly_salaried_code, salary_basis, payroll_name,
                      job_name, pos_title, grade_name, supervisor_unique_id,
                      supervisor_number, supervisor_first_name,
                      supervisor_last_name, effective_start_date, sob_name,
                      acct_seg1, acct_seg2, acct_seg3, acct_seg4, acct_seg5,
                      acct_seg6, acct_seg7, acct_seg8, acct_seg9, SOURCE,
                      change_reason, date_probation_end, frequency,
                      internal_address_line, perf_review_period,
                      perf_review_period_frequency, probation_period,
                      probation_unit, sal_review_period,
                      sal_review_period_frequency, source_type,
                      time_normal_finish, time_normal_start,
                      bargaining_unit_code, labour_union_member_flag,
                      ass_attribute_category, ass_attribute1, ass_attribute2,
                      ass_attribute3, ass_attribute4, ass_attribute5,
                      ass_attribute6, ass_attribute7, ass_attribute8,
                      ass_attribute9, ass_attribute10, notice_period,
                      notice_period_uom, employee_category,
                      job_post_source_name, period_of_placement_date_start,
                      vendor_employee_number, vendor_assignment_number,
                      project_title, applicant_rank, segment1, segment2,
                      segment3, segment4, segment5, segment6, segment7,
                      segment8, segment9, segment10, actual_start_date,
                      person_unique_id, full_name, assignment_type,
                      assignment_sequence, establishment, contract,
                      vacancy_name, eit_information_type,
                      eit_information_category, eit1, eit2, eit3, eit4, eit5,
                      eit6, eit7, eit8, eit9, eit10, gov_rep_entity,
                      timecard_approver_us, timecard_required_us,
                      work_schedule_us, shift_us, spouse_salary, legal_rep,
                      worker_comp_override_code, reporting_estab,
                      seasonal_worker_us, corp_officer_ind, corp_officer_code,
                      area_code, occupational_code, wage_plan_code,
                      seasonal_code, tax_loc, probationary_code,
                      pvt_disability_plan_id, family_leave_ins_plan_id,
                      alpha_ind_class_code, employer_paye_ref_gb,
                      unique_id_gb, econ, max_hol_per_adv, bacs_pay_rule,
                      smp_recovered, smp_compensation, ssp_recovered,
                      sap_recovered, sap_compensation, spp_recovered,
                      spp_compensation, govt_rep_entity_t4_rl1,
                      govt_rep_entity_t4a_rl1, govt_rep_entity_t4_rl2,
                      timecard_approver_ca, timecard_required_ca,
                      work_schedule_ca, shift_ca, naic_override_code,
                      seasonal_worker_ca, officer_code,
                      work_comp_acct_num_override,
                      work_comp_rate_code_override, tax_district_ref,
                      ie_paypath_info, employer_paye_ref_ie,
                      legal_employer_ie, govt_rep_entity_mx,
                      timecard_approver_mx, timecard_required_mx,
                      work_schedule_mx, govt_emp_sector, soc_sec_sal_type,
                      ss_rehire_rep, comp_subsidy_emp, reg_employer,
                      holiday_anniv_date, legal_employer_au,
                      incl_leave_loading, grp_cert_issue_date, hours_sgc_calc,
                      emp_coding, work_schedule_be, start_reason_be,
                      end_reason_be, emp_type_be, EXEMPT, liab_ins_provider,
                      class_of_risk, emp_cat_fr, start_reason_fr,
                      end_reason_fr, work_pattern, urssaf_code, corps,
                      stat_position, physical_share, pub_sector_emp_type,
                      work_pattern_start_day, work_days_per_yr,
                      detache_status, address_abroad, border_worker,
                      prof_status, reason_non_titulaire, reason_part_time,
                      comments_fr, identifier_fr, affectation_type,
                      percent_affected, admin_career_id, primary_affectation,
                      grouping_emp_name, batch_id, process_code, ERROR_CODE,
                      request_id, last_update_date, last_updated_by,
                      last_update_login, created_by, creation_date,
                      record_number, program_application_id, program_id,
                      program_update_date)
            SELECT business_group_name, employee_number, first_name,
                   last_name, hire_date, assignment_number, assignment_status,
                   country, primary_flag, assignment_category, ORGANIZATION,
                   LOCATION, work_at_home, person_type, manager_flag,
                   normal_hours, hourly_salaried_code, salary_basis,
                   payroll_name, job_name, pos_title, grade_name,
                   supervisor_unique_id, supervisor_number,
                   supervisor_first_name, supervisor_last_name,
                   effective_start_date, sob_name, acct_seg1, acct_seg2,
                   acct_seg3, acct_seg4, acct_seg5, acct_seg6, acct_seg7,
                   acct_seg8, acct_seg9, SOURCE, change_reason,
                   date_probation_end, frequency, internal_address_line,
                   perf_review_period, perf_review_period_frequency,
                   probation_period, probation_unit, sal_review_period,
                   sal_review_period_frequency, source_type,
                   time_normal_finish, time_normal_start,
                   bargaining_unit_code, labour_union_member_flag,
                   ass_attribute_category, ass_attribute1, ass_attribute2,
                   ass_attribute3, ass_attribute4, ass_attribute5,
                   ass_attribute6, ass_attribute7, ass_attribute8,
                   ass_attribute9, ass_attribute10, notice_period,
                   notice_period_uom, employee_category, job_post_source_name,
                   period_of_placement_date_start, vendor_employee_number,
                   vendor_assignment_number, project_title, applicant_rank,
                   segment1, segment2, segment3, segment4, segment5, segment6,
                   segment7, segment8, segment9, segment10, actual_start_date,
                   person_unique_id, full_name, assignment_type,
                   assignment_sequence, establishment, contract, vacancy_name,
                   eit_information_type, eit_information_category, eit1, eit2,
                   eit3, eit4, eit5, eit6, eit7, eit8, eit9, eit10,
                   gov_rep_entity, timecard_approver_us, timecard_required_us,
                   work_schedule_us, shift_us, spouse_salary, legal_rep,
                   worker_comp_override_code, reporting_estab,
                   seasonal_worker_us, corp_officer_ind, corp_officer_code,
                   area_code, occupational_code, wage_plan_code,
                   seasonal_code, tax_loc, probationary_code,
                   pvt_disability_plan_id, family_leave_ins_plan_id,
                   alpha_ind_class_code, employer_paye_ref_gb, unique_id_gb,
                   econ, max_hol_per_adv, bacs_pay_rule, smp_recovered,
                   smp_compensation, ssp_recovered, sap_recovered,
                   sap_compensation, spp_recovered, spp_compensation,
                   govt_rep_entity_t4_rl1, govt_rep_entity_t4a_rl1,
                   govt_rep_entity_t4_rl2, timecard_approver_ca,
                   timecard_required_ca, work_schedule_ca, shift_ca,
                   naic_override_code, seasonal_worker_ca, officer_code,
                   work_comp_acct_num_override, work_comp_rate_code_override,
                   tax_district_ref, ie_paypath_info, employer_paye_ref_ie,
                   legal_employer_ie, govt_rep_entity_mx,
                   timecard_approver_mx, timecard_required_mx,
                   work_schedule_mx, govt_emp_sector, soc_sec_sal_type,
                   ss_rehire_rep, comp_subsidy_emp, reg_employer,
                   holiday_anniv_date, legal_employer_au, incl_leave_loading,
                   grp_cert_issue_date, hours_sgc_calc, emp_coding,
                   work_schedule_be, start_reason_be, end_reason_be,
                   emp_type_be, EXEMPT, liab_ins_provider, class_of_risk,
                   emp_cat_fr, start_reason_fr, end_reason_fr, work_pattern,
                   urssaf_code, corps, stat_position, physical_share,
                   pub_sector_emp_type, work_pattern_start_day,
                   work_days_per_yr, detache_status, address_abroad,
                   border_worker, prof_status, reason_non_titulaire,
                   reason_part_time, comments_fr, identifier_fr,
                   affectation_type, percent_affected, admin_career_id,
                   primary_affectation, grouping_emp_name, batch_id,
                   process_code, ERROR_CODE, request_id, last_update_date,
                   last_updated_by, last_update_login, created_by,
                   creation_date, record_number, program_application_id,
                   program_id, program_update_date
              FROM xx_hr_asg_stg
             WHERE batch_id = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn);

         COMMIT;
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                             'Inside move_rec_pre_standard_table After COMMIT'
                            );
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_sqlerrm := SQLERRM;
            xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      'Inside move_rec_pre_standard_table At EXCEPTION Block'
                     );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                              xx_emf_cn_pkg.cn_tech_error,
                                 'In move_rec_pre_standard_table proc:'
                              || l_sqlerrm
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

--------------------------------------------------------------------------------
---------------------------< process_data >-------------------------------------
--------------------------------------------------------------------------------
      FUNCTION process_data (
         p_parameter_1   IN   VARCHAR2,
         p_parameter_2   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_return_status                  VARCHAR2 (15)
                                                  := xx_emf_cn_pkg.cn_success;

         /* Cursor Changed by Rohit, Instead of writting all columns should write SELECT* FROM*/
         CURSOR xx_asg_cur_main
         IS
            SELECT   *
                FROM xx_hr_asg_pre pre1
               WHERE NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                 AND batch_id = g_batch_id
                 AND NVL (pre1.effective_start_date, SYSDATE) =
                        (SELECT NVL (MAX (pre2.effective_start_date), SYSDATE)
                           FROM xx_hr_asg_pre pre2
                          WHERE pre2.batch_id = g_batch_id
                            AND pre1.employee_number = pre2.employee_number)
            -- commented for integra  and pre2.assignment_status <> 'Terminate Assignment')
            ORDER BY person_id, effective_start_date;

         l_person_id                      NUMBER;
         x_person_id                      NUMBER;
         x_per_object_version_number      NUMBER;
         x_asg_object_version_number      NUMBER;
         x_full_name                      VARCHAR2 (300);
         x_per_comment_id                 NUMBER;
         x_assignment_sequence            NUMBER;
         x_combination_warning            BOOLEAN;
         x_payroll_warning                BOOLEAN;
         x_orig_hire_warning              BOOLEAN;
         x_validate                       BOOLEAN                     := FALSE;
         x_business_group_id              NUMBER                       := NULL;
             /* Defaulted by Rohit J Incase Business Group is not available */
         x_employee_number                VARCHAR2 (40);
--Assisgnment API variables--
         x_concatenated_segments          VARCHAR2 (2000);
         x_soft_coding_keyflex_id         NUMBER;
         x_no_managers_warning            BOOLEAN;
         x_group_name                     VARCHAR2 (2000);
         x_assignment_id                  NUMBER;
         x_people_group_id                NUMBER;
         x_object_version_number          NUMBER;
         x_effective_start_date           DATE;
         x_effective_end_date             DATE;
         x_comment_id                     NUMBER;
         x_other_manager_warning          BOOLEAN;
         x_hourly_salaried_warning        BOOLEAN;
         x_cagr_grade_def_id              NUMBER;
         x_cagr_concatenated_segments     VARCHAR2 (2000);
         x_assignment_number              VARCHAR2 (2000);
         x_gsp_post_process_warning       VARCHAR2 (2000);
         x_tax_district_changed_warning   BOOLEAN;
         x_entries_changed_warning        VARCHAR2 (2000);
         x_spp_delete_warning             BOOLEAN;
         x_org_now_no_manager_warning     BOOLEAN;
         x_speciax_ceiling_step_id        NUMBER                       := NULL;
         x_asg_future_changes_warning     BOOLEAN;
         x_pay_proposax_warning           BOOLEAN;
         x_api_name                       VARCHAR2 (200);
         x_primary_dt_track               VARCHAR2 (50);
         x_special_ceiling_step_id        NUMBER;
         l_effective_start_date           DATE;
         l_datetrack_update_mode          VARCHAR2 (100);
         l_asg_exists_count               NUMBER                          := 0;
         x_flex_code                      fnd_id_flex_structures.id_flex_code%TYPE;
         x_flex_num                       fnd_id_flex_structures.id_flex_num%TYPE;
         x_concat                         fnd_id_flex_structures.concatenated_segment_delimiter%TYPE;
         x_appl                           fnd_application.application_short_name%TYPE;
         x_group_id                       NUMBER (10);
         x_concat_segs                    VARCHAR2 (2000);
         x_err_point                      VARCHAR2 (1000);
         x_hourly_sal_code                VARCHAR2 (10);
         x_prob_unit                      VARCHAR2 (10)                := NULL;
         x_freq_unit                      VARCHAR2 (10)                := NULL;
         l_emp_start_date                 DATE;
         l_sup_start_date                 DATE;
         l_effective_date                 DATE;
         x_assignment_extra_info_id       NUMBER;
-- end of API Variables
      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
         FOR xx_asg_rec_main IN xx_asg_cur_main
         LOOP
            BEGIN
               x_object_version_number := NULL;
               x_assignment_id := NULL;
               x_assignment_number := NULL;
               l_effective_start_date := NULL;
               x_soft_coding_keyflex_id := NULL;
               x_prob_unit := NULL;
               x_freq_unit := NULL;
               x_hourly_sal_code := NULL;
               x_err_point := 'FIND ASSIGNMENT';

               SELECT paaf.object_version_number, paaf.assignment_id,
                      paaf.assignment_number, paaf.effective_start_date
                 INTO x_object_version_number, x_assignment_id,
                      x_assignment_number, l_effective_start_date
                 FROM per_all_assignments_f paaf, per_all_people_f papf
                WHERE papf.attribute1 =
                         xx_asg_rec_main.person_unique_id
 -- papf.attribute2   = xx_asg_rec_main.employee_number -- changed for integra
                  AND papf.person_id = paaf.person_id
                  AND NVL (xx_asg_rec_main.effective_start_date, SYSDATE)
                         BETWEEN paaf.effective_start_date
                             AND paaf.effective_end_date
                  AND NVL (xx_asg_rec_main.effective_start_date, SYSDATE)
                         BETWEEN papf.effective_start_date
                             AND papf.effective_end_date;

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' HOURLY SALARIED CODE '
                                     || x_hourly_sal_code
                                    );

               IF xx_asg_rec_main.hourly_salaried_code IS NOT NULL
               THEN
                  x_err_point := 'FIND SALARIED CODE';

                  SELECT lookup_code
                    INTO x_hourly_sal_code
                    FROM hr_lookups
                   WHERE lookup_type = 'HOURLY_SALARIED_CODE'
                     AND UPPER (meaning) =
                                  UPPER (xx_asg_rec_main.hourly_salaried_code);

                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           ' HOURLY SALARIED CODE '
                                        || x_hourly_sal_code
                                       );
               END IF;

               IF xx_asg_rec_main.probation_unit IS NOT NULL
               THEN
                  x_err_point := 'FIND PROBATION UNIT';

                  SELECT lookup_code
                    INTO x_prob_unit
                    FROM hr_lookups
                   WHERE lookup_type = 'QUALIFYING_UNITS'
                     AND UPPER (meaning) =
                                      UPPER (xx_asg_rec_main.probation_unit);

                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' PROBATION UNIT ' || x_prob_unit
                                       );
               END IF;

               IF xx_asg_rec_main.frequency IS NOT NULL
               THEN
                  x_err_point := 'FIND FREQUENCY';

                  SELECT lookup_code
                    INTO x_freq_unit
                    FROM hr_lookups
                   WHERE lookup_type = 'FREQUENCY'
                     AND UPPER (meaning) = UPPER (xx_asg_rec_main.frequency);

                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' FREQUENCY UNIT ' || x_freq_unit
                                       );
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_sqlerrm := SQLERRM;
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    l_sqlerrm || ' ' || x_err_point
                                   );
               WHEN OTHERS
               THEN
                  l_sqlerrm := SQLERRM;
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    l_sqlerrm || ' ' || x_err_point
                                   );
            END;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' l_effective_start_date '
                                  || l_effective_start_date
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' xx_asg_rec_main.effective_start_date '
                                  || xx_asg_rec_main.effective_start_date
                                 );

            IF l_effective_start_date < xx_asg_rec_main.effective_start_date
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'UPDATE');
               l_datetrack_update_mode := 'UPDATE';
            ELSE
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'CORRECTION');
               l_datetrack_update_mode := 'CORRECTION';
            END IF;

            SELECT COUNT (1)
              INTO l_asg_exists_count
              FROM per_all_assignments_f
             WHERE assignment_id = x_assignment_id
               AND effective_start_date >=
                                          xx_asg_rec_main.effective_start_date
               AND primary_flag = 'Y'
               AND assignment_type = 'E';

            IF l_asg_exists_count > 0
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'CORRECTION');
               l_datetrack_update_mode := 'CORRECTION';
            END IF;

            SELECT DECODE (xx_asg_rec_main.country,
                           'US', TRUNC (xx_asg_rec_main.effective_start_date),
                           SYSDATE
                          )
              INTO l_effective_date
              FROM DUAL;

            BEGIN
               x_cagr_grade_def_id := NULL;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' l_datetrack_update_mode => '
                                     || l_datetrack_update_mode
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        ' organization is is => '
                                     || xx_asg_rec_main.organization_id
                                    );

               IF xx_asg_rec_main.person_type = g_emp_person_type
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'The user person type is '
                                        || g_emp_person_type
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'gov_rep_entity is '
                                        || xx_asg_rec_main.gov_rep_entity
                                       );
                  hr_assignment_api.update_emp_asg
                     (p_validate                          => g_validate_flag,
                      p_effective_date                    => l_effective_date,
                      p_datetrack_update_mode             => l_datetrack_update_mode,
                      p_assignment_id                     => x_assignment_id,
                      p_object_version_number             => x_object_version_number,
                      p_supervisor_id                     => xx_asg_rec_main.supervisor_id,
                      p_assignment_number                 => x_assignment_number, --xx_asg_rec_main.assignment_number, -- Corrected in mock conv
                      p_change_reason                     => xx_asg_rec_main.change_reason,
                      p_assignment_status_type_id         => xx_asg_rec_main.assignment_status_type_id,
                      p_comments                          => hr_api.g_varchar2,
                      p_date_probation_end                => xx_asg_rec_main.date_probation_end,
                      p_default_code_comb_id              => xx_asg_rec_main.default_code_comb_id,
                      p_frequency                         => x_freq_unit,
                      p_internal_address_line             => xx_asg_rec_main.internal_address_line,
                      p_manager_flag                      => xx_asg_rec_main.manager_flag,
                      p_normal_hours                      => xx_asg_rec_main.normal_hours,
                      p_perf_review_period                => xx_asg_rec_main.perf_review_period,
                      p_perf_review_period_frequency      => xx_asg_rec_main.perf_review_period_frequency,
                      p_probation_period                  => xx_asg_rec_main.probation_period,
                      p_probation_unit                    => x_prob_unit,--xx_asg_rec_main.probation_unit,
                      p_projected_assignment_end          => hr_api.g_date,
                      p_sal_review_period                 => xx_asg_rec_main.sal_review_period,
                      p_sal_review_period_frequency       => xx_asg_rec_main.sal_review_period_frequency,
                      p_set_of_books_id                   => xx_asg_rec_main.set_of_books_id,
                      p_source_type                       => xx_asg_rec_main.source_type,
                      p_time_normal_finish                => xx_asg_rec_main.time_normal_finish,
                      p_time_normal_start                 => xx_asg_rec_main.time_normal_start,
                      p_bargaining_unit_code              => xx_asg_rec_main.bargaining_unit_code,
                      p_labour_union_member_flag          => xx_asg_rec_main.labour_union_member_flag,
                      p_hourly_salaried_code              => x_hourly_sal_code
                                       -- xx_asg_rec_main.hourly_salaried_code
                                                                              ,
                      p_ass_attribute_category            => xx_asg_rec_main.ass_attribute_category,
                      p_ass_attribute1                    => xx_asg_rec_main.hr_rep_id,
                      p_ass_attribute2                    => xx_asg_rec_main.hr_director_id,
                      p_ass_attribute3                    => xx_asg_rec_main.ass_attribute3,
                      p_ass_attribute4                    => xx_asg_rec_main.ass_attribute4,
                      p_ass_attribute5                    => xx_asg_rec_main.ass_attribute5,
                      p_ass_attribute6                    => xx_asg_rec_main.ass_attribute6,
                      p_ass_attribute7                    => xx_asg_rec_main.ass_attribute7,
                      p_ass_attribute8                    => xx_asg_rec_main.ass_attribute8,
                      p_ass_attribute9                    => xx_asg_rec_main.ass_attribute9,
                      p_ass_attribute10                   => xx_asg_rec_main.ass_attribute10,
                      p_title                             => NULL,
                      p_segment1                          => --110
                                   COALESCE(xx_asg_rec_main.gov_rep_entity
                                         ,xx_asg_rec_main.employer_paye_ref_gb
              ,xx_asg_rec_main.govt_rep_entity_t4_rl1
              ,xx_asg_rec_main.tax_district_ref
              ,xx_asg_rec_main.govt_rep_entity_mx
              ,xx_asg_rec_main.reg_employer
              ,xx_asg_rec_main.legal_employer_au),
                      p_segment2                          => COALESCE
                                                                (xx_asg_rec_main.timecard_approver_us,
                                                                 xx_asg_rec_main.timecard_approver_ca,
                                                                 xx_asg_rec_main.ie_paypath_info,
                                                                 xx_asg_rec_main.timecard_approver_mx,
                                                                 xx_asg_rec_main.holiday_anniv_date,
                                                                 xx_asg_rec_main.incl_leave_loading,
                                                                 xx_asg_rec_main.emp_type_be,
                                                                 xx_asg_rec_main.EXEMPT,
                                                                 xx_asg_rec_main.emp_cat_fr
                                                                ),
                      p_segment3                          => COALESCE
                                                                (xx_asg_rec_main.timecard_required_us,
                                                                 xx_asg_rec_main.timecard_required_ca,
                                                                 xx_asg_rec_main.employer_paye_ref_ie,
                                                                 xx_asg_rec_main.timecard_required_mx,
                                                                 xx_asg_rec_main.grp_cert_issue_date,
                                                                 xx_asg_rec_main.emp_coding,
                                                                 xx_asg_rec_main.liab_ins_provider,
                                                                 xx_asg_rec_main.start_reason_fr
                                                                ),
                      p_segment4                          => COALESCE
                                                                (xx_asg_rec_main.work_schedule_us,
                                                                 xx_asg_rec_main.max_hol_per_adv,
                                                                 xx_asg_rec_main.work_schedule_ca,
                                                                 xx_asg_rec_main.legal_employer_ie,
                                                                 xx_asg_rec_main.work_schedule_mx,
                                                                 xx_asg_rec_main.hours_sgc_calc,
                                                                 xx_asg_rec_main.work_schedule_be,
                                                                 xx_asg_rec_main.class_of_risk,
                                                                 xx_asg_rec_main.end_reason_fr
                                                                ),
                      p_segment5                          => COALESCE
                                                                (xx_asg_rec_main.shift_us,
                                                                 xx_asg_rec_main.shift_ca,
                                                                 xx_asg_rec_main.govt_emp_sector,
                                                                 xx_asg_rec_main.start_reason_be,
                                                                 xx_asg_rec_main.work_pattern
                                                                ),
                      p_segment6                          => COALESCE
                                                                (xx_asg_rec_main.spouse_salary,
                                                                 xx_asg_rec_main.naic_override_code,
                                                                 xx_asg_rec_main.soc_sec_sal_type,
                                                                 xx_asg_rec_main.end_reason_be,
                                                                 xx_asg_rec_main.urssaf_code
                                                                ),
                      p_segment7                          => COALESCE
                                                                (xx_asg_rec_main.legal_rep,
                                                                 xx_asg_rec_main.seasonal_worker_ca,
                                                                 xx_asg_rec_main.corps
                                                                ),
                      p_segment8                          => COALESCE
                                                                (xx_asg_rec_main.worker_comp_override_code,
                                                                 xx_asg_rec_main.officer_code,
                                                                 xx_asg_rec_main.stat_position
                                                                ),
                      p_segment9                          => COALESCE
                                                                (xx_asg_rec_main.reporting_estab,
                                                                 xx_asg_rec_main.bacs_pay_rule,
                                                                 xx_asg_rec_main.work_comp_acct_num_override,
                                                                 xx_asg_rec_main.physical_share
                                                                ),
                      p_segment10                         => COALESCE
                                                                (xx_asg_rec_main.seasonal_worker_us,
                                                                 xx_asg_rec_main.unique_id_gb,
                                                                 xx_asg_rec_main.work_comp_rate_code_override,
                                                                 xx_asg_rec_main.ss_rehire_rep,
                                                                 xx_asg_rec_main.pub_sector_emp_type
                                                                ),
                      p_segment11                         => COALESCE
                                                                (xx_asg_rec_main.corp_officer_ind,
                                                                 xx_asg_rec_main.smp_recovered,
                                                                 xx_asg_rec_main.govt_rep_entity_t4a_rl1,
                                                                 xx_asg_rec_main.comp_subsidy_emp,
                                                                 xx_asg_rec_main.work_pattern_start_day
                                                                ),
                      p_segment12                         => COALESCE
                                                                (xx_asg_rec_main.area_code,
                                                                 xx_asg_rec_main.smp_compensation,
                                                                 xx_asg_rec_main.govt_rep_entity_t4_rl2,
                                                                 xx_asg_rec_main.detache_status
                                                                ),
                      p_segment13                         => COALESCE
                                                                (xx_asg_rec_main.occupational_code,
                                                                 xx_asg_rec_main.ssp_recovered,
                                                                 xx_asg_rec_main.address_abroad
                                                                ),
                      p_segment14                         => COALESCE
                                                                (xx_asg_rec_main.wage_plan_code,
                                                                 xx_asg_rec_main.econ,
                                                                 xx_asg_rec_main.border_worker
                                                                ),
                      p_segment15                         => COALESCE
                                                                (xx_asg_rec_main.probationary_code,
                                                                 xx_asg_rec_main.sap_recovered,
                                                                 xx_asg_rec_main.work_days_per_yr
                                                                ),
                      p_segment16                         => COALESCE
                                                                (xx_asg_rec_main.seasonal_code,
                                                                 xx_asg_rec_main.sap_compensation,
                                                                 xx_asg_rec_main.prof_status
                                                                ),
                      p_segment17                         => COALESCE
                                                                (xx_asg_rec_main.corp_officer_code,
                                                                 xx_asg_rec_main.spp_recovered,
                                                                 xx_asg_rec_main.reason_non_titulaire
                                                                ),
                      p_segment18                         => COALESCE
                                                                (xx_asg_rec_main.tax_loc,
                                                                 xx_asg_rec_main.spp_compensation
                                                                ),
                      p_segment19                         => COALESCE
                                                                (xx_asg_rec_main.pvt_disability_plan_id,
                                                                 xx_asg_rec_main.reason_part_time
                                                                ),
                      p_segment20                         => COALESCE
                                                                (xx_asg_rec_main.family_leave_ins_plan_id,
                                                                 xx_asg_rec_main.comments_fr
                                                                ),
                      p_segment21                         => xx_asg_rec_main.alpha_ind_class_code,
                      p_segment23                         => xx_asg_rec_main.identifier_fr,
                      p_segment24                         => xx_asg_rec_main.affectation_type,
                      p_segment25                         => xx_asg_rec_main.percent_affected,
                      p_segment26                         => xx_asg_rec_main.admin_career_id,
                      p_segment27                         => xx_asg_rec_main.primary_affectation,
                      p_segment28                         => xx_asg_rec_main.grouping_emp_name,
                      p_concat_segments                   => NULL
                                                -- xx_asg_rec_main.concat_segs
                                                                 ,
                      p_contract_id                       => xx_asg_rec_main.contract_id,
                      p_establishment_id                  => xx_asg_rec_main.establishment_id,
                      p_collective_agreement_id           => xx_asg_rec_main.collective_agreement_id,
                      p_cagr_id_flex_num                  => NULL,
                      p_cag_segment1                      => NULL,
                      p_cag_segment2                      => NULL,
                      p_cag_segment3                      => NULL,
                      p_cag_segment4                      => NULL,
                      p_cag_segment5                      => NULL,
                      p_cag_segment6                      => NULL,
                      p_cag_segment7                      => NULL,
                      p_cag_segment8                      => NULL,
                      p_cag_segment9                      => NULL,
                      p_cag_segment10                     => NULL,
                      p_cag_segment11                     => NULL,
                      p_cag_segment12                     => NULL,
                      p_cag_segment13                     => NULL,
                      p_cag_segment14                     => NULL,
                      p_cag_segment15                     => NULL,
                      p_cag_segment16                     => NULL,
                      p_cag_segment17                     => NULL,
                      p_cag_segment18                     => NULL,
                      p_cag_segment19                     => NULL,
                      p_cag_segment20                     => NULL,
                      p_notice_period                     => xx_asg_rec_main.notice_period,
                      p_notice_period_uom                 => xx_asg_rec_main.notice_period_uom,
                      p_employee_category                 => xx_asg_rec_main.employee_category,
                      p_work_at_home                      => xx_asg_rec_main.work_at_home,
                      p_job_post_source_name              => xx_asg_rec_main.job_post_source_name,
                      p_supervisor_assignment_id          => NULL,
                      p_cagr_grade_def_id                 => x_cagr_grade_def_id,
                      p_cagr_concatenated_segments        => x_cagr_concatenated_segments,
                      p_concatenated_segments             => x_concatenated_segments,
                      p_soft_coding_keyflex_id            => x_soft_coding_keyflex_id,
                      p_comment_id                        => x_comment_id,
                      p_effective_start_date              => x_effective_start_date,
                      p_effective_end_date                => x_effective_end_date,
                      p_no_managers_warning               => x_no_managers_warning,
                      p_other_manager_warning             => x_other_manager_warning,
                      p_hourly_salaried_warning           => x_hourly_salaried_warning,
                      p_gsp_post_process_warning          => x_gsp_post_process_warning
                     );
                  xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'The soft coding key flex field id from API is'
                            || x_soft_coding_keyflex_id
                           );
               ELSIF xx_asg_rec_main.person_type <> g_emp_person_type --xx_asg_rec_main.person_type = g_cwk_person_type
                                                                      --Changed post CRP3 01-JUN-2012
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'The user person type is '
                                        || xx_asg_rec_main.person_type
                                       );
                  hr_assignment_api.update_cwk_asg
                     (p_validate                        => g_validate_flag,
                      p_effective_date                  => xx_asg_rec_main.effective_start_date,
                      p_datetrack_update_mode           => l_datetrack_update_mode,
                      p_assignment_id                   => x_assignment_id,
                      p_object_version_number           => x_object_version_number,
                      p_assignment_category             => xx_asg_rec_main.assignment_category,
                      p_assignment_number               => xx_asg_rec_main.assignment_number,
                      p_change_reason                   => xx_asg_rec_main.change_reason,
                      p_comments                        => hr_api.g_varchar2,
                      p_default_code_comb_id            => xx_asg_rec_main.default_code_comb_id,
                      p_establishment_id                => xx_asg_rec_main.establishment_id,
                      p_frequency                       => x_freq_unit,--xx_asg_rec_main.frequency,--Changed post CRP3 01-JUN-2012
                      p_internal_address_line           => xx_asg_rec_main.internal_address_line,
                      p_labour_union_member_flag        => xx_asg_rec_main.labour_union_member_flag,
                      p_manager_flag                    => xx_asg_rec_main.manager_flag,
                      p_normal_hours                    => xx_asg_rec_main.normal_hours,
                      p_project_title                   => xx_asg_rec_main.project_title,
                      p_set_of_books_id                 => xx_asg_rec_main.set_of_books_id,
                      p_source_type                     => xx_asg_rec_main.source_type,
                      p_supervisor_id                   => xx_asg_rec_main.supervisor_id,
                      p_time_normal_finish              => xx_asg_rec_main.time_normal_finish,
                      p_time_normal_start               => xx_asg_rec_main.time_normal_start,
                      p_title                           => hr_api.g_varchar2,
                      p_vendor_assignment_number        => xx_asg_rec_main.vendor_assignment_number,
                      p_vendor_employee_number          => xx_asg_rec_main.vendor_employee_number,
                      p_vendor_id                       => NULL,
                      p_vendor_site_id                  => NULL,
                      p_po_header_id                    => NULL,
                      p_po_line_id                      => NULL,
                      p_projected_assignment_end        => NULL,
                      p_assignment_status_type_id       => xx_asg_rec_main.assignment_status_type_id,
                      p_concat_segments                 => NULL,
                      p_attribute_category              => xx_asg_rec_main.ass_attribute_category,
                      p_attribute1                      => xx_asg_rec_main.hr_rep_id,
                      p_attribute2                      => xx_asg_rec_main.hr_director_id,
                      p_attribute3                      => xx_asg_rec_main.ass_attribute3,
                      p_attribute4                      => xx_asg_rec_main.ass_attribute4,
                      p_attribute5                      => xx_asg_rec_main.ass_attribute5,
                      p_attribute6                      => xx_asg_rec_main.ass_attribute6,
                      p_attribute7                      => xx_asg_rec_main.ass_attribute7,
                      p_attribute8                      => xx_asg_rec_main.ass_attribute8,
                      p_attribute9                      => xx_asg_rec_main.ass_attribute9,
                      p_attribute10                     => xx_asg_rec_main.ass_attribute10,
                      p_scl_segment1                    => COALESCE
                                                              (xx_asg_rec_main.gov_rep_entity,
                                                               xx_asg_rec_main.employer_paye_ref_gb,
                                                               xx_asg_rec_main.govt_rep_entity_t4_rl1,
                                                               xx_asg_rec_main.tax_district_ref,
                                                               xx_asg_rec_main.govt_rep_entity_mx,
                                                               xx_asg_rec_main.reg_employer,
                                                               xx_asg_rec_main.legal_employer_au
                                                              ),
                      p_scl_segment2                    => COALESCE
                                                              (xx_asg_rec_main.timecard_approver_us,
                                                               xx_asg_rec_main.timecard_approver_ca,
                                                               xx_asg_rec_main.ie_paypath_info,
                                                               xx_asg_rec_main.timecard_approver_mx,
                                                               xx_asg_rec_main.holiday_anniv_date,
                                                               xx_asg_rec_main.incl_leave_loading,
                                                               xx_asg_rec_main.emp_type_be,
                                                               xx_asg_rec_main.EXEMPT,
                                                               xx_asg_rec_main.emp_cat_fr
                                                              ),
                      p_scl_segment3                    => COALESCE
                                                              (xx_asg_rec_main.timecard_required_us,
                                                               xx_asg_rec_main.timecard_required_ca,
                                                               xx_asg_rec_main.employer_paye_ref_ie,
                                                               xx_asg_rec_main.timecard_required_mx,
                                                               xx_asg_rec_main.grp_cert_issue_date,
                                                               xx_asg_rec_main.emp_coding,
                                                               xx_asg_rec_main.liab_ins_provider,
                                                               xx_asg_rec_main.start_reason_fr
                                                              ),
                      p_scl_segment4                    => COALESCE
                                                              (xx_asg_rec_main.work_schedule_us,
                                                               xx_asg_rec_main.max_hol_per_adv,
                                                               xx_asg_rec_main.work_schedule_ca,
                                                               xx_asg_rec_main.legal_employer_ie,
                                                               xx_asg_rec_main.work_schedule_mx,
                                                               xx_asg_rec_main.hours_sgc_calc,
                                                               xx_asg_rec_main.work_schedule_be,
                                                               xx_asg_rec_main.class_of_risk,
                                                               xx_asg_rec_main.end_reason_fr
                                                              ),
                      p_scl_segment5                    => COALESCE
                                                              (xx_asg_rec_main.shift_us,
                                                               xx_asg_rec_main.shift_ca,
                                                               xx_asg_rec_main.govt_emp_sector,
                                                               xx_asg_rec_main.start_reason_be,
                                                               xx_asg_rec_main.work_pattern
                                                              ),
                      p_scl_segment6                    => COALESCE
                                                              (xx_asg_rec_main.spouse_salary,
                                                               xx_asg_rec_main.naic_override_code,
                                                               xx_asg_rec_main.soc_sec_sal_type,
                                                               xx_asg_rec_main.end_reason_be,
                                                               xx_asg_rec_main.urssaf_code
                                                              ),
                      p_scl_segment7                    => COALESCE
                                                              (xx_asg_rec_main.legal_rep,
                                                               xx_asg_rec_main.seasonal_worker_ca,
                                                               xx_asg_rec_main.corps
                                                              ),
                      p_scl_segment8                    => COALESCE
                                                              (xx_asg_rec_main.worker_comp_override_code,
                                                               xx_asg_rec_main.officer_code,
                                                               xx_asg_rec_main.stat_position
                                                              ),
                      p_scl_segment9                    => COALESCE
                                                              (xx_asg_rec_main.reporting_estab,
                                                               xx_asg_rec_main.bacs_pay_rule,
                                                               xx_asg_rec_main.work_comp_acct_num_override,
                                                               xx_asg_rec_main.physical_share
                                                              ),
                      p_scl_segment10                   => COALESCE
                                                              (xx_asg_rec_main.seasonal_worker_us,
                                                               xx_asg_rec_main.unique_id_gb,
                                                               xx_asg_rec_main.work_comp_rate_code_override,
                                                               xx_asg_rec_main.ss_rehire_rep,
                                                               xx_asg_rec_main.pub_sector_emp_type
                                                              ),
                      p_scl_segment11                   => COALESCE
                                                              (xx_asg_rec_main.corp_officer_ind,
                                                               xx_asg_rec_main.smp_recovered,
                                                               xx_asg_rec_main.govt_rep_entity_t4a_rl1,
                                                               xx_asg_rec_main.comp_subsidy_emp,
                                                               xx_asg_rec_main.work_pattern_start_day
                                                              ),
                      p_scl_segment12                   => COALESCE
                                                              (xx_asg_rec_main.area_code,
                                                               xx_asg_rec_main.smp_compensation,
                                                               xx_asg_rec_main.govt_rep_entity_t4_rl2,
                                                               xx_asg_rec_main.detache_status
                                                              ),
                      p_scl_segment13                   => COALESCE
                                                              (xx_asg_rec_main.occupational_code,
                                                               xx_asg_rec_main.ssp_recovered,
                                                               xx_asg_rec_main.address_abroad
                                                              ),
                      p_scl_segment14                   => COALESCE
                                                              (xx_asg_rec_main.wage_plan_code,
                                                               xx_asg_rec_main.econ,
                                                               xx_asg_rec_main.border_worker
                                                              ),
                      p_scl_segment15                   => COALESCE
                                                              (xx_asg_rec_main.probationary_code,
                                                               xx_asg_rec_main.sap_recovered,
                                                               xx_asg_rec_main.work_days_per_yr
                                                              ),
                      p_scl_segment16                   => COALESCE
                                                              (xx_asg_rec_main.seasonal_code,
                                                               xx_asg_rec_main.sap_compensation,
                                                               xx_asg_rec_main.prof_status
                                                              ),
                      p_scl_segment17                   => COALESCE
                                                              (xx_asg_rec_main.corp_officer_code,
                                                               xx_asg_rec_main.spp_recovered,
                                                               xx_asg_rec_main.reason_non_titulaire
                                                              ),
                      p_scl_segment18                   => COALESCE
                                                              (xx_asg_rec_main.tax_loc,
                                                               xx_asg_rec_main.spp_compensation
                                                              ),
                      p_scl_segment19                   => COALESCE
                                                              (xx_asg_rec_main.pvt_disability_plan_id,
                                                               xx_asg_rec_main.reason_part_time
                                                              ),
                      p_scl_segment20                   => COALESCE
                                                              (xx_asg_rec_main.family_leave_ins_plan_id,
                                                               xx_asg_rec_main.comments_fr
                                                              ),
                      p_scl_segment21                   => xx_asg_rec_main.alpha_ind_class_code,
                      p_scl_segment23                   => xx_asg_rec_main.identifier_fr,
                      p_scl_segment24                   => xx_asg_rec_main.affectation_type,
                      p_scl_segment25                   => xx_asg_rec_main.percent_affected,
                      p_scl_segment26                   => xx_asg_rec_main.admin_career_id,
                      p_scl_segment27                   => xx_asg_rec_main.primary_affectation,
                      p_scl_segment28                   => xx_asg_rec_main.grouping_emp_name,
                      p_supervisor_assignment_id        => NULL,
                      p_org_now_no_manager_warning      => x_org_now_no_manager_warning,
                      p_effective_start_date            => x_effective_start_date,
                      p_effective_end_date              => x_effective_end_date,
                      p_comment_id                      => x_comment_id,
                      p_no_managers_warning             => x_no_managers_warning,
                      p_other_manager_warning           => x_other_manager_warning,
                      p_soft_coding_keyflex_id          => x_soft_coding_keyflex_id,
                      p_concatenated_segments           => x_concatenated_segments,
                      p_hourly_salaried_warning         => x_hourly_salaried_warning
                     );
                  xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'The soft coding key flex field id from API is'
                            || x_soft_coding_keyflex_id
                           );
               END IF;                             -- end of person type check
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  l_sqlerrm := SQLERRM;
                  xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                ' At Exception Set Assignment  x_error_code '
                             || x_error_code
                             || ' Rows Updated as Error '
                             || SQL%ROWCOUNT
                            );
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               => l_sqlerrm,
                      p_record_identifier_1      => xx_asg_rec_main.employee_number,
                      p_record_identifier_2      => xx_asg_rec_main.first_name,
                      p_record_identifier_3      => xx_asg_rec_main.last_name,
                      p_record_identifier_4      => xx_asg_rec_main.LOCATION,
                      p_record_identifier_5      => 'Assignment Creation API'
                     );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Error from API is ' || l_sqlerrm
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'RECORD_NUMBER '
                                        || xx_asg_rec_main.record_number
                                        || ' G_BATCH_ID '
                                        || g_batch_id
                                       );

                  UPDATE xx_hr_asg_pre
                     SET ERROR_CODE = x_error_code
                   WHERE record_number = xx_asg_rec_main.record_number
                     AND batch_id = g_batch_id;

                  COMMIT;
            END;                                   --END Update Assignment API

            BEGIN                              -- Updating Assignment Criteria
               x_special_ceiling_step_id := NULL;
               x_people_group_id := NULL;

               BEGIN
                  x_err_point :=
                             'FIND ASSIGNMENT FOR ASSIGNMENT CRITERIA UPDATE';

                  SELECT paaf.object_version_number, paaf.assignment_id,
                         paaf.assignment_number, paaf.effective_start_date
                    INTO x_object_version_number, x_assignment_id,
                         x_assignment_number, l_effective_start_date
                    FROM per_all_assignments_f paaf, per_all_people_f papf
                   WHERE papf.attribute1 =
                            xx_asg_rec_main.person_unique_id
 -- papf.attribute2   = xx_asg_rec_main.employee_number -- changed for integra
                     AND papf.person_id = paaf.person_id
                     AND NVL (xx_asg_rec_main.effective_start_date, SYSDATE)
                            BETWEEN paaf.effective_start_date
                                AND paaf.effective_end_date
                     AND NVL (xx_asg_rec_main.effective_start_date, SYSDATE)
                            BETWEEN papf.effective_start_date
                                AND papf.effective_end_date;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_sqlerrm := SQLERRM;
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              ' At '
                                           || x_err_point
                                           || x_error_code
                                           || ' Rows Updated as Error '
                                           || SQL%ROWCOUNT
                                          );
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_low,
                         p_category                 => xx_emf_cn_pkg.cn_tech_error,
                         p_error_text               => l_sqlerrm,
                         p_record_identifier_1      => xx_asg_rec_main.employee_number,
                         p_record_identifier_2      => xx_asg_rec_main.first_name,
                         p_record_identifier_3      => xx_asg_rec_main.last_name,
                         p_record_identifier_4      => xx_asg_rec_main.LOCATION,
                         p_record_identifier_5      => 'Pick Assignment'
                        );
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'record_number= '
                                           || xx_asg_rec_main.record_number
                                           || ' G_BATCH_ID '
                                           || g_batch_id
                                          );
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;

                     UPDATE xx_hr_asg_pre
                        SET ERROR_CODE = x_error_code
                      WHERE record_number = xx_asg_rec_main.record_number
                        AND batch_id = g_batch_id;

                     COMMIT;
               END;

               IF l_effective_start_date <
                                          xx_asg_rec_main.effective_start_date
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'UPDATE');
                  l_datetrack_update_mode := 'UPDATE';
               ELSE
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'CORRECTION');
                  l_datetrack_update_mode := 'CORRECTION';
               END IF;

               IF g_validate_flag = FALSE
               THEN
                  IF xx_asg_rec_main.person_type = g_emp_person_type
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'The user person type is '
                                           || g_emp_person_type
                                          );
                     hr_assignment_api.update_emp_asg_criteria
                        (p_effective_date                    => l_effective_date,
                         p_datetrack_update_mode             => l_datetrack_update_mode,
                         p_assignment_id                     => x_assignment_id,
                         p_validate                          => g_validate_flag,
                         p_called_from_mass_update           => FALSE,
                         p_grade_id                          => xx_asg_rec_main.grade_id,
                         p_position_id                       => xx_asg_rec_main.position_id,
                         p_job_id                            => xx_asg_rec_main.job_id,
                         p_payroll_id                        => xx_asg_rec_main.payroll_id,
                         p_location_id                       => xx_asg_rec_main.location_id,
                         p_organization_id                   => xx_asg_rec_main.organization_id,
                         p_pay_basis_id                      => xx_asg_rec_main.pay_basis_id,
                         p_segment1                          => xx_asg_rec_main.segment1,
                         p_segment2                          => xx_asg_rec_main.segment2,
                         p_segment3                          => xx_asg_rec_main.segment3,
                         p_segment4                          => xx_asg_rec_main.segment4,
                         p_segment5                          => xx_asg_rec_main.segment5,
                         p_segment6                          => xx_asg_rec_main.segment6,
                         p_segment7                          => xx_asg_rec_main.segment7,
                         p_segment8                          => xx_asg_rec_main.segment8,
                         p_segment9                          => xx_asg_rec_main.segment9,
                         p_segment10                         => xx_asg_rec_main.segment10,
                         p_employment_category               => xx_asg_rec_main.assignment_category
                         -- data file has no column called employment_category
                                                                                                   ,
                         p_object_version_number             => x_object_version_number,
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
                     xx_emf_pkg.write_log
                                         (xx_emf_cn_pkg.cn_low,
                                             'The people_group_id from API is'
                                          || x_people_group_id
                                         );
                  ELSIF xx_asg_rec_main.person_type <> g_emp_person_type --xx_asg_rec_main.person_type = g_cwk_person_type
                                                                         --Changed post CRP3 01-JUN-2012
                  THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'The user person type is '
                                           || xx_asg_rec_main.person_type
                                          );
                     hr_assignment_api.update_cwk_asg_criteria
                        (p_validate                          => g_validate_flag,
                         p_effective_date                    => xx_asg_rec_main.effective_start_date,
                         p_datetrack_update_mode             => l_datetrack_update_mode,
                         p_assignment_id                     => x_assignment_id,
                         p_called_from_mass_update           => FALSE,
                         p_object_version_number             => x_object_version_number,
                         p_grade_id                          => xx_asg_rec_main.grade_id,
                         p_position_id                       => xx_asg_rec_main.position_id,
                         p_job_id                            => xx_asg_rec_main.job_id,
                         p_location_id                       => xx_asg_rec_main.location_id,
                         p_organization_id                   => xx_asg_rec_main.organization_id,
                         p_pay_basis_id                      => xx_asg_rec_main.pay_basis_id,
                         p_segment1                          => xx_asg_rec_main.segment1,
                         p_segment2                          => xx_asg_rec_main.segment2,
                         p_segment3                          => xx_asg_rec_main.segment3,
                         p_segment4                          => xx_asg_rec_main.segment4,
                         p_segment5                          => xx_asg_rec_main.segment5,
                         p_segment6                          => xx_asg_rec_main.segment6,
                         p_segment7                          => xx_asg_rec_main.segment7,
                         p_segment8                          => xx_asg_rec_main.segment8,
                         p_segment9                          => xx_asg_rec_main.segment9,
                         p_segment10                         => xx_asg_rec_main.segment10,
                         p_concat_segments                   => NULL,
                         p_people_group_name                 => x_group_name,
                         p_effective_start_date              => x_effective_start_date,
                         p_effective_end_date                => x_effective_end_date,
                         p_people_group_id                   => x_people_group_id,
                         p_org_now_no_manager_warning        => x_org_now_no_manager_warning,
                         p_other_manager_warning             => x_other_manager_warning,
                         p_spp_delete_warning                => x_spp_delete_warning,
                         p_entries_changed_warning           => x_entries_changed_warning,
                         p_tax_district_changed_warning      => x_tax_district_changed_warning
                        );
                     xx_emf_pkg.write_log
                                         (xx_emf_cn_pkg.cn_low,
                                             'The people_group_id from API is'
                                          || x_people_group_id
                                         );
                  END IF;         -- end of person type check for criteria api
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_sqlerrm := SQLERRM;
                  xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            ' At Exception Assignment Criteria x_error_code '
                         || x_error_code
                         || 'Rows Updated as Error '
                         || SQL%ROWCOUNT
                        );
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_low,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               => l_sqlerrm,
                      p_record_identifier_1      => xx_asg_rec_main.employee_number,
                      p_record_identifier_2      => xx_asg_rec_main.first_name,
                      p_record_identifier_3      => xx_asg_rec_main.last_name,
                      p_record_identifier_4      => xx_asg_rec_main.LOCATION,
                      p_record_identifier_5      => 'Assignment Criteria API'
                     );
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;

                  UPDATE xx_hr_asg_pre
                     SET ERROR_CODE = x_error_code
                   WHERE record_number = xx_asg_rec_main.record_number
                     AND batch_id = g_batch_id;

                  COMMIT;
            END;                           --End Updating Assignment Crieteria

            -- additions for integra - start
            -- create EIT data
            IF xx_asg_rec_main.eit_information_type <> NULL
            THEN
               BEGIN
                  xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      'Before calling hr_assignment_extra_info_api.create_assignment_extra_info'
                     );
                  hr_assignment_extra_info_api.create_assignment_extra_info
                     (p_validate                      => g_validate_flag,
                      p_assignment_id                 => x_assignment_id,
                      p_information_type              => xx_asg_rec_main.eit_information_type,
                      p_aei_attribute_category        => NULL,
                      p_aei_attribute1                => NULL,
                      p_aei_attribute2                => NULL,
                      p_aei_attribute3                => NULL,
                      p_aei_attribute4                => NULL,
                      p_aei_attribute5                => NULL,
                      p_aei_attribute6                => NULL,
                      p_aei_attribute7                => NULL,
                      p_aei_attribute8                => NULL,
                      p_aei_attribute9                => NULL,
                      p_aei_attribute10               => NULL,
                      p_aei_attribute11               => NULL,
                      p_aei_attribute12               => NULL,
                      p_aei_attribute13               => NULL,
                      p_aei_attribute14               => NULL,
                      p_aei_attribute15               => NULL,
                      p_aei_attribute16               => NULL,
                      p_aei_attribute17               => NULL,
                      p_aei_attribute18               => NULL,
                      p_aei_attribute19               => NULL,
                      p_aei_attribute20               => NULL,
                      p_aei_information_category      => xx_asg_rec_main.eit_information_category,
                      p_aei_information1              => xx_asg_rec_main.eit1,
                      p_aei_information2              => xx_asg_rec_main.eit2,
                      p_aei_information3              => xx_asg_rec_main.eit3,
                      p_aei_information4              => xx_asg_rec_main.eit4,
                      p_aei_information5              => xx_asg_rec_main.eit5,
                      p_aei_information6              => xx_asg_rec_main.eit6,
                      p_aei_information7              => xx_asg_rec_main.eit7,
                      p_aei_information8              => xx_asg_rec_main.eit8,
                      p_aei_information9              => xx_asg_rec_main.eit9,
                      p_aei_information10             => xx_asg_rec_main.eit10,
                      p_aei_information11             => NULL,
                      p_aei_information12             => NULL,
                      p_aei_information13             => NULL,
                      p_aei_information14             => NULL,
                      p_aei_information15             => NULL,
                      p_aei_information16             => NULL,
                      p_aei_information17             => NULL,
                      p_aei_information18             => NULL,
                      p_aei_information19             => NULL,
                      p_aei_information20             => NULL,
                      p_aei_information21             => NULL,
                      p_aei_information22             => NULL,
                      p_aei_information23             => NULL,
                      p_aei_information24             => NULL,
                      p_aei_information25             => NULL,
                      p_aei_information26             => NULL,
                      p_aei_information27             => NULL,
                      p_aei_information28             => NULL,
                      p_aei_information29             => NULL,
                      p_aei_information30             => NULL,
                      p_assignment_extra_info_id      => x_assignment_extra_info_id,
                      p_object_version_number         => x_object_version_number
                     );
                  xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'x_assignment_extra_info_id from eit API is '
                              || x_assignment_extra_info_id
                             );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_sqlerrm := SQLERRM;
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_low,
                         p_category                 => xx_emf_cn_pkg.cn_tech_error,
                         p_error_text               => l_sqlerrm,
                         p_record_identifier_1      => xx_asg_rec_main.employee_number,
                         p_record_identifier_2      => xx_asg_rec_main.first_name,
                         p_record_identifier_3      => xx_asg_rec_main.last_name,
                         p_record_identifier_4      => xx_asg_rec_main.LOCATION,
                         p_record_identifier_5      => 'Assignment Extra Info API'
                        );
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'record_number= '
                                           || xx_asg_rec_main.record_number
                                           || ' G_BATCH_ID '
                                           || g_batch_id
                                          );

                     UPDATE xx_hr_asg_pre
                        SET ERROR_CODE = x_error_code
                      WHERE record_number = xx_asg_rec_main.record_number
                        AND batch_id = g_batch_id;
               END;                         --create_assignment_extra_info API
            END IF;
         -- additions for integta - end

         /* commented for integra - start
          IF xx_asg_rec_main.supervisor_id is not null THEN

          BEGIN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'supervisor_id is not null' );

                 x_err_point:='FIND ASSIGNMENT FOR SUPERVISOR';
          SELECT paaf.object_version_number, paaf.assignment_id
                        ,paaf.assignment_number, paaf.effective_start_date
          INTO x_object_version_number, x_assignment_id
              ,x_assignment_number, l_effective_start_date
          FROM
           per_all_assignments_f paaf
                  ,per_all_people_f      papf
                WHERE papf.attribute2   = xx_asg_rec_main.employee_number
                 AND papf.person_id    = paaf.person_id
                 AND NVL(xx_asg_rec_main.effective_start_date,SYSDATE) between paaf.effective_start_date and paaf.effective_end_date
                 AND NVL(xx_asg_rec_main.effective_start_date,SYSDATE) between papf.effective_start_date and papf.effective_end_date;


                  IF TRUNC(l_effective_start_date) < TRUNC(xx_asg_rec_main.superviser_start_date) THEN
                  l_datetrack_update_mode := 'UPDATE';
               l_effective_start_date :=TRUNC(xx_asg_rec_main.superviser_start_date);
                       SELECT paaf.object_version_number,paaf.assignment_number
                INTO x_object_version_number ,x_assignment_number
                FROM per_all_assignments_f paaf
                            ,per_all_people_f      papf
                       WHERE papf.attribute2   = xx_asg_rec_main.employee_number
                         AND papf.person_id    = paaf.person_id
                         AND TRUNC(l_effective_start_date) between paaf.effective_start_date and paaf.effective_end_date
                         AND TRUNC(l_effective_start_date) between papf.effective_start_date and papf.effective_end_date;
          ELSE
              l_datetrack_update_mode := 'CORRECTION';
                  END IF;

          xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,' Super date track '||l_datetrack_update_mode);

          hr_assignment_api.update_emp_asg
                    (p_validate                     => FALSE
                    ,p_effective_date               => l_effective_start_date
                    ,p_datetrack_update_mode        => l_datetrack_update_mode
                    ,p_assignment_id                => x_assignment_id
                    ,p_object_version_number        => x_object_version_number
                    ,p_supervisor_id                => xx_asg_rec_main.supervisor_id
                    ,p_assignment_number            => x_assignment_number
                    ,p_change_reason                => hr_api.g_varchar2
                    ,p_assignment_status_type_id    => hr_api.g_number
                    ,p_comments                     => hr_api.g_varchar2
                    ,p_date_probation_end           => hr_api.g_date
                    ,p_default_code_comb_id         => hr_api.g_number
                    ,p_frequency                    => hr_api.g_varchar2
                    ,p_internal_address_line        => hr_api.g_varchar2
                    ,p_manager_flag                 => hr_api.g_varchar2
                    ,p_normal_hours                 => hr_api.g_number
                    ,p_perf_review_period           => hr_api.g_number
                    ,p_perf_review_period_frequency => hr_api.g_varchar2
                    ,p_probation_period             => hr_api.g_number
                    ,p_probation_unit               => hr_api.g_varchar2
                    ,p_sal_review_period            => hr_api.g_number
                    ,p_sal_review_period_frequency  => hr_api.g_varchar2
                    ,p_set_of_books_id              => hr_api.g_number
                    ,p_source_type                  => hr_api.g_varchar2
                    ,p_time_normal_finish           => hr_api.g_varchar2
                    ,p_time_normal_start            => hr_api.g_varchar2
                    ,p_bargaining_unit_code         => hr_api.g_varchar2
                    ,p_labour_union_member_flag     => hr_api.g_varchar2
                    ,p_hourly_salaried_code         => hr_api.g_varchar2
                    ,p_ass_attribute1               => hr_api.g_varchar2
                    ,p_ass_attribute2               => hr_api.g_varchar2
                    ,p_segment1                     => hr_api.g_varchar2
                    ,p_contract_id                  => hr_api.g_number
                    ,p_establishment_id             => hr_api.g_number
                    ,p_collective_agreement_id      => hr_api.g_number
                    ,p_cagr_id_flex_num             => hr_api.g_number
                    ,p_notice_period                => hr_api.g_number
                    ,p_notice_period_uom                => hr_api.g_varchar2
                    ,p_employee_category              => xx_asg_rec_main.employee_category
                    ,p_work_at_home                 => hr_api.g_varchar2
                    ,p_job_post_source_name         => hr_api.g_varchar2
                    ,p_supervisor_assignment_id     => hr_api.g_number
                    ,p_cagr_grade_def_id            => x_cagr_grade_def_id
                    ,p_cagr_concatenated_segments   => x_cagr_concatenated_segments
                    ,p_concatenated_segments        => x_concatenated_segments
                    ,p_soft_coding_keyflex_id       => x_soft_coding_keyflex_id
                    ,p_comment_id                   => x_comment_id
                    ,p_effective_start_date         => x_effective_start_date
                    ,p_effective_end_date           => x_effective_end_date
                    ,p_no_managers_warning          => x_no_managers_warning
                    ,p_other_manager_warning        => x_other_manager_warning
                    ,p_hourly_salaried_warning      => x_hourly_salaried_warning
                    ,p_gsp_post_process_warning     => x_gsp_post_process_warning
                    );

         EXCEPTION
                 WHEN OTHERS THEN
                   l_sqlerrm := sqlerrm;
                   xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,   p_category => xx_emf_cn_pkg.CN_TECH_ERROR,   p_error_text => l_sqlerrm,   p_record_identifier_1 => xx_asg_rec_main.employee_number,   p_record_identifier_2 => xx_asg_rec_main.last_name || ', ' || xx_asg_rec_main.first_name,   p_record_identifier_3 => 'Supervisor Update API');
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'record_number= '||xx_asg_rec_main.record_number||' G_BATCH_ID '||G_BATCH_ID );
               UPDATE xx_hr_asg_pre
              SET error_code=x_error_code
              WHERE record_number=xx_asg_rec_main.record_number
                AND batch_id=G_BATCH_ID;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,' At Exception supervisor_id NOT NULL x_error_code ' ||x_error_code||' Rows Updated as Error '||SQL%ROWCOUNT);
              END; --Supervisor Update API
           END IF;
           --commented for integra - end */
         END LOOP;

         RETURN x_return_status;
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
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' At Exception 4 x_error_code '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END process_data;

--------------------------------------------------------------------------------
---------------------------< update_record_count >---------------------------------
--------------------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_hr_asg_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (error_count)
              FROM (SELECT COUNT (1) error_count
                      FROM xx_hr_asg_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_hr_asg_pre
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_hr_asg_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;
         x_validate      NUMBER;

         CURSOR c_get_success_cnt (c_validate NUMBER)
         IS
            SELECT COUNT (1) warn_count
              FROM xx_hr_asg_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code =
                      DECODE (c_validate,
                              1, process_code,
                              xx_emf_cn_pkg.cn_process_data
                             )
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         x_success_cnt   NUMBER;
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
--------------------------------------------------------------------------------
   -------  begin of Procedure main started -----
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
                               'Session ID '
                            || fnd_profile.VALUE ('DB_SESSION_ID')
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

      fnd_global.apps_initialize (fnd_global.user_id,
                                  fnd_global.resp_id,
                                  fnd_global.resp_appl_id
                                 );
      fnd_signon.set_session (TO_CHAR (SYSDATE, 'DD-MON-YYYY'));
      -- Call procedure to update records with the assignment mappings
      update_assignment_mappings;
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
         --x_error_code := xx_hr_asg_cnv_validations_pkg.pre_validations ();
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
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
                                     'Call data Validations'
                                    );
               x_error_code :=
                  xx_hr_asg_cnv_validations_pkg.data_validations
                                                       (x_pre_std_hdr_table
                                                                           (i)
                                                       );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Mark-1');
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
                  update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  l_sqlerrm := SQLERRM;
                  xx_emf_pkg.error
                                (xx_emf_cn_pkg.cn_low,
                                 xx_emf_cn_pkg.cn_tech_error,
                                    'While Fetching Cursor c_xx_pre_std_hdr:'
                                 || l_sqlerrm
                                );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Mark-2');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
                               || x_pre_std_hdr_table.COUNT
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Mark-3');
         update_pre_interface_records (x_pre_std_hdr_table);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Mark-3');
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_pre_std_hdr;
      END IF;

      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Mark-4');
      set_stage (xx_emf_cn_pkg.cn_derive);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Mark-5');

      OPEN c_xx_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_xx_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Mark-6');

               -- Perform header level Base App Validations

               -- modified for integra
               IF x_pre_std_hdr_table (i).person_type = g_emp_person_type
               THEN
                  xx_emf_pkg.write_log
                                     (xx_emf_cn_pkg.cn_low,
                                      'Calling data derivations for employee'
                                     );
                  x_error_code :=
                     xx_hr_asg_cnv_validations_pkg.data_derivations
                                                       (x_pre_std_hdr_table
                                                                           (i)
                                                       );
               ELSIF x_pre_std_hdr_table (i).person_type <> g_emp_person_type --x_pre_std_hdr_table (i).person_type = g_cwk_person_type
                                                                              --Changed post CRP3 01-JUN-2012
               THEN
                  xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                             'Calling data derivations for contingent worker'
                            );
                  x_error_code :=
                     xx_hr_cwk_asg_validation_pkg.data_derivations
                                                       (x_pre_std_hdr_table
                                                                           (i)
                                                       );
               END IF;

               xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'after end if  '
                              || x_pre_std_hdr_table (i).assignment_status
                              || 'Derived is '
                              || x_pre_std_hdr_table (i).assignment_status_type_id
                             );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Called Data Derivations'
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               -- xx_emf_pkg.propagate_error (x_error_code);
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'OK ');
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log
                                  (xx_emf_cn_pkg.cn_high,
                                   'Record Level Error in Data derivations 1'
                                  );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  xx_emf_pkg.write_log
                                 (xx_emf_cn_pkg.cn_high,
                                  'Process Level Error in Data derivations 2'
                                 );
                  update_pre_interface_records (x_pre_std_hdr_table);
               WHEN OTHERS
               THEN
                  l_sqlerrm := SQLERRM;
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        'Other Errors Data Der' || SQLERRM
                                       );
                  xx_emf_pkg.error
                       (xx_emf_cn_pkg.cn_low,
                        xx_emf_cn_pkg.cn_tech_error,
                           'While Fetching Cursor c_xx_pre_std_hdr(cn_valid):'
                        || l_sqlerrm
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

      set_stage (xx_emf_cn_pkg.cn_postval);
          --x_error_code := xx_hr_asg_cnv_validations_pkg.post_validations();
      -- dupatil added on 6dec07
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'mark_records_completed Post Validations'
                           );
      -- xx_emf_pkg.propagate_error (x_error_code);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'xx_emf_pkg.propagate_error Post Validations'
                           );
      -- Set the stage to Process Data
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Set Stage Called Process Data ' || x_error_code
                           );
      set_stage (xx_emf_cn_pkg.cn_process_data);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Process Data ' || x_error_code
                           );
      x_error_code := process_data (NULL, NULL);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Called Process Data ' || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_process_data);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After Process Data X_ERROR_CODE ' || x_error_code
                           );
      --xx_emf_pkg.propagate_error (x_error_code);
      update_record_count;
      xx_emf_pkg.create_report;
      COMMIT;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         retcode := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK1' || SQLERRM
                              );
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK2'
                              );
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK ---> ' || SQLERRM
                              );
         xx_emf_pkg.create_report;
   END main;
END xx_hr_asg_conversion_pkg; 
/
