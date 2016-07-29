DROP VIEW APPS.XX_BI_FI_ALL_ITM_V;

/* Formatted on 6/6/2016 4:59:55 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_ALL_ITM_V
(
   ITEM_CATEGORY,
   ITEM,
   ITEM_DESC,
   CCODE,
   CCODE_DESC,
   DCODE,
   DCODE_DESC,
   ORG_CODE,
   ORG_NAME
)
AS
   SELECT micv.category_set_name item_category,
          msib.segment1 item,
          msib.description item_desc,
          MCB.SEGMENT8 ccode,
          (SELECT fvt.description
             FROM fnd_flex_value_sets fvs,
                  fnd_flex_values ffv,
                  fnd_flex_values_tl fvt
            WHERE     ROWNUM = 1
                  AND fvt.LANGUAGE = USERENV ('LANG')
                  AND MCB.SEGMENT8 = ffv.flex_value
                  AND ffv.flex_value_set_id = fvs.flex_value_set_id
                  AND ffv.flex_value_id = fvt.flex_value_id)
             ccode_desc,
          MCB.SEGMENT9 dcode,
          (SELECT fvt.description
             FROM fnd_flex_value_sets fvs,
                  fnd_flex_values ffv,
                  fnd_flex_values_tl fvt
            WHERE     ROWNUM = 1
                  AND fvt.LANGUAGE = USERENV ('LANG')
                  AND MCB.SEGMENT9 = ffv.flex_value
                  AND ffv.flex_value_set_id = fvs.flex_value_set_id
                  AND ffv.flex_value_id = fvt.flex_value_id)
             dcode_desc,
          ood.organization_code org_code,
          ood.organization_name org_name
     FROM apps.mtl_system_items_b msib,
          apps.mtl_item_categories_v micv,
          APPS.MTL_CATEGORIES_B MCB,
          apps.po_asl_attributes paa,
          org_organization_definitions ood
    WHERE     msib.inventory_item_id = paa.item_id(+)
          AND msib.organization_id = paa.using_organization_id(+)
          AND msib.inventory_item_id = micv.inventory_item_id
          AND MCB.CATEGORY_ID = micv.CATEGORY_ID
          AND msib.organization_id = micv.organization_id
          AND msib.organization_id = ood.organization_id(+);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_ALL_ITM_V FOR APPS.XX_BI_FI_ALL_ITM_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_ALL_ITM_V FOR APPS.XX_BI_FI_ALL_ITM_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_ALL_ITM_V FOR APPS.XX_BI_FI_ALL_ITM_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_ALL_ITM_V FOR APPS.XX_BI_FI_ALL_ITM_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ALL_ITM_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ALL_ITM_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ALL_ITM_V TO XXINTG;
