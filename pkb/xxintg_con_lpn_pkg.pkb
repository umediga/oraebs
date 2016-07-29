DROP PACKAGE BODY APPS.XXINTG_CON_LPN_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_CON_LPN_PKG" AS

FUNCTION CREATE_LPN(p_lpn_name in VARCHAR2, 
                    p_organization_id in NUMBER, 
                    p_return_status   IN  OUT  VARCHAR2,
                    p_return_code     IN  OUT     VARCHAR2,
                    p_return_message  IN  OUT  VARCHAR2)
RETURN NUMBER IS

   p_api_version_number NUMBER;
   init_msg_list VARCHAR2(30);
   x_msg_details VARCHAR2(3000);
   x_msg_summary VARCHAR2(3000);
   p_validation_level NUMBER;
   p_commit VARCHAR2(30);

   /*Handle exceptions*/
   fail_api EXCEPTION;

   x_return_status       VARCHAR2(1);
   x_msg_count           NUMBER;
   x_msg_data           VARCHAR2(1000);
   x_lpn_id NUMBER;
   
BEGIN
--- Write some validation to see if LPN already exists and or already packed

      Wms_Container_Pub.Create_LPN(
                          p_api_version => 1.0,
                          p_init_msg_list => init_msg_list,
                          p_commit => p_commit,
                          p_validation_level => p_validation_level,
                          x_return_status => x_return_status,
                          x_msg_count => x_msg_count,
                          x_msg_data => x_msg_data,
                          p_lpn             =>     p_lpn_name ,
                          p_organization_id     => p_organization_id,
                          x_lpn_id  => x_lpn_id
                          );
                          
      DBMS_OUTPUT.PUT_LINE('LPN ID:'||x_lpn_id); 
      if nvl(x_lpn_id, 0) > 0 then
             p_return_status   := 'S';
             p_return_code     := 0;
             p_return_message  := 'SUCCESS';
             return x_lpn_id;
      else
             p_return_status   := 'E';
             p_return_code     := 3;
             p_return_message  := 'ERROR creating LPN';
             return null;
      end if;
             
exception
 when others then
             
             p_return_status   := 'E';
             p_return_code     := 3;
             p_return_message  := 'ERROR creating LPN-'||sqlerrm;
             
             return null;
         
end;
      

PROCEDURE PACK_LPN(p_lpn_contents intg_t_lpn_contents_t, 
                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_code      IN  OUT     VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
                   )
IS

   k_proc_name                     CONSTANT VARCHAR2(30) := 'PACK_LPN';
   l_msg_data                      VARCHAR2(240);
   l_lpn_id                        wms_license_plate_numbers.lpn_id%TYPE;
   l_user_id                       NUMBER := Fnd_Global.user_id;
   r_mtl_txn_iface                 mtl_transactions_interface%ROWTYPE;
   r_mtl_sn_iface                  mtl_serial_numbers_interface%ROWTYPE;
   r_mtl_lot_iface                 mtl_transaction_lots_interface%ROWTYPE;
   v_transaction_id                NUMBER;
   v_ser_cnt                       NUMBER;
   v_ser_num                       VARCHAR2(100); -- BXS NUMBER;
   v_return_status                 VARCHAR2(2000);
   v_return_code                   VARCHAR2(30);
   v_return_message                VARCHAR2(2000);

   e_error                         EXCEPTION;           
