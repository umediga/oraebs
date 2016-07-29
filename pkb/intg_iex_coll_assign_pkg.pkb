DROP PACKAGE BODY APPS.INTG_IEX_COLL_ASSIGN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.INTG_IEX_COLL_ASSIGN_PKG as
  procedure debug_print(p_debug_mesg in varchar2) is
  begin
    fnd_file.put_line(fnd_file.log, p_debug_mesg);
    dbms_output.put_line(p_debug_mesg);
  end debug_print;
  procedure generate_report is
    cursor processed is
      select party_name,
             a.account_number,
             c.meaning customer_class,
             a.cust_account_id,
             ac.name old_collector,
             a.collector_name new_collector,
             (select max(nvl(state, province))
                from hz_locations hl,
                     hz_party_sites hps,
                     hz_cust_acct_sites_all hcas,
                     hz_cust_site_uses_all hcsu
               where     b.cust_account_id = hcas.cust_account_id
                     and hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                     and hcas.status = 'A'
                     and hcsu.status = 'A'
                     and hcsu.primary_flag = 'Y'
                     and hcsu.site_use_code = 'BILL_TO'
                     and hcas.org_id=g_org_id
                     and hcas.party_site_id = hps.party_site_id
                     and hps.location_id = hl.location_id)
               state,
             (select max(country)
                from hz_locations hl,
                     hz_party_sites hps,
                     hz_cust_acct_sites_all hcas,
                     hz_cust_site_uses_all hcsu
               where     b.cust_account_id = hcas.cust_account_id
                     and hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                     and hcas.status = 'A'
                     and hcsu.status = 'A'
                     and hcsu.primary_flag = 'Y'
                     and hcsu.site_use_code = 'BILL_TO'
                     and hcas.org_id=g_org_id
                     and hcas.party_site_id = hps.party_site_id
                     and hps.location_id = hl.location_id)
               country,
             a.status,
             a.err_msg
        from intg_iex_coll_assignment_gt a,
             hz_cust_accounts b,
             ar_lookups c,
             ar_collectors ac
       where     b.customer_class_code = c.lookup_code(+)
             and c.lookup_type(+) = 'CUSTOMER CLASS'
             and a.cust_account_id = b.cust_account_id
             and a.old_collector_id = ac.collector_id(+)
       order by party_name;
    cursor unprocessed is
      select party_name,
             b.account_number,
             c.meaning customer_class,
             b.cust_account_id,
             ac.name old_collector,
             null new_collector,
             (select max(nvl(state, province))
                from hz_locations hl,
                     hz_party_sites hps,
                     hz_cust_acct_sites_all hcas,
                     hz_cust_site_uses_all hcsu
               where     b.cust_account_id = hcas.cust_account_id
                     and hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                    -- and hcas.status = 'A'
                     --and hcsu.status = 'A'
                     and hcsu.primary_flag = 'Y'
                     and hcsu.site_use_code = 'BILL_TO'
                     and hcas.org_id=g_org_id
                     and hcas.party_site_id = hps.party_site_id
                     and hps.location_id = hl.location_id)
               state,
             (select max(country)
                from hz_locations hl,
                     hz_party_sites hps,
                     hz_cust_acct_sites_all hcas,
                     hz_cust_site_uses_all hcsu
               where     b.cust_account_id = hcas.cust_account_id
                     and hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                     --and hcas.status = 'A'
                     --and hcsu.status = 'A'
                     and hcsu.primary_flag = 'Y'
                     and hcsu.site_use_code = 'BILL_TO'
                     and hcas.org_id=g_org_id
                     and hcas.party_site_id = hps.party_site_id
                     and hps.location_id = hl.location_id)
               country,
             null status,
             null err_msg
        from hz_cust_accounts b,
             ar_lookups c,
             ar_collectors ac,
             hz_customer_profiles hcp,
             hz_parties hp
       where     b.customer_class_code = c.lookup_code(+)
             and c.lookup_type(+) = 'CUSTOMER CLASS'
             and hcp.collector_id = ac.collector_id(+)
             and b.cust_account_id = hcp.cust_account_id(+)
             and hcp.site_use_id is null
             and b.party_id = hp.party_id
             --and b.status = 'A'
             and exists (select 1 from hz_cust_acct_sites_all hcas,hz_cust_site_uses_all hcsu
             where b.cust_account_id=hcas.cust_account_id
             and hcas.cust_acct_site_id=hcsu.cust_acct_site_id
             --and hcas.status='A'
             --and hcsu.status='A'
             and hcsu.site_use_code='BILL_TO'
             and hcas.org_id=g_org_id)
             and not exists
                   (select 1
                      from intg_iex_coll_assignment_gt a
                     where a.cust_account_id = b.cust_account_id)
       order by party_name;
  begin
    fnd_file.put_line(fnd_file.output, '<?xml version="1.0" encoding="UTF-8"?>');
    fnd_file.put_line(fnd_file.output, '<LIST_G_RECORDS>');
    for i in processed loop
      fnd_file.put_line(fnd_file.output, '<G_RECORDS>');
      fnd_file.put_line(fnd_file.output, '<PARTY_NAME><![CDATA[' || i.party_name || ']]></PARTY_NAME>');
      fnd_file.put_line(fnd_file.output, '<ACCOUNT_NUMBER><![CDATA[' || i.account_number || ']]></ACCOUNT_NUMBER>');
      fnd_file.put_line(fnd_file.output, '<CUSTOMER_CLASS><![CDATA[' || i.customer_class || ']]></CUSTOMER_CLASS>');
      fnd_file.put_line(fnd_file.output, '<COUNTRY><![CDATA[' || i.country || ']]></COUNTRY>');
      fnd_file.put_line(fnd_file.output, '<STATE><![CDATA[' || i.state || ']]></STATE>');
      fnd_file.put_line(fnd_file.output, '<OLD_COLLECTOR><![CDATA[' || i.old_collector || ']]></OLD_COLLECTOR>');
      fnd_file.put_line(fnd_file.output, '<NEW_COLLECTOR><![CDATA[' || i.new_collector || ']]></NEW_COLLECTOR>');
      fnd_file.put_line(fnd_file.output, '<STATUS><![CDATA[' || i.status || ']]></STATUS>');
      fnd_file.put_line(fnd_file.output, '<ERR_MSG>' || i.err_msg || '</ERR_MSG>');
      fnd_file.put_line(fnd_file.output, '</G_RECORDS>');
    end loop;
    for i in unprocessed loop
      fnd_file.put_line(fnd_file.output, '<G_RECORDS1>');
      fnd_file.put_line(fnd_file.output, '<PARTY_NAME><![CDATA[' || i.party_name || ']]></PARTY_NAME>');
      fnd_file.put_line(fnd_file.output, '<ACCOUNT_NUMBER><![CDATA[' || i.account_number || ']]></ACCOUNT_NUMBER>');
      fnd_file.put_line(fnd_file.output, '<CUSTOMER_CLASS><![CDATA[' || i.customer_class || ']]></CUSTOMER_CLASS>');
      fnd_file.put_line(fnd_file.output, '<COUNTRY><![CDATA[' || i.country || ']]></COUNTRY>');
      fnd_file.put_line(fnd_file.output, '<STATE><![CDATA[' || i.state || ']]></STATE>');
      fnd_file.put_line(fnd_file.output, '<OLD_COLLECTOR><![CDATA[' || i.old_collector || ']]></OLD_COLLECTOR>');
      fnd_file.put_line(fnd_file.output, '<NEW_COLLECTOR><![CDATA[' || i.new_collector || ']]></NEW_COLLECTOR>');
      fnd_file.put_line(fnd_file.output, '<STATUS><![CDATA[' || i.status || ']]></STATUS>');
      fnd_file.put_line(fnd_file.output, '<ERR_MSG>' || i.err_msg || '</ERR_MSG>');
      fnd_file.put_line(fnd_file.output, '</G_RECORDS1>');
    end loop;
    fnd_file.put_line(fnd_file.output, '</LIST_G_RECORDS>');
  exception
    when others then
      debug_print('Error in Printing Report');
      debug_print(sqlerrm);
  end generate_report;
  procedure update_collectors is
    cursor c is
      select * from intg_iex_coll_assignment_gt;
    l_cust_profile_rec   hz_customer_profile_v2pub.customer_profile_rec_type;
    x_return_status      varchar2(10);
    l_obj_ver_number     number;
    x_msg_data           varchar2(4000);
    x_msg_count          number;
    v_msg_index_out      number;
  begin
    for i in c loop
      l_cust_profile_rec.cust_account_profile_id := i.cust_account_profile_id;
      if i.object_version_number is null then
        l_obj_ver_number := null;
      else
        l_obj_ver_number := i.object_version_number;
      end if;
      l_cust_profile_rec.collector_id := i.collector_id;
      --dbms_output.put_line(i.collector_id);
      x_return_status := null;
      x_msg_count := null;
      x_msg_data := null;
      hz_customer_profile_v2pub.update_customer_profile(p_init_msg_list           => fnd_api.g_false,
                                                        p_customer_profile_rec    => l_cust_profile_rec,
                                                        p_object_version_number   => l_obj_ver_number,
                                                        x_return_status           => x_return_status,
                                                        x_msg_count               => x_msg_count,
                                                        x_msg_data                => x_msg_data);
      --dbms_output.put_line(x_return_status);
      update intg_iex_coll_assignment_gt
         set status = x_return_status
       where cust_account_profile_id = i.cust_account_profile_id;
      if x_msg_count > 0 then
        for v_index in 1 .. x_msg_count loop
          fnd_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => x_msg_data, p_msg_index_out => v_msg_index_out);
          x_msg_data := substr(x_msg_data, 1, 200);
          --dbms_output.put_line('And the error is :' || x_msg_data);
          -- dbms_output.put_line('============================================================');
          update intg_iex_coll_assignment_gt
             set err_msg = x_msg_data
           where cust_account_profile_id = i.cust_account_profile_id;
        end loop;
      end if;
    end loop;
  exception
    when others then
      debug_print('Error in updating Collectors');
      debug_print(sqlerrm);
  end;
  procedure collect_remaining is
    l_grp_qualifier    varchar2(30);
    l_level            varchar2(10);
    l_qualifier        varchar2(30);
    px_sql             varchar2(32767);
    l_qual_count       number;
    l_main_sql         varchar2(32767);
    l_insert_sql       varchar2(32767);
    l_cursor           integer;
    l_rows_processed   integer;
    crlf      constant varchar2(1) := '
