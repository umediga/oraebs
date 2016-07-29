DROP VIEW APPS.XX_BI_FI_STD_COST_RPT_V;

/* Formatted on 6/6/2016 4:59:38 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_STD_COST_RPT_V
(
   BUYER,
   BUYER_ID,
   ITEM_DESCRIPTION,
   ITEM_NUMBER,
   ITEM_TYPE_NAME,
   ORGANIZATION_CODE,
   COST_TYPE_NAME,
   ORGANIZATION_NAME,
   CCODE,
   CCODE_DESCRIPTION,
   DCODE,
   DCODE_DESCRIPTION,
   RESOURCE_COST,
   OVERHEAD_COST,
   MATERIAL_OVERHEAD_COST,
   MATERIAL_COST,
   ITEM_COST,
   CATEGORY_SET,
   CATEGORY
)
AS
   SELECT buyer,
          buyer_id,
          item_description,
          item_number,
          item_type_name,
          organization_code,
          cost_type_name,
          organization_name,
          mcb.segment8 AS ccode,
          (SELECT c.description
             FROM fnd_flex_value_sets a,
                  fnd_flex_values b,
                  fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  -- AND A.FLEX_VALUE_SET_NAME = 'INTG_ITEM'
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment8
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             ccode_description,
          mcb.segment9 AS dcode,
          (SELECT c.description
             FROM fnd_flex_value_sets a,
                  fnd_flex_values b,
                  fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  --AND A.FLEX_VALUE_SET_NAME = 'INTG_ITEM'
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment9
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             dcode_description,
          resource_cost,
          overhead_cost,
          material_overhead_cost,
          material_cost,
          item_cost,
          micv.category_set_name,
          micv.category_concat_segs
     FROM (  SELECT DISTINCT
                    msib.inventory_item_id,
                    msib.organization_id,
                    papf.full_name AS buyer,
                    msib.buyer_id AS buyer_id,
                    msib.description AS item_description,
                    msib.segment1 AS item_number,
                    fcl.meaning AS item_type_name,
                    ood.organization_code AS organization_code,
                    cct.cost_type AS cost_type_name,
                    ood.organization_name AS organization_name,
                    SUM (cst.resource_cost) AS resource_cost,
                    SUM (cst.overhead_cost) AS overhead_cost,
                    SUM (cst.material_overhead_cost) AS material_overhead_cost,
                    SUM (cst.material_cost) AS material_cost,
                    SUM (cst.item_cost) AS item_cost
               FROM org_organization_definitions ood,
                    mtl_system_items_b msib,
                    cst_item_costs cst,
                    fnd_common_lookups fcl,
                    per_all_people_f papf,
                    cst_cost_types cct
              WHERE     msib.organization_id = ood.organization_id
                    AND msib.inventory_item_id = cst.inventory_item_id
                    AND ood.organization_id = cst.organization_id
                    AND fcl.lookup_code = msib.item_type
                    AND msib.buyer_id = papf.person_id
                    AND cct.cost_type_id = cst.cost_type_id
                    AND fcl.lookup_type = 'ITEM_TYPE'
                    AND UPPER (cct.cost_type) = 'FROZEN'
                    AND SYSDATE BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
           --and ood.organization_code='MST'
           GROUP BY msib.inventory_item_id,
                    msib.organization_id,
                    papf.full_name,
                    msib.buyer_id,
                    msib.description,
                    msib.segment1,
                    fcl.meaning,
                    ood.organization_code,
                    cct.cost_type,
                    ood.organization_name
           UNION
             SELECT DISTINCT
                    msib.inventory_item_id,
                    msib.organization_id,
                    -- papf.full_name AS buyer,
                    NULL,
                    msib.buyer_id AS buyer_id,
                    msib.description AS item_description,
                    msib.segment1 AS item_number,
                    fcl.meaning AS item_type_name,
                    ood.organization_code AS organization_code,
                    cct.cost_type AS cost_type_name,
                    ood.organization_name AS organization_name,
                    SUM (cst.resource_cost) AS resource_cost,
                    SUM (cst.overhead_cost) AS overhead_cost,
                    SUM (cst.material_overhead_cost) AS material_overhead_cost,
                    SUM (cst.material_cost) AS material_cost,
                    SUM (cst.item_cost) AS item_cost
               FROM org_organization_definitions ood,
                    mtl_system_items_b msib,
                    cst_item_costs cst,
                    fnd_common_lookups fcl,
                    --per_all_people_f papf,
                    cst_cost_types cct
              WHERE     msib.organization_id = ood.organization_id
                    AND msib.inventory_item_id = cst.inventory_item_id
                    AND ood.organization_id = cst.organization_id
                    AND fcl.lookup_code = msib.item_type
                    -- AND msib.buyer_id = papf.person_id
                    AND cct.cost_type_id = cst.cost_type_id
                    AND fcl.lookup_type = 'ITEM_TYPE'
                    AND UPPER (cct.cost_type) = 'FROZEN'
                    --AND SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date
                    --and ood.organization_code='MST'
                    AND msib.buyer_id IS NULL
           GROUP BY msib.inventory_item_id,
                    msib.organization_id,
                    -- papf.full_name,
                    msib.buyer_id,
                    msib.description,
                    msib.segment1,
                    fcl.meaning,
                    ood.organization_code,
                    cct.cost_type,
                    ood.organization_name) a,
          apps.mtl_item_categories_v micv,
          apps.mtl_categories_b mcb
    WHERE     micv.inventory_item_id = a.inventory_item_id
          AND micv.organization_id = a.organization_id
          AND mcb.category_id = micv.category_id
          AND micv.category_set_name = 'Inventory';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_STD_COST_RPT_V FOR APPS.XX_BI_FI_STD_COST_RPT_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_STD_COST_RPT_V FOR APPS.XX_BI_FI_STD_COST_RPT_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_STD_COST_RPT_V FOR APPS.XX_BI_FI_STD_COST_RPT_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_STD_COST_RPT_V FOR APPS.XX_BI_FI_STD_COST_RPT_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_STD_COST_RPT_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_STD_COST_RPT_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_STD_COST_RPT_V TO XXINTG;
