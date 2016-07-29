DROP VIEW APPS.XX_XRTX_PO_REL_OU_SRC_V4;

/* Formatted on 6/6/2016 4:55:10 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REL_OU_SRC_V4
(
   OPERATING_UNIT,
   SOURCE_NAME,
   YEAR,
   REQ_REAPPROVAL_COUNT
)
AS
     SELECT hou.name operating_unit,
            a.document_creation_method source_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) req_reapproval_count
       FROM PO_RELEASES_ALL A, hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.release_type = 'BLANKET'
            AND a.authorization_status = 'REQUIRES REAPPROVAL'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME,
            a.document_creation_method,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 3 DESC;
