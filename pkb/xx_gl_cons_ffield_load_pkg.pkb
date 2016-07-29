DROP PACKAGE BODY APPS.XX_GL_CONS_FFIELD_LOAD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_GL_CONS_FFIELD_LOAD_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 29-Mar-2012
 File Name      : XXGLCONFLEXMAPLOAD.pkb
 Description    : This script creates the body of the package xx_gl_cons_ffield_load_pkg
----------------------------*------------------------------------------------------------------
----------------------------*------------------------------------------------------------------
COMMON GUIDELINES REGARDING EMF
-------------------------------
1. ALL LOW LEVEL EMF MESSAGES CAN BE RETAINED
2. HARD CODING OF EMF MESSAGES ARE ALLOWED IN THE CODE
3. ANY OTHER HARD CODING SHOULD BE DEALT BY CONSTANTS PACKAGE
4. EXCEPTION HANDLING SHOULD BE LEFT AS IS MOST OF THE PLACES UNLESS SPECIFIED
 Change History:
 ---------------------------------------------------------------------------------------------
 Date        Name          Remarks
 ---------------------------------------------------------------------------------------------
 29-Mar-2012   IBM Development Team   Initial development.
 11-Jun-2012   IBM Development Team   Added overloaded function get_ccid
 ---------------------------------------------------------------------------------------------
*/
   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS

   -------------------------------------------------------------------------------------
------------<Procedure for setting Environment>----------------------------------------
-------------------------------------------------------------------------------------
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Message in EMF');
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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' Error Message in  EMF :' || SQLERRM
                              );
         RAISE xx_emf_pkg.g_e_env_not_set;
   --RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
   END set_cnv_env;

--------------------------------------------------------------------------------
------------------< Mark_records_for_processing >-------------------------------
--------------------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (
      p_restart_flag    IN   VARCHAR2,
      p_override_flag   IN   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'In mark_records_for_processing'
                           );

      -- If the override is set records should not be purged from the pre-interface tables
      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_gl_cons_ffield_map_piface
                  WHERE batch_id = g_batch_id;

            UPDATE xx_gl_cons_ffield_map_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE replace(batch_id,CHR(13),'') = g_batch_id;
         ELSE
            UPDATE xx_gl_cons_ffield_map_piface
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
            UPDATE xx_gl_cons_ffield_map_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE replace(batch_id,CHR(13),'') = g_batch_id
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
         UPDATE xx_gl_cons_ffield_map_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE replace(batch_id,CHR(13),'') = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_gl_cons_ffield_map_piface
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_gl_cons_ffield_map_piface
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_gl_cons_ffield_map_piface
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
         UPDATE xx_gl_cons_ffield_map_piface
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
         UPDATE xx_gl_cons_ffield_map_piface
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
         UPDATE xx_gl_cons_ffield_map_piface
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
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Error Message in mark receords:' || SQLERRM
                              );
   END mark_records_for_processing;

--------------------------------------------------------------------------------
------------------< set_stage >-------------------------------------------------
--------------------------------------------------------------------------------
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'In Set Stage:');
      g_stage := p_stage;
   END set_stage;

-------------------------------------------------------------------------------------
------------Procedure for Updating stage Records-------------------------------------
-------------------------------------------------------------------------------------
   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER := fnd_global.conc_login_id;
      --fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'In update staging records:'
                           );

      UPDATE xx_gl_cons_ffield_map_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE replace(batch_id,CHR(13),'') = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;

      COMMIT;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Req id is :');
   END update_staging_records;

-------------------------------------------------------------------------------------
----------------------------------Procedure main-------------------------------------
-------------------------------------------------------------------------------------
   PROCEDURE main (
      errbuf                OUT NOCOPY      VARCHAR2,
      retcode               OUT NOCOPY      VARCHAR2,
      p_batch_id            IN              VARCHAR2,
      p_coa_mapping_id      IN              VARCHAR2,
      p_restart_flag        IN              VARCHAR2,
      p_override_flag       IN              VARCHAR2,
      p_purge_flag          IN              VARCHAR2,
      p_process_mode        IN              VARCHAR2,
      p_validate_and_load   IN              VARCHAR2,
      p_ledger_id           IN              VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_pre_std_hdr_table   g_xxgl_ffield_map_piface_tab;
      x_sqlerrm             VARCHAR2 (2000);

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_intg_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   flexfield_map_id, consolidation_id_11i, last_update_date,
                  last_updated_by, to_code_combination_id, to_segment1,
                  to_segment2, to_segment3, to_segment4, to_segment5,
                  to_segment6, to_segment7, to_segment8, --NPANDA to_segment9,
                  creation_date, created_by, last_update_login, segment1_low,
                  segment1_high, segment2_low, segment2_high, segment3_low,
                  segment3_high, segment4_low, segment4_high, segment5_low,
                  segment5_high, segment6_low, segment6_high, segment7_low,
                  segment7_high, segment8_low, segment8_high, attribute1,
                  attribute2, attribute3, attribute4, attribute5, CONTEXT,
                  coa_mapping_id, batch_id, record_number, process_code,
                  ERROR_CODE, request_id, program_application_id, program_id,
                  program_update_date
             FROM xx_gl_cons_ffield_map_piface
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              --     AND error_code   IN (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN) -- Changed by Rohit J
              AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success) IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

