DROP PACKAGE BODY APPS.XX_WSH_ASN_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_WSH_ASN_OUTBOUND_WS_PKG" 
IS
/* $Header: XXWSHASNOUTBOUNDWS.pkb 1.0.0 2012/03/20 00:00:00 bedabrata noship $ */
-----------------------------------------------------------------------------------
 /*
 Created By     : Bedabrata Bhattacharjee (IBM)
 Creation Date  : 20-MAR-2012
 Filename       : XXWSHASNOUTBOUNDWS.pkb
 Description    : Approved Shipment Number (ASN) Outbound Web Service API.

 Change History:

 Date        Issue#   Name                           Remarks
 ----------- -------- -----------------------------  ------------------------------
 20-Mar-2012        1 Bedabrata Bhattacharjee (IBM)  Initial Development.

*/
-----------------------------------------------------------------------------------
   PROCEDURE xx_get_asn (
      p_mode               IN              VARCHAR2
    , p_publish_batch_id   IN              NUMBER
    , p_delivery_list      IN              xx_wsh_input_del_ws_tabtyp
    , x_wsh_output_asn     OUT NOCOPY      xx_wsh_asn_out_ws_tabtyp
    , x_return_status      OUT NOCOPY      VARCHAR2
    , x_return_message     OUT NOCOPY      VARCHAR2
   )
   IS
-----------------------------------------------------------------------------------
 /*
 Created By     : Bedabrata Bhattacharjee
 Creation Date  : 20-MAR-2012
 Description    : This procedure is called by the BPEL Web Service
                  to fetch ASN details. P_MODE = LIST or BATCH

 Change History:

 Date        Issue#   Name                           Remarks
 ----------- -------- -----------------------------  ------------------------------
 20-Mar-2012        1 Bedabrata Bhattacharjee (IBM)  Initial Development.

*/
-----------------------------------------------------------------------------------
   -- Cursor to fetch Deliveries for the publish batch Id
      CURSOR cur_deliveries (cp_publish_batch_id IN NUMBER)
      IS
         SELECT xwdwv.*
           FROM xx_wsh_asn_publish_stg xwaps
              , xx_wsh_deliveries_ws_v xwdwv
          WHERE xwaps.publish_batch_id = cp_publish_batch_id
            AND xwaps.delivery_id = xwdwv.delivery_id;

      -- Cursor to fetch Orders for the publish batch Id
      CURSOR cur_orders (cp_publish_batch_id IN NUMBER)
      IS
         SELECT xwowv.*
           FROM xx_wsh_asn_publish_stg xwaps
              , xx_wsh_orders_ws_v xwowv
          WHERE xwaps.publish_batch_id = cp_publish_batch_id
            AND xwaps.delivery_id = xwowv.delivery_id;

      -- Cursor to fetch Items for the publish batch Id
      CURSOR cur_items (cp_publish_batch_id IN NUMBER)
      IS
         SELECT xwiwv.*
           FROM xx_wsh_asn_publish_stg xwaps
              , xx_wsh_items_ws_v xwiwv
          WHERE xwaps.publish_batch_id = cp_publish_batch_id
            AND xwaps.delivery_id = xwiwv.delivery_id;

      -- Table Type Variable for Delivery Staging Table
      TYPE x_wsh_deliveries_stg_typ IS TABLE OF xx_wsh_deliveries_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_wsh_deliveries_stg_tbl   x_wsh_deliveries_stg_typ;

      -- Table Type Variable for Orders Staging Table
      TYPE x_wsh_orders_stg_typ IS TABLE OF xx_wsh_orders_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_wsh_orders_stg_tbl       x_wsh_orders_stg_typ;

      -- Table Type Variable for Items Staging Table
      TYPE x_wsh_items_stg_typ IS TABLE OF xx_wsh_items_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_wsh_items_stg_tbl        x_wsh_items_stg_typ;
      x_publish_batch_id         NUMBER;
      e_outer_exception          EXCEPTION;
      e_incorrect_mode           EXCEPTION;
   BEGIN
      x_publish_batch_id := p_publish_batch_id;
      x_return_status := 'S';
      x_return_message := NULL;

      IF p_mode IS NULL OR p_mode NOT IN ('BATCH', 'LIST')
      THEN
         RAISE e_incorrect_mode;
      END IF;

      -- logic for mode = LIST
      IF p_mode = 'LIST'
      THEN
         BEGIN
            SELECT xx_wsh_asn_publish_batch_id_s1.NEXTVAL
              INTO x_publish_batch_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_publish_batch_id := NULL;
               x_return_message :=
                     'LIST Mode. Unable to generate Publish Batch Id. Error: '
                  || SQLERRM;
               RAISE e_outer_exception;
         END;

         BEGIN
            FOR i IN p_delivery_list.FIRST .. p_delivery_list.LAST
            LOOP
               INSERT INTO xx_wsh_asn_publish_stg
                           (publish_batch_id
                          , delivery_id
                          , publish_time
                          , publish_system
                          , ack_status
                          , ack_time
                          , aia_proc_inst_id
                          , creation_date
                          , created_by
                          , last_update_date
                          , last_updated_by
                          , last_update_login
                           )
                    VALUES (x_publish_batch_id
                          , p_delivery_list (i).delivery_id
                          , SYSDATE
                          , NULL
                          , NULL
                          , NULL
                          , NULL
                          , SYSDATE
                          , fnd_global.user_id
                          , SYSDATE
                          , fnd_global.user_id
                          , fnd_global.user_id
                           );
            END LOOP;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_return_message :=
                     'LIST Mode. Unable to Insert data into Publish Control Table. Error: '
                  || SQLERRM;
               RAISE e_outer_exception;
         END;
      END IF;

      --
      --- Fetch Data and Insert into Staging Table
      -- Fetch Deliveries
      OPEN cur_deliveries (x_publish_batch_id);

      LOOP
         EXIT WHEN cur_deliveries%NOTFOUND;

         FETCH cur_deliveries
         BULK COLLECT INTO x_wsh_deliveries_stg_tbl;
      END LOOP;

      FOR i IN x_wsh_deliveries_stg_tbl.FIRST .. x_wsh_deliveries_stg_tbl.LAST
      LOOP
         x_wsh_deliveries_stg_tbl (i).publish_batch_id := x_publish_batch_id;
      END LOOP;

      -- Fetch Orders
      OPEN cur_orders (x_publish_batch_id);

      LOOP
         EXIT WHEN cur_orders%NOTFOUND;

         FETCH cur_orders
         BULK COLLECT INTO x_wsh_orders_stg_tbl;
      END LOOP;

      FOR i IN x_wsh_orders_stg_tbl.FIRST .. x_wsh_orders_stg_tbl.LAST
      LOOP
         x_wsh_orders_stg_tbl (i).publish_batch_id := x_publish_batch_id;
      END LOOP;

      -- Fetch Items
      OPEN cur_items (x_publish_batch_id);

      LOOP
         EXIT WHEN cur_items%NOTFOUND;

         FETCH cur_items
         BULK COLLECT INTO x_wsh_items_stg_tbl;
      END LOOP;

      FOR i IN x_wsh_items_stg_tbl.FIRST .. x_wsh_items_stg_tbl.LAST
      LOOP
         x_wsh_items_stg_tbl (i).publish_batch_id := x_publish_batch_id;
      END LOOP;

      --
      --- Insert into Staging Tables
      -- Insert into Delivery stg tables
      BEGIN
         FORALL i_rec IN 1 .. x_wsh_deliveries_stg_tbl.COUNT
            INSERT INTO xx_wsh_deliveries_stg
                 VALUES x_wsh_deliveries_stg_tbl (i_rec);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_message :=
                  'Unable to Insert data into Deliveries Staging Table. Error: '
               || SQLERRM;
            RAISE e_outer_exception;
      END;

      -- Insert into Orders stg tables
      BEGIN
         FORALL i_rec IN 1 .. x_wsh_orders_stg_tbl.COUNT
            INSERT INTO xx_wsh_orders_stg
                 VALUES x_wsh_orders_stg_tbl (i_rec);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_message :=
                  'Unable to Insert data into Orders Staging Table. Error: '
               || SQLERRM;
            RAISE e_outer_exception;
      END;

      -- Insert into Items stg tables
      BEGIN
         FORALL i_rec IN 1 .. x_wsh_items_stg_tbl.COUNT
            INSERT INTO xx_wsh_items_stg
                 VALUES x_wsh_items_stg_tbl (i_rec);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_message :=
                  'Unable to Insert data into Items Staging Table. Error: '
               || SQLERRM;
            RAISE e_outer_exception;
      END;

      -- Fetch Data for Publishing to Target System
      SELECT CAST
                (MULTISET (SELECT *
                             FROM xx_wsh_asn_outbound_ws_v
                            WHERE publish_batch_id = x_publish_batch_id) AS xx_wsh_asn_out_ws_tabtyp
                )
        INTO x_wsh_output_asn
        FROM DUAL;

      --
      x_return_status := 'S';
      x_return_message := NULL;
   EXCEPTION
      WHEN e_incorrect_mode
      THEN
         x_return_status := 'E';
         x_return_message :=
                    'Mode is mandatory. Value should be either BATCH or LIST';
      WHEN e_outer_exception
      THEN
         x_return_status := 'E';
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END xx_get_asn;

