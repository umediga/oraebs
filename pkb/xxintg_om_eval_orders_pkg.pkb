DROP PACKAGE BODY APPS.XXINTG_OM_EVAL_ORDERS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_OM_EVAL_ORDERS_PKG" as
  procedure debug_log(str in varchar2) is
  begin
    fnd_file.put_line(fnd_file.log, str);
    dbms_output.put_line(str);
  end debug_log;

  procedure log_errors(p_pkg_name in varchar2 default 'xxintg_om_eval_orders_pkg'
                     , p_proc_name in varchar2
                     , p_header_id in number
                     , p_line_id in number
                     , p_date in date
                     , p_msg in varchar2) is
  begin
    insert into xxintg_om_eval_errors(package_name
                                    , procedure_name
                                    , header_id
                                    , line_id
                                    , error_date
                                    , message)
    values      (p_pkg_name
               , p_proc_name
               , p_header_id
               , p_line_id
               , p_date
               , p_msg);
  exception
    when others then
      debug_log(str => 'error occured in inserting errors');
  end log_errors;

  procedure set_line_status(p_line_id in number, p_line_status in varchar2, x_return_status out varchar2) is
    l_line_id varchar2(30);
    l_debug_log_level constant number := oe_debug_pub.g_debug_level;
    l_eval_return_line_id number;
    l_eval_days number;
    l_header_id number;
  begin
    l_line_id := p_line_id;
    select header_id
    into   l_header_id
    from   oe_order_lines_all
    where  line_id = l_line_id;
    oe_order_wf_util.
    update_flow_status_code(p_header_id => null
                          , p_line_id => l_line_id
                          , p_flow_status_code => p_line_status
                          , x_return_status => x_return_status);

    if p_line_status in('INTG_UNDER_EVAL','INTG_UNDER_RENTAL') then
      begin
        select max(line_id)
        into   l_eval_return_line_id
        from   oe_order_lines_all
        where      line_category_code = 'RETURN'
               and nvl(cancelled_flag, 'N') = 'N'
               and open_flag = 'Y'
               and return_context = 'ORDER'
               and return_attribute1 = l_header_id
               and return_attribute2 = l_line_id;
      exception
        when others then
          begin
            select max(line_id)
            into   l_eval_return_line_id
            from   oe_order_lines_all
            where      source_document_line_id = l_line_id
                   and line_category_code = 'RETURN'
                   and nvl(cancelled_flag, 'N') = 'N'
                   and open_flag = 'Y'
                   and order_source_id in (select order_source_id
                                          from   oe_order_sources
                                          where  name in ('Rental Orders','Evaluation Orders'));
          exception
            when others then
              log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                       , p_proc_name => 'set_line_status'
                       , p_header_id => null
                       , p_line_id => l_line_id
                       , p_date => sysdate
                       , p_msg => 'No Return Lines Found for :' || l_line_id);
          end;
      end;

      create_lot_serials(p_line_id, l_eval_return_line_id, x_return_status);
    end if;
  exception
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'set_line_status'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Unable to set the line status for :' || p_line_status);
      raise;
  end set_line_status;

  procedure set_line_status_wf(p_itemtype in varchar2
                             , p_itemkey in varchar2
                             , p_actid in number
                             , p_funcmode in varchar2
                             , p_result in out varchar2) is
    l_line_id varchar2(30);
    l_debug_log_level constant number := oe_debug_pub.g_debug_level;
    l_return_status varchar2(1);
    l_line_status varchar2(30);
    x_return_status varchar2(1);
    l_org_id number;
    l_line_type varchar2(30);
    l_line_type_id number;
  begin
    if (p_funcmode = 'RUN') then
      l_line_id := to_number(p_itemkey);
      select org_id, line_type_id
      into   l_org_id, l_line_type_id
      from   oe_order_lines_all
      where  line_id = l_line_id;
      mo_global.set_policy_context('S', l_org_id);
      select name
      into   l_line_type
      from   oe_transaction_types_tl
      where  transaction_type_id = l_line_type_id and language = 'US';

      if l_line_type = 'ILS Eval Line' then
        l_line_status := 'INTG_UNDER_EVAL';
      elsif l_line_type = 'ILS Rental Line' then
        l_line_status := 'INTG_UNDER_RENTAL';
      end if;

      set_line_status(l_line_id, l_line_status, x_return_status);
      p_result := 'COMPLETE';
    end if;
  exception
    when others then
      p_result := 'ERROR';
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'set_line_status_wf'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Unable to set the line status for :' || l_line_status);
      wf_core.context('OE_LINE_WF'
                    , 'Set Loan Line Status WF'
                    , p_itemtype
                    , p_itemkey
                    , p_actid
                    , p_funcmode);
      raise;
  end set_line_status_wf;

  procedure create_lot_serials(p_eval_line_id in number, p_return_line_id in number, x_return_status out varchar2) is
    cursor c1(p_line_id in number) is
      select mut.serial_number
      from   mtl_unit_transactions mut, mtl_material_transactions mmt, wsh_delivery_details wdd
      where      mmt.transaction_id = mut.transaction_id
             and mmt.trx_source_line_id = wdd.source_line_id
             and mmt.picking_line_id = wdd.delivery_detail_id
             and wdd.source_line_id = p_line_id;

    v_msg_index_out number;
    v_message varchar2(4000);
    l_line_id number;
    l_workflow_status varchar2(30);
    l_result_out number; --varchar2(30);
    l_msg_count number := 0;
    l_msg_data varchar2(240);
    --x_return_status varchar2(30);
    x_msg_count number;
    x_msg_data varchar2(240);
    l_line_tbl oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
    l_old_line_tbl oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
    l_control_rec oe_globals.control_rec_type;
    l_x_header_rec oe_order_pub.header_rec_type := oe_order_pub.g_miss_header_rec;
    l_x_header_adj_rec oe_order_pub.header_adj_rec_type;
    l_x_header_adj_tbl oe_order_pub.header_adj_tbl_type := oe_order_pub.g_miss_header_adj_tbl;
    l_x_header_scredit_rec oe_order_pub.header_scredit_rec_type;
    l_x_header_scredit_tbl oe_order_pub.header_scredit_tbl_type := oe_order_pub.g_miss_header_scredit_tbl;
    l_x_line_rec oe_order_pub.line_rec_type;
    l_old_line_rec oe_order_pub.line_rec_type;
    l_x_line_adj_rec oe_order_pub.line_adj_rec_type;
    l_x_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    l_x_line_scredit_rec oe_order_pub.line_scredit_rec_type;
    l_x_line_scredit_tbl oe_order_pub.line_scredit_tbl_type := oe_order_pub.g_miss_line_scredit_tbl;
    l_lot_serial_tbl oe_order_pub.lot_serial_tbl_type := oe_order_pub.g_miss_lot_serial_tbl;
    l_x_header_price_att_tbl oe_order_pub.header_price_att_tbl_type := oe_order_pub.g_miss_header_price_att_tbl;
    l_x_header_adj_att_tbl oe_order_pub.header_adj_att_tbl_type := oe_order_pub.g_miss_header_adj_att_tbl;
    l_x_header_adj_assoc_tbl oe_order_pub.header_adj_assoc_tbl_type := oe_order_pub.g_miss_header_adj_assoc_tbl;
    l_x_line_price_att_tbl oe_order_pub.line_price_att_tbl_type := oe_order_pub.g_miss_line_price_att_tbl;
    l_x_line_adj_att_tbl oe_order_pub.line_adj_att_tbl_type := oe_order_pub.g_miss_line_adj_att_tbl;
    l_x_line_adj_assoc_tbl oe_order_pub.line_adj_assoc_tbl_type := oe_order_pub.g_miss_line_adj_assoc_tbl;
    l_x_action_request_tbl oe_order_pub.request_tbl_type := oe_order_pub.g_miss_request_tbl;
    l_x_header_payment_tbl oe_order_pub.header_payment_tbl_type;
    l_x_line_payment_tbl oe_order_pub.line_payment_tbl_type;
    --
    l_debug_level constant number := oe_debug_pub.g_debug_level;
    l_new_request_date date;
    l_eval_days number;
    l_order_number number;
    l_trx_date date;
    ls_index number;
    j number;
    l_ship_from_org_id number;
    l_return_subinventory varchar2(100);
    l_returnable varchar2(100);
    non_return_exp exception;
  --
  begin
    l_old_line_tbl.delete;
    oe_line_util.query_row(p_line_id => p_eval_line_id, x_line_rec => l_old_line_rec);

    begin
      select a.segment2, b.order_number
      into   l_eval_days, l_order_number
      from   xxintg_om_hdr_add_info a, oe_order_headers_all b
      where  b.header_id = l_old_line_rec.header_id and b.context = 'Eval' and b.attribute11 = a.code_combination_id;
    exception
      when others then
        l_eval_days := 0;
    end;

    begin
      l_trx_date := nvl(l_old_line_rec.actual_shipment_date, l_old_line_rec.request_date) + l_eval_days;
    exception
      when others then
        l_trx_date := l_old_line_rec.request_date;
    end;

    begin
      select attribute15, attribute13
      into   l_ship_from_org_id, l_return_subinventory
      from   fnd_lookup_values_vl
      where  lookup_type = 'INTG_REPAIR_POOL_DEF_RET_ORG'
             and lookup_code =
                   (select segment1
                    from   mtl_system_items_b
                    where  inventory_item_id = l_old_line_rec.inventory_item_id
                           and organization_id =
                                 nvl(l_old_line_rec.ship_from_org_id
                                   , oe_sys_parameters.value('MASTER_ORGANIZATION_ID', l_old_line_rec.org_id)));
      select returnable_flag
      into   l_returnable
      from   mtl_system_items_b
      where  inventory_item_id = l_old_line_rec.inventory_item_id and organization_id = l_ship_from_org_id;

      if l_returnable = 'N' then
        raise non_return_exp;
      end if;
    exception
      when non_return_exp then
        l_ship_from_org_id := l_old_line_rec.ship_from_org_id;
      when others then
        l_ship_from_org_id := l_old_line_rec.ship_from_org_id;
    end;

    l_line_tbl := oe_order_pub.g_miss_line_tbl;
    l_control_rec.controlled_operation := true;
    l_control_rec.default_attributes := false;
    l_control_rec.change_attributes := false;
    l_line_tbl(1) := oe_order_pub.g_miss_line_rec;
    l_line_tbl(1).line_id := p_return_line_id;
    l_line_tbl(1).change_reason := 'No reason provided';
    l_line_tbl(1).operation := oe_globals.g_opr_update;
    l_line_tbl(1).request_date := l_trx_date;
    l_line_tbl(1).subinventory := l_return_subinventory;
    ls_index := 1;
    j := 1;

    for i in c1(p_eval_line_id) loop
      l_lot_serial_tbl(ls_index).lot_number := fnd_api.g_miss_char;
      l_lot_serial_tbl(ls_index).lot_serial_id := fnd_api.g_miss_num;
      l_lot_serial_tbl(ls_index).quantity := 1;
      l_lot_serial_tbl(ls_index).from_serial_number := i.serial_number;
      l_lot_serial_tbl(ls_index).to_serial_number := i.serial_number;
      l_lot_serial_tbl(ls_index).operation := oe_globals.g_opr_create;
      l_lot_serial_tbl(ls_index).line_id := p_return_line_id;
      l_lot_serial_tbl(ls_index).line_index := j;
      ls_index := ls_index + 1;
      j := j + 1;
    end loop;

    oe_order_pvt.process_order(p_api_version_number => 1.0
                             , p_init_msg_list => fnd_api.g_true
                             , x_return_status => x_return_status
                             , x_msg_count => x_msg_count
                             , x_msg_data => x_msg_data
                             , p_control_rec => l_control_rec
                             , p_x_line_tbl => l_line_tbl
                             , p_x_header_rec => l_x_header_rec
                             , p_x_header_adj_tbl => l_x_header_adj_tbl
                             , p_x_header_price_att_tbl => l_x_header_price_att_tbl
                             , p_x_header_adj_att_tbl => l_x_header_adj_att_tbl
                             , p_x_header_adj_assoc_tbl => l_x_header_adj_assoc_tbl
                             , p_x_header_scredit_tbl => l_x_header_scredit_tbl
                             , p_x_header_payment_tbl => l_x_header_payment_tbl
                             , p_x_line_adj_tbl => l_x_line_adj_tbl
                             , p_x_line_price_att_tbl => l_x_line_price_att_tbl
                             , p_x_line_adj_att_tbl => l_x_line_adj_att_tbl
                             , p_x_line_adj_assoc_tbl => l_x_line_adj_assoc_tbl
                             , p_x_line_scredit_tbl => l_x_line_scredit_tbl
                             , p_x_line_payment_tbl => l_x_line_payment_tbl
                             , p_x_lot_serial_tbl => l_lot_serial_tbl
                             , p_x_action_request_tbl => l_x_action_request_tbl);

    --dbms_output.put_line('x_return_status: ' || x_return_status);
    if x_return_status = fnd_api.g_ret_sts_unexp_error then
      --dbms_output.put_line('fnd_api.g_ret_sts_unexp_error');
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'Unable to update return line for :' || p_return_line_id || ' using eval line ID' || p_eval_line_id);
      raise fnd_api.g_exc_unexpected_error;
    elsif x_return_status = fnd_api.g_ret_sts_error then
      --dbms_output.put_line('fnd_api.g_ret_sts_error');
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'Unable to update return line for :' || p_return_line_id || ' using eval line ID' || p_eval_line_id);
      raise fnd_api.g_exc_error;
    end if;

    if x_msg_count > 0 then
      --dbms_output.put_line(x_msg_count);
      for v_index in 1 .. x_msg_count loop
        oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        v_message := substr(x_msg_data, 1, 200);
      -- dbms_output.put_line(x_msg_data);
      end loop;

      --dbms_output.put_line(v_message);
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => v_message);
    end if;
  exception
    when fnd_api.g_exc_unexpected_error then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'Unexpected Error in Order Line Update for returns');
    when fnd_api.g_exc_error then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'In Error Exception in Order Line for Returns');
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'In others exception in Update for returns');
  end create_lot_serials;

  procedure create_eval_return_line(p_line_id in number, x_return_status out varchar2) is
    v_msg_index_out number;
    v_message varchar2(4000);
    l_line_id number;
    l_workflow_status varchar2(30);
    l_result_out number; --varchar2(30);
    l_msg_count number := 0;
    l_msg_data varchar2(240);
    --x_return_status varchar2(30);
    x_msg_count number;
    x_msg_data varchar2(240);
    l_line_tbl oe_order_pub.line_tbl_type;
    l_old_line_tbl oe_order_pub.line_tbl_type;
    l_control_rec oe_globals.control_rec_type;
    l_x_header_rec oe_order_pub.header_rec_type;
    l_x_header_adj_rec oe_order_pub.header_adj_rec_type;
    l_x_header_adj_tbl oe_order_pub.header_adj_tbl_type;
    l_x_header_scredit_rec oe_order_pub.header_scredit_rec_type;
    l_x_header_scredit_tbl oe_order_pub.header_scredit_tbl_type;
    l_x_line_rec oe_order_pub.line_rec_type;
    l_old_line_rec oe_order_pub.line_rec_type;
    l_x_line_adj_rec oe_order_pub.line_adj_rec_type;
    l_x_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    l_x_line_scredit_rec oe_order_pub.line_scredit_rec_type;
    l_x_line_scredit_tbl oe_order_pub.line_scredit_tbl_type;
    l_x_lot_serial_tbl oe_order_pub.lot_serial_tbl_type;
    l_x_header_price_att_tbl oe_order_pub.header_price_att_tbl_type;
    l_x_header_adj_att_tbl oe_order_pub.header_adj_att_tbl_type;
    l_x_header_adj_assoc_tbl oe_order_pub.header_adj_assoc_tbl_type;
    l_x_line_price_att_tbl oe_order_pub.line_price_att_tbl_type;
    l_x_line_adj_att_tbl oe_order_pub.line_adj_att_tbl_type;
    l_x_line_adj_assoc_tbl oe_order_pub.line_adj_assoc_tbl_type;
    l_x_action_request_tbl oe_order_pub.request_tbl_type;
    l_x_header_payment_tbl oe_order_pub.header_payment_tbl_type;
    l_x_line_payment_tbl oe_order_pub.line_payment_tbl_type;
    --
    l_debug_level constant number := oe_debug_pub.g_debug_level;
    l_new_request_date date;
    l_eval_days number;
    l_order_number number;
    l_order_source_id number;
    l_line_type_id number;
    l_ship_from_org_id number;
    l_returnable varchar2(1);
    l_return_subinventory varchar2(30);
    l_line_type_name varchar2(30);
    non_return_exp exception;
  --
  begin
    if l_debug_level > 0 then
      oe_debug_pub.add('ENTERING xxintg_om_eval_orders_pkg.CREATE_RETURN_LINE', 1);
    end if;

    l_line_id := p_line_id;
    oe_line_util.query_row(p_line_id => l_line_id, x_line_rec => l_old_line_rec);
    
    begin
    select name into l_line_type_name from oe_line_types_v
    where line_type_id=l_old_line_rec.line_type_id;    
    exception when others then
    null;
    end;

    begin
      select a.segment2, b.order_number
      into   l_eval_days, l_order_number
      from   xxintg_om_hdr_add_info a, oe_order_headers_all b
      where  b.header_id = l_old_line_rec.header_id and b.context = 'Eval' and b.attribute11 = a.code_combination_id;
    exception
      when others then
        l_eval_days := 0;
    end;

