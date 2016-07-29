DROP PACKAGE BODY APPS.XX_PA_ACC_GEN_WF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PA_ACC_GEN_WF_PKG" as
  g_table_name fnd_tables.table_name%type;
  g_id_col_name fnd_id_flexs.unique_id_column_name%type;
  g_structure_column fnd_id_flexs.set_defining_column_name%type;
  g_id_flex_num fnd_id_flex_structures_vl.id_flex_num%type;
  g_po_wf_debug varchar2(1) := nvl(fnd_profile.value('PO_SET_DEBUG_WORKFLOW_ON'), 'N');
  g_cons_capital_fees varchar2(100) := 'Consulting Fees - Expense';

  procedure dbms_debug(p_debug in varchar2) is
    i integer;
    m integer;
    c integer := 4000;
  begin
    execute immediate('begin dbms' || '_output' || '.enable(1000000); end;');
    m := ceil(length(p_debug) / c);

    for i in 1 .. m loop
      execute immediate
        ('begin dbms' || '_output' || '.put_line(''' || replace(substr(p_debug, 1 + c * (i - 1), c), '''', '''''') || '''); end;');
    end loop;
  exception
    when others then
      null;
  end dbms_debug;

  function pa_segment_lookup_set_value(p_lookup_set in varchar2, p_lookup_code in varchar2)
    return varchar2 is
    x_lookup varchar2(30);
  begin
    select segment_value
    into   x_lookup
    from   pa_segment_value_lookups valuex, pa_segment_value_lookup_sets sets
    where      sets.segment_value_lookup_set_id = valuex.segment_value_lookup_set_id
           and sets.segment_value_lookup_set_name = p_lookup_set
           and valuex.segment_value_lookup = p_lookup_code;
    return x_lookup;
  exception
    when others then
      return null;
  end;

  function build_sql(nosegments in number)
    return clob is
    l_sql clob;
    l_string clob;
    l_from varchar2(1000);
    l_where varchar2(1000);
    l_select varchar2(1000);
    crlf constant varchar2(1) := '
';
  begin
    for i in 1 .. nosegments loop
      if i <> nosegments then
        l_string := l_string || 'segment' || i || ',';
      elsif i = nosegments then
        l_string := l_string || 'segment' || i || crlf;
        l_from := 'from ' || g_table_name || crlf;
        l_where := 'where  ' || g_id_col_name || '= :id1' || crlf;
        l_where := l_where || 'and  ' || g_structure_column || '= :id2' || crlf;
      end if;
    end loop;

    l_select := 'select ' || crlf;
    l_string := l_select || l_string || l_from || l_where;
    l_sql := l_string;
    return l_sql;
  exception
    when others then
      wf_core.context(pkg_name => 'XX_PA_ACC_GEN_WF_PKG '
                    , proc_name => 'BUILD_SQL'
                    , arg1 => 'Unable to build SQL'
                    , arg2 => null
                    , arg3 => null
                    , arg4 => null
                    , arg5 => null);
      return 'select segment1,segment2,segment3,segment4,segment5,segment6,segment7,
                  segment8 from  PAY_COST_ALLOCATION_KEYFLEX
                  where  COST_ALLOCATION_KEYFLEX_ID= :id1
                  and  ID_FLEX_NUM= :id2';
  end;

  procedure bind_variable(p_cursor in integer, p_column in varchar2, p_value in varchar2) is
  begin
    dbms_sql.bind_variable(p_cursor, p_column, p_value);
  end;

  procedure define_column(p_cursor in integer, p_position in number, p_column in varchar2) is
  begin
    dbms_sql.define_column(p_cursor, p_position, p_column, 400);
  end;

  function column_values(p_cursor in integer, p_position in number, p_column in varchar2)
    return varchar2 is
    l_column varchar2(400);
  begin
    l_column := p_column;
    dbms_sql.column_value(p_cursor, p_position, l_column);
    return l_column;
  end;

  procedure set_org_attributes(p_itemtype in varchar2
                             , p_itemkey in varchar2
                             , p_actid in number
                             , p_funcmode in varchar2
                             , x_result   out varchar2) is
    flexfield fnd_flex_key_api.flexfield_type;
    structures fnd_flex_key_api.structure_type;
    segments fnd_flex_key_api.segment_list;
    no_segments integer;
    l_clob clob;
    s integer;
    t integer;
    l_carry_out_org_id number;
    x_column varchar2(100);
    l_org_id number;
    l_billable_flag varchar2(1);
    l_ou_name varchar2(40);
    l_subacct_map varchar2(100);
    l_segment_value varchar2(100);
    l_cost_keyflex_id number;
    l_project_id number;
    l_task_id number;
    x_progress varchar2(5000);
    l_expenditure_type varchar2(100);
    l_coa_id number;
    l_delimiter varchar2(1);
    l_company varchar2(30);
    l_department varchar2(30);
    l_account varchar2(30);
    l_classification varchar2(30);
    l_region varchar2(30);
    l_product varchar2(30);
    l_intercompany varchar2(30) := '000';
    l_future varchar2(30) := '00000';
    l_concatenated_segs varchar2(500);
    x_eff_date date := sysdate;
    l_ccid number;
    task_org_id number;
  begin
    x_result := 'COMPLETE:SUCCESS';
    l_billable_flag := 'N';
    x_progress := 'INTG: Entering xx_pa_acc_gen_wf_pkg.set_org_attributes';

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    l_carry_out_org_id := wf_engine.getitemattrnumber(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'PROJECT_ORGANIZATION_ID');
    l_project_id := wf_engine.getitemattrnumber(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'PROJECT_ID');
    l_expenditure_type := wf_engine.getitemattrtext(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'EXPENDITURE_TYPE');
    l_task_id := wf_engine.getitemattrnumber(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'TASK_ID');
    l_coa_id := wf_engine.getitemattrnumber(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'CHART_OF_ACCOUNTS_ID');
    l_delimiter := fnd_flex_ext.get_delimiter('SQLGL', 'GL#', l_coa_id);
    x_progress := 'INTG: Project ID is ' || l_project_id;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    x_progress := 'INTG: Task ID is ' || l_task_id;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    x_progress := 'INTG: Expenditure Type is ' || l_expenditure_type;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    x_progress := 'INTG: Project Organization ID is ' || l_carry_out_org_id;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    segments.delete;
    fnd_flex_key_api.set_session_mode(session_mode => 'seed_data');
    flexfield := fnd_flex_key_api.find_flexfield(appl_short_name => 'PAY', flex_code => 'COST');
    g_table_name := flexfield.table_name;
    g_id_col_name := flexfield.unique_id_column;
    g_structure_column := flexfield.structure_column;
    structures := fnd_flex_key_api.find_structure(flexfield, 'INTG_COST_ALLOCATION_KF');
    g_id_flex_num := structures.structure_number;
    fnd_flex_key_api.get_segments(flexfield
                                , structures
                                , true
                                , no_segments
                                , segments);
    l_clob := build_sql(no_segments);

    --dbms_debug(l_clob);
    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, 'SQL to get segments is:' || l_clob);
    end if;

    s := dbms_sql.open_cursor;
    dbms_sql.parse(s, l_clob, dbms_sql.native);

    for i in 1 .. segments.count() loop
      define_column(s, i, segments(i));
    end loop;

    select cost_allocation_keyflex_id
    into   l_cost_keyflex_id
    from   hr_organization_units
    where  organization_id = l_carry_out_org_id;
    bind_variable(s, 'id1', l_cost_keyflex_id);
    bind_variable(s, 'id2', g_id_flex_num);
    t := dbms_sql.execute(s);

    loop
      if dbms_sql.fetch_rows(s) > 0 then
        for i in 1 .. segments.count() loop
          x_column := column_values(s, i, segments(i));
          --dbms_debug(upper(segments(i)) || '=' || x_column);
          --dbms_debug('INTG_COST_KFF_' || upper(segments(i)));
          x_progress := 'INTG: Setting value for :' || 'INTG_COST_KFF_' || upper(segments(i) || ' and value is ' || x_column);

          if (g_po_wf_debug = 'Y') then
            po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
          end if;

          if upper(segments(i)) = 'COMPANY' then
            l_company := x_column;
          elsif upper(segments(i)) = 'REGION' then
            l_region := x_column;
          elsif upper(segments(i)) = 'DEPARTMENT' then
            l_department := x_column;
          elsif upper(segments(i)) = 'PRODUCT' then
            l_product := x_column;
          end if;

          wf_engine.
          setitemattrtext(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'INTG_COST_KFF_' || upper(segments(i)), avalue => x_column);
        end loop;
      else
        exit;
      end if;
    end loop;

    dbms_sql.close_cursor(s);

    begin
      select carrying_out_organization_id
      into   task_org_id
      from   pa_tasks pt
      where  1 = 1 and pt.project_id = l_project_id and pt.task_id = l_task_id;
      select cost_allocation_keyflex_id
      into   l_cost_keyflex_id
      from   hr_organization_units
      where  organization_id = task_org_id;
      select segment2
      into   l_department
      from   pay_cost_allocation_keyflex
      where  cost_allocation_keyflex_id = l_cost_keyflex_id and id_flex_num = g_id_flex_num;
    exception
      when others then
        l_department := null;
    end;

    if p_itemtype = 'PAAPINVW' then
      l_org_id := wf_engine.getitemattrnumber(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'ORG_ID');
    end if;

    x_progress := 'INTG: ORG_ID is ' || l_org_id;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    if l_org_id is null then
      x_progress := 'INTG: ORG_ID is NULL. Getting it from project or pa_implementations';

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
      end if;

      begin
        select org_id
        into   l_org_id
        from   pa_projects_all
        where  project_id = l_project_id;
      exception
        when others then
          select org_id
          into   l_org_id
          from   pa_implementations;
      end;
    end if;

    x_progress := 'INTG: ORG_ID from projects is: ' || l_org_id;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    select name
    into   l_ou_name
    from   hr_operating_units
    where  organization_id = l_org_id;
    x_progress := 'INTG: Operating Unit Name is ' || l_ou_name;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    l_segment_value := pa_segment_lookup_set_value('INTG_OU_COUNTRY_MAPPING', l_ou_name);
    x_progress := 'INTG: mapped value for OU name in lookup set INTG_OU_COUNTRY_MAPPING is ' || l_segment_value;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    if p_itemtype = 'PAAPINVW' then
      l_billable_flag := nvl(wf_engine.getitemattrtext(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'BILLABLE_FLAG'), 'N');
    elsif p_itemtype in ('POWFRQAG', 'POWFPOAG') then
      select pt.billable_flag
      into   l_billable_flag
      from   pa_tasks pt
      where  1 = 1 and pt.project_id = l_project_id and pt.task_id = l_task_id;
      x_progress := 'INTG: billable flag is :' || l_billable_flag;

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
      end if;

      x_progress := 'INTG: Setting billable flag for PO and REQ';

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
      end if;

      wf_engine.setitemattrtext(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'PA_BILLABLE_FLAG', avalue => l_billable_flag);
    end if;

    if l_billable_flag = 'Y' then
      l_subacct_map := l_segment_value || '_CAPITAL_SUBACCOUNT';
      x_progress := 'INTG: Sub Account Mapping lookup set for Capital Project :' || l_subacct_map;

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
      end if;

      l_account := pa_segment_lookup_set_value('INTG_CAPITAL_ACCOUNT', l_expenditure_type);
      l_classification := pa_segment_lookup_set_value(l_subacct_map, l_expenditure_type);
      wf_engine.
      setitemattrtext(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'INTG_CAPITAL_EXP_TYPE_SUBACCT', avalue => l_subacct_map);

      if l_expenditure_type <> g_cons_capital_fees then
        l_department := '0000';
        l_product := '500';
      end if;
    elsif l_billable_flag = 'N' then
      l_subacct_map := l_segment_value || '_NONCAP_SUBACCOUNT';
      x_progress := 'INTG: Sub Account Mapping lookup set for Non Capital Project :' || l_subacct_map;

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
      end if;

      l_account := pa_segment_lookup_set_value('INTG_NONCAP_ACCOUNT', l_expenditure_type);
      l_classification := pa_segment_lookup_set_value(l_subacct_map, l_expenditure_type);
      wf_engine.setitemattrtext(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'INTG_NONCAP_EXP_TYPE_SUBACCT', avalue => l_subacct_map);
    end if;

    l_concatenated_segs :=    l_company
                           || l_delimiter
                           || l_department
                           || l_delimiter
                           || l_account
                           || l_delimiter
                           || l_classification
                           || l_delimiter
                           || l_product
                           || l_delimiter
                           || l_region
                           || l_delimiter
                           || l_intercompany
                           || l_delimiter
                           || l_future;
    x_progress := 'INTG: Concatenated segments are :' || l_concatenated_segs;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    l_ccid := fnd_flex_ext.get_ccid('SQLGL'
                                  , 'GL#'
                                  , l_coa_id
                                  , to_char(x_eff_date, 'YYYY/MM/DD HH24:MI:SS')
                                  , l_concatenated_segs);
    x_progress := 'INTG: CCID :' || l_ccid;

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    if l_ccid > 0 or l_ccid is not null then
      wf_engine.setitemattrnumber(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'INTG_CODE_COMBINATION_ID', avalue => l_ccid);

      if p_itemtype in ('POWFRQAG', 'POWFPOAG') then
        wf_engine.setitemattrnumber(itemtype => p_itemtype, itemkey => p_itemkey, aname => 'TEMP_ACCOUNT_ID', avalue => l_ccid);
      end if;
    else
      x_result := 'COMPLETE:FAILURE';
      return;
    end if;

    x_progress := 'INTG: Exiting xx_pa_acc_gen_wf_pkg.set_org_attributes';

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
    end if;

    x_result := 'COMPLETE:SUCCESS';
    return;
  exception
    when others then
      if dbms_sql.is_open(s) then
        dbms_sql.close_cursor(s);
      end if;

      x_progress := 'INTG: In exception in xx_pa_acc_gen_wf_pkg.set_org_attributes';

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(p_itemtype, p_itemkey, x_progress);
      end if;

      x_result := 'COMPLETE:FAILURE';
      return;
  end;

  function get_ccid(p_project_id in number
                  , p_task_id in number
                  , p_expenditure_type in varchar2
                  , p_organization_id in number
                  , p_org_id in number)
    return number is
    flexfield fnd_flex_key_api.flexfield_type;
    structures fnd_flex_key_api.structure_type;
    segments fnd_flex_key_api.segment_list;
    no_segments integer;
    l_clob clob;
    s integer;
    t integer;
    l_carry_out_org_id number;
    x_column varchar2(100);
    l_org_id number;
    l_billable_flag varchar2(1);
    l_ou_name varchar2(40);
    l_subacct_map varchar2(100);
    l_segment_value varchar2(100);
    l_cost_keyflex_id number;
    l_project_id number;
    l_task_id number;
    x_progress varchar2(5000);
    l_expenditure_type varchar2(100);
    l_coa_id number;
    l_delimiter varchar2(1);
    l_company varchar2(30);
    l_department varchar2(30);
    l_account varchar2(30);
    l_classification varchar2(30);
    l_region varchar2(30);
    l_product varchar2(30);
    l_intercompany varchar2(30) := '000';
    l_future varchar2(30) := '00000';
    l_concatenated_segs varchar2(500);
    x_eff_date date := sysdate;
    l_ccid number;
    x_result varchar2(400);
  begin
    x_result := 'COMPLETE:SUCCESS';
    l_billable_flag := 'N';
    l_project_id := p_project_id;
    l_expenditure_type := p_expenditure_type;
    l_task_id := p_task_id;
    l_carry_out_org_id := p_organization_id;
    l_org_id := p_org_id;
    select chart_of_accounts_id
    into   l_coa_id
    from   hr_operating_units a, gl_ledgers b
    where  organization_id = l_org_id and a.set_of_books_id = b.ledger_id;
    dbms_debug(l_coa_id);
    l_delimiter := fnd_flex_ext.get_delimiter('SQLGL', 'GL#', l_coa_id);
    segments.delete;
    fnd_flex_key_api.set_session_mode(session_mode => 'seed_data');
    flexfield := fnd_flex_key_api.find_flexfield(appl_short_name => 'PAY', flex_code => 'COST');
    g_table_name := flexfield.table_name;
    g_id_col_name := flexfield.unique_id_column;
    g_structure_column := flexfield.structure_column;
    structures := fnd_flex_key_api.find_structure(flexfield, 'INTG_COST_ALLOCATION_KF');
    g_id_flex_num := structures.structure_number;
    fnd_flex_key_api.get_segments(flexfield
                                , structures
                                , true
                                , no_segments
                                , segments);
    l_clob := build_sql(no_segments);
    s := dbms_sql.open_cursor;
    dbms_sql.parse(s, l_clob, dbms_sql.native);

    for i in 1 .. segments.count() loop
      define_column(s, i, segments(i));
    end loop;

    select cost_allocation_keyflex_id
    into   l_cost_keyflex_id
    from   hr_organization_units
    where  organization_id = l_carry_out_org_id;
    bind_variable(s, 'id1', l_cost_keyflex_id);
    bind_variable(s, 'id2', g_id_flex_num);
    t := dbms_sql.execute(s);

    loop
      if dbms_sql.fetch_rows(s) > 0 then
        for i in 1 .. segments.count() loop
          x_column := column_values(s, i, segments(i));
          dbms_debug(upper(segments(i)) || '=' || x_column);
          dbms_debug('INTG_COST_KFF_' || upper(segments(i)));

          if upper(segments(i)) = 'COMPANY' then
            l_company := x_column;
          elsif upper(segments(i)) = 'REGION' then
            l_region := x_column;
          elsif upper(segments(i)) = 'DEPARTMENT' then
            l_department := x_column;
          elsif upper(segments(i)) = 'PRODUCT' then
            l_product := x_column;
          end if;
        end loop;
      else
        exit;
      end if;
    end loop;

    dbms_sql.close_cursor(s);

    if l_org_id is null then
      begin
        select org_id
        into   l_org_id
        from   pa_projects_all
        where  project_id = l_project_id;
      exception
        when others then
          select org_id
          into   l_org_id
          from   pa_implementations;
      end;
    end if;

    select name
    into   l_ou_name
    from   hr_operating_units
    where  organization_id = l_org_id;
    l_segment_value := pa_segment_lookup_set_value('INTG_OU_COUNTRY_MAPPING', l_ou_name);
    dbms_debug(l_segment_value);
    select pt.billable_flag
    into   l_billable_flag
    from   pa_tasks pt
    where  1 = 1 and pt.project_id = l_project_id and pt.task_id = l_task_id;

    if l_billable_flag = 'Y' then
      l_subacct_map := l_segment_value || '_CAPITAL_SUBACCOUNT';
      l_account := pa_segment_lookup_set_value('INTG_CAPITAL_ACCOUNT', l_expenditure_type);
      l_classification := pa_segment_lookup_set_value(l_subacct_map, l_expenditure_type);

      if l_expenditure_type <> g_cons_capital_fees then
        l_department := '0000';
        l_product := '500';
      end if;
    elsif l_billable_flag = 'N' then
      l_subacct_map := l_segment_value || '_NONCAP_SUBACCOUNT';
      l_account := pa_segment_lookup_set_value('INTG_NONCAP_ACCOUNT', l_expenditure_type);
      l_classification := pa_segment_lookup_set_value(l_subacct_map, l_expenditure_type);
    end if;

    dbms_debug(l_subacct_map);
    dbms_debug(l_account);
    dbms_debug(l_classification);
    l_concatenated_segs :=    l_company
                           || l_delimiter
                           || l_department
                           || l_delimiter
                           || l_account
                           || l_delimiter
                           || l_classification
                           || l_delimiter
                           || l_product
                           || l_delimiter
                           || l_region
                           || l_delimiter
                           || l_intercompany
                           || l_delimiter
                           || l_future;
    dbms_debug(l_concatenated_segs);
    l_ccid := fnd_flex_ext.get_ccid('SQLGL'
                                  , 'GL#'
                                  , l_coa_id
                                  , to_char(x_eff_date, 'YYYY/MM/DD HH24:MI:SS')
                                  , l_concatenated_segs);

    if l_ccid > 0 or l_ccid is not null then
      x_result := 'COMPLETE:SUCCESS';
      return l_ccid;
    else
      x_result := 'COMPLETE:FAILURE';
      return 0;
    end if;
  exception
    when others then
      if dbms_sql.is_open(s) then
        dbms_sql.close_cursor(s);
      end if;

      x_result := 'COMPLETE:FAILURE';
      return -1;
  end;

  procedure intg_auto_create_flag(itemtype in   varchar2
                                , itemkey in    varchar2
                                , actid in      number
                                , funcmode in   varchar2
                                , resultout   out nocopy varchar2) is
    l_auto_create_flag varchar2(10);
    x_suggested_vendor_id number;
    l_vendor_type varchar2(100);
    x_progress varchar2(4000);
    l_req_id number;
  begin
    l_auto_create_flag := 'N';
    l_req_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'REQ_HEADER_ID');

    if l_req_id is not null then
      begin
        select 'Y'
        into   l_auto_create_flag
        from   po_requisition_headers_all prh
        where  requisition_header_id = l_req_id
               and exists
                     (select 1
                      from   po_requisition_lines_all prl, po_vendors pov
                      where      prh.requisition_header_id = prl.requisition_header_id
                             and prl.vendor_id = pov.vendor_id
                             and pov.vendor_type_lookup_code = 'INTERCOMPANY'
                             and prl.source_type_code = 'VENDOR'
                             and prl.document_type_code = 'CONTRACT'
                      union
                      select 1
                      from   po_requisition_lines_all prl, po_vendors pov
                      where      prh.requisition_header_id = prl.requisition_header_id
                             and prl.vendor_id = pov.vendor_id
                             and nvl(pov.vendor_type_lookup_code, 'VENDOR') <> 'INTERCOMPANY'
                             and prl.source_type_code = 'VENDOR'
                             and prl.document_type_code = 'BLANKET');
      exception
        when others then
          l_auto_create_flag := 'N';
      end;
    end if;

    po_wf_util_pkg.setitemattrtext(itemtype => itemtype, itemkey => itemkey, aname => 'AUTOCREATE_DOC', avalue => l_auto_create_flag);

    if l_auto_create_flag = 'Y' then
      x_progress := '10: INTG should_req_be_autocreated: result = ' || l_auto_create_flag;

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      end if;
    else
      x_progress := '20: should_req_be_autocreated: result = N';

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      end if;
    end if;

    resultout := wf_engine.eng_completed || ':' || 'Y';
  exception
    when others then
      wf_core.context('po_autocreate_doc', 'intg_auto_create_flag', x_progress);
      raise;
  end intg_auto_create_flag;

  procedure intg_auto_approve_flag(itemtype in   varchar2
                                 , itemkey in    varchar2
                                 , actid in      number
                                 , funcmode in   varchar2
                                 , resultout   out nocopy varchar2) is
    l_po_header_id number;
    x_suggested_vendor_id number;
    l_vendor_type varchar2(100);
    x_progress varchar2(4000);
    l_auto_approve_flag varchar2(1);
  begin
    l_auto_approve_flag := 'N';
    l_po_header_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'AUTOCREATED_DOC_ID');

    if l_po_header_id is not null then
      begin
        select 'Y'
        into   l_auto_approve_flag
        from   po_headers_all ph, po_vendors pov
        where  po_header_id = l_po_header_id and ph.vendor_id = pov.vendor_id and pov.vendor_type_lookup_code = 'INTERCOMPANY';
      exception
        when others then
          l_auto_approve_flag := 'N';
      end;
    end if;

    if l_auto_approve_flag = 'Y' then
      x_progress := '10: INTG should_po_be_autoapproved: result = ' || l_auto_approve_flag;

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      end if;
    else
      x_progress := '20: should_po_be_autoapproved: result = N';

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      end if;
    end if;

    if l_auto_approve_flag = 'Y' then
      resultout := wf_engine.eng_completed || ':' || 'Y';
    elsif l_auto_approve_flag = 'N' then
      resultout := wf_engine.eng_completed || ':' || 'N';
    end if;
  exception
    when others then
      wf_core.context('po_autocreate_doc', 'intg_auto_approce_flag', x_progress);
      raise;
  end intg_auto_approve_flag;

  function get_117_trx_flow_header_id(p_inventory_item_id number, p_po_ou_id in number, p_inv_org_ou_id in number)
    return number is
    l_logical_inv_org_id number := null;
    l_trx_flow_hdr_id number;
  begin
    select header_id
    into   l_trx_flow_hdr_id
    from   mtl_transaction_flow_headers a
    where      start_org_id = p_po_ou_id
           and end_org_id = p_inv_org_ou_id
           and exists
                 (select from_organization_id
                  from   mtl_transaction_flow_lines b
                  where      from_organization_id = (select organization_id
                                                     from   mtl_parameters
                                                     where  organization_code = '117')
                         and line_number = 1
                         and a.header_id = b.header_id);
    return l_trx_flow_hdr_id;
  exception
    when no_data_found then
      return null;
    when others then
      raise;
  end get_117_trx_flow_header_id;

  procedure intg_trx_flow_header(itemtype in   varchar2
                               , itemkey in    varchar2
                               , actid in      number
                               , funcmode in   varchar2
                               , resultout   out nocopy varchar2) is
    l_po_header_id number;
    x_suggested_vendor_id number;
    l_vendor_type varchar2(100);
    x_progress varchar2(4000);
    l_organization_code varchar2(30);
    l_po_ou_id number;
    l_ship_to_ou_id number;
    l_trx_flow_header_id number;
    p_trx_flow_header_id number;
    l_item_id number;
    l_log_inv_org_id number;
    l_exists varchar2(1);
  begin
    l_item_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ITEM_ID');
    l_ship_to_ou_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'SHIP_TO_OU_ID');
    l_po_ou_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'PURCHASING_OU_ID');
    p_trx_flow_header_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'TRANSACTION_FLOW_HEADER_ID');

    if l_item_id is not null then
      x_progress := '10: INTG item_ID check = ' || l_item_id;

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      end if;

      begin
        select 'Y'
        into   l_exists
        from   dual
        where  exists
                 (select b.organization_code
                  from   po_approved_supplier_list a, mtl_parameters b
                  where      item_id = l_item_id
                         and nvl(disable_flag, 'N') = 'N'
                         and a.owning_organization_id = b.organization_id
                         and b.organization_code = '117'
                  union
                  select b.organization_code
                  from   mtl_system_items_b a, mtl_parameters b
                  where      inventory_item_id = l_item_id
                         and a.organization_id = b.organization_id
                         and b.organization_code = '117'
                         and purchasing_enabled_flag = 'Y');
      exception
        when others then
          l_exists := null;
      end;

      if l_exists = 'Y' then
        l_trx_flow_header_id := get_117_trx_flow_header_id(l_item_id, l_po_ou_id, l_ship_to_ou_id);
        x_progress := '10: INTG transaction flow header_id = ' || l_trx_flow_header_id;

        if (g_po_wf_debug = 'Y') then
          po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
        end if;
      end if;
    else
      x_progress := '20: Item ID is null';

      if (g_po_wf_debug = 'Y') then
        po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
      end if;
    end if;

    if l_trx_flow_header_id is not null then
      po_wf_util_pkg.
      setitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'TRANSACTION_FLOW_HEADER_ID', avalue => l_trx_flow_header_id);
      l_log_inv_org_id := po_shared_proc_pvt.get_logical_inv_org_id(l_trx_flow_header_id);
      po_wf_util_pkg.
      setitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'INTG_PROCURING_INV_ORG_ID', avalue => l_log_inv_org_id);
    else
      l_log_inv_org_id := po_shared_proc_pvt.get_logical_inv_org_id(p_trx_flow_header_id);
      po_wf_util_pkg.
      setitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'INTG_PROCURING_INV_ORG_ID', avalue => l_log_inv_org_id);
    end if;

    resultout := wf_engine.eng_completed || ':' || 'Y';
  exception
    when others then
      wf_core.context('PO Account Generator', 'intg_trx_flow_header', x_progress);
      resultout := wf_engine.eng_completed || ':' || 'N';
      raise;
  end intg_trx_flow_header;

  procedure aa_from_org(itemtype in varchar2, itemkey in varchar2, actid in number, funcmode in varchar2, result out nocopy varchar2) is
    x_progress varchar2(100);
    x_account number;
    x_dest_org_id number;
    x_item_id number;
    x_status varchar2(1);
    x_vendor_site_id number;
    x_msg_data varchar2(2000);
    x_msg_count number;
    l_purchasing_ou_id number;
    dummy varchar2(40);
    ret boolean;
  begin
    x_progress := 'xx_pa_acc_gen_wf_pkg.AA_from_org : 01';

    if (g_po_wf_debug = 'Y') then
      po_wf_debug_pkg.insert_debug(itemtype, itemkey, x_progress);
    end if;

    -- Do nothing in cancel or timeout mode
    --
    if (funcmode <> wf_engine.eng_run) then
      result := wf_engine.eng_null;
      return;
    end if;

    x_dest_org_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'INTG_PROCURING_INV_ORG_ID');
    x_item_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'ITEM_ID');
    l_purchasing_ou_id := po_wf_util_pkg.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'PURCHASING_OU_ID');

    begin
      if x_item_id is not null then
        select ap_accrual_account
        into   x_account
        from   mtl_parameters
        where  organization_id = x_dest_org_id;
      else --treating it as an expense item.
        select accrued_code_combination_id
        into   x_account
        from   po_system_parameters_all
        where  org_id = l_purchasing_ou_id;
      end if;

      --
      po_wf_util_pkg.setitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'TEMP_ACCOUNT_ID', avalue => x_account);
    exception
      when no_data_found then
        null;
    end;

    if (x_account is not null) then
      result := 'COMPLETE:SUCCESS';
    else
      result := 'COMPLETE:FAILURE';
    end if;

    return;
  exception
    when others then
      wf_core.context('xx_pa_acc_gen_wf_pkg', 'AA_from_org', x_progress);
      raise;
  end aa_from_org;
end xx_pa_acc_gen_wf_pkg; 
/
