DROP PACKAGE BODY APPS.XX_INV_ITEM_CNV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ITEM_CNV_PKG" 
AS
----------------------------------------------------------------------
/* $Header: XXINVITEMCNVTL.pkb 1.2 2012/02/15 12:00:00 dsengupta noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 30-Dec-2011
 File Name      : XXINVITEMCNVTL.pkb
 Description    : This script creates the body for the Item Conversion translation package

 Change History:

 Version Date        Name			Remarks
 ------- ----------- ----			-------------------------------
 1.0     30-Dec-11   IBM Development Team	Initial development.
*/
----------------------------------------------------------------------

   -- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
   -- START RESTRICTIONS
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
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
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'mark_records_for_processing');

      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- purge from pre-interface tables and oracle standard tables
            DELETE FROM xx_inv_mtl_sys_item_pre
                  WHERE batch_id = g_batch_id;

            UPDATE xx_inv_mtl_sys_item_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id;

         ELSE

            UPDATE xx_inv_mtl_sys_item_pre
               SET process_code = xx_emf_cn_pkg.cn_preval,
                   ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                   request_id = xx_emf_pkg.g_request_id
             WHERE batch_id = g_batch_id;

	 END IF;

        DELETE FROM mtl_system_items_interface
         WHERE global_attribute20 = g_batch_id;

        DELETE FROM mtl_item_revisions_interface;

      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         IF p_override_flag = xx_emf_cn_pkg.cn_no
         THEN
            -- Update staging table
            UPDATE xx_inv_mtl_sys_item_stg
               SET request_id = xx_emf_pkg.g_request_id,
                   ERROR_CODE = xx_emf_cn_pkg.cn_null,
                   process_code = xx_emf_cn_pkg.cn_new
             WHERE batch_id = g_batch_id
               AND (   process_code = xx_emf_cn_pkg.cn_new
                    OR (    process_code = xx_emf_cn_pkg.cn_preval
                        AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                               (xx_emf_cn_pkg.CN_REC_WARN,
                                xx_emf_cn_pkg.cn_rec_err
                               )
                       )
                   );

         END IF;

         -- Update pre-interface table
         -- Scenario 1 Pre-Validation Stage
         UPDATE xx_inv_mtl_sys_item_stg a
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND EXISTS (
                   SELECT 1
                     FROM xx_inv_mtl_sys_item_pre
                    WHERE batch_id = g_batch_id
                      AND process_code = xx_emf_cn_pkg.cn_preval
                      AND ERROR_CODE IN
                             (xx_emf_cn_pkg.cn_null,
                              xx_emf_cn_pkg.CN_REC_WARN,
                              xx_emf_cn_pkg.cn_rec_err
                             )
                      AND record_number = a.record_number);

         DELETE FROM xx_inv_mtl_sys_item_pre
               WHERE batch_id = g_batch_id
                 AND process_code = xx_emf_cn_pkg.cn_preval
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_null,
                         xx_emf_cn_pkg.CN_REC_WARN,
                         xx_emf_cn_pkg.cn_rec_err
                        );

         -- Scenario 2 Data Validation Stage
         UPDATE xx_inv_mtl_sys_item_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.cn_preval
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_valid
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.CN_REC_WARN,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 3 Data Derivation Stage
         UPDATE xx_inv_mtl_sys_item_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.cn_derive
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_derive
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.CN_REC_WARN,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 4 Post Validation Stage
         UPDATE xx_inv_mtl_sys_item_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.CN_POSTVAL
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.CN_POSTVAL
            AND ERROR_CODE IN
                   (xx_emf_cn_pkg.cn_null,
                    xx_emf_cn_pkg.CN_REC_WARN,
                    xx_emf_cn_pkg.cn_rec_err
                   );

         -- Scenario 5 Process Data Stage
         UPDATE xx_inv_mtl_sys_item_pre
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS,
                process_code = xx_emf_cn_pkg.CN_POSTVAL
          WHERE batch_id = g_batch_id
            AND process_code = xx_emf_cn_pkg.cn_process_data
            AND ERROR_CODE IN
                            (xx_emf_cn_pkg.cn_null, xx_emf_cn_pkg.cn_rec_err);

      END IF;

      COMMIT;
   END;

   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_by       NUMBER := fnd_global.user_id;
      x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xx_inv_mtl_sys_item_stg
         SET process_code = g_stage,
             ERROR_CODE = DECODE (ERROR_CODE, NULL, p_error_code, ERROR_CODE),
             last_update_date = x_last_update_date,
             last_updated_by = x_last_update_by,
             last_update_login = x_last_updated_login
       WHERE batch_id = g_batch_id
         AND request_id = xx_emf_pkg.g_request_id
         AND process_code = xx_emf_cn_pkg.cn_new;

      COMMIT;
   END update_staging_records;

   -- END RESTRICTIONS
   PROCEDURE main (
      errbuf            OUT      VARCHAR2,
      retcode           OUT      VARCHAR2,
      p_batch_id        IN       VARCHAR2,
      p_restart_flag    IN       VARCHAR2,
      p_override_flag   IN       VARCHAR2,
      p_validate_and_load     IN VARCHAR2
    )
   IS
      x_error_code          NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;
      x_pre_std_hdr_table   G_XX_INV_ITEM_PRE_STD_TAB_TYPE;

      -- CURSOR FOR VARIOUS STAGES
      CURSOR c_xx_intg_pre_std_hdr (cp_process_status VARCHAR2)
      IS
          SELECT  *
            FROM xx_inv_mtl_sys_item_pre hdr
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

      PROCEDURE update_record_status (
         p_conv_pre_std_hdr_rec   IN OUT   G_XX_INV_ITEM_PRE_STD_REC_TYPE,
         p_error_code             IN       VARCHAR2
      )
      IS
      BEGIN
         -- For Item
         IF p_error_code IN
                        (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_pre_std_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_pre_std_hdr_rec.ERROR_CODE :=
               xx_inv_item_cnv_val_pkg.find_max
                                     (p_error_code,
                                      NVL (p_conv_pre_std_hdr_rec.ERROR_CODE,
                                           xx_emf_cn_pkg.CN_SUCCESS
                                          )
                                     );
         END IF;

         p_conv_pre_std_hdr_rec.process_code := g_stage;

      END update_record_status;

      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date     DATE   := SYSDATE;
         x_last_update_by       NUMBER := fnd_global.user_id;
         x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         UPDATE xx_inv_mtl_sys_item_pre
            SET process_code = g_stage,
                ERROR_CODE = NVL (ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS),
                last_updated_by = x_last_update_by,
                last_update_date = x_last_update_date,
                last_update_login = x_last_updated_login
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND process_code =
                   DECODE (p_process_code,
                           xx_emf_cn_pkg.cn_process_data, xx_emf_cn_pkg.CN_POSTVAL,
                           xx_emf_cn_pkg.cn_derive
                          )
            AND ERROR_CODE IN
                        (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

         COMMIT;
      END mark_records_complete;

      PROCEDURE update_pre_interface_records (
         p_cnv_pre_std_hdr_table   IN   g_xx_inv_item_pre_std_tab_type
      )
      IS
         x_last_update_date     DATE   := SYSDATE;
         x_last_update_by       NUMBER := fnd_global.user_id;
         x_last_updated_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         FOR indx IN 1 .. p_cnv_pre_std_hdr_table.COUNT
         LOOP
            UPDATE xx_inv_mtl_sys_item_pre
               SET segment1                         = p_cnv_pre_std_hdr_table (indx).segment1,
                   description                      = p_cnv_pre_std_hdr_table (indx).description,
                   build_in_wip_flag                = p_cnv_pre_std_hdr_table (indx).build_in_wip_flag,
                   lot_control_code                 = p_cnv_pre_std_hdr_table (indx).lot_control_code,
                   shelf_life_code                  = p_cnv_pre_std_hdr_table (indx).shelf_life_code,
                   default_so_source_type           = p_cnv_pre_std_hdr_table (indx).default_so_source_type,
                   atp_components_flag              = p_cnv_pre_std_hdr_table (indx).atp_components_flag,
                   serial_number_control_code       = p_cnv_pre_std_hdr_table (indx).serial_number_control_code,
                   location_control_code            = p_cnv_pre_std_hdr_table (indx).location_control_code,
                   planning_time_fence_code         = p_cnv_pre_std_hdr_table (indx).planning_time_fence_code,
                   lead_time_lot_size               = p_cnv_pre_std_hdr_table (indx).lead_time_lot_size,
                   std_lot_size                     = p_cnv_pre_std_hdr_table (indx).std_lot_size,
                   planning_time_fence_days         = p_cnv_pre_std_hdr_table (indx).planning_time_fence_days,
                   bom_item_type                    = p_cnv_pre_std_hdr_table (indx).bom_item_type,
                   atp_flag                         = p_cnv_pre_std_hdr_table (indx).atp_flag,
                   wip_supply_type                  = p_cnv_pre_std_hdr_table (indx).wip_supply_type,
                   primary_uom_code                 = p_cnv_pre_std_hdr_table (indx).primary_uom_code,
                   primary_unit_of_measure          = p_cnv_pre_std_hdr_table (indx).primary_unit_of_measure,
                   inventory_planning_code          = p_cnv_pre_std_hdr_table (indx).inventory_planning_code,
                   planning_make_buy_code           = p_cnv_pre_std_hdr_table (indx).planning_make_buy_code,
                   item_type                        = p_cnv_pre_std_hdr_table (indx).item_type,
                   mrp_planning_code                = p_cnv_pre_std_hdr_table (indx).mrp_planning_code,
                   organization_code                = p_cnv_pre_std_hdr_table (indx).organization_code,
                   template_name                    = p_cnv_pre_std_hdr_table (indx).template_name,
                   attribute_category               = p_cnv_pre_std_hdr_table (indx).attribute_category,
                   attribute1                       = p_cnv_pre_std_hdr_table (indx).attribute1,
                   attribute2                       = p_cnv_pre_std_hdr_table (indx).attribute2,
                   attribute3                       = p_cnv_pre_std_hdr_table (indx).attribute3,
                   attribute4                       = p_cnv_pre_std_hdr_table (indx).attribute4,
                   attribute5                       = p_cnv_pre_std_hdr_table (indx).attribute5,
                   attribute6                       = p_cnv_pre_std_hdr_table (indx).attribute6,
                   attribute7                       = p_cnv_pre_std_hdr_table (indx).attribute7,
                   attribute8                       = p_cnv_pre_std_hdr_table (indx).attribute8,
                   attribute9                       = p_cnv_pre_std_hdr_table (indx).attribute9,
                   attribute10                      = p_cnv_pre_std_hdr_table (indx).attribute10,
                   global_attribute20               = p_cnv_pre_std_hdr_table (indx).global_attribute20,
                   dual_uom_control                 = p_cnv_pre_std_hdr_table (indx).dual_uom_control,
                   secondary_uom_code               = p_cnv_pre_std_hdr_table (indx).secondary_uom_code,
                   dual_uom_deviation_high          = p_cnv_pre_std_hdr_table (indx).dual_uom_deviation_high,
                   dual_uom_deviation_low           = p_cnv_pre_std_hdr_table (indx).dual_uom_deviation_low,
                   shelf_life_days                  = p_cnv_pre_std_hdr_table (indx).shelf_life_days,
                   unit_weight                      = p_cnv_pre_std_hdr_table (indx).unit_weight,
                   weight_uom_code                  = p_cnv_pre_std_hdr_table (indx).weight_uom_code,
                   volume_uom_code                  = p_cnv_pre_std_hdr_table (indx).volume_uom_code,
                   unit_volume                      = p_cnv_pre_std_hdr_table (indx).unit_volume,
                   unit_length                      = p_cnv_pre_std_hdr_table (indx).unit_length,
                   unit_width                       = p_cnv_pre_std_hdr_table (indx).unit_width,
                   unit_height                      = p_cnv_pre_std_hdr_table (indx).unit_height,
                   global_trade_item_number         = p_cnv_pre_std_hdr_table (indx).global_trade_item_number,
                   gpc_code                         = p_cnv_pre_std_hdr_table (indx).gpc_code,
                   start_auto_lot_number            = p_cnv_pre_std_hdr_table (indx).start_auto_lot_number,
                   auto_lot_alpha_prefix            = p_cnv_pre_std_hdr_table (indx).auto_lot_alpha_prefix,
                   dimension_uom_code               = p_cnv_pre_std_hdr_table (indx).dimension_uom_code,
                   secondary_default_ind            = p_cnv_pre_std_hdr_table (indx).secondary_default_ind,
                   bom_enabled_flag                 = p_cnv_pre_std_hdr_table (indx).bom_enabled_flag,
                   eng_item_flag                    = p_cnv_pre_std_hdr_table (indx).eng_item_flag, -- Added on 13-dec-2013 for UAT
                   template_id                      = p_cnv_pre_std_hdr_table (indx).template_id,
                   organization_id                  = p_cnv_pre_std_hdr_table (indx).organization_id,
                   process_code                     = p_cnv_pre_std_hdr_table (indx).process_code,
                   error_code                       = p_cnv_pre_std_hdr_table (indx).error_code,
		   source_system_reference	    = p_cnv_pre_std_hdr_table (indx).source_system_reference,
		   pricing_uom			    = p_cnv_pre_std_hdr_table (indx).pricing_uom,
		   conversion_type		    = p_cnv_pre_std_hdr_table (indx).conversion_type,
                   last_updated_by                  = x_last_update_by,
                   last_update_date                 = x_last_update_date,
                   last_update_login                = x_last_updated_login
             WHERE record_number = p_cnv_pre_std_hdr_table (indx).record_number
               AND batch_id      = g_batch_id;
         END LOOP;

         COMMIT;
      END update_pre_interface_records;
      /***DS:
      PROCEDURE mark_duplicate_combination
      IS
         CURSOR c_xx_error_rec
         IS
         SELECT record_number
               ,legacy_item_number
               ,organization_code
               ,SUBSTR(error_desc,4) error_desc
           FROM xx_inv_item_org_stg a
          WHERE EXISTS (SELECT 1
                            FROM xx_inv_mtl_sys_item_stg b
                           WHERE a.legacy_item_number = b.legacy_item_number
                             AND b.batch_id = g_batch_id
                         )
            AND a.error_code = xx_emf_cn_pkg.CN_REC_ERR
            AND a.process_code = xx_emf_cn_pkg.CN_PREVAL
            AND SUBSTR(a.error_desc,1,3) = 'UPD';

         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
          UPDATE  xx_inv_item_org_stg a
             SET  organization_id = (select c.organization_id from org_organization_definitions c
				      where c.organization_code = xx_intg_common_pkg.get_inv_organization_id(organization_code)),
                  error_code      = xx_emf_cn_pkg.CN_SUCCESS
           WHERE  EXISTS (SELECT 1
                            FROM xx_inv_mtl_sys_item_stg b
                           WHERE a.legacy_item_number = b.legacy_item_number
                             AND b.batch_id = g_batch_id
                         );

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Number of Record updated 1:' || SQL%ROWCOUNT);

          UPDATE  xx_inv_item_org_stg a
             SET  process_code = xx_emf_cn_pkg.CN_PREVAL,
                  error_code   = xx_emf_cn_pkg.CN_REC_ERR,
                  error_desc   = 'UPD~Error:Invalid organization code '
           WHERE  organization_id = 0
             AND  error_code      = xx_emf_cn_pkg.CN_SUCCESS
             ;
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Number of Record updated 1:' || SQL%ROWCOUNT);

          UPDATE xx_inv_item_org_stg xio
             SET error_code   = xx_emf_cn_pkg.CN_REC_ERR,
                 process_code = xx_emf_cn_pkg.CN_PREVAL,
                 error_desc   = 'UPD~Error:Duplicate Item Org Assignment '
           WHERE
                rowid IN (SELECT "rowid" FROM
                               (SELECT "rowid", rank_n FROM
                                    (SELECT ROW_NUMBER()
                                            OVER (PARTITION BY
                                                  legacy_item_number
                                                 ,organization_id
                                                  ORDER BY rowid
                                                 ) rank_n
                                           ,rowid as "rowid"
                                      FROM xx_inv_item_org_stg a
                                     WHERE organization_id > 0
                                       AND EXISTS (SELECT 1
                                                     FROM xx_inv_mtl_sys_item_stg ximsi
                                                    WHERE a.legacy_item_number = ximsi.legacy_item_number
                                                      AND ximsi.batch_id       = g_batch_id
                                                      AND ximsi.request_id     = xx_emf_pkg.G_REQUEST_ID
                                                   )
                                    )
                                   WHERE rank_n > 1
                                   )
                                 )
              AND EXISTS (SELECT 1
                            FROM xx_inv_mtl_sys_item_stg b
                           WHERE xio.legacy_item_number = b.legacy_item_number
                             AND b.batch_id = g_batch_id
                             AND b.request_id         = xx_emf_pkg.G_REQUEST_ID
                         )
             ;

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Number of Record updated 2: ' || SQL%ROWCOUNT);
           COMMIT;

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Number of Duplicate Item Org Assignment ->' || SQL%ROWCOUNT);

           FOR cur_rec IN c_xx_error_rec
           LOOP
             xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                              ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                              ,p_error_text  => cur_rec.error_desc
                              ,p_record_identifier_1 => 'INV'||cur_rec.record_number
                              ,p_record_identifier_2 => cur_rec.legacy_item_number
                              ,p_record_identifier_3 => cur_rec.organization_code
                              );
          END LOOP;

          COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in duplicate assignment Validation ' || SQLCODE);
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                            ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                            ,p_error_text  => 'Errors in duplicate assignment Validation=>'||SQLERRM
                            );
      END mark_duplicate_combination;*/


      FUNCTION move_rec_pre_standard_table
         RETURN NUMBER
      IS
         x_creation_date           DATE                        := SYSDATE;
         x_created_by              NUMBER               := fnd_global.user_id;
         x_last_update_date        DATE                        := SYSDATE;
         x_last_update_by          NUMBER               := fnd_global.user_id;
         x_last_updated_login      NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);

         x_cnv_pre_std_hdr_table   G_XX_INV_ITEM_PRE_STD_TAB_TYPE;
         x_error_code              NUMBER         := xx_emf_cn_pkg.CN_SUCCESS;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside move_rec_pre_standard_table'
                              );

         -- CCID099 changes
         -- Select only the appropriate columns that are required to be inserted into the
         -- Pre-Interface Table and insert from the Staging Table

         INSERT INTO xx_inv_mtl_sys_item_pre
                     (segment1,
                      description,
                      build_in_wip_flag,
                      lot_control_code_text,
                      tracking_quantity_ind,
                      shelf_life_code_text,
                      default_so_source_type,
                      atp_components_flag_text,
                      serial_number_cntrl_code_text,
                      location_control_code_text,
                      planning_time_fence_code_text,
                      lead_time_lot_size,
                      std_lot_size,
                      planning_time_fence_days,
                      bom_enabled_flag,
                      secondary_default_ind,
                      bom_item_type_text,
                      atp_flag_text,
                      wip_supply_type_text,
                      primary_uom_code,
                      inventory_planning_code_text,
                      planning_make_buy_code_text,
                      item_type,
                      mrp_planning_code_text,
                      organization_code,
                      template_name,
                      attribute_category,
                      attribute1,
                      attribute2,
                      attribute3,
                      attribute4,
                      attribute5,
                      attribute6,
                      attribute7,
                      attribute8,
                      attribute9,
                      attribute10,
                      dual_uom_control,
                      secondary_uom_code,
                      dual_uom_deviation_high,
                      dual_uom_deviation_low,
                      batch_id,
                      record_number,
                      process_code,
                      error_code,
                      request_id,
                      program_application_id,
                      program_id,
                      program_update_date,
                      shelf_life_days,
                      unit_weight,
                      weight_uom_code,
                      volume_uom_code,
                      unit_volume,
                      unit_length,
                      unit_width,
                      unit_height,
                      global_trade_item_number,
                      gpc_code,
                      postprocessing_lead_time,
                      preprocessing_lead_time,
                      full_lead_time,
                      start_auto_lot_number,
                      auto_lot_alpha_prefix ,
                      dimension_uom_code,
                      inventory_item_flag,
                      stock_enabled_flag,
                      mtl_transactions_enabled_flag,
		      source_system_reference,
		      pricing_uom,
		      conversion_type,
		      inventory_item_status_code
                      )
               SELECT a.segment1,
                      a.description,
                      a.build_in_wip_flag,
                      a.lot_control_code,
                      a.tracking_quantity_ind,
                      a.shelf_life_code,
                      UPPER(a.default_so_source_type),
                      a.atp_components,
                      a.serial_number_control_code,
                      a.location_control_code,
                      a.planning_time_fence_code,
                      a.lead_time_lot_size,
                      DECODE(a.lead_time_lot_size, '', '', a.std_lot_size),
                      a.planning_time_fence_days,
                      null, --a.bom_enabled_flag,
                      a.secondary_default_ind,
                      a.bom_item_type,
                      a.atp_flag,
                      a.wip_supply_type,
                      a.primary_uom_code,
                      a.inventory_planning_code,
                      null,
                      a.item_type,
                      a.mrp_planning_code,
                      a.organization_code,
                      a.template_name,
                      a.attribute_category,
                      a.attribute1,
                      a.attribute2,
                      a.attribute3,
                      a.attribute4,
                      a.attribute5,
                      a.attribute6,
                      a.attribute7,
                      a.attribute8,
                      a.attribute9,
                      a.attribute10,
                      a.dual_uom_control,
                      a.secondary_uom_code,
                      a.dual_uom_deviation_high,
                      a.dual_uom_deviation_low,
                      a.batch_id,
                      a.record_number, --'MST'||a.record_number, -- Change on 11-sep-2013
                      g_stage,
                      a.error_code,
                      a.request_id,
                      a.program_application_id,
                      a.program_id,
                      a.program_update_date,
                      DECODE(a.shelf_life_code, '', '', a.shelf_life_days),
                      DECODE(a.weight_uom_code, '', '', a.unit_weight),
                      a.weight_uom_code,
                      a.volume_uom_code,
                      DECODE(a.volume_uom_code, '', '', a.unit_volume),
                      a.unit_length,
                      a.unit_width,
                      a.unit_height,
                      a.global_trade_item_number,
                      a.gpc_code,
                      null,
                      null,
                      null,
                      a.start_auto_lot_number,
                      a.auto_lot_alpha_prefix ,
                      a.dimension_uom_code,
                      'Y',
                      'Y',
                      'Y',
		      a.source_system_name,
		      a.pricing_uom,
		      a.conversion_type,
		      a.item_status
               FROM xx_inv_mtl_sys_item_stg a
               WHERE
                     a.batch_id = g_batch_id
                 AND a.process_code = xx_emf_cn_pkg.cn_preval
                 AND a.request_id = xx_emf_pkg.g_request_id
                 AND a.ERROR_CODE IN
                        (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);

          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                    'No of Records Insert into Pre-Interface 1=>'||SQL%ROWCOUNT
                                   );
         COMMIT;


         --Update the organization ID column to filter out the already loaded data
         update xx_inv_mtl_sys_item_pre
	    set organization_id = xx_intg_common_pkg.get_inv_organization_id(organization_code)
            where batch_id = g_batch_id
         ;

         COMMIT;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                    'No of Records Insert into Pre-Interface 2=>'||SQL%ROWCOUNT||'-'||SQLERRM
                                   );
            xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                              xx_emf_cn_pkg.cn_tech_error,
                              xx_emf_cn_pkg.cn_exp_unhand
                             );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
             xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'error in insertion'||SQLERRM);
            RETURN x_error_code;
      END move_rec_pre_standard_table;

      -- This program unit is updates records in pre-interface table with error
      -- for each record if Item Import is Success or all records are updated
      -- with Error Status if Item Import fails
      PROCEDURE mark_records_for_api_error
        (
            p_process_code   VARCHAR2,
            p_organization_id NUMBER,
	    p_case VARCHAR2
        )
        IS
            x_last_update_date       DATE := SYSDATE;
            x_last_updated_by        NUMBER := fnd_global.user_id;
            x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
                        x_record_count           NUMBER;
                        x_mst_org_id         NUMBER;
            PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for API Error');


          SELECT organization_id
            INTO x_mst_org_id
            FROM mtl_parameters
           WHERE organization_id=fnd_profile.value('MSD_MASTER_ORG')
           ;

           IF(p_organization_id=x_mst_org_id) THEN

              UPDATE mtl_system_items_interface
             SET process_flag = 3
           WHERE
                segment1 in
                (
              SELECT segment1
                FROM mtl_system_items_interface
               WHERE
                  set_process_id = g_set_process_id
                 AND organization_id != x_mst_org_id
              MINUS
              SELECT segment1
                FROM mtl_system_items_b
               WHERE
                   set_process_id    = g_set_process_id
                 AND organization_id = x_mst_org_id
          )
          AND organization_id != x_mst_org_id
          ;

           END IF;

	   IF p_case = 'S' THEN
	       UPDATE xx_inv_mtl_sys_item_pre xmtp
		 SET process_code = G_STAGE,
		     error_code   = xx_emf_cn_pkg.CN_REC_ERR,
		     last_updated_by   = x_last_updated_by,
		     last_update_date  = x_last_update_date,
		     last_update_login = x_last_update_login
	       WHERE request_id    = xx_emf_pkg.G_REQUEST_ID
		 AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
					    , xx_emf_cn_pkg.CN_POSTVAL
					    , xx_emf_cn_pkg.CN_DERIVE
					    )
		 AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN,xx_emf_cn_pkg.CN_REC_ERR)
		 AND xmtp.organization_id = p_organization_id
		 AND Exists (SELECT 1
			       FROM mtl_system_items_interface mti
			      WHERE mti.organization_id = p_organization_id
				AND mti.segment1        = xmtp.segment1
				AND set_process_id      = g_set_process_id
				AND mti.process_flag    <> 7 --= 3
			     )
		 AND batch_id = g_batch_id
		 ;
	   ELSE
	       UPDATE xx_inv_mtl_sys_item_pre xmtp
		 SET process_code = G_STAGE,
		     error_code   = xx_emf_cn_pkg.CN_REC_ERR,
		     last_updated_by   = x_last_updated_by,
		     last_update_date  = x_last_update_date,
		     last_update_login = x_last_update_login
	       WHERE request_id    = xx_emf_pkg.G_REQUEST_ID
		 AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
					    , xx_emf_cn_pkg.CN_POSTVAL
					    , xx_emf_cn_pkg.CN_DERIVE
					    )
		 AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN,xx_emf_cn_pkg.CN_REC_ERR)
		 AND xmtp.organization_id = p_organization_id
		 AND Exists (SELECT 1
			       FROM mtl_system_items_interface mti
			      WHERE mti.organization_id = p_organization_id
				--AND mti.segment1        = xmtp.segment1
				AND set_process_id      = g_set_process_id
				AND mti.process_flag    <> 7 --= 3
			     )
		 AND batch_id = g_batch_id
		 ;
	   END IF;

           x_record_count := SQL%ROWCOUNT;
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Record Marked with API Error=>'||x_record_count);

           COMMIT;
        END mark_records_for_api_error;


        PROCEDURE print_records_with_api_error
        IS
           CURSOR cur_print_error_records
           IS
           SELECT  mti.segment1 item_segment1
                  ,mp.organization_code
                  ,mie.error_message
                  ,xim.record_number
                  ,mie.column_name
            FROM mtl_system_items_interface mti
                ,mtl_interface_errors mie
                ,mtl_parameters mp
                ,xx_inv_mtl_sys_item_pre xim
                ,fnd_concurrent_programs fcp
           WHERE mti.set_process_id    = g_set_process_id
             AND mti.transaction_id    = mie.transaction_id
             AND mti.request_id        = mie.request_id
             AND mti.organization_id   = mie.organization_id
             AND mti.organization_id   = mp.organization_id
             AND mie.error_message     IS NOT NULL
             AND mie.program_id        = fcp.concurrent_program_id
             AND xim.organization_id   = mti.organization_id
             AND xim.segment1          = mti.segment1
             AND fcp.concurrent_program_name='INCOIN'
             ;
        BEGIN
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside print_records_with_api_error');
           FOR cur_rec IN cur_print_error_records
           LOOP
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_CODE:'||cur_rec.column_name);
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'~ERROR_MESSAGE:'||cur_rec.error_message);
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
                               ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
                               ,p_error_text  => cur_rec.error_message
                               ,p_record_identifier_1 => cur_rec.record_number
                               ,p_record_identifier_2 => cur_rec.organization_code
                               ,p_record_identifier_3 => cur_rec.item_segment1
                              );
           END LOOP;
        END print_records_with_api_error;

      FUNCTION process_data
         RETURN NUMBER
      IS
         x_return_status     VARCHAR2 (15) := xx_emf_cn_pkg.CN_SUCCESS;
         x_req_return_status BOOLEAN;
         x_req_id            NUMBER;
         x_dev_phase         VARCHAR2(20);
         x_phase             VARCHAR2(20);
         x_dev_status        VARCHAR2(20);
         x_status            VARCHAR2(20);
         x_message           VARCHAR2(100);

         CURSOR c_get_organization
         IS
         SELECT distinct organization_id
           FROM mtl_system_items_interface
          WHERE set_process_id = g_set_process_id
          ORDER by organization_id ;
      BEGIN
         -- CCID099 changes
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table
         SELECT xx_inv_mtl_set_process_id_s.NEXTVAL
           INTO g_set_process_id
           FROM dual;

         INSERT INTO mtl_system_items_interface
                     (process_flag
                     , transaction_type
                     , segment1
                     , description
		     , source_system_reference
                     , build_in_wip_flag
                     , lot_control_code
                     , shelf_life_code
                     , default_so_source_type
                     , atp_components_flag
                     , serial_number_control_code
                     , location_control_code
                     , planning_time_fence_code
                     , lead_time_lot_size
                     , std_lot_size
                     , planning_time_fence_days
                     , bom_item_type
                     , atp_flag
                     , wip_supply_type
                     , primary_uom_code
                     , tracking_quantity_ind
                     , inventory_planning_code
                     , planning_make_buy_code
                     , item_type
                     , mrp_planning_code
                     , organization_code
                     , template_name
                     , attribute_category
                     , attribute1
                     , attribute2
                     , attribute3
                     , attribute4
                     , attribute5
                     , attribute6
                     , attribute7
                     , attribute8
                     , attribute9
                     , attribute10
                     , set_process_id       -- to group the interface data batch wise
                     , global_attribute20
                     , dual_uom_control
                     , secondary_uom_code
                     , dual_uom_deviation_high
                     , dual_uom_deviation_low
                     , template_id
                     , organization_id
                     , shelf_life_days
                     , unit_weight
                     , weight_uom_code
                     , volume_uom_code
                     , unit_volume
                     , unit_length
                     , unit_width
                     , unit_height
                     , global_trade_item_number
                     , gpc_code
                     , postprocessing_lead_time
                     , preprocessing_lead_time
                     , full_lead_time
                     , start_auto_lot_number
                     , auto_lot_alpha_prefix
                     , dimension_uom_code
                     , bom_enabled_flag
                     , secondary_default_ind
                     , inventory_item_flag
                     , stock_enabled_flag
                     , mtl_transactions_enabled_flag
		                 , inventory_item_status_code
                     , eng_item_flag           -- Aded on 13-dec-2013 for UAT
                     , created_by
                     , creation_date
                     , last_updated_by
                     , last_update_date
                     , last_update_login
                      )
            SELECT
                      1
                      , 'CREATE'
                      , segment1
                      , description
		      , source_system_reference
                      , build_in_wip_flag
                      , lot_control_code
                      , shelf_life_code
                      , default_so_source_type
                      , atp_components_flag
                      , serial_number_control_code
                      , location_control_code
                      , planning_time_fence_code
                      , lead_time_lot_size
                      , std_lot_size
                      , planning_time_fence_days
                      , bom_item_type
                      , atp_flag
                      , wip_supply_type
                      , primary_uom_code
                      , tracking_quantity_ind
                      , inventory_planning_code
                      , planning_make_buy_code
                      , item_type
                      , mrp_planning_code
                      , organization_code
                      , template_name
                      , attribute_category
                      , pricing_uom
		      , conversion_type
                      , attribute3
                      , attribute4
                      , attribute5
                      , attribute6
                      , attribute7
                      , attribute8
                      , attribute9
                      , attribute10
                      , g_set_process_id  -- to group the data in mtl_system_items_interface table
                      , g_batch_id       --for error tracking
                      , dual_uom_control
                      , secondary_uom_code
                      , dual_uom_deviation_high
                      , dual_uom_deviation_low
                      , template_id
                      , organization_id
                      , shelf_life_days
                      , unit_weight
                      , weight_uom_code
                      , volume_uom_code
                      , unit_volume
                      , unit_length
                      , unit_width
                      , unit_height
                      , global_trade_item_number
                      , gpc_code
                      , postprocessing_lead_time
                      , preprocessing_lead_time
                      , full_lead_time
                      , start_auto_lot_number
                      , auto_lot_alpha_prefix
                      , dimension_uom_code
                      , bom_enabled_flag
                      , secondary_default_ind
                       ,inventory_item_flag
                       ,stock_enabled_flag
                       ,mtl_transactions_enabled_flag
		                   ,inventory_item_status_code
                       ,eng_item_flag -- Aded on 13-dec-2013 for UAT
                      , created_by
                      , creation_date
                      , last_updated_by
                      , last_update_date
                      , last_update_login
              FROM xx_inv_mtl_sys_item_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE IN
                        (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
               AND process_code = xx_emf_cn_pkg.CN_POSTVAL;

              FOR cur_rec IN c_get_organization
              LOOP
                 x_req_id :=FND_REQUEST.SUBMIT_REQUEST (application =>'INV'
                                                      ,program => 'INCOIN'
                                                      ,description => 'Item Open Interface'
                                                      ,argument1 => cur_rec.organization_id
                                                      ,argument2 => 2
                                                      ,argument3 => 1
                                                      ,argument4 => 1
                                                      ,argument5 => 1
                                                      ,argument6 => g_set_process_id
                                                      ,argument7 => 1
                                                      );
                 COMMIT;
                 IF x_req_id > 0 THEN
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Submit =>SUCCESS');
                    x_req_return_status := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id      => x_req_id,
                                                                           INTERVAL        => 10,
                                                                           max_wait        => null,
                                                                           phase           => x_phase,
                                                                           status          => x_status,
                                                                           dev_phase       => x_dev_phase,
                                                                           dev_status      => x_dev_status,
                                                                           MESSAGE         => x_message
                                                                           );
                   IF x_req_return_status = TRUE THEN
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Completed =>'||x_dev_status);
                      mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,cur_rec.organization_id, 'S');
                      -- Print the records with API Error
                      print_records_with_api_error;
                      x_error_code := xx_emf_cn_pkg.CN_SUCCESS;

		   ELSE

			xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Item Open Interface Completed =>'||x_dev_status);
			mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA,cur_rec.organization_id, 'F');
			-- Print the records with API Error
			print_records_with_api_error;
			x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
                   END IF;
                 ELSE
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in Item Interface Submit');
                    x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;

		    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
                                     ,p_category    =>      xx_emf_cn_pkg.CN_STG_APICALL
                                     ,p_error_text  => 'Error in Item Interface Submit'
                                     ,p_record_identifier_1 => 'Process level error : Exiting'
                                     );
                 END IF;
              END LOOP;
         RETURN x_return_status;
      END process_data;

      PROCEDURE update_record_count(p_validate_and_load IN VARCHAR2)
      IS
         CURSOR c_get_total_cnt
         IS
         SELECT sum(a.total_count) total_count from
	    (
	     SELECT COUNT (1) total_count
	       FROM xx_inv_mtl_sys_item_stg
	      WHERE batch_id = g_batch_id
		AND request_id = xx_emf_pkg.g_request_id
             ) a;

         x_total_cnt     NUMBER;

         CURSOR c_get_error_cnt
         IS
            SELECT sum(a.error_count) error_count from
           (
            SELECT COUNT (1) error_count
              FROM xx_inv_mtl_sys_item_stg
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
            UNION ALL
            SELECT COUNT (1) error_count
              FROM xx_inv_mtl_sys_item_pre
             WHERE batch_id   = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
             ) a;

         x_error_cnt     NUMBER;

         CURSOR c_get_warning_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_inv_mtl_sys_item_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND ERROR_CODE = xx_emf_cn_pkg.CN_REC_WARN;

         x_warn_cnt      NUMBER;

         CURSOR c_get_success_cnt
         IS
            SELECT COUNT (1) warn_count
              FROM xx_inv_mtl_sys_item_pre
             WHERE batch_id = g_batch_id
               AND request_id = xx_emf_pkg.g_request_id
               AND process_code = xx_emf_cn_pkg.cn_process_data
               AND ERROR_CODE = xx_emf_cn_pkg.CN_SUCCESS;

	CURSOR c_get_success_valid_cnt
	IS
	   SELECT COUNT (1) success_count
	     FROM xx_inv_mtl_sys_item_pre
	    WHERE batch_id = g_batch_id
	      AND request_id = xx_emf_pkg.g_request_id
	      AND process_code = xx_emf_cn_pkg.CN_POSTVAL
	      AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

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


	IF p_validate_and_load = g_validate_and_load THEN
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

    --  l_max_error  VARCHAR2(10);

   BEGIN
      retcode := xx_emf_cn_pkg.CN_SUCCESS;
      -- Need to maintain the version on the files.
              -- when updating the package remember to incrimint the version such that it can be checked in the log file from front end.
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvvl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvvl_pkb);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvtl_pks);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, cn_xxinvitemcnvtl_pkb);

      -- Start CCID099 changes
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
      -- End CCID099 changes

      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
       mark_records_for_processing (p_restart_flag       => p_restart_flag,
                                   p_override_flag      => p_override_flag
                                  );

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                            'Main:Param - p_override_flag ' || p_override_flag
                           );

      -- Once the records are identified based on the input parameters
      -- Start with pre-validations
      IF NVL (p_override_flag, xx_emf_cn_pkg.cn_no) = xx_emf_cn_pkg.cn_no
      THEN
         -- Set the stage to Pre Validations
         set_stage (xx_emf_cn_pkg.cn_preval);
         -- CCID099 changes
         -- Change the validations package to the appropriate package name
         -- Modify the parameters as required
         -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
         -- PRE_VALIDATIONS SHOULD BE RETAINED
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                 'calling pre_validations: batch_id'||p_batch_id
                           );
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                 'err code 1:'||x_error_code
                           );


          x_error_code := xx_inv_item_cnv_val_pkg.pre_validations(p_batch_id);

           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                      'err code 2'||x_error_code
                           );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                  'After pre-validations X_ERROR_CODE '
                               || x_error_code
                              );
         -- Update process code of staging records
         -- Also move the successful records to pre-interface tables
         update_staging_records (xx_emf_cn_pkg.CN_SUCCESS);
         --xx_emf_pkg.propagate_error (x_error_code);
         --Marking duplicate records in Organization Assignment Table
         --mark_duplicate_combination;
         x_error_code := move_rec_pre_standard_table;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                                       'move_rec_pre_standard_table'
                                    || x_error_code
                              );
         xx_emf_pkg.propagate_error (x_error_code);

      END IF;
 -- Once pre-validations are complete the loop through the pre-interface records
      -- and perform data validations on this table
      -- Set the stage to data Validations
        -----------------------------------------------------
