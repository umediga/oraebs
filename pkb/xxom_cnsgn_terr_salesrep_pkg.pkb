DROP PACKAGE BODY APPS.XXOM_CNSGN_TERR_SALESREP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_CNSGN_TERR_SALESREP_PKG"
AS
  ----------------------------------------------------------------------
  /* $Header: xxom_cnsgn_terr_salesrep_pkg.pks 1.0 2014/02/24 12:00:00 dparida noship $ */
  /*
  Created By     : Brian Stadnik.
  Creation Date  : 02/24/2014
  File Name      : xxom_cnsgn_terr_salesrep_pkg.pkb
  Description    : This program send territory, customer and sales rep data to surgisoft.
  Change History:
  Version Date        Name                    Remarks
  ------- ----------- --------------    ----------------------
  1.0     02-FEB-2014  Brian Stadnik    Initial development.
  2.0     15-JUN-2015  Sri Venkataraman  Org Id hard code changed to 101.
  3.0     25-MAR-2016  Kannan Mariappan  Updated to select territory name like following '510%REGION' Tag for the changes:"KM20160325"
  3.1     13-MAY-2016  Kannan Mariappan  Added extra validations for performance issue: Tag for the changes:"KM20160513"
  */
  ----------------------------------------------------------------------
  g_itemkey VARCHAR2(100):='TERR';
PROCEDURE log_message(
    p_log_message IN VARCHAR2)
IS
  pragma autonomous_transaction;
BEGIN
  INSERT
  INTO xxintg_cnsgn_cmn_log_tbl VALUES
    (
      xxintg_cnsgn_cmn_log_seq.nextval,
      'CONSGN-TERR',
      g_itemkey
      ||':'
      ||p_log_message,
      sysdate
    );
  COMMIT;

END LOG_MESSAGE;
FUNCTION get_tab_cols
  RETURN dbms_sql.desc_tab
IS
  s          INTEGER;
  t          INTEGER;
  l_colcount NUMBER;
  l_colmns dbms_sql.desc_tab;
  l_view VARCHAR2(30);
  --crlf constant varchar2(1) := ' ';
  sql_stmt   VARCHAR2(1000) := 'select * from $TABLE_NAME$';
  l_sql_stmt VARCHAR2(1000);
  l_stmt     VARCHAR2(4000);
BEGIN
  l_view := NULL;
  l_view := 'XX_TERR_QUAL_GT';
  l_colmns.delete;
  l_colcount := 0;
  l_sql_stmt := NULL;
  l_sql_stmt := sql_stmt;
  l_sql_stmt := REPLACE(l_sql_stmt, '$TABLE_NAME$', l_view);
  s          := dbms_sql.open_cursor;
  dbms_sql.parse(s, l_sql_stmt, dbms_sql.native);
  dbms_sql.describe_columns(s, l_colcount, l_colmns);
  dbms_sql.close_cursor(s);
  RETURN l_colmns;
EXCEPTION
WHEN OTHERS THEN
  dbms_output.put(sqlerrm);
  IF dbms_sql.is_open(s) THEN
    dbms_sql.close_cursor(s);
  END IF;
END get_tab_cols;
FUNCTION enabled_qualifiers
  RETURN VARCHAR2
IS
type t_array_char
IS
  TABLE OF VARCHAR2
  (
    80
  )
  INDEX BY binary_integer;
  l_conc_seg_delimiter VARCHAR2(80);
  l_qualifiers         VARCHAR2(4000);
  l_array t_array_char;
  CURSOR c
  IS
    SELECT a.comparison_operator
    FROM jtf_qual_usgs_all a,
      jty_all_enabled_attributes_v b
    WHERE a.qual_type_usg_id = -1001
    AND a.qual_type_usg_id   = b.qual_type_usg_id
    AND a.qual_usg_id        = b.qual_usg_id
      --               and org_id = 82
    AND org_id         = 101
    AND a.enabled_flag = 'Y'
    ORDER BY a.qual_usg_id DESC;
