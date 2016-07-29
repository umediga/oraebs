DROP PACKAGE BODY APPS.XX_INV_ITEM_ONHANDVAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ITEM_ONHANDVAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 27-Feb-2012
 File Name     : XXINVITEMONHANDVL.pkb
 Description   : This script creates the body of the package xx_inv_item_onhandval_pkg

 Change History:

 Version Date          Name          Remarks
-------- -----------   ----          ---------------------------
 1.0     27-Feb-2012   Mou Mukherjee      Initial development.
 1.1     22-MAR-2012   Mou Mukherjee      Included the extra fields as per new data mapping
 1.2     10-OCT-2014   Sharath Babu       Modified as per Wave2 For non-WMS organizations, locators are optional
 1.3     24-NOV-2014   Sharath Babu       Added NVL condition in is_lot_divisible_valid
*/
---------------------------------------------------------------------------

   --**********************************************************************
  --Function to Find Max.
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
  --Function to Pre Validations .
--**********************************************************************
   FUNCTION pre_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Pre-Validations');
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
--Function to Data Validations .
--**********************************************************************
   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_inv_itemonhandqty_pkg.g_xx_inv_itemqoh_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
      x_locator_cntrl     NUMBER := 0;

      /*--------------------------------------
      -- Function to validate Organization Code
      --@param1 -- p_organization_code
      --@param2 -- p_organization_id
      ----------------------------------------*/
      FUNCTION is_organization_valid (
         p_organization_code   IN       VARCHAR2,
         p_organization_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_code     VARCHAR2 (30);
         x_err_msg      VARCHAR2 (200);
	 x_organization_code VARCHAR2(30);
      BEGIN
         
          x_organization_code :=
            xx_intg_common_pkg.get_mapping_value
                                       (p_mapping_type        => 'ORGANIZATION_CODE',
                                        p_source              => NULL,
                                        p_old_value           => p_organization_code,
                                        p_date_effective      => SYSDATE
                                       );
          xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'is_organization_valid: Success Organization_ID=>'
                         || x_organization_code
                        );
	 
	 SELECT organization_id 
         INTO p_organization_id
         FROM mtl_parameters
         WHERE organization_code = x_organization_code;
         
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
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    'Invalid organization code =>'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_organization_code,
                         p_record_identifier_3      => p_organization_code
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
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    'Invalid organization code =>'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_organization_code,
                         p_record_identifier_3      => p_organization_code
                        );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Errors In Organization Validation '
                                     || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Errors In Organization Validation=>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_organization_code,
                     p_record_identifier_3      => p_organization_code
                    );
               RETURN x_error_code;           
      END is_organization_valid;

