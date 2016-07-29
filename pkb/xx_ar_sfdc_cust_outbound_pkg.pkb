DROP PACKAGE BODY APPS.XX_AR_SFDC_CUST_OUTBOUND_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_ar_sfdc_cust_outbound_pkg
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 04-APR-2014
 File Name     : XXARCUSTSFDCOUTINTF.pkb
 Description   : This script creates the body of the package
                 xx_ar_sfdc_cust_outbound_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-APR-2014 Sharath Babu          Initial Development
 17-Sep-2014 Bedabrata             Modification for Wave2. US customers
                                   restriction commented out.
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
        FROM xx_sdc_customer_publish_stg
       WHERE request_id = x_request_id
    ORDER BY publish_batch_id ASC;

      --PRAGMA AUTONOMOUS_TRANSACTION;
      x_event_parameter_list   wf_parameter_list_t;
      x_event_name             VARCHAR2 (100)      := 'xxintg.oracle.apps.sfdc.customer.publish';
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

   PROCEDURE fetch_upd_cust_details(
                                       p_errbuf           OUT NOCOPY  VARCHAR2
                                      ,p_retcode          OUT NOCOPY  NUMBER
                                      ,p_type             IN VARCHAR2
				      ,p_hidden1          IN VARCHAR2
				      ,p_hidden2          IN VARCHAR2
				      ,p_cust_site_from   IN HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
				      ,p_cust_site_to     IN HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE DEFAULT NULL
				      ,p_date_from        IN VARCHAR2 DEFAULT NULL
				      ,p_date_to          IN VARCHAR2 DEFAULT NULL
                                     )
   IS
      CURSOR c_cust_details( cp_type             VARCHAR2
                            ,cp_date_from        DATE
                            ,cp_date_to          DATE
                            ,cp_cust_site_from   HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE
                            ,cp_cust_site_to     HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE
                            )
      IS
      SELECT  DISTINCT cust_account_id
             ,cust_acct_site_id
             ,site_number
      FROM (
      SELECT   hca.cust_account_id
              ,hcsu.cust_acct_site_id
              ,hps.party_site_number site_number
              ,GREATEST(hp.last_update_date,hca.last_update_date,
               hcp.last_update_date,
               --NVL(hcps1.last_update_date,'01-JAN-1000'),
               NVL(hr.last_update_date,'01-JAN-1000'),
               hcas.last_update_date,
               hcsu.last_update_date,hps.last_update_date,
               hl.last_update_date,NVL(hcps2.last_update_date,'01-JAN-1000')
              --,NVL(get_terr_update_date(hl.country,hca.cust_account_id,hps.party_site_id,hca.account_number,hl.county,hl.postal_code,hl.province,hl.state,hp.party_name),'01-JAN-1000')
               ) last_update_date
              ,xx_ar_sfdc_cust_outbound_pkg.get_terr_update_flag(hl.country,hca.cust_account_id,hps.party_site_id,hca.account_number,hl.county,hl.postal_code,hl.province,hl.state,hp.party_name,cp_date_from,cp_date_to) territory_flag
        FROM  hz_parties hp
             ,hz_cust_accounts hca
             ,hz_customer_profiles hcp
             --,hz_contact_points hcps1
             ,hz_relationships hr
             ,hz_cust_acct_sites_all hcas
             ,hz_cust_site_uses_all hcsu
             ,hz_party_sites hps
             ,hz_locations hl
             ,hz_contact_points hcps2
       WHERE hcps2.status(+) = 'A'
         AND hcps2.contact_point_type(+) IN ('PHONE','EMAIL','WEB')
         AND hcps2.owner_table_name(+) = 'HZ_PARTY_SITES'
         AND hcps2.owner_table_id(+) = hps.party_site_id
         AND hcas.party_site_id = hps.party_site_id
         AND hps.status = 'A'
         --AND hps.party_id = hp.party_id
         --AND hl.country = 'US'
--         AND hl.country = DECODE(hcsu.site_use_code,'BILL_TO','US',hl.country)  -- Commented out for Wave2
         AND hl.location_id = hps.location_id
         AND hcsu.site_use_code IN ('BILL_TO','SHIP_TO')
         AND hcsu.status = 'A'
         AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
         AND EXISTS ( SELECT lookup_code
                        FROM fnd_lookup_values_vl
                       WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                         AND lookup_code = hcsu.org_id
                         AND NVL(enabled_flag,'X')='Y'
                         AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
         AND hcas.status = 'A'
         AND hcas.cust_account_id = hca.cust_account_id
         --AND hcps1.contact_point_type(+) IN ('PHONE','EMAIL','WEB')
         --AND hcps1.owner_table_name(+) = 'HZ_PARTIES'
         --AND hcps1.owner_table_id(+) = hp.party_id
         AND hr.subject_id(+) = hp.party_id
         AND hr.relationship_code(+) = 'Healthcare Sys Parent of'
         AND hp.status = 'A'
         AND hp.party_id = hca.party_id
         AND hcp.status = 'A'
         AND hca.status = 'A'
         AND hca.customer_type = 'R'
         AND hcp.cust_account_id = hca.cust_account_id
         AND hps.party_site_number BETWEEN NVL(cp_cust_site_from,hps.party_site_number) AND NVL(cp_cust_site_to,hps.party_site_number)
         )
         --WHERE last_update_date > TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','CUSTOMER_LAST_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS');
         WHERE ( ( ( last_update_date BETWEEN cp_date_from AND cp_date_to) OR (territory_flag = 'Y') )
                    AND cp_type IN ('INITIAL')
               )
           OR (site_number BETWEEN cp_cust_site_from AND cp_cust_site_to
               AND cp_type IN ('RESEND')) ;

           /*AND ( EXISTS ( SELECT 'X'
                          FROM xx_sdc_customer_publish_stg2 pub
                         WHERE pub.status <> 'NEW'
                           AND pub.last_update_date < last_update_date
                           AND pub.cust_acc_site_id = cust_acct_site_id
                           AND pub.cust_account_id = cust_account_id ) OR
		NOT EXISTS ( SELECT 'X'
			     FROM xx_sdc_customer_publish_stg2 pub
			    WHERE pub.status = 'NEW'
			      AND pub.cust_acc_site_id = cust_acct_site_id
		              AND pub.cust_account_id = cust_account_id )
		 );*/

      CURSOR c_cust_details_nw( cp_type             VARCHAR2
                               ,cp_date_from        DATE
                               ,cp_date_to          DATE
                               ,cp_cust_site_from   HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE
                               ,cp_cust_site_to     HZ_PARTY_SITES.PARTY_SITE_NUMBER%TYPE
                               )
      IS
      SELECT  DISTINCT cust_account_id
             ,cust_acct_site_id
             ,site_number
      FROM (
      SELECT   hca.cust_account_id
              ,hcsu.cust_acct_site_id
              ,hps.party_site_number site_number
              ,GREATEST(hp.last_update_date,hca.last_update_date,
               hcp.last_update_date,
               --NVL(hcps1.last_update_date,'01-JAN-1000'),
               NVL(hr.last_update_date,'01-JAN-1000'),
               hcas.last_update_date,
               hcsu.last_update_date,hps.last_update_date,
               hl.last_update_date,NVL(hcps2.last_update_date,'01-JAN-1000')
              --,NVL(get_terr_update_date(hl.country,hca.cust_account_id,hps.party_site_id,hca.account_number,hl.county,hl.postal_code,hl.province,hl.state,hp.party_name),'01-JAN-1000')
               ) last_update_date
              ,xx_ar_sfdc_cust_outbound_pkg.get_terr_update_flag(hl.country,hca.cust_account_id,hps.party_site_id,hca.account_number,hl.county,hl.postal_code,hl.province,hl.state,hp.party_name,cp_date_from,cp_date_to) territory_flag
        FROM  hz_parties hp
             ,hz_cust_accounts hca
             ,hz_customer_profiles hcp
             --,hz_contact_points hcps1
             ,hz_relationships hr
             ,hz_cust_acct_sites_all hcas
             ,hz_cust_site_uses_all hcsu
             ,hz_party_sites hps
             ,hz_locations hl
             ,hz_contact_points hcps2
       WHERE /*hcps2.status(+) = 'A'
         AND*/ hcps2.contact_point_type(+) IN ('PHONE','EMAIL','WEB')
         AND hcps2.owner_table_name(+) = 'HZ_PARTY_SITES'
         AND hcps2.owner_table_id(+) = hps.party_site_id
         AND hcas.party_site_id = hps.party_site_id
         --AND hps.status = 'A'
         --AND hps.party_id = hp.party_id
         --AND hl.country = 'US'
--         AND hl.country = DECODE(hcsu.site_use_code,'BILL_TO','US',hl.country) -- commented out for Wave2
         AND hl.location_id = hps.location_id
         AND hcsu.site_use_code IN ('BILL_TO','SHIP_TO')
         --AND hcsu.status = 'A'
         AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
         AND EXISTS ( SELECT lookup_code
                        FROM fnd_lookup_values_vl
                       WHERE lookup_type = 'XX_SFDC_OU_LOOKUP'
                         AND lookup_code = hcsu.org_id
                         AND NVL(enabled_flag,'X')='Y'
                         AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE))
         --AND hcas.status = 'A'
         AND hcas.cust_account_id = hca.cust_account_id
         AND hr.subject_id(+) = hp.party_id
         AND hr.relationship_code(+) = 'Healthcare Sys Parent of'
         --AND hp.status = 'A'
         AND hp.party_id = hca.party_id
         --AND hcp.status = 'A'
         --AND hca.status = 'A'
         AND hca.customer_type = 'R'
         AND hcp.cust_account_id = hca.cust_account_id
         AND hps.party_site_number BETWEEN NVL(cp_cust_site_from,hps.party_site_number) AND NVL(cp_cust_site_to,hps.party_site_number)
         )
         WHERE ( ( ( last_update_date BETWEEN cp_date_from AND cp_date_to) OR (territory_flag = 'Y') )
                  AND cp_type IN ('NEW')
                )
           OR (site_number BETWEEN cp_cust_site_from AND cp_cust_site_to
               AND cp_type IN ('RESEND')) ;

        CURSOR c_republish_rec( cp_type VARCHAR2, cp_date_from DATE, cp_date_to DATE )
        IS
          SELECT DISTINCT publish_batch_id
            FROM xx_sdc_customer_publish_stg
           WHERE TRUNC(creation_date) BETWEEN TRUNC(cp_date_from) AND TRUNC(cp_date_to)
             AND cp_type IN ('Reprocess')
             AND nvl(status, 'NEW')   <> 'SUCCESS';

      TYPE xx_sdc_cust_pub_tab IS TABLE OF xx_sdc_customer_publish_stg%ROWTYPE
      INDEX BY BINARY_INTEGER;

      xx_sdc_cust_pub_tab_typ   xx_sdc_cust_pub_tab;

      x_date           DATE   := SYSDATE;
      x_cnt            NUMBER := 0;
      x_counter        NUMBER := 0;
      x_batch_id       NUMBER;
      x_batch_size     NUMBER := TO_NUMBER(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','CUSTOMER_BATCH_SIZE'), 1000));
      x_error_code     NUMBER:= xx_emf_cn_pkg.CN_SUCCESS;
      x_cust_exists    VARCHAR2(1);
      x_csite_exists   VARCHAR2(1);
      x_date_from      DATE;
      x_date_to        DATE;
      x_new_type       VARCHAR2(20);

      invalid_params EXCEPTION;

   BEGIN

      p_retcode := xx_emf_cn_pkg.cn_success;
      x_error_code    := xx_emf_pkg.set_env;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Parameters: ');
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Run Type : ' || p_type);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Site Number From : ' || p_cust_site_from);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Site Number To   : ' || p_cust_site_to);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date From: ' || p_date_from);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Date To: ' || p_date_to);

      IF ( p_cust_site_from IS NOT NULL AND p_cust_site_to IS NULL ) OR
         ( p_cust_site_from IS NULL AND p_cust_site_to IS NOT NULL ) OR
         ( p_date_from IS NULL AND p_date_to IS NOT NULL ) OR
         ( p_date_from IS NOT NULL AND p_date_to IS NULL ) THEN
          RAISE invalid_params;
      END IF;

      IF p_date_from IS NOT NULL AND p_date_to IS NOT NULL THEN
         x_date_from := TO_DATE(p_date_from||' 00:00:00', 'DD-MON-YYYY HH24:MI:SS');
         x_date_to := TO_DATE(p_date_to||' 23:59:59', 'DD-MON-YYYY HH24:MI:SS');
      END IF;

      IF p_type = 'New' THEN
         IF p_cust_site_from IS NOT NULL AND p_cust_site_to IS NOT NULL THEN
            x_new_type := 'RESEND';
         ELSE
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Param Site Number null: New mode: Incremental run ');
            x_date_to := SYSDATE;
            x_date_from := TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','CUSTOMER_LAST_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS');
            x_new_type  := 'NEW';
         END IF;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Type: ' || x_new_type);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date From: ' || x_date_from);
	 xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date To: ' || x_date_to);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date From: ' || TO_CHAR(x_date_from,'DD-MON-YYYY HH24:MI:SS'));
	 xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date To: ' || TO_CHAR(x_date_to,'DD-MON-YYYY HH24:MI:SS'));

         --Fetch records to process
         FOR r_cust_details_nw IN c_cust_details_nw(x_new_type, x_date_from, x_date_to,p_cust_site_from,p_cust_site_to)
         LOOP
            --Commented to improve performance
            --x_cust_exists := 'N';
            --x_csite_exists := 'N';
            /*IF x_new_type = 'NEW' THEN
               --Check for customer data already sent or new data
               BEGIN
                  SELECT 'X'
                    INTO x_cust_exists
	            FROM xx_sdc_cust_account_stg stg
	                ,xx_sdc_cust_account_ws_v vw
	           WHERE stg.customer||NVL(stg.alias,'XXX')||stg.account_number||NVL(stg.acc_customer_classification,'XXX')||NVL(stg.parent_account_name,'XXX')||
	                 NVL(stg.parent_account_number,'9999')||NVL(stg.duns_number,'9999')||NVL(stg.credit_check,'X')||NVL(stg.credit_hold,'X') =
	                 vw.customer||NVL(vw.alias,'XXX')||vw.account_number||NVL(vw.acc_customer_classification,'XXX')||NVL(vw.parent_account_name,'XXX')||
	                 NVL(vw.parent_account_number,'9999')||NVL(vw.duns_number,'9999')||NVL(vw.credit_check,'X')||NVL(vw.credit_hold,'X')
	             AND stg.publish_batch_id = (SELECT MAX(publish_batch_id)
	                                           FROM xx_sdc_customer_publish_stg
	                                          WHERE cust_account_id = r_cust_details_nw.cust_account_id
	                                            AND status = 'SUCCESS' )
	             AND stg.customer_account_id = vw.customer_account_id
                     AND vw.customer_account_id = r_cust_details_nw.cust_account_id
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS THEN
                     x_cust_exists := 'N';
               END;
               --Check for customer site data already sent or new data
               BEGIN
                  SELECT 'X'
                    INTO x_csite_exists
                    FROM xx_sdc_cust_acc_sites_stg stg
                        ,xx_sdc_cust_acc_sites_ws_v vw
                   WHERE stg.site_number||stg.address_line_1||NVL(stg.address_line_2,'XXX')||NVL(stg.city,'XXX')||NVL(stg.state,'XXX')||NVL(stg.postal_code,'XXX')||NVL(stg.county,'XXX')||
                        NVL(stg.country,'XXX')||NVL(stg.gpo_entity,'XXX')||NVL(stg.territory,'XXX')||NVL(stg.gln_number,'XXX')||NVL(stg.cust_site_status,'XXX')||NVL(stg.site_phone_number,'XXX')||
	                NVL(stg.site_fax_number,'XXX')||NVL(stg.site_email_address,'XXX')||NVL(stg.site_url,'XXX')||NVL(stg.operating_unit_id,9999)||NVL(stg.ship_to_flag,'XXX')||NVL(stg.bill_to_flag,'XXX') =
	                vw.site_number||vw.address_line_1||NVL(vw.address_line_2,'XXX')||NVL(vw.city,'XXX')||NVL(vw.state,'XXX')||NVL(vw.postal_code,'XXX')||NVL(vw.county,'XXX')||
	                NVL(vw.country,'XXX')||NVL(vw.gpo_entity,'XXX')||NVL(vw.territory,'XXX')||NVL(vw.gln_number,'XXX')||NVL(vw.cust_site_status,'XXX')||NVL(vw.site_phone_number,'XXX')||
	                NVL(vw.site_fax_number,'XXX')||NVL(vw.site_email_address,'XXX')||NVL(vw.site_url,'XXX')||NVL(vw.operating_unit_id,9999)||NVL(vw.ship_to_flag,'XXX')||NVL(vw.bill_to_flag,'XXX')
	            AND stg.publish_batch_id = (SELECT MAX(publish_batch_id)
	                                          FROM xx_sdc_customer_publish_stg
	                                         WHERE cust_account_id = r_cust_details_nw.cust_account_id
	                                           AND cust_acc_site_id = r_cust_details_nw.cust_acct_site_id
	                                           AND status = 'SUCCESS')
	            AND stg.customer_account_site_id = vw.customer_account_site_id
	            AND stg.customer_account_id = vw.customer_account_id
	            AND vw.customer_account_site_id = r_cust_details_nw.cust_acct_site_id
                    AND vw.customer_account_id = r_cust_details_nw.cust_account_id
                    AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS THEN
                     x_csite_exists := 'N';
               END;
            END IF;*/
            --IF x_cust_exists = 'N' OR x_csite_exists = 'N' THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'cust_account_id: '||r_cust_details_nw.cust_account_id||' cust_acct_site_id: '||r_cust_details_nw.cust_acct_site_id);
               --Set batch id and increment counter
               IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
                   x_batch_id  := xx_sdc_customer_batch_s.nextval;
                   x_counter       := 1;
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' New Batch ID ...' || x_batch_id );
               ELSE
                   x_counter := x_counter + 1;
               END IF;
               x_cnt := x_cnt + 1;
               xx_sdc_cust_pub_tab_typ(x_cnt).publish_batch_id := x_batch_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).record_id := xxintg.xx_sdc_customer_publish_stg_s1.NEXTVAL;
               xx_sdc_cust_pub_tab_typ(x_cnt).cust_account_id := r_cust_details_nw.cust_account_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).cust_acc_site_id := r_cust_details_nw.cust_acct_site_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).publish_time := SYSDATE;
               xx_sdc_cust_pub_tab_typ(x_cnt).publish_system := x_publish_system;
               xx_sdc_cust_pub_tab_typ(x_cnt).target_system := x_target_system;
               xx_sdc_cust_pub_tab_typ(x_cnt).status := x_status_flag;
               xx_sdc_cust_pub_tab_typ(x_cnt).ack_time := NULL;
               xx_sdc_cust_pub_tab_typ(x_cnt).aia_proc_inst_id := NULL;
               xx_sdc_cust_pub_tab_typ(x_cnt).creation_date := SYSDATE;
               xx_sdc_cust_pub_tab_typ(x_cnt).created_by := x_user_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).last_update_date := SYSDATE;
               xx_sdc_cust_pub_tab_typ(x_cnt).last_updated_by := x_user_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).last_update_login := x_login_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).request_id := x_request_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).sfdc_id := NULL;
               xx_sdc_cust_pub_tab_typ(x_cnt).response_message := NULL;
            --END IF;
         END LOOP;

         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Record Count: '||xx_sdc_cust_pub_tab_typ.COUNT);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Insert into Control table');
         --Insert into control table
          IF xx_sdc_cust_pub_tab_typ.COUNT > 0
          THEN
             FORALL i IN 1 .. xx_sdc_cust_pub_tab_typ.COUNT
                INSERT INTO xx_sdc_customer_publish_stg
                     VALUES xx_sdc_cust_pub_tab_typ (i);
          END IF;
         IF x_new_type = 'NEW' THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update program last run date at EMF');
            --Update program last run date at EMF
            UPDATE xx_emf_process_parameters
               SET parameter_value = TO_CHAR(x_date, 'DD-MON-YYYY HH24:MI:SS')
             WHERE parameter_name = 'CUSTOMER_LAST_RUN'
               AND process_id = ( SELECT process_id
                                    FROM xx_emf_process_setup
                                   WHERE process_name = 'XXSFDCOUTBOUNDINTF');
            COMMIT;
         END IF;
      ELSIF p_type = 'Initial' THEN
         IF p_cust_site_from IS NOT NULL AND p_cust_site_to IS NOT NULL THEN
            x_new_type := 'RESEND';
         /*ELSIF p_date_from IS NOT NULL AND p_date_to IS NOT NULL THEN
            x_new_type  := 'INITIAL';*/
         ELSE
            x_date_to := SYSDATE;
            x_date_from := TO_DATE(NVL(xx_emf_pkg.get_paramater_value('XXSFDCOUTBOUNDINTF','CUSTOMER_LAST_RUN'), '01-JAN-9999'),'DD-MON-YYYY HH24:MI:SS');
            x_new_type  := 'INITIAL';
         END IF;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Type: ' || x_new_type);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date From: ' || x_date_from);
	 xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Derived Date To: ' || x_date_to);

         --Fetch records to process
         FOR r_cust_details IN c_cust_details(x_new_type, x_date_from, x_date_to,p_cust_site_from,p_cust_site_to)
         LOOP
            --Commented to improve performance
            --x_cust_exists := 'N';
            --x_csite_exists := 'N';
            /*IF x_new_type = 'INITIAL' THEN
               --Check for customer data already sent or new data
               BEGIN
                  SELECT 'X'
                    INTO x_cust_exists
	            FROM xx_sdc_cust_account_stg stg
	                ,xx_sdc_cust_account_ws_v vw
	           WHERE stg.customer||NVL(stg.alias,'XXX')||stg.account_number||NVL(stg.acc_customer_classification,'XXX')||NVL(stg.parent_account_name,'XXX')||
	                 NVL(stg.parent_account_number,'9999')||NVL(stg.duns_number,'9999')||NVL(stg.credit_check,'X')||NVL(stg.credit_hold,'X') =
	                 vw.customer||NVL(vw.alias,'XXX')||vw.account_number||NVL(vw.acc_customer_classification,'XXX')||NVL(vw.parent_account_name,'XXX')||
	                 NVL(vw.parent_account_number,'9999')||NVL(vw.duns_number,'9999')||NVL(vw.credit_check,'X')||NVL(vw.credit_hold,'X')
	             AND stg.publish_batch_id = (SELECT MAX(publish_batch_id)
	                                           FROM xx_sdc_customer_publish_stg
	                                          WHERE cust_account_id = r_cust_details.cust_account_id
	                                            AND status = 'SUCCESS' )
	             AND stg.customer_account_id = vw.customer_account_id
                     AND vw.customer_account_id = r_cust_details.cust_account_id
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS THEN
                     x_cust_exists := 'N';
               END;
               --Check for customer site data already sent or new data
               BEGIN
                  SELECT 'X'
                    INTO x_csite_exists
                    FROM xx_sdc_cust_acc_sites_stg stg
                        ,xx_sdc_cust_acc_sites_ws_v vw
                   WHERE stg.site_number||stg.address_line_1||NVL(stg.address_line_2,'XXX')||NVL(stg.city,'XXX')||NVL(stg.state,'XXX')||NVL(stg.postal_code,'XXX')||NVL(stg.county,'XXX')||
                        NVL(stg.country,'XXX')||NVL(stg.gpo_entity,'XXX')||NVL(stg.territory,'XXX')||NVL(stg.gln_number,'XXX')||NVL(stg.cust_site_status,'XXX')||NVL(stg.site_phone_number,'XXX')||
	                NVL(stg.site_fax_number,'XXX')||NVL(stg.site_email_address,'XXX')||NVL(stg.site_url,'XXX')||NVL(stg.operating_unit_id,9999)||NVL(stg.ship_to_flag,'XXX')||NVL(stg.bill_to_flag,'XXX') =
	                vw.site_number||vw.address_line_1||NVL(vw.address_line_2,'XXX')||NVL(vw.city,'XXX')||NVL(vw.state,'XXX')||NVL(vw.postal_code,'XXX')||NVL(vw.county,'XXX')||
	                NVL(vw.country,'XXX')||NVL(vw.gpo_entity,'XXX')||NVL(vw.territory,'XXX')||NVL(vw.gln_number,'XXX')||NVL(vw.cust_site_status,'XXX')||NVL(vw.site_phone_number,'XXX')||
	                NVL(vw.site_fax_number,'XXX')||NVL(vw.site_email_address,'XXX')||NVL(vw.site_url,'XXX')||NVL(vw.operating_unit_id,9999)||NVL(vw.ship_to_flag,'XXX')||NVL(vw.bill_to_flag,'XXX')
	            AND stg.publish_batch_id = (SELECT MAX(publish_batch_id)
	                                          FROM xx_sdc_customer_publish_stg
	                                         WHERE cust_account_id = r_cust_details.cust_account_id
	                                           AND cust_acc_site_id = r_cust_details.cust_acct_site_id
	                                           AND status = 'SUCCESS')
	            AND stg.customer_account_site_id = vw.customer_account_site_id
	            AND stg.customer_account_id = vw.customer_account_id
	            AND vw.customer_account_site_id = r_cust_details.cust_acct_site_id
                    AND vw.customer_account_id = r_cust_details.cust_account_id
                    AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS THEN
                     x_csite_exists := 'N';
               END;
            END IF;*/
            --IF x_cust_exists = 'N' OR x_csite_exists = 'N' THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'cust_account_id: '||r_cust_details.cust_account_id||' cust_acct_site_id: '||r_cust_details.cust_acct_site_id);
               --Set batch id and increment counter
               IF (NVL(x_counter,0) = x_batch_size) OR (x_counter = 0) THEN
                   x_batch_id  := xx_sdc_customer_batch_s.nextval;
                   x_counter       := 1;
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' New Batch ID ...' || x_batch_id );
               ELSE
                   x_counter := x_counter + 1;
               END IF;
               x_cnt := x_cnt + 1;
               xx_sdc_cust_pub_tab_typ(x_cnt).publish_batch_id := x_batch_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).record_id := xxintg.xx_sdc_customer_publish_stg_s1.NEXTVAL;
               xx_sdc_cust_pub_tab_typ(x_cnt).cust_account_id := r_cust_details.cust_account_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).cust_acc_site_id := r_cust_details.cust_acct_site_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).publish_time := SYSDATE;
               xx_sdc_cust_pub_tab_typ(x_cnt).publish_system := x_publish_system;
               xx_sdc_cust_pub_tab_typ(x_cnt).target_system := x_target_system;
               xx_sdc_cust_pub_tab_typ(x_cnt).status := x_status_flag;
               xx_sdc_cust_pub_tab_typ(x_cnt).ack_time := NULL;
               xx_sdc_cust_pub_tab_typ(x_cnt).aia_proc_inst_id := NULL;
               xx_sdc_cust_pub_tab_typ(x_cnt).creation_date := SYSDATE;
               xx_sdc_cust_pub_tab_typ(x_cnt).created_by := x_user_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).last_update_date := SYSDATE;
               xx_sdc_cust_pub_tab_typ(x_cnt).last_updated_by := x_user_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).last_update_login := x_login_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).request_id := x_request_id;
               xx_sdc_cust_pub_tab_typ(x_cnt).sfdc_id := NULL;
               xx_sdc_cust_pub_tab_typ(x_cnt).response_message := NULL;
            --END IF;
         END LOOP;

         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Record Count: '||xx_sdc_cust_pub_tab_typ.COUNT);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Insert into Control table');
         --Insert into control table
          IF xx_sdc_cust_pub_tab_typ.COUNT > 0
          THEN
             FORALL i IN 1 .. xx_sdc_cust_pub_tab_typ.COUNT
                INSERT INTO xx_sdc_customer_publish_stg
                     VALUES xx_sdc_cust_pub_tab_typ (i);
          END IF;
         IF x_new_type = 'INITIAL' THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Update program last run date at EMF');
            --Update program last run date at EMF
            UPDATE xx_emf_process_parameters
               SET parameter_value = TO_CHAR(x_date, 'DD-MON-YYYY HH24:MI:SS')
             WHERE parameter_name = 'CUSTOMER_LAST_RUN'
               AND process_id = ( SELECT process_id
                                    FROM xx_emf_process_setup
                                   WHERE process_name = 'XXSFDCOUTBOUNDINTF');
            COMMIT;
         END IF;
      ELSE
         FOR r_republish_rec IN c_republish_rec (p_type, x_date_from, x_date_to )
         LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' Republish Old Batch ID ...' || r_republish_rec.publish_batch_id );
	    x_batch_id  := xx_sdc_customer_batch_s.nextval;
	    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,' Republish New Batch ID ...' || x_batch_id );

            UPDATE xx_sdc_customer_publish_stg
               SET status             = 'NEW',
                   response_message   = NULL, -- Setting message as null
                   sfdc_id            = NULL,
                   last_update_date   = SYSDATE,
                   last_update_login  = x_login_id,
                   last_updated_by    = x_user_id,
                   request_id         = x_request_id,
	           publish_batch_id   = x_batch_id, -- Setting New Batch Id
	           aia_proc_inst_id   = NULL,
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
   WHEN invalid_params THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Please enter correct combination of parameter values');
      p_retcode := 1;
   WHEN OTHERS THEN
      p_retcode := xx_emf_cn_pkg.cn_prc_err;
      p_errbuf := 'Error in fetch_upd_cust_details'||SQLERRM;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'retcode: ' ||p_retcode||' Error: '||p_errbuf);

   END fetch_upd_cust_details;

   --Function to fetch territories last update date
   FUNCTION get_terr_update_date( p_country             VARCHAR2,
                                  p_customer_id         NUMBER,
                                  p_site_number         NUMBER,
                                  p_cust_account        VARCHAR2,
                                  p_county              VARCHAR2,
                                  p_postal_code         VARCHAR2,
                                  p_province            VARCHAR2,
                                  p_state               VARCHAR2,
                                  p_cust_name           VARCHAR2
                                )
   RETURN DATE
   IS
      CURSOR c_fetch_terr
      IS
      SELECT GREATEST(last_update_date) last_update_date
            FROM
              (
               SELECT GREATEST(jtqa.last_update_date,
                               jta.last_update_date,
                               jqua.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
              FROM jtf_terr_values jtva ,
                jtf_terr_qual jtqa ,
                jtf_qual_usgs jqua ,
                jtf_seeded_qual jsqa ,
                apps.jtf_terr jta
              WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
              AND jtqa.qual_usg_id         = jqua.qual_usg_id
              AND jqua.org_id              = jtqa.org_id
              AND jqua.enabled_flag        = 'Y'
              AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
              AND qual_type_usg_id         = -1001
              AND jtqa.terr_id             = jta.terr_id
              AND jsqa.name                = 'Customer Name'
              AND jtva.comparison_operator = '='
              AND jtva.low_value_char_id   = p_customer_id
              UNION
               SELECT GREATEST(jtqa.last_update_date,
                               jta.last_update_date,
                               jqua.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
              FROM jtf_terr_values jtva ,
                jtf_terr_qual jtqa ,
                jtf_qual_usgs jqua ,
                jtf_seeded_qual jsqa ,
                apps.jtf_terr jta
              WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
              AND jtqa.qual_usg_id         = jqua.qual_usg_id
              AND jqua.org_id              = jtqa.org_id
              AND jqua.enabled_flag        = 'Y'
              AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
              AND qual_type_usg_id         = -1001
              AND jtqa.terr_id             = jta.terr_id
              AND jsqa.name                = 'Site Number'
              AND jtva.comparison_operator = '='
              AND jtva.low_value_char_id   = p_site_number
              UNION
               SELECT GREATEST(jtqa.last_update_date,
                               jta.last_update_date,
                               jqua.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
              FROM jtf_terr_values jtva ,
                jtf_terr_qual jtqa ,
                jtf_qual_usgs jqua ,
                jtf_seeded_qual jsqa ,
                apps.jtf_terr jta
              WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
              AND jtqa.qual_usg_id            = jqua.qual_usg_id
              AND jqua.org_id                 = jtqa.org_id
              AND jqua.enabled_flag           = 'Y'
              AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
              AND qual_type_usg_id            = -1001
              AND jtqa.terr_id                = jta.terr_id
              AND jsqa.name                   = 'Customer Account Number'
              AND ( (jtva.comparison_operator = 'LIKE'
              AND p_cust_account LIKE '%'
                || jtva.low_value_char
                || '%')
              OR (jtva.comparison_operator = '='
              AND p_cust_account           = jtva.low_value_char )
              OR (JTVA.COMPARISON_OPERATOR = 'BETWEEN'
              and p_cust_account between jtva.low_value_char and jtva.high_value_char) )
              UNION
               SELECT GREATEST(jtqa.last_update_date,
                               jta.last_update_date,
                               jqua.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
              FROM jtf_terr_values jtva ,
                jtf_terr_qual jtqa ,
                jtf_qual_usgs jqua ,
                jtf_seeded_qual jsqa ,
                apps.jtf_terr jta
              WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
              AND jtqa.qual_usg_id         = jqua.qual_usg_id
              AND jqua.org_id              = jtqa.org_id
              AND jqua.enabled_flag        = 'Y'
              AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
              AND qual_type_usg_id         = -1001
              AND jtqa.terr_id             = jta.terr_id
              AND jsqa.name                = 'County'
              AND jtva.comparison_operator = '='
              AND jtva.low_value_char      = p_county
              UNION
               SELECT GREATEST(jtqa.last_update_date,
                               jta.last_update_date,
                               jqua.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
              FROM jtf_terr_values jtva ,
                jtf_terr_qual jtqa ,
                jtf_qual_usgs jqua ,
                jtf_seeded_qual jsqa ,
                apps.jtf_terr jta
              WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
              AND jtqa.qual_usg_id         = jqua.qual_usg_id
              AND jqua.org_id              = jtqa.org_id
              AND jqua.enabled_flag        = 'Y'
              AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
              AND qual_type_usg_id         = -1001
              AND jtqa.terr_id             = jta.terr_id
              AND jsqa.name                = 'Province'
              AND jtva.comparison_operator = '='
              AND jtva.low_value_char      = p_province
              UNION
               SELECT GREATEST(jtqa.last_update_date,
                               jta.last_update_date,
                               jqua.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
              FROM jtf_terr_values jtva ,
                jtf_terr_qual jtqa ,
                jtf_qual_usgs jqua ,
                jtf_seeded_qual jsqa ,
                apps.jtf_terr jta
              WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
              AND jtqa.qual_usg_id            = jqua.qual_usg_id
              AND jqua.org_id                 = jtqa.org_id
              AND jqua.enabled_flag           = 'Y'
              AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
              AND qual_type_usg_id            = -1001
              AND jtqa.terr_id                = jta.terr_id
              AND jsqa.name                   = 'Postal Code'
              AND ( (jtva.comparison_operator = 'LIKE'
              AND p_postal_code LIKE '%'
                || jtva.low_value_char
                || '%')
              OR (jtva.comparison_operator = '='
              AND p_postal_code            = jtva.low_value_char )
              OR (jtva.comparison_operator = 'BETWEEN'
              AND p_postal_code BETWEEN jtva.low_value_char AND jtva.high_value_char) )
              UNION
               SELECT GREATEST(jtqa.last_update_date,
                               jta.last_update_date,
                               jqua.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
              FROM jtf_terr_values jtva ,
                jtf_terr_qual jtqa ,
                jtf_qual_usgs jqua ,
                jtf_seeded_qual jsqa ,
                apps.jtf_terr jta
              WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
              AND jtqa.qual_usg_id         = jqua.qual_usg_id
              AND jqua.org_id              = jtqa.org_id
              AND jqua.enabled_flag        = 'Y'
              AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
              AND qual_type_usg_id         = -1001
              AND jtqa.terr_id             = jta.terr_id
              AND jsqa.name                = 'State'
              AND jtva.comparison_operator = '='
              AND jtva.low_value_char      = p_state
               UNION
               SELECT GREATEST(jtqa.last_update_date,
                               jqua.last_update_date,
                               jta.last_update_date,
                               jsqa.last_update_date,
                               jtva.last_update_date) last_update_date
	         FROM jtf_terr_values jtva ,
	              jtf_terr_qual jtqa ,
	              jtf_qual_usgs jqua ,
	              jtf_seeded_qual jsqa ,
	              apps.jtf_terr jta
	        WHERE jtva.terr_qual_id = jtqa.terr_qual_id
	          AND jtqa.qual_usg_id    = jqua.qual_usg_id
	          AND jqua.org_id         = jtqa.org_id
	          AND jqua.enabled_flag   = 'Y'
	          AND jqua.seeded_qual_id = jsqa.seeded_qual_id
	          AND qual_type_usg_id    = -1001
	          AND jtqa.terr_id        = jta.terr_id
	          AND jsqa.name           = 'Customer Name Range'
	          -- Condition splited for Ticket  # 2381
	          AND ((jtva.comparison_operator = 'LIKE'
	                 AND p_cust_name LIKE '%'
	                 || jtva.low_value_char
	                 || '%')
	              OR (jtva.comparison_operator = '='
	                 AND p_cust_name    = jtva.low_value_char )
	              OR (jtva.comparison_operator = 'BETWEEN'
	                  AND p_cust_name BETWEEN jtva.low_value_char AND jtva.high_value_char) )
              );

      x_date       DATE;
   BEGIN
      OPEN c_fetch_terr;
      FETCH c_fetch_terr
       INTO x_date;
      CLOSE c_fetch_terr;

      RETURN x_date;
   EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
   END get_terr_update_date;

   --Function to fetch territory flag if territories updated in date range
   FUNCTION get_terr_update_flag( p_country             VARCHAR2,
                                  p_customer_id         NUMBER,
                                  p_site_number         NUMBER,
                                  p_cust_account        VARCHAR2,
                                  p_county              VARCHAR2,
                                  p_postal_code         VARCHAR2,
                                  p_province            VARCHAR2,
                                  p_state               VARCHAR2,
                                  p_cust_name           VARCHAR2,
                                  p_date_from           DATE,
                                  p_date_to             DATE
                                )
   RETURN VARCHAR2
   IS
      x_flag VARCHAR2(10):='N';
   BEGIN
      SELECT 'Y'
        INTO x_flag
        FROM DUAL
       WHERE EXISTS
            (
            SELECT 'X'
              FROM jtf_terr_values jtva ,
                   jtf_terr_qual jtqa ,
                   jtf_qual_usgs jqua ,
                   jtf_seeded_qual jsqa ,
                   apps.jtf_terr jta
              WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
              AND jtqa.qual_usg_id         = jqua.qual_usg_id
              AND jqua.org_id              = jtqa.org_id
              AND jqua.enabled_flag        = 'Y'
              AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
              AND qual_type_usg_id         = -1001
              AND jtqa.terr_id             = jta.terr_id
              AND (  ( jsqa.name                = 'Customer Name'
                       AND jtva.comparison_operator = '='
                       AND jtva.low_value_char_id   = p_customer_id
                      )
                   OR ( jsqa.name                = 'Site Number'
                       AND jtva.comparison_operator = '='
                       AND jtva.low_value_char_id   = p_site_number
                      )
                   OR ( jsqa.name                   = 'Customer Account Number'
                       AND ( (jtva.comparison_operator = 'LIKE'
                              AND p_cust_account LIKE '%'
                              || jtva.low_value_char
                             || '%')
                           OR (jtva.comparison_operator = '='
                              AND p_cust_account           = jtva.low_value_char )
                           OR (JTVA.COMPARISON_OPERATOR = 'BETWEEN'
                               AND p_cust_account between jtva.low_value_char and jtva.high_value_char))
                      )
                   OR ( jsqa.name                = 'County'
                       AND jtva.comparison_operator = '='
                       AND jtva.low_value_char      = p_county
                      )
                   OR ( jsqa.name                = 'Province'
                       AND jtva.comparison_operator = '='
                       AND jtva.low_value_char      = p_province
                      )
                   OR ( jsqa.name                   = 'Postal Code'
                        AND ( (jtva.comparison_operator = 'LIKE'
                        AND p_postal_code LIKE '%'
                            || jtva.low_value_char
                            || '%')
                        OR (jtva.comparison_operator = '='
                            AND p_postal_code            = jtva.low_value_char )
                        OR (jtva.comparison_operator = 'BETWEEN'
                           AND p_postal_code BETWEEN jtva.low_value_char AND jtva.high_value_char))
                       )
                   OR ( jsqa.name                = 'State'
                        AND jtva.comparison_operator = '='
                        AND jtva.low_value_char      = p_state
                      )
                   OR ( jsqa.name           = 'Customer Name Range'
	                 AND ((jtva.comparison_operator = 'LIKE'
	                 AND p_cust_name LIKE '%'
	                    || jtva.low_value_char
	                    || '%')
	                 OR (jtva.comparison_operator = '='
	                     AND p_cust_name    = jtva.low_value_char )
	                 OR (jtva.comparison_operator = 'BETWEEN'
	                     AND p_cust_name BETWEEN jtva.low_value_char AND jtva.high_value_char))
	              )
	         )
	      AND (    jtqa.last_update_date BETWEEN p_date_from AND p_date_to
	            --OR jta.last_update_date BETWEEN p_date_from AND p_date_to
	            OR jqua.last_update_date BETWEEN p_date_from AND p_date_to
	            OR jsqa.last_update_date BETWEEN p_date_from AND p_date_to
	            OR jtva.last_update_date BETWEEN p_date_from AND p_date_to
	          )
	    );
      RETURN x_flag;
   EXCEPTION
      WHEN OTHERS THEN
         x_flag := 'N';
         RETURN x_flag;
   END get_terr_update_flag;
END xx_ar_sfdc_cust_outbound_pkg;
/
