DROP PACKAGE BODY APPS.XX_SDC_ORDER_VIEW_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_ORDER_VIEW_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Renjith
 Creation Date : 19-FEBR-2014
 File Name     : XX_SDC_ORDER_UPDATE_PKG.pks
 Description   : This script creates the specification of the package
		 xx_ont_so_acknowledge_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 19-FEBR-2014 Renjith              Initial Development
*/
----------------------------------------------------------------------
FUNCTION return_context ( p_header_id IN NUMBER
                         ,p_line_id   IN NUMBER
                        ) RETURN VARCHAR2
IS
 x_ret_context     VARCHAR2(30) :=NULL;
 x_ret_attribute1  VARCHAR2(240):=NULL;
 x_ret_attribute2  VARCHAR2(240):=NULL;

 x_ord_number      NUMBER        :=NULL;
 x_ord_line        VARCHAR2(100) := NULL;

 x_trx_number      VARCHAR2(20)  := NULL;
 x_trx_lno         NUMBER;

 x_cust_po         VARCHAR2(50);
 x_cust_line       VARCHAR2(100) := NULL;

 x_ret_value       VARCHAR2(500) := NULL;
BEGIN
   BEGIN
     SELECT  return_context
            ,return_attribute1
            ,return_attribute2
       INTO  x_ret_context
       	    ,x_ret_attribute1
       	    ,x_ret_attribute2
       FROM  oe_order_lines_all
      WHERE  header_id = p_header_id
        AND  line_id   = p_line_id;
   EXCEPTION WHEN OTHERS THEN
      x_ret_context     := NULL;
      x_ret_attribute1  := NULL;
      x_ret_attribute1  := NULL;
   END;

   IF x_ret_context IS NOT NULL THEN
      IF x_ret_context = 'ORDER' THEN
         BEGIN
           SELECT  order_number
             INTO  x_ord_number
             FROM  oe_order_headers_all
            WHERE  header_id = to_number(x_ret_attribute1);
         EXCEPTION WHEN OTHERS THEN
           x_ord_number := NULL;
         END;

         BEGIN
           SELECT  OE_Flex_UTIL.GET_CONCAT_VALUE(l.line_number,l.shipment_number,l.option_number,l.component_number,l.service_number)
             INTO  x_ord_line
             FROM  oe_order_lines_all l
            WHERE  line_id = to_number(x_ret_attribute2);
         END;
         x_ret_value := 'Sales Order' ||'-'||x_ord_number||'-'||x_ord_line;
      ELSIF x_ret_context = 'INVOICE' THEN
         BEGIN
           SELECT trx_number
             INTO x_trx_number
             FROM ra_customer_trx_all
            WHERE customer_trx_id = to_number(x_ret_attribute1);
         END;

         BEGIN
           SELECT line_number
             INTO x_trx_lno
             FROM ra_customer_trx_lines_all
            WHERE customer_trx_line_id = to_number(x_ret_attribute2);
         END;
         x_ret_value := 'Invoice'||'-'||x_trx_number||'-'||x_trx_lno;
      ELSIF x_ret_context = 'PO' THEN
         BEGIN
           SELECT  cust_po_number
             INTO  x_cust_po
             FROM  oe_order_headers_all
            WHERE  header_id = to_number(x_ret_attribute1);
         EXCEPTION WHEN OTHERS THEN
           x_ord_number := NULL;
         END;

         BEGIN
           SELECT  OE_Flex_UTIL.GET_CONCAT_VALUE(l.line_number,l.shipment_number,l.option_number,l.component_number,l.service_number)
             INTO  x_cust_line
             FROM  oe_order_lines_all l
            WHERE  line_id = to_number(x_ret_attribute2);
         END;
         x_ret_value := 'Customer PO' ||'-'||x_cust_po||'-'||x_cust_line;
      END IF;
   END IF;
   RETURN(NVL(x_ret_value,'X'));
END return_context;
----------------------------------------------------------------------
FUNCTION is_onhold ( p_header_id IN NUMBER
                    ,p_line_id   IN NUMBER
                   ) RETURN VARCHAR2
IS
  x_hold_cnt NUMBER :=0;
BEGIN
   SELECT COUNT(*) INTO x_hold_cnt
     FROM oe_order_holds_all
    WHERE header_id = p_header_id
      AND line_id   = p_line_id
      AND NVL(released_flag,'N') ='N';

    IF x_hold_cnt = 0 THEN
       RETURN('N');
    ELSE
       RETURN('Y');
    END IF;
EXCEPTION WHEN OTHERS THEN
   RETURN('N');
