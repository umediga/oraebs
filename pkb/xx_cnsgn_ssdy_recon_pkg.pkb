DROP PACKAGE BODY APPS.XX_CNSGN_SSDY_RECON_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CNSGN_SSDY_RECON_PKG" 
AS
   PROCEDURE log_message (p_log_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_log_message);
   END log_message;

  procedure build_onhand_summary (p_organization_id NUMBER) IS
  g_as_of_date_from date;
  g_as_of_date_to date;
  l_return_status varchar2(1);
  l_msg_count number;
  l_msg_data varchar2(4000);
  l_start_time number;
  l_end_time number;
  l_time_difference number;
  x_result varchar2(1);
  l_organization_id number;
begin
   l_organization_id := p_organization_id;
  /*-----------------------------------------------------------+
  |  Quantity Sources:                                         |
  |  table: cst_inv_qty_temp                                   |
  |  3 - Current Onhand Quantity                               |
  |  4 - Uncosted Onhand                                       |
  |  5 - Rollback onhand to the valuation date (Parameter)     |
  |  6 - Current Intransit                                     |
  |  7 - Uncosted Intransit                                    |
  |  8 - Rollback Intransit                                    |
  |  9 - Current Received                                      |
  |  10 - Rollback Receiving                                   |
  |                                                            |
  |  table cst_inv_cost_temp                                   |
  |  1 - Current cost value                                    |
  |  2 - Cost Updates done after valuation date                |
  |  3 - Current Receiving Cost                                |
  |  4 - Past Receiving Cost (Valuation date is not null)      |
+------------------------------------------------------------*/
--  fnd_global.apps_initialize(0,20420,1);
  delete cst_inv_qty_temp;
  delete cst_inv_cost_temp;
  delete cst_item_list_temp;
  delete cst_cg_list_temp;
  delete cst_sub_list_temp;
  delete xx_mtl_mwb_sum_gtmp;
  g_as_of_date_from := SYSDATE;--fnd_date.canonical_to_date(l_as_of_date_from);
  g_as_of_date_to := SYSDATE;--fnd_date.canonical_to_date(l_as_of_date_to) ;

  cst_inventory_pub.calculate_inventoryvalue(p_api_version => 1.0
                                             , p_init_msg_list => cst_utility_pub.get_true
                                             , p_organization_id => l_organization_id
                                             , p_onhand_value => 1
                                             , p_intransit_value => 0
                                             , p_receiving_value => 0
                                             , p_valuation_date => g_as_of_date_from    -- SYSDATE --
                                             , p_cost_type_id => 1
                                             , p_item_from => null
                                             , p_item_to => null
                                             , p_category_set_id => 1
                                             , p_category_from => null
                                             , p_category_to => null
                                             , p_cost_group_from => null
                                             , p_cost_group_to => null
                                             , p_subinventory_from => null
                                             , p_subinventory_to => null
                                             , p_qty_by_revision => null
                                             , p_zero_cost_only => 0
                                             , p_zero_qty => 0
                                             , p_expense_item => 0
                                             , p_expense_sub => 0
                                             , p_unvalued_txns => 0
                                             , p_receipt => 0
                                             , p_shipment => 0
                                             , p_own => 1
                                             , p_detail => 0
                                             , p_include_period_end => 0
                                             , x_return_status => l_return_status
                                             , x_msg_count => l_msg_count
                                             , x_msg_data => l_msg_data);
    commit;

  insert into xxintg.xx_mtl_mwb_sum_gtmp(inventory_item_id
                                       , organization_id
                                       , organization_code
                                       , item_number
                                       , item_description
                                       , qty
                                       , item_cost
                                       , value
                                       ,cost_group_id)
    select   ciq.inventory_item_id, ciq.organization_id, mp.organization_code, msi.segment1, msi.description, sum(ciq.rollback_qty) qty
           , cic.item_cost, sum(cic.item_cost * rollback_qty) value_at_cost,ciq.cost_group_id
    from     cst_inv_qty_temp ciq, mtl_system_items_b msi, mtl_parameters mp, cst_inv_cost_temp cic
    where        ciq.inventory_item_id = msi.inventory_item_id
             and ciq.organization_id = msi.organization_id
             and ciq.organization_id = mp.organization_id
             and ciq.inventory_item_id = cic.inventory_item_id
             and ciq.organization_id = cic.organization_id
             and ciq.qty_source = 3
    group by ciq.inventory_item_id
           , ciq.organization_id
           , msi.segment1
           , msi.description
           , mp.organization_code
           , cic.item_cost
           , ciq.cost_group_id
    order by mp.organization_code, msi.segment1;
  delete cst_inv_qty_temp;
  delete cst_inv_cost_temp;
  delete cst_item_list_temp;
  delete cst_cg_list_temp;
  delete cst_sub_list_temp;
  end build_onhand_summary;




   PROCEDURE get_onhand_qty (p_organization_code CHAR, p_retcode NUMBER, p_errbuf CHAR)
   IS
      l_organization_id   NUMBER;
      l_ret_code          NUMBER;
      l_errbuf            VARCHAR2 (2000);
