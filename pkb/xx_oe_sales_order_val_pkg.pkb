DROP PACKAGE BODY APPS.XX_OE_SALES_ORDER_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_SALES_ORDER_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Samir Singha Mahapatra
 Creation Date : 14-Mar-2012
 File Name     : XXOESOHDRVAL.pkb
 Description   : This script creates the body of the package
                 xx_oe_sales_order_val_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 14-MAR-2012 Samir                 Initial development.
 06-JUL-2012 Sharath Babu          Modified ship to logic as per change request
 30-OCT-2012 Sharath Babu          Added is_ship_priority_code_valid as per TDR
 21-JAN-2013 Sharath Babu          Added batch id join in pre validation update
 15-MAY-2013 Sharath Babu          Modified as per Wave1
 12-Jun-2013 Dinesh                Added NOT IN S in tax exempt check
 14-JUN-2014 Sharath Babu          Modified pre_validations to take values from 
                                   Process setup only in null as per Wave1
 07-OCT-2013 Sharath Babu          Modified logic to check for Booked Flag 'N'  
 09-NOV-2013 Sharath Babu          Modified as per Wave1 UIT run
 03-FEB-2014 Sharath Babu          Modified as per Wave1
 28-FEB-2014 Sharath Babu          Modified to add orig_system_reference for account_number
*/
----------------------------------------------------------------------
   FUNCTION find_max (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
   )
      RETURN VARCHAR2
   IS
      x_return_value VARCHAR2(100);
   BEGIN
	x_return_value := XX_INTG_COMMON_PKG.find_max(p_error_code1, p_error_code2);
        
	RETURN x_return_value;
   END find_max;
   
 FUNCTION pre_validations
    RETURN NUMBER
        IS
		x_error_code		NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp	NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		PRAGMA AUTONOMOUS_TRANSACTION;
         BEGIN
	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations');
	    UPDATE XX_OE_ORDER_HEADERS_ALL_STG
	       SET ship_from_org = NVL(ship_from_org,xx_oe_sales_order_conv_pkg.G_SHIP_FROM_ORG),
                   sold_from_org = NVL(sold_from_org,xx_oe_sales_order_conv_pkg.G_ORG_NAME),
		   org_code = NVL(org_code,xx_oe_sales_order_conv_pkg.G_ORG_NAME),
                   order_source = NVL(order_source,xx_oe_sales_order_conv_pkg.G_SOURCE_NAME),
		   order_type = NVL(order_type,NVL2(return_reason_code, xx_oe_sales_order_conv_pkg.G_RMA_ORDER_TYPE, xx_oe_sales_order_conv_pkg.G_ORDER_TYPE))
		  ,price_list = NVL(price_list,xx_oe_sales_order_conv_pkg.G_PRICE_LIST)   --Added as per Wave1
             WHERE batch_id = xx_oe_sales_order_conv_pkg.G_BATCH_ID
	       --AND order_source IS NULL
                   ;
            UPDATE XX_OE_ORDER_LINES_ALL_STG line
	       SET line_type = NVL(line_type, DECODE ((SELECT order_type 
	                                                 FROM XX_OE_ORDER_HEADERS_ALL_STG 
	                                                WHERE orig_sys_document_ref=line.orig_sys_document_ref
	                                                  AND batch_id = xx_oe_sales_order_conv_pkg.G_BATCH_ID  --Added on 21-JAN-13
	                                              ),
		                            xx_oe_sales_order_conv_pkg.G_ORDER_TYPE, 
		                            		xx_oe_sales_order_conv_pkg.G_LINE_TYPE, --xx_oe_sales_order_conv_pkg.G_SHIPONLY_LINE, --Changed in SIT
					    xx_oe_sales_order_conv_pkg.G_RMA_ORDER_TYPE, 
                                                --DECODE (line.line_type,                -- Joydeb (FS owner) confirmed only C will be sent
                                                --        'C', 
                                            xx_oe_sales_order_conv_pkg.G_RMA_LINE_TYPE
                                                --                'R', xx_oe_sales_order_conv_pkg.G_SHIPONLY_LINE ---G_LINE_TYPE -- Changed in SIT
                                                --    )                                --  Also, decode wihtin decode is not working					   
					  )),
		   price_list = NVL(price_list,xx_oe_sales_order_conv_pkg.G_PRICE_LIST),
                   ship_from_org = NVL(ship_from_org,xx_oe_sales_order_conv_pkg.G_SHIP_FROM_ORG)
             WHERE batch_id = xx_oe_sales_order_conv_pkg.G_BATCH_ID
	       --AND line_type IS NULL
	       ;
            COMMIT;
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
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Pre-Validations');
	END pre_validations;
  
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- END OF PRE-VALIDATIONS
-----------------------------------------------------------------------------------------------------------------------------------------------------
  
  ----------------  Order Header level Data Validations ------------------------------------------------------
  FUNCTION data_validations(p_cnv_hdr_rec IN OUT xx_oe_sales_order_conv_pkg.G_XX_SO_CNV_PRE_STD_REC_TYPE )
      RETURN NUMBER
    IS
	 x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
	 x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

	--- Local functions for all batch level validations
	--- Add as many functions as required in her
-----------------------------------------------------------------------------------------------------------------

FUNCTION is_organization_valid (p_organization_code IN  VARCHAR2,
                                p_organization_id  OUT NUMBER
				,p_orig_sys_document_ref IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		NUMBER;
	 x_organization_name	VARCHAR2(60);
      BEGIN

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Legacy Order Header => '|| p_orig_sys_document_ref);
	       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Organization Code   => '|| p_organization_code);

		IF p_organization_code IS NOT NULL THEN
		   SELECT organization_id
		     INTO p_organization_id
		     FROM hr_operating_units
		    WHERE upper(name)    = upper(p_organization_code);

		ELSE
		
			xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
					 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
					 ,p_error_text  => 'Order Header Level : Invalid organization code => '||p_orig_sys_document_ref || xx_emf_cn_pkg.CN_NO_DATA 
					 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
					 ,p_record_identifier_2 => p_organization_code
					 ,p_record_identifier_3 => p_cnv_hdr_rec.order_number
			      );
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;

		END IF;

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid: Success Organization_ID=>'||p_organization_id);
                    RETURN x_error_code;

                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid organization code =>'|| p_organization_code ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_number
                               );
	                 RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid organization code =>' || p_organization_code ||'-'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.ORIG_SYS_DOCUMENT_REF
                               );

			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Organization Validation ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid organization code =>'|| p_organization_code ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_organization_code
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.ORIG_SYS_DOCUMENT_REF
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Organization ' || x_error_code);
                        RETURN x_error_code;
END is_organization_valid;
-----------------------------------------------------------------------------------------------------------------
FUNCTION is_orig_sys_doc_ref_null(p_orig_sys_document_ref IN VARCHAR2
                                  ) RETURN NUMBER IS
  
       x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
  
     BEGIN
  
      IF p_orig_sys_document_ref IS NULL THEN
       -- x_error_code := xx_emf_cn_pkg.cn_rec_err;
        xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
	                 ,p_category   => xx_emf_cn_pkg.cn_valid
	                 ,p_error_text => 'Header Level Orig Sys Document Ref Column is Null '||p_orig_sys_document_ref
	                 );
      END IF;
  
      RETURN x_error_code;
 END is_orig_sys_doc_ref_null;
--------------------------------------------validation for Order Type--------------------------------------------

FUNCTION is_order_type_valid (p_organization_code	IN		VARCHAR2
                             ,p_order_type		IN OUT NOCOPY	VARCHAR2
                             ,p_order_type_id		OUT		NUMBER
			     ,p_order_category          OUT             VARCHAR2
			     ,p_invoicing_rule_id         OUT             NUMBER
                             ,p_accounting_rule_id      OUT             NUMBER
			     ,p_orig_sys_document_ref	IN		VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
	 x_order_type   VARCHAR2(100);
     BEGIN
	            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_order_type_valid: Order Type => '||p_order_type);

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Organization Code : '|| p_organization_code );                                                        

                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_order_type_valid: '||'Organization Code : '|| p_organization_code ||'Order Type : '|| x_order_type ||'La->'||USERENV ('LANG'));

                    SELECT otta.transaction_type_id,
		           otta.order_category_code,
                           otta.invoicing_rule_id,
                           otta.accounting_rule_id
		      INTO p_order_type_id,
		           p_order_category,
                           p_invoicing_rule_id,
                           p_accounting_rule_id
		      FROM oe_transaction_types_tl ott,
		           oe_transaction_types_all otta
		     WHERE UPPER(ott.NAME) = UPPER(nvl(x_order_type,p_order_type))  --Added upper as per wave1
		      AND ott.transaction_type_id=otta.transaction_type_id
		      AND rownum = 1
		      AND ott.LANGUAGE = USERENV ('LANG');

		    p_order_type := x_order_type;

                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_order_type_valid: '||'Organization Code : '|| p_organization_code ||'Order Type : '|| x_order_type ||' Order_Type_id => '|| p_order_type_id);

                    RETURN x_error_code;


                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => p_orig_sys_document_ref || ' Hdr Level : Invalid Order Type => '|| p_order_type ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.order_type
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_type||'-'||p_order_type_id
                               );
                         RETURN x_error_code;

                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => p_orig_sys_document_ref || ' Hdr Level : Invalid Order Type => '|| p_order_type ||'-'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.order_type
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_type||'-'||p_order_type_id
                               );
			 RETURN x_error_code;

                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => p_orig_sys_document_ref || ' Hdr Level : Invalid Order Type => '|| p_order_type ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.order_type
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_type||'-'||p_order_type_id
                               );

                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Order Type ' || x_error_code);
                        
			RETURN x_error_code;

      END is_order_type_valid;

-------------------validation for Order Source------------------------------------------
FUNCTION is_order_source_valid (p_order_source IN VARCHAR2
                             ,p_order_source_id OUT NUMBER
			     ,p_orig_sys_document_ref IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
     BEGIN
        IF (upper(p_order_source) != xx_oe_sales_order_conv_pkg.G_SOURCE_NAME)
        THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Order Header Level => Invalid Order Source, Order source should be (CONVERSION)'||p_orig_sys_document_ref);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			    ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			    ,p_error_text  => 'Invalid Order Source, Order source should be =>'||xx_oe_sales_order_conv_pkg.G_SOURCE_NAME
			    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			    ,p_record_identifier_2 => p_cnv_hdr_rec.order_source
			    ,p_record_identifier_3 => p_cnv_hdr_rec.order_source||'-'||p_order_source
                            );
        ELSE
	   SELECT order_source_id
	     INTO p_order_source_id
	     FROM oe_order_sources
	    WHERE upper(name) = upper(p_order_source )
	      AND enabled_flag = 'Y';
	   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_order_source_valid : '|| p_order_source || ' Success Order_Source_id => ' || p_order_source_id);
       END IF;
       RETURN x_error_code;
   EXCEPTION
      WHEN TOO_MANY_ROWS THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                          ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
	                  ,p_error_text  => 'Order Header Level : Invalid Order Source => '||p_orig_sys_document_ref ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
	                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
	                  ,p_record_identifier_2 => p_cnv_hdr_rec.order_source
	                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_source||'-'||p_order_source_id
                          );
         RETURN x_error_code;
      WHEN NO_DATA_FOUND THEN
	 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	 xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
	                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
	                  ,p_error_text  => 'Order Header Level : Invalid Order Source => '||p_orig_sys_document_ref ||'-'||xx_emf_cn_pkg.CN_NO_DATA
	                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
	                  ,p_record_identifier_2 => p_cnv_hdr_rec.order_source
	                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_source||'-'||p_order_source_id
                          );
	 RETURN x_error_code;
      WHEN OTHERS THEN
	 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	 xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
	                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
	                  ,p_error_text  => 'Order Header Level : Invalid Order Source =>'||p_orig_sys_document_ref ||'-'||SQLERRM
	                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
	                  ,p_record_identifier_2 => p_cnv_hdr_rec.order_source
	                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_source||'-'||p_order_source_id
                           );
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Order Source ' || x_error_code);                     
	RETURN x_error_code;
   END is_order_source_valid;
