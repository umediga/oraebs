DROP PACKAGE BODY APPS.XX_SDC_AR_RCPT_INTF_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_AR_RCPT_INTF_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 03-MAR-2014
 File Name     : XXSDCARRCPTINTF.pkb
 Description   : This script creates the package body of
                 xx_sdc_ar_rcpt_intf_pkg, which will send notifications
                 for equity Admins.
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 03-Mar-2014 Yogesh                Initial Version
 19-Sep-2014 Bedabrata             Change for Wave2. Commented out US specific
                                   Customer logic.
*/
----------------------------------------------------------------------
   x_user_id          NUMBER       := FND_GLOBAL.USER_ID;
   x_resp_id          NUMBER       := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER       := FND_GLOBAL.RESP_APPL_ID;
   x_login_id         NUMBER       := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER       := FND_GLOBAL.CONC_REQUEST_ID;

   x_publish_system   VARCHAR2(80) := 'EBS';
   x_target_system    VARCHAR2(280):= 'SFDC';
   x_status_flag      VARCHAR(10)  := 'NEW';

    PROCEDURE main_prc( p_errbuf           OUT   VARCHAR2
                       ,p_retcode          OUT   NUMBER
                       ,p_type             IN    VARCHAR2
                       ,p_hidden1          IN    VARCHAR2
                       ,p_hidden2          IN    VARCHAR2
                       ,p_cust_site_from   IN    HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
                       ,p_cust_site_to     IN    HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
                       ,p_date_from        IN    VARCHAR2 DEFAULT NULL
                       ,p_date_to          IN    VARCHAR2 DEFAULT NULL
                       )
    IS

       CURSOR c_elig_cust(   cp_type             VARCHAR2
                            ,cp_date_from        DATE
                            ,cp_date_to          DATE
                            ,cp_cust_site_from   HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE
                            ,cp_cust_site_to     HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE
                            )
       IS
       /*SELECT distinct customer_id, hcas.cust_acct_site_id
         FROM ar_payment_schedules_all aps,
              hz_cust_accounts_all hca,
              hz_cust_acct_sites_all hcas,
              hz_cust_site_uses_all   hcsu,
              (SELECT ORGANIZATION_ID
                 FROM HR_ALL_ORGANIZATION_UNITS HAOU,
                      (SELECT parameter_value
                         FROM xx_emf_process_parameters xpp, xx_emf_process_setup xps
                        WHERE 1 = 1
                          AND xps.process_id = xpp.process_id
                          AND xps.process_name = 'XX_SDC_AR_RCPT_INTF'
                          AND UPPER (parameter_name) like 'OPERATING_UNIT_%'
                          AND NVL (xpp.enabled_flag, 'Y') = 'Y'
                          AND NVL (xps.enabled_flag, 'Y') = 'Y') emfp
                WHERE haou.name = emfp.parameter_value) ouid
        WHERE hca.status='A'
          AND CUSTOMER_TYPE = 'R'
         AND NOT EXISTS (SELECT 1
                            FROM xx_sdc_ar_reciepts_publish_stg xsap
                           WHERE XSAP.STATUS = 'NEW'
                             AND XSAP.CUST_ACCOUNT_ID = HCA.CUST_ACCOUNT_ID
                             AND XSAP.CUST_ACCOUNT_ID = APS.CUSTOMER_ID
                             AND XSAP.CUST_ACCOUNT_ID = HCAS.CUST_ACCOUNT_ID)
          AND EXISTS (SELECT 1
                            FROM XX_SDC_AR_RECIEPTS_PUBLISH_STG XSAP
                           WHERE XSAP.STATUS != 'NEW'
                             AND xsap.creation_date < aps.last_update_date
                             AND XSAP.CUST_ACCOUNT_ID = HCA.CUST_ACCOUNT_ID
                             AND XSAP.CUST_ACCOUNT_ID = APS.CUSTOMER_ID
                             AND XSAP.CUST_ACCOUNT_ID = HCAS.CUST_ACCOUNT_ID
                             AND xsap.record_id in (select max(a.record_id)from XX_SDC_AR_RECIEPTS_PUBLISH_STG a where a.CUST_ACCOUNT_ID=XSAP.CUST_ACCOUNT_ID ))
          AND aps.status = 'OP'
          AND ouid.organization_id = hcas.org_id
          AND aps.customer_id = hca.cust_account_id
          AND aps.customer_site_use_id= hcsu.site_use_id
          AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
          AND hcas.cust_account_id = hca.cust_account_id;*/
       SELECT DISTINCT customer_id, cust_acct_site_id, site_number
         FROM (
       SELECT  aps.customer_id
              ,hcas.cust_acct_site_id
              ,hps.party_site_number site_number
              ,aps.last_update_date last_update_date
         FROM ar_payment_schedules_all aps,
              hz_cust_accounts_all hca,
              hz_cust_acct_sites_all hcas,
              hz_cust_site_uses_all  hcsu,
              hz_party_sites hps,
              hz_locations hl
        WHERE EXISTS ( SELECT lookup_code
                        FROM fnd_lookup_values_vl
                       WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                         AND lookup_code = hcas.org_id
                         AND NVL(enabled_flag,'X')='Y'
                         AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
          --AND hl.country = 'US'
--          AND hl.country = DECODE(hcsu.site_use_code,'BILL_TO','US',hl.country) -- Commented out for wave2
          AND hl.location_id = hps.location_id
          AND hcsu.status = 'A'
          AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
          AND hps.status = 'A'
          --AND hps.party_id = hca.party_id
          AND hps.party_site_id = hcas.party_site_id
          AND hcas.status = 'A'
          AND hcas.cust_account_id = hca.cust_account_id
          AND hca.customer_type = 'R'
          AND hca.status='A'
          AND hcsu.site_use_code = 'BILL_TO'
          AND aps.customer_site_use_id= hcsu.site_use_id
          AND aps.customer_id = hca.cust_account_id
          AND aps.status = 'OP'
          )
        --WHERE last_update_date > TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','AR_RECPT_LAST_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS');
         WHERE (last_update_date BETWEEN cp_date_from AND cp_date_to
                AND cp_type IN ('NEW'))
           OR (site_number BETWEEN cp_cust_site_from AND cp_cust_site_to
               AND cp_type IN ('RESEND')) ;

        CURSOR c_republish_rec( cp_type VARCHAR2, cp_date_from DATE, cp_date_to DATE )
        IS
          SELECT DISTINCT publish_batch_id
            FROM xx_sdc_ar_reciepts_publish_stg
           WHERE TRUNC(creation_date) BETWEEN TRUNC(cp_date_from) AND TRUNC(cp_date_to)
             AND cp_type IN ('Reprocess')
             AND nvl(status, 'NEW')   <> 'SUCCESS';

       /*CURSOR c_cust_ar_info(p_cust_acc_id NUMBER, p_cust_site_id NUMBER)
       IS
       SELECT *
         FROM XX_SDC_AR_RCPT_WS_V xsav
        WHERE xsav.cust_account_id=p_cust_acc_id
          AND xsav.customer_site_id = p_cust_site_id;

       CURSOR c_stg_tbl_rec(p_cust_acc_id NUMBER, p_cust_site_id NUMBER)
       IS
       SELECT *
         FROM xx_sdc_ar_receipt_stg
        WHERE record_id in( SELECT MAX(record_id)
                              FROM xx_sdc_ar_receipt_stg a
                             WHERE a.cust_account_id = p_cust_acc_id
                               AND a.customer_site_id = p_cust_site_id);*/

       TYPE sdc_ar_reciepts_publish_tbl IS TABLE OF xx_sdc_ar_reciepts_publish_stg%ROWTYPE
          INDEX BY BINARY_INTEGER;

       x_sdc_ar_reciepts_publish_tbl   sdc_ar_reciepts_publish_tbl;

       x_err_code       NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       x_err_msg        VARCHAR2(50);
       x_count          NUMBER:=0;
       x_date           DATE := SYSDATE;
       x_cnt            NUMBER := 0;
       x_counter        NUMBER := 0;
       x_batch_id       NUMBER;
       x_batch_size     NUMBER := TO_NUMBER(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','AR_RECPT_BATCH_SIZE'), 1000));
       x_rec_exists     VARCHAR2(1);
       x_date_from      DATE;
       x_date_to        DATE;
       x_new_type       VARCHAR2(20);

    BEGIN
       p_retcode := xx_emf_cn_pkg.cn_success;
       x_err_code := xx_emf_pkg.set_env;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Set EMF Env x_error_code: '||x_err_code);

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Parameters: ');
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Run Type : ' || p_type);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Site Number From : ' || p_cust_site_from);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Site Number To   : ' || p_cust_site_to);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date From: ' || p_date_from);
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date To: ' || p_date_to);

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Clearing the PLSQL Table Variable');
       x_sdc_ar_reciepts_publish_tbl.DELETE;

       x_date_from := TO_DATE(p_date_from, 'DD-MON-YYYY');
       x_date_to := TO_DATE(p_date_to, 'DD-MON-YYYY');

      IF p_type = 'New' THEN
         IF p_cust_site_from IS NOT NULL OR p_cust_site_to IS NOT NULL THEN
            x_new_type := 'RESEND';
         ELSE
            x_date_to := SYSDATE;
            x_date_from := TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','AR_RECPT_LAST_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS');
            x_new_type  := 'NEW';
         END IF;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Type: ' || x_new_type);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date From: ' || x_date_from);
	 xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date To: ' || x_date_to);

         FOR elig_cust_rec IN c_elig_cust(x_new_type, x_date_from, x_date_to,p_cust_site_from,p_cust_site_to)
         LOOP
            x_rec_exists := 'N';
            IF x_new_type = 'NEW' THEN
               --Check for data already sent or new data
               BEGIN
                  SELECT 'X'
                    INTO x_rec_exists
                    FROM xx_sdc_ar_receipt_stg stg
                        ,xx_sdc_ar_rcpt_ws_v vw
                   WHERE NVL(stg.collections_status,'Y')||NVL(stg.net_balance,0)||NVL(stg.daily_sales_outstanding,0)||NVL(stg.amount_overdue,0) =
                         NVL(vw.collections_status,'Y')||NVL(vw.net_balance,0)||NVL(vw.daily_sales_outstanding,0)||NVL(vw.amount_overdue,0)
                     AND stg.publish_batch_id = (SELECT MAX(publish_batch_id)
                                                   FROM xx_sdc_ar_reciepts_publish_stg
                                                  WHERE cust_account_id = elig_cust_rec.customer_id
                                                    AND customer_site_id = elig_cust_rec.cust_acct_site_id
                                                    AND status = 'SUCCESS' )
                     AND stg.customer_site_id = vw.customer_site_id
                     AND stg.cust_account_id = vw.cust_account_id
                     AND vw.customer_site_id = elig_cust_rec.cust_acct_site_id
                     AND vw.cust_account_id = elig_cust_rec.customer_id
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS THEN
                     x_rec_exists := 'N';
               END;
            END IF;

            IF x_rec_exists = 'N' THEN
               --Set batch id and increment counter
               IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
                  x_batch_id  := xx_sdc_ar_receipt_batch_s.nextval;
                  x_counter       := 1;
               ELSE
                  x_counter := x_counter + 1;
               END IF;
               x_count:=x_count+1;
               x_sdc_ar_reciepts_publish_tbl(x_count).record_id :=xxintg.xx_sdc_ar_rcpt_publish_stg_s1.NEXTVAL;
               x_sdc_ar_reciepts_publish_tbl(x_count).publish_batch_id :=x_batch_id;
               x_sdc_ar_reciepts_publish_tbl(x_count).cust_account_id := elig_cust_rec.customer_id;
               x_sdc_ar_reciepts_publish_tbl(x_count).customer_site_id := elig_cust_rec.cust_acct_site_id;
               x_sdc_ar_reciepts_publish_tbl(x_count).publish_time := SYSDATE;
               x_sdc_ar_reciepts_publish_tbl(x_count).publish_system:=x_publish_system;
               x_sdc_ar_reciepts_publish_tbl(x_count).target_system :=x_target_system;
               x_sdc_ar_reciepts_publish_tbl(x_count).status:=x_status_flag;
               x_sdc_ar_reciepts_publish_tbl(x_count).creation_date:=SYSDATE;
               x_sdc_ar_reciepts_publish_tbl(x_count).created_by:=x_user_id;
               x_sdc_ar_reciepts_publish_tbl(x_count).last_update_date:=SYSDATE;
               x_sdc_ar_reciepts_publish_tbl(x_count).last_updated_by:=x_user_id;
               x_sdc_ar_reciepts_publish_tbl(x_count).last_update_login:=x_login_id;
               x_sdc_ar_reciepts_publish_tbl(x_count).request_id := x_request_id;
               x_sdc_ar_reciepts_publish_tbl(x_count).instance_id := NULL;
               x_sdc_ar_reciepts_publish_tbl(x_count).sfdc_id := NULL;
               x_sdc_ar_reciepts_publish_tbl(x_count).response_message := NULL;
            END IF;
         END LOOP;

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Number of Customer Inserted to the Control Table are: '||x_sdc_ar_reciepts_publish_tbl.COUNT);

         IF x_sdc_ar_reciepts_publish_tbl.COUNT > 0
         THEN
            FORALL i_rec IN 1 .. x_sdc_ar_reciepts_publish_tbl.COUNT
               INSERT INTO xx_sdc_ar_reciepts_publish_stg
                    VALUES x_sdc_ar_reciepts_publish_tbl (i_rec);
         END IF;
         COMMIT;

         IF x_new_type = 'NEW' THEN
            --Update program last run date at EMF
            UPDATE xx_emf_process_parameters
               SET parameter_value = TO_CHAR(x_date, 'DD-MON-YYYY HH24:MI:SS')
             WHERE parameter_name = 'AR_RECPT_LAST_RUN'
               AND process_id = ( SELECT process_id
                                    FROM xx_emf_process_setup
                                   WHERE process_name = 'XXSFDCOUTBOUNDINTF');
            COMMIT;
         END IF;
      ELSE
         FOR r_republish_rec IN c_republish_rec (p_type, x_date_from, x_date_to )
         LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' Republish Old Batch ID ...' || r_republish_rec.publish_batch_id );
	    x_batch_id  := xx_sdc_ar_receipt_batch_s.nextval;
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' Republish New Batch ID ...' || x_batch_id );

            UPDATE xx_sdc_ar_reciepts_publish_stg
               SET status             = 'NEW',
                   response_message   = NULL,
                   sfdc_id            = NULL,
                   last_update_date   = SYSDATE,
                   last_update_login  = x_login_id,
                   last_updated_by    = x_user_id,
                   request_id         = x_request_id,
	           publish_batch_id   = x_batch_id,
	           instance_id        = NULL
             WHERE publish_batch_id = r_republish_rec.publish_batch_id
               AND nvl(status,'NEW') <> 'SUCCESS';
         END LOOP;
         COMMIT;
      END IF;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Call procedure to raise business event');
       --Call procedure to raise business event
       raise_publish_event;

    EXCEPTION WHEN OTHERS
    THEN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Unknow Error in side main_prc: '||SQLERRM);

    END main_prc;
