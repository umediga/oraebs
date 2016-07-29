DROP PACKAGE BODY APPS.XXOM_CUST_ADDR_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CUST_ADDR_PKG" 
IS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CUST_ADDR_PKG.sql
*
*   DESCRIPTION
* 
*   USAGE
* 
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
* 
*   DEPENDENCIES
*  
*   CALLED BY
* 
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     1.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
* Look at customer merge process and it's impact on the program and party site ids
* Need to get formal consignment from a DFF
* Need to get GP Pricing from somewhere?
* Add deliver tos
******************************************************************************************/
   PROCEDURE intg_cust_addr_extract (
      errbuf       OUT NOCOPY      VARCHAR2,
      retcode      OUT NOCOPY      NUMBER)
    --  p_category   IN              VARCHAR2

   IS
      v_status        VARCHAR2 (20);
      lv_count        NUMBER        := 0;
      l_proc_status   VARCHAR2 (1)  := 'P';
      l_recon_count   NUMBER        := 0;
      
      l_spine_territory_code   xxom_cust_addr_stg.spine_territory_code%TYPE;      
      l_neuro_territory_code   xxom_cust_addr_stg.neuro_terr_code%TYPE;
      l_recon_territory_code   xxom_cust_addr_stg.recon_terr_code%TYPE;
      l_recon_territory_code1  xxom_cust_addr_stg.recon1%TYPE;
      l_recon_territory_code2  XXOM_CUST_ADDR_STG.recon2%TYPE;
      l_recon_territory_code3  XXOM_CUST_ADDR_STG.recon3%TYPE;
      
      CURSOR terr_name_div_cur  (
                      l_party_site_number in varchar2 ) IS
      SELECT distinct xtcsd.division || '-' || xtcsd.product_code TERRITORY_NAME, division
      FROM   xx_terr_cust_salesrep_data xtcsd, fnd_lookup_values flv
      WHERE  party_site_number = l_party_site_number
      AND    division = flv.meaning
      AND    flv.lookup_type = 'INTG_FIELD_INVENTORY_DIVISIONS'
      AND    flv.language = 'US'
      AND    flv.enabled_flag = 'Y'
      and    flv.tag = '-'
      UNION
      SELECT TERRITORY_NAME, division
      FROM   xx_terr_cust_salesrep_data xtcsd, fnd_lookup_values flv
      WHERE  party_site_number = l_party_site_number
      AND    division = flv.meaning
      AND    flv.lookup_type = 'INTG_FIELD_INVENTORY_DIVISIONS'
      AND    flv.language = 'US'
      AND    flv.enabled_flag = 'Y'
      AND    nvl(flv.tag,'qqqqq') <> '-'
      ;

      CURSOR cust_addr_cur
      IS
         SELECT hca.cust_account_id, party.party_name locationname,
                hca.account_number customernumber,
                hl.address1 physicaladdressline1,
                hl.address2 physicaladdressline2, hl.city physicalcity,
                hl.state physicalstate, hl.postal_code physicalzip,
                hl.county county,
                l_cat.meaning location_type,
                hcsua_s.site_use_code,
                hcsua_s.primary_flag, 
                cp.credit_hold credit_hold,
                hca.customer_type customer_type,
                l_cat.meaning customer_category_meaning,
                l_type.meaning customer_type_meaning,
                party.status party_status, hca.status cust_status,
                hcasa_s.status acct_site_status,
                hps.status party_site_status, hcsua_s.status site_use_status,
                hps.party_site_number externalsystemid,
                -- BXS these need gotten from territory manager
                null recon_territory_code,
                null neuro_territory_code,
                rcm.duplicate_site_number duplicatesitenumber,
                rcm.customer_site_number newsitenumber,
                hcsua_s.cust_acct_site_id,
                -- BXS these need gotten from territory manager
                null spine_territory_code,
                    null Recon1,
                    null Recon2,
                null Recon3,
                'N' gpo_pricing, -- bxs - not wave1 requirement
                'N' formal_consignment, -- bxs - not wave 1 requirement
                NULL resource_id    --Always null for the addresses on this half of the UNION
           FROM hz_parties party,
                hz_cust_accounts hca,
                hz_cust_acct_sites_all hcasa_s,
                hz_cust_acct_sites_all hcasa_b,
                hz_party_sites hps,
                hz_locations hl,
                hz_cust_site_uses_all hcsua_s,
                hz_cust_site_uses_all hcsua_b,
                ar_lookups l_cat,
                ar_lookups l_type,
                hz_cust_profile_classes cpc,
                hz_customer_profiles cp,
                xxom_cust_addr_stg xcas,
                ra_customer_merges rcm,
                ra_customer_merge_headers rcmh
          WHERE party.party_id = hca.party_id
            AND hca.cust_account_id = hcasa_s.cust_account_id
            AND hcasa_s.cust_acct_site_id = hcsua_s.cust_acct_site_id
            AND hps.party_site_id = hcasa_s.party_site_id
            AND hps.party_id = party.party_id
            and hl.country = 'US'
            AND hps.location_id = hl.location_id
          --AND hca.cust_account_id(+) = rcm.customer_id
            AND hps.party_site_number = rcm.customer_site_number(+)
            AND rcmh.customer_merge_header_id(+) = rcm.customer_merge_header_id
            AND hca.customer_class_code = l_cat.lookup_code(+)
            AND l_cat.lookup_type(+) = 'CUSTOMER CLASS'
            AND hca.customer_type = l_type.lookup_code(+)
            AND l_type.lookup_type(+) = 'CUSTOMER_TYPE'
            AND hcsua_s.site_use_code = 'SHIP_TO'
            AND hcasa_b.cust_acct_site_id(+) = hcsua_b.cust_acct_site_id
            AND hcsua_b.site_use_code(+) = 'BILL_TO'
            AND hcsua_b.site_use_id(+) = cp.site_use_id
            AND cp.site_use_id IS NULL
            AND cp.profile_class_id = cpc.profile_class_id(+)
            AND cp.cust_account_id = hca.cust_account_id
