DROP PACKAGE BODY APPS.XXONT_DEFAULTING_RULES;

CREATE OR REPLACE PACKAGE BODY APPS."XXONT_DEFAULTING_RULES" 
IS
/******************************************************************************
-- Filename:  XXONT_DEFAULTING_RULES.pkb
-- RICEW Object id : O2C-EXT_081
-- Purpose :  Package Body for IDefaulting Rule Setups
--
-- Usage: Type PL/SQL Procedure
-- Caution:
-- Copyright (c) IBM
-- All rights reserved.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  04-Apr-2013  ABhargava          Created

********************************************************************************************/

FUNCTION SHIPMENT_PRIORITY ( p_database_object_name  VARCHAR2,
                             p_attribute_code        VARCHAR2 )
RETURN VARCHAR2
IS
l_hdr_rec        OE_AK_ORDER_HEADERS_V%ROWTYPE;
x_org_id         NUMBER;
x_ship_method    OE_AK_ORDER_HEADERS_V.SHIPPING_METHOD_CODE%TYPE;
x_ship_to_org_id OE_AK_ORDER_HEADERS_V.SHIP_TO_ORG_ID%TYPE;
l_ship_pri       OE_AK_ORDER_HEADERS_V.SHIPMENT_PRIORITY_CODE%TYPE;
l_code           VARCHAR2(200);
l_site_code      VARCHAR2(30);
BEGIN
    -- Getting the defaulting global record
    l_hdr_rec := ONT_HEADER_Def_Hdlr.g_record;
    x_org_id := FND_PROFILE.VALUE('ORG_ID');
    x_ship_to_org_id   :=l_hdr_rec.SHIP_TO_ORG_ID;
    x_ship_method      :=l_hdr_rec.SHIPPING_METHOD_CODE;

     BEGIN
        select meaning
        into l_code
        from fnd_lookup_values
        where lookup_type = 'SHIP_METHOD'
        and language = 'US'
        and lookup_code = x_ship_method;
     EXCEPTION
     WHEN OTHERS THEN
        select meaning
        into l_code
        from fnd_lookup_values
        where lookup_type = 'SHIP_METHOD'
        and language = 'US'
        and lookup_code = (select SHIP_VIA from hz_cust_site_uses_all where site_use_id = x_ship_to_org_id);
     END;

    Select decode(b.attribute3,'Domestic','Standard','International','INT','Standard') SHIP_PRI
    into l_ship_pri
    from hz_cust_site_uses_all a,
         hz_cust_acct_sites_all b
    where  a.site_use_id = x_ship_to_org_id
    and  a.cust_acct_site_id = b.cust_acct_site_id;

    IF (upper(l_code) like '%NEXT%DAY%' OR upper(l_code) like '%OVERNIGHT%') AND l_ship_pri = 'Standard' THEN
        return('RS');
    ELSIF (upper(l_code) like '%NEXT%DAY%' OR upper(l_code) like '%OVERNIGHT%') AND l_ship_pri = 'INT' THEN
        return('INTR');
    ELSE
        return(l_ship_pri);
    END IF;


    return(NULL);
EXCEPTION
WHEN OTHERS THEN
    return(NULL);
END;


FUNCTION CURRENCY      ( p_database_object_name  VARCHAR2,
                        p_attribute_code        VARCHAR2 )
RETURN VARCHAR2
IS
l_hdr_rec        OE_AK_ORDER_HEADERS_V%ROWTYPE;
x_org_id         NUMBER;
x_ship_to_org_id OE_AK_ORDER_HEADERS_V.SHIP_TO_ORG_ID%TYPE;
l_code           VARCHAR2(10);
BEGIN
    -- Getting the defaulting global record
    l_hdr_rec := ONT_HEADER_Def_Hdlr.g_record;
    x_org_id := FND_PROFILE.VALUE('ORG_ID');
    x_ship_to_org_id   :=l_hdr_rec.SHIP_TO_ORG_ID;

    select c.attribute1
    into l_code
    from hz_cust_site_uses_all a, hz_cust_acct_sites_all b, hz_customer_profiles c
    where a.cust_acct_site_id = b.cust_acct_site_id
    and c.cust_account_id = b.cust_account_id
    and a.site_use_id = x_ship_to_org_id;

    return(l_code);

EXCEPTION
WHEN OTHERS THEN
    return(NULL);
END;

FUNCTION ITEM_SHIP_METHOD      ( p_database_object_name  VARCHAR2,
                        p_attribute_code        VARCHAR2 )
RETURN VARCHAR2
IS
l_ln_rec        OE_AK_ORDER_LINES_V%ROWTYPE;
l_hdr_rec        OE_AK_ORDER_HEADERS_V%ROWTYPE;
l_def_ship_code VARCHAR2(100);
l_code  VARCHAR2(100);

