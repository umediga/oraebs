DROP TABLE APPS.XXINTG_SO_DET_SUM_TEMP_TBL CASCADE CONSTRAINTS;

CREATE GLOBAL TEMPORARY TABLE APPS.XXINTG_SO_DET_SUM_TEMP_TBL
(
  HEADER_ID                    NUMBER,
  ORDER_NUMBER                 NUMBER,
  ORDERED_DATE                 DATE,
  CREATED_BY                   VARCHAR2(100 BYTE),
  ORDER_SOURCE                 VARCHAR2(240 BYTE),
  ORDER_STATUS                 VARCHAR2(30 BYTE),
  CUST_PO_NUMBER               VARCHAR2(50 BYTE),
  ORDER_TYPE                   VARCHAR2(30 BYTE),
  HEADER_CONTEXT               VARCHAR2(30 BYTE),
  ORIG_SYS_DOC_REF             VARCHAR2(50 BYTE),
  CASE_NO                      VARCHAR2(50 BYTE),
  DIV                          VARCHAR2(50 BYTE),
  LINE_ID                      NUMBER,
  LINE_NUMBER                  NUMBER,
  ORDERED_ITEM                 VARCHAR2(2000 BYTE),
  ITEM_DESCRIPTION             VARCHAR2(240 BYTE),
  ORGANIZATION_CODE            VARCHAR2(4 BYTE),
  ORDERED_QUANTITY             NUMBER,
  UNIT_SELLING_PRICE           NUMBER,
  EXT_PRICE                    NUMBER,
  LINE_STATUS                  VARCHAR2(30 BYTE),
  LINE_SUBINVENTORY            VARCHAR2(10 BYTE),
  LINE_LPN                     VARCHAR2(240 BYTE),
  LINE_LOT_NUMBER              VARCHAR2(240 BYTE),
  LOT_NUMBER                   VARCHAR2(80 BYTE),
  SERIAL_NUMBER                VARCHAR2(30 BYTE),
  SUBINVENTORY_CODE            VARCHAR2(10 BYTE),
  SERIAL_RESERVATION_QUANTITY  NUMBER,
  LOCATOR                      VARCHAR2(50 BYTE),
  LICENSE_PLATE_NUMBER         VARCHAR2(30 BYTE),
  HEADER_HOLD_NAME             VARCHAR2(2000 BYTE),
  LINE_HOLD_NAME               VARCHAR2(2000 BYTE),
  SOLD_TO_ORG_ID               NUMBER,
  SOLD_TO_ACCOUNT_NUMBER       VARCHAR2(30 BYTE),
  SOLD_TO_ACCOUNT_NAME         VARCHAR2(240 BYTE),
  SOLD_TO_COUNTRY              VARCHAR2(60 BYTE),
  SOLD_TO_STATE                VARCHAR2(60 BYTE),
  SHIP_TO_ACCOUNT_NUMBER       VARCHAR2(30 BYTE),
  SHIP_TO_ACCOUNT_NAME         VARCHAR2(240 BYTE),
  SHIP_TO_ADDRESS              VARCHAR2(240 BYTE),
  SHIP_TO_CITY                 VARCHAR2(60 BYTE),
  SHIP_TO_STATE                VARCHAR2(60 BYTE),
  POSTAL_CODE                  VARCHAR2(60 BYTE),
  COUNTRY                      VARCHAR2(60 BYTE),
  PARTY_SITE_NUMBER            VARCHAR2(30 BYTE),
  SURGEON_NAME                 VARCHAR2(500 BYTE),
  SURGERY_DATE                 VARCHAR2(240 BYTE),
  PATIENT_ID                   VARCHAR2(240 BYTE),
  INVENTORY_ITEM_ID            NUMBER,
  SHIP_FROM_ORG_ID             NUMBER,
  SALESREP                     VARCHAR2(1000 BYTE),
  TERRITORY                    VARCHAR2(1000 BYTE),
  REGION                       VARCHAR2(1000 BYTE),
  DIVISION                     VARCHAR2(40 BYTE),
  CCODE                        VARCHAR2(40 BYTE),
  PRODUCT_CLASS                VARCHAR2(240 BYTE),
  DCODE                        VARCHAR2(40 BYTE),
  PRODUCT_TYPE                 VARCHAR2(240 BYTE),
  INVOICE_NUMBER               VARCHAR2(20 BYTE),
  INVOICE_AMOUNT               NUMBER,
  INVOICE_DATE                 DATE,
  DELIVERY_DETAIL_ID           NUMBER,
  RELEASED_STATUS              VARCHAR2(1 BYTE),
  OE_INTERFACED_FLAG           VARCHAR2(1 BYTE),
  INV_INTERFACED_FLAG          VARCHAR2(1 BYTE),
  SHIPPED_QUANTITY             NUMBER,
  RECORD_NUMBER                NUMBER
)
ON COMMIT PRESERVE ROWS
NOCACHE;


CREATE INDEX APPS.XXINTG_SO_DET_SUM_TEMP_N1 ON APPS.XXINTG_SO_DET_SUM_TEMP_TBL
(ORDER_NUMBER, LINE_ID);

CREATE INDEX APPS.XXINTG_SO_DET_SUM_TEMP_N2 ON APPS.XXINTG_SO_DET_SUM_TEMP_TBL
(RECORD_NUMBER);