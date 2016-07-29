DROP PACKAGE BODY APPS.XXQP_CATGY_SEGMENT;

CREATE OR REPLACE PACKAGE BODY APPS."XXQP_CATGY_SEGMENT" 
AS
FUNCTION GET_SEGMENT_VALUE(
    P_CATGY_SET_NAME    VARCHAR2,
    P_SEGMENT_NO        VARCHAR2,
    P_INVENTORY_ITEM_ID NUMBER,
    P_ORGANIZATION_ID   NUMBER)
  RETURN VARCHAR2
AS  
  /* This is a generic function used to fetch the Category segment value given the input parameters irrespective of the host module */
  L_SEGMENT1 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT2 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT3 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT4 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT5 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT6 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT7 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT8 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT9 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT10 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT11 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT12 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT13 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT14 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT15 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT16 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT17 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT18 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT19 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
  L_SEGMENT20 MTL_CATEGORIES_KFV.SEGMENT1%TYPE;
BEGIN
  OE_DEBUG_PUB.ADD(' INSIDE CUSTOM ATTRIBUTE CALL WITH INPUTS  ');
  OE_DEBUG_PUB.ADD(' inventory_item_id : '||P_inventory_item_id);
  OE_DEBUG_PUB.ADD(' ORGANIZATION_ID : '||P_ORGANIZATION_id);
  OE_DEBUG_PUB.ADD(' P_CATGY_SET_NAME : '||P_CATGY_SET_NAME);
  OE_DEBUG_PUB.ADD(' P_SEGMENT_NO : '||P_SEGMENT_NO);
  -- Derive DCODE
  SELECT MCK.segment1,
    MCK.segment2,
    MCK.segment3,
    MCK.segment4,
    MCK.segment5,
    MCK.segment6,
    MCK.segment7,
    MCK.segment8,
    MCK.segment9,
    MCK.segment10,
    MCK.segment11,
    MCK.segment12,
    MCK.segment13,
    MCK.segment14,
    MCK.segment15,
    MCK.segment16,
    MCK.segment17,
    MCK.segment18,
    MCK.segment19,
    MCK.segment20
  INTO L_SEGMENT1,
    L_SEGMENT2,
    L_SEGMENT3,
    L_SEGMENT4,
    L_SEGMENT5,
    L_SEGMENT6,
    L_SEGMENT7,
    L_SEGMENT8,
    L_SEGMENT9,
    L_SEGMENT10,
    L_SEGMENT11,
    L_SEGMENT12,
    L_SEGMENT13,
    L_SEGMENT14,
    L_SEGMENT15,
    L_SEGMENT16,
    L_SEGMENT17,
    L_SEGMENT18,
    L_SEGMENT19,
    L_SEGMENT20
  FROM mtl_item_categories mic,
    MTL_CATEGORIES_KFV MCK,
    MTL_CATEGORY_SETS MCS
  WHERE mic.inventory_item_id = P_inventory_item_id
  AND mic.category_set_id     = mcs.category_set_id
  AND MCS.CATEGORY_SET_NAME   = p_catgy_set_name
  AND MIC.CATEGORY_ID         = MCK.CATEGORY_ID
  AND mic.organization_id     =P_ORGANIZATION_ID;
  IF p_segment_no             ='SEGMENT1' THEN
    RETURN L_SEGMENT1;
  ELSIF p_segment_no ='SEGMENT2' THEN
    RETURN L_SEGMENT2;
  ELSIF p_segment_no ='SEGMENT3' THEN
    RETURN L_SEGMENT3;
  ELSIF p_segment_no ='SEGMENT4' THEN
    RETURN L_SEGMENT4;
  ELSIF p_segment_no ='SEGMENT5' THEN
    RETURN L_SEGMENT5;
  ELSIF p_segment_no ='SEGMENT6' THEN
    RETURN L_SEGMENT6;
  ELSIF p_segment_no ='SEGMENT7' THEN
    RETURN L_SEGMENT7;
  ELSIF p_segment_no ='SEGMENT8' THEN
    RETURN L_SEGMENT8;
  ELSIF p_segment_no ='SEGMENT9' THEN
    RETURN L_SEGMENT9;
  ELSIF p_segment_no ='SEGMENT10' THEN
    RETURN L_SEGMENT10;
  ELSIF p_segment_no ='SEGMENT11' THEN
    RETURN L_SEGMENT11;
  ELSIF p_segment_no ='SEGMENT12' THEN
    RETURN L_SEGMENT12;
  ELSIF p_segment_no ='SEGMENT13' THEN
    RETURN L_SEGMENT13;
  ELSIF p_segment_no ='SEGMENT14' THEN
    RETURN L_SEGMENT14;
  ELSIF p_segment_no ='SEGMENT15' THEN
    RETURN L_SEGMENT15;
  ELSIF p_segment_no ='SEGMENT16' THEN
    RETURN L_SEGMENT16;
  ELSIF p_segment_no ='SEGMENT17' THEN
    RETURN L_SEGMENT17;
  ELSIF p_segment_no ='SEGMENT18' THEN
    RETURN L_SEGMENT18;
  ELSIF p_segment_no ='SEGMENT19' THEN
    RETURN L_SEGMENT19;
  ELSIF p_segment_no ='SEGMENT20' THEN
    RETURN L_SEGMENT20;
  ELSE
    RETURN NULL;
  END IF;
  RETURN NULL;
