DROP PACKAGE BODY APPS.XX_ONT_ITEMORD_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_ITEMORD_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 21-MAY-2012
 File Name     : XXONTITEMORDVL.pkb
 Description   : This script creates the body of the package xx_ont_itemord_val_pkg

 Change History:

 Version Date        Name		    Remarks
-------- ----------- ----		    ---------------------------------------
 1.0     21-MAY-2012 IBM Development Team   Initial development.
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
	      p_cnv_hdr_rec IN OUT xx_ont_itemord_pkg.G_XX_ONT_ITEMORD_PRE_REC_TYPE
	) RETURN NUMBER
	IS
		x_error_code       NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp  NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_category_stru_id NUMBER;

		--- Local functions for all batch level validations
                --- Add as many functions as required in here

		--code to validate operating unit--
                FUNCTION is_ou_valid (x_operating_unit IN  VARCHAR2
			                       ,p_org_id   OUT NUMBER
			                       )
			                       RETURN NUMBER
                IS
  	            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                BEGIN

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ou_valid: Success Operating Unit=>'||x_operating_unit);

		    SELECT hou.organization_id
		      INTO p_org_id
		      FROM hr_operating_units hou
		     WHERE 1 = 1
		       AND hou.name = x_operating_unit;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ou_valid: Success ORG_ID=>'||p_org_id);

		    RETURN x_error_code;
                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
                         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
                         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Item Number ' || x_error_code);
			 RETURN x_error_code;
		END is_ou_valid;

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
			      ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			      ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			      ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
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
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
                         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Item Number=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
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
			    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			    ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			    ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
			     );
		    END IF;

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_criteria_valid: Success Criteria=>'||p_criteria);

                    RETURN x_error_code;
		END is_criteria_valid;

                --code to validate the category--
                FUNCTION is_category_valid (p_category_name    IN VARCHAR2
                                           ,p_category_id      OUT NUMBER
                                           )
                                           RETURN NUMBER
                IS
			x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                BEGIN
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_valid: p_category_name=>'||p_category_name);

                    SELECT category_id
                      INTO p_category_id
                      FROM mtl_categories_kfv mck
                     WHERE upper(mck.concatenated_segments) = upper(p_category_name);

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
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Name=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Category Name=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Category Name ' || x_error_code);
                        RETURN x_error_code;
		END is_category_valid;

                --code to validate general available--
                FUNCTION is_general_available_valid (p_general_available    IN VARCHAR2
                                           )
                                           RETURN NUMBER
                IS
		    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                BEGIN
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_general_available_valid: p_general_available=>'||p_general_available);

		    IF trim(p_general_available) <> 'Y' AND trim(p_general_available) <> 'N' THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'General Available can be either "Y" or "N"' );
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_VALID
			    ,p_error_text  => 'General Available can be either "Y" or "N"'
			    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			    ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			    ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
			     );
		    END IF;

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_general_available_valid: Success General Available=>'||p_general_available);

                    RETURN x_error_code;
		END is_general_available_valid;


		--code to validate the rule level--
                FUNCTION is_rule_level_valid (p_rule_level    IN VARCHAR2,
						x_rule_level_value    IN VARCHAR2,
						p_rule_value_id    OUT VARCHAR2,
						x_attribute10    IN VARCHAR2
                                           )
                                           RETURN NUMBER
                IS
			x_error_code	    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
			x_rule_value_id	    NUMBER;
			x_region_value	    VARCHAR2(400);
			------------------------------------------------- No test due to data format not fixed
			x_customer_id	    NUMBER;
			x_customer_class_id NUMBER;
			x_customer_category_code    VARCHAR2(30);
			x_region_id	    NUMBER;
			x_order_type_id	    NUMBER;
			x_ship_to_location_id	    NUMBER;
			x_sales_channel_code        VARCHAR2(30);
			x_sales_person_id	    NUMBER;
			x_end_customer_id	    NUMBER;
			x_bill_to_location_id	    NUMBER;
			x_deliver_to_location_id    NUMBER;
			------------------------------------------------- No test due to data format not fixed

                BEGIN
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid: p_rule_level=>'||p_rule_level);

		    IF upper(p_rule_level) = upper('Customer') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer');

			SELECT acct.cust_account_id
			  INTO x_customer_id
			  FROM hz_parties party,
			       hz_cust_accounts acct
			 WHERE acct.party_id = party.party_id
			   AND acct.status = 'A'
			   AND party.party_name = x_rule_level_value;

		    ELSIF upper(p_rule_level) = upper('Customer Class') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer Class');

			SELECT cpc.profile_class_id
			  INTO x_customer_class_id
			  FROM hz_cust_profile_classes cpc
			 WHERE cpc.status = 'A'
			   AND cpc.profile_class_id >= 0
			   AND cpc.name = x_rule_level_value;

		    ELSIF upper(p_rule_level) = upper('Customer Category') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Customer Category');

			SELECT lookup_code
			  INTO x_customer_category_code
			  FROM ar_lookups
			 WHERE lookup_type = 'CUSTOMER_CATEGORY'
			   AND upper(meaning) = x_rule_level_value;

		    ELSIF upper(p_rule_level) = upper('End Customer') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End Customer');

			SELECT acct.cust_account_id
			  INTO x_end_customer_id
			  FROM hz_parties party,
			       hz_cust_accounts acct
			 WHERE acct.party_id = party.party_id
			   AND acct.status = 'A'
			   AND party.party_name = x_rule_level_value;

		    ELSIF upper(p_rule_level) = upper('Order Type') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Order Type');

			SELECT order_type_id
			  INTO x_order_type_id
			  FROM oe_order_types_v
			 WHERE TRUNC(sysdate) BETWEEN start_date_active
			   AND nvl(end_date_active,    TRUNC(sysdate))
			   AND upper(name) = upper(x_rule_level_value);

		    ELSIF upper(p_rule_level) = upper('Sales Channel') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Sales Channel');

			SELECT lookup_code
			  INTO x_sales_channel_code
			  FROM oe_lookups
			 WHERE lookup_type = 'SALES_CHANNEL'
			   AND sysdate BETWEEN nvl(start_date_active,    sysdate)
			   AND nvl(end_date_active,    sysdate)
			   AND enabled_flag = 'Y'
			   AND upper(meaning) = upper(x_rule_level_value);

		    ELSIF upper(p_rule_level) = upper('Sales Person') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Sales Person');

			SELECT salesrep_id
			  INTO x_sales_person_id
			  FROM ra_salesreps
			 WHERE TRUNC(sysdate) BETWEEN nvl(start_date_active,    TRUNC(sysdate))
			   AND nvl(end_date_active,    TRUNC(sysdate))
			   AND upper(name) = upper(x_rule_level_value);

    		    ELSIF upper(p_rule_level) = upper('Ship To Location') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Ship To Location');

			SELECT site.site_use_id
			  INTO x_ship_to_location_id
			  FROM hz_cust_acct_sites acct_site,
			       hz_party_sites party_site,
			       hz_locations loc,
			       hz_cust_site_uses site,
			       hz_parties party,
			       hz_cust_accounts cust_acct
			 WHERE site.site_use_code = 'SHIP_TO'
			   AND site.cust_acct_site_id = acct_site.cust_acct_site_id
			   AND acct_site.party_site_id = party_site.party_site_id
			   AND party_site.location_id = loc.location_id
			   AND acct_site.status = 'A'
			   AND acct_site.cust_account_id = cust_acct.cust_account_id
			   AND cust_acct.party_id = party.party_id
			   AND cust_acct.status = 'A'
			   AND site.status = 'A'
			   AND decode(loc.city,    NULL,    NULL,    loc.city || ', ') || decode(loc.state,    NULL,    loc.province || ', ',    loc.state || ', ') || decode(loc.postal_code,    NULL,    NULL,    loc.postal_code || ', ') || decode(loc.country,    NULL,    NULL,    loc.country)
				= x_rule_level_value;------------------------------------------------- No test due to data format not fixed

		    ELSIF upper(p_rule_level) = upper('Bill To Location') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Bill To Location');

			SELECT site.site_use_id
			  INTO x_bill_to_location_id
			  FROM hz_cust_acct_sites acct_site,
			       hz_party_sites party_site,
			       hz_locations loc,
			       hz_cust_site_uses site,
			       hz_parties party,
			       hz_cust_accounts cust_acct
			 WHERE site.site_use_code = 'BILL_TO'
			   AND site.cust_acct_site_id = acct_site.cust_acct_site_id
			   AND acct_site.party_site_id = party_site.party_site_id
			   AND party_site.location_id = loc.location_id
			   AND acct_site.status = 'A'
			   AND acct_site.cust_account_id = cust_acct.cust_account_id
			   AND cust_acct.party_id = party.party_id
			   AND cust_acct.status = 'A'
			   AND site.status = 'A'
			   AND decode(loc.city,    NULL,    NULL,    loc.city || ', ') || decode(loc.state,    NULL,    loc.province || ', ',    loc.state || ', ') || decode(loc.postal_code,    NULL,    NULL,    loc.postal_code || ', ') || decode(loc.country,    NULL,    NULL,    loc.country)
				= x_rule_level_value;------------------------------------------------- No test due to data format not fixed

		    ELSIF upper(p_rule_level) = upper('Deliver To Location') THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Deliver To Location');

			SELECT site.site_use_id
			  INTO x_deliver_to_location_id
			  FROM hz_cust_acct_sites acct_site,
			       hz_party_sites party_site,
			       hz_locations loc,
			       hz_cust_site_uses site,
			       hz_parties party,
			       hz_cust_accounts cust_acct
			 WHERE site.site_use_code = 'DELIVER_TO'
			   AND site.cust_acct_site_id = acct_site.cust_acct_site_id
			   AND acct_site.party_site_id = party_site.party_site_id
			   AND party_site.location_id = loc.location_id
			   AND acct_site.status = 'A'
			   AND acct_site.cust_account_id = cust_acct.cust_account_id
			   AND cust_acct.party_id = party.party_id
			   AND cust_acct.status = 'A'
			   AND site.status = 'A'
			   AND decode(loc.city,    NULL,    NULL,    loc.city || ', ') || decode(loc.state,    NULL,    loc.province || ', ',    loc.state || ', ') || decode(loc.postal_code,    NULL,    NULL,    loc.postal_code || ', ') || decode(loc.country,    NULL,    NULL,    loc.country)
				= x_rule_level_value;------------------------------------------------- No test due to data format not fixed

		    ELSIF upper(p_rule_level) = upper('Regions') THEN

			SELECT replace(x_rule_level_value, '$', ',')
			  INTO x_region_value
			  FROM DUAL;

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Regions => '||NVL(x_region_value, 'NULL'));
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Zone => '||'Check for Zone...');
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Zone => '||NVL(x_attribute10, 'NULL'));

			SELECT	region_id
			  INTO  x_rule_value_id
			  FROM	wsh_regions_v
			 WHERE country
			     ||', '||state
			     ||', '||city
			     ||', '||ZONE
			     ||', '||postal_code_from
			     ||' -'||postal_code_to /*= x_region_value;*/
			     = x_region_value||', '||', '||', '||x_attribute10||', '||' -';

			p_rule_value_id := x_rule_value_id;

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Regions ID => '||p_rule_value_id);

			RETURN x_error_code;

		    ELSE

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Rule Level can be either "Customer" or "Customer Class" or "Customer Category" or "End Customer" or "Order Type" or "Sales Channel" or "Sales Person" or "Ship To Location" or "Bill To Location" or "Deliver To Location" or "Regions"' );
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_VALID
			    ,p_error_text  => 'Rule Level can be either "Customer" or "Customer Class" or "Customer Category" or "End Customer" or "Order Type" or "Sales Channel" or "Sales Person" or "Ship To Location" or "Bill To Location" or "Deliver To Location" or "Regions"'
			    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			    ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			    ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
			     );
		    END IF;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid: Success p_rule_level=>'||p_rule_level);

                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_WARN;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level=>'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );

		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level=>'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Rule Level=>'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Rule Level ' || x_error_code);
                        RETURN x_error_code;
		END is_rule_level_valid;

                --code to validate enabled--
                FUNCTION is_enabled_valid (p_enabled    IN VARCHAR2
                                           )
                                           RETURN NUMBER
                IS
		    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
                BEGIN
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_enabled_valid: p_enabled=>'||p_enabled);

		    IF trim(p_enabled) <> 'Y' AND trim(p_enabled) <> 'N' THEN

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Enabled can be either "Y" or "N"' );
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_VALID
			    ,p_error_text  => 'Enabled can be either "Y" or "N"'
			    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			    ,p_record_identifier_2 => p_cnv_hdr_rec.operating_unit
			    ,p_record_identifier_3 => p_cnv_hdr_rec.item_number
			     );
		    END IF;

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_enabled_valid: Success Enabled=>'||p_enabled);

                    RETURN x_error_code;
		END is_enabled_valid;


        -- Start of the main function perform_batch_validations
        -- This will only have calls to the individual functions.
        BEGIN
       	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

	    IF(p_cnv_hdr_rec.operating_unit IS NOT NULL)
	      THEN
	  	x_error_code_temp := is_ou_valid(p_cnv_hdr_rec.operating_unit
	  	                                          ,p_cnv_hdr_rec.org_id);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ou_valid - error '||x_error_code_temp);

	      	x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ou_valid not called as Operating Unit is null ');
	    END IF;

	    IF(p_cnv_hdr_rec.item_number IS NOT NULL)
	      THEN
		x_error_code_temp := is_item_number_valid(p_cnv_hdr_rec.item_number
		                                         ,p_cnv_hdr_rec.inventory_item_id);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid not called as Item Number is null ');
	    END IF;

	    IF(p_cnv_hdr_rec.criteria IS NOT NULL)
	      THEN
		x_error_code_temp := is_criteria_valid(p_cnv_hdr_rec.criteria
		                                          );
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_criteria_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_criteria_valid not called as Criteria is null ');
	    END IF;

	    IF(p_cnv_hdr_rec.category_name IS NOT NULL)
	      THEN
		x_error_code_temp := is_category_valid(p_cnv_hdr_rec.category_name
		                                      ,p_cnv_hdr_rec.category_id);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_category_valid not called as Category Name is null ');
	    END IF;

	    IF(p_cnv_hdr_rec.general_available IS NOT NULL)
	      THEN
		x_error_code_temp := is_general_available_valid(p_cnv_hdr_rec.general_available);

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_general_available_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_general_available_valid not called as General Available is null ');
	    END IF;

	    IF(p_cnv_hdr_rec.rule_level IS NOT NULL)
	      THEN
		x_error_code_temp := is_rule_level_valid(p_cnv_hdr_rec.rule_level, p_cnv_hdr_rec.rule_level_value, p_cnv_hdr_rec.rule_value_id, p_cnv_hdr_rec.attribute10);

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_valid not called as Rule Level is null ');
	    END IF;

	    /*
	    IF(p_cnv_hdr_rec.rule_level_value IS NOT NULL)
	      THEN
		x_error_code_temp := is_rule_level_value_valid(p_cnv_hdr_rec.rule_level_value);

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_value_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rule_level_value_valid not called as Rule Level Value is null ');
	    END IF;
	    */

	    IF(p_cnv_hdr_rec.enabled IS NOT NULL)
	      THEN
		x_error_code_temp := is_enabled_valid(p_cnv_hdr_rec.enabled);

		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_enabled_valid - error '||x_error_code_temp);

		x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_enabled_valid not called as Enabled value is null ');
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
		p_cnv_pre_std_hdr_rec IN OUT xx_ont_itemord_pkg.G_XX_ONT_ITEMORD_PRE_REC_TYPE
	) RETURN NUMBER
	IS
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	------------------
	BEGIN
  	    RETURN x_error_code;
	END data_derivations;

END xx_ont_itemord_val_pkg;
/


GRANT EXECUTE ON APPS.XX_ONT_ITEMORD_VAL_PKG TO INTG_XX_NONHR_RO;