-------------------End - validation for Order Source -------------------------------------------

------------------- validation for Price List ---------------------------------------------------

FUNCTION is_price_list_valid (p_price_list		IN  VARCHAR2
                             ,p_pricelist_id		OUT NUMBER
			     ,p_organization_id		IN  NUMBER	
			     ,p_order_type_id		IN  NUMBER
			     ,p_orig_sys_document_ref	IN  VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
	 x_price_list	VARCHAR2(100);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_price_list_valid: Price List => '|| p_price_list);
	       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_price_list_valid: Org Id     => '|| p_organization_id);

               IF p_price_list IS NOT NULL THEN
	       
	        SELECT list_header_id 
		INTO  p_pricelist_id
		FROM apps.qp_list_headers 
		WHERE 1=1
		AND UPPER(name)       = UPPER(p_price_list);  --Added upper as per wave1

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header : '|| p_orig_sys_document_ref ||' Price List => '|| x_price_list || ' Price_List_id => ' || p_pricelist_id);
                END IF;
                RETURN x_error_code;

     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Price List => '|| p_price_list ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.price_list
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.price_list_id||'-'||p_pricelist_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Price List => '|| p_price_list ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.price_list
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.price_list_id||'-'||p_pricelist_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Price List => '|| p_price_list ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.price_list
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.price_list_id||'-'||p_pricelist_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Price List ' || x_error_code);
               
		RETURN x_error_code;

      END is_price_list_valid;

------------------- End validation for Price List ------------------------------------------
------------------- validation for Customer Bill To Site ------------------------------------------
FUNCTION is_cust_billto_site_valid ( p_cust_number              IN  VARCHAR2
                                    ,p_bill_to_cust             IN  VARCHAR2
                                    ,p_bill_to_ref              IN  VARCHAR2       --Added as per Wave1
                                    ,p_inv_to_org_id		IN OUT NOCOPY NUMBER
			            ,p_organization_id		IN  NUMBER
			            ,p_orig_sys_document_ref	IN  VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable        VARCHAR2 (40);
	 l_valid	   NUMBER;
	 x_invoice_to_org  VARCHAR2(50) := NULL;
	 x_related_cust    VARCHAR2(1)  := 'N';
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_cust_billto_valid: organization_id =>' || p_organization_id);
                 --Modifed as per Wave1
	         SELECT hcsu.site_use_id
		   INTO p_inv_to_org_id
                   FROM hz_cust_accounts hca,
                        hz_party_sites hps,
                        hz_cust_acct_sites_all hcas,
                        hz_cust_site_uses_all hcsu
                  WHERE hca.party_id=hps.party_id
                    AND hcas.cust_account_id=hca.cust_account_id
                    AND hcas.party_site_id=hps.party_site_id
                    AND hcsu.cust_acct_site_id=hcas.cust_acct_site_id
                    AND hcsu.site_use_code='BILL_TO'
		    --AND hcsu.primary_flag='Y'              --Commented as per Wave1
		    AND hcsu.status='A'
		    AND hca.status='A'
                    AND hcas.org_id=hcsu.org_id
                    AND hcsu.orig_system_reference = p_bill_to_ref    --Added as per Wave1
                    --AND hca.account_number= p_bill_to_cust  --p_cust_number  Modified on 28-FEB-2014
                    AND hca.orig_system_reference = p_bill_to_cust
		    AND hcsu.org_id=p_organization_id;
	         --If bill to and ship to account is different then both the accounts should have a relationship
		 IF p_cust_number != p_bill_to_cust
		 THEN
		    BEGIN
		       SELECT 'Y'
		         INTO x_related_cust
                         FROM hz_cust_acct_relate_all hcar,
                              hz_cust_accounts bill_hca,
                              hz_cust_accounts ship_hca
	                WHERE --bill_hca.account_number=p_bill_to_cust  --Modified on 28-FEB-2014
	                      bill_hca.orig_system_reference = p_bill_to_cust
                          --AND ship_hca.account_number=p_cust_number
                          AND ship_hca.orig_system_reference=p_cust_number
                          AND hcar.bill_to_flag='Y'
                          AND hcar.cust_account_id=bill_hca.cust_account_id
                          AND hcar.related_cust_account_id=ship_hca.cust_account_id
		          AND hcar.org_id=p_organization_id
		         ;
		    EXCEPTION
		       WHEN NO_DATA_FOUND THEN
                          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Invoice To Org =>'|| p_inv_to_org_id||' Bill to account is not related'
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.invoice_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.invoice_to_org||'-'||p_inv_to_org_id
                                  );
		        WHEN OTHERS THEN
                           x_related_cust := 'Y';
		    END;
                 END IF;  		     
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invoice To Org: Success Invoice To Org Id=>'||p_inv_to_org_id);
                RETURN x_error_code;

     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Invoice To Org =>'|| p_inv_to_org_id ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.invoice_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.invoice_to_org||'-'||p_inv_to_org_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Invoice To Org =>'|| p_inv_to_org_id ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.invoice_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.invoice_to_org||'-'||p_inv_to_org_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Invoice To Org =>'|| p_inv_to_org_id ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.invoice_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.invoice_to_org||'-'||p_inv_to_org_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Invoice To Org ' || x_error_code);
               
		RETURN x_error_code;

      END is_cust_billto_site_valid;
------------------- End validation for Cust Bill To Site ---------------------------------------------
------------------- validation for Customer Ship To Site ------------------------------------------
FUNCTION is_cust_shipto_site_valid ( p_cust_number              IN  VARCHAR2
                                    ,p_ship_to_ref              IN  VARCHAR2
                                    ,p_ship_to_org_id		IN OUT NOCOPY NUMBER
			            ,p_organization_id		IN  NUMBER
			            ,p_orig_sys_document_ref	IN  VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable        VARCHAR2 (40);
	 l_valid	   NUMBER;
	 x_invoice_to_org  VARCHAR2(50) := NULL;
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_cust_shipto_valid: organization_id =>' || p_organization_id);
                 --Modified query as per change request
                 SELECT hcsu.site_use_id
		   INTO p_ship_to_org_id
                   FROM hz_cust_accounts hca,
                        hz_party_sites hps,
                        hz_cust_acct_sites_all hcas,
                        hz_cust_site_uses_all hcsu
                  WHERE hca.party_id=hps.party_id
                    AND hcas.cust_account_id=hca.cust_account_id
                    AND hcas.party_site_id=hps.party_site_id
                    AND hcsu.cust_acct_site_id=hcas.cust_acct_site_id
                    AND hcsu.site_use_code='SHIP_TO'
		    --AND hcsu.primary_flag='Y'
		    AND hcsu.status='A'
		    AND hca.status='A'
                    AND hcas.org_id=hcsu.org_id
                    --AND hca.account_number=p_cust_number           --Modified on 28-FEB-2014
                    AND hca.orig_system_reference=p_cust_number
                    --AND hcas.orig_system_reference=p_ship_to_ref   --Commented as per Wave1
                    AND hcsu.orig_system_reference = p_ship_to_ref   --Added as per Wave1
		    AND hcsu.org_id=p_organization_id;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Ship To Org: Success Ship To Org Id=>'||p_ship_to_org_id);
                RETURN x_error_code;

     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Ship To Org =>'|| p_ship_to_org_id ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_to_org||'-'||p_ship_to_org_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Ship To Org =>'|| p_ship_to_org_id ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_to_org||'-'||p_ship_to_org_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Ship To Org =>'|| p_ship_to_org_id ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_to_org||'-'||p_ship_to_org_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Ship To Org ' || x_error_code);
               
		RETURN x_error_code;

      END is_cust_shipto_site_valid;
------------------- End validation for Cust Ship ToSite ---------------------------------------------
-------------------  Validation for Shipping Method Code   ---------------------------------------------
FUNCTION is_ship_method_code_valid (p_cust_number       	IN VARCHAR2
                                   ,p_ship_method_code		IN OUT NOCOPY VARCHAR2
				   ,p_orig_sys_document_ref	IN VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_ship_method_code	VARCHAR2 (50);
     BEGIN
               --09-AUG-12 Modified to fix ship method code issue
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ship_method_code_valid: Customer Number =>'||p_cust_number);
               /*SELECT ship_via
	         INTO p_ship_method_code
	         FROM hz_cust_accounts
		WHERE account_number = p_cust_number;*/	
         
         x_ship_method_code :=
            xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'SHIP_VIA'                                                  
                                                  ,p_old_value => p_ship_method_code                                                                                                   
                                                  ,p_date_effective => SYSDATE
                                                 );
                                                     
         SELECT DISTINCT ship_method_code
           INTO p_ship_method_code
           FROM wsh_carrier_services_v 
          --WHERE UPPER(ship_method_meaning) = UPPER(x_ship_method_code); --Modified as per Wave1 as data file contains code
          WHERE UPPER(ship_method_code) = UPPER(x_ship_method_code);
             
         RETURN x_error_code;

     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipping Method Code =>'|| p_ship_method_code ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.shipping_method_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.shipping_method_code||'-'||p_ship_method_code
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipping Method Code =>'|| p_ship_method_code || xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.shipping_method_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.shipping_method_code||'-'||p_ship_method_code
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipping Method Code =>'|| p_ship_method_code ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                 ,p_record_identifier_2 => p_cnv_hdr_rec.shipping_method_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.shipping_method_code||'-'||p_ship_method_code
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Shipping Method Code ' || x_error_code);
               
		RETURN x_error_code;

      END is_ship_method_code_valid;
------------------- End Validation for Shipment Method Code ---------------------------------------------

-------------------  Validation for Currency Code -------------------------------------------------------
FUNCTION is_currency_code_valid (p_trans_curr_code  IN OUT VARCHAR2
                                ,p_orig_sys_document_ref IN VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
     BEGIN
              -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_currency_code_valid: Currency Code =>'||p_trans_curr_code);
	       IF p_trans_curr_code IS NOT NULL THEN
               SELECT 'X'
  	       INTO   x_variable
  	       FROM   fnd_currencies fc
               WHERE  UPPER(fc.currency_code) = UPPER(p_trans_curr_code) -- check if the currency is defined  Added upper as per Wave1
               AND    NVL(fc.end_date_active,ADD_MONTHS(SYSDATE,1)) >= ADD_MONTHS(SYSDATE,1) -- check if the currency is active forthe whole month
      	       AND    fc.enabled_flag = 'Y'; -- check if the currency is enabled
            ELSE
               xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                                     'Header : '|| p_orig_sys_document_ref||' Currency Code is NULL'|| p_trans_curr_code,
                                     p_cnv_hdr_rec.record_number,
                                     'Invalid Currency',
                                     'Invalid Currency Code'
                                    );
              -- x_error_code := xx_emf_cn_pkg.cn_rec_err;
            END IF;
   	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header : '|| p_orig_sys_document_ref||' Currency Code => ' || p_trans_curr_code);
            RETURN x_error_code;

     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Currency Code =>'|| p_trans_curr_code ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 =>'Invalid Currency'      --p_record_identifier_2 => 
                                  ,p_record_identifier_3 =>'Invalid Currency Code' --p_record_identifier_3 =>
		                  
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Currency Code =>'|| p_trans_curr_code||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 =>'Invalid Currency'      --p_record_identifier_2 => 
                                  ,p_record_identifier_3 =>'Invalid Currency Code' --p_record_identifier_3 =>
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Currency Code =>'|| p_trans_curr_code ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 =>'Invalid Currency'      --p_record_identifier_2 => 
                                  ,p_record_identifier_3 =>'Invalid Currency Code' --p_record_identifier_3 =>
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Currency Code ' || x_error_code);
               
		RETURN x_error_code;

      END is_currency_code_valid;
