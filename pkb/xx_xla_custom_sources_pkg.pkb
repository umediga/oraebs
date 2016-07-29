DROP PACKAGE BODY APPS.XX_XLA_CUSTOM_SOURCES_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_XLA_CUSTOM_SOURCES_PKG" as
  g_master_organization_id number;
  g_category_set_id number;
  g_category_structure_id number;
  function get_item_product_line(p_customer_trx_id in number
                               , p_cust_trx_line_id in number
                               , p_iface_line_context in varchar2
                               , p_order_type in varchar2)
    return varchar2 is
    l_first_line number;
    l_item_id number;
    l_organization_id number;
    l_revenue_account number;
    l_prod_segment varchar2(30);
  -----------------------------------------------------------------------------
  -- Start of comments                                                       --
  --                                                                         --
  -- PROCEDURE                                                               --
  --  get_item_product_line This function is used in AR SLA Accounting       --
  -- setups for freight. This takes the following parameters                 --
  --                    1) Customer Trx ID                                   --
  --                    2) Customer_trx_line_id                              --
  --                    3) Interface Line Context                            --
  --                    5) Order type (Interface_line_attribute2)            --
  -- VERSION 1.0                                                             --
  --                                                                         --
  -- PARAMETERS                                                              --
  --                                                                         --
  --  P_CUSTOMER_TRX_ID         customer_trx_id                              --
  --  P_CUSTOMER_TRX_LINE_ID    customer_trx_line_id                         --
  --  P_IFACE_LINE_CONTEXT     Interface Line Context of the invoice         --
  --  P_ORDER_TYPE             Interface_line_attribute2(currently not used) --
  --  Logic:                                                                 --
  --  With the customer trx ID, derive product, organization                 --
  --  and the line_Id of the first line of the invoice with the line         --
  --  TYPE of LINE                                                           --
  --  get the revenue accoun't product line of that item from item master    --
  --  Function return that value. If it is null or exception occurs it return--
  --  null value                                                             --
  --  This is setup in custom sources of SLA                                 --
  -- HISTORY:                                                                --
  --    06/30/2012       Naga         Created                                --
  --    05/13/2015       Renga (NTT)  Modified for Seaspine                  --
  -- End of comments                                                         --
  -----------------------------------------------------------------------------
  begin
    select customer_trx_line_id, inventory_item_id, warehouse_id
    into   l_first_line, l_item_id, l_organization_id
    from   ra_customer_trx_lines_all
    where      customer_trx_id = p_customer_trx_id
           and line_type = 'LINE'
           and line_number = (select min(line_number)
                              from   ra_customer_trx_lines_all
                              where  customer_trx_id = p_customer_trx_id and line_type = 'LINE' and inventory_item_id is not null);
    select sales_account
    into   l_revenue_account
    from   mtl_system_items_b
    where  inventory_item_id = l_item_id
           and organization_id = nvl(l_organization_id, (select min(master_organization_id) from mtl_parameters));
    select segment5
    into   l_prod_segment
    from   gl_code_combinations_kfv
    where  code_combination_id = l_revenue_account;
    return l_prod_segment;
  exception
    when others then
      return null;
  end;
  -----------------------------------------------------------------------------
  -- Start of comments                                                       --
  --                                                                         --
  -- PROCEDURE                                                               --
  --  get_vendor_type  This function is used in AP and CST SLA Accting       --
  -- setups for Accrual accounting. This takes the following parameters      --
  --                    1) vendor_id                                         --
  -- VERSION 1.0                                                             --
  --                                                                         --
  -- PARAMETERS                                                              --
  --                                                                         --
  --  P_VENDOR_ID         vendor_id from po_headers_all for CST              --
  --                      vendor_id from ap_invoices_all for AP              --
  --  Logic:                                                                 --
  --  Using Vendor ID, vedor type is derived and returned                    --
  --  If it is null or exception occurs it return                            --
  --  null value                                                             --
  --  This is setup in custom sources of SLA                                 --
  -- HISTORY:                                                                --
  --    12/03/2012       Naga         Created                                --
  -- End of comments                                                         --
  -----------------------------------------------------------------------------
  function get_vendor_type(p_vendor_id in number)
    return varchar2 is
    l_vendor_type varchar2(30);
  begin
    select vendor_type_lookup_code
    into   l_vendor_type
    from   po_vendors
    where  vendor_id = p_vendor_id;
    return l_vendor_type;
  exception
    when others then
      return null;
  end;
  -----------------------------------------------------------------------------
  -- Start of comments                                                       --
  --                                                                         --
  -- PROCEDURE                                                               --
  --  get_vendor_type  This function is used in CST SLA Accting              --
  -- setups for Accrual accounting. This takes the following parameters      --
  --                    1) organization_id                                   --
  -- VERSION 1.0                                                             --
  --                                                                         --
  -- PARAMETERS                                                              --
  --                                                                         --
  --  P_ORGANIZATION_ID    vendor_id from rcv_transactions for CST           --
  --  Logic:                                                                 --
  --  Using orgnaization_Id, receiving account's company segment is derived  --
  --  If it is null or exception occurs it return                            --
  --  null value                                                             --
  --  This is setup in custom sources of SLA                                 --
  -- HISTORY:                                                                --
  --    12/03/2012       Naga         Created                                --
  -- End of comments                                                         --
  -----------------------------------------------------------------------------
  function get_organization_id(p_rcv_trx_id in number)
    return number is
    l_organization_id varchar2(30);
  begin
    select organization_id
    into   l_organization_id
    from   rcv_transactions
    where  transaction_id = p_rcv_trx_id;
    return l_organization_id;
  exception
    when others then
      return null;
  end;
  -----------------------------------------------------------------------------
  -- Start of comments                                                       --
  --                                                                         --
  -- PROCEDURE                                                               --
  --  get_vendor_type  This function is used in CST SLA Accting              --
  -- setups for Accrual accounting. This takes the following parameters      --
  --                    1) organization_id                                   --
  -- VERSION 1.0                                                             --
  --                                                                         --
  -- PARAMETERS                                                              --
  --                                                                         --
  --  P_ORGANIZATION_ID    vendor_id from rcv_transactions for CST           --
  --  Logic:                                                                 --
  --  Using orgnaization_Id, receiving account's company segment is derived  --
  --  If it is null or exception occurs it return                            --
  --  null value                                                             --
  --  This is setup in custom sources of SLA                                 --
  -- HISTORY:                                                                --
  --    12/03/2012       Naga         Created                                --
  -- End of comments                                                         --
  -----------------------------------------------------------------------------
  function get_rcv_acct_bal_segment(p_rcv_trx_id in number)
    return varchar2 is
    l_company_code varchar2(30);
  begin
    select b.segment1
    into   l_company_code
    from   rcv_parameters a, gl_code_combinations b
    where  a.receiving_account_id = b.code_combination_id and a.organization_id = get_organization_id(p_rcv_trx_id);
    return l_company_code;
  exception
    when others then
      return null;
  end;
  -----------------------------------------------------------------------------
  -- Start of comments                                                       --
  --                                                                         --
  -- PROCEDURE                                                               --
  --  get_vendor_type  This function is used in CST SLA Accting              --
  -- setups for Accrual accounting. This takes the following parameters      --
  --                    1) organization_id                                   --
  -- VERSION 1.0                                                             --
  --                                                                         --
  -- PARAMETERS                                                              --
  --                                                                         --
  --  P_ORGANIZATION_ID    vendor_id from rcv_transactions for CST           --
  --  Logic:                                                                 --
  --  Using orgnaization_Id, receiving account's company segment is derived  --
  --  If it is null or exception occurs it return                            --
  --  null value                                                             --
  --  This is setup in custom sources of SLA                                 --
  -- HISTORY:                                                                --
  --    12/03/2012       Naga         Created                                --
  -- End of comments                                                         --
  -----------------------------------------------------------------------------
  function get_destination(p_rcv_trx_id in number)
    return varchar2 is
    l_destination varchar2(30);
  begin
    select b.destination_type_code
    into   l_destination
    from   rcv_transactions a, po_distributions_all b
    where  a.transaction_id = p_rcv_trx_id and a.po_distribution_id = b.po_distribution_id;
    return l_destination;
  exception
    when others then
      return null;
  end;
  -----------------------------------------------------------------------------
  -- Start of comments                                                       --
  --                                                                         --
  -- PROCEDURE                                                               --
  --  get_vendor_type  This function is used in CST SLA Accting              --
  -- setups for Accrual accounting. This takes the following parameters      --
  --                    1) organization_id                                   --
  -- VERSION 1.0                                                             --
  --                                                                         --
  -- PARAMETERS                                                              --
  --                                                                         --
  --  P_ORGANIZATION_ID    vendor_id from rcv_transactions for CST           --
  --  Logic:                                                                 --
  --  Using orgnaization_Id, receiving account's company segment is derived  --
  --  If it is null or exception occurs it return                            --
  --  null value                                                             --
  --  This is setup in custom sources of SLA                                 --
  -- HISTORY:                                                                --
  --    12/03/2012       Naga         Created                                --
  -- End of comments                                                         --
  -----------------------------------------------------------------------------
  function get_salesrep_region(p_trx_id in number)
    return varchar2 is
    l_salesrep_region varchar2(30);
  begin
    select d.segment6
    into   l_salesrep_region
    from   mtl_material_transactions a, jtf_rs_salesreps b, oe_order_lines_all c, gl_code_combinations_kfv d
    where      a.transaction_id = p_trx_id
           and a.trx_source_line_id = c.line_id
           and a.source_code = 'ORDER ENTRY'
           and a.transaction_type_id in (10008, 15) --Cogs Recognition and RMA
           and c.salesrep_id = b.salesrep_id
           and exists
                 (select 1
                  from   mtl_transaction_accounts mta
                  where  a.transaction_id = mta.transaction_id and mta.accounting_line_type = 35) -- Cost of Goods Sold
           and b.gl_id_rev = d.code_combination_id;
    return l_salesrep_region;
  exception
    when others then
      return null;
  end;
  function check_expense_accruals(p_inv_dist_id in number)
    return varchar2 is
    l_accrue_on_receipt varchar2(100);
    l_destination varchar2(100);
    l_organization_id number;
    l_count number;
    l_company_segment varchar2(30);
  begin
    select count(*)
    into   l_count
    from   ap_invoice_distributions_all a, gl_code_combinations_kfv e
    where      po_distribution_id is not null
           and a.dist_code_combination_id = e.code_combination_id
           and a.invoice_distribution_id = p_inv_dist_id
           and exists
                 (select 1
                  from   po_distributions_all b, rcv_parameters c, gl_code_combinations_kfv d, po_line_locations_all poll
                  where      a.po_distribution_id = b.po_distribution_id
                         and b.line_location_id = poll.line_location_id
                         and poll.accrue_on_receipt_flag = 'Y'
                         and b.destination_organization_id = c.organization_id
                         and c.receiving_account_id = d.code_combination_id
                         and a.dist_code_combination_id = b.accrual_account_id
                         and e.segment1 <> d.segment1
                         and b.destination_type_code = 'EXPENSE');
    if l_count <> 0 then
      begin
        select destination_organization_id
        into   l_organization_id
        from   po_distributions_all
        where  po_distribution_id = (select po_distribution_id
                                     from   ap_invoice_distributions_all
                                     where  invoice_distribution_id = p_inv_dist_id);
        select segment1
        into   l_company_segment
        from   rcv_parameters a, gl_code_combinations b
        where  organization_id = l_organization_id and a.receiving_account_id = b.code_combination_id;
        return l_company_segment;
      exception
        when others then
          return null;
      end;
    else
      return null;
    end if;
  exception
    when others then
      return null;
  end;
  function get_vendor_site_ic_segment(p_vendor_site_id in number)
    return varchar2 is
    l_ic_segment varchar2(30);
  begin
    select b.segment7
    into   l_ic_segment
    from   po_vendor_sites_all a, gl_code_combinations b
    where  a.accts_pay_code_combination_id = b.code_combination_id and vendor_site_id = p_vendor_site_id;
    return l_ic_segment;
  exception
    when others then
      return null;
  end;
  function check_ppv_vendor_type(p_trx_id in number)
    return varchar2 is
    l_yes varchar2(1);
  begin
    l_yes := 'N';
    select 'Y'
    into   l_yes
    from   mtl_material_transactions a
    where  transaction_id = p_trx_id
           and exists
                 (select 1
                  from   rcv_transactions b, po_headers_all c, po_vendors d
                  where      a.rcv_transaction_id = b.transaction_id
                         and b.po_header_id = c.po_header_id
                         and c.vendor_id = d.vendor_id
                         and source_document_code = 'PO'
                         and d.vendor_type_lookup_code = 'INTERCOMPANY');
    return l_yes;
  exception
    when others then
      return 'N';
  end;
  function get_vendor_site_ic(p_trx_id in number)
    return varchar2 is
    l_ic_segment varchar2(30);
  begin
    l_ic_segment := null;
    select get_vendor_site_ic_segment(c.vendor_site_id)
    into   l_ic_segment
    from   mtl_material_transactions a, rcv_transactions b, po_headers_all c, po_vendors d
    where      a.transaction_id = p_trx_id
           and a.rcv_transaction_id = b.transaction_id
           and b.po_header_id = c.po_header_id
           and c.vendor_id = d.vendor_id
           and source_document_code = 'PO'
           and d.vendor_type_lookup_code = 'INTERCOMPANY';
    return l_ic_segment;
  exception
    when others then
      return null;
  end;
  function get_ic_customer(p_order_line_id in varchar2)
    return varchar2 is
    l_ic_segment varchar2(400);
  begin
    l_ic_segment := null;
    select distinct glcc.segment7
    into   l_ic_segment
    from   oe_invoice_to_orgs_v c
         , hz_cust_accounts d
         , oe_order_lines_all e
         , ar_lookups ar
         , hz_cust_site_uses_all hcsu
         , gl_code_combinations glcc
    where      e.line_id = p_order_line_id
           and c.customer_id = d.cust_account_id
           and c.organization_id = e.invoice_to_org_id
           and e.invoice_to_org_id = hcsu.site_use_id
           and hcsu.gl_id_rev = glcc.code_combination_id
           and d.account_number = ar.lookup_code
           and ar.lookup_type = 'INTG_INTERCOMPANY_ACCOUNTS';
    return l_ic_segment;
  exception
    when others then
      return null;
  end get_ic_customer;
  function check_ic_customer(p_order_line_id in varchar2)
    return varchar2 is
    l_acct_number varchar2(400);
  begin
    l_acct_number := null;
    l_acct_number := get_ic_customer(p_order_line_id);
    if l_acct_number is not null then
      return 'Y';
    else
      return 'N';
    end if;
  exception
    when others then
      return 'N';
  end check_ic_customer;
  function build_sql(p_view in varchar2, p_colcount in number, p_columns in dbms_sql.desc_tab)
    return varchar2 is
    l_sql varchar2(4000);
    l_seperator varchar2(20) := ',';
    l_semicolon varchar2(20) := ';';
    l_colon varchar2(20) := ':';
    l_quote varchar2(1) := '''';
    l_pipe varchar2(20) := '||';
    l_last_pipe varchar2(20) := '||';
    crlf constant varchar2(1000) := '
';
  begin
    if p_view = 'CST_XLA_INV_WIP_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_INV_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_WIP_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_RCV_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 13 then
          exit;
        end if;
        if i = 12 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view in ('CST_XLA_INV_SO_V', 'CST_XLA_INV_REQ_V') then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_INV_RCPT_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 8 then
          exit;
        end if;
        if i = 7 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_INV_INTRAORG_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_OSP_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_INV_XFR_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_INV_XFR_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_INV_PO_V' then
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || p_view || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    if p_view = 'CST_XLA_INV_CU_V' then
      --p_view:='XXCST_XLA_INV_CU_V';
      l_sql := 'select ';
      for i in 1 .. p_columns.count() loop
        if i = 9 then
          exit;
        end if;
        if i = 8 then
          l_last_pipe := null;
        end if;
        l_sql :=    l_sql
                 || l_quote
                 || ' '
                 || initcap(replace(p_columns(i).col_name, '_', ' '))
                 || l_colon
                 || ' '
                 || l_quote
                 || l_pipe
                 || p_columns(i).col_name
                 || l_pipe
                 || l_quote
                 || l_semicolon
                 || l_quote
                 || l_last_pipe;
      end loop;
      l_sql := l_sql || ' from ' || 'XX_CST_XLA_INV_CU_V' || crlf;
      l_sql := l_sql || 'where transaction_id = :p_transaction_id';
    end if;
    dbms_output.put_line(l_sql);
    return l_sql;
  exception
    when others then
      dbms_output.put_line(sqlerrm);
      return null;
  end;
  function get_sql(p_view_name in varchar2)
    return varchar2 is
    s integer;
    t integer;
    l_colcount number;
    l_colmns dbms_sql.desc_tab;
    l_view varchar2(30);
    crlf constant varchar2(10000) := '
';
    sql_stmt varchar2(10000) := 'select * from $REP_VIEW_NAME$';
    l_sql_stmt varchar2(10000);
    l_stmt varchar2(10000);
  begin
    l_view := null;
    l_view := p_view_name;
    l_colmns.delete;
    l_colcount := 0;
    l_sql_stmt := null;
    l_sql_stmt := sql_stmt;
    l_sql_stmt := replace(l_sql_stmt, '$REP_VIEW_NAME$', l_view);
    s := dbms_sql.open_cursor;
    dbms_sql.parse(s, l_sql_stmt, dbms_sql.native);
    dbms_sql.describe_columns(s, l_colcount, l_colmns);
    l_stmt := build_sql(p_view_name, l_colcount, l_colmns);
    dbms_sql.close_cursor(s);
    return l_stmt;
  exception
    when others then
      dbms_output.put(sqlerrm);
      if dbms_sql.is_open(s) then
        dbms_sql.close_cursor(s);
      end if;
  end;
  function journal_desc(p_transaction_id in number)
    return varchar2 is
    l_trans_desc varchar2(10000);
    s integer;
    t integer;
    l_view_name varchar2(400);
    l_sql varchar2(10000);
    l_seperator varchar2(20) := '||''*''||';
    crlf constant varchar2(10000) := '
';
  begin
    select reporting_view_name
    into   l_view_name
    from   (select distinct b.reporting_view_name reporting_view_name
            from   apps.xla_transaction_entities_upg a
                 , apps.xla_event_class_attrs_fvl b
                 , apps.xla_event_types_b c
                 , apps.xla_events d
                 , mtl_material_transactions mmt
                 , cst_organization_definitions cst
            where      a.entity_id = d.entity_id
                   and nvl(source_id_int_1, -99) = mmt.transaction_id
                   and a.application_id = 707
                   and a.ledger_id = cst.set_of_books_id
                   and mmt.transaction_id = p_transaction_id
                   and nvl(a.source_id_int_2, -99) = mmt.organization_id
                   and mmt.organization_id = cst.organization_id
                   and a.entity_code = b.entity_code
                   and b.entity_code = c.entity_code
                   and a.entity_code = 'MTL_ACCOUNTING_EVENTS'
                   and b.event_class_code = c.event_class_code
                   and b.application_id = 707
                   and c.application_id = 707
                   and d.application_id = 707
                   and c.event_type_code = d.event_type_code
            union
            select b.reporting_view_name reporting_view_name
            from   apps.xla_transaction_entities_upg a
                 , apps.xla_event_class_attrs_fvl b
                 , apps.xla_event_types_b c
                 , apps.xla_events d
                 , rcv_accounting_events rcv
                 , rcv_transactions rct
                 , cst_organization_definitions cst
            where      a.entity_id = d.entity_id
                   and nvl(source_id_int_1, -99) = rct.transaction_id
                   and a.application_id = 707
                   and a.ledger_id = cst.set_of_books_id
                   and rct.transaction_id = p_transaction_id
                   and rct.organization_id = cst.organization_id
                   and rct.transaction_id = rcv.rcv_transaction_id
                   and nvl(source_id_int_2, -99) = rcv.accounting_event_id
                   and a.entity_code = b.entity_code
                   and b.entity_code = c.entity_code
                   and a.entity_code = 'RCV_ACCOUNTING_EVENTS'
                   and b.event_class_code = c.event_class_code
                   and b.application_id = 707
                   and c.application_id = 707
                   and d.application_id = 707
                   and c.event_type_code = d.event_type_code
            union
            select distinct b.reporting_view_name reporting_view_name
            from   apps.xla_transaction_entities_upg a
                 , apps.xla_event_class_attrs_fvl b
                 , apps.xla_event_types_b c
                 , apps.xla_events d
                 , cst_xla_wip_v wip
                 , cst_organization_definitions cst
            where      a.entity_id = d.entity_id
                   and nvl(source_id_int_1, -99) = wip.transaction_id
                   and nvl(source_id_int_2, -99) = wip.resource_id
                   and nvl(source_id_int_3, -99) = wip.basis_type_id
                   and a.application_id = 707
                   and a.ledger_id = cst.set_of_books_id
                   and wip.transaction_id = p_transaction_id
                   and wip.organization_code = cst.organization_code
                   and a.entity_code = b.entity_code
                   and b.entity_code = c.entity_code
                   and a.entity_code = 'WIP_ACCOUNTING_EVENTS'
                   and b.event_class_code = c.event_class_code
                   and b.application_id = 707
                   and c.application_id = 707
                   and d.application_id = 707
                   and c.event_type_code = d.event_type_code);
    l_sql := get_sql(l_view_name);
    --dbms_output.put_line(l_sql);
    -- dbms_output.put_line(l_view_name);
    s := dbms_sql.open_cursor;
    dbms_sql.parse(s, l_sql, dbms_sql.native);
    dbms_sql.bind_variable(s, 'p_transaction_id', p_transaction_id);
    dbms_sql.define_column(s, 1, l_trans_desc, 1000);
    t := dbms_sql.execute(s);
    loop
      if dbms_sql.fetch_rows(s) > 0 then
        dbms_sql.column_value(s, 1, l_trans_desc);
      else
        exit;
      end if;
    end loop;
    dbms_sql.close_cursor(s);
    --dbms_output.put_line(l_trans_desc);
    return substr(l_trans_desc, 1, 400);
  exception
    when others then
      if dbms_sql.is_open(s) then
        dbms_sql.close_cursor(s);
      end if;
      dbms_output.put_line(sqlerrm);
      dbms_output.put_line('No Value');
      return null;
  end;
  function get_order_type(p_order_line_id in number)
    return varchar2 is
    l_order_type varchar2(100);
  begin
    l_order_type := null;
    select name
    into   l_order_type
    from   oe_order_types_v a, oe_order_headers_all b, oe_order_lines_all c
    where  c.line_id = p_order_line_id and a.order_type_id = b.order_type_id and b.header_id = c.header_id;
    return l_order_type;
  exception
    when others then
      return null;
  end;
  function get_line_type(p_order_line_id in number)
    return varchar2 is
    l_line_type varchar2(100);
  begin
    l_line_type := null;
    select name
    into   l_line_type
    from   oe_line_types_v a, oe_order_lines_all b
    where  b.line_id = p_order_line_id and a.line_type_id = b.line_type_id;
    return l_line_type;
  exception
    when others then
      return null;
  end;
  function get_order_type_cogs(p_order_line_id in number)
    return number is
    l_cogs_account number;
  begin
    l_cogs_account := null;
    select glcc.code_combination_id
    into   l_cogs_account
    from   oe_transaction_types_all a, oe_order_headers_all b, oe_order_lines_all c, gl_code_combinations glcc
    where      c.line_id = p_order_line_id
           and a.transaction_type_id = b.order_type_id
           and a.org_id = b.org_id
           and b.header_id = c.header_id
           and a.cost_of_goods_sold_account = glcc.code_combination_id;
    return l_cogs_account;
  exception
    when others then
      return null;
  end;
  function get_line_type_cogs(p_order_line_id in number)
    return number is
    l_line_cogs_account number;
  begin
    l_line_cogs_account := null;
    begin
      select glcc.code_combination_id
      into   l_line_cogs_account
      from   oe_order_lines_all b, oe_transaction_types_all c, gl_code_combinations glcc
      where      b.line_id = p_order_line_id
             and c.transaction_type_code = 'LINE'
             and b.line_type_id = c.transaction_type_id
             and c.cost_of_goods_sold_account = glcc.code_combination_id;
    exception
      when others then
        l_line_cogs_account := get_order_type_cogs(p_order_line_id);
    end;
    if l_line_cogs_account is null then
      l_line_cogs_account := get_order_type_cogs(p_order_line_id);
    end if;
    return l_line_cogs_account;
  exception
    when others then
      return l_line_cogs_account;
  end;
  function get_ar_ic_cust_chk(p_acct_number in varchar2)
    return varchar2 is
    l_ic_acct varchar2(400);
  begin
    l_ic_acct := 'N';
    select 'Y'
    into   l_ic_acct
    from   ar_lookups ar, hz_cust_accounts hca
    where  hca.account_number = p_acct_number and hca.account_number = ar.lookup_code and ar.lookup_type = 'INTG_INTERCOMPANY_ACCOUNTS';
    return l_ic_acct;
  exception
    when others then
      return 'N';
  end get_ar_ic_cust_chk;
  function item_type(p_item_id in number)
    return mtl_system_items_b.item_type%type is
    l_item_type mtl_system_items_b.item_type%type;
  begin
    select item_type
    into   l_item_type
    from   mtl_system_items_b
    where  inventory_item_id = p_item_id and organization_id = 83;
    return l_item_type;
  exception
    when others then
      return null;
  end;
  function get_trf_org_material_acct(p_transaction_id in number)
    return number is
    l_material_account number;
  begin
    select b.material_account
    into   l_material_account
    from   mtl_material_transactions a, mtl_parameters b
    where  transaction_id = p_transaction_id and a.transfer_organization_id = b.organization_id;
    return l_material_account;
  exception
    when others then
      return null;
  end;
  function get_trx_warehouse(p_customer_trx_id in number, p_interface_context in varchar2)
    return varchar2 is
    l_warehouse varchar2(100);
  begin
    if p_interface_context = 'ORDER ENTRY' then
      select interface_header_attribute10
      into   l_warehouse
      from   ra_customer_trx_all rat
      where  rat.customer_trx_id = p_customer_trx_id;
    elsif p_interface_context in ('GLOBAL_PROCUREMENT', 'INTERCOMPANY') then
      select interface_header_attribute3
      into   l_warehouse
      from   ra_customer_trx_all
      where  customer_trx_id = p_customer_trx_id and interface_header_attribute4 <> interface_header_attribute5;
    end if;
    return l_warehouse;
  exception
    when others then
      return null;
  end;
  function get_warehouse_company(p_customer_trx_id in number, p_cust_trx_type_id in number, p_interface_context in varchar2)
    return varchar2 is
    l_warehouse varchar2(100);
    l_company varchar2(100);
    l_trx_type_comp_segment varchar2(10);
  begin
    l_warehouse := get_trx_warehouse(p_customer_trx_id, p_interface_context);
    begin
      select segment1
      into   l_trx_type_comp_segment
      from   ra_customer_trx_all a, ra_cust_trx_line_gl_dist_all b, gl_code_combinations c
      where      b.code_combination_id = c.code_combination_id
             and a.customer_trx_id = p_customer_trx_id
             and a.customer_trx_id = b.customer_trx_id
             and b.account_class = 'REC'
             and b.latest_rec_flag = 'Y';
    exception
      when others then
        l_trx_type_comp_segment := null;
    end;
    if l_warehouse is not null then
      select b.segment1
      into   l_company
      from   mtl_parameters a, gl_code_combinations_kfv b
      where      a.organization_id = l_warehouse
             and a.material_account = b.code_combination_id
             and b.segment1 <> nvl(l_trx_type_comp_segment, '000');
    end if;
    return l_company;
  exception
    when others then
      return null;
  end;
  function get_adj_trx_rec_acct(p_adjustment_id in number)
    return number is
    cust_trx_id number;
    receivables_account number;
  begin
    select customer_trx_id
    into   cust_trx_id
    from   ar_adjustments_all
    where  adjustment_id = p_adjustment_id;
    receivables_account := get_rec_account(cust_trx_id);
    return receivables_account;
  exception
    when others then
      return null;
  end;
  function get_rec_account(p_customer_trx_id in number)
    return varchar2 is
    receivables_account number;
  begin
    select code_combination_id
    into   receivables_account
    from   ar_xla_ctlgd_lines_v
    where  customer_trx_id = p_customer_trx_id and account_class = 'REC';
    return receivables_account;
  exception
    when others then
      return null;
  end;
  function get_item_product_segment(p_item_id in number, p_organization_id in number)
    return varchar2 is
    l_product_segment varchar2(30);
    l_organization_id number;
  begin
    l_product_segment := '901';
    l_organization_id := nvl(p_organization_id, g_master_organization_id);
    begin
      select segment1
      into   l_product_segment
      from   mtl_categories a, mtl_item_categories b
      where      b.inventory_item_id = p_item_id
             and b.organization_id = l_organization_id
             and a.category_id = b.category_id
             and b.category_set_id = g_category_set_id
             and a.structure_id = g_category_structure_id;
    exception
      when others then
        select a.segment5
        into   l_product_segment
        from   gl_code_combinations_kfv a, mtl_system_items_b b
        where      a.code_combination_id = b.cost_of_sales_account
               and b.organization_id = l_organization_id
               and b.inventory_item_id = p_item_id;
    end;
    return l_product_segment;
  exception
    when others then
      return l_product_segment;
  end;
  function get_ar_cr_ic_segment(p_cash_receipt_id in number)
    return varchar2 is
    l_ic_segment varchar2(30);
  begin
    l_ic_segment := null;
    select attribute1
    into   l_ic_segment
    from   ar_cash_receipts_all
    where  cash_receipt_id = p_cash_receipt_id;
    return l_ic_segment;
  exception
    when others then
      return null;
  end;
  function drop_ship_type(p_rcv_trx_id in number)
    return number is
    l_drop_ship_type number;
  begin
    l_drop_ship_type := null;
    select nvl(dropship_type_code, 0)
    into   l_drop_ship_type
    from   rcv_transactions rcv
    where  transaction_id = p_rcv_trx_id;
    return l_drop_ship_type;
  exception
    when others then
      return l_drop_ship_type;
  end;
  function po_receipt_cross_ou(p_transaction_id in number
                             , p_trx_source_type_id in number
                             , p_trx_type_id in number
                             , p_organization_id in number
                             , p_rcv_trx_id in number)
    return varchar2 is
    l_yes_no varchar2(1);
  begin
    l_yes_no := 'N';
    if p_trx_type_id = 10 then
      l_yes_no := 'Y';
      return l_yes_no;
    end if;
    select 'Y'
    into   l_yes_no
    from   rcv_transactions rcv
    where  transaction_id = p_rcv_trx_id
           and ((rcv.dropship_type_code = 1)
                or (exists
                      (select 1
                       from   po_line_locations_all pll
                       where  transaction_flow_header_id is not null and rcv.po_line_location_id = pll.line_location_id)));
    return l_yes_no;
  exception
    when others then
      return l_yes_no;
  end;
  function po_cross_ou_ic(p_transaction_id in number
                        , p_trx_source_type_id in number
                        , p_trx_type_id in number
                        , p_organization_id in number
                        , p_rcv_trx_id in number)
    return varchar2 is
    ic_segment varchar2(10);
    l_yes_no varchar2(1);
    l_dist_ccid_check number;
    l_org_code varchar2(3);
  begin
    l_yes_no := po_receipt_cross_ou(p_transaction_id
                                  , p_trx_source_type_id
                                  , p_trx_type_id
                                  , p_organization_id
                                  , p_rcv_trx_id);
    if l_yes_no = 'Y' then
      select count(*)
      into   l_dist_ccid_check
      from   rcv_transactions a, po_distributions_all b
      where      a.po_distribution_id = b.po_distribution_id
             and a.transaction_id = p_rcv_trx_id
             and b.dest_charge_account_Id <> b.code_combination_id;
      if l_dist_ccid_check > 0 then
        select gl.segment1
        into   ic_segment
        from   po_distributions_all pod, gl_code_combinations gl, rcv_transactions rcv
        where      pod.po_distribution_id = rcv.po_distribution_id
               and pod.code_combination_id = gl.code_combination_id --and pod.dest_charge_account_Id = gl.code_combination_id
               and rcv.transaction_id = p_rcv_trx_id;
      elsif l_dist_ccid_check = 0 then
        select organization_code
        into   l_org_code
        from   mtl_parameters
        where  organization_id =
                 (select from_organization_id
                  from   mtl_transaction_flow_lines a, po_line_locations_all b, rcv_transactions c
                  where      a.header_id = b.transaction_flow_header_id
                         and b.line_location_id = c.po_line_location_id
                         and c.transaction_id = p_rcv_trx_id);
        if l_org_code = '100' then
          ic_segment := '101';
        elsif l_org_code = '117' then
          ic_segment := '114';
        end if;
      end if;
    end if;
    return ic_segment;
  exception
    when others then
      return null;
  end;
  function po_cross_ou_ic_dest(p_transaction_id in number
                             , p_trx_source_type_id in number
                             , p_trx_type_id in number
                             , p_organization_id in number
                             , p_rcv_trx_id in number)
    return varchar2 is
    ic_segment varchar2(10);
    l_yes_no varchar2(1);
  begin
    l_yes_no := po_receipt_cross_ou(p_transaction_id
                                  , p_trx_source_type_id
                                  , p_trx_type_id
                                  , p_organization_id
                                  , p_rcv_trx_id);
    if l_yes_no = 'Y' then
      select gl.segment1
      into   ic_segment
      from   po_distributions_all pod, gl_code_combinations gl, rcv_transactions rcv
      where      pod.po_distribution_id = rcv.po_distribution_id --pod.code_combination_id = gl.code_combination_id
             and pod.dest_charge_account_Id = gl.code_combination_id
             and rcv.transaction_id = p_rcv_trx_id;
    end if;
    return ic_segment;
  exception
    when others then
      return null;
  end;
  function is_117_approved_supp_list(p_item_id in number)
    return varchar2 is
    l_yes varchar2(1);
    l_organization_code varchar2(3);
  begin
    l_yes := 'N';
    begin
      select 'Y'
      into   l_yes
      from   dual
      where  exists
               (select b.organization_code
                from   po_approved_supplier_list a, mtl_parameters b
                where      item_id = p_item_id
                       and nvl(disable_flag, 'N') = 'N'
                       and a.owning_organization_id = b.organization_id
                       and b.organization_code = '117'
                union
                select b.organization_code
                from   mtl_system_items_b a, mtl_parameters b
                where      inventory_item_id = p_item_id
                       and a.organization_id = b.organization_id
                       and b.organization_code = '117'
                       and inventory_item_status_code not in ('Inactive', 'Obsolete')
                       and purchasing_enabled_flag = 'Y');
    exception
      when others then
        l_yes := 'N';
    end;
    return l_yes;
  exception
    when others then
      return l_yes;
  end;
  function get_nonrec_account(p_invoice_id in number, p_inv_dist_id in number, p_dist_acct_id in number)
    return number is
    l_tax_account_id number;
    l_tax_rate_id number;
    l_org_id number;
    l_dist_account_Id number;
    l_tax_rate_code varchar2(4000);
    l_default_flag VARCHAR2(1) := 'Y';
    cursor c is
      select lookup_code lkup_code
      from   ap_lookup_codes
      where  lookup_type = 'INTG_SLA_NONREC_TAX_CODES';
  begin
    l_tax_rate_id := null;
    l_org_id := null;
    l_dist_account_Id := p_dist_acct_id;
    l_tax_rate_code := null;
    l_tax_account_id := null;
    select tax_rate_id, b.org_id
    into   l_tax_rate_id, l_org_id
    from   ap_invoice_lines_all a, ap_invoice_distributions_all b
    where      a.invoice_Id = p_invoice_id
           and a.line_number = b.invoice_line_number
           and a.invoice_id = b.invoice_id
           and b.invoice_distribution_id = p_inv_dist_id
           and b.line_type_lookup_code in ('NONREC_TAX','TRV');
    if l_tax_rate_id is not null then
      select tax_rate_code
      into   l_tax_rate_code
      from   zx_rates_b
      where  tax_rate_id = l_tax_rate_id;
      l_default_flag := 'N';
      for i in c loop
        if l_tax_rate_code like i.lkup_code || '%' then
        l_default_flag := 'Y';
          exit;
        else
          --l_dist_account_Id:= 1138;
          --return l_dist_account_Id;
          l_default_flag := 'N';
        end if;
      end loop;
      IF l_default_flag = 'Y' THEN
      select ZA.TAX_ACCOUNT_CCID
      into   l_tax_account_id
      from   ZX_ACCOUNTS ZA, HR_OPERATING_UNITS HROU, GL_LEDGERS GL, FND_ID_FLEX_STRUCTURES FIFS
      where      ZA.INTERNAL_ORGANIZATION_ID = HROU.ORGANIZATION_ID
             and GL.LEDGER_ID = ZA.LEDGER_ID
             and FIFS.APPLICATION_ID = 101
             and FIFS.ID_FLEX_CODE = 'GL#'
             and FIFS.ID_FLEX_NUM = GL.CHART_OF_ACCOUNTS_ID
             and tax_account_entity_id = l_tax_rate_id
             and hrou.organization_Id = l_org_id;
      ELSE
           return l_dist_account_Id;
      END IF;
    else
      return l_dist_account_Id;
    end if;
    l_tax_account_Id := nvl(l_tax_account_Id, l_dist_account_Id);
    return l_tax_account_Id;
  exception
    when others then
      return l_dist_account_Id;
  end;
begin
  --g_master_organization_id := 83;
  --g_category_set_id := 1100000041;

  g_master_organization_id := 102;
  g_category_set_id := 1100000081;
  g_category_structure_id := 50210;
end xx_xla_custom_sources_pkg;
/
