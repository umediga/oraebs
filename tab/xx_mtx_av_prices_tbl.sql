DROP TABLE APPS.XX_MTX_AV_PRICES_TBL CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_MTX_AV_PRICES_TBL
(
  ITEM               VARCHAR2(50 BYTE),
  NEW_ITEM           VARCHAR2(50 BYTE),
  INVENTORY_ITEM_ID  NUMBER,
  UOM                VARCHAR2(10 BYTE),
  PRICE              NUMBER,
  LINE_ORIG_REF      VARCHAR2(100 BYTE)
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
