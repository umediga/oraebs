DROP PACKAGE BODY APPS.XX_OM_PRICE_MODIFIER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_PRICE_MODIFIER_PKG" AS

FUNCTION XX_PRICE_MODIFIER_GPO_IDN(p_header_id NUMBER, p_line_id NUMBER)
RETURN VARCHAR2
IS

  x_attribute7 VARCHAR2(1000);


  CURSOR c_oe_price_adjustments(cp_header_id NUMBER,cp_line_id NUMBER)
  IS
    SELECT list_header_id
    FROM oe_price_adjustments
    WHERE header_id = cp_header_id
      AND line_id =cp_line_id
      AND list_header_id IS NOT NULL;

  CURSOR c_price_list(cp_header_id NUMBER, cp_line_id NUMBER)
  IS
    SELECT attribute7
    FROM qp_list_headers
    WHERE list_header_id IN (SELECT price_list_id FROM oe_order_lines_all WHERE header_id = cp_header_id and line_id = cp_line_id);

  BEGIN
    FOR x_gpo_price_list IN c_price_list(p_header_id, p_line_id) LOOP
      IF (x_gpo_price_list.attribute7 = 'GPO' OR x_gpo_price_list.attribute7 = 'IDN')  THEN
        x_attribute7 := x_gpo_price_list.attribute7;
        RETURN x_attribute7;
      ELSIF x_gpo_price_list.attribute7 IS NULL THEN

        FOR x_gpo_modifier IN c_oe_price_adjustments(p_header_id,p_line_id) LOOP
          BEGIN
            SELECT attribute7
            INTO x_attribute7
            FROM qp_list_headers
            WHERE list_header_id = x_gpo_modifier.list_header_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
            WHEN OTHERS THEN
              RETURN NULL;
          END;
            IF (x_attribute7 = 'GPO' OR x_attribute7 = 'IDN') THEN
             RETURN x_attribute7;
            END IF;
         END LOOP;

         RETURN NULL;

      END IF;
    END LOOP;

    RETURN NULL;
  EXCEPTION
   WHEN NO_DATA_FOUND THEN
     RETURN NULL;
   WHEN OTHERS THEN
    IF c_oe_price_adjustments%ISOPEN THEN
      CLOSE c_oe_price_adjustments;
    END IF;
    IF c_price_list%ISOPEN THEN
     CLOSE c_price_list;
    END IF;
    RETURN NULL;
END;

FUNCTION XX_START_DATE(p_header_id NUMBER ,p_line_id NUMBER, p_price_list_id NUMBER,p_cust_acc_id NUMBER)
RETURN DATE
AS
CURSOR c_qualifier(cp_price_list_id NUMBER,cp_cust_acc_id NUMBER)
IS
  SELECT qualifier_context
  FROM qp_qualifiers
  WHERE list_header_id = cp_price_list_id
  and qualifier_context = 'CUSTOMER'
  and qualifier_attr_value = cp_cust_acc_id;

CURSOR c_adjustments(cp_header_id NUMBER,cp_line_id NUMBER)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and line_id = cp_line_id
  and list_header_id is not null;

  x_att7 VARCHAR2(1000);
  x_start_date DATE;
  x_cust_acc_id NUMBER;

