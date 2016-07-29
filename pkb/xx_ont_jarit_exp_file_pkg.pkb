DROP PACKAGE BODY APPS.XX_ONT_JARIT_EXP_FILE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ONT_JARIT_EXP_FILE_PKG" AS
  /* $Header: XXONTJARITEXPORTFILE.pkb 1.0.0 2013/09/12 00:00:00 ibm noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 12-Sep-2013
  -- Filename       : XXONTJARITEXPORTFILE.pkb
  -- Description    : Package body for getting amount for OSP Items

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 12-Sep-2013   1.0       Partha S Mohanty    Initial development.
--====================================================================================

FUNCTION convert_to_euro( p_usd_val NUMBER
                         ,p_curr_code VARCHAR2)
         RETURN number
IS
 x_conv_rate NUMBER :=0;
 x_line_amt NUMBER  :=0;
BEGIN
  IF p_curr_code = 'EUR' THEN
     x_line_amt := p_usd_val;
  ELSE

    BEGIN
   	  SELECT conversion_rate
   	    INTO x_conv_rate
       FROM gl_daily_rates gdr, gl_daily_conversion_types gdct
      WHERE gdr.from_currency = NVL(p_curr_code,'USD')
       AND gdr.to_currency = 'EUR'
       AND gdr.conversion_date = TRUNC (SYSDATE)
       AND gdr.conversion_type = gdct.conversion_type
       AND gdct.user_conversion_type = 'EUR Customs';

       x_line_amt := NVL(p_usd_val,0)*x_conv_rate;
   EXCEPTION
   	WHEN OTHERS THEN
   	    x_line_amt := 0;
        dbms_output.put_line('Unable to  derive EURO rate for '||p_usd_val);
   END;
  END IF;
  return(x_line_amt);
END convert_to_euro;


FUNCTION get_line_value(p_wip_entity_id wip_entities.wip_entity_id%TYPE
                        ,p_org_id NUMBER)
            RETURN number

IS
  Cursor jarit_cur(p_wip_id NUMBER,p_orgzn_id NUMBER) is
      SELECT mmt.OWNING_ORGANIZATION_ID,
       mmt.TRANSACTION_DATE,
       mmt.TRANSACTION_ID,
       mmt.TRANSACTION_QUANTITY,
       mmt.TRANSACTION_UOM,
       mmt.PRIMARY_QUANTITY,
       mmt.SOURCE_CODE,
       mmt.SOURCE_LINE_ID,
       mmt.PARENT_TRANSACTION_ID,
       mmt.RCV_TRANSACTION_ID,
       mmt.transaction_source_name,
       mmt.INVENTORY_ITEM_ID,
       mmt.ORGANIZATION_ID,
       mmt.TRANSFER_LOCATOR_ID,
       mmt.TRANSACTION_TYPE_ID,
       mmt.TRANSACTION_ACTION_ID,
       mmt.TRANSACTION_SOURCE_TYPE_ID,
       mmt.TRANSACTION_SOURCE_ID,
       mtlv.LOT_NUMBER
  FROM MTL_MATERIAL_TRANSACTIONS mmt,
       MTL_TRANSACTION_LOT_VAL_V mtlv
 WHERE mmt.TRANSACTION_ACTION_ID NOT IN (24, 30)
   and (mmt.ORGANIZATION_ID = p_orgzn_id)
   and (mmt.TRANSACTION_SOURCE_TYPE_ID = 5 AND mmt.TRANSACTION_SOURCE_ID = p_wip_id) -- 164254
   AND (mmt.parent_transaction_id IS NULL)
   AND mmt.TRANSACTION_ID = mtlv.TRANSACTION_ID
   AND mmt.ORGANIZATION_ID = mtlv.ORGANIZATION_ID
   AND mmt.TRANSACTION_TYPE_ID <> 44;

Cursor forge_cur(p_lot_number VARCHAR2,p_orgzn_id NUMBER) is
   SELECT ROWID,
       TRANSACTION_DATE,
       TRANSACTION_ID,
       TRANSACTION_QUANTITY,
       TRANSACTION_UOM,
       PRIMARY_QUANTITY,
       PARENT_TRANSACTION_ID,
       LOGICAL_TRANSACTION,
       RCV_TRANSACTION_ID,
       transaction_source_name,
       INVENTORY_ITEM_ID,
       ORGANIZATION_ID,
       ORIGINAL_TRANSACTION_TEMP_ID
  FROM MTL_MATERIAL_TRANSACTIONS
 WHERE TRANSACTION_ACTION_ID NOT IN (24, 30)
   and (ORGANIZATION_ID = 1654)
   and (rowid IN
       (SELECT /*+ cardinality(A,1) leading(a) first_rows */
          M.rowid
           FROM mtl_transaction_lot_numbers A, mtl_material_transactions M
          WHERE A.lot_number = p_lot_number
            AND A.organization_id = p_orgzn_id
            AND M.TRANSACTION_ID = A.TRANSACTION_ID))
   and (LOGICAL_TRANSACTION = 2 OR LOGICAL_TRANSACTION IS NULL)
   and transaction_type_id = 41      -- Account alias receipt
   --and transaction_action_id = 27
   and transaction_source_type_id = 6; -- Account alias

