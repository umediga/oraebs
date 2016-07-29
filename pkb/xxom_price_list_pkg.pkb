DROP PACKAGE BODY APPS.XXOM_PRICE_LIST_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_PRICE_LIST_PKG" 
----------------------------------------------------------------------
/* $Header: XXOMPRICELIST.pkb 1.0 2012/05/02 12:00:00 npanda noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 02-May-2012
 File Name     : XXOMPRICELIST.pkb
 Description   : This script creates the body of the package
                 XXOM_PRICE_LIST_PKG
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 02-May-2012  IBM Development Team   Initial Draft.
*/
-----------------------------------------------------------------------
AS
-- ==========================================================================
-- Fetching Price List Header Dff Context Value From Process Setup Parameter
-- ==========================================================================
  l_context          VARCHAR2 (30) := XX_EMF_PKG.get_paramater_value('XXOMEXT036PL','CONTEXT');
  l_inv_cat          VARCHAR2 (30) := XX_EMF_PKG.get_paramater_value('XXOMEXT036PL','INV_CAT_SET');
  l_sales_mkt_cat    VARCHAR2 (30) := XX_EMF_PKG.get_paramater_value('XXOMEXT036PL','SALES_MKT_CAT_SET');

-- =================================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_price_list
-- Description    : This Function Will Invoked At OM Sales Order Line Form Personalization
--                  This will return Default Price List Name for the Item Entered in
--                  OM Order Line.
--                  If there is no Price for the Item then It will Return Null
-- Parameters description       :
--  IN:
--      p_ship_to_id:   Customer Ship To Org ID
--      p_item_id:      Inventory Item ID
--      p_customer_id:  Customer ID
--      p_org_id:       Operating Unit
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_price_list(p_ship_to_id    IN NUMBER,
                        p_item_id       IN NUMBER,
                        p_customer_id   IN NUMBER,
                        p_org_id        IN NUMBER
                       )
    RETURN VARCHAR2
