DROP VIEW APPS.XX_CN_NWDL_SEMI_ANUL_QUTA_V;

/* Formatted on 6/6/2016 4:58:48 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_NWDL_SEMI_ANUL_QUTA_V
(
   SALESREP_ID,
   LAST_PERIOD_ID,
   ORG_ID,
   NEWDEAL_SEMI_ANNUALTARGET
)
AS
     SELECT period_quotas.salesrep_id,
            MAX (period_quotas.period_id) last_period_id,
            period_quotas.org_id,
            SUM (
               (DECODE (period_quotas.target_amount,
                        0, 0,
                        period_quotas.target_amount)))
               newdeal_semi_annualtarget
       FROM cn_srp_period_quotas_all period_quotas,
            cn_quotas_all ele,
            cn_quota_rules_all ele_rev,
            cn_srp_quota_rules_all srp_ele_rev,
            cn_revenue_classes_all rev,
            cn_srp_quota_assigns_all q_assign,
            xx_cn_periods_v ipv
      WHERE     period_quotas.quota_id = ele.quota_id
            AND ele.quota_id = ele_rev.quota_id
            AND ele_rev.quota_rule_id = srp_ele_rev.quota_rule_id
            AND srp_ele_rev.revenue_class_id = rev.revenue_class_id
            AND period_quotas.srp_quota_assign_id =
                   q_assign.srp_quota_assign_id
            AND q_assign.quota_id = ele.quota_id
            AND q_assign.srp_quota_assign_id = srp_ele_rev.srp_quota_assign_id
            AND period_quotas.org_id = ipv.org_id
            AND ele.incentive_type_code = 'COMMISSION'
            AND rev.name = 'Newdeal'
            AND period_quotas.period_id BETWEEN ipv.start_period_id
                                            AND ipv.end_period_id
   GROUP BY period_quotas.salesrep_id,
            period_quotas.org_id,
            CEIL ( (period_quotas.period_id - (ipv.start_period_id - 1)) / 6);
