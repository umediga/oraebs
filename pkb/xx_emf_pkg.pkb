DROP PACKAGE BODY APPS.XX_EMF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_EMF_PKG" 
AS
----------------------------------------------------------------------
/*
       Created By : IBM Development
 Creation Date    : 07-MAR-2012
 File Name  : XX_EMF_PKG.pkb
 File Version     : 1
 Description      : This script creates the body of the package xx_emf_pkg
 Change History   :
 Date          Name              Remarks
 -----------   ----              ---------------------------------------
 07-MAR-2012   IBM Development   Initial development.
 02-AUG-2012   IBM Development   Modified the create_report to display
                                 in pipe delimited format for Integra
 03-AUG-2012   IBM Development   Modified CREATE_REPORT and added CREATE_REPORT_TEXT
                                 as a backup to the exisitng CREATE_REPORT procedure
                                 for Integra
 11-JUN-2013   IBM Development   Added generate_report to display distinct errors for 
                                 AR Open Invoice,Open SO and Supplier conversions
*/
----------------------------------------------------------------------
   set_globals_constant      CONSTANT VARCHAR2 (200)  := ' SET_GLOBALS';
   insert_dbg_constant       CONSTANT VARCHAR2 (2000)
                                                := ' INSERT_INTO_DEBUG_TRACE';
   insert_err_hdr_constant   CONSTANT VARCHAR2 (2000)
                                               := ' INSERT_INTO_ERROR_HEADER';
   insert_err_dtl_constant   CONSTANT VARCHAR2 (2000)
                                               := ' INSERT_INTO_ERROR_DETAIL';
   e_rollback_error                   EXCEPTION;

   PROCEDURE junk (a VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, a);
      DBMS_OUTPUT.put_line (a);
   END junk;

   FUNCTION set_globals (
      p_process_name           VARCHAR2,
      p_process_id             NUMBER,
      p_debug_level            VARCHAR2,
      p_debug_type             VARCHAR2,
      p_error_tab_ind          VARCHAR2,
      p_error_log_ind          VARCHAR2,
      p_pre_validation_flag    VARCHAR2,
      p_post_validation_flag   VARCHAR2,
      p_request_id             NUMBER DEFAULT NULL
   )
      RETURN NUMBER
   IS
      x_global_on_off     VARCHAR2 (3);
      x_conc_request_id   fnd_concurrent_requests.request_id%TYPE;
      x_return_value      NUMBER                  := xx_emf_cn_pkg.cn_success;

      FUNCTION get_session_id
         RETURN NUMBER
      IS
         x_return_value   NUMBER;
      BEGIN
         SELECT xx_emf_debug_trace_s.NEXTVAL
           INTO x_return_value
           FROM DUAL;

         RETURN x_return_value;
      EXCEPTION
         WHEN OTHERS
         THEN
            --
            RETURN NULL;
      END get_session_id;

      FUNCTION get_error_hdr_id
         RETURN NUMBER
      IS
         x_return_value   NUMBER;
      BEGIN
         SELECT xx_emf_error_header_s.NEXTVAL
           INTO x_return_value
           FROM DUAL;

         RETURN x_return_value;
      EXCEPTION
         WHEN OTHERS
         THEN
            --
            RETURN NULL;
      END get_error_hdr_id;
   BEGIN
      x_global_on_off := fnd_profile.VALUE (xx_emf_cn_pkg.cn_debug_prof);
      x_conc_request_id := NVL (p_request_id, fnd_global.conc_request_id);
      g_conc_request_id := x_conc_request_id;
      -- Set site level globals
      g_debug_on_off_ind := NVL (x_global_on_off, xx_emf_cn_pkg.cn_on);
      -- Set the global variables
      g_process_name := p_process_name;
      g_process_id := p_process_id;

      IF p_request_id IS NULL
      THEN
         -- SELECT from the sequence
         g_session_id := get_session_id;
         g_error_header_id := get_error_hdr_id;
      ELSE
         --SELECT the old session and Header Id for this Process/Request Id Combination
         SELECT session_id
           INTO g_session_id
           FROM xx_emf_debug_trace
          WHERE request_id = x_conc_request_id
            AND process_id = p_process_id
            AND ROWNUM < 2;

         /*SELECT MAX(debug_id)
           INTO g_debug_id
           FROM xx_emf_debug_trace
          WHERE request_id = x_conc_request_id
            AND process_id = p_process_id;*/
         SELECT header_id
           INTO g_error_header_id
           FROM xx_emf_error_headers
          WHERE request_id = x_conc_request_id AND process_id = p_process_id;
      END IF;

      g_request_id := x_conc_request_id;
      g_debug_level := p_debug_level;
      g_debug_type := p_debug_type;
      g_error_tab_ind := p_error_tab_ind;
      g_error_log_ind := p_error_log_ind;
      g_pre_valid_flag := p_pre_validation_flag;
      g_post_valid_flag := p_post_validation_flag;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'g_session_id= ' || g_session_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'g_request_id= ' || g_request_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'g_debug_level= ' || g_debug_level
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'g_debug_type= ' || g_debug_type
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'g_process_name= ' || g_process_name
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'g_process_id= ' || g_process_id
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'g_conc_request_id= ' || g_conc_request_id
                           );
      RETURN x_return_value;
   EXCEPTION
      -- Log the error message and continue with the process
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            xx_emf_cn_pkg.cn_exp_unhand
                            || set_globals_constant
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         x_return_value := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_return_value;
   END set_globals;

   PROCEDURE insert_into_debug_trace (
      p_debug_level   IN   NUMBER,
      p_debug_text    IN   VARCHAR2,
      p_attribute1    IN   VARCHAR2 DEFAULT NULL,
      p_attribute2    IN   VARCHAR2 DEFAULT NULL,
      p_attribute3    IN   VARCHAR2 DEFAULT NULL,
      p_attribute4    IN   VARCHAR2 DEFAULT NULL,
      p_attribute5    IN   VARCHAR2 DEFAULT NULL,
      p_attribute6    IN   VARCHAR2 DEFAULT NULL,
      p_attribute7    IN   VARCHAR2 DEFAULT NULL,
      p_attribute8    IN   VARCHAR2 DEFAULT NULL,
      p_attribute9    IN   VARCHAR2 DEFAULT NULL,
      p_attribute10   IN   VARCHAR2 DEFAULT NULL
   )
   IS
      -- Local variables
      x_created_by_user     VARCHAR2 (240) := fnd_global.user_name;
      x_created_by          NUMBER         := fnd_global.user_id;
      x_creation_date       DATE           := SYSDATE;
      x_last_updated_by     NUMBER         := fnd_global.user_id;
      x_last_update_date    DATE           := SYSDATE;
      x_last_update_login   NUMBER         := fnd_global.login_id;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_debug_id := NVL (g_debug_id, 0) + 1;

      INSERT INTO xx_emf_debug_trace_q
                  (session_id, debug_id, debug_level, debug_text,
                   request_id, process_name, process_id,
                   created_by_user, created_by, creation_date,
                   last_updated_by, last_update_date,
                   last_update_login, attribute1, attribute2,
                   attribute3, attribute4, attribute5, attribute6,
                   attribute7, attribute8, attribute9, attribute10
                  )
           VALUES (g_session_id, g_debug_id, p_debug_level, p_debug_text,
                   g_request_id, g_process_name, g_process_id,
                   x_created_by_user, x_created_by, x_creation_date,
                   x_last_updated_by, x_last_update_date,
                   x_last_update_login, p_attribute1, p_attribute2,
                   p_attribute3, p_attribute4, p_attribute5, p_attribute6,
                   p_attribute7, p_attribute8, p_attribute9, p_attribute10
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         -- Log it in log file and continue
         fnd_file.put_line (fnd_file.LOG,
                               xx_emf_cn_pkg.cn_exp_unhand
                            || insert_dbg_constant
                            || SQLERRM
                           );
         fnd_file.put_line (fnd_file.LOG, 'Error = ' || SQLERRM);
   END insert_into_debug_trace;

   PROCEDURE insert_into_error_header
   IS
      -- Local variables
      x_created_by_user     VARCHAR2 (240) := fnd_global.user_name;
      x_created_by          NUMBER         := fnd_global.user_id;
      x_creation_date       DATE           := SYSDATE;
      x_last_updated_by     NUMBER         := fnd_global.user_id;
      x_last_update_date    DATE           := SYSDATE;
      x_last_update_login   NUMBER         := fnd_global.login_id;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO xx_emf_error_headers
                  (header_id, transaction_id, process_name,
                   process_id, request_id, creation_date,
                   created_by_user, created_by, last_update_date,
                   last_updated_by, last_update_login
                  )
           VALUES (g_error_header_id, g_transaction_id, g_process_name,
                   g_process_id, g_request_id, x_creation_date,
                   x_created_by_user, x_created_by, x_last_update_date,
                   x_last_updated_by, x_last_update_login
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         -- Log it in log file and continue
         fnd_file.put_line (fnd_file.LOG,
                               xx_emf_cn_pkg.cn_exp_unhand
                            || insert_err_hdr_constant
                           );
   END insert_into_error_header;

   PROCEDURE insert_into_error_detail (
      p_err_text               VARCHAR2,
      p_err_type               VARCHAR2,
      p_err_severity           VARCHAR2,
      p_record_identifier_1    VARCHAR2,
      p_record_identifier_2    VARCHAR2,
      p_record_identifier_3    VARCHAR2,
      p_record_identifier_4    VARCHAR2,
      p_record_identifier_5    VARCHAR2,
      p_record_identifier_6    VARCHAR2,
      p_record_identifier_7    VARCHAR2,
      p_record_identifier_8    VARCHAR2,
      p_record_identifier_9    VARCHAR2,
      p_record_identifier_10   VARCHAR2
   )
   IS
      -- Local variables
      x_created_by          NUMBER := fnd_global.user_id;
      x_creation_date       DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_date    DATE   := SYSDATE;
      x_last_update_login   NUMBER := fnd_global.login_id;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_err_id := NVL (g_err_id, 0) + 1;

      INSERT INTO xx_emf_error_details
                  (header_id, err_id, err_text, err_type,
                   err_severity, record_identifier_1,
                   record_identifier_2, record_identifier_3,
                   record_identifier_4, record_identifier_5,
                   creation_date, created_by, last_update_date,
                   last_updated_by, last_update_login,
                   record_identifier_6, record_identifier_7,
                   record_identifier_8, record_identifier_9,
                   record_identifier_10
                  )
           VALUES (g_error_header_id, g_err_id, p_err_text, p_err_type,
                   p_err_severity, p_record_identifier_1,
                   p_record_identifier_2, p_record_identifier_3,
                   p_record_identifier_4, p_record_identifier_5,
                   x_creation_date, x_created_by, x_last_update_date,
                   x_last_updated_by, x_last_update_login,
                   p_record_identifier_6, p_record_identifier_7,
                   p_record_identifier_8, p_record_identifier_9,
                   p_record_identifier_10
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         -- Log it in log file and continue
         fnd_file.put_line (fnd_file.LOG,
                               xx_emf_cn_pkg.cn_exp_unhand
                            || insert_err_dtl_constant
                           );
   END insert_into_error_detail;

   FUNCTION set_env
      RETURN NUMBER
   IS
      -- This cursor gets the concurrent program name that is currently running
      CURSOR c_find_program (cp_conc_prog_id NUMBER)
      IS
         SELECT cp.concurrent_program_name
           FROM fnd_concurrent_programs cp
          WHERE cp.concurrent_program_id = cp_conc_prog_id;

      x_conc_program_id     fnd_concurrent_programs.concurrent_program_id%TYPE;
      x_conc_program_name   fnd_concurrent_programs.concurrent_program_name%TYPE;
      x_return_value        NUMBER                := xx_emf_cn_pkg.cn_success;
   BEGIN
      IF g_session_id IS NOT NULL
      THEN
         RETURN x_return_value;
      END IF;

      x_conc_program_id := fnd_global.conc_program_id;

      -- Continue only if the env can be found automatically
      IF x_conc_program_id >= 0
      THEN
         OPEN c_find_program (x_conc_program_id);

         FETCH c_find_program
          INTO x_conc_program_name;

         CLOSE c_find_program;

         -- Continue only if the conc program name could be found
         IF x_conc_program_name IS NOT NULL
         THEN
            x_return_value := set_env (x_conc_program_name);
         END IF;
      ELSE
         x_return_value := xx_emf_cn_pkg.cn_rec_err;
      END IF;

      RETURN x_return_value;
   EXCEPTION
      -- Log the error message and continue with the process
      WHEN OTHERS
      THEN
         -- Commented by rahul on
         x_return_value := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_return_value;
   END set_env;

   FUNCTION set_env (p_process_name VARCHAR2)
      RETURN NUMBER
   IS
      CURSOR c_xx_emf_process_setup
      IS
         SELECT ps.process_id, ps.process_name, ps.description,
                ps.process_type, ps.object_type, ps.module_name,
                ps.notification_group, ps.run_frequency, ps.runtime,
                ps.enabled_flag, ps.debug_level, ps.debug_type,
                ps.purge_interval, ps.pre_validation_flag,
                ps.post_validation_flag, ps.error_tab_ind, ps.error_log_ind,
                ps.org_id, ps.attribute_category, ps.attribute1,
                ps.attribute2, ps.attribute3, ps.attribute4, ps.attribute5,
                ps.attribute6, ps.attribute7, ps.attribute8, ps.attribute9,
                ps.attribute10, ps.attribute11, ps.attribute12,
                ps.attribute13, ps.attribute14, ps.attribute15,
                ps.attribute16, ps.attribute17, ps.attribute18,
                ps.attribute19, ps.attribute20, ps.attribute21,
                ps.attribute22, ps.attribute23, ps.attribute24,
                ps.attribute25, ps.attribute26, ps.attribute27,
                ps.attribute28, ps.attribute29, ps.attribute30
           FROM xx_emf_process_setup ps
          WHERE ps.process_name = p_process_name;

      r_xx_emf_process_setup   c_xx_emf_process_setup%ROWTYPE;
      e_no_process_defined     EXCEPTION;
      x_return_value           NUMBER             := xx_emf_cn_pkg.cn_success;
      x_error_tab_ind          VARCHAR2 (10);
   BEGIN
      IF g_session_id IS NOT NULL
      THEN
         RETURN x_return_value;
      END IF;

      OPEN c_xx_emf_process_setup;

      FETCH c_xx_emf_process_setup
       INTO r_xx_emf_process_setup;

      CLOSE c_xx_emf_process_setup;

      IF r_xx_emf_process_setup.process_id IS NULL
      THEN
         RAISE e_no_process_defined;
      END IF;

      x_return_value :=
         set_globals (r_xx_emf_process_setup.process_name,
                      r_xx_emf_process_setup.process_id,
                      r_xx_emf_process_setup.debug_level,
                      r_xx_emf_process_setup.debug_type,
                      r_xx_emf_process_setup.error_tab_ind,
                      r_xx_emf_process_setup.error_log_ind,
                      r_xx_emf_process_setup.pre_validation_flag,
                      r_xx_emf_process_setup.post_validation_flag,
                      NULL
                     );

      -- Included the if statment
      IF g_error_tab_ind = xx_emf_cn_pkg.cn_yes
      THEN
         insert_into_error_header;
      END IF;

      RETURN x_return_value;
   EXCEPTION
      -- Log the error message and continue with the process
      WHEN OTHERS
      THEN
         x_return_value := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_return_value;
   END set_env;

   FUNCTION set_env (p_process_name VARCHAR2, p_request_id NUMBER)
      RETURN NUMBER
   IS
      CURSOR c_xx_emf_process_setup
      IS
         SELECT ps.process_id, ps.process_name, ps.description,
                ps.process_type, ps.object_type, ps.module_name,
                ps.notification_group, ps.run_frequency, ps.runtime,
                ps.enabled_flag, ps.debug_level, ps.debug_type,
                ps.purge_interval, ps.pre_validation_flag,
                ps.post_validation_flag, ps.error_tab_ind, ps.error_log_ind,
                ps.org_id, ps.attribute_category, ps.attribute1,
                ps.attribute2, ps.attribute3, ps.attribute4, ps.attribute5,
                ps.attribute6, ps.attribute7, ps.attribute8, ps.attribute9,
                ps.attribute10, ps.attribute11, ps.attribute12,
                ps.attribute13, ps.attribute14, ps.attribute15,
                ps.attribute16, ps.attribute17, ps.attribute18,
                ps.attribute19, ps.attribute20, ps.attribute21,
                ps.attribute22, ps.attribute23, ps.attribute24,
                ps.attribute25, ps.attribute26, ps.attribute27,
                ps.attribute28, ps.attribute29, ps.attribute30
           FROM xx_emf_process_setup ps
          WHERE ps.process_name = p_process_name;

      r_xx_emf_process_setup   c_xx_emf_process_setup%ROWTYPE;
      e_no_process_defined     EXCEPTION;
      x_return_value           NUMBER             := xx_emf_cn_pkg.cn_success;
      x_error_tab_ind          VARCHAR2 (10);
   BEGIN
      OPEN c_xx_emf_process_setup;

      FETCH c_xx_emf_process_setup
       INTO r_xx_emf_process_setup;

      CLOSE c_xx_emf_process_setup;

      IF r_xx_emf_process_setup.process_id IS NULL
      THEN
         RAISE e_no_process_defined;
      END IF;

      x_return_value :=
         set_globals (r_xx_emf_process_setup.process_name,
                      r_xx_emf_process_setup.process_id,
                      r_xx_emf_process_setup.debug_level,
                      r_xx_emf_process_setup.debug_type,
                      r_xx_emf_process_setup.error_tab_ind,
                      r_xx_emf_process_setup.error_log_ind,
                      r_xx_emf_process_setup.pre_validation_flag,
                      r_xx_emf_process_setup.post_validation_flag,
                      p_request_id
                     );

      -- Included the if statment
      IF g_error_tab_ind = xx_emf_cn_pkg.cn_yes AND p_request_id IS NULL
      THEN
         insert_into_error_header;
      END IF;

      RETURN x_return_value;
   EXCEPTION
      -- Log the error message and continue with the process
      WHEN OTHERS
      THEN
         x_return_value := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_return_value;
   END set_env;

   PROCEDURE set_transaction_id (p_transaction_id VARCHAR2)
   IS
   BEGIN
      g_transaction_id := p_transaction_id;
   END set_transaction_id;

   PROCEDURE write_log (
      p_debug_level   IN   NUMBER,
      p_debug_text    IN   VARCHAR2,
      p_attribute1    IN   VARCHAR2 DEFAULT NULL,
      p_attribute2    IN   VARCHAR2 DEFAULT NULL,
      p_attribute3    IN   VARCHAR2 DEFAULT NULL,
      p_attribute4    IN   VARCHAR2 DEFAULT NULL,
      p_attribute5    IN   VARCHAR2 DEFAULT NULL,
      p_attribute6    IN   VARCHAR2 DEFAULT NULL,
      p_attribute7    IN   VARCHAR2 DEFAULT NULL,
      p_attribute8    IN   VARCHAR2 DEFAULT NULL,
      p_attribute9    IN   VARCHAR2 DEFAULT NULL,
      p_attribute10   IN   VARCHAR2 DEFAULT NULL
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF g_debug_on_off_ind = xx_emf_cn_pkg.cn_on
      THEN
         IF p_debug_level >= g_debug_level
         THEN
            IF    g_debug_type = xx_emf_cn_pkg.cn_table
               OR g_debug_type = xx_emf_cn_pkg.cn_tlog
               OR g_debug_type = xx_emf_cn_pkg.cn_tdbms
            THEN
               insert_into_debug_trace (p_debug_level      => p_debug_level,
                                        p_debug_text       => p_debug_text,
                                        p_attribute1       => p_attribute1,
                                        p_attribute2       => p_attribute2,
                                        p_attribute3       => p_attribute3,
                                        p_attribute4       => p_attribute4,
                                        p_attribute5       => p_attribute5,
                                        p_attribute6       => p_attribute6,
                                        p_attribute7       => p_attribute7,
                                        p_attribute8       => p_attribute8,
                                        p_attribute9       => p_attribute9,
                                        p_attribute10      => p_attribute10
                                       );
            END IF;

            IF    g_debug_type = xx_emf_cn_pkg.cn_dbms
               OR g_debug_type = xx_emf_cn_pkg.cn_tdbms
            THEN
               DBMS_OUTPUT.put_line (p_debug_text);
            END IF;

            IF    g_debug_type = xx_emf_cn_pkg.cn_log
               OR g_debug_type = xx_emf_cn_pkg.cn_tlog
            THEN
               fnd_file.put_line (fnd_file.LOG, p_debug_text);
            END IF;

            IF g_debug_type = xx_emf_cn_pkg.cn_all
            THEN
               insert_into_debug_trace (p_debug_level      => p_debug_level,
                                        p_debug_text       => p_debug_text,
                                        p_attribute1       => p_attribute1,
                                        p_attribute2       => p_attribute2,
                                        p_attribute3       => p_attribute3,
                                        p_attribute4       => p_attribute4,
                                        p_attribute5       => p_attribute5,
                                        p_attribute6       => p_attribute6,
                                        p_attribute7       => p_attribute7,
                                        p_attribute8       => p_attribute8,
                                        p_attribute9       => p_attribute9,
                                        p_attribute10      => p_attribute10
                                       );
               DBMS_OUTPUT.put_line (p_debug_text);
               fnd_file.put_line (fnd_file.LOG, p_debug_text);
            ELSE
               NULL;
            END IF;
         END IF;
      END IF;

      COMMIT;
   END write_log;

   PROCEDURE error (
      p_severity               IN   VARCHAR2,
      p_category               IN   VARCHAR2,
      p_error_text             IN   VARCHAR2,
      p_record_identifier_1    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_2    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_3    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_4    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_5    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_6    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_7    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_8    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_9    IN   VARCHAR2 DEFAULT NULL,
      p_record_identifier_10   IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      IF g_error_tab_ind = xx_emf_cn_pkg.cn_yes
      THEN
         insert_into_error_detail (p_error_text,
                                   p_category,
                                   p_severity,
                                   p_record_identifier_1,
                                   p_record_identifier_2,
                                   p_record_identifier_3,
                                   p_record_identifier_4,
                                   p_record_identifier_5,
                                   p_record_identifier_6,
                                   p_record_identifier_7,
                                   p_record_identifier_8,
                                   p_record_identifier_9,
                                   p_record_identifier_10
                                  );
      END IF;

      IF g_error_log_ind = xx_emf_cn_pkg.cn_log
      THEN
         fnd_file.put_line (fnd_file.LOG, p_error_text);
      ELSIF g_error_log_ind = xx_emf_cn_pkg.cn_out
      THEN
         -- fnd_file.put_line ( fnd_file.output, p_error_text);
         NULL;
      ELSE
         NULL;
      END IF;

      write_log (p_debug_level      => xx_emf_cn_pkg.cn_high,
                 p_debug_text       => p_error_text,
                 p_attribute1       => xx_emf_cn_pkg.cn_error,
                 p_attribute2       => p_category,
                 p_attribute3       => p_severity,
                 p_attribute4       => p_record_identifier_1,
                 p_attribute5       => p_record_identifier_2,
                 p_attribute6       => p_record_identifier_3,
                 p_attribute7       => p_record_identifier_4,
                 p_attribute8       => p_record_identifier_5
                );

      IF p_severity = xx_emf_cn_pkg.cn_high
      THEN
         raise_application_error (-20100, p_error_text);
      END IF;
   END error;

   -- Added by Rahul on 11-Sep-2007
   PROCEDURE create_report
   IS
      x_errbuf    VARCHAR2 (2000);
      x_retcode   VARCHAR2 (2000);
   BEGIN
      create_report (x_errbuf, x_retcode, g_request_id);
      x_retcode := xx_emf_cn_pkg.cn_success;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := xx_emf_cn_pkg.cn_rec_err;
   END;

   PROCEDURE create_report (
      errbuf         OUT      VARCHAR2,
      retcode        OUT      VARCHAR2,
      p_request_id   IN       NUMBER
   )
   IS
      -- To get the header records
      CURSOR c_error_headers
      IS
         SELECT total_recs_cnt, success_recs_cnt, error_recs_cnt, header_id,
                process_id, warning_recs_cnt
           FROM xx_emf_error_headers
          WHERE request_id = p_request_id;

      -- To get the batch_name records
      CURSOR c_batch_info (cp_request_id NUMBER)
      IS
         SELECT batch_id, request_id, total_cnt, error_cnt, warn_cnt,
                success_cnt
           FROM xx_emf_batch_id_rec_cnt
          WHERE request_id = cp_request_id;

      -- To Get the Identifier's parameters'value
      CURSOR c_paramters_value (cp_process_id IN NUMBER)
      IS
         SELECT   parameter_value, parameter_name
             FROM xx_emf_process_parameters
            WHERE process_id = cp_process_id
              AND UPPER (parameter_name) LIKE 'IDENTI%'
         ORDER BY parameter_name;

      -- To fetch detail records
      CURSOR c_error_details (cp_header_id IN NUMBER)
      IS
         SELECT   err_id record_id, SUBSTR (err_text, 1, 200) error_message,
                  SUBSTR (err_type, 1, 11) ERROR_CODE,
                  SUBSTR (record_identifier_1, 1, 23) identifier1,
                  SUBSTR (record_identifier_2, 1, 23) identifier2,
                  SUBSTR (record_identifier_3, 1, 23) identifier3,
                  SUBSTR (record_identifier_4, 1, 23) identifier4,
                  SUBSTR (record_identifier_5, 1, 23) identifier5
             FROM xx_emf_error_details
            WHERE header_id = cp_header_id
         ORDER BY err_id;

      -- To fetch summary records
      CURSOR c_error_summary (cp_header_id IN NUMBER)
      IS
         SELECT   SUBSTR (err_type, 1, 11) ERROR_CODE,
                  SUBSTR (err_text, 1, 200) error_message,
                  COUNT (1) failure_count
             FROM xx_emf_error_details
            WHERE header_id = cp_header_id
         GROUP BY err_type, err_text;

      -- Local Variables
      x_conc_prog_name                  fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;
      x_msg                             VARCHAR2 (100);
      x_instance_name                   VARCHAR2 (100);
      x_length                          NUMBER;
      x_display_name                    NUMBER;
      x_display_buff                    NUMBER;
      x_identifier1                     VARCHAR2 (100);
      x_identifier2                     VARCHAR2 (100);
      x_identifier3                     VARCHAR2 (100);
      x_identifer_count                 NUMBER                            := 1;
      x_resp_id                         NUMBER           := fnd_global.resp_id;
      x_resp_appl_id                    NUMBER      := fnd_global.resp_appl_id;
      -- Commented by IBM on 02-AUG-2012
      /*x_conc_label_req_id   CONSTANT VARCHAR2 (30)
                                                  := 'Concurrent Request ID :';*/
      -- Added by IBM on 02-AUG-2012
      x_label_sysdate          CONSTANT VARCHAR2 (30)                := 'Date';
      -- Added by IBM on 02-AUG-2012
      x_conc_label_req_id      CONSTANT VARCHAR2 (30)
                                                    := 'Concurrent Request ID';
      -- Added by IBM on 02-AUG-2012
      x_conc_label_prog_name   CONSTANT VARCHAR2 (30)
                                                  := 'Concurrent Program Name';
      x_report_width           CONSTANT NUMBER                          := 263;
      x_dis_buffer                      VARCHAR2 (3000);
      x_dis1                            INTEGER;
      x_dis2                            INTEGER;
      x_display_sysdate                 VARCHAR2 (30);
      x_param_count                     NUMBER                            := 0;
      x_i                               INTEGER;

      TYPE param_type IS RECORD (
         parameter_name    xx_emf_process_parameters.parameter_name%TYPE,
         parameter_value   xx_emf_process_parameters.parameter_value%TYPE,
         parameter_width   NUMBER
      );

      TYPE param_type_tab IS TABLE OF param_type
         INDEX BY BINARY_INTEGER;

      x_param_tab                       param_type_tab;
   BEGIN
      SELECT TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
        INTO x_display_sysdate
        FROM DUAL;

      fnd_file.put_line (fnd_file.LOG, 'Request id : ' || p_request_id);

      -- getting the user concurrent program name
      BEGIN
         SELECT fcp.user_concurrent_program_name
           INTO x_conc_prog_name
           FROM fnd_concurrent_programs_vl fcp, fnd_concurrent_requests fcr
          WHERE fcr.request_id = p_request_id
            AND fcp.application_id = fcr.program_application_id
            AND fcp.concurrent_program_id = fcr.concurrent_program_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Request id not passed properly'
                               || SQLCODE
                               || SQLERRM
                              );
      END;

      fnd_global.apps_initialize (user_id           => fnd_profile.VALUE
                                                                    ('USER_ID'),
                                  resp_id           => x_resp_id,
                                  resp_appl_id      => x_resp_appl_id
                                 );
      x_instance_name := fnd_profile.VALUE ('XX_EMF_REPORT_HEADING');
      fnd_file.put_line (fnd_file.LOG,
                         'The profile value is ' || x_instance_name
                        );
      -- To display 1st line(Line)
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output, RPAD ('-', x_report_width, '-'));*/
      -- To display 2nd line (Instance name)
      x_length := LENGTH (x_instance_name);
      x_display_name := (263 - (x_length)) / 2;
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output,
                         LPAD (' ', x_display_name) || x_instance_name
                        );*/
      -- To display 3rd line(Concurrent request id,Concurrent program user name and date)
      x_dis1 :=
           (x_report_width / 2)
         - (LENGTH (x_conc_label_req_id) + LENGTH (g_conc_request_id))
         - (LENGTH (x_conc_prog_name) / 2);
      x_dis2 :=
           (x_report_width / 2)
         - (LENGTH (x_conc_prog_name) / 2)
         - (LENGTH (x_display_sysdate));
      x_dis_buffer := NULL;
      -- Commented by IBM on 02-AUG-2012
      /*x_dis_buffer :=
            x_conc_label_req_id
         || g_conc_request_id
         || LPAD (' ', x_dis1)
         || x_conc_prog_name
         || LPAD (' ', x_dis2)
         || x_display_sysdate;*/
      -- Added by IBM on 02-AUG-2012
      x_dis_buffer :=
            x_label_sysdate
         || CHR (9)
         || x_display_sysdate
         || CHR (10)
         || x_conc_label_req_id
         || CHR (9)
         || g_conc_request_id
         || CHR (10)
         || x_conc_label_prog_name
         || CHR (9)
         || x_conc_prog_name;
      fnd_file.put_line (fnd_file.output, x_dis_buffer);
      -- To display 4th line(Line)
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output, RPAD ('-', x_report_width, '-'));*/
      -- To display 5th Line(Executable file name appended with Summary);
      x_length := LENGTH (x_conc_prog_name);
      x_display_buff := (x_length) / 2;
      x_display_name := ((x_report_width - (x_length)) / 2) - x_display_buff;
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output,
                            RPAD (' ', x_display_name + 9)
                         || x_conc_prog_name
                         || ' -  '
                         || 'Summary'
                        );*/
      x_dis_buffer := NULL;

      -- Commented by IBM on 02-AUG-2012
      /*x_dis_buffer :=
            RPAD ('Batch Name', 80, '  ')
         || RPAD ('Processed records', 45, '  ')
         || RPAD ('Success records', 45, '   ')
         || RPAD ('Warning records', 45, '  ')
         || RPAD ('Failed records', 45, '  ');
      fnd_file.put_line (fnd_file.output, x_dis_buffer);*/
      FOR rec_error_hdr IN c_error_headers
      LOOP
         x_dis_buffer := NULL;
         -- Commented by IBM on 02-AUG-2012
         /*x_dis_buffer :=
               RPAD (x_conc_prog_name, 80, '  ')
            || RPAD (rec_error_hdr.total_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.success_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.warning_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.error_recs_cnt, 45, '  ');*/

         -- Added by IBM on 02-AUG-2012
         x_dis_buffer :=
               'Processed records'
            || CHR (9)
            || rec_error_hdr.total_recs_cnt
            || CHR (10)
            || 'Success records'
            || CHR (9)
            || rec_error_hdr.success_recs_cnt
            || CHR (10)
            || 'Warning records'
            || CHR (9)
            || rec_error_hdr.warning_recs_cnt
            || CHR (10)
            || 'Failed records'
            || CHR (9)
            || rec_error_hdr.error_recs_cnt
            || CHR (10)
            || CHR (10);
         fnd_file.put_line (fnd_file.output, x_dis_buffer);

         FOR rec_bat_info IN c_batch_info (p_request_id)
         LOOP
            x_dis_buffer := NULL;
            -- Commented by IBM on 02-AUG-2012
            /*x_dis_buffer :=
                  RPAD (rec_bat_info.batch_id, 80, '  ')
               || RPAD (rec_bat_info.total_cnt, 45, '  ')
               || RPAD (rec_bat_info.success_cnt, 45, '  ')
               || RPAD (rec_bat_info.warn_cnt, 45, '  ')
               || RPAD (rec_bat_info.error_cnt, 45, '  ');*/
            -- Added by IBM on 02-AUG-2012
            x_dis_buffer :=
                  'Batch Name'
               || CHR (9)
               || rec_bat_info.batch_id
               || CHR (10)
               || 'Processed records'
               || CHR (9)
               || rec_bat_info.total_cnt
               || CHR (10)
               || 'Success records'
               || CHR (9)
               || rec_bat_info.success_cnt
               || CHR (10)
               || 'Warning records'
               || CHR (9)
               || rec_bat_info.warn_cnt
               || CHR (10)
               || 'Failed records'
               || CHR (9)
               || rec_bat_info.error_cnt
               || CHR (10)
               || CHR (10);
            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;

         -- To display 6th line('Line')
         -- Commented by IBM on 02-AUG-2012
         /*fnd_file.put_line (fnd_file.output, RPAD ('-', 263, '-'));*/
         -- To display 7th line(Executable file name appended with Errors);
         x_length := LENGTH (x_conc_prog_name);
         x_display_buff := (x_length) / 2;
         x_display_name :=
                          ((x_report_width - (x_length)) / 2) - x_display_buff;
         -- Commented by IBM on 02-AUG-2012
         /*fnd_file.put_line (fnd_file.output,
                               RPAD (' ', x_display_name + 9)
                            || x_conc_prog_name
                            || ' -  '
                            || 'Errors'
                           ); -- To display Error Details 1st line
         fnd_file.put_line (fnd_file.output, CHR (10));*/
         -- Added by IBM on 02-AUG-2012
         fnd_file.put_line (fnd_file.output,
                            CHR (9) || CHR (9) || 'SUMMARY SECTION'
                           );
         x_dis_buffer := NULL;
         x_dis_buffer :=
               CHR (9)
            || CHR (9)
            || 'Distinct Error Code'
            || CHR (9)
            || 'Distinct Error Message'
            || CHR (9)
            || 'Failure Count';
         fnd_file.put_line (fnd_file.output, x_dis_buffer);

         -- Added by IBM on 02-AUG-2012
         FOR rec_error_sumry IN c_error_summary (rec_error_hdr.header_id)
         LOOP
            x_dis_buffer := NULL;
            x_dis_buffer :=
                  CHR (9)
               || CHR (9)
               || rec_error_sumry.ERROR_CODE
               || CHR (9)
               || rec_error_sumry.error_message
               || CHR (9)
               || rec_error_sumry.failure_count;
            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;

         -- Added by IBM on 02-AUG-2012
         fnd_file.put_line (fnd_file.output, CHR (10));
         fnd_file.put_line (fnd_file.output,
                            CHR (9) || CHR (9) || 'DETAIL SECTION'
                           );
         -- To get the parameter's value
         x_param_count := 0;

         FOR rec_parameters_value IN
            c_paramters_value (rec_error_hdr.process_id)
         LOOP
            x_param_tab (x_param_count + 1).parameter_name :=
                                          rec_parameters_value.parameter_name;
            x_param_tab (x_param_count + 1).parameter_value :=
                                         rec_parameters_value.parameter_value;

            IF (x_param_count + 1) <= 3
            THEN
               x_param_tab (x_param_count + 1).parameter_width := 15;
            ELSE
               x_param_tab (x_param_count + 1).parameter_width := 15;
            END IF;

            x_param_count := x_param_count + 1;
         END LOOP;

         --- Parameters are required to display identifier's in output report
         IF x_param_count = 0
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Setup is missing for record identifier'
                               || ''''
                               || 's'
                              );
         END IF;

         -- End of parameter's value
         -- To display 8th line(Error details)
         x_dis_buffer := NULL;
         -- Commented by IBM on 02-AUG-2012
         /*x_dis_buffer :=
                 x_dis_buffer
               || RPAD ('Error Code'
                      , 13
                      , ' '
                       )
               || RPAD ('Error Message'
                      , 200
                      , ' '
                       );*/
         -- Added by IBM on 02-AUG-2012
         x_dis_buffer :=
               x_dis_buffer
            || CHR (9)
            || CHR (9)
            || 'Error Code'
            || CHR (9)
            || 'Error Message';

         IF x_param_count > 0
         THEN
            FOR x_i IN 1 .. x_param_count
            LOOP
               -- Commented by IBM on 02-AUG-2012
               /*x_dis_buffer :=
                     x_dis_buffer
                     || RPAD (NVL (x_param_tab (x_i).parameter_value, ' ')
                            , x_param_tab (x_i).parameter_width
                            , ' '
                             );*/
               -- Added by IBM on 02-AUG-2012
               x_dis_buffer :=
                  x_dis_buffer || CHR (9)
                  || x_param_tab (x_i).parameter_value;
            END LOOP;
         END IF;

         fnd_file.put_line (fnd_file.output, x_dis_buffer);

         -- Commented by IBM on 02-AUG-2012
         /* fnd_file.put_line (fnd_file.output
                           , RPAD ('-'
                                 , x_report_width
                                 , '-'
                                  )
                            );*/

         -- Error details record loop started
         FOR rec_error_dtl IN c_error_details (rec_error_hdr.header_id)
         LOOP
            x_dis_buffer := NULL;
            -- Commented by IBM on 02-AUG-2012
            /* x_dis_buffer :=
                      RPAD (rec_error_dtl.ERROR_CODE
                          , 13
                          , ' '
                           )
                   || RPAD (rec_error_dtl.error_message
                          , 200
                          , ' '
                           )
                   || ' ';*/
            -- Added by IBM on 02-AUG-2012
            x_dis_buffer :=
                  CHR (9)
               || CHR (9)
               || rec_error_dtl.ERROR_CODE
               || CHR (9)
               || rec_error_dtl.error_message;

            IF x_param_count > 0
            THEN
               FOR x_i IN 1 .. x_param_count
               LOOP
                  CASE x_i
                     WHEN 1
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /* x_dis_buffer :=
                               x_dis_buffer
                               || RPAD (rec_error_dtl.identifier1
                                      , x_param_tab (x_i).parameter_width
                                      , ' '
                                       );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier1;
                     WHEN 2
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier2
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier2;
                     WHEN 3
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier3
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier3;
                     WHEN 4
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier4
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier4;
                     WHEN 5
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier5
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier5;
                  END CASE;
               END LOOP;
            END IF;

            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;
      END LOOP;
   -- To display 9th line
   -- Commented by IBM on 02-AUG-2012
   /*fnd_file.put_line (fnd_file.output
                    , RPAD ('-'
                          , 263
                          , '-'
                           )
                     );*/
   END create_report;
   --Added to display distinct errors of AR,Suppplier and SO Conversions
   PROCEDURE generate_report
   IS
      x_errbuf    VARCHAR2 (2000);
      x_retcode   VARCHAR2 (2000);
   BEGIN
      generate_report (x_errbuf, x_retcode, g_request_id);
      x_retcode := xx_emf_cn_pkg.cn_success;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := xx_emf_cn_pkg.cn_rec_err;
   END generate_report;

   PROCEDURE generate_report (
      errbuf         OUT      VARCHAR2,
      retcode        OUT      VARCHAR2,
      p_request_id   IN       NUMBER
   )
   IS
      -- To get the header records
      CURSOR c_error_headers
      IS
         SELECT total_recs_cnt, success_recs_cnt, error_recs_cnt, header_id,
                process_id, warning_recs_cnt
           FROM xx_emf_error_headers
          WHERE request_id = p_request_id;

      -- To get the batch_name records
      CURSOR c_batch_info (cp_request_id NUMBER)
      IS
         SELECT batch_id, request_id, total_cnt, error_cnt, warn_cnt,
                success_cnt
           FROM xx_emf_batch_id_rec_cnt
          WHERE request_id = cp_request_id;

      -- To Get the Identifier's parameters'value
      CURSOR c_paramters_value (cp_process_id IN NUMBER)
      IS
         SELECT   parameter_value, parameter_name
             FROM xx_emf_process_parameters
            WHERE process_id = cp_process_id
              AND UPPER (parameter_name) LIKE 'IDENTI%'
         ORDER BY parameter_name;

      -- To fetch detail records
      CURSOR c_error_details (cp_header_id IN NUMBER)
      IS
         SELECT   err_id record_id, SUBSTR (err_text, 1, 200) error_message,
                  SUBSTR (err_type, 1, 50) ERROR_CODE,
                  SUBSTR (record_identifier_1, 1, 23) identifier1,
                  SUBSTR (record_identifier_2, 1, 23) identifier2,
                  SUBSTR (record_identifier_3, 1, 23) identifier3,
                  SUBSTR (record_identifier_4, 1, 23) identifier4,
                  SUBSTR (record_identifier_5, 1, 23) identifier5
             FROM xx_emf_error_details
            WHERE header_id = cp_header_id
         ORDER BY err_id;

      -- To fetch summary records
      CURSOR c_error_summary (cp_header_id IN NUMBER)
      IS
         SELECT SUBSTR (err_type, 1, 50) ERROR_CODE,
            SUBSTR(err_text,DECODE(instr(err_text,'Invalid'),0,1,instr(err_text,'Invalid')),(DECODE(instr(err_text,'=>'),0,200,instr(err_text,'=>'))-DECODE(instr(err_text,'Invalid'),0,1,instr(err_text,'Invalid')))-1) error_message,
            COUNT (DISTINCT record_identifier_1) failure_count
       FROM xx_emf_error_details
      WHERE header_id = cp_header_id              
         GROUP BY SUBSTR (err_type, 1, 50), SUBSTR(err_text,DECODE(instr(err_text,'Invalid'),0,1,instr(err_text,'Invalid')),(DECODE(instr(err_text,'=>'),0,200,instr(err_text,'=>'))-DECODE(instr(err_text,'Invalid'),0,1,instr(err_text,'Invalid')))-1);

      -- Local Variables
      x_conc_prog_name                  fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;
      x_msg                             VARCHAR2 (100);
      x_instance_name                   VARCHAR2 (100);
      x_length                          NUMBER;
      x_display_name                    NUMBER;
      x_display_buff                    NUMBER;
      x_identifier1                     VARCHAR2 (100);
      x_identifier2                     VARCHAR2 (100);
      x_identifier3                     VARCHAR2 (100);
      x_identifer_count                 NUMBER                            := 1;
      x_resp_id                         NUMBER           := fnd_global.resp_id;
      x_resp_appl_id                    NUMBER      := fnd_global.resp_appl_id;
      -- Commented by IBM on 02-AUG-2012
      /*x_conc_label_req_id   CONSTANT VARCHAR2 (30)
                                                  := 'Concurrent Request ID :';*/
      -- Added by IBM on 02-AUG-2012
      x_label_sysdate          CONSTANT VARCHAR2 (30)                := 'Date';
      -- Added by IBM on 02-AUG-2012
      x_conc_label_req_id      CONSTANT VARCHAR2 (30)
                                                    := 'Concurrent Request ID';
      -- Added by IBM on 02-AUG-2012
      x_conc_label_prog_name   CONSTANT VARCHAR2 (30)
                                                  := 'Concurrent Program Name';
      x_report_width           CONSTANT NUMBER                          := 263;
      x_dis_buffer                      VARCHAR2 (3000);
      x_dis1                            INTEGER;
      x_dis2                            INTEGER;
      x_display_sysdate                 VARCHAR2 (30);
      x_param_count                     NUMBER                            := 0;
      x_i                               INTEGER;

      TYPE param_type IS RECORD (
         parameter_name    xx_emf_process_parameters.parameter_name%TYPE,
         parameter_value   xx_emf_process_parameters.parameter_value%TYPE,
         parameter_width   NUMBER
      );

      TYPE param_type_tab IS TABLE OF param_type
         INDEX BY BINARY_INTEGER;

      x_param_tab                       param_type_tab;
   BEGIN
      SELECT TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
        INTO x_display_sysdate
        FROM DUAL;

      fnd_file.put_line (fnd_file.LOG, 'Request id : ' || p_request_id);

      -- getting the user concurrent program name
      BEGIN
         SELECT fcp.user_concurrent_program_name
           INTO x_conc_prog_name
           FROM fnd_concurrent_programs_vl fcp, fnd_concurrent_requests fcr
          WHERE fcr.request_id = p_request_id
            AND fcp.application_id = fcr.program_application_id
            AND fcp.concurrent_program_id = fcr.concurrent_program_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Request id not passed properly'
                               || SQLCODE
                               || SQLERRM
                              );
      END;

      fnd_global.apps_initialize (user_id           => fnd_profile.VALUE
                                                                    ('USER_ID'),
                                  resp_id           => x_resp_id,
                                  resp_appl_id      => x_resp_appl_id
                                 );
      x_instance_name := fnd_profile.VALUE ('XX_EMF_REPORT_HEADING');
      fnd_file.put_line (fnd_file.LOG,
                         'The profile value is ' || x_instance_name
                        );
      -- To display 1st line(Line)
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output, RPAD ('-', x_report_width, '-'));*/
      -- To display 2nd line (Instance name)
      x_length := LENGTH (x_instance_name);
      x_display_name := (263 - (x_length)) / 2;
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output,
                         LPAD (' ', x_display_name) || x_instance_name
                        );*/
      -- To display 3rd line(Concurrent request id,Concurrent program user name and date)
      x_dis1 :=
           (x_report_width / 2)
         - (LENGTH (x_conc_label_req_id) + LENGTH (g_conc_request_id))
         - (LENGTH (x_conc_prog_name) / 2);
      x_dis2 :=
           (x_report_width / 2)
         - (LENGTH (x_conc_prog_name) / 2)
         - (LENGTH (x_display_sysdate));
      x_dis_buffer := NULL;
      -- Commented by IBM on 02-AUG-2012
      /*x_dis_buffer :=
            x_conc_label_req_id
         || g_conc_request_id
         || LPAD (' ', x_dis1)
         || x_conc_prog_name
         || LPAD (' ', x_dis2)
         || x_display_sysdate;*/
      -- Added by IBM on 02-AUG-2012
      x_dis_buffer :=
            x_label_sysdate
         || CHR (9)
         || x_display_sysdate
         || CHR (10)
         || x_conc_label_req_id
         || CHR (9)
         || g_conc_request_id
         || CHR (10)
         || x_conc_label_prog_name
         || CHR (9)
         || x_conc_prog_name;
      fnd_file.put_line (fnd_file.output, x_dis_buffer);
      -- To display 4th line(Line)
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output, RPAD ('-', x_report_width, '-'));*/
      -- To display 5th Line(Executable file name appended with Summary);
      x_length := LENGTH (x_conc_prog_name);
      x_display_buff := (x_length) / 2;
      x_display_name := ((x_report_width - (x_length)) / 2) - x_display_buff;
      -- Commented by IBM on 02-AUG-2012
      /*fnd_file.put_line (fnd_file.output,
                            RPAD (' ', x_display_name + 9)
                         || x_conc_prog_name
                         || ' -  '
                         || 'Summary'
                        );*/
      x_dis_buffer := NULL;

      -- Commented by IBM on 02-AUG-2012
      /*x_dis_buffer :=
            RPAD ('Batch Name', 80, '  ')
         || RPAD ('Processed records', 45, '  ')
         || RPAD ('Success records', 45, '   ')
         || RPAD ('Warning records', 45, '  ')
         || RPAD ('Failed records', 45, '  ');
      fnd_file.put_line (fnd_file.output, x_dis_buffer);*/
      FOR rec_error_hdr IN c_error_headers
      LOOP
         x_dis_buffer := NULL;
         -- Commented by IBM on 02-AUG-2012
         /*x_dis_buffer :=
               RPAD (x_conc_prog_name, 80, '  ')
            || RPAD (rec_error_hdr.total_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.success_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.warning_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.error_recs_cnt, 45, '  ');*/

         -- Added by IBM on 02-AUG-2012
         x_dis_buffer :=
               'Processed records'
            || CHR (9)
            || rec_error_hdr.total_recs_cnt
            || CHR (10)
            || 'Success records'
            || CHR (9)
            || rec_error_hdr.success_recs_cnt
            || CHR (10)
            || 'Warning records'
            || CHR (9)
            || rec_error_hdr.warning_recs_cnt
            || CHR (10)
            || 'Failed records'
            || CHR (9)
            || rec_error_hdr.error_recs_cnt
            || CHR (10)
            || CHR (10);
         fnd_file.put_line (fnd_file.output, x_dis_buffer);

         FOR rec_bat_info IN c_batch_info (p_request_id)
         LOOP
            x_dis_buffer := NULL;
            -- Commented by IBM on 02-AUG-2012
            /*x_dis_buffer :=
                  RPAD (rec_bat_info.batch_id, 80, '  ')
               || RPAD (rec_bat_info.total_cnt, 45, '  ')
               || RPAD (rec_bat_info.success_cnt, 45, '  ')
               || RPAD (rec_bat_info.warn_cnt, 45, '  ')
               || RPAD (rec_bat_info.error_cnt, 45, '  ');*/
            -- Added by IBM on 02-AUG-2012
            x_dis_buffer :=
                  'Batch Name'
               || CHR (9)
               || rec_bat_info.batch_id
               || CHR (10)
               || 'Processed records'
               || CHR (9)
               || rec_bat_info.total_cnt
               || CHR (10)
               || 'Success records'
               || CHR (9)
               || rec_bat_info.success_cnt
               || CHR (10)
               || 'Warning records'
               || CHR (9)
               || rec_bat_info.warn_cnt
               || CHR (10)
               || 'Failed records'
               || CHR (9)
               || rec_bat_info.error_cnt
               || CHR (10)
               || CHR (10);
            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;

         -- To display 6th line('Line')
         -- Commented by IBM on 02-AUG-2012
         /*fnd_file.put_line (fnd_file.output, RPAD ('-', 263, '-'));*/
         -- To display 7th line(Executable file name appended with Errors);
         x_length := LENGTH (x_conc_prog_name);
         x_display_buff := (x_length) / 2;
         x_display_name :=
                          ((x_report_width - (x_length)) / 2) - x_display_buff;
         -- Commented by IBM on 02-AUG-2012
         /*fnd_file.put_line (fnd_file.output,
                               RPAD (' ', x_display_name + 9)
                            || x_conc_prog_name
                            || ' -  '
                            || 'Errors'
                           ); -- To display Error Details 1st line
         fnd_file.put_line (fnd_file.output, CHR (10));*/
         -- Added by IBM on 02-AUG-2012
         fnd_file.put_line (fnd_file.output,
                            CHR (9) || CHR (9) || 'SUMMARY SECTION'
                           );
         x_dis_buffer := NULL;
         x_dis_buffer :=
               CHR (9)
            || CHR (9)
            || 'Distinct Error Code'
            || CHR (9)
            || 'Distinct Error Message'
            || CHR (9)
            || 'Failure Count';
         fnd_file.put_line (fnd_file.output, x_dis_buffer);

         -- Added by IBM on 02-AUG-2012
         FOR rec_error_sumry IN c_error_summary (rec_error_hdr.header_id)
         LOOP
            x_dis_buffer := NULL;
            x_dis_buffer :=
                  CHR (9)
               || CHR (9)
               || rec_error_sumry.ERROR_CODE
               || CHR (9)
               || rec_error_sumry.error_message
               || CHR (9)
               || rec_error_sumry.failure_count;
            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;

         -- Added by IBM on 02-AUG-2012
         fnd_file.put_line (fnd_file.output, CHR (10));
         fnd_file.put_line (fnd_file.output,
                            CHR (9) || CHR (9) || 'DETAIL SECTION'
                           );
         -- To get the parameter's value
         x_param_count := 0;

         FOR rec_parameters_value IN
            c_paramters_value (rec_error_hdr.process_id)
         LOOP
            x_param_tab (x_param_count + 1).parameter_name :=
                                          rec_parameters_value.parameter_name;
            x_param_tab (x_param_count + 1).parameter_value :=
                                         rec_parameters_value.parameter_value;

            IF (x_param_count + 1) <= 3
            THEN
               x_param_tab (x_param_count + 1).parameter_width := 15;
            ELSE
               x_param_tab (x_param_count + 1).parameter_width := 15;
            END IF;

            x_param_count := x_param_count + 1;
         END LOOP;

         --- Parameters are required to display identifier's in output report
         IF x_param_count = 0
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Setup is missing for record identifier'
                               || ''''
                               || 's'
                              );
         END IF;

         -- End of parameter's value
         -- To display 8th line(Error details)
         x_dis_buffer := NULL;
         -- Commented by IBM on 02-AUG-2012
         /*x_dis_buffer :=
                 x_dis_buffer
               || RPAD ('Error Code'
                      , 13
                      , ' '
                       )
               || RPAD ('Error Message'
                      , 200
                      , ' '
                       );*/
         -- Added by IBM on 02-AUG-2012
         x_dis_buffer :=
               x_dis_buffer
            || CHR (9)
            || CHR (9)
            || 'Error Code'
            || CHR (9)
            || 'Error Message';

         IF x_param_count > 0
         THEN
            FOR x_i IN 1 .. x_param_count
            LOOP
               -- Commented by IBM on 02-AUG-2012
               /*x_dis_buffer :=
                     x_dis_buffer
                     || RPAD (NVL (x_param_tab (x_i).parameter_value, ' ')
                            , x_param_tab (x_i).parameter_width
                            , ' '
                             );*/
               -- Added by IBM on 02-AUG-2012
               x_dis_buffer :=
                  x_dis_buffer || CHR (9)
                  || x_param_tab (x_i).parameter_value;
            END LOOP;
         END IF;

         fnd_file.put_line (fnd_file.output, x_dis_buffer);

         -- Commented by IBM on 02-AUG-2012
         /* fnd_file.put_line (fnd_file.output
                           , RPAD ('-'
                                 , x_report_width
                                 , '-'
                                  )
                            );*/

         -- Error details record loop started
         FOR rec_error_dtl IN c_error_details (rec_error_hdr.header_id)
         LOOP
            x_dis_buffer := NULL;
            -- Commented by IBM on 02-AUG-2012
            /* x_dis_buffer :=
                      RPAD (rec_error_dtl.ERROR_CODE
                          , 13
                          , ' '
                           )
                   || RPAD (rec_error_dtl.error_message
                          , 200
                          , ' '
                           )
                   || ' ';*/
            -- Added by IBM on 02-AUG-2012
            x_dis_buffer :=
                  CHR (9)
               || CHR (9)
               || rec_error_dtl.ERROR_CODE
               || CHR (9)
               || rec_error_dtl.error_message;

            IF x_param_count > 0
            THEN
               FOR x_i IN 1 .. x_param_count
               LOOP
                  CASE x_i
                     WHEN 1
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /* x_dis_buffer :=
                               x_dis_buffer
                               || RPAD (rec_error_dtl.identifier1
                                      , x_param_tab (x_i).parameter_width
                                      , ' '
                                       );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier1;
                     WHEN 2
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier2
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier2;
                     WHEN 3
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier3
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier3;
                     WHEN 4
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier4
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier4;
                     WHEN 5
                     THEN
                        -- Commented by IBM on 02-AUG-2012
                        /*x_dis_buffer :=
                              x_dis_buffer
                              || RPAD (rec_error_dtl.identifier5
                                     , x_param_tab (x_i).parameter_width
                                     , ' '
                                      );*/
                        -- Added by IBM on 02-AUG-2012
                        x_dis_buffer :=
                           x_dis_buffer || CHR (9)
                           || rec_error_dtl.identifier5;
                  END CASE;
               END LOOP;
            END IF;

            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;
      END LOOP;
   -- To display 9th line
   -- Commented by IBM on 02-AUG-2012
   /*fnd_file.put_line (fnd_file.output
                    , RPAD ('-'
                          , 263
                          , '-'
                           )
                     );*/
   END generate_report;   

   -- Added by IBM on 03-AUG-2012 as backup to the existing CREATE_REPORT for Integra
   PROCEDURE create_report_text
   IS
      x_errbuf    VARCHAR2 (2000);
      x_retcode   VARCHAR2 (2000);
   BEGIN
      create_report_text (x_errbuf, x_retcode, g_request_id);
      x_retcode := xx_emf_cn_pkg.cn_success;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := xx_emf_cn_pkg.cn_rec_err;
   END;

   -- Added by IBM on 03-AUG-2012 as backup to the existing CREATE_REPORT for Integra
   PROCEDURE create_report_text (
      errbuf         OUT      VARCHAR2,
      retcode        OUT      VARCHAR2,
      p_request_id   IN       NUMBER
   )
   IS
      -- To get the header records
      CURSOR c_error_headers
      IS
         SELECT total_recs_cnt, success_recs_cnt, error_recs_cnt, header_id,
                process_id, warning_recs_cnt
           FROM xx_emf_error_headers
          WHERE request_id = p_request_id;

      -- To get the batch_name records
      CURSOR c_batch_info (cp_request_id NUMBER)
      IS
         SELECT batch_id, request_id, total_cnt, error_cnt, warn_cnt,
                success_cnt
           FROM xx_emf_batch_id_rec_cnt
          WHERE request_id = cp_request_id;

      -- To Get the Identifier's parameters'value
      CURSOR c_paramters_value (cp_process_id IN NUMBER)
      IS
         SELECT   parameter_value, parameter_name
             FROM xx_emf_process_parameters
            WHERE process_id = cp_process_id
              AND UPPER (parameter_name) LIKE 'IDENTI%'
         ORDER BY parameter_name;

      -- To fetch detail records
      CURSOR c_error_details (cp_header_id IN NUMBER)
      IS
         SELECT   err_id record_id, SUBSTR (err_text, 1, 200) error_message,
                  SUBSTR (err_type, 1, 11) ERROR_CODE,
                  SUBSTR (record_identifier_1, 1, 23) identifier1,
                  SUBSTR (record_identifier_2, 1, 23) identifier2,
                  SUBSTR (record_identifier_3, 1, 23) identifier3,
                  SUBSTR (record_identifier_4, 1, 23) identifier4,
                  SUBSTR (record_identifier_5, 1, 23) identifier5
             FROM xx_emf_error_details
            WHERE header_id = cp_header_id
         ORDER BY err_id;

      -- Local Variables
      x_conc_prog_name               fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;
      x_msg                          VARCHAR2 (100);
      x_instance_name                VARCHAR2 (100);
      x_length                       NUMBER;
      x_display_name                 NUMBER;
      x_display_buff                 NUMBER;
      x_identifier1                  VARCHAR2 (100);
      x_identifier2                  VARCHAR2 (100);
      x_identifier3                  VARCHAR2 (100);
      x_identifer_count              NUMBER                               := 1;
      x_resp_id                      NUMBER              := fnd_global.resp_id;
      x_resp_appl_id                 NUMBER         := fnd_global.resp_appl_id;
      x_conc_label_req_id   CONSTANT VARCHAR2 (30)
                                                  := 'Concurrent Request ID :';
      x_report_width        CONSTANT NUMBER                             := 263;
      x_dis_buffer                   VARCHAR2 (1000);
      x_dis1                         INTEGER;
      x_dis2                         INTEGER;
      x_display_sysdate              VARCHAR2 (30);
      x_param_count                  NUMBER                               := 0;
      x_i                            INTEGER;

      TYPE param_type IS RECORD (
         parameter_name    xx_emf_process_parameters.parameter_name%TYPE,
         parameter_value   xx_emf_process_parameters.parameter_value%TYPE,
         parameter_width   NUMBER
      );

      TYPE param_type_tab IS TABLE OF param_type
         INDEX BY BINARY_INTEGER;

      x_param_tab                    param_type_tab;
   BEGIN
      SELECT TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
        INTO x_display_sysdate
        FROM DUAL;

      fnd_file.put_line (fnd_file.LOG, 'Request id : ' || p_request_id);

      -- getting the user concurrent program name
      BEGIN
         SELECT fcp.user_concurrent_program_name
           INTO x_conc_prog_name
           FROM fnd_concurrent_programs_vl fcp, fnd_concurrent_requests fcr
          WHERE fcr.request_id = p_request_id
            AND fcp.application_id = fcr.program_application_id
            AND fcp.concurrent_program_id = fcr.concurrent_program_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Request id not passed properly'
                               || SQLCODE
                               || SQLERRM
                              );
      END;

      fnd_global.apps_initialize (user_id           => fnd_profile.VALUE
                                                                    ('USER_ID'),
                                  resp_id           => x_resp_id,
                                  resp_appl_id      => x_resp_appl_id
                                 );
      x_instance_name := fnd_profile.VALUE ('XX_EMF_REPORT_HEADING');
      fnd_file.put_line (fnd_file.LOG,
                         'The profile value is ' || x_instance_name
                        );
      -- To display 1st line(Line)
      fnd_file.put_line (fnd_file.output, RPAD ('-', x_report_width, '-'));
      -- To display 2nd line (Instance name)
      x_length := LENGTH (x_instance_name);
      x_display_name := (263 - (x_length)) / 2;
      fnd_file.put_line (fnd_file.output,
                         LPAD (' ', x_display_name) || x_instance_name
                        );
      -- To display 3rd line(Concurrent request id,Concurrent program user name and date)
      x_dis1 :=
           (x_report_width / 2)
         - (LENGTH (x_conc_label_req_id) + LENGTH (g_conc_request_id))
         - (LENGTH (x_conc_prog_name) / 2);
      x_dis2 :=
           (x_report_width / 2)
         - (LENGTH (x_conc_prog_name) / 2)
         - (LENGTH (x_display_sysdate));
      x_dis_buffer := NULL;
      x_dis_buffer :=
            x_conc_label_req_id
         || g_conc_request_id
         || LPAD (' ', x_dis1)
         || x_conc_prog_name
         || LPAD (' ', x_dis2)
         || x_display_sysdate;
      fnd_file.put_line (fnd_file.output, x_dis_buffer);
      -- To display 4th line(Line)
      fnd_file.put_line (fnd_file.output, RPAD ('-', x_report_width, '-'));
      -- To display 5th Line(Executable file name appended with Summary);
      x_length := LENGTH (x_conc_prog_name);
      x_display_buff := (x_length) / 2;
      x_display_name := ((x_report_width - (x_length)) / 2) - x_display_buff;
      fnd_file.put_line (fnd_file.output,
                            RPAD (' ', x_display_name + 9)
                         || x_conc_prog_name
                         || ' -  '
                         || 'Summary'
                        );
      x_dis_buffer := NULL;
      x_dis_buffer :=
            RPAD ('Batch Name', 80, '  ')
         || RPAD ('Processed records', 45, '  ')
         || RPAD ('Success records', 45, '   ')
         || RPAD ('Warning records', 45, '  ')
         || RPAD ('Failed records', 45, '  ');
      fnd_file.put_line (fnd_file.output, x_dis_buffer);

      FOR rec_error_hdr IN c_error_headers
      LOOP
         x_dis_buffer := NULL;
         x_dis_buffer :=
               RPAD (x_conc_prog_name, 80, '  ')
            || RPAD (rec_error_hdr.total_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.success_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.warning_recs_cnt, 45, '  ')
            || RPAD (rec_error_hdr.error_recs_cnt, 45, '  ');
         fnd_file.put_line (fnd_file.output, x_dis_buffer);

         FOR rec_bat_info IN c_batch_info (p_request_id)
         LOOP
            x_dis_buffer := NULL;
            x_dis_buffer :=
                  RPAD (rec_bat_info.batch_id, 80, '  ')
               || RPAD (rec_bat_info.total_cnt, 45, '  ')
               || RPAD (rec_bat_info.success_cnt, 45, '  ')
               || RPAD (rec_bat_info.warn_cnt, 45, '  ')
               || RPAD (rec_bat_info.error_cnt, 45, '  ');
            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;

         -- To display 6th line('Line')
         fnd_file.put_line (fnd_file.output, RPAD ('-', 263, '-'));
         -- To display 7th line(Executable file name appended with Errors);
         x_length := LENGTH (x_conc_prog_name);
         x_display_buff := (x_length) / 2;
         x_display_name :=
                          ((x_report_width - (x_length)) / 2) - x_display_buff;
         fnd_file.put_line (fnd_file.output,
                               RPAD (' ', x_display_name + 9)
                            || x_conc_prog_name
                            || ' -  '
                            || 'Errors'
                           );             -- To display Error Details 1st line
         -- To get the parameter's value
         x_param_count := 0;

         FOR rec_parameters_value IN
            c_paramters_value (rec_error_hdr.process_id)
         LOOP
            x_param_tab (x_param_count + 1).parameter_name :=
                                          rec_parameters_value.parameter_name;
            x_param_tab (x_param_count + 1).parameter_value :=
                                         rec_parameters_value.parameter_value;

            IF (x_param_count + 1) <= 3
            THEN
               x_param_tab (x_param_count + 1).parameter_width := 15;
            ELSE
               x_param_tab (x_param_count + 1).parameter_width := 15;
            END IF;

            x_param_count := x_param_count + 1;
         END LOOP;

         --- Parameters are required to display identifier's in output report
         IF x_param_count = 0
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Setup is missing for record identifier'
                               || ''''
                               || 's'
                              );
         END IF;

         -- End of parameter's value
         -- To display 8th line(Error details)
         x_dis_buffer := NULL;
         x_dis_buffer :=
               x_dis_buffer
            || RPAD ('Error Code', 13, ' ')
            || RPAD ('Error Message', 200, ' ');

         IF x_param_count > 0
         THEN
            FOR x_i IN 1 .. x_param_count
            LOOP
               x_dis_buffer :=
                     x_dis_buffer
                  || RPAD (NVL (x_param_tab (x_i).parameter_value, ' '),
                           x_param_tab (x_i).parameter_width,
                           ' '
                          );
            END LOOP;
         END IF;

         fnd_file.put_line (fnd_file.output, x_dis_buffer);
         fnd_file.put_line (fnd_file.output, RPAD ('-', x_report_width, '-'));

         -- Error details record loop started
         FOR rec_error_dtl IN c_error_details (rec_error_hdr.header_id)
         LOOP
            x_dis_buffer := NULL;
            x_dis_buffer :=
                  RPAD (rec_error_dtl.ERROR_CODE, 13, ' ')
               || RPAD (rec_error_dtl.error_message, 200, ' ')
               || ' ';

            IF x_param_count > 0
            THEN
               FOR x_i IN 1 .. x_param_count
               LOOP
                  CASE x_i
                     WHEN 1
                     THEN
                        x_dis_buffer :=
                              x_dis_buffer
                           || RPAD (rec_error_dtl.identifier1,
                                    x_param_tab (x_i).parameter_width,
                                    ' '
                                   );
                     WHEN 2
                     THEN
                        x_dis_buffer :=
                              x_dis_buffer
                           || RPAD (rec_error_dtl.identifier2,
                                    x_param_tab (x_i).parameter_width,
                                    ' '
                                   );
                     WHEN 3
                     THEN
                        x_dis_buffer :=
                              x_dis_buffer
                           || RPAD (rec_error_dtl.identifier3,
                                    x_param_tab (x_i).parameter_width,
                                    ' '
                                   );
                     WHEN 4
                     THEN
                        x_dis_buffer :=
                              x_dis_buffer
                           || RPAD (rec_error_dtl.identifier4,
                                    x_param_tab (x_i).parameter_width,
                                    ' '
                                   );
                     WHEN 5
                     THEN
                        x_dis_buffer :=
                              x_dis_buffer
                           || RPAD (rec_error_dtl.identifier5,
                                    x_param_tab (x_i).parameter_width,
                                    ' '
                                   );
                  END CASE;
               END LOOP;
            END IF;

            fnd_file.put_line (fnd_file.output, x_dis_buffer);
         END LOOP;
      END LOOP;

      -- To display 9th line
      fnd_file.put_line (fnd_file.output, RPAD ('-', 263, '-'));
   END create_report_text;

   -- This function is used to delete select data from the error headers tables
   FUNCTION local_delete_error_headers_f (x_no_of_days IN NUMBER)
      RETURN BOOLEAN
   IS
   BEGIN
      DELETE FROM xx_emf_error_headers
            WHERE creation_date <= SYSDATE - (x_no_of_days);

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Error Code:  ' || SQLCODE);
         fnd_file.put_line (fnd_file.LOG, 'Error Description:  ' || SQLERRM);
         RETURN (FALSE);
   END local_delete_error_headers_f;

   -- This function is used to delete select data from the error details tables
   FUNCTION local_delete_error_details_f (x_no_of_days IN NUMBER)
      RETURN BOOLEAN
   IS
   BEGIN
      DELETE FROM xx_emf_error_details
            WHERE creation_date <= SYSDATE - (x_no_of_days);

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Error Code:  ' || SQLCODE);
         fnd_file.put_line (fnd_file.LOG, 'Error Description:  ' || SQLERRM);
         RETURN (FALSE);
   END local_delete_error_details_f;

   -- This is the main function use to call the other two delete functions
   -- If detail records deleted sucessfully then only it will proceed with the deletion
   -- of header record
   FUNCTION local_delete_error_data_f (p_no_of_days IN NUMBER)
      RETURN BOOLEAN
   IS
   BEGIN
      IF (local_delete_error_details_f (p_no_of_days) <> TRUE)
      THEN
         RAISE e_rollback_error;
      END IF;

      IF (local_delete_error_headers_f (p_no_of_days) <> TRUE)
      THEN
         RAISE e_rollback_error;
      END IF;

      COMMIT;
      RETURN (TRUE);
   EXCEPTION
      WHEN e_rollback_error
      THEN
         ROLLBACK;
         RETURN (FALSE);
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Error Code:  ' || SQLCODE);
         fnd_file.put_line (fnd_file.LOG, 'Error Description:  ' || SQLERRM);
         RETURN (FALSE);
   END local_delete_error_data_f;

   -- This function is used for archiving error header and detail information
   FUNCTION local_error_archive_f (p_no_of_days IN NUMBER)
      RETURN BOOLEAN
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, 'Starting ERROR Archiving Process');

      -- Inserting the data into error header backup table
      INSERT INTO xx_emf_error_headers_bk
                  (header_id, transaction_id, process_name, process_id,
                   request_id, total_recs_cnt, success_recs_cnt,
                   error_recs_cnt, creation_date, created_by_user,
                   created_by, last_update_date, last_updated_by,
                   last_update_login)
         (SELECT header_id, transaction_id, process_name, process_id,
                 request_id, total_recs_cnt, success_recs_cnt,
                 error_recs_cnt, creation_date, created_by_user, created_by,
                 last_update_date, last_updated_by, last_update_login
            FROM xx_emf_error_headers
           WHERE creation_date <= (SYSDATE - p_no_of_days));

      -- Inserting the data into error details backup table
      INSERT INTO xx_emf_error_details_bk
                  (header_id, err_id, err_text, err_type, err_severity,
                   record_identifier_1, record_identifier_2,
                   record_identifier_3, record_identifier_4,
                   record_identifier_5, creation_date, created_by,
                   last_update_date, last_updated_by, last_update_login)
         (SELECT header_id, err_id, err_text, err_type, err_severity,
                 record_identifier_1, record_identifier_2,
                 record_identifier_3, record_identifier_4,
                 record_identifier_5, creation_date, created_by,
                 last_update_date, last_updated_by, last_update_login
            FROM xx_emf_error_details
           WHERE creation_date <= (SYSDATE - p_no_of_days));

      COMMIT;
      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Error Code:  ' || SQLCODE);
         fnd_file.put_line (fnd_file.LOG, 'Error Description:  ' || SQLERRM);
         RETURN (FALSE);
   END local_error_archive_f;

   -- Main procedure to insert the data into backup tables and delete the data from main error tables
   -- for the selected no_of_days parameter
   PROCEDURE arch_purge (p_no_of_days IN NUMBER)
   IS
   BEGIN
      -- Local procedure called to insert the data into backup tables
      IF (local_error_archive_f (p_no_of_days) <> TRUE)
      THEN                                 -- Store the data in backup tables
         RAISE e_rollback_error;
      END IF;

      -- Local procedure called to delete the data from base tabels
      IF (local_delete_error_data_f (p_no_of_days) <> TRUE)
      THEN                                 -- Delete the data from main tables
         RAISE e_rollback_error;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN e_rollback_error
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Error Code:  ' || SQLCODE);
         fnd_file.put_line (fnd_file.LOG, 'Error Description:  ' || SQLERRM);
   END arch_purge;

-- Added by rahul
---------------------------------------------------------------------------
-- Purge error backup and trace tables procedure starts
---------------------------------------------------------------------------
   PROCEDURE purge_errors
   IS
      --Cursor Declaration
      -- To select processes from the process setup table.
      CURSOR c_process_setup
      IS
         SELECT process_id, purge_interval
           FROM xx_emf_process_setup xbps;

      -- Local Variable Declaration
      x_purge_records   NUMBER;
      x_del_success     VARCHAR2 (1);
   BEGIN
      FOR rec_prcss IN c_process_setup
      LOOP
         x_del_success := 'N';

         -- Delete the data from back error header tables
         BEGIN
            DELETE FROM xx_emf_error_details_bk
                  WHERE EXISTS (
                           SELECT 'x'
                             FROM xx_emf_error_headers_bk
                            WHERE process_id = rec_prcss.process_id
                              AND creation_date <=
                                          SYSDATE
                                          - (rec_prcss.purge_interval));

            x_del_success := 'Y';
         EXCEPTION
            WHEN OTHERS
            THEN
               x_del_success := 'N';
         END;

         -- Delete the data from back error details tables
         IF x_del_success = 'Y'
         THEN
            BEGIN
               DELETE FROM xx_emf_error_headers_bk
                     WHERE process_id = rec_prcss.process_id
                       AND creation_date <=
                                          SYSDATE
                                          - (rec_prcss.purge_interval);

               x_del_success := 'Y';
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_del_success := 'N';
            END;
         END IF;

         -- Delete the data from debug trace tables
         IF x_del_success = 'Y'
         THEN
            BEGIN
               DELETE FROM xx_emf_debug_trace
                     WHERE process_id = rec_prcss.process_id
                       AND creation_date <=
                                          SYSDATE
                                          - (rec_prcss.purge_interval);

               x_del_success := 'Y';
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_del_success := 'N';
            END;
         END IF;

         IF x_del_success = 'Y'
         THEN
            COMMIT;
         ELSE
            ROLLBACK;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
   END purge_errors;

   -- This procedure is manily used while calling from concurrent program
   PROCEDURE purge_errors (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
   IS
   BEGIN
      purge_errors;
   END purge_errors;

   -- This is main procedure which is called the 2 procedure
   -- 1.This procedure will accept no_of_days as an input parameter and will insert the data in backup error tables
   --   Also delete the data from main error tables
   -- 2.This procedure is used to delete the data from backup error tables and trace tables based on purge interval
   --   set  in process setup form
   PROCEDURE arch_purge_errors (
      errbuf         OUT      VARCHAR2,
      retcode        OUT      VARCHAR2,
      p_no_of_days   IN       NUMBER
   )
   IS
   BEGIN
      arch_purge (p_no_of_days);
      purge_errors;
   END arch_purge_errors;

   PROCEDURE propagate_error (p_error_code IN VARCHAR2)
   IS
   BEGIN
      IF p_error_code = xx_emf_cn_pkg.cn_rec_err
      THEN
         RAISE xx_emf_pkg.g_e_rec_error;
      ELSIF p_error_code = xx_emf_cn_pkg.cn_prc_err
      THEN
         RAISE xx_emf_pkg.g_e_prc_error;
      END IF;
   END propagate_error;

   PROCEDURE update_recs_cnt (
      p_total_recs_cnt     NUMBER,
      p_success_recs_cnt   NUMBER,
      p_warning_recs_cnt   NUMBER,
      p_error_recs_cnt     NUMBER
   )
   IS
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_date    DATE   := SYSDATE;
      x_last_update_login   NUMBER := fnd_global.login_id;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_emf_error_headers
         SET total_recs_cnt = p_total_recs_cnt,
             success_recs_cnt = p_success_recs_cnt,
             error_recs_cnt = p_error_recs_cnt,
             warning_recs_cnt = p_warning_recs_cnt,
             last_updated_by = x_last_updated_by,
             last_update_date = x_last_update_date,
             last_update_login = x_last_update_login
       WHERE header_id = g_error_header_id;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
   END update_recs_cnt;

   PROCEDURE bulk_error (
      p_severity     IN   VARCHAR2,
      p_category     IN   VARCHAR2,
      p_error_text   IN   VARCHAR2,
      p_rec_ident    IN   g_xx_emf_ident_tab_type
   )
   IS
      x_error_details_type   xx_emf_error_details_tab_type;
      x_created_by           NUMBER                     := fnd_global.user_id;
      x_creation_date        DATE                          := SYSDATE;
      x_last_updated_by      NUMBER                     := fnd_global.user_id;
      x_last_update_date     DATE                          := SYSDATE;
      x_last_update_login    NUMBER                    := fnd_global.login_id;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      x_error_details_type := xx_emf_error_details_tab_type ();

      IF p_rec_ident.COUNT > 0
      THEN
         FOR i IN 1 .. p_rec_ident.COUNT
         LOOP
            x_error_details_type.EXTEND;
            x_error_details_type (i) :=
               xx_emf_error_details_rec_type
                                         (g_error_header_id,
                                          g_err_id,
                                          p_error_text,
                                          p_category,
                                          p_severity,
                                          p_rec_ident (i).record_identifier_1,
                                          p_rec_ident (i).record_identifier_2,
                                          p_rec_ident (i).record_identifier_3,
                                          p_rec_ident (i).record_identifier_4,
                                          p_rec_ident (i).record_identifier_5
                                         );
         END LOOP;

         INSERT INTO xx_emf_error_details
                     (header_id, err_id, err_text, err_type, err_severity,
                      record_identifier_1, record_identifier_2,
                      record_identifier_3, record_identifier_4,
                      record_identifier_5, creation_date, created_by,
                      last_update_date, last_updated_by, last_update_login)
            SELECT header_id, err_id, err_text, err_type, err_severity,
                   record_identifier_1, record_identifier_2,
                   record_identifier_3, record_identifier_4,
                   record_identifier_5, x_creation_date, x_created_by,
                   x_last_update_date, x_last_updated_by, x_last_update_login
              FROM TABLE
                      (CAST
                          (x_error_details_type AS xx_emf_error_details_tab_type
                          )
                      );

         COMMIT;
      END IF;
   END bulk_error;

   PROCEDURE put_line (p_buffer VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_buffer);
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'Error while puting message in Output :  '
                            || SQLERRM
                           );
   END put_line;

   PROCEDURE print_debug_log (p_request_id NUMBER)
   IS
      CURSOR cur_print_log
      IS
         SELECT   *
             FROM xx_emf_debug_trace
            WHERE request_id = p_request_id
         --ORDER BY creation_date,attribute1,debug_id
         ORDER BY attribute1 NULLS FIRST, creation_date, debug_id;
   BEGIN
      FOR cur_rec IN cur_print_log
      LOOP
         fnd_file.put_line (fnd_file.LOG,
                            cur_rec.attribute1 || '-' || cur_rec.debug_text
                           );
      END LOOP;
   END print_debug_log;

   FUNCTION get_paramater_value (
      p_process_name     VARCHAR2,
      p_parameter_name   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      x_param_value   xx_emf_process_parameters.parameter_value%TYPE;
   BEGIN
      SELECT parameter_value
        INTO x_param_value
        FROM xx_emf_process_setup xeps, xx_emf_process_parameters xepp
       WHERE xeps.process_name = p_process_name
         AND xeps.process_id = xepp.process_id
         AND UPPER (xepp.parameter_name) = UPPER (p_parameter_name);

      RETURN x_param_value;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_param_value := NULL;
         RETURN x_param_value;
   END get_paramater_value;
END xx_emf_pkg; 
/


GRANT EXECUTE ON APPS.XX_EMF_PKG TO INTG_XX_NONHR_RO;
