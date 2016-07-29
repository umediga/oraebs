DROP PACKAGE BODY APPS.XX_OM_ADMIN_FEES_CAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XX_OM_ADMIN_FEES_CAL_PKG AS
/*
  Created By     : Sharath Babu
  Creation Date  : 18-ARP-2014
  Filename       : XX_OM_ADMIN_FEES_CAL_PKG.pkb
  Description    : Admin fee report
  Change History:
  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  18-Apr-2014   1.0       Sharath Babu        Initial development.
  07-AUG-2014   2.0       Vighnesh            rearranged the query in  XX_GPO_ENTITY_CODE function.
  11-FEB-2016   3.0       Vinod               Case 9558: When looking for modifier or price list, only look for active ones. Report is currently displaying
                                              inactive modifiers
  */
  --------------------------------------------------------------------------------

FUNCTION XX_START_DATE(p_cust_acc_id NUMBER)
RETURN DATE
AS
  x_att7 VARCHAR2(1000);
  x_start_date DATE;
  x_cust_acc_id NUMBER;

BEGIN

    BEGIN
      SELECT start_date_active
      INTO x_start_date
      FROM qp_qualifiers
      WHERE list_header_id = G_PRICE_LIST_ID
      and qualifier_context = 'CUSTOMER'
      and qualifier_attr_value = p_cust_acc_id;
    EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
     END;
     IF x_start_date IS NULL THEN
     BEGIN
        SELECT start_date_active
        INTO x_start_date
        FROM qp_list_headers
        WHERE list_header_id = G_PRICE_LIST_ID;
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
      END;
        RETURN x_start_date;
      END IF;
      RETURN x_start_date;
EXCEPTION
  WHEN OTHERS THEN
   RETURN NULL;
END;

FUNCTION XX_EXPIRATION_DATE(p_cust_acc_id NUMBER)
RETURN DATE
AS
  x_att7 VARCHAR2(1000);
  x_end_date DATE;
  x_cust_acc_id NUMBER;

BEGIN


  BEGIN
      SELECT end_date_active
      INTO x_end_date
      FROM qp_qualifiers
      WHERE list_header_id = G_PRICE_LIST_ID
      and qualifier_context = 'CUSTOMER'
      and qualifier_attr_value = p_cust_acc_id;
    EXCEPTION
         WHEN OTHERS THEN
          RETURN NULL;
     END;
     IF x_end_date IS NULL THEN
   BEGIN
        SELECT end_date_active
        INTO x_end_date
        FROM qp_list_headers
        WHERE list_header_id = G_PRICE_LIST_ID;
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
      END;
        RETURN x_end_date;
      END IF;
        RETURN x_end_date;
EXCEPTION
  WHEN OTHERS THEN
   RETURN NULL;

END;

FUNCTION XX_LIST_PRICE_CAL(p_header_id NUMBER ,p_line_id NUMBER, p_price_list_id NUMBER, p_in_price_list VARCHAR2, p_inv_item_id NUMBER)
RETURN NUMBER
AS
x_list_header_id qp_list_headers.list_header_id%TYPE;
x_header_id oe_order_lines_all.header_id%TYPE;
x_price_list_id oe_order_lines_all.price_list_id%TYPE;
x_attr7 qp_list_headers.attribute7%TYPE;
x_list_price qp_list_lines.list_price%TYPE;

begin
  x_header_id := p_header_id;

  IF (p_in_price_list IS NOT NULL ) THEN

    BEGIN
        SELECT qll.operand
        INTO x_list_price
      FROM qp_list_lines qll , QP_PRICING_ATTRIBUTES qpa , qp_list_headers qlh
      WHERE qlh.name =p_in_price_list
      AND qlh.list_header_id = qll.list_header_id
      AND qll.list_line_id = qpa.list_line_id
      AND qpa.product_attr_value = to_char(p_inv_item_id);
    EXCEPTION
        WHEN OTHERS THEN
         RETURN 0;
    END;
           RETURN x_list_price;

  ELSIF (p_in_price_list IS NULL ) THEN
    BEGIN
        SELECT unit_list_price
        INTO x_list_price
        FROM oe_order_lines_all ool
        WHERE price_list_id = p_price_list_id
          AND ool.header_id = x_header_id
          AND ool.line_id = p_line_id;
      EXCEPTION
        WHEN OTHERS THEN
           RETURN 0;
      END;

      RETURN x_list_price;

  END IF;
