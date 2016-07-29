DROP PACKAGE BODY APPS.XX_AR_AGING_XML_RPT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_AGING_XML_RPT_PKG" as
  procedure debug(p_msg in varchar2) is
  begin
    fnd_file.put_line(fnd_file.log, p_msg);
    --dbms_outout.put_line(p_msg);
  end;
   procedure print_xml_element(p_field in varchar2, p_value in varchar2) is
  begin
    fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
  end;

  procedure print_xml_element(p_field in varchar2, p_value in number) is
  begin
    fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '>' || p_value || '</' || upper(p_field) || '>');
  end;

  procedure print_xml_element(p_field in varchar2, p_value in date) is
  begin
    fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
  end;

  /*==========================================================================
  | PRIVATE PROCEDURE populate_setup_information                             |
  |                                                                          |
  | DESCRIPTION                                                              |
  |      Populates setup related info to local variables                     |
  |                                                                          |
  |                                                                          |
  | CALLED FROM PROCEDURES/FUNCTIONS (local to this package body)            |
  |                                                                          |
  | PARAMETERS                                                               |
  |  NONE                                                                    |
  |                                                                          |
  | KNOWN ISSUES                                                             |
  |                                                                          |
  | NOTES                                                                    |
  |                                                                          |
  | MODIFICATION HISTORY                                                     |
  | Date                  Author            Description of Changes           |
  | 10-JUL-2009           Naga Uppara       Created                          |
  | 15-DEC-2015           Raviteja (NTT)    Case#6747 - State and TRX Date   |
  *==========================================================================*/
  procedure populate_setup_information is
    l_sys_query varchar2(20000);
  begin
    debug(' xx_ar_aging_xml_rpt_pkg.populate_setup_information()+');
    l_sys_query := '
        SELECT  param.org_id,
      sob.name,
      sob.chart_of_accounts_id,
      sob.currency_code,
      cur.precision,
      decode(:p_in_currency,NULL,''Y'',NULL),
      param.set_of_books_id
    FROM gl_sets_of_books sob,
             ar_system_parameters param,
             fnd_currencies cur
        WHERE  sob.set_of_books_id = param.set_of_books_id
        AND  sob.currency_code = cur.currency_code
    AND  rownum = 1
    ' || pg_org_where_sys_param;
    debug(' l_sys_query  :' || l_sys_query);
    execute immediate l_sys_query
      into pg_param_org_id, pg_company_name, pg_coaid, pg_functional_currency, pg_func_curr_precision, pg_convert_flag, pg_set_of_books_id
      using pg_in_currency;
    debug(' Rows returned  ' || sql%rowcount);
    debug(' xx_ar_aging_xml_rpt_pkg.populate_setup_information()+');
  exception
    when others then
      arp_standard.debug(' Exception ' || sqlerrm);
      arp_standard.debug(' Exception xx_ar_aging_xml_rpt_pkg.populate_setup_information()');
      raise;
  end populate_setup_information;

  /*==========================================================================
  | PRIVATE FUNCTION get_reporting_entity_id                                 |
  |                                                                          |
  | DESCRIPTION                                                              |
  |                                                                          |
  |                                                                          |
  | CALLED FROM PROCEDURES/FUNCTIONS (local to this package body)            |
  |                                                                          |
  | PARAMETERS                                                               |
  |                                                                          |
  | KNOWN ISSUES                                                             |
  |                                                                          |
  | NOTES                                                                    |
  |                                                                          |
  | MODIFICATION HISTORY                                                     |
  | Date                  Author            Description of Changes           |
  | 10-JUL-2009           Naga Uppara       Created                          |
  *==========================================================================*/
 function adj_max_idformula
    return number is
  begin
    declare
      adj_max_id number(16);
    begin
      select ar_adjustments_s.nextval
      into   adj_max_id
      from   dual;
      pg_adj_max_id := adj_max_id;
      return (adj_max_id);
    exception
      when no_data_found then
        return (-1);
    end;

    return null;
  end;

  procedure build_invoice_select is
  begin
    ------------------------------------------------------------
    -- BUILD FIRST SELECT STATEMENT
    ------------------------------------------------------------
    l_inv_sel1 := 'select substrb(party.party_name,1,50) cust_name_inv, ' || 'cust_acct.account_number cust_no_inv,';
    l_inv_sel1 := l_inv_sel1 || new_line;

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel1 :=    l_inv_sel1
                    || 'decode(upper(:p_in_sortoption),''CUSTOMER'',NULL, '
                    || 'arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id))';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel1 := l_inv_sel1 || 'col.name';
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel1 := l_inv_sel1 || 'extns.resource_name';
    elsif (pg_rep_type = 'ARXAGF') then
      /* Aging Reports pick those transactions
         as well which are not yet accounted. Only Aging 7 bucket by Account Report
         will include the transactions either Accounted or for which POST TO GL flag
         is set to NO.] */
      l_inv_sel1 := l_inv_sel1 || 'decode(types.post_to_gl, ''Y'', ';
      l_inv_sel1 := l_inv_sel1 || lp_accounting_flexfield;
      l_inv_sel1 := l_inv_sel1 || ', NULL)';
    end if;

    l_inv_sel1 := l_inv_sel1 || ' sort_field1_inv,' || new_line;
    l_inv_sel1 :=    l_inv_sel1
                  || 'arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id) sort_field2_inv,'
                  || new_line;

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel1 := l_inv_sel1 || 'decode(upper(:p_in_sortoption),''CUSTOMER'',-999,ps.cust_trx_type_id)';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel1 := l_inv_sel1 || 'col.collector_id';
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel1 := l_inv_sel1 || 'nvl(sales.salesrep_id, -3)';
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel1 := l_inv_sel1 || 'c.code_combination_id';
    end if;

    l_inv_sel1 := l_inv_sel1 || ' inv_tid_inv, ';
    l_inv_sel1 :=    l_inv_sel1
                  || ' site.site_use_id contact_site_id_inv, '
                  || 'loc.state cust_state_inv, '
                  || 'loc.city cust_city_inv, '
                  || 'decode(:format_detailed,NULL,-1,acct_site.cust_acct_site_id) addr_id_inv, '
                  || 'nvl(cust_acct.cust_account_id,-999) cust_id_inv, '
                  || 'ps.payment_schedule_id payment_sched_id_inv, '
                  || 'ps.class class_inv, '
				  || 'ps.trx_date transaction_date_inv,'   --Added for case #6747
                  || 'ps.due_date  due_date_inv, '
                  || 'amt_due_remaining_inv, '
                  || 'ps.trx_number invnum, '
                  || 'ceil(:as_of_date - ps.due_date) days_past_due, '
                  || 'ps.amount_adjusted amount_adjusted_inv, '
                  || 'ps.amount_applied amount_applied_inv, '
                  || 'ps.amount_credited amount_credited_inv, '
                  || 'ps.gl_date gl_date_inv, '
                  || 'decode(ps.invoice_currency_code, :functional_currency, NULL, '
                  || 'decode(ps.exchange_rate, NULL, ''*'', NULL)) data_converted_inv, '
                  || 'nvl(ps.exchange_rate, 1) ps_exchange_rate_inv, ';
    l_inv_sel1 :=    l_inv_sel1
                  || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0, '
                  || 'dh.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_0,:bucket_days_to_0, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b0_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_1, '
                  || 'dh.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_1,:bucket_days_to_1, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b1_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_2, '
                  || 'dh.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_2,:bucket_days_to_2, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b2_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_3, '
                  || 'dh.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_3,:bucket_days_to_3, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b3_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_4, '
                  || 'dh.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_4,:bucket_days_to_4, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b4_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_5, '
                  || 'dh.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_5,:bucket_days_to_5, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b5_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_6, '
                  || 'dh.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_6,:bucket_days_to_6, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b6_inv,';
                  debug('b0_inv');
                  debug('b1_inv');
                  debug('b2_inv');
                  debug('b3_inv');
                  debug('b4_inv');
                  debug('b5_inv');
                  debug('b6_inv');             
    l_inv_sel1 := l_inv_sel1 || lp_acct_flex_bal_seg || ' company_inv,';
    l_inv_sel1 := l_inv_sel1 || lp_query_show_bill || ' cons_billing_number, ';
    l_inv_sel1 :=    l_inv_sel1
                  || ' arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id)'
                  || ' invoice_type_inv ';
    l_inv_sel1 := l_inv_sel1 || ' from hz_cust_accounts cust_acct, ' || 'hz_parties party, ';
    l_inv_sel1 :=    l_inv_sel1
                  || '(select a.customer_id, '
                  || 'a.customer_site_use_id , '
                  || 'a.customer_trx_id, '
                  || 'a.payment_schedule_id, '
                  || 'a.class , '
                  || 'sum(a.primary_salesrep_id) primary_salesrep_id, '
				  || 'a.trx_date,'    --Added for case #6747
                  || 'a.due_date , '
                  || 'sum(a.amount_due_remaining) amt_due_remaining_inv, '
                  || 'a.trx_number, '
                  || 'a.amount_adjusted, '
                  || 'a.amount_applied , '
                  || 'a.amount_credited , '
                  || 'a.amount_adjusted_pending, '
                  || 'a.gl_date , '
                  || 'a.cust_trx_type_id, '
                  || 'a.org_id, '
                  || 'a.invoice_currency_code, '
                  || 'a.exchange_rate, '
                  || 'sum(a.cons_inv_id) cons_inv_id '
                  || 'from '
                  || '(  select '
                  || 'ps.customer_id, '
                  || 'ps.customer_site_use_id , '
                  || 'ps.customer_trx_id, '
                  || 'ps.payment_schedule_id, '
                  || 'ps.class , '
                  || '0 primary_salesrep_id, '
				  || 'ps.trx_date,'   --Added for case #6747
                  || 'ps.due_date , '
                  || 'nvl(sum ( decode( :c_convert_flag, ''Y'', '
                  || 'nvl(adj.acctd_amount, 0), '
                  || 'adj.amount ) '
                  || '),0) * (-1)  amount_due_remaining, '
                  || 'ps.trx_number, '
                  || 'ps.amount_adjusted , '
                  || 'ps.amount_applied , '
                  || 'ps.amount_credited , '
                  || 'ps.amount_adjusted_pending, '
                  || 'ps.gl_date , '
                  || 'ps.cust_trx_type_id, '
                  || 'ps.org_id, '
                  || 'ps.invoice_currency_code, '
                  || 'nvl(ps.exchange_rate,1) exchange_rate, '
                  || '0 cons_inv_id '
                  || 'from  ar_payment_schedules ps, '
                  || 'ar_adjustments adj ';
                  
                  debug('amount_due_remaining');

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_inv_sel1 := l_inv_sel1 || ', hz_cust_accounts cust_acct ';
    end if;

    l_inv_sel1 :=    l_inv_sel1
                  || 'where  ps.gl_date <= :as_of_date '
                  || 'and ps.customer_id > 0 '
                  || 'and  ps.gl_date_closed  > :as_of_date '
                  || 'and  decode(upper(:p_in_currency),NULL, ps.invoice_currency_code, '
                  || 'upper(:p_in_currency)) = ps.invoice_currency_code '
                  || 'and  adj.payment_schedule_id = ps.payment_schedule_id '
                  || 'and  adj.status = ''A'' '
                  || 'and  adj.gl_date > :as_of_date ';
    l_inv_sel1 := l_inv_sel1 || lp_customer_num_low;
    l_inv_sel1 := l_inv_sel1 || lp_customer_num_high;

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_inv_sel1 := l_inv_sel1 || ' and ps.customer_id = cust_acct.cust_account_id ';
    end if;

    l_inv_sel1 := l_inv_sel1 || pg_org_where_ps;
    l_inv_sel1 := l_inv_sel1 || pg_org_where_adj;
    l_inv_sel1 :=    l_inv_sel1
                  || ' group by '
                  || 'ps.customer_id, '
                  || 'ps.customer_site_use_id , '
                  || 'ps.customer_trx_id, '
                  || 'ps.class , '
		  || 'ps.trx_date,'   --Added for case #6747
                  || 'ps.due_date, '
                  || 'ps.trx_number, '
                  || 'ps.amount_adjusted , '
                  || 'ps.amount_applied , '
                  || 'ps.amount_credited , '
                  || 'ps.amount_adjusted_pending, '
                  || 'ps.gl_date , '
                  || 'ps.cust_trx_type_id, '
                  || 'ps.org_id, '
                  || 'ps.invoice_currency_code, '
                  || 'nvl(ps.exchange_rate,1), '
                  || 'ps.payment_schedule_id '
                  || 'UNION ALL '
                  || 'select /*+ INDEX(ps AR_PAYMENT_SCHEDULES_N9) */ ps.customer_id, '
                  || 'ps.customer_site_use_id , '
                  || 'ps.customer_trx_id, '
                  || 'ps.payment_schedule_id, '
                  || 'ps.class , '
                  || '0 primary_salesrep_id, '
				  || 'ps.trx_date ,'  --Added for case #6747
                  || 'ps.due_date  , '
                  || 'nvl(sum ( decode '
                  || '( :c_convert_flag, ''Y'', '
                  || '(decode(ps.class, ''CM'', '
                  || 'decode ( app.application_type, ''CM'', '
                  || 'app.acctd_amount_applied_from, '
                  || 'app.acctd_amount_applied_to '
                  || '), '
                  || 'app.acctd_amount_applied_to)+ '
                  || 'nvl(app.acctd_earned_discount_taken,0) + '
                  || 'nvl(app.acctd_unearned_discount_taken,0)) '
                  || ', '
                  || '( app.amount_applied + '
                  || 'nvl(app.earned_discount_taken,0) + '
                  || 'nvl(app.unearned_discount_taken,0) ) '
                  || ') * '
                  || 'decode '
                  || '( ps.class, ''CM'', '
                  || 'decode(app.application_type, ''CM'', -1, 1), 1 ) '
                  || '), 0) amount_due_remaining_inv, '
                  || 'ps.trx_number , '
                  || 'ps.amount_adjusted, '
                  || 'ps.amount_applied , '
                  || 'ps.amount_credited , '
                  || 'ps.amount_adjusted_pending, '
                  || 'ps.gl_date gl_date_inv, '
                  || 'ps.cust_trx_type_id, '
                  || 'ps.org_id, '
                  || 'ps.invoice_currency_code, '
                  || 'nvl(ps.exchange_rate, 1) exchange_rate, '
                  || '0 cons_inv_id '
                  || 'from  ar_payment_schedules ps, '
                  || 'ar_receivable_applications app ';

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_inv_sel1 := l_inv_sel1 || ', hz_cust_accounts cust_acct ';
    end if;

    l_inv_sel1 :=    l_inv_sel1
                  || 'where  ps.gl_date <= :as_of_date '
                  || 'and   ps.customer_id > 0 '
                  || 'and   ps.gl_date_closed  > :as_of_date '
                  || 'and   decode(upper(:p_in_currency),NULL, ps.invoice_currency_code, '
                  || 'upper(:p_in_currency)) = ps.invoice_currency_code '
                  || 'and  (app.applied_payment_schedule_id = ps.payment_schedule_id '
                  || 'OR '
                  || 'app.payment_schedule_id = ps.payment_schedule_id) '
                  || 'and   app.status IN (''APP'', ''ACTIVITY'') '
                  || 'and   nvl( app.confirmed_flag, ''Y'' ) = ''Y'' '
                  || 'and   app.gl_date > :as_of_date';
    l_inv_sel1 := l_inv_sel1 || lp_customer_num_low;
    l_inv_sel1 := l_inv_sel1 || lp_customer_num_high;

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_inv_sel1 := l_inv_sel1 || ' and ps.customer_id = cust_acct.cust_account_id ';
    end if;

    l_inv_sel1 := l_inv_sel1 || pg_org_where_ps;
    l_inv_sel1 := l_inv_sel1 || pg_org_where_app;
    l_inv_sel1 :=    l_inv_sel1
                  || ' group by '
                  || 'ps.customer_id, '
                  || 'ps.customer_site_use_id , '
                  || 'ps.customer_trx_id, '
                  || 'ps.class , '
				  || 'ps.trx_date,'   --Added for case #6747
                  || 'ps.due_date, '
                  || 'ps.trx_number, '
                  || 'ps.amount_adjusted , '
                  || 'ps.amount_applied , '
                  || 'ps.amount_credited , '
                  || 'ps.amount_adjusted_pending, '
                  || 'ps.gl_date , '
                  || 'ps.cust_trx_type_id, '
                  || 'ps.org_id, '
                  || 'ps.invoice_currency_code, '
                  || 'nvl(ps.exchange_rate, 1), '
                  || 'ps.payment_schedule_id '
                  || 'UNION ALL '
                  || 'select  ps.customer_id, '
                  || 'ps.customer_site_use_id , '
                  || 'ps.customer_trx_id, '
                  || 'ps.payment_schedule_id, '
                  || 'ps.class class_inv, '
                  || 'nvl(ct.primary_salesrep_id, -3) primary_salesrep_id, '
				  || 'ps.trx_date transaction_date_inv,'  --Added for case #6747
                  || 'ps.due_date  due_date_inv, '
                  || 'decode( :c_convert_flag, ''Y'', '
                  || 'ps.acctd_amount_due_remaining, '
                  || 'ps.amount_due_remaining) amt_due_remaining_inv, '
                  || 'ps.trx_number, '
                  || 'ps.amount_adjusted , '
                  || 'ps.amount_applied , '
                  || 'ps.amount_credited , '
                  || 'ps.amount_adjusted_pending, '
                  || 'ps.gl_date , '
                  || 'ps.cust_trx_type_id, '
                  || 'ps.org_id, '
                  || 'ps.invoice_currency_code, '
                  || 'nvl(ps.exchange_rate, 1) exchange_rate, '
                  || 'ps.cons_inv_id '
                  || 'from  ar_payment_schedules ps, '
                  || 'ra_customer_trx ct ';

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_inv_sel1 := l_inv_sel1 || ', hz_cust_accounts cust_acct ';
    end if;

    l_inv_sel1 :=    l_inv_sel1
                  || 'where  ps.gl_date <= :as_of_date '
                  || --     and ps.customer_id > 0
                    'and   ps.gl_date_closed  > :as_of_date '
                  || 'and   decode(upper(:p_in_currency),NULL, ps.invoice_currency_code, '
                  || 'upper(:p_in_currency)) = ps.invoice_currency_code '
                  || 'and  ps.customer_trx_id = ct.customer_trx_id';

    if pg_rep_type = 'ARXAGR' then
      l_inv_sel1 := l_inv_sel1 || ' and ps.class <> ''CB'' ';
    end if;

    l_inv_sel1 := l_inv_sel1 || lp_customer_num_low;
    l_inv_sel1 := l_inv_sel1 || lp_customer_num_high;

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_inv_sel1 := l_inv_sel1 || ' and ps.customer_id = cust_acct.cust_account_id';
    end if;

    l_inv_sel1 := l_inv_sel1 || p_org_where_ps;
    l_inv_sel1 := l_inv_sel1 || p_org_where_ct;

    if pg_rep_type = 'ARXAGR' then
      l_inv_sel1 :=    l_inv_sel1
                    || ' UNION ALL '
                    || 'select  ps.customer_id, '
                    || 'ps.customer_site_use_id , '
                    || 'ps.customer_trx_id, '
                    || 'ps.payment_schedule_id, '
                    || 'ps.class class_inv, '
                    || 'ct.primary_salesrep_id primary_salesrep_id, '
					|| 'ps.trx_date transaction_date_inv,'   --Added for case #6747
                    || 'ps.due_date  due_date_inv, '
                    || 'decode( :c_convert_flag, ''Y'', '
                    || 'ps.acctd_amount_due_remaining, '
                    || 'ps.amount_due_remaining) amt_due_remaining_inv, '
                    || 'ps.trx_number, '
                    || 'ps.amount_adjusted , '
                    || 'ps.amount_applied , '
                    || 'ps.amount_credited , '
                    || 'ps.amount_adjusted_pending, '
                    || 'ps.gl_date , '
                    || 'ps.cust_trx_type_id, '
                    || 'ps.org_id, '
                    || 'ps.invoice_currency_code, '
                    || 'nvl(ps.exchange_rate, 1) exchange_rate, '
                    || 'ps.cons_inv_id '
                    || 'from  ar_payment_schedules ps, '
                    || 'ra_customer_trx ct, '
                    || 'ar_adjustments adj ';
                    
                    debug('ps.amount_due_remaining');

      if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
        l_inv_sel1 := l_inv_sel1 || ', hz_cust_accounts cust_acct ';
      end if;

      l_inv_sel1 :=    l_inv_sel1
                    || 'where  ps.gl_date <= :as_of_date '
                    || --    and ps.customer_id > 0
                      'and   ps.gl_date_closed  > :as_of_date '
                    || 'and   decode(upper(:p_in_currency),NULL, ps.invoice_currency_code, '
                    || 'upper(:p_in_currency)) = ps.invoice_currency_code '
                    || 'and  ps.class = ''CB'' '
                    || 'and  ps.customer_trx_id = adj.chargeback_customer_trx_id '
                    || 'and  adj.customer_trx_id = ct.customer_trx_id';
      l_inv_sel1 := l_inv_sel1 || lp_customer_num_low;
      l_inv_sel1 := l_inv_sel1 || lp_customer_num_high;

      if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
        l_inv_sel1 := l_inv_sel1 || ' and ps.customer_id = cust_acct.cust_account_id ';
      end if;

      l_inv_sel1 := l_inv_sel1 || p_org_where_ps;
      l_inv_sel1 := l_inv_sel1 || p_org_where_ct;
      l_inv_sel1 := l_inv_sel1 || p_org_where_adj;
    end if;

    l_inv_sel1 :=    l_inv_sel1
                  || ' ) a '
                  || ' group by a.customer_id, '
                  || 'a.customer_site_use_id , '
                  || 'a.customer_trx_id, '
                  || 'a.payment_schedule_id, '
                  || 'a.class , '
				  || 'a.trx_date ,'  --Added for case #6747
                  || 'a.due_date , '
                  || 'a.trx_number, '
                  || 'a.amount_adjusted, '
                  || 'a.amount_applied , '
                  || 'a.amount_credited , '
                  || 'a.amount_adjusted_pending, '
                  || 'a.gl_date , '
                  || 'a.cust_trx_type_id, '
                  || 'a.org_id, '
                  || 'a.invoice_currency_code, '
                  || 'a.exchange_rate) ps, ';
    --end if;
    l_inv_sel1 := l_inv_sel1 || lp_table_show_bill;
    l_inv_sel1 := l_inv_sel1 || lp_agr_from3;
    l_inv_sel1 :=    l_inv_sel1
                  || ' hz_cust_site_uses site, '
                  || 'hz_cust_acct_sites acct_site, '
                  || 'hz_party_sites party_site, '
                  || 'hz_locations loc, '
                  || 'ra_cust_trx_line_gl_dist gld, ';

    if pg_rep_type = 'ARXAGF' then
      l_inv_sel1 :=    l_inv_sel1
                    || 'xla_distribution_links lk, '
                    || 'xla_ae_lines ae ,'
                    || 'xla_ae_headers aeh, '
                    || 'ra_cust_trx_types types, ';
    end if;

    l_inv_sel1 := l_inv_sel1 || 'ar_dispute_history dh, ' || 'gl_code_combinations c ';
    l_inv_sel1 := l_inv_sel1 || lp_agl_from1;
    l_inv_sel1 :=    l_inv_sel1
                  || ' where '
                  || 'upper(RTRIM(RPAD(:p_in_summary_option_low,1)) ) = ''I'' '
                  || 'and   ps.customer_site_use_id = site.site_use_id '
                  || 'and   site.cust_acct_site_id = acct_site.cust_acct_site_id '
                  || 'and   acct_site.party_site_id = party_site.party_site_id '
                  || 'and   loc.location_id = party_site.location_id '
                  || 'and   gld.account_class = ''REC'' '
                  || 'and   gld.latest_rec_flag = ''Y'' ';

    if pg_rep_type = 'ARXAGF' then
      l_inv_sel1 :=    l_inv_sel1
                    || 'and types.cust_trx_type_id = ps.cust_trx_type_id '
                    || 'and types.org_id = ps.org_id '
                    || 'and gld.event_id = lk.event_id(+) '
                    || 'and gld.cust_trx_line_gl_dist_id = lk.source_distribution_id_num_1(+) '
                    || 'and lk.source_distribution_type(+)   = ''RA_CUST_TRX_LINE_GL_DIST_ALL'' '
                    || 'and lk.application_id(+)             = 222 '
                    || 'and ae.application_id(+)          = 222 '
                    || 'and lk.ae_header_id                = ae.ae_header_id(+) '
                    || 'and lk.ae_line_num                 = ae.ae_line_num(+) '
                    || 'and ae.ae_header_id = aeh.ae_header_id(+) '
                    || 'and aeh.application_id(+)          = 222 '
                    || 'and aeh.event_type_code(+) <> ''MANUAL'' '
                    || 'and decode(ae.accounting_class_code,'''',decode(lk.source_distribution_type,'''',''Y'',''N''),''RECEIVABLE'',''Y'',''N'') = ''Y'' '
                    || 'and decode(ae.ledger_id,'''',decode(types.post_to_gl, ''N'', gld.code_combination_id, decode(gld.posting_control_id,-3,-999999,gld.code_combination_id)),gld.set_of_books_id,ae.code_combination_id,-999999)= c.code_combination_id ';
    else
      l_inv_sel1 := l_inv_sel1 || 'and gld.code_combination_id = c.code_combination_id ';
    end if;

    l_inv_sel1 :=    l_inv_sel1
                  || 'and   ps.payment_schedule_id  =  dh. payment_schedule_id(+) '
                  || 'and   ps.org_id = :param_org_id '
                  || 'and  :as_of_date  >= nvl(dh.start_date(+), :as_of_date) '
                  || 'and  :as_of_date  <  nvl(dh.end_date(+), :as_of_date + 1) '
                  || 'and   cust_acct.party_id = party.party_id ';
    l_inv_sel1 := l_inv_sel1 || lp_customer_name_low;
    l_inv_sel1 := l_inv_sel1 || lp_customer_name_high;
    l_inv_sel1 := l_inv_sel1 || lp_customer_num_low;
    l_inv_sel1 := l_inv_sel1 || lp_customer_num_high;
    l_inv_sel1 := l_inv_sel1 || lp_invoice_type_low;
    l_inv_sel1 := l_inv_sel1 || lp_invoice_type_high;
    l_inv_sel1 := l_inv_sel1 || lp_bal_low;
    l_inv_sel1 := l_inv_sel1 || lp_bal_high;
    l_inv_sel1 := l_inv_sel1 || lp_where_show_bill;
    l_inv_sel1 := l_inv_sel1 || lp_agfs_where2;
    l_inv_sel1 := l_inv_sel1 || lp_aglr_where1;

    if (pg_rep_type in ('ARXAGR', 'ARXAGL')) then
      l_inv_sel1 := l_inv_sel1 || ' and ps.customer_trx_id = gld.customer_trx_id ';
    end if;

    l_inv_sel1 := l_inv_sel1 || lp_agl_where1;

    if pg_rep_type = 'ARXAGR' then
      l_inv_sel1 := l_inv_sel1 || ' and nvl(ps.primary_salesrep_id,-3) = sales.salesrep_id ';
    end if;

    l_inv_sel1 := l_inv_sel1 || lp_agr_where5;
    l_inv_sel1 := l_inv_sel1 || lp_agr_where4;
    l_inv_sel1 := l_inv_sel1 || p_org_where_gld;
    l_inv_sel1 := l_inv_sel1 || p_org_where_addr;
    l_inv_sel1 := l_inv_sel1 || lp_agr_where_org1;

    --:common_query_inv1 := l_inv_sel1;
    -----------------------------------------------------------------
    -- BUILD SELECT #3
    -----------------------------------------------------------------
    if (    pg_in_customer_name_low is null
        and pg_in_customer_name_high is null
        and pg_in_customer_num_low is null
        and pg_in_customer_num_high is null) then
      l_inv_sel3 :=    'select '
                    || 'substrb(nvl(party.party_name,:p_short_unid_phrase),1,50) cust_name_inv, '
                    || 'cust_acct.account_number cust_no_inv,';
    else
      l_inv_sel3 :=    'select  /*+ leading(cust_acct) push_pred(app) use_nl(ps, app) push_pred(site) push_pred(acct_site) */ '
                    || 'substrb(nvl(party.party_name,:p_short_unid_phrase),1,50) cust_name_inv, '
                    || 'cust_acct.account_number cust_no_inv,';
    end if;

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel3 := l_inv_sel3 || 'decode(upper(:p_in_sortoption),''CUSTOMER'',NULL, ' || 'initcap(:lp_payment_meaning)) ,';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel3 := l_inv_sel3 || lp_agl_name;
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel3 := l_inv_sel3 || lp_agr_name;
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel3 := l_inv_sel3 || 'app.segments, ';
    end if;

    l_inv_sel3 := l_inv_sel3 || 'initcap(:lp_payment_meaning),';

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel3 := l_inv_sel3 || '-999,';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel3 := l_inv_sel3 || lp_agl_id;
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel3 := l_inv_sel3 || lp_agr_id;
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel3 := l_inv_sel3 || 'app.code_combination_id,';
    end if;

    l_inv_sel3 :=    l_inv_sel3
                  || ' site.site_use_id, '
                  || 'loc.state cust_state_inv, '
                  || 'loc.city cust_state_inv, '
                  || 'decode(:format_detailed,NULL,-1,acct_site.cust_acct_site_id) addr_id_inv, '
                  || 'nvl(cust_acct.cust_account_id, -999) cust_id_inv, '
                  || 'ps.payment_schedule_id, '
                  || 'app.class, '
				  || 'ps.trx_date,'   --Added for case #6747
                  || 'ps.due_date, '
                  || 'decode '
                  || '( :c_convert_flag, ''Y'',  nvl(-SUM(acctd_amount), 0), nvl(-SUM(amount), 0)), '
                  || 'ps.trx_number, '
                  || 'ceil(:as_of_date - ps.due_date), '
                  || 'ps.amount_adjusted, '
                  || 'ps.amount_applied, '
                  || 'ps.amount_credited, '
                  || 'ps.gl_date, '
                  || 'decode(ps.invoice_currency_code, :functional_currency, NULL, '
                  || 'decode(ps.exchange_rate, NULL, ''*'', NULL)), '
                  || 'nvl(ps.exchange_rate, 1),';
    l_inv_sel3 :=    l_inv_sel3
                  || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_0,:bucket_days_to_0, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b0_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_1, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_1,:bucket_days_to_1, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b1_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_2, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_2,:bucket_days_to_2, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b2_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_3, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_3,:bucket_days_to_3, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b3_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_4, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_4,:bucket_days_to_4, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b4_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_5, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_5,:bucket_days_to_5, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b5_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_6, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_6,:bucket_days_to_6, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b6_inv,';
    l_inv_sel3 := l_inv_sel3 || 'app.segment1 company_inv,';
    l_inv_sel3 := l_inv_sel3 || lp_query_show_bill || ' cons_billing_number, ';
    l_inv_sel3 := l_inv_sel3 || ' initcap(:lp_payment_meaning)';
    l_inv_sel3 := l_inv_sel3 || ' from  hz_cust_accounts cust_acct, ' || 'hz_parties party, ' || 'ar_payment_schedules ps,';
    l_inv_sel3 := l_inv_sel3 || lp_table_show_bill;
    l_inv_sel3 := l_inv_sel3 || lp_agr_from3;
    l_inv_sel3 :=    l_inv_sel3
                  || ' hz_cust_site_uses site, '
                  || 'hz_cust_acct_sites acct_site, '
                  || 'hz_party_sites party_site, '
                  || 'hz_locations loc, ';

    if (    pg_in_customer_name_low is null
        and pg_in_customer_name_high is null
        and pg_in_customer_num_low is null
        and pg_in_customer_num_high is null) then
      l_inv_sel3 :=    l_inv_sel3
                    || '(Select '
                    || lp_acct_flex_bal_seg
                    || ' segment1, '
                    || lp_accounting_flexfield
                    || ' segments, '
                    || 'c.code_combination_id code_combination_id, '
                    || 'ps.payment_schedule_id payment_schedule_id, '
                    || 'decode(app.applied_payment_schedule_id,   -4,   ''CLAIM'',   ps.class) class, '
                    || 'app.acctd_amount_applied_from acctd_amount, '
                    || 'app.amount_applied amount, '
                    || 'app.status status ';
    else
      l_inv_sel3 :=    l_inv_sel3
                    || '(Select /*+ index ( app AR_RECEIVABLE_APPLICATIONS_N1 ) */'
                    || lp_acct_flex_bal_seg
                    || ' segment1, '
                    || lp_accounting_flexfield
                    || ' segments, '
                    || 'c.code_combination_id code_combination_id, '
                    || 'ps.payment_schedule_id payment_schedule_id, '
                    || 'decode(app.applied_payment_schedule_id,   -4,   ''CLAIM'',   ps.class) class, '
                    || 'app.acctd_amount_applied_from acctd_amount, '
                    || 'app.amount_applied amount, '
                    || 'app.status status ';
    end if;

    l_inv_sel3 :=    l_inv_sel3
                  || 'FROM ar_receivable_applications app, '
                  || 'gl_code_combinations c, '
                  || 'ar_payment_schedules ps ';
    l_inv_sel3 :=    l_inv_sel3
                  || ' where    app.gl_date <= :as_of_date '
                  || 'and upper(RTRIM(RPAD(:p_in_summary_option_low,1)))  = ''I'' '
                  || 'and    ps.org_id = :param_org_id '
                  || 'and    ps.cash_receipt_id = app.cash_receipt_id '
                  || 'and    app.code_combination_id = c.code_combination_id '
                  || 'and    app.status in ( ''ACC'', ''UNAPP'', ''UNID'',''OTHER ACC'') '
                  || 'and    nvl(app.confirmed_flag, ''Y'') = ''Y''';
    l_inv_sel3 :=    l_inv_sel3
                  || 'and    ps.gl_date_closed  > :as_of_date '
                  || 'and    ((app.reversal_gl_date is not null AND '
                  || 'ps.gl_date <= :as_of_date) '
                  || 'OR '
                  || 'app.reversal_gl_date is null ) '
                  || 'and    decode(upper(:p_in_currency), NULL, ps.invoice_currency_code, '
                  || 'upper(:p_in_currency)) = ps.invoice_currency_code '
                  || 'and    nvl( ps.receipt_confirmed_flag, ''Y'' ) = ''Y'' ';

    if (pg_rep_type = 'ARXAGF') then
      l_inv_sel3 := l_inv_sel3 || 'AND app.posting_control_id <> -3 ' || 'AND app.event_id IS NULL';
    end if;

    l_inv_sel3 := l_inv_sel3 || lp_bal_low;
    l_inv_sel3 := l_inv_sel3 || lp_bal_high;
    l_inv_sel3 := l_inv_sel3 || p_org_where_ps;
    l_inv_sel3 := l_inv_sel3 || p_org_where_app;

    if (pg_rep_type = 'ARXAGF') then
      if (    pg_in_customer_name_low is null
          and pg_in_customer_name_high is null
          and pg_in_customer_num_low is null
          and pg_in_customer_num_high is null) then
        l_inv_sel3 :=    l_inv_sel3
                      || 'UNION ALL '
                      || 'SELECT '
                      || lp_acct_flex_bal_seg
                      || ', '
                      || lp_accounting_flexfield
                      || ' ,'
                      || 'c.code_combination_id, '
                      || 'ps.payment_schedule_id, '
                      || 'decode(ae.accounting_class_code, ''UNAPP'', ps.class, decode(app1.applied_payment_schedule_id,   -4,   ''CLAIM'',   ps.class)) class, '
                      || 'nvl(lk.UNROUNDED_ACCOUNTED_CR, 0) - nvl(lk.UNROUNDED_ACCOUNTED_DR, 0), '
                      || 'nvl(lk.UNROUNDED_ENTERED_CR, 0) - nvl(lk.UNROUNDED_ENTERED_DR,0), '
                      || 'decode(ae.accounting_class_code, ''ACC'', ''ACC'', ''UNID'', ''UNID'', ''UNAPP'', ''UNAPP'', decode(app1.status, ''OTHER ACC'', ''OTHER ACC'', ae.accounting_class_code)) status '
                      || 'FROM ar_payment_schedules ps, '
                      || 'gl_code_combinations c, '
                      || 'xla_distribution_links lk, '
                      || 'xla_ae_lines ae, '
                      || 'xla_ae_headers aeh, '
                      || 'ar_distributions dist, '
                      || '(Select app.cash_receipt_id cash_receipt_id, '
                      || 'app.receivable_application_id source_id, '
                      || 'app.reversal_gl_date reversal_gl_date, '
                      || 'app.set_of_books_id set_of_books_id, '
                      || 'app.applied_payment_schedule_id applied_payment_schedule_id, '
                      || 'app.status status, '
                      || '''RA'' source_table '
                      || 'FROM ar_receivable_applications app '
                      || 'WHERE app.gl_date <= :as_of_date '
                      || 'AND app.posting_control_id <> -3 '
                      || 'AND app.event_id IS NOT NULL '
                      || 'AND nvl(app.confirmed_flag, ''Y'') = ''Y'' ';
      else
        l_inv_sel3 :=    l_inv_sel3
                      || 'UNION ALL '
                      || 'SELECT  /*+ push_pred(app1) use_nl(ps, app1) */'
                      || lp_acct_flex_bal_seg
                      || ', '
                      || lp_accounting_flexfield
                      || ' ,'
                      || 'c.code_combination_id, '
                      || 'ps.payment_schedule_id, '
                      || 'decode(ae.accounting_class_code, ''UNAPP'', ps.class, decode(app1.applied_payment_schedule_id,   -4,   ''CLAIM'',   ps.class)) class, '
                      || 'nvl(lk.UNROUNDED_ACCOUNTED_CR, 0) - nvl(lk.UNROUNDED_ACCOUNTED_DR, 0), '
                      || 'nvl(lk.UNROUNDED_ENTERED_CR, 0) - nvl(lk.UNROUNDED_ENTERED_DR,0), '
                      || 'decode(ae.accounting_class_code, ''ACC'', ''ACC'', ''UNID'', ''UNID'', ''UNAPP'', ''UNAPP'', decode(app1.status, ''OTHER ACC'', ''OTHER ACC'', ae.accounting_class_code)) status '
                      || 'FROM ar_payment_schedules ps, '
                      || 'gl_code_combinations c, '
                      || 'xla_distribution_links lk, '
                      || 'xla_ae_lines ae, '
                      || 'xla_ae_headers aeh, '
                      || 'ar_distributions dist, '
                      || '(Select app.cash_receipt_id cash_receipt_id, '
                      || 'app.receivable_application_id source_id, '
                      || 'app.reversal_gl_date reversal_gl_date, '
                      || 'app.set_of_books_id set_of_books_id, '
                      || 'app.applied_payment_schedule_id applied_payment_schedule_id, '
                      || 'app.status status, '
                      || '''RA'' source_table '
                      || 'FROM ar_receivable_applications app '
                      || 'WHERE app.gl_date <= :as_of_date '
                      || 'AND app.posting_control_id <> -3 '
                      || 'AND app.event_id IS NOT NULL '
                      || 'AND nvl(app.confirmed_flag, ''Y'') = ''Y'' ';
      end if;

      l_inv_sel3 := l_inv_sel3 || p_org_where_app;
      l_inv_sel3 :=    l_inv_sel3
                    || 'UNION ALL '
                    || 'Select crh.cash_receipt_id, '
                    || 'crh.cash_receipt_history_id, '
                    || 'crh.reversal_gl_date, '
                    || 'cr.set_of_books_id, '
                    || 'NULL, '
                    || 'NULL, '
                    || '''CRH'' source_table '
                    || 'FROM  ar_cash_receipt_history crh, '
                    || 'ar_cash_receipts cr '
                    || 'WHERE crh.gl_date <= :as_of_date '
                    || 'AND   crh.posting_control_id <> -3 '
                    || 'AND   event_id IS NOT NULL '
                    || 'AND   cr.cash_receipt_id = crh.cash_receipt_id '
                    || 'AND   NVL(cr.confirmed_flag, ''Y'') = ''Y'' ';
      l_inv_sel3 := l_inv_sel3 || p_org_where_crh;
      l_inv_sel3 :=    l_inv_sel3
                    || ') app1 '
                    || 'WHERE UPPER(RTRIM(rpad(:p_in_summary_option_low, 1))) = ''I'' '
                    || 'AND ps.org_id = :param_org_id '
                    || 'AND ps.cash_receipt_id = app1.cash_receipt_id '
                    || 'AND dist.source_id = app1.source_id '
                    || 'AND dist.source_table = app1.source_table '
                    || 'AND dist.line_id = lk.source_distribution_id_num_1 '
                    || 'AND lk.application_id = 222 '
                    || 'AND ae.application_id = 222 '
                    || 'AND lk.source_distribution_type = ''AR_DISTRIBUTIONS_ALL'' '
                    || 'AND lk.ae_header_id = ae.ae_header_id '
                    || 'AND lk.ae_line_num = ae.ae_line_num '
                    || 'AND aeh.ae_header_id = ae.ae_header_id '
                    || 'AND aeh.application_id = 222 '
                    || 'AND aeh.event_type_code <> ''MANUAL'' '
                    || 'AND (ae.accounting_class_code IN (''ACC'', ''UNID'', ''UNAPP'') OR app1.status = ''OTHER ACC'') '
                    || 'AND ae.accounting_date <= :as_of_date '
                    || 'AND ae.ledger_id = app1.set_of_books_id '
                    || 'AND ae.code_combination_id = c.code_combination_id '
                    || 'AND ps.gl_date_closed > :as_of_date '
                    || 'AND((app1.reversal_gl_date IS NOT NULL '
                    || 'AND ps.gl_date <= :as_of_date) OR app1.reversal_gl_date IS NULL) '
                    || 'AND decode(UPPER(:p_in_currency), NULL, ps.invoice_currency_code, UPPER(:p_in_currency)) = ps.invoice_currency_code '
                    || 'AND nvl(ps.receipt_confirmed_flag, ''Y'') = ''Y'' ';
      l_inv_sel3 := l_inv_sel3 || lp_bal_low;
      l_inv_sel3 := l_inv_sel3 || lp_bal_high;
      l_inv_sel3 := l_inv_sel3 || p_org_where_ps;
    end if;

    l_inv_sel3 := l_inv_sel3 || ' ) app ';
    l_inv_sel3 := l_inv_sel3 || lp_agl_from1;
    l_inv_sel3 :=    l_inv_sel3
                  || 'WHERE ps.payment_schedule_id = app.payment_schedule_id '
                  || 'AND ps.customer_id = cust_acct.cust_account_id(+) '
                  || 'AND cust_acct.party_id = party.party_id(+) '
                  || 'AND ps.customer_site_use_id = site.site_use_id(+) '
                  || 'AND site.cust_acct_site_id = acct_site.cust_acct_site_id(+) '
                  || 'AND acct_site.party_site_id = party_site.party_site_id(+) '
                  || 'AND loc.location_id(+) = party_site.location_id ';
    l_inv_sel3 := l_inv_sel3 || lp_customer_name_low;
    l_inv_sel3 := l_inv_sel3 || lp_customer_name_high;
    l_inv_sel3 := l_inv_sel3 || lp_customer_num_low;
    l_inv_sel3 := l_inv_sel3 || lp_customer_num_high;
    l_inv_sel3 := l_inv_sel3 || lp_where_show_bill;
    l_inv_sel3 := l_inv_sel3 || lp_agr_where4;
    l_inv_sel3 := l_inv_sel3 || lp_agr_where5;
    l_inv_sel3 := l_inv_sel3 || lp_agl_where1;
    l_inv_sel3 := l_inv_sel3 || lp_agr_where3;
    l_inv_sel3 := l_inv_sel3 || p_org_where_addr;
    l_inv_sel3 := l_inv_sel3 || lp_agr_where_org1;
    l_inv_sel3 := l_inv_sel3 || ' GROUP BY party.party_name, ' || 'cust_acct.account_number, ' || 'site.site_use_id, ';

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel3 := l_inv_sel3 || 'decode(upper(:p_in_sortoption),''CUSTOMER'',NULL,' || 'initcap(:lp_payment_meaning)),';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel3 := l_inv_sel3 || lp_agl_name;
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel3 := l_inv_sel3 || lp_agr_name;
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel3 := l_inv_sel3 || 'app.segments,';
    end if;

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel3 := l_inv_sel3 || '-999,';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel3 := l_inv_sel3 || lp_agl_id;
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel3 := l_inv_sel3 || lp_agr_id;
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel3 := l_inv_sel3 || 'app.code_combination_id,';
    end if;

    l_inv_sel3 :=    l_inv_sel3
                  || '   loc.state, '
                  || 'loc.city, '
                  || 'acct_site.cust_acct_site_id, '
                  || 'cust_acct.cust_account_id, '
                  || 'ps.payment_schedule_id, '
				  || 'ps.trx_date,'   --Added for case #6747
                  || 'ps.due_date, '
                  || 'ps.trx_number, '
                  || 'ps.amount_adjusted, '
                  || 'ps.amount_applied, '
                  || 'ps.amount_credited, '
                  || 'ps.gl_date, '
                  || 'ps.amount_in_dispute, '
                  || 'ps.amount_adjusted_pending, '
                  || 'ps.invoice_currency_code, '
                  || 'ps.exchange_rate, '
                  || 'app.class,';
    l_inv_sel3 := l_inv_sel3 || 'app.segment1,';
    l_inv_sel3 := l_inv_sel3 || ' decode( app.status, ''UNID'', ''UNID'',''OTHER ACC'',''OTHER ACC'',
                 ''UNAPP''),';
    l_inv_sel3 := l_inv_sel3 || lp_query_show_bill || ',';
    l_inv_sel3 := l_inv_sel3 || 'initcap(:lp_payment_meaning)';
    --   :common_query_inv2 := l_inv_sel3;
    -----------------------------------------------------------------
    -- BUILD SELECT #4
    -----------------------------------------------------------------
    l_inv_sel4 := 'select substrb(nvl(party.party_name, :p_short_unid_phrase),1,50) cust_name_inv, '
                  || 'cust_acct.account_number cust_no_inv,';

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel4 := l_inv_sel4 || 'decode(upper(:p_in_sortoption),''CUSTOMER'',NULL, ' || 'initcap(:lp_risk_meaning)) ,';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel4 := l_inv_sel4 || lp_agl_name;
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel4 := l_inv_sel4 || lp_agr_name;
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel4 := l_inv_sel4 || lp_accounting_flexfield || ',';
    end if;

    l_inv_sel4 := l_inv_sel4 || 'initcap(:lp_risk_meaning),';

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel4 := l_inv_sel4 || '-999,';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel4 := l_inv_sel4 || lp_agl_id;
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel4 := l_inv_sel4 || lp_agr_id;
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel4 := l_inv_sel4 || 'c.code_combination_id,';
    end if;

    l_inv_sel4 :=    l_inv_sel4
                  || ' site.site_use_id, '
                  || 'loc.state cust_state_inv, '
                  || 'loc.city cust_city_inv, '
                  || 'decode(:format_detailed,NULL,-1,acct_site.cust_acct_site_id) addr_id_inv, '
                  || 'nvl(cust_acct.cust_account_id, -999) cust_id_inv, '
                  || 'ps.payment_schedule_id, '
                  || 'initcap(:lp_risk_meaning), '
				  || 'ps.trx_date,'    --Added for case #6747
                  || 'ps.due_date, '
                  || 'decode( :c_convert_flag, ''Y'', crh.acctd_amount, crh.amount), '
                  || 'ps.trx_number, '
                  || 'ceil(:as_of_date - ps.due_date), '
                  || 'ps.amount_adjusted, '
                  || 'ps.amount_applied, '
                  || 'ps.amount_credited, '
                  || 'crh.gl_date, '
                  || 'decode(ps.invoice_currency_code, :functional_currency, NULL, '
                  || 'decode(crh.exchange_rate, NULL, ''*'', NULL)), '
                  || 'nvl(crh.exchange_rate, 1),';
    l_inv_sel4 :=    l_inv_sel4
                  || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0, '
                  || '0,0,:bucket_days_from_0,:bucket_days_to_0, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b0_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_1, '
                  || '0,0,:bucket_days_from_1,:bucket_days_to_1, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b1_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_2, '
                  || '0,0,:bucket_days_from_2,:bucket_days_to_2, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b2_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_3, '
                  || '0,0,:bucket_days_from_3,:bucket_days_to_3, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b3_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_4, '
                  || '0,0,:bucket_days_from_4,:bucket_days_to_4, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b4_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_5, '
                  || '0,0,:bucket_days_from_5,:bucket_days_to_5, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b5_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_6, '
                  || '0,0,:bucket_days_from_6,:bucket_days_to_6, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b6_inv,';
    l_inv_sel4 := l_inv_sel4 || lp_acct_flex_bal_seg || ' company_inv,';
    l_inv_sel4 := l_inv_sel4 || lp_query_show_bill || ' cons_billing_number, ';
    l_inv_sel4 := l_inv_sel4 || 'initcap(:lp_risk_meaning)';
    l_inv_sel4 := l_inv_sel4 || ' from   hz_cust_accounts cust_acct, ' || 'hz_parties party, ' || 'ar_payment_schedules ps,';
    l_inv_sel4 := l_inv_sel4 || lp_table_show_bill;
    l_inv_sel4 :=    l_inv_sel4
                  || '   hz_cust_site_uses site, '
                  || 'hz_cust_acct_sites acct_site, '
                  || 'hz_party_sites party_site, '
                  || 'hz_locations loc, '
                  || 'ar_cash_receipts cr, '
                  || 'ar_cash_receipt_history crh, '
                  || 'gl_code_combinations c ';

    if (pg_rep_type = 'ARXAGF') then
      l_inv_sel4 :=    l_inv_sel4
                    || ', xla_distribution_links lk, '
                    || 'xla_ae_lines ae, '
                    || 'xla_ae_headers aeh, '
                    || 'ar_distributions dist ';
    end if;

    l_inv_sel4 := l_inv_sel4 || lp_agl_from1;
    l_inv_sel4 := l_inv_sel4 || lp_agr_from1;
    l_inv_sel4 :=    l_inv_sel4
                  || ' where  crh.gl_date <= :as_of_date '
                  || 'and upper(RTRIM(RPAD(:p_in_summary_option_low,1)))  = ''I'' '
                  || 'and upper(:p_risk_option) != ''NONE'' '
                  || 'and ps.customer_id = cust_acct.cust_account_id(+) '
                  || 'and cust_acct.party_id = party.party_id(+) '
                  || 'and ps.cash_receipt_id = cr.cash_receipt_id '
                  || 'and ps.org_id = :param_org_id '
                  || 'and cr.cash_receipt_id = crh.cash_receipt_id ';

    if (pg_rep_type = 'ARXAGF') then
      l_inv_sel4 :=    l_inv_sel4
                    || 'and dist.source_id = crh.cash_receipt_history_id '
                    || 'and dist.source_table = ''CRH'' '
                    || 'and dist.line_id = lk.source_distribution_id_num_1(+) '
                    || 'and lk.application_id(+) = 222 '
                    || 'and ae.application_id(+) = 222 '
                    || 'and lk.source_distribution_type(+) = ''AR_DISTRIBUTIONS_ALL'' '
                    || 'and lk.ae_header_id = ae.ae_header_id(+) '
                    || 'and lk.ae_line_num = ae.ae_line_num(+) '
                    || 'and ae.ae_header_id = aeh.ae_header_id(+) '
                    || 'and aeh.application_id(+) = 222 '
                    || 'and aeh.event_type_code(+) <> ''MANUAL'' '
                    || 'and decode(ae.ledger_id, '''',decode(crh.posting_control_id, -3, -999999, crh.account_code_combination_id), cr.set_of_books_id, ae.code_combination_id, -999999) = c.code_combination_id '
                    || 'and NVL(ae.accounting_class_code, dist.source_type) = dist.source_type '
                    || 'and decode(crh.status, ''CONFIRMED'', ''CONFIRMATION'', ''REMITTED'', ''REMITTANCE'', crh.status) = dist.source_type ';
    else
      l_inv_sel4 := l_inv_sel4 || 'and crh.account_code_combination_id = c.code_combination_id ';
    end if;

    l_inv_sel4 :=    l_inv_sel4
                  || 'and ps.customer_site_use_id = site.site_use_id(+) '
                  || 'and site.cust_acct_site_id = acct_site.cust_acct_site_id(+) '
                  || 'and acct_site.party_site_id = party_site.party_site_id(+) '
                  || 'and loc.location_id(+) = party_site.location_id '
                  || 'and decode(upper(:p_in_currency), NULL, ps.invoice_currency_code, '
                  || 'upper(:p_in_currency)) = ps.invoice_currency_code '
                  || 'and (crh.current_record_flag = ''Y'' '
                  || 'or crh.reversal_gl_date > :as_of_date ) '
                  || 'and crh.status not in (decode(crh.factor_flag, '
                  || ' ''Y'',''RISK_ELIMINATED'', '
                  || ' ''N'',''CLEARED''), '
                  || ' ''REVERSED'') '
                  || 'and not exists (select ''x''  '
                  || 'from ar_receivable_applications ra '
                  || 'where ra.cash_receipt_id = cr.cash_receipt_id '
                  || 'and ra.status = ''ACTIVITY'' '
                  || 'and applied_payment_schedule_id = -2) '
                  || 'and cr.cash_receipt_id not in '
                  || '(select ps.reversed_cash_receipt_id  '
                  || 'from ar_payment_schedules ps '
                  || ' where ps.reversed_cash_receipt_id=cr.cash_receipt_id '
                  || 'and ps.class=''DM'' '
                  || 'and ps.gl_date<= (:as_of_date)) ';
    l_inv_sel4 := l_inv_sel4 || lp_customer_name_low;
    l_inv_sel4 := l_inv_sel4 || lp_customer_name_high;
    l_inv_sel4 := l_inv_sel4 || lp_customer_num_low;
    l_inv_sel4 := l_inv_sel4 || lp_customer_num_high;
    l_inv_sel4 := l_inv_sel4 || lp_bal_low;
    l_inv_sel4 := l_inv_sel4 || lp_bal_high;
    l_inv_sel4 := l_inv_sel4 || lp_where_show_bill;
    l_inv_sel4 := l_inv_sel4 || lp_agr_where4;
    l_inv_sel4 := l_inv_sel4 || lp_agr_where5;
    l_inv_sel4 := l_inv_sel4 || lp_agl_where1;
    l_inv_sel4 := l_inv_sel4 || lp_agr_where3;
    l_inv_sel4 := l_inv_sel4 || p_org_where_ps;
    l_inv_sel4 := l_inv_sel4 || p_org_where_crh;
    l_inv_sel4 := l_inv_sel4 || p_org_where_cr;
    l_inv_sel4 := l_inv_sel4 || p_org_where_addr;
    l_inv_sel4 := l_inv_sel4 || lp_agr_where_org1;
    --   :common_query_inv3 := l_inv_sel4;
    -----------------------------------------------------------------
    -- BUILD SELECT #5
    -----------------------------------------------------------------
    /* Bug 4252491 : fyi, the code to back out applications/adjustments done *after* the
      as of date is in COMP_AMT_DUE_REM_INV formula, we could not put the logic into
      this function, because we were running into error
      ORA-06505: PL/SQL: variable requires more than 32767 bytes of contiguous
   */
    l_inv_sel5 := 'select substrb(party.party_name,1,50) cust_name_inv, ' || 'cust_acct.account_number cust_no_inv,';

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel5 :=    l_inv_sel5
                    || 'decode(upper(:p_in_sortoption),''CUSTOMER'',NULL,  '
                    || 'arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id))';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel5 := l_inv_sel5 || 'col.name';
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel5 := l_inv_sel5 || 'extns.resource_name';
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel5 := l_inv_sel5 || lp_accounting_flexfield;
    end if;

    l_inv_sel5 := l_inv_sel5 || ' sort_field1_inv,';
    l_inv_sel5 := l_inv_sel5 || ' arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id) sort_field2_inv,';

    if (pg_rep_type = 'ARXAGS') then
      l_inv_sel5 := l_inv_sel5 || 'decode(upper(:p_in_sortoption),''CUSTOMER'',-999,ps.cust_trx_type_id)';
    elsif (pg_rep_type = 'ARXAGL') then
      l_inv_sel5 := l_inv_sel5 || 'col.collector_id';
    elsif (pg_rep_type = 'ARXAGR') then
      l_inv_sel5 := l_inv_sel5 || 'nvl(sales.salesrep_id, -3)';
    elsif (pg_rep_type = 'ARXAGF') then
      l_inv_sel5 := l_inv_sel5 || 'c.code_combination_id';
    end if;

    l_inv_sel5 := l_inv_sel5 || ' inv_tid_inv, ';
    l_inv_sel5 :=    l_inv_sel5
                  || '      site.site_use_id contact_site_id_inv, '
                  || 'loc.state cust_state_inv, '
                  || 'loc.city cust_city_inv, '
                  || 'decode(:format_detailed,NULL,-1,acct_site.cust_acct_site_id) addr_id_inv, '
                  || 'nvl(cust_acct.cust_account_id,-999) cust_id_inv, '
                  || 'ps.payment_schedule_id payment_sched_id_inv, '
                  || 'ps.class class_inv, '
				  || 'ps.trx_date transaction_date_inv,'   --Added for case #6747
                  || 'ps.due_date  due_date_inv, '
                  || 'decode( :c_convert_flag, ''Y'', '
                  || 'ps.acctd_amount_due_remaining, '
                  || 'ps.amount_due_remaining) amt_due_remaining_inv, '
                  || 'ps.trx_number invnum, '
                  || 'ceil(:as_of_date - ps.due_date) days_past_due, '
                  || 'ps.amount_adjusted amount_adjusted_inv, '
                  || 'ps.amount_applied amount_applied_inv, '
                  || 'ps.amount_credited amount_credited_inv, '
                  || 'ps.gl_date gl_date_inv, '
                  || 'decode(ps.invoice_currency_code, :functional_currency, NULL, '
                  || 'decode(ps.exchange_rate, NULL, ''*'', NULL)) data_converted_inv, '
                  || 'nvl(ps.exchange_rate, 1) ps_exchange_rate_inv,';
    l_inv_sel5 :=    l_inv_sel5
                  || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_0,:bucket_days_to_0, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b0_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_1, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_1,:bucket_days_to_1, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b1_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_2, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_2,:bucket_days_to_2, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b2_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_3, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_3,:bucket_days_to_3, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b3_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_4, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_4,:bucket_days_to_4, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b4_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_5, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_5,:bucket_days_to_5, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b5_inv, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_6, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_6,:bucket_days_to_6, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b6_inv,';
    l_inv_sel5 := l_inv_sel5 || lp_acct_flex_bal_seg || ' company_inv,';
    l_inv_sel5 := l_inv_sel5 || lp_query_show_bill || ' cons_billing_number, ';
    l_inv_sel5 := l_inv_sel5 || ' arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id) invoice_type_inv 
