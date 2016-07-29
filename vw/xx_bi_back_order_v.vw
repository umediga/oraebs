DROP VIEW APPS.XX_BI_BACK_ORDER_V;

/* Formatted on 6/6/2016 4:59:58 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_BACK_ORDER_V
(
   ORDER_NUMBER,
   LINE_NUMBER,
   ORDERED_QUANTITY,
   CUSTOMER_NAME,
   TERRITORY,
   WAREHOUSE,
   ITEM,
   DESCRIPTION,
   UOM,
   SHIPPING_QUANTITY,
   SHIP_METHOD,
   REQUEST_DATE,
   SCHEDULE_DATE,
   SUBINVENTORY,
   SUBINVENTORY_DESCRIPTION,
   LOT_NUMBER,
   LOT_EXPIRATION_DATE,
   AVAILABLE_QUANTITY,
   JOB,
   WORK_ORDER_QUANTITY,
   SCHEDULED_COMPLETION_DATE,
   DIVISION,
   ITEM_TYPE_CODE,
   LINE_CATEGORY_CODE,
   PARTY_TYPE,
   ACCOUNT_NAME,
   EXPENSE_ACCOUNT,
   ITEM_TYPE,
   MATERIAL_ACCOUNT,
   OPERATING_UNIT,
   ORGANIZATION_NAME,
   LOCATION_ID
)
AS
   (SELECT order_number "ORDER_NUMBER",
           ool.line_number "LINE_NUMBER",
           ool.ordered_quantity "Ordered Quantity",
           hp.party_name "CUSTOMER_NAME",
           (SELECT a.description
              FROM fnd_territories_tl a,
                   hr_locations_all b,
                   hr_all_organization_units c
             WHERE     a.LANGUAGE = USERENV ('LANG')
                   AND a.territory_code = b.country
                   AND b.location_id = c.location_id
                   AND c.organization_id = ood.organization_id
                   AND c.business_group_id = ood.business_group_id)
              territory,                 --L.TERRITORY_SHORT_NAME "TERRITORY",
           ood.organization_code "Warehouse",
           ool.ordered_item "Item",
           msib.description "DESCRIPTION",
           ool.order_quantity_uom "UOM",
           ool.shipping_quantity "QTY",
           (SELECT meaning
              FROM apps.fnd_lookup_values
             WHERE     lookup_code = ool.shipping_method_code
                   AND lookup_type = 'SHIP_METHOD'
                   AND LANGUAGE = USERENV ('LANG'))
              "Ship_Method",
           ool.request_date "REQUEST_DATE",
           ool.schedule_ship_date "SCHEDULE_DATE",
           msu.secondary_inventory_name,
           msu.description subinventory_description,
           mln.lot_number lot_number,
           mln.expiration_date lot_expire_dt,
           moqd.primary_transaction_quantity tran_qty,
           we.wip_entity_name,
           (wdj.start_quantity - wdj.quantity_completed) qty,
           wdj.scheduled_completion_date scheduled_completion_date,
           (SELECT mcb.segment4
              FROM mtl_item_categories mic,
                   mtl_category_sets_tl mcst,
                   mtl_category_sets_b mcsb,
                   mtl_categories_b mcb
             WHERE     mcst.category_set_id = mcsb.category_set_id
                   AND mcst.LANGUAGE = USERENV ('LANG')
                   AND mic.category_set_id = mcsb.category_set_id
                   AND mic.category_id = mcb.category_id
                   AND mcst.category_set_name = 'Sales and Marketing'
                   AND mic.inventory_item_id = msib.inventory_item_id
                   AND mic.organization_id = msib.organization_id)
              division,
           ool.item_type_code,
           ool.line_category_code,
           hp.party_type,
           hca.account_name,
           msib.expense_account,
           msib.item_type,
           msu.material_account,
           ood.operating_unit,
           ood.organization_name,
           hl.location_id
      -- hcsu.location
      FROM apps.oe_order_headers_all ooh,
           apps.oe_order_lines_all ool,
           apps.hz_parties hp,
           apps.hz_party_sites hps,
           apps.hz_cust_acct_sites_all hcas,
           apps.hz_cust_site_uses_all hcsu,
           apps.hz_cust_accounts_all hca,
           apps.mtl_system_items_b msib,
           apps.mtl_onhand_quantities_detail moqd,
           apps.mtl_lot_numbers mln,
           apps.mtl_secondary_inventories msu,
           apps.org_organization_definitions ood,
           --apps.fnd_territories_vl l,
           apps.hz_locations hl,
           wip_discrete_jobs wdj,
           wip_entities we
     WHERE     ool.flow_status_code = 'AWAITING_SHIPPING'
           AND NVL (wdj.status_type, '3') = 3
           AND hcsu.site_use_code = 'BILL_TO'
           AND ooh.org_id = ool.org_id
           AND ooh.header_id = ool.header_id
           AND hp.party_id = hps.party_id
           AND hps.party_site_id = hcas.party_site_id
           AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
           AND hcas.cust_account_id = ooh.sold_to_org_id
           AND hcsu.site_use_id = ooh.invoice_to_org_id
           AND hp.party_id = hca.party_id
           AND hca.cust_account_id = hcas.cust_account_id
           AND hcsu.org_id = ooh.org_id
           AND msib.organization_id = ooh.ship_from_org_id
           AND msib.inventory_item_id = ool.inventory_item_id
           AND ooh.ship_from_org_id = ood.organization_id
           AND msib.organization_id = mln.organization_id
           AND msib.inventory_item_id = moqd.inventory_item_id
           AND moqd.inventory_item_id = mln.inventory_item_id
           AND moqd.organization_id = mln.organization_id
           AND moqd.lot_number = mln.lot_number
           AND moqd.subinventory_code = msu.secondary_inventory_name
           AND mln.organization_id = msu.organization_id
           AND moqd.organization_id = msib.organization_id
           AND ood.organization_id = msib.organization_id
           AND moqd.inventory_item_id = ool.inventory_item_id
           -- AND l.territory_code = hl.country
           AND hps.location_id = hl.location_id
           AND wdj.primary_item_id(+) = msib.inventory_item_id
           AND msib.organization_id = wdj.organization_id(+)
           AND we.organization_id(+) = msib.organization_id
           AND we.primary_item_id(+) = msib.inventory_item_id);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_BACK_ORDER_V FOR APPS.XX_BI_BACK_ORDER_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_BACK_ORDER_V FOR APPS.XX_BI_BACK_ORDER_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_BACK_ORDER_V FOR APPS.XX_BI_BACK_ORDER_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_BACK_ORDER_V FOR APPS.XX_BI_BACK_ORDER_V;


GRANT SELECT ON APPS.XX_BI_BACK_ORDER_V TO ETLEBSUSER;

GRANT SELECT ON APPS.XX_BI_BACK_ORDER_V TO XXINTG;
