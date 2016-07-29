DROP PACKAGE BODY APPS.XX_INV_ORG_TRANSFER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ORG_TRANSFER_PKG" AS
/******************************************************************************
-- Filename:  XXOINVORGTRANSFERPKG.pkb
-- RICEW Object id : O2C_INT_070
-- Purpose :  Package Body for Automated Direct Org Transfer 
--
-- Usage: Concurrent Program ( Type PL/SQL Procedure)
-- Caution:
-- Copyright (c) IBM
-- All rights reserved.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  18-Jul-2012  SDatta             Created
-- 1.1  03-Apr-2013  ABhargava          Bug #002354 to avaiod items from Locators that are disbaled.
-- 1.2  11-Feb-2014  Vishal             added to_char to query
--
--
******************************************************************************/


-- Procedure to create conc output
PROCEDURE output (p_msg IN VARCHAR2)
IS
BEGIN
   fnd_file.put_line( fnd_file.output,p_msg);
END output;

-- Procedure to log the debug/ error message
PROCEDURE log ( p_context IN VARCHAR2
               ,p_msg     IN VARCHAR2
              )
IS
   x_msg VARCHAR2(4000);
   
BEGIN
   IF p_context IS NULL THEN
      x_msg := SUBSTR(p_msg,1,4000);
   
   ELSE
      x_msg := SUBSTR( TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS ') ||
                       RPAD(p_context,30,' ')||' : '||
                       REPLACE(p_msg,chr(10),' ')
                      ,1,4000
                     );
   END IF;
   
   fnd_file.put_line( fnd_file.log,x_msg);
-- Exception not required since called from exception handler only   
END log;   

-- Function to return org name (to be used for o/p report)
FUNCTION get_org_name (p_organization_id IN NUMBER)
RETURN VARCHAR2 IS
BEGIN
   FOR rec IN ( SELECT *
                  FROM hr_all_organization_units
                 WHERE organization_id = p_organization_id
              )
   LOOP
      RETURN rec.name;
   END LOOP;
   
   RETURN p_organization_id;
   
EXCEPTION
   WHEN OTHERS THEN
      RETURN p_organization_id;
END get_org_name; 

-- Function to check if direct transfer is allowed
FUNCTION allow_direct_transfer ( p_from_inv_org_id IN NUMBER
                                ,p_to_inv_org_id   IN NUMBER
                               )
RETURN BOOLEAN IS
BEGIN
   -- Verify the transit type in shipping network
   FOR rec IN ( SELECT *
                  FROM mtl_shipping_network_view
                 WHERE from_organization_id = p_from_inv_org_id
                   AND to_organization_id = p_to_inv_org_id
                   AND intransit_type = 1 -- Direct transfer
              )
   LOOP
      RETURN TRUE;
   END LOOP;
   
   -- Return false if above loop does not return any row
   RETURN FALSE;

EXCEPTION
   WHEN OTHERS THEN
      log('allow_direct_transfer.OTHERS',dbms_utility.format_error_backtrace);
      RETURN FALSE;
END allow_direct_transfer;        

-- Following function returns TRUE if the subinv exists in the organization
FUNCTION check_subinventory ( p_organization_id IN NUMBER
                             ,p_subinventory    IN VARCHAR2
                            )
RETURN BOOLEAN IS
BEGIN
   FOR rec IN ( SELECT '1'
                  FROM mtl_secondary_inventories
                 WHERE organization_id = p_organization_id
                   AND secondary_inventory_name = p_subinventory
              )
   LOOP
      RETURN TRUE;
   END LOOP;

   -- When no data found then return null
   RETURN FALSE;

EXCEPTION
   WHEN OTHERS THEN
      log('check_subinventory.OTHERS',dbms_utility.format_error_backtrace);
      RETURN FALSE;
END check_subinventory;                            

-- Following procedure will purge the interface table for the input parameter
PROCEDURE purge_record (p_transaction_interface_id IN NUMBER)
IS
BEGIN
   -- Purge from transaction interface table   
   DELETE FROM mtl_transactions_interface
    WHERE transaction_interface_id = p_transaction_interface_id;
    
   DELETE FROM mtl_transaction_lots_interface
    WHERE transaction_interface_id = p_transaction_interface_id;
    
   DELETE FROM mtl_serial_numbers_interface
    WHERE transaction_interface_id = p_transaction_interface_id;

-- Exception not required since called from exception handler only
END purge_record;