-------------------------------------------------------------------------
-----------< Update_record_status >--------------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   g_xxgl_ffield_map_piface_rec,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               ' In Update_record_status'
                              );

         IF p_error_code IN
                         (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' Error code in Update rec status '
                                  || p_conv_pre_std_hdr_rec.ERROR_CODE
                                 );
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_gl_cons_ffield_val_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.cn_success
                                          )
                                     );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     ' Error code 1 in Update rec status '
                                  || p_conv_pre_std_hdr_rec.ERROR_CODE
                                 );
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'G_STAGE ' || g_stage);
         p_conv_pre_std_hdr_rec.process_code := g_stage;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Updated error code= '
                               || p_conv_pre_std_hdr_rec.ERROR_CODE
                              );
      END update_record_status;

-------------------------------------------------------------------------
 -----------< mark_records_complete >-------------------------------------
 -------------------------------------------------------------------------
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER := fnd_global.conc_login_id;
         --fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'In mark records complete:Process-Code=>'
                               || p_process_code
                              );

         UPDATE xx_gl_cons_ffield_map_piface
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

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '~Number of Record Marked:Process-Code=>'
                               || p_process_code
                               || '-'
                               || SQL%ROWCOUNT
                              );
         COMMIT;
      END mark_records_complete;

-------------------------------------------------------------------------
-----------< update_pre_interface_records >------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xxgl_ffield_map_piface_tab
      )
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER := fnd_global.conc_login_id;
         --fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Before update pre interface records:'
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

            --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_pre_std_hdr_table(indx).parent_id ' || p_cnv_pre_std_hdr_table(indx).parent_id);
            BEGIN
               UPDATE xx_gl_cons_ffield_map_piface
                  SET flexfield_map_id =
                               p_cnv_pre_std_hdr_table (indx).flexfield_map_id,
                      consolidation_id_11i =
                           p_cnv_pre_std_hdr_table (indx).consolidation_id_11i,
                      last_update_date =
                               p_cnv_pre_std_hdr_table (indx).last_update_date,
                      last_updated_by =
                                p_cnv_pre_std_hdr_table (indx).last_updated_by,
                      to_code_combination_id =
                         p_cnv_pre_std_hdr_table (indx).to_code_combination_id,
                      to_segment1 = p_cnv_pre_std_hdr_table (indx).to_segment1,
                      to_segment2 = p_cnv_pre_std_hdr_table (indx).to_segment2,
                      to_segment3 = p_cnv_pre_std_hdr_table (indx).to_segment3,
                      to_segment4 = p_cnv_pre_std_hdr_table (indx).to_segment4,
                      to_segment5 = p_cnv_pre_std_hdr_table (indx).to_segment5,
                      to_segment6 = p_cnv_pre_std_hdr_table (indx).to_segment6,
                      to_segment7 = p_cnv_pre_std_hdr_table (indx).to_segment7,
                      to_segment8 = p_cnv_pre_std_hdr_table (indx).to_segment8,
                     --NPANDA to_segment9 = p_cnv_pre_std_hdr_table (indx).to_segment9,
                      creation_date =
                                  p_cnv_pre_std_hdr_table (indx).creation_date,
                      created_by = p_cnv_pre_std_hdr_table (indx).created_by,
                      last_update_login =
                              p_cnv_pre_std_hdr_table (indx).last_update_login,
                      segment1_low =
                                   p_cnv_pre_std_hdr_table (indx).segment1_low,
                      segment1_high =
                                  p_cnv_pre_std_hdr_table (indx).segment1_high,
                      segment2_low =
                                   p_cnv_pre_std_hdr_table (indx).segment2_low,
                      segment2_high =
                                  p_cnv_pre_std_hdr_table (indx).segment2_high,
                      segment3_low =
                                   p_cnv_pre_std_hdr_table (indx).segment3_low,
                      segment3_high =
                                  p_cnv_pre_std_hdr_table (indx).segment3_high,
                      segment4_low =
                                   p_cnv_pre_std_hdr_table (indx).segment4_low,
                      segment4_high =
                                  p_cnv_pre_std_hdr_table (indx).segment4_high,
                      segment5_low =
                                   p_cnv_pre_std_hdr_table (indx).segment5_low,
                      segment5_high =
                                  p_cnv_pre_std_hdr_table (indx).segment5_high,
                      segment6_low =
                                   p_cnv_pre_std_hdr_table (indx).segment6_low,
                      segment6_high =
                                  p_cnv_pre_std_hdr_table (indx).segment6_high,
                      segment7_low =
                                   p_cnv_pre_std_hdr_table (indx).segment7_low,
                      segment7_high =
                                  p_cnv_pre_std_hdr_table (indx).segment7_high,
                      segment8_low =
                                   p_cnv_pre_std_hdr_table (indx).segment8_low,
                      segment8_high =
                                  p_cnv_pre_std_hdr_table (indx).segment8_high,
                      attribute1 = p_cnv_pre_std_hdr_table (indx).attribute1,
                      attribute2 = p_cnv_pre_std_hdr_table (indx).attribute2,
                      attribute3 = p_cnv_pre_std_hdr_table (indx).attribute3,
                      attribute4 = p_cnv_pre_std_hdr_table (indx).attribute4,
                      attribute5 = p_cnv_pre_std_hdr_table (indx).attribute5,
                      CONTEXT = p_cnv_pre_std_hdr_table (indx).CONTEXT,
                      coa_mapping_id =
                                 p_cnv_pre_std_hdr_table (indx).coa_mapping_id,
                      batch_id = p_cnv_pre_std_hdr_table (indx).batch_id,
                      record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number,
                      process_code =
                                   p_cnv_pre_std_hdr_table (indx).process_code,
                      ERROR_CODE = p_cnv_pre_std_hdr_table (indx).ERROR_CODE,
                      request_id = p_cnv_pre_std_hdr_table (indx).request_id,
                      program_application_id =
                         p_cnv_pre_std_hdr_table (indx).program_application_id,
                      program_id = p_cnv_pre_std_hdr_table (indx).program_id,
                      program_update_date =
                            p_cnv_pre_std_hdr_table (indx).program_update_date
                WHERE record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number
                  AND batch_id = g_batch_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log
                                 (xx_emf_cn_pkg.cn_low,
                                     'update_pre_interface_records failed ->'
                                  || SQLERRM
                                 );
            END;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;