--AND hcsua.site_use_id = cp.site_use_id(+)
            AND l_type.meaning = 'External'
            AND rcm.delete_duplicate_flag(+) = 'Y'  -- Added by Ravi on 06/30/10 to eliminate duplicates customers
            AND hl.country = 'US' -- Added by Krishna
            AND l_cat.meaning IN (
                   SELECT flex_value
                     FROM apps.fnd_flex_values_vl ffvv,
                          apps.fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name =
                                                'INTG_CNSGN_CUST'
                      AND ffvv.enabled_flag = 'Y'
                      AND ffvv.flex_value_set_id = ffvs.flex_value_set_id)
                     -- AND ffvv.flex_value = p_category)
            AND rcmh.process_flag(+) = 'Y'
            AND rcm.customer_site_code(+) = 'SHIP_TO'
            AND xcas.cust_acct_site_id (+) = hcsua_s.cust_acct_site_id
            AND hca.customer_type = 'R'
            AND (
                  ( greatest(hca.last_update_date, hcasa_s.last_update_date, hps.last_update_date, hl.last_update_date,
                           hcsua_s.last_update_date, cp.last_update_date) >
                                              nvl((SELECT MAX (to_date(transaction_date,'DD-MON-RRRR HH24:MI:SS'))
                                                       FROM xxom_cust_addr_stg
                                                      WHERE party_site_number = hps.party_site_number),
                                                       greatest(hca.last_update_date, hcasa_s.last_update_date,
                                                                hps.last_update_date, hl.last_update_date, hcsua_s.last_update_date,
                                                                 cp.last_update_date)-1)
                                ) -- first part of OR
              
              -- THIS NEEDS TO LOOK AT THE TERRITORY CODES FOR UPDATES            
              OR (EXISTS (
                           (
                           SELECT DISTINCT DECODE (flv.tag, 
                                          '-', xtcsd.division || '-' || xtcsd.product_code, 
                                          xtcsd.territory_name) territory_name
                           from xx_terr_cust_salesrep_data xtcsd, fnd_lookup_values flv
                           where xtcsd.party_site_number = hps.party_site_number -- 90899
                           and xtcsd.division = flv.meaning -- nvl(xtcsd.division, 'RECON') = flv.meaning
                           and flv.lookup_type = 'INTG_FIELD_INVENTORY_DIVISIONS'
                           and flv.language = 'US'
                           and flv.enabled_flag = 'Y'
                           MINUS
                           select distinct territory_name
                           from xxom_cust_addr_stg_v xcasv
                           where xcasv.party_site_number = hps.party_site_number -- 90899
                           )  -- select 1 of union
                        UNION
                           (
                           select distinct territory_name
                           from xxom_cust_addr_stg_v xcasv
                           where xcasv.party_site_number = hps.party_site_number -- 90899
                           MINUS
                           SELECT DISTINCT DECODE (flv.tag, 
                                          '-', xtcsd.division || '-' || xtcsd.product_code, 
                                          xtcsd.territory_name) territory_name
                           from xx_terr_cust_salesrep_data xtcsd, fnd_lookup_values flv
                           where xtcsd.party_site_number = hps.party_site_number -- 90899
                           and xtcsd.division = flv.meaning -- nvl(xtcsd.division, 'RECON') = flv.meaning
                           and flv.lookup_type = 'INTG_FIELD_INVENTORY_DIVISIONS'
                           and flv.language = 'US'
                           and flv.enabled_flag = 'Y'
                           ) -- select 2 of union
                        ) -- exists?

                  ) -- 2nd part of OR
              ) -- AND
         UNION
         SELECT hca.cust_account_id, party.party_name locationname,
                hca.account_number customernumber,
                hl.address1 physicaladdressline1,
                hl.address2 physicaladdressline2, hl.city physicalcity,
                hl.state physicalstate, hl.postal_code physicalzip,
                hl.county county,
                l_cat.meaning location_type,
                hcsua_d.site_use_code,
                hcsua_d.primary_flag, 
                NULL, --cp.credit_hold credit_hold,
                hca.customer_type customer_type,
                l_cat.meaning customer_category_meaning,
                l_type.meaning customer_type_meaning,
                party.status party_status, hca.status cust_status,
                hcasa_d.status acct_site_status,
                hps.status party_site_status, hcsua_d.status site_use_status,
                hps.party_site_number externalsystemid,
                -- BXS these need gotten from territory manager
                null recon_territory_code,
                null neuro_territory_code,
                rcm.duplicate_site_number duplicatesitenumber,
                rcm.customer_site_number newsitenumber,
                hcsua_d.cust_acct_site_id,
                -- BXS these need gotten from territory manager
                null spine_territory_code,
                    null Recon1,
                    null Recon2,
                null Recon3,
                'N' gpo_pricing, -- bxs - not wave1 requirement
                'N' formal_consignment, -- bxs - not wave 1 requirement
                hps.attribute1 resource_id --Question: Should this half of the UNION also join this value to jtf_rs_salesreps and back to hz_parties - to avoid any cross-linked addresses?
           FROM hz_parties party,
                hz_cust_accounts hca,
                hz_cust_acct_sites_all hcasa_d,
                hz_party_sites hps,
                hz_locations hl,
                hz_cust_site_uses_all hcsua_d,
                ar_lookups l_cat,
                ar_lookups l_type,
                xxom_cust_addr_stg xcas,
                ra_customer_merges rcm,
                ra_customer_merge_headers rcmh
          WHERE party.party_id = hca.party_id
            AND hca.cust_account_id = hcasa_d.cust_account_id
            AND hcasa_d.cust_acct_site_id = hcsua_d.cust_acct_site_id
            AND hps.party_site_id = hcasa_d.party_site_id
            AND hps.party_id = party.party_id
            and hl.country = 'US'
            AND hps.location_id = hl.location_id
          --AND hca.cust_account_id(+) = rcm.customer_id
            AND hps.party_site_number = rcm.customer_site_number(+)
            AND rcmh.customer_merge_header_id(+) = rcm.customer_merge_header_id
            AND hca.customer_class_code = l_cat.lookup_code(+)
            AND l_cat.lookup_type(+) = 'CUSTOMER CLASS'
            AND hca.customer_type = l_type.lookup_code(+)
            AND l_type.lookup_type(+) = 'CUSTOMER_TYPE'
            AND hcsua_d.site_use_code = 'DELIVER_TO'
            AND rcm.delete_duplicate_flag(+) = 'Y'  -- Added by Ravi on 06/30/10 to eliminate duplicates customers
            AND l_cat.meaning IN (
                   SELECT flex_value
                     FROM apps.fnd_flex_values_vl ffvv,
                          apps.fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name =
                                                'INTG_CNSGN_CUST'
                      AND ffvv.enabled_flag = 'Y'
                      AND ffvv.flex_value_set_id = ffvs.flex_value_set_id)
            AND rcmh.process_flag(+) = 'Y'
            AND rcm.customer_site_code(+) = 'SHIP_TO'
            AND xcas.cust_acct_site_id (+) = hcsua_d.cust_acct_site_id
            AND hps.attribute1 IS NOT NULL
            AND GREATEST (hca.last_update_date, 
                          hcasa_d.last_update_date, 
                          hps.last_update_date,
                          hl.last_update_date,
                          hcsua_d.last_update_date) > NVL ((SELECT MAX (to_date(transaction_date,'DD-MON-RRRR HH24:MI:SS'))
                                                              FROM xxom_cust_addr_stg
                                                             WHERE party_site_number = hps.party_site_number),
                                                           GREATEST (hca.last_update_date, 
                                                                     hcasa_d.last_update_date,
                                                                     hps.last_update_date, 
                                                                     hl.last_update_date, 
                                                                     hcsua_d.last_update_date)-1);
                                                                 
