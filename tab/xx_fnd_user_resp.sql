DROP TABLE APPS.XX_FND_USER_RESP CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_FND_USER_RESP
(
  USER_NAME                VARCHAR2(50 BYTE),
  RESPONSIBILITY_NAME      VARCHAR2(100 BYTE),
  RESPONSIBILITY_KEY       VARCHAR2(100 BYTE),
  EMPLOYEE                 VARCHAR2(100 BYTE),
  EMPLOYEE_TYPE            VARCHAR2(100 BYTE),
  EMAIL_ADDRESS            VARCHAR2(100 BYTE),
  START_DATE               DATE,
  ATTRIBUTE1               VARCHAR2(100 BYTE),
  ATTRIBUTE2               VARCHAR2(100 BYTE),
  EMPLOYEE_ID              VARCHAR2(100 BYTE),
  ATTRIBUTE4               VARCHAR2(100 BYTE),
  ATTRIBUTE5               VARCHAR2(100 BYTE),
  NEW_RESPONSIBILITY_NAME  VARCHAR2(100 BYTE),
  NEW_RESP_KEY             VARCHAR2(35 BYTE),
  ROLE_NAME                VARCHAR2(100 BYTE),
  ROLE_KEY                 VARCHAR2(100 BYTE)
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


GRANT SELECT ON APPS.XX_FND_USER_RESP TO INTG_XX_NONHR_RO;