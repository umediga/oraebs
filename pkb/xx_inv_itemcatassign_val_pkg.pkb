DROP PACKAGE BODY APPS.XX_INV_ITEMCATASSIGN_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ITEMCATASSIGN_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 28-MAR-2012
 File Name     : XXINVITEMCATASSIGNVALVL.pkb
 Description   : This script creates the body of the package xx_inv_itemcatassign_val_pkg

 Change History:

 Version Date        Name		    Remarks
-------- ----------- ----		    ---------------------------------------
 1.0     28-MAR-2012 IBM Development Team   Initial development.
*/
----------------------------------------------------------------------

	FUNCTION find_max (
		p_error_code1 IN VARCHAR2,
		p_error_code2 IN VARCHAR2) RETURN VARCHAR2
	IS
		x_return_value VARCHAR2(100);
	BEGIN
		x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);

		RETURN x_return_value;
	END find_max;
----------------------------------------------------------------------------------------
        FUNCTION pre_validations
                RETURN NUMBER
        IS
		x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;


	--- Local functions for all batch level validations
        --- Add as many functions as required in here
           /* Write local functions to perform batch level validation */

        -- Start of the main function perform_batch_validations
        -- This will only have calls to the individual functions.
        BEGIN
   	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations');

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
	END pre_validations;
---------------------------------------------------------------------------------------------------------

        FUNCTION data_validations (
	      p_cnv_hdr_rec IN OUT xx_inv_itemcatassign_pkg.G_XX_INV_ITEMCAT_PRE_REC_TYPE
	) RETURN NUMBER
	IS
		x_error_code       NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_category_stru_id NUMBER;

		--- Local functions for all batch level validations
                --- Add as many functions as required in here

                FUNCTION is_organization_valid (p_organization_code IN  VARCHAR2
			                       ,p_organization_id   OUT NUMBER
			                       )
			                       RETURN NUMBER
                IS
  	            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                    x_err_code   VARCHAR2(30);
                    x_err_msg    VARCHAR2(200);

                BEGIN
                   /* call black box function and fetch the oracle organization
                   -- code based on Integra organization code
                   */
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid: Success Organization_CODE=>'||p_organization_code);
                    /*xx_intg_common_pkg.get_inv_organization_id(p_legacy_org_name     =>p_organization_code
                                                              ,p_inv_organization_id =>p_organization_id
                                                              ,p_error_code          =>x_err_code
                                                              ,p_error_msg           =>x_err_msg
                                                              );*/--***DS: Need to debug cause why Org ID is not fetched
		    SELECT mp.organization_id
		      INTO p_organization_id
		      FROM mtl_parameters mp
			   --,hr_all_organization_units haou
		     WHERE 1 = 1
		    -- AND haou.organization_id = mp.organization_id
		       AND mp.organization_code    = p_organization_code
		     --AND haou.name            = x_organization_name
		     --AND (process_enabled_flag = 'Y'
		     --     OR x_organization_code='000'
		     --    )
		     ;

                     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid: Success Organization_ID=>'||p_organization_id);

                    IF p_organization_id IS NULL
                    THEN
                       IF x_err_code = xx_emf_cn_pkg.CN_TOO_MANY
                       THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid organization code =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number
                                        );
	                 RETURN x_error_code;
                       ELSIF x_err_code = xx_emf_cn_pkg.CN_NO_DATA
                       THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid organization code =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number
                                         );
			 RETURN x_error_code;
                       ELSIF x_err_code = xx_emf_cn_pkg.CN_OTHERS
                       THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Organization Validation ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Errors In Organization Validation=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number
                                          );

                       RETURN x_error_code;
                      END IF;
                    ELSE
                        RETURN x_error_code;
                    END IF;
                    RETURN x_error_code;
		END is_organization_valid;

                --code to validate the item number--
                FUNCTION is_item_number_valid (
                                               p_legacy_item_number   IN  VARCHAR2
		                              ,p_inventory_item_id    OUT NUMBER
                                              ,p_organization_id      IN  NUMBER
                )
                    RETURN NUMBER
                IS
		    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                    x_err_code   VARCHAR2(30);
                    x_err_msg    VARCHAR2(200);
                BEGIN

                    /* Write your code to validate the Item*/
                     /* fetch the oracle item */
                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid: '|| p_legacy_item_number);
                    -- Validate the Oracle Item Number
                   /*xx_intg_common_pkg.get_inventory_item_id(p_legacy_item_name  =>p_legacy_item_number
                                                          ,p_organization_id   =>p_organization_id
                                                          ,p_inventory_item_id =>p_inventory_item_id
                                                          ,p_error_code        =>x_err_code
 		                                          ,p_error_msg         =>x_err_msg
 			                                 );*/
		    SELECT inventory_item_id
		      INTO p_inventory_item_id
		      FROM mtl_system_items_b
		     WHERE organization_id = p_organization_id
		       AND segment1 = p_legacy_item_number;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid: Success inventory_item_id=>'||p_inventory_item_id);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number
                               );
                         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Item Number ' || x_error_code);
                    RETURN x_error_code;
		END is_item_number_valid;

                --code to validate the category set--
                FUNCTION is_category_set_valid (
                                               p_category_set_name IN VARCHAR2
                                               ,p_category_set_id  OUT NUMBER
                                               ,p_category_stru_id OUT NUMBER
                )
                        RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                BEGIN
                    SELECT category_set_id
                          ,structure_id
                      INTO p_category_set_id
                          ,p_category_stru_id
                      FROM mtl_category_sets mcs
                     WHERE mcs.category_set_name = p_category_set_name;

                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_set_valid: Success Category_set_id=>'||p_category_set_id);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Set Name=>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number||'-'||p_category_set_name
                               );
                         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Set Name=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number||'-'||p_category_set_name
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Set Name=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number||'-'||p_category_set_name
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Set Name ' || x_error_code);
                        RETURN x_error_code;
		END is_category_set_valid;

                --code to validate the category--
                FUNCTION is_category_valid (p_category_name    IN VARCHAR2
                                           ,p_category_stru_id IN NUMBER
                                           ,p_category_id      OUT NUMBER
                                           )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_variable     NUMBER;
                        l_valid        NUMBER;
                BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_valid: p_category_name=>'||p_category_name);

                    SELECT category_id
                      INTO p_category_id
                      FROM mtl_categories_kfv mck
                     WHERE upper(mck.concatenated_segments) = upper(p_category_name)
                       --AND structure_id = p_category_stru_id
                     ;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_valid: Success p_category_id=>'||p_category_id);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_WARN;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Name=>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number||'-'||p_cnv_hdr_rec.category_set_name
			                                            ||'-'||p_category_name
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Name=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number||'-'||p_cnv_hdr_rec.category_set_name
			                                            ||'-'||p_category_name
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Name=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.inventory_item_number||'-'||p_cnv_hdr_rec.category_set_name
			                                            ||'-'||p_category_name
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Name ' || x_error_code);
                        RETURN x_error_code;
		END is_category_valid;

        -- Start of the main function perform_batch_validations
        -- This will only have calls to the individual functions.
        BEGIN
       		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

	  	x_error_code_temp := is_organization_valid(p_cnv_hdr_rec.organization_code
	  	                                          ,p_cnv_hdr_rec.organization_id);
	      	x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

		x_error_code_temp := is_item_number_valid(p_cnv_hdr_rec.inventory_item_number
		                                         ,p_cnv_hdr_rec.inventory_item_id
		                                         ,p_cnv_hdr_rec.organization_id);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

		x_error_code_temp := is_category_set_valid(p_cnv_hdr_rec.category_set_name
		                                          ,p_cnv_hdr_rec.category_set_id
		                                          ,x_category_stru_id
		                                          );
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

		x_error_code_temp := is_category_valid(p_cnv_hdr_rec.category_name
		                                      ,x_category_stru_id
		                                      ,p_cnv_hdr_rec.category_id);
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

		xx_emf_pkg.propagate_error ( x_error_code_temp);

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
	END data_validations;
