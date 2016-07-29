DROP PACKAGE BODY APPS.XXIEX_UWQ_DELIN_ENUMS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXIEX_UWQ_DELIN_ENUMS_PKG" as
  pg_debug   number(2);

  procedure set_mo_global is
    l   varchar2(240);

    cursor c_org_id is
      select organization_id
        from hr_operating_units
       where mo_global.check_access(organization_id) = 'Y';
  begin
    mo_global.init('IEX');
    mo_global.set_policy_context('M', null);

    for i_org in c_org_id loop
      mo_global.set_policy_context('S', i_org.organization_id);
      l :=
        iex_utilities.get_cache_value(
          'GL_CURRENCY' || i_org.organization_id,
          'SELECT  GLSOB.CURRENCY_CODE CURRENCY from GL_SETS_OF_BOOKS GLSOB, AR_SYSTEM_PARAMETERS ARSYS WHERE ARSYS.SET_OF_BOOKS_ID ' ||
          ' = GLSOB.SET_OF_BOOKS_ID');
      l :=
        iex_utilities.get_cache_value('DEFAULT_EXCHANGE_RATE_TYPE' || i_org.organization_id,
                                      'SELECT DEFAULT_EXCHANGE_RATE_TYPE FROM AR_CMGT_SETUP_OPTIONS');
    end loop;

    mo_global.set_policy_context('M', null);
  end set_mo_global;

  procedure enumerate_my_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number) as
    l_node_label         varchar2(200);
    l_ld_list            ieu_pub.enumeratordatarecordlist;
    l_node_counter       number;
    l_bind_list          ieu_pub.bindvariablerecordlist;
    l_access             varchar2(10);
    l_level              varchar2(15);
    l_person_id          number;

    cursor c_person is
      select source_id
        from jtf_rs_resource_extns
       where resource_id = p_resource_id;

    cursor c_del_new_nodes is
      select lookup_code, meaning
        from fnd_lookup_values
       where lookup_type = 'IEX_UWQ_NODE_STATUS' and language = userenv('LANG');

    cursor c_node_label(in_lookup_type varchar2, in_lookup_code varchar2) is
      select meaning
        from fnd_lookup_values
       where lookup_type = in_lookup_type and lookup_code = in_lookup_code and language = userenv('LANG');

    cursor c_sel_enum(in_sel_enum_id number) is
      select work_q_view_for_primary_node, work_q_label_lu_type, work_q_label_lu_code
        from ieu_uwq_sel_enumerators
       where sel_enum_id = in_sel_enum_id;

    l_sel_enum_rec       c_sel_enum%rowtype;
    l_complete_days      varchar2(40);
    l_data_source        varchar2(1000);
    l_default_where      varchar2(1000);
    l_security_where     varchar2(2000);
    l_node_where         varchar2(2000);
    l_uwq_where          varchar2(1000);
    l_org_id             number;

    type tbl_wclause is table of varchar2(500)
                          index by binary_integer;

    l_wclause            tbl_wclause;
    l_str_and            varchar2(100);
    l_str_del            varchar2(1000);
    l_str_bkr            varchar2(1000);
    l_str_bkr2           varchar2(1000);
    l_bkr_filter         varchar2(240);
    l_check              number;
    l_enablenodes        varchar2(10);
    l_additional_where   varchar2(2500);
    l_strategy_level     varchar2(100);
    l_filter_col_str1    varchar2(1000);
    l_filter_col_str2    varchar2(1000);
    l_filter_cond_str    varchar2(1000);
  begin
    set_mo_global;
    if mo_global.get_current_org_id is null then
    mo_global.set_policy_context('S',fnd_global.org_id);
    end if;
    l_node_counter := 0;

    open c_sel_enum(p_sel_enum_id);

    fetch c_sel_enum into l_sel_enum_rec;

    close c_sel_enum;

    open c_node_label(l_sel_enum_rec.work_q_label_lu_type, l_sel_enum_rec.work_q_label_lu_code);

    fetch c_node_label into l_node_label;

    close c_node_label;

    l_data_source := 'INTG_MY_ORDERS_ON_HOLD';
    l_default_where := ' RESOURCE_ID = :RESOURCE_ID ';
    l_ld_list(l_node_counter).node_label := l_node_label;
    l_ld_list(l_node_counter).view_name := l_sel_enum_rec.work_q_view_for_primary_node;
    l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
    l_ld_list(l_node_counter).data_source := l_data_source;
    l_bind_list(2).bind_var_name := ':RESOURCE_ID';
    l_bind_list(2).bind_var_value := p_resource_id;
    l_bind_list(2).bind_var_data_type := 'NUMBER';
    l_ld_list(l_node_counter).where_clause := l_default_where;
    l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
    l_ld_list(l_node_counter).media_type_id := '';
    l_ld_list(l_node_counter).node_type := 0;
    l_ld_list(l_node_counter).hide_if_empty := '';
    l_ld_list(l_node_counter).node_depth := 1;
    l_node_counter := l_node_counter + 1;
    ieu_pub.add_uwq_node_data(p_resource_id, p_sel_enum_id, l_ld_list);
  exception
    when others then
      raise;
  end enumerate_my_orders_on_hold;
  procedure enumerate_all_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number) as
    l_node_label         varchar2(200);
    l_ld_list            ieu_pub.enumeratordatarecordlist;
    l_node_counter       number;
    l_bind_list          ieu_pub.bindvariablerecordlist;
    l_access             varchar2(10);
    l_level              varchar2(15);
    l_person_id          number;

    cursor c_person is
      select source_id
        from jtf_rs_resource_extns
       where resource_id = p_resource_id;

    cursor c_del_new_nodes is
      select lookup_code, meaning
        from fnd_lookup_values
       where lookup_type = 'IEX_UWQ_NODE_STATUS' and language = userenv('LANG');

    cursor c_node_label(in_lookup_type varchar2, in_lookup_code varchar2) is
      select meaning
        from fnd_lookup_values
       where lookup_type = in_lookup_type and lookup_code = in_lookup_code and language = userenv('LANG');

    cursor c_sel_enum(in_sel_enum_id number) is
      select work_q_view_for_primary_node, work_q_label_lu_type, work_q_label_lu_code
        from ieu_uwq_sel_enumerators
       where sel_enum_id = in_sel_enum_id;

    l_sel_enum_rec       c_sel_enum%rowtype;
    l_complete_days      varchar2(40);
    l_data_source        varchar2(1000);
    l_default_where      varchar2(1000);
    l_security_where     varchar2(2000);
    l_node_where         varchar2(2000);
    l_uwq_where          varchar2(1000);
    l_org_id             number;

    type tbl_wclause is table of varchar2(500)
                          index by binary_integer;

    l_wclause            tbl_wclause;
    l_str_and            varchar2(100);
    l_str_del            varchar2(1000);
    l_str_bkr            varchar2(1000);
    l_str_bkr2           varchar2(1000);
    l_bkr_filter         varchar2(240);
    l_check              number;
    l_enablenodes        varchar2(10);
    l_additional_where   varchar2(2500);
    l_strategy_level     varchar2(100);
    l_filter_col_str1    varchar2(1000);
    l_filter_col_str2    varchar2(1000);
    l_filter_cond_str    varchar2(1000);
    l_view_name VARCHAR2(240);
  l_refresh_view_name VARCHAR2(240);
  begin
    set_mo_global;
   -- if mo_global.get_current_org_id is null then
   -- mo_global.set_policy_context('S',82);
    --end if;
    l_node_counter := 0;

    open c_sel_enum(p_sel_enum_id);

    fetch c_sel_enum into l_sel_enum_rec;

    close c_sel_enum;

    open c_node_label(l_sel_enum_rec.work_q_label_lu_type, l_sel_enum_rec.work_q_label_lu_code);

    fetch c_node_label into l_node_label;

    close c_node_label;

    l_data_source := 'INTG_ALL_ORDERS_ON_HOLD';
     l_view_name:='XXIEX_ALL_ORDERS_ON_HOLD_V';
    l_refresh_view_name:='XXIEX_ALL_ORDERS_ON_HOLD_V';
    --l_default_where := ' RESOURCE_ID = :RESOURCE_ID ';
    l_ld_list(l_node_counter).node_label := l_node_label;
    l_ld_list(l_node_counter).view_name := l_sel_enum_rec.work_q_view_for_primary_node;
    l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
    l_ld_list(l_node_counter).data_source := l_data_source;
   l_bind_list(2).bind_var_name := ':RESOURCE_ID';
    --l_bind_list(2).bind_var_value := p_resource_id;
    l_bind_list(2).bind_var_value := -1;
    l_bind_list(2).bind_var_data_type := 'NUMBER';
   -- l_ld_list(l_node_counter).where_clause := l_default_where;
   -- l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
    l_ld_list(l_node_counter).media_type_id := '';
    l_ld_list(l_node_counter).node_type := 0;
    l_ld_list(l_node_counter).hide_if_empty := '';
    l_ld_list(l_node_counter).node_depth := 1;
    l_node_counter := l_node_counter + 1;
    ieu_pub.add_uwq_node_data(p_resource_id, p_sel_enum_id, l_ld_list);
  exception
    when others then
      raise;
  end enumerate_all_orders_on_hold;
    procedure enumerate_dom_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number) as
    l_node_label         varchar2(200);
    l_ld_list            ieu_pub.enumeratordatarecordlist;
    l_node_counter       number;
    l_bind_list          ieu_pub.bindvariablerecordlist;
    l_access             varchar2(10);
    l_level              varchar2(15);
    l_person_id          number;

    cursor c_person is
      select source_id
        from jtf_rs_resource_extns
       where resource_id = p_resource_id;

    cursor c_del_new_nodes is
      select lookup_code, meaning
        from fnd_lookup_values
       where lookup_type = 'IEX_UWQ_NODE_STATUS' and language = userenv('LANG');

    cursor c_node_label(in_lookup_type varchar2, in_lookup_code varchar2) is
      select meaning
        from fnd_lookup_values
       where lookup_type = in_lookup_type and lookup_code = in_lookup_code and language = userenv('LANG');

    cursor c_sel_enum(in_sel_enum_id number) is
      select work_q_view_for_primary_node, work_q_label_lu_type, work_q_label_lu_code
        from ieu_uwq_sel_enumerators
       where sel_enum_id = in_sel_enum_id;

    l_sel_enum_rec       c_sel_enum%rowtype;
    l_complete_days      varchar2(40);
    l_data_source        varchar2(1000);
    l_default_where      varchar2(1000);
    l_security_where     varchar2(2000);
    l_node_where         varchar2(2000);
    l_uwq_where          varchar2(1000);
    l_org_id             number;

    type tbl_wclause is table of varchar2(500)
                          index by binary_integer;

    l_wclause            tbl_wclause;
    l_str_and            varchar2(100);
    l_str_del            varchar2(1000);
    l_str_bkr            varchar2(1000);
    l_str_bkr2           varchar2(1000);
    l_bkr_filter         varchar2(240);
    l_check              number;
    l_enablenodes        varchar2(10);
    l_additional_where   varchar2(2500);
    l_strategy_level     varchar2(100);
    l_filter_col_str1    varchar2(1000);
    l_filter_col_str2    varchar2(1000);
    l_filter_cond_str    varchar2(1000);
    l_view_name VARCHAR2(240);
  l_refresh_view_name VARCHAR2(240);
  begin
  --  set_mo_global;
   -- if mo_global.get_current_org_id is null then
    mo_global.set_policy_context('S',82);
    --end if;
    l_node_counter := 0;

    open c_sel_enum(p_sel_enum_id);

    fetch c_sel_enum into l_sel_enum_rec;

    close c_sel_enum;

    open c_node_label(l_sel_enum_rec.work_q_label_lu_type, l_sel_enum_rec.work_q_label_lu_code);

    fetch c_node_label into l_node_label;

    close c_node_label;

    l_data_source := 'INTG_DOM_ORDERS_ON_HOLD';
    l_view_name:='XXIEX_DOM_ORDERS_ON_HOLD_V';
    l_refresh_view_name:='XXIEX_DOM_ORDERS_ON_HOLD_V';
    --l_default_where := ' RESOURCE_ID = :RESOURCE_ID ';
    l_ld_list(l_node_counter).node_label := l_node_label;
    --l_ld_list(l_node_counter).view_name := l_sel_enum_rec.work_q_view_for_primary_node;
    l_ld_list(l_node_counter).view_name := l_view_name;
    l_ld_list(l_node_counter).REFRESH_VIEW_NAME := l_refresh_view_name;
    l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
    l_ld_list(l_node_counter).data_source := l_data_source;
    l_bind_list(2).bind_var_name := ':RESOURCE_ID';
    --l_bind_list(2).bind_var_value := p_resource_id;
    l_bind_list(2).bind_var_value := -1;
    l_bind_list(2).bind_var_data_type := 'NUMBER';
   -- l_ld_list(l_node_counter).where_clause := l_default_where;
   -- l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
    l_ld_list(l_node_counter).media_type_id := '';
    l_ld_list(l_node_counter).node_type := 0;
    l_ld_list(l_node_counter).hide_if_empty := '';
    l_ld_list(l_node_counter).node_depth := 1;
    l_node_counter := l_node_counter + 1;
    ieu_pub.add_uwq_node_data(p_resource_id, p_sel_enum_id, l_ld_list);
  exception
    when others then
      raise;
  end enumerate_dom_orders_on_hold;
   procedure enumerate_intl_orders_on_hold(p_resource_id   in number,
                                        p_language      in varchar2,
                                        p_source_lang   in varchar2,
                                        p_sel_enum_id   in number) as
    l_node_label         varchar2(200);
    l_ld_list            ieu_pub.enumeratordatarecordlist;
    l_node_counter       number;
    l_bind_list          ieu_pub.bindvariablerecordlist;
    l_access             varchar2(10);
    l_level              varchar2(15);
    l_person_id          number;

    cursor c_person is
      select source_id
        from jtf_rs_resource_extns
       where resource_id = p_resource_id;

    cursor c_del_new_nodes is
      select lookup_code, meaning
        from fnd_lookup_values
       where lookup_type = 'IEX_UWQ_NODE_STATUS' and language = userenv('LANG');

    cursor c_node_label(in_lookup_type varchar2, in_lookup_code varchar2) is
      select meaning
        from fnd_lookup_values
       where lookup_type = in_lookup_type and lookup_code = in_lookup_code and language = userenv('LANG');

    cursor c_sel_enum(in_sel_enum_id number) is
      select work_q_view_for_primary_node, work_q_label_lu_type, work_q_label_lu_code
        from ieu_uwq_sel_enumerators
       where sel_enum_id = in_sel_enum_id;

    l_sel_enum_rec       c_sel_enum%rowtype;
    l_complete_days      varchar2(40);
    l_data_source        varchar2(1000);
    l_default_where      varchar2(1000);
    l_security_where     varchar2(2000);
    l_node_where         varchar2(2000);
    l_uwq_where          varchar2(1000);
    l_org_id             number;

    type tbl_wclause is table of varchar2(500)
                          index by binary_integer;

    l_wclause            tbl_wclause;
    l_str_and            varchar2(100);
    l_str_del            varchar2(1000);
    l_str_bkr            varchar2(1000);
    l_str_bkr2           varchar2(1000);
    l_bkr_filter         varchar2(240);
    l_check              number;
    l_enablenodes        varchar2(10);
    l_additional_where   varchar2(2500);
    l_strategy_level     varchar2(100);
    l_filter_col_str1    varchar2(1000);
    l_filter_col_str2    varchar2(1000);
    l_filter_cond_str    varchar2(1000);
     l_view_name VARCHAR2(240);
  l_refresh_view_name VARCHAR2(240);
  begin
  --  set_mo_global;
   -- if mo_global.get_current_org_id is null then
    mo_global.set_policy_context('S',82);
    --end if;
    l_node_counter := 0;

    open c_sel_enum(p_sel_enum_id);

    fetch c_sel_enum into l_sel_enum_rec;

    close c_sel_enum;

    open c_node_label(l_sel_enum_rec.work_q_label_lu_type, l_sel_enum_rec.work_q_label_lu_code);

    fetch c_node_label into l_node_label;

    close c_node_label;

    l_data_source := 'INTG_INTL_ORDERS_ON_HOLD';
      l_view_name:='XXIEX_INTL_ORDERS_ON_HOLD_V';
    l_refresh_view_name:='XXIEX_INTL_ORDERS_ON_HOLD_V';
    --l_default_where := ' RESOURCE_ID = :RESOURCE_ID ';
    l_ld_list(l_node_counter).node_label := l_node_label;
    l_ld_list(l_node_counter).view_name := l_sel_enum_rec.work_q_view_for_primary_node;
    l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
    l_ld_list(l_node_counter).data_source := l_data_source;
   l_bind_list(2).bind_var_name := ':RESOURCE_ID';
    --l_bind_list(2).bind_var_value := p_resource_id;
    l_bind_list(2).bind_var_value := -1;
    l_bind_list(2).bind_var_data_type := 'NUMBER';
   -- l_ld_list(l_node_counter).where_clause := l_default_where;
   -- l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
    l_ld_list(l_node_counter).media_type_id := '';
    l_ld_list(l_node_counter).node_type := 0;
    l_ld_list(l_node_counter).hide_if_empty := '';
    l_ld_list(l_node_counter).node_depth := 1;
    l_node_counter := l_node_counter + 1;
    ieu_pub.add_uwq_node_data(p_resource_id, p_sel_enum_id, l_ld_list);
  exception
    when others then
      raise;
  end enumerate_intl_orders_on_hold;
  procedure enumerate_acc_delin_nodes(p_resource_id in number
                                    , p_language in varchar2
                                    , p_source_lang in varchar2
                                    , p_sel_enum_id in number) as
    l_node_label varchar2(200);
    l_ld_list ieu_pub.enumeratordatarecordlist;
    l_node_counter number;
    l_bind_list ieu_pub.bindvariablerecordlist;
    l_access varchar2(10);
    l_level varchar2(15);
    l_person_id number;
    l_check number;
    l_collector_id number;

    cursor c_person is
      select source_id
      from   jtf_rs_resource_extns
      where  resource_id = p_resource_id;

    cursor c_del_new_nodes is
      select lookup_code, meaning
      from   fnd_lookup_values
      where  lookup_type = 'IEX_UWQ_NODE_STATUS' and language = userenv('LANG');

    cursor c_node_label(in_lookup_type varchar2, in_lookup_code varchar2) is
      select meaning
      from   fnd_lookup_values
      where  lookup_type = in_lookup_type and lookup_code = in_lookup_code and language = userenv('LANG');

    cursor c_sel_enum(in_sel_enum_id number) is
      select work_q_view_for_primary_node, work_q_label_lu_type, work_q_label_lu_code
      from   ieu_uwq_sel_enumerators
      where  sel_enum_id = in_sel_enum_id;

    cursor c_collector_id is
          select collector_id
      from   ar_collectors
      where  resource_id = p_resource_id and resource_type = 'RS_RESOURCE';

    l_sel_enum_rec c_sel_enum%rowtype;
    l_complete_days varchar2(40);
    l_data_source varchar2(1000);
    l_default_where varchar2(1000);
    l_security_where varchar2(2000);
    l_node_where varchar2(2000);
    l_uwq_where varchar2(1000);
    l_org_id number;

    type tbl_wclause is table of varchar2(500)
                          index by binary_integer;

    l_str_and varchar2(100);
    l_str_del varchar2(1000);
    l_str_bkr varchar2(1000);
    l_bkr_filter varchar2(240);
    l_view_name varchar2(240);
    l_refresh_view_name varchar2(240);
    l_enablenodes varchar2(10);
    l_additional_where1 varchar2(2000);
    l_additional_where2 varchar2(2000);
    l varchar2(240);

    cursor c_org_id is
      select organization_id
      from   hr_operating_units
      where  mo_global.check_access(organization_id) = 'Y';

    cursor c_strategy_level is
      select preference_value
      from   iex_app_preferences_b
      where  preference_name = 'COLLECTIONS STRATEGY LEVEL' and org_id is null and enabled_flag = 'Y'; 

    l_strategy_level varchar2(30);
    l_group_check number;
    l_level_count number;

    cursor c_multi_level is
      select lookup_code
      from   iex_lookups_v
      where  lookup_type = 'IEX_RUNNING_LEVEL' and lookup_code = 'ACCOUNT' and iex_utilities.validate_running_level(lookup_code) = 'Y';
  begin
    set_mo_global;
    l_access := nvl(fnd_profile.value('IEX_CUST_ACCESS'), 'F');
    l_level := nvl(fnd_profile.value('IEX_ACCESS_LEVEL'), 'PARTY');
    l_complete_days := nvl(fnd_profile.value('IEX_UWQ_COMPLETION_DAYS'), 30);
    l_bkr_filter := nvl(fnd_profile.value('IEX_BANKRUPTCY_FILTER'), 'Y');
    l_str_and := ' AND ';
    l_str_del := ' AND NUMBER_OF_DELINQUENCIES > 0 ';
    l_node_counter := 0;
    l_check := 0;
    l_group_check:=0;
    open c_sel_enum(p_sel_enum_id);
    fetch c_sel_enum
    into l_sel_enum_rec;
    close c_sel_enum;
    open c_node_label(l_sel_enum_rec.work_q_label_lu_type, l_sel_enum_rec.work_q_label_lu_code);
    fetch c_node_label
    into l_node_label;
    close c_node_label;
    open c_strategy_level;
    fetch c_strategy_level
    into l_strategy_level;
    close c_strategy_level;
    select count(1)
    into   l_level_count
    from   iex_lookups_v
    where  lookup_type = 'IEX_RUNNING_LEVEL' and iex_utilities.validate_running_level(lookup_code) = 'Y';

    if l_level_count > 1 then
      open c_multi_level;
      fetch c_multi_level
      into l_strategy_level;
      close c_multi_level;
    end if;

    l_data_source := 'INTG_IEX_DOM_ACC_DLN_ALL_UWQ';
    l_view_name := 'XX_IEX_DOM_CU_DLN_UWQ_V';
    l_refresh_view_name := 'XX_IEX_DOM_CU_DLN_UWQ_V';

    --if l_strategy_level = 'ACCOUNT' then
      --l_str_bkr := ' AND NUMBER_OF_BANKRUPTCIES = 0 ';
     -- l_default_where := ' RESOURCE_ID = :RESOURCE_ID and IEU_PARAM_PK_COL=''CUST_ACCOUNT_ID'' ';
      --l_security_where := ' :person_id = :person_id and collector_resource_id = -1 ';
      --l_security_where := ' 1 = 1 ';
      l_ld_list(l_node_counter).node_label := l_node_label;
      l_ld_list(l_node_counter).view_name := l_view_name;
      l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
      l_ld_list(l_node_counter).data_source := l_data_source;
      l_ld_list(l_node_counter).refresh_view_name := l_refresh_view_name;
      l_bind_list(1).bind_var_name := ':RESOURCE_ID';
      l_bind_list(1).bind_var_value := 1;
      l_bind_list(1).bind_var_data_type := 'NUMBER';

        l_ld_list(l_node_counter).refresh_view_name := l_view_name;
        --l_bind_list(2).bind_var_name := ':PERSON_ID';
        --l_bind_list(2).bind_var_value := -1;
        --l_bind_list(2).bind_var_data_type := 'NUMBER';
        --l_bind_list(2).bind_var_name := ':COLLECTOR_RESOURCE_ID';
        --l_bind_list(2).bind_var_value := -1;
        --l_bind_list(2).bind_var_data_type := 'NUMBER';

       

       -- l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
      
    --end if;

    l_ld_list(l_node_counter).media_type_id := '';
    l_ld_list(l_node_counter).node_type := 0;
    l_ld_list(l_node_counter).hide_if_empty := '';
    l_ld_list(l_node_counter).node_depth := 1;
    l_node_counter := l_node_counter + 1;
 /*   l_enablenodes := nvl(fnd_profile.value('IEX_ENABLE_UWQ_STATUS'), 'N');

    if (l_enablenodes <> 'N') then
      for cur_rec in c_del_new_nodes loop
        if l_strategy_level = 'ACCOUNT' then
          if (cur_rec.lookup_code = 'ACTIVE') then
            l_node_where := l_default_where || ' AND NUMBER_OF_DELINQUENCIES > 0  AND ACTIVE_DELINQUENCIES IS NOT NULL ';
            l_data_source := 'IEX_ACC_DLN_ACT_UWQ';
          elsif (cur_rec.lookup_code = 'PENDING') then
            l_node_where := l_default_where || ' AND NUMBER_OF_DELINQUENCIES > 0 AND PENDING_DELINQUENCIES IS NOT NULL ';
            l_data_source := 'IEX_ACC_DLN_PEND_UWQ';
          elsif (cur_rec.lookup_code = 'COMPLETE') then
            l_node_where := l_default_where || ' AND NUMBER_OF_DELINQUENCIES > 0 AND COMPLETE_DELINQUENCIES IS NOT NULL ';
            l_data_source := 'IEX_ACC_DLN_COMP_UWQ';
          end if;

          --l_security_where := ' :person_id = :person_id and collector_resource_id = -1 ';
          l_security_where := ' collector_resource_id = -1 ';
          l_ld_list(l_node_counter).node_label := cur_rec.meaning;
          l_ld_list(l_node_counter).view_name := l_view_name;
          l_ld_list(l_node_counter).data_source := l_data_source;
          l_ld_list(l_node_counter).refresh_view_name := l_refresh_view_name;
          l_bind_list(1).bind_var_name := ':RESOURCE_ID';
          l_bind_list(1).bind_var_value := 1;
          l_bind_list(1).bind_var_data_type := 'NUMBER';

          if (l_access in ('P', 'F')) then
            if l_bkr_filter = 'Y' then
              l_ld_list(l_node_counter).where_clause := l_node_where || l_str_bkr;
            else
              l_ld_list(l_node_counter).where_clause := l_node_where;
            end if;

            l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
          else
            l_ld_list(l_node_counter).refresh_view_name := l_view_name;

            if l_bkr_filter = 'Y' then
              l_ld_list(l_node_counter).where_clause := l_node_where || l_str_and || l_security_where || l_str_bkr;
            else
              l_ld_list(l_node_counter).where_clause := l_node_where || l_str_and || l_security_where;
            end if;

            --l_bind_list(2).bind_var_name := ':PERSON_ID';
            --l_bind_list(2).bind_var_value := -1;
            --l_bind_list(2).bind_var_data_type := 'NUMBER';
            l_bind_list(3).bind_var_name := ':COLLECTOR_RESOURCE_ID';
            l_bind_list(3).bind_var_value := -1;
            l_bind_list(3).bind_var_data_type := 'NUMBER';
            l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
          end if;
        else
          if (cur_rec.lookup_code = 'ACTIVE') then
            l_node_where := l_default_where;
            l_data_source := 'IEX_ACC_DLN_ACT_UWQ';
          elsif (cur_rec.lookup_code = 'PENDING') then
            l_node_where := l_default_where;
            l_data_source := 'IEX_ACC_DLN_PEND_UWQ';
          elsif (cur_rec.lookup_code = 'COMPLETE') then
            l_node_where := l_default_where;
            l_data_source := 'IEX_ACC_DLN_COMP_UWQ';
          end if;

          l_ld_list(l_node_counter).node_label := cur_rec.meaning;
          l_ld_list(l_node_counter).view_name := l_view_name;
          l_ld_list(l_node_counter).data_source := l_data_source;
          l_ld_list(l_node_counter).refresh_view_name := l_refresh_view_name;
          l_bind_list(1).bind_var_name := ':RESOURCE_ID';
          l_bind_list(1).bind_var_value := -1;
          l_bind_list(1).bind_var_data_type := 'NUMBER';
          l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
        end if;

        l_ld_list(l_node_counter).media_type_id := '';
        l_ld_list(l_node_counter).node_type := 0;
        l_ld_list(l_node_counter).hide_if_empty := '';
        l_ld_list(l_node_counter).node_depth := 2;
        l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
        l_node_counter := l_node_counter + 1;
      end loop;
    end if;
*/
    ieu_pub.add_uwq_node_data(p_resource_id, p_sel_enum_id, l_ld_list);
  exception
    when others then
      raise;
  end enumerate_acc_delin_nodes;
    procedure enumerate_intl_acc_delin_nodes(p_resource_id in number
                                    , p_language in varchar2
                                    , p_source_lang in varchar2
                                    , p_sel_enum_id in number) as
    l_node_label varchar2(200);
    l_ld_list ieu_pub.enumeratordatarecordlist;
    l_node_counter number;
    l_bind_list ieu_pub.bindvariablerecordlist;
    l_access varchar2(10);
    l_level varchar2(15);
    l_person_id number;
    l_check number;
    l_collector_id number;

    cursor c_person is
      select source_id
      from   jtf_rs_resource_extns
      where  resource_id = p_resource_id;

    cursor c_del_new_nodes is
      select lookup_code, meaning
      from   fnd_lookup_values
      where  lookup_type = 'IEX_UWQ_NODE_STATUS' and language = userenv('LANG');

    cursor c_node_label(in_lookup_type varchar2, in_lookup_code varchar2) is
      select meaning
      from   fnd_lookup_values
      where  lookup_type = in_lookup_type and lookup_code = in_lookup_code and language = userenv('LANG');

    cursor c_sel_enum(in_sel_enum_id number) is
      select work_q_view_for_primary_node, work_q_label_lu_type, work_q_label_lu_code
      from   ieu_uwq_sel_enumerators
      where  sel_enum_id = in_sel_enum_id;

    cursor c_collector_id is
      select collector_id
      from   ar_collectors
      where  resource_id = p_resource_id and resource_type = 'RS_RESOURCE';

    l_sel_enum_rec c_sel_enum%rowtype;
    l_complete_days varchar2(40);
    l_data_source varchar2(1000);
    l_default_where varchar2(1000);
    l_security_where varchar2(2000);
    l_node_where varchar2(2000);
    l_uwq_where varchar2(1000);
    l_org_id number;

    type tbl_wclause is table of varchar2(500)
                          index by binary_integer;

    l_str_and varchar2(100);
    l_str_del varchar2(1000);
    l_str_bkr varchar2(1000);
    l_bkr_filter varchar2(240);
    l_view_name varchar2(240);
    l_refresh_view_name varchar2(240);
    l_enablenodes varchar2(10);
    l_additional_where1 varchar2(2000);
    l_additional_where2 varchar2(2000);
    l varchar2(240);

    cursor c_org_id is
      select organization_id
      from   hr_operating_units
      where  mo_global.check_access(organization_id) = 'Y';

    cursor c_strategy_level is
      select preference_value
      from   iex_app_preferences_b
      where  preference_name = 'COLLECTIONS STRATEGY LEVEL' and org_id is null and enabled_flag = 'Y'; 

    l_strategy_level varchar2(30);
    l_group_check number;
    l_level_count number;

    cursor c_multi_level is
      select lookup_code
      from   iex_lookups_v
      where  lookup_type = 'IEX_RUNNING_LEVEL' and lookup_code = 'ACCOUNT' and iex_utilities.validate_running_level(lookup_code) = 'Y';
  begin
    set_mo_global;
    l_access := nvl(fnd_profile.value('IEX_CUST_ACCESS'), 'F');
    l_level := nvl(fnd_profile.value('IEX_ACCESS_LEVEL'), 'PARTY');
    l_complete_days := nvl(fnd_profile.value('IEX_UWQ_COMPLETION_DAYS'), 30);
    l_bkr_filter := nvl(fnd_profile.value('IEX_BANKRUPTCY_FILTER'), 'Y');
    l_str_and := ' AND ';
    l_str_del := ' AND NUMBER_OF_DELINQUENCIES > 0 ';
    l_node_counter := 0;
    l_check := 0;
    l_group_check:=0;
    open c_sel_enum(p_sel_enum_id);
    fetch c_sel_enum
    into l_sel_enum_rec;
    close c_sel_enum;
    open c_node_label(l_sel_enum_rec.work_q_label_lu_type, l_sel_enum_rec.work_q_label_lu_code);
    fetch c_node_label
    into l_node_label;
    close c_node_label;
    open c_strategy_level;
    fetch c_strategy_level
    into l_strategy_level;
    close c_strategy_level;
    select count(1)
    into   l_level_count
    from   iex_lookups_v
    where  lookup_type = 'IEX_RUNNING_LEVEL' and iex_utilities.validate_running_level(lookup_code) = 'Y';

    if l_level_count > 1 then
      open c_multi_level;
      fetch c_multi_level
      into l_strategy_level;
      close c_multi_level;
    end if;

    l_data_source := 'INTG_IEX_ACC_INTL_DLN_ALL_UWQ';
    l_view_name := 'XX_IEX_INTL_CU_DLN_UWQ_V';
    l_refresh_view_name := 'XX_IEX_INTL_CU_DLN_UWQ_V';

    --if l_strategy_level = 'ACCOUNT' then
      --l_str_bkr := ' AND NUMBER_OF_BANKRUPTCIES = 0 ';
      --l_default_where := ' RESOURCE_ID = :RESOURCE_ID and IEU_PARAM_PK_COL=''CUST_ACCOUNT_ID'' ';
      --l_security_where := ' :person_id = :person_id and collector_resource_id = -1 ';
      --l_security_where := ' 1 = 1 ';
      l_ld_list(l_node_counter).node_label := l_node_label;
      l_ld_list(l_node_counter).view_name := l_view_name;
      l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
      l_ld_list(l_node_counter).data_source := l_data_source;
      l_ld_list(l_node_counter).refresh_view_name := l_refresh_view_name;
      l_bind_list(1).bind_var_name := ':RESOURCE_ID';
      l_bind_list(1).bind_var_value := 1;
      l_bind_list(1).bind_var_data_type := 'NUMBER';

        l_ld_list(l_node_counter).refresh_view_name := l_view_name;
        --l_bind_list(2).bind_var_name := ':PERSON_ID';
        --l_bind_list(2).bind_var_value := -1;
        --l_bind_list(2).bind_var_data_type := 'NUMBER';
        --l_bind_list(2).bind_var_name := ':COLLECTOR_RESOURCE_ID';
        --l_bind_list(2).bind_var_value := -1;
        --l_bind_list(2).bind_var_data_type := 'NUMBER';

       

        --l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
      
    --end if;

    l_ld_list(l_node_counter).media_type_id := '';
    l_ld_list(l_node_counter).node_type := 0;
    l_ld_list(l_node_counter).hide_if_empty := '';
    l_ld_list(l_node_counter).node_depth := 1;
    l_node_counter := l_node_counter + 1;
 /*   l_enablenodes := nvl(fnd_profile.value('IEX_ENABLE_UWQ_STATUS'), 'N');

    if (l_enablenodes <> 'N') then
      for cur_rec in c_del_new_nodes loop
        if l_strategy_level = 'ACCOUNT' then
          if (cur_rec.lookup_code = 'ACTIVE') then
            l_node_where := l_default_where || ' AND NUMBER_OF_DELINQUENCIES > 0  AND ACTIVE_DELINQUENCIES IS NOT NULL ';
            l_data_source := 'IEX_ACC_DLN_ACT_UWQ';
          elsif (cur_rec.lookup_code = 'PENDING') then
            l_node_where := l_default_where || ' AND NUMBER_OF_DELINQUENCIES > 0 AND PENDING_DELINQUENCIES IS NOT NULL ';
            l_data_source := 'IEX_ACC_DLN_PEND_UWQ';
          elsif (cur_rec.lookup_code = 'COMPLETE') then
            l_node_where := l_default_where || ' AND NUMBER_OF_DELINQUENCIES > 0 AND COMPLETE_DELINQUENCIES IS NOT NULL ';
            l_data_source := 'IEX_ACC_DLN_COMP_UWQ';
          end if;

          --l_security_where := ' :person_id = :person_id and collector_resource_id = -1 ';
          l_security_where := ' collector_resource_id = -1 ';
          l_ld_list(l_node_counter).node_label := cur_rec.meaning;
          l_ld_list(l_node_counter).view_name := l_view_name;
          l_ld_list(l_node_counter).data_source := l_data_source;
          l_ld_list(l_node_counter).refresh_view_name := l_refresh_view_name;
          l_bind_list(1).bind_var_name := ':RESOURCE_ID';
          l_bind_list(1).bind_var_value := 1;
          l_bind_list(1).bind_var_data_type := 'NUMBER';

          if (l_access in ('P', 'F')) then
            if l_bkr_filter = 'Y' then
              l_ld_list(l_node_counter).where_clause := l_node_where || l_str_bkr;
            else
              l_ld_list(l_node_counter).where_clause := l_node_where;
            end if;

            l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
          else
            l_ld_list(l_node_counter).refresh_view_name := l_view_name;

            if l_bkr_filter = 'Y' then
              l_ld_list(l_node_counter).where_clause := l_node_where || l_str_and || l_security_where || l_str_bkr;
            else
              l_ld_list(l_node_counter).where_clause := l_node_where || l_str_and || l_security_where;
            end if;

            --l_bind_list(2).bind_var_name := ':PERSON_ID';
            --l_bind_list(2).bind_var_value := -1;
            --l_bind_list(2).bind_var_data_type := 'NUMBER';
            l_bind_list(3).bind_var_name := ':COLLECTOR_RESOURCE_ID';
            l_bind_list(3).bind_var_value := -1;
            l_bind_list(3).bind_var_data_type := 'NUMBER';
            l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
          end if;
        else
          if (cur_rec.lookup_code = 'ACTIVE') then
            l_node_where := l_default_where;
            l_data_source := 'IEX_ACC_DLN_ACT_UWQ';
          elsif (cur_rec.lookup_code = 'PENDING') then
            l_node_where := l_default_where;
            l_data_source := 'IEX_ACC_DLN_PEND_UWQ';
          elsif (cur_rec.lookup_code = 'COMPLETE') then
            l_node_where := l_default_where;
            l_data_source := 'IEX_ACC_DLN_COMP_UWQ';
          end if;

          l_ld_list(l_node_counter).node_label := cur_rec.meaning;
          l_ld_list(l_node_counter).view_name := l_view_name;
          l_ld_list(l_node_counter).data_source := l_data_source;
          l_ld_list(l_node_counter).refresh_view_name := l_refresh_view_name;
          l_bind_list(1).bind_var_name := ':RESOURCE_ID';
          l_bind_list(1).bind_var_value := -1;
          l_bind_list(1).bind_var_data_type := 'NUMBER';
          l_ld_list(l_node_counter).bind_vars := ieu_pub.set_bind_var_data(l_bind_list);
        end if;

        l_ld_list(l_node_counter).media_type_id := '';
        l_ld_list(l_node_counter).node_type := 0;
        l_ld_list(l_node_counter).hide_if_empty := '';
        l_ld_list(l_node_counter).node_depth := 2;
        l_ld_list(l_node_counter).res_cat_enum_flag := 'N';
        l_node_counter := l_node_counter + 1;
      end loop;
    end if;
*/
    ieu_pub.add_uwq_node_data(p_resource_id, p_sel_enum_id, l_ld_list);
  exception
    when others then
      raise;
  end enumerate_intl_acc_delin_nodes;
begin
  pg_debug := to_number(nvl(fnd_profile.value('IEX_DEBUG_LEVEL'), '20'));
end xxiex_uwq_delin_enums_pkg;
/