';
    cursor c is
      select collector_id, attribute1
        from ar_collectors
       where attribute1 is not null
       and attribute2=g_org_id;
    cursor c1(p_qual_group in varchar2) is
      select lookup_code l_grp_qualifier, attribute13 l_qualifier, attribute15 l_level
        from fnd_lookup_values_vl
       where lookup_type = p_qual_group and attribute13 <> 'ACCOUNT_NUMBER';
  begin
    for i in c loop
      select count(*)
        into l_qual_count
        from fnd_lookup_values_vl
       where lookup_type = i.attribute1 and nvl(attribute13,'N') <> 'ACCOUNT_NUMBER';
       l_main_sql := null;
      if l_qual_count > 0 then
        l_main_sql :=
                      'select a.cust_account_id,
                           a.account_number,
                           hcp.cust_account_profile_id,
                           party_name,
                           ac.collector_id new_collector_id,
                           ac.name collector_name,
                           hcp.object_version_number
                    from hz_cust_accounts a, hz_customer_profiles hcp, ar_collectors ac,hz_parties hp
                    where a.status = ''A'' and a.cust_account_id = hcp.cust_account_id and hcp.site_use_id is null and ac.attribute1 = :qual_group
                    and nvl(hcp.collector_id,-1)<>ac.collector_id
                    and a.party_id=hp.party_id
                    and exists (select 1 from hz_cust_acct_sites_all hcas1,hz_cust_site_uses_all hcsu1
                    where hcas1.cust_acct_site_id=hcsu1.cust_acct_site_id
                    and a.cust_account_id=hcas1.cust_account_id
                    and hcsu1.site_use_code=''BILL_TO''
                    and hcas1.org_id=:g_org_id)
                    and account_number not in
                        (select lookup_code from fnd_lookup_values_vl
                         where lookup_type in (select lookup_code from fnd_lookup_values_vl
                         where attribute13=''ACCOUNT_NUMBER''
                         and lookup_type in (select attribute1 from ar_collectors)))'
                      || crlf;
        for j in c1(i.attribute1) loop
          select long_text
            into px_sql
            from fnd_attached_documents a, fnd_documents b, fnd_documents_long_text c
           where     entity_name = 'FND_LOOKUP_VALUES'
                 and pk1_value = 'INTG_IEX_QUALIFIERS'
                 and pk2_value = j.l_qualifier
                 and a.document_id = b.document_id
                 and b.media_id = c.media_id;
          l_main_sql := l_main_sql || px_sql || crlf;
        end loop;
      end if;
      l_insert_sql := 'insert into intg_iex_coll_assignment_gt (cust_account_id,account_number,cust_account_profile_id,party_name,
       collector_id,collector_name,object_version_number)' || crlf;
      if length(l_main_sql) > 0 then
        l_main_sql := l_insert_sql || l_main_sql;
        debug_print('Processed for Collector Qualifier Group: ' || i.attribute1);
        debug_print('SQL For the Same: ' || l_main_sql);
        debug_print('------------------------------------------');
        l_cursor := dbms_sql.open_cursor;
        dbms_sql.parse(l_cursor, l_main_sql, dbms_sql.native);
        dbms_sql.bind_variable(l_cursor, 'qual_group', i.attribute1);
        dbms_sql.bind_variable(l_cursor, 'g_org_id', g_org_id);
        l_rows_processed := dbms_sql.execute(l_cursor);
        dbms_sql.close_cursor(l_cursor);
      end if;
    end loop;
  exception
    when others then
      if dbms_sql.is_open(l_cursor) then
        dbms_sql.close_cursor(l_cursor);
      end if;
      debug_print('Error in collecting remaining accounts');
      debug_print(sqlerrm);
  end;
  procedure collect_named_accounts is
    l_grp_qualifier    varchar2(30);
    l_level            varchar2(10);
    l_qualifier        varchar2(30);
    px_sql             varchar2(32767);
    l_qual_count       number;
    l_main_sql         varchar2(32767);
    l_insert_sql       varchar2(32767);
    l_cursor           integer;
    l_rows_processed   integer;
    crlf      constant varchar2(1) := '