IS
    x_price_list        VARCHAR2 (240);
    l_price_list        VARCHAR2 (240);
    indx                NUMBER := 0;

  CURSOR ship_to_csr
    IS
    SELECT qh.name
      FROM hz_cust_site_uses_all hcsu,
           qp_list_headers qh,
           qp_list_lines ql,
           qp_pricing_attributes qpa
     WHERE hcsu.site_use_id = p_ship_to_id
       AND hcsu.site_use_code = 'SHIP_TO'
       AND hcsu.status = 'A'
       AND hcsu.price_list_id = qh.list_header_id
       AND qh.list_type_code = 'PRL'
       AND sysdate BETWEEN NVL(qh.start_date_active,sysdate)
                       AND NVL(qh.end_date_active,sysdate+1)
       AND ql.list_line_type_code = 'PLL'
       AND qh.list_header_id = ql.list_header_id
       AND SYSDATE BETWEEN NVL (ql.start_date_active,SYSDATE)
                       AND NVL (ql.end_date_active,SYSDATE + 1)
       AND ql.list_line_id = qpa.list_line_id
       AND qh.list_header_id = qpa.list_header_id
       AND qpa.product_attribute_context = 'ITEM'
       AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
       AND qpa.product_attr_value = p_item_id;

  CURSOR price_list_csr
    IS
           SELECT DISTINCT
                  qh.list_header_id,
                  qh.name,
                  ql.product_precedence,
                  obh.order_number
             FROM qp_list_headers qh,
                  qp_pricing_attributes qpa,
                  qp_list_lines ql,
                  oe_blanket_headers_all obh,
                  oe_blanket_headers_ext bhe
            WHERE qh.list_header_id = obh.price_list_id
              AND obh.org_id = p_org_id
              AND (qh.global_flag = 'Y' OR qh.orig_org_id = p_org_id)
              AND obh.order_number = bhe.order_number
              AND sysdate BETWEEN nvl(bhe.start_date_active,sysdate) AND nvl(bhe.end_date_active,sysdate)
              AND obh.sold_to_org_id = p_customer_id
              AND obh.open_flag = 'Y'
              AND obh.cancelled_flag IS NULL
              AND qh.context = l_context --'Price List Details'
              AND UPPER(qh.attribute4) IN (
                 SELECT DISTINCT UPPER(segment6)
                   FROM mtl_item_categories_v
                  WHERE category_set_name IN (l_inv_cat, l_sales_mkt_cat)--('Inventory','Sales and Marketing')
                    AND inventory_item_id = p_item_id
                    AND organization_id IN (
                               SELECT DISTINCT master_organization_id
                                 FROM mtl_parameters
                                 ))
              AND qh.list_type_code = 'PRL'
              AND ql.list_line_type_code = 'PLL'
              AND qpa.product_attribute_context = 'ITEM'
              AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
              AND SYSDATE BETWEEN NVL (qh.start_date_active, SYSDATE)
                              AND NVL (qh.end_date_active, SYSDATE + 1)
              AND SYSDATE BETWEEN NVL (ql.start_date_active, SYSDATE)
                              AND NVL (ql.end_date_active, SYSDATE + 1)
              AND qh.list_header_id = qpa.list_header_id
              AND qpa.product_attr_value = p_item_id
              AND qh.list_header_id = ql.list_header_id
              AND ql.list_line_id = qpa.list_line_id
            ORDER BY ql.product_precedence,
                     obh.order_number;

 BEGIN
    p_price_list_table.DELETE;

    IF NVL(p_customer_id,-99) <> -99
    THEN

     OPEN ship_to_csr;
     FETCH ship_to_csr INTO x_price_list;
     IF ship_to_csr%NOTFOUND
     THEN
        x_price_list := Null;
     END IF;
	 CLOSE ship_to_csr;


     IF x_price_list IS NULL
      THEN
       FOR i in price_list_csr
        LOOP
         indx := indx + 1;
         p_price_list_table(indx).list_header_id     := i.list_header_id;
         p_price_list_table(indx).name               := i.name;
         p_price_list_table(indx).product_precedence := i.product_precedence;
         p_price_list_table(indx).order_number       := i.order_number;
        END LOOP;
     END IF;

     IF x_price_list IS NOT NULL
      THEN
       l_price_list := x_price_list;
     ELSE
       l_price_list := p_price_list_table(1).name;
     END IF;

    ELSE
      l_price_list := Null;
    END IF;

   RETURN l_price_list;

 EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
 END get_price_list;
-- =================================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_price_list_id
-- Description    : This Function Will Invoked At OM Sales Order Line Form Personalization
--                  This will return Default Price List ID for the Item Entered in
--                  OM Order Line.
--                  If there is no Price for the Item then It will Return Null
-- Parameters description       :
--  IN:
--      p_ship_to_id:   Customer Ship To Org ID
--      p_item_id:      Inventory Item ID
--      p_customer_id:  Customer ID
--      p_org_id:       Operating Unit
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_price_list_id(p_ship_to_id    IN NUMBER,
                           p_item_id       IN NUMBER,
                           p_customer_id   IN NUMBER,
                           p_org_id        IN NUMBER
                          )
    RETURN NUMBER
