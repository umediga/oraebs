DROP PACKAGE BODY APPS.XXOM_SET_BKDN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_SET_BKDN_PKG" IS

/*************************************************************************************
*   PROGRAM NAME
*     XXOM_SET_BKDN_PKG.sql
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
*     1.0 22-DEC-2013 Brian Stadnik
*         29-MAY-2014 Brian Stadnik       Removed logic to use p_trans_date
*                                         Moved call to transaction manager inside of the 
*                                         loop in order to place a single kit into a 
*                                         batch, so if one kit errors out, then all of them
*                                         will not error out.
*                                         Changed the transaction_date to just use the 
*                                         sysdate.
*                                         Changed to not breakdown if the LPN is not in the 
*                                         consignment org
*                                         Added log_message procedure to help with troubleshooting
*
* ISSUES:
*
*
******************************************************************************************/

PROCEDURE log_message(p_log_message  IN  VARCHAR2)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO xxintg_cnsgn_cmn_log_tbl 
      VALUES (xxintg_cnsgn_cmn_log_seq.nextval, 'XXOM_SET_BKDN_PKG',
             p_log_message, SYSDATE);
  COMMIT;
  dbms_output.put_line(p_log_message);
END LOG_MESSAGE;


PROCEDURE INTG_SET_BKDN_EXT_PRC
                                (errbuf                 OUT VARCHAR2,
                                 retcode            OUT VARCHAR2,
                                 p_from_orgn_id       IN  NUMBER,
                                 p_to_orgn_id       IN  NUMBER,
                                 p_to_subinv_code    IN  VARCHAR2,
                                 p_trans_date        IN  VARCHAR2,
                                 p_rec_acc_alias_name    IN  VARCHAR2,
                                 p_rec_tran_type_name    IN  VARCHAR2,
                                 p_set_subinv_code    IN  VARCHAR2
                                 )

IS

v_status          VARCHAR2(20);
lv_count          NUMBER:=NULL;
l_proc_status          VARCHAR2(1):=NULL;
v_org_code        VARCHAR2(20):=NULL;
v_to_orgn_code    VARCHAR2(20);
v_lot_exp_date      DATE:= NULL;
--l_trans_date        DATE:=to_date(p_trans_date, 'YYYY/MM/DD HH24:MI:SS');
l_trans_date        DATE := fnd_date.canonical_to_date(p_trans_date);
l_to_orgn_id           NUMBER:=p_to_orgn_id;
l_from_orgn_id         NUMBER:=p_from_orgn_id;
l_to_subinv_code    VARCHAR2(50):=p_to_subinv_code;
l_set_locator_id     NUMBER;
l_source_name        VARCHAR2(50);
l_rec_acc_alias_name    VARCHAR2(50) :=p_rec_acc_alias_name;
l_rec_tran_type_name    VARCHAR2(50) :=p_rec_tran_type_name;
l_tran_type_name    VARCHAR2(50):=NULL;
l_set_subinv_code    VARCHAR2(50):=p_set_subinv_code;
l_wo_comp_found      VARCHAR2(1);
l_wo_issue_found      VARCHAR2(1);

r_wo_comp_date        DATE; 
r_xx_set_creation_date DATE;

c_container_split  NUMBER := 52;
-- Cursor to get the work order details

e_validation_error exception;

cursor c_shipments is
select mtt.transaction_type_name,
       mso.segment1 internal_order_number, 
       mmt.transaction_date,
       1 transaction_quantity, 
       mmt.transaction_uom, 
       mmt.transaction_id, 
       mmt.inventory_item_id, 
       mut.serial_number, 
       mmt.ship_to_location_id, 
       subinv.secondary_inventory_name set_subinventory_code,
       mil.segment1 loc_segment1,
       mil.segment2 loc_segment2,
       mil.segment3 loc_segment3
       --substr(subinv.secondary_inventory_name,1,10) loc_segment1,
       --decode(subinv.attribute1,'H','001',substr(div.snm_division,1,3) ) loc_segment2,
       --'REC' loc_segment2,--, oeh.ship_to_org_id       
       --'001' loc_segment3
  from mtl_material_transactions mmt,
       mtl_Sales_orders mso, 
       mtl_unit_transactions mut,
       mtl_transaction_types mtt,
       mtl_secondary_inventories subinv, 
       -- intg_set_bkdn_stg xxset, 
       xxom_sales_marketing_set_v div,
       mtl_system_items_b msib,
       mtl_item_locations mil
 where mmt.transaction_type_id in (54, 62)  -- = 62
   and mmt.transaction_source_type_id = 8
   and mmt.transaction_source_id = mso.sales_order_id
   and mtt.transaction_type_id = mmt.transaction_type_id
   and mmt.transaction_id = mut.transaction_id
   and mmt.organization_id = l_from_orgn_id
   and mmt.transfer_organization_id = l_to_orgn_id 
   and nvl(subinv.location_id,mmt.ship_to_location_id) = mmt.ship_to_location_id
   and subinv.secondary_inventory_name = nvl(l_set_subinv_code, subinv.secondary_inventory_name) 
   and subinv.organization_id = mmt.transfer_organization_id
   and subinv.secondary_inventory_name = mmt.transfer_subinventory
   and div.inventory_item_id = mmt.inventory_item_id
   and div.organization_id = mmt.organization_id
   and mil.organization_id = mmt.transfer_organization_id
   and mil.inventory_location_id = mmt.transfer_locator_id
   and mil.subinventory_code = mmt.transfer_subinventory
   -- BXS add join to look for KIT only
   and msib.inventory_item_id = mmt.inventory_item_id
   and msib.organization_id = mmt.organization_id
   and msib.item_type = 'K'
   -- and xxset.orig_transaction_id (+) = mmt.transaction_id
   -- and mmt.transaction_date >= NVL (xxset.creation_date, mmt.transaction_date-1)
   -- 5/28/14 - removing transaction_date requirement
   -- since we are looking for kits that haven't been processed
   -- and mmt.transaction_Date >= l_trans_date
   --
   -- BXS Explode only the latest shipment by looking at the latest shipment
   --     for that serial number
   and mmt.transaction_date = 
       (
        select max (mmt2.transaction_date)
        from mtl_material_transactions mmt2, mtl_unit_transactions mut2
        where mmt2.organization_id = p_from_orgn_id
        and mmt2.transaction_type_id in (54, 62)
        and mmt2.transaction_id = mut2.transaction_id
        and mut2.serial_number = mut.serial_number
       )
   -- 06/03/14 - check if the transaction exists in the staging table
   and not exists  ( select 1 from intg_set_bkdn_stg xxset where 
                     xxset.orig_transaction_id = mmt.transaction_id
                     and xxset.CHILD_ITEM = xxset.parent_item and xxset.serial_number is not null 
                     and mut.serial_number = xxset.serial_number)
   ;
      
cursor c_locator(cp_seg1 in varchar2, cp_seg2 in varchar2, cp_seg3 in varchar2) is
   select mil.inventory_location_id 
     from mtl_item_locations mil 
    where       
          mil.segment1 = cp_seg1
      and mil.segment2 = cp_seg2 --'REC'
      and mil.segment3 = cp_seg3 -- always 001
      ;
      
CURSOR c_work_order(cp_item_id in number, cp_serial_number in varchar2) IS
SELECT       we.wip_entity_name,
             we.primary_item_id,
             we.wip_entity_id,
             mut.serial_number,
             null lot_number,
             mut.serial_number lot_serial,
             1 transaction_quantity,
             mmt.transaction_date,
             mmt.subinventory_code,
             mmt.transaction_uom,
             mmt.revision,
             mmt.transfer_subinventory,
             mmt.transaction_type_id,
             mmt.transaction_id,
             mtt.transaction_type_name
  from mtl_unit_transactions mut, 
              mtl_material_transactions mmt,
              mtl_transaction_types mtt,
              wip_entities we,
              wip_discrete_jobs wdj,
              bom_bill_of_materials bbom,
              intg_set_bkdn_stg xxset 
 where mut.transaction_id = mmt.transaction_id
   and mmt.transaction_type_id = mtt.transaction_type_id
   and mut.serial_number = cp_serial_number
   and mmt.inventory_item_id = cp_item_id
   and we.wip_entity_id = wdj.wip_entity_id
   and mmt.organization_id = p_from_orgn_id
   and mmt.transaction_type_id = 44  -- WIP Completion
--   and bbom.attribute1='Y'
   and wdj.status_type in ( 4, 12 )
--   AND wdj.attribute5 IN (Select organization_code 
--                             from org_organization_definitions where organization_id=l_to_orgn_id)
   -- In the case of two or more WIP completions e.g. serial number change
   -- get the most recent one
   and mmt.transaction_date = 
   (
   select max (transaction_date)
   from mtl_material_transactions mmt2
   where mmt2.transaction_source_id = we.wip_entity_id
   and mmt2.organization_id = p_from_orgn_id
   and mmt2.transaction_type_id = 44  -- WIP Completion
   )
   -- 
   and mmt.transaction_source_type_id = 5
   and we.wip_entity_id=mmt.transaction_source_id
   and we.primary_item_id=bbom.assembly_item_id
   and we.organization_id=bbom.organization_id
   and xxset.orig_transaction_id (+) = mmt.transaction_id
   and mmt.transaction_date >= NVL (xxset.creation_date, mmt.transaction_date-1)
   ;

