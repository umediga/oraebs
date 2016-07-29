DROP PACKAGE BODY APPS.XX_PO_ASL_CONV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PO_ASL_CONV_PKG" 
AS
--==================================================================================
  -- Created By     : Kirthana Ramesh
  -- Creation Date  : 23-APR-2013
  -- Filename       : XX_PO_ASL_CONV_PKG.pkb
  -- Description    : Package body for Approved Supplier List Conversion

   -- Change History:

   -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ------------------------------------
  -- 23-APR-2013   1.0         Kirthana Ramesh     Initial development.
--====================================================================================

   --**********************************************************************
--    Procedure to set environment.
--**********************************************************************
   PROCEDURE set_cnv_env (
      p_batch_id        VARCHAR2,
      p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside set_cnv_env...');
      g_batch_id := p_batch_id;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'G_BATCH_ID: ' || g_batch_id
                           );
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

   PROCEDURE dbg_low (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'In xx_po_asl_conv_pkg.'
                            || g_api_name
                            || ': '
                            || p_dbg_text
                           );
   END dbg_low;

   PROCEDURE dbg_med (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'In xx_po_asl_conv_pkg.'
                            || g_api_name
                            || ': '
                            || p_dbg_text
                           );
   END dbg_med;

   PROCEDURE dbg_high (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high,
                               'In xx_po_asl_conv_pkg.'
                            || g_api_name
                            || ': '
                            || p_dbg_text
                           );
   END dbg_high;

--**********************************************************************
--    Procedure to mark records for processing.
--**********************************************************************
   PROCEDURE mark_records_for_processing (p_restart_flag IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      ----- All records are processed if the Restart Flag is set to All Records otherwise only Error records -----
      g_api_name := 'mark_records_for_processing';
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Inside of mark records for processing...'
                           );

      IF p_restart_flag = xx_emf_cn_pkg.cn_all_recs
      THEN
         --------------Update ASL stg table-------------------------------
         UPDATE xx_po_asl_stg
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id;
      ELSIF p_restart_flag = xx_emf_cn_pkg.cn_err_recs
      THEN
         --------------Update credit card stg table table-------------------------------
         UPDATE xx_po_asl_stg
            SET request_id = xx_emf_pkg.g_request_id,
                ERROR_CODE = xx_emf_cn_pkg.cn_null,
                process_code = xx_emf_cn_pkg.cn_new
          WHERE batch_id = g_batch_id
            AND NVL (ERROR_CODE, xx_emf_cn_pkg.cn_rec_err) IN
                   (xx_emf_cn_pkg.cn_rec_warn,
                    xx_emf_cn_pkg.cn_rec_err,
                    xx_emf_cn_pkg.cn_prc_err
                   );
      END IF;

      COMMIT;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'End of mark records for processing...'
                           );
   END;

--**********************************************************************
--    Procedure to set stage for staging table.
--**********************************************************************
   PROCEDURE set_stage (p_stage VARCHAR2)
   IS
   BEGIN
      g_stage := p_stage;
   END set_stage;

--**********************************************************************
--    Procedure to update staging table for Routing Header
--**********************************************************************
   PROCEDURE update_staging_records (p_error_code VARCHAR2)
   IS
      x_last_update_date    DATE   := SYSDATE;
      x_last_updated_by     NUMBER := fnd_global.user_id;
      x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'update_staging_records';
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Inside update_staging_records'
                           );

      UPDATE xx_po_asl_stg
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
         xx_emf_pkg.write_log
                          (xx_emf_cn_pkg.cn_low,
                              'Error while updating staging records status: '
                           || SQLERRM
                          );
   END update_staging_records;

--**********************************************************************
--    Function to Find Max
--**********************************************************************
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

--**********************************************************************
--    Function for pre validations
--**********************************************************************
   FUNCTION pre_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

