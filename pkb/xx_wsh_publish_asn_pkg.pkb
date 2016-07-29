DROP PACKAGE BODY APPS.XX_WSH_PUBLISH_ASN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_WSH_PUBLISH_ASN_PKG" 
IS
/* $Header: xxwshpublishasnpkg.pls 1.2 2012/02/27 08:48:59 bedabrata no ship $ */
-----------------------------------------------------------------------------------
/*
 Created By   : Bedabrata Bhattacharjee
 Creation Date: 27-Feb-2012
 Filename     : XXWSHPUBLISHASNPKG.pkb
 Description  : ASN Publish Public API

 Change History:

 Date        Version#   Name                         Remarks
 ----------- --------   ----                         ------------------------------
 27-Feb-2012   1.0      Bedabrata Bhattacharjee      Initial development.
 30-Aug-2012   1.1      Bedabrata Bhattacharjee      Modified procedure xx_republish_asn
                                                     to include all deliveries.
 27-Jun-2013   1.2      Bedabrata Bhattacharjee      Modification for GHX

*/
-----------------------------------------------------------------------------------
   FUNCTION xx_publish_gxs_ghx (p_delivery_id IN NUMBER)
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Koushik Das
 Creation Date  : 18-MAY-2012
 Filename       :
 Description    : This function returns Y if the delivery customer is interested in
                  EDI 856 transaction.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 18-May-2012   1.0       Koushik Das         Initial development.
 27-Jun-2013   1.1       Bedabrata           Modification for GHX
 */
--------------------------------------------------------------------------------
      CURSOR c_customer (cp_delivery_id NUMBER)
      IS
        SELECT hca.account_number
             , hcas.attribute4 translated_customer_name
          FROM wsh_new_deliveries wnd,
               wsh_locations wl,
               hz_party_sites hps,
               hz_cust_acct_sites_all hcas,
               hz_cust_accounts hca
         WHERE wnd.ultimate_dropoff_location_id = wl.wsh_location_id
           AND wl.location_source_code = 'HZ'
           AND wl.source_location_id = hps.location_id
           AND hps.party_site_id = hcas.party_site_id
           AND hca.cust_account_id = hcas.cust_account_id
           AND hps.status = 'A'
           AND hcas.status = 'A'
           AND hca.status = 'A'
           AND wnd.delivery_id =  cp_delivery_id;

      CURSOR c_lookup (cp_customer_number VARCHAR2)
      IS
         SELECT lookup_code
           FROM oe_lookups
          WHERE lookup_type = 'INTG_856_PARTNERS'
            AND enabled_flag = 'Y'
            AND (   end_date_active IS NULL
                 OR TRUNC (end_date_active) >= TRUNC (SYSDATE)
                )
            AND lookup_code = cp_customer_number;

      x_translated_customer_name   VARCHAR2 (50);
      x_customer_number            VARCHAR2 (30);
      x_gxs_ghx                    VARCHAR2 (1);
   BEGIN
      x_gxs_ghx := 'N';

      FOR customer_rec IN c_customer (p_delivery_id)
      LOOP
         x_translated_customer_name := customer_rec.translated_customer_name;
         x_customer_number := customer_rec.account_number;

         IF x_translated_customer_name IS NOT NULL
         THEN
            -- logic for GXS
            FOR lookup_rec IN c_lookup (x_customer_number)
            LOOP
               x_gxs_ghx := 'Y';
            END LOOP;

            -- end logic for GXS

          -- Logic for GHX
--            IF customer_rec.order_source = 'EDIGHX'
--            THEN
--               x_gxs_ghx := 'Y';
--            END IF;
            BEGIN
            
                SELECT 'Y'
                  INTO x_gxs_ghx
                  FROM oe_order_sources oos, oe_order_headers_all ooh
                 WHERE ooh.order_source_id = oos.order_source_id
                   AND oos.NAME = 'EDIGHX'
                   AND ooh.header_id =
                                     xx_wsh_publish_asn_pkg.xx_source_header_id (p_delivery_id);
            EXCEPTION
             WHEN OTHERS THEN
               NULL;
            END; 
         -- END logic for GHX
         END IF;
      END LOOP;

      RETURN x_gxs_ghx;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_gxs_ghx := 'N';
         RETURN x_gxs_ghx;
   END xx_publish_gxs_ghx;

   PROCEDURE raise_publish_event (p_publish_batch_id IN NUMBER)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