';
    l_inv_sel5 := l_inv_sel5 || ' from  hz_cust_accounts cust_acct, ' || 'hz_parties party, ' || 'ar_payment_schedules ps,';
    l_inv_sel5 := l_inv_sel5 || lp_table_show_bill;
    l_inv_sel5 := l_inv_sel5 || lp_agr_from3;
    l_inv_sel5 :=    l_inv_sel5
                  || '      hz_cust_site_uses site, '
                  || 'hz_cust_acct_sites acct_site, '
                  || 'hz_party_sites party_site, '
                  || 'hz_locations loc, '
                  || 'ar_transaction_history th, ';

    /*Aging Reports pick those transactions
       as well which are not yet accounted. Only Aging 7 bucket by Account Report
       will include the transactions either Accounted or for which POST TO GL flag
       is set to NO.] */
    if pg_rep_type = 'ARXAGF' then
      l_inv_sel5 :=    l_inv_sel5
                    || '   (SELECT th1.customer_trx_id, '
                    || 'th1.transaction_history_id, '
                    || 'ae.code_combination_id '
                    || 'FROM ar_distributions ard, '
                    || 'xla_distribution_links lk, '
                    || 'xla_ae_lines ae, '
                    || 'ar_transaction_history th1, '
                    || 'ra_customer_trx trx, '
                    || 'xla_ae_headers hd '
                    || 'WHERE th1.event_id IS NOT NULL '
                    || 'AND ard.source_id = th1.transaction_history_id '
                    || 'AND ard.source_table = ''TH'' '
                    || 'AND ard.source_table_secondary IS NULL '
                    || 'AND ard.line_id = lk.source_distribution_id_num_1 '
                    || 'AND lk.application_id = 222 '
                    || 'AND lk.source_distribution_type = ''AR_DISTRIBUTIONS_ALL'' '
                    || 'AND ae.application_id = 222 '
                    || 'AND lk.ae_header_id = ae.ae_header_id '
                    || 'AND lk.ae_line_num = ae.ae_line_num '
                    || 'AND lk.ae_header_id = hd.ae_header_id '
                    || 'AND hd.application_id  = 222 '
                    || 'AND hd.event_type_code <> ''MANUAL'' '
                    || 'AND th1.customer_trx_id = trx.customer_trx_id '
                    || 'AND trx.set_of_books_id = hd.ledger_id '
                    || 'AND lk.unrounded_entered_dr  IS NOT NULL '
                    || 'AND ae.accounting_class_code IN '
                    || '( ''RECEIVABLE'',''DEFERRED_TAX'',''TAX'', '
                    || '''UNPAID_BR'',''REM_BR'',''FAC_BR'')  '
                    || 'UNION ALL '
                    || 'SELECT th2.customer_trx_id, '
                    || 'th2.transaction_history_id, '
                    || 'ard.code_combination_id '
                    || 'FROM ar_distributions ard, '
                    || 'ar_transaction_history th2 '
                    || 'WHERE th2.event_id IS NULL '
                    || 'AND th2.posting_control_id <> -3 '
                    || 'AND ard.source_table      = ''TH'' '
                    || 'AND ard.source_id         = th2.transaction_history_id '
                    || 'AND ard.amount_dr         IS NOT NULL '
                    || 'AND ard.source_table_secondary IS NULL) dist, ';
    else
      l_inv_sel5 := l_inv_sel5 || 'ar_distributions   dist, ';
    end if;

    l_inv_sel5 := l_inv_sel5 || 'gl_code_combinations c ';
    --end if;
    l_inv_sel5 := l_inv_sel5 || lp_agr_from2;
    l_inv_sel5 := l_inv_sel5 || lp_agl_from2;
    l_inv_sel5 := l_inv_sel5 || lp_agl_from1;
    l_inv_sel5 :=    l_inv_sel5
                  || ' where  ps.gl_date <= :as_of_date '
                  || 'and   upper(RTRIM(RPAD(:p_in_summary_option_low,1)) ) = ''I'' '
                  || 'and    ps.customer_site_use_id = site.site_use_id '
                  || 'and   ps.org_id = :param_org_id '
                  || 'and    site.cust_acct_site_id = acct_site.cust_acct_site_id '
                  || 'and   acct_site.party_site_id  = party_site.party_site_id '
                  || 'and   loc.location_id = party_site.location_id '
                  || 'and   ps.gl_date_closed  > :as_of_date '
                  || 'and   ps.class = ''BR'' '
                  || 'and   decode(upper(:p_in_currency),NULL, ps.invoice_currency_code, '
                  || 'upper(:p_in_currency)) = ps.invoice_currency_code '
                  || 'and   cust_acct.party_id = party.party_id ';

    if pg_rep_type = 'ARXAGF' then
      l_inv_sel5 :=    l_inv_sel5
                    || ' and th.transaction_history_id IN '
                    || '(SELECT MAX(th1.transaction_history_id) '
                    || 'FROM ar_transaction_history th1, '
                    || 'ra_customer_trx trx, '
                    || 'ar_distributions ard, '
                    || 'xla_distribution_links lk, '
                    || 'xla_ae_lines ae, '
                    || 'xla_ae_headers hd '
                    || 'WHERE th1.customer_trx_id = ps.customer_trx_id '
                    || 'AND th1.customer_trx_id = trx.customer_trx_id '
                    || 'AND th1.transaction_history_id = ard.source_id '
                    || 'AND ard.source_table = ''TH'' '
                    || 'AND ard.source_table_secondary IS NULL '
                    || 'AND ard.line_id = lk.source_distribution_id_num_1(+) '
                    || 'AND lk.application_id(+) = 222 '
                    || 'AND lk.source_distribution_type(+) = ''AR_DISTRIBUTIONS_ALL'' '
                    || 'AND lk.ae_header_id = ae.ae_header_id(+) '
                    || 'AND lk.ae_line_num = ae.ae_line_num(+) '
                    || 'AND ae.application_id(+) = 222 '
                    || 'AND lk.ae_header_id = hd.ae_header_id(+) '
                    || 'AND hd.application_id(+)  = 222 '
                    || 'AND hd.event_type_code(+) <> ''MANUAL'' '
                    || 'AND trx.set_of_books_id = DECODE(hd.ledger_id,NULL,trx.set_of_books_id,hd.ledger_id)) '
                    || 'and dist.customer_trx_id        = ps.customer_trx_id '
                    || 'and th.transaction_history_id   = dist.transaction_history_id '
                    || 'and c.code_combination_id       = dist.code_combination_id ';
    else
      l_inv_sel5 :=    l_inv_sel5
                    || 'and   th.transaction_history_id =  '
                    || '(select max(transaction_history_id) '
                    || 'from ar_transaction_history th2, '
                    || 'ar_distributions  dist2 '
                    || 'where th2.transaction_history_id = dist2.source_id '
                    || 'and  dist2.source_table = ''TH'' '
                    || 'and  th2.gl_date <= :as_of_date '
                    || 'and  dist2.amount_dr is not null '
                    || 'and  th2.customer_trx_id = ps.customer_trx_id) '
                    || 'and   th.transaction_history_id = dist.source_id '
                    || 'and   dist.source_table = ''TH'' '
                    || 'and   dist.amount_dr is not null '
                    || 'and   dist.source_table_secondary is NULL '
                    || 'and   dist.code_combination_id = c.code_combination_id ';
    end if;

    l_inv_sel5 := l_inv_sel5 || lp_customer_name_low;
    l_inv_sel5 := l_inv_sel5 || lp_customer_name_high;
    l_inv_sel5 := l_inv_sel5 || lp_customer_num_low;
    l_inv_sel5 := l_inv_sel5 || lp_customer_num_high;
    l_inv_sel5 := l_inv_sel5 || lp_invoice_type_low;
    l_inv_sel5 := l_inv_sel5 || lp_invoice_type_high;
    l_inv_sel5 := l_inv_sel5 || lp_bal_low;
    l_inv_sel5 := l_inv_sel5 || lp_bal_high;
    l_inv_sel5 := l_inv_sel5 || lp_where_show_bill;
    l_inv_sel5 := l_inv_sel5 || lp_agfs_where4;
    l_inv_sel5 := l_inv_sel5 || lp_aglr_where1;
    l_inv_sel5 := l_inv_sel5 || lp_aglr_where6;
    l_inv_sel5 := l_inv_sel5 || lp_aglr_where8;
    l_inv_sel5 := l_inv_sel5 || lp_agl_where1;
    l_inv_sel5 := l_inv_sel5 || lp_agr_where1;
    l_inv_sel5 := l_inv_sel5 || lp_agr_where4;
    l_inv_sel5 := l_inv_sel5 || p_org_where_ps;
    l_inv_sel5 := l_inv_sel5 || p_org_where_addr;
    l_inv_sel5 := l_inv_sel5 || lp_agl_where_org2;
    l_inv_sel5 := l_inv_sel5 || lp_agr_where_org1;
    l_inv_sel5 := l_inv_sel5 || lp_agr_where_org2;
    l_inv_sel5 := l_inv_sel5 || ' order by 30, 3, 1, 2, 9, 15, 13, 14 desc';
  --:common_query_inv4 := l_inv_sel5;
  --return (l_inv_sel);
  end;

  function build_customer_select
    return clob is
  begin
    ------------------------------------------------------------
    -- BUILD FIRST SELECT STATEMENT - OPEN TRX - l_cus_sel1
    ------------------------------------------------------------
    l_cus_sel1 := 'select     
         substrb(party.party_name,1,50) short_cust_name,
         cust_acct.cust_account_id cust_id,
         cust_acct.account_number cust_no,';

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel1 := l_cus_sel1 || 'decode(upper(:sort_option),''T'',
     arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id), NULL)';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel1 := l_cus_sel1 || 'col.name';
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel1 := l_cus_sel1 || ' extns.resource_name ';
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel1 := l_cus_sel1 || 'decode(types.post_to_gl, ''Y'', ';
      l_cus_sel1 := l_cus_sel1 || lp_accounting_flexfield;
      l_cus_sel1 := l_cus_sel1 || ', NULL)';
    end if;

    l_cus_sel1 := l_cus_sel1 || ' sort_field1,';

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel1 := l_cus_sel1 || 'arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id)';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel1 := l_cus_sel1 || 'to_char(col.collector_id)';
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel1 := l_cus_sel1 || 'to_char(nvl(sales.salesrep_id,-3)) ';
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel1 := l_cus_sel1 || 'to_char(c.code_combination_id)';
    end if;
/* ps.trx_date transaction_date  Added for case #6747 */
    l_cus_sel1 := l_cus_sel1 || ' sort_field2, ';
    l_cus_sel1 := l_cus_sel1 || '    ps.payment_schedule_id payment_sched_id,
         ps.class class,
		 ps.trx_date transaction_date,    
         ps.due_date due_date,
         ps.amt_due_remaining,
         ceil(:as_of_date - ps.due_date) days_past_due ,
         ps.amount_adjusted amount_adjusted,
         ps.amount_applied amount_applied,
         ps.amount_credited amount_credited,
         ps.gl_date gl_date,
         decode(ps.invoice_currency_code, :functional_currency, NULL,
                        decode(ps.exchange_rate, NULL, ''*'', NULL)) data_converted,
         nvl(ps.exchange_rate, 1) ps_exchange_rate,';
    l_cus_sel1 := l_cus_sel1 || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0,
                dh.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_0,:bucket_days_to_0,
                 ps.due_date,:bucket_category,:as_of_date) b0,
      arpt_sql_func_util.bucket_function(:bucket_line_type_1,
                dh.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_1,:bucket_days_to_1,
                 ps.due_date,:bucket_category,:as_of_date) b1,
      arpt_sql_func_util.bucket_function(:bucket_line_type_2,
                dh.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_2,:bucket_days_to_2,
                 ps.due_date,:bucket_category,:as_of_date) b2,
      arpt_sql_func_util.bucket_function(:bucket_line_type_3,
                dh.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_3,:bucket_days_to_3,
                 ps.due_date,:bucket_category,:as_of_date) b3,
      arpt_sql_func_util.bucket_function(:bucket_line_type_4,
                dh.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_4,:bucket_days_to_4,
                 ps.due_date,:bucket_category,:as_of_date) b4,
      arpt_sql_func_util.bucket_function(:bucket_line_type_5,
                dh.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_5,:bucket_days_to_5,
                 ps.due_date,:bucket_category,:as_of_date) b5,
      arpt_sql_func_util.bucket_function(:bucket_line_type_6,
                dh.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_6,:bucket_days_to_6,
                 ps.due_date,:bucket_category,:as_of_date) b6,';
    l_cus_sel1 := l_cus_sel1 || lp_acct_flex_bal_seg || ' bal_segment_value,';

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel1 := l_cus_sel1 || 'decode(upper(:sort_option),to_char(ps.cust_trx_type_id),NULL)';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel1 := l_cus_sel1 || 'col.name';
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel1 := l_cus_sel1 || 'extns.resource_name';
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel1 := l_cus_sel1 || lp_accounting_flexfield;
    end if;
/* a.trx_date,ps.tex_date columns Added for case #6747 */
    l_cus_sel1 := l_cus_sel1 || ' inv_tid,';
    l_cus_sel1 := l_cus_sel1 || ' arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id) invoice_type';
    l_cus_sel1 := l_cus_sel1 || ' from   ';
    l_cus_sel1 := l_cus_sel1 || '(select a.customer_id,
      a.customer_site_use_id ,
      a.customer_trx_id,
      a.payment_schedule_id,
      a.class ,
      sum(a.primary_salesrep_id) primary_salesrep_id,
	  a.trx_date,    
      a.due_date ,
      sum(a.amount_due_remaining) amt_due_remaining,
      a.trx_number,
      a.amount_adjusted,
      a.amount_applied ,
      a.amount_credited ,
      a.amount_adjusted_pending,
      a.gl_date ,
      a.cust_trx_type_id,
      a.org_id,
      a.invoice_currency_code,
      a.exchange_rate
from 
(  select  /*+ LEADING(adj) INDEX(ps ar_payment_schedules_u1) */
      ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.payment_schedule_id,
      ps.class ,
      0 primary_salesrep_id,
	  ps.trx_date,   
      ps.due_date ,
      nvl(sum ( decode( :c_convert_flag, ''Y'',
                      nvl(adj.acctd_amount, 0),
                      adj.amount )
                   ),0) * (-1)  amount_due_remaining,
      ps.trx_number,
      ps.amount_adjusted ,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date ,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code,
      nvl(ps.exchange_rate,1) exchange_rate
   from  ar_payment_schedules ps,
         ar_adjustments adj';

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ', hz_cust_accounts cust_acct';
    end if;

    l_cus_sel1 := l_cus_sel1 || ' where  ps.gl_date <= :as_of_date
     and ps.customer_id > 0
    and  ps.gl_date_closed  > :as_of_date
    and  ps.org_id = :param_org_id 
    and  nvl(upper(:p_in_currency), ps.invoice_currency_code)
            = ps.invoice_currency_code
    and  adj.payment_schedule_id = ps.payment_schedule_id
    and  adj.status = ''A''
    and  ps.org_id = adj.org_id
    and  adj.gl_date > :as_of_date ';
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_low;
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_high;

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ' and ps.customer_id = cust_acct.cust_account_id ';
    end if;
/* ps.trx_date columns Added for case #6747 */
    l_cus_sel1 := l_cus_sel1 || 'group by 
   ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.class ,
	  ps.trx_date,  
      ps.due_date,
      ps.trx_number,
      ps.amount_adjusted ,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date ,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code,
      nvl(ps.exchange_rate,1),
      ps.payment_schedule_id
UNION ALL
   select /*+ LEADING(app) USE_NL(ps) */
      ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.payment_schedule_id,
      ps.class ,
      0 primary_salesrep_id,
	  ps.trx_date,  
      ps.due_date  ,
      nvl(sum ( decode
                   ( :c_convert_flag, ''Y'',
             (decode(ps.class, ''CM'',
                decode ( app.application_type, ''CM'',
                     app.acctd_amount_applied_from,
                                         app.acctd_amount_applied_to
                    ),
                app.acctd_amount_applied_to)+
                       nvl(app.acctd_earned_discount_taken,0) +
                       nvl(app.acctd_unearned_discount_taken,0))
             ,
                     ( app.amount_applied +
                       nvl(app.earned_discount_taken,0) +
                       nvl(app.unearned_discount_taken,0) )
           ) *
           decode
                   ( ps.class, ''CM'',
                      decode(app.application_type, ''CM'', -1, 1), 1 )
                ), 0) amount_due_remaining_inv, 
      ps.trx_number ,
      ps.amount_adjusted,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date gl_date_inv,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code, 
      nvl(ps.exchange_rate, 1) exchange_rate
   from  ar_payment_schedules ps,
         ar_receivable_applications app';

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ', hz_cust_accounts cust_acct';
    end if;

    l_cus_sel1 := l_cus_sel1 || ' where  ps.gl_date <= :as_of_date
    and   ps.customer_id > 0
    and   ps.gl_date_closed  > :as_of_date
    and   app.org_id = :param_org_id 
    and   ps.org_id = app.org_id
    and   NVL(upper(:p_in_currency),ps.invoice_currency_code)
              = ps.invoice_currency_code
    and   app.applied_payment_schedule_id = ps.payment_schedule_id
    and   app.status IN (''APP'', ''ACTIVITY'')
    and   nvl( app.confirmed_flag, ''Y'' ) = ''Y''
    and   app.gl_date > :as_of_date ';
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_low;
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_high;

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ' and ps.customer_id = cust_acct.cust_account_id ';
    end if;
/* ps.trx_date column Added for case #6747 */
    l_cus_sel1 := l_cus_sel1 || 'group by 
  ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.class ,
	  ps.trx_date,  
      ps.due_date,
      ps.trx_number,
      ps.amount_adjusted ,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date ,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code,
      nvl(ps.exchange_rate, 1),
      ps.payment_schedule_id 
';
    l_cus_sel1 := l_cus_sel1 || 'UNION ALL
   select /*+ LEADING(app) USE_NL(ps) */ 
      ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.payment_schedule_id,
      ps.class ,
      0 primary_salesrep_id,
	  ps.trx_date,  
      ps.due_date  ,
      nvl(sum ( decode
                   ( :c_convert_flag, ''Y'',
             (decode(ps.class, ''CM'',
                decode ( app.application_type, ''CM'',
                     app.acctd_amount_applied_from,
                                         app.acctd_amount_applied_to
                    ),
                app.acctd_amount_applied_to)+
                       nvl(app.acctd_earned_discount_taken,0) +
                       nvl(app.acctd_unearned_discount_taken,0))
             ,
                     ( app.amount_applied +
                       nvl(app.earned_discount_taken,0) +
                       nvl(app.unearned_discount_taken,0) )
           ) *
           decode
                   ( ps.class, ''CM'',
                      decode(app.application_type, ''CM'', -1, 1), 1 )
                ), 0) amount_due_remaining_inv, 
      ps.trx_number ,
      ps.amount_adjusted,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date gl_date_inv,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code, 
      nvl(ps.exchange_rate, 1) exchange_rate
   from  ar_payment_schedules ps,
         ar_receivable_applications app';

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ', hz_cust_accounts cust_acct';
    end if;

    l_cus_sel1 := l_cus_sel1 || ' where  ps.gl_date <= :as_of_date
    and   ps.customer_id > 0
    and   ps.gl_date_closed  > :as_of_date
    and   app.org_id = :param_org_id 
    and   ps.org_id = app.org_id
    and   NVL(upper(:p_in_currency),ps.invoice_currency_code)
              = ps.invoice_currency_code
    and   app.payment_schedule_id = ps.payment_schedule_id
    and   app.status IN (''APP'', ''ACTIVITY'')
    and   nvl( app.confirmed_flag, ''Y'' ) = ''Y''
    and   app.gl_date > :as_of_date ';
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_low;
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_high;

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ' and ps.customer_id = cust_acct.cust_account_id ';
    end if;
/* ps.trx_date column Added for case #6747 */
    l_cus_sel1 := l_cus_sel1 || 'group by 
      ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.class ,
	  ps.trx_date,   
      ps.due_date,
      ps.trx_number,
      ps.amount_adjusted ,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date ,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code,
      nvl(ps.exchange_rate, 1),
      ps.payment_schedule_id 
';
    l_cus_sel1 := l_cus_sel1 || 'UNION ALL
   select  /*+ LEADING(ps)
               NO_INDEX(ps ar_payment_schedules_n9 */
      ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.payment_schedule_id,
      ps.class class_inv,
      nvl(ct.primary_salesrep_id, -3) primary_salesrep_id,
	  ps.trx_date transaction_date_inv,   
      ps.due_date  due_date_inv,
      decode( :c_convert_flag, ''Y'',
              ps.acctd_amount_due_remaining,
              ps.amount_due_remaining) amt_due_remaining_inv,
      ps.trx_number,
      ps.amount_adjusted ,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date ,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code,
      nvl(ps.exchange_rate, 1) exchange_rate
   from  ar_payment_schedules ps,
         ra_customer_trx ct';

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ', hz_cust_accounts cust_acct';
    end if;

    l_cus_sel1 := l_cus_sel1 || ' where  ps.gl_date <= :as_of_date
    and   ps.gl_date_closed  > :as_of_date
    and   ps.org_id = :param_org_id 
    and   ps.org_id = ct.org_id
    and   decode(upper(:p_in_currency),NULL, ps.invoice_currency_code,
              upper(:p_in_currency)) = ps.invoice_currency_code
    and  ps.customer_trx_id = ct.customer_trx_id
   ';

    if pg_rep_type = 'ARXAGR' then
      l_cus_sel1 := l_cus_sel1 || ' and ps.class <> ''CB'' ';
    end if;

    l_cus_sel1 := l_cus_sel1 || lp_customer_num_low;
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_high;

    if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
      l_cus_sel1 := l_cus_sel1 || ' and ps.customer_id = cust_acct.cust_account_id';
    end if;
/* ps.trx_date Added for case #6747 */
    if pg_rep_type = 'ARXAGR' then
      l_cus_sel1 := l_cus_sel1 || ' UNION ALL
   select  ps.customer_id,
      ps.customer_site_use_id ,
      ps.customer_trx_id,
      ps.payment_schedule_id,
      ps.class class_inv,
      ct.primary_salesrep_id primary_salesrep_id,
	  ps.trx_date transaction_date_inv,    
      ps.due_date  due_date_inv,
      decode( :c_convert_flag, ''Y'',
              ps.acctd_amount_due_remaining,
              ps.amount_due_remaining) amt_due_remaining_inv,
      ps.trx_number,
      ps.amount_adjusted ,
      ps.amount_applied ,
      ps.amount_credited ,
      ps.amount_adjusted_pending,
      ps.gl_date ,
      ps.cust_trx_type_id,
      ps.org_id,
      ps.invoice_currency_code,
      nvl(ps.exchange_rate, 1) exchange_rate
   from  ar_payment_schedules ps,
         ra_customer_trx ct,
         ar_adjustments adj';

      if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
        l_cus_sel1 := l_cus_sel1 || ', hz_cust_accounts cust_acct';
      end if;

      l_cus_sel1 := l_cus_sel1 || ' where  ps.gl_date <= :as_of_date
    and   ps.gl_date_closed  > :as_of_date
    and   ps.org_id = :param_org_id 
    and   ps.org_id = adj.org_id
    and   adj.org_id = ct.org_id
    and   decode(upper(:p_in_currency),NULL, ps.invoice_currency_code,
              upper(:p_in_currency)) = ps.invoice_currency_code
    and  ps.class = ''CB''
    and  ps.customer_trx_id = adj.chargeback_customer_trx_id
    and  adj.customer_trx_id = ct.customer_trx_id ';
      l_cus_sel1 := l_cus_sel1 || lp_customer_num_low;
      l_cus_sel1 := l_cus_sel1 || lp_customer_num_high;

      if pg_in_customer_num_low is not null or pg_in_customer_num_high is not null then
        l_cus_sel1 := l_cus_sel1 || ' and ps.customer_id = cust_acct.cust_account_id';
      end if;
    end if;
 /* a.trx_date column Added for case #6747 */
    --debug('I am here');
    l_cus_sel1 := l_cus_sel1 || ' ) a
group by a.customer_id,
      a.customer_site_use_id ,
      a.customer_trx_id,
      a.payment_schedule_id,
      a.class ,
	  a.trx_date,   
      a.due_date ,
      a.trx_number,
      a.amount_adjusted,
      a.amount_applied ,
      a.amount_credited ,
      a.amount_adjusted_pending,
      a.gl_date ,
      a.cust_trx_type_id,
      a.org_id,
      a.invoice_currency_code,
      a.exchange_rate) ps, ';
    l_cus_sel1 := l_cus_sel1 || ' ar_dispute_history dh';
    l_cus_sel1 := l_cus_sel1 || ',ra_cust_trx_line_gl_dist gld ';

    if pg_rep_type = 'ARXAGF' then
      l_cus_sel1 := l_cus_sel1 || ',xla_distribution_links lk
                ,xla_ae_lines ae 
                ,xla_ae_headers aeh 
                ,ra_cust_trx_types types ';
    end if;

    l_cus_sel1 := l_cus_sel1 || ',gl_code_combinations c
                ,hz_cust_accounts cust_acct
                ,hz_parties party';
    --end if;
    l_cus_sel1 := l_cus_sel1 || lp_agl_from1;
    l_cus_sel1 := l_cus_sel1 || lp_agr_from1;
    l_cus_sel1 := l_cus_sel1 || ' where   /* ps.gl_date <= :as_of_date and
            ps.org_id = :param_org_id and  
            ps.gl_date_closed  > :as_of_date and 
           decode(upper(:p_in_currency),NULL, ps.invoice_currency_code,
                   upper(:p_in_currency)) = ps.invoice_currency_code */
            ps.payment_schedule_id  =  dh.payment_schedule_id(+) 
     and    :as_of_date  >= nvl(dh.start_date(+), :as_of_date)
     and    :as_of_date  <  nvl(dh.end_date(+), :as_of_date + 1)
     and    gld.account_class = ''REC''
     and    gld.latest_rec_flag  =  ''Y'' ';

    if pg_rep_type = 'ARXAGF' then
      l_cus_sel1 := l_cus_sel1
                    || ' and types.cust_trx_type_id = ps.cust_trx_type_id 
     and    types.org_id = ps.org_id
     and    ps.org_id = gld.org_id
     and    gld.event_id = lk.event_id(+) 
     and    gld.cust_trx_line_gl_dist_id = lk.source_distribution_id_num_1(+)
     and    lk.source_distribution_type(+)   = ''RA_CUST_TRX_LINE_GL_DIST_ALL''
     and    lk.application_id(+)             = 222
     and    ae.application_id(+)          = 222
     and    lk.ae_header_id                = ae.ae_header_id(+)
     and    lk.ae_line_num                 = ae.ae_line_num(+)
     and    ae.ae_header_id                = aeh.ae_header_id(+)
     and    aeh.application_id(+)          = 222
     and    aeh.event_type_code(+)         <> ''MANUAL''
     and    decode(ae.accounting_class_code,'''',decode(lk.source_distribution_type,'''',''Y'',''N''),''RECEIVABLE'',''Y'',''N'') = ''Y''
     and    decode(ae.ledger_id,'''',decode(types.post_to_gl, ''N'', gld.code_combination_id, decode(gld.posting_control_id,-3,-999999,gld.code_combination_id)),gld.set_of_books_id,ae.code_combination_id,-999999)= c.code_combination_id ';
    else
      l_cus_sel1 := l_cus_sel1 || 'and gld.code_combination_id = c.code_combination_id ';
    end if;

    l_cus_sel1 := l_cus_sel1 || ' and    cust_acct.party_id = party.party_id ';
    l_cus_sel1 := l_cus_sel1 || lp_where;
    l_cus_sel1 := l_cus_sel1 || lp_customer_name_low;
    l_cus_sel1 := l_cus_sel1 || lp_customer_name_high;
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_low;
    l_cus_sel1 := l_cus_sel1 || lp_customer_num_high;
    l_cus_sel1 := l_cus_sel1 || lp_invoice_type_low;
    l_cus_sel1 := l_cus_sel1 || lp_invoice_type_high;
    l_cus_sel1 := l_cus_sel1 || lp_bal_low;
    l_cus_sel1 := l_cus_sel1 || lp_bal_high;
    l_cus_sel1 := l_cus_sel1 || lp_agfs_where1;
    l_cus_sel1 := l_cus_sel1 || lp_aglr_where1;

    if (pg_rep_type in ('ARXAGR', 'ARXAGL')) then
      l_cus_sel1 := l_cus_sel1 || ' and ps.customer_trx_id = gld.customer_trx_id ';
    end if;

    l_cus_sel1 := l_cus_sel1 || lp_agl_where1;

    if pg_rep_type = 'ARXAGR' then
      l_cus_sel1 := l_cus_sel1 || ' and nvl(ps.primary_salesrep_id,-3) = sales.salesrep_id ';
    end if;

    l_cus_sel1 := l_cus_sel1 || lp_agr_where5;
    l_cus_sel1 := l_cus_sel1 || lp_agr_where4;
    l_cus_sel1 := l_cus_sel1 || lp_agr_where_org1;
    --x_common_query_cus1 := l_cus_sel1;
    ------------------------------------------------------------
    -- BUILD THIRD SELECT STATEMENT - OPEN RECEIPTS
    ------------------------------------------------------------
    l_cus_sel3 :=    'select  /*+ LEADING(app) USE_NL(ps) */ '
                  || 'substrb(party.party_name,1,50) short_cust_name, '
                  || 'nvl(cust_acct.cust_account_id, -999) cust_id, '
                  || 'cust_acct.account_number cust_no,';

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel3 := l_cus_sel3 || 'decode(upper(:sort_option),''T'',initcap(:lp_payment_meaning), NULL),';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel3 := l_cus_sel3 || lp_agl_name;
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel3 := l_cus_sel3 || lp_agr_name;
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 := l_cus_sel3 || 'app.segments, ';
    end if;

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel3 := l_cus_sel3 || 'initcap(:lp_payment_meaning),';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(col.collector_id),';
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(nvl(sales.salesrep_id,-3)),';
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(app.code_combination_id),';
    end if;

    l_cus_sel3 :=    l_cus_sel3
                  || '   ps.payment_schedule_id, '
                  || 'app.class, '
				  || 'ps.trx_date,'    /* Added for case #6747 */
                  || 'ps.due_date, '
                  || 'decode(:c_convert_flag, ''Y'', nvl(-SUM(acctd_amount), 0), nvl(-SUM(amount), 0)), '
                  || 'ceil(:as_of_date - ps.due_date), '
                  || 'ps.amount_adjusted, '
                  || 'ps.amount_applied, '
                  || 'ps.amount_credited, '
                  || 'ps.gl_date, '
                  || 'decode(ps.invoice_currency_code, :functional_currency, NULL, '
                  || 'decode(ps.exchange_rate, NULL, ''*'', NULL)), '
                  || 'nvl(ps.exchange_rate, 1),';
    l_cus_sel3 :=    l_cus_sel3
                  || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_0,:bucket_days_to_0, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b0, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_1, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_1,:bucket_days_to_1, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b1, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_2, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_2,:bucket_days_to_2, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b2, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_3, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_3,:bucket_days_to_3, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b3, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_4, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_4,:bucket_days_to_4, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b4, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_5, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_5,:bucket_days_to_5, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b5, '
                  || 'arpt_sql_func_util.bucket_function(:bucket_line_type_6, '
                  || 'ps.amount_in_dispute,ps.amount_adjusted_pending, '
                  || ':bucket_days_from_6,:bucket_days_to_6, '
                  || 'ps.due_date,:bucket_category,:as_of_date) b6,';
    l_cus_sel3 := l_cus_sel3 || 'app.segment1, ';

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel3 := l_cus_sel3 || 'decode(upper(:sort_option),''T'',''-1'',NULL)';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel3 := l_cus_sel3 || 'col.name';
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(-3)';
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 := l_cus_sel3 || 'app.segments';
    end if;

    l_cus_sel3 := l_cus_sel3 || ' inv_tid,';
    l_cus_sel3 := l_cus_sel3 || 'initcap(:lp_payment_meaning)';
    l_cus_sel3 := l_cus_sel3 || ' from ar_payment_schedules ps, ' || 'hz_cust_accounts cust_acct, ' || 'hz_parties party,';
    l_cus_sel3 :=    l_cus_sel3
                  || ' (SELECT  /*+ LEADING(ps) USE_NL(ps,c) '
                  || 'NO_INDEX(app ar_receivable_applications_n6) */ '
                  || lp_acct_flex_bal_seg
                  || ' segment1, '
                  || lp_accounting_flexfield
                  || ' segments, '
                  || 'c.code_combination_id code_combination_id, '
                  || 'ps.payment_schedule_id payment_schedule_id, '
                  || 'decode(app.applied_payment_schedule_id,   -4,   ''CLAIM'',   ps.class) class, '
                  || 'app.acctd_amount_applied_from acctd_amount, '
                  || 'app.amount_applied amount, '
                  || 'app.status status '
                  || 'FROM ar_receivable_applications app, '
                  || 'gl_code_combinations c, '
                  || 'ar_payment_schedules ps '
                  || 'WHERE app.gl_date <= :as_of_date '
                  || 'AND ps.cash_receipt_id = app.cash_receipt_id '
                  || 'AND app.code_combination_id = c.code_combination_id '
                  || 'AND app.status IN(''ACC'', ''UNAPP'', ''UNID'', ''OTHER ACC'') '
                  || 'AND nvl(app.confirmed_flag, ''Y'') = ''Y'' '
                  || 'AND ps.gl_date_closed > : as_of_date '
                  || 'AND ps.org_id = :param_org_id '
                  || 'AND((app.reversal_gl_date IS NOT NULL '
                  || 'AND ps.gl_date <= : as_of_date) OR app.reversal_gl_date IS NULL) '
                  || 'AND decode(UPPER(: p_in_currency), NULL,   ps.invoice_currency_code, UPPER(:p_in_currency)) = ps.invoice_currency_code '
                  || 'AND nvl(ps.receipt_confirmed_flag, ''Y'') = ''Y'' ';

    if (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 := l_cus_sel3 || 'AND app.posting_control_id <> -3
                AND app.event_id IS NULL ';
    end if;

    l_cus_sel3 := l_cus_sel3 || lp_bal_low;
    l_cus_sel3 := l_cus_sel3 || lp_bal_high;

    if (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 :=    l_cus_sel3
                    || 'UNION ALL '
                    || 'SELECT /*+ LEADING(app1) USE_NL(dist,c,lk,ae,aeh) */ '
                    || lp_acct_flex_bal_seg
                    || ', '
                    || lp_accounting_flexfield
                    || ', c.code_combination_id, '
                    || 'app1.payment_schedule_id, '
                    || 'decode(ae.accounting_class_code, ''UNAPP'', app1.class, decode(app1.applied_payment_schedule_id, -4, ''CLAIM'', app1.class)) class, '
                    || 'nvl(lk.UNROUNDED_ACCOUNTED_CR, 0) - nvl(lk.UNROUNDED_ACCOUNTED_DR, 0) acctd_amount, '
                    || 'nvl(lk.UNROUNDED_ENTERED_CR, 0) - nvl(lk.UNROUNDED_ENTERED_DR,0) amount, '
                    || 'decode(ae.accounting_class_code, ''ACC'', ''ACC'', ''UNID'', ''UNID'', ''UNAPP'', ''UNAPP'', decode(app1.status, ''OTHER ACC'', ''OTHER ACC'', ae.accounting_class_code)) status '
                    || 'FROM '
                    || 'gl_code_combinations c, '
                    || 'xla_distribution_links lk, '
                    || 'xla_ae_lines ae, '
                    || 'xla_ae_headers aeh, '
                    || 'ar_distributions dist, '
                    || '(Select /*+ LEADING(ps) USE_NL(app) NO_INDEX(app ar_receivable_applications_n6) */ '
                    || 'app.cash_receipt_id cash_receipt_id, '
                    || 'app.receivable_application_id source_id, '
                    || 'app.reversal_gl_date reversal_gl_date, '
                    || 'app.set_of_books_id set_of_books_id, '
                    || 'app.applied_payment_schedule_id applied_payment_schedule_id, '
                    || 'app.status status, '
                    || '''RA'' source_table, '
                    || 'ps.payment_schedule_id, '
                    || 'ps.class '
                    || 'FROM   ar_payment_schedules ps, '
                    || '       ar_receivable_applications app '
                    || 'WHERE app.gl_date <= :as_of_date '
                    || 'AND   app.org_id = :param_org_id '
                    || 'AND   app.posting_control_id <> -3 '
                    || 'AND   app.event_id IS NOT NULL '
                    || 'AND   nvl(app.confirmed_flag,   ''Y'') = ''Y'' '
                    || 'AND   ps.cash_receipt_id = app.cash_receipt_id '
                    || 'AND   ps.gl_date_closed > :as_of_date '
                    || 'AND   ps.org_id = :param_org_id '
                    || 'AND   decode(UPPER(:p_in_currency), NULL, ps.invoice_currency_code, UPPER(:p_in_currency)) = '
                    || '          ps.invoice_currency_code '
                    || 'AND   nvl(ps.receipt_confirmed_flag, ''Y'') = ''Y'' '
                    || 'AND   ((app.reversal_gl_date IS NOT NULL AND ps.gl_date <= :as_of_date) '
                    || '            OR app.reversal_gl_date IS NULL)';
      l_cus_sel3 :=    l_cus_sel3
                    || 'UNION ALL '
                    || 'Select /*+ LEADING(ps) USE_NL(crh,cr) */ '
                    || 'crh.cash_receipt_id, '
                    || 'crh.cash_receipt_history_id, '
                    || 'crh.reversal_gl_date, '
                    || 'cr.set_of_books_id, '
                    || 'NULL, '
                    || 'NULL, '
                    || '''CRH'' source_table, '
                    || 'ps.payment_schedule_id, '
                    || 'ps.class '
                    || 'FROM  ar_payment_schedules ps, '
                    || '      ar_cash_receipt_history crh, '
                    || '      ar_cash_receipts cr '
                    || 'WHERE crh.gl_date <= :as_of_date '
                    || 'AND   crh.org_id = :param_org_id '
                    || 'AND   crh.posting_control_id <> -3 '
                    || 'AND   event_id IS NOT NULL '
                    || 'AND   cr.cash_receipt_id = crh.cash_receipt_id '
                    || 'AND   nvl(cr.confirmed_flag, ''Y'') = ''Y'' '
                    || 'AND   ps.cash_receipt_id = crh.cash_receipt_id '
                    || 'AND   ps.gl_date_closed > :as_of_date '
                    || 'AND   ps.org_id = :param_org_id '
                    || 'AND   decode(UPPER(:p_in_currency), NULL, ps.invoice_currency_code, UPPER(:p_in_currency)) = '
                    || '          ps.invoice_currency_code '
                    || 'AND   nvl(ps.receipt_confirmed_flag, ''Y'') = ''Y'' '
                    || 'AND   ((crh.reversal_gl_date IS NOT NULL AND ps.gl_date <= :as_of_date) '
                    || '            OR crh.reversal_gl_date IS NULL)';
      l_cus_sel3 :=    l_cus_sel3
                    || ') app1 '
                    || 'WHERE  '
                    || '    dist.source_id = app1.source_id '
                    || 'AND dist.source_table = app1.source_table '
                    || 'AND dist.line_id = lk.source_distribution_id_num_1 '
                    || 'AND lk.application_id = 222 '
                    || 'AND ae.application_id = 222 '
                    || 'AND lk.source_distribution_type = ''AR_DISTRIBUTIONS_ALL'' '
                    || 'AND lk.ae_header_id = ae.ae_header_id '
                    || 'AND lk.ae_line_num = ae.ae_line_num '
                    || 'AND ae.ae_header_id = aeh.ae_header_id '
                    || 'AND aeh.application_id = 222 '
                    || 'AND aeh.event_type_code <> ''MANUAL'' '
                    || 'AND (ae.accounting_class_code IN (''ACC'', ''UNID'', ''UNAPP'') OR app1.status = ''OTHER ACC'') '
                    || 'AND ae.accounting_date <= :as_of_date '
                    || 'AND ae.ledger_id = app1.set_of_books_id '
                    || 'AND ae.code_combination_id = c.code_combination_id ';
      l_cus_sel3 := l_cus_sel3 || lp_bal_low;
      l_cus_sel3 := l_cus_sel3 || lp_bal_high;
    end if;

    l_cus_sel3 := l_cus_sel3 || ' ) app ';
    l_cus_sel3 := l_cus_sel3 || lp_agl_from1;
    l_cus_sel3 := l_cus_sel3 || lp_agr_from1;
    l_cus_sel3 := l_cus_sel3 || ' where  ps.payment_schedule_id = app.payment_schedule_id
    and    ps.customer_id = cust_acct.cust_account_id(+)
    and    cust_acct.party_id= party.party_id (+) ';
    l_cus_sel3 := l_cus_sel3 || lp_where;
    l_cus_sel3 := l_cus_sel3 || lp_customer_name_low;
    l_cus_sel3 := l_cus_sel3 || lp_customer_name_high;
    l_cus_sel3 := l_cus_sel3 || lp_customer_num_low;
    l_cus_sel3 := l_cus_sel3 || lp_customer_num_high;
    l_cus_sel3 := l_cus_sel3 || lp_agl_where1;
    l_cus_sel3 := l_cus_sel3 || lp_agr_where3;
    l_cus_sel3 := l_cus_sel3 || lp_agr_where4;
    l_cus_sel3 := l_cus_sel3 || lp_agr_where5;
    l_cus_sel3 := l_cus_sel3 || lp_agr_where_org1;
    l_cus_sel3 := l_cus_sel3 || ' GROUP BY party.party_name,
         cust_acct.account_number,
         cust_acct.cust_account_id,';

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel3 := l_cus_sel3 || 'decode(upper(:sort_option),''T'',initcap(:lp_payment_meaning), NULL),';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel3 := l_cus_sel3 || lp_agl_name;
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel3 := l_cus_sel3 || lp_agr_name;
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 := l_cus_sel3 || ' app.segments, ';
    end if;

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel3 := l_cus_sel3 || 'initcap(:lp_payment_meaning),';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(col.collector_id),';
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(nvl(sales.salesrep_id,-3)),';
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(app.code_combination_id),';
    end if;
/* ps.trx_date column Added for case #6747 */
    l_cus_sel3 := l_cus_sel3 || '    ps.payment_schedule_id,
	     ps.trx_date,   
         ps.due_date,
         ps.amount_adjusted,
         ps.amount_applied,
         ps.amount_credited,
         ps.gl_date,
         ps.amount_in_dispute,
         ps.amount_adjusted_pending,
         ps.invoice_currency_code,
         ps.exchange_rate,
         app.class,
         app.code_combination_id,';
    l_cus_sel3 := l_cus_sel3 || ' app.segment1, ';
    l_cus_sel3 := l_cus_sel3 || ' decode( app.status, ''UNID'', ''UNID'',''OTHER ACC'',''OTHER ACC'',''UNAPP'') ,';

    if (pg_rep_type = 'ARXAGS') then
      l_cus_sel3 := l_cus_sel3 || 'decode(upper(:sort_option),''T'',''-1'',NULL), ';
    elsif (pg_rep_type = 'ARXAGL') then
      l_cus_sel3 := l_cus_sel3 || lp_agl_name;
    elsif (pg_rep_type = 'ARXAGR') then
      l_cus_sel3 := l_cus_sel3 || 'to_char(-3),';
    elsif (pg_rep_type = 'ARXAGF') then
      l_cus_sel3 := l_cus_sel3 || ' app.segments, ';
    end if;

    l_cus_sel3 := l_cus_sel3 || 'initcap(:lp_payment_meaning)';

    --x_common_query_cus3 := l_cus_sel3;
    ------------------------------------------------------------
    -- BUILD FOURTH SELECT STATEMENT - RECEIPTS AT RISK
    ------------------------------------------------------------
    if pg_risk_option != 'NONE' then
      l_cus_sel4 := ' UNION ALL ' || new_line;
      l_cus_sel4 := l_cus_sel4 || 'select substrb(party.party_name,1,50) short_cust_name,
         nvl(cust_acct.cust_account_id, -999) cust_id,
         cust_acct.account_number cust_no,';

      if (pg_rep_type = 'ARXAGS') then
        l_cus_sel4 := l_cus_sel4 || 'decode(upper(:sort_option),''T'',initcap(:lp_risk_meaning), NULL),';
      elsif (pg_rep_type = 'ARXAGL') then
        l_cus_sel4 := l_cus_sel4 || lp_agl_name;
      elsif (pg_rep_type = 'ARXAGR') then
        l_cus_sel4 := l_cus_sel4 || lp_agr_name;
      elsif (pg_rep_type = 'ARXAGF') then
        l_cus_sel4 := l_cus_sel4 || lp_accounting_flexfield || ',';
      end if;

      if (pg_rep_type = 'ARXAGS') then
        l_cus_sel4 := l_cus_sel4 || 'initcap(:lp_risk_meaning),';
      elsif (pg_rep_type = 'ARXAGL') then
        l_cus_sel4 := l_cus_sel4 || 'to_char(col.collector_id),';
      elsif (pg_rep_type = 'ARXAGR') then
        l_cus_sel4 := l_cus_sel4 || 'to_char(nvl(sales.salesrep_id,-3)),';
      elsif (pg_rep_type = 'ARXAGF') then
        l_cus_sel4 := l_cus_sel4 || 'to_char(c.code_combination_id),';
      end if;
/* ps.trx_date column Added for case #6747 */
      l_cus_sel4 := l_cus_sel4 || '  ps.payment_schedule_id,
         initcap(:lp_risk_meaning),
		 ps.trx_date,    
         ps.due_date,
         decode( :c_convert_flag, ''Y'', crh.acctd_amount, crh.amount),
         ceil(:as_of_date - ps.due_date),
         ps.amount_adjusted,
         ps.amount_applied,
         ps.amount_credited,
         crh.gl_date,
         decode(ps.invoice_currency_code, :functional_currency, NULL,
                decode(crh.exchange_rate, NULL, ''*'', NULL)),
         nvl(crh.exchange_rate, 1),';
      l_cus_sel4 := l_cus_sel4 || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0,
                0,0,:bucket_days_from_0,:bucket_days_to_0,
                 ps.due_date,:bucket_category,:as_of_date) b0,
      arpt_sql_func_util.bucket_function(:bucket_line_type_1,
                0,0,:bucket_days_from_1,:bucket_days_to_1,
                 ps.due_date,:bucket_category,:as_of_date) b1,
      arpt_sql_func_util.bucket_function(:bucket_line_type_2,
                0,0,:bucket_days_from_2,:bucket_days_to_2,
                 ps.due_date,:bucket_category,:as_of_date) b2,
      arpt_sql_func_util.bucket_function(:bucket_line_type_3,
                0,0,:bucket_days_from_3,:bucket_days_to_3,
                 ps.due_date,:bucket_category,:as_of_date) b3,
      arpt_sql_func_util.bucket_function(:bucket_line_type_4,
                0,0,:bucket_days_from_4,:bucket_days_to_4,
                 ps.due_date,:bucket_category,:as_of_date) b4,
      arpt_sql_func_util.bucket_function(:bucket_line_type_5,
                0,0,:bucket_days_from_5,:bucket_days_to_5,
                 ps.due_date,:bucket_category,:as_of_date) b5,
      arpt_sql_func_util.bucket_function(:bucket_line_type_6,
                0,0,:bucket_days_from_6,:bucket_days_to_6,
                 ps.due_date,:bucket_category,:as_of_date) b6,';
      l_cus_sel4 := l_cus_sel4 || lp_acct_flex_bal_seg || ',';

      if (pg_rep_type = 'ARXAGS') then
        l_cus_sel4 := l_cus_sel4 || 'decode(upper(:sort_option),''T'',''-1'',NULL)';
      elsif (pg_rep_type = 'ARXAGL') then
        l_cus_sel4 := l_cus_sel4 || 'col.name';
      elsif (pg_rep_type = 'ARXAGR') then
        l_cus_sel4 := l_cus_sel4 || 'to_char(-3)';
      elsif (pg_rep_type = 'ARXAGF') then
        l_cus_sel4 := l_cus_sel4 || lp_accounting_flexfield;
      end if;

      l_cus_sel4 := l_cus_sel4 || ' inv_tid,';
      l_cus_sel4 := l_cus_sel4 || 'initcap(:lp_risk_meaning)';
      l_cus_sel4 := l_cus_sel4 || ' from       hz_cust_accounts cust_acct,
                   hz_parties party,
                   ar_payment_schedules ps,
                   ar_cash_receipts cr,
                   ar_cash_receipt_history crh,
                   gl_code_combinations c ';

      if (pg_rep_type = 'ARXAGF') then
        l_cus_sel4 := l_cus_sel4 || ', xla_distribution_links lk,
                   xla_ae_lines ae,
                   xla_ae_headers aeh,
                   ar_distributions dist ';
      end if;

      l_cus_sel4 := l_cus_sel4 || lp_agl_from1;
      l_cus_sel4 := l_cus_sel4 || lp_agr_from1;
      l_cus_sel4 := l_cus_sel4 || ' where  crh.gl_date <= :as_of_date
    and upper(:p_risk_option) != ''NONE''
    and ps.customer_id = cust_acct.cust_account_id(+)
    and ps.org_id = :param_org_id
    and cust_acct.party_id = party.party_id (+)
    and ps.cash_receipt_id = cr.cash_receipt_id
    and cr.cash_receipt_id = crh.cash_receipt_id 
    and cr.org_id = crh.org_id ';

      if (pg_rep_type = 'ARXAGF') then
        l_cus_sel4 := l_cus_sel4
                      || 'and dist.source_id = crh.cash_receipt_history_id
    and dist.source_table = ''CRH''
    and dist.line_id = lk.source_distribution_id_num_1(+)
    and lk.application_id(+) = 222
    and ae.application_id(+) = 222
    and lk.source_distribution_type(+) = ''AR_DISTRIBUTIONS_ALL''
    and lk.ae_header_id = ae.ae_header_id(+)
    and lk.ae_line_num = ae.ae_line_num(+)
    and ae.ae_header_id = aeh.ae_header_id (+)
    and aeh.application_id (+)  = 222
    and aeh.event_type_code(+) <> ''MANUAL'' 
    and decode(ae.ledger_id,   '''', decode(crh.posting_control_id,   -3,   -999999,   crh.account_code_combination_id),   cr.set_of_books_id,   ae.code_combination_id,   -999999) = c.code_combination_id 
    and NVL(ae.accounting_class_code, dist.source_type) = dist.source_type
    and decode(crh.status, ''CONFIRMED'', ''CONFIRMATION'', ''REMITTED'', ''REMITTANCE'', crh.status) = dist.source_type ';
      else
        l_cus_sel4 := l_cus_sel4 || 'and crh.account_code_combination_id = c.code_combination_id ';
      end if;

      l_cus_sel4 := l_cus_sel4 || ' and (  crh.current_record_flag = ''Y''
            or crh.reversal_gl_date > :as_of_date )
    and    crh.status not in ( decode(crh.factor_flag,
                                                ''Y'',''RISK_ELIMINATED'',
                                                ''N'',''CLEARED''),
                                    ''REVERSED'')
    and    NVL(upper(:p_in_currency),ps.invoice_currency_code)
                 = ps.invoice_currency_code 
    /* Bug 4127480 : exclude receipts applied to short term debt */
    and   not exists (select ''x'' 
                      from ar_receivable_applications ra
                      where ra.cash_receipt_id = cr.cash_receipt_id
                      and ra.status = ''ACTIVITY''
                      and applied_payment_schedule_id = -2) 
    and cr.cash_receipt_id not in 
            (select ps.reversed_cash_receipt_id 
                   from ar_payment_schedules ps 
                    where ps.reversed_cash_receipt_id=cr.cash_receipt_id
                   and   ps.org_id = cr.org_id 
                   and   ps.class=''DM''
                   and   ps.gl_date<= (:as_of_date)) ';
      l_cus_sel4 := l_cus_sel4 || lp_where;
      l_cus_sel4 := l_cus_sel4 || lp_customer_name_low;
      l_cus_sel4 := l_cus_sel4 || lp_customer_name_high;
      l_cus_sel4 := l_cus_sel4 || lp_customer_num_low;
      l_cus_sel4 := l_cus_sel4 || lp_customer_num_high;
      l_cus_sel4 := l_cus_sel4 || lp_bal_low;
      l_cus_sel4 := l_cus_sel4 || lp_bal_high;
      l_cus_sel4 := l_cus_sel4 || lp_aglr_where5;
      l_cus_sel4 := l_cus_sel4 || lp_agr_where3;
      l_cus_sel4 := l_cus_sel4 || lp_agr_where4;
      l_cus_sel4 := l_cus_sel4 || lp_agr_where5;
      l_cus_sel4 := l_cus_sel4 || lp_agl_where1;
      l_cus_sel4 := l_cus_sel4 || lp_agr_where_org1;
    -- x_common_query_cus4 := l_cus_sel4;
    end if;

    ------------------------------------------------------------
    -- BUILD FIFTH SELECT STATEMENT - BR ONLY
    ------------------------------------------------------------
    if p_br_enabled = 'Y' then
      l_cus_sel5 := 'select substrb(party.party_name,1,50) short_cust_name,
         nvl(cust_acct.cust_account_id, -999) cust_id,
         cust_acct.account_number cust_no,';

      if (pg_rep_type = 'ARXAGS') then
        l_cus_sel5 := l_cus_sel5 || 'decode(upper(:sort_option),''T'',ctt.name, NULL)';
      elsif (pg_rep_type = 'ARXAGL') then
        l_cus_sel5 := l_cus_sel5 || 'col.name';
      elsif (pg_rep_type = 'ARXAGR') then
        l_cus_sel5 := l_cus_sel5 || 'extns.resource_name';
      elsif (pg_rep_type = 'ARXAGF') then
        l_cus_sel5 := l_cus_sel5 || lp_accounting_flexfield;
      end if;

      l_cus_sel5 := l_cus_sel5 || ' sort_field1,';

      if (pg_rep_type = 'ARXAGS') then
        l_cus_sel5 := l_cus_sel5 || 'ctt.name';
      elsif (pg_rep_type = 'ARXAGL') then
        l_cus_sel5 := l_cus_sel5 || 'to_char(col.collector_id)';
      elsif (pg_rep_type = 'ARXAGR') then
        l_cus_sel5 := l_cus_sel5 || 'to_char(nvl(sales.salesrep_id,-3))';
      elsif (pg_rep_type = 'ARXAGF') then
        l_cus_sel5 := l_cus_sel5 || 'to_char(c.code_combination_id)';
      end if;
/* ps.trx_date column Added for case #6747 */
      l_cus_sel5 := l_cus_sel5 || ' sort_field2,';
      l_cus_sel5 := l_cus_sel5 || '  ps.payment_schedule_id payment_sched_id,
         ps.class class,
		 ps.trx_date transaction_date,   
         ps.due_date due_date,
         decode( :c_convert_flag, ''Y'', ps.acctd_amount_due_remaining,
                         ps.amount_due_remaining) amt_due_remaining,
         ceil(:as_of_date - ps.due_date) days_past_due ,
         ps.amount_adjusted amount_adjusted,
         ps.amount_applied amount_applied,
         ps.amount_credited amount_credited,
         ps.gl_date gl_date,
         decode(ps.invoice_currency_code, :functional_currency, NULL,
                        decode(ps.exchange_rate, NULL, ''*'', NULL)) data_converted,
         nvl(ps.exchange_rate, 1) ps_exchange_rate,';
      l_cus_sel5 := l_cus_sel5 || ' arpt_sql_func_util.bucket_function(:bucket_line_type_0,
                ps.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_0,:bucket_days_to_0,
                 ps.due_date,:bucket_category,:as_of_date) b0,
      arpt_sql_func_util.bucket_function(:bucket_line_type_1,
                ps.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_1,:bucket_days_to_1,
                 ps.due_date,:bucket_category,:as_of_date) b1,
      arpt_sql_func_util.bucket_function(:bucket_line_type_2,
                ps.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_2,:bucket_days_to_2,
                 ps.due_date,:bucket_category,:as_of_date) b2,
      arpt_sql_func_util.bucket_function(:bucket_line_type_3,
                ps.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_3,:bucket_days_to_3,
                 ps.due_date,:bucket_category,:as_of_date) b3,
      arpt_sql_func_util.bucket_function(:bucket_line_type_4,
                ps.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_4,:bucket_days_to_4,
                 ps.due_date,:bucket_category,:as_of_date) b4,
      arpt_sql_func_util.bucket_function(:bucket_line_type_5,
                ps.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_5,:bucket_days_to_5,
                 ps.due_date,:bucket_category,:as_of_date) b5,
      arpt_sql_func_util.bucket_function(:bucket_line_type_6,
                ps.amount_in_dispute,ps.amount_adjusted_pending,
                :bucket_days_from_6,:bucket_days_to_6,
                 ps.due_date,:bucket_category,:as_of_date) b6,';
      l_cus_sel5 := l_cus_sel5 || lp_acct_flex_bal_seg || ' bal_segment_value,';

      if (pg_rep_type = 'ARXAGS') then
        l_cus_sel5 := l_cus_sel5 || 'decode(upper(:sort_option),''T'',to_char(ctt.cust_trx_type_id),NULL)';
      elsif (pg_rep_type = 'ARXAGL') then
        l_cus_sel5 := l_cus_sel5 || 'col.name';
      elsif (pg_rep_type = 'ARXAGR') then
        l_cus_sel5 := l_cus_sel5 || 'extns.resource_name';
      elsif (pg_rep_type = 'ARXAGF') then
        l_cus_sel5 := l_cus_sel5 || lp_accounting_flexfield;
      end if;

      l_cus_sel5 := l_cus_sel5 || ' inv_tid,';
      l_cus_sel5 := l_cus_sel5 || 'ctt.name invoice_type';
      l_cus_sel5 := l_cus_sel5 || ' from       ra_cust_trx_types ctt,
                   hz_cust_accounts cust_acct,
                   hz_parties party,
                   ar_payment_schedules ps,
                   ar_transaction_history th, ';

      if pg_rep_type = 'ARXAGF' then
        l_cus_sel5 := l_cus_sel5 || '   (SELECT th1.customer_trx_id,
                              th1.transaction_history_id,
                              ae.code_combination_id
                       FROM ar_distributions ard,
                            xla_distribution_links lk,
                            xla_ae_lines ae,
                            ar_transaction_history th1,
                            ra_customer_trx trx,
                            xla_ae_headers hd 
                       WHERE th1.event_id IS NOT NULL 
                         AND ard.source_id = th1.transaction_history_id 
                         AND ard.source_table = ''TH''
                         AND ard.source_table_secondary IS NULL
                         AND ard.line_id = lk.source_distribution_id_num_1 
                         AND lk.application_id = 222 
                         AND lk.source_distribution_type = ''AR_DISTRIBUTIONS_ALL'' 
                         AND ae.application_id = 222 
                         AND lk.ae_header_id = ae.ae_header_id 
                         AND lk.ae_line_num = ae.ae_line_num 
                         AND lk.ae_header_id = hd.ae_header_id 
                         AND hd.application_id  = 222
                         AND hd.event_type_code <> ''MANUAL'' 
                         AND th1.customer_trx_id = trx.customer_trx_id 
                         AND trx.set_of_books_id = hd.ledger_id 
                         AND lk.unrounded_entered_dr  IS NOT NULL
                         AND ae.accounting_class_code IN 
                         ( ''RECEIVABLE'',''DEFERRED_TAX'',''TAX'',
                         ''UNPAID_BR'',''REM_BR'',''FAC_BR'') 
                      UNION ALL
                      SELECT th2.customer_trx_id,
                             th2.transaction_history_id,
                             ard.code_combination_id
                      FROM ar_distributions ard,
                           ar_transaction_history th2 
                      WHERE th2.event_id IS NULL
                         AND th2.posting_control_id <> -3 
                         AND ard.source_table      = ''TH'' 
                         AND ard.source_id         = th2.transaction_history_id 
                         AND ard.amount_dr         IS NOT NULL
                         AND ard.source_table_secondary IS NULL) dist, ';
      else
        l_cus_sel5 := l_cus_sel5 || 'ar_distributions dist, ';
      end if;

      l_cus_sel5 := l_cus_sel5 || 'gl_code_combinations c';
      l_cus_sel5 := l_cus_sel5 || lp_agl_from2;
      l_cus_sel5 := l_cus_sel5 || lp_agl_from1;
      l_cus_sel5 := l_cus_sel5 || lp_agr_from2;
      l_cus_sel5 := l_cus_sel5 || lp_agr_from1;
      l_cus_sel5 := l_cus_sel5 || ' where  ps.gl_date <= :as_of_date
     and    ps.gl_date_closed  > :as_of_date
     and    ps.class = ''BR''
     and    decode(upper(:p_in_currency),NULL, ps.invoice_currency_code,
                   upper(:p_in_currency)) = ps.invoice_currency_code
     and    ps.cust_trx_type_id = ctt.cust_trx_type_id
     and    ps.org_id = ctt.org_id
     and    ps.customer_id = cust_acct.cust_account_id
     and    ps.org_id = :param_org_id
     and    cust_acct.party_id = party.party_id ';

      if pg_rep_type = 'ARXAGF' then
        l_cus_sel5 := l_cus_sel5
                      || ' and th.transaction_history_id IN 
         (SELECT MAX(th1.transaction_history_id)
          FROM ar_transaction_history th1,
               ra_customer_trx trx,
               ar_distributions ard,
               xla_distribution_links lk,
               xla_ae_lines ae,
               xla_ae_headers hd 
          WHERE th1.customer_trx_id = ps.customer_trx_id
            AND th1.customer_trx_id = trx.customer_trx_id 
            AND th1.transaction_history_id = ard.source_id  
            AND ard.source_table = ''TH'' 
            AND ard.source_table_secondary IS NULL
            AND ard.line_id = lk.source_distribution_id_num_1(+) 
            AND lk.application_id(+) = 222 
            AND lk.source_distribution_type(+) = ''AR_DISTRIBUTIONS_ALL'' 
            AND lk.ae_header_id = ae.ae_header_id(+) 
            AND lk.ae_line_num = ae.ae_line_num(+) 
            AND ae.application_id(+) = 222 
            AND lk.ae_header_id = hd.ae_header_id(+) 
            AND hd.application_id(+)  = 222
            AND hd.event_type_code(+) <> ''MANUAL'' 
            AND trx.set_of_books_id = DECODE(hd.ledger_id,NULL,trx.set_of_books_id,hd.ledger_id))
       and dist.customer_trx_id        = ps.customer_trx_id
       and th.transaction_history_id   = dist.transaction_history_id
       and c.code_combination_id       = dist.code_combination_id ';
      else
        l_cus_sel5 := l_cus_sel5 || ' and   th.transaction_history_id = 
         (select max(transaction_history_id)
            from ar_transaction_history th2, 
                ar_distributions  dist2 
                where th2.transaction_history_id = dist2.source_id
                 and  dist2.source_table = ''TH''
                 and  th2.gl_date <= :as_of_date
                 and  dist2.amount_dr is not null
                 and  th2.customer_trx_id = ps.customer_trx_id)
       and    th.transaction_history_id = dist.source_id 
       and    dist.source_table = ''TH''
       and    dist.amount_dr is not null
       and    dist.source_table_secondary is NULL
       and    dist.code_combination_id = c.code_combination_id ';
      end if;

      l_cus_sel5 := l_cus_sel5 || lp_where;
      l_cus_sel5 := l_cus_sel5 || lp_customer_name_low;
      l_cus_sel5 := l_cus_sel5 || lp_customer_name_high;
      l_cus_sel5 := l_cus_sel5 || lp_customer_num_low;
      l_cus_sel5 := l_cus_sel5 || lp_customer_num_high;
      l_cus_sel5 := l_cus_sel5 || lp_invoice_type_low;
      l_cus_sel5 := l_cus_sel5 || lp_invoice_type_high;
      l_cus_sel5 := l_cus_sel5 || lp_bal_low;
      l_cus_sel5 := l_cus_sel5 || lp_bal_high;
      l_cus_sel5 := l_cus_sel5 || lp_agfs_where3;
      l_cus_sel5 := l_cus_sel5 || lp_aglr_where1;
      l_cus_sel5 := l_cus_sel5 || lp_aglr_where2;
      l_cus_sel5 := l_cus_sel5 || lp_aglr_where3;
      l_cus_sel5 := l_cus_sel5 || lp_aglr_where8;
      l_cus_sel5 := l_cus_sel5 || lp_agl_where1;
      l_cus_sel5 := l_cus_sel5 || lp_agr_where1;
      l_cus_sel5 := l_cus_sel5 || lp_agr_where4;
      l_cus_sel5 := l_cus_sel5 || lp_agr_where_org1;
      l_cus_sel5 := l_cus_sel5 || lp_agr_where_org2;
      l_cus_sel5 := l_cus_sel5 || ' order by 24,4,1,3';
    --x_common_query_cus5 := l_cus_sel5;
    end if;

    --debug(l_cus_sel1);
    --debug(l_cus_sel2);
    --debug(l_cus_sel3);
    --debug(l_cus_sel4);
    --debug(l_cus_sel5);
    return 'Y';
  exception
    when others then
      debug(sqlerrm);
      return 'N';
  end;

  procedure bind_parameters(p_cursor integer) is
    cursor buc_info_cur is
      select *
      from   (select lines.bucket_sequence_num buc_number, days_start, days_to, report_heading1, report_heading2, type
                   , decode(type,  'DISPUTE_ONLY', type,  'PENDADJ_ONLY', type,  'DISPUTE_PENDADJ', type,  null) bucket_category
              from   ar_aging_bucket_lines lines, ar_aging_buckets buckets
              where      lines.aging_bucket_id = buckets.aging_bucket_id
                     and upper(buckets.bucket_name) = upper(pg_in_bucket_type_low)
                     and nvl(buckets.status, 'A') = 'A') buckets
           , (select     rownum - 1 sequence_number
              from       dual
              connect by rownum < 8) dummy
      where  dummy.sequence_number = buckets.buc_number(+);
  begin
    debug('xx_ar_aging_xml_rpt_pkg.bind_bucket_parameters()+');
    debug('p_cursor  :' || p_cursor);
    dbms_sql.bind_variable(p_cursor, 'as_of_date', pg_in_as_of_date_low);
    debug('p_cursor-1  :' || p_cursor);
    dbms_sql.bind_variable(p_cursor, 'param_org_id', pg_param_org_id);
    debug('p_cursor-2  :' || p_cursor);
    dbms_sql.bind_variable(p_cursor, 'c_convert_flag', pg_convert_flag);
    debug('p_cursor-3  :' || p_cursor);
    --dbms_sql.bind_variable(p_cursor, 'convert_flag', pg_convert_flag);
    debug('p_cursor-4  :' || p_cursor);
    dbms_sql.bind_variable(p_cursor, 'functional_currency', pg_functional_currency);
    debug('p_cursor-5  :' || p_cursor);

    if pg_in_summary_option_low = 'I' then
      dbms_sql.bind_variable(p_cursor, 'format_detailed', pg_format_detailed);
      dbms_sql.bind_variable(p_cursor, 'p_in_summary_option_low', pg_in_summary_option_low);
      dbms_sql.bind_variable(p_cursor, 'p_short_unid_phrase', p_short_unid_phrase);
    end if;

    debug('p_cursor-1 6  :' || p_cursor);
    --dbms_sql.bind_variable(p_cursor, 'p_short_unid_phrase', p_short_unid_phrase);
    dbms_sql.bind_variable(p_cursor, 'lp_payment_meaning', lp_payment_meaning);
    debug('p_cursor-7  :' || p_cursor);

    if (pg_risk_option in ('SUMMARY', 'DETAIL')) or (pg_risk_option = 'NONE' and pg_in_summary_option_low = 'I') then
      dbms_sql.bind_variable(p_cursor, 'lp_risk_meaning', lp_risk_meaning);
      debug('p_cursor-8 :' || p_cursor);
      dbms_sql.bind_variable(p_cursor, 'p_risk_option', pg_risk_option);
    end if;

    debug('p_cursor-9  :' || p_cursor);
    dbms_sql.bind_variable(p_cursor, 'p_in_currency', pg_in_currency);
    debug('p_cursor-10  :' || p_cursor);
    dbms_sql.bind_variable(p_cursor, 'bucket_category', 'D');
    debug('p_cursor-11  :' || p_cursor);

    if pg_in_customer_name_low is not null then
      dbms_sql.bind_variable(p_cursor, 'p_in_customer_name_low', pg_in_customer_name_low);
    end if;

    if pg_in_customer_name_high is not null then
      dbms_sql.bind_variable(p_cursor, 'p_in_customer_name_high', pg_in_customer_name_high);
    end if;

    if pg_in_customer_num_low is not null then
      debug('p_cursor-12  :' || p_cursor);
      dbms_sql.bind_variable(p_cursor, 'p_in_customer_num_low', pg_in_customer_num_low);
    end if;

    if pg_in_customer_num_high is not null then
      debug('p_cursor-13  :' || p_cursor);
      dbms_sql.bind_variable(p_cursor, 'p_in_customer_num_high', pg_in_customer_num_high);
    end if;

    if pg_in_invoice_type_low is not null then
      dbms_sql.bind_variable(p_cursor, 'p_in_invoice_type_low', pg_in_invoice_type_low);
    end if;

    if pg_in_invoice_type_high is not null then
      dbms_sql.bind_variable(p_cursor, 'p_in_invoice_type_high', pg_in_invoice_type_high);
    end if;

    if pg_rep_type = 'ARXAGL' then
      if pg_in_collector_low is not null then
        dbms_sql.bind_variable(p_cursor, 'p_in_collector_low', pg_in_collector_low);
      end if;

      if pg_in_collector_high is not null then
        dbms_sql.bind_variable(p_cursor, 'p_in_collector_high', pg_in_collector_high);
      end if;
    end if;

    if pg_rep_type = 'ARXAGR' then
      if pg_in_salesrep_low is not null then
        dbms_sql.bind_variable(p_cursor, 'p_in_salesrep_name_low', pg_in_salesrep_low);
      end if;

      if pg_in_salesrep_high is not null then
        dbms_sql.bind_variable(p_cursor, 'p_in_salesrep_name_high', pg_in_salesrep_high);
      end if;
    end if;

    for buc_rec in buc_info_cur loop
      debug('bucket_days_from_' || buc_rec.sequence_number || ' value ' || buc_rec.days_start);
      debug('bucket_days_to_' || buc_rec.sequence_number || ' value ' || buc_rec.days_to);
      debug('bucket_line_type_' || buc_rec.sequence_number || ' value ' || buc_rec.type);
      debug('bucket_category_' || buc_rec.sequence_number || ' value ' || buc_rec.bucket_category);
      dbms_sql.bind_variable(p_cursor, 'bucket_days_from_' || buc_rec.sequence_number, buc_rec.days_start);
      dbms_sql.bind_variable(p_cursor, 'bucket_days_to_' || buc_rec.sequence_number, buc_rec.days_to);
      dbms_sql.bind_variable(p_cursor, 'bucket_line_type_' || buc_rec.sequence_number, buc_rec.type);
    --dbms_sql.bind_variable(p_cursor, ':bucket_category_' || buc_rec.sequence_number, buc_rec.bucket_category);
    --dbms_sql.bind_variable(p_cursor, 'bucket_category', buc_rec.bucket_category);
    end loop;

    debug('xx_ar_aging_xml_rpt_pkg.bind_bucket_parameters()-');
  exception
    when others then
      debug('Exception ' || sqlerrm);
      debug('Exception xx_ar_aging_xml_rpt_pkg.bind_parameters()');
  end bind_parameters;

  function initialize
    return boolean is
    l_option_sql varchar2(3000);
    l_adj number;
  begin
    p_mrcsobtype := 'N';
    p_br_enabled := 'Y';
    l_adj := adj_max_idformula;
    lp_ar_system_parameters := 'AR_SYSTEM_PARAMETERS';
    lp_ar_system_parameters_all := 'AR_SYSTEM_PARAMETERS';
    lp_ar_payment_schedules := 'AR_PAYMENT_SCHEDULES';
    lp_ar_payment_schedules_all := 'AR_PAYMENT_SCHEDULES';
    lp_ar_adjustments := 'AR_ADJUSTMENTS';
    lp_ar_adjustments_all := 'AR_ADJUSTMENTS';
    lp_ar_cash_receipt_history := 'AR_CASH_RECEIPT_HISTORY';
    lp_ar_cash_receipt_history_all := 'AR_CASH_RECEIPT_HISTORY';
    lp_ar_batches := 'AR_BATCHES';
    lp_ar_batches_all := 'AR_BATCHES';
    lp_ar_cash_receipts := 'AR_CASH_RECEIPTS';
    lp_ar_cash_receipts_all := 'AR_CASH_RECEIPTS';
    lp_ar_distributions := 'AR_XLA_ARD_LINES_V';
    lp_ar_distributions_all := 'AR_XLA_ARD_LINES_V';
    lp_ra_customer_trx := 'RA_CUSTOMER_TRX';
    lp_ra_customer_trx_all := 'RA_CUSTOMER_TRX';
    lp_ra_batches := 'RA_BATCHES';
    lp_ra_batches_all := 'RA_BATCHES';
    lp_ra_cust_trx_gl_dist := 'AR_XLA_CTLGD_LINES_V';
    lp_ra_cust_trx_gl_dist_all := 'AR_XLA_CTLGD_LINES_V';
    lp_ar_misc_cash_dists := 'AR_MISC_CASH_DISTRIBUTIONS';
    lp_ar_misc_cash_dists_all := 'AR_MISC_CASH_DISTRIBUTIONS';
    lp_ar_rate_adjustments := 'AR_RATE_ADJUSTMENTS';
    lp_ar_rate_adjustments_all := 'AR_RATE_ADJUSTMENTS';
    lp_ar_receivable_apps := 'AR_RECEIVABLE_APPLICATIONS';
    lp_ar_receivable_apps_all := 'AR_RECEIVABLE_APPLICATIONS';
    -- *** End ***
    xla_mo_reporting_api.initialize(pg_reporting_level, pg_reporting_entity_id, 'AUTO', 'N');
    p_org_where_ps := xla_mo_reporting_api.get_predicate('ps', 'push_subq');
    p_org_where_gld := xla_mo_reporting_api.get_predicate('gld', 'push_subq');
    p_org_where_ct := xla_mo_reporting_api.get_predicate('ct', 'push_subq');
    p_org_where_sales := xla_mo_reporting_api.get_predicate('sales', 'push_subq');
    p_org_where_ct2 := xla_mo_reporting_api.get_predicate('ct2', 'push_subq');
    p_org_where_adj := xla_mo_reporting_api.get_predicate('adj', 'push_subq');
    p_org_where_app := xla_mo_reporting_api.get_predicate('app', 'push_subq');
    p_org_where_crh := xla_mo_reporting_api.get_predicate('crh', 'push_subq');
    p_org_where_cr := xla_mo_reporting_api.get_predicate('cr', 'push_subq');
    p_org_where_param := xla_mo_reporting_api.get_predicate('PARAM', null);
    xla_mo_reporting_api.initialize(pg_reporting_level, pg_reporting_entity_id, 'AUTO');
    p_org_where_addr := xla_mo_reporting_api.get_predicate('acct_site', 'push_subq');
    p_reporting_entity_name := substrb(xla_mo_reporting_api.get_reporting_entity_name, 1, 80);
    p_reporting_level_name := substrb(xla_mo_reporting_api.get_reporting_level_name, 1, 30);

    if pg_in_customer_name_low is not null then
      lp_customer_name_low := ' and party.party_name >= :p_in_customer_name_low ';
    end if;

    if pg_in_customer_name_high is not null then
      lp_customer_name_high := ' and party.party_name <= :p_in_customer_name_high ';
    end if;

    if pg_in_customer_num_low is not null then
      lp_customer_num_low := ' and cust_acct.account_number >= :p_in_customer_num_low ';
    end if;

    if pg_in_customer_num_high is not null then
      lp_customer_num_high := ' and cust_acct.account_number <= :p_in_customer_num_high ';
    end if;

    if pg_in_invoice_type_low is not null then
      lp_invoice_type_low := ' and arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id) >= :p_in_invoice_type_low ';
    end if;

    if pg_in_invoice_type_high is not null then
      lp_invoice_type_high := ' and arpt_sql_func_util.get_org_trx_type_details(ps.cust_trx_type_id,ps.org_id) <= :p_in_invoice_type_high ';
    end if;

    if pg_in_bal_segment_low is not null then
      lp_bal_low := ' and '
                    || ar_calc_aging.flex_sql(p_application_id => 101
                                            , p_id_flex_code => 'GL#'
                                            , p_id_flex_num => pg_coaid
                                            , p_table_alias => 'C'
                                            , p_mode => 'WHERE'
                                            , p_qualifier => 'GL_BALANCING'
                                            , p_function => '>='
                                            , p_operand1 => pg_in_bal_segment_low);
    end if;

    if pg_in_bal_segment_high is not null then
      lp_bal_high := ' and '
                     || ar_calc_aging.flex_sql(p_application_id => 101
                                             , p_id_flex_code => 'GL#'
                                             , p_id_flex_num => pg_coaid
                                             , p_table_alias => 'C'
                                             , p_mode => 'WHERE'
                                             , p_qualifier => 'GL_BALANCING'
                                             , p_function => '<='
                                             , p_operand1 => pg_in_bal_segment_high);
    end if;

    lp_accounting_flexfield := ar_calc_aging.flex_sql(p_application_id => 101
                                                    , p_id_flex_code => 'GL#'
                                                    , p_id_flex_num => pg_coaid
                                                    , p_table_alias => 'c'
                                                    , p_mode => 'SELECT'
                                                    , p_qualifier => 'ALL');
    lp_acct_flex_bal_seg := ar_calc_aging.flex_sql(p_application_id => 101
                                                 , p_id_flex_code => 'GL#'
                                                 , p_id_flex_num => pg_coaid
                                                 , p_table_alias => 'c'
                                                 , p_mode => 'SELECT'
                                                 , p_qualifier => 'GL_BALANCING');

    begin
      p_cons_profile_value := ar_setup.value('AR_SHOW_BILLING_NUMBER', null);
    exception
      when others then
        null;
    end;

    if (p_cons_profile_value = 'N') then
      lp_query_show_bill := 'to_char(NULL)';
      lp_table_show_bill := null;
      lp_where_show_bill := null;
    else
      lp_query_show_bill := 'ci.cons_billing_number';
      lp_table_show_bill := 'ar_cons_inv ci,';
      lp_where_show_bill := 'and ps.cons_inv_id = ci.cons_inv_id(+)';
    end if;

    if upper(rtrim(rpad(pg_in_summary_option_low, 1))) = 'I' then
      lp_where := ' and upper(RTRIM(RPAD(:p_in_summary_option_low,1))) = ''C''   ';
    end if;

    ----------------------------------------------------------------------
    --                     Merge project modifications                  --
    ----------------------------------------------------------------------
    -- Initialize label values
    --------------------------
    p_sort_on := '';
    p_label_1 := '';
    p_report_name := '';
    p_segment_label := '';
    p_low := '';
    p_high := '';
    p_label := '';
    p_grand_total := '';
    p_bal_label := '';
    pg_rep_type := upper(pg_rep_type);

    -- get string and label definitions from table
    -----------------------------------------------
    begin
      p_report_name := arp_standard.fnd_message(pg_rep_type || '_REPORT_NAME');
      p_segment_label := arp_standard.fnd_message(pg_rep_type || '_SEG_LABEL');
      p_bal_label := arp_standard.fnd_message(pg_rep_type || '_BAL_LABEL');
      p_label_1 := arp_standard.fnd_message(pg_rep_type || '_LABEL_1');

      if pg_rep_type = 'ARXAGS' then
        if upper(rtrim(rpad(pg_in_summary_option_low, 1))) = 'I' then
          p_bal_label := arp_standard.fnd_message(pg_rep_type || '_BAL_LABEL_INV');
        end if;

        if upper(substr(p_in_sortoption, 1, 1)) = 'C' then
          p_sort_on := arp_standard.fnd_message(pg_rep_type || '_SORT_ONC');
          p_grand_total := arp_standard.fnd_message(pg_rep_type || '_GRAND_TOTAL_C');
        else
          p_sort_on := arp_standard.fnd_message(pg_rep_type || '_SORT_ONT');
          p_grand_total := arp_standard.fnd_message(pg_rep_type || '_GRAND_TOTAL_T');
        end if;
      else
        p_sort_on := arp_standard.fnd_message(pg_rep_type || '_SORT_ON');
        p_grand_total := arp_standard.fnd_message(pg_rep_type || '_GRAND_TOTAL');
      end if;

      if pg_rep_type in ('ARXAGL', 'ARXAGR') then
        p_label := arp_standard.fnd_message(pg_rep_type || '_LABEL');
      end if;
    exception
      when no_data_found then
        null;
    end;

    -- initialize lexical parameter values used for AGL
    ---------------------------------------------------
    lp_agl_name := ''''',';
    lp_agl_id := ''''',';
    lp_agl_from1 := '';
    lp_agl_from2 := '';
    lp_agl_where1 := '';
    lp_agl_where_org2 := '';
    -- initialize lexical parameters used for AGR
    ---------------------------------------------
    lp_agr_name := ''''',';
    lp_agr_id := ''''',';
    lp_agr_from1 := '';
    lp_agr_from2 := '';
    lp_agr_from3 := '';
    lp_agr_where1 := '';
    lp_agr_where2 := '';
    lp_agr_where3 := '';
    lp_agr_where4 := '';
    lp_agr_where5 := '';
    lp_agr_where_org1 := '';
    lp_agr_where_org2 := '';
    -- initialize lexical parameters used for both AGL and AGR
    --------------------------------------------------------
    lp_aglr_where1 := '';
    lp_aglr_where2 := '';
    lp_aglr_where3 := '';
    lp_aglr_where4 := '';
    lp_aglr_where5 := '';
    lp_aglr_where6 := '';
    lp_aglr_where7 := '';
    lp_aglr_where8 := '';
    -- initialize lexical parameters used for both AGF and AGS
    --------------------------------------------------------
    lp_agfs_where1 := '';
    lp_agfs_where2 := '';
    lp_agfs_where3 := '';
    lp_agfs_where4 := '';

    -- define generic lexical parameters for use in both ARXAGF and ARXAGS
    ----------------------------------------------------------------------
    if (pg_rep_type in ('ARXAGF', 'ARXAGS')) then
      lp_agfs_where1 := ' and ps.customer_id = cust_acct.cust_account_id ' || ' and ps.customer_trx_id = gld.customer_trx_id ';
      lp_agfs_where2 := ' and ps.customer_id = cust_acct.cust_account_id ' || ' and ps.customer_trx_id = gld.customer_trx_id ';
      lp_agfs_where3 := ' and ps.customer_id=cust_acct.cust_account_id ' || 'and ps.customer_trx_id = th.customer_trx_id ';
      lp_agfs_where4 := ' and ps.customer_id = cust_acct.cust_account_id ' || ' and ps.customer_trx_id = th.customer_trx_id ';
    end if;

    -- define generic lexical parameters for use in both ARXAGL and ARXAGR
    ----------------------------------------------------------------------
    if (pg_rep_type in ('ARXAGL', 'ARXAGR')) then
      lp_aglr_where1 := ' and ps.customer_id = cust_acct.cust_account_id ';
      lp_aglr_where3 := ' and ps.customer_trx_id = ct.customer_trx_id ';
      lp_aglr_where4 := ' and ct.customer_trx_id = gld.customer_trx_id ';
      lp_aglr_where5 := ' and ps.trx_number is not null ';
      lp_aglr_where6 := ' and ps.customer_trx_id = ct.customer_trx_id ';
      lp_aglr_where7 := ' and ct.customer_trx_id = gld.customer_trx_id';
      lp_aglr_where8 := ' and ct.customer_trx_id = th.customer_trx_id ';
    end if;

    -- define lexical parameters for from and where clause
    -------------------------------------------------------
    if pg_rep_type = 'ARXAGL' then
      p_low := pg_in_collector_low;
      p_high := pg_in_collector_high;
      lp_agl_name := ' col.name, ';
      lp_agl_id := ' col.collector_id, ';
      lp_agl_from1 := ' ,hz_customer_profiles site_cp ' || ' ,hz_customer_profiles cust_cp ' || ' ,ar_collectors col ';

      if upper(p_mrcsobtype) = 'R' then
        lp_agl_from2 := ' ,ra_customer_trx_all_mrc_v ct ';
      else
        lp_agl_from2 := ' ,ra_customer_trx ct ';
      end if;

      lp_agl_where1 :=    ' and cust_cp.cust_account_id = cust_acct.cust_account_id '
                       || ' and cust_cp.site_use_id is null '
                       || ' and site_cp.site_use_id(+) = ps.customer_site_use_id '
                       || ' and col.collector_id = NVL(site_cp.collector_id, cust_cp.collector_id) ';

      if pg_in_collector_low is not null then
        lp_agl_where1 := lp_agl_where1 || ' and col.name >= :p_in_collector_low';
      end if;

      if pg_in_collector_high is not null then
        lp_agl_where1 := lp_agl_where1 || ' and col.name <= :p_in_collector_high';
      end if;

      lp_agl_where_org2 := p_org_where_ct;
    end if;

    if pg_rep_type = 'ARXAGR' then
      p_low := pg_in_salesrep_low;
      p_high := pg_in_salesrep_high;
      lp_agr_name := ' extns.resource_name, ';
      lp_agr_id := ' nvl(sales.salesrep_id,-3), ';
      lp_agr_from1 := ' ,ra_salesreps_all sales ,jtf_rs_resource_extns_vl extns ';

      if upper(p_mrcsobtype) = 'R' then
        lp_agr_from2 := ' ,ra_customer_trx_all_mrc_v ct ';
      else
        lp_agr_from2 := ' ,ra_customer_trx ct ';
      end if;

      lp_agr_from3 := ' ra_salesreps_all sales , jtf_rs_resource_extns_vl extns, ';
      lp_agr_where1 := ' and nvl(ct.primary_salesrep_id,-3) = sales.salesrep_id '
                       || ' and nvl(sales.org_id, ct.org_id) = ct.org_id ';
      lp_agr_where2 := ' and ps.class != ''CB''';
      lp_agr_where3 := ' and sales.salesrep_id = -3';
      lp_agr_where4 :=    ' and extns.resource_name between nvl(:p_in_salesrep_name_low,extns.resource_name)'
                       || ' and nvl(:p_in_salesrep_name_high,extns.resource_name)'
                       || ' and sales.resource_id = extns.resource_id ';
      lp_agr_where5 := ' and nvl(sales.org_id, ps.org_id) = ps.org_id ';
      lp_agr_where_org1 := p_org_where_sales;
      lp_agr_where_org2 := p_org_where_ct;
    end if;

    p_short_unid_phrase := rtrim(rpad(arpt_sql_func_util.get_lookup_meaning('MISC_PHRASES', 'UNIDENTIFIED_PAYMENT'), 18));
    lp_payment_meaning := rtrim(rpad(arpt_sql_func_util.get_lookup_meaning('INV/CM/ADJ', 'PMT'), 20));
    lp_risk_meaning := rtrim(rpad(arpt_sql_func_util.get_lookup_meaning('MISC_PHRASES', 'RISK'), 20));
    debug(p_org_where_param);
    --debug('Here');
    l_option_sql := 'SELECT  param.org_id ,sob.name,
              sob.chart_of_accounts_id,
              sob.currency_code,
              cur.precision,
              decode(:pg_in_currency,NULL,''Y'',NULL),
               param.set_of_books_id                
       FROM    gl_sets_of_books sob,
              AR_SYSTEM_PARAMETERS param,
              fnd_currencies cur
        WHERE  sob.set_of_books_id = param.set_of_books_id
        AND       sob.currency_code = cur.currency_code ';
    l_option_sql := l_option_sql || p_org_where_param;
    debug(l_option_sql);
    execute immediate l_option_sql
      into pg_param_org_id, pg_company_name, pg_coaid, pg_functional_currency, pg_func_curr_precision, pg_convert_flag
         , pg_set_of_books_id
      using pg_in_currency;
    select pg_param_org_id lookup_org_id, decode(pg_credit_option, 'DETAIL', 'Y', 'N') include_credit_high
         , decode(pg_credit_option, 'SUMMARY', 'Y', 'N') in_on_account_low, meaning credit_option_meaning
    into   pg_lookup_org_id, pg_include_credit_high, pg_in_on_account_low, pg_credit_option_meaning
    from   ar_lookups
    where  lookup_type = 'OPEN_CREDITS' and lookup_code = pg_credit_option;
    select pg_param_org_id sel_opt_org_id
         , decode(upper(rtrim(rpad(pg_in_on_account_low, 1))), 'Y', 'Y', null) print_on_account_flag
         , upper(rtrim(rpad(nvl(pg_in_sortoption, '*'), 1))) sort_option
         , upper(rtrim(rpad(pg_in_summary_option_low, 1))) summary_option
         , decode(upper(rtrim(rpad(pg_in_format_option_low, 1))), 'D', 'D', null) format_detailed
         , decode(pg_in_invoice_type_high, pg_in_invoice_type_low, pg_in_invoice_type_low, pg_in_invoice_type_low || ' to ' || pg_in_invoice_type_high) invoice_type_print
         , decode(pg_in_customer_name_low, pg_in_customer_name_high, pg_in_customer_name_low, pg_in_customer_name_low || ' to ' || pg_in_customer_name_high) customer_name_print
         , decode(pg_in_amt_due_low, pg_in_amt_due_high, pg_in_amt_due_low, pg_in_amt_due_low || ' to ' || pg_in_amt_due_high) balance_due_print
    into   pg_sel_opt_org_id, pg_print_on_account_flag, pg_sort_option, pg_summary_option, pg_format_detailed
         , pg_invoice_type_print, pg_customer_name_print, pg_balance_due_print
    from   dual;

    if upper(rtrim(rpad(pg_in_summary_option_low, 1))) = 'I' then
      --common_query_inv := build_invoice_select;
      build_invoice_select;
    --common_query_inv := NULL;
    elsif upper(rtrim(rpad(pg_in_summary_option_low, 1))) = 'C' then
      common_query_cus := build_customer_select;
    --common_query_cus := null;
    end if;
    debug(common_query_cus);
    return (true);
  exception
    when others then
      debug(sqlerrm);
      return (false);
  end;

  function comp_amt_due_remainingformula(p_payment_sched_id in number
                                       , p_class in varchar2
                                       , p_amount_adjusted in number
                                       , p_data_converted in varchar2
                                       , p_invoice_type in varchar2
                                       , p_amount_applied in number
                                       , p_amount_credited in number
                                       , p_amt_due_remaining in number
                                       , p_b0 in number
                                       , p_b1 in number
                                       , p_b2 in number
                                       , p_b3 in number
                                       , p_b4 in number
                                       , p_b5 in number
                                       , p_b6 in number
                                       , p_row_id in ROWID)                                        ---Added By sumanth as part of the 8583#
    return number is
  begin
    declare
      amount_applied_late number;
      adjustments_amount number;

      cursor cncl_br(br_trx_id number) is
        select transaction_history_id
        from   ar_transaction_history
        where  customer_trx_id = br_trx_id and gl_date > pg_in_as_of_date_low and event = 'CANCELLED';

      br_trx_id number;
      ret_exch_amt number;

      cursor c is
        select *
        from   xx_ar_aging_rpt_cust_gt;

      c_on_account_amount_cash number := 0;
      c_on_account_amount_credit number := 0;
      c_on_account_amount_risk number := 0;
      c_cust_amount_claim number := 0;
      c_amt_due_remaining number :=NULL;
      c_data_converted_flag number;
      c_cust_b0 number := 0;
      c_cust_b1 number := 0;
      c_cust_b2 number := 0;
      c_cust_b3 number := 0;
      c_cust_b4 number := 0;
      c_cust_b5 number := 0;
      c_cust_b6 number := 0;
    begin
      --for i in c loop
      c_on_account_amount_cash := 0;
      c_on_account_amount_credit := 0;
      c_on_account_amount_risk := 0;
      c_cust_amount_claim := 0;
      c_cust_b0 := 0;
      c_cust_b1 := 0;
      c_cust_b2 := 0;
      c_cust_b3 := 0;
      c_cust_b4 := 0;
      c_cust_b5 := 0;
      c_cust_b6 := 0;
      c_amt_due_remaining := null;
      c_data_converted_flag := 0;

      if (pg_credit_option = 'NONE') and ((p_class = 'PMT') or (p_class = 'CM')) then
        return (0);
      end if;

      if (pg_credit_option = 'SUMMARY') and ((p_class = 'PMT') or (p_class = 'CM')) and (pg_sort_option = 'T') then
        return (0);
      end if;

      if (pg_risk_option = 'NONE') and (p_invoice_type = lp_risk_meaning) then
        return (0);
      end if;

      if (pg_risk_option = 'SUMMARY') and (p_invoice_type = lp_risk_meaning) and (pg_sort_option = 'T') then
        return (0);
      end if;

      if (pg_credit_option = 'NONE') and (p_class = 'CLAIM') then
        return (0);
      end if;

      c_amt_due_remaining := p_amt_due_remaining;

      if p_br_enabled = 'Y' then
        if p_class = 'BR' then
          select customer_trx_id
          into   br_trx_id
          from   ar_payment_schedules
          where  payment_schedule_id = p_payment_sched_id;

          for j in cncl_br(br_trx_id) loop
            ret_exch_amt := 0;

            if pg_rep_type = 'ARXAGF' then
              select sum(decode(pg_convert_flag
                              , 'Y', decode(nvl(acctd_amount_cr, 0), 0, nvl(acctd_amount_dr, 0), (acctd_amount_cr * -1))
                              , decode(nvl(amount_cr, 0), 0, nvl(amount_dr, 0), (amount_cr * -1))))
              into   ret_exch_amt
              from   ar_xla_ard_lines_v
              where      source_table = 'TH'
                     and source_id = j.transaction_history_id
                     and source_id_secondary in (select customer_trx_line_id
                                                 from   ra_customer_trx_lines
                                                 where  customer_trx_id = br_trx_id);
            else
              select sum(decode(pg_convert_flag
                              , 'Y', decode(nvl(acctd_amount_cr, 0), 0, nvl(acctd_amount_dr, 0), (acctd_amount_cr * -1))
                              , decode(nvl(amount_cr, 0), 0, nvl(amount_dr, 0), (amount_cr * -1))))
              into   ret_exch_amt
              from   ar_distributions
              where      source_table = 'TH'
                     and source_id = j.transaction_history_id
                     and source_id_secondary in (select customer_trx_line_id
                                                 from   ra_customer_trx_lines
                                                 where  customer_trx_id = br_trx_id);
            end if;

            c_amt_due_remaining := nvl(c_amt_due_remaining, 0) + nvl(ret_exch_amt, 0);
          end loop;

          if p_amount_applied is not null or p_amount_credited is not null then
            if (p_invoice_type not in (lp_payment_meaning, lp_risk_meaning) and p_class <> 'CLAIM') then
              select nvl(sum(decode(pg_convert_flag
                                  , 'Y', (decode(ps.class
                                               , 'CM', decode(ra.application_type
                                                            , 'CM', ra.acctd_amount_applied_from
                                                            , ra.acctd_amount_applied_to)
                                               , ra.acctd_amount_applied_to)
                                          + nvl(ra.acctd_earned_discount_taken, 0)
                                          + nvl(ra.acctd_unearned_discount_taken, 0))
                                  , (ra.amount_applied + nvl(ra.earned_discount_taken, 0) + nvl(ra.unearned_discount_taken, 0)))
                             * decode(ps.class, 'CM', decode(ra.application_type, 'CM', -1, 1), 1))
                       , 0)
              into   amount_applied_late
              from   ar_receivable_applications ra, ar_payment_schedules ps
              where      (ra.applied_payment_schedule_id = p_payment_sched_id or ra.payment_schedule_id = p_payment_sched_id)
                     and ra.status || '' = 'APP'
                     and nvl(ra.confirmed_flag, 'Y') = 'Y'
                     and ra.gl_date + 0 > pg_in_as_of_date_low
                     and ps.payment_schedule_id = p_payment_sched_id;
            end if;

            c_amt_due_remaining := nvl(c_amt_due_remaining, 0) + amount_applied_late;
          end if;

          if p_amount_adjusted is not null
             and (p_invoice_type not in (lp_payment_meaning, lp_risk_meaning) and p_class <> 'CLAIM') then
            select sum(nvl(decode(pg_convert_flag, 'Y', acctd_amount, amount), 0))
            into   adjustments_amount
            from   ar_adjustments adj
            where      gl_date > pg_in_as_of_date_low
                   and payment_schedule_id = p_payment_sched_id
                   and status = 'A'
                   and adjustment_id < pg_adj_max_id;
            c_amt_due_remaining := nvl(c_amt_due_remaining, 0) - nvl(adjustments_amount, 0);
          end if;
        end if; /* :class = 'BR' */
      end if; /* pg_br_enabled = 'Y' */

      if    (to_number(c_amt_due_remaining) < pg_in_amt_due_low)
         or (to_number(c_amt_due_remaining) > pg_in_amt_due_high)
         or (to_number(c_amt_due_remaining) = 0) then
        c_amt_due_remaining := null;
        return (c_amt_due_remaining);
      end if;

      if pg_credit_option = 'SUMMARY' and p_class = 'PMT' then
        c_on_account_amount_cash := c_amt_due_remaining;
        c_amt_due_remaining := 0;
        return (0);
      end if;

      if pg_credit_option = 'SUMMARY' and p_class = 'CM' then
        c_on_account_amount_credit := c_amt_due_remaining;
        c_amt_due_remaining := 0;
        return (0);
      end if;

      if pg_risk_option = 'SUMMARY' and p_invoice_type = lp_risk_meaning then
        c_on_account_amount_risk := c_amt_due_remaining;
        c_amt_due_remaining := 0;
        return (0);
      end if;

      if pg_credit_option = 'SUMMARY' and p_class = 'CLAIM' then
        c_cust_amount_claim := c_amt_due_remaining;
        c_amt_due_remaining := 0;
        return (0);
      end if;

      if p_b0 = 1 then
        c_cust_b0 := c_amt_due_remaining;
        update xx_ar_aging_rpt_cust_gt
        set    b0 = c_cust_b0
        where  payment_sched_id = p_payment_sched_id
        and    rowid = p_row_id;                                                         ---Added By sumanth as part of the 8583#
      end if;

      if p_b1 = 1 then
        c_cust_b1 := c_amt_due_remaining;
        update xx_ar_aging_rpt_cust_gt
        set    b1 = c_cust_b1
        where  payment_sched_id = p_payment_sched_id
        and    rowid = p_row_id;                                                         ---Added By sumanth as part of the 8583#
      end if;

      if p_b2 = 1 then
        c_cust_b2 := c_amt_due_remaining;
        update xx_ar_aging_rpt_cust_gt
        set    b2 = c_cust_b2
        where  payment_sched_id = p_payment_sched_id
        and    rowid = p_row_id;                                                        ---Added By sumanth as part of the 8583#
      end if;

      if p_b3 = 1 then
        c_cust_b3 := c_amt_due_remaining;
        update xx_ar_aging_rpt_cust_gt
        set    b3 = c_cust_b3
        where  payment_sched_id = p_payment_sched_id
        and    rowid = p_row_id;                                                         ---Added By sumanth as part of the 8583#
      end if;

      if p_b4 = 1 then
        c_cust_b4 := c_amt_due_remaining;
        update xx_ar_aging_rpt_cust_gt
        set    b4 = c_cust_b4
        where  payment_sched_id = p_payment_sched_id
        and    rowid = p_row_id;                                                         ---Added By sumanth as part of the 8583#
      end if;

      if p_b5 = 1 then
        c_cust_b5 := c_amt_due_remaining;
        update xx_ar_aging_rpt_cust_gt
        set    b5 = c_cust_b5
        where  payment_sched_id = p_payment_sched_id
        and    rowid = p_row_id;                                                       ---Added By sumanth as part of the 8583#
      end if;  

      if p_b6 = 1 then
        c_cust_b6 := c_amt_due_remaining;
        update xx_ar_aging_rpt_cust_gt
        set    b6 = c_cust_b6
        where  payment_sched_id = p_payment_sched_id
        and    rowid = p_row_id;                                                        ---Added By sumanth as part of the 8583#
      end if;

      if p_data_converted is not null then
        c_data_converted_flag := 1;
      end if;

      --end loop;
      return (c_amt_due_remaining);
    end;
  end;

  function comp_amt_due_rem_invformula(p_class_inv in varchar2
                                     , p_cust_id_inv in number
                                     , p_invoice_type_inv in varchar2
                                     , p_amt_due_remaining_inv in number
                                     , p_payment_sched_id_inv in number
                                     , p_amount_applied_inv in number
                                     , p_amount_credited_inv in number
                                     , p_amount_adjusted_inv in number
                                     , p_data_converted_inv in varchar2
                                     , p_b0_inv in number
                                     , p_b1_inv in number
                                     , p_b2_inv in number
                                     , p_b3_inv in number
                                     , p_b4_inv in number
                                     , p_b5_inv in number
                                     , p_b6_inv in number
                                     , p_row_id in ROWID)                                        ---Added By sumanth as part of the 8583#
    return number is
    amount_applied_late number;
    adjustments_amount number;
    l_rev_gl_date date;
    l_status varchar2(25);

    cursor cncl_br(br_trx_id number) is
      select transaction_history_id
      from   ar_transaction_history
      where  customer_trx_id = br_trx_id and gl_date > pg_in_as_of_date_low and event = 'CANCELLED';

    cursor c is
      select *
      from   xx_ar_aging_rpt_inv_gt;

    br_trx_id number;
    ret_exch_amt number;
    c_amount_ch_inv number := 0;
    c_amount_cr_inv number := 0;
    c_amount_risk_inv number := 0;
    c_amount_claim_inv number := 0;
    c_inv_b0 number := 0;
    c_inv_b1 number := 0;
    c_inv_b2 number := 0;
    c_inv_b3 number := 0;
    c_inv_b4 number := 0;
    c_inv_b5 number := 0;
    c_inv_b6 number := 0;
    c_amt_due_rem_inv number := null;
    c_data_conv_flag_inv number := 0;
    c_data_conv_gsum_inv varchar2(100);
  begin
    c_amount_ch_inv := 0;
    c_amount_cr_inv := 0;
    c_amount_risk_inv := 0;
    c_amount_claim_inv := 0;
    c_inv_b0 := 0;
    c_inv_b1 := 0;
    c_inv_b2 := 0;
    c_inv_b3 := 0;
    c_inv_b4 := 0;
    c_inv_b5 := 0;
    c_inv_b6 := 0;
    c_amt_due_rem_inv := null;
    c_data_conv_flag_inv := 0;

    if pg_sort_option = 'T' then
      if (pg_credit_option = 'NONE') and ((p_class_inv = 'PMT') or (p_class_inv = 'CM')) then
        return (0);
      end if;

      if p_cust_id_inv is not null then
        if (pg_credit_option = 'SUMMARY') and ((p_class_inv = 'PMT') or (p_class_inv = 'CM')) then
          return (0);
        end if;

        if (pg_risk_option = 'SUMMARY') and (p_invoice_type_inv = lp_risk_meaning) then
          return (0);
        end if;
      end if;

      if (pg_risk_option = 'NONE') and (p_invoice_type_inv = lp_risk_meaning) then
        return (0);
      end if;
    else
      if (pg_credit_option = 'NONE') and ((p_class_inv = 'PMT') or (p_class_inv = 'CM')) then
        return (0);
      end if;

      if (pg_risk_option = 'NONE') and (p_invoice_type_inv = lp_risk_meaning) then
        return (0);
      end if;
    end if;

    if (pg_credit_option = 'NONE') and (p_class_inv = 'CLAIM') then
      return (0);
    end if;

    c_amt_due_rem_inv := p_amt_due_remaining_inv;

    if p_br_enabled = 'Y' then
      -- this section is for processing the BR itself
      if p_class_inv = 'BR' then
        select customer_trx_id
        into   br_trx_id
        from   ar_payment_schedules
        where  payment_schedule_id = p_payment_sched_id_inv;

        for j in cncl_br(br_trx_id) loop
          ret_exch_amt := 0;

          if pg_rep_type = 'ARXAGF' then
            select sum(decode(pg_convert_flag
                            , 'Y', decode(nvl(acctd_amount_cr, 0), 0, nvl(acctd_amount_dr, 0), (acctd_amount_cr * -1))
                            , decode(nvl(amount_cr, 0), 0, nvl(amount_dr, 0), (amount_cr * -1))))
            into   ret_exch_amt
            from   ar_xla_ard_lines_v
            where      source_table = 'TH'
                   and source_id = j.transaction_history_id
                   and source_id_secondary in (select customer_trx_line_id
                                               from   ra_customer_trx_lines
                                               where  customer_trx_id = br_trx_id);
          else
            select sum(decode(pg_convert_flag
                            , 'Y', decode(nvl(acctd_amount_cr, 0), 0, nvl(acctd_amount_dr, 0), (acctd_amount_cr * -1))
                            , decode(nvl(amount_cr, 0), 0, nvl(amount_dr, 0), (amount_cr * -1))))
            into   ret_exch_amt
            from   ar_distributions
            where      source_table = 'TH'
                   and source_id = j.transaction_history_id
                   and source_id_secondary in (select customer_trx_line_id
                                               from   ra_customer_trx_lines
                                               where  customer_trx_id = br_trx_id);
          end if;

          c_amt_due_rem_inv := nvl(c_amt_due_rem_inv, 0) + nvl(ret_exch_amt, 0);
        end loop;

        if p_amount_applied_inv is not null or p_amount_credited_inv is not null then
          if (p_invoice_type_inv not in (lp_payment_meaning, lp_risk_meaning) and p_class_inv <> 'CLAIM') then
            select nvl(sum(decode(pg_convert_flag
                                , 'Y', (decode(ps.class
                                             , 'CM', decode(ra.application_type
                                                          , 'CM', ra.acctd_amount_applied_from
                                                          , ra.acctd_amount_applied_to)
                                             , ra.acctd_amount_applied_to)
                                        + nvl(ra.acctd_earned_discount_taken, 0)
                                        + nvl(ra.acctd_unearned_discount_taken, 0))
                                , (ra.amount_applied + nvl(ra.earned_discount_taken, 0) + nvl(ra.unearned_discount_taken, 0)))
                           * decode(ps.class, 'CM', decode(ra.application_type, 'CM', -1, 1), 1))
                     , 0)
            into   amount_applied_late
            from   ar_receivable_applications ra, ar_payment_schedules ps
            where  (ra.applied_payment_schedule_id = p_payment_sched_id_inv or ra.payment_schedule_id = p_payment_sched_id_inv)
                   and ra.status || '' = 'APP'
                   and nvl(ra.confirmed_flag, 'Y') = 'Y'
                   and ra.gl_date + 0 > pg_in_as_of_date_low
                   and ps.payment_schedule_id = p_payment_sched_id_inv;
            c_amt_due_rem_inv := nvl(c_amt_due_rem_inv, 0) + amount_applied_late;
          end if;
        end if;

        if     p_amount_adjusted_inv is not null
           and p_invoice_type_inv not in (lp_payment_meaning, lp_risk_meaning)
           and p_class_inv <> 'CLAIM' then
          select sum(nvl(decode(pg_convert_flag, 'Y', acctd_amount, amount), 0))
          into   adjustments_amount
          from   ar_adjustments adj
          where      gl_date > pg_in_as_of_date_low
                 and payment_schedule_id = p_payment_sched_id_inv
                 and status = 'A'
                 and adjustment_id < pg_adj_max_id;
          c_amt_due_rem_inv := nvl(c_amt_due_rem_inv, 0) - nvl(adjustments_amount, 0);
        end if;
      end if; /* class_inv = 'BR' */
    end if;

    if    (to_number(c_amt_due_rem_inv) < pg_in_amt_due_low)
       or (to_number(c_amt_due_rem_inv) > pg_in_amt_due_high)
       or (to_number(c_amt_due_rem_inv) = 0) then
      c_amt_due_rem_inv := null;
      return (c_amt_due_rem_inv);
    end if;

    if pg_credit_option = 'SUMMARY' and p_class_inv = 'PMT' then
      select cr.status
      into   l_status
      from   ar_cash_receipts cr, ar_payment_schedules ps
      where  ps.payment_schedule_id = p_payment_sched_id_inv and ps.cash_receipt_id = cr.cash_receipt_id;

      if rtrim(l_status) = 'REV' then
        begin
          select crh.gl_date
          into   l_rev_gl_date
          from   ar_cash_receipt_history crh, ar_payment_schedules ps
          where      ps.payment_schedule_id = p_payment_sched_id_inv
                 and ps.cash_receipt_id = crh.cash_receipt_id
                 and crh.current_record_flag = 'Y'
                 and crh.status = 'REVERSED';

          if (pg_in_as_of_date_low < l_rev_gl_date) then
            c_amount_ch_inv := c_amt_due_rem_inv;
          end if;
        exception
          when no_data_found then
            null;
        end;
      else
        c_amount_ch_inv := c_amt_due_rem_inv;
      end if;

      c_amt_due_rem_inv := 0;
      return (0);
    end if;

    if pg_credit_option = 'SUMMARY' and p_class_inv = 'CM' then
      c_amount_cr_inv := c_amt_due_rem_inv;
      c_amt_due_rem_inv := 0;
      return (0);
    end if;

    if pg_credit_option = 'NONE' and (p_class_inv = 'CM' or p_class_inv = 'PMT') then
      return (c_amt_due_rem_inv);
    end if;

    if p_invoice_type_inv = lp_risk_meaning then
      if pg_risk_option = 'SUMMARY' then
        c_amount_risk_inv := c_amt_due_rem_inv;
        c_amt_due_rem_inv := 0;
        return (0);
      end if;

      if pg_risk_option = 'NONE' then
        return (c_amt_due_rem_inv);
      end if;
    end if;

    if pg_credit_option = 'SUMMARY' and p_class_inv = 'CLAIM' then
      c_amount_claim_inv := c_amt_due_rem_inv;
      c_amt_due_rem_inv := 0;
      return (0);
    end if;

    if p_b0_inv = 1 then
      c_inv_b0 := c_amt_due_rem_inv;
      update xx_ar_aging_rpt_inv_gt
      set    b0_inv = c_inv_b0
      where  payment_sched_id_inv = p_payment_sched_id_inv
      and    rowid = p_row_id;                                                            ---Added By sumanth as part of the 8583#
    end if;

    if p_b1_inv = 1 then
      c_inv_b1 := c_amt_due_rem_inv;
      update xx_ar_aging_rpt_inv_gt
      set    b1_inv = c_inv_b1
      where  payment_sched_id_inv = p_payment_sched_id_inv
      and    rowid = p_row_id;                                                           ---Added By sumanth as part of the 8583#
    end if;

    if p_b2_inv = 1 then
      c_inv_b2 := c_amt_due_rem_inv;
      update xx_ar_aging_rpt_inv_gt
      set    b2_inv = c_inv_b2
      where  payment_sched_id_inv = p_payment_sched_id_inv
      and    rowid = p_row_id;                                                           ---Added By sumanth as part of the 8583#
    end if;

    if p_b3_inv = 1 then
      c_inv_b3 := c_amt_due_rem_inv;
      update xx_ar_aging_rpt_inv_gt
      set    b3_inv = c_inv_b3
      where  payment_sched_id_inv = p_payment_sched_id_inv
      and    rowid = p_row_id;                                                          ---Added By sumanth as part of the 8583#
    end if;

    if p_b4_inv = 1 then
      c_inv_b4 := c_amt_due_rem_inv;
      update xx_ar_aging_rpt_inv_gt
      set    b4_inv = c_inv_b4
      where  payment_sched_id_inv = p_payment_sched_id_inv
      and    rowid = p_row_id;                                                     ---Added By sumanth as part of the 8583#  
    end if;

    if p_b5_inv = 1 then
      c_inv_b5 := c_amt_due_rem_inv;
      update xx_ar_aging_rpt_inv_gt
      set    b5_inv = c_inv_b5
      where  payment_sched_id_inv = p_payment_sched_id_inv
      and    rowid = p_row_id;                                                          ---Added By sumanth as part of the 8583#
    end if;

    if p_b6_inv = 1 then
      c_inv_b6 := c_amt_due_rem_inv;
      update xx_ar_aging_rpt_inv_gt
      set    b6_inv = c_inv_b6
      where  payment_sched_id_inv = p_payment_sched_id_inv
      and    rowid = p_row_id;                                                         ---Added By sumanth as part of the 8583#
    end if;

    if p_data_converted_inv is not null then
      c_data_conv_flag_inv := 1;
      c_data_conv_gsum_inv := '*';
    end if;

    return (c_amt_due_rem_inv);
  end;

procedure insert_data is
    l_insert long;
    l_sql clob;
    l_cust_select clob;
    l_inv_select clob;
    insert_cursor integer;
    insert_execute integer;
    l_amt_remain number;
    l_inv_amt_remain number;

    cursor c is
      select rowid,ag.*                                                                 ---Added By sumanth as part of the 8583#
      from   xx_ar_aging_rpt_cust_gt ag
      where amt_due_remaining<>0
      order by payment_sched_id;

    cursor c1 is
      select rowid,ag.*                                                                  ---Added By sumanth as part of the 8583#
      from   xx_ar_aging_rpt_inv_gt ag
      where amt_due_remaining_inv<>0
      order by payment_sched_id_inv;
	  /* trx_date column Added for case #6747 */
  begin
    if pg_in_summary_option_low = 'C' then
      l_insert := 'insert into xx_ar_aging_rpt_cust_gt (short_cust_name 
            , cust_id 
            , cust_no 
            , sort_field1 
            , sort_field2 
            , payment_sched_id 
            , class 
			, trx_date   
            , due_date 
            , amt_due_remaining 
            , days_past_due 
            , amount_adjusted 
            , amount_applied 
            , amount_credited 
            , gl_date 
            , data_converted 
            , ps_exchange_rate 
            , b0 
            , b1 
            , b2 
            , b3 
            , b4 
            , b5 
            , b6 
            , bal_segment_value 
            , inv_tid 
            , invoice_type )';
      l_insert := l_insert || new_line;
      l_cust_select := ' select 
                   rpad(''a'', 50, ''-'') short_cust_name
                 , 0 cust_id 
                 , rpad(''a'', 30, ''-'') cust_no
                 , rpad(''a'', 500, ''-'') sort_field1
                 , rpad(''a'', 40, ''-'') sort_field2
                 , 0 payment_sched_id
                 , rpad(''a'', 32, ''-'') class
				 , sysdate transaction_date
                 , sysdate due_date, 0 amt_due_remaining
                 , 0 days_past_due, 0 amount_adjusted
                 , 0 amount_applied, 0 amount_credited
                 , sysdate gl_date
                 , ''x'' data_converted
                 , 0 ps_exchange_rate
                 , 0 b0
                 , 0 b1
                 , 0 b2
                 , 0 b3
                 , 0 b4
                 , 0 b5
                 , 0 b6
                 , rpad(''a'', 25, ''-'') bal_segment_value
                 , rpad(''a'', 500, ''-'') inv_tid
                 , rpad(''a'', 32, ''-'') invoice_type
    from   dual
    where  1 = 2
    union all ';
      l_cust_select := l_cust_select || new_line;
      l_cust_select := l_cust_select || '$common_query_cus1$';
      --l_cust_select := l_cust_select || 'UNION ALL';
      --l_cust_select := l_cust_select || '$common_query_cus2$';
      l_cust_select := l_cust_select || new_line;
      l_cust_select := l_cust_select || ' UNION ALL ';
      l_cust_select := l_cust_select || new_line;
      l_cust_select := l_cust_select || '$common_query_cus3$';
      l_cust_select := l_cust_select || new_line;
      --l_cust_select := l_cust_select || ' UNION ALL ';
      --l_cust_select := l_cust_select || new_line;
      l_cust_select := l_cust_select || ' $common_query_cus4$';
      l_cust_select := l_cust_select || new_line;
      l_cust_select := l_cust_select || 'UNION ALL';
      l_cust_select := l_cust_select || new_line;
      l_cust_select := l_cust_select || '$common_query_cus5$';
      l_sql := l_insert || l_cust_select;
      l_sql := replace(l_sql, '$common_query_cus1$', l_cus_sel1);
      l_sql := replace(l_sql, '$common_query_cus3$', l_cus_sel3);
      l_sql := replace(l_sql, '$common_query_cus4$', l_cus_sel4);
      l_sql := replace(l_sql, '$common_query_cus5$', l_cus_sel5);
      --debug(l_sql);
      -- print_clob(l_sql);
      --insert into xx_ar_aging_sqls
      --values      (l_sql);
    elsif pg_in_summary_option_low = 'I' then
      l_insert := 'insert into xx_ar_aging_rpt_inv_gt (cust_name_inv 
                , cust_no_inv 
                , sort_field1_inv 
                , sort_field2_inv 
                , inv_tid_inv 
                , contact_site_id_inv 
                , cust_state_inv 
                , cust_city_inv 
                , addr_id_inv 
                , cust_id_inv 
                , payment_sched_id_inv 
                , class_inv 
				, trx_date    
                , due_date_inv 
                , amt_due_remaining_inv 
                , invnum 
                , days_past_due 
                , amount_adjusted_inv 
                , amount_applied_inv 
                , amount_credited_inv 
                , gl_date_inv 
                , data_converted_inv 
                , ps_exchange_rate_inv 
                , b0_inv 
                , b1_inv 
                , b2_inv 
                , b3_inv 
                , b4_inv 
                , b5_inv 
                , b6_inv 
                , company_inv 
                , cons_billing_number 
                , invoice_type_inv )';
      l_insert := l_insert || new_line;
      l_inv_select := 'select  
            rpad(''a'',50,''-'')      cust_name_inv,
            rpad(''a'',30,''-'')      cust_no_inv,
            rpad(''a'',4000,''-'')    sort_field1_inv,
            rpad(''a'',4000,''-'')    sort_field2_inv,
            0                         inv_tid_inv,
            0                          contact_site_id_inv,
            rpad(''a'',60,''-'')       cust_state_inv,
            rpad(''a'',60,''-'')  cust_city_inv,
            0                     addr_id_inv,
            0                     cust_id_inv,
            0                     payment_sched_id_inv,
            rpad(''a'',20,''-'')  class_inv,
			sysdate               transaction_date_inv,   
            sysdate               due_date_inv,
            0                     amt_due_remaining_inv,
            rpad(''a'',30,''-'')  invnum,
            0                     days_past_due,
            0                     amount_adjusted_inv,
            0                     amount_applied_inv,
            0                     amount_credited_inv,
            sysdate               gl_date_inv,
            ''x''                 data_converted_inv,
             0                    ps_exchange_rate_inv,
             0                    b0_inv,
             0                    b1_inv,
             0                    b2_inv,
             0                    b3_inv,
             0                    b4_inv,
             0                    b5_inv,
             0                    b6_inv,
            rpad(''a'',25,''-'')  company_inv,
            rpad(''a'',30,''-'')  cons_billing_number,
            rpad(''a'',32,''-'')  invoice_type_inv
    from    dual
    where   1=2
    UNION ALL ';
      l_inv_select := l_inv_select || new_line;
      l_inv_select := l_inv_select || '$common_query_inv1$';
      l_inv_select := l_inv_select || new_line;
      l_inv_select := l_inv_select || ' UNION ALL ';
      l_inv_select := l_inv_select || new_line;
      l_inv_select := l_inv_select || '$common_query_inv3$';
      l_inv_select := l_inv_select || ' UNION ALL ';
      l_inv_select := l_inv_select || '$common_query_inv4$';
      l_inv_select := l_inv_select || new_line;
      l_inv_select := l_inv_select || ' UNION ALL ';
      l_inv_select := l_inv_select || '$common_query_inv5$';
      l_sql := l_insert || l_inv_select;
      l_sql := replace(l_sql, '$common_query_inv1$', l_inv_sel1);
      l_sql := replace(l_sql, '$common_query_inv3$', l_inv_sel3);
      l_sql := replace(l_sql, '$common_query_inv4$', l_inv_sel4);
      l_sql := replace(l_sql, '$common_query_inv5$', l_inv_sel5);
      --debug(l_sql);
      --insert into xx_ar_aging_sqls
      --values      (l_sql);
    end if;

    insert_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(insert_cursor, l_sql, dbms_sql.native);
    bind_parameters(insert_cursor);
    debug('Done binding');
    insert_execute := dbms_sql.execute(insert_cursor);
    dbms_sql.close_cursor(insert_cursor);

    for i in c loop
      l_amt_remain := comp_amt_due_remainingformula(i.payment_sched_id
                                                  , i.class
                                                  , i.amount_adjusted
                                                  , i.data_converted
                                                  , i.invoice_type
                                                  , i.amount_applied
                                                  , i.amount_credited
                                                  , i.amt_due_remaining
                                                  , i.b0
                                                  , i.b1
                                                  , i.b2
                                                  , i.b3
                                                  , i.b4
                                                  , i.b5
                                                  , i.b6
                                                  ,i.rowid);                            ---Added By sumanth as part of the 8583#
    end loop;

    for i in c1 loop
      l_inv_amt_remain := comp_amt_due_rem_invformula(i.class_inv
                                                    , i.cust_id_inv
                                                    , i.invoice_type_inv
                                                    , i.amt_due_remaining_inv
                                                    , i.payment_sched_id_inv
                                                    , i.amount_applied_inv
                                                    , i.amount_credited_inv
                                                    , i.amount_adjusted_inv
                                                    , i.data_converted_inv
                                                    , i.b0_inv
                                                    , i.b1_inv
                                                    , i.b2_inv
                                                    , i.b3_inv
                                                    , i.b4_inv
                                                    , i.b5_inv
                                                    , i.b6_inv
                                                    , i.rowid);                               ---Added By sumanth as part of the 8583#
    end loop;

    if pg_in_summary_option_low = 'I' then
      update xx_ar_aging_rpt_inv_gt a
      set    collector = (select ac.name
                          from   hz_customer_profiles hcp, ar_collectors ac
                          where      site_use_id is null
                                 and hcp.cust_account_id = a.cust_id_inv
                                 and hcp.collector_id = ac.collector_id);
      debug('records updated in xx_ar_aging_rpt_inv_gt for collector:' || sql%rowcount);
      update xx_ar_aging_rpt_inv_gt a
      set    customer_class = (select al.meaning
                               from   hz_cust_accounts hca, ar_lookups al
                               where      hca.customer_class_code = al.lookup_code
                                      and hca.cust_account_id = a.cust_id_inv
                                      and al.lookup_type = 'CUSTOMER CLASS');
      debug('records updated in xx_ar_aging_rpt_inv_gt for customer class:' || sql%rowcount);
      update xx_ar_aging_rpt_inv_gt a1
      set    country = (select max(hl.country)
                        from   hz_cust_accounts a, hz_cust_acct_sites b, hz_cust_site_uses c, hz_party_sites d, hz_locations hl
                        where      a.cust_account_id = b.cust_account_id
                               and b.cust_acct_site_id = c.cust_acct_site_id
                               and a.cust_account_id = a1.cust_id_inv
                               and c.site_use_code = 'BILL_TO'
                               and nvl(c.status, 'A') = 'A'
                               and nvl(b.status, 'A') = 'A'
                               and primary_flag = 'Y'
                               --and b.org_id=pg_param_org_id
                               and b.party_site_id = d.party_site_id
                               and d.location_id = hl.location_id);
      debug('records updated in xx_ar_aging_rpt_inv_gt for Bill To Country:' || sql%rowcount);
	  /* Added for case #6747 */
	  update xx_ar_aging_rpt_inv_gt a1
      set    state = (select max(hl.state)
                        from   hz_cust_accounts a, hz_cust_acct_sites b, hz_cust_site_uses c, hz_party_sites d, hz_locations hl
                        where      a.cust_account_id = b.cust_account_id
                               and b.cust_acct_site_id = c.cust_acct_site_id
                               and a.cust_account_id = a1.cust_id_inv
                               and c.site_use_code = 'BILL_TO'
                               and nvl(c.status, 'A') = 'A'
                               and nvl(b.status, 'A') = 'A'
                               and primary_flag = 'Y'
                               --and b.org_id=pg_param_org_id
                               and b.party_site_id = d.party_site_id
                               and d.location_id = hl.location_id);
      debug('records updated in xx_ar_aging_rpt_inv_gt for Bill To state:' || sql%rowcount);

      if pg_in_collector is not null then
        delete xx_ar_aging_rpt_inv_gt
        where  nvl(collector, '###') <> pg_in_collector;
      end if;

      if pg_in_customer_class is not null then
        delete xx_ar_aging_rpt_inv_gt
        where  nvl(customer_class, '###') <> pg_in_customer_class;
      end if;

      if pg_in_country is not null then
        delete xx_ar_aging_rpt_inv_gt
        where  nvl(country, '###') <> (select territory_short_name from fnd_territories_vl where territory_code=pg_in_country);
      end if;
	  if pg_in_state is not null then
        delete xx_ar_aging_rpt_inv_gt
        where  nvl(STATE, '###') <> (SELECT   state
                                               FROM   hz_locations
                                              WHERE   state = pg_in_state);
      end if;
       if pg_in_account is not null then
        debug('delete xx_ar_aging_rpt_inv_gt where sort_field1_inv not like ''%'||pg_in_account||'%''');
        execute immediate 'delete xx_ar_aging_rpt_inv_gt where sort_field1_inv not like ''%'||pg_in_account||'%''';
      end if;
    end if;

    if pg_in_summary_option_low = 'C' then
      update xx_ar_aging_rpt_cust_gt a
      set    collector = (select ac.name
                          from   hz_customer_profiles hcp, ar_collectors ac
                          where  site_use_id is null and hcp.cust_account_id = a.cust_id and hcp.collector_id = ac.collector_id);
      debug('records updated in xx_ar_aging_rpt_cust_gt for collector:' || sql%rowcount);
      update xx_ar_aging_rpt_cust_gt a
      set    customer_class = (select al.meaning
                               from   hz_cust_accounts hca, ar_lookups al
                               where      hca.customer_class_code = al.lookup_code
                                      and hca.cust_account_id = a.cust_id
                                      and al.lookup_type = 'CUSTOMER CLASS');
      debug('records updated in xx_ar_aging_rpt_cust_gt for customer class:' || sql%rowcount);
      update xx_ar_aging_rpt_cust_gt a1
      set    country = (select max(fnd.territory_short_name)
                        from   hz_cust_accounts a, hz_cust_acct_sites b, hz_cust_site_uses c, hz_party_sites d, hz_locations hl,fnd_territories_vl fnd
                        where      a.cust_account_id = b.cust_account_id
                               and b.cust_acct_site_id = c.cust_acct_site_id
                               and a.cust_account_id = a1.cust_id
                               and c.site_use_code = 'BILL_TO'
                               and nvl(c.status, 'A') = 'A'
                               and nvl(b.status, 'A') = 'A'
                               and primary_flag = 'Y'                               
                               and b.party_site_id = d.party_site_id
                               and d.location_id = hl.location_id
                               and hl.country=fnd.territory_code);
      debug('records updated in xx_ar_aging_rpt_cust_gt for Bill To Country:' || sql%rowcount);
	  /* Added for case #6747 */
	   update xx_ar_aging_rpt_cust_gt a1
      set    state = (select max(hl.state)
                        from   hz_cust_accounts a, hz_cust_acct_sites b, hz_cust_site_uses c, hz_party_sites d, hz_locations hl,fnd_territories_vl fnd
                        where      a.cust_account_id = b.cust_account_id
                               and b.cust_acct_site_id = c.cust_acct_site_id
                               and a.cust_account_id = a1.cust_id
                               and c.site_use_code = 'BILL_TO'
                               and nvl(c.status, 'A') = 'A'
                               and nvl(b.status, 'A') = 'A'
                               and primary_flag = 'Y'                               
                               and b.party_site_id = d.party_site_id
                               and d.location_id = hl.location_id
                               and hl.country=fnd.territory_code);
      debug('records updated in xx_ar_aging_rpt_cust_gt for Bill To State:' || sql%rowcount);

      if pg_in_collector is not null then
        delete xx_ar_aging_rpt_cust_gt
        where  nvl(collector, '###') <> pg_in_collector;
      end if;

      if pg_in_customer_class is not null then
        delete xx_ar_aging_rpt_cust_gt
        where  nvl(customer_class, '###') <> pg_in_customer_class;
      end if;

      if pg_in_country is not null then
        delete xx_ar_aging_rpt_cust_gt
        where  nvl(country, '###') <> pg_in_country;
      END IF;
	  /* Added for case #6747 */
	  if pg_in_state is not null then
        delete xx_ar_aging_rpt_cust_gt
        where  nvl(state, '###') <> pg_in_state;
      end if;
      if pg_in_account is not null then
        execute immediate 'delete xx_ar_aging_rpt_cust_gt where sort_field1 not like ''%'||pg_in_account||'%''';
      end if;
    end if;

    debug('Done executing');
  exception
    when others then
      if dbms_sql.is_open(insert_cursor) then
        dbms_sql.close_cursor(insert_cursor);
      end if;

      debug(sqlerrm);
  end;
  FUNCTION get_report_heading RETURN VARCHAR2 IS
  CURSOR buc_info_cur IS
    select report_heading1,
           report_heading2
    from ar_aging_bucket_lines lines,
         ar_aging_buckets buckets
    where lines.aging_bucket_id = buckets.aging_bucket_id
    and   UPPER(buckets.bucket_name) = UPPER(pg_in_bucket_type_low)
    and   NVL(buckets.status,'A') = 'A'
    order by lines.bucket_sequence_num;