Cursor po_cur(p_lot_number VARCHAR2,p_orgzn_id NUMBER) is
  SELECT ROWID,
       TRANSACTION_DATE,
       TRANSACTION_ID,
       TRANSACTION_QUANTITY,
       TRANSACTION_UOM,
       PRIMARY_QUANTITY,
       SOURCE_CODE,
       SOURCE_LINE_ID,
       TRANSFER_TRANSACTION_ID,
       PARENT_TRANSACTION_ID,
       LOGICAL_TRANSACTION,
       TRANSACTION_SET_ID,
       RCV_TRANSACTION_ID,
       transaction_source_name,
       TRANSACTION_TYPE_ID,
       TRANSACTION_ACTION_ID,
       TRANSACTION_SOURCE_TYPE_ID,
       TRANSACTION_SOURCE_ID
  FROM MTL_MATERIAL_TRANSACTIONS
 WHERE TRANSACTION_ACTION_ID NOT IN (24, 30)
   and (ORGANIZATION_ID = p_orgzn_id)
   and (rowid IN
       (SELECT /*+ cardinality(A,1) leading(a) first_rows */
          M.rowid
           FROM mtl_transaction_lot_numbers A, mtl_material_transactions M
          WHERE A.lot_number = p_lot_number
            AND A.organization_id = p_orgzn_id
            AND M.TRANSACTION_ID = A.TRANSACTION_ID))
   and (LOGICAL_TRANSACTION = 2 OR LOGICAL_TRANSACTION IS NULL)
   and transaction_type_id = 18        -- PO Receipt
   and transaction_source_type_id = 1; -- Purchase order
 --  and transaction_action_id = 27

  -- Variables
   x_forge_cost_euro NUMBER:=0;
   x_forge_euro_cost NUMBER:=0;
   x_forge_cost      NUMBER:=0;

   x_po_cost_euro   NUMBER:=0;
   x_po_euro_cost   NUMBER:=0;
   x_po_cost        NUMBER:=0;

   x_total_cust     NUMBER:=0;
   x_cur_code_po    VARCHAR2(50):= NULL;
   x_cur_code_forge VARCHAR2(50):= NULL;
