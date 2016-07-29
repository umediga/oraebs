DROP VIEW APPS.XX_XRTX_HR_SOURCE_V;

/* Formatted on 6/6/2016 4:56:41 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_HR_SOURCE_V
(
   TRANSACTION_SOURCE_TYPE_NAME,
   TRANSACTION_HOUR,
   ORG_NAME,
   YEAR,
   TRANSACTION_SOURCE_COUNT
)
AS
     SELECT mtst.transaction_source_type_name,
            TO_CHAR (mmt.transaction_date, 'HH24') transaction_hour,
            ood.ORGANIZATION_NAME ORG_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY') YEAR,
            COUNT (mmt.transaction_source_type_id) transaction_source_count
       FROM xx_xrtx_mmt_t mmt,
            MTL_TXN_SOURCE_TYPES mtst,
            org_organization_definitions ood
      WHERE     mmt.transaction_date BETWEEN TO_DATE (
                                                CONCAT (
                                                   '01-JAN-',
                                                   (  TO_CHAR (SYSDATE, 'YYYY')
                                                    - 3)),
                                                'DD-MON-YYYY')
                                         AND SYSDATE
            AND mmt.organization_id = ood.organization_id
            AND mmt.transaction_source_type_id =
                   mtst.transaction_source_type_id
   GROUP BY TO_CHAR (mmt.transaction_date, 'HH24'),
            mtst.transaction_source_type_name,
            ood.ORGANIZATION_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY');
