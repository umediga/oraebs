DROP PACKAGE BODY APPS.XX_ONT_INTERCO_INV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XX_ONT_INTERCO_INV_PKG
AS
  /******************************************************************************
  -- Filename:  XXONTINTERCOINV.pkb
  -- RICEW Object id : R2R-EXT_019
  -- Purpose :  Package Body for Intercompany Invoicing
  --
  -- Usage: Concurrent Program ( Type PL/SQL Procedure)
  -- Caution:
  -- Copyright (c) IBM
  -- All rights reserved.
  -- Ver  Date         Author             Modification
  -- ---- -----------  ------------------ --------------------------------------
  -- 1.0  28-May-2012  ABhargava          Created
  -- 1.1  15-Nov-2012  ABhargava          Changes in the Grouping Logic
  -- 1.2  19-Nov-2012  ABhargava          Changes to the Rounding Figure and Partial Processing
  -- 1.3  01-Oct-2012  ABhargava          For Material Transactions Item Cost needs to be picked from
  MTL_MATERIAL_TRANSACTIONS
  -- 1.4  27-Feb-2013  ABhargava          Added ISNUMBER function to accomodate the error in cursor for
  TRANSACTION_REFERENCE
  -- 1.5  04-Sep-2013  ABhargava          Issue - 00953 to prevent the lines from Sales Order
  -- 1.6  14-May-2013  Sajan/Jaya Maran   Issue - 006547 removed time wait
  -- 1.7  14-FEB-2016  Renganayaki S      Case#8447 - Change for Payables Invoice GL Date
  ******************************************************************************/
  PROCEDURE print_debug(
      p_msg IN VARCHAR2)
  IS
  BEGIN
    fnd_file.put_line(fnd_file.log, p_msg);
  END;
  FUNCTION isnumber(
      val IN VARCHAR2)
    RETURN NUMBER
  IS
    l_val NUMBER;
  BEGIN
    l_val := to_number(val);
    RETURN 1;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
  END;
  FUNCTION get_basic_price(
      p_transaction_id IN NUMBER ,
      p_price_list_id IN NUMBER ,
      p_inventory_item_id IN NUMBER ,
      p_transaction_uom IN VARCHAR2 ,
      p_trf_price_date IN DATE ,
      x_invoice_currency_code OUT VARCHAR2 ,
      l_return_status OUT VARCHAR2)
    RETURN NUMBER
  IS
    l_transfer_price   NUMBER;
    l_primary_uom      VARCHAR2(10);
    l_organization_id  NUMBER;
    l_item_description VARCHAR2(4000);
    l_price_list_name  VARCHAR2(400);
  BEGIN
    l_transfer_price := NULL;
    l_return_status := 'S';
    BEGIN
      SELECT organization_id
      INTO l_organization_id
      FROM mtl_material_transactions
      WHERE transaction_id = p_transaction_id ;
      SELECT spll.operand,
        SUBSTR(spl.currency_code, 1, 15)
      INTO l_transfer_price,
        x_invoice_currency_code
      FROM qp_list_headers_b spl,
        qp_list_lines spll,
        qp_pricing_attributes qpa
      WHERE spl.list_header_id = p_price_list_id
      AND spll.list_header_id = spl.list_header_id
      AND spll.list_line_id = qpa.list_line_id
      AND qpa.product_attribute_context = 'ITEM'
      AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
      AND qpa.product_attr_value = TO_CHAR(p_inventory_item_id)
      AND qpa.product_uom_code = p_transaction_uom
        /*and p_trf_price_date between nvl(spll.start_date_active, (p_trf_price_date - 1))
        and nvl(spll.end_date_active + 0.99999, (p_trf_price_date + 1))*/
      AND qpa.pricing_attribute_context IS NULL
      AND qpa.excluder_flag = 'N'
      AND qpa.pricing_phase_id = 1
      AND rownum = 1;
      print_debug('l_transfer_price = ' || l_transfer_price || ' in get_transfer_price_for_item');
      print_debug('l_invoice_currency_code = ' || x_invoice_currency_code || ' in get_transfer_price_for_item');
      l_return_status := 'S';
    EXCEPTION
    WHEN no_data_found THEN
      print_debug('Get static price list in primary uom  in get_transfer_price_for_item');
      BEGIN
        SELECT spll.operand,
          SUBSTR(spl.currency_code, 1, 15),
          msi.primary_uom_code
        INTO l_transfer_price,
          x_invoice_currency_code,
          l_primary_uom
        FROM qp_list_headers_b spl,
          qp_list_lines spll,
          qp_pricing_attributes qpa,
          mtl_system_items_b msi
        WHERE msi.organization_id = l_organization_id
        AND msi.inventory_item_id = p_inventory_item_id
        AND spl.list_header_id = p_price_list_id
        AND spll.list_header_id = spl.list_header_id
        AND qpa.list_header_id = spl.list_header_id
        AND spll.list_line_id = qpa.list_line_id
        AND qpa.product_attribute_context = 'ITEM'
        AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
        AND qpa.product_attr_value = TO_CHAR(msi.inventory_item_id)
        AND qpa.product_uom_code = msi.primary_uom_code
          /*and p_trf_price_date between nvl(spll.start_date_active, (p_trf_price_date - 1))
          and nvl(spll.end_date_active + 0.99999, (p_trf_price_date + 1))*/
        AND qpa.pricing_attribute_context IS NULL
        AND qpa.excluder_flag = 'N'
        AND qpa.pricing_phase_id = 1
        AND rownum = 1;
        l_return_status := 'S';
      EXCEPTION
      WHEN no_data_found THEN
        print_debug('no price list found in get_transfer_price_for_item');
        l_transfer_price := NULL;
        l_return_status := 'E';
        SELECT concatenated_segments,
          primary_uom_code
        INTO l_item_description,
          l_primary_uom
        FROM mtl_system_items_kfv
        WHERE organization_id = l_organization_id
        AND inventory_item_id = p_inventory_item_id;
        SELECT name
        INTO l_price_list_name
        FROM qp_list_headers
        WHERE list_header_id = p_price_list_id;
        print_debug( 'Price not found for item : ' || l_item_description || ' for UOM Code: ' || l_primary_uom || ' in Price list: ' ||
        l_price_list_name);
      END;
    WHEN OTHERS THEN
      print_debug('sqlerrm = ' || sqlerrm || ' in get_transfer_price_for_item');
      l_transfer_price := NULL;
      l_return_status := 'E';
    END;
    l_return_status := 'S';
    RETURN l_transfer_price;
  END;
/*================================================================================
Procedure to update the Manual Correction Column for a Particular Batch or Order
==================================================================================*/
  PROCEDURE manual_correction(
      x_errbuf OUT VARCHAR2,
      x_retcode OUT VARCHAR2,
      l_batch_id IN NUMBER,
      l_header_id IN NUMBER)
  IS
  BEGIN
    IF l_header_id IS NULL THEN
      UPDATE xx_ont_interco_staging
      SET ar_made = DECODE(ar_made, g_status_error, g_status_success, ar_made, NULL, NULL, ar_made) ,
        ap_made = DECODE( ap_made, g_status_error, g_status_success, ap_made, NULL, NULL, ap_made) ,
        manual_corr = g_status_success ,
        last_update_date = sysdate ,
        last_updated_by = fnd_global.user_id
      WHERE batch_id = l_batch_id
      AND (ar_made = g_status_error
      OR ap_made = g_status_error);
      fnd_file.put_line(fnd_file.log, 'Update Row Count :' || sql%rowcount);
    ELSE
      UPDATE xx_ont_interco_staging
      SET ar_made = DECODE(ar_made, g_status_error, g_status_success, ar_made, NULL, NULL, ar_made) ,
        ap_made = DECODE( ap_made, g_status_error, g_status_success, ap_made, NULL, NULL, ap_made) ,
        manual_corr = g_status_success ,
        last_update_date = sysdate ,
        last_updated_by = fnd_global.user_id
      WHERE batch_id = l_batch_id
      AND (ar_made = g_status_error
      OR ap_made = g_status_error)
      AND source_ref_id IN
        (SELECT line_id FROM oe_order_lines_all WHERE header_id = l_header_id
        );
      fnd_file.put_line(fnd_file.log, 'Update Row Count :' || sql%rowcount);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Unhandled Exception in MANUAL CORRECTION: ' || sqlerrm);
  END manual_correction;
