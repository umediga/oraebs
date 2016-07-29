DROP PACKAGE BODY APPS.XXOM_MAT_RCPT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_MAT_RCPT_PKG" IS

/*************************************************************************************
*   PROGRAM NAME
*     XXOM_MAT_RCPT_PKG.sql
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
*     1.0  05-JAN-2014 Brian Stadnik      Initial Version
*     2.0  15-MAY-2014 Brian Stadnik      Exclude transactions originating in Surgisoft
*     3.0  15-JUL-2014 Brian Stadnik      Added the transactions that were previously excluded
*                                         so that the validation changes in the Surgisoft processes
*                                         can be utilized
*
* ISSUES:
*
******************************************************************************************/

PROCEDURE INTG_INV_RCPT_EXT_PRC (errbuf                 OUT VARCHAR2,
                                           retcode            OUT VARCHAR2,
                                           p_orgn_id           IN   NUMBER,
                                           p_subinv_code        IN  VARCHAR2,
                                           p_trans_date        IN  VARCHAR2,
                                           -- p_tran_type        IN  VARCHAR2,
                                           p_set_org_id        IN   NUMBER
                                           )

IS

v_status      VARCHAR2(20);
lv_count      NUMBER:=0;
l_proc_status   VARCHAR2(1):= 'P';
v_lot_exp_date  VARCHAR2(30):= NULL;
l_trans_date  DATE;
l_sub_xfer_source_code VARCHAR2(20) := 'Txn from SS';

/***** Vishy 03/20/2014 - All variables ****/
      l_transaction_id NUMBER; -- Vishy 03/18/2014
      l_return_status varchar2(10); --Vishy 03/18/2014
      l_return_message varchar2(200); --Vishy 03/18/2014
      l_transaction_source_name varchar2(30); --Vishy 03/18/2014
      l_kit_serial  VARCHAR2(30); --Vishy 03/18/2014
      l_transaction_type_id NUMBER;
      l_transaction_source_id NUMBER;
      l_txn_int_id NUMBER;
      l_txn_batch_id NUMBER;
      l_txn_header_id NUMBER;
      l_source_code VARCHAR2 (30) := 'LPN Reconfig';
      l_org_id NUMBER;
      l_content_org_id NUMBER;
      l_kit_org_id NUMBER;
      l_content_subinventory_code VARCHAR2(10);
      l_content_locator_id NUMBER;
      l_kit_subinventory_code VARCHAR2(10);
      l_kit_locator_id NUMBER;
      j NUMBER := 0;
      l_kit_lpn_id NUMBER;
      l_content_lpn_id NUMBER;
      x_msg_count NUMBER;
      x_trans_count NUMBER;
      x_return_status varchar2(10); --Vishy 03/18/2014
      x_return_message varchar2(200); --Vishy 03/18/2014
      l_return NUMBER;
      l_item_code VARCHAR2(40);
      l_subinventory_code VARCHAR2(10);
      l_locator_id NUMBER;
      l_quantity NUMBER;
      l_uom VARCHAR2(3);
      l_lot_control_code NUMBER;
      l_serial_number_control_code NUMBER;
      l_lot_number VARCHAR2(80);
      l_serial_number  VARCHAR2(30);
      /***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/
      l_xmrs_transaction_id number;
      l_xmrs_kit_transaction_id number;
      l_lpn_id number;

-- Cursor to get the inventory receipt details

CURSOR inv_rec IS
SELECT   mmt.transaction_id,
     mtt.transaction_type_name,
         NVL (DECODE (mtt.transaction_type_name,
                      'Account alias receipt',
                      '-1',
                      'Subinventory Transfer',
                      -- mmt.transfer_subinventory
                          (
                select  nvl(nvl(milk.attribute3,msi.attribute2),-999)
      from
           mtl_secondary_inventories msi,
           mtl_item_locations milk
      where msi.organization_id = mmt.transfer_organization_id
      and milk.organization_id = msi.organization_id
      -- msi.secondary_inventory_name
      and milk.inventory_location_id = mmt.transfer_locator_id
      and msi.secondary_inventory_name = mmt.transfer_subinventory
         ),
        -- add -1 as a default
        -1
                      ), organization_name)
            party_Initiat,
         --  mmt.attribute3 party_recv_transfer,
       /*  (  select jrs.salesrep_number
     from jtf_rs_salesreps jrs,
       hr_employees he,
       mtl_secondary_inventories msi,
       hr_locations hl,
       po_location_associations_all pla
     where pla.location_id = hl.location_id
     and hl.location_id = msi.location_id
     and msi.description = he.full_name
     and   jrs.person_id = he.employee_id
     and msi.secondary_inventory_name = mmt.transfer_subinventory_code
     */
     NVL ( (
      select  nvl(nvl(milk.attribute3,msi.attribute2),-999)
      from
           mtl_secondary_inventories msi,
           mtl_item_locations milk
      where msi.secondary_inventory_name = mmt.subinventory_code
      and msi.organization_id = mmt.organization_id -- added the locator logic
      and milk.organization_id = mmt.organization_id --  added the locator logic
      and milk.subinventory_code = msi.secondary_inventory_name -- added the locator logic
      and milk.inventory_location_id = mmt.locator_id -- added the locator logic
         ),-999  )
         party_recv_transfer,
         mmt.inventory_item_id,
         mmt.organization_id,
         decode(msib.item_type,'K','Y','N') is_set, -- bbom.attribute1 is_set,
         decode(msib.item_type,'K','Loaner','Field Stock') inv_item_type,
         mut.serial_number,
         mtln.lot_number,
         NVL (mut.serial_number, mtln.lot_number) lot_serial,
         CASE
            WHEN mut.serial_number IS NOT NULL
            THEN
               1
            WHEN mut.serial_number IS NULL AND mtln.lot_number IS NOT NULL
            THEN
               mtln.transaction_quantity
            ELSE
               mmt.transaction_quantity
         END
            quantity,
         to_Char(mmt.transaction_date, 'DD-MON-YYYY HH24:MI:SS') date_transfer,
         NULL transfer_method,
         NULL tracking_number,
         to_Char(mmt.transaction_date, 'DD-MON-YYYY HH24:MI:SS') date_shipped,
         NULL address1,
         NULL address2,
         NULL city,
         NULL state,
         NULL zip,
         NULL county,
         -- NVL (item_cat.inv_type, 'Field Stock') inv_item_type,
         mmt.transaction_reference,
         null order_number,
         msib.segment1 -- Vishy 03/21/2014 (included item code)
FROM
--XXOM_MAT_RCPT_STG xmrs, /* Amin 05/29/2014 eliminate duplicate unpacks*/
         mtl_material_transactions mmt,
         mtl_transaction_types mtt,
         mtl_transaction_lot_numbers mtln,
         mtl_unit_transactions mut,
         mtl_system_items_b msib,
         bom_bill_of_materials bbom,
         org_organization_definitions ood,
         mtl_secondary_inventories msi
         /*
         ,
         (SELECT   DECODE (mck.concatenated_segments,
                           NULL, 'Field Stock',
                           'Loaner')
                      inv_type,
                   mic.inventory_item_id,
                   mic.organization_id
            FROM   mtl_category_sets mcs,
                   mtl_item_categories mic,
                   mtl_categories_kfv mck
           WHERE       mcs.category_set_name = 'DEFAULT LOAN DAYS'
                   AND mcs.category_set_id = mic.category_set_id
                   AND mck.category_id = mic.category_id) item_cat
                   */
 WHERE       mmt.organization_id = p_orgn_id
         AND mtt.transaction_type_name IN (
                   SELECT flex_value
                     FROM apps.fnd_flex_values_vl ffvv,
                          apps.fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name =
                                                'INTG_INV_REC_TXN_TYPE1'
                      AND ffvv.enabled_flag = 'Y'
                      AND ffvv.flex_value_set_id = ffvs.flex_value_set_id)
          AND nvl(mmt.transaction_source_id,-99999) not in
                      ( SELECT disposition_id -- distribution_account
                        FROM   mtl_generic_dispositions
                        WHERE  organization_id = p_orgn_id
                        AND    segment1 = 'KIT_EXPLOSION_150'
                      )
         -- stadnik - 15-JUL-14 we want to include the transactions originating in
         -- Surgisoft so that we can validate in the SSDLY
        -- AND  ( nvl(mmt.source_code,'XYZYZX') <> 'Txn from SS'
              and  nvl(mmt.transaction_source_name, 'XYZYZX') <> 'NOSS'
        --       )
         AND mmt.transaction_id = mtln.transaction_id(+)
         AND mmt.transaction_id = mut.transaction_id(+)
         AND mmt.transaction_type_id = mtt.transaction_type_id
         AND mmt.inventory_item_id = bbom.assembly_item_id(+)
         AND msi.secondary_inventory_name = mmt.subinventory_code
         AND msi.organization_id = p_orgn_id
         and msi.attribute1 not in ('H','I')
         AND msib.inventory_item_id = mmt.inventory_item_id
         AND msib.organization_id = p_orgn_id
         AND bbom.organization_id(+) = p_set_org_id -- pass set organization id parameter here 160/180
         -- AND mmt.inventory_item_id = item_cat.inventory_item_id(+)
         -- AND mmt.organization_id = item_cat.organization_id(+)
         AND ood.organization_id(+) = mmt.transfer_organization_id
         AND mmt.transaction_quantity > 0
         AND trunc(mmt.transaction_date) >= l_trans_date
         /* Amin 05/29/2014 eliminate duplicate unpacks*/
         AND NOT EXISTS ( SELECt 1 from XXOM_MAT_RCPT_STG xmrs where xmrs.orig_transaction_id=mmt.transaction_id)
        /* AND mmt.transaction_id = xmrs.orig_transaction_id (+)
         and mmt.transaction_date >= NVL ( (TO_DATE (xmrs.transaction_date, 'DD-MON-YYYY HH24:MI:SS')), mmt.transaction_date- 1)*/
