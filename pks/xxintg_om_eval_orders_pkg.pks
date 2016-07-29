DROP PACKAGE APPS.XXINTG_OM_EVAL_ORDERS_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_OM_EVAL_ORDERS_PKG" as
  procedure debug_log(str in varchar2);

  procedure log_errors(p_pkg_name in varchar2 default 'xxintg_om_eval_orders_pkg'
                     , p_proc_name in varchar2
                     , p_header_id in number
                     , p_line_id in number
                     , p_date in date
                     , p_msg in varchar2);

  procedure set_line_status(p_line_id in number, p_line_status in varchar2, x_return_status out varchar2);

  procedure set_line_status_wf(p_itemtype in varchar2
                             , p_itemkey in varchar2
                             , p_actid in number
                             , p_funcmode in varchar2
                             , p_result in out varchar2);

  procedure copy_line(p_line_id in number, p_line_type_id in number, p_line_type_name in varchar2, x_return_status out varchar2);

  procedure create_eval_return_line(p_line_id in number, x_return_status out varchar2);

  procedure create_lot_serials(p_eval_line_id in number, p_return_line_id in number, x_return_status out varchar2);

  procedure create_return_line(p_itemtype in varchar2
                             , p_itemkey in varchar2
                             , p_actid in number
                             , p_funcmode in varchar2
                             , p_result in out varchar2);

  function line_shipment_option(p_line_id in number)
    return varchar2;

  procedure update_instance(p_instance_id in number
                          , p_txn_rec     csi_datastructures_pub.transaction_rec
                          , x_return_status   out varchar2
                          , x_msg_count   out nocopy number
                          , x_msg_data   out nocopy varchar2);

  procedure close_eval_line(p_itemtype in varchar2
                          , p_itemkey in varchar2
                          , p_actid in number
                          , p_funcmode in varchar2
                          , p_result in out varchar2);

  procedure convert_to_rental(p_line_id in number);

  procedure set_rental_status(p_itemtype in varchar2
                            , p_itemkey in varchar2
                            , p_actid in number
                            , p_funcmode in varchar2
                            , p_result in out varchar2);

  procedure convert_to_sell(p_line_id in number);

  procedure eval_to_sell(p_line_id in number);
  procedure create_exchange(p_line_id in number);

  procedure rental_ib_update(p_itemtype in varchar2
                           , p_itemkey in varchar2
                           , p_actid in number
                           , p_funcmode in varchar2
                           , p_result in out varchar2);

  procedure update_instance_for_rent(p_instance_id in number, p_line_id in number, x_return_status out varchar2);
  function get_messages(p_action in varchar2,p_line_id in number, p_header_id in number)
  return varchar2;
  procedure eval_extension(p_esc_stage in number, p_eval_line_id in number);
  procedure validate_po(itemtype in varchar2, itemkey in varchar2, actid in number, funcmode in varchar2, resultout out nocopy varchar2);
  procedure custpo_hold(itemtype in   varchar2
                          , itemkey in    varchar2
                          , actid in      number
                          , funcmode in   varchar2
                          , resultout in out nocopy varchar2);
procedure update_status(p_status_code varchar2, p_org_id number, p_line_id number);                          
                          
end; 
/