BEGIN


  SELECT attribute7
  INTO x_att7
  FROM qp_list_headers
  WHERE list_header_id =p_price_list_id;
  --dbms_output.put_line('Att7 :'||x_Att7);
  IF  (x_att7 = 'GPO' OR x_att7 = 'IDN') THEN
    BEGIN
      SELECT start_date_active
      INTO x_start_date
      FROM qp_qualifiers
      WHERE list_header_id = p_price_list_id
      and qualifier_context = 'CUSTOMER'
      and qualifier_attr_value = p_cust_acc_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
          RETURN NULL;
        WHEN OTHERS THEN
          RETURN NULL;
     END;
     IF x_start_date IS NULL THEN
		  BEGIN
        SELECT start_date_active
        INTO x_start_date
        FROM qp_list_headers
        WHERE list_header_id =p_price_list_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
          RETURN NULL;
        WHEN OTHERS THEN
          RETURN NULL;
      END;
	    RETURN x_start_date;
	  END IF;
  ELSE -- IF Attribute7 is not in GPO or IDN
    --dbms_output.put_line('Entering Else Section');
    FOR x_adjustments IN c_adjustments(p_header_id,p_line_id) LOOP
      BEGIN
        SELECT attribute7
        INTO x_att7
        FROM qp_list_headers
        WHERE list_header_id =x_adjustments.list_header_id;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           RETURN NULL;
         WHEN TOO_MANY_ROWS THEN
           RETURN NULL;
         WHEN OTHERS THEN
           RETURN NULL;
      END;
      --dbms_output.put_line('Att7 in Else :'||x_Att7);
      IF (x_att7 = 'GPO' OR x_att7 = 'IDN') THEN
      SELECT start_date_active
      INTO x_start_date
      FROM qp_qualifiers
      WHERE list_header_id = x_adjustments.list_header_id
      and qualifier_context = 'CUSTOMER'
      and qualifier_attr_value = p_cust_acc_id;
      --dbms_output.put_line('Start Date :'||x_start_date);
      IF x_start_date IS NULL THEN
  		  BEGIN
          SELECT start_date_active
          INTO x_start_date
          FROM qp_list_headers
          WHERE list_header_id =x_adjustments.list_header_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RETURN NULL;
          WHEN TOO_MANY_ROWS THEN
            RETURN NULL;
          WHEN OTHERS THEN
            RETURN NULL;
        END;
  	    RETURN x_start_date;
      ELSE
        RETURN x_start_date;
	    END IF;
      END IF;
    END LOOP;
   END IF;

   RETURN NULL;

EXCEPTION
  WHEN OTHERS THEN

   IF c_qualifier%ISOPEN THEN
   CLOSE c_qualifier;
   END IF;

   IF c_adjustments%ISOPEN THEN
   CLOSE c_adjustments;
   END IF;


   RETURN NULL;

END;

FUNCTION XX_EXPIRATION_DATE(p_header_id NUMBER ,p_line_id NUMBER, p_price_list_id NUMBER,p_cust_acc_id NUMBER)
RETURN DATE
AS
CURSOR c_qualifier(cp_price_list_id NUMBER,cp_cust_acc_id NUMBER)
IS
  SELECT qualifier_context
  FROM qp_qualifiers
  WHERE list_header_id = cp_price_list_id
  and qualifier_context = 'CUSTOMER'
  and qualifier_attr_value = cp_cust_acc_id;

CURSOR c_adjustments(cp_header_id NUMBER,cp_line_id NUMBER)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and line_id = cp_line_id
  and list_header_id is not null;

  x_att7 VARCHAR2(1000);
  x_end_date DATE;
  x_cust_acc_id NUMBER;

BEGIN


  SELECT attribute7
  INTO x_att7
  FROM qp_list_headers
  WHERE list_header_id =p_price_list_id;
  --dbms_output.put_line('Att7 :'||x_Att7);
  IF  (x_att7 = 'GPO' OR x_att7 = 'IDN') THEN
    BEGIN
      SELECT end_date_active
      INTO x_end_date
      FROM qp_qualifiers
      WHERE list_header_id = p_price_list_id
      and qualifier_context = 'CUSTOMER'
      and qualifier_attr_value = p_cust_acc_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
          RETURN NULL;
        WHEN OTHERS THEN
          RETURN NULL;
     END;
     IF x_end_date IS NULL THEN
		  BEGIN
        SELECT end_date_active
        INTO x_end_date
        FROM qp_list_headers
        WHERE list_header_id =p_price_list_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN TOO_MANY_ROWS THEN
          RETURN NULL;
        WHEN OTHERS THEN
          RETURN NULL;
      END;
	    RETURN x_end_date;
	  END IF;
  ELSE -- IF Attribute7 is not in GPO or IDN
    --dbms_output.put_line('Entering Else Section');
    FOR x_adjustments IN c_adjustments(p_header_id,p_line_id) LOOP
      BEGIN
        SELECT attribute7
        INTO x_att7
        FROM qp_list_headers
        WHERE list_header_id =x_adjustments.list_header_id;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           RETURN NULL;
         WHEN TOO_MANY_ROWS THEN
           RETURN NULL;
         WHEN OTHERS THEN
           RETURN NULL;
      END;
      --dbms_output.put_line('Att7 in Else :'||x_Att7);
      IF (x_att7 = 'GPO' OR x_att7 = 'IDN') THEN
      SELECT end_date_active
      INTO x_end_date
      FROM qp_qualifiers
      WHERE list_header_id = x_adjustments.list_header_id
      and qualifier_context = 'CUSTOMER'
      and qualifier_attr_value = p_cust_acc_id;
      --dbms_output.put_line('Start Date :'||x_start_date);
      IF x_end_date IS NULL THEN
  		  BEGIN
          SELECT end_date_active
          INTO x_end_date
          FROM qp_list_headers
          WHERE list_header_id =x_adjustments.list_header_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RETURN NULL;
          WHEN TOO_MANY_ROWS THEN
            RETURN NULL;
          WHEN OTHERS THEN
            RETURN NULL;
        END;
  	    RETURN x_end_date;
      ELSE
        RETURN x_end_date;
	    END IF;
      END IF;
    END LOOP;
   END IF;

   RETURN NULL;