/*--------------------------------------
      -- Function to validate Organization Code
      --@param1 -- p_owning_organization_name
      --@param2 -- p_owning_organization_id
      ----------------------------------------*/
      FUNCTION is_owning_organization_valid (
         p_owning_organization_code   IN       VARCHAR2,
         p_owning_organization_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_code     VARCHAR2 (30);
         x_err_msg      VARCHAR2 (200);
	 x_own_organization_code VARCHAR2(30);
      BEGIN
         
          x_own_organization_code :=
            xx_intg_common_pkg.get_mapping_value
                                       (p_mapping_type        => 'ORGANIZATION_CODE',
                                        p_source              => NULL,
                                        p_old_value           => p_owning_organization_code,
                                        p_date_effective      => SYSDATE
                                       );
          xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'is_owning_organization_valid: Success Owning_Organization_ID=>'
                         || p_owning_organization_id
                        );
	 
	 SELECT organization_id 
         INTO p_owning_organization_id
         FROM mtl_parameters
         WHERE organization_code = x_own_organization_code;

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
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    'Invalid owning organization code =>'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                         p_record_identifier_3      => p_cnv_hdr_rec.organization_name
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
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    'Invalid owning organization code =>'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                         p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                         p_record_identifier_3      => p_cnv_hdr_rec.organization_name
                        );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Errors In Owning Organization Validation '
                                     || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Errors In Owning Organization Validation=>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.organization_name
                    );
               RETURN x_error_code;       
      END is_owning_organization_valid;
      /*--------------------------------------
      -- Function to validate Item number
      --@param1 -- p_item_number
      --@param2 -- p_organization_id
      --@param3 -- p_inventory_item_id
      ----------------------------------------*/-- Validation for item number --
      FUNCTION is_item_number_valid (
         p_item_number         IN       VARCHAR2,
         p_organization_id     IN       NUMBER,
         p_inventory_item_id   OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_code     VARCHAR2 (30);
         x_err_msg      VARCHAR2 (200);
         x_space        VARCHAR2 (10);
         n_itemnumber   NUMBER;
         l_itemfnd      NUMBER;
         x_count        NUMBER;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_item_number_valid: '
                               || p_item_number
                               || '-'
                               || p_organization_id
                              );

         -- get the Oracle Item Number if cross exists between Legacy Item Number and Oracle Item Number
         SELECT COUNT (*)
           INTO x_count
           FROM mtl_system_items_b
          WHERE segment1 = p_item_number
            AND organization_id = p_organization_id
            AND enabled_flag = 'Y';

         IF (x_count > 0)
         THEN
            x_error_code := xx_emf_cn_pkg.cn_success;
         END IF;

         SELECT inventory_item_id
           INTO p_inventory_item_id
           FROM mtl_system_items_b
          WHERE segment1 = p_item_number
            AND organization_id = p_organization_id
            AND enabled_flag = 'Y';

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_item_number_valid: '
                               || p_item_number
                               || '-'
                               || p_organization_id
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Item# Validation Success=>'
                               || p_inventory_item_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Item Number =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Item Number =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Item Number =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Item Number =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Item Number =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Error: Validating Item Number =>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
      END is_item_number_valid;


      /*-------------------------------------------------------------
      -- Function to validate Inventory / Transactable Item number
      --@param1 -- p_item_number
      --@param2 -- p_organization_id
      ---------------------------------------------------------------*/
      FUNCTION is_item_inv_transact_valid (
         p_item_number         IN       VARCHAR2,
         p_organization_id     IN       NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_code     VARCHAR2 (30);
         x_err_msg      VARCHAR2 (200);
         x_space        VARCHAR2 (10);
         x_inv_item     VARCHAR2(10);
	 x_transact_flag VARCHAR2(10);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_item_inv_transact_valid: '
                               || p_item_number
                               || '-'
                               || p_organization_id
                              );

          SELECT  INVENTORY_ITEM_FLAG , MTL_TRANSACTIONS_ENABLED_FLAG
           INTO x_inv_item , x_transact_flag
           FROM mtl_system_items_b
          WHERE segment1 = p_item_number
            AND organization_id = p_organization_id;
	   
	   IF( x_inv_item = 'Y') AND (x_transact_flag = 'Y') THEN

           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'is_item_inv_transact_valid Success=>'
                               || p_item_number
                              );
         RETURN x_error_code;
	 ELSE
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Item processed is not inventory/Transactable =>' || SQLERRM
                                 );
	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item processed is not inventory/Transactable =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
	END IF;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Inventory/Transactable Item =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Inventory/Transactable Item =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Inventory/Transactable Item =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Inventory/Transactable Item =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Inventory/Transactable Item Validation Error =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Inventory/Transactable Item Validation Error =>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
      END is_item_inv_transact_valid;

      /*-------------------------------------------------------
      -- Function to validate subinventory - Locator Segments
      --@param1 -- p_item_location1
      --@param2 -- p_item_location2
      --@param3 -- p_item_location3
      --@param4 -- p_organization_id
      --@param5 -- p_subinventory_code
      --@param6 -- p_sub_organization_code 
      --------------------------------------------------------*/
        FUNCTION is_location_sub_code_valid (
         p_item_location1      IN OUT  VARCHAR2,
         p_item_location2      IN OUT  VARCHAR2,
         p_item_location3      IN OUT  VARCHAR2,
         p_organization_id     IN   NUMBER,
         p_subinventory_code   IN OUT  VARCHAR2,
	 p_sub_organization_code   IN       VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         x_location     VARCHAR2 (240);
         x_delimiter    VARCHAR2 (2)   := '.';
	 x_subinvcode   xx_intg_mapping.new_value1%TYPE;
	 x_subinventory_code  mtl_secondary_inventories.secondary_inventory_name%TYPE;
	 x_loc_seg1   xx_intg_mapping.new_value1%TYPE; 
	 x_loc_seg2   xx_intg_mapping.new_value2%TYPE;
	 x_loc_seg3   xx_intg_mapping.new_value3%TYPE;
 	 x_loc_seg4   xx_intg_mapping.new_value4%TYPE;
	 x_loc_seg5   xx_intg_mapping.new_value5%TYPE;
	 x_loc_seg6   xx_intg_mapping.new_value6%TYPE;
	 x_loc_seg7   xx_intg_mapping.new_value7%TYPE;
	 x_first      VARCHAR2(10);
	 x_oldvalue2  xx_intg_mapping.old_value2%TYPE; 
	 x_oldvalue3  xx_intg_mapping.old_value3%TYPE;
	 x_non_wms_flag  VARCHAR2(10) := 'N';
      BEGIN
         --Added as per Wave2 For non-WMS organizations, locators are optional
         BEGIN
         SELECT 'Y'
           INTO x_non_wms_flag
	   FROM apps.xx_emf_process_setup eps
	       ,apps.xx_emf_process_parameters epr
	  WHERE epr.parameter_value LIKE '%|'||p_sub_organization_code||'%'
	    and epr.parameter_name = 'NON_WMS_ORGS'
	    and eps.process_id = epr.process_id
            and eps.process_name = 'XXINVITEMONHANDCNV';
         EXCEPTION
         WHEN OTHERS THEN
            x_non_wms_flag := 'N';
         END;
         BEGIN
         SELECT old_value2,old_value3
            INTO x_oldvalue2 , x_oldvalue3
            FROM xx_intg_mapping
          WHERE old_value1 = p_subinventory_code
          AND old_value7 = p_sub_organization_code
	  AND ROWNUM = 1;
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Subinvetntory code =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
            SELECT secondary_inventory_name
               INTO x_subinventory_code
              FROM mtl_secondary_inventories msi
            WHERE msi.organization_id = p_organization_id
            AND UPPER (secondary_inventory_name) = UPPER (p_subinventory_code);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Subinvetntory code SUCCESS=>'
                               || x_subinventory_code
                               || '-'
                               || x_locator_cntrl
                              );
          --  RETURN x_error_code;
            EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Subinvetntory code =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Subinvetntory code =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                 p_error_text               =>    'Error: Validating Subinvetntory code =>'
                                               || SQLERRM,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                 p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                );
            RETURN x_error_code;
  END;
  IF ( (x_non_wms_flag = 'N') OR 
     ( (x_non_wms_flag = 'Y') AND (p_item_location1 IS NOT NULL AND p_item_location2 IS NOT NULL AND p_item_location3 IS NOT NULL)))  THEN  --As per Wave2
  BEGIN                                      
       SELECT  mil.segment1
                || x_delimiter
                || mil.segment2
                || x_delimiter
                || mil.segment3
           INTO x_location
           FROM mtl_item_locations mil
          WHERE mil.organization_id = p_organization_id
            AND mil.segment1 = p_item_location1
            AND mil.segment2 = p_item_location2
            AND mil.segment3 = p_item_location3
          --  AND mil.status_id = 1             -- Commented on 12th Jan 14 ( since we have the non costed subinventory also)
	    AND mil.end_date_active IS NULL
            AND NVL (mil.subinventory_code, p_subinventory_code) = p_subinventory_code
	    AND mil.disable_date is NULL;  -- Added on 12th Jan 14

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Locator Segments SUCCESS=>' || x_location
                              );
