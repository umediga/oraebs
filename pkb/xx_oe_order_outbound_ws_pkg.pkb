DROP PACKAGE BODY APPS.XX_OE_ORDER_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_ORDER_OUTBOUND_WS_PKG" 
AS
/* $Header: XXOEORDOUTWS.pks 1.1.0 2012/03/07 00:00:00 kdas noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       : XXOEORDOUTWS.pkb
 Description    : Sales Order Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.
 26-Feb-2014   1.1       Bedabrata           Modification for GHX
 */
--------------------------------------------------------------------------------
   FUNCTION xx_get_line_item_status_code (
      p_source_header_id   NUMBER,
      p_source_line_id     NUMBER
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 13-APR-2012
 Filename       :
 Description    : This function return the Line Item Status Code.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 13-Apr-2012   1.0       Koushik Das         Initial development.
 26-Feb-2014   1.1       Bedabrata           Modification for GHX
 */
--------------------------------------------------------------------------------
      x_line_item_status_code   VARCHAR2 (20) := NULL;
      x_edi_invalid_item        VARCHAR2 (200):= 'EDIINVALID'; -- GHX
      x_item_backordered        VARCHAR2 (20) := 'IB'; -- GHX
      x_item_shipped            VARCHAR2 (20) := 'AC';
      x_item_on_hold            VARCHAR2 (20) := 'IH';
      x_item_rejected           VARCHAR2 (20) := 'IR'; -- GHX
      x_item_price_changed      VARCHAR2 (20) := 'IP'; -- GHX
      x_item_uom_changed        VARCHAR2 (20) := 'IC'; -- GHX
      x_default                 VARCHAR2 (20) := 'IA';


   BEGIN
      -- for IH
      IF x_line_item_status_code IS NULL
      THEN
         BEGIN
            SELECT x_item_on_hold
              INTO x_line_item_status_code
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM oe_order_holds_all oh
                       WHERE oh.header_id = p_source_header_id
                         AND oh.line_id = p_source_line_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               x_line_item_status_code := NULL;
         END;
      END IF;

      -- for AC
      IF x_line_item_status_code IS NULL
      THEN
         BEGIN
            SELECT x_item_shipped
              INTO x_line_item_status_code
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM wsh_delivery_details wdd
                       WHERE wdd.source_header_id = p_source_header_id
                         AND wdd.source_line_id = p_source_line_id
                         AND wdd.source_code = 'OE'
                         AND wdd.released_status = 'C');
         EXCEPTION
            WHEN OTHERS
            THEN
               x_line_item_status_code := NULL;
         END;
      END IF;

     -- for IB
      IF x_line_item_status_code IS NULL
      THEN
         BEGIN
            SELECT x_item_backordered
              INTO x_line_item_status_code
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM wsh_delivery_details wdd
                       WHERE wdd.source_header_id = p_source_header_id
                         AND wdd.source_line_id = p_source_line_id
                         AND wdd.source_code = 'OE'
                         AND wdd.released_status = 'B');
         EXCEPTION
            WHEN OTHERS
            THEN
               x_line_item_status_code := NULL;
         END;
      END IF;

     -- for IR
      IF x_line_item_status_code IS NULL
      THEN
         BEGIN
            SELECT x_item_rejected
              INTO x_line_item_status_code
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM oe_order_lines_all ol
                       WHERE ol.header_id = p_source_header_id
                         AND ol.line_id = p_source_line_id
                         AND ol.ordered_item = x_edi_invalid_item);
         EXCEPTION
            WHEN OTHERS
            THEN
               x_line_item_status_code := NULL;
         END;
      END IF;

      -- for IC
      IF x_line_item_status_code IS NULL
      THEN
         BEGIN
            SELECT x_item_uom_changed
              INTO x_line_item_status_code
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM oe_order_lines_all ol
                       WHERE ol.header_id = p_source_header_id
                         AND ol.line_id = p_source_line_id
                         AND ol.order_quantity_uom <> NVL(ol.tp_attribute1,'XX'));
         EXCEPTION
            WHEN OTHERS
            THEN
               x_line_item_status_code := NULL;
         END;
      END IF;

      -- for IP
      IF x_line_item_status_code IS NULL
      THEN
         BEGIN
            SELECT x_item_price_changed
              INTO x_line_item_status_code
              FROM DUAL
             WHERE EXISTS (
                      SELECT 1
                        FROM oe_order_lines_all ol
                       WHERE ol.header_id = p_source_header_id
                         AND ol.line_id = p_source_line_id
                         AND NVL(ol.customer_item_net_price,0)-NVL(ol.unit_selling_price,0)<>0);
         EXCEPTION
            WHEN OTHERS
            THEN
               x_line_item_status_code := NULL;
         END;
      END IF;


      IF x_line_item_status_code IS NULL
      THEN
         x_line_item_status_code := x_default;
      END IF;

      RETURN x_line_item_status_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN x_default;
   END xx_get_line_item_status_code;

   PROCEDURE xx_get_order (
      p_mode               IN              VARCHAR2,
      p_publish_batch_id   IN              NUMBER,
      p_oe_input_order     IN              xx_oe_input_ord_ws_out_tabtyp,
      x_oe_output_order    OUT NOCOPY      xx_oe_ord_outbound_ws_tabtyp,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   )
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Description    : This procedure is called by the AIA Web Service
                  to fetch Sales Order details.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.

 */