--      CURSOR c_qty_sum IS
--      select inventory_item_id from xx_mtl_mwb_sum_gtmp;
   BEGIN
      log_message ('Begin - Get Organization Parameter ' || p_organization_code);

      SELECT organization_id
        INTO l_organization_id                                                                   --, l_organization_code
        FROM org_organization_definitions
       WHERE organization_code = NVL (p_organization_code, '150');

      log_message ('Organization ID Parameter ' || l_organization_id);

      DELETE FROM xx_mtl_mwb_gtmp;


      log_message ('--- Build Onhand Summary Table ----');
      build_onhand_summary(l_organization_id);


      log_message ('Truncated previous Onhand Quantity staging table ...');
      --select * from xx_mtl_mwb_gtmp

      --------------------------------------
-- Get Onhand Quantity --
--------------------------------------
      log_message ('Building Onhand Quantity staging table ...');

      INSERT INTO xx_mtl_mwb_gtmp
                  (organization_code,
                   org_id,
                   item,
                   item_id,
                   primary_uom_code,
                   subinventory_code,
                   locator_id,
                   LOCATOR,
                   lot,
                   serial,
                   onhand,
                   lpn,
                   lpn_id,
                   lot_expiry_date,
                   c_code,
                   d_code,
                   control_flag
                  )
         SELECT   p_organization_code organization_code,                                                           --  1
                  moqd.organization_id org_id,                                                                         --
                  msi.segment1 item,                                                                                   --
                  msi.inventory_item_id item_id,                                                                       --
                  msi.primary_uom_code,
                  moqd.subinventory_code,                                                                            --2
                  moqd.locator_id,                                                                                     --
                  NULL locator_code,                                                                                -- 3
                  moqd.lot_number lot,                                                                              -- 4
                  NULL serial,
                  SUM (moqd.primary_transaction_quantity) onhand,                                                   -- 5
                  NULL lpn,                                                                                     -- 6  --
                  moqd.lpn_id,                                                                                         --
                  NULL lot_expiry_date,                                                                          -- 7 --
                  NULL c_code,
                  NULL d_code,
                  'NO_LOT_SERIAL'
             FROM mtl_onhand_quantities_detail moqd,
                  mtl_system_items_b msi,
                  xx_mtl_mwb_sum_gtmp gtmp
            WHERE 1 = 1
              AND moqd.organization_id = l_organization_id                                        --:onh_organization_id
              AND moqd.inventory_item_id = msi.inventory_item_id
              AND moqd.organization_id = msi.organization_id
               --and msi.segment1 = '90250'--'121145'
              -- and msi.inventory_item_id = 141375
              AND msi.serial_number_control_code = 1
              AND msi.lot_control_code = 1                                              --> No Lot and Serial Control --
              AND msi.inventory_item_id = gtmp.inventory_item_id
              AND moqd.cost_group_id = gtmp.cost_group_id
         GROUP BY moqd.organization_id,
                  moqd.subinventory_code,
                  msi.inventory_item_id,
                  msi.segment1,
                  msi.primary_uom_code,
                  moqd.lot_number,
                  moqd.locator_id,
                  moqd.lpn_id
         UNION
