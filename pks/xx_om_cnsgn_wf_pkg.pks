DROP PACKAGE APPS.XX_OM_CNSGN_WF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_CNSGN_WF_PKG" as
  procedure xx_om_validate_po(itemtype in   varchar2
                            , itemkey in    varchar2
                            , actid in      number
                            , funcmode in   varchar2
                            , resultout   out nocopy varchar2);
  procedure xx_om_custpo_hold(itemtype in   varchar2
                            , itemkey in    varchar2
                            , actid in      number
                            , funcmode in   varchar2
                            , resultout in out nocopy varchar2);
  procedure xx_om_create_ir_iso(itemtype in   varchar2
                              , itemkey in    varchar2
                              , actid in      number
                              , funcmode in   varchar2
                              , resultout in out nocopy varchar2);
  procedure create_product_request(itemtype in   varchar2
                                 , itemkey in    varchar2
                                 , actid in      number
                                 , funcmode in   varchar2
                                 , resultout in out nocopy varchar2);
  procedure create_so(p_header_Id in number, px_return_status out varchar2, x_new_order_number out number);
  procedure create_ous_so(p_header_Id in number, px_return_status out varchar2, x_new_order_number out number);
   procedure xx_om_create_ous_ir_iso(itemtype in   varchar2
                              , itemkey in    varchar2
                              , actid in      number
                              , funcmode in   varchar2
                              , resultout in out nocopy varchar2);
end;
/