--**********************************************************************
--    Function to validate the Routing Header data
--**********************************************************************
   FUNCTION data_validation (
      p_cnv_hdr_rec   IN OUT   xx_po_asl_conv_pkg.g_asl_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER                  := xx_emf_cn_pkg.cn_success;
      x_using_org_code    mtl_parameters.organization_code%TYPE       := NULL;
      x_using_org_id      mtl_parameters.organization_id%TYPE         := NULL;
      x_owning_org_code   mtl_parameters.organization_code%TYPE       := NULL;
      X_OWNING_ORG_ID     MTL_PARAMETERS.ORGANIZATION_ID%TYPE         := NULL;
      x_ou_org_code       hr_operating_units.name%TYPE       := NULL;
      x_ou_org_id         hr_operating_units.ORGANIZATION_ID%TYPE         := NULL;
      x_item_exists       VARCHAR2 (1)                                := NULL;
      x_item_id           mtl_system_items_b.inventory_item_id%TYPE   := NULL;
      x_vendor_num        ap_suppliers.segment1%TYPE                  := NULL;
      x_vendor_id         ap_suppliers.vendor_id%TYPE                 := NULL;
      X_ASL_STATUS        PO_ASL_STATUSES.STATUS%type                 := null;
      x_org_id NUMBER := FND_PROFILE.value ('ORG_ID');

      ---------------- Validate Using Organization Code ------------------
     /* FUNCTION is_using_org_valid (
         p_using_org_code   IN       VARCHAR2,
         p_using_org_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Using Organization Code'
                              );
         x_using_org_code :=
            xx_intg_common_pkg.get_mapping_value
                                       (p_mapping_type        => 'SITE_NAME',
                                        p_old_value           => p_using_org_code,
                                        p_date_effective      => SYSDATE
                                       );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'derived value of  x_using_org_code: '
                               || x_using_org_code
                              );

         SELECT organization_id
           INTO x_using_org_id
           FROM mtl_parameters
          WHERE organization_code = x_using_org_code;

         p_using_org_id := x_using_org_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_valid,
                     p_error_text               => 'Invalid Using Organization Code => ',
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                     p_record_identifier_3      => p_using_org_code
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_valid,
                     p_error_text               => 'Invalid Using Organization Code',
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                     p_record_identifier_3      => p_using_org_code
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                          (xx_emf_cn_pkg.cn_low,
                              'Errors In Using Organization Code Validation '
                           || SQLCODE
                          );
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_valid,
                     p_error_text               =>    'Invalid Using Organization Code',
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                     p_record_identifier_3      =>  p_using_org_code
                    );
            RETURN x_error_code;
      END is_using_org_valid;*/

      ---------------- Validate Owning Organization Code ------------------
      FUNCTION is_owning_org_valid (
         p_owning_org_code   IN       VARCHAR2,
         p_owning_org_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Owning Organization Code'
                              );
         x_owning_org_code :=
            xx_intg_common_pkg.get_mapping_value
                                       (p_mapping_type        => 'SITE_NAME',
                                        p_old_value           => p_owning_org_code,
                                        p_date_effective      => SYSDATE
                                       );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'derived value of  x_using_org_code: '
                               || x_owning_org_code
                              );

         SELECT organization_id
           INTO x_owning_org_id
           FROM mtl_parameters
          WHERE organization_code = x_owning_org_code;

         p_owning_org_id := x_owning_org_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_valid,
                    p_error_text               =>    'Invalid Owning Organization Code ',
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                    p_record_identifier_3      => p_owning_org_code
                   );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_valid,
                    p_error_text               =>    'Invalid Owning Organization Code ',
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                    p_record_identifier_3      => p_owning_org_code
                   );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'Errors In Owning Organization Code Validation '
                          || SQLCODE
                         );
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_valid,
                    p_error_text               =>    'Invalid Owning Organization Code ',
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                    p_record_identifier_3      => p_owning_org_code
                   );
            RETURN x_error_code;
      END is_owning_org_valid;

    FUNCTION IS_OU_ORG_VALID (
         P_USING_ORG_CODE   IN       VARCHAR2,
         p_ou_org_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for OU Organization Code'
                              );
         x_ou_org_code :=
            XX_INTG_COMMON_PKG.GET_MAPPING_VALUE
                                       (P_MAPPING_TYPE        => 'OU_MAPPING',
                                        p_old_value           => p_using_org_code,
                                        p_date_effective      => SYSDATE
                                       );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'derived value of  x_ou_org_code: '
                               || x_ou_org_code
                              );

         SELECT ORGANIZATION_ID
           INTO x_ou_org_id
           FROM hr_operating_units
          WHERE name = x_ou_org_code;

         p_ou_org_id := x_ou_org_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_valid,
                    p_error_text               =>    'Invalid OU Organization Code ',
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    P_RECORD_IDENTIFIER_2      => P_CNV_HDR_REC.ITEM_NUM,
                    p_record_identifier_3      => P_USING_ORG_CODE
                   );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    P_CATEGORY                 => XX_EMF_CN_PKG.CN_VALID,
                    p_error_text               =>    'Invalid OU Organization Code ',
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    P_RECORD_IDENTIFIER_2      => P_CNV_HDR_REC.ITEM_NUM,
                    p_record_identifier_3      => P_USING_ORG_CODE
                   );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                         (XX_EMF_CN_PKG.CN_LOW,
                             'Errors In OU Organization Code Validation '
                          || SQLCODE
                         );
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    P_CATEGORY                 => XX_EMF_CN_PKG.CN_VALID,
                    p_error_text               =>    'Invalid OU Organization Code ',
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    P_RECORD_IDENTIFIER_2      => P_CNV_HDR_REC.ITEM_NUM,
                    p_record_identifier_3      => P_USING_ORG_CODE
                   );
            RETURN X_ERROR_CODE;
      END is_ou_org_valid;


      ---------------- Validate Item Number ------------------
      FUNCTION is_item_num_valid (p_item_num IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Item Number'
                              );

         SELECT 'Y'
           INTO x_item_exists
           FROM mtl_system_items_b
          WHERE UPPER(segment1) = UPPER(p_item_num) AND ROWNUM = 1;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_valid,
                     p_error_text               => 'Invalid Item Number ',
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                     p_record_identifier_3      => p_item_num
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_valid,
                     p_error_text               => 'Invalid Item Number ',
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                     p_record_identifier_3      => p_item_num
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Item Number Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_valid,
                     p_error_text               => 'Invalid Item Number ',
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                     p_record_identifier_3      => p_item_num
                    );
            RETURN x_error_code;
      END is_item_num_valid;

      ---------------- Validate Item - Org Combination ------------------
      FUNCTION is_item_org_combination_valid (
         p_item_num   IN       VARCHAR2,
         p_item_id    OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      'Validation for Item Number - Organization combination'
                     );

         SELECT inventory_item_id
           INTO x_item_id
           from MTL_SYSTEM_ITEMS_B
          WHERE UPPER(segment1) = UPPER(p_item_num) AND organization_id = x_owning_org_id;

         p_item_id := x_item_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_valid,
                p_error_text               =>    'Invalid Item Number - Organization combination',
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                p_record_identifier_3      => p_item_num||' - '||x_owning_org_id
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_valid,
                p_error_text               =>    'Invalid Item Number - Organization combination',
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                p_record_identifier_3      => p_item_num||' - '||x_owning_org_id
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   'Errors In Item Number - Organization combination Validation '
                || SQLCODE
               );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_valid,
                p_error_text               =>    'Invalid Item Number - Organization combination',
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                p_record_identifier_3      => p_item_num||' - '||x_owning_org_id
               );
            RETURN x_error_code;
      END is_item_org_combination_valid;

      ---------------- Validate Item Purchasing Attribute ------------------
      FUNCTION is_item_purchasing_att_valid (p_item_num IN VARCHAR)
         RETURN NUMBER
      IS
         x_error_code     NUMBER := xx_emf_cn_pkg.cn_success;
         x_item_pur_att   NUMBER;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Item Purchasing Attribute'
                              );

         SELECT 1
           into X_ITEM_PUR_ATT
           FROM mtl_system_items_b
          where INVENTORY_ITEM_ID = X_ITEM_ID
            AND organization_id = x_owning_org_id
            AND purchasing_item_flag = 'Y'
            AND purchasing_enabled_flag = 'Y';

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_valid,
                   p_error_text               => 'Invalid Item Purchasing Attribute ',
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                   p_record_identifier_3      => p_item_num
                  );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_valid,
                   p_error_text               => 'Invalid Item Purchasing Attribute ',
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                   p_record_identifier_3      => p_item_num
                  );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'Errors In Item Purchasing Attribute Validation '
                         || SQLCODE
                        );
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_valid,
                   p_error_text               => 'Invalid Item Purchasing Attribute ',
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.old_vendor_num,
                   p_record_identifier_3      => p_item_num
                  );
            RETURN x_error_code;
      END is_item_purchasing_att_valid;

      ---------------- Validate ASL Status ------------------
      FUNCTION is_asl_status_valid (
         p_asl_status      IN       VARCHAR2,
         p_asl_status_id   OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for ASL Status'
                              );
         x_asl_status := p_asl_status;

         SELECT status_id
           INTO p_asl_status_id
           FROM po_asl_statuses
          WHERE status = x_asl_status;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                         p_error_text               =>    'Invalid ASL Status => ',
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                         p_record_identifier_3      => x_asl_status
                        );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               =>    'Invalid ASL Status => ',
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                         p_record_identifier_3      => x_asl_status
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In ASL Status Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                          p_error_text               =>    'Invalid ASL Status => ',
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.item_num,
                         p_record_identifier_3      => x_asl_status
                        );
            RETURN x_error_code;
      END is_asl_status_valid;

      ---------------- Validate Supplier ------------------
      FUNCTION is_supp_valid (
         p_vendor_name    IN       VARCHAR2,
         p_vendor_id         OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validation for Supplier'
                              );

         SELECT vendor_id, segment1
           INTO x_vendor_id, x_vendor_num
           FROM AP_SUPPLIERS
           where upper(vendor_name) = UPPER(p_vendor_name)
         -- WHERE ATTRIBUTE2 LIKE '%' || P_OLD_VENDOR_NUM || '%' 
         --   AND attribute1 like '%' || p_source_sys_name || '%' 
            AND enabled_flag = 'Y'
            AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE - 1)
                            AND NVL (end_date_active, SYSDATE + 1);

         p_vendor_id := x_vendor_id;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                         p_error_text               =>    'Invalid Supplier ',
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_vendor_name,
                         p_record_identifier_3      => p_vendor_name
                        );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                         p_error_text               =>    'Invalid Supplier ',
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_vendor_name,
                         p_record_identifier_3      => p_vendor_name
                        );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In Supplier Validation ' || SQLCODE
                                 );
            xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_valid,
                         p_error_text               =>    'Invalid Supplier ',
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_vendor_name,
                         p_record_identifier_3      => p_vendor_name
                        );
            RETURN x_error_code;
      END is_supp_valid;

      ---------------- Validate Supplier Site ------------------
      FUNCTION is_supp_site_valid (
         P_VENDOR_ADDRESS   IN       VARCHAR2,
         p_ou_organization_id IN NUMBER,
         p_vendor_site_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         XX_EMF_PKG.WRITE_LOG (XX_EMF_CN_PKG.CN_LOW,
                               'Validation for Supplier Site ORG ID ' || x_org_id
                              );

         SELECT vendor_site_id
           INTO p_vendor_site_id
           FROM ap_supplier_sites_all
          WHERE vendor_id = x_vendor_id
            and ORG_ID = p_ou_organization_id
            and inactive_date is null
            and UPPER(SUBSTR(replace((ADDRESS_LINE1||ADDRESS_LINES_ALT||ADDRESS_LINE2||ADDRESS_LINE3||CITY||STATE||ZIP||COUNTRY),' ',''),1,15)) = UPPER(SUBSTR(replace(P_VENDOR_ADDRESS,' ',''),1,15));
            
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_valid,
                        p_error_text               =>    'Invalid Supplier Site',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_vendor_address,
                        p_record_identifier_3      => p_vendor_address
                       );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_valid,
                        p_error_text               =>    'Invalid Supplier Site',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_vendor_address,
                        p_record_identifier_3      => p_vendor_address
                       );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Supplier Site Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
                       (p_severity                 => xx_emf_cn_pkg.cn_medium,
                        p_category                 => xx_emf_cn_pkg.cn_valid,
                        p_error_text               =>    'Invalid Supplier Site',
                        p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                        p_record_identifier_2      => p_vendor_address,
                        p_record_identifier_3      => p_vendor_address
                       );
            RETURN x_error_code;
      END is_supp_site_valid;
   BEGIN
      g_api_name := 'Data_validation';
      XX_EMF_PKG.WRITE_LOG (XX_EMF_CN_PKG.CN_LOW, 'Inside Data-Validations');
    /*  x_error_code_temp :=
         is_using_org_valid (p_cnv_hdr_rec.using_organization,
                             p_cnv_hdr_rec.using_organization_id
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);*/
      x_error_code_temp :=
         is_owning_org_valid (p_cnv_hdr_rec.owning_organization,
                              p_cnv_hdr_rec.owning_organization_id
                             );
      X_ERROR_CODE := FIND_MAX (X_ERROR_CODE, X_ERROR_CODE_TEMP);
      X_ERROR_CODE_TEMP :=
         IS_OU_ORG_VALID (P_CNV_HDR_REC.OWNING_ORGANIZATION,
                              P_CNV_HDR_REC.OU_ORGANIZATION_ID
                             );                                   --added by Omkar
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp := is_item_num_valid (p_cnv_hdr_rec.item_num);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_item_org_combination_valid (p_cnv_hdr_rec.item_num,
                                        p_cnv_hdr_rec.item_id
                                       );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
                         is_item_purchasing_att_valid (p_cnv_hdr_rec.item_num);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_asl_status_valid (p_cnv_hdr_rec.asl_status,
                              p_cnv_hdr_rec.asl_status_id
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_supp_valid (p_cnv_hdr_rec.vendor_name,          --added by Omkar
                        p_cnv_hdr_rec.vendor_id
                       );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         IS_SUPP_SITE_VALID (P_CNV_HDR_REC.VENDOR_ADDRESS,
                             p_cnv_hdr_rec.ou_organization_id,        -- added by Omkar
                             p_cnv_hdr_rec.vendor_site_id
                            );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END data_validation;

--**********************************************************************
--  Function for Approved Supplier List Derivations
--**********************************************************************
   FUNCTION data_derivations (
      p_cnv_hdr_rec   IN OUT   xx_po_asl_conv_pkg.g_asl_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_api_name := 'data_derivations';
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END data_derivations;

--**********************************************************************
--    Function for post validation
--**********************************************************************
   FUNCTION post_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      g_api_name := 'main.post_validations';
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '8');
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '9');
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '9');
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Completed ASL Post-Validations'
                              );
   END post_validations;

