DROP TABLE APPS.XX_M2C_SALESREP_TERR_DATA_Q CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_M2C_SALESREP_TERR_DATA_Q
(
  TERR_ID          NUMBER,
  RANK             NUMBER,
  TERR_NAME        VARCHAR2(2000 BYTE),
  SELECT_FLAG      VARCHAR2(1 BYTE),
  UNIQUE_FLAG      VARCHAR2(1 BYTE),
  QUALIFIER_NAME   VARCHAR2(2000 BYTE),
  QUALIFIER_VALUE  VARCHAR2(2000 BYTE)
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
