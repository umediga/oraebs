DROP PACKAGE APPS.XX_AR_AGING_XML_RPT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_AGING_XML_RPT_PKG" as
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
  | 15-DEC-2015           Raviteja (NTT)    Case#6747 - State and TRX date   |
  *==========================================================================*/
 ar_aging_ctgry_invoice varchar2(20) := 'INVOICE';
  ar_aging_ctgry_receipt varchar2(20) := 'RECEIPT';
  ar_aging_ctgry_risk varchar2(20) := 'RISK';
  ar_aging_ctgry_br varchar2(20) := 'BILLS_RECEIVABLE';
  --
  pg_org_where_ps varchar2(2000) := null;
  pg_org_where_gld varchar2(2000) := null;
  pg_org_where_ct varchar2(2000) := null;
  pg_org_where_sales varchar2(2000) := null;
  pg_org_where_ct2 varchar2(2000) := null;
  pg_org_where_adj varchar2(2000) := null;
  pg_org_where_app varchar2(2000) := null;
  pg_org_where_crh varchar2(2000) := null;
  pg_org_where_ra varchar2(2000) := null;
  pg_org_where_cr varchar2(2000) := null;
  pg_org_where_sys_param varchar2(2000) := null;
  pg_bal_seg_where varchar2(2000) := null;
  pg_adj_max_id number;
  --
  pg_rep_type varchar2(30);
  pg_reporting_level varchar2(30);
  pg_reporting_entity_id number;
  pg_coaid number;
  pg_in_bal_segment_low varchar2(30);
  pg_in_bal_segment_high varchar2(30);
  pg_in_as_of_date_low date;
  pg_in_summary_option_low varchar2(80);
  pg_in_format_option_low varchar2(80);
  pg_in_bucket_type_low varchar2(30);
  pg_credit_option varchar2(80);
  pg_risk_option varchar2(80);
  pg_in_currency varchar2(20);
  pg_in_customer_name_low varchar2(240);
  pg_in_customer_name_high varchar2(240);
  pg_in_customer_num_low varchar2(200);
  pg_in_customer_num_high varchar2(200);
  pg_in_amt_due_low varchar2(200);
  pg_in_amt_due_high varchar2(200);
  pg_in_invoice_type_low varchar2(500);
  pg_in_invoice_type_high varchar2(500);
  pg_in_collector_low varchar2(30);
  pg_in_collector_high varchar2(30);
  pg_in_salesrep_low varchar2(30);
  pg_in_salesrep_high varchar2(30);
  pg_retain_staging_flag varchar(1);
  pg_cons_profile_value varchar2(1);
  pg_accounting_method varchar2(30);
  pg_in_collector varchar2(30);
  pg_in_customer_class varchar2(30);
  pg_in_country varchar2(400);
  pg_in_state varchar2(400);
  pg_in_account varchar2(30);
  --
  pg_accounting_flexfield varchar2(2000);
  --
  pg_acct_flex_bal_seg varchar2(2000);
  --
  pg_report_name varchar2(2000);
  pg_segment_label varchar2(2000);
  pg_bal_label varchar2(2000);
  pg_label_1 varchar2(2000);
  pg_sort_on varchar2(2000);
  pg_grand_total varchar2(2000);
  pg_label varchar2(2000);
  pg_param_org_id number;
  pg_company_name varchar2(2000);
  pg_functional_currency varchar2(2000);
  pg_func_curr_precision number;
  pg_convert_flag varchar2(2000);
  pg_set_of_books_id number;
  pg_in_sortoption varchar2(2000);
  pg_request_id number;
  pg_parent_request_id number := -1;
  pg_worker_id number := 1;
  pg_worker_count number := 1;
  pg_short_unid_phrase varchar2(2000);
  pg_payment_meaning varchar2(2000);
  pg_risk_meaning varchar2(2000);
  pg_lookup_org_id number;
  pg_include_credit_high varchar2(400);
  pg_in_on_account_low varchar2(400);
  pg_sel_opt_org_id number;
  pg_print_on_account_flag varchar2(100);
  pg_sort_option varchar2(100);
  pg_summary_option varchar2(100);
  pg_format_detailed varchar2(100);
  pg_invoice_type_print varchar2(1000);
  pg_customer_name_print varchar2(4000);
  pg_balance_due_print varchar2(1000);
  pg_credit_option_meaning varchar2(4000);
  --
  pg_reporting_entity_name varchar2(2000);
  pg_reporting_level_name varchar2(2000);
  --
  pg_temp_site_use_id number;
  pg_temp_contact_phone varchar2(360);
  pg_temp_contacts varchar2(360);
  pg_temp_contact_name hz_parties.party_name%type;
  l_cus_sel1 clob;
  l_cus_sel2 clob;
  l_cus_sel3 clob;
  l_cus_sel4 clob;
  l_cus_sel5 clob;
  l_inv_sel long;
  l_inv_sel1 long;
  l_inv_sel2 long;
  l_inv_sel3 long;
  l_inv_sel4 long;
  l_inv_sel5 long;
  new_line varchar2(10) := '