--**********************************************************************
--    Procedure to count staging table record for Routing Headers
--**********************************************************************
   PROCEDURE update_record_count (pr_validate_and_load IN VARCHAR2)
   IS
      CURSOR c_get_total_cnt
      IS
         SELECT COUNT (1) total_count
           FROM xx_po_asl_stg
          WHERE batch_id = g_batch_id
                AND request_id = xx_emf_pkg.g_request_id;

      x_total_cnt     NUMBER;

      CURSOR c_get_error_cnt
      IS
         SELECT SUM (error_count)
           FROM (SELECT COUNT (1) error_count
                   FROM xx_po_asl_stg
                  WHERE batch_id = g_batch_id
                    AND request_id = xx_emf_pkg.g_request_id
                    AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_err);

      x_error_cnt     NUMBER;

      CURSOR c_get_warning_cnt
      IS
         SELECT COUNT (1) warn_count
           FROM xx_po_asl_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            AND ERROR_CODE = xx_emf_cn_pkg.cn_rec_warn;

      x_warn_cnt      NUMBER;

      CURSOR c_get_success_cnt
      IS
         SELECT COUNT (1) success_count
           FROM xx_po_asl_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            --AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;

      x_success_cnt   NUMBER;

      -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
      CURSOR c_get_success_valid_cnt
      IS
         SELECT COUNT (1) success_count
           FROM xx_po_asl_stg
          WHERE batch_id = g_batch_id
            AND request_id = xx_emf_pkg.g_request_id
            --AND process_code = xx_emf_cn_pkg.CN_POSTVAL
            AND ERROR_CODE = xx_emf_cn_pkg.cn_success;
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

      IF pr_validate_and_load = g_validate_and_load
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

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'ASL record processing status - '
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' x_total_cnt : ' || x_total_cnt
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' x_success_cnt : ' || x_success_cnt
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' x_warn_cnt : ' || x_warn_cnt
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            ' x_error_cnt : ' || x_error_cnt
                           );
      xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                  p_success_recs_cnt      => x_success_cnt,
                                  p_warning_recs_cnt      => x_warn_cnt,
                                  p_error_recs_cnt        => x_error_cnt
                                 );
   END update_record_count;