-----------------------------------------------------------------------------------
/* Created By : Bedabrata Bhattacharjee
 Creation Date: 27-Feb-2011
 Filename     : XXWSHPUBLISHASNPKG.pkb
 Description  : Raises custom business event for ASN

 Change History:

 Date        Version#   Name                         Remarks
 ----------- --------   ----                         ------------------------------
 27-Feb-2012   1.0      Bedabrata Bhattacharjee      Initial development.

*/
-----------------------------------------------------------------------------------
      x_event_parameter_list   wf_parameter_list_t;
      x_param                  wf_parameter_t;
      x_event_name             VARCHAR2 (100)
                                        := 'intg.oracle.apps.wsh.asn.publish';
      x_event_key              VARCHAR2 (100);
      x_parameter_index        NUMBER;
      x_event_data             CLOB;
      x_text                   VARCHAR2 (32000);
      x_published_entity       VARCHAR2 (100)      := 'ASN';
   --x_content CLOB; -- debug
   BEGIN
      x_event_key := TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISSSSSSS');
      x_parameter_index := 0;
      x_event_parameter_list := wf_parameter_list_t ();
      x_param := wf_parameter_t (NULL, NULL);
      x_event_parameter_list.EXTEND;
      x_param.setname ('PUBLISH_BATCH_ID');
      x_param.setvalue (p_publish_batch_id);
      x_parameter_index := x_parameter_index + 1;
      x_event_parameter_list (x_parameter_index) := x_param;
      wf_event.RAISE (p_event_name      => x_event_name
                    , p_event_key       => x_event_key
                    , p_parameters      => x_event_parameter_list
                     );
       -- debug
      /* wf_diagnostics.get_bes_debug(x_event_name
             ,x_event_key
             ,x_content);

      INSERT INTO xxtemp_clob
                 (event_name
                 ,event_key
                 ,event_msg)
                 VALUES
                 (x_event_name
                 ,x_event_key
                 ,x_content);        */
           -- Debug
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_text := SQLERRM;
   END raise_publish_event;

--
--
   PROCEDURE populate_publish_tbl (
      p_publish_batch_id   NUMBER
    , p_delivery_id        NUMBER
    , p_publish_time       DATE
    , p_publish_system     VARCHAR2
    , p_ack_status         VARCHAR2
    , p_ack_time           DATE
    , p_aia_proc_inst_id   VARCHAR2
   )
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
-----------------------------------------------------------------------------------
/* Created By : Bedabrata Bhattacharjee
 Creation Date: 27-Feb-2011
 Filename     : XXWSHPUBLISHASNPKG.pkb
 Description  : Inserts/ Updates data to the XX_WSH_ASN_PUBLISH_STG Custom Table

 Change History:

 Date        Version#   Name                         Remarks
 ----------- --------   ----                         ------------------------------
 27-Feb-2012   1.0      Bedabrata Bhattacharjee      Initial development.

*/
-----------------------------------------------------------------------------------
   BEGIN
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
           VALUES (p_publish_batch_id
                 , p_delivery_id
                 , SYSDATE
                 , p_publish_system
                 , p_ack_status
                 , p_ack_time
                 , p_aia_proc_inst_id
                 , SYSDATE
                 , fnd_global.user_id
                 , SYSDATE
                 , fnd_global.user_id
                 , fnd_global.user_id
                  );

      COMMIT;
   END populate_publish_tbl;