BEGIN
   x_forge_cost_euro :=0;
   x_forge_euro_cost :=0;
   x_forge_cost      :=0;

   x_po_cost_euro    :=0;
   x_po_euro_cost    :=0;
   x_po_cost         :=0;

   x_total_cust      :=0;
   x_cur_code_po     := NULL;
   x_cur_code_forge  := NULL;

   FOR jarit_rec IN jarit_cur(p_wip_entity_id,p_org_id)
    LOOP
     -- forging cost
     FOR forge_rec IN forge_cur(jarit_rec.lot_number,p_org_id)
       LOOP
        BEGIN
         SELECT currency_code,PRIMARY_QUANTITY * UNIT_COST
                INTO x_cur_code_forge,x_forge_cost
          FROM CST_INV_DISTRIBUTION_V
         WHERE organization_id = p_org_id
           and transaction_id = forge_rec.transaction_id --'4228837'
           and (transaction_id = forge_rec.transaction_id OR parent_transaction_id = forge_rec.transaction_id)
           and line_type_name = 'Inv valuation'
           and transaction_source_type_name = 'Account alias';
         EXCEPTION
           WHEN OTHERS THEN
              x_forge_cost := 0;
              dbms_output.put_line('Inside  Forge value exception'||x_po_cost);
         END;
         x_forge_euro_cost := convert_to_euro(x_forge_cost,x_cur_code_forge);
         x_forge_cost_euro := x_forge_cost_euro +  x_forge_euro_cost;
         dbms_output.put_line('Incremental forge value in USD:'||x_forge_cost||' Value in EURO : '||x_forge_euro_cost);

       END LOOP;

      -- Po cost

     FOR po_rec IN po_cur(jarit_rec.lot_number,p_org_id)
       LOOP

        BEGIN
         SELECT distinct
             api.invoice_currency_code, api.invoice_amount
             INTO x_cur_code_po,x_po_cost
          FROM mtl_material_transactions mmt,
             mtl_transaction_lot_numbers mtl,
             mtl_transaction_types mtt,
             mtl_txn_source_types mtst,
             rcv_transactions rt,
             rcv_shipment_headers rsh,
             rcv_shipment_lines rsl,
             ap_invoices_all api,
             ap_suppliers aps,
             po_headers_all poh,
             ap_invoice_lines_all apli,
             mtl_system_items_b msib
           WHERE 1 = 1
             AND mtl.transaction_id = mmt.transaction_id
             AND mmt.transaction_type_id = mtt.transaction_type_id
             AND mtt.transaction_type_name = 'PO Receipt'
             AND mmt.transaction_source_type_id = mtst.transaction_source_type_id
             AND mtst.transaction_source_type_name = 'Purchase order'
             AND mmt.rcv_transaction_id = rt.transaction_id
             AND rt.shipment_header_id = rsh.shipment_header_id
             AND rsh.packing_slip = api.invoice_num
             AND api.vendor_id = aps.vendor_id
             AND rt.po_header_id = poh.po_header_id
             AND rt.shipment_line_id = rsl.shipment_line_id
             AND rsh.shipment_header_id = rsl.shipment_header_id
             AND apli.invoice_id = api.invoice_id
             AND apli.inventory_item_id = msib.inventory_item_id
             AND msib.organization_id = mmt.organization_id
             AND rt.po_header_id = po_rec.transaction_source_id --172343
             AND mtl.lot_number = jarit_rec.lot_number; --'LOT123';
        EXCEPTION
          WHEN OTHERS THEN
            x_po_cost := 0;
            dbms_output.put_line('Inside  Invoice value exception'||x_po_cost);
        END;
          x_po_euro_cost := convert_to_euro(x_po_cost,x_cur_code_po);
          x_po_cost_euro := x_po_cost_euro +  x_po_euro_cost;
          dbms_output.put_line('Incremental Invoice value in USD:'||x_po_cost||' Value in EURO : '||x_po_euro_cost);
       END LOOP;

   END LOOP; -- Main Jarit loop
   x_total_cust := x_po_cost_euro + x_forge_cost_euro ;
   dbms_output.put_line('Final Invoice value'||x_po_cost_euro);
   dbms_output.put_line('Final forge value'  ||x_forge_cost_euro);
   dbms_output.put_line('Final total value'  ||x_total_cust);
   RETURN(x_total_cust);
END;

-- get related invoice


FUNCTION get_related_invoice(p_wip_entity_id wip_entities.wip_entity_id%TYPE
                            ,p_org_id NUMBER) RETURN VARCHAR2

