DROP VIEW APPS.XX_XRTX_AR_TXN_OU_SRC_V8;

/* Formatted on 6/6/2016 4:56:57 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_TXN_OU_SRC_V8
(
   OPERATING_UNIT,
   SOURCE_NAME,
   CREATION_DATE,
   TRANSACTION_NAME,
   CLOSE_CT
)
AS
     SELECT c.NAME operating_unit,
            b.NAME source_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') creation_date,
            d.NAME transaction_name,
            COUNT (*) close_ct
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
            AND E.CUSTOMER_TRX_ID = A.CUSTOMER_TRX_ID
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY C.NAME,
            B.NAME,
            TO_CHAR (TRUNC (A.CREATION_DATE), 'YYYY'),
            D.NAME
   ORDER BY 3 DESC;
