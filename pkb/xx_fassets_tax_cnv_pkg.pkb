DROP PACKAGE BODY APPS.XX_FASSETS_TAX_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_FASSETS_TAX_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 20-Mar-2012
 File Name      : XXFASSTTAXCNV.pkb
 Description    : This script creates the body of the package XX_FA_ASST_CNV_PKG
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
 20-Sep-10   IBM Development Team   Initial development.
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
            DELETE FROM xx_fa_tax_int_piface
                  WHERE batch_id = g_batch_id;

            UPDATE xx_fa_tax_int_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_fa_tax_int_piface
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
            UPDATE xx_fa_tax_int_stg
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
         UPDATE xx_fa_tax_int_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_fa_tax_int_piface
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_fa_tax_int_piface
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_fa_tax_int_piface
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
         UPDATE xx_fa_tax_int_piface
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
         UPDATE xx_fa_tax_int_piface
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
         UPDATE xx_fa_tax_int_piface
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

      UPDATE xx_fa_tax_int_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_updated_by,
             last_update_login = x_last_update_login
       WHERE batch_id = g_batch_id
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
      p_restart_flag        IN              VARCHAR2,
      p_override_flag       IN              VARCHAR2,
      p_tax_book            IN              VARCHAR2,
      p_validate_and_load   IN              VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_pre_std_hdr_table   g_xx_faasst_tax_piface_tab;
      x_sqlerrm             VARCHAR2 (2000);

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_intg_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   asset_number, book_type_code, adjusted_rate, basic_rate,
                  bonus_rule, ceiling_name, COST, date_placed_in_service,
                  depreciate_flag, deprn_method_code, deprn_reserve,
                  itc_amount_id, life_in_months, original_cost,
                  production_capacity, prorate_convention_code,
                  salvage_value, ytd_deprn, accumulated_deprn,
                  posting_status, tax_request_id, short_fiscal_year_flag,
                  conversion_date, original_deprn_start_date,
                  amortize_nbv_flag, amortization_start_date,
                  fully_rsvd_revals_counter, reval_amortization_basis,
                  reval_ceiling, reval_reserve, unrevalued_cost,
                  ytd_reval_deprn_expense, transaction_name, attribute1,
                  attribute2, attribute3, attribute4, attribute5, attribute6,
                  attribute7, attribute8, attribute9, attribute10,
                  attribute11, attribute12, attribute13, attribute14,
                  attribute15, attribute_category_code, global_attribute1,
                  global_attribute2, global_attribute3, global_attribute4,
                  global_attribute5, global_attribute6, global_attribute7,
                  global_attribute8, global_attribute9, global_attribute10,
                  global_attribute11, global_attribute12, global_attribute13,
                  global_attribute14, global_attribute15, global_attribute16,
                  global_attribute17, global_attribute18, global_attribute19,
                  global_attribute20, global_attribute_category,

                  --description                    ,
                  group_asset_id, batch_id, record_number, process_code,
                  ERROR_CODE, creation_date, created_by, last_update_date,
                  last_updated_by, last_update_login, request_id,
                  program_application_id, program_id, program_update_date
             FROM xx_fa_tax_int_piface
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
         p_conv_pre_std_hdr_rec   IN OUT   g_xx_faasst_tax_piface_rec,
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
               xx_fassets_tax_val_pkg.find_max
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

         UPDATE xx_fa_tax_int_piface
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
         p_cnv_pre_std_hdr_table   IN   g_xx_faasst_tax_piface_tab
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
            UPDATE xx_fa_tax_int_piface
               SET asset_number = p_cnv_pre_std_hdr_table (indx).asset_number,
                   book_type_code =
                                 p_cnv_pre_std_hdr_table (indx).book_type_code,
                   adjusted_rate =
                                  p_cnv_pre_std_hdr_table (indx).adjusted_rate,
                   basic_rate = p_cnv_pre_std_hdr_table (indx).basic_rate,
                   bonus_rule = p_cnv_pre_std_hdr_table (indx).bonus_rule,
                   ceiling_name = p_cnv_pre_std_hdr_table (indx).ceiling_name,
                   COST = p_cnv_pre_std_hdr_table (indx).COST,
                   date_placed_in_service =
                         p_cnv_pre_std_hdr_table (indx).date_placed_in_service,
                   depreciate_flag =
                                p_cnv_pre_std_hdr_table (indx).depreciate_flag,
                   deprn_method_code =
                              p_cnv_pre_std_hdr_table (indx).deprn_method_code,
                   deprn_reserve =
                                  p_cnv_pre_std_hdr_table (indx).deprn_reserve,
                   itc_amount_id =
                                  p_cnv_pre_std_hdr_table (indx).itc_amount_id,
                   life_in_months =
                                 p_cnv_pre_std_hdr_table (indx).life_in_months,
                   original_cost =
                                  p_cnv_pre_std_hdr_table (indx).original_cost,
                   production_capacity =
                            p_cnv_pre_std_hdr_table (indx).production_capacity,
                   prorate_convention_code =
                        p_cnv_pre_std_hdr_table (indx).prorate_convention_code,
                   salvage_value =
                                  p_cnv_pre_std_hdr_table (indx).salvage_value,
                   ytd_deprn = p_cnv_pre_std_hdr_table (indx).ytd_deprn,
                   accumulated_deprn =
                              p_cnv_pre_std_hdr_table (indx).accumulated_deprn,
                   posting_status =
                                 p_cnv_pre_std_hdr_table (indx).posting_status,
                   tax_request_id =
                                 p_cnv_pre_std_hdr_table (indx).tax_request_id,
                   short_fiscal_year_flag =
                         p_cnv_pre_std_hdr_table (indx).short_fiscal_year_flag,
                   conversion_date =
                                p_cnv_pre_std_hdr_table (indx).conversion_date,
                   original_deprn_start_date =
                      p_cnv_pre_std_hdr_table (indx).original_deprn_start_date,
                   amortize_nbv_flag =
                              p_cnv_pre_std_hdr_table (indx).amortize_nbv_flag,
                   amortization_start_date =
                        p_cnv_pre_std_hdr_table (indx).amortization_start_date,
                   fully_rsvd_revals_counter =
                      p_cnv_pre_std_hdr_table (indx).fully_rsvd_revals_counter,
                   reval_amortization_basis =
                       p_cnv_pre_std_hdr_table (indx).reval_amortization_basis,
                   reval_ceiling =
                                  p_cnv_pre_std_hdr_table (indx).reval_ceiling,
                   reval_reserve =
                                  p_cnv_pre_std_hdr_table (indx).reval_reserve,
                   unrevalued_cost =
                                p_cnv_pre_std_hdr_table (indx).unrevalued_cost,
                   ytd_reval_deprn_expense =
                        p_cnv_pre_std_hdr_table (indx).ytd_reval_deprn_expense,
                   transaction_name =
                               p_cnv_pre_std_hdr_table (indx).transaction_name,
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
                   attribute11 = p_cnv_pre_std_hdr_table (indx).attribute11,
                   attribute12 = p_cnv_pre_std_hdr_table (indx).attribute12,
                   attribute13 = p_cnv_pre_std_hdr_table (indx).attribute13,
                   attribute14 = p_cnv_pre_std_hdr_table (indx).attribute14,
                   attribute15 = p_cnv_pre_std_hdr_table (indx).attribute15,
                   attribute_category_code =
                        p_cnv_pre_std_hdr_table (indx).attribute_category_code,
                   global_attribute1 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute1,
                   global_attribute2 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute2,
                   global_attribute3 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute3,
                   global_attribute4 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute4,
                   global_attribute5 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute5,
                   global_attribute6 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute6,
                   global_attribute7 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute7,
                   global_attribute8 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute8,
                   global_attribute9 =
                              p_cnv_pre_std_hdr_table (indx).global_attribute9,
                   global_attribute10 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute10,
                   global_attribute11 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute11,
                   global_attribute12 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute12,
                   global_attribute13 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute13,
                   global_attribute14 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute14,
                   global_attribute15 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute15,
                   global_attribute16 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute16,
                   global_attribute17 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute17,
                   global_attribute18 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute18,
                   global_attribute19 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute19,
                   global_attribute20 =
                             p_cnv_pre_std_hdr_table (indx).global_attribute20,
                   global_attribute_category =
                      p_cnv_pre_std_hdr_table (indx).global_attribute_category,
                   --description                =p_cnv_pre_std_hdr_table(indx).description            ,
                   group_asset_id =
                                 p_cnv_pre_std_hdr_table (indx).group_asset_id,
                   --batch_id                    =p_cnv_pre_std_hdr_table(indx).batch_id                ,
                   --record_number                    =p_cnv_pre_std_hdr_table(indx).record_number            ,
                   process_code = p_cnv_pre_std_hdr_table (indx).process_code,
                   ERROR_CODE = p_cnv_pre_std_hdr_table (indx).ERROR_CODE,
                   creation_date =
                                  p_cnv_pre_std_hdr_table (indx).creation_date,
                   created_by = p_cnv_pre_std_hdr_table (indx).created_by,
                   last_update_date =
                               p_cnv_pre_std_hdr_table (indx).last_update_date,
                   last_updated_by =
                                p_cnv_pre_std_hdr_table (indx).last_updated_by,
                   last_update_login =
                              p_cnv_pre_std_hdr_table (indx).last_update_login,
                   request_id = p_cnv_pre_std_hdr_table (indx).request_id,
                   program_application_id =
                         p_cnv_pre_std_hdr_table (indx).program_application_id,
                   program_id = p_cnv_pre_std_hdr_table (indx).program_id,
                   program_update_date =
                            p_cnv_pre_std_hdr_table (indx).program_update_date
             WHERE record_number =
                                  p_cnv_pre_std_hdr_table (indx).record_number
               AND batch_id = g_batch_id;
         EXCEPTION WHEN OTHERS THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'update_pre_interface_records failed ->' || sqlerrm);
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
         x_creation_date           DATE                       := SYSDATE;
         x_created_by              NUMBER               := fnd_global.user_id;
         x_last_update_date        DATE                       := SYSDATE;
         x_last_updated_by         NUMBER               := fnd_global.user_id;
         x_last_update_login       NUMBER         := fnd_global.conc_login_id;
         --fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         x_cnv_pre_std_hdr_table   g_xx_faasst_tax_piface_tab;
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
         INSERT INTO xx_fa_tax_int_piface
                     (asset_number, book_type_code, adjusted_rate, basic_rate,
                      bonus_rule, ceiling_name, COST, date_placed_in_service,
                      depreciate_flag, deprn_method_code, deprn_reserve,
                      itc_amount_id, life_in_months, original_cost,
                      production_capacity, prorate_convention_code,
                      salvage_value, ytd_deprn, accumulated_deprn,
                      posting_status, tax_request_id, short_fiscal_year_flag,
                      conversion_date, original_deprn_start_date,
                      amortize_nbv_flag, amortization_start_date,
                      fully_rsvd_revals_counter, reval_amortization_basis,
                      reval_ceiling, reval_reserve, unrevalued_cost,
                      ytd_reval_deprn_expense, transaction_name, attribute1,
                      attribute2, attribute3, attribute4, attribute5,
                      attribute6, attribute7, attribute8, attribute9,
                      attribute10, attribute11, attribute12, attribute13,
                      attribute14, attribute15, attribute_category_code,
                      global_attribute1, global_attribute2, global_attribute3,
                      global_attribute4, global_attribute5, global_attribute6,
                      global_attribute7, global_attribute8, global_attribute9,
                      global_attribute10, global_attribute11,
                      global_attribute12, global_attribute13,
                      global_attribute14, global_attribute15,
                      global_attribute16, global_attribute17,
                      global_attribute18, global_attribute19,
                      global_attribute20, global_attribute_category,

                      --description            ,
                      group_asset_id, batch_id, record_number, process_code,
                      ERROR_CODE, creation_date, created_by, last_update_date,
                      last_updated_by, last_update_login, request_id,
                      program_application_id, program_id, program_update_date)
            SELECT asset_number, p_tax_book, adjusted_rate, basic_rate,
                   bonus_rule, ceiling_name, COST, date_placed_in_service,
                   'YES',
                         -- depreciate_flag
                         deprn_method_code,
                   CASE
                      WHEN TO_NUMBER (TO_CHAR (stg.date_placed_in_service,
                                               'YYYY'
                                              )
                                     ) >= 2012
                         THEN   TO_NUMBER (stg.accumulated_deprn)
                              - TO_NUMBER (stg.global_attribute10)
                      ELSE TO_NUMBER (stg.accumulated_deprn)
                   END,
                   itc_amount_id, life_in_months, original_cost,
                   production_capacity, prorate_convention_code,
                   salvage_value, ytd_deprn, accumulated_deprn,
                                                                -- total accumulated deprn
                   'POST',
                          -- posting status
                          tax_request_id, short_fiscal_year_flag,
                   conversion_date, original_deprn_start_date,
                   amortize_nbv_flag, amortization_start_date,
                   fully_rsvd_revals_counter, reval_amortization_basis,
                   reval_ceiling, reval_reserve, unrevalued_cost,
                   ytd_reval_deprn_expense, transaction_name, attribute1,
                   attribute2, attribute3, attribute4, attribute5, attribute6,
                   attribute7, attribute8, attribute9, attribute10,
                   attribute11, attribute12, attribute13, attribute14,
                   attribute15, attribute_category_code, global_attribute1,
                   global_attribute2, global_attribute3, global_attribute4,
                   global_attribute5, global_attribute6, global_attribute7,
                   global_attribute8, global_attribute9, global_attribute10,
                   global_attribute11, global_attribute12, global_attribute13,
                   global_attribute14, global_attribute15, global_attribute16,
                   global_attribute17, global_attribute18, global_attribute19,
                   global_attribute20, global_attribute_category,

                   --description            ,
                   group_asset_id, batch_id, record_number, process_code,
                   ERROR_CODE, creation_date, created_by, last_update_date,
                   last_updated_by, last_update_login, request_id,
                   program_application_id, program_id, program_update_date
              FROM xx_fa_tax_int_stg stg
             WHERE batch_id = g_batch_id
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
         x_assest_ccid     NUMBER;
         x_loc_id          NUMBER;
         x_category_id     NUMBER;
      BEGIN
         --BEGIN
            -- Change the logic to whatever needs to be done
            -- with valid records in the pre-interface tables
            -- either call the appropriate API to process the data
            -- or to insert into an interface table.
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Before Insert into FA_TAX_INTERFACE>>'
                                 );

            INSERT INTO fa_tax_interface
                        (asset_number, book_type_code, adjusted_rate,
                         basic_rate, bonus_rule, ceiling_name, COST,
                         date_placed_in_service, depreciate_flag,
                         deprn_method_code, deprn_reserve, itc_amount_id,
                         life_in_months, original_cost, production_capacity,
                         prorate_convention_code, salvage_value, ytd_deprn,

                         --accumulated_deprn                ,
                         posting_status, tax_request_id,
                         short_fiscal_year_flag, conversion_date,
                         original_deprn_start_date, amortize_nbv_flag,
                         amortization_start_date, fully_rsvd_revals_counter,
                         reval_amortization_basis, reval_ceiling,
                         reval_reserve, unrevalued_cost,
                         ytd_reval_deprn_expense, transaction_name,

                         --attribute1                 ,
                         attribute2, attribute3, attribute4, attribute5,
                         attribute6, attribute7, attribute8, attribute9,
                         attribute10, attribute11, attribute12, attribute13,
                         attribute14, attribute15, attribute_category_code,
                         global_attribute1, global_attribute2,
                         global_attribute3, global_attribute4,
                         global_attribute5, global_attribute6,
                         global_attribute7, global_attribute8,
                         global_attribute9, global_attribute10,
                         global_attribute11, global_attribute12,
                         global_attribute13, global_attribute14,
                         global_attribute15, global_attribute16,
                         global_attribute17, global_attribute18,
                         global_attribute19, global_attribute20,
                         global_attribute_category, group_asset_id,
                         creation_date, created_by, last_update_date,
                         last_updated_by, last_update_login)
               SELECT asset_number, book_type_code, adjusted_rate, basic_rate,
                      bonus_rule, ceiling_name, COST, date_placed_in_service,
                      depreciate_flag, deprn_method_code, deprn_reserve,
                      itc_amount_id, life_in_months, original_cost,
                      production_capacity, prorate_convention_code,
                      salvage_value, ytd_deprn,
                                               --accumulated_deprn                ,
                                               posting_status, tax_request_id,
                      short_fiscal_year_flag, conversion_date,
                      original_deprn_start_date, amortize_nbv_flag,
                      amortization_start_date, fully_rsvd_revals_counter,
                      reval_amortization_basis, reval_ceiling, reval_reserve,
                      unrevalued_cost, ytd_reval_deprn_expense,
                      transaction_name,
                                       --attribute1                 ,
                                       attribute2, attribute3, attribute4,
                      attribute5, attribute6, attribute7, attribute8,
                      attribute9, attribute10, attribute11, attribute12,
                      attribute13, attribute14, attribute15,
                      attribute_category_code, global_attribute1,
                      global_attribute2, global_attribute3, global_attribute4,
                      global_attribute5, global_attribute6, global_attribute7,
                      global_attribute8, global_attribute9,
                      global_attribute10, global_attribute11,
                      global_attribute12, global_attribute13,
                      global_attribute14, global_attribute15,
                      global_attribute16, global_attribute17,
                      global_attribute18, global_attribute19,
                      global_attribute20, global_attribute_category,
                      group_asset_id, creation_date, created_by,
                      last_update_date, last_updated_by, last_update_login
                 FROM xx_fa_tax_int_piface
                WHERE batch_id = g_batch_id
                  AND request_id = xx_emf_pkg.g_request_id
                  AND ERROR_CODE IN
                         (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
                  AND process_code = xx_emf_cn_pkg.cn_postval
                  AND asset_number IS NOT NULL;

            RETURN x_return_status;
            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_sqlerrm := SUBSTR (SQLERRM, 1, 800);
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
                --
               /* UPDATE xx_fa_mass_add_piface
                   SET error_code=xx_emf_cn_pkg.CN_REC_ERR
                 WHERE batch_id= G_BATCH_ID
                   AND record_number= xx_asst_hdr_rec.record_number;
                    COMMIT;*/
               xx_emf_pkg.error
                          (p_severity                 => xx_emf_cn_pkg.cn_medium,
                           p_category                 => xx_emf_cn_pkg.cn_tech_error,
                           p_error_text               =>    'Err Main-ASSTTAX Excp1'
                                                         || x_sqlerrm,
                           p_record_identifier_1      => NULL,
                           p_record_identifier_2      => NULL,
                           p_record_identifier_3      => 'Err in Asset Tax Insert'
                          );
               RETURN x_return_status;
         END;
      /* Added by Rohit Jain*/
      EXCEPTION
         WHEN OTHERS
         THEN
            x_sqlerrm := SQLERRM;
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_high,
                              p_category                 => xx_emf_cn_pkg.cn_tech_error,
                              p_error_text               =>    'Error in Main-Insr Exp2'
                                                            || x_sqlerrm,
                              p_record_identifier_3      => 'Process Main Insert'
                             );
            RETURN x_error_code;
      END process_data;

