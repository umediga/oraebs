DROP VIEW APPS.XX_CN_NWDL_ANUL_PERF_V;

/* Formatted on 6/6/2016 4:58:49 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_NWDL_ANUL_PERF_V
(
   SALESREP_ID,
   LAST_PERIOD_ID,
   ORG_ID,
   NEWDEAL_ANNUAL_PERF
)
AS
     SELECT cpqa.salesrep_id,
            MAX (cpqa.period_id) last_period_id,
            cpqa.org_id,
            SUM (
               (DECODE (cpqa.perf_achieved_ptd, 0, 0, cpqa.perf_achieved_ptd)))
               newdeal_annual_perf
       FROM cn_srp_period_quotas_all cpqa,
            cn_quotas_all cqa,
            cn_quota_rules_all cqra,
            cn_srp_quota_rules_all csqr,
            cn_revenue_classes_all rev,
            cn_srp_quota_assigns_all qasa,
            xx_cn_periods_v xcpv
      WHERE     cpqa.quota_id = cqa.quota_id
            AND cqa.quota_id = cqra.quota_id
            AND cqra.quota_rule_id = csqr.quota_rule_id
            AND csqr.revenue_class_id = rev.revenue_class_id
            AND cpqa.srp_quota_assign_id = qasa.srp_quota_assign_id
            AND qasa.quota_id = cqa.quota_id
            AND qasa.srp_quota_assign_id = csqr.srp_quota_assign_id
            AND cqa.incentive_type_code = 'COMMISSION'
            AND rev.name = 'Newdeal'
            AND cpqa.org_id = xcpv.org_id
            AND cpqa.period_id BETWEEN xcpv.start_period_id
                                   AND xcpv.end_period_id
   GROUP BY cpqa.salesrep_id,
            cpqa.org_id,
            CEIL ( (cpqa.period_id - (xcpv.start_period_id - 1)) / 12);
