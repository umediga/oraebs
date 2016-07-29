DROP TABLE APPS.XX_XRTX_CONPRG_DATE CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_CONPRG_DATE
(
  START_DATE  VARCHAR2(40 BYTE),
  END_DATE    VARCHAR2(40 BYTE)
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