BEGIN
  OPEN c;
  FETCH c bulk collect INTO l_array;
  CLOSE c;
  FOR i IN 1 .. l_array.count
  LOOP
    l_qualifiers   := l_qualifiers || l_array(i);
    IF i            < l_array.count THEN
      l_qualifiers := l_qualifiers || ' , ';
    END IF;
  END LOOP;
  RETURN l_qualifiers;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END enabled_qualifiers;
PROCEDURE get_distinct_terr
IS
  l_clob CLOB;
  cur INTEGER;
  exe INTEGER;
BEGIN
  log_message('In get_distict_terr');
  DELETE xx_terr_qual_gt;
  log_message('In get_distict_terr - After Delete');
  l_clob := 'insert into xx_terr_qual_gt (terr_id,' || crlf;
  l_clob := l_clob || enabled_qualifiers || crlf;
  l_clob := l_clob || ')' || crlf;
  l_clob := l_clob || ' select distinct terr_id,' || crlf;
  l_clob := l_clob || enabled_qualifiers || crlf;
  l_clob := l_clob || ' from JTY_1001_DENORM_ATTR_VALUES ' || crlf;
  l_clob := l_clob || ' where source_id=-1001 ' || crlf;
  --l_clob := l_clob || 'and qual_col1_table is not null' || crlf;
  l_clob := l_clob || ' group by terr_id, ' || crlf;
  l_clob := l_clob || enabled_qualifiers || crlf;
  log_message('Clob ' || l_clob);
  cur := dbms_sql.open_cursor;
  dbms_sql.parse(cur, l_clob, dbms_sql.native);
  exe := dbms_sql.execute(cur);
  dbms_sql.close_cursor(cur);
  log_message('Leaving .. In get_distict_terr');
EXCEPTION
WHEN OTHERS THEN
  log_message(sqlerrm);
  IF dbms_sql.is_open(cur) THEN
    dbms_sql.close_cursor(cur);
  END IF;
END;
FUNCTION get_sql
  RETURN VARCHAR2
IS
  l_sql     VARCHAR2(32000);
  l_upd_sql VARCHAR2(32000);
  l_cols dbms_sql.desc_tab;
  l_col_name VARCHAR2(30);
  l_table    VARCHAR2(30);
  l_where    VARCHAR2(4000);
BEGIN
  log_message('Get SQL . ');
  l_cols := get_tab_cols;
  get_distinct_terr;
  log_message('Get SQL .. Before Loop ');
  FOR i IN 1 .. l_cols.count()
  LOOP
    BEGIN
      l_sql := 'update xx_terr_qual_gt xx' || crlf;
      l_sql := l_sql || ' set (' || l_cols(i).col_name || '_tbl,' || crlf;
      l_sql := l_sql || l_cols(i).col_name || '_sql) = ' || crlf;
      l_sql := l_sql || ' (select qual_col1_table, real_time_where ' || crlf;
      l_sql := l_sql || ' from jtf_qual_usgs_all a, jty_all_enabled_attributes_v b ' || crlf;
      l_sql := l_sql || ' where a.qual_type_usg_id = -1001' || crlf;
      l_sql := l_sql || ' and a.qual_type_usg_id = b.qual_type_usg_id' || crlf;
      l_sql := l_sql || ' and a.qual_usg_id = b.qual_usg_id' || crlf;
      --      l_sql := l_sql || ' and org_id = 82' || crlf;
      l_sql := l_sql || ' and org_id = 101' || crlf;
      l_sql := l_sql || ' and a.enabled_flag = ''Y''' || crlf;
      l_sql := l_sql || ' and upper(a.comparison_operator) = ''' || upper(l_cols(i).col_name) || ''')' || crlf;
      l_sql := l_sql || ' where ' || l_cols(i).col_name || ' is not null';
      --log_message(l_sql);
      UPDATE xx_terr_qual_gt
      SET q1012_cp_sql    = REPLACE(q1012_cp_sql, 'comp_name_range', 'party_name')
      WHERE q1012_cp_sql IS NOT NULL
      AND q1012_cp_sql LIKE '%comp_name_range%';
      EXECUTE immediate l_sql;
      l_upd_sql := 'update xx_terr_qual_gt xx ' || crlf;
      l_upd_sql := l_upd_sql || ' set ' || l_cols(i).col_name || '_sql =' || crlf;
      l_upd_sql := l_upd_sql || ' replace(' || l_cols(i).col_name || '_sql,''A.txn_date'',''sysdate'')' || crlf;
      l_upd_sql := l_upd_sql || ' where ' || l_cols(i).col_name || '_sql is not null' || crlf;
      l_upd_sql := l_upd_sql || ' and ' || l_cols(i).col_name || '_sql like ''%txn_date%''';
      --log_message(l_upd_sql);
      EXECUTE immediate l_upd_sql;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END LOOP;
  log_message('Get SQL . ' || l_sql);
  RETURN l_sql;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END;