';
    cursor c is
      select collector_id, attribute1
        from ar_collectors
       where attribute1 is not null
       and attribute2=g_org_id;
    cursor c1(p_qual_group in varchar2) is
      select lookup_code l_grp_qualifier, attribute13 l_qualifier
        from fnd_lookup_values_vl
       where lookup_type = p_qual_group and attribute13 = 'ACCOUNT_NUMBER';
  begin
    for i in c loop
      select count(*)
        into l_qual_count
        from fnd_lookup_values_vl
       where lookup_type = i.attribute1 and attribute13 = 'ACCOUNT_NUMBER';
      l_main_sql := null;
      if l_qual_count > 0 then
        l_main_sql :=
                      'select a.cust_account_id,
                           a.account_number,
                           hcp.cust_account_profile_id,
                           party_name,
                           ac.collector_id new_collector_id,
                           ac.name collector_name,
                           hcp.object_version_number,
                           hcp.collector_id old_collector_id
                    from hz_cust_accounts a, hz_customer_profiles hcp, ar_collectors ac,hz_parties hp
                    where a.status = ''A'' and a.cust_account_id = hcp.cust_account_id and hcp.site_use_id is null and ac.attribute1 = :qual_group
                    and exists (select 1 from hz_cust_acct_sites_all hcas1,hz_cust_site_uses_all hcsu1
                    where hcas1.cust_acct_site_id=hcsu1.cust_acct_site_id
                    and a.cust_account_id=hcas1.cust_account_id
                    and hcsu1.site_use_code=''BILL_TO''
                    and hcas1.org_id=:g_org_id)
                    and nvl(hcp.collector_id,1)<>ac.collector_id
                    and a.party_id=hp.party_id'
                      || crlf;
        for j in c1(i.attribute1) loop
          select long_text
            into px_sql
            from fnd_attached_documents a, fnd_documents b, fnd_documents_long_text c
           where     entity_name = 'FND_LOOKUP_VALUES'
                 and pk1_value = 'INTG_IEX_QUALIFIERS'
                 and pk2_value = j.l_qualifier
                 and a.document_id = b.document_id
                 and b.media_id = c.media_id;
          l_main_sql := l_main_sql || px_sql || crlf;
        end loop;
      end if;
      l_insert_sql := 'insert into intg_iex_coll_assignment_gt (cust_account_id,account_number,cust_account_profile_id,party_name,
       collector_id,collector_name,object_version_number,old_collector_id)' || crlf;
      if length(l_main_sql) > 0 then
        l_main_sql := l_insert_sql || l_main_sql;
        debug_print('Processed for Collector Qualifier Group (Named accounts): ' || i.attribute1);
        debug_print('SQL For the Same: ' || l_main_sql);
        debug_print('------------------------------------------');
        l_cursor := dbms_sql.open_cursor;
        dbms_sql.parse(l_cursor, l_main_sql, dbms_sql.native);
        dbms_sql.bind_variable(l_cursor, 'qual_group', i.attribute1);
        dbms_sql.bind_variable(l_cursor, 'g_org_id', g_org_id);
        l_rows_processed := dbms_sql.execute(l_cursor);
        dbms_sql.close_cursor(l_cursor);
      end if;
    end loop;
  exception
    when others then
      if dbms_sql.is_open(l_cursor) then
        dbms_sql.close_cursor(l_cursor);
      end if;
      debug_print('Error in collecting named accounts');
      debug_print(sqlerrm);
  end;
  procedure assign_collectors(x_errbuf out varchar2, retcode out number,p_org_id in number, p_mode in varchar2 default 'VALIDATE') is
  begin
  g_org_id:=p_org_id;
    collect_named_accounts;
    collect_remaining;
    if p_mode='UPDATE' then
    update_collectors;
    end if;
    generate_report;
  exception
    when others then
      debug_print('Error in main procedure');
      debug_print(sqlerrm);
  end;
  procedure debug_log(p_msg in varchar2) is
  begin
    dbms_output.put_line(p_msg);
    fnd_file.put_line(fnd_file.log, p_msg);
  end;
  procedure exec_invoice_print_pr(p_cust_trx_id in number, x_req_id out number) is
    l_conc_request_id    number;
    l_phase              varchar2(100);
    l_status             varchar2(100);
    l_dev_phase          varchar2(100);
    l_dex_status         varchar2(100);
    l_message            varchar2(240);
    l_check              boolean;
    x_boolean            boolean;
    l_company_code       varchar2(240);
    l_class_code         varchar2(20);
    l_invoice_number     varchar2(50);
    l_customer_id        number;
    l_cust_trx_type_id   number;
    l_org_id             number;
    l_ou_name            varchar2(400);
    l_template_name      varchar2(4000);
  begin
    l_class_code := null;
    l_invoice_number := null;
    l_customer_id := null;
    l_org_Id :=NULL;
    begin
      select d.type, trx_number, d.cust_trx_type_id, b.bill_to_customer_id,b.org_id,ou.name
        into l_class_code, l_invoice_number, l_cust_trx_type_id, l_customer_id,l_org_Id,l_ou_name
        from ra_customer_trx b, ra_cust_trx_types d,hr_operating_units ou
       where b.customer_trx_id = p_cust_trx_id and b.cust_trx_type_id = d.cust_trx_type_id
       and   b.org_id=ou.organization_id;
    exception
      when too_many_rows then
        null;
      when no_data_found then
        null;
      when others then
        null;
    end;

    debug_log('Calling the INTG Print Selected Invoices for invoice number :' || l_invoice_number);
    l_template_name:='XXR2RPRINTSELINV_SS';
    if l_ou_name in ('OU United States','ILS Corporation','ILS Manufacturing') then
    l_template_name:='XXR2RPRINTSELINV_SS';
    elsif l_ou_name in ('OU Australia','OU New Zealand') then
    l_template_name:='XXR2RPRINTSELINV_NZ';
    elsif l_ou_name in ('OU Canada') then
    l_template_name:='XXR2RPRINTSELINV_CA';
     elsif l_ou_name in ('OU Switzerland') then
    l_template_name:='XXR2RPRINTSELINV_CH';
    end if;
    x_boolean := fnd_request.add_layout('XXINTG', l_template_name, 'en', 'US', 'PDF');
    fnd_request.set_org_id (l_org_id);
    l_conc_request_id := fnd_request.submit_request(application   => 'XXINTG',
                                                    program       => 'XXR2RPRINTSELINV_SS',
                                                    description   => 'Printing ' || l_invoice_number ||
                                                                    ' Using INTG Print Selected Invoices',
                                                    sub_request   => false,
                                                    argument1     => 'TRX_NUMBER',
                                                    argument2     => l_class_code,
                                                    argument3     => l_cust_trx_type_id,
                                                    argument4     => l_invoice_number,
                                                    argument5     => l_invoice_number,
                                                    argument6     => '',
                                                    argument7     => '',
                                                    argument8     => '',
                                                    argument9     => l_customer_id,
                                                    argument10    => '',
                                                    argument11    => 'N',
                                                    argument12    => 'N',
                                                    argument13    => '',
                                                    argument14    => 'SEL',
                                                    argument15    => 1,
                                                    argument16    => 'N',
                                                    argument17    => 10,
                                                    argument18    => '',
                                                    argument19    => '',
                                                    argument20    => '',
                                                    argument21    => '',
                                                    argument22    => 'N',
                                                    argument23    => 'Trade Compliance',
                                                    argument24    => 'MSD_MASTER_ORG',
                                                    argument25    => '');
    x_req_id := l_conc_request_id;
    g_req_mesg := 'INTG Print Selected Invoices Program Submitted with Request Id = ' || l_conc_request_id;
    debug_log(g_req_mesg);
    commit;
  exception
    when others then
      debug_log('<exec_submit_print_pr>' || sqlcode || sqlerrm);
  end exec_invoice_print_pr;
   function get_request_mesg
      return varchar2
   is
   begin
      return (g_req_mesg);
   exception
      when others
      then
         debug_log ('<get_request_mesg>' || sqlcode || sqlerrm);
   end get_request_mesg;
end;
/
