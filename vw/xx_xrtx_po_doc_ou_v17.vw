DROP VIEW APPS.XX_XRTX_PO_DOC_OU_V17;

/* Formatted on 6/6/2016 4:55:53 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_OU_V17
(
   OPERATING_UNIT,
   YEAR,
   INPROCESS_COUNT
)
AS
     SELECT hou.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) inprocess_count
       FROM po_headers_all A, hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.type_lookup_code = 'CONTRACT'
            AND a.authorization_status = 'IN PROCESS'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;
