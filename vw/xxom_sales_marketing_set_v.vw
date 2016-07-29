DROP VIEW APPS.XXOM_SALES_MARKETING_SET_V;

/* Formatted on 6/6/2016 5:00:06 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXOM_SALES_MARKETING_SET_V
(
   ORGANIZATION_ID,
   INVENTORY_ITEM_ID,
   SNM_DIVISION,
   PRODUCT_SEGMENT,
   BRAND,
   PRODUCT_CLASS,
   PRODUCT_TYPE,
   FUTURE
)
AS
   SELECT mic.organization_id,
          mic.inventory_item_id,
          mck.segment4 snm_division,
          mck.segment10 Product_Segment,
          SEGMENT7 brand,
          SEGMENT8 product_class,
          SEGMENT9 product_type,
          SEGMENT6 future
     FROM mtl_item_categories mic,
          mtl_categories_kfv mck,
          mtl_category_sets mcs
    WHERE     mck.category_id = mic.category_id
          AND mic.category_set_id = mcs.category_set_id
          AND UPPER (mcs.category_set_name) = UPPER ('SALES AND MARKETING')
          AND mck.category_id = mic.category_id;


GRANT SELECT ON APPS.XXOM_SALES_MARKETING_SET_V TO XXAPPSREAD;
