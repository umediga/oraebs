DROP PACKAGE BODY APPS.XX_OE_PUBLISH_ORDER_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_PUBLISH_ORDER_PKG" 
AS
/* $Header: XXOEPUBLISHORD.pkb 1.0.0 2012/03/07 00:00:00 kdas noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       : XXOEPUBLISHORD.pkb
 Description    : Sales Order Publish Public API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.
 05-Sep-2012   1.0       Koushik Das         Added the procedure xx_publish_order_scheduled.
 10-Oct-2012     2       Koushik Das         Changed as per DCR 100912.

 */
--------------------------------------------------------------------------------
   FUNCTION xx_publish_gxs_ghx (p_header_id IN NUMBER)
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       :
 Description    : This function returns Y if the order customer is interested in
                  EDI 855 transaction.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 17-May-2012   1.0       Koushik Das         Initial development.

 */
--------------------------------------------------------------------------------
      CURSOR c_translated_customer_name (cp_header_id NUMBER)
      IS
         SELECT ship_cas.attribute4 translated_customer_name
           FROM hz_cust_site_uses_all ship_su,
                hz_party_sites ship_ps,
                hz_locations ship_loc,
                hz_cust_acct_sites_all ship_cas,
                oe_order_headers_all h
          WHERE h.ship_to_org_id = ship_su.site_use_id(+)
            AND ship_su.cust_acct_site_id = ship_cas.cust_acct_site_id(+)
            AND ship_cas.party_site_id = ship_ps.party_site_id(+)
            AND ship_loc.location_id(+) = ship_ps.location_id
            AND h.header_id = cp_header_id;

      CURSOR c_lookup (cp_translated_customer_name VARCHAR2)
      IS
         SELECT lookup_code
           FROM oe_lookups
          WHERE lookup_type = 'INTG_855_PARTNERS_GXS'
            AND enabled_flag = 'Y'
            AND (   end_date_active IS NULL
                 OR TRUNC (end_date_active) >= TRUNC (SYSDATE)
                )
            AND lookup_code = cp_translated_customer_name;

      CURSOR c_order_source (cp_header_id NUMBER)
      IS
         SELECT s.NAME order_source
           FROM oe_order_headers_all h,
                oe_order_sources s
          WHERE h.order_source_id = s.order_source_id
            AND s.NAME = 'EDIGHX'
            AND h.header_id = cp_header_id;

      x_translated_customer_name   VARCHAR2 (50);
      x_gxs_ghx                    VARCHAR2 (1);
   BEGIN
      x_gxs_ghx := 'N';

      FOR translated_customer_name_rec IN
         c_translated_customer_name (p_header_id)
      LOOP
         x_translated_customer_name :=
                        translated_customer_name_rec.translated_customer_name;

         IF x_translated_customer_name IS NOT NULL
         THEN
            FOR lookup_rec IN c_lookup (x_translated_customer_name)
            LOOP
               x_gxs_ghx := 'Y';
            END LOOP;

            IF x_gxs_ghx = 'N'
            THEN
               FOR order_source_rec IN c_order_source (p_header_id)
               LOOP
                  x_gxs_ghx := 'Y';
               END LOOP;
            END IF;
         END IF;
      END LOOP;

      RETURN x_gxs_ghx;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_gxs_ghx := 'N';
         RETURN x_gxs_ghx;
   END xx_publish_gxs_ghx;

   PROCEDURE xx_raise_publish_event (p_publish_batch_id IN NUMBER)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
-------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       :
 Description    : This procedure raise the custom business event for Sales Order.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.

 */
