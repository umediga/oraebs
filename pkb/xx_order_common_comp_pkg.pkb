DROP PACKAGE BODY APPS.XX_ORDER_COMMON_COMP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ORDER_COMMON_COMP_PKG" 
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-2012
 File Name     : XXOMCOMMON.pkb
 Description   : Common Components to be used for OM related interfaces and extensions

 Change History:

 Date        Name             Remarks
 ----------- -----------      ---------------------------------------
 07-MAR-2012 IBM Development  Initial development
 */
--------------------------------------------------------------------------------------
AS
   --
   /*
   Purpose        : This Function will returns the line_id.
   Input          : order number , line_number
   Output         : It will return the order line_id
   Special Logic  : This API function can only be called after a call to initialize the Multi Org Access
   */
   --
   FUNCTION get_line_id (p_order_number NUMBER, p_line_number VARCHAR2)
      RETURN NUMBER
   AS
      x_line_number            NUMBER;
      x_shipment_number        NUMBER;
      x_option_number          NUMBER          := NULL;
      x_component_number       NUMBER;
      x_service_number         NUMBER;
      x_int_line_number        NUMBER;
      x_int_shipment_number    NUMBER;
      x_int_option_number      NUMBER;
      x_int_component_number   NUMBER;
      x_int_service_number     NUMBER;
      x_line_id                NUMBER;
      x_string                 VARCHAR2 (1000);
   BEGIN
      --
      -- Selecting line_number
      SELECT INSTR (p_line_number, '.', 1, 1)
        INTO x_int_line_number
        FROM SYS.DUAL;

      IF x_int_line_number = 0
      THEN
         x_line_number := p_line_number;
      ELSE
         x_line_number := SUBSTR (p_line_number, 1, x_int_line_number - 1);
      END IF;

      x_string := ' AND line_number=' || x_line_number;

      --
      -- Selecting shipment_number
      IF x_int_line_number > 0
      THEN
         SELECT INSTR (p_line_number, '.', 1, 2)
           INTO x_int_shipment_number
           FROM SYS.DUAL;

         IF x_int_shipment_number = 0
         THEN
            x_shipment_number :=
                                SUBSTR (p_line_number, x_int_line_number + 1);
            x_string :=
                   x_string || ' AND shipment_number = ' || x_shipment_number;
         ELSE
            IF x_int_shipment_number - x_int_line_number > 1
            THEN
               x_shipment_number :=
                  SUBSTR (p_line_number,
                          x_int_line_number + 1,
                          (x_int_shipment_number - x_int_line_number
                          ) - 1
                         );
               x_string :=
                    x_string || ' AND shipment_number = ' || x_shipment_number;
            ELSE
               x_string := x_string || ' AND shipment_number IS NULL';
            END IF;
         END IF;

         IF x_int_shipment_number > 0
         THEN
            --
            -- Selecting option_number
            SELECT INSTR (p_line_number, '.', 1, 3)
              INTO x_int_option_number
              FROM SYS.DUAL;

            IF x_int_option_number = 0
            THEN
               x_option_number :=
                            SUBSTR (p_line_number, x_int_shipment_number + 1);
               x_string :=
                       x_string || ' AND option_number = ' || x_option_number;
            ELSE
               IF x_int_option_number - x_int_shipment_number > 1
               THEN
                  x_option_number :=
                     SUBSTR (p_line_number,
                             x_int_shipment_number + 1,
                             (x_int_option_number - x_int_shipment_number
                             ) - 1
                            );
                  x_string :=
                        x_string || ' AND option_number = ' || x_option_number;
               ELSE
                  x_string := x_string || ' AND option_number IS NULL';
               END IF;
            END IF;

            IF x_int_option_number > 0
            THEN
               -- Selecting component_number
               SELECT INSTR (p_line_number, '.', 1, 4)
                 INTO x_int_component_number
                 FROM SYS.DUAL;

               IF x_int_component_number = 0
               THEN
                  x_component_number :=
                              SUBSTR (p_line_number, x_int_option_number + 1);
                  x_string :=
                        x_string
                     || ' AND component_number = '
                     || x_component_number;
               ELSE
                  IF x_int_component_number - x_int_option_number > 1
                  THEN
                     x_component_number :=
                        SUBSTR (p_line_number,
                                x_int_option_number + 1,
                                  (x_int_component_number
                                   - x_int_option_number
                                  )
                                - 1
                               );
                     x_string :=
                           x_string
                        || ' AND component_number = '
                        || x_component_number;
                  ELSE
                     x_string := x_string || ' AND component_number IS NULL';
                  END IF;
               END IF;

               IF x_int_component_number > 0
               THEN
                  SELECT INSTR (p_line_number, '.', 1, 5)
                    INTO x_int_service_number
                    FROM SYS.DUAL;

                  IF x_int_service_number = 0
                  THEN
                     x_service_number :=
                           SUBSTR (p_line_number, x_int_component_number + 1);
                     x_string :=
                           x_string
                        || ' AND service_number = '
                        || x_service_number;
                  ELSE
                     IF x_int_service_number - x_int_component_number > 1
                     THEN
                        x_service_number :=
                           SUBSTR (p_line_number,
                                   x_int_component_number + 1,
                                     (  x_int_service_number
                                      - x_int_component_number
                                     )
                                   - 1
                                  );
                        x_string :=
                              x_string
                           || ' AND service_number = '
                           || x_service_number;
                     ELSE
                        x_string := x_string || ' AND service_number IS NULL';
                     END IF;
                  END IF;
               ELSE
                  x_string :=
                        x_string
                     || ' AND service_number IS NULL AND service_number IS NULL';
               END IF;                     --IF x_int_component_number >0 THEN
            ELSE
               x_string :=
                     x_string
                  || ' AND component_number IS NULL AND service_number IS NULL';
            END IF;                           --IF x_int_option_number >0 THEN
         ELSE
            x_string :=
                  x_string
               || ' AND option_number IS NULL AND component_number IS NULL AND service_number IS NULL';
         END IF;                            --IF x_int_shipment_number >0 THEN
      ELSE
         x_string :=
               x_string
            || ' AND shipment_number IS NULL AND option_number IS NULL AND component_number IS NULL AND service_number IS NULL';
      END IF;                 --IF x_int_line_number >0 THEN RETURN x_line_id;

      /*DBMS_OUTPUT.put_line (   'line_number :'
                            || x_line_number
                            || ' shipment_number :'
                            || x_shipment_number
                            || ' option_number :'
                            || x_option_number
                            || '  component_number :'
                            || x_component_number
                            || ' service_number :'
                            || x_service_number);
      DBMS_OUTPUT.put_line ('x_string : ' || x_string);*/
      EXECUTE IMMEDIATE    ' SELECT line_id from oe_order_lines_v
            WHERE order_number= '
                        || p_order_number
                        || x_string
                   INTO x_line_id;

      RETURN x_line_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Error while trying to fetch the line_id from the procedure get_line_id corresponding sql error :'
             || SQLERRM
            );
         RETURN NULL;
   END get_line_id;

   --
   /*
   Purpose        : This procedure will returns the customer demographic information.
   Input          : Customer Number
   Output         : It will return a row from the HZ_CUSTOMER_PARTY_FIND_V view
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_cust_demographics (
      p_customer_number     IN       VARCHAR2,
      p_party_site_number   IN       VARCHAR2,
      x_customer_rec        OUT      hz_customer_party_find_v%ROWTYPE
   )
   IS
   BEGIN
      SELECT *
        INTO x_customer_rec
        FROM hz_customer_party_find_v
       WHERE customer_number = p_customer_number
         AND party_site_number = p_party_site_number;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_cust_demographics, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_cust_demographics;

   --
   /*
   Purpose        : This Function will returns the customer_status
   Input          : Customer Number
   Output         : It will return Customer Status
   Special Logic  : None
   */
   --
   FUNCTION get_cust_status (p_customer_number IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_cust_status   hz_cust_accounts.status%TYPE;
   BEGIN
      SELECT status
        INTO x_cust_status
        FROM hz_cust_accounts
       WHERE account_number = p_customer_number;

      RETURN x_cust_status;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_cust_status, corresponding SQL error :'
             || SQLERRM
            );
         RETURN NULL;
   END;

   --
   /*
   Purpose        : This Procedure will returns the payment options that have been set up for that customer.
   Input          : Customer Number
   Output         : payment options
   Special Logic  : None
   */
   --
   PROCEDURE get_cust_payment_options (
      p_customer_number        IN       VARCHAR2,
      x_customer_profile_rec   OUT      hz_customer_profiles%ROWTYPE
   )
   IS
   BEGIN
      SELECT hcp.*
        INTO x_customer_profile_rec
        FROM hz_cust_accounts hca, hz_customer_profiles hcp
       WHERE hca.cust_account_id = hcp.cust_account_id
         AND hca.account_number = p_customer_number;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_cust_payment_options, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_cust_payment_options;

   --
   /*
   Purpose        : This Function will returns the order type
   Input          : Order Number
   Output         : Order Type
   Special Logic  : This API function can only be called after a call to initialize the Multi Org Access

   */
   --
   FUNCTION get_order_type (p_order_number IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_order_type   oe_order_headers_v.order_type%TYPE;
   BEGIN
      SELECT order_type
        INTO x_order_type
        FROM oe_order_headers_v
       WHERE order_number = p_order_number;

      RETURN x_order_type;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_order_type, corresponding SQL error :'
             || SQLERRM
            );
         RETURN NULL;
   END get_order_type;

   --
   /*
   Purpose        : This Function will returns the total order amount. This should be inclusive of freight, taxes, fees, etc
   Input          : Order Number
   Output         : Total Order Amount
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   FUNCTION get_order_amount (p_order_number IN VARCHAR2)
      RETURN NUMBER
   IS
      x_subtotal    NUMBER;
      x_discount    NUMBER;
      x_charges     NUMBER;
      x_tax         NUMBER;
      x_total       NUMBER;
      x_header_id   NUMBER;
   BEGIN
      SELECT header_id
        INTO x_header_id
        FROM oe_order_headers_v
       WHERE order_number = p_order_number;

      apps.oe_oe_totals_summary.order_totals (x_header_id,
                                              x_subtotal,
                                              x_discount,
                                              x_charges,
                                              x_tax
                                             );
      x_total :=
           NVL (x_subtotal, 0)
         + NVL (x_discount, 0)
         + NVL (x_charges, 0)
         + NVL (x_tax, 0);
      RETURN x_total;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_order_amount, corresponding SQL error :'
             || SQLERRM
            );
         RETURN NULL;
   END get_order_amount;

   --
   /*
   Purpose        : This Function will returns the order line type.
   Input          : Order Number
   Output         : Order Line Type
   Special Logic  : None
   */
   --
   FUNCTION get_line_type (p_line_id IN NUMBER)
      RETURN VARCHAR2
   IS
      x_line_type   oe_transaction_types_tl.NAME%TYPE;
   BEGIN
      SELECT lt.NAME line_type
        INTO x_line_type
        FROM oe_transaction_types_tl lt,
             oe_order_lines_all oel,
             oe_order_headers_all oeh
       WHERE oel.line_type_id = lt.transaction_type_id
         AND lt.LANGUAGE = USERENV ('LANG')
         AND oel.line_id = p_line_id
         AND oel.header_id = oeh.header_id;

      --AND oeh.order_number = p_order_number;
      RETURN x_line_type;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_type, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_line_type;

   --
   /*
   Purpose        : This Procedure will returns the ship-to information for the line.
   Input          : Order Number , line number
   Output         : It will return Customer Status
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_shipto_info (
      p_line_id        IN       NUMBER,
      x_ship_to_info   OUT      ship_to_info_rec
   )
   IS
   BEGIN
      SELECT ship_to,
             ship_to_address1,
             ship_to_address2,
             ship_to_address3,
             ship_to_address4,
             ship_to_address5,
             ship_to_contact,
             ship_to_contact_id,
             ship_to_location,
             ship_to_org_id
        INTO x_ship_to_info
        FROM oe_order_lines_v
       WHERE line_number = p_line_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_shipto_info, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_line_shipto_info;

   --
   /*
   Purpose        : This Procedure will returns the Bill-to information for the line.
   Input          : Order Number , line number
   Output         : It will return one row corresponding to the Bill-to information details
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_billto_info (
      p_line_id        IN       NUMBER,
      x_bill_to_info   OUT      bill_to_info_rec
   )
   IS
   BEGIN
      SELECT invoice_to,
             invoice_to_address1,
             invoice_to_address2,
             invoice_to_address3,
             invoice_to_address4,
             invoice_to_address5,
             invoice_to_contact,
             invoice_to_contact_id,
             invoice_to_location,
             invoice_to_org_id
        INTO x_bill_to_info
        FROM oe_order_lines_v
       WHERE line_number = p_line_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_billto_info, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_line_billto_info;

   --
   /*
   Purpose        : This Procedure will returns the Sold-to information for the line.
   Input          : Order Number , line number
   Output         : It will return one row corresponding to the SOld-to information details
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_soldto_info (
      p_line_id        IN       NUMBER,
      x_sold_to_info   OUT      sold_to_info_rec
   )
   IS
   BEGIN
      SELECT hp.party_name,
             hp.address1,
             hp.address2,
             hp.address3,
             hp.address4,
             ola.sold_to_org_id,
             ola.invoice_to_contact,
             ola.invoice_to_contact_id,
             ola.invoice_to_location
        INTO x_sold_to_info
        FROM oe_order_lines_v ola, hz_parties hp, hz_cust_accounts hca
       WHERE ola.sold_to_org_id = hca.cust_account_id
         AND hca.party_id = hp.party_id
         AND ola.line_id = p_line_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_soldto_info, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_line_soldto_info;

   --
   /*
   Purpose        : This Procedure will returns the Deliver-to information for the line.
   Input          : Order Number , line number
   Output         : It will return one row corresponding to the Deliver-to information details
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_deliverto_info (
      p_line_id           IN       NUMBER,
      x_deliver_to_info   OUT      deliver_to_info_rec
   )
   IS
   BEGIN
      SELECT deliver_to,
             deliver_to_address1,
             deliver_to_address2,
             deliver_to_address3,
             deliver_to_address4,
             deliver_to_contact,
             deliver_to_contact_id,
             deliver_to_location,
             deliver_to_org_id
        INTO x_deliver_to_info
        FROM oe_order_lines_v
       WHERE line_number = p_line_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_deliverto_info, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_line_deliverto_info;

   --
   /*
   Purpose        : This Procedure will returns information about the item on the line
   Input          : Order number, inventory organization id and line number
   Output         : It will return Customer Status
   Special Logic  : None
   */
   --
   PROCEDURE get_line_item_info (
      p_line_id           IN       NUMBER,
      p_organization_id   IN       NUMBER,
      x_item_rec          OUT      mtl_system_items_b%ROWTYPE
   )
   IS
   BEGIN
      SELECT mtl.*
        INTO x_item_rec
        FROM mtl_system_items_b mtl,
             oe_order_lines_all oel,
             oe_order_headers_all oeh
       WHERE oel.inventory_item_id = mtl.inventory_item_id
         AND mtl.organization_id = p_organization_id
         AND oel.line_number = p_line_id
         AND oel.header_id = oeh.header_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_item_info, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_line_item_info;

   --
   /*
   Purpose        : This Function will returns the payment method used for the line.
   Input          : Order Number,line Number
   Output         : Payment Method
   Special Logic  : None
   */
   --
   FUNCTION get_line_payment_method (p_line_id IN NUMBER)
      RETURN VARCHAR2
   IS
      x_payment_method   oe_payment_types_tl.NAME%TYPE;
   BEGIN
      SELECT oept.NAME
        INTO x_payment_method
        FROM oe_order_headers_all oeh,
             oe_order_lines_all oel,
             oe_payments oep,
             oe_payment_types_tl oept
       WHERE oep.payment_type_code = oept.payment_type_code
         AND oept.LANGUAGE = USERENV ('LANG')
         AND oep.line_id = oel.line_id
         AND oep.header_id = oel.header_id
         AND oel.header_id = oeh.header_id
         AND oel.line_number = p_line_id;

      RETURN x_payment_method;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_payment_method, corresponding SQL error :'
             || SQLERRM
            );
         RETURN NULL;
   END get_line_payment_method;

   --
   /*
   Purpose        : This Function will returns the status of the line.
   Input          : Order Number,line Number
   Output         : It will return the line status
   Special Logic  : None
   */
   --
   FUNCTION get_line_status (p_line_id IN NUMBER)
      RETURN VARCHAR2
   IS
      x_line_status   oe_order_lines_all.flow_status_code%TYPE;
   BEGIN
      SELECT oe_line_status_pub.get_line_status (oel.line_id,
                                                 oel.flow_status_code
                                                )
        INTO x_line_status
        FROM oe_order_lines_all oel
       WHERE oel.line_id = p_line_id;

      RETURN x_line_status;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_status, corresponding SQL error :'
             || SQLERRM
            );
         RETURN NULL;
   END get_line_status;

   --
   /*
   Purpose        : This Procedure will returns the shipment information for the line.
   Input          : COrder Number,line Number
   Output         : It will return one row with the shipment related details
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_shipment_info (
      p_line_id         IN       NUMBER,
      x_shipment_info   OUT      shipment_info_rec
   )
   IS
   BEGIN
      SELECT shipment_number,
             shipment_priority_code,
             shipped_quantity,
             shipped_quantity2,
             shipping_instructions,
             shipping_interfaced_flag,
             shipping_method_code,
             shipping_quantity,
             shipping_quantity2,
             shipping_quantity_uom,
             shipping_quantity_uom2,
             ship_from,
             ship_from_location,
             ship_from_org_id,
             ship_model_complete_flag,
             ship_set,
             ship_set_id
        INTO x_shipment_info
        FROM oe_order_lines_v
       WHERE line_id = p_line_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'Exception within procedure get_line_shipment_info, corresponding SQL error :'
             || SQLERRM
            );
         NULL;
   END get_line_shipment_info;
-- Function to get the conversion rate with Base UOM code
FUNCTION get_conversion_rate (p_inventory_item_id IN number
			     ,p_uom     IN varchar2)
    RETURN number
IS
    x_rate number := NULL;

    CURSOR c_rate
    IS
	   SELECT conversion_rate
	     FROM mtl_uom_conversions
	    WHERE inventory_item_id = p_inventory_item_id
		  AND uom_code = p_uom;

    CURSOR c_rate_alt
    IS
	   SELECT conversion_rate
	     FROM mtl_uom_conversions
	    WHERE inventory_item_id = 0
		  AND uom_code = p_uom;


BEGIN

    OPEN c_rate;
    FETCH c_rate INTO x_rate;
    IF c_rate%NOTFOUND THEN
	  CLOSE c_rate;
	  OPEN c_rate_alt;
	  FETCH c_rate_alt INTO x_rate;
	  CLOSE c_rate_alt;
    END IF;
    IF c_rate%ISOPEN THEN
	  CLOSE c_rate;
    END IF;
    RETURN x_rate;
EXCEPTION
    WHEN OTHERS THEN
	  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'SQLERRM ' || SQLERRM);
	  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Unhandled exception in get_conversion_rate');

	  RETURN NULL;
END get_conversion_rate;
--
----------------------------------------------------------------------------
--------------------<   get_case_details   >--------------------------------
----------------------------------------------------------------------------
-- Function to get the Masterpack details, case details and partial case details
-- Parameters:
-- p_inv_org_name      Inventory organizations i.e. 'IO_AHP_DOTHAN'
-- p_item_number       Item Number
-- p_uom_code          Unit of measure of the shipped quantity
-- p_shipped_quantity  shipped quantity
-- p_ip                Customer specific innerpack conversion ratio
-- p_no_of_mp          Number of Master Packs
-- p_no_of_ca          Number of Cases
-- p_no_of_incmp_ca    Number of Imcomplete Cases
-- p_total_no_of_label Total number of labels to be printed
-- p_mp_qty            Masterpack quantity in inner pack/retail pack/customer qty for each label
-- p_mp_qty_in_alt_uom Masterpack quantity in alternate uom each for each label
-- p_ca_qty            Case quantity in inner pack/retail pack/customer qty for each label
-- p_ca_qty_in_alt_uom Case quantity in alternate uom each for each label
-- p_ip_qty            Partial Case quantity in inner pack/retail pack/customer qty for each label
-- p_ip_qty_in_alt_uom Partial Case quantity in alternate uom each for each label
-- This Function will work with following assumptions
-- 1. All UOM's referred should have conversion rate with base UOM
-- 2. UOM for Master Pack is 'MP'
-- 3. UOM for Case is 'CA'
-- 4. UOM for Inner Case/Pack is 'IP'
-- 5. UOM for Retail Pack is 'RP'
--------------------------------------------------------------------------------------------
   FUNCTION get_case_details (
      p_inv_org_name        IN       VARCHAR2,
      p_item_number         IN       VARCHAR2,
      p_uom_code            IN       VARCHAR2,
      p_shipped_quantity    IN       NUMBER,
      p_ip                  IN       NUMBER,
      p_no_of_mp            OUT      NUMBER,
      p_no_of_ca            OUT      NUMBER,
      p_no_of_incmp_ca      OUT      NUMBER,
      p_total_no_of_label   OUT      NUMBER,
      p_mp_qty              OUT      NUMBER,
      p_mp_qty_in_inv_uom   OUT      NUMBER,--AK
      p_mp_qty_in_alt_uom   OUT      NUMBER,
      p_ca_qty              OUT      NUMBER,
      p_ca_qty_in_alt_uom   OUT      NUMBER,
      p_ip_qty              OUT      NUMBER,
      p_ip_qty_in_alt_uom   OUT      NUMBER
   )
      RETURN NUMBER
   IS
--
      CURSOR get_item_id
      IS
         SELECT msi.inventory_item_id
           FROM mtl_system_items_b msi
          WHERE msi.segment1 = p_item_number ;



      x_error_code         NUMBER                  := xx_emf_cn_pkg.cn_success;
      l_inventory_item_id  NUMBER;
      l_uom_code           mtl_uom_conversions.uom_code%TYPE;
      l_conversion_rate1   mtl_uom_conversions.conversion_rate%TYPE;
      l_conversion_rate2   mtl_uom_conversions.conversion_rate%TYPE;
      l_conversion_rate3   mtl_uom_conversions.conversion_rate%TYPE;
      l_conversion_rate4   mtl_uom_conversions.conversion_rate%TYPE;
      -- CC added a new variable for Retail Pack
      l_conversion_rate5   mtl_uom_conversions.conversion_rate%TYPE;
      l_quantity_in_mp     NUMBER;
      l_quantity_in_ca     NUMBER;
      l_total_qty          NUMBER;
   BEGIN
      l_uom_code := p_uom_code;

      FOR rec_item_id IN get_item_id LOOP
          l_inventory_item_id := rec_item_id.inventory_item_id;
      END LOOP;

      --DBMS_OUTPUT.put_line ('l_uom_code : ' || l_uom_code);
      --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
      --                      'l_uom_code : ' || l_uom_code
      --                     );

      l_conversion_rate1 := get_conversion_rate (l_inventory_item_id,l_uom_code);

      IF l_conversion_rate1 IS NULL
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         --DBMS_OUTPUT.put_line ('Conversion rate not found: ' || SQLERRM);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Conversion rate not found:  ' || SQLERRM
                              );
      ELSE
         l_uom_code := 'MP';

         --DBMS_OUTPUT.put_line ('l_uom_code : ' || l_uom_code);

         l_conversion_rate2 := get_conversion_rate (l_inventory_item_id,l_uom_code);
         IF l_conversion_rate2 IS NULL
         THEN
            l_conversion_rate2 := 1;
         END IF;

         l_uom_code := 'CA';

         --DBMS_OUTPUT.put_line ('l_uom_code : ' || l_uom_code);

         l_conversion_rate3 := get_conversion_rate (l_inventory_item_id,l_uom_code);
         IF l_conversion_rate3 IS NULL
         THEN
            l_conversion_rate3 := 1;
         END IF;

         l_uom_code := 'RP';

         --DBMS_OUTPUT.put_line ('l_uom_code : ' || l_uom_code);

         -- Open the cursor for the 'RP' quantity UOM
         l_conversion_rate4 := get_conversion_rate (l_inventory_item_id,l_uom_code);

         -- CC -- Added new calculation for Retail Pack
         l_uom_code := 'IP';

         --DBMS_OUTPUT.put_line ('l_uom_code : ' || l_uom_code);

         -- Open the cursor for the 'IP' quantity UOM
         l_conversion_rate5 := get_conversion_rate (l_inventory_item_id,l_uom_code);
         IF l_conversion_rate5 IS NULL
         THEN
            l_conversion_rate5 := 1;
         END IF;

         IF l_conversion_rate4 IS NULL
         THEN
            l_conversion_rate4 := l_conversion_rate5;
         END IF;

         l_total_qty := l_conversion_rate1 * p_shipped_quantity;

         IF l_conversion_rate2 > 1
         THEN
            p_no_of_mp := FLOOR (l_total_qty / l_conversion_rate2);
         ELSE
            p_no_of_mp := 0;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_conversion_rate1 : ' || l_conversion_rate1
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_conversion_rate2 : ' || l_conversion_rate2
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_conversion_rate3 : ' || l_conversion_rate3
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_conversion_rate4 : ' || l_conversion_rate4
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_conversion_rate5 : ' || l_conversion_rate5
                              );

         --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
         --                      'l_total_qty : ' || l_total_qty
         --                     );
         --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
         --                         'l_total_qty/l_conversion_rate2 : '
         --                      || l_total_qty / l_conversion_rate2
         --                     );
         --
         --DBMS_OUTPUT.put_line ('p_no_of_mp : ' || p_no_of_mp);
         --DBMS_OUTPUT.put_line ('l_conversion_rate1 : ' || l_conversion_rate1);
         --DBMS_OUTPUT.put_line ('l_conversion_rate2 : ' || l_conversion_rate2);
         --DBMS_OUTPUT.put_line ('l_conversion_rate3 : ' || l_conversion_rate3);
         --DBMS_OUTPUT.put_line ('l_conversion_rate4 : ' || l_conversion_rate4);
         --DBMS_OUTPUT.put_line ('l_conversion_rate5 : ' || l_conversion_rate5);
         --DBMS_OUTPUT.put_line ('l_total_qty : ' || l_total_qty);
         --DBMS_OUTPUT.put_line (   'l_total_qty/l_conversion_rate2 : '
         --                      || l_total_qty / l_conversion_rate2
         --                     );
         --DBMS_OUTPUT.put_line ('p_no_of_mp : ' || p_no_of_mp);
         --
         IF l_conversion_rate2 > 1
         THEN
            l_quantity_in_mp := p_no_of_mp * l_conversion_rate2;
            p_mp_qty_in_alt_uom := l_conversion_rate2;

            IF p_ip = 0
            THEN
               p_mp_qty := CEIL (l_conversion_rate2 / l_conversion_rate4);
               p_mp_qty_in_inv_uom :=
                     CEIL (l_conversion_rate4 * p_mp_qty)
                     / l_conversion_rate3;
            ELSE
               p_mp_qty := CEIL (l_conversion_rate2 / p_ip);
               p_mp_qty_in_inv_uom :=
                                   CEIL (p_ip * p_mp_qty)
                                   / l_conversion_rate3;
            END IF;

            l_total_qty := l_total_qty - l_quantity_in_mp;
         --DBMS_OUTPUT.put_line ('l_quantity_in_mp : ' || l_quantity_in_mp);
         --DBMS_OUTPUT.put_line ('p_mp_qty_in_alt_uom : ' || p_mp_qty_in_alt_uom);
         --DBMS_OUTPUT.put_line ('p_mp_qty : ' || p_mp_qty);
         --DBMS_OUTPUT.put_line ('l_total_qty : ' || l_total_qty);

         /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_quantity_in_mp : ' || l_quantity_in_mp
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_mp_qty_in_alt_uom : ' || p_mp_qty_in_alt_uom
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_mp_qty : ' || p_mp_qty);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_total_qty : ' || l_total_qty
                              );*/
         ELSE
            l_quantity_in_mp := 0;
            p_mp_qty_in_alt_uom := 0;
            p_mp_qty_in_inv_uom := 0;
            p_mp_qty := 0;
         END IF;

         IF l_total_qty > 0
         THEN
            p_no_of_ca := FLOOR (l_total_qty / l_conversion_rate3);
            --
            l_quantity_in_ca := p_no_of_ca * l_conversion_rate3;
            --
            l_total_qty := l_total_qty - l_quantity_in_ca;

            --
            IF p_no_of_ca > 0
            THEN
               p_ca_qty_in_alt_uom := l_conversion_rate3;

               --
               IF p_ip = 0
               THEN
                  p_ca_qty := CEIL (l_conversion_rate3 / l_conversion_rate4);
               ELSE
                  p_ca_qty := CEIL (l_conversion_rate3 / p_ip);
               END IF;
            ELSE
               p_ca_qty_in_alt_uom := 0;
               --
               p_ca_qty := 0;
            END IF;
         ELSE
            p_no_of_ca := 0;
            --
            p_ca_qty := 0;
            p_ca_qty_in_alt_uom := 0;
         END IF;

         /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_no_of_ca : ' || p_no_of_ca
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_quantity_in_ca : ' || l_quantity_in_ca
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_ca_qty_in_alt_uom : ' || p_ca_qty_in_alt_uom
                              );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_ca_qty : ' || p_ca_qty);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'l_total_qty : ' || l_total_qty
                              );*/
         --
         --DBMS_OUTPUT.put_line ('p_no_of_ca : ' || p_no_of_ca);
         --DBMS_OUTPUT.put_line ('l_quantity_in_ca : ' || l_quantity_in_ca);
         --DBMS_OUTPUT.put_line ('p_ca_qty_in_alt_uom : ' || p_ca_qty_in_alt_uom);
         --DBMS_OUTPUT.put_line ('p_ca_qty : ' || p_ca_qty);
         --DBMS_OUTPUT.put_line ('l_total_qty : ' || l_total_qty);
         IF l_total_qty > 0
         THEN
            p_no_of_incmp_ca := 1;
            p_ip_qty_in_alt_uom := l_total_qty;

            IF p_ip = 0
            THEN
               p_ip_qty := CEIL (ROUND(l_total_qty,0) / l_conversion_rate4);
            ELSE
               p_ip_qty := CEIL (ROUND(l_total_qty,0) / p_ip);
            END IF;
         ELSE
            p_no_of_incmp_ca := 0;
            p_ip_qty_in_alt_uom := 0;
            p_ip_qty := 0;
         END IF;

         p_total_no_of_label := p_no_of_mp + p_no_of_ca + p_no_of_incmp_ca;
      /*xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'p_no_of_incmp_ca : ' || p_no_of_incmp_ca
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'p_ip_qty_in_alt_uom : ' || p_ip_qty_in_alt_uom
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'p_ip_qty : ' || p_ip_qty);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'l_total_qty : ' || l_total_qty
                           );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'p_total_no_of_label : ' || p_total_no_of_label
                           );*/
      --
      --DBMS_OUTPUT.put_line ('p_no_of_incmp_ca : ' || p_no_of_incmp_ca);
      --DBMS_OUTPUT.put_line ('p_ip_qty_in_alt_uom : ' || p_ip_qty_in_alt_uom);
      --DBMS_OUTPUT.put_line ('p_ip_qty : ' || p_ip_qty);
      --DBMS_OUTPUT.put_line ('l_total_qty : ' || l_total_qty);
      --DBMS_OUTPUT.put_line ('p_total_no_of_label : ' || p_total_no_of_label);
      END IF;

      RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         --DBMS_OUTPUT.put_line
         --                 (   'error in update_run_date procedure : Others=>'
         --                  || SQLERRM
         --                 );
         xx_emf_pkg.write_log
                         (xx_emf_cn_pkg.cn_low,
                             'Error in get_case_details procedure : Others=>'
                          || SQLERRM
                         );
         RETURN x_error_code;
   END get_case_details;
--
END xx_order_common_comp_pkg;
/


GRANT EXECUTE ON APPS.XX_ORDER_COMMON_COMP_PKG TO INTG_XX_NONHR_RO;