--
--
   FUNCTION xx_publish_shipconfirmed (
      p_subscription_guid   IN              RAW
    , p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2
   IS
-----------------------------------------------------------------------------------
/* Created By : Bedabrata Bhattacharjee
 Creation Date: 27-Feb-2012
 Filename     : XXWSHPUBLISHASNPKG.pkb
 Description  : Subscribes to Standard business event
                oracle.apps.wsh.delivery.gen.shipconfirmed to publish ASN

 Change History:

 Date        Version#   Name                         Remarks
 ----------- --------   ----                         ------------------------------
 27-Feb-2012   1.0      Bedabrata Bhattacharjee      Initial development.

*/
-----------------------------------------------------------------------------------
      x_param_list         wf_parameter_list_t;
      x_param_name         VARCHAR2 (250);
      x_param_value        VARCHAR2 (250);
      x_delivery_id        NUMBER;
      x_publish_batch_id   NUMBER;
      x_require_publish    VARCHAR2 (1)        := 'Y';
      x_gxs_ghx            VARCHAR2 (1);
   BEGIN
      x_param_list := p_event.getparameterlist;

      IF x_param_list IS NOT NULL
      THEN
         FOR i IN x_param_list.FIRST .. x_param_list.LAST
         LOOP
            x_param_name := x_param_list (i).getname;
            x_param_value := x_param_list (i).getvalue;

            IF (x_param_name = 'DELIVERY_ID')
            THEN
               x_delivery_id := x_param_value;
            END IF;
         END LOOP;
      END IF;

/*      BEGIN
         SELECT 'Y'
           INTO x_require_publish
           FROM DUAL
          WHERE NOT EXISTS (SELECT 1
                              FROM xx_wsh_asn_publish_stg
                             WHERE delivery_id = x_delivery_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_require_publish := 'N';
      END;
*/
      x_gxs_ghx := xx_publish_gxs_ghx (x_delivery_id);

      IF x_gxs_ghx = 'Y'
      THEN
         IF x_require_publish = 'Y'
         THEN
            BEGIN
               SELECT xx_wsh_asn_publish_batch_id_s1.NEXTVAL
                 INTO x_publish_batch_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_publish_batch_id := NULL;
            END;

            populate_publish_tbl (p_publish_batch_id      => x_publish_batch_id
                                , p_delivery_id           => x_delivery_id
                                , p_publish_time          => SYSDATE
                                , p_publish_system        => 'B2B_SERVER'
                                , p_ack_status            => NULL
                                , p_ack_time              => NULL
                                , p_aia_proc_inst_id      => NULL
                                 );
            -- Call Procedure to raise custom Business Event
            raise_publish_event (p_publish_batch_id => x_publish_batch_id);
         END IF;
      END IF;

      RETURN 'SUCCESS';
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'ERROR';
   END xx_publish_shipconfirmed;

--
--
-----------------------------------------------------------------------------------
/* Created By : Bedabrata Bhattacharjee
 Creation Date: 10-Apr-2012
 Filename     : XXWSHPUBLISHASNPKG.pkb
 Description  : Recovers or Republishes ASN 856 Interface data from control
                staging table.

 Change History:

 Date        Version#   Name                         Remarks
 ----------- --------   ----                         ------------------------------
 10-Apr-2012   1.0      Bedabrata Bhattacharjee      Initial development.
 30-Aug-2012   1.1      Bedabrata Bhattacharjee      Change the cursor query to fetch data from
                                                     base table and also from staging table
                                                     conditionally.

*/
-----------------------------------------------------------------------------------
   PROCEDURE xx_republish_asn (
      p_errbuf          OUT NOCOPY      VARCHAR2
    , p_retcode         OUT NOCOPY      VARCHAR2
    , p_type            IN              VARCHAR2
    , p_delivery_from   IN              NUMBER
    , p_delivery_to     IN              NUMBER
    , p_date_from       IN              DATE
    , p_date_to         IN              DATE
   )
   IS
      CURSOR c_republish_asn (
         cp_type            VARCHAR2
       , cp_delivery_from   VARCHAR2
       , cp_delivery_to     VARCHAR2
       , cp_date_from       DATE
       , cp_date_to         DATE
      )
      IS
         SELECT wnd.delivery_id delivery_id
           FROM wsh_new_deliveries wnd
          WHERE NVL (wnd.shipment_direction, 'O') IN ('O', 'IO')
            AND wnd.status_code = 'CL'                               -- Closed
            AND cp_type = 'Resend'
            AND xx_publish_gxs_ghx (wnd.delivery_id) = 'Y'
            AND wnd.delivery_id >= NVL (cp_delivery_from, wnd.delivery_id)
            AND wnd.delivery_id <= NVL (cp_delivery_to, wnd.delivery_id)
            AND TRUNC (wnd.initial_pickup_date) >=
                           NVL (cp_date_from, TRUNC (wnd.initial_pickup_date))
            AND TRUNC (wnd.initial_pickup_date) <=
                             NVL (cp_date_to, TRUNC (wnd.initial_pickup_date))
         UNION ALL
         SELECT DISTINCT xwaps.delivery_id delivery_id
                    FROM xx_wsh_asn_publish_stg xwaps
                       , wsh_new_deliveries wnd
                   WHERE xwaps.delivery_id = wnd.delivery_id
                     AND NVL (xwaps.ack_status, 'X') <> 'SUCCESS'
                     AND xx_publish_gxs_ghx (wnd.delivery_id) = 'Y'
                     AND wnd.delivery_id >=
                                       NVL (cp_delivery_from, wnd.delivery_id)
                     AND wnd.delivery_id <=
                                         NVL (cp_delivery_to, wnd.delivery_id)
                     AND TRUNC (xwaps.publish_time) >=
                                TRUNC (NVL (cp_date_from, xwaps.publish_time))
                     AND TRUNC (xwaps.publish_time) <=
                                  TRUNC (NVL (cp_date_to, xwaps.publish_time))
                     AND cp_type = 'Recover';

      x_type               VARCHAR2 (80);
      x_delivery_from      wsh_new_deliveries.delivery_id%TYPE;
      x_delivery_to        wsh_new_deliveries.delivery_id%TYPE;
      x_date_from          DATE;
      x_date_to            DATE;
      x_publish_batch_id   NUMBER;
      x_delivery_id        wsh_new_deliveries.delivery_id%TYPE;
   BEGIN
      x_type := p_type;
      x_delivery_from := p_delivery_from;
      x_delivery_to := p_delivery_to;
      x_date_from := fnd_date.canonical_to_date (p_date_from);
      x_date_to := fnd_date.canonical_to_date (p_date_to);
      fnd_file.put_line (fnd_file.LOG, 'Paramteres: ');
      fnd_file.put_line (fnd_file.LOG, 'Delivery From: ' || x_delivery_from);
      fnd_file.put_line (fnd_file.LOG, 'Delivery To: ' || x_delivery_to);
      fnd_file.put_line (fnd_file.LOG, 'Date From: ' || x_date_from);
      fnd_file.put_line (fnd_file.LOG, 'Date To: ' || x_date_to);

      FOR republish_asn_rec IN c_republish_asn (x_type
                                              , x_delivery_from
                                              , x_delivery_to
                                              , x_date_from
                                              , x_date_to
                                               )
      LOOP
         fnd_file.put_line (fnd_file.LOG
                          ,    'Fetching Delivery to Interface. Delivery: '
                            || republish_asn_rec.delivery_id
                           );

         BEGIN
            SELECT xx_wsh_asn_publish_batch_id_s1.NEXTVAL
              INTO x_publish_batch_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_publish_batch_id := NULL;
         END;

         x_delivery_id := republish_asn_rec.delivery_id;

         BEGIN
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
                       , x_delivery_id
                       , SYSDATE
                       , 'B2B_SERVER'
                       , NULL
                       , NULL
                       , NULL
                       , SYSDATE
                       , fnd_global.user_id
                       , SYSDATE
                       , fnd_global.user_id
                       , fnd_global.user_id
                        );

            fnd_file.put_line
                        (fnd_file.LOG
                       , 'Delivery Record Inserted into Publish Staging Table'
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                                (fnd_file.LOG
                               , 'Exception occurred while inserting data...'
                                );
               fnd_file.put_line (fnd_file.LOG, SQLCODE || '-' || SQLERRM);
         END;

         -- Call Procedure to raise custom Business Event
         raise_publish_event (p_publish_batch_id => x_publish_batch_id);
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG
                          , 'Exception occurred while resubmitting...'
                           );
         fnd_file.put_line (fnd_file.LOG, SQLCODE || '-' || SQLERRM);
   END xx_republish_asn;
