DROP VIEW APPS.XX_XRTX_ACTION_DAILY_V;

/* Formatted on 6/6/2016 4:57:57 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_ACTION_DAILY_V
(
   TRANSACTION_ACTION,
   ORG_NAME,
   TRANSACTION_DAY,
   YEAR,
   TRANSACTION_ACTION_COUNT
)
AS
     SELECT ml.meaning transaction_action,
            ood.ORGANIZATION_NAME ORG_NAME,
            TO_CHAR (transaction_date, 'D') transaction_day,
            TO_CHAR (mmt.transaction_date, 'YYYY') YEAR,
            COUNT (mmt.transaction_action_id) transaction_action_count
       FROM xx_xrtx_mmt_t mmt, mfg_lookups ml, org_organization_definitions ood
      WHERE     mmt.transaction_date BETWEEN TO_DATE (
                                                CONCAT (
                                                   '01-JAN-',
                                                   (  TO_CHAR (SYSDATE, 'YYYY')
                                                    - 3)),
                                                'DD-MON-YYYY')
                                         AND SYSDATE
            AND mmt.organization_id = ood.organization_id
            AND mmt.transaction_action_id = ml.lookup_code
            AND ml.lookup_type = 'MTL_TRANSACTION_ACTION'
   GROUP BY TO_CHAR (transaction_date, 'D'),
            ml.meaning,
            ood.ORGANIZATION_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY');
