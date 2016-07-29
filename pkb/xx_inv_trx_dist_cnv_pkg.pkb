DROP PACKAGE BODY APPS.XX_INV_TRX_DIST_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_TRX_DIST_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 24-FEB-2012
 File Name     : XXARTRXDISTCONV.pkb
 Description   : This script creates the body of the package
         xx_inv_trx_dist_cnv_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 24-FEB-2012 Sharath Babu        Initial Development
 21-MAY-2012 Sharath Babu        Commented condition in update_record_count
                                 to display sucess cnt with validate only mode
*/
----------------------------------------------------------------------
    -- Do not change anything in these procedures mark_records_for_processing and set_cnv_env
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
            DELETE FROM xx_ar_inv_trx_dist_pre_int
                  WHERE batch_id = g_batch_id;

            UPDATE xx_ar_inv_trx_dist_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;
         ELSE
            UPDATE xx_ar_inv_trx_dist_pre_int
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.cn_success,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;
         END IF;

         DELETE FROM ra_interface_distributions_all
               WHERE attribute11 = g_batch_id;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_ar_inv_trx_dist_stg
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
         UPDATE xx_ar_inv_trx_dist_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_ar_inv_trx_dist_pre_int
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.cn_rec_warn,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_ar_inv_trx_dist_pre_int
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.cn_rec_warn,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_ar_inv_trx_dist_pre_int
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
         UPDATE xx_ar_inv_trx_dist_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_valid
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_derive
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 4 Post Validation Stage
         UPDATE xx_ar_inv_trx_dist_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_derive
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_postval
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 5 Process Data Stage
         UPDATE xx_ar_inv_trx_dist_pre_int
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_success,
                process_code = xx_emf_cn_pkg.cn_postval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err);
      END IF;

      COMMIT;
   END mark_records_for_processing;

   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (
      p_error_code      VARCHAR2,
      p_record_number   NUMBER
   )
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_by       NUMBER := fnd_global.user_id;
      x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      x_error_code           NUMBER := xx_emf_cn_pkg.cn_success;
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Inside Update Staging Records'
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_record_number = '
                            || p_record_number
                            || ' error_code = '
                            || p_error_code
                           );

      UPDATE xx_ar_inv_trx_dist_stg
         SET process_code = g_stage,
             error_code = DECODE (error_code, NULL, p_error_code, error_code),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_update_by,
             last_update_login = x_last_updated_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new
         AND record_number = p_record_number;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Error While Updating Staging table = '
                               || SQLERRM
                              );
         xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                           xx_emf_cn_pkg.cn_tech_error,
                           xx_emf_cn_pkg.cn_exp_unhand
                          );
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
   END update_staging_records;

   PROCEDURE update_pre_interface_records (
      p_trx_pre_iface_tab   IN   g_xx_ar_cnv_pre_std_tab_type
   )
   IS
      x_error_code           NUMBER := xx_emf_cn_pkg.cn_success;
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_by       NUMBER := fnd_global.user_id;
      x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF p_trx_pre_iface_tab.COUNT > 0
      THEN
         FOR indx IN 1 .. p_trx_pre_iface_tab.COUNT
         LOOP
            xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            ' update_pre_interface_records process_code for '
                         || p_trx_pre_iface_tab (indx).record_number
                         || ' is '
                         || p_trx_pre_iface_tab (indx).process_code
                        );

                          UPDATE xx_ar_inv_trx_dist_pre_int
			     SET process_code      = p_trx_pre_iface_tab(indx).process_code
				,error_code        = p_trx_pre_iface_tab(indx).error_code
				,last_updated_by   = x_last_update_by
				,last_update_date  = x_last_update_date
				,last_update_login = x_last_updated_login
				,org_id            = p_trx_pre_iface_tab(indx).org_id
				,code_combination_id = p_trx_pre_iface_tab(indx).code_combination_id
				,operating_unit_name = p_trx_pre_iface_tab(indx).operating_unit_name
				,account_class      = p_trx_pre_iface_tab(indx).account_class
				,segment1  = p_trx_pre_iface_tab(indx).segment1
				,segment2  = p_trx_pre_iface_tab(indx).segment2
				,segment3  = p_trx_pre_iface_tab(indx).segment3
				,segment4  = p_trx_pre_iface_tab(indx).segment4
				,segment5  = p_trx_pre_iface_tab(indx).segment5
				,segment6  = p_trx_pre_iface_tab(indx).segment6
				,segment7  = p_trx_pre_iface_tab(indx).segment7
				,segment8  = p_trx_pre_iface_tab(indx).segment8
				,segment9  = p_trx_pre_iface_tab(indx).segment9
			   WHERE batch_id=g_batch_id
			     AND record_number =p_trx_pre_iface_tab(indx).record_number;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Updated for batch g_batch_id ='
                                  || g_batch_id
                                 );
         END LOOP;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log
                       (xx_emf_cn_pkg.cn_low,
                           'Error while updating xx_ar_inv_trx_dist_pre_int '
                        || SQLERRM
                       );
   END update_pre_interface_records;

   FUNCTION process_data
      RETURN NUMBER
   IS
      x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
      x_creation_date       DATE   := SYSDATE;
      x_created_by          NUMBER := fnd_global.user_id;
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
   BEGIN
      INSERT INTO ra_interface_distributions_all
        	      (
        		 --interface_distribution_id
        		 interface_line_id
        		,interface_line_context
        		,interface_line_attribute1
        		,interface_line_attribute2
        		,interface_line_attribute3
        		,interface_line_attribute4
        		,interface_line_attribute5
        		,interface_line_attribute6
        		,interface_line_attribute7
        		,interface_line_attribute8
        		,account_class
        		,amount
        		,percent
        		,interface_status
        		--,request_id
        		,code_combination_id
        		,segment1
        		,segment2
        		,segment3
        		,segment4
        		,segment5
        		,segment6
        		,segment7
        		,segment8
        		,segment9
        		,segment10
        		,segment11
        		,segment12
        		,segment13
        		,segment14
        		,segment15
        		,segment16
        		,segment17
        		,segment18
        		,segment19
        		,segment20
        		,segment21
        		,segment22
        		,segment23
        		,segment24
        		,segment25
        		,segment26
        		,segment27
        		,segment28
        		,segment29
        		,segment30
        		,comments
        		,attribute_category
        		,attribute1
        		,attribute2
        		,attribute3
        		,attribute4
        		,attribute5
        		,attribute6
        		,attribute7
        		,attribute8
        		,attribute9
        		,attribute10
        		,attribute11
        		,attribute12
        		,attribute13
        		,attribute14
        		,attribute15
        		,acctd_amount
        		,interface_line_attribute10
        		,interface_line_attribute11
        		,interface_line_attribute12
        		,interface_line_attribute13
        		,interface_line_attribute14
        		,interface_line_attribute15
        		,interface_line_attribute9
        		,created_by
        		,creation_date
        		,last_updated_by
        		,last_update_date
        		,last_update_login
        		,org_id
        		,interim_tax_ccid
        		,interim_tax_segment1
        		,interim_tax_segment2
        		,interim_tax_segment3
        		,interim_tax_segment4
        		,interim_tax_segment5
        		,interim_tax_segment6
        		,interim_tax_segment7
        		,interim_tax_segment8
        		,interim_tax_segment9
        		,interim_tax_segment10
        		,interim_tax_segment11
        		,interim_tax_segment12
        		,interim_tax_segment13
        		,interim_tax_segment14
        		,interim_tax_segment15
        		,interim_tax_segment16
        		,interim_tax_segment17
        		,interim_tax_segment18
        		,interim_tax_segment19
        		,interim_tax_segment20
        		,interim_tax_segment21
        		,interim_tax_segment22
        		,interim_tax_segment23
        		,interim_tax_segment24
        		,interim_tax_segment25
        		,interim_tax_segment26
        		,interim_tax_segment27
        		,interim_tax_segment28
        		,interim_tax_segment29
        		,interim_tax_segment30
        	      )
	      SELECT
		       --interface_distribution_id
		       interface_line_id
		      ,interface_line_context
		      ,interface_line_attribute1
		      ,interface_line_attribute2
		      ,interface_line_attribute3
		      ,interface_line_attribute4
		      ,interface_line_attribute5
		      ,interface_line_attribute6
		      ,interface_line_attribute7
		      ,interface_line_attribute8
		      ,account_class
		      ,amount
		      ,percent
		      ,interface_status
		      --,request_id
		      ,code_combination_id
		      ,segment1
		      ,segment2
		      ,segment3
		      ,segment4
		      ,segment5
		      ,segment6
		      ,segment7
		      ,segment8
		      ,segment9
		      ,segment10
		      ,segment11
		      ,segment12
		      ,segment13
		      ,segment14
		      ,segment15
		      ,segment16
		      ,segment17
		      ,segment18
		      ,segment19
		      ,segment20
		      ,segment21
		      ,segment22
		      ,segment23
		      ,segment24
		      ,segment25
		      ,segment26
		      ,segment27
		      ,segment28
		      ,segment29
		      ,segment30
		      ,comments
		      ,attribute_category
		      ,attribute1
		      ,attribute2
		      ,attribute3
		      ,attribute4
		      ,attribute5
		      ,attribute6
		      ,attribute7
		      ,attribute8
		      ,attribute9
		      ,attribute10
		      ,batch_id       --attribute11
		      ,attribute12
		      ,attribute13
		      ,attribute14
		      ,attribute15
		      ,acctd_amount
		      ,interface_line_attribute10
		      ,interface_line_attribute11
		      ,interface_line_attribute12
		      ,interface_line_attribute13
		      ,interface_line_attribute14
		      ,interface_line_attribute15
		      ,interface_line_attribute9
		      ,x_created_by
		      ,x_creation_date
		      ,x_last_updated_by
		      ,x_last_update_date
		      ,x_last_update_login
		      ,org_id
		      ,interim_tax_ccid
		      ,interim_tax_segment1
		      ,interim_tax_segment2
		      ,interim_tax_segment3
		      ,interim_tax_segment4
		      ,interim_tax_segment5
		      ,interim_tax_segment6
		      ,interim_tax_segment7
		      ,interim_tax_segment8
		      ,interim_tax_segment9
		      ,interim_tax_segment10
		      ,interim_tax_segment11
		      ,interim_tax_segment12
		      ,interim_tax_segment13
		      ,interim_tax_segment14
		      ,interim_tax_segment15
		      ,interim_tax_segment16
		      ,interim_tax_segment17
		      ,interim_tax_segment18
		      ,interim_tax_segment19
		      ,interim_tax_segment20
		      ,interim_tax_segment21
		      ,interim_tax_segment22
		      ,interim_tax_segment23
		      ,interim_tax_segment24
		      ,interim_tax_segment25
		      ,interim_tax_segment26
		      ,interim_tax_segment27
		      ,interim_tax_segment28
		      ,interim_tax_segment29
              ,interim_tax_segment30
         FROM  xx_ar_inv_trx_dist_pre_int
        WHERE  batch_id = G_BATCH_ID
         AND   request_id = xx_emf_pkg.G_REQUEST_ID
         AND   error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         AND   process_code = xx_emf_cn_pkg.CN_POSTVAL;

      COMMIT;
      RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                               'Error in Process_Data = ' || SQLERRM
                              );
   END process_data;

   PROCEDURE mark_records_complete (p_process_code VARCHAR2)
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_by       NUMBER := fnd_global.user_id;
      x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_ar_inv_trx_dist_pre_int
         SET process_code = g_stage,
             ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.cn_success),
             last_updated_by = x_last_update_by,
             last_update_date = x_last_update_date,
             last_update_login = x_last_updated_login
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
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                               'Error in mark_records_complete = ' || SQLERRM
                              );
   END mark_records_complete;

   PROCEDURE main (
      errbuf                OUT      VARCHAR2,
      retcode               OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2
   )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      x_ar_trx_stg_table    g_xx_ar_cnv_stg_tab_type;
      x_pre_std_hdr_table   g_xx_ar_cnv_pre_std_tab_type;

      -- Cursor to fetch distribution staging data
      CURSOR c_xx_intg_trx_cnv (cp_process_status VARCHAR2)
      IS
         SELECT   diststg.*
             FROM xx_ar_inv_trx_dist_stg diststg
            WHERE diststg.batch_id = g_batch_id
              AND diststg.request_id = xx_emf_pkg.g_request_id
              AND diststg.process_code = cp_process_status
              AND diststg.ERROR_CODE IS NULL
         ORDER BY diststg.record_number;

      -- Cursor to distribution pre interface data
      CURSOR c_xx_intg_pre_std_hdr (cp_process_status VARCHAR2)
      IS
         SELECT   distpre.*
             FROM xx_ar_inv_trx_dist_pre_int distpre
            WHERE distpre.batch_id = g_batch_id
              AND distpre.request_id = xx_emf_pkg.g_request_id
              AND distpre.process_code = cp_process_status
              AND distpre.ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY distpre.record_number;

      PROCEDURE update_master_status (
         p_trx_pre_iface_rec   IN OUT   g_xx_ar_cnv_pre_std_rec_type,
         p_error_code          IN       VARCHAR2
      )
      IS
      BEGIN
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Inside update_master_status  p_error_code ='
                             || p_error_code
                            );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'G_STAGE =' || g_stage);

         IF p_error_code IN
                         (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_trx_pre_iface_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_trx_pre_iface_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max
                                        (p_error_code,
                                         NVL (p_trx_pre_iface_rec.ERROR_CODE,
                                              xx_emf_cn_pkg.cn_success
                                             )
                                        );
         END IF;

         p_trx_pre_iface_rec.process_code := g_stage;
      END update_master_status;

      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date       DATE   := SYSDATE;
         x_created_by          NUMBER := fnd_global.user_id;
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, xx_emf_cn_pkg.cn_preval);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, xx_emf_pkg.g_request_id);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, g_batch_id);

         INSERT INTO xx_ar_inv_trx_dist_pre_int
                       	(
        			 amount
        			,percent
        			,segment1
        			,segment2
        			,segment3
        			,segment4
        			,segment5
        			,segment6
        			,segment7
        			,segment8
        			,segment9
        			,segment10
        			,comments
        			,account_class
        			,attribute_category
        			,attribute1
        			,attribute2
        			,attribute3
        			,attribute4
        			,attribute5
        			,attribute6
        			,attribute7
        			,attribute8
        			,attribute9
        			,attribute10
        			,acctd_amount
        			,interface_line_context
        			,interface_line_attribute1
        			,interface_line_attribute2
        			,interface_line_attribute3
        			,interface_line_attribute4
        			,interface_line_attribute5
        			,interface_line_attribute6
        			,interface_line_attribute7
        			,interface_line_attribute8
        			,interface_line_attribute9
        			,interface_line_attribute10
        			,operating_unit_name
        			,interim_tax_segment1
        			,interim_tax_segment2
        			,interim_tax_segment3
        			,interim_tax_segment4
        			,interim_tax_segment5
        			,interim_tax_segment6
        			,interim_tax_segment7
        			,interim_tax_segment8
        			,interim_tax_segment9
        			,interim_tax_segment10
        			,batch_id
        			,record_number
        			,process_code
        			,error_code
        			,created_by
        			,creation_date
        			,last_update_date
        			,last_updated_by
        			,last_update_login
        			,request_id
        			,program_application_id
        			,program_id
        			,program_update_date
                                  )
        		    SELECT
        			 amount
        			,percent
        			,segment1
        			,segment2
        			,segment3
        			,segment4
        			,segment5
        			,segment6
        			,segment7
        			,segment8
        			,segment9
        			,segment10
        			,comments
        			,account_class
        			,attribute_category
        			,attribute1
        			,attribute2
        			,attribute3
        			,attribute4
        			,attribute5
        			,attribute6
        			,attribute7
        			,attribute8
        			,attribute9
        			,attribute10
        			,acctd_amount
        			,interface_line_context
        			,interface_line_attribute1
        			,interface_line_attribute2
        			,interface_line_attribute3
        			,interface_line_attribute4
        			,interface_line_attribute5
        			,interface_line_attribute6
        			,interface_line_attribute7
        			,interface_line_attribute8
        			,interface_line_attribute9
        			,interface_line_attribute10
        			,operating_unit_name
        			,interim_tax_segment1
        			,interim_tax_segment2
        			,interim_tax_segment3
        			,interim_tax_segment4
        			,interim_tax_segment5
        			,interim_tax_segment6
        			,interim_tax_segment7
        			,interim_tax_segment8
        			,interim_tax_segment9
        			,interim_tax_segment10
        			,batch_id
        			,record_number
        			,process_code
        			,error_code
        			,x_created_by
        			,x_creation_date
        			,x_last_update_date
        			,x_last_updated_by
        			,x_last_update_login
        			,request_id
        			,program_application_id
        			,program_id
        			,program_update_date
    		   FROM xx_ar_inv_trx_dist_stg
              WHERE batch_id = G_BATCH_ID
                AND process_code = xx_emf_cn_pkg.CN_PREVAL
                AND request_id = xx_emf_pkg.G_REQUEST_ID
                AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

         COMMIT;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'Error in move_rec_pre_standard_table = '
                                 || SQLERRM
                                );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            RETURN x_error_code;
      END move_rec_pre_standard_table;

      PROCEDURE update_record_count
      IS
         CURSOR c_get_total_cnt
         IS
            SELECT COUNT (1) total_count
              FROM xx_ar_inv_trx_dist_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT COUNT (1) error_count
              FROM xx_ar_inv_trx_dist_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_ar_inv_trx_dist_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_ar_inv_trx_dist_pre_int
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               --AND process_code = xx_emf_cn_pkg.cn_process_data  --Commented to display sucess cnt with validate only mode
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
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Main  begins');
      retcode := xx_emf_cn_pkg.cn_success;
      set_cnv_env (p_batch_id           => p_batch_id,
                   p_required_flag      => xx_emf_cn_pkg.cn_yes
                  );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Start of main program....'
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
      mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'After mark record for processing call'
                           );

      IF NVL (p_override_flag, xx_emf_cn_pkg.cn_no) = xx_emf_cn_pkg.cn_no
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Within p_override_flag '
                              );
        /********************************************************
          Pre Validations starts here................
        ***********************************************************/
         set_stage (xx_emf_cn_pkg.cn_preval);

         OPEN c_xx_intg_trx_cnv (xx_emf_cn_pkg.cn_new);

         FETCH c_xx_intg_trx_cnv
         BULK COLLECT INTO x_ar_trx_stg_table;

         FOR i IN 1 .. x_ar_trx_stg_table.COUNT
         LOOP
            x_error_code :=
               xx_ar_trx_dist_cnv_val_pkg.pre_validations
                                                       (x_ar_trx_stg_table (i)
                                                       );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After pre-validations X_ERROR_CODE '
                                 );
            update_staging_records (x_error_code,
                                    x_ar_trx_stg_table (i).record_number
                                   );
         END LOOP;

         IF c_xx_intg_trx_cnv%ISOPEN
         THEN
            CLOSE c_xx_intg_trx_cnv;
         END IF;

        /*****************************************************************************
          Pre Validations Ends here................
         **********************************************************************************/

         /**********************************************************************************
            Moving Records from Staging table to Pre-Interface tables
                     having process_code = 'Pre- Validations'
         ***********************************************************************************/
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.propagate_error (x_error_code);
         xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_medium,
                             'After move_rec_pre_standard_table x_error_code '
                          || x_error_code
                         );
      END IF;                                       -- End of override if loop

    /*********************************************************************************
        Data Validations Starts here................
     **********************************************************************************/
      set_stage (xx_emf_cn_pkg.cn_valid);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Data Validations starts here'
                           );

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      FETCH c_xx_intg_pre_std_hdr
      BULK COLLECT INTO x_pre_std_hdr_table;

      FOR i IN 1 .. x_pre_std_hdr_table.COUNT
      LOOP
      BEGIN
         x_error_code :=
            xx_ar_trx_dist_cnv_val_pkg.data_validations
                                                      (x_pre_std_hdr_table (i)
                                                      );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After data validations x_error_code for '
                               || x_pre_std_hdr_table (i).record_number
                               || ' is '
                               || x_error_code
                              );
         update_master_status (x_pre_std_hdr_table (i), x_error_code);
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
		raise_application_error (-20199,
					 xx_emf_cn_pkg.cn_prc_err);
	     WHEN OTHERS
	     THEN
		xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
				  xx_emf_cn_pkg.cn_tech_error,
				  xx_emf_cn_pkg.cn_exp_unhand,
				  x_pre_std_hdr_table (i).record_number
				 );
      END;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

      update_pre_interface_records (x_pre_std_hdr_table);
      /********************************************************
         Data Validations Ends here................
      ***********************************************************/

      /********************************************************
             Data Derivation starts here................
       ***********************************************************/
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Data Derivations Starts here'
                           );
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      FETCH c_xx_intg_pre_std_hdr
      BULK COLLECT INTO x_pre_std_hdr_table;

      FOR i IN 1 .. x_pre_std_hdr_table.COUNT
      LOOP
      BEGIN
         x_error_code :=
            xx_ar_trx_dist_cnv_val_pkg.data_derivations
                                                      (x_pre_std_hdr_table (i)
                                                      );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'data_derivations: x_error_code for '
                               || x_pre_std_hdr_table (i).record_number
                               || ' is '
                               || x_error_code
                              );
         update_master_status (x_pre_std_hdr_table (i), x_error_code);
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
      			       'Process Level Error in Data Derivations'
      			      );
      		update_pre_interface_records (x_pre_std_hdr_table);
      		raise_application_error (-20199,
      					 xx_emf_cn_pkg.cn_prc_err);
      	     WHEN OTHERS
      	     THEN
      		xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
      				  xx_emf_cn_pkg.cn_tech_error,
      				  xx_emf_cn_pkg.cn_exp_unhand,
      				  x_pre_std_hdr_table (i).record_number
				 );
      END;
      END LOOP;

      IF c_xx_intg_pre_std_hdr%ISOPEN
      THEN
         CLOSE c_xx_intg_pre_std_hdr;
      END IF;

      update_pre_interface_records (x_pre_std_hdr_table);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Data Derivations ends here '
                           );
      /********************************************************
          Data Derivations Ends here....
       ***********************************************************/
      /********************************************************
         Post Validations starts here................
      ***********************************************************/
      set_stage (xx_emf_cn_pkg.cn_postval);
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      x_error_code := xx_ar_trx_dist_cnv_val_pkg.post_validations;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
  				   'After post-validations X_ERROR_CODE '
   				|| x_error_code
  			 );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.propagate_error (x_error_code);

      /********************************************************
         Post Validations Ends here....
       ***********************************************************/

      -- Set the stage to Process Data
      -- Perform process data only if p_validate_and_load is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load
      THEN
         set_stage (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Start of process data section '
                              );
         x_error_code := process_data;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'End of process data section '
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Start of mark_records_complete '
                              );
         mark_records_complete (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'End of mark_records_complete '
                              );
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;                                 --End If for p_validate_and_load

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Start of statistics update_record_count program '
                           );
      update_record_count;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'End of statistics update_record_count program '
                           );
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
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
         retcode := xx_emf_cn_pkg.cn_prc_err;
         xx_emf_pkg.create_report;
   END main;
END xx_inv_trx_dist_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_TRX_DIST_CNV_PKG TO INTG_XX_NONHR_RO;
