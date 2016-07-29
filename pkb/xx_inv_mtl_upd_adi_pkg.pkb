DROP PACKAGE BODY APPS.XX_INV_MTL_UPD_ADI_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_MTL_UPD_ADI_PKG" as
procedure log_message (p_message IN VARCHAR2) IS
 begin
    insert into xx_debug values ('MTL_UPD',p_message);
 end log_message;
 
 function upd_mtl_xns
          (p_org_code IN VARCHAR2,
 p_Transaction_Type IN VARCHAR2,
 p_Item             IN VARCHAR2,
 p_Revision         IN VARCHAR2,
 p_From_Subinventory IN VARCHAR2,
 p_From_Locator      IN VARCHAR2,
 p_To_Subinventory   IN VARCHAR2,
 p_To_Locator        IN VARCHAR2, 
 p_UOM               IN VARCHAR2,
 p_Quantity          IN Number,
 p_Lot_number        IN VARCHAR2,   
 p_Serial_serial_number IN VARCHAR2,
 p_Sales_Rep           IN VARCHAR2,  
 p_Account_Alias_Name  IN VARCHAR2,
 p_Reason              IN VARCHAR2, 
 p_Reference           IN VARCHAR2, 
 p_Lot_Expiry          IN date,
 p_attribute1          IN VARCHAR2,
 P_attribute2          IN VARCHAR2,
 P_attribute3          IN VARCHAR2,
 P_attribute4          IN VARCHAR2,
 P_attribute5          IN VARCHAR2,
 P_attribute6          IN VARCHAR2,
 P_attribute7          IN VARCHAR2,
 P_attribute8          IN VARCHAR2,
 P_attribute9          IN VARCHAR2,
 P_attribute10         IN VARCHAR2) 
 RETURN VARCHAR2 IS 
 x_revision_num number;
 x_err_msg varchar2(100);
   l_transaction_type_id         mtl_transaction_types.transaction_type_id%TYPE;
   l_transaction_src_type_id     mtl_transaction_types.transaction_source_type_id%TYPE;
   l_transaction_action_id       mtl_transaction_types.transaction_action_id%TYPE;
   l_transaction_type_name       mtl_transaction_types.transaction_type_name%TYPE;
   l_account_alias_name          mtl_generic_dispositions.segment1%TYPE;
   l_account_id                  mtl_generic_dispositions.distribution_account%TYPE;
   l_location_control_code       apps.mtl_system_items_b.location_control_code%TYPE;
   l_source_header_id            NUMBER;
   v_inv_item_id                 NUMBER;
   l_subinv_code                 VARCHAR2 (30);
   v_salesrep                    VARCHAR2 (30);
   l_source_line_id              NUMBER;
   l_trans_temp_id               NUMBER;
   v_org_id                      NUMBER;
   l_err_msg                     VARCHAR2 (6000):= '';
   l_source_code                 VARCHAR2 (30):='SURGISOFT';
   v_primary_uom                 VARCHAR2 (3);
   v_lot_control_code            NUMBER;
   v_sno_control_code            NUMBER;
   v_shelf_life_code             NUMBER;
   v_revision_qty_control_code   NUMBER;
   v_account_alias_name          VARCHAR2 (30);
   v_cnt                         NUMBER;
   v_reason                      VARCHAR2 (1000);
   lv_count                      NUMBER:=0;
   v_issue_receipt_sign          VARCHAR2 (1):=null;
   v_mtl_trans                   NUMBER:=0;
   v_lot_no_serial               NUMBER:=0;
   v_serial_no_lot               NUMBER:=0;
   v_lot_serial                  NUMBER:=0;
   v_request_id                  NUMBER;
   v_err_cnt                     NUMBER;
   l_tranfer_locator             NUMBER;
   l_locator_id                  NUMBER;
   v_lot_cnt                    NUMBER;
   v_serial_cnt                 NUMBER;
   l_lot_expiry                 date;
   l_serial_serial_number       number;
  -- p_api_version                NUMBER;
   l_reason_id                  NUMBER;
   p1_lot_number                 NUMBER;
   p_organization_id            NUMBER;
   p_inventory_item_id         NUMBER;
   p_transaction_temp_id        NUMBER;
   p_transaction_action_id      NUMBER;
   p_transfer_organization_id   NUMBER;
   p_object_id                  NUMBER;
   l_return_status              VARCHAR2(100);
   l_msg_count                  NUMBER;
   l_msg_data                   VARCHAR2(100);

 BEGIN
      l_err_msg := NULL;
      l_transaction_type_id:= NULL;
      l_transaction_action_id := NULL;
      l_transaction_src_type_id := NULL;
      l_transaction_type_name := NULL;
      v_org_id := NULL;
      l_trans_temp_id := NULL;
      l_source_header_id := NULL;
      l_source_line_id := NULL;
      v_inv_item_id := NULL;
      l_subinv_code := NULL;
      v_salesrep := NULL;
      v_primary_uom := NULL;
      v_shelf_life_code := NULL;
      v_lot_control_code := NULL;
      v_sno_control_code := NULL;
      v_revision_qty_control_code := NULL;
      l_location_control_code := NULL;
      v_issue_receipt_sign := NULL;
      v_reason := NULL;
      l_tranfer_locator := NULL;

      BEGIN
         SELECT transaction_type_id, transaction_action_id,
                transaction_source_type_id, transaction_type_name
           INTO l_transaction_type_id, l_transaction_action_id,
                l_transaction_src_type_id, l_transaction_type_name
           FROM mtl_transaction_types
          WHERE transaction_type_name = p_transaction_type
          AND transaction_type_name in ('Account alias issue','Account alias receipt','Subinventory Transfer','Direct Org Transfer');
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg ||'1. Invalid Transaction Type';
            log_message (l_err_msg);      
            --return l_err_msg;
      END;
      log_message ('Transaction Type Name - '|| l_transaction_type_name ||' ID - '||l_transaction_type_id);

      /* Derive the Organization_id */
      BEGIN
         SELECT organization_id
           INTO v_org_id
           FROM org_organization_definitions
          WHERE organization_code = p_org_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg ||' 2.Invalid Organization';
            log_message (l_err_msg);      
            --return l_err_msg;
      END;
      
      BEGIN
         SELECT inventory_item_id
           INTO v_inv_item_id
           FROM apps.mtl_system_items_b
          WHERE inventory_item_status_code <> 'Inactive'
            AND segment1 = p_item
            AND organization_id = v_org_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg ||' 3.Invalid Item';
            log_message (l_err_msg);      
            --return l_err_msg;

      END;

      IF p_revision IS NULL
      THEN
       --  l_err_msg := l_err_msg || ' 4.Revision is NULL';
        -- log_message (l_err_msg);
        NULL;      
         --return l_err_msg;
      END IF;

      BEGIN
         SELECT secondary_inventory_name
           INTO l_subinv_code
           FROM apps.mtl_secondary_inventories
          WHERE secondary_inventory_name = p_From_Subinventory
            AND organization_id = v_org_id;
      EXCEPTION
         WHEN OTHERS
         THEN
         l_err_msg := l_err_msg || ' 5.Invalid From Subinventory';
         log_message (l_err_msg);      
         --return l_err_msg;      
      END;

      --validating For NULL OnHand Quantity
      IF p_quantity IS NULL
      THEN
         l_err_msg := l_err_msg || ' 6.Quantity Cannot be NULL';
         log_message (l_err_msg);      
         --return l_err_msg;
      END IF;

        fnd_file.put_line
               (fnd_file.LOG,'from_subinv :'||p_From_Subinventory);


      --Validating For UOM Not Present in Base Table
      IF p_item IS NOT NULL
      THEN
         BEGIN
            SELECT primary_uom_code, shelf_life_code, lot_control_code,
                   serial_number_control_code, revision_qty_control_code,
                   location_control_code
              INTO v_primary_uom, v_shelf_life_code, v_lot_control_code,
                   v_sno_control_code, v_revision_qty_control_code,
                   l_location_control_code
              FROM apps.mtl_system_items_b
             WHERE inventory_item_status_code <> 'Inactive'
               AND inventory_item_id = v_inv_item_id
               AND primary_uom_code = p_uom
               AND organization_id = v_org_id;
         EXCEPTION
            WHEN OTHERS
            THEN
             l_err_msg := l_err_msg || ' 6.Invalid UOM';
             log_message (l_err_msg);      
             --return l_err_msg;
         END;
      END IF;


      -- Fetching Sign for Issue from stores, Receipt into stores

      BEGIN
    SELECT   DECODE (ml.meaning,
                 'Issue from stores',
                 '-',
                 'Receipt into stores',
                 '',
                 'Subinventory transfer',
                 '') INTO v_issue_receipt_sign
     FROM   apps.mfg_lookups ml, mtl_transaction_types mtt
     WHERE  ml.lookup_type = 'MTL_TRANSACTION_ACTION'
         AND ml.lookup_code = mtt.transaction_action_id
         AND mtt.transaction_type_name = l_transaction_type_name;

    log_message('v_issue_receipt_sign for transaction_type: '|| v_issue_receipt_sign ||'for'|| l_transaction_type_name);

      EXCEPTION
         WHEN OTHERS
         THEN

         l_err_msg := l_err_msg || ' 7.Error getting sign for transaction type';
         log_message (l_err_msg);      
         --return l_err_msg;
      END;



      IF (l_transaction_type_id = 31) OR (l_transaction_type_id = 41)
      THEN
      fnd_file.put_line
               (fnd_file.LOG,'Account alias issue or Account alias receipt');

      l_account_id:= NULL;
       l_account_alias_name:= NULL;
      BEGIN
      SELECT segment1, distribution_account
           INTO l_account_alias_name, l_account_id
           FROM mtl_generic_dispositions
          WHERE organization_id = v_org_id
          AND segment1= p_account_alias_name;
         fnd_file.put_line
               (fnd_file.LOG,'account_alias_name:'||l_account_alias_name);

       EXCEPTION
        WHEN OTHERS THEN
        NULL;
         l_err_msg := l_err_msg || ' 8.Invalid Dist Account';
         log_message (l_err_msg);      
         --return l_err_msg;
      END;
     END IF;

    log_message('l_account_alias_name:'|| l_account_alias_name);


    IF p_reason is not null THEN
    BEGIN
      -- Validating the Reason code
      SELECT reason_id
        INTO l_reason_id
        FROM mtl_transaction_reasons
       WHERE reason_name = p_reason;

     EXCEPTION
         WHEN OTHERS THEN
         NULL;
         l_err_msg := l_err_msg || ' 8.Invalid Reason Code';
         log_message (l_err_msg);      
         --return l_err_msg;
     END;
    END IF;



     IF p_from_locator IS NOT NULL THEN
     BEGIN
        SELECT INVENTORY_LOCATION_ID
        INTO l_locator_id
        FROM mtl_item_locations_kfv
        WHERE CONCATENATED_SEGMENTS = p_from_locator;
     EXCEPTION
         WHEN OTHERS THEN
         NULL;
         l_err_msg := l_err_msg || ' 9.Invalid From Locator';
         log_message (l_err_msg);      
         --return l_err_msg;
     END;
     END IF;
     log_message('To Locator '||p_to_locator);
     IF p_to_locator IS NOT NULL THEN
     BEGIN
     SELECT INVENTORY_LOCATION_ID
     INTO l_tranfer_locator
     FROM mtl_item_locations_kfv
     WHERE CONCATENATED_SEGMENTS = p_to_locator;
     EXCEPTION
         WHEN OTHERS THEN
         NULL;
         l_err_msg := l_err_msg || ' 10.Invalid To Locator';
         log_message (l_err_msg);      
         --return l_err_msg;
     END;
     END IF;

     -- Validate lots ---

     IF p_lot_number IS NOT NULL THEN
        SELECT 1 , expiration_date
        INTO v_lot_cnt, l_lot_expiry
        FROM MTL_LOT_NUMBERS
        WHERE lot_number = p_lot_number
        AND inventory_item_id = v_inv_item_id
        AND organization_id = v_org_id;

        IF v_lot_cnt > 0 THEN
          null;
        ELSIF v_lot_cnt=0 THEN
        l_lot_expiry := p_lot_expiry;
           inv_lot_api_pub.insertlot(p_api_version  => 1.0
                             , p_init_msg_list => fnd_api.g_true
                             , p_commit        => fnd_api.g_true
                             , p_validation_level  => fnd_api.g_valid_level_full
                             , p_inventory_item_id =>v_inv_item_id
                             , p_organization_id       => v_org_id
                             , p_lot_number    =>   p_lot_number
                             , p_expiration_date => l_lot_expiry
                             , p_transaction_temp_id => NULL
                             , p_transaction_action_id => NULL
                             , p_transfer_organization_id  => NULL
                             , x_object_id                =>p_object_id
                             , x_return_status            => l_return_status
                             , x_msg_count                =>l_msg_count
                             , x_msg_data                  =>l_msg_data  );
        ELSE
         l_err_msg := l_err_msg || ' 11.Lot exists bit not for Item and Lot Combo';
         log_message (l_err_msg);      
         --return l_err_msg;
        END IF;
     ELSIF v_lot_control_code <> 1 THEN
        IF p_lot_number IS NULL THEN
        l_err_msg := l_err_msg || ' 12.Lot Number not provied';
         log_message (l_err_msg);      
         --return l_err_msg;        
        END IF;
     END IF;

     IF p_serial_serial_number IS NOT NULL THEN
       SELECT count(*)
       INTO v_serial_cnt
       FROM mtl_serial_numbers
       WHERE serial_number = p_serial_serial_number
       AND inventory_item_id = v_inv_item_id;

       IF v_serial_cnt > 0 THEN
        NULL;
       ELSIF v_serial_cnt = 0 THEN
        NULL;
         l_serial_serial_number := p_serial_serial_number;
         inv_serial_number_pub.insertserial(p_api_version => 1.0
                                           ,p_init_msg_list => fnd_api.g_false
                                           ,p_commit => fnd_api.g_false
                                           ,p_validation_level => fnd_api.g_valid_level_full
                                           ,p_inventory_item_id => v_inv_item_id
                                           ,p_organization_id => v_org_id
                                           ,p_serial_number => l_serial_serial_number
                                           ,p_current_status  => 1
                                           ,p_group_mark_id  => -1
                                           ,p_lot_number => NULL
                                           ,p_initialization_date => SYSDATE
                                           ,x_return_status  => l_return_status
                                           ,x_msg_count  =>l_msg_count
                                           ,x_msg_data =>l_msg_data
                                           ,p_organization_type => NULL
                                           ,p_owning_org_id     => NULL
                                           ,p_owning_tp_type    => NULL
                                           ,p_planning_org_id    => NULL
                                           ,p_planning_tp_type  => NULL );
                                                      fnd_file.put_line
               (fnd_file.LOG,' Serial control Item,  New serial number is:'||l_serial_serial_number);
               
       ELSE
         l_err_msg := l_err_msg || ' 13.Invalid Serial Number';
         log_message (l_err_msg);      
         --return l_err_msg;        

       END IF;
     ELSIF v_sno_control_code <> 1 THEN
        IF p_serial_serial_number IS NULL THEN
         l_err_msg := l_err_msg || ' 14.Serial Number Cannot be blank for Serial controlled Item';
         log_message (l_err_msg);      
         --return l_err_msg;        
        END IF;
     END IF;
     
     IF l_err_msg IS NOT NULL THEN
        commit;
        log_message ('l_err_msg IS NOT NULL aborting ..');
        return  l_err_msg;
     ELSE
        l_err_msg :='SUCCESS';--NULL; -- insert interface tables --
     END IF;

    IF l_err_msg = 'SUCCESS' THEN

      IF p_quantity > 0
      THEN

      -- Fetching Transaction Interface ID from Sequence
      BEGIN
         SELECT apps.mtl_material_transactions_s.NEXTVAL
           INTO l_trans_temp_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
         l_err_msg := l_err_msg || ' 15.MTL Sequence Error';
         log_message (l_err_msg);      
         --return l_err_msg;        
      END;

      -- Fetching Source Header ID from Sequence
      BEGIN
         SELECT xx_mtl_item_source_hdr_s.NEXTVAL
           INTO l_source_header_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
         l_err_msg := l_err_msg || ' 16.HDR Sequence Error';
         log_message (l_err_msg);      
         --return l_err_msg;        
      END;
      
      

      -- Fetching Source Line ID from Sequence
      BEGIN
         SELECT xx_mtl_item_source_line_s.NEXTVAL
           INTO l_source_line_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_msg := l_err_msg || ' 16.LINE Sequence Error';
         log_message (l_err_msg);      
         --return l_err_msg;       
      END;
 
      INSERT INTO apps.mtl_transactions_interface
                        (source_code,
                         source_line_id,
                         source_header_id,
                         process_flag,
                         transaction_mode,
                         validation_required,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         organization_id,
                         transaction_quantity,
                         transaction_uom,
                         transaction_date,
                         dsp_segment1,
                         transaction_type_id,
                         inventory_item_id,
                         subinventory_code,
                         revision,
                         transaction_interface_id,
                         distribution_account_id,
                         transaction_reference,
                         scheduled_flag,
                         flow_schedule,
                         attribute3,
                         transfer_subinventory,
                         locator_id,
                         reason_id,
                         transfer_locator
                        )
                 VALUES (l_source_code,                         -- source_code
                         l_source_line_id,                      -- source_line_id
                         l_source_header_id,                    -- source_header_id
                         1,                                     -- process_flag
                         3,                                     -- transaction_mode
                         1,                                     -- validation_required
                         SYSDATE,                               -- last_update_date
                         fnd_global.user_id,                    -- last_updated_by
                         SYSDATE,                               -- creation_date
                         fnd_global.user_id,                    -- created_by
                         v_org_id,                              -- organization_id
                         v_issue_receipt_sign||p_quantity,  -- transaction_quantity
                         p_uom,                             -- transaction_uom
                         SYSDATE,                               -- transaction_date
                         l_account_alias_name,                  -- dsp_segment1
                         l_transaction_type_id,                 -- transaction_type_id
                         v_inv_item_id,                         -- inventory_item_id
                         l_subinv_code,                         -- subinventory_code
                         p_revision,                        -- revision
                         l_trans_temp_id,                       -- transaction_interface_id
                         l_account_id,                          -- distribution_account_id
                         p_REFERENCE,                       -- transaction_reference
                         NULL,
                         '2',
                      -- v_salesrep,
                      -- Added by Sridhar on 2/7/2012.Salesrep fetched from cursor
                         p_sales_rep,
                         p_To_Subinventory,                        -- Transfer_subinventory
                         l_locator_id,                           -- From Locator
                         l_reason_id,                            -- Reason id
                         l_tranfer_locator                       -- Transfer Locator
                        );

              v_mtl_trans:= v_mtl_trans + 1;


