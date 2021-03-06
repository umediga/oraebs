DROP TABLE APPS.XX_TEMP_PROFILE CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_TEMP_PROFILE
(
  APPLICATION_ID            NUMBER              NOT NULL,
  PROFILE_OPTION_ID         NUMBER              NOT NULL,
  APPLICATION_NAME          VARCHAR2(240 BYTE)  NOT NULL,
  PROFILE_OPTION_NAME       VARCHAR2(80 BYTE)   NOT NULL,
  USER_PROFILE_OPTION_NAME  VARCHAR2(240 BYTE)  NOT NULL,
  DESCRIPTION               VARCHAR2(240 BYTE),
  HIERARCHY_TYPE            VARCHAR2(8 BYTE)
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
