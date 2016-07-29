DROP VIEW APPS.XX_OLM_CLASS_NAME_VW;

/* Formatted on 6/6/2016 4:58:22 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OLM_CLASS_NAME_VW
(
   TITLE,
   EVENT_ID
)
AS
   SELECT "TITLE", "EVENT_ID"
     FROM (SELECT 'ALL' title, 00 event_id FROM DUAL
           UNION
           SELECT oet.title, oet.event_id
             FROM ota_activity_versions tav,
                  ota_activity_versions_tl tat,
                  po_vendors ven,
                  ota_act_cat_inclusions aci,
                  ota_category_usages_vl act,
                  ota_category_usages_tl par,
                  ota_events_tl oet,
                  ota_events oe
            WHERE     tav.activity_version_id = tat.activity_version_id
                  AND oe.activity_version_id = tav.activity_version_id
                  AND oe.event_id = oet.event_id
                  AND tat.LANGUAGE = USERENV ('LANG')
                  AND oet.language = USERENV ('LANG')
                  AND tav.vendor_id = ven.vendor_id(+)
                  AND aci.activity_version_id = tav.activity_version_id
                  AND act.category_usage_id = aci.category_usage_id
                  AND act.parent_cat_usage_id = par.category_usage_id
                  AND par.LANGUAGE = USERENV ('LANG')
                  AND act.TYPE = 'C'
                  AND tav.business_group_id =
                         ota_general.get_business_group_id
                  AND aci.primary_flag = 'Y'
                  AND ota_admin_access_util.admin_can_access_object (
                         'H',
                         oet.event_id) = 'Y'
           ORDER BY title);
