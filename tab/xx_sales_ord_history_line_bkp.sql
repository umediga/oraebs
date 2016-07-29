DROP TABLE APPS.XX_SALES_ORD_HISTORY_LINE_BKP CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_SALES_ORD_HISTORY_LINE_BKP
(
  BATCH_ID                VARCHAR2(100 BYTE),
  RECORD_NUMBER           NUMBER,
  SOURCE_SYSTEM_NAME      VARCHAR2(100 BYTE),
  LINE_ID                 NUMBER                NOT NULL,
  HEADER_ID               NUMBER,
  SOURCE                  VARCHAR2(240 BYTE),
  SALES_ORDER_NUMBER      NUMBER                NOT NULL,
  ORDER_LINE_NUMBER       NUMBER                NOT NULL,
  REQUESTED_DATE          DATE,
  WAREHOUSE               VARCHAR2(240 BYTE),
  RMA_NUMBER              VARCHAR2(30 BYTE),
  RETURNED_DATE           DATE,
  ITEM                    VARCHAR2(240 BYTE),
  ITEM_DESCRIPTION        VARCHAR2(240 BYTE),
  ORDER_QUANTITY          NUMBER,
  UNIT_PRICE              NUMBER,
  TOTAL_PRICE             NUMBER,
  PRICE_LIST              VARCHAR2(240 BYTE),
  SHIPPED_QUANTITY        NUMBER,
  SCHEDULED_SHIPPED_DATE  DATE,
  LOT_NUMBER              VARCHAR2(30 BYTE),
  SERIAL_NUMBER           VARCHAR2(30 BYTE),
  SHIP_TO_NAME            VARCHAR2(240 BYTE),
  TRACKING_NUMBER         VARCHAR2(20 BYTE),
  BILL_TO_NAME            VARCHAR2(240 BYTE),
  ACTUAL_SHIP_DATE        DATE,
  INVOICE_NUMBER          VARCHAR2(100 BYTE),
  INVOICE_DATE            DATE,
  PATIENT_NAME            VARCHAR2(100 BYTE),
  LINE_CHARGES            NUMBER,
  LINE_TAX                NUMBER,
  LINE_TOTAL              NUMBER
)
TABLESPACE APPS_TS_TX_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;