-------------------------------------------------------------------------
      -----------< move_rec_pre_standard_table >-------------------------------
      -------------------------------------------------------------------------
      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date           DATE                         := SYSDATE;
         x_created_by              NUMBER               := fnd_global.user_id;
         x_last_update_date        DATE                         := SYSDATE;
         x_last_updated_by         NUMBER               := fnd_global.user_id;
         x_last_update_login       NUMBER         := fnd_global.conc_login_id;
         --fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         x_cnv_pre_std_hdr_table   g_xxgl_ffield_map_piface_tab;
         -- := G_XX_HR_PH_CNV_PRE_REC_TYPE();
         x_error_code              NUMBER         := xx_emf_cn_pkg.cn_success;
         x_count                   NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move rec pre standard table'
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'BATCH_ID :' || g_batch_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'process_code : ' || xx_emf_cn_pkg.cn_preval
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'error_code : '
                               || xx_emf_cn_pkg.cn_success
                               || ' '
                               || xx_emf_cn_pkg.cn_rec_warn
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'request_id :' || xx_emf_pkg.g_request_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );

         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table
         --xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'In beforre insert table xx_ar_receipt_hdr_piface');
         INSERT INTO xx_gl_cons_ffield_map_piface
                     (flexfield_map_id, consolidation_id_11i,
                      last_update_date, last_updated_by,
                      to_code_combination_id, to_segment1, to_segment2,
                      to_segment3, to_segment4, to_segment5, to_segment6,
                      to_segment7, to_segment8, --NPANDA to_segment9,
                      creation_date,
                      created_by, last_update_login, segment1_low,
                      segment1_high, segment2_low, segment2_high,
                      segment3_low, segment3_high, segment4_low,
                      segment4_high, segment5_low, segment5_high,
                      segment6_low, segment6_high, segment7_low,
                      segment7_high, segment8_low, segment8_high, attribute1,
                      attribute2, attribute3, attribute4, attribute5, CONTEXT,
                      coa_mapping_id, batch_id, record_number, process_code,
                      ERROR_CODE, request_id, program_application_id,
                      program_id, program_update_date)
            SELECT flexfield_map_id, consolidation_id_11i, last_update_date,
                   last_updated_by, to_code_combination_id, to_segment1,
                   to_segment2, to_segment3, to_segment4, to_segment5,
                   to_segment6, to_segment7, to_segment8, --NPANDA to_segment9,
                   creation_date, created_by, last_update_login, segment1_low,
                   segment1_high, segment2_low, segment2_high, segment3_low,
                   segment3_high, segment4_low, segment4_high, segment5_low,
                   segment5_high, segment6_low, segment6_high, segment7_low,
                   segment7_high, segment8_low, segment8_high, attribute1,
                   attribute2, attribute3, attribute4, attribute5, CONTEXT,
                   TO_NUMBER (p_coa_mapping_id), replace(batch_id,CHR(13),''), record_number,
                   process_code, ERROR_CODE, request_id,
                   program_application_id, program_id, program_update_date
              FROM xx_gl_cons_ffield_map_stg stg
             WHERE replace(batch_id,CHR(13),'') = g_batch_id
               AND process_code = xx_emf_cn_pkg.cn_preval
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                                                                             --AND nvl(date_to,sysdate) >= trunc(sysdate)
         ;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Record count is ' || SQL%ROWCOUNT
                              );
         COMMIT;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_tech_error,
                       p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                       p_record_identifier_3      => 'Move Rec pre_standard_table'
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
         x_return_status   VARCHAR2 (15) := xx_emf_cn_pkg.cn_success;
      BEGIN
         --BEGIN
            -- Change the logic to whatever needs to be done
            -- with valid records in the pre-interface tables
            -- either call the appropriate API to process the data
            -- or to insert into an interface table.
         IF p_purge_flag = 'Y' AND p_process_mode = 'ALL'
         THEN
            DELETE FROM gl.gl_cons_flexfield_map;

            COMMIT;
         ELSIF p_purge_flag = 'Y' AND p_process_mode <> 'ALL'
         THEN
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                'Wrong use of purge flag.Cannot use purge with process mode Update/Replace.'
               );
         END IF;

         IF p_process_mode = 'ALL'
         THEN
            BEGIN
               xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                 'Before Insert into GL_CONS_FLEXFIELD_MAP>>'
                                );

               INSERT INTO gl_cons_flexfield_map
                           (flexfield_map_id, consolidation_id_11i,
                            last_update_date, last_updated_by,
                            to_code_combination_id, creation_date, created_by,
                            last_update_login, segment1_low, segment1_high,
                            segment2_low, segment2_high, segment3_low,
                            segment3_high, segment4_low, segment4_high,
                            segment5_low, segment5_high, segment6_low,
                            segment6_high, segment7_low, segment7_high,
                            segment8_low, segment8_high, attribute1,
                            attribute2, attribute3, attribute4, attribute5,
                            CONTEXT, coa_mapping_id)
                  SELECT flexfield_map_id, consolidation_id_11i,
                         last_update_date, last_updated_by,
                         to_code_combination_id, creation_date, created_by,
                         last_update_login, segment1_low, segment1_high,
                         segment2_low, segment2_high, segment3_low,
                         segment3_high, segment4_low, segment4_high,
                         segment5_low, segment5_high, segment6_low,
                         segment6_high, segment7_low, segment7_high,
                         segment8_low, segment8_high, attribute1, attribute2,
                         attribute3, attribute4, attribute5, CONTEXT,
                         coa_mapping_id
                    FROM xx_gl_cons_ffield_map_piface
                   WHERE batch_id = g_batch_id
                     AND request_id = xx_emf_pkg.g_request_id
                     AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_success,
                             xx_emf_cn_pkg.cn_rec_warn
                            )
                     AND process_code = xx_emf_cn_pkg.cn_postval
                     AND to_code_combination_id IS NOT NULL;

               RETURN x_return_status;
               COMMIT;
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX
               THEN
                  x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                  x_return_status := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               =>    'Re-run with Purge Flag set to YES.'
                                                    || x_sqlerrm,
                      p_record_identifier_1      => NULL,
                      p_record_identifier_2      => NULL,
                      p_record_identifier_3      => 'Unique index violated while inserting in gl_cons_flexfield_map.'
                     );
                  RETURN x_return_status;
               WHEN OTHERS
               THEN
                  x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                  x_return_status := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               =>    'Err Main-GL_MAP Excp1'
                                                    || x_sqlerrm,
                      p_record_identifier_1      => NULL,
                      p_record_identifier_2      => NULL,
                      p_record_identifier_3      => 'Err in gl_cons_flexfield_map Insert'
                     );
                  RETURN x_return_status;
            END;
         ELSIF p_purge_flag <> 'Y'
         THEN
            BEGIN
               xx_emf_pkg.write_log
                                   (xx_emf_cn_pkg.cn_low,
                                    'Before updating GL_CONS_FLEXFIELD_MAP>>'
                                   );
               MERGE INTO gl_cons_flexfield_map tgt
                  USING (SELECT flexfield_map_id, consolidation_id_11i,
                                last_update_date, last_updated_by,
                                to_code_combination_id, creation_date,
                                created_by, last_update_login, segment1_low,
                                segment1_high, segment2_low, segment2_high,
                                segment3_low, segment3_high, segment4_low,
                                segment4_high, segment5_low, segment5_high,
                                segment6_low, segment6_high, segment7_low,
                                segment7_high, segment8_low, segment8_high,
                                attribute1, attribute2, attribute3,
                                attribute4, attribute5, CONTEXT,
                                coa_mapping_id
                           FROM xx_gl_cons_ffield_map_piface
                          WHERE batch_id = g_batch_id
                            AND request_id = xx_emf_pkg.g_request_id
                            AND ERROR_CODE IN
                                   (xx_emf_cn_pkg.cn_success,
                                    xx_emf_cn_pkg.cn_rec_warn
                                   )
                            AND process_code = xx_emf_cn_pkg.cn_postval
                            AND to_code_combination_id IS NOT NULL) src
                  ON (    src.segment1_low = tgt.segment1_low
                      AND src.segment1_high = tgt.segment1_high
                      AND src.segment2_low = tgt.segment2_low
                      AND src.segment2_high = tgt.segment2_high
                      AND src.segment3_low = tgt.segment3_low
                      AND src.segment3_high = tgt.segment3_high
                      AND src.segment4_low = tgt.segment4_low
                      AND src.segment4_high = tgt.segment4_high
                      AND src.segment5_low = tgt.segment5_low
                      AND src.segment5_high = tgt.segment5_high
                      AND src.segment6_low = tgt.segment6_low
                      AND src.segment6_high = tgt.segment6_high
                      AND src.segment7_low = tgt.segment7_low
                      AND src.segment7_high = tgt.segment7_high
                      AND src.segment8_low = tgt.segment8_low
                      AND src.segment8_high = tgt.segment8_high)
                  WHEN MATCHED THEN
                     UPDATE
                        SET tgt.to_code_combination_id =
                                                    src.to_code_combination_id,
                            tgt.coa_mapping_id = src.coa_mapping_id,
                            tgt.last_update_date = src.last_update_date,
                            tgt.last_updated_by = src.last_updated_by,
                            tgt.last_update_login = src.last_update_login
                  WHEN NOT MATCHED THEN
                     INSERT (tgt.flexfield_map_id, tgt.consolidation_id_11i,
                             tgt.last_update_date, tgt.last_updated_by,
                             tgt.to_code_combination_id, tgt.creation_date,
                             tgt.created_by, tgt.last_update_login,
                             tgt.segment1_low, tgt.segment1_high,
                             tgt.segment2_low, tgt.segment2_high,
                             tgt.segment3_low, tgt.segment3_high,
                             tgt.segment4_low, tgt.segment4_high,
                             tgt.segment5_low, tgt.segment5_high,
                             tgt.segment6_low, tgt.segment6_high,
                             tgt.segment7_low, tgt.segment7_high,
                             tgt.segment8_low, tgt.segment8_high,
                             tgt.attribute1, tgt.attribute2, tgt.attribute3,
                             tgt.attribute4, tgt.attribute5, tgt.CONTEXT,
                             tgt.coa_mapping_id)
                     VALUES (src.flexfield_map_id, src.consolidation_id_11i,
                             src.last_update_date, src.last_updated_by,
                             src.to_code_combination_id, src.creation_date,
                             src.created_by, src.last_update_login,
                             src.segment1_low, src.segment1_high,
                             src.segment2_low, src.segment2_high,
                             src.segment3_low, src.segment3_high,
                             src.segment4_low, src.segment4_high,
                             src.segment5_low, src.segment5_high,
                             src.segment6_low, src.segment6_high,
                             src.segment7_low, src.segment7_high,
                             src.segment8_low, src.segment8_high,
                             src.attribute1, src.attribute2, src.attribute3,
                             src.attribute4, src.attribute5, src.CONTEXT,
                             src.coa_mapping_id);
               RETURN x_return_status;
               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
                  x_return_status := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               =>    'Err Main-GL_MAP Excp1'
                                                    || x_sqlerrm,
                      p_record_identifier_1      => NULL,
                      p_record_identifier_2      => NULL,
                      p_record_identifier_3      => 'Err in gl_cons_flexfield_map Update.'
                     );
                  RETURN x_return_status;
            END;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_sqlerrm := SQLERRM;
            x_return_status := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_high,
                              p_category                 => xx_emf_cn_pkg.cn_tech_error,
                              p_error_text               =>    'Error in Main-Insr Exp2'
                                                            || x_sqlerrm,
                              p_record_identifier_3      => 'Process Main Insert'
                             );
            RETURN x_return_status;
      END process_data;