----------( Stage 3: DATA VALIDATION)-----------------
         ------------------------------------------------------
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_preval);

      LOOP
         FETCH c_xx_intg_pre_std_hdr
         BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'BULK COLLECT');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Before Loop - x_pre_std_hdr_table.count '
                               || x_pre_std_hdr_table.COUNT
                              );


         FOR i IN 1 .. x_pre_std_hdr_table.COUNT
         LOOP
            BEGIN
               -- Perform header level Base App Validations
               x_error_code :=
                  xx_inv_item_cnv_val_pkg.data_validations
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
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_pre_std_hdr_table (i).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'x_pre_std_hdr_table.count '
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


      xx_emf_pkg.WRITE_LOG(xx_emf_cn_pkg.cn_low, fnd_global.conc_request_id || ' : Before Data Derivations');
      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.cn_derive);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
					      'batch_id  '
					   || g_batch_id
					   || ' is '
					   || x_error_code
				    );
      --For Item
      OPEN c_xx_intg_pre_std_hdr (xx_emf_cn_pkg.cn_valid);

      LOOP
	 FETCH c_xx_intg_pre_std_hdr
	 BULK COLLECT INTO x_pre_std_hdr_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;
	 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
						   'table count  '
						|| x_pre_std_hdr_table.COUNT
				    );
	 FOR i IN 1 .. x_pre_std_hdr_table.COUNT
	 LOOP
	    BEGIN
	       -- Perform header level Base App Validations
	       x_error_code :=
		  xx_inv_item_cnv_val_pkg.data_derivations
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
				    x_pre_std_hdr_table (i).record_number
				   );
	    END;
	 END LOOP;

	 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
				  'x_pre_std_hdr_table.count '
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

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.CN_POSTVAL);
      -- CCID099 changes
      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      x_error_code := xx_inv_item_cnv_val_pkg.post_validations(g_batch_id);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
			       'After post-validations X_ERROR_CODE '
			    || x_error_code
			   );

      mark_records_complete (xx_emf_cn_pkg.CN_POSTVAL);
      xx_emf_pkg.propagate_error (x_error_code);


      -- Perform process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD -- DS: Added 30-Jan-12
      IF p_validate_and_load = g_validate_and_load THEN
	      -- Set the stage to Process Data
	      set_stage (xx_emf_cn_pkg.cn_process_data);
	      --Call Process Data
	      x_error_code := process_data ;

	      mark_records_complete (xx_emf_cn_pkg.cn_process_data);

	      xx_emf_pkg.propagate_error (x_error_code);

      end if; --for validate only flag check -- DS: Added 30-Jan-12

      update_record_count(p_validate_and_load);

      --x_error_code:=process_data_cross_reference;
      --xx_emf_pkg.propagate_error (x_error_code);

      xx_emf_pkg.create_report;

      COMMIT; -- DS: Added 30-Jan-12
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         fnd_file.put_line (fnd_file.output, xx_emf_pkg.cn_env_not_set);
         DBMS_OUTPUT.put_line (xx_emf_pkg.cn_env_not_set);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count(p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'xyz1: '||SQLERRM);
         retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count(p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'xyz2: '||SQLERRM);
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count(p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'xyz3: '||SQLERRM);
         retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count(p_validate_and_load);
         xx_emf_pkg.create_report;
   END main;
END xx_inv_item_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEM_CNV_PKG TO INTG_XX_NONHR_RO;
