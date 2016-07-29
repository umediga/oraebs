DROP PACKAGE BODY APPS.XX_SDC_AR_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_AR_OUTBOUND_WS_PKG" 
AS
/* $Header: XXSDCARRCPTOUTWS.pks 1.0.0 2014/02/12 00:00:00  noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Yogesh
 Creation Date  : 26-FEB-2014
 Filename       : XXSDCARRCPTOUTWS.pks
 Description    : Customer Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 12-Feb-2014   1.0       Yogesh              Initial development.

 */
--------------------------------------------------------------------------------
   PROCEDURE xx_get_balance (
         p_mode                 IN              VARCHAR2,
         p_publish_batch_id     IN              NUMBER,
         p_cust_accont_id_ls    IN              xx_sdc_in_ar_rcpt_ws_ot_tabtyp,
         x_output_ar_bal        OUT NOCOPY      xx_sdc_ar_rcpt_ws_ot_tabtyp,
         x_return_status        OUT NOCOPY      VARCHAR2,
         x_return_message       OUT NOCOPY      VARCHAR2
   )
   IS
     CURSOR c_ar_bal_batch_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xsarps.record_id,xsarps.publish_batch_id,xsar.*,xsarps.target_system
           FROM xx_sdc_ar_rcpt_ws_v xsar,
                (SELECT DISTINCT cust_account_id,customer_site_id,publish_batch_id,record_id,target_system
                            FROM xx_sdc_ar_reciepts_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id
                             AND NVL(status, 'NEW') <> 'SUCCESS' ) xsarps
          WHERE xsar.cust_account_id = xsarps.cust_account_id
            AND xsar.customer_site_id = xsarps.customer_site_id;


     CURSOR c_cust_account_list_info (cp_cust_account_id NUMBER,
                                      cp_customer_site_id NUMBER,
                                      cp_record_id       NUMBER)
      IS
         SELECT xsarps.record_id,xsarps.publish_batch_id,xsar.*,xsarps.target_system
           FROM XX_SDC_AR_RCPT_WS_V xsar,
                (SELECT DISTINCT cust_account_id,customer_site_id,publish_batch_id,record_id,target_system
                            FROM xx_sdc_ar_reciepts_publish_stg
                           WHERE record_id = cp_record_id
                             AND cust_account_id=cp_cust_account_id
                             AND customer_site_id = cp_customer_site_id
                             AND NVL(status, 'NEW') <> 'SUCCESS' ) xsarps
          WHERE xsar.cust_account_id = xsarps.cust_account_id
            AND xsar.customer_site_id = xsarps.customer_site_id;


      x_publish_batch_id       NUMBER               := NULL;
      e_incorrect_mode         EXCEPTION;

      TYPE sdc_ar_bal_tbl IS TABLE OF xx_sdc_ar_receipt_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_sdc_ar_bal_tbl             sdc_ar_bal_tbl;


   BEGIN
         mo_global.set_policy_context('S',82);
         x_publish_batch_id := p_publish_batch_id;

        IF p_mode IS NULL OR p_mode NOT IN ('BATCH', 'LIST')
         THEN
            RAISE e_incorrect_mode;
         END IF;

         IF p_mode = 'BATCH'
         THEN
            OPEN c_ar_bal_batch_info (x_publish_batch_id);
            FETCH c_ar_bal_batch_info
            BULK COLLECT INTO x_sdc_ar_bal_tbl;

            CLOSE c_ar_bal_batch_info;

            IF x_sdc_ar_bal_tbl.COUNT > 0
            THEN
               FORALL i_rec IN 1 .. x_sdc_ar_bal_tbl.COUNT
                  INSERT INTO xx_sdc_ar_receipt_stg
                       VALUES x_sdc_ar_bal_tbl (i_rec);
            END IF;

                 SELECT  CAST
                             (MULTISET(SELECT xsarps.record_id
                                             ,xsarps.publish_batch_id
                                             ,xsar.customer_name
                                             ,xsar.account_number
                                             ,xsar.collections_status
                                             ,xsar.cust_account_id
                                             ,xsar.customer_site_id
                                             ,NVL(xsar.net_balance,0)
                                             ,xsar.net_bal_currency
                                             ,NVL(xsar.Daily_sales_Outstanding,0)
                                             ,NVL(xsar.amount_overdue,0)
                                             ,xsarps.target_system
                                             ,xsar.site_number
                                         FROM XX_SDC_AR_RCPT_WS_V xsar,
                                             (SELECT DISTINCT cust_account_id,customer_site_id,publish_batch_id,record_id,target_system
                                                FROM xx_sdc_ar_reciepts_publish_stg
                                               WHERE publish_batch_id = x_publish_batch_id) xsarps
                                        WHERE xsar.cust_account_id = xsarps.cust_account_id
                                          AND xsar.customer_site_id = xsarps.customer_site_id ) AS xx_sdc_ar_rcpt_ws_ot_tabtyp
                              )
                    INTO x_output_ar_bal
                    from dual;

            x_return_status := 'S';
            x_return_message := NULL;
         END IF;

         /*IF p_mode = 'LIST'
         THEN
            FOR i IN 1 .. p_cust_accont_id_ls.COUNT
            LOOP
                OPEN c_cust_account_list_info (p_cust_accont_id_ls(i).record_id,p_cust_accont_id_ls(i).cust_account_id,p_cust_accont_id_ls(i).customer_site_id );
                FETCH c_cust_account_list_info
                BULK COLLECT INTO x_sdc_cust_account_tbl;

                CLOSE c_cust_account_list_info;

                IF x_sdc_cust_account_tbl.COUNT > 0
                THEN
                   FORALL i_rec IN 1 .. x_sdc_cust_account_tbl.COUNT
                      INSERT INTO xx_sdc_cust_account_stg
                           VALUES x_sdc_cust_account_tbl (i_rec);
                END IF;

                OPEN c_cust_sites_list_info (p_cust_accont_id_ls(i).record_id,p_cust_accont_id_ls(i).cust_account_id );
                FETCH c_cust_sites_list_info
                BULK COLLECT INTO x_sdc_cust_acc_sites_stg_tbl;

                CLOSE c_cust_sites_list_info;

                IF x_sdc_cust_acc_sites_stg_tbl.COUNT > 0
                THEN
                   FORALL i_rec IN 1 .. x_sdc_cust_acc_sites_stg_tbl.COUNT
                      INSERT INTO xx_sdc_cust_acc_sites_stg
                           VALUES x_sdc_cust_acc_sites_stg_tbl (i_rec);
                END IF;

                SELECT DISTINCT PUBLISH_BATCH_ID
		  INTO x_publish_batch_id
		  FROM xx_sdc_customer_publish_stg
                 WHERE record_id = p_cust_accont_id_ls(i).record_id;
            END LOOP;

            SELECT CAST
                      (MULTISET (SELECT *
                                   FROM xx_sdc_customer_ws_v
                                  WHERE publish_batch_id = x_publish_batch_id) AS xx_sdc_cust_otbound_ws_tabtyp
                      )
              INTO x_output_Customer
              FROM DUAL;

            x_return_status := 'S';
            x_return_message := NULL;

         END IF;*/
      EXCEPTION
         WHEN e_incorrect_mode
         THEN
            x_return_status := 'E';
            x_return_message := 'Mode is mandatory and can be BATCH or LIST';
         WHEN OTHERS
         THEN
            x_return_status := 'E';
            x_return_message := SQLERRM;


      END xx_get_balance;
