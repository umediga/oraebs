DROP PACKAGE BODY APPS.XXQP_PRICE_CONSTRUCT;

CREATE OR REPLACE PACKAGE BODY APPS."XXQP_PRICE_CONSTRUCT" 
AS
   ----------------------------------------------------------------------
   /*
   Created By    : IBM Development Team
   Creation Date : 07-NOV-2013
   File Name     : XXQPPRCCONSTR.pkb
   Description   : This script creates the package body of the package XXQP_FREIGHT_CONFIG
   Change History:
   Date         Name                   Remarks
   -----------  -------------          -----------------------------------
   07-NOV-2013  Debjani Roy            Initial Draft.
   */
   ----------------------------------------------------------------------

   FUNCTION XXINTG_ORD_TOTAL_CONST (
      xx_line_record IN oe_order_pub.g_line%TYPE)
      RETURN NUMBER
   IS
      x_tot_amount   NUMBER;
   BEGIN
      BEGIN
         SELECT SUM (oel.unit_list_price * oel.pricing_quantity)
           INTO x_tot_amount
           FROM oe_order_headers oeh, oe_order_lines_all oel
          WHERE     oeh.header_id = oel.header_id
                AND oeh.attribute15 = 'Y'
                AND oel.attribute15 = 'Y'
                AND oeh.header_id = xx_line_record.header_id;

         RETURN x_tot_amount;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END XXINTG_ORD_TOTAL_CONST;

   FUNCTION XXINTG_PRC_ENG_API (
      xx_line_record        IN oe_order_pub.g_line%TYPE,
      x_prc_list_id         IN qp_list_headers.list_header_id%TYPE,
      x_inventory_item_id   IN mtl_system_items_b.inventory_item_id%TYPE,
      x_primary_uom_code    IN mtl_system_items_b.primary_uom_code%TYPE)
      RETURN NUMBER
   IS
      ----initialization start
      p_line_tbl                 QP_PREQ_GRP.LINE_TBL_TYPE;
      p_qual_tbl                 QP_PREQ_GRP.QUAL_TBL_TYPE;
      p_line_attr_tbl            QP_PREQ_GRP.LINE_ATTR_TBL_TYPE;
      p_LINE_DETAIL_tbl          QP_PREQ_GRP.LINE_DETAIL_TBL_TYPE;
      p_LINE_DETAIL_qual_tbl     QP_PREQ_GRP.LINE_DETAIL_QUAL_TBL_TYPE;
      p_LINE_DETAIL_attr_tbl     QP_PREQ_GRP.LINE_DETAIL_ATTR_TBL_TYPE;
      p_related_lines_tbl        QP_PREQ_GRP.RELATED_LINES_TBL_TYPE;
      p_control_rec              QP_PREQ_GRP.CONTROL_RECORD_TYPE;
      x_line_tbl                 QP_PREQ_GRP.LINE_TBL_TYPE;
      x_line_qual                QP_PREQ_GRP.QUAL_TBL_TYPE;
      x_line_attr_tbl            QP_PREQ_GRP.LINE_ATTR_TBL_TYPE;
      x_line_detail_tbl          QP_PREQ_GRP.LINE_DETAIL_TBL_TYPE;
      x_line_detail_qual_tbl     QP_PREQ_GRP.LINE_DETAIL_QUAL_TBL_TYPE;
      x_line_detail_attr_tbl     QP_PREQ_GRP.LINE_DETAIL_ATTR_TBL_TYPE;
      x_related_lines_tbl        QP_PREQ_GRP.RELATED_LINES_TBL_TYPE;
      x_return_status            VARCHAR2 (240);
      x_return_status_text       VARCHAR2 (240);
      qual_rec                   QP_PREQ_GRP.QUAL_REC_TYPE;
      line_attr_rec              QP_PREQ_GRP.LINE_ATTR_REC_TYPE;
      line_rec                   QP_PREQ_GRP.LINE_REC_TYPE;
      detail_rec                 QP_PREQ_GRP.LINE_DETAIL_REC_TYPE;
      ldet_rec                   QP_PREQ_GRP.LINE_DETAIL_REC_TYPE;
      rltd_rec                   QP_PREQ_GRP.RELATED_LINES_REC_TYPE;
      l_pricing_contexts_Tbl     QP_Attr_Mapping_PUB.Contexts_Result_Tbl_Type;
      l_qualifier_contexts_Tbl   QP_Attr_Mapping_PUB.Contexts_Result_Tbl_Type;
      v_line_tbl_cnt             INTEGER;

      I                          BINARY_INTEGER;
      l_version                  VARCHAR2 (240);
      l_file_val                 VARCHAR2 (60);

      x_tran_curr_code           oe_order_headers_all.transactional_curr_code%TYPE;
      x_ordered_date             oe_order_headers_all.ordered_date%TYPE;
      x_con_item                 oe_order_headers_all.attribute11%TYPE;
   ----initialization end
   BEGIN
      BEGIN
         SELECT transactional_curr_code, ordered_date, attribute11
           INTO x_tran_curr_code, x_ordered_date, x_con_item
           FROM oe_order_headers
          WHERE header_id = xx_line_record.header_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN 0;
      END;



      ---api start
      /*QP_Attr_Mapping_PUB.Build_Contexts (p_request_type_code => 'ONT',
       p_pricing_type => 'L',
       x_price_contexts_result_tbl => l_pricing_contexts_Tbl,
       x_qual_contexts_result_tbl => l_qualifier_Contexts_Tbl);*/

      v_line_tbl_cnt := 1;

      ---- Control Record
      p_control_rec.pricing_event := 'BATCH';                 -- 'BATCH'; LINE
      p_control_rec.calculate_flag := 'Y'; --QP_PREQ_GRP.G_SEARCH_N_CALCULATE;
      p_control_rec.simulation_flag := 'Y';
      p_control_rec.rounding_flag := 'Q';
      p_control_Rec.manual_discount_flag := 'Y';
      p_control_rec.request_type_code := 'ONT';
      --p_control_rec.TEMP_TABLE_INSERT_FLAG := 'N';
      p_control_rec.source_order_amount_flag := 'Y';

      -------------------------
      ---- Line Records ---------

      line_rec.request_type_code := 'ONT';
      --    line_rec.header_id            := 157802;
      --    line_rec.line_id := 208795; -- Order Line Id. This can be any thing for this script
      line_rec.line_Index := '1';                        -- Request Line Index
      line_rec.line_type_code := 'LINE';        -- LINE or ORDER(Summary Line)
      line_rec.pricing_effective_date := x_ordered_date; -- Pricing as of what date ?
      line_rec.active_date_first := x_ordered_date; -- Can be Ordered Date or Ship Date
      line_rec.active_date_second := x_ordered_date; -- Can be Ordered Date or Ship Date
      line_rec.active_date_first_type := 'NO TYPE';                -- ORD/SHIP
      line_rec.active_date_second_type := 'NO TYPE';               -- ORD/SHIP
      line_rec.line_quantity := 1;                         -- Ordered Quantity
      line_rec.line_uom_code := x_primary_uom_code;        -- Ordered UOM Code
      line_rec.currency_code := x_tran_curr_code;             -- Currency Code
      line_rec.price_flag := 'Y'; -- Price Flag can have 'Y' , 'N'(No pricing) , 'P'(Phase)
      p_line_tbl (1) := line_rec;

      ---- Line Attribute Record



      line_attr_rec.LINE_INDEX := 1;
      line_attr_rec.PRICING_CONTEXT := 'ITEM';                              --
      line_attr_rec.PRICING_ATTRIBUTE := 'PRICING_ATTRIBUTE1';
      line_attr_rec.PRICING_ATTR_VALUE_FROM := x_inventory_item_id; -- INVENTORY ITEM ID
      line_attr_rec.VALIDATED_FLAG := 'N';
      p_line_attr_tbl (1) := line_attr_rec;                    --Deb start end


      ---- Qualifier Attribute Record

      qual_rec.LINE_INDEX := 1; -- Attributes for the above line. Attributes are attached with the line index
      qual_rec.QUALIFIER_CONTEXT := 'MODLIST';
      qual_rec.QUALIFIER_ATTRIBUTE := 'QUALIFIER_ATTRIBUTE4';
      qual_rec.QUALIFIER_ATTR_VALUE_FROM := x_prc_list_id;   -- PRICE LIST ID;
      qual_rec.COMPARISON_OPERATOR_CODE := '=';
      qual_rec.VALIDATED_FLAG := 'Y';
      p_qual_tbl (1) := qual_rec;


      qual_rec.LINE_INDEX := 1;
      qual_rec.QUALIFIER_CONTEXT := 'CUSTOMER';
      qual_rec.QUALIFIER_ATTRIBUTE := 'QUALIFIER_ATTRIBUTE2';
      qual_rec.QUALIFIER_ATTR_VALUE_FROM := xx_line_record.sold_to_org_id;
      qual_rec.COMPARISON_OPERATOR_CODE := '=';
      qual_rec.VALIDATED_FLAG := 'N';
      p_qual_tbl (2) := qual_rec;


      QP_PREQ_PUB.PRICE_REQUEST (p_line_tbl,
                                 p_qual_tbl,
                                 p_line_attr_tbl,
                                 p_line_detail_tbl,
                                 p_line_detail_qual_tbl,
                                 p_line_detail_attr_tbl,
                                 p_related_lines_tbl,
                                 p_control_rec,
                                 x_line_tbl,
                                 x_line_qual,
                                 x_line_attr_tbl,
                                 x_line_detail_tbl,
                                 x_line_detail_qual_tbl,
                                 x_line_detail_attr_tbl,
                                 x_related_lines_tbl,
                                 x_return_status,
                                 x_return_status_text);

      ROLLBACK;

      I := x_line_tbl.FIRST;

      IF I IS NOT NULL
      THEN
         LOOP
            --DBMS_OUTPUT.PUT_LINE ('Line Index: ' || x_line_tbl (I).line_index);
            --DBMS_OUTPUT.PUT_LINE ('Unit_price: ' || x_line_tbl (I).unit_price);
            IF x_line_tbl (I).unit_price <> 0
            THEN
               RETURN x_line_tbl (I).unit_price;
            END IF;

            EXIT WHEN I = x_line_tbl.LAST;
            I := x_line_tbl.NEXT (I);
         END LOOP;
      END IF;
   ---api end

   END XXINTG_PRC_ENG_API;


   FUNCTION XXINTG_ORD_CONST_ITEM_PRC (
      xx_line_record IN oe_order_pub.g_line%TYPE)
      RETURN NUMBER
   IS
      x_inv_item            mtl_system_items_b.segment1%TYPE;
      x_request_date        DATE;
      x_org_id              oe_order_headers.org_id%TYPE;
      x_list_price          NUMBER;
      x_con_item            oe_order_headers_all.attribute11%TYPE;
      x_inventory_item_id   mtl_system_items_b.inventory_item_id%TYPE;
      x_primary_uom_code    mtl_system_items_b.primary_uom_code%TYPE;
      x_pricelist_code      VARCHAR2 (10) := 'PRL';
      x_qual_context        VARCHAR2 (25) := 'CUSTOMER';
      x_qual_attribute      VARCHAR2 (25) := 'QUALIFIER_ATTRIBUTE2';
      x_prod_attribute      VARCHAR2 (25) := 'PRICING_ATTRIBUTE1';

      CURSOR xx_sel_prc_list
      IS
           SELECT name,
                  qlh.list_header_id,
                  operand,
                  qll.list_line_id
             FROM qp_list_headers qlh,
                  qp_list_lines qll,
                  qp_pricing_attributes qpa
            WHERE     qll.list_header_id = qlh.list_header_id
                  AND qll.list_header_id = qpa.list_header_id
                  AND qll.list_line_id = qpa.list_line_id
                  AND qpa.product_attribute = x_prod_attribute
                  AND qpa.product_attr_value = x_inventory_item_id
                  --  AND  TRUNC(x_request_date)   BETWEEN NVL(qll.start_date_active,TRUNC(sysdate))
                  --                                              AND NVL(qll.end_date_active,TRUNC(sysdate))
                  AND TRUNC (x_request_date) BETWEEN NVL (
                                                        qll.start_date_active,
                                                        TRUNC (x_request_date)) -- ADDED FOR #9065
                                                 AND NVL (
                                                        qll.end_date_active,
                                                        TRUNC (x_request_date))
                  AND EXISTS
                         (SELECT 1
                            FROM qp_qualifiers qql
                           WHERE     qql.list_header_id = qlh.list_header_id
                                 AND qualifier_context = x_qual_context
                                 AND qualifier_attribute = x_qual_attribute
                                 AND qualifier_ATTR_VALUE =
                                        xx_line_record.sold_to_org_id
                                 --                 AND  TRUNC(x_request_date)   BETWEEN NVL(start_date_active,TRUNC(sysdate))
                                 --                                                            AND NVL(end_date_active,TRUNC(sysdate))
                                 AND TRUNC (x_request_date) BETWEEN NVL (
                                                                       start_date_active,
                                                                       TRUNC (
                                                                          x_request_date)) -- ADDED FOR #9065
                                                                AND NVL (
                                                                       end_date_active,
                                                                       TRUNC (
                                                                          x_request_date)))
                  --  AND   TRUNC(x_request_date)   BETWEEN NVL(qlh.start_date_active,TRUNC(sysdate))
                  --                                                  AND NVL(qlh.end_date_active,TRUNC(sysdate))
                  AND TRUNC (x_request_date) BETWEEN NVL (
                                                        qlh.start_date_active,
                                                        TRUNC (x_request_date)) -- ADDED FOR #9065
                                                 AND NVL (
                                                        qlh.end_date_active,
                                                        TRUNC (x_request_date))
                  AND list_type_code = x_pricelist_code
                  AND (   global_flag = 'N'
                       OR (    global_flag = 'Y'
                           AND orig_org_id = xx_line_record.org_id))
                  AND active_flag = 'Y'
         ORDER BY NVL (qll.product_precedence, 9999999999);
   BEGIN
      BEGIN
         SELECT ordered_date, attribute11
           INTO x_request_date, x_con_item
           FROM oe_order_headers
          WHERE header_id = xx_line_record.header_id;

         IF x_con_item IS NULL
         THEN
            RETURN NULL;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END;

      BEGIN
         SELECT inventory_item_id, primary_uom_code
           INTO x_inventory_item_id, x_primary_uom_code
           FROM mtl_system_items_b
          WHERE     SEGMENT1 = x_con_item
                AND organization_id =
                       (SELECT organization_id
                          FROM mtl_parameters
                         WHERE master_organization_id = organization_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END;

      FOR xx_sel_prc_list_rec IN xx_sel_prc_list
      LOOP
         /*x_list_price:= XXINTG_PRC_ENG_API(xx_line_record
                                          ,xx_sel_prc_list_rec.list_header_id
                                          ,x_inventory_item_id
                                          ,x_primary_uom_code
                            );*/

         x_list_price := xx_sel_prc_list_rec.operand;

         --dbms_output.put_line('Pricelist Name '||xx_sel_prc_list_rec.name);
         --dbms_output.put_line('List line id '||xx_sel_prc_list_rec.list_line_id);

         IF NVL (x_list_price, 0) > 0
         THEN
            RETURN x_list_price;
         END IF;
      END LOOP;

      RETURN NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END XXINTG_ORD_CONST_ITEM_PRC;
END XXQP_PRICE_CONSTRUCT;
/