UNION
SELECT   mmt.transaction_id,
     mtt.transaction_type_name,
         pov.vendor_name party_Initiat,
         ''||poda.deliver_to_person_id party_recv_transfer,
         mmt.inventory_item_id,
         mmt.organization_id,
         decode(msib.item_type,'K','Y','N') is_set, -- bbom.attribute1 is_set,
         decode(msib.item_type,'K','Loaner','Field Stock') inv_item_type,
         mut.serial_number,
         mtln.lot_number,
         NVL (mut.serial_number, mtln.lot_number) lot_serial,
         CASE
            WHEN mut.serial_number IS NOT NULL
            THEN
               1
            WHEN mut.serial_number IS NULL AND mtln.lot_number IS NOT NULL
            THEN
               mtln.transaction_quantity
            ELSE
               mmt.transaction_quantity
         END
            quantity,
         to_Char(mmt.transaction_date, 'DD-MON-YYYY HH24:MI:SS') date_transfer,
         NULL transfer_method,
         NULL tracking_number,
         to_Char(mmt.transaction_date, 'DD-MON-YYYY HH24:MI:SS') date_shipped,
         NULL address1,
         NULL address2,
         NULL city,
         NULL state,
         NULL zip,
         NULL county,
         -- NVL (item_cat.inv_type, 'Field Stock') inv_item_type,
         mmt.transaction_reference,
         null order_number,
         msib.segment1 -- Vishy 03/21/2014 (included item code)
  FROM
    /* Amin 05/29/2014 eliminate duplicate unpacks*/
  --XXOM_MAT_RCPT_STG xmrs,
         mtl_material_transactions mmt,
         mtl_system_items_b msib,
         mtl_transaction_types mtt,
         mtl_transaction_lot_numbers mtln,
         mtl_unit_transactions mut,
         bom_bill_of_materials bbom,
         po_headers_all poha,
         po_vendors pov,
         po_distributions_all poda,
         rcv_transactions rcvt
         /*,
         (SELECT   DECODE (mck.concatenated_segments,
                           NULL, 'Field Stock',
                           'Loaner')
                      inv_type,
                   mic.inventory_item_id,
                   mic.organization_id
            FROM   mtl_category_sets mcs,
                   mtl_item_categories mic,
                   mtl_categories_kfv mck
           WHERE       mcs.category_set_name = 'DEFAULT LOAN DAYS'
                   AND mcs.category_set_id = mic.category_set_id
                   AND mck.category_id = mic.category_id) item_cat
                   */
 WHERE       mmt.organization_id = p_orgn_id
         AND mtt.transaction_type_name IN (
                   SELECT flex_value
                     FROM apps.fnd_flex_values_vl ffvv,
                          apps.fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name =
                                                'INTG_INV_REC_TXN_TYPE2'
                      AND ffvv.enabled_flag = 'Y'
                      AND ffvv.flex_value_set_id = ffvs.flex_value_set_id)
         AND mmt.transaction_id = mtln.transaction_id(+)
         AND mmt.transaction_id = mut.transaction_id(+)
         AND mmt.transaction_type_id = mtt.transaction_type_id
         AND mmt.inventory_item_id = bbom.assembly_item_id(+)
         AND msib.inventory_item_id = mmt.inventory_item_id
         and msib.organization_id = mmt.organization_id
         AND bbom.organization_id(+) = p_set_org_id --pass set organization id parameter here
         -- AND mmt.inventory_item_id = item_cat.inventory_item_id(+)
         -- AND mmt.organization_id = item_cat.organization_id(+)
         AND poha.po_header_id = mmt.transaction_source_id
         AND poha.vendor_id = pov.vendor_id
         AND poha.po_header_id = poda.po_header_id
         AND rcvt.transaction_id = mmt.source_line_id
         AND rcvt.po_line_id = poda.po_line_id
--         AND TRUNC (mmt.transaction_date) = TRUNC (SYSDATE)-24--check
         -- AND mmt.subinventory_code = p_subinv_code
         AND mmt.transaction_quantity > 0
         AND trunc(mmt.transaction_date) >= l_trans_date
                 /* Amin 05/29/2014 eliminate duplicate unpacks*/
         AND NOT EXISTS ( SELECt 1 from XXOM_MAT_RCPT_STG xmrs where xmrs.orig_transaction_id=mmt.transaction_id)
        /* AND mmt.transaction_id = xmrs.orig_transaction_id (+)
         and mmt.transaction_date >= NVL ( (TO_DATE (xmrs.transaction_date, 'DD-MON-YYYY HH24:MI:SS')), mmt.transaction_date- 1)*/
UNION
SELECT   mmt.transaction_id,
     mtt.transaction_type_name,
         organization_name party_Initiat,
         nvl(nvl(milk.attribute3,msi.attribute2),-999) party_recv_transfer, -- added the locator logic,
         mmt.inventory_item_id,
         mmt.organization_id,
         decode(msib.item_type,'K','Y','N') is_set, -- bbom.attribute1 is_set,
         decode(msib.item_type,'K','Loaner','Field Stock') inv_item_type,
         mut.serial_number,
         mtln.lot_number,
         NVL (mut.serial_number, mtln.lot_number) lot_serial,
         CASE
            WHEN mut.serial_number IS NOT NULL
            THEN
               1
            WHEN mut.serial_number IS NULL AND mtln.lot_number IS NOT NULL
            THEN
               mtln.transaction_quantity
            ELSE
               mmt.transaction_quantity
         END
            quantity,
         to_Char(mmt.transaction_date, 'DD-MON-YYYY HH24:MI:SS') date_transfer,
         wcs.ship_method_meaning transfer_method,
         nvl(wnd.waybill,oeoh.cust_po_number) tracking_number,
         to_Char(wnd.confirm_date, 'DD-MON-YYYY HH24:MI:SS') date_shipped,
         wl.address1,
         wl.address2,
         wl.city,
         wl.state,
         wl.postal_code,
         wl.county,
        -- NVL (item_cat.inv_type, 'Field Stock') inv_item_type,
         mmt.transaction_reference,
         oeoh.order_number order_number,
         msib.segment1 -- Vishy 03/21/2014 (included item code)
  FROM
          /* Amin 05/29/2014 eliminate duplicate unpacks*/
  --XXOM_MAT_RCPT_STG xmrs,
         mtl_material_transactions mmt,
         mtl_secondary_inventories msi,
         mtl_system_items_b msib,
         mtl_transaction_types mtt,
         mtl_transaction_lot_numbers mtln,
         mtl_unit_transactions mut,
         bom_bill_of_materials bbom,
         org_organization_definitions ood,
         mtl_material_transactions mmt2,
         hz_parties hp,
         hz_cust_accounts hca,
         wsh_carrier_Services wcs,
         oe_order_headers_all oeoh,
         wsh_new_deliveries wnd,
         /* Amin 05/29/2014 eliminate duplicate unpacks*/
         oe_order_lines_all oel,

        -- wsh_delivery_assignments wda,
        -- wsh_delivery_details wdd,
        /* Amin 05/29/2014 eliminate duplicate unpacks*/
         wsh_locations wl,
         mtl_item_locations milk -- , --Vishy added the locator logic -- ,
         -- hr_employees he,
         /*
         (SELECT   DECODE (mck.concatenated_segments,
                           NULL, 'Field Stock',
                           'Loaner')
                      inv_type,
                   mic.inventory_item_id,
                   mic.organization_id
            FROM   mtl_category_sets mcs,
                   mtl_item_categories mic,
                   mtl_categories_kfv mck
           WHERE       mcs.category_set_name = 'DEFAULT LOAN DAYS'
                   AND mcs.category_set_id = mic.category_set_id
                   AND mck.category_id = mic.category_id) item_cat
                   */
 WHERE       mmt.organization_id = p_orgn_id
         AND mtt.transaction_type_name IN (
                   SELECT flex_value
                     FROM apps.fnd_flex_values_vl ffvv,
                          apps.fnd_flex_value_sets ffvs
                    WHERE ffvs.flex_value_set_name = 'INTG_INV_REC_TXN_TYPE3'
                      AND ffvv.enabled_flag = 'Y'
                      AND ffvv.flex_value_set_id = ffvs.flex_value_set_id)
         AND mmt.transaction_id = mtln.transaction_id(+)
         AND mmt.transaction_id = mut.transaction_id(+)
         AND mmt.transaction_type_id = mtt.transaction_type_id
         AND mmt.inventory_item_id = bbom.assembly_item_id(+)
         AND msib.inventory_item_id = mmt.inventory_item_id
         and msib.organization_id = p_orgn_id
         AND bbom.organization_id(+) = p_set_org_id--1067 --pass set organization id parameter here
         -- AND mmt.inventory_item_id = item_cat.inventory_item_id(+)
         -- AND mmt.organization_id = item_cat.organization_id(+)
         AND mmt.transfer_organization_id = ood.organization_id(+)
         AND msi.secondary_inventory_name = mmt.subinventory_code
         AND msi.organization_id = mmt.organization_id -- Vishy 03/21/2014 - added the where condition
         and msi.attribute1 not in ('H','I')
         AND mmt.transfer_transaction_id = mmt2.transaction_id
         AND mmt2.trx_source_Delivery_id = wnd.delivery_id
         /* Amin 05/29/2014 eliminate duplicate unpacks*/
          and mmt2.trx_source_line_id=oel.line_id

        AND oel.header_id = oeoh.header_id
        /* Amin 05/29/2014 eliminate duplicate unpacks*/
        -- AND wdd.source_header_id = oeoh.header_id
        -- and wnd.delivery_id = wda.delivery_id
       --  AND wda.delivery_detail_id = wdd.delivery_detail_id  -- For deliveries not linked to sales orders joining through delivery details.. 08/20/10 by Ravi Pampana
        -- AND wdd.source_code = 'OE' -- Vishy 03/21/2014 - added the where condition
         AND oeoh.sold_to_org_id = hca.cust_account_id
         AND hca.party_id = hp.party_id
         AND wcs.ship_method_code(+) = wnd.ship_method_code
         AND wnd.ultimate_Dropoff_location_id = wl.wsh_location_id
         -- AND mmt.subinventory_code = p_subinv_code
         AND mmt.transaction_quantity > 0
         AND trunc(mmt.transaction_date) >= l_trans_date

       /* Amin 05/29/2014 eliminate duplicate unpacks*/
         AND NOT EXISTS ( SELECt 1 from XXOM_MAT_RCPT_STG xmrs where xmrs.orig_transaction_id=mmt.transaction_id)
        /* AND mmt.transaction_id = xmrs.orig_transaction_id (+)
         and mmt.transaction_date >= NVL ( (TO_DATE (xmrs.transaction_date, 'DD-MON-YYYY HH24:MI:SS')), mmt.transaction_date- 1)*/

         and milk.organization_id = msi.organization_id ---- added the locator logic
         and milk.subinventory_code = msi.secondary_inventory_name ---- added the locator logic
         and milk.inventory_location_id = mmt.locator_id -- added the locator logic

--         AND  mmt.attribute2 IS NULL
          ;

