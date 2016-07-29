DROP PACKAGE BODY APPS.XX_WMS_CAROUSEL_INBND_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_WMS_CAROUSEL_INBND_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Yogesh
 Creation Date : 05-JUN-2012
 File Name     : xxwmscarinbndpkg.pkb
 Description   : This script creates the specification of the package
		 body xx_wms_carousel_inbnd_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-JUN-2012 Yogesh                Initial Development
*/
----------------------------------------------------------------------
    PROCEDURE load_task( p_task_id        IN     NUMBER
                        ,p_trx_id         IN     NUMBER
                        ,p_trx_qty        IN     NUMBER
                        ,p_status         OUT    VARCHAR2
                       )
    IS
    CURSOR c_trx_details(p_pick_id NUMBER)
    IS
    SELECT  transaction_quantity
           ,cartonization_id
      FROM  mtl_material_transactions_temp mmttt1
     WHERE  transaction_temp_id = p_pick_id;
       x_trx_details_rec          C_TRX_DETAILS%ROWTYPE;
       x_short_pick               NUMBER;
    BEGIN
       OPEN c_trx_details(p_trx_id);
       FETCH c_trx_details
         INTO x_trx_details_rec;
       CLOSE c_trx_details; 
       IF x_trx_details_rec.transaction_quantity != p_trx_qty THEN
          UPDATE xxintg.xx_wms_carousel_inbd_stg
             SET short_pick_flag = 1,
                 error_code = xx_emf_cn_pkg.CN_REC_ERR,
                 process_code = xx_emf_cn_pkg.CN_IN_PROG
	   WHERE pick_id = p_trx_id;
	  p_status:= 'E';
	  RETURN;
       END IF;
       BEGIN
          UPDATE mtl_material_transactions_temp
             SET wms_task_status = 4,
                 transfer_lpn_id = x_trx_details_rec.cartonization_id,
                 last_update_date = sysdate
           WHERE transaction_temp_id = p_trx_id;
          UPDATE wms_dispatched_tasks
             SET status = 4
           WHERE task_id = p_task_id;
          UPDATE wms_license_plate_numbers
             SET lpn_context = 8,
                 last_update_date = sysdate
           WHERE lpn_id = x_trx_details_rec.cartonization_id;
          UPDATE xxintg.xx_wms_carousel_inbd_stg
             SET process_code = xx_emf_cn_pkg.CN_PROCESS_DATA,
                 error_code = xx_emf_cn_pkg.CN_SUCCESS,
                 transaction_quantity = x_trx_details_rec.transaction_quantity,
                 short_pick_flag = 0
           WHERE pick_id = p_trx_id;      
       EXCEPTION
         WHEN OTHERS THEN
              p_status:= 'E';
              rollback;
              xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                               ,p_category                 => 'Carousel Inbound Interface'
                               ,p_error_text               => 'Task Load Updates Failed'
                               ,p_record_identifier_1      => p_trx_id
                              );                 
              RETURN;
       END;
       p_status:= 'S';
    END load_task;
----------------------------------------------------------------------
    FUNCTION task_split( p_trx_id      IN   NUMBER
                        ,p_picked_qty  IN   NUMBER 
                        ,p_uom         IN   VARCHAR2
                       )
    RETURN NUMBER                       
    IS
       x_split_qty_tab             WMS_TASK_MGMT_PUB.TASK_QTY_TBL_TYPE;
       x_ret_task_typ_tab          WMS_TASK_MGMT_PUB.TASK_TAB_TYPE;
       x_task_dtl_tab              WMS_TASK_MGMT_PUB.TASK_DETAIL_TBL_TYPE;
       x_ret_sts                   VARCHAR2(500);
       x_ret_msg_count             NUMBER;
       x_ret_msg_data              VARCHAR2(500);
    BEGIN
       x_split_qty_tab(1).quantity  := p_picked_qty;
       x_split_qty_tab(1).uom       := p_uom;
       WMS_TASK_MGMT_PUB.split_task ( p_source_transaction_number    => p_trx_id,
                                      p_split_quantities             => x_split_qty_tab,
                                      p_commit                       => FND_API.G_FALSE ,
                                      x_resultant_tasks              => x_ret_task_typ_tab ,
                                      x_resultant_task_details       => x_task_dtl_tab ,
                                      x_return_status                => x_ret_sts ,
                                      x_msg_count                    => x_ret_msg_count ,
                                      x_msg_data                     => x_ret_msg_data  );
       IF x_ret_sts = 'S' and  x_ret_msg_count is NULL                                    
       THEN
         RETURN x_ret_task_typ_tab(1).transaction_number;
       ELSE
         RETURN -1;
       END IF;
    EXCEPTION   
      WHEN OTHERS THEN
              rollback;
              xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                               ,p_category                 => 'Carousel Inbound Interface'
                               ,p_error_text               => 'Error in Split Task API'
                               ,p_record_identifier_1      => p_trx_id
                              );            
              RETURN -1;
    END task_split;
