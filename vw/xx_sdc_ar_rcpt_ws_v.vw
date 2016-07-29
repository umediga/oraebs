DROP VIEW APPS.XX_SDC_AR_RCPT_WS_V;

/* Formatted on 6/6/2016 4:58:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_AR_RCPT_WS_V
(
   CUSTOMER_NAME,
   ACCOUNT_NUMBER,
   COLLECTIONS_STATUS,
   CUST_ACCOUNT_ID,
   CUSTOMER_SITE_ID,
   NET_BALANCE,
   NET_BAL_CURRENCY,
   DAILY_SALES_OUTSTANDING,
   AMOUNT_OVERDUE,
   SITE_NUMBER
)
AS
   SELECT hp.party_name customer_name,
          hca.account_number,
          NVL (
             xx_sdc_ar_rcpt_intf_pkg.ret_collection_status (
                hca.cust_account_id),
             'Current')
             Collections_Status,
          hca.cust_account_id,
          hcsa.cust_acct_site_id,
          NVL (
             (SELECT ROUND (
                        SUM (
                             aps.amount_due_remaining
                           * NVL (aps.exchange_rate, 1)),
                        2)
                FROM ar_payment_schedules_all aps
               WHERE     aps.customer_id = hca.cust_account_id
                     AND aps.Customer_site_use_id = hcsu.site_use_id
                     AND aps.status = 'OP'),
             0)
             net_balance,
          'USD' net_balance_currency,
          /*NVL((SELECT ROUND(SUM( DECODE(PS.CLASS, 'INV', 1,'DM',1, 'CB',1,'DEP',1, 'BR',1, 0) * PS.ACCTD_AMOUNT_DUE_REMAINING ) * MAX(SP.CER_DSO_DAYS),0)/ DECODE(SUM( DECODE(PS.CLASS, 'INV', 1, 'DM', 1, 'CB', 1, 'DEP', 1, 'BR', 1, 0) * DECODE(SIGN (TRUNC(SYSDATE) - PS.TRX_DATE - SP.CER_DSO_DAYS), - 1, (PS.AMOUNT_DUE_ORIGINAL + NVL (PS.AMOUNT_ADJUSTED,0)) * NVL( PS.EXCHANGE_RATE, 1 ), 0)),0,1) DSO_Value
             FROM AR_PAYMENT_SCHEDULES_all PS,
                  ar_system_parameters_all sp
            WHERE ps.customer_id = hca.cust_account_id
              AND ps.Customer_site_use_id= hcsu.site_use_id
              AND hcsa.org_id = sp.org_id
              ), 0)  daily_sales_outstanding,*/
          NVL (IEX_COLL_IND.GET_CONV_DSO (NULL, NULL, hcsu.site_use_id), 0)
             daily_sales_outstanding,
          NVL (
             (SELECT ROUND (
                        SUM (
                             aps.amount_due_remaining
                           * NVL (aps.exchange_rate, 1)),
                        2)
                FROM ar_payment_schedules_all aps, iex_delinquencies_all ida
               WHERE     aps.customer_id = hca.cust_account_id
                     AND aps.Customer_site_use_id = hcsu.site_use_id
                     AND aps.status = 'OP'
                     AND ida.status != 'CURRENT'
                     AND ida.cust_account_id = APS.CUSTOMER_ID
                     AND ida.transaction_id = APS.CUSTOMER_TRX_ID
                     AND aps.class IN ('INV', 'DM', 'CB')
                     AND aps.due_date < SYSDATE),
             0)
             amount_overdue,
          hps.party_site_number site_number
     FROM hz_parties hp,
          hz_cust_accounts_all hca,
          hz_cust_acct_sites_all hcsa,
          hz_cust_site_uses_all hcsu,
          hz_party_sites hps
    /*(SELECT organization_id
       FROM hr_all_organization_units haou,
         (SELECT parameter_value
            FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
           WHERE 1 = 1
             AND xps.process_id = xpp.process_id
             AND xps.process_name = 'XX_SDC_AR_RCPT_INTF'
             AND UPPER (parameter_name) like 'OPERATING_UNIT_%'
             AND NVL (xpp.enabled_flag, 'Y') = 'Y'
             AND NVL (xps.enabled_flag, 'Y') = 'Y') EMFP
      WHERE haou.name = emfp.parameter_value) OUID*/
    WHERE     hcsu.site_use_code = 'BILL_TO'
          AND hcsu.status = 'A'
          AND hcsu.cust_acct_site_id = hcsa.cust_acct_site_id
          AND hcsa.party_site_id = hps.party_site_id
          AND EXISTS
                 (SELECT lookup_code
                    FROM fnd_lookup_values_vl
                   WHERE     lookup_type = 'XX_SFDC_OU_LOOKUP'
                         AND lookup_code = hcsa.org_id
                         AND NVL (enabled_flag, 'X') = 'Y'
                         AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                         AND NVL (end_date_active, SYSDATE))
          AND hcsa.cust_account_id = hca.cust_account_id
          AND hp.party_id = hca.party_id
          AND hca.customer_type = 'R';