--**********************************************************************
--                Main Procedure
--**********************************************************************
   PROCEDURE main (
      x_errbuf              OUT      VARCHAR2,
      x_retcode             OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2
   )
   IS
      ----------------------- Private Variable Declaration Section -----------------------
      --Stop the program with EMF error header insertion fails
      l_process_status    NUMBER;
      x_error_code        NUMBER         := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER         := xx_emf_cn_pkg.cn_success;
      x_asl_table         g_asl_tbl_type;

      CURSOR c_asl_stg (cp_process_status VARCHAR2)
      IS
         SELECT   *
             FROM xx_po_asl_stg
            WHERE batch_id = g_batch_id
              AND request_id = xx_emf_pkg.g_request_id
              AND process_code = cp_process_status
              AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
         ORDER BY record_number;

--**********************************************************************
--    Procedure to update Routing Header error record status
--**********************************************************************
      PROCEDURE upd_rec_status_asl (
         p_conv_hdr_rec   IN OUT   g_asl_rec_type,
         p_error_code     IN       VARCHAR2
      )
      IS
      BEGIN
         g_api_name := 'main.upd_rec_status_asl';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside of update asl record status...'
                              );

         IF p_error_code IN
                         (xx_emf_cn_pkg.cn_rec_err, xx_emf_cn_pkg.cn_prc_err)
         THEN
            p_conv_hdr_rec.ERROR_CODE := xx_emf_cn_pkg.cn_rec_err;
         ELSE
            p_conv_hdr_rec.ERROR_CODE :=
               xx_intg_common_pkg.find_max (p_error_code,
                                            NVL (p_conv_hdr_rec.ERROR_CODE,
                                                 xx_emf_cn_pkg.cn_success
                                                )
                                           );
         END IF;

         p_conv_hdr_rec.process_code := g_stage;
      END upd_rec_status_asl;

