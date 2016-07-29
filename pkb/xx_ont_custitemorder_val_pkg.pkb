DROP PACKAGE BODY APPS.XX_ONT_CUSTITEMORDER_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_CUSTITEMORDER_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 30-AUG-2013
 File Name     : XXONTITEMORDERVL.pkb
 Description   : This script creates the body of the package xx_ont_custitemorder_val_pkg

 Change History:

 Version Date        Name		    Remarks
-------- ----------- ----		    ---------------------------------------
 1.0     30-AUG-2013 Mou Mukherjee         Initial development.
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
	      p_cnv_hdr_rec IN OUT xx_ont_custitemorder_pkg.G_XX_ITEMORDER_PRE_REC_TYPE
	) RETURN NUMBER
	IS
		x_error_code       NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_category_stru_id NUMBER;

		--- Local functions for all batch level validations
                --- Add as many functions as required in here

	        --code to validate the item number--
                FUNCTION is_item_number_valid (
                                               x_item_number	    IN  VARCHAR2
		                              ,p_inventory_item_id  OUT NUMBER
                )
                    RETURN NUMBER
                IS
		    x_error_code    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		    x_count	    NUMBER;
                BEGIN

                    /* Write your code to validate the Item*/
                     /* fetch the oracle item */
                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid: '|| x_item_number);
                    -- Validate the Oracle Item Number

		    SELECT count(*)
		      INTO x_count
		      FROM mtl_system_items_b
		     WHERE segment1 = x_item_number
		       AND organization_id = fnd_profile.value('MSD_MASTER_ORG');

		    IF (x_count>0) THEN
			SELECT inventory_item_id
			  INTO p_inventory_item_id
			  FROM mtl_system_items_b
			 WHERE organization_id = fnd_profile.value('MSD_MASTER_ORG')
			   AND segment1 = x_item_number;
		    ELSE
		      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			      ,p_category    => xx_emf_cn_pkg.CN_VALID
			      ,p_error_text  => 'ITEM NUMBER not present in master=>'||SQLERRM
			      ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			      ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			      ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
			     );
		    END IF;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid: Success inventory_item_id=>'||p_inventory_item_id);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Item Number ' || x_error_code);
                    RETURN x_error_code;
		END is_item_number_valid;

                --code to validate the criteria--
                FUNCTION is_criteria_valid (p_criteria IN VARCHAR2
                )
                        RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                BEGIN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_criteria_valid: '|| p_criteria);

		    IF trim(p_criteria) <> 'I' AND trim(p_criteria) <> 'C' THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Criteria can be either "I - Item" or "C - Item Category"' );
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_VALID
			    ,p_error_text  => 'Criteria can be either "I - Item" or "C - Item Category"'
			    ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			    ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			    ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
			     );
		    END IF;

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_criteria_valid: Success Criteria=>'||p_criteria);

                    RETURN x_error_code;
		END is_criteria_valid;

                --code to validate the category segment1--
                FUNCTION is_category_seg1_valid (p_cat_seg1    IN OUT VARCHAR2
                                                )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_cat_seg1  VARCHAR2 (100);
                 BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg1_valid: =>'||p_cat_seg1);

			select B.FLEX_VALUE
			 INTO x_cat_seg1
			from FND_FLEX_VALUE_SETS a,
			     FND_FLEX_VALUES b
			where a.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
			and   a.FLEX_VALUE_SET_NAME = xx_emf_pkg.get_paramater_value('XXONTCUSTITEMORDER','VSSEGMENT1') --'INTG_DIV'
			and   b.enabled_flag = 'Y'
			and   b. FLEX_VALUE = p_cat_seg1;

			 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'segment1: Success =>'||p_cat_seg1);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment1 =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment1 =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment1 =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Segment1 ' || x_error_code);
                        RETURN x_error_code;

		END is_category_seg1_valid;

		                --code to validate the category segment2--
                FUNCTION is_category_seg2_valid (p_cat_seg2    IN OUT VARCHAR2
                                                )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_cat_seg2  VARCHAR2 (100);
                 BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg2_valid: =>'||p_cat_seg2);

		    select B.FLEX_VALUE
		        INTO x_cat_seg2
			from FND_FLEX_VALUE_SETS a,
			     FND_FLEX_VALUES b
			where a.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
			and   a.FLEX_VALUE_SET_NAME = xx_emf_pkg.get_paramater_value('XXONTCUSTITEMORDER','VSSEGMENT2') --'INTG_PRODUCT_SEGMENT'
			and   b.enabled_flag = 'Y'
			and   b. FLEX_VALUE = p_cat_seg2;

			 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'segment2: Success =>'||p_cat_seg2);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment2 =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment2 =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment2 =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Segment2 ' || x_error_code);
                        RETURN x_error_code;

		END is_category_seg2_valid;

		                --code to validate the category segment3--
                FUNCTION is_category_seg3_valid (p_cat_seg3    IN OUT VARCHAR2
                                                )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_cat_seg3  VARCHAR2 (100);
                 BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg3_valid: =>'||p_cat_seg3);

			select B.FLEX_VALUE
			 INTO x_cat_seg3
			from FND_FLEX_VALUE_SETS a,
			     FND_FLEX_VALUES b
			where a.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
			and   a.FLEX_VALUE_SET_NAME = xx_emf_pkg.get_paramater_value('XXONTCUSTITEMORDER','VSSEGMENT3') -- 'INTG_BRAND'
			and   b.enabled_flag = 'Y'
			and   b. FLEX_VALUE = p_cat_seg3;

			 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'segment3: Success =>'||p_cat_seg3);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment3 =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment3 =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment3 =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Segment3 ' || x_error_code);
                        RETURN x_error_code;

		END is_category_seg3_valid;

		                --code to validate the category segment4--
                FUNCTION is_category_seg4_valid (p_cat_seg4    IN OUT VARCHAR2
                                                )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_cat_seg4  VARCHAR2 (100);
                 BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg4_valid: =>'||p_cat_seg4);

			select B.FLEX_VALUE
			 INTO x_cat_seg4
			from FND_FLEX_VALUE_SETS a,
			     FND_FLEX_VALUES b
			where a.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
			and   a.FLEX_VALUE_SET_NAME = xx_emf_pkg.get_paramater_value('XXONTCUSTITEMORDER','VSSEGMENT4') --'INTG_PRODUCT_CLASS'
			and   b.enabled_flag = 'Y'
			and   b. FLEX_VALUE = p_cat_seg4;

			 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'segment4: Success =>'||p_cat_seg4);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment4 =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment4 =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment4 =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Segment4 ' || x_error_code);
                        RETURN x_error_code;

		END is_category_seg4_valid;

		                --code to validate the category segment5--
                FUNCTION is_category_seg5_valid ( p_cat_seg1    IN VARCHAR2
						  ,p_cat_seg5    IN OUT VARCHAR2
                                                )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_cat_seg5  VARCHAR2 (100);
                 BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg4_valid: =>'||p_cat_seg5);

			select distinct B.FLEX_VALUE
			 INTO x_cat_seg5
			from FND_FLEX_VALUE_SETS a,
			     FND_FLEX_VALUES b
			where a.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
			and   a.FLEX_VALUE_SET_NAME = xx_emf_pkg.get_paramater_value('XXONTCUSTITEMORDER','VSSEGMENT5') --'INTG_PRODUCT_TYPE'
			and   b.enabled_flag = 'Y'
			and   b. FLEX_VALUE = p_cat_seg5
			and   b.parent_flex_value_low = nvl(p_cat_seg1,b.parent_flex_value_low);

			 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'segment5: Success =>'||p_cat_seg5);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment5 =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment5 =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment5 =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Segment5 ' || x_error_code);
                        RETURN x_error_code;

		END is_category_seg5_valid;

		                --code to validate the category segment6--
                FUNCTION is_category_seg6_valid (p_cat_seg6    IN OUT VARCHAR2
                                                )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_cat_seg6  VARCHAR2 (100);
                 BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg6_valid: =>'||p_cat_seg6);

			select B.FLEX_VALUE
			 INTO x_cat_seg6
			from FND_FLEX_VALUE_SETS a,
			     FND_FLEX_VALUES b
			where a.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
			and   a.FLEX_VALUE_SET_NAME = xx_emf_pkg.get_paramater_value('XXONTCUSTITEMORDER','VSSEGMENT6') --'INTG_CONTRACT_CATEGORY'
			and   b.enabled_flag = 'Y'
			and   b. FLEX_VALUE = p_cat_seg6;

			 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'segment6: Success =>'||p_cat_seg6);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment6 =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment6 =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Segment6 =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Segment6 ' || x_error_code);
                        RETURN x_error_code;

		END is_category_seg6_valid;

             --code to validate the rule level--
                FUNCTION is_rule_level_valid (p_rule_level    IN OUT VARCHAR2,
						x_rule_level_value    IN VARCHAR2,
						p_customer_id    OUT VARCHAR2,
						p_customer_class_id OUT NUMBER,
						p_customer_class_code  OUT VARCHAR2,
						p_customer_category_code  OUT VARCHAR2,
						p_region_id  OUT NUMBER,
						p_order_type_id	 OUT   NUMBER,
						p_ship_to_location_id	OUT  NUMBER,
						p_sales_channel_code  OUT  VARCHAR2,
						p_sales_person_id  OUT NUMBER,
						p_end_customer_id  OUT NUMBER,
						p_bill_to_location_id	OUT   NUMBER,
						p_deliver_to_location_id   OUT NUMBER
                                           )
                                           RETURN NUMBER
                IS
			x_error_code	    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_rule_value_id	    NUMBER;
			x_region_value	    VARCHAR2(400);
			x_customer_id	    NUMBER;
			x_customer_class_id NUMBER;
			x_customer_category_code    VARCHAR2(30);
			x_customer_class_code    VARCHAR2(100);
			x_region_id	    NUMBER;
			x_order_type_id	    NUMBER;
			x_ship_to_location_id	    NUMBER;
			x_sales_channel_code        VARCHAR2(30);
			x_sales_person_id	    NUMBER;
			x_end_customer_id	    NUMBER;
			x_bill_to_location_id	    NUMBER;
			x_deliver_to_location_id    NUMBER;
			x_rule_level                VARCHAR2(100);
			x_rule_code               VARCHAR2(100);

                BEGIN

		                           p_customer_id := NULL;
						p_customer_class_id := NULL;
						p_customer_class_code := NULL;
						p_region_id := NULL;
						p_order_type_id	:= NULL;
						p_ship_to_location_id := NULL;
						p_sales_channel_code := NULL;
						p_sales_person_id := NULL;
						p_end_customer_id := NULL;
						p_bill_to_location_id := NULL;
						p_deliver_to_location_id := NULL;

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid: p_rule_level=>'||p_rule_level);

			IF ( p_rule_level IS NOT NULL ) THEN

			     BEGIN

			        x_rule_level := p_rule_level;

			        SELECT ffvv.flex_value
				  INTO x_rule_code
				  FROM fnd_flex_values_vl ffvv,
					 fnd_flex_value_sets ffvs
				  WHERE 1=1
				  AND ffvs.flex_value_set_name = 'XXINTG_ITEM_RULE_VSET'
				  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
				  AND upper(ffvv.description) = upper(x_rule_level);

					p_rule_level := x_rule_code;
				EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

				IF ( x_rule_level_value IS NULL ) THEN
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid not called as Rule Level value is null ');
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Rule Level Value cannot be NULL =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
			       END IF;
			END IF;
		    IF upper(x_rule_level) = upper('Customer') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer');

			BEGIN

			SELECT acct.cust_account_id
			  INTO x_customer_id
			  FROM hz_parties party,
			       hz_cust_accounts acct
			 WHERE acct.party_id = party.party_id
			   AND acct.status = 'A'
			   AND party.party_name = x_rule_level_value;

			   p_customer_id := x_customer_id;

		   	   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'customer id => '||p_customer_id);

			EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Customer Class') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer Class');

			BEGIN

			SELECT cpc.profile_class_id
			  INTO x_customer_class_id
			  FROM hz_cust_profile_classes cpc
			 WHERE cpc.status = 'A'
			   AND cpc.profile_class_id >= 0
			   AND cpc.name = x_rule_level_value;

			   p_customer_class_id := x_customer_class_id;

			   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer class id => '||p_customer_class_id);

			   	EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Class =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Class =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Class =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Customer Category') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer Category');

			BEGIN
			SELECT lookup_code
			  INTO x_customer_category_code
			  FROM ar_lookups
			 WHERE lookup_type = 'CUSTOMER_CATEGORY'
			   AND upper(meaning) = upper(x_rule_level_value);

			   p_customer_category_code := x_customer_category_code;

			   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'customer category code => '||p_customer_category_code);

				EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Category =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Category =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Category =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;


                ELSIF upper(x_rule_level) = upper('Customer Classification') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer Classification');

			BEGIN
			SELECT lookup_code
			  INTO x_customer_class_code
			  FROM ar_lookups
			 WHERE lookup_type = 'CUSTOMER CLASS'
			   AND upper(meaning) = upper(x_rule_level_value);

			   p_customer_class_code := x_customer_class_code;

			   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'customer class code => '||p_customer_class_code);

				EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Classification =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Classification =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Customer Classification =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('End Customer') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End Customer');

			BEGIN
			SELECT acct.cust_account_id
			  INTO x_end_customer_id
			  FROM hz_parties party,
			       hz_cust_accounts acct
			 WHERE acct.party_id = party.party_id
			   AND acct.status = 'A'
			   AND party.party_name = x_rule_level_value;

			   p_end_customer_id := x_end_customer_id;

        	              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'end customer id => '||p_end_customer_id);

			      	EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for End Customer =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for End Customer =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for End Customer =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Order Type') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Order Type');

			BEGIN

			SELECT order_type_id
			  INTO x_order_type_id
			  FROM oe_order_types_v
			 WHERE TRUNC(sysdate) BETWEEN start_date_active
			   AND nvl(end_date_active,    TRUNC(sysdate))
			   AND upper(name) = upper(x_rule_level_value);

			   p_order_type_id:= x_order_type_id;

                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'oder type  => '||p_order_type_id);

			   	EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Order Type =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Order Type =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Order Type =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Sales Channel') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Sales Channel');

			BEGIN
			SELECT lookup_code
			  INTO x_sales_channel_code
			  FROM oe_lookups
			 WHERE lookup_type = 'SALES_CHANNEL'
			   AND sysdate BETWEEN nvl(start_date_active,    sysdate)
			   AND nvl(end_date_active,    sysdate)
			   AND enabled_flag = 'Y'
			   AND upper(meaning) = upper(x_rule_level_value);

			   p_sales_channel_code := x_sales_channel_code;

			   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'sales channel code  => '||p_sales_channel_code);

			   	EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Sales Channel =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Sales Channel =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Sales Channel =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Salesrep') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Salesrep');

			BEGIN
			SELECT salesrep_id
			  INTO x_sales_person_id
			  FROM ra_salesreps
			 WHERE TRUNC(sysdate) BETWEEN nvl(start_date_active,    TRUNC(sysdate))
			   AND nvl(end_date_active,    TRUNC(sysdate))
			   AND upper(name) = upper(x_rule_level_value);

			   p_sales_person_id := x_sales_person_id;

			   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'sales person id  => '||p_sales_person_id);

			   	EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Sales Person =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Sales Person =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Sales Person =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

    		    ELSIF upper(x_rule_level) = upper('Ship To Location') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Ship To Location');

			BEGIN
			SELECT site.site_use_id
			  INTO x_ship_to_location_id
			  FROM hz_cust_site_uses site
			   WHERE site.site_use_code = 'SHIP_TO'
			   AND site.status = 'A'
			   AND site.location = x_rule_level_value;

				p_ship_to_location_id := x_ship_to_location_id;

				xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ship to location id  => '||p_ship_to_location_id);

					EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Ship To Location =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Ship To Location =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Ship To Location =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Bill To Location') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Bill To Location');

			BEGIN
			SELECT site.site_use_id
			  INTO x_bill_to_location_id
			  FROM hz_cust_site_uses site
			   WHERE site.site_use_code = 'BILL_TO'
			   AND site.status = 'A'
			   AND site.location = x_rule_level_value;

				p_bill_to_location_id := x_bill_to_location_id;

				xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'bill to location id => '||p_bill_to_location_id);

					EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Bill To Location =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Bill To Location =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Bill To Location =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Deliver To Location') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Deliver To Location');

			BEGIN
			SELECT site.site_use_id
			  INTO x_deliver_to_location_id
			  FROM hz_cust_site_uses site
			   WHERE site.site_use_code = 'DELIVER_TO'
			   AND site.status = 'A'
			   AND site.location = x_rule_level_value;

				p_deliver_to_location_id := x_deliver_to_location_id;
				xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'deliver to location id => '||p_deliver_to_location_id);

					EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Delivet To Location =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Deliver To Location =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Deliver To Location =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

		    ELSIF upper(x_rule_level) = upper('Regions') THEN

			/*SELECT replace(x_rule_level_value, '$', ',')
			  INTO x_region_value
			  FROM DUAL; */

			--xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Regions => '||NVL(x_region_value, 'NULL'));
			--xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Zone => '||'Check for Zone...');
			--xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Zone => '||NVL(x_attribute10, 'NULL'));

			BEGIN
			SELECT	region_id
			  INTO  x_rule_value_id
			  FROM	wsh_regions_v
			  WHERE country||state||city||ZONE||postal_code_from||postal_code_to = x_rule_level_value;
			/* WHERE country
			     ||', '||state
			     ||', '||city
			     ||', '||ZONE
			     ||', '||postal_code_from
			     ||' -'||postal_code_to
			     = x_region_value; */

			p_region_id := x_rule_value_id;

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Regions ID => '||p_region_id);
				EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Region =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Region =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level Value for Region =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		    END;

			RETURN x_error_code;

		    ELSE

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Rule Level can be either "Customer" or "Customer Class" or "Customer Category" or "End Customer" or "Order Type" or "Sales Channel" or "Sales Person" or "Ship To Location" or "Bill To Location" or "Deliver To Location" or "Regions"' );
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_VALID
			    ,p_error_text  => 'Rule Level can be either "Customer" or "Customer Class" or "Customer Category" or "End Customer" or "Order Type" or "Sales Channel" or "Sales Person" or "Ship To Location" or "Bill To Location" or "Deliver To Location" or "Regions"'
			    ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			    ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			    ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
			     );
		    END IF;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid: Success p_rule_level=>'||p_rule_level);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level=>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Rule Level ' || x_error_code);
                        RETURN x_error_code;
		END is_rule_level_valid;

		FUNCTION is_restriction_type_valid (p_restriction_type IN OUT  VARCHAR2
			                       )
			                       RETURN NUMBER
                IS
  	            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		    x_rest_code               VARCHAR2(100);
                BEGIN

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_restriction_type_valid: Restriction Type =>'||p_restriction_type);

		   SELECT ffvv.flex_value
				  INTO x_rest_code
				  FROM fnd_flex_values_vl ffvv,
					 fnd_flex_value_sets ffvs
				  WHERE 1=1
				  AND ffvs.flex_value_set_name = 'XXINTG_ITEM_RESTRICTION_VSET'
				  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
				  AND upper(ffvv.description) = upper(p_restriction_type);

					p_restriction_type := x_rest_code;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_restriction_type_valid: Success Restriction_Code=>'||p_restriction_type);

		    RETURN x_error_code;
                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Restriction Type =>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Restriction Type=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Restriction Type =>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Restriction Type ' || x_error_code);
			 RETURN x_error_code;
		END is_restriction_type_valid;

        -- Start of the main function perform_batch_validations
        -- This will only have calls to the individual functions.
        BEGIN
       	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');
	    IF(p_cnv_hdr_rec.sequence_num IS NULL)
	      THEN
	  	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Sequence cannot be NULL =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
	    END IF;

	    IF(p_cnv_hdr_rec.criteria IS NOT NULL)
	      THEN
		x_error_code_temp := is_criteria_valid(p_cnv_hdr_rec.criteria
		                                          );
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_criteria_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_criteria_valid not called as Criteria is null ');
		 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Criteria cannot be NULL =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
	    END IF;

	    IF(p_cnv_hdr_rec.item_number IS NOT NULL)
	      THEN
		x_error_code_temp := is_item_number_valid(p_cnv_hdr_rec.item_number
		                                         ,p_cnv_hdr_rec.inventory_item_id);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
	        IF(p_cnv_hdr_rec.criteria = 'I') THEN
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Item cannot be NULL as Criteria is I =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
		END IF;
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid not called as Item Number is null ');
	    END IF;

	      IF(p_cnv_hdr_rec.CAT_SEG1 IS NOT NULL)
	      THEN
		x_error_code_temp := is_category_seg1_valid(p_cnv_hdr_rec.CAT_SEG1);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg1_valid '||x_error_code_temp);
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	      ELSE

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg1_valid not called as Segment1 is null ');
	    END IF;
	    IF(p_cnv_hdr_rec.CAT_SEG2 IS NOT NULL)
	      THEN
		x_error_code_temp := is_category_seg2_valid(p_cnv_hdr_rec.CAT_SEG2);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg2_valid '||x_error_code_temp);
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	     ELSE

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg2_valid not called as Segment2 is null ');
	    END IF;
	    IF(p_cnv_hdr_rec.CAT_SEG3 IS NOT NULL)
	      THEN
		x_error_code_temp := is_category_seg3_valid(p_cnv_hdr_rec.CAT_SEG3);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg3_valid '||x_error_code_temp);
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg3_valid not called as Segment3 is null ');
	    END IF;
	    IF(p_cnv_hdr_rec.CAT_SEG4 IS NOT NULL)
	      THEN
		x_error_code_temp := is_category_seg4_valid(p_cnv_hdr_rec.CAT_SEG4);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg4_valid '||x_error_code_temp);
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	     ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg4_valid not called as Segment4 is null ');
	    END IF;
	    IF(p_cnv_hdr_rec.CAT_SEG5 IS NOT NULL)
	      THEN
		x_error_code_temp := is_category_seg5_valid(p_cnv_hdr_rec.CAT_SEG1 , p_cnv_hdr_rec.CAT_SEG5);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg5_valid '||x_error_code_temp);
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg5_valid not called as Segment5 is null ');
	    END IF;
	    IF(p_cnv_hdr_rec.CAT_SEG6 IS NOT NULL)
	      THEN
		x_error_code_temp := is_category_seg6_valid(p_cnv_hdr_rec.CAT_SEG6);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg6_valid '||x_error_code_temp);
		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
            ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_seg6_valid not called as Segment6 is null ');
	    END IF;

	    IF((p_cnv_hdr_rec.CAT_SEG1 IS NULL) and (p_cnv_hdr_rec.CAT_SEG2 IS NULL) and (p_cnv_hdr_rec.CAT_SEG3 IS NULL) and (p_cnv_hdr_rec.CAT_SEG4 IS NULL) and (p_cnv_hdr_rec.CAT_SEG5 IS NULL) and (p_cnv_hdr_rec.CAT_SEG6 IS NULL) and (p_cnv_hdr_rec.criteria = 'C'))
             THEN
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Category Segments cannot be NULL as Criteria is C =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_valid not called as Category Segment is null ');
	       RETURN x_error_code;
	    END IF;

	   IF(p_cnv_hdr_rec.rule_level IS NOT NULL)
	      THEN
		x_error_code_temp := is_rule_level_valid(p_cnv_hdr_rec.rule_level
		                                        ,p_cnv_hdr_rec.rule_level_value
							,p_cnv_hdr_rec.customer_id
							,p_cnv_hdr_rec.customer_class_id
							,p_cnv_hdr_rec.customer_class_code
							,p_cnv_hdr_rec.customer_category_code
							,p_cnv_hdr_rec.region_id
							,p_cnv_hdr_rec.order_type_id
							,p_cnv_hdr_rec.ship_to_location_id
							,p_cnv_hdr_rec.sales_channel_code
							,p_cnv_hdr_rec.sales_person_id
							,p_cnv_hdr_rec.end_customer_id
							,p_cnv_hdr_rec.bill_to_location_id
							,p_cnv_hdr_rec.deliver_to_location_id);

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid not called as Rule Level is null ');
		 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Rule Level cannot be NULL =>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.sequence_num
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.item_number
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.rule_level
                               );
			       RETURN x_error_code;
	    END IF;

	    IF(p_cnv_hdr_rec.restriction_type IS NOT NULL)
	      THEN
		x_error_code_temp := is_restriction_type_valid(p_cnv_hdr_rec.restriction_type
		                                                );

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_restriction_type_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_restriction_type_valid not called as restriction type is null ');
	      -- RETURN x_error_code;
	    END IF;

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
		p_cnv_pre_std_hdr_rec IN OUT xx_ont_custitemorder_pkg.G_XX_ITEMORDER_PRE_REC_TYPE
	) RETURN NUMBER
	IS
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	------------------
	BEGIN
  	    RETURN x_error_code;
	END data_derivations;

END xx_ont_custitemorder_val_pkg;
/
