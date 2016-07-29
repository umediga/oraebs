DROP VIEW APPS.XX_XRTX_PO_DOC_BUY_V27;

/* Formatted on 6/6/2016 4:56:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_BUY_V27
(
   OPERATING_UNIT,
   BUYER_NAME,
   YEAR,
   PRE_APPRROVED_COUNT
)
AS
     SELECT hou.NAME operating_unit,
            PAPF2.FULL_NAME Buyer_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            COUNT (*) pre_apprroved_count
       FROM po_headers_all A,
            per_all_people_F PAPF2,
            hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.agent_id = PAPF2.PERSON_ID
            AND A.type_lookup_code = 'PLANNED'
            AND a.authorization_status = 'PRE-APPROVED'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME,
            PAPF2.FULL_NAME,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 3 DESC;