-------------------------------------------------------------------------
-----------< update_record_count >---------------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_count (p_validate_and_load IN VARCHAR2)
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_gl_cons_ffield_map_stg
             WHERE replace(batch_id,CHR(13),'') = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (a.error_count) error_count
              FROM (SELECT COUNT (1) error_count
                      FROM xx_gl_cons_ffield_map_stg
                     WHERE replace(batch_id,CHR(13),'') = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_gl_cons_ffield_map_piface
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err) a;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_gl_cons_ffield_map_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_gl_cons_ffield_map_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         CURSOR c_get_success_valid_cnt
         IS
            SELECT COUNT (1) success_count
              FROM xx_gl_cons_ffield_map_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_postval
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

         IF p_validate_and_load = g_validate_and_load
         THEN
            OPEN c_get_success_cnt;

            FETCH c_get_success_cnt
             INTO x_success_cnt;

            CLOSE c_get_success_cnt;
         ELSE
            OPEN c_get_success_valid_cnt;

            FETCH c_get_success_valid_cnt
             INTO x_success_cnt;

            CLOSE c_get_success_valid_cnt;
         END IF;

         xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                     p_success_recs_cnt      => x_success_cnt,
                                     p_warning_recs_cnt      => x_warn_cnt,
                                     p_error_recs_cnt        => x_error_cnt
                                    );
      END;