CURSOR c_work_order_components(cp_wip_entity_id in number) IS
SELECT       mmt.inventory_item_id,
             mut.serial_number,
             mtln.lot_number,
             NVL (mut.serial_number, mtln.lot_number) lot_serial,
             CASE                                       --- Added this logic to fetch lot qty instead of total qty transacted on 08/02/10.
            WHEN mut.serial_number IS NOT NULL
            THEN
               1
            WHEN mut.serial_number IS NULL AND mtln.lot_number IS NOT NULL
            THEN
               mtln.transaction_quantity
            ELSE
               mmt.transaction_quantity
           END 
           --
           +
            -- transaction_quantity,
            --
            NVL(CASE                                       --- Added this logic to fetch lot qty instead of total qty transacted on 08/02/10.
            WHEN mut2.serial_number IS NOT NULL
            THEN
               1
            WHEN mut2.serial_number IS NULL AND mtln2.lot_number IS NOT NULL
            THEN
               mtln2.transaction_quantity
            ELSE
               mmt2.transaction_quantity
           END,0)
            transaction_quantity,
            --- transaction_quantity,
             --mmt.transaction_quantity) transaction_quantity,
             mmt.transaction_date,
             mmt.subinventory_code,
             mmt.transaction_uom,
             mmt.revision,
             mmt.transfer_subinventory,
             mmt.transaction_type_id,
             mmt.transaction_id,
             mtt.transaction_type_name
      FROM   mtl_material_transactions mmt,
             wip_entities we,
             wip_discrete_jobs wdj,
             mtl_transaction_lot_numbers mtln,
             mtl_unit_transactions mut,
             mtl_transaction_types mtt,
             mtl_secondary_inventories mseci
             -- 
             ,
             mtl_material_transactions mmt2,
             mtl_transaction_lot_numbers mtln2,
             mtl_unit_transactions mut2
             -- 
     WHERE   we.wip_entity_id = wdj.wip_entity_id
       AND   mmt.organization_id = p_from_orgn_id
       AND   mmt.transaction_type_id = mtt.transaction_type_id
       AND   mmt.transaction_type_id = 35
       AND   mmt.transaction_source_type_id = 5
       and   mmt.transaction_source_id = we.wip_entity_id
       AND   mmt.transaction_source_id = cp_wip_entity_id
       AND   mmt.transaction_id = mtln.transaction_id(+)
       AND   mmt.transaction_id = mut.transaction_id(+)
       AND   mseci.secondary_inventory_name=mmt.subinventory_code
       AND   mmt.organization_id=mseci.organization_id
       --
       --  add reversing transactions to get the accurate quantity
       AND   mmt2.organization_id (+) = p_from_orgn_id
       -- AND   mmt2.transaction_type_id = mtt2.transaction_type_id
       AND   mmt2.transaction_type_id (+) in (43,90,38) -- WIP return, WIP scrap, WIP negative issue
       AND   mmt2.transaction_source_type_id (+) = 5
       AND   mmt2.transaction_source_id (+) = mmt.transaction_source_id
       AND   mmt2.transaction_id  = mtln2.transaction_id(+)
       AND   mmt2.transaction_id = mut2.transaction_id(+)
       AND   decode(mmt2.inventory_item_id,null,'-1' , 
                   nvl(nvl(mut.serial_number,mtln.lot_number),'-1') ) 
                 = nvl(nvl(mut2.serial_number, mtln2.lot_number),'-1')
       AND   mmt2.inventory_item_id (+) = mmt.inventory_item_id
       AND   mseci.secondary_inventory_name=mmt.subinventory_code
       AND   mmt.organization_id=mseci.organization_id
       -- don't create a record in the staging table or explode if the total quantity is 0
       AND  ( CASE
            WHEN mut.serial_number IS NOT NULL
            THEN
               1
            WHEN mut.serial_number IS NULL AND mtln.lot_number IS NOT NULL
            THEN
               mtln.transaction_quantity
            ELSE
               mmt.transaction_quantity
           END +
            -- transaction_quantity,
            --
            NVL(CASE
            WHEN mut2.serial_number IS NOT NULL
            THEN
               1
            WHEN mut2.serial_number IS NULL AND mtln2.lot_number IS NOT NULL
            THEN
               mtln2.transaction_quantity
            ELSE
               mmt2.transaction_quantity
           END,0) ) <> 0;


       cursor c_wo_comp_date(cp_item_id in number, cp_serial_number in varchar2) IS
        SELECT       
              mmt.transaction_date
         from mtl_unit_transactions mut, 
              mtl_material_transactions mmt,
              mtl_transaction_types mtt,
              wip_entities we,
              wip_discrete_jobs wdj,
              bom_bill_of_materials bbom 
        where mut.transaction_id = mmt.transaction_id
          and mmt.transaction_type_id = mtt.transaction_type_id
          and mut.serial_number = cp_serial_number
          and mmt.inventory_item_id = cp_item_id
          and we.wip_entity_id = wdj.wip_entity_id
          and mmt.organization_id = p_from_orgn_id
          and mmt.transaction_type_id = 44  -- WIP Completion
     --   and bbom.attribute1='Y'
          and wdj.status_type in ( 4, 12 )
     --   AND wdj.attribute5 IN (Select organization_code 
     --                             from org_organization_definitions where organization_id=l_to_orgn_id)
          and mmt.transaction_source_type_id = 5
          and we.wip_entity_id=mmt.transaction_source_id
          and we.primary_item_id=bbom.assembly_item_id
          and we.organization_id=bbom.organization_id;

       cursor c_xx_set_creation_date(cp_item_id in number, cp_serial_number in varchar2) IS
        SELECT max(created_date)
          from xxintg.xx_set_info xx
         where xx.inventory_item_id = cp_item_id
           and xx.serial = cp_serial_number
           and xx.status_interface = 'N'
           and xx.batch_id =
            ( select max(xxs.batch_id)
            from xxintg.xx_set_info xxs
           where xxs.set_serial=xx.set_serial
           and xxs.inventory_item_id = xx.inventory_item_id
           and nvl(xxs.status_interface,'N') = 'N'
         ) ;  -- To fetch the components     ;
           
       cursor c_xx_work_order(cp_item_id in number, cp_serial_number in varchar2) IS      
       SELECT xx.serial wip_entity_name,
             xx.inventory_item_id primary_item_id,
             null wip_entity_id,
             xx.serial serial_number,
             null lot_number,
             xx.serial lot_serial,
             xx.transaction_quantity,
             xx.created_date transaction_date,
             null subinventory_code,
             xx.transaction_unit_of_measure transaction_uom,
             null revision,
             null transfer_subinventory,
             null transaction_type_id,
             xx.transaction_id,
             'KIT Completion' transaction_type_name
        from xxintg.xx_set_info xx
       where serial=cp_serial_number
         and inventory_item_id = cp_item_id
         -- only take the lastest set of unprocessed records
         -- BXS 5/21/14
         and nvl(xx.status_interface,'N') = 'N'
         and xx.batch_id =
         ( select max(xxs.batch_id)
            from xxintg.xx_set_info xxs
           where xxs.set_serial=xx.set_serial
           and xxs.inventory_item_id = xx.inventory_item_id
           and nvl(xxs.status_interface,'N') = 'N'
         );


        CURSOR c_xx_work_order_components(cp_serial_number in varchar2, cp_parent_item_id number) IS
        SELECT xx.inventory_item_id,
               xx.serial serial_number,
             xx.lot lot_number,
             NVL (xx.serial, xx.lot) lot_serial,
             xx.transaction_quantity,
             xx.created_date transaction_date,
             null subinventory_code,
             xx.transaction_unit_of_measure transaction_uom,
             null revision,
             null transfer_subinventory,
             null transaction_type_id,
             xx.transaction_id,
             'KIT Issue' transaction_type_name
        from xxintg.xx_set_info xx
       where set_serial=cp_serial_number
         and inventory_item_id <> cp_parent_item_id
         -- only take the lastest set of unprocessed records
         -- BXS 5/21/14
         and nvl(xx.status_interface,'N') = 'N'
         and xx.batch_id =
         ( select max(xxs.batch_id)
            from xxintg.xx_set_info xxs
           where xxs.set_serial=xx.set_serial
           and xxs.inventory_item_id = xx.inventory_item_id
           and nvl(xxs.status_interface,'N') = 'N'
         ) ;  -- To fetch the components     

    r_shipments c_shipments%rowtype;
     
    procedure process_work_order(r_shipments c_shipments%rowtype) is
    begin
       
            FOR r_work_order IN c_work_order(r_shipments.inventory_item_id, r_shipments.serial_number) LOOP                            
            l_wo_comp_found := 'T' ;
         
                 FOR r_work_order_components in c_work_order_components(r_work_order.wip_entity_id) LOOP 
                     l_wo_issue_found := 'T' ;
                     
                        FND_FILE.PUT_LINE(fnd_file.LOG,
                            'Starting Work Order Loop to get components.'
                             );
                     
                 -- Put any Validations/select queries if required here
                     -- Deriving Expiration Date
                     IF r_work_order_components.lot_number is not null THEN
                         BEGIN
                              select expiration_date into v_lot_exp_date from  mtl_lot_numbers
                              where inventory_item_id = r_work_order_components.inventory_item_id
                              AND lot_number = r_work_order_components.lot_serial
                              AND organization_id = p_from_orgn_id;
                                   EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                        v_lot_exp_date := NULL;
                                      WHEN OTHERS THEN
                                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving v_lot_exp_date');
                                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is :'||sqlcode ||' : '||sqlerrm );
                                        v_lot_exp_date := NULL;
                                        RAISE e_validation_error;
                         END;
                     ELSE
                         
                         v_lot_exp_date := NULL;
                     
                     END IF;    