----------------------------------------------------------------------
    FUNCTION ret_collection_status ( p_cust_account_id   IN   NUMBER)
    RETURN VARCHAR2
    IS
       CURSOR c_col_status(p_acct_id NUMBER)
       IS
       SELECT flv.meaning status
         FROM iex_delinquencies_all ida
             ,fnd_lookup_values_vl flv
        WHERE flv.lookup_type = 'IEX_DELINQUENCY_STATUS'
          AND flv.lookup_code = ida.status
          AND NVL(flv.enabled_flag,'X')='Y'
          AND SYSDATE BETWEEN NVL(flv.start_date_active,SYSDATE) AND NVL(flv.end_date_active,SYSDATE)
          AND cust_account_id = p_acct_id;

       x_status    VARCHAR2(100):=NULL;
    BEGIN

       FOR col_status_rec in c_col_status(p_cust_account_id)
       LOOP
           IF col_status_rec.status = 'DELINQUENT'
           THEN
              RETURN col_status_rec.status;
           END IF;
           x_status:=col_status_rec.status;
       END LOOP;
       RETURN x_status;
    END ret_collection_status;

   --Procedure to raise business event
   PROCEDURE raise_publish_event
   IS

      CURSOR c_fetch_batch
      IS
      SELECT DISTINCT publish_batch_id
        FROM xx_sdc_ar_reciepts_publish_stg
       WHERE request_id = x_request_id
    ORDER BY publish_batch_id ASC;

      --PRAGMA AUTONOMOUS_TRANSACTION;
      x_event_parameter_list   wf_parameter_list_t;
      x_event_name             VARCHAR2 (100)      := 'xxintg.oracle.apps.sfdc.arreceipt.publish';
      x_event_key              VARCHAR2 (100)      := SYS_GUID();
   BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside BE raise');
      FOR r_fetch_batch IN c_fetch_batch
      LOOP
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside BE raise: '||r_fetch_batch.publish_batch_id);
         x_event_parameter_list := WF_PARAMETER_LIST_T ( WF_PARAMETER_T ('PUBLISH_BATCH_ID', r_fetch_batch.publish_batch_id));

         wf_event.raise ( p_event_name   => x_event_name
                         ,p_event_key    => x_event_key
                         --,p_event_data   => p_event_data
                         ,p_parameters   => x_event_parameter_list);
         --COMMIT;
      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Exception in raise_publish_event');
   END raise_publish_event;

END xx_sdc_ar_rcpt_intf_pkg;
/
