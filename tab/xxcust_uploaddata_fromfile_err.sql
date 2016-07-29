DROP TABLE APPS.XXCUST_UPLOADDATA_FROMFILE_ERR CASCADE CONSTRAINTS;

CREATE GLOBAL TEMPORARY TABLE APPS.XXCUST_UPLOADDATA_FROMFILE_ERR
(
  RECORD_ID   NUMBER,
  ERR_MSG     VARCHAR2(4000 BYTE),
  ERR_DATA    VARCHAR2(4000 BYTE),
  PROCESS_ID  NUMBER
)
ON COMMIT PRESERVE ROWS
NOCACHE;


GRANT SELECT ON APPS.XXCUST_UPLOADDATA_FROMFILE_ERR TO INTG_XX_NONHR_RO;