--**********************************************************************
--        Procedure to update Routing Header staging records
--**********************************************************************
      PROCEDURE update_int_records_asl (p_cnv_asl_table IN g_asl_tbl_type)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         indx                  NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.update_int_records_asl';

         FOR indx IN 1 .. p_cnv_asl_table.COUNT
         LOOP
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'p_cnv_asl_table(indx).process_code '
                                  || p_cnv_asl_table (indx).process_code
                                 );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'p_cnv_asl_table(indx).error_code '
                                  || p_cnv_asl_table (indx).ERROR_CODE
                                 );

            UPDATE xx_po_asl_stg
               SET asl_id = p_cnv_asl_table (indx).asl_id,
                   using_organization =
                                     p_cnv_asl_table (indx).using_organization,
                   using_organization_id =
                                  p_cnv_asl_table (indx).using_organization_id,
                   owning_organization =
                                    p_cnv_asl_table (indx).owning_organization,
                   owning_organization_id =
                                 P_CNV_ASL_TABLE (INDX).OWNING_ORGANIZATION_ID,
                    OU_ORGANIZATION_ID =
                                 p_cnv_asl_table (indx).ou_organization_id, --Added by Omkar
                   vendor_business_type =
                                   p_cnv_asl_table (indx).vendor_business_type,
                   asl_status = p_cnv_asl_table (indx).asl_status,
                   asl_status_id = p_cnv_asl_table (indx).asl_status_id,
                   old_vendor_num = p_cnv_asl_table (indx).old_vendor_num,
                   vendor_id = p_cnv_asl_table (indx).vendor_id,
                   vendor_site_code = p_cnv_asl_table (indx).vendor_site_code,
                   vendor_site_id = p_cnv_asl_table (indx).vendor_site_id,
                   item_num = p_cnv_asl_table (indx).item_num,
                   item_id = p_cnv_asl_table (indx).item_id,
                   item_category = p_cnv_asl_table (indx).item_category,
                   category_id = p_cnv_asl_table (indx).category_id,
                   primary_vendor_item =
                                    p_cnv_asl_table (indx).primary_vendor_item,
                   attribute_category =
                                     p_cnv_asl_table (indx).attribute_category,
                   attribute1 = p_cnv_asl_table (indx).attribute1,
                   attribute2 = p_cnv_asl_table (indx).attribute2,
                   attribute3 = p_cnv_asl_table (indx).attribute3,
                   attribute4 = p_cnv_asl_table (indx).attribute4,
                   attribute5 = p_cnv_asl_table (indx).attribute5,
                   attribute6 = p_cnv_asl_table (indx).attribute6,
                   attribute7 = p_cnv_asl_table (indx).attribute7,
                   attribute8 = p_cnv_asl_table (indx).attribute8,
                   attribute9 = p_cnv_asl_table (indx).attribute9,
                   attribute10 = p_cnv_asl_table (indx).attribute10,
                   attribute11 = p_cnv_asl_table (indx).attribute11,
                   attribute12 = p_cnv_asl_table (indx).attribute12,
                   attribute13 = p_cnv_asl_table (indx).attribute13,
                   attribute14 = p_cnv_asl_table (indx).attribute14,
                   attribute15 = p_cnv_asl_table (indx).attribute15,
                   disable_flag = p_cnv_asl_table (indx).disable_flag,
                   batch_id = p_cnv_asl_table (indx).batch_id,
                   record_number = p_cnv_asl_table (indx).record_number,
                   process_code = p_cnv_asl_table (indx).process_code,
                   ERROR_CODE = p_cnv_asl_table (indx).ERROR_CODE,
                   request_id = p_cnv_asl_table (indx).request_id,
                   program_id = p_cnv_asl_table (indx).program_id,
                   program_application_id =
                                 p_cnv_asl_table (indx).program_application_id,
                   program_update_date =
                                    p_cnv_asl_table (indx).program_update_date,
                   creation_date = p_cnv_asl_table (indx).creation_date,
                   created_by = p_cnv_asl_table (indx).created_by,
                   last_update_date = p_cnv_asl_table (indx).last_update_date,
                   last_updated_by = p_cnv_asl_table (indx).last_updated_by,
                   last_update_login =
                                      p_cnv_asl_table (indx).last_update_login
             WHERE record_number = p_cnv_asl_table (indx).record_number
               AND batch_id = g_batch_id;
         END LOOP;

         COMMIT;
      END update_int_records_asl;

--**********************************************************************
--        Procedure to mark records complete for credit card conversion
--**********************************************************************
      PROCEDURE mark_records_complete (p_process_code VARCHAR2)
      IS
         x_last_update_date    DATE   := SYSDATE;
         x_last_updated_by     NUMBER := fnd_global.user_id;
         x_last_update_login   NUMBER
                             := fnd_profile.VALUE (xx_emf_cn_pkg.cn_login_id);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.mark_records_complete';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '10');            --**DS
         xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                      'Inside of mark records complete for ASL Conversion...'
                     );

         UPDATE xx_po_asl_stg                                         --Header
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
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Error in Update of mark_records_complete '
                               || SQLERRM
                              );
      END mark_records_complete;

