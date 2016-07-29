DROP PACKAGE BODY APPS.XX_AR_UPD_SALESREP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_UPD_SALESREP_PKG" is
  procedure update_restock_ref_lines is
    cursor restock_lines is
      select distinct org_id, interface_line_context, rtrim(ltrim(interface_line_attribute1)) interface_line_attribute1
                    , rtrim(ltrim(interface_line_attribute2)) interface_line_attribute2
                    , rtrim(ltrim(interface_line_attribute3)) interface_line_attribute3
                    , rtrim(ltrim(interface_line_attribute4)) interface_line_attribute4
                    , rtrim(ltrim(interface_line_attribute5)) interface_line_attribute5
                    , rtrim(ltrim(interface_line_attribute6)) interface_line_attribute6
                    , rtrim(ltrim(interface_line_attribute7)) interface_line_attribute7
                    , rtrim(ltrim(interface_line_attribute8)) interface_line_attribute8
                    , rtrim(ltrim(interface_line_attribute9)) interface_line_attribute9
                    , rtrim(ltrim(interface_line_attribute10)) interface_line_attribute10
                    , rtrim(ltrim(interface_line_attribute11)) interface_line_attribute11
                    , rtrim(ltrim(interface_line_attribute12)) interface_line_attribute12
                    , rtrim(ltrim(interface_line_attribute13)) interface_line_attribute13
                    , rtrim(ltrim(interface_line_attribute14)) interface_line_attribute14, reference_line_id
      from   ra_interface_lines_all a
      where  org_id = 82 and interface_line_context = 'ORDER ENTRY' and nvl(interface_status, '~') <> 'P' and reference_line_id is not null
             and exists
                   (select 1
                    from   oe_charge_lines_v b, oe_order_headers_all c, oe_order_types_v d
                    where      b.header_id = c.header_id
                           and charge_name = xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST2')
                           and a.interface_line_attribute1 = c.order_number
                           and c.order_type_id = d.order_type_id
                           and a.interface_line_attribute2 = d.name);
    l_count number;
  begin
    l_count := 0;
    for i in restock_lines loop
      update ra_interface_lines_all
      set    reference_line_id = null
      where      nvl(interface_status, '~') <> 'P'
             and reference_line_id is not null
             and interface_line_context = i.interface_line_context
             and reference_line_id = i.reference_line_id
             and rtrim(ltrim(interface_line_attribute1)) = nvl(i.interface_line_attribute1, rtrim(ltrim(interface_line_attribute1)))
             and rtrim(ltrim(interface_line_attribute2)) = nvl(i.interface_line_attribute2, rtrim(ltrim(interface_line_attribute2)));
      l_count := l_count + sql%rowcount;
    end loop;
    fnd_file.put_line(fnd_file.log
                    ,    'Number of reference line IDS Updated for the restock lines '
                      || xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST2')
                      || ': '
                      || l_count);
  end update_restock_ref_lines;
  procedure update_item_info(p_order_number in number default null) is
  begin
    update ra_interface_lines_all a
    set    line_type = case
                         when nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'Y' then line_type
                         when nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'N' then 'LINE'
                         else line_type
                       end
         , quantity = 1
         , unit_selling_price = amount
         , (inventory_item_id
          , description
          , uom_code) = (select inventory_item_id, description, primary_uom_code
                         from   mtl_system_items_b b
                         where  case
                                  when (select charge_name
                                        from   oe_charge_lines_v c
                                        where  a.interface_line_attribute6 = c.charge_id) =
                                         xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST2')
                                       and a.interface_line_context = 'ORDER ENTRY' then
                                    xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'ITEM2')
                                  when (select charge_name
                                        from   oe_charge_lines_v c
                                        where  a.interface_line_attribute6 = c.charge_id) =
                                         xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST1')
                                       and a.interface_line_context = 'ORDER ENTRY' then
                                    xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'ITEM1')
                                end = b.segment1
                                and organization_id = oe_sys_parameters.value('MASTER_ORGANIZATION_ID'))
    where      interface_line_context = 'ORDER ENTRY'
           and nvl(interface_status, '~') <> 'P'
           and line_type = case
                             when nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'Y' then 'LINE'
                             when nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'N' then 'FREIGHT'
                             else line_type
                           end
           and interface_line_attribute1 = nvl(p_order_number, interface_line_attribute1)
           and case
                 when     nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'Y'
                      and oe_sys_parameters.value('OE_INVENTORY_ITEM_FOR_FREIGHT', org_id) is not null
                      and line_type = 'LINE' then
                   oe_sys_parameters.value('OE_INVENTORY_ITEM_FOR_FREIGHT', org_id)
                 when line_type = 'FREIGHT' then
                   '0'
               end = nvl(inventory_item_id, '0')
           and exists
                 (select 1
                  from   oe_charge_lines_v d
                  where  a.interface_line_attribute6 = d.charge_id
                         and charge_name in
                               (xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST2')
                              , xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST1')));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high
                       , 'Number of records updated for item information in ra_interface_lines_all :' || sql%rowcount);
  end;
  procedure update_reference_line(p_order_number in number default null) is
    l_row_count number;
    cursor c is
      select distinct reference_line_id
      from   ra_interface_lines_all a
      where      reference_line_id is not null
             and nvl(interface_status, '~') <> 'P'
             and interface_line_context = 'ORDER ENTRY'
             and not exists
                   (select 1
                    from   iby_trxn_extensions_v iby
                    where  a.payment_trxn_extension_id = iby.trxn_extension_id and iby.instrument_type = 'CREDITCARD')
             and not exists
                       (select 1
                        from   ra_customer_trx_all rct, ra_customer_trx_lines_all rctl, iby_trxn_extensions_v iby
                        where      rct.customer_trx_id = rctl.customer_trx_id
                               and rct.payment_trxn_extension_id = iby.trxn_extension_id
                               and a.reference_line_id = rctl.customer_trx_line_id
                               and iby.instrument_type = 'CREDITCARD')
             and batch_source_name not in (select name
                                           from   ra_batch_sources_all
                                           where  receipt_handling_option = 'REFUND')
             and cust_trx_type_id in (select cust_trx_type_id
                                      from   ra_cust_trx_types_all
                                      where  type = 'CM');
    cursor c1 is
      select   interface_line_attribute1, interface_line_attribute2, count(*) reflinecount
      from     ra_interface_lines_all a
      where        org_id = 82
               and reference_line_id is null
               and nvl(interface_status, '~') <> 'P'
               and interface_line_context = 'ORDER ENTRY'
               and exists
                     (select 1
                      from   iby_trxn_extensions_v iby
                      where  a.payment_trxn_extension_id = iby.trxn_extension_id and iby.instrument_type = 'CREDITCARD')
               and exists
                     (select 1
                      from   ra_customer_trx_all rct, ra_customer_trx_lines_all rctl, iby_trxn_extensions_v iby
                      where      rct.customer_trx_id = rctl.customer_trx_id
                             and rct.payment_trxn_extension_id = iby.trxn_extension_id
                             and a.reference_line_id = rctl.customer_trx_line_id
                             and iby.instrument_type = 'CREDITCARD')
               and batch_source_name not in (select name
                                             from   ra_batch_sources_all
                                             where  receipt_handling_option = 'REFUND')
               and cust_trx_type_id in (select cust_trx_type_id
                                        from   ra_cust_trx_types_all
                                        where  type = 'CM')
      group by interface_line_attribute1, interface_line_attribute2;
  begin
    update_restock_ref_lines;
    l_row_count := 0;
    for i in c loop
      update ra_interface_lines_all
      set    reference_line_id = null
           , previous_customer_trx_id = null
           , request_id = null
      where  reference_line_id = i.reference_line_id and nvl(interface_status, '~') <> 'P' and interface_line_context = 'ORDER ENTRY';
      fnd_file.put_line(fnd_file.log, 'Reference Line ID is removed for non credit card orders' || i.reference_line_id);
      l_row_count := sql%rowcount + l_row_count;
    end loop;
    fnd_file.put_line(fnd_file.log, 'Reference Line ID is removed for non credit card orders ' || l_row_count || ' rows.');
    for i in c1 loop
      if i.reflinecount > 0 then
        update ra_interface_lines_all
        set    reference_line_id = null
             , previous_customer_trx_id = null
             , request_id = null
        where      interface_line_attribute1 = i.interface_line_attribute1
               and interface_line_attribute2 = i.interface_line_attribute2
               and nvl(interface_status, '~') <> 'P'
               and interface_line_context = 'ORDER ENTRY';
        fnd_file.put_line(fnd_file.log
                        , 'Reference Line ID is removed for credit card orders with atleast one line with no reference for order'
                          || i.interface_line_attribute1);
      end if;
    end loop;
  end;
  -------------------------------------------------------------------------------------------------
  -- insert_scredits
  -- This procedure inserts Sales Credit Relevant Data into ra_interface_salescredits_all table
  -------------------------------------------------------------------------------------------------
  procedure insert_scredits(p_salescredit_rec in oe_invoice_pub.ra_interface_scredits_rec_type) is
  begin
    insert into ra_interface_salescredits_all(created_by
                                            , creation_date
                                            , last_updated_by
                                            , last_update_date
                                            , interface_salescredit_id
                                            , interface_line_id
                                            , interface_line_context
                                            , interface_line_attribute1
                                            , interface_line_attribute2
                                            , interface_line_attribute3
                                            , interface_line_attribute4
                                            , interface_line_attribute5
                                            , interface_line_attribute6
                                            , interface_line_attribute7
                                            , interface_line_attribute8
                                            , interface_line_attribute9
                                            , interface_line_attribute10
                                            , interface_line_attribute11
                                            , interface_line_attribute12
                                            , interface_line_attribute13
                                            , interface_line_attribute14
                                            , interface_line_attribute15
                                            , salesrep_number
                                            , salesrep_id
                                            , sales_credit_type_name
                                            , sales_credit_type_id
                                            , sales_credit_amount_split
                                            , sales_credit_percent_split
                                            , interface_status
                                            , request_id
                                            , attribute_category
                                            , attribute1
                                            , attribute2
                                            , attribute3
                                            , attribute4
                                            , attribute5
                                            , attribute6
                                            , attribute7
                                            , attribute8
                                            , attribute9
                                            , attribute10
                                            , attribute11
                                            , attribute12
                                            , attribute13
                                            , attribute14
                                            , attribute15
                                            , org_id
                                            , salesgroup_id)
    values      (p_salescredit_rec.created_by, p_salescredit_rec.creation_date, p_salescredit_rec.last_updated_by, p_salescredit_rec.last_update_date
               , p_salescredit_rec.interface_salescredit_id, p_salescredit_rec.interface_line_id, p_salescredit_rec.interface_line_context
               , p_salescredit_rec.interface_line_attribute1, p_salescredit_rec.interface_line_attribute2, p_salescredit_rec.interface_line_attribute3
               , p_salescredit_rec.interface_line_attribute4, p_salescredit_rec.interface_line_attribute5, p_salescredit_rec.interface_line_attribute6
               , p_salescredit_rec.interface_line_attribute7, p_salescredit_rec.interface_line_attribute8, p_salescredit_rec.interface_line_attribute9
               , p_salescredit_rec.interface_line_attribute10, p_salescredit_rec.interface_line_attribute11, p_salescredit_rec.interface_line_attribute12
               , p_salescredit_rec.interface_line_attribute13, p_salescredit_rec.interface_line_attribute14, p_salescredit_rec.interface_line_attribute15
               , p_salescredit_rec.salesrep_number, p_salescredit_rec.salesrep_id, p_salescredit_rec.sales_credit_type_name
               , p_salescredit_rec.sales_credit_type_id, p_salescredit_rec.sales_credit_amount_split, p_salescredit_rec.sales_credit_percent_split
               , p_salescredit_rec.interface_status, p_salescredit_rec.request_id, p_salescredit_rec.attribute_category, p_salescredit_rec.attribute1
               , p_salescredit_rec.attribute2, p_salescredit_rec.attribute3, p_salescredit_rec.attribute4, p_salescredit_rec.attribute5
               , p_salescredit_rec.attribute6, p_salescredit_rec.attribute7, p_salescredit_rec.attribute8, p_salescredit_rec.attribute9
               , p_salescredit_rec.attribute10, p_salescredit_rec.attribute11, p_salescredit_rec.attribute12, p_salescredit_rec.attribute13
               , p_salescredit_rec.attribute14, p_salescredit_rec.attribute15, p_salescredit_rec.org_id, p_salescredit_rec.sales_group_id);
  end;
  -------------------------------------------------------------------------------------------------
  --get_salesrep_info
  -- This procedure inserts Sales Rep Information corresponding to the Sales Order
  -------------------------------------------------------------------------------------------------
  procedure get_salesrep_info(p_price_adjustment_id in number
                            , x_header_scredit_tbl   out oe_order_pub.header_scredit_tbl_type
                            , x_header_scredit_rec   out nocopy oe_order_pub.header_scredit_rec_type) is
    l_header_id number;
  begin
    select header_id
    into   l_header_id
    from   oe_price_adjustments
    where  price_adjustment_id = p_price_adjustment_id;
    oe_header_scredit_util.query_rows(p_header_id => l_header_id, x_header_scredit_tbl => x_header_scredit_tbl);
    x_header_scredit_rec := x_header_scredit_tbl(1);
  end;
  -------------------------------------------------------------------------------------------------
  -- get_interface_line_info
  -- This procedure gets the relvant line information from ra_interface_lines_all table for Sales Credit insert
  -------------------------------------------------------------------------------------------------
  procedure get_interface_line_info(p_price_adjustment_id in number
                                  , x_interface_line_rec   out oe_invoice_pub.ra_interface_lines_rec_type) is
    p_interface_line_rec ra_interface_lines_all%rowtype;
  begin
    select *
    into   p_interface_line_rec
    from   ra_interface_lines_all a
    where      interface_line_context = 'ORDER ENTRY'
           and interface_line_attribute6 = p_price_adjustment_id
           and nvl(interface_status, '~') <> 'P'
           and line_type = 'FREIGHT'
           and not exists
                     (select 1
                      from   ra_interface_salescredits_all b
                      where      a.interface_line_context = b.interface_line_context
                             and a.interface_line_attribute1 = b.interface_line_attribute1
                             and a.interface_line_attribute2 = b.interface_line_attribute2
                             and a.interface_line_attribute3 = b.interface_line_attribute3
                             and a.interface_line_attribute4 = b.interface_line_attribute4
                             and a.interface_line_attribute5 = b.interface_line_attribute5
                             and a.interface_line_attribute6 = b.interface_line_attribute6
                             and a.interface_line_attribute7 = b.interface_line_attribute7
                             and a.interface_line_attribute8 = b.interface_line_attribute8
                             and a.interface_line_attribute9 = b.interface_line_attribute9
                             and a.interface_line_attribute10 = b.interface_line_attribute10
                             and a.interface_line_attribute11 = b.interface_line_attribute11
                             and a.interface_line_attribute12 = b.interface_line_attribute12
                             and a.interface_line_attribute13 = b.interface_line_attribute13
                             and a.interface_line_attribute14 = b.interface_line_attribute14
                             and a.interface_line_attribute15 = b.interface_line_attribute15);
    x_interface_line_rec.interface_line_context := p_interface_line_rec.interface_line_context;
    x_interface_line_rec.interface_line_attribute1 := p_interface_line_rec.interface_line_attribute1;
    x_interface_line_rec.interface_line_attribute2 := p_interface_line_rec.interface_line_attribute2;
    x_interface_line_rec.interface_line_attribute3 := p_interface_line_rec.interface_line_attribute3;
    x_interface_line_rec.interface_line_attribute4 := p_interface_line_rec.interface_line_attribute4;
    x_interface_line_rec.interface_line_attribute5 := p_interface_line_rec.interface_line_attribute5;
    x_interface_line_rec.interface_line_attribute6 := p_interface_line_rec.interface_line_attribute6;
    x_interface_line_rec.interface_line_attribute7 := p_interface_line_rec.interface_line_attribute7;
    x_interface_line_rec.interface_line_attribute8 := p_interface_line_rec.interface_line_attribute8;
    x_interface_line_rec.interface_line_attribute9 := p_interface_line_rec.interface_line_attribute9;
    x_interface_line_rec.interface_line_attribute10 := p_interface_line_rec.interface_line_attribute10;
    x_interface_line_rec.interface_line_attribute11 := p_interface_line_rec.interface_line_attribute11;
    x_interface_line_rec.interface_line_attribute12 := p_interface_line_rec.interface_line_attribute12;
    x_interface_line_rec.interface_line_attribute13 := p_interface_line_rec.interface_line_attribute13;
    x_interface_line_rec.interface_line_attribute14 := p_interface_line_rec.interface_line_attribute14;
    x_interface_line_rec.interface_line_attribute15 := p_interface_line_rec.interface_line_attribute15;
    x_interface_line_rec.primary_salesrep_id := p_interface_line_rec.primary_salesrep_id;
    x_interface_line_rec.amount := p_interface_line_rec.amount;
    x_interface_line_rec.org_id := p_interface_line_rec.org_id;
  end;
  -------------------------------------------------------------------------------------------------
  -- prepare_salescredit_rec
  -- This procedure prepares the data into table type for Inserts
  -------------------------------------------------------------------------------------------------
  procedure prepare_salescredit_rec(p_interface_line_rec in oe_invoice_pub.ra_interface_lines_rec_type
                                  , p_header_scredit_rec in oe_order_pub.header_scredit_rec_type
                                  , x_interface_scredit_rec   out nocopy oe_invoice_pub.ra_interface_scredits_rec_type) is
  begin
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'ENTER LINE PREPARE_SALESCREDIT_REC ( ) PROCEDURE');
    x_interface_scredit_rec.creation_date := inv_le_timezone_pub.get_le_day_time_for_ou(sysdate, p_interface_line_rec.org_id);
    x_interface_scredit_rec.last_update_date := inv_le_timezone_pub.get_le_day_time_for_ou(sysdate, p_interface_line_rec.org_id);
    x_interface_scredit_rec.created_by := fnd_global.user_id;
    x_interface_scredit_rec.last_updated_by := fnd_global.user_id;
    x_interface_scredit_rec.interface_salescredit_id := null;
    x_interface_scredit_rec.interface_line_id := null;
    x_interface_scredit_rec.interface_line_context := p_interface_line_rec.interface_line_context;
    x_interface_scredit_rec.interface_line_attribute1 := p_interface_line_rec.interface_line_attribute1;
    x_interface_scredit_rec.interface_line_attribute2 := p_interface_line_rec.interface_line_attribute2;
    x_interface_scredit_rec.interface_line_attribute3 := p_interface_line_rec.interface_line_attribute3;
    x_interface_scredit_rec.interface_line_attribute4 := p_interface_line_rec.interface_line_attribute4;
    x_interface_scredit_rec.interface_line_attribute5 := p_interface_line_rec.interface_line_attribute5;
    x_interface_scredit_rec.interface_line_attribute6 := p_interface_line_rec.interface_line_attribute6;
    x_interface_scredit_rec.interface_line_attribute7 := p_interface_line_rec.interface_line_attribute7;
    x_interface_scredit_rec.interface_line_attribute8 := p_interface_line_rec.interface_line_attribute8;
    x_interface_scredit_rec.interface_line_attribute9 := p_interface_line_rec.interface_line_attribute9;
    x_interface_scredit_rec.interface_line_attribute10 := p_interface_line_rec.interface_line_attribute10;
    x_interface_scredit_rec.interface_line_attribute11 := p_interface_line_rec.interface_line_attribute11;
    x_interface_scredit_rec.interface_line_attribute12 := p_interface_line_rec.interface_line_attribute12;
    x_interface_scredit_rec.interface_line_attribute13 := p_interface_line_rec.interface_line_attribute13;
    x_interface_scredit_rec.interface_line_attribute14 := p_interface_line_rec.interface_line_attribute14;
    x_interface_scredit_rec.interface_line_attribute15 := p_interface_line_rec.interface_line_attribute15;
    x_interface_scredit_rec.salesrep_number := null;
    x_interface_scredit_rec.salesrep_id := p_interface_line_rec.primary_salesrep_id;
    x_interface_scredit_rec.sales_credit_type_id := 1;
    x_interface_scredit_rec.sales_credit_percent_split := 100;
    x_interface_scredit_rec.sales_credit_amount_split := p_interface_line_rec.amount;
    x_interface_scredit_rec.attribute_category := p_header_scredit_rec.context;
    x_interface_scredit_rec.sales_group_id := p_header_scredit_rec.sales_group_id;
    x_interface_scredit_rec.attribute1 := substrb(p_header_scredit_rec.attribute1, 1, 150);
    x_interface_scredit_rec.attribute2 := substrb(p_header_scredit_rec.attribute2, 1, 150);
    x_interface_scredit_rec.attribute3 := substrb(p_header_scredit_rec.attribute3, 1, 150);
    x_interface_scredit_rec.attribute4 := substrb(p_header_scredit_rec.attribute4, 1, 150);
    x_interface_scredit_rec.attribute5 := substrb(p_header_scredit_rec.attribute5, 1, 150);
    x_interface_scredit_rec.attribute6 := substrb(p_header_scredit_rec.attribute6, 1, 150);
    x_interface_scredit_rec.attribute7 := substrb(p_header_scredit_rec.attribute7, 1, 150);
    x_interface_scredit_rec.attribute8 := substrb(p_header_scredit_rec.attribute8, 1, 150);
    x_interface_scredit_rec.attribute9 := substrb(p_header_scredit_rec.attribute9, 1, 150);
    x_interface_scredit_rec.attribute10 := substrb(p_header_scredit_rec.attribute10, 1, 150);
    x_interface_scredit_rec.attribute11 := substrb(p_header_scredit_rec.attribute11, 1, 150);
    x_interface_scredit_rec.attribute12 := substrb(p_header_scredit_rec.attribute12, 1, 150);
    x_interface_scredit_rec.attribute13 := substrb(p_header_scredit_rec.attribute13, 1, 150);
    x_interface_scredit_rec.attribute14 := substrb(p_header_scredit_rec.attribute14, 1, 150);
    x_interface_scredit_rec.attribute15 := substrb(p_header_scredit_rec.attribute15, 1, 150);
    x_interface_scredit_rec.org_id := p_interface_line_rec.org_id;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'EXITING LINE PREPARE_SALESCREDIT_REC');
  end prepare_salescredit_rec;
  -------------------------------------------------------------------------------------------------
  -- interface_scredits
  -- This procedure calls all the relavnt procedures to insert data into Sales Credit and perform
  -- update on ra_interface_lines_all table
  -------------------------------------------------------------------------------------------------
  procedure interface_scredits(p_order_number in number default null, x_ret out varchar) is
    pragma autonomous_transaction;
    l_hdr_scredit_tbl oe_order_pub.header_scredit_tbl_type;
    x_header_scredit_rec oe_order_pub.header_scredit_rec_type;
    x_interface_line_rec oe_invoice_pub.ra_interface_lines_rec_type;
    x_interface_scredit_rec oe_invoice_pub.ra_interface_scredits_rec_type;
    cursor c is
      select interface_line_attribute6 price_adjustment_id
      from   ra_interface_lines_all a
      where      interface_line_context = 'ORDER ENTRY'
             and nvl(interface_status, '~') <> 'P'
             and line_type = 'FREIGHT'
             and interface_line_attribute1 = nvl(p_order_number, interface_line_attribute1)
             and not exists
                       (select 1
                        from   ra_interface_salescredits_all b
                        where      a.interface_line_context = b.interface_line_context
                               and a.interface_line_attribute1 = b.interface_line_attribute1
                               and a.interface_line_attribute2 = b.interface_line_attribute2
                               and a.interface_line_attribute3 = b.interface_line_attribute3
                               and a.interface_line_attribute4 = b.interface_line_attribute4
                               and a.interface_line_attribute5 = b.interface_line_attribute5
                               and a.interface_line_attribute6 = b.interface_line_attribute6
                               and a.interface_line_attribute7 = b.interface_line_attribute7
                               and a.interface_line_attribute8 = b.interface_line_attribute8
                               and a.interface_line_attribute9 = b.interface_line_attribute9
                               and a.interface_line_attribute10 = b.interface_line_attribute10
                               and a.interface_line_attribute11 = b.interface_line_attribute11
                               and a.interface_line_attribute12 = b.interface_line_attribute12
                               and a.interface_line_attribute13 = b.interface_line_attribute13
                               and a.interface_line_attribute14 = b.interface_line_attribute14
                               and a.interface_line_attribute15 = b.interface_line_attribute15)
             and exists
                   (select 1
                    from   oe_charge_lines_v c
                    where  a.interface_line_attribute6 = c.charge_id
                           and charge_name in
                                 (xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST2')
                                , xx_emf_pkg.get_paramater_value('XX_AR_INTERCO_SALESREP_UPDATE', 'PRICE_LIST1')));
  begin
    for i in c loop
      get_salesrep_info(i.price_adjustment_id, l_hdr_scredit_tbl, x_header_scredit_rec);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Price Adjustment ID:' || i.price_adjustment_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Count from l_hdr_scredit_tbl:' || l_hdr_scredit_tbl.count());
      get_interface_line_info(i.price_adjustment_id, x_interface_line_rec);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high
                         , 'Price adjustment ID from interface Lines:' || x_interface_line_rec.interface_line_attribute6);
      prepare_salescredit_rec(x_interface_line_rec, x_header_scredit_rec, x_interface_scredit_rec);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Salesrep_id:' || x_interface_scredit_rec.salesrep_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Salesgroup_id:' || x_interface_scredit_rec.sales_group_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high
                         , 'Price adjustment ID from sales credits:' || x_interface_scredit_rec.interface_line_attribute6);
      insert_scredits(x_interface_scredit_rec);
    end loop;
    update_reference_line(p_order_number);
    update_item_info(p_order_number);
    x_ret := 'S';
    commit;
  exception
    when others then
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Exception for Order Number :' || p_order_number);
      x_ret := 'E';
      rollback;
  end;
  -----------------------------------------------------------
  -- Main Procedure
  -----------------------------------------------------------
  procedure main_prc(x_errbuf out varchar2, x_retcode out varchar2, int_context in varchar2) is
    cursor glb_proc is
      select *
      from   ra_interface_lines_all
      where  interface_line_context = 'GLOBAL_PROCUREMENT' and nvl(interface_status, '~') <> 'P';
    cursor c_trx_line is
      select ril.interface_line_context, ril.interface_line_id, ril.primary_salesrep_id, interface_line_attribute1 order_number
           , interface_line_attribute2, interface_line_attribute3, interface_line_attribute4, interface_line_attribute5
           , ril.interface_line_attribute6 line_id, ril.interface_line_attribute7, ril.interface_line_attribute8
           , ril.interface_line_attribute9, ril.interface_line_attribute10, ril.interface_line_attribute11, ril.interface_line_attribute12
           , ril.interface_line_attribute13, ril.interface_line_attribute14, ril.interface_line_attribute15, ORIG_SYSTEM_BILL_CUSTOMER_ID
           , ORIG_SYSTEM_BILL_address_ID, ril.org_id
      from   apps.ra_interface_lines_all ril, apps.ra_cust_trx_types_all rct
      where      ril.cust_trx_type_id = rct.cust_trx_type_id
             and ril.batch_source_name = 'Intercompany'
             and ril.org_id = rct.org_id
             and interface_line_context in ('INTERCOMPANY', 'ORDER ENTRY')
             and nvl(interface_status, '~') <> 'P';
    cursor c_ord_line(p_line_id number) is
      select sold_to_org_id, org_id
      from   oe_order_lines_all
      where  line_id = p_line_id;
    cursor c_sales_rep(p_inv_org_id number
                     , p_org_id number
                     , p_acct_site_id in number) is
      select rep.salesrep_id, rep.name
      from   hz_cust_site_uses_all hau, hz_cust_acct_sites_all has, hz_cust_accounts hca, jtf_rs_salesreps rep
      where      hau.cust_acct_site_id = has.cust_acct_site_id
             and hau.site_use_code = 'BILL_TO'
             and hca.cust_account_id = has.cust_account_id
             and hau.primary_salesrep_id = rep.salesrep_id
             and hca.cust_account_id = p_inv_org_id
             and has.cust_acct_site_id = p_acct_site_id
             and has.org_id = p_org_id;
    cursor c_ra_intf_lines is
      select distinct a.interface_line_attribute1 order_number, a.org_id
      from   ra_interface_lines_all a
      where      a.line_type = case
                                 when nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'Y' then 'LINE'
                                 when nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'N' then 'FREIGHT'
                                 else line_type
                               end
             and a.interface_line_context = 'ORDER ENTRY'
             and case
                   when     nvl(oe_sys_parameters.value('OE_INVOICE_FREIGHT_AS_LINE', org_id), 'N') = 'Y'
                        and oe_sys_parameters.value('OE_INVENTORY_ITEM_FOR_FREIGHT', org_id) is not null
                        and line_type = 'LINE' then
                     oe_sys_parameters.value('OE_INVENTORY_ITEM_FOR_FREIGHT', org_id)
                   when line_type = 'FREIGHT' then
                     '0'
                 end = nvl(inventory_item_id, '0')
             and nvl(interface_status, '~') <> 'P';
    --J Jamner
    cursor ap_intf is
      select distinct a.invoice_id, d.source_line_id
      from   ap_invoices_interface a, ap_invoice_lines_interface d
      where      a.source = 'Intercompany'
             and a.reference_1 is not null
             and a.status <> 'PROCESSED'
             and a.invoice_id = d.invoice_id
             and d.source_application_id = 222
             and d.source_entity_code = 'TRANSACTIONS'
             and d.source_event_class_code = 'INTERCOMPANY_TRX'
             and exists
                   (select 1
                    from   ra_customer_trx_all b, ra_cust_trx_types_all c
                    where      a.reference_1 = b.customer_trx_id
                           and b.interface_header_context = 'GLOBAL_PROCUREMENT'
                           and b.cust_trx_type_id = c.cust_trx_type_id
                           and b.org_id = c.org_id);
    x_salesrep_id number;
    x_salesrep_name jtf_rs_salesreps.name%type;
    x_org_salesrep_name jtf_rs_salesreps.name%type;
    x_inv_org_id number;
    x_org_id number;
    x_rec_cntr number := 0;
    x_error_code number;
    x_customer_number oe_order_headers_v.customer_number%type;
    x_count number := 0;
    x_fail number := 0;
    x_uom varchar2(100);
    x_item varchar2(100);
    x_price_list varchar2(100);
    x_item_id number;
    l_not_valid exception;
    g_err varchar2(10);
    is_117_item varchar2(1);
  begin
    if int_context = 'AR' then
      x_error_code := xx_emf_pkg.set_env;
      for i in glb_proc loop
        if i.inventory_item_id is not null then
          is_117_item := xx_xla_custom_sources_pkg.is_117_approved_supp_list(i.inventory_item_id);
          if is_117_item = 'Y' then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'This is JJamner Invoice for Global Procurement, Changing the transaction type');
            update ra_interface_lines_all
            set    cust_trx_type_id = (select cust_trx_type_id
                                       from   ra_cust_trx_types_all
                                       where  name = 'JJamner-Intercompany'
                                              and org_id = (select organization_id
                                                            from   hr_operating_units
                                                            where  name = 'ILS Corporation'))
            where      nvl(interface_status, '~') <> 'P'
                   and interface_line_context = 'GLOBAL_PROCUREMENT'
                   and interface_line_attribute7 = i.interface_line_attribute7
                   and interface_line_attribute1 = i.interface_line_attribute1;
          end if;
        end if;
      end loop;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start of Salesrep Update for global procurement');
      update ra_interface_lines_all a
      set    primary_salesrep_id = (select rep.salesrep_id
                                    from   hz_cust_site_uses_all hau, hz_cust_acct_sites_all has, hz_cust_accounts hca, jtf_rs_salesreps rep
                                    where      hau.cust_acct_site_id = has.cust_acct_site_id
                                           and hau.site_use_code = 'BILL_TO'
                                           and hca.cust_account_id = has.cust_account_id
                                           and hau.primary_salesrep_id = rep.salesrep_id
                                           and hca.cust_account_id = a.orig_system_bill_customer_id
                                           and has.cust_acct_site_id = a.orig_system_bill_address_id
                                           and has.org_id = a.org_id)
      where  a.interface_line_context = 'GLOBAL_PROCUREMENT' and nvl(a.interface_status, '~') <> 'P';
      update ra_interface_salescredits_all a
      set    salesrep_id = (select primary_salesrep_id
                            from   ra_interface_lines_all b
                            where      b.interface_line_context = 'GLOBAL_PROCUREMENT'
                                   and nvl(b.interface_status, '~') <> 'P'
                                   and a.interface_line_context = b.interface_line_context
                                   and b.interface_line_attribute1 = nvl(a.interface_line_attribute1, b.interface_line_attribute1)
                                   and b.interface_line_attribute2 = nvl(a.interface_line_attribute2, b.interface_line_attribute2)
                                   and b.interface_line_attribute3 = nvl(a.interface_line_attribute3, b.interface_line_attribute3)
                                   and b.interface_line_attribute4 = nvl(a.interface_line_attribute4, b.interface_line_attribute4)
                                   and b.interface_line_attribute5 = nvl(a.interface_line_attribute5, b.interface_line_attribute5)
                                   and b.interface_line_attribute6 = nvl(a.interface_line_attribute6, b.interface_line_attribute6)
                                   and b.interface_line_attribute7 = nvl(a.interface_line_attribute7, b.interface_line_attribute7)
                                   and b.interface_line_attribute8 = nvl(a.interface_line_attribute8, b.interface_line_attribute8))
      where  A.interface_line_context = 'GLOBAL_PROCUREMENT' and nvl(A.interface_status, '~') <> 'P';
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, sql%rowcount || ' records updated for Salesrep Update for global procurement');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End of Salesrep Update for global procurement');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start of Salesrep Update for INTERCOMPANY');
      update ra_interface_lines_all a
      set    primary_salesrep_id = (select rep.salesrep_id
                                    from   hz_cust_site_uses_all hau, hz_cust_acct_sites_all has, hz_cust_accounts hca, jtf_rs_salesreps rep
                                    where      hau.cust_acct_site_id = has.cust_acct_site_id
                                           and hau.site_use_code = 'BILL_TO'
                                           and hca.cust_account_id = has.cust_account_id
                                           and hau.primary_salesrep_id = rep.salesrep_id
                                           and hca.cust_account_id = a.orig_system_bill_customer_id
                                           and has.cust_acct_site_id = a.orig_system_bill_address_id
                                           and has.org_id = A.org_id)
      where  a.interface_line_context = 'INTERCOMPANY' and nvl(a.interface_status, '~') <> 'P';
      update ra_interface_salescredits_all a
      set    salesrep_id = (select primary_salesrep_id
                            from   ra_interface_lines_all b
                            where      b.interface_line_context = 'INTERCOMPANY'
                                   and nvl(b.interface_status, '~') <> 'P'
                                   and a.interface_line_context = b.interface_line_context
                                   and b.interface_line_attribute1 = nvl(a.interface_line_attribute1, b.interface_line_attribute1)
                                   and b.interface_line_attribute2 = nvl(a.interface_line_attribute2, b.interface_line_attribute2)
                                   and b.interface_line_attribute3 = nvl(a.interface_line_attribute3, b.interface_line_attribute3)
                                   and b.interface_line_attribute4 = nvl(a.interface_line_attribute4, b.interface_line_attribute4)
                                   and b.interface_line_attribute5 = nvl(a.interface_line_attribute5, b.interface_line_attribute5)
                                   and b.interface_line_attribute6 = nvl(a.interface_line_attribute6, b.interface_line_attribute6)
                                   and b.interface_line_attribute7 = nvl(a.interface_line_attribute7, b.interface_line_attribute7)
                                   and b.interface_line_attribute8 = nvl(A.interface_line_attribute8, b.interface_line_attribute8)
                                   and b.interface_line_attribute9 = nvl(A.interface_line_attribute9, b.interface_line_attribute9)
                                   and b.interface_line_attribute15 = nvl(A.interface_line_attribute15, b.interface_line_attribute15))
      where  A.interface_line_context = 'INTERCOMPANY' and nvl(A.interface_status, '~') <> 'P';
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, sql%rowcount || ' records updated for Salesrep Update for INTERCOMPANY');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End of Salesrep Update for INTERCOMPANY');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start of Salesrep Update for ORDER ENTRY and Intercompany Batch Source');
      update ra_interface_lines_all a
      set    primary_salesrep_id = (select rep.salesrep_id
                                    from   hz_cust_site_uses_all hau, hz_cust_acct_sites_all has, hz_cust_accounts hca, jtf_rs_salesreps rep
                                    where      hau.cust_acct_site_id = has.cust_acct_site_id
                                           and hau.site_use_code = 'BILL_TO'
                                           and hca.cust_account_id = has.cust_account_id
                                           and hau.primary_salesrep_id = rep.salesrep_id
                                           and hca.cust_account_id = a.orig_system_bill_customer_id
                                           and has.cust_acct_site_id = a.orig_system_bill_address_id
                                           and has.org_id = A.org_id)
      where  A.interface_line_context = 'ORDER ENTRY' and nvl(A.interface_status, '~') <> 'P' and A.batch_source_name = 'Intercompany';
      update ra_interface_salescredits_all a
      set    salesrep_id = (select primary_salesrep_id
                            from   ra_interface_lines_all b
                            where      b.interface_line_context = 'ORDER ENTRY'
                                   and nvl(b.interface_status, '~') <> 'P'
                                   and b.batch_source_name = 'Intercompany'
                                   and a.interface_line_context = b.interface_line_context
                                   and b.interface_line_attribute1 = nvl(a.interface_line_attribute1, b.interface_line_attribute1)
                                   and b.interface_line_attribute2 = nvl(a.interface_line_attribute2, b.interface_line_attribute2)
                                   and b.interface_line_attribute3 = nvl(a.interface_line_attribute3, b.interface_line_attribute3)
                                   and b.interface_line_attribute4 = nvl(a.interface_line_attribute4, b.interface_line_attribute4)
                                   and b.interface_line_attribute5 = nvl(a.interface_line_attribute5, b.interface_line_attribute5)
                                   and b.interface_line_attribute6 = nvl(a.interface_line_attribute6, b.interface_line_attribute6)
                                   and b.interface_line_attribute7 = nvl(a.interface_line_attribute7, b.interface_line_attribute7)
                                   and b.interface_line_attribute8 = nvl(A.interface_line_attribute8, b.interface_line_attribute8)
                                   and b.interface_line_attribute9 = nvl(A.interface_line_attribute9, b.interface_line_attribute9)
                                   and b.interface_line_attribute10 = nvl(A.interface_line_attribute10, b.interface_line_attribute10)
                                   and b.interface_line_attribute11 = nvl(A.interface_line_attribute11, b.interface_line_attribute11)
                                   and b.interface_line_attribute12 = nvl(A.interface_line_attribute12, b.interface_line_attribute12)
                                   and b.interface_line_attribute13 = nvl(A.interface_line_attribute13, b.interface_line_attribute13)
                                   and b.interface_line_attribute14 = nvl(A.interface_line_attribute14, b.interface_line_attribute14))
      where  A.interface_line_context = 'ORDER ENTRY' and nvl(A.interface_status, '~') <> 'P'
             and exists
                   (select 1
                    from   ra_interface_lines_all b
                    where      b.interface_line_context = 'ORDER ENTRY'
                           and nvl(b.interface_status, '~') <> 'P'
                           and b.batch_source_name = 'Intercompany'
                           and a.interface_line_context = b.interface_line_context
                           and b.interface_line_attribute1 = nvl(a.interface_line_attribute1, b.interface_line_attribute1)
                           and b.interface_line_attribute2 = nvl(a.interface_line_attribute2, b.interface_line_attribute2)
                           and b.interface_line_attribute3 = nvl(a.interface_line_attribute3, b.interface_line_attribute3)
                           and b.interface_line_attribute4 = nvl(a.interface_line_attribute4, b.interface_line_attribute4)
                           and b.interface_line_attribute5 = nvl(a.interface_line_attribute5, b.interface_line_attribute5)
                           and b.interface_line_attribute6 = nvl(a.interface_line_attribute6, b.interface_line_attribute6)
                           and b.interface_line_attribute7 = nvl(a.interface_line_attribute7, b.interface_line_attribute7)
                           and b.interface_line_attribute8 = nvl(A.interface_line_attribute8, b.interface_line_attribute8)
                           and b.interface_line_attribute9 = nvl(A.interface_line_attribute9, b.interface_line_attribute9)
                           and b.interface_line_attribute10 = nvl(A.interface_line_attribute10, b.interface_line_attribute10)
                           and b.interface_line_attribute11 = nvl(A.interface_line_attribute11, b.interface_line_attribute11)
                           and b.interface_line_attribute12 = nvl(A.interface_line_attribute12, b.interface_line_attribute12)
                           and b.interface_line_attribute13 = nvl(A.interface_line_attribute13, b.interface_line_attribute13)
                           and b.interface_line_attribute14 = nvl(A.interface_line_attribute14, b.interface_line_attribute14));
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low
                         , sql%rowcount || ' records updated for Salesrep Update for Intercompany ORDER ENTRY Orders');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'End of Salesrep Update for Intercompany ORDER ENTRY Orders');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, '--------------------------------------------------------');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'PO Update for chargesheet orders');
      update ra_interface_lines_all rct
      set    purchase_order = (select cust_po_number
                               from   oe_order_headers_all oeh, oe_transaction_types_tl oet
                               where      rct.interface_line_attribute1 = oeh.order_number
                                      and rct.interface_line_attribute2 = oet.name
                                      and oeh.order_type_id = oet.transaction_type_Id
                                      and oet.name = 'ILS Charge Sheet Order'
                                      and oet.language = 'US')
      where      rct.purchase_order is null
             and nvl(rct.interface_status, '~') <> 'P'
             and rct.interface_line_context = 'ORDER ENTRY'
             and rct.interface_line_attribute2 = 'ILS Charge Sheet Order';
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, sql%rowcount || ' records updated for PO Update for chargesheet orders');
      update_reference_line;
      begin
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start of Freight Lines Update ');
        x_rec_cntr := 0;
        for c1 in c_ra_intf_lines loop
          begin
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, ' ');
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Processing for Order Number -  ' || c1.order_number);
            mo_global.set_policy_context('S', c1.org_id);
            --interface_scredits(c1.order_number, g_err);
            if g_err = 'S' then
              x_rec_cntr := x_rec_cntr + 1;
            else
              x_fail := x_fail + 1;
            end if;
          exception
            when others then
              x_fail := x_fail + 1;
          end;
        end loop;
        xx_emf_pkg.put_line(' ');
        xx_emf_pkg.put_line('************** Freight Line Update **************');
        xx_emf_pkg.put_line(' ');
        xx_emf_pkg.put_line('Total Freight Lines Updated  : ' || x_rec_cntr);
        xx_emf_pkg.put_line('Total Freight Lines Failed   : ' || x_fail);
        commit;
      end;
    elsif int_context = 'AP' then
      update ap_invoices_interface a
      set    (vendor_id
            , vendor_site_code
            , vendor_site_id
            , accts_pay_code_combination_id) = (select povs.vendor_id, povs.vendor_site_code, povs.vendor_site_id
                                                     , accts_pay_code_combination_id
                                                from   po_vendor_sites_all povs, po_vendors pov
                                                where      pov.vendor_name = 'J. JAMNER SURGICAL INSTRUMENTS, INC'
                                                       and povs.vendor_id = pov.vendor_id
                                                       and povs.org_id = a.org_id
                                                       and nvl(trunc(povs.inactive_date), trunc(sysdate)) >= trunc(sysdate))
      where  source = 'Intercompany' and reference_1 is not null and status <> 'PROCESSED'
             and exists
                   (select 1
                    from   ra_customer_trx_all b, ra_cust_trx_types_all c
                    where      a.reference_1 = b.customer_trx_id
                           and b.interface_header_context = 'GLOBAL_PROCUREMENT'
                           and b.cust_trx_type_id = c.cust_trx_type_id
                           and b.org_id = c.org_id
                           and c.name = 'JJamner-Intercompany');
      for i in ap_intf loop
        intg_ic_pricing_pkg.update_ic_accrual_acct(i.invoice_id, i.source_line_id);
      end loop;
    end if;
  end main_prc;
end xx_ar_upd_salesrep_pkg;
/