/*** Vishy 03/20/2014: Cursors for unpack and split ****/
/***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/

  cursor c_kit_request_move is

         select oeh.cust_po_number cust_po_number, mmt.content_lpn_id lpn_id, mmt.transaction_id transaction_id, xmrs.transaction_id xmrs_kit_transaction_id
            from XXOM_MAT_RCPT_STG xmrs, mtl_material_transactions mmt, mtl_parameters mp, wms_license_plate_numbers wlpn,
            oe_order_headers_all oeh, oe_order_lines_all ool, oe_transaction_types_tl oet, OE_TRANSACTION_TYPES_ALL a,
            apps.wms_lpn_contents wlc
            where nvl(xmrs.status,'NOT APPLICABLE') <> 'SUCCESS' and xmrs.oracle_trans_type = 'Int Req Direct Org Xfer'
            and xmrs.orig_transaction_id = mmt.transaction_id and mmt.trx_source_line_id = ool.line_id and
            oeh.header_id = ool.header_id and ool.line_type_id = a.transaction_type_id and
            a.transaction_type_id = oet.transaction_type_id and
            oet.language = (Select language_code from fnd_languages where installed_flag = 'B') and
            oet.name like '%Kitting%Request%'and mmt.content_lpn_id is not null
            and mmt.transaction_source_type_id = 7 and mmt.transaction_action_id = 3 and oeh.cust_po_number is not null
            and mmt.organization_id = mp.organization_id and mp.organization_code = '150'
            and mmt.content_lpn_id = wlpn.lpn_id and wlpn.organization_id = mmt.organization_id
            and wlc.parent_lpn_id = wlpn.lpn_id and wlpn.parent_lpn_id is null
            and wlc.inventory_item_id = mmt.inventory_item_id
           -- and wlpn.parent_lpn_id is null
          -- Vishy: 16-may-2014 changed to remove set org id and run unpack for all orgs coming into 150
           -- and mmt.transfer_organization_id = p_set_org_id
           and exists (select count(1) from mtl_onhand_quantities_detail moqd
                where moqd.organization_id = wlc.organization_id
                and moqd.inventory_item_id = wlc.inventory_item_id
                and moqd.lpn_id = wlc.parent_lpn_id
                and nvl(moqd.lot_number, -1) = nvl(wlc.lot_number, -1)
                and mmt.transaction_id = moqd.create_transaction_id (+)
                having count(1) > 0
                )

       UNION

         select oeh.cust_po_number cust_po_number, wlpn2.lpn_id lpn_id, mmt.transaction_id transaction_id, xmrs.transaction_id xmrs_kit_transaction_id
            from XXOM_MAT_RCPT_STG xmrs, mtl_material_transactions mmt, mtl_parameters mp,
            oe_order_headers_all oeh, oe_order_lines_all ool, oe_transaction_types_tl oet, OE_TRANSACTION_TYPES_ALL a,
            wms_license_plate_numbers wlpn,  wms_license_plate_numbers wlpn2,  apps.wms_lpn_contents wlc
            where xmrs.oracle_trans_type = 'Int Req Direct Org Xfer'
            and xmrs.orig_transaction_id = mmt.transaction_id and mmt.trx_source_line_id = ool.line_id and
            oeh.header_id = ool.header_id and ool.line_type_id = a.transaction_type_id and
            a.transaction_type_id = oet.transaction_type_id and
            oet.language = (Select language_code from fnd_languages where installed_flag = 'B') and
            oet.name like '%Kitting%Request%'and mmt.content_lpn_id is not null
            and mmt.transaction_source_type_id = 7 and mmt.transaction_action_id = 3 and oeh.cust_po_number is not null
            and mmt.organization_id = mp.organization_id and mp.organization_code = '150'
            and wlpn.lpn_id = mmt.content_lpn_id and wlpn.lpn_id = wlpn2.parent_lpn_id
            and mmt.organization_id = wlpn.organization_id and mmt.organization_id = wlpn2.organization_id
            and wlc.parent_lpn_id = wlpn2.lpn_id and wlpn2.parent_lpn_id is not null
            and wlc.inventory_item_id = mmt.inventory_item_id
            and exists (select count(1) from mtl_onhand_quantities_detail moqd
            where moqd.organization_id = wlc.organization_id
            and moqd.inventory_item_id = wlc.inventory_item_id
            and moqd.lpn_id = wlc.parent_lpn_id
            and nvl(moqd.lot_number, -1) = nvl(wlc.lot_number, -1)
            and mmt.transaction_id = moqd.create_transaction_id (+)
            having count(1) > 0)
            order by 1;

/***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/
/****
      cursor c_unpack_floater is

        select mmt.transaction_id transaction_id, xmrs.transaction_id xmrs_transaction_id
            from XXOM_MAT_RCPT_STG xmrs, mtl_material_transactions mmt, mtl_parameters mp
            where nvl(xmrs.status,'NOT APPLICABLE') <> 'SUCCESS' and xmrs.oracle_trans_type = 'Int Req Direct Org Xfer'
            and xmrs.orig_transaction_id = mmt.transaction_id and mmt.content_lpn_id is not null
            and mmt.transaction_source_type_id = 7 and mmt.transaction_action_id = 3
            and mmt.organization_id = mp.organization_id and mp.organization_code = '150';
            -- Vishy: 16-may-2014 changed to remove set org id and run unpack for all orgs coming into 150
           -- and mmt.organization_id = p_set_org_id;
*****/
/*** Vishy: 08/05/2014: Changes to unpack hospital consignment and to unpack multi-level LPNs *****/
cursor c_unpack_nonss_multilevel is

     select distinct wlpn.lpn_id
                from apps.mtl_material_transactions mmt, apps.mtl_parameters mp, apps.wms_license_plate_numbers wlpn,
                oe_order_headers_all oeh, oe_order_lines_all ool, oe_transaction_types_tl oet, OE_TRANSACTION_TYPES_ALL a,
                wms_lpn_contents wlc
                where mmt.content_lpn_id is not null
                and mmt.transaction_source_type_id = 7 and mmt.transaction_action_id = 3
                and mmt.organization_id = mp.organization_id and mp.organization_code = '150'
                and mmt.organization_id = wlpn.organization_id
                and wlpn.lpn_id = mmt.content_lpn_id
                and mmt.trx_source_line_id = ool.line_id
                and oeh.header_id = ool.header_id and ool.line_type_id = a.transaction_type_id
                and a.transaction_type_id = oet.transaction_type_id
                and oet.language = (Select language_code from fnd_languages where installed_flag = 'B')
                and oet.name like '%Consignment%Request%'
                and wlc.parent_lpn_id = wlpn.lpn_id and wlpn.parent_lpn_id is null
                and wlc.inventory_item_id = mmt.inventory_item_id
                and exists (select count(1) from mtl_onhand_quantities_detail moqd
                where moqd.organization_id = wlc.organization_id
                and moqd.inventory_item_id = wlc.inventory_item_id
                and moqd.lpn_id = wlc.parent_lpn_id
                and nvl(moqd.lot_number, -1) = nvl(wlc.lot_number, -1)
                and mmt.transaction_id = moqd.create_transaction_id (+)
                having count(1) > 0)

     UNION

     select distinct wlpn2.lpn_id
                from apps.mtl_material_transactions mmt, apps.mtl_parameters mp, apps.wms_license_plate_numbers wlpn,
                apps.wms_license_plate_numbers wlpn2, oe_order_headers_all oeh, oe_order_lines_all ool,
                oe_transaction_types_tl oet, OE_TRANSACTION_TYPES_ALL a, wms_lpn_contents wlc 
                where mmt.content_lpn_id is not null
                and mmt.transaction_source_type_id = 7 and mmt.transaction_action_id = 3
                and mmt.organization_id = mp.organization_id and mp.organization_code = '150'
                and mmt.organization_id = wlpn.organization_id
                and mmt.organization_id = wlpn2.organization_id
                and wlpn.lpn_id = mmt.content_lpn_id and wlpn.lpn_id = wlpn2.parent_lpn_id
                and mmt.trx_source_line_id = ool.line_id
                and oeh.header_id = ool.header_id and ool.line_type_id = a.transaction_type_id
                and a.transaction_type_id = oet.transaction_type_id
                and oet.language = (Select language_code from fnd_languages where installed_flag = 'B')
                and oet.name like '%Consignment%Request%'
                and wlc.parent_lpn_id = wlpn2.lpn_id and wlpn2.parent_lpn_id is not null
                and wlc.inventory_item_id = mmt.inventory_item_id
                and exists (select count(1) from mtl_onhand_quantities_detail moqd
                where moqd.organization_id = wlc.organization_id
                and moqd.inventory_item_id = wlc.inventory_item_id
                and moqd.lpn_id = wlc.parent_lpn_id
                and nvl(moqd.lot_number, -1) = nvl(wlc.lot_number, -1)
                and mmt.transaction_id = moqd.create_transaction_id (+)
                having count(1) > 0)
                ;
/*****
  select distinct wlpn.lpn_id
            from apps.mtl_material_transactions mmt, apps.mtl_parameters mp, apps.wms_license_plate_numbers wlpn,
            oe_order_headers_all oeh, oe_order_lines_all ool, oe_transaction_types_tl oet, OE_TRANSACTION_TYPES_ALL a
            where mmt.content_lpn_id is not null
            and mmt.transaction_source_type_id = 7 and mmt.transaction_action_id = 3
            and mmt.organization_id = mp.organization_id and mp.organization_code = '150'
            and mmt.organization_id = wlpn.organization_id
            and wlpn.lpn_id = mmt.content_lpn_id
            and mmt.trx_source_line_id = ool.line_id
            and oeh.header_id = ool.header_id and ool.line_type_id = a.transaction_type_id
            and a.transaction_type_id = oet.transaction_type_id
            and oet.language = (Select language_code from fnd_languages where installed_flag = 'B')
            and oet.name like '%Consignment%Request%' and mmt.transaction_id not in
            (
              select xmrs.orig_transaction_id
            from apps.XXOM_MAT_RCPT_STG xmrs
            where xmrs.oracle_trans_type = 'Int Req Direct Org Xfer'
            and xmrs.orig_transaction_id = mmt.transaction_id) and exists (select count(1) from apps.wms_lpn_contents wlc
            where wlc.parent_lpn_id = wlpn.lpn_id having count(1) > 0)

 UNION

 select distinct wlpn2.lpn_id
            from apps.mtl_material_transactions mmt, apps.mtl_parameters mp, apps.wms_license_plate_numbers wlpn,
            apps.wms_license_plate_numbers wlpn2, oe_order_headers_all oeh, oe_order_lines_all ool,
            oe_transaction_types_tl oet, OE_TRANSACTION_TYPES_ALL a
            where mmt.content_lpn_id is not null
            and mmt.transaction_source_type_id = 7 and mmt.transaction_action_id = 3
            and mmt.organization_id = mp.organization_id and mp.organization_code = '150'
            and mmt.organization_id = wlpn.organization_id
            and mmt.organization_id = wlpn2.organization_id
            and wlpn.lpn_id = mmt.content_lpn_id and wlpn.lpn_id = wlpn2.parent_lpn_id
            and mmt.trx_source_line_id = ool.line_id
            and oeh.header_id = ool.header_id and ool.line_type_id = a.transaction_type_id
            and a.transaction_type_id = oet.transaction_type_id
            and oet.language = (Select language_code from fnd_languages where installed_flag = 'B')
            and oet.name like '%Consignment%Request%'
            and exists (select count(1) from apps.wms_lpn_contents wlc
            where (wlc.parent_lpn_id = wlpn.lpn_id or wlc.parent_lpn_id = wlpn2.lpn_id) having count(1) > 0)
            ;
*****/
/**** End Changes 08/05/2014 ****/

BEGIN
apps.fnd_file.put_line (fnd_file.LOG,
                    'Starting INTG Consignment Material Receipt Program');

apps.fnd_file.put_line (fnd_file.LOG,
                    'p_orgn_id: ' || to_char(p_orgn_id));

l_trans_date := to_date(p_trans_date,'YYYY/MM/DD HH24:MI:SS');

FOR c1_inv_rec IN inv_rec LOOP