------------------- End Validation for Currency Code ---------------------------------------------
-------------------  Validation for Tax Exempt Flag ---------------------------------------------
FUNCTION is_tax_exempt_flag_valid (p_tax_exempt_flag IN OUT VARCHAR2
				  ,p_orig_sys_document_ref IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);

     BEGIN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_tax_exempt_flag_valid : Tax Exempt Flag =>'||p_tax_exempt_flag);


                   IF (upper(p_tax_exempt_flag) NOT IN ('R', 'T','S'))  --Added as per Wave1
                   THEN
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Tax Exempt Flag, Tax_exempt_flag should be (S)');
 	              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Order Header Level : Invalid Tax Exempt Flag, Tax_exempt_flag should be (S) =>'
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.tax_exempt_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.tax_exempt_flag||'-'||p_tax_exempt_flag
                               );
                   ELSE
		        IF p_tax_exempt_flag = 'R'
			THEN
			   p_tax_exempt_flag := 'S';
			ELSE
                           p_tax_exempt_flag := 'S';
			END IF;
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_tax_exempt_flag_valid : Success Tax_exempt_flag =>'||p_tax_exempt_flag);

                   END IF;

                   RETURN x_error_code;

                EXCEPTION

                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Tax Exempt Flag =>'|| p_tax_exempt_flag ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.tax_exempt_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.tax_exempt_flag||'-'||p_tax_exempt_flag
                               );
                         RETURN x_error_code;

                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Tax Exempt Flag =>'|| p_tax_exempt_flag ||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.tax_exempt_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.tax_exempt_flag||'-'||p_tax_exempt_flag
                               );
			 RETURN x_error_code;

                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Tax Exempt Flag =>'|| p_tax_exempt_flag ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.tax_exempt_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.tax_exempt_flag||'-'||p_tax_exempt_flag
                               );

                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Tax Exempt Flag ' || x_error_code);
                        
			RETURN x_error_code;

      END is_tax_exempt_flag_valid;
------------------- End Validation for Tax Exempt Flag ---------------------------------------------

