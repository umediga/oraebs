DROP VIEW APPS.XX_CN_QRTR_BONS_TRGT_V;

/* Formatted on 6/6/2016 4:58:47 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_QRTR_BONS_TRGT_V
(
   SALESREP_ID,
   LAST_PERIOD_ID,
   ORG_ID,
   QRTR_BONUS_TARGET
)
AS
     SELECT cpq.salesrep_id,
            MAX (cpq.period_id) last_period_id,
            cpq.org_id,
            SUM ( (DECODE (target_amount, 0, 0, target_amount)))
               qrtr_bonus_target
       FROM cn_srp_period_quotas cpq, cn_quotas cq, xx_cn_periods_v xcpv
      WHERE     cpq.quota_id = cq.quota_id
            AND cpq.org_id = xcpv.org_id
            AND cpq.period_id BETWEEN xcpv.start_period_id
                                  AND xcpv.end_period_id
            AND cq.incentive_type_code = 'BONUS'
   GROUP BY cpq.salesrep_id,
            cpq.org_id,
            CEIL ( (cpq.period_id - (xcpv.start_period_id - 1)) / 3);
