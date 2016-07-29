DROP VIEW APPS.XX_BI_INV_BIN_TRANS_TEST_V;

/* Formatted on 6/6/2016 4:59:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_INV_BIN_TRANS_TEST_V
(
   BIN,
   BIN_DESCRIPTION,
   PART_CODE,
   PART_DESCRIPTION,
   LOT_NUMBER,
   LOT_EXPIRATION_DATE,
   "Transaction Quantity",
   "Curr Quantity Part Lot",
   "Transaction_date",
   ORDER_NUMBER,
   "Ord Line num",
   "Customer_reference",
   DELIVERY_DESC,
   "Customer Number",
   SHIP_TO_LOCATION,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   CITY,
   STATE,
   POSTAL_CODE,
   "Shipping Desc",
   "Fed Ex Tracking",
   MOVEMENT_DESCRIPTION,
   ORGANIZATION_CODE,
   DIVISION
)
AS
     SELECT DISTINCT
            (SELECT mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
               FROM mtl_item_locations mil
              WHERE     mil.inventory_location_id = moq.locator_id
                    AND mil.organization_id = moq.organization_id
                    AND moq.subinventory_code = mil.subinventory_code)
               "BIN",
            msu.description "BIN_DESCRIPTION",
            msi.segment1 "PART_CODE",
            msi.description "PART_DESCRIPTION",
            NVL (moq.lot_number, wd.lot_number) "LOT_NUMBER",
            mln.expiration_date "LOT_EXPIRATION_DATE",
            moq.transaction_quantity "Transaction Quantity",
            moq.transaction_quantity "Curr Quantity Part Lot",
            moq.creation_date "Transaction_date",
            ooh.order_number "ORDER_NUMBER",
            (ool.line_number || '.' || ool.shipment_number) "Ord Line num",
            ooh.cust_po_number "Customer_reference",
            party.party_name "DELIVERY_DESC",
            cust_acct.account_number "Customer Number",
            ship_use.site_use_id ship_to_location,
            ship_loc.address1 ship_to_address1,
            ship_loc.address2 ship_to_address2,
            ship_loc.city,
            ship_loc.state,
            ship_loc.postal_code,
            ool.shipping_method_code "Shipping Desc",
            d.waybill "Fed Ex Tracking",
            ott.name "MOVEMENT_DESCRIPTION",
            ood.organization_code,
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
                    AND mic.inventory_item_id = ool.inventory_item_id
                    AND mic.organization_id = ool.ship_from_org_id)
               division
       FROM oe_order_headers_all ooh,
            oe_order_lines_all ool,
            oe_transaction_types_tl ott,
            hz_locations ship_loc,
            hz_cust_acct_sites_all ship_cas,
            hz_party_sites ship_ps,
            hz_cust_accounts cust_acct,
            hz_parties party,
            mtl_lot_numbers mln,
            wsh_delivery_details wd,
            wsh_delivery_assignments wda,
            wsh_new_deliveries d,
            mtl_system_items_b msi,
            apps.mtl_secondary_inventories msu,
            org_organization_definitions ood,
            --mtl_material_transactions mmt,
            mtl_onhand_quantities moq,
            hz_cust_site_uses_all ship_use
      WHERE     ooh.header_id = ool.header_id
            AND ship_use.site_use_code(+) = 'SHIP_TO'
            AND ship_use.site_use_id(+) = ooh.ship_to_org_id
            AND ship_use.cust_acct_site_id = ship_cas.cust_acct_site_id
            AND ship_cas.party_site_id = ship_ps.party_site_id
            AND ship_ps.location_id = ship_loc.location_id
            AND wd.source_header_id = ooh.header_id
            AND ool.line_id = NVL (wd.source_line_id, ool.line_id)
            AND ool.inventory_item_id = msi.inventory_item_id(+)
            AND msi.organization_id(+) = ool.ship_from_org_id
            AND msi.organization_id = moq.organization_id(+)
            AND msi.inventory_item_id = moq.inventory_item_id(+)
            AND ooh.sold_to_org_id = cust_acct.cust_account_id(+)
            AND cust_acct.party_id = party.party_id(+)
            AND moq.inventory_item_id = mln.inventory_item_id(+)
            AND moq.lot_number = mln.lot_number(+)
            AND moq.organization_id = mln.organization_id(+)
            AND moq.subinventory_code = msu.secondary_inventory_name(+)
            AND moq.organization_id = msu.organization_id(+)
            AND ott.LANGUAGE = USERENV ('LANG')
            AND ott.LANGUAGE = 'US'
            AND ooh.order_type_id = ott.transaction_type_id
            --AND d.delivery_type = 'STANDARD'
            AND wd.delivery_detail_id = wda.delivery_detail_id(+)
            AND wda.delivery_id = d.delivery_id(+)
            --AND msi.organization_id = mmt.organization_id
            --AND msi.inventory_item_id = mmt.inventory_item_id
            --AND mmt.trx_source_line_id = ool.line_id(+)
            --AND mmt.transaction_type_id = 15
            --AND wd.released_status = 'C'
            AND msi.organization_id = ood.organization_id(+)
            AND EXISTS
                   (SELECT 1
                      FROM mtl_item_categories mic,
                           mtl_category_sets_tl mcst,
                           mtl_category_sets_b mcsb,
                           mtl_categories_b mcb
                     WHERE     mcst.category_set_id = mcsb.category_set_id
                           AND mcst.LANGUAGE = USERENV ('LANG')
                           AND mic.category_set_id = mcsb.category_set_id
                           AND mic.category_id = mcb.category_id
                           AND mcst.category_set_name = 'Sales and Marketing'
                           AND mic.inventory_item_id = ool.inventory_item_id
                           AND mic.organization_id = ool.ship_from_org_id
                           AND mcb.segment4 = 'SPINE')
   --and ooh.order_number=114326    --114288
   ORDER BY ooh.order_number;
