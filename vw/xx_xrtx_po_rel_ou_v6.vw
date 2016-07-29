DROP VIEW APPS.XX_XRTX_PO_REL_OU_V6;

/* Formatted on 6/6/2016 4:55:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REL_OU_V6
(
   OPERATING_UNIT,
   YEAR,
   APPROVED_COUNT
)
AS
     SELECT hou.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) approved_count
       FROM PO_RELEASES_ALL A, hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.release_type = 'BLANKET'
            AND a.authorization_status = 'APPROVED'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;