EXCEPTION
        WHEN OTHERS THEN
         RETURN 0;
END;
FUNCTION XX_GPO_PRICE_LIST
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_price_list_name qp_list_headers.name%TYPE;

BEGIN

      select name
      into x_price_list_name
      from qp_list_headers qlh
      where qlh.list_header_id = G_PRICE_LIST_ID
      AND NVL(qlh.active_flag,'N') = 'Y'
      AND TRUNC(SYSDATE) BETWEEN NVL(qlh.start_date_active, TRUNC(SYSDATE)) AND NVL(qlh.end_date_active, TRUNC(SYSDATE)) ; -- 9558

      RETURN x_price_list_name;
EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;

 END;

FUNCTION XX_GPO_LIST_PRICE(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER, p_inv_item_id NUMBER)
RETURN NUMBER
AS
l_operand NUMBER := 0;
BEGIN
      SELECT qll.operand
      into l_operand
      FROM QP_LIST_LINES QLL , QP_PRICING_ATTRIBUTES QPA , QP_LIST_HEADERS QLH
      WHERE qlh.name = XX_GPO_PRICE_LIST
      AND NVL(qlh.active_flag,'N') = 'Y'
      AND TRUNC(SYSDATE) BETWEEN NVL(qlh.start_date_active, TRUNC(SYSDATE)) AND NVL(qlh.end_date_active, TRUNC(SYSDATE)) -- 9558
      AND qlh.list_header_id = qll.list_header_id
      AND TRUNC(SYSDATE) BETWEEN NVL(qll.start_date_active, TRUNC(SYSDATE)) AND NVL(qll.end_date_active, TRUNC(SYSDATE)) -- 9558
      AND QLL.LIST_LINE_ID = QPA.LIST_LINE_ID
      AND qpa.product_attr_value = p_inv_item_id;

      RETURN l_operand;
EXCEPTION
WHEN OTHERS THEN
     RETURN 0;
END;

FUNCTION XX_DISCOUNT_CAL(p_header_id NUMBER ,p_line_id NUMBER, p_price_list_id NUMBER, p_in_price_list VARCHAR2)
RETURN NUMBER
AS
x_list_header_id qp_list_headers.list_header_id%TYPE;
x_header_id oe_order_lines_all.header_id%TYPE;
x_price_list_id oe_order_lines_all.price_list_id%TYPE;
x_attr7 qp_list_headers.attribute7%TYPE;
x_list_price qp_list_lines.list_price%TYPE;
x_price oe_order_lines_all.unit_selling_price%TYPE;
x_discount NUMBER;

begin
  x_header_id := p_header_id;

  IF (p_in_price_list IS NOT NULL ) THEN

    BEGIN
        SELECT list_header_id
        INTO x_list_header_id
      FROM qp_list_headers qlh
      WHERE qlh.name =p_in_price_list;
    EXCEPTION
         WHEN OTHERS THEN
         RETURN 0;
    END;

    BEGIN

        SELECT price_list_id
        INTO x_price_list_id
        FROM oe_order_lines_all ool
        WHERE ool.price_list_id = x_list_header_id
         AND ool.header_id = x_header_id
         AND ool.line_id = p_line_id;

    EXCEPTION
         WHEN OTHERS THEN
         RETURN 0;
    END;

    BEGIN

            SELECT unit_list_price
            INTO x_list_price
            FROM oe_order_lines_all ool
            WHERE price_list_id = x_price_list_id
              AND ool.header_id = x_header_id
              AND ool.line_id = p_line_id;
        EXCEPTION
          WHEN OTHERS THEN
           RETURN 0;
      END;

      BEGIN

        SELECT unit_selling_price
        INTO x_price
        FROM oe_order_lines_all ool
        WHERE ool.header_id = x_header_id
          AND ool.line_id = p_line_id;
      EXCEPTION
        WHEN OTHERS THEN
           RETURN 0;
      END;

      x_discount := x_list_price-x_price;

      RETURN x_discount;

  ELSIF (p_in_price_list IS NULL ) THEN
    BEGIN
        SELECT unit_list_price
        INTO x_list_price
        FROM oe_order_lines_all ool
        WHERE price_list_id = p_price_list_id
          AND ool.header_id = x_header_id
          AND ool.line_id = p_line_id;
      EXCEPTION
        WHEN OTHERS THEN
           RETURN 0;
      END;

      BEGIN

             SELECT unit_selling_price
             INTO x_price
             FROM oe_order_lines_all ool
            WHERE ool.header_id = x_header_id
              AND ool.line_id = p_line_id;
           EXCEPTION
             WHEN OTHERS THEN
               RETURN 0;
           END;

           x_discount := x_list_price-x_price;

            RETURN x_discount;


  END IF;