';
  common_query_inv clob;
  common_query_cus clob;
  p_mrcsobtype varchar2(1);
  p_br_enabled varchar2(1);
  lp_ar_system_parameters varchar2(400);
  lp_ar_system_parameters_all varchar2(400);
  lp_ar_payment_schedules varchar2(400);
  lp_ar_payment_schedules_all varchar2(400);
  lp_ar_adjustments varchar2(400);
  lp_ar_adjustments_all varchar2(400);
  lp_ar_cash_receipt_history varchar2(400);
  lp_ar_cash_receipt_history_all varchar2(400);
  lp_ar_batches varchar2(400);
  lp_ar_batches_all varchar2(400);
  lp_ar_cash_receipts varchar2(400);
  lp_ar_cash_receipts_all varchar2(400);
  lp_ar_distributions varchar2(400);
  lp_ar_distributions_all varchar2(400);
  lp_ra_customer_trx varchar2(400);
  lp_ra_customer_trx_all varchar2(400);
  lp_ra_batches varchar2(400);
  lp_ra_batches_all varchar2(400);
  lp_ra_cust_trx_gl_dist varchar2(400);
  lp_ra_cust_trx_gl_dist_all varchar2(400);
  lp_ar_misc_cash_dists varchar2(400);
  lp_ar_misc_cash_dists_all varchar2(400);
  lp_ar_rate_adjustments varchar2(400);
  lp_ar_rate_adjustments_all varchar2(400);
  lp_ar_receivable_apps varchar2(400);
  lp_ar_receivable_apps_all varchar2(400);
  p_org_where_ps varchar2(4000);
  p_org_where_gld varchar2(4000);
  p_org_where_ct varchar2(4000);
  p_org_where_sales varchar2(4000);
  p_org_where_ct2 varchar2(4000);
  p_org_where_adj varchar2(4000);
  p_org_where_app varchar2(4000);
  p_org_where_crh varchar2(4000);
  p_org_where_cr varchar2(4000);
  p_org_where_param varchar2(4000);
  p_org_where_addr varchar2(4000);
  p_reporting_entity_name varchar2(4000);
  p_reporting_level_name varchar2(4000);
  lp_customer_name_low varchar2(4000);
  lp_customer_name_high varchar2(4000);
  lp_customer_num_low varchar2(4000);
  lp_customer_num_high varchar2(4000);
  lp_invoice_type_low varchar2(4000);
  lp_invoice_type_high varchar2(4000);
  lp_bal_low varchar2(4000);
  lp_bal_high varchar2(4000);
  lp_accounting_flexfield varchar2(4000);
  lp_acct_flex_bal_seg varchar2(4000);
  p_cons_profile_value varchar2(4000);
  lp_query_show_bill varchar2(4000);
  lp_table_show_bill varchar2(4000);
  lp_where_show_bill varchar2(4000);
  lp_where varchar2(4000);
  p_sort_on varchar2(4000);
  p_label_1 varchar2(4000);
  p_report_name varchar2(4000);
  p_segment_label varchar2(4000);
  p_low varchar2(4000);
  p_high varchar2(4000);
  p_label varchar2(4000);
  p_grand_total varchar2(4000);
  p_bal_label varchar2(4000);
  lp_agl_name varchar2(4000);
  lp_agl_id varchar2(4000);
  lp_agl_from1 varchar2(4000);
  lp_agl_from2 varchar2(4000);
  lp_agl_where1 varchar2(4000);
  lp_agl_where_org2 varchar2(4000);
  lp_agr_name varchar2(4000);
  lp_agr_id varchar2(4000);
  lp_agr_from1 varchar2(4000);
  lp_agr_from2 varchar2(4000);
  lp_agr_from3 varchar2(4000);
  lp_agr_where1 varchar2(4000);
  lp_agr_where2 varchar2(4000);
  lp_agr_where3 varchar2(4000);
  lp_agr_where4 varchar2(4000);
  lp_agr_where5 varchar2(4000);
  lp_agr_where_org1 varchar2(4000);
  lp_agr_where_org2 varchar2(4000);
  lp_aglr_where1 varchar2(4000);
  lp_aglr_where2 varchar2(4000);
  lp_aglr_where3 varchar2(4000);
  lp_aglr_where4 varchar2(4000);
  lp_aglr_where5 varchar2(4000);
  lp_aglr_where6 varchar2(4000);
  lp_aglr_where7 varchar2(4000);
  lp_aglr_where8 varchar2(4000);
  lp_agfs_where1 varchar2(4000);
  lp_agfs_where2 varchar2(4000);
  lp_agfs_where3 varchar2(4000);
  lp_agfs_where4 varchar2(4000);
  p_short_unid_phrase varchar2(4000);
  lp_payment_meaning varchar2(4000);
  lp_risk_meaning varchar2(4000);
  p_in_sortoption varchar2(100);

  /*==========================================================================
  | PRIVATE FUNCTION get_contact_information                                 |
  |                                                                          |
  | DESCRIPTION                                                              |
  |  Returns contact information  associated to given site,return values     |
  |  also depends on what sort of information is requested                   |
  |                                                                          |
  | CALLED FROM PROCEDURES/FUNCTIONS (local to this package body)            |
  |                                                                          |
  | PARAMETERS                                                               |
  |  p_site_use_id                                                           |
  |  p_info_type  -possible values are NAME and PHONE                        |
  | KNOWN ISSUES                                                             |
  |                                                                          |
  | NOTES                                                                    |
  |                                                                          |
  | MODIFICATION HISTORY                                                     |
  | Date                  Author            Description of Changes           |
  | 10-JUL-2009           Naveen Prodduturi Created                          |
  *==========================================================================*/
 procedure main(xerrbuf   out varchar2
               , xretcode   out varchar2
               , p_rep_type in varchar2
               , p_reporting_level in varchar2
               , p_reporting_entity_id in varchar2
               , p_operating_unit_id in number
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
               , p_in_account in varchar2);

  procedure debug(p_msg in varchar2);
function build_customer_select
    return clob;
  procedure build_invoice_select;
  procedure insert_data;
  procedure generate_report;
  procedure bind_parameters(p_cursor in integer);
  function initialize
    return boolean;
end xx_ar_aging_xml_rpt_pkg;
/
