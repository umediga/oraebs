DROP PACKAGE BODY APPS.INTG_IC_PRICING_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."INTG_IC_PRICING_PKG" 
AS
  /* $Header: XXINVICINVOICING_R2R_EXT_161.pls  3.0 2014/03/18 05:41:10 nuppara noship $ */
  PROCEDURE print_log(
      p_message IN VARCHAR2)
  IS
  BEGIN
    fnd_file.put_line(fnd_file.log, p_message);
    --dbms_output.put_line(p_message);
  END;
  FUNCTION get_transfer_price(
      i_transaction_id IN NUMBER ,
      i_price_list_id IN NUMBER ,
      i_sell_ou_id IN NUMBER ,
      i_ship_ou_id IN NUMBER ,
      o_currency_code OUT nocopy VARCHAR2 ,
      x_return_status OUT nocopy VARCHAR2 ,
      x_msg_count OUT nocopy     NUMBER ,
      x_msg_data OUT nocopy      VARCHAR2 ,
      i_order_line_id IN NUMBER DEFAULT NULL)
    RETURN NUMBER
  IS
    l_ic_rate_type         VARCHAR2(100);
    l_dest_currency_code   VARCHAR2(10);
    l_src_currency_code    VARCHAR2(10);
    l_ship_from_org_id     NUMBER;
    l_item_id              NUMBER;
    l_trf_price_type       NUMBER;
    l_trf_price            NUMBER;
    l_converted_amount     NUMBER;
    l_denominator          NUMBER;
    l_numerator            NUMBER;
    l_rate                 NUMBER;
    l_order_source         NUMBER;
    l_req_line_id          NUMBER;
    l_dest_organization_id NUMBER;
  BEGIN
    fnd_file.put_line(fnd_file.log, 'INTG:Enter intg_ic_pricing_pkg.get_transfer_price');
    l_ic_rate_type := fnd_profile.value('IC_CURRENCY_CONVERSION_TYPE');
    fnd_file.put_line(fnd_file.log, 'INTG: Profile value INV: Currency Conversion Rate Type for Intercompany: ' || l_ic_rate_type);
    SELECT currency_code
    INTO l_dest_currency_code
    FROM hr_operating_units a,
      gl_ledgers b
    WHERE a.set_of_books_id = b.ledger_id
    AND a.organization_id = i_sell_ou_id;
    fnd_file.put_line(fnd_file.log, 'INTG: Currency Code of the Selling OU: ' || l_dest_currency_code);
    SELECT a.transactional_curr_code,
      b.ship_from_org_id,
      inventory_item_id,
      b.order_source_id
    INTO l_src_currency_code,
      l_ship_from_org_id,
      l_item_id,
      l_order_source
    FROM oe_order_headers_all a,
      oe_order_lines_all b
    WHERE a.header_id = b.header_id
    AND b.line_id = i_order_line_id;
    fnd_file.put_line(fnd_file.log, 'INTG: Order Currency Code: ' || l_src_currency_code);
    fnd_file.put_line(fnd_file.log, 'INTG: Ship From Organization ID: ' || l_ship_from_org_id);
    fnd_file.put_line(fnd_file.log, 'INTG: Order Source : ' || l_order_source);
    IF l_order_source = 10 THEN
      SELECT source_document_line_id
      INTO l_req_line_id
      FROM oe_order_lines_all
      WHERE line_id = i_order_line_id;
      fnd_file.put_line(fnd_file.log, 'INTG: Requisition Line ID : ' || l_req_line_id);
      SELECT destination_organization_id
      INTO l_dest_organization_id
      FROM po_requisition_lines_all
      WHERE requisition_line_id = l_req_line_id;
      fnd_file.put_line(fnd_file.log, 'INTG: Destination Organization in Requisition Line ID : ' || l_dest_organization_id);
    END IF;
    SELECT cost_type_id
    INTO l_trf_price_type
    FROM cst_cost_types
    WHERE DECODE(organization_id, NULL, -10, organization_id) = DECODE(organization_id, NULL, -10, l_dest_organization_id)
    AND attribute1 = 'TRFPRICEACROSSOU'
    AND TRUNC(sysdate) BETWEEN NVL(fnd_date.canonical_to_date(attribute2), TRUNC(sysdate)) AND NVL(fnd_date.canonical_to_date(attribute3), TRUNC(
      sysdate));
    fnd_file.put_line(fnd_file.log, 'INTG: Cost Type ID for Transfer Between OUs : ' || l_trf_price_type);
    l_trf_price := cst_cost_api.get_item_cost(p_api_version => 1.0 , p_inventory_item_id => l_item_id , p_organization_id => l_dest_organization_id ,
    p_cost_group_id => NULL , p_cost_type_id => l_trf_price_type , p_precision => 2);
    fnd_file.put_line(fnd_file.log, 'INTG: Transfer Price in Cost type Setup : ' || l_trf_price);
    fnd_file.put_line(fnd_file.log, 'INTG: gl_currency_api.convert_closest_amount');
    fnd_file.put_line(fnd_file.log, 'INTG: gl_currency_api.convert_closest_amount Parameters');
    fnd_file.put_line(fnd_file.log, 'INTG: x_from_currency :' || l_dest_currency_code);
    fnd_file.put_line(fnd_file.log, 'INTG: x_to_currency :' || l_src_currency_code);
    fnd_file.put_line(fnd_file.log, 'INTG: x_conversion_type :' || l_ic_rate_type);
    fnd_file.put_line(fnd_file.log, 'INTG: x_conversion_date :' || sysdate);
    gl_currency_api.convert_closest_amount(x_from_currency => l_dest_currency_code , x_to_currency => l_src_currency_code , x_conversion_date =>
    TRUNC(sysdate) , x_conversion_type => l_ic_rate_type , x_amount => l_trf_price , x_user_rate => NULL , x_max_roll_days => -1 , x_converted_amount
    => l_converted_amount , x_denominator => l_denominator , x_numerator => l_numerator , x_rate => l_rate);
    o_currency_code := l_src_currency_code;
    fnd_file.put_line(fnd_file.log, 'INTG: Coversion Rate (x_rate) :' || l_rate);
    x_return_status := fnd_api.g_ret_sts_success;
    RETURN l_converted_amount;
  EXCEPTION
  WHEN OTHERS THEN
    x_return_status := fnd_api.g_ret_sts_error;
    x_msg_data := 'Error From Integra Custom Code';
    x_msg_count := 1;
    fnd_file.put_line(fnd_file.log, 'INTG: Error From Integra Custom Code in getting Transfer Price');
    RETURN (NULL);
  END;
  FUNCTION get_int_transfer_price(
      p_transaction_id IN NUMBER ,
      p_organization_id IN NUMBER ,
      p_inventory_item_id IN NUMBER ,
      x_return_status OUT nocopy VARCHAR2 ,
      x_msg_data OUT nocopy      VARCHAR2 ,
      x_msg_count OUT nocopy     NUMBER)
    RETURN NUMBER
  IS
    l_ic_rate_type         VARCHAR2(100);
    l_dest_currency_code   VARCHAR2(10);
    l_src_currency_code    VARCHAR2(10);
    l_ship_from_org_id     NUMBER;
    l_item_id              NUMBER;
    l_trf_price_type       NUMBER;
    l_trf_price            NUMBER;
    l_converted_amount     NUMBER;
    l_denominator          NUMBER;
    l_numerator            NUMBER;
    l_rate                 NUMBER;
    l_order_source         NUMBER;
    l_req_line_id          NUMBER;
    l_dest_organization_id NUMBER;
  BEGIN
    SELECT cost_type_id
    INTO l_trf_price_type
    FROM cst_cost_types
    WHERE DECODE(organization_id, NULL, -10, organization_id) = DECODE(organization_id, NULL, -10, p_organization_id)
    AND attribute1 = 'TRFPRICEWITHINOU'
    AND TRUNC(sysdate) BETWEEN NVL(fnd_date.canonical_to_date(attribute2), TRUNC(sysdate)) AND NVL(fnd_date.canonical_to_date(attribute3), TRUNC(
      sysdate));
    l_trf_price := cst_cost_api.get_item_cost(p_api_version => 1.0 , p_inventory_item_id => p_inventory_item_id , p_organization_id =>
    p_organization_id , p_cost_type_id => l_trf_price_type);
    x_return_status := fnd_api.g_ret_sts_success;
    x_msg_count := 0;
    RETURN l_trf_price;
  EXCEPTION
  WHEN OTHERS THEN
    x_return_status := fnd_api.g_ret_sts_error;
    x_msg_data := 'Error From Integra Custom Code in getting transfer price from cost type';
    x_msg_count := 1;
    RETURN (NULL);
  END;