EXCEPTION
        WHEN OTHERS THEN
           RETURN 0;
END;
FUNCTION XX_PERCENTAGE
RETURN VARCHAR
AS

x_attr_7 qp_list_headers.attribute7%TYPE;
x_attr_10 qp_list_headers.attribute10%TYPE;

BEGIN

 BEGIN
      SELECT qlh.attribute10
      INTO x_attr_10
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = G_PRICE_LIST_ID;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr_10;
 EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
END;

FUNCTION XX_DIVISION
RETURN VARCHAR
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr4 qp_list_headers.attribute4%TYPE;
BEGIN

 BEGIN
      SELECT qlh.attribute4
      INTO x_attr4
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = G_PRICE_LIST_ID;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr4;
 EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
 END;
FUNCTION XX_CONTRACT_NUMBER
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr11 qp_list_headers.attribute11%TYPE;

BEGIN

   BEGIN
      SELECT qlh.attribute11
      INTO x_attr11
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = G_PRICE_LIST_ID;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr11;
EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
 END;

FUNCTION XX_ADMIN_FEE_PAYMENT
RETURN VARCHAR
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr5 qp_list_headers.attribute5%TYPE;

BEGIN

 BEGIN
      SELECT qlh.attribute5
      INTO x_attr5
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = G_PRICE_LIST_ID;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr5;
EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
 END;
FUNCTION XX_GPO_IDN_NAME(p_price_list_id NUMBER)
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr3 qp_list_headers.attribute3%TYPE;

BEGIN
   BEGIN
      SELECT qlh.attribute3
      INTO x_attr3
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr3;
 EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
 END;

FUNCTION XX_GPO_ENTITY_CODE(p_gpo VARCHAR2, p_site_id NUMBER)
 RETURN VARCHAR
 AS
    l_name      VARCHAR2(100);
    l_code      VARCHAR2(3);
    l_ecode     VARCHAR2(100);
    l_sc_pos    NUMBER;
    l_gpo_code  VARCHAR2(100);
 BEGIN
   -- l_name := XX_OM_ADMIN_FEES_CAL_PKG.XX_GPO_IDN_NAME(p_price_list_id);


      l_name := p_gpo;

   ----interchanged the first two queries for  ticket #8582-----

    select attribute1
    into l_ecode
    from hz_cust_acct_sites_all
    where cust_acct_site_id = p_site_id;


    select lookup_code
    into l_code
    from  fnd_lookup_values
    where lookup_type =   'INTG_GPO_ABBREV_MAPPING'
    and language = 'US'
    and enabled_flag = 'Y'
    and meaning = l_name;


    IF instr(l_ecode,l_code) >= 1 THEN
        select decode(instr(substr(l_ecode,instr(l_ecode,l_code)+4),';'),0,length(l_ecode),instr(substr(l_ecode,instr(l_ecode,l_code)+4),';'))
        into l_sc_pos
        from dual;

        select substr(l_ecode,instr(l_ecode,l_code)+4,l_sc_pos -1 )
        into l_gpo_code
        from dual;
        return (l_gpo_code);
    ELSE
        return (l_ecode);
    END IF;

 EXCEPTION
 WHEN OTHERS THEN
    return (l_ecode);
 END;

