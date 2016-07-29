DROP VIEW APPS.XX_SDC_OIC_SP_DETAILS_V;

/* Formatted on 6/6/2016 4:58:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_OIC_SP_DETAILS_V
(
   SALES_PERSON_NUM,
   SALESREP_ID,
   QUOTA_PERIOD,
   PAY_PERIOD_ID,
   QUOTA_NAME,
   QUOTA_ID,
   COMM_PTD,
   BONUS_PTD,
   TARGET_AMOUNT,
   CURRENCY,
   ORG_ID
)
AS
     SELECT rep.salesrep_number salesrep_num,
            rep.salesrep_id,
            (SELECT DISTINCT period_name
               FROM cn_period_statuses_all
              WHERE period_id = cml.processed_period_id)
               quota_period,
            cml.processed_period_id pay_period_id,
            qut.name quota_name,
            qut.quota_id,
            DECODE (qut.incentive_type_code,
                    'COMMISSION', SUM (cml.commission_amount),
                    NULL)
               commission_ptd,
            DECODE (qut.incentive_type_code,
                    'BONUS', SUM (cml.commission_amount),
                    NULL)
               bonus_ptd,
            (SELECT SUM (pqa.target_amount)
               FROM cn_srp_period_quotas_all pqa
              WHERE     pqa.salesrep_id = rep.salesrep_id
                    AND pqa.period_id = cml.processed_period_id
                    AND pqa.quota_id = qut.quota_id)
               target_amount,
            NVL (cmh.orig_currency_code, 'USD') currency,
            cmh.org_id
       FROM cn_commission_headers_all cmh,
            cn_commission_lines_all cml,
            jtf_rs_salesreps rep,
            cn_quotas_all qut
      WHERE     cml.credited_salesrep_id = rep.salesrep_id
            AND cml.quota_id = qut.quota_id
            AND cml.status = 'CALC'
            AND cml.commission_header_id = cmh.commission_header_id
            AND NOT EXISTS
                   (SELECT 'Y'
                      FROM cn_period_statuses_all psa
                     WHERE     psa.start_date < '01-JAN-2014'
                           AND psa.period_id = cml.processed_period_id)
            AND EXISTS
                   (SELECT lookup_code
                      FROM fnd_lookup_values_vl
                     WHERE     lookup_type = 'XX_SFDC_OU_LOOKUP'
                           AND lookup_code = cmh.org_id
                           AND NVL (enabled_flag, 'X') = 'Y'
                           AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                           AND NVL (end_date_active, SYSDATE))
   GROUP BY rep.salesrep_number,
            rep.salesrep_id,
            qut.quota_id,
            qut.name,
            cml.processed_period_id,
            qut.incentive_type_code,
            NVL (cmh.orig_currency_code, 'USD'),
            cmh.org_id
   ORDER BY salesrep_id, quota_id, pay_period_id;
