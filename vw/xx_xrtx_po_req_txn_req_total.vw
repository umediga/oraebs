DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_REQ_TOTAL;

/* Formatted on 6/6/2016 4:54:22 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_REQ_TOTAL
(
   REQUESTOR_NAME,
   YEAR,
   TOTAL_COUNT
)
AS
     SELECT PAPF2.FULL_NAME requestor_name,
            TO_CHAR (A.creation_date, 'YYYY') YEAR,
            COUNT (*) Total_count
       FROM po_requisition_headers_all A,
            po_requisition_lines_all b,
            per_people_x PAPF2
      WHERE     A.type_lookup_code = 'INTERNAL'
            AND A.requisition_header_id = b.requisition_header_id
            AND papf2.person_id = a.preparer_id
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY PAPF2.FULL_NAME, TO_CHAR (A.creation_date, 'YYYY')
   ORDER BY 2 DESC;
