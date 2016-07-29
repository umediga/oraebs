DROP PROCEDURE APPS.XX_XXOM_SET_BKDN_SER_WRAP_PKG;

CREATE OR REPLACE PROCEDURE APPS."XX_XXOM_SET_BKDN_SER_WRAP_PKG" (p_serial_number IN VARCHAR2) IS
  l_errbuf varchar2(2000);
  l_retcode number;
  cursor c is
    select   distinct mut.serial_number
                    , mmt.organization_id
                    , mmt.transfer_organization_id
                    , (select count(*)
                       from   apps.xx_set_info wdv
                       where      mut.serial_number = wdv.set_serial
                              and status_interface = 'N'
                              and lpn_name is not null
                              and batch_id = (select max(batch_id)
                                              from   apps.xx_set_info xsi
                                              where  wdv.set_serial = xsi.set_serial and status_interface = 'N' and lpn_name is not null))
                        contents
    from     apps.wsh_delivery_details wd
           , apps.wsh_delivery_assignments wda
           , apps.mtl_system_items_b msi
           , apps.mtl_material_transactions mmt
           , apps.mtl_unit_transactions mut
           , apps.wms_license_plate_numbers wlp
    where        wd.delivery_detail_id = wda.delivery_detail_id
             and wd.inventory_item_id = msi.inventory_item_id
             and 83 = msi.organization_id
             and wd.source_code = 'OE'
             and mmt.organization_id = 2103
             and mmt.picking_line_id = wd.delivery_detail_id
             and mmt.trx_source_line_id = wd.source_line_id
             and mmt.transaction_id = mut.transaction_id
             and mut.serial_number=p_serial_number
             and mut.serial_number = wlp.license_plate_number
             and nvl(wlp.subinventory_code, mmt.subinventory_code) = mmt.subinventory_code
             and delivery_id in (select wdd.delivery_id
                                 from   apps.wms_license_plate_numbers w, apps.wsh_deliverables_v wdd
                                 where      w.organization_id = 2103
                                        and subinventory_code is not null
                                        and lpn_context = 1
                                        and w.lpn_id = wdd.lpn_id
                                        and (license_plate_number like '180%' or license_plate_number like '160%')
                                        and not exists
                                              (select 1
                                               from   apps.mtl_transactions_interface i
                                               where  i.lpn_id = w.lpn_id)
                                        and not exists
                                              (select 1
                                               from   apps.mtl_material_transactions i
                                               where  i.lpn_id = w.lpn_id))
    order by mut.serial_number;
begin
  for i in c loop
    xxom_set_bkdn_ser_pkg.intg_set_bkdn_ext_prc(errbuf => l_errbuf
                                              , retcode => l_retcode
                                              , p_from_orgn_id => i.transfer_organization_id
                                              , p_to_orgn_id => i.organization_id
                                              , p_to_subinv_code => null
                                              , p_trans_date => '01-MAY-2014'
                                              , p_rec_acc_alias_name => 'KIT_EXPLOSION_150'
                                              , p_rec_tran_type_name => null
                                              , p_set_subinv_code => null
                                              , p_serial_number => i.serial_number);
  end loop;
    dbms_output.put_line('Completed Explosion of the kit' || p_serial_number);
  commit;
end;
/


GRANT EXECUTE ON APPS.XX_XXOM_SET_BKDN_SER_WRAP_PKG TO XXAPPSREAD;