--            p_subinventory_code := x_subinvcode;
            RETURN x_error_code; -- ADDED on 10th-July-13
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments ' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Locator Segments =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                  );
            RETURN x_error_code;            
            END; 
            END IF;  --As per Wave2
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                 p_error_text               =>    'Error: Validating Subinvetntory code =>'
                                               || SQLERRM,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                 p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                );
            RETURN x_error_code;
  END;
   IF( x_oldvalue2 IS NOT NULL and x_oldvalue3 IS NOT NULL) THEN
  IF ( (x_non_wms_flag = 'N') OR 
     ( (x_non_wms_flag = 'Y') AND (p_item_location1 IS NOT NULL AND p_item_location2 IS NOT NULL AND p_item_location3 IS NOT NULL)))  THEN  --As per Wave2
     
    SELECT p_item_location1||p_item_location2||p_item_location3
        INTO x_location
        FROM DUAL;
 
    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Concatenated location =>' || x_location);

        SELECT SUBSTR(p_item_location3,1,1) 
           INTO x_first
           FROM dual;

       BEGIN
       SELECT new_value1
       INTO x_subinvcode
         FROM xx_intg_mapping
       WHERE x_location BETWEEN old_value2 AND old_value3
       AND p_subinventory_code = old_value1
       AND x_first IN ( NVL(old_value4,x_first) , NVL(old_value5,x_first) , NVL(old_value6,x_first));

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Oracle Subinvetntory code =>' || x_subinvcode
                                 );
        EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                 p_error_text               =>    'Error: Validating Locator =>'
                                               || SQLERRM,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                 p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                );
            RETURN x_error_code;

       END;
       BEGIN
        SELECT secondary_inventory_name
           INTO x_subinventory_code
           FROM mtl_secondary_inventories msi
          WHERE msi.organization_id = p_organization_id
          AND UPPER (secondary_inventory_name) = UPPER (x_subinvcode);
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Subinvetntory code SUCCESS=>'
                               || x_subinventory_code
                               || '-'
                               || x_locator_cntrl
                              );
     --    RETURN x_error_code;
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Subinvetntory code =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Subinvetntory code =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                 p_error_text               =>    'Error: Validating Subinvetntory code =>'
                                               || SQLERRM,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                 p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                );
            RETURN x_error_code;
  END;
  BEGIN                                      
       SELECT  mil.segment1
                || x_delimiter
                || mil.segment2
                || x_delimiter
                || mil.segment3
           INTO x_location
           FROM mtl_item_locations mil
          WHERE mil.organization_id = p_organization_id
            AND mil.segment1 = p_item_location1
            AND mil.segment2 = p_item_location2
            AND mil.segment3 = p_item_location3
            AND mil.status_id = 1
            AND NVL (mil.subinventory_code, x_subinvcode) = x_subinvcode;

xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Locator Segments SUCCESS=>' || x_location
                              );
            p_subinventory_code := x_subinvcode;
          --  RETURN x_error_code;
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments ' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Locator Segments =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                  );
            RETURN x_error_code;
            END; 
        RETURN x_error_code;   
     END IF;  --As per Wave2
  ELSIF ( x_oldvalue2 IS NULL and x_oldvalue3 IS NULL) THEN
      
    xx_intg_common_pkg.get_mapping_value
                                       (p_mapping_type        => 'SUBINVENTORY_CODE',
                                        p_old_value1          => p_subinventory_code,
                    p_old_value7          => p_sub_organization_code,
                    p_date_effective      => SYSDATE,
                             p_new_value1          => x_loc_seg1,
                    p_new_value2          => x_loc_seg2,
                    p_new_value3          => x_loc_seg3,
                    p_new_value4          => x_loc_seg4,
                    p_new_value5          => x_loc_seg5,
                    p_new_value6          => x_loc_seg6,
                    p_new_value7          => x_loc_seg7
                                         );
BEGIN
      SELECT secondary_inventory_name
           INTO x_subinventory_code
           FROM mtl_secondary_inventories msi
          WHERE msi.organization_id = p_organization_id
          AND UPPER (secondary_inventory_name) = UPPER (x_loc_seg1);
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Subinvetntory code SUCCESS=>'
                               || x_subinventory_code
                               || '-'
                               || x_locator_cntrl
                              );
     --    RETURN x_error_code;
         p_subinventory_code := x_loc_seg1;
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Subinvetntory code =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Subinvetntory code =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Subinvetntory code =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                (p_severity                 => xx_emf_cn_pkg.cn_medium,
                 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                 p_error_text               =>    'Error: Validating Subinvetntory code =>'
                                               || SQLERRM,
                 p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                 p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                 p_record_identifier_3      => p_cnv_hdr_rec.subinventory_code
                );
            RETURN x_error_code;
  END;
  
  IF(p_item_location1 IS NULL AND p_item_location2 IS NULL AND p_item_location3 IS NULL) THEN
  IF x_non_wms_flag = 'N' THEN  --As per Wave2    
BEGIN
    SELECT  mil.segment1
                || x_delimiter
                || mil.segment2
                || x_delimiter
                || mil.segment3
           INTO x_location
           FROM mtl_item_locations mil
          WHERE mil.organization_id = p_organization_id
            AND mil.segment1 = x_loc_seg2
            AND mil.segment2 = x_loc_seg3
            AND mil.segment3 = x_loc_seg4
            AND mil.status_id = 1
            AND NVL (mil.subinventory_code, x_loc_seg1) = x_loc_seg1;

        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Locator Segments SUCCESS=>' || x_location
                              );
         p_item_location1 := x_loc_seg2;    
         p_item_location2 := x_loc_seg3;    
         p_item_location3 := x_loc_seg4;
         
         RETURN x_error_code;
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments ' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Locator Segments =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                  );
            RETURN x_error_code;
         END;
         END IF;  --As per Wave2
  RETURN x_error_code;

  ELSIF(p_item_location1 IS NOT NULL AND p_item_location2 IS NOT NULL AND p_item_location3 IS NOT NULL) THEN
  IF ( (x_non_wms_flag = 'N') OR 
     ( (x_non_wms_flag = 'Y') AND (p_item_location1 IS NOT NULL AND p_item_location2 IS NOT NULL AND p_item_location3 IS NOT NULL)))  THEN  --As per Wave2

   IF(x_loc_seg1 = 'FG') THEN
     BEGIN
        SELECT  mil.segment1
                || x_delimiter
                || mil.segment2
                || x_delimiter
                || mil.segment3
           INTO x_location
           FROM mtl_item_locations mil
          WHERE mil.organization_id = p_organization_id
            AND mil.segment1 = x_loc_seg2
            AND mil.segment2 = x_loc_seg3
            AND mil.segment3 = x_loc_seg4
            AND mil.status_id = 1
            AND NVL (mil.subinventory_code, x_loc_seg1) = x_loc_seg1;

        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Locator Segments SUCCESS=>' || x_location
                              );
         p_item_location1 := x_loc_seg2;    
         p_item_location2 := x_loc_seg3;    
         p_item_location3 := x_loc_seg4;
         
         RETURN x_error_code;
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments ' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Locator Segments =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                  );
            RETURN x_error_code;
         END;
         RETURN x_error_code;
    ELSIF(x_loc_seg1 != 'FG') THEN
    BEGIN
    SELECT  mil.segment1
                || x_delimiter
                || mil.segment2
                || x_delimiter
                || mil.segment3
           INTO x_location
           FROM mtl_item_locations mil
          WHERE mil.organization_id = p_organization_id
            AND mil.segment1 = p_item_location1
            AND mil.segment2 = p_item_location2
            AND mil.segment3 = p_item_location3
            AND mil.status_id = 1
            AND NVL (mil.subinventory_code, x_loc_seg1) = x_loc_seg1;

        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Locator Segments SUCCESS=>' || x_location
                              );

     EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments ' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Locator Segments =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                  );
            RETURN x_error_code;
         END;
     RETURN x_error_code;
    END IF;
    END IF;  --As per Wave2
    ELSE
  IF ( (x_non_wms_flag = 'N') OR 
     ( (x_non_wms_flag = 'Y') AND (p_item_location1 IS NOT NULL AND p_item_location2 IS NOT NULL AND p_item_location3 IS NOT NULL)))  THEN  --As per Wave2

     	    IF(x_loc_seg1 = 'FG') THEN
     BEGIN
        SELECT  mil.segment1
                || x_delimiter
                || mil.segment2
                || x_delimiter
                || mil.segment3
           INTO x_location
           FROM mtl_item_locations mil
          WHERE mil.organization_id = p_organization_id
            AND mil.segment1 = x_loc_seg2
            AND mil.segment2 = x_loc_seg3
            AND mil.segment3 = x_loc_seg4
            AND mil.status_id = 1
            AND NVL (mil.subinventory_code, x_loc_seg1) = x_loc_seg1;

        xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Locator Segments SUCCESS=>' || x_location
                              );
         p_item_location1 := x_loc_seg2;    
         p_item_location2 := x_loc_seg3;    
         p_item_location3 := x_loc_seg4;
         
         RETURN x_error_code;
         EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments ' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Locator Segments =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3
                  );
            RETURN x_error_code;
         END;
         RETURN x_error_code;
    ELSIF(x_loc_seg1 != 'FG') THEN
	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Locator Segments ' || SQLERRM
                                 );
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Locator Segments =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.loc_segment1||p_cnv_hdr_rec.loc_segment2||p_cnv_hdr_rec.loc_segment3	   
                    );
            RETURN x_error_code;
	    END IF;
  END IF;
  END IF;  --As per Wave2
