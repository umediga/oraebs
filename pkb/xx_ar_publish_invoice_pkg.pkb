DROP PACKAGE BODY APPS.XX_AR_PUBLISH_INVOICE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_PUBLISH_INVOICE_PKG" 
AS
--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain/Payel Banerjee
 Creation Date  : 04-APR-2012
 Filename       : XXARPUBLISHINV.pkb
 Description    : Invoice Publish Public API.

 Change History:

 Date        Version#    Name                                  Remarks
 ----------- --------    ------------------------------     -----------------------------------
 04-APR-2012      1.0    Deepika Jain/Payel Banerjee(IBM)        Initial development.
 10-Oct-2012      2.0    Koushik Das (IBM)                   Changed as per DCR 100912.

 */
--------------------------------------------------------------------------------
   PROCEDURE raise_publish_event (p_publish_batch_id IN NUMBER)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
-------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain/Payel Banerjee
 Creation Date  : 04-APR-2012
 Filename       :
 Description    : This procedure raise the custom business event for Invoice publish

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 04-APR-2012   1.0      Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------
      x_event_parameter_list   wf_parameter_list_t;
      x_param                  wf_parameter_t;
      x_event_name             VARCHAR2 (100)
                                     := 'intg.oracle.apps.ar.invoice.publish';
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
      wf_event.RAISE (p_event_name      => x_event_name
                    , p_event_key       => x_event_key
                    , p_parameters      => x_event_parameter_list
                     );
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END raise_publish_event;

   FUNCTION publish_autoinvoice_run (
      p_subscription_guid   IN              RAW
    , p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain
 Creation Date  : 04-APR-2012
 Filename       :
 Description    : This is a subscription function for
                  oracle.apps.ar.batch.AutoInvoice.run event.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 04-APR-2012   1.0      Deepika Jain        Initial development.

 */
--------------------------------------------------------------------------------
      CURSOR c_invoice_header_info (cp_request_id NUMBER)
      IS
         SELECT customer_trx_id
              , transaction_number
              , document_type                                          --added
           FROM xx_ar_invoice_headers_ws_v
          WHERE request_id = cp_request_id;

      x_request_id         NUMBER;
      x_publish_batch_id   NUMBER;
      x_require_publish    VARCHAR2 (1)    := 'N';
      x_sqlcode            NUMBER;
      x_sqlerrm            VARCHAR2 (2000);
      x_search_result      VARCHAR2 (1);
   BEGIN
      x_request_id := p_event.getvalueforparameter ('REQUEST_ID');

      FOR invoice_header_info_rec IN c_invoice_header_info (x_request_id)
      LOOP
         x_search_result :=
            require_publish_check (invoice_header_info_rec.customer_trx_id
                                 , invoice_header_info_rec.document_type
                                  );

         IF x_search_result = 'Y'
         THEN
            BEGIN
               SELECT 'Y'
                 INTO x_require_publish
                 FROM DUAL
                WHERE NOT EXISTS (
                         SELECT 1
                           FROM xx_ar_invoice_publish_stg
                          WHERE customer_trx_id =
                                       invoice_header_info_rec.customer_trx_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  x_require_publish := 'N';
            END;

            IF x_require_publish = 'Y'
            THEN
               BEGIN
                  SELECT xx_ar_invoice_publish_stg_s1.NEXTVAL
                    INTO x_publish_batch_id
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_publish_batch_id := NULL;
               END;

               BEGIN
                  INSERT INTO xx_ar_invoice_publish_stg
                              (publish_batch_id
                             , customer_trx_id
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
                             , invoice_header_info_rec.customer_trx_id
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
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               raise_publish_event (p_publish_batch_id => x_publish_batch_id);
            END IF;
         END IF;
      END LOOP;

      RETURN 'SUCCESS';
   EXCEPTION
      WHEN OTHERS
      THEN
         x_sqlcode := SQLCODE;
         x_sqlerrm := SUBSTR (SQLERRM, 1, 2000);
         RETURN 'ERROR';
   END publish_autoinvoice_run;

   FUNCTION publish_invoice_complete (
      p_subscription_guid   IN              RAW
    , p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
/*
Created By     : Deepika Jain
Creation Date  : 04-APR-2012
Filename       :
Description    : This is a subscription function for
                 oracle.apps.ar.transaction.Invoice.complete event.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
04-APR-2012   1.0      Deepika Jain        Initial development.

*/
--------------------------------------------------------------------------------
      CURSOR c_invoice_header_info (cp_customer_trx_id NUMBER)
      IS
         SELECT customer_trx_id
              , transaction_number
           FROM xx_ar_invoice_headers_ws_v
          WHERE customer_trx_id = cp_customer_trx_id;

      x_customer_trx_id    NUMBER;
      x_publish_batch_id   NUMBER;
      x_require_publish    VARCHAR2 (1)    := 'N';
      x_sqlcode            NUMBER;
      x_sqlerrm            VARCHAR2 (2000);
      x_tran_type          VARCHAR2 (10)   := 'INV';
      x_search_result      VARCHAR2 (1);
   BEGIN
      x_customer_trx_id := p_event.getvalueforparameter ('CUSTOMER_TRX_ID');
      x_search_result :=
                       require_publish_check (x_customer_trx_id, x_tran_type);

      IF x_search_result = 'Y'
      THEN
         FOR invoice_header_info_rec IN
            c_invoice_header_info (x_customer_trx_id)
         LOOP
            BEGIN
               SELECT 'Y'
                 INTO x_require_publish
                 FROM DUAL
                WHERE NOT EXISTS (
                         SELECT 1
                           FROM xx_ar_invoice_publish_stg
                          WHERE customer_trx_id =
                                       invoice_header_info_rec.customer_trx_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  x_require_publish := 'N';
            END;

            IF x_require_publish = 'Y'
            THEN
               BEGIN
                  SELECT xx_ar_invoice_publish_stg_s1.NEXTVAL
                    INTO x_publish_batch_id
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_publish_batch_id := NULL;
               END;

               BEGIN
                  INSERT INTO xx_ar_invoice_publish_stg
                              (publish_batch_id
                             , customer_trx_id
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
                             , invoice_header_info_rec.customer_trx_id
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
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               raise_publish_event (p_publish_batch_id => x_publish_batch_id);
            END IF;
         END LOOP;

         RETURN 'SUCCESS';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_sqlcode := SQLCODE;
         x_sqlerrm := SUBSTR (SQLERRM, 1, 2000);
         RETURN 'ERROR';
   END publish_invoice_complete;

   FUNCTION publish_creditmemo_complete (
      p_subscription_guid   IN              RAW
    , p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
/*
Created By     : Deepika Jain
Creation Date  : 25-APR-2012
Filename       :
Description    : This is a subscription function for
                 oracle.apps.ar.transaction.DebitMemo.complete event.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
25-APR-2012   1.0      Deepika Jain        Initial development.

*/
--------------------------------------------------------------------------------
      CURSOR c_invoice_header_info (cp_customer_trx_id NUMBER)
      IS
         SELECT customer_trx_id
              , transaction_number
           FROM xx_ar_invoice_headers_ws_v
          WHERE customer_trx_id = cp_customer_trx_id;

      x_customer_trx_id    NUMBER;
      x_publish_batch_id   NUMBER;
      x_require_publish    VARCHAR2 (1)    := 'N';
      x_sqlcode            NUMBER;
      x_sqlerrm            VARCHAR2 (2000);
      x_tran_type          VARCHAR2 (10)   := 'CM';
      x_search_result      VARCHAR2 (1);
   BEGIN
      x_customer_trx_id := p_event.getvalueforparameter ('CUSTOMER_TRX_ID');
      x_search_result :=
                       require_publish_check (x_customer_trx_id, x_tran_type);

      IF x_search_result = 'Y'
      THEN
         FOR invoice_header_info_rec IN
            c_invoice_header_info (x_customer_trx_id)
         LOOP
            BEGIN
               SELECT 'Y'
                 INTO x_require_publish
                 FROM DUAL
                WHERE NOT EXISTS (
                         SELECT 1
                           FROM xx_ar_invoice_publish_stg
                          WHERE customer_trx_id =
                                       invoice_header_info_rec.customer_trx_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  x_require_publish := 'N';
            END;

            IF x_require_publish = 'Y'
            THEN
               BEGIN
                  SELECT xx_ar_invoice_publish_stg_s1.NEXTVAL
                    INTO x_publish_batch_id
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_publish_batch_id := NULL;
               END;

               BEGIN
                  INSERT INTO xx_ar_invoice_publish_stg
                              (publish_batch_id
                             , customer_trx_id
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
                             , invoice_header_info_rec.customer_trx_id
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
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               raise_publish_event (p_publish_batch_id => x_publish_batch_id);
            END IF;
         END LOOP;

         RETURN 'SUCCESS';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_sqlcode := SQLCODE;
         x_sqlerrm := SUBSTR (SQLERRM, 1, 2000);
         RETURN 'ERROR';
   END publish_creditmemo_complete;

   FUNCTION publish_debitmemo_complete (
      p_subscription_guid   IN              RAW
    , p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
/*
Created By     : Deepika Jain
Creation Date  : 25-APR-2012
Filename       :
Description    : This is a subscription function for
                 oracle.apps.ar.transaction.DebitMemo.complete event.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
25-APR-2012   1.0      Deepika Jain        Initial development.

*/
--------------------------------------------------------------------------------
      CURSOR c_invoice_header_info (cp_customer_trx_id NUMBER)
      IS
         SELECT customer_trx_id
              , transaction_number
           FROM xx_ar_invoice_headers_ws_v
          WHERE customer_trx_id = cp_customer_trx_id;

      x_customer_trx_id    NUMBER;
      x_publish_batch_id   NUMBER;
      x_require_publish    VARCHAR2 (1)    := 'N';
      x_sqlcode            NUMBER;
      x_sqlerrm            VARCHAR2 (2000);
      x_tran_type          VARCHAR2 (10)   := 'DM';
      x_search_result      VARCHAR2 (1);
   BEGIN
      x_customer_trx_id := p_event.getvalueforparameter ('CUSTOMER_TRX_ID');
      x_search_result :=
                       require_publish_check (x_customer_trx_id, x_tran_type);

      IF x_search_result = 'Y'
      THEN
         FOR invoice_header_info_rec IN
            c_invoice_header_info (x_customer_trx_id)
         LOOP
            BEGIN
               SELECT 'Y'
                 INTO x_require_publish
                 FROM DUAL
                WHERE NOT EXISTS (
                         SELECT 1
                           FROM xx_ar_invoice_publish_stg
                          WHERE customer_trx_id =
                                       invoice_header_info_rec.customer_trx_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  x_require_publish := 'N';
            END;

            IF x_require_publish = 'Y'
            THEN
               BEGIN
                  SELECT xx_ar_invoice_publish_stg_s1.NEXTVAL
                    INTO x_publish_batch_id
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_publish_batch_id := NULL;
               END;

               BEGIN
                  INSERT INTO xx_ar_invoice_publish_stg
                              (publish_batch_id
                             , customer_trx_id
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
                             , invoice_header_info_rec.customer_trx_id
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
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               raise_publish_event (p_publish_batch_id => x_publish_batch_id);
            END IF;
         END LOOP;

         RETURN 'SUCCESS';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_sqlcode := SQLCODE;
         x_sqlerrm := SUBSTR (SQLERRM, 1, 2000);
         RETURN 'ERROR';
   END publish_debitmemo_complete;

   --- Procedure to republish invoice
   ---
   PROCEDURE republish_invoice (
      p_errbuf         OUT NOCOPY      VARCHAR2
    , p_retcode        OUT NOCOPY      VARCHAR2
    , p_type           IN              VARCHAR2
    , p_invoice_from   IN              VARCHAR2
    , p_invoice_to     IN              VARCHAR2
    , p_date_from      IN              VARCHAR2
    , p_date_to        IN              VARCHAR2
   )
   IS
--------------------------------------------------------------------------------
/*
Created By     : Payel Banerjee
Creation Date  : 30-MAY-2012
Filename       :
Description    : This procedure will resubmit invoices for 810
Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
30-MAY-2012   1.0      Payel Banerjee        Initial development.
24-OCT-2012   1.1      Bedabrata             Modified the cursor Query to enable
                                             resend of all eligible Invoices

*/
--------------------------------------------------------------------------------
   -- Cursor Modified to enable sending of all eligible invoices
      CURSOR c_republish_invoice (
         cp_type           VARCHAR2
       , cp_invoice_from   VARCHAR2
       , cp_invoice_to     VARCHAR2
       , cp_date_from      DATE
       , cp_date_to        DATE
      )
      IS
         SELECT rct.customer_trx_id customer_trx_id
              , rct.trx_number invoice_number
           FROM ra_customer_trx_all rct
              , ra_cust_trx_types_all rctt
          WHERE rct.trx_number >= NVL (cp_invoice_from, rct.trx_number)
            AND rct.trx_number <= NVL (cp_invoice_to, rct.trx_number)
            AND TRUNC (rct.trx_date) >=
                                      NVL (cp_date_from, TRUNC (rct.trx_date))
            AND TRUNC (rct.trx_date) <= NVL (cp_date_to, TRUNC (rct.trx_date))
            AND cp_type = 'Resend'
            AND rct.cust_trx_type_id = rctt.cust_trx_type_id
            AND rctt.org_id = rct.org_id
            AND xx_ar_publish_invoice_pkg.require_publish_check
                                                         (rct.customer_trx_id
                                                        , rctt.TYPE
                                                         ) = 'Y'
         UNION ALL
         SELECT DISTINCT xaips.customer_trx_id customer_trx_id
                       , rct.trx_number invoice_number
                    FROM xx_ar_invoice_publish_stg xaips
                       , ra_customer_trx_all rct
                       , ra_cust_trx_types_all rctt
                   WHERE xaips.customer_trx_id = rct.customer_trx_id
                     AND rct.trx_number >=
                                         NVL (cp_invoice_from, rct.trx_number)
                     AND rct.trx_number <= NVL (cp_invoice_to, rct.trx_number)
                     AND TRUNC (xaips.publish_time) >=
                                NVL (cp_date_from, TRUNC (xaips.publish_time))
                     AND TRUNC (xaips.publish_time) <=
                                  NVL (cp_date_to, TRUNC (xaips.publish_time))
                     AND cp_type = 'Recover'
                     AND rct.cust_trx_type_id = rctt.cust_trx_type_id
                     AND rctt.org_id = rct.org_id
                     AND xx_ar_publish_invoice_pkg.require_publish_check
                                                         (rct.customer_trx_id
                                                        , rctt.TYPE
                                                         ) = 'Y';

      x_type               VARCHAR2 (80);
      x_invoice_from       ra_customer_trx_all.trx_number%TYPE;
      x_invoice_to         ra_customer_trx_all.trx_number%TYPE;
      x_date_from          DATE;
      x_date_to            DATE;
      x_publish_batch_id   NUMBER;
      x_invoice_number     ra_customer_trx_all.trx_number%TYPE;
      x_customer_trx_id    ra_customer_trx_all.customer_trx_id%TYPE;
   BEGIN
      x_type := p_type;
      x_invoice_from := p_invoice_from;
      x_invoice_to := p_invoice_to;
      x_date_from := fnd_date.canonical_to_date (p_date_from);
      x_date_to := fnd_date.canonical_to_date (p_date_to);
      fnd_file.put_line (fnd_file.LOG, 'Paramteres: ');
      fnd_file.put_line (fnd_file.LOG, 'Invoice From: ' || x_invoice_from);
      fnd_file.put_line (fnd_file.LOG, 'Invoice To: ' || x_invoice_to);
      fnd_file.put_line (fnd_file.LOG, 'Date From: ' || x_date_from);
      fnd_file.put_line (fnd_file.LOG, 'Date To: ' || x_date_to);
      fnd_file.put_line (fnd_file.LOG, 'Published Invoices: ');

      FOR republish_invoice_rec IN c_republish_invoice (x_type
                                                      , x_invoice_from
                                                      , x_invoice_to
                                                      , x_date_from
                                                      , x_date_to
                                                       )
      LOOP
         BEGIN
            SELECT xx_ar_invoice_publish_stg_s1.NEXTVAL
              INTO x_publish_batch_id
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_publish_batch_id := NULL;
         END;

         x_customer_trx_id := republish_invoice_rec.customer_trx_id;
         x_invoice_number := republish_invoice_rec.invoice_number;

         BEGIN
            INSERT INTO xx_ar_invoice_publish_stg
                        (publish_batch_id
                       , customer_trx_id
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
                       , x_customer_trx_id
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
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                                (fnd_file.LOG
                               , 'Exception occurred while inserting data...'
                                );
               fnd_file.put_line (fnd_file.LOG, SQLCODE || '-' || SQLERRM);
         END;

         fnd_file.put_line (fnd_file.LOG
                          , 'Invoice Number: ' || x_invoice_number
                           );
         raise_publish_event (p_publish_batch_id => x_publish_batch_id);
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG
                          , 'Exception occurred while resubmitting...'
                           );
         fnd_file.put_line (fnd_file.LOG, SQLCODE || '-' || SQLERRM);
   END republish_invoice;

   FUNCTION require_publish_check (
      p_cust_trx_id   IN   ra_customer_trx_all.customer_trx_id%TYPE
    , p_tran_type     IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
/*
Created By     : Payel Banerjee
Creation Date  : 30-MAY-2012
Filename       :
Description    : This function will check if the invoice requires publishing.

Change History:

Date        Version#    Name                Remarks
----------- --------    ---------------     -----------------------------------
30-MAY-2012   1.0      Payel Banerjee        Initial development.
12-Nov-2013   1.1      Bedabrata             Modification for GHX

*/
--------------------------------------------------------------------------------

      --Change begin
      CURSOR c_translated_customer_name (cp_customer_trx_id NUMBER)
      IS
         SELECT DISTINCT ra1.attribute4 translated_customer_name
             ,  ra1.attribute7 ghx_edi_enabled -- added for GHX
                    -- SELECT DISTINCT ra1.translated_customer_name
         FROM            hz_cust_acct_sites_all ra1
                       , hz_cust_site_uses_all rsu1
                       , ra_customer_trx_all rct1
                       , hz_cust_accounts rc1
                   WHERE 1=1
                 --   rct1.sold_to_customer_id = rc1.cust_account_id -- Commented by Jagdish , Beda since for converted invoices SOLD_TO_CUST_ID is null 02/03/2013
                     AND rsu1.cust_acct_site_id = ra1.cust_acct_site_id
                     AND rc1.cust_account_id = ra1.cust_account_id
                     AND rct1.ship_to_site_use_id = rsu1.site_use_id
                     -- Added by Bedabrata on 2012-09-17 to fetch ISA# for ship to site only.
                     AND ra1.attribute4 IS NOT NULL
                     --    and ra1.translated_customer_name is not NULL
                     AND rct1.customer_trx_id = cp_customer_trx_id;

--Change end
      CURSOR c_lookup (cp_translated_customer_name VARCHAR2)
      IS
         SELECT lookup_code
           FROM ar_lookups
          WHERE lookup_type = 'INTG_810_PARTNERS'
            AND enabled_flag = 'Y'
            AND (   end_date_active IS NULL
                 OR TRUNC (end_date_active) >= TRUNC (SYSDATE)
                )
            AND lookup_code = cp_translated_customer_name;

       -- Cursor For Order Source for GHX
      CURSOR c_order_source (cp_customer_trx_id NUMBER)
      IS
      SELECT oos.name order_source
      FROM oe_order_headers_all ooh
		 , oe_order_lines_all ool
		 , ra_customer_trx_lines_all rctl
         , oe_order_sources oos
      WHERE ooh.header_id = ool.header_id
      AND ool.line_id = rctl.interface_line_attribute6
      AND rctl.customer_trx_id = cp_customer_trx_id
      AND ooh.order_source_id = oos.order_source_id -- Added for GHX
	  AND oos.enabled_flag = 'Y' -- Added for GHX
      AND rownum = 1;

      -- Cursor to find enabled for transaction type from lookup values
      CURSOR c_trx_type_found (cp_flex_value VARCHAR2, cp_tran_type VARCHAR2)
      IS
        SELECT ffv.flex_value
          FROM fnd_flex_values_vl ffv
             , fnd_flex_value_sets ffvs
         WHERE ffvs.flex_value_set_name = 'GHX_EDI_810_ENABLED_VALUES'
           AND ffvs.flex_value_set_id = ffv.flex_value_set_id
           AND ffv.enabled_flag = 'Y'
           AND ffv.flex_value = cp_flex_value
           AND INSTR(UPPER(ffv.flex_value), UPPER(cp_tran_type)) > 0;

      x_code_exists                VARCHAR2 (1)  := 'N';
      x_translated_customer_name   VARCHAR2 (50);
      x_order_source               VARCHAR2 (50) := NULL;
   BEGIN
      FOR translated_customer_name_rec IN
         c_translated_customer_name (p_cust_trx_id)
      LOOP
         x_translated_customer_name :=
                        translated_customer_name_rec.translated_customer_name;

         IF x_translated_customer_name IS NOT NULL -- ISA# exists
         THEN
            x_translated_customer_name :=
                  translated_customer_name_rec.translated_customer_name
               || '-'
               || p_tran_type;


            FOR rec_order_source IN c_order_source(p_cust_trx_id)
            LOOP
              x_order_source := rec_order_source.order_source;
            END LOOP;

            FOR lookup_rec IN c_lookup (x_translated_customer_name)
            LOOP
               x_code_exists := 'Y';
            END LOOP;

            -- logic for GHX
          IF ((translated_customer_name_rec.ghx_edi_enabled IS NOT NULL) AND (x_order_source = 'EDIGHX') )
          THEN

            FOR rec_trx_type_found IN c_trx_type_found (translated_customer_name_rec.ghx_edi_enabled, p_tran_type)
            LOOP
             x_code_exists := 'Y';

            END LOOP;
          END IF;

         END IF;
      END LOOP;

      RETURN x_code_exists;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_code_exists := 'N';
         RETURN x_code_exists;
   END require_publish_check;
END xx_ar_publish_invoice_pkg;
/
