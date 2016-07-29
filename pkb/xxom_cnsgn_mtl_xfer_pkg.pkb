DROP PACKAGE BODY APPS.XXOM_CNSGN_MTL_XFER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CNSGN_MTL_XFER_PKG" 
/*************************************************************************************
*
*   HEADER
*      Source control header
*
*   PROGRAM NAME
*     XXOM_CNSGN_MTL_XFER_PKG.pkb
*
*   DESCRIPTION - This will perform various inventory transactions based on the
*   transaction_type_id that is passed in. Primarily, it is used for subinventory
*   transfers, but also will support miscellaneous gains and issues.
*
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
*
  1.1      05/05/2014                    PL/SQL Numbric error: User_name was getting passed instead of userid
                                         Changed parameter passed toconsignment_transfer procedure.
                                         Ticket 005897
******************************************************************************************/
IS

l_external_transaction_id mtl_transactions_interface.transaction_reference%TYPE;
   l_user_id NUMBER;
   l_user_name VARCHAR2(100); -- the web service is passing the user_name

PROCEDURE log_message(p_log_message  IN  VARCHAR2)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO xxintg_cnsgn_cmn_log_tbl
      VALUES (xxintg_cnsgn_cmn_log_seq.nextval, 'XXOM_CNSGN_MTL_XFER_PKG',
           l_external_transaction_id || ': '|| p_log_message, SYSDATE);
  COMMIT;
  dbms_output.put_line(p_log_message);
END LOG_MESSAGE;



PROCEDURE initialize_values
            (

                   --p_locator_id OUT NUMBER, -- kitting org
                   -- p_locator_id OUT NUMBER,
                   p_odc_organization_id  OUT NUMBER,
                   -- p_vdc_organization_id  OUT NUMBER,
                   p_consignment_org_id OUT NUMBER,
                   p_transaction_source_name IN varchar2,
                   p_transaction_source_id out NUMBER,
                   p_return_status    IN OUT  VARCHAR2,
                                     p_return_code            IN OUT    VARCHAR2,
                   p_return_message   IN OUT  VARCHAR2
            )
IS

BEGIN

      -- BXS
      BEGIN
      BEGIN
      SELECT user_id
      INTO   l_user_id
      FROM   fnd_user
      WHERE upper(user_name) =  l_user_name;

      EXCEPTION
      WHEN OTHERS THEN
        BEGIN
        SELECT user_id
        INTO   l_user_id
        FROM   fnd_user
        WHERE  upper(user_name) = 'MARY.SCOZ';
        END;
      END;

      fnd_global.apps_initialize (user_id => l_user_id, -- 1136, -- VISHY1634
                                  resp_id => 21676, -- INVENTORY
                                  resp_appl_id => 385);
      EXCEPTION
      WHEN OTHERS THEN
         p_return_message := 'apps_initialize error.';
         RAISE;
      END;


BEGIN
SELECT organization_id
INTO   p_consignment_org_id
FROM   MTL_PARAMETERS
WHERE  organization_code = '150';
END;

/***
BEGIN
SELECT organization_id
INTO   p_odc_organization_id
FROM   MTL_PARAMETERS
WHERE  organization_code = '160';
END;
***/

--BEGIN
--SELECT organization_id
--INTO   p_vdc_organization_id
--FROM   MTL_PARAMETERS
--WHERE  organization_code = '180';
--END;



--BEGIN
--SELECT inventory_location_id
--INTO   p_odc_kitting_locator_id
--FROM   mtl_item_locations
--WHERE  organization_id = p_organization_id
--AND    subinventory_code = 'KITTING'
--AND    segment1 = 'KITTING'
--AND    segment2 = '001'
-- AND    segment1 = '001';
--END;


--BEGIN
--SELECT inventory_location_id
--INTO   p_vdc_kitting_locator_id
--FROM   mtl_item_locations
--WHERE  organization_id = p_organization_id
--AND    subinventory_code = 'KITTING'
--AND    segment1 = 'KITTING'
--AND    segment2 = '001'
--AND    segment1 = '001';
--END;

         -- Selecting distribution account

              BEGIN
                SELECT disposition_id -- distribution_account
                  INTO   p_transaction_source_id
                  FROM   mtl_generic_dispositions
                 WHERE   organization_id = p_consignment_org_id
                   AND   SEGMENT1 = p_transaction_source_name; -- l_rec_acc_alias_name;
              EXCEPTION
                 WHEN OTHERS THEN
                 /*
                      l_err_msg :=
                      l_err_msg || ' Unable to fetch distribution account id ';
                      DBMS_OUTPUT.PUT_LINE('unable to fetch v_disp_id:');
                      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unable to fetch  distribution account details for : ' ||l_rec_acc_alias_name);
                      */
                      log_message('Cannot find distribution account for: ' || p_transaction_source_name );
              END;

    p_return_status := 'S';
    p_return_code := '0';
    p_return_message := 'Successfully retrieved item info.';

EXCEPTION
WHEN OTHERS THEN
    p_return_status := 'E';
    p_return_code := sqlcode;
    p_return_message := sqlerrm;
END initialize_values;

/*

PROCEDURE verify_subinventory
        (
          p2_organization_id  IN NUMBER,
          p2_subinventory IN VARCHAR2,
          p2_subinventory_name  IN OUT VARCHAR2,
          p2_process_flag IN OUT VARCHAR2,
          p2_return_status  IN OUT VARCHAR2,
          p2_return_message  IN OUT VARCHAR2
        )
IS
  BEGIN
    NULL;
  END verify_subinventory;


*/

PROCEDURE get_inventory_location
        ( p_salesrep_id  IN VARCHAR2,
          p_subinventory IN OUT VARCHAR2,
          p_inventory_location_id  IN OUT NUMBER,
          p_return_status   IN OUT VARCHAR2,
          p_return_message  IN OUT VARCHAR2
        )
IS

   l_secondary_inventory_name VARCHAR2(50);
   l_segment1 VARCHAR2(30); -- Vishy: Added this 23-apr-2014
   l_segment2 VARCHAR2(30);
   l_segment3 VARCHAR2(30);
  -- l_div_code VARCHAR2(30);

BEGIN
  -- l_div_code := substr(UPPER(l_division),1,3);
   log_message('p_salesrep_id in get_inventory_location: ' || p_salesrep_id);

   -- BXS This is a kitting center transaxtion

    IF (p_salesrep_id < 0) THEN

    -- Vishy: 23-Apr-2014: Replaced hardcoding sub and locator derivation with SQL to derivie based on sales rep IDs
    /****
       IF (p_salesrep_id in (-7,-4)) THEN -- in ( -7, -14, -15) THEN
             l_secondary_inventory_name := 'RECONKIT';
             l_segment2 := 'REC';  -- substr(UPPER(l_division),1,3); -- UAT
             l_segment3 := '001';

       ELSIF (p_salesrep_id = -14) THEN --- BXS to determine ids for spine for both overages and scrap as to where to issue the material from
             l_secondary_inventory_name := 'SPINEKIT';
             l_segment2 := 'SPI'; -- substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := 'ODC';

       ELSIF (p_salesrep_id = -15) THEN
             l_secondary_inventory_name := 'SPINEKIT';
             l_segment2 := 'SPI';  -- l_segment2 := substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := 'VDC';

       ELSIF (p_salesrep_id in (-8, -17) ) THEN --BXS to figure out for multiple divisions and multiple orgs (overages)
             l_secondary_inventory_name := 'OVERAGE';
             l_segment2 := '001';  -- l_segment2 := substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := '001';

       ELSIF (p_salesrep_id = -1) THEN --BXS to figure out for multiple divisions and multiple orgs (overages)
             l_secondary_inventory_name := 'KITCLEANUP';
             l_segment2 := '001';  -- l_segment2 := substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := '001';

       -- BXS this needs to addressed
       ELSIF UPPER(l_division) = 'NEURO' THEN
             l_secondary_inventory_name := 'NEUROKIT';
             l_segment2 := 'NEU'; -- substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := '001';
       ELSIF UPPER(l_division) = 'SPINE' THEN
             l_secondary_inventory_name := 'SPINEKIT';
             l_segment2 := 'SPI'; -- substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := '001';
       ELSIF UPPER(l_division) = 'RECON' THEN
             l_secondary_inventory_name := 'RECONKIT';
             l_segment2 := 'REC'; -- substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := '001';

       END IF;
     *****/
     BEGIN
       select distinct msi.secondary_inventory_name, milk.segment1, milk.segment2, decode(p_salesrep_id, -14, 'ODC',-15,'VDC',milk.segment3),
          milk.inventory_location_id
        into p_subinventory, l_segment1, l_segment2, l_segment3, p_inventory_location_id
        from mtl_secondary_inventories msi, mtl_item_locations_kfv milk, mtl_parameters mp
        where mp.organization_code = '150' and
          mp.organization_id = msi.organization_id and
          msi.organization_id = milk.organization_id and
          msi.secondary_inventory_name = milk.subinventory_code and
          nvl(milk.attribute3,msi.attribute2) = p_salesrep_id and (milk.disable_date is null or trunc(milk.disable_date) > sysdate);

     EXCEPTION WHEN no_data_found THEN
            log_message('Cannot find sub,loc for sales rep ID : '|| p_salesrep_id);
      END;

        log_message('l_secondary_inventory_name: '|| p_subinventory);
       -- log_message('l_division: '|| substr(UPPER(l_division),1,3));
        log_message('l_segment1: '|| l_segment1);
        log_message('l_segment2: '|| l_segment2);
        log_message('l_segment3: '|| l_segment3);

     /****
      BEGIN
           SELECT ms.secondary_inventory_name, inventory_location_id
           INTO p_subinventory, p_inventory_location_id
           FROM  mtl_secondary_inventories ms,
                 mtl_item_locations mil,
                 mtl_parameters mp
           WHERE mp.organization_code = '150'
           AND mp.organization_id = ms.organization_id
           AND ms.secondary_inventory_name = l_secondary_inventory_name
           AND ms.secondary_inventory_name = mil.subinventory_code
           AND ms.organization_id = mil.organization_id
           AND mil.segment1 = l_segment1
           AND mil.segment2 = l_segment2
           AND mil.segment3 = l_segment3
           AND mil.organization_id = mp.organization_id; -- l_consignment_org_id;
      EXCEPTION WHEN no_data_found THEN
            log_message('Cannot find sub,loc for: '|| l_secondary_inventory_name);
            log_message('Cannot find sub,loc for: '|| l_segment1 || '.' || l_segment2 || '.' ||l_segment2);
      END;
     *****/

   ELSIF (p_salesrep_id is null or p_salesrep_id in (160,180)) then
        p_subinventory := null;
        p_inventory_location_id := null;

   ELSE
    /**** Vishy 06/04/2014: Changed to handle multiple locators for reps and dealers and removed the division as the reps
          are unique and no need to check the division ***/
     -- This is for a transfer involving reps
         log_message('getting sub and locator for: ' || p_salesrep_id);
        begin
         SELECT msi.secondary_inventory_name, inventory_location_id
         INTO  p_subinventory, p_inventory_location_id
         FROM  mtl_secondary_inventories msi,
               mtl_item_locations_kfv milk, mtl_parameters mp
         WHERE mp.organization_code = '150'
         AND   mp.organization_id = msi.organization_id
         AND   msi.organization_id = milk.organization_id
         AND   msi.secondary_inventory_name = milk.subinventory_code
         AND   nvl(milk.attribute3,msi.attribute2) = p_salesrep_id
       --  AND   milk.segment2 = l_div_code -- '001'   -- assumption of setup per FS  -- different IN UAT
       --  AND   milk.segment3 = '001'
         AND   (milk.disable_date is null or trunc(milk.disable_date) > sysdate);

       exception when no_data_found then
          log_message('Cannot find sub,loc for '|| p_salesrep_id);
       end;

        log_message('l_secondary_inventory_name: '|| p_subinventory);
        log_message('Location ID: ' || p_inventory_location_id);

   END IF;



   /**** Old Code --- VP Changed on 03/04/2014 to make it simpler
   IF p_salesrep_id < 0 THEN

       IF p_salesrep_id in (-7,-4) THEN -- in ( -7, -14, -15) THEN
             l_secondary_inventory_name := 'RECONKIT';
             -- l_secondary_inventory_name := 'ODCRECONKT';
             if (p_to_flag = 'Y') then
              l_to_organization_code := '150';
             else
              l_to_organization_code := '160';
             end if;
             l_segment2 := 'REC';  -- substr(UPPER(l_division),1,3); -- UAT
             l_segment3 := '001';
       ELSIF p_salesrep_id = -14 THEN --- BXS to determine ids for spine for both overages and scrap as to where to issue the material from
             l_secondary_inventory_name := 'SPINEKIT';
             -- l_secondary_inventory_name := 'ODCSPINEKT';
             if (p_to_flag = 'Y') then
              l_to_organization_code := '150';
             else
              l_to_organization_code := '160';
             end if;
             l_segment2 := 'SPI'; -- substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := 'ODC';
       ELSIF p_salesrep_id = -15 THEN
             l_secondary_inventory_name := 'SPINEKIT';
             if (p_to_flag = 'Y') then
              l_to_organization_code := '150';
             else
              l_to_organization_code := '180';
             end if;
             l_segment2 := 'SPI';  -- l_segment2 := substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := 'VDC';

       ELSIF p_salesrep_id = -8 THEN --BXS to figure out for multiple divisions and multiple orgs (overages)
             l_secondary_inventory_name := 'OVERAGE';
             l_to_organization_code := '150';
             l_segment2 := '001';  -- l_segment2 := substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := '001';
       -- BXS this needs to addressed
       ELSIF UPPER(l_division) = 'NEURO' THEN
             l_secondary_inventory_name := 'NEUROKIT';
             l_segment2 := 'NEU'; -- substr(UPPER(l_division),1,3); -- UIT
             l_segment3 := '001';
       END IF;

      log_message('l_secondary_inventory_name: '|| l_secondary_inventory_name);
      log_message('l_division: '|| substr(UPPER(l_division),1,3));

         Begin
           SELECT ms.secondary_inventory_name, inventory_location_id
           INTO p_subinventory, p_inventory_location_id
           FROM  mtl_secondary_inventories ms,
                 mtl_item_locations mil,
                 mtl_parameters mp
           WHERE ms.secondary_inventory_name = l_secondary_inventory_name
           AND ms.secondary_inventory_name = mil.subinventory_code
           AND   mil.segment2 = l_segment2
           AND   mil.segment3 = l_segment3
           AND   mil.organization_id = mp.organization_id -- l_consignment_org_id;
           AND   mp.organization_code = '150';
         exception when no_data_found then
            log_message('Cannot find sub,loc for '|| l_secondary_inventory_name);
         end;

         begin
           SELECT mp.organization_id
           INTO  p_organization_id
           FROM  mtl_parameters mp
           where mp.organization_code = l_to_organization_code;

         exception when no_data_found then
            log_message('Cannot find org for '|| l_to_organization_code);
         end;

          log_message('p_organization_id: '|| p_organization_id);

  elsif p_salesrep_id is null then
        p_organization_id := null;
        p_subinventory := null;
        p_inventory_location_id := null;

   ELSE

     -- This is for a transfer involving reps
         log_message('getting sub and locator for: ' || p_salesrep_id);
        begin
         SELECT msi.secondary_inventory_name, inventory_location_id
         INTO  p_subinventory, p_inventory_location_id
         FROM  mtl_secondary_inventories msi,
               mtl_item_locations mil
         WHERE msi.attribute2 = p_salesrep_id
         AND   msi.secondary_inventory_name = mil.subinventory_code
         AND   mil.segment2 = l_div_code -- '001'   -- assumption of setup per FS  -- different IN UAT
         AND   mil.segment3 = '001';

       exception when no_data_found then
          log_message('Cannot find sub,loc for '|| p_salesrep_id);
       end;

        begin
         SELECT mp.organization_id
         INTO  p_organization_id
         FROM  mtl_parameters mp
         where mp.organization_code = '150';

        exception when no_data_found then
          log_message('Cannot find org for '|| p_organization_id);
       end;
        log_message('p_organization_id: '|| p_organization_id);

   END IF;
  *****/
   p_return_status := 'S';
   -- p_return_code := '0';
   p_return_message := 'Successfully found subinventory: ';
   log_message(p_return_message ||': ' || p_subinventory || ': ' || p_inventory_location_id);

EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_return_message := 'Unable to find inventory location id for: ' || p_salesrep_id;
   p_return_status := 'E';
WHEN OTHERS THEN
   p_return_message := 'Unexpected Error 1: ' || sqlcode || ': ' || sqlerrm;
   p_return_status := 'E';
END get_inventory_location;


PROCEDURE get_organization_id
        ( p_salesrep_id  IN VARCHAR2,
          p_to_salesrep_id IN VARCHAR2,
          p_organization_id IN OUT NUMBER,
          p_return_status   IN OUT VARCHAR2,
          p_return_message  IN OUT VARCHAR2
        )
IS
   l_organization_id NUMBER := 0;
   l_div_code VARCHAR2(30);
   l_organization_code VARCHAR2(3);

BEGIN
   l_div_code := substr(UPPER(l_division),1,3);
   log_message('p_salesrep_id in get_organization_id: ' || p_salesrep_id);
   log_message('p_tosalesrep_id in get_organization_id: ' || p_to_salesrep_id);

   -- BXS This is a kitting center transaxtion

   /**** Old Code --- VP Changed on 03/04/2014 to make it simpler ***/
       IF ((p_salesrep_id in (-7)) and (p_to_salesrep_id is null or p_to_salesrep_id in (160))) THEN -- in ( -7, -14, -15) THEN
              l_organization_code := '160';

       ELSIF ((p_salesrep_id = -14) and (p_to_salesrep_id is null or p_to_salesrep_id in (160))) THEN --- BXS to determine ids for spine for both overages and scrap as to where to issue the material from
              l_organization_code := '160';

       ELSIF ((p_salesrep_id = -31) and (p_to_salesrep_id is null or p_to_salesrep_id in (160))) THEN --- BXS to determine ids for spine for both overages and scrap as to where to issue the material from
              l_organization_code := '160';

       ELSIF ((p_salesrep_id = -15) and (p_to_salesrep_id is null or p_to_salesrep_id in (180))) THEN
              l_organization_code := '180';

       ELSIF ( (p_salesrep_id in (-1,-8)) or (p_to_salesrep_id in (-1,-8)) ) THEN --BXS to figure out for multiple divisions and multiple orgs (overages)
             l_organization_code := '150';

       ELSIF (p_salesrep_id in (-4,-16,-36)) THEN -- Scrap transaction. we still want to keep it as 150 - set it to null before calling scrap
            l_organization_code := '150';

       ELSE
            l_organization_code := '150';

       END IF;

      log_message('l_organization_code: '|| l_organization_code);
      log_message('l_division: '|| substr(UPPER(l_division),1,3));

      begin
        SELECT mp.organization_id
          INTO  l_organization_id
          FROM  mtl_parameters mp
        where mp.organization_code = l_organization_code;

      exception when no_data_found then
          log_message('Cannot find org for '|| l_organization_code);
      end;

      log_message(' organization_id: '|| l_organization_id);

      p_organization_id := l_organization_id;
      p_return_status := 'S';
     -- p_return_code := '0';
      p_return_message := 'Successfully found Org ID: ' || p_organization_id;

EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_return_message := 'Unable to find org id for: ' || p_salesrep_id;
   p_return_status := 'E';
WHEN OTHERS THEN
   p_return_message := 'Unexpected Error 1: ' || sqlcode || ': ' || sqlerrm;
   p_return_status := 'E';
END get_organization_id;



PROCEDURE consignment_transaction
            (
                   p_source_code      IN  VARCHAR2,
                   p_transaction_source_id IN NUMBER,
                   p_header_id        IN NUMBER,
                   p_line_id          IN NUMBER,
                   p_organization_id  IN  NUMBER,
                   p_transaction_type_id IN NUMBER,
                   p_subinventory     IN  VARCHAR2,
                   p_inventory_location_id          IN  VARCHAR2,
                   p_lpn              IN VARCHAR2,
                   p_xfer_item        IN  VARCHAR2,
                   p_xfer_quantity    IN  NUMBER,
                   p_xfer_uom         IN  VARCHAR2,
                   p_lot_number       IN VARCHAR2,
                   p_serial_number    IN VARCHAR2,
                   p_to_organization_id  IN  NUMBER,
                   p_to_subinventory  IN  VARCHAR2,
                   p_to_inventory_location_id       IN  VARCHAR2,
                   p_to_lpn           IN VARCHAR,
                   p_reason_id        IN  NUMBER,
                   p_user_id          IN  NUMBER,
                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
            )
IS

   x_mtl_txn_int    mtl_transactions_interface%ROWTYPE;
   x_mtl_lot_int    mtl_transaction_lots_interface%ROWTYPE;
   x_mtl_ser_int    mtl_serial_numbers_interface%ROWTYPE;

   l_inventory_item_id NUMBER;
   l_primary_uom VARCHAR2(10);
   l_expiration_date DATE;
   l_origination_date DATE;
   l_txn_int_id NUMBER;
   l_serial_number varchar2(30);
   l_source_serial_control_code number;
   l_source_lot_control_code number;
   l_dest_serial_control_code number;
   l_dest_lot_control_code number;
   l_source_shelf_life_code number; -- Vishy 04/25/2014 Added to check exp date for lot controlled/exp controlled items