/*
   CURSOR c_lpn_to_pack(cp_organization_id in number, cp_inventory_item_id in number, cp_lot_number in varchar2, cp_subinventory in varchar2, cp_locator_id in number) IS
    select 
       moq.organization_id,
       moq.subinventory_code,
       moq.locator_id, 
       moq.inventory_item_id, 
       msi.primary_uom_code uom_code,
       moq.transaction_quantity   
       from mtl_onhand_quantities_detail moq, 
            mtl_system_items msi    
     where 1=1
       and moq.inventory_item_id = msi.inventory_item_id
       and moq.organization_id = msi.organization_id
       and msi.inventory_item_id = cp_inventory_item_id
       and msi.organization_id=cp_organization_id
       and moq.subinventory_code = cp_subinventory
       and moq.locator_id = cp_locator_id
       and (moq.lot_number = cp_lot_number or cp_lot_number is null) 
      ;
*/  
   
     CURSOR c_lpn(cp_lpn_number in varchar2) IS 
     select organization_id, subinventory_code, locator_id, lpn_context, lpn_id, license_plate_number
       from wms_license_plate_numbers where license_plate_number = cp_lpn_number;
       
     CURSOR c_lpn_id(cp_lpn_id in number) IS 
     select organization_id, subinventory_code, locator_id, lpn_context, license_plate_number, lpn_id
       from wms_license_plate_numbers where lpn_id = cp_lpn_id;

     CURSOR c_serial(cp_inventory_item_id in number, cp_serial_number in varchar2) IS
     select current_organization_id, current_subinventory_code, current_locator_id, current_status, lpn_id
       from mtl_serial_numbers
      where serial_number = cp_serial_number
        and inventory_item_id = cp_inventory_item_id;  
       
     CURSOR c_item(cp_inventory_item_id in number, cp_organization_id in number) IS
     select primary_uom_code
       from mtl_system_items
      where organization_id = cp_organization_id
        and inventory_item_id = cp_inventory_item_id;  


     CURSOR c_serial_iface(cp_inventory_item_id in number, cp_organization_id in number, cp_serial_number in varchar2) IS
     select msni.process_flag, mmti.transfer_lpn_id
     from mtl_serial_numbers_interface msni, mtl_transactions_interface mmti
     where msni.fm_serial_number = cp_serial_number
       and msni.transaction_interface_id = mmti.transaction_interface_id
       and mmti.inventory_item_id = cp_inventory_item_id
       and mmti.organization_id = cp_organization_id;
        
     CURSOR c_lot_iface(cp_inventory_item_id in number, cp_organization_id number, cp_lot_number in varchar2) IS
     select mtli.process_flag, mmti.transfer_lpn_id
     from mtl_transaction_lots_interface mtli, mtl_transactions_interface mmti
     where mtli.lot_number = cp_lot_number
       and mtli.transaction_interface_id = mmti.transaction_interface_id
       and mmti.inventory_item_id = cp_inventory_item_id
       and mmti.organization_id = cp_organization_id;


--     r_lpn_to_pack c_lpn_to_pack%rowtype;
     r_lpn c_lpn%rowtype;
     r_lpn_id c_lpn_id%rowtype;
     r_serial c_serial%rowtype;
     r_lot_iface c_lot_iface%rowtype;
     r_serial_iface c_serial_iface%rowtype;

     procedure log(p_message in varchar2) is
     begin
        dbms_output.put_line(to_char(sysdate, 'yyyy/mm/dd hh24:mi:ss')||'=>'||p_message);
     end;       
        
