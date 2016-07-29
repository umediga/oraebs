DROP VIEW APPS.XX_BI_P2M_QA_AQL_LIST_V;

/* Formatted on 6/6/2016 4:59:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_QA_AQL_LIST_V
(
   ORGANIZATION_CODE,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   RECEIPT_ROUTING,
   ITEM_CAT,
   SAMPLING_PLAN,
   PLAN_NAME,
   EFFECTIVE_FROM,
   EFFECTIVE_TO,
   DEFINITION_LEVEL
)
AS
   SELECT org.organization_code,
          ITEM.SEGMENT1,
          ITEM.DESCRIPTION,
          'Inspection',
          'Dedicated Entry',
          plan.sampling_plan_code,
          qa.name,
          det.EFFECTIVE_FROM,
          det.effective_to,
          'Defined at Item Level'
     FROM apps.qa_sl_sp_rcv_criteria skip,
          apps.mtl_system_items_b ITEM,
          apps.qa_sampling_association det,
          apps.qa_sampling_plans plan,
          apps.mtl_parameters org,
          apps.QA_PLANS QA
    WHERE     skip.item_id = item.inventory_item_id
          AND skip.organization_id = item.organization_id
          AND skip.organization_id = org.organization_id
          AND skip.item_id IS NOT NULL
          AND det.CRITERIA_ID = skip.criteria_id
          AND det.SAMPLING_PLAN_ID = plan.sampling_plan_id
          AND plan.organization_id = skip.organization_id
          AND qa.PLAN_ID(+) = det.COLLECTION_PLAN_ID
   UNION
   -- Get skip criteria based on the categories (if no item line)
   SELECT org.organization_code,
          ITEM.SEGMENT1,
          ITEM.DESCRIPTION,
          DECODE (NVL (item.receiving_routing_id, 99),
                  1, 'Standard',
                  2, 'Inspection',
                  3, 'Direct',
                  99, 'Missing'),
          NVL (cat.segment1, 'Missing Quality category'),
          DECODE (NVL (item.receiving_routing_id, 99),
                  99, 'Missing',
                  1, NULL,
                  3, NULL,
                  2, plan.sampling_plan_code),
          qa.name,
          det.EFFECTIVE_FROM,
          det.effective_to,
          'Defined at Category Level'
     FROM apps.qa_sl_sp_rcv_criteria skip,
          apps.mtl_system_items_b ITEM,
          apps.MTL_ITEM_CATEGORIES_V cat,
          apps.qa_sampling_association det,
          apps.qa_sampling_plans plan,
          apps.mtl_parameters org,
          apps.QA_PLANS QA
    WHERE     item.organization_id = org.organization_id
          AND cat.category_set_name(+) = 'Quality'
          AND cat.organization_id(+) = item.organization_id
          AND cat.INVENTORY_ITEM_ID(+) = item.inventory_item_id
          AND skip.ORGANIZATION_ID(+) = cat.organization_id
          AND SKIP.ITEM_CATEGORY_ID(+) = CAT.CATEGORY_ID
          AND qa.PLAN_ID(+) = det.COLLECTION_PLAN_ID
          AND NOT EXISTS
                 (SELECT 1
                    FROM apps.qa_sl_sp_rcv_criteria skip_a
                   WHERE     skip_a.organization_id = item.organization_id
                         AND skip_a.item_id = item.inventory_item_id)
          AND det.CRITERIA_ID(+) = skip.criteria_id
          AND det.SAMPLING_PLAN_ID = plan.sampling_plan_id(+)
          -- exclude Obsolete, Make item and Direct receipt routing
          AND item.inventory_item_status_code NOT IN ('Inactive', 'Obsolete')
          AND ITEM.PLANNING_MAKE_BUY_CODE = 2                           -- Buy
   ORDER BY 1;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_QA_AQL_LIST_V FOR APPS.XX_BI_P2M_QA_AQL_LIST_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_P2M_QA_AQL_LIST_V TO ETLEBSUSER;
