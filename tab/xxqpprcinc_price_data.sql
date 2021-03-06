DROP TABLE APPS.XXQPPRCINC_PRICE_DATA CASCADE CONSTRAINTS;

CREATE GLOBAL TEMPORARY TABLE APPS.XXQPPRCINC_PRICE_DATA
(
  OPERAND             VARCHAR2(50 BYTE),
  PRODUCT_ATTR_VALUE  VARCHAR2(50 BYTE),
  LIST_HEADER_ID      NUMBER
)
ON COMMIT PRESERVE ROWS
NOCACHE;


CREATE INDEX APPS.XXQPPRC_INDEX_PRICE_DATA1 ON APPS.XXQPPRCINC_PRICE_DATA
(PRODUCT_ATTR_VALUE);

CREATE INDEX APPS.XXQPPRC_INDEX_PRICE_DATA2 ON APPS.XXQPPRCINC_PRICE_DATA
(LIST_HEADER_ID);