if l_line_type_name='ILS Eval Line' then
    begin
      select line_type_id
      into   l_line_type_id
      from   oe_line_types_v
      where  name = 'ILS Eval Returns';
    exception
      when others then
        l_line_type_id := 0;

        if l_debug_level > 0 then
          oe_debug_pub.add('INTG: ILS Eval Returns line type is not setup', 1);
          x_return_status := 'E';
        end if;
    end;

    begin
      select order_source_id
      into   l_order_source_id
      from   oe_order_sources
      where  name = 'Evaluation Orders';
    exception
      when others then
        l_order_source_id := 2;
    end;
elsif l_line_type_name='ILS Rental Line' then
 begin
      select line_type_id
      into   l_line_type_id
      from   oe_line_types_v
      where  name = 'ILS Rental Return Line';
    exception
      when others then
        l_line_type_id := 0;

        if l_debug_level > 0 then
          oe_debug_pub.add('INTG: ILS Rental Returns line type is not setup', 1);
          x_return_status := 'E';
        end if;
    end;

    begin
      select order_source_id
      into   l_order_source_id
      from   oe_order_sources
      where  name = 'Rental Orders';
    exception
      when others then
        l_order_source_id := 2;
    end;
end if;
    begin
      select attribute15, attribute13
      into   l_ship_from_org_id, l_return_subinventory
      from   fnd_lookup_values_vl
      where  lookup_type = 'INTG_REPAIR_POOL_DEF_RET_ORG'
             and lookup_code =
                   (select segment1
                    from   mtl_system_items_b
                    where  inventory_item_id = l_old_line_rec.inventory_item_id
                           and organization_id =
                                 nvl(l_old_line_rec.ship_from_org_id
                                   , oe_sys_parameters.value('MASTER_ORGANIZATION_ID', l_old_line_rec.org_id)));
      select returnable_flag
      into   l_returnable
      from   mtl_system_items_b
      where  inventory_item_id = l_old_line_rec.inventory_item_id and organization_id = l_ship_from_org_id;

      if l_returnable = 'N' then
        raise non_return_exp;
      end if;
    exception
      when non_return_exp then
        l_ship_from_org_id := l_old_line_rec.ship_from_org_id;
      when others then
        l_ship_from_org_id := l_old_line_rec.ship_from_org_id;
    end;

    l_line_tbl := oe_order_pub.g_miss_line_tbl;
    l_new_request_date := l_old_line_rec.request_date + l_eval_days;
    l_line_tbl(1) := l_old_line_rec;

    if l_line_type_id is not null then
      l_line_tbl(1).line_type_id := l_line_type_id;
    end if;

