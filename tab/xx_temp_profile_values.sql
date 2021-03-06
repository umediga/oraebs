DROP TABLE APPS.XX_TEMP_PROFILE_VALUES CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_TEMP_PROFILE_VALUES
(
  PROFILE_OPTION_NAME   VARCHAR2(80 BYTE)       NOT NULL,
  SITE_LEVEL            VARCHAR2(4 BYTE),
  APPLICATION_LEVEL     VARCHAR2(50 BYTE),
  RESPONSIBILITY_LEVEL  VARCHAR2(100 BYTE),
  USER_LEVEL            VARCHAR2(100 BYTE),
  PROFILE_OPTION_VALUE  VARCHAR2(240 BYTE),
  LEVEL_VALUE_FOR_APPS  VARCHAR2(50 BYTE)
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
