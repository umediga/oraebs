DROP PACKAGE BODY APPS.XX_PO_SR_LOAD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PO_SR_LOAD_PKG" 
IS
   ----------------------------------------------------------------------
   /*
    Created By    : Yogesh
    Creation Date : 26-MAY-2013
    File Name     : xxposrload.pkb
    Description   : This script creates the package body of the object
                    xx_po_sr_load_pkg
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    26-May-2013 Yogesh                Initial Version
    03-Feb-2014 ABHARGAVA             If ASL Created is Global then Sourcing Rule will be ALL ORGS
    20-Mar-2014 ABHARGAVA             If Sourcing Rule already exist then Update it for different Vendor Site
   */
    ----------------------------------------------------------------------


    PROCEDURE sr_insert_upd_stg( x_error_code    OUT   NUMBER
                                ,x_error_msg     OUT   VARCHAR2
                                ,p_org_id        IN    NUMBER)
    IS
       CURSOR  c_sr_name
       IS

       SELECT q.*
         FROM (SELECT   SUBSTR (aps.vendor_name, 1, 15) sr_name,
                        --owning_organization_id org_id,
                        -- Above statement commented since we need to set sourcing rule as Global or Local based on USING ORG
                        using_organization_id org_id  ,
                        aps.vendor_name,
                        pasl.vendor_id,
                        pasl.vendor_site_id
                   FROM po_approved_supplier_list pasl,
                        ap_suppliers aps
                  WHERE owning_organization_id =
                                              NVL (p_org_id, owning_organization_id)
                    AND pasl.vendor_id = aps.vendor_id
                    AND nvl(pasl.DISABLE_FLAG,'N') = 'N'
                    AND pasl.vendor_site_id is not NULL
               GROUP BY aps.vendor_name,
                        using_organization_id,
                        pasl.vendor_id,
                        pasl.vendor_site_id) q
        WHERE NOT EXISTS (
                 SELECT 1
                   FROM mrp_sourcing_rules msr,
                        mrp_sr_receipt_org msro,
                        mrp_sr_source_org  msso
                  WHERE nvl(msr.organization_id,q.org_id) = q.org_id
                    AND msr.sourcing_rule_id=msro.sourcing_rule_id
                    AND msso.sr_receipt_id = msro.sr_receipt_id
                    AND msr.sourcing_rule_name not like '%DNU'
                    AND msso.vendor_id = q.vendor_id
                    AND msso.vendor_site_id = q.vendor_site_id);

       CURSOR  c_multiple_sr_name
       IS
       SELECT sr_name,
          organization_id,
          COUNT (1)
     FROM xx_po_sr_load_stg
    WHERE request_id =xx_emf_pkg.G_REQUEST_ID
        GROUP BY sr_name, organization_id
       HAVING COUNT (1) > 1;

       CURSOR  c_sr_rec (p_sr_name VARCHAR2)
       IS
       SELECT record_id,
              sr_name,
              vendor_id,
              vendor_site_id,
              organization_id
         FROM xx_po_sr_load_stg
        WHERE request_id =xx_emf_pkg.G_REQUEST_ID
          AND sr_name = p_sr_name;

       x_data_rec                  G_XX_PO_SR_LOAD_TAB_TYPE;
       x_cntr                      NUMBER := 0;
       x_suffix_ctr                NUMBER := 0;
       x_suffix_intg               VARCHAR2(3);
    BEGIN
       FOR r_sr_list IN c_sr_name LOOP
           BEGIN
              x_cntr := x_cntr + 1;
              x_data_rec(x_cntr).record_id       :=xx_po_sr_load_s.nextval;
              x_data_rec(x_cntr).sr_name         :=r_sr_list.sr_name;
              x_data_rec(x_cntr).organization_id :=r_sr_list.org_id;
              x_data_rec(x_cntr).description     :=r_sr_list.vendor_name;
              x_data_rec(x_cntr).vendor_id       :=r_sr_list.vendor_id;
              x_data_rec(x_cntr).vendor_site_id  :=r_sr_list.vendor_site_id;
           EXCEPTION WHEN OTHERS THEN
            x_error_msg := x_error_msg || SQLERRM;
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_HIGH,'Error While Reading Valid ASL ' || x_cntr ||SQLERRM);
            EXIT;
           END;
       END LOOP;

       FOR i in 1..x_data_rec.count
        LOOP
          BEGIN
             INSERT INTO XX_PO_SR_LOAD_STG
              ( record_id
           ,request_id
           ,sr_name
           ,organization_id
           ,description
           ,vendor_id
           ,vendor_site_id
           ,process_code
           ,error_code
           ,error_message
           ,created_by
           ,creation_date
           ,last_update_date
           ,last_updated_by
           ,last_update_login
           ,attribute1
           ,attribute2
           ,attribute3
           ,attribute4
           ,attribute5)
          VALUES
           ( x_data_rec(i).record_id
            ,xx_emf_pkg.G_REQUEST_ID
            ,x_data_rec(i).sr_name
            ,x_data_rec(i).organization_id
            ,x_data_rec(i).description
            ,x_data_rec(i).vendor_id
            ,x_data_rec(i).vendor_site_id
            ,xx_emf_cn_pkg.CN_NEW
            ,xx_emf_cn_pkg.CN_NULL
            ,NULL
            ,FND_GLOBAL.USER_ID                         -- created_by
                ,SYSDATE                                    -- creation_date
                ,SYSDATE                                    -- last_update_date
                ,FND_GLOBAL.USER_ID                         -- last_updated_by
                ,FND_PROFILE.VALUE (xx_emf_cn_pkg.CN_LOGIN_ID)
                ,NULL
                ,NULL
                ,NULL
                ,NULL
                ,NULL);
          EXCEPTION
          WHEN OTHERS THEN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while Inserting the data into Stage: ' ||SQLERRM);
                xx_emf_pkg.error(xx_emf_cn_pkg.CN_LOW, xx_emf_cn_pkg.CN_TECH_ERROR, xx_emf_cn_pkg.CN_EXP_UNHAND);
                x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
                   x_error_msg := 'Error Inserting the data into Stage: ' ||SQLERRM;
                   rollback;
          END;
       END LOOP;

       FOR r_mul_sr_name in c_multiple_sr_name
       LOOP
           x_suffix_ctr:=1;
           FOR r_sr_rec in c_sr_rec(r_mul_sr_name.sr_name)
           LOOP
               IF x_suffix_ctr < 10
               THEN
                  x_suffix_intg:=lpad(to_char(x_suffix_ctr),2,'0');
               ELSE
                  x_suffix_intg:= to_char(x_suffix_ctr);
               END IF;
               BEGIN
                  UPDATE xx_po_sr_load_stg
                     SET sr_name = r_sr_rec.sr_name||x_suffix_intg
                   WHERE sr_name = r_sr_rec.sr_name
                     AND record_id = r_sr_rec.record_id
                     AND vendor_id = r_sr_rec.vendor_id
                     AND vendor_site_id = r_sr_rec.vendor_site_id
                     AND organization_id= r_sr_rec.organization_id;
               EXCEPTION WHEN OTHERS
                    THEN
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error while updating the Suffix for SR Name with same 15 charaters: ' ||SQLERRM);
                      /*UPDATE XX_PO_SR_LOAD_STG
                         SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                             error_code = xx_emf_cn_pkg.CN_REC_ERR
                       WHERE sr_name = r_sr_rec.sr_name
                         AND record_id = r_sr_rec.record_id
                         AND vendor_id = r_sr_rec.vendor_id;
                       x_error_msg := x_error_msg || SQLERRM;
                   x_error_code := xx_emf_cn_pkg.cn_rec_err;*/
                   rollback;
               END;
               x_suffix_ctr:=x_suffix_ctr+1;
           END LOOP;
       END LOOP;

       Commit;
    END sr_insert_upd_stg;

    ----------------------------------------------------------------------

   PROCEDURE update_record_count
   IS
      CURSOR c_get_total_cnt IS
      SELECT COUNT (1) total_count
        FROM xx_po_sr_load_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID;

      x_total_cnt NUMBER;

      CURSOR c_get_error_cnt IS
      SELECT SUM(error_count)
        FROM (
      SELECT COUNT (1) error_count
        FROM xx_po_sr_load_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

       x_error_cnt NUMBER;

      CURSOR c_get_warning_cnt IS
      SELECT COUNT (1) warn_count
        FROM xx_po_sr_load_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

       x_warn_cnt NUMBER;

      CURSOR c_get_success_cnt IS
      SELECT COUNT (1) success_count
        FROM xx_po_sr_load_stg
       WHERE request_id = xx_emf_pkg.G_REQUEST_ID
         AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
         AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

      x_success_cnt NUMBER;

   BEGIN
      OPEN c_get_total_cnt;
      FETCH c_get_total_cnt INTO x_total_cnt;
      CLOSE c_get_total_cnt;

      OPEN c_get_error_cnt;
      FETCH c_get_error_cnt INTO x_error_cnt;
      CLOSE c_get_error_cnt;

      OPEN c_get_warning_cnt;
      FETCH c_get_warning_cnt INTO x_warn_cnt;
      CLOSE c_get_warning_cnt;

      OPEN c_get_success_cnt;
      FETCH c_get_success_cnt INTO x_success_cnt;
      CLOSE c_get_success_cnt;

      xx_emf_pkg.update_recs_cnt
        ( p_total_recs_cnt   => x_total_cnt,
          p_success_recs_cnt => x_success_cnt,
          p_warning_recs_cnt => x_warn_cnt,
          p_error_recs_cnt   => x_error_cnt
        );

   END update_record_count;

    ----------------------------------------------------------------------

    PROCEDURE create_sourcing_rule( x_error_code    OUT   NUMBER
                                   ,x_error_msg     OUT   VARCHAR2
                                   ,p_org_id        IN    NUMBER)
    IS
       CURSOR  c_sr_create
       IS
       SELECT *
         FROM xx_po_sr_load_stg
        WHERE request_id = xx_emf_pkg.G_REQUEST_ID;

      /* CURSOR c_sup_site_info ( V_ORG_ID      NUMBER
                               ,V_VENDOR_ID   NUMBER)
       IS
       SELECT *
         FROM ap_supplier_sites_all assa,
              org_organization_definitions ood
        WHERE assa.org_id = ood.operating_unit
          AND ood.organization_id = v_org_id
          AND assa.vendor_id= v_vendor_id;    */

       x_sr_type                     VARCHAR2(200);
       l_org_code                    VARCHAR2(100);
       x_sr_status                   NUMBER;
       x_rank                        NUMBER;
       x_source_type                 VARCHAR2(200);
       x_sr_type_id                  NUMBER;
       x_source_type_id              NUMBER;
       x_no_sup_sites                NUMBER;
       x_alloc_ptg                   NUMBER:=100;
       x_loop_ctr                    NUMBER:=0;
       x_return_status               VARCHAR2 (1);
       x_msg_count                   NUMBER:= 0;
       x_msg_data                    VARCHAR2 (1000);
       x_msg_index_out               NUMBER;
       x_count                       NUMBER;
       x_err_count                   NUMBER:= 0;
       x_sourcing_rule_rec           mrp_sourcing_rule_pub.sourcing_rule_rec_type;
       x_sourcing_rule_val_rec       mrp_sourcing_rule_pub.sourcing_rule_val_rec_type;
       x_receiving_org_tbl           mrp_sourcing_rule_pub.receiving_org_tbl_type;
       x_receiving_org_val_tbl       mrp_sourcing_rule_pub.receiving_org_val_tbl_type;
       x_shipping_org_tbl            mrp_sourcing_rule_pub.shipping_org_tbl_type;
       x_shipping_org_val_tbl        mrp_sourcing_rule_pub.shipping_org_val_tbl_type;
       x_sourcing_rule_rec_out       mrp_sourcing_rule_pub.sourcing_rule_rec_type;
       x_sourcing_rule_val_rec_out   mrp_sourcing_rule_pub.sourcing_rule_val_rec_type;
       x_receiving_org_tbl_out       mrp_sourcing_rule_pub.receiving_org_tbl_type;
       x_receiving_org_val_tbl_out   mrp_sourcing_rule_pub.receiving_org_val_tbl_type;
       x_shipping_org_tbl_out        mrp_sourcing_rule_pub.shipping_org_tbl_type;
       x_shipping_org_val_tbl_out    mrp_sourcing_rule_pub.shipping_org_val_tbl_type;
       l_src_id                      NUMBER;
       l_sr_receipt_id               NUMBER;
    BEGIN
       xx_intg_common_pkg.get_process_param_value( 'XXPOSRLOAD_CP'
                                              ,'MRP_SOURCING_RULE_TYPE'
                                              ,x_sr_type
                                          );
       IF x_sr_type IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Sourcing Rule Type not Defined in Process Setput');
          return;
       END IF;

       xx_intg_common_pkg.get_process_param_value( 'XXPOSRLOAD_CP'
                                              ,'SORCING_RULE_STATUS'
                                              ,x_sr_status
                                          );
       IF x_sr_status IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Sourcing Rule Status not Defined in Process Setput');
          return;
       END IF;

       xx_intg_common_pkg.get_process_param_value( 'XXPOSRLOAD_CP'
                                              ,'RANK'
                                              ,x_rank
                                          );
       IF x_rank IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Rank Defined in Process Setput');
          return;
       END IF;

       xx_intg_common_pkg.get_process_param_value( 'XXPOSRLOAD_CP'
                                              ,'MRP_SOURCE_TYPE'
                                              ,x_source_type
                                          );
       IF x_source_type IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Source type not Defined in Process Setput');
          return;
       END IF;

       BEGIN
          SELECT lookup_code
            INTO x_sr_type_id
            FROM mfg_lookups
           WHERE lookup_type = 'MRP_SOURCING_RULE_TYPE'
             AND meaning = x_sr_type;
       EXCEPTION WHEN OTHERS THEN
         x_sr_type_id := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in Fetching SR Type ID from MFG Lookup');
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         return;
       END;

       BEGIN
          SELECT lookup_code
            INTO  x_source_type_id
            FROM mfg_lookups
           WHERE lookup_type = 'MRP_SOURCE_TYPE'
             AND meaning = x_source_type;
       EXCEPTION WHEN OTHERS
       THEN
         x_sr_type_id := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in Fetching Shipping Org Source Type ID from MFG Lookup');
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         return;
       END;
       --------------------------------------
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Calling API for Sourcing Rule Creation');
       --------------------------------------
       FOR r_sr_create in c_sr_create
       LOOP
           x_sourcing_rule_rec := mrp_sourcing_rule_pub.g_miss_sourcing_rule_rec;
           -- Added logic to check if ASL is Global then ALL ORGS Sourcing Rule should be created
           IF r_sr_create.organization_id = -1 THEN
              x_sourcing_rule_rec.organization_id := NULL;
           ELSE
              x_sourcing_rule_rec.organization_id := r_sr_create.organization_id;
           END IF;

           -- Logic Added to not create sourcing rule but update the same for different Vendor Site
           BEGIN
                select msr.sourcing_rule_id, sr_receipt_id
                into l_src_id , l_sr_receipt_id
                from MRP_SOURCING_RULES msr
                    ,MRP_SR_RECEIPT_ORG msro
                where SOURCING_RULE_NAME = r_sr_create.sr_name
                AND msr.SOURCING_RULE_ID = msro.SOURCING_RULE_ID
                AND organization_id is NULL;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              l_src_id := NULL;
              l_sr_receipt_id := NULL;
           END;


           x_sourcing_rule_rec.sourcing_rule_name := r_sr_create.sr_name;                --SR Name
           x_sourcing_rule_rec.description := r_sr_create.description;    --SR Description/Vendor Full Name

           x_sourcing_rule_rec.planning_active := 1;                       -- Active?
           x_sourcing_rule_rec.status := x_sr_status;                      -- Update New record
           x_sourcing_rule_rec.sourcing_rule_type := x_sr_type_id;            -- 1:Sourcing Rule

           IF l_src_id IS NULL THEN
             x_sourcing_rule_rec.operation := 'CREATE';
           ELSE
             x_sourcing_rule_rec.operation := 'UPDATE';
             x_sourcing_rule_rec.sourcing_rule_id  := l_src_id;
           END IF;

           x_receiving_org_tbl := mrp_sourcing_rule_pub.g_miss_receiving_org_tbl;
           x_shipping_org_tbl := mrp_sourcing_rule_pub.g_miss_shipping_org_tbl;

           IF l_sr_receipt_id IS NULL THEN
               x_receiving_org_tbl (1).effective_date := TRUNC (SYSDATE);

               -- Added logic to check if ASL is Global then ALL ORGS Sourcing Rule should be created
               IF r_sr_create.organization_id = -1 THEN
                  x_receiving_org_tbl (1).receipt_organization_id := NULL;
               ELSE
                  x_receiving_org_tbl (1).receipt_organization_id := r_sr_create.organization_id;
               END IF;

               x_receiving_org_tbl (1).operation := 'CREATE';         -- Create or Update
            ELSE
               x_receiving_org_tbl (1).operation := 'UPDATE';         -- Create or Update
               x_receiving_org_tbl (1).sr_receipt_id := l_sr_receipt_id;
            END IF;
           x_shipping_org_tbl (1).RANK := x_rank;
           x_shipping_org_tbl (1).allocation_percent := x_alloc_ptg;        -- Allocation 100
           x_shipping_org_tbl (1).source_type := x_source_type_id;                       -- BUY FROM
           x_shipping_org_tbl (1).vendor_id := r_sr_create.vendor_id;
           x_shipping_org_tbl (1).vendor_Site_Id:=r_sr_create.vendor_site_id;
           x_shipping_org_tbl (1).receiving_org_index := 1;
           x_shipping_org_tbl (1).operation := 'CREATE';


           mrp_sourcing_rule_pub.process_sourcing_rule
                                                     ( p_api_version_number         => 1.0
                                                      ,p_init_msg_list              => fnd_api.g_true
                                                      ,p_commit                     => fnd_api.g_true
                                                      ,x_return_status              => x_return_status
                                                      ,x_msg_count                  => x_msg_count
                                                      ,x_msg_data                   => x_msg_data
                                                      ,p_sourcing_rule_rec          => x_sourcing_rule_rec
                                                      ,p_sourcing_rule_val_rec      => x_sourcing_rule_val_rec
                                                      ,p_receiving_org_tbl          => x_receiving_org_tbl
                                                      ,p_receiving_org_val_tbl      => x_receiving_org_val_tbl
                                                      ,p_shipping_org_tbl           => x_shipping_org_tbl
                                                      ,p_shipping_org_val_tbl       => x_shipping_org_val_tbl
                                                      ,x_sourcing_rule_rec          => x_sourcing_rule_rec_out
                                                      ,x_sourcing_rule_val_rec      => x_sourcing_rule_val_rec_out
                                                      ,x_receiving_org_tbl          => x_receiving_org_tbl_out
                                                      ,x_receiving_org_val_tbl      => x_receiving_org_val_tbl_out
                                                      ,x_shipping_org_tbl           => x_shipping_org_tbl_out
                                                      ,x_shipping_org_val_tbl       => x_shipping_org_val_tbl_out
                                                     );
           IF x_return_status != fnd_api.g_ret_sts_success
           THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'API Failed Creating the SR : '||r_sr_create.sr_name||'->'||r_sr_create.description);
                x_error_msg := null;
             x_error_code := xx_emf_cn_pkg.cn_rec_err;
             IF x_msg_count > 0
               THEN
                  FOR l_index IN 1 .. x_msg_count
                  LOOP
                     x_msg_data :=
                        fnd_msg_pub.get (p_msg_index      => l_index,
                                         p_encoded        => fnd_api.g_false
                                        );
                     x_error_msg := x_error_msg || x_msg_data;
                          END LOOP;
                 END IF;
             xx_emf_pkg.error (p_severity                 => xx_emf_cn_pkg.cn_low,
                           p_category                 => 'SR_LOAD_ERROR',
                           p_error_text               =>  x_error_msg,
                           p_record_identifier_1      => r_sr_create.record_id,
                           p_record_identifier_2      => r_sr_create.sr_name,
                           p_record_identifier_3      => r_sr_create.organization_id
                                  );
                 UPDATE XX_PO_SR_LOAD_STG
                    SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                        error_code = xx_emf_cn_pkg.CN_REC_ERR,
                        error_message = SUBSTR (x_error_msg,1,3999)
                  WHERE sr_name = r_sr_create.sr_name
                    AND record_id = r_sr_create.record_id
                    AND vendor_id = r_sr_create.vendor_id
                    AND vendor_site_id = r_sr_create.vendor_site_id
                    AND organization_id= r_sr_create.organization_id;
             continue;
       ELSE
                 UPDATE XX_PO_SR_LOAD_STG
                    SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                        error_code = xx_emf_cn_pkg.CN_SUCCESS
                  WHERE sr_name = r_sr_create.sr_name
                    AND record_id = r_sr_create.record_id
                    AND vendor_id = r_sr_create.vendor_id
                    AND vendor_site_id = r_sr_create.vendor_site_id
                    AND organization_id= r_sr_create.organization_id;
           END IF;
       END LOOP;
    EXCEPTION WHEN OTHERS THEN
       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
       x_error_msg := x_error_msg || SQLERRM;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in procedure: create_sourcing_rule -> '||x_error_msg);
    END create_sourcing_rule;

    ----------------------------------------------------------------------

    PROCEDURE main_prc ( p_errbuf        OUT VARCHAR2
                        ,p_retcode       OUT VARCHAR2
                        ,p_org_id        IN  NUMBER)
    IS
       x_error_code                   NUMBER;
       x_error_msg                    VARCHAR2(250);

    BEGIN
       p_retcode := xx_emf_cn_pkg.CN_SUCCESS;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Before Setting Environment');

       -- Emf Env initialization
       x_error_code := xx_emf_pkg.set_env;
       -- ------------------------------------ --
       -- Setting Global Variables
       --x_error_code := xx_global_var;
       -- ------------------------------------ --
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'sr_insert_upd_stg');

       sr_insert_upd_stg( x_error_code
                          ,x_error_msg
                          ,p_org_id);
       IF x_error_code = xx_emf_cn_pkg.cn_rec_err
       THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'sr_insert_upd_stg failed');
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_error_msg);
       END IF;

       create_sourcing_rule( x_error_code
                          ,x_error_msg
                          ,p_org_id);
       IF x_error_code = xx_emf_cn_pkg.cn_rec_err
       THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'create_sourcing_rule failed');
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_error_msg);
       END IF;

       -- update record count
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling Procedure to display Processing Summary');
       update_record_count;

       -- emf report
       xx_emf_pkg.create_report;

    EXCEPTION WHEN OTHERS THEN
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in main procedure');
       x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
       x_error_msg := x_error_msg || SQLERRM;
       xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in main procedure ->'||x_error_msg);
    END main_prc;
END xx_po_sr_load_pkg;
/
