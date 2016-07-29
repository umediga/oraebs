DROP VIEW APPS.XX_BI_P2M_OHQTY_V;

/* Formatted on 6/6/2016 4:59:09 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_OHQTY_V
(
   ORGANIZATION,
   PROCESS_ITEM_NUMBER,
   ITEM_DESCRIPTION,
   SUB_INVENTORY_NAME,
   ON_HAND_QUANTITY,
   LOT_NUMBER,
   SERIAL_NUMBER,
   LOCATOR,
   CCODE,
   CCODE_DESCRIPTION,
   DCODE,
   DCODE_DESCRIPTION,
   STANDARD_COST,
   LOT_EXPIRATION_DATE,
   ABC_CLASSIFICATION,
   CREATE_TRANSACTION_ID
)
AS
   SELECT ood.organization_code ORGANIZATION,
          msi.segment1 process_item_number,
          msi.description item_description,
          moq.subinventory_code sub_inventory_name,
          DECODE (msn.serial_number,
                  NULL, moq.transaction_quantity,
                  msn.serial_number, 1)
             on_hand_quantity,
          moq.lot_number,
          msn.serial_number,
          mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
             "Locator",
          mcb.segment8 AS ccode,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment8
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             ccode_description,
          mcb.segment9 AS dcode,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment9
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             dcode_description,
          cst.item_cost standard_cost,
          mln.expiration_date lot_expiration_date,
          z.abc_class_name abc_classification,
          NULL
     FROM apps.org_organization_definitions ood,
          apps.mtl_system_items_b msi,
          apps.mtl_onhand_quantities moq,
          apps.cst_item_costs cst,
          apps.cst_cost_types cct,
          apps.mtl_lot_numbers mln,
          apps.mtl_item_locations mil,
          apps.mtl_serial_numbers msn,
          apps.mtl_item_categories mic,
          apps.mtl_category_sets_tl mcst,
          apps.mtl_category_sets_b mcsb,
          apps.mtl_categories_b mcb,
          --MTL_ABC_CLASSES MAC,
          --MTL_ABC_ASSIGNMENTS MAA
          (SELECT mac.abc_class_name abc_classification,
                  mac.organization_id,
                  maa.inventory_item_id,
                  mac.abc_class_name,
                  maa.abc_class_id
             FROM apps.mtl_abc_classes mac,
                  apps.mtl_abc_assignments maa,
                  apps.mtl_system_items_b msib
            WHERE     maa.inventory_item_id = msib.inventory_item_id
                  AND mac.organization_id = msib.organization_id
                  AND maa.abc_class_id = mac.abc_class_id
                  AND maa.assignment_group_id = 1) z
    WHERE     ood.organization_id = msi.organization_id
          AND msi.organization_id = moq.organization_id
          AND msi.inventory_item_id = moq.inventory_item_id
          AND msi.inventory_item_id = cst.inventory_item_id
          AND ood.organization_id = cst.organization_id
          AND UPPER (cct.cost_type) = 'FROZEN'
          AND cct.cost_type_id = cst.cost_type_id
          AND moq.inventory_item_id = mln.inventory_item_id(+)
          AND moq.lot_number = mln.lot_number(+)
          AND moq.organization_id = mln.organization_id(+)
          AND moq.inventory_item_id = msn.inventory_item_id(+)
          AND moq.organization_id = msn.current_organization_id(+)
          AND moq.subinventory_code = msn.current_subinventory_code(+)
          AND moq.locator_id = msn.current_locator_id
          AND NVL (moq.lot_number, 'ABC') = NVL (msn.lot_number, 'ABC')
          --AND moq.create_transaction_id= msn.last_transaction_id(+)
          AND mcst.category_set_id = mcsb.category_set_id
          AND mcst.LANGUAGE = USERENV ('LANG')
          AND moq.organization_id = mil.organization_id(+)
          AND moq.locator_id = mil.inventory_location_id(+)
          AND moq.subinventory_code = mil.subinventory_code(+)
          AND mic.category_set_id = mcsb.category_set_id
          AND mic.category_id = mcb.category_id
          AND mcst.category_set_name = 'Sales and Marketing'
          AND mic.inventory_item_id = msi.inventory_item_id
          AND mic.organization_id = msi.organization_id
          AND z.inventory_item_id(+) = msi.inventory_item_id
          AND z.organization_id(+) = msi.organization_id
          --AND  moq.organization_id =2103
          --AND msi.segment1='1523077'
          AND msn.current_status(+) = 3
   UNION
   SELECT ood.organization_code ORGANIZATION,
          msi.segment1 process_item_number,
          msi.description item_description,
          moq.subinventory_code sub_inventory_name,
          DECODE (msn.serial_number,
                  NULL, moq.transaction_quantity,
                  msn.serial_number, 1)
             on_hand_quantity,
          moq.lot_number,
          msn.serial_number,
          mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
             "Locator",
          mcb.segment8 AS ccode,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment8
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             ccode_description,
          mcb.segment9 AS dcode,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment9
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             dcode_description,
          cst.item_cost standard_cost,
          mln.expiration_date lot_expiration_date,
          z.abc_class_name abc_classification,
          moq.create_transaction_id
     FROM apps.org_organization_definitions ood,
          apps.mtl_system_items_b msi,
          apps.mtl_onhand_quantities moq,
          apps.cst_item_costs cst,
          apps.cst_cost_types cct,
          apps.mtl_lot_numbers mln,
          apps.mtl_serial_numbers msn,
          apps.mtl_item_locations mil,
          apps.mtl_item_categories mic,
          apps.mtl_category_sets_tl mcst,
          apps.mtl_category_sets_b mcsb,
          apps.mtl_categories_b mcb,
          --MTL_ABC_CLASSES MAC,
          --MTL_ABC_ASSIGNMENTS MAA
          (SELECT mac.abc_class_name abc_classification,
                  mac.organization_id,
                  maa.inventory_item_id,
                  mac.abc_class_name,
                  maa.abc_class_id
             FROM apps.mtl_abc_classes mac,
                  apps.mtl_abc_assignments maa,
                  apps.mtl_system_items_b msib
            WHERE     maa.inventory_item_id = msib.inventory_item_id
                  AND mac.organization_id = msib.organization_id
                  AND maa.abc_class_id = mac.abc_class_id
                  AND maa.assignment_group_id = 1) z
    WHERE     ood.organization_id = msi.organization_id
          AND msi.organization_id = moq.organization_id
          AND msi.inventory_item_id = moq.inventory_item_id
          AND msi.inventory_item_id = cst.inventory_item_id
          AND ood.organization_id = cst.organization_id
          AND UPPER (cct.cost_type) = 'FROZEN'
          AND cct.cost_type_id = cst.cost_type_id
          AND moq.inventory_item_id = mln.inventory_item_id
          AND moq.lot_number = mln.lot_number(+)
          AND moq.organization_id = mln.organization_id(+)
          AND moq.inventory_item_id = msn.inventory_item_id(+)
          AND moq.organization_id = msn.current_organization_id(+)
          AND moq.subinventory_code = msn.current_subinventory_code(+)
          AND moq.locator_id = msn.current_locator_id(+)
          --AND NVL (moq.lot_number, 'ABC') = NVL (msn.lot_number(+), 'ABC')
          AND moq.create_transaction_id = msn.last_transaction_id(+)
          AND mcst.category_set_id = mcsb.category_set_id
          AND mcst.LANGUAGE = USERENV ('LANG')
          AND moq.organization_id = mil.organization_id(+)
          AND moq.locator_id = mil.inventory_location_id(+)
          AND moq.subinventory_code = mil.subinventory_code(+)
          AND mic.category_set_id = mcsb.category_set_id
          AND mic.category_id = mcb.category_id
          AND mcst.category_set_name = 'Sales and Marketing'
          AND mic.inventory_item_id = msi.inventory_item_id
          AND mic.organization_id = msi.organization_id
          AND z.inventory_item_id(+) = msi.inventory_item_id
          AND z.organization_id(+) = msi.organization_id
          AND NOT EXISTS
                 (SELECT 1
                    FROM apps.mtl_serial_numbers msn
                   WHERE     msn.inventory_item_id = msi.inventory_item_id
                         AND msn.current_organization_id =
                                msi.organization_id
                         AND msn.current_status(+) = 3
                         AND msn.current_subinventory_code =
                                moq.subinventory_code
                         AND moq.locator_id = msn.current_locator_id)
          --    AND  moq.organization_id =2103
          -- AND msi.segment1='1523077'
          AND msn.current_status(+) = 3
   UNION ALL
   SELECT ood.organization_code ORGANIZATION,
          msi.segment1 process_item_number,
          msi.description item_description,
          moq.subinventory_code sub_inventory_name,
          moq.transaction_quantity,
          NULL lot_number,
          NULL serial_number,
          mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
             "Locator",
          mcb.segment8 AS ccode,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment8
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             ccode_description,
          mcb.segment9 AS dcode,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment9
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             dcode_description,
          cst.item_cost standard_cost,
          NULL lot_expiration_date,
          z.abc_class_name abc_classification,
          NULL
     FROM apps.org_organization_definitions ood,
          apps.mtl_system_items_b msi,
          apps.mtl_onhand_quantities moq,
          apps.cst_item_costs cst,
          apps.cst_cost_types cct,
          apps.mtl_item_locations mil,
          apps.mtl_item_categories mic,
          apps.mtl_category_sets_tl mcst,
          apps.mtl_category_sets_b mcsb,
          apps.mtl_categories_b mcb,
          (SELECT mac.abc_class_name abc_classification,
                  mac.organization_id,
                  maa.inventory_item_id,
                  mac.abc_class_name,
                  maa.abc_class_id
             FROM apps.mtl_abc_classes mac,
                  apps.mtl_abc_assignments maa,
                  apps.mtl_system_items_b msib
            WHERE     maa.inventory_item_id = msib.inventory_item_id
                  AND mac.organization_id = msib.organization_id
                  AND maa.abc_class_id = mac.abc_class_id
                  AND maa.assignment_group_id = 1) z
    WHERE     ood.organization_id = msi.organization_id
          AND msi.organization_id = moq.organization_id
          AND msi.inventory_item_id = moq.inventory_item_id
          AND msi.inventory_item_id = cst.inventory_item_id
          AND ood.organization_id = cst.organization_id
          AND UPPER (cct.cost_type) = 'FROZEN'
          AND cct.cost_type_id = cst.cost_type_id
          AND mcst.category_set_id = mcsb.category_set_id
          AND mcst.LANGUAGE = USERENV ('LANG')
          AND mic.category_set_id = mcsb.category_set_id
          AND moq.organization_id = mil.organization_id(+)
          AND moq.locator_id = mil.inventory_location_id(+)
          AND moq.subinventory_code = mil.subinventory_code(+)
          AND mic.category_id = mcb.category_id
          AND mcst.category_set_name = 'Sales and Marketing'
          AND mic.inventory_item_id = msi.inventory_item_id
          AND mic.organization_id = msi.organization_id
          AND z.inventory_item_id(+) = msi.inventory_item_id
          AND z.organization_id(+) = msi.organization_id
          AND NOT EXISTS
                 (SELECT 1
                    FROM apps.mtl_serial_numbers msn
                   WHERE     msn.inventory_item_id = msi.inventory_item_id
                         AND msn.current_organization_id =
                                msi.organization_id
                         AND msn.current_status(+) = 3
                         AND msn.current_subinventory_code =
                                moq.subinventory_code
                         AND moq.locator_id = msn.current_locator_id)
          AND NOT EXISTS
                 (SELECT 1
                    FROM apps.mtl_lot_numbers mln
                   WHERE     moq.inventory_item_id = mln.inventory_item_id
                         AND moq.lot_number = mln.lot_number
                         AND moq.organization_id = mln.organization_id);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_OHQTY_V FOR APPS.XX_BI_P2M_OHQTY_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2M_OHQTY_V FOR APPS.XX_BI_P2M_OHQTY_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2M_OHQTY_V FOR APPS.XX_BI_P2M_OHQTY_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2M_OHQTY_V FOR APPS.XX_BI_P2M_OHQTY_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_P2M_OHQTY_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_P2M_OHQTY_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_P2M_OHQTY_V TO XXINTG;