PROCEDURE get_terr_data
IS
  l_sql        VARCHAR2(32000);
  l_table      VARCHAR2(30);
  l_terr_id    NUMBER;
  l_insert_sql VARCHAR2(4000);
  l_select_sql VARCHAR2(3000);
  l_where_sql  VARCHAR2(4000);
  l_exe_sql    VARCHAR2(4000);
  l_col        VARCHAR2(30);
  s            INTEGER;
  t            INTEGER;
  l_cols dbms_sql.desc_tab;
  CURSOR c
  IS
    SELECT DISTINCT upper(a.comparison_operator) col_name
    FROM jtf_qual_usgs_all a,
      jty_all_enabled_attributes_v b
    WHERE a.qual_type_usg_id = -1001
    AND a.qual_type_usg_id   = b.qual_type_usg_id
    AND a.qual_usg_id        = b.qual_usg_id
      --             and org_id = 82
    AND org_id             = 101
    AND a.enabled_flag     = 'Y'
    AND a.qual_col1_table IS NOT NULL
    AND a.qual_usg_id     <> -1003
    AND a.real_time_where IS NOT NULL;
BEGIN
  log_message('Inside the get_terr_data procedure ');
  l_sql := get_sql;
  log_message('Before the forloop'||':'||TO_CHAR(CAST(sysdate AS TIMESTAMP)));
  FOR i IN c
  LOOP
    --log_message('Inside the for loop: '||to_char(i));
    l_sql := 'select distinct ' || i.col_name || '_tbl,' || i.col_name || '_sql from  xx_terr_qual_gt' || crlf;
    l_sql := l_sql || 'where ' || i.col_name || '_tbl is not null ' || crlf;
    l_sql := l_sql || 'and ' || i.col_name || '_sql is not null ';
    --log_message(l_sql);
    s := dbms_sql.open_cursor;
    dbms_sql.parse(s, l_sql, dbms_sql.native);
    --dbms_sql.define_column(s, 1, l_terr_id);
    dbms_sql.define_column(s, 1, l_table, 30);
    dbms_sql.define_column(s, 2, l_where_sql, 4000);
    t           := dbms_sql.execute(s);
    l_terr_id   := NULL;
    l_table     := NULL;
    l_where_sql := NULL;
    l_exe_sql   := NULL;
    LOOP
      IF dbms_sql.fetch_rows(s) > 0 THEN
        --dbms_sql.column_value(s, 1, l_terr_id);
        dbms_sql.column_value(s, 1, l_table);
        dbms_sql.column_value(s, 2, l_where_sql);
      ELSE
        EXIT;
      END IF;
      IF l_table IS NOT NULL THEN
        --log_message(l_table);
        log_message('---------------------------------------');
        IF l_table    = 'HZ_PARTIES' AND upper(l_where_sql) LIKE '%Q1001%' THEN
          l_col      := 'party_relationship_id';
        elsif l_table = 'HZ_PARTIES' AND upper(l_where_sql) NOT LIKE '%Q1001%' THEN
          l_col      := 'party_id';
        elsif l_table = 'HZ_LOCATIONS' THEN
          l_col      := 'location_id,party_site_id';
        elsif l_table = 'HZ_PARTY_SITES' THEN
          l_col      := 'party_site_id';
        END IF;
        l_insert_sql   := 'insert into xx_terr_denorm_acct_gt (terr_id,' || l_col || ')' || crlf;
        l_select_sql   := 'select b.terr_id,a.' || l_col || ' from ' || l_table || ' a, JTY_1001_DENORM_ATTR_VALUES b' || crlf;
        IF l_table      = 'HZ_LOCATIONS' THEN
          l_select_sql := l_select_sql || ', hz_party_sites c' || crlf;
          l_where_sql  := l_where_sql || crlf;
          l_where_sql  := l_where_sql || ' and a.location_id=c.location_id';
          l_where_sql  := l_where_sql || ' and exists (select 1 from hz_party_site_uses hpsu where c.party_site_id=hpsu.party_site_id';
          l_where_sql  := l_where_sql || ' and hpsu.site_use_type=''SHIP_TO'')';
          l_where_sql  := l_where_sql || ' and (b.q9001_low_value_char  =''SPINE'''; --KM20160513
          l_where_sql  := l_where_sql || ' or b.q9001_low_value_char =''ORTHO'')'; --KM20160513
          --KM20160513 Included one more condition at where clause SPINE,ORTHO part of tuning
        END IF;
        IF l_table     = 'HZ_PARTY_SITES' THEN
          l_where_sql := l_where_sql || ' and exists (select 1 from hz_party_site_uses hpsu where a.party_site_id=hpsu.party_site_id';
          l_where_sql := l_where_sql || ' and hpsu.site_use_type=''SHIP_TO'')';
        END IF;
        l_select_sql := l_select_sql || l_where_sql;
        l_exe_sql    := l_insert_sql || l_select_sql;
        log_message(l_exe_sql);
        EXECUTE immediate l_exe_sql;
      END IF;
    END LOOP;
    dbms_sql.close_cursor(s);
  END LOOP;
  log_message('After the forloop'||':'||TO_CHAR(CAST(sysdate AS TIMESTAMP)));
  -- Added on 02/26 Naga --
  log_message('Before update statement of xx_terr_denorm_acct_gt'||':'||TO_CHAR(CAST(sysdate AS TIMESTAMP)));
  UPDATE xx_terr_denorm_acct_gt a
  SET
    (
      party_id
    )
    =
    (SELECT party_id
    FROM hz_party_sites b
    WHERE a.party_site_id = b.party_site_id
    )
  WHERE party_site_id IS NOT NULL
  AND party_id        IS NULL;
  log_message('After update statement of xx_terr_denorm_acct_gt'||':'||TO_CHAR(CAST(sysdate AS      TIMESTAMP)));
  log_message('Before Insert statement of xx_terr_cust_salesrep_data'||':'||TO_CHAR(CAST(sysdate AS TIMESTAMP)));
  INSERT
  INTO xx_terr_cust_salesrep_data
    (
      terr_id ,
      territory_name ,
      product_code ,
      party_id ,
      party_name ,
      party_number ,
      party_type ,
      account_number ,
      cust_account_id ,
      resource_id ,
      salesrep_id ,
      salesrep_number ,
      salesrep_name ,
      user_id ,
      party_site_id ,
      party_site_number
    )
  SELECT DISTINCT a.terr_id,
    jta.name,
    SUBSTR(jta.name,7,3),
    a.party_id,
    d.party_name,
    d.party_number,
    d.party_type,
    c.account_number,
    c.cust_account_id ,
    b.resource_id,
    salesrep_id,
    salesrep_number,
    NVL(jrs.name, res.source_name),
    res.user_id,
    a.party_site_id ,
    hps.party_site_number
  FROM xx_terr_denorm_acct_gt a ,
    jtf_terr_rsc_all b ,
    hz_parties d ,
    hz_cust_accounts c ,
    jtf_rs_salesreps jrs ,
    jtf_rs_resource_extns res ,
    jtf_terr_all jta ,
    hz_party_sites hps
  WHERE a.terr_id           = b.terr_id
  AND d.party_id            = c.party_id(+)
  AND NVL(c.status(+), 'A') = 'A'
  AND a.party_id(+)         = d.party_id
  AND b.resource_id         = jrs.resource_id
    --               and b.org_id = 82
  AND b.org_id = 101
    -- added below to take care of effective dated salesrep territory relationships
  AND sysdate BETWEEN b.start_date_active AND b.end_date_active
    --               and jrs.org_id = 82
  AND jrs.org_id      = 101
  AND d.party_type    = 'ORGANIZATION'
  AND b.resource_id   = res.resource_id
  AND a.terr_id       = jta.terr_id
  AND a.party_site_id = hps.party_site_id
    -- UPDATE FOR THE TM ENHANCEMENT PROJECT KM20160325
  AND jta.name LIKE '510%REGION'
  ORDER BY a.terr_id;
  log_message('After Insert statement of xx_terr_cust_salesrep_data'||':'||TO_CHAR(CAST(sysdate AS TIMESTAMP)));
  /* KM20160513 OLD CODE WITHOUT ANYCHANGE
 update xx_terr_cust_salesrep_data a
    set    division = (select distinct q9001_low_value_char
                       from   jty_1001_denorm_attr_values b
                       where  source_id = -1001 and a.terr_id = b.terr_id and q9001_low_value_char is not null);
 */
  UPDATE xx_terr_cust_salesrep_data a
  SET division =
    (SELECT DISTINCT q9001_low_value_char
    FROM jty_1001_denorm_attr_values b
    WHERE source_id           = -1001
    AND a.terr_id             = b.terr_id
    AND q9001_low_value_char IS NOT NULL
    GROUP BY b.terr_id,
      b.q9001_low_value_char
    )
  WHERE a.TERRITORY_NAME LIKE '510%REGION' ;
  --KM20160513 ADDED GROUP BY AND ONE MORE CONDTION AT WHERE CLAUSE FOR PERFORMANCE TUNING
  log_message('After Update statement of disviosn'||':'||TO_CHAR(CAST(sysdate AS TIMESTAMP)));