-------------------  Validation for Payment Term ---------------------------------------------
FUNCTION is_payment_term_valid (p_org_code		 IN		VARCHAR2
                                ,p_payment_term		 IN OUT NOCOPY	VARCHAR2
				,p_payment_term_id	 OUT    NOCOPY	NUMBER	
				,p_orig_sys_document_ref IN		VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_payment_term		VARCHAR2(40);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_payment_term_valid: Payment Term =>'||p_payment_term||'-'||p_org_code);

		IF p_payment_term IS NOT NULL THEN

		x_payment_term := XX_INTG_COMMON_PKG.get_mapping_value(p_mapping_type    => 'PAYMENT_TERM'
								     ,p_source          => NULL
								     ,p_old_value1      => p_payment_term
								     ,p_old_value2      => 'AR'
								     ,p_date_effective  => sysdate);

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Success Payment Term    =>'||x_payment_term);
		SELECT term_id,
                       name
		INTO p_payment_term_id,
                     p_payment_term
		FROM RA_TERMS_TL at1      
  	       WHERE UPPER(trim(at1.name))  =  UPPER(x_payment_term)--nvl(x_payment_term,p_payment_term)
		--AND enabled_flag	= 'Y'
		AND    language		= 'US';

		p_payment_term := x_payment_term;

                
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header : '|| p_orig_sys_document_ref||' Org Code : '||p_org_code ||'  Payment Term => '|| p_payment_term ||'  Payment Term ID => '||p_payment_term_id);

		END IF;

                RETURN x_error_code;

     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Payment Term =>'|| p_payment_term ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.payment_term
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.payment_term||'-'||p_payment_term_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Payment Term =>'|| p_payment_term ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.payment_term
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.payment_term||'-'||p_payment_term_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Payment Term =>'|| p_payment_term ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.payment_term
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.payment_term||'-'||p_payment_term_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Payment Term ' || x_error_code);
               
		RETURN x_error_code;

      END is_payment_term_valid;
------------------- End Validation for Payment Term ---------------------------------------------

-------------------  Validation for Freight Terms Code ---------------------------------------------
FUNCTION is_freight_term_valid (p_freight_term           IN OUT NOCOPY	VARCHAR2                               
				,p_sold_to_org		 IN		VARCHAR2
				,p_orig_sys_document_ref IN		VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_freight_term		VARCHAR2(40);
	 x_cust_no		NUMBER;
     BEGIN
              	IF p_freight_term IS NOT NULL THEN
		      x_freight_term := XX_INTG_COMMON_PKG.get_mapping_value(p_mapping_type    => 'FREIGHT_TERMS_OM'
		                                                           ,p_source          => NULL
                                                                           ,p_old_value       => p_freight_term
                                                                           ,p_date_effective  => sysdate);
		       SELECT meaning
		       INTO   p_freight_term
  		       FROM   fnd_lookup_values
  			--WHERE  UPPER(meaning) = UPPER(x_freight_term)  ----Modified as per Wave1 as data file contains code
  	              WHERE  UPPER(lookup_code) = UPPER(x_freight_term)
  			AND    lookup_type =  'FREIGHT_TERMS' --xx_emf_cn_pkg.cn_freight_terms_code           -- CN_FREIGHT_TERMS_CODE := 'FREIGHT TERMS'
  			AND    ENABLED_FLAG = 'Y'
			AND    language  = 'US'
			AND    nvl(end_date_active,SYSDATE)>=SYSDATE;
		
		ELSE			
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Fetching default freight term from customer          ' || p_sold_to_org);		    

			SELECT freight_term, account_number
			INTO p_freight_term, x_cust_no
			FROM hz_cust_accounts 
			WHERE 1=1--orig_system_reference = p_sold_to_org
                          --AND account_number=p_sold_to_org  Modified on 28-FEB-2014
                          AND orig_system_reference = p_sold_to_org
			  AND status			= 'A';	    

		END IF;

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Success FREIGHT TERM => '|| x_freight_term);
                RETURN x_error_code;

     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Freight Term =>'|| p_freight_term ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.freight_terms_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.freight_terms_code||'-'||p_freight_term
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Freight Term =>'|| p_freight_term || xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.freight_terms_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.freight_terms_code||'-'||p_freight_term
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Freight Term =>'|| p_freight_term ||'-'||SQLERRM
		                ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.freight_terms_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.freight_terms_code||'-'||p_freight_term
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Freight Term ' || x_error_code);
               
		RETURN x_error_code;

      END is_freight_term_valid;
------------------- End Validation for Freight Terms Code-------------------------------------------

--------------------------------- Validation For FOB     -------------------------------------------
FUNCTION is_FOB_valid (p_fob			 IN OUT NOCOPY	VARCHAR2 
		      ,p_sold_to_org		 IN		VARCHAR2
		      ,p_orig_sys_document_ref   IN		VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_fob			VARCHAR2(40);
	 x_cust_no		NUMBER;
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_FOB_valid : FOB  => ' || p_fob);

		IF p_fob IS NOT NULL
		THEN
		      x_fob := XX_INTG_COMMON_PKG.get_mapping_value(p_mapping_type    => 'FOB_POINT' 
		                                                  ,p_source          => NULL
                                                                  ,p_old_value       => p_fob
                                                                  ,p_date_effective  => SYSDATE);
                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_FOB_valid : FOB : => ' || x_fob);                                                                                                                                 
		       SELECT lookup_code
			INTO   p_fob
			FROM   fnd_lookup_values
			WHERE  1=1 
			--AND    meaning      = x_fob  --Modified as per Wave1 as data file contains code
			AND    UPPER(lookup_code) = UPPER(x_fob)
			AND    lookup_type  =  xx_emf_cn_pkg.CN_FOB_LOOKUP_CODE 
			AND    ENABLED_FLAG = 'Y'
			AND    language     = 'US'
			AND    nvl(end_date_active,SYSDATE)>=SYSDATE  
			AND ROWNUM = 1;
			
		ELSE			
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Fetching default FOB from customer   ' || p_sold_to_org);		    

			SELECT fob_point
			INTO   p_fob
			FROM hz_cust_accounts 
			WHERE 1=1--orig_system_reference = p_sold_to_org
			  --AND account_number=p_sold_to_org  Modified on 28-FEB-2014
			  AND orig_system_reference = p_sold_to_org
			  AND status			= 'A';

		END IF;

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header : '|| p_orig_sys_document_ref||' FOB => '|| p_fob);
                RETURN x_error_code;

     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid FOB =>'|| p_fob ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.FOB_POINT_CODE
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.FOB_POINT_CODE||'-'|| p_fob
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid FOB =>'|| p_fob || xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.FOB_POINT_CODE
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.FOB_POINT_CODE ||'-'|| p_fob
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid FOB =>'|| p_fob ||'-'||SQLERRM
		                ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.FOB_POINT_CODE
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.FOB_POINT_CODE ||'-'|| p_fob
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE FOB_POINT_CODE :  ' || x_error_code);
               
		RETURN x_error_code;

      END is_FOB_valid;
--------------------------------- End Validation For FOB     ---------------------------------------

-------------------  Validation for Customer PO Number  --------------------------------------------
FUNCTION is_cust_po_num_valid (p_cust_po_num  IN OUT VARCHAR2
			 ,p_orig_sys_document_ref IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_cust_po_num  	VARCHAR2(40);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_cust_po_num_valid: Customer PO Number =>'||p_cust_po_num);

		IF p_cust_po_num IS NULL
		THEN
		
			 xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Customer PO Number is NULL'
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => null
		                  ,p_record_identifier_3 => null
                                    );
			--x_error_code := xx_emf_cn_pkg.cn_rec_err;
		END IF;

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Success Customer PO Number =>'|| p_cust_po_num);
                RETURN x_error_code;

     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Customer PO Number =>'|| p_cust_po_num || p_orig_sys_document_ref 
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => null	--p_cnv_hdr_rec.fob_point_code
		                  ,p_record_identifier_3 => null	--p_cnv_hdr_rec.fob_point_code||'-'||p_fob
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Customer PO Number is null =>'|| p_cust_po_num
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => null
		                  ,p_record_identifier_3 => null
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Customer PO Number =>'|| p_cust_po_num
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => null	
		                  ,p_record_identifier_3 => null	
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Customer PO Number ' || x_error_code);
               
		RETURN x_error_code;

      END is_cust_po_num_valid;
------------------- End Validation for Customer PO Number  --------------------------

-------------------  Validation for Sold To Org  --------------------------

FUNCTION is_sold_to_org_valid (p_sold_to_org	  IN  VARCHAR2
                             ,p_sold_to_org_id    IN OUT NOCOPY NUMBER
			     ,p_party_id          OUT NUMBER
			     ,p_organization_id   IN  NUMBER
			     ,p_orig_sys_document_ref IN VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_sold_to_org_valid: Sold To Org     => ' || p_sold_to_org);
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_sold_to_org_valid: organization_id => ' || p_organization_id);

                IF p_sold_to_org IS NOT NULL THEN			

			SELECT CUST_ACCOUNT_ID,
			       party_id
			INTO   p_sold_to_org_id,
			       p_party_id
			FROM HZ_CUST_ACCOUNTS 
			WHERE 1=1--orig_system_reference	= p_sold_to_org 
                          --AND account_number=p_sold_to_org  Modified on 28-FEB-2014
                          AND orig_system_reference = p_sold_to_org
			  AND status = 'A'; -- Legacy CUSTOMER_NUMBER
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Sold To Org: Success p_sold_to_org Id=>'||p_sold_to_org_id);
		END IF;
                RETURN x_error_code;
     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity	=> xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category		=> xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Sold To Org / InActive Customer =>'|| p_sold_to_org ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.sold_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.sold_to_org_id||'-'||p_sold_to_org_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Sold To Org / InActive Customer =>'||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.sold_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.sold_to_org_id||'-'||p_sold_to_org_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Sold To Org / InActive Customer =>'||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                   ,p_record_identifier_2 => p_cnv_hdr_rec.sold_to_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.sold_to_org_id||'-'||p_sold_to_org_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Sold To Org ' || x_error_code);
               
		RETURN x_error_code;

      END is_sold_to_org_valid;

------------------- End Validation for Sold To Org  ----------------------------------

-------------------  Validation for Customer Number  ---------------------------------
FUNCTION is_cust_no_valid (  p_cust_no			IN  OUT NOCOPY VARCHAR2                           
			    ,p_organization_id		IN  NUMBER
			    ,p_orig_sys_document_ref	IN  VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
     BEGIN
             --  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_sold_to_org_valid: Sold To Org     => ' || p_cust_no);
             --  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_sold_to_org_valid: organization_id => ' || p_organization_id);

                IF p_cust_no IS NOT NULL THEN

			SELECT account_number
			INTO   p_cust_no
			FROM  HZ_CUST_ACCOUNTS 
			WHERE 1=1 --orig_system_reference	= p_cust_no 
			  --AND account_number=p_cust_no  Modified on 28-FEB-2014
			  AND orig_system_reference = p_cust_no
			  AND status			= 'A';


                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header : '|| p_orig_sys_document_ref ||' Success Customer Number => '|| p_cust_no );
		END IF;
                RETURN x_error_code;
     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity	=> xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category		=> xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Legacy Customer Number =>'|| p_cust_no ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.customer_number
		                  ,p_record_identifier_3 => null
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Legacy Customer Number =>'|| p_cust_no ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.customer_number
		                  ,p_record_identifier_3 => null
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Legacy Customer Number =>'|| p_cust_no ||'-'||SQLERRM
		                  ,p_record_identifier_1  => p_cnv_hdr_rec.record_number
		                   ,p_record_identifier_2 => p_cnv_hdr_rec.customer_number
		                  ,p_record_identifier_3  => null
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Customer Number ' || x_error_code);
               
		RETURN x_error_code;

      END is_cust_no_valid;
------------------- End Validation for Customer Number  ------------------------------

-------------------  Validation for Ship To Customer Number  -------------------------

FUNCTION is_ship_cust_no_valid (p_ship_to_cust_no	IN OUT NOCOPY  VARCHAR2                            
			     ,p_organization_id		IN	       NUMBER
			     ,p_orig_sys_document_ref	IN	       VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
     BEGIN
              -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_sold_to_org_valid: Sold To Org     => ' || p_sold_to_org);
              -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_sold_to_org_valid: organization_id => ' || p_organization_id);

                IF p_ship_to_cust_no IS NOT NULL THEN			

			SELECT account_number
			INTO   p_ship_to_cust_no
			FROM  HZ_CUST_ACCOUNTS 
			WHERE 1=1 --orig_system_reference	= p_ship_to_cust_no
                          --AND account_number=p_ship_to_cust_no  Modified on 28-FEB-2014
                          AND orig_system_reference = p_ship_to_cust_no
			  AND status			= 'A'; -- Legacy CUSTOMER_NUMBER

                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header : '|| p_orig_sys_document_ref ||' Success Ship To Customer Number => '|| p_ship_to_cust_no );
		END IF;
                RETURN x_error_code;
     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity	=> xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category		=> xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Legacy Ship To Customer Number =>'|| p_ship_to_cust_no ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_to_customer_number
		                  ,p_record_identifier_3 => null
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Legacy Ship To Customer Number =>'|| p_ship_to_cust_no ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_to_customer_number
		                  ,p_record_identifier_3 => null
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity         => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category             => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text           => 'Header : '|| p_orig_sys_document_ref ||' Invalid Legacy Ship To Customer Number =>'|| p_ship_to_cust_no ||'-'||SQLERRM
		                  ,p_record_identifier_1  => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2  => p_cnv_hdr_rec.ship_to_customer_number
		                  ,p_record_identifier_3  => null
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Ship To Cust No ' || x_error_code);
               
		RETURN x_error_code;

      END is_ship_cust_no_valid;
------------------- End Validation for Ship To Customer Number  ----------------------
-------------------  Validation for Ship From Org  --------------------------
FUNCTION is_ship_from_org_valid (p_ship_from_org          IN OUT NOCOPY VARCHAR2
                                ,p_ship_from_org_id       IN OUT NOCOPY NUMBER
			        ,p_orig_sys_document_ref  IN VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_err_msg  	        VARCHAR2(100);
	 x_err_code		VARCHAR2(100);
	 x_organization_code    VARCHAR2(100);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ship_from_org_valid: Ship From Org => ' || p_ship_from_org);

             
	       IF p_ship_from_org IS NOT NULL THEN
                   SELECT mp.organization_id
			 INTO p_ship_from_org_id
			 FROM mtl_parameters mp			    
			WHERE 1 = 1
			AND mp.organization_code    = p_ship_from_org;		 
			--AND (process_enabled_flag = 'Y'
			--       OR x_organization_code='000'
			--      ) ;

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Ship From Org: Success p_ship_from_org_id => '|| p_ship_from_org_id);
		
		END IF;

                RETURN x_error_code;
     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity	=> xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category		=> xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Ship From Org =>'|| p_ship_from_org ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_from_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_from_org_id||'-'||p_ship_from_org_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Ship From Org =>'|| p_ship_from_org ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_from_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_from_org_id||'-'||p_ship_from_org_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Hdr Level x_err_code => '|| x_err_code);
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Hdr Level x_err_msg  => '|| x_err_msg);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Ship From Org =>'|| p_ship_from_org ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.ship_from_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_from_org_id||'-'||p_ship_from_org_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Ship From Org ' || x_error_code);
               
		RETURN x_error_code;

      END is_ship_from_org_valid;
------------------- End Validation for Ship From Org  --------------------------

-------------------  Validation for Sold From Org  --------------------------
FUNCTION is_sold_from_org_valid (p_sold_from_org  IN  VARCHAR2
                             ,p_sold_from_org_id  IN OUT NOCOPY NUMBER
			     ,p_orig_sys_document_ref IN VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_organization_name	VARCHAR2(100);
	 x_org_id		NUMBER;
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_sold_from_org_valid: Sold From Org =>'||p_orig_sys_document_ref ||'-'||p_sold_from_org);

               IF p_sold_from_org IS NOT NULL THEN
                SELECT organization_id
		INTO p_sold_from_org_id
		FROM hr_operating_units
		WHERE UPPER (NAME) = UPPER (p_sold_from_org);

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Sold From Org: Success p_sold_from_org_id =>'||p_sold_from_org_id);
		END IF;

                RETURN x_error_code;
     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity	=> xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category		=> xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Sold From Org =>'|| p_sold_from_org ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.sold_from_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.sold_from_org_id||'-'||p_sold_from_org_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Sold From Org => '|| p_sold_from_org ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.sold_from_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.sold_from_org_id||'-'||p_sold_from_org_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'Header : '|| p_orig_sys_document_ref ||' Invalid Sold From Org =>'|| p_sold_from_org ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.sold_from_org
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.sold_from_org_id||'-'||p_sold_from_org_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Sold From Org ' || x_error_code);
               
		RETURN x_error_code;

      END is_sold_from_org_valid;
------------------- End Validation for Sold From Org  --------------------------
-------------------  Validation for Booked Flag  --------------------------
FUNCTION is_booked_flag_valid (p_booked_flag IN OUT VARCHAR2 
				,p_orig_sys_document_ref IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);

     BEGIN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_booked_flag_valid : Booked Flag =>'||p_booked_flag);

                   IF p_booked_flag IS NULL
		   THEN
		      p_booked_flag := 'Y';
		   END IF;
                   IF (upper(p_booked_flag) NOT IN ('Y', 'N'))  --Modified as per Wave1 07-OCT-13
                   THEN
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Booked Flag, Booked Flag should be (Y)');
 	              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Invalid Booked Flag, Booked Flag should be (Y) or (N) =>'
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.booked_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.booked_flag||'-'||p_booked_flag
                               );
                   ELSE
		
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_booked_flag_valid : Success booked_flag =>'||p_booked_flag);

                   END IF;

                   RETURN x_error_code;
                EXCEPTION                  
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Booked Flag =>'|| p_booked_flag  ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.booked_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.booked_flag||'-'|| p_booked_flag
                               );

                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Booked Flag ' || x_error_code);
                        
			RETURN x_error_code;

      END is_booked_flag_valid;

------------------- End Validation for Booked Flag  --------------------------

-------------------  Validation for Cancelled Flag  --------------------------
FUNCTION is_cancelled_flag_valid (p_cancelled_flag IN VARCHAR2 
				,p_orig_sys_document_ref IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);

     BEGIN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_cancelled_flag_valid : Cancelled Flag =>'||p_cancelled_flag);


                   IF (upper(p_cancelled_flag) NOT IN ('N'))
                   THEN
                      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Cancelled Flag, Cancelled Flag should be (N)');
 	              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Cancelled Flag =>'|| p_cancelled_flag  ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.cancelled_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.cancelled_flag||'-'|| p_cancelled_flag
                               );
                   ELSE
		
			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_cancelled_flag_valid : Success cancelled_flag =>'||p_cancelled_flag);

                   END IF;

                   RETURN x_error_code;

                EXCEPTION

                  
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Cancelled Flag =>'|| p_cancelled_flag  ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_hdr_rec.cancelled_flag
			                  ,p_record_identifier_3 => p_cnv_hdr_rec.cancelled_flag||'-'||p_cancelled_flag
                               );

                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Cancelled Flag ' || x_error_code);
                        
			RETURN x_error_code;

      END is_cancelled_flag_valid;
------------------- End Validation for Cancelled Flag  --------------------------
-------------------  Validation for Hold Type Code--------------------------

FUNCTION is_hold_type_code_valid (p_hold_type_code	IN  OUT NOCOPY VARCHAR2
				, p_hold_id	        IN  OUT NOCOPY NUMBER
				, p_orig_sys_document_ref	IN VARCHAR2
				) RETURN NUMBER 
IS
 
	 x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
BEGIN     
   IF p_hold_type_code IS NOT NULL
   THEN
     IF UPPER(p_hold_type_code) = 'H' Then  --Added upper as per Wave1
        p_hold_type_code     := xx_oe_sales_order_conv_pkg.G_HOLD_TYPE_H;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_hold_type_code_valid : Success Hold Type Code =>'||p_hold_type_code);
	SELECT hold_id
       	  INTO p_cnv_hdr_rec.hold_id
          FROM oe_hold_definitions 
	 WHERE 1=1
	   AND Name = p_hold_type_code
	   And Type_Code = 'CREDIT'
	   AND end_date_active IS NULL; 	             
	 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_hold_type_code_valid : Success Hold Id =>'||p_hold_id);
      ELSE
	 p_hold_type_code     := xx_oe_sales_order_conv_pkg.G_HOLD_TYPE_ABC;
         SELECT hold_id
       	   INTO p_cnv_hdr_rec.hold_id
           FROM Oe_Hold_Definitions 
	  WHERE 1=1
	    AND Name = p_hold_type_code
	    AND Type_Code = 'HOLD'
	    AND end_date_active IS NULL; 
      END IF;
   END IF;
   RETURN x_error_code;
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
                       ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
	               ,p_error_text  => 'Header : '|| p_orig_sys_document_ref ||' Invalid Hold Type Code =>'|| p_hold_type_code  ||'-'||SQLERRM
	               ,p_record_identifier_1 =>  p_cnv_hdr_rec.record_number
	               -- ,p_record_identifier_2 => p_cnv_hdr_rec.status
	               ,p_record_identifier_3 => p_cnv_hdr_rec.hold_type_code||'-'|| p_hold_type_code
                       );
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE  Hold Type Code ' || x_error_code);                    
    RETURN x_error_code;
END is_hold_type_code_valid;
--Deliver To Address Validation 16-AUG-12 Added to check for deliver to address
FUNCTION is_deliver_to_valid ( p_cnv_hdr_rec IN OUT xx_oe_sales_order_conv_pkg.G_XX_SO_CNV_PRE_STD_REC_TYPE )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_cust_po_num  	VARCHAR2(40);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_deliver_to_valid');
               
          IF p_cnv_hdr_rec.order_type = xx_oe_sales_order_conv_pkg.G_RMA_ORDER_TYPE THEN
             p_cnv_hdr_rec.deliver_to_org_id := NULL;
          ELSE             
             IF p_cnv_hdr_rec.sold_to_org_id IS NOT NULL AND p_cnv_hdr_rec.org_id IS NOT NULL THEN
                IF p_cnv_hdr_rec.deliver_to_address1 IS NOT NULL OR p_cnv_hdr_rec.deliver_to_address2 IS NOT NULL
		      OR p_cnv_hdr_rec.deliver_to_address3 IS NOT NULL OR p_cnv_hdr_rec.deliver_to_address4 IS NOT NULL
		      OR p_cnv_hdr_rec.deliver_to_city IS NOT NULL OR p_cnv_hdr_rec.deliver_to_state IS NOT NULL
		      OR p_cnv_hdr_rec.deliver_to_postal_code IS NOT NULL OR p_cnv_hdr_rec.deliver_to_county IS NOT NULL
		      OR p_cnv_hdr_rec.deliver_to_country IS NOT NULL
		THEN		   
		   IF p_cnv_hdr_rec.deliver_to_address1 IS NULL THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Deliver to Address1 is NULL');
		         x_error_code := xx_emf_cn_pkg.cn_rec_err;
			 xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Invalid : Deliver to Address1 is NULL =>'
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_document_ref
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_type
                                    );			
	           END IF;
	           IF p_cnv_hdr_rec.deliver_to_country IS NULL THEN
	               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Deliver to Country is NULL');
	               x_error_code := xx_emf_cn_pkg.cn_rec_err;
	               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		       		        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		       		        ,p_error_text  => 'Invalid : Deliver to Country is NULL =>'
		       		        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		       		        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_document_ref
		       		        ,p_record_identifier_3 => p_cnv_hdr_rec.order_type
		                         );			
	           END IF; --null check
		END IF;  --not null check
             END IF;  --sold to check          
          END IF; --order type check
                
                RETURN x_error_code;

     EXCEPTION
           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_cnv_hdr_rec.orig_sys_document_ref ||' Invalid Delivery to Address =>'|| 'Exception'
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_document_ref	
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.order_type	
                      );               
               
		RETURN x_error_code;

      END is_deliver_to_valid;
