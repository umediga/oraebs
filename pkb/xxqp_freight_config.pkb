DROP PACKAGE BODY APPS.XXQP_FREIGHT_CONFIG;

CREATE OR REPLACE PACKAGE BODY APPS."XXQP_FREIGHT_CONFIG" AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team   
Creation Date : 04-July-2013
File Name     : XXQPFRCONFIG122.pkb
Description   : This script creates the package body of the package XXQP_FREIGHT_CONFIG
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
04-July-2013  Narendra Yadav        Initial Draft.
08-Aug-2013   Aabhas Bhargava       Changes as per feedback from Sri 
16-Aug-2013   Aabhas Bhargava       Changes as per modified FRS (added 2 more functions)
26-Sep-2013   Narendra Yadav        Changes as per modified FRS (added 3 more functions)
29-Oct-2013   Narendra Yadav        Changes into XXINTG_CONFIG_FRCOST as per New FS
29-Jan-2014   Vishal Rathore        Changes in XXINTG_CONFIG_FRCOST
12-May-2014   Vishal Rathore        Case # 006417
16-June-2014  Krishna Ayalavarapu   Added few addl functions to setup pricing attributes for case #7608

*/
----------------------------------------------------------------------

FUNCTION HEADER_PRICE_LIST(P_HEADER_ID number) return number  is
l_price_list_id number;
begin
   
   select PRICE_LIST_ID into l_price_list_id from oe_order_headers_all where header_id=p_header_id;
    return nvl(l_price_list_id,393050); -- ILS LIST PRICE (Shell)
  exception when others then
      return 393050; -- ILS LIST PRICE (Shell)
      
end;
FUNCTION order_source(p_order_source_id number) return varchar2 is
l_source varchar2(200);
begin
    select name into l_source from oe_order_sources where order_source_id=p_order_source_id;
    return l_source;
    exception 
    when others then
    return null;  
end;


FUNCTION DAY_OF_THE_WEEK(p_date date,p_param varchar2) return varchar2 is
l_day varchar2(100);
begin
select ltrim(rtrim(upper(to_char(p_date,p_param )))) into l_day from dual;
return l_day;
end;

FUNCTION DAY_OF_THE_WEEK_TWO_DATES(p_date1 date,p_date2 date,p_param varchar2) return varchar2 IS
l_day varchar2(100);
l_date date;
begin
  l_date :=nvl(p_date1,p_date2);
select ltrim(rtrim(upper(to_char(l_date,p_param )))) into l_day from dual;
return l_day;
end;