FUNCTION XX_GPO_PARTY_NAME(p_price_list_id NUMBER)
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr3 qp_list_headers.attribute3%TYPE;

BEGIN

     BEGIN
      SELECT qlh.attribute3
      INTO x_attr3
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr3;
    EXCEPTION
      WHEN OTHERS THEN
           RETURN NULL;
 END;

FUNCTION XX_LINE_PRICE_LIST(p_price_list_id NUMBER)
RETURN VARCHAR2
IS
x_line_price_list qp_list_headers.name%TYPE;
BEGIN
            SELECT name
            INTO x_line_price_list
            FROM qp_list_headers
            WHERE list_header_id = p_price_list_id;

        RETURN x_line_price_list;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
            WHEN OTHERS THEN
              RETURN NULL;
          END;

 /*

 FUNCTION XX_PRICE_LIST_CHK(p_price_list_id NUMBER,p_cust_site_use_id NUMBER, p_cust_acc_id NUMBER)
RETURN VARCHAR2
AS
x_cnt_price_list_id NUMBER := 0;
x_price_list_chk VARCHAR2(10) := 'Y' ;
BEGIN

     BEGIN
      SELECT count(price_list_id)
      INTO x_cnt_price_list_id
      FROM hz_cust_site_uses_all hcua
      WHERE hcua.site_use_id = p_cust_site_use_id
      AND hcua.price_list_id =  p_price_list_id;

       EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
     END;

      IF x_cnt_price_list_id > 0
       then
        x_price_list_chk := 'Y' ;
       else
         BEGIN
         SELECT count(price_list_id)
             INTO x_cnt_price_list_id
             FROM hz_cust_accounts hca
             WHERE hca.cust_account_id =p_cust_acc_id
             AND hca.price_list_id =  p_price_list_id;

      EXCEPTION
            WHEN OTHERS THEN
          RETURN NULL;
          END;

       IF x_cnt_price_list_id > 0
       then
        x_price_list_chk := 'Y' ;
       else
         x_price_list_chk := 'N';
       END IF;
     end if;
          RETURN x_price_list_chk;
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
END;
*/

 FUNCTION XX_PRICE_LIST_CHK(p_cust_site_use_id NUMBER, p_cust_acc_id NUMBER , p_attr4 VARCHAR2, p_attr7 VARCHAR2,p_attr3 VARCHAR2,
                            p_attr11 VARCHAR2 , p_inv_id NUMBER)
RETURN VARCHAR2
AS
x_cnt_price_list_id NUMBER := 0;
x_price_list_chk VARCHAR2(10) := 'N' ;
x_site_price_list_id NUMBER;
x_acct_price_list_id NUMBER;
x_cust_acc_id NUMBER;
x_cnt_item NUMBER := 0;
x_item_flag VARCHAR2(10) := 'N';
CURSOR c_secondary_price_list_site (cp_cust_site_use_id NUMBER )
  IS
    SELECT qspl.list_header_id
    from qp_secondary_price_lists_v qspl,
        hz_cust_site_uses_all hcua
    where qspl.parent_price_list_id = to_char(hcua.price_list_id)
    AND hcua.site_use_id = cp_cust_site_use_id;

 CURSOR c_secondary_price_list_acct (cp_cust_acc_id NUMBER )
  IS
    SELECT qspl.list_header_id
    from qp_secondary_price_lists_v qspl,
        hz_cust_accounts hca
    where qspl.parent_price_list_id = to_char(hca.price_list_id)
    AND hca.cust_account_id = cp_cust_acc_id;