BEGIN

   x_mtl_txn_int := NULL;
   x_mtl_lot_int := NULL;
   x_mtl_ser_int := NULL;
   l_txn_int_id := NULL;



   BEGIN

      log_message ('p_xfer_item: ' || p_xfer_item);
      log_message ('p_organization_id: ' || p_organization_id);
      log_message ('p_to_organization_id: ' || p_to_organization_id);
                            log_message(p_source_code);
                      log_message(p_transaction_source_id);
                      log_message(p_header_id);
                      log_message(p_line_id);
                      log_message(p_organization_id);
                      log_message(p_transaction_type_id);
                      log_message(p_subinventory);
                      log_message(p_inventory_location_id);
                      log_message(p_lpn);
                      log_message(p_xfer_item);
                      log_message(p_xfer_quantity);
                      log_message(p_xfer_uom);
                      log_message(p_lot_number);
                      log_message(p_serial_number);
                      log_message(p_to_organization_id);
                      log_message(p_to_subinventory);
                      log_message(p_to_inventory_location_id);
                      log_message(p_to_lpn);
                      log_message(p_reason_id);
                      log_message(p_user_id);
                      log_message(p_return_status);
                      log_message(p_return_message);
                      log_message ('done: ' || p_to_organization_id);

   IF p_xfer_item IS NOT NULL THEN
      dbms_output.put_line ('getting item info...');
      log_message ('getting item info...');

    -- Vishy 04/25/2014 Added to check exp date for lot controlled/exp controlled items
      BEGIN
        SELECT msib.inventory_item_id, msib.primary_uom_code,
               mln.expiration_date, mln.origination_date, msib.lot_control_code, msib.serial_number_control_code,msib.shelf_life_code
        INTO     l_inventory_item_id, l_primary_uom,
               l_expiration_date, l_origination_date, l_source_lot_control_code, l_source_serial_control_code, l_source_shelf_life_code
        FROM     mtl_system_items_b msib, mtl_lot_numbers mln
        WHERE msib.organization_id = p_organization_id
        AND   msib.segment1 = p_xfer_item
        AND   mln.inventory_item_id (+) = msib.inventory_item_id
        AND   mln.organization_id (+) = msib.organization_id
        AND   mln.lot_number (+) = p_lot_number;
      EXCEPTION
      WHEN no_data_found THEN
         log_message('Cannot get item info 1');
      END;

   END IF;

    IF p_to_organization_id IS NOT NULL THEN
      dbms_output.put_line ('getting item info for destination org...');

      BEGIN
        SELECT msib.inventory_item_id, msib.primary_uom_code,
               mln.expiration_date, mln.origination_date, msib.lot_control_code, msib.serial_number_control_code
        INTO     l_inventory_item_id, l_primary_uom,
               l_expiration_date, l_origination_date, l_dest_lot_control_code, l_dest_serial_control_code
        FROM     mtl_system_items_b msib, mtl_lot_numbers mln
        WHERE msib.organization_id = p_to_organization_id
        AND   msib.segment1 = p_xfer_item
        AND   mln.inventory_item_id (+) = msib.inventory_item_id
        AND   mln.organization_id (+) = msib.organization_id
        AND   mln.lot_number (+) = p_lot_number;
      EXCEPTION
      WHEN no_data_found THEN
         log_message('Cannot get item info 2');
      END;
   END IF;

  begin
   SELECT mtl_material_transactions_s.NEXTVAL
   INTO l_txn_int_id
   FROM dual;
 EXCEPTION
      WHEN no_data_found THEN
         log_message('Cannot get transaction interface id');
  END;

   log_message(' mln.expiration_date: ' ||  l_expiration_date);
   log_message('p_header_id: ' || p_header_id );
   log_message('p_transaction_type_id: ' || p_transaction_type_id );
   log_message('x_mtl_txn_int.transaction_interface_id: ' || l_txn_int_id);

   -- Interface Columns
   x_mtl_txn_int.source_code           := p_source_code;
   x_mtl_txn_int.transaction_source_id := p_transaction_source_id;
   x_mtl_txn_int.source_header_id      := p_header_id;
   x_mtl_txn_int.source_line_id        := p_line_id; -- do I need to loop through an add a 1 each time
   x_mtl_txn_int.transaction_header_id := p_header_id;
   x_mtl_txn_int.transaction_interface_id := l_txn_int_id;
   x_mtl_txn_int.process_flag          := 1; -- Pending
   x_mtl_txn_int.transaction_mode      := 1; -- Batch = 3 1 = online
   x_mtl_txn_int.transaction_type_id   := p_transaction_type_id; -- 2 Sub xfer; -- 3 Direct Org Transfer -- 21 Intransit
   x_mtl_txn_int.transaction_reference := l_external_transaction_id;
   /*** Vishy 03/12/2014 ***/
   If (p_reason_id is not null and p_reason_id <> 0) Then
      x_mtl_txn_int.reason_id :=  p_reason_id;
   End If;

   IF p_transaction_type_id = 21 THEN
     begin
      select p_serial_number || '_' || wsh_deliveries_s.nextval
      into x_mtl_txn_int.shipment_number
      from dual;
    EXCEPTION
      WHEN no_data_found THEN
         log_message('Cannot get deliveries shipment number');
    END;
   END IF;

    log_message ('p_transaction_type_id: ' || p_transaction_type_id);
    log_message ('p_source_code: ' || p_source_code);
    log_message ('Sub insert into MTI: ' || p_subinventory);
    log_message ('Loc insert into MTI: ' || p_inventory_location_id);
    log_message ('TO Sub insert into MTI: ' || p_to_subinventory);
    log_message ('TO Loc insert into MTI: ' || p_to_inventory_location_id);

   -- Source data
   x_mtl_txn_int.inventory_item_id     := l_inventory_item_id;
   -- x_mtl_txn_int.revision              := l_revision;  no revision control in inventory after receiving
   x_mtl_txn_int.organization_id       := p_organization_id;
   x_mtl_txn_int.subinventory_code     := p_subinventory;
   x_mtl_txn_int.locator_id            := p_inventory_location_id;
   x_mtl_txn_int.transaction_quantity  := p_xfer_quantity;
   x_mtl_txn_int.transaction_uom       := NVL(p_xfer_uom, l_primary_uom);
   x_mtl_txn_int.transaction_date      := SYSDATE;

   IF 1=0 THEN -- TBD
   x_mtl_txn_int.content_lpn_id         := to_number(p_lpn);
   END IF;

   x_mtl_txn_int.lpn_id         := to_number(p_lpn);

   IF ((p_transaction_type_id = 200) and (p_to_lpn is not null) and (p_lpn is not null)
        and to_number(p_lpn) = to_number(p_to_lpn)) THEN
      x_mtl_txn_int.content_lpn_id := to_number(p_lpn);
      x_mtl_txn_int.lpn_id := null;
      x_mtl_txn_int.transfer_lpn_id := null;
      x_mtl_txn_int.transaction_source_name := 'Txn from SS';
      log_message('x_mtl_txn_int.transaction_source_name 1: ' || x_mtl_txn_int.transaction_source_name);
   elsif (p_transaction_type_id in (200,999)) and (p_to_lpn is not null) then -- vishy 03/12/2014
       x_mtl_txn_int.transfer_lpn_id := to_number(p_to_lpn);
       x_mtl_txn_int.transaction_source_name := 'Txn from SS';
       log_message('x_mtl_txn_int.transaction_source_name 2: ' || x_mtl_txn_int.transaction_source_name);
   END IF;

   /*** Vishy: 03/20/2014: Setting transfer lpn for pack and container split transactions ***/
   -- BXS: Set transfer lpn for alias receipt also
   IF ((p_transaction_type_id in (87,89,41)) and (p_to_lpn is not null)) Then
      x_mtl_txn_int.transfer_lpn_id := to_number(p_to_lpn);
   End If;

   log_message ('lpn id : ' ||  x_mtl_txn_int.lpn_id );
   log_message (' transfer lpn id : ' ||  x_mtl_txn_int.transfer_lpn_id );
   log_message (' content lpn id : ' ||  x_mtl_txn_int.content_lpn_id );

   -- Destination data
   x_mtl_txn_int.transfer_organization  := p_to_organization_id;
   x_mtl_txn_int.transfer_subinventory  := p_to_subinventory;  --NVL(p_to_subinventory,p_subinventory);
   x_mtl_txn_int.transfer_locator       := p_to_inventory_location_id;

   -- WHO Columns
   x_mtl_txn_int.creation_date         := SYSDATE;
   x_mtl_txn_int.created_by            := p_user_id;
   x_mtl_txn_int.last_update_date      := SYSDATE;
   x_mtl_txn_int.last_updated_by       := p_user_id;
   -- x_mtl_txn_int.request_id            := l_request_id;

   log_message (' insterting int MTI: ' );
   INSERT INTO mtl_transactions_interface VALUES x_mtl_txn_int;
   log_message (' successfully inserted into MTI' );

   EXCEPTION
   WHEN OTHERS THEN
      p_return_status := 'E';
   -- p_return_code := '0';
      p_return_message := 'Error inserting into mtl_transactions_interface table: ' ||SQLERRM;
      RAISE;
   END;

   log_message(' p_lot_number: ' || p_lot_number );
   log_message(' p_transaction_type_id: ' || p_transaction_type_id );

   -- Assign record for LOT Controlled items
   -- BXS - check if it is lot controlled and null, as that is a different exception
   -- this will give a better message
   IF (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 31) OR
        (p_lot_number IS NOT NULL AND l_dest_lot_control_code = 2 and p_transaction_type_id = 21) OR
        --         (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 2) OR
        (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 200) OR -- BXS 06/23/2014
        (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 88) OR -- Vishy 03/11/2014
        (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 999) OR -- Vishy 03/12/2014
        (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 41)  OR -- BXS 03/26/2014
        (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 87) OR -- Vishy added for pack and split
        (p_lot_number IS NOT NULL AND l_source_lot_control_code = 2 and p_transaction_type_id = 89)  ---- Vishy added for pack and split

      THEN

      BEGIN
        log_message ('processing lot...for interface id: '||l_txn_int_id);
        log_message ('processing lot...for lot number: '||p_lot_number);

        -- Vishy 04/25/2014 Added to check exp date for lot controlled/exp controlled items

        IF (p_transaction_type_id = 41 and l_source_shelf_life_code <> 1 and l_expiration_date is null) THEN
            l_expiration_date := sysdate + 183;
        END IF;

        x_mtl_lot_int.transaction_interface_id := l_txn_int_id;
        x_mtl_lot_int.process_flag             := 1; -- Pending
        --  x_mtl_lot_int.request_id               := l_request_id;

        x_mtl_lot_int.transaction_quantity     := abs(p_xfer_quantity);
        x_mtl_lot_int.lot_number               := p_lot_number;
        x_mtl_lot_int.lot_expiration_date      := l_expiration_date;
        x_mtl_lot_int.origination_date         := l_origination_date;

        -- WHO Columns
        x_mtl_lot_int.creation_date            := SYSDATE;
        x_mtl_lot_int.created_by               := p_user_id;
        x_mtl_lot_int.last_update_date         := SYSDATE;
        x_mtl_lot_int.last_updated_by          := p_user_id;

        INSERT INTO mtl_transaction_lots_interface VALUES x_mtl_lot_int;

      EXCEPTION
      WHEN OTHERS THEN
         p_return_status  := 'E';
         p_return_message := 'main.insert.mtli '|| dbms_utility.format_error_backtrace;
         RAISE;  -- BXS create pragma exception for clarity
      END;
   END IF;

   log_message ('l_source_serial_control_code:'||l_source_serial_control_code);
   log_message ('l_dest_serial_control_code:'||l_dest_serial_control_code);
   log_message ('try to process serial...for serial number: '||p_serial_number);

   -- Assign records for SERIAL Controlled items
   IF   ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 31) OR
        ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_dest_serial_control_code in (2,5) and p_transaction_type_id = 21) OR
        -- ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 2) OR
        ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 200) OR -- BXS 6/23/2014
        ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 88) OR -- Vishy 03/11/2014
        ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 999) OR -- Vishy 03/12/2014
        ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 41) OR-- BXS 03/26/2014
        ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 87) OR-- Vishy added for pack and split
        ((nvl(p_serial_number, p_lot_number)) IS NOT NULL AND l_source_serial_control_code in (2,5) and p_transaction_type_id = 89) -- Vishy added for pack and split

        THEN
                  -- AND serial_number_control_code <> 1
       log_message ('processing serial for interface id...'||l_txn_int_id);
       log_message ('processing serial...for serial number: '||p_serial_number);

       BEGIN
         x_mtl_ser_int.transaction_interface_id := l_txn_int_id;
         x_mtl_ser_int.process_flag             := 1;  -- pending
         -- x_mtl_ser_int.request_id               := x_mtl_txn_int.request_id;
         x_mtl_ser_int.fm_serial_number         := nvl(p_serial_number,p_lot_number);
         x_mtl_ser_int.to_serial_number         := nvl(p_serial_number,p_lot_number);

         -- WHO Columns
         x_mtl_ser_int.creation_date            := SYSDATE;
         x_mtl_ser_int.created_by               := p_user_id;
         x_mtl_ser_int.last_update_date         := SYSDATE;
         x_mtl_ser_int.last_updated_by          := p_user_id;

         INSERT INTO mtl_serial_numbers_interface VALUES x_mtl_ser_int;

       EXCEPTION
       WHEN OTHERS THEN
          p_return_status  := 'E';
          p_return_message := 'main.insert.msni  '|| dbms_utility.format_error_backtrace;
          RAISE;  -- BXS create pragma exception for clarity
       END;
   END IF;

   p_return_status := 'S';
   -- p_return_code := '0';
   p_return_message := 'Successfully inserted into mtl_transactions_interface table.';

EXCEPTION
WHEN OTHERS THEN
   p_return_status := 'E';
-- p_return_code := '0';
   p_return_message := 'Unknown Error in consignment_trnsaction procedure: ' ||SQLERRM  ||p_return_message;
END consignment_transaction;