--                     -- Deriving TRANSACTION_TYPE_NAME
--                               BEGIN
--                                   select TRANSACTION_TYPE_NAME
--                                     into l_tran_type_name
--                                     from  mtl_transaction_types
--                                    where TRANSACTION_TYPE_ID = c1_work_order.TRANSACTION_TYPE_ID;
--                                    EXCEPTION
--                                       WHEN NO_DATA_FOUND THEN
--                                         l_tran_type_name := NULL;
--                                       WHEN OTHERS THEN
--                                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving l_tran_type_name');
--                                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is :'||sqlcode ||' : '||sqlerrm );
--                                         l_tran_type_name := NULL;
--                                         RAISE e_validation_error;
--                     END;

                   -- Inserting into staging table from cursor
                        
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Before insert in loop');
                        INSERT INTO INTG_SET_BKDN_STG(  transaction_id,
                                                            transaction_date,
                                                            oracle_trans_type,
                                                            party_initiating_tfr,
                                                            party_receiving_tfr,
                                                            work_order_number,
                                                            organization_id,
                                                            child_item,
                                                            parent_item,
                                                            lot_serial_number,
                                                            lot_number,
                                                            serial_number,
                                                            revision,
                                                            uom,
                                                            expiration_date ,
                                                            quantity,
                                                            date_transfer,
                                                            date_shipped,
                                                            inventory_type,
                                                            subinventory_code,
                                                            record_number,
                                                            status_flat_file,
                                                            message_flat_file,
                                                            status_interface,
                                                            message_interface,
                                                            ORIG_TRANSACTION_ID,
                                                            creation_date,
                                                            created_by,
                                                            last_update_date,
                                                            last_updated_by,
                                                            internal_order_number,
                                                            set_subinventory,
                                                            set_locator,
                                                            set_locator_id                                            
                                                            )
                                                     VALUES
                                                            (
                                                            INTG_SET_BKDN_TRANS_SEQ.NEXTVAL,        --transaction_id
                                                            TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'),    --transaction_date -- change to sysdate
                                                            r_work_order_components.transaction_type_name,                      --oracle_trans_type
                                                            '-1',                        --party_initiating_tfr
                                                            v_org_code,          --party_receiving_tfr (Changed on 07/06/10)
                                                            r_work_order.wip_entity_name,            --work_order_number
                                                            p_to_orgn_id,                            -- organization_id
                                                            r_work_order_components.inventory_item_id,        --child_item
                                                            r_work_order.primary_item_id,            --parent_item
                                                            r_work_order_components.lot_serial,            --lot_serial_number
                                                            r_work_order_components.lot_number,            --lot_number
                                                            r_work_order_components.serial_number,            --serial_number
                                                            r_work_order_components.revision,
                                                            r_work_order_components.transaction_uom,
                                                            v_lot_exp_date,                    --expiration_date
                                                            abs(r_work_order_components.transaction_quantity),    --quantity
                                                            SYSDATE,    --date_transfer
                                                            r_shipments.transaction_date,            --date_shipped
                                                            'LOANER',                    --inventory_type
                                                            r_work_order_components.subinventory_code,        -- subinventory_code
                                                            INTG_SET_BKDN_REC_SEQ.NEXTVAL,
                                                            NULL,                        --status_flat_file
                                                            NULL,                        --message_flat_file
                                                            NULL,                        --status_interface
                                                            NULL,                        --message_interface
                                                            r_work_order_components.transaction_id,
                                                            SYSDATE,    --creation_date
                                                            FND_GLOBAL.user_id, -- created_by
                                                            SYSDATE,    --last_update_date
                                                            FND_GLOBAL.user_id, -- last_updated_by
                                                            r_shipments.internal_order_number,
                                                            r_shipments.set_subinventory_code,
                                                            r_shipments.loc_segment1||'.'||r_shipments.loc_segment2||'.'||r_shipments.loc_segment3,
                                                            l_set_locator_id                                            
                                                            );
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert into INTG_SET_BKDN_STG for work order component: ' || r_work_order_components.transaction_id || ': ' ||
                                                                r_work_order_components.lot_serial             );
                       lv_count := lv_count + 1;
                       
                       apps.fnd_file.put_line (
                          fnd_file.LOG, 'In lv_count loop: ' || lv_count );

            --       UPDATE inv.mtl_material_transactions
            --       SET      attribute2     = l_proc_date
            --       WHERE    transaction_id = c1_work_order.transaction_id;
            --NH       COMMIT;
   
            
        END LOOP;
         
         
            if  l_wo_comp_found = 'T' then
         
               
                        -- Inserting WIP Completion Row
                        INSERT INTO INTG_SET_BKDN_STG(  transaction_id,
                                                            transaction_date,
                                                            oracle_trans_type,
                                                            party_initiating_tfr,
                                                            party_receiving_tfr,
                                                            work_order_number,
                                                            organization_id,
                                                            child_item,
                                                            parent_item,
                                                            lot_serial_number,
                                                            lot_number,
                                                            serial_number,
                                                            revision,
                                                            uom,
                                                            expiration_date ,
                                                            quantity,
                                                            date_transfer,
                                                            date_shipped,
                                                            inventory_type,
                                                            subinventory_code,
                                                            record_number,
                                                            status_flat_file,
                                                            message_flat_file,
                                                            status_interface,
                                                            message_interface,
                                                            ORIG_TRANSACTION_ID,
                                                            creation_date,
                                                            created_by,
                                                            last_update_date,
                                                            last_updated_by,
                                                            internal_order_number,
                                                            set_subinventory,
                                                            set_locator,
                                                            set_locator_id                                            
                                                            )
                                                     VALUES
                                                            (
                                                            INTG_SET_BKDN_TRANS_SEQ.NEXTVAL,        --transaction_id
                                                            TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'),    --transaction_date
                                                            r_work_order.transaction_type_name,                      --oracle_trans_type
                                                            '-1',                        --party_initiating_tfr
                                                            v_org_code,          --party_receiving_tfr (Changed on 07/06/10)
                                                            r_work_order.wip_entity_name,            --work_order_number
                                                            p_to_orgn_id,                            -- organization_id
                                                            r_work_order.primary_item_id,        --child_item
                                                            r_work_order.primary_item_id,            --parent_item
                                                            r_work_order.lot_serial,            --lot_serial_number
                                                            r_work_order.lot_number,            --lot_number
                                                            r_work_order.serial_number,            --serial_number
                                                            r_work_order.revision,
                                                            r_work_order.transaction_uom,
                                                            null,                    --expiration_date
                                                            abs(r_work_order.transaction_quantity),    --quantity
                                                            SYSDATE,    --date_transfer
                                                            r_shipments.transaction_date,            --date_shipped
                                                            'LOANER',                    --inventory_type
                                                            r_work_order.subinventory_code,        -- subinventory_code
                                                            INTG_SET_BKDN_REC_SEQ.NEXTVAL,
                                                            NULL,                        --status_flat_file
                                                            NULL,                        --message_flat_file
                                                            NULL,                        --status_interface
                                                            NULL,                        --message_interface
                                                            r_work_order.transaction_id,
                                                            SYSDATE,    --creation_date
                                                            FND_GLOBAL.user_id, -- created_by
                                                            SYSDATE,    --last_update_date
                                                            FND_GLOBAL.user_id, -- last_updated_by
                                                            r_shipments.internal_order_number,
                                                            r_shipments.set_subinventory_code,
                                                            r_shipments.loc_segment1||'.'||r_shipments.loc_segment2||'.'||r_shipments.loc_segment3,
                                                            l_set_locator_id                                            
                                                            );
                       lv_count := lv_count + 1;
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name );
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name );
              else
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Not Inserting into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name||' because component issues not found' );
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Not Inserting into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name||' because component issues not found' );
              end if;  
         
       END LOOP;
       
   end;     
      
      
   procedure process_xx_set(r_shipments c_shipments%rowtype) is
    begin
       
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Before c_xx_work_order loop:'||r_shipments.inventory_item_id ||'-'|| r_shipments.serial_number);
            FOR r_work_order IN c_xx_work_order(r_shipments.inventory_item_id, r_shipments.serial_number) LOOP                            
            l_wo_comp_found := 'T' ;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'In c_xx_work_order loop:'||r_work_order.serial_number);
                 FOR r_work_order_components in c_xx_work_order_components(r_work_order.serial_number, r_work_order.primary_item_id) LOOP 
                     l_wo_issue_found := 'T' ;
                     
                        FND_FILE.PUT_LINE(fnd_file.LOG,
                            'Starting XX Set Loop to get components.'
                             );
                     
                 -- Put any Validations/select queries if required here
                     -- Deriving Expiration Date
                     IF r_work_order_components.lot_number is not null THEN
                         BEGIN
                              select expiration_date into v_lot_exp_date from  mtl_lot_numbers
                              where inventory_item_id = r_work_order_components.inventory_item_id
                              AND lot_number = r_work_order_components.lot_serial
                              AND organization_id = p_from_orgn_id;
                                   EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                        v_lot_exp_date := NULL;
                                      WHEN OTHERS THEN
                                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving v_lot_exp_date');
                                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is :'||sqlcode ||' : '||sqlerrm );
                                        v_lot_exp_date := NULL;
                                        RAISE e_validation_error;
                         END;
                     ELSE
                         
                         v_lot_exp_date := NULL;
                     
                     END IF;    

--                     -- Deriving TRANSACTION_TYPE_NAME
--                               BEGIN
--                                   select TRANSACTION_TYPE_NAME
--                                     into l_tran_type_name
--                                     from  mtl_transaction_types
--                                    where TRANSACTION_TYPE_ID = c1_work_order.TRANSACTION_TYPE_ID;
--                                    EXCEPTION
--                                       WHEN NO_DATA_FOUND THEN
--                                         l_tran_type_name := NULL;
--                                       WHEN OTHERS THEN
--                                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving l_tran_type_name');
--                                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is :'||sqlcode ||' : '||sqlerrm );
--                                         l_tran_type_name := NULL;
--                                         RAISE e_validation_error;
--                     END;

                   -- Inserting into staging table from cursor
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Before insert in loop');
                        INSERT INTO INTG_SET_BKDN_STG(  transaction_id,
                                                            transaction_date,
                                                            oracle_trans_type,
                                                            party_initiating_tfr,
                                                            party_receiving_tfr,
                                                            work_order_number,
                                                            organization_id,
                                                            child_item,
                                                            parent_item,
                                                            lot_serial_number,
                                                            lot_number,
                                                            serial_number,
                                                            revision,
                                                            uom,
                                                            expiration_date ,
                                                            quantity,
                                                            date_transfer,
                                                            date_shipped,
                                                            inventory_type,
                                                            subinventory_code,
                                                            record_number,
                                                            status_flat_file,
                                                            message_flat_file,
                                                            status_interface,
                                                            message_interface,
                                                            ORIG_TRANSACTION_ID,
                                                            creation_date,
                                                            created_by,
                                                            last_update_date,
                                                            last_updated_by,
                                                            internal_order_number,
                                                            set_subinventory,
                                                            set_locator,
                                                            set_locator_id                                            
                                                            )
                                                     VALUES
                                                            (
                                                            INTG_SET_BKDN_TRANS_SEQ.NEXTVAL,        --transaction_id
                                                            TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'),    --transaction_date
                                                            r_work_order_components.transaction_type_name,                      --oracle_trans_type
                                                            '-1',                        --party_initiating_tfr
                                                            v_org_code,          --party_receiving_tfr (Changed on 07/06/10)
                                                            r_work_order.wip_entity_name,            --work_order_number
                                                            p_to_orgn_id,                            -- organization_id
                                                            r_work_order_components.inventory_item_id,        --child_item
                                                            r_work_order.primary_item_id,            --parent_item
                                                            r_work_order_components.lot_serial,            --lot_serial_number
                                                            r_work_order_components.lot_number,            --lot_number
                                                            r_work_order_components.serial_number,            --serial_number
                                                            r_work_order_components.revision,
                                                            r_work_order_components.transaction_uom,
                                                            v_lot_exp_date,                    --expiration_date
                                                            abs(r_work_order_components.transaction_quantity),    --quantity
                                                            SYSDATE,    --date_transfer
                                                            r_shipments.transaction_date,            --date_shipped
                                                            'LOANER',                    --inventory_type
                                                            r_work_order_components.subinventory_code,        -- subinventory_code
                                                            INTG_SET_BKDN_REC_SEQ.NEXTVAL,
                                                            'NOT APPLICABLE',                        --status_flat_file
                                                            'DATA GENERATED FROM XXSET NEED NOT BE EXPORTED',                        --message_flat_file
                                                            NULL,                        --status_interface
                                                            NULL,                        --message_interface
                                                            r_work_order_components.transaction_id,
                                                            SYSDATE,    --creation_date
                                                            FND_GLOBAL.user_id, -- created_by
                                                            SYSDATE,    --last_update_date
                                                            FND_GLOBAL.user_id, -- last_updated_by
                                                            r_shipments.internal_order_number,
                                                            r_shipments.set_subinventory_code,
                                                            r_shipments.loc_segment1||'.'||r_shipments.loc_segment2||'.'||r_shipments.loc_segment3,
                                                            l_set_locator_id                                            
                                                            );
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert into INTG_SET_BKDN_STG for work order component: ' || r_work_order_components.transaction_id || ': ' ||
                                                                r_work_order_components.lot_serial             );
                       lv_count := lv_count + 1;
                       
                       apps.fnd_file.put_line (
                          fnd_file.LOG, 'In lv_count loop: ' || lv_count );

            --       UPDATE inv.mtl_material_transactions
            --       SET      attribute2     = l_proc_date
            --       WHERE    transaction_id = c1_work_order.transaction_id;
            --NH       COMMIT;
            
             begin
              update xxintg.xx_set_info set status_interface = 'Y'
              where set_serial = r_work_order.wip_entity_name
              and inventory_item_id = r_work_order_components.inventory_item_id
              and nvl(lot,-1) =  nvl(r_work_order_components.lot_number,-1);   
         
            exception when no_data_found then
              FND_FILE.PUT_LINE(FND_FILE.LOG,' Could not update set info for the children: ' || r_work_order_components.inventory_item_id );
            end;
            
             END LOOP;
         
         
            if  l_wo_comp_found = 'T' then
         
               
                        -- Inserting WIP Completion Row
                        INSERT INTO INTG_SET_BKDN_STG(  transaction_id,
                                                            transaction_date,
                                                            oracle_trans_type,
                                                            party_initiating_tfr,
                                                            party_receiving_tfr,
                                                            work_order_number,
                                                            organization_id,
                                                            child_item,
                                                            parent_item,
                                                            lot_serial_number,
                                                            lot_number,
                                                            serial_number,
                                                            revision,
                                                            uom,
                                                            expiration_date ,
                                                            quantity,
                                                            date_transfer,
                                                            date_shipped,
                                                            inventory_type,
                                                            subinventory_code,
                                                            record_number,
                                                            status_flat_file,
                                                            message_flat_file,
                                                            status_interface,
                                                            message_interface,
                                                            ORIG_TRANSACTION_ID,
                                                            creation_date,
                                                            created_by,
                                                            last_update_date,
                                                            last_updated_by,
                                                            internal_order_number,
                                                            set_subinventory,
                                                            set_locator,
                                                            set_locator_id                                            
                                                            )
                                                     VALUES
                                                            (
                                                            INTG_SET_BKDN_TRANS_SEQ.NEXTVAL,        --transaction_id
                                                            TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'),    --transaction_date
                                                            r_work_order.transaction_type_name,                      --oracle_trans_type
                                                            '-1',                        --party_initiating_tfr
                                                            v_org_code,          --party_receiving_tfr (Changed on 07/06/10)
                                                            r_work_order.wip_entity_name,            --work_order_number
                                                            p_to_orgn_id,                            -- organization_id
                                                            r_work_order.primary_item_id,        --child_item
                                                            r_work_order.primary_item_id,            --parent_item
                                                            r_work_order.lot_serial,            --lot_serial_number
                                                            r_work_order.lot_number,            --lot_number
                                                            r_work_order.serial_number,            --serial_number
                                                            r_work_order.revision,
                                                            r_work_order.transaction_uom,
                                                            null,                    --expiration_date
                                                            abs(r_work_order.transaction_quantity),    --quantity
                                                            SYSDATE,    --date_transfer
                                                            r_shipments.transaction_date,            --date_shipped
                                                            'LOANER',                    --inventory_type
                                                            r_work_order.subinventory_code,        -- subinventory_code
                                                            INTG_SET_BKDN_REC_SEQ.NEXTVAL,
                                                            'NOT APPLICABLE',                        --status_flat_file
                                                            'DATA GENERATED FROM XXSET NEED NOT BE EXPORTED',                        --message_flat_file
                                                            NULL,                        --status_interface
                                                            NULL,                        --message_interface
                                                           r_work_order.transaction_id,
                                                            SYSDATE,    --creation_date
                                                            FND_GLOBAL.user_id, -- created_by
                                                            SYSDATE,    --last_update_date
                                                            FND_GLOBAL.user_id, -- last_updated_by
                                                            r_shipments.internal_order_number,
                                                            r_shipments.set_subinventory_code,
                                                            r_shipments.loc_segment1||'.'||r_shipments.loc_segment2||'.'||r_shipments.loc_segment3,
                                                            l_set_locator_id                                            
                                                            );
                       lv_count := lv_count + 1;
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name );
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name );
              else
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Not Inserting into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name||' because component issues not found' );
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Not Inserting into INTG_SET_BKDN_STG for work order number:' || r_work_order.wip_entity_name||' because component issues not found' );
              end if;   
              
              begin
                update xxintg.xx_set_info set status_interface = 'Y'
                  where serial = r_work_order.serial_number
                and inventory_item_id = r_work_order.primary_item_id;  
         
              exception when no_data_found then
                FND_FILE.PUT_LINE(FND_FILE.LOG,' Could not update set info for the parent: ' || r_work_order.primary_item_id );
              end;
         
       END LOOP;
       
       
   
   end;     


