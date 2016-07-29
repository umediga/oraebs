DROP PACKAGE APPS.XX_CN_INV_EXTRACT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CN_INV_EXTRACT_PKG" AUTHID CURRENT_USER
AS
/* $Header: XXCNINVEXTRACT.pks 1.0.0 2012/05/18 00:00:00 dsur noship $ */
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 21-Sep-2012
 File Name     : XXCNINVEXTRACT.pks
 Description   : This script creates the specification of the package
                 xx_cn_inv_extract_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 21-Sep-2012  IBM Development Team   Initial development.
*/
----------------------------------------------------------------------


g_total_cnt     NUMBER ;
g_error_cnt     NUMBER ;
g_success_cnt   NUMBER ;
g_warn_cnt      NUMBER ;

--------
TYPE G_XX_INV_EXT_REC_TYPE  IS RECORD
   (INVOICE_NUMBER             VARCHAR2(20),
   OIC_PROCESSED_DATE         DATE,
   INVOICE_DATE               DATE,
   ORDER_NUMBER               NUMBER,
   HEADER_ID                  NUMBER,
   INVENTORY_ITEM_ID          NUMBER,
   ORDER_LINE_NUMBER          NUMBER,
   ORDER_LINE_ID              NUMBER,
   ITEM_NUMBER                VARCHAR2(40),
   DESCRIPTION                VARCHAR2(240),
   INTG_ORG_ID                NUMBER,
   ORGANIZATION_CODE          VARCHAR2(3),
   ORGANIZATION_ID            NUMBER(15),
   OPERATING_UNIT             NUMBER,
   WAREHOUSE_NAME             VARCHAR2(240),
   PARTY_ID                   NUMBER(15),
   PARTY_NUMBER               VARCHAR2(30),
   CUSTOMER_NAME              VARCHAR2(360),
   MATERIAL_NUMBER            VARCHAR2(60),
   UNIT_SELLING_PRICE         NUMBER,
   UNIT_LIST_PRICE            NUMBER,
   ITEM_COST                  NUMBER,
   ORDERED_QUANTITY           NUMBER,
   QUANTITY_SHIPPED           NUMBER,
   UOM                        VARCHAR2(3),
   UNIT_DIFF                  NUMBER,
   TRANSACTION_AMOUNT         NUMBER,
   CANCELLED_QUANTITY         NUMBER,
   SHIPPING_QUANTITY          NUMBER,
   TRANSACTION_TYPE_ID        NUMBER,
   SHIP_FROM_ORG_ID           NUMBER,
   BILL_TO_ADDRESS_ID         NUMBER(15),
   SHIP_TO_ADDRESS_ID         NUMBER(15),
   BILL_TO_CONTACT_ID         NUMBER(15),
   SHIP_TO_CONTACT_ID         NUMBER(15),
   CREATION_DATE              DATE,
   LINE_TYPE_ID               NUMBER,
   PRICE_LIST_ID              NUMBER,
   DIVISION                   VARCHAR2(40),
   SUB_DIVISION               VARCHAR2(40),
   CONTRACT_CATEGORY          VARCHAR2(40),
   BRAND                      VARCHAR2(40),
   PRODUCT_CLASS              VARCHAR2(40),
   PRODUCT_TYPE               VARCHAR2(40),
   DCODE                      VARCHAR2(40),
   INVENTORY_ITEM_STATUS_CODE VARCHAR2(10),
   CURRENCY                   VARCHAR2(15),
   ORDER_TYPE                 VARCHAR2(30),
   CUST_ACCOUNT_ID            NUMBER (15),
   ACCOUNT_NAME               VARCHAR2(240),
   ACCOUNT_NUMBER             VARCHAR2(30),
   ORDER_DATE                 DATE,
   ORDER_HEADER_ID            NUMBER,
   CONVERSION_RATE            NUMBER,
   CONVERSION_TYPE_CODE       VARCHAR2(30),
   HEADER_SALESREP_ID         NUMBER(15),
   ORIG_BOOK_SALESREP_ID      NUMBER,
   ORIG_BOOK_SALESREP_NUM     NUMBER,
   ORIG_BOOK_SALESREP_NAME    VARCHAR2(360),
   CRM_SALESREP_NAME          VARCHAR2(360),
   HEADER_SHIP_COUNTRY_ID     NUMBER,
   CUSTOMER_TRX_ID            NUMBER(15),
   CUST_PO_NUMBER             VARCHAR2(50),
   CUSTOMER_TRX_LINE_ID       NUMBER(15),
   PRIMARY_SALESREP_ID        NUMBER(15),
   LINE_SALESREP_ID           NUMBER(15),
   CUST_TRX_LINE_SALESREP_ID  NUMBER (15),
   HEADER_SHIP_COUNTRY_NAME   VARCHAR2(80),
   LATEST_SALESREP_ID         NUMBER(15),
   EMPLOYEE_NUMBER            VARCHAR2(30),
   EMPLOYEE_NAME              VARCHAR2(360),
   SALESREP_NUMBER            VARCHAR2(30),
   SALES_ORDER                VARCHAR2(50),
   SALES_ORDER_LINE           VARCHAR2(30),
   SET_OF_BOOKS_ID            NUMBER(15),
   REVENUE_AMOUNT             NUMBER,
   EXTENDED_AMOUNT            NUMBER,
   QUANTITY_INVOICED          NUMBER,
   QUANTITY_ORDERED           NUMBER,
   UNIT_STANDARD_PRICE        NUMBER,
   REVENUE_TYPE               VARCHAR2(10),
   SPLIT_PCT                  NUMBER,
   INTG_RECORD_ID             NUMBER(15),
   TERRITORIES_NAME           VARCHAR2(2000),
   REG_TERRITORIES_NAME       VARCHAR2(2000),
   AREA_TERRITORIES_NAME      VARCHAR2(2000),
   SALES_CREDIT_ID            NUMBER,
   SALES_CREATION_DATE        DATE,
   SALES_HEADER_ID            NUMBER,
   SALESREP_ID                NUMBER(15),
   PERCENT                    NUMBER,
   LINE_ID                    NUMBER,
   CONTEXT                    VARCHAR2(240),
   ORIG_SYS_CREDIT_REF        VARCHAR2(50),
   SALES_CREDIT_TYPE_ID       NUMBER,
   SALES_GROUP_ID             NUMBER,
   SALES_GROUP_UPDATED_FLAG  VARCHAR2(1),
   LATTEST_FLAG              VARCHAR2(1),
   TERR_ID                   NUMBER,
   TRANSACTION_TYPE_NAME     VARCHAR2(20),
   TRAN_TYPE_DESCRIPTION     VARCHAR2(80),
   TRANSACTION_TYPE          VARCHAR2(20),
   POST_TO_GL                VARCHAR2(1),
   ORDER_SOURCE_NAME         VARCHAR2(240),
   LINE_NUMBER               NUMBER,
   SALES_CHANNEL_CODE        VARCHAR2(30),
   PRICE_LIST_NAME           VARCHAR2(240),
   PROG_CREATION_DATE        DATE,
   CREATED_BY                NUMBER,
   LAST_UPDATE_DATE          DATE,
   LAST_UPDATED_BY           NUMBER,
   LAST_UPDATE_LOGIN         NUMBER,
   REQUEST_ID                NUMBER
   );

-----Invoice table type

TYPE g_xx_inv_ext_tab_type IS TABLE OF G_XX_INV_EXT_REC_TYPE
     INDEX BY BINARY_INTEGER;


PROCEDURE xx_insert_record (o_errbuf OUT VARCHAR2,
                            o_retcode OUT VARCHAR2);

PROCEDURE update_record_count;


END xx_cn_inv_extract_pkg;
/
