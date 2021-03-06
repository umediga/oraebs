DROP TABLE APPS.XX_XRTX_DB_SCHEMA_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_DB_SCHEMA_T
(
  USERNAME                     VARCHAR2(30 BYTE) NOT NULL,
  USER_ID                      NUMBER           NOT NULL,
  PASSWORD                     VARCHAR2(30 BYTE),
  ACCOUNT_STATUS               VARCHAR2(32 BYTE) NOT NULL,
  LOCK_DATE                    DATE,
  EXPIRY_DATE                  DATE,
  DEFAULT_TABLESPACE           VARCHAR2(30 BYTE) NOT NULL,
  TEMPORARY_TABLESPACE         VARCHAR2(30 BYTE) NOT NULL,
  CREATED                      DATE             NOT NULL,
  PROFILE                      VARCHAR2(30 BYTE) NOT NULL,
  INITIAL_RSRC_CONSUMER_GROUP  VARCHAR2(30 BYTE)
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
