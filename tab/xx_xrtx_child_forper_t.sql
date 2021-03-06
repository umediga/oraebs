DROP TABLE APPS.XX_XRTX_CHILD_FORPER_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_CHILD_FORPER_T
(
  FORM_NAME            VARCHAR2(30 BYTE)        NOT NULL,
  USER_FORM_NAME       VARCHAR2(80 BYTE)        NOT NULL,
  SEQUENCE             NUMBER                   NOT NULL,
  FORM_ID              NUMBER                   NOT NULL,
  DESCRIPTION          VARCHAR2(255 BYTE)       NOT NULL,
  RULE_TYPE            VARCHAR2(1 BYTE),
  ENABLED              VARCHAR2(1 BYTE)         NOT NULL,
  TRIGGER_EVENT        VARCHAR2(30 BYTE)        NOT NULL,
  TRIGGER_OBJECT       VARCHAR2(100 BYTE),
  CONDITION            VARCHAR2(2000 BYTE),
  FIRE_IN_ENTER_QUERY  VARCHAR2(1 BYTE),
  CREATED_BY           VARCHAR2(100 BYTE)
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