END IF;
END is_location_sub_code_valid;  

      /*--------------------------------------
      -- Function to derive the value of transaction type id
      --@param1 -- p_transaction_type
      --@param2 -- p_transaction_type_id
      ----------------------------------------*/--Validate the transaction type --
      FUNCTION is_transaction_type_valid (
         p_transaction_type      IN       VARCHAR2,
         p_transaction_type_id   OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         -- Validate the transaction type
         SELECT transaction_type_id
           INTO p_transaction_type_id
           FROM mtl_transaction_types mtt
          WHERE UPPER (mtt.transaction_type_name) = UPPER (p_transaction_type);

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Transaction type SUCCESS=>'
                               || p_transaction_type
                               || '-'
                               || p_transaction_type_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Transaction type =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Transaction type =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.transaction_type_name
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Transaction type =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Transaction type =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.transaction_type_name
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Error: Validating Transaction type =>'
                                  || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Transaction type =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.transaction_type_name
                  );
            RETURN x_error_code;
      END is_transaction_type_valid;
  /*--------------------------------------
      -- Function to derive the value of transaction source id
      --@param1 -- p_transaction_source
      --@param2 -- p_organization_id
      --@param3 -- p_transaction_type_id
      ----------------------------------------*/
      --Validate the transaction source --  16th-AUG-2012
      FUNCTION is_transaction_source_valid (
         p_transaction_source      IN       VARCHAR2,
	 p_organization_id         IN       NUMBER,
         p_transaction_source_id   OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
      BEGIN
         -- Validate the transaction source
	    SELECT DISPOSITION_ID
	    INTO p_transaction_source_id
	    FROM MTL_GENERIC_DISPOSITIONS
	    WHERE organization_id = p_organization_id
	    AND segment1 = p_transaction_source;
        	
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Transaction source SUCCESS=>'
                               || p_transaction_source
                               || '-'
                               || p_transaction_source_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Transaction source =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Transaction source =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.transaction_source_name
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Transaction source =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Transaction source =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.transaction_source_name
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Error: Validating Transaction source =>'
                                  || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Error: Validating Transaction source =>'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.transaction_source_name
                  );
            RETURN x_error_code;
      END is_transaction_source_valid;
      /*--------------------------------------
      -- Function to derive UOM Code
      --@param1 -- p_item_number
      --@param2 -- p_organization_id
      --@param3 -- p_transaction_uom
      ----------------------------------------*/
      FUNCTION is_transaction_uom_valid (
         p_item_number       IN       VARCHAR2,
         p_organization_id   IN       NUMBER,
         p_transaction_uom   OUT      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code             NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_code               VARCHAR2 (30);
         x_err_msg                VARCHAR2 (200);
         x_transaction_uom_code   VARCHAR2 (10);
      BEGIN
         SELECT primary_uom_code
           INTO p_transaction_uom
           FROM mtl_system_items_b
          WHERE segment1 = p_item_number
            AND organization_id = p_organization_id;

         -- get the actual uom code
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Transaction UOM SUCCESS=>'
                               || p_transaction_uom
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Transaction UOM =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Transaction UOM =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.transaction_uom
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Transaction UOM =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Transaction UOM =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.transaction_uom
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Error: Validating Transaction UOM =>'
                                  || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               =>    'Error: Validating Transaction UOM =>'
                                                  || SQLERRM,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                    p_record_identifier_3      => p_cnv_hdr_rec.transaction_uom
                   );
            RETURN x_error_code;
      END is_transaction_uom_valid;

      /*-----------------------------------------------------------------
      -- Function to validate lot and serial number and derive to serial number
      --@param1 -- p_fm_number
      --@param2 -- p_organization_id
      --@param3 -- p_inventory_item_id
      --@param4 -- p_transaction_qty
      --@param5 -- p_to_number
      ------------------------------------------------------------------*/
      FUNCTION is_serial_lot_number_valid (
         p_fm_number           IN       VARCHAR2,
         p_organization_id     IN       NUMBER,
         p_tran_id             IN       NUMBER,
         p_tran_action_id      IN       NUMBER,
         p_inventory_item_id   IN       NUMBER,
         p_lot_number          IN       VARCHAR2,
         p_transaction_qty     IN OUT   NUMBER,
         p_to_number           IN OUT   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code            NUMBER         := xx_emf_cn_pkg.cn_success;
         x_success               NUMBER;
         p_proc_msg              VARCHAR2 (100);
         x_serial_control_code   NUMBER;
	 x_variable           NUMBER;
         x_lot_control_code   NUMBER;
         x_lot_number_seq     NUMBER;
         x_count              NUMBER        := 0;
         x_lot_number         VARCHAR2 (20);

      BEGIN
         SELECT serial_number_control_code , lot_control_code
           INTO x_serial_control_code ,  x_lot_control_code
           FROM mtl_system_items_b msi
          WHERE msi.organization_id = p_organization_id
            AND msi.inventory_item_id = p_inventory_item_id;

         IF (x_serial_control_code IN (2, 5)) AND x_lot_control_code = 1
         THEN
            IF (p_fm_number IS NOT NULL) AND (p_lot_number IS NULL)
            THEN
            
               x_success :=
                  inv_serial_number_pub.validate_serials
                                           (p_org_id         => p_organization_id,
                                            p_item_id        => p_inventory_item_id,
                                            p_qty            => p_transaction_qty,
                                            p_trx_src_id     => p_tran_id ,
                                            p_trx_action_id  => p_tran_action_id ,
                                            p_start_ser      => p_fm_number,
                                            x_end_ser        => p_to_number,
                                            x_proc_msg       => p_proc_msg
                                           );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Serial Number Validation->'
                                     || p_fm_number
                                     || '-'
                                     || p_organization_id
                                     || '-'
                                     || p_inventory_item_id
                                     || p_to_number
                                    );
                                    
               IF (x_success = 1)
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'SQLCODE NODATA ' || SQLCODE
                                       );
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                      p_error_text               =>    'Invalid To serial Number =>'
                                                    || xx_emf_cn_pkg.cn_no_data,
                      p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                      p_record_identifier_3      => p_cnv_hdr_rec.fm_serial_number
                     );
                  RETURN x_error_code;
               ELSE
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'To Serial Number SUCCESS=>'
                                        || p_to_number
                                       );
                  RETURN x_error_code;
               END IF;
            ELSIF ((p_fm_number IS NOT NULL) AND (p_lot_number IS NOT NULL))  THEN
               xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_low,
                      'Item is serial controlled but lot number is provided =>'
                   || SQLERRM
                  );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Item is serial controlled but lot number is provided =>'
                                                 || xx_emf_cn_pkg.cn_too_many,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.lot_number
                  );
               RETURN x_error_code;
	      
	      ELSIF ((p_fm_number IS NULL) AND (p_lot_number IS NOT NULL))  THEN
               xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_low,
                      'Item serial controlled but fm_serial_number is NULL and Lot number provided  =>'
                   || SQLERRM
                  );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Item serial controlled but fm_serial_number is NULL and Lot number provided =>'
                                                 || xx_emf_cn_pkg.cn_too_many,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.lot_number
                  );
               RETURN x_error_code;
	       ELSIF ((p_fm_number IS NULL) AND (p_lot_number IS NULL))  THEN
               xx_emf_pkg.write_log
                  (xx_emf_cn_pkg.cn_low,
                      'Item serial controlled but fm_serial_number is NULL =>'
                   || SQLERRM
                  );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    'Item serial controlled but fm_serial_number is NULL =>'
                                                 || xx_emf_cn_pkg.cn_no_data,
                   p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                   p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                   p_record_identifier_3      => p_cnv_hdr_rec.item_segment1|| ' - '||p_cnv_hdr_rec.fm_serial_number
                  );
               RETURN x_error_code;
	      
            END IF;
         ELSIF ((x_serial_control_code = 1) AND x_lot_control_code = 1)
         THEN
            IF ((p_fm_number IS NOT NULL) AND (p_lot_number IS NULL))
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item non serial/lot controlled but fm_serial_number provided =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item non serial/lot controlled but fm_serial_number provided =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.fm_serial_number
                    );
               RETURN x_error_code;
	     ELSIF ((p_fm_number IS NOT NULL) AND (p_lot_number IS NOT NULL))
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item non serial/lot controlled but fm_serial_number and lot number provided =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item non serial/lot controlled but fm_serial_number and lot number provided =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.fm_serial_number|| ' - '||p_cnv_hdr_rec.lot_number
                    );
               RETURN x_error_code;

	    ELSIF ((p_fm_number IS NULL) AND (p_lot_number IS NOT NULL))
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item non serial/lot controlled but lot number provided =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item non serial/lot controlled but lot number provided =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.lot_number
                    );
               RETURN x_error_code;
            ELSIF (p_fm_number IS NULL) AND (p_lot_number IS NULL)
            THEN
               RETURN x_error_code;
            END IF;
         --RETURN x_error_code;

	 ELSIF (x_lot_control_code = 2 AND x_serial_control_code = 1)
	THEN
            IF (p_lot_number IS NOT NULL) AND (p_fm_number IS NULL)
            THEN
	       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Lot Number Validation SUCCESS->'
                                        || p_lot_number
                                       );
               RETURN x_error_code;
	     ELSIF (p_lot_number IS NOT NULL) AND (p_fm_number IS NOT NULL) THEN 
		 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item lot controlled but serial number provided =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item lot controlled but serial number provided =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.fm_serial_number
                    );
               RETURN x_error_code;
	        ELSIF (p_lot_number IS NULL) AND (p_fm_number IS NOT NULL) THEN 
		 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item lot controlled but lot number not provided and fm_serial_number provided =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item lot controlled but lot number not provided and fm_serial_number provided =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.fm_serial_number
                    );
               RETURN x_error_code;
                 ELSIF (p_lot_number IS NULL) AND (p_fm_number IS NULL) THEN 
		 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item lot controlled but lot number not provided =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item lot controlled but lot number not provided =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.lot_number
                    );
               RETURN x_error_code;
	  END IF;

	  ELSIF (x_lot_control_code = 2 AND x_serial_control_code IN (2,5))
	  THEN
            IF (p_lot_number IS NOT NULL) AND (p_fm_number IS NULL)
            THEN
	      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item lot/serial controlled but fm_serial_number is null =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item lot/serial controlled but fm_serial_number is null =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.fm_serial_number
                    );
               RETURN x_error_code;
	     ELSIF (p_lot_number IS NULL) AND (p_fm_number IS NULL) THEN 
		 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item lot/serial controlled but lot number/fm_serial_number is null =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item lot/serial controlled but lot number/fm_serial_number is null =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.fm_serial_number||' - '||p_cnv_hdr_rec.lot_number
                    );
               RETURN x_error_code;
	        ELSIF (p_lot_number IS NULL) AND (p_fm_number IS NOT NULL) THEN 
		 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Item lot/serial controlled but lot number is null =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Item lot/serial controlled but lot number is null =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1||' - '||p_cnv_hdr_rec.lot_number
                    );
               RETURN x_error_code;
                 ELSIF (p_lot_number IS NOT NULL) AND (p_fm_number IS NOT NULL) THEN 
                 
		 x_success :=
                  inv_serial_number_pub.validate_serials
                                           (p_org_id         => p_organization_id,
                                            p_item_id        => p_inventory_item_id,
                                            p_trx_src_id     => p_tran_id ,
                                            p_trx_action_id  => p_tran_action_id ,
                                            p_qty            => p_transaction_qty,
                                            p_start_ser      => p_fm_number,
                                            x_end_ser        => p_to_number,
                                            x_proc_msg       => p_proc_msg
                                           );
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Serial Number Validation->'
                                     || p_fm_number
                                     || '-'
                                     || p_organization_id
                                     || '-'
                                     || p_inventory_item_id
                                     || p_to_number
                                    );

              
               IF (x_success = 1)
               THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'SQLCODE NODATA ' || SQLCODE
                                       );
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                      p_error_text               =>    'Invalid To serial Number =>'
                                                    || xx_emf_cn_pkg.cn_no_data,
                      p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                      p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                      p_record_identifier_3      => p_cnv_hdr_rec.fm_serial_number
                     );
                  RETURN x_error_code;
               ELSE
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'To Serial Number SUCCESS=>'
                                        || p_to_number
                                       );
                  RETURN x_error_code;

	  END IF;
         END IF;      
         END IF;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Lot/Serial Number =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Lot/Serial Number =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.fm_serial_number
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Serial Number =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Lot/ To Serial Number =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.fm_serial_number
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors in Serial Number Validation=>'
                                  || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                    p_error_text               =>    'Errors in Lot/Serial Number Validation=>'
                                                  || SQLERRM,
                    p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                    p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                    p_record_identifier_3      => p_cnv_hdr_rec.fm_serial_number
                   );
            RETURN x_error_code;
      END is_serial_lot_number_valid;

      /*--------------------------------------
      -- Function to validate lot_divisible_flag
      --@param1 -- p_organization_id
      --@param2 -- p_inventory_item_id
      ----------------------------------------*/
      FUNCTION is_lot_divisible_valid (
         p_organization_id     IN              NUMBER,
         p_inventory_item_id   IN              NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code         NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable           NUMBER;
         x_lot_control_code   NUMBER;
         x_lot_number         VARCHAR2 (20);
 	 x_lot_div_flag       VARCHAR2(10):= 'N';
      BEGIN
         SELECT lot_control_code , lot_divisible_flag
           INTO x_lot_control_code , x_lot_div_flag
           FROM mtl_system_items_b msi
          WHERE msi.organization_id = p_organization_id
            AND msi.inventory_item_id = p_inventory_item_id;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Lot Divisible Validation->'
                               || p_organization_id
                               || '-'
                               || p_inventory_item_id
                               || x_lot_control_code
                              );

         IF (x_lot_control_code = 2)  
         THEN
		IF (NVL(x_lot_div_flag,'N') = 'N')  --Modified on 26-NOV-14 added NVL
	       THEN
	         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Lot Divisible Flag should be Y =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               => 'Lot Divisible Flag should be Y =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
               RETURN x_error_code;
	    ELSIF (NVL(x_lot_div_flag,'N') = 'Y')
	     THEN
                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Lot Divisible Validation successful->'
                                        || p_inventory_item_id
                                       );
		RETURN x_error_code;
	   END IF;   

         ELSIF (x_lot_control_code = 1) THEN
            RETURN x_error_code;
         END IF;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Lot Divisible Flag =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Lot Divisible =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Lot Divisible =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Lot Divisible =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors in Lot Divisible flag Validation=>'
                                  || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Errors in Lot Divisible flag Validation=>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
      END is_lot_divisible_valid;


 /*--------------------------------------
      -- Function to validate shelf life 
      --@param1 -- p_organization_id
      --@param2 -- p_inventory_item_id
      --@param3 -- p_expiration_date
      ----------------------------------------*/
      FUNCTION is_shelf_life_valid (
         p_organization_id     IN              NUMBER,
         p_inventory_item_id   IN              NUMBER,
	 p_expiration_date     IN              DATE
      )
         RETURN NUMBER
      IS
         x_error_code         NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable           NUMBER;
         x_shelf_life_code   NUMBER;
      BEGIN
         SELECT shelf_life_code
           INTO x_shelf_life_code
           FROM mtl_system_items_b msi
          WHERE msi.organization_id = p_organization_id
            AND msi.inventory_item_id = p_inventory_item_id;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Shelf Life Validation->'
                               || p_organization_id
                               || '-'
                               || p_inventory_item_id
                               || x_shelf_life_code
                              );

         IF (x_shelf_life_code IN (2,4))
         THEN
		IF (p_expiration_date IS NULL)
	       THEN
	         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Expiration Date should be present =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               => 'Expiration Date should be present =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
               RETURN x_error_code;
	    ELSIF (p_expiration_date IS NOT NULL)
	     THEN
                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Shelf Life Validation successful->'
                                        || p_inventory_item_id
                                       );
		RETURN x_error_code;
	   END IF;   

         ELSIF (x_shelf_life_code = 1)
	 THEN
		IF (p_expiration_date IS NOT NULL)
	       THEN
	         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Expiration Date should not be present =>'
                                     || SQLERRM
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               => 'Expiration Date should not be present =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
               RETURN x_error_code;
	    ELSIF (p_expiration_date IS NULL)
	     THEN
                xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                           'Shelf Life Validation successful->'
                                        || p_inventory_item_id
                                       );
		RETURN x_error_code;
	   END IF;   
         END IF;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Shelf Life =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Shelf Life =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Shelf Life =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Shelf Life =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors in Shelf Life Validation=>'
                                  || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Errors in Shelf Life Validation=>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.item_segment1
                    );
            RETURN x_error_code;
      END is_shelf_life_valid;


