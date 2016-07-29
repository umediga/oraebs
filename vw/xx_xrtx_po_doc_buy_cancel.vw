DROP VIEW APPS.XX_XRTX_PO_DOC_BUY_CANCEL;

/* Formatted on 6/6/2016 4:56:29 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_BUY_CANCEL
(
   BUYER_NAME,
   YEAR,
   CANCEL_COUNT
)
AS
     SELECT PAPF2.FULL_NAME Buyer_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) cancel_count
       FROM po_headers_all A, per_all_people_F PAPF2
      WHERE     A.agent_id = PAPF2.PERSON_ID
            AND A.type_lookup_code = 'STANDARD'
            AND A.authorization_status IS NOT NULL
            AND NVL (a.cancel_flag, 'N') <> 'N'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY PAPF2.FULL_NAME, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;
