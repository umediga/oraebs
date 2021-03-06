DROP TABLE APPS.XX_CONSG_MTI_TBL CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_CONSG_MTI_TBL
(
  FROMINTEGRAID          NUMBER,
  FROMREPNAME            VARCHAR2(100 BYTE),
  FROMSETSERIALNUMBER    VARCHAR2(100 BYTE),
  TOINTEGRAID            NUMBER,
  TOREPNAME              VARCHAR2(100 BYTE),
  TOSETSERIALNUMBER      VARCHAR2(100 BYTE),
  PACKLISTID             NUMBER,
  TRANSFERGROUPID        NUMBER,
  TRANSACTION_REFERENCE  VARCHAR2(100 BYTE)
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


GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_CONSG_MTI_TBL TO XXAPPSREAD;