BEGIN

   

     SELECT mtl_material_transactions_s.NEXTVAL
       INTO v_transaction_id
     FROM DUAL;
     
     log('v_transaction_id='||v_transaction_id);
   v_ser_num := NULL; 
   FOR i IN p_lpn_contents.First..p_lpn_contents.Last          
   LOOP
      r_mtl_txn_iface := NULL;      
      r_mtl_txn_iface.transaction_header_id := v_transaction_id;
      
              log('p_lpn_contents(i).inventory_item_id: '||p_lpn_contents(i).inventory_item_id);
      log('p_lpn_contents(i).organization_id: '||p_lpn_contents(i).organization_id);
      
      open c_item(p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id);
      fetch c_item into  r_mtl_txn_iface.transaction_uom;
      if c_item%notfound then
            
         v_return_code := 'E';
         v_return_message := 'Item not found';
         log(v_return_message);
         close c_item;
         raise e_error;
      
      end if;
      close c_item;
      
      log('uom: '|| r_mtl_txn_iface.transaction_uom);

      v_ser_num := p_lpn_contents(i).serial_number;
      
      log ('v_ser_num: ' || v_ser_num);

      if v_ser_num is null then
           if  p_lpn_contents(i).lpn_id is not null then
                 log ('here i am: ' || v_ser_num);
              open c_lpn_id(p_lpn_contents(i).lpn_id);
              fetch c_lpn_id into r_lpn_id;
              if c_lpn_id%notfound then
                       v_return_code := 'E';
                       v_return_message := 'Invalid LPN ID';
                       log(v_return_message);
                       close c_lpn_id;
                       raise e_error;
              else
                 if r_lpn_id.lpn_context not in (1,5) then 
                       v_return_code := 'E';
                       v_return_message := 'LPN is not in Inventory or Defined but not used context. Cannot be used to pack';
                       log(v_return_message);
                       close c_lpn_id;
                       raise e_error;
                 else
                       r_mtl_txn_iface.transfer_lpn_id := r_lpn_id.lpn_id;
                          log ('r_mtl_txn_iface.transfer_lpn_id: ' || r_mtl_txn_iface.transfer_lpn_id);
                              
                 end if;
               
              end if;
              close c_lpn_id;
            
           end if;          
                          
      else --       if v_ser_num is not null then -- Create LPN if doesn't exist or get the lpn id
             log('create lpn if it doesn''t exist');

             open c_lpn(v_ser_num);
             fetch c_lpn into r_lpn;

             if c_lpn%notfound then -- create lpm
                l_lpn_id := create_lpn(v_ser_num, p_lpn_contents(i).organization_id, v_return_status, v_return_code, v_return_message);

                if nvl(l_lpn_id, -1)  < 0 then -- Error creating LPN 
                     close c_lpn;
                     raise e_error;
                else
                     r_mtl_txn_iface.transfer_lpn_id := l_lpn_id;
                          
                end if;

             else -- LPN Exists
                 
                 if r_lpn.lpn_context not in (1,5) then 
                        
                       v_return_code := 'E';
                       v_return_message := 'LPN is not in Inventory or Defined but not used context. Cannot be used to pack';
                       log(v_return_message);
                       close c_lpn;
                       raise e_error;
                 else
                       r_mtl_txn_iface.transfer_lpn_id := r_lpn.lpn_id;
                              
                 end if;
                 
                 if r_lpn.subinventory_code is not null and r_lpn.subinventory_code <> p_lpn_contents(i).subinventory then
                       v_return_code := 'E';
                       v_return_message := 'LPN is not in Subinventory '||p_lpn_contents(i).subinventory;
                       close c_lpn;
                       raise e_error;
                 end if;
                 
                 if r_lpn.locator_id is not null and r_lpn.locator_id <> p_lpn_contents(i).locator_id then
                       v_return_code := 'E';
                       v_return_message := 'LPN is not in Locator_ID '||p_lpn_contents(i).locator_id;
                       close c_lpn;
                       raise e_error;
                 end if;
                       
              end if;
              
              close c_lpn;                           
      end if;
      

      SELECT mtl_material_transactions_s.NEXTVAL
        INTO r_mtl_txn_iface.transaction_interface_id
        FROM DUAL;
        
        log('r_mtl_txn_iface.transaction_interface_id: '|| r_mtl_txn_iface.transaction_interface_id);

          r_mtl_txn_iface.creation_date         := SYSDATE;
          r_mtl_txn_iface.created_by            := l_user_id;
          r_mtl_txn_iface.last_update_date      := SYSDATE;
          r_mtl_txn_iface.last_updated_by       := l_user_id;
          r_mtl_txn_iface.transaction_date      := SYSDATE;
          r_mtl_txn_iface.source_code           := 'AUTO PACK';
          r_mtl_txn_iface.source_line_id        := -1;
          r_mtl_txn_iface.source_header_id      := -1;
          r_mtl_txn_iface.process_flag          := 1;
          r_mtl_txn_iface.lock_flag             := 2;
          r_mtl_txn_iface.transaction_mode      := 3;
          r_mtl_txn_iface.transaction_type_id   := 87; -- Container pack
          r_mtl_txn_iface.transaction_source_id := 13;
          r_mtl_txn_iface.locator_id            := p_lpn_contents(i).locator_id;
          r_mtl_txn_iface.subinventory_code     := p_lpn_contents(i).subinventory;
          r_mtl_txn_iface.organization_id       := p_lpn_contents(i).organization_id;
          r_mtl_txn_iface.inventory_item_id     := p_lpn_contents(i).inventory_item_id;