if l_line_type_name='ILS Eval Line' then
    l_line_tbl(1).return_reason_code := 'EVAL RETURN';
    elsif l_line_type_name='ILS Rental Line' then
    l_line_tbl(1).return_reason_code := 'RENTAL RETURN';  
    end if;  
    l_line_tbl(1).line_category_code := 'RETURN';
    l_line_tbl(1).booked_flag := fnd_api.g_miss_char;
    l_line_tbl(1).cancelled_flag := fnd_api.g_miss_char;
    l_line_tbl(1).open_flag := fnd_api.g_miss_char;
    l_line_tbl(1).shipping_interfaced_flag := fnd_api.g_miss_char;
    l_line_tbl(1).invoice_interface_status_code := fnd_api.g_miss_char;
    l_line_tbl(1).model_remnant_flag := fnd_api.g_miss_char;
    l_line_tbl(1).flow_status_code := 'ENTERED';
    l_line_tbl(1).fulfilled_flag := fnd_api.g_miss_char;
    l_line_tbl(1).cancelled_quantity := fnd_api.g_miss_num;
    l_line_tbl(1).reserved_quantity := fnd_api.g_miss_num;
    l_line_tbl(1).fulfilled_quantity := fnd_api.g_miss_num;
    l_line_tbl(1).shipped_quantity := fnd_api.g_miss_num;
    l_line_tbl(1).promise_date := fnd_api.g_miss_date;
    l_line_tbl(1).earliest_acceptable_date := fnd_api.g_miss_date;
    l_line_tbl(1).latest_acceptable_date := fnd_api.g_miss_date;
    l_line_tbl(1).schedule_ship_date := fnd_api.g_miss_date;
    l_line_tbl(1).schedule_arrival_date := fnd_api.g_miss_date;
    l_line_tbl(1).actual_shipment_date := fnd_api.g_miss_date;
    l_line_tbl(1).actual_arrival_date := fnd_api.g_miss_date;
    l_line_tbl(1).fulfillment_date := fnd_api.g_miss_date;
    l_line_tbl(1).request_date := l_new_request_date;
    l_line_tbl(1).ship_from_org_id := nvl(l_ship_from_org_id, l_old_line_rec.ship_from_org_id);
    l_line_tbl(1).subinventory := l_return_subinventory;
    l_line_tbl(1).return_context := 'ORDER';
    l_line_tbl(1).return_attribute1 := l_old_line_rec.header_id;
    l_line_tbl(1).return_attribute2 := l_old_line_rec.line_id;
    l_line_tbl(1).cust_po_number := l_old_line_rec.cust_po_number;
    l_line_tbl(1).reference_line_id := l_old_line_rec.line_id;
    l_line_tbl(1).reference_type := 'ORDER';
    l_line_tbl(1).reference_header_id := l_old_line_rec.header_id;
    l_line_tbl(1).order_source_id := l_order_source_id;
    l_line_tbl(1).source_document_type_id := l_order_source_id;
    l_line_tbl(1).source_document_id := l_old_line_rec.header_id;
    l_line_tbl(1).source_document_line_id := l_old_line_rec.line_id;
    l_line_tbl(1).orig_sys_document_ref := l_order_number;
    l_line_tbl(1).orig_sys_line_ref := l_old_line_rec.line_number;
    l_line_tbl(1).orig_sys_shipment_ref := fnd_api.g_miss_char;
    l_line_tbl(1).calculate_price_flag := 'N';
    --
    l_line_tbl(1).shipment_number := fnd_api.g_miss_num;
    l_line_tbl(1).option_number := fnd_api.g_miss_num;
    l_line_tbl(1).line_number := fnd_api.g_miss_num;
    l_line_tbl(1).service_number := fnd_api.g_miss_num;
    l_line_tbl(1).component_number := fnd_api.g_miss_num;
    l_line_tbl(1).line_id := fnd_api.g_miss_num;
    --  Set Operation.
    l_line_tbl(1).operation := oe_globals.g_opr_create;
    --  Set control flags.
    l_control_rec.controlled_operation := true;
    l_control_rec.validate_entity := true;
    l_control_rec.write_to_db := true;
    l_control_rec.default_attributes := true;
    l_control_rec.change_attributes := true;
    l_control_rec.clear_dependents := true;
    --  Instruct API to retain its caches
    l_control_rec.clear_api_cache := false;
    l_control_rec.clear_api_requests := false;
    --  Set control flags.
    --  Call OE_Order_PVT.Process_order
    oe_order_pvt.process_order(p_api_version_number => 1.0
                             , p_init_msg_list => fnd_api.g_true
                             , x_return_status => x_return_status
                             , x_msg_count => x_msg_count
                             , x_msg_data => x_msg_data
                             , p_control_rec => l_control_rec
                             , p_x_line_tbl => l_line_tbl
                             , p_x_header_rec => l_x_header_rec
                             , p_x_header_adj_tbl => l_x_header_adj_tbl
                             , p_x_header_price_att_tbl => l_x_header_price_att_tbl
                             , p_x_header_adj_att_tbl => l_x_header_adj_att_tbl
                             , p_x_header_adj_assoc_tbl => l_x_header_adj_assoc_tbl
                             , p_x_header_scredit_tbl => l_x_header_scredit_tbl
                             , p_x_header_payment_tbl => l_x_header_payment_tbl
                             , p_x_line_adj_tbl => l_x_line_adj_tbl
                             , p_x_line_price_att_tbl => l_x_line_price_att_tbl
                             , p_x_line_adj_att_tbl => l_x_line_adj_att_tbl
                             , p_x_line_adj_assoc_tbl => l_x_line_adj_assoc_tbl
                             , p_x_line_scredit_tbl => l_x_line_scredit_tbl
                             , p_x_line_payment_tbl => l_x_line_payment_tbl
                             , p_x_lot_serial_tbl => l_x_lot_serial_tbl
                             , p_x_action_request_tbl => l_x_action_request_tbl);

    --dbms_output.put_line('x_return_status: ' || x_return_status);
    if x_return_status = fnd_api.g_ret_sts_unexp_error then
      --dbms_output.put_line('fnd_api.g_ret_sts_unexp_error');
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_return_line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Unable to create return line for for :' || l_line_id);
      raise fnd_api.g_exc_unexpected_error;
    elsif x_return_status = fnd_api.g_ret_sts_error then
      --dbms_output.put_line('fnd_api.g_ret_sts_error');
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_return_line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Unable to create return line for for :' || l_line_id);
      raise fnd_api.g_exc_error;
    end if;

    if x_msg_count > 0 then
      --dbms_output.put_line(x_msg_count);
      for v_index in 1 .. x_msg_count loop
        oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        v_message := substr(x_msg_data, 1, 200);
      --dbms_output.put_line(x_msg_data);
      end loop;

      --dbms_output.put_line(v_message);
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_return_line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => v_message);
    end if;

    --  Load OUT parameters.
    l_x_line_rec := l_line_tbl(1);
  exception
    when fnd_api.g_exc_unexpected_error then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_return_line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Unexpected Error in Order Line Creation');
    when fnd_api.g_exc_error then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_return_line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'In Error Exception in Order Line Creation');
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_return_line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'In others exception');
  end create_eval_return_line;

  procedure copy_line(p_line_id in number, p_line_type_id in number, p_line_type_name in varchar2, x_return_status out varchar2) is
    x_header_id number;
    x_msg_count number;
    x_msg_data varchar2(4000);
    v_msg_index_out number;
    v_message varchar2(4000);
    l_header_id number;
    l_line_tbl oe_globals.selected_record_tbl;
    l_hdr_tbl oe_globals.selected_record_tbl;
    x_copy_rec oe_order_copy_util.copy_rec_type;
  begin
    select header_id
    into   l_header_id
    from   oe_order_lines_all
    where  line_id = p_line_id;
    l_hdr_tbl(1).id1 := l_header_id;
    l_line_tbl(1).id1 := p_line_id;
    x_copy_rec.init_msg_list := fnd_api.g_false;
    x_copy_rec.commit := fnd_api.g_false;
    x_copy_rec.copy_order := fnd_api.g_false;
    x_copy_rec.hdr_info := fnd_api.g_false;
    x_copy_rec.hdr_descflex := fnd_api.g_false;
    x_copy_rec.hdr_scredits := fnd_api.g_false;
    x_copy_rec.hdr_attchmnts := fnd_api.g_false;
    x_copy_rec.hdr_holds := fnd_api.g_false;
    x_copy_rec.hdr_credit_card_details := fnd_api.g_false;
    x_copy_rec.all_lines := fnd_api.g_false;
    x_copy_rec.incl_cancelled := fnd_api.g_false;
    x_copy_rec.line_price_mode := oe_order_copy_util.g_cpy_orig_price;
    x_copy_rec.line_price_date := fnd_api.g_miss_date;
    x_copy_rec.line_descflex := fnd_api.g_true;
    x_copy_rec.line_scredits := fnd_api.g_true;
    x_copy_rec.line_attchmnts := fnd_api.g_true;
    x_copy_rec.line_fulfill_sets := fnd_api.g_false;
    x_copy_rec.line_ship_arr_sets := fnd_api.g_false;
    x_copy_rec.append_to_header_id := l_hdr_tbl(1).id1;
    x_copy_rec.line_type := p_line_type_id;
    x_copy_rec.line_count := 1;

    if p_line_type_name = 'ILS Eval Line' then
      x_copy_rec.return_reason_code := 'EVAL RETURN';
    end if;

    x_copy_rec.source_block_type := 'LINE';
    x_copy_rec.source_org_id := fnd_global.org_id;
    x_copy_rec.copy_org_id := fnd_global.org_id;
    --x_copy_rec.hdr_type := 1033;
    x_copy_rec.default_null_values := 'Y';
    x_copy_rec.api_version_number := 1.0;
    oe_order_copy_util.copy_order(p_copy_rec => x_copy_rec
                                , p_hdr_id_tbl => l_hdr_tbl
                                , p_line_id_tbl => l_line_tbl
                                , x_header_id => x_header_id
                                , x_return_status => x_return_status
                                , x_msg_count => x_msg_count
                                , x_msg_data => x_msg_data);

    if x_msg_count > 0 then
      for v_index in 1 .. x_msg_count loop
        v_message := null;
        oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        v_message := substr(x_msg_data, 1, 200);
        log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                 , p_proc_name => 'copy_return_line'
                 , p_header_id => null
                 , p_line_id => p_line_id
                 , p_date => sysdate
                 , p_msg => v_message);
      end loop;
    end if;
  end;

  procedure create_return_line(p_itemtype in varchar2
                             , p_itemkey in varchar2
                             , p_actid in number
                             , p_funcmode in varchar2
                             , p_result in out varchar2) is
    l_line_id varchar2(30);
    l_debug_log_level constant number := oe_debug_pub.g_debug_level;
    l_return_status varchar2(1);
    l_line_status varchar2(30);
    x_return_status varchar2(1);
    l_org_id number;
    l_line_type varchar2(30);
    l_line_type_id number;
  begin
    if (p_funcmode = 'RUN') then
      l_line_id := to_number(p_itemkey);
      select org_id
      into   l_org_id
      from   oe_order_lines_all
      where  line_id = l_line_id;
      mo_global.set_policy_context('S', l_org_id);
      select name
      into   l_line_type
      from   oe_line_types_v
      where  line_type_id = (select line_type_id
                             from   oe_order_lines_all
                             where  line_id = l_line_id);

      if l_line_type = 'ILS Eval Line' then
        select line_type_id
        into   l_line_type_id
        from   oe_line_types_v
        where  name = 'ILS Eval Returns';
        --copy_line(l_line_id, l_line_type_id, l_line_type, x_return_status);
        create_eval_return_line(l_line_id, x_return_status);
      elsif l_line_type = 'ILS Rental Line' then
        create_eval_return_line(l_line_id, x_return_status);
      --copy_line(l_line_id, l_line_type_id, l_line_type, x_return_status);
      end if;

      if x_return_status = fnd_api.g_ret_sts_success then
        p_result := 'COMPLETE';
      else
        p_result := 'ERROR';
      end if;
    end if;
  exception
    when others then
      p_result := 'ERROR';
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_return_line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Unable to create return line for for :' || l_line_id);
      wf_core.context('OE_LINE_WF'
                    , 'Set Loan Line Status WF'
                    , p_itemtype
                    , p_itemkey
                    , p_actid
                    , p_funcmode);
      raise;
  end create_return_line;

  function line_shipment_option(p_line_id in number)
    return varchar2 is
    l_line_number varchar2(100);
    line_number number;
    shipment_number number;
    option_number number;
    component_number number;
    service_number number;
    p_concat_value varchar2(100);
  begin
    begin
      select line_number, shipment_number, option_number, component_number, service_number
      into   line_number, shipment_number, option_number, component_number, service_number
      from   oe_order_lines_all
      where  line_id = p_line_id;
    exception
      when others then
        p_concat_value := '1.1';
    end;

    if service_number is not null then
      if option_number is not null then
        if component_number is not null then
          p_concat_value :=    line_number
                            || '.'
                            || shipment_number
                            || '.'
                            || option_number
                            || '.'
                            || component_number
                            || '.'
                            || service_number;
        else
          p_concat_value := line_number || '.' || shipment_number || '.' || option_number || '..' || service_number;
        end if;
      --- if a option is not attached
      else
        if component_number is not null then
          p_concat_value := line_number || '.' || shipment_number || '..' || component_number || '.' || service_number;
        else
          p_concat_value := line_number || '.' || shipment_number || '...' || service_number;
        end if;
      end if; /* if option number is not null */
    -- if the service number is null
    else
      if option_number is not null then
        if component_number is not null then
          p_concat_value := line_number || '.' || shipment_number || '.' || option_number || '.' || component_number;
        else
          p_concat_value := line_number || '.' || shipment_number || '.' || option_number;
        end if;
      --- if a option is not attached
      else
        if component_number is not null then
          p_concat_value := line_number || '.' || shipment_number || '..' || component_number;
        else
          p_concat_value := line_number || '.' || shipment_number;
        end if;
      end if; /* if option number is not null */
    end if; /* if service number is not null */

    return p_concat_value;
  exception
    when others then
      p_concat_value := '1.1';
      return p_concat_value;
  end line_shipment_option;

  procedure update_instance(p_instance_id in number
                          , p_txn_rec     csi_datastructures_pub.transaction_rec
                          , x_return_status   out varchar2
                          , x_msg_count   out nocopy number
                          , x_msg_data   out nocopy varchar2) is
    l_new_instance_rec csi_datastructures_pub.instance_rec;
    l_party_tbl csi_datastructures_pub.party_tbl;
    l_account_tbl csi_datastructures_pub.party_account_tbl;
    l_version_label_rec csi_datastructures_pub.version_label_rec;
    l_t_party_tbl csi_datastructures_pub.party_tbl;
    l_t_account_tbl csi_datastructures_pub.party_account_tbl;
    l_new_party_tbl csi_datastructures_pub.party_tbl;
    l_new_account_tbl csi_datastructures_pub.party_account_tbl;
    lb_party_tbl csi_datastructures_pub.party_tbl;
    lc_party_tbl csi_datastructures_pub.party_tbl;
    l_temp_party_tbl csi_datastructures_pub.party_tbl;
    la_account_tbl csi_datastructures_pub.party_account_tbl;
    l_temp_acct_tbl csi_datastructures_pub.party_account_tbl;
    l_instance_rec csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tbl csi_datastructures_pub.extend_attrib_values_tbl;
    l_pricing_attrib_tbl csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tbl csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tbl csi_datastructures_pub.instance_asset_tbl;
    k_txn_rec csi_datastructures_pub.transaction_rec;
    x_instance_id_lst csi_datastructures_pub.id_tbl;
    v_msg_index_out number;
    v_message varchar2(4000);
    l_count number;
    l_ser_number varchar2(30);
    l_ship_to_loc_id number;
    l_bill_to_loc_id number;
    l_party_account_id number;
    l_owner_party_id number;
    l_api_version constant number := 1.0;
    p_instance_rec csi_datastructures_pub.instance_rec;
    l_txn_rec csi_datastructures_pub.transaction_rec;
    l_party_site_id number;
    l_order_number number;
    l_line_number varchar2(100);
    l_loan_order_number number;
    l_eval_line_id number;
    l_line_type_id number;
    l_line_type varchar2(30);
  begin
    debug_log(str => 'Entering update_instance');

    if p_txn_rec.inv_material_transaction_id is not null then
      if p_txn_rec.transaction_type_id in (51, 53) then
        select line_type_id
        into   l_line_type_id
        from   oe_order_lines_all
        where  line_id = p_txn_rec.source_line_ref_id;
        select name
        into   l_line_type
        from   oe_transaction_types_tl
        where  language = 'US' and transaction_type_id = l_line_type_id;

        if l_line_type in ('ILS Eval Line', 'ILS Eval Returns') then
          l_ext_attrib_values_tbl.delete;
          l_new_party_tbl.delete;
          l_t_account_tbl.delete;
          l_pricing_attrib_tbl.delete;
          l_org_assignments_tbl.delete;
          l_asset_assignment_tbl.delete;
          select object_version_number
          into   p_instance_rec.object_version_number
          from   csi_item_instances
          where  instance_id = p_instance_id;
          p_instance_rec.instance_id := p_instance_id;

          if l_line_type = 'ILS Eval Line' then
            p_instance_rec.instance_type_code := 'EVAL';
            p_instance_rec.instance_status_id := 10000;
            p_instance_rec.instance_description := 'Integra Owned Evaluation Unit';
          elsif l_line_type = 'ILS Eval Returns' then
            p_instance_rec.instance_type_code := null;
            p_instance_rec.instance_description := null;
          end if;

          select order_number
          into   l_order_number
          from   oe_order_headers_all
          where  header_id = (select header_id
                              from   oe_order_lines_all
                              where  line_id = p_txn_rec.source_line_ref_id);
          l_line_number := line_shipment_option(p_txn_rec.source_line_ref_id);
          l_txn_rec.transaction_type_id := 10000;
          l_txn_rec.transaction_date := sysdate;
          l_txn_rec.source_transaction_date := sysdate;
          l_txn_rec.object_version_number := 1;
          l_txn_rec.source_header_ref := 'EVAL' || '-' || to_char(l_order_number);
          l_txn_rec.source_line_ref := l_line_number;
          l_txn_rec.source_line_ref_id := p_txn_rec.source_line_ref_id;
          csi_item_instance_pub.update_item_instance(p_api_version => l_api_version
                                                   , p_commit => fnd_api.g_false
                                                   , p_init_msg_list => fnd_api.g_false
                                                   , p_validation_level => fnd_api.g_valid_level_full
                                                   , p_instance_rec => p_instance_rec
                                                   , p_ext_attrib_values_tbl => l_ext_attrib_values_tbl
                                                   , p_party_tbl => l_new_party_tbl
                                                   , p_account_tbl => l_t_account_tbl
                                                   , p_pricing_attrib_tbl => l_pricing_attrib_tbl
                                                   , p_org_assignments_tbl => l_org_assignments_tbl
                                                   , p_asset_assignment_tbl => l_asset_assignment_tbl
                                                   , p_txn_rec => l_txn_rec
                                                   , x_instance_id_lst => x_instance_id_lst
                                                   , x_return_status => x_return_status
                                                   , x_msg_count => x_msg_count
                                                   , x_msg_data => x_msg_data);
          debug_log(str => 'Return status from update instance in Eval Ship/Return :' || x_return_status);

          if x_msg_count > 0 then
            debug_log(str => x_msg_count);

            for v_index in 1 .. x_msg_count loop
              fnd_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
              v_message := substr(x_msg_data, 1, 200);
              debug_log(str => x_msg_data);
              log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                       , p_proc_name => 'update_instance'
                       , p_header_id => null
                       , p_line_id => l_eval_line_id
                       , p_date => sysdate
                       , p_msg => 'Unable to instance for line ID :' || p_txn_rec.source_line_ref_id);
            end loop;

            debug_log(str => substr(v_message, 1, 2000));
          end if;
        end if;
      end if;
    end if;
  exception
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'update_instance'
               , p_header_id => null
               , p_line_id => p_txn_rec.source_line_ref_id
               , p_date => sysdate
               , p_msg => 'Others expection occured for line ID :' || p_txn_rec.source_line_ref_id);
  end update_instance;

  procedure close_eval_line(p_itemtype in varchar2
                          , p_itemkey in varchar2
                          , p_actid in number
                          , p_funcmode in varchar2
                          , p_result in out varchar2) is
    l_line_id varchar2(30);
    l_debug_log_level constant number := oe_debug_pub.g_debug_level;
    l_eval_line_id number;
    l_flow_status varchar2(100);
    l_act_status varchar2(100);
    l_act_name varchar2(400);
  begin
    if (p_funcmode = 'RUN') then
      l_line_id := to_number(p_itemkey);

      begin
        select return_attribute2
        into   l_eval_line_id
        from   oe_order_lines_all
        where  line_id = l_line_id and return_context = 'ORDER' and line_category_code = 'RETURN';
        select flow_status_code
        into   l_flow_status
        from   oe_order_lines
        where  line_id = l_eval_line_id;
        wf_engine.setitemattrtext(p_itemtype, p_itemkey, 'XX_EVAL_ACTION', 'Return');
      exception
        when others then
          p_result := 'No eval Reference';
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'Close Eval  Line'
                   , p_header_id => null
                   , p_line_id => l_line_id
                   , p_date => sysdate
                   , p_msg => 'Warning:Not able to find reference line to the Eval return line. Cannot close the Eval line');
          return;
      end;

      -- if l_flow_status = 'INTG_UNDER_EVAL' then
      begin
        select b.activity_name
        into   l_act_name
        from   wf_item_activity_statuses a, wf_process_activities b
        where      item_type = 'OEOL'
               and item_key = to_char(l_eval_line_id)
               and a.process_activity = b.instance_id
               and a.activity_status = 'NOTIFIED';

        /*
         select a.activity_status
         into   l_act_status
         from   wf_item_activity_statuses a, wf_process_activities b
         where      item_type = 'OEOL'
                and item_key = to_char(l_eval_line_id)
                and a.process_activity = b.instance_id
                and activity_name = 'XXINTG_WAIT_IN_EVAL_STATUS'; */
        --if l_act_status = 'NOTIFIED' then
        if l_act_name in ('XXINTG_WAIT_IN_EVAL_STATUS', 'XXINTG_WAIT_IN_RENTAL_STATUS') then
          if l_act_name = 'XXINTG_WAIT_IN_EVAL_STATUS' then
            wf_engine.completeactivity('OEOL', to_char(l_eval_line_id), 'XXINTG_WAIT_IN_EVAL_STATUS', 'RETURN');
          elsif l_act_name = 'XXINTG_WAIT_IN_RENTAL_STATUS' then
            wf_engine.completeactivity('OEOL', to_char(l_eval_line_id), 'XXINTG_WAIT_IN_RENTAL_STATUS', 'RETURN');
          end if;
        end if;
      exception
        when others then
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'Close Eval Line'
                   , p_header_id => null
                   , p_line_id => l_line_id
                   , p_date => sysdate
                   , p_msg => 'Error:Workflow is not at the Notified status');
          p_result := 'No Notified status';
          return;
      end;

      --end if;
      p_result := 'Eval Line Closed';
    end if;
  exception
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'Close Eval Line'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Error:Other exception');
      p_result := 'Other Exception';
      return;
      wf_core.context('OE_LINE_WF'
                    , 'Close Eval Line'
                    , p_itemtype
                    , p_itemkey
                    , p_actid
                    , p_funcmode);
      raise;
  end close_eval_line;

  procedure convert_to_rental(p_line_id in number) is
    l_line_id varchar2(30);
    l_debug_log_level constant number := oe_debug_pub.g_debug_level;
    l_eval_line_id number;
    l_flow_status varchar2(100);
    l_act_status varchar2(100);
  begin
    begin
      select flow_status_code
      into   l_flow_status
      from   oe_order_lines_all
      where  line_id = p_line_id;
    exception
      when others then
        log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                 , p_proc_name => 'Close Eval  Line'
                 , p_header_id => null
                 , p_line_id => p_line_id
                 , p_date => sysdate
                 , p_msg => 'No Order Line Status');
    end;

    if l_flow_status = 'INTG_UNDER_EVAL' then
      begin
        select a.activity_status
        into   l_act_status
        from   wf_item_activity_statuses a, wf_process_activities b
        where      item_type = 'OEOL'
               and item_key = to_char(p_line_id)
               and a.process_activity = b.instance_id
               and activity_name = 'XXINTG_WAIT_IN_EVAL_STATUS';

        if l_act_status = 'NOTIFIED' then
          wf_engine.completeactivity('OEOL', to_char(p_line_id), 'XXINTG_WAIT_IN_EVAL_STATUS', 'RENTAL');
        end if;
      exception
        when others then
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'Convert To Rental'
                   , p_header_id => null
                   , p_line_id => p_line_id
                   , p_date => sysdate
                   , p_msg => 'Error:Workflow is not at the Notified status');
      end;
    end if;
  exception
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'Close Eval Line'
               , p_header_id => null
               , p_line_id => p_line_id
               , p_date => sysdate
               , p_msg => 'Error:Other exception');
      raise;
  end convert_to_rental;

  procedure set_rental_status(p_itemtype in varchar2
                            , p_itemkey in varchar2
                            , p_actid in number
                            , p_funcmode in varchar2
                            , p_result in out varchar2) is
    l_line_id number;
    x_return_status varchar2(1);
  begin
    if (p_funcmode = 'RUN') then
      l_line_id := to_number(p_itemkey);
      oe_order_wf_util.
      update_flow_status_code(p_header_id => null
                            , p_line_id => l_line_id
                            , p_flow_status_code => 'INTG_UNDER_RENTAL'
                            , x_return_status => x_return_status);

      if x_return_status = fnd_api.g_ret_sts_success then
        p_result := 'COMPLETE';
      else
        p_result := 'ERROR';
      end if;
    end if;
  exception
    when others then
      p_result := 'ERROR';
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'convert_into_rental'
               , p_header_id => null
               , p_line_id => l_line_id
               , p_date => sysdate
               , p_msg => 'Unable to create return line for for :' || l_line_id);
      wf_core.context('OE_LINE_WF'
                    , 'Set Rental Line Status WF'
                    , p_itemtype
                    , p_itemkey
                    , p_actid
                    , p_funcmode);
      raise;
  end;

  procedure convert_to_sell(p_line_id in number) is
    l_line_id varchar2(30);
    l_debug_log_level constant number := oe_debug_pub.g_debug_level;
    l_eval_line_id number;
    l_flow_status varchar2(100);
    l_act_status varchar2(100);
  begin
    begin
      select flow_status_code
      into   l_flow_status
      from   oe_order_lines_all
      where  line_id = p_line_id;
    exception
      when others then
        log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                 , p_proc_name => 'Close Eval  Line'
                 , p_header_id => null
                 , p_line_id => p_line_id
                 , p_date => sysdate
                 , p_msg => 'No Order Line Status');
    end;

    if l_flow_status in ('INTG_UNDER_RENTAL') then
      begin
        select a.activity_status
        into   l_act_status
        from   wf_item_activity_statuses a, wf_process_activities b
        where      item_type = 'OEOL'
               and item_key = to_char(p_line_id)
               and a.process_activity = b.instance_id
               and activity_name = 'XXINTG_WAIT_IN_RENTAL_STATUS';

        if l_act_status = 'NOTIFIED' then
          wf_engine.completeactivity('OEOL', to_char(p_line_id), 'XXINTG_WAIT_IN_RENTAL_STATUS', 'SELL');
        end if;
      exception
        when others then
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'Convert To Rental'
                   , p_header_id => null
                   , p_line_id => p_line_id
                   , p_date => sysdate
                   , p_msg => 'Error:Workflow is not at the Notified status');
      end;
    end if;
  exception
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'Close Eval Line'
               , p_header_id => null
               , p_line_id => p_line_id
               , p_date => sysdate
               , p_msg => 'Error:Other exception');
      raise;
  end convert_to_sell;

  procedure eval_to_sell(p_line_id in number) is
    l_line_id varchar2(30);
    l_debug_log_level constant number := oe_debug_pub.g_debug_level;
    l_eval_line_id number;
    l_flow_status varchar2(100);
    l_act_status varchar2(100);
  begin
    begin
      select flow_status_code
      into   l_flow_status
      from   oe_order_lines_all
      where  line_id = p_line_id;
    exception
      when others then
        log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                 , p_proc_name => 'Close Eval  Line'
                 , p_header_id => null
                 , p_line_id => p_line_id
                 , p_date => sysdate
                 , p_msg => 'No Order Line Status');
    end;

    if l_flow_status in ('INTG_UNDER_EVAL') then
      begin
        select a.activity_status
        into   l_act_status
        from   wf_item_activity_statuses a, wf_process_activities b
        where      item_type = 'OEOL'
               and item_key = to_char(p_line_id)
               and a.process_activity = b.instance_id
               and activity_name = 'XXINTG_WAIT_IN_EVAL_STATUS';

        if l_act_status = 'NOTIFIED' then
          wf_engine.completeactivity('OEOL', to_char(p_line_id), 'XXINTG_WAIT_IN_EVAL_STATUS', 'SELL');
        end if;
      exception
        when others then
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'Convert To Rental'
                   , p_header_id => null
                   , p_line_id => p_line_id
                   , p_date => sysdate
                   , p_msg => 'Error:Workflow is not at the Notified status');
      end;
    end if;
  exception
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'Close Eval Line'
               , p_header_id => null
               , p_line_id => p_line_id
               , p_date => sysdate
               , p_msg => 'Error:Other exception');
      raise;
  end eval_to_sell;

  procedure rental_ib_update(p_itemtype in varchar2
                           , p_itemkey in varchar2
                           , p_actid in number
                           , p_funcmode in varchar2
                           , p_result in out varchar2) is
    l_line_id varchar2(30);
    l_loan_line_id number;
    l_loan_ship_trx number;
    l_loan_account number;
    l_loan_account_combo varchar2(100);
    l_org_id number;
    l_equiment_ref varchar2(100);
    l_instance_id number;
    l_return_status varchar2(1);
    l_item_id number;
    l_serial_number varchar2(30);
  begin
    if (p_funcmode = 'RUN') then
      l_line_id := to_number(p_itemkey);

      begin
        begin
          select b.inventory_item_id, serial_number
          into   l_item_id, l_serial_number
          from   mtl_unit_transactions a, mtl_material_transactions b
          where  b.transaction_type_id = 33 and b.trx_source_line_id = l_line_id and a.transaction_id = b.transaction_id;
        exception
          when others then
            p_result := 'COMPLETE:N';
            log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                     , p_proc_name => 'rental IB Update'
                     , p_header_id => null
                     , p_line_id => l_line_id
                     , p_date => sysdate
                     , p_msg => 'Error:Not able to find serial number for the order line.');
            return;
        end;

        begin
          select instance_id
          into   l_instance_id
          from   csi_item_instances
          where      serial_number = l_serial_number
                 and inventory_item_id = l_item_id
                 and instance_status_id in (select instance_status_id
                                            from   csi_instance_statuses
                                            where  name = 'Under Evaluation')
                 and rownum = 1;
        exception
          when others then
            p_result := 'COMPLETE:N';
            log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                     , p_proc_name => 'rental_eval_ib_update'
                     , p_header_id => null
                     , p_line_id => l_line_id
                     , p_date => sysdate
                     , p_msg => 'Warning:Unable to find IB. Cannot update IB');
            return;
        end;

        begin
          update_instance_for_rent(l_instance_id, l_line_id, l_return_status);

          if l_return_status = 'S' then
            p_result := 'COMPLETE:Y';
          else
            p_result := 'COMPLETE:N';
          end if;
        exception
          when others then
            p_result := 'COMPLETE:N';
            log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                     , p_proc_name => 'rental_eval_ib_update'
                     , p_header_id => null
                     , p_line_id => l_line_id
                     , p_date => sysdate
                     , p_msg => 'Warning:Unable to update the IB');
            return;
        end;
      exception
        when others then
          p_result := 'COMPLETE:N';
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'rental_eval_ib_update'
                   , p_header_id => null
                   , p_line_id => l_line_id
                   , p_date => sysdate
                   , p_msg => 'Not able to find reference line to the loan return line. Cannot perform return accounting for Loan selling.');
      end;
    end if;
  end rental_ib_update;

  procedure update_instance_for_rent(p_instance_id in number, p_line_id in number, x_return_status out varchar2) is
    l_new_instance_rec csi_datastructures_pub.instance_rec;
    l_party_tbl csi_datastructures_pub.party_tbl;
    l_account_tbl csi_datastructures_pub.party_account_tbl;
    l_version_label_rec csi_datastructures_pub.version_label_rec;
    l_t_party_tbl csi_datastructures_pub.party_tbl;
    l_t_account_tbl csi_datastructures_pub.party_account_tbl;
    l_new_party_tbl csi_datastructures_pub.party_tbl;
    l_new_account_tbl csi_datastructures_pub.party_account_tbl;
    lb_party_tbl csi_datastructures_pub.party_tbl;
    lc_party_tbl csi_datastructures_pub.party_tbl;
    l_temp_party_tbl csi_datastructures_pub.party_tbl;
    la_account_tbl csi_datastructures_pub.party_account_tbl;
    l_temp_acct_tbl csi_datastructures_pub.party_account_tbl;
    l_instance_rec csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tbl csi_datastructures_pub.extend_attrib_values_tbl;
    l_pricing_attrib_tbl csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tbl csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tbl csi_datastructures_pub.instance_asset_tbl;
    k_txn_rec csi_datastructures_pub.transaction_rec;
    x_instance_id_lst csi_datastructures_pub.id_tbl;
    x_msg_count number;
    x_msg_data varchar2(4000);
    v_msg_index_out number;
    v_message varchar2(4000);
    l_count number;
    l_ser_number varchar2(30);
    l_ship_to_loc_id number;
    l_bill_to_loc_id number;
    l_party_account_id number;
    l_owner_party_id number;
    l_api_version constant number := 1.0;
    p_instance_rec csi_datastructures_pub.instance_rec;
    l_txn_rec csi_datastructures_pub.transaction_rec;
    l_party_site_id number;
    l_order_number number;
    l_line_number varchar2(100);
    l_loan_order_number number;
  begin
    debug_log(str => 'Entering update_instance_for_sell');
    l_ext_attrib_values_tbl.delete;
    l_new_party_tbl.delete;
    l_t_account_tbl.delete;
    l_pricing_attrib_tbl.delete;
    l_org_assignments_tbl.delete;
    l_asset_assignment_tbl.delete;
    select object_version_number
    into   p_instance_rec.object_version_number
    from   csi_item_instances
    where  instance_id = p_instance_id;
    p_instance_rec.instance_id := p_instance_id;
    p_instance_rec.instance_type_code := 'RENTAL';
    p_instance_rec.instance_description := 'Integra Owned Rental Unit';
    p_instance_rec.instance_status_id := 10001;
    select order_number
    into   l_order_number
    from   oe_order_headers_all
    where  header_id = (select header_id
                        from   oe_order_lines_all
                        where  line_id = p_line_id);
    l_line_number := line_shipment_option(p_line_id);
    l_txn_rec.transaction_type_id := 10001;
    l_txn_rec.transaction_date := sysdate;
    l_txn_rec.source_transaction_date := sysdate;
    l_txn_rec.object_version_number := 1;
    l_txn_rec.source_header_ref := 'EVAL' || '-' || to_char(l_order_number) || '-' || 'RENTAL';
    l_txn_rec.source_line_ref := l_line_number;
    l_txn_rec.source_line_ref_id := p_line_id;
    csi_item_instance_pub.update_item_instance(p_api_version => l_api_version
                                             , p_commit => fnd_api.g_false
                                             , p_init_msg_list => fnd_api.g_false
                                             , p_validation_level => fnd_api.g_valid_level_full
                                             , p_instance_rec => p_instance_rec
                                             , p_ext_attrib_values_tbl => l_ext_attrib_values_tbl
                                             , p_party_tbl => l_new_party_tbl
                                             , p_account_tbl => l_t_account_tbl
                                             , p_pricing_attrib_tbl => l_pricing_attrib_tbl
                                             , p_org_assignments_tbl => l_org_assignments_tbl
                                             , p_asset_assignment_tbl => l_asset_assignment_tbl
                                             , p_txn_rec => l_txn_rec
                                             , x_instance_id_lst => x_instance_id_lst
                                             , x_return_status => x_return_status
                                             , x_msg_count => x_msg_count
                                             , x_msg_data => x_msg_data);
    debug_log(str => 'Return status from update instance in Loan selling :' || x_return_status);

    if x_msg_count > 0 then
      debug_log(str => x_msg_count);

      for v_index in 1 .. x_msg_count loop
        fnd_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
        v_message := substr(x_msg_data, 1, 200);
        debug_log(str => x_msg_data);
      end loop;

      debug_log(str => substr(v_message, 1, 2000));
    end if;
  end update_instance_for_rent;

  procedure create_exchange(p_line_id in number) is
    x_header_id number;
    x_msg_count number;
    x_msg_data varchar2(4000);
    v_msg_index_out number;
    v_message varchar2(4000);
    l_header_id number;
    l_line_tbl oe_globals.selected_record_tbl;
    l_hdr_tbl oe_globals.selected_record_tbl;
    x_copy_rec oe_order_copy_util.copy_rec_type;
    l_open_flag varchar2(1);
    l_shipped varchar2(30);
    x_return_status varchar2(1);
    l_line_number varchar2(10);
    l_order_number number;
    l_exchanged varchar2(50);
    l_category_code varchar2(10);
    l_line_type varchar2(30);
    l_line_status varchar2(30);
  begin
    select a.header_id, a.line_number, a.line_category_code, b.name, a.flow_status_code
    into   l_header_id, l_line_number, l_category_code, l_line_type, l_line_status
    from   oe_order_lines_all a, oe_line_types_v b
    where  line_id = p_line_id and a.line_type_id = b.line_type_id;
    select order_number
    into   l_order_number
    from   oe_order_headers_all
    where  header_id = l_header_id;
    l_hdr_tbl(1).id1 := l_header_id;
    l_line_tbl(1).id1 := p_line_id;

    begin
      select 'Shipped'
      into   l_shipped
      from   dual
      where  exists
               (select 1
                from   mtl_material_transactions
                where  trx_source_line_id = p_line_id and transaction_type_id = 33);
    exception
      when others then
        l_shipped := 'Not Shipped';
    end;

    begin
      select 'Already Exchanged'
      into   l_exchanged
      from   dual
      where  exists
               (select 1
                from   oe_order_lines_all
                where      cancelled_flag = 'N'
                       and source_document_line_id = p_line_id
                       and source_document_id = l_header_id
                       and source_document_type_id = (select order_source_id
                                                      from   oe_order_sources
                                                      where  name = 'Exchange'));
    exception
      when others then
        l_exchanged := 'Exchange Eligible';
    end;

    if (    l_shipped = 'Shipped'
        and l_exchanged = 'Exchange Eligible'
        and l_category_code = 'ORDER'
        and l_line_type = 'ILS Eval Line'
        and l_line_status <> 'INTG_EXCHANGED') then
      x_copy_rec.init_msg_list := fnd_api.g_false;
      x_copy_rec.commit := fnd_api.g_false;
      x_copy_rec.copy_order := fnd_api.g_false;
      x_copy_rec.hdr_info := fnd_api.g_false;
      x_copy_rec.hdr_descflex := fnd_api.g_false;
      x_copy_rec.hdr_scredits := fnd_api.g_false;
      x_copy_rec.hdr_attchmnts := fnd_api.g_false;
      x_copy_rec.hdr_holds := fnd_api.g_false;
      x_copy_rec.hdr_credit_card_details := fnd_api.g_false;
      x_copy_rec.all_lines := fnd_api.g_false;
      x_copy_rec.incl_cancelled := fnd_api.g_false;
      x_copy_rec.line_price_mode := oe_order_copy_util.g_cpy_orig_price;
      x_copy_rec.line_price_date := fnd_api.g_miss_date;
      x_copy_rec.line_descflex := fnd_api.g_true;
      x_copy_rec.line_scredits := fnd_api.g_true;
      x_copy_rec.line_attchmnts := fnd_api.g_true;
      x_copy_rec.line_fulfill_sets := fnd_api.g_false;
      x_copy_rec.line_ship_arr_sets := fnd_api.g_false;
      x_copy_rec.append_to_header_id := l_hdr_tbl(1).id1;
      --x_copy_rec.line_type := p_line_type_id;
      x_copy_rec.line_count := 1;
      x_copy_rec.source_block_type := 'LINE';
      x_copy_rec.source_org_id := fnd_global.org_id;
      x_copy_rec.copy_org_id := fnd_global.org_id;
      --x_copy_rec.hdr_type := 1033;
      x_copy_rec.default_null_values := 'Y';
      x_copy_rec.api_version_number := 1.0;
      oe_order_copy_util.copy_order(p_copy_rec => x_copy_rec
                                  , p_hdr_id_tbl => l_hdr_tbl
                                  , p_line_id_tbl => l_line_tbl
                                  , x_header_id => x_header_id
                                  , x_return_status => x_return_status
                                  , x_msg_count => x_msg_count
                                  , x_msg_data => x_msg_data);

      if x_msg_count > 0 then
        for v_index in 1 .. x_msg_count loop
          v_message := null;
          oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
          v_message := substr(x_msg_data, 1, 200);
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'copy_return_line'
                   , p_header_id => null
                   , p_line_id => p_line_id
                   , p_date => sysdate
                   , p_msg => v_message);
        end loop;
      end if;

      if x_return_status = 'S' then
        update oe_order_lines_all
        set    orig_sys_document_ref = l_order_number
             , orig_sys_line_ref = l_line_number
             , source_document_type_id = (select order_source_id
                                          from   oe_order_sources
                                          where  name = 'Exchange')
        where  source_document_line_id = p_line_id and source_document_id = l_header_id and source_document_type_id = 2;
        x_return_status := null;
        select open_flag
        into   l_open_flag
        from   oe_order_lines_all
        where  line_id = p_line_id;

        if l_open_flag = 'Y' then
          oe_order_wf_util.
          update_flow_status_code(p_header_id => null
                                , p_line_id => p_line_id
                                , p_flow_status_code => 'INTG_EXCHANGED'
                                , x_return_status => x_return_status);
        end if;
      end if;
    end if;
  exception
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'Create_exchange_line'
               , p_header_id => null
               , p_line_id => p_line_id
               , p_date => sysdate
               , p_msg => 'Unable to create exchange line');
  end create_exchange;

  function get_messages(p_action in varchar2, p_line_id in number, p_header_id in number)
    return varchar2 is
    l_exchange_check number;
    l_ship_check number;
    l_category_code varchar2(10);
    l_line_type varchar2(30);
    l_open_check number;
    l_cancel_check number;
    l_rental_check number;
    l_rental_comp_check number;
    l_line_status varchar2(30);
    l_first_extension varchar2(50);
    l_first_ext_days number;
    l_second_ext_days number;
  begin
    select a.line_category_code, b.name, a.flow_status_code
    into   l_category_code, l_line_type, l_line_status
    from   oe_order_lines_all a, oe_line_types_v b
    where  line_id = p_line_id and a.line_type_id = b.line_type_id;

    if (l_category_code = 'ORDER' and l_line_type = 'ILS Eval Line') then
      if p_action = 'EXCHANGE' then
        begin
          begin
            select count(*)
            into   l_exchange_check
            from   oe_order_lines_all
            where      source_document_line_id = p_line_id
                   and source_document_id = p_header_id
                   and source_document_type_id = (select order_source_id
                                                  from   oe_order_sources
                                                  where  name = 'Exchange');
          exception
            when others then
              l_exchange_check := 0;
          end;

          begin
            select count(*)
            into   l_ship_check
            from   mtl_material_transactions
            where  trx_source_line_id = p_line_id and transaction_type_id = 33;
          exception
            when others then
              l_ship_check := 0;
          end;

          if l_exchange_check > 0 then
            return 'This line is already exchanged. Please stop creating Exchange line and cancel the existing existing exchange line first!';
          elsif l_ship_check = 0 then
            return 'Eval line needs to be shipped before it can be exchanged!';
          elsif l_category_code = 'RETURN' then
            return 'Return line cannot be exchanged! Please cancel this action.';
          elsif l_line_status = 'INTG_EXCHANGED' then
            return 'This line is already Exchanged. Please cancel this action';
          elsif (l_exchange_check = 0 and l_ship_check > 0 and l_category_code = 'ORDER' and l_line_status <> 'INTG_EXCHANGED') then
            return 'You are about to create Exchange Line. Please ensure all conditions are met!';
          end if;
        exception
          when others then
            return 'Error Occured. Please contact support by logging GAC ticket';
        end;
      elsif p_action = 'RENTAL' then
        begin
          if l_line_status <> 'INTG_UNDER_EVAL' then
            return 'Eval line needs to be in status Under Evaluation before it can be Rented!';
          elsif l_line_status = 'INTG_UNDER_EVAL' then
            return 'You are about to convert eval to rental. Please ensure all conditions are met!';
          end if;
        exception
          when others then
            return 'Error Occured. Please contact support by logging GAC ticket';
        end;
      elsif p_action = 'EXTEND-1' then
        begin
          select max(segment3)
          into   l_first_ext_days
          from   xxintg_om_hdr_add_info a, oe_order_headers_all b
          where      b.header_id = p_header_id
                 and b.context = 'Eval'
                 and a.segment30 = p_header_id
                 and a.segment30 = b.header_id
                 and segment3 is not null;
        exception
          when others then
            l_first_ext_days := 0;
        end;

        begin
          if l_line_status <> 'INTG_UNDER_EVAL' or l_first_ext_days = 0 then
            return 'Eval line needs to be in status Under Evaluation and extesion days are required to be entered before it can be Extended!';
          elsif l_line_status = 'INTG_UNDER_EVAL' and l_first_ext_days > 0 then
            return 'You are about to extend evaluation period. Please ensure all conditions are met!';
          end if;
        exception
          when others then
            return 'Error Occured. Please contact support by logging GAC ticket';
        end;
      elsif p_action = 'EXTEND-2' then
        begin
          select max(segment4)
          into   l_second_ext_days
          from   xxintg_om_hdr_add_info a, oe_order_headers_all b
          where      b.header_id = p_header_id
                 and b.context = 'Eval'
                 and a.segment30 = p_header_id
                 and a.segment30 = b.header_id
                 and segment3 is not null;
        exception
          when others then
            l_second_ext_days := 0;
        end;

        begin
          select case
                   when max(segment_attribute3) is not null then 'Extended'
                   else 'Not Extended'
                 end
          into   l_first_extension
          from   xxintg_om_hdr_add_info a, oe_order_headers_all b
          where  b.header_id = p_header_id and b.context = 'Eval' --and b.attribute11 = a.code_combination_id
                 and a.segment30 = p_header_id and b.header_id = a.segment30 and segment_attribute3 is not null;
        exception
          when others then
            l_first_extension := 'Not Extended';
        end;

        begin
          if l_line_status <> 'INTG_UNDER_EVAL' or l_second_ext_days = 0 then
            return 'Eval line needs to be in status Under Evaluation and extension days are required before it can be Extended!';
          elsif l_first_extension = 'Not Extended' then
            return 'Please perform first extension before executing second extension';
          elsif l_line_status = 'INTG_UNDER_EVAL' and l_second_ext_days > 0 then
            return 'You are about to extend evaluation period. Please ensure all conditions are met!';
          end if;
        exception
          when others then
            return 'Error Occured. Please contact support by logging GAC ticket';
        end;
      end if;
    else
      return 'This line (return line) is not eligible for any actions!';
    end if;
  exception
    when others then
      return 'Error Occured. Please contact support by logging GAC ticket';
  end;

  procedure eval_extension(p_esc_stage in number, p_eval_line_id in number) is
    v_msg_index_out number;
    v_message varchar2(4000);
    l_line_id number;
    l_workflow_status varchar2(30);
    l_result_out number; --varchar2(30);
    l_msg_count number := 0;
    l_msg_data varchar2(240);
    x_return_status varchar2(30);
    x_msg_count number;
    x_msg_data varchar2(240);
    l_line_tbl oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
    l_old_line_tbl oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
    l_control_rec oe_globals.control_rec_type;
    l_x_header_rec oe_order_pub.header_rec_type := oe_order_pub.g_miss_header_rec;
    l_x_header_adj_rec oe_order_pub.header_adj_rec_type;
    l_x_header_adj_tbl oe_order_pub.header_adj_tbl_type := oe_order_pub.g_miss_header_adj_tbl;
    l_x_header_scredit_rec oe_order_pub.header_scredit_rec_type;
    l_x_header_scredit_tbl oe_order_pub.header_scredit_tbl_type := oe_order_pub.g_miss_header_scredit_tbl;
    l_x_line_rec oe_order_pub.line_rec_type;
    l_old_line_rec oe_order_pub.line_rec_type;
    l_x_line_adj_rec oe_order_pub.line_adj_rec_type;
    l_x_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    l_x_line_scredit_rec oe_order_pub.line_scredit_rec_type;
    l_x_line_scredit_tbl oe_order_pub.line_scredit_tbl_type := oe_order_pub.g_miss_line_scredit_tbl;
    l_lot_serial_tbl oe_order_pub.lot_serial_tbl_type := oe_order_pub.g_miss_lot_serial_tbl;
    l_x_header_price_att_tbl oe_order_pub.header_price_att_tbl_type := oe_order_pub.g_miss_header_price_att_tbl;
    l_x_header_adj_att_tbl oe_order_pub.header_adj_att_tbl_type := oe_order_pub.g_miss_header_adj_att_tbl;
    l_x_header_adj_assoc_tbl oe_order_pub.header_adj_assoc_tbl_type := oe_order_pub.g_miss_header_adj_assoc_tbl;
    l_x_line_price_att_tbl oe_order_pub.line_price_att_tbl_type := oe_order_pub.g_miss_line_price_att_tbl;
    l_x_line_adj_att_tbl oe_order_pub.line_adj_att_tbl_type := oe_order_pub.g_miss_line_adj_att_tbl;
    l_x_line_adj_assoc_tbl oe_order_pub.line_adj_assoc_tbl_type := oe_order_pub.g_miss_line_adj_assoc_tbl;
    l_x_action_request_tbl oe_order_pub.request_tbl_type := oe_order_pub.g_miss_request_tbl;
    l_x_header_payment_tbl oe_order_pub.header_payment_tbl_type;
    l_x_line_payment_tbl oe_order_pub.line_payment_tbl_type;
    --
    l_debug_level constant number := oe_debug_pub.g_debug_level;
    l_new_request_date date;
    l_eval_days number;
    l_order_number number;
    l_trx_date date;
    ls_index number;
    j number;
    l_ship_from_org_id number;
    l_return_subinventory varchar2(100);
    l_returnable varchar2(100);
    non_return_exp exception;
    l_eval_return_line_id number;
    l_second_extension varchar2(50);
    l_first_extension varchar2(50);
    l_esc_stage varchar2(30);
    l_ret_line_rec oe_order_pub.line_rec_type;
  --
  begin
    l_old_line_tbl.delete;
    oe_line_util.query_row(p_line_id => p_eval_line_id, x_line_rec => l_old_line_rec);

    if p_esc_stage = 1 then
      l_esc_stage := 'FIRST';
    elsif p_esc_stage = 2 then
      l_esc_stage := 'SECOND';
    end if;

    begin
      select max(line_id)
      into   l_eval_return_line_id
      from   oe_order_lines_all
      where      line_category_code = 'RETURN'
             and nvl(cancelled_flag, 'N') = 'N'
             and open_flag = 'Y'
             and return_context = 'ORDER'
             and return_attribute1 = l_old_line_rec.header_id
             and return_attribute2 = l_old_line_rec.line_id;
    exception
      when others then
        begin
          select max(line_id)
          into   l_eval_return_line_id
          from   oe_order_lines_all
          where      source_document_line_id = l_old_line_rec.line_id
                 and line_category_code = 'RETURN'
                 and nvl(cancelled_flag, 'N') = 'N'
                 and open_flag = 'Y'
                 and order_source_id = (select order_source_id
                                        from   oe_order_sources
                                        where  name = 'Evaluation Orders');
        exception
          when others then
            log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                     , p_proc_name => 'set_line_status'
                     , p_header_id => null
                     , p_line_id => l_line_id
                     , p_date => sysdate
                     , p_msg => 'No Return Lines Found for :' || l_old_line_rec.line_id);
        end;
    end;

    if l_old_line_rec.flow_status_code = 'INTG_UNDER_EVAL' and l_eval_return_line_id is not null then
      oe_line_util.query_row(p_line_id => l_eval_return_line_id, x_line_rec => l_ret_line_rec);

      if l_esc_stage = 'FIRST' then
        begin
          select case
                   when segment_attribute3 is not null then 'Extended'
                   else 'Not Extended'
                 end
          into   l_first_extension
          from   xxintg_om_hdr_add_info a, oe_order_headers_all b
          where  b.header_id = l_old_line_rec.header_id and b.context = 'Eval' and b.attribute11 = a.code_combination_id;
        exception
          when others then
            l_first_extension := 'Not Extended';
        end;

        if l_first_extension = 'Not Extended' then
          begin
            select a.segment3, b.order_number
            into   l_eval_days, l_order_number
            from   xxintg_om_hdr_add_info a, oe_order_headers_all b
            where      b.header_id = l_old_line_rec.header_id
                   and b.context = 'Eval'
                   and b.attribute11 = a.code_combination_id
                   and segment_attribute3 is null;
          exception
            when others then
              l_eval_days := 0;
          end;
        end if;

        update xxintg_om_hdr_add_info
        set    segment_attribute2 = l_ret_line_rec.request_date
        where  segment30 = l_old_line_rec.header_id
               and code_combination_id = (select attribute11
                                          from   oe_order_headers_all
                                          where  header_id = l_old_line_rec.header_id and context = 'Eval');
      --end if;
      elsif l_esc_stage = 'SECOND' then
        begin
          select case
                   when max(segment_attribute3) is not null then 'Extended'
                   else 'Not Extended'
                 end
          into   l_first_extension
          from   xxintg_om_hdr_add_info a, oe_order_headers_all b
          where  b.header_id = l_old_line_rec.header_id and b.context = 'Eval' --and b.attribute11 = a.code_combination_id
                 and a.segment30 = l_old_line_rec.header_id and segment_attribute3 is not null;
        exception
          when others then
            l_first_extension := 'Not Extended';
        end;

        begin
          select case
                   when max(segment_attribute4) is not null then 'Extended'
                   else 'Not Extended'
                 end
          into   l_second_extension
          from   xxintg_om_hdr_add_info a, oe_order_headers_all b
          where  b.header_id = l_old_line_rec.header_id and b.context = 'Eval' --and b.attribute11 = a.code_combination_id;
                 and a.segment30 = l_old_line_rec.header_id and segment_attribute4 is not null;
        exception
          when others then
            l_second_extension := 'Not Extended';
        end;

        if (l_second_extension = 'Not Extended' and l_first_extension = 'Extended') then
          begin
            select a.segment4, b.order_number
            into   l_eval_days, l_order_number
            from   xxintg_om_hdr_add_info a, oe_order_headers_all b
            where  b.header_id = l_old_line_rec.header_id and b.context = 'Eval' and b.attribute11 = a.code_combination_id;
          exception
            when others then
              l_eval_days := 0;
          end;
        end if;
      end if;

      if ((l_esc_stage = 'FIRST' and l_first_extension = 'Not Extended' and l_eval_days > 0)
          or (l_esc_stage = 'SECOND' and l_second_extension = 'Not Extended' and l_first_extension = 'Extended')) then
        begin
          l_trx_date := l_ret_line_rec.request_date + l_eval_days;
        exception
          when others then
            l_trx_date := l_ret_line_rec.request_date;
        end;

        l_line_tbl := oe_order_pub.g_miss_line_tbl;
        l_control_rec.controlled_operation := true;
        l_control_rec.default_attributes := false;
        l_control_rec.change_attributes := false;
        l_line_tbl(1) := oe_order_pub.g_miss_line_rec;
        l_line_tbl(1).line_id := l_eval_return_line_id;
        l_line_tbl(1).change_reason := 'No reason provided';
        l_line_tbl(1).operation := oe_globals.g_opr_update;
        l_line_tbl(1).request_date := l_trx_date;
        oe_order_pvt.process_order(p_api_version_number => 1.0
                                 , p_init_msg_list => fnd_api.g_true
                                 , x_return_status => x_return_status
                                 , x_msg_count => x_msg_count
                                 , x_msg_data => x_msg_data
                                 , p_control_rec => l_control_rec
                                 , p_x_line_tbl => l_line_tbl
                                 , p_x_header_rec => l_x_header_rec
                                 , p_x_header_adj_tbl => l_x_header_adj_tbl
                                 , p_x_header_price_att_tbl => l_x_header_price_att_tbl
                                 , p_x_header_adj_att_tbl => l_x_header_adj_att_tbl
                                 , p_x_header_adj_assoc_tbl => l_x_header_adj_assoc_tbl
                                 , p_x_header_scredit_tbl => l_x_header_scredit_tbl
                                 , p_x_header_payment_tbl => l_x_header_payment_tbl
                                 , p_x_line_adj_tbl => l_x_line_adj_tbl
                                 , p_x_line_price_att_tbl => l_x_line_price_att_tbl
                                 , p_x_line_adj_att_tbl => l_x_line_adj_att_tbl
                                 , p_x_line_adj_assoc_tbl => l_x_line_adj_assoc_tbl
                                 , p_x_line_scredit_tbl => l_x_line_scredit_tbl
                                 , p_x_line_payment_tbl => l_x_line_payment_tbl
                                 , p_x_lot_serial_tbl => l_lot_serial_tbl
                                 , p_x_action_request_tbl => l_x_action_request_tbl);

        --dbms_output.put_line('x_return_status: ' || x_return_status);
        if x_return_status = fnd_api.g_ret_sts_success then
          if l_esc_stage = 'FIRST' then
            update xxintg_om_hdr_add_info
            set    segment_attribute3 = l_trx_date
            where  segment30 in (select header_id
                                 from   oe_order_headers_all
                                 where  header_id = l_old_line_rec.header_id and context = 'Eval');
          elsif l_esc_stage = 'SECOND' then
            update xxintg_om_hdr_add_info
            set    segment_attribute4 = l_trx_date
            where  segment30 in (select header_id
                                 from   oe_order_headers_all
                                 where  header_id = l_old_line_rec.header_id and context = 'Eval');
          end if;
        elsif x_return_status = fnd_api.g_ret_sts_unexp_error then
          --dbms_output.put_line('fnd_api.g_ret_sts_unexp_error');
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'create_lot_serials'
                   , p_header_id => null
                   , p_line_id => p_eval_line_id
                   , p_date => sysdate
                   , p_msg => 'Unable to update return line for :' || l_eval_return_line_id || ' using eval line ID' || p_eval_line_id);
          raise fnd_api.g_exc_unexpected_error;
        elsif x_return_status = fnd_api.g_ret_sts_error then
          --dbms_output.put_line('fnd_api.g_ret_sts_error');
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'create_lot_serials'
                   , p_header_id => null
                   , p_line_id => p_eval_line_id
                   , p_date => sysdate
                   , p_msg => 'Unable to update return line for :' || l_eval_return_line_id || ' using eval line ID' || p_eval_line_id);
          raise fnd_api.g_exc_error;
        end if;

        if x_msg_count > 0 then
          --dbms_output.put_line(x_msg_count);
          for v_index in 1 .. x_msg_count loop
            oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
            v_message := substr(x_msg_data, 1, 200);
          -- dbms_output.put_line(x_msg_data);
          end loop;

          --dbms_output.put_line(v_message);
          log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
                   , p_proc_name => 'create_lot_serials'
                   , p_header_id => null
                   , p_line_id => p_eval_line_id
                   , p_date => sysdate
                   , p_msg => v_message);
        end if;
      end if;
    end if;
  exception
    when fnd_api.g_exc_unexpected_error then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'Unexpected Error in Order Line Update for returns');
    when fnd_api.g_exc_error then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'In Error Exception in Order Line for Returns');
    when others then
      log_errors(p_pkg_name => 'xxom_eval_orders_pkg'
               , p_proc_name => 'create_lot_serials'
               , p_header_id => null
               , p_line_id => p_eval_line_id
               , p_date => sysdate
               , p_msg => 'In others exception in Update for returns');
  end eval_extension;
  procedure validate_po(itemtype in varchar2, itemkey in varchar2, actid in number, funcmode in varchar2, resultout out nocopy varchar2) is
  cursor cur_copy_ord(p_org_id number, p_line_id number) is
    select oola.cust_po_number
    from   oe_order_lines oola
    where  oola.org_id = p_org_id and oola.line_id = p_line_id;

  -- Cursor to verify line hOLD
  cursor c_chk_hold is
    select 'Y'
    from   oe_order_holds a, oe_hold_sources b, oe_hold_definitions c
    where      1 = 1
           and a.line_id = to_number(itemkey)
           and a.hold_source_id = b.hold_source_id
           and c.hold_id = b.hold_id
           and c.name = 'Awaiting PO Hold'
           and c.type_code = 'HOLD'
           and a.released_flag = 'N'
           and a.hold_release_id is null
           and trunc(sysdate) between nvl(c.start_date_active, trunc(sysdate)) and nvl(c.end_date_active, trunc(sysdate))
           and c.item_type = 'OEOL';

  l_user_id number;
  l_person_id number;
  l_dest_org_id number;
  l_deliver_to_loc_id number;
  l_err_msg varchar2(150);
  l_cc_id number;
  l_line_num varchar2(100);
  l_line_id number;
  l_org_id number;
  x_hold_exists varchar2(100);
  l_hold_line_type varchar2(10);
  l_temp varchar2(100);
