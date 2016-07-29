DROP VIEW APPS.XX_BI_M2C_ITEM_CODES;

/* Formatted on 6/6/2016 4:59:29 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_ITEM_CODES
(
   ITEM_NUMBER,
   DESCRIPTION,
   SALES_MARKETING_CATEGORY,
   A_CODE,
   A_CODE_DESCRIPTION,
   B_CODE,
   B_CODE_DESCRIPTION,
   C_CODE,
   C_CODE_DESCRIPTION,
   D_CODE,
   D_CODE_DESCRIPTION
)
AS
   SELECT DISTINCT
          inv.segment1 Item_Number,
          inv.description Description,
          (SELECT cat2.concatenated_segments
             FROM apps.mtl_categories_kfv cat2, apps.mtl_item_categories ic2
            WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                  AND inv.inventory_item_id = ic2.inventory_item_id(+)
                  AND ic2.organization_id(+) = 107
                  AND ic2.category_set_id(+) = 1000001005
                  AND cat2.structure_id(+) = 50255)
             Sales_Marketing_Category,
          (SELECT SUBSTR (cat2.concatenated_segments, 1, 5)
             FROM apps.mtl_categories_kfv cat2, apps.mtl_item_categories ic2
            WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                  AND inv.inventory_item_id = ic2.inventory_item_id(+)
                  AND ic2.organization_id(+) = 107
                  AND ic2.category_set_id(+) = 1000001005
                  AND cat2.structure_id(+) = 50255)
             A_Code,
          (SELECT fvt.description code_Description
             FROM fnd_flex_values ffv,
                  fnd_flex_value_sets fvs,
                  fnd_flex_values_tl fvt
            WHERE     ffv.flex_value_set_id = fvs.flex_value_set_id
                  AND fvs.flex_value_set_name IN ('ITGR_CATG_SM_ACODE',
                                                  'ITGR_CATG_SM_BCODE',
                                                  'ITGR_CATG_SM_CCODE',
                                                  'ITGR_CATG_SM_DCODE')
                  AND fvt.language = 'US'
                  AND fvt.flex_value_id = ffv.flex_value_id
                  AND NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                  AND NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                  AND ffv.flex_value =
                         (SELECT SUBSTR (cat2.concatenated_segments, 1, 5)
                            FROM apps.mtl_categories_kfv cat2,
                                 apps.mtl_item_categories ic2
                           WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                                 AND inv.inventory_item_id =
                                        ic2.inventory_item_id(+)
                                 AND ic2.organization_id(+) = 107
                                 AND ic2.category_set_id(+) = 1000001005
                                 AND cat2.structure_id(+) = 50255))
             A_Code_Description,
          (SELECT SUBSTR (cat2.concatenated_segments, 7, 5)
             FROM apps.mtl_categories_kfv cat2, apps.mtl_item_categories ic2
            WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                  AND inv.inventory_item_id = ic2.inventory_item_id(+)
                  AND ic2.organization_id(+) = 107
                  AND ic2.category_set_id(+) = 1000001005
                  AND cat2.structure_id(+) = 50255)
             B_Code,
          (SELECT fvt.description code_Description
             FROM fnd_flex_values ffv,
                  fnd_flex_value_sets fvs,
                  fnd_flex_values_tl fvt
            WHERE     ffv.flex_value_set_id = fvs.flex_value_set_id
                  AND fvs.flex_value_set_name IN ('ITGR_CATG_SM_ACODE',
                                                  'ITGR_CATG_SM_BCODE',
                                                  'ITGR_CATG_SM_CCODE',
                                                  'ITGR_CATG_SM_DCODE')
                  AND fvt.language = 'US'
                  AND fvt.flex_value_id = ffv.flex_value_id
                  AND NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                  AND NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                  AND ffv.flex_value =
                         (SELECT SUBSTR (cat2.concatenated_segments, 7, 5)
                            FROM apps.mtl_categories_kfv cat2,
                                 apps.mtl_item_categories ic2
                           WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                                 AND inv.inventory_item_id =
                                        ic2.inventory_item_id(+)
                                 AND ic2.organization_id(+) = 107
                                 AND ic2.category_set_id(+) = 1000001005
                                 AND cat2.structure_id(+) = 50255))
             B_Code_Description,
          (SELECT SUBSTR (cat2.concatenated_segments, 13, 5)
             FROM apps.mtl_categories_kfv cat2, apps.mtl_item_categories ic2
            WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                  AND inv.inventory_item_id = ic2.inventory_item_id(+)
                  AND ic2.organization_id(+) = 107
                  AND ic2.category_set_id(+) = 1000001005
                  AND cat2.structure_id(+) = 50255)
             C_Code,
          (SELECT fvt.description code_Description
             FROM fnd_flex_values ffv,
                  fnd_flex_value_sets fvs,
                  fnd_flex_values_tl fvt
            WHERE     ffv.flex_value_set_id = fvs.flex_value_set_id
                  AND fvs.flex_value_set_name IN ('ITGR_CATG_SM_ACODE',
                                                  'ITGR_CATG_SM_BCODE',
                                                  'ITGR_CATG_SM_CCODE',
                                                  'ITGR_CATG_SM_DCODE')
                  AND fvt.language = 'US'
                  AND fvt.flex_value_id = ffv.flex_value_id
                  AND NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                  AND NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                  AND ffv.flex_value =
                         (SELECT SUBSTR (cat2.concatenated_segments, 13, 5)
                            FROM apps.mtl_categories_kfv cat2,
                                 apps.mtl_item_categories ic2
                           WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                                 AND inv.inventory_item_id =
                                        ic2.inventory_item_id(+)
                                 AND ic2.organization_id(+) = 107
                                 AND ic2.category_set_id(+) = 1000001005
                                 AND cat2.structure_id(+) = 50255))
             C_Code_Description,
          (SELECT SUBSTR (cat2.concatenated_segments, 19, 5)
             FROM apps.mtl_categories_kfv cat2, apps.mtl_item_categories ic2
            WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                  AND inv.inventory_item_id = ic2.inventory_item_id(+)
                  AND ic2.organization_id(+) = 107
                  AND ic2.category_set_id(+) = 1000001005
                  AND cat2.structure_id(+) = 50255)
             D_Code,
          (SELECT fvt.description code_Description
             FROM fnd_flex_values ffv,
                  fnd_flex_value_sets fvs,
                  fnd_flex_values_tl fvt
            WHERE     ffv.flex_value_set_id = fvs.flex_value_set_id
                  AND fvs.flex_value_set_name IN ('ITGR_CATG_SM_ACODE',
                                                  'ITGR_CATG_SM_BCODE',
                                                  'ITGR_CATG_SM_CCODE',
                                                  'ITGR_CATG_SM_DCODE')
                  AND fvt.language = 'US'
                  AND fvt.flex_value_id = ffv.flex_value_id
                  AND NVL (ffv.start_date_active, SYSDATE) <= SYSDATE
                  AND NVL (ffv.end_date_active, SYSDATE) >= SYSDATE
                  AND ffv.flex_value =
                         (SELECT SUBSTR (cat2.concatenated_segments, 19, 5)
                            FROM apps.mtl_categories_kfv cat2,
                                 apps.mtl_item_categories ic2
                           WHERE     ic2.CATEGORY_ID = cat2.category_id(+)
                                 AND inv.inventory_item_id =
                                        ic2.inventory_item_id(+)
                                 AND ic2.organization_id(+) = 107
                                 AND ic2.category_set_id(+) = 1000001005
                                 AND cat2.structure_id(+) = 50255))
             D_Code_Description
     FROM apps.mtl_system_items_b inv;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_ITEM_CODES FOR APPS.XX_BI_M2C_ITEM_CODES;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_ITEM_CODES FOR APPS.XX_BI_M2C_ITEM_CODES;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_ITEM_CODES FOR APPS.XX_BI_M2C_ITEM_CODES;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_ITEM_CODES FOR APPS.XX_BI_M2C_ITEM_CODES;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_ITEM_CODES TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_ITEM_CODES TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_ITEM_CODES TO XXINTG;
