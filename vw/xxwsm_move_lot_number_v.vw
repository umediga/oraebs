DROP VIEW APPS.XXWSM_MOVE_LOT_NUMBER_V;

/* Formatted on 6/6/2016 5:00:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXWSM_MOVE_LOT_NUMBER_V
(
   ORGANIZATION_ID,
   TRANSACTION_ID,
   INVENTORY_ITEM_ID,
   LOT_NUMBER,
   SERIAL_TRANSACTION_ID,
   TRANS_QUANTITY,
   LOT_DESCRIPTION,
   VENDOR_NAME,
   SUPPLIER_LOT_NUMBER,
   GRADE_CODE,
   ORIGINATION_DATE,
   EXPIRATION_DATE
)
AS
   SELECT mtln.organization_id,
          mtln.transaction_id,
          mtln.inventory_item_id,
          mtln.lot_number,
          mtln.serial_transaction_id,
          mtln.transaction_quantity trans_quantity,
          mtln.description lot_description,
          mtln.vendor_name,
          mtln.supplier_lot_number,
          mtln.grade_code,
          mtln.origination_date,
          mln.expiration_date
     FROM mtl_lot_numbers mln, mtl_transaction_lot_numbers mtln
    WHERE     mtln.organization_id = mln.organization_id
          AND mtln.inventory_item_id = mln.inventory_item_id
          AND mtln.lot_number = mln.lot_number;
