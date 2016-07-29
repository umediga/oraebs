DROP VIEW APPS.XX_XRTX_PO_DOC_OU_CANCEL3;

/* Formatted on 6/6/2016 4:56:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_OU_CANCEL3
(
   OPERATING_UNIT,
   YEAR,
   CANCEL_COUNT
)
AS
     SELECT hou.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) cancel_count
       FROM po_headers_all A, hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.type_lookup_code = 'PLANNED'
            AND A.authorization_status IS NOT NULL
            AND NVL (a.cancel_flag, 'N') <> 'N'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;