/*================================================================================
Procedure  to Get the List Price as per the Price List attached to Shipping Network
==================================================================================*/
  PROCEDURE interco_get_list_price(
      p_price_list_id IN NUMBER ,
      p_organization IN NUMBER ,
      p_item_id IN NUMBER ,
      p_item_qty IN NUMBER ,
      p_item_uom IN VARCHAR2 ,
      p_currency IN VARCHAR2 ,
      p_cust_acct_id IN NUMBER ,
      o_list_price OUT NUMBER ,
      o_status OUT VARCHAR2 ,
      o_msg OUT VARCHAR2)
  IS
    -- Variables
    x_in_line_tbl qp_preq_grp.line_tbl_type;
    x_in_qual_tbl qp_preq_grp.qual_tbl_type;
    x_in_line_attr_tbl qp_preq_grp.line_attr_tbl_type;
    x_in_line_detail_tbl qp_preq_grp.line_detail_tbl_type;
    x_in_line_detail_qual_tbl qp_preq_grp.line_detail_qual_tbl_type;
    x_in_line_detail_attr_tbl qp_preq_grp.line_detail_attr_tbl_type;
    x_in_related_lines_tbl qp_preq_grp.related_lines_tbl_type;
    x_in_control_rec qp_preq_grp.control_record_type;
    x_out_line_tbl qp_preq_grp.line_tbl_type;
    x_out_qual_tbl qp_preq_grp.qual_tbl_type;
    x_out_line_attr_tbl qp_preq_grp.line_attr_tbl_type;
    x_out_line_detail_tbl qp_preq_grp.line_detail_tbl_type;
    x_out_line_detail_qual_tbl qp_preq_grp.line_detail_qual_tbl_type;
    x_out_line_detail_attr_tbl qp_preq_grp.line_detail_attr_tbl_type;
    x_out_related_lines_tbl qp_preq_grp.related_lines_tbl_type;
    x_pricing_contexts_tbl qp_attr_mapping_pub.contexts_result_tbl_type;
    x_qualifier_contexts_tbl qp_attr_mapping_pub.contexts_result_tbl_type;
    x_return_status      VARCHAR2(240);
    x_return_status_text VARCHAR2(240);
  BEGIN
    o_status := fnd_api.g_ret_sts_success;
    o_msg := NULL;
    -- Build pricing contexts
    qp_attr_mapping_pub. build_contexts(p_request_type_code => 'IC' , p_pricing_type => 'L' , x_price_contexts_result_tbl => x_pricing_contexts_tbl ,
    x_qual_contexts_result_tbl => x_qualifier_contexts_tbl);
    -- Create the control record
    x_in_control_rec.pricing_event := 'LINE';
    x_in_control_rec.calculate_flag := 'Y';
    x_in_control_rec.simulation_flag := 'N';
    x_in_control_rec.rounding_flag := 'Q';
    x_in_control_rec.manual_discount_flag := 'Y';
    x_in_control_rec.request_type_code := 'IC';
    x_in_control_rec.temp_table_insert_flag := 'Y';
    -- Create line record
    x_in_line_tbl(1).request_type_code := 'IC';
    x_in_line_tbl(1).line_index := '1';
    x_in_line_tbl(1).line_type_code := 'LINE';
    x_in_line_tbl(1).pricing_effective_date := sysdate;
    x_in_line_tbl(1).active_date_first := sysdate;
    x_in_line_tbl(1).active_date_second := sysdate;
    x_in_line_tbl(1).active_date_first_type := 'NO TYPE';
    x_in_line_tbl(1).active_date_second_type := 'NO TYPE';
    x_in_line_tbl(1).line_quantity := p_item_qty;
    x_in_line_tbl(1).line_uom_code := p_item_uom;
    x_in_line_tbl(1).currency_code := p_currency;
    x_in_line_tbl(1).price_flag := 'Y';
    -- Create line attribute records
    x_in_line_attr_tbl(1).line_index := 1;
    x_in_line_attr_tbl(1).pricing_context := 'ITEM';
    x_in_line_attr_tbl(1).pricing_attribute := 'PRICING_ATTRIBUTE3';
    x_in_line_attr_tbl(1).pricing_attr_value_from := 'ALL';
    x_in_line_attr_tbl(1).validated_flag := 'N';
    x_in_line_attr_tbl(2).line_index := 1;
    x_in_line_attr_tbl(2).pricing_context := 'ITEM';
    x_in_line_attr_tbl(2).pricing_attribute := 'PRICING_ATTRIBUTE1';
    x_in_line_attr_tbl(2).pricing_attr_value_from := TO_CHAR(p_item_id);
    x_in_line_attr_tbl(2).validated_flag := 'N';
    x_in_line_attr_tbl(3).line_index := 1;
    x_in_line_attr_tbl(3).pricing_context := 'INTG_COST'; --'PRICING ATTRIBUTE';
    x_in_line_attr_tbl(3).pricing_attribute := 'PRICING_ATTRIBUTE1';
    x_in_line_attr_tbl(3).pricing_attr_value_from := cst_cost_api. get_item_cost(p_api_version => 1.0 , p_inventory_item_id => p_item_id ,
    p_organization_id => p_organization);
    x_in_line_attr_tbl(3).validated_flag := 'Y';
    -- Create qualifier attribute records
    x_in_qual_tbl(1).line_index := 1;
    x_in_qual_tbl(1).qualifier_context := 'MODLIST';
    x_in_qual_tbl(1).qualifier_attribute := 'QUALIFIER_ATTRIBUTE4';
    x_in_qual_tbl(1).qualifier_attr_value_from := TO_CHAR(p_price_list_id);
    x_in_qual_tbl(1).comparison_operator_code := '=';
    x_in_qual_tbl(1).validated_flag := 'Y';
    x_in_qual_tbl(2).line_index := 1;
    x_in_qual_tbl(2).qualifier_context := 'INTERCOMPANY_INVOICING';
    x_in_qual_tbl(2).qualifier_attribute := 'QUALIFIER_ATTRIBUTE3';
    x_in_qual_tbl(2).qualifier_attr_value_from := TO_CHAR(p_cust_acct_id);
    x_in_qual_tbl(2).comparison_operator_code := '=';
    x_in_qual_tbl(2).validated_flag := 'Y';
    -- Invoke the pricing request API to get the list price
    qp_preq_pub.price_request(p_line_tbl => x_in_line_tbl , p_qual_tbl => x_in_qual_tbl , p_line_attr_tbl => x_in_line_attr_tbl , p_line_detail_tbl
    => x_in_line_detail_tbl , p_line_detail_qual_tbl => x_in_line_detail_qual_tbl , p_line_detail_attr_tbl => x_in_line_detail_attr_tbl ,
    p_related_lines_tbl => x_in_related_lines_tbl , p_control_rec => x_in_control_rec , x_line_tbl => x_out_line_tbl , x_line_qual => x_out_qual_tbl
    , x_line_attr_tbl => x_out_line_attr_tbl , x_line_detail_tbl => x_out_line_detail_tbl , x_line_detail_qual_tbl => x_out_line_detail_qual_tbl ,
    x_line_detail_attr_tbl => x_out_line_detail_attr_tbl , x_related_lines_tbl => x_out_related_lines_tbl , x_return_status => x_return_status ,
    x_return_status_text => x_return_status_text);
    -- Get the price
    IF x_out_line_tbl.count > 0 AND x_return_status = fnd_api.g_ret_sts_success THEN
      o_list_price := x_out_line_tbl(1).adjusted_unit_price;
    ELSE
      o_status := fnd_api.g_ret_sts_error;
      o_msg := x_return_status || ':' || x_return_status_text;
      o_list_price := NULL;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    o_status := fnd_api.g_ret_sts_error;
    o_msg := dbms_utility.format_error_backtrace;
    o_list_price := NULL;
  END interco_get_list_price;