CURSOR c_price_list (cp_attr4 VARCHAR2, cp_attr7 VARCHAR2, cp_attr3 VARCHAR2, cp_attr11 VARCHAR2)
  IS
    SELECT list_header_id
    from qp_list_headers
    where attribute4 = cp_attr4
    and attribute7 = cp_attr7
    and attribute3 = nvl(cp_attr3 , attribute3)
    and attribute11 = nvl(cp_attr11 , attribute11)
    and LIST_TYPE_CODE = 'PRL'
    AND NVL(active_flag,'N') = 'Y'
    AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND NVL(end_date_active, TRUNC(SYSDATE));   -- 9558

BEGIN

  G_PRICE_LIST_ID := NULL ; -- 9558

     BEGIN
      SELECT price_list_id
      INTO x_site_price_list_id
      FROM hz_cust_site_uses_all hcua
      WHERE hcua.site_use_id = p_cust_site_use_id;
     -- AND hcua.price_list_id =  p_price_list_id;

      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
     END;

      IF (x_site_price_list_id IS NOT NULL and x_price_list_chk = 'N' )
       then
    BEGIN
        select count(list_header_id)
          into x_cnt_price_list_id
            from qp_list_headers
           where attribute4 = p_attr4
            and attribute7 = p_attr7
            and attribute3 = p_attr3
            and attribute11 = nvl(p_attr11 , attribute11)
            and list_header_id = x_site_price_list_id
            and LIST_TYPE_CODE = 'PRL'
            AND NVL(active_flag,'N') = 'Y'
            AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND NVL(end_date_active, TRUNC(SYSDATE)) ;   -- 9558

     EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
     END;
             if x_cnt_price_list_id > 0 then
             if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,x_site_price_list_id) = 'Y') then
            x_price_list_chk := 'Y' ;
            G_PRICE_LIST_ID := x_site_price_list_id;
            end if;
         else
-- search for secondary price list starts
    for rec_secondary_price_list_site IN c_secondary_price_list_site (p_cust_site_use_id) loop
       for rec_price_list IN c_price_list (p_attr4 ,p_attr7 ,p_attr3 ,p_attr11) loop
        if ( rec_secondary_price_list_site.list_header_id = rec_price_list.list_header_id ) then
             if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,rec_price_list.list_header_id) = 'Y') then
             x_price_list_chk := 'Y' ;
         G_PRICE_LIST_ID := rec_price_list.list_header_id;
--            else
--               x_price_list_chk := 'N' ;
             end if;
            end if;
          end loop;
     end loop;
     if x_price_list_chk = 'Y'  then
       RETURN x_price_list_chk;
     end if;
     end if;
