DROP PACKAGE BODY APPS.XX_OM_PRINT_QUOTE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_PRINT_QUOTE_PKG" 
----------------------------------------------------------------------
/* $Header: XXASOPRINTQOT.pkb 1.0 2012/06/22 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 22-Jun-2012
 File Name      : XXASOPRINTQOT.pkb
 Description    : This script creates the specification of the xx_om_print_quote_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     22-Jun-12   IBM Development Team    Initial development.
 1.1     19-Nov-12   Renjith                 Changes to xx_om_jtf_notes
 1.2     16-Jul-13   Dhiren Parida           Added Logic to fetch Price for Bundled Item , Accessory Item
*/
----------------------------------------------------------------------
 AS
  -- =================================================================================
  -- Name           : xx_om_jtf_notes
  -- Description    : This Function Extract All The Notes For A Given Quote Number .
  -- Parameters description       :
  --
  -- p_quote_id  : Parameter To Quote Id (IN)
  -- ==============================================================================
  FUNCTION xx_om_jtf_notes(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_notes_string VARCHAR2(2400);
  BEGIN
    x_notes_string := NULL;

    SELECT REPLACE(SUBSTR(a.note, 2, length(a.note)), ',', CHR(10))
      INTO x_notes_string
      FROM (SELECT source_object_id,
                   LTRIM(SYS_CONNECT_BY_PATH(notes, ' ,')) note
              FROM (SELECT source_object_id,
                           notes,
                           ROW_NUMBER() OVER(PARTITION BY source_object_id ORDER BY notes) - 1 AS seq
                      FROM jtf_notes_vl
                     WHERE source_object_id = p_quote_id
                       AND note_status_meaning = 'Public'
                       AND source_object_code = 'ASO_QUOTE')
             WHERE CONNECT_BY_ISLEAF = 1
            CONNECT BY seq = PRIOR seq + 1
                   AND source_object_id = PRIOR source_object_id
             START WITH seq = 0) a;

    RETURN(x_notes_string);
  EXCEPTION
    WHEN OTHERS THEN
      x_notes_string := NULL;
      RETURN(x_notes_string);
  END xx_om_jtf_notes;
  ------------------------------------------------
  FUNCTION xx_aso_del_add1(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_addr1 VARCHAR2(2400);
  BEGIN
    x_del_addr1 := NULL;

    SELECT quote_to_locations.address1
      INTO x_del_addr1
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_addr1);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_addr1 := NULL;
      RETURN(x_del_addr1);
  END xx_aso_del_add1;

  ------------------------------------------------
  FUNCTION xx_aso_del_add2(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_addr2 VARCHAR2(2400);
  BEGIN
    x_del_addr2 := NULL;

    SELECT quote_to_locations.address2
      INTO x_del_addr2
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_addr2);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_addr2 := NULL;
      RETURN(x_del_addr2);
  END xx_aso_del_add2;

  ------------------------------------------------
  FUNCTION xx_aso_del_add3(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_addr3 VARCHAR2(2400);
  BEGIN
    x_del_addr3 := NULL;

    SELECT quote_to_locations.address3
      INTO x_del_addr3
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_addr3);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_addr3 := NULL;
      RETURN(x_del_addr3);
  END xx_aso_del_add3;

  ------------------------------------------------
  FUNCTION xx_aso_del_add4(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_addr4 VARCHAR2(2400);
  BEGIN
    x_del_addr4 := NULL;

    SELECT quote_to_locations.address4
      INTO x_del_addr4
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_addr4);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_addr4 := NULL;
      RETURN(x_del_addr4);
  END xx_aso_del_add4;
  ------------------------------------------------
  FUNCTION xx_aso_del_country(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_country VARCHAR2(2400);
  BEGIN
    x_del_country := NULL;

    SELECT quote_to_locations.country
      INTO x_del_country
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_country);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_country := NULL;
      RETURN(x_del_country);
  END xx_aso_del_country;

  ------------------------------------------------
  FUNCTION xx_aso_del_countryname(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_countryname VARCHAR2(2400);
  BEGIN
    x_del_countryname := NULL;

    SELECT i_territories.territory_short_name
      INTO x_del_countryname
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_countryname);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_countryname := NULL;
      RETURN(x_del_countryname);
  END xx_aso_del_countryname;

  ------------------------------------------------
  FUNCTION xx_aso_del_city(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_city VARCHAR2(2400);
  BEGIN
    x_del_city := NULL;

    SELECT decode(quote_to_locations.city,
                  null,
                  '',
                  quote_to_locations.city ||
                  decode(quote_to_locations.county,
                         null,
                         '',
                         ',' || quote_to_locations.county))
      INTO x_del_city
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_city);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_city := NULL;
      RETURN(x_del_city);
  END xx_aso_del_city;

  ------------------------------------------------
  FUNCTION xx_aso_del_county(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_county VARCHAR2(2400);
  BEGIN
    x_del_county := NULL;

    SELECT quote_to_locations.state ||
           decode(quote_to_locations.postal_code,
                  null,
                  '',
                  ' ' || quote_to_locations.postal_code ||
                  decode(quote_to_locations.province,
                         null,
                         '',
                         ',' || quote_to_locations.province))
      INTO x_del_county
      FROM aso_quote_headers aso_quotes,
           hz_party_sites        quote_to_party_sites,
           hz_locations          quote_to_locations,
           fnd_territories_vl    i_territories
     WHERE aso_quotes.end_customer_party_site_id =
           quote_to_party_sites.party_site_id(+)
       AND quote_to_party_sites.location_id =
           quote_to_locations.location_id(+)
       AND quote_to_locations.country = i_territories.territory_code(+)
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_county);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_county := NULL;
      RETURN(x_del_county);
  END xx_aso_del_county;

  --------------------------------------------------

  FUNCTION xx_aso_del_contactname(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_contactname VARCHAR2(2400);
  BEGIN
    x_del_contactname := NULL;

    SELECT I_INVOICE_REL_PARTY.PARTY_NAME
      INTO x_del_contactname
    --I_ACCTS_INV_PARTY.PARTY_NAME deliver_to_cust_party_name
      FROM HZ_RELATIONSHIPS      I_INVOICE_REL,
           HZ_PARTIES            I_INVOICE_REL_PARTY,
           HZ_PARTIES            I_ACCTS_INV_PARTY,
           HZ_RELATIONSHIPS      I_HEADER_CONTACT_REL,
           HZ_PARTIES            I_HEADER_CONTACT_PARTY,
           aso_quote_headers aso_quotes
     WHERE ASO_QUOTES.END_CUSTOMER_CUST_PARTY_ID =
           I_ACCTS_INV_PARTY.PARTY_ID(+)
       AND ASO_QUOTES.END_CUSTOMER_PARTY_ID = I_INVOICE_REL.PARTY_ID(+)
       AND I_INVOICE_REL.SUBJECT_ID = I_INVOICE_REL_PARTY.PARTY_ID(+)
       AND I_INVOICE_REL.SUBJECT_TYPE(+) = 'PERSON'
       AND I_INVOICE_REL.SUBJECT_TABLE_NAME(+) = 'HZ_PARTIES'
       AND i_invoice_rel.object_id(+) =
           aso_quotes.END_CUSTOMER_CUST_PARTY_ID
       AND ASO_QUOTES.END_CUSTOMER_PARTY_ID = I_INVOICE_REL.PARTY_ID(+)
       AND ASO_QUOTES.PARTY_ID = I_HEADER_CONTACT_REL.PARTY_ID(+)
       AND I_HEADER_CONTACT_REL.SUBJECT_ID =
           I_HEADER_CONTACT_PARTY.PARTY_ID(+)
       AND I_HEADER_CONTACT_REL.SUBJECT_TYPE(+) = 'PERSON'
       AND I_HEADER_CONTACT_REL.SUBJECT_TABLE_NAME(+) = 'HZ_PARTIES'
       AND i_header_contact_rel.object_id(+) = aso_quotes.cust_party_id
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_contactname);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_contactname := NULL;
      RETURN(x_del_contactname);
  END xx_aso_del_contactname;
  -----------------------------------------------------------
  FUNCTION xx_aso_del_partyname(p_quote_id IN NUMBER) RETURN VARCHAR2 IS
    x_del_partyname VARCHAR2(2400);
  BEGIN
    x_del_partyname := NULL;

    SELECT I_ACCTS_INV_PARTY.PARTY_NAME
      INTO x_del_partyname
      FROM HZ_RELATIONSHIPS      I_INVOICE_REL,
           HZ_PARTIES            I_INVOICE_REL_PARTY,
           HZ_PARTIES            I_ACCTS_INV_PARTY,
           HZ_RELATIONSHIPS      I_HEADER_CONTACT_REL,
           HZ_PARTIES            I_HEADER_CONTACT_PARTY,
           aso_quote_headers aso_quotes
     WHERE ASO_QUOTES.END_CUSTOMER_CUST_PARTY_ID =
           I_ACCTS_INV_PARTY.PARTY_ID(+)
       AND ASO_QUOTES.END_CUSTOMER_PARTY_ID = I_INVOICE_REL.PARTY_ID(+)
       AND I_INVOICE_REL.SUBJECT_ID = I_INVOICE_REL_PARTY.PARTY_ID(+)
       AND I_INVOICE_REL.SUBJECT_TYPE(+) = 'PERSON'
       AND I_INVOICE_REL.SUBJECT_TABLE_NAME(+) = 'HZ_PARTIES'
       AND i_invoice_rel.object_id(+) =
           aso_quotes.END_CUSTOMER_CUST_PARTY_ID
       AND ASO_QUOTES.END_CUSTOMER_PARTY_ID = I_INVOICE_REL.PARTY_ID(+)
       AND ASO_QUOTES.PARTY_ID = I_HEADER_CONTACT_REL.PARTY_ID(+)
       AND I_HEADER_CONTACT_REL.SUBJECT_ID =
           I_HEADER_CONTACT_PARTY.PARTY_ID(+)
       AND I_HEADER_CONTACT_REL.SUBJECT_TYPE(+) = 'PERSON'
       AND I_HEADER_CONTACT_REL.SUBJECT_TABLE_NAME(+) = 'HZ_PARTIES'
       AND i_header_contact_rel.object_id(+) = aso_quotes.cust_party_id
       AND aso_quotes.quote_header_id = p_quote_id;

    RETURN(x_del_partyname);
  EXCEPTION
    WHEN OTHERS THEN
      x_del_partyname := NULL;
      RETURN(x_del_partyname);
  END xx_aso_del_partyname;

  FUNCTION xx_om_division_cnt(p_quote_id IN NUMBER) RETURN NUMBER IS
    x_rec_count number;
    l_attribute_category varchar2(200);
    l_attribute9  varchar2(200);
    l_attribute11 varchar2(200);
  BEGIN

    x_rec_count := 0;

      SELECT attribute_category,attribute9,attribute11
        INTO l_attribute_category,l_attribute9,l_attribute11
        FROM ASO_QUOTE_HEADERS_ALL
        WHERE quote_header_id = p_quote_id;

      IF (l_attribute_category = 'Long Term_Courtesy_Consignment' AND   l_attribute11 = 'INSTR')
		OR (l_attribute_category = 'Long Term_Courtesy_Consignment' AND   l_attribute11 IS NULL )
      THEN
        x_rec_count := 0;
      ELSIF (l_attribute_category = 'One Time or Contract' AND   l_attribute9 = 'INSTR')
                OR (l_attribute_category = 'One Time or Contract' AND   l_attribute9 IS NULL)
      THEN
        x_rec_count := 0;
      ELSE
        x_rec_count := 1;
      END IF;

      RETURN(x_rec_count);
  EXCEPTION
    WHEN OTHERS THEN
      x_rec_count := 0;
      RETURN(x_rec_count);
  END xx_om_division_cnt;

  FUNCTION xx_om_cap_itm_cnt(p_quote_id IN NUMBER) RETURN NUMBER IS
    x_rec_count number;
    l_attribute_category varchar2(200);
    l_attribute9  varchar2(200);
    l_attribute11 varchar2(200);
  BEGIN
    x_rec_count := 0;
    select count(*)
      into x_rec_count
      from MTL_ITEM_CATEGORIES_V micv, aso_pvt_qte_lines_prnt_bali_v qte
     where micv.inventory_item_id = qte.inventory_item_id
       and qte.quote_header_id = p_quote_id
       and micv.category_set_name in ('Sales and Marketing', 'Inventory')
       and micv.organization_id = qte.organization_id
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
      RETURN(0);
  END xx_om_cap_itm_cnt;

  FUNCTION xx_om_bund_itm_price(p_quote_id IN NUMBER, p_item_id IN NUMBER)
    RETURN NUMBER IS
    x_item_price number;
    x_curr_code  varchar2(100);
  BEGIN

    x_item_price := 0;
    x_curr_code  := Null;

    BEGIN
      Select currency_code
        into x_curr_code
        from aso_quote_headers
       where quote_header_id = p_quote_id;

    EXCEPTION
      WHEN OTHERS THEN
        x_curr_code := Null;
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
            x_item_price := null;
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
    l_cust_account_id    number;
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
      select currency_code,cust_account_id
        into l_curr_code,l_cust_account_id
        from aso_quote_headers
       where quote_header_id = p_hdr_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_curr_code := 'USD';
        l_cust_account_id := 0;
    END;
    commit;

    l_index := 1;
    l_panda_rec_table(l_index).p_line_id := g_line_id;
    l_panda_rec_table(l_index).p_inventory_item_id := p_item_id;
    l_panda_rec_table(l_index).p_qty := 1;
    l_panda_rec_table(l_index).p_request_date := TRUNC(SYSDATE);
    l_panda_rec_table(l_index).p_pricing_date := TRUNC(SYSDATE);
    l_panda_rec_table(l_index).p_uom := l_uom;
    l_panda_rec_table(l_index).p_customer_id := l_cust_account_id;
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

  FUNCTION xx_ava_language(p_lang_code IN VARCHAR2, p_msg_name IN VARCHAR2)
    RETURN NUMBER IS
    x_lang_count NUMBER;
  BEGIN
    x_lang_count := 0;
    select count(*)
      into x_lang_count
      from FND_NEW_MESSAGES
     where message_name = p_msg_name
       and language_code = p_lang_code;

    return(x_lang_count);

  EXCEPTION
    WHEN OTHERS THEN
      x_lang_count := 0;
      return(x_lang_count);
  END xx_ava_language;


END xx_om_print_quote_pkg;
/