--------------------------------------------------------------------------------
      x_event_parameter_list   wf_parameter_list_t;
      x_param                  wf_parameter_t;
      x_event_name             VARCHAR2 (100)
                                      := 'intg.oracle.apps.ont.order.publish';
      x_event_key              VARCHAR2 (100)      := NULL;
      x_parameter_index        NUMBER              := 0;
   BEGIN
      x_event_key := TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISSSSSSS');
      x_event_parameter_list := wf_parameter_list_t ();
      -- Add the values to the Event Parameters
      x_param := wf_parameter_t (NULL, NULL);
      x_event_parameter_list.EXTEND;
      x_param.setname ('PUBLISH_BATCH_ID');
      x_param.setvalue (p_publish_batch_id);
      x_parameter_index := x_parameter_index + 1;
      x_event_parameter_list (x_parameter_index) := x_param;
      wf_event.RAISE (p_event_name      => x_event_name,
                      p_event_key       => x_event_key,
                      p_parameters      => x_event_parameter_list
                     );
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Exception while raising business event.'
                           );
   END xx_raise_publish_event;

   FUNCTION xx_publish_xmlint_status (
      p_subscription_guid   IN              RAW,
      p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       :
 Description    : This is a subscription function for
                  oracle.apps.ont.oi.xml_int.status event.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.
 17-May-2012   2.0       Koushik Das         Added call to xx_publish_gxs_ghx.

 */
--------------------------------------------------------------------------------
      CURSOR c_header_info (cp_header_id NUMBER)
      IS
         SELECT request_date,
                order_number
           FROM oe_order_headers_all
          WHERE header_id = cp_header_id
            AND booked_flag = 'Y'
            AND flow_status_code = 'BOOKED';

      x_order_source_id    NUMBER;
      x_sold_to_org_id     NUMBER;
      x_header_id          NUMBER;
      x_org_id             NUMBER;
      x_order_type_id      NUMBER;
      x_line_ids           VARCHAR2 (4000);
      x_order_number       NUMBER;
      x_gxs_ghx            VARCHAR2 (1);
      x_request_date       DATE;
      x_publish_batch_id   NUMBER;
      x_require_publish    VARCHAR2 (1);
      x_sqlcode            NUMBER;
      x_sqlerrm            VARCHAR2 (2000);
   BEGIN
      x_order_source_id := p_event.getvalueforparameter ('ORDER_SOURCE_ID');
      x_sold_to_org_id := p_event.getvalueforparameter ('SOLD_TO_ORG_ID');
      x_header_id := p_event.getvalueforparameter ('HEADER_ID');
      x_org_id := p_event.getvalueforparameter ('ORG_ID');
      x_order_type_id := p_event.getvalueforparameter ('ORDER_TYPE_ID');
      x_line_ids := p_event.getvalueforparameter ('LINE_IDS');

      IF x_line_ids = 'ALL'
      THEN
         x_gxs_ghx := xx_publish_gxs_ghx (x_header_id);

         IF x_gxs_ghx = 'Y'
         THEN
            FOR header_info_rec IN c_header_info (x_header_id)
            LOOP
               x_request_date := header_info_rec.request_date;
               x_order_number := header_info_rec.order_number;

               BEGIN
                  SELECT 'Y'
                    INTO x_require_publish
                    FROM DUAL
                   WHERE NOT EXISTS (SELECT 1
                                       FROM xx_oe_order_publish_stg
                                      WHERE header_id = x_header_id);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     x_require_publish := 'N';
               END;

               IF x_require_publish = 'Y'
               THEN
                  BEGIN
                     SELECT xx_oe_order_publish_stg_s1.NEXTVAL
                       INTO x_publish_batch_id
                       FROM DUAL;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        x_publish_batch_id := NULL;
                  END;

                  BEGIN
                     INSERT INTO xx_oe_order_publish_stg
                                 (publish_batch_id, header_id, publish_time,
                                  publish_system, ack_status, ack_time,
                                  aia_proc_inst_id, creation_date,
                                  created_by, last_update_date,
                                  last_updated_by, last_update_login
                                 )
                          VALUES (x_publish_batch_id, x_header_id, SYSDATE,
                                  'B2B_SERVER', NULL, NULL,
                                  NULL, SYSDATE,
                                  fnd_global.user_id, SYSDATE,
                                  fnd_global.user_id, fnd_global.user_id
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        x_sqlcode := SQLCODE;
                        x_sqlerrm := SUBSTR (SQLERRM, 1, 2000);
                        RETURN 'ERROR';
                  END;

                  xx_raise_publish_event
                                     (p_publish_batch_id      => x_publish_batch_id);
               END IF;
            END LOOP;
         END IF;
      END IF;

      RETURN 'SUCCESS';
   EXCEPTION
      WHEN OTHERS
      THEN
         x_sqlcode := SQLCODE;
         x_sqlerrm := SUBSTR (SQLERRM, 1, 2000);
         RETURN 'ERROR';
   END xx_publish_xmlint_status;

   PROCEDURE xx_republish_order (
      p_errbuf       OUT NOCOPY      VARCHAR2,
      p_retcode      OUT NOCOPY      VARCHAR2,
      p_type         IN              VARCHAR2,
      p_order_from   IN              NUMBER,
      p_order_to     IN              NUMBER,
      p_date_from    IN              VARCHAR2,
      p_date_to      IN              VARCHAR2
   )
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 07-MAR-2012
 Filename       :
 Description    : This procedure is used by the republish concurrent program.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 07-Mar-2012   1.0       Koushik Das         Initial development.
 28-Aug-2012   2.0       Koushik Das         Change the cursor query to fetch data from
                                             base table and also from staging table
                                             conditionally.

 */
--------------------------------------------------------------------------------
      CURSOR c_republish_order (
         cp_type         VARCHAR2,
         cp_order_from   VARCHAR2,
         cp_order_to     VARCHAR2,
         cp_date_from    DATE,
         cp_date_to      DATE
      )
      IS
         SELECT   ooh.header_id header_id,
                  ooh.order_number order_number
             FROM oe_order_headers_all ooh
            WHERE ooh.booked_flag = 'Y'
              AND ooh.flow_status_code = 'BOOKED'
              AND cp_type = 'Resend'
              AND xx_publish_gxs_ghx (ooh.header_id) = 'Y'
              AND ooh.order_number >= NVL (cp_order_from, ooh.order_number)
              AND ooh.order_number <= NVL (cp_order_to, ooh.order_number)
              AND TRUNC (ooh.ordered_date) >=
                                  NVL (cp_date_from, TRUNC (ooh.ordered_date))
              AND TRUNC (ooh.ordered_date) <=
                                    NVL (cp_date_to, TRUNC (ooh.ordered_date))
         UNION ALL
         SELECT   xoops.header_id header_id,
                  ooh.order_number order_number
             FROM xx_oe_order_publish_stg xoops,
                  oe_order_headers_all ooh
            WHERE xoops.header_id = ooh.header_id
              AND NVL (xoops.ack_status, 'X') <> 'SUCCESS'
              AND cp_type = 'Recover'
              AND xoops.publish_batch_id =
                                      (SELECT MAX (xps.publish_batch_id)
                                         FROM xx_oe_order_publish_stg xps
                                        WHERE xoops.header_id = xps.header_id)
              AND xx_publish_gxs_ghx (ooh.header_id) = 'Y'
              AND ooh.order_number >= NVL (cp_order_from, ooh.order_number)
              AND ooh.order_number <= NVL (cp_order_to, ooh.order_number)
              AND TRUNC (ooh.ordered_date) >=
                                  NVL (cp_date_from, TRUNC (ooh.ordered_date))
              AND TRUNC (ooh.ordered_date) <=
                                    NVL (cp_date_to, TRUNC (ooh.ordered_date))
         ORDER BY order_number;

      x_type               VARCHAR2 (80);
      x_order_from         oe_order_headers_all.order_number%TYPE;
      x_order_to           oe_order_headers_all.order_number%TYPE;
      x_date_from          DATE;
      x_date_to            DATE;
      x_publish_batch_id   NUMBER;
      x_order_number       oe_order_headers_all.order_number%TYPE;
      x_header_id          oe_order_headers_all.header_id%TYPE;
   BEGIN
      x_type := p_type;
      x_order_from := p_order_from;
      x_order_to := p_order_to;
      x_date_from := fnd_date.canonical_to_date (p_date_from);
      x_date_to := fnd_date.canonical_to_date (p_date_to);
      fnd_file.put_line (fnd_file.LOG, 'Paramteres: ');
      fnd_file.put_line (fnd_file.LOG, 'Order Number From: ' || x_order_from);
      fnd_file.put_line (fnd_file.LOG, 'Order Number To: ' || x_order_to);
      fnd_file.put_line (fnd_file.LOG, 'Ordered Date From: ' || x_date_from);
      fnd_file.put_line (fnd_file.LOG, 'Ordered Date To: ' || x_date_to);
      fnd_file.put_line (fnd_file.LOG, 'Published Orders: ');

      FOR republish_order_rec IN c_republish_order (x_type,
                                                    x_order_from,
                                                    x_order_to,
                                                    x_date_from,
                                                    x_date_to
                                                   )
      LOOP
         BEGIN
            SELECT xx_oe_order_publish_stg_s1.NEXTVAL
              INTO x_publish_batch_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_publish_batch_id := NULL;
         END;

         x_header_id := republish_order_rec.header_id;
         x_order_number := republish_order_rec.order_number;

         BEGIN
            INSERT INTO xx_oe_order_publish_stg
                        (publish_batch_id, header_id, publish_time,
                         publish_system, ack_status, ack_time,
                         aia_proc_inst_id, creation_date, created_by,
                         last_update_date, last_updated_by, last_update_login
                        )
                 VALUES (x_publish_batch_id, x_header_id, SYSDATE,
                         'B2B_SERVER', NULL, NULL,
                         NULL, SYSDATE, fnd_global.user_id,
                         SYSDATE, fnd_global.user_id, fnd_global.user_id
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                                (fnd_file.LOG,
                                 'Exception occurred while inserting data...'
                                );
               fnd_file.put_line (fnd_file.LOG, SQLCODE || '-' || SQLERRM);
         END;

         fnd_file.put_line (fnd_file.LOG, 'Order Number: ' || x_order_number);
         xx_raise_publish_event (p_publish_batch_id => x_publish_batch_id);
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Exception occurred while resubmitting...'
                           );
         fnd_file.put_line (fnd_file.LOG, SQLCODE || '-' || SQLERRM);
   END xx_republish_order;

   PROCEDURE xx_publish_order_scheduled (
      p_errbuf    OUT NOCOPY   VARCHAR2,
      p_retcode   OUT NOCOPY   VARCHAR2
   )
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 05-SEP-2012
 Filename       :
 Description    : This procedure is used by the scheduled publish concurrent program.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 05-Sep-2012   1.0       Koushik Das         Initial development.

 */
--------------------------------------------------------------------------------
      CURSOR c_publish_order
      IS
         SELECT   ooh.header_id header_id,
                  ooh.order_number order_number
             FROM oe_order_headers_all ooh
            WHERE 1 = 1
              AND ooh.booked_flag = 'Y'
              AND ooh.flow_status_code = 'BOOKED'
              AND xx_publish_gxs_ghx (ooh.header_id) = 'Y'
              AND NOT EXISTS (SELECT 1
                                FROM oe_order_holds_all oh
                               WHERE oh.header_id = ooh.header_id)
              AND NOT EXISTS (SELECT 1
                                FROM xx_oe_order_publish_stg xps
                               WHERE xps.header_id = ooh.header_id)
              AND NOT EXISTS (
                     SELECT 1
                       FROM oe_order_lines_all ool
                      WHERE ooh.header_id = ool.header_id
                        AND ool.schedule_ship_date IS NULL)
         UNION ALL
         SELECT   ooh.header_id header_id,
                  ooh.order_number order_number
             FROM oe_order_headers_all ooh
            WHERE 1 = 1
              AND ooh.booked_flag = 'Y'
              AND ooh.flow_status_code = 'BOOKED'
              AND xx_publish_gxs_ghx (ooh.header_id) = 'Y'
              AND EXISTS (SELECT 1
                            FROM oe_order_holds_all oh
                           WHERE oh.header_id = ooh.header_id)
              AND NOT EXISTS (SELECT 1
                                FROM xx_oe_order_publish_stg xps
                               WHERE xps.header_id = ooh.header_id)
         ORDER BY order_number;

      TYPE publish_order_tbl_type IS TABLE OF c_publish_order%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_publish_order_tbl       publish_order_tbl_type;

      TYPE order_publish_stg_tbl_type IS TABLE OF xx_oe_order_publish_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_order_publish_stg_tbl   order_publish_stg_tbl_type;
      x_publish_batch_id        NUMBER;
   BEGIN
      x_publish_order_tbl.DELETE;

      OPEN c_publish_order;

      FETCH c_publish_order
      BULK COLLECT INTO x_publish_order_tbl;

      CLOSE c_publish_order;

      x_order_publish_stg_tbl.DELETE;

      IF x_publish_order_tbl.COUNT > 0
      THEN
         FOR i IN x_publish_order_tbl.FIRST .. x_publish_order_tbl.LAST
         LOOP
            BEGIN
               SELECT xx_oe_order_publish_stg_s1.NEXTVAL
                 INTO x_publish_batch_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_publish_batch_id := NULL;
            END;

            x_order_publish_stg_tbl (i).publish_batch_id := x_publish_batch_id;
            x_order_publish_stg_tbl (i).header_id :=
                                             x_publish_order_tbl (i).header_id;
            x_order_publish_stg_tbl (i).publish_time := SYSDATE;
            x_order_publish_stg_tbl (i).publish_system := 'B2B_SERVER';
            x_order_publish_stg_tbl (i).ack_status := NULL;
            x_order_publish_stg_tbl (i).ack_time := NULL;
            x_order_publish_stg_tbl (i).aia_proc_inst_id := NULL;
            x_order_publish_stg_tbl (i).creation_date := SYSDATE;
            x_order_publish_stg_tbl (i).created_by := fnd_global.user_id;
            x_order_publish_stg_tbl (i).last_update_date := SYSDATE;
            x_order_publish_stg_tbl (i).last_updated_by := fnd_global.user_id;
            x_order_publish_stg_tbl (i).last_update_login :=
                                                            fnd_global.user_id;
         END LOOP;
      END IF;

      IF x_order_publish_stg_tbl.COUNT > 0
      THEN
         FORALL i IN x_order_publish_stg_tbl.FIRST .. x_order_publish_stg_tbl.LAST
            INSERT INTO xx_oe_order_publish_stg
                 VALUES x_order_publish_stg_tbl (i);
         COMMIT;
         fnd_file.put_line (fnd_file.LOG,
                            'Following Orders are selected for publish:'
                           );

         FOR i IN
            x_order_publish_stg_tbl.FIRST .. x_order_publish_stg_tbl.LAST
         LOOP
            fnd_file.put_line (fnd_file.LOG,
                                  'Order Number: '
                               || x_publish_order_tbl (i).order_number
                              );
            xx_raise_publish_event
               (p_publish_batch_id      => x_order_publish_stg_tbl (i).publish_batch_id
               );
         END LOOP;
      ELSE
         fnd_file.put_line (fnd_file.LOG,
                            'No Order is selected for publish.');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Exception occurred while submitting...'
                           );
         fnd_file.put_line (fnd_file.LOG, SQLCODE || '-' || SQLERRM);
   END xx_publish_order_scheduled;
END xx_oe_publish_order_pkg;
/
