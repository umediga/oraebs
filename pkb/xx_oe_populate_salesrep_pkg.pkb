DROP PACKAGE BODY APPS.XX_OE_POPULATE_SALESREP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_POPULATE_SALESREP_PKG" 
AS
/* $Header: XX_OE_POPULATE_SALESREP_PKG.pkb 1.0.0 2012/05/08 00:00:00 riqbal noship $ */
--------------------------------------------------------------------------------
/*
 Created By     : Raquib Iqbal
 Creation Date  : 08-MAY-2012
 Filename       : XX_OE_POPULATE_SALESREP_PKG.pks
 Description    : Populate Salesrep Assigment public API. This package is used to populate Salesrep from Territory Manager for a given Sales Order line

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 08-May-2012   1.0       Raquib Iqbal        Initial development.

*/--------------------------------------------------------------------------------
   g_category_name       mtl_category_sets_tl.category_set_name%TYPE;
   g_enable_debug        VARCHAR2 (1)                                  := 'Y';
                                                        --Debug mode set to 1
--DEBUG mode decides if debug messages required or not
   g_created_by          NUMBER                         := fnd_global.user_id;
   g_last_update_login   NUMBER                        := fnd_global.login_id;
   g_creation_date       DATE                                      := SYSDATE;
   g_global_error_flag   VARCHAR2 (1)                                  := 'N';
   g_batch_id            NUMBER                                        := 0;
   
   g_object_name         VARCHAR2 (30)  := 'XX_OE_ASSIGN_SALESREP';
   g_category_set        VARCHAR2 (360) := xx_emf_pkg.get_paramater_value (g_object_name, 'CATEGORY_NAME');
   g_organization_id     NUMBER         := fnd_profile.VALUE ('MSD_MASTER_ORG');                               