/*================================================================================
Procedure to Insert Data into AP_INVOICE_INTERFACE and  AP_INVOICE_LINES_INTERFACE
==================================================================================*/
  PROCEDURE create_ap(
      x_errbuf OUT VARCHAR2,
      x_retcode OUT VARCHAR2)
  IS
    CURSOR c1(p_customer_trx_id IN NUMBER)
    IS
      SELECT *
      FROM ra_customer_trx_lines_all rctl
      WHERE interface_line_context ='INTERCOMPANY'
      AND interface_line_attribute15='P'
      AND line_type ='LINE'
      AND rctl.customer_trx_id =p_customer_trx_Id
      AND EXISTS
        (SELECT 1
        FROM ra_customer_trx_all trx,
          ra_batch_sources_all rbs
        WHERE rctl.customer_trx_id=trx.customer_trx_id
        AND trx.batch_source_id =rbs.batch_source_Id
        AND trx.org_id =rbs.org_Id
        AND rbs.name ='INTG Intercompany'
        );
    CURSOR c
    IS
      SELECT DISTINCT customer_trx_id,
        org_id
      FROM ra_customer_trx_lines_all rctl
      WHERE interface_line_context ='INTERCOMPANY'
      AND interface_line_attribute15='P'
      AND line_type ='LINE'
      AND EXISTS
        (SELECT 1
        FROM ra_customer_trx_all trx,
          ra_batch_sources_all rbs
        WHERE rctl.customer_trx_id=trx.customer_trx_id
        AND trx.batch_source_id =rbs.batch_source_Id
        AND trx.org_id =rbs.org_Id
        AND rbs.name ='INTG Intercompany'
        );
    l_intg_rec xx_ont_interco_staging%rowtype;
    l_ship_net mtl_shipping_network_view%rowtype;
    l_inv_hdr_id            NUMBER;
    l_inv_type_lookup_code  VARCHAR2(25) := 'STANDARD';
    l_line_type_lookup_code VARCHAR2(25) := 'ITEM';
    l_dist_conc_code        VARCHAR2(100);
    l_dist_conc_code_inv    VARCHAR2(100);
    l_item_cost             NUMBER;
    l_tot_cost              NUMBER;
    l_inv_profit            NUMBER;
    l_offset_amt            NUMBER;
    l_ins_cnt               NUMBER := 0;
    l_err_cnt               NUMBER := 0;
    l_cnt                   NUMBER;
    l_batch_id              NUMBER;
    l_return                BOOLEAN;
    l_req_id                NUMBER;
    l_err                   VARCHAR2(100);
    l_max_batch             NUMBER;
    l_price_list_id         NUMBER;
    l_inv_amt               NUMBER;
    l_line_num              NUMBER := 0;
    l_descr                 VARCHAR2(200);
    l_order_date            DATE;
    l_phase                 VARCHAR2(100);
    l_status                VARCHAR2(100);
    l_dev_phase             VARCHAR2(100);
    l_dev_status            VARCHAR2(100);
    l_message               VARCHAR2(100);
    l_seg1                  VARCHAR2(100);
    o_list_price            NUMBER;
    o_status                VARCHAR2(10);
    o_msg                   VARCHAR2(2000);
    l_list_price            NUMBER;
    l_error_transaction     EXCEPTION;
    l_mul_factor            NUMBER;
    l_ret                   VARCHAR2(10) := 'N';
    l_from_org_code         VARCHAR2(3);
    l_to_org_code           VARCHAR2(3);
    l_cust_trx_line_id      NUMBER;
    l_cust_trx_id           NUMBER;
    l_supplier_id           NUMBER;
    l_supplier_site_Id      NUMBER;
    l_inv_curr_code         VARCHAR2(10);
    l_trx_date              DATE;
    l_trx_number            VARCHAR2(400);
    l_type                  VARCHAR2(10);
    l_ic_accrual_amt        NUMBER;
  BEGIN
    SELECT MAX(batch_id) INTO l_max_batch FROM xx_ont_interco_staging;
    FOR i IN c
    LOOP
      SELECT ap_invoices_interface_s.nextval INTO l_inv_hdr_id FROM dual;
      l_line_num:=0;
      SELECT amount_due_original,
        invoice_currency_code,
        trx_date,
        trx_number
      INTO l_inv_amt,
        l_inv_curr_code,
        l_trx_date,
        l_trx_number
      FROM ar_payment_schedules_all
      WHERE customer_trx_id=i.customer_trx_id;
      FOR j IN c1(i.customer_trx_id)
      LOOP
        BEGIN
          BEGIN
            SELECT *
            INTO l_intg_rec
            FROM xx_ont_interco_staging
            WHERE mtl_transaction_Id=j.interface_line_attribute7;
            SELECT *
            INTO l_ship_net
            FROM mtl_shipping_network_view
            WHERE from_organization_id = l_intg_rec.from_org_id
            AND to_organization_id = l_intg_rec.to_org_id;
          EXCEPTION
          WHEN OTHERS THEN
            NULL;
          END;
          l_inv_profit:=NULL;
          SELECT b.type
          INTO l_type
          FROM ra_customer_trx_all a,
            ra_cust_trx_types_all b
          WHERE a.org_Id =b.org_Id
          AND a.customer_trx_Id =i.customer_trx_Id
          AND a.cust_trx_type_id =b.cust_trx_type_id;
          IF (l_intg_rec.return_category_code ='ORDER' AND l_type='INV')THEN
            l_ic_accrual_amt :=(l_intg_rec.ordered_qty*l_intg_rec.item_cost);
            l_inv_profit :=j.extended_amount -(l_intg_rec.ordered_qty*l_intg_rec.item_cost);
            l_inv_profit:=round(l_inv_profit,2);
            l_ic_accrual_amt:=round(l_ic_accrual_amt,2);
          elsif (l_intg_rec.return_category_code='RETURN' AND l_type='CM') THEN
            l_ic_accrual_amt := -1*(l_intg_rec.ordered_qty*l_intg_rec.item_cost);
            l_inv_profit :=j.extended_amount+(l_intg_rec.ordered_qty*l_intg_rec.item_cost);
            l_inv_profit:=round(l_inv_profit,2);
            l_ic_accrual_amt:=round(l_ic_accrual_amt,2);
          END IF;
          g_err_msg := 'before inserting into interface tables, checking the required values';
          IF l_ship_net.attribute11 IS NULL OR l_ship_net.profit_in_inv_account IS NULL OR l_inv_profit IS NULL OR l_ic_accrual_amt IS NULL THEN
            RETURN;
          END IF;
          l_line_num := l_line_num + 1;
          INSERT
          INTO ap_invoice_lines_interface
            (
              invoice_id ,
              invoice_line_id ,
              line_number ,
              line_type_lookup_code ,
              amount ,
              accounting_date ,
              dist_code_combination_id ,
              quantity_invoiced ,
              description ,
              inventory_item_id,
              reference_key1,
              reference_key2
              --source_application_id,source_entity_code, source_trx_id,source_line_Id,source_trx_level_type
            )
            VALUES
            (
              l_inv_hdr_id,
              ap_invoice_lines_interface_s.nextval,
              l_line_num,
              'ITEM',
              l_ic_accrual_amt,
             -- sysdate ,        --Commented for Case#8447
             l_trx_date,         --Added for Case#8447
              l_ship_net.attribute11,
              j.quantity_ordered,
              j.description,
              j.inventory_item_id,
              j.customer_trx_line_Id,
              j.interface_line_attribute7--,222,'TRANSACTIONS',j.customer_trx_id, j.customer_trx_line_Id,'LINE'
            );
          l_line_num := l_line_num + 1;
          INSERT
          INTO ap_invoice_lines_interface
            (
              invoice_id ,
              invoice_line_id ,
              line_number ,
              line_type_lookup_code ,
              amount ,
              accounting_date ,
              dist_code_combination_id ,
              quantity_invoiced ,
              description ,
              inventory_item_id,
              reference_key1,
              reference_key2
              --source_application_id,source_entity_code, source_trx_id,source_line_Id,source_trx_level_type
            )
            VALUES
            (
              l_inv_hdr_id,
              ap_invoice_lines_interface_s.nextval,
              l_line_num,
              'ITEM',
              l_inv_profit,
             -- sysdate ,  --Commented for Case#8447
             l_trx_date,   --Added for Case#8447
              l_ship_net.profit_in_inv_account,
              j.quantity_ordered,
              j.description,
              j.inventory_item_id,
              j.customer_trx_line_Id ,
              j.interface_line_attribute7
              --,222,'TRANSACTIONS',j.customer_trx_id, j.customer_trx_line_Id,'LINE'
            );
          l_ins_cnt := l_ins_cnt + 1;
          UPDATE xx_ont_interco_staging
          SET ap_err_msg = l_trx_number ,
            ap_ins = g_status_success ,
            ap_made='Y',
            ap_inv_id = l_inv_hdr_id ,
            batch_id = l_max_batch ,
            last_update_date = sysdate ,
            last_updated_by = fnd_global.user_id
          WHERE source = l_intg_rec.source
          AND source_ref_grp_id = l_intg_rec.source_ref_grp_id
          AND mtl_transaction_Id =l_intg_rec.mtl_transaction_id;
          UPDATE ra_customer_trx_lines_all
          SET interface_line_attribute15 =NULL,
            last_update_date = sysdate ,
            last_updated_by = fnd_global.user_id
          WHERE customer_trx_line_id =j.customer_trx_line_Id
          AND interface_line_attribute15='P';
        EXCEPTION
        WHEN OTHERS THEN
          UPDATE xx_ont_interco_staging
          SET ap_err_msg = g_err_msg ,
            ap_ins = g_status_error ,
            batch_id = l_max_batch ,
            last_update_date = sysdate ,
            last_updated_by = fnd_global.user_id
          WHERE source = l_intg_rec.source
          AND source_ref_grp_id = l_intg_rec.source_ref_grp_id
          AND mtl_transaction_Id =l_intg_rec.mtl_transaction_id;
          UPDATE ra_customer_trx_lines_all
          SET interface_line_attribute15 ='P',
            last_update_date = sysdate ,
            last_updated_by = fnd_global.user_id
          WHERE customer_trx_line_id =j.customer_trx_line_Id;
          l_err_cnt := l_err_cnt + 1;
          fnd_file.put_line(fnd_file.log, 'Exception in AP Insert: ' || g_err_msg);
          g_err_msg := NULL;
        END;
      END LOOP;
      g_err_msg := 'Error Fetching supplier information';
      BEGIN
        SELECT MAX(supp_id),
          MAX(supp_pay_site_id)
        INTO l_supplier_id,
          l_supplier_site_Id
        FROM xx_ont_interco_staging
        WHERE ar_err_msg=
          (SELECT trx_number
          FROM ra_customer_trx_all
          WHERE customer_trx_Id=i.customer_trx_Id
          );
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
      INSERT
      INTO ap_invoices_interface
        (
          invoice_id ,
          invoice_num ,
          invoice_type_lookup_code ,
          invoice_date ,
          vendor_id ,
          vendor_site_id ,
          invoice_amount ,
          invoice_currency_code ,
          gl_date ,
          source ,
          org_id,
          reference_1
        )
        VALUES
        (
          l_inv_hdr_id,
          l_trx_number,
          NULL,
          l_trx_date,
          l_supplier_id,
          --l_supplier_site_Id,
          l_ship_net.attribute6,
          l_inv_amt ,
          l_inv_curr_code,
          --sysdate,          --Commented for Case#8447
          l_trx_date,         --Added for Case#8447
          g_source,
          --i.org_id,
          l_intg_rec.to_ou,
          i.customer_trx_id
        );
    END LOOP;
    SELECT xx_ont_interco_batch_seq.nextval INTO l_batch_id FROM dual;
    l_req_id := fnd_request.submit_request(application => 'SQLAP' , program => 'APXIIMPT' , description => 'Import AP Invoice' , start_time =>
    sysdate , sub_request => NULL , argument1 => NULL , argument2 => 'Intercompany' , argument3 => NULL , argument4 => 'IC-BATCH-' || l_batch_id ,
    argument5 => NULL , argument6 => NULL , argument7 => NULL , argument8 => 'N' , argument9 => 'N' , argument10 => 'N' , argument11 => 'Y' ,
    argument12 => 1000 , argument13 => fnd_profile.value('USER_ID') , argument14 => fnd_profile.value('LOGIN_ID'));
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    fnd_file.put_line(fnd_file.log, 'Unhandled Exception in AP Creation: ' || sqlerrm);
    x_retcode := 2;
  END create_ap;