-------------------------------------------------------------------------
-----------< update_record_count >---------------------------------------
-------------------------------------------------------------------------
      PROCEDURE update_record_count (p_validate_and_load IN VARCHAR2)
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_fa_tax_int_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT SUM (a.error_count) error_count
              FROM (SELECT COUNT (1) error_count
                      FROM xx_fa_tax_int_stg
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                    UNION ALL
                    SELECT COUNT (1) error_count
                      FROM xx_fa_tax_int_piface
                     WHERE batch_id = g_batch_id
                       AND request_id = xx_emf_pkg.g_request_id
                       AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err) a;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_fa_tax_int_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_fa_tax_int_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

         CURSOR c_get_success_valid_cnt
         IS
            SELECT COUNT (1) success_count
              FROM xx_fa_tax_int_piface
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
              FROM xx_fa_tax_int_stg
             WHERE batch_id = g_batch_id
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
              FROM xx_fa_tax_int_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_fa_tax_int_piface
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_fa_tax_int_piface
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
                            'Main:Param - p_tax_book ' || p_tax_book
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
          --xx_fa_assets_val_pkg.pre_validations(x_pre_std_hdr_table (i));
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
                  xx_fassets_tax_val_pkg.data_validations
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
                  ------Comment by venu for Error
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
                      p_record_identifier_1      => x_pre_std_hdr_table (i).asset_number,
                      p_record_identifier_2      =>    x_pre_std_hdr_table (i).asset_number
                                                    || ', '
                                                    || x_pre_std_hdr_table (i).asset_number,
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
                  xx_fassets_tax_val_pkg.data_derivations
                                                      (x_pre_std_hdr_table (i)
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
                      p_record_identifier_1      => x_pre_std_hdr_table (i).asset_number,
                      p_record_identifier_2      =>    x_pre_std_hdr_table (i).asset_number
                                                    || ', '
                                                    || x_pre_std_hdr_table (i).asset_number,
                      p_record_identifier_3      => 'Stage 3:Data Derivation'
                     );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count in der'
                               || x_pre_std_hdr_table.COUNT
                              );
         --------comment by venu for error
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
      x_error_code := xx_fassets_tax_val_pkg.post_validations();
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
END xx_fassets_tax_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_FASSETS_TAX_CNV_PKG TO INTG_XX_NONHR_RO;