--------------------------------------------------------
-- UNION 2  : Lot Controlled Only --
--------------------------------------------------------
         SELECT   p_organization_code organization_code,                                                           --  1
                  moqd.organization_id org_id,                                                                         --
                  msi.segment1 item,                                                                                   --
                  msi.inventory_item_id,                                                                               --
                  msi.primary_uom_code,
                  moqd.subinventory_code,                                                                            --2
                  moqd.locator_id,                                                                                     --
                  NULL locator_code,                                                                                -- 3
                  moqd.lot_number,                                                                                  -- 4
                  NULL serial,
                  SUM (moqd.primary_transaction_quantity) onhand,                                                   -- 5
                  NULL lpn,                                                                                     -- 6  --
                  moqd.lpn_id,                                                                                         --
                  lot.expiration_date lot_expiry_date,                                                           -- 7 --
                  NULL c_code,
                  NULL d_code,
                  'LOT_CONTROL'
             FROM mtl_onhand_quantities_detail moqd,
                  mtl_system_items_b msi,
                  mtl_lot_numbers lot,
                  xx_mtl_mwb_sum_gtmp gtmp
            WHERE 1 = 1
              AND moqd.organization_id = l_organization_id                                        --:onh_organization_id
              AND moqd.inventory_item_id = msi.inventory_item_id
              AND moqd.organization_id = msi.organization_id
              AND msi.organization_id = lot.organization_id
              AND msi.inventory_item_id = lot.inventory_item_id
              AND moqd.lot_number = lot.lot_number
               --and msi.segment1 = '90250'--'121145'
              -- and msi.inventory_item_id = 141375
              AND NVL (msi.serial_number_control_code, 1) = 1
              AND msi.lot_control_code <> 1
              AND msi.inventory_item_id = gtmp.inventory_item_id
              AND moqd.cost_group_id = gtmp.cost_group_id
         GROUP BY moqd.organization_id,
                  moqd.subinventory_code,
                  msi.inventory_item_id,
                  msi.segment1,
                  msi.primary_uom_code,
                  moqd.lot_number,
                  moqd.locator_id,
                  moqd.lpn_id,
                  lot.expiration_date
         UNION
--------------------------------------------------------
-- UNION 3.1  : Serial Controlled Only -- LPN_ID NOT NULL --
--------------------------------------------------------
         SELECT   p_organization_code organization_code,                                                           --  1
                  moqd.organization_id org_id,                                                                         --
                  msi.segment1 item,                                                                                   --
                  msi.inventory_item_id,                                                                               --
                  msi.primary_uom_code,
                  moqd.subinventory_code,                                                                            --2
                  moqd.locator_id,                                                                                     --
                  NULL locator_code,                                                                                -- 3
                  moqd.lot_number,                                                                                  -- 4
                  ser.serial_number serial,
                  1,
                  --SUM (moqd.primary_transaction_quantity) onhand,                                                            -- 5
                  NULL lpn,                                                                                     -- 6  --
                  moqd.lpn_id,                                                                                         --
                  NULL lot_expiry_date,                                                                          -- 7 --
                  NULL c_code,
                  NULL d_code,
                  'SERIAL_CONTROL'
             FROM mtl_onhand_quantities_detail moqd,
                  mtl_system_items_b msi,
                  mtl_serial_numbers ser,
                  xx_mtl_mwb_sum_gtmp gtmp
            WHERE 1 = 1
              AND moqd.organization_id = l_organization_id                                        --:onh_organization_id
              AND moqd.inventory_item_id = msi.inventory_item_id
              AND moqd.organization_id = msi.organization_id
              AND msi.organization_id = ser.current_organization_id
              AND msi.inventory_item_id = ser.inventory_item_id
              AND ser.current_status = 3
              AND msi.serial_number_control_code <> 1
              AND msi.lot_control_code = 1
              AND moqd.lpn_id = ser.lpn_id
              AND moqd.locator_id = ser.current_locator_id
              AND moqd.subinventory_code = ser.current_subinventory_code
              AND msi.inventory_item_id = gtmp.inventory_item_id
              AND moqd.cost_group_id = gtmp.cost_group_id
         --     AND msi.segment1 = 'PSPINSTP'
         GROUP BY moqd.organization_id,
                  moqd.subinventory_code,
                  msi.inventory_item_id,
                  msi.segment1,
                  msi.primary_uom_code,
                  moqd.lot_number,
                  ser.serial_number,
                  moqd.locator_id,
                  moqd.lpn_id