l_report_heading  VARCHAR2(32767) := '';
i              NUMBER(1)       := 0;
l_new_line        VARCHAR2(100)     := '
';

BEGIN
  
    debug(  'AR_AGING_BUCKETS_PKG.get_report_heading()+');
  

  FOR buc_rec IN buc_info_cur LOOP
    IF buc_rec.report_heading2 IS NULL THEN
    l_report_heading := l_report_heading ||l_new_line||
         '<HEAD_TOP_'||i||'></HEAD_TOP_'||i||'>';
        l_report_heading := l_report_heading ||l_new_line||
         '<HEAD_BOT_'||i||'>'||buc_rec.report_heading1||'</HEAD_BOT_'||i||'>';
    ELSE
        l_report_heading := l_report_heading ||l_new_line||
         '<HEAD_TOP_'||i||'>'||buc_rec.report_heading1||'</HEAD_TOP_'||i||'>';
        l_report_heading := l_report_heading ||l_new_line||
         '<HEAD_BOT_'||i||'>'||buc_rec.report_heading2||'</HEAD_BOT_'||i||'>';
    END IF;

      debug(  'report_heading1: '||buc_rec.report_heading1);
      debug(  'report_heading2: '||buc_rec.report_heading2);
    

    i := i + 1;

  END LOOP;

  debug(  'AR_AGING_BUCKETS_PKG.get_report_heading()-');
  

  RETURN l_report_heading;

  EXCEPTION
    WHEN OTHERS THEN
    debug(  ' Exception '||SQLERRM);
    debug(  ' Exception AR_AGING_BUCKETS_PKG.get_report_heading()');
      
      
