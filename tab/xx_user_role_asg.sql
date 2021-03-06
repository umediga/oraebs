DROP TABLE APPS.XX_USER_ROLE_ASG CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_USER_ROLE_ASG
(
  USER_NAME        VARCHAR2(100 BYTE),
  NAME             VARCHAR2(200 BYTE),
  ROLE_KEY         VARCHAR2(200 BYTE),
  FLAG             VARCHAR2(10 BYTE),
  STATUS           VARCHAR2(20 BYTE),
  RKEY             VARCHAR2(100 BYTE),
  APPL_SHORT_NAME  VARCHAR2(10 BYTE)
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
