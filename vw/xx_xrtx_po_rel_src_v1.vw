DROP VIEW APPS.XX_XRTX_PO_REL_SRC_V1;

/* Formatted on 6/6/2016 4:55:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REL_SRC_V1
(
   SOURCE_NAME,
   YEAR,
   TOTAL_COUNT
)
AS
     SELECT a.document_creation_method source_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) total_count
       FROM PO_RELEASES_ALL A
      WHERE     A.release_type = 'BLANKET'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY A.document_creation_method,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;
