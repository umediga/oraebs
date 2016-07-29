DROP PACKAGE BODY APPS.XX_ASO_PRICE_ALERT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ASO_PRICE_ALERT_PKG" 
----------------------------------------------------------------------
/* $Header: XXASOPRCALRT.pkb 1.0 2012/05/10 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 10-May-2012
 File Name     : XXASOMSRPUPD.pks
 Description   : This script creates the body of the package
                 xx_aso_price_alert_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 10-May-2012  IBM Development Team   Initial Draft.
 01-Aug-2013  Dhiren K Parida        Modified as per the New FS for Wave1
                                     Included logic for Modifier
*/
----------------------------------------------------------------------
 AS
  -- =================================================================================
  -- Name           : xx_aso_prc_alert
  -- Description    : This Function Will Invoked From The HTML Quoting AM Class
  --                  This will check the price protected flag at Price List DFF.
  -- Parameters description       :
  --
  -- p_header_id     : Parameter To Store Quote Header ID (IN)
  -- p_line_id       : Parameter To Store Quote Header ID (IN)
  -- ==============================================================================
  FUNCTION xx_aso_prc_alert(p_header_id NUMBER, p_line_id NUMBER)
    RETURN VARCHAR2 IS
    x_opr_value   VARCHAR2(100);
    x_pl_dff_flag VARCHAR2(100);

    CURSOR c_pl_dff_flag(cp_line_id NUMBER) IS
      SELECT qlh.attribute2 price_flag
        FROM qp_list_headers_b     qlh,
             aso_quote_headers_all aqh,
             aso_quote_lines_all   aql
       WHERE aqh.quote_header_id = aql.quote_header_id
         AND NVL(aql.priced_price_list_id, aqh.price_list_id) =
             qlh.list_header_id
         AND aql.quote_line_id = cp_line_id
         AND qlh.attribute2 IS NOT NULL
      UNION
      select qlh.attribute2 price_flag
        from ASO_OA_PRICE_ADJ_LINE_V aopa, qp_list_headers_all qlh
       where 1 = 1
         and aopa.quote_line_id = cp_line_id
         and aopa.Arithmetic_operator = 'NEWPRICE'
         and aopa.modifier_header_id = qlh.list_header_id
         AND qlh.attribute2 IS NOT NULL
      UNION
      select qll.attribute1 price_flag
        from ASO_OA_PRICE_ADJ_LINE_V aopa, qp_list_lines qll
       where 1 = 1
         and aopa.quote_line_id = cp_line_id
         and aopa.Arithmetic_operator = 'NEWPRICE'
         and aopa.modifier_line_id = qll.list_line_id
         AND qll.attribute1 IS NOT NULL;

  BEGIN

    IF p_line_id IS NOT NULL THEN
      x_pl_dff_flag := 'No';

      OPEN c_pl_dff_flag(p_line_id);

      FETCH c_pl_dff_flag
        INTO x_pl_dff_flag;

      CLOSE c_pl_dff_flag;

      IF NVL(x_pl_dff_flag, 'No') = 'No' THEN
        x_pl_dff_flag := 'No';
      ELSE
        x_pl_dff_flag := 'Yes';
      END IF;

      RETURN x_pl_dff_flag;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'No';
    WHEN OTHERS THEN
      RETURN 'No';
  END xx_aso_prc_alert;

  -- =================================================================================
  -- Name           : xx_aso_org_pl_price
  -- Description    : This Function Will Invoked From The HTML Quoting AM Class
  --                  This will Fetch the List Price For The Item in Quote Line.
  -- Parameters description       :
  --
  -- p_header_id     : Parameter To Store Quote Header ID (IN)
  -- p_line_id       : Parameter To Store Quote Header ID (IN)
  -- ==============================================================================
  FUNCTION xx_aso_org_pl_price(p_header_id NUMBER, p_line_id NUMBER)
    RETURN VARCHAR2 IS
    x_line_price VARCHAR2(100);

    CURSOR c_pl_org_prc(cp_line_id NUMBER) IS
      SELECT aql.line_quote_price
        FROM ---qp_list_headers_b     qlh,
             aso_quote_headers_all aqh,
             aso_quote_lines_all   aql
       WHERE aqh.quote_header_id = aql.quote_header_id
         --AND NVL(aql.priced_price_list_id, aqh.price_list_id) =
         --    qlh.list_header_id
         AND aql.quote_line_id = cp_line_id;



  BEGIN
    x_line_price := 0;

    OPEN c_pl_org_prc(p_line_id);

    FETCH c_pl_org_prc
      INTO x_line_price;

    IF c_pl_org_prc%NOTFOUND THEN
      x_line_price := 0;
    END IF;

    CLOSE c_pl_org_prc;

    RETURN x_line_price;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_line_price := 0;
      RETURN x_line_price;
    WHEN OTHERS THEN
      x_line_price := 0;
      RETURN x_line_price;
  END xx_aso_org_pl_price;

  -- =================================================================================
  -- Name           : xx_aso_org_pl_price
  -- Description    : This Function Will Invoked From The HTML Quoting AM Class
  --                  This will Fetch the List Price For The Item in Quote Line.
  -- Parameters description       :
  --
  -- p_header_id     : Parameter To Store Quote Header ID (IN)
  -- p_line_id       : Parameter To Store Quote Header ID (IN)
  -- ==============================================================================
  FUNCTION xx_aso_org_pl_percent(p_header_id NUMBER, p_line_id NUMBER)
    RETURN VARCHAR2 IS
    x_line_price VARCHAR2(100);

    CURSOR c_pl_org_prc(cp_line_id NUMBER) IS
      SELECT aql.line_adjusted_percent
        FROM ---qp_list_headers_b     qlh,
             aso_quote_headers_all aqh,
             aso_quote_lines_all   aql
       WHERE aqh.quote_header_id = aql.quote_header_id
         --AND NVL(aql.priced_price_list_id, aqh.price_list_id) =
         ---    qlh.list_header_id
         AND aql.quote_line_id = cp_line_id;



  BEGIN
    x_line_price := 0;

    OPEN c_pl_org_prc(p_line_id);

    FETCH c_pl_org_prc
      INTO x_line_price;

    IF c_pl_org_prc%NOTFOUND THEN
      x_line_price := 0;
    END IF;

    CLOSE c_pl_org_prc;

    RETURN x_line_price;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_line_price := 0;
      RETURN x_line_price;
    WHEN OTHERS THEN
      x_line_price := 0;
      RETURN x_line_price;
  END xx_aso_org_pl_percent;


  -- =================================================================================
  -- Name           : xx_aso_org_line_adj_prc
  -- Description    : This Function Will Invoked From The HTML Quoting AM Class
  --                  This will Calculate the Total Price For a Quote Line.
  -- Parameters description       :
  --
  -- p_header_id     : Parameter To Store Quote Header ID (IN)
  -- p_line_id       : Parameter To Store Quote Line ID (IN)
  -- p_qty           : Parameter To Store Quote Line Qty (IN)
  -- p_list_price    : Parameter To Store Quote Line List Price (IN)
  -- ==============================================================================
  FUNCTION xx_aso_org_line_adj_prc(p_header_id  NUMBER,
                                   p_line_id    NUMBER,
                                   p_qty        VARCHAR2,
                                   p_list_price VARCHAR2) RETURN VARCHAR2 IS

    x_line_price VARCHAR2(100);

    CURSOR c_pl_org_prc(cp_line_id NUMBER) IS
      SELECT (aql.line_quote_price * aql.quantity) line_total
        FROM --- qp_list_headers_b     qlh,
             aso_quote_headers_all aqh,
             aso_quote_lines_all   aql
       WHERE aqh.quote_header_id = aql.quote_header_id
         --AND NVL(aql.priced_price_list_id, aqh.price_list_id) =
         --    qlh.list_header_id
         AND aql.quote_line_id = cp_line_id;



  BEGIN

    x_line_price := 0;

    OPEN c_pl_org_prc(p_line_id);

    FETCH c_pl_org_prc
      INTO x_line_price;

    IF c_pl_org_prc%NOTFOUND THEN
      x_line_price := 0;
    END IF;

    CLOSE c_pl_org_prc;

    RETURN(x_line_price);

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;
  END xx_aso_org_line_adj_prc;

END xx_aso_price_alert_pkg;
/
