DROP VIEW APPS.XX_SDC_CUST_ACC_SITES_WS_V;

/* Formatted on 6/6/2016 4:58:10 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_CUST_ACC_SITES_WS_V
(
   SITE_NUMBER,
   ADDRESS_LINE_1,
   ADDRESS_LINE_2,
   CITY,
   STATE,
   POSTAL_CODE,
   COUNTY,
   COUNTRY,
   GPO_ENTITY,
   TERRITORY,
   GLN_NUMBER,
   CUST_SITE_STATUS,
   SITE_PHONE_NUMBER,
   SITE_FAX_NUMBER,
   SITE_EMAIL_ADDRESS,
   SITE_URL,
   OPERATING_UNIT_ID,
   SHIP_TO_FLAG,
   BILL_TO_FLAG,
   SITE_LAST_UPDATE_DATE,
   SITE_CREATION_DATE,
   CUSTOMER_ACCOUNT_ID,
   CUSTOMER_ACCOUNT_SITE_ID
)
AS
   SELECT hps.party_site_number site_number,
          hl.address1,
          hl.address2,
          hl.city,
          NVL (hl.state, hl.province),
          SUBSTR (hl.postal_code, 1, 20) postal_code,
          hl.county,
          hl.country,
          hcas.attribute1 gpo_entity,
          xx_sdc_cust_outbound_ws_pkg.get_territories (hl.country,
                                                       hca.cust_account_id,
                                                       hps.party_site_id,
                                                       hca.account_number,
                                                       hl.county,
                                                       hl.postal_code,
                                                       hl.province,
                                                       hl.state,
                                                       hp.party_name)
             territory,
          /*(SELECT sic_code
             FROM hz_cust_site_uses_all
            WHERE cust_acct_site_id   = hcas.cust_acct_site_id
              AND site_use_code       = 'BILL_TO'
              AND status              = 'A'
          ) SIC_CODE,*/
          /*(SELECT SUBSTR(jta.name,1,2390)
             FROM jtf_terr_values_all jtva ,
                  jtf_terr_qual_all jtqa ,
                  jtf_qual_usgs_all jqua ,
                  jtf_seeded_qual_all jsqa ,
                  jtf_terr_all jta
            WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
              AND jtqa.qual_usg_id         = jqua.qual_usg_id
              AND jqua.org_id              = jtqa.org_id
              AND jqua.enabled_flag        = 'Y'
              AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
              AND qual_type_usg_id         = -1001
              AND jtqa.terr_id             = jta.terr_id
              AND jsqa.name                = 'Site Number'
              AND jtva.comparison_operator = '='
              AND jtva.low_value_char_id   = hps.party_site_id
              ) territory,*/
          hcas.attribute2 gln_number,
          hcas.status site_status,
          (SELECT    DECODE (phone_country_code, NULL, NULL, '+')
                  || phone_country_code
                  || DECODE (phone_country_code, NULL, NULL, ' ')
                  || DECODE (phone_area_code, NULL, NULL, '(')
                  || phone_area_code
                  || DECODE (phone_area_code, NULL, NULL, ')')
                  || DECODE (phone_area_code, NULL, NULL, ' ')
                  || phone_number
             FROM hz_contact_points
            WHERE     owner_table_name = 'HZ_PARTY_SITES'
                  AND contact_point_type = 'PHONE'
                  AND primary_flag = 'Y'
                  AND phone_line_type = 'GEN'
                  AND status = 'A'
                  AND owner_table_id = hps.party_site_id)
             site_phone_number,
          (SELECT    DECODE (phone_country_code, NULL, NULL, '+')
                  || phone_country_code
                  || DECODE (phone_country_code, NULL, NULL, ' ')
                  || DECODE (phone_area_code, NULL, NULL, '(')
                  || phone_area_code
                  || DECODE (phone_area_code, NULL, NULL, ')')
                  || DECODE (phone_area_code, NULL, NULL, ' ')
                  || phone_number
             FROM hz_contact_points
            WHERE     owner_table_name = 'HZ_PARTY_SITES'
                  AND contact_point_type = 'PHONE'
                  --AND primary_by_purpose = 'Y'
                  AND phone_line_type = 'FAX'
                  AND status = 'A'
                  AND owner_table_id = hps.party_site_id
                  AND ROWNUM = 1)
             site_fax_number,
          (SELECT email_address
             FROM hz_contact_points
            WHERE     owner_table_name = 'HZ_PARTY_SITES'
                  AND contact_point_type = 'EMAIL'
                  AND primary_flag = 'Y'
                  AND status = 'A'
                  AND owner_table_id = hps.party_site_id)
             site_email_address,
          (SELECT url
             FROM hz_contact_points
            WHERE     owner_table_name = 'HZ_PARTY_SITES'
                  AND contact_point_type = 'WEB'
                  AND primary_flag = 'Y'
                  AND status = 'A'
                  AND owner_table_id = hps.party_site_id)
             site_url,
          hcas.org_id,
          NVL (
             (SELECT DECODE (hcsu.site_use_code, 'SHIP_TO', 'Y', 'N')
                FROM hz_cust_site_uses_all hcsu
               WHERE     hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcsu.site_use_code = 'SHIP_TO'
                     AND hcsu.status = 'A'),
             'N')
             ship_to_flag,
          NVL (
             (SELECT DECODE (hcsu.site_use_code, 'BILL_TO', 'Y', 'N')
                FROM hz_cust_site_uses_all hcsu
               WHERE     hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcsu.site_use_code = 'BILL_TO'
                     AND hcsu.status = 'A'),
             'N')
             bill_to_flag,
          hcas.last_update_date acc_site_last_update_date,
          hcas.creation_date acc_site_creation_date,
          hca.cust_account_id account_id,
          --HCAS.PARTY_SITE_ID ACCOUNT_SITE_ID
          hcas.cust_acct_site_id account_site_id
     FROM hz_parties hp,
          hz_cust_accounts hca,
          hz_cust_acct_sites_all hcas,
          hz_party_sites hps,
          --hz_cust_site_uses_all hcsu,
          hz_locations hl
    WHERE     hl.location_id = hps.location_id --AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                                      --AND hcsu.site_use_code     = 'SHIP_TO'
                                    --AND hps.party_id           = hp.party_id
          AND hps.party_site_id = hcas.party_site_id --AND hps.status             = 'A'
                                   --AND hps.party_id           = hca.party_id
                                            --AND hp.status              = 'A'
          AND hp.party_id = hca.party_id    --AND hcas.status            = 'A'
          AND hcas.cust_account_id = hca.cust_account_id --AND hca.status             = 'A'
          AND hca.customer_type = 'R';