IS
    x_price_list        NUMBER;
    l_price_list        NUMBER;
    indx                NUMBER := 0;

  CURSOR ship_to_csr
    IS
    SELECT qh.list_header_id
      FROM hz_cust_site_uses_all hcsu,
           qp_list_headers qh,
           qp_list_lines ql,
           qp_pricing_attributes qpa
     WHERE hcsu.site_use_id = p_ship_to_id
       AND hcsu.site_use_code = 'SHIP_TO'
       AND hcsu.status = 'A'
       AND hcsu.price_list_id = qh.list_header_id
       AND qh.list_type_code = 'PRL'
       AND sysdate BETWEEN NVL(qh.start_date_active,sysdate)
                       AND NVL(qh.end_date_active,sysdate+1)
       AND ql.list_line_type_code = 'PLL'
       AND qh.list_header_id = ql.list_header_id
       AND SYSDATE BETWEEN NVL (ql.start_date_active,SYSDATE)
                       AND NVL (ql.end_date_active,SYSDATE + 1)
       AND ql.list_line_id = qpa.list_line_id
       AND qh.list_header_id = qpa.list_header_id
       AND qpa.product_attribute_context = 'ITEM'
       AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
       AND qpa.product_attr_value = p_item_id;

  CURSOR price_list_csr
    IS
           SELECT DISTINCT
                  qh.list_header_id,
                  qh.name,
                  ql.product_precedence,
                  obh.order_number
             FROM qp_list_headers qh,
                  qp_pricing_attributes qpa,
                  qp_list_lines ql,
                  oe_blanket_headers_all obh,
                  oe_blanket_headers_ext bhe
            WHERE qh.list_header_id = obh.price_list_id
              AND obh.org_id = p_org_id
              AND (qh.global_flag = 'Y' OR qh.orig_org_id = p_org_id)
              AND obh.order_number = bhe.order_number
              AND sysdate BETWEEN nvl(bhe.start_date_active,sysdate) AND nvl(bhe.end_date_active,sysdate)
              AND obh.sold_to_org_id = p_customer_id
              AND obh.open_flag = 'Y'
              AND obh.cancelled_flag IS NULL
              AND qh.context = l_context --'Price List Details'
              AND UPPER(qh.attribute4) IN (
                 SELECT DISTINCT UPPER(segment6)
                   FROM mtl_item_categories_v
                  WHERE category_set_name IN (l_inv_cat, l_sales_mkt_cat)--('Inventory','Sales and Marketing')
                    AND inventory_item_id = p_item_id
                    AND organization_id IN (
                               SELECT DISTINCT master_organization_id
                                 FROM mtl_parameters
                                 ))
              AND qh.list_type_code = 'PRL'
              AND ql.list_line_type_code = 'PLL'
              AND qpa.product_attribute_context = 'ITEM'
              AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
              AND SYSDATE BETWEEN NVL (qh.start_date_active, SYSDATE)
                              AND NVL (qh.end_date_active, SYSDATE + 1)
              AND SYSDATE BETWEEN NVL (ql.start_date_active, SYSDATE)
                              AND NVL (ql.end_date_active, SYSDATE + 1)
              AND qh.list_header_id = qpa.list_header_id
              AND qpa.product_attr_value = p_item_id
              AND qh.list_header_id = ql.list_header_id
              AND ql.list_line_id = qpa.list_line_id
            ORDER BY ql.product_precedence,
                     obh.order_number;

 BEGIN
    p_price_list_table.DELETE;

    IF NVL(p_customer_id,-99) <> -99
    THEN

     OPEN ship_to_csr;
     FETCH ship_to_csr INTO x_price_list;
     IF ship_to_csr%NOTFOUND
     THEN
        x_price_list := Null;
     END IF;
	 CLOSE ship_to_csr;

     IF x_price_list IS NULL
      THEN
       FOR i in price_list_csr
        LOOP
         indx := indx + 1;
         p_price_list_table(indx).list_header_id     := i.list_header_id;
         p_price_list_table(indx).name               := i.name;
         p_price_list_table(indx).product_precedence := i.product_precedence;
         p_price_list_table(indx).order_number       := i.order_number;
        END LOOP;
     END IF;

     IF x_price_list IS NOT NULL
      THEN
       l_price_list := x_price_list;
     ELSE
       l_price_list := p_price_list_table(1).list_header_id;
     END IF;

    ELSE
      l_price_list := Null;
    END IF;

   RETURN l_price_list;

 EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
 END get_price_list_id;
