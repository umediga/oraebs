DROP FUNCTION APPS.XX_OE_GET_SALES_REP_DETAIL;

CREATE OR REPLACE FUNCTION APPS.xx_oe_get_sales_rep_detail(p_inventory_item_id number,p_customer_id number,p_org_id number,p_ship_to_org_id number)
return varchar2
IS
PRAGMA AUTONOMOUS_TRANSACTION;
CURSOR c_get_customer_detail
IS
    SELECT hps.party_id ,
      hp.party_name ,
      hl.country ,
      hps.party_site_id,
      mc.segment4,
      mc.segment10,
      mc.segment9,
      account_number,
      hl.county,
      hl.postal_code,
      hl.province,
      hl.state,
      msi.attribute1
    FROM  hz_cust_site_uses hcsu ,
      hz_cust_acct_sites hcas ,
      hz_party_sites hps ,
      hz_locations hl ,
      hz_parties hp,
      mtl_category_sets mcs,
      mtl_item_categories mic,
      mtl_categories_b mc,
      hz_cust_accounts hca,
      mtl_system_items_b msi
    WHERE  hcsu.site_use_id       = p_ship_to_org_id
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
    AND mcs.category_set_name              = xx_emf_pkg.get_paramater_value ('XX_OE_ASSIGN_SALESREP', 'CATEGORY_NAME' )
    AND mcs.category_set_id                = mic.category_set_id
    AND mic.inventory_item_id              = p_inventory_item_id
    AND mic.organization_id                = fnd_profile.value ('MSD_MASTER_ORG')
    AND mic.inventory_item_id              = msi.inventory_item_id
    AND mic.organization_id                = msi.organization_id
    AND mc.category_id                     = mic.category_id
    AND mc.enabled_flag                    = 'Y'
    AND NVL (mc.disable_date, sysdate + 1) > sysdate
    AND hca.cust_account_id                = p_customer_id;

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

  x_line_scredit_tbl oe_order_pub.line_scredit_tbl_type;
  x_msg_string      VARCHAR2(4000) := NULL;

  l_rep_name        VARCHAR2(50);
  l_comm_flag       VARCHAR2 (10);
  l_return_value    VARCHAR2(240);

BEGIN

DBMS_OUTPUT.PUT_LINE ('START');
x_msg_string := Null;

BEGIN
mo_global.set_policy_context('S',p_org_id);
END;

FOR order_details_info IN c_get_customer_detail
LOOP

xx_oe_pop_salesrep_pkg.xx_find_territories (p_country => order_details_info.country
                      , p_customer_name_range => order_details_info.party_name
                      , p_customer_id => order_details_info.party_id
                      , p_site_number => order_details_info.party_site_id
                      , p_division => order_details_info.segment4
                      , p_sub_division => order_details_info.segment10
                      , p_dcode => order_details_info.segment9
                      , p_surgeon_name => Null ---order_details_info.attribute8
                      , p_cust_account => order_details_info.account_number
                      , p_county => order_details_info.county
                      , p_postal_code => order_details_info.postal_code
                      , p_province => order_details_info.province
                      , p_state => order_details_info.state
                      , o_terr_id => x_terr_id
                      , o_status => x_territory_status
                      , o_error_message => x_error_message );

l_comm_flag := order_details_info.attribute1;

END LOOP;

IF p_inventory_item_id IS NULL OR p_customer_id IS NULL OR p_ship_to_org_id IS NULL
THEN
 l_return_value := 'Either Item OR Customer# OR Ship-To Location Field is Null, Please Verify The Same';
 ROLLBACK;
 return l_return_value;

ELSIF p_inventory_item_id IS NOT NULL AND p_customer_id IS NOT NULL AND p_ship_to_org_id IS NOT NULL
THEN
BEGIN
xx_oe_pop_salesrep_pkg.xx_ins_sales_credit_record (p_line_scredit_tbl => x_line_scredit_tbl ,
                            p_org_id => p_org_id,
                            o_return_status => x_return_status,
                            o_return_message => x_return_message );

       x_msg_string := 'Salesrep Name                       | Territory Name ';
       x_msg_string := x_msg_string ||CHR(10)||'-----------------------------------------------------------';

IF x_line_scredit_tbl.count = 0
Then
      l_return_value := 'NO SALES CREDIT';
      ROLLBACK;
      return l_return_value;
end if;

FOR l_salesrep_cnt  IN x_line_scredit_tbl.first .. x_line_scredit_tbl.last
LOOP

      l_rep_name := Null;
      BEGIN
        SELECT jrdv.resource_name
          INTO l_rep_name
          FROM jtf_rs_salesreps rs
              ,jtf_rs_defresources_v jrdv
         WHERE rs.salesrep_id =  x_line_scredit_tbl(l_salesrep_cnt).salesrep_id
           AND rs.resource_id = jrdv.resource_id
           AND rownum < 2;
      EXCEPTION
      WHEN OTHERS THEN
        l_rep_name := Null;
      END;
      l_return_value := l_rep_name;
      x_msg_string := x_msg_string ||CHR(10)||RPAD(l_rep_name,35,'*')||' | '||x_line_scredit_tbl(l_salesrep_cnt).attribute1;
     --- x_msg_string := x_msg_string ||CHR(10)||l_rep_name||'                                   | '||x_line_scredit_tbl(l_salesrep_cnt).percent;

END LOOP;
      DBMS_OUTPUT.PUT_LINE (x_msg_string);
EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE ('Error '||SQLERRM);
   ROLLBACK;
   return l_return_value;
END;
--ELSE
  --  x_msg_string := x_msg_string ||CHR(10)||'NO SALES CREDIT';
END IF;
    ROLLBACK;
    return l_return_value;

EXCEPTION
WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE ('Main In Error '||SQLERRM);
   ROLLBACK;
   return x_msg_string;
END xx_oe_get_sales_rep_detail;
/
