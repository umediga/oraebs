DROP PACKAGE BODY APPS.XX_INV_ITEMCOST_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ITEMCOST_PKG" AS
  /* $Header: XXINVITEMCOSTCNV.pkb 1.0.1 2012/03/12 00:00:00 partha noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 14-FEB-2012
  -- Filename       : XXINVITEMCOSTCNV.pkb
  -- Description    : Package body for Item Cost Import

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 20-Jan-2012   1.0       Partha S Mohanty    Initial development.
--====================================================================================
   g_request_id NUMBER := fnd_profile.VALUE('CONC_REQUEST_ID');

   g_user_id NUMBER := fnd_global.user_id; --fnd_profile.VALUE('USER_ID');

   g_resp_id NUMBER := fnd_profile.VALUE('RESP_ID');
   ctr  number(30) := 1;

------------------< set_cnv_env >-----------------------------------------------
--------------------------------------------------------------------------------
    PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                          ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                          ) IS
    	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
    	G_BATCH_ID	  := p_batch_id;
    	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID: '||G_BATCH_ID );

    	-- Set the environment
    	x_error_code := xx_emf_pkg.set_env;
    	IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
    		xx_emf_pkg.propagate_error(x_error_code);
    	END IF;
    EXCEPTION
    	WHEN OTHERS THEN
    		RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
    END set_cnv_env;

   PROCEDURE dbg_low (p_dbg_text varchar2)
      IS
      BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low
                                , 'In xxs_inv_itemcost_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_low;

    PROCEDURE dbg_med (p_dbg_text varchar2)
      IS
      BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                                , 'In xxs_inv_itemcost_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_med;

------------------< mark_records_for_processing >-------------------------------
--------------------------------------------------------------------------------

    PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2
                                          ) IS
    	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
    	-- If the override is set records should not be purged from the pre-interface tables
      g_api_name := 'mark_records_for_processing';
    	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside of mark records for processing...');

    	IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN

    			UPDATE xx_cst_item_upload_stg -- Item Cost Staging
    			   SET request_id = xx_emf_pkg.G_REQUEST_ID,
    			       error_code = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_BATCH_ID;


             DELETE FROM CST_ITEM_CST_DTLS_INTERFACE;
                      -- WHERE attribute11 = G_BATCH_ID;

    	ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN


    			-- Update Item Cost Staging
    			UPDATE xx_cst_item_upload_stg
    			   SET request_id   = xx_emf_pkg.G_REQUEST_ID,
    			       error_code   = xx_emf_cn_pkg.CN_NULL,
    			       process_code = xx_emf_cn_pkg.CN_NEW,
                 error_mesg = NULL
    			 WHERE batch_id = G_BATCH_ID
    				       AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				       xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);

    			DELETE FROM CST_ITEM_CST_DTLS_INTERFACE;
                      -- WHERE attribute11 = G_BATCH_ID;

          END IF;


          COMMIT;

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark records for processing...');
    END;

    --------------------------------------------------------------------------------
    -----------------< set_stage >--------------------------------------------------
    --------------------------------------------------------------------------------

    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
    	G_STAGE := p_stage;
    END set_stage;


    PROCEDURE dbg_high (p_dbg_text varchar2)
      IS
      BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                                , 'In xxs_inv_itemcost_pkg.' || g_api_name || ': ' || p_dbg_text
                                 );
    END dbg_high;

-----------------< update_staging_records >-------------------------------------
--------------------------------------------------------------------------------

PROCEDURE update_staging_records( p_error_code VARCHAR2) IS

	x_last_update_date     DATE   := SYSDATE;
	x_last_updated_by      NUMBER := fnd_global.user_id;
	x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

	PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
 g_api_name := 'update_staging_records';
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside update_staging_records...');

	UPDATE xx_cst_item_upload_stg
	   SET process_code = G_STAGE,
	       error_code = DECODE ( error_code, NULL, p_error_code, error_code),
	       last_update_date = x_last_update_date,
	       last_updated_by   = x_last_updated_by,
	       last_update_login = x_last_update_login -- In template please made change
	 WHERE batch_id		= G_BATCH_ID
	   AND request_id	= xx_emf_pkg.G_REQUEST_ID
	   AND process_code	= xx_emf_cn_pkg.CN_NEW; --xx_emf_cn_pkg.CN_NEW; ***DS - to dynamically change process at different stages (pre-val/data-deri)

	COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating staging records status: '||SQLERRM);

END update_staging_records;

--**********************************************************************
  --Function to Find Max.
--**********************************************************************

  FUNCTION find_max (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
       )
    RETURN VARCHAR2
   IS
      x_return_value VARCHAR2(100);
   BEGIN
      x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);

    RETURN x_return_value;
  END find_max;

   -- pre_validations

   FUNCTION pre_validations
    RETURN NUMBER
    IS
     x_error_code    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

     -- Cursor for duplicate header record
     CURSOR c_xx_itemcost_dup IS
     SELECT
          ic1.inventory_item
	        ,ic1.inv_organization_code
	        ,ic1.resource_code
          FROM   xx_cst_item_upload_stg ic1
          WHERE  ic1.rowid<>(SELECT min(ic2.rowid)
                   FROM xx_cst_item_upload_stg ic2
                   WHERE ic2.inventory_item = ic1.inventory_item
                   AND ic2.inv_organization_code = ic1.inv_organization_code
                   AND ic2.resource_code = ic1.resource_code
                   AND ic2.process_code = xx_emf_cn_pkg.CN_NEW
                   AND ic2.batch_id	= G_BATCH_ID
                   )
          AND ic1.process_code = xx_emf_cn_pkg.CN_NEW
          AND ic1.batch_id	=G_BATCH_ID
          FOR UPDATE OF ic1.process_code
              ,ic1.error_code
              ,ic1.error_mesg;

BEGIN
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations : Duplicate checking');

     --Start of the loop to print all the headers that are duplicate in the staging table
     dbg_low('Following records are duplicate Item Cost records');
      FOR cnt IN c_xx_itemcost_dup
      LOOP
           UPDATE xx_cst_item_upload_stg
           SET process_code = xx_emf_cn_pkg.CN_PREVAL,
               error_code = xx_emf_cn_pkg.CN_REC_ERR
              ,error_mesg='Duplicate record exists in the header staging table'
           WHERE CURRENT OF c_xx_itemcost_dup;

           dbg_low('Inventory item:     '||cnt.inventory_item);
           dbg_low('Organization Code:      '||cnt.inv_organization_code);
           dbg_low('Resource Code:      '||cnt.resource_code);

      END LOOP;--End of LOOP to print the duplicate records in the staging table
     commit;
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


   /*-------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   XX_ITEMCOST_VALIDATION
   Parameters       :   P_ERROR_FLAG IN OUT VARCHAR2
   Purpose          :   Item Cost Validation
   --------------------------------------------------------------------------------------------------------------------*/
  FUNCTION xx_itemcost_validation(csr_itemcost_print_rec IN OUT xx_inv_itemcost_pkg.G_XX_ITEMCOST_STG_REC_TYPE
                          ) RETURN NUMBER
     IS

      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      l_invorg_id          NUMBER := NULL;
      l_item_id            NUMBER := NULL;
      l_make_buy_code      NUMBER := NULL;
      x_org_code           VARCHAR2(3):= NULL;

    FUNCTION is_org_code_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2)
           RETURN number
           IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            IF p_org_code IS NULL THEN
                dbg_med('Organization Code can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code can not be Null'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );

              return x_error_code;
            ELSE
             BEGIN

               x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINVITEMCOSTCNV'
                                  ,p_date_effective => sysdate
                                  );
                dbg_low('Mapped Organization Code : '||x_org_code);
                SELECT mp.organization_id
                 INTO l_invorg_id
                  FROM mtl_parameters mp
                 WHERE mp.organization_code = x_org_code;
                 RETURN  x_error_code;
             EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Organization Code does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the Organization Code');
                  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Organization Code'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                         ,p_record_identifier_4 => NULL
                        );
                RETURN  x_error_code;
             END;
            END IF;
           END;


         -----------------------------------------------------------------------------------------------
         --Validate Item Number
         -----------------------------------------------------------------------------------------------
       FUNCTION is_inventory_item_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2)
           RETURN number
           IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           begin
            IF p_inventory_item IS NULL THEN
                dbg_med('Item Number can not be Null ');
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Number can not be Null;'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );

              return x_error_code;
            ELSE
            ---
             BEGIN
               SELECT a.inventory_item_id
                 INTO l_item_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = p_inventory_item
                     AND a.organization_id = l_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                RETURN  x_error_code;
              EXCEPTION
                WHEN no_data_found THEN
                  dbg_med('Invalid Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Invalid Item Number'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validaing Item Number');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validaing Item Number'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                  RETURN  x_error_code;
              END ;
            END IF;
           END;
        ------
        -- is_item_cost_flag_valid -- NEW For UAT

        FUNCTION is_item_cost_flag_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
             x_cost_enabled_flag VARCHAR2(1):= NULL;
           BEGIN
               SELECT costing_enabled_flag  INTO x_cost_enabled_flag
                 from mtl_system_items_b msi
                   WHERE msi.organization_id = l_invorg_id
                     AND msi.segment1 = p_inventory_item;

              IF  UPPER(x_cost_enabled_flag) = 'Y' THEN
                    return x_error_code;
              ELSIF NVL(UPPER(x_cost_enabled_flag),'N') = 'N' THEN
                   dbg_med('Item Is not Costing Enabled');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Is not Costing Enabled'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                   return x_error_code;
              END IF;
              return x_error_code;
             EXCEPTION
               WHEN no_data_found THEN
                   dbg_med('Item Is not Costing Enabled');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Is not Costing Enabled'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                   return x_error_code;

               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating Costing Enabled ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while validating Costing Enabled'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                    return x_error_code;
      END is_item_cost_flag_valid;

        -- is_buy_item_valid
       FUNCTION is_buy_item_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN
               SELECT count('x')  into l_make_buy_code
                 from MTL_SYSTEM_ITEMS_VL msi,
                      MFG_LOOKUPS ml
                   WHERE msi.organization_id = l_invorg_id
                     AND msi.inventory_item_id = l_item_id
                     AND ml.lookup_type = 'MTL_PLANNING_MAKE_BUY'
                     AND ml.lookup_code = msi.planning_make_buy_code
                     AND ml.meaning = 'Buy';
              IF  nvl(l_make_buy_code,0) >=1 THEN
                return x_error_code;
              ELSIF nvl(l_make_buy_code,0) <=0 THEN
                 dbg_med('Item Is not a valid Buy Item');
                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Is not a valid Buy Item'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                return x_error_code;
              END IF;
             EXCEPTION
               WHEN no_data_found THEN
                   dbg_med('Item Is not a valid Buy Item');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Item Is not a valid Buy Item'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                   return x_error_code;

               WHEN OTHERS THEN
                  dbg_med('Unexpected error while validating the ''Buy'' Item Code ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while validating the ''Buy'' Item Code '
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                    return x_error_code;
            END is_buy_item_valid;


         -----------------------------------------------------------------------------------------------
         --Validate the Resource Code
         -----------------------------------------------------------------------------------------------
       FUNCTION is_resource_code_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2,p_resource_code VARCHAR2)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
             l_resource_id	   NUMBER;
           BEGIN
            IF p_resource_code IS NOT NULL THEN
             BEGIN
	            SELECT   resource_id
                 INTO   l_resource_id
                 FROM   bom_resources br
		                    ,org_organization_definitions  ood
                WHERE   br.organization_id    = ood.organization_id
		                  AND   br.resource_code      = p_resource_code
                      AND   ood.organization_code = x_org_code;   -- Change
                return x_error_code;
             EXCEPTION
               WHEN no_data_found THEN
                   dbg_med('Resource Code does not exist ');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource Code does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                   return x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Resource Code ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Resource Code '
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                    return x_error_code;
             END;
            ELSE
                  dbg_med('Resource Code is NULL ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Resource Code is NULL'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                    return x_error_code;
            END IF;
           END;

         -----------------------------------------------------------------------------------------------
         --Validate the Cost Element
         -----------------------------------------------------------------------------------------------

      FUNCTION is_cost_element_valid(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2,p_cost_element VARCHAR2)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
             l_cost_element_id	   NUMBER;

           BEGIN

            IF p_cost_element NOT IN('Material','Material Overhead') THEN
                 dbg_med('Cost Element is not valid for Item Cost Import.');
                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                 xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Cost Element is not valid for Item Cost Import.'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                return x_error_code;
             ELSE
                return x_error_code;
             END IF;

          /* IF p_cost_element IS NOT NULL THEN
            BEGIN
	             SELECT DISTINCT   a.cost_element_id
                 INTO   l_cost_element_id
                 FROM   cst_cost_elements a,
                        cst_item_cost_details b,
                        org_organization_definitions od
                WHERE   a.cost_element_id    = b.cost_element_id
                  AND   od.organization_id   = b.organization_id
                  AND   od.organization_code = x_org_code            -- changed
		              AND   a.cost_element       IN ('Material','Material Overhead')
                  AND   a.cost_element       = p_cost_element;
                 return x_error_code_temp;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Cost Element is not valid for Item Cost Import.');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Cost Element is not valid for Item Cost Import.'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                   return x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while validating the Cost Element ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_VALID
                         ,p_error_text  => 'Unexpected error while validating the Cost Element '
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item

                        );
                   return x_error_code;

            END;
         ELSE
            return x_error_code;
         END IF; */
       END is_cost_element_valid;


	BEGIN
    g_api_name := 'xx_itemcost_validation';
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');
    x_error_code_temp := is_org_code_valid(csr_itemcost_print_rec.record_number,
                                      csr_itemcost_print_rec.inv_organization_code,
                                      csr_itemcost_print_rec.inventory_item
		                                  );
		x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

     x_error_code_temp := is_inventory_item_valid(csr_itemcost_print_rec.record_number,
                                      csr_itemcost_print_rec.inv_organization_code,
                                      csr_itemcost_print_rec.inventory_item
		                                  );
		x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

    x_error_code_temp := is_item_cost_flag_valid(csr_itemcost_print_rec.record_number,
                                                 csr_itemcost_print_rec.inv_organization_code,
                                                 csr_itemcost_print_rec.inventory_item);
    x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

    If upper(g_make_buy) = 'BUY' THEN  -- Added in UAT
       x_error_code_temp := is_buy_item_valid(csr_itemcost_print_rec.record_number,
                                      csr_itemcost_print_rec.inv_organization_code,
                                      csr_itemcost_print_rec.inventory_item
		                                  );
		   x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);
    End if;

    x_error_code_temp := is_resource_code_valid(csr_itemcost_print_rec.record_number,
                                      csr_itemcost_print_rec.inv_organization_code,
                                      csr_itemcost_print_rec.inventory_item,
                                      csr_itemcost_print_rec.resource_code
		                                  );
		x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);

    x_error_code_temp := is_cost_element_valid(csr_itemcost_print_rec.record_number,
                                      csr_itemcost_print_rec.inv_organization_code,
                                      csr_itemcost_print_rec.inventory_item,
                                      csr_itemcost_print_rec.cost_element
		                                  );
		x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp);


    xx_emf_pkg.propagate_error (x_error_code_temp);

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

   END xx_itemcost_validation;


  /*-------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   XX_ITEMCOST_DATA_DERIVATIONS
   Parameters       :   P_ERROR_FLAG IN OUT VARCHAR2
   Purpose          :   Item Cost Derivations
   --------------------------------------------------------------------------------------------------------------------*/
  FUNCTION xx_itemcost_data_derivations(csr_itemcost_print_rec IN OUT xx_inv_itemcost_pkg.G_XX_ITEMCOST_STG_REC_TYPE
                          ) RETURN NUMBER
     IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      l_invorg_id          NUMBER := NULL;
      l_item_id            NUMBER := NULL;
      l_make_buy_code      NUMBER := NULL;
      l_resource_id        NUMBER := NULL;
      x_org_code           VARCHAR2(3):= NULL;

       FUNCTION get_org_id(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2,p_org_id OUT NUMBER,p_org_code_orig OUT VARCHAR2)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN
               x_org_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value1   =>trim(p_org_code)
                                  ,p_old_value2   =>'XXINVITEMCOSTCNV'
                                  ,p_date_effective => sysdate
                                  );
               SELECT mp.organization_id
                 INTO l_invorg_id
                 FROM mtl_parameters mp
                WHERE mp.organization_code = x_org_code;
                p_org_id := l_invorg_id;
                p_org_code_orig := x_org_code; -- used only for reference
                RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Organization Code does not exist ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Organization Code does not exist'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                         ,p_record_identifier_4 => NULL
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving the Organization Code');
                  x_error_code_temp := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving the Organization Code'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                         ,p_record_identifier_4 => NULL
                        );
                RETURN  x_error_code;
            END get_org_id;

          --get the item_id

       FUNCTION get_item_id(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2,p_inv_item_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
          BEGIN
               SELECT a.inventory_item_id
                 INTO l_item_id
                 FROM mtl_system_items_b a
                WHERE a.segment1 = p_inventory_item
                     AND a.organization_id = l_invorg_id
                     AND a.bom_enabled_flag = 'Y'
                     AND a.enabled_flag = 'Y';
                p_inv_item_id := l_item_id;
               RETURN  x_error_code;
            EXCEPTION
               WHEN no_data_found THEN
                  dbg_med('Unable to derive Inventory Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Inventory Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                  RETURN  x_error_code;
               WHEN OTHERS THEN
                  dbg_med('Unexpected error while deriving Inventory Item id');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving Inventory Item id'
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                  RETURN  x_error_code;
            END get_item_id;

       FUNCTION get_resource_id(p_rec_number NUMBER,p_org_code VARCHAR2,p_inventory_item VARCHAR2,p_resource_code VARCHAR2,p_resource_id OUT NUMBER)
           RETURN number
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           BEGIN
	            SELECT   resource_id
                 INTO   l_resource_id
                 FROM   bom_resources br
		                    ,org_organization_definitions  ood
                WHERE   br.organization_id    = ood.organization_id
		                  AND   br.resource_code      = p_resource_code
                      AND   ood.organization_code = x_org_code;
                p_resource_id :=  l_resource_id;
                return x_error_code;
             EXCEPTION
               WHEN no_data_found THEN
                   dbg_med('Unable to derive Resource Id ');
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unable to derive Resource Id '
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                   return x_error_code;

               WHEN OTHERS THEN
                  dbg_med(' Unexpected error while deriving the Resource Id ');
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATADRV
                         ,p_error_text  => 'Unexpected error while deriving the Resource Id '
                         ,p_record_identifier_1 => p_rec_number
                         ,p_record_identifier_2 => p_org_code
                         ,p_record_identifier_3 => p_inventory_item
                        );
                    return x_error_code;
            END get_resource_id;


    BEGIN
      g_api_name := 'xx_itemcost_data_derivations';
       --get the organization_id
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivations');
	   x_error_code_temp := get_org_id (csr_itemcost_print_rec.record_number,
                                          csr_itemcost_print_rec.inv_organization_code,
                                          csr_itemcost_print_rec.inventory_item,
                                          csr_itemcost_print_rec.organization_id,
                                          csr_itemcost_print_rec.organization_code
		                                      );

       x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );

       x_error_code_temp := get_item_id (csr_itemcost_print_rec.record_number,
                                          csr_itemcost_print_rec.inv_organization_code,
                                          csr_itemcost_print_rec.inventory_item,
                                          csr_itemcost_print_rec.inventory_item_id
		                                      );

       x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );


       x_error_code_temp := get_resource_id (csr_itemcost_print_rec.record_number,
                                             csr_itemcost_print_rec.inv_organization_code,
                                             csr_itemcost_print_rec.inventory_item,
                                             csr_itemcost_print_rec.resource_code,
                                             csr_itemcost_print_rec.resource_id
		                                      );

       x_error_code      := FIND_MAX(x_error_code, x_error_code_temp );


       xx_emf_pkg.propagate_error ( x_error_code_temp );
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
	END xx_itemcost_data_derivations;

  FUNCTION post_validations
   RETURN NUMBER
    IS
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
     g_api_name := 'main.post_validations';
		 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');

     -- Update 'MTL' records with error if 'MTLOH' records are errored out
    /*
    UPDATE xx_cst_item_upload_stg a
    			   SET error_code = xx_emf_cn_pkg.CN_REC_ERR,
    			       process_code = xx_emf_cn_pkg.CN_POSTVAL,
                 error_mesg='Error out due to corresponding ''Material Overhead'' record error'
             WHERE cost_element = 'Material'
                 AND  NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
    				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
                 AND (a.inventory_item,a.inv_organization_code) IN ( select b.inventory_item,b.inv_organization_code
                                                                          from xx_cst_item_upload_stg b
                                                                          where a.inventory_item= b.inventory_item
                                                                           and  a.inv_organization_code=b.inv_organization_code
                                                                           AND  b.cost_element = 'Material Overhead'
                                                                           AND  nvl(b.error_mesg,'XX') not like 'Duplicate%'
                                                                           AND  NVL (b.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				                                                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR));


      -- Update 'MTLOH' records with error if 'MTL' records are errored out
     UPDATE xx_cst_item_upload_stg a
    			   SET error_code =xx_emf_cn_pkg.CN_REC_ERR,
    			       process_code = xx_emf_cn_pkg.CN_POSTVAL,
                 error_mesg='Error out due to corresponding ''Material'' record error'
             WHERE cost_element = 'Material Overhead'
                 AND  NVL (a.error_code, xx_emf_cn_pkg.CN_REC_ERR) NOT IN (
    				            xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR)
                 AND (a.inventory_item,a.inv_organization_code) IN ( select b.inventory_item,b.inv_organization_code
                                                                          from xx_cst_item_upload_stg b
                                                                          where a.inventory_item= b.inventory_item
                                                                           and  a.organization_code=b.inv_organization_code
                                                                           AND  b.cost_element = 'Material'
                                                                           AND  nvl(b.error_mesg,'XX') not like 'Duplicate%'
                                                                           AND  NVL (b.error_code, xx_emf_cn_pkg.CN_REC_ERR) IN (
    				                                                                    xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR));

	 commit;
   */
   RETURN x_error_code;
	EXCEPTION
		WHEN xx_emf_pkg.G_E_REC_ERROR THEN
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			RETURN x_error_code;
		WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
			x_error_code := xx_emf_cn_pkg.cn_prc_err;
			RETURN x_error_code;
		WHEN OTHERS THEN
			x_error_code := xx_emf_cn_pkg.cn_prc_err;
			RETURN x_error_code;
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Post-Validations');
	END post_validations;



   -- update_record_count
   PROCEDURE update_record_count(pr_validate_and_load IN VARCHAR2)
	IS
		CURSOR c_get_total_cnt IS
		SELECT COUNT (1) total_count
		  FROM xx_cst_item_upload_stg
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID;

		x_total_cnt NUMBER;

		CURSOR c_get_error_cnt IS
		SELECT SUM(error_count)
		  FROM (
			SELECT COUNT (1) error_count
			  FROM xx_cst_item_upload_stg
			 WHERE batch_id   = G_BATCH_ID
			   AND request_id = xx_emf_pkg.G_REQUEST_ID
			   AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

		x_error_cnt NUMBER;

		CURSOR c_get_warning_cnt IS
		SELECT COUNT (1) warn_count
		  FROM xx_cst_item_upload_stg
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

		x_warn_cnt NUMBER;

		CURSOR c_get_success_cnt IS
		SELECT COUNT (1) success_count
		  FROM xx_cst_item_upload_stg
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

		x_success_cnt NUMBER;

    -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Starts
    CURSOR c_get_success_valid_cnt IS
		SELECT COUNT (1) success_count
		  FROM xx_cst_item_upload_stg
		 WHERE batch_id = G_BATCH_ID
		   AND request_id = xx_emf_pkg.G_REQUEST_ID
		   AND process_code = xx_emf_cn_pkg.CN_POSTVAL
		   AND error_code = xx_emf_cn_pkg.CN_SUCCESS;
   -- Added for if p_validate_only_flag is set to VALIDATE_ONLY Ends


	BEGIN
		OPEN c_get_total_cnt;
		FETCH c_get_total_cnt INTO x_total_cnt;
		CLOSE c_get_total_cnt;

		OPEN c_get_error_cnt;
		FETCH c_get_error_cnt INTO x_error_cnt;
		CLOSE c_get_error_cnt;

		OPEN c_get_warning_cnt;
		FETCH c_get_warning_cnt INTO x_warn_cnt;
		CLOSE c_get_warning_cnt;

    IF pr_validate_and_load = g_validate_and_load THEN
       OPEN c_get_success_cnt;
		   FETCH c_get_success_cnt INTO x_success_cnt;
		   CLOSE c_get_success_cnt;
    ELSE
       OPEN c_get_success_valid_cnt;
		   FETCH c_get_success_valid_cnt INTO x_success_cnt;
		   CLOSE c_get_success_valid_cnt;
		END IF;

		xx_emf_pkg.update_recs_cnt
		(
		    p_total_recs_cnt   => x_total_cnt,
		    p_success_recs_cnt => x_success_cnt,
		    p_warning_recs_cnt => x_warn_cnt,
		    p_error_recs_cnt   => x_error_cnt
		);
	END update_record_count;

   /*-------------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   main
   Parameters       :   x_errbuf                  OUT VARCHAR2
                        x_retcode                 OUT VARCHAR2
                        p_run_mode                IN  VARCHAR2
   Purpose          :   This is the main procedure which subsequently calls all other procedure.
      -------------------------------------------------------------------------------------------------------------------------*/
   PROCEDURE main(x_errbuf   OUT VARCHAR2
                                ,x_retcode  OUT VARCHAR2
                                ,p_batch_id      IN  VARCHAR2
                                ,p_restart_flag  IN  VARCHAR2
				                        ,p_cost_type     IN  VARCHAR2
                                ,p_make_buy      IN  VARCHAR2
                                ,p_validate_and_load     IN VARCHAR2
                                ) IS
      --------------------------------------------------------------------------------------------------------
      -- Private Variable Declaration Section
      --------------------------------------------------------------------------------------------------------

      --Stop the program with EMF error header insertion fails
      l_process_status NUMBER;

      x_error_code          NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER                := xx_emf_cn_pkg.CN_SUCCESS;

      x_itemcost_table         g_xx_itemcost_tab_type;

     CURSOR c_xx_itemcost ( cp_process_status VARCHAR2)
        IS
         SELECT *
           FROM xx_cst_item_upload_stg
         WHERE batch_id     = G_BATCH_ID
           AND request_id   = xx_emf_pkg.G_REQUEST_ID
           AND process_code = cp_process_status
           AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
         ORDER BY record_number;

     PROCEDURE update_record_status (
    		p_conv_hdr_rec  IN OUT  G_XX_ITEMCOST_STG_REC_TYPE,
    		p_error_code            IN      VARCHAR2
    	       ) IS
           BEGIN
        g_api_name := 'main.update_record_status';
    		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');

    		IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    		THEN
    			p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
    		ELSE
    			p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));

    		END IF;
    		p_conv_hdr_rec.process_code := G_STAGE;

    	END update_record_status;

  PROCEDURE update_int_records (p_cnv_itemcost_table IN g_xx_itemcost_tab_type)
            IS
            x_last_update_date      DATE := SYSDATE;
            x_last_updated_by       NUMBER := fnd_global.user_id;
            x_last_update_login     NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
	    indx		    NUMBER;

            PRAGMA AUTONOMOUS_TRANSACTION;
       BEGIN
           g_api_name := 'main.update_int_records';

            FOR indx IN 1 .. p_cnv_itemcost_table.COUNT LOOP

              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_itemcost_table(indx).process_code ' || p_cnv_itemcost_table(indx).process_code);
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_cnv_itemcost_table(indx).error_code ' || p_cnv_itemcost_table(indx).error_code);

            UPDATE xx_cst_item_upload_stg
               SET  item_number                      = p_cnv_itemcost_table(indx).item_number                   ,
                    inv_organization_code            = p_cnv_itemcost_table(indx).inv_organization_code         , -- Added for data file actually not in interface table
                    overhead_code                    = p_cnv_itemcost_table(indx).overhead_code                 , -- Added for data file actually not in interface table
                    organization_id                  = p_cnv_itemcost_table(indx).organization_id               ,
                    usage_rate_or_amount             = p_cnv_itemcost_table(indx).usage_rate_or_amount          ,
                    cost_element                     = p_cnv_itemcost_table(indx).cost_element                  ,
                    inventory_item_id                = p_cnv_itemcost_table(indx).inventory_item_id             ,
                    cost_type_id                     = p_cnv_itemcost_table(indx).cost_type_id                  ,
                    last_update_date                 = p_cnv_itemcost_table(indx).last_update_date              ,
                    last_updated_by                  = p_cnv_itemcost_table(indx).last_updated_by               ,
                    creation_date                    = p_cnv_itemcost_table(indx).creation_date                 ,
                    created_by                       = p_cnv_itemcost_table(indx).created_by                    ,
                    last_update_login                = p_cnv_itemcost_table(indx).last_update_login             ,
                    group_id                         = p_cnv_itemcost_table(indx).group_id                      ,
                    operation_sequence_id            = p_cnv_itemcost_table(indx).operation_sequence_id         ,
                    operation_seq_num                = p_cnv_itemcost_table(indx).operation_seq_num             ,
                    department_id                    = p_cnv_itemcost_table(indx).department_id                 ,
                    level_type                       = p_cnv_itemcost_table(indx).level_type                    ,
                    activity_id                      = p_cnv_itemcost_table(indx).activity_id                   ,
                    resource_seq_num                 = p_cnv_itemcost_table(indx).resource_seq_num              ,
                    resource_id                      = p_cnv_itemcost_table(indx).resource_id                   ,
                    resource_rate                    = p_cnv_itemcost_table(indx).resource_rate                 ,
                    item_units                       = p_cnv_itemcost_table(indx).item_units                    ,
                    activity_units                   = p_cnv_itemcost_table(indx).activity_units                ,
                    basis_type                       = p_cnv_itemcost_table(indx).basis_type                    ,
                    basis_resource_id                = p_cnv_itemcost_table(indx).basis_resource_id             ,
                    basis_factor                     = p_cnv_itemcost_table(indx).basis_factor                  ,
                    net_yield_or_shrinkage_factor    = p_cnv_itemcost_table(indx).net_yield_or_shrinkage_factor ,
                    item_cost                        = p_cnv_itemcost_table(indx).item_cost                     ,
                    cost_element_id                  = p_cnv_itemcost_table(indx).cost_element_id               ,
                    rollup_source_type               = p_cnv_itemcost_table(indx).rollup_source_type            ,
                    activity_context                 = p_cnv_itemcost_table(indx).activity_context              ,
                    request_id                       = p_cnv_itemcost_table(indx).request_id                    ,
                    organization_code                = p_cnv_itemcost_table(indx).organization_code             ,
                    cost_type                        = p_cnv_itemcost_table(indx).cost_type                     ,
                    inventory_item                   = p_cnv_itemcost_table(indx).inventory_item                ,
                    department                       = p_cnv_itemcost_table(indx).department                    ,
                    activity                         = p_cnv_itemcost_table(indx).activity                      ,
                    resource_code                    = p_cnv_itemcost_table(indx).resource_code                 ,
                    basis_resource_code              = p_cnv_itemcost_table(indx).basis_resource_code           ,
                    program_application_id           = p_cnv_itemcost_table(indx).program_application_id        ,
                    program_id                       = p_cnv_itemcost_table(indx).program_id                    ,
                    program_update_date              = p_cnv_itemcost_table(indx).program_update_date           ,
                    attribute_category               = p_cnv_itemcost_table(indx).attribute_category            ,
                    attribute1                       = p_cnv_itemcost_table(indx).attribute1                    ,
                    attribute2                       = p_cnv_itemcost_table(indx).attribute2                    ,
                    attribute3                       = p_cnv_itemcost_table(indx).attribute3                    ,
                    attribute4                       = p_cnv_itemcost_table(indx).attribute4                    ,
                    attribute5                       = p_cnv_itemcost_table(indx).attribute5                    ,
                    attribute6                       = p_cnv_itemcost_table(indx).attribute6                    ,
                    attribute7                       = p_cnv_itemcost_table(indx).attribute7                    ,
                    attribute8                       = p_cnv_itemcost_table(indx).attribute8                    ,
                    attribute9                       = p_cnv_itemcost_table(indx).attribute9                    ,
                    attribute10                      = p_cnv_itemcost_table(indx).attribute10                   ,
                    attribute11                      = p_cnv_itemcost_table(indx).batch_id  , -- Batch_Id tracking
                    attribute12                      = p_cnv_itemcost_table(indx).attribute12                   ,
                    attribute13                      = p_cnv_itemcost_table(indx).attribute13                   ,
                    attribute14                      = p_cnv_itemcost_table(indx).attribute14                   ,
                    attribute15                      = p_cnv_itemcost_table(indx).attribute15                   ,
                    transaction_id                   = p_cnv_itemcost_table(indx).transaction_id                ,
                    transaction_type                 = p_cnv_itemcost_table(indx).transaction_type              ,
                    yielded_cost                     = p_cnv_itemcost_table(indx).yielded_cost                  ,
                    lot_size                         = p_cnv_itemcost_table(indx).lot_size                      ,
                    based_on_rollup_flag             = p_cnv_itemcost_table(indx).based_on_rollup_flag          ,
                    shrinkage_rate                   = p_cnv_itemcost_table(indx).shrinkage_rate                ,
                    inventory_asset_flag             = p_cnv_itemcost_table(indx).inventory_asset_flag          ,
                    group_description                = p_cnv_itemcost_table(indx).group_description             ,
                    process_flag                     = p_cnv_itemcost_table(indx).process_flag                  ,
                    error_code                       = p_cnv_itemcost_table(indx).error_code                    ,
                    error_type                       = p_cnv_itemcost_table(indx).error_type                    ,
                    error_explanation                = p_cnv_itemcost_table(indx).error_explanation             ,
                    error_flag                       = p_cnv_itemcost_table(indx).error_flag                    ,
                   -- batch_id                         = p_cnv_itemcost_table(indx).batch_id                      ,
                    process_code                     = p_cnv_itemcost_table(indx).process_code                  ,
                    error_mesg                       = p_cnv_itemcost_table(indx).error_mesg
                    --record_number                    = p_cnv_itemcost_table(indx).record_number
                 WHERE record_number = p_cnv_itemcost_table(indx).record_number
                       AND   BATCH_ID = G_BATCH_ID;
            END LOOP;

            COMMIT;
    END update_int_records;

    -- mark_records_complete
    PROCEDURE mark_records_complete (
		p_process_code	VARCHAR2
	       ) IS
		x_last_update_date       DATE   := SYSDATE;
		x_last_updated_by        NUMBER := fnd_global.user_id;
		x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);

		PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of mark records complete...');
		g_api_name := 'main.mark_records_complete';

		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside mark_records_complete');

			UPDATE xx_cst_item_upload_stg	--Header
			   SET process_code      = G_STAGE,
			       error_code        = NVL ( error_code, xx_emf_cn_pkg.CN_SUCCESS),
			       last_updated_by   = x_last_updated_by,
			       last_update_date  = x_last_update_date,
			       last_update_login = x_last_update_login
			 WHERE batch_id     = G_BATCH_ID
			   AND request_id   = xx_emf_pkg.G_REQUEST_ID
			   AND process_code = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA, xx_emf_cn_pkg.CN_POSTVAL, xx_emf_cn_pkg.CN_DERIVE)
			   AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
		COMMIT;

	EXCEPTION
		WHEN OTHERS THEN
	            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
	END mark_records_complete;



  FUNCTION xx_itemcost_insert_interface
    RETURN NUMBER
	 IS
		x_return_status       VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;
      --cursor to insert into ITEMCOST interface table
      CURSOR c_xx_itemcost_intupld(cp_process_status VARCHAR2) IS
         SELECT *
           FROM xx_cst_item_upload_stg bis
           WHERE batch_id     = G_BATCH_ID
		         AND request_id   = xx_emf_pkg.G_REQUEST_ID
		         AND process_code = cp_process_status	--***DS - what shd be the process code value passed here
		         AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		        ORDER BY record_number;

   BEGIN
      g_api_name := 'main.xx_itemcost_insert_interface';
      FOR c_xx_intupld_rec IN c_xx_itemcost_intupld(xx_emf_cn_pkg.CN_POSTVAL)
      LOOP
         BEGIN

          INSERT INTO CST_ITEM_CST_DTLS_INTERFACE
               (item_number,
                organization_id ,
                usage_rate_or_amount,
                cost_element,
                inventory_item_id ,
                cost_type_id,
                --group_id ,
                operation_sequence_id,
                operation_seq_num ,
                department_id,
                level_type ,
                activity_id ,
                resource_seq_num,
                resource_id,
                resource_rate,
                item_units,
                activity_units,
                basis_type ,
                basis_resource_id,
                basis_factor,
                net_yield_or_shrinkage_factor,
                item_cost,
                cost_element_id ,
                rollup_source_type ,
                activity_context ,
              --  request_id ,
                organization_code ,
                cost_type,
                inventory_item ,
                department,
                activity ,
                resource_code,
                basis_resource_code,
                program_application_id,
                program_id,
                program_update_date,
                attribute_category ,
                attribute1,
                attribute2 ,
                attribute3 ,
                attribute4 ,
                attribute5 ,
                attribute6 ,
                attribute7 ,
                attribute8 ,
                attribute9  ,
                attribute10  ,
                attribute11 ,
                attribute12 ,
                attribute13 ,
                attribute14 ,
                attribute15  ,
                transaction_id ,
                transaction_type ,
                yielded_cost ,
                lot_size,
                based_on_rollup_flag,
                shrinkage_rate,
                inventory_asset_flag ,
                group_description,
                process_flag ,
             --   error_code
                error_type ,
                error_explanation  ,
                error_flag ,
                last_update_date,
                last_updated_by ,
                creation_date ,
                created_by,
                last_update_login
                )
          VALUES ( c_xx_intupld_rec.item_number                   ,
                   c_xx_intupld_rec.organization_id               ,
                   c_xx_intupld_rec.usage_rate_or_amount          ,
                   c_xx_intupld_rec.cost_element                  ,
                   c_xx_intupld_rec.inventory_item_id             ,
                   c_xx_intupld_rec.cost_type_id                  ,
                  -- c_xx_intupld_rec.group_id                      ,
                   c_xx_intupld_rec.operation_sequence_id         ,
                   c_xx_intupld_rec.operation_seq_num             ,
                   c_xx_intupld_rec.department_id                 ,
                   c_xx_intupld_rec.level_type                    ,
                   c_xx_intupld_rec.activity_id                   ,
                   c_xx_intupld_rec.resource_seq_num              ,
                   c_xx_intupld_rec.resource_id                   ,
                   c_xx_intupld_rec.resource_rate                 ,
                   c_xx_intupld_rec.item_units                    ,
                   c_xx_intupld_rec.activity_units                ,
                   c_xx_intupld_rec.basis_type                    ,
                   c_xx_intupld_rec.basis_resource_id             ,
                   c_xx_intupld_rec.basis_factor                  ,
                   c_xx_intupld_rec.net_yield_or_shrinkage_factor ,
                   c_xx_intupld_rec.item_cost                     ,
                   c_xx_intupld_rec.cost_element_id               ,
                   c_xx_intupld_rec.rollup_source_type            ,
                   c_xx_intupld_rec.activity_context              ,
                  -- c_xx_intupld_rec.request_id                    ,
                   c_xx_intupld_rec.organization_code             ,
                   c_xx_intupld_rec.cost_type                     ,
                   c_xx_intupld_rec.inventory_item                ,
                   c_xx_intupld_rec.department                    ,
                   c_xx_intupld_rec.activity                      ,
                   c_xx_intupld_rec.resource_code                 ,
                   c_xx_intupld_rec.basis_resource_code           ,
                   c_xx_intupld_rec.program_application_id        ,
                   c_xx_intupld_rec.program_id                    ,
                   c_xx_intupld_rec.program_update_date           ,
                   c_xx_intupld_rec.attribute_category            ,
                   c_xx_intupld_rec.attribute1                    ,
                   c_xx_intupld_rec.attribute2                    ,
                   c_xx_intupld_rec.attribute3                    ,
                   c_xx_intupld_rec.attribute4                    ,
                   c_xx_intupld_rec.attribute5                    ,
                   c_xx_intupld_rec.attribute6                    ,
                   c_xx_intupld_rec.attribute7                    ,
                   c_xx_intupld_rec.attribute8                    ,
                   c_xx_intupld_rec.attribute9                    ,
                   c_xx_intupld_rec.attribute10                   ,
                   c_xx_intupld_rec.attribute11                   ,
                   c_xx_intupld_rec.attribute12                   ,
                   c_xx_intupld_rec.attribute13                   ,
                   c_xx_intupld_rec.attribute14                   ,
                   c_xx_intupld_rec.attribute15                   ,
                   c_xx_intupld_rec.transaction_id                ,
                   c_xx_intupld_rec.transaction_type              ,
                   c_xx_intupld_rec.yielded_cost                  ,
                   c_xx_intupld_rec.lot_size                      ,
                   c_xx_intupld_rec.based_on_rollup_flag          ,
                   c_xx_intupld_rec.shrinkage_rate                ,
                   c_xx_intupld_rec.inventory_asset_flag          ,
                   c_xx_intupld_rec.group_description             ,
                   g_process_flag ,                   ---c_xx_intupld_rec.process_flag,
                --   c_xx_intupld_rec.error_code                    ,
                   c_xx_intupld_rec.error_type                    ,
                   c_xx_intupld_rec.error_explanation             ,
                   c_xx_intupld_rec.error_flag                    ,
                   SYSDATE,
			             g_user_id,
			             SYSDATE,
			             g_user_id,
			             g_user_id
                  );

           END;
       END LOOP;

      RETURN x_return_status;
	       EXCEPTION
		       WHEN OTHERS THEN
			       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while inserting into Standard Interface Tables: ' ||SQLERRM);
			       xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
			       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
			       RETURN x_error_code;

   END xx_itemcost_insert_interface;

  -- mark_records_for_api_error

  PROCEDURE mark_records_for_api_error(p_process_code IN VARCHAR2)
	IS
			x_last_update_date       DATE := SYSDATE;
			x_last_updated_by        NUMBER := fnd_global.user_id;
			x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
      x_record_count           NUMBER;
			PRAGMA AUTONOMOUS_TRANSACTION;
		BEGIN
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Mark Record for API Error');
		   UPDATE xx_cst_item_upload_stg xcius
		     SET process_code = G_STAGE,
		         error_code   = xx_emf_cn_pkg.CN_REC_ERR,
		         last_updated_by   = x_last_updated_by,
		         last_update_date  = x_last_update_date,
		         last_update_login = x_last_update_login
		   WHERE batch_id    = G_BATCH_ID
		     AND process_code  = DECODE (p_process_code, xx_emf_cn_pkg.CN_PROCESS_DATA
		                                , xx_emf_cn_pkg.CN_POSTVAL
		                                , xx_emf_cn_pkg.CN_DERIVE
		                                )
		     AND error_code    IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
		     AND Exists (SELECT 1
		                   FROM CST_ITEM_CST_DTLS_INTERFACE cicdi
		                  WHERE 1=1
		                    AND cicdi.inventory_item    = xcius.inventory_item
                        AND cicdi.organization_code = xcius.organization_code
                        AND cicdi.resource_code = xcius.resource_code
                        AND cicdi.attribute11=xcius.batch_id
                        AND xcius.batch_id = G_BATCH_ID
		                    AND cicdi.error_code IS NOT NULL
		                 );

		   x_record_count := SQL%ROWCOUNT;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No of Record Marked with API Error=>'||x_record_count);
		   COMMIT;
		END mark_records_for_api_error;
  --print_records_with_api_error
  PROCEDURE print_records_with_api_error
		IS
         CURSOR cur_print_error_records
           IS
         SELECT xcius.inventory_item
		         ,xcius.organization_code
             ,xcius.inv_organization_code
		         ,cicdi.error_code
		         ,cicdi.error_explanation
		         ,xcius.record_number
		    FROM CST_ITEM_CST_DTLS_INTERFACE cicdi
		   	     ,XX_CST_ITEM_UPLOAD_STG xcius
		   WHERE  cicdi.inventory_item    = xcius.inventory_item
              AND cicdi.organization_code = xcius.organization_code
              AND cicdi.resource_code = xcius.resource_code
              AND cicdi.attribute11=xcius.batch_id
              AND xcius.batch_id = G_BATCH_ID
		          AND cicdi.error_code IS NOT NULL
		     ;
		BEGIN
		   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside print_records_with_api_error');
          FOR cur_rec IN cur_print_error_records
           LOOP
	           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
		  	             ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
			               ,p_error_text  => cur_rec.error_code||'-'||cur_rec.error_explanation
			               ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.inv_organization_code||'('||cur_rec.organization_code||')'
                     ,p_record_identifier_3 => cur_rec.inventory_item
		                );
		   END LOOP;
		END print_records_with_api_error;

  /*-------------------------------------------------------------------------------------------------------------------
   Procedure Name   :   xx_itemcost_upload
   Purpose          :   This is the ITEMCOST_upload procedure which performs the creation of ITEMCOST.
   --------------------------------------------------------------------------------------------------------------------*/

  PROCEDURE xx_itemcost_upload(p_cost_imp_type VARCHAR2) IS
      --Variable Declaration
      l_completed           BOOLEAN;
      l_phase               VARCHAR2(200);
      l_vstatus             VARCHAR2(200);
      l_dev_phase           VARCHAR2(200);
      l_dev_status          VARCHAR2(200);
      l_message             VARCHAR2(2000);
      l_standard_request_id NUMBER;
   BEGIN
     g_api_name := 'main.xx_itemcost_upload';
      --IF p_error_flag = 'N' THEN --commented by manash on 17/05/11
         --added on 17/05/11 by manash
         l_standard_request_id := fnd_request.submit_request
                             (application      => 'BOM',
                              program          => 'CSTPCIMP',
                              description      => NULL,
                              start_time       => NULL,
                              sub_request      => FALSE,
                              argument1        => 1, --'ITM', --p_run_option,  -- Import cost option
                              argument2        => 2,             -- Mode to run this request
                              argument3        => 2,             -- Group ID option
                              argument4        => NULL,          -- Group ID Dummy
                              argument5        => NULL,          -- Group ID
                              argument6        => p_cost_imp_type,-- 'Curent'  -- Cost type to import to
                              argument7        => 2              -- Delete successful rows
                             );
         COMMIT;
         IF l_standard_request_id > 0 THEN
            l_completed := fnd_concurrent.wait_for_request(request_id => l_standard_request_id
                                                          ,INTERVAL   => 60
                                                          ,max_wait   => 0
                                                          ,phase      => l_phase
                                                          ,status     => l_vstatus
                                                          ,dev_phase  => l_dev_phase
                                                          ,dev_status => l_dev_status
                                                          ,message    => l_message);
            /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'L_DEV_STATUS: ' || L_DEV_STATUS);*/
             IF l_completed = TRUE THEN
		          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Import Item Cost Program Completed =>'||l_dev_status);
		          mark_records_for_api_error(xx_emf_cn_pkg.CN_PROCESS_DATA);
		          -- Print the records with API Error
		          print_records_with_api_error;
		          x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
		       END IF;
         ELSIF l_standard_request_id = 0 THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Error in submitting the Import Item Cost Program');
          x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
		      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
				         ,p_category    => xx_emf_cn_pkg.CN_STG_APICALL
				         ,p_error_text  => 'Error in submitting the Import Item Cost Program'
				         ,p_record_identifier_1 => 'Process level error : Exiting'
			           );
         END IF;

   EXCEPTION
		WHEN OTHERS THEN
		    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND,SUBSTR(SQLERRM,1,255));
   END xx_itemcost_upload;

   BEGIN
      --Main Begin
      ----------------------------------------------------------------------------------------------------
      --Initialize Trace
      --Purpose : Set the program environment for Tracing
      ----------------------------------------------------------------------------------------------------
      fnd_file.put_line (fnd_file.LOG, '***DS - 1');
      x_retcode := xx_emf_cn_pkg.CN_SUCCESS;

	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');

	    -- Set Env --
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling ITEMCOST Set_cnv_env');
	    set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);
	    g_make_buy := p_make_buy;
        -- include all the parameters to the conversion main here
        -- as medium log messages
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id '	|| p_batch_id);
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag '	|| p_restart_flag);


	    -- Call procedure to update records with the current request_id
	     -- So that we can process only those records
	     -- This gives a better handling of restartability
	     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
	     mark_records_for_processing(p_restart_flag => p_restart_flag);

       -- Set the stage to Pre Validations
	set_stage (xx_emf_cn_pkg.CN_PREVAL);
       -- PRE_VALIDATIONS SHOULD BE RETAINED
		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling xx_inv_itemcost_pkg.pre_validations ..');

		x_error_code := xx_inv_itemcost_pkg.pre_validations;

		xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After pre-validations X_ERROR_CODE ' || X_ERROR_CODE);
      -- Update process code of staging records
		  -- Update Header and Lines Level
		  update_staging_records ( xx_emf_cn_pkg.CN_SUCCESS);

		  xx_emf_pkg.propagate_error ( x_error_code);

      -- Set the stage to data Validations
	    set_stage (xx_emf_cn_pkg.CN_VALID);
      OPEN c_xx_itemcost ( xx_emf_cn_pkg.CN_PREVAL);
	     LOOP
	       	FETCH c_xx_itemcost
		    BULK COLLECT INTO x_itemcost_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

		   FOR i IN 1 .. x_itemcost_table.COUNT
		  LOOP
			  BEGIN
				-- Perform Base App Validations
				x_error_code := xx_itemcost_validation(x_itemcost_table (i));
			        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_itemcost_table (i).record_number|| ' is ' || x_error_code);
			       	update_record_status (x_itemcost_table (i), x_error_code);
              xx_emf_pkg.propagate_error (x_error_code);
        EXCEPTION
          -- If HIGH error then it will be propagated to the next level
          -- IF the process has to continue maintain it as a medium severity
           WHEN xx_emf_pkg.G_E_REC_ERROR
           THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
           WHEN xx_emf_pkg.G_E_PRC_ERROR
           THEN
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data Validations');
                  update_int_records ( x_itemcost_table);
                  RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
           WHEN OTHERS
           THEN
                  xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_itemcost_table (i).record_number);
         END;

       END LOOP;
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_itemcost_table.count ' || x_itemcost_table.COUNT );
          update_int_records( x_itemcost_table);
          x_itemcost_table.DELETE;

          EXIT WHEN c_xx_itemcost%NOTFOUND;
      END LOOP;
      IF c_xx_itemcost%ISOPEN THEN
          CLOSE c_xx_itemcost;
      END IF;


	      xx_emf_pkg.WRITE_LOG(xx_emf_cn_pkg.cn_low, fnd_global.conc_request_id || ' : Before Data Derivations');
       -- Once data-validations are complete the loop through the pre-interface records
       -- and perform data derivations on this table
       -- Set the stage to data derivations
      set_stage (xx_emf_cn_pkg.CN_DERIVE);
      OPEN c_xx_itemcost ( xx_emf_cn_pkg.CN_VALID);
      LOOP
            FETCH c_xx_itemcost
            BULK COLLECT INTO x_itemcost_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;

            FOR i IN 1 .. x_itemcost_table.COUNT
            LOOP
                    BEGIN

                            -- Perform Base App Validations
                            x_error_code := xx_itemcost_data_derivations (x_itemcost_table (i));
                            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_error_code for  '|| x_itemcost_table (i).record_number|| ' is ' || x_error_code);

                            update_record_status (x_itemcost_table (i), x_error_code);
                            xx_emf_pkg.propagate_error (x_error_code);
                    EXCEPTION
                            -- If HIGH error then it will be propagated to the next level
                            -- IF the process has to continue maintain it as a medium severity
                            WHEN xx_emf_pkg.G_E_REC_ERROR
                            THEN
                                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, xx_emf_cn_pkg.CN_REC_ERR);
                            WHEN xx_emf_pkg.G_E_PRC_ERROR
                            THEN
                                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'Process Level Error in Data derivations');
                                    update_int_records ( x_itemcost_table);
                                    RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
                            WHEN OTHERS
                            THEN
                                    xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND, x_itemcost_table (i).record_number);
                    END;
            END LOOP;

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_itemcost_table.count ' || x_itemcost_table.COUNT );

            update_int_records ( x_itemcost_table);
            x_itemcost_table.DELETE;

            EXIT WHEN c_xx_itemcost%NOTFOUND; --***DS: Table type variable used like cursor
    END LOOP;

    IF c_xx_itemcost%ISOPEN THEN
            CLOSE c_xx_itemcost;
    END IF;
   -- Set the stage to Post Validations
   set_stage (xx_emf_cn_pkg.CN_POSTVAL);

                -- Change the validations package to the appropriate package name
                -- Modify the parameters as required
                -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
                -- PRE_VALIDATIONS SHOULD BE RETAINED
    x_error_code := post_validations ();
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
    xx_emf_pkg.propagate_error ( x_error_code);

  -- Perform data derivations and process data only if p_validate_only_flag is set to VALIDATE_AND_LOAD
 IF p_validate_and_load = g_validate_and_load THEN
      -- Set the stage to Process
    set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Before process_data');
    x_error_code := xx_itemcost_insert_interface;
    xx_itemcost_upload(p_cost_type);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After process_data');
    mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'After Process Data mark_records_complete x_error_code'||x_error_code);
    xx_emf_pkg.propagate_error ( x_error_code);
   -- xx_itemcost_upload(p_cost_type);
  END IF; --for validate only flag check -- Added 30-Jan-12
    update_record_count(p_validate_and_load);
    xx_emf_pkg.create_report;

EXCEPTION
	WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
		fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
		x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
    update_record_count(p_validate_and_load);
	  xx_emf_pkg.create_report;

	WHEN xx_emf_pkg.G_E_REC_ERROR THEN
		x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
    update_record_count(p_validate_and_load);
	  xx_emf_pkg.create_report;

	WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
		x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
    update_record_count(p_validate_and_load);
	  xx_emf_pkg.create_report;

	WHEN OTHERS THEN
		x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
    update_record_count(p_validate_and_load);
		xx_emf_pkg.create_report;

 END main;

END xx_inv_itemcost_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEMCOST_PKG TO INTG_XX_NONHR_RO;