--          r_mtl_txn_iface.transfer_lpn_id       := r_lpn_to_pack.lpn_id;
--          r_mtl_txn_iface.transaction_uom       := r_lpn_to_pack.uom_code;
          r_mtl_txn_iface.transaction_quantity  := p_lpn_contents(i).quantity;
          r_mtl_txn_iface.primary_quantity          := p_lpn_contents(i).quantity;
  
         INSERT
           INTO mtl_transactions_interface
         VALUES r_mtl_txn_iface;

         if p_lpn_contents(i).serial_number is not null then
             
             open c_serial_iface(p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id, p_lpn_contents(i).serial_number);
             fetch c_serial_iface into r_serial_iface;
             IF c_serial_iface%NOTFOUND THEN
--                log('serial not found');
--             ELSE -- BXS
                 
                 r_mtl_sn_iface  := NULL;
                 r_mtl_sn_iface.creation_date         := SYSDATE;
                 r_mtl_sn_iface.created_by            := l_user_id;
                 r_mtl_sn_iface.last_update_date      := SYSDATE;
                 r_mtl_sn_iface.last_updated_by       := l_user_id;
                 r_mtl_sn_iface.transaction_interface_id :=  r_mtl_txn_iface.transaction_interface_id;
                 r_mtl_sn_iface.fm_serial_number      := p_lpn_contents(i).serial_number;
                 r_mtl_sn_iface.to_serial_number      := p_lpn_contents(i).serial_number;
                 r_mtl_sn_iface.process_flag         :=      1;

                 INSERT
                   INTO mtl_serial_numbers_interface
                 VALUES r_mtl_sn_iface;
         
               END IF;
               
             close c_serial_iface;
             
          end if;
          
          
          if p_lpn_contents(i).lot_number is not null then 
          
                  
             open c_lot_iface(p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id, p_lpn_contents(i).lot_number);
             fetch c_lot_iface into r_lot_iface;
             IF c_lot_iface%NOTFOUND THEN
  --                           log('lot not found');
--             ELSE -- BXS
                 
                 r_mtl_lot_iface  := NULL;
                 r_mtl_lot_iface.creation_date         := SYSDATE;
                 r_mtl_lot_iface.created_by            := l_user_id;
                 r_mtl_lot_iface.last_update_date      := SYSDATE;
                 r_mtl_lot_iface.last_updated_by       := l_user_id;
                 r_mtl_lot_iface.transaction_interface_id :=  r_mtl_txn_iface.transaction_interface_id;
                 r_mtl_lot_iface.lot_number      :=           p_lpn_contents(i).lot_number;
                 r_mtl_lot_iface.transaction_quantity :=      p_lpn_contents(i).quantity;
                 r_mtl_lot_iface.process_flag         :=      1;

                 INSERT
                   INTO mtl_transaction_lots_interface
                 VALUES r_mtl_lot_iface;
         
               END IF;
               
             close c_lot_iface;
             
          end if;

      END LOOP;
      
      p_return_status    := 'S';
      p_return_code      := 0;
      p_return_message   := 'Success';

 exception
   when e_error then
        p_return_status    := v_return_status;
        p_return_code      := v_return_code;
        p_return_message   := v_return_message;

     if c_lpn%ISOPEN then
       close c_lpn;
     end if;
       
     if c_lpn_id%ISOPEN then
       close c_lpn_id;
     end if;

     if c_serial%ISOPEN then
       close c_serial;
     end if;
       
     if c_item%ISOPEN then
       close c_item;
     end if;

     if c_serial_iface%ISOPEN then
       close c_serial_iface;
     end if;
        
     if c_lot_iface%ISOPEN then
       close c_lot_iface;
     end if;
     
        
        log('Error='||p_return_message);      
        
    when others then
        p_return_status    := 'E';
        p_return_code      := 3;
        p_return_message   := sqlerrm;
        
     if c_lpn%ISOPEN then
       close c_lpn;
     end if;
       
     if c_lpn_id%ISOPEN then
       close c_lpn_id;
     end if;

     if c_serial%ISOPEN then
       close c_serial;
     end if;
       
     if c_item%ISOPEN then
       close c_item;
     end if;

     if c_serial_iface%ISOPEN then
       close c_serial_iface;
     end if;
        
     if c_lot_iface%ISOPEN then
       close c_lot_iface;
     end if;


        log('Error='||p_return_message);      
         
 END;
 
 