--------------------------------------------------------
-- UNION 3.2  : Serial Controlled Only -- LPN_ID NULL --
--------------------------------------------------------
         UNION
         SELECT   /*+ index (moqd XX_MTL_ONHAND_QUANTITIES_N1)*/
                  p_organization_code organization_code,                                                           --  1
                  moqd.organization_id org_id,                                                                         --
                  msi.segment1 item,                                                                                   --
                  msi.inventory_item_id,                                                                               --
                  msi.primary_uom_code,
                  moqd.subinventory_code,                                                                            --2
                  moqd.locator_id,                                                                                     --
                  NULL locator_code,                                                                                -- 3
                  moqd.lot_number,                                                                                  -- 4
                  ser.serial_number serial,
                  1,
                  --SUM (moqd.primary_transaction_quantity) onhand,                                                            -- 5
                  NULL lpn,                                                                                     -- 6  --
                  moqd.lpn_id,                                                                                         --
                  NULL lot_expiry_date,                                                                          -- 7 --
                  NULL c_code,
                  NULL d_code,
                  'SERIAL_CONTROL'
             FROM mtl_onhand_quantities_detail moqd,
                  mtl_system_items_b msi,
                  mtl_serial_numbers ser,
                  xx_mtl_mwb_sum_gtmp gtmp
            WHERE 1 = 1
              AND moqd.organization_id = l_organization_id                                        --:onh_organization_id
              AND moqd.inventory_item_id = msi.inventory_item_id
              AND moqd.organization_id = msi.organization_id
              AND msi.organization_id = ser.current_organization_id
              AND msi.inventory_item_id = ser.inventory_item_id
              AND ser.current_status = 3
              AND msi.serial_number_control_code <> 1
              AND msi.lot_control_code = 1
              AND NVL (moqd.lpn_id, -99) = -99
              AND NVL (ser.lpn_id, -99) = -99
              AND moqd.locator_id = ser.current_locator_id
              AND moqd.subinventory_code = ser.current_subinventory_code
              AND msi.inventory_item_id = gtmp.inventory_item_id
              AND moqd.cost_group_id = gtmp.cost_group_id
         --     AND msi.segment1 = 'PSPINSTP'
         GROUP BY moqd.organization_id,
                  moqd.subinventory_code,
                  msi.inventory_item_id,
                  msi.segment1,
                  msi.primary_uom_code,
                  moqd.lot_number,
                  ser.serial_number,
                  moqd.locator_id,
                  moqd.lpn_id
         UNION
--------------------------------------------------------
-- UNION 4 : Lot and Serial Controlled Both --
--------------------------------------------------------
         SELECT   p_organization_code organization_code,                                                           --  1
                  moqd.organization_id org_id,                                                                         --
                  msi.segment1 item,                                                                                   --
                  msi.inventory_item_id,                                                                               --
                  msi.primary_uom_code,
                  moqd.subinventory_code,                                                                            --2
                  moqd.locator_id,                                                                                     --
                  NULL locator_code,                                                                                -- 3
                  moqd.lot_number,                                                                                  -- 4
                  ser.serial_number serial,
                  1,
                  --SUM (moqd.primary_transaction_quantity) onhand,                                                   -- 5
                  NULL lpn,                                                                                     -- 6  --
                  moqd.lpn_id,                                                                                         --
                  NULL lot_expiry_date,                                                                          -- 7 --
                  NULL c_code,
                  NULL d_code,
                  'LOT_AND_SERIAL_CONTROL'
             FROM mtl_onhand_quantities_detail moqd,
                  mtl_system_items_b msi,
                  mtl_serial_numbers ser,
                  xx_mtl_mwb_sum_gtmp gtmp
            WHERE 1 = 1
              AND moqd.organization_id = l_organization_id                                        --:onh_organization_id
              AND moqd.inventory_item_id = msi.inventory_item_id
              AND moqd.organization_id = msi.organization_id
              AND msi.organization_id = ser.current_organization_id
              AND msi.inventory_item_id = ser.inventory_item_id
              AND ser.current_status = 3
              AND moqd.lot_number = ser.lot_number
              AND NVL (moqd.lpn_id, -99) = NVL (ser.lpn_id, -99)
              AND moqd.locator_id = ser.current_locator_id
              AND moqd.subinventory_code = ser.current_subinventory_code
              AND msi.serial_number_control_code <> 1
              AND msi.lot_control_code <> 1
              AND msi.inventory_item_id = gtmp.inventory_item_id
              AND moqd.cost_group_id = gtmp.cost_group_id
         --AND msi.segment1 = 'CRWPBSP'
         GROUP BY moqd.organization_id,
                  moqd.subinventory_code,
                  msi.inventory_item_id,
                  msi.segment1,
                  msi.primary_uom_code,
                  ser.serial_number,
                  moqd.lot_number,
                  moqd.locator_id,
                  moqd.lpn_id;

      log_message ('Building Onhand Quantity - COMPLETE');