END is_onhold;

----------------------------------------------------------------------
FUNCTION line_status ( p_header_id IN NUMBER
                      ,p_line_id   IN NUMBER
                      ,p_status      IN   VARCHAR2
                      ) RETURN VARCHAR2
IS
   x_status       VARCHAR2(200);
   x_status_desc  VARCHAR2(200);
BEGIN
   BEGIN
     SELECT  decode(RELEASED_STATUS,'Y','PICKED','S','PICKED','B','PICKED',p_status)
       INTO  x_status
       FROM  wsh_delivery_details
      WHERE  source_code = 'OE'
        AND  source_line_id = p_line_id
        AND  source_header_id = p_header_id
        AND  released_status != 'D';
   EXCEPTION WHEN OTHERS THEN
      x_status := p_status;
   END;

   BEGIN
      SELECT  meaning
        INTO  x_status_desc
        FROM  oe_lookups
       WHERE  lookup_code =  x_status
         AND  lookup_type = 'LINE_FLOW_STATUS';
   EXCEPTION WHEN OTHERS THEN
      x_status_desc := 'Awaiting Shipping';
   END;
   RETURN(x_status_desc);
EXCEPTION WHEN OTHERS THEN
   RETURN('Awaiting Shipping');
END line_status;

----------------------------------------------------------------------
FUNCTION header_total ( p_header_id   IN   NUMBER)
RETURN NUMBER
IS
  CURSOR c_line
  IS
  SELECT  unit_selling_price
         ,decode(line_category_code,'RETURN',(ordered_quantity *-1),ordered_quantity) qty
    FROM  oe_order_lines_all
   WHERE  NVL(cancelled_flag,'N') <> 'Y'
     AND  header_id = p_header_id;

  CURSOR c_tax
  IS
  SELECT  decode(line_category_code,'RETURN',(tax_value *-1),tax_value) tax
    FROM  oe_order_lines_all
   WHERE  NVL(cancelled_flag,'N') <> 'Y'
     AND  header_id = p_header_id;

   x_tot      NUMBER:=0;
   x_tax      NUMBER:=0;
   x_charge   NUMBER := 0;
BEGIN
   FOR r_line IN c_line
   LOOP
     x_tot := x_tot + (r_line.unit_selling_price * r_line.qty);
   END LOOP;

   FOR r_tax IN c_tax
   LOOP
     x_tax := x_tax + r_tax.tax;
   END LOOP;

   BEGIN
      SELECT NVL(SUM(operand),0)
        INTO x_charge
        FROM oe_price_adjustments
       WHERE header_id = p_header_id
         AND charge_type_code <> 'TAX';
   EXCEPTION WHEN OTHERS THEN
     x_charge := 0;
   END;

   x_tot := x_tot + x_tax + x_charge;
   RETURN(NVL(x_tot,0));
EXCEPTION WHEN OTHERS THEN
   RETURN(0);
END header_total;

----------------------------------------------------------------------
FUNCTION header_sub_total ( p_header_id   IN   NUMBER)
RETURN NUMBER
IS
  CURSOR c_line
  IS
  SELECT  unit_selling_price
         ,decode(line_category_code,'RETURN',(ordered_quantity *-1),ordered_quantity) qty
    FROM  oe_order_lines_all
   WHERE  NVL(cancelled_flag,'N') <> 'Y'
     AND  header_id = p_header_id;

   x_tot NUMBER:=0;
BEGIN
   FOR r_line IN c_line
   LOOP
     x_tot := x_tot + (r_line.unit_selling_price * r_line.qty);
   END LOOP;
   RETURN(NVL(x_tot,0));
EXCEPTION WHEN OTHERS THEN
   RETURN(0);
END header_sub_total;

----------------------------------------------------------------------
FUNCTION header_tax ( p_header_id   IN   NUMBER)
RETURN NUMBER
IS
  CURSOR c_tax
  IS
  SELECT  decode(line_category_code,'RETURN',(tax_value *-1),tax_value) tax
    FROM  oe_order_lines_all
   WHERE  NVL(cancelled_flag,'N') <> 'Y'
     AND  header_id = p_header_id;

   x_tax      NUMBER:=0;
BEGIN
   FOR r_tax IN c_tax
   LOOP
     x_tax := x_tax + NVL(r_tax.tax,0);
   END LOOP;
   RETURN(NVL(x_tax,0));
EXCEPTION WHEN OTHERS THEN
   RETURN(0);
END header_tax;

----------------------------------------------------------------------
END xx_sdc_order_view_pkg;
/