/*================================================================================
Procedure to Insert Data into AP_INVOICE_INTERFACE and  AP_INVOICE_LINES_INTERFACE
==================================================================================*/
  PROCEDURE create_ar(
      x_errbuf OUT VARCHAR2,
      x_retcode OUT VARCHAR2)
  IS
    CURSOR c_ar_inv_hdr
    IS
      SELECT source,
        source_ref_grp_id,
        tran_date,
        from_org_code,
        to_org_code
      FROM xx_ont_interco_staging
      WHERE NVL(ar_ins, g_status_error) = g_status_error
      GROUP BY source,
        source_ref_grp_id,
        tran_date,
        from_org_code,
        to_org_code;
    CURSOR c_ar_inv_lines(hdr_id NUMBER , tdate DATE , fcode NUMBER , tcode NUMBER)
    IS
      SELECT *
      FROM xx_ont_interco_staging
      WHERE NVL(ar_ins, g_status_error) = g_status_error
      AND source_ref_grp_id = hdr_id
      AND tran_date = tdate
      AND from_org_code = fcode
      AND to_org_code = tcode;
    l_order_num oe_order_headers_all.order_number%type;
    l_orig_sys_ref oe_order_headers_all.orig_sys_document_ref%type;
    l_header_id oe_order_headers_all.header_id%type;
    l_order_date oe_order_headers_all.ordered_date%type;
    l_line_num oe_order_lines_all.line_number%type;
    l_org_id oe_order_lines_all.org_id%type;
    l_ship_date oe_order_lines_all.schedule_ship_date%type;
    l_desc mtl_system_items_b.description%type;
    l_uom mtl_system_items_b.primary_uom_code%type;
    l_trx_type_id ra_cust_trx_types_all.cust_trx_type_id%type;
    l_pay_term hz_cust_site_uses_all.payment_term_id%type;
    l_salesrep hz_cust_site_uses_all.primary_salesrep_id%type;
    l_cust_acct_site_id hz_cust_site_uses_all.cust_acct_site_id%type;
    l_sob hr_operating_units.set_of_books_id%type;
    l_rec_acct_id       NUMBER;
    l_rev_acct_id       NUMBER;
    l_tax_acct_id       NUMBER;
    l_line_type         VARCHAR2(100) := 'LINE';
    l_trx_type          VARCHAR2(100) := 'INTG Intercompany';
    l_cm_trx_type       VARCHAR2(100) := 'INTG Intercompany CM';
    l_source_event      VARCHAR2(100) := 'INTERCOMPANY_TRX';
    l_ins_cnt           NUMBER := 0;
    l_err_cnt           NUMBER := 0;
    l_req_id            NUMBER;
    l_err               VARCHAR2(100);
    l_cnt               NUMBER := 0;
    l_trx_num           VARCHAR2(100);
    l_line_id           NUMBER;
    l_max_batch         NUMBER;
    l_price_list_id     NUMBER;
    l_tot_cost          NUMBER;
    l_item_cost         NUMBER;
    l_line_no           NUMBER;
    l_phase             VARCHAR2(100);
    l_status            VARCHAR2(100);
    l_dev_phase         VARCHAR2(100);
    l_dev_status        VARCHAR2(100);
    l_message           VARCHAR2(100);
    l_seg1              VARCHAR2(100);
    o_list_price        NUMBER;
    o_status            VARCHAR2(10);
    o_msg               VARCHAR2(2000);
    l_mul_factor        NUMBER := 1;
    l_error_transaction EXCEPTION;
    no_pay_terms        EXCEPTION;
    l_ret               VARCHAR2(10) := 'N';
    l_grp_seq           NUMBER;
    x_price_ret_status  VARCHAR2(1);
    x_inv_curr_code     VARCHAR2(100);
    l_ar_request_id     NUMBER;
    l_trf_price_mkp     NUMBER;
    l_reference         VARCHAR2(100);
    l_qty               NUMBER;
    l_batch_source_id   NUMBER;
  BEGIN
    SELECT MAX(batch_id)
    INTO l_max_batch
    FROM xx_ont_interco_staging;
    FOR c1 IN
    (SELECT tran_date,
      from_org_code,
      to_org_code
    FROM xx_ont_interco_staging
    WHERE NVL(ar_ins, g_status_error) = g_status_error
    AND source = 'MTL_TRANSACTION'
    GROUP BY tran_date,
      from_org_code,
      to_org_code
    )
    LOOP
      SELECT oe_order_headers_s.nextval INTO l_grp_seq FROM dual;
      UPDATE xx_ont_interco_staging
      SET source_ref_grp_id = l_grp_seq
      WHERE tran_date = c1.tran_date
      AND from_org_code = c1.from_org_code
      AND to_org_code = c1.to_org_code
      AND NVL(ar_ins, g_status_error) = g_status_error
      AND source = 'MTL_TRANSACTION';
    END LOOP;
    FOR rec1 IN c_ar_inv_hdr
    LOOP
      BEGIN
        l_line_no := 0;
        FOR rec IN c_ar_inv_lines(rec1.source_ref_grp_id, rec1.tran_date, rec1.from_org_code, rec1.to_org_code)
        LOOP
          BEGIN
            IF rec.source = 'SALES_ORDER' THEN
              g_err_msg := 'Error Fetching Order Header Info';
              l_reference :=rec.mtl_transaction_id;
              SELECT ooh.order_number,
                ooh.header_id,
                ool.line_number,
                ooh.orig_sys_document_ref,
                ooh.ordered_date,
                ool.org_id ,
                rec.tran_date
              INTO l_order_num,
                l_header_id,
                l_line_num,
                l_orig_sys_ref,
                l_order_date,
                l_org_id,
                l_ship_date
              FROM oe_order_headers_all ooh,
                oe_order_lines_all ool
              WHERE ooh.header_id = ool.header_id
              AND ool.line_id = rec.source_ref_id
              AND EXISTS
                (SELECT 1
                FROM mtl_material_transactions mmt
                WHERE ool.line_Id =mmt.trx_source_line_id
                AND rec.mtl_transaction_id=mmt.transaction_id
                );
              l_price_list_id := rec.pricelist_id;
            elsif rec.source = 'MTL_TRANSACTION' THEN
              l_order_num := rec.source_ref_grp_id;
              l_header_id := rec.source_ref_grp_id;
              l_line_num := rec.source_ref_grp_id;
              l_orig_sys_ref := rec.source_ref_grp_id;
              l_org_id := rec.from_org_id;
              l_order_date := rec.tran_date;
              l_ship_date := rec.tran_date;
              l_price_list_id := rec.pricelist_id;
              l_reference :=rec.source_ref_id;
            END IF;
            g_err_msg := 'Error Fetching SOB ID';
            -- Fetching Set Of Books ID
            SELECT set_of_books_id
            INTO l_sob
            FROM hr_operating_units
            WHERE organization_id = rec.from_ou;
            g_err_msg := 'Error Fetching Item Details';
            -- Fetching Item Description
            SELECT description,
              primary_uom_code,
              segment1
            INTO l_desc,
              l_uom,
              l_seg1
            FROM mtl_system_items_b
            WHERE inventory_item_id = rec.inventory_item_id
            AND organization_id = rec.from_org_id;
            SELECT batch_source_id
            INTO l_batch_source_id
            FROM ra_batch_sources_all
            WHERE org_id =rec.from_ou
            AND name = l_trx_type ;
            g_err_msg := 'Error Fetching Cust TRX TYPE ID';
            IF NVL(rec.return_category_code,'ORDER')='ORDER' THEN
              l_qty :=rec.ordered_qty;
              SELECT cust_trx_type_id
              INTO l_trx_type_id
              FROM ra_cust_trx_types_all
              WHERE name = l_trx_type
              AND org_id = rec.from_ou;
              BEGIN
                g_err_msg := 'Error Fetching Customer Site Details ';
                SELECT payment_term_id,
                  NVL(primary_salesrep_id, -3),
                  cust_acct_site_id
                INTO l_pay_term,
                  l_salesrep,
                  l_cust_acct_site_id
                FROM hz_cust_site_uses_all
                WHERE site_use_id = rec.cust_bill_site_id
                AND org_id = rec.from_ou;
                IF l_pay_term IS NULL THEN
                  raise no_pay_terms;
                END IF;
              EXCEPTION
              WHEN no_pay_terms THEN
                g_err_msg := 'Please Assign Payment Terms for Customer Site';
                raise;
              WHEN OTHERS THEN
                g_err_msg := 'Error Fetching Customer Site Details ';
                raise;
              END;
            elsif rec.return_category_code='RETURN' THEN
              l_qty :=-1*rec.ordered_qty;
              g_err_msg := 'Transaction Type INTG Intercompany CM is missing. Please set up.';
              BEGIN
                SELECT credit_memo_type_id
                INTO l_trx_type_id
                FROM ra_cust_trx_types_all
                WHERE name = l_trx_type
                AND org_id = rec.from_ou;
              EXCEPTION
              WHEN OTHERS THEN
                BEGIN
                  SELECT cust_trx_type_id
                  INTO l_trx_type_id
                  FROM ra_cust_trx_types_all
                  WHERE name = l_cm_trx_type
                  AND org_id = rec.from_ou;
                EXCEPTION
                WHEN OTHERS THEN
                  g_err_msg := 'Transaction Type INTG Intercompany CM is missing. Please set up.';
                  raise;
                END;
              END;
              BEGIN
                g_err_msg := 'Error Fetching Customer Site Details ';
                l_pay_term:=NULL;
                SELECT NVL(primary_salesrep_id, -3),
                  cust_acct_site_id
                INTO l_salesrep,
                  l_cust_acct_site_id
                FROM hz_cust_site_uses_all
                WHERE site_use_id = rec.cust_bill_site_id
                AND org_id = rec.from_ou;
              EXCEPTION
              WHEN OTHERS THEN
                g_err_msg := 'Error Fetching Customer Site Details ';
                raise;
              END;
            END IF;
            g_err_msg := 'Error Fetchin REC from Customer Site';
            SELECT gl_id_rec
            INTO l_rec_acct_id
            FROM hz_cust_site_uses_all
            WHERE site_use_id = rec.cust_bill_site_id
            AND org_id = rec.from_ou;
            g_err_msg := 'Error Fetching REV Acc. from Shipping N/W';
            SELECT gcc.code_combination_id,
              ms.attribute13
            INTO l_rev_acct_id,
              l_trf_price_mkp
            FROM mtl_shipping_network_view ms,
              gl_code_combinations_kfv gcc
            WHERE from_organization_code = rec.from_org_code
            AND to_organization_code = rec.to_org_code
            AND gcc.code_combination_id = ms.attribute12;
            BEGIN
              o_list_price := rec.transfer_price;
              o_status := 'S';
              IF o_list_price IS NULL THEN
                o_list_price := rec.item_cost*rec.trf_price_markup;
              END IF;
              o_status := 'S';
              IF o_status = 'S' AND o_list_price IS NOT NULL THEN
                -- Rounding Logic Changes
                IF NVL(rec.return_category_code,'ORDER') ='ORDER' THEN
                  l_tot_cost := ROUND(o_list_price * rec.ordered_qty, 2);
                elsif NVL(rec.return_category_code,'ORDER')='RETURN' THEN
                  l_tot_cost := -1*ROUND(o_list_price * rec.ordered_qty, 2);
                  --l_tot_cost:=-1*l_tot_cost;
                END IF;
                -- END;
              ELSE
                g_err_msg := 'Error Deriving List Price ' || o_msg || 'Item ' || l_desc || '( ' || l_seg1 || ' )';
                raise l_error_transaction;
              END IF;
            EXCEPTION
            WHEN l_error_transaction THEN
              raise;
            WHEN OTHERS THEN
              g_err_msg := 'Error Deriving List Price ' || sqlerrm || 'Item ' || l_desc || '( ' || l_seg1 || ' )';
              raise;
            END;
            l_line_no := l_line_no + 1;
            g_err_msg := 'Error Inserting Data into Lines Interface Table';
            --fnd_file.put_line (fnd_file.LOG,'Insert into  RA_INTERFACE_LINES_ALL  '||REC.SOURCE_REF_ID);
            -- Insert Data into Lines Interface Table
            INSERT
            INTO ra_interface_lines_all
              (
                interface_line_context ,
                interface_line_attribute1 ,
                interface_line_attribute2 ,
                interface_line_attribute3 ,
                interface_line_attribute4 ,
                interface_line_attribute5 ,
                interface_line_attribute6 ,
                interface_line_attribute7 ,
                interface_line_attribute8 ,
                batch_source_name ,
                set_of_books_id ,
                line_type ,
                description ,
                currency_code ,
                amount ,
                cust_trx_type_id ,
                term_id ,
                orig_system_bill_customer_id ,
                orig_system_bill_address_id ,
                orig_system_sold_customer_id ,
                line_number ,
                quantity ,
                quantity_ordered ,
                unit_selling_price ,
                unit_standard_price ,
                ship_date_actual ,
                primary_salesrep_id ,
                sales_order ,
                sales_order_line ,
                sales_order_date ,
                inventory_item_id ,
                uom_code ,
                interface_line_attribute15 ,
                interface_line_attribute9 ,
                org_id ,
                reset_trx_date_flag ,
                warehouse_id ,
                source_event_class_code ,
                conversion_type ,
                conversion_rate ,
                taxable_flag
              )
              VALUES
              (
                upper(g_source),
                l_order_num,
                l_line_num,
                rec.from_org_id,
                rec.from_ou,
                rec.to_ou,
                rec.source_ref_id,
                l_reference ,
                rec.from_org_id,
                l_trx_type,
                l_sob,
                l_line_type,
                l_desc,
                rec.curr,
                l_tot_cost,
                l_trx_type_id,
                l_pay_term,
                rec.cust_id ,
                l_cust_acct_site_id,
                rec.cust_id,
                l_line_num,
                l_qty,
                l_qty,
                o_list_price,
                o_list_price ,
                l_ship_date,
                l_salesrep,
                l_order_num,
                l_line_no,
                l_order_date,
                rec.inventory_item_id,
                l_uom,
                'P',
                l_header_id,
                rec.from_ou ,
                'Y',
                rec.from_org_id,
                l_source_event,
                'User' ,
                1 ,
                'N'
              );
            g_err_msg := 'Error Inserting Data into Salescredit Table';
            -- Inserting Data into Salescredit Table
            INSERT
            INTO ra_interface_salescredits_all
              (
                interface_line_context ,
                interface_line_attribute1 ,
                interface_line_attribute2 ,
                interface_line_attribute3 ,
                interface_line_attribute4 ,
                interface_line_attribute5 ,
                interface_line_attribute6 ,
                interface_line_attribute7 ,
                interface_line_attribute8 ,
                salesrep_id ,
                sales_credit_type_id ,
                sales_credit_percent_split ,
                interface_line_attribute15 ,
                interface_line_attribute9 ,
                org_id
              )
              VALUES
              (
                upper(g_source),
                l_order_num,
                l_line_num,
                rec.from_org_id,
                rec.from_ou,
                rec.to_ou,
                rec.source_ref_id,
                l_reference ,
                rec.from_org_id,
                l_salesrep,
                1,
                100,
                'P',
                l_header_id,
                rec.from_ou
              );
            g_err_msg := 'Error Inserting REC Data into Distributions Table';
            -- Inserting Data into Distributions Table for REC
            INSERT
            INTO ra_interface_distributions_all
              (
                interface_line_context ,
                interface_line_attribute1 ,
                interface_line_attribute2 ,
                interface_line_attribute3 ,
                interface_line_attribute4 ,
                interface_line_attribute5 ,
                interface_line_attribute6 ,
                interface_line_attribute7 ,
                interface_line_attribute8 ,
                account_class ,
                amount ,
                percent ,
                code_combination_id ,
                interface_line_attribute15 ,
                interface_line_attribute9 ,
                org_id
              )
              VALUES
              (
                upper(g_source),
                l_order_num,
                l_line_num,
                rec.from_org_id,
                rec.from_ou,
                rec.to_ou,
                rec.source_ref_id,
                l_reference ,
                rec.from_org_id,
                'REC',
                l_tot_cost,
                100,
                l_rec_acct_id,
                'P',
                l_header_id,
                rec.from_ou
              );
            g_err_msg := 'Error Inserting REV Data into Distributions Table';
            -- Inserting Data into Distributions Table for REV
            INSERT
            INTO ra_interface_distributions_all
              (
                interface_line_context ,
                interface_line_attribute1 ,
                interface_line_attribute2 ,
                interface_line_attribute3 ,
                interface_line_attribute4 ,
                interface_line_attribute5 ,
                interface_line_attribute6 ,
                interface_line_attribute7 ,
                interface_line_attribute8 ,
                account_class ,
                amount ,
                percent ,
                code_combination_id ,
                interface_line_attribute15 ,
                interface_line_attribute9 ,
                org_id
              )
              VALUES
              (
                upper(g_source),
                l_order_num,
                l_line_num,
                rec.from_org_id,
                rec.from_ou,
                rec.to_ou,
                rec.source_ref_id,
                l_reference ,
                rec.from_org_id,
                'REV',
                l_tot_cost,
                100,
                l_rev_acct_id,
                'P' ,
                l_header_id,
                rec.from_ou
              );
            l_ins_cnt := l_ins_cnt + 1;
            UPDATE xx_ont_interco_staging
            SET ar_err_msg = 'Y' ,
              ar_ins = g_status_success ,
              batch_id = l_max_batch ,
              last_update_date = sysdate ,
              last_updated_by = fnd_global.user_id
            WHERE source = rec.source
            AND source_ref_grp_id = rec.source_ref_grp_id
            AND source_ref_id = rec.source_ref_id
            AND mtl_transaction_id=rec.mtl_transaction_id;
          EXCEPTION
          WHEN OTHERS THEN
            g_err_msg := g_err_msg || ' for Line ' || rec.source_ref_id;
            fnd_file.put_line(fnd_file.log, SQLERRM);
            UPDATE xx_ont_interco_staging
            SET ar_err_msg = g_err_msg ,
              ar_ins = g_status_error ,
              batch_id = l_max_batch ,
              last_update_date = sysdate ,
              last_updated_by = fnd_global.user_id
            WHERE source = rec.source
            AND source_ref_grp_id = rec.source_ref_grp_id
            AND source_ref_id = rec.source_ref_id
            AND mtl_transaction_id=rec.mtl_transaction_id;
            l_err_cnt := l_err_cnt + 1;
            g_err_msg := NULL;
            l_ret := 'Y';
          END;
        END LOOP;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Failed for Batch ID ' || rec1.source_ref_grp_id);
        l_ret := 'Y';
      END;
    END LOOP;
    fnd_file.put_line(fnd_file.log, 'Rows Successfully Inserted into AR Interface Table : ' || l_ins_cnt);
    fnd_file.put_line(fnd_file.log, 'Rows Error Out                                     : ' || l_err_cnt);
    BEGIN
      IF l_ins_cnt > 0 THEN
      fnd_file.put_line(fnd_file.log, 'Submitting AR Interface Program ');
        l_req_id := fnd_request.submit_request(application => 'AR' , program => 'RAXMTR' , description => 'Import AR Invoice' , start_time => sysdate
        , sub_request => NULL , argument1 => 4 , argument2 => -99 , argument3 => l_batch_source_id , argument4 => 'INTG Intercompany' , argument5 =>
        sysdate , argument6 => NULL , argument7 => NULL , argument8 => NULL , argument9 => NULL , argument10 => NULL , argument11 => NULL ,
        argument12 => NULL , argument13 => NULL , argument14 => NULL , argument15 => NULL , argument16 => NULL , argument17 => NULL , argument18 =>
        NULL , argument19 => NULL , argument20 => NULL , argument21 => NULL , argument22 => NULL , argument23 => NULL , argument24 => NULL ,
        argument25 => NULL , argument26 => 'Y' , argument27 => NULL);
        COMMIT;
        IF l_req_id = 0 THEN
          fnd_file.put_line(fnd_file.log, 'Exception in Submitting AR Interface Program ');
        ELSE
        fnd_file.put_line(fnd_file.log, 'Autoinvoice Master submitted successfully. Updating the AR req ID');
          UPDATE xx_ont_interco_staging
          SET ar_request_id = l_req_id
          WHERE source_ref_grp_id = l_grp_seq
          AND batch_id = l_max_batch
          AND ar_err_msg = 'Y'
          AND ar_ins = g_status_success;
          IF fnd_concurrent.wait_for_request(request_id => l_req_id , interval => 10 , phase => l_phase , status => l_status , dev_phase =>
            l_dev_phase , dev_status => l_dev_status , MESSAGE => l_message) THEN
            BEGIN
            fnd_file.put_line(fnd_file.log, 'Update records that are processed successfully');
              UPDATE xx_ont_interco_staging a
              SET ar_made='Y',
                last_update_date = sysdate ,
                last_updated_by = fnd_global.user_id,
                ar_err_msg=
                (SELECT DISTINCT trx_number
                FROM ra_customer_trx_all b,
                  ra_customer_trx_lines_all c
                WHERE a.mtl_transaction_id =c.interface_line_attribute7
                AND c.interface_line_context ='INTERCOMPANY'
                AND b.customer_trx_Id =c.customer_trx_id
                AND (b.org_Id,b.batch_source_id) IN
                  (SELECT org_Id,
                    batch_source_id
                  FROM ra_batch_sources_all
                  WHERE name='INTG Intercompany'
                  )
                AND a.source_ref_id=c.interface_line_attribute6
                )
              WHERE ar_made IS NULL
              AND ar_err_msg ='Y'
              AND batch_id = l_max_batch
              AND ar_ins ='S'
              AND EXISTS
                (SELECT DISTINCT trx_number
                FROM ra_customer_trx_all b,
                  ra_customer_trx_lines_all c
                WHERE a.mtl_transaction_id =c.interface_line_attribute7
                AND c.interface_line_context ='INTERCOMPANY'
                AND b.customer_trx_Id =c.customer_trx_id
                AND (b.org_Id,b.batch_source_id) IN
                  (SELECT org_Id,
                    batch_source_id
                  FROM ra_batch_sources_all
                  WHERE name='INTG Intercompany'
                  )
                AND a.source_ref_id=c.interface_line_attribute6
                );
             fnd_file.put_line(fnd_file.log, sql%rowcount||' Records processed successfully');
             fnd_file.put_line(fnd_file.log, 'Update records that are not processed successfully');
              UPDATE xx_ont_interco_staging a
              SET ar_err_msg = g_err_msg ,
                ar_made=NULL,
                ar_ins = g_status_error ,
                last_update_date = sysdate ,
                last_updated_by = fnd_global.user_id
              WHERE NOT EXISTS
                (SELECT 1
                FROM ra_customer_trx_lines_all b,
                  ra_customer_trx_all c,
                  ra_batch_sources_all d
                WHERE a.mtl_transaction_id =b.interface_line_attribute7
                AND a.source_ref_id =b.interface_line_attribute6
                AND b.customer_trx_Id =c.customer_trx_id
                AND c.batch_source_id =d.batch_source_Id
                AND d.name ='INTG Intercompany'
                AND b.interface_line_context ='INTERCOMPANY'
                AND c.org_Id =d.org_Id
                )
              AND ar_ins ='Y'
              AND ar_err_msg='Y'
              AND batch_id = l_max_batch;
              fnd_file.put_line(fnd_file.log, sql%rowcount||' Records rejected');
            EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line (fnd_file.LOG,' g_err_msg ' ||  g_err_msg||SQLERRM);
              UPDATE xx_ont_interco_staging
              SET ar_err_msg = g_err_msg ,
                ar_ins = g_status_error ,
                last_update_date = sysdate ,
                last_updated_by = fnd_global.user_id
              WHERE batch_id=l_max_batch;
              l_ret := 'Y';
            END;
          END IF;
        END IF;
      END IF;
      fnd_file.put_line(fnd_file.log, 'Deleting interface records that are not processed');
      DELETE
      FROM ra_interface_distributions_all a
      WHERE interface_line_context = 'INTERCOMPANY'
      AND NVL(interface_status,'~')<>'P'
      AND interface_line_id IS NOT NULL
      AND EXISTS
        (SELECT 1
        FROM ra_interface_errors_all b
        WHERE a.interface_line_id=b.interface_line_id
        )
      AND interface_line_attribute6 IN
        (SELECT source_ref_id
        FROM xx_ont_interco_staging
        WHERE NVL(ar_ins, g_status_error) = 'S'
        )
      AND interface_line_attribute7 IN
        (SELECT mtl_transaction_id
        FROM xx_ont_interco_staging
        WHERE NVL(ar_ins, g_status_error) = 'S'
        );
      DELETE
      FROM ra_interface_salescredits_all a
      WHERE interface_line_context = 'INTERCOMPANY'
      AND NVL(interface_status,'~')<>'P'
      AND interface_line_id IS NOT NULL
      AND EXISTS
        (SELECT 1
        FROM ra_interface_errors_all b
        WHERE a.interface_line_id=b.interface_line_id
        )
      AND interface_line_attribute6 IN
        (SELECT source_ref_id
        FROM xx_ont_interco_staging
        WHERE NVL(ar_ins, g_status_error) = 'S'
        )
      AND interface_line_attribute7 IN
        (SELECT mtl_transaction_id
        FROM xx_ont_interco_staging
        WHERE NVL(ar_ins, g_status_error) = 'S'
        );
      DELETE
      FROM ra_interface_lines_all a
      WHERE interface_line_context = 'INTERCOMPANY'
      AND NVL(interface_status,'~')<>'P'
      AND interface_line_id IS NOT NULL
      AND EXISTS
        (SELECT 1
        FROM ra_interface_errors_all b
        WHERE a.interface_line_id=b.interface_line_id
        )
      AND interface_line_attribute6 IN
        (SELECT source_ref_id
        FROM xx_ont_interco_staging
        WHERE NVL(ar_ins, g_status_error) = 'S'
        )
      AND interface_line_attribute7 IN
        (SELECT mtl_transaction_id
        FROM xx_ont_interco_staging
        WHERE NVL(ar_ins, g_status_error) = 'S'
        );
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Exception in Submitting AR Interface ' || sqlerrm);
    END;
    IF l_ret = 'Y' THEN
      x_retcode := 1;
      -- Print Header
      fnd_file.put_line(fnd_file.log, ' ');
      fnd_file.put_line(fnd_file.log, 'Error Record Details For AR Interface');
      fnd_file.put_line(fnd_file.log, rpad('*', 140, '*'));
      fnd_file.put_line(fnd_file.log, rpad('Trans. No./Order No.', 40, ' ') || rpad('Error Message', 120, ' '));
      fnd_file.put_line(fnd_file.log, rpad('*', 140, '*'));
      -- Print Error Records
      FOR c3 IN
      (SELECT * FROM xx_ont_interco_staging WHERE ar_ins = 'E' OR ar_made = 'E'
      )
      LOOP
        fnd_file.put_line(fnd_file.log, rpad(c3.source_ref_id, 40, ' ') || rpad(SUBSTR(c3.ar_err_msg, 0, 120), 120, ' '));
      END LOOP;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Unhandled Exception in AR Creation: ' || sqlerrm);
    x_retcode := 2;
  END create_ar;
