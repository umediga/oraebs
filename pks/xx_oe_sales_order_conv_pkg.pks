DROP PACKAGE APPS.XX_OE_SALES_ORDER_CONV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_SALES_ORDER_CONV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Samir Singha Mahapatra
 Creation Date : 15-Mar-2012
 File Name     : XXOESOHDRCNV.pks
 Description   : This script creates the specification of the package 
                 xx_oe_sales_order_conv_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 11-DEC-2013 Sharath Babu          Modified to add REQUEST_DATE as per Wave1
 28-FEB-2014 Sharath Babu          Modified to add RETURN_REASON_CODE
*/
----------------------------------------------------------------------
G_STAGE			VARCHAR2(2000);
G_BATCH_ID		VARCHAR2(200);
G_LINE_BATCH_ID		VARCHAR2(200);
g_validate_and_load     VARCHAR2(100) := 'VALIDATE_AND_LOAD';
g_process_name          VARCHAR2(60)  := 'XXOESALESORDCNV';
G_SOURCE_ID		NUMBER;
G_ORG_ID		NUMBER;
G_ORG_NAME              VARCHAR2(60);
G_SOURCE_NAME           VARCHAR2(60);
G_SHIP_FROM_ORG         VARCHAR2(10);
G_ORDER_TYPE            VARCHAR2(60);
G_RMA_ORDER_TYPE        VARCHAR2(60);
G_HOLD_TYPE_H           VARCHAR2(60);
G_HOLD_TYPE_ABC         VARCHAR2(60);
G_SHIPONLY_LINE         VARCHAR2(60);
G_LINE_TYPE             VARCHAR2(60);
G_RMA_LINE_TYPE         VARCHAR2(60);
G_PRICE_LIST            VARCHAR2(60);
G_TP_CONTEXT            VARCHAR2(60);  --23-AUG-12 added for tp context value
------------------------------- Sales Order Header Level Declaration ----------------------------

