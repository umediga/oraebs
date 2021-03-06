DROP TABLE APPS.XX_XRTX_HRWS_MODULE_CLS_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_HRWS_MODULE_CLS_T
(
  LOGIN_HOUR             VARCHAR2(20 BYTE),
  MODULE_CLASSIFICATION  VARCHAR2(100 BYTE),
  TOTAL_USAGE_COUNT      NUMBER,
  AVG_LOGIN_PER_HR       NUMBER,
  TOTAL_USAGE_MINS       NUMBER,
  AVG_MINS_USAGE         NUMBER
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
