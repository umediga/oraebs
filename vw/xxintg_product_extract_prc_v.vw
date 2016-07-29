DROP VIEW APPS.XXINTG_PRODUCT_EXTRACT_PRC_V;

/* Formatted on 6/6/2016 5:00:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_PRODUCT_EXTRACT_PRC_V
(
   SKU,
   DESCRIPTION,
   UNIT_OF_MEASURE,
   DATE_ADDED,
   SALES_UM,
   BUYER,
   ABC_CODE,
   INC_AV_MATERIAL_COST,
   INC_AV_LABOR_COST,
   INC_AV_BURDEN_COST,
   INC_AV_OUTPLANT_COST,
   INC_AV_TOTAL_COST,
   LAST_STD_COST_DATE,
   PURCHASING_UM,
   PRICE_GROUP_CODE,
   QTY_PER_PACKAGE,
   LIST_PRICE,
   INVENTORY_TYPE,
   LEAD_TIME_CODE,
   ROYALTY_CODE,
   VENDOR_NUMBER,
   VENDOR_NAME,
   GROUP1,
   GROUP2,
   GROUP3,
   GROUP4,
   GROUP5,
   GROUP6,
   USER_DEFINED1,
   USER_DEFINED2,
   USER_DEFINED3,
   USER_DEFINED4,
   CAT_CODE,
   CE_MARK,
   LAST_UPDATE_DATE
)
AS
   SELECT msib.segment1,
          msib.description,
          msib.primary_unit_of_measure,
          msib.last_update_date,
          msib.primary_unit_of_measure,
          msib.buyer_id,
          NULL,
          (SELECT cic.material_cost
             FROM cst_item_costs cic, mtl_parameters mp
            WHERE     cic.inventory_item_id = msib.inventory_item_id
                  AND cic.organization_id = msib.organization_id
                  AND cic.cost_type_id = mp.primary_cost_method
                  AND mp.organization_id = msib.organization_id),
          (SELECT cic.resource_cost
             FROM cst_item_costs cic, mtl_parameters mp
            WHERE     cic.inventory_item_id = msib.inventory_item_id
                  AND cic.organization_id = msib.organization_id
                  AND cic.cost_type_id = mp.primary_cost_method
                  AND mp.organization_id = msib.organization_id),
          (SELECT cic.overhead_cost
             FROM cst_item_costs cic, mtl_parameters mp
            WHERE     cic.inventory_item_id = msib.inventory_item_id
                  AND cic.organization_id = msib.organization_id
                  AND cic.cost_type_id = mp.primary_cost_method
                  AND mp.organization_id = msib.organization_id),
          (SELECT cic.material_overhead_cost
             FROM cst_item_costs cic, mtl_parameters mp
            WHERE     cic.inventory_item_id = msib.inventory_item_id
                  AND cic.organization_id = msib.organization_id
                  AND cic.cost_type_id = mp.primary_cost_method
                  AND mp.organization_id = msib.organization_id),
          (SELECT cic.item_cost
             FROM cst_item_costs cic, mtl_parameters mp
            WHERE     cic.inventory_item_id = msib.inventory_item_id
                  AND cic.organization_id = msib.organization_id
                  AND cic.cost_type_id = mp.primary_cost_method
                  AND mp.organization_id = msib.organization_id),
          (SELECT cic.last_update_date
             FROM cst_item_costs cic, mtl_parameters mp
            WHERE     cic.inventory_item_id = msib.inventory_item_id
                  AND cic.organization_id = msib.organization_id
                  AND cic.cost_type_id = mp.primary_cost_method
                  AND mp.organization_id = msib.organization_id),
          msib.unit_of_issue,
          NULL,
          NULL,
          msib.list_price_per_unit,
          msib.item_type,
          msib.full_lead_time,
          NULL,
          (SELECT vendor_id
             FROM po_asl_suppliers_v
            WHERE     item_id = msib.inventory_item_id
                  AND using_organization_id = msib.organization_id)
             VENDOR_ID,
          (SELECT vendor_name
             FROM po_asl_suppliers_v
            WHERE     item_id = msib.inventory_item_id
                  AND using_organization_id = msib.organization_id)
             VENDOR_NAME,
          (SELECT mcb.segment4
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id),
          (SELECT mcb.segment10
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id),
          (SELECT mcb.segment8
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id),
          (SELECT mcb.segment9
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id),
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          msib.attribute4,
          msib.attribute1,
          msib.last_update_date
     FROM mtl_system_items_b msib, org_organization_definitions ood
    WHERE     msib.organization_id = ood.organization_id
          AND ood.organization_code = 'MST';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_PRODUCT_EXTRACT_PRC_V FOR APPS.XXINTG_PRODUCT_EXTRACT_PRC_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_PRODUCT_EXTRACT_PRC_V FOR APPS.XXINTG_PRODUCT_EXTRACT_PRC_V;


GRANT SELECT ON APPS.XXINTG_PRODUCT_EXTRACT_PRC_V TO ETLEBSUSER;