TYPE G_XX_ORDER_CNV_HDR_REC_TYPE IS RECORD
(
  ORIG_SYS_DOCUMENT_REF                   VARCHAR2(50)  
, SOURCE_SYSTEM_NAME                      VARCHAR2(50)  
, ORDER_SOURCE                            VARCHAR2(240) 
, ORG_CODE                                VARCHAR2(250)  
, ORDER_NUMBER                            NUMBER   
, ORDERED_DATE                            DATE   
, ORDER_TYPE                              VARCHAR2(40) 
, PRICE_LIST                              VARCHAR2(240)  
, CONVERSION_RATE                         NUMBER    
, CONVERSION_RATE_DATE                    DATE  
, CONVERSION_TYPE_CODE                    VARCHAR2(30)    
, TRANSACTIONAL_CURR_CODE                 VARCHAR2(15) 
, SALESREP                                VARCHAR2(240)
, SALES_CHANNEL_CODE                      VARCHAR2(30)
, RETURN_REASON_CODE                      VARCHAR2(30)
, TAX_POINT_CODE                          VARCHAR2(30)
, TAX_EXEMPT_FLAG                         VARCHAR2(1)
, TAX_EXEMPT_NUMBER                       VARCHAR2(80)
, TAX_EXEMPT_REASON_CODE                  VARCHAR2(30)
, INVOICING_RULE_ID                       NUMBER
, ACCOUNTING_RULE_ID                      NUMBER
, PAYMENT_TERM                            VARCHAR2(30)
, DEMAND_CLASS_CODE                       VARCHAR2(30)
, SHIPMENT_PRIORITY_CODE                  VARCHAR2(30)
, SHIPPING_METHOD_CODE                    VARCHAR2(30) 
, FREIGHT_CARRIER_CODE                    VARCHAR2(30)
, FREIGHT_TERMS_CODE                      VARCHAR2(30)                                                   
, FOB_POINT_CODE                          VARCHAR2(30)
, PARTIAL_SHIPMENTS_ALLOWED               VARCHAR2(1)
, SHIPPING_INSTRUCTIONS                   VARCHAR2(2000)
, PACKING_INSTRUCTIONS                    VARCHAR2(2000)
, CUSTOMER_PO_NUMBER                      VARCHAR2(50) 
, CUSTOMER_PAYMENT_TERM                   VARCHAR2(30)
, SOLD_TO_ORG                             VARCHAR2(360)
, INVOICE_TO_ORG                          VARCHAR2(240)
, DELIVER_TO_ORG                          VARCHAR2(240)
--, DELIVER_TO_CUSTOMER_NUMBER              VARCHAR2(50)
, CUSTOMER_NUMBER                         VARCHAR2(30)
, SHIPMENT_PRIORITY_CODE_INT              VARCHAR2(30)
, SHIP_TO_ORG                             VARCHAR2(240)
, SHIP_TO_CUSTOMER_NUMBER                 VARCHAR2(50)
, SHIP_TO_ADDRESS1                        VARCHAR2(240)
, SHIP_TO_ADDRESS2                        VARCHAR2(240)
, SHIP_TO_ADDRESS3                        VARCHAR2(240)
, SHIP_TO_ADDRESS4                        VARCHAR2(240)
, SHIP_TO_CITY                            VARCHAR2(60)
, SHIP_TO_COUNTY                          VARCHAR2(60)
, SHIP_TO_POSTAL_CODE                     VARCHAR2(60)
, SHIP_TO_PROVINCE                        VARCHAR2(60)
, SHIP_TO_STATE                           VARCHAR2(60)
, SHIP_TO_COUNTRY                         VARCHAR2(60)
, SHIP_FROM_ORG                           VARCHAR2(240)
, BILL_TO_CUSTOMER_NUMBER                 VARCHAR2(50)
, BILL_TO_ADDRESS1                        VARCHAR2(240)
, BILL_TO_ADDRESS2                        VARCHAR2(240)
, BILL_TO_ADDRESS3                        VARCHAR2(240)
, BILL_TO_ADDRESS4                        VARCHAR2(240)
, BILL_TO_CITY                            VARCHAR2(60)
, BILL_TO_COUNTY                          VARCHAR2(60)
, BILL_TO_POSTAL_CODE                     VARCHAR2(60)
, BILL_TO_PROVINCE                        VARCHAR2(60)
, BILL_TO_STATE                           VARCHAR2(60)
, BILL_TO_COUNTRY                         VARCHAR2(60)
, SOLD_FROM_ORG                           VARCHAR2(240)
, DELIVER_TO_CUSTOMER_NUMBER              VARCHAR2(50)
, DELIVER_TO_ADDRESS1                     VARCHAR2(240)
, DELIVER_TO_ADDRESS2                     VARCHAR2(240)
, DELIVER_TO_ADDRESS3                     VARCHAR2(240)
, DELIVER_TO_ADDRESS4                     VARCHAR2(240)
, DELIVER_TO_CITY                         VARCHAR2(60)
, DELIVER_TO_COUNTY                       VARCHAR2(60)
, DELIVER_TO_POSTAL_CODE                  VARCHAR2(60)
, DELIVER_TO_PROVINCE                     VARCHAR2(60)
, DELIVER_TO_STATE                        VARCHAR2(60)
, DELIVER_TO_COUNTRY                      VARCHAR2(60)
, DELIVER_TO_CONTACT                      VARCHAR2(240)
, DROP_SHIP_FLAG                          VARCHAR2(1)  
, BOOKED_FLAG                             VARCHAR2(1)  
, CLOSED_FLAG                             VARCHAR2(1) 
, CANCELLED_FLAG                          VARCHAR2(1) 
, CONTEXT                                 VARCHAR2(30)
, ATTRIBUTE1                              VARCHAR2(240)
, ATTRIBUTE2                              VARCHAR2(240)
, ATTRIBUTE3                              VARCHAR2(240)
, ATTRIBUTE4                              VARCHAR2(240)
, ATTRIBUTE5                              VARCHAR2(240)
, ATTRIBUTE6				  VARCHAR2(240)
, ATTRIBUTE7				  VARCHAR2(240)
, ATTRIBUTE8				  VARCHAR2(240)
, ATTRIBUTE9				  VARCHAR2(240)
, ATTRIBUTE10				  VARCHAR2(240)
, GLOBAL_ATTRIBUTE_CATEGORY               VARCHAR2(30) 
, GLOBAL_ATTRIBUTE1                       VARCHAR2(240)
, GLOBAL_ATTRIBUTE2                       VARCHAR2(240)
, GLOBAL_ATTRIBUTE3                       VARCHAR2(240)
, GLOBAL_ATTRIBUTE4                       VARCHAR2(240)
, GLOBAL_ATTRIBUTE5                       VARCHAR2(240)
, GLOBAL_ATTRIBUTE6			  VARCHAR2(240)
, GLOBAL_ATTRIBUTE7			  VARCHAR2(240)
, GLOBAL_ATTRIBUTE8			  VARCHAR2(240)
, GLOBAL_ATTRIBUTE9			  VARCHAR2(240)
, GLOBAL_ATTRIBUTE10     		  VARCHAR2(240)    
, ORDER_CATEGORY                          VARCHAR2(30) 
, REJECTED_FLAG                           VARCHAR2(1)  
, SALES_CHANNEL                           VARCHAR2(80) 
, CUSTOMER_PREFERENCE_SET_CODE            VARCHAR2(30) 
, PRICE_REQUEST_CODE                      VARCHAR2(240)
, ORIG_SYS_CUSTOMER_REF                   VARCHAR2(50) 
, ORIG_SHIP_ADDRESS_REF                   VARCHAR2(50) 
, ACCOUNTING_RULE_DURATION                NUMBER       
, BLANKET_NUMBER                          NUMBER  
, PRICING_DATE                            DATE    
, TRANSACTION_PHASE_CODE                  VARCHAR2(30)
, QUOTE_NUMBER                            NUMBER      
, QUOTE_DATE                              DATE        
, SUPPLIER_SIGNATURE                      VARCHAR2(240)
, SUPPLIER_SIGNATURE_DATE                 DATE         
, CUSTOMER_SIGNATURE                      VARCHAR2(240)
, CUSTOMER_SIGNATURE_DATE                 DATE         
, EXPIRATION_DATE                         DATE         
, SALES_REGION                            VARCHAR2(30) 
, SALESMAN_NUMBER                         VARCHAR2(30) 
, HOLD_TYPE_CODE                          VARCHAR2(30) 
, RELEASE_REASON_CODE                     VARCHAR2(30) 
, COMMENTS                                VARCHAR2(2000)
, CHAR_PARAM1                             VARCHAR2(2000)
, CHAR_PARAM2                             VARCHAR2(240) 
, DATE_PARAM1                             DATE          
, DATE_PARAM2                             DATE 
, TP_CONTEXT                              VARCHAR2(30)   
, TP_ATTRIBUTE1                           VARCHAR2(100)  
, TP_ATTRIBUTE2                           VARCHAR2(100)
, REQUEST_DATE                            DATE
, BATCH_ID                                VARCHAR2(200)                                                                         
, RECORD_NUMBER                           NUMBER
, PROCESS_CODE                            VARCHAR2(100) 
, ERROR_CODE                              VARCHAR2(100) 
, REQUEST_ID                              NUMBER        
, CREATION_DATE                           DATE      
, CREATED_BY                              NUMBER            
, LAST_UPDATE_DATE                        DATE          
, LAST_UPDATED_BY                         NUMBER        
, LAST_UPDATE_LOGIN                       NUMBER        
);

        TYPE G_XX_ORDER_CNV_HDR_TAB_TYPE IS TABLE OF G_XX_ORDER_CNV_HDR_REC_TYPE 
        INDEX BY BINARY_INTEGER;


