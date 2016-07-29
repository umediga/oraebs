DROP VIEW APPS.XX_BI_SALES_BACKORDERS_V;

/* Formatted on 6/6/2016 4:58:59 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_BACKORDERS_V
(
   BOOKING_DATE,
   ORDERED_DATE,
   ORDER_NO,
   ORDER_TYPE,
   ORDER_HEADER_PO_NO,
   ORDER_FLEXFIELD_PO_NO,
   SHIP_TO_CUSTOMER_NO,
   SHIP_TO_CUSTOMER,
   SITE_NUMBER,
   SHIP_TO_NAME,
   CREATED_BY_NAME,
   ITEM_PART_NO,
   DESCRIPTION,
   SEGMENT1,
   SEGMENT2,
   SEGMENT3,
   SEGMENT4,
   BASE_QTY,
   ITEM_LINE_ID,
   HEADER_ATTRIBUTE1,
   HEADER_ATTRIBUTE2,
   HEADER_ATTRIBUTE3,
   HEADER_ATTRIBUTE4,
   HEADER_ATTRIBUTE5,
   HEADER_ATTRIBUTE10,
   HEADER_ATTRIBUTE11,
   HEADER_ATTRIBUTE12,
   HEADER_ATTRIBUTE13,
   HEADER_ATTRIBUTE14,
   HEADER_ATTRIBUTE15,
   HEADER_ATTRIBUTE16,
   HEADER_ATTRIBUTE17,
   HEADER_ATTRIBUTE18,
   HEADER_ATTRIBUTE19,
   HEADER_ATTRIBUTE20,
   SALES_CHANNEL,
   DIVISION,
   OPERATING_UNIT,
   ORG_CODE
)
AS
     SELECT ooh.booked_date booking_date,
            ooh.ordered_date ordered_date,
            ooh.order_number order_number,
            ottt.NAME order_type,
            ooh.cust_po_number order_header_po_no,
            ooh.attribute4 order_flexfield_po_no,
            hca.account_number "Ship To Customer No",
            hp.party_name "Ship To Customer ",
            hps.party_site_number "site number ",
               hp.party_name
            || ' '
            || hl.city
            || ', '
            || hl.state
            || ' '
            || hl.postal_code
               ship_to_name,
            fu.user_name,
            msi.segment1 "Item Part No",
            msi.description "Description",
            mic.segment1 segment1,
            mic.segment2 segment2,
            mic.segment3 segment3,
            mic.segment4 segment4,
            (  SELECT SUM (
                         TO_NUMBER (
                            DECODE (ool1.line_category_code,
                                    'ORDER', ool1.ordered_quantity,
                                    'RETURN', -1 * ool1.ordered_quantity)))
                 FROM oe_order_lines_all ool1
                WHERE     ool1.line_id = ool.line_id
                      AND ool1.header_id = ooh.header_id
             GROUP BY ool1.line_category_code, ool1.ordered_quantity)
               base_qty,
            ool.line_id "item line id",
            ooh.attribute1 header_attribute1,
            ooh.attribute2 header_attribute2,
            ooh.attribute3 header_attribute3,
            ooh.attribute4 header_attribute4,
            ooh.attribute5 header_attribute5,
            ooh.attribute10 header_attribute10,
            ooh.attribute11 header_attribute11,
            ooh.attribute12 header_attribute12,
            ooh.attribute13 header_attribute13,
            ooh.attribute14 header_attribute14,
            ooh.attribute15 header_attribute15,
            ooh.attribute16 header_attribute16,
            ooh.attribute17 header_attribute17,
            ooh.attribute18 header_attribute18,
            ooh.attribute19 header_attribute19,
            ooh.attribute20 header_attribute20,
            ooh.sales_channel_code sales_channel,
            mcb.segment4 division,
            ooh.org_id "OPERATING_UNIT",
            ood.organization_code "ORG_CODE"
       FROM apps.oe_order_headers_all ooh,
            apps.oe_order_lines_all ool,
            apps.oe_transaction_types_tl ottt,
            apps.hz_parties hp,
            apps.hz_party_sites hps,
            apps.hz_cust_acct_sites_all hcas,
            apps.hz_cust_site_uses_all hcsu,
            apps.hz_cust_accounts_all hca,
            apps.fnd_user fu,
            apps.mtl_system_items_b msi,
            apps.mtl_item_categories_v mic,
            apps.wsh_delivery_details dd,
            apps.hz_locations hl,
            apps.mtl_categories_b mcb,
            org_organization_definitions ood
      WHERE     ooh.header_id = ool.header_id
            AND ottt.LANGUAGE = USERENV ('LANG')
            AND ooh.org_id = ool.org_id
            AND ooh.order_type_id = ottt.transaction_type_id
            AND hca.cust_account_id = hcas.cust_account_id
            AND hp.party_id = hps.party_id
            AND hcas.party_site_id = hps.party_site_id
            AND hps.location_id = hl.location_id
            AND hcsu.site_use_code(+) = 'SHIP_TO'
            AND hcsu.cust_acct_site_id(+) = hcas.cust_acct_site_id
            AND hcsu.site_use_id = ooh.ship_to_org_id
            AND fu.user_id = ooh.created_by
            AND msi.inventory_item_id = ool.inventory_item_id
            AND mic.inventory_item_id = msi.inventory_item_id
            AND msi.organization_id = mic.organization_id
            AND ooh.booked_flag = 'Y'
            AND mic.category_set_id = 5
            AND dd.released_status = 'B'                      -- 'BackOrdered'
            AND dd.source_header_id = ooh.header_id
            AND dd.source_line_id = ool.line_id
            AND mcb.category_id = mic.category_id
            AND msi.organization_id =
                   NVL (ool.ship_from_org_id, ooh.ship_from_org_id)
   GROUP BY ooh.booked_date,
            ooh.ordered_date,
            ooh.order_number,
            ottt.NAME,
            ooh.cust_po_number,
            ooh.attribute4,
            hca.account_number,
            hp.party_name,
            hps.party_site_number,
            fu.user_name,
            msi.segment1,
            msi.description,
            ool.line_category_code,
            ool.ordered_quantity,
            mic.segment4,
            ool.line_id,
            mic.segment1,
            mic.segment2,
            mic.segment3,
            mic.segment4,
            ooh.attribute1,
            ooh.attribute2,
            ooh.attribute3,
            ooh.attribute4,
            ooh.attribute5,
            ooh.attribute10,
            ooh.attribute11,
            ooh.attribute12,
            ooh.attribute13,
            ooh.attribute14,
            ooh.attribute15,
            ooh.attribute16,
            ooh.attribute17,
            ooh.attribute18,
            ooh.attribute19,
            ooh.attribute20,
            ooh.header_id,
            hl.city,
            hl.state,
            hl.postal_code,
            ooh.sales_channel_code,
            mcb.segment4,
            ooh.org_id,
            ood.organization_code;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_BACKORDERS_V FOR APPS.XX_BI_SALES_BACKORDERS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_BACKORDERS_V FOR APPS.XX_BI_SALES_BACKORDERS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_BACKORDERS_V FOR APPS.XX_BI_SALES_BACKORDERS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_BACKORDERS_V FOR APPS.XX_BI_SALES_BACKORDERS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_BACKORDERS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_BACKORDERS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_BACKORDERS_V TO XXINTG;
