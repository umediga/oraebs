DROP PACKAGE BODY APPS.XX_INTG_OELINES_FR_UPD;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INTG_OELINES_FR_UPD" 
AS
/******************************************************************************
-- Filename:  XX_INTG_OELINES_FR_UPD.pkb
-- DCR to Update Freight Terms for Order Lines
-- Usage: Concurrent Program ( Type PL/SQL Procedure)
-- Caution:
-- Copyright (c) IBM
-- All rights reserved.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  28-Nov-2012  ABhargava          Created
-- 2.0  14-Feb-2013  ABhargava          Chnaged for BUG# 001947
-- 3.0  27-Feb-2013  ABhargava          Changed for BUG # 002040
-- 4.0  6-Mar-2013   ABhargava          Added check for Partial Delivery
-- 5.0  23-Aug-2013  ABhargava          Made changes as per Wave1 Req
-- 6.0  13-Sep-2013  ABhargava          Added VALIDATE_AND_LOAD check
-- 7.0  04-Oct-2013  Narendra Yadav     Added some i/p parameters and API to update freight_term_code at Delivery
-- 8.0  29-Nov-2013  ABhargava          Added Check for Shipment Priority
******************************************************************************/
-- **********************************************************************
--    Procedure to set environment.
-- **********************************************************************
PROCEDURE set_cnv_env (p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes)
IS

  x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;

BEGIN

  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside set_cnv_env...');

  -- Set the environment
  --x_error_code := xx_emf_pkg.set_env;
  x_error_code := xx_emf_pkg.set_env(p_process_name => 'XX_INTG_OELINES_FR_UPD');

  IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
  THEN
     xx_emf_pkg.propagate_error (x_error_code);
  END IF;

EXCEPTION
  WHEN OTHERS
  THEN
     RAISE xx_emf_pkg.g_e_env_not_set;
END set_cnv_env;

