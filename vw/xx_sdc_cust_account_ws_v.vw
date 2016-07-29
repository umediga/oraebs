DROP VIEW APPS.XX_SDC_CUST_ACCOUNT_WS_V;

/* Formatted on 6/6/2016 4:58:10 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_CUST_ACCOUNT_WS_V
(
   CUSTOMER,
   ALIAS,
   ACCOUNT_NUMBER,
   ACC_CUSTOMER_CLASSIFICATION,
   ACCOUNT_PHONE_NUMBER,
   ACCOUNT_FAX_NUMBER,
   ACCOUNT_EMAIL,
   ACCOUNT_URL,
   PARENT_ACCOUNT_NAME,
   PARENT_ACCOUNT_NUMBER,
   DUNS_NUMBER,
   REC_CUSTOMER_CLASSIFICATION,
   CREDIT_CHECK,
   CREDIT_HOLD,
   ACCOUNT_LAST_UPDATE_DATE,
   ACCOUNT_CREATION_DATE,
   CUSTOMER_ACCOUNT_ID,
   PAYMENT_TERM
)
AS
   SELECT hp.party_name customer,
          hp.known_as alias,
          hca.account_number,
          (SELECT meaning
             FROM ar_lookups
            WHERE     lookup_type = 'CUSTOMER CLASS'
                  AND lookup_code = hca.customer_class_code
                  AND NVL (enabled_flag, 'X') = 'Y'
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE))
             customer_class,
          /*(SELECT phone_number
             FROM hz_contact_points
            WHERE owner_table_name = 'HZ_PARTIES'
              AND contact_point_type = 'PHONE'
              AND primary_by_purpose = 'Y'
              AND phone_line_type    = 'GEN'
              AND status             = 'A'
              AND owner_table_id     = hp.party_id
          )*/
          NULL phone_number,
          /*(SELECT phone_number
             FROM hz_contact_points
            WHERE owner_table_name = 'HZ_PARTIES'
              AND contact_point_type = 'PHONE'
              AND primary_by_purpose = 'Y'
              AND phone_line_type    = 'FAX'
              AND status             = 'A'
              AND owner_table_id     = hp.party_id
          )*/
          NULL Fax_Number,
          /*(SELECT email_address
             FROM hz_contact_points
            WHERE owner_table_name = 'HZ_PARTIES'
              AND contact_point_type = 'EMAIL'
              AND primary_by_purpose = 'Y'
              AND status             = 'A'
              AND owner_table_id     = hp.party_id
          )*/
          NULL email_address,
          /*(SELECT url
             FROM hz_contact_points
            WHERE owner_table_name = 'HZ_PARTIES'
              AND contact_point_type = 'WEB'
              AND primary_by_purpose = 'Y'
              AND status             = 'A'
              AND owner_table_id     = hp.party_id)*/
          NULL account_site_url,
          (SELECT hp1.party_name
             FROM hz_relationships hr, hz_parties hp1
            WHERE     hr.object_id = hp.party_id
                  AND hr.relationship_code = 'Healthcare Sys Parent of'
                  AND hp1.status = 'A'
                  AND hp1.party_id = hr.subject_id
                  AND hr.status = 'A'
                  AND ROWNUM = 1)
             parent_account_name,
          (SELECT hca1.account_number
             FROM hz_relationships hr,                      --hz_parties  hp1,
                                      hz_cust_accounts hca1
            WHERE     hr.object_id = hp.party_id
                  AND hr.relationship_code = 'Healthcare Sys Parent of'
                  AND hca1.status = 'A'
                  AND hca1.party_id = hr.subject_id
                  AND hr.status = 'A'
                  AND ROWNUM = 1)
             parent_account_number,
          hp.duns_number,
          /*(SELECT ffvv.flex_value_meaning
             FROM fnd_lookup_values flv,
                  fnd_flex_value_sets ffvs,
                  fnd_flex_values_vl ffvv
            WHERE flv.lookup_type = 'CUSTOMER CLASS'
              AND NVL (flv.language, USERENV ('LANG')) = USERENV ('LANG')
              AND flv.enabled_flag                     = 'Y'
              AND NVL (flv.end_date_active, sysdate)  >= sysdate
              AND lookup_code                          = hca.customer_class_code
              AND ffvs.flex_value_set_name ='XX_SDC_CUST_CLASSIFICATION_MAP'
              AND ffvs.flex_value_set_id= ffvv.flex_value_set_id
              AND ffvv.flex_value = flv.meaning
          )*/
          NULL classification,
          NVL (hcp.credit_checking, 'N'),
          NVL (hcp.credit_hold, 'N'),
          hca.last_update_date acc_last_update_date,
          hca.creation_date acc_creation_date,
          hca.cust_account_id account_id,
          (SELECT term.name
             FROM ra_terms term
            WHERE hcp.standard_terms = term.term_id(+) AND ROWNUM < 2)
     FROM hz_parties hp, hz_cust_accounts hca, hz_customer_profiles hcp
    WHERE /*hp.status = 'A'
      AND*/
         hp   .party_id = hca.party_id
          --AND hcp.status = 'A'
          AND hcp.site_use_id IS NULL
          --AND hca.status = 'A'
          AND hca.customer_type = 'R'
          AND hcp.cust_account_id = hca.cust_account_id;
