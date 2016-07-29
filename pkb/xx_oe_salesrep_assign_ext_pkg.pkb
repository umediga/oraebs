DROP PACKAGE BODY APPS.XX_OE_SALESREP_ASSIGN_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_SALESREP_ASSIGN_EXT_PKG"
AS
  /* $Header: XX_OE_SALESREP_ASSIGN_EXT_PKG.pkb 1.0.0 2012/04/18 riqbal noship $ */
  --------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 18-ARP-2012
  Filename       : XX_OE_SALESREP_ASSIGN_EXT_PKG.pkb
  Description    : Salesrep Assigment public API
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  18-Apr-2012   1.0       Raquib Iqbal        Initial development.
  23-Oct-2012   1.1       Vishal Rathore      Change for Canada Province logic
  25-Oct-2012   1.2       Sujan Datta         COMMIT issue in business event
  1-Mar-2013    1.3       Vishal/Beda         Redesign of the code
  3-Apr-2013    1.4       Vishal              Ticket  # 2381
  11-Jun-2013   1.5       Vishal              Enhancement for O2C-EXT_040-W1
  4-Oct-2013    1.6       Vishal              Enhancement for O2C-EXT_040-W1(new
  attribute and territories with same
  attributes)
  6-Dec-2013    1.7       Vishal              Logic for spine
  11-Dec-2013   1.8       Vishal              Logic for state and between/Like for
  attribute
  14-Dec-2013   1.9       Vishal              Few additonal log
  21-May-2014   2.0       Vishal              Ticket # 6528 Changes to exclude salesrep
  population when manually entered
  21-May-2014   2.1       Vishal              Ticket # 6528 Changes to populate territories
  when manually entered
  09-07-2014    1.2       Sanjeev            Modified as per the case 7839 to skip the AME
  approval noticiation if salesrep exists
  i
  15-Sep-2014   1.3      Jaya Maran          Modified for Ticket#7197. OE MSG intialize commented.
  25-MAR-2016   1.4      Kannan Mariappan    Updating Internal Salesrep from TM along with External Salesrep
  */
  --------------------------------------------------------------------------------
  g_object_name VARCHAR2 (30) := 'XX_OE_ASSIGN_SALESREP';
  --DEBUG mode decides if debug messages required or not
  g_created_by        NUMBER         := fnd_global.user_id;
  g_last_update_login NUMBER         := fnd_global.login_id;
  g_multiple_salesrep VARCHAR2 (30)  := xx_emf_pkg.get_paramater_value (g_object_name, 'MULTIPLE_SALESREP');
  g_no_salesrep       VARCHAR2 (30)  := xx_emf_pkg.get_paramater_value (g_object_name, 'NO_SALESREP');
  g_no_territories    VARCHAR2 (30)  := NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'NO_TERRITORIES'),'Territory Mismatch');
  g_program_source    VARCHAR2 (1)   := NULL;
  g_prog_stage        VARCHAR2 (200) := 'xx_oe_salesrep_assign_ext_pkg Global';
PROCEDURE write_emf_log_high(
    p_debug_text  IN VARCHAR2,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;
PROCEDURE write_emf_log_low(
    p_debug_text  IN VARCHAR2,
    p_attribute1  IN VARCHAR2 DEFAULT NULL,
    p_attribute2  IN VARCHAR2 DEFAULT NULL,
    p_attribute3  IN VARCHAR2 DEFAULT NULL,
    p_attribute4  IN VARCHAR2 DEFAULT NULL,
    p_attribute5  IN VARCHAR2 DEFAULT NULL,
    p_attribute6  IN VARCHAR2 DEFAULT NULL,
    p_attribute7  IN VARCHAR2 DEFAULT NULL,
    p_attribute8  IN VARCHAR2 DEFAULT NULL,
    p_attribute9  IN VARCHAR2 DEFAULT NULL,
    p_attribute10 IN VARCHAR2 DEFAULT NULL )
IS
BEGIN
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_low, p_debug_text,p_attribute1,p_attribute2,p_attribute3,p_attribute4,p_attribute5,p_attribute6,p_attribute7,p_attribute8,p_attribute9,p_attribute10);
END;
-- ins_sales_credit_record PROCEDURE HAS BEEN MODIFIED TO GET THE CHANGES FOR TERRITROY MANAGER ENHANCEMENT REQUEST
--KM20160525
PROCEDURE ins_sales_credit_record(
    p_line_scredit_tbl IN OUT oe_order_pub.line_scredit_tbl_type ,
    p_header_id        IN NUMBER ,
    p_line_id          IN NUMBER ,
    p_terr_id          IN NUMBER ,
    o_return_status OUT VARCHAR2 ,
    o_return_message OUT VARCHAR2 )
IS
  -------------------------------------------------------------------------------
  /*
  UPDATED BY     : KANNAN MARIAPPAN
  UPDATE DATE    : 25-MAR-2016
  Procedure name : ins_sales_credit_record
  Description    : Update to get the both EXTERNAL AND INTERNAL Sales rep and its association
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  25-MAR-2016   1.7       KANNAN MARIAPPAN    Territory Manager Enhancement Project.
  */
  --------------------------------------------------------------------------------
type l_salescredit_type
IS
  record
  (
    salesrep_id jtf_rs_salesreps.salesrep_id%type,
    role_id jtf_rs_defresroles_vl.role_id%type,
    terr_id jtf_rs_defresroles_vl.attribute1%type,
    terr_name jtf_rs_defresroles_vl.attribute2%type,
    salesrep_type jtf_rs_defresroles_vl.attribute4%type,
    sales_credit_type_id jtf_rs_salesreps.sales_credit_type_id%type) ; -- added one more column here to populate the sales credit type id to differentiate EXTERNAL and INTERNAL
type l_salescredit_id_tbl_type
IS
  TABLE OF l_salescredit_type INDEX BY binary_integer;
type l_lines_salescredit_type
IS
  record
  (
    salesrep_id jtf_rs_salesreps.salesrep_id%type,
    role_id jtf_rs_defresroles_vl.role_id%type,
    percent oe_sales_credits.percent%type,
    sales_credit_id oe_sales_credits.sales_credit_id%type,
    sales_credit_type_id jtf_rs_salesreps.sales_credit_type_id%type) ; -- added one more column here to populate the sales credit type id to differentiate EXTERNAL and INTERNAL
type l_lines_salescredit_tbl_type
IS
  TABLE OF l_lines_salescredit_type INDEX BY binary_integer;
  l_index NUMBER := 1;
  l_lines_salescredit_tbl_rec l_lines_salescredit_tbl_type;
  l_salesrep_id_tbl_rec l_salescredit_id_tbl_type;
  l_salesrep_id_tbl_rec_temp l_salescredit_id_tbl_type;
  l_tot_credit NUMBER                                              := 0;
  l_winn_terr_name xxintg.xx_m2c_salesrep_terr_data.terr_name%type := NULL;
  l_winn_terr_id xxintg.xx_m2c_salesrep_terr_data.terr_id%type     := NULL;
  l_lines_salesrep oe_order_lines_all.salesrep_id%type             := 0;
  l_credit_salesrep oe_order_lines_all.salesrep_id%type            := 0;
  l_no_salesrep oe_order_lines_all.salesrep_id%type                := 0;
  l_multi_salesrep oe_order_lines_all.salesrep_id%type             := 0;
  l_ext_exists BOOLEAN ; -- THIS BOOLEAN RETURNS TRUE IF SALESREP AND TM VALUE EXISTS FOR EXTERNAL
  l_int_exists BOOLEAN;  -- THIS BOOLEAN RETURNS TRUE IF SALESREP AND TM VALUE EXISTS FOR INTERNAL
  l_count_rec  NUMBER:=0;
  l_count_ext  NUMBER:=0; -- THIS COUNT RETURS NUMBER OF RECORD EXISIT FOR EXTERNAL TO HANDLE MULTIPLE_SALES_REP PROBLEM
  l_count_int  NUMBER:=0; -- THIS COUNT RETURS NUMBER OF RECORD EXISIT FOR INTERNAL TO HANDLE MULTIPLE_SALES_REP PROBLEM
