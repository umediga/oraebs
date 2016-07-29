DROP VIEW APPS.XX_XRTX_PO_DOC_BUY_V9;

/* Formatted on 6/6/2016 4:56:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_BUY_V9
(
   OPERATING_UNIT,
   BUYER_NAME,
   YEAR,
   INCOMPLETE_COUNT
)
AS
     SELECT hou.NAME operating_unit,
            PAPF2.FULL_NAME Buyer_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            COUNT (*) incomplete_count
       FROM po_headers_all A,
            per_all_people_F PAPF2,
            hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.agent_id = PAPF2.PERSON_ID
            AND A.type_lookup_code = 'BLANKET'
            AND a.authorization_status = 'INCOMPLETE'
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
