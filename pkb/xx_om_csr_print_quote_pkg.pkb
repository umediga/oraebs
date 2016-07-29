DROP PACKAGE BODY APPS.XX_OM_CSR_PRINT_QUOTE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_CSR_PRINT_QUOTE_PKG" 
----------------------------------------------------------------------
/* $Header: XX_ONTPRINTQOT.pkb 1.0 2013/10/10 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 10-Sep-2013
 File Name      : XX_ONTPRINTQOT.pkb
 Description    : This script creates the body of the xx_om_csr_print_quote_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     10-Sep-13   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
 AS
  FUNCTION xx_om_cap_itm_cnt(p_quote_id IN NUMBER) RETURN NUMBER IS
    x_rec_count number;
  BEGIN
    x_rec_count := 0;

    select count(*)
      into x_rec_count
      from MTL_ITEM_CATEGORIES_V        micv,
           oe_prn_order_lines_v         qte,
           org_organization_definitions ood
     where micv.inventory_item_id = qte.inventory_item_id
       and qte.header_id = p_quote_id
       and micv.category_set_name in ('Sales and Marketing', 'Inventory')
       and ood.organization_code = 'MST'
       and micv.organization_id = ood.organization_id
       and ((micv.segment5 IN
           (select flex_value
                from FND_FLEX_VALUES_VL a, FND_FLEX_VALUE_SETS b
               where a.flex_value_set_id = b.flex_value_set_id
                 and a.flex_value = 'CAPITAL'
                 and b.flex_value_set_name = 'INTG_PRODUCT_CATEGORY'
                 and a.enabled_flag = 'Y')) or
           (micv.segment9 IN
           (select flex_value
                from FND_FLEX_VALUES_VL a, FND_FLEX_VALUE_SETS b
               where a.flex_value_set_id = b.flex_value_set_id
                 and a.flex_value = 'CAPITAL'
                 and b.flex_value_set_name = 'INTG_PRODUCT_TYPE'
                 and a.enabled_flag = 'Y')));

    RETURN(x_rec_count);
  EXCEPTION
    WHEN OTHERS THEN
      x_rec_count := 0;
      RETURN(x_rec_count);
  END xx_om_cap_itm_cnt;

  FUNCTION xx_om_bund_itm_price(p_quote_id IN NUMBER, p_item_id IN NUMBER)
    RETURN NUMBER IS
    x_item_price number;
    x_curr_code  varchar2(100);
  BEGIN

    x_item_price := 0;
    x_curr_code  := Null;

    ---- Derivation requird
    BEGIN
      select transactional_curr_code
        into x_curr_code
        from oe_order_headers
       where header_id = p_quote_id;
    EXCEPTION
      WHEN OTHERS THEN
        x_curr_code := 'USD';
    END;

    BEGIN

      SELECT qll.operand
        into x_item_price
        FROM qp_list_lines         qll,
             qp_list_headers   qlh,
             qp_pricing_attributes qpa
       WHERE 1 = 1
         AND qlh.list_header_id = qll.list_header_id
         AND qlh.name = 'ILS LIST PRICE ' || TO_CHAR(SYSDATE, 'YYYY')
         AND qpa.list_line_id = qll.list_line_id
         AND qpa.product_attr_value = TO_CHAR(p_item_id)
         AND qpa.product_attribute_context = 'ITEM'
         AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
         AND TRUNC(SYSDATE) between
             NVL(qll.start_date_active, TRUNC(sysdate)) and
             NVL(qll.end_date_active, TRUNC(sysdate))
         AND TRUNC(SYSDATE) between
             NVL(qlh.start_date_active, TRUNC(sysdate)) and
             NVL(qlh.end_date_active, TRUNC(sysdate));

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN

          SELECT qll.operand
            into x_item_price
            FROM qp_list_lines         qll,
                 qp_list_headers   qlh,
                 qp_pricing_attributes qpa
           WHERE 1 = 1
             AND qlh.list_header_id = qll.list_header_id
             AND qlh.name =
                 TO_CHAR(SYSDATE, 'YYYY') || '-MSRP-' || x_curr_code
             AND qpa.list_line_id = qll.list_line_id
             AND qpa.product_attr_value = TO_CHAR(p_item_id)
             AND qpa.product_attribute_context = 'ITEM'
             AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
             AND TRUNC(SYSDATE) between
                 NVL(qll.start_date_active, TRUNC(sysdate)) and
                 NVL(qll.end_date_active, TRUNC(sysdate))
             AND TRUNC(SYSDATE) between
                 NVL(qlh.start_date_active, TRUNC(sysdate)) and
                 NVL(qlh.end_date_active, TRUNC(sysdate));

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            x_item_price := 0;
        END;
    END;

    RETURN(x_item_price);

  EXCEPTION
    WHEN OTHERS THEN
      x_item_price := 0;
      RETURN(x_item_price);
  END xx_om_bund_itm_price;

  FUNCTION xx_om_access_itm_price(p_item_id IN NUMBER,
                                  p_org_id  IN NUMBER,
                                  p_cust_id IN NUMBER,
                                  p_hdr_id  IN NUMBER) RETURN NUMBER IS

    -- Variables
    PRAGMA AUTONOMOUS_TRANSACTION;

    l_panda_rec_table    oe_oe_pricing_availability.PANDA_REC_TABLE;
    l_index              number;
    l_enforce_price_flag varchar2(100);
    l_inventory_item_id  number;
    l_uom                varchar2(10);
    l_customer_id        number;
    l_ship_to_org_id     number;
    l_invoice_to_org_id  number;

    g_line_id number := 1244;

    G_req_line_tbl             OE_OE_PRICING_AVAILABILITY.QP_LINE_TBL_TYPE;
    G_Req_line_attr_tbl        OE_OE_PRICING_AVAILABILITY.QP_LINE_ATTR_TBL_TYPE;
    G_Req_LINE_DETAIL_attr_tbl OE_OE_PRICING_AVAILABILITY.QP_LINE_DATTR_TBL_TYPE;
    G_Req_LINE_DETAIL_tbl      OE_OE_PRICING_AVAILABILITY.QP_LINE_DETAIL_TBL_TYPE;
    G_Req_related_lines_tbl    OE_OE_PRICING_AVAILABILITY.QP_RLTD_LINES_TBL_TYPE;
    G_Req_qual_tbl             OE_OE_PRICING_AVAILABILITY.QP_QUAL_TBL_TYPE;
    G_Req_LINE_DETAIL_qual_tbl OE_OE_PRICING_AVAILABILITY.QP_LINE_DQUAL_TBL_TYPE;
    G_child_detail_type        VARCHAR2(30);

    l_out_uom            varchar2(30);
    l_out_currency       varchar2(40);
    l_out_unit_price     number;
    l_out_adjusted_price number;
    l_count              number;
    l_out_tot_price      number;
    l_curr_code          varchar2(100);

    l_item_segment1 varchar2(20);
    l_cust_number   varchar2(30);

  BEGIN
    commit;
    BEGIN
      mo_global.set_policy_context('S', p_org_id);
      commit;
    END;

    l_out_unit_price := 0;

    l_panda_rec_table.delete;
    g_req_line_tbl.delete;
    g_req_line_attr_tbl.delete;
    g_req_LINE_DETAIL_attr_tbl.delete;
    g_req_LINE_DETAIL_tbl.delete;
    g_req_related_lines_tbl.delete;
    g_req_qual_tbl.delete;
    g_req_LINE_DETAIL_qual_tbl.delete;

    ---- Derivation requird
    BEGIN
      SELECT primary_uom_code
        INTO l_uom
        FROM mtl_system_items_b msi
       WHERE inventory_item_id = p_item_id
         AND rownum < 2; --- value will be taken from from input

    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    commit;
    ---- Derivation requird
    BEGIN
      select transactional_curr_code
        into l_curr_code
        from oe_order_headers
       where header_id = p_hdr_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_curr_code := 'USD';
    END;
    commit;
    l_index := 1;
    l_panda_rec_table(l_index).p_line_id := g_line_id;
    l_panda_rec_table(l_index).p_inventory_item_id := p_item_id;
    l_panda_rec_table(l_index).p_qty := 1;
    l_panda_rec_table(l_index).p_request_date := TRUNC(SYSDATE);
    l_panda_rec_table(l_index).p_pricing_date := TRUNC(SYSDATE);
    l_panda_rec_table(l_index).p_uom := l_uom;
    l_panda_rec_table(l_index).p_customer_id := p_cust_id;
    l_panda_rec_table(l_index).p_currency := l_curr_code;

    oe_oe_pricing_availability.pass_values_to_backend(l_panda_rec_table);

    oe_oe_pricing_availability.price_item(out_req_line_tbl             => g_req_line_tbl,
                                          out_Req_line_attr_tbl        => g_req_line_attr_tbl,
                                          out_Req_LINE_DETAIL_attr_tbl => g_req_line_detail_attr_tbl,
                                          out_Req_LINE_DETAIL_tbl      => g_req_line_detail_tbl,
                                          out_Req_related_lines_tbl    => g_req_related_lines_tbl,
                                          out_Req_qual_tbl             => g_req_qual_tbl,
                                          out_Req_LINE_DETAIL_qual_tbl => g_req_line_detail_qual_tbl,
                                          out_child_detail_type        => g_child_detail_type);
    commit;

    FOR i in g_req_line_tbl.first .. g_req_line_tbl.last loop

      IF i = 2 THEN
        l_count              := i;
        l_out_uom            := g_req_line_tbl(i).priced_uom_code;
        l_out_currency       := g_req_line_tbl(i).currency_code;
        l_out_unit_price     := g_req_line_tbl(i).unit_price;
        l_out_adjusted_Price := g_req_line_tbl(i).adjusted_unit_price;
        l_out_tot_price      := g_req_line_tbl(i)
                               .adjusted_unit_price * g_req_line_tbl(i)
                               .line_quantity;
      END IF;

      DBMS_OUTPUT.PUT_LINE(l_count || l_out_uom || l_out_currency ||
                           l_out_unit_price || l_out_adjusted_Price || g_req_line_tbl

                           (i).line_quantity || l_out_tot_price);

    END LOOP;

    RETURN(l_out_unit_price);

  EXCEPTION
    WHEN OTHERS THEN
      l_out_unit_price := 0;
      RETURN(l_out_unit_price);

  END xx_om_access_itm_price;

END xx_om_csr_print_quote_pkg;
/
