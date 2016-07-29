DROP PACKAGE BODY APPS.XX_SDC_OIC_SP_DET_OUT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_OIC_SP_DET_OUT_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 04-APR-2014
 File Name     : XXSDCOICSPOUTWS.pkb
 Description   : This script creates the body of the package
                 xx_sdc_oic_sp_det_out_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-APR-2014 Sharath Babu          Initial Development
 */
----------------------------------------------------------------------
   x_user_id          NUMBER       := FND_GLOBAL.USER_ID;
   x_login_id         NUMBER       := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER       := FND_GLOBAL.CONC_REQUEST_ID;

   PROCEDURE xx_get_oic_details (
         p_mode                 IN              VARCHAR2,
         p_publish_batch_id     IN              NUMBER,
         p_sale_person_num_ls   IN              xx_sdc_oic_sp_det_ls_ot_tabtyp,
         x_output_oic_det       OUT NOCOPY      xx_sdc_oic_sp_det_ot_tabtyp,
         x_return_status        OUT NOCOPY      VARCHAR2,
         x_return_message       OUT NOCOPY      VARCHAR2
   )
   IS
     CURSOR c_oic_sp_details (cp_publish_batch_id NUMBER)
      IS
         SELECT pub.record_id
               ,pub.publish_batch_id
               ,oicd.sales_person_num
               ,oicd.salesrep_id
               ,oicd.quota_period
               ,oicd.pay_period_id
               ,oicd.quota_name
               ,oicd.quota_id
               ,oicd.comm_ptd
               ,oicd.bonus_ptd
               ,oicd.target_amount
               ,oicd.currency
               ,oicd.org_id
               ,pub.publish_system source_system
               ,pub.target_system
               ,SYSDATE
               ,x_user_id
               ,SYSDATE
               ,x_user_id
               ,x_login_id
               ,x_request_id
           FROM xx_sdc_oic_sp_details_v oicd,
                (SELECT DISTINCT salesrep_id,pay_period_id,quota_id,publish_batch_id,record_id,target_system,publish_system
                            FROM xx_sdc_oic_sp_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id
                             AND nvl(status, 'NEW') <> 'SUCCESS' ) pub
          WHERE oicd.quota_id = pub.quota_id
            AND oicd.pay_period_id = pub.pay_period_id
            AND oicd.salesrep_id = pub.salesrep_id;


     CURSOR c_cust_account_list_info (cp_sale_pnum       NUMBER,
                                      cp_record_id       NUMBER)
      IS
         SELECT pub.record_id
               ,pub.publish_batch_id
               ,oicd.sales_person_num
               ,oicd.salesrep_id
               ,oicd.quota_period
               ,oicd.pay_period_id
               ,oicd.quota_name
               ,oicd.quota_id
               ,oicd.comm_ptd
               ,oicd.bonus_ptd
               ,oicd.target_amount
               ,oicd.currency
               ,oicd.org_id
               ,pub.publish_system source_system
               ,pub.target_system
               ,SYSDATE
               ,x_user_id
               ,SYSDATE
               ,x_user_id
               ,x_login_id
               ,x_request_id
         FROM xx_sdc_oic_sp_details_v oicd,
                 (SELECT DISTINCT salesrep_id,pay_period_id,quota_id,publish_batch_id,record_id,target_system,publish_system
                             FROM xx_sdc_oic_sp_publish_stg
                            WHERE record_id = cp_record_id
                              AND sales_person_num = cp_sale_pnum
                              AND nvl(status, 'NEW') <> 'SUCCESS') pub
          WHERE oicd.quota_id = pub.quota_id
            AND oicd.pay_period_id = pub.pay_period_id
            AND oicd.salesrep_id = pub.salesrep_id;


      x_publish_batch_id       NUMBER               := NULL;
      e_incorrect_mode         EXCEPTION;

      TYPE sdc_oic_det_tbl IS TABLE OF xx_sdc_oic_sp_details_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      xx_sdc_oic_det_tbl             sdc_oic_det_tbl;

   BEGIN
         mo_global.set_policy_context('S',82);
         x_publish_batch_id := p_publish_batch_id;

        IF p_mode IS NULL OR p_mode NOT IN ('BATCH', 'LIST')
         THEN
            RAISE e_incorrect_mode;
         END IF;

         IF p_mode = 'BATCH'
         THEN
            OPEN c_oic_sp_details (x_publish_batch_id);
            FETCH c_oic_sp_details
            BULK COLLECT INTO xx_sdc_oic_det_tbl;

            CLOSE c_oic_sp_details;

            IF xx_sdc_oic_det_tbl.COUNT > 0
            THEN
               FORALL i_rec IN 1 .. xx_sdc_oic_det_tbl.COUNT
                  INSERT INTO xx_sdc_oic_sp_details_stg
                       VALUES xx_sdc_oic_det_tbl (i_rec);
            END IF;

                 SELECT  CAST
                             (MULTISET(SELECT pub.record_id
                                             ,pub.publish_batch_id
                                             ,oicd.sales_person_num
                                             ,oicd.salesrep_id
                                             ,oicd.quota_period
                                             ,oicd.pay_period_id
                                             ,oicd.quota_name
                                             ,oicd.quota_id
                                             ,NVL(oicd.comm_ptd,0)
                                             ,NVL(oicd.bonus_ptd,0)
                                             ,NVL(oicd.target_amount,0)
                                             ,oicd.currency
                                             ,oicd.org_id
                                             ,pub.publish_system source_system
                                             ,pub.target_system
                                             ,SYSDATE
                                             ,x_user_id
                                             ,SYSDATE
                                             ,x_user_id
                                             ,x_login_id
                                             ,x_request_id
                                             ,NULL attribute1
                                             ,NULL attribute2
                                             ,NULL attribute3
                                             ,NULL attribute4
                                         FROM xx_sdc_oic_sp_details_v oicd,
                                              (SELECT DISTINCT salesrep_id,pay_period_id,quota_id,publish_batch_id,record_id,target_system,publish_system
                                                 FROM xx_sdc_oic_sp_publish_stg
                                                WHERE publish_batch_id = p_publish_batch_id
                                                  AND nvl(status, 'NEW') <> 'SUCCESS' ) pub
                                        WHERE oicd.quota_id = pub.quota_id
                                          AND oicd.pay_period_id = pub.pay_period_id
                                          AND oicd.salesrep_id = pub.salesrep_id ) AS xx_sdc_oic_sp_det_ot_tabtyp
                                   )
                    INTO x_output_oic_det
                    FROM dual;

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


      END xx_get_oic_details;
END xx_sdc_oic_sp_det_out_pkg;
/