------------------------------------------------------
-- Update C Code, D Code and LPN for transactions --
------------------------------------------------------
      UPDATE xx_mtl_mwb_gtmp x
         SET x.c_code = (SELECT product_class
                           FROM xxom_sales_marketing_set_v
                          WHERE organization_id = l_organization_id AND inventory_item_id = x.item_id),
             x.d_code = (SELECT product_type
                           FROM xxom_sales_marketing_set_v
                          WHERE organization_id = l_organization_id AND inventory_item_id = x.item_id),
             lpn = (SELECT license_plate_number
                      FROM wms_license_plate_numbers
                     WHERE organization_id = l_organization_id AND lpn_id = x.lpn_id),
             snm_division = (SELECT snm_division
                               FROM xxom_sales_marketing_set_v
                              WHERE organization_id = l_organization_id AND inventory_item_id = x.item_id),
             item_cost =
                     (SELECT item_cost
                        FROM cst_item_costs
                       WHERE organization_id = l_organization_id AND inventory_item_id = x.item_id AND cost_type_id = 1),
             LOCATOR = (SELECT description
                          FROM mtl_item_locations
                         WHERE inventory_location_id = x.locator_id AND subinventory_code = x.subinventory_code),
             party_type =
                         (SELECT DISTINCT attribute1
                                     FROM mtl_secondary_inventories
                                    WHERE secondary_inventory_name = x.subinventory_code
                                      AND organization_id = l_organization_id),
             sales_person_number =
                         (SELECT DISTINCT attribute2
                                     FROM mtl_secondary_inventories
                                    WHERE secondary_inventory_name = x.subinventory_code
                                      AND organization_id = l_organization_id),
             organization_code = '150';

      COMMIT;
      -- select * from mtl_secondary_inventories
      log_message ('Enhance Onhand Table with Code (C and D), LPN, Division and Item Cost - COMPLETE');
      log_message ('Enhance Onhand Table with Locator, Party Type and Sales Rep Number');

      UPDATE xx_mtl_mwb_gtmp x
         SET c_code_desc =
                (SELECT c.description
                   FROM fnd_id_flex_structures_vl a,
                        fnd_id_flex_segments_vl b,
                        fnd_flex_values_vl c
                  WHERE a.id_flex_code = 'MCAT'
                    AND a.id_flex_num = b.id_flex_num
                    AND a.id_flex_code = b.id_flex_code
                    AND a.id_flex_structure_code = 'SALES_CATEGORIES'
                    AND b.application_column_name = 'SEGMENT8'
                    AND b.flex_value_set_id = c.flex_value_set_id
                    AND NVL (c.enabled_flag, 'N') = 'Y'
                    AND NVL (c.end_date_active, SYSDATE + 1) >= SYSDATE
                    AND c.flex_value = x.c_code),
             d_code_desc =
                (SELECT c.description
                   FROM fnd_id_flex_structures_vl a,
                        fnd_id_flex_segments_vl b,
                        fnd_flex_values_vl c
                  WHERE a.id_flex_code = 'MCAT'
                    AND a.id_flex_num = b.id_flex_num
                    AND a.id_flex_code = b.id_flex_code
                    AND a.id_flex_structure_code = 'SALES_CATEGORIES'
                    AND b.application_column_name = 'SEGMENT9'
                    AND b.flex_value_set_id = c.flex_value_set_id
                    AND NVL (c.enabled_flag, 'N') = 'Y'
                    AND NVL (c.end_date_active, SYSDATE + 1) >= SYSDATE
                    AND c.parent_flex_value_low = x.snm_division
                    AND c.flex_value = x.d_code);

------------------------------------------------------------------------
-- Remove Unwanted Neuro Items based on Jasons email --
-- Find better way to remove may be a lookup --
-- Another WAY
-- Keep C_CODE = C2525 which has corresponding D1851, D1852, D1853 )--
-- Mike's Comment : Do not filter by Items --
------------------------------------------------------------------------
      /*
      DELETE FROM xx_mtl_mwb_gtmp
            WHERE snm_division = 'NEURO'
              AND item NOT IN
                     ('CLS164',
                      'CLS165',
                      'CLS194',
                      'CLP410',
                      'CLP411',
                      'CLP412',
                      'CLP420',
                      'CLP430',
                      'CLP440',
                      'CLP441',
                      'CLP442',
                      'CLP450',
                      'CLP451',
                      'CLP452',
                      'CLP453',
                      'CLM510',
                      'CLM511',
                      'CLT304',
                      '- CRANCLOSINSP',
                      'CLT303',
                      'CLX201',
                      'CLX202',
                      'CLX203',
                      'CLX204',
                      'CLX205'
                     );

---------------------------------------------------------------
-- Per Mike's Feedback 04/07/2014, Do not delete INSTR
-- They need to have ability to filter and Cognos level
      DELETE FROM xx_mtl_mwb_gtmp
            WHERE snm_division = 'INSTR';
---------------------------------------------------------------
      COMMIT;

      log_message('Remove Records for INSTR Division');

*/

      -------------------------------------------------
