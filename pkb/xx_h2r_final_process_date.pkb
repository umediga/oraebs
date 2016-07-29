DROP PACKAGE BODY APPS.XX_H2R_FINAL_PROCESS_DATE;

CREATE OR REPLACE PACKAGE BODY APPS."XX_H2R_FINAL_PROCESS_DATE" 
AS
/* $Header: XXH2RFINALPRSDAT.pks 1.0.0 2012/05/31 00:00:00$ */
--=============================================================================
-- Created By     : MuthuKumar Chandran
-- Creation Date  : 31-MAY-2012
-- Filename       : XXH2RFINALPRSDAT.pkb
-- Description    : Package body for Final Process Date.
-- Change History:
-- Date          Version#    Name                    Remarks
-- -----------   --------    ---------------         ------------------------
-- 31-MAY-2012   1.0         MuthuKumar Chandran     Initial Development.
--=============================================================================
   ----------------------------------------------------------------------------
   --------------------------< xx_final_process_date >-------------------------
   ----------------------------------------------------------------------------
   PROCEDURE xx_final_process_date (
      o_errbuf       OUT      VARCHAR2,
      o_retcode      OUT      VARCHAR2,
      p_no_of_days   IN       VARCHAR2
   )
   IS
      x_error_code                   NUMBER          := 0;
      x_error_message                VARCHAR2 (2000) := NULL;
      x_count                        NUMBER          := 0;
      x_total_count                  NUMBER          := 0;
      x_success_count                NUMBER          := 0;
      x_error_count                  NUMBER          := 0;
      x_org_now_no_manager_warning   BOOLEAN;
      x_days                         VARCHAR2 (30);
      x_asg_future_changes_warning   BOOLEAN;
      x_entries_changed_warning      VARCHAR2 (100);
      x_object_version_number        NUMBER;
      x_final_process_date           DATE;
      x_end_date                     DATE;

      -- Cursor to fetch Terminated Employee Records
      CURSOR cur_xx_fnl_pr_dat
      IS
         SELECT ppos.person_id
               ,ppos.period_of_service_id
               ,pasf.payroll_id
               ,ppos.actual_termination_date
               ,ppos.object_version_number
           FROM per_periods_of_service ppos
               ,per_all_assignments_f pasf
          WHERE ppos.actual_termination_date IS NOT NULL
            AND ppos.final_process_date IS NULL
            AND pasf.person_id = ppos.person_id
            AND pasf.effective_end_date = ppos.actual_termination_date;

      TYPE xx_final_prdat IS TABLE OF cur_xx_fnl_pr_dat%ROWTYPE;

      x_final_prdat                  xx_final_prdat;
   BEGIN
      o_retcode := xx_emf_cn_pkg.cn_success;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before Setting Environment'
                           );
      -- Emf Env initialization
      x_error_code := xx_emf_pkg.set_env;
      xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_medium,
                         'Starting main process with the following parameters'
                        );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_no_of_days ' || p_no_of_days
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before loop cur_xx_fnl_pr_dat'
                           );

      OPEN cur_xx_fnl_pr_dat;
      FETCH cur_xx_fnl_pr_dat
      BULK COLLECT INTO x_final_prdat;
      CLOSE cur_xx_fnl_pr_dat;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'no of records:' || x_final_prdat.COUNT
                           );

      --Validating whether any employee's are terminated on the given day
      IF x_final_prdat.COUNT = 0
      THEN
         x_error_code := 1;
         x_error_message := 'There are no Terminated Employees to process.';
         xx_emf_pkg.error (p_severity        => xx_emf_cn_pkg.cn_low,
                           p_category        => 'No_Records',
                           p_error_text      => 'E:' || x_error_message
                          );
      ELSE
         FOR i IN x_final_prdat.FIRST .. x_final_prdat.LAST
         LOOP
            IF x_final_prdat (i).payroll_id IS NOT NULL
            THEN
               BEGIN
                  SELECT end_date
                    INTO x_end_date
                    FROM per_time_periods ptp
                   WHERE payroll_id = x_final_prdat (i).payroll_id
                     AND TRUNC (SYSDATE) BETWEEN TRUNC (ptp.start_date)
                                             AND TRUNC (ptp.end_date);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_error_code := 1;
                     x_error_message :=
                              'LAST_STANDARD_PROCESS_DATE can not be derived';
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_low,
                         p_category                 => 'LSPD-DV01',
                         p_error_text               => 'E:' || x_error_message,
                         p_record_identifier_1      => x_final_prdat (i).person_id,
                         p_record_identifier_2      => x_final_prdat (i).actual_termination_date,
                         p_record_identifier_3      => x_final_prdat (i).object_version_number
                        );
               END;
            ELSE
               x_error_code := 1;
               x_error_message := 'Payroll ID is NULL';
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_low,
                   p_category                 => 'LSPD-DV02',
                   p_error_text               => 'E:' || x_error_message,
                   p_record_identifier_1      => x_final_prdat (i).person_id,
                   p_record_identifier_2      => x_final_prdat (i).actual_termination_date,
                   p_record_identifier_3      => x_final_prdat (i).object_version_number
                  );
            END IF;

            IF x_error_code = 0
            THEN
               BEGIN
                  BEGIN
                     SELECT lookup_code
                       INTO x_days
                       FROM fnd_lookup_values
                      WHERE meaning = p_no_of_days
                        AND LANGUAGE = USERENV ('LANG')
                        AND UPPER (lookup_type) = g_lookup_type
                        AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                        AND NVL (end_date_active, SYSDATE);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        x_error_code := 1;
                        x_error_message :=
                             'Error while Fetching lookup values.' || SQLERRM;
                        xx_emf_pkg.error
                           (p_severity                 => xx_emf_cn_pkg.cn_low,
                            p_category                 => 'LKUP-DV03',
                            p_error_text               =>    'E:'
                                                          || x_error_message,
                            p_record_identifier_1      => x_final_prdat (i).person_id,
                            p_record_identifier_2      => x_final_prdat (i).actual_termination_date,
                            p_record_identifier_3      => x_final_prdat (i).object_version_number
                           );
                  END;

                  x_final_process_date :=
                         (x_final_prdat (i).actual_termination_date + x_days
                         );
                  x_object_version_number :=
                                       x_final_prdat (i).object_version_number;
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'x_final_process_date : '
                                        || x_final_process_date
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'x_object_version_number: '
                                        || x_object_version_number
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'period_of_service_id: '
                                        || x_final_prdat (i).period_of_service_id
                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'x_error_code before API call: '
                                        || x_error_code
                                       );
                   --Calling API to update the Final Process Date
                  hr_ex_employee_api.final_process_emp
                     (p_validate                        => FALSE,
                      p_period_of_service_id            => x_final_prdat (i).period_of_service_id,
                      p_object_version_number           => x_object_version_number,
                      p_final_process_date              => x_final_process_date,
                      p_org_now_no_manager_warning      => x_org_now_no_manager_warning,
                      p_asg_future_changes_warning      => x_asg_future_changes_warning,
                      p_entries_changed_warning         => x_entries_changed_warning
                     );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_error_code := 1;
                     x_error_message :=
                        'Error while updating final process date.' || SQLERRM;
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_low,
                         p_category                 => 'FPD-API',
                         p_error_text               => 'E:' || x_error_message,
                         p_record_identifier_1      => x_final_prdat (i).person_id,
                         p_record_identifier_2      => x_final_prdat (i).actual_termination_date,
                         p_record_identifier_3      => x_final_prdat (i).object_version_number
                        );
               END;
               COMMIT;

               IF x_error_code = 0
               THEN
                  BEGIN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                              'last_standard_process_date:'
                                           || x_end_date
                                          );
                    --Updating Last Standard Process Date
                     UPDATE per_periods_of_service
                        SET last_standard_process_date = x_end_date
                      WHERE period_of_service_id =
                                           x_final_prdat (i).period_of_service_id
                        AND object_version_number = x_object_version_number;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        x_error_code := 1;
                        x_error_message :=
                              'Error while updating Last_Standard_Process_Date.'
                           || SQLERRM;
                        xx_emf_pkg.error
                           (p_severity                 => xx_emf_cn_pkg.cn_low,
                            p_category                 => 'LSPD-UPD',
                            p_error_text               => 'E:' || x_error_message,
                            p_record_identifier_1      => x_final_prdat (i).person_id,
                            p_record_identifier_2      => x_final_prdat (i).actual_termination_date,
                            p_record_identifier_3      => x_final_prdat (i).object_version_number
                           );
                  END;
               END IF;
            END IF;

            --Variable to check the count
            x_count := x_count + 1;

            IF x_error_code = 0
            THEN
               x_success_count := x_success_count + 1;
            ELSIF x_error_code = 1
            THEN
               x_error_count := x_error_count + 1;
            END IF;

            --Re-initializing error code and message
            x_error_code := 0;
            x_error_message := NULL;
         END LOOP;
      END IF;
      COMMIT;
      x_total_count := x_success_count + x_error_count;
      xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_count,
                                  p_success_recs_cnt      => x_success_count,
                                  p_warning_recs_cnt      => 0,
                                  p_error_recs_cnt        => x_error_count
                                 );
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_retcode := xx_emf_cn_pkg.cn_error;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                               'Error in xx_final_process_date : ' || SQLERRM
                              );
         xx_emf_pkg.create_report;
   END xx_final_process_date;
END xx_h2r_final_process_date;
/
