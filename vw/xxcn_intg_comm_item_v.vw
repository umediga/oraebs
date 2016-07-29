DROP VIEW APPS.XXCN_INTG_COMM_ITEM_V;

/* Formatted on 6/6/2016 5:00:27 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXCN_INTG_COMM_ITEM_V
(
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   CATEGORY_SEGMENT1,
   CATEGORY_SEGMENT2,
   CATEGORY_SEGMENT3,
   CATEGORY_SEGMENT4,
   CATEGORY_SEGMENT5,
   INVENTORY_ITEM_STATUS_CODE,
   INVENTORY_ITEM_ID,
   ORGANIZATION_ID,
   ITEM_TYPE_CODE,
   ORG_ID,
   ACTIVE_FLAG
)
AS
   SELECT msib.segment1 item_number,
          msib.DESCRIPTION item_description,
          mc.segment1 category_segment1,
          mc.segment2 category_segment2,
          mc.segment3 category_segment3,
          mc.segment4 category_segment4,
          mc.segment5 category_segment5,
          msib.inventory_item_status_code,
          msib.inventory_item_id,
          ood.organization_id,
          msib.item_type item_type_code,
          ood.operating_unit org_id,
          msib.inventory_item_status_code active_flag
     FROM apps.org_organization_definitions ood,
          apps.mtl_parameters mp,
          apps.mtl_item_categories mic,
          apps.mtl_category_sets_tl mcst,
          apps.mtl_system_items_b msib,
          apps.mtl_categories mc
    WHERE     1 = 1
          AND msib.inventory_item_id = mic.inventory_item_id
          AND ood.organization_id = mp.organization_id
          AND msib.organization_id = mp.organization_id
          AND mp.organization_id != mp.master_organization_id
          AND msib.organization_id = mic.organization_id
          AND mic.category_id = mc.category_id
          AND mic.category_set_id = mcst.category_set_id
          AND UPPER (mcst.category_set_name) =
                 UPPER (
                    xx_emf_pkg.get_paramater_value ('XXINTG_CN_COMM_ITEM',
                                                    'CATEGORY_SET'))
          AND mcst.LANGUAGE = USERENV ('LANG')
          -- Check for Commissionable --
          AND NVL (msib.attribute4, 'XXX') =
                 xx_emf_pkg.get_paramater_value ('XXINTG_CN_COMM_ITEM',
                                                 'COMMISSIONABLE_FLAG')
          AND TRUNC (SYSDATE) BETWEEN NVL (
                                         fnd_date.canonical_to_date (
                                            msib.attribute5),
                                         TRUNC (SYSDATE))
                                  AND NVL (
                                         fnd_date.canonical_to_date (
                                            msib.attribute6),
                                         TRUNC (SYSDATE));
