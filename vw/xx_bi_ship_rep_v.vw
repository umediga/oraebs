DROP VIEW APPS.XX_BI_SHIP_REP_V;

/* Formatted on 6/6/2016 4:58:54 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SHIP_REP_V
(
   OPERATING_UNIT,
   ORDER_NUMBER,
   ORDER_LINE_NUMBER,
   CREATED_BY,
   CUST_PO_NUMBER,
   SHIP_FROM_ORG_ID,
   EVALUATING_DEPT,
   HCP_PERFORMING_EVAL,
   DIVISION,
   PHYSICIAN_2,
   PHYSICIAN_3,
   PHYSICIAN_4,
   PHYSICIAN_5,
   PHYSICIAN_6,
   PHYSICIAN_7,
   PHYSICIAN_8,
   PHYSICIAN_9,
   PHYSICIAN_10,
   SHIP_FROM_ORG_NAME,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   CURRENCY,
   UNIT_SELLING_PRICE,
   SHIPPED_QUANTITY,
   EXTENDED_PRICE,
   RELEASE_DATE,
   DROP_OFF_DATE,
   SHIPPED_DATE,
   DELIVERY_NUMBER,
   CARRIER,
   CUSTOMER_NAME,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   SHIP_TO_ADDRESS3,
   SHIP_TO_CITY,
   SHIP_TO_COUNTY,
   SHIP_TO_STATE,
   SHIP_TO_POSTAL_CODE,
   SHIP_TO_COUNTRY,
   ORDER_TYPE,
   FREIGHT_TERMS,
   TRACKING_NUMBER,
   WAYBILL,
   INVOICE_NO,
   FREIGHT_COST,
   REVENUE_COST,
   TOTAL_BY_DELIVERY_NUMBER
)
AS
   SELECT ooh.org_id operating_unit,
          ooh.order_number,
          ool.line_number,
          fu.user_name created_by,
          ooh.cust_po_number,
          ool.ship_from_org_id,
          ohai.segment1 evaluating_dept,
          ohai.segment11 hcp_performing_eval,
          (SELECT mcb.segment4
             FROM apps.mtl_item_categories mic,
                  apps.mtl_category_sets_tl mcst,
                  apps.mtl_category_sets_b mcsb,
                  apps.mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.LANGUAGE = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msi.inventory_item_id
                  AND mic.organization_id = msi.organization_id)
             division,
          ohai.segment12 physician_2,
          ohai.segment13 physician_3,
          ohai.segment14 physician_4,
          ohai.segment15 physician_5,
          ohai.segment16 physician_6,
          ohai.segment17 physician_7,
          ohai.segment18 physician_8,
          ohai.segment19 physician_9,
          ohai.segment20 physician_10,
          (SELECT ood.organization_name
             FROM org_organization_definitions ood
            WHERE ood.organization_id = ool.ship_from_org_id AND ROWNUM = 1)
             ship_from_org_name,
          ool.ordered_item,
          wd.item_description,
          ooh.transactional_curr_code currency,
          ool.unit_selling_price,
          wd.shipped_quantity,
          (wd.shipped_quantity * ool.unit_selling_price) extended_price,
          --rctl.EXTENDED_AMOUNT,
          apps.xx_bi_ship_rep_pkg.get_release_date (wd.move_order_line_id,
                                                    wd.source_line_id)
             release_date,
          s.actual_arrival_date drop_off_date,
          s.actual_departure_date shipped_date,
          d.NAME delivery_number,
          wcv.freight_code carrier,
          hp.party_name customer_name,
          hl.address1 ship_to_address1,
          hl.address2 ship_to_address2,
          hl.address3 ship_to_address3,
          hl.city ship_to_city,
          hl.county ship_to_county,
          hl.state ship_to_state,
          hl.postal_code ship_to_postal_code,
          al.meaning ship_to_country,
          ot.NAME order_type,
          d.freight_terms_code freight_terms,
          wd.tracking_number,
          d.waybill,
          rct.trx_number invoice_number,
          (SELECT unit_amount
             FROM wsh_freight_costs
            WHERE delivery_id = d.delivery_id AND ROWNUM = 1)
             freight_cost,
          b.base_transaction_value revenue_cost,        --rctl.REVENUE_AMOUNT,
          0 total_by_delivery_number                       --,z.source_line_id
     FROM oe_order_headers_all ooh,
          oe_order_lines_all ool,
          oe_transaction_types_tl ot,
          apps.xxintg_om_hdr_add_info ohai,
          wsh_delivery_details wd,
          wsh_delivery_assignments wda,
          hz_cust_accounts hca,
          hz_parties hp,
          hz_locations hl,
          ar_lookups al,
          mtl_txn_request_lines mtrl,
          wsh_new_deliveries d,
          wsh_carriers wcv,
          wsh_delivery_legs dl,
          wsh_trip_stops s,
          fnd_user fu,
          ra_customer_trx_lines_all rctl,
          ra_customer_trx_all rct,
          mtl_material_transactions a,
          mtl_transaction_accounts b,
          apps.mtl_system_items_b msi
    /*(SELECT NVL (B.BASE_TRANSACTION_VALUE, 0) REVENUE_COST,
            A.SOURCE_LINE_ID,
            A.INVENTORY_ITEM_ID
       FROM MTL_MATERIAL_TRANSACTIONS A, MTL_TRANSACTION_ACCOUNTS B
      WHERE     B.ACCOUNTING_LINE_TYPE = 36
            AND A.TRANSACTION_TYPE_ID = 33
            AND A.TRANSACTION_SOURCE_TYPE_ID = 2
            AND A.TRANSACTION_SOURCE_ID = B.TRANSACTION_SOURCE_ID
            AND A.TRANSACTION_ID = B.TRANSACTION_ID
            AND A.ORGANIZATION_ID = B.ORGANIZATION_ID
            AND A.INVENTORY_ITEM_ID = B.INVENTORY_ITEM_ID) Z*/
    WHERE     ot.LANGUAGE = 'US'
          AND wd.released_status = 'C'
          AND d.delivery_type = 'STANDARD'
          AND al.lookup_type = 'HZ_DOMAIN_SUFFIX_LIST'
          AND NVL (d.shipment_direction, 'O') IN ('O', 'IO')
          AND ooh.header_id = ool.header_id
          AND ooh.org_id = ool.org_id
          AND ot.transaction_type_id = ooh.order_type_id
          AND ooh.attribute11 = TO_CHAR (ohai.code_combination_id(+))
          AND wd.source_header_id = ooh.header_id
          AND ool.line_id = wd.source_line_id
          AND wd.customer_id = hca.cust_account_id
          AND hca.party_id = hp.party_id
          AND wd.ship_to_location_id = hl.location_id
          AND wd.delivery_detail_id = wda.delivery_detail_id
          AND wd.move_order_line_id = mtrl.line_id
          AND wda.delivery_id = d.delivery_id
          AND wd.carrier_id = wcv.carrier_id
          AND d.delivery_id = dl.delivery_id
          AND dl.pick_up_stop_id = s.stop_id
          AND ooh.order_number = rctl.sales_order
          AND ool.line_number = rctl.sales_order_line
          AND rctl.customer_trx_id = rct.customer_trx_id
          AND TO_CHAR (ooh.order_number) = rct.interface_header_attribute1
          AND ooh.org_id = rct.org_id
          AND a.source_line_id = ool.line_id
          AND a.source_line_id = wd.source_line_id
          AND a.inventory_item_id = ool.inventory_item_id
          AND a.organization_id = wd.organization_id
          AND hl.country = al.lookup_code(+)
          AND ool.created_by = fu.user_id
          AND b.accounting_line_type = 36
          AND a.transaction_type_id = 33
          AND a.transaction_source_type_id = 2
          AND a.transaction_source_id = b.transaction_source_id
          AND a.transaction_id = b.transaction_id
          AND a.organization_id = b.organization_id
          AND a.inventory_item_id = b.inventory_item_id
          AND msi.inventory_item_id = a.inventory_item_id
          AND msi.organization_id = a.organization_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SHIP_REP_V FOR APPS.XX_BI_SHIP_REP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SHIP_REP_V FOR APPS.XX_BI_SHIP_REP_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SHIP_REP_V FOR APPS.XX_BI_SHIP_REP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SHIP_REP_V FOR APPS.XX_BI_SHIP_REP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SHIP_REP_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SHIP_REP_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SHIP_REP_V TO XXINTG;