/*--------------------------------------
      -- Function to derive revision
      --@param1 -- p_item_number
      --@param2 -- p_organization_id
      --@param3 -- p_revision
      ----------------------------------------*/
      FUNCTION is_revision_valid (
         p_item_number       IN       VARCHAR2,
         p_organization_id   IN       NUMBER,
         p_revision          OUT      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code              NUMBER        := xx_emf_cn_pkg.cn_success;
         x_err_code                VARCHAR2 (30);
         x_variable                VARCHAR2 (4);
         x_count                   NUMBER;
         x_space                   VARCHAR2 (10);
         n_itemnumber              NUMBER;
         l_itemfnd                 NUMBER;
         x_revision_control_code   NUMBER;
      BEGIN
         FOR rec IN (SELECT   revision
                         FROM mtl_item_revisions
                        WHERE inventory_item_id =
                                 (SELECT inventory_item_id
                                    FROM mtl_system_items_b msi
                                   WHERE msi.segment1 = p_item_number
                                     AND organization_id = p_organization_id
                                     AND revision_qty_control_code = 2)
                          AND organization_id = p_organization_id
                          AND TRUNC (SYSDATE) >= TRUNC (effectivity_date)
                     ORDER BY effectivity_date DESC)
         LOOP
            p_revision := rec.revision;
            RETURN x_error_code;
         END LOOP;
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Revision =>' || p_revision
                                 );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Revision =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Revision =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.revision
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Revision =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid Revision =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.revision
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors in Revision Validation=>'
                                  || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Errors in Revision Validation=>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.revision
                    );
            RETURN x_error_code;
      END is_revision_valid;

         /*--------------------------------------
      -- Function to derive LPN_ID
      --@param1 -- p_lpn_number
      --@param1 -- p_lpn_id
      ----------------------------------------*/
      FUNCTION is_lpn_number_valid (
         p_lpn_number   IN       VARCHAR2,
	 p_organization_id     IN       NUMBER,
         p_lpn_id       OUT      VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_code     VARCHAR2 (30);
         x_err_msg      VARCHAR2 (200);
      BEGIN
         SELECT lpn_id
           INTO p_lpn_id
           FROM wms_license_plate_numbers
          WHERE license_plate_number = p_lpn_number
	  and organization_id = p_organization_id;

         -- get the lpn id
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'LPN ID SUCCESS=>' || p_lpn_id
                              );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid LPN  =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid LPN =>'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.lpn_number
                    );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid LPN =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Invalid LPN =>'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.lpn_number
                    );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors in LPN Validation=>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                    (p_severity                 => xx_emf_cn_pkg.cn_medium,
                     p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                     p_error_text               =>    'Errors in LPN Validation=>'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                     p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                     p_record_identifier_3      => p_cnv_hdr_rec.lpn_number
                    );
            RETURN x_error_code;
      END is_lpn_number_valid;

        /*--------------------------------------
      -- Function to validate transaction qty
      --@param1 -- p_itm_transaction_qty
      ----------------------------------------*/
      FUNCTION is_transaction_qty_valid (p_itm_transaction_qty IN OUT VARCHAR2
                                         )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_msg      VARCHAR2 (200);
      BEGIN
         IF (p_itm_transaction_qty <= 0)
         THEN
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Transaction qty must be greater than 0 =>'
                               || p_itm_transaction_qty
                              );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    'Transaction qty must be greater than 0 =>'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                p_record_identifier_3      => p_cnv_hdr_rec.transaction_quantity
               );
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Transaction_qty SUCCESS=>'
                                  || p_itm_transaction_qty
                                 );
            RETURN x_error_code;
         END IF;
      END is_transaction_qty_valid;

       /*--------------------------------------
      -- Function to validate lot transaction qty
      --@param1 -- p_mtli_transaction_qty
      ----------------------------------------*/
      FUNCTION is_lot_transaction_qty_valid (p_mtli_transaction_qty IN OUT VARCHAR2
                                         )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;
         x_err_msg      VARCHAR2 (200);
      BEGIN
         IF (p_mtli_transaction_qty <= 0)
         THEN
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Lot Transaction qty must be greater than 0 =>'
                               || p_mtli_transaction_qty
                              );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    'Lot Transaction qty must be greater than 0 =>'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_hdr_rec.record_number,
                p_record_identifier_2      => p_cnv_hdr_rec.organization_name,
                p_record_identifier_3      => p_cnv_hdr_rec.mtli_transactions_quantity
               );
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Lot Transaction_qty SUCCESS=>'
                                  || p_mtli_transaction_qty
                                 );
            RETURN x_error_code;
         END IF;
      END is_lot_transaction_qty_valid;
   ------------------------ Start the BEGIN part of Data Validations ----------------------------------
   -- Start of the main function perform_batch_validations
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Validations');

      IF (p_cnv_hdr_rec.organization_name IS NOT NULL)
      THEN
         x_error_code_temp :=
            is_organization_valid (p_cnv_hdr_rec.organization_name,
                                   p_cnv_hdr_rec.organization_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                'is_orgn_code_valid not called as organization_code is null '
               );
      END IF;

      IF (p_cnv_hdr_rec.mti_owning_organization_name IS NOT NULL)
      THEN
         x_error_code_temp :=
            is_owning_organization_valid (p_cnv_hdr_rec.mti_owning_organization_name,
                                   p_cnv_hdr_rec.mti_owning_organization_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                'is_owning_organization_valid not called as owning_organization_code is null '
               );
      END IF;
    
      IF (p_cnv_hdr_rec.item_segment1 IS NOT NULL)
      THEN
         x_error_code_temp :=
            is_item_number_valid (p_cnv_hdr_rec.item_segment1,
                                  p_cnv_hdr_rec.organization_id,
                                  p_cnv_hdr_rec.inventory_item_id
                                 );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log
                 (xx_emf_cn_pkg.cn_low,
                  'is_item_number_valid not called as item_segment1 is null '
                 );
      END IF;

      IF (p_cnv_hdr_rec.item_segment1 IS NOT NULL)
      THEN
         x_error_code_temp :=
            is_item_inv_transact_valid (p_cnv_hdr_rec.item_segment1,
                                  p_cnv_hdr_rec.organization_id
                                 );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log
                 (xx_emf_cn_pkg.cn_low,
                  'is_item_inv_transact_valid not called as item_segment1 is null '
                 );
      END IF;

      IF (p_cnv_hdr_rec.subinventory_code IS NOT NULL)
      THEN
         x_error_code_temp :=
            is_location_sub_code_valid (p_cnv_hdr_rec.loc_segment1,
                                    p_cnv_hdr_rec.loc_segment2,
                                    p_cnv_hdr_rec.loc_segment3,
                                    p_cnv_hdr_rec.organization_id,
                                    p_cnv_hdr_rec.subinventory_code,
				    p_cnv_hdr_rec.organization_name
                                   );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log
             (xx_emf_cn_pkg.cn_low,
              'is_location_sub_code_valid not called as subinventory is null '
             );
      END IF;
      x_error_code_temp :=
         is_transaction_type_valid (p_cnv_hdr_rec.transaction_type_name,
                                    p_cnv_hdr_rec.transaction_type_id
                                   );
      x_error_code := find_max (x_error_code, x_error_code_temp);

       x_error_code_temp :=
         is_transaction_source_valid (p_cnv_hdr_rec.transaction_source_name,   --16th-AUG-12
	                              p_cnv_hdr_rec.organization_id,
                                    p_cnv_hdr_rec.transaction_source_id
                                   );
      x_error_code := find_max (x_error_code, x_error_code_temp);

      IF     (p_cnv_hdr_rec.item_segment1 IS NOT NULL)
         AND (p_cnv_hdr_rec.organization_id IS NOT NULL)
      THEN
         x_error_code_temp :=
            is_transaction_uom_valid (p_cnv_hdr_rec.item_segment1,
                                      p_cnv_hdr_rec.organization_id,
                                      p_cnv_hdr_rec.transaction_uom
                                     );
         x_error_code := find_max (x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
             'is_transaction_uom_valid not called as item number and organization is null '
            );
      END IF;

      x_error_code_temp :=
         is_serial_lot_number_valid (p_cnv_hdr_rec.fm_serial_number,
                                 p_cnv_hdr_rec.organization_id,
                                 p_cnv_hdr_rec.transaction_source_id,
                                 p_cnv_hdr_rec.transaction_action_id,
                                 p_cnv_hdr_rec.inventory_item_id,
                                 p_cnv_hdr_rec.lot_number,
                                 p_cnv_hdr_rec.transaction_quantity,
                                 p_cnv_hdr_rec.to_serial_number				 
                                );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_revision_valid (p_cnv_hdr_rec.item_segment1,
                            p_cnv_hdr_rec.organization_id,
                            p_cnv_hdr_rec.revision
                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);

      IF (p_cnv_hdr_rec.lpn_number IS NOT NULL)
      THEN
         x_error_code_temp :=
            is_lpn_number_valid (p_cnv_hdr_rec.lpn_number,
				 p_cnv_hdr_rec.organization_id,
                                 p_cnv_hdr_rec.transfer_lpn_id
                                );
	 x_error_code := find_max (x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log
             (xx_emf_cn_pkg.cn_low,
              'is_lpn_number_valid not called as lpn number is null '
             );
      END IF;
      x_error_code := find_max (x_error_code, x_error_code_temp);
      x_error_code_temp :=
         is_lot_divisible_valid (p_cnv_hdr_rec.organization_id,
                              p_cnv_hdr_rec.inventory_item_id
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.propagate_error (x_error_code_temp);
      x_error_code_temp :=
         is_shelf_life_valid (p_cnv_hdr_rec.organization_id,
                              p_cnv_hdr_rec.inventory_item_id,
			      p_cnv_hdr_rec.lot_expiration_date
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.propagate_error (x_error_code_temp);
      x_error_code_temp :=
                 is_transaction_qty_valid (p_cnv_hdr_rec.transaction_quantity
		                           );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.propagate_error (x_error_code_temp);
      x_error_code_temp :=
                 is_lot_transaction_qty_valid (p_cnv_hdr_rec.mtli_transactions_quantity
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
   END data_validations;

-----------------------------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------
    -------------------< POST VALIDATION >--------------------------
    ----------------------------------------------------------------------
   FUNCTION post_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Post-Validations');
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
   END post_validations;

-----------------------------------------------------------------------------------------------------------------------

   ----------------------------------------------------------------------
-------------------< DATA DERIVATIONS >--------------------------
----------------------------------------------------------------------
   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT NOCOPY   xx_inv_itemonhandqty_pkg.g_xx_inv_itemqoh_pre_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

----------------------------------------------------------------------
-------------------< get_distribution_account >-----------------------
----------------------------------------------------------------------
      FUNCTION get_distribution_account (
         p_organization_id        IN       NUMBER,
         p_inventory_item_id      IN       NUMBER,
         p_distribution_account   OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code            NUMBER         := xx_emf_cn_pkg.cn_success;
         x_bg_id                 VARCHAR2 (40);
         x_business_group_name   VARCHAR2 (100);
      BEGIN
         SELECT cost_of_sales_account
           INTO p_distribution_account
           FROM mtl_system_items
          WHERE inventory_item_id = p_inventory_item_id
            AND organization_id = p_organization_id;

         xx_emf_pkg.write_log
                          (xx_emf_cn_pkg.cn_high,
                              'ON Hand Qty:1: Cost of Goods Sold Account ID=>'
                           || p_distribution_account
                           || '-'
                           || p_cnv_pre_std_hdr_rec.inventory_item_id
                           || ';'
                           || p_organization_id
                          );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Distribution Account =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               =>    'Invalid Distribution Account =>'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.source_line_id,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.organization_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.item_segment1
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Invalid Distribution Account =>' || SQLERRM
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               =>    'Invalid Distribution Account =>'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.source_line_id,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.organization_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.item_segment1
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'Error: Deriving Distribution Account =>'
                                 || SQLERRM
                                );
            x_error_code := xx_emf_cn_pkg.cn_prc_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               =>    'Error: Deriving Distribution Account =>'
                                              || SQLERRM,
                p_record_identifier_1      => p_cnv_pre_std_hdr_rec.source_line_id,
                p_record_identifier_2      => p_cnv_pre_std_hdr_rec.organization_name,
                p_record_identifier_3      => p_cnv_pre_std_hdr_rec.item_segment1
               );
            RETURN x_error_code;
      END get_distribution_account;
-------------------------------------------------------
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Data-Derivations');
      x_error_code_temp :=
         get_distribution_account (p_cnv_pre_std_hdr_rec.organization_id,
                                   p_cnv_pre_std_hdr_rec.inventory_item_id,
                                   p_cnv_pre_std_hdr_rec.distribution_account_id
                                  );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.propagate_error (x_error_code_temp);
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
END xx_inv_item_onhandval_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEM_ONHANDVAL_PKG TO INTG_XX_NONHR_RO;