-- Call SSDY Load Programs --
-------------------------------------------------
      log_message ('Calling SSDY Loader Program');
      load_ssdy_files (l_organization_id,l_ret_code, l_errbuf);  --Uncommented as per case#009343
      COMMIT;
      log_message ('Calling SSDY Loader Program - COMPLETE');
   EXCEPTION
      WHEN OTHERS
      THEN
         log_message ('Error: Unknown error ' || SQLERRM);
   END;

   PROCEDURE load_ssdy_files (p_organization_id NUMBER,p_retcode NUMBER, p_errbuf CHAR)
   IS
      l_organization_id     NUMBER;
      l_request_id          NUMBER;
      l_control_file_path   VARCHAR2 (300);
      l_data_file_path      VARCHAR2 (300);
      l_data_file_name      VARCHAR2 (200);
      l_request_complete    BOOLEAN;
      l_dev_status          VARCHAR2 (100);
      l_dev_phase           VARCHAR2 (100);
      l_phase               VARCHAR2 (100);
      l_status              VARCHAR2 (30);
      l_message             VARCHAR2 (4000);

      CURSOR get_ssdly_load_stat
      IS
         SELECT   division,
                  COUNT (*) COUNT
             FROM xx_consgmt_ssdy_xns
         GROUP BY division;

      CURSOR get_onhand_load_stat
      IS
         SELECT   snm_division,
                  COUNT (*)
             FROM xx_mtl_mwb_gtmp
         GROUP BY snm_division;
   BEGIN

      l_organization_id := p_organization_id;
      DELETE FROM xx_consgmt_ssdy_xns;

      --NULL;

      ---------------------------------------------------
-- Derive Directory Paths --
---------------------------------------------------
      SELECT directory_path
        INTO l_control_file_path
        FROM all_directories
       WHERE directory_name = 'XXSSDYCNTRL';

      SELECT directory_path
        INTO l_data_file_name
        FROM all_directories
       WHERE directory_name = 'XXSSDYDATA';

--------------------------------------------------------
-- Submit Common Loader Program for 3 division files --
--------------------------------------------------------
      l_dev_status               := NULL;
      l_dev_phase                := NULL;
      l_phase                    := NULL;
      l_status                   := NULL;
      l_message                  := NULL;

      BEGIN
         log_message ('Calling SSDY Loader Program for RECON ');
         l_request_id               :=
            fnd_request.submit_request (application      => 'XXINTG',
                                        program          => 'XXINTGCOMMCNVLDR',
                                        description      => NULL,
                                        start_time       => SYSDATE,
                                        sub_request      => FALSE,
                                        argument1        => 'XX_CONSGMT_SSDY_RECON',
                                        -- Name of the conversion program - Control File --
                                        argument2        => l_control_file_path,                     --Control File Path
                                        argument3        => 'ssdy_recon.txt',                          -- Data FIle Name
                                        argument4        => l_data_file_name
                                       );
         COMMIT;                                                                                       -- Data File Path

         IF l_request_id IS NOT NULL
         THEN
            LOOP
               l_request_complete         :=
                  apps.fnd_concurrent.wait_for_request (l_request_id,
                                                        1,
                                                        0,
                                                        l_phase,
                                                        l_status,
                                                        l_dev_phase,
                                                        l_dev_status,
                                                        l_message
                                                       );

               IF UPPER (l_phase) = 'COMPLETED'
               THEN
                  EXIT;
               END IF;
            END LOOP;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            log_message ('Error in SSDY Loader Program for RECON ');
            NULL;
      END;

      BEGIN
         l_dev_status               := NULL;
         l_dev_phase                := NULL;
         l_phase                    := NULL;
         l_status                   := NULL;
         l_message                  := NULL;
         log_message ('Calling SSDY Loader Program for NEURO ');
         l_request_id               :=
            fnd_request.submit_request (application      => 'XXINTG',
                                        program          => 'XXINTGCOMMCNVLDR',
                                        description      => NULL,
                                        start_time       => SYSDATE,
                                        sub_request      => FALSE,
                                        argument1        => 'XX_CONSGMT_SSDY_NEURO',
                                        -- Name of the conversion program - Control File --
                                        argument2        => l_control_file_path,                     --Control File Path
                                        argument3        => 'ssdy_neuro.txt',                          -- Data FIle Name
                                        argument4        => l_data_file_name
                                       );
         COMMIT;                                                                                       -- Data File Path

         IF l_request_id IS NOT NULL
         THEN
            LOOP
               l_request_complete         :=
                  apps.fnd_concurrent.wait_for_request (l_request_id,
                                                        1,
                                                        0,
                                                        l_phase,
                                                        l_status,
                                                        l_dev_phase,
                                                        l_dev_status,
                                                        l_message
                                                       );

               IF UPPER (l_phase) = 'COMPLETED'
               THEN
                  EXIT;
               END IF;
            END LOOP;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            log_message ('Error in SSDY Loader Program for NEURO ');
            NULL;
      END;

      BEGIN
         l_dev_status               := NULL;
         l_dev_phase                := NULL;
         l_phase                    := NULL;
         l_status                   := NULL;
         l_message                  := NULL;
         log_message ('Calling SSDY Loader Program for SPINE ');
         l_request_id               :=
            fnd_request.submit_request (application      => 'XXINTG',
                                        program          => 'XXINTGCOMMCNVLDR',
                                        description      => NULL,
                                        start_time       => SYSDATE,
                                        sub_request      => FALSE,
                                        argument1        => 'XX_CONSGMT_SSDY_SPINE',
                                        -- Name of the conversion program - Control File --
                                        argument2        => l_control_file_path,                     --Control File Path
                                        argument3        => 'ssdy_spine.txt',                          -- Data FIle Name
                                        argument4        => l_data_file_name
                                       );
         COMMIT;                                                                                       -- Data File Path

         IF l_request_id IS NOT NULL
         THEN
            LOOP
               l_request_complete         :=
                  apps.fnd_concurrent.wait_for_request (l_request_id,
                                                        1,
                                                        0,
                                                        l_phase,
                                                        l_status,
                                                        l_dev_phase,
                                                        l_dev_status,
                                                        l_message
                                                       );

               IF UPPER (l_phase) = 'COMPLETED'
               THEN
                  EXIT;
               END IF;
            END LOOP;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            log_message ('Error in SSDY Loader Program for SPINE ');
            NULL;
      END;