EXCEPTION
  WHEN OTHERS THEN

   IF c_qualifier%ISOPEN THEN
   CLOSE c_qualifier;
   END IF;

   IF c_adjustments%ISOPEN THEN
   CLOSE c_adjustments;
   END IF;


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
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and line_id = cp_line_id
  and list_header_id is not null;

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
      AND qpa.product_attr_value = p_inv_item_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
         RETURN 0;
        WHEN OTHERS THEN
         RETURN 0;
    END;
   /*
    BEGIN

        SELECT price_list_id
        INTO x_price_list_id
        FROM oe_order_lines_all ool
        WHERE ool.price_list_id = x_list_header_id
         AND ool.header_id = x_header_id
         AND ool.line_id = p_line_id;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
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
          WHEN NO_DATA_FOUND THEN
           RETURN 0;
          WHEN OTHERS THEN
           RETURN 0;
      END;
          */
          RETURN x_list_price;



  ELSIF (p_in_price_list IS NULL ) THEN
    BEGIN

      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = p_price_list_id;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
           RETURN 0;
        WHEN OTHERS THEN
           RETURN 0;
      END;

    IF (x_attr7 ='GPO' OR x_attr7 = 'IDN') THEN

      BEGIN
        SELECT unit_list_price
        INTO x_list_price
        FROM oe_order_lines_all ool
        WHERE price_list_id = p_price_list_id
          AND ool.header_id = x_header_id
          AND ool.line_id = p_line_id;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
           RETURN 0;
        WHEN OTHERS THEN
           RETURN 0;
      END;

      RETURN x_list_price;

    ELSE
      FOR x_adjustments IN c_adjustments(x_header_id,p_line_id)
      LOOP

        BEGIN
          SELECT attribute7
          INTO x_attr7
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
           RETURN 0;
          WHEN OTHERS THEN
           RETURN 0;
        END;

        IF (x_attr7 = 'GPO' OR x_attr7 = 'IDN' ) THEN

          BEGIN

            SELECT unit_list_price
            INTO x_list_price
            FROM oe_order_lines_all ool
            WHERE ool.header_id = x_header_id
             AND ool.line_id = p_line_id;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
              RETURN 0;
            WHEN OTHERS THEN
              RETURN 0;
          END;

          RETURN x_list_price;

        END IF;
      END LOOP;
    END IF;
  END IF;