-------------------------------------------------------------------------
-----------< update_record_count >---------------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_gl_cons_ffield_map_stg
             WHERE replace(batch_id,CHR(13),'') = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            /*SELECT COUNT (1) error_count
              FROM xx_fa_mass_add_piface
             WHERE batch_id   = G_BATCH_ID
               AND request_id = xx_emf_pkg.G_REQUEST_ID
               AND error_code = xx_emf_cn_pkg.CN_REC_ERR
            UNION ALL*/
            SELECT COUNT (1) error_count
              FROM xx_gl_cons_ffield_map_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_gl_cons_ffield_map_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_gl_cons_ffield_map_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         x_success_cnt   NUMBER;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'In update_record_count '
                              );

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
----  begin of procedure main starts here      ------------------------
----------------------------------------------------------------------
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'In start of Main program'
                           );
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
                            'Main:Param - p_process_mode ' || p_process_mode
                           );
      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );

     -- Once the records are identified based on the input parameters
     -- Start with pre-validations
-----------------------------------------------------------------------------------------------
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
         -- x_error_code :=
          --xx_gl_cons_ffield_val_pkg.pre_validations(x_pre_std_hdr_table (i));
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After pre-validations X_ERROR_CODE '
                               || x_error_code
                              );
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         update_staging_records (xx_emf_cn_pkg.cn_success);
         xx_emf_pkg.propagate_error (x_error_code);
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After update_staging_records X_ERROR_CODE '
                               || x_error_code
                              );
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;

     -- Once pre-validations are complete the loop through the pre-interface records
     -- and perform data validations on this table
     -- Set the stage to data Validations
