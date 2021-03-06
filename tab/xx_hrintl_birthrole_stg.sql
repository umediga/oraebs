DROP TABLE APPS.XX_HRINTL_BIRTHROLE_STG CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_HRINTL_BIRTHROLE_STG
(
  ROLE_TO_GRANT     VARCHAR2(600 BYTE),
  USERNAME_CORRECT  VARCHAR2(300 BYTE),
  USERNAME_JULY23   VARCHAR2(300 BYTE),
  EMPLOYEE_NUMBER   NUMBER,
  LAST_NAME         VARCHAR2(300 BYTE),
  FIRST_NAME        VARCHAR2(300 BYTE),
  PERSON_TYPE       VARCHAR2(300 BYTE),
  WORK_COUNTRY      VARCHAR2(300 BYTE),
  WORK_LOCATION     VARCHAR2(300 BYTE),
  ERROR_MESSAGE     VARCHAR2(2000 BYTE),
  STATUS_CODE       VARCHAR2(30 BYTE),
  EXTRA_ATTRIBUTE1  VARCHAR2(150 BYTE),
  EXTRA_ATTRIBUTE2  VARCHAR2(150 BYTE),
  EXTRA_ATTRIBUTE3  VARCHAR2(150 BYTE),
  EXTRA_ATTRIBUTE4  VARCHAR2(150 BYTE),
  EXTRA_ATTRIBUTE5  VARCHAR2(150 BYTE)
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