IS
  Cursor jarit_cur(p_wip_id NUMBER,p_orgzn_id NUMBER) is
      SELECT mmt.OWNING_ORGANIZATION_ID,
       mmt.TRANSACTION_DATE,
       mmt.TRANSACTION_ID,
       mmt.TRANSACTION_QUANTITY,
       mmt.TRANSACTION_UOM,
       mmt.PRIMARY_QUANTITY,
       mmt.SOURCE_CODE,
       mmt.SOURCE_LINE_ID,
       mmt.PARENT_TRANSACTION_ID,
       mmt.RCV_TRANSACTION_ID,
       mmt.transaction_source_name,
       mmt.INVENTORY_ITEM_ID,
       mmt.ORGANIZATION_ID,
       mmt.TRANSFER_LOCATOR_ID,
       mmt.TRANSACTION_TYPE_ID,
       mmt.TRANSACTION_ACTION_ID,
       mmt.TRANSACTION_SOURCE_TYPE_ID,
       mmt.TRANSACTION_SOURCE_ID,
       mtlv.LOT_NUMBER
  FROM MTL_MATERIAL_TRANSACTIONS mmt,
       MTL_TRANSACTION_LOT_VAL_V mtlv
 WHERE mmt.TRANSACTION_ACTION_ID NOT IN (24, 30)
   and (mmt.ORGANIZATION_ID = p_orgzn_id)
   and (mmt.TRANSACTION_SOURCE_TYPE_ID = 5 AND mmt.TRANSACTION_SOURCE_ID = p_wip_id) -- 164254
   AND (mmt.parent_transaction_id IS NULL)
   AND mmt.TRANSACTION_ID = mtlv.TRANSACTION_ID
   AND mmt.ORGANIZATION_ID = mtlv.ORGANIZATION_ID
   AND mmt.TRANSACTION_TYPE_ID <> 44;

Cursor forge_cur(p_lot_number VARCHAR2,p_orgzn_id NUMBER) is
   SELECT ROWID,
       TRANSACTION_DATE,
       TRANSACTION_ID,
       TRANSACTION_QUANTITY,
       TRANSACTION_UOM,
       PRIMARY_QUANTITY,
       PARENT_TRANSACTION_ID,
       LOGICAL_TRANSACTION,
       RCV_TRANSACTION_ID,
       transaction_source_name,
       INVENTORY_ITEM_ID,
       ORGANIZATION_ID,
       ORIGINAL_TRANSACTION_TEMP_ID
  FROM MTL_MATERIAL_TRANSACTIONS
 WHERE TRANSACTION_ACTION_ID NOT IN (24, 30)
   and (ORGANIZATION_ID = 1654)
   and (rowid IN
       (SELECT /*+ cardinality(A,1) leading(a) first_rows */
          M.rowid
           FROM mtl_transaction_lot_numbers A, mtl_material_transactions M
          WHERE A.lot_number = p_lot_number
            AND A.organization_id = p_orgzn_id
            AND M.TRANSACTION_ID = A.TRANSACTION_ID))
   and (LOGICAL_TRANSACTION = 2 OR LOGICAL_TRANSACTION IS NULL)
   and transaction_type_id = 41      -- Account alias receipt
   --and transaction_action_id = 27
   and transaction_source_type_id = 6; -- Account alias

Cursor po_cur(p_lot_number VARCHAR2,p_orgzn_id NUMBER) is
  SELECT ROWID,
       TRANSACTION_DATE,
       TRANSACTION_ID,
       TRANSACTION_QUANTITY,
       TRANSACTION_UOM,
       PRIMARY_QUANTITY,
       SOURCE_CODE,
       SOURCE_LINE_ID,
       TRANSFER_TRANSACTION_ID,
       PARENT_TRANSACTION_ID,
       LOGICAL_TRANSACTION,
       TRANSACTION_SET_ID,
       RCV_TRANSACTION_ID,
       transaction_source_name,
       TRANSACTION_TYPE_ID,
       TRANSACTION_ACTION_ID,
       TRANSACTION_SOURCE_TYPE_ID,
       TRANSACTION_SOURCE_ID
  FROM MTL_MATERIAL_TRANSACTIONS
 WHERE TRANSACTION_ACTION_ID NOT IN (24, 30)
   and (ORGANIZATION_ID = 1654)
   and (rowid IN
       (SELECT /*+ cardinality(A,1) leading(a) first_rows */
          M.rowid
           FROM mtl_transaction_lot_numbers A, mtl_material_transactions M
          WHERE A.lot_number = p_lot_number
            AND A.organization_id = p_orgzn_id
            AND M.TRANSACTION_ID = A.TRANSACTION_ID))
   and (LOGICAL_TRANSACTION = 2 OR LOGICAL_TRANSACTION IS NULL)
   and transaction_type_id = 18        -- PO Receipt
   and transaction_source_type_id = 1; -- Purchase order
 --  and transaction_action_id = 27

  -- Variables
   x_forge_ref      VARCHAR2(100) := NULL;
   x_forge_rel_inv  VARCHAR2(500) := NULL;
   x_inv_number     VARCHAR2(100) := NULL;
   x_po_rel_inv     VARCHAR2(500) := NULL;
   x_total_rel_inv  VARCHAR2(1000):= NULL;
   x_total_rel_inv1 VARCHAR2(1000):= NULL;