END get_report_heading;
  FUNCTION get_report_header_xml RETURN VARCHAR2 IS
l_message    VARCHAR2(2000);
l_xml_header VARCHAR2(32000);

BEGIN
    debug(  'AR_AGING_BUCKETS_PKG.get_report_header_xml()+');
 

  IF to_number(pg_reporting_level) = 1000 AND
     mo_utils.check_ledger_in_sp(TO_NUMBER(pg_reporting_entity_id)) = 'N' THEN
    FND_MESSAGE.SET_NAME('FND','FND_MO_RPT_PARTIAL_LEDGER');
    l_message := FND_MESSAGE.get;
  END IF;

  l_xml_header := '<?xml version="1.0" encoding="'||fnd_profile.value('ICX_CLIENT_IANA_ENCODING')||'"?>
<ARAGEREP>
<MSG_TXT>'||l_message||'</MSG_TXT>
<COMPANY_NAME>'||pg_company_name||'</COMPANY_NAME>
<REPORTING_LEVEL>'||pg_reporting_level_name||'</REPORTING_LEVEL>
<REPORTING_ENTITY>'||pg_reporting_entity_name||'</REPORTING_ENTITY>
<BAL_SEG_LOW>'||pg_in_bal_segment_low||'</BAL_SEG_LOW>
<BAL_SEG_HIGH>'||pg_in_bal_segment_high||'</BAL_SEG_HIGH>
<AS_OF_GL_DATE>'||TO_CHAR(pg_in_as_of_date_low,'YYYY-MM-DD')||'</AS_OF_GL_DATE>
<SUMMARY_TYPE>'||pg_in_summary_option_low||'</SUMMARY_TYPE>
<SUMMARY_TYPE_MEANING>'||ARPT_SQL_FUNC_UTIL.get_lookup_meaning('REPORT_TYPE',pg_in_summary_option_low)||'</SUMMARY_TYPE_MEANING>
<REPORT_FORMAT>'||pg_in_format_option_low||'</REPORT_FORMAT>
<REPORT_FORMAT_MEANING>'||ARPT_SQL_FUNC_UTIL.get_lookup_meaning('REPORT_FORMAT',pg_in_format_option_low)||'</REPORT_FORMAT_MEANING>
<BUCKET_NAME>'||pg_in_bucket_type_low||'</BUCKET_NAME>
<CREDIT_OPTION>'||pg_credit_option||'</CREDIT_OPTION>
<CREDIT_OPTION_MEANING>'||ARPT_SQL_FUNC_UTIL.get_lookup_meaning('OPEN_CREDITS',pg_credit_option)||'</CREDIT_OPTION_MEANING>
<RISK_OPTION>'||pg_risk_option||'</RISK_OPTION>
<RISK_OPTION_MEANING>'||ARPT_SQL_FUNC_UTIL.get_lookup_meaning('SHOW_RISK',pg_risk_option)||'</RISK_OPTION_MEANING>
<CURRENCY>'||pg_in_currency||'</CURRENCY>
<CUST_NAME_LOW><![CDATA['||pg_in_customer_name_low||']]> </CUST_NAME_LOW>
<CUST_NAME_HIGH><![CDATA['||pg_in_customer_name_high||']]></CUST_NAME_HIGH>
<CUST_NUM_LOW>'||pg_in_customer_num_low||'</CUST_NUM_LOW>
<CUST_NUM_HIGH>'||pg_in_customer_num_high||'</CUST_NUM_HIGH>
<CUSTOMER_CLASS>'||pg_in_customer_class||'</CUSTOMER_CLASS>
<COLLECTOR><![CDATA['||pg_in_collector||']]> </COLLECTOR>
<COLLECTOR_LOW><![CDATA['||pg_in_collector_low||']]> </COLLECTOR_LOW>
<COLLECTOR_HIGH><![CDATA['||pg_in_collector_high||']]></COLLECTOR_HIGH>
<SALESREP_LOW><![CDATA['||pg_in_salesrep_low||']]> </SALESREP_LOW>
<SALESREP_HIGH><![CDATA['||pg_in_salesrep_high||']]></SALESREP_HIGH>
<COUNTRY><![CDATA['||pg_in_country||']]></COUNTRY>
<STATE><![CDATA['||pg_in_state||']]></STATE>
<AMT_DUE_LOW>'||pg_in_amt_due_low||'</AMT_DUE_LOW>
<AMT_DUE_HIGH>'||pg_in_amt_due_high||'</AMT_DUE_HIGH>
<INV_TYPE_LOW>'||pg_in_invoice_type_low||'</INV_TYPE_LOW>
<INV_TYPE_HIGH>'||pg_in_invoice_type_high||'</INV_TYPE_HIGH>
<CONS_PROFILE_VALUE>'||pg_cons_profile_value||'</CONS_PROFILE_VALUE>
<FUNC_CURRENCY>'||pg_functional_currency||'</FUNC_CURRENCY>
<RISK_MEANING>'||pg_risk_meaning||'</RISK_MEANING>'||get_report_heading();

    debug(  'AR_AGING_BUCKETS_PKG.get_report_header_xml()-');
 
  RETURN l_xml_header;

  EXCEPTION
   WHEN OTHERS THEN
    debug(  'Exception message '||SQLERRM);
    debug(  'Exception AR_AGING_BUCKETS_PKG.get_report_header_xml()');
    RETURN NULL;