EXCEPTION
WHEN OTHERS THEN
  log_message(sqlerrm);
  IF dbms_sql.is_open(s) THEN
    dbms_sql.close_cursor(s);
  END IF;
END;
PROCEDURE write_file(
    p_retcode OUT NUMBER,
    x_error_message OUT VARCHAR2,
    p_datafile_name IN VARCHAR2)
IS
  lv_file_name VARCHAR2(4000);
  lv_record    VARCHAR2(4000);
  lv_file utl_file.file_type;
  lv_location       VARCHAR2(4000);
  l_comm_seq_no     NUMBER;
  l_terr_seq_no     NUMBER;
  l_stmt            VARCHAR2(32000);
  gk_data_file_path VARCHAR2(200) := 'XXSGSFTOUT';
  /*cursor c_get_terr_data is
  select *
  from   xx_terr_cust_salesrep_data;
  */
  CURSOR c_get_terr_data
  IS
    SELECT MIN(xtcsd.terr_id) TERR_ID,
      xtcsd.division
      || '-'
      || xtcsd.product_code TERRITORY_NAME,
      xtcsd.division,
      xtcsd.SALESREP_NUMBER,
      'Active' ACTIVE
    FROM xx_terr_cust_salesrep_data xtcsd,
      XXOM_TERR_SALESREP_STG xtss
    WHERE xtcsd.division IN
      (SELECT meaning
      FROM fnd_lookup_values
      WHERE lookup_type = 'INTG_FIELD_INVENTORY_DIVISIONS'
      AND language      = 'US'
      AND enabled_flag  = 'Y'
      AND tag           = '-'
      )
  AND xtcsd.terr_id          = xtss.terr_id (+)
  AND xtcsd.salesrep_number  = xtss.salesrep_number (+)
  AND xtss.transaction_date IS NULL
  GROUP BY xtcsd.division
    || '-'
    || xtcsd.product_code,
    xtcsd.division,
    xtcsd.SALESREP_NUMBER,
    'Active'
  UNION
  SELECT MIN(xtcsd.terr_id) TERR_ID,
    xtcsd.division
    || '-'
    || xtcsd.product_code TERRITORY_NAME,
    xtcsd.division,
    xtcsd.SALESREP_NUMBER,
    'Inactive' ACTIVE
  FROM xx_terr_cust_salesrep_data xtcsd,
    XXOM_TERR_SALESREP_STG xtss
  WHERE xtcsd.terr_id (+)       = xtss.terr_id
  AND xtss.active_flag          = 'A'
  AND xtcsd.salesrep_number (+) = xtss.salesrep_number
  AND xtcsd.territory_name     IS NULL
  AND xtss.division            IN
    (SELECT meaning
    FROM fnd_lookup_values
    WHERE lookup_type = 'INTG_FIELD_INVENTORY_DIVISIONS'
    AND language      = 'US'
    AND enabled_flag  = 'Y'
    AND tag           = '-'
    )
  GROUP BY xtcsd.division
    || '-'
    || xtcsd.product_code,
    xtcsd.division,
    xtcsd.SALESREP_NUMBER,
    'Inactive'
  UNION
  SELECT DISTINCT xtcsd.terr_id,
    xtcsd.TERRITORY_NAME,
    xtcsd.division,
    xtcsd.SALESREP_NUMBER,
    'Active' ACTIVE
  FROM xx_terr_cust_salesrep_data xtcsd,
    XXOM_TERR_SALESREP_STG xtss
  WHERE xtcsd.division IN
    (SELECT meaning
    FROM fnd_lookup_values
    WHERE lookup_type     = 'INTG_FIELD_INVENTORY_DIVISIONS'
    AND language          = 'US'
    AND enabled_flag      = 'Y'
    AND NVL(tag,'qqqqq') <> '-'
    )
  AND xtcsd.terr_id          = xtss.terr_id (+)
  AND xtcsd.salesrep_number  = xtss.salesrep_number (+)
  AND xtss.transaction_date IS NULL
  UNION
  SELECT DISTINCT xtcsd.terr_id,
    xtcsd.TERRITORY_NAME,
    xtcsd.division,
    xtcsd.SALESREP_NUMBER,
    'Inactive' ACTIVE
  FROM xx_terr_cust_salesrep_data xtcsd,
    XXOM_TERR_SALESREP_STG xtss
  WHERE xtcsd.terr_id (+)       = xtss.terr_id
  AND xtss.active_flag          = 'A'
  AND xtcsd.salesrep_number (+) = xtss.salesrep_number
  AND xtcsd.territory_name     IS NULL
  AND xtss.division            IN
    (SELECT meaning
    FROM fnd_lookup_values
    WHERE lookup_type     = 'INTG_FIELD_INVENTORY_DIVISIONS'
    AND language          = 'US'
    AND enabled_flag      = 'Y'
    AND NVL(tag,'qqqqq') <> '-'
    )
  ORDER BY division;
  l_count        NUMBER;
  l_cur_division VARCHAR2(10);
