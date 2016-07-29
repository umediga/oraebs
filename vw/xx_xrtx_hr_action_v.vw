DROP VIEW APPS.XX_XRTX_HR_ACTION_V;

/* Formatted on 6/6/2016 4:56:41 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_HR_ACTION_V
(
   TRANSACTION_ACTION,
   TRANSACTION_HOUR,
   ORG_NAME,
   YEAR,
   TRANSACTION_ACTION_COUNT
)
AS
     SELECT ml.meaning Transaction_action,
            TO_CHAR (mmt.transaction_date, 'HH24') transaction_hour,
            ood.ORGANIZATION_NAME ORG_NAME,
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
   GROUP BY TO_CHAR (mmt.transaction_date, 'HH24'),
            ml.meaning,
            ood.ORGANIZATION_NAME,
            TO_CHAR (mmt.transaction_date, 'YYYY');
