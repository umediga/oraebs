DROP VIEW APPS.XX_XRTX_PO_REL_SRC_V3;

/* Formatted on 6/6/2016 4:55:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REL_SRC_V3
(
   SOURCE_NAME,
   YEAR,
   INPROCESS_COUNT
)
AS
     SELECT a.document_creation_method source_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) inprocess_count
       FROM PO_RELEASES_ALL A
      WHERE     A.release_type = 'BLANKET'
            AND a.authorization_status = 'IN PROCESS'
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