----------------------------------------------------------------------------------------------------------

        FUNCTION post_validations
                RETURN NUMBER
        IS
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        --- Local functions for all batch level validations
        --- Add as many functions as required in here
	/*
	-- write functions to perform post validations
	*/

        -- Start of the main function perform_batch_validations
        -- This will only have calls to the individual functions.
        BEGIN
       		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside post_validations');

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
	END post_validations;
---------------------------------------------------------------------------------------------------------------------------

	FUNCTION data_derivations (
		p_cnv_pre_std_hdr_rec IN OUT xx_inv_itemcatassign_pkg.G_XX_INV_ITEMCAT_PRE_REC_TYPE
	) RETURN NUMBER
	IS
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	------------------
	BEGIN
  	    RETURN x_error_code;
	END data_derivations;
--------------------------------------------------------------------------------------------------

        FUNCTION checkassignmentexistence(p_organization_id   IN NUMBER,
                                          p_inventory_item_id IN NUMBER,
                                          p_category_set_id   IN NUMBER,
                                          p_category_id       IN NUMBER
                                         ) RETURN NUMBER
       IS
          l_assign_exist NUMBER := 0;
       BEGIN
           SELECT count(1)
             INTO l_assign_exist
             FROM mtl_item_categories
            WHERE inventory_item_id = p_inventory_item_id
              AND organization_id   = p_organization_id
              AND category_set_id   = p_category_set_id
              AND category_id       = p_category_id
              ;

           RETURN l_assign_exist;
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
                l_assign_exist := 0;
                RETURN l_assign_exist;
           WHEN OTHERS THEN
                l_assign_exist := 0;
                RETURN l_assign_exist;
       END checkassignmentexistence;

        FUNCTION checksetassignment(p_organization_id   IN NUMBER,
                                    p_inventory_item_id IN NUMBER,
                                    p_category_set_id   IN NUMBER,
                                    p_category_id       IN NUMBER
                                   ) RETURN NUMBER
       IS
          l_old_cateory_id NUMBER := 0;
       BEGIN
           SELECT category_id
             INTO l_old_cateory_id
             FROM mtl_item_categories
            WHERE inventory_item_id = p_inventory_item_id
              AND organization_id   = p_organization_id
              AND category_set_id   = p_category_set_id
              ;

           RETURN l_old_cateory_id;
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
                l_old_cateory_id := 0;
                RETURN l_old_cateory_id;
           WHEN OTHERS THEN
                l_old_cateory_id := 0;
                RETURN l_old_cateory_id;
       END checksetassignment;

END xx_inv_itemcatassign_val_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEMCATASSIGN_VAL_PKG TO INTG_XX_NONHR_RO;