--Added as per TDR 30-OCT-12 Validation for shipment_priority_code      
FUNCTION is_ship_priority_code_valid ( p_ship_priority_code     IN OUT VARCHAR2
                                      ,p_ship_to_org_id         IN     VARCHAR2
				      ,p_orig_sys_document_ref	IN     VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
	 x_ship_priority_code	VARCHAR2 (50);
	 x_attr3                VARCHAR2(50);
	 x_old_value2           VARCHAR2(50);
     BEGIN               
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ship_priority_code_valid: p_ship_priority_code =>'||p_ship_priority_code);

         SELECT hcas.attribute3
	   INTO x_attr3
           FROM hz_cust_accounts hca,
                hz_party_sites hps,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsu
          WHERE hca.party_id=hps.party_id
            AND hcas.cust_account_id=hca.cust_account_id
            AND hcas.party_site_id=hps.party_site_id
            AND hcsu.cust_acct_site_id=hcas.cust_acct_site_id
            AND hcsu.site_use_code='SHIP_TO'		    
	    AND hcsu.status='A'
	    AND hca.status='A'
            AND hcas.org_id=hcsu.org_id
            AND hcsu.site_use_id = p_ship_to_org_id;                        
         
         IF x_attr3 IS NULL OR x_attr3 = 'Domestic' THEN 
            x_old_value2 := 'Domestic';
         ELSIF x_attr3 = 'International' THEN
            x_old_value2 := 'International';
         END IF;
         
         x_ship_priority_code :=
            xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'SHIPMENT_PRIORITY_CODE'                                                  
                                                  ,p_old_value1 => p_ship_priority_code
                                                  ,p_old_value2 => x_old_value2
                                                  ,p_date_effective => SYSDATE
                                                 );	
         SELECT   lookup_code  --meaning  Modified on 21-JAN-13
	   INTO   p_ship_priority_code
  	   FROM   fnd_lookup_values
  	  WHERE  UPPER(lookup_code) = UPPER(x_ship_priority_code)  --Modified as per Wave1 file
  	    --meaning = x_ship_priority_code
  	    AND  lookup_type =  'SHIPMENT_PRIORITY' 
  	    AND  enabled_flag = 'Y'
	    AND  language  = 'US'
	    AND  nvl(end_date_active,SYSDATE)>=SYSDATE;  	              
         
         RETURN x_error_code;

     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipment Priority Code =>'|| p_ship_priority_code ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.shipment_priority_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.shipment_priority_code||'-'||p_ship_priority_code
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipment Priority Code =>'|| p_ship_priority_code || xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.shipment_priority_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.shipment_priority_code||'-'||p_ship_priority_code
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipment Priority Code =>'|| p_ship_priority_code ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                 ,p_record_identifier_2 => p_cnv_hdr_rec.shipment_priority_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.shipment_priority_code||'-'||p_ship_priority_code
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Shipment Priority Code ' || x_error_code);
               
		RETURN x_error_code;

      END is_ship_priority_code_valid;
   --Added as per Wave1 09-NOV-13
   -------------------  Validation for Shipping Method Code assignment to org  ---------------------------------------------
   FUNCTION is_ship_method_asgn_valid ( p_ship_method_code  IN  VARCHAR2,
                                           p_ship_from_org_id  IN  NUMBER,
				           p_orig_sys_document_ref	IN VARCHAR2
			                 )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;         
	 x_ship_method_code	VARCHAR2 (50);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ship_method_asgn_valid: =>'||p_ship_method_code);
                                                              
         SELECT wcs.ship_method_code
           INTO x_ship_method_code
           FROM wsh_carrier_services_v wcs
               ,wsh_org_carrier_services_v wocs
          WHERE wcs.carrier_service_id = wocs.carrier_service_id
            AND wocs.enabled_flag = 'Y'
            AND wocs.organization_id = p_ship_from_org_id
            AND UPPER(wcs.ship_method_code) = UPPER(p_ship_method_code);
             
         RETURN x_error_code;

     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipping Method Code Assignment to Ship From Org =>'|| p_ship_method_code ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.shipping_method_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_from_org
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipping Method Code Assignment to Ship From Org =>'|| p_ship_method_code || xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_hdr_rec.shipping_method_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_from_org
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Shipping Method Code Assignment to Ship From Org =>'|| p_ship_method_code ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		                 ,p_record_identifier_2 => p_cnv_hdr_rec.shipping_method_code
		                  ,p_record_identifier_3 => p_cnv_hdr_rec.ship_from_org
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Shipping Method Code ' || x_error_code);
               
	       RETURN x_error_code;

      END is_ship_method_asgn_valid;      
            
