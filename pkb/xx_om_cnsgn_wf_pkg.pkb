DROP PACKAGE BODY APPS.XX_OM_CNSGN_WF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_CNSGN_WF_PKG" as
  c_created_by_module constant varchar2(100) := 'ONT_PROCESS_ORDER_API';
  cursor so_dt_address_cur(p_site_use_id in number) is
    select loc.address1, loc.address2, loc.city, loc.state, loc.postal_code
    from   hz_cust_site_uses_all su, hz_cust_acct_sites_all cas, hz_party_sites ps, hz_locations loc
    where      su.site_use_id = p_site_use_id
           and su.cust_acct_site_id = cas.cust_acct_site_id
           and cas.party_site_id = ps.party_site_id
           and ps.location_id = loc.location_id;
  cursor po_hold_line_type_cur(p_line_type in varchar2) is
    select lu.meaning
    from   fnd_lookup_values lu
    where      lu.lookup_type = 'XXOM_PO_HOLD_LINE_TYPES'
           and lu.meaning = p_line_type
           and lu.language = 'US'
           and lu.enabled_flag = 'Y'
           and sysdate between lu.start_date_active and nvl(lu.end_date_active, sysdate + 1);
  procedure log_message(p_log_message in varchar2) is
    pragma autonomous_transaction;
  begin
    insert into xxintg_cnsgn_cmn_log_tbl
    values      (xxintg_cnsgn_cmn_log_seq.nextval, 'CONSGN-WF', p_log_message, sysdate);
    commit;
    dbms_output.put_line('log message: ' || p_log_message);
  end LOG_MESSAGE;
  procedure create_location(p_party_id in number, p_loc_data in so_dt_address_cur%rowtype, x_location_id out number) is
    v_location_rec HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    v_location_id number;
    v_return_status varchar2(2000);
    v_msg_count number;
    v_msg_data varchar2(20000);
    cursor existing_loc_cur(p_party_id in number
                          , p_loc_data so_dt_address_cur%rowtype) is
      select loc.location_id
      from   hz_party_sites ps, hz_locations loc
      where      loc.location_id = ps.location_id
             and ps.party_id = p_party_id
             and loc.address1 = p_loc_data.address1
             and loc.postal_code = p_loc_data.postal_code;
  begin
    log_message('- In create_location');
    open existing_loc_cur(p_party_id, p_loc_data);
    fetch existing_loc_cur into v_location_id;
    if existing_loc_cur%found then
      log_message('- - Location already exists: ' || v_location_id || '  Continuing...');
    else
      v_location_rec.country := 'US';
      v_location_rec.address1 := p_loc_data.address1;
      v_location_rec.address2 := p_loc_data.address2;
      v_location_rec.city := p_loc_data.city;
      v_location_rec.postal_code := p_loc_data.postal_code;
      v_location_rec.state := p_loc_data.state;
      v_location_rec.created_by_module := c_created_by_module;
      HZ_LOCATION_V2PUB.CREATE_LOCATION(p_init_msg_list => FND_API.G_TRUE
                                      , p_location_rec => v_location_rec
                                      , x_location_id => v_location_id
                                      , x_return_status => v_return_status
                                      , x_msg_count => v_msg_count
                                      , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created Location ID: ' || v_location_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_loc_cur;
    x_location_id := v_location_id;
  end create_location;
  procedure create_sites(p_party_id in number
                       , p_cust_acct_id in number
                       , p_location_id in number
                       , p_salesrep_number in varchar2
                       , x_cust_acct_site_id   out number) is
    v_party_site_rec HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
    v_party_site_id number;
    v_party_site_num varchar2(100);
    v_cust_acct_site_rec HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
    v_cust_acct_site_id number;
    v_return_status varchar2(2000);
    v_msg_count number;
    v_msg_data varchar2(20000);
    cursor existing_ps_cur(p_party_id number, p_location_id number) is
      select ps.party_site_id
      from   hz_party_sites ps
      where  ps.location_id = p_location_id and ps.party_id = p_party_id;
    cursor existing_cas_cur(p_cust_acct_id number, p_party_site_id number) is
      select cust_acct_site_id
      from   hz_cust_acct_sites_all
      where  cust_account_id = p_cust_acct_id and party_site_id = p_party_site_id;
  begin
    log_message('- In create_sites');
    open existing_ps_cur(p_party_id, p_location_id);
    fetch existing_ps_cur into v_party_site_id;
    if existing_ps_cur%found then
      log_message('- - Party Site already exists: ' || v_party_site_id || '  Continuing...');
    else
      v_party_site_rec.party_id := p_party_id;
      v_party_site_rec.location_id := p_location_id;
      v_party_site_rec.attribute1 := p_salesrep_number;
      v_party_site_rec.created_by_module := c_created_by_module;
      HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE(p_init_msg_list => FND_API.G_TRUE
                                          , p_party_site_rec => v_party_site_rec
                                          , x_party_site_id => v_party_site_id
                                          , x_party_site_number => v_party_site_num
                                          , x_return_status => v_return_status
                                          , x_msg_count => v_msg_count
                                          , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created Party Site ID: ' || v_party_site_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_ps_cur;
    open existing_cas_cur(p_cust_acct_id, v_party_site_id);
    fetch existing_cas_cur into v_cust_acct_site_id;
    if existing_cas_cur%found then
      log_message('- - Cust Acct Site already exists: ' || v_cust_acct_site_id || '  Continuing...');
    else
      v_cust_acct_site_rec.cust_account_id := p_cust_acct_id;
      v_cust_acct_site_rec.party_site_id := v_party_site_id;
      v_cust_acct_site_rec.created_by_module := c_created_by_module;
      HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE(p_init_msg_list => FND_API.G_TRUE
                                                     , p_cust_acct_site_rec => v_cust_acct_site_rec
                                                     , x_cust_acct_site_id => v_cust_acct_site_id
                                                     , x_return_status => v_return_status
                                                     , x_msg_count => v_msg_count
                                                     , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created Cust Acct Site ID: ' || v_cust_acct_site_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_cas_cur;
    x_cust_acct_site_id := v_cust_acct_site_id;
  end create_sites;
  procedure create_site_use(p_cust_acct_site_id in number, p_site_use_code in varchar2, x_site_use_id out number) is
    v_site_use_rec HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    v_site_use_id number;
    v_st_site_use_rec HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    v_st_site_id number;
    v_cust_profile_rec HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    v_return_status varchar2(2000);
    v_msg_count number;
    v_msg_data varchar2(20000);
    cursor existing_su_cur(p_cust_acct_site_id number, p_site_use_code varchar2) is
      select site_use_id
      from   hz_cust_site_uses_all
      where  cust_acct_site_id = p_cust_acct_site_id and site_use_code = p_site_use_code and status = 'A';
  begin
    log_message('- In create_site_use ' || p_site_use_code);
    open existing_su_cur(p_cust_acct_site_id, p_site_use_code);
    fetch existing_su_cur into v_site_use_id;
    if existing_su_cur%found then
      log_message('- - ' || p_site_use_code || ' Cust Site Use already exists: ' || v_site_use_id || '  Continuing...');
    else
      v_site_use_rec.cust_acct_site_id := p_cust_acct_site_id;
      v_site_use_rec.site_use_code := p_site_use_code;
      v_site_use_rec.created_by_module := c_created_by_module;
      HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(p_init_msg_list => FND_API.G_TRUE
                                                    , p_cust_site_use_rec => v_site_use_rec
                                                    , p_customer_profile_rec => v_cust_profile_rec
                                                    , p_create_profile => FND_API.G_FALSE
                                                    , p_create_profile_amt => FND_API.G_FALSE
                                                    , x_site_use_id => v_site_use_id
                                                    , x_return_status => v_return_status
                                                    , x_msg_count => v_msg_count
                                                    , x_msg_data => v_msg_data);
      if v_return_status = FND_API.G_RET_STS_SUCCESS then
        log_message('- - Created ' || p_site_use_code || ' Site Use ID: ' || v_site_use_id);
      else
        log_message('- - x_return_status = ' || substr(v_return_status, 1, 255));
        log_message('- - x_msg_count = ' || to_char(v_msg_count));
        log_message('- - x_msg_data = ' || substr(v_msg_data, 1, 255));
        if v_msg_count > 1 then
          for I in 1 .. v_msg_count loop
            log_message('- - ' || I || '. ' || substr(FND_MSG_PUB.GET(p_encoded => FND_API.G_FALSE), 1, 255));
          end loop;
        end if;
      end if;
    end if;
    close existing_su_cur;
    x_site_use_id := v_site_use_id;
  end create_site_use;
  procedure create_rep_deliver_to(p_salesrep_id in number
                                , p_so_deliver_to_org_id in number
                                , p_salesrep_number in varchar2
                                , p_location_id in number
                                , x_iso_deliver_to_org_id   out number) is
    so_dt_address_rec so_dt_address_cur%rowtype;
    l_cust_acct_id number;
    l_party_id number;
    l_salesrep_number varchar2(50);
    l_location_id number;
    l_cust_acct_site_id number;
  begin
    if p_so_deliver_to_org_id is null then
      raise no_data_found;
    end if;
    open so_dt_address_cur(p_so_deliver_to_org_id);
    fetch so_dt_address_cur into so_dt_address_rec;
    if so_dt_address_cur%notfound then
      close so_dt_address_cur;
      log_message('Csnnot locate SO DT Address Data from SU: ' || p_so_deliver_to_org_id);
      raise no_data_found;
    else
      close so_dt_address_cur;
    end if;
    log_message('Trying to create a deliver to location.');
    begin
      select pla.customer_id, hca.party_id, p_salesrep_number
      into   l_cust_acct_id, l_party_id, l_salesrep_number
      from   po_location_associations_all pla, hz_cust_accounts hca
      where  location_id = p_location_Id and pla.customer_id = hca.cust_account_Id;
    exception
      when others then
        raise no_data_found;
    end;
    log_message('cust_account_id: ' || l_cust_acct_id);
    create_location(p_party_id => l_party_id, p_loc_data => so_dt_address_rec, x_location_id => l_location_id);
    log_message('location_id: ' || l_location_id);
    create_sites(p_party_id => l_party_id
               , p_cust_acct_id => l_cust_acct_id
               , p_location_id => l_location_id
               , p_salesrep_number => l_salesrep_number
               , x_cust_acct_site_id => l_cust_acct_site_id);
    log_message('cust_acct_site_id: ' || l_cust_acct_site_id);
    create_site_use(p_cust_acct_site_id => l_cust_acct_site_id, p_site_use_code => 'DELIVER_TO', x_site_use_id => x_iso_deliver_to_org_id);
    log_message('site_use_id: ' || x_iso_deliver_to_org_id);
  exception
    when no_data_found then
      x_iso_deliver_to_org_id := null;
    when others then
      x_iso_deliver_to_org_id := null;
  end create_rep_deliver_to;
  procedure copy_attachments(p_from_header_id in number, p_to_header_id in number) is
    v_attachment_status varchar2(30);
  begin
    oe_atchmt_util.copy_attachments(p_entity_code => oe_globals.g_entity_header
                                  , p_from_entity_id => p_from_header_id
                                  , p_to_entity_id => p_to_header_id
                                  , p_manual_attachments_only => 'Y'
                                  , x_return_status => v_attachment_status);
    log_message('Attachment copy status: ' || v_attachment_status);
  end copy_attachments;
  procedure create_so(p_header_Id in number, px_return_status out varchar2, x_new_order_number out number) is
    l_header_rec oe_order_pub.header_rec_type;
    l_line_tbl oe_order_pub.line_tbl_type;
    l_header_rec_out oe_order_pub.header_rec_type;
    l_header_val_rec_out oe_order_pub.header_val_rec_type;
    l_header_adj_tbl_out oe_order_pub.header_adj_tbl_type;
    l_header_adj_val_tbl_out oe_order_pub.header_adj_val_tbl_type;
    l_header_price_att_tbl_out oe_order_pub.header_price_att_tbl_type;
    l_header_adj_att_tbl_out oe_order_pub.header_adj_att_tbl_type;
    l_header_adj_assoc_tbl_out oe_order_pub.header_adj_assoc_tbl_type;
    l_header_scredit_tbl_out oe_order_pub.header_scredit_tbl_type;
    l_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    l_line_tbl_out oe_order_pub.line_tbl_type;
    l_line_val_tbl_out oe_order_pub.line_val_tbl_type;
    l_line_adj_tbl_out oe_order_pub.line_adj_tbl_type;
    l_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    l_line_adj_val_tbl_out oe_order_pub.line_adj_val_tbl_type;
    l_line_price_att_tbl_out oe_order_pub.line_price_att_tbl_type;
    l_line_adj_att_tbl_out oe_order_pub.line_adj_att_tbl_type;
    l_line_adj_assoc_tbl_out oe_order_pub.line_adj_assoc_tbl_type;
    l_line_scredit_tbl oe_order_pub.line_scredit_tbl_type;
    l_line_scredit_val_tbl oe_order_pub.line_scredit_val_tbl_type;
    l_line_scredit_tbl_out oe_order_pub.line_scredit_tbl_type;
    l_line_scredit_val_tbl_out oe_order_pub.line_scredit_val_tbl_type;
    l_lot_serial_tbl_out oe_order_pub.lot_serial_tbl_type;
    l_lot_serial_val_tbl_out oe_order_pub.lot_serial_val_tbl_type;
    l_request_tbl oe_order_pub.request_tbl_type;
    l_request_out_tbl oe_order_pub.request_tbl_type;
    x_return_status varchar2(1);
    x_msg_count number;
    x_msg_data varchar2(4000);
    l_api_version_number number := 1;
    l_order_number number;
    l_org_id number;
    l_ship_to number;
    l_site_use_id number;
    l_sold_to_org_id number;
    l_location_id number;
    l_ship_method_code varchar2(100);
    l_temp_employee_id number;
    l_user_id number;
    i integer;
    l_msg_index number;
    l_kit_number varchar2(100);
    l_ship_from_org_id number;
    l_salesrep_id number;
    l_subinventory varchar2(100);
    l_salesrep_number varchar2(50);
    l_deliver_to_org_id number;
    l_srep_dt_org_id number;
    l_pr_status varchar2(50);
    l_attribute1 varchar2(400);
    l_attribute2 varchar2(400);
    l_attribute3 varchar2(400);
    l_attribute4 varchar2(400);
    l_attribute9 varchar2(400);
    l_attribute20 varchar2(400);
    x_iso_deliver_to_org_id number;
    l_cs_sold_to number;
    l_repl_count number;
    cursor c1(c_header_id in number) is
      select line_id, inventory_item_id, ordered_quantity, line_number
      from   oe_order_lines_all
      where      header_id = c_header_id
             and line_type_id = Oe_Sys_Parameters.value('INTG_REPLENISHMENT_LINE_TYPE', org_id)
             and nvl(cancelled_flag, 'N') = 'N';
  begin
    begin
      select order_number, org_id, ship_to_org_id, shipping_method_code, created_by, salesrep_id, deliver_to_org_id, attribute1, attribute2
           , attribute3, attribute4, attribute9, attribute20, sold_to_org_id, org_id
      into   l_order_number, l_org_id, l_ship_to, l_ship_method_code, l_user_id, l_salesrep_id, l_deliver_to_org_id, l_attribute1
           , l_attribute2, l_attribute3, l_attribute4, l_attribute9, l_attribute20, l_cs_sold_to, l_org_id
      from   oe_order_headers_all
      where  header_id = p_header_id;
    exception
      when others then
        log_message('Error in getting charge sheet order information for header_Id: ' || p_header_id);
    end;
    begin
      select count(*)
      into   l_repl_count
      from   oe_order_lines_all
      where      header_id = p_header_id
             and line_type_id = Oe_Sys_Parameters.value('INTG_REPLENISHMENT_LINE_TYPE', org_id)
             and nvl(cancelled_flag, 'N') = 'N';
    exception
      when others then
        l_repl_count := 0;
    end;
     if l_repl_count > 0 then
      begin
        select employee_id
        into   l_temp_employee_id
        from   fnd_user
        where  user_id = l_user_id;
      exception
        when others then
          select user_id
          into   l_user_id
          from   fnd_user
          where  user_name = 'MARY.SCOZ';
      end;
      fnd_global.apps_initialize(user_id => l_user_id, resp_id => 21623, resp_appl_id => 660);
      mo_global.set_policy_context('S', l_org_id);
      mo_global.init('ONT');
      begin
        select max(subinventory)
        into   l_subinventory
        from   oe_order_lines_all
        where      header_Id = p_header_id
               and line_type_id = Oe_Sys_Parameters.value('INTG_REPLENISHMENT_LINE_TYPE', org_id)
               and subinventory is not null;
        log_message('Subinventory for the replenishment lines :' || l_subinventory);
      exception
        when others then
          l_subinventory := null;
          log_message('Subinventory is not found in the charge sheet order for Replenishment lines: ' || p_header_id);
      end;
      select salesrep_number
      into   l_salesrep_number
      from   jtf_rs_salesreps
      where  salesrep_id = l_salesrep_id;
      log_message('Salesrep Number for the sales rep ID from charge sheet order :' || l_salesrep_number);
      if l_subinventory is not null then
        begin
          select location_id
          into   l_location_id
          from   mtl_secondary_inventories
          where  secondary_inventory_name = l_subinventory
                 and organization_id = (select organization_id
                                        from   mtl_parameters
                                        where  organization_code = '150');
        exception
          when others then
            log_message('Location ID is missing for the subinventory :' || l_subinventory);
        end;
      else
        log_message('Try getting the Subinventory based on salesrep number in the charge sheet :' || l_salesrep_number);
        begin
          select msi.secondary_inventory_name, location_id
          into   l_subinventory, l_location_id
          from   mtl_secondary_inventories msi, mtl_item_locations_kfv milk, mtl_parameters mp
          where      mp.organization_code = '150'
                 and mp.organization_id = msi.organization_id
                 and msi.organization_id = milk.organization_id
                 and msi.secondary_inventory_name = milk.subinventory_code
                 and nvl(milk.attribute3, msi.attribute2) = l_salesrep_number
                 and (milk.disable_date is null or trunc(milk.disable_date) > sysdate);
        exception
          when no_data_found then
            log_message('Cannot find subinventory based on salesrep number for: ' || l_salesrep_number);
        end;
      end if;
      if l_location_id is not null then
        select customer_Id, site_use_id
        into   l_sold_to_org_id, l_site_use_id
        from   po_location_associations_all
        where  location_id = l_location_id;
        log_message('Customer information found based on location for location_id: ' || l_location_id);
      else
        log_message('Customer information not found for the location ID: ' || l_location_id);
        fnd_message.set_name('ONT', 'INTG_PROD_REQ_CUST_INFO_MISS');
        oe_msg_pub.add;
      end if;
      l_header_rec := oe_order_pub.g_miss_header_rec;
      l_header_rec.operation := oe_globals.g_opr_create;
      l_header_rec.order_type_id := 1123;
      l_header_rec.sold_to_org_id := l_sold_to_org_id;
      l_header_rec.ship_to_org_id := l_site_use_id;
      l_header_rec.sales_channel_code := 'FIA';
      l_header_rec.shipping_method_code := l_ship_method_code;
      l_header_rec.org_id := l_org_id;
      l_header_rec.salesrep_id := -3;
      l_header_rec.transactional_curr_code := 'USD';
      l_header_rec.context := 'Consignment';
      l_header_rec.attribute1 := l_attribute1;
      l_header_rec.attribute2 := l_attribute2;
      l_header_rec.attribute3 := l_attribute3;
      l_header_rec.attribute4 := l_attribute4;
      l_header_rec.attribute9 := l_attribute9;
      l_header_rec.attribute14 := l_order_number;
      l_header_rec.attribute20 := l_attribute20;
      begin
        select max(attribute1)
        into   l_kit_number
        from   oe_order_lines_all
        where      header_id = p_header_id
               and context = 'Consignment'
               and line_type_id = (select line_type_id
                                   from   oe_line_types_v
                                   where  name = 'Replenishment');
      exception
        when others then
          l_kit_number := null;
      end;
      x_iso_deliver_to_org_id := null;
      if l_cs_sold_to = l_sold_to_org_id then
        l_header_rec.deliver_to_org_id := l_deliver_to_org_id;
      else
        if l_deliver_to_org_id is not null then
          create_rep_deliver_to(p_salesrep_id => l_salesrep_id
                              , p_so_deliver_to_org_id => l_deliver_to_org_id
                              , p_salesrep_number => l_salesrep_number
                              , p_location_id => l_location_id
                              , x_iso_deliver_to_org_id => l_srep_dt_org_id);
          if l_srep_dt_org_id is not null then
            l_header_rec.deliver_to_org_id := l_srep_dt_org_id;
          end if;
        end if;
      end if;
      l_header_rec.cust_po_number := l_kit_number;
      l_header_rec.ordered_date := sysdate;
      l_line_tbl := oe_order_pub.g_miss_line_tbl;
      i := 1;
      for j in c1(p_header_id) loop
        l_ship_from_org_id := null;
        select default_shipping_org
        into   l_ship_from_org_id
        from   mtl_system_items_b
        where  inventory_item_id = j.inventory_item_id
               and organization_id = (select distinct master_organization_id
                                      from   mtl_parameters
                                      where  organization_code = '150');
        l_line_tbl(i) := oe_order_pub.g_miss_line_rec;
        l_line_tbl(i).operation := oe_globals.g_opr_create;
        l_line_tbl(i).inventory_item_id := j.inventory_item_id;
        l_line_tbl(i).ordered_quantity := j.ordered_quantity;
        l_line_tbl(i).cust_po_number := l_kit_number;
        l_line_tbl(i).ship_from_org_id := l_ship_from_org_id;
        i := i + 1;
      end loop;
      l_request_tbl(1).entity_code := OE_GLOBALS.G_ENTITY_HEADER;
      l_request_tbl(1).request_type := OE_GLOBALS.G_BOOK_ORDER;
      oe_order_pub.process_order(p_api_version_number => l_api_version_number
                               , p_header_rec => l_header_rec
                               , p_line_tbl => l_line_tbl
                               , p_line_adj_tbl => l_line_adj_tbl
                               , p_action_request_tbl => l_request_tbl
                               , p_line_scredit_tbl => l_line_scredit_tbl
                               , x_header_rec => l_header_rec_out
                               , x_header_val_rec => l_header_val_rec_out
                               , x_header_adj_tbl => l_header_adj_tbl_out
                               , x_header_adj_val_tbl => l_header_adj_val_tbl_out
                               , x_header_price_att_tbl => l_header_price_att_tbl_out
                               , x_header_adj_att_tbl => l_header_adj_att_tbl_out
                               , x_header_adj_assoc_tbl => l_header_adj_assoc_tbl_out
                               , x_header_scredit_tbl => l_header_scredit_tbl_out
                               , x_header_scredit_val_tbl => l_header_scredit_val_tbl_out
                               , x_line_tbl => l_line_tbl_out
                               , x_line_val_tbl => l_line_val_tbl_out
                               , x_line_adj_tbl => l_line_adj_tbl_out
                               , x_line_adj_val_tbl => l_line_adj_val_tbl_out
                               , x_line_price_att_tbl => l_line_price_att_tbl_out
                               , x_line_adj_att_tbl => l_line_adj_att_tbl_out
                               , x_line_adj_assoc_tbl => l_line_adj_assoc_tbl_out
                               , x_line_scredit_tbl => l_line_scredit_tbl_out
                               , x_line_scredit_val_tbl => l_line_scredit_val_tbl_out
                               , x_lot_serial_tbl => l_lot_serial_tbl_out
                               , x_lot_serial_val_tbl => l_lot_serial_val_tbl_out
                               , x_action_request_tbl => l_request_out_tbl
                               , x_return_status => x_return_status
                               , x_msg_count => x_msg_count
                               , x_msg_data => x_msg_data);
      log_message('x_return_status from create order = ' || substr(x_return_status, 1, 255));
      log_message('x_msg_count from create order = ' || to_char(x_msg_count));
      log_message('x_msg_data from create order= ' || substr(x_msg_data, 1, 255));
      log_message('New Order Number = ' || l_header_rec_out.order_number);
      px_return_status := x_return_status;
      x_new_order_number := l_header_rec_out.order_number;
      if x_new_order_number is not null then
        select b.meaning
        into   l_pr_status
        from   oe_order_headers_all a, oe_lookups b
        where  header_Id = l_header_rec_out.header_id and b.lookup_type = 'FLOW_STATUS' and a.flow_status_code = b.lookup_code;
        update oe_order_headers_all
        set    context = 'Consignment', attribute14 = x_new_order_number || ' - ' || l_pr_status
        where  header_id = p_header_id;
        copy_attachments(p_header_id, l_header_rec_out.header_id);
      end if;
      for k in 1 .. x_msg_count loop
        oe_msg_pub.get(p_msg_index => k, p_encoded => FND_API.G_FALSE, p_data => x_msg_data, p_msg_index_out => l_msg_index);
        log_message('- - x_msg_data from create order loop = ' || substr(x_msg_data, 1, 255));
        if x_new_order_number is null then
          update oe_order_headers_all
          set    context = 'Consignment', attribute14 = substr(x_msg_data, 1, 240)
          where  header_id = p_header_id;
        end if;
      end loop;
    end if;
  end;
  procedure create_product_request(itemtype in   varchar2
                                 , itemkey in    varchar2
                                 , actid in      number
                                 , funcmode in   varchar2
                                 , resultout in out nocopy varchar2) is
    l_header_id number;
    x_return_status varchar2(100);
    x_prod_req_number number;
    l_org_id number;
    l_cs_order_type number;
  begin
    l_header_id := to_number(itemkey);
    select org_id,order_type_id
    into   l_org_id,l_cs_order_type
    from   oe_order_headers_all
    where  header_id = l_header_id;
    if l_cs_order_type=Oe_Sys_Parameters.value('INTG_CHARGE_SHEET_ORDER_TYPE', l_org_id) then
    if l_org_id = 82 then
      create_so(l_header_id, x_return_status, x_prod_req_number);
    else
      create_ous_so(l_header_id, x_return_status, x_prod_req_number);
    end if;
    end if;
    if x_prod_req_number is not null then
      resultout := 'COMPLETE:Y';
    else
      resultout := 'COMPLETE:N';
    end if;
  end create_product_request;
  procedure xx_om_validate_po(itemtype in   varchar2
                            , itemkey in    varchar2
                            , actid in      number
                            , funcmode in   varchar2
                            , resultout   out nocopy varchar2) is
    cursor cur_copy_ord(p_org_id number, p_line_id number) is
      select ooha.cust_po_number
           , (select NAME
              from   oe_transaction_types_tl
              where  transaction_type_id = oola.line_type_id and rownum < 2)
               line_type
           , ooha.attribute5 -- Fix For Point# 8
      from   oe_order_lines oola, oe_order_headers ooha
      where  oola.org_id = p_org_id and oola.line_id = p_line_id and oola.header_id = ooha.header_id;
    -- Cursor to verify line hOLD
    cursor c_chk_hold is
      select 'Y'
      from   oe_order_holds a, oe_hold_sources b, oe_hold_definitions c
      where      1 = 1
             and a.line_id = to_number(itemkey)
             and a.hold_source_id = b.hold_source_id
             and c.hold_id = b.hold_id
             and c.NAME = 'Awaiting PO Hold'
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
      open po_hold_line_type_cur(rec_copy_ord.line_type);
      fetch po_hold_line_type_cur into l_temp;
      if po_hold_line_type_cur%found then
        l_hold_line_type := 'Y';
      end if;
      close po_hold_line_type_cur;
      --IF rec_copy_ord.line_type IN
      --   ('Bill Only Line', 'Replenishment', 'Non-Replenishment') THEN
      if l_hold_line_type = 'Y' then
        x_hold_exists := 'N';
        open c_chk_hold;
        fetch c_chk_hold into x_hold_exists;
        close c_chk_hold;
        if rec_copy_ord.cust_po_number is null and x_hold_exists = 'Y' then
          resultout := 'COMPLETE:N';
        elsif rec_copy_ord.cust_po_number is not null and x_hold_exists = 'N' then
          resultout := 'COMPLETE:Y';
        else
          resultout := 'COMPLETE:N';
        end if;
      else
        resultout := 'COMPLETE:Y';
      end if;
    end loop;
  exception
    when others then
      l_err_msg := substr(sqlerrm, 1, 130);
      wf_core.CONTEXT('xx_om_consignment_order_pkg'
                    , 'xx_om_validate_po'
                    , itemtype
                    , itemkey
                    , 'Error ' || l_err_msg);
      raise;
  end xx_om_validate_po;
  -- ==============================================================================================
  -- Name           : xx_om_apply_cust_po_hold
  -- Description    : Procedure To Put Cust PO Number HOLD
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  procedure xx_om_custpo_hold(itemtype in   varchar2
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
    -- Cursor to fetch line details of the SO
    cursor c_oe_order_lines(p_itemkey number) is
      select oel.line_id
           , oel.ship_from_org_id
           , oel.header_id
           , oel.order_source_id
           , oel.inventory_item_id
           , oeh.cust_po_number
           , (select NAME
              from   oe_transaction_types_tl
              where  transaction_type_id = oel.line_type_id and rownum < 2)
               line_type
           , oel.line_number
           , oeh.order_number
           , oel.last_updated_by
           , oeh.attribute5
      from   oe_order_lines oel, oe_order_headers oeh
      where  line_id = p_itemkey and oeh.header_id = oel.header_id;
    -- Cursor to fetch HOLD ID
    cursor c_hold_id is
      select hold_id
      from   oe_hold_definitions
      where      NAME = 'Awaiting PO Hold'
             and type_code = 'HOLD'
             and trunc(sysdate) between nvl(start_date_active, trunc(sysdate)) and nvl(end_date_active, trunc(sysdate))
             and item_type = 'OEOL';
    -- Cursor to verify line hOLD
    cursor c_chk_hold is
      select 'Y'
      from   oe_order_holds a, oe_hold_sources b, oe_hold_definitions c
      where      1 = 1
             and a.line_id = to_number(itemkey)
             and a.hold_source_id = b.hold_source_id
             and c.hold_id = b.hold_id
             and c.NAME = 'Awaiting PO Hold'
             and c.type_code = 'HOLD'
             and a.released_flag = 'N'
             and a.hold_release_id is null
             and trunc(sysdate) between nvl(c.start_date_active, trunc(sysdate)) and nvl(c.end_date_active, trunc(sysdate))
             and c.item_type = 'OEOL';
  begin
    if (funcmode = 'RUN') then
      -- Extract WF data
      l_org_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ORG_ID');
      l_user_id := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
      x_release_reason_code := 'SUPERVISOR_APPROVE';
      for rec_oe_order_lines in c_oe_order_lines(to_number(itemkey)) loop
        --A lookup now allows line types to be added to/removed from thios logic on the fly
        l_hold_line_type := 'N';
        open po_hold_line_type_cur(rec_oe_order_lines.line_type);
        fetch po_hold_line_type_cur into l_temp;
        if po_hold_line_type_cur%found then
          l_hold_line_type := 'Y';
        end if;
        close po_hold_line_type_cur;
        if l_hold_line_type = 'Y' then
          --IF rec_oe_order_lines.line_type IN
          --   ('Bill Only Line', 'Replenishment', 'Non-Replenishment') THEN
          x_order_tbl(1).header_id := rec_oe_order_lines.header_id;
          x_order_tbl(1).line_id := rec_oe_order_lines.line_id;
          x_hold_exists := 'N';
          open c_chk_hold;
          fetch c_chk_hold into x_hold_exists;
          close c_chk_hold;
          open c_hold_id;
          fetch c_hold_id into x_hold_id;
          close c_hold_id;
          if x_hold_id is not null and x_hold_exists = 'N' then -- and rec_oe_order_lines.cust_po_number is null then
            --xx_om_update_sales_line('AWAITING_PO', l_org_id, itemkey);
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
          elsif x_hold_id is not null and x_hold_exists = 'Y' and rec_oe_order_lines.cust_po_number is not null then
            --xx_om_update_sales_line('BOOKED', l_org_id, itemkey);
            update oe_order_lines_all
            set    cust_po_number = (select cust_po_number
                                     from   oe_order_headers_all
                                     where  header_Id = rec_oe_order_lines.header_id)
            where  line_id = rec_oe_order_lines.line_id
                   and (cust_po_number is null
                        or cust_po_number <> (select cust_po_number
                                              from   oe_order_headers_all
                                              where  line_id = rec_oe_order_lines.line_id));
            oe_holds_pub.release_holds(p_api_version => 1.0
                                     , p_init_msg_list => fnd_api.g_true
                                     , p_commit => fnd_api.g_false
                                     , p_validation_level => fnd_api.g_valid_level_full
                                     , p_order_tbl => x_order_tbl
                                     , p_hold_id => x_hold_id
                                     , p_release_reason_code => x_release_reason_code
                                     , p_release_comment => null
                                     , p_check_authorization_flag => null
                                     , x_return_status => x_return_status
                                     , x_msg_count => x_msg_count
                                     , x_msg_data => x_msg_data);
          end if;
        end if;
      end loop;
    end if;
    resultout := 'COMPLETE:COMPLETE';
    return;
  exception
    when others then
      wf_core.CONTEXT('xx_om_cnsgn_wf_pkg'
                    , 'xx_om_custpo_hold '
                    , itemtype
                    , itemkey
                    , to_char(actid)
                    , funcmode
                    , 'ERROR : ' || sqlerrm);
      raise;
  end xx_om_custpo_hold;
  procedure xx_om_create_ir_iso(itemtype in   varchar2
                              , itemkey in    varchar2
                              , actid in      number
                              , funcmode in   varchar2
                              , resultout in out nocopy varchar2) is
    l_int_req_ret_sts varchar2(1);
    l_req_header_rec po_create_requisition_sv.header_rec_type;
    l_req_line_tbl po_create_requisition_sv.line_tbl_type;
    l_created_by number;
    l_org_id number;
    l_preparer_id number;
    l_destination_org_id number;
    l_deliver_to_locn_id number;
    l_msg_count number;
    l_msg_data varchar2(2000);
    k number := 0;
    j number := 0;
    l_item_exists varchar2(50);
    l_item varchar2(50);
    v_msg_index_out number;
    g_pkg_name varchar2(30) := 'auto_create_internal_req';
    l_header_id number;
    x_return_status varchar2(1000);
    l_dest_subinventory mtl_secondary_inventories.secondary_inventory_name%type;
    l_order_locator_id mtl_item_locations.INVENTORY_LOCATION_ID%type;
    l_source_org_code varchar2(10);
    l_dest_lpn_id number;
    l_cust_po_number oe_order_headers.cust_po_number%type;
    l_temp_employee_id number;
    l_no_org_count number;
    l_cs_order_number varchar2(100);
    l_pr_order_number number;
    l_pr_order_status varchar2(400);
    cursor ord_hdr_cur(p_header_id in number) is
      select created_by, org_id, cust_po_number, attribute14, order_number, flow_status_code
      from   oe_order_headers
      where  header_id = p_header_id and nvl(context, 'Consignment') = 'Consignment';
    cursor ord_line_cur(p_header_id in number) is
      select line_id, order_quantity_uom, ordered_quantity, ship_to_org_id, inventory_item_id, schedule_ship_date, org_id, ship_from_org_id
           , sold_to_org_id, subinventory, source_document_id, source_document_line_id, item_type_code
      from   oe_order_lines_all
      where  header_id = p_header_id and nvl(cancelled_flag, 'N') = 'N';
    -- and nvl(booked_flag, 'N') = 'Y';
    cursor employee_id_cur(p_user_id in number) is
      select employee_id
      from   fnd_user
      where  user_id = p_user_id;
    cursor dest_org_locn_cur(p_cust_id in number) is
      select b.location_id, b.organization_id
      from   oe_ship_to_orgs_v a, po_location_associations b
      where  a.organization_id = b.site_use_id and a.organization_id = p_cust_id;
  begin
    oe_debug_pub.ADD(' Entering procedure auto_create_internal_req ', 2);
    l_header_id := to_number(itemkey);
    x_return_status := fnd_api.g_ret_sts_success;
    l_cust_po_number := null;
    open ord_hdr_cur(l_header_id);
    fetch ord_hdr_cur
    into l_created_by, l_org_id, l_cust_po_number, l_cs_order_number, l_pr_order_number, l_pr_order_status;
    close ord_hdr_cur;
    oe_debug_pub.ADD('auto_create_internal_req after hdr query ', 2);
    begin
      open employee_id_cur(l_created_by);
      fetch employee_id_cur into l_preparer_id;
      close employee_id_cur;
    exception
      when no_data_found then
        l_preparer_id := null;
      when others then
        x_return_status := fnd_api.g_ret_sts_unexp_error;
        raise fnd_api.g_exc_unexpected_error;
    end;
    if l_preparer_id is null then
      fnd_message.set_name('XXINTG', 'INTG_DEL_TO_PERSON_NOT_FOUND');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      raise fnd_api.g_exc_error;
    end if;
    l_temp_employee_id := Oe_Sys_Parameters.value('ONT_EMP_ID_FOR_SS_ORDERS', l_org_id);
    if l_temp_employee_id is null then
      fnd_message.set_name('XXINTG', 'INTG_DEFAULT_PREP_NOT_FOUND');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      raise fnd_api.g_exc_error;
    end if;
    select count(*)
    into   l_no_org_count
    from   oe_order_lines_all
    where  header_id = l_header_id and ship_from_org_id is null;
    if l_no_org_count > 0 then
      fnd_message.set_name('XXINTG', 'XXOM_ORDER_BOOK_PROD_REQ');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      raise fnd_api.g_exc_error;
    end if;
    l_req_header_rec.preparer_id := l_temp_employee_id;
    l_req_header_rec.summary_flag := 'N';
    l_req_header_rec.enabled_flag := 'Y';
    l_req_header_rec.authorization_status := 'APPROVED';
    l_req_header_rec.type_lookup_code := 'INTERNAL';
    l_req_header_rec.transferred_to_oe_flag := 'Y';
    l_req_header_rec.org_id := l_org_id;
    log_message('Header Data Populated ' || l_header_id);
    for cur_ord_line in ord_line_cur(l_header_id) loop
      j := j + 1;
      if cur_ord_line.item_type_code <> oe_globals.g_item_standard then
        log_message('Item type check' || l_header_id || ' / ' || cur_ord_line.inventory_item_id);
        fnd_message.set_name('ONT', 'ONT_ISO_ITEM_TYPE_NOT_STD');
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        raise fnd_api.g_exc_error;
      end if;
      begin
        open dest_org_locn_cur(cur_ord_line.ship_to_org_id);
        fetch dest_org_locn_cur
        into l_deliver_to_locn_id, l_destination_org_id;
        close dest_org_locn_cur;
      exception
        when no_data_found then
          l_destination_org_id := null;
          l_deliver_to_locn_id := null;
          begin
          l_destination_org_id:=Oe_Sys_Parameters.value('INTG_CONSIGNMENT_ORGANIZATION', l_org_id);

          exception
            when others then
              l_destination_org_id := null;
          end;
          begin
            select location_id
            into   l_deliver_to_locn_id
            from   po_location_associations
            where  site_use_id = cur_ord_line.ship_to_org_id;
          exception
            when others then
              l_deliver_to_locn_id := null;
          end;
      end;
      log_message('Deliver To location ID is' || l_deliver_to_locn_id);
      if l_deliver_to_locn_id is null then
        log_message('Deliver to Location Not found for ship to site_use_id' || l_header_id || ' / ' || cur_ord_line.ship_to_org_id);
        fnd_message.set_name('XXINTG', 'INTG_OM_DELIVER_TO_LOCATION');
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_error;
      end if;
      l_item_exists := 'N';
      l_item := null;
      begin
        select 'Y'
        into   l_item_exists
        from   mtl_system_items_b
        where  inventory_item_id = cur_ord_line.inventory_item_id
               and organization_id = Oe_Sys_Parameters.value('INTG_CONSIGNMENT_ORGANIZATION', l_org_id);
        log_message('Item assigned to 150?' || l_item_exists);
      exception
        when others then
          log_message('Item is not assigned to consignment organization. ' || l_header_id || ' / ' || cur_ord_line.inventory_item_id);
          select segment1
          into   l_item
          from   mtl_system_items_b
          where  inventory_item_id = cur_ord_line.inventory_item_id
                 and organization_id = (select organization_id
                                        from   mtl_parameters
                                        where  organization_code = 'MST');
          fnd_message.set_name('XXINTG', 'INTG_OM_ITEM_NOT_ASSIGNED');
          fnd_message.set_token('ITEM', l_item);
          oe_msg_pub.ADD;
          x_return_status := fnd_api.g_ret_sts_error;
          resultout := 'COMPLETE:N';
          raise fnd_api.g_exc_error;
      end;
      begin
        select secondary_inventory_name
        into   l_dest_subinventory
        from   mtl_secondary_inventories msi
        where  msi.location_id = l_deliver_to_locn_id and organization_id = l_destination_org_id;
        log_message('Destination Subinventory' || l_dest_subinventory);
      exception
        when others then
          log_message('Invalid ISO subinventory. ' || l_header_id || ' / ' || cur_ord_line.sold_to_org_id);
          fnd_message.set_name('XXINTG', 'INTG_OM_INVALID_ISO_SUBINV');
          oe_msg_pub.ADD;
          x_return_status := fnd_api.g_ret_sts_error;
          resultout := 'COMPLETE:N';
          raise fnd_api.g_exc_error;
      end;
      begin
        l_order_locator_id := null;
        if l_dest_subinventory = 'RECONKIT' then
          select inventory_location_id
          into   l_order_locator_id
          from   mtl_item_locations
          where  Subinventory_code = 'RECONKIT' and segment1 = 'RECONKIT' and segment2 = 'REC' and segment3 = '001';
        elsif l_dest_subinventory = 'NEUROKIT' then
          select inventory_location_id
          into   l_order_locator_id
          from   mtl_item_locations
          where  Subinventory_code = 'NEUROKIT' and segment1 = 'NEUROKIT' and segment2 = 'NEU' and segment3 = '001';
        elsif l_dest_subinventory = 'SPINEKIT' then
          begin
            select organization_code
            into   l_source_org_code
            from   mtl_parameters
            where  organization_id = cur_ord_line.ship_from_org_id;
          exception
            when others then
              null;
          end;
          if l_source_org_code = '160' then
            select inventory_location_id
            into   l_order_locator_id
            from   mtl_item_locations
            where  Subinventory_code = 'SPINEKIT' and segment1 = 'SPINEKIT' and segment2 = 'SPI' and segment3 = 'ODC';
          elsif l_source_org_code = '180' then
            select inventory_location_id
            into   l_order_locator_id
            from   mtl_item_locations
            where  Subinventory_code = 'SPINEKIT' and segment1 = 'SPINEKIT' and segment2 = 'SPI' and segment3 = 'VDC';
          end if;
        else
          begin
            select mil.inventory_location_id
            into   l_order_locator_id
            from   mtl_item_locations mil, xxom_sales_marketing_set_v xsms
            where      mil.organization_id = l_destination_org_id
                   and upper(mil.subinventory_code) = upper(l_dest_subinventory)
                   and xsms.inventory_item_id = cur_ord_line.inventory_item_id
                   and xsms.organization_id = l_destination_org_id
                   and upper(mil.segment1) = upper(l_dest_subinventory)
                   and mil.segment2 = substr(snm_division, 1, 3)
                   and mil.segment3 = '001';
          exception
            when others then
              begin
                select mil.inventory_location_id
                into   l_order_locator_id
                from   mtl_item_locations mil
                where      mil.organization_id = l_destination_org_id
                       and upper(mil.subinventory_code) = upper(l_dest_subinventory)
                       and upper(mil.segment1) = upper(l_dest_subinventory)
                       and mil.segment2 = '001'
                       and mil.segment3 = '001';
              exception
                when others then
                  log_message(   'Error Replishment Request - Locator Derivation: '
                              || l_dest_subinventory
                              || ' for Item '
                              || cur_ord_line.inventory_item_id);
              end;
          end;
        end if;
        l_dest_lpn_id := null;
        begin
          select lpn_id
          into   l_dest_lpn_id
          from   wms_license_plate_numbers
          where  license_plate_number = l_cust_po_number;
        exception
          when others then
            log_message('LPN ID - Unable to find for - ' || l_cust_po_number);
        end;
      end;
      log_message('Destination Locator ' || l_order_locator_id);
      if l_order_locator_id is null then
        log_message('Invalid ISO Locator. ' || l_header_id || ' / ' || cur_ord_line.inventory_item_id || ' / ' || l_dest_subinventory);
        fnd_message.set_name('XXINTG', 'INTG_OM_INVALID_DEST_LOCATOR');
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_error;
      end if;
      l_req_line_tbl(j).line_num := j;
      l_req_line_tbl(j).line_type_id := 1;
      l_req_line_tbl(j).source_doc_line_reference := cur_ord_line.line_id;
      l_req_line_tbl(j).uom_code := cur_ord_line.order_quantity_uom;
      l_req_line_tbl(j).quantity := cur_ord_line.ordered_quantity;
      l_req_line_tbl(j).deliver_to_location_id := l_deliver_to_locn_id;
      l_req_line_tbl(j).destination_type_code := 'INVENTORY';
      l_req_line_tbl(j).destination_organization_id := l_destination_org_id;
      l_req_line_tbl(j).destination_subinventory := l_dest_subinventory;
      l_req_line_tbl(j).to_person_id := l_preparer_id;
      l_req_line_tbl(j).source_type_code := 'INVENTORY';
      l_req_line_tbl(j).item_id := cur_ord_line.inventory_item_id;
      l_req_line_tbl(j).need_by_date := nvl(cur_ord_line.schedule_ship_date, sysdate);
      l_req_line_tbl(j).source_organization_id := cur_ord_line.ship_from_org_id;
      l_req_line_tbl(j).org_id := cur_ord_line.org_id;
    end loop;
    oe_debug_pub.ADD(' auto_create_internal_req before PO API call ', 2);
    begin
      po_create_requisition_sv.process_requisition(px_header_rec => l_req_header_rec
                                                 , px_line_table => l_req_line_tbl
                                                 , x_return_status => l_int_req_ret_sts
                                                 , x_msg_count => l_msg_count
                                                 , x_msg_data => l_msg_data);
      if l_int_req_ret_sts = fnd_api.g_ret_sts_unexp_error then
        oe_debug_pub.ADD(' PO API call returned unexpected error ' || l_msg_data, 2);
        log_message('po_create_requisition_sv - returned unexpected error ' || l_header_id);
        log_message(l_msg_data);
        fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
        oe_msg_pub.ADD;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_unexpected_error;
      elsif l_int_req_ret_sts = fnd_api.g_ret_sts_error then
        oe_debug_pub.ADD(' PO API call returned error ' || l_msg_data, 2);
        log_message('po_create_requisition_sv - returned error ' || l_header_id);
        log_message(l_msg_data);
        fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
        oe_msg_pub.ADD;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_error;
      end if;
    end;
    if l_msg_count > 0 then
      for v_index in 1 .. l_msg_count loop
        oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => v_msg_index_out);
        log_message(l_msg_data);
      end loop;
    end if;
    if (l_req_line_tbl.count() > 0 and l_req_header_rec.requisition_header_id > 0) then
      begin
        update oe_order_headers a
        set    ATTRIBUTE14 = l_pr_order_number
                             || (select b.meaning
                                 from   oe_lookups b
                                 where  b.lookup_type = 'FLOW_STATUS' and l_pr_order_status = b.lookup_code)
        where  order_type_id = 1124 and context = 'Consignment' and order_number = l_cs_order_number;
      exception
        when others then
          null;
      end;
      log_message('Updating Header - Related Order ' || l_header_id);
      update oe_order_headers
      set    source_document_id = l_req_header_rec.requisition_header_id
           , orig_sys_document_ref = l_req_header_rec.segment1
           , source_document_type_id = oe_globals.g_order_source_internal
           , order_source_id = oe_globals.g_order_source_internal
      where  header_id = l_header_id;
      oe_debug_pub.add('auto_create_internal_req after hdr update ', 2);
      for k in 1 .. l_req_line_tbl.count loop
        if (l_req_line_tbl(k).requisition_line_id is not null) then
          update oe_order_lines
          set    source_document_id = l_req_header_rec.requisition_header_id
               , source_document_line_id = l_req_line_tbl(k).requisition_line_id
               , source_document_type_id = oe_globals.g_order_source_internal
               , orig_sys_document_ref = l_req_header_rec.segment1
               , orig_sys_line_ref = l_req_line_tbl(k).line_num
               , global_attribute14 = nvl(l_order_locator_id, global_attribute14)
               , global_attribute15 = nvl(l_dest_lpn_id, global_attribute15)
          where  oe_order_lines.line_id = l_req_line_tbl(k).source_doc_line_reference and header_id = l_header_id;
        end if;
      end loop;
      oe_debug_pub.add('auto_create_internal_req after line update ', 2);
      resultout := 'COMPLETE:Y';
      x_return_status := fnd_api.g_ret_sts_success;
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_SUCCESS');
      oe_msg_pub.ADD;
      OE_STANDARD_WF.Save_Messages;
      OE_STANDARD_WF.Clear_Msg_Context;
    else
      x_return_status := fnd_api.g_ret_sts_error;
      resultout := 'COMPLETE:N';
      raise fnd_api.g_exc_error;
    end if;
  --resultout := 'COMPLETE:Y';
  exception
    when fnd_api.g_exc_unexpected_error then
      log_message('Unexpected error in xx_om_create_ir_iso ' || l_header_id);
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
      oe_msg_pub.ADD;
      resultout := 'COMPLETE:N';
      OE_STANDARD_WF.Save_Messages;
      OE_STANDARD_WF.Clear_Msg_Context;
      oe_debug_pub.add('auto_create_internal_req: In Unexpected error', 2);
      wf_core.context('xx_om_consignment_order_pkg'
                    , 'xx_om_create_ir_iso'
                    , itemtype
                    , itemkey
                    , 'xx_om_create_ir_iso');
    when fnd_api.g_exc_error then
      log_message('Error in xx_om_create_ir_iso ' || l_header_id);
      x_return_status := fnd_api.g_ret_sts_error;
      oe_debug_pub.add('auto_create_internal_req: In execution error', 2);
      resultout := 'COMPLETE:N';
      OE_STANDARD_WF.Save_Messages;
      OE_STANDARD_WF.Clear_Msg_Context;
    when others then
      log_message('WHEN OTHERS in xx_om_create_ir_iso ' || l_header_id || ' / ' || sqlerrm);
      oe_debug_pub.add('auto_create_internal_req: In Other error', 2);
      if oe_msg_pub.check_msg_level(oe_msg_pub.g_msg_lvl_unexp_error) then
        oe_msg_pub.add_exc_msg(g_pkg_name, 'auto_create_internal_req');
      end if;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      wf_core.context('xx_om_consignment_order_pkg'
                    , 'xx_om_create_ir_iso'
                    , itemtype
                    , itemkey
                    , 'xx_om_create_ir_iso');
      resultout := 'COMPLETE:N';
      raise;
  end xx_om_create_ir_iso;
  procedure xx_om_create_ous_ir_iso(itemtype in   varchar2
                                  , itemkey in    varchar2
                                  , actid in      number
                                  , funcmode in   varchar2
                                  , resultout in out nocopy varchar2) is
    l_int_req_ret_sts varchar2(1);
    l_req_header_rec po_create_requisition_sv.header_rec_type;
    l_req_line_tbl po_create_requisition_sv.line_tbl_type;
    l_created_by number;
    l_org_id number;
    l_preparer_id number;
    l_destination_org_id number;
    l_deliver_to_locn_id number;
    l_msg_count number;
    l_msg_data varchar2(2000);
    k number := 0;
    j number := 0;
    l_item_exists varchar2(50);
    l_item varchar2(50);
    v_msg_index_out number;
    g_pkg_name varchar2(30) := 'auto_create_internal_req';
    l_header_id number;
    x_return_status varchar2(1000);
    l_order_locator_id mtl_item_locations.INVENTORY_LOCATION_ID%type;
    l_source_org_code varchar2(10);
    l_dest_lpn_id number;
    l_cust_po_number oe_order_headers.cust_po_number%type;
    l_temp_employee_id number;
    l_dest_subinventory mtl_secondary_inventories.secondary_inventory_name%type;
    l_item_type varchar2(30);
    l_no_org_count number;
    l_line_po varchar2(300);
    cursor ord_hdr_cur(p_header_id in number) is
      select created_by, org_id, attribute9 cust_po_number
      from   oe_order_headers_all
      where  header_id = p_header_id;
    cursor ord_line_cur(p_header_id in number) is
      select line_id, order_quantity_uom, ordered_quantity, ship_to_org_id, inventory_item_id, schedule_ship_date, org_id, ship_from_org_id
           , sold_to_org_id, subinventory, source_document_id, source_document_line_id, item_type_code, attribute1 cust_po_number
      from   oe_order_lines_all a
      where  header_id = p_header_id and nvl(cancelled_flag, 'N') = 'N'
             and exists
                   (select 1
                    from   oe_order_headers_all b
                    where  a.header_id = b.header_id
                           and b.order_type_id = Oe_Sys_Parameters.value('INTG_CONSIGN_PROD_REQ_ORDER_TYPE', b.org_id));
    cursor employee_id_cur(p_user_id in number) is
      select employee_id
      from   fnd_user
      where  user_id = p_user_id;
  begin
    oe_debug_pub.ADD(' Entering procedure auto_create_internal_req ', 2);
    l_header_id := to_number(itemkey);
    x_return_status := fnd_api.g_ret_sts_success;
    l_cust_po_number := null;
    open ord_hdr_cur(l_header_id);
    fetch ord_hdr_cur
    into l_created_by, l_org_id, l_cust_po_number;
    close ord_hdr_cur;
    oe_debug_pub.ADD('auto_create_internal_req after hdr query ', 2);

    begin
      open employee_id_cur(l_created_by);
      fetch employee_id_cur into l_preparer_id;
      close employee_id_cur;
    exception
      when no_data_found then
        l_preparer_id := null;
      when others then
        x_return_status := fnd_api.g_ret_sts_unexp_error;
        raise fnd_api.g_exc_unexpected_error;
    end;

    if l_preparer_id is null then
      fnd_message.set_name('XXINTG', 'INTG_DEL_TO_PERSON_NOT_FOUND');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      raise fnd_api.g_exc_error;
    end if;
    l_temp_employee_id := Oe_Sys_Parameters.value('ONT_EMP_ID_FOR_SS_ORDERS', l_org_id);
    if l_temp_employee_id is null then
      fnd_message.set_name('XXINTG', 'INTG_DEFAULT_PREP_NOT_FOUND');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      raise fnd_api.g_exc_error;
    end if;
    select count(*)
    into   l_no_org_count
    from   oe_order_lines_all
    where  header_id = l_header_id and ship_from_org_id is null;
    if l_no_org_count > 0 then
      fnd_message.set_name('XXINTG', 'XXOM_ORDER_BOOK_PROD_REQ');
      oe_msg_pub.ADD;
      x_return_status := fnd_api.g_ret_sts_error;
      raise fnd_api.g_exc_error;
    end if;
    l_req_header_rec.preparer_id := l_temp_employee_id;
    l_req_header_rec.summary_flag := 'N';
    l_req_header_rec.enabled_flag := 'Y';
    l_req_header_rec.authorization_status := 'APPROVED';
    l_req_header_rec.type_lookup_code := 'INTERNAL';
    l_req_header_rec.transferred_to_oe_flag := 'Y';
    l_req_header_rec.org_id := l_org_id;
    log_message('Header Data Populated ' || l_header_id);
    for cur_ord_line in ord_line_cur(l_header_id) loop
      j := j + 1;
      if cur_ord_line.item_type_code <> oe_globals.g_item_standard then
        log_message('Item type check' || l_header_id || ' / ' || cur_ord_line.inventory_item_id);
        fnd_message.set_name('ONT', 'ONT_ISO_ITEM_TYPE_NOT_STD');
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        raise fnd_api.g_exc_error;
      end if;
      begin
        select location_id, organization_id
        into   l_deliver_to_locn_id, l_destination_org_id
        from   po_location_associations_all
        where  site_use_id = cur_ord_line.ship_to_org_id;
      exception
        when others then
          null;
      end;
      if l_destination_org_id is null then
        l_destination_org_id := Oe_Sys_Parameters.value('INTG_CONSIGNMENT_ORGANIZATION', l_org_id);
      end if;
      log_message('Deliver To location ID is' || l_deliver_to_locn_id);
      if l_deliver_to_locn_id is null then
        log_message('Deliver to Location Not found for ship to site_use_id' || l_header_id || ' / ' || cur_ord_line.ship_to_org_id);
        fnd_message.set_name('XXINTG', 'INTG_OM_DELIVER_TO_LOCATION');
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_error;
      end if;
      if l_destination_org_id is null then
        fnd_message.set_name('XXINTG', 'INTG_CONSIGN_ORG_SETUP');
        oe_msg_pub.ADD;
        x_return_status := fnd_api.g_ret_sts_error;
        raise fnd_api.g_exc_error;
      end if;
      l_item_exists := 'N';
      l_item := null;
      begin
        select 'Y'
        into   l_item_exists
        from   mtl_system_items_b
        where  inventory_item_id = cur_ord_line.inventory_item_id and organization_id = l_destination_org_id;
        log_message('Item assigned to 150?' || l_item_exists);
      exception
        when others then
          log_message('Item is not assigned to consignment organization. ' || l_header_id || ' / ' || cur_ord_line.inventory_item_id);
          select segment1
          into   l_item
          from   mtl_system_items_b
          where  inventory_item_id = cur_ord_line.inventory_item_id
                 and organization_id = (select organization_id
                                        from   mtl_parameters
                                        where  organization_code = 'MST');
          fnd_message.set_name('XXINTG', 'INTG_OM_ITEM_NOT_ASSIGNED');
          fnd_message.set_token('ITEM', l_item);
          oe_msg_pub.ADD;
          x_return_status := fnd_api.g_ret_sts_error;
          resultout := 'COMPLETE:N';
          raise fnd_api.g_exc_error;
      end;
      if l_item_exists = 'Y' then
        begin
          select fnd.meaning
          into   l_item_type
          from   mtl_system_items_b msib, fnd_common_lookups fnd
          where      inventory_item_Id = cur_ord_line.inventory_item_id
                 and fnd.lookup_code = msib.item_type
                 and nvl(fnd.start_date_active, sysdate) <= sysdate
                 and nvl(fnd.end_date_active, sysdate) >= sysdate
                 and fnd.enabled_flag = 'Y'
                 and fnd.lookup_type = 'ITEM_TYPE'
                 and msib.organization_id = (select organization_id
                                             from   mtl_parameters
                                             where  organization_code = 'MST');
        exception
          when others then
            l_item_type := null;
            select segment1
            into   l_item
            from   mtl_system_items_b
            where  inventory_item_id = cur_ord_line.inventory_item_id
                   and organization_id = (select organization_id
                                          from   mtl_parameters
                                          where  organization_code = 'MST');
        end;
        if l_item_type is null then
          fnd_message.set_name('XXINTG', 'INTG_OM_ITEM_TYPE_SETUP');
          fnd_message.set_token('ITEM', l_item);
          oe_msg_pub.ADD;
          x_return_status := fnd_api.g_ret_sts_error;
          resultout := 'COMPLETE:N';
          raise fnd_api.g_exc_error;
        end if;
        if l_item_type = 'Surgical Kit' then
          begin
            select secondary_inventory_name
            into   l_dest_subinventory
            from   mtl_secondary_inventories msi
            where  msi.location_id = l_deliver_to_locn_id and organization_Id = l_destination_org_id;
            log_message('Destination Subinventory' || l_dest_subinventory);
          exception
            when others then
              log_message('Invalid ISO KIT subinventory. ' || l_header_id || ' / ' || cur_ord_line.sold_to_org_id);
              fnd_message.set_name('XXINTG', 'INTG_OM_INVALID_KIT_SUBINV');
              oe_msg_pub.ADD;
              x_return_status := fnd_api.g_ret_sts_error;
              resultout := 'COMPLETE:N';
              raise fnd_api.g_exc_error;
          end;
        else
          begin
            select secondary_inventory_name
            into   l_dest_subinventory
            from   mtl_secondary_inventories msi
            where  msi.secondary_inventory_name = nvl(cur_ord_line.cust_po_number, l_cust_po_number)
                   and organization_Id = l_destination_org_id;
          exception
            when others then
              log_message('Invalid ISO Comp subinventory. ' || l_header_id || ' / ' || cur_ord_line.sold_to_org_id);
              fnd_message.set_name('XXINTG', 'INTG_OM_INVALID_COMP_SUBINV');
              oe_msg_pub.ADD;
              x_return_status := fnd_api.g_ret_sts_error;
              resultout := 'COMPLETE:N';
              raise fnd_api.g_exc_error;
          end;
        end if;
      end if;
      l_req_line_tbl(j).line_num := j;
      l_req_line_tbl(j).line_type_id := 1;
      l_req_line_tbl(j).source_doc_line_reference := cur_ord_line.line_id;
      l_req_line_tbl(j).uom_code := cur_ord_line.order_quantity_uom;
      l_req_line_tbl(j).quantity := cur_ord_line.ordered_quantity;
      l_req_line_tbl(j).deliver_to_location_id := l_deliver_to_locn_id;
      l_req_line_tbl(j).destination_type_code := 'INVENTORY';
      l_req_line_tbl(j).destination_organization_id := l_destination_org_id;
      l_req_line_tbl(j).destination_subinventory := l_dest_subinventory;
      l_req_line_tbl(j).to_person_id := nvl(l_preparer_id, l_temp_employee_id);
      l_req_line_tbl(j).source_type_code := 'INVENTORY';
      l_req_line_tbl(j).item_id := cur_ord_line.inventory_item_id;
      l_req_line_tbl(j).need_by_date := nvl(cur_ord_line.schedule_ship_date, sysdate);
      l_req_line_tbl(j).source_organization_id := cur_ord_line.ship_from_org_id;
      l_req_line_tbl(j).org_id := cur_ord_line.org_id;
    end loop;
    oe_debug_pub.ADD(' auto_create_internal_req before PO API call ', 2);
    begin
      po_create_requisition_sv.process_requisition(px_header_rec => l_req_header_rec
                                                 , px_line_table => l_req_line_tbl
                                                 , x_return_status => l_int_req_ret_sts
                                                 , x_msg_count => l_msg_count
                                                 , x_msg_data => l_msg_data);
      if l_int_req_ret_sts = fnd_api.g_ret_sts_unexp_error then
        oe_debug_pub.ADD(' PO API call returned unexpected error ' || l_msg_data, 2);
        log_message('po_create_requisition_sv - returned unexpected error ' || l_header_id);
        log_message(l_msg_data);
        fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
        oe_msg_pub.ADD;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_unexpected_error;
      elsif l_int_req_ret_sts = fnd_api.g_ret_sts_error then
        oe_debug_pub.ADD(' PO API call returned error ' || l_msg_data, 2);
        log_message('po_create_requisition_sv - returned error ' || l_header_id);
        log_message(l_msg_data);
        fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
        oe_msg_pub.ADD;
        resultout := 'COMPLETE:N';
        raise fnd_api.g_exc_error;
      end if;
    end;
    if l_msg_count > 0 then
      for v_index in 1 .. l_msg_count loop
        oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => v_msg_index_out);
        log_message(l_msg_data);
      end loop;
    end if;
    if (l_req_line_tbl.count() > 0 and l_req_header_rec.requisition_header_id > 0) then
      update oe_order_headers
      set    ATTRIBUTE14 = ORIG_SYS_DOCUMENT_REF
      where  header_id = l_header_id;
      log_message('Updating Header - Related Order ' || l_header_id);
      update oe_order_headers_all
      set    source_document_id = l_req_header_rec.requisition_header_id
           , orig_sys_document_ref = l_req_header_rec.segment1
           , source_document_type_id = oe_globals.g_order_source_internal
           , order_source_id = oe_globals.g_order_source_internal
      where  header_id = l_header_id;
      oe_debug_pub.add('auto_create_internal_req after hdr update ', 2);
      for k in 1 .. l_req_line_tbl.count loop
        if (l_req_line_tbl(k).requisition_line_id is not null) then
          update oe_order_lines_all
          set    source_document_id = l_req_header_rec.requisition_header_id
               , source_document_line_id = l_req_line_tbl(k).requisition_line_id
               , source_document_type_id = oe_globals.g_order_source_internal
               , orig_sys_document_ref = l_req_header_rec.segment1
               , orig_sys_line_ref = l_req_line_tbl(k).line_num
          where  line_id = l_req_line_tbl(k).source_doc_line_reference and header_id = l_header_id;
        end if;
      end loop;
      oe_debug_pub.add('auto_create_internal_req after line update ', 2);
      resultout := 'COMPLETE:Y';
      x_return_status := fnd_api.g_ret_sts_success;
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_SUCCESS');
      oe_msg_pub.ADD;
    --OE_STANDARD_WF.Save_Messages;
    --OE_STANDARD_WF.Clear_Msg_Context;
    else
      x_return_status := fnd_api.g_ret_sts_error;
      resultout := 'COMPLETE:N';
      raise fnd_api.g_exc_error;
    end if;
  --resultout := 'COMPLETE:Y';
  exception
    when fnd_api.g_exc_unexpected_error then
      log_message('Unexpected error in xx_om_create_ir_iso ' || l_header_id);
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
      oe_msg_pub.ADD;
      resultout := 'COMPLETE:N';
      OE_STANDARD_WF.Save_Messages;
      --OE_STANDARD_WF.Clear_Msg_Context;
      oe_debug_pub.add('auto_create_internal_req: In Unexpected error', 2);
      wf_core.context('xx_om_consignment_order_pkg'
                    , 'xx_om_create_ir_iso'
                    , itemtype
                    , itemkey
                    , 'xx_om_create_ir_iso');
    when fnd_api.g_exc_error then
      log_message('Error in xx_om_create_ir_iso ' || l_header_id);
      x_return_status := fnd_api.g_ret_sts_error;
      oe_debug_pub.add('auto_create_internal_req: In execution error', 2);
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
      oe_msg_pub.ADD;
      resultout := 'COMPLETE:N';
      OE_STANDARD_WF.Save_Messages;
    --OE_STANDARD_WF.Clear_Msg_Context;
    when others then
      log_message('WHEN OTHERS in xx_om_create_ir_iso ' || l_header_id || ' / ' || sqlerrm);
      oe_debug_pub.add('auto_create_internal_req: In Other error', 2);
      if oe_msg_pub.check_msg_level(oe_msg_pub.g_msg_lvl_unexp_error) then
        oe_msg_pub.add_exc_msg(g_pkg_name, 'auto_create_internal_req');
      end if;
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      wf_core.context('xx_om_consignment_order_pkg'
                    , 'xx_om_create_ir_iso'
                    , itemtype
                    , itemkey
                    , 'xx_om_create_ir_iso');
      fnd_message.set_name('XXINTG', 'INTG_ISO_CREATION_FAILED');
      oe_msg_pub.ADD;
      resultout := 'COMPLETE:N';
      raise;
  end xx_om_create_ous_ir_iso;
  procedure create_ous_so(p_header_Id in number, px_return_status out varchar2, x_new_order_number out number) is
    l_header_rec oe_order_pub.header_rec_type;
    l_line_tbl oe_order_pub.line_tbl_type;
    l_header_rec_out oe_order_pub.header_rec_type;
    l_header_val_rec_out oe_order_pub.header_val_rec_type;
    l_header_adj_tbl_out oe_order_pub.header_adj_tbl_type;
    l_header_adj_val_tbl_out oe_order_pub.header_adj_val_tbl_type;
    l_header_price_att_tbl_out oe_order_pub.header_price_att_tbl_type;
    l_header_adj_att_tbl_out oe_order_pub.header_adj_att_tbl_type;
    l_header_adj_assoc_tbl_out oe_order_pub.header_adj_assoc_tbl_type;
    l_header_scredit_tbl_out oe_order_pub.header_scredit_tbl_type;
    l_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
    l_line_tbl_out oe_order_pub.line_tbl_type;
    l_line_val_tbl_out oe_order_pub.line_val_tbl_type;
    l_line_adj_tbl_out oe_order_pub.line_adj_tbl_type;
    l_line_adj_tbl oe_order_pub.line_adj_tbl_type;
    l_line_adj_val_tbl_out oe_order_pub.line_adj_val_tbl_type;
    l_line_price_att_tbl_out oe_order_pub.line_price_att_tbl_type;
    l_line_adj_att_tbl_out oe_order_pub.line_adj_att_tbl_type;
    l_line_adj_assoc_tbl_out oe_order_pub.line_adj_assoc_tbl_type;
    l_line_scredit_tbl oe_order_pub.line_scredit_tbl_type;
    l_line_scredit_val_tbl oe_order_pub.line_scredit_val_tbl_type;
    l_line_scredit_tbl_out oe_order_pub.line_scredit_tbl_type;
    l_line_scredit_val_tbl_out oe_order_pub.line_scredit_val_tbl_type;
    l_lot_serial_tbl_out oe_order_pub.lot_serial_tbl_type;
    l_lot_serial_val_tbl_out oe_order_pub.lot_serial_val_tbl_type;
    l_request_tbl oe_order_pub.request_tbl_type;
    l_request_out_tbl oe_order_pub.request_tbl_type;
    x_return_status varchar2(1);
    x_msg_count number;
    x_msg_data varchar2(4000);
    l_api_version_number number := 1;
    l_order_number number;
    l_org_id number;
    l_ship_to number;
    l_site_use_id number;
    l_sold_to_org_id number;
    l_location_id number;
    l_ship_method_code varchar2(100);
    l_temp_employee_id number;
    l_user_id number;
    i integer;
    l_msg_index number;
    l_kit_number varchar2(100);
    l_ship_from_org_id number;
    l_salesrep_id number;
    l_subinventory varchar2(100);
    l_salesrep_number varchar2(50);
    l_deliver_to_org_id number;
    l_srep_dt_org_id number;
    l_pr_status varchar2(50);
    l_attribute1 varchar2(400);
    l_attribute2 varchar2(400);
    l_attribute3 varchar2(400);
    l_attribute4 varchar2(400);
    l_attribute9 varchar2(400);
    l_attribute20 varchar2(400);
    x_iso_deliver_to_org_id number;
    l_cs_sold_to number;
    l_curr_code varchar2(30);
    l_repln_count number;
    l_cs_order_type number;
    l_invoice_to number;
    l_po_number varchar2(400);
    cursor c1(c_header_id in number) is
      select line_id, inventory_item_id, ordered_quantity, line_number, subinventory
      from   oe_order_lines_all
      where      header_id = c_header_id
             and line_type_id = Oe_Sys_Parameters.value('INTG_REPLENISHMENT_LINE_TYPE', org_id)
             and nvl(cancelled_flag, 'N') = 'N';
  begin
    begin
      select order_number, org_id, ship_to_org_id, shipping_method_code, created_by, salesrep_id, deliver_to_org_id, attribute1, attribute2
           , attribute3, attribute4, attribute9, attribute20, sold_to_org_id, org_id, TRANSACTIONAL_CURR_CODE,order_type_id,invoice_to_org_id
           ,cust_po_number
      into   l_order_number, l_org_id, l_ship_to, l_ship_method_code, l_user_id, l_salesrep_id, l_deliver_to_org_id, l_attribute1
           , l_attribute2, l_attribute3, l_attribute4, l_attribute9, l_attribute20, l_cs_sold_to, l_org_id, l_curr_code,l_cs_order_type,l_invoice_to
           ,l_po_number
      from   oe_order_headers_all
      where  header_id = p_header_id;
    exception
      when others then
        log_message('Error in getting charge sheet order information for header_Id: ' || p_header_id);
    end;

    begin
    select count(*) into l_repln_count
    from   oe_order_lines_all
      where      header_id = p_header_id
             and line_type_id = Oe_Sys_Parameters.value('INTG_REPLENISHMENT_LINE_TYPE', org_id)
             and nvl(cancelled_flag, 'N') = 'N';
    exception when others then
    l_repln_count:=0;
    end;
    if l_repln_count>0 then
    begin
      select employee_id
      into   l_temp_employee_id
      from   fnd_user
      where  user_id = l_user_id;
    exception
      when others then
        select user_id
        into   l_user_id
        from   fnd_user
        where  user_name = 'EDI.WORKER';
    end;
    --fnd_global.apps_initialize(user_id => l_user_id, resp_id => 21623, resp_appl_id => 660);
    mo_global.set_policy_context('S', l_org_id);
    mo_global.init('ONT');
    l_ship_from_org_id := Oe_Sys_Parameters.value('MASTER_ORGANIZATION_ID', l_org_id);
    l_header_rec := oe_order_pub.g_miss_header_rec;
    l_header_rec.operation := oe_globals.g_opr_create;
    l_header_rec.order_type_id := Oe_Sys_Parameters.value('INTG_CONSIGN_PROD_REQ_ORDER_TYPE', l_org_id);
    l_header_rec.sold_to_org_id := l_cs_sold_to;
    l_header_rec.ship_to_org_id := l_ship_to;
    l_header_rec.invoice_to_org_id := l_invoice_to;
    l_header_rec.sales_channel_code := 'FIA';
    l_header_rec.shipping_method_code := l_ship_method_code;
    l_header_rec.org_id := l_org_id;
    l_header_rec.salesrep_id := -3;
    l_header_rec.transactional_curr_code := l_curr_code;
    l_header_rec.attribute14 := l_order_number;
    l_header_rec.context := 'Consignment';
    l_header_rec.ordered_date := sysdate;
    l_header_rec.ship_from_org_id := l_ship_from_org_id;
    l_header_rec.cust_po_number := l_po_number;
    l_line_tbl := oe_order_pub.g_miss_line_tbl;
    i := 1;
    for j in c1(p_header_id) loop
      l_line_tbl(i) := oe_order_pub.g_miss_line_rec;
      l_line_tbl(i).operation := oe_globals.g_opr_create;
      l_line_tbl(i).inventory_item_id := j.inventory_item_id;
      l_line_tbl(i).ordered_quantity := j.ordered_quantity;
      --l_line_tbl(i).cust_po_number := j.subinventory;
      l_line_tbl(i).context := 'Consignment';
      l_line_tbl(i).attribute1 := j.subinventory;
      l_line_tbl(i).ship_from_org_id := l_ship_from_org_id;
      --l_header_rec.cust_po_number := j.subinventory;
      l_header_rec.ATTRIBUTE9 := j.subinventory;
      i := i + 1;
    end loop;
    l_request_tbl(1).entity_code := OE_GLOBALS.G_ENTITY_HEADER;
    l_request_tbl(1).request_type := OE_GLOBALS.G_BOOK_ORDER;
    oe_order_pub.process_order(p_api_version_number => l_api_version_number
                             , p_header_rec => l_header_rec
                             , p_line_tbl => l_line_tbl
                             , p_line_adj_tbl => l_line_adj_tbl
                             , p_action_request_tbl => l_request_tbl
                             , p_line_scredit_tbl => l_line_scredit_tbl
                             , x_header_rec => l_header_rec_out
                             , x_header_val_rec => l_header_val_rec_out
                             , x_header_adj_tbl => l_header_adj_tbl_out
                             , x_header_adj_val_tbl => l_header_adj_val_tbl_out
                             , x_header_price_att_tbl => l_header_price_att_tbl_out
                             , x_header_adj_att_tbl => l_header_adj_att_tbl_out
                             , x_header_adj_assoc_tbl => l_header_adj_assoc_tbl_out
                             , x_header_scredit_tbl => l_header_scredit_tbl_out
                             , x_header_scredit_val_tbl => l_header_scredit_val_tbl_out
                             , x_line_tbl => l_line_tbl_out
                             , x_line_val_tbl => l_line_val_tbl_out
                             , x_line_adj_tbl => l_line_adj_tbl_out
                             , x_line_adj_val_tbl => l_line_adj_val_tbl_out
                             , x_line_price_att_tbl => l_line_price_att_tbl_out
                             , x_line_adj_att_tbl => l_line_adj_att_tbl_out
                             , x_line_adj_assoc_tbl => l_line_adj_assoc_tbl_out
                             , x_line_scredit_tbl => l_line_scredit_tbl_out
                             , x_line_scredit_val_tbl => l_line_scredit_val_tbl_out
                             , x_lot_serial_tbl => l_lot_serial_tbl_out
                             , x_lot_serial_val_tbl => l_lot_serial_val_tbl_out
                             , x_action_request_tbl => l_request_out_tbl
                             , x_return_status => x_return_status
                             , x_msg_count => x_msg_count
                             , x_msg_data => x_msg_data);
    log_message('x_return_status from create order = ' || substr(x_return_status, 1, 255));
    log_message('x_msg_count from create order = ' || to_char(x_msg_count));
    log_message('x_msg_data from create order= ' || substr(x_msg_data, 1, 255));
    log_message('New Order Number = ' || l_header_rec_out.order_number);
    px_return_status := x_return_status;
    x_new_order_number := l_header_rec_out.order_number;
    if x_new_order_number is not null then
      select b.meaning
      into   l_pr_status
      from   oe_order_headers_all a, oe_lookups b
      where  header_Id = l_header_rec_out.header_id and b.lookup_type = 'FLOW_STATUS' and a.flow_status_code = b.lookup_code;
      update oe_order_headers_all
      set    context = 'Consignment', attribute14 = x_new_order_number || ' - ' || l_pr_status
      where  header_id = p_header_id;
    --copy_attachments(p_header_id,l_header_rec_out.header_id);
    end if;
    for k in 1 .. x_msg_count loop
      oe_msg_pub.get(p_msg_index => k, p_encoded => FND_API.G_FALSE, p_data => x_msg_data, p_msg_index_out => l_msg_index);
      log_message('- - x_msg_data from create order loop = ' || substr(x_msg_data, 1, 255));
      if x_new_order_number is null then
        update oe_order_headers_all
        set    context = 'Consignment', attribute14 = substr(x_msg_data, 1, 240)
        where  header_id = p_header_id;
      end if;
    end loop;
    end if;
  end create_ous_so;
end xx_om_cnsgn_wf_pkg;
/