PROCEDURE XX_INTG_OELINES_FR_UPDATE (p_errbuff OUT VARCHAR2,p_retcode OUT VARCHAR2,p_order_number IN NUMBER,p_status VARCHAR2,p_operating_unit NUMBER,p_inv_org NUMBER,p_validate IN VARCHAR)
IS
    CURSOR C1_CURR IS
    SELECT   ool.flow_status_code
             ,ooh.order_number
             ,ooh.header_id
             ,ool.line_id
             ,ool.line_number
             ,ool.ordered_item Item
             ,ool.cancelled_flag
             ,ool.open_flag
             ,ool.booked_flag
             ,ool.freight_terms_code
             ,ool.shipping_method_code
             ,ool.shipment_priority_code
             ,ool.org_id
             ,ool.ordered_quantity
             ,(SELECT flv1.meaning FROM fnd_lookup_values flv1
               WHERE flv1.lookup_code = ool.shipping_method_code
                     AND flv1.lookup_type = 'SHIP_METHOD'
                     AND flv1.language = 'US'
                     AND flv1.enabled_flag = 'Y') Shipping_Method
             ,(SELECT flv2.meaning FROM fnd_lookup_values flv2
               WHERE flv2.lookup_code = ool.freight_terms_code
                     AND flv2.lookup_type = 'FREIGHT_TERMS'
                     AND flv2.language = 'US'
                     AND flv2.enabled_flag = 'Y') FREIGHT_TERMS
             ,mtc.category_concat_segs Con_cat_segs
             ,ooh.order_type_id
             ,ool.ship_from_org_id
             ,ool.inventory_item_id
             ,'BACKORDERED' QUERY_STATUS
        FROM oe_order_headers_all ooh,
             oe_order_lines_all ool,
             wsh_delivery_details wdd,
             --fnd_lookup_values flv1,
             --fnd_lookup_values flv2,
             mtl_item_categories_v mtc
        WHERE ooh.header_id = ool.header_id
        AND wdd.source_line_id = ool.line_id
        AND TRUNC (ool.request_date) <= TRUNC (SYSDATE)
        and WDD.RELEASED_STATUS = 'B'
        AND ooh.order_number = NVL (p_order_number, ooh.order_number)
        and ooh.org_id = nvl(p_operating_unit, ooh.org_id) --added condition for operating unit
        --AND ooh.ship_from_org_id = NVL(p_inv_org,ooh.ship_from_org_id) --added condition for inventory organization
        AND nvl(ool.ship_from_org_id,0) = NVL(p_inv_org,nvl(ool.ship_from_org_id,0))
        AND NVL(p_status,'BACKORDERED') = 'BACKORDERED' -- added status of order
       -- AND ool.shipping_method_code=flv1.lookup_code
        --AND ool.freight_terms_code = flv2.lookup_code
        AND mtc.inventory_item_id =ool.inventory_item_id
        and MTC.CATEGORY_SET_NAME = 'Inventory'
        AND mtc.organization_id = ool.ship_from_org_id
        --AND flv1.lookup_type = 'SHIP_METHOD'
        --and flv1.language = 'US'
        --and flv1.enabled_flag = 'Y'
        --AND flv2.lookup_type = 'FREIGHT_TERMS'
        --and flv2.language = 'US'
        --and flv2.enabled_flag = 'Y'
   UNION ALL
       SELECT
             ool.flow_status_code
             ,ooh.order_number
             ,ooh.header_id
             ,ool.line_id
             ,ool.line_number
             ,ool.ordered_item Item
             ,ool.cancelled_flag
             ,ool.open_flag
             ,ool.booked_flag
             ,ool.freight_terms_code
             ,ool.shipping_method_code
             ,ool.shipment_priority_code
             ,ool.org_id
             ,ool.ordered_quantity
             ,(SELECT flv1.meaning FROM fnd_lookup_values flv1
               WHERE flv1.lookup_code = ool.shipping_method_code
                     AND flv1.lookup_type = 'SHIP_METHOD'
                     AND flv1.language = 'US'
                     AND flv1.enabled_flag = 'Y') Shipping_Method
             ,(SELECT flv2.meaning FROM fnd_lookup_values flv2
               WHERE flv2.lookup_code = ool.freight_terms_code
                     AND flv2.lookup_type = 'FREIGHT_TERMS'
                     AND flv2.language = 'US'
                     AND flv2.enabled_flag = 'Y') FREIGHT_TERMS
             ,mtc.category_concat_segs Con_cat_segs
             ,ooh.order_type_id
             ,ool.ship_from_org_id
             ,ool.inventory_item_id
             ,'ENTERED/BOOKED' QUERY_STATUS
        FROM oe_order_headers_all ooh,
             oe_order_lines_all ool,
             --fnd_lookup_values flv1,
             --fnd_lookup_values flv2,
             mtl_item_categories_v mtc
        WHERE ooh.header_id = ool.header_id
        --AND wdd.source_line_id = ool.line_id
        AND TRUNC (ool.request_date) <= TRUNC (SYSDATE)
        --and WDD.RELEASED_STATUS = 'S'
        AND ooh.order_number = NVL (p_order_number, ooh.order_number)
        and ooh.org_id = nvl(p_operating_unit,ooh.org_id)--added condition for org_id
        --AND ooh.ship_from_org_id = NVL(p_inv_org,ooh.ship_from_org_id) --added condition for inv_org_id
         AND nvl(ool.ship_from_org_id,0) = NVL(p_inv_org,nvl(ool.ship_from_org_id,0))
        AND NVL(p_status,'ENTERED/BOOKED') = 'ENTERED/BOOKED' -- added condition for order status
        AND ool.flow_status_code IN ('BOOKED','ENTERED')
        --AND ool.shipping_method_code=flv1.lookup_code
        --AND ool.freight_terms_code = flv2.lookup_code
        AND mtc.inventory_item_id =ool.inventory_item_id
        and MTC.CATEGORY_SET_NAME = 'Inventory'
        AND mtc.organization_id = ool.ship_from_org_id
        /*AND flv1.lookup_type = 'SHIP_METHOD'
        and flv1.language = 'US'
        and flv1.enabled_flag = 'Y'
        AND flv2.lookup_type = 'FREIGHT_TERMS'
        and flv2.language = 'US'
        and flv2.enabled_flag = 'Y'*/
   UNION ALL
        SELECT
             ool.flow_status_code
             ,ooh.order_number
             ,ooh.header_id
             ,ool.line_id
             ,ool.line_number
             ,ool.ordered_item Item
             ,ool.cancelled_flag
             ,ool.open_flag
             ,ool.booked_flag
             ,ool.freight_terms_code
             ,ool.shipping_method_code
             ,ool.shipment_priority_code
             ,ool.org_id
             ,ool.ordered_quantity
             ,(SELECT flv1.meaning FROM fnd_lookup_values flv1
               WHERE flv1.lookup_code = ool.shipping_method_code
                     AND flv1.lookup_type = 'SHIP_METHOD'
                     AND flv1.language = 'US'
                     AND flv1.enabled_flag = 'Y') Shipping_Method
             ,(SELECT flv2.meaning FROM fnd_lookup_values flv2
               WHERE flv2.lookup_code = ool.freight_terms_code
                     AND flv2.lookup_type = 'FREIGHT_TERMS'
                     AND flv2.language = 'US'
                     AND flv2.enabled_flag = 'Y') FREIGHT_TERMS
             ,mtc.category_concat_segs Con_cat_segs
             ,ooh.order_type_id
             ,ool.ship_from_org_id
             ,ool.inventory_item_id
             ,'ENTERED/BOOKED' QUERY_STATUS
        FROM oe_order_headers_all ooh,
             oe_order_lines_all ool,
             wsh_delivery_details wdd,
             --fnd_lookup_values flv1,
            -- fnd_lookup_values flv2,
             mtl_item_categories_v mtc
        WHERE ooh.header_id = ool.header_id
        AND wdd.source_line_id = ool.line_id
        AND TRUNC (ool.request_date) <= TRUNC (SYSDATE)
        AND WDD.RELEASED_STATUS = 'R'
        AND ooh.order_number = NVL (p_order_number, ooh.order_number)
        and ooh.org_id = nvl(p_operating_unit,ooh.org_id) --added condition for operating unit
        --AND ooh.ship_from_org_id = NVL(p_inv_org,ooh.ship_from_org_id) --added condition for inventory organization
          AND nvl(ool.ship_from_org_id,0) = NVL(p_inv_org,nvl(ool.ship_from_org_id,0))
        AND NVL(p_status,'ENTERED/BOOKED') = 'ENTERED/BOOKED' -- added status of order
        AND ool.flow_status_code = 'AWAITING_SHIPPING'
        --AND ool.shipping_method_code=flv1.lookup_code
        --AND ool.freight_terms_code = flv2.lookup_code
        AND mtc.inventory_item_id =ool.inventory_item_id
        and MTC.CATEGORY_SET_NAME = 'Inventory'
        AND mtc.organization_id = ool.ship_from_org_id
   UNION ALL
        SELECT
             ool.flow_status_code
             ,ooh.order_number
             ,ooh.header_id
             ,ool.line_id
             ,ool.line_number
             ,ool.ordered_item Item
             ,ool.cancelled_flag
             ,ool.open_flag
             ,ool.booked_flag
             ,ool.freight_terms_code
             ,ool.shipping_method_code
             ,ool.shipment_priority_code
             ,ool.org_id
             ,ool.ordered_quantity
             ,(SELECT flv1.meaning FROM fnd_lookup_values flv1
               WHERE flv1.lookup_code = ool.shipping_method_code
                     AND flv1.lookup_type = 'SHIP_METHOD'
                     AND flv1.language = 'US'
                     AND flv1.enabled_flag = 'Y') Shipping_Method
             ,(SELECT flv2.meaning FROM fnd_lookup_values flv2
               WHERE flv2.lookup_code = ool.freight_terms_code
                     AND flv2.lookup_type = 'FREIGHT_TERMS'
                     AND flv2.language = 'US'
                     AND flv2.enabled_flag = 'Y') FREIGHT_TERMS
             ,mtc.category_concat_segs Con_cat_segs
             ,ooh.order_type_id
             ,ool.ship_from_org_id
             ,ool.inventory_item_id
             ,'AWAITING_SHIPPING' QUERY_STATUS
        FROM oe_order_headers_all ooh,
             oe_order_lines_all ool,
             wsh_delivery_details wdd,
             --fnd_lookup_values flv1,
            -- fnd_lookup_values flv2,
             mtl_item_categories_v mtc
        WHERE ooh.header_id = ool.header_id
        AND wdd.source_line_id = ool.line_id
        AND TRUNC (ool.request_date) <= TRUNC (SYSDATE)
        AND WDD.RELEASED_STATUS in ('S','Y')
        AND ooh.order_number = NVL (p_order_number, ooh.order_number)
        and ooh.org_id = nvl(p_operating_unit,ooh.org_id) --added condition for operating unit
        --AND ooh.ship_from_org_id = NVL(p_inv_org,ooh.ship_from_org_id) --added condition for inventory organization
          AND nvl(ool.ship_from_org_id,0) = NVL(p_inv_org,nvl(ool.ship_from_org_id,0))
        AND NVL(p_status,'AWAITING_SHIPPING') = 'AWAITING_SHIPPING' -- added status of order
        AND ool.flow_status_code = 'AWAITING_SHIPPING'
        --AND ool.shipping_method_code=flv1.lookup_code
        --AND ool.freight_terms_code = flv2.lookup_code
        AND mtc.inventory_item_id =ool.inventory_item_id
        and MTC.CATEGORY_SET_NAME = 'Inventory'
        AND mtc.organization_id = ool.ship_from_org_id
        /*AND flv1.lookup_type = 'SHIP_METHOD'
        and flv1.language = 'US'
        and flv1.enabled_flag = 'Y'
        AND flv2.lookup_type = 'FREIGHT_TERMS'
        and flv2.language = 'US'
        and flv2.enabled_flag = 'Y'*/;


    CURSOR C2_CURR(l_ord_type NUMBER,l_item_id NUMBER,l_org_id NUMBER,l_ship_id NUMBER) IS
    select *
    from XX_INTG_FREIGHT_TERM_UPDATE
    where NVL(TRANSACTION_TYPE_ID,l_ord_type) = l_ord_type
    and   NVL(INVENTORY_ITEM_ID,l_item_id) = l_item_id
    and   ORGANIZATION_ID = l_org_id
    and   nvl(INV_ORG_ID,nvl(l_ship_id,0)) =  nvl(l_ship_id,0)
    and   trunc(sysdate) between nvl(DATE_FROM,to_date('01-JAN-1900','DD-MON-YYYY')) and nvl(DATE_TO,to_date('31-DEC-4712','DD-MON-YYYY'))
    order by rank;

    l_return_status                VARCHAR2 (2000);
    l_msg_count                    NUMBER;
    l_msg_data                     VARCHAR2 (2000);
    l_line_val_rec                 oe_order_pub.Line_Val_Rec_Type;
    l_line_id                      NUMBER;
    l_ship_qty                     NUMBER;
    l_fr_code                      VARCHAR2(100);
    l_cnt                          NUMBER := 0;

    l_msg_index                    NUMBER;
    l_data                         VARCHAR2 (2000);

    x_return_message               VARCHAR2(4000);
    g_err_msg                      VARCHAR2(200);
    l_excep                        EXCEPTION;
    --added by narendra for API to update Freight_terms_code
    init_msg_list                  VARCHAR2(30);
    l_delivery_rec                 WSH_DELIVERIES_PUB.Delivery_Pub_Rec_Type;
    o_name                         VARCHAR2(100);
    o_del_id                       NUMBER;