END get_report_header_xml;
procedure generate_report is
l_report_header varchar2(32000);
  cursor cust_aging is
    select   case when cust_id=-999 then 'Unidentified Payment' else short_cust_name end customer_name
           , cust_no customer_number
           , sort_field1 sort_field1
           , sort_field2 code_combination_id
           , sum(amt_due_remaining) amt_due_remaining
           , sum(b0) b_0
           , sum(b1) b_1
           , sum(b2) b_2
           , sum(b3) b_3
           , sum(b4) b_4
           , sum(b5) b_5
           , sum(b6) b_6
           , collector
           , customer_class
           , COUNTRY
           , State
	-- , trx_date   /* Added for case #6747 */ 
    from     xx_ar_aging_rpt_cust_gt a
    where amt_due_remaining<>0
    group by short_cust_name
           , cust_no
           , sort_field1
           , sort_field2
           , COUNTRY
           , State
	 --, trx_date   /* Added for case #6747 */ 
           , collector
           , customer_class
           , cust_id
    order by 3, 1;

  cursor inv_aging is
    select   case when cust_id_inv=-999 then 'Unidentified Payment' else cust_name_inv end customer_name
           , cust_no_inv customer_number
           , sort_field1_inv sort_field1
           , sort_field2_inv trx_type
           , inv_tid_inv code_combination_id
           , class_inv invoice_type
	   , trx_Date		 trx_date   /* Added for case #6747 */
           , due_date_inv due_date
           , sum(amt_due_remaining_inv) amt_due_remaining
           , invnum trx_number
           , sum(b0_inv) b_0
           , sum(b1_inv) b_1
           , sum(b2_inv) b_2
           , sum(b3_inv) b_3
           , sum(b4_inv) b_4
           , sum(b5_inv) b_5
           , sum(b6_inv) b_6
           , collector
           , customer_class
           , country
	   , state
    from     xx_ar_aging_rpt_inv_gt
    where amt_due_remaining_inv<>0
    group by cust_name_inv
           , cust_no_inv
           , sort_field1_inv
           , sort_field2_inv
           , inv_tid_inv
           , class_inv
           , due_date_inv
           , invnum
           , collector
           , customer_class
           , country
	   , state
	   , trx_date   /* Added for case #6747 */
           , cust_id_inv
    order by 3,2,9;