------------------- End Validation for Hold Type Code--------------------------

      --- Start of the main function perform_batch_validations
      --- This will only have calls to the individual functions.
      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

	 x_error_code_temp := is_orig_sys_doc_ref_null(p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 x_error_code_temp := is_organization_valid(p_cnv_hdr_rec.org_code
	  	                                    ,p_cnv_hdr_rec.org_id
						    ,p_cnv_hdr_rec.orig_sys_document_ref);
         x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 --Validate Order Type, Category Code, Invoice Rule and Accounting Rule
	 x_error_code_temp := is_order_type_valid (p_cnv_hdr_rec.org_code
	                                           ,p_cnv_hdr_rec.order_type
		                                   ,p_cnv_hdr_rec.order_type_id
						   ,p_cnv_hdr_rec.order_category
						   ,p_cnv_hdr_rec.invoicing_rule_id
						   ,p_cnv_hdr_rec.accounting_rule_id
		                                   ,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 
	 x_error_code_temp := is_order_source_valid(p_cnv_hdr_rec.order_source
		                                         ,p_cnv_hdr_rec.order_source_id
		                                         ,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 
	 x_error_code_temp := is_price_list_valid(p_cnv_hdr_rec.price_list
		                                         ,p_cnv_hdr_rec.price_list_id
		                                         ,p_cnv_hdr_rec.org_id
							 ,p_cnv_hdr_rec.order_type_id
							 ,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
         --
         x_error_code_temp := is_cust_billto_site_valid (p_cnv_hdr_rec.customer_number                                                        
	                                                ,p_cnv_hdr_rec.bill_to_customer_number
	                                                ,p_cnv_hdr_rec.invoice_to_org            --Added as per Wave1
                                                        ,p_cnv_hdr_rec.invoice_to_org_id
			                                ,p_cnv_hdr_rec.org_id
			                                ,p_cnv_hdr_rec.orig_sys_document_ref
							);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
         --Modified as per Change Request
	 x_error_code_temp := is_cust_shipto_site_valid (p_cnv_hdr_rec.ship_to_customer_number  --p_cnv_hdr_rec.customer_number
	                                                ,p_cnv_hdr_rec.orig_ship_address_ref  
                                                        ,p_cnv_hdr_rec.ship_to_org_id
			                                ,p_cnv_hdr_rec.org_id
			                                ,p_cnv_hdr_rec.orig_sys_document_ref
							);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
         --
	 x_error_code_temp := is_ship_from_org_valid (p_cnv_hdr_rec.ship_from_org
                                                     ,p_cnv_hdr_rec.ship_from_org_id
			                             ,p_cnv_hdr_rec.orig_sys_document_ref);
      	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);


         x_error_code_temp := is_ship_method_code_valid(p_cnv_hdr_rec.customer_number
	                                                ,p_cnv_hdr_rec.shipping_method_code	                                               
							,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp); 
	 --Added as per Wave1 09-NOV-13
	 IF p_cnv_hdr_rec.shipping_method_code IS NOT NULL AND p_cnv_hdr_rec.ship_from_org_id IS NOT NULL THEN
	    x_error_code_temp := is_ship_method_asgn_valid(p_cnv_hdr_rec.shipping_method_code	
	                                                        ,p_cnv_hdr_rec.ship_from_org_id
	    							,p_cnv_hdr_rec.orig_sys_document_ref);
	    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp); 
	 END IF;

	 x_error_code_temp := is_currency_code_valid(p_cnv_hdr_rec.transactional_curr_code
						     ,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
        -- fnd_file.put_line(fnd_file.log,' After calling is_currency_code_valid x_error_code_temp => ' || x_error_code_temp);

         x_error_code_temp := is_tax_exempt_flag_valid (p_cnv_hdr_rec.tax_exempt_flag
							,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
         --fnd_file.put_line(fnd_file.log,' After calling is_tax_exempt_flag_valid x_error_code_temp => ' || x_error_code_temp);

	 
	 x_error_code_temp := is_payment_term_valid(p_cnv_hdr_rec.org_code
	                                           ,p_cnv_hdr_rec.payment_term
		                                   ,p_cnv_hdr_rec.payment_term_id
					           ,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
         fnd_file.put_line(fnd_file.log,' After calling is_payment_term_valid x_error_code_temp => ' || x_error_code_temp);
         fnd_file.put_line(fnd_file.log,' Before calling is_freight_term_valid ');        
         x_error_code_temp := is_freight_term_valid (p_cnv_hdr_rec.freight_terms_code
				                    ,p_cnv_hdr_rec.ship_to_customer_number
				                    ,p_cnv_hdr_rec.orig_sys_document_ref);
         x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);                                              
         fnd_file.put_line(fnd_file.log,' After calling is_freight_term_valid x_error_code_temp => ' || x_error_code_temp);        
	 x_error_code_temp := is_FOB_valid(p_cnv_hdr_rec.fob_point_code
                                    , p_cnv_hdr_rec.ship_to_customer_number
					  ,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 fnd_file.put_line(fnd_file.log,' FOB POINT error code : '||x_error_code);

	 x_error_code_temp := is_cust_po_num_valid(p_cnv_hdr_rec.customer_po_number
						,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 
	 x_error_code_temp := is_sold_to_org_valid (--p_cnv_hdr_rec.sold_to_org
                                               --p_cnv_hdr_rec.ship_to_customer_number
                                                p_cnv_hdr_rec.customer_number  --Modified as per Wave1
		                               ,p_cnv_hdr_rec.sold_to_org_id
					       ,p_cnv_hdr_rec.new_party_id
		                               ,p_cnv_hdr_rec.org_id
					       ,p_cnv_hdr_rec.orig_sys_document_ref);

	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

         fnd_file.put_line(fnd_file.log,' After calling is_sold_to_org_valid x_error_code_temp => ' || x_error_code_temp);

	 x_error_code_temp := is_cust_no_valid (p_cnv_hdr_rec.customer_number
		                              -- ,p_cnv_hdr_rec.sold_to_org_id
		                               ,p_cnv_hdr_rec.org_id
					       ,p_cnv_hdr_rec.orig_sys_document_ref);

	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 x_error_code_temp := is_ship_cust_no_valid (p_cnv_hdr_rec.SHIP_TO_CUSTOMER_NUMBER
		                             --  ,p_cnv_hdr_rec.sold_to_org_id
		                               ,p_cnv_hdr_rec.org_id
					       ,p_cnv_hdr_rec.orig_sys_document_ref);

	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);


         x_error_code_temp := is_sold_from_org_valid(p_cnv_hdr_rec.sold_from_org
		                               ,p_cnv_hdr_rec.sold_from_org_id
					       ,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 x_error_code_temp := is_booked_flag_valid (p_cnv_hdr_rec.booked_flag
						,p_cnv_hdr_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 x_error_code_temp := is_hold_type_code_valid (p_cnv_hdr_rec.hold_type_code
							,p_cnv_hdr_rec.hold_id
							,p_cnv_hdr_rec.orig_sys_document_ref);							         					
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 
	 --16-AUG-12 Added to check for deliver to address
	 x_error_code_temp := is_deliver_to_valid (p_cnv_hdr_rec);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 
	 --Added as per TDR 30-OCT-12
	 IF p_cnv_hdr_rec.shipment_priority_code IS NOT NULL AND p_cnv_hdr_rec.ship_to_org_id IS NOT NULL THEN
	    x_error_code_temp := is_ship_priority_code_valid( p_cnv_hdr_rec.shipment_priority_code
	                                                     ,p_cnv_hdr_rec.ship_to_org_id
	                                                     ,p_cnv_hdr_rec.orig_sys_document_ref);
	    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp); 
	 END IF;

	 RETURN x_error_code;
     EXCEPTION
        WHEN xx_emf_pkg.G_E_REC_ERROR THEN
      	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                RETURN x_error_code;
      	WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
      		x_error_code := xx_emf_cn_pkg.cn_rec_err;
      		RETURN x_error_code;
      	WHEN OTHERS THEN
      	     x_error_code := xx_emf_cn_pkg.cn_rec_err;
      	        RETURN x_error_code;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Data-Validations');

  END data_validations;

  ----- End Order Header Level Data Validations ----------------------------------------------------
  ----- Order Line Level Data Validations ----------------------------------------------------------
    
  FUNCTION data_validations_line(p_cnv_line_rec IN OUT xx_oe_sales_order_conv_pkg.G_XX_SO_LINE_PRE_STD_REC_TYPE )
      RETURN NUMBER
    IS
	 x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
	 x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

	--- Local functions for all batch level validations

FUNCTION is_linetype_valid ( p_sold_from_org	     IN		   VARCHAR2
                            ,p_line_type             IN OUT	   VARCHAR2
                            ,p_line_type_id          IN OUT NOCOPY NUMBER
			    ,p_invoicing_rule_id     OUT           NUMBER
                            ,p_accounting_rule_id    OUT           NUMBER
			    ,p_orig_sys_document_ref IN		   VARCHAR2
			    ,p_orig_sys_line_ref     IN            VARCHAR2	
                            )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		NUMBER;
	 x_line_type		VARCHAR2(60);
      BEGIN
                
               -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_linetype_valid: Line Type => '|| p_line_type);

		IF p_line_type IS NOT NULL THEN	
		    SELECT otta.transaction_type_id,
                           otta.invoicing_rule_id,
                           otta.accounting_rule_id
		      INTO p_line_type_id,
                           p_invoicing_rule_id,
                           p_accounting_rule_id
		      FROM oe_transaction_types_tl ott,
		           oe_transaction_types_all otta
		     WHERE UPPER(ott.NAME) = UPPER(p_line_type)  --Added upper as per Wave1
		      AND ott.transaction_type_id=otta.transaction_type_id
		      AND ott.LANGUAGE = USERENV ('LANG');

			    --p_line_type := x_line_type;

			xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'HDR : '|| p_orig_sys_document_ref ||'LINE : '|| p_orig_sys_line_ref ||'Organization Code : '|| p_sold_from_org ||' Order Line Type : '|| x_line_type || ' Line Type Id : '|| p_line_type_id);
		ELSE		
			xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_LOW
					 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
					 ,p_error_text  => 'HDR '|| p_orig_sys_document_ref ||'LINE : '|| p_orig_sys_line_ref ||' Organization Code : '|| p_sold_from_org ||' Invalid : Line Type is NULL: Header may not be available => '|| p_line_type ||'-'||xx_emf_cn_pkg.CN_NO_DATA
					 ,p_record_identifier_1 => p_cnv_line_rec.record_number
					 ,p_record_identifier_2 => p_line_type
					 ,p_record_identifier_3 => p_cnv_line_rec.line_type
			      );
			--x_error_code := xx_emf_cn_pkg.CN_REC_ERR;

		END IF;                    
                    RETURN x_error_code;
                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Organization Code : '|| p_sold_from_org ||' Invalid Line Type => '|| p_line_type ||'-'|| xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			                  ,p_record_identifier_2 => p_line_type
			                  ,p_record_identifier_3 => p_cnv_line_rec.line_type
                               );
	                 RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Organization Code : '|| p_sold_from_org ||' Invalid Line Type => '|| p_line_type ||'-'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			                     ,p_record_identifier_2 => p_line_type
			                  ,p_record_identifier_3 => p_cnv_line_rec.line_type
                               );

			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Order Line Type ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Organization Code : '|| p_sold_from_org ||' Invalid Line Type => '|| p_line_type ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			                     ,p_record_identifier_2 => p_line_type
			                  ,p_record_identifier_3 => p_cnv_line_rec.line_type
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Organization ' || x_error_code);
                        RETURN x_error_code;
      END is_linetype_valid;

----------------------validation for Item-----------------------------
FUNCTION is_inv_item_valid (p_inventory_item		IN OUT NOCOPY VARCHAR2
                           ,p_item_type_code		IN	VARCHAR2
			   ,p_inventory_item_id		IN OUT NOCOPY VARCHAR2			   
			   ,p_orig_sys_document_ref	IN	VARCHAR2
			   ,p_orig_sys_line_ref         IN      VARCHAR2
			   ,p_ship_from_org_id		IN	NUMBER)
         RETURN NUMBER
      IS
         x_error_code      NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable        VARCHAR2 (40);
	 l_valid	   NUMBER;
	 x_order_type      VARCHAR2(100);
	 x_legacy_item     VARCHAR2(100);
     BEGIN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Is_item_number_valid: ' || p_inventory_item);
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Ship From Org ' || p_ship_from_org_id);
        x_legacy_item := p_inventory_item;      
        --
	SELECT distinct msi.inventory_item_id, msi.segment1
          INTO p_inventory_item_id , p_inventory_item
          FROM mtl_system_items_b msi
         WHERE msi.organization_id = p_ship_from_org_id --FND_PROFILE.VALUE('MSD_MASTER_ORG')
           AND msi.segment1      = p_inventory_item;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Success  Inv Item => ' || p_inventory_item || 'Item Id : '|| p_inventory_item_id);
        RETURN x_error_code;
    EXCEPTION
       WHEN TOO_MANY_ROWS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid legacy item number => '|| x_legacy_item ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			                 -- ,p_record_identifier_2 => p_cnv_line_rec.org_code
			                  ,p_record_identifier_3 => p_cnv_line_rec.item_type_code
                               );
		         RETURN x_error_code;
                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid legacy item number => '|| x_legacy_item ||'-'|| xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			               --   ,p_record_identifier_2 => p_cnv_line_rec.org_code
			                  ,p_record_identifier_3 => p_cnv_line_rec.item_type_code
                               );
			 RETURN x_error_code;
                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid legacy item number => '|| x_legacy_item ||'-'|| SQLERRM
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			                 -- ,p_record_identifier_2 => p_cnv_line_rec.org_code
			                  ,p_record_identifier_3 => p_cnv_line_rec.item_type_code
                               );
                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE legacy item number ' || x_error_code);
                        RETURN x_error_code;
      END is_inv_item_valid;

-------------------validation for Order Source------------------------------------------
FUNCTION is_ordered_qty_valid (p_ordered_quantity	IN  OUT NUMBER
                             ,p_shipped_quantity	IN  OUT NUMBER
			     ,p_pricing_quantity	IN  OUT NUMBER
			     ,p_orig_sys_document_ref	IN	VARCHAR2
			     ,p_orig_sys_line_ref       IN      VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
     BEGIN
                    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ordered_qty_valid : Order Qty =>'||p_ordered_quantity);
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ordered_qty_valid : Shipped Qty =>'||p_shipped_quantity);

          
                    p_ordered_quantity :=  nvl(p_ordered_quantity,0) - nvl(p_shipped_quantity,0) ;
		    p_pricing_quantity :=  nvl(p_ordered_quantity,0) - nvl(p_shipped_quantity,0) ;

		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_ordered_quantity => '|| p_ordered_quantity);
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_pricing_quantity => '|| p_pricing_quantity);

                   RETURN x_error_code;
                EXCEPTION
                    WHEN TOO_MANY_ROWS THEN
		         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Ordered Qty and Ship Qty => ' ||'-'|| xx_emf_cn_pkg.CN_TOO_MANY
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_line_rec.ordered_quantity
			                  ,p_record_identifier_3 => p_cnv_line_rec.shipped_quantity||'-'||p_shipped_quantity
                               );
                         RETURN x_error_code;

                    WHEN NO_DATA_FOUND THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Ordered Qty and Ship Qty => ' ||'-'||xx_emf_cn_pkg.CN_NO_DATA
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			                  ,p_record_identifier_2 => p_cnv_line_rec.ordered_quantity
			                  ,p_record_identifier_3 => p_cnv_line_rec.shipped_quantity||'-'||p_shipped_quantity
                               );
			 RETURN x_error_code;

                    WHEN OTHERS THEN
	                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	                 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		         xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
			                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Ordered Qty and Ship Qty => ' ||'-'||SQLERRM
			                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
			               ,p_record_identifier_2 => p_cnv_line_rec.ordered_quantity
			                  ,p_record_identifier_3 => p_cnv_line_rec.shipped_quantity||'-'||p_shipped_quantity
                               );

                        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Ordered Qty / Shipped Qty ' || x_error_code);
                        
			RETURN x_error_code;

      END is_ordered_qty_valid;
-------------------End - validation for Order Quantity ----------------------------------------------------