TYPE G_XX_SO_CNV_PRE_STD_REC_TYPE IS RECORD
(
 ORIG_SYS_DOCUMENT_REF                   VARCHAR2(50)                                                                                                                                                                                  
, ORDER_SOURCE                            VARCHAR2(240)
, ORDER_SOURCE_ID                         NUMBER                                                                                                                                                                                      
, ORG_CODE                                VARCHAR2(250)  
, ORG_ID                                  NUMBER                                                                                                                                                                                 
, ORDER_NUMBER                            NUMBER  
, ORDER_ID                                NUMBER                                                                                                                                                                                              
, ORDERED_DATE                            DATE                                                                                                                                                                                          
, ORDER_TYPE                              VARCHAR2(40) 
, ORDER_TYPE_ID                           NUMBER                                                                                                                                                                                  
, PRICE_LIST                              VARCHAR2(240) 
, PRICE_LIST_ID                           NUMBER                                                                                                                                                                                         
, CONVERSION_RATE                         NUMBER                                                                                                                                                                                        
, CONVERSION_RATE_DATE                    DATE                                                                                                                                                                                          
, CONVERSION_TYPE_CODE                    VARCHAR2(30)                                                                                                                                                                                  
, TRANSACTIONAL_CURR_CODE                 VARCHAR2(15)                                                                                                                                                                                  
, SALESREP                                VARCHAR2(240) 
, SALESREP_ID                             NUMBER(15)                                                                                                                                                                                  
, SALES_CHANNEL_CODE                      VARCHAR2(30)                                                                                                                                                                                  
, RETURN_REASON_CODE                      VARCHAR2(30)                                                                                                                                                                                  
, TAX_POINT_CODE                          VARCHAR2(30)                                                                                                                                                                                  
, TAX_EXEMPT_FLAG                         VARCHAR2(1)                                                                                                                                                                                   
, TAX_EXEMPT_NUMBER                       VARCHAR2(80)                                                                                                                                                                                  
, TAX_EXEMPT_REASON_CODE                  VARCHAR2(30)                                                                                                                                                                                  
, INVOICING_RULE_ID                       NUMBER                                                                                                                                                                                  
, ACCOUNTING_RULE_ID                      NUMBER                                                                                                                                                                                 
, PAYMENT_TERM                            VARCHAR2(30) 
, PAYMENT_TERM_ID                         NUMBER(15)                                                                                                                                                                                    
, DEMAND_CLASS_CODE                       VARCHAR2(30)                                                                                                                                                                                  
, SHIPMENT_PRIORITY_CODE                  VARCHAR2(30)                                                                                                                                                                                  
, SHIPPING_METHOD_CODE                    VARCHAR2(30)                                                                                                                                                                                  
, FREIGHT_CARRIER_CODE                    VARCHAR2(30)                                                                                                                                                                                  
, FREIGHT_TERMS_CODE                      VARCHAR2(30)                                                                                                                                                                                  
, FOB_POINT_CODE                          VARCHAR2(30)                                                                                                                                                                                  
, PARTIAL_SHIPMENTS_ALLOWED               VARCHAR2(1)                                                                                                                                                                                   
, SHIPPING_INSTRUCTIONS                   VARCHAR2(2000)                                                                                                                                                                                
, PACKING_INSTRUCTIONS                    VARCHAR2(2000)                                                                                                                                                                                
, CUSTOMER_PO_NUMBER                      VARCHAR2(50)                                                                                                                                                                                  
, CUSTOMER_PAYMENT_TERM                   VARCHAR2(30)                                                                                                                                                                                  
, SOLD_TO_ORG                             VARCHAR2(360) 
, SOLD_TO_ORG_ID                          NUMBER                                                                                                                                                                                         
, INVOICE_TO_ORG                          VARCHAR2(240) 
, INVOICE_TO_ORG_ID                       NUMBER                                                                                                                                                                                 
, DELIVER_TO_ORG                          VARCHAR2(240)                                                                                                                                                                                 
--, DELIVER_TO_CUSTOMER_NUMBER              VARCHAR2(50)                                                                                                                                                                                  
, CUSTOMER_NUMBER                         VARCHAR2(30)                                                                                                                                                                                  
, SHIPMENT_PRIORITY_CODE_INT              VARCHAR2(30)                                                                                                                                                                                  
, SHIP_TO_ORG                             VARCHAR2(240)
, SHIP_TO_ORG_ID                          NUMBER                                                                                                                                                                                      
, SHIP_TO_CUSTOMER_NUMBER                 VARCHAR2(50)                                                                                                                                                                                  
, SHIP_TO_ADDRESS1                        VARCHAR2(240)                                                                                                                                                                                 
, SHIP_TO_ADDRESS2                        VARCHAR2(240)                                                                                                                                                                                 
, SHIP_TO_ADDRESS3                        VARCHAR2(240)                                                                                                                                                                                 
, SHIP_TO_ADDRESS4                        VARCHAR2(240)                                                                                                                                                                                 
, SHIP_TO_CITY                            VARCHAR2(60)                                                                                                                                                                                  
, SHIP_TO_COUNTY                          VARCHAR2(60)                                                                                                                                                                                  
, SHIP_TO_POSTAL_CODE                     VARCHAR2(60)                                                                                                                                                                                  
, SHIP_TO_PROVINCE                        VARCHAR2(60)                                                                                                                                                                                  
, SHIP_TO_STATE                           VARCHAR2(60)                                                                                                                                                                                  
, SHIP_TO_COUNTRY                         VARCHAR2(60)  
--Added for Integra
, BILL_TO_ORG                             VARCHAR2(240)
, BILL_TO_ORG_ID                          NUMBER                                                                                                                                                                                      
, BILL_TO_CUSTOMER_NUMBER                 VARCHAR2(50)                                                                                                                                                                                  
, BILL_TO_ADDRESS1                        VARCHAR2(240)                                                                                                                                                                                 
, BILL_TO_ADDRESS2                        VARCHAR2(240)                                                                                                                                                                                 
, BILL_TO_ADDRESS3                        VARCHAR2(240)                                                                                                                                                                                 
, BILL_TO_ADDRESS4                        VARCHAR2(240)                                                                                                                                                                                 
, BILL_TO_CITY                            VARCHAR2(60)                                                                                                                                                                                  
, BILL_TO_COUNTY                          VARCHAR2(60)                                                                                                                                                                                  
, BILL_TO_POSTAL_CODE                     VARCHAR2(60)                                                                                                                                                                                  
, BILL_TO_PROVINCE                        VARCHAR2(60)                                                                                                                                                                                  
, BILL_TO_STATE                           VARCHAR2(60)                                                                                                                                                                                  
, BILL_TO_COUNTRY                         VARCHAR2(60)                                                                                                                                                                                  
, DELIVER_TO_CUSTOMER_NUMBER              VARCHAR2(50)                                                                                                                                                                                  
, DELIVER_TO_ADDRESS1                     VARCHAR2(240)                                                                                                                                                                                 
, DELIVER_TO_ADDRESS2                     VARCHAR2(240)                                                                                                                                                                                 
, DELIVER_TO_ADDRESS3                     VARCHAR2(240)                                                                                                                                                                                 
, DELIVER_TO_ADDRESS4                     VARCHAR2(240)                                                                                                                                                                                 
, DELIVER_TO_CITY                         VARCHAR2(60)
, DELIVER_TO_COUNTY                       VARCHAR2(60)
, DELIVER_TO_POSTAL_CODE                  VARCHAR2(60)
, DELIVER_TO_PROVINCE                     VARCHAR2(60)
, DELIVER_TO_STATE                        VARCHAR2(60)
, DELIVER_TO_COUNTRY                      VARCHAR2(60)
, DELIVER_TO_CONTACT                      VARCHAR2(240)
, DELIVER_TO_ORG_ID                       NUMBER
, DELIVER_TO_CONTACT_ID                   NUMBER  --Added to populate contact id as per DCR 03-SEP-12
---
, SHIP_FROM_ORG                           VARCHAR2(240)
, SHIP_FROM_ORG_ID                        NUMBER                                                                                                                                                                                      
, SOLD_FROM_ORG                           VARCHAR2(240) 
, SOLD_FROM_ORG_ID                        NUMBER                                                                                                                                                                                     
, DROP_SHIP_FLAG                          VARCHAR2(1)                                                                                                                                                                                   
, BOOKED_FLAG                             VARCHAR2(1)                                                                                                                                                                                   
, CLOSED_FLAG                             VARCHAR2(1)                                                                                                                                                                                   
, CANCELLED_FLAG                          VARCHAR2(1)                                                                                                                                                                                   
, CONTEXT                                 VARCHAR2(30)                                                                                                                                                                                  
, ATTRIBUTE1                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE2                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE3                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE4                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE5                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE6                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE7                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE8                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE9                              VARCHAR2(240)                                                                                                                                                                                 
, ATTRIBUTE10                             VARCHAR2(240)          
, GLOBAL_ATTRIBUTE_CATEGORY               VARCHAR2(30)                                                                                                                                                                                  
, GLOBAL_ATTRIBUTE1                       VARCHAR2(240)                                                                                                                                                                                 
, GLOBAL_ATTRIBUTE2                       VARCHAR2(240)                                                                                                                                                                                 
, GLOBAL_ATTRIBUTE3                       VARCHAR2(240)                                                                                                                                                                                 
, GLOBAL_ATTRIBUTE4                       VARCHAR2(240)                                                                                                                                                                                 
, GLOBAL_ATTRIBUTE5                       VARCHAR2(240)                                                                                                                                                                                 
, ORDER_CATEGORY                          VARCHAR2(30)                                                                                                                                                                                  
, REJECTED_FLAG                           VARCHAR2(1)                                                                                                                                                                                   
, SALES_CHANNEL                           VARCHAR2(80)                                                                                                                                                                                  
, CUSTOMER_PREFERENCE_SET_CODE            VARCHAR2(30)                                                                                                                                                                                  
, PRICE_REQUEST_CODE                      VARCHAR2(240)                                                                                                                                                                                 
, ORIG_SYS_CUSTOMER_REF                   VARCHAR2(50)                                                                                                                                                                                  
, ORIG_SHIP_ADDRESS_REF                   VARCHAR2(50)                                                                                                                                                                                  
, ACCOUNTING_RULE_DURATION                NUMBER                                                                                                                                                                                        
, BLANKET_NUMBER                          NUMBER                                                                                                                                                                                        
, PRICING_DATE                            DATE                                                                                                                                                                                          
, TRANSACTION_PHASE_CODE                  VARCHAR2(30)                                                                                                                                                                                  
, QUOTE_NUMBER                            NUMBER                                                                                                                                                                                        
, QUOTE_DATE                              DATE                                                                                                                                                                                          
, SUPPLIER_SIGNATURE                      VARCHAR2(240)                                                                                                                                                                                 
, SUPPLIER_SIGNATURE_DATE                 DATE                                                                                                                                                                                          
, CUSTOMER_SIGNATURE                      VARCHAR2(240)                                                                                                                                                                                 
, CUSTOMER_SIGNATURE_DATE                 DATE                                                                                                                                                                                          
, EXPIRATION_DATE                         DATE                                                                                                                                                                                          
, SALES_REGION                            VARCHAR2(30)                                                                                                                                                                                  
, SALESMAN_NUMBER                         VARCHAR2(30)                                                                                                                                                                                  
, HOLD_TYPE_CODE                          VARCHAR2(30)
, RELEASE_REASON_CODE                     VARCHAR2(30)                                                                                                                                                                                  
, COMMENTS                                VARCHAR2(2000)                                                                                                                                                                                
, CHAR_PARAM1                             VARCHAR2(2000)                                                                                                                                                                                
, CHAR_PARAM2                             VARCHAR2(240)                                                                                                                                                                                 
, DATE_PARAM1                             DATE                                                                                                                                                                                          
, DATE_PARAM2                             DATE      
, TP_CONTEXT                              VARCHAR2(30)   
, TP_ATTRIBUTE1                           VARCHAR2(100)  
, TP_ATTRIBUTE2                           VARCHAR2(100) 
, REQUEST_DATE                            DATE
, BATCH_ID                                VARCHAR2(200)                                                                                                                                                                                 
, RECORD_NUMBER                           NUMBER
, PROCESS_CODE                            VARCHAR2(100)                                                                                                                                                                                 
, ERROR_CODE                              VARCHAR2(100)                                                                                                                                                                                 
, CREATED_BY                              NUMBER                                                                                                                                                                                        
, CREATION_DATE                           DATE                                                                                                                                                                                          
, LAST_UPDATE_DATE                        DATE                                                                                                                                                                                          
, LAST_UPDATED_BY                         NUMBER                                                                                                                                                                                        
, LAST_UPDATE_LOGIN                       NUMBER                                                                                                                                                                                        
, REQUEST_ID                              NUMBER   
, HOLD_ID				  NUMBER
, NEW_FOB_POINT				  VARCHAR2(30)
, NEW_FREIGHT_TERM    			  VARCHAR2(30)
, NEW_PARTY_ID				  NUMBER(15)
, GLOBAL_LOCATION_NUMBER			  VARCHAR2(40)
, NEW_WAREHOUSE_ID			  NUMBER(15)
, NEW_SHIP_VIA				  VARCHAR2(30)
, NEW_PRIMARY_SALESREP_ID		  NUMBER(15)
, NEW_ADD_FLAG				  VARCHAR2(1)
, NEW_SITE_FLAG				  NUMBER--VARCHAR2(1)
, NEW_LOCATION_ID			  NUMBER(15)
);								
        TYPE G_XX_SO_CNV_PRE_STD_TAB_TYPE IS TABLE OF G_XX_SO_CNV_PRE_STD_REC_TYPE 
        INDEX BY BINARY_INTEGER;				