begin
  -- Extract WF data
  l_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
  l_user_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');

  for rec_copy_ord in cur_copy_ord(l_org_id, itemkey) loop
    l_hold_line_type := 'N';
    x_hold_exists := 'N';
    open c_chk_hold;
    fetch c_chk_hold
    into x_hold_exists;
    close c_chk_hold;

    if rec_copy_ord.cust_po_number is null and x_hold_exists = 'Y' then
      resultout := 'COMPLETE:N';
    elsif rec_copy_ord.cust_po_number is not null and x_hold_exists = 'N' then
      resultout := 'COMPLETE:Y';
    else
      resultout := 'COMPLETE:N';
    end if;
  end loop;
exception
  when others then
    l_err_msg := substr(sqlerrm, 1, 130);
    wf_core.context('xx_om_consignment_order_pkg'
                  , 'xx_om_validate_po'
                  , itemtype
                  , itemkey
                  , 'Error ' || l_err_msg);
    raise;
end validate_po;

procedure custpo_hold(itemtype in   varchar2
                          , itemkey in    varchar2
                          , actid in      number
                          , funcmode in   varchar2
                          , resultout in out nocopy varchar2) is
  x_order_tbl oe_holds_pvt.order_tbl_type;
  x_hold_id number;
  x_return_status varchar2(1000);
  x_msg_data varchar2(1000);
  x_msg_count number;
  x_hold_exists varchar2(100);
  l_org_id number;
  l_user_id number;
  x_release_reason_code varchar2(100);
  l_hold_line_type varchar2(10);
  l_temp varchar2(100);

  cursor c_oe_order_lines(p_itemkey number) is
    select oel.line_id, oel.header_id
    from   oe_order_lines_all oel
    where  line_id = p_itemkey;

  -- Cursor to fetch HOLD ID
  cursor c_hold_id is
    select hold_id
    from   oe_hold_definitions
    where      name = 'Awaiting PO Hold'
           and type_code = 'HOLD'
           and trunc(sysdate) between nvl(start_date_active, trunc(sysdate)) and nvl(end_date_active, trunc(sysdate))
           and item_type = 'OEOL';
