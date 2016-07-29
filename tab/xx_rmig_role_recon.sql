DROP TABLE APPS.XX_RMIG_ROLE_RECON CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_RMIG_ROLE_RECON
(
  ROLE_CATEGORY        VARCHAR2(30 BYTE)        NOT NULL,
  USER_ROLE_NAME       VARCHAR2(360 BYTE),
  ROLE_KEY             VARCHAR2(320 BYTE)       NOT NULL,
  RESPONSIBILITY_NAME  VARCHAR2(100 BYTE)       NOT NULL,
  REQUEST_GROP_ID      NUMBER(15),
  REQUEST_GROUP_NAME   VARCHAR2(30 BYTE)
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