BEGIN
FND_FILE.PUT_LINE(FND_FILE.LOG,'Starting..');
                 apps.fnd_file.put_line (
                    fnd_file.LOG,
                    'p_from_orgn_id: ' || p_from_orgn_id
                 );
                 apps.fnd_file.put_line (
                    fnd_file.LOG,
                    'p_to_orgn_id: ' || p_to_orgn_id
                 );
                 apps.fnd_file.put_line (
                    fnd_file.LOG,
                    'p_to_subinv_code: ' || p_to_subinv_code
                 );
                 apps.fnd_file.put_line (
                    fnd_file.LOG,
                    'p_rec_acc_alias_name: ' || p_rec_acc_alias_name
                 );
                 apps.fnd_file.put_line (
                    fnd_file.LOG,
                    'p_rec_tran_type_name: ' || p_rec_tran_type_name
                 );
                 apps.fnd_file.put_line (
                    fnd_file.LOG,
                    'p_trans_date: '||p_trans_date
                 );
    -- Deleting existing data from table

--  DELETE FROM XXOM_SET_BKDN_STG;
--  COMMIT;

  BEGIN
  -- Get to organization code
   Select organization_code into v_to_orgn_code
     from org_organization_definitions where
          organization_id=l_to_orgn_id;
  EXCEPTION
       WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving v_org_code');
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is :'||sqlcode ||' : '||sqlerrm );
             v_to_orgn_code:= NULL;
             RAISE e_validation_error;
 END;

-- IF v_to_orgn_code = '150' THEN --
           -- Deriving Organization Code
         BEGIN
              SELECT organization_code into v_org_code FROM  org_organization_definitions
               WHERE organization_id = p_from_orgn_id;
         EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        v_org_code := NULL;
                      WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving v_org_code');
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is :'||sqlcode ||' : '||sqlerrm );
                        v_org_code := NULL;
                        RAISE e_validation_error;
         END;

  FOR r_shipments IN c_shipments LOOP
      BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'In Shipments Loop');
        open c_locator(r_shipments.loc_segment1, r_shipments.loc_segment2, r_shipments.loc_segment3);
        fetch c_locator into l_set_locator_id;
        IF c_locator%notfound THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving Locator:'||r_shipments.loc_segment1||'.'||r_shipments.loc_segment2||'.'||r_shipments.loc_segment3);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to derive locator');
           close c_locator;
           raise e_validation_error;
        END IF;
        close c_locator;    
        l_wo_comp_found  := 'F';
        l_wo_issue_found := 'F'; 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'1');
        
        r_wo_comp_date   := NULL; 
        r_xx_set_creation_date := NULL;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Oepning c_wo_comp_date');
        open c_wo_comp_date(r_shipments.inventory_item_id, r_shipments.serial_number);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Item ID:' || r_shipments.inventory_item_id); 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Serial Number:' || r_shipments.serial_number); 
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Oepning c_xx_set_creation_date'); 
        open c_xx_set_creation_date(r_shipments.inventory_item_id, r_shipments.serial_number);
        
        fetch c_wo_comp_date into r_wo_comp_date;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'After fetching c_wo_comp_date' || r_wo_comp_date);
        if c_wo_comp_date%notfound then
           r_wo_comp_date := null;
        end if;
        close c_wo_comp_date;

        fetch c_xx_set_creation_date into r_xx_set_creation_date;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'After fetching c_xx_set_creation_date' || r_xx_set_creation_date);
        if c_xx_set_creation_date%notfound then
           r_xx_set_creation_date := null;
        end if;
        close c_xx_set_creation_date;
         
        if r_xx_set_creation_date is not null and r_xx_set_creation_date > nvl(r_wo_comp_date, to_date('1/1/1900', 'mm/dd/yyyy')) then  
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Entering process_xx_set Loop');
             process_xx_set(r_shipments);
             
        else     
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Entering process_work_order Loop');
             process_work_order(r_shipments);

        end if;
               

        if  l_wo_comp_found = 'T' and l_wo_issue_found = 'T' then 
   

        -- Insert Shipment only when wip component and issue were found
                INSERT INTO INTG_SET_BKDN_STG(  transaction_id,
                                            transaction_date,
                                            oracle_trans_type,
                                            party_initiating_tfr,
                                            party_receiving_tfr,
                                            work_order_number,
                                            organization_id,
                                            child_item,
                                            parent_item,
                                            lot_serial_number,
                                            lot_number,
                                            serial_number,
                                            revision,
                                            uom,
                                            expiration_date ,
                                            quantity,
                                            date_transfer,
                                            date_shipped,
                                            inventory_type,
                                            subinventory_code,
                                            record_number,
                                            status_flat_file,
                                            message_flat_file,
                                            status_interface,
                                            message_interface,
                                            ORIG_TRANSACTION_ID,
                                            creation_date,
                                            created_by,
                                            last_update_date,
                                            last_updated_by,
                                            internal_order_number,
                                            set_subinventory,
                                            set_locator,
                                            set_locator_id                                            
                                            )
                                     VALUES
                                            (
                                            INTG_SET_BKDN_TRANS_SEQ.NEXTVAL,        --transaction_id
                                            TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'),    --transaction_date
                                            r_shipments.transaction_type_name,                      --oracle_trans_type
                                            '-1',                        --party_initiating_tfr
                                            v_org_code,          --party_receiving_tfr (Changed on 07/06/10)
                                            null, --r_work_order.wip_entity_name,            --work_order_number
                                            p_to_orgn_id,                            -- organization_id
                                            r_shipments.inventory_item_id,        --child_item
                                            r_shipments.inventory_item_id,            --parent_item
                                            r_shipments.serial_number,            --lot_serial_number
                                            null,            --lot_number
                                            r_shipments.serial_number,            --serial_number
                                            null,
                                            r_shipments.transaction_uom,
                                            null,                    --expiration_date
                                            abs(r_shipments.transaction_quantity),    --quantity
                                            SYSDATE,    --date_transfer
                                            r_shipments.transaction_date,            --date_shipped
                                            'LOANER',                    --inventory_type
                                            r_shipments.set_subinventory_code,        -- subinventory_code
                                            INTG_SET_BKDN_REC_SEQ.NEXTVAL,
                                            'NOT APPLICABLE',                        --status_flat_file
                                            'This transaction need not be sent',                        --message_flat_file
                                            'N',                        --status_interface
                                            NULL,                        --message_interface
                                            r_shipments.transaction_id,
                                            SYSDATE,    --creation_date
                                            FND_GLOBAL.user_id, -- created_by
                                            SYSDATE,    --last_update_date
                                            FND_GLOBAL.user_id, -- last_updated_by
                                            r_shipments.internal_order_number,
                                            r_shipments.set_subinventory_code,
                                            r_shipments.loc_segment1||'.'||r_shipments.loc_segment2||'.'||r_shipments.loc_segment3,
                                            l_set_locator_id                                            
                                            );
                                            
                                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert Shipment int INTG_SET_BKDN_STG for order number:' || r_shipments.internal_order_number );
                                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Insert Shipment int INTG_SET_BKDN_STG for order number:' || r_shipments.internal_order_number );

         else
                                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Not Inserting Shipment because work order not found' );
                                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Not Inserting Shipment because work order not found' );
                                           
         end if;
      EXCEPTION
      WHEN e_validation_error THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Validation Error, continuing with next record...' );         
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, sqlcode || 'Not Inserting Shipment because work order not found: ' || sqlerrm );
      END;                     
   END LOOP;   