/*-- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
-- START RESTRICTIONS
   PROCEDURE set_cnv_env
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE xx_emf_pkg.g_e_env_not_set;
   END set_cnv_env; */

   PROCEDURE ins_sales_credit_record (
      p_header_id       IN   oe_order_lines_all.header_id%TYPE,
      p_line_id         IN   oe_order_lines_all.line_id%TYPE,
      p_territory_id    IN   jtf_terr_all.terr_id%TYPE,
      o_return_status   OUT   VARCHAR2
   )
   IS
      l_index                NUMBER := 0;
      l_tot_credit           NUMBER                              := 0;
      
      TYPE l_salesrep_id_tbl_type IS TABLE OF jtf_rs_salesreps.salesrep_id%TYPE
         INDEX BY BINARY_INTEGER;

      l_salesrep_id_tbl_rec          l_salesrep_id_tbl_type;
      
   
      TYPE xx_oe_sales_credits_tbl IS TABLE OF xxintg.xx_oe_sales_credits%ROWTYPE
         INDEX BY PLS_INTEGER;

      xx_oe_sales_credits_rec   xx_oe_sales_credits_tbl;
   BEGIN
      xx_oe_sales_credits_rec.DELETE;
      l_salesrep_id_tbl_rec.DELETE;
      --Get Salesrep (s) as defined in the Territory
      --Divide Percent
      --Populate Custom Staging table use custom index
      --DAte func
      l_index :=0;
      FOR c_salesrep_rec IN
            (SELECT rs.resource_id, rs.salesrep_number, rs.salesrep_id
               FROM jtf_terr_rsc_all jtr, jtf_rs_salesreps rs
              WHERE jtr.terr_id = p_territory_id
                AND SYSDATE BETWEEN NVL (jtr.start_date_active, SYSDATE)
                                AND NVL (jtr.end_date_active, SYSDATE)
                AND SYSDATE BETWEEN NVL (rs.start_date_active, SYSDATE)
                                AND NVL (rs.end_date_active, SYSDATE)
                AND rs.resource_id = jtr.resource_id)
         LOOP
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Salesrep ID:'
                                  || c_salesrep_rec.salesrep_id
                                 );
            l_index := l_index + 1;
            l_salesrep_id_tbl_rec (l_index) := c_salesrep_rec.salesrep_id;
         END LOOP;
         
       IF NVL(l_salesrep_id_tbl_rec.COUNT,0)>=1 THEN
       
         FOR i IN l_salesrep_id_tbl_rec.FIRST .. l_salesrep_id_tbl_rec.LAST
           LOOP
             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  ' Salesrep ID:' || l_salesrep_id_tbl_rec (i)
                                 );
    
             xx_oe_sales_credits_rec (i).sales_credit_id := XX_OE_SALES_CREDITS_S1.nextval;      
             xx_oe_sales_credits_rec (i).creation_date := sysdate;
             xx_oe_sales_credits_rec (i).created_by := g_created_by;
             xx_oe_sales_credits_rec (i).last_update_date := sysdate;
             xx_oe_sales_credits_rec (i).last_updated_by := g_created_by;
             xx_oe_sales_credits_rec (i).last_update_login := g_last_update_login;
             xx_oe_sales_credits_rec (i).header_id := p_header_id;
             xx_oe_sales_credits_rec (i).salesrep_id := l_salesrep_id_tbl_rec(i);
             -- xx_oe_sales_credits_rec (i).percent := 100/l_salesrep_id_tbl_rec.COUNT;   
             xx_oe_sales_credits_rec (i).line_id := p_line_id;
             xx_oe_sales_credits_rec (i).lattest_flag := 'Y';                    -- Custom Column
             xx_oe_sales_credits_rec (i).terr_id := p_territory_id;              -- Custom Column
            
             xx_oe_sales_credits_rec (i).percent := TRUNC ((100 / l_salesrep_id_tbl_rec.COUNT), 3);
             l_tot_credit := l_tot_credit + xx_oe_sales_credits_rec (i).PERCENT;
             
             IF i = l_salesrep_id_tbl_rec.LAST
              THEN
               xx_oe_sales_credits_rec (i).PERCENT :=
                        xx_oe_sales_credits_rec (i).PERCENT
                        + (100 - l_tot_credit);
             END IF;
             -- Now insert into custom table xx_oe_sales_credits
             insert into xx_oe_sales_credits
             values xx_oe_sales_credits_rec(i);
         END LOOP;
             commit;
       END IF;
       o_return_status := 'S';
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     ' Error inside ins_sales_credit_record :'||SQLERRM
                    );
         o_return_status := 'E';
   END ins_sales_credit_record;

   PROCEDURE ins_jtf_terr_results_gt_mt (o_return_status OUT VARCHAR2)
   IS
   --Populate global temporary table
   BEGIN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE apps.jtf_terr_results_gt_mt';

                  INSERT INTO jtf_terr_results_gt_mt jtr
                              (trans_id, source_id, qual_type_id,
                               trans_object_id, trans_detail_object_id,
                               txn_date, terr_id, absolute_rank,
                               top_level_terr_id, num_winners, worker_id)
                     (SELECT   -1002, -1001, -1002, temp.trans_object_id,
                               temp.trans_detail_object_id,
                               TRUNC (temp.txn_date), temp.terr_id,
                               temp.absolute_rank, temp.top_level_terr_id,
                               COUNT (1) no_of_combination, temp.num_winners
                          FROM (
                                --State
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b
                                          WHERE b.q1008_low_value_char =
                                                                       a.state
                                            AND b.q1008_cp = '='
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                UNION ALL
                                -- PROVINCE
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b,
                                                fnd_lookup_values flv
                                          WHERE UPPER (b.q1013_low_value_char) =
                                                               UPPER (meaning)
                                            AND lookup_type = 'CA_PROVINCE'
                                            AND LANGUAGE = 'US'
                                            AND lookup_code = a.province
                                            AND b.q1013_cp = '='
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                UNION ALL
                                -- Customer Name Range added on 02-26-2013 by Raquib
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b,
                                                hz_parties hp
                                          WHERE (    b.q1012_cp = '='
                                                 AND b.q1012_low_value_char =
                                                                 hp.party_name
                                                )
                                             OR     (    b.q1012_cp = 'LIKE'
                                                     AND hp.party_name LIKE
                                                               b.q1012_low_value_char
                                                            || '%'
                                                    )
                                                AND a.party_id = hp.party_id
                                                AND b.source_id = -1001
                                                AND a.txn_date
                                                       BETWEEN b.start_date
                                                           AND b.end_date
                                                AND b.trans_type_id = -1002
                                UNION ALL
                                --Party_id
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b
                                          WHERE b.q1002_cp = '='
                                            AND b.q1002_low_value_char_id =
                                                                    a.party_id
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                UNION ALL
--Country
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b
                                          WHERE b.q1003_cp = '='
                                            AND b.q1003_low_value_char =
                                                                     a.country
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                UNION ALL
--City
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b
                                          WHERE b.q1006_cp = '='
                                            AND b.q1006_low_value_char =
                                                                        a.city
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                UNION ALL
--Postal Code
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b
                                          WHERE (   (    a.postal_code =
                                                            b.q1007_low_value_char
                                                     AND b.q1007_cp = '='
                                                    )
                                                 OR (    a.postal_code LIKE
                                                               b.q1007_low_value_char
                                                            || '%'
                                                     AND b.q1007_cp = 'LIKE'
                                                    )
                                                 OR (    b.q1007_cp =
                                                                     'BETWEEN'
                                                     AND a.postal_code
                                                            BETWEEN b.q1007_low_value_char
                                                                AND b.q1007_high_value_char
                                                    )
                                                )
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                UNION ALL
--County
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b
                                          WHERE b.q1011_cp = '='
                                            AND b.q1011_low_value_char =
                                                                      a.county
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                UNION ALL
--Category Code (Division)
                                SELECT DISTINCT a.trans_object_id,
                                                a.trans_detail_object_id,
                                                a.txn_date txn_date,
                                                b.terr_id, b.absolute_rank,
                                                b.top_level_terr_id,
                                                b.num_winners
                                           FROM jty_terr_1001_account_trans_gt a,
                                                jty_1001_denorm_attr_values b,
                                                jtf_terr_all jta,
                                                jtf_terr_types_all jtt
                                          WHERE SUBSTR
                                                      (jtt.NAME,
                                                       1,
                                                       LENGTH (a.category_code)
                                                      ) LIKE a.category_code
                                            AND b.source_id = -1001
                                            AND a.txn_date BETWEEN b.start_date
                                                               AND b.end_date
                                            AND b.trans_type_id = -1002
                                            AND jta.terr_id = b.terr_id
                                            AND jtt.terr_type_id =
                                                         jta.territory_type_id) temp
                      GROUP BY temp.trans_object_id,
                               temp.trans_detail_object_id,
                               TRUNC (temp.txn_date),
                               temp.terr_id,
                               temp.absolute_rank,
                               temp.top_level_terr_id,
                               temp.num_winners);

      o_return_status := 'S';
      xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_low,
                       'JTF_TERR_RESULTS_GT_MT  table populated successfully '
                      );
   EXCEPTION
      WHEN OTHERS
      THEN
         o_return_status := 'E';
   END ins_jtf_terr_results_gt_mt;

   PROCEDURE ins_jty_terr_1001_acct_trans (
      p_city               IN       jty_terr_1001_account_trans_gt.city%TYPE,
      p_county             IN       jty_terr_1001_account_trans_gt.county%TYPE,
      p_state              IN       jty_terr_1001_account_trans_gt.state%TYPE,
      p_province           IN       jty_terr_1001_account_trans_gt.province%TYPE, -- Added on 13-feb-2013 
      p_postal_code        IN       jty_terr_1001_account_trans_gt.postal_code%TYPE,
      p_country            IN       jty_terr_1001_account_trans_gt.country%TYPE,
      p_brand              IN       VARCHAR2,
      p_subinventory       IN       VARCHAR2,
      p_sales_order_type   IN       VARCHAR2,
      p_party_id           IN       hz_parties.party_id%TYPE,
      p_party_site_id      IN       hz_party_sites.party_site_id%TYPE,
      p_category_code      IN       mtl_categories_b.segment1%TYPE,
      p_division           IN       mtl_categories_b.segment4%TYPE,
      p_enable_flag        IN       VARCHAR2,
      o_return_status      OUT      VARCHAR2
   )
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      x_postal_code   jty_terr_1001_account_trans_gt.postal_code%TYPE; 
   BEGIN
      --TRIM postal code to  first 3 characters  for Canada.
       /*
       IF fnd_global.org_id = --Canadian OU
         THEN
            l_postal_code := SUBSTR (p_postal_code, 1, 5);
         ELSE
            l_postal_code := p_postal_code;
         END IF;*/
      x_postal_code := INSTR (p_postal_code, '-');

      IF x_postal_code = 0
      THEN
         x_postal_code := p_postal_code;
      ELSE
         x_postal_code :=
                     SUBSTR (p_postal_code, 1, INSTR (p_postal_code, '-') - 1);
      END IF;

      EXECUTE IMMEDIATE 'TRUNCATE TABLE apps.jty_terr_1001_account_trans_gt';

      INSERT INTO jty_terr_1001_account_trans_gt
                  (trans_object_id, trans_detail_object_id, city,
                   postal_code, state, province,
                   county, country, party_id,
                   party_site_id, category_code,
                   txn_date
                  )
           VALUES (-9999, -1006, UPPER (p_city),
                   x_postal_code, UPPER (p_state), UPPER (p_province),
                   UPPER (p_county), UPPER (p_country), p_party_id,
                   p_party_site_id, p_division        --Item Category Division
                                              ,
                   SYSDATE
                  );

      xx_emf_pkg.write_log
                (xx_emf_cn_pkg.cn_low,
                 'JTY_TERR_1001_ACCOUNT_TRANS_GT table populated successfully'
                );
      o_return_status := 'S';
   EXCEPTION
      WHEN OTHERS
      THEN
         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
             'Unexpected error occured while populating jty_terr_1001_account_trans_gt table'
            );
         o_return_status := 'E';
   END ins_jty_terr_1001_acct_trans;

   PROCEDURE get_ship_from_address (
      p_ship_from_org_id            IN       NUMBER,
      o_ship_to_location            OUT      hz_cust_site_uses_all.LOCATION%TYPE,
      o_ship_to_party_id            OUT      hz_party_sites.party_id%TYPE,
      o_ship_to_party_name          OUT      hz_parties.party_name%TYPE,
      o_ship_to_site_use_code       OUT      hz_cust_site_uses_all.site_use_code%TYPE,
      o_ship_to_account_number      OUT      hz_cust_accounts.account_number%TYPE,
      o_ship_to_party_site_number   OUT      hz_party_sites.party_site_number%TYPE,
      o_ship_to_party_site_name     OUT      hz_party_sites.party_site_name%TYPE,
      o_ship_to_address1            OUT      hz_locations.address1%TYPE,
      o_ship_to_address2            OUT      hz_locations.address2%TYPE,
      o_ship_to_address3            OUT      hz_locations.address3%TYPE,
      o_ship_to_city                OUT      hz_locations.city%TYPE,
      o_ship_to_county              OUT      hz_locations.county%TYPE,
      o_ship_to_postal_code         OUT      hz_locations.postal_code%TYPE,
      o_ship_to_state               OUT      hz_locations.state%TYPE,
      o_ship_to_country             OUT      hz_locations.country%TYPE,
      o_ship_to_province            OUT      hz_locations.province%TYPE, -- Added on 28-feb-2013
      o_ship_to_party_site_id       OUT      hz_party_sites.party_site_id%TYPE,
      o_ship_to_site_use_id         OUT      hz_cust_site_uses_all.site_use_id%TYPE
   )
   IS
   BEGIN
      SELECT hcsu.LOCATION, hps.party_id,
                      hp.party_name, hcsu.site_use_code,
                      hcsu.site_use_id, hp.party_number,
                      hps.party_site_number,
                      hps.party_site_name, hl.address1,
                      hl.address2, hl.address3,
                      hl.city, hl.county,
                      hl.postal_code, hl.state,
                      hl.province, hl.country,
                      hps.party_site_id
                 INTO o_ship_to_location, o_ship_to_party_id,
                      o_ship_to_party_name, o_ship_to_site_use_code,
                      o_ship_to_site_use_id, o_ship_to_account_number,
                      o_ship_to_party_site_number,
                      o_ship_to_party_site_name, o_ship_to_address1,
                      o_ship_to_address2, o_ship_to_address3,
                      o_ship_to_city, o_ship_to_county,
                      o_ship_to_postal_code, o_ship_to_state,
                      o_ship_to_province, o_ship_to_country,
                      o_ship_to_party_site_id
                 FROM hz_cust_site_uses_all hcsu,
                      hz_cust_acct_sites_all hcas,
                      hz_party_sites hps,
                      hz_locations hl,
                      hz_parties hp
                -- ,hz_cust_accounts hca
               WHERE  hcsu.site_use_id = p_ship_from_org_id
                  AND hcsu.site_use_code = 'SHIP_TO'
                  -- AND hcsu.primary_flag = 'Y'
                  AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                  AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
                  AND hcas.party_site_id = hps.party_site_id(+)
                  AND hl.location_id(+) = hps.location_id
                  AND hp.party_id = hps.party_id
                                                -- and HCA.PARTY_ID = HPS.PARTY_ID
                                                -- AND hca.cust_account_id = hcas.cust_account_id
               ;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_ship_to_location := NULL;
         o_ship_to_party_id := NULL;
         o_ship_to_party_name := NULL;
         o_ship_to_site_use_code := NULL;
         o_ship_to_site_use_id := NULL;
         o_ship_to_account_number := NULL;
         o_ship_to_party_site_number := NULL;
         o_ship_to_party_site_name := NULL;
         o_ship_to_address1 := NULL;
         o_ship_to_address2 := NULL;
         o_ship_to_address3 := NULL;
         o_ship_to_city := NULL;
         o_ship_to_county := NULL;
         o_ship_to_postal_code := NULL;
         o_ship_to_state := NULL;
         o_ship_to_country := NULL;
         o_ship_to_party_site_id := NULL;
         xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'Ship to Address not found for Ship_to_org_id: '
                          || p_ship_from_org_id
                         );
   END get_ship_from_address;

   PROCEDURE calc_item_cateories (
      p_item_id           IN       mtl_item_categories.inventory_item_id%TYPE,
      p_organization_id   IN       mtl_item_categories.organization_id%TYPE,
      o_segment1          OUT      mtl_categories_b.segment1%TYPE,
      o_segment2          OUT      mtl_categories_b.segment1%TYPE,
      o_segment3          OUT      mtl_categories_b.segment1%TYPE,
      o_segment4          OUT      mtl_categories_b.segment1%TYPE,
      o_segment5          OUT      mtl_categories_b.segment1%TYPE,
      o_segment6          OUT      mtl_categories_b.segment1%TYPE,
      o_segment7          OUT      mtl_categories_b.segment1%TYPE,
      o_segment8          OUT      mtl_categories_b.segment1%TYPE,
      o_segment9          OUT      mtl_categories_b.segment1%TYPE,
      o_segment10         OUT      mtl_categories_b.segment1%TYPE
   )
   IS
   BEGIN
      SELECT mc.segment1, mc.segment2, mc.segment3, mc.segment4,
                      mc.segment5, mc.segment6, mc.segment7, mc.segment8,
                      mc.segment9, mc.segment10
                 INTO o_segment1, o_segment2, o_segment3, o_segment4,
                      o_segment5, o_segment6, o_segment7, o_segment8,
                      o_segment9, o_segment10
                 FROM mtl_category_sets mcs,
                      mtl_item_categories mic,
                      mtl_categories_b mc
                WHERE mcs.category_set_name = g_category_set
                  AND mcs.category_set_id = mic.category_set_id
                  AND mic.inventory_item_id = p_item_id
                  AND mic.organization_id = g_organization_id
                  AND mc.category_id = mic.category_id
                  AND mc.enabled_flag = 'Y'
                  AND NVL (mc.disable_date, SYSDATE + 1) > SYSDATE;
   EXCEPTION
      WHEN OTHERS
      THEN
         o_segment1 := NULL;
         o_segment2 := NULL;
         o_segment3 := NULL;
         o_segment4 := NULL;
         o_segment5 := NULL;
         o_segment6 := NULL;
         o_segment7 := NULL;
         o_segment8 := NULL;
         o_segment9 := NULL;
         o_segment10 := NULL;
         xx_emf_pkg.write_log
                        (xx_emf_cn_pkg.cn_low,
                            'Item Category not found for Inventory_Item_id: '
                         || p_item_id
                         || ' Organization ID: '
                         || p_organization_id
                        );
   END calc_item_cateories;

  -- Procedure will count total, sucess, error records.
   PROCEDURE update_record_count
   IS
      x_total_cnt     NUMBER := 0;
      x_error_cnt     NUMBER := 0;
      x_success_cnt   NUMBER := 0;
      x_warn_cnt      NUMBER := 0;
   BEGIN
      x_total_cnt := g_total_cnt;
      x_error_cnt := g_error_cnt;
      x_success_cnt := g_success_cnt;
      x_warn_cnt := g_warn_cnt;
