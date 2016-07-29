DROP VIEW APPS.XX_XRTX_TYPE_DAILY_V;

/* Formatted on 6/6/2016 4:54:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_TYPE_DAILY_V
(
   TRANSACTION_TYPE,
   TRANSACTION_DAY,
   ORG_NAME,
   YEAR,
   TRANSACTION_TYPE_COUNT
)
AS
     SELECT mtt.TRANSACTION_TYPE_NAME transaction_type,
            TO_CHAR (transaction_date, 'D') transaction_day,
            ood.ORGANIZATION_NAME ORG_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY') YEAR,
            COUNT (mmt.TRANSACTION_TYPE_ID) transaction_type_count
       FROM xx_xrtx_mmt_t mmt,
            mtl_transaction_types mtt,
            org_organization_definitions ood
      WHERE     mmt.organization_id = ood.organization_id
            AND mmt.transaction_type_id = mtt.TRANSACTION_TYPE_ID
            AND mmt.transaction_date BETWEEN TO_DATE (
                                                CONCAT (
                                                   '01-JAN-',
                                                   (  TO_CHAR (SYSDATE, 'YYYY')
                                                    - 3)),
                                                'DD-MON-YYYY')
                                         AND SYSDATE
   GROUP BY TO_CHAR (transaction_date, 'D'),
            mtt.TRANSACTION_TYPE_NAME,
            ood.ORGANIZATION_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY');