----------------------------------------------------------------------
    procedure create_wms_task( p_trx_id         in     number
                               ,p_divertcode_user_id   IN      VARCHAR2     
                              ,p_task_id        OUT    NUMBER
                              ,p_status         OUT    VARCHAR2
                             )
    IS
       x_user_name                VARCHAR2(50);
       x_person_id                NUMBER; 
       x_task_id                  NUMBER;
    BEGIN
           begin
            --Commented and Below SELECT Statement is Added to Enable Multiple users handling for carousel. 
           /*xx_intg_common_pkg.get_process_param_value( 'XXWMSCARINBNDPKG'
                                           	       ,'USER'
                                        	       ,x_user_name
                                     		     ); */                                     		     
           SELECT  employee_id
             INTO  x_person_id
             FROM  fnd_user fu,
                   per_all_people_f ppf
            WHERE  fu.user_name = upper(p_divertcode_user_id)
              AND  ppf.person_id = fu.employee_id
              AND  SYSDATE BETWEEN ppf.effective_start_date and ppf.effective_end_date;                                     		     
       EXCEPTION        
         WHEN OTHERS THEN
              p_status:= 'E';
              xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                               ,p_category                 => 'Carousel Inbound Interface'
                               ,p_error_text               => 'Carousel User not defined/Invalid user'
                               ,p_record_identifier_1      => p_trx_id
                              ); 
              RETURN;
       END;
       IF x_person_id is null
       THEN
          p_status:= 'E';
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'Employee not Tagged to Carousel User'
                           ,p_record_identifier_1      => p_trx_id
                          ); 
          RETURN;
       END IF;
        SELECT  wms_dispatched_tasks_s.NEXTVAL
             into  x_task_id
             from  dual;
       INSERT INTO wms_dispatched_tasks
                  (
                    task_id
                   ,transaction_temp_id
                   ,organization_id
                   ,user_task_type
                   ,person_id
                   ,effective_start_date
                   ,effective_end_date
                   ,equipment_id
                   ,equipment_instance
                   ,person_resource_id
                   ,machine_resource_id
                   ,status
                   ,dispatched_time
                   ,last_update_date
                   ,last_updated_by
                   ,creation_date
                   ,created_by
                   ,task_type
                   ,priority
                   ,operation_plan_id
                   ,move_order_line_id
                  )
          (SELECT  x_task_id
                  ,transaction_temp_id
                  ,organization_id
                  ,NVL(standard_operation_id, 2)
                  ,x_person_id
                  ,SYSDATE
                  ,SYSDATE
                  ,null
                  ,null
                  ,NULL	
                  ,null
                  ,1
                  ,SYSDATE
                  ,SYSDATE
                  ,x_person_id
                  ,SYSDATE
                  ,x_person_id
                  ,NVL(wms_task_type, 1)
                  ,task_priority
                  ,operation_plan_id
                  ,move_order_line_id
             FROM  mtl_material_transactions_temp
            WHERE  transaction_temp_id = p_trx_id);
           UPDATE  xxintg.xx_wms_carousel_inbd_stg 
              SET  task_id = x_task_id 
            WHERE  pick_id = p_trx_id;
    p_task_id:=x_task_id;
    EXCEPTION
      WHEN OTHERS THEN
                rollback;
                xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                                 ,p_category                 => 'Carousel Inbound Interface'
                                 ,p_error_text               => 'Cannot Insert into Dispatched Task Table '
                                 ,p_record_identifier_1      => p_trx_id
                                );               
    END create_wms_task;
