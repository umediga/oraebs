DROP VIEW APPS.XXOIC_SALESREP_V;

/* Formatted on 6/6/2016 5:00:07 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXOIC_SALESREP_V
(
   NAME,
   SALESREP_ID,
   PAYRUN_ID
)
AS
   SELECT DISTINCT res.resource_name name, rep.salesrep_id, par.payrun_id
     FROM cn_commission_headers_all cmh,
          cn_commission_lines_all cml,
          cn_quotas_all qut,
          cn_payruns_all par,
          jtf_rs_salesreps rep,
          cn_payment_worksheets_all cpw,
          jtf_rs_groups_tl jrgt,
          cn_revenue_classes_all crc,
          jtf_rs_resource_extns_tl res
    WHERE     cmh.commission_header_id = cml.commission_header_id
          AND cml.processed_period_id = par.pay_period_id
          AND cml.credited_salesrep_id = rep.salesrep_id
          AND cml.quota_id = qut.quota_id
          AND NVL (cmh.transaction_amount, 0) <> 0
          AND UPPER (cml.Status) = 'CALC'
          AND cpw.Payrun_Id = Par.Payrun_Id
          AND rep.Salesrep_Id = cpw.Salesrep_Id
          AND jrgt.GROUP_ID = cmh.Comp_Group_Id
          AND crc.Revenue_Class_Id = cmh.Revenue_Class_Id
          AND jrgt.Language = 'US'
          AND qut.Quota_Group_Code IS NOT NULL
          AND cpw.Quota_Id IS NULL
          AND rep.resource_id = res.resource_id;
