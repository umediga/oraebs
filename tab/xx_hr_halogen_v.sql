DROP TABLE APPS.XX_HR_HALOGEN_V CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_HR_HALOGEN_V
(
  USER_NAME        VARCHAR2(100 BYTE),
  EMAIL_ADDRESS    VARCHAR2(240 BYTE),
  FIRST_NAME       VARCHAR2(150 BYTE),
  LAST_NAME        VARCHAR2(150 BYTE)           NOT NULL,
  PASSWORD         CHAR(8 BYTE),
  HIRE_DATE        DATE                         NOT NULL,
  JOB_TITLE        VARCHAR2(700 BYTE),
  DEPARTMENT       VARCHAR2(240 BYTE),
  SUPERVISOR_ID    VARCHAR2(100 BYTE),
  HR_REP           VARCHAR2(100 BYTE),
  LOCATION_CODE    VARCHAR2(60 BYTE),
  EMPLOYEE_NUMBER  VARCHAR2(30 BYTE),
  COUNTRY          VARCHAR2(60 BYTE)
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