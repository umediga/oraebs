DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_V9;

/* Formatted on 6/6/2016 4:54:27 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_V9
(
   OPERATING_UNIT,
   YEAR,
   SYSTEM_SAVED_COUNT
)
AS
     SELECT hou.name operating_unit,
            TO_CHAR (a.creation_date, 'YYYY') year,
            COUNT (*) system_saved_count
       FROM po_requisition_headers_all A, hr_all_organization_units hou
      WHERE     A.type_lookup_code = 'INTERNAL'
            AND a.authorization_status = 'SYSTEM_SAVED'
            AND A.org_id = hou.organization_id
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME, TO_CHAR (A.creation_date, 'YYYY')
   ORDER BY 2 DESC;
