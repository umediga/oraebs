DROP VIEW APPS.XX_XRTX_PO_REL_BUY_TOTAL;

/* Formatted on 6/6/2016 4:55:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REL_BUY_TOTAL
(
   BUYER_NAME,
   YEAR,
   TOTAL_COUNT
)
AS
     SELECT papf2.full_name Buyer_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) total_count
       FROM po_releases_all A, per_all_people_F PAPF2
      WHERE     A.agent_id = PAPF2.PERSON_ID
            AND release_type = 'BLANKET'
            AND A.authorization_status IS NOT NULL
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY papf2.full_name, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;
