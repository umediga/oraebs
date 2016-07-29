DROP VIEW APPS.XX_XRTX_AR_TXN_SRC_V1;

/* Formatted on 6/6/2016 4:56:51 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_TXN_SRC_V1
(
   SOURCE_NAME,
   CREATION_DATE,
   TRANSACTION_NAME,
   TOTAL_COUNT
)
AS
     SELECT b.NAME source_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') creation_date,
            d.NAME transaction_name,
            COUNT (*) Total_count
       FROM RA_CUSTOMER_TRX_ALL A,
            ra_batch_sources_all b,
            RA_CUST_TRX_TYPES_ALL d
      WHERE     A.batch_source_id = b.batch_source_id
            AND b.batch_source_type = 'FOREIGN'
            AND a.cust_trx_type_id = d.cust_trx_type_id
            AND TRUNC (a.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY b.NAME, TO_CHAR (TRUNC (A.creation_date), 'YYYY'), d.NAME
   ORDER BY 2 DESC;