--***********************************************************************************************
--        Function to call standard APIs to load Approved Supplier List data into Oracle tables
--***********************************************************************************************
      FUNCTION process_data
         RETURN NUMBER
      IS
         --cursor to select approved supplier list data
         CURSOR c_xx_asl_data (cp_process_status VARCHAR2)
         IS
            SELECT   *
                FROM xx_po_asl_stg
               WHERE batch_id = g_batch_id
                 AND request_id = xx_emf_pkg.g_request_id
                 AND process_code = cp_process_status
                 AND ERROR_CODE IN
                        (xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn)
            ORDER BY record_number;

         x_process_code    VARCHAR2 (30);
         x_error_code      NUMBER;
         x_return_code     VARCHAR2 (15)           := xx_emf_cn_pkg.cn_success;
         p_init_msg_list   VARCHAR2 (200)                    := fnd_api.g_true;
         x_msg_count       NUMBER                                := 2;
         x_msg_data        VARCHAR2 (2000);
         x_return_status   VARCHAR2 (15)           := xx_emf_cn_pkg.cn_success;
         l_msg_index_out   VARCHAR2 (400);
         l_result_code     VARCHAR2 (60);
         o_rowid           ROWID;
         o_asl_id          NUMBER;
         l_result_rec      iby_fndcpt_common_pub.result_rec_type;
         l_assignment_id   NUMBER;
         x_msg             VARCHAR2 (2000);
         x_record_skip     EXCEPTION;
      BEGIN
         mo_global.init ('PO');
         g_api_name := 'main.process_data';
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Process Data');

         FOR r_xx_asl_data IN c_xx_asl_data (xx_emf_cn_pkg.cn_postval)
         LOOP
            BEGIN
               xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                 'Before Approved Supplier List Creation....'
                                );
               ---
               x_return_status := NULL;
               x_msg_count := NULL;
               x_msg_data := NULL;
               l_msg_index_out := NULL;
               o_rowid:=NULL;
               o_asl_id := NULL;
               ---
               --
               --Creation of Approved Supplier List using Oracle Standard PO API.
               --
               po_asl_ths.insert_row
                  (x_row_id                      => o_rowid,
                   x_asl_id                      => o_asl_id,
                   x_using_organization_id       => r_xx_asl_data.using_organization_id,
                   x_owning_organization_id      => r_xx_asl_data.owning_organization_id,
                   x_vendor_business_type        => 'DIRECT',
                   x_asl_status_id               => r_xx_asl_data.asl_status_id,
                   x_last_update_date            => NVL
                                                       (TO_DATE
                                                           (r_xx_asl_data.last_update_date,
                                                            'DD/MM/RRRR HH:MI:SS AM'
                                                           ),
                                                        SYSDATE
                                                       ),
                   x_last_updated_by             => r_xx_asl_data.last_updated_by,
                   x_creation_date               => TO_DATE
                                                       (r_xx_asl_data.creation_date,
                                                        'DD/MM/RRRR HH:MI:SS AM'
                                                       ),
                   x_created_by                  => r_xx_asl_data.created_by,
                   x_manufacturer_id             => NULL,
                   x_vendor_id                   => r_xx_asl_data.vendor_id,
                   x_item_id                     => r_xx_asl_data.item_id,
                   x_category_id                 => r_xx_asl_data.category_id,
                   x_vendor_site_id              => r_xx_asl_data.vendor_site_id,
                   x_primary_vendor_item         => r_xx_asl_data.primary_vendor_item,
                   x_manufacturer_asl_id         => NULL,
                   x_comments                    => NULL,
                   x_review_by_date              => NULL,
                   x_attribute_category          => r_xx_asl_data.attribute_category,
                   x_attribute1                  => r_xx_asl_data.attribute1,
                   x_attribute2                  => r_xx_asl_data.attribute2,
                   x_attribute3                  => r_xx_asl_data.attribute3,
                   x_attribute4                  => r_xx_asl_data.attribute4,
                   x_attribute5                  => r_xx_asl_data.attribute5,
                   x_attribute6                  => r_xx_asl_data.attribute6,
                   x_attribute7                  => r_xx_asl_data.attribute7,
                   x_attribute8                  => r_xx_asl_data.attribute8,
                   x_attribute9                  => r_xx_asl_data.attribute9,
                   x_attribute10                 => r_xx_asl_data.attribute10,
                   x_attribute11                 => r_xx_asl_data.attribute11,
                   x_attribute12                 => r_xx_asl_data.attribute12,
                   x_attribute13                 => r_xx_asl_data.attribute13,
                   x_attribute14                 => r_xx_asl_data.attribute14,
                   x_attribute15                 => r_xx_asl_data.attribute15,
                   x_last_update_login           => r_xx_asl_data.last_update_login,
                   x_disable_flag                => r_xx_asl_data.disable_flag
                  );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'ASL ID='
                                     || o_asl_id
                                     || ' record_number: '
                                     || r_xx_asl_data.record_number
                                    );
               po_asl_attributes_ths.insert_row
                  (x_row_id                            => o_rowid,
                   x_asl_id                            => o_asl_id,
                   x_using_organization_id             => r_xx_asl_data.using_organization_id,
                   x_last_update_date                  => NVL
                                                             (TO_DATE
                                                                 (r_xx_asl_data.last_update_date,
                                                                  'DD/MM/RRRR HH:MI:SS AM'
                                                                 ),
                                                              SYSDATE
                                                             ),
                   x_last_updated_by                   => r_xx_asl_data.last_updated_by,
                   x_creation_date                     => TO_DATE
                                                             (r_xx_asl_data.creation_date,
                                                              'DD/MM/RRRR HH:MI:SS AM'
                                                             ),
                   x_created_by                        => r_xx_asl_data.created_by,
                   x_document_sourcing_method          => 'ASL',
                   x_release_generation_method         => 'CREATE_AND_APPROVE',
                   x_purchasing_unit_of_measure        => NULL,
                   x_enable_plan_schedule_flag         => NULL,
                   x_enable_ship_schedule_flag         => NULL,
                   x_plan_schedule_type                => NULL,
                   x_ship_schedule_type                => NULL,
                   x_plan_bucket_pattern_id            => NULL,
                   x_ship_bucket_pattern_id            => NULL,
                   x_enable_autoschedule_flag          => NULL,
                   x_scheduler_id                      => NULL,
                   x_enable_authorizations_flag        => NULL,
                   x_vendor_id                         => r_xx_asl_data.vendor_id,
                   x_vendor_site_id                    => r_xx_asl_data.vendor_site_id,
                   x_item_id                           => r_xx_asl_data.item_id,
                   x_category_id                       => NULL,
                   x_attribute_category                => NULL,
                   x_attribute1                        => NULL,
                   x_attribute2                        => NULL,
                   x_attribute3                        => NULL,
                   x_attribute4                        => NULL,
                   x_attribute5                        => NULL,
                   x_attribute6                        => NULL,
                   x_attribute7                        => NULL,
                   x_attribute8                        => NULL,
                   x_attribute9                        => NULL,
                   x_attribute10                       => NULL,
                   x_attribute11                       => NULL,
                   x_attribute12                       => NULL,
                   x_attribute13                       => NULL,
                   x_attribute14                       => NULL,
                   x_attribute15                       => NULL,
                   x_last_update_login                 => NULL,
                   x_price_update_tolerance            => NULL,
                   x_processing_lead_time              => NULL,
                   x_delivery_calendar                 => NULL,
                   x_min_order_qty                     => NULL,
                   x_fixed_lot_multiple                => NULL,
                   x_country_of_origin_code            => NULL,
                   x_enable_vmi_flag                   => NULL,
                   x_vmi_min_qty                       => NULL,
                   x_vmi_max_qty                       => NULL,
                   x_enable_vmi_auto_repl_flag         => NULL,
                   x_vmi_replenishment_approval        => NULL,
                   x_consigned_from_supplier_flag      => NULL,
                   x_consigned_billing_cycle           => NULL,
                   x_last_billing_date                 => NULL,
                   x_replenishment_method              => NULL,
                   x_vmi_min_days                      => NULL,
                   x_vmi_max_days                      => NULL,
                   x_fixed_order_quantity              => NULL,
                   x_forecast_horizon                  => NULL,
                   x_consume_on_aging_flag             => NULL,
                   x_aging_period                      => NULL
                  );

               UPDATE xx_po_asl_stg
                  SET asl_id = o_asl_id
                WHERE record_number = r_xx_asl_data.record_number
                  AND batch_id = r_xx_asl_data.batch_id;

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_msg := NULL;
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Error for record number ='
                                        || r_xx_asl_data.record_number
                                        || SQLERRM
                                       );
