DROP TABLE APPS.XX_ORD CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_ORD
(
  HEADER_ID           NUMBER                    NOT NULL,
  LINE_ID             NUMBER                    NOT NULL,
  ORDER_TYPE_NAME     VARCHAR2(30 BYTE)         NOT NULL,
  ORDER_NUMBER        NUMBER                    NOT NULL,
  ORDERED_DATE        DATE,
  ORDER_CURRENCY      VARCHAR2(15 BYTE),
  PARTY_NUMBER        VARCHAR2(30 BYTE)         NOT NULL,
  CUSTOMER_NAME       VARCHAR2(360 BYTE)        NOT NULL,
  CUSTOMER_NUMBER     VARCHAR2(30 BYTE)         NOT NULL,
  LINE_NUMBER         NUMBER                    NOT NULL,
  INVENTORY_ITEM_ID   NUMBER                    NOT NULL,
  ORDERED_ITEM        VARCHAR2(2000 BYTE),
  ORDER_QUANTITY_UOM  VARCHAR2(3 BYTE),
  ORDERED_QUANTITY    NUMBER,
  UNIT_SELLING_PRICE  NUMBER,
  LIST_PRICE          NUMBER
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
