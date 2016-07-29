DROP PACKAGE BODY APPS.XX_OSFM_WIP_ITEM_REQMTS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OSFM_WIP_ITEM_REQMTS_PKG"
AS
  ----------------------------------------------------------------------
  /*
  Created By     : IBM Development Team
  Creation Date  : 11-Sep-2012
  File Name      : xx_wip_item_requirements_pkg.pkb
  Description    : This script creates the body of the package xx_wip_item_requirements_pkg
  Version Date        Name        Remarks
  ------- ----------- ---------        ------------------------------------------------------------------------
  1.0     11-Sep-2012 Mou Mukherjee        Initial development.
  2.0     11-Sep-2015 Prasanna Sunkad     Ticket4358#
  -------------------------------------------------------------------------------------------------------------
  */
PROCEDURE load_item_requirements(
    p_wip_entity_id IN NUMBER ,
    x_status OUT VARCHAR2 ,
    x_msg OUT VARCHAR2 )
IS
  CURSOR c_get_items
  IS
    SELECT wro.wip_entity_id ,
      wro.operation_seq_num ,
      wro.inventory_item_id ,
      wro.organization_id ,
      wro.segment1 component ,
      WRO.REQUIRED_QUANTITY ,
      DECODE(WDJ.STATUS_TYPE,12,DECODE(NVL(WRO.QUANTITY_ISSUED,0),0,0,ABS(WRO.QUANTITY_ISSUED)),DECODE(NVL(WRO.QUANTITY_ISSUED,0),0,'',ABS(WRO.QUANTITY_ISSUED)))QUANTITY_ISSUED,
      --ABS(WRO.QUANTITY_ISSUED) quantity_issued,
      NVL(WRO.QUANTITY_ALLOCATED,0) QUANTITY_ALLOCATED,
      --,(wro.required_quantity - wro.quantity_issued) open_quantity
      ((wro.required_quantity - wro.quantity_issued) - NVL(wro.quantity_allocated,0)) unallocated_qty ,
      msib.description ,
      msib.primary_uom_code ,
      msib.serial_number_control_code ,
      MSIB.LOT_CONTROL_CODE ,
      MFGL.MEANING WIP_SUPPLY_TYPE
      /*(
      CASE
      WHEN wro.quantity_issued <>0
      THEN
      (SELECT mttt.subinventory_code
      FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID = WRO.WIP_ENTITY_ID
      AND mttt.inventory_item_id       = msib.inventory_item_id
      AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
      AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID
      )
      ELSE NULL
      END )SUBINVENTORY_CODE,
      (
      CASE
      WHEN wro.quantity_issued <>0
      THEN
      (SELECT milk.concatenated_segments
      FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID = WRO.WIP_ENTITY_ID
      AND mttt.inventory_item_id       = msib.inventory_item_id
      AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
      AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID
      )
      ELSE NULL
      END )CONCATENATED_SEGMENTS,
      DECODE(msib.serial_number_control_code,1,(
      CASE
      WHEN wro.quantity_issued <>0
      THEN
      (SELECT mtlt.lot_number
      FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID = WRO.WIP_ENTITY_ID
      AND mttt.inventory_item_id       = msib.inventory_item_id
      AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
      AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID
      )
      ELSE NULL
      END ),
      (SELECT msnt.serial_number serial_number
      FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_unit_transactions msnt ,
      MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID =WRO.WIP_ENTITY_ID
      AND mttt.inventory_item_id       = msib.inventory_item_id
      AND MTTT.TRANSACTION_ID          = MSNT.TRANSACTION_ID
      AND mttt.locator_id              = milk.inventory_location_id
      ))lot_number,
      (
      CASE
      WHEN wro.quantity_issued <>0
      THEN
      (SELECT mtlt.expiration_date
      FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID = WRO.WIP_ENTITY_ID
      AND mttt.inventory_item_id       = msib.inventory_item_id
      AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
      AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID
      )
      ELSE NULL
      END )expiration_date*/
    FROM WIP_REQUIREMENT_OPERATIONS WRO ,
      WIP_DISCRETE_JOBS WDJ,
      MTL_SYSTEM_ITEMS_B MSIB,
      MFG_LOOKUPS MFGL
    WHERE WRO.WIP_ENTITY_ID   = NVL(P_WIP_ENTITY_ID,WRO.WIP_ENTITY_ID)
    AND WRO.WIP_ENTITY_ID     =WDJ.WIP_ENTITY_ID
    AND wro.organization_id   =wdj.organization_id
    AND wro.inventory_item_id = msib.inventory_item_id
    AND wro.organization_id   = msib.organization_id
    AND MFGL.LOOKUP_TYPE      = 'WIP_SUPPLY_SHORT'
    AND wdj.class_code       IN ('RWK_LOT','LOTMFG')
    AND MFGL.LOOKUP_CODE      = WRO.WIP_SUPPLY_TYPE
    ORDER BY WRO.SEGMENT1;
  CURSOR c_sub_inv (P_ENTITY_ID NUMBER,p_item_id NUMBER,P_serial_code VARCHAR2)
  IS
    SELECT DISTINCT mttt.subinventory_code SUBINVENTORY_CODE,
      MILK.CONCATENATED_SEGMENTS CONCATENATED_SEGMENTS,
      DECODE(P_serial_code,1, mtlt.lot_number,
      (SELECT msnt.serial_number serial_number
      FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
        MTL_UNIT_TRANSACTIONS MSNT ,
        MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID = P_ENTITY_ID
      AND MTTT.INVENTORY_ITEM_ID       = P_ITEM_ID
      AND MTTT.TRANSACTION_ID          = MSNT.TRANSACTION_ID
      AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID
      ))LOT_NUMBER,
      MTLT.EXPIRATION_DATE EXPIRATION_DATE,
     /* DECODE((SELECT STATUS_TYPE FROM WIP_DISCRETE_JOBS WHERE WIP_ENTITY_ID=P_ENTITY_ID),12,DECODE(NVL((select sum(MTLT.TRANSACTION_QUANTITY) FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
    WHERE MTTT.TRANSACTION_SOURCE_ID = P_ENTITY_ID
    AND MTTT.INVENTORY_ITEM_ID       = P_ITEM_ID
    AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
    AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID),0),0,0,ABS((select sum(MTLT.TRANSACTION_QUANTITY) FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
    WHERE MTTT.TRANSACTION_SOURCE_ID = P_ENTITY_ID
    AND MTTT.INVENTORY_ITEM_ID       = P_ITEM_ID
    AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
    AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID))),DECODE(NVL((select sum(MTLT.TRANSACTION_QUANTITY) FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
    WHERE MTTT.TRANSACTION_SOURCE_ID = P_ENTITY_ID
    AND MTTT.INVENTORY_ITEM_ID       = P_ITEM_ID
    AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
    AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID),0),0,'',ABS((select sum(MTLT.TRANSACTION_QUANTITY) FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      mtl_transaction_lot_val_v mtlt ,
      MTL_ITEM_LOCATIONS_KFV MILK
    WHERE MTTT.TRANSACTION_SOURCE_ID = P_ENTITY_ID
    AND MTTT.INVENTORY_ITEM_ID       = P_ITEM_ID
    AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
    AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID))))TRANSACTION_QUANTITY*/
    DECODE((SELECT STATUS_TYPE FROM WIP_DISCRETE_JOBS WHERE WIP_ENTITY_ID=P_ENTITY_ID),12,DECODE(NVL(MTLT.TRANSACTION_QUANTITY,0),0,0,ABS(MTLT.TRANSACTION_QUANTITY)),DECODE(NVL(MTLT.TRANSACTION_QUANTITY,0),0,'',ABS(MTLT.TRANSACTION_QUANTITY)))TRANSACTION_QUANTITY
      --abs(mtlt.transaction_quantity) transaction_quantity
    FROM MTL_MATERIAL_TRANSACTIONS MTTT ,
      MTL_TRANSACTION_LOT_VAL_V MTLT ,
      MTL_ITEM_LOCATIONS_KFV MILK
    WHERE MTTT.TRANSACTION_SOURCE_ID = P_ENTITY_ID
    AND MTTT.INVENTORY_ITEM_ID       = P_ITEM_ID
    AND MTTT.TRANSACTION_ID          = MTLT.TRANSACTION_ID
    AND MTTT.LOCATOR_ID              = MILK.INVENTORY_LOCATION_ID
    AND MTTT.TRANSACTION_TYPE_ID=35;
    x_wip_item_requirements_rec xx_wip_item_requirements_tmp%ROWTYPE;
    x_qty_temp NUMBER := 0;
  BEGIN
    -- Get items for the job
    FOR rec IN c_get_items
    LOOP
      -- When required open quantity is 0
      --    IF rec.open_quantity = 0 THEN
      x_wip_item_requirements_rec.wip_entity_id     := rec.wip_entity_id;
      x_wip_item_requirements_rec.operation_seq_num := rec.operation_seq_num;
      x_wip_item_requirements_rec.inventory_item_id := rec.inventory_item_id;
      x_wip_item_requirements_rec.organization_id   := rec.organization_id;
      x_wip_item_requirements_rec.item_code         := rec.component;
      x_wip_item_requirements_rec.item_desc         := rec.description;
      x_wip_item_requirements_rec.uom               := rec.primary_uom_code;
      X_WIP_ITEM_REQUIREMENTS_REC.WIP_SUPPLY_TYPE   := REC.WIP_SUPPLY_TYPE;
      --         X_WIP_ITEM_REQUIREMENTS_REC.SUBINVENTORY      := REC.SUBINVENTORY_CODE;
      --         X_WIP_ITEM_REQUIREMENTS_REC.ITEM_LOCATOR      := REC.CONCATENATED_SEGMENTS;
      --         X_WIP_ITEM_REQUIREMENTS_REC.LOT_NUMBER        := REC.LOT_NUMBER;
      --         x_wip_item_requirements_rec.lot_expiry_date   := rec.expiration_date;
      X_WIP_ITEM_REQUIREMENTS_REC.SERIAL_NUMBER := rec.serial_number_control_code;
      X_WIP_ITEM_REQUIREMENTS_REC.OPEN_QTY      := REC.REQUIRED_QUANTITY;
      --      X_WIP_ITEM_REQUIREMENTS_REC.PENDING_QTY       := REC.QUANTITY_ISSUED ;
      X_WIP_ITEM_REQUIREMENTS_REC.SOURCE_TYPE := NULL;
      IF REC.QUANTITY_ISSUED                  <>0 THEN
        FOR rec1                              IN C_SUB_INV(rec.wip_entity_id,rec.inventory_item_id,rec.serial_number_control_code)
        LOOP
          X_WIP_ITEM_REQUIREMENTS_REC.SUBINVENTORY    := REC1.SUBINVENTORY_CODE;
          X_WIP_ITEM_REQUIREMENTS_REC.ITEM_LOCATOR    := REC1.CONCATENATED_SEGMENTS;
          X_WIP_ITEM_REQUIREMENTS_REC.LOT_NUMBER      := REC1.LOT_NUMBER;
          X_WIP_ITEM_REQUIREMENTS_REC.LOT_EXPIRY_DATE := REC1.EXPIRATION_DATE;
          X_WIP_ITEM_REQUIREMENTS_REC.PENDING_QTY     := REC1.TRANSACTION_QUANTITY ;
          INSERT INTO XX_WIP_ITEM_REQUIREMENTS_TMP VALUES X_WIP_ITEM_REQUIREMENTS_REC;
        END LOOP;
      ELSE
        X_WIP_ITEM_REQUIREMENTS_REC.SUBINVENTORY    := NULL;
        X_WIP_ITEM_REQUIREMENTS_REC.ITEM_LOCATOR    := NULL;
        X_WIP_ITEM_REQUIREMENTS_REC.LOT_NUMBER      := NULL;
        X_WIP_ITEM_REQUIREMENTS_REC.LOT_EXPIRY_DATE := NULL;
        X_WIP_ITEM_REQUIREMENTS_REC.PENDING_QTY     := REC.QUANTITY_ISSUED;
        INSERT INTO XX_WIP_ITEM_REQUIREMENTS_TMP VALUES X_WIP_ITEM_REQUIREMENTS_REC;
      END IF;
      /*  END IF;
      -- When quantity is issued
      IF rec.quantity_issued != 0 AND rec.open_quantity != 0 THEN
      x_wip_item_requirements_rec.wip_entity_id     := rec.wip_entity_id;
      x_wip_item_requirements_rec.operation_seq_num := rec.operation_seq_num;
      x_wip_item_requirements_rec.inventory_item_id := rec.inventory_item_id;
      x_wip_item_requirements_rec.organization_id   := rec.organization_id;
      x_wip_item_requirements_rec.item_code         := rec.component;
      x_wip_item_requirements_rec.item_desc         := rec.description;
      x_wip_item_requirements_rec.uom               := rec.primary_uom_code;
      x_wip_item_requirements_rec.wip_supply_type   := rec.wip_supply_type;
      x_wip_item_requirements_rec.subinventory      := NULL;
      x_wip_item_requirements_rec.item_locator      := NULL;
      x_wip_item_requirements_rec.lot_number        := NULL;
      x_wip_item_requirements_rec.lot_expiry_date   := NULL;
      x_wip_item_requirements_rec.serial_number     := NULL;
      X_WIP_ITEM_REQUIREMENTS_REC.OPEN_QTY          := REC.QUANTITY_ISSUED;
      x_wip_item_requirements_rec.pending_qty       := NULL;
      x_wip_item_requirements_rec.source_type       := '2';
      INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      END IF;
      -- When there is a allocated quantity
      IF rec.quantity_allocated > 0 THEN
      x_wip_item_requirements_rec.wip_entity_id     := rec.wip_entity_id;
      x_wip_item_requirements_rec.operation_seq_num := rec.operation_seq_num;
      x_wip_item_requirements_rec.inventory_item_id := rec.inventory_item_id;
      x_wip_item_requirements_rec.organization_id   := rec.organization_id;
      x_wip_item_requirements_rec.item_code         := rec.component;
      x_wip_item_requirements_rec.item_desc         := rec.description;
      x_wip_item_requirements_rec.uom               := rec.primary_uom_code;
      x_wip_item_requirements_rec.wip_supply_type   := rec.wip_supply_type;
      -- Get the allocation details from transaction temp table
      IF rec.serial_number_control_code = 1 THEN--(not serial control)
      FOR items IN ( SELECT mttt.subinventory_code
      ,milk.concatenated_segments
      ,mtlt.lot_number
      ,mtlt.expiration_date
      ,mttt.primary_quantity
      FROM MTL_MATERIAL_TRANSACTIONS MTTT
      ,mtl_transaction_lot_val_v mtlt
      ,MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID = rec.wip_entity_id
      AND mttt.inventory_item_id = rec.inventory_item_id
      AND MTTT.TRANSACTION_ID = MTLT.TRANSACTION_ID
      AND mttt.locator_id = milk.inventory_location_id
      )
      LOOP
      x_wip_item_requirements_rec.subinventory      := items.subinventory_code;
      x_wip_item_requirements_rec.item_locator      := items.concatenated_segments;
      x_wip_item_requirements_rec.lot_number        := items.lot_number;
      x_wip_item_requirements_rec.lot_expiry_date   := items.expiration_date;
      x_wip_item_requirements_rec.serial_number     := NULL;
      x_wip_item_requirements_rec.open_qty          := rec.quantity_allocated;
      x_wip_item_requirements_rec.pending_qty       := items.primary_quantity;
      x_wip_item_requirements_rec.source_type       := '3';
      INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      END LOOP;
      ELSE --(serial control)
      FOR ser IN (        SELECT mttt.subinventory_code
      ,milk.concatenated_segments
      ,msnt.serial_number serial_number
      ,mttt.primary_quantity
      FROM MTL_MATERIAL_TRANSACTIONS MTTT
      ,mtl_unit_transactions msnt
      ,MTL_ITEM_LOCATIONS_KFV MILK
      WHERE MTTT.TRANSACTION_SOURCE_ID =rec.wip_entity_id
      AND mttt.inventory_item_id = rec.inventory_item_id
      AND MTTT.TRANSACTION_ID = MSNT.TRANSACTION_ID
      AND mttt.locator_id = milk.inventory_location_id
      )
      LOOP
      x_wip_item_requirements_rec.subinventory      := ser.subinventory_code;
      x_wip_item_requirements_rec.item_locator      := ser.concatenated_segments;
      x_wip_item_requirements_rec.lot_number        := NULL;
      x_wip_item_requirements_rec.lot_expiry_date   := NULL;
      x_wip_item_requirements_rec.serial_number     := ser.serial_number;
      x_wip_item_requirements_rec.open_qty          := rec.quantity_allocated;
      x_wip_item_requirements_rec.pending_qty       := ser.primary_quantity;
      x_wip_item_requirements_rec.source_type       := '4';
      INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      END LOOP;
      END IF;
      END IF;
      -- When there is a unallocated quantity display from onhand
      IF rec.unallocated_qty > 0 THEN
      x_wip_item_requirements_rec.wip_entity_id     := rec.wip_entity_id;
      x_wip_item_requirements_rec.operation_seq_num := rec.operation_seq_num;
      x_wip_item_requirements_rec.inventory_item_id := rec.inventory_item_id;
      x_wip_item_requirements_rec.organization_id   := rec.organization_id;
      x_wip_item_requirements_rec.item_code         := rec.component;
      x_wip_item_requirements_rec.item_desc         := rec.description;
      x_wip_item_requirements_rec.uom               := rec.primary_uom_code;
      x_wip_item_requirements_rec.wip_supply_type   := rec.wip_supply_type;
      x_wip_item_requirements_rec.subinventory      := NULL;
      x_wip_item_requirements_rec.item_locator      := NULL;
      x_wip_item_requirements_rec.lot_number        := NULL;
      x_wip_item_requirements_rec.lot_expiry_date   := NULL;
      x_wip_item_requirements_rec.serial_number     := NULL;
      x_wip_item_requirements_rec.open_qty          := rec.unallocated_qty;
      x_wip_item_requirements_rec.pending_qty       := NULL;
      x_wip_item_requirements_rec.source_type       := '5';
      INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      -- Get the onhand details
      /*    IF rec.serial_number_control_code = 1 THEN--(not serial control)
      FOR onhand IN (SELECT *
      FROM ( SELECT moqd.subinventory_code
      ,milk.concatenated_segments
      ,moqd.lot_number
      ,mln.expiration_date
      ,SUM(moqd.primary_transaction_quantity) primary_transaction_quantity
      FROM mtl_onhand_quantities_detail moqd
      ,mtl_item_locations_kfv milk
      ,mtl_lot_numbers mln
      WHERE moqd.inventory_item_id = rec.inventory_item_id
      AND moqd.organization_id = rec.organization_id
      AND moqd.locator_id = milk.inventory_location_id
      AND moqd.inventory_item_id = mln.inventory_item_id (+)
      AND moqd.organization_id = mln.organization_id (+)
      AND moqd.lot_number = mln.lot_number (+)
      GROUP BY moqd.subinventory_code
      ,milk.concatenated_segments
      ,moqd.lot_number
      ,mln.expiration_date
      HAVING SUM(moqd.primary_transaction_quantity) >= rec.unallocated_qty
      ) onhand
      ORDER BY primary_transaction_quantity
      )
      LOOP
      x_wip_item_requirements_rec.subinventory      := onhand.subinventory_code;
      x_wip_item_requirements_rec.item_locator      := onhand.concatenated_segments;
      x_wip_item_requirements_rec.lot_number        := onhand.lot_number;
      x_wip_item_requirements_rec.lot_expiry_date   := onhand.expiration_date;
      x_wip_item_requirements_rec.serial_number     := NULL;
      x_wip_item_requirements_rec.open_qty          := rec.unallocated_qty;
      x_wip_item_requirements_rec.pending_qty       := onhand.primary_transaction_quantity;
      x_wip_item_requirements_rec.source_type       := '4';
      INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      EXIT;
      END LOOP; */
      -- nowhere required qty found need to sum up
      /*  IF x_wip_item_requirements_rec.subinventory IS NULL THEN
      FOR onhand IN (SELECT *
      FROM ( SELECT moqd.subinventory_code
      ,milk.concatenated_segments
      ,moqd.lot_number
      ,mln.expiration_date
      ,SUM(moqd.primary_transaction_quantity) primary_transaction_quantity
      FROM mtl_onhand_quantities_detail moqd
      ,mtl_item_locations_kfv milk
      ,mtl_lot_numbers mln
      WHERE moqd.inventory_item_id = rec.inventory_item_id
      AND moqd.organization_id = rec.organization_id
      AND moqd.locator_id = milk.inventory_location_id
      AND moqd.inventory_item_id = mln.inventory_item_id (+)
      AND moqd.organization_id = mln.organization_id (+)
      AND moqd.lot_number = mln.lot_number (+)
      GROUP BY moqd.subinventory_code
      ,milk.concatenated_segments
      ,moqd.lot_number
      ,mln.expiration_date
      ) onhand
      ORDER BY primary_transaction_quantity desc
      )
      LOOP
      x_qty_temp := x_qty_temp + onhand.primary_transaction_quantity;
      x_wip_item_requirements_rec.subinventory      := onhand.subinventory_code;
      x_wip_item_requirements_rec.item_locator      := onhand.concatenated_segments;
      x_wip_item_requirements_rec.lot_number        := onhand.lot_number;
      x_wip_item_requirements_rec.lot_expiry_date   := onhand.expiration_date;
      x_wip_item_requirements_rec.serial_number     := NULL;
      x_wip_item_requirements_rec.open_qty          := rec.unallocated_qty;
      x_wip_item_requirements_rec.pending_qty       := onhand.primary_transaction_quantity;
      x_wip_item_requirements_rec.source_type       := '5';
      INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      EXIT WHEN x_qty_temp >= rec.unallocated_qty;
      END LOOP;
      END IF; */
      /*
      ELSE --(serial control)
      FOR on_ser IN (SELECT mosv.subinventory_code
      ,mosv.locator
      ,mosv.serial_number
      ,mosv.on_hand
      FROM mtl_onhand_serial_v mosv
      WHERE inventory_item_id = rec.inventory_item_id
      AND organization_id = rec.organization_id
      AND ROWNUM <= rec.unallocated_qty
      )
      LOOP
      x_wip_item_requirements_rec.subinventory      := on_ser.subinventory_code;
      x_wip_item_requirements_rec.item_locator      := on_ser.locator;
      x_wip_item_requirements_rec.lot_number        := NULL;
      x_wip_item_requirements_rec.lot_expiry_date   := NULL;
      x_wip_item_requirements_rec.serial_number     := on_ser.serial_number;
      x_wip_item_requirements_rec.open_qty          := rec.unallocated_qty;
      x_wip_item_requirements_rec.pending_qty       := on_ser.on_hand;
      x_wip_item_requirements_rec.source_type       := '6';
      INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      END LOOP;
      END IF;  */
      --      END IF;
      -- Reset
      x_wip_item_requirements_rec := NULL;
      x_qty_temp                  := 0;
    END LOOP;
    x_status := '0';
  EXCEPTION
  WHEN OTHERS THEN
    x_msg    := dbms_utility.format_error_backtrace || CHR(10)|| SQLERRM;
    x_status := '1';
  END LOAD_ITEM_REQUIREMENTS;
END XX_OSFM_WIP_ITEM_REQMTS_PKG;
/
