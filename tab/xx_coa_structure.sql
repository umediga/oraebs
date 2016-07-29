DROP TABLE APPS.XX_COA_STRUCTURE CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_COA_STRUCTURE
(
  COA_NAME                 VARCHAR2(200 BYTE),
  COA_ID                   NUMBER,
  SEGMENT_NUM              VARCHAR2(200 BYTE),
  SEGMENT_NAME             VARCHAR2(200 BYTE),
  APPLICATION_COLUMN_NAME  VARCHAR2(200 BYTE),
  DEFAULT_VALUE            VARCHAR2(200 BYTE),
  GL_BALANCING             VARCHAR2(200 BYTE),
  GL_MANAGEMENT            VARCHAR2(200 BYTE),
  FA_COST_CTR              VARCHAR2(200 BYTE),
  GL_SECONDARY_TRACKING    VARCHAR2(200 BYTE),
  GL_ACCOUNT               VARCHAR2(200 BYTE),
  GL_INTERCOMPANY          VARCHAR2(100 BYTE),
  GL_LEDGER                VARCHAR2(100 BYTE)
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