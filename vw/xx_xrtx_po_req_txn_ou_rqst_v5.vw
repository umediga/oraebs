DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_RQST_V5;

/* Formatted on 6/6/2016 4:54:47 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_RQST_V5
(
   OPERATING_UNIT,
   REQUESTOR_NAME,
   YEAR,
   REJECTED_COUNT
)
AS
     SELECT hou.NAME operating_unit,
            PAPF2.FULL_NAME requestor_name,
            TO_CHAR (A.creation_date, 'YYYY') YEAR,
            COUNT (*) rejected_count
       FROM po_requisition_headers_all A,
            po_requisition_lines_all b,
            hr_all_organization_units hou,
            PER_ALL_PEOPLE_F PAPF2
      WHERE     A.type_lookup_code = 'INTERNAL'
            AND a.authorization_status = 'REJECTED'
            AND A.requisition_header_id = b.requisition_header_id
            AND A.org_id = hou.organization_id
            AND PAPF2.PERSON_ID = b.TO_PERSON_ID
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME, PAPF2.FULL_NAME, TO_CHAR (A.creation_date, 'YYYY')
   ORDER BY 3 DESC;
