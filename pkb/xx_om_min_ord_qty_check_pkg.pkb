DROP PACKAGE BODY APPS.XX_OM_MIN_ORD_QTY_CHECK_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_MIN_ORD_QTY_CHECK_PKG" 
----------------------------------------------------------------------
/* $Header: XXOMMINORDQTY.pkb 1.0 2012/03/23 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 23-Mar-2012
 File Name      : XXOMMINORDQTY.pkb
 Description    : This script creates the specification of the xx_om_min_ord_qty_check_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     23-Mar-12   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
AS
   PROCEDURE xx_om_msg_update (p_min_ord_qty IN NUMBER,p_pc_id1 number,p_pc_id2 number)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      x_err_msg   VARCHAR2 (2000);
   BEGIN
      UPDATE oe_pc_conditions_vl
         SET user_message =
                   'Order Quantity Is Less Than Minimum Order Quantity '
                || p_min_ord_qty
       WHERE constraint_id IN (p_pc_id1, p_pc_id2);

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_err_msg := 'Error In MSG Update :' || SUBSTR (SQLERRM, 1, 100);
         oe_msg_pub.add_text (x_err_msg);
         oe_debug_pub.ADD (x_err_msg);
   END;

-- =================================================================================
-- Name           : xx_om_chk_qty_pc
-- Description    : This Procedure Will Invoked At Processing Constraint Level
--                  This will return either 1(fail) if the order quantity is less than Minimum Qty
--                  and for all other cases it will return 0(sucess)
--
-- Parameters description       :
--
-- p_application_id                    : Parameter To Store application id (IN)
-- p_entity_short_name                 : Parameter To Entity Short Name  (IN)
-- p_validation_entity_short_name      : Parameter To Validation Entity Short Name (IN)
-- p_validation_tmplt_short_name       : Parameter (IN)
-- p_record_set_tmplt_short_name       : Parameter (IN)
-- p_scope                             : Parameter (IN)
-- p_result                            : Parameter To Return Value (OUT)
-- ==============================================================================
   PROCEDURE xx_om_chk_qty_pc (
      p_application_id                 IN              NUMBER,
      p_entity_short_name              IN              VARCHAR2,
      p_validation_entity_short_name   IN              VARCHAR2,
      p_validation_tmplt_short_name    IN              VARCHAR2,
      p_record_set_tmplt_short_name    IN              VARCHAR2,
      p_scope                          IN              VARCHAR2,
      p_result                         OUT NOCOPY      NUMBER
   )
   IS
      x_ordered_quantity         NUMBER         := NULL;
      x_inventory_item_id        NUMBER         := NULL;
      x_minimum_order_quantity   VARCHAR2 (10);
      x_prc_id                   NUMBER;
      x_prc_hdr_id               NUMBER;
      x_err_msg                  VARCHAR2 (200) := NULL;
      x_label_name               VARCHAR2 (200) := NULL;
      x_count                    NUMBER;
      x_pc_id1                   NUMBER;
      x_pc_id2                   NUMBER;

      -- Cursor to extract minimum order quantity
      CURSOR c_min_ord_qty (
         p_price_list_id   NUMBER,
         p_item_id         NUMBER,
         p_label_name      VARCHAR2
      )
      IS
         SELECT qll.attribute2
           FROM qp_list_lines qll,
                qp_list_headers qlh,
                qp_pricing_attributes qpa
          WHERE 1 = 1
            AND qlh.list_header_id = p_price_list_id
            AND qll.list_header_id = qlh.list_header_id
            AND UPPER (qlh.NAME) LIKE '%' || p_label_name || '%'
            AND qll.list_line_type_code = 'PLL'
            AND SYSDATE BETWEEN NVL (qlh.start_date_active, SYSDATE)
                            AND NVL (qlh.end_date_active, SYSDATE)
            AND SYSDATE BETWEEN NVL (qll.start_date_active, SYSDATE)
                            AND NVL (qll.end_date_active, SYSDATE)
            AND qlh.active_flag = 'Y'
            AND qlh.list_header_id = qpa.list_header_id
            AND qll.list_line_id = qpa.list_line_id
            AND qpa.product_attr_value = TO_CHAR (p_item_id);

      CURSOR c_pc_id
      IS
         SELECT constraint_id
           FROM oe_pc_conditions_vl
          WHERE user_message LIKE
                         'Order Quantity Is Less Than Minimum Order Quantity%';
   BEGIN
      x_prc_id := oe_line_security.g_record.price_list_id;
      x_prc_hdr_id := oe_header_security.g_record.price_list_id;
      x_ordered_quantity := oe_line_security.g_record.ordered_quantity;
      x_inventory_item_id := oe_line_security.g_record.inventory_item_id;
      x_label_name :=
                xx_emf_pkg.get_paramater_value (g_process_name, g_label_name);

      OPEN c_min_ord_qty (NVL (x_prc_id, x_prc_hdr_id),
                          x_inventory_item_id,
                          x_label_name
                         );

      FETCH c_min_ord_qty
       INTO x_minimum_order_quantity;

      CLOSE c_min_ord_qty;

      IF (    x_inventory_item_id IS NOT NULL
          AND x_ordered_quantity < x_minimum_order_quantity
         )
      THEN
         x_count := 1;

         FOR rec_pc_id IN c_pc_id
         LOOP
            p_pc_msg_table (x_count).pc_id := rec_pc_id.constraint_id;
            x_count := x_count + 1;
         END LOOP;

         x_pc_id1 := p_pc_msg_table (1).pc_id;
         x_pc_id2 := p_pc_msg_table (2).pc_id;
         xx_om_msg_update (x_minimum_order_quantity,x_pc_id1,x_pc_id2);
         p_result := 1;
      ELSE
         p_result := 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_result := 0;
      WHEN OTHERS
      THEN
         x_err_msg := 'Error :' || SUBSTR (SQLERRM, 1, 100);
         oe_msg_pub.add_text (x_err_msg);
         oe_debug_pub.ADD (x_err_msg);
         p_result := 0;
   END xx_om_chk_qty_pc;

-- =================================================================================
-- Name           : xx_om_chk_qty_form
-- Description    : This Function Will Invoked At Form Personalization Level
--                  This will return message if quantity is defined for the Item in DFF attribute
--                  else it will return a null message.
-- Parameters description       :
--
-- p_price_list_name  : Parameter To Store Price List Name (IN)
-- p_inv_item_id      : Parameter To Store Item ID (IN)
-- ==============================================================================
   FUNCTION xx_om_chk_qty_form (
      p_price_list_name   VARCHAR2,
      p_inv_item_id       NUMBER
   )
      RETURN VARCHAR2
   IS
      x_minimum_order_quantity   NUMBER;
      x_err_msg                  VARCHAR2 (200) := NULL;
      x_label_name               VARCHAR2 (200) := NULL;

      -- Cursor to extract minimum order quantity
      CURSOR c_min_ord_qty (
         p_price_list   VARCHAR2,
         p_item_id      NUMBER,
         p_label_name   VARCHAR2
      )
      IS
         SELECT DISTINCT qll.attribute2
                    FROM qp_list_lines qll,
                         qp_list_headers qlh,
                         qp_pricing_attributes qpa
                   WHERE 1 = 1
                     AND UPPER (p_price_list) IN (
                             SELECT DISTINCT UPPER (NAME)
                                        FROM qp_list_headers
                                       WHERE UPPER (NAME) LIKE
                                                    '%' || p_label_name || '%')
                     AND qll.list_header_id = qlh.list_header_id
                     AND UPPER (qlh.NAME) = UPPER (p_price_list)
                     AND qll.list_line_type_code = 'PLL'
                     AND SYSDATE BETWEEN NVL (qlh.start_date_active, SYSDATE)
                                     AND NVL (qlh.end_date_active, SYSDATE)
                     AND SYSDATE BETWEEN NVL (qll.start_date_active, SYSDATE)
                                     AND NVL (qll.end_date_active, SYSDATE)
                     AND qlh.active_flag = 'Y'
                     AND qlh.list_header_id = qpa.list_header_id
                     AND qll.list_line_id = qpa.list_line_id
                     AND qpa.product_attr_value = TO_CHAR (p_item_id);
   BEGIN
      x_label_name :=
                xx_emf_pkg.get_paramater_value (g_process_name, g_label_name);

      OPEN c_min_ord_qty (p_price_list_name, p_inv_item_id, x_label_name);

      FETCH c_min_ord_qty
       INTO x_minimum_order_quantity;

      CLOSE c_min_ord_qty;

      IF x_minimum_order_quantity IS NOT NULL
      THEN
         RETURN (   'Minimum Order Quantity For This Item Is '
                 || x_minimum_order_quantity
                );
      ELSE
         RETURN (' ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_err_msg := 'Error :' || SUBSTR (SQLERRM, 1, 100);
         oe_msg_pub.add_text (x_err_msg);
         oe_debug_pub.ADD (x_err_msg);
         RETURN (' ');
   END xx_om_chk_qty_form;
END xx_om_min_ord_qty_check_pkg;
/