begin
  if (funcmode = 'RUN') then
    -- Extract WF data
    l_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
    l_user_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');

    for rec_oe_order_lines in c_oe_order_lines(to_number(itemkey)) loop
      x_order_tbl(1).header_id := rec_oe_order_lines.header_id;
      x_order_tbl(1).line_id := rec_oe_order_lines.line_id;
      open c_hold_id;
      fetch c_hold_id
      into x_hold_id;
      close c_hold_id;

      if x_hold_id is not null then
        update_status('RENTAL_BILLING_HOLD', l_org_id, itemkey);
        oe_holds_pub.apply_holds(p_api_version => 1.0
                               , p_init_msg_list => fnd_api.g_true
                               , p_commit => fnd_api.g_false
                               , p_validation_level => fnd_api.g_valid_level_full
                               , p_order_tbl => x_order_tbl
                               , p_hold_id => x_hold_id
                               , p_hold_until_date => null
                               , p_hold_comment => null
                               , p_check_authorization_flag => null
                               , x_return_status => x_return_status
                               , x_msg_count => x_msg_count
                               , x_msg_data => x_msg_data);
      end if;
    end loop;
  end if;

  resultout := 'COMPLETE:COMPLETE';
  return;
exception
  when others then
    wf_core.context('xx_om_consignment_order_pkg'
                  , 'xx_om_custpo_hold '
                  , itemtype
                  , itemkey
                  , to_char(actid)
                  , funcmode
                  , 'ERROR : ' || sqlerrm);
    raise;
end custpo_hold;

procedure update_status(p_status_code varchar2, p_org_id number, p_line_id number) is
  x_return_status varchar2(100);
  l_error_message varchar2(400);

  
begin
  mo_global.set_policy_context('S', p_org_id);

  oe_order_wf_util.
    update_flow_status_code(p_header_id => null
                          , p_line_id => p_line_id
                          , p_flow_status_code => p_status_code
                          , x_return_status => x_return_status);


  debug_log('SO Update Line Status End - ' || p_line_id || ' - ' || p_status_code);
exception
  when others then
    l_error_message := 'Unexpected Error In xx_om_update_sales_line procedure ' || substr(sqlerrm, 11, 150);
    debug_log(l_error_message);
    raise;
end update_status;
end xxintg_om_eval_orders_pkg; 
/
