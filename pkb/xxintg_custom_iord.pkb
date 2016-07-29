DROP PACKAGE BODY APPS.XXINTG_CUSTOM_IORD;

CREATE OR REPLACE PACKAGE BODY APPS.XXINTG_CUSTOM_IORD is
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 28-Aug-13
 File Name     : XXONTITEMORDER.pkb
 Description   : This script creates package body for XXINTG_CUSTOM_IORD
 Change History:

 Date        Name                Remarks
 ----------- ------------        -------------------------------------
 28-Aug-13    Aabhas             Initial Version
*/
----------------------------------------------------------------------

FUNCTION XXINTG_IOR_RULEVALUE (L_RULE_LEVEL in VARCHAR,L_RULE_LEVEL_ID IN VARCHAR)
RETURN VARCHAR2
IS
l_val VARCHAR2(240);
BEGIN
IF L_RULE_LEVEL IN('CUSTOMER','END_CUST') THEN
   select party_name
   into l_val
   from hz_parties a
       ,HZ_CUST_ACCOUNTS b
   where a.party_id = b.party_id
   and   b.cust_account_id = to_number(L_RULE_LEVEL_ID);
ELSIF   L_RULE_LEVEL = 'CUST_CLASS' THEN
   select name
   into l_val
   from hz_cust_profile_classes
   where profile_class_id = to_number(L_RULE_LEVEL_ID);
ELSIF   L_RULE_LEVEL = 'CUST_CATEGORY' THEN
   SELECT meaning
   into l_val
   FROM ar_lookups
   WHERE lookup_type = 'CUSTOMER_CATEGORY'
   and lookup_code = L_RULE_LEVEL_ID;
ELSIF   L_RULE_LEVEL = 'CUST_CLASSIF' THEN
   SELECT meaning
   into l_val
   FROM ar_lookups
   WHERE lookup_type = 'CUSTOMER CLASS'
   and lookup_code = L_RULE_LEVEL_ID;
ELSIF   L_RULE_LEVEL = 'REGIONS' THEN
   SELECT COUNTRY ||', '||STATE||', '||CITY||', '||ZONE||', '||POSTAL_CODE_FROM ||' - '||POSTAL_CODE_TO REGION
   into l_val
   FROM WSH_REGIONS_V
   where region_id = to_number(L_RULE_LEVEL_ID);
ELSIF   L_RULE_LEVEL = 'ORDER_TYPE' THEN
   select name
   into l_val
   FROM oe_order_types_v
   where order_type_id = to_number(L_RULE_LEVEL_ID);
ELSIF   L_RULE_LEVEL = 'SALES_CHANNEL' THEN
   SELECT meaning
   into l_val
   FROM oe_lookups
   WHERE lookup_type = 'SALES_CHANNEL'
   and lookup_code = L_RULE_LEVEL_ID;
ELSIF   L_RULE_LEVEL = 'SALES_REP' THEN
    SELECT name
    into l_val
    FROM ra_salesreps
    where salesrep_id = to_number(L_RULE_LEVEL_ID);
ELSIF   L_RULE_LEVEL IN ('SHIP_TO_LOC','BILL_TO_LOC','DELIVER_TO_LOC') THEN
    select location
    into l_val
    from HZ_CUST_SITE_USES
    where site_use_id =   to_number(L_RULE_LEVEL_ID);
END IF;
RETURN (l_val);
EXCEPTION
WHEN OTHERS THEN
     RETURN NULL;
END XXINTG_IOR_RULEVALUE;


FUNCTION XXINTG_IOR_VALUE_SET(L_VAL_SET_NM IN VARCHAR2,L_CODE IN VARCHAR2)
return varchar2 is
l_res varchar2(240);
begin
    SELECT ffvv.description
    INTO l_res
    FROM fnd_flex_values_vl ffvv,
         fnd_flex_value_sets ffvs
    WHERE 1=1
    AND ffvs.flex_value_set_name = L_VAL_SET_NM
    AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
    AND ffvv.flex_value = L_CODE;
  return(l_res);
EXCEPTION
WHEN OTHERS THEN
    return NULL;
END XXINTG_IOR_VALUE_SET;

FUNCTION XXINTG_IOR_ITEM_SEG1 (L_INV_ID IN NUMBER)
return varchar2 is
l_item_desc varchar2(240);
l_id number :=0;
begin
    SELECT organization_id
    into l_id
    FROM ORG_ORGANIZATION_DEFINITIONS
    where organization_name = 'IO INTEGRA ITEM MASTER';

    select segment1
    into l_item_desc
    from mtl_system_items_b
    where inventory_item_id = l_inv_id
    and organization_id = l_id;
  return(l_item_desc);
EXCEPTION
WHEN OTHERS THEN
    return NULL;
END XXINTG_IOR_ITEM_SEG1;

FUNCTION XXINTG_IOR_ITEM_DESC (L_INV_ID IN NUMBER)
return varchar2 is
l_item_desc varchar2(240);
l_id number :=0;
begin
    SELECT organization_id
    into l_id
    FROM ORG_ORGANIZATION_DEFINITIONS
    where organization_name = 'IO INTEGRA ITEM MASTER';

    select description
    into l_item_desc
    from mtl_system_items_b
    where inventory_item_id = l_inv_id
    and organization_id = l_id;
  return(l_item_desc);
EXCEPTION
WHEN OTHERS THEN
    return NULL;
END XXINTG_IOR_ITEM_DESC;

END XXINTG_CUSTOM_IORD;
/