-- search for secondary price list ends
     elsif (x_site_price_list_id IS NULL and x_price_list_chk = 'N' ) then
         BEGIN
         SELECT price_list_id
             INTO x_acct_price_list_id
             FROM hz_cust_accounts hca
             WHERE hca.cust_account_id = p_cust_acc_id;
            -- AND hca.price_list_id =  p_price_list_id;

      EXCEPTION
            WHEN OTHERS THEN
          RETURN NULL;
          END;

       IF (x_acct_price_list_id IS NOT NULL and x_price_list_chk = 'N' )
       then
    BEGIN
        select count(list_header_id)
          into x_cnt_price_list_id
            from qp_list_headers
           where attribute4 = p_attr4
            and attribute7 = p_attr7
            and attribute3 = p_attr3
            and attribute11 = nvl(p_attr11 , attribute11)
            and list_header_id = x_acct_price_list_id
            and LIST_TYPE_CODE = 'PRL'
            AND NVL(active_flag,'N') = 'Y'
            AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND NVL(end_date_active, TRUNC(SYSDATE)) ; --9558

     EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
     END;
             if x_cnt_price_list_id > 0 then
             if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,x_acct_price_list_id) = 'Y') then
            x_price_list_chk := 'Y' ;
            G_PRICE_LIST_ID := x_acct_price_list_id;
            end if;
         else

 -- search for secondary price list starts
    for rec_secondary_price_list_acct IN c_secondary_price_list_acct (p_cust_acc_id) loop
       for rec_price_list IN c_price_list (p_attr4 ,p_attr7 ,p_attr3 ,p_attr11) loop
        if ( rec_secondary_price_list_acct.list_header_id = rec_price_list.list_header_id ) then
            if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,rec_price_list.list_header_id) = 'Y') then
             x_price_list_chk := 'Y' ;
           G_PRICE_LIST_ID := rec_price_list.list_header_id;
       --     else
     --          x_price_list_chk := 'N' ;
         end if;
        end if;
          end loop;
     end loop;
       end if;
       -- find pice list for ship to account if bill to account dont have price list -- starts
       elsif (x_acct_price_list_id IS NULL and x_price_list_chk = 'N' ) then

    BEGIN

       select cust_account_id
         INTO x_cust_acc_id
          from hz_cust_acct_sites_all hcsa , hz_cust_site_uses_all hcua
          where hcsa.cust_acct_site_id = hcua.cust_acct_site_id
              and hcua.site_use_id = p_cust_site_use_id;

          SELECT price_list_id
             INTO x_acct_price_list_id
             FROM hz_cust_accounts hca
             WHERE hca.cust_account_id = x_cust_acc_id;

      EXCEPTION
            WHEN OTHERS THEN
          RETURN NULL;
          END;
          IF (x_acct_price_list_id IS NOT NULL and x_price_list_chk = 'N' )
            then
           BEGIN
        select count(list_header_id)
          into x_cnt_price_list_id
            from qp_list_headers
           where attribute4 = p_attr4
            and attribute7 = p_attr7
            and attribute3 = p_attr3
            and attribute11 = nvl(p_attr11 , attribute11)
            and list_header_id = x_acct_price_list_id
            and LIST_TYPE_CODE = 'PRL'
            AND NVL(active_flag,'N') = 'Y'
            AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND NVL(end_date_active, TRUNC(SYSDATE)) ;   -- 9558

     EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
     END;

         if x_cnt_price_list_id > 0 then
             if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,x_acct_price_list_id) = 'Y') then
            x_price_list_chk := 'Y' ;
            G_PRICE_LIST_ID := x_acct_price_list_id;
            end if;
         else

 -- search for secondary price list starts
    for rec_secondary_price_list_acct IN c_secondary_price_list_acct (x_cust_acc_id) loop
       for rec_price_list IN c_price_list (p_attr4 ,p_attr7 ,p_attr3 ,p_attr11) loop
        if ( rec_secondary_price_list_acct.list_header_id = rec_price_list.list_header_id ) then
            if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,rec_price_list.list_header_id) = 'Y') then
             x_price_list_chk := 'Y' ;
           G_PRICE_LIST_ID := rec_price_list.list_header_id;
       --     else
     --          x_price_list_chk := 'N' ;
         end if;
        end if;
          end loop;
     end loop;
       end if;
              -- find pice list for ship to account if bill to account dont have price list -- ends
       end if;
       end if;
       END IF;
          RETURN x_price_list_chk;
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
END;

 FUNCTION XX_PRICE_LIST_QUAL_CHK(p_cust_acc_id NUMBER , p_attr4 VARCHAR2, p_attr7 VARCHAR2,p_attr3 VARCHAR2,p_attr11 VARCHAR2,p_inv_id NUMBER,p_ord_item VARCHAR2)
RETURN VARCHAR2
AS
x_cnt_price_list_id NUMBER := 0;
x_price_list_chk VARCHAR2(10) := 'N' ;

CURSOR c_cust_price_mod (cp_cust_acc_id NUMBER , cp_attr4 VARCHAR2, cp_attr7 VARCHAR2,cp_attr3 VARCHAR2,cp_attr11 VARCHAR2)
  IS
    SELECT ql.list_header_id , qhl.LIST_TYPE_CODE
      FROM qp_qualifiers  ql , qp_list_headers qhl
      WHERE ql.list_header_id = qhl.list_header_id
      AND ql.qualifier_context = 'CUSTOMER'
      AND ql.QUALIFIER_ATTRIBUTE= 'QUALIFIER_ATTRIBUTE2'
      AND ql.qualifier_attr_value = cp_cust_acc_id
      AND qhl.attribute4 = cp_attr4
      and qhl.attribute7 = cp_attr7
      and qhl.attribute3 = cp_attr3
      and qhl.attribute11 = nvl(cp_attr11 , qhl.attribute11)
      AND NVL(qhl.active_flag,'N') = 'Y'
      AND TRUNC(SYSDATE) BETWEEN NVL(qhl.start_date_active, TRUNC(SYSDATE)) AND NVL(qhl.end_date_active, TRUNC(SYSDATE)); -- 9558

