DROP TABLE APPS.XX_XTRX_CUST_WF_EXEC_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XTRX_CUST_WF_EXEC_T
(
  EXECUTION_COUNT         NUMBER,
  ACTIVITY_NAME           VARCHAR2(30 BYTE),
  ITEM_TYPE_DISPLAY_NAME  VARCHAR2(80 BYTE),
  ITEM_TYPE               VARCHAR2(8 BYTE)
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