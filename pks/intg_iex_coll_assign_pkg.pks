DROP PACKAGE APPS.INTG_IEX_COLL_ASSIGN_PKG;

CREATE OR REPLACE PACKAGE APPS.INTG_IEX_COLL_ASSIGN_PKG as
  g_req_mesg   varchar2(4000);
  g_org_id number;
  procedure debug_print(p_debug_mesg in varchar2);
  procedure generate_report;
  procedure update_collectors;
  procedure collect_remaining;
  procedure collect_named_accounts;
  procedure assign_collectors(x_errbuf out varchar2, retcode out number, p_org_id in number, p_mode in varchar2 default 'VALIDATE');
  procedure debug_log(p_msg in varchar2);
  procedure exec_invoice_print_pr(p_cust_trx_id in number, x_req_id out number);
  function get_request_mesg
    return varchar2;
end intg_iex_coll_assign_pkg;
/
