DROP VIEW APPS.XX_XRTX_OM_TXN_OU_CNT;

/* Formatted on 6/6/2016 4:56:36 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_OM_TXN_OU_CNT
(
   OPERATING_UNIT,
   CREATION_DATE,
   YEAR,
   IMPORT_COUNT,
   MANUAL_COUNT
)
AS
     SELECT b.NAME operating_unit,
            TRUNC (A.creation_date) creation_date,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            COUNT (*) IMPORT_COUNT,
            NULL MANUAL_count
       FROM oe_order_headers_all A,
            hr_all_organization_units b,
            OE_ORDER_SOURCES c
      WHERE     A.org_id = b.organization_id
            AND A.order_source_id = c.order_source_id
            AND c.NAME NOT IN ('Online', 'Copy')
   GROUP BY b.NAME,
            TRUNC (A.creation_date),
            TO_CHAR (TRUNC (A.creation_date), 'YYYY'),
            NULL
   UNION
     SELECT b.NAME operating_unit,
            TRUNC (A.creation_date) creation_date,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            NULL,
            COUNT (*)
       FROM oe_order_headers_all A,
            hr_all_organization_units b,
            OE_ORDER_SOURCES c
      WHERE     A.org_id = b.organization_id
            AND A.order_source_id = c.order_source_id
            AND c.NAME IN ('Online', 'Copy')
   GROUP BY b.NAME,
            TRUNC (A.creation_date),
            TO_CHAR (TRUNC (A.creation_date), 'YYYY'),
            NULL;
