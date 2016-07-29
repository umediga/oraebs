DROP VIEW APPS.XXWSM_MOVE_UNIT_TRANS_V;

/* Formatted on 6/6/2016 5:00:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXWSM_MOVE_UNIT_TRANS_V
(
   TRANSACTION_ID,
   SERIAL_NUMBER,
   INVENTORY_ITEM_ID,
   PARENT_SERIAL_NUMBER,
   VENDOR_SERIAL_NUMBER
)
AS
   SELECT mut.transaction_id,
          mut.serial_number,
          mut.inventory_item_id,
          msn.parent_serial_number,
          msn.vendor_serial_number
     FROM mtl_serial_numbers msn, mtl_unit_transactions mut
    WHERE     mut.serial_number = msn.serial_number
          AND mut.inventory_item_id = msn.inventory_item_id;