END;
FUNCTION XX_GPO_PRICE_LIST(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_price_list_name qp_list_headers.name%TYPE;
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  AND   line_id = cp_line_id
  AND list_header_id IS NOT NULL;
BEGIN

 BEGIN
   SELECT attribute7
   INTO x_attr7
   FROM qp_list_headers
   WHERE list_header_id = p_price_list_id;
 EXCEPTION
   WHEN NO_DATA_FOUND THEN
     RETURN NULL;
   WHEN OTHERS THEN
     RETURN NULL;
 END;

   IF (x_attr7 = 'GPO' or x_attr7='IDN') THEN
     BEGIN
       SELECT name
       INTO x_price_list_name
       FROM qp_list_headers
       WHERE list_header_id = p_price_list_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN OTHERS THEN
          RETURN NULL;
      END;

      RETURN x_price_list_name;

    ELSE
     FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
     LOOP
       BEGIN
         SELECT attribute7
         INTO x_attr7
         FROM qp_list_headers
         WHERE list_header_id =  x_adjustments.list_header_id;
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
        WHEN OTHERS THEN
          RETURN NULL;
      END;

        IF (x_attr7 ='GPO' or x_attr7='IDN') THEN
          BEGIN
            SELECT name
            INTO x_price_list_name
            FROM qp_list_headers
            WHERE list_header_id = x_adjustments.list_header_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
               RETURN NULL;
            WHEN OTHERS THEN
              RETURN NULL;
          END;

          RETURN  x_price_list_name;

        END IF;
      END LOOP;
   END IF;

 END;

FUNCTION XX_GPO_LIST_PRICE(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER, p_inv_item_id NUMBER)
RETURN NUMBER
AS
l_operand NUMBER := 0;
BEGIN
      SELECT qll.operand
      into l_operand
      FROM QP_LIST_LINES QLL , QP_PRICING_ATTRIBUTES QPA , QP_LIST_HEADERS QLH
      WHERE qlh.name = XX_GPO_PRICE_LIST(p_header_id,p_line_id, p_price_list_id)
      AND qlh.list_header_id = qll.list_header_id
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
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and   line_id = cp_line_id
  and list_header_id is not null;

begin
  x_header_id := p_header_id;

  IF (p_in_price_list IS NOT NULL ) THEN

    BEGIN
        SELECT list_header_id
        INTO x_list_header_id
      FROM qp_list_headers qlh
      WHERE qlh.name =p_in_price_list;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
         RETURN 0;
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
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
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
          WHEN NO_DATA_FOUND THEN
           RETURN 0;
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
          WHEN NO_DATA_FOUND THEN
           RETURN 0;
        WHEN OTHERS THEN
           RETURN 0;
      END;

      x_discount := x_list_price-x_price;

      RETURN x_discount;


  ELSIF (p_in_price_list IS NULL ) THEN
    BEGIN

      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = p_price_list_id;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
           RETURN 0;
        WHEN OTHERS THEN
           RETURN 0;
      END;

    IF (x_attr7 ='GPO' OR x_attr7 = 'IDN') THEN

      BEGIN
        SELECT unit_list_price
        INTO x_list_price
        FROM oe_order_lines_all ool
        WHERE price_list_id = p_price_list_id
          AND ool.header_id = x_header_id
          AND ool.line_id = p_line_id;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
           RETURN 0;
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
             WHEN NO_DATA_FOUND THEN
               RETURN 0;
             WHEN OTHERS THEN
               RETURN 0;
           END;

           x_discount := x_list_price-x_price;

            RETURN x_discount;

    ELSE
      FOR x_adjustments IN c_adjustments(x_header_id,p_line_id)
      LOOP

        BEGIN
          SELECT attribute7
          INTO x_attr7
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
           RETURN 0;
          WHEN OTHERS THEN
           RETURN 0;
        END;

        IF (x_attr7 = 'GPO' OR x_attr7 = 'IDN' ) THEN

          BEGIN

            SELECT unit_list_price
            INTO x_list_price
            FROM oe_order_lines_all ool
            WHERE ool.header_id = x_header_id
             AND ool.line_id = p_line_id;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
              RETURN 0;
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
             WHEN NO_DATA_FOUND THEN
               RETURN 0;
             WHEN OTHERS THEN
               RETURN 0;
           END;

           x_discount := x_list_price-x_price;

            RETURN x_discount;

        END IF;
      END LOOP;
    END IF;
  END IF;

END;
FUNCTION XX_PERCENTAGE(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR
AS

x_attr_7 qp_list_headers.attribute7%TYPE;
x_attr_10 qp_list_headers.attribute10%TYPE;

CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and line_id = cp_line_id
  and list_header_id IS NOT NULL;

BEGIN

  BEGIN
      SELECT qlh.attribute7
      INTO x_attr_7
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id =p_price_list_id ;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
  END;

  IF x_attr_7 ='GPO' THEN
    BEGIN
      SELECT qlh.attribute10
      INTO x_attr_10
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr_10;

  ELSIF x_attr_7 ='IDN' THEN
  --  x_attr_10 := NULL;
    BEGIN
      SELECT qlh.attribute10
      INTO x_attr_10
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;
    RETURN x_attr_10;
  ELSIF x_attr_7 IS NULL THEN

   FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
   LOOP
    BEGIN
      SELECT attribute7
      INTO x_attr_7
      FROM qp_list_headers
      WHERE list_header_id = x_adjustments.list_header_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      WHEN OTHERS THEN
          RETURN NULL;
    END;

      IF x_attr_7 = 'GPO' THEN
        BEGIN

          SELECT attribute10
          INTO x_attr_10
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
       END;

       RETURN x_attr_10;

       ELSIF x_attr_7 = 'IDN' THEN
       -- x_attr_10 :=NULL;
        BEGIN

          SELECT attribute10
          INTO x_attr_10
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
       END;

        RETURN x_attr_10;

        END IF;

        END LOOP;
     --   RETURN x_attr_10;

  END IF;

END;
FUNCTION XX_DIVISION(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr4 qp_list_headers.attribute4%TYPE;
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and   LINE_ID = cp_line_id
  and list_header_id IS NOT NULL;


BEGIN

 BEGIN
      SELECT qlh.attribute7
      INTO x_attr7
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id =p_price_list_id ;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
  END;

  IF x_attr7 ='GPO' OR x_attr7 = 'IDN' THEN
    BEGIN
      SELECT qlh.attribute4
      INTO x_attr4
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr4;

  ELSE
   FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
   LOOP
      BEGIN
      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = x_adjustments.list_header_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      WHEN OTHERS THEN
          RETURN NULL;
    END;

      IF x_attr7 = 'GPO' OR x_attr7 ='IDN' THEN

         BEGIN
          SELECT attribute4
          INTO x_attr4
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
          WHEN OTHERS THEN
              RETURN NULL;
         END;

         RETURN x_attr4;

         END IF;
     END LOOP;
     END IF;
 END;

FUNCTION XX_ADMIN_FEE_PAYMENT(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr5 qp_list_headers.attribute5%TYPE;
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  AND line_id = cp_line_id
  and List_header_id is not null;


BEGIN

 BEGIN
      SELECT qlh.attribute7
      INTO x_attr7
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id =p_price_list_id ;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
  END;

  IF x_attr7 ='GPO' OR x_attr7 = 'IDN' THEN
    BEGIN
      SELECT qlh.attribute5
      INTO x_attr5
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr5;

  ELSE
   FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
   LOOP
      BEGIN
      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = x_adjustments.list_header_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      WHEN OTHERS THEN
          RETURN NULL;
    END;

      IF x_attr7 = 'GPO' OR x_attr7 ='IDN' THEN

         BEGIN
          SELECT attribute5
          INTO x_attr5
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
          WHEN OTHERS THEN
              RETURN NULL;
         END;

         RETURN x_attr5;

         END IF;
     END LOOP;
     END IF;
 END;
FUNCTION XX_GPO_IDN_NAME(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr3 qp_list_headers.attribute3%TYPE;
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and   line_id = cp_line_id
  and list_header_id is not null;


BEGIN

 BEGIN
      SELECT qlh.attribute7
      INTO x_attr7
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id =p_price_list_id ;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
  END;

  IF x_attr7 ='GPO' OR x_attr7 = 'IDN' THEN
    BEGIN
      SELECT qlh.attribute3
      INTO x_attr3
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr3;

  ELSE
   FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
   LOOP
      BEGIN
      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = x_adjustments.list_header_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      WHEN OTHERS THEN
          RETURN NULL;
    END;

      IF x_attr7 = 'GPO' OR x_attr7 ='IDN' THEN

         BEGIN
          SELECT attribute3
          INTO x_attr3
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
          WHEN OTHERS THEN
              RETURN NULL;
         END;

         RETURN x_attr3;

         END IF;
     END LOOP;
     END IF;
 END;
FUNCTION XX_GPO_ENTITY_CODE(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr11 qp_list_headers.attribute11%TYPE;
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and   line_id = cp_line_id
  and list_header_id is not null;


BEGIN

 BEGIN
      SELECT qlh.attribute7
      INTO x_attr7
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id =p_price_list_id ;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
  END;

  IF x_attr7 ='GPO' OR x_attr7 = 'IDN' THEN
    BEGIN
      SELECT qlh.attribute11
      INTO x_attr11
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr11;

  ELSE
   FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
   LOOP
      BEGIN
      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = x_adjustments.list_header_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      WHEN OTHERS THEN
          RETURN NULL;
    END;

      IF x_attr7 = 'GPO' OR x_attr7 ='IDN' THEN

         BEGIN
          SELECT attribute11
          INTO x_attr11
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
          WHEN OTHERS THEN
              RETURN NULL;
         END;

         RETURN x_attr11;

         END IF;
     END LOOP;
     END IF;
 END;
FUNCTION XX_GPO_PARTY_NAME(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr3 qp_list_headers.attribute3%TYPE;
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and   line_id = cp_line_id
  and list_header_id is not null;

BEGIN

 BEGIN
      SELECT qlh.attribute7
      INTO x_attr7
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id =p_price_list_id ;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
  END;

  IF x_attr7 ='GPO' OR x_attr7 = 'IDN' THEN
    BEGIN
      SELECT qlh.attribute3
      INTO x_attr3
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr3;

  ELSE
   FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
   LOOP
      BEGIN
      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = x_adjustments.list_header_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      WHEN OTHERS THEN
          RETURN NULL;
    END;

      IF x_attr7 = 'GPO' OR x_attr7 ='IDN' THEN

         BEGIN
          SELECT attribute3
          INTO x_attr3
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
          WHEN OTHERS THEN
              RETURN NULL;
         END;

         RETURN x_attr3;

         END IF;
     END LOOP;
     END IF;
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

FUNCTION XX_CONTRACT_NUMBER(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER)
RETURN VARCHAR2
AS
x_attr7 qp_list_headers.attribute7%TYPE;
x_attr11 qp_list_headers.attribute11%TYPE;
CURSOR c_adjustments(cp_header_id oe_order_lines_all.header_id%TYPE,cp_line_id oe_order_lines_all.line_id%TYPE)
IS
  SELECT list_header_id
  FROM oe_price_adjustments
  WHERE header_id = cp_header_id
  and   line_id = cp_line_id
  and list_header_id is not null;


BEGIN

 BEGIN
      SELECT qlh.attribute7
      INTO x_attr7
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id =p_price_list_id ;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
      WHEN OTHERS THEN
         RETURN NULL;
  END;

  IF x_attr7 ='GPO' OR x_attr7 = 'IDN' THEN
    BEGIN
      SELECT qlh.attribute11
      INTO x_attr11
      FROM qp_list_headers qlh
      WHERE qlh.list_header_id = p_price_list_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
              RETURN NULL;
      WHEN OTHERS THEN
           RETURN NULL;
    END;

    RETURN x_attr11;

  ELSE
   FOR x_adjustments IN c_adjustments(p_header_id,p_line_id)
   LOOP
      BEGIN
      SELECT attribute7
      INTO x_attr7
      FROM qp_list_headers
      WHERE list_header_id = x_adjustments.list_header_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN NULL;
      WHEN OTHERS THEN
          RETURN NULL;
    END;

      IF x_attr7 = 'GPO' OR x_attr7 ='IDN' THEN

         BEGIN
          SELECT attribute11
          INTO x_attr11
          FROM qp_list_headers
          WHERE list_header_id = x_adjustments.list_header_id;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN NULL;
          WHEN OTHERS THEN
              RETURN NULL;
         END;

         RETURN x_attr11;

         END IF;
     END LOOP;
     END IF;
 END;
 FUNCTION XX_GPO_ENTITY_CODE(p_header_id NUMBER,p_line_id NUMBER, p_price_list_id NUMBER, p_site_id NUMBER)
 RETURN VARCHAR
 AS
    l_name      VARCHAR2(100);
    l_code      VARCHAR2(3);
    l_ecode     VARCHAR2(100);
    l_sc_pos    NUMBER;
    l_gpo_code  VARCHAR2(100);
 BEGIN
    l_name := XX_OM_PRICE_MODIFIER_PKG.XX_GPO_IDN_NAME(p_header_id,p_line_id, p_price_list_id);

    select lookup_code
    into l_code
    from  fnd_lookup_values
    where lookup_type =   'INTG_GPO_ABBREV_MAPPING'
    and language = 'US'
    and enabled_flag = 'Y'
    and UPPER(meaning) = UPPER(l_name);

    select attribute1
    into l_ecode
    from hz_cust_acct_sites_all
    where cust_acct_site_id = p_site_id;

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
END;
/
