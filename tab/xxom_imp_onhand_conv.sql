DROP TABLE APPS.XXOM_IMP_ONHAND_CONV CASCADE CONSTRAINTS;

CREATE TABLE APPS.XXOM_IMP_ONHAND_CONV
(
  ORGANIZATION_CODE     VARCHAR2(10 BYTE),
  ITEM_CODE             VARCHAR2(35 BYTE),
  LICENSE_PLATE_NUMBER  VARCHAR2(30 BYTE),
  SERIAL_NUMBER         VARCHAR2(30 BYTE),
  SUBINVENTORY_CODE     VARCHAR2(30 BYTE),
  FROM_LOCATOR          VARCHAR2(30 BYTE),
  TO_ORGANIZATION_CODE  VARCHAR2(10 BYTE),
  TO_SUBINVENTORY_CODE  VARCHAR2(10 BYTE),
  TO_LOCATOR            VARCHAR2(30 BYTE)
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


GRANT SELECT ON APPS.XXOM_IMP_ONHAND_CONV TO XXAPPSREAD;