--Calling update record count Procedure of EMF Packg
      xx_emf_pkg.update_recs_cnt (p_total_recs_cnt        => x_total_cnt,
                                  p_success_recs_cnt      => x_success_cnt,
                                  p_warning_recs_cnt      => x_warn_cnt,
                                  p_error_recs_cnt        => x_error_cnt
                                 );
   END update_record_count;


   PROCEDURE xx_oe_populate_salesrep (
      o_errbuf            OUT      VARCHAR2,
      o_retcode           OUT      VARCHAR2,
      p_order_number      IN       NUMBER DEFAULT NULL,
      p_order_dt_from     IN       VARCHAR2 DEFAULT NULL,
      p_order_dt_to       IN       VARCHAR2 DEFAULT NULL
   )
   IS
      CURSOR c_order_details (
         cp_order_number      NUMBER,
         cp_order_date_from   DATE,
         cp_order_date_to     DATE
      )
      IS
         SELECT ooh.header_id, ooh.order_number, ool.line_id,
                ool.line_number, ool.line_type_id, ool.inventory_item_id,
                ool.ship_to_org_id, ool.subinventory, ool.org_id, haou.NAME,
                ott.NAME sales_order_type, ool.ordered_item, ool.salesrep_id,
                ool.ship_from_org_id, ool.invoice_to_org_id
           FROM oe_order_headers_all ooh,
                oe_order_lines_all ool,
                hr_all_organization_units haou,
                oe_transaction_types_tl ott
          WHERE ooh.header_id = ool.header_id
            AND ool.org_id = haou.organization_id
            AND ott.LANGUAGE = USERENV ('LANG')
            AND ooh.order_type_id = ott.transaction_type_id
            AND ooh.flow_status_code not in ('CLOSED','CANCELLED')
            AND TRUNC (ooh.order_number) =
                                       NVL (cp_order_number, ooh.order_number)
            AND TRUNC(ooh.ordered_date)   BETWEEN TRUNC(NVL(cp_order_date_from,ooh.ordered_date)
                                                           )
                                                       AND TRUNC (NVL(cp_order_date_to, ooh.ordered_date)
                                                           );

      --Local Variable
      x_error_code                  NUMBER         := xx_emf_cn_pkg.cn_success;
      --Item Category variable
      x_segment1                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment2                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment3                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment4                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment5                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment6                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment7                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment8                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment9                    mtl_categories_b.segment1%TYPE     := NULL;
      x_segment10                   mtl_categories_b.segment1%TYPE     := NULL;
      --Ship to address variable
      x_ship_to_party_id            hz_party_sites.party_id%TYPE;
      x_ship_to_party_name          hz_parties.party_name%TYPE;
      x_ship_to_account_number      hz_cust_accounts.account_number%TYPE;
      x_ship_to_party_site_number   hz_party_sites.party_site_number%TYPE;
      x_ship_to_party_site_name     hz_party_sites.party_site_name%TYPE;
      x_ship_to_address1            hz_locations.address1%TYPE;
      x_ship_to_address2            hz_locations.address2%TYPE;
      x_ship_to_address3            hz_locations.address3%TYPE;
      x_ship_to_city                hz_locations.city%TYPE;
      x_ship_to_county              hz_locations.county%TYPE;
      x_ship_to_postal_code         hz_locations.postal_code%TYPE;
      x_ship_to_state               hz_locations.state%TYPE;
      x_ship_to_country             hz_locations.country%TYPE;
      x_ship_to_location            hz_cust_site_uses_all.LOCATION%TYPE;
      x_ship_to_province            hz_locations.province%TYPE;          -- Added on 28-feb-2013
      x_ship_to_site_use_code       hz_cust_site_uses_all.site_use_code%TYPE;
      x_ship_to_site_use_id         hz_cust_site_uses_all.site_use_id%TYPE;
      x_ship_to_party_site_id       hz_party_sites.party_site_id%TYPE;
      x_transactable_flag           mtl_system_items_b.mtl_transactions_enabled_flag%TYPE;
      x_terr_id                     jtf_terr_all.terr_id%TYPE          := NULL;
      x_return_status               VARCHAR2 (1)                       := NULL;
      x_return_status_1             VARCHAR2 (1)                       := NULL;
      x_return_status_2             VARCHAR2 (1)                       := NULL;
      
      p_order_date_from            DATE;
      p_order_date_to              DATE;
