DROP TABLE APPS.XXINTG_NEW_CANDIDATE_USER CASCADE CONSTRAINTS;

CREATE TABLE APPS.XXINTG_NEW_CANDIDATE_USER
(
  PERSON_ID         NUMBER,
  APPLICANT_NUMBER  VARCHAR2(100 BYTE),
  FULL_NAME         VARCHAR2(200 BYTE),
  USER_PERSON_TYPE  VARCHAR2(100 BYTE),
  UNIQUE_ID         VARCHAR2(100 BYTE),
  USER_NAME_EMAIL   VARCHAR2(200 BYTE),
  STATUS            VARCHAR2(100 BYTE),
  ATTRIBUTE1        VARCHAR2(100 BYTE),
  ATTRIBUTE2        VARCHAR2(100 BYTE),
  ATTRIBUTE3        VARCHAR2(100 BYTE)
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