BEGIN
      FOR cust_addr_rec IN cust_addr_cur
      LOOP
         v_status:= NULL;


         -- Validate if the customer address, business purpose or customers are active else inactive
         IF     (cust_addr_rec.party_status = 'A')
            AND (cust_addr_rec.cust_status = 'A')
            AND (cust_addr_rec.acct_site_status = 'A')
            AND (cust_addr_rec.party_site_status = 'A')
            AND (cust_addr_rec.site_use_status = 'A')
         THEN
            v_status := 'ACTIVE';
         ELSE
            v_status := 'INACTIVE';
         END IF;
         
         -- 
         -- lookup the territory codes here
         --
        FOR terr_name_div_rec IN terr_name_div_cur ( cust_addr_rec.externalsystemid )
        LOOP
        
          IF terr_name_div_rec.division = 'SPINE' THEN
             -- FOR NOW IT WILL RESET EVERY TIME IF MORE THAN ONE
             l_spine_territory_code := terr_name_div_rec.territory_name;
          ELSIF terr_name_div_rec.division = 'NEURO' THEN
             -- FOR NOW IT WILL RESET EVERY TIME IF MORE THAN ONE
             l_neuro_territory_code := terr_name_div_rec.territory_name;
          ELSIF terr_name_div_rec.division = 'RECON' THEN
          
             l_recon_count := l_recon_count + 1;
             
             IF l_recon_count = 1 THEN
                l_recon_territory_code := terr_name_div_rec.territory_name;
             ELSIF l_recon_count = 2 THEN
                l_recon_territory_code1 := terr_name_div_rec.territory_name;
             ELSIF l_recon_count = 3 THEN
                  l_recon_territory_code2 := terr_name_div_rec.territory_name;
             ELSIF l_recon_count = 4 THEN
                l_recon_territory_code3 := terr_name_div_rec.territory_name;
             ELSE
                l_recon_territory_code3 := terr_name_div_rec.territory_name;
                fnd_file.put_line (fnd_file.LOG,
                         'Recon territory codes have exceeded the maximum of 4.');
             END IF;
          END IF;

        END LOOP;
         

         INSERT INTO XXOM_CUST_ADDR_STG
                     (transaction_id,
                      transaction_date,
                      exported_date,
                      location_name,
                      customer_number,
                      cust_address1,
                      cust_address2,
                      cust_city,
                      cust_state,
                      cust_zip,
                      cust_county,
                      cust_loc_type,
                      cust_credit_hold,
                      cust_status,
                      cust_acct_site_id,
                      party_site_number,
                      recon_terr_code,
                      neuro_terr_code,
                      old_customer_site_number,
                      spine_territory_code,
                      recon1,
                        recon2,
                      recon3,
                      gpo_pricing, -- bxs
                      formal_consignment, -- bxs
                      resource_id,
                      customer_use,
                      customer_type,
                      primary_flag,
                      creation_date,
                      last_update_date,
                      status,
                      MESSAGE,
                      created_by,
                      last_updated_by
                     )
              VALUES  
                     (
                      XXOM_CUST_ADDR_STG_SEQ.NEXTVAL,
                      l_proc_date,
                      l_proc_date,
                      cust_addr_rec.locationname,
                      cust_addr_rec.customernumber,
                      cust_addr_rec.physicaladdressline1,
                      cust_addr_rec.physicaladdressline2,
                      cust_addr_rec.physicalcity,
                      cust_addr_rec.physicalstate,
                      cust_addr_rec.physicalzip,
                      cust_addr_rec.county,
                      cust_addr_rec.location_type, -- 'Hospital', etc
                      cust_addr_rec.credit_hold,
                      v_status,
                      cust_addr_rec.cust_acct_site_id,
                      cust_addr_rec.externalsystemid,
                      l_recon_territory_code, -- cust_addr_rec.recon_territory_code,
                      l_neuro_territory_code, -- cust_addr_rec.neuro_territory_code,
                      NULL, -- bxs in place of commented out lines
                      /* BXS
                      cust_addr_rec.duplicatesitenumber,
                      */
                      l_spine_territory_code, -- cust_addr_rec.spine_territory_code,
                          l_recon_territory_code1, -- cust_addr_rec.recon1,
                          l_recon_territory_code2, -- cust_addr_rec.recon2,
                      l_recon_territory_code3, -- cust_addr_rec.recon3,
                      cust_addr_rec.gpo_pricing,
                      cust_addr_rec.formal_consignment,
                      cust_addr_rec.resource_id,
                      cust_addr_rec.site_use_code, -- customer_use
                      cust_addr_rec.customer_type,
                      cust_addr_rec.primary_flag,
                      SYSDATE, -- creation_date
                      SYSDATE, -- last_update_date
                      NULL, -- status
                      NULL,  -- message
                      NULL, -- created_by
                      NULL  -- last_updated_by
                     );

         lv_count := lv_count + 1;
         
               
         l_spine_territory_code := NULL;
         l_recon_territory_code := NULL;
         l_neuro_territory_code := NULL;
         l_recon_territory_code1 := NULL;
         l_recon_territory_code2 := NULL;
         l_recon_territory_code3 := NULL;
         
         l_recon_count := 0;
         
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                         'The Total Number of Records Inserted into XXOM_CUST_ADDR_STG Table is:' || lv_count
                        );

      IF l_proc_status = 'P'
      THEN
        intg_log_message ('Data Loaded into Table Successfully','PROCESSED');
        COMMIT;
      ELSE
        ROLLBACK;
        fnd_file.put_line
            (fnd_file.LOG,
                'No Data loaded into Staging table:'
             || SQLERRM
            );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
       fnd_file.put_line
            (fnd_file.LOG,
                'No Data loaded into Staging table:'
             || SQLERRM
            );
         ROLLBACK;
         intg_log_message ('Unable to insert into Staging table XXOM_CUST_ADDR_STG..','ERROR');
   END intg_cust_addr_extract;

   PROCEDURE intg_log_message (
      p_msg        IN   VARCHAR2,
      p_status     IN   VARCHAR2
     -- p_trans_id   IN   NUMBER
   )
   IS
   BEGIN
      UPDATE XXOM_CUST_ADDR_STG
         SET status = p_status,
             MESSAGE = p_msg;
      -- WHERE transaction_id = p_trans_id;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Log_msg: ' || SQLERRM);
   END intg_log_message;

END XXOM_CUST_ADDR_PKG;
/
