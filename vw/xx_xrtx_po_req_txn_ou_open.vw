DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_OPEN;

/* Formatted on 6/6/2016 4:54:57 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_OPEN
(
   OPERATING_UNIT,
   YEAR,
   OPEN_COUNT
)
AS
     SELECT hou.name operating_unit,
            TO_CHAR (a.creation_date, 'YYYY') year,
            COUNT (*) open_count
       FROM po_requisition_headers_all a, hr_all_organization_units hou
      WHERE     type_lookup_code = 'INTERNAL'
            AND NVL (A.closed_code, 'OPEN') != 'FINALLY CLOSED'
            AND NVL (a.cancel_flag, 'N') = 'N'
            AND A.org_id = hou.organization_id
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.name, TO_CHAR (a.creation_date, 'YYYY')
   ORDER BY 2 DESC;
