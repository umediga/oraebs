DROP PACKAGE BODY APPS.XX_QP_PRICE_BK_XMLP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_PRICE_BK_XMLP_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 26-MAR-2013
 File Name     : XXQPPRICEBKXMLP.pkb
 Description   : This script creates the body of the package
                 xx_qp_price_bk_xmlp_pkg to create code for after
                 parameter form trigger
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 26-MAR-2013 Sharath Babu          Initial Development
*/
----------------------------------------------------------------------
--After Parameter Form Trigger
FUNCTION AFTERPFORM RETURN BOOLEAN IS
BEGIN
   P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
   
   IF p_cust_num IS NULL AND p_cust_name IS NULL AND
      p_gpo_idn IS NULL AND p_cntrct_num IS NULL AND
      p_list_name IS NULL AND p_item_cat IS NULL AND p_item_num IS NULL THEN
      LP_WHERE := ' AND 1 = 2';
      fnd_file.put_line(fnd_file.log,'Any one of the these parameters is mandatory: Customer Number, Customer Name, GPO/IDN Name,'||
                                      'Contract Number, Price/Modifier List Name, Item Category, Item Number : LP_WHERE: '||LP_WHERE);
   END IF;
   
   IF p_cust_num IS NOT NULL THEN
      LP_CUST_NUM := ' AND hca.account_number = :p_cust_num';
   ELSIF p_cust_name IS NOT NULL THEN
      LP_CUST_NUM := ' AND hca.account_number = :p_cust_name';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_CUST_NUM);
   
   IF p_gpo_idn IS NOT NULL THEN
      LP_GPO_IDN := ' AND qlh.attribute3 = :p_gpo_idn';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_GPO_IDN);
   
   IF p_cntrct_num IS NOT NULL THEN
      LP_CNTRCT_NUM := ' AND qlh.attribute11 = :p_cntrct_num';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_CNTRCT_NUM);
   
   IF p_list_name IS NOT NULL THEN
      LP_LIST_NAME := ' AND qlh.name = :p_list_name';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_LIST_NAME);
   
   IF p_item_cat IS NOT NULL THEN      
      LP_ITEM_CAT_PRL := ' AND TO_NUMBER(qpa.product_attr_value) = :p_item_cat AND qpa.product_attribute = '''||'PRICING_ATTRIBUTE2'||'''';
      LP_ITEM_CAT_DLT := ' AND TO_NUMBER(qms.product_attr_val) = :p_item_cat AND qms.product_attr = '''||'PRICING_ATTRIBUTE2'||'''';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_ITEM_CAT_PRL);
   fnd_file.put_line(fnd_file.log,LP_ITEM_CAT_DLT);
   
   IF p_item_num IS NOT NULL THEN
      LP_ITEM_NUM_PRL := ' AND TO_NUMBER(qpa.product_attr_value) = :p_item_num AND qpa.product_attribute = '''||'PRICING_ATTRIBUTE1'||'''';
      LP_ITEM_NUM_DLT := ' AND TO_NUMBER(qms.product_attr_val) = :p_item_num AND qms.product_attr = '''||'PRICING_ATTRIBUTE1'||'''';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_ITEM_NUM_PRL);
   fnd_file.put_line(fnd_file.log,LP_ITEM_NUM_DLT);
   
   IF p_prod_class IS NOT NULL THEN
      LP_PROD_CLASS := ' AND (product_class = :p_prod_class OR cust_name IS NOT NULL)';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_PROD_CLASS);

    IF p_division IS NOT NULL THEN
      LP_DIVISION := ' AND (division = :p_division OR cust_name IS NOT NULL)';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_DIVISION);

   IF p_product_type IS NOT NULL THEN
      LP_PRODUCT_TYPE := ' AND (( EXISTS (SELECT 1 FROM fnd_flex_values_vl fvl '||
                                                    ' ,fnd_flex_value_sets fvs '||
                                                ' WHERE fvl.flex_value_set_id = fvs.flex_value_set_id '||
                                                '  AND   fvs.flex_value_set_name ='''||'INTG_PRODUCT_TYPE'||''''||
                                                '   AND   flex_value = dcode '||
                                                '   AND   flex_value = :p_product_type) '||
                           ' OR cust_name IS NOT NULL)) ' ;
                       --AND (product_type = :p_product_type OR cust_name IS NOT NULL)';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_PRODUCT_TYPE);

   
   IF p_brand IS NOT NULL THEN
      LP_BRAND := ' AND (brand = :p_brand OR cust_name IS NOT NULL) ';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_BRAND);
   
   IF p_ou_name IS NOT NULL THEN
      LP_OU_NAME := ' AND qlh.orig_org_id = :p_ou_name';
   END IF;
   fnd_file.put_line(fnd_file.log,LP_OU_NAME);
   
   RETURN (TRUE);
END AFTERPFORM; 

--After Report Trigger
FUNCTION AFTERREPORT RETURN BOOLEAN IS
   v_reqid NUMBER;
BEGIN
   NULL;
   RETURN (TRUE);
EXCEPTION
   WHEN OTHERS THEN
   NULL;
   RETURN (FALSE);
END AFTERREPORT;
--Function to get item standard cost
FUNCTION get_item_std_cost( p_inv_item_id IN NUMBER )
RETURN NUMBER 
IS
   CURSOR c_org_id 
   IS 
   SELECT organization_id 
   FROM org_organization_definitions; 
   
   x_total_cost NUMBER := 0;
   x_counter NUMBER := 0;
   x_item_cost NUMBER := 0;   
   
BEGIN
   FOR i IN c_org_id 
   LOOP
      x_item_cost := cst_cost_api.get_item_cost(1.1,p_inv_item_id,i.organization_id);
      IF x_item_cost != 0 THEN
         x_total_cost := x_total_cost + x_item_cost;
         x_counter := x_counter + 1;
      END IF;
   END LOOP;
   IF x_counter <> 0 THEN
      x_item_cost := ROUND((x_total_cost/x_counter),2); 
   END IF;
   RETURN x_item_cost;
EXCEPTION
WHEN OTHERS THEN
   RETURN 0;  	
END get_item_std_cost;
--Function to calculate gross margin
FUNCTION get_gross_margin( p_price    IN NUMBER 
                          ,p_std_cost IN NUMBER )
RETURN NUMBER 
IS
   
   x_gross_margin NUMBER := NULL;   
BEGIN

   IF p_price <> 0 AND p_price IS NOT NULL THEN
      x_gross_margin := (( p_price - p_std_cost )/p_price)*100;
   END IF;
   x_gross_margin := ROUND(x_gross_margin,2);
   
   RETURN x_gross_margin;
EXCEPTION
WHEN OTHERS THEN
   RETURN 0;  	
END get_gross_margin;

END XX_QP_PRICE_BK_XMLP_PKG;  
/