--FND_FILE.PUT_LINE(FND_FILE.LOG,'CURSOR COUNT  is '||SQL%ROWCOUNT);


     -- Put any Validations/select queries if required here
      -- Deriving Expiration Date
         BEGIN
         select TO_CHAR(expiration_date, 'DD-MON-YYYY HH24:MI:SS')
         into v_lot_exp_date
         from  mtl_lot_numbers
         where inventory_item_id = c1_inv_rec.inventory_item_id
         AND lot_number = c1_inv_rec.lot_serial
         AND organization_id = p_orgn_id;
              EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   v_lot_exp_date := NULL;
                 WHEN OTHERS THEN
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Deriving v_lot_exp_date');
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is :'||sqlcode ||' : '||sqlerrm );
                   v_lot_exp_date := NULL;
         END;
       -- Inserting into staging table from cursor
            INSERT INTO XXOM_MAT_RCPT_STG(
                            transaction_id,
                            orig_transaction_id,
                            transaction_date ,
                            oracle_trans_type ,
                            party_initiating_tfr ,
                            party_receiving_tfr,
                            item ,
                            is_set,
                            lot_serial_number,
                            expiration_date,
                            quantity,
                            date_transfer,
                            transfer_method,
                            tracking_number,
                            date_shipped,
                            deliver_to_address1 ,
                            deliver_to_address2 ,
                            deliver_to_city ,
                            deliver_to_state ,
                            deliver_to_zip ,
                            inventory_type,
                            transaction_reference,
                            order_number,
                            status,
                            message,
                            inventory_item_id,
                            organization_id,
                            lot_number,
                            serial_number
                                   )
                                         VALUES
                                                (
                                                XXOM_MAT_RCPT_TRANS_SEQ.NEXTVAL,        --transaction_id
                                                c1_inv_rec.transaction_id,
                                                l_proc_date, -- l_proc_date,--TO_CHAR (sysdate, 'DD-MON-YYYY HH24:MI:SS'),    --transaction_date
                                                c1_inv_rec.transaction_type_name,                      --oracle_trans_type
                                                c1_inv_rec.party_initiat,                        --party_initiating_tfr
                                                c1_inv_rec.party_recv_transfer,                        --party_receiving_tfr
                                                c1_inv_rec.segment1,    --Vishy: 03/21/2014            --item
                                                c1_inv_rec.is_set,                    --is_set
                                                c1_inv_rec.lot_serial,                    --lot_serial_number
                                                v_lot_exp_date, -- v_lot_exp_date,                    --expiration_date
                                                c1_inv_rec.quantity,                --quantity
                                                c1_inv_rec.date_transfer, -- c1_inv_rec.date_transfer,            --date_transfer
                                                c1_inv_rec.transfer_method,                --transfer_method
                                                c1_inv_rec.tracking_number,            --tracking_number
                                                c1_inv_rec.date_shipped, -- c1_inv_rec.date_shipped,            --date_shipped
                                                c1_inv_rec.address1,
                                                c1_inv_rec.address2,
                                                c1_inv_rec.city,
                                                c1_inv_rec.state,
                                                c1_inv_rec.zip,
                                                c1_inv_rec.inv_item_type,
                                                substr(c1_inv_rec.Transaction_Reference,1,78),                  --inventory_type
                                                c1_inv_rec.order_number,
                                                NULL,                        --status
                                                NULL,                        --message
                                                c1_inv_rec.inventory_item_id,
                                                c1_inv_rec.organization_id,
                                                c1_inv_rec.lot_number,
                                                c1_inv_rec.serial_number
                                                );


           lv_count := lv_count + 1;
 END LOOP;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'COUNT  is :'||lv_count );

      /*****/
        /****
        Vishy 03/18/2014: We need to move the kitting replenishments from shipped LPN to KIT LPN. We need to pack and unpack to the KIT LPN
        1. Check if the record status <> 'SUCCESS'
        2. Check if the transaction type = Int Req Direct Org Xfer
        3. Check if the line type is ILS Kitting Request
        4. Check the order number and get the KIT LPN from the customer PO field
        5. Select distinct content LPN IDs for the above transactions
        6. Pack into KIT LPN: Transfer LPN = KIT LPN; Content LPN is the shipped LPN
        7. Unpack the inner content LPN: LPN = KIT LPN; Content LPN is the shipped LPN
        *****/


      --  Vishy 03/18/2014: We need to move the kitting replenishments from shipped LPN to KIT LPN. We need to pack and unpack to the KIT LPN
      /***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/
/*****
        FOR c_rec_unpack_floater in c_unpack_floater LOOP
          l_transaction_id := c_rec_unpack_floater.transaction_id;
          l_xmrs_transaction_id := c_rec_unpack_floater.xmrs_transaction_id;

          BEGIN
             unpackFloater
             (p_transaction_id => l_transaction_id,
              p_xmrs_transaction_id => l_xmrs_transaction_id,
              x_return_status => l_return_status,
              x_return_message => l_return_message);

            If (l_return_status  <> FND_API.G_RET_STS_SUCCESS) THEN
                apps.fnd_file.put_line ( fnd_file.LOG,
               'Error returned from unpackFloater for transaction ID: ' || l_transaction_id || ': ' || l_return_status);
               apps.fnd_file.put_line ( fnd_file.LOG,
               'Error Message: ' || l_transaction_id || ': ' || l_return_message);
            Else
               apps.fnd_file.put_line ( fnd_file.LOG,
               'Processed successfully for unpackFloater for transaction ID: ' || l_transaction_id || ': ' || l_return_status);
               apps.fnd_file.put_line ( fnd_file.LOG,
               'Success Message: ' || l_transaction_id || ': ' || l_return_message);
            End if;

          END;

        END LOOP;
*****/
      /***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/

        FOR c_rec_kit_request_move in c_kit_request_move LOOP
         j := 0;
            l_kit_serial := c_rec_kit_request_move.cust_po_number;
            l_content_lpn_id := c_rec_kit_request_move.lpn_id;

            l_transaction_id := c_rec_kit_request_move.transaction_id;
            l_xmrs_kit_transaction_id := c_rec_kit_request_move.xmrs_kit_transaction_id;

            l_transaction_source_name := 'KIT_EXPLOSION_150';

            Begin
             select organization_id, subinventory_code, locator_id into
              l_content_org_id, l_content_subinventory_code, l_content_locator_id from wms_license_plate_numbers where
              lpn_id = l_content_lpn_id;
            Exception
              when no_data_found then
                apps.fnd_file.put_line (fnd_file.LOG,'Cannot find content lpn id: ' ||  l_content_lpn_id);
            End;

            Begin
             select organization_id, subinventory_code, locator_id, lpn_id into
              l_kit_org_id, l_kit_subinventory_code, l_kit_locator_id, l_kit_lpn_id from wms_license_plate_numbers where
              license_plate_number = l_kit_serial;
            Exception
              when no_data_found then
                apps.fnd_file.put_line (fnd_file.LOG,'Cannot find Kit serial: ' ||  l_kit_serial);
            End;

            apps.fnd_file.put_line (fnd_file.LOG,'Kit Serial: ' ||  l_kit_serial);
            apps.fnd_file.put_line (fnd_file.LOG,'Kit lpn ID: ' ||  l_kit_lpn_id);
            apps.fnd_file.put_line (fnd_file.LOG,'Content LPN: ' ||  l_content_lpn_id);
            apps.fnd_file.put_line (fnd_file.LOG,'Kit Sub: ' ||  l_kit_subinventory_code);
            apps.fnd_file.put_line (fnd_file.LOG,'Content Sub: ' ||  l_content_subinventory_code);
            apps.fnd_file.put_line (fnd_file.LOG,'Kit Loc: ' ||  l_kit_locator_id);
            apps.fnd_file.put_line (fnd_file.LOG,'Content Loc: ' ||  l_content_locator_id);
            apps.fnd_file.put_line (fnd_file.LOG,'Kit Org: ' ||  l_kit_org_id);
            apps.fnd_file.put_line (fnd_file.LOG,'Content Org: ' ||  l_content_org_id);

            IF ((l_content_org_id <> l_kit_org_id) or (l_kit_subinventory_code <> l_content_subinventory_code)
                or (l_content_locator_id <> l_kit_locator_id)) THEN
                apps.fnd_file.put_line (fnd_file.LOG,' The KIT Serial and the Content LPN are in differnt places: ');
                Continue;
            END IF;

      /***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/

            Begin
             select msi.organization_id, msi.segment1, mmt.subinventory_code, mmt.locator_id, xmrs.quantity,
             mmt.transaction_uom, msi.lot_control_code, msi.serial_number_control_code
             into l_org_id, l_item_code, l_subinventory_code, l_locator_id, l_quantity, l_uom,
              l_lot_control_code, l_serial_number_control_code
             from mtl_material_transactions mmt, mtl_system_items msi, XXOM_MAT_RCPT_STG xmrs
              where mmt.transaction_id = l_transaction_id and
                    xmrs.transaction_id = l_xmrs_kit_transaction_id and
                    xmrs.orig_transaction_id = mmt.transaction_id and
                    mmt.inventory_item_id = msi.inventory_item_id and
                    mmt.organization_id = msi.organization_id;
            Exception
              when no_data_found then
                apps.fnd_file.put_line (fnd_file.LOG,'Cannot find mmt record: ' ||  l_transaction_id);
            End;

/***
XXOM_MAT_RCPT_STG xmrs
          where mmt.transaction_id = p_transaction_id and
          xmrs.transaction_id = p_xmrs_transaction_id and
          xmrs.orig_transaction_id = mmt.transaction_id and
***/

            BEGIN
                SELECT disposition_id -- distribution_account
                  INTO   l_transaction_source_id
                  FROM   mtl_generic_dispositions
                 WHERE   organization_id = l_org_id
                   AND   SEGMENT1 = l_transaction_source_name; -- l_rec_acc_alias_name;
              EXCEPTION
                 WHEN no_data_found THEN
                  apps.fnd_file.put_line (fnd_file.LOG,'Cannot find distribution account for: ' || l_transaction_source_name );
              END;

      /***** Vishy: 08/05/2014: Used XMRS to get serial number and lot number *****
            IF (l_lot_control_code = 2 AND l_serial_number_control_code = 1) THEN

                select lot_number into l_lot_number from mtl_transaction_lot_numbers where transaction_id = l_transaction_id;
                l_serial_number := null;

              ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code <> 1) THEN

                select serial_number into l_serial_number from mtl_unit_transactions where transaction_id = l_transaction_id;
                l_lot_number := null;

              ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code = 1) THEN
                l_serial_number := null;
                l_lot_number := null;
            END IF;
           Commented this part and used the below queries ******/

  /***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/

            IF (l_lot_control_code = 2 AND l_serial_number_control_code = 1) THEN

                select lot_number into l_lot_number from XXOM_MAT_RCPT_STG where transaction_id = l_xmrs_kit_transaction_id;
                l_serial_number := null;

              ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code <> 1) THEN

                select serial_number into l_serial_number from XXOM_MAT_RCPT_STG where transaction_id = l_xmrs_kit_transaction_id;
                l_lot_number := null;

              ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code = 1) THEN
                l_serial_number := null;
                l_lot_number := null;
            END IF;

            BEGIN
                 SELECT   apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL
                   INTO   l_txn_header_id
                   FROM   DUAL;
              EXCEPTION
                WHEN OTHERS THEN
                  apps.fnd_file.put_line (fnd_file.LOG,'MTL_MATERIAL_TRANSACTIONS_S sequence errored out');
                  l_return_status := FND_API.G_RET_STS_ERROR;
            END;

             j := j+1;

                l_transaction_type_id := 89; -- Container UnPack
                apps.fnd_file.put_line (fnd_file.LOG,' Item to unpack: ' || l_kit_lpn_id);

                BEGIN
                 SELECT   apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL
                   INTO   l_txn_header_id
                   FROM   DUAL;
                EXCEPTION
                WHEN OTHERS THEN
                  apps.fnd_file.put_line (fnd_file.LOG,'MTL_MATERIAL_TRANSACTIONS_S sequence errored out');
                  l_return_status := FND_API.G_RET_STS_ERROR;
                END;

                    XXOM_CNSGN_MTL_XFER_PKG.consignment_transaction
                      (
                             p_source_code      => l_source_code,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_txn_header_id,
                             p_line_id          => j,
                             p_organization_id  => l_org_id, -- logic to decide whith one -- l_organization_id,
                             p_transaction_type_id => l_transaction_type_id,
                             p_subinventory     => l_subinventory_code,
                             p_inventory_location_id  => l_locator_id,
                             p_lpn              => l_content_lpn_id, --this should be moved to content lpn id
                             p_xfer_item        => l_item_code, -- l_xfer_item,
                             p_xfer_quantity    => (-1) * l_quantity, --l_xfer_quantity,
                             p_xfer_uom         => l_uom, -- l_xfer_uom,
                             p_lot_number       => l_lot_number,
                             p_serial_number    => l_serial_number,
                             p_to_organization_id  => null,
                             p_to_subinventory  => null, -- l_to_subinventory,
                             p_to_inventory_location_id  => null,
                             p_to_lpn           => l_kit_lpn_id, -- kit LPN,
                             p_reason_id        => null,
                             p_user_id          => FND_GLOBAL.USER_ID,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );

                        IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking lpn to kit --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking lpn to kit --> ' || l_return_status);
                        ELSE
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully unpacked the lpn to kit --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking lpn to kit --> ' || l_return_status);
                        END IF;

               /******
                     j := j+1;
                     l_transaction_type_id := 87; -- Container Pack from
                     apps.fnd_file.put_line (fnd_file.LOG,' Content LPN ID: ' || l_content_lpn_id);

                    XXOM_CNSGN_MTL_XFER_PKG.consignment_transaction
                      (
                             p_source_code      => l_source_code,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_txn_header_id,
                             p_line_id          => j,
                             p_organization_id  => l_org_id, -- logic to decide whith one -- l_organization_id,
                             p_transaction_type_id => l_transaction_type_id,
                             p_subinventory     => l_subinventory_code,
                             p_inventory_location_id  => l_locator_id,
                             p_lpn              => null, --this should be moved to content lpn id
                             p_xfer_item        => l_item_code, -- l_xfer_item,
                             p_xfer_quantity    => l_quantity, --l_xfer_quantity,
                             p_xfer_uom         => l_uom, -- l_xfer_uom,
                             p_lot_number       => l_lot_number,
                             p_serial_number    => l_serial_number,
                             p_to_organization_id  => null,
                             p_to_subinventory  => null, -- l_to_subinventory,
                             p_to_inventory_location_id  => null,
                             p_to_lpn           => l_kit_lpn_id, -- kit LPN,
                             p_reason_id        => null,
                             p_user_id          => FND_GLOBAL.USER_ID,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );

                        IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from packing LPN tp KIT --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from packing LPN tp KIT --> ' || l_return_status);
                        ELSE
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully packed LPN tp KIT--> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully packed LPN tp KIT --> ' || l_return_status);
                        END IF;

                ******/
               apps.fnd_file.put_line (fnd_file.LOG,'Before call TM: Header ID for reg txns: '|| l_txn_header_id);

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
                                            ,p_header_id => l_txn_header_id);

               IF x_return_status <> fnd_api.g_ret_sts_success THEN
                  IF x_msg_count > 0 THEN
                    FOR i IN 1 .. x_msg_count
                    LOOP
                        x_return_message := substr ( x_return_message || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 2000);
                        apps.fnd_file.put_line (fnd_file.LOG,'x_return_message for unpack/pack txn of lpn to kit: '|| x_return_message);
                    END LOOP;
                  END IF;
                 -- RAISE fnd_api.g_exc_error;
               END IF;

              apps.fnd_file.put_line (fnd_file.LOG,'After call TM: x_return_status for unpack/pack txn of lpn to kit:: '|| x_return_status);
              apps.fnd_file.put_line (fnd_file.LOG,'After call TM: x_return_message for unpack/pack txn of lpn to kit:: '|| x_return_message);

        END LOOP;

 /*** Vishy: 08/05/2014: Changes to unpack hospital consignment and to unpack multi-level LPNs *****/

  FOR c_rec_unpack_nonss_multilevel in c_unpack_nonss_multilevel LOOP

      l_lpn_id := c_rec_unpack_nonss_multilevel.lpn_id;

          BEGIN
             unpack_noss_multi_level
             (p_lpn_id => l_lpn_id,
              x_return_status => l_return_status,
              x_return_message => l_return_message);

            If (l_return_status  <> FND_API.G_RET_STS_SUCCESS) THEN
                apps.fnd_file.put_line ( fnd_file.LOG,
               'Error returned from unpackFloater for transaction ID: ' || l_transaction_id || ': ' || l_return_status);
               apps.fnd_file.put_line ( fnd_file.LOG,
               'Error Message: ' || l_transaction_id || ': ' || l_return_message);
            Else
               apps.fnd_file.put_line ( fnd_file.LOG,
               'Processed successfully for unpackFloater for transaction ID: ' || l_transaction_id || ': ' || l_return_status);
               apps.fnd_file.put_line ( fnd_file.LOG,
               'Success Message: ' || l_transaction_id || ': ' || l_return_message);
            End if;

          END;

        END LOOP;

 /**** End Changes *****/


     l_proc_status:= 'P';
     COMMIT;
                 apps.fnd_file.put_line (
                    fnd_file.LOG,
                    'In lv_count > 1: ' || lv_count
                 );
    -- Calling utl file procedure to generate flat file and place in ftp folder

      IF l_proc_status = 'P'
      THEN
      fnd_file.put_line (fnd_file.LOG, 'Starting Extract: ' || SQLERRM);
         INTG_INV_RCPT_EXP_PRC ;
    END IF;

