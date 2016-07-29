DROP PACKAGE BODY APPS.XXAR_REV_COGS_REPORT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXAR_REV_COGS_REPORT_PKG" as
  c_level_statement constant number := fnd_log.level_statement;
  c_level_procedure constant number := fnd_log.level_procedure;
  c_level_event constant number := fnd_log.level_event;
  c_level_exception constant number := fnd_log.level_exception;
  c_level_error constant number := fnd_log.level_error;
  c_level_unexpected constant number := fnd_log.level_unexpected;
  c_level_log_disabled constant number := 99;
  c_default_module constant varchar2(240) := 'XXAR_REV_COGS_REPORT_PKG';
  g_log_level number;
  g_log_enabled boolean;
  c_insert_gt_statement constant varchar2(32000) := null;
  c_insert_gt_select constant varchar2(32000) := null;
  c_new_insert_gt_stmt constant varchar2(32000) := 'insert into XXar_rev_cogs_details_gt
               (cust_trx_line_gl_dist_id,
                customer_trx_line_id,
                revenue,
                entered_revenue,
                customer_trx_id,
                order_type,
                order_number,
                line_id,
                return_order_number
               ) ';
  c_new_insert_gt_select constant varchar2(32000)
    := '   select   max(rcgl.cust_trx_line_gl_dist_id),
               rctl.customer_trx_line_id,
               sum (rcgl.acctd_amount) revenue,
               sum (rcgl.amount) entered_revenue,
               rctl.customer_trx_id customer_trx_id,
               rctl.interface_line_attribute2 order_type,
               interface_line_attribute1 order_number,
               interface_line_attribute6 order_line_id,
               case
                  when rctl.previous_customer_trx_line_id is not null
                     then (select interface_line_attribute1
                             from ra_customer_trx_lines_all rctl1
                            where rctl.previous_customer_trx_line_id = rctl1.customer_trx_line_id)
                  else null
               end return_order_number
          from ra_customer_trx_lines_all rctl,
               ra_cust_trx_line_gl_dist_all rcgl
         where rctl.interface_line_context = ''ORDER ENTRY''
           and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
           and rcgl.account_class = ''REV''
           and rcgl.account_set_flag = ''N''
           and rctl.line_type = ''LINE''
           and rcgl.org_id in (select organization_id from hr_operating_units where set_of_books_id=:1)
           and rcgl.set_of_books_id = :1
           $AR_CUSTOMER_WHERE$
           $AR_PERIOD_WHERE$
      group by rctl.customer_trx_id,
               rctl.interface_line_attribute2,
               interface_line_attribute1,
               interface_line_attribute6,
               rctl.previous_customer_trx_line_id,
               rctl.customer_trx_line_id
      order by interface_line_attribute6 ' ;
  c_cogs_upd_stmt varchar2(32676)
    := ' merge into XXar_rev_cogs_details_gt a
      using (select   trx_source_line_id trx_source_line_id,
                      max(mmt.transaction_id) transaction_id,
                      max(inv_sub_ledger_id) inv_sub_ledger_id,
                      mso.segment1 order_number,
                      mso.segment2 order_type,
                      sum (base_transaction_value) cogs_amount
                 from mtl_material_transactions mmt,
                      mtl_transaction_accounts mta,
                      mtl_sales_orders mso,
                      gl_code_combinations_kfv glcc
                where transaction_type_id in (10008,15,16)
                  and exists (select 1
                                from cst_organization_definitions cod
                               where mmt.organization_id = cod.organization_id and cod.set_of_books_id = :1)
                  and mmt.transaction_date $L_DATES$
                  and mmt.transaction_id = mta.transaction_id
                  and mta.accounting_line_type = 35
                  and mta.reference_account = glcc.code_combination_id
                  and mmt.transaction_source_id = mso.sales_order_id
                  and mta.transaction_date $L_DATES$
                  $COGS_CUSTOMER_WHERE$
             group by trx_source_line_id,
                      --mmt.transaction_id,
                      mso.segment1,
                      mso.segment2) b
      on (a.line_id = b.trx_source_line_id and a.order_number = b.order_number and a.order_type = b.order_type)
      when matched then
         update
            set a.mmt_transaction_id = b.transaction_id, a.cogs_amount = b.cogs_amount,a.inv_sub_ledger_id=b.inv_sub_ledger_id
      when not matched then
         insert (order_number, order_type, line_id, mmt_transaction_id, cogs_amount,inv_sub_ledger_id)
         values (b.order_number, b.order_type, b.trx_source_line_id, b.transaction_id, b.cogs_amount,b.inv_sub_ledger_id) ';

  procedure trace(p_msg in varchar2, p_level in number, p_module in varchar2 default c_default_module) is
  begin
    if (p_msg is null and p_level >= g_log_level) then
      fnd_log.message(p_level, p_module);
    elsif p_level >= g_log_level then
      fnd_log.string(p_level, p_module, p_msg);
    end if;
  exception
    when xla_exceptions_pkg.application_exception then
      raise;
    when others then
      xla_exceptions_pkg.raise_message(p_location => 'XXAR_REV_COGS_REPORT_PKG.trace');
  end trace;

  /*======================================================================+
  |                                                                       |
  | Private Procedure                                                     |
  |                                                                       |
  |    Print_Logfile                                                      |
  |                                                                       |
  |    Print concurrent request logs.                                     |
  |                                                                       |
  +======================================================================*/
  procedure print_logfile(p_msg in varchar2) is
  begin
    fnd_file.put_line(fnd_file.log, p_msg);
  exception
    when xla_exceptions_pkg.application_exception then
      raise;
    when others then
      xla_exceptions_pkg.raise_message(p_location => 'XXAR_REV_COGS_REPORT_PKG.print_logfile');
  end print_logfile;

  function ar_period_where
    return varchar2 is
    l_period_where varchar(32000);
    l_year varchar2(100);
    x_1st_period varchar2(100);
    l_from_date date;
    l_to_date date;
    l_from_date_char varchar2(20);
    l_to_date_char varchar2(20);
  begin
    if p_balance_type = 'PTD' then
      if p_period_name is null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        l_period_where := ' and trunc(rcgl.gl_date) between ''' || l_from_date || ''' and '' ' || l_to_date || ''' ';
        print_logfile('AR Period Where is: ' || l_period_where);
      elsif p_period_name is not null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = p_period_name;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = p_period_name;
        l_period_where := ' and trunc(rcgl.gl_date) between ''' || l_from_date || ''' and '' ' || l_to_date || ''' ';
        print_logfile('AR Period Where is: ' || l_period_where);
      end if;
    elsif p_balance_type = 'YTD' then
      begin
        select to_char(sysdate, 'YYYY')
        into   l_year
        from   dual;
        gl_period_statuses_pkg.
        select_year_1st_period(x_application_id => 401, x_ledger_id => p_ledger_id, x_period_year => l_year, x_period_name => x_1st_period);
      end;

      if p_period_name is not null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = p_period_name;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = x_1st_period;
        l_period_where := ' and trunc(rcgl.gl_date) between ''' || l_from_date || ''' and '' ' || l_to_date || ''' ';
        print_logfile('AR Period Where is: ' || l_period_where);
      elsif p_period_name is null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = x_1st_period;
        l_period_where := ' and trunc(rcgl.gl_date) between ''' || l_from_date || ''' and '' ' || l_to_date || ''' ';
        print_logfile('AR Period Where is: ' || l_period_where);
      end if;
    end if;

    return l_period_where;
  exception
    when others then
      xla_exceptions_pkg.raise_message(p_location => 'XXAR_REV_COGS_REPORT_PKG.replace_period_where');
  end ar_period_where;

  function cogs_period_where
    return varchar2 is
    l_period_where varchar(32000);
    l_year varchar2(100);
    x_1st_period varchar2(100);
    l_from_date date;
    l_to_date date;
    l_from_date_char varchar2(200);
    l_to_date_char varchar2(200);
  begin
    if p_balance_type = 'PTD' then
      if p_period_name is null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        l_from_date := to_date(to_char(l_from_date, 'DDMMYYYY'), 'DDMMYYYY');
        l_to_date := to_date(to_char(l_to_date, 'DDMMYYYY'), 'DDMMYYYY') + .99999;
        l_from_date_char := to_char(l_from_date, 'DD-MON-YYYY HH24:MI:SS');
        l_to_date_char := to_char(l_to_date, 'DD-MON-YYYY HH24:MI:SS');
        l_from_date_char := '''' || l_from_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_to_date_char := '''' || l_to_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_period_where := ' between to_date (' || l_from_date_char || ' and to_date (' || l_to_date_char || ' ';
        print_logfile('COGS Period Where is: ' || l_period_where);
      elsif p_period_name is not null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and period_name = p_period_name;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and period_name = p_period_name;
        l_from_date := to_date(to_char(l_from_date, 'DDMMYYYY'), 'DDMMYYYY');
        l_to_date := to_date(to_char(l_to_date, 'DDMMYYYY'), 'DDMMYYYY') + .99999;
        l_from_date_char := to_char(l_from_date, 'DD-MON-YYYY HH24:MI:SS');
        l_to_date_char := to_char(l_to_date, 'DD-MON-YYYY HH24:MI:SS');
        l_from_date_char := '''' || l_from_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_to_date_char := '''' || l_to_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_period_where := ' between to_date (' || l_from_date_char || ' and to_date (' || l_to_date_char || ' ';
        print_logfile('COGS Period Where is: ' || l_period_where);
      end if;
    elsif p_balance_type = 'YTD' then
      begin
        select to_char(sysdate, 'YYYY')
        into   l_year
        from   dual;
        gl_period_statuses_pkg.
        select_year_1st_period(x_application_id => 401, x_ledger_id => p_ledger_id, x_period_year => l_year, x_period_name => x_1st_period);
      end;

      if p_period_name is not null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and period_name = p_period_name;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and period_name = x_1st_period;
        l_from_date := to_date(to_char(l_from_date, 'DDMMYYYY'), 'DDMMYYYY');
        l_to_date := to_date(to_char(l_to_date, 'DDMMYYYY'), 'DDMMYYYY') + .99999;
        l_from_date_char := to_char(l_from_date, 'DD-MON-YYYY HH24:MI:SS');
        l_to_date_char := to_char(l_to_date, 'DD-MON-YYYY HH24:MI:SS');
        l_from_date_char := '''' || l_from_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_to_date_char := '''' || l_to_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_period_where := ' between to_date (' || l_from_date_char || ' and to_date (' || l_to_date_char || ' ';
        print_logfile('COGS Period Where is: ' || l_period_where);
      elsif p_period_name is null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 401 and ledger_id = p_ledger_id and period_name = x_1st_period;
        l_from_date := to_date(to_char(l_from_date, 'DDMMYYYY'), 'DDMMYYYY');
        l_to_date := to_date(to_char(l_to_date, 'DDMMYYYY'), 'DDMMYYYY') + .99999;
        l_from_date_char := to_char(l_from_date, 'DD-MON-YYYY HH24:MI:SS');
        l_to_date_char := to_char(l_to_date, 'DD-MON-YYYY HH24:MI:SS');
        l_from_date_char := '''' || l_from_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_to_date_char := '''' || l_to_date_char || '''' || ',' || '''DD-MON-YYYY HH24:MI:SS''' || ')';
        l_period_where := ' between to_date (' || l_from_date_char || ' and to_date (' || l_to_date_char || ' ';
        print_logfile('COGS Period Where is: ' || l_period_where);
      end if;
    end if;

    return l_period_where;
  exception
    when others then
      xla_exceptions_pkg.raise_message(p_location => 'XXAR_REV_COGS_REPORT_PKG.replace_period_where');
  end cogs_period_where;

  function xla_period_where
    return varchar2 is
    l_period_where varchar(32000);
    l_year varchar2(100);
    x_1st_period varchar2(100);
    l_from_date date;
    l_to_date date;
    l_from_date_char varchar2(20);
    l_to_date_char varchar2(20);
  begin
    if p_balance_type = 'PTD' then
      if p_period_name is null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        l_period_where :=    ' and trunc(xlah.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and trunc(xlal.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and glcc.segment1 = '''
                          || p_bal_segment
                          || '''  ';
        print_logfile('XLA Period Where is: ' || l_period_where);
      elsif p_period_name is not null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = p_period_name;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = p_period_name;
        l_period_where :=    ' and trunc(xlah.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and trunc(xlal.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and glcc.segment1 = '''
                          || p_bal_segment
                          || ''' ';
        print_logfile('XLA Period Where is: ' || l_period_where);
      end if;
    elsif p_balance_type = 'YTD' then
      begin
        select to_char(sysdate, 'YYYY')
        into   l_year
        from   dual;
        gl_period_statuses_pkg.
        select_year_1st_period(x_application_id => 401, x_ledger_id => p_ledger_id, x_period_year => l_year, x_period_name => x_1st_period);
      end;

      if p_period_name is not null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = p_period_name;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = x_1st_period;
        l_period_where :=    ' and trunc(xlah.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and trunc(xlal.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and glcc.segment1 = '''
                          || p_bal_segment
                          || ''' ';
        print_logfile('XLA Period Where is: ' || l_period_where);
      elsif p_period_name is null then
        select trunc(end_date)
        into   l_to_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and trunc(sysdate) between start_date and end_date;
        select trunc(start_date)
        into   l_from_date
        from   gl_period_statuses
        where  application_id = 222 and ledger_id = p_ledger_id and period_name = x_1st_period;
        l_period_where :=    ' and trunc(xlah.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and trunc(xlal.accounting_date) between '''
                          || l_from_date
                          || ''' and '''
                          || l_to_date
                          || '''
                                 and glcc.segment1 = '''
                          || p_bal_segment
                          || ''' ';
        print_logfile('XLA Period Where is: ' || l_period_where);
      end if;
    end if;

    return l_period_where;
  exception
    when others then
      xla_exceptions_pkg.raise_message(p_location => 'XXAR_REV_COGS_REPORT_PKG.xla_period_where');
  end xla_period_where;

  procedure update_revenue_account is
    type t_array_num is table of number
                          index by binary_integer;

    l_conc_seg_delimiter varchar2(80);
    l_concat_segment varchar2(4000);
    l_line_ids t_array_num;
    max_buffer_size number := 10000;
    l_rev_upd_stmt varchar2(32000)
      := 'update XXar_rev_cogs_details_gt
               set (revenue_account, revenue_gl_date, balancing_segment,invoice_currency,exchange_rate) =
                      (select distinct concatenated_segments,
                                       trunc (xlah.accounting_date),
                                       glcc.segment1,
                                       xlal.currency_code,
                                       xlal.currency_conversion_rate
                                  from xla_ae_lines xlal,
                                       xla_ae_headers xlah,
                                       xla_distribution_links xdl,
                                       gl_code_combinations_kfv glcc
                                 where --xlal.application_id = 222
                                   --and
                                   xlal.ae_header_id = xlah.ae_header_id
                                   --and xlah.application_id = 222
                                   and xlah.ledger_id = :1
                                   and xlal.ledger_id = :1
                                   and xlah.ae_header_id = xdl.ae_header_id
                                   and xdl.ae_line_num = xlal.ae_line_num
                                   and xdl.application_id = 222
                                   and xdl.source_distribution_type = ''RA_CUST_TRX_LINE_GL_DIST_ALL''
                                   $L_XLA_DATES$
                                   and xlal.accounting_class_code = ''REVENUE''
                                   and glcc.code_combination_id = xlal.code_combination_id
                                   and xdl.source_distribution_id_num_1 = :2)
             where cust_trx_line_gl_dist_id = :2';

    cursor c is
      select cust_trx_line_gl_dist_id
      from   xxar_rev_cogs_details_gt
      where  cust_trx_line_gl_dist_id is not null;
  begin
    l_rev_upd_stmt := replace(l_rev_upd_stmt, '$L_XLA_DATES$', xla_period_where);
    open c;

    loop
      fetch c
      bulk collect into l_line_ids
      limit max_buffer_size;

      for i in 1 .. l_line_ids.count loop
        execute immediate l_rev_upd_stmt using p_ledger_id, p_ledger_id, l_line_ids(i), l_line_ids(i);
      end loop;

      commit;
      exit when c%notfound;
    end loop;

    if c%isopen then
      close c;
    end if;
  exception
    when others then
      print_logfile('Error in Exception updating Revenue details : ' || sqlerrm);
  end update_revenue_account;

  procedure update_cogs_account is
    type t_array_num is table of number
                          index by binary_integer;

    l_conc_seg_delimiter varchar2(80);
    l_concat_segment varchar2(4000);
    l_line_ids t_array_num;
    l_inv_sub_ledger_ids dbms_sql.number_table;
    l_trx_ids dbms_sql.number_table;
    max_buffer_size number := 10000;
    l_cogs_upd_stmt varchar2(32000)
      := ' update XXar_rev_cogs_details_gt
               set (cogs_account, cogs_gl_date, xla_cogs_amount, balancing_segment) =
                      (select   concatenated_segments cogs_account,
                                xlah.accounting_date cogs_gl_date,
                                sum (nvl (accounted_dr, 0)) - sum (nvl (accounted_cr, 0)) xla_cogs_amount,
                                glcc.segment1
                           from xla_ae_lines xlal,
                                xla_ae_headers xlah,
                                xla_distribution_links xdl,
                                gl_code_combinations_kfv glcc
                          where --xlal.application_id = 707
                            --and
                            xlal.ae_header_id = xlah.ae_header_id
                            --and xlah.application_id = 707
                            and xdl.application_id = 707
                            and xlah.ledger_id = :1
                            and xlal.ledger_id = :1
                            and xdl.source_distribution_type = ''MTL_TRANSACTION_ACCOUNTS''
                            and xlal.accounting_class_code = ''COST_OF_GOODS_SOLD''
                            and xdl.source_distribution_id_num_1 in (select inv_sub_ledger_id from
                            mtl_transaction_accounts where transaction_id=:2)
                            and xdl.ae_header_id=xlah.ae_header_id
                            and xdl.ae_line_num=xlal.ae_line_num
                            $L_XLA_DATES$
                            and glcc.code_combination_id = xlal.code_combination_id
                       group by xlal.code_combination_id,
                                concatenated_segments,
                                xlah.accounting_date,
                                glcc.segment1)
             where inv_sub_ledger_id= :3
             and line_id = :4 ';

    cursor c is
      select distinct line_id, inv_sub_ledger_id, mmt_transaction_id
      from   xxar_rev_cogs_details_gt
      where  mmt_transaction_id is not null;
  begin
    l_cogs_upd_stmt := replace(l_cogs_upd_stmt, '$L_XLA_DATES$', xla_period_where);
    open c;

    loop
      fetch c
      bulk collect into l_line_ids, l_inv_sub_ledger_ids, l_trx_ids
      limit max_buffer_size;

      for i in 1 .. l_line_ids.count loop
        execute immediate l_cogs_upd_stmt
          using p_ledger_id
              , p_ledger_id
              , l_trx_ids(i)
              , l_inv_sub_ledger_ids(i)
              , l_line_ids(i);
      end loop;

      commit;
      exit when c%notfound;
    end loop;

    if c%isopen then
      close c;
    end if;
  exception
    when others then
      print_logfile('Error in Exception updating COGS details : ' || sqlerrm);
  end update_cogs_account;

  procedure populate_gt is
    l_ar_insert_gt_sql varchar2(32000);
    l_cogs_update_gt_sql varchar2(32000);
    g_financial_cat_set_id constant number := 1100000041;
    g_master_org_id constant number := 102;
    l_ar_customer_where varchar2(4000);
    l_cogs_customer_where varchar2(4000);
  begin
    l_ar_insert_gt_sql := c_new_insert_gt_stmt || c_new_insert_gt_select;
    l_ar_insert_gt_sql := replace(l_ar_insert_gt_sql, '$AR_PERIOD_WHERE$', ar_period_where);
    if p_customer_id is not null then
    l_ar_customer_where:=' and exists (select 1 from ra_customer_trx_all rat
    where rctl.customer_trx_id=rat.customer_trx_id
    and rat.bill_to_customer_id = '||p_customer_id||')';
    l_cogs_customer_where:=' and exists (select 1 from oe_order_lines_all oel
    where oel.line_id=mmt.trx_source_line_id
    and oel.sold_to_org_id='||p_customer_id||')';
    else
    l_ar_customer_where:=' and 1=1 ';
    l_cogs_customer_where:=' and 1=1 ';
    end if;
    l_ar_insert_gt_sql := replace(l_ar_insert_gt_sql, '$AR_CUSTOMER_WHERE$', l_ar_customer_where);
    print_logfile(l_ar_insert_gt_sql);
    execute immediate l_ar_insert_gt_sql using p_ledger_id, p_ledger_id;
    print_logfile('# of rows inserted into GT table ' || ' : ' || sql%rowcount);
    commit;
    fnd_stats.gather_table_stats('XXINTG', 'XXar_rev_cogs_details_gt', 40);
    l_cogs_update_gt_sql := c_cogs_upd_stmt;
    l_cogs_update_gt_sql := replace(l_cogs_update_gt_sql, '$L_DATES$', cogs_period_where);
    l_cogs_update_gt_sql := replace(l_cogs_update_gt_sql, '$COGS_CUSTOMER_WHERE$', l_cogs_customer_where);
    print_logfile(l_cogs_update_gt_sql);
    execute immediate l_cogs_update_gt_sql using p_ledger_id;
    commit;
    print_logfile('# of rows updated into GT table ' || ' : ' || sql%rowcount);
    update_revenue_account();
    update_cogs_account();
    update xxar_rev_cogs_details_gt xx
    set    (header_id
          , new_hospital_fulfillment) = (select header_id, a.attribute19
                                         from   oe_order_headers_all a, oe_order_types_115_all b
                                         where      a.order_type_id = b.order_type_id
                                                and xx.order_number = a.order_number
                                                and xx.order_type = b.name)
    where  balancing_segment is not null;
    update xxar_rev_cogs_details_gt xx
    set    line_id = -1, line_number = '-1.1'
    where  not exists
             (select 1
              from   oe_order_lines_all a
              where  xx.header_id = a.header_id and xx.line_id = a.line_id)
           and balancing_segment is not null;
    update xxar_rev_cogs_details_gt xx
    set    line_number = (select    decode(line.line_number, null, null, line.line_number)
                                 || decode(line.shipment_number, null, null, '.' || line.shipment_number)
                                 || decode(line.option_number, null, null, '.' || line.option_number)
                                 || decode(line.component_number, null, null, '.' || line.component_number)
                                 || decode(line.service_number, null, null, '.' || line.service_number)
                          from   oe_order_lines_all line
                          where  line.line_id = xx.line_id)
    where  line_id <> -1 and balancing_segment is not null;
    update xxar_rev_cogs_details_gt xx
    set    (line_type
          , item
          , item_desc
          , ip_owner
          , warehouse
          , ordered_quantity
          , item_dcode
          , Geo_code) = (select b.name
                                      , (select msi.segment1
                                         from   mtl_system_items_b msi
                                         where  msi.organization_id = nvl(a.ship_from_org_id, g_master_org_id)
                                                and msi.inventory_item_id = a.inventory_item_id)
                                          item
                                      , (select msi.description
                                         from   mtl_system_items_b msi
                                         where  msi.organization_id = nvl(a.ship_from_org_id, g_master_org_id)
                                                and msi.inventory_item_id = a.inventory_item_id)
                                          item_desc
                                      , (select mc.segment2
                                         from   mtl_item_categories mic, mtl_categories_kfv mc
                                         where      mic.category_set_id = g_financial_cat_set_id
                                                and mic.category_id = mc.category_id
                                                and mic.inventory_item_id = a.inventory_item_id
                                                and mic.organization_id = g_master_org_id)
                                          ip_owner
                                      , (select organization_code
                                         from   mtl_parameters mp
                                         where  mp.organization_id = a.ship_from_org_id)
                                          warehouse
                                      , a.ordered_quantity
                                      , (select mc.segment9
                                         from   mtl_item_categories mic, mtl_categories_kfv mc
                                         where      mic.category_set_id = 5
                                                and mic.category_id = mc.category_id
                                                and mic.inventory_item_id = a.inventory_item_id
                                                and mic.organization_id = g_master_org_id)
                                      /*, nvl((select country from oe_deliver_to_orgs_v del where del.organization_id=a.deliver_to_org_Id),
                                            (select country from oe_ship_to_orgs_v del where del.organization_id=a.ship_to_org_Id))*/ --Commented for case#11872
                                       ,(select hcsa.attribute17
                                           from hz_cust_acct_sites_all hcsa
                                               ,hz_cust_site_uses_all hcsua
                                          where hcsa.cust_acct_site_id = hcsua.cust_acct_site_id
                                            and hcsua.site_use_id = a.ship_to_org_Id) Geo_code --Added for case#11872
                            from   oe_order_lines_all a, oe_line_types_v b
                            where  a.line_type_id = b.line_type_id
                             and xx.line_id = a.line_id
                           )
    where  balancing_segment is not null;
    update xxar_rev_cogs_details_gt xx
    set    (item
          , ordered_quantity) = (select description, nvl(quantity_invoiced, quantity_credited)
                                 from   ra_customer_trx_lines_all a
                                 where  xx.customer_trx_line_id = a.customer_trx_line_id)
    where  line_id = -1 and balancing_segment is not null;
    update xxar_rev_cogs_details_gt xx
    set    (customer_number
          , customer_name) = (select account_number, party_name
                              from   oe_order_headers_all a, hz_cust_accounts hca, hz_parties hp
                              where  xx.header_id = a.header_id and a.sold_to_org_id = hca.cust_account_id and hca.party_id = hp.party_id)
    where  balancing_segment is not null;
    update xxar_rev_cogs_details_gt xx
    set    (trx_number
          , ar_trx_type) = (select trx_number, name
                            from   ra_customer_trx_all a, ra_cust_trx_types_all b
                            where      xx.customer_trx_id = a.customer_trx_id
                                   and a.cust_trx_type_id = b.cust_trx_type_id
                                   and a.org_id = b.org_id)
    where  balancing_segment is not null;
    update xxar_rev_cogs_details_gt xx
    set    revenue_gl_period = p_period_name
    where  cust_trx_line_gl_dist_id is not null;
    update xxar_rev_cogs_details_gt xx
    set    cogs_gl_period = p_period_name
    where  mmt_transaction_id is not null;
    update xxar_rev_cogs_details_gt xx
    set    return_order_number = (select case
                                           when a.reference_line_id is not null then
                                             (select max(order_number)
                                              from   oe_order_headers_all oeh, oe_order_lines_all oel
                                              where  oeh.header_id = oel.header_id and oel.line_id = a.reference_line_id)
                                           else
                                             null
                                         end
                                           return_order_number
                                  from   oe_order_lines_all a, oe_order_headers_all b
                                  where  a.header_id = b.header_id and xx.line_id = a.line_id);
    insert into xxar_rev_cogs_report_gt(order_number
                                      , returned_order_number
                                      , order_type
                                      , line_number
                                      , line_type
                                      , item
                                      , item_desc
                                      , ip_owner
                                      , ordered_quantity
                                      , customer_number
                                      , customer_name
                                      , trx_number
                                      , ar_trx_type
                                      , revenue_amount
                                      , revenue_account
                                      , revenue_gl_date
                                      , revenue_gl_period
                                      , cogs_amount
                                      , cogs_account
                                      , cogs_gl_date
                                      , cogs_gl_period
                                      , balancing_segment
                                      , new_hospital_fulfillment
                                      , warehouse
                                      , entered_revenue
                                      , exchange_rate
                                      , invoice_currency
                                      , item_dcode
                                      , Geo_code)
      select   order_number, return_order_number, order_type, line_number, line_type, item, item_desc, ip_owner, ordered_quantity
             , customer_number, customer_name, trx_number, ar_trx_type, sum(revenue), revenue_account, revenue_gl_date, revenue_gl_period
             , sum(xla_cogs_amount), cogs_account, cogs_gl_date, cogs_gl_period, balancing_segment, new_hospital_fulfillment, warehouse
             , entered_revenue, exchange_rate, invoice_currency,item_dcode,Geo_code
      from     xxar_rev_cogs_details_gt
      where    balancing_segment = p_bal_segment
      group by header_id
             , order_number
             , return_order_number
             , order_type
             , line_id
             , line_number
             , line_type
             , item
             , item_desc
             , ip_owner
             , ordered_quantity
             , customer_number
             , customer_name
             , trx_number
             , ar_trx_type
             , revenue_account
             , revenue_gl_date
             , revenue_gl_period
             , cogs_account
             , cogs_gl_date
             , cogs_gl_period
             , balancing_segment
             , new_hospital_fulfillment
             , warehouse
             , entered_revenue
             , exchange_rate
             , invoice_currency
             , item_dcode
             , Geo_code
      order by order_number, line_number;
    print_logfile('Customer ID : ' || p_customer_id);
    if p_customer_id is not null then
      print_logfile('Customer ID : ' || p_customer_id);
      delete xxar_rev_cogs_report_gt
      where  customer_number not in (select account_number
                                     from   hz_cust_accounts
                                     where  cust_account_id = p_customer_id);
    end if;

    commit;
  exception
    when others then
      print_logfile('Error in Exception : ' || sqlerrm);
  end;

  function before_report
    return boolean is
    l_ledger_id number;
    l_bal_segment varchar2(100);
    l_period_name varchar2(100);
    l_balance_type varchar2(100);
    l_customer_id number;
  begin
    l_ledger_id := p_ledger_id;
    l_bal_segment := p_bal_segment;
    l_balance_type := p_balance_type;
    l_period_name := p_period_name;
    l_customer_id := p_customer_id;
    --xla_security_pkg.set_security_context(p_application_id => 707);
    print_logfile('Parameters');
    print_logfile('-----------------------------------------');
    print_logfile('Ledger ID : ' || l_ledger_id);
    print_logfile('Balancing Segment : ' || l_bal_segment);
    print_logfile('Balance Type : ' || l_balance_type);
    print_logfile('Period Name : ' || l_period_name);
    print_logfile('Customer ID : ' || l_customer_id);
    delete xxar_rev_cogs_report_gt;
    populate_gt;
    commit;
    return true;
  exception
    when others then
      print_logfile('Error in Exception : ' || sqlerrm);
      return false;
  end;
begin
  g_log_level := fnd_log.g_current_runtime_level;
  g_log_enabled := fnd_log.test(log_level => g_log_level, module => c_default_module);

  if not g_log_enabled then
    g_log_level := c_level_log_disabled;
  end if;
end xxar_rev_cogs_report_pkg;
/
