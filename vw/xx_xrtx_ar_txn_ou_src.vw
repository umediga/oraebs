DROP VIEW APPS.XX_XRTX_AR_TXN_OU_SRC;

/* Formatted on 6/6/2016 4:57:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_TXN_OU_SRC
(
   OPERATING_UNIT,
   SOURCE_NAME,
   TRANSACTION_NAME,
   YEAR,
   CREATION_TYPE,
   TOTAL_TYPE,
   CREATION_DATE,
   A,
   B,
   C,
   D,
   E,
   F,
   G,
   H,
   I,
   J,
   K,
   L
)
AS
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Total' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          HR_ALL_ORGANIZATION_UNITS C,
          RA_CUST_TRX_TYPES_ALL D
    --ar_payment_schedules_all e
    WHERE     A.org_id = c.organization_id
          AND A.batch_source_id = b.batch_source_id
          AND B.BATCH_SOURCE_TYPE = 'FOREIGN'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
   --and e.customer_trx_id=a.customer_trx_id
   UNION ALL
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Incomplete' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          HR_ALL_ORGANIZATION_UNITS C,
          RA_CUST_TRX_TYPES_ALL D
    --ar_payment_schedules_all e
    WHERE     A.org_id = c.organization_id
          AND A.batch_source_id = b.batch_source_id
          AND b.batch_source_type = 'FOREIGN'
          AND A.complete_flag = 'N'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
   --and e.customer_trx_id=a.customer_trx_id
   UNION ALL
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Open' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          hr_all_organization_units c,
          RA_CUST_TRX_TYPES_ALL D,
          ar_payment_schedules_all e
    WHERE     A.org_id = c.organization_id
          AND A.batch_source_id = b.batch_source_id
          AND B.BATCH_SOURCE_TYPE = 'FOREIGN'
          AND e.status = 'OP'
          AND A.complete_flag <> 'N'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
          AND e.customer_trx_id = a.customer_trx_id
   UNION ALL
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Close' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          hr_all_organization_units c,
          RA_CUST_TRX_TYPES_ALL D,
          ar_payment_schedules_all e
    WHERE     A.org_id = c.organization_id
          AND A.batch_source_id = b.batch_source_id
          AND B.BATCH_SOURCE_TYPE = 'FOREIGN'
          AND e.status = 'CL'
          AND A.complete_flag <> 'N'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
          AND e.customer_trx_id = a.customer_trx_id
   UNION ALL
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Total' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          HR_ALL_ORGANIZATION_UNITS C,
          RA_CUST_TRX_TYPES_ALL D
    --ar_payment_schedules_all e
    WHERE     A.org_id = c.organization_id
          AND A.batch_source_id = b.batch_source_id
          AND b.batch_source_type = 'INV'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
   --and e.customer_trx_id=a.customer_trx_id
   UNION ALL
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Incomplete' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          HR_ALL_ORGANIZATION_UNITS C,
          RA_CUST_TRX_TYPES_ALL D
    --ar_payment_schedules_all e
    WHERE     A.org_id = c.organization_id
          AND A.batch_source_id = b.batch_source_id
          AND b.batch_source_type = 'INV'
          AND A.complete_flag = 'N'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
   --and e.customer_trx_id=a.customer_trx_id
   UNION ALL
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Open' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          HR_ALL_ORGANIZATION_UNITS C,
          RA_CUST_TRX_TYPES_ALL D,
          ar_payment_schedules_all e
    WHERE     A.ORG_ID = C.ORGANIZATION_ID
          AND A.batch_source_id = b.batch_source_id
          AND b.batch_source_type = 'INV'
          AND e.status = 'OP'
          AND A.complete_flag <> 'N'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
          AND e.customer_trx_id = a.customer_trx_id
   UNION ALL
   SELECT c.NAME operating_unit,
          b.NAME source_name,
          d.NAME transaction_name,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Close' total_type,
          TRUNC (a.creation_date) creation_date,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM RA_CUSTOMER_TRX_ALL A,
          ra_batch_sources_all b,
          HR_ALL_ORGANIZATION_UNITS C,
          RA_CUST_TRX_TYPES_ALL D,
          ar_payment_schedules_all e
    WHERE     A.org_id = c.organization_id
          AND A.batch_source_id = b.batch_source_id
          AND B.BATCH_SOURCE_TYPE = 'INV'
          AND e.status = 'CL'
          AND A.complete_flag <> 'N'
          AND A.CUST_TRX_TYPE_ID = D.CUST_TRX_TYPE_ID
          AND e.customer_trx_id = a.customer_trx_id
   ORDER BY 1,
            2,
            5,
            6,
            4 DESC;
