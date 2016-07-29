DROP PACKAGE BODY APPS.XXINTG_REPROCESS_POREQS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_REPROCESS_POREQS_PKG" 
AS

  PROCEDURE auto_create_internal_req(x_return_status OUT NOCOPY VARCHAR2) IS
  
    /*
    **  PROGRAM LOGIC
    **--Query Order Header
    **--Query Order Line
    **--Derive Values not available on the Internal Sales Order
    **--Pass the Internal Sales Order Header values to the internal req header record
    **--Pass the Internal Sales Order Line values to the internal req Line table
    **--Call the Purchasing API and pass the internal req header record and line tables to Create the Internal Req
    **--Check return status of the Purchasing API
    **--Update the Internal Sales Order with the Req header id, Req line Ids, Req NUMBER and line numbers.
    **--Check for return status
    **--Handle Exceptions
     */
    x_ret_status          VARCHAR2(1000);
    l_int_req_ret_sts      VARCHAR2(1);
    l_req_header_rec       po_create_requisition_sv.header_rec_type;
    l_req_line_tbl         po_create_requisition_sv.line_tbl_type;
    l_created_by           NUMBER;
    l_org_id               NUMBER;
    l_preparer_id          NUMBER;
    l_destination_org_id   NUMBER;
    l_deliver_to_locn_id   NUMBER;
    l_msg_count            NUMBER;
    l_msg_data             VARCHAR2(2000);
    k                      NUMBER := 0;
    j                      NUMBER := 0;
    v_msg_index_out        NUMBER;
    g_pkg_name             VARCHAR2(30) := 'auto_create_internal_req';
    
    v_trx_id           NUMBER := 0;
    
    v_req_line_id       NUMBER := 0;
    
    v_req_line_tbl         po_create_requisition_sv.line_tbl_type;
    
    v_loop_count       NUMBER  := 0;
    
    v_req_line_count       NUMBER  := 0;
    
    v_prep_id        NUMBER := 0;
    v_org_id        NUMBER := 0;
    
    e_rec_not_found_I       EXCEPTION;
    e_rec_not_found_d       EXCEPTION;
    e_end_exception        EXCEPTION;


    CURSOR req_hdr IS
      SELECT distinct preparer_id, org_id
        FROM po_requisitions_interface_all pri
       WHERE source_type_code = 'INVENTORY' AND requisition_type = 'INTERNAL' AND process_flag = 'ERROR' AND interface_source_code = 'MSC'
             AND EXISTS
                   (SELECT 1
                      FROM po_interface_errors err
                     WHERE err.interface_transaction_id = pri.transaction_id
                           AND upper(error_message) LIKE 'YOU MUST ENTER AN OUTSIDE OPERATION LINE  IF YOU ENTER AN OUTSIDE OPERATION ITEM%') 
             AND item_id IN (SELECT inventory_item_id
                               FROM mtl_system_items_b
                              WHERE outside_operation_flag = 'Y'
                                    AND organization_id in (SELECT b.master_organization_id
                                                              FROM cst_organization_definitions a, mtl_parameters b
                                                             WHERE a.organization_id = b.organization_id AND a.operating_unit = pri.org_id));

    CURSOR req_cur(p_org_id IN NUMBER) IS
      SELECT source_type_code,
             transaction_id,
             process_flag,
             interface_source_code,
             requisition_line_id,
             req_distribution_id,
             requisition_type,
             destination_type_code,
             item_description,
             quantity,
             unit_price,
             authorization_status,
             batch_id,
             preparer_id,
             autosource_flag,
             item_id,
             charge_account_id,
             category_id,
             uom_code,
             line_type_id,
             unit_of_measure,
             source_organization_id,
             destination_organization_id,
             deliver_to_location_id,
             deliver_to_requestor_id,
             suggested_buyer_id,
             need_by_date,
             accrual_account_id,
             variance_account_id,
             project_accounting_context,
             org_id,
             vmi_flag,
             base_unit_price
       FROM po_requisitions_interface_all pri
       WHERE source_type_code = 'INVENTORY' AND requisition_type = 'INTERNAL' AND process_flag = 'ERROR' AND interface_source_code = 'MSC'
             AND EXISTS
                   (SELECT 1
                    FROM po_interface_errors err
                    WHERE err.interface_transaction_id = pri.transaction_id
                    AND upper(error_message) LIKE 'YOU MUST ENTER AN OUTSIDE OPERATION LINE  IF YOU ENTER AN OUTSIDE OPERATION ITEM%')
                    AND item_id IN (SELECT inventory_item_id
                                    FROM mtl_system_items_b
                                     WHERE outside_operation_flag = 'Y'
                                     AND organization_id IN (SELECT b.master_organization_id
                                                             FROM cst_organization_definitions a, mtl_parameters b
                                                             WHERE a.organization_id = b.organization_id 
                                                             AND a.operating_unit = pri.org_id)
                   );
       --AND    transaction_id not in (90226,91226);
  BEGIN
  
  
     BEGIN

          SELECT distinct preparer_id, org_id
          into   v_prep_id, v_org_id
        FROM po_requisitions_interface_all pri
           WHERE source_type_code = 'INVENTORY' AND requisition_type = 'INTERNAL' AND process_flag = 'ERROR' AND interface_source_code = 'MSC'
             AND EXISTS
               (SELECT 1
                  FROM po_interface_errors err
                 WHERE err.interface_transaction_id = pri.transaction_id
                   AND upper(error_message) LIKE 'YOU MUST ENTER AN OUTSIDE OPERATION LINE  IF YOU ENTER AN OUTSIDE OPERATION ITEM%') 
             AND item_id IN (SELECT inventory_item_id
                       FROM mtl_system_items_b
                      WHERE outside_operation_flag = 'Y'
                        AND organization_id in (SELECT b.master_organization_id
                                      FROM cst_organization_definitions a, mtl_parameters b
                                     WHERE a.organization_id = b.organization_id AND a.operating_unit = pri.org_id));
                                     
                                     
              EXCEPTION WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'No qualified data in the interface table to process and proceed further!');
              fnd_file.put_line(fnd_file.log,'Error is ... '||SQLERRM);
              fnd_file.put_line(fnd_file.log,' SQLCODE = '||SQLCODE);
              fnd_file.put_line(fnd_file.log,'SQLERRM = '||SUBSTR(SQLERRM,1,150));  
              raise e_end_exception;
     
     
     
     END;
     
    oe_debug_pub.add(' Entering procedure auto_create_internal_req ', 2);
    fnd_file.put_line(fnd_file.log, '........................................................');
    
    -- Populating Req Hdr Record

    fnd_file.put_line(fnd_file.log, 'These preparer_id s from the Interface Table are requested to be processed by the program!');
    fnd_file.put_line(fnd_file.log, '******************************************************************************************');
    
    FOR i IN req_hdr LOOP
      x_return_status := fnd_api.g_ret_sts_success;
      l_req_header_rec.preparer_id := i.preparer_id;
      l_req_header_rec.summary_flag := 'N';
      l_req_header_rec.enabled_flag := 'Y';
      l_req_header_rec.authorization_status := 'APPROVED';
      l_req_header_rec.type_lookup_code := 'INTERNAL';
      l_req_header_rec.org_id := i.org_id;
      
        fnd_file.put_line(fnd_file.log, 'preparer_id ' || '# - ' || i.preparer_id);
        fnd_file.put_line(fnd_file.log, '----------------------------');
        fnd_file.put_line(fnd_file.log, '........................................................');
      
        -- Populating Req Line Table
        
        fnd_file.put_line(fnd_file.log, 'These REQUISITION_LINE_ID s from the Interface Table are requested to be processed by the program!');
        fnd_file.put_line(fnd_file.log, '**************************************************************************************************');        

      FOR req_int IN req_cur(i.org_id) LOOP
        j := j + 1;
        l_req_line_tbl(j).source_type_code := req_int.source_type_code;
        l_req_line_tbl(j).destination_type_code := req_int.destination_type_code;
        l_req_line_tbl(j).item_description := req_int.item_description;
        l_req_line_tbl(j).quantity := req_int.quantity;
        l_req_line_tbl(j).unit_price := req_int.unit_price;
        l_req_line_tbl(j).item_id := req_int.item_id;
        l_req_line_tbl(j).category_id := req_int.category_id;
        l_req_line_tbl(j).uom_code := req_int.uom_code;
        l_req_line_tbl(j).line_type_id := req_int.line_type_id;
        l_req_line_tbl(j).source_organization_id := req_int.source_organization_id;
        l_req_line_tbl(j).destination_organization_id := req_int.destination_organization_id;
        l_req_line_tbl(j).deliver_to_location_id := req_int.deliver_to_location_id;
        l_req_line_tbl(j).requisition_line_id := req_int.requisition_line_id;
        --l_req_line_tbl(j).distribution_id := req_int.req_distribution_id; -- ????
        l_req_line_tbl(j).to_person_id := req_int.preparer_id;
        l_req_line_tbl(j).suggested_buyer_id := req_int.suggested_buyer_id;
        l_req_line_tbl(j).need_by_date := req_int.need_by_date;
        l_req_line_tbl(j).source_doc_line_reference := -9999999;
        l_req_line_tbl(j).org_id := req_int.org_id;
        l_req_line_tbl(j).line_num := j;
        

        fnd_file.put_line(fnd_file.log, 'requisition_line_id ' || '# - ' || j || req_int.requisition_line_id);
        fnd_file.put_line(fnd_file.log, '-----------------------------------');
        
        
      END LOOP;

    END LOOP;
    
    fnd_file.put_line(fnd_file.log, 'Number of requisition lines to be processed = ' || l_req_line_tbl.count());

    BEGIN
    
         -- Calling the key API to create Requisitions
         
      fnd_file.put_line(fnd_file.log, '........................................................');  
      fnd_file.put_line(fnd_file.log, 'Program is going to call the API to create the Requisitions');
      
      po_create_requisition_sv.process_requisition(px_header_rec     => l_req_header_rec,
                                                   px_line_table     => l_req_line_tbl,
                                                   x_return_status   => l_int_req_ret_sts,
                                                   x_msg_count       => l_msg_count,
                                                   x_msg_data        => l_msg_data);

      fnd_file.put_line(fnd_file.log, 'After the API Call .....');
      fnd_file.put_line(fnd_file.log, 'l_int_req_ret_sts is - ' || l_int_req_ret_sts);
      fnd_file.put_line(fnd_file.log, 'l_msg_data is - ' || l_msg_data);
      fnd_file.put_line(fnd_file.log, 'l_msg_count is - ' || l_msg_count);
      
      
      -- Sankar Narayanan
      
      
        -- IF the API successfully creates the requisitions then
        -- insert into a mirror table 
      
      IF l_int_req_ret_sts = fnd_api.g_ret_sts_success THEN
            
        FOR b IN 1..l_req_line_tbl.count LOOP

         BEGIN

             BEGIN
             
                v_req_line_count := v_req_line_count + 1;

            INSERT INTO xxintg_po_req_iface_all
             (
             SELECT *
              FROM po_requisitions_interface_all
              WHERE  requisition_line_id = l_req_line_tbl(b).requisition_line_id
             );

             COMMIT;  
             
             
             fnd_file.put_line(fnd_file.log,'Successfully Processed this requisition line id - ' || l_req_line_tbl(b).requisition_line_id);
             fnd_file.put_line(fnd_file.log,'=======================================');
             

             EXCEPTION WHEN OTHERS THEN
            RAISE e_rec_not_found_I;

             END;

           EXCEPTION WHEN e_rec_not_found_I THEN
           fnd_file.put_line(fnd_file.log, 'In e_rec_not_found_I during insert into mirror table - ');

           WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.log,'When Others error during insert into mirror table');
           fnd_file.put_line(fnd_file.log,'Error is ... '||SQLERRM);
           fnd_file.put_line(fnd_file.log,' SQLCODE = '||SQLCODE);
           fnd_file.put_line(fnd_file.log,'SQLERRM = '||SUBSTR(SQLERRM,1,150));             

         END;   
         

         -- delete from the po_requisitions_interface_all table

         BEGIN

             BEGIN
            DELETE FROM po_requisitions_interface_all
            WHERE  requisition_line_id = l_req_line_tbl(b).requisition_line_id;

             COMMIT;  

             EXCEPTION WHEN OTHERS THEN
            RAISE e_rec_not_found_d;

             END;

           EXCEPTION WHEN e_rec_not_found_d THEN
           fnd_file.put_line(fnd_file.log, 'In e_rec_not_found_d during delete from the iface table - ');
           

           WHEN OTHERS THEN
           fnd_file.put_line(fnd_file.log,'When Others error during delete from the iface table');
           fnd_file.put_line(fnd_file.log,'Error is ... '||SQLERRM);
           fnd_file.put_line(fnd_file.log,' SQLCODE = '||SQLCODE);
           fnd_file.put_line(fnd_file.log,'SQLERRM = '||SUBSTR(SQLERRM,1,150));  

         END;

          END LOOP;
          
          
               fnd_file.put_line(fnd_file.log,'Total number of successful requisition lines = ' || v_req_line_count);
          

              
      END IF;      
      

        -- IF the API fails to create requisitions then
        

      IF l_int_req_ret_sts = fnd_api.g_ret_sts_unexp_error THEN
        oe_debug_pub.add(' PO API call returned unexpected error ' || l_msg_data, 2);
        --oe_debug_pub.add(' PO API call returned unexpected error ' || l_msg_data);
        fnd_file.put_line(fnd_file.log,'API error l_msg_data is - ' || l_msg_data);
        RAISE fnd_api.g_exc_unexpected_error;
      ELSIF l_int_req_ret_sts = fnd_api.g_ret_sts_error THEN
        oe_debug_pub.add(' PO API call returned error ' || l_msg_data, 2);
        RAISE fnd_api.g_exc_error;
      END IF;

    END;

    IF l_msg_count > 0 THEN

      FOR v_index in 1 .. l_msg_count LOOP
        oe_msg_pub.get(p_msg_index => v_index, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => v_msg_index_out);
        fnd_file.put_line(fnd_file.log,'API error l_msg_data is - ' || l_msg_data);
        fnd_file.put_line(fnd_file.log,'============================================================');
      END LOOP;

    END IF;

  EXCEPTION
    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      oe_debug_pub.add('auto_create_internal_req: In Unexpected error', 2);
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;
      oe_debug_pub.add('auto_create_internal_req: In execution error', 2);


    WHEN NO_DATA_FOUND THEN
      fnd_file.put_line(fnd_file.log,'No suitable records found in the req iface table to process!');    
    
    WHEN e_end_exception THEN
      
      fnd_file.put_line(fnd_file.log,'In e_end_exception.No qualified data in the interface table to process and proceed further!');  

    WHEN OTHERS THEN
      oe_debug_pub.add('auto_create_internal_req: In Other error', 2);

      IF oe_msg_pub.check_msg_level(oe_msg_pub.g_msg_lvl_unexp_error) THEN
        oe_msg_pub.add_exc_msg(g_pkg_name, 'auto_create_internal_req');
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;
      
      fnd_file.put_line(fnd_file.log,'When Others error during in auto_create_internal_req procedure');
      fnd_file.put_line(fnd_file.log,'Error is ... '||SQLERRM);
      fnd_file.put_line(fnd_file.log,' SQLCODE = '||SQLCODE);
      fnd_file.put_line(fnd_file.log,'SQLERRM = '||SUBSTR(SQLERRM,1,150));   
      
  END auto_create_internal_req;
  
  
------

PROCEDURE main (errbuf OUT VARCHAR2, retcode OUT VARCHAR2)
IS
  
  x_ret_status VARCHAR2(200);
  

BEGIN

   --fnd_global.apps_initialize(1559, 51052, 201);
   --mo_global.set_policy_context('S', 82);
   
   -- calling the auto_create_internal_req procedure
   
      --fnd_global.apps_initialize(1559, 51052, 201);
      mo_global.set_policy_context('S', 82);
      --apps.mo_global.set_policy_context('M'); ---- ????
   
   auto_create_internal_req(x_ret_status);
   
    EXCEPTION
    WHEN OTHERS THEN
       
      fnd_file.put_line(fnd_file.log,'When Others error during in MAIN procedure');
      fnd_file.put_line(fnd_file.log,'Error is ... '||SQLERRM);
      fnd_file.put_line(fnd_file.log,' SQLCODE = '||SQLCODE);
      fnd_file.put_line(fnd_file.log,'SQLERRM = '||SUBSTR(SQLERRM,1,150));   

END main;
  

END xxintg_reprocess_poreqs_pkg; 
/