BEGIN
    -- Getting the defaulting global record
    l_hdr_rec := ONT_HEADER_Def_Hdlr.g_record;
    l_ln_rec := ONT_LINE_Def_Hdlr.g_record;
    l_code := null;
    
    select fv.description into l_def_ship_code
      from FND_LOOKUP_VALUES_VL fv, mtl_system_items msi
     where fv.lookup_type = 'XXINTG_ITEM_SHIP_METHOD'
       and fv.enabled_flag = 'Y' and sysdate between nvl(fv.start_date_active,sysdate) and nvl(fv.end_date_active,sysdate)
       and fv.LOOKUP_CODE = msi.segment1 and msi.organization_id = 83 and msi.inventory_item_id = l_ln_rec.inventory_item_id
       and rownum = 1;

    begin
      select ship_method_code into l_code from WSH_CARRIER_SERVICES_V wcsv where wcsv.ship_method_meaning = l_def_ship_code and wcsv.enabled_flag = 'Y' and rownum = 1;
      return(l_code);
    exception
      when others then
           null;
    end;
    
    begin
       select wcsv.ship_method_code into l_code 
         from WSH_CARRIER_SERVICES_V wcsvl, HZ_CUST_SITE_USES_ALL hcsu, WSH_CARRIER_SERVICES_V wcsv
        where wcsvl.ship_method_code = l_hdr_rec.shipping_method_code  and l_hdr_rec.shipping_method_code is not null 
          and wcsvl.carrier_id = wcsv.carrier_id and wcsv.attribute3 = l_def_ship_code
          and wcsv.enabled_flag = 'Y' and wcsvl.enabled_flag = 'Y' and rownum = 1;
       return(l_code);   
    exception
      when others then
           null;
    end;    
    
    begin
       select wcsv.ship_method_code into l_code from WSH_CARRIER_SERVICES_V wcsv
        where wcsv.attribute3 = l_def_ship_code and wcsv.attribute4 = 'Y' and wcsv.enabled_flag = 'Y'  and rownum = 1;
       return(l_code);   
    exception
      when others then
           null;
    end;
    
    return(null);

EXCEPTION
WHEN OTHERS THEN
    return(NULL);
END;

FUNCTION ITEM_SHIP_METHOD_PRC      ( p_database_object_name  VARCHAR2,
                        p_attribute_code        VARCHAR2 )
RETURN VARCHAR2
IS
l_ln_rec        OE_AK_ORDER_LINES_V%ROWTYPE;
l_hdr_rec        OE_AK_ORDER_HEADERS_V%ROWTYPE;
l_def_ship_code VARCHAR2(100);
l_code  VARCHAR2(100);

BEGIN
    
    l_hdr_rec := ONT_HEADER_Def_Hdlr.g_record;
    l_ln_rec := ONT_LINE_Def_Hdlr.g_record;
    l_code := null;
    
    select fv.description into l_def_ship_code
      from FND_LOOKUP_VALUES_VL fv, mtl_system_items msi
     where fv.lookup_type = 'XXINTG_ITEM_SHIP_METHOD'
       and fv.enabled_flag = 'Y' and sysdate between nvl(fv.start_date_active,sysdate) and nvl(fv.end_date_active,sysdate)
       and fv.LOOKUP_CODE = msi.segment1 and msi.organization_id = 83 and msi.inventory_item_id = l_ln_rec.inventory_item_id
       and rownum = 1;

    begin
      select ship_method_code into l_code from WSH_CARRIER_SERVICES_V wcsv 
      where to_number(wcsv.attribute3) <= to_number(l_def_ship_code) and wcsv.ship_method_code = l_hdr_rec.shipping_method_code
        and wcsv.enabled_flag = 'Y' and rownum = 1 and wcsv.attribute3 is not null and l_hdr_rec.shipping_method_code is not null ;
      return(l_code);
    exception
      when others then
           null;
    end;

    begin
      select ship_method_code into l_code from WSH_CARRIER_SERVICES_V wcsv where wcsv.ship_method_meaning = l_def_ship_code and wcsv.enabled_flag = 'Y' and rownum = 1;
      return(l_code);
    exception
      when others then
           null;
    end;
    
    begin
       select wcsv.ship_method_code into l_code 
         from WSH_CARRIER_SERVICES_V wcsvl, HZ_CUST_SITE_USES_ALL hcsu, WSH_CARRIER_SERVICES_V wcsv
        where wcsvl.ship_method_code = l_hdr_rec.shipping_method_code  and l_hdr_rec.shipping_method_code is not null 
          and wcsvl.carrier_id = wcsv.carrier_id and wcsv.attribute3 = l_def_ship_code
          and wcsv.enabled_flag = 'Y' and wcsvl.enabled_flag = 'Y' and rownum = 1;
       return(l_code);   
    exception
      when others then
           null;
    end;    
    
    begin
       select wcsv.ship_method_code into l_code from WSH_CARRIER_SERVICES_V wcsv
        where wcsv.attribute3 = l_def_ship_code and wcsv.attribute4 = 'Y' and wcsv.enabled_flag = 'Y'  and rownum = 1;
       return(l_code);   
    exception
      when others then
           null;
    end;
    
    return(null);

EXCEPTION
WHEN OTHERS THEN
    return(NULL);
END;

END XXONT_DEFAULTING_RULES;
/
