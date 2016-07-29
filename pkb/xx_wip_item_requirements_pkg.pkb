DROP PACKAGE BODY APPS.XX_WIP_ITEM_REQUIREMENTS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_WIP_ITEM_REQUIREMENTS_PKG" 
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
-------------------------------------------------------------------------------------------------------------
*/

PROCEDURE load_item_requirements ( p_wip_entity_id IN NUMBER
                                  ,x_status        OUT VARCHAR2
				  ,x_msg           OUT VARCHAR2
			         )

IS
CURSOR c_get_items
   IS
   SELECT wro.wip_entity_id
         ,wro.operation_seq_num
         ,wro.inventory_item_id
         ,wro.organization_id
         ,wro.segment1 component
         ,wro.required_quantity
         ,wro.quantity_issued
         ,NVL(wro.quantity_allocated,0) quantity_allocated
         ,(wro.required_quantity - wro.quantity_issued) open_quantity
         ,((wro.required_quantity - wro.quantity_issued) - NVL(wro.quantity_allocated,0)) unallocated_qty
         ,msib.description
         ,msib.primary_uom_code
         ,msib.serial_number_control_code
         ,msib.lot_control_code
         ,mfgl.meaning wip_supply_type
     FROM wip_requirement_operations wro
         ,mtl_system_items_b msib
         ,mfg_lookups mfgl
    WHERE wro.wip_entity_id = p_wip_entity_id
      AND wro.inventory_item_id = msib.inventory_item_id
      AND wro.organization_id = msib.organization_id
      AND mfgl.lookup_type = 'WIP_SUPPLY_SHORT'
      AND mfgl.lookup_code = wro.wip_supply_type
      ORDER BY wro.segment1;

   x_wip_item_requirements_rec xx_wip_item_requirements_tmp%ROWTYPE;
   x_qty_temp                  NUMBER := 0;

BEGIN
   -- Get items for the job
   FOR rec IN c_get_items
   LOOP
      -- When required open quantity is 0
      IF rec.open_quantity = 0 THEN
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
         x_wip_item_requirements_rec.open_qty          := NULL;
         x_wip_item_requirements_rec.pending_qty       := NULL;
	 x_wip_item_requirements_rec.source_type       := '1';

         INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
      END IF;

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
         x_wip_item_requirements_rec.open_qty          := rec.quantity_issued;
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
                                 ,mtlt.lot_expiration_date
                                 ,mttt.primary_quantity
                            FROM mtl_material_transactions_temp mttt
                                ,mtl_transaction_lots_temp mtlt
                                ,mtl_item_locations_kfv milk
                           WHERE mttt.transaction_source_id = rec.wip_entity_id
                             AND mttt.inventory_item_id = rec.inventory_item_id
                             AND mttt.transaction_temp_id = mtlt.transaction_temp_id (+)
                             AND mttt.locator_id = milk.inventory_location_id
                          )
             LOOP
                x_wip_item_requirements_rec.subinventory      := items.subinventory_code;
                x_wip_item_requirements_rec.item_locator      := items.concatenated_segments;
                x_wip_item_requirements_rec.lot_number        := items.lot_number;
                x_wip_item_requirements_rec.lot_expiry_date   := items.lot_expiration_date;
                x_wip_item_requirements_rec.serial_number     := NULL;
                x_wip_item_requirements_rec.open_qty          := rec.quantity_allocated;
                x_wip_item_requirements_rec.pending_qty       := items.primary_quantity;
		 x_wip_item_requirements_rec.source_type       := '3';
                INSERT INTO xx_wip_item_requirements_tmp VALUES x_wip_item_requirements_rec;
             END LOOP;

         ELSE --(serial control)
            FOR ser IN ( SELECT mttt.subinventory_code
                               ,milk.concatenated_segments
                               ,msnt.fm_serial_number||
                                DECODE(msnt.to_serial_number,NULL,NULL,' - '||msnt.to_serial_number) serial_number
                               ,mttt.primary_quantity
                           FROM mtl_material_transactions_temp mttt
                               ,mtl_serial_numbers_temp msnt
                               ,mtl_item_locations_kfv milk
                          WHERE mttt.transaction_source_id = rec.wip_entity_id
                            AND mttt.inventory_item_id = rec.inventory_item_id
                            AND mttt.transaction_temp_id = msnt.transaction_temp_id
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
      END IF;

      -- Reset
      x_wip_item_requirements_rec := NULL;
      x_qty_temp := 0;
   END LOOP;

   x_status := '0';

EXCEPTION
   WHEN OTHERS THEN
      x_msg := dbms_utility.format_error_backtrace || CHR(10)|| SQLERRM;
      x_status := '1';
END load_item_requirements;

END xx_wip_item_requirements_pkg;
/