BEGIN
    set_cnv_env (xx_emf_cn_pkg.CN_YES);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '  ');
    xx_emf_pkg.put_line(rpad('Order Number',30,' ')||rpad('Line Number',15,' ')||rpad('Freight Code(Old/New)',40,' ')||rpad('Ship Method(Old/New)',40,' ')||rpad('Status',20,' '));
    xx_emf_pkg.put_line(rpad('-',145,'-'));
    << c1_loop >>
    FOR C1 in C1_CURR
    LOOP
    BEGIN
         x_return_message := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, '************************');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Order : '||c1.order_number||' '||c1.line_number);

         -- Added on 6th March to check for Partial Delivery
         g_err_msg := 'Error Checking Partial Delivery Check ';
         l_cnt := 0;
         l_ship_qty := 0;
         --Added on 02-OCT-2013 to check Partial Delivery as per order status
         IF c1.query_status = 'BACKORDERED' THEN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'check bo count');
           select count(1)
           into l_cnt
           from wsh_delivery_details
           where source_header_id = c1.HEADER_ID
           and released_status NOT IN ('B')
           and source_line_id = c1.line_id;

         ELSIF c1.query_status =  ('ENTERED/BOOKED') THEN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'check enter book count');
           select count(1)
           into l_ship_qty
           from wsh_Delivery_details
           where source_header_id = c1.HEADER_ID
           and  RELEASED_STATUS = 'C'
           ;

         ELSIF c1.query_status = 'AWAITING_SHIPPING' THEN
           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'check awaiting count');
           --select count(1) into l_cnt from wsh_delivery_details
           --where source_header_id = c1.HEADER_ID and released_status NOT IN ('B') and source_line_id = c1.line_id;

		      --   IF l_cnt =0 THEN
        			 select count(1)
        			 into l_ship_qty
        			 from wsh_Delivery_details
        			 where source_header_id = c1.HEADER_ID
        			 and  RELEASED_STATUS = 'C';
          --   END IF;
         END IF;

         --added some more condition in IF condition
         IF (l_cnt = 0 AND c1.query_status = 'BACKORDERED') OR (l_ship_qty > 0 AND c1.query_status in ('ENTERED/BOOKED','AWAITING_SHIPPING' )) THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Passed Partial Delivery Check ');
         << c2_loop >>
         FOR C2 in C2_CURR (c1.order_type_id,c1.inventory_item_id,c1.org_id,c1.ship_from_org_id)
         LOOP
             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Second Loop ');
             -- Check if Ship Method, Shipment Priority and Category Matches
             IF (c1.shipping_method like c2.ship_method_from or c2.ship_method_from IS NULL)
             AND  (c1.Con_cat_segs like c2.category or c2.category IS NULL)
             AND  (c1.shipment_priority_code = c2.SHIP_PRIORITY OR c2.SHIP_PRIORITY IS NULL)THEN

               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Passed 1st Conditions Check for FRUPD_ID  '||c2.FRUPD_ID);

               -- Check if the Shipping Method and Freight Terms are null Or match the existing values
               IF  (c2.SHIP_METHOD_TO is NULL AND c2.FREIGHT_TERMS IS NULL)
               --OR  (c2.SHIP_METHOD_TO = c1.shipping_method  AND c2.FREIGHT_TERMS = c1.freight_terms)
               OR  (c1.shipping_method = nvl(c2.SHIP_METHOD_TO,c1.shipping_method)  AND c1.freight_terms = nvl(c2.freight_terms,c1.FREIGHT_TERMS))
               THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Skipped Line since match or NULL ');
                   EXIT c2_loop;
               ELSE
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Passed 2nd Conditions Check for FRUPD_ID  '||c2.FRUPD_ID);
                   l_line_id                    := c1.line_id;
                   l_line_val_rec := oe_order_pub.G_MISS_LINE_VAL_REC;
                   l_delivery_rec.FREIGHT_TERMS_code := FND_API.G_MISS_CHAR;
                   l_delivery_rec.ship_method_name := FND_API.G_MISS_CHAR;
                   IF c2.FREIGHT_TERMS IS NOT NULL AND c2.FREIGHT_TERMS != c1.freight_terms THEN
                      g_err_msg := 'Error Fetching Freight Terms Name';
                      l_line_val_rec.freight_terms := c2.FREIGHT_TERMS;
                      select lookup_code into l_delivery_rec.FREIGHT_TERMS_code
                      from fnd_lookup_values where lookup_type = 'FREIGHT_TERMS' and language='US' and meaning = c2.FREIGHT_TERMS;
                      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Ord Fr Terms:'||l_line_val_rec.freight_terms);
                      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Del Fr Terms:'||l_delivery_rec.FREIGHT_TERMS_code);
                   END IF;
                   IF c2.SHIP_METHOD_TO IS NOT NULL AND c2.SHIP_METHOD_TO != c1.shipping_method THEN
                      g_err_msg := 'Error Fetching Ship Method Code ';
                      l_line_val_rec.shipping_method := c2.SHIP_METHOD_TO;
                      l_delivery_rec.ship_method_name := c2.SHIP_METHOD_TO;
                      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Ord Ship:'||l_line_val_rec.shipping_method);
                      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Del Ship:'||l_delivery_rec.ship_method_name);
                   END IF;

                   -- Added as per the changes to the FRS on 13th Sept 2013
                   IF nvl(p_validate,'VALIDATE_AND_LOAD') = 'VALIDATE_AND_LOAD' THEN
                     g_err_msg := 'Unknown Error in API';
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Inside Ord Upd');
  --                   oe_msg_pub.initialize;
                       --added condition to update in case of Shipping Awaiting
                     IF (c1.query_status IN ('BACKORDERED','ENTERED/BOOKED')) THEN
                       oe_order_pub.Update_Line
                        (
                         p_line_id         => l_line_id
                        ,p_line_val_rec    => l_line_val_rec
                        ,p_org_id          => c1.org_id
                        ,x_return_status   => l_return_status
                        ,x_msg_count       => l_msg_count
                        ,x_msg_data        => l_msg_data
                        );

                       IF l_msg_count = 0 AND l_return_status = 'S'
                       THEN
                           xx_emf_pkg.put_line(rpad(c1.order_number,30,' ')||rpad(c1.line_number,15,' ')||rpad(c1.freight_terms||'/'||c2.FREIGHT_TERMS,40,' ')||rpad(c1.shipping_method||'/'||c2.SHIP_METHOD_TO,40,' ')||rpad('Success',20,' '));
                           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'line:'||l_line_id|| ' updated with '||l_line_val_rec.freight_terms|| ','||l_line_val_rec.shipping_method);
                       ELSE
                           xx_emf_pkg.put_line(rpad(c1.order_number,30,' ')||rpad(c1.line_number,15,' ')||rpad(c1.freight_terms||'/'||c2.FREIGHT_TERMS,40,' ')||rpad(c1.shipping_method||'/'||c2.SHIP_METHOD_TO,40,' ')||rpad('Error',20,' '));
                           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' ********* ERROR ********* ');
                           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Line ID - '||l_line_id);

                           FOR i IN 1 .. l_msg_count
                           LOOP
                              oe_msg_pub.get (p_msg_index          => i,
                                              p_encoded            => fnd_api.g_false,
                                              p_data               => l_data,
                                              p_msg_index_out      => l_msg_index
                                             );
                              x_return_message := x_return_message ||' '||l_data;
                           END LOOP;
                           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Error Message '||x_return_message);

                       END IF;
                     ELSIF c1.query_status = 'AWAITING_SHIPPING' THEN
                 --API wsh_delivery_details_pub.update_shipping_attributes();
                       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Inside Del Upd');
                       l_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
                       /*FND_GLOBAL.APPS_INITIALIZE(
                                       user_id      => 125186
                                    ,  resp_id      => 21623
                                    ,  resp_appl_id => 660);

                       --source_code := 'OE'; */
                      select wnd.delivery_id
                      into  l_delivery_rec.delivery_id
                      from wsh_new_deliveries wnd,wsh_delivery_assignments wda,wsh_delivery_details wdd
                      where 1=1
                            AND wnd.delivery_id = wda.delivery_id
                            AND wda.delivery_detail_id = wdd.delivery_detail_id
                            AND wdd.source_line_id = c1.line_id;
                       IF (l_delivery_rec.delivery_id is NOT NULL) THEN

                       WSH_DELIVERIES_PUB.Create_Update_Delivery(
                        p_api_version_number      => 1.0,
                        p_init_msg_list           => FND_API.G_TRUE, --init_msg_list,
                        x_return_status           => l_return_status,
                        x_msg_count               => l_msg_count,
                        x_msg_data                => l_msg_data,
                        p_action_code             => 'UPDATE',
                        p_delivery_info           => l_delivery_rec,
                        p_delivery_name           => l_delivery_rec.delivery_id,
                        x_delivery_id             => o_del_id,
                        x_name                    => o_name
                        );

                           IF (l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Del Upd Err:' ||l_return_status ||' '||l_msg_count);
                              WSH_UTIL_CORE.get_messages('Y', l_msg_data, l_data,l_msg_count);
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Error:' ||l_msg_data);
                              xx_emf_pkg.put_line(rpad(c1.order_number,30,' ')||rpad(c1.line_number,15,' ')||rpad(c1.freight_terms||'/'||c2.FREIGHT_TERMS,40,' ')||rpad(c1.shipping_method||'/'||c2.SHIP_METHOD_TO,40,' ')||rpad('Error',20,' '));
                              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' ********* ERROR ********* ');
                              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' Line ID - '||l_line_id);
                           ELSE
                              xx_emf_pkg.put_line(rpad(c1.order_number||'/'||l_delivery_rec.delivery_id,30,' ')||rpad(c1.line_number,15,' ')||rpad(c1.freight_terms||'/'||c2.FREIGHT_TERMS,40,' ')||rpad(c1.shipping_method||'/'||c2.SHIP_METHOD_TO,40,' ')||rpad('Success',20,' '));
                              xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Del:'||l_delivery_rec.delivery_id|| ' updated with '||l_delivery_rec.freight_terms_code|| ','||l_delivery_rec.ship_method_name);
                              --commit;
                           END IF;
                       ELSE
                           xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Unable to fetch delivery_id');
                       END IF;
                     END IF;
                   END IF;
                   EXIT c2_loop;
               END IF;
             END IF;
         END LOOP c2_loop;
         ELSE
             xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Partial Delivery Moving to Next Line');
         END IF;
    EXCEPTION
    WHEN OTHERS THEN
         xx_emf_pkg.put_line(rpad(c1.order_number,30,' ')||rpad(c1.line_number,15,' ')||rpad(l_fr_code,40,' ')||rpad('Error',20,' '));
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' ********* ERROR ********* ');
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, ' API Update Operation Failed for Line ID '||l_line_id);
         xx_emf_pkg.error (
                p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => 'Updating Frieght Terms - Order Lines',
                p_error_text               => 'API Update Operation Failed',
                p_record_identifier_1      => l_line_id,
                p_record_identifier_2      => x_return_message
               );
    END;
    END LOOP c1_loop;


EXCEPTION
WHEN l_excep THEN

    ------Added EMF Log Message to insert data into EMF table ------
    xx_emf_pkg.error (
                p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => 'Updating Frieght Terms - Order Lines',
                p_error_text               => 'API Update Operation Failed',
                p_record_identifier_1      => l_line_id,
                p_record_identifier_2      => x_return_message
               );
     --p_retcode := 2;
    ------Added EMF Log Message end------
WHEN OTHERS THEN

    ------Added EMF Log Message to insert data into EMF table ------
    xx_emf_pkg.error (
                p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => 'Updating Frieght Terms - Order Lines',
                p_error_text               => 'Update Operation Failed:',
                p_record_identifier_1      => l_line_id,
                p_record_identifier_2      => g_err_msg
               );
    ------Added EMF Log Message end------
    p_retcode := 2;
END XX_INTG_OELINES_FR_UPDATE;



END XX_INTG_OELINES_FR_UPD;
/