PROCEDURE main ( o_errbuf            OUT VARCHAR2
                ,o_retcode           OUT VARCHAR2
                ,p_from_inv_org_id   IN NUMBER
                ,p_from_subinventory IN VARCHAR2
                ,p_to_inv_org_id     IN NUMBER
                ,p_to_subinventory   IN VARCHAR2
               )
IS     
   -- Cursor to fetch the onhand records
   CURSOR c_onhand_details
   IS
   SELECT moqd.inventory_item_id
         ,moqd.revision
         ,moqd.organization_id
         ,moqd.transaction_quantity
         ,moqd.transaction_uom_code
         ,moqd.lot_number
         ,moqd.create_transaction_id
         ,moqd.lpn_id
         ,moqd.containerized_flag
         ,moqd.locator_id
         ,moqd.onhand_quantities_id
         ,milk.concatenated_segments locator_code
         ,milk_dest.inventory_location_id transfer_locator         
         ,msib.serial_number_control_code
         ,mln.expiration_date
         ,mln.origination_date
         ,DECODE( msib_dest.inventory_item_id
                 ,msib.inventory_item_id
                 ,'Y'
                 ,'N'
                ) item_exists_in_dest_org
         ,DECODE( moqd.revision
                 ,NULL,msib.segment1
                 ,msib.segment1||','||moqd.revision
                ) item -- This column will be used for report only
         ,( SELECT DECODE( COUNT(1)
                          ,0,NULL
                          ,1,MIN(serial_number)
                          ,MIN(serial_number)||'-'||MAX(serial_number)
                         )
              FROM mtl_serial_numbers
             WHERE last_transaction_id = moqd.create_transaction_id
          ) serial_number -- This column will be used for report only
         ,NULL status
         ,NULL message
     FROM mtl_onhand_quantities_detail moqd
         ,mtl_item_locations_kfv milk
         ,mtl_lot_numbers mln
         ,mtl_system_items_b msib
         ,( SELECT *  -- to verify if item exists in dest org
              FROM mtl_system_items_b msib2
             WHERE msib2.organization_id = p_to_inv_org_id
          ) msib_dest
         ,( SELECT *  -- to verify if locator exists in dest org and subinv
              FROM mtl_item_locations_kfv milk2
             WHERE milk2.organization_id = p_to_inv_org_id
               -- Added on 03 Apr 2013 for BUG # 002354 to avoid picking items from Locators which are disabled
               AND nvl(milk2.disable_date,trunc(sysdate+1)) > trunc(sysdate)
               AND milk2.subinventory_code = NVL(p_to_subinventory,p_from_subinventory)
               AND milk2.enabled_flag = 'Y'
               -- Added on 06 June 2013 
               AND milk2.status_id = 1
               AND SYSDATE BETWEEN NVL(milk2.start_date_active,SYSDATE-1)
                                   AND NVL(milk2.end_date_active,SYSDATE+1)
          ) milk_dest 
    WHERE moqd.organization_id = p_from_inv_org_id
      AND moqd.subinventory_code = p_from_subinventory
      -- Added on 03 Apr 2013 for BUG # 002354 to avoid picking items from Locators which are disabled
      AND nvl(milk.disable_date,trunc(sysdate+1)) > trunc(sysdate)
      -- Added on 06 June 2013 
      AND milk.status_id = 1
      AND moqd.locator_id = milk.inventory_location_id (+)
      AND moqd.inventory_item_id = mln.inventory_item_id (+)
      AND moqd.organization_id = mln.organization_id (+)
      AND moqd.lot_number = mln.lot_number (+)
      AND msib.organization_id = moqd.organization_id
      AND msib.inventory_item_id = moqd.inventory_item_id
      AND msib.inventory_item_id = msib_dest.inventory_item_id (+)
      AND milk.concatenated_segments = milk_dest.concatenated_segments (+)      
      -- Exclude if records exists in interface
      AND NOT EXISTS ( SELECT 1
                         FROM mtl_transactions_interface mti
                        WHERE mti.transaction_reference = to_char(moqd.create_transaction_id)
                     );

   TYPE t_onhand IS TABLE OF c_onhand_details%ROWTYPE INDEX BY BINARY_INTEGER;
   
   x_onhand_tbl     t_onhand;
   x_mtl_txn_int    mtl_transactions_interface%ROWTYPE;
   x_mtl_lot_int    mtl_transaction_lots_interface%ROWTYPE;
   x_mtl_ser_int    mtl_serial_numbers_interface%ROWTYPE;
   
   x_total_count    INTEGER := 0;
   x_skipped_count  INTEGER := 0;
   x_error_count    INTEGER := 0;
   x_iface_count    INTEGER := 0;
   
   e_skip_record    EXCEPTION;
   e_others         EXCEPTION;
   
