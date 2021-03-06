DROP TABLE APPS.XX_XRTX_ITEM_INV_DATA_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_ITEM_INV_DATA_T
(
  ORGANIZATION_ID         NUMBER,
  MASTER_ORGANIZATION_ID  NUMBER,
  SHORT_CODE              VARCHAR2(30 BYTE),
  DESCRIPTION             VARCHAR2(50 BYTE),
  ITEMS_DEFINED_INV_ORG   NUMBER,
  ITEMS_MANUALLY_CREATED  NUMBER(30),
  ITEMS_ITERFACE_CREATED  NUMBER(30)
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