PROCEDURE Create_Transfer_Request
            (      p_user_id          IN  VARCHAR2,
                   p_salesrep_id      IN VARCHAR2,

                   p_source_system IN VARCHAR2,
                   p_external_transaction_id IN VARCHAR2,

                   p_source_code      IN  VARCHAR2,
                   p_reason_id        IN  NUMBER,
                   p_division         IN  VARCHAR2,

                   p_transaction_type IN  VARCHAR2,

                   p_container        IN  VARCHAR2,

                   p_to_division      IN  VARCHAR2,
                   p_to_salesrep_id   IN  VARCHAR2,

                   p_to_serial        IN  VARCHAR2,
                   p_to_container     IN  VARCHAR2,

                   p_tranaction_items IN xxintg_t_trx_line_t,

                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_code            IN  OUT     VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
            )
IS

   l_transaction_items xxintg_t_trx_line_t;

   i NUMBER := 0;
   j NUMBER := 0;

   l_odc_organization_id NUMBER;
   l_consignment_org_id NUMBER;
   l_to_organization_id NUMBER;
   l_organization_id NUMBER;
   l_from_organization_id Number;

   l_source_code VARCHAR2(20);
   l_transaction_type_id  NUMBER;
   l_subinventory VARCHAR2(30);
   l_locator VARCHAR2(30);
   l_inventory_location_id NUMBER;

   l_transaction_id NUMBER;
   l_header_id NUMBER;

   l_to_subinventory VARCHAR2(30);
   l_to_locator VARCHAR2(30);
   l_to_inventory_location_id NUMBER;
   l_inventory_item_id NUMBER;
   l_reason_id  VARCHAR2(30);

   l_lpn_id  VARCHAR2(100);
   l_to_lpn_id VARCHAR2(100);

   l_xfer_item VARCHAR2(50);
   l_xfer_quantity NUMBER;
   l_xfer_uom VARCHAR2(20);

   l_return NUMBER;
   l_return_status VARCHAR2(20) := fnd_api.g_ret_sts_success;
   l_return_code VARCHAR2(10);
   l_return_message VARCHAR2(200);

   l_sub_xfer_source_code VARCHAR2(20) := 'Txn from SS';

     x_return_status VARCHAR2(1);
     x_return_message VARCHAR2(2000);
     x_msg_count NUMBER;
     x_trans_count NUMBER;
   l_transaction_source_name varchar2(30);
   l_transaction_source_id number;
   l_license_plate_number wms_license_plate_numbers.license_plate_number%TYPE;
   p_to_flag varchar2(1) := null;
   l_item_present BOOLEAN := false; -- Vishy 03/11/2014
   l_transaction_type_id_up NUMBER; -- Vishy 03/11/2014
   l_source_code_up VARCHAR2(20);  -- Vishy 03/11/2014
   l_header_id_up NUMBER; -- Vishy 03/11/2014
   l_transaction_quantity NUMBER := 0; -- Vishy 03/11/2014
   l_transaction_type_id_dummy NUMBER := 0; -- Vishy 03/12/2014
   l_source_code_dummy VARCHAR2(20);  -- Vishy 03/12/2014
   l_header_id_dummy NUMBER; -- Vishy 03/12/2014
   l_content_rec_inserted NUMBER := 0; -- Vishy 03/12/2014
   l_reason_id_dummy NUMBER := 0; -- Vishy 03/12/2014
   v_count NUMBER := 0; -- Vishy 03/12/2014
   /** Query Reservation Specific *** Vishy 03/21/2014 ***/
   l_count number := 0;
    l_rsv_rec inv_reservation_global.mtl_reservation_rec_type;
    l_tmp_rsv_tbl inv_reservation_global.mtl_reservation_tbl_type;
    l_tmp_rsv_tbl_count NUMBER;
    x_msg_data varchar2(1000);
    l_error_code NUMBER;
/*** Update reservation specific *** 03/21/2014 ***/
      l_rsv_old   inv_reservation_global.mtl_reservation_rec_type;
      l_rsv_new   inv_reservation_global.mtl_reservation_rec_type;
      l_msg_count NUMBER;
      l_msg_data  VARCHAR2(240);
      l_reservation_id    NUMBER;
      l_dummy_sn  inv_reservation_global.serial_number_tbl_type;
      l_status    VARCHAR2(1);
   --   l_lot_number varchar2(80);
   -- Vishy: 17-Oct-2014: Added a variable to hold item type;
   l_lpn_item_type varchar2(10);
   l_lot_control_code number;
   l_serial_number_control_code number;
   l_lot_number varchar2(80) := null;
   l_serial_number varchar2(30) := null;

   -- Main item for the serial number
   CURSOR serial_cur  IS
      SELECT wlpn.organization_id, wlpn.subinventory_code, wlpn.locator_id, wlpn.lpn_context,
             wlpn.lpn_id, wlpn.license_plate_number, wlc.inventory_item_id, wlc.lot_number,
             wlc.quantity, wlc.uom_code, msib.segment1 item
            -- decode(msn.serial_number,wlpn.license_plate_number,msn.serial_number,null) serial_number
      FROM  wms_license_plate_numbers wlpn, wms_lpn_contents wlc,
            mtl_system_items_b msib, mtl_serial_numbers msn
      WHERE msn.serial_number = P_CONTAINER
      AND   msn.lpn_id = wlpn.lpn_id
      AND   wlc.parent_lpn_id = wlpn.lpn_id
      AND   wlpn.organization_id = msn.current_organization_id
      AND   wlc.inventory_item_id = msn.inventory_item_id
      AND   wlpn.subinventory_code = msn.current_subinventory_code
      AND   wlpn.locator_id = msn.current_locator_id
      AND   wlpn.organization_id = msib.organization_id
      AND   wlc.inventory_item_id = msib.inventory_item_id
      AND   msib.item_type = 'K';

   -- All items - include the main LPN
   CURSOR lpn_contents_cur (p_lpn_id number) IS
      SELECT wlpn.organization_id, wlpn.subinventory_code, wlpn.locator_id, wlpn.lpn_context,
             wlpn.lpn_id, wlpn.license_plate_number, wlc.inventory_item_id, wlc.lot_number,
             wlc.quantity, wlc.uom_code, msib.segment1 item,
             msn.serial_number, msib.item_type
      FROM  wms_license_plate_numbers wlpn, wms_lpn_contents wlc,
            mtl_system_items_b msib, mtl_serial_numbers msn
      WHERE wlpn.lpn_id = p_lpn_id -- p_lpn_id
      AND   wlc.parent_lpn_id = wlpn.lpn_id
      AND   wlpn.organization_id = msib.organization_id
      AND   wlc.inventory_item_id = msib.inventory_item_id
      AND   msn.lpn_id (+) = wlc.parent_lpn_id -- parent_lpn_id
      AND   msn.current_organization_id (+) = wlc.organization_id
      AND   msn.inventory_item_id (+) = wlc.inventory_item_id;

      /*** Vishy 03/12/2014 : New cursor for the dummy transactions check ****/
      CURSOR lpn_items_cur (p_lpn_id number) IS
      SELECT wlpn.lpn_id, wlpn.license_plate_number, wlc.inventory_item_id, wlc.lot_number,
             wlc.quantity, wlc.uom_code, msib.segment1 item, msib.item_type
      FROM  wms_license_plate_numbers wlpn, wms_lpn_contents wlc,
            mtl_system_items_b msib
      WHERE wlpn.lpn_id = p_lpn_id -- p_lpn_id
      AND   wlc.parent_lpn_id = wlpn.lpn_id
      AND   wlpn.organization_id = msib.organization_id
      AND   wlc.inventory_item_id = msib.inventory_item_id;