BEGIN
   -- Initialize the out variables
   o_errbuf  := '0';
   o_retcode := '0';
   
   -- Display the paramters
   log(NULL,'p_from_inv_org_id   => '|| p_from_inv_org_id);
   log(NULL,'p_from_subinventory => '|| p_from_subinventory);
   log(NULL,'p_to_inv_org_id     => '|| p_to_inv_org_id);
   log(NULL,'p_to_subinventory   => '|| p_to_subinventory);                  
   
   -- Check the mandatory parameters
   IF (p_from_inv_org_id IS NULL OR p_from_subinventory IS NULL OR
      p_to_inv_org_id IS NULL) THEN
      o_errbuf  := 'Source Orgnization, Source Subinventory and Destination Organization are mandatory.'; 
      o_retcode := '1';
      RETURN;
   END IF;
   
   -- Check if destination subinv is valid
   IF p_to_subinventory IS NULL THEN
      IF NOT check_subinventory(p_to_inv_org_id,p_from_subinventory) THEN
         o_errbuf  := p_from_subinventory ||' does not exists in the destination organization'; 
         o_retcode := '1';
         RETURN;
      END IF;
   END IF;
   
   -- Check if the source and dest orgs are same
   IF p_from_inv_org_id = p_to_inv_org_id THEN
      o_errbuf  := 'Source and destination organizations can not be same';
      o_retcode := '1';
      RETURN;
   END IF;
   
   -- Program will exit if Direct Transfer is not allowed between orgs
   IF NOT allow_direct_transfer(p_from_inv_org_id,p_to_inv_org_id) THEN
      o_errbuf  := 'Direct Transfer is not allowed between the organizations';
      o_retcode := '1';
      RETURN;
   END IF;
   
   -- Fetch the On Hand data for the org and subinventory
    OPEN c_onhand_details;
   FETCH c_onhand_details
    BULK COLLECT INTO x_onhand_tbl;
   CLOSE c_onhand_details;
   
   x_total_count := x_onhand_tbl.COUNT;
   
   -- Load transaction interface table
   IF x_onhand_tbl.COUNT > 0 THEN
      FOR i IN x_onhand_tbl.FIRST .. x_onhand_tbl.LAST
      LOOP
         BEGIN
            -- Initialize the variables
            x_mtl_txn_int := NULL;
            x_mtl_lot_int := NULL;
            x_mtl_ser_int := NULL;
            
            -- =================================================================
            -- Define the exclusion logic
            -- =================================================================
            -- Exclude the items do not exist in dest org
            IF x_onhand_tbl(i).item_exists_in_dest_org = 'N' THEN
               x_onhand_tbl(i).status  := 'W';
               x_onhand_tbl(i).message := 'Item does not exist in dest org';
               RAISE e_skip_record;
            END IF;
            
            -- Exclude the txn when same locator is not defined in dest org
            IF (x_onhand_tbl(i).locator_code IS NOT NULL
               AND x_onhand_tbl(i).transfer_locator IS NULL) THEN
               
               x_onhand_tbl(i).status  := 'W';
               x_onhand_tbl(i).message := 'Locator does not exist in dest org';               
               RAISE e_skip_record;            
            ELSE
               x_mtl_txn_int.transfer_locator := x_onhand_tbl(i).transfer_locator;
            END IF;
            
            -- =================================================================
            -- End of the exclusion logic
            -- =================================================================
            
            -- Assign the record to the interface table
            BEGIN              
               SELECT mtl_material_transactions_s.NEXTVAL
                 INTO x_mtl_txn_int.transaction_interface_id
                 FROM dual;
                 
               -- Interface Columns
               x_mtl_txn_int.source_code           := 'Inter Org';
               x_mtl_txn_int.source_header_id      := fnd_global.conc_request_id;
               x_mtl_txn_int.source_line_id        := x_onhand_tbl(i).onhand_quantities_id;
               x_mtl_txn_int.process_flag          := 1; -- Pending
               x_mtl_txn_int.transaction_mode      := 3; -- Batch
               x_mtl_txn_int.transaction_type_id   := 3; -- Direct Org Transfer
               x_mtl_txn_int.transaction_reference := x_onhand_tbl(i).create_transaction_id;
               
               -- WHO Columns
               x_mtl_txn_int.creation_date         := SYSDATE;
               x_mtl_txn_int.created_by            := fnd_global.user_id;
               x_mtl_txn_int.last_update_date      := SYSDATE;
               x_mtl_txn_int.last_updated_by       := fnd_global.user_id;
               x_mtl_txn_int.request_id            := fnd_global.conc_request_id;
               
               -- Source data
               x_mtl_txn_int.inventory_item_id     := x_onhand_tbl(i).inventory_item_id;
               x_mtl_txn_int.revision              := x_onhand_tbl(i).revision;
               x_mtl_txn_int.organization_id       := x_onhand_tbl(i).organization_id;
               x_mtl_txn_int.subinventory_code     := p_from_subinventory;
               x_mtl_txn_int.locator_id            := x_onhand_tbl(i).locator_id;
               x_mtl_txn_int.transaction_quantity  := x_onhand_tbl(i).transaction_quantity;
               x_mtl_txn_int.transaction_uom       := x_onhand_tbl(i).transaction_uom_code;
               x_mtl_txn_int.transaction_date      := SYSDATE;
               
               -- Destination data
               x_mtl_txn_int.transfer_organization  := p_to_inv_org_id;
               x_mtl_txn_int.transfer_subinventory  := NVL(p_to_subinventory,p_from_subinventory);
               x_mtl_txn_int.transfer_locator       := x_mtl_txn_int.transfer_locator;
               x_mtl_txn_int.content_lpn_id         := x_onhand_tbl(i).lpn_id;
            
               INSERT INTO mtl_transactions_interface VALUES x_mtl_txn_int;
               
            EXCEPTION
               WHEN OTHERS THEN
                  x_onhand_tbl(i).status  := 'E';
                  x_onhand_tbl(i).message := 'main.insert.mti '||
                                             dbms_utility.format_error_backtrace;
                  
                  RAISE e_others;
            END;
            
            -- Assign record for LOT Controlled items
            IF x_onhand_tbl(i).lot_number IS NOT NULL THEN
               BEGIN
                  x_mtl_lot_int.transaction_interface_id := x_mtl_txn_int.transaction_interface_id;
                  x_mtl_lot_int.process_flag             := x_mtl_txn_int.process_flag;  
                  x_mtl_lot_int.creation_date            := x_mtl_txn_int.creation_date;
                  x_mtl_lot_int.created_by               := x_mtl_txn_int.created_by;
                  x_mtl_lot_int.last_update_date         := x_mtl_txn_int.last_update_date;
                  x_mtl_lot_int.last_updated_by          := x_mtl_txn_int.last_updated_by;
                  x_mtl_lot_int.request_id               := x_mtl_txn_int.request_id;
                  
                  x_mtl_lot_int.transaction_quantity     := x_onhand_tbl(i).transaction_quantity;
                  x_mtl_lot_int.lot_number               := x_onhand_tbl(i).lot_number;
                  x_mtl_lot_int.lot_expiration_date      := x_onhand_tbl(i).expiration_date;
                  x_mtl_lot_int.origination_date         := x_onhand_tbl(i).origination_date;
                  
                  INSERT INTO mtl_transaction_lots_interface VALUES x_mtl_lot_int;
                  
               EXCEPTION
                  WHEN OTHERS THEN
                     x_onhand_tbl(i).status  := 'E';
                     x_onhand_tbl(i).message := 'main.insert.mtli '||
                                                dbms_utility.format_error_backtrace;
                     RAISE e_others;
               END;
            END IF;

            -- Assign records for SERIAL Controlled items
            IF x_onhand_tbl(i).serial_number_control_code <> 1 THEN
               -- Get all serial numbers
               FOR rec IN ( SELECT serial_number
                              FROM mtl_serial_numbers
                             WHERE last_transaction_id = x_onhand_tbl(i).create_transaction_id
                          )
               LOOP
                  BEGIN
                     x_mtl_ser_int.transaction_interface_id := x_mtl_txn_int.transaction_interface_id;
                     x_mtl_ser_int.process_flag             := x_mtl_txn_int.process_flag;  
                     x_mtl_ser_int.creation_date            := x_mtl_txn_int.creation_date;
                     x_mtl_ser_int.created_by               := x_mtl_txn_int.created_by;
                     x_mtl_ser_int.last_update_date         := x_mtl_txn_int.last_update_date;
                     x_mtl_ser_int.last_updated_by          := x_mtl_txn_int.last_updated_by;
                     x_mtl_ser_int.request_id               := x_mtl_txn_int.request_id;
                     x_mtl_ser_int.fm_serial_number         := rec.serial_number;
                     
                     INSERT INTO mtl_serial_numbers_interface VALUES x_mtl_ser_int;
                     
                  EXCEPTION
                     WHEN OTHERS THEN
                        x_onhand_tbl(i).status  := 'E';
                        x_onhand_tbl(i).message := 'main.insert.msni '||
                                                   dbms_utility.format_error_backtrace;
                        RAISE e_others;
                  END;
               END LOOP;
            END IF;
            
            x_iface_count := x_iface_count + 1;
            x_onhand_tbl(i).status  := 'S';             
         EXCEPTION
            WHEN e_skip_record THEN  -- Do nothing exception
               x_skipped_count := x_skipped_count + 1;
            
            WHEN e_others THEN
               -- Purge if any record inserted into the interface table
               purge_record(x_mtl_txn_int.transaction_interface_id);
               x_error_count := x_error_count + 1;
               
            WHEN OTHERS THEN
               x_onhand_tbl(i).status  := 'E';
               x_onhand_tbl(i).message := 'main.loop.OTHERS '||
                                          dbms_utility.format_error_backtrace;
               
               -- Purge if any record inserted into the interface table
               purge_record(x_mtl_txn_int.transaction_interface_id);
               x_error_count := x_error_count + 1;
         END;
      END LOOP;
   ELSE
      o_errbuf  := 'The source organization/subinventory does not have any ONHAND to transfer';
      o_retcode := '1';
      RETURN;
   END IF;

   -- Set the warning status
   IF x_skipped_count > 0 OR x_error_count > 0 THEN
      o_errbuf  := 'Please review output for error/ warning messages';
      o_retcode := '1';
   END IF;
   
   -- ==========================================================================
   -- Create a summary report in concurrent output
   -- ==========================================================================
   -- Header section
   output('INTG Direct Org Transfer Processing Report');
   output(RPAD('-',120,'-'));
   output('');
   output('  Request ID : '|| fnd_global.conc_request_id);
   output('Request Date : '|| TO_CHAR(SYSDATE,'DD-Mon-YYYY HH:MI:SS AM'));
   output('Requested By : '|| fnd_global.user_name);
   output('');
   output('      Source : '|| get_org_name(p_from_inv_org_id)||' - '||p_from_subinventory);
   output(' Destination : '|| get_org_name(p_to_inv_org_id)||' - '||NVL(p_to_subinventory,p_from_subinventory));
   output('');
   output('Summary');
   output(RPAD('-',30,'-'));
   output('  Total Record Count : '|| x_total_count);
   output('Warning Record Count : '|| x_skipped_count);
   output('  Error Record Count : '|| x_error_count);
   output('    Interfaced Count : '|| x_iface_count);
   output(RPAD('-',30,'-'));
   output('');
   output( RPAD('ITEM, REV',20,' ') ||' '||
           RPAD(  'LOCATOR',20,' ') ||' '||
           LPAD( 'QUANTITY',15,' ') ||' '||
           RPAD(      'LOT',20,' ') ||' '||
           RPAD(   'SERIAL',40,' ') ||' '||
           'MESSAGE'
         );         
   output( RPAD('-',20,'-') ||' '||
           RPAD('-',20,'-') ||' '||
           LPAD('-',15,'-') ||' '||
           RPAD('-',20,'-') ||' '||
           RPAD('-',40,'-') ||' '||
           RPAD('-',40,'-')
         );         
   
   -- Reopen the onhand loop to display the processing details
   FOR i IN x_onhand_tbl.FIRST .. x_onhand_tbl.LAST
   LOOP
      output( RPAD(x_onhand_tbl(i).item                  ,20,' ') ||' '||
              RPAD(NVL(x_onhand_tbl(i).locator_code,' ') ,20,' ') ||' '||
              LPAD(x_onhand_tbl(i).transaction_quantity||' '||
                   x_onhand_tbl(i).transaction_uom_code  ,15,' ') ||' '||
              RPAD(NVL(x_onhand_tbl(i).lot_number,' ')   ,20,' ') ||' '||
              RPAD(NVL(x_onhand_tbl(i).serial_number,' '),40,' ') ||' '||
              REPLACE(x_onhand_tbl(i).status||' '||
                      x_onhand_tbl(i).message
                     ,chr(10),' '
                     )
            );      
   END LOOP;   
   -- ==========================================================================
   -- End of report
   -- ==========================================================================
   
EXCEPTION
   -- Exception in the main block
   WHEN OTHERS THEN
      o_errbuf := SQLERRM ||chr(10)||dbms_utility.format_error_backtrace;
      o_retcode := '2';
END main;    
END xx_inv_org_transfer_pkg;
/