--------------------------------------------------------------------------------

    FUNCTION sdc_publish_ar_balance ( p_subscription_guid   IN              RAW,
                                      p_event               IN OUT NOCOPY   wf_event_t
                                    )
    RETURN VARCHAR2
    IS
       x_xml_event_data            XMLTYPE;
       x_key                       varchar2(20);
       x_record_id                 NUMBER;

           PRAGMA                      AUTONOMOUS_TRANSACTION;
    BEGIN
    x_xml_event_data:=SYS.XMLTYPE.createxml(p_event.geteventdata());
     x_key:=p_event.getvalueforparameter ('event_key');

               SELECT EXTRACTVALUE (x_xml_event_data,'/default/event_key')
                 INTO x_key
            FROM dual;

             /*SELECT xxintg.xx_sdc_customer_publish_stg_s1.NEXTVAL
               INTO x_record_id
               FROM DUAL;

             INSERT INTO xx_sdc_customer_publish_stg ( publish_batch_id,
             					       record_id,
             					       cust_account_id,
             					       publish_time,
                 				       publish_system,
             					       status,
             					       ack_time,
             					       aia_proc_inst_id,
             					       creation_date,
             					       created_by,
             					       last_update_date,
             					       last_updated_by,
             					       last_update_login)
             values( NULL,
                     x_record_id,
                     nvl(to_number(x_key),1),
                     SYSDATE,
                     'EBS',
                     'NEW',
                     NULL,
                     NULL,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.user_id);
                     Commit;

    Insert into temp2 values (substr(x_xml_event_data,1,3999));
    commit;  */
    RETURN 'SUCCESS';
    END sdc_publish_ar_balance;
END xx_sdc_ar_outbound_ws_pkg;
/
