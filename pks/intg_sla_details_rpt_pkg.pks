DROP PACKAGE APPS.INTG_SLA_DETAILS_RPT_PKG;

CREATE OR REPLACE PACKAGE APPS."INTG_SLA_DETAILS_RPT_PKG" as
  g_ledger_id number;
  g_ledger_name varchar(30);
  g_date_from date;
  g_date_to date;
  g_ep_request_ids dbms_sql.number_table;
  l_ignore integer;
  c integer;
  g_report_view_tbl dbms_sql.varchar2_table;
  g_report_request_id number;
  crlf constant varchar2(1) := '
';
  g_parent_request_id number;
  g_worker_id number;
  g_sub_acct_from varchar2(100);
  g_sub_acct_to varchar2(100);
  g_natural_acct_from varchar2(100);
  g_natural_acct_to varchar2(100);
  g_company_code varchar2(100);
  g_period_num_from number;
  g_period_num_to number;
  g_period_name_from number;
  g_period_name_to number;
  g_period_from varchar2(100);
  g_period_to varchar2(100);
  g_ledger_category_code varchar2(20);
  g_reporting_center_from varchar2(100);
  g_reporting_center_to varchar2(100);
  g_primary_ledger_id number;
  p_parent_request_id number;
  lp_where_clause varchar2(400);
  p_output_format varchar2(100);

  procedure debug(p_msg in varchar2);

  procedure generate_xml(error_string   out varchar2
                       , return_status   out number
                       , p_ledger_id in number
                       , p_company_code in varchar2
                       , p_reporting_center_from in varchar2
                       , p_reporting_center_to in varchar2
                       , p_natural_acct_from in varchar2
                       , p_natural_acct_to in varchar2
                       , p_sub_acct_from in varchar2
                       , p_sub_acct_to in varchar2
                       , p_period_from in varchar2
                       , p_period_to in varchar2
                       , p_number_of_workers in number
                       , p_output_format in varchar2);

  function get_view_columns(p_reporting_view in varchar2)
    return varchar2;

  function get_app_view_columns(p_app_id in number, p_reporting_view in varchar2)
    return varchar2;

  procedure wait_for_requests(p_array_request_id in dbms_sql.number_table
                            , p_error_status   out nocopy varchar2
                            , p_warning_status   out nocopy varchar2);

  procedure launch_child_requests(p_parent_request_id in number, p_worker_tbl dbms_sql.number_table);

  procedure worker_collection(xerrbuf out varchar2, xretcode out varchar2, p_parent_request_id in number, p_worker_id in number);

  function get_exp_org_name(p_exp_org_id in number)
    return varchar2;

  function get_project_number(p_project_id in number)
    return varchar2;

  function get_task_number(p_task_id in number)
    return varchar2;

  procedure update_ap_info;

  procedure update_ar_info;

  procedure update_cst_info;

  procedure update_fa_info;

  function before_report
    return boolean;

  function return_quantity(p_quantity IN NUMBER, p_accounted_net IN NUMBER)
  return NUMBER;

  procedure generate_csv_report(errbuf out varchar2, retcode out varchar2, p_request_id in number, p_output_format in varchar2);

  procedure launch_report(p_parent_request_id in number, p_report_name in varchar2, p_output_format in varchar2);

  procedure cleanup_staging_tables(errbuf out varchar2, retcode out number, p_report_request_id in number);
end intg_sla_details_rpt_pkg;
/
