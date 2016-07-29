DROP PACKAGE BODY APPS.XX_SDC_OIC_OUTBOUND_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_OIC_OUTBOUND_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 04-APR-2014
 File Name     : XXSDCOICOUTINTF.pkb
 Description   : This script creates the body of the package
                 xx_sdc_oic_outbound_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-APR-2014 Sharath Babu          Initial Development
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

   --Procedure to raise business event
   PROCEDURE raise_publish_event
   IS

      CURSOR c_fetch_batch
      IS
      SELECT DISTINCT publish_batch_id
        FROM xx_sdc_oic_sp_publish_stg
       WHERE request_id = x_request_id
    ORDER BY publish_batch_id ASC;

      --PRAGMA AUTONOMOUS_TRANSACTION;
      x_event_parameter_list   wf_parameter_list_t;
      x_event_name             VARCHAR2 (100)      := 'xxintg.oracle.apps.sfdc.oicdetails.publish';
      x_event_key              VARCHAR2 (100)      := SYS_GUID();
   BEGIN

      FOR r_fetch_batch IN c_fetch_batch
      LOOP
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside BE raise: '||r_fetch_batch.publish_batch_id);
         x_event_parameter_list := WF_PARAMETER_LIST_T ( WF_PARAMETER_T ('PUBLISH_BATCH_ID', r_fetch_batch.publish_batch_id)
                                                        ,WF_PARAMETER_T ('TARGET_SYSTEM', x_target_system)
                                                       );

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

   PROCEDURE fetch_upd_oic_details(
                                       p_errbuf           OUT NOCOPY  VARCHAR2
                                      ,p_retcode          OUT NOCOPY  NUMBER
                                      ,p_type             IN VARCHAR2
                                      ,p_hidden1          IN VARCHAR2
                                      ,p_hidden2          IN VARCHAR2
                                      ,p_slrep_num_from   IN JTF_RS_SALESREPS.SALESREP_NUMBER%TYPE DEFAULT NULL
                                      ,p_slrep_num_to     IN JTF_RS_SALESREPS.SALESREP_NUMBER%TYPE DEFAULT NULL
                                      ,p_date_from        IN VARCHAR2 DEFAULT NULL
                                      ,p_date_to          IN VARCHAR2 DEFAULT NULL
                                  )
   IS
      CURSOR c_oic_details( cp_type             VARCHAR2
                            ,cp_date_from        DATE
                            ,cp_date_to          DATE
                            ,cp_slrep_num_from   JTF_RS_SALESREPS.SALESREP_NUMBER%TYPE
                            ,cp_slrep_num_to     JTF_RS_SALESREPS.SALESREP_NUMBER%TYPE
                            )
      IS
      SELECT  DISTINCT  sales_person_num
              ,salesrep_id
              ,pay_period_id
              ,quota_id
      FROM (
      SELECT   rep.salesrep_number sales_person_num
              ,rep.salesrep_id
              ,cml.processed_period_id pay_period_id
              ,qut.quota_id
              ,GREATEST(cml.last_update_date,
                        NVL(( SELECT pqa.last_update_date
                                FROM cn_srp_period_quotas_all pqa
                               WHERE pqa.salesrep_id = rep.salesrep_id
                                 AND pqa.period_id = cml.processed_period_id
                                 AND pqa.quota_id = qut.quota_id
                             ), '01-JAN-1000')
                        ) last_update_date
         FROM  cn_commission_headers_all cmh
              ,cn_commission_lines_all cml
              ,jtf_rs_salesreps rep
              ,cn_quotas_all qut
        WHERE cml.credited_salesrep_id=rep.salesrep_id
          AND cml.quota_id = qut.quota_id
          AND cml.status = 'CALC'
          AND cml.commission_header_id = cmh.commission_header_id
          AND NOT EXISTS ( SELECT 'Y'
                             FROM cn_period_statuses_all psa
                            WHERE psa.start_date < '01-JAN-2014'
                              AND psa.period_id = cml.processed_period_id )
          AND EXISTS ( SELECT lookup_code
                        FROM fnd_lookup_values_vl
                       WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                         AND lookup_code = cmh.org_id
                         AND NVL(enabled_flag,'X')='Y'
                   AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
         )
         WHERE (last_update_date BETWEEN cp_date_from AND cp_date_to
                AND cp_type IN ('NEW'))
           OR (sales_person_num BETWEEN cp_slrep_num_from AND cp_slrep_num_to
               AND cp_type IN ('RESEND'))
         ORDER BY salesrep_id, quota_id, pay_period_id;

        CURSOR c_republish_rec( cp_type VARCHAR2, cp_date_from DATE, cp_date_to DATE )
        IS
          SELECT DISTINCT publish_batch_id
            FROM xx_sdc_oic_sp_publish_stg
           WHERE TRUNC(creation_date) BETWEEN TRUNC(cp_date_from) AND TRUNC(cp_date_to)
             AND cp_type IN ('Reprocess')
             AND nvl(status, 'NEW')   <> 'SUCCESS';

      TYPE xx_sdc_oic_pub_tab IS TABLE OF xx_sdc_oic_sp_publish_stg%ROWTYPE
      INDEX BY BINARY_INTEGER;

      xx_sdc_oic_pub_tab_typ   xx_sdc_oic_pub_tab;

      x_date           DATE   := SYSDATE;
      x_cnt            NUMBER := 0;
      x_counter        NUMBER := 0;
      x_batch_id       NUMBER;
      x_batch_size     NUMBER := TO_NUMBER(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','OIC_BATCH_SIZE'), 1000));
      x_error_code     NUMBER:= xx_emf_cn_pkg.CN_SUCCESS;
      x_oic_exists    VARCHAR2(1);
      x_csite_exists   VARCHAR2(1);
      x_date_from      DATE;
      x_date_to        DATE;
      x_new_type       VARCHAR2(20);

   BEGIN

      p_retcode := xx_emf_cn_pkg.cn_success;
      x_error_code    := xx_emf_pkg.set_env;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Parameters: ');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Run Type : ' || p_type);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'SalesRep Number From : ' || p_slrep_num_from);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'SalesRep Number To   : ' || p_slrep_num_to);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date From: ' || p_date_from);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date To: ' || p_date_to);

      x_date_from := TO_DATE(p_date_from, 'DD-MON-YYYY');
      x_date_to := TO_DATE(p_date_to, 'DD-MON-YYYY');

      IF p_type = 'New' THEN
         IF p_slrep_num_from IS NOT NULL OR p_slrep_num_to IS NOT NULL THEN
            x_new_type := 'RESEND';
         ELSE
            x_date_to := SYSDATE;
            x_date_from := TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','OIC_LAST_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS');
            x_new_type  := 'NEW';
         END IF;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Type: ' || x_new_type);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date From: ' || x_date_from);
	 xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date To: ' || x_date_to);

         --Fetch records to process
         FOR r_oic_details IN c_oic_details(x_new_type, x_date_from, x_date_to,p_slrep_num_from,p_slrep_num_to)
         LOOP
            x_oic_exists := 'N';
            IF x_new_type = 'NEW' THEN
               --Check for oic data already sent or new data
               BEGIN
                  SELECT 'X'
                    INTO x_oic_exists
	            FROM xx_sdc_oic_sp_details_stg stg
	                ,xx_sdc_oic_sp_details_v vw
	           WHERE NVL(stg.comm_ptd,0)||NVL(stg.bonus_ptd,0)||NVL(stg.target_amount,0)||NVL(stg.currency,'XXXX') =
	                 NVL(vw.comm_ptd,0)||NVL(vw.bonus_ptd,0)||NVL(vw.target_amount,0)||NVL(vw.currency,'XXXX')
	             AND stg.publish_batch_id = (SELECT MAX(publish_batch_id)
	                                           FROM xx_sdc_oic_sp_publish_stg
	                                          WHERE salesrep_id = r_oic_details.salesrep_id
	                                            AND pay_period_id = r_oic_details.pay_period_id
	                                            AND quota_id = r_oic_details.quota_id
	                                            AND status = 'SUCCESS'
	                                          )
	             AND vw.salesrep_id = stg.salesrep_id
	             AND vw.pay_period_id = stg.pay_period_id
	             AND vw.quota_id = stg.quota_id
                     AND stg.salesrep_id = r_oic_details.salesrep_id
                     AND stg.pay_period_id = r_oic_details.pay_period_id
                     AND stg.quota_id = r_oic_details.quota_id
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS THEN
                     x_oic_exists := 'N';
               END;
            END IF;
            IF x_oic_exists = 'N' THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'salesrep_num: '||r_oic_details.sales_person_num||' quota_id: '||
                                                          r_oic_details.quota_id||' pay_period_id: '||r_oic_details.pay_period_id);
               --Set batch id and increment counter
               IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
                   x_batch_id  := xx_sdc_oicdetails_batch_s.nextval;
                   x_counter       := 1;
               ELSE
                   x_counter := x_counter + 1;
               END IF;
               x_cnt := x_cnt + 1;
               xx_sdc_oic_pub_tab_typ(x_cnt).publish_batch_id := x_batch_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).record_id := xx_sdc_oicdetails_pub_rec_s.NEXTVAL;
               xx_sdc_oic_pub_tab_typ(x_cnt).sales_person_num := r_oic_details.sales_person_num;
               xx_sdc_oic_pub_tab_typ(x_cnt).salesrep_id := r_oic_details.salesrep_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).pay_period_id := r_oic_details.pay_period_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).quota_id := r_oic_details.quota_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).publish_system := x_publish_system;
               xx_sdc_oic_pub_tab_typ(x_cnt).target_system := x_target_system;
               xx_sdc_oic_pub_tab_typ(x_cnt).status := x_status_flag;
               xx_sdc_oic_pub_tab_typ(x_cnt).creation_date := SYSDATE;
               xx_sdc_oic_pub_tab_typ(x_cnt).created_by := x_user_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).last_update_date := SYSDATE;
               xx_sdc_oic_pub_tab_typ(x_cnt).last_updated_by := x_user_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).last_update_login := x_login_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).request_id := x_request_id;
               xx_sdc_oic_pub_tab_typ(x_cnt).ack_time := NULL;
               xx_sdc_oic_pub_tab_typ(x_cnt).instance_id := NULL;
               xx_sdc_oic_pub_tab_typ(x_cnt).sfdc_id := NULL;
               xx_sdc_oic_pub_tab_typ(x_cnt).response_message := NULL;
            END IF;
         END LOOP;

         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Record Count: '||xx_sdc_oic_pub_tab_typ.COUNT);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Insert into Control table');
         --Insert into control table
          IF xx_sdc_oic_pub_tab_typ.COUNT > 0
          THEN
             FORALL i IN 1 .. xx_sdc_oic_pub_tab_typ.COUNT
                INSERT INTO xx_sdc_oic_sp_publish_stg
                     VALUES xx_sdc_oic_pub_tab_typ (i);
          END IF;
         IF x_new_type = 'NEW' THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update program last run date at EMF');
            --Update program last run date at EMF
            UPDATE xx_emf_process_parameters
               SET parameter_value = TO_CHAR(x_date, 'DD-MON-YYYY HH24:MI:SS')
             WHERE parameter_name = 'OIC_LAST_RUN'
               AND process_id = ( SELECT process_id
                                    FROM xx_emf_process_setup
                                   WHERE process_name = 'XXSFDCOUTBOUNDINTF');
            COMMIT;
         END IF;
      ELSE
         FOR r_republish_rec IN c_republish_rec (p_type, x_date_from, x_date_to )
         LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' Republish Old Batch ID ...' || r_republish_rec.publish_batch_id );
	    x_batch_id  := xx_sdc_oicdetails_batch_s.nextval;
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' Republish New Batch ID ...' || x_batch_id );

            UPDATE xx_sdc_oic_sp_publish_stg
               SET status             = 'NEW',
                   response_message   = NULL,
                   sfdc_id            = NULL,
                   last_update_date   = SYSDATE,
                   last_update_login  = x_login_id,
                   last_updated_by    = x_user_id,
                   request_id         = x_request_id,
	           publish_batch_id   = x_batch_id,
	           instance_id        = NULL,
	           ack_time           = NULL
             WHERE publish_batch_id = r_republish_rec.publish_batch_id
               AND nvl(status,'NEW') <> 'SUCCESS';
         END LOOP;
         COMMIT;
      END IF;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Call procedure to raise business event');
       --Call procedure to raise business event
       raise_publish_event;

   EXCEPTION
   WHEN OTHERS THEN
      p_retcode := xx_emf_cn_pkg.cn_prc_err;
      p_errbuf := 'Error in fetch_upd_oic_details'||SQLERRM;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||p_retcode||' Error: '||p_errbuf);

   END fetch_upd_oic_details;

END xx_sdc_oic_outbound_pkg;
/
