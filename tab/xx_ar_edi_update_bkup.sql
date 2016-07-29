DROP TABLE APPS.XX_AR_EDI_UPDATE_BKUP CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_AR_EDI_UPDATE_BKUP
(
  SEQ_NO        VARCHAR2(100 BYTE),
  TRANS_CODE    VARCHAR2(200 BYTE),
  ACC_NO        VARCHAR2(200 BYTE),
  EDI_LOC_CODE  VARCHAR2(200 BYTE),
  ORIG_SYS_REF  VARCHAR2(200 BYTE),
  STATUS_CODE   VARCHAR2(10 BYTE),
  ERR_MSG       VARCHAR2(200 BYTE)
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