---------------------------------------------
-- Enhance SSDY Table --
---------------------------------------------
      log_message ('Enhance SSDLY Table - Populate LPN ');

      UPDATE xx_consgmt_ssdy_xns
         SET inventory_item_id = (SELECT inventory_item_id
                                    FROM mtl_system_items_b
                                   WHERE organization_id = l_organization_id AND segment1 = product_number),
             lpn = DECODE (iskit, '1', lot_serial, NULL);

      COMMIT;
      log_message ('Enhance SSDLY - Populate C_CODE, D_CODE and Item_Cost ');

      UPDATE xx_consgmt_ssdy_xns x
         SET x.c_code = (SELECT product_class
                           FROM xxom_sales_marketing_set_v
                          WHERE organization_id = l_organization_id AND inventory_item_id = x.inventory_item_id),
             x.d_code = (SELECT product_type
                           FROM xxom_sales_marketing_set_v
                          WHERE organization_id = l_organization_id AND inventory_item_id = x.inventory_item_id),
             item_cost =
                        (SELECT item_cost
                           FROM cst_item_costs
                          WHERE organization_id = l_organization_id AND inventory_item_id = x.inventory_item_id AND cost_type_id = 1),
             date_received = NULL;

      log_message ('Enhance SSDLY - Populate Lot Number');

      UPDATE xx_consgmt_ssdy_xns x
         SET lot_number = UPPER (lot_serial)
       WHERE EXISTS (
                  SELECT 1
                    FROM mtl_lot_numbers
                   WHERE lot_number = x.lot_serial AND inventory_item_id = x.inventory_item_id
                         AND organization_id = l_organization_id);

      UPDATE xx_consgmt_ssdy_xns x
         SET x.lot_expiry_date =
                (SELECT expiration_date
                   FROM mtl_lot_numbers
                  WHERE lot_number = x.lot_number AND inventory_item_id = x.inventory_item_id AND organization_id = l_organization_id)
       WHERE lot_number IS NOT NULL;

      log_message ('Enhance SSDLY - Populate Serial Number');

      UPDATE xx_consgmt_ssdy_xns x
         SET serial_number = UPPER (lot_serial)
       WHERE EXISTS (
                SELECT 1
                  FROM mtl_serial_numbers
                 WHERE serial_number = x.lot_serial
                   AND inventory_item_id = x.inventory_item_id
                   AND current_organization_id = l_organization_id);

      UPDATE xx_consgmt_ssdy_xns x
         SET c_code_desc =
                (SELECT c.description
                   FROM fnd_id_flex_structures_vl a,
                        fnd_id_flex_segments_vl b,
                        fnd_flex_values_vl c
                  WHERE a.id_flex_code = 'MCAT'
                    AND a.id_flex_num = b.id_flex_num
                    AND a.id_flex_code = b.id_flex_code
                    AND a.id_flex_structure_code = 'SALES_CATEGORIES'
                    AND b.application_column_name = 'SEGMENT8'
                    AND b.flex_value_set_id = c.flex_value_set_id
                    AND NVL (c.enabled_flag, 'N') = 'Y'
                    AND NVL (c.end_date_active, SYSDATE + 1) >= SYSDATE
                    AND c.flex_value = x.c_code),
             d_code_desc =
                (SELECT c.description
                   FROM fnd_id_flex_structures_vl a,
                        fnd_id_flex_segments_vl b,
                        fnd_flex_values_vl c
                  WHERE a.id_flex_code = 'MCAT'
                    AND a.id_flex_num = b.id_flex_num
                    AND a.id_flex_code = b.id_flex_code
                    AND a.id_flex_structure_code = 'SALES_CATEGORIES'
                    AND b.application_column_name = 'SEGMENT9'
                    AND b.flex_value_set_id = c.flex_value_set_id
                    AND NVL (c.enabled_flag, 'N') = 'Y'
                    AND NVL (c.end_date_active, SYSDATE + 1) >= SYSDATE
                    AND c.parent_flex_value_low = x.division
                    AND c.flex_value = x.d_code);

      --Added as per case#009343
      log_message ('Replace Special symbols in fields: keeperpool,issue_error,receipt_error');

      UPDATE xx_consgmt_ssdy_xns
         SET keeperpool = REPLACE(REGEXP_REPLACE(keeperpool, '\s'), CHR(0))
            ,issue_error = REPLACE(REGEXP_REPLACE(issue_error, '\s'), CHR(0))
            ,receipt_error = REPLACE(REGEXP_REPLACE(receipt_error, '\s'), CHR(0));