PROCEDURE UNPACK_LPN(p_lpn_contents intg_t_lpn_contents_t, 
                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_code      IN  OUT     VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
                   )
IS

   k_proc_name                     CONSTANT VARCHAR2(30) := 'UNPACK_LPN';
   l_msg_data                      VARCHAR2(240);
   l_lpn_id                        wms_license_plate_numbers.lpn_id%TYPE;
   l_user_id                       NUMBER := Fnd_Global.user_id;
   r_mtl_txn_iface                 mtl_transactions_interface%ROWTYPE;
   r_mtl_sn_iface                  mtl_serial_numbers_interface%ROWTYPE;
   r_mtl_lot_iface                 mtl_transaction_lots_interface%ROWTYPE;
   v_transaction_id                NUMBER;
   v_ser_cnt                       NUMBER;
   v_ser_num                       VARCHAR2(100); -- BXS NUMBER;
   v_return_status                 VARCHAR2(2000);
   v_return_code                   VARCHAR2(30);
   v_return_message                VARCHAR2(2000);

   e_error                         EXCEPTION;           
   
     CURSOR c_lpn(cp_lpn_number in varchar2) IS 
     select organization_id, subinventory_code, locator_id, lpn_context, lpn_id, license_plate_number
       from wms_license_plate_numbers where license_plate_number = cp_lpn_number;
       
     CURSOR c_lpn_id(cp_lpn_id in number) IS 
     select organization_id, subinventory_code, locator_id, lpn_context, license_plate_number, lpn_id
       from wms_license_plate_numbers where lpn_id = cp_lpn_id;

     CURSOR c_serial(cp_inventory_item_id in number, cp_serial_number in varchar2) IS
     select current_organization_id, current_subinventory_code, current_locator_id, current_status, lpn_id
       from mtl_serial_numbers
      where serial_number = cp_serial_number
        and inventory_item_id = cp_inventory_item_id;  
       
     CURSOR c_item(cp_inventory_item_id in number, cp_organization_id in number) IS
     select primary_uom_code
       from mtl_system_items
      where organization_id = cp_organization_id
        and inventory_item_id = cp_inventory_item_id;  


     CURSOR c_serial_iface(cp_inventory_item_id in number, cp_organization_id in number, cp_serial_number in varchar2) IS
     select msni.process_flag, mmti.transfer_lpn_id
     from mtl_serial_numbers_interface msni, mtl_transactions_interface mmti
     where msni.fm_serial_number = cp_serial_number
       and msni.transaction_interface_id = mmti.transaction_interface_id
       and mmti.inventory_item_id = cp_inventory_item_id
       and mmti.organization_id = cp_organization_id;
        
     CURSOR c_lot_iface(cp_inventory_item_id in number, cp_organization_id number, cp_lot_number in varchar2) IS
     select mtli.process_flag, mmti.transfer_lpn_id
     from mtl_transaction_lots_interface mtli, mtl_transactions_interface mmti
     where mtli.lot_number = cp_lot_number
       and mtli.transaction_interface_id = mmti.transaction_interface_id
       and mmti.inventory_item_id = cp_inventory_item_id
       and mmti.organization_id = cp_organization_id;


     cursor c_lpn_contents(cp_lpn_id in number, cp_inventory_item_id in number, cp_organization_id in number, cp_lot_number in varchar2) IS
     select lpn_content_id
       from wms_lpn_contents
      where parent_lpn_id = cp_lpn_id
        and inventory_item_id = cp_inventory_item_id
        and organization_id = cp_organization_id
        and nvl(lot_number, '*') = nvl(cp_lot_number, '*'); 


     CURSOR c_serial_lpn(cp_inventory_item_id in number, cp_organization_id in number, cp_lpn_id in number, cp_serial_number in varchar2) IS
     select current_organization_id, current_subinventory_code, current_locator_id, current_status, lpn_id
       from mtl_serial_numbers
      where serial_number = cp_serial_number
        and inventory_item_id = cp_inventory_item_id
        and lpn_id = cp_lpn_id;  