/*=============================================================================================
Procedure to Insert Data into Staging Table
===============================================================================================*/
  PROCEDURE insert_staging(
      x_errbuf OUT VARCHAR2,
      x_retcode OUT VARCHAR2)
  IS
    CURSOR c_order_lines
    IS
      SELECT mp.organization_code frm_org_code,
        ool.org_id,
        ABS(mmt.primary_quantity) "ORDERED_QUANTITY" ,
        NVL( ool.pricing_quantity_uom, ool.order_quantity_uom) "ORDER_QUANTITY_UOM",
        ool.inventory_item_id,
        ool.line_id,
        ool.header_id ,
        mso.segment2 order_type,
        ool.unit_selling_price,
        ooh.transactional_curr_code,
        ooh.order_number,
        ooh.ordered_date,
        mmt.transaction_date,
        mmt.transaction_id mmt_transaction_Id,
        mmt.organization_Id from_organization_id,
        (SELECT MAX(unit_cost)
        FROM cst_revenue_cogs_match_lines crc
        WHERE crc.cogs_om_line_id= mmt.trx_source_line_id
        ) item_cost,
      ool.reference_line_id,
      (SELECT (flv.lookup_code)
      FROM hr_operating_units hou,
        fnd_lookup_values_vl flv
      WHERE hou.organization_id = ool.org_id
      AND flv.tag = hou.short_code
      AND flv.lookup_type = 'INTG_DEFAULT_IO_OU'
      AND flv.enabled_flag = 'Y'
      AND sysdate BETWEEN start_date_active AND NVL(end_date_active, sysdate + 1)
      ) to_org_code,
      CASE
        WHEN (mmt.transaction_type_id=10008
        AND mmt.primary_quantity >0)
        THEN 'ORDER'
        WHEN (mmt.transaction_type_id=10008
        AND mmt.primary_quantity <0)
        THEN 'RETURN'
        ELSE ool.line_category_code
      END line_category_code
    FROM oe_order_lines_all ool,
      oe_order_headers_all ooh,
      mtl_parameters mp,
      oe_transaction_types_all ott,
      mtl_material_transactions mmt,
      mtl_sales_orders mso
    WHERE mmt.trx_source_line_id=ool.line_Id
    AND EXISTS
      (SELECT 1
      FROM cst_organization_definitions cst
      WHERE cst.organization_id=mmt.organization_id
      AND ool.org_id =cst.operating_unit
      )
    AND EXISTS
      (SELECT 1
      FROM mtl_transaction_accounts mta
      WHERE mmt.transaction_id =mta.transaction_id
      AND mta.accounting_line_type=35
      )
    AND mmt.organization_id =
      (SELECT organization_Id FROM mtl_parameters WHERE organization_code='126'
      )
    AND mmt.trx_source_line_id =ool.line_id
    AND mmt.transaction_source_id=mso.sales_order_id
    AND mmt.costed_flag IS NULL
    AND ool.ship_from_org_id IS NOT NULL
    AND ool.cancelled_flag = 'N'
    AND ool.open_flag = 'N'
    AND ool.header_id = ooh.header_id
    AND ool.ship_from_org_id = mp.organization_id
    AND ooh.order_type_id = ott.transaction_type_id
      --and nvl(ott.attribute1, 'No') = 'Yes'
    AND NOT EXISTS
      (SELECT 1
      FROM xx_ont_interco_staging
      WHERE source_ref_id = ool.line_id
      AND source = 'SALES_ORDER'
      AND mtl_transaction_id=mmt.transaction_id
      );
    CURSOR c_mtl_tran
    IS
      SELECT 'MTL_TRANSACTION' "SOURCE",
        mt.transaction_set_id "SOURCE_REF_GRP_ID",
        mt.transaction_id "SOURCE_REF_ID" ,
        TRUNC(mt.transaction_date) tran_date,
        'INTERNAL' "ORDER_TYPE",
        mt.inventory_item_id,
        mt.actual_cost ,
        ABS(NVL( mt.primary_quantity, mt.transaction_quantity)) ordered_qty ,
        DECODE(mt.primary_quantity, NULL, mt.transaction_uom, e.primary_uom_code) "ITEM_UOM",
        mt.organization_id "FROM_ORG_ID" ,
        mt.transfer_organization_id "TO_ORG_ID",
        c.organization_code "FRM_ORG",
        d.organization_code "TO_ORG" ,
        c.operating_unit "FROM_OU",
        d.operating_unit "TO_OU" ,
        c.currency_code
      FROM mtl_material_transactions mt ,
        cst_organization_definitions c,
        cst_organization_definitions d,
        mtl_system_items_b e,
        mtl_interorg_parameters f
      WHERE mt.transfer_organization_id IS NOT NULL
      AND mt.organization_id <> mt.transfer_organization_id
      AND c.organization_id = mt.organization_id
      AND d.organization_id = mt.transfer_organization_id
      AND mt.organization_id = f.from_organization_id
      AND mt.transfer_organization_id = f.to_organization_id
      AND NVL(f.attribute2, '2') = '1'
      AND mt.transaction_type_id IN (54,62, 3)
      AND mt.costed_flag IS NULL
      AND NVL(primary_quantity, transaction_quantity) < 0
      AND e.inventory_item_id = mt.inventory_item_id
      AND e.organization_id = mt.organization_id
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ont_interco_staging
        WHERE source_ref_id = mt.transaction_id
        AND source = 'MTL_TRANSACTION'
        );
    l_cnt NUMBER := 0;
    l_ship_net mtl_shipping_network_view%rowtype;
    l_ins            VARCHAR2(10) := 'N';
    l_cust_id        NUMBER;
    l_ins_cnt        NUMBER := 0;
    l_err_cnt        NUMBER := 0;
    l_from_org_id    NUMBER;
    l_to_org_id      NUMBER;
    l_op_unit_frm    NUMBER;
    l_op_unit_to     NUMBER;
    l_curr_code      VARCHAR2(10);
    l_item_cost      NUMBER;
    l_req_id         NUMBER;
    l_ret            VARCHAR2(10);
    l_transfer_price NUMBER;
    l_to_org_code    VARCHAR2(3);
  BEGIN
    SELECT NVL(MAX(batch_id), 0) + 1 INTO g_batch_id FROM xx_ont_interco_staging;
    fnd_file.put_line(fnd_file.log, 'Collecting Sales Order Shipments that need intercompany invoicing');
    FOR i IN c_order_lines
    LOOP
      BEGIN
        BEGIN
          BEGIN
            g_err_msg := 'Error in Deriving Shipping Networks ';
            SELECT *
            INTO l_ship_net
            FROM mtl_shipping_network_view
            WHERE from_organization_code = i.frm_org_code
            AND to_organization_code = i.to_org_code
            AND attribute2 = '1'
            AND attribute3 IS NOT NULL;
            SELECT a.operating_unit,
              b.operating_unit
            INTO l_op_unit_frm,
              l_op_unit_to
            FROM cst_organization_definitions a,
              cst_organization_definitions b
            WHERE a.organization_code = i.frm_org_code
            AND b.organization_code = i.to_org_code;
            l_ins := 'Y';
          EXCEPTION
          WHEN no_data_found THEN
            l_ins := 'N';
          WHEN OTHERS THEN
            l_ins := 'N';
          END;
          IF l_ins = 'Y' THEN
            BEGIN
              SELECT hcas.cust_account_id
              INTO l_cust_id
              FROM hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcs
              WHERE hcs.site_use_id = l_ship_net.attribute4
              AND hcas.cust_acct_site_id = hcs.cust_acct_site_id;
            EXCEPTION
            WHEN OTHERS THEN
              g_err_msg := 'Error Deriving Customer ID';
              raise;
            END;
            IF i.item_cost IS NULL THEN
              BEGIN
                l_item_cost := cst_cost_api.get_item_cost(p_api_version => 1.0 , p_inventory_item_id => i.inventory_item_id , p_organization_id =>
                i.from_organization_id);
              EXCEPTION
              WHEN OTHERS THEN
                g_err_msg := 'Error Deriving Item Cost ';
                raise;
              END;
            ELSE
              l_item_cost:=i.item_cost;
            END IF;
            g_err_msg := 'Error While calculating transfer price (cost*markup from shipping network)';
            BEGIN
              l_transfer_price:=l_item_cost*l_ship_net.attribute13;
            EXCEPTION
            WHEN OTHERS THEN
              raise;
            END;
            g_err_msg := 'Error While Inserting Data into Staging Tabele';
            INSERT
            INTO xx_ont_interco_staging
              (
                source ,
                source_ref_grp_id ,
                source_ref_id ,
                tran_date ,
                order_type ,
                batch_id ,
                inventory_item_id ,
                ordered_qty ,
                unit_selling_price ,
                curr ,
                pricelist_id ,
                item_cost ,
                item_uom ,
                from_org_code ,
                to_org_code ,
                from_org_id ,
                to_org_id ,
                from_ou ,
                to_ou ,
                cust_id ,
                cust_bill_site_id ,
                supp_id ,
                supp_pay_site_id ,
                created_by ,
                creation_date ,
                last_updated_by ,
                last_update_date ,
                mtl_transaction_id,
                transfer_price,
                fair_market_price,
                reference_line_id,
                return_category_code,
                trf_price_markup
              )
              VALUES
              (
                'SALES_ORDER',
                i.header_id,
                i.line_id,
                TRUNC(i.transaction_date),
                i.order_type,
                g_batch_id,
                i.inventory_item_Id ,
                i.ordered_quantity,
                i.unit_selling_price,
                i.transactional_curr_code,
                l_ship_net.pricelist_id ,
                ROUND(NVL( i.item_cost,l_item_cost),2),
                i.order_quantity_uom,
                i.frm_org_code,
                i.to_org_code,
                l_ship_net.from_organization_Id,
                l_ship_net.to_organization_id,
                l_op_unit_frm ,
                l_op_unit_to,
                l_cust_id,
                l_ship_net.attribute4,
                l_ship_net.attribute5,
                l_ship_net.attribute6,
                fnd_global.user_id ,
                sysdate,
                fnd_global.user_id,
                sysdate,
                i.mmt_transaction_Id,
                l_transfer_price,
                l_transfer_price,
                i.reference_line_id,
                i.line_category_code,
                l_ship_net.attribute13
              );
            UPDATE mtl_material_transactions
            SET transfer_price = l_transfer_price,
              attribute15='Y'
            WHERE transaction_id =i.mmt_transaction_Id;
            l_ins_cnt := l_ins_cnt + 1;
            fnd_file.put_line(fnd_file.output, ' ');
            fnd_file.put_line(fnd_file.output, '***** PROCESSED ***** ');
            fnd_file.put_line(fnd_file.output, 'Type         : ' || 'SALES_ORDER');
            fnd_file.put_line(fnd_file.output, 'Order Number : ' || i.order_number);
            fnd_file.put_line(fnd_file.output, 'From  Org    : ' || i.frm_org_code);
            fnd_file.put_line(fnd_file.output, 'To    Org    : ' || i.to_org_code);
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Exception for Order Line: ' || i.order_number || ' Error Msg. ' || g_err_msg|| '  '||SQLERRM);
          fnd_file.put_line(fnd_file.output, ' ');
          fnd_file.put_line(fnd_file.output, '***** ERROR ***** ');
          fnd_file.put_line(fnd_file.output, 'Type         : ' || 'SALES_ORDER');
          fnd_file.put_line(fnd_file.output, 'Order Number : ' || i.order_number);
          fnd_file.put_line(fnd_file.output, 'From  Org    : ' || i.frm_org_code);
          fnd_file.put_line(fnd_file.output, 'To    Org    : ' || i.to_org_code);
          fnd_file.put_line(fnd_file.output, 'Please Check Log File for Error Message');
          l_err_cnt := l_err_cnt + 1;
        END;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Exception in Staging Table Insert: ' || g_err_msg);
        l_err_cnt := l_err_cnt + 1;
      END;
    END LOOP;
    l_req_id := fnd_global.conc_request_id;
    --fnd_file.put_line(fnd_file.OUTPUT,'l_req_id '||l_req_id);
    -- Insert Inter Org Transfer Data
    fnd_file.put_line(fnd_file.log, 'collecting inventory transfers between orgs');
    FOR j IN c_mtl_tran
    LOOP
      BEGIN
        BEGIN
          SELECT *
          INTO l_ship_net
          FROM mtl_shipping_network_view
          WHERE from_organization_code = j.frm_org
          AND to_organization_code = j.to_org
          AND attribute2 = '1'
          AND attribute3 IS NOT NULL;
          BEGIN
            SELECT hcas.cust_account_id
            INTO l_cust_id
            FROM hz_cust_acct_sites_all hcas,
              hz_cust_site_uses_all hcs
            WHERE hcs.site_use_id = l_ship_net.attribute4
            AND hcas.cust_acct_site_id = hcs.cust_acct_site_id;
          EXCEPTION
          WHEN OTHERS THEN
            g_err_msg := 'Error Deriving Customer ID';
            raise;
          END;
          IF j.actual_cost IS NULL THEN
            BEGIN
              l_item_cost := cst_cost_api.get_item_cost(p_api_version => 1.0 , p_inventory_item_id => j.inventory_item_id , p_organization_id =>
              j.from_org_id);
            EXCEPTION
            WHEN OTHERS THEN
              g_err_msg := 'Error Deriving Item Cost ';
              raise;
            END;
          ELSE
            l_item_cost:=j.actual_cost;
          END IF;
          g_err_msg := 'Error While calculating transfer price (cost*markup from shipping network)';
          BEGIN
            l_transfer_price:=l_item_cost*l_ship_net.attribute13;
          EXCEPTION
          WHEN OTHERS THEN
            raise;
          END;
          g_err_msg := 'Error While Inserting Data into Staging Table';
          INSERT
          INTO xx_ont_interco_staging
            (
              source ,
              request_id ,
              source_ref_id ,
              tran_date ,
              order_type ,
              batch_id ,
              inventory_item_id ,
              ordered_qty ,
              unit_selling_price ,
              curr ,
              pricelist_id ,
              item_cost ,
              item_uom ,
              from_org_code ,
              to_org_code ,
              from_org_id ,
              to_org_id ,
              from_ou ,
              to_ou ,
              cust_id ,
              cust_bill_site_id ,
              supp_id ,
              supp_pay_site_id ,
              created_by ,
              creation_date ,
              last_updated_by ,
              last_update_date ,
              mtl_transaction_id,
              transfer_price,
              fair_market_price,
              trf_price_markup,
              return_category_code
            )
            VALUES
            (
              j.source,
              l_req_id,
              j.source_ref_id,
              j.tran_date,
              j.order_type,
              g_batch_id,
              j.inventory_item_id,
              j.ordered_qty ,
              ROUND(NVL(j.actual_cost,l_item_cost), 2),
              j.currency_code,
              l_ship_net.pricelist_id,
              j.actual_cost,
              j.item_uom ,
              j.frm_org,
              j.to_org ,
              j.from_org_id,
              j.to_org_id,
              j.from_ou,
              j.to_ou,
              l_cust_id,
              l_ship_net.attribute4,
              l_ship_net.attribute5 ,
              l_ship_net.attribute6,
              fnd_global.user_id ,
              sysdate,
              fnd_global.user_id,
              sysdate,
              j.source_ref_id,
              l_transfer_price,
              l_transfer_price,
              l_ship_net.attribute13,
              'ORDER'
            );
          UPDATE mtl_material_transactions
          SET transfer_price = l_transfer_price,
            attribute15='Y'
          WHERE transaction_id =j.source_ref_id;
          l_ins_cnt := l_ins_cnt + 1;
          fnd_file.put_line(fnd_file.output, ' ');
          fnd_file.put_line(fnd_file.output, '***** PROCESSED ***** ');
          fnd_file.put_line(fnd_file.output, 'Type           : ' || j.source);
          fnd_file.put_line(fnd_file.output, 'Transaction ID : ' || j.source_ref_id);
          fnd_file.put_line(fnd_file.output, 'From  Org      : ' || j.frm_org);
          fnd_file.put_line(fnd_file.output, 'To    Org      : ' || j.to_org);
        EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Exception for MTL Transaction: ' || j.source_ref_id || ' Error Msg. ' || g_err_msg );
          fnd_file.put_line(fnd_file.output, '***** ERROR ***** ');
          fnd_file.put_line(fnd_file.output, 'Type           : ' || j.source);
          fnd_file.put_line(fnd_file.output, 'Transaction ID : ' || j.source_ref_id);
          fnd_file.put_line(fnd_file.output, 'From  Org      : ' || j.frm_org);
          fnd_file.put_line(fnd_file.output, 'To    Org      : ' || j.to_org);
          fnd_file.put_line(fnd_file.output, 'Please Check Log File for Error Message');
          l_err_cnt := l_err_cnt + 1;
        END;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Exception for MTL Transaction: ' || j.source_ref_id || ' Error Msg. ' || g_err_msg ) ;
        l_err_cnt := l_err_cnt + 1;
      END;
    END LOOP;
    fnd_file.put_line(fnd_file.log, 'Rows Successfully Inserted: ' || l_ins_cnt);
    fnd_file.put_line(fnd_file.log, 'Rows Error Out            : ' || l_err_cnt);
    IF l_err_cnt >= 1 THEN
      x_retcode := 1;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Unhandled Exception in Staging Table Insert: ' || sqlerrm);
    x_retcode := 2;
  END insert_staging;
END xx_ont_interco_inv_pkg;
/
