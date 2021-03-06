DROP TABLE APPS.XX_XRTX_INTERFACE_ERRORS_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_INTERFACE_ERRORS_T
(
  ERROR_COUNT        NUMBER,
  ORGANIZATION_CODE  VARCHAR2(3 BYTE),
  ERROR_INTERFACE    VARCHAR2(30 BYTE),
  ERROR_CODE         VARCHAR2(240 BYTE),
  ERROR_MESSAGE      VARCHAR2(2000 BYTE)
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