------------------------------------------------------------------------------------------------
 ------------------------------------------------------
 ----------( Stage 2: Data Validations)----------------
 ------------------------------------------------------
      set_stage (xx_emf_cn_pkg.cn_valid);

      --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Before data validation for Loop' || X_ERROR_CODE);
      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'Before data validation for Loop1' || X_ERROR_CODE);
      LOOP                                             --c_xx_intg_pre_std_hdr
         FETCH c_xx_intg_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         --   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_MEDIUM, 'After data validation for Loop Record=' || x_pre_std_hdr_table.COUNT);
         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
                -- Perform header level Base App Validations
               --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion ');
               x_error_code :=
                  xx_gl_cons_ffield_val_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for validtion Record=>'
                                     || x_pre_std_hdr_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               ------Comment by venu for Error
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        'In Exception 1:' || SQLERRM
                                       );
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
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        'In Exception 3:' || SQLERRM
                                       );
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                      p_record_identifier_1      =>    x_pre_std_hdr_table (i).segment1_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment2_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment3_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment4_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment5_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment6_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment7_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment8_low,
                      p_record_identifier_2      =>    x_pre_std_hdr_table (i).to_segment1
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment2
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment3
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment4
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment5
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment6
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment7
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment8, --NPANDA added comma
                                                   --NPANDA || '.'
                                                   --NPANDA || x_pre_std_hdr_table (i).to_segment9,
                      p_record_identifier_3      => 'Stage 2:Data Validation'
                     );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count'
                               || x_pre_std_hdr_table.COUNT
                              );
         --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Calling update_pre_interface_records' || x_pre_std_hdr_table(1).error_code);
         --Comment by venu for Error
         update_pre_interface_records (x_pre_std_hdr_table);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Called update_pre_interface_records'
                              );
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, g_stage);
      --mark_records_complete (xx_emf_cn_pkg.CN_VALID);
      --commit;
      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations

      -----------------------------------------------------------------------------
