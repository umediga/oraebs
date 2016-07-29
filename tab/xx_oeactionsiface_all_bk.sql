DROP TABLE APPS.XX_OEACTIONSIFACE_ALL_BK CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_OEACTIONSIFACE_ALL_BK
(
  ORDER_SOURCE_ID        NUMBER,
  ORIG_SYS_DOCUMENT_REF  VARCHAR2(50 BYTE),
  ORIG_SYS_LINE_REF      VARCHAR2(50 BYTE),
  ORIG_SYS_SHIPMENT_REF  VARCHAR2(50 BYTE),
  CHANGE_SEQUENCE        VARCHAR2(50 BYTE),
  ORG_ID                 NUMBER,
  HOLD_ID                NUMBER,
  HOLD_TYPE_CODE         VARCHAR2(30 BYTE),
  HOLD_TYPE_ID           NUMBER,
  HOLD_UNTIL_DATE        DATE,
  RELEASE_REASON_CODE    VARCHAR2(30 BYTE),
  COMMENTS               VARCHAR2(2000 BYTE),
  CONTEXT                VARCHAR2(30 BYTE),
  ATTRIBUTE1             VARCHAR2(240 BYTE),
  ATTRIBUTE2             VARCHAR2(240 BYTE),
  ATTRIBUTE3             VARCHAR2(240 BYTE),
  ATTRIBUTE4             VARCHAR2(240 BYTE),
  ATTRIBUTE5             VARCHAR2(240 BYTE),
  ATTRIBUTE6             VARCHAR2(240 BYTE),
  ATTRIBUTE7             VARCHAR2(240 BYTE),
  ATTRIBUTE8             VARCHAR2(240 BYTE),
  ATTRIBUTE9             VARCHAR2(240 BYTE),
  ATTRIBUTE10            VARCHAR2(240 BYTE),
  ATTRIBUTE11            VARCHAR2(240 BYTE),
  ATTRIBUTE12            VARCHAR2(240 BYTE),
  ATTRIBUTE13            VARCHAR2(240 BYTE),
  ATTRIBUTE14            VARCHAR2(240 BYTE),
  ATTRIBUTE15            VARCHAR2(240 BYTE),
  REQUEST_ID             NUMBER,
  OPERATION_CODE         VARCHAR2(30 BYTE),
  ERROR_FLAG             VARCHAR2(1 BYTE),
  STATUS_FLAG            VARCHAR2(1 BYTE),
  INTERFACE_STATUS       VARCHAR2(1000 BYTE),
  FULFILLMENT_SET_NAME   VARCHAR2(30 BYTE),
  SOLD_TO_ORG            VARCHAR2(360 BYTE),
  SOLD_TO_ORG_ID         NUMBER,
  CHAR_PARAM1            VARCHAR2(2000 BYTE),
  CHAR_PARAM2            VARCHAR2(240 BYTE),
  CHAR_PARAM3            VARCHAR2(240 BYTE),
  CHAR_PARAM4            VARCHAR2(240 BYTE),
  CHAR_PARAM5            VARCHAR2(240 BYTE),
  DATE_PARAM1            DATE,
  DATE_PARAM2            DATE,
  DATE_PARAM3            DATE,
  DATE_PARAM4            DATE,
  DATE_PARAM5            DATE
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