--     r_lpn_to_pack c_lpn_to_pack%rowtype;
     r_lpn_contents c_lpn_contents%rowtype;
     r_lpn c_lpn%rowtype;
     r_lpn_id c_lpn_id%rowtype;
     r_serial c_serial%rowtype;
     r_lot_iface c_lot_iface%rowtype;
     r_serial_iface c_serial_iface%rowtype;
     r_serial_lpn c_serial_lpn%rowtype;
     

     procedure log(p_message in varchar2) is
     begin
        dbms_output.put_line(to_char(sysdate, 'yyyy/mm/dd hh24:mi:ss')||'=>'||p_message);
     end;       
        
BEGIN

   

     SELECT mtl_material_transactions_s.NEXTVAL
       INTO v_transaction_id
     FROM DUAL;
     
     log('v_transaction_id='||v_transaction_id);
   v_ser_num := NULL; 
   FOR i IN p_lpn_contents.First..p_lpn_contents.Last          
   LOOP
      r_mtl_txn_iface := NULL;      
      r_mtl_txn_iface.transaction_header_id := v_transaction_id;

            
              log('p_lpn_contents(i).inventory_item_id: '||p_lpn_contents(i).inventory_item_id);
      log('p_lpn_contents(i).organization_id: '||p_lpn_contents(i).organization_id);
      
      open c_item(p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id);
      fetch c_item into  r_mtl_txn_iface.transaction_uom;
      if c_item%notfound then
            
         v_return_code := 'E';
         v_return_message := 'Item not found';
         log(v_return_message);
         close c_item;
         raise e_error;
      
      end if;
      close c_item;

      if  p_lpn_contents(i).lpn_id is not null then
      
              open c_lpn_id(p_lpn_contents(i).lpn_id);
              fetch c_lpn_id into r_lpn_id;
              if c_lpn_id%notfound then
                       v_return_code := 'E';
                       v_return_message := 'Invalid LPN ID';
                                log(v_return_message);
                       close c_lpn_id;
                       raise e_error;
              else
                  
                 if r_lpn_id.lpn_context not in (1,5) then 
                        
                       v_return_code := 'E';
                       v_return_message := 'LPN is not in Inventory or Defined but not used context. Cannot be used to unpack';
                                log(v_return_message);
                       close c_lpn_id;
                       raise e_error;
                 else
                       
                       if nvl(p_lpn_contents(i).locator_id, -1) <> r_lpn_id.locator_id or
                          nvl(p_lpn_contents(i).subinventory,'X') <> r_lpn_id.subinventory_code or
                          nvl(p_lpn_contents(i).organization_id,-1) <> r_lpn_id.organization_id
                       then
                          v_return_code := 'E';
                          v_return_message := 'LPN is not in Same Subinventory/Locator/Organization as requested. Cannot unpack';
                                   log(v_return_message);
                          close c_lpn_id;
                          raise e_error;
                       end if;       
                       
                       r_mtl_txn_iface.lpn_id            := r_lpn_id.lpn_id;
                       r_mtl_txn_iface.locator_id        := p_lpn_contents(i).locator_id;
                       r_mtl_txn_iface.subinventory_code := p_lpn_contents(i).subinventory;
                       r_mtl_txn_iface.organization_id   := p_lpn_contents(i).organization_id;
                       
                              
                 end if;
               
              end if;
              close c_lpn_id;
            