CURSOR c_ship_price_mod (cp_cust_acc_id NUMBER , cp_attr4 VARCHAR2, cp_attr7 VARCHAR2,cp_attr3 VARCHAR2,cp_attr11 VARCHAR2)
  IS
    SELECT ql.list_header_id , qhl.LIST_TYPE_CODE
      FROM qp_qualifiers  ql , qp_list_headers qhl
      WHERE ql.list_header_id = qhl.list_header_id
      AND ql.qualifier_context = 'SHIP_TO_CUST '
      AND ql.QUALIFIER_ATTRIBUTE= 'QUALIFIER_ATTRIBUTE40'
      AND ql.qualifier_attr_value = cp_cust_acc_id
      AND qhl.attribute4 = cp_attr4
      and qhl.attribute7 = cp_attr7
      and qhl.attribute3 = cp_attr3
      and qhl.attribute11 = nvl(cp_attr11 , qhl.attribute11)
      AND NVL(qhl.active_flag,'N') = 'Y'
      AND TRUNC(SYSDATE) BETWEEN NVL(qhl.start_date_active, TRUNC(SYSDATE)) AND NVL(qhl.end_date_active, TRUNC(SYSDATE)); -- 9558

BEGIN

     G_PRICE_LIST_ID := NULL ; -- 9558


     BEGIN

      SELECT count(ql.list_header_id)
      INTO x_cnt_price_list_id
      FROM qp_qualifiers  ql , qp_list_headers qhl
      WHERE ql.list_header_id = qhl.list_header_id
      AND ql.qualifier_context = 'CUSTOMER'
      AND ql.QUALIFIER_ATTRIBUTE= 'QUALIFIER_ATTRIBUTE2'
      AND ql.qualifier_attr_value = p_cust_acc_id
      AND qhl.attribute4 = p_attr4
      and qhl.attribute7 = p_attr7
      and qhl.attribute3 = p_attr3
      and qhl.attribute11 = nvl(p_attr11 , qhl.attribute11)
      AND NVL(qhl.active_flag,'N') = 'Y'
      AND TRUNC(SYSDATE) BETWEEN NVL(qhl.start_date_active, TRUNC(SYSDATE)) AND NVL(qhl.end_date_active, TRUNC(SYSDATE));

       EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
     END;

      IF x_cnt_price_list_id > 0 then
            for rec_c_cust_price_mod IN c_cust_price_mod (p_cust_acc_id,p_attr4, p_attr7,p_attr3,p_attr11) loop
        if (rec_c_cust_price_mod.LIST_TYPE_CODE = 'PRL') then
          if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,rec_c_cust_price_mod.list_header_id) = 'Y') then
               x_price_list_chk := 'Y' ;
               G_PRICE_LIST_ID := rec_c_cust_price_mod.list_header_id;
          end if;
        else
           if (XX_OM_ADMIN_FEES_CAL_PKG.XX_MOD_PROD_CHK(p_inv_id,rec_c_cust_price_mod.list_header_id) = 'Y') then
                 x_price_list_chk := 'Y' ;
            G_PRICE_LIST_ID := rec_c_cust_price_mod.list_header_id;
        end if;
        end if;
        end loop;
       else
         BEGIN
         SELECT count(ql.list_header_id)
         INTO x_cnt_price_list_id
         FROM qp_qualifiers ql, qp_list_headers qhl
         WHERE ql.list_header_id = qhl.list_header_id
         AND ql.qualifier_context = 'SHIP_TO_CUST '
         AND ql.QUALIFIER_ATTRIBUTE= 'QUALIFIER_ATTRIBUTE40'
         AND ql.qualifier_attr_value = p_cust_acc_id
     AND qhl.attribute4 = p_attr4
         and qhl.attribute7 = p_attr7
         and qhl.attribute3 = p_attr3
         and qhl.attribute11 = nvl(p_attr11 , qhl.attribute11)
         AND NVL(qhl.active_flag,'N') = 'Y'
         AND TRUNC(SYSDATE) BETWEEN NVL(qhl.start_date_active, TRUNC(SYSDATE)) AND NVL(qhl.end_date_active, TRUNC(SYSDATE));

      EXCEPTION
            WHEN OTHERS THEN
          RETURN NULL;
          END;

       IF x_cnt_price_list_id > 0
       then
        for rec_c_ship_price_mod IN c_ship_price_mod (p_cust_acc_id,p_attr4, p_attr7,p_attr3,p_attr11) loop
        if (rec_c_ship_price_mod.LIST_TYPE_CODE = 'PRL') then
          if (XX_OM_ADMIN_FEES_CAL_PKG.XX_PRICE_LIST_PROD_CHK(p_inv_id,rec_c_ship_price_mod.list_header_id) = 'Y') then
               x_price_list_chk := 'Y' ;
               G_PRICE_LIST_ID := rec_c_ship_price_mod.list_header_id;
          end if;
        else
           if (XX_OM_ADMIN_FEES_CAL_PKG.XX_MOD_PROD_CHK(p_inv_id,rec_c_ship_price_mod.list_header_id) = 'Y') then
                 x_price_list_chk := 'Y' ;
             G_PRICE_LIST_ID := rec_c_ship_price_mod.list_header_id;
        end if;
        end if;
        end loop;
       else
         x_price_list_chk := 'N';
       END IF;
        END IF;
     RETURN x_price_list_chk;
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
END;
FUNCTION  XX_PRICE_LIST_PROD_CHK(p_inv_id NUMBER ,p_price_list_id NUMBER)
RETURN VARCHAR2
IS
x_cnt_item NUMBER := 0;
x_item_flag VARCHAR2(10) := 'N';
BEGIN
            SELECT count(product_attr_value)
            INTO x_cnt_item
            FROM qp_list_lines_v
            WHERE list_header_id = p_price_list_id
            AND product_attr_value = p_inv_id
            AND TRUNC(SYSDATE) BETWEEN NVL(start_date_active, TRUNC(SYSDATE)) AND NVL(end_date_active, TRUNC(SYSDATE));




            IF x_cnt_item > 0 then
        x_item_flag := 'Y';
        else
            x_item_flag := 'N';
        end if;
          RETURN x_item_flag;
          EXCEPTION
              WHEN OTHERS THEN
              RETURN NULL;
          END;