--dbms_output.put_line('Inserted data '||v_mtl_trans);
         -- Inserting into interface table
         IF     v_lot_control_code = 2
            AND v_sno_control_code = 1
                                   -- lot controlled but not serial controlled
         THEN


            fnd_file.put_line
               (fnd_file.LOG,'lot controlled but not serial controlled');


            INSERT INTO apps.mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code,
                         source_line_id,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by
                        )
                 VALUES (l_trans_temp_id,           -- transaction interface_id
                         l_source_code,             -- source code
                         l_source_line_id,          -- source line id
                         p_lot_number,          -- lot number
                         l_lot_expiry,         -- lot_Expiration_date
                         p_quantity,            -- transaction_quantity
                         SYSDATE,                   -- last_update_date
                         fnd_global.user_id,        -- last_updated_by
                         SYSDATE,                   -- creation_date
                         fnd_global.user_id         -- created_by
                        );

             v_lot_no_serial:= v_lot_no_serial + 1;

         ELSIF v_lot_control_code = 1 AND v_sno_control_code <> 1 -- Serial controlled and no lot
         THEN

         fnd_file.put_line
               (fnd_file.LOG,'Serial controlled and no lot');

            INSERT INTO apps.mtl_serial_numbers_interface
                        (transaction_interface_id,
                         source_code,
                         source_line_id,
                         fm_serial_number,
                         to_serial_number,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by
                        )
                 VALUES (l_trans_temp_id,
                         l_source_code,
                         l_source_line_id,
                         p_serial_serial_number,
                         p_serial_serial_number,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id
                        );
            v_serial_no_lot:= v_serial_no_lot + 1;
         ELSIF v_lot_control_code = 2 AND v_sno_control_code = 2
         THEN
                                                 -- lot and serial
              fnd_file.put_line(fnd_file.LOG,'-- lot and serial');
             INSERT INTO apps.mtl_serial_numbers_interface
                        (transaction_interface_id,
                         fm_serial_number,
                         to_serial_number,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by
                        )
                 VALUES (l_trans_temp_id,
                         p_serial_serial_number,
                         p_serial_serial_number,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id
                        );


               INSERT INTO apps.mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code,
                         source_line_id,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by
                        )
                 VALUES (l_trans_temp_id,           -- transaction interface_id
                         l_source_code,             -- source code
                         l_source_line_id,          -- source line id
                         p_lot_number,          -- lot number
                         DECODE (v_shelf_life_code,
                         1,
                         NULL,
                         l_lot_expiry),         -- lot_Expiration_date
                         p_quantity,            -- transaction_quantity
                         SYSDATE,                   -- last_update_date
                         fnd_global.user_id,        -- last_updated_by
                         SYSDATE,                   -- creation_date
                         fnd_global.user_id         -- created_by
                        );

              v_lot_serial:= v_lot_serial + 1;

         END IF;
      END IF;

   ELSE
        NULL;
   END IF;
   COMMIT;
 /*
 
    BEGIN
             SELECT revision_num
               INTO x_revision_num
               FROM po_headers_all
              WHERE segment1 = p_org_code;
          EXCEPTION WHEN OTHERS THEN
             x_err_msg := 'Cannot Fetch ORG_ID and PO Revision Num';
             --    raise_application_error (-20001,x_err_msg);
             return x_err_msg;
          END;
    return x_err_msg;
 */
 commit;
 IF (l_err_msg = 'SUCCESS') THEN
    return NULL;
 END IF;
 END upd_mtl_xns;
 END xx_inv_mtl_upd_adi_pkg; 
/