-- =================================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_price_list_aso
-- Description    : This Function Will Invoked At ASO Quote Line OAF
--                  This will return Default Price List Name for the Item Entered in
--                  ASO Quote Line.
--                  If there is no Price for the Item then It will Return Null
-- Parameters description       :
--  IN:
--      p_quote_header_id:   Quote Header ID
--      p_item_id:          Inventory Item ID
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_price_list_aso(p_quote_header_id   IN NUMBER,
                            p_item_id           IN NUMBER
                           )
    RETURN VARCHAR2
IS
    l_customer_id       NUMBER;
    l_org_id            NUMBER;
    l_ship_to_id        NUMBER;
    x_price_list        VARCHAR2 (240);
    l_price_list        VARCHAR2 (240);
    indx                NUMBER := 0;

  CURSOR ship_to_csr (p_ship_to_id NUMBER)
    IS
    SELECT qh.name
      FROM hz_cust_site_uses_all hcsu,
           qp_list_headers qh,
           qp_list_lines ql,
           qp_pricing_attributes qpa
     WHERE hcsu.site_use_id = p_ship_to_id
       AND hcsu.site_use_code = 'SHIP_TO'
       AND hcsu.status = 'A'
       AND hcsu.price_list_id = qh.list_header_id
       AND qh.list_type_code = 'PRL'
       AND sysdate BETWEEN NVL(qh.start_date_active,sysdate)
                       AND NVL(qh.end_date_active,sysdate+1)
       AND ql.list_line_type_code = 'PLL'
       AND qh.list_header_id = ql.list_header_id
       AND SYSDATE BETWEEN NVL (ql.start_date_active,SYSDATE)
                       AND NVL (ql.end_date_active,SYSDATE + 1)
       AND ql.list_line_id = qpa.list_line_id
       AND qh.list_header_id = qpa.list_header_id
       AND qpa.product_attribute_context = 'ITEM'
       AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
       AND qpa.product_attr_value = p_item_id;

  CURSOR price_list_csr(p_customer_id NUMBER, p_org_id NUMBER)
    IS
           SELECT DISTINCT
                  qh.list_header_id,
                  qh.name,
                  ql.product_precedence,
                  obh.order_number
             FROM qp_list_headers qh,
                  qp_pricing_attributes qpa,
                  qp_list_lines ql,
                  oe_blanket_headers_all obh,
                  oe_blanket_headers_ext bhe
            WHERE qh.list_header_id = obh.price_list_id
              AND obh.org_id = p_org_id
              AND (qh.global_flag = 'Y' OR qh.orig_org_id = p_org_id)
              AND obh.order_number = bhe.order_number
              AND sysdate BETWEEN nvl(bhe.start_date_active,sysdate) AND nvl(bhe.end_date_active,sysdate)
              AND obh.sold_to_org_id = p_customer_id
              AND obh.open_flag = 'Y'
              AND obh.cancelled_flag IS NULL
              AND qh.context = l_context --'Price List Details'
              AND UPPER(qh.attribute4) IN (
                 SELECT DISTINCT UPPER(segment6)
                   FROM mtl_item_categories_v
                  WHERE category_set_name IN (l_inv_cat, l_sales_mkt_cat)--('Inventory','Sales and Marketing')
                    AND inventory_item_id = p_item_id
                    AND organization_id IN (
                               SELECT DISTINCT master_organization_id
                                 FROM mtl_parameters
                                 ))
              AND qh.list_type_code = 'PRL'
              AND ql.list_line_type_code = 'PLL'
              AND qpa.product_attribute_context = 'ITEM'
              AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
              AND SYSDATE BETWEEN NVL (qh.start_date_active, SYSDATE)
                              AND NVL (qh.end_date_active, SYSDATE + 1)
              AND SYSDATE BETWEEN NVL (ql.start_date_active, SYSDATE)
                              AND NVL (ql.end_date_active, SYSDATE + 1)
              AND qh.list_header_id = qpa.list_header_id
              AND qpa.product_attr_value = p_item_id
              AND qh.list_header_id = ql.list_header_id
              AND ql.list_line_id = qpa.list_line_id
            ORDER BY ql.product_precedence,
                     obh.order_number;

 BEGIN
    p_price_list_table.DELETE;

    SELECT hca.cust_account_id,
           hcsu.site_use_id,
           qh.org_id
      INTO l_customer_id, l_ship_to_id, l_org_id
      FROM aso_quote_headers_all qh,
           hz_cust_accounts hca,
           hz_cust_acct_sites_all hcas,
           hz_cust_site_uses_all hcsu
     WHERE qh.quote_header_id = p_quote_header_id
       AND qh.cust_account_id = hca.cust_account_id
       AND qh.party_id = hca.party_id
       AND hca.cust_account_id = hcas.cust_account_id
       AND hcas.status = 'A'
       AND hcas.ship_to_flag = 'P'
       AND qh.org_id = hcas.org_id
       --AND qh.invoice_to_party_site_id = hcas.party_site_id
       AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
       AND hcsu.site_use_code = 'SHIP_TO'
       AND hcsu.status = 'A'
       AND hcsu.primary_flag = 'Y'
       AND hcsu.org_id = hcas.org_id;

    IF NVL(l_customer_id,-99) <> -99
    THEN

     OPEN ship_to_csr(l_ship_to_id);
     FETCH ship_to_csr INTO x_price_list;
     IF ship_to_csr%NOTFOUND
     THEN
        x_price_list := Null;
     END IF;
	 CLOSE ship_to_csr;


     IF x_price_list IS NULL
      THEN
       FOR i in price_list_csr(l_customer_id, l_org_id)
        LOOP
         indx := indx + 1;
         p_price_list_table(indx).list_header_id     := i.list_header_id;
         p_price_list_table(indx).name               := i.name;
         p_price_list_table(indx).product_precedence := i.product_precedence;
         p_price_list_table(indx).order_number       := i.order_number;
        END LOOP;
     END IF;

     IF x_price_list IS NOT NULL
      THEN
       l_price_list := x_price_list;
     ELSE
       l_price_list := p_price_list_table(1).name;
     END IF;

    ELSE
      l_price_list := Null;
    END IF;

   RETURN l_price_list;

 EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
 END get_price_list_aso;