END GET_SEGMENT_VALUE;
FUNCTION GET_VALUE_FOR_OM(
    P_CATGY_SET_NAME VARCHAR2,
    P_SEGMENT_NO     VARCHAR2,
    P_LINE_RECORD IN oe_order_pub.g_line%type)
  RETURN VARCHAR2
AS
  /* This function should be used by Advanced pricing attribute mapping for Order Management A sample usage for DCODE category segment is as follows.
  XXQP_CATGY_SEGMENT.GET_VALUE_FOR_OM('Sales and Marketing','SEGMENT9',oe_order_pub.g_line)
  */
  L_ORGANIZATION_ID NUMBER;
  L_VALUE           VARCHAR2(1000);
BEGIN
  L_ORGANIZATION_ID    :=P_LINE_RECORD.SHIP_FROM_ORG_ID;
  IF L_ORGANIZATION_ID IS NULL THEN
    SELECT ORGANIZATION_ID
    INTO L_ORGANIZATION_ID
    FROM ORG_ORGANIZATION_DEFINITIONS
    WHERE ORGANIZATION_CODE='MST';
  END IF;
  L_VALUE := GET_SEGMENT_VALUE(P_CATGY_SET_NAME ,P_SEGMENT_NO,P_LINE_RECORD.INVENTORY_ITEM_ID, L_ORGANIZATION_ID);
  OE_DEBUG_PUB.ADD(' Returned Value : '||l_value);
  OE_DEBUG_PUB.ADD(' End of custom messages. ');
  RETURN l_value;
END GET_VALUE_FOR_OM;

FUNCTION GET_VALUE_FOR_OM_HDR(
    P_CATGY_SET_NAME VARCHAR2,
    P_SEGMENT_NO     VARCHAR2,
    P_HDR_RECORD IN OE_ORDER_PUB.G_HDR%type)
  RETURN VARCHAR2
    
AS
  /* This function should be used by Advanced pricing attribute mapping for Order Management A sample usage for DCODE category segment is as follows.
  XXQP_CATGY_SEGMENT.GET_VALUE_FOR_OM('Sales and Marketing','SEGMENT9',oe_order_pub.g_line)
  */
  cursor data_cur is  
  select inventory_item_id,ship_from_org_id , line_id 
  from oe_order_lines_all 
  where header_id=p_hdr_record.header_id;
  L_ORGANIZATION_ID NUMBER;
  L_VALUE           VARCHAR2(1000);
