DROP VIEW APPS.XX_BI_SALES_OPERATION_V;

/* Formatted on 6/6/2016 4:58:58 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_OPERATION_V
(
   SALES_ORDER_NUMBER,
   SALES_ORDER_TYPE,
   PO_NUMBER,
   CUSTOMER_NUMBER,
   CUSTOMER_NAME,
   CUSTOMER_TYPE,
   HELD_BY,
   HOLD_NAME,
   HOLD_LEVEL,
   HOLD_COMMENT,
   ORG_ID,
   RELEASE_DATE,
   RELEASED_BY,
   RELEASE_REASON,
   RELEASE_COMMENT,
   RELEASE_YEAR,
   RELEASE_QUARTER,
   RELEASE_MONTH,
   RELEASE_DAY,
   ORDER_AMOUNT,
   DIVISION
)
AS
   SELECT ooh.order_number "Sales Order Number",
          ott.name "Sales Order Type",
          ooh.cust_po_number "PO NUMBER",
          hca.account_number "Customer Number",
          party.party_name "CUSTOMER_NAME",
          party.party_type "Customer Type",
          (SELECT USER_NAME
             FROM fnd_user
            WHERE user_id = oeh.created_by)
             "Held By",
          hd.name "Hold Name",
          flv.meaning "hold_level",
          hs.hold_comment "Hold Comment",
          ooh.org_id "Org ID",
          hr.creation_date "RELEASED_DATE",
          (SELECT USER_NAME
             FROM fnd_user
            WHERE user_id = hr.created_by)
             "RELEASED_BY",
          hr.release_reason_code "Release Reason",
          hr.release_comment "Release Comment",
          hr.creation_date "Release date: Year",
          hr.creation_date "Release date: Quarter",
          hr.creation_date "Release date: MONTH",
          hr.creation_date "Release date:DAY",
          (SELECT SUM (oola.ORDERED_QUANTITY * oola.UNIT_SELLING_PRICE)
             FROM oe_order_lines_all oola
            WHERE oola.header_id = ooh.header_id)
             "Order Amount",
          NULL "DIVISION"
     FROM apps.oe_order_headers_all ooh,
          --  apps.oe_order_lines_all ool,
          apps.oe_transaction_types_tl ott,
          hz_cust_accounts cust_acct,
          hz_parties party,
          apps.hz_cust_accounts_all hca,
          oe_order_holds_all oeh,
          apps.oe_hold_sources_all hs,
          apps.oe_hold_releases hr,
          OE_HOLD_DEFINITIONS hd,
          apps.fnd_lookup_values flv
    WHERE     ott.language = USERENV ('LANG')
          AND flv.lookup_type = 'HOLD_ENTITY_DESC'
          AND flv.language = USERENV ('LANG')
          AND ooh.order_type_id = ott.transaction_type_id
          -- and ooh.org_id = ool.org_id
          -- and ooh.header_id = ool.header_id
          AND ooh.sold_to_org_id = cust_acct.cust_account_id(+)
          AND cust_acct.party_id = party.party_id(+)
          AND party.party_id = hca.party_id
          AND ooh.org_id = oeh.org_id
          AND ooh.header_id = oeh.header_id
          AND oeh.org_id = hs.org_id
          AND oeh.hold_source_id = hs.hold_source_id
          AND oeh.hold_release_id = hr.hold_release_id(+)
          AND hs.hold_id = hd.hold_id
          AND hs.hold_entity_code = flv.lookup_code
   UNION
   SELECT ooh.order_number "Sales Order Number",
          ott.name "Sales Order Type",
          ooh.cust_po_number "PO NUMBER",
          hca.account_number "Customer Number",
          party.party_name "CUSTOMER_NAME",
          party.party_type "Customer Type",
          (SELECT USER_NAME
             FROM fnd_user
            WHERE user_id = oeh.created_by)
             "Held By",
          hd.name "Hold Name",
          flv.meaning "hold_level",
          hs.hold_comment "Hold Comment",
          ooh.org_id "Org ID",
          hr.creation_date "RELEASED_DATE",
          (SELECT USER_NAME
             FROM fnd_user
            WHERE user_id = hr.created_by)
             "RELEASED_BY",
          hr.release_reason_code "Release Reason",
          hr.release_comment "Release Comment",
          hr.creation_date "Release date: Year",
          hr.creation_date "Release date: Quarter",
          hr.creation_date "Release date: MONTH",
          hr.creation_date "Release date:DAY",
          (ool.ORDERED_QUANTITY * ool.UNIT_SELLING_PRICE) "Order Amount",
          (SELECT mcb.segment4
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.language = USERENV ('LANG')
                  AND mcst.category_set_id = 5
                  AND mcst.category_set_id = mcsb.category_set_id
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mic.organization_id = ool.ship_from_org_id
                  AND mic.inventory_item_id = ool.inventory_item_id)
             DIVISION
     FROM apps.oe_order_headers_all ooh,
          apps.oe_order_lines_all ool,
          apps.oe_transaction_types_tl ott,
          hz_cust_accounts cust_acct,
          hz_parties party,
          apps.hz_cust_accounts_all hca,
          oe_order_holds_all oeh,
          apps.oe_hold_sources_all hs,
          apps.oe_hold_releases hr,
          OE_HOLD_DEFINITIONS hd,
          apps.fnd_lookup_values flv
    WHERE     ott.language = USERENV ('LANG')
          AND flv.lookup_type = 'HOLD_ENTITY_DESC'
          AND flv.language = USERENV ('LANG')
          AND ooh.order_type_id = ott.transaction_type_id
          AND ooh.org_id = ool.org_id
          AND ooh.header_id = ool.header_id
          AND ooh.sold_to_org_id = cust_acct.cust_account_id(+)
          AND cust_acct.party_id = party.party_id(+)
          AND party.party_id = hca.party_id
          AND ooh.org_id = oeh.org_id
          AND ooh.header_id = oeh.header_id
          AND ool.line_id = oeh.line_id
          AND oeh.org_id = hs.org_id
          AND oeh.hold_source_id = hs.hold_source_id
          AND oeh.hold_release_id = hr.hold_release_id(+)
          AND hs.hold_id = hd.hold_id
          AND hs.hold_entity_code = flv.lookup_code;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_OPERATION_V FOR APPS.XX_BI_SALES_OPERATION_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_OPERATION_V FOR APPS.XX_BI_SALES_OPERATION_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_OPERATION_V FOR APPS.XX_BI_SALES_OPERATION_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_OPERATION_V FOR APPS.XX_BI_SALES_OPERATION_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_OPERATION_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_OPERATION_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_OPERATION_V TO XXINTG;