EXCEPTION
WHEN OTHERS THEN
ROLLBACK;
      fnd_file.put_line (fnd_file.LOG, 'Cannot create an Extract file.. No Data loaded into Staging table: ' || SQLERRM);
END INTG_INV_RCPT_EXT_PRC;

PROCEDURE INTG_INV_RCPT_ERR_PRC ( p_msg         IN VARCHAR2,
                                  p_status      IN VARCHAR2,
                                  p_trans_id    IN NUMBER)
   -------------------------------------------------------------------------------------------------------------|
   --|   This Procedure(INTG_INV_RCPT_ERR_PRC ) used to send take care of error routine                         |
   -------------------------------------------------------------------------------------------------------------|
   IS
   BEGIN
      UPDATE   XXOM_MAT_RCPT_STG
         SET   status = p_status,
               message = p_msg
       WHERE   transaction_id = p_trans_id;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Log_msg: ' || SQLERRM);
   END INTG_INV_RCPT_ERR_PRC;

  PROCEDURE INTG_INV_RCPT_EXP_PRC
   --------------------------------------------------------------------------------------------
   --   This Procedure(INTG_INV_RCPT_EXP_PRC  ) will create the data files from staging tables
   --   INTG_SET_BKDN_STG and Update the date on the staging table with the current
   --   date and time as Exported_date and Exported_status as processed_date and 'Yes' .
   --------------------------------------------------------------------------------------------

   IS

      l_batch_no          NUMBER;
      l_comm_seq_no       NUMBER;
      l_errmsg            VARCHAR2(1000);
      l_division          VARCHAR2(100);

      l_file_handle   UTL_FILE.file_type;
      l_file_dir      VARCHAR2(100) := 'XXSGSFTOUT';
      l_file_name     VARCHAR2 (50);
      l_file_name1    VARCHAR2 (50);

      /****
      l_transaction_id NUMBER; -- Vishy 03/18/2014
      l_return_status varchar2(10); --Vishy 03/18/2014
      l_return_message varchar2(200); --Vishy 03/18/2014
      l_transaction_source_name varchar2(30); --Vishy 03/18/2014
      l_kit_serial  VARCHAR2(30); --Vishy 03/18/2014
      l_transaction_type_id NUMBER;
      l_transaction_source_id NUMBER;
      l_txn_int_id NUMBER;
      l_txn_batch_id NUMBER;
      l_txn_header_id NUMBER;
      l_source_code VARCHAR2 (30) := 'LPN Reconfig';
      l_org_id NUMBER;
      l_content_org_id NUMBER;
      l_kit_org_id NUMBER;
      l_content_subinventory_code VARCHAR2(10);
      l_content_locator_id NUMBER;
      l_kit_subinventory_code VARCHAR2(10);
      l_kit_locator_id NUMBER;
      j NUMBER := 0;
      l_kit_lpn_id NUMBER;
      l_content_lpn_id NUMBER;
      x_msg_count NUMBER;
      x_trans_count NUMBER;
      x_return_status varchar2(10); --Vishy 03/18/2014
      x_return_message varchar2(200); --Vishy 03/18/2014
      l_return NUMBER;
      l_item_code VARCHAR2(40);
      l_subinventory_code VARCHAR2(10);
      l_locator_id NUMBER;
      l_quantity NUMBER;
      l_uom VARCHAR2(3);
      l_lot_control_code NUMBER;
      l_serial_number_control_code NUMBER;
      l_lot_number VARCHAR2(80);
      l_serial_number  VARCHAR2(30);
      ****/


      CURSOR c_div
      IS
         SELECT distinct nvl(xsms.snm_division, 'nodiv') snm_division
           FROM XXOM_MAT_RCPT_STG xmrs, XXOM_SALES_MARKETING_SET_V xsms
          WHERE xmrs.MAT_RCPT_INTF_DATE IS NULL
            AND xmrs.inventory_item_id = xsms.inventory_item_id (+)
            AND xmrs.organization_id = xsms.organization_id (+)
          ORDER BY snm_division;


      CURSOR c1 (cp_division in varchar2)
      IS
         SELECT     xmrs.transaction_id,
            xmrs.orig_transaction_id,
            xmrs.transaction_date ,
            xmrs.oracle_trans_type ,
            xmrs.party_initiating_tfr ,
            xmrs.party_receiving_tfr,
            xmrs.item ,
            xmrs.is_set,
            xmrs.lot_serial_number,
            xmrs.expiration_date,
            xmrs.quantity,
            xmrs.date_transfer,
            xmrs.transfer_method,
            xmrs.tracking_number,
            xmrs.date_shipped,
            xmrs.deliver_to_address1 ,
            xmrs.deliver_to_address2 ,
            xmrs.deliver_to_city ,
            xmrs.deliver_to_state ,
            xmrs.deliver_to_zip ,
            xmrs.inventory_type,
            xmrs.transaction_reference,
            xmrs.order_number,
            xmrs.lot_number,
            xmrs.serial_number,
            xmrs.inventory_item_id -- Vishy: 03/21/2014 added this column to send them to SS
           FROM XXOM_MAT_RCPT_STG xmrs, XXOM_SALES_MARKETING_SET_V xsms
          WHERE xmrs.MAT_RCPT_INTF_DATE IS NULL
            AND xmrs.inventory_item_id = xsms.inventory_item_id (+)
            AND xmrs.organization_id = xsms.organization_id (+)
            AND nvl(xsms.snm_division, 'nodiv') = cp_division
           ORDER BY transaction_id;

  BEGIN

   FOR r_div in c_div LOOP
      l_division := r_div.snm_division;

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
        SELECT   XXOM_MAT_RCPT_SEQ.NEXTVAL
        INTO l_int_seq_no
        FROM DUAL;

         fnd_file.put_line (fnd_file.LOG, 'l_int_seq_no : ' || l_int_seq_no );
        EXCEPTION
        WHEN OTHERS THEN
            apps.fnd_file.put_line ( fnd_file.LOG,
               'Unable to fetch sequence l_int_seq_no value: ' || l_int_seq_no
            );
        END;

        apps.fnd_file.put_line ( fnd_file.LOG,
                           'In procedure1 INTG_INV_RCPT_EXT_PRC: ' || l_int_seq_no
           );

        -- Find the path where the file has to be stored.

        apps.fnd_file.put_line (
                      fnd_file.LOG,
                      'l_file_dir: ' || l_file_dir
                   );


                l_file_name  := l_comm_seq_no || '_INVR_' || l_int_seq_no ||'_'||l_division||'.tx1';
                l_file_name1 := l_comm_seq_no || '_INVR_' || l_int_seq_no ||'_'||l_division||'.txt';


            --l_file_name:= 'INVR'||l_int_seq_no||'.txt';
                   apps.fnd_file.put_line ( fnd_file.LOG,
                      'l_file_name: ' || l_file_name1
                   );
                l_file_handle := UTL_FILE.fopen (l_file_dir, l_file_name, 'w');

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
                    || 'ITEM'
                    || '|'
                    || 'IS_SET'
                    || '|'
                    || 'LOT_SERIAL_NUMBER'
                    || '|'
                    || 'EXPIRATION_DATE'
                    || '|'
                    || 'QUANTITY'
                    || '|'
                    || 'DATE_TRANSFER'
                    || '|'
                    || 'TRANSFER_METHOD'
                    || '|'
                    || 'TRACKING_NUMBER'
                    || '|'
                    || 'DATE_SHIPPED'
                    || '|'
                    || 'DELIVER_TO_ADDRESS1'
                    || '|'
                    || 'DELIVER_TO_ADDRESS2'
                    || '|'
                    || 'DELIVER_TO_CITY'
                    || '|'
                    || 'DELIVER_TO_STATE'
                    || '|'
                    || 'DELIVER_TO_ZIP'
                    || '|'
                    || 'INVENTORY_TYPE'
                    || '|'
                    || 'ORACLE_TRANSACTION_ID'
                    || '|'
                    ||  'TRANSACTION_REFERENCE'
                    || '|'
                    ||  'LOT_NUMBER'
                    || '|'
                    ||  'SERIAL_NUMBER'
                    || '|'


               );
      FOR c1_rec in c1(r_div.snm_division) LOOP

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
                  || c1_rec.inventory_item_id -- passing the id to SS 03/21/2014: Vishy
                  || '|'
                  || c1_rec.is_set
                  || '|'
                  || c1_rec.lot_serial_number
                  || '|'
                  || c1_rec.expiration_date
                  || '|'
                  || c1_rec.quantity
                  || '|'
                  || c1_rec.date_transfer
                  || '|'
                  || c1_rec.transfer_method
                  || '|'
                  || c1_rec.tracking_number||';Oracle#'||c1_rec.order_number
                  || '|'
                  || c1_rec.date_shipped
                  || '|'
                  || c1_rec.deliver_to_address1
                  || '|'
                  || c1_rec.deliver_to_address2
                  || '|'
                  || c1_rec.deliver_to_city
                  || '|'
                  || c1_rec.deliver_to_state
                  || '|'
                  || c1_rec.deliver_to_zip
                  || '|'
                  || c1_rec.inventory_type
                  || '|'
                  || c1_rec.orig_transaction_id
                  || '|'
                  || c1_rec.transaction_reference
                  || '|'
                  || c1_rec.lot_number
                  || '|'
                  || c1_rec.serial_number
                  || '|'
               );

          --  WHERE transaction_id = p_trans_id;

            UPDATE XXOM_MAT_RCPT_STG
            SET   status = 'SUCCESS',
                  message = 'File has been extracted and moved to '||l_file_dir,
                  MAT_RCPT_FILE_NAME = l_file_name1,
                  MAT_RCPT_INTF_DATE = sysdate
            WHERE transaction_id = c1_rec.transaction_id;



         END LOOP;

            UTL_FILE.fclose (l_file_handle);
            UTL_FILE.FRENAME(l_file_dir, l_file_name, l_file_dir, l_file_name1, TRUE);

            xxom_consgn_comm_ftp_pkg.add_new_file(l_file_name1); -- Provide actual file name as parameter.

         COMMIT;

     END LOOP; --Division


  --   xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends actual data file to surgisoft using sFTP. -- Jag commented: 06/07 -- Too many concurrent spawns.
     xxom_consgn_comm_ftp_pkg.GEN_CONF_FILE('Oracle_transfer_complete.txt','XXSGSFTOUT','XXSGSFTARCH'); -- This process generates confirmation file at the end.
  --   xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends/overwrites confirmation file to surgisoft using sFTP.

   EXCEPTION
      WHEN UTL_FILE.invalid_mode
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode Parameter');
        dbms_output.put_line('Invalid Mode Parameter');
      WHEN UTL_FILE.invalid_path
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Location');
         dbms_output.put_line('Invalid File Location');
      WHEN UTL_FILE.invalid_filehandle
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Filehandle');
         dbms_output.put_line('Invalid Filehandle');
      WHEN UTL_FILE.invalid_operation
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid Operation');
         dbms_output.put_line('Invalid Operation');
      WHEN UTL_FILE.read_error
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Read Error');
         dbms_output.put_line('Read Error');
      WHEN UTL_FILE.internal_error
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Internal Error');
         dbms_output.put_line('Internal Error');
      WHEN UTL_FILE.charsetmismatch
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Opened With FOPEN_NCHAR But Later I/O Inconsistent');
         dbms_output.put_line(
                 'Opened With FOPEN_NCHAR
       But Later I/O Inconsistent'
                );
      WHEN UTL_FILE.file_open
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Already Opened');
         dbms_output.put_line('File Already Opened');
      WHEN UTL_FILE.invalid_maxlinesize
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Line Size Exceeds 32K');
         dbms_output.put_line('Line Size Exceeds 32K');
      WHEN UTL_FILE.invalid_filename
      THEN
          fnd_file.put_line (fnd_file.LOG, 'Invalid File Name');
         dbms_output.put_line('Invalid File Name');
      WHEN UTL_FILE.access_denied
      THEN
         fnd_file.put_line (fnd_file.LOG, 'File Access Denied By');
        dbms_output.put_line('File Access Denied By');
      WHEN UTL_FILE.invalid_offset
      THEN
         fnd_file.put_line (fnd_file.LOG, 'FSEEK Param Less Than 0');
        dbms_output.put_line('FSEEK Param Less Than 0');
      WHEN OTHERS
      THEN
        fnd_file.put_line (fnd_file.LOG, 'Unknown UTL_FILE Error'||to_char(sqlcode)||'-'||substr(sqlerrm,1,500));
         dbms_output.put_line('Unknown UTL_FILE Error');
       --  retcode:= 2;
       --  errbuf:= TO_CHAR(sqlcode)||'-'||SUBSTR (SQLERRM, 1, 255);
   END INTG_INV_RCPT_EXP_PRC ;

     /***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/

   PROCEDURE unpackFloater( p_transaction_id IN NUMBER,
                            p_xmrs_transaction_id IN NUMBER,
                            x_return_status OUT NOCOPY VARCHAR2,
                            x_return_message OUT NOCOPY VARCHAR2)

   IS

    /*** Variables for FI Customization Vishy: 03/18/2014 ****/
    l_source_code VARCHAR2 (30) := 'Container Unpack';
    l_transaction_source_type_id NUMBER;
    l_transaction_action_id NUMBER;
    l_txn_source_line_id NUMBER;
    l_item_id  NUMBER;
    l_org_id NUMBER;
    l_transfer_org_id NUMBER;
    l_org_code VARCHAR2(3);
    l_transfer_org_code VARCHAR2(3);
    l_item_type VARCHAR2(30);
    l_lot_control_code NUMBER;
    l_serial_number_control_code NUMBER;
    l_item_code VARCHAR2(40);
    l_sold_to_org_id NUMBER;
    l_transaction_type_name VARCHAR2(30);
    l_txn_header_id NUMBER;
    l_transaction_source_name varchar2(30);
    l_transaction_source_id NUMBER;
    l_transaction_type_id NUMBER;
    l_subinventory_code VARCHAR2(10);
    l_locator_id NUMBER;
    l_lpn_id NUMBER;
    l_quantity NUMBER;
    l_uom VARCHAR2(3);
    l_return_status VARCHAR2(20);
    l_return_message VARCHAR2(200);
    l_lot_number VARCHAR2(80);
    l_serial_number  VARCHAR2(30);
    x_msg_count NUMBER;
    x_trans_count NUMBER;
    l_return NUMBER;

   BEGIN
    /*** Begin Gaeaglobal Technologies - Customization
        Vishy Parthasarathy - 18-March-2014
        This procedure will automatically unpack the items from the LPN for the fol. scenarios:
        1. Transaction source type id = 7 and transaction action id = 3 Internal Req Direct Org Transfer
        2. Destination organization = 150
        3. For line type of ILS Consignment Request
        4. The item should not be of type Kit 'K' ****/

        apps.fnd_file.put_line (fnd_file.LOG,'Entered Post processing to unpack floating stock: Transaction ID: ' || p_transaction_id);
        l_return_status := FND_API.G_RET_STS_SUCCESS;

      BEGIN

       select mmt.transaction_source_type_id, mmt.transaction_action_id, mmt.trx_source_line_id, mmt.inventory_item_id,
          mmt.organization_id, mmt.transfer_organization_id, mp1.organization_code, msi.item_type,
          msi.lot_control_code, msi.serial_number_control_code, msi.segment1, mmt.subinventory_code, mmt.locator_id,
          mmt.content_lpn_id, xmrs.quantity, mmt.transaction_uom
            into l_transaction_source_type_id, l_transaction_action_id, l_txn_source_line_id,l_item_id, l_org_id, l_transfer_org_id,
            l_org_code, l_item_type, l_lot_control_code, l_serial_number_control_code,l_item_code, l_subinventory_code, l_locator_id,
            l_lpn_id, l_quantity, l_uom
          from mtl_material_transactions mmt, mtl_parameters mp1, mtl_system_items msi, XXOM_MAT_RCPT_STG xmrs
          where mmt.transaction_id = p_transaction_id and
          xmrs.transaction_id = p_xmrs_transaction_id and
          xmrs.orig_transaction_id = mmt.transaction_id and
          mmt.organization_id = mp1.organization_id and
          msi.organization_id = mmt.organization_id and
          msi.inventory_item_id = mmt.inventory_item_id;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          apps.fnd_file.put_line (fnd_file.LOG,'No data found for transaction id' || p_transaction_id);
       WHEN OTHERS THEN
          apps.fnd_file.put_line (fnd_file.LOG,'Exception while finding the inter-org receipt record '||sqlerrm);
          l_return_status := FND_API.G_RET_STS_ERROR;
       END;

              apps.fnd_file.put_line (fnd_file.LOG,'The transaction is direct org to 150. Item: ' || l_item_code);
              apps.fnd_file.put_line (fnd_file.LOG,'Source type: ' || l_transaction_source_type_id);
              apps.fnd_file.put_line (fnd_file.LOG,'Action ID: ' || l_transaction_action_id);

       --  dbms_output.put_line('1');
      if (l_transaction_source_type_id = 7 and l_transaction_action_id = 3 and l_org_code = '150') then

            apps.fnd_file.put_line (fnd_file.LOG,'The transaction is direct org to 150. Item: ' || l_item_code);

            BEGIN
              SELECT oeh.sold_to_org_id, oet.name
                INTO  l_sold_to_org_id, l_transaction_type_name
                FROM   oe_order_headers_all oeh, oe_transaction_types_tl oet,
                OE_TRANSACTION_TYPES_ALL a,oe_order_lines_all ool
                WHERE ool.line_id = l_txn_source_line_id and oeh.header_id = ool.header_id and ool.line_type_id = a.transaction_type_id
                and a.transaction_type_id = oet.transaction_type_id and
                oet.language = (Select language_code from fnd_languages where installed_flag = 'B');

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                    inv_log_util.trace('No data found for source line id: ' || l_txn_source_line_id , 'INV_TXNSTUB_PUB', 9);
               WHEN OTHERS THEN
                inv_log_util.trace('Exception while finding the inter-org receipt record '||sqlerrm, 'INV_TXNSTUB_PUB', 9);
                l_return_status := FND_API.G_RET_STS_ERROR;
            END;
        --    dbms_output.put_line('2');
              apps.fnd_file.put_line (fnd_file.LOG,'Transaction Type name: ' || l_transaction_type_name);
              apps.fnd_file.put_line (fnd_file.LOG,'Item Type: ' || l_item_type);
              apps.fnd_file.put_line (fnd_file.LOG,'Lot Control Code: ' || l_lot_control_code);
              apps.fnd_file.put_line (fnd_file.LOG,'Serial Control Code: ' || l_serial_number_control_code);

        if (l_transaction_type_name like '%Consignment%Request%' and l_item_type <> 'K') then

            l_transaction_source_name := 'KIT_EXPLOSION_150';
            dbms_output.put_line('3');
            BEGIN
                SELECT disposition_id -- distribution_account
                  INTO   l_transaction_source_id
                  FROM   mtl_generic_dispositions
                 WHERE   organization_id = l_org_id
                   AND   SEGMENT1 = l_transaction_source_name; -- l_rec_acc_alias_name;
              EXCEPTION
                 WHEN OTHERS THEN
                  apps.fnd_file.put_line (fnd_file.LOG,'Cannot find distribution account for: ' || l_transaction_source_name );
              END;

            BEGIN
                 SELECT   apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL
                   INTO   l_txn_header_id
                   FROM   DUAL;
              EXCEPTION
                WHEN OTHERS THEN
                  apps.fnd_file.put_line (fnd_file.LOG,'MTL_MATERIAL_TRANSACTIONS_S sequence errored out');
            END;

     /***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing for unpack and kitting request****/

            IF (l_lot_control_code = 2 AND l_serial_number_control_code = 1) THEN

                select lot_number into l_lot_number from XXOM_MAT_RCPT_STG where transaction_id = p_xmrs_transaction_id;
                l_serial_number := null;

              ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code <> 1) THEN

                select serial_number into l_serial_number from XXOM_MAT_RCPT_STG where transaction_id = p_xmrs_transaction_id;
                l_lot_number := null;

              ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code = 1) THEN
                l_serial_number := null;
                l_lot_number := null;
            END IF;

         --   dbms_output.put_line('4');


                  l_transaction_type_id := 88; -- Container Unpack
                  apps.fnd_file.put_line (fnd_file.LOG,' Item to unpack: ' || l_item_id);

                    XXOM_CNSGN_MTL_XFER_PKG.consignment_transaction
                      (
                             p_source_code      => l_source_code,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_txn_header_id,
                             p_line_id          => 1,
                             p_organization_id  => l_org_id, -- logic to decide whith one -- l_organization_id,
                             p_transaction_type_id => l_transaction_type_id,
                             p_subinventory     => l_subinventory_code,
                             p_inventory_location_id  => l_locator_id,
                             p_lpn              => l_lpn_id,
                             p_xfer_item        => l_item_code, -- l_xfer_item,
                             p_xfer_quantity    => (-1) * l_quantity, --l_xfer_quantity,
                             p_xfer_uom         => l_uom, -- l_xfer_uom,
                             p_lot_number       => l_lot_number,
                             p_serial_number    => l_serial_number,
                             p_to_organization_id  => null,
                             p_to_subinventory  => null, -- l_to_subinventory,
                             p_to_inventory_location_id  => null,
                             p_to_lpn           => null, -- p_to_container,
                             p_reason_id        => null,
                             p_user_id          => FND_GLOBAL.USER_ID,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );

                        IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_status);
                          apps.fnd_file.put_line (fnd_file.LOG,' item  --> '|| l_item_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' serial  --> ' || l_serial_number);
                          apps.fnd_file.put_line (fnd_file.LOG,' lpn  --> ' || l_lpn_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' lot  --> ' || l_lot_number);
                        ELSE
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully unpacked the item --> ' || l_item_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully unpacked the item --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_status);
                          apps.fnd_file.put_line (fnd_file.LOG,' serial  --> ' || l_serial_number);
                          apps.fnd_file.put_line (fnd_file.LOG,' lpn  --> ' || l_lpn_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' lot  --> ' || l_lot_number);
                        END IF;

               apps.fnd_file.put_line (fnd_file.LOG,'Before call TM: Header ID for reg txns: '|| l_txn_header_id);

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
                                            ,p_header_id => l_txn_header_id);

               IF x_return_status <> fnd_api.g_ret_sts_success THEN
                  IF x_msg_count > 0 THEN
                    FOR i IN 1 .. x_msg_count
                    LOOP
                        x_return_message := substr ( x_return_message || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 2000);
                        apps.fnd_file.put_line (fnd_file.LOG,'x_return_message for regular txns: '|| x_return_message);
                    END LOOP;
                  END IF;
                 -- RAISE fnd_api.g_exc_error;
               END IF;

              apps.fnd_file.put_line (fnd_file.LOG,'After call TM: Status Reg txns: '|| l_return_status);
         /*********

            IF (l_lot_control_code = 2 AND l_serial_number_control_code = 1) THEN
                dbms_output.put_line('5');
                apps.fnd_file.put_line (fnd_file.LOG,'Inside Lot control');

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
                                                             lpn_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                         )
                                select
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
                                          organization_id, -- Check
                                          -1* transaction_quantity,
                                          transaction_uom,
                                          sysdate, --to_date(c1_rec.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          null,
                                          88,--Container Unpack
                                          inventory_item_id,
                                          subinventory_code,
                                          revision,
                                          l_txn_int_id,
                                          l_transaction_source_id,
                                          'TRA_REF_UP',
                                          locator_id,
                                          null,
                                          null,
                                          null,
                                          null,
                                          content_lpn_id,
                                          l_txn_batch_id,
                                          1, --Sequence
                                          l_txn_header_id
                                        from mtl_material_transactions where transaction_id = p_transaction_id;



                     EXCEPTION
                        WHEN OTHERS THEN
                          apps.fnd_file.put_line (fnd_file.LOG,'Unable to insert into MMT for lot control item: '|| sqlerrm||
                          ': ' || l_txn_int_id);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                     END;

                    dbms_output.put_line('6');

                     BEGIN
                            INSERT INTO apps.mtl_transaction_lots_interface (
                                                                        transaction_interface_id,
                                                                        source_code,
                                                                        source_line_id,
                                                                        lot_number,
                                                                       -- lot_expiration_date,
                                                                        transaction_quantity,
                                                                        last_update_date,
                                                                        last_updated_by,
                                                                        creation_date,
                                                                        created_by
                                                                        )
                             select
                              l_txn_int_id,     --transaction interface_id
                                l_source_code,          --source code
                                1,                    --source line id
                                lot_number,      -- lot number
                               -- expiration_date,
                                transaction_quantity,
                                SYSDATE,
                                FND_GLOBAL.USER_ID,
                                SYSDATE,
                                FND_GLOBAL.USER_ID from mtl_transaction_lot_numbers where transaction_id = p_transaction_id;


                     EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (fnd_file.LOG,'Unable to insert into MTLN for lot control item : '||sqlerrm || ': '
                        || l_txn_int_id);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                     END;
                      dbms_output.put_line('7');
                ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code <> 1) THEN

                   BEGIN
                         dbms_output.put_line('8');
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
                                                             lpn_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                         )
                                select
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
                                          organization_id, -- Check
                                          -1* transaction_quantity,
                                          transaction_uom,
                                          sysdate, --to_date(c1_rec.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          null,
                                          88,--Container Unpack
                                          inventory_item_id,
                                          subinventory_code,
                                          revision,
                                          l_txn_int_id,
                                          l_transaction_source_id,
                                          'TRA_REF_UP',
                                          locator_id,
                                          null,
                                          null,
                                          null,
                                          null,
                                          content_lpn_id,
                                          l_txn_batch_id,
                                          1, --Sequence
                                          l_txn_header_id
                                        from mtl_material_transactions where transaction_id = p_transaction_id;

                     EXCEPTION
                        WHEN OTHERS THEN
                          apps.fnd_file.put_line (fnd_file.LOG,'Unable to insert into MMT for lot control item: ' ||sqlerrm || ': '
                          || l_txn_int_id);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                     END;
                       dbms_output.put_line('9');
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
                         select l_txn_int_id,
                                   l_source_code,
                                   serial_number,
                                   serial_number,
                                   SYSDATE,
                                   FND_GLOBAL.USER_ID,
                                   SYSDATE,
                                   FND_GLOBAL.USER_ID from mtl_unit_transactions where transaction_id = p_transaction_id;

                        EXCEPTION
                        WHEN OTHERS THEN
                            apps.fnd_file.put_line (fnd_file.LOG,'Unable to insert into MUT for lot control item: '||sqlerrm || ': '
                            || l_txn_int_id);
                          x_return_status := FND_API.G_RET_STS_ERROR;
                    END;
                     dbms_output.put_line('10');
                ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code = 1) THEN

                    BEGIN
                         dbms_output.put_line('11');
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
                                                             lpn_id,
                                                             transaction_batch_id,
                                                             transaction_batch_seq,
                                                             transaction_header_id
                                         )
                                select
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
                                          organization_id, -- Check
                                          -1* transaction_quantity,
                                          transaction_uom,
                                          sysdate, --to_date(c1_rec.transaction_date, 'DD-MON-YYYY HH24:MI:SS'),
                                          null,
                                          88,--Container Unpack
                                          inventory_item_id,
                                          subinventory_code,
                                          revision,
                                          l_txn_int_id,
                                          l_transaction_source_id,
                                          'TRA_REF_UP',
                                          locator_id,
                                          null,
                                          null,
                                          null,
                                          null,
                                          content_lpn_id,
                                          l_txn_batch_id,
                                          1, --Sequence
                                          l_txn_header_id
                                        from mtl_material_transactions where transaction_id = p_transaction_id;

                     EXCEPTION
                        WHEN OTHERS THEN
                        apps.fnd_file.put_line (fnd_file.LOG,'Unable to insert into MMT for lot control item: '||sqlerrm || ': '
                        || l_txn_int_id);
                        x_return_status := FND_API.G_RET_STS_ERROR;
                     END;
                      dbms_output.put_line('12');
                 END IF;
          ******/
          end if;

           dbms_output.put_line('13');

      end if;

       dbms_output.put_line('14');

      x_return_status := FND_API.G_RET_STS_SUCCESS;

  END;

  /*** Vishy: 08/05/2014: Changes to unpack hospital consignment and to unpack multi-level LPNs *****/
   PROCEDURE unpack_noss_multi_level( p_lpn_id IN NUMBER,
                          x_return_status OUT NOCOPY VARCHAR2,
                          x_return_message OUT NOCOPY VARCHAR2)

   IS

    /*** Variables for FI Customization Vishy: 03/18/2014 ****/
    l_source_code VARCHAR2 (30) := 'Container Unpack';
    l_transaction_source_type_id NUMBER;
    l_transaction_action_id NUMBER;
    l_txn_source_line_id NUMBER;
    l_item_id  NUMBER;
    l_org_id NUMBER;
    l_transfer_org_id NUMBER;
    l_org_code VARCHAR2(3);
    l_transfer_org_code VARCHAR2(3);
    l_item_type VARCHAR2(30);
    l_lot_control_code NUMBER;
    l_serial_number_control_code NUMBER;
    l_item_code VARCHAR2(40);
    l_sold_to_org_id NUMBER;
    l_transaction_type_name VARCHAR2(30);
    l_txn_header_id NUMBER;
    l_transaction_source_name varchar2(30);
    l_transaction_source_id NUMBER;
    l_transaction_type_id NUMBER;
    l_subinventory_code VARCHAR2(10);
    l_locator_id NUMBER;
    l_lpn_id NUMBER;
    l_quantity NUMBER;
    l_uom VARCHAR2(3);
    l_return_status VARCHAR2(20);
    l_return_message VARCHAR2(200);
    l_lot_number VARCHAR2(80);
    l_serial_number  VARCHAR2(30);
    x_msg_count NUMBER;
    x_trans_count NUMBER;
    l_return NUMBER;

    cursor c_unpack_lpn (p_lpn_id number) is
      select wlc.inventory_item_id, wlpn.organization_id, mp.organization_code, msi.item_type,
          msi.lot_control_code, msi.serial_number_control_code, msi.segment1, wlpn.subinventory_code, wlpn.locator_id,
          wlc.quantity, wlc.uom_code, wlc.lot_number
          from wms_license_plate_numbers wlpn, wms_lpn_contents wlc, mtl_parameters mp, mtl_system_items msi
          where wlpn.lpn_id = p_lpn_id and wlc.parent_lpn_id = wlpn.lpn_id and
          wlpn.organization_id = mp.organization_id and wlpn.organization_id = msi.organization_id and
          wlc.inventory_item_id = msi.inventory_item_id;