BEGIN
  for p_line_record in data_cur loop
      L_ORGANIZATION_ID    :=P_LINE_RECORD.SHIP_FROM_ORG_ID;
      IF L_ORGANIZATION_ID IS NULL THEN
        SELECT ORGANIZATION_ID
        INTO L_ORGANIZATION_ID
        FROM ORG_ORGANIZATION_DEFINITIONS
        WHERE ORGANIZATION_CODE='MST';
      END IF;
      L_VALUE := GET_SEGMENT_VALUE(P_CATGY_SET_NAME ,P_SEGMENT_NO,P_LINE_RECORD.INVENTORY_ITEM_ID, L_ORGANIZATION_ID);
      OE_DEBUG_PUB.ADD(' Returned Value : '||l_value);
      OE_DEBUG_PUB.ADD(' End of custom messages. ');
      if l_value is not null then
         RETURN l_value;
      end if;
end loop;
END GET_VALUE_FOR_OM_HDR;

FUNCTION GET_VALUE_FOR_ASO(
    P_CATGY_SET_NAME VARCHAR2,
    P_SEGMENT_NO     VARCHAR2,
    P_LINE_RECORD IN ASO_PRICING_INT.G_LINE_REC%type)
  RETURN VARCHAR2
AS
  L_ORGANIZATION_ID NUMBER;
  /* This function should be used by Advanced pricing attribute mapping for Oracle quoting module. A sample usage for DCODE category segment is as follows.
  XXQP_CATGY_SEGMENT.GET_VALUE_FOR_ASO('Sales and Marketing','SEGMENT9',ASO_PRICING_INT.G_LINE_REC);
  */
BEGIN
  L_ORGANIZATION_ID    :=P_LINE_RECORD.ORGANIZATION_ID;
  IF L_ORGANIZATION_ID IS NULL THEN
    SELECT ORGANIZATION_ID
    INTO L_ORGANIZATION_ID
    FROM ORG_ORGANIZATION_DEFINITIONS
    WHERE ORGANIZATION_CODE='MST';
  END IF;
  RETURN GET_SEGMENT_VALUE(P_CATGY_SET_NAME ,P_SEGMENT_NO,P_LINE_RECORD.INVENTORY_ITEM_ID, L_ORGANIZATION_ID);
END GET_VALUE_FOR_ASO;
/* This function returns the value of ship to account cust acct id for a given order header id. This is 
required for Pricing attribute QUALIFIER_ATTRIBUTE40.   */
 FUNCTION get_Ship_to_cust_account_id(p_line_rec OE_ORDER_PUB.G_LINE%type)

RETURN number IS   

l_cust_acct_id number;

BEGIN

      SELECT   hca.cust_account_id
    INTO l_cust_acct_id
      FROM       
              hz_cust_site_uses_all hcs_ship,
             hz_cust_acct_sites_all ship_casa,
             hz_cust_accounts hca
 WHERE   p_line_rec.ship_to_org_id = hcs_ship.site_use_id
     
     and hcs_ship.site_use_code      = 'SHIP_TO'
         AND hcs_ship.cust_acct_site_id = ship_casa.cust_acct_site_id
         AND hca.cust_account_id = ship_casa.cust_account_id;




   RETURN l_cust_acct_id;

 EXCEPTION
     WHEN NO_DATA_FOUND THEN
       return null;
     WHEN OTHERS THEN
       return NULL;
END get_Ship_to_cust_account_id;

Function get_nationality(p_line_rec OE_ORDER_PUB.G_LINE%type) return varchar2 
as 
l_nationality varchar2(30);
begin
   l_nationality :='Domestic';
   select has.attribute3 into l_nationality
   from AR.hz_cust_acct_sites_all has, apps.hz_cust_site_uses_all hcsu  
   where  hcsu.site_use_id=p_line_rec.ship_to_org_id  and hcsu.cust_acct_site_id=has.cust_acct_site_id;
   if l_nationality is null then 
        l_nationality :='Domestic';
   end if;
   RETURN  l_nationality;
  exception 
  when others then
  return l_nationality;