-------------------- Sales Order Line Level Declaration ------------------------------------------

TYPE G_XX_SO_LINE_STG_REC_TYPE IS RECORD
(
BATCH_ID   				VARCHAR2(200),
RECORD_NUMBER  			NUMBER,
ORIG_SYS_DOCUMENT_REF 		VARCHAR2(50),
ORIG_SYS_LINE_REF 		VARCHAR2(50),
ORIG_SYS_SHIPMENT_REF 		VARCHAR2(50),
LINE_NUMBER 			NUMBER,
SHIPMENT_NUMBER 			NUMBER,
LINE_TYPE 				VARCHAR2(30),
ITEM_TYPE_CODE  			VARCHAR2(30),
INVENTORY_ITEM		      VARCHAR2(2000),
SOURCE_TYPE_CODE 			VARCHAR2(30),
SCHEDULE_STATUS_CODE 		VARCHAR2(30),
SCHEDULE_SHIP_DATE 		DATE,
SCHEDULE_ARRIVAL_DATE 		DATE,
ACTUAL_ARRIVAL_DATE 		DATE,
PROMISE_DATE 			DATE,
SCHEDULE_DATE 			DATE,
ORDERED_QUANTITY 			NUMBER,
ORDER_QUANTITY_UOM 		VARCHAR2(3),
SHIPPING_QUANTITY 		NUMBER,
SHIPPING_QUANTITY_UOM 		VARCHAR2(3),
SHIPPED_QUANTITY 			NUMBER,
CANCELLED_QUANTITY 		NUMBER,
FULFILLED_QUANTITY 		NUMBER,
PRICING_QUANTITY 			NUMBER,
PRICING_QUANTITY_UOM 		VARCHAR2(3),
SOLD_TO_ORG  			VARCHAR2(360),
SHIP_FROM_ORG 			VARCHAR2(240),
SHIP_TO_ORG 			VARCHAR2(240),
DELIVER_TO_ORG 			VARCHAR2(240),
INVOICE_TO_ORG 			VARCHAR2(240),
DROP_SHIP_FLAG 			VARCHAR2(1),
LOAD_SEQ_NUMBER 			NUMBER,
AUTHORIZED_TO_SHIP_FLAG 	VARCHAR2(1),
SHIP_SET_NAME 			VARCHAR2(30),
ARRIVAL_SET_NAME 			VARCHAR2(30),
INVOICE_SET_NAME 			VARCHAR2(30),
PRICE_LIST 				VARCHAR2(240),
PRICING_DATE 			DATE,
UNIT_LIST_PRICE 			NUMBER,
UNIT_SELLING_PRICE 		NUMBER,
CALCULATE_PRICE_FLAG 		VARCHAR2(1),
TAX_CODE 				VARCHAR2(50),
TAX_VALUE 				NUMBER,
TAX_DATE 				DATE,
TAX_POINT_CODE 			VARCHAR2(30),
TAX_EXEMPT_FLAG 			VARCHAR2(30),
TAX_EXEMPT_NUMBER 		VARCHAR2(80),
TAX_EXEMPT_REASON_CODE 		VARCHAR2(30),
INVOICING_RULE 			VARCHAR2(30),
ACCOUNTING_RULE 			VARCHAR2(30),
PAYMENT_TERM 			VARCHAR2(30),
DEMAND_CLASS_CODE 		VARCHAR2(30),
SHIPMENT_PRIORITY_CODE 		VARCHAR2(30),
SHIPPING_METHOD_CODE	 	VARCHAR2(30),
FREIGHT_CARRIER_CODE 		VARCHAR2(30),
FREIGHT_TERMS_CODE 		VARCHAR2(30),
FOB_POINT_CODE 			VARCHAR2(30),
SALESREP 				VARCHAR2(240),
CUSTOMER_PO_NUMBER 		VARCHAR2(50),
CUSTOMER_LINE_NUMBER 		VARCHAR2(50),
CUSTOMER_SHIPMENT_NUMBER 	VARCHAR2(50),
CLOSED_FLAG 			VARCHAR2(1),
CANCELLED_FLAG 			VARCHAR2(1),
CONTEXT 				VARCHAR2(30),
ATTRIBUTE1 				VARCHAR2(240),
ATTRIBUTE2 				VARCHAR2(240),
ATTRIBUTE3 				VARCHAR2(240),
ATTRIBUTE4 				VARCHAR2(240),
ATTRIBUTE5 				VARCHAR2(240),
ATTRIBUTE6 			VARCHAR2(240),
ATTRIBUTE7 			VARCHAR2(240),
ATTRIBUTE8		 	VARCHAR2(240),
ATTRIBUTE9 			VARCHAR2(240),
ATTRIBUTE10 			VARCHAR2(240),
GLOBAL_ATTRIBUTE_CATEGORY 	VARCHAR2(30),
GLOBAL_ATTRIBUTE1 		VARCHAR2(240),
GLOBAL_ATTRIBUTE2 		VARCHAR2(240),
GLOBAL_ATTRIBUTE3 		VARCHAR2(240),
GLOBAL_ATTRIBUTE4 		VARCHAR2(240),
GLOBAL_ATTRIBUTE5 		VARCHAR2(240),
FULFILLED_FLAG 			VARCHAR2(1),
REQUEST_DATE 			DATE,
SHIPPING_INSTRUCTIONS 		VARCHAR2(2000),
PACKING_INSTRUCTIONS 		VARCHAR2(2000),
SOLD_FROM_ORG 			VARCHAR2(240),
CUSTOMER_ITEM_NAME 		VARCHAR2(2000),
SUBINVENTORY 			VARCHAR2(10),
UNIT_LIST_PRICE_PER_PQTY 	VARCHAR2(3),
UNIT_SELLING_PRICE_PER_PQTY 	VARCHAR2(3),
PRICE_REQUEST_CODE 		VARCHAR2(240),
ORIG_SHIP_ADDRESS_REF 		VARCHAR2(50),
ORIG_BILL_ADDRESS_REF 		VARCHAR2(50),
SHIP_TO_CUSTOMER_NUMBER 	VARCHAR2(30),
INVOICE_TO_CUSTOMER_NUMBER 	VARCHAR2(30),
DELIVER_TO_CUSTOMER_NUMBER 	VARCHAR2(30),
ACCOUNTING_RULE_DURATION  	NUMBER,	
USER_ITEM_DESCRIPTION 		VARCHAR2(1000),
LINE_CATEGORY_CODE 		VARCHAR2(30),
TP_CONTEXT                      VARCHAR2(30),   
TP_ATTRIBUTE1                   VARCHAR2(100),  
TP_ATTRIBUTE2                   VARCHAR2(100),  
TP_ATTRIBUTE3                   VARCHAR2(100),  
TP_ATTRIBUTE4                   VARCHAR2(100),  
TP_ATTRIBUTE5                   VARCHAR2(100),  
ORDERED_ITEM                    VARCHAR2(240),  
SALES_REGION 			VARCHAR2(30),
SALESMAN_NUMBER 			VARCHAR2(30),
PROCESS_CODE 			VARCHAR2(100),
ERROR_CODE 				VARCHAR2(100),
CREATED_BY 				NUMBER,
CREATION_DATE 			DATE,
LAST_UPDATE_DATE 			DATE,
LAST_UPDATED_BY 			NUMBER,
LAST_UPDATE_LOGIN 		NUMBER,
REQUEST_ID 				NUMBER,
RETURN_REASON_CODE              VARCHAR2(30)    --Added on 28-FEB-2014
);
        TYPE G_XX_SO_LINE_STG_TAB_TYPE IS TABLE OF G_XX_SO_LINE_STG_REC_TYPE 
        INDEX BY BINARY_INTEGER;