--
   FUNCTION xx_source_header_id (p_delivery_id IN NUMBER)
      RETURN NUMBER
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Bedabrata
 Creation Date  : 28-JAN-2014
 Filename       :
 Description    : This function returns Order Source header id if source is GHX/GXS 

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 28-JAN-2014   1.0       Bedabrata           Initial development.
 */
--------------------------------------------------------------------------------
      CURSOR c_order (cp_delivery_id NUMBER)
      IS
        SELECT wdd.source_header_id
          FROM wsh_delivery_assignments_v wda
             , wsh_delivery_details wdd
             , oe_order_headers_all ooha
             , oe_order_sources oos
         WHERE wdd.delivery_detail_id = wda.delivery_detail_id
           AND wdd.source_header_id = ooha.header_id
           AND oos.order_source_id = ooha.order_source_id
           AND oos.name =any ('EDIGHX', 'EDIGXS')
           AND wda.delivery_id = cp_delivery_id;

      x_source_header_id                    NUMBER := -99999;
   BEGIN
      FOR order_rec IN c_order (p_delivery_id)
      LOOP
        x_source_header_id := order_rec.source_header_id;
      END LOOP;

      RETURN x_source_header_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_source_header_id := -99999;
         RETURN x_source_header_id;
   END xx_source_header_id;
--
END xx_wsh_publish_asn_pkg; 
/