FUNCTION  XX_MOD_PROD_CHK(p_ord_item VARCHAR2 ,p_price_list_id NUMBER)
RETURN VARCHAR2
IS
x_cnt_item NUMBER := 0;
x_item_flag VARCHAR2(10) := 'N';
BEGIN
           /* SELECT count(product_attr_value)
            INTO x_cnt_item
            FROM qp_modifier_summary_v
            WHERE list_header_id = p_price_list_id
        AND product_attr_value = p_ord_item ;
      */
      SELECT 1
           INTO x_cnt_item
           FROM DUAL
        WHERE EXISTS
            (select 'X'
            FROM qp_list_lines         ql
               , qp_pricing_attributes qpa
            WHERE qpa.list_header_id   = p_price_list_id
            AND qpa.product_attr_value = p_ord_item
            AND ql.list_line_id    = qpa.list_line_id
            AND TRUNC(SYSDATE) BETWEEN NVL(ql.start_date_active, TRUNC(SYSDATE)) AND NVL(ql.end_date_active, TRUNC(SYSDATE))
            );

            IF x_cnt_item > 0 then
        x_item_flag := 'Y';
        else
            x_item_flag := 'N';
        end if;
          RETURN x_item_flag;
          EXCEPTION
              WHEN OTHERS THEN
              RETURN NULL;
          END;
END;

/