--                  FOR i IN 1 .. x_msg_count
--                  LOOP
--                     fnd_msg_pub.get (p_msg_index          => i,
--                                      p_encoded            => fnd_api.g_false,
--                                      p_data               => x_msg_data,
--                                      p_msg_index_out      => l_msg_index_out
--                                     );
--                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
--                                              'x_msg_data(l_msg_index_out)='
--                                           || x_msg_data
--                                           || '('
--                                           || l_msg_index_out
--                                           || ')'
--                                          );
--                     x_msg := x_msg || x_msg_data;
--                  END LOOP;
--                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
--                                        'API error: PO_ASL_THS.insert_row'
--                                       );
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'API error for record number '
                                        || r_xx_asl_data.record_number
                                        || ' '
                                        || SQLERRM
                                       );
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
--                  xx_emf_pkg.error
--                        (p_severity                 => xx_emf_cn_pkg.cn_low,
--                         p_category                 => xx_emf_cn_pkg.cn_postval,
--                         p_error_text               =>    'After PO_ASL_THS.insert_row :'
--                                                       || ' '
--                                                       || x_msg
--                                                       || ':'
--                                                       || r_xx_asl_data.item_num,
--                         p_record_identifier_1      => r_xx_asl_data.record_number,
--                         p_record_identifier_2      => r_xx_asl_data.old_vendor_num
--                        );
--
                  xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_low,
                         p_category                 => xx_emf_cn_pkg.cn_postval,
                         p_error_text               =>    'After API :'
                                                       || ' '
                                                       || x_msg
                                                       || ':'
                                                       || r_xx_asl_data.item_num,
                         p_record_identifier_1      => r_xx_asl_data.record_number,
                         p_record_identifier_2      => r_xx_asl_data.old_vendor_num
                        );

                  --ROLLBACK;
                  UPDATE xx_po_asl_stg
                     SET ERROR_CODE = xx_emf_cn_pkg.cn_rec_err
                   WHERE batch_id = g_batch_id
                     AND record_number = r_xx_asl_data.record_number;

                  COMMIT;
            END;
         END LOOP;                          -- ending loop for asl data cursor

         RETURN x_return_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                        'Error while inserting into Standard Oracle Tables: '
                     || SQLERRM
                    );
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_high,
                     p_category                 => xx_emf_cn_pkg.cn_tech_error,
                     p_error_text               => SQLERRM,
                     p_record_identifier_3      => 'Process Approved Supplier List'
                    );
            RETURN x_error_code;
      END process_data;
   BEGIN