--------------------------------------------------------------------------------
      CURSOR c_header_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xoohw.*
           FROM xx_oe_order_headers_ws_v xoohw,
                (SELECT DISTINCT header_id
                            FROM xx_oe_order_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id) xoops
          WHERE xoohw.header_id = xoops.header_id;

      CURSOR c_line_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xoolw.*
           FROM xx_oe_order_lines_ws_v xoolw,
                (SELECT DISTINCT header_id
                            FROM xx_oe_order_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id) xoops
          WHERE xoolw.header_id = xoops.header_id;

      x_publish_batch_id       NUMBER               := NULL;
      e_incorrect_mode         EXCEPTION;

      TYPE oe_order_publish_tbl IS TABLE OF xx_oe_order_publish_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_oe_order_publish_tbl   oe_order_publish_tbl;

      TYPE oe_order_headers_tbl IS TABLE OF xx_oe_order_headers_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_oe_order_headers_tbl   oe_order_headers_tbl;

      TYPE oe_order_lines_tbl IS TABLE OF xx_oe_order_lines_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_oe_order_lines_tbl     oe_order_lines_tbl;
   BEGIN
      x_publish_batch_id := p_publish_batch_id;

      IF p_mode IS NULL OR p_mode NOT IN ('BATCH', 'LIST')
      THEN
         RAISE e_incorrect_mode;
      END IF;

      IF p_mode = 'LIST'
      THEN
         SELECT xx_oe_order_publish_stg_s1.NEXTVAL
           INTO x_publish_batch_id
           FROM DUAL;

         x_oe_order_publish_tbl.DELETE;

         FOR i IN 1 .. p_oe_input_order.COUNT
         LOOP
            x_oe_order_publish_tbl (i).publish_batch_id := x_publish_batch_id;
            x_oe_order_publish_tbl (i).header_id :=
                                               p_oe_input_order (i).header_id;
            x_oe_order_publish_tbl (i).publish_time := SYSDATE;
            x_oe_order_publish_tbl (i).publish_system := NULL;
            x_oe_order_publish_tbl (i).ack_status := NULL;
            x_oe_order_publish_tbl (i).ack_time := NULL;
            x_oe_order_publish_tbl (i).aia_proc_inst_id := NULL;
            x_oe_order_publish_tbl (i).creation_date := SYSDATE;
            x_oe_order_publish_tbl (i).created_by := fnd_global.user_id;
            x_oe_order_publish_tbl (i).last_update_date := SYSDATE;
            x_oe_order_publish_tbl (i).last_updated_by := fnd_global.user_id;
            x_oe_order_publish_tbl (i).last_update_login :=
                                                           fnd_global.user_id;
         END LOOP;

         IF x_oe_order_publish_tbl.COUNT > 0
         THEN
            FORALL i_rec IN 1 .. x_oe_order_publish_tbl.COUNT
               INSERT INTO xx_oe_order_publish_stg
                    VALUES x_oe_order_publish_tbl (i_rec);
         END IF;
      END IF;

      OPEN c_header_info (x_publish_batch_id);

      FETCH c_header_info
      BULK COLLECT INTO x_oe_order_headers_tbl;

      CLOSE c_header_info;

      IF x_oe_order_headers_tbl.COUNT > 0
      THEN
         FOR i IN x_oe_order_headers_tbl.FIRST .. x_oe_order_headers_tbl.LAST
         LOOP
            x_oe_order_headers_tbl (i).publish_batch_id := x_publish_batch_id;
         END LOOP;

         FORALL i_rec IN 1 .. x_oe_order_headers_tbl.COUNT
            INSERT INTO xx_oe_order_headers_stg
                 VALUES x_oe_order_headers_tbl (i_rec);
      END IF;

      OPEN c_line_info (x_publish_batch_id);

      FETCH c_line_info
      BULK COLLECT INTO x_oe_order_lines_tbl;

      CLOSE c_line_info;

      IF x_oe_order_lines_tbl.COUNT > 0
      THEN
         FOR i IN x_oe_order_lines_tbl.FIRST .. x_oe_order_lines_tbl.LAST
         LOOP
            x_oe_order_lines_tbl (i).publish_batch_id := x_publish_batch_id;
         END LOOP;

         FORALL i_rec IN 1 .. x_oe_order_lines_tbl.COUNT
            INSERT INTO xx_oe_order_lines_stg
                 VALUES x_oe_order_lines_tbl (i_rec);
      END IF;

      SELECT CAST
                (MULTISET (SELECT *
                             FROM xx_oe_order_outbound_ws_v
                            WHERE publish_batch_id = x_publish_batch_id) AS xx_oe_ord_outbound_ws_tabtyp
                )
        INTO x_oe_output_order
        FROM DUAL;

      x_return_status := 'S';
      x_return_message := NULL;
   EXCEPTION
      WHEN e_incorrect_mode
      THEN
         x_return_status := 'E';
         x_return_message := 'Mode is mandatory and can be BATCH or LIST';
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END xx_get_order;

   PROCEDURE xx_update_ack (
      p_publish_batch_id   IN              NUMBER,
      p_publish_system     IN              VARCHAR2,
      p_ack_status         IN              VARCHAR2,
      p_aia_proc_inst_id   IN              VARCHAR2,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   )
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Description    : This procedure is called by the AIA Web Service
                  to update the Acknowledgement Status to Ebiz.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.

 */
--------------------------------------------------------------------------------
   BEGIN
      IF p_publish_batch_id IS NOT NULL
      THEN
         UPDATE xx_oe_order_publish_stg
            SET ack_status = p_ack_status,
                ack_time = SYSDATE,
                aia_proc_inst_id = p_aia_proc_inst_id,
                last_update_date = SYSDATE,
                last_updated_by = fnd_global.user_id,
                last_update_login = fnd_global.user_id
          WHERE publish_batch_id = p_publish_batch_id
            AND publish_system = NVL (p_publish_system, publish_system);
      END IF;

      x_return_status := 'S';
      x_return_message := NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END xx_update_ack;
END xx_oe_order_outbound_ws_pkg;
/