-- END IF;

    l_proc_status:= 'P';

    -- Calling utl file procedure to generate flat file and place in ftp folder
    IF l_proc_status = 'P' THEN
       XXOM_SET_BKDN_PKG.INTG_SET_BKDN_EXP_PRC;
       XXOM_SET_BKDN_PKG.INTG_SET_BKDN_INS_PRC(l_from_orgn_id,
                l_to_orgn_id,
                l_to_subinv_code,
                sysdate,
                l_rec_acc_alias_name,
                l_rec_tran_type_name,
                l_set_subinv_code);
      fnd_file.put_line (fnd_file.LOG, 'l_proc_status: ' || l_proc_status);
    END IF;

EXCEPTION
WHEN OTHERS THEN
--nh ROLLBACK;
      fnd_file.put_line (fnd_file.LOG, 'Cannot create an Extract file. No Data loaded into Staging table' || SQLERRM);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot create an Extract file.No Data loaded into Staging table' || SQLERRM);
      
END INTG_SET_BKDN_EXT_PRC;

PROCEDURE INTG_SET_BKDN_INS_PRC(l_from_orgn_id        IN NUMBER,
                l_to_orgn_id        IN NUMBER,
                l_to_subinv_code    IN  VARCHAR2,
                l_trans_date        IN  DATE,
                l_rec_acc_alias_name    IN  VARCHAR2,
                l_rec_tran_type_name    IN  VARCHAR2,
                l_set_subinv_code    IN  VARCHAR2
)
   -------------------------------------------------------------------------------------------------------------|
   --|   This Procedure(INTG_SET_BKDN_INS_PRC ) will insert records into interface tables with data      |
   --|   fetched from INTG_SET_BKDN_EXT_PRC then process transaction interface has to run                |
   -------------------------------------------------------------------------------------------------------------|

   IS

      v_count                 NUMBER:=0;
      v_count1                 NUMBER:=0;
      l_err_msg               VARCHAR2 (6000) := null;
      v_inv_item_id           apps.mtl_system_items_b.inventory_item_id%TYPE;
      v_lot_control_code        NUMBER;
      v_sno_control_code        NUMBER;
      l_source_code             VARCHAR2 (30) := 'Field Inv App';
      v_trans_temp_id           NUMBER := 0;
      l_transaction_type_id    NUMBER := NULL;
      l_inventory_location_id    NUMBER := NULL;
      v_disp_id            NUMBER := NULL;
      l_mmt_subinv_code        VARCHAR2 (30) := NULL;
      v_locator_id         NUMBER;
      l_source_name        VARCHAR2(50);

      x_return_status   VARCHAR2(100);
      x_return_code     VARCHAR2(50);
      x_return_message  VARCHAR2(2000);
      v_lpn_id          NUMBER;
      l_auto_lpn_id          NUMBER;

      l_txn_header_id   NUMBER;
      l_txn_batch_id    NUMBER;


      txl_return_status varchar2(100);
      txl_msg_cnt number;
      txl_msg_data varchar2(2000);
      txl_trans_count number; 
      txl_return_val number;
      l_current_organization_id number;
      l_consignment_org_id NUMBER := 2103;

     CURSOR c_lpn(cp_lpn_number in varchar2) IS 
     select organization_id, subinventory_code, locator_id, lpn_context, lpn_id, license_plate_number
       from wms_license_plate_numbers where license_plate_number = cp_lpn_number;

      r_lpn c_lpn%rowtype;
      
      CURSOR C_TOP_ITEM IS
      SELECT DISTINCT sbs.serial_number, sbs.parent_item, sbs.work_order_number, sbs.set_subinventory, 
                      sbs.set_locator_id, sbs.transaction_date, sbs.uom, sbs.organization_id, msib.segment1 item_number
        FROM INTG_SET_BKDN_STG sbs, mtl_system_items_b msib
       WHERE sbs.status_interface IS NULL
         AND sbs.oracle_trans_type in ('WIP Completion', 'KIT Completion')
         AND msib.organization_id = sbs.organization_id
         AND msib.inventory_item_id = sbs.parent_item;
        
      CURSOR c1(cp_work_order_number in varchar2)
      IS
         SELECT     
            transaction_id        ,
            orig_transaction_id    ,
            transaction_date    ,
            oracle_trans_type        ,
            party_initiating_tfr     ,
            party_receiving_tfr      ,
            work_order_number        ,
            child_item               ,
            parent_item              ,
            lot_serial_number          ,
            lot_number          ,
            serial_number          ,
            revision        ,
            uom            ,
            expiration_date          ,
            quantity                ,
            date_transfer            ,
            date_shipped             ,
            inventory_type         ,
            subinventory_code,
            set_subinventory,
            set_locator_id
           FROM INTG_SET_BKDN_STG
           WHERE work_order_number = cp_work_order_number
             AND oracle_trans_type in ('WIP Issue', 'KIT Issue')
             AND status_interface is null           
           ORDER BY transaction_id;

   BEGIN
          apps.fnd_file.put_line (
               fnd_file.LOG,
               'In procedure1 INTG_SET_BKDN_INS_PRC: ' || l_from_orgn_id||l_to_orgn_id||l_to_subinv_code||l_rec_acc_alias_name||l_rec_tran_type_name||l_set_subinv_code
           );

   -- Selecting number of records eligible for import from staging

           BEGIN
               SELECT   count(*)
             INTO v_count
           FROM   INTG_SET_BKDN_STG
          WHERE status_interface is NULL
          AND oracle_trans_type = 'WIP component issue' ;
             EXCEPTION
              WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to fetch count from ITGR_ORA_SET_BKDN_STG:');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to fetch count from ITGR_ORA_SET_BKDN_STG: ' ||null);
         END;
             apps.fnd_file.put_line (fnd_file.LOG,
                                  'Number of Records fetched from staging to process: ' || v_count);
   
   FOR R_TOP_ITEM IN C_TOP_ITEM LOOP
   l_txn_header_id := mtl_material_transactions_s.nextval;

             open c_lpn(R_TOP_ITEM.SERIAL_NUMBER);
              apps.fnd_file.put_line (fnd_file.LOG,
                                  'Cursor opened for : ' || R_TOP_ITEM.SERIAL_NUMBER);
             fetch c_lpn into r_lpn;
             
              apps.fnd_file.put_line (fnd_file.LOG,
                                  'After fetch : ');

             if c_lpn%notfound then -- create lpm
                  v_lpn_id := XXINTG_CON_LPN_PKG.CREATE_LPN(R_TOP_ITEM.SERIAL_NUMBER,
                                                            -- r_top_item.item_number || '_' || r_top_item.serial_number, 
                                                            l_to_orgn_id, 
                                                            x_return_status,
                                                            x_return_code,
                                                            x_return_message);

                  apps.fnd_file.put_line (fnd_file.LOG,
                                  'Inside LPN not found');
                if nvl(v_lpn_id, -1)  < 0 then -- Error creating LPN 
                    -- close c_lpn;
                     v_lpn_id := null; -- confirm with Brian to see what should be done in this case
                      l_err_msg :=
                         l_err_msg || ' Unable to create  LPN that is not found '||R_TOP_ITEM.SERIAL_NUMBER||' '||x_return_message;
                         apps.fnd_file.put_line (fnd_file.output,
                      l_err_msg);
                end if;
                l_current_organization_id := l_to_orgn_id;
                apps.fnd_file.put_line (fnd_file.LOG,
                                  'Current Org ID : ' || l_current_organization_id);
             else -- LPN Exists Need to check additional columns to see if lpn is in valid status and resides in proper subinventory
             apps.fnd_file.put_line (fnd_file.LOG,
                                  'LPN Exists : ' || r_lpn.lpn_id);
              v_lpn_id := r_lpn.lpn_id; 
              l_current_organization_id := r_lpn.organization_id;
              apps.fnd_file.put_line (fnd_file.LOG,
                                  'Current Org ID : ' || l_current_organization_id);
              apps.fnd_file.put_line (fnd_file.LOG,
                                  'Consignment Org ID : ' || l_consignment_org_id);
			
              --close c_lpn;                           

              -- BXS -- IF the current organization is not the consignment organization, do not explode the kit
              IF l_current_organization_id <> l_consignment_org_id THEN
                 apps.fnd_file.put_line ( fnd_file.LOG,
                                  'LPN is not in the consignment org: ' || l_current_organization_id );
                 -- goto endoftopitem;  -- don't do anything right now.  I want these transactions
              ELSE
              -- LPN is in the consignment org, but need to see if the lpn is empty
              -- if not, we need to unpack it with a new transaction type
                 NULL;
              END IF;
                            
              -- BXS -- If the lpn is not empty then we need to unpack the contents and transfer to 
              --        KITCLEANUP (or leave them with the current sub)

           end if;
       close c_lpn; 
       

      /******* Vishy P commented 19-feb-2014
      FND_FILE.PUT_LINE(FND_FILE.LOG,'x_return_status:'||x_return_status||' v_lpn_id:'||v_lpn_id );
      if x_return_status <> 'S' or nvl(v_lpn_id, -1) < 0 then   
                    -- see if we can find the lpn that already exists
                    begin
                    select lpn_id
                    into v_lpn_id
                    from wms_license_plate_numbers
                    where license_plate_number = R_TOP_ITEM.SERIAL_NUMBER;
                    exception
                    when others THEN
                      l_err_msg :=
                         l_err_msg || ' Unable to find existing LPN '||R_TOP_ITEM.SERIAL_NUMBER||' '||x_return_message;
                         apps.fnd_file.put_line (fnd_file.output,
                      l_err_msg);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,l_err_msg);
                    end;

                    l_err_msg :=
                    l_err_msg || ' Unable to create LPN '||R_TOP_ITEM.SERIAL_NUMBER||' '||x_return_message;
                       apps.fnd_file.put_line (fnd_file.output,
                   l_err_msg);
                   FND_FILE.PUT_LINE(FND_FILE.LOG,l_err_msg);
                   -- goto endoftopitem; -- do nothing for now.  this is a rerun
                   
      end if;      
      
      ******/
   
      l_txn_batch_id := mtl_material_transactions_s.nextval;
      FOR c1_rec in c1(R_TOP_ITEM.WORK_ORDER_NUMBER) LOOP
      
      
       apps.fnd_file.put_line (fnd_file.LOG,
                                  'Inside c1_rec' || R_TOP_ITEM.WORK_ORDER_NUMBER);

            BEGIN
                 SELECT   lot_control_code,
                          serial_number_control_code
                   INTO   v_lot_control_code,
                                 v_sno_control_code
                   FROM        apps.mtl_system_items_b
                  WHERE       inventory_item_status_code <> 'Inactive'
                    AND     inventory_item_id = c1_rec.child_item
                    AND     organization_id = l_to_orgn_id; -- Check
           EXCEPTION
               WHEN OTHERS
               THEN
                            l_err_msg :=
                            l_err_msg || ' Item Not Present for p_to_orgn_id '||l_to_orgn_id;
                               apps.fnd_file.put_line (fnd_file.output,
                           'Item '||c1_rec.child_item||' Not Present for Org: ' || l_to_orgn_id);
                           FND_FILE.PUT_LINE(FND_FILE.LOG,l_err_msg);

           END;

             -- Fetching Transaction Interface ID from Sequence
              BEGIN
                 SELECT   apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL
                   INTO   v_trans_temp_id
                   FROM   DUAL;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    l_err_msg :=
                       l_err_msg
                       || 'MTL_MATERIAL_TRANSACTIONS_S sequence errored out';
                       FND_FILE.PUT_LINE(FND_FILE.LOG,l_err_msg);
              END;


              BEGIN
                SELECT   transaction_type_id
                  INTO   l_transaction_type_id
                  FROM   mtl_transaction_types
                 WHERE   transaction_type_name = 'Account alias receipt'; -- l_rec_tran_type_name;
              EXCEPTION
                 WHEN OTHERS THEN
                      l_err_msg :=
                      l_err_msg || ' Unable to fetch Transaction Type ID ';
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to fetch l_transaction_type_id:');
                      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unable to fetch Transaction Type ID for: ' ||l_rec_tran_type_name);
              END;

         -- Selecting distribution account

              BEGIN
                SELECT disposition_id -- distribution_account
                  INTO   v_disp_id
                  FROM   mtl_generic_dispositions
                 WHERE   organization_id = l_to_orgn_id
                   AND   SEGMENT1 = l_rec_acc_alias_name;
              EXCEPTION
                 WHEN OTHERS THEN
                      l_err_msg :=
                      l_err_msg || ' Unable to fetch distribution account id ';
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to fetch v_disp_id:');
                      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unable to fetch  distribution account details for : ' ||l_rec_acc_alias_name);
              END;
              
              BEGIN
                SELECT transaction_type_name
                  INTO   l_source_name
                  FROM   mtl_transaction_types
                 WHERE   transaction_type_id =  41; -- SEGMENT1 = l_rec_acc_alias_name;
              EXCEPTION
                 WHEN OTHERS THEN
                      l_err_msg :=
                      l_err_msg || ' Unable to fetch transaction_type_id account id ';
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'unable to fetch v_disp_id:');
                      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'unable to fetch  distribution account details for : ' ||l_rec_acc_alias_name);
              END;


              IF l_err_msg IS NOT NULL
                  THEN
                     UPDATE   INTG_SET_BKDN_STG
                        SET   message_interface = l_err_msg,
                              status_interface = 'ERROR'
                      WHERE   transaction_id = c1_rec.transaction_id;
              END IF;
              apps.fnd_file.put_line (fnd_file.LOG,
                                  'Before checking l_err_msg');
             -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Before checking l_err_msg');
              --IF l_err_msg IS NULL
              --THEN
                -- FND_FILE.PUT_LINE(FND_FILE.LOG,'v_lot_control_code = '||v_lot_control_code ||' v_sno_control_code = '||v_sno_control_code);
               
                apps.fnd_file.put_line (fnd_file.LOG,
                                  'v_lot_control_code = '||v_lot_control_code ||' v_sno_control_code = '||v_sno_control_code);
               
                 IF v_lot_control_code = 2 AND v_sno_control_code = 1
                 THEN

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Bef Insert to MTL transaction inter1  ');
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Bef Insert to MTL transaction inter1  ');
                     BEGIN

                          INSERT INTO apps.mtl_transactions_interface (
                                                             source_code,
                                                             source_line_id,
                                                             source_header_id,
                                                             process_flag,
                                                             transaction_mode,
                                                             validation_required,
                                                             last_update_date,
                                                             last_updated_by,
                                                             creation_date,
                                                             created_by,
                                                             organization_id,
                                                             transaction_quantity,
                                                             transaction_uom,
                                                             transaction_date,
                                                             transaction_source_name, -- dsp_segment1,
                                                             transaction_type_id,
                                                             inventory_item_id,
                                                             subinventory_code,
                                                             revision,
                                                             transaction_interface_id,
                                                             -- distribution_account_id,
                                                             transaction_source_id,
                                                             transaction_reference,
                                                             locator_id,
                                                             transfer_organization,
                                                             transfer_subinventory,
                                                             scheduled_flag,
                                                             flow_schedule,
                                                             transfer_lpn_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                         )
                                VALUES   (
                                      l_source_code,
                                          1,
                                          1,
                                          1,
                                          3,
                                          1,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          l_to_orgn_id, -- Check
                                          abs(c1_rec.quantity),
                                          c1_rec.uom,
                                          sysdate, --to_date(c1_rec.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          l_rec_acc_alias_name,
                                          l_transaction_type_id,--Direct Org Transfer Type Id is 3
                                          c1_rec.child_item,
                                          c1_rec.set_subinventory,
                                          c1_rec.revision,
                                          v_trans_temp_id,
                                          v_disp_id,
                                          'TRA_REF',
                                          c1_rec.set_locator_id,
                                          null,
                                          null,
                                          null,
                                          '2',
                                          v_lpn_id,
                                          l_txn_batch_id,
                                          1, --Sequence
                                          l_txn_header_id
                                          );



                     EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transactions_interface-1 '
                                 || SQLERRM
                             );
                     END;

                     BEGIN
                            INSERT INTO apps.mtl_transaction_lots_interface (
                                                                        transaction_interface_id,
                                                                        source_code,
                                                                        source_line_id,
                                                                        lot_number,
                                                                        lot_expiration_date,
                                                                        transaction_quantity,
                                                                        last_update_date,
                                                                        last_updated_by,
                                                                        creation_date,
                                                                        created_by
                                                                        )
                             VALUES   (
                              v_trans_temp_id,     --transaction interface_id
                                l_source_code,          --source code
                                1,                    --source line id
                                c1_rec.lot_number,      -- lot number
                                c1_rec.expiration_date,
                                abs(c1_rec.quantity),
                                SYSDATE,
                                FND_GLOBAL.USER_ID,
                                SYSDATE,
                                FND_GLOBAL.USER_ID);

                              v_count1 := v_count1+1;
                     EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transaction_lots_interface '
                                 || SQLERRM
                             );
                     END;
                ELSIF v_lot_control_code = 1 AND v_sno_control_code <> 1
                 THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Bef Insert to MTL and SER-->  ' || c1_rec.serial_number);
                     
                     /*** Update the status and organization since the serial has been issued out of stores in source org ****/
                      apps.fnd_file.put_line (fnd_file.LOG,
                            'Before update serial number to set the status ' || c1_rec.serial_number ||' source Org: ' ||  l_from_orgn_id || 
                            ' to org: ' ||  l_to_orgn_id || ' Item: ' || c1_rec.child_item
                             );
                     Begin
                      update  apps.mtl_serial_numbers set current_status = 1, current_organization_id = l_to_orgn_id,
                        current_subinventory_code = null, current_locator_id = null 
                        where inventory_item_id = c1_rec.child_item and serial_number = c1_rec.serial_number
                        and current_status = 4 and current_organization_id = l_from_orgn_id;
                        
                      exception when no_data_found then
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Cannot find serial number to set the status ' || c1_rec.serial_number || ' source Org: ' ||  l_from_orgn_id || 
                            ' to org: ' ||  l_to_orgn_id || 'Item: ' || c1_rec.child_item
                             );
                     end;
                     
                     /*** End update ***/
                     
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Bef Insert to MTL transaction inte:2  ');
                     BEGIN
                          INSERT INTO apps.mtl_transactions_interface (
                                                             source_code,
                                                             source_line_id,
                                                             source_header_id,
                                                             process_flag,
                                                             transaction_mode,
                                                             validation_required,
                                                             last_update_date,
                                                             last_updated_by,
                                                             creation_date,
                                                             created_by,
                                                             organization_id,
                                                             transaction_quantity,
                                                             transaction_uom,
                                                             transaction_date,
                                                             transaction_source_name, -- dsp_segment1,
                                                             transaction_type_id,
                                                             inventory_item_id,
                                                             subinventory_code,
                                                             revision,
                                                             transaction_interface_id,
                                                             -- distribution_account_id,
                                                             transaction_source_id,
                                                             transaction_reference,
                                                             locator_id,
                                                             transfer_organization,
                                                             transfer_subinventory,
                                                             scheduled_flag,
                                                             flow_schedule,
                                                             transfer_lpn_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                                             )
                                VALUES   (
                                      l_source_code,
                                          1,
                                          1,
                                          1,
                                          3,
                                          1,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          l_to_orgn_id, -- Check
                                          abs(c1_rec.quantity),
                                          c1_rec.uom,
                                          sysdate, --to_date(c1_rec.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          l_rec_acc_alias_name,
                                          l_transaction_type_id,--Direct Org Transfer Type Id is 3
                                          c1_rec.child_item,
                                          c1_rec.set_subinventory,
                                          c1_rec.revision,
                                          v_trans_temp_id,
                                          v_disp_id,
                                          'TRA_REF',
                                          c1_rec.set_locator_id,
                                          null,
                                          null,
                                          null,
                                          '2',
                                          v_lpn_id,
                                          l_txn_batch_id,
                                          1, --Sequence
                                          l_txn_header_id
                                          );

        --                insert into test123 values('mtl-ser');
                        EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transaction_interface2 '
                                 || SQLERRM
                             );
                        END;
                  
                        BEGIN
                          INSERT INTO apps.mtl_serial_numbers_interface (
                                                                      transaction_interface_id,
                                                                      source_code,
                                                                      fm_serial_number,
                                                                      to_serial_number,
                                                                      last_update_date,
                                                                      last_updated_by,
                                                                      creation_date,
                                                                      created_by
                                                                        )
                         VALUES   (v_trans_temp_id,
                                   l_source_code,
                                   c1_rec.serial_number,
                                   c1_rec.serial_number,
                                   SYSDATE,
                                   FND_GLOBAL.USER_ID,
                                   SYSDATE,
                                   FND_GLOBAL.USER_ID);
                           v_count1 := v_count1+1;
                        EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transaction_serial_interface '
                                 || SQLERRM
                             );
                        END;

                ELSIF v_lot_control_code = 1 AND v_sno_control_code = 1 THEN
                        BEGIN
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Bef Insert to MTL transaction inter3  ');
                                                  apps.fnd_file.put_line (
                                                                 fnd_file.LOG,' Bef Insert to MTL transaction inter3');
                                                 apps.fnd_file.put_line (
                                                                 fnd_file.LOG,' Bef Insert to MTL transaction inter3'              
                                                                 ||R_TOP_ITEM.WORK_ORDER_NUMBER);
                                                                 
                                                                  apps.fnd_file.put_line (
                                                                 fnd_file.LOG,' Bef Insert to MTL transaction inter3'              
                                                                 || c1_rec.child_item);
                            
                          INSERT INTO apps.mtl_transactions_interface (
                                                             source_code,
                                                             source_line_id,
                                                             source_header_id,
                                                             process_flag,
                                                             transaction_mode,
                                                             validation_required,
                                                             last_update_date,
                                                             last_updated_by,
                                                             creation_date,
                                                             created_by,
                                                             organization_id,
                                                             transaction_quantity,
                                                             transaction_uom,
                                                             transaction_date,
                                                             transaction_source_name, -- dsp_segment1,
                                                             transaction_type_id,
                                                             inventory_item_id,
                                                             subinventory_code,
                                                             revision,
                                                             transaction_interface_id,
                                                             -- distribution_account_id,
                                                             transaction_source_id,
                                                             transaction_reference,
                                                             locator_id,
                                                             transfer_organization,
                                                             transfer_subinventory,
                                                             scheduled_flag,
                                                             flow_schedule,
                                                             transfer_lpn_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                         )
                                VALUES   (
                                      l_source_code,
                                          1,
                                          1,
                                          1,
                                          3,
                                          1,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          l_to_orgn_id, -- Check
                                          abs(c1_rec.quantity),
                                          c1_rec.uom,
                                          sysdate, --to_date(c1_rec.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          l_rec_acc_alias_name,
                                          l_transaction_type_id,-- 41 
                                          c1_rec.child_item,
                                          c1_rec.set_subinventory,
                                          c1_rec.revision,
                                          v_trans_temp_id,
                                          v_disp_id,
                                          'TRA_REF',
                                          c1_rec.set_locator_id,
                                          null,
                                          null,
                                          null,
                                          '2',
                                          v_lpn_id,
                                          l_txn_batch_id,
                                          1, --Sequence
                                          l_txn_header_id);


                             v_count1 := v_count1+1;
                        EXCEPTION
                           WHEN OTHERS THEN
                            apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transaction_interface3 '
                                 || SQLERRM
                             );
                             FND_FILE.PUT_LINE(FND_FILE.LOG,'Unable to insert into mtl_transaction_interface3 ' || SQLERRM);
                        END;
              
                 END IF;

                  fnd_file.put_line (fnd_file.OUTPUT, 'Transaction IDs: ' || c1_rec.transaction_id|| ': ' || c1_rec.orig_transaction_id||': ' ||v_trans_temp_id);

            --  END IF;

              UPDATE   INTG_SET_BKDN_STG
                 SET   status_interface = 'Y',
                       message_interface = 'Processed'
               WHERE   transaction_id = c1_rec.transaction_id;


              v_inv_item_id := NULL;
              v_count := NULL;
              l_err_msg := NULL;


            END LOOP;
            
            
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Serial Number: ' || R_TOP_ITEM.serial_number || ' Parent_Item: ' ||R_TOP_ITEM.parent_item|| 
                ' orgid: ' || l_current_organization_id);
            
            --  Insert top item to pack
            --  BXS split the newly created LPN from the WMS generated LPN
          begin
            -- get the current lpn_id
            select lpn_id
            into   l_auto_lpn_id
            from   mtl_serial_numbers msn
            where msn.serial_number = R_TOP_ITEM.serial_number and inventory_item_id = R_TOP_ITEM.parent_item 
          --  and child_item = parent_item_id
            and current_organization_id = R_TOP_ITEM.organization_id;
          exception
            when no_data_found then
              apps.fnd_file.put_line (fnd_file.LOG,
                                  'Cannot find LPN for the serial to split : ' || R_TOP_ITEM.serial_number || ': ' || R_TOP_ITEM.parent_item);
            end;
            

            
                     BEGIN
                   fnd_file.put_line (fnd_file.log, 'Top Level Item Split Old LPN: ' || l_auto_lpn_id );
                   fnd_file.put_line (fnd_file.log, 'Top Level Item Split Old LPN: ' || v_lpn_id );
                          INSERT INTO apps.mtl_transactions_interface (
                                                             source_code,
                                                             source_line_id,
                                                             source_header_id,
                                                             process_flag,
                                                             transaction_mode,
                                                             validation_required,
                                                             last_update_date,
                                                             last_updated_by,
                                                             creation_date,
                                                             created_by,
                                                             organization_id,
                                                             transaction_quantity,
                                                             transaction_uom,
                                                             transaction_date,
                                                             dsp_segment1,
                                                             transaction_type_id,
                                                             inventory_item_id,
                                                             subinventory_code,
                                                             transaction_interface_id,
                                                             transaction_reference,
                                                             locator_id,
                                                             lpn_id,
                                                             transfer_lpn_id, -- new LPN id
                                                             transaction_source_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                                             )
                                VALUES   (
                                          l_source_code,
                                          1,
                                          1,
                                          1,
                                          3,
                                          1,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          l_to_orgn_id, -- Check
                                          1,
                                          R_TOP_ITEM.uom,
                                          sysdate, --to_date(R_TOP_ITEM.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          null, -- l_source_name, -- l_rec_acc_alias_name,
                                          89, -- 52, -- c_container_split,
                                          R_TOP_ITEM.parent_item,
                                          R_TOP_ITEM.set_subinventory,
                                          mtl_material_transactions_s.nextval,
                                          'TRA_REF',
                                          R_TOP_ITEM.set_locator_id,
                                          l_auto_lpn_id,
                                          v_lpn_id,
                                          13,
                                          l_txn_batch_id,
                                          2, --Sequence
                                          l_txn_header_id
                                          );

        --                insert into test123 values('mtl-ser');
                        EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transaction_interface2 '
                                 || SQLERRM
                             );
                        END;
                     /*
                          INSERT INTO apps.mtl_transactions_interface (
                                                             source_code,
                                                             source_line_id,
                                                             source_header_id,
                                                             process_flag,
                                                             transaction_mode,
                                                             validation_required,
                                                             last_update_date,
                                                             last_updated_by,
                                                             creation_date,
                                                             created_by,
                                                             organization_id,
                                                             transaction_quantity,
                                                             transaction_uom,
                                                             transaction_date,
                                                             dsp_segment1,
                                                             transaction_type_id,
                                                             inventory_item_id,
                                                             subinventory_code,
                                                             transaction_interface_id,
                                                             transaction_reference,
                                                             locator_id,
                                                             transfer_lpn_id,
                                                             transaction_source_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                                             )
                                VALUES   (
                                          l_source_code,
                                          1,
                                          1,
                                          1,
                                          3,
                                          1,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          SYSDATE,
                                          FND_GLOBAL.USER_ID,
                                          l_to_orgn_id, -- Check
                                          1,
                                          R_TOP_ITEM.uom,
                                          to_date(R_TOP_ITEM.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          null, -- l_source_name, -- l_rec_acc_alias_name,
                                          87,--Pack; 
                                          R_TOP_ITEM.parent_item,
                                          R_TOP_ITEM.set_subinventory,
                                          mtl_material_transactions_s.nextval,
                                          'TRA_REF',
                                          R_TOP_ITEM.set_locator_id,
                                          v_lpn_id,
                                          13,
                                          l_txn_batch_id,
                                          2, --Sequence
                                          l_txn_header_id
                                          );

        --                insert into test123 values('mtl-ser');
                        EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transaction_interface2 '
                                 || SQLERRM
                             );
                        END;
                  */
                        BEGIN
                          INSERT INTO apps.mtl_serial_numbers_interface (
                                                                      transaction_interface_id,
                                                                      source_code,
                                                                      fm_serial_number,
                                                                      to_serial_number,
                                                                      last_update_date,
                                                                      last_updated_by,
                                                                      creation_date,
                                                                      created_by
                                                                        )
                         VALUES   (mtl_material_transactions_s.currval,
                                   l_source_code,
                                   R_TOP_ITEM.serial_number,
                                   R_TOP_ITEM.serial_number,
                                   SYSDATE,
                                   FND_GLOBAL.USER_ID,
                                   SYSDATE,
                                   FND_GLOBAL.USER_ID);

                           v_count1 := v_count1+1;
                        EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (
                            fnd_file.LOG,
                            'Unable to insert into mtl_transaction_serial_interface '
                                 || SQLERRM
                             );
                        END;
                        
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Serial Number: ' || R_TOP_ITEM.serial_number || ' Parent_Item: ' ||R_TOP_ITEM.parent_item ||
                ' work_order_number: ' || r_top_item.work_order_number);
            
              UPDATE   INTG_SET_BKDN_STG
                 SET   status_interface = 'Y',
                       message_interface = 'Processed'
               WHERE   work_order_number = r_top_item.work_order_number
                    and child_item = r_top_item.parent_item
                    and child_item = parent_item 
                    and serial_number = r_top_item.serial_number;
               


       txl_return_val := 
       INV_TXN_MANAGER_PUB.process_transactions(
       p_api_version => 1.0
      ,p_init_msg_list => fnd_api.g_true
      ,p_commit => fnd_api.g_true
      ,p_validation_level => fnd_api.g_valid_level_full
      ,x_return_status => txl_return_status
      ,x_msg_count => txl_msg_cnt
      ,x_msg_data => txl_msg_data
      ,x_trans_count => txl_trans_count
      ,p_table => 1 -- mti
      ,p_header_id => l_txn_header_id
       );             

            <<endoftopitem>> -- in case of lpn creation failure, program will jump to this location to pickup next serial number            
             NULL;
             
   END LOOP; --PARENT ITEM     

            fnd_file.put_line (fnd_file.OUTPUT, 'No. of Records Inserted into Interface tables: ' || v_count1);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No. of Records Inserted into Interface tables: ' || v_count1);

       COMMIT;

       fnd_file.put_line (fnd_file.OUTPUT, 'Submitting transaction for transaction header id: ' || l_txn_header_id);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting transaction for transaction header id: ' || l_txn_header_id);


       if txl_return_val <> 0 then 
          fnd_file.put_line (fnd_file.OUTPUT, 'Return Error Status from INV_TXN_MANAGER_PUB: ' || txl_return_status||'-'||txl_msg_data);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Return Status from INV_TXN_MANAGER_PUB: ' || txl_return_status||'-'||txl_msg_data);
       else

          fnd_file.put_line (fnd_file.OUTPUT, 'Return Success Status from INV_TXN_MANAGER_PUB: ' || txl_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Return Status from INV_TXN_MANAGER_PUB: ' || txl_return_status);
       end if;
       
       COMMIT;
       
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Log_msg: ' || SQLERRM);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Log_msg: ' || SQLERRM);
         v_count1:=null;
   END INTG_SET_BKDN_INS_PRC;


 PROCEDURE INTG_SET_BKDN_EXP_PRC
   -------------------------------------------------------------------------------------------------------------|
   --|   This Procedure(INTG_SET_BKDN_EXP_PRC ) will create the data files from staging tables                  |
   --|   INTG_SET_BKDN_STG and Update staging table with the extract date and file name                         |
   -------------------------------------------------------------------------------------------------------------|

   IS

      l_batch_no          NUMBER;
      l_comm_seq_no       NUMBER;
      l_errmsg            VARCHAR2(1000);

      l_file_handle   UTL_FILE.file_type;
      l_file_dir      VARCHAR2(100);
      l_file_name     VARCHAR2 (50);
      l_file_name1     VARCHAR2 (50);

      l_division       VARCHAR2(30);

      CURSOR c_div
      IS
         SELECT distinct nvl(xsms.snm_division, 'nodiv') snm_division
           FROM INTG_SET_BKDN_STG isbs, XXOM_SALES_MARKETING_SET_V xsms
           WHERE isbs.status_flat_file is null
             and isbs.parent_item = xsms.inventory_item_id (+)
             and isbs.organization_id = xsms.organization_id (+)
           ORDER BY 1;

      CURSOR c1(cp_division in varchar2)
      IS
         SELECT transaction_id        ,
                orig_transaction_id,
                transaction_date    ,
                oracle_trans_type        ,
                party_initiating_tfr     ,
                party_receiving_tfr      ,
                work_order_number        ,
                child_item               ,
                parent_item              ,
                lot_serial_number       ,
                expiration_date          ,
                quantity                ,
                date_transfer            ,
                date_shipped             ,
                inventory_type,
                nvl(xsms.snm_division, 'nodiv') snm_division
           FROM INTG_SET_BKDN_STG isbs, XXOM_SALES_MARKETING_SET_V xsms
           WHERE isbs.status_flat_file is null
             and isbs.parent_item = xsms.inventory_item_id (+)
             and isbs.organization_id = xsms.organization_id (+)
             and nvl(xsms.snm_division, 'nodiv') = cp_division
           ORDER BY transaction_id;

   BEGIN

   FOR r_div in c_div LOOP

     l_division := r_div.snm_division;