BEGIN
  --  LOOP IS JUST TO WRITE THE LOG INFORMATION ON HOW MANY TERR ID GOT INVOLVED FOR THIS PARTICULAR LINE ID AND HEADER ID
  FOR c_terr_row IN
  (SELECT terr_id
  FROM xxintg.xx_m2c_salesrep_terr_data
  WHERE select_flag = 'Y'
  AND unique_flag   = 'Y'
  )
  LOOP
    write_emf_log_low('Entering ins_sales_credit_record',p_header_id,p_line_id,c_terr_row.terr_id);
    --APPS.xxintg_ont_wf_log_proc( p_header_id||'Entering ins_sales_credit_record '||p_line_id||'-'||c_terr_row.terr_id);
  END LOOP;
  -- ABOVE LOOP IS JUST TO WRITE THE LOG INFORMATION ON HOW MANY TERR ID GOT INVOLVED FOR THIS PARTICULAR LINE ID AND HEADER ID
  -- GET THE SALES REP ID FROM THE LINE TABLE
  BEGIN
    --APPS.xxintg_ont_wf_log_proc(p_header_id||'After first loop inside select stmnt in ins_sales_credit_record'||p_line_id);
    SELECT ool.salesrep_id
    INTO l_lines_salesrep
    FROM oe_order_lines_all ool
    WHERE line_id =p_line_id;
  EXCEPTION
  WHEN OTHERS THEN
    l_lines_salesrep := 0;
    --APPS.xxintg_ont_wf_log_proc(p_header_id||'select stmnt exception ins_sales_credit_record'||p_line_id||'-'||l_lines_salesrep);
  END;
  -- GET THE SALES REP DETAIL FOR "NO SALES REP"
  write_emf_log_low('Heder_id Line_id and sales_rep_id at line',p_header_id,p_line_id,l_lines_salesrep);
  BEGIN
    SELECT rs.salesrep_id
    INTO l_no_salesrep
    FROM jtf_rs_salesreps rs
    WHERE name    = g_no_salesrep
    AND rs.org_id = fnd_global.org_id;
    --APPS.xxintg_ont_wf_log_proc(p_header_id||' inside second select stmnt ins_sales_credit_record'||l_no_salesrep||'-'||g_no_salesrep);
  EXCEPTION
  WHEN OTHERS THEN
    l_no_salesrep := 0;
    --APPS.xxintg_ont_wf_log_proc(p_header_id||' inside second select stmnt  exception ins_sales_credit_record'||l_no_salesrep);
  END;
  write_emf_log_low('Heder_id Line_id and sales_rep_id for No Slaes Rep',p_header_id,p_line_id,l_no_salesrep);
  -- GET THE SALES REP DETAIL FOR "MULTI SALES REP"
  write_emf_log_low('Heder_id Line_id and sales_rep_id at line',p_header_id,p_line_id,l_lines_salesrep);
  BEGIN
    SELECT rs.salesrep_id
    INTO l_multi_salesrep
    FROM jtf_rs_resource_extns_vl jrrev,
      jtf_rs_salesreps rs
    WHERE jrrev.resource_name ='Multiple Sales Rep'
    AND jrrev.resource_id     =rs.resource_id
    AND rs.org_id             = fnd_global.org_id;
    --APPS.xxintg_ont_wf_log_proc(p_header_id||' inside second select stmnt ins_sales_credit_record'||l_no_salesrep||'-'||g_no_salesrep);
  EXCEPTION
  WHEN OTHERS THEN
    l_multi_salesrep := 0;
    --APPS.xxintg_ont_wf_log_proc(p_header_id||' inside second select stmnt  exception ins_sales_credit_record'||l_no_salesrep);
  END;
  write_emf_log_low('Heder_id Line_id and sales_rep_id for Multi Slaes Rep',p_header_id,p_line_id,l_multi_salesrep);
  --GET THE SALES REP DETAILS AND TERRITROY DETAILS FRO THE WINNING TERRITORY
  -- FLAG ENABLED TERRITOERY BASED ON RANK AND THE CUSTOM LOGIC
  FOR c_salesrep_rec IN
  (SELECT DISTINCT rs.resource_id ,
    rs.salesrep_number ,
    rs.salesrep_id ,
    rol.role_id,
    xmstd.terr_id,
    xmstd.terr_name,
    DECODE(jrgv.attribute1,'EXTERNAL',1,'INTERNAL',2,1) sales_credit_type_id,
    NVL(jrgv.attribute1,'') salesrep_type --
  FROM jtf_terr_rsc jtr ,
    jtf_rs_salesreps rs ,
    jtf_rs_groups_vl jrgv,
    jtf_rs_role_relations jrrr,
    jtf_rs_group_members jrgm,
    (SELECT jrd.role_id ,
      rs.resource_id
    FROM jtf_rs_salesreps rs ,
      jtf_rs_defresroles_vl jrd
    WHERE sysdate BETWEEN NVL (rs.start_date_active , sysdate) AND NVL (end_date_active, sysdate)
    AND jrd.role_resource_id = rs.resource_id
    AND jrd.role_type_name   = 'Sales Compensation'
    AND sysdate BETWEEN NVL (jrd.res_rl_start_date , sysdate ) AND NVL (jrd.res_rl_end_date, sysdate)
    AND delete_flag = 'N' -- condition added for  Ticket  # 2381
    ) rol,
    xxintg.xx_m2c_salesrep_terr_data xmstd
  WHERE jtr.terr_id = xmstd.terr_id
  AND sysdate BETWEEN NVL (jtr.start_date_active, sysdate) AND NVL (jtr.end_date_active, sysdate)
  AND sysdate BETWEEN NVL (rs.start_date_active, sysdate) AND NVL (rs.end_date_active, sysdate)
  AND rs.org_id              = fnd_global.org_id
  AND select_flag            = 'Y'
  AND unique_flag            = 'Y'
  AND rs.resource_id         = jtr.resource_id
  AND rol.resource_id(+)     = rs.resource_id
  AND jrrr.role_resource_type='RS_GROUP_MEMBER'
  AND jrrr.role_resource_id  =jrgm.group_member_id
  AND sysdate BETWEEN NVL(jrrr.start_date_active,sysdate) AND NVL(jrrr.end_date_active,sysdate)
  AND jrgm.group_id   =jrgv.group_id
  AND jrgm.resource_id=rs.resource_id
  AND jrrr.delete_flag='N'
  ORDER BY DECODE(jrgv.attribute1,'EXTERNAL',1,'INTERNAL',2,1)
  )
  LOOP
    write_emf_log_low('Entering ins_sales_credit_record loop',p_header_id,p_line_id,p_terr_id,c_salesrep_rec.salesrep_id,c_salesrep_rec.role_id);
    --APPS.xxintg_ont_wf_log_proc (p_header_id||'Entering ins_sales_credit_record first loop'||p_line_id||'-'||p_terr_id||'-'||c_salesrep_rec.salesrep_id||'-'||c_salesrep_rec.role_id);
    -- insert into xxintg.xxoe_sales_rep_temp(sno,salesrep_id,role_id,percent,sales_credit_id,terr_id,terr_name) values(l_index,c_salesrep_rec.salesrep_id,null,null,NULL,c_salesrep_rec.terr_id,c_salesrep_rec.terr_name);
    l_salesrep_id_tbl_rec (l_index).salesrep_id          := c_salesrep_rec.salesrep_id;
    l_salesrep_id_tbl_rec (l_index).role_id              := c_salesrep_rec.role_id;
    l_salesrep_id_tbl_rec (l_index).terr_id              := c_salesrep_rec.terr_id;
    l_salesrep_id_tbl_rec (l_index).terr_name            := c_salesrep_rec.terr_name;
    l_salesrep_id_tbl_rec (l_index).salesrep_type        := c_salesrep_rec.salesrep_type;
    l_salesrep_id_tbl_rec (l_index).sales_credit_type_id := c_salesrep_rec.sales_credit_type_id;
    l_index                                              := l_index + 1;
    --write_emf_log_low('ATTR COLUMN'||l_salesrep_id_tbl_rec (l_index).sales_credit_type_id);
    --Logging
  END LOOP;
  ---LOOP THE ABOVE TO CHECK NO TERRITORIES FOR INTERNAL AND EXTERNAL
  -- ABOVE LOOOP STORE THE SALES REP AND TERR DETAILS IN "l_salesrep_id_tbl_rec" record
  -- it fetches the resource attached with the winning territory
  --START
  -- WE NEED TO POPLATE NO SALES REP and NO TERRITORY IF THERE IS NO SALES NO RECORD FOUND FOR THE ABOVE CURSOR
  l_int_exists:=false;
  l_ext_exists:=false;
  write_emf_log_low('Before EN=tering into loop l_int_exists and l_ext_exists ');
  BEGIN
    IF(l_salesrep_id_tbl_rec.count=0) THEN
      write_emf_log_low('Both Internal and External Not Exisits ');
    ELSE
      FOR l_salesrep_tbl IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        write_emf_log_low('Inside the loop and before validation ');
        IF (l_salesrep_id_tbl_rec(l_salesrep_tbl).sales_credit_type_id =1) THEN
          l_ext_exists                                                :=true;
          l_count_ext                                                 :=l_count_ext+1;
          write_emf_log_low('Count of ext:'||l_count_ext);
        ELSIF (l_salesrep_id_tbl_rec(l_salesrep_tbl).sales_credit_type_id=2) THEN
          l_int_exists                                                  :=true;
          l_count_int                                                   :=l_count_int+1;
          write_emf_log_low('Count of Int:'||l_count_int);
        END IF;
      END LOOP;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_int_exists :=false;
    l_ext_exists :=false;
  END;
  write_emf_log_low('After the loop l_int_exists and l_ext_exists ');
  write_emf_log_low('Count of l_salesrep_id_tbl_rec record before appending:'||l_salesrep_id_tbl_rec.count);
  --
  --EXTERNAL SALES REP EXISTS AND INTERNAL NOT EXISTS
  IF(l_ext_exists AND (NOT l_int_exists )) THEN
    write_emf_log_low('l_ext_exists AND (NOT l_int_exists )');
    --l_salesrep_id_tbl_rec:= l_salescredit_id_tbl_type();
    --l_salesrep_id_tbl_rec.EXTEND();
    --EXTERNAL SALES REP EXISTS AND INTERNAL NOT EXISTS AND EXTERNAL RECORD COUNT IS ONE
    IF(l_count_ext=1) THEN
      write_emf_log_low('No Internal and External  Sales rep is only one');
      l_count_rec                                              :=l_salesrep_id_tbl_rec.count+1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_no_salesrep;
      l_salesrep_id_tbl_rec(l_count_rec).salesrep_type         :='INTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 2;
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      write_emf_log_low('Count of l_salesrep_id_tbl_rec record after appending:'||l_salesrep_id_tbl_rec.count);
      write_emf_log_low('Inside the ext_exisit and int_not_exists ',p_header_id,p_line_id);
      --EXTERNAL SALES REP EXISTS AND INTERNAL NOT EXISTS AND EXTERNAL RECORD COUNT IS GREATER THAN ONE
      -- HERE WE ARE RETURNING MULTIPLE SALES REP
    ELSIF(l_count_ext>1) THEN
      l_salesrep_id_tbl_rec.delete;
      write_emf_log_low('No Internal and External Sales rep greatedr than one');
      l_salesrep_id_tbl_rec (1).salesrep_id                    := l_multi_salesrep;
      l_salesrep_id_tbl_rec (1).sales_credit_type_id           := 1;
      l_salesrep_id_tbl_rec (1).role_id                        :=0;
      l_salesrep_id_tbl_rec (1).terr_name                      := g_no_territories;
      l_salesrep_id_tbl_rec (1).salesrep_type                  := 'EXTERNAL';
      l_count_rec                                              :=l_salesrep_id_tbl_rec.count+1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_no_salesrep;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_type        := 'INTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 2;
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      write_emf_log_low('Count of l_salesrep_id_tbl_rec record after appending:'||l_salesrep_id_tbl_rec.count);
      write_emf_log_low('Inside the ext_exisit and int_not_exists ',p_header_id,p_line_id);
    END IF;
    --EXTERNAL SALES REP NOT EXISTS AND INTERNAL EXISTS
  ELSIF((NOT l_ext_exists) AND l_int_exists) THEN
    write_emf_log_low('((NOT l_ext_exists) AND l_int_exists)');
    --l_salesrep_id_tbl_rec:= l_salescredit_id_tbl_type();
    --l_salesrep_id_tbl_rec.EXTEND();
    --INTERNAL SALES REP EXISTS AND EXTERNAL NOT EXISTS AND INTERNAL RECORD COUNT IS  ONE
    IF(l_count_int=1) THEN
      write_emf_log_low('No External and Internal Sales rep is only one');
      l_salesrep_id_tbl_rec_temp:=l_salesrep_id_tbl_rec;
      l_salesrep_id_tbl_rec.delete;
      l_count_rec                                              :=1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_no_salesrep;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_type        := 'EXTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 1;
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec_temp.first .. l_salesrep_id_tbl_rec_temp.last
      LOOP
        write_emf_log_low('Adding Internal data from temp table');
        l_count_rec                                             :=l_salesrep_id_tbl_rec.count+1;
        l_salesrep_id_tbl_rec (l_count_rec).salesrep_id         :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_id;
        l_salesrep_id_tbl_rec (l_count_rec).role_id             :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).role_id;
        l_salesrep_id_tbl_rec (l_count_rec).terr_id             :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_id;
        l_salesrep_id_tbl_rec (l_count_rec).terr_name           :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_name;
        l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id:=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).sales_credit_type_id;
        l_salesrep_id_tbl_rec (l_count_rec).salesrep_type       :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_type;
      END LOOP;
      write_emf_log_low('Count of l_salesrep_id_tbl_rec record after appending:'||l_salesrep_id_tbl_rec.count);
      write_emf_log_low('Inside the int_exisit and extt_not_exists ',p_header_id,p_line_id);
      --INTERNAL SALES REP EXISTS AND EXTERNAL NOT EXISTS AND INTERNAL RECORD COUNT IS  GREATER THAN ONE
      --HERE WE ARE RETRUNIG MULTIPLE SALES REP
    ELSIF(l_count_int>1) THEN
      l_salesrep_id_tbl_rec.delete;
      write_emf_log_low('No External and Internal Sales rep greatedr than one');
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_multi_salesrep;
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 2;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_type        := 'INTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      l_count_rec                                              :=l_salesrep_id_tbl_rec.count+1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_no_salesrep;
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_type        := 'EXTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      write_emf_log_low('Count of l_salesrep_id_tbl_rec record after appending:'||l_salesrep_id_tbl_rec.count);
      write_emf_log_low('Inside the int_exisit and extt_not_exists ',p_header_id,p_line_id);
    END IF;
    --INTERNAL AND EXTERNAL SALES REP EXSITS
  ELSIF( (l_ext_exists) AND (l_int_exists)) THEN
    write_emf_log_low('Internal and External  exists');
    --INTERNAL AND EXTERNAL SALES REP EXSITS AND EXTERNAL RECORD COUNT IS GREATER THAN ONE
    IF((l_count_int=1) AND (l_count_ext>1)) THEN
      write_emf_log_low('Internal and External  exists and external greater than one');
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        IF(l_salesrep_id_tbl_rec(l_salesrep_cnt).sales_credit_type_id=2) THEN
          -- store to temp record
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_id         :=l_salesrep_id_tbl_rec(l_salesrep_cnt).salesrep_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).role_id             :=l_salesrep_id_tbl_rec(l_salesrep_cnt).role_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_id             :=l_salesrep_id_tbl_rec(l_salesrep_cnt).terr_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_name           :=l_salesrep_id_tbl_rec(l_salesrep_cnt).terr_name;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).sales_credit_type_id:=l_salesrep_id_tbl_rec(l_salesrep_cnt).sales_credit_type_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_type       :=l_salesrep_id_tbl_rec(l_salesrep_cnt).salesrep_type;
        END IF;
      END LOOP;
      l_salesrep_id_tbl_rec.delete;
      --l_salesrep_id_tbl_rec                                    :=l_salesrep_id_tbl_rec_temp;
      l_count_rec                                              :=1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_multi_salesrep;
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_type        := 'EXTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec_temp.first .. l_salesrep_id_tbl_rec_temp.last
      LOOP
        -- store to temp record
        l_count_rec                                            :=l_salesrep_id_tbl_rec.count+1;
        l_salesrep_id_tbl_rec(l_count_rec).salesrep_id         :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_id;
        l_salesrep_id_tbl_rec(l_count_rec).role_id             :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).role_id;
        l_salesrep_id_tbl_rec(l_count_rec).terr_id             :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_id;
        l_salesrep_id_tbl_rec(l_count_rec).terr_name           :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_name;
        l_salesrep_id_tbl_rec(l_count_rec).sales_credit_type_id:=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).sales_credit_type_id;
        l_salesrep_id_tbl_rec(l_count_rec).salesrep_type       :=l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_type;
      END LOOP;
      --INTERNAL AND EXTERNAL SALES REP EXSITS AND INTERNAL RECORD COUNT IS GREATER THAN ONE
    ELSIF((l_count_int >1) AND (l_count_ext=1)) THEN
      write_emf_log_low('Internal and External  exists and Internal greater than one');
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        IF(l_salesrep_id_tbl_rec(l_salesrep_cnt).sales_credit_type_id=1) THEN
          -- store to temp record
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_id         :=l_salesrep_id_tbl_rec(l_salesrep_cnt).salesrep_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).role_id             :=l_salesrep_id_tbl_rec(l_salesrep_cnt).role_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_id             :=l_salesrep_id_tbl_rec(l_salesrep_cnt).terr_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).terr_name           :=l_salesrep_id_tbl_rec(l_salesrep_cnt).terr_name;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).sales_credit_type_id:=l_salesrep_id_tbl_rec(l_salesrep_cnt).sales_credit_type_id;
          l_salesrep_id_tbl_rec_temp(l_salesrep_cnt).salesrep_type       :=l_salesrep_id_tbl_rec(l_salesrep_cnt).salesrep_type;
        END IF;
      END LOOP;
      l_salesrep_id_tbl_rec.delete;
      l_salesrep_id_tbl_rec                                    :=l_salesrep_id_tbl_rec_temp;
      l_count_rec                                              :=l_salesrep_id_tbl_rec.count+1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_multi_salesrep;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_type        := 'INTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 2;
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      --INTERNAL AND EXTERNAL SALES REP EXSITS AND BOTH EXTERNAL INTERNAL RECORD COUNT IS GREATER THAN ONE
    ELSIF((l_count_int >1) AND (l_count_ext>1)) THEN
      l_salesrep_id_tbl_rec.delete;
      write_emf_log_low('Internal and External Sales rep greatedr than one');
      l_salesrep_id_tbl_rec (1).salesrep_id                    := l_multi_salesrep;
      l_salesrep_id_tbl_rec (1).sales_credit_type_id           := 1;
      l_salesrep_id_tbl_rec (1).salesrep_type                  := 'EXTERNAL';
      l_salesrep_id_tbl_rec (1).terr_name                      := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
      l_count_rec                                              :=l_salesrep_id_tbl_rec.count+1;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_id          := l_multi_salesrep;
      l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id := 2;
      l_salesrep_id_tbl_rec (l_count_rec).salesrep_type        := 'INTERNAL';
      l_salesrep_id_tbl_rec (l_count_rec).terr_name            := g_no_territories;
      l_salesrep_id_tbl_rec (l_count_rec).role_id              :=0;
    END IF;
    --INTERNAL AND EXTERNAL SALES REP DOES NOT EXISITS
  ELSIF((NOT l_ext_exists) AND (NOT l_int_exists)) THEN
    write_emf_log_low('((NOT l_ext_exists) AND (not l_int_exists))');
    -- l_salesrep_id_tbl_rec:= l_salescredit_id_tbl_type();
    --l_salesrep_id_tbl_rec.EXTEND();
    --l_count_rec:=0;
    l_count_rec                                                 :=l_salesrep_id_tbl_rec.count+1;
    l_salesrep_id_tbl_rec (l_count_rec).salesrep_id             := l_no_salesrep;
    l_salesrep_id_tbl_rec (l_count_rec).sales_credit_type_id    := 1;
    l_salesrep_id_tbl_rec (l_count_rec).salesrep_type           := 'EXTERNAL';
    l_salesrep_id_tbl_rec (l_count_rec).terr_name               := g_no_territories;
    l_salesrep_id_tbl_rec (l_count_rec).role_id                 :=0;
    l_salesrep_id_tbl_rec (l_count_rec +1).salesrep_id          := l_no_salesrep;
    l_salesrep_id_tbl_rec (l_count_rec +1).sales_credit_type_id := 2;
    l_salesrep_id_tbl_rec (l_count_rec +1).salesrep_type        := 'INTERNAL';
    l_salesrep_id_tbl_rec (l_count_rec +1).terr_name            := g_no_territories;
    l_salesrep_id_tbl_rec (l_count_rec +1).role_id              :=0;
    write_emf_log_low('Count of l_salesrep_id_tbl_rec record after appending:'||l_salesrep_id_tbl_rec.count);
    write_emf_log_low('Inside both int and ext not_exists ',p_header_id,p_line_id);
  END IF;
  --
  --END
  write_emf_log_low('After loop in ins_sales_credit_record ',p_header_id,p_line_id);
  --APPS.xxintg_ont_wf_log_proc (p_header_id||'After first loop in l_salesrep_id_tbl_rec.count'||p_line_id||'-'||l_salesrep_id_tbl_rec.count);
  --IF (l_salesrep_id_tbl_rec.count = 0 AND (l_lines_salesrep =0 OR l_no_salesrep=l_lines_salesrep ))THEN
  IF l_salesrep_id_tbl_rec.count = 0 THEN
    --APPS.xxintg_ont_wf_log_proc (p_header_id||'After first loop inside l_salesrep_id_tbl_rec.count in ins_sales_credit_record '||p_line_id||'-'||l_salesrep_id_tbl_rec.count);
    --No Resources is attached to the Territory
    --Logging
    --No Resources
    write_emf_log_low('Inside l_salesrep_id_tbl_rec.count = 0 ',p_header_id,p_line_id);
    o_return_status  := 'Error';
    o_return_message := 'No active Resources is attached to the Territory for order line ' || p_terr_id;
    -- IF NO RESOURECE ATTACHED TO THE WINNING TERRITORY JUST RETURN THE ERROR MESSAGE
  ELSE -- WINNING TERRITROY HAS THE RESOURCE ALLOCATION and count >0
    -- THIS LOOP CONTINUES FOR THE SALES REP ID ASSOCIATION FOR THE PARTICULAR HEADER ID AND LINE ID
    write_emf_log_low('123456');
    l_index := 1;
    FOR c_line_salesrep_rec IN
    (SELECT salesrep_id,
      sales_group_id,
      percent,
      sales_credit_id,
      sales_credit_type_id
    FROM oe_sales_credits osc
    WHERE header_id = p_header_id
    AND line_id     = p_line_id
    ORDER BY sales_credit_type_id
    )
    ---  --APPS.xxintg_ont_wf_log_proc ('Before Entering l_lines_salescredit_tbl_type loop');
    LOOP
      write_emf_log_low('Entering l_lines_salescredit_tbl_type loop',p_header_id,p_line_id,c_line_salesrep_rec.salesrep_id,c_line_salesrep_rec.sales_group_id);
      --APPS.xxintg_ont_wf_log_proc (p_header_id||'Entering l_lines_salescredit_tbl_type first loop in ins_sales_credit_record procedure'||p_line_id||'-'||c_line_salesrep_rec.salesrep_id||'-'||c_line_salesrep_rec.sales_group_id||'-'||c_line_salesrep_rec.percent||'-'||c_line_salesrep_rec.sales_credit_id||'-'||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
      -- insert into xxintg.xxoe_sales_rep_temp(sno,salesrep_id,role_id,percent,sales_credit_id) values(l_index,c_line_salesrep_rec.salesrep_id,c_line_salesrep_rec.sales_group_id,c_line_salesrep_rec.percent,c_line_salesrep_rec.sales_credit_id);
      l_lines_salescredit_tbl_rec (l_index).salesrep_id          := c_line_salesrep_rec.salesrep_id;
      l_lines_salescredit_tbl_rec (l_index).role_id              := c_line_salesrep_rec.sales_group_id;
      l_lines_salescredit_tbl_rec (l_index).percent              := c_line_salesrep_rec.percent;
      l_lines_salescredit_tbl_rec (l_index).sales_credit_id      := c_line_salesrep_rec.sales_credit_id;
      l_lines_salescredit_tbl_rec (l_index).sales_credit_type_id := c_line_salesrep_rec.sales_credit_type_id;
      l_index                                                    := l_index + 1;
      write_emf_log_low('123456',TO_CHAR(l_index));
      --Logging
    END LOOP;
    -- STORE THE SALES REP AND CREDIT DETAILS IN "l_lines_salescredit_tbl_rec" AS A RECORD
    -- BASED ON THE HEADER AND LINE LEVEL INFORMATION PROVIDED IN THE ORDER
    write_emf_log_low('All count in loop',p_header_id,p_line_id,l_lines_salesrep,l_no_salesrep,l_lines_salescredit_tbl_rec.count, l_salesrep_id_tbl_rec.count);
    --APPS.xxintg_ont_wf_log_proc (p_header_id||'After first loop Entering l_lines_salescredit_tbl_type in ins_sales_credit_record procedure '||p_line_id||'-'||l_lines_salesrep||'-'||l_no_salesrep||'-'||l_lines_salescredit_tbl_rec.count||'-'|| l_salesrep_id_tbl_rec.count||'-'||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
    -- IF LINE SALES REP IS 'NO SALES REP'
    --AND THE COUNT OF SALES CREDIT RECORD TABLE IS ZERO
    -- ENTER INTO THE FOLLOWING LOOP
    IF l_lines_salesrep = l_no_salesrep AND l_lines_salescredit_tbl_rec.count = 0 THEN
      write_emf_log_low('Inside l_salesrep_id_tbl_rec.count = 0 else ',p_header_id,p_line_id);
      --APPS.xxintg_ont_wf_log_proc (p_header_id||'Before sceond loop inside l_salesrep_id_tbl_rec.count = 0 else in ins_sales_credit_record procedure'||p_line_id||'-'||l_lines_salesrep||'-'||l_no_salesrep||'-'||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
      -- "l_salesrep_id_tbl_rec' HAS THE INFORMATION ASSOCIATED WITH THE WINNING TERRITROY
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        write_emf_log_low('Inside for loop l_salesrep_cnt ',p_header_id,p_line_id);
        --APPS.xxintg_ont_wf_log_proc (p_header_id||'second Inside for loop l_salesrep_cnt'||p_line_id||'-'||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
        p_line_scredit_tbl (l_salesrep_cnt)             := oe_order_pub.g_miss_line_scredit_rec;
        p_line_scredit_tbl (l_salesrep_cnt).header_id   := p_header_id;
        p_line_scredit_tbl (l_salesrep_cnt).line_id     := p_line_id;
        p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_id;
        --Assigning group id
        p_line_scredit_tbl (l_salesrep_cnt).sales_group_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).role_id;
        p_line_scredit_tbl (l_salesrep_cnt).attribute2     := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_id;
        p_line_scredit_tbl (l_salesrep_cnt).attribute1     := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_name;
        p_line_scredit_tbl (l_salesrep_cnt).attribute4     := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type;
        write_emf_log_low('p_line_scredit_tbl (l_salesrep_cnt).attribute4:'||p_line_scredit_tbl (l_salesrep_cnt).attribute4);
        write_emf_log_low('l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type:'||l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type);
        p_line_scredit_tbl (l_salesrep_cnt).operation            := oe_globals.g_opr_create;
        p_line_scredit_tbl (l_salesrep_cnt).sales_credit_type_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id;
        p_line_scredit_tbl (l_salesrep_cnt).percent              := 100;
        write_emf_log_low('debug'||l_salesrep_cnt||','||l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_id||','||p_line_scredit_tbl (l_salesrep_cnt).percent);
      END LOOP;
      -- END OF THE FOLLOWING CONDITION
      --l_lines_salesrep = l_no_salesrep AND l_lines_salescredit_tbl_rec.count = 0
    elsif l_lines_salesrep != l_no_salesrep AND l_lines_salescredit_tbl_rec.count = 0 THEN
      write_emf_log_low('LINE SLAES IS NOT EQUAL TO NO SALES REP');
      write_emf_log_low('Inside for loop l_salesrep_cnt 1 ',p_header_id,p_line_id);
      write_emf_log_low('Inside l_salesrep_id_tbl_rec.count = 0 else ',p_header_id,p_line_id);
      -- "l_salesrep_id_tbl_rec' HAS THE INFORMATION ASSOCIATED WITH THE WINNING TERRITROY
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        write_emf_log_low('LINE SLAES IS NOT EQUAL TO NO SALES REP');
        write_emf_log_low('12345567890');
        write_emf_log_low(TO_CHAR(l_salesrep_cnt));
        write_emf_log_low('Inside for loop l_salesrep_cnt ',p_header_id,p_line_id);
        p_line_scredit_tbl (l_salesrep_cnt)                          := oe_order_pub.g_miss_line_scredit_rec;
        p_line_scredit_tbl (l_salesrep_cnt).header_id                := p_header_id;
        p_line_scredit_tbl (l_salesrep_cnt).line_id                  := p_line_id;
        p_line_scredit_tbl (l_salesrep_cnt).sales_group_id           := l_salesrep_id_tbl_rec (l_salesrep_cnt).role_id;
        IF(l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id=1) THEN
          write_emf_log_low('INSIDE EXTERNAL COUNT');
          write_emf_log_low(TO_CHAR(l_salesrep_cnt));
          p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_lines_salesrep;
          p_line_scredit_tbl (l_salesrep_cnt).attribute2  := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_id;
          p_line_scredit_tbl (l_salesrep_cnt).attribute1  := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_name;
          p_line_scredit_tbl (l_salesrep_cnt).attribute4  := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type;
          write_emf_log_low('p_line_scredit_tbl (l_salesrep_cnt).attribute4:'||p_line_scredit_tbl (l_salesrep_cnt).attribute4);
          write_emf_log_low('l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type:'||l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type);
          p_line_scredit_tbl (l_salesrep_cnt).operation            := oe_globals.g_opr_create;
          p_line_scredit_tbl (l_salesrep_cnt).sales_credit_type_id := 1;
          p_line_scredit_tbl (l_salesrep_cnt).percent              := 100 ;
          -- INTERNAL ONE
        ELSE
          write_emf_log_low('INSIDE INTERNAL COUNT');
          write_emf_log_low(TO_CHAR(l_salesrep_cnt));
          p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_id;
          p_line_scredit_tbl (l_salesrep_cnt).attribute2  := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_id;
          p_line_scredit_tbl (l_salesrep_cnt).attribute1  := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_name;
          p_line_scredit_tbl (l_salesrep_cnt).attribute4  := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type;
          write_emf_log_low('p_line_scredit_tbl (l_salesrep_cnt).attribute4:'||p_line_scredit_tbl (l_salesrep_cnt).attribute4);
          write_emf_log_low('l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type:'||l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type);
          p_line_scredit_tbl (l_salesrep_cnt).operation            := oe_globals.g_opr_create;
          p_line_scredit_tbl (l_salesrep_cnt).sales_credit_type_id := 2;
          p_line_scredit_tbl (l_salesrep_cnt).percent              := 100 ;
        END IF;
      END LOOP;
    elsif l_lines_salescredit_tbl_rec.count = l_salesrep_id_tbl_rec.count THEN
      write_emf_log_low('Inside for loop third condition ',p_header_id,p_line_id);
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        write_emf_log_low('TEST LOOP ENTERED',p_header_id,p_line_id);
        write_emf_log_low('Inside for loop l_salesrep_cnt ',p_header_id,p_line_id);
        IF(l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id= l_lines_salescredit_tbl_rec (l_salesrep_cnt).sales_credit_type_id) THEN
          write_emf_log_low('Inside for loop l_salesrep_cnt ',p_header_id,p_line_id);
          write_emf_log_low('TEST ',p_header_id,p_line_id);
          write_emf_log_low('TEST_1 ',p_header_id,p_line_id);
          p_line_scredit_tbl (l_salesrep_cnt)               := oe_order_pub.g_miss_line_scredit_rec;
          p_line_scredit_tbl (l_salesrep_cnt).header_id     := p_header_id;
          p_line_scredit_tbl (l_salesrep_cnt).line_id       := p_line_id;
          IF(l_lines_salesrep                               <>0 AND l_lines_salesrep <>l_no_salesrep AND (l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id=1)) THEN
            p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_lines_salesrep;
          ELSE
            p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_id;
          END IF;
          --Assigning group id
          p_line_scredit_tbl (l_salesrep_cnt).sales_group_id := NVL(l_salesrep_id_tbl_rec (l_salesrep_cnt).role_id,0);
          p_line_scredit_tbl (l_salesrep_cnt).attribute2     := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_id;
          p_line_scredit_tbl (l_salesrep_cnt).attribute1     := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_name;
          p_line_scredit_tbl (l_salesrep_cnt).attribute4     := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type;
          write_emf_log_low('p_line_scredit_tbl (l_salesrep_cnt).attribute4:'||p_line_scredit_tbl (l_salesrep_cnt).attribute4);
          write_emf_log_low('l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type:'||l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type);
          p_line_scredit_tbl (l_salesrep_cnt).operation            := oe_globals.G_OPR_UPDATE;
          p_line_scredit_tbl (l_salesrep_cnt).change_reason        := 'MANUAL';
          p_line_scredit_tbl (l_salesrep_cnt).sales_credit_type_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id;
          p_line_scredit_tbl (l_salesrep_cnt).percent              := 100;
          -- THIS IS UNIQUE KEY
          p_line_scredit_tbl (l_salesrep_cnt).sales_credit_id := l_lines_salescredit_tbl_rec (l_salesrep_cnt).sales_credit_id;
          write_emf_log_low('11122233');
        END IF;
      END LOOP;
      -- END OF FOLLOWINIG CONDITION
      --l_lines_salescredit_tbl_rec.count = l_salesrep_id_tbl_rec.count
    elsif l_lines_salescredit_tbl_rec.count = 1 THEN
      write_emf_log_low('Inside for loop third another condition ',p_header_id,p_line_id);
      FOR l_salesrep_cnt IN l_salesrep_id_tbl_rec.first .. l_salesrep_id_tbl_rec.last
      LOOP
        write_emf_log_low('TEST ANOTHER LOOP ENTERED',p_header_id,p_line_id);
        write_emf_log_low('Inside for loop l_salesrep_cnt ',p_header_id,p_line_id);

          write_emf_log_low('Inside for loop l_salesrep_cnt ',p_header_id,p_line_id);
          write_emf_log_low('TEST ',p_header_id,p_line_id);
          write_emf_log_low('TEST_1 ',p_header_id,p_line_id);
          p_line_scredit_tbl (l_salesrep_cnt)               := oe_order_pub.g_miss_line_scredit_rec;
          p_line_scredit_tbl (l_salesrep_cnt).header_id     := p_header_id;
          p_line_scredit_tbl (l_salesrep_cnt).line_id       := p_line_id;
          IF(l_lines_salesrep                               <>0 AND l_lines_salesrep <>l_no_salesrep AND (l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id=1)) THEN
            p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_lines_salesrep;
          ELSE
            p_line_scredit_tbl (l_salesrep_cnt).salesrep_id := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_id;
          END IF;
          --Assigning group id
          p_line_scredit_tbl (l_salesrep_cnt).sales_group_id := NVL(l_salesrep_id_tbl_rec (l_salesrep_cnt).role_id,0);
          p_line_scredit_tbl (l_salesrep_cnt).attribute2     := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_id;
          p_line_scredit_tbl (l_salesrep_cnt).attribute1     := l_salesrep_id_tbl_rec (l_salesrep_cnt).terr_name;
          p_line_scredit_tbl (l_salesrep_cnt).attribute4     := l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type;
          write_emf_log_low('p_line_scredit_tbl (l_salesrep_cnt).attribute4:'||p_line_scredit_tbl (l_salesrep_cnt).attribute4);
          write_emf_log_low('l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type:'||l_salesrep_id_tbl_rec (l_salesrep_cnt).salesrep_type);
          p_line_scredit_tbl (l_salesrep_cnt).sales_credit_type_id     := l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id;
          p_line_scredit_tbl (l_salesrep_cnt).percent                  := 100;
          IF(l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id=1 AND (l_salesrep_id_tbl_rec (l_salesrep_cnt).sales_credit_type_id= l_lines_salescredit_tbl_rec (l_salesrep_cnt).sales_credit_type_id)) THEN
            p_line_scredit_tbl (l_salesrep_cnt).operation              := oe_globals.G_OPR_UPDATE;
            p_line_scredit_tbl (l_salesrep_cnt).change_reason          := 'MANUAL';
            -- THIS IS UNIQUE KEY
            p_line_scredit_tbl (l_salesrep_cnt).sales_credit_id := l_lines_salescredit_tbl_rec (l_salesrep_cnt).sales_credit_id;
          ELSE
            p_line_scredit_tbl (l_salesrep_cnt).operation := oe_globals.g_opr_create;
          END IF;
          write_emf_log_low('11122233');

      END LOOP;
      -- END OF FOLLOWINIG CONDITION
      --l_lines_salescredit_tbl_rec.count = l_salesrep_id_tbl_rec.count
    ELSE
      write_emf_log_low('Inside for loop l_salesrep_cnt on fourth condition before loop',p_header_id,p_line_id);
      --"l_lines_salescredit_tbl_rec" has the info based on header and line id
      --"l_salesrep_id_tbl_rec" has the info based on winning territory
      -- COUNT OF BOTH RECORD NOT EQUALS THIS ELSE CONDITION WILL CONTINUE
      FOR l_salesrep_cnt IN l_lines_salescredit_tbl_rec.first .. l_lines_salescredit_tbl_rec.last
      LOOP
        write_emf_log_low('Inside for loop l_salesrep_cnt on fourth condition',p_header_id,p_line_id);
        UPDATE oe_sales_credits
        SET attribute1          = g_no_territories
        WHERE sales_credit_id   = l_lines_salescredit_tbl_rec (l_salesrep_cnt).sales_credit_id
        AND SALES_CREDIT_TYPE_ID=l_salesrep_id_tbl_rec(l_salesrep_cnt).sales_credit_type_id;
      END LOOP;
    END IF;
    o_return_status  := 'Success';
    o_return_message := 'Successfully populated salesrep';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  o_return_status  := 'Error';
  o_return_message := 'Unexpected Error ' || p_terr_id;
  write_emf_log_high('Exception ins_sales_credit_record ' || sqlerrm,p_header_id,p_line_id,p_terr_id);
END ins_sales_credit_record;
PROCEDURE xx_find_territories(
    p_country             VARCHAR2 ,
    p_customer_name_range VARCHAR2 ,
    p_customer_id         NUMBER ,
    p_site_number         NUMBER,
    p_division            VARCHAR2,
    p_sub_division        VARCHAR2,
    p_dcode               VARCHAR2,
    p_surgeon_name        VARCHAR2,
    p_cust_account        VARCHAR2,
    p_county              VARCHAR2,
    p_postal_code         VARCHAR2,
    p_province            VARCHAR2,
    p_state               VARCHAR2,
    o_terr_id OUT NUMBER ,
    o_status OUT VARCHAR2 ,
    o_error_message OUT VARCHAR2 )
IS
  CURSOR cur_multiple_territories
  IS
    SELECT terr_id ,
      rank ,
      terr_name,
      select_flag,
      qualifier_name ,
      qualifier_value
    FROM xxintg.xx_m2c_salesrep_terr_data
    WHERE terr_id IS NOT NULL FOR UPDATE ;
  l_rank             NUMBER   := NULL;
  l_max_rank         NUMBER   := NULL;
  l_current_rank     NUMBER   := NULL;
  l_parent_terr_id   NUMBER   := NULL;
  l_current_terr_id  NUMBER   := NULL;
  l_terr_id          NUMBER;
  l_count            NUMBER := 0;
  l_multi_count      NUMBER := 0;
  l_territories_name VARCHAR2 (500);
  l_select_flag      VARCHAR2 (1);
  l_terr_select_flag VARCHAR2 (1);
  l_terr_count       NUMBER;
  l_exception_count  NUMBER;
BEGIN
  write_emf_log_low('Entering xx_find_territories ',NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
  BEGIN
    SELECT COUNT(1)
    INTO l_exception_count
    FROM xx_emf_process_setup xeps ,
      xx_emf_process_parameters xepp
    WHERE xeps.process_name = g_object_name
    AND xeps.process_id     = xepp.process_id
    AND upper (xepp.parameter_name) LIKE 'DIVISION_EXCEPTIONS%'
    AND NVL (xepp.enabled_flag, 'Y') = 'Y'
    AND xepp.parameter_value         = p_division;
  EXCEPTION
  WHEN OTHERS THEN
    l_exception_count := 0;
  END;
  IF l_exception_count != 0 THEN
    BEGIN
      INSERT
      INTO xxintg.xx_m2c_salesrep_terr_data
        (
          terr_id,
          rank,
          terr_name,
          qualifier_name,
          qualifier_value,
          unique_flag ,
          select_flag
        )
      SELECT jtqa.terr_id ,
        rank ,
        jta.name,
        jsqa.name qualifier_name,
        jtva.low_value_char,
        'Y',
        'Y'
      FROM jtf_terr_values jtva ,
        jtf_terr_qual jtqa ,
        jtf_qual_usgs jqua ,
        jtf_seeded_qual jsqa ,
        apps.jtf_terr jta
      WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
      AND jtqa.qual_usg_id         = jqua.qual_usg_id
      AND jqua.org_id              = jtqa.org_id
      AND jqua.enabled_flag        = 'Y'
      AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
      AND qual_type_usg_id         = -1001
      AND jtqa.terr_id             = jta.terr_id
      AND jsqa.name                = 'Division'
      AND jtva.comparison_operator = '='
      AND jtva.low_value_char      = p_division;
    EXCEPTION
    WHEN OTHERS THEN
      write_emf_log_low('Error inserting xx_m2c_salesrep_terr_data ' || sqlerrm);
    END;
  ELSE
    BEGIN
      INSERT
      INTO xxintg.xx_m2c_salesrep_terr_data
        (
          terr_id,
          rank,
          terr_name,
          qualifier_name,
          qualifier_value
        )
      SELECT DISTINCT terr_id ,
        rank ,
        name,
        qualifier_name,
        low_value_char
      FROM
        (SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Country'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_country
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id = jtqa.terr_qual_id
        AND jtqa.qual_usg_id    = jqua.qual_usg_id
        AND jqua.org_id         = jtqa.org_id
        AND jqua.enabled_flag   = 'Y'
        AND jqua.seeded_qual_id = jsqa.seeded_qual_id
        AND qual_type_usg_id    = -1001
        AND jtqa.terr_id        = jta.terr_id
        AND jsqa.name           = 'Customer Name Range'
          -- Condition splited for Ticket  # 2381
        AND ((jtva.comparison_operator = 'LIKE'
        AND p_customer_name_range LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_customer_name_range    = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_customer_name_range BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Customer Name'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char_id   = p_customer_id
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Site Number'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char_id   = p_site_number
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Division'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_division
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Sub Division'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_sub_division
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
        AND jtqa.qual_usg_id            = jqua.qual_usg_id
        AND jqua.org_id                 = jtqa.org_id
        AND jqua.enabled_flag           = 'Y'
        AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
        AND qual_type_usg_id            = -1001
        AND jtqa.terr_id                = jta.terr_id
        AND jsqa.name                   = 'Dcode'
        AND ( (jtva.comparison_operator = 'LIKE'
        AND p_dcode LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_dcode                  = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_dcode BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Surgeon Name'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_surgeon_name
        AND NOT EXISTS
          (SELECT 1
          FROM jtf_terr_qual jtqa ,
            jtf_qual_usgs jqua ,
            jtf_seeded_qual jsqa
          WHERE jtqa.qual_usg_id  = jqua.qual_usg_id
          AND jqua.org_id         = jtqa.org_id
          AND jqua.enabled_flag   = 'Y'
          AND jqua.seeded_qual_id = jsqa.seeded_qual_id
          AND qual_type_usg_id    = -1001
          AND jtqa.terr_id        = jta.terr_id
          AND jsqa.name           = 'Customer Account Number'
          )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
        AND jtqa.qual_usg_id            = jqua.qual_usg_id
        AND jqua.org_id                 = jtqa.org_id
        AND jqua.enabled_flag           = 'Y'
        AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
        AND qual_type_usg_id            = -1001
        AND jtqa.terr_id                = jta.terr_id
        AND jsqa.name                   = 'Customer Account Number'
        AND ( (jtva.comparison_operator = 'LIKE'
        AND p_cust_account LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_cust_account           = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_cust_account BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        AND NOT EXISTS
          (SELECT 1
          FROM jtf_terr_qual jtqa ,
            jtf_qual_usgs jqua ,
            jtf_seeded_qual jsqa
          WHERE jtqa.qual_usg_id  = jqua.qual_usg_id
          AND jqua.org_id         = jtqa.org_id
          AND jqua.enabled_flag   = 'Y'
          AND jqua.seeded_qual_id = jsqa.seeded_qual_id
          AND qual_type_usg_id    = -1001
          AND jtqa.terr_id        = jta.terr_id
          AND jsqa.name           = 'Surgeon Name'
          )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'County'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_county
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'Province'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_province
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
        AND jtqa.qual_usg_id            = jqua.qual_usg_id
        AND jqua.org_id                 = jtqa.org_id
        AND jqua.enabled_flag           = 'Y'
        AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
        AND qual_type_usg_id            = -1001
        AND jtqa.terr_id                = jta.terr_id
        AND jsqa.name                   = 'Postal Code'
        AND ( (jtva.comparison_operator = 'LIKE'
        AND p_postal_code LIKE '%'
          || jtva.low_value_char
          || '%')
        OR (jtva.comparison_operator = '='
        AND p_postal_code            = jtva.low_value_char )
        OR (jtva.comparison_operator = 'BETWEEN'
        AND p_postal_code BETWEEN jtva.low_value_char AND jtva.high_value_char) )
        UNION ALL
        SELECT jtqa.terr_id ,
          rank ,
          jta.name,
          jsqa.name qualifier_name,
          jtva.low_value_char
        FROM jtf_terr_values jtva ,
          jtf_terr_qual jtqa ,
          jtf_qual_usgs jqua ,
          jtf_seeded_qual jsqa ,
          apps.jtf_terr jta
        WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
        AND jtqa.qual_usg_id         = jqua.qual_usg_id
        AND jqua.org_id              = jtqa.org_id
        AND jqua.enabled_flag        = 'Y'
        AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
        AND qual_type_usg_id         = -1001
        AND jtqa.terr_id             = jta.terr_id
        AND jsqa.name                = 'State'
        AND jtva.comparison_operator = '='
        AND jtva.low_value_char      = p_state
        UNION ALL
          (SELECT jtqa.terr_id ,
            1 ,
            jta.name,
            jsqa.name qualifier_name,
            jtva.low_value_char
          FROM jtf_terr_values jtva ,
            jtf_terr_qual jtqa ,
            jtf_qual_usgs jqua ,
            jtf_seeded_qual jsqa ,
            apps.jtf_terr jta,
            jtf_terr_values jtva1 ,
            jtf_terr_qual jtqa1 ,
            jtf_qual_usgs jqua1 ,
            jtf_seeded_qual jsqa1
          WHERE jtva.terr_qual_id       = jtqa.terr_qual_id
          AND jtqa.qual_usg_id          = jqua.qual_usg_id
          AND jqua.org_id               = jtqa.org_id
          AND jqua.enabled_flag         = 'Y'
          AND jqua.seeded_qual_id       = jsqa.seeded_qual_id
          AND jqua.qual_type_usg_id     = -1001
          AND jtqa.terr_id              = jta.terr_id
          AND jsqa.name                 = 'Customer Account Number'
          AND jtva.comparison_operator  = '='
          AND p_cust_account            = jtva.low_value_char
          AND jtva1.terr_qual_id        = jtqa1.terr_qual_id
          AND jtqa1.qual_usg_id         = jqua1.qual_usg_id
          AND jqua1.org_id              = jtqa1.org_id
          AND jqua1.enabled_flag        = 'Y'
          AND jqua1.seeded_qual_id      = jsqa1.seeded_qual_id
          AND jqua1.qual_type_usg_id    = -1001
          AND jtqa1.terr_id             = jta.terr_id
          AND jsqa1.name                = 'Surgeon Name'
          AND jtva1.comparison_operator = '='
          AND jtva1.low_value_char      = p_surgeon_name
          )
        )
      ORDER BY rank ;
      INSERT
      INTO xx_m2c_salesrep_terr_data_q
        (
          terr_id,
          rank,
          terr_name,
          select_flag,
          unique_flag,
          qualifier_name,
          qualifier_value
        )
      SELECT * FROM xxintg.xx_m2c_salesrep_terr_data;
    EXCEPTION
    WHEN OTHERS THEN
      write_emf_log_low('Error inserting xx_m2c_salesrep_terr_data ' || sqlerrm);
    END;
    BEGIN
      INSERT
      INTO xxintg.xx_m2c_salesrep_terr_data
        (
          qualifier_name,
          qualifier_value
        )
        (SELECT 'Country',p_country FROM dual
          UNION ALL
          SELECT 'Customer Name Range',p_customer_name_range FROM dual
          UNION ALL
          SELECT 'Customer Name',TO_CHAR(p_customer_id) FROM dual
          UNION ALL
          SELECT 'Site Number',TO_CHAR(p_site_number) FROM dual
          UNION ALL
          SELECT 'Division',p_division FROM dual
          UNION ALL
          SELECT 'Sub Division',p_sub_division FROM dual
          UNION ALL
          SELECT 'Dcode',p_dcode FROM dual
          UNION ALL
          SELECT 'Surgeon Name',p_surgeon_name FROM dual
          UNION ALL
          SELECT 'Customer Account Number',p_cust_account FROM dual
          UNION ALL
          SELECT 'County',p_county FROM dual
          UNION ALL
          SELECT 'Province',p_province FROM dual
          UNION ALL
          SELECT 'Postal Code',p_postal_code FROM dual
          UNION ALL
          SELECT 'State',p_state FROM dual
        );
    EXCEPTION
    WHEN OTHERS THEN
      write_emf_log_low('Error inserting xx_m2c_salesrep_terr_data ' || sqlerrm);
    END;
    FOR rec_cur_multiple_territories IN cur_multiple_territories
    LOOP
      write_emf_log_low
      (
        rec_cur_multiple_territories.terr_id||','||rec_cur_multiple_territories.rank||','|| rec_cur_multiple_territories.terr_name||','||rec_cur_multiple_territories.qualifier_name||','||rec_cur_multiple_territories.qualifier_value
      )
      ;
      l_current_rank         :=rec_cur_multiple_territories.rank ;
      l_max_rank             :=rec_cur_multiple_territories.rank ;
      l_parent_terr_id       :=rec_cur_multiple_territories.terr_id ;
      l_current_terr_id      :=rec_cur_multiple_territories.terr_id ;
      l_select_flag          := 'Y';
      WHILE l_parent_terr_id <> 1
      LOOP
        BEGIN
          SELECT parent_territory_id,
            rank
          INTO l_parent_terr_id,
            l_current_rank
          FROM apps.jtf_terr jta
          WHERE terr_id = l_current_terr_id;
        EXCEPTION
        WHEN OTHERS THEN
          l_parent_terr_id := 1;
        END;
        IF l_parent_terr_id  != 1 THEN
          l_terr_select_flag := 'N';
          l_terr_count       := 0;
          FOR qua_row IN
          (SELECT jtva.low_value_char std_qua_value,
            xxmstd.qualifier_value cust_qua_value,
            qualifier_name
          FROM jtf_terr_values jtva ,
            jtf_terr_qual jtqa ,
            jtf_qual_usgs jqua ,
            jtf_seeded_qual jsqa ,
            apps.jtf_terr jta,
            xxintg.xx_m2c_salesrep_terr_data xxmstd
          WHERE jtva.terr_qual_id                          = jtqa.terr_qual_id
          AND jtqa.qual_usg_id                             = jqua.qual_usg_id
          AND jqua.org_id                                  = jtqa.org_id
          AND jqua.enabled_flag                            = 'Y'
          AND jqua.seeded_qual_id                          = jsqa.seeded_qual_id
          AND qual_type_usg_id                             = -1001
          AND jtqa.terr_id                                 = jta.terr_id
          AND jsqa.name                                    = qualifier_name
          AND jtqa.terr_id                                 = l_parent_terr_id
          AND rec_cur_multiple_territories.qualifier_name != qualifier_name
          )
          LOOP
            l_terr_count            := l_terr_count + 1;
            IF qua_row.std_qua_value = qua_row.cust_qua_value THEN
              l_terr_select_flag    := 'Y';
            END IF;
          END LOOP;
          IF l_terr_select_flag = 'N' AND l_terr_count != 0 THEN
            l_select_flag      := 'N';
          END IF;
          l_current_terr_id := l_parent_terr_id;
        END IF;
      END LOOP;
      IF l_select_flag = 'Y' THEN
        UPDATE xxintg.xx_m2c_salesrep_terr_data
        SET select_flag = 'Y'
        WHERE CURRENT OF cur_multiple_territories;
      END IF;
    END LOOP;
  END IF;
  SELECT COUNT(1)
  INTO l_count
  FROM xxintg.xx_m2c_salesrep_terr_data
  WHERE select_flag  = 'Y';
  IF l_count         = 0 THEN
    o_terr_id       := -9999;
    o_status        := 'Error';
    o_error_message := 'No matching territories found for the attributes';
    write_emf_log_low('Inside l_count         = 0   ',NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
  ELSE
    UPDATE xxintg.xx_m2c_salesrep_terr_data
    SET unique_flag   = 'Y'
    WHERE select_flag = 'Y'
    AND rank          =
      (SELECT MIN(rank)
      FROM xxintg.xx_m2c_salesrep_terr_data
      WHERE select_flag = 'Y'
      ) ;
    UPDATE xxintg.xx_m2c_salesrep_terr_data
    SET unique_flag = 'D'
    WHERE terr_id  IN
      (SELECT terr_id
      FROM xxintg.xx_m2c_salesrep_terr_data
      WHERE select_flag = 'Y'
      AND unique_flag   = 'Y'
      HAVING COUNT(1)  !=
        (SELECT MAX(COUNT(1))
        FROM xxintg.xx_m2c_salesrep_terr_data
        WHERE select_flag = 'Y'
        AND unique_flag   = 'Y'
        GROUP BY terr_id
        )
      GROUP BY terr_id
      );
    o_status        := 'Success';
    o_error_message := NULL;
    write_emf_log_low('Inside l_count         = 1   ',NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  o_terr_id       := -9999;
  o_status        := 'Error';
  o_error_message := 'Unexpected Error occured in find_territories procedure ' ;
  write_emf_log_high('Exception xx_find_territories ' || sqlerrm,NULL,NULL,p_country,p_customer_name_range,p_customer_id,p_site_number);
END xx_find_territories;
PROCEDURE xx_oe_assign_salesrep(
    o_status OUT VARCHAR2 ,
    o_errormess OUT VARCHAR2 ,
    p_header_id IN NUMBER,
    p_line_id   IN NUMBER DEFAULT NULL )
IS
  -------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 18-APR-2012
  Filename       :
  Description    : This procedure is used to populate the Salesrep to the respective order line
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  18-Apr-2012   1.0       Raquib Iqbal        Initial development.
  */
  --------------------------------------------------------------------------------
  CURSOR c_order_details_info (cp_header_id NUMBER,cp_line_id NUMBER)
  IS
    SELECT ool.line_id ,
      ool.line_number ,
      hps.party_id ,
      hp.party_name ,
      hl.country ,
      hps.party_site_id,
      -- Added for version 1.5
      mc.segment4,
      mc.segment10,
      mc.segment9,
      ooh.attribute8,
      account_number,
      -- end for version 1.5
      hl.county,
      hl.postal_code,
      hl.province,
      hl.state
    FROM oe_order_lines ool ,
      oe_order_headers ooh ,
      hz_cust_site_uses hcsu ,
      hz_cust_acct_sites hcas ,
      hz_party_sites hps ,
      hz_locations hl ,
      hz_parties hp,
      -- Added for version 1.5
      mtl_category_sets mcs,
      mtl_item_categories mic,
      mtl_categories_b mc,
      hz_cust_accounts hca
      -- End for version 1.5
    WHERE ool.header_id        = cp_header_id
    AND ool.line_id            = NVL(cp_line_id,ool.line_id)
    AND hcsu.site_use_id       = ool.ship_to_org_id
    AND hcsu.site_use_code     = 'SHIP_TO'
    AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
    AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
    AND hcas.party_site_id     = hps.party_site_id(+)
    AND hl.location_id(+)      = hps.location_id
    AND hp.party_id            = hps.party_id
    AND hps.status             = 'A'
    AND hp.status              = 'A'
    AND hcas.status            = 'A'
    AND hcsu.status            = 'A'
      -- Added for version 1.5
    AND mcs.category_set_name              = xx_emf_pkg.get_paramater_value ('XX_OE_ASSIGN_SALESREP', 'CATEGORY_NAME' )
    AND mcs.category_set_id                = mic.category_set_id
    AND mic.inventory_item_id              = ool.inventory_item_id
    AND mic.organization_id                = fnd_profile.value ('MSD_MASTER_ORG')
    AND mc.category_id                     = mic.category_id
    AND mc.enabled_flag                    = 'Y'
    AND NVL (mc.disable_date, sysdate + 1) > sysdate
    AND ool.header_id                      = ooh.header_id
    AND hca.cust_account_id                = ooh.sold_to_org_id
      -- end for version 1.5
    AND NOT EXISTS
      (SELECT 1
      FROM xx_emf_process_setup xeps ,
        xx_emf_process_parameters xepp
      WHERE xeps.process_name = g_object_name
      AND xeps.process_id     = xepp.process_id
      AND upper (xepp.parameter_name) LIKE 'ORDER_LINE_STATUS%'
      AND NVL (xepp.enabled_flag, 'Y') = 'Y'
      AND ool.flow_status_code         = upper (xepp.parameter_value)
      )
    /*AND NOT EXISTS
    (SELECT 1
    FROM oe_sales_credits osc
    WHERE header_id = cp_header_id
    AND line_id     = ool.line_id
    )*/
    ;
  x_action_type       VARCHAR2 (10) := NULL;
  x_validation_status VARCHAR2 (30) := NULL;
  x_return_status     VARCHAR2 (10) := NULL;
  x_error_message     VARCHAR2 (2000);
  x_territory_status  VARCHAR2 (10);
  x_msg_count         NUMBER;
  x_msg_data          VARCHAR2 (2000);
  x_org_id            NUMBER;
  x_return_message    VARCHAR2 (2000);
  x_error_code        NUMBER      := xx_emf_cn_pkg.cn_success;
  x_terr_id jtf_terr.terr_id%type := NULL;
  x_ord_number NUMBER;
  -- =================================================================================
  -- Declare Table type Variable
  -- =================================================================================
  --xx_line_terr_table xx_line_terr_tab_type;
  x_index              NUMBER := 0;
  l_api_version_number NUMBER := 1.0;
  l_msg_count          NUMBER;
  l_msg_data           VARCHAR2 (2000);
  x_debug_file         VARCHAR2 (100);
  /*****************INPUT VARIABLES FOR PROCESS_ORDER API**************************/
  --l_header_rec oe_order_pub.header_rec_type;
  x_header_scredit_tbl oe_order_pub.header_scredit_tbl_type;
  -- x_line_tbl oe_order_pub.line_tbl_type;
  x_line_scredit_tbl oe_order_pub.line_scredit_tbl_type;
  l_action_request_tbl oe_order_pub.request_tbl_type;
  /*****************OUT VARIABLES FOR PROCESS_ORDER API****************************/
  l_header_rec_out oe_order_pub.header_rec_type;
  l_header_val_rec_out oe_order_pub.header_val_rec_type;
  l_header_adj_tbl_out oe_order_pub.header_adj_tbl_type;
  l_header_adj_val_tbl_out oe_order_pub.header_adj_val_tbl_type;
  l_header_price_att_tbl_out oe_order_pub.header_price_att_tbl_type;
  l_header_adj_att_tbl_out oe_order_pub.header_adj_att_tbl_type;
  l_header_adj_assoc_tbl_out oe_order_pub.header_adj_assoc_tbl_type;
  l_header_scredit_tbl_out oe_order_pub.header_scredit_tbl_type;
  l_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
  l_line_tbl_out oe_order_pub.line_tbl_type;
  l_line_val_tbl_out oe_order_pub.line_val_tbl_type;
  l_line_adj_tbl_out oe_order_pub.line_adj_tbl_type;
  l_line_adj_val_tbl_out oe_order_pub.line_adj_val_tbl_type;
  l_line_price_att_tbl_out oe_order_pub.line_price_att_tbl_type;
  l_line_adj_att_tbl_out oe_order_pub.line_adj_att_tbl_type;
  l_line_adj_assoc_tbl_out oe_order_pub.line_adj_assoc_tbl_type;
  l_line_scredit_tbl_out oe_order_pub.line_scredit_tbl_type;
  l_line_scredit_val_tbl_out oe_order_pub.line_scredit_val_tbl_type;
  l_lot_serial_tbl_out oe_order_pub.lot_serial_tbl_type;
  l_lot_serial_val_tbl_out oe_order_pub.lot_serial_val_tbl_type;
  l_action_request_tbl_out oe_order_pub.request_tbl_type;
  l_line_scredit_tbl_temp oe_order_pub.line_scredit_tbl_type;
  --x_line_tbl_count NUMBER := 1;
  l_msg_index NUMBER;
BEGIN
  write_emf_log_low('Inside xx_oe_assign_salesrep  ',p_header_id);
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 1';
  --Call EMF procedure to set the env.Set_cnv_env;
  mo_global.init ('ONT');
  mo_global.set_policy_context ('S', fnd_global.org_id);
  --l_header_rec           := oe_order_pub.g_miss_header_rec;
  --l_header_rec.header_id := p_header_id;
  FOR order_details_info IN c_order_details_info (p_header_id,p_line_id )
  LOOP
    --x_line_tbl (x_line_tbl_count)           := oe_order_pub.g_miss_line_rec;
    --x_line_tbl (x_line_tbl_count).header_id := p_header_id;
    --x_line_tbl (x_line_tbl_count).line_id        := order_details_info.line_id;
    write_emf_log_low('Inside order_details_info loop  ',p_header_id,order_details_info.line_id);
    g_prog_stage       := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 5';
    x_error_message    := NULL;
    x_territory_status := NULL;
    x_return_message   := NULL;
    x_return_status    := NULL;
    x_terr_id          := NULL;
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------
    ----KM20150325
    -- GET INTERNAL REP DETAILS BY CALLING THE FIND TERRITOIRES AGAIN AND POPULATE TO THE TEMP TABLE
    ---------------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------
    --NEW LOGIN ADDED
    ---------------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------
    -- FOLLOWING FOUR STEPS WORKS FOR EXTERNAL SALES REP AND ITS CREDITS
    --delete the following temp table xx_m2c_salesrep_terr_data
    --xx_find_territories(populate the terr id and other info in temp  based on the given i/p)
    --ins_sales_credit_record(validate and get the sales credit record based on detail in temp table)
    --store the o/p of ins_sales_credit_record in temp record(first record)
    -- FOLLOWING FOUR STEPS WORKS FOR INTERNAL SALES REP AND ITS CREDITS
    --delete the following temp table xx_m2c_salesrep_terr_data again for internal
    --xx_find_territories(populate the terr id and other info in temp  based on country,zip,division)
    --ins_sales_credit_record(validate and get the sales credit record based on detail in temp table)
    --store the o/p of ins_sales_credit_record in temp record(second record)
    ---------------------------------------------------------------------------------------------------------------
    -- call process_order api using the temp record(combining record one and two as a single record)
    -- THIS will update the Sales rep at the corresponding sales quota
    -- DELETE THE TEMP TABLE
    DELETE
    FROM xxintg.xx_m2c_salesrep_terr_data;
    write_emf_log_low('Calling xx_find_territories  ',p_header_id,order_details_info.line_id,order_details_info.country,order_details_info.party_name, order_details_info.party_id,order_details_info.party_site_id);
    xx_find_territories (p_country => order_details_info.country , p_customer_name_range => order_details_info.party_name , p_customer_id => order_details_info.party_id , p_site_number => order_details_info.party_site_id , p_division => order_details_info.segment4,p_sub_division => order_details_info.segment10,p_dcode => order_details_info.segment9,p_surgeon_name => order_details_info.attribute8, p_cust_account => order_details_info.account_number, p_county => order_details_info.county, p_postal_code => order_details_info.postal_code, p_province => order_details_info.province,p_state => order_details_info.state, o_terr_id => x_terr_id , o_status => x_territory_status , o_error_message => x_error_message );
    --ABOVE API CALL POPULATE THE VALUES INTO THE FOLLWOING TEMP TABLE(xx_m2c_salesrep_terr_data) AND ALSO IT UPDATE THE TO COLUMN SELECT_FLAG ANF UNIQUE_FLAG
    --AFTER THIS API CALL TEMP TABLE SHOULD HAVE ONLY ONE RECORD WITH SELECT_FLAG='Y' AND UNIQUE_FLAG='Y' or NO RECORD , NOT MORE THAN ONE
    write_emf_log_low('After calling xx_find_territories  ',p_header_id,order_details_info.line_id,order_details_info.country,order_details_info.party_name, order_details_info.party_id,order_details_info.party_site_id,x_terr_id,x_territory_status,x_error_message );
    g_prog_stage         := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 6.1';
    IF x_territory_status = 'Error' THEN
      g_prog_stage       := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 7';
      write_emf_log_low(' Inside x_territory_status = Error',p_header_id,order_details_info.line_id );
      -- Logging
      o_status    := 'Error';
      o_errormess := x_error_message;
    ELSE
      write_emf_log_low('Inside x_territory_status = Error else part',p_header_id,order_details_info.line_id );
      g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 8';
      write_emf_log_low('Calling ins_sales_credit_record ',p_header_id,order_details_info.line_id,x_terr_id );
      --FOLLOWING API WILL OUTPUT OF THE SINGLE RECORD WHICH HAS ALL THE SALES CREDIT INFORMATION FOR EXTERNAL SALES REP
      --ALL VALIDATIONS HANDLED INSIDE THE FOLLWOING API-
      --FOLLOWING API WILL RETURN TWO RECORDS ONE IS FOR EXTERNAL WITH VALID DATA AND ONE DUMMY RECORD FOR INTERNAL
      --SALES_CREDIT_TYPE_ID=1 MEANS THE RECORD DENOTES EXTERNAL
      --SALES_CREDIT_TYPE_ID BASED ON DFF(ATTRIBUTE1) ON RESOURCE_GROUP
      ins_sales_credit_record (p_line_scredit_tbl => x_line_scredit_tbl , p_header_id => p_header_id, p_line_id => order_details_info.line_id,p_terr_id => x_terr_id, o_return_status => x_return_status, o_return_message => x_return_message );
      x_index := x_index + 1;
      -- ASSIGN THE OUTPUT VALUE TO THE TEMP RECORD
      FOR l_salesrep_tbl IN x_line_scredit_tbl.first .. x_line_scredit_tbl.last
      LOOP
        -- SALES_CREDIT_TYPE_ID=1 DENOTES EXTERNAL VALUES
        IF (x_line_scredit_tbl(l_salesrep_tbl).sales_credit_type_id =1) THEN
          write_emf_log_low('Inside for loop External temp record creation ',p_header_id,p_line_id);
          --APPS.xxintg_ont_wf_log_proc (p_header_id||'second Inside for loop l_salesrep_cnt'||p_line_id||'-'||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
          l_line_scredit_tbl_temp (1)             := oe_order_pub.g_miss_line_scredit_rec;
          l_line_scredit_tbl_temp (1).header_id   := x_line_scredit_tbl(l_salesrep_tbl).header_id;
          l_line_scredit_tbl_temp (1).line_id     := x_line_scredit_tbl(l_salesrep_tbl).line_id;
          l_line_scredit_tbl_temp (1).salesrep_id := x_line_scredit_tbl(l_salesrep_tbl).salesrep_id;
          --Assigning group id
          l_line_scredit_tbl_temp (1).sales_group_id       := x_line_scredit_tbl(l_salesrep_tbl).sales_group_id;
          l_line_scredit_tbl_temp (1).attribute2           := x_line_scredit_tbl(l_salesrep_tbl).attribute2;
          l_line_scredit_tbl_temp (1).attribute1           := x_line_scredit_tbl(l_salesrep_tbl).attribute1;
          l_line_scredit_tbl_temp (1).attribute4           := x_line_scredit_tbl(l_salesrep_tbl).attribute4;
          l_line_scredit_tbl_temp (1).operation            := x_line_scredit_tbl(l_salesrep_tbl).operation;
          l_line_scredit_tbl_temp (1).sales_credit_type_id := x_line_scredit_tbl(l_salesrep_tbl).sales_credit_type_id;
          l_line_scredit_tbl_temp (1).sales_credit_id      := x_line_scredit_tbl(l_salesrep_tbl).sales_credit_id;
          l_line_scredit_tbl_temp (1).percent              := x_line_scredit_tbl(l_salesrep_tbl).percent;
          write_emf_log_low('Sales Rep Id for the External');
          write_emf_log_low('Sales Rep Id for the External:'||l_line_scredit_tbl_temp (1).salesrep_id);
        END IF;
      END LOOP;
      x_line_scredit_tbl.delete;
      -- DELETE THE X_LINE_SCREDIT_TBL to MAKE SURE ITS NOT MERGING WITH THE FURHTER CALL
      -- DELTE THE TEMP TABLE WHICH CONTAINS EXTERNAL VALUES SHOW THAT WE CAN POPULATE THE VALUES FOR INTERNAL
      DELETE
      FROM xxintg.xx_m2c_salesrep_terr_data;
      write_emf_log_low('Calling xx_find_territories_internal',p_header_id,order_details_info.line_id,order_details_info.country,order_details_info.party_name, order_details_info.party_id,order_details_info.party_site_id);
      xx_find_territories (p_country => order_details_info.country , p_customer_name_range => NULL , p_customer_id => NULL , p_site_number => NULL , p_division => order_details_info.segment4,p_sub_division => NULL,p_dcode => NULL,p_surgeon_name => NULL, p_cust_account => order_details_info.account_number, p_county =>NULL, p_postal_code => order_details_info.postal_code, p_province => NULL,p_state =>order_details_info.state, o_terr_id => x_terr_id , o_status => x_territory_status , o_error_message => x_error_message );
      --ABOVE API CALL POPULATE THE VALUES INTO THE FOLLWOING TEMP TABLE(xx_m2c_salesrep_terr_data) AND ALSO IT UPDATE THE TO COLUMN SELECT_FLAG ANF UNIQUE_FLAG
      --AFTER THIS API CALL TEMP TABLE SHOULD HAVE ONLY ONE RECORD WITH SELECT_FLAG='Y' AND UNIQUE_FLAG='Y' or NO RECORD , NOT MORE THAN ONE
      write_emf_log_low('After calling xx_find_territories_internal',p_header_id,order_details_info.line_id,order_details_info.country,order_details_info.party_name, order_details_info.party_id,order_details_info.party_site_id,x_terr_id,x_territory_status,x_error_message );
      g_prog_stage         := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 6.1';
      IF x_territory_status = 'Error' THEN
        g_prog_stage       := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 7';
        write_emf_log_low(' Inside x_territory_status = Error',p_header_id,order_details_info.line_id );
        -- Logging
        o_status    := 'Error';
        o_errormess := x_error_message;
      ELSE
        write_emf_log_low('Inside x_territory_status = Error else part',p_header_id,order_details_info.line_id );
        g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 8';
        x_index      := x_index + 1;
        -- Call procudere to fetch and insert Salesrep at sales credit from at Order Header Level
        write_emf_log_low('Calling ins_sales_credit_record ',p_header_id,order_details_info.line_id,x_terr_id );
        --FOLLOWING API WILL OUTPUT OF THE SINGLE RECORD WHICH HAS ALL THE SALES CREDIT INFORMATION FOR INTERNAL SALES REP
        --ALL VALIDATIONS HANDLED INSIDE THE FOLLWOING API-
        --FOLLOWING API WILL RETURN TWO RECORDS ONE IS FOR INTERNAL WITH VALID DATA AND ONE DUMMY RECORD FOR EXTERNAL
        --SALES_CREDIT_TYPE_ID=2 MEANS THE RECORD DENOTES INTERNAL
        --SALES_CREDIT_TYPE_ID BASED ON DFF(ATTRIBUTE1) ON RESOURCE_GROUP
        ins_sales_credit_record (p_line_scredit_tbl => x_line_scredit_tbl , p_header_id => p_header_id, p_line_id => order_details_info.line_id,p_terr_id => x_terr_id, o_return_status => x_return_status, o_return_message => x_return_message );
        -- ASSIGN THE OUTPUT VALUE TO THE TEMP RECORD
        FOR l_salesrep_tbl IN x_line_scredit_tbl.first .. x_line_scredit_tbl.last
        LOOP
          -- ASSIGN THE OUTPUT VALUE TO THE TEMP RECORD
          --SALES_CREDIT_TYPE_ID=2 DENOTES FOR INTERNAL
          IF (x_line_scredit_tbl(l_salesrep_tbl).sales_credit_type_id =2) THEN
            write_emf_log_low('Inside for loop Internal temp record creation ',p_header_id,p_line_id);
            --APPS.xxintg_ont_wf_log_proc (p_header_id||'second Inside for loop l_salesrep_cnt'||p_line_id||'-'||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
            l_line_scredit_tbl_temp (2)             := oe_order_pub.g_miss_line_scredit_rec;
            l_line_scredit_tbl_temp (2).header_id   := x_line_scredit_tbl(l_salesrep_tbl).header_id;
            l_line_scredit_tbl_temp (2).line_id     := x_line_scredit_tbl(l_salesrep_tbl).line_id;
            l_line_scredit_tbl_temp (2).salesrep_id := x_line_scredit_tbl(l_salesrep_tbl).salesrep_id;
            --Assigning group id
            l_line_scredit_tbl_temp (2).sales_group_id       := x_line_scredit_tbl(l_salesrep_tbl).sales_group_id;
            l_line_scredit_tbl_temp (2).attribute2           := x_line_scredit_tbl(l_salesrep_tbl).attribute2;
            l_line_scredit_tbl_temp (2).attribute1           := x_line_scredit_tbl(l_salesrep_tbl).attribute1;
            l_line_scredit_tbl_temp (2).attribute4           := x_line_scredit_tbl(l_salesrep_tbl).attribute4;
            l_line_scredit_tbl_temp (2).operation            := x_line_scredit_tbl(l_salesrep_tbl).operation;
            l_line_scredit_tbl_temp (2).sales_credit_type_id := x_line_scredit_tbl(l_salesrep_tbl).sales_credit_type_id;
            l_line_scredit_tbl_temp (2).sales_credit_id      := x_line_scredit_tbl(l_salesrep_tbl).sales_credit_id;
            l_line_scredit_tbl_temp (2).percent              := x_line_scredit_tbl(l_salesrep_tbl).percent;
          END IF;
        END LOOP;
        -- Call procudere to fetch and insert Salesrep at sales credit from at Order Header Level
        write_emf_log_low('Sales Rep Id for INT');
        write_emf_log_low('Sales Rep Id for INT:'||l_line_scredit_tbl_temp (1).salesrep_id);
        write_emf_log_low('Sales Rep Type for INT:'||l_line_scredit_tbl_temp (1).attribute4);
        write_emf_log_low('Sales Rep Id for EXT');
        write_emf_log_low('Sales Rep Id for EXT'||l_line_scredit_tbl_temp (2).salesrep_id);
        write_emf_log_low('Sales Rep Type for EXT'||l_line_scredit_tbl_temp (2).attribute4);
      END IF;
      -------------------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------------------
      IF x_return_status = 'Success' THEN
        write_emf_log_low('Inside x_return_status = Success',p_header_id,order_details_info.line_id,x_terr_id );
        --oe_msg_pub.initialize;
        oe_order_pub.process_order (p_api_version_number => l_api_version_number ,p_org_id => fnd_global.org_id , p_init_msg_list => fnd_api.g_false , p_line_scredit_tbl => l_line_scredit_tbl_temp , x_header_rec => l_header_rec_out , x_header_val_rec => l_header_val_rec_out , x_header_adj_tbl => l_header_adj_tbl_out , x_header_adj_val_tbl => l_header_adj_val_tbl_out , x_header_price_att_tbl => l_header_price_att_tbl_out , x_header_adj_att_tbl => l_header_adj_att_tbl_out , x_header_adj_assoc_tbl => l_header_adj_assoc_tbl_out , x_header_scredit_tbl => l_header_scredit_tbl_out , x_header_scredit_val_tbl => l_header_scredit_val_tbl_out , x_line_tbl => l_line_tbl_out , x_line_val_tbl => l_line_val_tbl_out , x_line_adj_tbl => l_line_adj_tbl_out , x_line_adj_val_tbl => l_line_adj_val_tbl_out , x_line_price_att_tbl => l_line_price_att_tbl_out , x_line_adj_att_tbl => l_line_adj_att_tbl_out , x_line_adj_assoc_tbl => l_line_adj_assoc_tbl_out , x_line_scredit_tbl => l_line_scredit_tbl_out ,
        x_line_scredit_val_tbl => l_line_scredit_val_tbl_out , x_lot_serial_tbl => l_lot_serial_tbl_out , x_lot_serial_val_tbl => l_lot_serial_val_tbl_out , x_action_request_tbl => l_action_request_tbl_out , x_return_status => x_return_status , x_msg_count => l_msg_count , x_msg_data => l_msg_data );
        /*****************CHECK RETURN STATUS***********************************/
        /*****************DISPLAY ERROR MSGS*************************************/
        write_emf_log_low('After oe_order_pub.process_order',p_header_id,order_details_info.line_id );
        IF l_msg_count = 0 AND x_return_status = 'S' THEN
          o_status    := 'Success';
          write_emf_log_low('Inside l_msg_count = 0 AND x_return_status = S',p_header_id,order_details_info.line_id );
        ELSE
          write_emf_log_low('Inside l_msg_count = 0 AND x_return_status = S else part',p_header_id,order_details_info.line_id );
          FOR i IN 1 .. l_msg_count
          LOOP
            oe_msg_pub.get (p_msg_index => i , p_encoded => fnd_api.g_false , p_data => l_msg_data , p_msg_index_out => l_msg_index );
          END LOOP;
          o_status    := 'Error';
          o_errormess := l_msg_data;
          write_emf_log_low('o_errormess ' || o_errormess,p_header_id,order_details_info.line_id );
        END IF;
      ELSE
        o_status    := 'Error';
        o_errormess := x_return_message;
      END IF;
    END IF;
    --Record processed successfully..fetch next record'
  END LOOP;
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 12';
  --Reset the global variable
  g_program_source := NULL;
  write_emf_log_low('Returning from xx_oe_assign_salesrep ' ,p_header_id);
EXCEPTION
WHEN OTHERS THEN
  o_status     := 'Error';
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep 13';
  o_errormess  := 'Message: Further processing stopped since unexpected error occured ' || p_header_id || ' - ' || sqlerrm;
  write_emf_log_low(' Exception xx_oe_assign_salesrep ' || sqlerrm,p_header_id );
END xx_oe_assign_salesrep;
FUNCTION validate_order_eligibility(
    p_header_id IN NUMBER,
    p_line_id   IN NUMBER DEFAULT NULL)
  RETURN VARCHAR2
IS
  x_eligibility VARCHAR2 (1) := 'N';
  x_count       NUMBER       := 0;
BEGIN
  write_emf_log_low('Entering validate_order_eligibility ' ,p_header_id );
  SELECT COUNT (1)
  INTO x_count
  FROM oe_order_headers ooh ,
    oe_order_lines ool
  WHERE ooh.header_id           = p_header_id
  AND ooh.header_id             = ool.header_id
  AND ool.line_id               = NVL(p_line_id,ool.line_id)
  AND ooh.flow_status_code NOT IN
    (SELECT upper (xepp.parameter_value)
    FROM xx_emf_process_setup xeps ,
      xx_emf_process_parameters xepp
    WHERE xeps.process_name = g_object_name
    AND xeps.process_id     = xepp.process_id
    AND upper (xepp.parameter_name) LIKE 'ORDER_HEADER_STATUS%'
    AND NVL (xepp.enabled_flag, 'Y') = 'Y'
    )
  AND NOT EXISTS
    (SELECT 1
    FROM xx_emf_process_setup xeps ,
      xx_emf_process_parameters xepp
    WHERE xeps.process_name = g_object_name
    AND xeps.process_id     = xepp.process_id
    AND upper (xepp.parameter_name) LIKE 'ORDER_LINE_STATUS%'
    AND NVL (xepp.enabled_flag, 'Y') = 'Y'
    AND ool.flow_status_code         = upper (xepp.parameter_value)
    )
    /*AND NOT EXISTS
    (SELECT 1
    FROM oe_sales_credits osc
    WHERE header_id = ooh.header_id
    AND line_id     = ool.line_id
    )
    AND OOL.SALESREP_ID IN
    (SELECT SALESREP_ID FROM JTF_RS_SALESREPS WHERE name = 'No Sales Rep'
    )
    */
    ;
  IF x_count       = 0 THEN
    x_eligibility := 'N';
    write_emf_log_low('x_eligibility = N ' ,p_header_id );
  ELSE
    x_eligibility := 'Y';
    write_emf_log_low('x_eligibility = Y ' ,p_header_id );
  END IF;
  RETURN x_eligibility;
EXCEPTION
WHEN OTHERS THEN
  write_emf_log_high(' Exception  validate_order_eligibility ' || sqlerrm ,p_header_id );
  x_eligibility := 'N';
  RETURN x_eligibility;
END validate_order_eligibility;
FUNCTION check_sr_exits(
    p_header_id IN NUMBER,
    p_line_id   IN NUMBER DEFAULT NULL)
  RETURN VARCHAR2
IS
  x_sr_exits VARCHAR2 (1) := 'N';
  x_count    NUMBER       := 0;
BEGIN
  write_emf_log_low('Entering check_sr_exits ' ,p_header_id );
  SELECT COUNT (1)
  INTO x_count
  FROM oe_order_headers ooh
  WHERE ooh.header_id  = p_header_id
  AND ooh.salesrep_id IS NOT NULL;
  IF x_count           = 0 THEN
    x_sr_exits        := 'N';
    write_emf_log_low('x_sr_exits = N ' ,p_header_id );
  ELSE
    x_sr_exits := 'Y';
    write_emf_log_low('x_sr_exits = Y ' ,p_header_id );
  END IF;
  RETURN x_sr_exits;
EXCEPTION
WHEN OTHERS THEN
  write_emf_log_high(' Exception  check_sr_exits ' || sqlerrm ,p_header_id );
  x_sr_exits := 'N';
  RETURN x_sr_exits;
END check_sr_exits;
FUNCTION xx_catch_business_event(
    p_subscription_guid IN raw ,
    p_event             IN OUT nocopy wf_event_t )
  RETURN VARCHAR2
IS
  -------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 18-APR-2012
  Filename       :
  Description    : This function is used in the subscription of seeded business event oracle.apps.ont.oi.xml_int.status
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  18-Apr-2012   1.0       Raquib Iqbal        Initial development.
  */
  --------------------------------------------------------------------------------
  x_order_source_id NUMBER;
  x_sold_to_org_id  NUMBER;
  x_header_id       NUMBER;
  x_org_id          NUMBER;
  x_order_type_id   NUMBER;
  x_line_ids        VARCHAR2 (4000);
  x_order_number    NUMBER;
  x_status          VARCHAR2 (50);
  x_errormess       VARCHAR2 (2000);
  x_error_code      NUMBER       := xx_emf_cn_pkg.cn_success;
  x_validate        VARCHAR2 (1) := NULL;
BEGIN
  x_error_code := xx_emf_pkg.set_env (p_process_name => g_object_name);
  x_header_id  := p_event.getvalueforparameter ('HEADER_ID');
  write_emf_log_high('Entering  xx_catch_business_event ' ,x_header_id );
  BEGIN
    SELECT xx_oe_salesrep_assign_ext_pkg.validate_order_eligibility (x_header_id )
    INTO x_validate
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    write_emf_log_low( 'Exception validate_order_eligibility...' || sqlerrm ,x_header_id);
    x_validate := 'N';
  END;
  write_emf_log_low( 'x_validate : ' || x_validate ,x_header_id);
  IF x_validate = 'N' THEN
    write_emf_log_low( 'Inside x_validate   = N ' ,x_header_id);
    RETURN 'Error';
    --p_errbuf := 'Program can not be called since Sales Credits already exists';
  ELSE
    write_emf_log_low( 'Inside x_validate else ' ,x_header_id);
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_catch_business_event 1';
    --Reset Program source variable
    g_program_source := 'B';
    --Calling Salesrep assignment procedure
    write_emf_log_low('Calling  xx_oe_assign_salesrep ' ,x_header_id );
    xx_oe_assign_salesrep (o_status => x_status , o_errormess => x_errormess , p_header_id => x_header_id );
    -- logging
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_catch_business_event 2';
    write_emf_log_low('After calling  xx_oe_assign_salesrep ' ,x_header_id,NULL,NULL,NULL,NULL,NULL,NULL,x_status,x_errormess );
    IF x_status = 'Success' THEN
      RETURN 'Success';
    ELSE
      RETURN 'Error';
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  -- logging
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_catch_business_event 3';
  write_emf_log_low(' Exception xx_catch_business_event  ' || sqlerrm ,x_header_id );
  RETURN 'Error';
END xx_catch_business_event;
FUNCTION xx_oe_call_salesrep_proc(
    p_header_id NUMBER)
  RETURN VARCHAR2
IS
  x_error_code NUMBER       := xx_emf_cn_pkg.cn_success;
  x_validate   VARCHAR2 (1) := NULL;
BEGIN
  x_error_code := xx_emf_pkg.set_env (p_process_name => 'XX_OE_ASSIGN_SALESREP');
  write_emf_log_high( 'Inside xx_oe_call_salesrep_proc...',p_header_id);
  BEGIN
    SELECT xx_oe_salesrep_assign_ext_pkg.validate_order_eligibility (p_header_id )
    INTO x_validate
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    write_emf_log_low( 'Exception validate_order_eligibility...' || sqlerrm ,p_header_id);
    x_validate := 'N';
  END;
  write_emf_log_low( 'x_validate : ' || x_validate ,p_header_id);
  g_prog_stage   := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 2';
  IF x_validate   = 'N' THEN
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 3';
    fnd_message.set_name ('XXINTG', 'XXOE_SALESREP_EXISTS');
    write_emf_log_low( 'Inside x_validate   = N ' ,p_header_id);
    RETURN fnd_message.get;
    --p_errbuf := 'Program can not be called since Sales Credits already exists';
  ELSE
    write_emf_log_low( 'Inside x_validate else ' ,p_header_id);
    RETURN xx_oe_call_salesrep_auto_proc(p_header_id);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  write_emf_log_high( 'Exception xx_oe_call_salesrep_proc...' || sqlerrm ,p_header_id);
END xx_oe_call_salesrep_proc;
FUNCTION xx_oe_call_salesrep_auto_proc(
    p_header_id NUMBER)
  RETURN VARCHAR2
IS
  -------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 18-APR-2012
  Filename       :
  Description    : This function is used in the menu option
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  18-Apr-2012   1.0       Raquib Iqbal        Initial development.
  */
  --------------------------------------------------------------------------------
  pragma autonomous_transaction;
  x_errbuf         VARCHAR2 (200);
  x_retcode        VARCHAR2 (30);
  x_error_status   VARCHAR2 (2000) := NULL;
  x_success_status VARCHAR2 (2000) := NULL;
  x_validate       VARCHAR2 (1)    := NULL;
  x_status         VARCHAR2 (50);
  x_errormess      VARCHAR2 (2000);
  x_error_code     NUMBER := xx_emf_cn_pkg.cn_success;
BEGIN
  write_emf_log_high( 'Inside xx_oe_call_salesrep_auto_proc...',p_header_id);
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 1';
  --Reset Program source variable
  g_program_source := NVL (g_program_source, 'P');
  g_prog_stage     := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 4';
  --Call the original procedure
  xx_oe_assign_salesrep (o_status => x_status , o_errormess => x_errormess , p_header_id => p_header_id );
  write_emf_log_low( 'After  xx_oe_assign_salesrep ' ,p_header_id);
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 5';
  -- logging table will change
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 6';
  IF x_status   = 'Success' THEN
    write_emf_log_low( 'Inside  x_status = Success ' ,p_header_id);
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 7';
    fnd_message.set_name ('XXINTG', 'XXOE_SALESREP_SUCCESS');
    COMMIT;
    write_emf_log_low( 'After  commit ' ,p_header_id);
    -- x_errbuf := 'Salesrep populated successfully for all lines in the order. Please requery to view Salesrep';
  ELSE
    write_emf_log_low( 'Inside  x_status = Success else part ' ,p_header_id);
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 8';
    fnd_message.set_name ('XXINTG', 'XXOE_SALESREP_FAIL');
    fnd_message.set_token ('BATCH', x_errormess);
    ROLLBACK;
  END IF;
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 9';
  write_emf_log_high( 'Exiting xx_oe_call_salesrep_auto_proc...',p_header_id);
  RETURN fnd_message.get;
EXCEPTION
WHEN OTHERS THEN
  write_emf_log_high( 'Inside Exception xx_oe_call_salesrep_auto_proc...' || sqlerrm ,p_header_id);
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 10';
  fnd_message.set_name ('XXINTG', 'XXOE_SALESREP_FAIL');
  fnd_message.set_token ('BATCH', 'Unexpected Error');
  RETURN fnd_message.get;
END xx_oe_call_salesrep_auto_proc;
PROCEDURE xx_oe_populate_salesrep_bulk(
    o_errbuf OUT VARCHAR2 ,
    o_retcode OUT VARCHAR2 ,
    p_order_from      IN NUMBER ,
    p_order_to        IN NUMBER ,
    p_order_type      IN VARCHAR2 ,
    p_order_status    IN VARCHAR2 ,
    p_order_date_from IN VARCHAR2 ,
    p_order_date_to   IN VARCHAR2 )
IS
  -------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 18-APR-2012
  Filename       :
  Description    : This function is used  for enahanced concurrent program
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  18-Apr-2012   1.0       Raquib Iqbal        Initial development.
  */
  --------------------------------------------------------------------------------
  CURSOR c_orders ( cp_order_from NUMBER , cp_order_to NUMBER , cp_order_type VARCHAR2 , cp_flow_status_code VARCHAR2 , cp_order_date_from VARCHAR2 , cp_order_date_to VARCHAR2 )
  IS
    SELECT DISTINCT ooh.header_id
    FROM oe_order_headers ooh ,
      oe_transaction_types_tl ott ,
      oe_order_lines ool
    WHERE ooh.header_id         = ool.header_id
    AND ott.language            = userenv ('LANG')
    AND ool.flow_status_code    = NVL (cp_flow_status_code, ool.flow_status_code)
    AND ott.transaction_type_id = ooh.order_type_id
    AND ooh.order_number BETWEEN NVL (cp_order_from , ooh.order_number ) AND NVL (cp_order_to , ooh.order_number )
    AND ott.name                  = NVL (cp_order_type, ott.name)
    AND ooh.flow_status_code NOT IN
      (SELECT upper (xepp.parameter_value)
      FROM xx_emf_process_setup xeps ,
        xx_emf_process_parameters xepp
      WHERE xeps.process_name = g_object_name
      AND xeps.process_id     = xepp.process_id
      AND upper (xepp.parameter_name) LIKE 'CONC_PROG_HEADER_STATUS%'
      AND NVL (xepp.enabled_flag, 'Y') = 'Y'
      )
  AND TRUNC(ooh.ordered_date) BETWEEN NVL (fnd_date.canonical_to_date (cp_order_date_from) , TRUNC(ooh.ordered_date) ) AND NVL (fnd_date.canonical_to_date (cp_order_date_to) , TRUNC(ooh.ordered_date ))
  AND xx_oe_salesrep_assign_ext_pkg.validate_order_eligibility (ooh.header_id ) = 'Y';
  x_status        VARCHAR2 (50);
  x_errormess     VARCHAR2 (2000);
  x_return_status BOOLEAN := true;
  x_error_code    NUMBER  := xx_emf_cn_pkg.cn_success;
BEGIN
  x_error_code := xx_emf_pkg.set_env;
  write_emf_log_high( 'Entering xx_oe_populate_salesrep_bulk...');
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep_bulk 1';
  --Reset global variable
  write_emf_log_high( 'parameter xx_oe_populate_salesrep_bulk...',NULL,NULL,p_order_from , p_order_to , p_order_type , p_order_status , p_order_date_from , p_order_date_to );
  FOR rec_index IN c_orders (p_order_from , p_order_to , p_order_type , p_order_status , p_order_date_from , p_order_date_to )
  LOOP
    -- logging
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep_bulk 2';
    --Call Salesrep procedure
    write_emf_log_high( 'Inside loop before xx_oe_assign_salesrep...',rec_index.header_id);
    xx_oe_assign_salesrep (o_status => x_status , o_errormess => x_errormess , p_header_id => rec_index.header_id );
    write_emf_log_high( 'After xx_oe_assign_salesrep...',rec_index.header_id,NULL,x_status);
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 5';
    -- logging table will change
    g_prog_stage      := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep 6';
    IF x_status        = 'Fail' AND x_return_status THEN
      x_return_status := false;
      xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low ,p_category => 'ORD-ERROR' ,p_error_text => 'Error :' || x_errormess ,p_record_identifier_1 => rec_index.header_id );
    END IF;
    -- logging
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep_bulk 3';
  END LOOP;
  IF NOT x_return_status THEN
    o_retcode := 1;
  END IF;
  write_emf_log_high( 'After loop...');
  xx_emf_pkg.create_report;
  xx_common_process_email.notify_user(fnd_global.conc_request_id);
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep_bulk 4';
EXCEPTION
WHEN OTHERS THEN
  -- Logging
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_populate_salesrep_bulk 5';
  o_retcode    := 2;
  write_emf_log_high( 'Exception  xx_oe_populate_salesrep_bulk...' ||sqlerrm);
END xx_oe_populate_salesrep_bulk;
PROCEDURE xx_oe_assign_salesrep_line(
    p_header_id IN NUMBER,
    p_line_id   IN NUMBER,
    o_status OUT VARCHAR2 ,
    o_errormess OUT VARCHAR2)
IS
  -------------------------------------------------------------------------------
  /*
  Created By     : Vishal Rathore
  Creation Date  : 1-Aug-2013
  Filename       :
  Description    : This function is used to populate SalesRep in every order lines
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  1-Aug-2013   1.0       Vishal Rathore        Initial development.
  */
  --------------------------------------------------------------------------------
  x_header_id  NUMBER;
  x_line_id    NUMBER;
  x_status     VARCHAR2 (50);
  x_errormess  VARCHAR2 (2000);
  x_error_code NUMBER       := xx_emf_cn_pkg.cn_success;
  x_validate   VARCHAR2 (1) := NULL;
BEGIN
  x_error_code := xx_emf_pkg.set_env (p_process_name => g_object_name);
  x_header_id  := p_header_id;
  x_line_id    := p_line_id;
  write_emf_log_high('Entering  xx_oe_assign_salesrep_line ' ,x_header_id,x_line_id );
  BEGIN
    SELECT xx_oe_salesrep_assign_ext_pkg.validate_order_eligibility (x_header_id,x_line_id )
    INTO x_validate
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    write_emf_log_low( 'Exception validate_order_eligibility...' || sqlerrm ,x_header_id);
    x_validate := 'N';
  END;
  write_emf_log_low( 'x_validate : ' || x_validate ,x_header_id,x_line_id);
  IF x_validate = 'N' THEN
    write_emf_log_low( 'Inside x_validate   = N ' ,x_header_id);
    o_status    := 'Error';
    o_errormess := 'Program can not be called since Sales Credits already exists';
  ELSE
    write_emf_log_low( 'Inside x_validate else ' ,x_header_id,x_line_id);
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep_line 1';
    --Reset Program source variable
    g_program_source := 'B';
    --Calling Salesrep assignment procedure
    write_emf_log_low('Calling  xx_oe_assign_salesrep ' ,x_header_id,x_line_id );
    xx_oe_assign_salesrep (o_status => x_status , o_errormess => x_errormess , p_header_id => x_header_id,p_line_id => x_line_id );
    -- logging
    g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep_line 2';
    write_emf_log_low('After calling  xx_oe_assign_salesrep_line ' ,x_header_id,x_line_id,NULL,NULL,NULL,NULL,NULL,x_status,x_errormess );
    IF x_status = 'Success' THEN
      o_status := 'Success';
    ELSE
      o_status := 'Error';
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  -- logging
  g_prog_stage := 'xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep_line 3';
  write_emf_log_low(' Exception xx_catch_business_event  ' || sqlerrm ,x_header_id ,x_line_id);
  o_status := 'Error';
END xx_oe_assign_salesrep_line;
END xx_oe_salesrep_assign_ext_pkg;
/