begin

  if pg_in_summary_option_low = 'C' then
  l_report_header:=get_report_header_xml;
  fnd_file.put_line(fnd_file.output, l_report_header);
    for i in cust_aging loop
    fnd_file.put_line(fnd_file.output, '<ROW>');
      print_xml_element('SORT_FIELD1', i.sort_field1);
      print_xml_element('CUSTOMER_NAME', i.customer_name);
      print_xml_element('CUSTOMER_NUMBER', i.customer_number);
      print_xml_element('CUSTOMER_CLASS', i.customer_class);
      print_xml_element('COUNTRY', i.country);
      print_xml_element('STATE', i.state);  /* Added for case #6747 */
      print_xml_element('COLLECTOR', i.collector);      
      print_xml_element('INVOICE_TYPE', to_char(null));
      print_xml_element('TRX_NUMBER', to_char(null));
    --print_xml_element('TRX_DATE', i.trx_date);    /* Added for case #6747 */
      print_xml_element('TRX_DATE', to_char(null)); /* Added for case #6747 */
      print_xml_element('DUE_DATE', to_char(null));
      print_xml_element('AMT_DUE_REMAINING', i.amt_due_remaining);
      print_xml_element('B_0', i.b_0);
      print_xml_element('B_1', i.b_1);
      print_xml_element('B_2', i.b_2);
      print_xml_element('B_3', i.b_3);
      print_xml_element('B_4', i.b_4);
      print_xml_element('B_5', i.b_5);
      print_xml_element('B_6', i.b_6);
      fnd_file.put_line(fnd_file.output, '</ROW>');
    end loop;
    fnd_file.put_line(fnd_file.output, '</ARAGEREP>');
  elsif pg_in_summary_option_low = 'I' then
  l_report_header:=get_report_header_xml;
  fnd_file.put_line(fnd_file.output, l_report_header);
    for i in inv_aging loop
    fnd_file.put_line(fnd_file.output, '<ROW>');
      print_xml_element('CUSTOMER_NAME', i.customer_name);
      print_xml_element('CUSTOMER_NUMBER', i.customer_number);
      print_xml_element('SORT_FIELD1', i.sort_field1);
      print_xml_element('CUSTOMER_CLASS', i.customer_class);
      print_xml_element('COUNTRY', i.country);
      print_xml_element('STATE', i.state); /* Added for case #6747 */
      print_xml_element('COLLECTOR', i.collector);
      print_xml_element('AMT_DUE_REMAINING', i.amt_due_remaining);
      print_xml_element('INVOICE_TYPE', i.invoice_type);
      print_xml_element('TRX_NUMBER', i.trx_number);
      print_xml_element('TRX_DATE', i.trx_date);     /* Added for case #6747 */
      print_xml_element('DUE_DATE', i.due_date);
      print_xml_element('B_0', i.b_0);
      print_xml_element('B_1', i.b_1);
      print_xml_element('B_2', i.b_2);
      print_xml_element('B_3', i.b_3);
      print_xml_element('B_4', i.b_4);
      print_xml_element('B_5', i.b_5);
      print_xml_element('B_6', i.b_6);
      fnd_file.put_line(fnd_file.output, '</ROW>');
    end loop;
    fnd_file.put_line(fnd_file.output, '</ARAGEREP>');
  end if;