------------------- validation for Pricing Quantity UOM ---------------------------------------------------

FUNCTION is_price_qty_uom_valid (p_order_qty_uom         IN OUT VARCHAR2
                                ,p_pricing_qty_uom	 IN OUT	VARCHAR2
				,p_shipping_qty_uom	 IN OUT	VARCHAR2
				,p_inventory_item_id     IN     NUMBER--Added by Samir on 23-Jul-2012
				,p_organization_id       IN     NUMBER--Added by Samir on 23-Jul-2012
				,p_orig_sys_document_ref IN	VARCHAR2
				,p_orig_sys_line_ref     IN     VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 l_valid		NUMBER;
	 x_price_qty_uom	VARCHAR2(10);
	 x_order_qty_uom	VARCHAR2(10);
	 x_shipping_qty_uom	VARCHAR2(10);
	 x_legacy_ord_uom	VARCHAR2(10);
	 x_legacy_pricing_uom	VARCHAR2(10);

     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_price_qty_uom_valid: Order Qty UOM   => '|| p_order_qty_uom);
	       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_price_qty_uom_valid: Pricing Qty UOM => '|| p_pricing_qty_uom);

	       x_legacy_ord_uom     :=  p_order_qty_uom ;
               x_legacy_pricing_uom :=  p_pricing_qty_uom;

	       
	       /*IF p_order_qty_uom IS NOT NULL THEN

	       x_order_qty_uom := XX_INTG_COMMON_PKG.get_mapping_value(p_mapping_type  => 'UOM_NAME'
                                                                   ,p_source         => NULL
                                                                     ,p_old_value      => p_order_qty_uom
                                                                     ,p_date_effective => sysdate);*/ --Commented by Samir on 23-Jul-2012
                                                                     
               --Modified as per Wave1  
               BEGIN
                  SELECT uom_code
                    INTO x_order_qty_uom
                    FROM mtl_units_of_measure
                   WHERE UPPER(uom_code) = UPPER(p_order_qty_uom)
                     AND language = 'US';
               EXCEPTION 
                  WHEN OTHERS THEN
                  --Added by Samir on 23-Jul-2012
                   SELECT primary_uom_code
		     INTO x_order_qty_uom
		     FROM mtl_system_items_b
		    WHERE inventory_item_id=p_inventory_item_id 
		      AND organization_id=p_organization_id;
		END;
                p_order_qty_uom := x_order_qty_uom;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'HDR '|| p_orig_sys_document_ref ||'LINE : '|| p_orig_sys_line_ref ||' Order Qty UOM => '|| p_order_qty_uom);
		--END IF;
	       
	       
	       IF p_pricing_qty_uom IS NOT NULL THEN

	         /*x_price_qty_uom := XX_INTG_COMMON_PKG.get_mapping_value(p_mapping_type  => 'UOM_NAME'
                                                                   ,p_source        =>  NULL
                                                                     ,p_old_value     =>  p_pricing_qty_uom
                                                                     ,p_date_effective => sysdate);
                

                p_pricing_qty_uom := x_price_qty_uom;*/--Commented by Samir on 23-Jul-2012
                --Added by Samir on 23-Jul-2012
                  --Modified as per Wave1
                  BEGIN
                     SELECT uom_code
                       INTO x_price_qty_uom
                       FROM mtl_units_of_measure
                      WHERE UPPER(uom_code) = UPPER(p_pricing_qty_uom)
                        AND language = 'US';
                     p_pricing_qty_uom := x_price_qty_uom;
                  EXCEPTION 
                     WHEN OTHERS THEN
                     p_pricing_qty_uom := x_order_qty_uom;                  
                  END;
                
		--p_pricing_qty_uom := x_order_qty_uom;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'HDR '|| p_orig_sys_document_ref ||'LINE : '|| p_orig_sys_line_ref ||' Pricing Qty UOM => '|| p_pricing_qty_uom);
		END IF;

		IF p_shipping_qty_uom IS NOT NULL THEN

	         /*x_price_qty_uom := XX_INTG_COMMON_PKG.get_mapping_value(p_mapping_type  => 'UOM_NAME'
                                                                   ,p_source        =>  NULL
                                                                     ,p_old_value     =>  p_shipping_qty_uom
                                                                     ,p_date_effective => sysdate);


                 p_shipping_qty_uom := x_price_qty_uom;*/--Commented by Samir on 23-Jul-2012
                  --Modified as per Wave1
                  BEGIN
                     SELECT uom_code
                       INTO x_shipping_qty_uom
                       FROM mtl_units_of_measure
                      WHERE UPPER(uom_code) = UPPER(p_shipping_qty_uom)
                        AND language = 'US';
                     p_shipping_qty_uom := x_shipping_qty_uom;
                  EXCEPTION 
                     WHEN OTHERS THEN
                     p_shipping_qty_uom := x_order_qty_uom;                  
                  END;
                 
                --Added by Samir on 23-Jul-2012
		 --p_shipping_qty_uom := x_order_qty_uom;
                 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'HDR '|| p_orig_sys_document_ref ||'LINE : '|| p_orig_sys_line_ref ||' Shipping Qty UOM => '|| p_shipping_qty_uom);
		END IF;

                RETURN x_error_code;
     EXCEPTION

           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Order Qty UOM => '|| x_legacy_ord_uom ||' Invalid Pricing Qty UOM => '||x_legacy_pricing_uom || ' Invalid Shipping Qty UOM => ' || p_shipping_qty_uom ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.pricing_quantity_uom
		                  ,p_record_identifier_3 => p_cnv_line_rec.pricing_quantity_uom||'-'||p_pricing_qty_uom
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Order Qty UOM => '|| x_legacy_ord_uom ||' Invalid Pricing Qty UOM => ' || x_legacy_pricing_uom|| ' Invalid Shipping Qty UOM => ' || p_shipping_qty_uom ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.pricing_quantity_uom
		                  ,p_record_identifier_3 => p_cnv_line_rec.pricing_quantity_uom||'-'||p_pricing_qty_uom
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Order Qty UOM => '|| x_legacy_ord_uom ||' Invalid Pricing Qty UOM => '|| x_legacy_pricing_uom|| ' Invalid Shipping Qty UOM => ' || p_shipping_qty_uom ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.pricing_quantity_uom
		                  ,p_record_identifier_3 => p_cnv_line_rec.pricing_quantity_uom||'-'||p_pricing_qty_uom
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Pricing Qty UOM' || x_error_code);
               
		RETURN x_error_code;

      END is_price_qty_uom_valid;

------------------- End validation for Pricing Qty UOM ------------------------------------------
------------------- validation for Price List ---------------------------------------------------