BEGIN
  --log_message('Inside the write_file procedure ');
  DELETE FROM xx_terr_cust_salesrep_data;
  get_terr_data;
  l_count := 0;
  FOR i IN c_get_terr_data
  LOOP
    log_message('Inside the loop c_terr_date count value'||':'||l_count);
    --log_message('Inside the loop c_terr_date i value'||':'||i);
    IF i.terr_id IS NOT NULL THEN
      --The row appears to be complete.  Proceed as normal.
      IF NVL(l_cur_division,'NULL') <> i.division THEN
        log_message('l_cur_division: ' || NVL(l_cur_division,'NULL') );
        log_message('i.division: ' || NVL(i.division,'DIVNULL') );
        -- first close the old file if it is open
        IF l_cur_division IS NOT NULL THEN
          UTL_FILE.fflush (lv_file);
          UTL_FILE.fclose (lv_file);
          --   UTL_FILE.FRENAME('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname1, TRUE);
          /*
          apps.fnd_file.put_line (fnd_file.LOG,
          'Number of records written to item price extract ' || l_fname1 || ': ' || l_record_count);
          */
          xxom_consgn_comm_ftp_pkg.add_new_file(lv_file_name); -- Provide actual file name as parameter.
          l_count := 0;
        END IF;
        BEGIN
          SELECT xxom_cnsgn_cmn_file_seq.nextval INTO l_comm_seq_no FROM dual;
          fnd_file.put_line(fnd_file.log, 'l_comm_seq_no:' || l_comm_seq_no);
        EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Unable to fetch sequence no value for XXOM_CNSGN_CMN_FILE_SEQ: ');
        END;
        BEGIN
          SELECT xxom_cnsgn_terr_file_seq.nextval INTO l_terr_seq_no FROM dual;
          fnd_file.put_line(fnd_file.log, 'l_terr_seq_no:' || l_terr_seq_no);
        EXCEPTION
        WHEN OTHERS THEN
          --    intg_log_message ('Unable to fetch sequence no value for XXOM_CNSGN_TERR_FILE_SEQ','ERROR');
          fnd_file.put_line(fnd_file.log, 'Unable to fetch sequence no value for XXOM_CNSGN_TERR_FILE_SEQ: ');
        END;
        -- Open the new file
        -- BXS -- lv_file_name := p_datafile_name || to_char(sysdate, 'DDMONRRRR_HHMISS') || '.txt';
        lv_file_name := l_comm_seq_no || '_TERR_' || l_terr_seq_no || '_' || i.division || '.txt';
        -- lv_file_name := l_comm_seq_no || '_TEST_' || l_terr_seq_no || '.txt';
        --if gv_processed.count > 0 then
        lv_file        := utl_file.fopen(gk_data_file_path, lv_file_name, 'W');
        l_cur_division := i.division;
        -- if l_count = 0 then
        -- Add transaction_id
        -- transaction_date
        lv_record := 'TRANSACTION_ID' || '|' || 'TRANSACTION_DATE' || '|' || 'TERR_ID' || '|' || 'ACTIVE' || '|' || 'DIVISION' || '|' || 'TERRITORY_NAME' || '|'
        /*
        || 'PARTY_ID'
        || '|'
        || 'PARTY_TYPE'
        || '|'
        || 'PARTY_NUMBER'
        || '|'
        || 'PARTY_NAME'
        || '|'
        || 'ACCOUNT_NUMBER'
        || '|'
        || 'CUST_ACCOUNT_ID'
        || '|'
        */
        || 'SALESREP_NUMBER'
        /*
        || '|'
        || 'SALESREP_ID'
        || '|'
        || 'RESOURCE_ID'
        || '|'
        || 'USER_ID'
        || '|'
        || 'SALESREP_NAME'
        */
        || '|'; ---change it
        utl_file.put_line(lv_file, lv_record);
        --end if;
      END IF;
      lv_record := xxom_cnsgn_terr_file_seq.nextval || '|' || sysdate || '|' || i.terr_id || '|' || i.active || '|' || i.division || '|' || i.territory_name || '|'
      /*
      || i.party_id
      || '|'
      || i.party_type
      || '|'
      || i.party_number
      || '|'
      || i.party_name
      || '|'
      || i.account_number
      || '|'
      || i.cust_account_id
      || '|'
      */
      || i.salesrep_number
      /*
      || '|'
      || i.salesrep_id
      || '|'
      || i.resource_id
      || '|'
      || i.user_id
      || '|'
      || i.salesrep_name
      */
      || '|'; ---change it
      utl_file.put_line(lv_file, lv_record);
      l_count    := l_count + 1;
      IF i.ACTIVE = 'Active' THEN
        INSERT
        INTO XXOM_TERR_SALESREP_STG VALUES
          (
            i.TERR_ID,
            i.TERRITORY_NAME,
            i.DIVISION,
            i.SALESREP_NUMBER,
            SYSDATE,
            'A'
          );
      ELSE
        UPDATE XXOM_TERR_SALESREP_STG
        SET active_flag     = 'I'
        WHERE terr_id       = i.terr_id
        AND salesrep_number = i.SALESREP_NUMBER;
      END IF;
    ELSE
      --The row appears to be incomplete.  Do not add it to the outbound files.
      NULL;
    END IF;
    --  END IF; -- DIVISION CHANGE -- This is only for the header
  END LOOP;
  --end if;
  -- utl_file.fclose(lv_file);
  IF l_count > 0 THEN
    -- Flush and close the final file
    UTL_FILE.fflush (lv_file);
    UTL_FILE.fclose (lv_file);
    -- UTL_FILE.FRENAME('XXSGSFTOUT', l_fname, 'XXSGSFTOUT', l_fname1, TRUE);
    -- UTL_FILE.fflush (l_filehandle_arch);
    -- UTL_FILE.fclose (l_filehandle_arch);
    -- apps.fnd_file.put_line (fnd_file.LOG,
    --                'Number of records written to ' || l_fname1 || ': ' || l_record_count);
    -- xxom_consgn_comm_ftp_pkg.add_new_file(l_fname1); -- Provide actual file name as parameter.
    --     l_fname1 := l_comm_seq_no || '_ITEM_' || l_item_seq_no || '_' || item_rec.division || '.txt';
    log_message('lv_file_name: ' || lv_file_name);
    xxom_consgn_comm_ftp_pkg.add_new_file(lv_file_name); -- Provide actual file name as parameter.
    xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;              -- This process sends actual data file to surgisoft using sFTP.
    -- xxom_consgn_comm_ftp_pkg.GEN_CONF_FILE('Oracle_transfer_complete.txt','XXSGSFTOUT','XXSGSFTARCH'); -- This process generates confirmation file at the end.
    -- xxom_consgn_comm_ftp_pkg.FTP_DATA_FILE;   -- This process sends/overwrites confirmation file to surgisoft using sFTP.
  END IF;
  lv_file_name := NULL;
  /*if gv_processed.count > 0 then
  p_retcode := 0;
  else
  p_retcode := 2;
  end if;*/
EXCEPTION
WHEN utl_file.invalid_path THEN
  lv_location     := 'The directory path : "' || gk_data_file_path || '" does not exist. Please check it.';
  x_error_message := lv_location;
  p_retcode       := 2;
WHEN utl_file.invalid_filehandle THEN
  lv_location     := 'Not a Valid File Handle';
  x_error_message := lv_location;
  p_retcode       := 2;
WHEN utl_file.invalid_operation THEN
  utl_file.fclose(lv_file);
  lv_location     := 'File Is Not Open For Writing/Appending';
  x_error_message := lv_location;
  p_retcode       := 2;
WHEN utl_file.write_error THEN
  utl_file.fclose(lv_file);
  lv_location     := 'OS error occured during write operation';
  x_error_message := lv_location;
  p_retcode       := 2;
WHEN OTHERS THEN
  lv_location     := 'ERROR IN XX_TERR_CUST_SALESREP_PKG.WRITE_FILE:  ' || SUBSTR(sqlerrm, 1, 250);
  x_error_message := lv_location;
  p_retcode       := 2;
END write_file;
END xxom_cnsgn_terr_salesrep_pkg;
/
