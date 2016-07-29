DROP VIEW APPS.XX_SFDC_ITEM_OUT_V;

/* Formatted on 6/6/2016 4:58:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SFDC_ITEM_OUT_V
(
   INVENTORY_ITEM_ID,
   ITEM_CODE,
   LONG_DESCRIPTION,
   DESCRIPTION,
   ITEM_STATUS,
   COMMS_NL_TRACKABLE_FLAG,
   DIVISION,
   PRODUCT_SEGMENT,
   BRAND,
   PRODUCT_CLASS,
   PRODUCT_CLASS_DESC,
   PRODUCT_TYPE,
   PRODUCT_TYPE_DESC,
   SUBDIVISION,
   PRODUCT_USE,
   PRODUCT_USE_DESC,
   PRODUCT_FAMILY,
   PRODUCT_FAMILY_DESC,
   INV_PRODUCT_TYPE,
   INV_PRODUCT_TYPE_DESC,
   ITEM_COST,
   LAST_UPDATE_DATE
)
AS
   SELECT msib.inventory_item_id,
          msib.segment1 ITEM_CODE,
          msit.long_description,
          msib.description,
          msib.inventory_item_status_code ITEM_STATUS,
          DECODE (msib.comms_nl_trackable_flag, 'Y', 1, 0),
          sal.division,
          sal.product_segment,
          sal.brand,
          sal.product_class                          --,sal.product_class_desc
                           ,
          SUBSTR (sal.product_class_desc, 1, 40) product_class_desc,
          sal.product_type,
          sal.product_type_desc,
          inv.subdivision,
          inv.product_use,
          inv.product_use_desc,
          inv.product_family,
          inv.product_family_desc,
          inv.inv_product_type,
          inv.inv_product_type_desc,
          (SELECT SUM (item_cost)
             FROM CST_ITEM_COST_TYPE_V cict
            WHERE     cict.INVENTORY_ITEM_ID = msib.inventory_item_id
                  AND cict.cost_type = 'Frozen'
                  AND cict.ORGANIZATION_ID = ood.organization_id),
          GREATEST (NVL (sal.last_update_date, '01-JAN-1000'),
                    NVL (inv.last_update_date, '01-JAN-1000'),
                    msib.last_update_date,
                    msit.last_update_date)
             last_update_date
     FROM mtl_system_items_b msib,
          mtl_system_items_tl msit,
          org_organization_definitions ood,
          (SELECT mic.inventory_item_id,
                  mic.organization_id,
                  mcb.segment4 DIVISION,
                  mcb.segment10 PRODUCT_SEGMENT,
                  mcb.segment7 BRAND,
                  mcb.segment8 PRODUCT_CLASS              --INTG_PRODUCT_CLASS
                                            ,
                  (SELECT ffvt.description
                     FROM fnd_flex_value_sets ffvs,
                          fnd_flex_values ffv,
                          fnd_flex_values_tl ffvt
                    WHERE     ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.flex_value_id = ffvt.flex_value_id
                          AND ffvt.language = USERENV ('LANG')
                          AND ffvs.flex_value_set_name = 'INTG_PRODUCT_CLASS'
                          AND ffv.flex_value = mcb.segment8)
                     PRODUCT_CLASS_DESC,
                  mcb.segment9 PRODUCT_TYPE                --INTG_PRODUCT_TYPE
                                           ,
                  (SELECT ffvt.description
                     FROM fnd_flex_value_sets ffvs,
                          fnd_flex_values ffv,
                          fnd_flex_values_tl ffvt
                    WHERE     ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.flex_value_id = ffvt.flex_value_id
                          AND ffvt.language = USERENV ('LANG')
                          AND ffvs.flex_value_set_name = 'INTG_PRODUCT_TYPE'
                          AND ffv.parent_flex_value_low = mcb.segment4
                          AND ffv.flex_value = mcb.segment9)
                     PRODUCT_TYPE_DESC,
                  GREATEST (mic.last_update_date,
                            mcst.last_update_date,
                            mcsb.last_update_date,
                            mcb.last_update_date)
                     last_update_date
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing') sal,
          (SELECT mic.inventory_item_id,
                  mic.organization_id,
                  mcb.segment2 SUBDIVISION,
                  mcb.segment3 PRODUCT_USE                  --INTG_PRODUCT_USE
                                          ,
                  (SELECT ffvt.description
                     FROM fnd_flex_value_sets ffvs,
                          fnd_flex_values ffv,
                          fnd_flex_values_tl ffvt
                    WHERE     ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.flex_value_id = ffvt.flex_value_id
                          AND ffvt.language = USERENV ('LANG')
                          AND ffvs.flex_value_set_name = 'INTG_PRODUCT_USE'
                          AND ffv.flex_value = mcb.segment3)
                     PRODUCT_USE_DESC,
                  mcb.segment4 PRODUCT_FAMILY            --INTG_PRODUCT_FAMILY
                                             ,
                  (SELECT ffvt.description
                     FROM fnd_flex_value_sets ffvs,
                          fnd_flex_values ffv,
                          fnd_flex_values_tl ffvt
                    WHERE     ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.flex_value_id = ffvt.flex_value_id
                          AND ffvt.language = USERENV ('LANG')
                          AND ffvs.flex_value_set_name =
                                 'INTG_PRODUCT_FAMILY'
                          AND ffv.flex_value = mcb.segment4)
                     PRODUCT_FAMILY_DESC,
                  mcb.segment5 INV_PRODUCT_TYPE        --INTG_PRODUCT_CATEGORY
                                               ,
                  (SELECT ffvt.description
                     FROM fnd_flex_value_sets ffvs,
                          fnd_flex_values ffv,
                          fnd_flex_values_tl ffvt
                    WHERE     ffvs.flex_value_set_id = ffv.flex_value_set_id
                          AND ffv.flex_value_id = ffvt.flex_value_id
                          AND ffvt.language = USERENV ('LANG')
                          AND ffvs.flex_value_set_name =
                                 'INTG_PRODUCT_CATEGORY'
                          AND ffv.flex_value = mcb.segment5)
                     INV_PRODUCT_TYPE_DESC,
                  GREATEST (mic.last_update_date,
                            mcst.last_update_date,
                            mcsb.last_update_date,
                            mcb.last_update_date)
                     last_update_date
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Inventory') inv
    WHERE     msib.organization_id = ood.organization_id
          AND ood.organization_code = 'MST'
          AND msib.item_type IN ('FG', 'RPR', 'TLIN')
          AND msib.inventory_item_id = msit.inventory_item_id
          AND msib.organization_id = msit.organization_id
          AND msit.language = USERENV ('LANG')
          AND sal.inventory_item_id(+) = msib.inventory_item_id
          AND sal.organization_id(+) = msib.organization_id
          AND inv.inventory_item_id(+) = msib.inventory_item_id
          --AND msib.enabled_flag = 'Y'
          AND inv.organization_id(+) = msib.organization_id;