BEGIN
   log_message(' In create transfer procedure');

   l_transaction_items := xxintg_t_trx_line_t();
   -- BXS - Check if this is a duplicate transaction
   -- look at mtl_material_transactions for source and transaction_id

   l_user_name := p_user_id; -- the web service is passing the user_name

   l_external_transaction_id := p_external_transaction_id;
   log_message('  l_external_transaction_id: ' ||  l_external_transaction_id);

   -- Get a new transaction ID
   SELECT mtl_material_transactions_s.NEXTVAL
   INTO l_header_id
   FROM dual;
      log_message(' Completed get transaction id');

   l_division := p_division;
   l_transaction_source_name := 'KIT_EXPLOSION_150';

   -- Initialize all the Consignment specific variables
   initialize_values
      (  --p_locator_id OUT NUMBER, -- kitting org
                   -- p_locator_id OUT NUMBER,
         p_odc_organization_id  => l_odc_organization_id,
         -- p_vdc_organization_id  OUT NUMBER,
         p_consignment_org_id => l_consignment_org_id,
         p_transaction_source_name => l_transaction_source_name,
         p_transaction_source_id => l_transaction_source_id,
         p_return_status    => l_return_status,
         p_return_code            => l_return_code,
         p_return_message   => l_return_message
       );

   IF ( l_return_status <> 'S' ) THEN
      log_message('l_return_message: ' || l_return_message);
   END IF;

   -- get the transaction specific details
   -- from location
         log_message('from location: sales Rep ID: ' || p_salesrep_id );
   get_inventory_location
        ( p_salesrep_id  => p_salesrep_id,
          p_subinventory => l_subinventory,
          p_inventory_location_id => l_inventory_location_id,
          p_return_status =>  l_return_status,
          p_return_message =>  l_return_message
        );

   IF ( l_return_status <> 'S' ) THEN
      log_message('l_return_message: ' || l_return_message);
   END IF;

      log_message('After calling from get_inventory_location. Sub:  ' || l_subinventory);
      log_message('After calling from get_inventory_location. Loc:  ' || l_inventory_location_id);

      log_message('to location: To Sales Rep ID: ' || p_to_salesrep_id);
   -- to location

   -- BXS this should be wrapped in an if statement looking at the
   -- to_sub and to_loc
   get_inventory_location
        ( p_salesrep_id  => p_to_salesrep_id,
          p_subinventory => l_to_subinventory,
          p_inventory_location_id => l_to_inventory_location_id,
          p_return_status =>  l_return_status,
          p_return_message =>  l_return_message
        );

   IF ( l_return_status <> 'S' ) THEN
      log_message('l_return_message: ' || l_return_message);
   END IF;

     log_message('After calling TO get_inventory_location. Sub:  ' || l_to_subinventory);
     log_message('After calling TO get_inventory_location. Loc:  ' || l_to_inventory_location_id);

   get_organization_id
        ( p_salesrep_id  => p_salesrep_id,
          p_to_salesrep_id  => p_to_salesrep_id,
          p_organization_id => l_to_organization_id,
          p_return_status =>  l_return_status,
          p_return_message =>  l_return_message
        );

   IF ( l_return_status <> 'S' ) THEN
      log_message('l_return_message: ' || l_return_message);
   END IF;
   -- Unpack the xxintg_t_trx_line
   -- assumption is that all lines have the same "header" information - transaction_type, from, to, etc.
   l_transaction_items := p_tranaction_items;

   -- This will depend on the transaction type -BXS

   l_organization_id := l_consignment_org_id;
   l_source_code :=  'Inventory'; -- 'Inter Org';

   log_message('After assigning Orgs: From Org ID: ' || l_organization_id);
   log_message('After assigning Orgs: TO Org ID: ' || l_to_organization_id);

   log_message('p_container: ' || p_container);
   j := 0;

   -- we are moving a whole set and a rep cannot move a set to themselves
   IF (( p_container IS NOT NULL ) AND (l_organization_id <> l_to_organization_id) AND (p_salesrep_id not in (-8,-17))) THEN
      log_message('This is a kit transfer.... ');

      FOR serial_rec IN serial_cur
      LOOP
      log_message('In serial loop: ' || serial_rec.lpn_id);
      l_license_plate_number := serial_rec.license_plate_number;

      for lpn_contents_rec in lpn_contents_cur (serial_rec.lpn_id)
      loop

      log_message('In loop lpn rec cursor: ');
      -- but we have to transact what Oracle says we have in the set
      -- and ignore what Surgisoft says we have (which is the else statement).
      -- we have to populate that into the xx_set_info table though
      j := j + 1;
      log_message('j: ' || j || ' item: ' || lpn_contents_rec.item || ' quantity: ' || lpn_contents_rec.quantity || 'lpn_contents_rec.serial_number: '||lpn_contents_rec.serial_number);

      IF  p_salesrep_id < 0  THEN
         log_message('This is a kit transfer from Kitting Room to FG.... ');
         -- We have the top level part number
         IF ( lpn_contents_rec.serial_number = p_container )
             AND ( lpn_contents_rec.item_type = 'K' )
          THEN --    or THEN
         -- l_transaction_type_id := 3; -- Direct Org Transfer
         l_transaction_type_id := 21; -- Intransit Shipment
         l_source_code :=  'Inter Org';
         -- l_to_organization_id := l-- 1661; -- lookup based on division;
         -- interorg back to the DC
          consignment_transaction
            (
                   p_source_code      => l_source_code,
                   p_transaction_source_id => l_transaction_source_id,
                   p_header_id        => l_header_id,
                   p_line_id          => j,
                   p_organization_id  => l_organization_id, -- logic to decide whith one -- l_organization_id,
                   p_transaction_type_id => l_transaction_type_id,
                   p_subinventory     => l_subinventory,
                   p_inventory_location_id  => l_inventory_location_id,
                   p_lpn              => lpn_contents_rec.lpn_id,
                   p_xfer_item        => lpn_contents_rec.item, -- l_xfer_item,
                   p_xfer_quantity    => (-1) * lpn_contents_rec.quantity, --l_xfer_quantity,
                   p_xfer_uom         => lpn_contents_rec.uom_code, -- l_xfer_uom,
                   p_lot_number       => lpn_contents_rec.lot_number,
                   p_serial_number    => lpn_contents_rec.serial_number,
                   p_to_organization_id  => l_to_organization_id,
                   p_to_subinventory  => null, -- l_to_subinventory,
                   p_to_inventory_location_id       => null,
                   p_to_lpn           => null, -- p_to_container,
                   p_reason_id        => l_reason_id,
       --            p_user_id          => p_user_id,       for Ticket 005897
                   p_user_id          => l_user_id,
                   p_return_status    => l_return_status,
                   p_return_message   => l_return_message
            );

              IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                log_message(' Main kit transferred --> ' || lpn_contents_rec.serial_number);
                log_message(' Message from transfer of the main kit --> ' || l_return_message);
                log_message(' item  --> '|| lpn_contents_rec.item);
                log_message(' serial  --> ' || lpn_contents_rec.serial_number);
                log_message(' lpn  --> ' || lpn_contents_rec.lpn_id);
                log_message(' lot  --> ' || lpn_contents_rec.lot_number);
              ELSE
                log_message(' Main kit transferred --> ' || lpn_contents_rec.serial_number);
                log_message(' Message from transfer of the main kit --> ' || l_return_message);
                log_message(' item  --> '|| lpn_contents_rec.item);
                log_message(' serial  --> ' || lpn_contents_rec.serial_number);
                log_message(' lpn  --> ' || lpn_contents_rec.lpn_id);
                log_message(' lot  --> ' || lpn_contents_rec.lot_number);
             END IF;

             /**** Insert into set table ****/

            insert into xx_set_info
            VALUES
            (
              lpn_contents_rec.license_plate_number, -- LPN NAME
              p_container, -- SET_SERIAL
              lpn_contents_rec.inventory_item_id,
              lpn_contents_rec.lot_number, -- LOT
              lpn_contents_rec.serial_number, -- SERIAL  of part
              lpn_contents_rec.quantity, -- TRANSACTION_QUANTITY
              lpn_contents_rec.uom_code, -- TRANSACTION_UNIT_OF_MEASURE VARCHAR2(10),
              l_source_code, -- SOURCE_CODE  -- (Account alias receipt  /  Account alias Issue)
              l_header_id, -- TRANSACTION_ID,
              null, -- TRANSACTION_SET_ID,
              null, -- TRANSACTION_SOURCE_ID,
              null, -- CREATED_BY,
              sysdate, -- CREATED_DATE,
              'N',  -- status,
              lpn_contents_rec.item,
              l_header_id -- batch_id
             );

         -- make sure that the components are not a Kit for whatever reason
         ELSIF lpn_contents_rec.item_type <> 'K' THEN
            l_transaction_type_id := 31;  -- account alias issue
            l_source_code :=  'Inter Org';

            -- account alias issue all the part numbers out
            consignment_transaction
            (
                   p_source_code      => l_source_code,
                   p_transaction_source_id => l_transaction_source_id,
                   p_header_id        => l_header_id,
                   p_line_id          => j,
                   p_organization_id  => l_organization_id, -- logic to decide whith one -- l_organization_id,
                   p_transaction_type_id => l_transaction_type_id,
                   p_subinventory     => l_subinventory,
                   p_inventory_location_id  => l_inventory_location_id,
                   p_lpn              => lpn_contents_rec.lpn_id,
                   p_xfer_item        => lpn_contents_rec.item, -- l_xfer_item,
                   p_xfer_quantity    => (-1) * lpn_contents_rec.quantity, --l_xfer_quantity,
                   p_xfer_uom         => lpn_contents_rec.uom_code, -- l_xfer_uom,
                   p_lot_number       => lpn_contents_rec.lot_number,
                   p_serial_number    => lpn_contents_rec.serial_number,
                   p_to_organization_id  => null,
                   p_to_subinventory  => null,
                   p_to_inventory_location_id       => null,
                   p_to_lpn           => null, -- p_to_container,
                   p_reason_id        => l_reason_id,
                   --            p_user_id          => p_user_id, -- for Ticket 005897
                   p_user_id          => l_user_id,
                   p_return_status    => l_return_status,
                   p_return_message   => l_return_message
            );

              IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                log_message(' Main kit failed to transfer --> ' || lpn_contents_rec.serial_number);
                log_message(' Message from transfer of the main kit --> ' || l_return_message);
                log_message(' item  --> '|| lpn_contents_rec.item);
                log_message(' serial  --> ' || lpn_contents_rec.serial_number);
                log_message(' lpn  --> ' || lpn_contents_rec.lpn_id);
                log_message(' lot  --> ' || lpn_contents_rec.lot_number);
              ELSE
                log_message(' Main kit transferred --> ' || lpn_contents_rec.serial_number);
                log_message(' Message from transfer of the main kit --> ' || l_return_message);
                log_message(' item  --> '|| lpn_contents_rec.item);
                log_message(' serial  --> ' || lpn_contents_rec.serial_number);
                log_message(' lpn  --> ' || lpn_contents_rec.lpn_id);
                log_message(' lot  --> ' || lpn_contents_rec.lot_number);
             END IF;

         ELSE

           log_message('There may be a kit that looks like a component: '   );
           -- so we will not do anything with it at this time
           NULL;

         END IF;
      END IF;


    end loop;

      /** Vishy: 05/27/2014: Moved the insertion of set info records from outside to inside the serial cursor so that
          we dont insert if we cannot find the LPN **/
      /** Vishy: 10/20/2014: Move the lot field to serial field if the item is serial controlled. SS passes only one value
          for lot/serial number ****/
      l_lot_number := null;
      l_serial_number := null;

      FOR h IN l_transaction_items.First..l_transaction_items.Last
         LOOP
         log_message('h: ' || h || ' item: ' || l_transaction_items(h).item || ' quantity: ' || l_transaction_items(h).quantity);
            BEGIN
              SELECT msib.inventory_item_ID, msib.lot_control_code, msib.serial_number_control_code
              INTO   l_inventory_item_id, l_lot_control_code, l_serial_number_control_code
              FROM   mtl_system_items_b msib
              WHERE  segment1 = l_transaction_items(h).item
              AND    organization_id = l_organization_id;
            EXCEPTION
            WHEN OTHERS THEN
              null; --  user experience only
              log_message('l_inventory_item_id not found for: ' || l_organization_id || ': ' ||l_transaction_items(h).item);
            END;

            log_message(l_transaction_items(h).serial_number ||': '||l_inventory_item_id||': '||
               l_transaction_items(h).serial_number ||': '|| l_transaction_items(h).quantity ||': '||
               l_transaction_items(h).uom ||': '|| l_source_code || ': '|| l_header_id);

               l_lot_number := l_transaction_items(h).lot_number;
               l_serial_number := l_transaction_items(h).serial_number;


            If (l_transaction_items(h).lot_number is not null and l_lot_control_code = 1 and
                l_serial_number_control_code in (2,5)) Then -- Item is non-lot controlled, but serial controlled
                  l_serial_number := l_transaction_items(h).lot_number;
                  l_lot_number := null;
            End if;

            log_message('l_lot_number ' || l_lot_number);
            log_message('l_serial_number ' || l_serial_number);

            /**** End Change ****/

            If  serial_rec.inventory_item_id <> l_inventory_item_id then
              -- Only if the item is not a high level item, since we are already inserting for the kit.
                -- insert into the temporary table
                insert into xx_set_info
                (
                lpn_name,
                set_serial,
                inventory_item_id,
                lot,
                serial,
                transaction_quantity,
                transaction_unit_of_measure,
                source_code,
                transaction_id,
                transaction_set_id,
                transaction_source_id,
                created_by,
                created_date,
                status_interface,
                item_number,
                batch_id
                )
                VALUES
                (
                  l_license_plate_number, -- LPN NAME
                  p_container, -- SET_SERIAL
                  l_inventory_item_id,
                  l_lot_number, -- l_transaction_items(h).lot_number, -- LOT
                  l_serial_number, -- l_transaction_items(h).serial_number, -- SERIAL  of part
                  l_transaction_items(h).quantity, -- TRANSACTION_QUANTITY
                  l_transaction_items(h).uom, -- TRANSACTION_UNIT_OF_MEASURE VARCHAR2(10),
                  l_source_code, -- SOURCE_CODE  -- (Account alias receipt  /  Account alias Issue)
                  l_header_id, -- TRANSACTION_ID,
                  null, -- TRANSACTION_SET_ID,
                  null, -- TRANSACTION_SOURCE_ID,
                  null, -- CREATED_BY,
                  sysdate, -- CREATED_DATE,
                  'N',  -- status,
                  l_transaction_items(h).item,
                  l_header_id -- batch_id
                 );
             End If;
        END LOOP;

        /**End Move - Vishy: 05/27/2014 - End Changes**/

      END LOOP;


   END IF;

   --------------------------------------------------
   -- BXS Rep to Rep Transfer
   --------------------------------------------------
   IF ( p_salesrep_id is not null ) AND ( p_to_salesrep_id is not null ) AND
      ( l_to_organization_id = l_organization_id ) THEN

       log_message('Subinventory_Transfer Starting... or Scrap Txn');

       IF ( ( p_salesrep_id in (-4,-16,-36) ) OR ( p_to_salesrep_id in (-4,-16,-36) ) )
              THEN --scrap txn BXS to figure for Neuro IDs  txnsource ids based on division
          l_transaction_type_id := 31;
          l_to_organization_id := null;
          l_to_subinventory := null;
          l_to_inventory_location_id := null;
          l_to_lpn_id := null;

              BEGIN
                SELECT disposition_id -- distribution_account
                  INTO   l_transaction_source_id
                  FROM   mtl_generic_dispositions
                 WHERE   organization_id = l_organization_id
                   AND   SEGMENT1 = 'SCRAP-' || UPPER(l_division);
              EXCEPTION
                 WHEN OTHERS THEN
                      log_message('Cannot find distribution account for: ' || l_transaction_source_id );
              END;
       ELSE
          l_transaction_type_id := 200;
          l_source_code := l_sub_xfer_source_code;
       END IF;

        log_message('p_container...' || p_container);
        log_message('p_to_container...' || p_to_container);
        log_message('p_salesrep_id...' || p_salesrep_id);
        log_message('p_to_salesrep_id...' || p_to_salesrep_id);

       IF  p_salesrep_id = -1000 THEN -- finder logic gain part through alias receipt
          l_transaction_type_id := 41; -- Account Alias Receipt


          -- switch the from to the to and null the to because SS cannot send these values
          -- in the order that we are expecting for this transaction
          l_organization_id := l_to_organization_id;
          l_subinventory := l_to_subinventory;
          l_inventory_location_id := l_to_inventory_location_id;
          l_lpn_id := l_to_lpn_id;
          l_to_organization_id := null;
          l_to_subinventory := null;
          l_to_inventory_location_id := null;
          l_to_lpn_id := null;

        -- Selecting distribution account
        BEGIN
          SELECT disposition_id -- distribution_account
            INTO   l_transaction_source_id
            FROM   mtl_generic_dispositions
           WHERE   organization_id = l_organization_id
             AND   SEGMENT1 = 'SCRAP-' || UPPER(l_division);
        EXCEPTION
           WHEN OTHERS THEN
                log_message('Cannot find distribution account for: ' || l_transaction_source_id );
        END;

       END IF;


    IF (( p_to_container IS NOT NULL ) or (p_container is not null))
    --( p_salesrep_id <> nvl(p_to_salesrep_id,-999))
    THEN
        log_message('This is a sub transfer/aa scrap/aa receipt with an LPN.... ');

      IF ( p_container IS NOT NULL ) THEN
        begin
          SELECT  wlpn.lpn_id
          INTO l_lpn_id
          FROM  wms_license_plate_numbers wlpn, wms_lpn_contents wlc,
                mtl_system_items_b msib, mtl_serial_numbers msn
          WHERE msn.serial_number = p_container
          AND   msn.lpn_id = wlpn.lpn_id
          AND   wlc.parent_lpn_id = wlpn.lpn_id
          AND   wlpn.organization_id = msn.current_organization_id
          AND   wlc.inventory_item_id = msn.inventory_item_id
          AND   wlpn.subinventory_code = msn.current_subinventory_code
          AND   wlpn.locator_id = msn.current_locator_id
          AND   wlpn.organization_id = msib.organization_id
          AND   wlc.inventory_item_id = msib.inventory_item_id
          AND   msib.item_type = 'K' and rownum = 1;
        EXCEPTION
          WHEN OTHERS THEN
            log_message('Cannot find lpn ID for: ' || p_container );
            begin
              select lpn_id into l_lpn_id from wms_license_plate_numbers where license_plate_number = p_container;
              log_message('Cannot find lpn ID after cannot find. Passed value: ' || p_container );
              log_message('Cannot find lpn ID after cannot find. Lpn ID: ' || l_lpn_id );
            exception
            when no_data_found then
              log_message('Cannot find lpn ID after cannot find: ' || p_container );
            end;

        END;
      END IF;

      IF ( p_to_container IS NOT NULL ) THEN
        begin
          SELECT  wlpn.lpn_id
          INTO l_to_lpn_id
          FROM  wms_license_plate_numbers wlpn, wms_lpn_contents wlc,
                mtl_system_items_b msib, mtl_serial_numbers msn
          WHERE msn.serial_number = p_to_container
          AND   msn.lpn_id = wlpn.lpn_id
          AND   wlc.parent_lpn_id = wlpn.lpn_id
          AND   wlpn.organization_id = msn.current_organization_id
          AND   wlc.inventory_item_id = msn.inventory_item_id
          AND   wlpn.subinventory_code = msn.current_subinventory_code
          AND   wlpn.locator_id = msn.current_locator_id
          AND   wlpn.organization_id = msib.organization_id
          AND   wlc.inventory_item_id = msib.inventory_item_id
          AND   msib.item_type = 'K'  and rownum = 1;
        EXCEPTION
          WHEN OTHERS THEN
            log_message('Cannot find lpn ID for: ' || p_to_container );
            begin
              select lpn_id into l_to_lpn_id from wms_license_plate_numbers where license_plate_number = p_to_container;
              log_message('Cannot find lpn ID after cannot find. Passed value: ' || p_to_container );
              log_message('Cannot find lpn ID after cannot find. Lpn ID: ' || l_to_lpn_id );
            exception
            when no_data_found then
              log_message('Cannot find lpn ID after cannot find: ' || p_to_container );
            end;
        END;
      END IF;
    END IF;

      log_message(' From Org: ' || l_organization_id);
      log_message(' From Sub: ' || l_subinventory);
      log_message(' From Loc: ' || l_inventory_location_id);
      log_message(' From LPN: ' || l_lpn_id);

      log_message(' To Org: ' || l_to_organization_id);
      log_message(' To Sub: ' || l_to_subinventory);
      log_message(' To Loc: ' || l_to_inventory_location_id);
      log_message(' To LPN: ' || l_to_lpn_id);

      /*** Modified by Vishy: 03/11/2014: If the transfer is a complete kit, then we need to unpack everything that is not passed in the list from SS
       ****/
       j := 0;
       l_transaction_quantity := 0;
        IF (l_lpn_id is not null and l_to_lpn_id is not null and l_lpn_id = l_to_lpn_id and l_lpn_id > 0) THEN
        -- We need to unpack all the items that are not in the list from the LPN.before we move the whole LPN

         -- Get a new transaction ID
               SELECT mtl_material_transactions_s.NEXTVAL
               INTO l_header_id_up
               FROM dual;

         FOR lpn_contents_rec in lpn_contents_cur (l_lpn_id)
          LOOP
              l_item_present := false;
              l_transaction_quantity := lpn_contents_rec.quantity;
              /*** Vishy: 08-Sep-2014: Logic to handle lots as part of reservations and unpack ****/
             -- l_lot_number := lpn_contents_rec.lot_number;
              j := j+1;
              log_message(' Item in LPN: ' || lpn_contents_rec.item);
              log_message(' Lot in LPN: ' || lpn_contents_rec.lot_number);
              log_message(' Qty in LPN: ' || lpn_contents_rec.quantity);

              l_lot_number := null;
              l_serial_number := null;

              FOR i IN l_transaction_items.First..l_transaction_items.Last
                LOOP

                /** Vishy: 10/20/2014: Move the lot field to serial field if the item is serial controlled. SS passes only one value
                    for lot/serial number ****/

                BEGIN
                  SELECT msib.inventory_item_ID, msib.lot_control_code, msib.serial_number_control_code
                  INTO   l_inventory_item_id, l_lot_control_code, l_serial_number_control_code
                  FROM   mtl_system_items_b msib
                  WHERE  segment1 = l_transaction_items(i).item
                  AND    organization_id = l_organization_id;
                EXCEPTION
                WHEN OTHERS THEN
                  null; --  user experience only
                  log_message('l_inventory_item_id not found for: ' || l_organization_id || ': ' ||l_transaction_items(i).item);
                END;

                  log_message(l_transaction_items(i).serial_number ||': '||l_inventory_item_id||': '||
                    l_transaction_items(i).lot_number ||': '|| l_transaction_items(i).quantity ||': '||
                    l_transaction_items(i).uom);

                   l_lot_number := l_transaction_items(i).lot_number;
                   l_serial_number := l_transaction_items(i).serial_number;


                If (l_transaction_items(i).lot_number is not null and l_lot_control_code = 1 and
                    l_serial_number_control_code in (2,5)) Then -- Item is non-lot controlled, but serial controlled
                      l_serial_number := l_transaction_items(i).lot_number;
                      l_lot_number := null;
                End if;

                log_message('l_lot_number ' || l_lot_number);
                log_message('l_serial_number ' || l_serial_number);

                /*** End Change *****/

                  IF (l_transaction_items(i).item = lpn_contents_rec.item) and
                  (nvl(l_lot_number,-999) = nvl(lpn_contents_rec.lot_number,-999) and
                  nvl(l_serial_number,-999) = nvl(lpn_contents_rec.serial_number,-999))
                  THEN
                    l_item_present := true;
                    log_message(' Item found: ' || l_transaction_items(i).item);
                    If (l_transaction_items(i).quantity <> lpn_contents_rec.quantity) and
                       (lpn_contents_rec.quantity > l_transaction_items(i).quantity) Then
                          l_transaction_quantity := lpn_contents_rec.quantity - l_transaction_items(i).quantity;
                          l_item_present := false;
                          log_message(' Qty mismatch: ' || lpn_contents_rec.quantity || ': ' || l_transaction_items(i).quantity);
                    END IF;
                  END IF;
              END LOOP;

              IF (l_item_present = false and lpn_contents_rec.item_type <> 'K') then
                  l_transaction_type_id_up := 88; -- Container Unpack
                  l_source_code_up :=  'Container Unpack';
                  log_message(' Item to unpack: (' ||  j || '): ' || lpn_contents_rec.item);
                  log_message(' Lot to unpack: (' ||  j || '): ' || lpn_contents_rec.lot_number);
                  log_message(' Qty to unpack: (' ||  j || '): ' || l_transaction_quantity);

                 /**** Before we unpack, we have to query the reservation and remove the reservation from the LPN level so that we can continue
                  with the move transaction *** Vishy 03/21/2014 ***/

                BEGIN
                    l_rsv_rec.organization_id := l_organization_id;
                    l_rsv_rec.inventory_item_id := lpn_contents_rec.inventory_item_id;
                    if (lpn_contents_rec.lot_number is not null) then
                      l_rsv_rec.lot_number := lpn_contents_rec.lot_number;
                    end if;
                    l_rsv_rec.lpn_id := lpn_contents_rec.lpn_id;

                      BEGIN
                      INV_RESERVATION_PVT.query_reservation(
                          p_api_version_number         => 1.0
                        , p_init_msg_lst               => fnd_api.g_false
                        , x_return_status              => l_return_status
                        , x_msg_count                  => x_msg_count
                        , x_msg_data                   => x_msg_data
                        , p_query_input                => l_rsv_rec
                        , p_lock_records               => fnd_api.g_true
                        , x_mtl_reservation_tbl        => l_tmp_rsv_tbl
                        , x_mtl_reservation_tbl_count  => l_tmp_rsv_tbl_count
                        , x_error_code                 => l_error_code
                        );

                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      log_message('No Records found with the matching criteria: ' || lpn_contents_rec.lpn_id);
                    WHEN OTHERS THEN
                      log_message('No Records found with the matching criteria2: ' || lpn_contents_rec.lpn_id);
                    END;

                    log_message (' Number of rerurned records: ' || l_tmp_rsv_tbl_count);

                    IF (l_tmp_rsv_tbl_count > 0) THEN

                      FOR i IN l_tmp_rsv_tbl.First..l_tmp_rsv_tbl.Last
                           LOOP
                           /*** Update all the reservations for the LPN being moved to null ****/
                               BEGIN
                                    log_message (' Reservation ID being updated: ' || l_tmp_rsv_tbl(i).reservation_id);
                                    l_rsv_old.reservation_id               := l_tmp_rsv_tbl(i).reservation_id;
                                    l_rsv_new.lpn_id := null;

                                   inv_reservation_pub.update_reservation
                                     (
                                        p_api_version_number        => 1.0
                                      , p_init_msg_lst              => fnd_api.g_true
                                      , x_return_status             => l_status
                                      , x_msg_count                 => l_msg_count
                                      , x_msg_data                  => l_msg_data
                                      , p_original_rsv_rec          => l_rsv_old
                                      , p_to_rsv_rec                => l_rsv_new
                                      , p_original_serial_number    => l_dummy_sn   --no serial contorl
                                      , p_to_serial_number            => l_dummy_sn  -- no serial control
                                      , p_validation_flag           => fnd_api.g_true
                                      );

                                   IF l_status = fnd_api.g_ret_sts_success THEN
                                      log_message('Update Done');
                                    ELSE
                                      IF l_msg_count = 1 THEN
                                       log_message('Error1: '|| l_msg_data);
                                       ELSE
                                         FOR l_index IN 1..l_msg_count LOOP
                                              l_msg_data := fnd_msg_pub.get(l_index,'T');
                                          --  fnd_msg_pub.get(l_msg_data);
                                            log_message('Error2: '|| l_msg_data);
                                         END LOOP;
                                      END IF;
                                   END IF;
                                END;

                             /**** Vishy: 06/03/2014: Update MMTT record to remove the LPN allocation as well as we remove the reservation from the LPM ****/
                            Begin
                             update mtl_material_transactions_temp set allocated_lpn_id = null where reservation_id = l_tmp_rsv_tbl(i).reservation_id;
                             exception when no_data_found then
                                log_message ('Cannot find allocation for the reservation ID: ' || l_tmp_rsv_tbl(i).reservation_id);
                            End;

                            END LOOP;

                    END IF;

                  End;

                    consignment_transaction
                      (
                             p_source_code      => l_source_code_up,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_header_id_up,
                             p_line_id          => j,
                             p_organization_id  => l_organization_id, -- logic to decide whith one -- l_organization_id,
                             p_transaction_type_id => l_transaction_type_id_up,
                             p_subinventory     => l_subinventory,
                             p_inventory_location_id  => l_inventory_location_id,
                             p_lpn              => lpn_contents_rec.lpn_id,
                             p_xfer_item        => lpn_contents_rec.item, -- l_xfer_item,
                             p_xfer_quantity    => (-1) * l_transaction_quantity, --l_xfer_quantity,
                             p_xfer_uom         => lpn_contents_rec.uom_code, -- l_xfer_uom,
                             p_lot_number       => lpn_contents_rec.lot_number,
                             p_serial_number    => lpn_contents_rec.serial_number,
                             p_to_organization_id  => null,
                             p_to_subinventory  => null, -- l_to_subinventory,
                             p_to_inventory_location_id  => null,
                             p_to_lpn           => null, -- p_to_container,
                             p_reason_id        => l_reason_id,
                             --            p_user_id          => p_user_id, -- for Ticket 005897
                   p_user_id          => l_user_id,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );

                        IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                          log_message(' Message from unpacking missing item --> ' || l_return_message);
                          log_message(' item  --> '|| lpn_contents_rec.item);
                          log_message(' serial  --> ' || lpn_contents_rec.serial_number);
                          log_message(' lpn  --> ' || lpn_contents_rec.lpn_id);
                          log_message(' lot  --> ' || lpn_contents_rec.lot_number);
                        ELSE
                          log_message(' Successfully unpacked the item --> ' || lpn_contents_rec.item);
                          log_message(' Successfully unpacked the item --> ' || l_return_message);
                          log_message(' serial  --> ' || lpn_contents_rec.serial_number);
                          log_message(' lpn  --> ' || lpn_contents_rec.lpn_id);
                          log_message(' lot  --> ' || lpn_contents_rec.lot_number);
                          log_message(' Qty unpacked  --> ' || l_transaction_quantity);
                        END IF;
                End If;
          END LOOP;

          v_count := 0;
          Begin
            select count(1) into v_count from mtl_transactions_interface where transaction_header_id = l_header_id_up;
          exception
          when no_data_found then
            log_message('Cannot find MTI records for header ID: '|| l_header_id_up);
          end;

          log_message('V count for unpack txns: '|| v_count);

          If v_count > 0 Then
            log_message('Before call TM: Header ID for unpack txns: '|| l_header_id_up);
            l_return := INV_TXN_MANAGER_PUB.process_transactions(p_api_version => 1.0
                                  ,p_init_msg_list => fnd_api.g_true -- 'T'
                                  ,p_commit => fnd_api.g_true  -- 'T'
                                  -- ,p_commit => fnd_api.g_false
                                  ,p_validation_level => fnd_api.g_valid_level_full
                                  ,x_return_status => l_return_status
                                  ,x_msg_count => x_msg_count
                                  ,x_msg_data => x_return_message
                                  ,x_trans_count => x_trans_count
                                  ,p_table => 1
                                  ,p_header_id => l_header_id_up);

             IF l_return_status <> fnd_api.g_ret_sts_success THEN
                IF x_msg_count > 0 THEN
                  FOR i IN 1 .. x_msg_count
                  LOOP
                      x_return_message := substr ( x_return_message || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 2000);
                      log_message('x_return_message for unpack error: '|| x_return_message);
                  END LOOP;
                END IF;
              --  RAISE fnd_api.g_exc_error;
             END IF;
          log_message('After call TM: Status Unpack : '|| l_return_status);
         End If;

        End if;

      /****End Change 03/11/2014 by Vishy for Unpacking missing items from kit before moving the entire kit****/

        SELECT mtl_material_transactions_s.NEXTVAL
             INTO l_header_id_dummy
             FROM dual;

        Begin
          SELECT reason_id into l_reason_id_dummy from mtl_transaction_reasons where reason_name = 'SurgiSoft Oracle Mismatch';
        Exception
        when no_data_found then
          log_message('Cannot find reason Id for reason code: SurgiSoft Oracle Mismatch ');
        End;

        l_lot_number := null;
        l_serial_number := null;

        FOR n IN l_transaction_items.First..l_transaction_items.Last
        LOOP
           log_message('n: ' || n || ' item: ' || l_transaction_items(n).item || ' quantity: ' || l_transaction_items(n).quantity);

           If (l_transaction_type_id = 31) then
              l_transaction_items(n).quantity := (-1) * l_transaction_items(n).quantity;
           End if;

           /** Vishy: 10/20/2014: Move the lot field to serial field if the item is serial controlled. SS passes only one value
                    for lot/serial number ****/

                BEGIN
                  SELECT msib.inventory_item_ID, msib.lot_control_code, msib.serial_number_control_code
                  INTO   l_inventory_item_id, l_lot_control_code, l_serial_number_control_code
                  FROM   mtl_system_items_b msib
                  WHERE  segment1 = l_transaction_items(n).item
                  AND    organization_id = l_organization_id;
                EXCEPTION
                WHEN OTHERS THEN
                  null; --  user experience only
                  log_message('l_inventory_item_id not found for: ' || l_organization_id || ': ' ||l_transaction_items(i).item);
                END;

                  log_message(l_transaction_items(n).serial_number ||': '||l_inventory_item_id||': '||
                    l_transaction_items(n).lot_number ||': '|| l_transaction_items(n).quantity ||': '||
                    l_transaction_items(n).uom);

                   l_lot_number := l_transaction_items(n).lot_number;
                   l_serial_number := l_transaction_items(n).serial_number;


                If (l_transaction_items(n).lot_number is not null and l_lot_control_code = 1 and
                    l_serial_number_control_code in (2,5)) Then -- Item is non-lot controlled, but serial controlled
                      l_serial_number := l_transaction_items(n).lot_number;
                      l_lot_number := null;
                End if;

                log_message('l_lot_number ' || l_lot_number);
                log_message('l_serial_number ' || l_serial_number);

                /*** End Change *****/

           /*** Check for items and quantities where SS has more than Oracle. These will have to be processed and failed prior to moving the
           entire LPN ****/
           -- Change subtransfer to be To SS Transfer
          If (l_lpn_id is not null and l_to_lpn_id is not null and l_lpn_id = l_to_lpn_id and l_lpn_id > 0 and
            l_transaction_type_id = 200 ) then

            log_message('Inside Full LPN Move ');
            l_item_present := false;
            l_transaction_quantity := 0;

              FOR lpn_items_rec in lpn_items_cur (l_lpn_id)
                LOOP
                --Vishy:17-OCT-2014: Added check for SS qty more only if item type <> K
                  l_lpn_item_type := lpn_items_rec.item_type;

                  IF (l_transaction_items(n).item = lpn_items_rec.item) and
                      (nvl(l_lot_number,-999) = nvl(lpn_items_rec.lot_number,-999))
                  THEN
                        l_item_present := true;
                        log_message(' Item found: ' || l_transaction_items(n).item);
                        If (l_transaction_items(n).quantity <> lpn_items_rec.quantity) and
                           (l_transaction_items(n).quantity > lpn_items_rec.quantity ) Then
                              l_transaction_quantity := l_transaction_items(n).quantity - lpn_items_rec.quantity;
                              l_transaction_items(n).quantity := lpn_items_rec.quantity;
                              l_item_present := false;
                              log_message(' Qty mismatch: ' || l_transaction_items(n).quantity || ': ' || lpn_items_rec.quantity);
                        END IF;
                  END IF;
                End Loop;

                If (l_item_present = false and l_transaction_quantity > 0) then -- there is a mismatch
                   If (l_lpn_item_type <> 'K') then
                       /*** Insert one record for the transfer and one record for the mismatch as the item is found but with more in SS***/
                        l_transaction_type_id_dummy := 999; -- Dummy transaction for the remainder
                        l_source_code_dummy :=  'SS Qty More';
                        log_message('Inside item present and mismatch  ');
                        log_message(' Insert as error record: ' ||  l_transaction_items(n).item);
                        log_message(' Qty Difference: ' ||  l_transaction_quantity);
                        l_reason_id := 'SurgiSoft Oracle Mismatch';

                       consignment_transaction
                        (
                               p_source_code      => l_source_code_dummy,
                               p_transaction_source_id => l_transaction_source_id,
                               p_header_id        => l_header_id_dummy,
                               p_line_id          => n,
                               p_organization_id  => l_organization_id, -- always consignment
                               p_transaction_type_id => l_transaction_type_id_dummy,
                               p_subinventory     => l_subinventory,
                               p_inventory_location_id  => l_inventory_location_id,
                               p_lpn              => l_lpn_id,
                               p_xfer_item        => l_transaction_items(n).item, -- l_xfer_item,
                               p_xfer_quantity    => l_transaction_quantity, --l_xfer_quantity,
                               p_xfer_uom         => l_transaction_items(n).uom, -- l_xfer_uom,
                               p_lot_number       => l_lot_number,
                               p_serial_number    => l_serial_number,
                               p_to_organization_id  => l_to_organization_id,
                               p_to_subinventory  => l_to_subinventory,
                               p_to_inventory_location_id => l_to_inventory_location_id,
                               p_to_lpn           => l_to_lpn_id,
                               p_reason_id        => l_reason_id_dummy,
                               --            p_user_id          => p_user_id,
                               p_user_id          => l_user_id,
                               p_return_status    => l_return_status,
                               p_return_message   => l_return_message
                        );

                         IF ( l_return_status <> 'S' ) THEN
                            log_message('Error processing: ' || l_transaction_items(i).item || l_return_message);
                         END IF;
                   End If;

                    If (l_content_rec_inserted = 0) then
                     consignment_transaction
                      (
                             p_source_code      => l_source_code,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_header_id,
                             p_line_id          => n,
                             p_organization_id  => l_organization_id, -- always consignment
                             p_transaction_type_id => l_transaction_type_id,
                             p_subinventory     => l_subinventory,
                             p_inventory_location_id  => l_inventory_location_id,
                             p_lpn              => l_lpn_id,
                             p_xfer_item        => l_transaction_items(n).item, -- l_xfer_item,
                             p_xfer_quantity    => l_transaction_items(n).quantity, --l_xfer_quantity,
                             p_xfer_uom         => l_transaction_items(n).uom, -- l_xfer_uom,
                             p_lot_number       => l_lot_number,
                             p_serial_number    => l_serial_number,
                             p_to_organization_id  => l_to_organization_id,
                             p_to_subinventory  => l_to_subinventory,
                             p_to_inventory_location_id => l_to_inventory_location_id,
                             p_to_lpn           => l_to_lpn_id,
                             p_reason_id        => l_reason_id,
                             --            p_user_id          => p_user_id, -- for Ticket 005897
                             p_user_id          => l_user_id,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );

                       IF ( l_return_status <> 'S' ) THEN
                          log_message('Error processing: ' || l_transaction_items(i).item || l_return_message);
                       END IF;
                     End if;
                     l_content_rec_inserted := l_content_rec_inserted + 1;

                elsif (l_item_present = false and l_transaction_quantity = 0 and l_lpn_item_type <> 'K') then -- the item is not found then insert only the dummy one

                  /*** Insert one record for the transfer and one record for the mismatch as the item is found but with more in SS***/
                    l_transaction_type_id_dummy := 999; -- Dummy transaction for the remainder
                    l_source_code_dummy :=  'SS Qty More';
                    log_message('Inside item not present');
                    log_message(' Insert as error record: ' ||  l_transaction_items(n).item);
                    log_message(' Qty Difference: ' ||  l_transaction_quantity);
                    l_reason_id := 'SurgiSoft Oracle Mismatch';
                   consignment_transaction
                    (
                           p_source_code      => l_source_code_dummy,
                           p_transaction_source_id => l_transaction_source_id,
                           p_header_id        => l_header_id_dummy,
                           p_line_id          => n,
                           p_organization_id  => l_organization_id, -- always consignment
                           p_transaction_type_id => l_transaction_type_id_dummy,
                           p_subinventory     => l_subinventory,
                           p_inventory_location_id  => l_inventory_location_id,
                           p_lpn              => l_lpn_id,
                           p_xfer_item        => l_transaction_items(n).item, -- l_xfer_item,
                           p_xfer_quantity    => l_transaction_items(n).quantity, --l_xfer_quantity,
                           p_xfer_uom         => l_transaction_items(n).uom, -- l_xfer_uom,
                           p_lot_number       => l_lot_number,
                           p_serial_number    => l_serial_number,
                           p_to_organization_id  => l_to_organization_id,
                           p_to_subinventory  => l_to_subinventory,
                           p_to_inventory_location_id => l_to_inventory_location_id,
                           p_to_lpn           => l_to_lpn_id,
                           p_reason_id        => l_reason_id_dummy,
                           --            p_user_id          => p_user_id,
                           p_user_id          => l_user_id,
                           p_return_status    => l_return_status,
                           p_return_message   => l_return_message
                    );

                 IF ( l_return_status <> 'S' ) THEN
                    log_message('Error processing: ' || l_transaction_items(i).item || l_return_message);
                 END IF;

                Else -- item is found and no mismatch - insert as-is
                 log_message('Inside found and no mismatch ' || l_content_rec_inserted );

                                       log_message('VALUES******');
                      log_message(l_source_code);
                      log_message(l_transaction_source_id);
                      log_message(l_header_id);
                      log_message(n);
                      log_message(l_organization_id);
                      log_message(l_transaction_type_id);
                      log_message(l_subinventory);
                      log_message(l_inventory_location_id);
                      log_message(l_lpn_id);
                      log_message(l_transaction_items(n).item);
                      log_message(l_transaction_items(n).quantity);
                      log_message(l_transaction_items(n).uom);
                      log_message(l_lot_number);--log_message(l_transaction_items(n).lot_number);
                      log_message(l_serial_number);--log_message(l_transaction_items(n).serial_number);
                      log_message(l_to_organization_id);
                      log_message(l_to_subinventory);
                      log_message(l_to_inventory_location_id);
                      log_message(l_to_lpn_id);
                      log_message(l_reason_id);
                      log_message(p_user_id);
                      log_message(l_return_status);
                      log_message(l_return_message);
                      log_message('END VALUES******');

                 If (l_content_rec_inserted = 0) then
                    consignment_transaction
                      (
                             p_source_code      => l_source_code,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_header_id,
                             p_line_id          => n,
                             p_organization_id  => l_organization_id, -- always consignment
                             p_transaction_type_id => l_transaction_type_id,
                             p_subinventory     => l_subinventory,
                             p_inventory_location_id  => l_inventory_location_id,
                             p_lpn              => l_lpn_id,
                             p_xfer_item        => l_transaction_items(n).item, -- l_xfer_item,
                             p_xfer_quantity    => l_transaction_items(n).quantity, --l_xfer_quantity,
                             p_xfer_uom         => l_transaction_items(n).uom, -- l_xfer_uom,
                             p_lot_number       => l_lot_number,
                             p_serial_number    => l_serial_number,
                             p_to_organization_id  => l_to_organization_id,
                             p_to_subinventory  => l_to_subinventory,
                             p_to_inventory_location_id => l_to_inventory_location_id,
                             p_to_lpn           => l_to_lpn_id,
                             p_reason_id        => null, -- l_reason_id,
                            --            p_user_id          => p_user_id,
                   p_user_id          => l_user_id,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );


                       IF ( l_return_status <> 'S' ) THEN
                          log_message('Error processing: ' || l_transaction_items(i).item || l_return_message);
                       END IF;
                   End If;
                   l_content_rec_inserted := l_content_rec_inserted + 1;

                End If;

             /**** End of this block ****/
          Else -- vishy 03/12/2014
             -- Make the actual transaction
             consignment_transaction
                  (
                         p_source_code      => l_source_code,
                         p_transaction_source_id => l_transaction_source_id,
                         p_header_id        => l_header_id,
                         p_line_id          => n,
                         p_organization_id  => l_organization_id, -- always consignment
                         p_transaction_type_id => l_transaction_type_id,
                         p_subinventory     => l_subinventory,
                         p_inventory_location_id  => l_inventory_location_id,
                         p_lpn              => l_lpn_id,
                         p_xfer_item        => l_transaction_items(n).item, -- l_xfer_item,
                         p_xfer_quantity    => l_transaction_items(n).quantity, --l_xfer_quantity,
                         p_xfer_uom         => l_transaction_items(n).uom, -- l_xfer_uom,
                         p_lot_number       => l_lot_number,
                         p_serial_number    => l_serial_number,
                         p_to_organization_id  => l_to_organization_id,
                         p_to_subinventory  => l_to_subinventory,
                         p_to_inventory_location_id => l_to_inventory_location_id,
                         p_to_lpn           => l_to_lpn_id,
                         p_reason_id        => l_reason_id,
                         --            p_user_id          => p_user_id,
                   p_user_id          => l_user_id,
                         p_return_status    => l_return_status,
                         p_return_message   => l_return_message
                  );

                 IF ( l_return_status <> 'S' ) THEN
                    log_message('Error processing: ' || l_transaction_items(i).item || l_return_message);
                 END IF;
          End If; -- Vishy 03/12/2014
        END LOOP;
   /***** This is the inter-org from 150 to DC directly if we need to move overages back to inventory at the DC
   ELSIF ((l_organization_id <> l_to_organization_id) AND (p_salesrep_id in (-8,-17))) THEN -- Overrages

   log_message('This is a Inter-Org transfer.... ');

   IF (p_container is not null)
    THEN
        log_message('This is a inter-org transfer from an LPN.... ');
          SELECT  wlpn.lpn_id
          INTO l_lpn_id
          FROM  wms_license_plate_numbers wlpn, wms_lpn_contents wlc,
                mtl_system_items_b msib, mtl_serial_numbers msn
          WHERE msn.serial_number = P_CONTAINER
          AND   msn.lpn_id = wlpn.lpn_id
          AND   wlc.parent_lpn_id = wlpn.lpn_id
          AND   wlpn.organization_id = msn.current_organization_id
          AND   wlc.inventory_item_id = msn.inventory_item_id
          AND   wlpn.subinventory_code = msn.current_subinventory_code
          AND   wlpn.locator_id = msn.current_locator_id
          AND   wlpn.organization_id = msib.organization_id
          AND   wlc.inventory_item_id = msib.inventory_item_id
          AND   msib.item_type = 'K';
    END IF;

    FOR n IN l_transaction_items.First..l_transaction_items.Last
        LOOP
         log_message('n: ' || n || ' item: ' || l_transaction_items(n).item || ' quantity: ' || l_transaction_items(n).quantity);

         l_transaction_type_id := 3;
         -- item, quantity, uom, serial_number, lot_number
         -- Make the actual transaction
         consignment_transaction
              (
                     p_source_code      => l_source_code,
                     p_transaction_source_id => l_transaction_source_id,
                     p_header_id        => l_header_id,
                     p_line_id          => n,
                     p_organization_id  => l_organization_id, -- always consignment
                     p_transaction_type_id => l_transaction_type_id,
                     p_subinventory     => l_subinventory,
                     p_inventory_location_id  => l_inventory_location_id,
                     p_lpn              => l_lpn_id,
                     p_xfer_item        => l_transaction_items(n).item, -- l_xfer_item,
                     p_xfer_quantity    => l_transaction_items(n).quantity, --l_xfer_quantity,
                     p_xfer_uom         => l_transaction_items(n).uom, -- l_xfer_uom,
                     p_lot_number       => l_transaction_items(n).lot_number,
                     p_serial_number    => l_transaction_items(n).serial_number,
                     p_to_organization_id  => l_to_organization_id,
                     p_to_subinventory  => l_to_subinventory,
                     p_to_inventory_location_id => l_to_inventory_location_id,
                     p_to_lpn           => l_to_lpn_id,
                     p_reason_id        => l_reason_id,
                     p_user_id          => p_user_id,
                     p_return_status    => l_return_status,
                     p_return_message   => l_return_message
              );

         IF ( l_return_status <> 'S' ) THEN
            log_message('Error processing: ' || l_transaction_items(i).item || l_return_message);
         END IF;

     END LOOP;
   ******/
   END IF;

   COMMIT;

   log_message('Before call TM: Header ID for reg txns: '|| l_header_id);

   l_return := INV_TXN_MANAGER_PUB.process_transactions(p_api_version => 1.0
                                                              ,p_init_msg_list => fnd_api.g_true -- 'T'
                                                              ,p_commit => fnd_api.g_true  -- 'T'
                                -- ,p_commit => fnd_api.g_false
                                                              ,p_validation_level => fnd_api.g_valid_level_full
                                                              ,x_return_status => x_return_status
                                                              ,x_msg_count => x_msg_count
                                                              ,x_msg_data => x_return_message
                                                              ,x_trans_count => x_trans_count
                                                              ,p_table => 1
                                                              ,p_header_id => l_header_id);

   IF x_return_status <> fnd_api.g_ret_sts_success THEN
      IF x_msg_count > 0 THEN
        FOR i IN 1 .. x_msg_count
        LOOP
            x_return_message := substr ( x_return_message || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 2000);
            log_message('x_return_message for regular txns: '|| x_return_message);
        END LOOP;
      END IF;
     -- RAISE fnd_api.g_exc_error;
   END IF;

   log_message('After call TM: Status Reg txns: '|| l_return_status);

   v_count := 0;

   Begin
      select count(1) into v_count from mtl_transactions_interface where transaction_header_id = l_header_id_dummy;
   exception
      when no_data_found then
      log_message('Cannot find MTI records for header ID: '|| l_header_id_dummy);
   end;

   log_message('V count for SS more than Oracle txns: '|| v_count);

   If v_count > 0 then

       log_message('Before call TM: Header ID for dummy txns: '|| l_header_id_dummy);

       l_return := INV_TXN_MANAGER_PUB.process_transactions(p_api_version => 1.0
                                    ,p_init_msg_list => fnd_api.g_true -- 'T'
                                    ,p_commit => fnd_api.g_true  -- 'T'
                                    -- ,p_commit => fnd_api.g_false
                                    ,p_validation_level => fnd_api.g_valid_level_full
                                    ,x_return_status => x_return_status
                                    ,x_msg_count => x_msg_count
                                    ,x_msg_data => x_return_message
                                    ,x_trans_count => x_trans_count
                                    ,p_table => 1
                                    ,p_header_id => l_header_id_dummy);

       IF x_return_status <> fnd_api.g_ret_sts_success THEN
          IF x_msg_count > 0 THEN
            FOR i IN 1 .. x_msg_count
            LOOP
                x_return_message := substr ( x_return_message || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 2000);
                log_message('x_return_message for dummy records: '|| x_return_message);
            END LOOP;
          END IF;
         -- RAISE fnd_api.g_exc_error;
       END IF;
       log_message('After call TM: Status dummy txns: '|| l_return_status);
    End If;

   p_return_status := 'S';
   p_return_code := l_header_id;
   p_return_message := 'Successfully processed transfer. Transaction ID: ' || l_header_id;

EXCEPTION
/***
WHEN fnd_api.g_exc_error THEN
      x_return_status  := fnd_api.g_ret_sts_error;
      --  Get message count and data
      fnd_msg_pub.count_and_get(p_count => x_msg_count, p_data => x_return_message);
***/
WHEN OTHERS THEN
   p_return_status := 'E';
   p_return_code := sqlcode;
   p_return_message := 'Error processing transfer.' || sqlerrm;
END Create_Transfer_Request;

END XXOM_CNSGN_MTL_XFER_PKG;
/
