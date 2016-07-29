DROP PACKAGE APPS.XXIEX_UWQ_DELIN_ENUMS_PKG;

CREATE OR REPLACE PACKAGE APPS."XXIEX_UWQ_DELIN_ENUMS_PKG" as
  procedure set_mo_global;

  procedure enumerate_my_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number);
   procedure enumerate_all_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number);
   procedure enumerate_dom_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number);
   procedure enumerate_intl_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number);
  procedure enumerate_acc_delin_nodes(p_resource_id in number, p_language in varchar2, p_source_lang in varchar2, p_sel_enum_id in number);
  procedure enumerate_intl_acc_delin_nodes(p_resource_id in number, p_language in varchar2, p_source_lang in varchar2, p_sel_enum_id in number);                                        
end; 
/
