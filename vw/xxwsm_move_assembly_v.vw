DROP VIEW APPS.XXWSM_MOVE_ASSEMBLY_V;

/* Formatted on 6/6/2016 5:00:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXWSM_MOVE_ASSEMBLY_V
(
   TRANSACTION_ID,
   REASON_ID,
   SUBINVENTORY_CODE,
   LOCATOR_ID,
   TRANSACTION_QUANTITY,
   TRANSACTION_UOM,
   TRANSACTION_REFERENCE,
   REASON_NAME,
   TRANSACTION_SOURCE_ID,
   TRANSACTION_SET_ID
)
AS
   SELECT mmt.transaction_id,
          mmt.reason_id,
          mmt.subinventory_code,
          mmt.locator_id,
          mmt.transaction_quantity,
          mmt.transaction_uom,
          mmt.transaction_reference,
          mtr.reason_name,
          mmt.transaction_source_id,
          mmt.transaction_set_id
     FROM mtl_material_transactions mmt, mtl_transaction_reasons mtr
    WHERE mmt.reason_id = mtr.reason_id(+);
