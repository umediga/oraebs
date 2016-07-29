DROP VIEW APPS.XX_XRTX_PO_DOC_OU_CLOSED2;

/* Formatted on 6/6/2016 4:56:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_OU_CLOSED2
(
   OPERATING_UNIT,
   YEAR,
   CLOSED_COUNT
)
AS
     SELECT hou.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) closed_count
       FROM po_headers_all A, hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.type_lookup_code = 'CONTRACT'
            AND A.authorization_status IS NOT NULL
            AND NVL (A.closed_code, 'OPEN') IN ('CLOSED', 'FINALLY CLOSED')
            AND NVL (a.cancel_flag, 'N') = 'N'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.name, TO_CHAR (TRUNC (a.creation_date), 'YYYY')
   ORDER BY 2 DESC;