/*
     -- Derive Division to be placed in file name
     DECLARE
        v_parent_item_id NUMBER;
        v_organization_id NUMBER;

     BEGIN
              SELECT  parent_item, organization_id INTO v_parent_item_id, v_organization_id
                FROM INTG_SET_BKDN_STG
               WHERE status_flat_file is null
                 AND parent_item IS NOT NULL
                 AND ROWNUM=1;

              SELECT mck.segment4 snm_division
                INTO l_division
                FROM   mtl_item_categories mic,
                       mtl_categories_kfv mck,
                       mtl_category_sets mcs
               WHERE   mck.category_id = mic.category_id
                 AND mic.organization_id = v_organization_id
                 AND mic.category_set_id = mcs.category_set_id
                 AND UPPER (mcs.category_set_name) = UPPER ('SALES AND MARKETING')
                 AND mck.category_id = mic.category_id
                 AND INVENTORY_ITEM_ID = v_parent_item_id;

                fnd_file.put_line (fnd_file.LOG, 'l_division : ' || l_division );

      EXCEPTION
        WHEN OTHERS THEN
              fnd_file.put_line (fnd_file.LOG, 'Unable to derive parent item to determine division');
              l_division := null;
      END;

*/

        BEGIN
        SELECT   XXOM_CNSGN_CMN_FILE_SEQ.NEXTVAL
        INTO   l_comm_seq_no
        FROM   DUAL;
        EXCEPTION
        WHEN OTHERS THEN
           apps.fnd_file.put_line ( fnd_file.LOG,
             'Unable to fetch common sequence value: ' || l_comm_seq_no
           );
        END;

        BEGIN
         SELECT   INTG_SET_BKDN_SEQ.NEXTVAL INTO l_int_seq_no FROM DUAL;

         fnd_file.put_line (fnd_file.LOG, 'l_int_seq_no : ' || l_int_seq_no );
      EXCEPTION
         WHEN OTHERS
         THEN
            apps.fnd_file.put_line (
               fnd_file.LOG,
               'Unable to fetch sequence l_int_seq_no value: ' || l_int_seq_no
           );

      END;

                        apps.fnd_file.put_line (
                           fnd_file.LOG,
                           'In procedure1 INTG_ORA_SET_BKDN_EXT_PRC: ' || l_int_seq_no
           );

    -- Find the path where the file has to be stored.


                   apps.fnd_file.put_line (
                      fnd_file.LOG,
                      'l_file_dir: ' || l_file_dir
                   );

                l_file_name := l_comm_seq_no||'_'||'BKDN'||'_'||l_int_seq_no||'_'||l_division||'.tx1';
                l_file_name1 := l_comm_seq_no||'_'||'BKDN'||'_'||l_int_seq_no||'_'||l_division||'.txt';


            --l_file_name:= 'BKDN'||l_int_seq_no||'.txt';
                   apps.fnd_file.put_line (
                      fnd_file.LOG,
                      'l_file_name: ' || l_file_name1
                   );

               l_file_handle      := UTL_FILE.fopen ('XXSGSFTOUT', l_file_name, 'w');