-- ==============================================================================
-- Name           : XXOM_PRICE_LIST_PKG.get_sales_agreement_num
-- Description    : This Function Will Invoked At OM Sales Order Line Form Personalization
--                  This will return Sales Agreement Number for the Customer and
--                  Item Entered in OM Order Line.
--                  If there is no Sales Agreement for the Customer hen It will
--                  Return Null
-- Parameters description       :
--  IN:
--      p_ship_to_id:   Customer Ship To Org ID
--      p_item_id:      Inventory Item ID
--      p_customer_id:  Customer ID
--      p_org_id:       Operating Unit
--  IN OUT:
--  OUT:
-- ==============================================================================
FUNCTION get_sales_agreement_num(p_ship_to_id    IN NUMBER,
                                 p_item_id       IN NUMBER,
                                 p_customer_id   IN NUMBER,
                                 p_org_id        IN NUMBER
                                )
     RETURN NUMBER
IS
    x_price_list_id     NUMBER;
    l_order_number      NUMBER;
    indx                NUMBER := 0;


  CURSOR ship_to_csr
    IS
    SELECT qh.name
      FROM hz_cust_site_uses_all hcsu,
           qp_list_headers qh,
           qp_list_lines ql,
           qp_pricing_attributes qpa
     WHERE hcsu.site_use_id = p_ship_to_id
       AND hcsu.site_use_code = 'SHIP_TO'
       AND hcsu.price_list_id = qh.list_header_id
       AND qh.list_type_code = 'PRL'
       AND sysdate BETWEEN NVL(qh.start_date_active,sysdate)
                       AND NVL(qh.end_date_active,sysdate+1)
       AND ql.list_line_type_code = 'PLL'
       AND qh.list_header_id = ql.list_header_id
       AND SYSDATE BETWEEN NVL (ql.start_date_active,SYSDATE)
                       AND NVL (ql.end_date_active,SYSDATE + 1)
       AND ql.list_line_id = qpa.list_line_id
       AND qh.list_header_id = qpa.list_header_id
       AND qpa.product_attribute_context = 'ITEM'
       AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
       AND qpa.product_attr_value = p_item_id;

  CURSOR agreement_no_csr
    IS
           SELECT DISTINCT
                  qh.list_header_id,
                  qh.name,
                  ql.product_precedence,
                  obh.order_number
             FROM qp_list_headers qh,
                  qp_pricing_attributes qpa,
                  qp_list_lines ql,
                  oe_blanket_headers_all obh,
                  oe_blanket_headers_ext bhe
            WHERE qh.list_header_id = obh.price_list_id
              AND obh.org_id = p_org_id
              AND (qh.global_flag = 'Y' OR qh.orig_org_id = p_org_id)
              AND obh.order_number = bhe.order_number
              AND sysdate BETWEEN nvl(bhe.start_date_active,sysdate) AND nvl(bhe.end_date_active,sysdate)
              AND obh.sold_to_org_id = p_customer_id
              AND obh.open_flag = 'Y'
              AND obh.cancelled_flag IS NULL
              AND qh.context = l_context --'Price List Details'
              AND UPPER(qh.attribute4) IN (
                 SELECT DISTINCT upper(segment6)
                   FROM mtl_item_categories_v
                  WHERE category_set_name IN (l_inv_cat, l_sales_mkt_cat)--('Inventory','Sales and Marketing')
                    AND inventory_item_id = p_item_id
                    AND organization_id IN (
                               SELECT DISTINCT master_organization_id
                                 FROM mtl_parameters
                                 ))
              AND qh.list_type_code = 'PRL'
              AND ql.list_line_type_code = 'PLL'
              AND qpa.product_attribute_context = 'ITEM'
              AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
              AND SYSDATE BETWEEN NVL (qh.start_date_active, SYSDATE)
                              AND NVL (qh.end_date_active, SYSDATE + 1)
              AND SYSDATE BETWEEN NVL (ql.start_date_active, SYSDATE)
                              AND NVL (ql.end_date_active, SYSDATE + 1)
              AND qh.list_header_id = qpa.list_header_id
              AND qpa.product_attr_value = p_item_id
              AND qh.list_header_id = ql.list_header_id
              AND ql.list_line_id = qpa.list_line_id
            ORDER BY ql.product_precedence,
                     obh.order_number;

 BEGIN
    p_price_list_table.DELETE;

    IF NVL(p_customer_id,-99) <> -99
     THEN

     OPEN ship_to_csr;
     FETCH ship_to_csr INTO x_price_list_id;
     IF ship_to_csr%NOTFOUND
     THEN
        x_price_list_id := Null;
     END IF;
	 CLOSE ship_to_csr;

     IF x_price_list_id IS NULL
      THEN
       FOR i in agreement_no_csr
        LOOP
         indx := indx + 1;
         p_price_list_table(indx).list_header_id     := i.list_header_id;
         p_price_list_table(indx).name               := i.name;
         p_price_list_table(indx).product_precedence := i.product_precedence;
         p_price_list_table(indx).order_number       := i.order_number;
        END LOOP;
     END IF;

     IF x_price_list_id IS NOT NULL
       THEN
       l_order_number := NULL;
     ELSE
       l_order_number := p_price_list_table(1).order_number;
     END IF;

    ELSE
      l_order_number := Null;
    END IF;

   RETURN l_order_number;

 EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
 END get_sales_agreement_num;
END XXOM_PRICE_LIST_PKG;
/
