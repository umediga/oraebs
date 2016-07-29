DROP VIEW APPS.XX_BI_ORDER_DETAILS_V;

/* Formatted on 6/6/2016 4:59:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_ORDER_DETAILS_V
(
   OPERATING_UNIT_NAME,
   OPERATING_UNIT,
   ORG_CODE,
   ORDER_NUMBER,
   ORDERED_DATE,
   ORDER_TYPE,
   CUSTOMER,
   CUSTOMER_NUMBER,
   ORDER_STATUS,
   CUSTOMER_PO,
   SHIP_TO_ADDRESS,
   CREATED_BY,
   CURRENCY_CODE,
   ORDERED_AMOUNT,
   SHIPPING_METHOD,
   FREIGHT_TERM,
   PRIORITY,
   ITEM_NUMBER,
   DESCRIPTION,
   ORDERED_QTY,
   SHIPPED_QTY,
   BACKORDERED_QTY,
   UOM,
   LINE_STATUS,
   SHIPPING_ORG,
   REQUESTED_DATE,
   SHIPPED_DATE
)
AS
     SELECT hou.NAME,
            ooha.org_id,
            mp.organization_code,
            ooha.order_number,
            ooha.ordered_date,
            ottt.NAME,
            hp.party_name,
            hcaa.account_number,
            ooha.flow_status_code,
            ooha.cust_po_number,
               ship_hp.party_name
            || ' , '
            || hl.address1
            || ' , '
            || hl.address2
            || ' , '
            || hl.address3
            || ' , '
            || hl.city
            || ' , '
            || hl.state
            || ' , '
            || hl.postal_code
            || ' , '
            || hl.country,
            fu.user_name,
            ooha.transactional_curr_code,
            SUM (
               ABS (
                    NVL (oola.unit_selling_price, 0)
                  * NVL (oola.ordered_quantity, 0))),
            NVL2 (oola.shipping_method_code, flv.meaning, NULL),
            ol.meaning,
            oola.shipment_priority_code,
            msib.segment1,
            msib.description,
            oola.ordered_quantity,
            oola.shipped_quantity,
            wdv.requested_quantity,
            muom.unit_of_measure,
            wdv.released_status_name,
            mp.organization_code,
            NVL (oola.request_date, ooha.request_date) --,wdv.latest_pickup_date
                                                      ,
            xx_bi_ship_rep_pkg.get_ship_date (wdv.delivery_detail_id)
       FROM oe_order_headers_all ooha,
            oe_order_lines_all oola,
            oe_transaction_types_tl ottt,
            hz_cust_accounts hcaa,
            hz_parties hp,
            hz_parties ship_hp,
            hz_party_sites ship_hps,
            hz_cust_accounts ship_hcaa,
            hz_cust_acct_sites_all ship_hcasa,
            hz_cust_site_uses_all ship_hcsua,
            hz_locations hl,
            fnd_user fu,
            fnd_lookup_values flv,
            oe_lookups ol,
            mtl_system_items_b msib,
            wsh_deliverables_v wdv,
            mtl_units_of_measure muom,
            mtl_parameters mp,
            hr_operating_units hou,
            org_organization_definitions ood
      WHERE     ooha.org_id = hou.organization_id
            AND ooha.header_id = oola.header_id
            AND ooha.order_type_id = ottt.transaction_type_id(+)
            AND ottt.LANGUAGE = USERENV ('LANG')
            AND ooha.sold_to_org_id = hcaa.cust_account_id(+)
            AND hcaa.party_id = hp.party_id(+)
            AND ooha.ship_to_org_id = ship_hcsua.site_use_id(+)
            AND ship_hcsua.site_use_code = 'SHIP_TO'
            AND ship_hcsua.cust_acct_site_id = ship_hcasa.cust_acct_site_id(+)
            AND ship_hcasa.party_site_id = ship_hps.party_site_id(+)
            AND hl.location_id(+) = ship_hps.location_id
            AND ship_hcaa.party_id = ship_hp.party_id(+)
            AND ship_hcaa.cust_account_id(+) = ship_hcasa.cust_account_id
            AND ooha.created_by = fu.user_id(+)
            AND flv.LANGUAGE = USERENV ('LANG')
            AND oola.shipping_method_code = flv.lookup_code(+)
            AND oola.freight_terms_code = ol.lookup_code(+)
            AND ol.lookup_type(+) = 'FREIGHT_TERMS'
            AND oola.inventory_item_id = msib.inventory_item_id
            AND oola.ship_from_org_id = msib.organization_id
            AND oola.line_id = wdv.source_line_id(+)
            AND wdv.source_code = 'OE'
            AND oola.order_quantity_uom = muom.uom_code(+)
            AND wdv.organization_id = mp.organization_id(+)
            AND ooha.ship_from_org_id = ood.organization_id
   GROUP BY hou.NAME,
            ooha.org_id,
            mp.organization_code,
            ooha.order_number,
            ooha.ordered_date,
            ottt.NAME,
            hp.party_name,
            hcaa.account_number,
            ooha.flow_status_code,
            ooha.cust_po_number,
               ship_hp.party_name
            || ' , '
            || hl.address1
            || ' , '
            || hl.address2
            || ' , '
            || hl.address3
            || ' , '
            || hl.city
            || ' , '
            || hl.state
            || ' , '
            || hl.postal_code
            || ' , '
            || hl.country,
            fu.user_name,
            ooha.transactional_curr_code,
            NVL2 (oola.shipping_method_code, flv.meaning, NULL),
            ol.meaning,
            oola.shipment_priority_code,
            msib.segment1,
            msib.description,
            oola.ordered_quantity,
            oola.shipped_quantity,
            wdv.requested_quantity,
            muom.unit_of_measure,
            wdv.released_status_name,
            mp.organization_code,
            NVL (oola.request_date, ooha.request_date),
            --,wdv.latest_pickup_date
            xx_bi_ship_rep_pkg.get_ship_date (wdv.delivery_detail_id);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_ORDER_DETAILS_V FOR APPS.XX_BI_ORDER_DETAILS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_ORDER_DETAILS_V FOR APPS.XX_BI_ORDER_DETAILS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_ORDER_DETAILS_V FOR APPS.XX_BI_ORDER_DETAILS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_ORDER_DETAILS_V FOR APPS.XX_BI_ORDER_DETAILS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_ORDER_DETAILS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_ORDER_DETAILS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_ORDER_DETAILS_V TO XXINTG;