end;

  procedure main(xerrbuf   out varchar2
               , xretcode   out varchar2
               , p_rep_type in varchar2
               , p_reporting_level in varchar2
               , p_reporting_entity_id in varchar2
               , p_operating_unit_id in number
               --, p_ca_set_of_books_id in number
               , p_coaid in number
               , p_in_bal_segment_low in varchar2
               , p_in_bal_segment_high in varchar2
               , p_in_as_of_date_low in varchar2
               , p_in_summary_option_low in varchar2
               , p_in_format_option_low in varchar2
               , p_in_bucket_type_low in varchar2
               , p_credit_option in varchar2
               , p_risk_option in varchar2
               , p_in_currency in varchar2
               , p_in_customer_name_low in varchar2
               , p_in_customer_name_high in varchar2
               , p_in_customer_num_low in varchar2
               , p_in_customer_num_high in varchar2
               , p_in_amt_due_low in number
               , p_in_amt_due_high in number
               , p_in_invoice_type_low in varchar2
               , p_in_invoice_type_high in varchar2
               --, p_in_collector_low in varchar2
               --, p_in_collector_high in varchar2
               --, p_in_salesrep_low in varchar2
               --, p_in_salesrep_high in varchar2
               , p_in_customer_class in varchar2
               , p_in_collector in varchar2
               , p_in_country in varchar2
			 --  , p_in_state  in varchar2
               , p_in_account in varchar2) is
    l_result boolean;
  begin
    pg_rep_type := p_rep_type;
    pg_reporting_level := to_number(nvl(p_reporting_level, 0));
    pg_reporting_entity_id := to_number(nvl(p_reporting_entity_id, 0));
    pg_coaid := to_number(nvl(p_coaid, 0));
    pg_in_bal_segment_low := p_in_bal_segment_low;
    pg_in_bal_segment_high := p_in_bal_segment_high;
    pg_in_as_of_date_low := fnd_date.canonical_to_date(p_in_as_of_date_low);
    pg_in_summary_option_low := p_in_summary_option_low;
    pg_in_format_option_low := p_in_format_option_low;
    pg_in_bucket_type_low := p_in_bucket_type_low;
    pg_credit_option := p_credit_option;
    pg_risk_option := p_risk_option;
    pg_in_currency := p_in_currency;
    pg_in_customer_name_low := p_in_customer_name_low;
    pg_in_customer_name_high := p_in_customer_name_high;
    pg_in_customer_num_low := p_in_customer_num_low;
    pg_in_customer_num_high := p_in_customer_num_high;
    pg_in_invoice_type_low := p_in_invoice_type_low;
    pg_in_invoice_type_high := p_in_invoice_type_high;
    pg_in_amt_due_low := p_in_amt_due_low;
    pg_in_amt_due_high := p_in_amt_due_high;
   -- pg_in_collector_low := p_in_collector_low;
   -- pg_in_collector_high := p_in_collector_high;
   --pg_in_salesrep_low := p_in_salesrep_low;
   -- pg_in_salesrep_high := p_in_salesrep_high;
   pg_in_collector_low := NULL;
   pg_in_collector_high := NULL;
   pg_in_salesrep_low := NULL;
   pg_in_salesrep_high := NULL;
    pg_in_sortoption := 'CUSTOMER';
    pg_in_customer_class := p_in_customer_class;
    pg_in_collector := p_in_collector;
    pg_in_country := p_in_country;
	  pg_in_state :=NULL;    /* Added for case #6747 */
    pg_in_account:=p_in_account;
    pg_param_org_id:=p_operating_unit_id;
    mo_global.set_policy_context('S',pg_param_org_id);
    l_result := initialize;
    insert_data;
    generate_report;
    exception when others then
    debug('Exception in main program: '||sqlerrm);
  end;
END XX_AR_AGING_XML_RPT_PKG;
/