FUNCTION is_price_list_valid (p_price_list		IN  VARCHAR2
                             ,p_pricelist_id		OUT NUMBER
			     ,p_orig_sys_document_ref	IN  VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
	 l_valid	NUMBER;
	 x_price_list	VARCHAR2(100);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_price_list_valid: Price List => '|| p_price_list);

               IF p_price_list IS NOT NULL THEN
	       
		SELECT list_header_id 
		INTO  p_pricelist_id
		FROM apps.qp_list_headers 
		WHERE 1=1
		AND UPPER(name)       = UPPER(p_price_list);  --Added upper as per Wave1

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Header : '|| p_orig_sys_document_ref ||' Price List => '|| x_price_list || ' Price_List_id => ' || p_pricelist_id);
                END IF;
                RETURN x_error_code;

     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Price List => '|| p_price_list ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.price_list
		                  ,p_record_identifier_3 => p_cnv_line_rec.price_list_id||'-'||p_pricelist_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Price List => '|| p_price_list ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.price_list
		                  ,p_record_identifier_3 => p_cnv_line_rec.price_list_id||'-'||p_pricelist_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Header : '|| p_orig_sys_document_ref||' Invalid Price List => '|| p_price_list ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.price_list
		                  ,p_record_identifier_3 => p_cnv_line_rec.price_list_id||'-'||p_pricelist_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Price List ' || x_error_code);
               
		RETURN x_error_code;

      END is_price_list_valid;
------------------- End validation for Price List ------------------------------------------
-------------------  Validation for Ship From Org  --------------------------------------------------
FUNCTION is_ship_from_org_valid (p_ship_from_org	 IN	VARCHAR2
                                 ,p_ship_from_org_id     IN	OUT NOCOPY NUMBER
			        ,p_orig_sys_document_ref IN	VARCHAR2
				,p_orig_sys_line_ref     IN     VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
	 x_err_msg	        VARCHAR2(100);
	 x_err_code		VARCHAR2(100);
	 x_organization_code    VARCHAR2(100);
     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_ship_from_org_valid: Ship From Org =>'||p_ship_from_org);

              IF p_ship_from_org IS NOT NULL THEN

             
		 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Line Level x_organization_code => '|| x_organization_code);
		  SELECT mp.organization_id
			 INTO p_ship_from_org_id
			 FROM mtl_parameters mp			    
			WHERE 1 = 1
			AND mp.organization_code    = p_ship_from_org			 ;
			--AND (process_enabled_flag = 'Y'
			--       OR x_organization_code='000'
			--      ) ;

                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'HDR '|| p_orig_sys_document_ref ||'LINE : '|| p_orig_sys_line_ref ||' Success Ship From Org Id => '|| p_ship_from_org_id);

		END IF;
                RETURN x_error_code;
     EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
	  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	  xx_emf_pkg.error (p_severity	=> xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category		=> xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Ship From Org => '|| p_ship_from_org ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.ship_from_org
		                  ,p_record_identifier_3 => p_cnv_line_rec.ship_from_org_id||'-'||p_ship_from_org_id
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Ship From Org => '|| p_ship_from_org ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.ship_from_org
		                  ,p_record_identifier_3 => p_cnv_line_rec.ship_from_org_id||'-'||p_ship_from_org_id
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'HDR :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Ship From Org => '|| p_ship_from_org||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.ship_from_org
		                  ,p_record_identifier_3 => p_cnv_line_rec.ship_from_org_id||'-'||p_ship_from_org_id
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Ship From Org ' || x_error_code);
               
		RETURN x_error_code;

      END is_ship_from_org_valid;
     --Validation for calculate_price_flag added as per Wave1 23-OCT-13
     FUNCTION is_calc_price_flag_valid (p_calc_price_flag IN OUT VARCHAR2
                                        )
     RETURN NUMBER
     IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
     BEGIN
        IF (upper(p_calc_price_flag) != 'P')
        THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid Calculate Price Flag: '||p_calc_price_flag);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
			    ,p_error_text  => 'Invalid CALCULATE_PRICE_FLAG =>'||p_calc_price_flag
			    ,p_record_identifier_1 => p_cnv_line_rec.record_number
			    ,p_record_identifier_2 => p_cnv_line_rec.calculate_price_flag
			    ,p_record_identifier_3 => p_calc_price_flag
                            );
       END IF;
       p_calc_price_flag := UPPER(p_calc_price_flag);
       RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS THEN
	 xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	 x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	 xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
	                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
	                  ,p_error_text  => 'Invalid Calculate Price Flag '
	                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
	                  ,p_record_identifier_2 => p_cnv_line_rec.calculate_price_flag
	                  ,p_record_identifier_3 => p_calc_price_flag
                           );
	RETURN x_error_code;
   END is_calc_price_flag_valid; 
   --Added as per Wave1 09-NOV-13    
   -------------------  Validation for Customer Item Name --------------------------------------------------
   FUNCTION is_cust_item_name_valid (p_cust_item_name	 IN	VARCHAR2
                                 ,p_sold_to_org_id       IN	NUMBER
                                 ,p_inv_item_id          IN     NUMBER
			         ,p_orig_sys_document_ref IN	VARCHAR2
				 ,p_orig_sys_line_ref     IN     VARCHAR2
			     )
         RETURN NUMBER
      IS
         x_error_code		NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable		VARCHAR2 (40);
     BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_cust_item_name_valid: Customer Item Name =>'||p_cust_item_name);

         SELECT customer_item_number
           INTO x_variable
           FROM mtl_customer_items mci
          WHERE mci.inactive_flag = 'N'
            AND mci.customer_item_number = p_cust_item_name
            AND mci.customer_id = p_sold_to_org_id
            AND ROWNUM = 1;
            
        SELECT customer_item_number
          INTO x_variable
	  FROM mtl_customer_item_xrefs_v mcix
	 WHERE mcix.customer_item_number = p_cust_item_name
	   AND mcix.customer_id = p_sold_to_org_id
	   AND mcix.inactive_flag = 'N'
           AND mcix.inventory_item_id = p_inv_item_id
           AND ROWNUM = 1;
                        
        RETURN x_error_code;
     EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
	  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	  xx_emf_pkg.error (p_severity	=> xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category		=> xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'LINE :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Cust Item Name or Cross Reference => '|| p_cust_item_name ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.customer_item_name
		                  ,p_record_identifier_3 => p_cnv_line_rec.inventory_item
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'LINE :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Cust Item Name or Cross Reference => '|| p_cust_item_name ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.customer_item_name
		                  ,p_record_identifier_3 => p_cnv_line_rec.inventory_item
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text		=> 'LINE :  '|| p_orig_sys_document_ref||'-'||'LINE : '|| p_orig_sys_line_ref ||' Invalid Cust Item Name or Cross Reference => '|| p_cust_item_name||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.customer_item_name
		                  ,p_record_identifier_3 => p_cnv_line_rec.inventory_item
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Ship From Org ' || x_error_code);
               
		RETURN x_error_code;

      END is_cust_item_name_valid;
   
------------------- End Validation for Ship From Org  --------------------------
   --Added on 03-FEB-2014 as per Wave1
   -------------------  Validation for schedule status code  --------------------------
   FUNCTION is_schedule_status_code_valid (p_sch_sts_code IN VARCHAR2 
    				           )
   RETURN NUMBER
   IS
      x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;

   BEGIN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_schedule_status_code_valid : schedule_status_code =>'||p_sch_sts_code);

      IF p_sch_sts_code IS NOT NULL
      THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid schedule_status_code, Value should be NULL');
 	   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	   xx_emf_pkg.error ( p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		             ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		             ,p_error_text  => 'Invalid schedule_status_code. Value Should be NULL =>'
		             ,p_record_identifier_1 => p_cnv_line_rec.record_number
		             ,p_record_identifier_2 => p_cnv_line_rec.orig_sys_line_ref
		             ,p_record_identifier_3 => p_cnv_line_rec.schedule_status_code
                  );
      END IF;
      RETURN x_error_code;
   EXCEPTION                  
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
	                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
	                  ,p_error_text  => 'Line : Invalid schedule_status_code. Value Should be NULL =>'|| p_sch_sts_code  ||'-'||SQLERRM
	                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
	                  ,p_record_identifier_2 => p_cnv_line_rec.orig_sys_line_ref
	                  ,p_record_identifier_3 => p_cnv_line_rec.schedule_status_code
                  );

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Booked Flag ' || x_error_code);
           
	RETURN x_error_code;

   END is_schedule_status_code_valid;
   --Added as per Wave1 28-FEB-2014
   ------------------- validation for Return Reason Code ---------------------------------------------------
   FUNCTION is_rtn_rsn_code_valid (p_rtn_rsn_code	IN OUT  VARCHAR2
                                  )
   RETURN NUMBER
   IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
	 x_rtn_rsn_code	VARCHAR2(100);
   BEGIN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_rtn_rsn_code_valid: Return Reason Code => '|| p_rtn_rsn_code);

	 SELECT lookup_code
           INTO x_rtn_rsn_code
           FROM fnd_lookup_values
          WHERE UPPER(lookup_code) = UPPER(p_rtn_rsn_code)
	    AND lookup_type =  'CREDIT_MEMO_REASON'
	    AND enabled_flag = 'Y'
	    AND language  = 'US'
	    AND nvl(end_date_active,SYSDATE)>=SYSDATE;

         p_rtn_rsn_code := x_rtn_rsn_code;
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Line : '|| p_cnv_line_rec.orig_sys_document_ref ||' Return Reason Code => '|| x_rtn_rsn_code);
      
      RETURN x_error_code;
     EXCEPTION
           WHEN TOO_MANY_ROWS THEN
		     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
		     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Line : '|| p_cnv_line_rec.orig_sys_document_ref||' Invalid Return Reason Code => '|| p_rtn_rsn_code ||'-'||xx_emf_cn_pkg.CN_TOO_MANY
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.orig_sys_line_ref
		                  ,p_record_identifier_3 => p_cnv_line_rec.return_reason_code
                      );
                RETURN x_error_code;

           WHEN NO_DATA_FOUND THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Line : '|| p_cnv_line_rec.orig_sys_document_ref||' Invalid Return Reason Code => '|| p_rtn_rsn_code ||'-'||xx_emf_cn_pkg.CN_NO_DATA
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.orig_sys_line_ref
		                  ,p_record_identifier_3 => p_cnv_line_rec.return_reason_code
                      );
		 RETURN x_error_code;

           WHEN OTHERS THEN
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE OTHERS ' || SQLCODE);
	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_HIGH
		                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
		                  ,p_error_text  => 'Line : '|| p_cnv_line_rec.orig_sys_document_ref||' Invalid Return Reason Code => '|| p_rtn_rsn_code ||'-'||SQLERRM
		                  ,p_record_identifier_1 => p_cnv_line_rec.record_number
		                  ,p_record_identifier_2 => p_cnv_line_rec.orig_sys_line_ref
		                  ,p_record_identifier_3 => p_cnv_line_rec.return_reason_code
                      );

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'X_ERROR_CODE Return Reason Code ' || x_error_code);
               
		RETURN x_error_code;

      END is_rtn_rsn_code_valid;
------------------- End validation for Return Reason Code ------------------------------------------
      --- Start of the main function perform_batch_validations
      --- This will only have calls to the individual functions.

      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

	 x_error_code_temp := is_linetype_valid(p_cnv_line_rec.sold_from_org
	                                        ,p_cnv_line_rec.line_type
	  	                                ,p_cnv_line_rec.line_type_id
						,p_cnv_line_rec.invoicing_rule_id
						,p_cnv_line_rec.accounting_rule_id
						,p_cnv_line_rec.orig_sys_document_ref
						,p_cnv_line_rec.orig_sys_line_ref);
                            
         x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 x_error_code_temp := is_ship_from_org_valid (p_cnv_line_rec.ship_from_org
                                                     ,p_cnv_line_rec.ship_from_org_id
						     ,p_cnv_line_rec.orig_sys_document_ref
			                             ,p_cnv_line_rec.orig_sys_line_ref);
      	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
         
        	 		
	x_error_code_temp := is_inv_item_valid (  --p_cnv_line_rec.inventory_item
	                                            p_cnv_line_rec.ordered_item
		                                   ,p_cnv_line_rec.item_type_code
		                                   ,p_cnv_line_rec.inventory_item_id
		                                   ,p_cnv_line_rec.orig_sys_document_ref
						   ,p_cnv_line_rec.orig_sys_line_ref
						   ,p_cnv_line_rec.ship_from_org_id
		                                   );
			   
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 x_error_code_temp := is_ordered_qty_valid(p_cnv_line_rec.ordered_quantity
		                                   ,p_cnv_line_rec.shipped_quantity
		                                   ,p_cnv_line_rec.pricing_quantity
						   ,p_cnv_line_rec.orig_sys_document_ref
						   ,p_cnv_line_rec.orig_sys_line_ref
		                                         );
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 
	  x_error_code_temp := is_price_list_valid(p_cnv_line_rec.price_list
		                                  ,p_cnv_line_rec.price_list_id      
					          ,p_cnv_line_rec.orig_sys_document_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 --Added as per Wave1 09-NOV-13 
	 IF p_cnv_line_rec.customer_item_name IS NOT NULL AND p_cnv_line_rec.sold_to_org_id IS NOT NULL 
	    AND p_cnv_line_rec.inventory_item_id IS NOT NULL THEN
	    x_error_code_temp := is_cust_item_name_valid(p_cnv_line_rec.customer_item_name
	                                                ,p_cnv_line_rec.sold_to_org_id
	                                                ,p_cnv_line_rec.inventory_item_id
	                                                ,p_cnv_line_rec.orig_sys_document_ref
	                                                ,p_cnv_line_rec.orig_sys_line_ref);
	    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 END IF;
	 
	 --Modified on 03-FEB-2014 to make calc price flag check mandatory
	 --Added as per Wave1 23-OCT-13
	 --IF p_cnv_line_rec.calculate_price_flag IS NOT NULL THEN
	 x_error_code_temp := is_calc_price_flag_valid(p_cnv_line_rec.calculate_price_flag);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 --END IF;
	 
	 --Added as per Wave1 03-FEB-2014
	 x_error_code_temp := is_schedule_status_code_valid(p_cnv_line_rec.schedule_status_code);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 
	 x_error_code_temp := is_price_qty_uom_valid(p_cnv_line_rec.order_quantity_uom
	                                         ,p_cnv_line_rec.pricing_quantity_uom
						 ,p_cnv_line_rec.shipping_quantity_uom
                                                 ,p_cnv_line_rec.inventory_item_id--Added by Samir on 23-Jul-2012
                                                 ,p_cnv_line_rec.ship_from_org_id--Added by Samir on 23-Jul-2012
	                                         ,p_cnv_line_rec.orig_sys_document_ref
						 ,p_cnv_line_rec.orig_sys_line_ref);
	 x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

	 --Added as per Wave1 28-FEB-2014
	 IF p_cnv_line_rec.return_reason_code IS NOT NULL THEN
	    x_error_code_temp := is_rtn_rsn_code_valid(p_cnv_line_rec.return_reason_code);
	    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	 END IF;
	 
	 RETURN x_error_code;
     EXCEPTION
        WHEN xx_emf_pkg.G_E_REC_ERROR THEN
      	        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                RETURN x_error_code;
      	WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
      		x_error_code := xx_emf_cn_pkg.cn_rec_err;
      		RETURN x_error_code;
      	WHEN OTHERS THEN
      	     x_error_code := xx_emf_cn_pkg.cn_rec_err;
      	        RETURN x_error_code;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Data-Validations');

  END data_validations_line;

  ----- End Order Line Level Data Validations ------------------------------------------------------

   FUNCTION post_validations
   RETURN NUMBER
        IS
		x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
		x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         BEGIN
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');
	 RETURN x_error_code;
	EXCEPTION
		WHEN xx_emf_pkg.G_E_REC_ERROR THEN
			x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
			RETURN x_error_code;
		WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
			x_error_code := xx_emf_cn_pkg.cn_rec_err;
			RETURN x_error_code;
		WHEN OTHERS THEN
			x_error_code := xx_emf_cn_pkg.cn_rec_err;
			RETURN x_error_code;
	        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Post-Validations');
	END post_validations;

 FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec IN OUT  xx_oe_sales_order_conv_pkg.G_XX_SO_CNV_PRE_STD_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;

    ---------------------------------------derivation for Sales Orders ------------------------------------
   
      BEGIN
	      RETURN x_error_code;
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Data-derivations');
   END data_derivations;

   FUNCTION data_derivations_line (
       p_cnv_line_rec IN OUT  xx_oe_sales_order_conv_pkg.G_XX_SO_LINE_PRE_STD_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;

    ---------------------------------------derivation for sales order ------------------------------------
   
      BEGIN
	      RETURN x_error_code;
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Data-derivations');
   END data_derivations_line;

END xx_oe_sales_order_val_pkg;
/


GRANT EXECUTE ON APPS.XX_OE_SALES_ORDER_VAL_PKG TO INTG_XX_NONHR_RO;