--               l_file_handle := UTL_FILE.fopen ('XXSGSFTOUT', l_file_name, 'w');
--               l_file_handle_arch := UTL_FILE.fopen ('XXSGSFTOUTARCH', l_file_name, 'w');

               UTL_FILE.put_line (
                    l_file_handle,
                       'TRANSACTION_ID'
                    || '|'
                    || 'TRANSACTION_DATE'
                    || '|'
                    || 'ORACLE_TRANS_TYPE'
                    || '|'
                    || 'PARTY_INITIATING_TFR'
                    || '|'
                    || 'PARTY_RECEIVING_TFR'
                    || '|'
                    || 'WORK_ORDER_NUMBER'
                    || '|'
                    || 'CHILD_ITEM'
                    || '|'
                    || 'PARENT_ITEM'
                    || '|'
                    || 'LOT_SERIAL_NUMBER'
                    || '|'
                    || 'EXPIRATION_DATE'
                    || '|'
                    || 'QUANTITY'
                    || '|'
                    || 'DATE_TRANSFER'
                    || '|'
                    || 'DATE_SHIPPED'
                    || '|'
                    || 'INVENTORY_TYPE'
                    || '|'
                    || 'ORACLE_TRANSACTION_ID'
                    || '|'
               );

      FOR c1_rec in c1(r_div.snm_division) LOOP
      EXIT WHEN c1%NOTFOUND;

      fnd_file.put_line (fnd_file.LOG, 'writing into utlfile');

           UTL_FILE.put_line (
                  l_file_handle,
                     c1_rec.transaction_id
                  || '|'
                  || c1_rec.transaction_date
                  || '|'
                  || c1_rec.oracle_trans_type
                  || '|'
                  || c1_rec.party_initiating_tfr
                  || '|'
                  || c1_rec.party_receiving_tfr
                  || '|'
                  || c1_rec.work_order_number
                  || '|'
                  || c1_rec.child_item
                  || '|'
                  || c1_rec.parent_item
                  || '|'
                  || c1_rec.lot_serial_number
                  || '|'
                  || c1_rec.expiration_date
                  || '|'
                  || c1_rec.quantity
                  || '|'
                  || c1_rec.date_transfer
                  || '|'
                  || c1_rec.date_shipped
                  || '|'
                  || c1_rec.inventory_type
                  || '|'
                  || c1_rec.orig_transaction_id
                  || '|'
               );

              UPDATE INTG_SET_BKDN_STG
                SET   status_flat_file = 'SUCCESS',
                     message_flat_file = 'File has been extracted and moved to'||l_file_dir,
                     SS_BKDN_FILE_NAME = l_file_name,
                     SS_BKDN_INTF_DATE = SYSDATE
               WHERE orig_transaction_id = c1_rec.orig_transaction_id;



         END LOOP;

           -- UTL_FILE.fflush (l_file_handle);


    -- Calling procedure to insert into interface tables for process transaction interface

            UTL_FILE.fclose (l_file_handle);
            UTL_FILE.FRENAME('XXSGSFTOUT', l_file_name, 'XXSGSFTOUT', l_file_name1, TRUE);
            xxom_consgn_comm_ftp_pkg.add_new_file(l_file_name1); -- Provide actual file name as parameter.
            COMMIT;

   END LOOP;  
               
   --xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends actual data file to surgisoft using sFTP.
   xxom_consgn_comm_ftp_pkg.GEN_CONF_FILE('Oracle_transfer_complete.txt','XXSGSFTOUT','XXSGSFTARCH'); -- This process generates confirmation file at the end.
   --xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends/overwrites confirmation file to surgisoft using sFTP.

   EXCEPTION
      WHEN UTL_FILE.invalid_mode
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode Parameter');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Mode Parameter');
      WHEN UTL_FILE.invalid_path
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Location');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid File Location');
      WHEN UTL_FILE.invalid_filehandle
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Filehandle');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Filehandle');
      WHEN UTL_FILE.invalid_operation
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Operation');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Operation');
      WHEN UTL_FILE.read_error
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Read Error');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Read Error');
      WHEN UTL_FILE.internal_error
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Internal Error');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Internal Error');
      WHEN UTL_FILE.charsetmismatch
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Opened With FOPEN_NCHAR But Later I/O Inconsistent');
         FND_FILE.PUT_LINE(FND_FILE.LOG,
                 'Opened With FOPEN_NCHAR
       But Later I/O Inconsistent'
                );
      WHEN UTL_FILE.file_open
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Already Opened');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'File Already Opened');
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Line Size Exceeds 32K');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Line Size Exceeds 32K');
      WHEN UTL_FILE.invalid_filename
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Name');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid File Name');
      WHEN UTL_FILE.access_denied
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Access Denied By');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'File Access Denied By');
      WHEN UTL_FILE.invalid_offset
      THEN
         fnd_file.put_line (fnd_file.LOG, 'FSEEK Param Less Than 0');
        FND_FILE.PUT_LINE(FND_FILE.LOG,'FSEEK Param Less Than 0');
      WHEN OTHERS
      THEN
        fnd_file.put_line (fnd_file.LOG, 'Unknown UTL_FILE Error');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown UTL_FILE Error-'||sqlerrm);
       --  retcode:= 2;
       --  errbuf:= TO_CHAR(sqlcode)||'-'||SUBSTR (SQLERRM, 1, 255);
   END INTG_SET_BKDN_EXP_PRC;
END XXOM_SET_BKDN_PKG;
/