--         end if;          
                          
      else --       if v_ser_num is not null then -- Create LPN if doesn't exist or get the lpn id

           v_ser_num := p_lpn_contents(i).serial_number;
           if v_ser_num is not null then
             open c_lpn(v_ser_num);
             fetch c_lpn into r_lpn;
                 
                 open c_serial_lpn(p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id, r_lpn.lpn_id, p_lpn_contents(i).serial_number);
                 fetch c_serial_lpn into r_serial_lpn;
                 if c_serial_lpn%notfound then
                       v_return_code := 'E';
                       v_return_message := 'Serial Number is not packed in LPN. Cannot unpack';
                                log(v_return_message);
                       close c_serial_lpn;
                       close c_lpn;
                       
                       raise e_error;
                 else
                       close c_serial_lpn; 
                 end if;                     

                 if r_lpn.lpn_context not in (1,5) then 
                        
                       v_return_code := 'E';
                       v_return_message := 'LPN is not in Inventory or Defined but not used context. Cannot be used to unpack';
                                log(v_return_message);
                       close c_lpn;
                       raise e_error;
                 else
                       
                       if nvl(p_lpn_contents(i).locator_id, -1) <> r_lpn.locator_id or
                          nvl(p_lpn_contents(i).subinventory,'X') <> r_lpn.subinventory_code or
                          nvl(p_lpn_contents(i).organization_id,-1) <> r_lpn.organization_id
                       then
                          v_return_code := 'E';
                          v_return_message := 'LPN is not in Same Subinventory/Locator/Organization as requested. Cannot unpack';
                                   log(v_return_message);
                          close c_lpn;
                          raise e_error;
                       end if;       
                       
                       r_mtl_txn_iface.lpn_id            := r_lpn.lpn_id;
                       r_mtl_txn_iface.locator_id        := p_lpn_contents(i).locator_id;
                       r_mtl_txn_iface.subinventory_code := p_lpn_contents(i).subinventory;
                       r_mtl_txn_iface.organization_id   := p_lpn_contents(i).organization_id;

                              
                 end if;                                        
              
              close c_lpn;
           else

                          v_return_code := 'E';
                          v_return_message := 'LPN and serial number both are null, unable to derive LPN to unpack';
                                   log(v_return_message);
                          raise e_error;
           end if;               
                                              
      end if;
      
      open c_lpn_contents(r_mtl_txn_iface.lpn_id, p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id, p_lpn_contents(i).lot_number);
      fetch c_lpn_contents into r_lpn_contents;
      if c_lpn_contents%notfound then
         v_return_code := 'E';
         v_return_message := 'Item is not packed in the given LPN, cannot unpack';
                  log(v_return_message);
         close c_lpn_contents;
         raise e_error;
      end if;   
      close c_lpn_contents;      

      SELECT mtl_material_transactions_s.NEXTVAL
        INTO r_mtl_txn_iface.transaction_interface_id
        FROM DUAL;

          r_mtl_txn_iface.creation_date         := SYSDATE;
          r_mtl_txn_iface.created_by            := l_user_id;
          r_mtl_txn_iface.last_update_date      := SYSDATE;
          r_mtl_txn_iface.last_updated_by       := l_user_id;
          r_mtl_txn_iface.transaction_date      := SYSDATE;
          r_mtl_txn_iface.source_code           := 'AUTO UNPACK';
          r_mtl_txn_iface.source_line_id        := -1;
          r_mtl_txn_iface.source_header_id      := -1;
          r_mtl_txn_iface.process_flag          := 1;
          r_mtl_txn_iface.lock_flag             := 2;
          r_mtl_txn_iface.transaction_mode      := 3;
          r_mtl_txn_iface.transaction_type_id   := 88; -- Container unpack
          r_mtl_txn_iface.transaction_source_id := 13;
          r_mtl_txn_iface.inventory_item_id     := p_lpn_contents(i).inventory_item_id;