--
--
   PROCEDURE xx_update_ack (
      p_publish_batch_id   IN              NUMBER
    , p_publish_system     IN              VARCHAR2
    , p_aia_proc_inst_id   IN              NUMBER
    , p_ack_status         IN              VARCHAR2
    , x_return_status      OUT NOCOPY      VARCHAR2
    , x_return_message     OUT NOCOPY      VARCHAR2
   )
   IS
-----------------------------------------------------------------------------------
 /*
 Created By     : Bedabrata Bhattacharjee
 Creation Date  : 22-MAR-2012
 Description    : TThis procedure is called by the AIA Web Service
                  to update the Acknowledgement Status to Ebiz.

 Change History:

 Date        Issue#   Name                           Remarks
 ----------- -------- -----------------------------  ------------------------------
 22-Mar-2012        1 Bedabrata Bhattacharjee (IBM)  Initial Development.

*/
-----------------------------------------------------------------------------------
   BEGIN
      IF p_publish_batch_id IS NOT NULL
      THEN
         UPDATE xx_wsh_asn_publish_stg
            SET ack_status = p_ack_status
              , ack_time = SYSDATE
              , aia_proc_inst_id = p_aia_proc_inst_id
              , last_update_date = SYSDATE
              , last_updated_by = fnd_global.user_id
              , last_update_login = fnd_global.user_id
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
--
--
END xx_wsh_asn_outbound_ws_pkg;
/