----------------------------------------------------------------------
    FUNCTION  carousel_inbd_task_load( p_divertcode_user_id   IN      VARCHAR2
			              ,p_order_no             IN      NUMBER
			              ,p_carton_id            IN      VARCHAR2
			              ,p_item                 IN      VARCHAR2
              			      ,p_bin                  IN      VARCHAR2
              			      ,p_trx_quantity         IN      NUMBER
				      ,p_short                IN      NUMBER 
				      ,p_lot                  IN      VARCHAR2
				      ,p_pick_id              IN      NUMBER
              			     )
    RETURN VARCHAR2              			     
      IS
      CURSOR c_task_details( p_trx_temp_id NUMBER
                            ,p_item_no     VARCHAR2
                          )
      IS
      SELECT  transaction_temp_id pick_id,
              mmtt.subinventory_code,
              mmtt.locator_id,
              msi.segment1 item,
              msi.inventory_item_id,
              mmtt.organization_id, 
              wlpn.license_plate_number carton_id,
              xwcov.bin,
              xwcov.lot,
              mmtt.transaction_quantity trx_qty,
              mmtt.transaction_uom uom
        FROM  mtl_material_transactions_temp mmtt,
              wms_license_plate_numbers wlpn,
              mtl_system_items_b msi,
              xx_wms_carousel_otbnd_v xwcov,
              xx_emf_process_parameters xpp,
              xx_emf_process_setup xps
       WHERE  transaction_temp_id = p_trx_temp_id
         AND  mmtt.wms_task_status!=4
         AND  wlpn.lpn_id = mmtt.cartonization_id
         AND  msi.inventory_item_id = mmtt.inventory_item_id
         AND  msi.organization_id = mmtt.organization_id
         AND  msi.segment1=p_item_no
         AND  xwcov.pickid = mmtt.transaction_temp_id
         AND  xpp.parameter_name = 'ZONE'
         AND  xps.process_id = xpp.process_id
         AND  xps.process_name = 'XXWMSCAROTBNDV'
         AND  mmtt.subinventory_code = xpp.parameter_value
         AND  xwcov.ZONE =  xpp.parameter_value
         AND  NVL (xps.enabled_flag, 'Y') = 'Y'
         AND  NVL (xpp.enabled_flag, 'Y') = 'Y'; 
       x_task_details_rec          C_TASK_DETAILS%ROWTYPE;
       x_stage_rec_exists          VARCHAR2(5):='N';
       x_task_exists               VARCHAR2(5):='N';
       x_task_id                   NUMBER;
       x_ret_sts                   VARCHAR2(10);
       x_err_code                  NUMBER;
       x_pick_id                   NUMBER;
       x_ret_msg                   VARCHAR2(100);
       x_status                    NUMBER;
       x_divert_user_id            NUMBER;
       x_user_name                 VARCHAR2(50); 
       x_user_valid                VARCHAR2(5):='N';
       PRAGMA                      AUTONOMOUS_TRANSACTION;
    BEGIN
       x_err_code := xx_emf_pkg.set_env('XXWMSCARINBNDPKG');
       IF p_pick_id is null
        THEN
          x_status:=1;
          x_ret_msg:= 'Invalid Pick ID';
          rollback;
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'PICK_ID is Null'
                           ,p_record_identifier_1      => p_pick_id
                          );          
          RETURN x_status || ' - ' || x_ret_msg;
       ELSE
          x_pick_id:=p_pick_id;
       END IF;       
       OPEN c_task_details(x_pick_id,p_item);
       FETCH c_task_details 
        INTO x_task_details_rec;
       IF c_task_details%NOTFOUND 
          THEN
          x_status:=1;
          x_ret_msg:= 'Invalid Pick ID and Item Number Combination';
          rollback;
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'Invalid Pick ID and ITEM# Comibination'
                           ,p_record_identifier_1      => x_pick_id     
                          );          
          RETURN x_status || ' - ' || x_ret_msg;
       END IF;
       CLOSE c_task_details;        
       IF p_item is null
        THEN
          x_status:=1;
          x_ret_msg:= 'Invalid Item Loaded';
          rollback;
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'LOADED ITEM# is Null'
                           ,p_record_identifier_1      => x_pick_id     
                          );                             
          RETURN x_status || ' - ' || x_ret_msg;
       END IF;    
       OPEN c_task_details(x_pick_id,p_item);
       IF p_carton_id is null OR p_carton_id!=x_task_details_rec.carton_id
        THEN
          x_status:=1;
          x_ret_msg:= 'Invalid Carton/Tote Number';
          rollback;
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'Loaded Carton is Null/Invalid'
                           ,p_record_identifier_1      => x_pick_id
                          );             
          RETURN x_status || ' - ' || x_ret_msg;
       END IF; 
       IF p_bin is null OR p_bin!=x_task_details_rec.bin
        THEN
          x_status:=1;
          x_ret_msg:= 'Invalid Locator/Bin';
          rollback;
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'Null/Invalid Locator'
                           ,p_record_identifier_1      => x_pick_id
                          );             
          RETURN x_status || ' - ' || x_ret_msg;
       END IF; 
       BEGIN
          SELECT  user_id
            INTO  x_divert_user_id
            FROM  fnd_user
           WHERE  user_name = upper(p_divertcode_user_id);
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             x_divert_user_id:=NULL;
             x_status:=1;
             x_ret_msg:= 'Loading with Invalid User ID ';
             rollback;
             xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                              ,p_category                 => 'Carousel Inbound Interface'
                              ,p_error_text               => 'Loading with Invalid User ID'
                              ,p_record_identifier_1      => x_pick_id
                             );          
             RETURN x_status || ' - ' || x_ret_msg;             
       END; 
       BEGIN  
       --Commented and Below SELECT Statement is Added to Enable Multiple users handling for carousel. 
          /*xx_intg_common_pkg.get_process_param_value( 'XXWMSCARINBNDPKG'
                                            	      ,'USER'
                                               	      ,x_user_name
                                    		     );*/
          BEGIN                           		     
             SELECT 'Y'
               INTO x_user_valid
               FROM xx_emf_process_setup eps,
                    xx_emf_process_parameters epp
              WHERE eps.process_name = 'XXWMSCARINBNDPKG'
                AND eps.process_id = epp.process_id
                AND epp.parameter_name LIKE 'USER%'
                AND (epp.parameter_value) = upper(p_divertcode_user_id);
          EXCEPTION
             WHEN no_data_found
             THEN 
             x_user_valid :='N';               
             WHEN OTHERS THEN
                x_status:=1;
                x_ret_msg:= 'Carousel User Not Defined in Oracle Process Setup ';                            
          END;   
          IF x_user_valid != 'Y'
          THEN
             x_divert_user_id:=NULL;
             x_status:=1;
             x_ret_msg:= 'Loading with Invalid User ID/Carousel User Not Defined in Oracle Process Setup ';
             rollback;
             xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                              ,p_category                 => 'Carousel Inbound Interface'
                              ,p_error_text               => 'Loading with Invalid User ID'
                              ,p_record_identifier_1      => x_pick_id
                             );          
             RETURN x_status || ' - ' || x_ret_msg;     
          END IF;  
       EXCEPTION
          WHEN OTHERS THEN
             x_status:=1;
             x_ret_msg:= 'Carousel User Not Defined in Oracle ';
       END;             
       IF p_trx_quantity is null or p_trx_quantity = 0
        THEN
          x_status:=1;
          x_ret_msg:= 'Picked Quantity is Null/Zero';
          rollback;
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'TRX QTY is Null'
                           ,p_record_identifier_1      => x_pick_id
                          );          
          RETURN x_status || ' - ' || x_ret_msg;
       ELSIF p_trx_quantity > x_task_details_rec.trx_qty
        THEN
          x_status:=1;
          x_ret_msg:= 'Picked Quantity is more than Requested Quantity';
          rollback;
          xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                           ,p_category                 => 'Carousel Inbound Interface'
                           ,p_error_text               => 'Picked QTY is More than TRX QTY'
                           ,p_record_identifier_1      => x_pick_id
                          );          
          RETURN x_status || ' - ' || x_ret_msg;
       ELSIF p_trx_quantity < x_task_details_rec.trx_qty
          THEN
            x_pick_id:=task_split( x_pick_id,p_trx_quantity,x_task_details_rec.uom);
          IF x_pick_id = -1
           THEN
             x_status:=1;
             x_ret_msg:= 'Error in Task Splitting';
             rollback;
             xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                              ,p_category                 => 'Carousel Inbound Interface'
                              ,p_error_text               => 'Error in Task Splitting'
                              ,p_record_identifier_1      => x_pick_id
                             );          
             RETURN x_status || ' - ' || x_ret_msg;          
          END IF; 
       END IF;      
       BEGIN
          SELECT  'Y',task_id
            INTO  x_stage_rec_exists,x_task_id
            FROM  xxintg.xx_wms_carousel_inbd_stg
           WHERE  pick_id = x_pick_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             x_stage_rec_exists:='N';
             x_task_id:=NULL;
       END;
       IF x_stage_rec_exists != 'Y'
        THEN
          INSERT into  xxintg.xx_wms_carousel_inbd_stg ( pick_id,
                                                         task_id,
                                                         carton_id,
                                                         order_no,
                                                         item,
                                                         inventory_item_id,
                                                         transaction_quantity,
                                                         subinventory_code,
                                                         locator_id,
                                                         short_pick_flag,
                                                         organization_id,
                                                         lot_number,
                                                         divertcode_user_id,
                                                         process_code,
                                                         error_code,
                                                         creation_date,
                                                         last_update_date
                                                       )
                                                 VALUES( x_pick_id,
                                                         NULL,
                                                         p_carton_id,
                                                         p_order_no,
                                                         p_item,
                                                         x_task_details_rec.inventory_item_id,
                                                         p_trx_quantity,
                                                         x_task_details_rec.subinventory_code,
                                                         x_task_details_rec.locator_id,
                                                         p_short,
                                                         x_task_details_rec.organization_id,
                                                         p_lot,
                                                         x_divert_user_id,
                                                         xx_emf_cn_pkg.CN_NEW,
                                                         NULL,
                                                         sysdate,
                                                         sysdate
                                                       );
       END IF;  
       BEGIN
          SELECT 'Y'
            INTO x_task_exists
            FROM wms_dispatched_tasks
           WHERE transaction_temp_id = x_pick_id;
       EXCEPTION
          WHEN OTHERS THEN
               x_task_exists := 'N';
       END; 
       IF x_task_exists != 'Y'
       THEN
          create_wms_task( p_trx_id     => x_pick_id
                           ,p_divertcode_user_id => p_divertcode_user_id
                          ,p_task_id    => x_task_id
                          ,p_status     => x_ret_sts                          
                         );
          IF x_ret_sts = 'E'
           THEN
             x_status:=1;
             x_ret_msg:='Error in Insert into Dispatched Task';
             rollback;
             RETURN x_status || ' - ' || x_ret_msg;
          END IF;       
       END IF;
       load_task( p_task_id     =>  x_task_id
                 ,p_trx_id      =>  x_pick_id
                 ,p_trx_qty     =>  p_trx_quantity
                 ,p_status      =>  x_ret_sts
                );
       IF x_ret_sts = 'S'
        THEN
          x_status:=0;
          x_ret_msg:='Load Complete';
          Commit;
          RETURN x_status || ' - ' || x_ret_msg;
       ELSE
          x_status:=1;
          x_ret_msg:='Load Quantity Mismatch/Load Updates Failed';
          rollback;
          RETURN x_status || ' - ' || x_ret_msg;
       END IF;
    EXCEPTION   
      WHEN OTHERS THEN
           rollback;
           xx_emf_pkg.error( p_severity                 => xx_emf_cn_pkg.cn_medium
                            ,p_category                 => 'Carousel Inbound Interface'
                            ,p_error_text               => 'Error in Split Task API'
                            ,p_record_identifier_1      => x_pick_id
                           );            
           x_status:=1;
           x_ret_msg:='Load Failed, Please Check The EMF Error Tables';
           RETURN x_status || ' - ' || x_ret_msg;  
    END carousel_inbd_task_load; 
END xx_wms_carousel_inbnd_pkg;
/