--Main Begin
----------------------------------------------------------------------------------------------------
--Initialize Trace
--Purpose : Set the program environment for Tracing
----------------------------------------------------------------------------------------------------
      x_retcode := xx_emf_cn_pkg.cn_success;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before Setting Environment'
                           );
      -- Set Env --
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Calling ASL conversion Set_cnv_env'
                           );
      set_cnv_env (p_batch_id, xx_emf_cn_pkg.cn_yes);
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
                               'Main:Param - p_validate_and_load '
                            || p_validate_and_load
                           );
      -- Call procedure to update records with the current request_id
      -- So that we can process only those records
      -- This gives a better handling of restartability
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Calling mark_records_for_processing..'
                           );
      mark_records_for_processing (p_restart_flag => p_restart_flag);
------------------------------------------------------------------------------
--    processing for Approved Supplier List Records
------------------------------------------------------------------------------

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.cn_preval);
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Calling xx_po_asl_conv_pkg.pre_validations ..'
                           );
      x_error_code := pre_validations;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After pre_validations X_ERROR_CODE '
                            || x_error_code
                           );
      -- Update process code of staging records
      -- Update Header and Lines Level
      update_staging_records (xx_emf_cn_pkg.cn_success);
      xx_emf_pkg.propagate_error (x_error_code);
      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.cn_valid);

      OPEN c_asl_stg (xx_emf_cn_pkg.cn_preval);

      LOOP
         FETCH c_asl_stg
         BULK COLLECT INTO x_asl_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_asl_table.COUNT
         LOOP
            BEGIN
               -- Perform Base App Validations
               x_error_code := data_validation (x_asl_table (i));
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_asl_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               upd_rec_status_asl (x_asl_table (i), x_error_code);
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
                  update_int_records_asl (x_asl_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_asl_table (i).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_asl_table.count ' || x_asl_table.COUNT
                              );
         update_int_records_asl (x_asl_table);
         x_asl_table.DELETE;
         EXIT WHEN c_asl_stg%NOTFOUND;
      END LOOP;

      IF c_asl_stg%ISOPEN
      THEN
         CLOSE c_asl_stg;
      END IF;

      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               fnd_global.conc_request_id
                            || ' : Before Data Derivations'
                           );
      -- Once data-validations are complete the loop through the pre-interface records
      -- and perform data derivations on this table
      -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.cn_derive);

      OPEN c_asl_stg (xx_emf_cn_pkg.cn_valid);

      LOOP
         FETCH c_asl_stg
         BULK COLLECT INTO x_asl_table LIMIT xx_emf_cn_pkg.cn_bulk_collect;

         FOR i IN 1 .. x_asl_table.COUNT
         LOOP
            BEGIN
               -- Perform Base App Validations
               x_error_code := data_derivations (x_asl_table (i));
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'x_error_code for  '
                                     || x_asl_table (i).record_number
                                     || ' is '
                                     || x_error_code
                                    );
               upd_rec_status_asl (x_asl_table (i), x_error_code);
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
                  update_int_records_asl (x_asl_table);
                  raise_application_error (-20199, xx_emf_cn_pkg.cn_prc_err);
               WHEN OTHERS
               THEN
                  xx_emf_pkg.error (xx_emf_cn_pkg.cn_medium,
                                    xx_emf_cn_pkg.cn_tech_error,
                                    xx_emf_cn_pkg.cn_exp_unhand,
                                    x_asl_table (i).record_number
                                   );
            END;
         END LOOP;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_asl_table.count ' || x_asl_table.COUNT
                              );
         update_int_records_asl (x_asl_table);
         x_asl_table.DELETE;
         EXIT WHEN c_asl_stg%NOTFOUND;
      END LOOP;

      IF c_asl_stg%ISOPEN
      THEN
         CLOSE c_asl_stg;
      END IF;

      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.cn_postval);
          -- Change the validations package to the appropriate package name
          -- Modify the parameters as required
          -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      x_error_code := post_validations;
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'After post-validations X_ERROR_CODE '
                            || x_error_code
                           );
      mark_records_complete (xx_emf_cn_pkg.cn_postval);
      xx_emf_pkg.write_log
          (xx_emf_cn_pkg.cn_medium,
              'After mark_records_complete_rtg post-validations X_ERROR_CODE '
           || x_error_code
          );
      xx_emf_pkg.propagate_error (x_error_code);

      -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
      IF p_validate_and_load = g_validate_and_load
      THEN
         -- Set the stage to Process
         set_stage (xx_emf_cn_pkg.cn_process_data);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,
                               'Before process_data');
         x_error_code := process_data;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium, 'After process_data');
         mark_records_complete (xx_emf_cn_pkg.cn_postval);
         xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_medium,
                      'After Process Data mark_records_complete x_error_code'
                   || x_error_code
                  );
         xx_emf_pkg.propagate_error (x_error_code);
      END IF;                                   --for validate only flag check

      update_record_count (p_validate_and_load);
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_env_not_set
      THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Checking if this is OK');
         fnd_file.put_line (fnd_file.output, xx_emf_pkg.cn_env_not_set);
         x_retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_retcode := xx_emf_cn_pkg.cn_rec_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
      WHEN OTHERS
      THEN
         x_retcode := xx_emf_cn_pkg.cn_prc_err;
         update_record_count (p_validate_and_load);
         xx_emf_pkg.create_report;
   END main;
END xx_po_asl_conv_pkg;
/
