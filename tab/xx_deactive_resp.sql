DROP TABLE APPS.XX_DEACTIVE_RESP CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_DEACTIVE_RESP
(
  USER_NAME               VARCHAR2(100 BYTE)    NOT NULL,
  RESPONSIBILITY_KEY      VARCHAR2(30 BYTE)     NOT NULL,
  RESPONSIBILITY_NAME     VARCHAR2(100 BYTE)    NOT NULL,
  APPLICATION_SHORT_NAME  VARCHAR2(50 BYTE)     NOT NULL,
  STATUS                  VARCHAR2(1000 BYTE)
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
