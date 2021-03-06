DROP VIEW APPS.XX_CN_QRTR_BONUS_GOAL_V;

/* Formatted on 6/6/2016 4:58:46 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_QRTR_BONUS_GOAL_V
(
   SALESREP_ID,
   LAST_PERIOD_ID,
   ORG_ID,
   QRTR_BONUS_GOAL
)
AS
     SELECT salesrep_id,
            MAX (cpq.period_id) last_period_id,
            cpq.org_id,
            SUM ( (DECODE (performance_goal_ptd, 0, 0, performance_goal_ptd)))
               qrtr_bonus_goal
       FROM cn_srp_period_quotas cpq, cn_quotas cq, xx_cn_periods_v xcpv
      WHERE     cpq.quota_id = cq.quota_id
            AND cpq.org_id = xcpv.org_id
            AND cpq.period_id BETWEEN xcpv.start_period_id
                                  AND xcpv.end_period_id
            AND cq.incentive_type_code = 'BONUS'
   GROUP BY salesrep_id, cpq.org_id;