/***** Gaea: VishyP 07-OCT-2014: Added join between MSN and WLPN on LPN ID. There may be same item with multiple serials
that may be loose in the same sub and locator which we do not want to unpack *****/

    Cursor c_serial_unpack (p_lpn_id number, l_item_id number, l_org_id number) is
     select msn.serial_number from mtl_serial_numbers msn, wms_lpn_contents wlc, wms_license_plate_numbers wlpn
                where wlpn.lpn_id = p_lpn_id and wlpn.lpn_id = wlc.parent_lpn_id and wlc.inventory_item_id = l_item_id and 
                wlpn.organization_id = l_org_id and wlpn.organization_id = msn.current_organization_id and
                wlpn.subinventory_code = msn.current_subinventory_code and wlpn.locator_id = msn.current_locator_id and 
                wlc.inventory_item_id = msn.inventory_item_id and wlpn.lpn_id = msn.lpn_id and msn.current_status = 3;

   BEGIN
    /*** Begin Gaeaglobal Technologies - Customization
        Vishy Parthasarathy - 18-March-2014
        This procedure will automatically unpack the items from the LPN for the fol. scenarios:
        1. Transaction source type id = 7 and transaction action id = 3 Internal Req Direct Org Transfer
        2. Destination organization = 150
        3. For line type of ILS Consignment Request
        4. The item should not be of type Kit 'K' ****/

        apps.fnd_file.put_line (fnd_file.LOG,'Entered Post processing to unpack noss and multi-level: LPN ID: ' || p_lpn_id);
        l_return_status := FND_API.G_RET_STS_SUCCESS;

    For c_rec_unpack_lpn IN c_unpack_lpn (p_lpn_id) Loop

        l_item_id := c_rec_unpack_lpn.inventory_item_id;
        l_org_id := c_rec_unpack_lpn.organization_id;
        l_org_code := c_rec_unpack_lpn.organization_code;
        l_item_type := c_rec_unpack_lpn.item_type;
        l_lot_control_code := c_rec_unpack_lpn.lot_control_code;
        l_serial_number_control_code := c_rec_unpack_lpn.serial_number_control_code;
        l_item_code := c_rec_unpack_lpn.segment1;
        l_subinventory_code := c_rec_unpack_lpn.subinventory_code;
        l_locator_id := c_rec_unpack_lpn.locator_id;
        l_quantity := c_rec_unpack_lpn.quantity;
        l_uom := c_rec_unpack_lpn.uom_code;
        l_lot_number := c_rec_unpack_lpn.lot_number;

        apps.fnd_file.put_line (fnd_file.LOG,'The transaction is direct org to 150. Item: ' || l_item_code);
        apps.fnd_file.put_line (fnd_file.LOG,'The transaction is direct org to 150. Item: ' || l_item_code);
        apps.fnd_file.put_line (fnd_file.LOG,'Transaction Type name: ' || l_transaction_type_name);
        apps.fnd_file.put_line (fnd_file.LOG,'Item Type: ' || l_item_type);
        apps.fnd_file.put_line (fnd_file.LOG,'Lot Control Code: ' || l_lot_control_code);
        apps.fnd_file.put_line (fnd_file.LOG,'Serial Control Code: ' || l_serial_number_control_code);

      If (l_org_code = '150') and (l_item_type <> 'K') Then

            l_transaction_source_name := 'KIT_EXPLOSION_150';

            BEGIN
                SELECT disposition_id -- distribution_account
                  INTO   l_transaction_source_id
                  FROM   mtl_generic_dispositions
                 WHERE   organization_id = l_org_id
                   AND   SEGMENT1 = l_transaction_source_name; -- l_rec_acc_alias_name;
              EXCEPTION
                 WHEN OTHERS THEN
                  apps.fnd_file.put_line (fnd_file.LOG,'Cannot find distribution account for: ' || l_transaction_source_name );
              END;

            BEGIN
                 SELECT   apps.MTL_MATERIAL_TRANSACTIONS_S.NEXTVAL
                   INTO   l_txn_header_id
                   FROM   DUAL;
              EXCEPTION
                WHEN OTHERS THEN
                  apps.fnd_file.put_line (fnd_file.LOG,'MTL_MATERIAL_TRANSACTIONS_S sequence errored out');
            END;
   /**** If item is serial controlled, we will have to handle it differently ****/

           If (l_lot_control_code = 2 AND l_serial_number_control_code = 1) THEN

                l_serial_number := null;

           ELSIF (l_lot_control_code = 1 AND l_serial_number_control_code = 1) THEN

                l_serial_number := null;
                l_lot_number := null;

            END IF;

         If (l_serial_number_control_code <> 1 ) and (l_lot_control_code = 1) Then

          for c_rec_serial_unpack in c_serial_unpack (p_lpn_id, l_item_id, l_org_id) loop
              l_lot_number := null;
              l_quantity := 1;
              l_serial_number := c_rec_serial_unpack.serial_number;

               l_transaction_type_id := 88; -- Container Unpack
                  apps.fnd_file.put_line (fnd_file.LOG,' Item to unpack: ' || l_item_id);

                    XXOM_CNSGN_MTL_XFER_PKG.consignment_transaction
                      (
                             p_source_code      => l_source_code,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_txn_header_id,
                             p_line_id          => 1,
                             p_organization_id  => l_org_id, -- logic to decide whith one -- l_organization_id,
                             p_transaction_type_id => l_transaction_type_id,
                             p_subinventory     => l_subinventory_code,
                             p_inventory_location_id  => l_locator_id,
                             p_lpn              => p_lpn_id,
                             p_xfer_item        => l_item_code, -- l_xfer_item,
                             p_xfer_quantity    => (-1) * l_quantity, --l_xfer_quantity,
                             p_xfer_uom         => l_uom, -- l_xfer_uom,
                             p_lot_number       => l_lot_number,
                             p_serial_number    => l_serial_number,
                             p_to_organization_id  => null,
                             p_to_subinventory  => null, -- l_to_subinventory,
                             p_to_inventory_location_id  => null,
                             p_to_lpn           => null, -- p_to_container,
                             p_reason_id        => null,
                             p_user_id          => FND_GLOBAL.USER_ID,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );

                        IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_status);
                          apps.fnd_file.put_line (fnd_file.LOG,' item  --> '|| l_item_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' serial  --> ' || l_serial_number);
                          apps.fnd_file.put_line (fnd_file.LOG,' lpn  --> ' || l_lpn_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' lot  --> ' || l_lot_number);
                        ELSE
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully unpacked the item --> ' || l_item_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully unpacked the item --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_status);
                          apps.fnd_file.put_line (fnd_file.LOG,' serial  --> ' || l_serial_number);
                          apps.fnd_file.put_line (fnd_file.LOG,' lpn  --> ' || l_lpn_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' lot  --> ' || l_lot_number);
                        END IF;

               apps.fnd_file.put_line (fnd_file.LOG,'Before call TM: Header ID for reg txns: '|| l_txn_header_id);

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
                                            ,p_header_id => l_txn_header_id);

               IF x_return_status <> fnd_api.g_ret_sts_success THEN
                  IF x_msg_count > 0 THEN
                    FOR i IN 1 .. x_msg_count
                    LOOP
                        x_return_message := substr ( x_return_message || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 2000);
                        apps.fnd_file.put_line (fnd_file.LOG,'x_return_message for regular txns: '|| x_return_message);
                    END LOOP;
                  END IF;
                 -- RAISE fnd_api.g_exc_error;
               END IF;

              apps.fnd_file.put_line (fnd_file.LOG,'After call TM: Status Reg txns: '|| l_return_status);

            x_return_status := FND_API.G_RET_STS_SUCCESS;

          end loop;

        else

                  l_transaction_type_id := 88; -- Container Unpack
                  apps.fnd_file.put_line (fnd_file.LOG,' Item to unpack: ' || l_item_id);

                    XXOM_CNSGN_MTL_XFER_PKG.consignment_transaction
                      (
                             p_source_code      => l_source_code,
                             p_transaction_source_id => l_transaction_source_id,
                             p_header_id        => l_txn_header_id,
                             p_line_id          => 1,
                             p_organization_id  => l_org_id, -- logic to decide whith one -- l_organization_id,
                             p_transaction_type_id => l_transaction_type_id,
                             p_subinventory     => l_subinventory_code,
                             p_inventory_location_id  => l_locator_id,
                             p_lpn              => p_lpn_id,
                             p_xfer_item        => l_item_code, -- l_xfer_item,
                             p_xfer_quantity    => (-1) * l_quantity, --l_xfer_quantity,
                             p_xfer_uom         => l_uom, -- l_xfer_uom,
                             p_lot_number       => l_lot_number,
                             p_serial_number    => l_serial_number,
                             p_to_organization_id  => null,
                             p_to_subinventory  => null, -- l_to_subinventory,
                             p_to_inventory_location_id  => null,
                             p_to_lpn           => null, -- p_to_container,
                             p_reason_id        => null,
                             p_user_id          => FND_GLOBAL.USER_ID,
                             p_return_status    => l_return_status,
                             p_return_message   => l_return_message
                      );

                        IF (l_return_status <> fnd_api.g_ret_sts_success) THEN
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_status);
                          apps.fnd_file.put_line (fnd_file.LOG,' item  --> '|| l_item_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' serial  --> ' || l_serial_number);
                          apps.fnd_file.put_line (fnd_file.LOG,' lpn  --> ' || l_lpn_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' lot  --> ' || l_lot_number);
                        ELSE
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully unpacked the item --> ' || l_item_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' Successfully unpacked the item --> ' || l_return_message);
                          apps.fnd_file.put_line (fnd_file.LOG,' Message from unpacking missing item --> ' || l_return_status);
                          apps.fnd_file.put_line (fnd_file.LOG,' serial  --> ' || l_serial_number);
                          apps.fnd_file.put_line (fnd_file.LOG,' lpn  --> ' || l_lpn_id);
                          apps.fnd_file.put_line (fnd_file.LOG,' lot  --> ' || l_lot_number);
                        END IF;

               apps.fnd_file.put_line (fnd_file.LOG,'Before call TM: Header ID for reg txns: '|| l_txn_header_id);

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
                                            ,p_header_id => l_txn_header_id);

               IF x_return_status <> fnd_api.g_ret_sts_success THEN
                  IF x_msg_count > 0 THEN
                    FOR i IN 1 .. x_msg_count
                    LOOP
                        x_return_message := substr ( x_return_message || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F'), 2000);
                        apps.fnd_file.put_line (fnd_file.LOG,'x_return_message for regular txns: '|| x_return_message);
                    END LOOP;
                  END IF;
                 -- RAISE fnd_api.g_exc_error;
               END IF;

              apps.fnd_file.put_line (fnd_file.LOG,'After call TM: Status Reg txns: '|| l_return_status);

            x_return_status := FND_API.G_RET_STS_SUCCESS;
        End If;

      End if;

      End Loop;

  END;

  /**** End Chnages: 08/05/2014 ****/

END XXOM_MAT_RCPT_PKG; 
/
