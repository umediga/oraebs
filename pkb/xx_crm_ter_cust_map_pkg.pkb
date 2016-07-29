DROP PACKAGE BODY APPS.XX_CRM_TER_CUST_MAP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CRM_TER_CUST_MAP_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xxcrmtercustmap.pkb
 Description   : This script creates the package body of
                 xx_crm_ter_cust_map_pkg, which will Load the Territory and Customer
                 Mapping data, based on various matching contitions
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 12-Aug-2014 Yogesh                Initial Version
*/
----------------------------------------------------------------------

    PROCEDURE load_mapping_data( x_error_code    OUT   NUMBER
                                ,x_error_msg     OUT   VARCHAR2)
    IS
       CURSOR c_map_sites
       IS
       SELECT jtqa.terr_id ter_num ,
              jta.name ter_name,
              hca.account_number customer_number,
              hps.party_site_number,
              JSQA.name MATCHING_ATTR_TYP,
              --jtva.low_value_char_id matching_attr_val
              hps.party_site_number matching_attr_val
         FROM jtf_terr_values_all jtva ,
              jtf_terr_qual_all jtqa ,
              jtf_qual_usgs_all jqua ,
              jtf_seeded_qual jsqa ,
              jtf_terr_all jta,
              hz_cust_accounts_all hca,
              hz_party_sites hps
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
          AND jtqa.qual_usg_id         = jqua.qual_usg_id
          AND jqua.org_id              = jtqa.org_id
          AND jqua.enabled_flag        = 'Y'
          AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
          AND qual_type_usg_id         = -1001
          AND jtqa.terr_id             = jta.terr_id
          AND jsqa.name                = 'Site Number'
          AND jtva.comparison_operator = '='
          AND jtva.low_value_char_id=hps.party_site_id(+)
          AND hps.status             = 'A'
          AND hca.party_id  = hps.party_id;

       CURSOR c_map_cust_name
       IS
       SELECT jtqa.terr_id ter_num,
              jta.name ter_name,
              hca.account_number customer_number,
              hps.party_site_number,
              jsqa.name matching_attr_typ,
              jtva.low_value_char matching_attr_val
         FROM jtf_terr_values_all jtva ,
              jtf_terr_qual_all jtqa ,
              jtf_qual_usgs_all jqua ,
              jtf_seeded_qual_all jsqa ,
              jtf_terr_all jta,
              hz_cust_accounts_all hca,
              hz_party_sites hps,
              hz_cust_site_uses_all hcsu ,
              hz_cust_acct_sites_all hcas
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
          AND jtqa.qual_usg_id         = jqua.qual_usg_id
          AND jqua.org_id              = jtqa.org_id
          AND jqua.enabled_flag        = 'Y'
          AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
          AND qual_type_usg_id         = -1001
          AND jtqa.terr_id             = jta.terr_id
          AND jsqa.name                = 'Customer Name'
          AND jtva.comparison_operator = '='
          AND jtva.low_value_char_id   = hca.cust_account_id
          AND hca.cust_account_id      = hcas.cust_account_id
          AND hcsu.site_use_code       = 'SHIP_TO'
          AND hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
          AND hcsu.cust_acct_site_id   = hcas.cust_acct_site_id(+)
          AND hcas.party_site_id       = hps.party_site_id(+)
          AND hps.status               = 'A'
          AND hcas.status              = 'A'
          AND hcsu.status              = 'A';

       CURSOR c_map_cust_num_range
       IS
       SELECT jtqa.terr_id ter_num,
              jta.name ter_name,
              hca.account_number customer_number,
              hps.party_site_number,
              jsqa.name matching_attr_typ,
              jtva.low_value_char matching_attr_val
         from jtf_terr_values_all jtva ,
              jtf_terr_qual_all jtqa ,
              jtf_qual_usgs_all jqua ,
              jtf_seeded_qual jsqa ,
              jtf_terr_all jta,
              hz_cust_accounts_all hca,
              hz_party_sites hps,
              hz_cust_site_uses_all hcsu ,
              hz_cust_acct_sites_all hcas
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
          AND jtqa.qual_usg_id            = jqua.qual_usg_id
          AND jqua.org_id                 = jtqa.org_id
          AND jqua.enabled_flag           = 'y'
          AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
          AND qual_type_usg_id            = -1001
          AND jtqa.terr_id                = jta.terr_id
          AND jsqa.name                   = 'Customer Account Number'
          AND ( (jtva.comparison_operator = 'LIKE'
                 AND hca.account_number LIKE '%'|| jtva.low_value_char|| '%')
           OR (jtva.comparison_operator = '='
              AND hca.account_number      = jtva.low_value_char )
           OR (jtva.comparison_operator = 'BETWEEN'
               and hca.account_number between jtva.low_value_char and jtva.high_value_char) )
          AND hca.cust_account_id    = hcas.cust_account_id
          AND hcsu.site_use_code     = 'SHIP_TO'
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
          AND hcas.party_site_id     = hps.party_site_id(+)
          AND hps.status             = 'A'
          AND hcas.status            = 'A'
          AND hcsu.status            = 'A';

       CURSOR c_map_postal_code
       IS
       SELECT jtqa.terr_id ter_num,
              jta.name ter_name,
              hca.account_number customer_number,
              hps.party_site_number,
              jsqa.name matching_attr_typ,
              jtva.low_value_char matching_attr_val
         from jtf_terr_values_all jtva ,
              jtf_terr_qual_all jtqa ,
              jtf_qual_usgs_all jqua ,
              jtf_seeded_qual jsqa ,
              jtf_terr_all jta,
              hz_locations hl,
              hz_party_sites hps,
              hz_cust_acct_sites_all hcas ,
              hz_cust_site_uses_all hcsu ,
              hz_cust_accounts_all hca
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
          AND jtqa.qual_usg_id            = jqua.qual_usg_id
          AND jqua.org_id                 = jtqa.org_id
          AND jqua.enabled_flag           = 'Y'
          AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
          AND qual_type_usg_id            = -1001
          AND JTQA.TERR_ID                = JTA.TERR_ID
          AND JSQA.name                   = 'Postal Code'
          AND ( (jtva.comparison_operator = 'LIKE'
          AND        hl.postal_code LIKE '%'
            || jtva.low_value_char
            || '%')
          OR (JTVA.COMPARISON_OPERATOR = '='
          AND HL.POSTAL_CODE    = JTVA.LOW_VALUE_CHAR
          OR (JTVA.COMPARISON_OPERATOR = 'BETWEEN'
          AND hl.POSTAL_CODE between JTVA.LOW_VALUE_CHAR and JTVA.HIGH_VALUE_CHAR)
          ) )
          AND HL.LOCATION_ID(+)      = HPS.LOCATION_ID
          AND HCAS.PARTY_SITE_ID     = HPS.PARTY_SITE_ID(+)
          AND HCSU.CUST_ACCT_SITE_ID = HCAS.CUST_ACCT_SITE_ID
          AND HCSU.SITE_USE_CODE     = 'SHIP_TO'
          AND hca.cust_account_id    = hcas.cust_account_id
          AND HPS.STATUS             = 'A'
          AND HCAS.STATUS            = 'A'
          AND HCSU.STATUS            = 'A' ;

         /*FROM jtf_terr_values_all jtva ,
              jtf_terr_qual_all jtqa ,
              jtf_qual_usgs_all jqua ,
              jtf_seeded_qual jsqa ,
              jtf_terr_all jta,
              hz_cust_accounts_all hca,
              hz_party_sites hps,
              hz_cust_site_uses_all hcsu ,
              hz_cust_acct_sites_all hcas ,
              hz_locations hl
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
          AND jtqa.qual_usg_id            = jqua.qual_usg_id
          AND jqua.org_id                 = jtqa.org_id
          AND jqua.enabled_flag           = 'Y'
          AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
          AND qual_type_usg_id            = -1001
          AND jtqa.terr_id                = jta.terr_id
          AND jsqa.name                   = 'Postal Code'
          AND ( (jtva.comparison_operator = 'LIKE'
          AND hl.postal_code LIKE '%'
              || jtva.low_value_char
              || '%')
           OR (jtva.comparison_operator = '='
               AND hl.postal_code            = jtva.low_value_char )
           OR (jtva.comparison_operator = 'between'
               AND hl.postal_code BETWEEN jtva.low_value_char AND jtva.high_value_char) )
          AND hca.cust_account_id    = hcas.cust_account_id
          AND hcsu.site_use_code     = 'SHIP_TO'
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
          AND hl.location_id(+)      = hps.location_id
          --AND hp.party_id            = hps.party_id
          AND hcas.party_site_id     = hps.party_site_id(+)
          AND hps.status             = 'A'
          AND hcas.status            = 'A'
          AND hcsu.status            = 'A';
          --AND hp.status              = 'A'; */


       TYPE crm_ter_map_tbl IS TABLE OF xx_crm_ter_cust_map_temp%rowtype
         INDEX BY BINARY_INTEGER;

       x_crm_ter_map_tbl        crm_ter_map_tbl;
       x_err_msg                VARCHAR2(1000);


    BEGIN
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Truncating the Temporary Table:');

       DELETE FROM xx_crm_ter_cust_map_temp;

       OPEN c_map_sites;
       FETCH c_map_sites
       BULK COLLECT INTO x_crm_ter_map_tbl;

       CLOSE c_map_sites;

       IF x_crm_ter_map_tbl.COUNT > 0
       THEN
          FORALL i_rec IN 1 .. x_crm_ter_map_tbl.COUNT
             INSERT INTO xx_crm_ter_cust_map_temp
                  VALUES x_crm_ter_map_tbl (i_rec);
       END IF;

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Number of Records Inserted for ''Site Number'' Matcthing : '||x_crm_ter_map_tbl.COUNT);

       OPEN c_map_cust_name;
       FETCH c_map_cust_name
       BULK COLLECT INTO x_crm_ter_map_tbl;

       CLOSE c_map_cust_name;

       IF x_crm_ter_map_tbl.COUNT > 0
       THEN
          FORALL i_rec IN 1 .. x_crm_ter_map_tbl.COUNT
             INSERT INTO xx_crm_ter_cust_map_temp
                  VALUES x_crm_ter_map_tbl (i_rec);
       END IF;

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Number of Records Inserted for ''Customer Name'' Matcthing : '||x_crm_ter_map_tbl.COUNT);

       OPEN c_map_cust_num_range;
       FETCH c_map_cust_num_range
       BULK COLLECT INTO x_crm_ter_map_tbl;

       CLOSE c_map_cust_num_range;

       IF x_crm_ter_map_tbl.COUNT > 0
       THEN
          FORALL i_rec IN 1 .. x_crm_ter_map_tbl.COUNT
             INSERT INTO xx_crm_ter_cust_map_temp
                  VALUES x_crm_ter_map_tbl (i_rec);
       END IF;

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Number of Records Inserted for ''Customer Account Number'' Matcthing : '||x_crm_ter_map_tbl.COUNT);

       OPEN c_map_postal_code;
       FETCH c_map_postal_code
       BULK COLLECT INTO x_crm_ter_map_tbl;

       CLOSE c_map_postal_code;

       IF x_crm_ter_map_tbl.COUNT > 0
       THEN
          FORALL i_rec IN 1 .. x_crm_ter_map_tbl.COUNT
             INSERT INTO xx_crm_ter_cust_map_temp
                  VALUES x_crm_ter_map_tbl (i_rec);
       END IF;

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Number of Records Inserted for ''Postal Code'' Matcthing : '||x_crm_ter_map_tbl.COUNT);

    EXCEPTION
       WHEN OTHERS THEN
       x_err_msg := SQLERRM;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Error While Inserting the Mapping Data: '||x_err_msg);
    END load_mapping_data;

--------------------------------------------------------------------------------------------------------------
    PROCEDURE main_prc( x_error_code    OUT   NUMBER
                       ,x_error_msg     OUT   VARCHAR2)
    IS
       x_err_code                NUMBER;
       x_err_msg                 VARCHAR2(50);
    BEGIN
       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_error_code);

       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling Procedure to refersh the Territory and Customer Mapping: ');
       load_mapping_data(x_err_code,x_error_msg);

    END main_prc;

END xx_crm_ter_cust_map_pkg;
/