BEGIN
   x_forge_ref         :=NULL;
   x_forge_rel_inv     :=NULL;
   x_inv_number        :=NULL;
   x_po_rel_inv        :=NULL;
   x_total_rel_inv     :=NULL;

   FOR jarit_rec IN jarit_cur(p_wip_entity_id,p_org_id)
    LOOP
     -- forging cost
     FOR forge_rec IN forge_cur(jarit_rec.lot_number,p_org_id)
       LOOP
        BEGIN
         SELECT transaction_reference
                INTO x_forge_ref
          FROM CST_INV_DISTRIBUTION_V
         WHERE organization_id = p_org_id
           and transaction_id = forge_rec.transaction_id --'4228837'
           and (transaction_id = forge_rec.transaction_id OR parent_transaction_id = forge_rec.transaction_id)
           and line_type_name = 'Inv valuation'
           and transaction_source_type_name = 'Account alias';
         EXCEPTION
           WHEN OTHERS THEN
              x_forge_rel_inv :=NULL;
              dbms_output.put_line('Inside  Forge related invoice exception'||x_forge_ref);
         END;
         x_forge_rel_inv := x_forge_rel_inv ||','||  x_forge_ref||',';
         dbms_output.put_line('Incremental forge related invoice'||x_forge_ref);

       END LOOP;

      -- Po cost

     FOR po_rec IN po_cur(jarit_rec.lot_number,p_org_id)
       LOOP

        BEGIN
         SELECT distinct
             rsh.packing_slip invoice_number
             INTO x_inv_number
          FROM mtl_material_transactions mmt,
             mtl_transaction_lot_numbers mtl,
             mtl_transaction_types mtt,
             mtl_txn_source_types mtst,
             rcv_transactions rt,
             rcv_shipment_headers rsh,
             rcv_shipment_lines rsl,
             ap_invoices_all api,
             ap_suppliers aps,
             po_headers_all poh,
             ap_invoice_lines_all apli,
             mtl_system_items_b msib
           WHERE 1 = 1
             AND mtl.transaction_id = mmt.transaction_id
             AND mmt.transaction_type_id = mtt.transaction_type_id
             AND mtt.transaction_type_name = 'PO Receipt'
             AND mmt.transaction_source_type_id = mtst.transaction_source_type_id
             AND mtst.transaction_source_type_name = 'Purchase order'
             AND mmt.rcv_transaction_id = rt.transaction_id
             AND rt.shipment_header_id = rsh.shipment_header_id
             AND rsh.packing_slip = api.invoice_num
             AND api.vendor_id = aps.vendor_id
             AND rt.po_header_id = poh.po_header_id
             AND rt.shipment_line_id = rsl.shipment_line_id
             AND rsh.shipment_header_id = rsl.shipment_header_id
             AND apli.invoice_id = api.invoice_id
             AND apli.inventory_item_id = msib.inventory_item_id
             AND msib.organization_id = mmt.organization_id
             AND rt.po_header_id = po_rec.transaction_source_id --172343
             AND mtl.lot_number = jarit_rec.lot_number; --'LOT123';
        EXCEPTION
          WHEN OTHERS THEN
            x_inv_number := NULL;
            dbms_output.put_line('Inside  Po related Invoice  exception'||x_inv_number);
        END;
          x_po_rel_inv := x_po_rel_inv ||','|| x_inv_number||',';
          dbms_output.put_line('Incremental Po related Invoice '||x_inv_number);
       END LOOP;

   END LOOP; -- Main Jarit loop
   x_total_rel_inv := x_po_rel_inv || x_forge_rel_inv ;
   x_total_rel_inv1 := replace(replace(trim(replace(x_total_rel_inv,',',' ')),' ',','),',,',',');
   dbms_output.put_line('Final Po related Invoice'||x_po_rel_inv);
   dbms_output.put_line('Final forge value'  ||x_forge_rel_inv);
   dbms_output.put_line('Final total value'  ||x_total_rel_inv);
   RETURN(x_total_rel_inv1);
END;




END xx_ont_jarit_exp_file_pkg;
/
