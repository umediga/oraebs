DROP PACKAGE BODY APPS.XX_MTL_STOCKLOC_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_MTL_STOCKLOC_CONVERSION_PKG" AS
/* $Header: XXMTLSTOCKLOCCNV.pks 1.0.0 2012/03/15 00:00:00$ */ 
--=================================================================================
  -- Created By     : Arjun.K 
  -- Creation Date  : 07-MAR-2012
  -- Filename       : XXMTLSTOCKLOCCNV.pks
  -- Description    : Package specification for Inventory stock locator conversion.

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     --------------------------------
  -- 07-MAR-2012   1.0         Arjun.K             Initial Development.
  -- 29-AUG-2012   1.1         Arjun.K             Added fnd_msg_pub.initialze to 
  --                                               intialize global message table.
  -- 30-MAY-2013   1.2         Mou Mukherjee       Added source_system_name = p_stocklocstg_table(indx).source_system_name
  --                                               in the update statement in the update_staging_record procedure
--=================================================================================

   ----------------------------------------------------------------------------
   ----------------------------< set_cnv_env >---------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                         ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                         ) 
   IS
      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
      G_BATCH_ID       := p_batch_id;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID: '||G_BATCH_ID );

      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;
      IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
         xx_emf_pkg.propagate_error(x_error_code);
      END IF;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark set_cnv_env.');
   EXCEPTION
      WHEN OTHERS THEN
         RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
   END set_cnv_env;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_low >----------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_low (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low
                            ,g_api_name 
                            || ': '||
                            p_dbg_text
                           );
   END dbg_low;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_med >----------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_med (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                            ,g_api_name 
                            || ' : '||
                            p_dbg_text
                           );
   END dbg_med;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_high >---------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_high (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                            ,g_api_name 
                            || ' : '||
                            p_dbg_text
                           );
   END dbg_high;

   ----------------------------------------------------------------------------
   ---------------------< mark_records_for_processing >------------------------
   ----------------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'mark_records_for_processing';
      dbg_low('Inside of mark records for processing...');
      IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN
         UPDATE xx_mtl_stock_locator_stg -- Stock Locator Staging Table
            SET request_id = xx_emf_pkg.G_REQUEST_ID,
                error_code = xx_emf_cn_pkg.CN_NULL,
                process_code = xx_emf_cn_pkg.CN_NEW
          WHERE batch_id = G_BATCH_ID;
            --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);
      ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN
         UPDATE xx_mtl_stock_locator_stg
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_NULL,
                process_code = xx_emf_cn_pkg.CN_NEW
          WHERE batch_id = G_BATCH_ID
            AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN
                (xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);
      END IF;
      COMMIT;
      dbg_low('End of mark records for processing.');
   END mark_records_for_processing;

   ----------------------------------------------------------------------------
   ------------------------------< set_stage >---------------------------------
   ----------------------------------------------------------------------------
    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
       G_STAGE := p_stage;
    END set_stage;

   ----------------------------------------------------------------------------
   ------------------------< update_staging_records >--------------------------
   ----------------------------------------------------------------------------
   PROCEDURE update_staging_records( p_error_code VARCHAR2) 
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'update_staging_records';
      dbg_low('Inside update_staging_records...');

      UPDATE xx_mtl_stock_locator_stg
         SET process_code = G_STAGE,
             error_code = DECODE ( error_code, NULL, p_error_code, error_code),
             last_update_date = x_last_update_date,
             last_updated_by   = G_USER_ID,
             last_update_login = x_last_update_login -- In template please make change
       WHERE batch_id = G_BATCH_ID
         AND request_id = xx_emf_pkg.G_REQUEST_ID
         AND process_code = xx_emf_cn_pkg.CN_NEW;-- To dynamically change process at different stages (pre-val/data-deri)

      COMMIT;
      dbg_low('End of update staging records.');
   EXCEPTION
      WHEN OTHERS THEN
         dbg_low('Error while updating staging records status: '||SQLERRM);
   END update_staging_records;

   ----------------------------------------------------------------------------
   -------------------------------< find_max >---------------------------------
   ----------------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2,
                      p_error_code2 IN VARCHAR2
                     )
   RETURN VARCHAR2
   IS
      x_return_value VARCHAR2(100);
   BEGIN
      x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);
    RETURN x_return_value;
   END find_max;

   ----------------------------------------------------------------------------
   ----------------------------< pre_validations >-----------------------------
   ----------------------------------------------------------------------------
   FUNCTION pre_validations
   RETURN NUMBER
   IS
      x_error_code      NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      g_api_name := 'pre_validations';
      dbg_low('Inside pre_validations');
      dbg_low('End of pre validations.');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

   ----------------------------------------------------------------------------
   ----------------------------< data_validations >----------------------------
   ----------------------------------------------------------------------------
   FUNCTION data_validations(csr_stockloc_stg_rec IN OUT xx_mtl_stockloc_conversion_pkg.G_XXMTL_STOCKLOC_STG_REC_TYPE)
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      
      -------------------------------------------------------------------------------
      ------------------------------<validate_duplicate_data>------------------------
      -------------------------------------------------------------------------------
      FUNCTION validate_duplicate_data ( p_org_code     IN NUMBER
                                        ,p_conc_segment IN VARCHAR2
                                       )
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

         CURSOR xx_st_loc_dup_rec_cur
         IS
            SELECT mil.segment1
                  ,mil.segment2
                  ,mil.segment3
                  ,mp.organization_code
              FROM mtl_item_locations mil
                  ,mtl_parameters mp
             WHERE mp.organization_id = mil.organization_id;

         TYPE xx_dup_tbl IS TABLE OF xx_st_loc_dup_rec_cur%ROWTYPE
         INDEX BY BINARY_INTEGER;

         xx_dup_rec     xx_dup_tbl;

      BEGIN
         OPEN xx_st_loc_dup_rec_cur;
         FETCH xx_st_loc_dup_rec_cur BULK COLLECT INTO xx_dup_rec;
         CLOSE xx_st_loc_dup_rec_cur;
         dbg_low('count'||xx_dup_rec.COUNT);

         IF NVL(xx_dup_rec.COUNT,0) > 0 THEN
            FOR i IN 1 .. xx_dup_rec.COUNT
            LOOP
               IF xx_dup_rec(i).segment1||'.'||xx_dup_rec(i).segment2||'.'||xx_dup_rec(i).segment3 = p_conc_segment 
                  AND xx_dup_rec(i).organization_code = p_org_code 
               THEN 
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (p_severity            => xx_emf_cn_pkg.cn_low
                                ,p_category            => 'DUP-VAL001'
                                ,p_error_text          => 'Locator already exists.'
                                ,p_record_identifier_1 => csr_stockloc_stg_rec.record_number
                                ,p_record_identifier_2 => p_conc_segment
                                ,p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                                );
               END IF;
            END LOOP;
         END IF;
            RETURN x_error_code;
      EXCEPTION
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      END validate_duplicate_data;

      ----------------------------------------------------------------------------
      ---------------------< dff_locator_segment1_is_valid >----------------------
      ----------------------------------------------------------------------------
      FUNCTION locator_type_is_valid(p_dff_locator_segment1  IN OUT   VARCHAR2)
      RETURN NUMBER
      IS
         x_error_code           NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        BEGIN
           SELECT ffvt.flex_value_meaning
             INTO p_dff_locator_segment1
             FROM fnd_flex_values ffv
                 ,fnd_flex_value_sets ffvs
                 ,fnd_flex_values_tl ffvt
            WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
              AND ffvs.flex_value_set_name = G_LOCATOR_TYPE
              AND ffv.enabled_flag ='Y'
              AND ffv.flex_value_id = ffvt.flex_value_id
              AND UPPER(ffvt.flex_value_meaning) = UPPER(p_dff_locator_segment1)
              AND language = USERENV ('LANG');
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dff_locator_segment1 :=NULL;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dff_locator_segment1 :=NULL;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dff_locator_segment1 :=NULL;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END locator_type_is_valid;

      ----------------------------------------------------------------------------
      ----------------------------< class_is_valid >------------------------------
      ----------------------------------------------------------------------------
      FUNCTION class_is_valid(p_dff_locator_segment2  IN OUT   VARCHAR2)
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        BEGIN
           SELECT ffvt.flex_value_meaning
             INTO p_dff_locator_segment2
             FROM fnd_flex_values ffv
                 ,fnd_flex_value_sets ffvs
                 ,fnd_flex_values_tl ffvt
            WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
              AND ffvs.flex_value_set_name = G_LOCATOR_CLASS
              AND ffv.enabled_flag ='Y'
              AND ffv.flex_value_id = ffvt.flex_value_id
              AND UPPER(ffvt.flex_value_meaning) = UPPER(p_dff_locator_segment2)
              AND language = USERENV ('LANG');
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dff_locator_segment2 := NULL;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dff_locator_segment2 := NULL;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dff_locator_segment2 := NULL;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END class_is_valid;

      ----------------------------------------------------------------------------
      ------------------------< dimension_uom_is_valid >--------------------------
      ----------------------------------------------------------------------------
      FUNCTION dimension_uom_is_valid(p_dimension_uom  IN OUT   VARCHAR2)
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        BEGIN
           SELECT uom_code
             INTO p_dimension_uom
             FROM mtl_units_of_measure_tl
            WHERE uom_code = UPPER(p_dimension_uom)
              AND language = USERENV ('LANG');
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dimension_uom := NULL;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dimension_uom := NULL;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_dimension_uom := NULL;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END dimension_uom_is_valid;

   BEGIN
      g_api_name := 'data_validations';
      dbg_low('Inside data_validations');

      x_error_code_temp := validate_duplicate_data( csr_stockloc_stg_rec.organization_code
                                                   ,csr_stockloc_stg_rec.conc_segment);
      x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );

      IF csr_stockloc_stg_rec.dff_locator_segment1 IS NOT NULL THEN
         -- To validate locator type
         x_error_code_temp := locator_type_is_valid(csr_stockloc_stg_rec.dff_locator_segment1);
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_stockloc_stg_rec.dff_locator_segment1 IS NULL THEN
            dbg_low('Locator Type not valid');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'LOCTYP-VAL001',
                             p_error_text => 'E:'||'Locator Type not valid',
                             p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                             p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                             p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                            ); 
         END IF;
      END IF;

      IF csr_stockloc_stg_rec.dff_locator_segment2 IS NOT NULL THEN
         -- To validate locator class
         x_error_code_temp := class_is_valid(csr_stockloc_stg_rec.dff_locator_segment2);
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_stockloc_stg_rec.dff_locator_segment2 IS NULL THEN
            dbg_low('Locator Class not valid');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'LOCCLS-VAL002',
                             p_error_text => 'E:'||'Locator Class not valid',
                             p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                             p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                             p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                            ); 
         END IF;
      END IF;
      IF csr_stockloc_stg_rec.dimension_uom IS NOT NULL THEN
         -- To validate dimension uom
         x_error_code_temp := dimension_uom_is_valid(csr_stockloc_stg_rec.dimension_uom);
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_stockloc_stg_rec.dimension_uom IS NULL THEN
            dbg_low('Dimension UOM not valid');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'DIMUOM-VAL003',
                             p_error_text => 'E:'||'Dimension UOM not valid',
                             p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                             p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                             p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                            ); 
         END IF;
      END IF;
      dbg_low('End of data validations.');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END data_validations;

   ----------------------------------------------------------------------------
   ----------------------------< data_derivations >----------------------------
   ----------------------------------------------------------------------------
   FUNCTION data_derivations(csr_stockloc_stg_rec IN OUT xx_mtl_stockloc_conversion_pkg.G_XXMTL_STOCKLOC_STG_REC_TYPE)
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

      ----------------------------------------------------------------------------
      --------------------------< get_organiztion_id >----------------------------
      ----------------------------------------------------------------------------
      FUNCTION get_organiztion_id(p_organiztion_code    IN          VARCHAR2
                                 ,p_organiztion_id      OUT NOCOPY  NUMBER
                                 ) 
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        p_organiztion_id := NULL;
        BEGIN
           SELECT organization_id
             INTO p_organiztion_id
             FROM mtl_parameters
            WHERE organization_code = p_organiztion_code;
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END get_organiztion_id;

      ----------------------------------------------------------------------------
      -------------------------< get_subinventory_code >--------------------------
      ----------------------------------------------------------------------------
      FUNCTION get_subinventory_code(p_organiztion_id       IN       NUMBER
                                    ,p_subinventory_code    IN OUT   VARCHAR2
                                    ) 
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        BEGIN
           SELECT secondary_inventory_name
             INTO p_subinventory_code
             FROM mtl_secondary_inventories
            WHERE organization_id = p_organiztion_id
              AND UPPER(secondary_inventory_name) = UPPER(p_subinventory_code);
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_subinventory_code := NULL;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_subinventory_code := NULL;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_subinventory_code := NULL;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END get_subinventory_code;

      ----------------------------------------------------------------------------
      -----------------------------< get_status_id >------------------------------
      ----------------------------------------------------------------------------
      FUNCTION get_status_id(p_status_code       IN       VARCHAR2
                            ,p_status_id         OUT      NUMBER
                            ) 
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        p_status_id := NULL;
        BEGIN
           SELECT status_id
             INTO p_status_id
             FROM mtl_material_statuses
            WHERE status_code = p_status_code;
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END get_status_id;

      ----------------------------------------------------------------------------
      --------------------< get_inventory_location_type_id >----------------------
      ----------------------------------------------------------------------------
      FUNCTION get_inventory_location_type_id
                            (p_inventory_location_type     IN       VARCHAR2
                            ,p_inventory_location_type_id  OUT      NUMBER
                            ) 
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        p_inventory_location_type_id := NULL;
        BEGIN
           SELECT TO_NUMBER(lookup_code)
             INTO p_inventory_location_type_id
             FROM fnd_lookup_values 
            WHERE lookup_type ='MTL_LOCATOR_TYPES'
              AND meaning = p_inventory_location_type
              AND LANGUAGE = USERENV ('LANG');
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END get_inventory_location_type_id;

   BEGIN
      g_api_name := 'data_derivations';
      dbg_low('Inside data_derivations');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivations');

      IF csr_stockloc_stg_rec.organization_code IS NULL THEN
         dbg_low('Organization Code is NULL');
         x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                          p_category => xx_emf_cn_pkg.cn_organization_valid,
                          p_error_text => 'E:'||'Organization Code is NULL',
                          p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                          p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                          p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                         );      

      ELSE
         -- To get Organiztion ID
         x_error_code_temp := get_organiztion_id(csr_stockloc_stg_rec.organization_code
                                                ,csr_stockloc_stg_rec.organization_id
                                                );
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_stockloc_stg_rec.organization_id IS NULL THEN
            dbg_low('Organization ID not derived');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => xx_emf_cn_pkg.cn_organization_valid,
                             p_error_text => 'E:'||'Organization ID not derived',
                             p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                             p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                             p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                            ); 
         END IF;
      END IF;

      IF csr_stockloc_stg_rec.subinventory_code IS NULL THEN
         dbg_low('Subinventory Code is NULL');
         x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                          p_category => 'SUBINV-DV001',
                          p_error_text => 'E:'||'Subinventory Code is NULL',
                          p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                          p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                          p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                         );      

      ELSE
         -- To get Subinventory Code
         x_error_code_temp := get_subinventory_code(csr_stockloc_stg_rec.organization_id
                                                   ,csr_stockloc_stg_rec.subinventory_code
                                                   );
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_stockloc_stg_rec.subinventory_code IS NULL THEN
            dbg_low('Subinventory code not derived');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'SUBINV-DV001',
                             p_error_text => 'E:'||'Subinventory Code not derived',
                             p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                             p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                             p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                            ); 
         END IF;
      END IF;

      IF csr_stockloc_stg_rec.status_code IS NULL THEN
         dbg_low('Status Code is NULL');
         x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                          p_category => 'STATUS-DV002',
                          p_error_text => 'E:'||'Status Code is NULL',
                          p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                          p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                          p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                         );      

      ELSE
         -- To get Status ID
         x_error_code_temp := get_status_id(csr_stockloc_stg_rec.status_code
                                           ,csr_stockloc_stg_rec.status_id
                                           );
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_stockloc_stg_rec.status_id IS NULL THEN
            dbg_low('Status ID not derived');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'STATUS-DV002',
                             p_error_text => 'E:'||'Status ID not derived',
                             p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                             p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                             p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                            ); 
         END IF;
      END IF;

      IF csr_stockloc_stg_rec.inventory_location_type IS NULL THEN
         dbg_low('Inventory Location Type is NULL');
         x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                          p_category => 'INVLOC-DV003',
                          p_error_text => 'E:'||'Inventory Location Type is NULL',
                          p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                          p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                          p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                         );      

      ELSE
         -- To get Inventory Location Type
         x_error_code_temp := get_inventory_location_type_id(csr_stockloc_stg_rec.inventory_location_type
                                                            ,csr_stockloc_stg_rec.inventory_location_type_id
                                                            );
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_stockloc_stg_rec.inventory_location_type_id IS NULL THEN
            dbg_low('Inventory Location ID not derived');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'INVLOC-DV003',
                             p_error_text => 'E:'||'Inventory Location Type ID not derived',
                             p_record_identifier_1 => csr_stockloc_stg_rec.record_number,
                             p_record_identifier_2 => csr_stockloc_stg_rec.conc_segment, 
                             p_record_identifier_3 => csr_stockloc_stg_rec.subinventory_code
                            ); 
         END IF;
      END IF;

      dbg_low('End of data derivations.');
      RETURN x_error_code; 
   EXCEPTION
   WHEN xx_emf_pkg.G_E_REC_ERROR THEN
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      RETURN x_error_code;
   WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
      x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
      RETURN x_error_code;
   WHEN OTHERS THEN
      x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
      RETURN x_error_code;
   END data_derivations;

   --------------------------------------------------------------------------------
   ---------------------------< post_validations >---------------------------------
   --------------------------------------------------------------------------------
   FUNCTION post_validations
   RETURN NUMBER
   IS 
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      g_api_name := 'post_validations';
      dbg_low('Inside post_validations');
      dbg_low('End of post validations.');
      RETURN x_error_code;
   EXCEPTION
   WHEN xx_emf_pkg.g_e_rec_error THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      RETURN x_error_code;
   WHEN xx_emf_pkg.g_e_prc_error THEN
      x_error_code := xx_emf_cn_pkg.cn_prc_err;
      RETURN x_error_code;
   WHEN others THEN
      x_error_code := xx_emf_cn_pkg.cn_prc_err;
      RETURN x_error_code;
   END post_validations;

   --------------------------------------------------------------------------------
   --------------------------< update_record_count >-------------------------------
   --------------------------------------------------------------------------------
   PROCEDURE update_record_count
   IS
      CURSOR c_get_total_cnt
      IS
         SELECT COUNT (1) total_count
           FROM xx_mtl_stock_locator_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID;

      x_total_cnt NUMBER;

      CURSOR c_get_error_cnt
      IS
         SELECT SUM(error_count)
           FROM (
               SELECT COUNT (1) error_count
                 FROM xx_mtl_stock_locator_stg 
                WHERE batch_id   = G_BATCH_ID
                  AND request_id = xx_emf_pkg.G_REQUEST_ID
                  AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

      x_error_cnt NUMBER;

      CURSOR c_get_warning_cnt
      IS
         SELECT COUNT (1) warn_count
           FROM xx_mtl_stock_locator_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

      x_warn_cnt NUMBER;

      CURSOR c_get_success_cnt (c_validate NUMBER)
      IS
         SELECT COUNT (1) success_count
           FROM xx_mtl_stock_locator_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND process_code = decode(c_validate,1,process_code,xx_emf_cn_pkg.CN_PROCESS_DATA)
            AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

      x_success_cnt NUMBER;
      x_validate    NUMBER;

   BEGIN

      IF g_validate_flag = TRUE THEN
         x_validate := 1;
      ELSE
         x_validate := 0;
      END IF;

      OPEN c_get_total_cnt;
      FETCH c_get_total_cnt INTO x_total_cnt;
      CLOSE c_get_total_cnt;
      dbg_low('x_total_cnt:'||x_total_cnt);

      OPEN c_get_error_cnt;
      FETCH c_get_error_cnt INTO x_error_cnt;
      CLOSE c_get_error_cnt;
      dbg_low('x_error_cnt:'||x_error_cnt);

      OPEN c_get_warning_cnt;
      FETCH c_get_warning_cnt INTO x_warn_cnt;
      CLOSE c_get_warning_cnt;
      dbg_low('x_warn_cnt:'||x_warn_cnt);

      OPEN c_get_success_cnt(x_validate);
      FETCH c_get_success_cnt INTO x_success_cnt;
      CLOSE c_get_success_cnt;
      dbg_low('x_success_cnt:'||x_success_cnt);

      xx_emf_pkg.update_recs_cnt
      (p_total_recs_cnt   => x_total_cnt
      ,p_success_recs_cnt => x_success_cnt
      ,p_warning_recs_cnt => x_warn_cnt
      ,p_error_recs_cnt   => x_error_cnt
      );
   END update_record_count;

   /*------------------------------------------------------------------------------
   Procedure Name   :   main
   Parameters       :   x_errbuf                  OUT VARCHAR2
                        x_retcode                 OUT VARCHAR2
                        p_batch_id                IN  VARCHAR2
                        p_restart_flag            IN  VARCHAR2
                        p_validate_and_load       IN  VARCHAR2
   Purpose          :   This is the main procedure which subsequently calls 
                        all other procedure.
   ------------------------------------------------------------------------------*/
   PROCEDURE main(x_errbuf             OUT VARCHAR2
                 ,x_retcode            OUT VARCHAR2
                 ,p_batch_id           IN  VARCHAR2
                 ,p_restart_flag       IN  VARCHAR2
                 ,p_validate_and_load  IN  VARCHAR2
                 )
   IS
      x_error_code          NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
      x_stocklocstg_table   G_XXMTL_STOCKLOC_STG_TAB_TYPE;
      x_sqlerrm             VARCHAR2(2000);

      CURSOR c_xx_stocklocstg ( cp_process_status VARCHAR2) 
      IS
         SELECT * 
           FROM xx_mtl_stock_locator_stg
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = G_REQUEST_ID
            AND process_code = cp_process_status
            AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
          ORDER BY record_number;

      ----------------------------------------------------------------------------
      --------------------------< update_record_status >--------------------------
      ----------------------------------------------------------------------------
      PROCEDURE update_record_status (p_conv_hdr_rec  IN OUT  G_XXMTL_STOCKLOC_STG_REC_TYPE,
                                      p_error_code    IN      VARCHAR2
                                     )
      IS
      BEGIN
         g_api_name := 'main.update_record_status';
         dbg_low('Inside update_record_status...');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');
         IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
         THEN
            p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
         ELSE
            p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, 
                                         NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
         END IF;
         p_conv_hdr_rec.process_code := G_STAGE;
         dbg_low('End of update record status.');
      END update_record_status;

      ----------------------------------------------------------------------------
      ---------------------------< update_stg_records >---------------------------
      ----------------------------------------------------------------------------
      PROCEDURE update_stg_records (p_stocklocstg_table IN g_xxmtl_stockloc_stg_tab_type)
      IS
         x_last_update_date         DATE   := SYSDATE;
         x_last_updated_by          NUMBER := fnd_global.user_id;
         x_last_update_login        NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         x_program_application_id   NUMBER := fnd_global.prog_appl_id;
         x_program_id               NUMBER := fnd_global.conc_program_id;
         x_program_update_date      DATE   := SYSDATE;
         indx                       NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.update_stg_records'; 
         dbg_low('Inside update_stg_records...');
         FOR indx IN 1 .. p_stocklocstg_table.COUNT LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_stocklocstg_table(indx).process_code ' || p_stocklocstg_table(indx).process_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_stocklocstg_table(indx).error_code ' || p_stocklocstg_table(indx).error_code);

            UPDATE xx_mtl_stock_locator_stg
               SET organization_code            = p_stocklocstg_table(indx).organization_code
                  ,organization_id              = p_stocklocstg_table(indx).organization_id
                  ,subinventory_code            = NVL(p_stocklocstg_table(indx).subinventory_code,subinventory_code)
                  ,loc_segment1                 = p_stocklocstg_table(indx).loc_segment1
                  ,loc_segment2                 = p_stocklocstg_table(indx).loc_segment2
                  ,loc_segment3                 = p_stocklocstg_table(indx).loc_segment3
                  ,loc_segment3a                = p_stocklocstg_table(indx).loc_segment3a
                  ,loc_segment3b                = p_stocklocstg_table(indx).loc_segment3b
                  ,conc_segment                 = p_stocklocstg_table(indx).conc_segment
                  ,status_code                  = p_stocklocstg_table(indx).status_code
                  ,status_id                    = p_stocklocstg_table(indx).status_id
                  ,inventory_location_type      = p_stocklocstg_table(indx).inventory_location_type
                  ,inventory_location_type_id   = p_stocklocstg_table(indx).inventory_location_type_id
                  ,picking_order                = p_stocklocstg_table(indx).picking_order
                  ,dimension_uom                = NVL(p_stocklocstg_table(indx).dimension_uom,dimension_uom)
                  ,length                       = p_stocklocstg_table(indx).length
                  ,width                        = p_stocklocstg_table(indx).width
                  ,height                       = p_stocklocstg_table(indx).height
                  ,dff_locator_segment1         = NVL(p_stocklocstg_table(indx).dff_locator_segment1,dff_locator_segment1)
                  ,dff_locator_segment2         = NVL(p_stocklocstg_table(indx).dff_locator_segment2,dff_locator_segment2)
                  ,alias                        = p_stocklocstg_table(indx).alias
                  ,inventory_location_id        = p_stocklocstg_table(indx).inventory_location_id
		  ,source_system_name           = p_stocklocstg_table(indx).source_system_name
                  ,process_code                 = p_stocklocstg_table(indx).process_code
                  ,error_code                   = p_stocklocstg_table(indx).error_code
                  ,created_by                   = p_stocklocstg_table(indx).created_by
                  ,creation_date                = p_stocklocstg_table(indx).creation_date
                  ,last_update_date             = x_last_update_date
                  ,last_updated_by              = x_last_updated_by
                  ,last_update_login            = x_last_update_login
                  ,request_id                   = p_stocklocstg_table(indx).request_id
                  ,program_application_id       = x_program_application_id
                  ,program_id                   = x_program_id
                  ,program_update_date          = x_program_update_date
             WHERE record_number = p_stocklocstg_table(indx).record_number
               AND batch_id      = p_stocklocstg_table(indx).batch_id;
         END LOOP;
         COMMIT;
         dbg_low('End of update stg records.');
      END update_stg_records;

      -------------------------------------------------------------------------
      --------------------------< process_data >-------------------------------
      -------------------------------------------------------------------------
      FUNCTION process_data
      RETURN NUMBER
      IS
         x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;

         CURSOR xx_stocklocstg_cur
         IS
         SELECT *
           FROM xx_mtl_stock_locator_stg
          WHERE 1 = 1
            AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_WARN)
            AND batch_id     = G_BATCH_ID
          ORDER BY record_number;


      lv_return_status                  VARCHAR2(1);
      ln_msg_count                      NUMBER;
      lv_msg_data                       VARCHAR2(2000);
      ln_inventory_location_id          NUMBER;
      lv_locator_exists                 VARCHAR2(100);
      ln_count                          NUMBER    :=0;

      lv_message_data                   VARCHAR2(2000);
      lv_error_buf                      VARCHAR2(4000);
      ln_msg_index_out                  NUMBER;
      

      BEGIN
         -- Change the logic to whatever needs to be done
         -- with valid records in the pre-interface tables
         -- either call the appropriate API to process the data
         -- or to insert into an interface table.
         FOR xx_stocklocstg_rec IN xx_stocklocstg_cur
         LOOP
            BEGIN
               ln_msg_count := 0;
               lv_msg_data := NULL;
               lv_error_buf := NULL;
               lv_message_data := NULL;
               x_sqlerrm := NULL;
               fnd_msg_pub.initialize;--Added on 29-AUG-2012 to intialize global message table
               inv_loc_wms_pub.create_locator
                         (x_return_status                => lv_return_status
                         ,x_msg_count                    => ln_msg_count
                         ,x_msg_data                     => lv_msg_data
                         ,x_inventory_location_id        => ln_inventory_location_id
                         ,x_locator_exists               => lv_locator_exists
                         ,p_organization_id              => xx_stocklocstg_rec.organization_id
                         ,p_organization_code            => NULL
                         ,p_concatenated_segments        => xx_stocklocstg_rec.conc_segment
                         ,p_description                  => xx_stocklocstg_rec.conc_segment
                         ,p_inventory_location_type      => xx_stocklocstg_rec.inventory_location_type_id
                         ,p_picking_order                => xx_stocklocstg_rec.picking_order
                         ,p_location_maximum_units       => NULL
                         ,p_subinventory_code            => xx_stocklocstg_rec.subinventory_code
                         ,p_location_weight_uom_code     => NULL
                         ,p_max_weight                   => NULL
                         ,p_volume_uom_code              => NULL
                         ,p_max_cubic_area               => NULL
                         ,p_x_coordinate                 => NULL
                         ,p_y_coordinate                 => NULL
                         ,p_z_coordinate                 => NULL
                         ,p_physical_location_id         => NULL
                         ,p_pick_uom_code                => NULL
                         ,p_dimension_uom_code           => xx_stocklocstg_rec.dimension_uom
                         ,p_length                       => xx_stocklocstg_rec.length
                         ,p_width                        => xx_stocklocstg_rec.width
                         ,p_height                       => xx_stocklocstg_rec.height
                         ,p_status_id                    => xx_stocklocstg_rec.status_id
                         ,p_dropping_order               => NULL
                         ,p_attribute_category           => NULL
                         ,p_attribute1                   => xx_stocklocstg_rec.dff_locator_segment1
                         ,p_attribute2                   => xx_stocklocstg_rec.dff_locator_segment2
                         ,p_attribute3                   => NULL
                         ,p_attribute4                   => NULL
                         ,p_attribute5                   => NULL
                         ,p_attribute6                   => NULL
                         ,p_attribute7                   => NULL
                         ,p_attribute8                   => NULL
                         ,p_attribute9                   => NULL
                         ,p_attribute10                  => NULL
                         ,p_attribute11                  => NULL
                         ,p_attribute12                  => NULL
                         ,p_attribute13                  => NULL
                         ,p_attribute14                  => NULL
                         ,p_attribute15                  => NULL
                         ,p_alias                        => xx_stocklocstg_rec.alias
                         );
               IF lv_return_status <> 'S' THEN 
                       FOR cur_err_rec IN 1 .. ln_msg_count
                       LOOP
                          fnd_msg_pub.get (p_msg_index          => cur_err_rec,
                                           p_encoded            => fnd_api.g_false,
                                           p_data               => lv_message_data,
                                           p_msg_index_out      => ln_msg_index_out
                                          );
                          lv_error_buf := lv_error_buf||lv_message_data;
                       END LOOP;
                       x_sqlerrm := substr(lv_error_buf,1,800);
                       x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                       xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                        ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                        ,p_error_text          =>   x_sqlerrm
                                        ,p_record_identifier_1 =>   xx_stocklocstg_rec.record_number
                                        ,p_record_identifier_2 =>   xx_stocklocstg_rec.conc_segment
                                        ,p_record_identifier_3 =>   xx_stocklocstg_rec.subinventory_code
                                        );
                       UPDATE xx_mtl_stock_locator_stg
                          SET error_code         = x_error_code
                             ,process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                        WHERE batch_id           = G_BATCH_ID
                          AND record_number      = xx_stocklocstg_rec.record_number;
               ELSE
                  UPDATE xx_mtl_stock_locator_stg
                     SET inventory_location_id = ln_inventory_location_id
                        ,process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                   WHERE batch_id           = G_BATCH_ID
                     AND record_number      = xx_stocklocstg_rec.record_number;
               END IF;
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  x_sqlerrm := substr(sqlerrm,1,800);
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                   ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                   ,p_error_text          =>   x_sqlerrm
                                   ,p_record_identifier_1 =>   xx_stocklocstg_rec.record_number
                                   ,p_record_identifier_2 =>   xx_stocklocstg_rec.conc_segment
                                   ,p_record_identifier_3 =>   xx_stocklocstg_rec.subinventory_code
                                   );
                  UPDATE xx_mtl_stock_locator_stg
                     SET error_code         = x_error_code
                        ,process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                   WHERE batch_id           = G_BATCH_ID
                     AND record_number      = xx_stocklocstg_rec.record_number;
                   COMMIT;
            END;
            ln_count :=ln_count+1;
            IF ln_count = 1000
            THEN
               COMMIT;
               ln_count := 0;
            END IF;
         END LOOP;
         COMMIT;
         RETURN x_return_status;
      EXCEPTION
            WHEN OTHERS THEN
              x_sqlerrm := sqlerrm;
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                ,p_error_text          => x_sqlerrm
                                ,p_record_identifier_4 => 'Process to Create Stock Locator'
                               );
              RETURN x_error_code;
      END process_data;

      -- mark_records_complete
      PROCEDURE mark_records_complete (p_process_code           VARCHAR2)
      IS
         x_last_update_date       DATE   := SYSDATE;
         x_last_updated_by        NUMBER := fnd_global.user_id;
         x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.mark_records_complete';
         dbg_low('Inside mark_records_complete...');

         UPDATE xx_mtl_stock_locator_stg
            SET process_code      = G_STAGE,
                error_code        = NVL (error_code, xx_emf_cn_pkg.CN_SUCCESS),
                last_updated_by   = x_last_updated_by,
                last_update_date  = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = xx_emf_pkg.G_REQUEST_ID
            AND process_code = DECODE (p_process_code
                                      ,xx_emf_cn_pkg.CN_PROCESS_DATA
                                      ,xx_emf_cn_pkg.CN_POSTVAL
                                      ,xx_emf_cn_pkg.CN_DERIVE)
            AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
         COMMIT;
         dbg_low('End of mark records complete.');
      EXCEPTION 
      WHEN OTHERS THEN
         dbg_low('Error in Update of mark records complete: '||SQLERRM);
      END mark_records_complete;
   BEGIN
      --Main Begin
      g_api_name := 'Main';
      x_retcode := xx_emf_cn_pkg.CN_SUCCESS;
      dbg_low('Before Setting Environment');

      -- Set Env --
      dbg_low('Calling set_cnv_env..');
      set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);

      -- Include all the parameters to the conversion main here
      -- as medium log messages
      dbg_med('Starting main process with the following parameters');
      dbg_med('Param - p_batch_id          '|| p_batch_id);
      dbg_med('Param - p_restart_flag      '|| p_restart_flag);
      dbg_med('Param - p_validate_and_load '|| p_validate_and_load);
      --Popluate the global variable for validate flag
      IF p_validate_and_load = g_validate_and_load THEN
         g_validate_flag := FALSE;
         --dbg_med('Param - g_validate_flag '|| g_validate_flag);
      ELSE
         g_validate_flag := TRUE;
         --dbg_med('Param - g_validate_flag '|| g_validate_flag);
      END IF;

      -- Call procedure to update records with the current request_id
      -- so that we can process only those records
      -- This gives a better handling of restarting
      dbg_low('Calling mark_records_for_processing..');
      mark_records_for_processing(p_restart_flag => p_restart_flag);

      -- Set the stage to Pre Validations
      set_stage (xx_emf_cn_pkg.CN_PREVAL);

      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low('Calling pre_validations ..');
      x_error_code := pre_validations();
      dbg_med('After pre-validations X_ERROR_CODE : ' || X_ERROR_CODE);
      -- Update process code of staging records
      -- Update Header and Lines Level
      update_staging_records (x_error_code);
      xx_emf_pkg.propagate_error (x_error_code);

      dbg_low(G_REQUEST_ID || ' : Before Data Validations');
      -- Once pre-validations are complete loop through the pre-interface records
      -- and perform data validation on this table

      -- Set the stage to data Validations
      set_stage (xx_emf_cn_pkg.CN_VALID);

      OPEN c_xx_stocklocstg ( xx_emf_cn_pkg.CN_PREVAL);
      LOOP
      FETCH c_xx_stocklocstg 
      BULK COLLECT INTO x_stocklocstg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
         FOR i IN 1 .. x_stocklocstg_table.COUNT
         LOOP
            BEGIN
               -- Perform validations
               x_error_code := data_validations(x_stocklocstg_table (i));
               dbg_low('x_error_code for '|| x_stocklocstg_table (i).record_number|| ' is ' || x_error_code);
               update_record_status (x_stocklocstg_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
              -- If HIGH error then it will be propagated to the next level
              -- IF the process has to continue maintain it as a medium severity
              WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                 dbg_high(xx_emf_cn_pkg.CN_REC_ERR);
              WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                 dbg_high('Process Level Error in Data Validations');
                 update_stg_records (x_stocklocstg_table);
                 RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
              WHEN OTHERS THEN
                 xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM
                                 ,xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,xx_emf_cn_pkg.CN_EXP_UNHAND
                                 ,x_stocklocstg_table (i).record_number);
            END;
         END LOOP;
         dbg_low('x_stocklocstg_table.count ' || x_stocklocstg_table.COUNT );
         update_stg_records( x_stocklocstg_table);
         x_stocklocstg_table.DELETE;
         EXIT WHEN c_xx_stocklocstg%NOTFOUND;
      END LOOP; 

      IF c_xx_stocklocstg%ISOPEN THEN
          CLOSE c_xx_stocklocstg;
      END IF;

      dbg_low(G_REQUEST_ID || ' : Before Data Derivations');
      -- Once data-validations are complete loop through the pre-interface records
      -- and perform data derivations on this table

      -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.CN_DERIVE);
      OPEN c_xx_stocklocstg ( xx_emf_cn_pkg.CN_VALID);
      LOOP
      FETCH c_xx_stocklocstg 
      BULK COLLECT INTO x_stocklocstg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
         FOR i IN 1 .. x_stocklocstg_table.COUNT
         LOOP
            BEGIN
               -- Perform Dervations
               x_error_code := data_derivations(x_stocklocstg_table (i));
               dbg_low('x_error_code for '|| x_stocklocstg_table (i).record_number|| ' is ' || x_error_code);
               update_record_status (x_stocklocstg_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
              -- If HIGH error then it will be propagated to the next level
              -- IF the process has to continue maintain it as a medium severity
              WHEN xx_emf_pkg.G_E_REC_ERROR THEN                 dbg_high(xx_emf_cn_pkg.CN_REC_ERR);
              WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                 dbg_high('Process Level Error in Data Derivations');
                 update_stg_records (x_stocklocstg_table);
                 RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
              WHEN OTHERS THEN
                 xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM
                                 ,xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,xx_emf_cn_pkg.CN_EXP_UNHAND
                                 ,x_stocklocstg_table (i).record_number);
            END;
         END LOOP;
         dbg_low('x_stocklocstg_table.count ' || x_stocklocstg_table.COUNT );
         update_stg_records( x_stocklocstg_table);
         x_stocklocstg_table.DELETE;
         EXIT WHEN c_xx_stocklocstg%NOTFOUND;
      END LOOP; 

      IF c_xx_stocklocstg%ISOPEN THEN
          CLOSE c_xx_stocklocstg;
      END IF;

      -- Set the stage to Post Validations
      set_stage (xx_emf_cn_pkg.CN_POSTVAL);

      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low('Calling post_validations ..');
      x_error_code := post_validations();
      dbg_med('After post-validations X_ERROR_CODE : ' || X_ERROR_CODE);
      -- Update mark records complete for staging records
      mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
      dbg_med('After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
      xx_emf_pkg.propagate_error (x_error_code);

      -- Set the stage to Process
      set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

      IF g_validate_flag = FALSE THEN
         dbg_low('Calling process_data');
         x_error_code := process_data();
         dbg_med('After post-process_data X_ERROR_CODE : ' || X_ERROR_CODE);
         mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
         dbg_med('After mark_records_complete X_ERROR_CODE'||X_ERROR_CODE);
         xx_emf_pkg.propagate_error ( x_error_code);
      END IF;

      update_record_count;
      xx_emf_pkg.create_report;

   EXCEPTION
      WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking for G_E_ENV_NOT_SET');
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN OTHERS THEN
         x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
   END main;
END xx_mtl_stockloc_conversion_pkg;
/


GRANT EXECUTE ON APPS.XX_MTL_STOCKLOC_CONVERSION_PKG TO INTG_XX_NONHR_RO;
