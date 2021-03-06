DROP TABLE APPS.XXINTG_MIG_SCRIPT_RESP CASCADE CONSTRAINTS;

CREATE TABLE APPS.XXINTG_MIG_SCRIPT_RESP
(
  RESP_SEQUENCE  NUMBER,
  ROLE_CODE      VARCHAR2(50 BYTE),
  RESP_NAME      VARCHAR2(50 BYTE),
  RESP_CODE      VARCHAR2(50 BYTE),
  MIGRATED       VARCHAR2(1 BYTE)
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


CREATE UNIQUE INDEX APPS.XXINTG_MIG_SCRIPT_RESP_U1 ON APPS.XXINTG_MIG_SCRIPT_RESP
(ROLE_CODE, RESP_CODE)
LOGGING
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );

ALTER TABLE APPS.XXINTG_MIG_SCRIPT_RESP ADD (
  CONSTRAINT XXINTG_MIG_SCRIPT_RESP_U1
  UNIQUE (ROLE_CODE, RESP_CODE)
  USING INDEX APPS.XXINTG_MIG_SCRIPT_RESP_U1
  ENABLE VALIDATE);