-------------------------------------------------------------------------------
 /*
 Created By     : Raquib Iqbal
 Creation Date  : 08-MAY-2012
 Filename       :
 Description    : This procedure is used to populate the Salesrep to the respective order line

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 08-May-2012   1.0       Raquib Iqbal        Initial development.

 */
--------------------------------------------------------------------------------
   BEGIN
      
      --Call EMF procedure to set the env
      IF fnd_global.conc_request_id IS NOT NULL
      THEN
         -- Set the environment for conc process
         x_error_code := xx_emf_pkg.set_env;
      ELSE
         x_error_code :=
            xx_emf_pkg.set_env
                          (p_process_name      => 'XX_OE_POPULATE_SALESREP_FRM_TM');
      END IF;

      -- write message to concurrent log
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'INPUT PARAMETERS');
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '-----------------------------'
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Order Number : ' || p_order_number
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Order Date (From) : ' || p_order_dt_from
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Order Date (To) : ' || p_order_dt_to
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            '-----------------------------'
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Processing started');

     
      p_order_date_from := fnd_date.canonical_to_date(p_order_dt_from);
      p_order_date_to   := fnd_date.canonical_to_date(p_order_dt_to);
     
      g_total_cnt    := 0;
      g_error_cnt    := 0;
      g_success_cnt  := 0;
      g_warn_cnt     := 0;
       -- Update Lattest_flag with 'N' for  old records present in xx_oe_sales_credits table
      FOR c_order_detl_rec IN c_order_details (p_order_number,
                                                  p_order_date_from,
                                                  p_order_date_to
                                                 )
       LOOP                                          
         update xx_oe_sales_credits
          set lattest_flag = 'N'
         where header_id = c_order_detl_rec.header_id;
       END LOOP;
  
      --Open the Cursor
      FOR c_order_detalis_rec IN c_order_details (p_order_number,
                                                  p_order_date_from,
                                                  p_order_date_to
                                                 )
      LOOP
         g_total_cnt := g_total_cnt + 1;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Processing started for Order_number: '
                               || c_order_detalis_rec.order_number
                               || ' line number :'
                               || c_order_detalis_rec.line_number
                              );
         -- Get the Item Category
         calc_item_cateories
                   (p_item_id              => c_order_detalis_rec.inventory_item_id,
                    p_organization_id      => c_order_detalis_rec.ship_from_org_id,
                    o_segment1             => x_segment1,
                    o_segment2             => x_segment2,
                    o_segment3             => x_segment3,
                    o_segment4             => x_segment4,
                    o_segment5             => x_segment5,
                    o_segment6             => x_segment6,
                    o_segment7             => x_segment7,
                    o_segment8             => x_segment8,
                    o_segment9             => x_segment9,
                    o_segment10            => x_segment10
                   );

         IF x_segment4 IS NULL
         THEN
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Item Category is not defined for item : '
                                || c_order_detalis_rec.ordered_item
                               );
         END IF;

         --Get Ship to Address
         get_ship_from_address
                  (p_ship_from_org_id               => c_order_detalis_rec.ship_to_org_id,
                   o_ship_to_location               => x_ship_to_location,
                   o_ship_to_party_id               => x_ship_to_party_id,
                   o_ship_to_party_name             => x_ship_to_party_name,
                   o_ship_to_site_use_code          => x_ship_to_site_use_code,
                   o_ship_to_account_number         => x_ship_to_account_number,
                   o_ship_to_party_site_number      => x_ship_to_party_site_number,
                   o_ship_to_party_site_name        => x_ship_to_party_site_name,
                   o_ship_to_address1               => x_ship_to_address1,
                   o_ship_to_address2               => x_ship_to_address2,
                   o_ship_to_address3               => x_ship_to_address3,
                   o_ship_to_city                   => x_ship_to_city,
                   o_ship_to_county                 => x_ship_to_county,
                   o_ship_to_postal_code            => x_ship_to_postal_code,
                   o_ship_to_state                  => x_ship_to_state,
                   o_ship_to_country                => x_ship_to_country,
                   o_ship_to_province               => x_ship_to_province, -- Added on 28-feb-2013
                   o_ship_to_party_site_id          => x_ship_to_party_site_id,
                   o_ship_to_site_use_id            => x_ship_to_site_use_id
                  );

         IF x_ship_to_party_site_id IS NULL
         THEN
            xx_emf_pkg.write_log
                     (xx_emf_cn_pkg.cn_low,
                         'Ship from address not found for Ship_from_org_id: '
                      || c_order_detalis_rec.ship_from_org_id
                     );
         END IF;

         --Populate  jty_terr_1001_account_trans_gt temporary table
         ins_jty_terr_1001_acct_trans
                          (p_city                  => x_ship_to_city,
                           p_county                => x_ship_to_county,
                           p_state                 => x_ship_to_state,
                           p_province              => x_ship_to_province, -- Added on 28-feb-2013
                           p_postal_code           => x_ship_to_postal_code,
                           p_country               => x_ship_to_country,
                           p_brand                 => NULL,
                           p_subinventory          => c_order_detalis_rec.subinventory,
                           p_sales_order_type      => NULL,
                           p_party_id              => x_ship_to_party_id,
                           p_party_site_id         => x_ship_to_party_site_id,
                           p_category_code         => NULL,
                           p_division              => x_segment4,
                           p_enable_flag           => NULL,
                           o_return_status         => x_return_status
                          );

         IF x_return_status = 'S'
         THEN
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                ' Table JTY_TERR_1001_ACCOUNT_TRANS_GT populated successfully'
               );
         END IF;

         --Populate  jty_terr_1001_account_trans_gt temporary table
         ins_jtf_terr_results_gt_mt (o_return_status => x_return_status_1);

         --Now get the winning territory based on the higehest number of combination and Rank
         BEGIN
            x_terr_id := NULL;

            SELECT jtr.terr_id
              INTO x_terr_id
              FROM jtf_terr_results_gt_mt jtr
             WHERE jtr.num_winners = (SELECT MAX (num_winners)
                                        FROM jtf_terr_results_gt_mt)
               AND jtr.absolute_rank = (SELECT MAX (absolute_rank)
                                          FROM jtf_terr_results_gt_mt
                                         WHERE num_winners = jtr.num_winners);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Territory found...Terr_id: ' || x_terr_id
                                 );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'No Territory found'
                                    );
               x_terr_id := NULL;
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Multiple Territory found'
                                    );
               x_terr_id := NULL;
         END;

         --Populate Custom table based winning territory Salesrep
         ins_sales_credit_record
                                (p_header_id          => c_order_detalis_rec.header_id,
                                 p_line_id            => c_order_detalis_rec.line_id,
                                 p_territory_id       => x_terr_id,
                                 o_return_status      => x_return_status_2
                                );

         IF x_return_status_2 = 'S'
         THEN
            g_success_cnt := g_success_cnt + 1;
            xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                        'Record(s) populated successfully for Order_number: '
                     || c_order_detalis_rec.order_number
                     || ' line number :'
                     || c_order_detalis_rec.line_number
                    );
         ELSE
            xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                        'Record(s) NOT populated successfully for Order_number: '
                     || c_order_detalis_rec.order_number
                     || ' line number :'
                     || c_order_detalis_rec.line_number
                    );
            g_error_cnt := g_error_cnt + 1;        
            xx_emf_pkg.error (p_severity           => xx_emf_cn_pkg.CN_MEDIUM,
                        p_category                 => xx_emf_cn_pkg.CN_VALID,
                        p_error_text               => 'Record(s) NOT populated successfully in xx_oe_sales_credits',
                        p_record_identifier_1      => c_order_detalis_rec.order_number,
                        p_record_identifier_2      => c_order_detalis_rec.Header_id,
                        p_record_identifier_3      => c_order_detalis_rec.Line_id
                       );          
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Processing completed for Order_number: '
                               || c_order_detalis_rec.order_number
                               || ' line number :'
                               || c_order_detalis_rec.line_number
                              );
      END LOOP;

   /*   --All records fetched
      xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_low,
                        p_category                 => xx_emf_cn_pkg.cn_prc_err,
                        p_error_text               => 'Processing Started',
                        p_record_identifier_1      => p_order_number,
                        p_record_identifier_2      => p_order_date_from,
                        p_record_identifier_3      => p_order_date_to
                       );
      x_error_code := xx_emf_cn_pkg.cn_rec_err;*/
      --Print the Report
      update_record_count;
      xx_emf_pkg.create_report;
   EXCEPTION
      WHEN OTHERS
      THEN
          xx_emf_pkg.write_log
                    (xx_emf_cn_pkg.cn_low,
                     ' Error inside xx_oe_populate_salesrep :'||SQLERRM
                    );
          update_record_count;
          xx_emf_pkg.create_report;          
   END xx_oe_populate_salesrep;
END xx_oe_populate_salesrep_pkg;
/