----------------------------------------------------
-- Summarize SSDLY Table --
----------------------------------------------------
      DELETE FROM xx_consgmt_ssdy_sum_xns;

      COMMIT;

      INSERT INTO xx_consgmt_ssdy_sum_xns
         SELECT   division,
                  -- TRANSACTION_ID   ,
                  -- TRANSACTION_DATE ,
                  product_number,
                  inventory_id,
                  lot_serial,
                  -- STOCK_ID                ,
                  SUM (qty) quantity_sum,
                  party_responsible,
                  LOCATION,
                  keeperpool,
                  pending_receipt,
                  indispute,
                  iskit,
                  inkit,
                  parent_product,
                  parent_lotserial,
                  pending_reconciliation,
                  in_inventory,
                  date_received,
                  receipt_error,
                  issue_error,
                  lot_expiry_date,
                  c_code,
                  d_code,
                  item_cost,
                  lot_number,
                  serial_number,
                  attribute1,
                  attribute2,
                  attribute3,
                  attribute4,
                  attribute5,
                  attribute6,
                  lpn,
                  c_code_desc,
                  d_code_desc,
                  inventory_item_id
             FROM xx_consgmt_ssdy_xns
         --   WHERE product_number = '06350106'
         GROUP BY division,
                  --TRANSACTION_ID   ,
                  --TRANSACTION_DATE ,
                  product_number,
                  inventory_id,
                  lot_serial,
                  --STOCK_ID                ,
                  --QTY                     ,
                  party_responsible,
                  LOCATION,
                  keeperpool,
                  pending_receipt,
                  indispute,
                  iskit,
                  inkit,
                  parent_product,
                  parent_lotserial,
                  pending_reconciliation,
                  in_inventory,
                  date_received,
                  receipt_error,
                  issue_error,
                  lot_expiry_date,
                  c_code,
                  d_code,
                  item_cost,
                  lot_number,
                  serial_number,
                  attribute1,
                  attribute2,
                  attribute3,
                  attribute4,
                  attribute5,
                  attribute6,
                  lpn,
                  c_code_desc,
                  d_code_desc,
                  inventory_item_id;

      COMMIT;
---------------------------------------------------------------
-- Print Status Report of the load.
---------------------------------------------------------------
      fnd_file.put_line (fnd_file.output, '----------------------------------------------------------------------');
      fnd_file.put_line (fnd_file.output, '                     SSDLY and Onhand Load Status                     ');
      fnd_file.put_line (fnd_file.output, '----------------------------------------------------------------------');
      fnd_file.put_line (fnd_file.output, 'DIVISION                         NUMBER OF RECORDS                    ');
      fnd_file.put_line (fnd_file.output, '----------------------------------------------------------------------');

      FOR i IN get_ssdly_load_stat
      LOOP
         fnd_file.put_line (fnd_file.output,
                            i.division || '                    ' || i.COUNT || '                       '
                           );
      END LOOP;

      fnd_file.put_line (fnd_file.output, '');
      fnd_file.put_line (fnd_file.output, '----------------------- END OF REPORT ---------------------------------');
   END;
END xx_cnsgn_ssdy_recon_pkg;
/
