DROP TABLE APPS.XX_CAR_DEBUG CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_CAR_DEBUG
(
  A  VARCHAR2(100 BYTE),
  B  VARCHAR2(1000 BYTE),
  C  DATE
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