FUNCTION XXINTG_CONFIG_CONTYPE(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
xx_con_type VARCHAR2(200) := null;
xx_list_type VARCHAR2(100) := null;
CURSOR xx_adj_recs IS select * from oe_price_adjustments opa where xx_line_record.header_id = opa.header_id;
BEGIN
    IF (xx_line_record.line_id is not null) THEN
        select qlh.list_type_code,qlh.attribute7
        into xx_list_type,xx_con_type
        from qp_list_headers qlh
        where 1=1
        AND xx_line_record.price_list_id = qlh.list_header_id;
        -- Check if Attribute7 is Null for Price List, if so fetch details for Modifiers
        IF xx_con_type IS NULL THEN
            FOR i IN xx_adj_recs LOOP
                select qlh1.attribute7
                into xx_con_type
                from qp_list_headers qlh1
                where 1=1
                AND i.list_header_id = qlh1.list_header_id
                AND qlh1.automatic_flag = 'Y'; -- Automatic Flag should be Y

                IF (xx_con_type is not null) THEN
                    RETURN xx_con_type;
                END IF;
            END LOOP;
            RETURN null;
        ELSE
            RETURN xx_con_type;
        END IF;
    ELSE
         RETURN null;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
FUNCTION XXINTG_CONFIG_CONTYPE_NAME(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
xx_con_type_name VARCHAR2(200) := null;
xx_list_type VARCHAR2(100) := null;
CURSOR xx_adj_recs IS select * from oe_price_adjustments opa where xx_line_record.header_id = opa.header_id;
BEGIN
    IF (xx_line_record.line_id is not null) THEN
        select qlh.list_type_code,qlh.attribute3
        into xx_list_type,xx_con_type_name
        from qp_list_headers qlh
        where 1=1
        AND xx_line_record.price_list_id = qlh.list_header_id;
        -- Check if Attribute3 is Null for Price List, if so fetch details for Modifiers
        IF xx_con_type_name IS NULL  THEN
            FOR i IN xx_adj_recs LOOP
                select qlh1.attribute3
                into xx_con_type_name
                from qp_list_headers qlh1
                where 1=1
                AND i.list_header_id = qlh1.list_header_id
                AND qlh1.automatic_flag = 'Y'; -- Automatic Flag should be Y 

                IF (xx_con_type_name is not null) THEN
                    RETURN xx_con_type_name;
                END IF;
            END LOOP;
            RETURN null;
        ELSE
            RETURN xx_con_type_name;
        END IF;
    ELSE
         RETURN null;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
FUNCTION XXINTG_CONFIG_DIV(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER IS
xx_total_amt NUMBER := 0;
xx_division  VARCHAR2(100);
BEGIN
    -- Derive Divison 
    SELECT MCK.SEGMENT4 
    into xx_division
    from 
        mtl_item_categories mic,
        MTL_CATEGORIES_KFV MCK,
        MTL_CATEGORY_SETS MCS
    where mic.inventory_item_id = xx_line_record.inventory_item_id
    AND mic.category_set_id = mcs.category_set_id
    AND MCS.CATEGORY_SET_NAME = 'Sales and Marketing'
    AND MIC.CATEGORY_ID = MCK.CATEGORY_ID
    AND mic.organization_id = xx_line_record.ship_from_org_id;
         
    -- Total Amount needs to be returned 
    SELECT SUM(oola.ordered_quantity*oola.unit_selling_price)
    INTO xx_total_amt
    FROM oe_order_lines oola,
         mtl_item_categories mic,
         mtl_categories_kfv mck,
         mtl_category_sets mcs
    WHERE  oola.header_id = xx_line_record.header_id
          AND oola.inventory_item_id = mic.inventory_item_id
          AND oola.ship_from_org_id = mic.organization_id
          AND mic.category_set_id = mcs.category_set_id
          AND mcs.category_set_name = 'Sales and Marketing'
          AND mic.category_id = mck.category_id
          AND mck.segment4 = xx_division; 
    RETURN NVL(xx_total_amt,0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
FUNCTION XXINTG_CONFIG_PROSHIP(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
l_cnt NUMBER :=0;
BEGIN
  IF (xx_line_record.header_id is not null) THEN
    -- Check if any of the lines in the Sales Order has Context Shipping and Attribute2 set to Y 
    SELECT count(1)
    into l_cnt
    FROM oe_order_headers ooha
    WHERE xx_line_record.header_id = ooha.header_id
    and ooha.tp_context = 'Shipping'
    and ooha.tp_attribute2 = 'Y';
  ELSE
    RETURN null;
  END IF;
  
  IF l_cnt >= 1 THEN
    RETURN 'Y';
  ELSE
    -- Check if any of the items in the Order are part of the Proactive Item Lookup 
    SELECT count(flv.lookup_code)
    INTO l_cnt 
    FROM fnd_lookup_values flv
    WHERE flv.lookup_code in (select ordered_item from oe_order_lines where header_id = xx_line_record.header_id)
          AND flv.lookup_type like 'XX_OM_MANIFEST_PROACTIVE_ITEMS'
          AND flv.language = 'US';
    IF l_cnt >= 1 THEN
      RETURN 'Y';
    ELSE
      RETURN null;
    END IF;
  END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
/*FUNCTION XXINTG_CONFIG_FRCOST(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER IS
xx_net_frcost NUMBER := 0;
BEGIN
  SELECT SUM(NVL(wfc.attribute1,0))
  INTO xx_net_frcost
  FROM wsh_delivery_details wdd,
       wsh_delivery_assignments wda,
       wsh_freight_costs wfc
  WHERE 1=1
        AND xx_line_record.line_id = wdd.source_line_id
        AND xx_line_record.header_id = wdd.source_header_id
        AND wdd.delivery_detail_id = wda.delivery_detail_id
        AND wda.delivery_id = wfc.delivery_id
  GROUP BY wfc.delivery_id;
  RETURN xx_net_frcost;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;*/

FUNCTION XXINTG_CONFIG_FRCOST(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER IS
xx_net_frcost NUMBER := 0;
xx_total_shipped_quantity NUMBER := 0;
xx_delivery_id NUMBER := null;
xx_shipped_quantity NUMBER := 0;
xx_avg_frcost NUMBER := 0;
BEGIN
  begin
  -- Commented by Vishal on 29-Jan-2014
         /*SELECT wda.delivery_id,sum(wdd.shipped_quantity)
         INTO xx_delivery_id,xx_total_shipped_quantity
         FROM oe_order_lines oola,
                wsh_delivery_details wdd,
                wsh_delivery_assignments wda
         WHERE 1=1
                 AND oola.line_id = xx_line_record.line_id
                 AND oola.line_id = wdd.source_line_id
             AND wdd.source_code = 'OE'
             AND wdd.delivery_detail_id = wda.delivery_detail_id
         GROUP BY wda.delivery_id;*/
       SELECT wdaa.delivery_id,
        SUM(wdda.shipped_quantity)
        INTO xx_delivery_id,
          xx_total_shipped_quantity
        FROM wsh_delivery_details wdd,
          wsh_delivery_assignments wda,
          wsh_delivery_details wdda,
          wsh_delivery_assignments wdaa,
          oe_order_lines oola
        WHERE 1                     =1
        AND oola.line_id            = wdd.source_line_id
        AND wdd.source_line_id      = xx_line_record.line_id
        AND wdda.source_code        = 'OE'
        AND wdd.source_code         = 'OE'
        AND wdd.delivery_detail_id  = wda.delivery_detail_id
        AND wda.delivery_id         = wdaa.delivery_id
        and WDAA.DELIVERY_DETAIL_ID = WDDA.DELIVERY_DETAIL_ID
        GROUP BY wdaa.delivery_id;       
  EXCEPTION
      WHEN OTHERS THEN
           RETURN 0;
  END;
    SELECT NVL(wdd.shipped_quantity,0)
    INTO xx_shipped_quantity
    FROM wsh_delivery_details wdd
    WHERE 1=1
    AND wdd.source_line_id = xx_line_record.line_id;
      
    SELECT SUM(NVL(wfc.attribute1,0))
    INTO xx_net_frcost
    FROM wsh_freight_costs wfc
    WHERE 1=1
            AND wfc.delivery_id = xx_delivery_id
  GROUP BY wfc.delivery_id;
    
  xx_avg_frcost := (xx_net_frcost/xx_total_shipped_quantity);
  RETURN (xx_avg_frcost * xx_shipped_quantity);
  
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;

FUNCTION XXINTG_CONFIG_CONT_PRC(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
xx_temp VARCHAR2(200) := null;
CURSOR xx_adj_recs IS select * from oe_price_adjustments opa where xx_line_record.header_id = opa.header_id;
BEGIN
  xx_temp := XXINTG_CONFIG_CONTYPE(xx_line_record);
  IF (xx_temp is not null) THEN
    RETURN 'Y';
  ELSE
     FOR i IN xx_adj_recs LOOP
        IF (i.automatic_flag = 'Y') THEN
            RETURN 'Y';
        END IF;
     END LOOP;
     RETURN null;
  END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
FUNCTION XXINTG_CONFIG_HAZAR(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
xx_hz_flag VARCHAR2(200) := null;
BEGIN
  SELECT msi.hazardous_material_flag
  INTO xx_hz_flag
  FROM mtl_system_items msi
  WHERE 1=1
        AND xx_line_record.inventory_item_id = msi.inventory_item_id
        AND xx_line_record.ship_from_org_id = msi.organization_id;
  IF (xx_hz_flag = 'Y') THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
-- Changes as per New FRS (Addition of 2 more functions )
FUNCTION XXINTG_CONFIG_CUSTACC(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
xx_cust_acc VARCHAR2(200) := null;
BEGIN
  select hca.account_number 
  into xx_cust_acc
  from oe_order_headers ooh
      ,hz_cust_site_uses hcsu
      ,HZ_CUST_ACCT_SITES hcas
      ,HZ_CUST_ACCOUNTS hca
  where ooh.header_id = xx_line_record.header_id
  and   ooh.ship_to_org_id = hcsu.site_use_id
  and   hcsu.cust_acct_site_id = hcas.cust_acct_site_id
  and   hcas.cust_account_id = hca.cust_account_id;
  RETURN xx_cust_acc;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
FUNCTION XXINTG_CONFIG_CUSTID(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER IS
xx_cust_id NUMBER;
BEGIN
  select hca.cust_account_id 
  into xx_cust_id
  from oe_order_headers ooh
      ,hz_cust_site_uses hcsu
      ,HZ_CUST_ACCT_SITES hcas
      ,HZ_CUST_ACCOUNTS hca
  where ooh.header_id = xx_line_record.header_id
  and   ooh.ship_to_org_id = hcsu.site_use_id
  and   hcsu.cust_acct_site_id = hcas.cust_acct_site_id
  and   hcas.cust_account_id = hca.cust_account_id;
  RETURN xx_cust_id;
EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
-- End of  Changes as per New FRS (Addition of 2 more functions )

--Changes as per New FRS on 26/09/2013 (Addition of 3 more functions )
FUNCTION XXINTG_CONFIG_GETDIV(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
--xx_division VARCHAR2(200);
xx_div_code VARCHAR2(100);
BEGIN
     SELECT MCK.SEGMENT1 
     into xx_div_code
     from 
        mtl_item_categories mic,
        MTL_CATEGORIES_KFV MCK,
        MTL_CATEGORY_SETS MCS
     where mic.inventory_item_id = xx_line_record.inventory_item_id
          AND mic.category_set_id = mcs.category_set_id
          AND MCS.CATEGORY_SET_NAME = 'Inventory'
          AND MIC.CATEGORY_ID = MCK.CATEGORY_ID
          AND mic.organization_id = xx_line_record.ship_from_org_id;
          
     /*SELECT ffvv.description
        INTO xx_division
            FROM fnd_flex_values_vl ffvv,
                 fnd_flex_value_sets ffvs
            WHERE 1=1
                  AND ffvs.flex_value_set_name = 'INTG_DIV'
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.flex_value = xx_div_code;*/
     RETURN xx_div_code;
EXCEPTION
    WHEN OTHERS THEN
         RETURN null;
END;
FUNCTION XXINTG_CONFIG_SUBDIV(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
--xx_sub_div VARCHAR2(200);
xx_subdiv_code VARCHAR2(100);
BEGIN
     SELECT MCK.SEGMENT2 
     into xx_subdiv_code
     from 
        mtl_item_categories mic,
        MTL_CATEGORIES_KFV MCK,
        MTL_CATEGORY_SETS MCS
     where mic.inventory_item_id = xx_line_record.inventory_item_id
          AND mic.category_set_id = mcs.category_set_id
          AND MCS.CATEGORY_SET_NAME = 'Inventory'
          AND MIC.CATEGORY_ID = MCK.CATEGORY_ID
          AND mic.organization_id = xx_line_record.ship_from_org_id;
          
    /* SELECT ffvv.description
        INTO xx_sub_div
            FROM fnd_flex_values_vl ffvv,
                 fnd_flex_value_sets ffvs
            WHERE 1=1
                  AND ffvs.flex_value_set_name = 'INTG_SUB_DIVISION'
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.flex_value = xx_subdiv_code;*/
     RETURN xx_subdiv_code;
EXCEPTION
    WHEN OTHERS THEN
         RETURN null;
END;
FUNCTION XXINTG_CONFIG_PROTYPE(xx_line_record IN oe_order_pub.g_line%type) RETURN CHAR IS
--xx_product_type VARCHAR2(200);
xx_product_code VARCHAR2(100);
BEGIN
     SELECT MCK.SEGMENT5 
     into xx_product_code
     from 
        mtl_item_categories mic,
        MTL_CATEGORIES_KFV MCK,
        MTL_CATEGORY_SETS MCS
     where mic.inventory_item_id = xx_line_record.inventory_item_id
          AND mic.category_set_id = mcs.category_set_id
          AND MCS.CATEGORY_SET_NAME = 'Inventory'
          AND MIC.CATEGORY_ID = MCK.CATEGORY_ID
          AND mic.organization_id = xx_line_record.ship_from_org_id;
          
     /*SELECT ffvv.description
        INTO xx_product_type
            FROM fnd_flex_values_vl ffvv,
                 fnd_flex_value_sets ffvs
            WHERE 1=1
                  AND ffvs.flex_value_set_name = 'INTG_PRODUCT_CATEGORY'
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.flex_value = xx_product_code;*/
     RETURN xx_product_code;
EXCEPTION
     WHEN OTHERS THEN
         RETURN null;
END;
-- End of  Changes as per New FRS (Addition of 3 more functions ) on 26-Sep-2013

FUNCTION XXINTG_CONFIG_TOTFR(xx_line_record IN oe_order_pub.g_line%type,xx_type IN VARCHAR2) RETURN NUMBER IS
xx_tot_frcost NUMBER := 0;
xx_delivery_id NUMBER := null;
BEGIN
  begin
         /*SELECT wda.delivery_id INTO xx_delivery_id FROM wsh_delivery_details wdd, wsh_delivery_assignments wda
         WHERE 1=1 AND wdd.source_line_id = xx_line_record.line_id AND wdd.source_code = 'OE' AND wdd.delivery_detail_id = wda.delivery_detail_id;*/
       -- added for case # 006417
       select distinct WDA.DELIVERY_ID into XX_DELIVERY_ID from WSH_DELIVERY_DETAILS WDD, WSH_DELIVERY_ASSIGNMENTS WDA 
       WHERE 1=1 AND wdd.source_line_id = xx_line_record.line_id AND wdd.source_code = 'OE' AND wdd.delivery_detail_id = wda.delivery_detail_id and rownum=1;
  EXCEPTION
      WHEN OTHERS THEN
           RETURN 0;
  END;
  IF xx_type = 'INTG' THEN  
       SELECT SUM(NVL(wfc.attribute1,0)) INTO xx_tot_frcost    FROM wsh_freight_costs wfc WHERE 1=1 AND wfc.delivery_id = xx_delivery_id ;
  ELSE
     SELECT SUM(NVL(wfc.unit_amount,0)) INTO xx_tot_frcost    FROM wsh_freight_costs wfc WHERE 1=1 AND wfc.delivery_id = xx_delivery_id ;
  END IF;
  RETURN (xx_tot_frcost);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;

FUNCTION XXINTG_CONFIG_PRORATE(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER IS
xx_total_shipped_quantity NUMBER := 0;
xx_shipped_quantity NUMBER := 0;
BEGIN
  BEGIN
         SELECT sum(nvl(wdda.shipped_quantity,0)), sum(decode(wdda.source_line_id,wdd.source_line_id,wdd.shipped_quantity,0))
         INTO xx_total_shipped_quantity, xx_shipped_quantity
         FROM wsh_delivery_details wdd,
                wsh_delivery_assignments wda,
            wsh_delivery_details wdda,
            wsh_delivery_assignments wdaa
         WHERE 1=1
                 AND wdd.source_line_id = xx_line_record.line_id
                 AND wdda.source_code = 'OE' AND wdd.source_code = 'OE'
             AND wdd.delivery_detail_id = wda.delivery_detail_id
             AND wda.delivery_id = wdaa.delivery_id
             AND wdaa.delivery_detail_id = wdda.delivery_detail_id
         GROUP BY wda.delivery_id;
  EXCEPTION
      WHEN OTHERS THEN
           RETURN 0;
  END;
    IF xx_shipped_quantity>0 and xx_total_shipped_quantity>0 then
     RETURN (xx_shipped_quantity / xx_total_shipped_quantity);
  ELSE 
     RETURN 0;
  END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;

END;
/
