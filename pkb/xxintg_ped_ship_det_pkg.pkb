DROP PACKAGE BODY APPS.XXINTG_PED_SHIP_DET_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_PED_SHIP_DET_PKG" 
AS

   ----------------------------------------------------------------------
   /*
    Created By     : Shankar Narayanan
    Creation Date  : 30-AUG-2013
    File Name      : XXINTG_Pedigree_PKG.pkb
    Description    : This script creates the package body for the xxintg_PED_SHIP_DET_PKG package


   Change History:

   Version Date          Name                Remarks
   ------- -----------   -----------------    -------------------------------
   1.0     30-AUG-2013   Shankar Narayanan       Initial development.
   
   */
   ----------------------------------------------------------------------
   
   PROCEDURE intg_PED_SHIP_DET_PRC (errbuf     OUT VARCHAR2,
                                    retcode    OUT VARCHAR2,
                                    p_org_id       NUMBER,
                                    p_date         VARCHAR2)
   IS
   
   ----------------------------------------------------------------------
   /**************************************************************************************
   *
   *   PROCEDURE
   *     intg_PED_SHIP_DET_PRC
   *
   *   DESCRIPTION
   *   Derives the Pedigree related shipping, customer, delivery information and poppulates the custom stg table
   *
   *   PARAMETERS
   *   ==========
   *   NAME               TYPE             DESCRIPTION
   *   -----------------  --------         -----------------------------------------------
   *   p_org_id           number        Inventory Organization ID of the shipping org (SL City DC)
   *   p_date          varchar2        Delivery Confirmation Date
   *
   *
   *   RETURN VALUE
   *   NA
   *
   *   PREREQUISITES
   *   NA
   *
   *   CALLED BY
   *   A Concurrent Program Named INTG Pedigree Interface to Intuitive
   *
   **************************************************************************************/
   
      l_fname      VARCHAR2 (500);
      l_file_dir   VARCHAR2 (500);
      l_errmsg     VARCHAR2 (500);
      
      v_st_lic_number varchar2(200) := '';
      v_st_exp_date   date;
      v_bt_lic_number varchar2(200) := '';
      v_bt_exp_date   date;     
      v_st_address1   varchar2(150);
      v_st_address2   varchar2(150);
      v_st_address3   varchar2(150);
      v_st_city       varchar2(150);
      v_st_zip          varchar2(150);
      v_st_state      varchar2(150);
      v_st_country    varchar2(150);
     

      CURSOR cur_ship_det
      IS
               SELECT   DISTINCT wdd.source_header_number sonumber, -- distinct ??
                           wdd.source_line_number soline,
                           wdd.shipped_quantity shippedqty,
                           msi.concatenated_segments item,
                           msi.description itemdescription,
                           wdd.cust_po_number customerpo,
                           TRIM(wdd.lot_number) lotnumber,
                           wnd.name delivery,
                           wdd.delivery_detail_id,
                           wnd.confirm_date shipdate,
                           wnd.confirmed_by shippedby,
                           wl.address1 address1,
                           wl.address2 address2,
                           wl.city city,
                           wl.state state,
                           wl.postal_code zip,
                           mp.organization_code shipfrom,
                           hp.party_name customer,
                           hp1.party_name shiptocustomer,
                           ooh.attribute10 custemail
           FROM   wsh_new_deliveries wnd,
                  wsh_locations wl,
                  wsh_delivery_details wdd,
                  wsh_delivery_assignments wda,
                  mtl_system_items_kfv msi,
                  mtl_parameters mp,
                  hz_cust_Accounts_all hca, --
                  hz_parties hp,
                  mtl_categories mc,
                  mtl_category_Sets mcs,
                  mtl_item_categories mic,
                  oe_order_headers_all ooh,
                  hz_party_sites hps,
                  hz_parties hp1,
                  hz_cust_acct_sites_all hcas,
                  hz_cust_site_uses_all hcsu
          WHERE   NOT EXISTS (select 1 from XXINTG_IPM_PEDIGREE where delivery_detail_id = wdd.delivery_detail_id and status = 'DONE') -- Jagdish 05/08/2014 --
                  --1=1
                  AND wnd.ultimate_dropoff_location_id = wl.wsh_location_id
                  AND wda.delivery_id = wnd.delivery_id
                  AND wda.delivery_detail_id = wdd.delivery_detail_id
                  AND msi.inventory_item_id = wdd.inventory_item_id
                  AND msi.organization_id = wdd.organization_id
                  AND wdd.ship_to_site_use_id = hcsu.site_use_id
                  AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                  AND hcas.party_Site_id = hps.party_Site_id
                  AND wdd.released_Status = 'C'
                  AND hp.party_id = hca.party_id
                  AND hca.cust_account_id = wdd.CUSTOMER_ID
                  AND ooh.order_number = wdd.source_header_number
                  AND mp.organization_id = wdd.organization_id
                  --AND TRUNC (wnd.confirm_date) = TRUNC(NVL (TO_DATE (p_date, 'YYYY/MM/DD HH24:MI:SS'),TO_DATE (SYSDATE-15, 'YYYY/MM/DD HH24:MI:SS')))
                  --AND TRUNC (wnd.confirm_date) > trunc(sysdate) - 1                    
                  AND mp.organization_id = p_org_id
                  AND upper(mc.segment1) = 'SALT LAKE CITY'
                  AND mcs.category_set_name = 'FG_SOURCE_SITE'
                  AND mcs.category_set_id = mic.category_set_id
                  AND mic.category_id = mc.category_id
                  AND mic.inventory_item_id = msi.inventory_item_id
                  AND mic.organization_id = mp.organization_id
                  AND hps.location_id = wl.wsh_location_id
                  AND hp1.party_id = hps.party_id;
                     

               e_exception exception;
                  
   BEGIN
      Fnd_File.PUT_LINE (Fnd_File.LOG,
                         '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      Fnd_File.PUT_LINE (Fnd_File.LOG,
                         'Inside procedure INTG_PED_SHIP_DET_PRC ');
      Fnd_File.PUT_LINE (Fnd_File.LOG,
                         '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');


      FOR rec_ship_det IN cur_ship_det
      LOOP
        Fnd_File.PUT_LINE (Fnd_File.LOG,'Processing Delivery ID - '||rec_ship_det.Delivery_Detail_id);
      
         BEGIN
         
            BEGIN
      
          
          v_st_lic_number := '';
          v_st_exp_date   := '';
          v_bt_lic_number := '';
          v_bt_exp_date   := ''; 
          v_st_address1      := '';
          v_st_address2      := '';
          v_st_address3      := '';
          v_st_city      := '';
          v_st_zip      := '';
          v_st_state      := '';
          v_st_country      := '';
          
          
          ----------------------------------------------------------------------------------
          -- Get the license # and date details for Pedigree customers Bill To 
          ----------------------------------------------------------------------------------
          
            BEGIN

                --Fnd_File.PUT_LINE (Fnd_File.LOG,'Deriving Bill To License  - '||rec_ship_det.Delivery_Detail_id);
                SELECT stg.REG_NUMBER ,STG.end_date
                INTO   v_bt_lic_number, v_bt_exp_date
                FROM   apps.hz_parties hp,
                       apps.hz_cust_accounts hca,
                       apps.hr_operating_units hou,
                       apps.hz_party_sites party_site,
                       apps.hz_locations loc,
                       apps.HZ_CUST_ACCT_SITES_ALL sites,
                       apps.hz_cust_site_uses_all site_uses
                       ,oe_order_headers_all h, oe_order_lines_all l
                       ,XXINTG_ITEM_ORDERABILITY_V  stg
                 WHERE hP.party_id = hca.party_id
                   AND hp.STATUS = 'A'
                   AND hca.STATUS = 'A'
                   AND PARTY_SITE.PARTY_ID      = HP.PARTY_ID
                   AND hca.cust_account_id      = sites.cust_account_id
                   AND sites.PARTY_SITE_ID      = PARTY_SITE.PARTY_SITE_ID
                   AND PARTY_SITE.LOCATION_ID   = LOC.LOCATION_ID
                   AND sites.cust_acct_site_id  = site_uses.cust_acct_site_id
                 AND site_uses.site_use_code  = 'BILL_TO' 
                   AND site_uses.STATUS         = 'A'
                   AND HOU.ORGANIZATION_ID      = sites.ORG_ID
                    AND h.header_id = l.header_id
                and  hca.cust_account_id = l.sold_to_org_id
                and   stg.inventory_item_id = l.inventory_item_id  
                and   RULE_LEVEL = 'BILL_TO_LOC'
                and h.order_number = rec_ship_det.sonumber --49507
                and  site_uses.location = stg.BILL_TO_LOCATION_ID
                and  rownum = 1; 
                
                
                exception when others then                
                --raise e_exception;
                Fnd_File.PUT_LINE (Fnd_File.LOG,'EXCEPTION: Deriving Bill To License #  - '||rec_ship_det.Delivery_Detail_id);
                null;


            END;


          ----------------------------------------------------------------------------------
          -- Get the license # and date details for Pedigree customers Ship To 
          ----------------------------------------------------------------------------------

                BEGIN
                
                --Fnd_File.PUT_LINE (Fnd_File.LOG,'Deriving Ship To License #  - '||rec_ship_det.Delivery_Detail_id);

                SELECT stg.REG_NUMBER ,STG.end_date   
                INTO   v_st_lic_number, v_st_exp_date
                FROM   apps.hz_parties hp,
                       apps.hz_cust_accounts hca,
                       apps.hr_operating_units hou,
                       apps.hz_party_sites party_site,
                       apps.hz_locations loc,
                       apps.HZ_CUST_ACCT_SITES_ALL sites,
                       apps.hz_cust_site_uses_all site_uses
                       ,oe_order_headers_all h, oe_order_lines_all l
                       ,XXINTG_ITEM_ORDERABILITY_V  stg
                 WHERE hP.party_id = hca.party_id
                   AND hp.STATUS = 'A'
                   AND hca.STATUS = 'A'
                   AND PARTY_SITE.PARTY_ID      = HP.PARTY_ID
                   AND hca.cust_account_id      = sites.cust_account_id
                   AND sites.PARTY_SITE_ID      = PARTY_SITE.PARTY_SITE_ID
                   AND PARTY_SITE.LOCATION_ID   = LOC.LOCATION_ID
                   AND sites.cust_acct_site_id  = site_uses.cust_acct_site_id
                 AND site_uses.site_use_code  = 'SHIP_TO' 
                   AND site_uses.STATUS         = 'A'
                   AND HOU.ORGANIZATION_ID      = sites.ORG_ID
                    AND h.header_id = l.header_id
                and  hca.cust_account_id = l.sold_to_org_id
                and   stg.inventory_item_id = l.inventory_item_id --145432   
                and   RULE_LEVEL = 'SHIP_TO_LOC'
                and h.order_number = rec_ship_det.sonumber --49507
                and  site_uses.location = stg.SHIP_TO_LOCATION_ID
                and  rownum = 1;      
                
                
                exception when others then 
                Fnd_File.PUT_LINE (Fnd_File.LOG,'EXCEPTION: Deriving Ship To License #  - '||rec_ship_det.Delivery_Detail_id);                      
                --raise e_exception;
                null;
                
                END;

            END;        
          
          
 
 
             BEGIN
             
             
          ----------------------------------------------------------------------------------
       -- Set the environment
          ----------------------------------------------------------------------------------
                
 
       /*    Begin
                     
                     mo_global.set_policy_context('S', fnd_global.org_id);
                     
           End;
         */  

          ----------------------------------------------------------------------------------
          -- Get the ST address information
          ----------------------------------------------------------------------------------           
 
        BEGIN
            --fnd_file.put_line(fnd_file.LOG,'Location Derivation delivery detail ID '|| rec_ship_det.delivery_detail_id);
            SELECT LOC.ADDRESS1,LOC.ADDRESS2,LOC.ADDRESS3,LOC.CITY,LOC.POSTAL_CODE,LOC.STATE,LOC.COUNTRY  
            INTO   v_st_address1, v_st_address2, v_st_address3, v_st_city, v_st_zip, v_st_state, v_st_country
            FROM   apps.hz_parties hp,
                   apps.hz_cust_accounts hca,
                   apps.hr_operating_units hou,
                   apps.hz_party_sites party_site,
                   apps.hz_locations loc,
                   apps.HZ_CUST_ACCT_SITES_ALL sites,
                   apps.hz_cust_site_uses_all site_uses
                   ,apps.oe_order_headers_all ooha
                   ,OE_ORDER_HEADERS_V ohv
             WHERE 1=1
               AND hP.party_id = hca.party_id
               AND hp.STATUS = 'A'
               AND hca.STATUS = 'A'
               AND PARTY_SITE.PARTY_ID      = HP.PARTY_ID
               AND hca.cust_account_id      = sites.cust_account_id
               AND sites.PARTY_SITE_ID      = PARTY_SITE.PARTY_SITE_ID
               AND PARTY_SITE.LOCATION_ID   = LOC.LOCATION_ID
               AND sites.cust_acct_site_id  = site_uses.cust_acct_site_id
               AND site_uses.site_use_code  = 'BILL_TO' 
               AND site_uses.STATUS         = 'A'
               AND HOU.ORGANIZATION_ID      = sites.ORG_ID
               AND ooha.sold_to_org_id      = hca.cust_account_id
               and ohv.header_id            = ooha.header_id
               and ooha.order_number        = rec_ship_det.sonumber
               and ohv.INVOICE_TO_ORG_ID    = site_uses.location;


        exception when others then  
            fnd_file.put_line(fnd_file.LOG,'Failed During Location Derivation delivery detail ID '|| rec_ship_det.delivery_detail_id);                      
            raise e_exception;
 
       END;        
 
           ----------------------------------------------------------------------------------
           -- Insert into the custom staging table which is polled by the WebService
           ----------------------------------------------------------------------------------    
         fnd_file.put_line(fnd_file.LOG,'Before Stage Table Insert '|| rec_ship_det.delivery_detail_id); 
         INSERT INTO --XXINTG_IPM_PEDIGREE_TAB
                     XXINTG_IPM_PEDIGREE
                         (Sales_Order_Number,
                                        Sales_Order_Line,
                                        Shipped_Quantity,
                                        Item,
                                        Item_Description,
                                        Customer_PO,
                                        Lot_Number,
                                        Delivery,
                                        delivery_Detail_id,
                                        Ship_Date,
                                        Shipped_By,
                                        Address1,
                                        Address2,
                                        City,
                                        State,
                                        Zip,
                                        Ship_From,
                                        Customer,
                                        Ship_To_Customer,
                                        Customer_Email
                                        ,CREATION_DATE -- SEP-12
                                        ,ShipToDrugLicense
                                        ,ShipToLicenseExpiration
                                        ,SoldToDrugLicense
                                        ,SoldToLicenseExpiration
                                        ,status
                                        ,soldto_ADDRESS1
                                        ,soldto_ADDRESS2
                                        ,soldto_ADDRESS3
                                        ,soldto_CITY
                                        ,soldto_STATE
                                        ,soldto_ZIP
                                        ,soldto_country
                    )
           VALUES   (rec_ship_det.SONumber,
                     rec_ship_det.SOLine,
                     rec_ship_det.ShippedQty,
                     rec_ship_det.Item,
                     rec_ship_det.ItemDescription,
                     rec_ship_det.CustomerPO,
                     rec_ship_det.LotNumber,
                     rec_ship_det.Delivery,
                     rec_ship_det.Delivery_Detail_id,
                     TRUNC(rec_ship_det.ShipDate), -- 22-AUG-2013
                     rec_ship_det.ShippedBy,
                     rec_ship_det.Address1,
                     rec_ship_det.Address2,
                     rec_ship_det.City,
                     rec_ship_det.State,
                     rec_ship_det.Zip,
                     rec_ship_det.ShipFrom,
                     rec_ship_det.Customer,
                     rec_ship_det.ShipToCustomer,
                     rec_ship_det.Custemail
                     ,null -- SEP-12 creation_date
                     ,v_st_lic_number -- ShipToDrugLicense
                     ,v_st_exp_date -- ShipToLicenseExpiration
                     ,v_bt_lic_number -- SoldToDrugLicense
                     ,v_bt_exp_date --SoldToLicenseExpiration
                     ,'PENDING' -- status for SOA process
                     ,v_st_address1
                     ,v_st_address2
                     ,v_st_address3
                     ,v_st_city
                     ,v_st_state
                     ,v_st_zip                     
                     ,v_st_country
                     );
           
           
              EXCEPTION WHEN OTHERS THEN
                  Fnd_File.PUT_LINE (Fnd_File.LOG,'The error is : ' || SQLERRM);
                  RAISE e_exception;
            
            END;
             
             EXCEPTION 
         WHEN    e_exception THEN
         
                 fnd_file.put_line(fnd_file.LOG,'Insert operation failed. - skipping this record with delivery detail ID' || rec_ship_det.delivery_detail_id);
             
             WHEN OTHERS THEN
                 Fnd_File.PUT_LINE (Fnd_File.LOG,'When OTHERS error inside the loop!'||SQLERRM);
                     
         END;
         
      END LOOP;
      
            
      
      COMMIT; 
      
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ROLLBACK;
         apps.fnd_file.put_line (fnd_file.LOG, 'NO DATA FOUND while processing the Pedigree Interface');
      WHEN OTHERS
      THEN
         ROLLBACK;
         l_errmsg := SUBSTR (SQLERRM, 1, 100);
         apps.fnd_file.put_line (fnd_file.LOG, 'OTHERS Error Message while processing the Pedigree Interface ' || l_errmsg);
   END intg_PED_SHIP_DET_PRC;
END xxintg_PED_SHIP_DET_PKG; 
/
