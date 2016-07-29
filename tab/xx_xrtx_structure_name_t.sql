DROP TABLE APPS.XX_XRTX_STRUCTURE_NAME_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_STRUCTURE_NAME_T
(
  ID_FLEX_NUM                     NUMBER(15)    NOT NULL,
  ID_FLEX_CODE                    VARCHAR2(4 BYTE) NOT NULL,
  ID_FLEX_NAME                    VARCHAR2(30 BYTE) NOT NULL,
  APPLICATION_ID                  NUMBER(10)    NOT NULL,
  ID_FLEX_STRUCTURE_CODE          VARCHAR2(30 BYTE) NOT NULL,
  ID_FLEX_STRUCTURE_NAME          VARCHAR2(30 BYTE) NOT NULL,
  DESCRIPTION                     VARCHAR2(240 BYTE),
  CONCATENATED_SEGMENT_DELIMITER  VARCHAR2(1 BYTE) NOT NULL,
  CROSS_SEGMENT_VALIDATION_FLAG   VARCHAR2(1 BYTE) NOT NULL,
  DYNAMIC_INSERTS_ALLOWED_FLAG    VARCHAR2(1 BYTE) NOT NULL,
  ENABLED_FLAG                    VARCHAR2(1 BYTE) NOT NULL,
  FREEZE_FLEX_DEFINITION_FLAG     VARCHAR2(1 BYTE) NOT NULL,
  FREEZE_STRUCTURED_HIER_FLAG     VARCHAR2(1 BYTE) NOT NULL,
  STRUCTURE_VIEW_NAME             VARCHAR2(30 BYTE)
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
