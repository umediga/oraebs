DROP PACKAGE APPS.XX_PA_ACC_GEN_WF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PA_ACC_GEN_WF_PKG" as
  procedure dbms_debug(p_debug in varchar2);

  function build_sql(nosegments in number)
    return clob;

  procedure bind_variable(p_cursor in integer, p_column in varchar2, p_value in varchar2);

  procedure define_column(p_cursor in integer, p_position in number, p_column in varchar2);

  function column_values(p_cursor in integer, p_position in number, p_column in varchar2)
    return varchar2;

  procedure set_org_attributes(p_itemtype in varchar2
                             , p_itemkey in varchar2
                             , p_actid in number
                             , p_funcmode in varchar2
                             , x_result   out varchar2);

  function pa_segment_lookup_set_value(p_lookup_set in varchar2, p_lookup_code in varchar2)
    return varchar2;

  procedure intg_auto_create_flag(itemtype in   varchar2
                                , itemkey in    varchar2
                                , actid in      number
                                , funcmode in   varchar2
                                , resultout   out nocopy varchar2);

  procedure intg_auto_approve_flag(itemtype in   varchar2
                                 , itemkey in    varchar2
                                 , actid in      number
                                 , funcmode in   varchar2
                                 , resultout   out nocopy varchar2);

  function get_117_trx_flow_header_id(p_inventory_item_id number, p_po_ou_id in number, p_inv_org_ou_id in number)
    return number;

  procedure intg_trx_flow_header(itemtype in   varchar2
                               , itemkey in    varchar2
                               , actid in      number
                               , funcmode in   varchar2
                               , resultout   out nocopy varchar2);

  procedure aa_from_org(itemtype in varchar2, itemkey in varchar2, actid in number, funcmode in varchar2, result out nocopy varchar2);
end xx_pa_acc_gen_wf_pkg; 
/
