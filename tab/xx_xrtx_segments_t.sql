DROP TABLE APPS.XX_XRTX_SEGMENTS_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_SEGMENTS_T
(
  SEGMENT_NAME             VARCHAR2(30 BYTE)    NOT NULL,
  DESCRIPTION              VARCHAR2(240 BYTE),
  ENABLED_FLAG             VARCHAR2(1 BYTE)     NOT NULL,
  APPLICATION_COLUMN_NAME  VARCHAR2(30 BYTE)    NOT NULL,
  SEGMENT_NUM              NUMBER(3)            NOT NULL,
  DISPLAY_FLAG             VARCHAR2(1 BYTE)     NOT NULL,
  FORM_ABOVE_PROMPT        VARCHAR2(80 BYTE)    NOT NULL,
  FORM_LEFT_PROMPT         VARCHAR2(80 BYTE)    NOT NULL,
  FLEX_VALUE_SET_ID        NUMBER(10)           NOT NULL,
  FLEX_VALUE_SET_NAME      VARCHAR2(60 BYTE)    NOT NULL,
  ID_FLEX_NUM              NUMBER(15)           NOT NULL,
  ID_FLEX_CODE             VARCHAR2(4 BYTE)     NOT NULL,
  APPLICATION_ID           NUMBER(10)           NOT NULL,
  GL_BALANCING             VARCHAR2(200 BYTE),
  GL_MANAGEMENT            VARCHAR2(200 BYTE),
  FA_COST_CTR              VARCHAR2(200 BYTE),
  GL_SECONDARY_TRACKING    VARCHAR2(200 BYTE),
  GL_ACCOUNT               VARCHAR2(200 BYTE),
  GL_INTERCOMPANY          VARCHAR2(100 BYTE),
  GL_LEDGER                VARCHAR2(100 BYTE)
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