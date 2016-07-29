DROP PACKAGE BODY APPS.XX_PO_SR_ASSIGN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PO_SR_ASSIGN_PKG" 
IS
   ----------------------------------------------------------------------
   /*
    Created By    : Yogesh
    Creation Date : 29-APR-2013
    File Name     : xxposrassign.pkb
    Description   : This script creates the package body of the object
                    xx_po_sr_assign_pkg
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    29-Apr-2013 Yogesh               Initial Version
    11-Feb-2014 ABhargava            Changed to Pick Organization from Owning Org ID from ASL 
   */
    ----------------------------------------------------------------------
    
    FUNCTION xx_global_var
    RETURN NUMBER
    IS
      x_error_code                NUMBER := xx_emf_cn_pkg.cn_success; 
      x_assnt_type                VARCHAR2(100);
      x_sr_type                   VARCHAR2(100);
      x_assnt_set                 VARCHAR2(100);
    BEGIN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Intializing the Global Variables' );
       
       xx_intg_common_pkg.get_process_param_value( 'XXPOSRASSIGN_CP'
                                              ,'P_ASSIGNMENT_TYPE'
                                              ,x_assnt_type
                                          );       
       IF x_assnt_type IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Assignment Type not Defined in Process Setput');
       END IF;

       xx_intg_common_pkg.get_process_param_value( 'XXPOSRASSIGN_CP'
                                              ,'P_SOURCING_RULE_TYPE'
                                              ,x_sr_type
                                          );       
       IF x_sr_type IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Sourcing Rule Type not Defined in Process Setput');
       END IF;      
       
       xx_intg_common_pkg.get_process_param_value( 'XXPOSRASSIGN_CP'
                                              ,'P_MRP_ASSIGNMENT_SET'
                                              ,x_assnt_set
                                          );       
       IF x_assnt_set IS NULL THEN
          xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'MRP Assignment Set not Defined in Process Setput');
       END IF;       
       
       BEGIN
          SELECT lookup_code
            INTO g_assignment_type_id
            FROM fnd_lookup_values
           WHERE lookup_type = 'MRP_ASSIGNMENT_TYPE'
             AND meaning = x_assnt_type
             AND LANGUAGE = 'US';
       EXCEPTION WHEN OTHERS THEN
         g_assignment_type_id := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in Fetching Assignment Type ID from FND Lookup');
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         RETURN x_error_code;
       END;  
       
       BEGIN
          SELECT lookup_code
            INTO g_sr_type_id
            FROM fnd_lookup_values
           WHERE lookup_type = 'MRP_SOURCING_RULE_TYPE'
             AND meaning = x_sr_type
             AND LANGUAGE = 'US';
       EXCEPTION WHEN OTHERS THEN
         g_assignment_type_id := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in Fetching Sourcing Rule Type ID from FND Lookup');
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         RETURN x_error_code;
       END;  
       
       BEGIN
          SELECT assignment_set_id
            INTO g_assignment_set_id 
            FROM mrp_assignment_sets
           WHERE assignment_set_name = x_assnt_set;
       EXCEPTION WHEN OTHERS THEN
         g_assignment_set_id  := NULL;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in MRP Assignment Set Id ID');
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         RETURN x_error_code;
       END;        
       RETURN x_error_code;
    END xx_global_var;  

    ----------------------------------------------------------------------    
    
    PROCEDURE item_rule_insert_stg( x_error_code    OUT   NUMBER
                                   ,x_error_msg     OUT   VARCHAR2
                                   ,p_org_id        IN    NUMBER)
    IS    
       CURSOR  c_item_sr_list
       IS
       -- changed query on 11th FEB for Logic to pick Org from Owing Organization ID
       SELECT *
      FROM (SELECT q.*, msr.sourcing_rule_name, msr.sourcing_rule_id
              FROM (SELECT pasl.item_id, 
                           pasl.owning_organization_id,
                           pasl.vendor_id, 
                           SUBSTR (aps.vendor_name, 1,15) sr_name
                      FROM po_approved_supplier_list pasl, ap_suppliers aps
                     WHERE NOT EXISTS (
                              SELECT 1
                                FROM mrp_sr_assignments msa,
                                     fnd_lookup_values flv1,
                                     fnd_lookup_values flv2
                               WHERE nvl(msa.organization_id,pasl.owning_organization_id) = pasl.owning_organization_id
                                 AND msa.inventory_item_id = pasl.item_id
                                 AND msa.assignment_type = g_assignment_type_id
                                 AND msa.assignment_set_id=g_assignment_set_id--flv1.lookup_code
                                 AND msa.sourcing_rule_type = g_sr_type_id)
                       AND aps.vendor_id = pasl.vendor_id
                       AND nvl(pasl.disable_flag,'N') = 'N'
                       AND pasl.using_organization_id = -1) q,
                   mrp_sourcing_rules msr
             WHERE msr.sourcing_rule_name = q.sr_name
               AND nvl(msr.organization_id,q.owning_organization_id) = q.owning_organization_id
               AND q.owning_organization_id = p_org_id) q1
     WHERE NOT EXISTS (
              SELECT 1
                FROM xxintg.xx_po_sr_assign_stg sas
               WHERE sas.item_id = q1.item_id
                 AND sas.sr_id = q1.sourcing_rule_id
                    AND sas.organization_id = q1.owning_organization_id
                    AND sas.assignment_type_id = g_assignment_type_id);   
                        
       x_data_rec                  G_XX_PO_SR_ASSIGN_TAB_TYPE;      
       x_cntr                      NUMBER := 0;
    
    BEGIN
       FOR r_item_sr_list IN c_item_sr_list LOOP
           BEGIN
              x_cntr := x_cntr + 1;
              x_data_rec(x_cntr).item_id         :=r_item_sr_list.item_id;
              -- Changed to Owning Organization ID on 11th FEB 
              x_data_rec(x_cntr).organization_id :=r_item_sr_list.owning_organization_id;
              x_data_rec(x_cntr).vendor_id       :=r_item_sr_list.vendor_id;
              x_data_rec(x_cntr).sr_id           :=r_item_sr_list.sourcing_rule_id;
              x_data_rec(x_cntr).sr_name         :=r_item_sr_list.sourcing_rule_name;
           EXCEPTION WHEN OTHERS THEN
            x_error_msg := x_error_msg || SQLERRM;
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_HIGH,'Error While Reading Valid Items ' || x_cntr ||SQLERRM);
            EXIT;
           END;
       END LOOP;    
       
       FOR i in 1..x_data_rec.count 
        LOOP
          BEGIN
             INSERT INTO XX_PO_SR_ASSIGN_STG
              ( request_id        
            ,item_id           
            ,organization_id   
            ,vendor_id         
            ,sr_id             
            ,sr_name           
            ,assignment_type_id
            ,sr_type_id        
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
           ( xx_emf_pkg.G_REQUEST_ID
            ,x_data_rec(i).item_id
            ,x_data_rec(i).organization_id
            ,x_data_rec(i).vendor_id
            ,x_data_rec(i).sr_id
            ,x_data_rec(i).sr_name
            ,g_assignment_type_id
            ,g_sr_type_id
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
                   x_error_msg := 'Error while reading File Inserting the data into Stage: ' ||SQLERRM;
          END;     
       END LOOP;
       Commit;
    END item_rule_insert_stg;         
    
   
        ----------------------------------------------------------------------    
        
       PROCEDURE update_record_count
       IS
          CURSOR c_get_total_cnt IS
          SELECT COUNT (1) total_count
            FROM xx_po_sr_assign_stg
           WHERE request_id = xx_emf_pkg.G_REQUEST_ID;
    
          x_total_cnt NUMBER;
    
          CURSOR c_get_error_cnt IS
          SELECT SUM(error_count)
            FROM (
          SELECT COUNT (1) error_count
            FROM xx_po_sr_assign_stg
           WHERE request_id = xx_emf_pkg.G_REQUEST_ID
             AND error_code = xx_emf_cn_pkg.CN_REC_ERR);
    
           x_error_cnt NUMBER;
    
          CURSOR c_get_warning_cnt IS
          SELECT COUNT (1) warn_count
            FROM xx_po_sr_assign_stg
           WHERE request_id = xx_emf_pkg.G_REQUEST_ID
             AND error_code = xx_emf_cn_pkg.CN_REC_WARN;
    
           x_warn_cnt NUMBER;
    
          CURSOR c_get_success_cnt IS
          SELECT COUNT (1) success_count
            FROM xx_po_sr_assign_stg
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
    
    PROCEDURE main_prc ( p_errbuf        OUT VARCHAR2
                        ,p_retcode       OUT VARCHAR2
                        ,p_org_id        IN  NUMBER)
    IS
       CURSOR  c_assnt_data
       IS   
       SELECT * 
         FROM xx_po_sr_assign_stg 
        WHERE process_code in (xx_emf_cn_pkg.cn_new);
         
       x_error_code                   NUMBER;
       x_error_msg                    VARCHAR2(250);
       x_ctr                          NUMBER:=0;
       x_session_id                   NUMBER;
       x_return_status                VARCHAR2 (1);
       x_msg_count                    NUMBER := 0;
       x_msg_data                     VARCHAR2 (1000);
       x_msg_index_out                NUMBER;
       x_count                        NUMBER;
       x_org_cnt                      NUMBER;
       x_vendor_cnt                   NUMBER;
       x_org_class                    VARCHAR2 (3);
       x_org_num                      NUMBER;
       x_line_num                     NUMBER := 0;
       x_err_count                    NUMBER := 0;
       x_processed_rec                NUMBER;       
       --p NUMBER;
       x_assignment_set_rec_in        mrp_src_assignment_pub.assignment_set_rec_type;
       x_assignment_set_val_rec_in    mrp_src_assignment_pub.assignment_set_val_rec_type;
       x_assignment_tbl_in            mrp_src_assignment_pub.assignment_tbl_type;
       x_assignment_val_tbl_in        mrp_src_assignment_pub.assignment_val_tbl_type;
       x_assignment_set_rec_out       mrp_src_assignment_pub.assignment_set_rec_type;
       x_assignment_set_val_rec_out   mrp_src_assignment_pub.assignment_set_val_rec_type;
       x_assignment_tbl_out           mrp_src_assignment_pub.assignment_tbl_type;
       x_assignment_val_tbl_out       mrp_src_assignment_pub.assignment_val_tbl_type; 

    BEGIN    
       p_retcode := xx_emf_cn_pkg.CN_SUCCESS;
       
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Before Setting Environment');

       -- Emf Env initialization
       x_error_code := xx_emf_pkg.set_env;                        
       -- ------------------------------------ --
       -- Setting Global Variables
       x_error_code := xx_global_var;
       -- ------------------------------------ --
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Start Calling item_rule_insert_stg..');
       
       item_rule_insert_stg( x_error_code
                            ,x_error_msg
                            ,p_org_id);

       FOR r_assnt_data in c_assnt_data loop
           x_ctr:=x_ctr+1;
           x_assignment_tbl_in (x_ctr).assignment_set_id := g_assignment_set_id;
           x_assignment_tbl_in (x_ctr).assignment_type   := r_assnt_data.assignment_type_id;
           x_assignment_tbl_in (x_ctr).operation         := 'CREATE';
           x_assignment_tbl_in (x_ctr).organization_id   := r_assnt_data.organization_id;
           x_assignment_tbl_in (x_ctr).inventory_item_id := r_assnt_data.item_id;--44966;--39796;
           x_assignment_tbl_in (x_ctr).sourcing_rule_id  := r_assnt_data.sr_id;
           x_assignment_tbl_in (x_ctr).sourcing_rule_type:= r_assnt_data.sr_type_id;
       END LOOP;
       
       IF x_assignment_tbl_in.count >0
       THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_assignment_tbl_in.count ||'-> Records Has to be Processed for Sourcing Assignment' );       
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling API for Sourcing rule Assignment' );
       ELSE 
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'-------------------------------------------------------------------------');
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'No Valid Item/Sourcing Rule Combination found for Assignment, Processing' );
       END IF;
       mrp_src_assignment_pub.process_assignment(
                                                  p_api_version_number     => 1.0,
                          p_init_msg_list          => fnd_api.g_false,
                                                  p_return_values          => fnd_api.g_false,
                                                  p_commit                 => fnd_api.g_false,
                                                  x_return_status          => x_return_status,
                                                  x_msg_count              => x_msg_count,
                                                  x_msg_data               => x_msg_data,
                                                  p_assignment_set_rec     => x_assignment_set_rec_in,
                                                  p_assignment_set_val_rec => x_assignment_set_val_rec_in,
                                                  p_assignment_tbl         => x_assignment_tbl_in,
                                                  p_assignment_val_tbl     => x_assignment_val_tbl_in,
                                                  x_assignment_set_rec     => x_assignment_set_rec_out,
                                                  x_assignment_set_val_rec => x_assignment_set_val_rec_out,
                                                  x_assignment_tbl         => x_assignment_tbl_out,
                                                  x_assignment_val_tbl     => x_assignment_val_tbl_out
                                                 );
       IF x_return_status = fnd_api.g_ret_sts_success
       THEN
          BEGIN
             UPDATE xx_po_sr_assign_stg 
                SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                    error_code = xx_emf_cn_pkg.CN_SUCCESS
              WHERE request_id = xx_emf_pkg.G_REQUEST_ID;
          EXCEPTION
         WHEN OTHERS THEN    
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in Updating Completed Records' );
      END;        
          
          BEGIN
             SELECT count(1)
               INTO x_processed_rec
               FROM xx_po_sr_assign_stg 
              WHERE request_id = xx_emf_pkg.G_REQUEST_ID
                AND process_code = xx_emf_cn_pkg.CN_PROCESS_DATA
                AND error_code = xx_emf_cn_pkg.CN_SUCCESS;
          EXCEPTION
         WHEN OTHERS THEN    
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error in Counting, Completed Records' );
      END;                
           
           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_processed_rec ||' -> Assignment Completed Successfully' );
           Commit;
       END IF;
       
       IF x_msg_count > 0
       THEN
          FOR r_index IN 1 .. x_msg_count
          LOOP
              x_msg_data := fnd_msg_pub.get (p_msg_index => r_index,
                                             p_encoded => fnd_api.g_false
                                            );
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SUBSTR (x_msg_data, 1, 500));              
          END LOOP;
          UPDATE xx_po_sr_assign_stg 
             SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                 error_code = xx_emf_cn_pkg.CN_REC_ERR
           WHERE request_id = xx_emf_pkg.G_REQUEST_ID;
           Commit;          
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'MSG:' || x_assignment_set_rec_out.return_status);
       END IF; 
       -- update record count
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling Procedure to display Processing Summary');
       update_record_count;
       
       -- emf report
       xx_emf_pkg.create_report;       
       
    EXCEPTION WHEN OTHERS THEN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in Main Procedure');
         rollback;
         UPDATE xx_po_sr_assign_stg 
            SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                error_code = xx_emf_cn_pkg.CN_REC_ERR
          WHERE request_id = xx_emf_pkg.G_REQUEST_ID;         
    END main_prc;  
END xx_po_sr_assign_pkg;
/
