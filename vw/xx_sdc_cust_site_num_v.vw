DROP VIEW APPS.XX_SDC_CUST_SITE_NUM_V;

/* Formatted on 6/6/2016 4:58:09 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_CUST_SITE_NUM_V
(
   CUST_SITE_NUMBER,
   CUSTOMER_NAME
)
AS
     SELECT hps.party_site_number, hp.party_name
       FROM hz_parties hp,
            hz_cust_accounts hca,
            hz_cust_acct_sites_all hcas,
            hz_party_sites hps
      WHERE /*hps.party_id           = hp.party_id
        AND*/
           hps  .party_site_id = hcas.party_site_id --AND hps.status             = 'A'
                                   --AND hps.party_id           = hca.party_id
                                            --AND hp.status              = 'A'
            AND hp.party_id = hca.party_id  --AND hcas.status            = 'A'
            AND hcas.cust_account_id = hca.cust_account_id --AND HCA.STATUS             = 'A'
            AND hca.customer_type = 'R'
   ORDER BY TO_NUMBER (hps.party_site_number) ASC;
