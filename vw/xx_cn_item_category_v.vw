DROP VIEW APPS.XX_CN_ITEM_CATEGORY_V;

/* Formatted on 6/6/2016 4:58:50 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_ITEM_CATEGORY_V
(
   CUSTOMER_TRX_LINE_ID,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   CATEGORY_SET_NAME,
   DIVISION,
   PRODUCT_SEGMENT,
   CONTRACT_CATEGORY,
   BRAND,
   PRODUCT_CLASS,
   PRODUCT_TYPE
)
AS
   SELECT rct.customer_trx_line_id customer_trx_line_id,
          mst.segment1 item_number,
          mst.description item_description,
          mcs.category_set_name category_set_name,
          mck.segment4 division,
          mck.segment10 product_segment,
          mck.segment6 contract_category,
          mck.segment7 brand,
          mck.segment8 product_class,
          mck.segment9 product_type
     FROM ra_customer_trx_lines_all rct,
          mtl_system_items_b mst,
          mtl_item_categories mic,
          mtl_categories_kfv mck,
          mtl_category_sets_v mcs,
          org_organization_definitions ood
    WHERE     rct.inventory_item_id = mst.inventory_item_id
          AND ood.organization_id = mst.organization_id
          AND mic.organization_id = mst.organization_id
          AND mst.inventory_item_id = mic.inventory_item_id
          AND mic.category_id = mck.category_id
          AND mic.category_set_id = mcs.category_set_id
          AND mcs.category_set_name = 'Sales and Marketing'
          AND ood.organization_name = 'IO INTEGRA ITEM MASTER';


GRANT SELECT ON APPS.XX_CN_ITEM_CATEGORY_V TO XXAPPSREAD;