/******************************************************************************
-- Filename:  XXINVICINVOICING.pkb
-- RICEW Object id : R2R-EXT_161
-- Purpose :  Package Body for Intercompany Partner Updates
-- Called from mtl_intercompany_invoices.callback
-- transaction_id for which intercompany invoice is being created is passed
-- as parameter
-- Usage: PL/SQL procedure
-- Logic:
-- When there are two companies (two different company names and
-- Balancing segments) have intercompany transaction flows with other
-- Intercompany this is requried.
_ _ _ _ _ Sea Spine (ILS Mfg OU)
|
|
-- Ex: OU Germany |
|
|_ _ _ _ _ _ Ascension (ILS Mfg OU)
-- In the above example between OU Germany and ILS Mfg OU only one customer
-- can be captured in intercompany trx flows. But based on the transaction between
-- Org 401 to Org 121 Customer should be Ascension
-- When transaction is between 401 and 112 then it should be Sea Spine
-- This is configured in the shipping networks (DFFs).
-- This procedure takes it from there and updates ra_interface_lines_all table.
-- This all happens in one call as part of the Create Intercompany AR invoices
-- and there is no need for a seperate program.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  28-Dec-2013  NUPPARA            Created
--
--
******************************************************************************/
  PROCEDURE update_customer(
      p_transaction_id IN NUMBER)
  IS
    l_ship_inv_org_id   NUMBER;
    l_sell_inv_org_id   NUMBER;
    l_cust_account_id   NUMBER;
    x_cust_acct_site_id NUMBER;
    x_site_use_id       NUMBER;
    x_msg_data          VARCHAR2(4000);
    l_interorg_params mtl_interorg_parameters%rowtype;
    l_salesrep_id NUMBER;
    is_117_item   VARCHAR2(1);
    l_inv_item_id NUMBER;
    l_glb_count number;
    CURSOR c1
    IS
      SELECT *
      FROM ra_interface_lines_all
      WHERE interface_line_context IN ('GLOBAL_PROCUREMENT', 'INTERCOMPANY')
      AND interface_line_attribute7 = p_transaction_id
      AND NVL(interface_status, '~') <> 'P';
    CURSOR network_params(p_from_organization_id IN NUMBER, p_to_organization_id IN NUMBER)
    IS
      SELECT *
      FROM mtl_interorg_parameters
      WHERE from_organization_id = p_from_organization_id
      AND to_organization_id = p_to_organization_id;
  BEGIN
    print_log('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
    print_log('INTG: Messages start for: ' || p_transaction_id);
    l_ship_inv_org_id := -1;
    l_sell_inv_org_id := -1;
    SELECT organization_id,
      transfer_organization_id,
      inventory_item_id
    INTO l_ship_inv_org_id,
      l_sell_inv_org_id,
      l_inv_item_id
    FROM mtl_material_transactions
    WHERE transaction_id = p_transaction_id;
    print_log('INTG:Shipping From Inventory Org: ' || l_ship_inv_org_id);
    print_log('INTG:Shipping To Inventory Org: ' || l_sell_inv_org_id);
    l_glb_count:=0;
    begin
    select count(*)
    into l_glb_count
    from ra_interface_lines_all
    where interface_line_attribute7=p_transaction_id
    and NVL(interface_status, '~') <> 'P'
    and interface_line_context='GLOBAL_PROCUREMENT'
    and org_id =
              (SELECT organization_id
              FROM hr_operating_units
              WHERE name = 'ILS Corporation'
              );
    exception when others then
    l_glb_count:=0;
    end;
    BEGIN
      is_117_item := xx_xla_custom_sources_pkg.is_117_approved_supp_list(l_inv_item_id);
      IF is_117_item = 'Y' and l_glb_count>0 then
        SELECT organization_id
        INTO l_sell_inv_org_id
        FROM mtl_parameters
        WHERE organization_code = '117';
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
    OPEN network_params(l_ship_inv_org_id, l_sell_inv_org_id);
    FETCH network_params INTO l_interorg_params;
    FOR i IN c1
    LOOP
      print_log('INTG: Customer from Transaction Flows: ' || i.orig_system_bill_customer_id);
      print_log('INTG: Customer Site ID from Transaction Flows: ' || i.orig_system_bill_address_id);
      print_log('INTG: AR Transaction Type ID: ');
      IF i.inventory_item_id IS NOT NULL THEN
        is_117_item := xx_xla_custom_sources_pkg.is_117_approved_supp_list(i.inventory_item_id);
        IF is_117_item = 'Y' and l_glb_count>0 THEN
          UPDATE ra_interface_lines_all
          SET cust_trx_type_id =
            (SELECT cust_trx_type_id
            FROM ra_cust_trx_types_all
            WHERE name = 'JJamner-Intercompany'
            AND org_id =
              (SELECT organization_id
              FROM hr_operating_units
              WHERE name = 'ILS Corporation'
              )
            )
          WHERE NVL(interface_status, '~') <> 'P'
          AND interface_line_context = 'GLOBAL_PROCUREMENT'
          AND interface_line_attribute7 = p_transaction_id;
        END IF;
      END IF;
    END LOOP;
    BEGIN
      SELECT MAX(cust_account_id)
      INTO l_cust_account_id
      FROM hz_cust_accounts
      WHERE party_id =
        (SELECT party_id
        FROM hz_parties
        WHERE party_name = l_interorg_params.attribute3
        );
    EXCEPTION
    WHEN OTHERS THEN
      l_cust_account_id := NULL;
    END;
    print_log('INTG: Customer Name from Shipping Network: ' || l_interorg_params.attribute3);
    print_log('INTG: Customer number from Shipping Network: ' || l_cust_account_id);
    print_log('INTG: Customer Site Use ID from Shipping Network: ' || l_interorg_params.attribute4);
    BEGIN
      SELECT cust_acct_site_id
      INTO x_cust_acct_site_id
      FROM hz_cust_site_uses_all
      WHERE site_use_id = l_interorg_params.attribute4;
    EXCEPTION
    WHEN OTHERS THEN
      x_cust_acct_site_id:=NULL;
    END;
    print_log('INTG: Customer Acct Site ID from Shipping Network: ' || x_cust_acct_site_id);
    BEGIN
      SELECT NVL(primary_salesrep_id, -1)
      INTO l_salesrep_id
      FROM hz_cust_site_uses_all
      WHERE site_use_id = l_interorg_params.attribute4;
    EXCEPTION
    WHEN OTHERS THEN
      l_salesrep_id := -1;
    END;
    print_log('INTG: Salesrep ID from Customer Site Use ID: ' || l_salesrep_id);
    IF l_cust_account_id IS NOT NULL THEN
      UPDATE ra_interface_lines_all
      SET orig_system_bill_customer_id = l_cust_account_id ,
        orig_system_sold_customer_id = l_cust_account_id ,
        orig_system_bill_address_id = x_cust_acct_site_id ,
        paying_customer_id = l_cust_account_id ,
        paying_site_use_id = l_interorg_params.attribute4
      WHERE NVL(interface_status, '~') <> 'P'
      AND interface_line_context IN ('GLOBAL_PROCUREMENT', 'INTERCOMPANY')
      AND interface_line_attribute7 = p_transaction_id
      AND orig_system_bill_customer_id <> l_cust_account_id
      AND orig_system_bill_address_id <> x_cust_acct_site_id;
      UPDATE ra_interface_salescredits_all
      SET salesrep_id =
        CASE
          WHEN l_salesrep_id = -1
          THEN salesrep_id
          ELSE l_salesrep_id
        END
      WHERE NVL(interface_status, '~') <> 'P'
      AND interface_line_context IN ('GLOBAL_PROCUREMENT', 'INTERCOMPANY')
      AND interface_line_attribute7 = p_transaction_id;
      UPDATE ra_interface_lines_all
      SET primary_salesrep_id =
        CASE
          WHEN l_salesrep_id = -1
          THEN primary_salesrep_id
          ELSE l_salesrep_id
        END
      WHERE NVL(interface_status, '~') <> 'P'
      AND interface_line_context IN ('GLOBAL_PROCUREMENT', 'INTERCOMPANY')
      AND interface_line_attribute7 = p_transaction_id;
    END IF;
    print_log('INTG: Message End for: ' || p_transaction_id);
    print_log('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
    CLOSE network_params;
  EXCEPTION
  WHEN OTHERS THEN
    print_log('INTG: Exception in Updating Customers in RA_INTERFACE_LINES_ALL');
    print_log('INTG: Holding the record in the RA_INTERFACE_LINES_ALL for fix');
    UPDATE ra_interface_lines_all
    SET request_id = -999999
    WHERE NVL(interface_status, '~') <> 'P'
    AND interface_line_context = 'INTERCOMPANY'
    AND interface_line_attribute7 = p_transaction_id;
  END;
  FUNCTION build_accrual_acct(
      p_dist_account IN NUMBER,
      p_liability_acct IN NUMBER,
      p_org_id IN NUMBER,
      x_dist_acct OUT NUMBER)
    RETURN NUMBER
  IS
    l_flex_num        NUMBER;
    l_segment_num     NUMBER;
    l_segment_num_ic  NUMBER;
    l_segment_num_bs  NUMBER;
    l_ic_accrual_acct NUMBER;
    l_app_short_name  VARCHAR2(50);
    l_num_of_segs     NUMBER;
    l_segments fnd_flex_ext.segmentarray;
    l_intercompany_segment VARCHAR2(30);
    l_accrual_acct_segment VARCHAR2(30);
    l_flex_code            VARCHAR2(4) := 'GL#';
    l_return_status        VARCHAR2(1) := fnd_api.g_ret_sts_success;
    l_error_message        VARCHAR2(2000);
    x_return_status        VARCHAR2(1) := fnd_api.g_ret_sts_success;
    l_inv_txn_id           NUMBER;
    l_org_id               NUMBER;
    lreturn_status         VARCHAR2(1);
    lmsg_data              VARCHAR2(4000);
    lsob_id                NUMBER;
    l_company_segment      VARCHAR2(30);
    CURSOR fifs_acct_cur(l_flex_num IN NUMBER)
    IS
      SELECT fifs.segment_num
      FROM fnd_id_flex_segments fifs,
        fnd_segment_attribute_values fsav
      WHERE fifs.application_column_name = fsav.application_column_name
      AND fifs.id_flex_num = fsav.id_flex_num
      AND fifs.id_flex_code = fsav.id_flex_code
      AND fifs.application_id = fsav.application_id
      AND fsav.application_id = 101
      AND fsav.id_flex_code = 'GL#'
      AND fsav.id_flex_num = l_flex_num
      AND fsav.segment_attribute_type = 'GL_ACCOUNT'
      AND fsav.attribute_value = 'Y';
    CURSOR fifs_comp_cur(l_flex_num IN NUMBER)
    IS
      SELECT fifs.segment_num
      FROM fnd_id_flex_segments fifs,
        fnd_segment_attribute_values fsav
      WHERE fifs.application_column_name = fsav.application_column_name
      AND fifs.id_flex_num = fsav.id_flex_num
      AND fifs.id_flex_code = fsav.id_flex_code
      AND fifs.application_id = fsav.application_id
      AND fsav.application_id = 101
      AND fsav.id_flex_code = 'GL#'
      AND fsav.id_flex_num = l_flex_num
      AND fsav.segment_attribute_type = 'GL_BALANCING'
      AND fsav.attribute_value = 'Y';
    CURSOR fifs_intcomp_cur(l_flex_num IN NUMBER)
    IS
      SELECT fifs.segment_num
      FROM fnd_id_flex_segments fifs,
        fnd_segment_attribute_values fsav
      WHERE fifs.application_column_name = fsav.application_column_name
      AND fifs.id_flex_num = fsav.id_flex_num
      AND fifs.id_flex_code = fsav.id_flex_code
      AND fifs.application_id = fsav.application_id
      AND fsav.application_id = 101
      AND fsav.id_flex_code = 'GL#'
      AND fsav.id_flex_num = l_flex_num
      AND fsav.segment_attribute_type = 'GL_INTERCOMPANY'
      AND fsav.attribute_value = 'Y';
    CURSOR fnd_application_cur
    IS
      SELECT application_short_name FROM fnd_application WHERE application_id = 101;
  BEGIN
    x_return_status := fnd_api.g_ret_sts_success;
    l_org_id := p_org_id;
    x_dist_acct := p_dist_account;
    inv_globals.get_ledger_info(x_return_status => lreturn_status , x_msg_data => lmsg_data , p_context_type => 'Operating Unit Information' ,
    p_org_id => p_org_id , x_sob_id => lsob_id , x_coa_id => l_flex_num , p_account_info_context => 'BOTH');
    print_log('l_flex_num is :' || l_flex_num);
    OPEN fifs_comp_cur(l_flex_num);
    FETCH fifs_comp_cur INTO l_segment_num_bs;
    CLOSE fifs_comp_cur;
    print_log('Company Segment Number is :' || l_segment_num_bs);
    OPEN fifs_acct_cur(l_flex_num);
    FETCH fifs_acct_cur INTO l_segment_num;
    CLOSE fifs_acct_cur;
    print_log('Account Segment Number is :' || l_segment_num);
    OPEN fifs_intcomp_cur(l_flex_num);
    FETCH fifs_intcomp_cur INTO l_segment_num_ic;
    CLOSE fifs_intcomp_cur;
    print_log('Intercompany Segment Number is :' || l_segment_num_ic);
    BEGIN
      SELECT segment7,
        segment1
      INTO l_intercompany_segment,
        l_company_segment
      FROM gl_code_combinations
      WHERE code_combination_id = p_liability_acct;
      print_log('IC Segment from Invoice liability account :' || l_intercompany_segment);
      print_log('Company Segment for Liability Account: ' || l_company_segment);
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
    l_accrual_acct_segment := '216300';
    print_log('IC Accual Account Segment is :' || l_accrual_acct_segment);
    OPEN fnd_application_cur;
    FETCH fnd_application_cur INTO l_app_short_name;
    CLOSE fnd_application_cur;
    IF fnd_flex_ext.get_segments(application_short_name => l_app_short_name , key_flex_code => l_flex_code , structure_number => l_flex_num ,
      combination_id => p_dist_account , n_segments => l_num_of_segs , segments => l_segments) THEN
      l_segments(l_segment_num) := l_accrual_acct_segment;
      l_segments(l_segment_num_ic) := l_intercompany_segment;
      --if l_company_segment = '114' then
      --l_segments(l_segment_num_bs) := l_company_segment;
      --end if;
      IF fnd_flex_ext.get_combination_id(application_short_name => l_app_short_name , key_flex_code => l_flex_code , structure_number => l_flex_num ,
        validation_date => sysdate , n_segments => l_num_of_segs , segments => l_segments , combination_id => l_ic_accrual_acct) THEN
        print_log('New IC Accrual CCID is :' || l_ic_accrual_acct);
        IF l_ic_accrual_acct IS NULL OR l_ic_accrual_acct = -1 THEN
          print_log('New IC Accrual CCID is :' || l_ic_accrual_acct);
          RETURN NULL;
        ELSE
          print_log('New IC Accrual CCID is :' || l_ic_accrual_acct);
          x_dist_acct := l_ic_accrual_acct;
          RETURN l_ic_accrual_acct;
        END IF;
      ELSE
        RETURN NULL;
      END IF;
    ELSE
      RETURN NULL;
    END IF;
    IF l_ic_accrual_acct IS NULL THEN
      RETURN NULL;
    END IF;
  EXCEPTION
  WHEN fnd_api.g_exc_error THEN
    x_return_status := fnd_api.g_ret_sts_error;
    RETURN NULL;
  END build_accrual_acct;
  PROCEDURE update_supplier(
      p_invoice_id IN NUMBER)
  IS
    result            BOOLEAN;
    x_msg_data        VARCHAR2(4000);
    x_vendor_id       NUMBER;
    x_pay_site_id     NUMBER;
    x_ship_inv_org_id NUMBER;
    x_sell_inv_org_id NUMBER;
    x_ship_le_id      NUMBER;
    x_ship_le_name    VARCHAR2(100);
    x_ship_ou_id      NUMBER;
    x_sell_ou_id      NUMBER;
    l_customer_trx_id NUMBER;
    l_sell_le_id      NUMBER;
    l_supplier_result NUMBER;
    l_vendor_id       NUMBER;
    l_vendor_site_id  NUMBER;
    l_liability_acct  NUMBER;
    l_intf_liab_acct  NUMBER;
    l_org_id          NUMBER;
    x_dist_acct       NUMBER;
    l_new_dist_acct   NUMBER;
    l_interorg_params mtl_interorg_parameters%rowtype;
    l_cust_trx_type VARCHAR2(30);
    CURSOR network_params(p_from_organization_id IN NUMBER, p_to_organization_id IN NUMBER)
    IS
      SELECT *
      FROM mtl_interorg_parameters
      WHERE from_organization_id = p_from_organization_id
      AND to_organization_id = p_to_organization_id;
  BEGIN
    print_log('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
    print_log('INTG: Messages Start');
    print_log('INTG: Processing invoice_id: ' || p_invoice_id);
    SELECT reference_1,
      legal_entity_id,
      vendor_id,
      vendor_site_id,
      accts_pay_code_combination_id,
      org_id
    INTO l_customer_trx_id,
      l_sell_le_id,
      l_vendor_id,
      l_vendor_site_id,
      l_intf_liab_acct,
      l_org_id
    FROM ap_invoices_interface
    WHERE invoice_id = p_invoice_id;
    print_log('INTG: Customer TRX ID : ' || l_customer_trx_id);
    print_log('INTG: Selling LE ID : ' || l_sell_le_id);
    print_log('INTG: Original Vendor ID : ' || l_vendor_id);
    print_log('INTG: Original Vendor Site ID : ' || l_vendor_site_id);
    x_ship_inv_org_id := -1;
    x_sell_inv_org_id := -1;
    SELECT MAX(organization_id),
      MAX(transfer_organization_id)
    INTO x_ship_inv_org_id,
      x_sell_inv_org_id
    FROM mtl_material_transactions
    WHERE transaction_id IN
      (SELECT b.interface_header_attribute7
      FROM ap_invoices_interface a,
        ra_customer_trx_all b
      WHERE invoice_id = p_invoice_id
      AND a.reference_1 = b.customer_trx_id
      );
    -- intercept for the 117 changes. Check if the AR transaction type is JJamner-Intercompany on AR Invoice
    -- if it is then change the transfer organization_id to 117 organization to get the shipping network
    -- which gets us the correct supplier.
    BEGIN
      SELECT name
      INTO l_cust_trx_type
      FROM ra_cust_trx_types_all a,
        ra_customer_trx_all b
      WHERE b.customer_trx_id = l_customer_trx_id
      AND a.cust_trx_type_id = b.cust_trx_type_id
      AND a.org_id = b.org_id;
      IF l_cust_trx_type = 'JJamner-Intercompany' THEN
        SELECT organization_id
        INTO x_ship_inv_org_id
        FROM mtl_parameters
        WHERE organization_code = '117';
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
    print_log('INTG:Shipping From Inventory Org: ' || x_ship_inv_org_id);
    print_log('INTG:Shipping To Inventory Org: ' || x_sell_inv_org_id);
    OPEN network_params(x_ship_inv_org_id, x_sell_inv_org_id);
    FETCH network_params INTO l_interorg_params;
    CLOSE network_params;
    print_log('INTG:Supplier ID from shipping network: ' || l_interorg_params.attribute5);
    print_log('INTG:Supplier Site ID from shipping network: ' || l_interorg_params.attribute6);
    x_vendor_id := l_interorg_params.attribute5;
    x_pay_site_id := l_interorg_params.attribute6;
    IF x_vendor_id IS NOT NULL THEN
      IF x_pay_site_id IS NOT NULL THEN
        IF (x_vendor_id <> l_vendor_id OR x_pay_site_id <> l_vendor_site_id) THEN
          print_log('INTG: Vendor or Vendor Site ID is different. Updating the AP_INVOICES_INTERFACE');
          UPDATE ap_invoices_interface a
          SET
            (
              vendor_id ,
              vendor_site_code ,
              vendor_site_id ,
              accts_pay_code_combination_id
            )
            =
            (SELECT x_vendor_id,
              povs.vendor_site_code,
              x_pay_site_id ,
              povs.accts_pay_code_combination_id
            FROM po_vendor_sites_all povs,
              po_vendors pov
            WHERE pov.vendor_id = x_vendor_id
            AND povs.vendor_id = pov.vendor_id
            AND povs.vendor_site_id = x_pay_site_id
            AND povs.org_id = a.org_id
            AND NVL(TRUNC(povs.inactive_date), TRUNC(sysdate)) >= TRUNC(sysdate)
            )
          WHERE invoice_id = p_invoice_id;
        ELSE
          print_log('INTG: Vendor and Vendor Site ID are the same. Skipping Update.');
        END IF;
      END IF;
    END IF;
    print_log('INTG Messages End');
    print_log('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
  EXCEPTION
  WHEN OTHERS THEN
    print_log('INTG: Exception in Updating Vendor in AP_INVOICE_INTERFACE');
    NULL;
  END;
  PROCEDURE update_ic_accrual_acct(
      p_invoice_id IN NUMBER,
      p_cust_trx_line_id IN NUMBER)
  IS
    l_liability_acct           NUMBER;
    l_intf_liab_acct           NUMBER;
    l_org_id                   NUMBER;
    x_dist_acct                NUMBER;
    l_new_dist_acct            NUMBER;
    l_dist_code_combination_id NUMBER;
  BEGIN
    print_log('$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
    print_log('INTG: Messages Start');
    print_log('INTG: Processing invoice_id: ' || p_invoice_id);
    print_log('INTG: Processing p_cust_trx_line_id: ' || p_cust_trx_line_id);
    BEGIN
      SELECT accts_pay_code_combination_id,
        org_id
      INTO l_intf_liab_acct,
        l_org_id
      FROM ap_invoices_interface
      WHERE invoice_id = p_invoice_id;
      SELECT DISTINCT dist_code_combination_id
      INTO l_dist_code_combination_id
      FROM ap_invoice_lines_interface
      WHERE invoice_id = p_invoice_id
      AND reference_1 = p_cust_trx_line_id;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
    print_log('INTG: Interface Liability account: ' || l_intf_liab_acct);
    print_log('INTG: Interface IC Accrual account: ' || l_dist_code_combination_id);
    IF (l_dist_code_combination_id IS NOT NULL AND l_intf_liab_acct IS NOT NULL) THEN
      l_new_dist_acct := build_accrual_acct(p_dist_account => l_dist_code_combination_id , p_liability_acct => l_intf_liab_acct , p_org_id =>
      l_org_id , x_dist_acct => x_dist_acct);
      print_log('INTG: New IC Accrual account: ' || l_new_dist_acct);
      IF l_new_dist_acct IS NOT NULL THEN
        print_log('INTG : Updating IC Accrual Account');
        UPDATE ap_invoice_lines_interface
        SET dist_code_combination_id = l_new_dist_acct
        WHERE invoice_id = p_invoice_id
        AND dist_code_combination_id <> l_new_dist_acct
        AND dist_code_combination_id = l_dist_code_combination_id
        AND reference_1 = p_cust_trx_line_id;
      END IF;
    END IF;
  END;
  FUNCTION get_item_cost(
      p_inventory_item_id IN NUMBER,
      p_organization_id IN NUMBER)
    RETURN NUMBER
  IS
    l_cost NUMBER;
  BEGIN
    SELECT item_cost
    INTO l_cost
    FROM cst_item_costs
    WHERE inventory_item_id = p_inventory_item_id
    AND organization_id = p_organization_id
    AND cost_type_id = 1;
    RETURN ROUND(l_cost, 2);
  EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
  END;
  FUNCTION get_profit_inv_acct(
      p_from_organization_id IN NUMBER,
      p_to_organization_id IN NUMBER)
    RETURN NUMBER
  IS
    l_profit_in_inv_acct NUMBER;
  BEGIN
    SELECT profit_in_inv_account
    INTO l_profit_in_inv_acct
    FROM mtl_interorg_parameters
    WHERE from_organization_id = p_from_organization_id
    AND to_organization_id = p_to_organization_id;
    RETURN l_profit_in_inv_acct;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN -1;
  END;
  FUNCTION get_sequence
    RETURN NUMBER
  IS
    l_inv_sub_ledger_id NUMBER;
  BEGIN
    SELECT cst_inv_sub_ledger_id_s.nextval INTO l_inv_sub_ledger_id FROM dual;
    RETURN l_inv_sub_ledger_id;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
  END;
  FUNCTION check_cogs_percentage(
      p_transaction_id IN NUMBER)
    RETURN NUMBER
  IS
    l_result NUMBER;
  BEGIN
    l_result := 0;
    SELECT cogs.cogs_percentage
    INTO l_result
    FROM cst_cogs_events def_cogs,
      mtl_material_transactions def_cogs_mmt,
      cst_cogs_events cogs,
      mtl_material_transactions cogs_mmt
    WHERE cogs_mmt.transaction_id = p_transaction_id
    AND cogs_mmt.transaction_id = cogs.mmt_transaction_id
    AND cogs_mmt.transaction_type_id = 10008
    AND cogs.event_type = 3
    AND cogs.cogs_percentage <> 0
    AND cogs.prior_event_id = def_cogs.event_id
    AND def_cogs.mmt_transaction_id = def_cogs_mmt.transaction_id
    AND def_cogs.event_type = 1
    AND def_cogs.cogs_percentage = 0
    AND def_cogs_mmt.transaction_type_id = 30;
    RETURN l_result;
  EXCEPTION
  WHEN OTHERS THEN
    l_result := 0;
    RETURN l_result;
  END;
  FUNCTION check_cogs_recognition(
      p_transaction_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_result VARCHAR2(10);
  BEGIN
    l_result := 'N';
    SELECT 'Y'
    INTO l_result
    FROM cst_cogs_events def_cogs,
      mtl_material_transactions def_cogs_mmt,
      cst_cogs_events cogs,
      mtl_material_transactions cogs_mmt
    WHERE cogs_mmt.transaction_id = p_transaction_id
    AND cogs_mmt.transaction_id = cogs.mmt_transaction_id
    AND cogs_mmt.transaction_type_id = 10008
    AND cogs.event_type = 3
    AND cogs.cogs_percentage <> 0
    AND cogs.prior_event_id = def_cogs.event_id
    AND def_cogs.mmt_transaction_id = def_cogs_mmt.transaction_id
    AND def_cogs.event_type = 1
    AND def_cogs.cogs_percentage = 0
    AND def_cogs_mmt.transaction_type_id = 30;
    RETURN l_result;
  EXCEPTION
  WHEN OTHERS THEN
    l_result := 'N';
    RETURN l_result;
  END;
  FUNCTION get_profit_inv_acct(
      p_trf_organization_id IN NUMBER ,
      p_organization_id IN NUMBER ,
      p_trx_type_id IN NUMBER ,
      p_rcv_trx_id IN NUMBER)
    RETURN NUMBER
  IS
    l_profit_in_inv_acct  NUMBER;
    l_coa_id              NUMBER;
    l_delimiter           VARCHAR2(1);
    l_company             VARCHAR2(30);
    l_department          VARCHAR2(30);
    l_account             VARCHAR2(30);
    l_classification      VARCHAR2(30);
    l_region              VARCHAR2(30);
    l_product             VARCHAR2(30);
    l_intercompany        VARCHAR2(30) := '000';
    l_future              VARCHAR2(30) := '00000';
    l_concatenated_segs   VARCHAR2(500);
    l_ppv_account         NUMBER;
    x_eff_date            DATE := sysdate;
    l_supplier_type_check VARCHAR2(30);
    l_drop_ship_flag      VARCHAR2(1);
  BEGIN
    l_profit_in_inv_acct := NULL;
    BEGIN
      l_supplier_type_check := 'N';
      SELECT 'Y'
      INTO l_supplier_type_check
      FROM rcv_transactions b,
        po_headers_all c,
        po_vendors d
      WHERE b.transaction_id = p_rcv_trx_id
      AND b.po_header_id = c.po_header_id
      AND c.vendor_id = d.vendor_id
      AND source_document_code = 'PO'
      AND d.vendor_type_lookup_code = 'INTERCOMPANY';
    EXCEPTION
    WHEN OTHERS THEN
      l_supplier_type_check := 'N';
    END;
    IF p_trx_type_id IN (13, 10) THEN
      SELECT profit_in_inv_account
      INTO l_profit_in_inv_acct
      FROM mtl_interorg_parameters
      WHERE from_organization_id = p_trf_organization_id
      AND to_organization_id = p_organization_id;
    elsif p_trx_type_id IN (19, 39,69) THEN
      BEGIN
        SELECT NVL(drop_ship_flag, 'N')
        INTO l_drop_ship_flag
        FROM po_line_locations_all a,
          rcv_transactions b
        WHERE a.line_location_id = b.po_line_location_id
        AND b.transaction_id = p_rcv_trx_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_drop_ship_flag := 'N';
      END;
      BEGIN
        BEGIN
          SELECT purchase_price_var_account,
            chart_of_accounts_id,
            segment1,
            segment2,
            segment3,
            segment4,
            segment5,
            segment6,
            segment7 ,
            segment8
          INTO l_profit_in_inv_acct,
            l_coa_id,
            l_company,
            l_department,
            l_account,
            l_classification,
            l_product,
            l_region,
            l_intercompany ,
            l_future
          FROM mtl_parameters a,
            gl_code_combinations_kfv b
          WHERE organization_id = p_organization_id
          AND a.purchase_price_var_account = b.code_combination_id;
          print_log('INTG: PPV Account from Org: ' || l_profit_in_inv_acct);
        EXCEPTION
        WHEN OTHERS THEN
          l_profit_in_inv_acct := -1;
          --return -1;
        END;
        IF l_drop_ship_flag = 'N' THEN
          IF l_supplier_type_check = 'Y' THEN
            print_log('INTG: Intercompany Supplier Check Passed');
            BEGIN
              SELECT gl.segment1
              INTO l_intercompany
              FROM po_distributions_all pod,
                gl_code_combinations gl,
                rcv_transactions rcv
              WHERE pod.po_distribution_id = rcv.po_distribution_id
              AND pod.dest_charge_account_id = gl.code_combination_id
              AND rcv.transaction_id = p_rcv_trx_id;
            EXCEPTION
            WHEN OTHERS THEN
              l_intercompany := NULL;
            END;
            print_log('INTG: Intercompany Segment: ' || l_intercompany);
            print_log('INTG: Company Segment: ' || l_company);
            l_department := '9001';
            l_account := '419110';
            l_delimiter := fnd_flex_ext.get_delimiter('SQLGL', 'GL#', l_coa_id);
            l_concatenated_segs := l_company || l_delimiter || l_department || l_delimiter || l_account || l_delimiter || l_classification ||
            l_delimiter || l_product || l_delimiter || l_region || l_delimiter || l_intercompany || l_delimiter || l_future;
            print_log(l_concatenated_segs);
            l_profit_in_inv_acct := fnd_flex_ext.get_ccid('SQLGL' , 'GL#' , l_coa_id , TO_CHAR(x_eff_date, 'YYYY/MM/DD HH24:MI:SS') ,
            l_concatenated_segs);
            IF l_profit_in_inv_acct > 0 OR l_profit_in_inv_acct IS NOT NULL THEN
              print_log(l_profit_in_inv_acct);
              --return l_profit_in_inv_acct;
            END IF;
          END IF;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        print_log('INTG: In Exception');
        NULL;
        l_profit_in_inv_acct := -1;
        --return -1;
      END;
    END IF;
    print_log('INTG: PPV Account from Org: ' || l_profit_in_inv_acct);
    RETURN l_profit_in_inv_acct;
  EXCEPTION
  WHEN OTHERS THEN
    print_log('Exception in getting the PII Account');
    RETURN -1;
  END;
  FUNCTION get_entered_amount(
      p_transaction_id IN NUMBER,
      p_inventory_item_Id IN NUMBER,
      p_organization_id IN NUMBER,
      p_accounting_line_type IN NUMBER,
      p_entered_amount IN NUMBER,
      p_transaction_type_Id IN NUMBER,
      p_quantity IN NUMBER,
      P_base_amount IN NUMBER,
      p_currency IN VARCHAR2,
      p_rate IN NUMBER)
    RETURN NUMBER
  IS
    l_entered_amount     NUMBER;
    l_item_cost          NUMBER;
    l_currency_code      VARCHAR2(3);
    l_log_sales_check    NUMBER;
    l_trx_source_line_id NUMBER;
  BEGIN
    SELECT currency_code
    INTO l_currency_code
    FROM cst_organization_definitions
    WHERE organization_Id=p_organization_Id;
    l_log_sales_check:=0;
    l_trx_source_line_id:=NULL;
    BEGIN
      SELECT trx_source_line_id
      INTO l_trx_source_line_id
      FROM mtl_material_transactions
      WHERE transaction_id=p_transaction_id
      AND transaction_type_id in (10008,16);
      IF l_trx_source_line_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO l_log_sales_check
        FROM mtl_material_transactions
        WHERE trx_source_line_Id=l_trx_source_line_id
        AND transaction_type_Id IN (30,16);
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      l_log_sales_check:=0;
    END;
    l_item_cost:=NULL;
    l_item_cost := NVL(cst_cost_api.get_item_cost(1.0,p_inventory_item_Id,p_organization_Id,NULL,NULL,2),0);
    CASE
    WHEN (p_accounting_line_type = 1 AND p_transaction_type_Id IN (10, 13, 19, 39,69)) THEN
      IF NVL(p_currency,l_currency_code)<>l_currency_code THEN
        l_item_cost:=l_item_cost/p_rate;
        l_entered_amount:=ROUND((l_item_cost*p_quantity),2);
      elsif NVL(p_currency,l_currency_code)=l_currency_code THEN
        l_entered_amount:=ROUND((l_item_cost*p_quantity),2);
      END IF;
    WHEN p_transaction_type_Id IN (11,14,30) THEN
      l_entered_amount:=ROUND((l_item_cost*p_quantity),2);
    WHEN (l_log_sales_check>0 AND p_transaction_type_Id IN (10008)) THEN
      l_entered_amount:=ROUND((l_item_cost*p_quantity),2);
		WHEN (l_log_sales_check>0 AND p_accounting_line_type <>37 AND p_transaction_type_Id IN (16)) THEN
      l_entered_amount:=ROUND((l_item_cost*p_quantity),2);	
		WHEN (l_log_sales_check>0 AND p_accounting_line_type =37 AND p_transaction_type_Id IN (16)) THEN
      l_entered_amount:=0;		
    ELSE
      CASE
      WHEN (NVL(p_entered_amount,0)<> 0) THEN
        l_entered_amount :=p_entered_amount;
      ELSE
        l_entered_amount:=p_base_amount;
      END CASE;
    END CASE;
    RETURN l_entered_amount;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN p_entered_amount;
  END;
  FUNCTION get_functional_currency(
      p_organization_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_currency_code VARCHAR2(3);
  BEGIN
    SELECT currency_code
    INTO l_currency_code
    FROM cst_organization_definitions
    WHERE organization_Id=p_organization_Id;
    RETURN l_currency_code;
  END;
  FUNCTION get_functional_amount(
      p_transaction_id IN NUMBER,
      p_inventory_item_Id IN NUMBER,
      p_organization_id IN NUMBER,
      p_accounting_line_type IN NUMBER,
      p_transaction_type_Id IN NUMBER,
      p_quantity IN NUMBER,
      P_base_amount IN NUMBER)
    RETURN NUMBER
  IS
    l_functional_amount  NUMBER;
    l_item_cost          NUMBER;
    l_currency_code      VARCHAR2(3);
    l_log_sales_check    NUMBER;
    l_trx_source_line_id NUMBER;
  BEGIN
    l_item_cost:=NULL;
    l_item_cost := NVL(cst_cost_api.get_item_cost(1.0,p_inventory_item_Id,p_organization_Id,NULL,NULL,2),0);
    l_log_sales_check:=0;
    l_trx_source_line_id:=NULL;
    BEGIN
      SELECT trx_source_line_id
      INTO l_trx_source_line_id
      FROM mtl_material_transactions
      WHERE transaction_id=p_transaction_id
      AND transaction_type_id in (10008,16);
      IF l_trx_source_line_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO l_log_sales_check
        FROM mtl_material_transactions
        WHERE trx_source_line_Id=l_trx_source_line_id
        AND transaction_type_Id IN (30,16);
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      l_log_sales_check:=0;
    END;
    CASE
    WHEN (p_accounting_line_type = 1 AND p_transaction_type_Id IN (10, 13, 19,39,69)) THEN
      l_functional_amount:=ROUND((l_item_cost*p_quantity),2);
    WHEN p_transaction_type_Id IN (11,14,30) THEN
      l_functional_amount:=ROUND((l_item_cost*p_quantity),2);
    WHEN (l_log_sales_check>0 AND p_transaction_type_Id IN (10008)) THEN
      l_functional_amount:=ROUND((l_item_cost*p_quantity),2);
		WHEN (l_log_sales_check>0 AND p_accounting_line_type<>37 AND p_transaction_type_Id IN (16)) THEN
      l_functional_amount:=ROUND((l_item_cost*p_quantity),2);	
		WHEN (l_log_sales_check>0 AND p_accounting_line_type=37 AND p_transaction_type_Id IN (16)) THEN
      l_functional_amount:=0;		
    ELSE
      l_functional_amount:=p_base_amount;
    END CASE;
    RETURN l_functional_amount;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN p_base_amount;
  END get_functional_amount;
  FUNCTION get_ppv_amt(
      p_type IN VARCHAR2,
      p_transaction_id IN NUMBER,
      p_inventory_item_Id IN NUMBER,
      p_organization_id IN NUMBER,
      p_accounting_line_type IN NUMBER,
      p_entered_amount IN NUMBER,
      p_transaction_type_Id IN NUMBER,
      p_quantity IN NUMBER,
      P_base_amount IN NUMBER,
      p_currency IN VARCHAR2,
      p_rate IN NUMBER)
    RETURN NUMBER
  IS
    l_amount NUMBER;
  BEGIN
    CASE
    WHEN p_type='ENTERED' THEN
      l_amount:=NVL(p_entered_amount,p_base_amount)-get_entered_amount(p_transaction_id,p_inventory_item_Id, p_organization_id,p_accounting_line_type
      , p_entered_amount,p_transaction_type_Id,p_quantity, P_base_amount,p_currency,p_rate);
      l_amount:=ROUND(l_amount,2);
    WHEN p_type='ACCOUNTED' THEN
      l_amount:=p_base_amount-get_functional_amount(p_transaction_id,p_inventory_item_Id, p_organization_id,p_accounting_line_type,
      p_transaction_type_Id,p_quantity, P_base_amount);
      l_amount:=ROUND(l_amount,2);
    END CASE;
    RETURN l_amount;
  EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
  END;
END intg_ic_pricing_pkg;
/