----------( Stage 3: Data Derivations)---------------------------------------
-----------------------------------------------------------------------------
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_xx_intg_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Records Count in data derivation:'
                               || x_pre_std_hdr_table.COUNT
                              );

         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data Derivation ');
               x_error_code :=
                  xx_gl_cons_ffield_val_pkg.data_derivations
                                                     (x_pre_std_hdr_table (i),
                                                      TO_NUMBER (p_ledger_id)
                                                     );
               -- x_error_code := xx_hr_emp_ph_cnv_val_pkg.data_derivations (x_pre_std_hdr_table (i));
                --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for derivation  '|| x_pre_std_hdr_table (i).record_number|| ' is ' || x_error_code);
                --------comment by venu for error
               update_record_status (x_pre_std_hdr_table (i), x_error_code);
               --update_record_status (x_pre_std_hdr_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
               -- If HIGH error then it will be propagated to the next level
               -- IF the process has to continue maintain it as a medium severity
               WHEN xx_emf_pkg.g_e_rec_error
               THEN
                  --fnd_file.Put_line(1, ' In Exception 1, During data derivation:'||SQLERRM);
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                                        xx_emf_cn_pkg.cn_rec_err || SQLERRM
                                       );
               WHEN xx_emf_pkg.g_e_prc_error
               THEN
                  --fnd_file.Put_line(1, ' In Exception 2, During data derivation:'||SQLERRM);
                  xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_high,
                                    'Process Level Error in Data derivations'
                                 || SQLERRM
                                );
                  --------comment by venu for error--------------------------------------------
                  update_pre_interface_records (x_pre_std_hdr_table);
                  --update_pre_interface_records (x_pre_std_hdr_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'In Exception 3, During data derivation:'
                                 || SQLERRM
                                );
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_tech_error,
                      p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                      p_record_identifier_1      =>    x_pre_std_hdr_table (i).segment1_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment2_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment3_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment4_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment5_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment6_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment7_low
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).segment8_low,
                      p_record_identifier_2      =>    x_pre_std_hdr_table (i).to_segment1
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment2
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment3
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment4
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment5
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment6
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment7
                                                    || '.'
                                                    || x_pre_std_hdr_table (i).to_segment8, --NPANDA added comma
                                                   --NPANDA || '.'
                                                   --NPANDA || x_pre_std_hdr_table (i).to_segment9,
                      p_record_identifier_3      => 'Stage 3:Data Derivation'
                     );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count in der'
                               || x_pre_std_hdr_table.COUNT
                              );
         update_pre_interface_records (x_pre_std_hdr_table);
         x_pre_std_hdr_table.DELETE;
         EXIT WHEN c_xx_intg_pre_std_hdr%NOTFOUND;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
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
       -- x_error_code := xx_cn_trnx_validations_pkg.post_validations();
      --Comment by venu for Error
      x_error_code := xx_gl_cons_ffield_val_pkg.post_validations();
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );

      IF p_validate_and_load = g_validate_and_load
      THEN
         mark_records_complete (xx_emf_cn_pkg.cn_postval);
         xx_emf_pkg.propagate_error (x_error_code);
         -- Set the stage to Post Validations
         set_stage (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Calling Process Data'
                              );
         x_error_code := process_data (NULL, NULL);
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.propagate_error (x_error_code);
         update_record_count;
      END IF;

      update_record_count (p_validate_and_load);
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         fnd_file.put_line (fnd_file.output, xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
   END main;

-- get_ccid function
   FUNCTION get_ccid (
      x_segment1       IN       VARCHAR2,
      x_segment2       IN       VARCHAR2,
      x_segment3       IN       VARCHAR2,
      x_segment4       IN       VARCHAR2,
      x_segment5       IN       VARCHAR2,
      x_segment6       IN       VARCHAR2,
      x_segment7       IN       VARCHAR2,
      x_segment8       IN       VARCHAR2,
      x_source         IN       VARCHAR2,
      x_segment1_out   OUT      VARCHAR2,
      x_segment2_out   OUT      VARCHAR2,
      x_segment3_out   OUT      VARCHAR2,
      x_segment4_out   OUT      VARCHAR2,
      x_segment5_out   OUT      VARCHAR2,
      x_segment6_out   OUT      VARCHAR2,
      x_segment7_out   OUT      VARCHAR2,
      x_segment8_out   OUT      VARCHAR2,
      x_segment9_out   OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      x_ccid   NUMBER;
   BEGIN
      SELECT gcc.segment1, gcc.segment2, gcc.segment3, gcc.segment4,
             gcc.segment5, gcc.segment6, gcc.segment7, gcc.segment8,
             gcc.segment9, gcf.to_code_combination_id
        INTO x_segment1_out, x_segment2_out, x_segment3_out, x_segment4_out,
             x_segment5_out, x_segment6_out, x_segment7_out, x_segment8_out,
             x_segment9_out, x_ccid
        FROM gl_code_combinations gcc,
             gl_cons_flexfield_map gcf,
             gl_coa_mappings gcm,
             fnd_lookup_values fv
       WHERE gcm.to_coa_id = gcc.chart_of_accounts_id
         AND SYSDATE BETWEEN gcm.start_date_active
                         AND NVL (gcm.end_date_active,
                                  TO_DATE ('01/01/2099', 'DD/MM/YYYY')
                                 )
         AND fv.lookup_type = 'INTG_LEGACY_TARGET_COA_MAPPING'
         AND fv.LANGUAGE = 'US'
         AND fv.enabled_flag = 'Y'
         AND fv.lookup_code = x_source
         AND fv.meaning = gcm.NAME
         AND gcm.coa_mapping_id = gcf.coa_mapping_id
         AND NVL (x_segment1, 'XXXX') BETWEEN NVL (gcf.segment1_low, 'XXXX')
                                          AND NVL (gcf.segment1_high, 'XXXX')
         AND NVL (x_segment2, 'XXXX') BETWEEN NVL (gcf.segment2_low, 'XXXX')
                                          AND NVL (gcf.segment2_high, 'XXXX')
         AND NVL (x_segment3, 'XXXX') BETWEEN NVL (gcf.segment3_low, 'XXXX')
                                          AND NVL (gcf.segment3_high, 'XXXX')
         AND NVL (x_segment4, 'XXXX') BETWEEN NVL (gcf.segment4_low, 'XXXX')
                                          AND NVL (gcf.segment4_high, 'XXXX')
         AND NVL (x_segment5, 'XXXX') BETWEEN NVL (gcf.segment5_low, 'XXXX')
                                          AND NVL (gcf.segment5_high, 'XXXX')
         AND NVL (x_segment6, 'XXXX') BETWEEN NVL (gcf.segment6_low, 'XXXX')
                                          AND NVL (gcf.segment6_high, 'XXXX')
         AND NVL (x_segment7, 'XXXX') BETWEEN NVL (gcf.segment7_low, 'XXXX')
                                          AND NVL (gcf.segment7_high, 'XXXX')
         AND NVL (x_segment8, 'XXXX') BETWEEN NVL (gcf.segment8_low, 'XXXX')
                                          AND NVL (gcf.segment8_high, 'XXXX')
         AND gcc.code_combination_id = gcf.to_code_combination_id;

      RETURN x_ccid;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END;

-- get_ccid over loaded function

   FUNCTION get_ccid (
      x_segment1   IN   VARCHAR2,
      x_segment2   IN   VARCHAR2,
      x_segment3   IN   VARCHAR2,
      x_segment4   IN   VARCHAR2,
      x_segment5   IN   VARCHAR2,
      x_segment6   IN   VARCHAR2,
      x_segment7   IN   VARCHAR2,
      x_segment8   IN   VARCHAR2,
      x_source     IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      x_ccid   NUMBER;
   BEGIN
      SELECT gcf.to_code_combination_id
        INTO x_ccid
        FROM gl_code_combinations gcc,
             gl_cons_flexfield_map gcf,
             gl_coa_mappings gcm,
             fnd_lookup_values fv
       WHERE gcm.to_coa_id = gcc.chart_of_accounts_id
         AND SYSDATE BETWEEN gcm.start_date_active
                         AND NVL (gcm.end_date_active,
                                  TO_DATE ('01/01/2099', 'DD/MM/YYYY')
                                 )
         AND fv.lookup_type = 'INTG_LEGACY_TARGET_COA_MAPPING'
         AND fv.LANGUAGE = 'US'
         AND fv.enabled_flag = 'Y'
         AND fv.lookup_code = x_source
         AND fv.meaning = gcm.NAME
         AND gcm.coa_mapping_id = gcf.coa_mapping_id
         AND NVL (x_segment1, 'XXXX') BETWEEN NVL (gcf.segment1_low, 'XXXX')
                                          AND NVL (gcf.segment1_high, 'XXXX')
         AND NVL (x_segment2, 'XXXX') BETWEEN NVL (gcf.segment2_low, 'XXXX')
                                          AND NVL (gcf.segment2_high, 'XXXX')
         AND NVL (x_segment3, 'XXXX') BETWEEN NVL (gcf.segment3_low, 'XXXX')
                                          AND NVL (gcf.segment3_high, 'XXXX')
         AND NVL (x_segment4, 'XXXX') BETWEEN NVL (gcf.segment4_low, 'XXXX')
                                          AND NVL (gcf.segment4_high, 'XXXX')
         AND NVL (x_segment5, 'XXXX') BETWEEN NVL (gcf.segment5_low, 'XXXX')
                                          AND NVL (gcf.segment5_high, 'XXXX')
         AND NVL (x_segment6, 'XXXX') BETWEEN NVL (gcf.segment6_low, 'XXXX')
                                          AND NVL (gcf.segment6_high, 'XXXX')
         AND NVL (x_segment7, 'XXXX') BETWEEN NVL (gcf.segment7_low, 'XXXX')
                                          AND NVL (gcf.segment7_high, 'XXXX')
         AND NVL (x_segment8, 'XXXX') BETWEEN NVL (gcf.segment8_low, 'XXXX')
                                          AND NVL (gcf.segment8_high, 'XXXX')
         AND gcc.code_combination_id = gcf.to_code_combination_id;

      RETURN x_ccid;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END;

-- get_ccid over loaded function with component name
   FUNCTION get_ccid (
      x_segment1   IN   VARCHAR2,
      x_segment2   IN   VARCHAR2,
      x_segment3   IN   VARCHAR2,
      x_segment4   IN   VARCHAR2,
      x_segment5   IN   VARCHAR2,
      x_segment6   IN   VARCHAR2,
      x_segment7   IN   VARCHAR2,
      x_segment8   IN   VARCHAR2,
      x_source     IN   VARCHAR2,
      x_component_name IN       VARCHAR2
   )
      RETURN NUMBER
   IS
      x_ccid   NUMBER;
   BEGIN
      SELECT gcf.to_code_combination_id
        INTO x_ccid
        FROM gl_code_combinations gcc,
             gl_cons_flexfield_map gcf,
             gl_coa_mappings gcm,
             fnd_lookup_values fv
       WHERE gcm.to_coa_id = gcc.chart_of_accounts_id
         AND SYSDATE BETWEEN gcm.start_date_active
                         AND NVL (gcm.end_date_active,
                                  TO_DATE ('01/01/2099', 'DD/MM/YYYY')
                                 )
         AND fv.lookup_type = 'INTG_LEGACY_TARGET_COA_MAPPING'
         AND fv.LANGUAGE = 'US'
         AND fv.attribute8 = x_source
         AND fv.attribute9 = x_component_name
         AND fv.attribute10 = gcm.name
         AND fv.enabled_flag = 'Y'
         --AND fv.lookup_code = x_source
         --AND fv.meaning = gcm.NAME
         AND gcm.coa_mapping_id = gcf.coa_mapping_id
         AND NVL (x_segment1, 'XXXX') BETWEEN NVL (gcf.segment1_low, 'XXXX')
                                          AND NVL (gcf.segment1_high, 'XXXX')
         AND NVL (x_segment2, 'XXXX') BETWEEN NVL (gcf.segment2_low, 'XXXX')
                                          AND NVL (gcf.segment2_high, 'XXXX')
         AND NVL (x_segment3, 'XXXX') BETWEEN NVL (gcf.segment3_low, 'XXXX')
                                          AND NVL (gcf.segment3_high, 'XXXX')
         AND NVL (x_segment4, 'XXXX') BETWEEN NVL (gcf.segment4_low, 'XXXX')
                                          AND NVL (gcf.segment4_high, 'XXXX')
         AND NVL (x_segment5, 'XXXX') BETWEEN NVL (gcf.segment5_low, 'XXXX')
                                          AND NVL (gcf.segment5_high, 'XXXX')
         AND NVL (x_segment6, 'XXXX') BETWEEN NVL (gcf.segment6_low, 'XXXX')
                                          AND NVL (gcf.segment6_high, 'XXXX')
         AND NVL (x_segment7, 'XXXX') BETWEEN NVL (gcf.segment7_low, 'XXXX')
                                          AND NVL (gcf.segment7_high, 'XXXX')
         AND NVL (x_segment8, 'XXXX') BETWEEN NVL (gcf.segment8_low, 'XXXX')
                                          AND NVL (gcf.segment8_high, 'XXXX')
         AND gcc.code_combination_id = gcf.to_code_combination_id;

      RETURN x_ccid;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END;

END xx_gl_cons_ffield_load_pkg;
/


GRANT EXECUTE ON APPS.XX_GL_CONS_FFIELD_LOAD_PKG TO INTG_XX_NONHR_RO;
