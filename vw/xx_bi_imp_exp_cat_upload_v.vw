DROP VIEW APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V;

/* Formatted on 6/6/2016 4:59:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V
(
   ORG_CODE,
   ORG_NAME,
   ITEM,
   ITEM_DESC,
   STATUS,
   UOM,
   ITEM_TYPE,
   ITEM_TYPE_DESC,
   ILS_MFG_SITE,
   ILS_MFG_SITE_DESCRIPTION,
   MANUFACTURER,
   COUNTRY_OF_ORIGIN,
   COUNTRY_OF_ORIGIN_FULL_NAME,
   HTS_DESC,
   HTS_DESC_DESCRIPTION,
   DUTY_PERCENTAGE,
   PMA_510K,
   FDA_CODE,
   VENDOR_FDA_EST_REG_NBR,
   VENDOR_DEVICE_NUMBER,
   SCH_B,
   SCHEDULE_B_LONG_DESCRIPTION,
   ECCN,
   ECCN_DESCRIPTION,
   LICENSE_REQD,
   ILS_EST_REG_NBR,
   ILS_DEVICE_NUMBER,
   OPERATING_UNIT
)
AS
   SELECT ood.organization_code org_code,
          ood.organization_name org_name,
          inv.segment1 item,
          inv.description item_desc,
          inv.inventory_item_status_code status,
          inv.primary_unit_of_measure uom,
          inv.item_type item_type,
          flv.meaning item_type_desc,
          inv.attribute11,
          inv.attribute12,
          inv.attribute11,
          inv.attribute9,
          ftt.territory_short_name country_of_origin_full_name,
          inv.attribute13,
          (SELECT ffvt.description
             FROM fnd_flex_value_sets ffvs,
                  fnd_flex_values_tl ffvt,
                  fnd_flex_values ffv
            WHERE     flex_value_set_name = 'INTG_HTS_CODE'
                  AND ffvt.LANGUAGE = USERENV ('LANG')
                  AND ffvt.flex_value_id = ffv.flex_value_id
                  AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                  AND ffv.flex_value LIKE inv.attribute13)
             hts_desc_description,
          --inv.attribute13,
          NVL (
             (SELECT ffv.attribute2
                FROM fnd_flex_value_sets ffvs,
                     fnd_flex_values_tl ffvt,
                     fnd_flex_values ffv
               WHERE     flex_value_set_name = 'INTG_HTS_CODE'
                     AND ffvt.LANGUAGE = USERENV ('LANG')
                     AND ffvt.flex_value_id = ffv.flex_value_id
                     AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                     AND ffv.flex_value LIKE inv.attribute13),
             0)
             "DUTY PCT",
          inv.attribute20,
          inv.attribute21,
          inv.attribute25,
          inv.attribute23,
          inv.attribute17 schedule_b,
          (SELECT ffvt.description
             FROM fnd_flex_value_sets ffvs,
                  fnd_flex_values_tl ffvt,
                  fnd_flex_values ffv
            WHERE     flex_value_set_name = 'INTG_SCHEDULE_B_NUMBER'
                  AND ffvt.LANGUAGE = USERENV ('LANG')
                  AND ffvt.flex_value_id = ffv.flex_value_id
                  AND ffv.flex_value_set_id = ffvs.flex_value_set_id
                  AND ffv.flex_value LIKE inv.attribute17)
             schedule_b_long_description,
          inv.attribute18,
          inv.attribute18,
          inv.attribute19,
          inv.attribute22,
          inv.attribute6,
          hou.organization_id
     FROM apps.mtl_system_items_b inv,
          apps.po_asl_attributes paa,
          org_organization_definitions ood,
          fnd_lookup_values flv,
          fnd_territories_tl ftt,
          hr_operating_units hou
    WHERE     inv.inventory_item_id = paa.item_id(+)
          AND inv.organization_id = paa.using_organization_id(+)
          AND inv.organization_id = ood.organization_id(+)
          AND inv.item_type = flv.lookup_code(+)
          AND flv.lookup_type = 'ITEM_TYPE'
          AND flv.LANGUAGE = 'US'
          AND flv.view_application_id = 3
          AND ftt.territory_code = inv.attribute9
          AND ftt.LANGUAGE = USERENV ('LANG')
          AND hou.organization_id = ood.operating_unit;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_IMP_EXP_CAT_UPLOAD_V FOR APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_IMP_EXP_CAT_UPLOAD_V FOR APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_IMP_EXP_CAT_UPLOAD_V FOR APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_IMP_EXP_CAT_UPLOAD_V FOR APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_IMP_EXP_CAT_UPLOAD_V TO XXINTG;