TYPE G_XX_SO_LINE_PRE_STD_REC_TYPE IS RECORD
( BATCH_ID   			VARCHAR2(200),
RECORD_NUMBER  			NUMBER,
ORIG_SYS_DOCUMENT_REF 		VARCHAR2(50),
ORIG_SYS_LINE_REF 		VARCHAR2(50),
ORIG_SYS_SHIPMENT_REF 		VARCHAR2(50),
LINE_NUMBER 			NUMBER,
LINE_ID                         NUMBER,
HEADER_ID                       NUMBER,     
SHIPMENT_NUMBER 		NUMBER,
LINE_TYPE 			VARCHAR2(30),
LINE_TYPE_ID                    NUMBER , 
ITEM_TYPE_CODE  		VARCHAR2(30),
INVENTORY_ITEM 			VARCHAR2(2000),
INVENTORY_ITEM_ID               NUMBER ,
SOURCE_TYPE_CODE 		VARCHAR2(30),
SCHEDULE_STATUS_CODE 		VARCHAR2(30),
SCHEDULE_SHIP_DATE 		DATE,
SCHEDULE_ARRIVAL_DATE 		DATE,
ACTUAL_ARRIVAL_DATE 		DATE,
PROMISE_DATE 			DATE,
SCHEDULE_DATE 			DATE,
ORDERED_QUANTITY 		NUMBER,
ORDER_QUANTITY_UOM 		VARCHAR2(3),
SHIPPING_QUANTITY 		NUMBER,
SHIPPING_QUANTITY_UOM 		VARCHAR2(3),
SHIPPED_QUANTITY 		NUMBER,
CANCELLED_QUANTITY 		NUMBER,
FULFILLED_QUANTITY 		NUMBER,
PRICING_QUANTITY 		NUMBER,
PRICING_QUANTITY_UOM 		VARCHAR2(3),
SOLD_TO_ORG  			VARCHAR2(360),
SOLD_TO_ORG_ID                  NUMBER,
SHIP_FROM_ORG 			VARCHAR2(240),
SHIP_FROM_ORG_ID                NUMBER,
SHIP_TO_ORG 			VARCHAR2(240),
SHIP_TO_ORG_ID                  NUMBER,
DELIVER_TO_ORG 			VARCHAR2(240),
INVOICE_TO_ORG 			VARCHAR2(240),
INVOICE_TO_ORG_ID               NUMBER,
DROP_SHIP_FLAG 			VARCHAR2(1),
LOAD_SEQ_NUMBER 		NUMBER,
AUTHORIZED_TO_SHIP_FLAG 	VARCHAR2(1),
SHIP_SET_NAME 			VARCHAR2(30),
ARRIVAL_SET_NAME 		VARCHAR2(30),
INVOICE_SET_NAME 		VARCHAR2(30),
PRICE_LIST 			VARCHAR2(240),
PRICE_LIST_ID                   NUMBER,
PRICING_DATE 			DATE,
UNIT_LIST_PRICE 		NUMBER,
UNIT_SELLING_PRICE 		NUMBER,
CALCULATE_PRICE_FLAG 		VARCHAR2(1),
TAX_CODE 			VARCHAR2(50),
TAX_VALUE 			NUMBER,
TAX_DATE 			DATE,
TAX_POINT_CODE 			VARCHAR2(30),
TAX_EXEMPT_FLAG 		VARCHAR2(30),
TAX_EXEMPT_NUMBER 		VARCHAR2(80),
TAX_EXEMPT_REASON_CODE 		VARCHAR2(30),
INVOICING_RULE_ID 	        NUMBER,
ACCOUNTING_RULE_ID		NUMBER,
PAYMENT_TERM 			VARCHAR2(30),
PAYMENT_TERM_ID			NUMBER,
DEMAND_CLASS_CODE 		VARCHAR2(30),
SHIPMENT_PRIORITY_CODE 		VARCHAR2(30),
SHIPPING_METHOD_CODE 		VARCHAR2(30),
FREIGHT_CARRIER_CODE 		VARCHAR2(30),
FREIGHT_TERMS_CODE 		VARCHAR2(30),
FOB_POINT_CODE 			VARCHAR2(30),
SALESREP 			VARCHAR2(240),
SALESREP_ID                     NUMBER,
CUSTOMER_PO_NUMBER 		VARCHAR2(50),
CUSTOMER_LINE_NUMBER 		VARCHAR2(50),
CUSTOMER_SHIPMENT_NUMBER 	VARCHAR2(50),
CLOSED_FLAG 			VARCHAR2(1),
CANCELLED_FLAG 			VARCHAR2(1),
CONTEXT 			VARCHAR2(30),
ATTRIBUTE1 			VARCHAR2(240),
ATTRIBUTE2 			VARCHAR2(240),
ATTRIBUTE3		 	VARCHAR2(240),
ATTRIBUTE4 			VARCHAR2(240),
ATTRIBUTE5 			VARCHAR2(240),
ATTRIBUTE6 			VARCHAR2(240),
ATTRIBUTE7 			VARCHAR2(240),
ATTRIBUTE8		 	VARCHAR2(240),
ATTRIBUTE9 			VARCHAR2(240),
ATTRIBUTE10 			VARCHAR2(240),
GLOBAL_ATTRIBUTE_CATEGORY 	VARCHAR2(30),
GLOBAL_ATTRIBUTE1 		VARCHAR2(240),
GLOBAL_ATTRIBUTE2 		VARCHAR2(240),
GLOBAL_ATTRIBUTE3 		VARCHAR2(240),
GLOBAL_ATTRIBUTE4 		VARCHAR2(240),
GLOBAL_ATTRIBUTE5 		VARCHAR2(240),
FULFILLED_FLAG 			VARCHAR2(1),
REQUEST_DATE 			DATE,
SHIPPING_INSTRUCTIONS 		VARCHAR2(2000),
PACKING_INSTRUCTIONS 		VARCHAR2(2000),
SOLD_FROM_ORG 			VARCHAR2(240),
SOLD_FROM_ORG_ID                NUMBER,
CUSTOMER_ITEM_NAME 		VARCHAR2(2000),
SUBINVENTORY 			VARCHAR2(10),
UNIT_LIST_PRICE_PER_PQTY 	NUMBER,
UNIT_SELLING_PRICE_PER_PQTY 	NUMBER,
PRICE_REQUEST_CODE 		VARCHAR2(240),
ORIG_SHIP_ADDRESS_REF 		VARCHAR2(50),
ORIG_BILL_ADDRESS_REF 		VARCHAR2(50),
SHIP_TO_CUSTOMER_NUMBER 	VARCHAR2(30),
INVOICE_TO_CUSTOMER_NUMBER 	VARCHAR2(30),
DELIVER_TO_CUSTOMER_NUMBER 	VARCHAR2(30),
ACCOUNTING_RULE_DURATION  	NUMBER,	
USER_ITEM_DESCRIPTION 		VARCHAR2(1000),
LINE_CATEGORY_CODE 		VARCHAR2(30),
TP_CONTEXT                      VARCHAR2(30),   
TP_ATTRIBUTE1                   VARCHAR2(100),  
TP_ATTRIBUTE2                   VARCHAR2(100),  
TP_ATTRIBUTE3                   VARCHAR2(100),  
TP_ATTRIBUTE4                   VARCHAR2(100),  
TP_ATTRIBUTE5                   VARCHAR2(100),  
ORDERED_ITEM                    VARCHAR2(240),   
CUSTOMER_ITEM_ID                NUMBER,          
CUSTOMER_ITEM_ID_TYPE           VARCHAR2(30),   
SALES_REGION 			VARCHAR2(30),
SALESMAN_NUMBER 		VARCHAR2(30),
PROCESS_CODE 			VARCHAR2(100),
ERROR_CODE 			VARCHAR2(100),
CREATED_BY 			NUMBER,
CREATION_DATE 			DATE,
LAST_UPDATE_DATE 		DATE,
LAST_UPDATED_BY 		NUMBER,
LAST_UPDATE_LOGIN 		NUMBER,
REQUEST_ID 			NUMBER,
RETURN_REASON_CODE              VARCHAR2(30)    --Added on 28-FEB-2014
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      TYPE G_XX_SO_LINE_PRE_STD_TAB_TYPE IS TABLE OF G_XX_SO_LINE_PRE_STD_REC_TYPE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      INDEX BY BINARY_INTEGER;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
							    

PROCEDURE main (
           errbuf		OUT VARCHAR2,
           retcode		OUT VARCHAR2,
           p_batch_id		IN VARCHAR2,
           p_restart_flag	IN VARCHAR2,
           p_override_flag	IN VARCHAR2,
	   p_validate_and_load  IN VARCHAR2
   );


END xx_oe_sales_order_conv_pkg;
/


GRANT EXECUTE ON APPS.XX_OE_SALES_ORDER_CONV_PKG TO INTG_XX_NONHR_RO;
