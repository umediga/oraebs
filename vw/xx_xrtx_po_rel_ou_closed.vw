DROP VIEW APPS.XX_XRTX_PO_REL_OU_CLOSED;

/* Formatted on 6/6/2016 4:55:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REL_OU_CLOSED
(
   OPERATING_UNIT,
   YEAR,
   CLOSED_COUNT
)
AS
     SELECT hou.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) closed_count
       FROM PO_RELEASES_ALL A, hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND release_type = 'BLANKET'
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
   GROUP BY hou.NAME, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;
