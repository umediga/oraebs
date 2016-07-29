DROP VIEW APPS.XX_XRTX_OM_TXN_SRC_CNT;

/* Formatted on 6/6/2016 4:56:35 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_OM_TXN_SRC_CNT
(
   SOURCE_NAME,
   CREATION_DATE,
   YEAR,
   IMPORT_COUNT,
   MANUAL_COUNT
)
AS
     SELECT c.NAME source_name,
            TRUNC (A.creation_date) creation_date,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            COUNT (*) IMPORT_COUNT,
            NULL MANUAL_count
       FROM oe_order_headers_all A, OE_ORDER_SOURCES c
      WHERE     A.order_source_id = c.order_source_id
            AND c.NAME NOT IN ('Online', 'Copy')
   GROUP BY c.NAME,
            TRUNC (A.creation_date),
            TO_CHAR (TRUNC (A.creation_date), 'YYYY'),
            NULL
   UNION
     SELECT c.NAME source_name,
            TRUNC (A.creation_date) creation_date,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            NULL,
            COUNT (*)
       FROM oe_order_headers_all A, OE_ORDER_SOURCES c
      WHERE     A.order_source_id = c.order_source_id
            AND c.NAME IN ('Online', 'Copy')
   GROUP BY c.NAME,
            TRUNC (A.creation_date),
            TO_CHAR (TRUNC (A.creation_date), 'YYYY'),
            NULL;