end;

 FUNCTION get_Ship_to_cust_account_id(p_header_id IN NUMBER)

RETURN number IS   

l_cust_acct_id number;

BEGIN

      SELECT   hca.cust_account_id
    INTO l_cust_acct_id
      FROM        oe_order_headers_v ooh,
              hz_cust_site_uses_all hcs_ship,
             hz_cust_acct_sites_all ship_casa,
             hz_cust_accounts hca
 WHERE   ooh.ship_to_org_id = hcs_ship.site_use_id
     and ooh.header_id=p_header_id
     and hcs_ship.site_use_code      = 'SHIP_TO'
         AND hcs_ship.cust_acct_site_id = ship_casa.cust_acct_site_id
         AND hca.cust_account_id = ship_casa.cust_account_id;




   RETURN l_cust_acct_id;

 EXCEPTION
     WHEN NO_DATA_FOUND THEN
       return null;
     WHEN OTHERS THEN
       return NULL;
END get_Ship_to_cust_account_id;

Function get_nationality(p_header_id in number) return varchar2 
as 
l_nationality varchar2(30);
begin
   select has.attribute3 into l_nationality
   from AR.hz_cust_acct_sites_all has, apps.oe_order_headers_all oh,apps.hz_cust_site_uses_all hcsu  
   where oh.header_id=p_header_id and hcsu.site_use_id=oh.ship_to_org_id  and hcsu.cust_acct_site_id=has.cust_acct_site_id;
   if l_nationality is null then 
        l_nationality :='Domestic';
   end if;
   RETURN  l_nationality;
  exception 
  when others then
  return l_nationality;
end;


FUNCTION get_division(p_header_id IN number) RETURN CHAR IS
--xx_division VARCHAR2(200);
xx_div_code VARCHAR2(100);
BEGIN
     SELECT distinct MCK.SEGMENT1
     into xx_div_code
     from
        mtl_item_categories mic,
        MTL_CATEGORIES_KFV MCK,
        MTL_CATEGORY_SETS MCS,
        oe_order_lines_all oola,
        oe_order_headers_all ooha
     where ooha.header_id=p_header_id and
     ooha.header_id=oola.header_id and
             mic.inventory_item_id = oola.inventory_item_id
          AND mic.category_set_id = mcs.category_set_id
          AND MCS.CATEGORY_SET_NAME = 'Inventory'
          AND MIC.CATEGORY_ID = MCK.CATEGORY_ID
          AND mic.organization_id = oola.ship_from_org_id;

         RETURN xx_div_code;
EXCEPTION
   when too_many_rows then
          return 'MULTI';
    WHEN OTHERS THEN
         RETURN null;
END;


FUNCTION get_sub_division(p_header_id IN number) RETURN CHAR IS
--xx_division VARCHAR2(200);
xx_div_code VARCHAR2(100);
BEGIN
     SELECT distinct MCK.SEGMENT2
     into xx_div_code
     from
        mtl_item_categories mic,
        MTL_CATEGORIES_KFV MCK,
        MTL_CATEGORY_SETS MCS,
        oe_order_lines_all oola,
        oe_order_headers_all ooha
     where ooha.header_id=p_header_id and
     ooha.header_id=oola.header_id and
             mic.inventory_item_id = oola.inventory_item_id
          AND mic.category_set_id = mcs.category_set_id
          AND MCS.CATEGORY_SET_NAME = 'Inventory'
          AND MIC.CATEGORY_ID = MCK.CATEGORY_ID
          AND mic.organization_id = oola.ship_from_org_id;

         RETURN xx_div_code;
EXCEPTION
   when too_many_rows then
          return 'MULTI';
    WHEN OTHERS THEN
         RETURN null;
END;
END XXQP_CATGY_SEGMENT; 
/