--          r_mtl_txn_iface.transfer_lpn_id       := r_lpn_to_pack.lpn_id;
--          r_mtl_txn_iface.transaction_uom       := r_lpn_to_pack.uom_code;
          r_mtl_txn_iface.transaction_quantity  := p_lpn_contents(i).quantity;
          r_mtl_txn_iface.primary_quantity          := p_lpn_contents(i).quantity;
  
         INSERT
           INTO mtl_transactions_interface
         VALUES r_mtl_txn_iface;

         if p_lpn_contents(i).serial_number is not null then
             
             open c_serial_iface(p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id, p_lpn_contents(i).serial_number);
             fetch c_serial_iface into r_serial_iface;
             IF c_serial_iface%NOTFOUND THEN
--                     log('Not Adding Serial Info');
--             ELSE
                     log(' Adding Serial Info');
                 r_mtl_sn_iface  := NULL;
                 r_mtl_sn_iface.creation_date         := SYSDATE;
                 r_mtl_sn_iface.created_by            := l_user_id;
                 r_mtl_sn_iface.last_update_date      := SYSDATE;
                 r_mtl_sn_iface.last_updated_by       := l_user_id;
                 r_mtl_sn_iface.transaction_interface_id :=  r_mtl_txn_iface.transaction_interface_id;
                 r_mtl_sn_iface.fm_serial_number      := p_lpn_contents(i).serial_number;
                 r_mtl_sn_iface.to_serial_number      := p_lpn_contents(i).serial_number;
                 r_mtl_sn_iface.process_flag         :=      1;

                 INSERT
                   INTO mtl_serial_numbers_interface
                 VALUES r_mtl_sn_iface;
                 log('Done Adding Serial Info');
               END IF;
               
             close c_serial_iface;
             
          end if;
          
          
          if p_lpn_contents(i).lot_number is not null then 
          
                  
             open c_lot_iface(p_lpn_contents(i).inventory_item_id, p_lpn_contents(i).organization_id, p_lpn_contents(i).lot_number);
             fetch c_lot_iface into r_lot_iface;
             IF c_lot_iface%NOTFOUND THEN
--                 log('Not Adding Lot Info');
--             ELSE -- BXS
                 log('Adding Lot Info');
                 r_mtl_lot_iface  := NULL;
                 r_mtl_lot_iface.creation_date         := SYSDATE;
                 r_mtl_lot_iface.created_by            := l_user_id;
                 r_mtl_lot_iface.last_update_date      := SYSDATE;
                 r_mtl_lot_iface.last_updated_by       := l_user_id;
                 r_mtl_lot_iface.transaction_interface_id :=  r_mtl_txn_iface.transaction_interface_id;
                 r_mtl_lot_iface.lot_number      :=           p_lpn_contents(i).lot_number;
                 r_mtl_lot_iface.transaction_quantity :=      p_lpn_contents(i).quantity;
                 r_mtl_lot_iface.process_flag         :=      1;

                 INSERT
                   INTO mtl_transaction_lots_interface
                 VALUES r_mtl_lot_iface;
         
               END IF;
                                log('Done Adding Lot Info');
               
             close c_lot_iface;
             
          end if;

      END LOOP;
      
      p_return_status    := 'S';
      p_return_code      := 0;
      p_return_message   := 'Success';
      
 exception
   when e_error then
        p_return_status    := v_return_status;
        p_return_code      := v_return_code;
        p_return_message   := v_return_message;
        
     if c_lpn%ISOPEN then
       close c_lpn;
     end if;
       
     if c_lpn_id%ISOPEN then
       close c_lpn_id;
     end if;

     if c_serial%ISOPEN then
       close c_serial;
     end if;
       
     if c_item%ISOPEN then
       close c_item;
     end if;

     if c_serial_iface%ISOPEN then
       close c_serial_iface;
     end if;
        
     if c_lot_iface%ISOPEN then
       close c_lot_iface;
     end if;

     if c_lpn_contents%ISOPEN then
       close c_lpn_contents;
     end if;

     if c_serial_lpn%ISOPEN then
       close c_serial_lpn;
     end if;
     


        log('Error='||p_return_message);      
        
    when others then
        p_return_status    := 'E';
        p_return_code      := 3;
        p_return_message   := sqlerrm;
        

        log('Error='||p_return_message);      
         
 END;

                    

END; 
/
