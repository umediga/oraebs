DROP PACKAGE BODY APPS.INTG_SLA_DETAILS_RPT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."INTG_SLA_DETAILS_RPT_PKG" as
  procedure debug(p_msg in varchar2) is
  begin
    dbms_output.put_line(p_msg);
    fnd_file.put_line(fnd_file.log, p_msg);
  end;

  procedure cleanup_staging_tables(errbuf out varchar2, retcode out number, p_report_request_id in number) is
  begin
    debug('cleanup_staging_tables()+');
    --debug(  'pg_retain_staging_flag :'||pg_retain_staging_flag );
    delete from xx_sla_ae_lines
    where       parent_request_id = p_report_request_id;
    delete from xx_sla_gl_ccids
    where       parent_request_id = p_report_request_id;
    delete from xx_sla_ae_lines_gt
    where       parent_request_id = p_report_request_id;
    debug('cleanup_staging_tables()-');
  end cleanup_staging_tables;

  function get_project_number(p_project_id in number)
    return varchar2 is
    l_project_number varchar2(400);
  begin
    select project_number
    into   l_project_number
    from   pa_proj_all_basic_un_sec_v
    where  project_id = p_project_id;
    return l_project_number;
  exception
    when others then
      return null;
  end;

  function get_task_number(p_task_id in number)
    return varchar2 is
    l_task_number varchar2(400);
  begin
    select task_number
    into   l_task_number
    from   pa_tasks
    where  task_id = p_task_id;
    return l_task_number;
  exception
    when others then
      return null;
  end;

  function get_exp_org_name(p_exp_org_id in number)
    return varchar2 is
    l_org_name varchar2(400);
  begin
    select name
    into   l_org_name
    from   hr_organization_units
    where  organization_id = p_exp_org_id;
    return l_org_name;
  exception
    when others then
      return null;
  end;

  function tracking_numbers(p_customer_trx_id in number)
    return varchar2 is
    type t_array_char is table of varchar2(80)
                           index by binary_integer;

    l_conc_seg_delimiter varchar2(80);
    l_concat_tracking_nos varchar2(4000);
    l_array t_array_char;

    cursor c is
      select distinct interface_line_attribute4
      from   ra_customer_trx_lines_all
      where      customer_trx_id = p_customer_trx_id
             and interface_line_context = 'ORDER ENTRY'
             and line_type = 'LINE'
             and nvl(interface_line_attribute4, '~') <> '0';
  begin
    open c;
    fetch c
    bulk collect into l_array;
    close c;

    for i in 1 .. l_array.count loop
      l_concat_tracking_nos := l_concat_tracking_nos || l_array(i);

      if i < l_array.count then
        l_concat_tracking_nos := l_concat_tracking_nos || ' , ';
      end if;
    end loop;

    return l_concat_tracking_nos;
  exception
    when others then
      return null;
  end tracking_numbers;

  procedure update_cst_info is
  begin
    debug('----<<Entering update_cst_info>>------------');
    debug('----<<Script for updating WIP Job Number>>------------');
    update xx_sla_ae_lines xx
    set    cst_source_number = cst_wip_entity
    where      application_id = 707
           and entity_code = 'WIP_ACCOUNTING_EVENTS'
           and cst_source_number is null
           and cst_wip_entity is not null
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('----<<Script for updating variance quantity for flow schedules>>------------');
    update xx_sla_ae_lines xx
    set    cst_primary_quantity = (select sum(wfs.quantity_completed)
                                   from   wip_transactions b, wip_entities c, wip_flow_schedules wfs
                                   where      xx.cst_transaction_id = b.transaction_id
                                          and b.wip_entity_id = c.wip_entity_id
                                          and c.wip_entity_id = wfs.wip_entity_id
                                          and c.organization_id = wfs.organization_id
                                          and c.entity_type = 4)
    where      entity_code = 'WIP_ACCOUNTING_EVENTS'
           and event_class_code = 'VARIANCE'
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('----<<Script for updating Variance Quantty for move transactions>>------------');
    update xx_sla_ae_lines xx
    set    cst_primary_quantity = (select sum(wmt.primary_quantity)
                                   from   wip_entities b, mtl_parameters mp, wip_move_transactions wmt
                                   where      xx.cst_organization_code = mp.organization_code
                                          and b.organization_id = mp.organization_id
                                          and xx.cst_wip_entity = b.wip_entity_name
                                          and b.wip_entity_id = wmt.wip_entity_id
                                          and b.primary_item_id = wmt.primary_item_id
                                          and b.organization_id = wmt.organization_id
                                          and b.entity_type in (1, 3))
    where      entity_code = 'WIP_ACCOUNTING_EVENTS'
           and event_class_code = 'VARIANCE'
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('----<<Script for updating WIP transaction source type>>------------');
    update xx_sla_ae_lines xx
    set    cst_trx_source_type = (select meaning
                                  from   wip_entities we, mtl_parameters mp, mfg_lookups mfg
                                  where      xx.cst_wip_entity = we.wip_entity_name
                                         and xx.cst_organization_code = mp.organization_code
                                         and we.organization_id = mp.organization_id
                                         and we.entity_type = mfg.lookup_code
                                         and mfg.lookup_type = 'WIP_ENTITY')
    where  entity_code = 'WIP_ACCOUNTING_EVENTS' and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('----<<Script for updating WIP transaction type>>------------');
    update xx_sla_ae_lines xx
    set    cst_transaction_type = (select meaning
                                   from   wip_transactions wt, mfg_lookups mfg
                                   where      xx.cst_transaction_id = wt.transaction_id
                                          and wt.transaction_type = mfg.lookup_code
                                          and mfg.lookup_type = 'WIP_TRANSACTION_TYPE')
    where  entity_code = 'WIP_ACCOUNTING_EVENTS' and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('----------------<<entering update_po_info>>-------------------------------');
    debug('------<<Update script for Expense Destinaton POs>>------');
    update xx_sla_ae_lines xx
    set    (cst_project_number
          , cst_po_task_number
          , cst_po_exp_org_name
          , cst_po_exp_type
          , cst_po_line_number
          , cst_receipt_date
          , cst_receipt_num
          , cst_party_type
          , cst_party_name
          , cst_party_number
          , cst_item_description
          , cst_trx_source_type
          , cst_transaction_type) = (select max(intg_sla_details_rpt_pkg.get_project_number(pod.project_id))
                                          , max(intg_sla_details_rpt_pkg.get_task_number(pod.task_id))
                                          , max(intg_sla_details_rpt_pkg.get_exp_org_name(pod.expenditure_organization_id))
                                          , max(pod.expenditure_type), max(pol.line_num), max(trunc(rsh.creation_date))
                                          , max(rsh.receipt_num), max('Supplier'), max(vendor_name), max(aps.segment1)
                                          , max(pol.item_description), max('Receiving'), max(fl.meaning)
                                     from   po_distributions_all pod
                                          , po_lines_all pol
                                          , rcv_transactions rcv
                                          , rcv_shipment_headers rsh
                                          , po_headers_all poh
                                          , ap_suppliers aps
                                          , fnd_lookup_values_vl fl
                                     where      xx.cst_transaction_id = rcv.transaction_id
                                            and rcv.transaction_type = fl.lookup_code
                                            --and pod.destination_type_code = 'EXPENSE'
                                            --and pod.destination_context = 'EXPENSE'
                                            and pol.po_header_id = poh.po_header_id
                                            and poh.vendor_id = aps.vendor_id
                                            and pod.po_line_id = pol.po_line_id
                                            and pod.line_location_id = rcv.po_line_location_id
                                            and rcv.shipment_header_id = rsh.shipment_header_id
                                            and fl.lookup_type = 'RCV TRANSACTION TYPE')
    where      entity_code = 'RCV_ACCOUNTING_EVENTS' --and event_class_code = 'DELIVER_EXPENSE'
           and application_id = 707
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('------<<Update script for PO for Inventory destination>>------');
    update xx_sla_ae_lines xx
    set    (cst_project_number
          , cst_po_task_number
          , cst_po_exp_org_name
          , cst_po_exp_type
          , cst_po_line_number
          , cst_receipt_date
          , cst_receipt_num
          , cst_party_type
          , cst_party_name
          , cst_party_number
          , cst_item_description) = (select max(intg_sla_details_rpt_pkg.get_project_number(pod.project_id))
                                          , max(intg_sla_details_rpt_pkg.get_task_number(pod.task_id))
                                          , max(intg_sla_details_rpt_pkg.get_exp_org_name(pod.expenditure_organization_id))
                                          , max(pod.expenditure_type), max(pol.line_num), max(trunc(rsh.creation_date))
                                          , max(rsh.receipt_num), max('Supplier'), max(vendor_name), max(aps.segment1)
                                          , max(pol.item_description)
                                     from   po_distributions_all pod
                                          , rcv_transactions rcv
                                          , po_headers_all poh
                                          , po_lines_all pol
                                          , mtl_material_transactions mmt
                                          , rcv_shipment_headers rsh
                                          , ap_suppliers aps
                                     where      xx.cst_transaction_id = mmt.transaction_id
                                            and mmt.rcv_transaction_id = rcv.transaction_id
                                            and pod.po_distribution_id = rcv.po_distribution_id
                                            and mmt.transaction_source_type_id = 1
                                            and pod.po_line_id = pol.po_line_id
                                            and pol.po_header_id = poh.po_header_id
                                            and rcv.shipment_header_id = rsh.shipment_header_id
                                            and poh.vendor_id = aps.vendor_id)
    where      entity_code = 'MTL_ACCOUNTING_EVENTS'
           and event_class_code = 'PURCHASE_ORDER'
           and application_id = 707
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('------<<Update script for PO for Accrual Write off destination>>------');
    update xx_sla_ae_lines xx
    set    (cst_project_number
          , cst_po_task_number
          , cst_po_exp_org_name
          , cst_po_exp_type
          , cst_po_line_number
          , cst_party_type
          , cst_party_name
          , cst_party_number) = (select max(intg_sla_details_rpt_pkg.get_project_number(pod.project_id))
                                      , max(intg_sla_details_rpt_pkg.get_task_number(pod.task_id))
                                      , max(intg_sla_details_rpt_pkg.get_exp_org_name(pod.expenditure_organization_id))
                                      , max(pod.expenditure_type), max(pol.line_num), max('Supplier'), max(aps.vendor_name)
                                      , max(aps.segment1)
                                 from   po_distributions_all pod, cst_write_offs wrt, po_headers_all poh, po_lines_all pol, ap_suppliers aps
                                 where      xx.cst_write_off_id = wrt.write_off_id
                                        and pod.po_distribution_id = wrt.po_distribution_id
                                        and pod.po_line_id = pol.po_line_id
                                        and pol.po_header_id = poh.po_header_id
                                        and poh.vendor_id = aps.vendor_id)
    where      entity_code = 'WO_ACCOUNTING_EVENTS'
           and application_id = 707
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('------<<Update script for PO for Shopfloor destination>>------');
    update xx_sla_ae_lines xx
    set    (cst_project_number
          , cst_po_task_number
          , cst_po_exp_org_name
          , cst_po_exp_type
          , cst_po_line_number
          , cst_receipt_date
          , cst_receipt_num
          , cst_party_type
          , cst_party_name
          , cst_party_number) = (select max(intg_sla_details_rpt_pkg.get_project_number(pod.project_id))
                                      , max(intg_sla_details_rpt_pkg.get_task_number(pod.task_id))
                                      , max(intg_sla_details_rpt_pkg.get_exp_org_name(pod.expenditure_organization_id))
                                      , max(pod.expenditure_type), max(pol.line_num), max(trunc(rsh.creation_date)), max(rsh.receipt_num)
                                      , max('Supplier'), max(aps.vendor_name), max(aps.segment1)
                                 from   po_distributions_all pod
                                      , wip_transactions wip
                                      , po_headers_all poh
                                      , po_lines_all pol
                                      , rcv_shipment_headers rsh
                                      , rcv_transactions rcv
                                      , ap_suppliers aps
                                 where      xx.cst_transaction_id = wip.transaction_id
                                        and wip.rcv_transaction_id is not null
                                        and wip.rcv_transaction_id = rcv.transaction_id
                                        and rcv.shipment_header_id = rsh.shipment_header_id
                                        and pod.po_distribution_id = rcv.po_distribution_id
                                        and pod.po_line_id = pol.po_line_id
                                        and pol.po_header_id = poh.po_header_id
                                        and poh.vendor_id = aps.vendor_id)
    where      entity_code = 'WIP_ACCOUNTING_EVENTS'
           and event_class_code = 'OSP'
           and application_id = 707
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('------<<Update script for Transaction source Type>>------');
    update xx_sla_ae_lines xx
    set    cst_trx_source_type = (select transaction_source_type_name
                                  from   mtl_txn_source_types mts
                                  where  xx.cst_transaction_source_type_id = mts.transaction_source_type_id)
    where  entity_code = 'MTL_ACCOUNTING_EVENTS' and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('------<<Update script for WIP Assembly item number>>------');
    update xx_sla_ae_lines
    set    cst_item_name = cst_assembly_name
    where      cst_item_name is null
           and entity_code = 'WIP_ACCOUNTING_EVENTS'
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('------<<Update script for Primary UOM>>------');
    update xx_sla_ae_lines xx
    set    (cst_primary_unit_of_measure) = (select primary_unit_of_measure
                                            from   mtl_system_items_b msi
                                            where  organization_id = 83 and xx.cst_item_name = msi.segment1)
    where  cst_primary_unit_of_measure is null and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('------<<Update script for CST Item description>>------');
    update xx_sla_ae_lines xx
    set    (cst_item_description) = (select description
                                     from   mtl_system_items_b msi
                                     where  organization_id = 83 and xx.cst_item_name = msi.segment1)
    where  cst_item_description is null and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('------<<Update script for Expense PO Number>>------');
    update xx_sla_ae_lines xx
    set    cst_trx_source_type = case
                                   when event_class_code = 'DELIVER_EXPENSE' then 'Expense Purchase'
                                   else 'Material Purchase'
                                 end
         , cst_source_number = cst_po_number
    where  entity_code = 'RCV_ACCOUNTING_EVENTS' --and event_class_code = 'DELIVER_EXPENSE'
                                                and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('------<<Update script for Party for Cost Management>>------');
    update xx_sla_ae_lines xx
    set    (cst_party_type
          , cst_party_number
          , cst_party_name) = (select 'Customer', hca.account_number, hp.party_name
                               from   oe_order_lines_all oel, hz_cust_accounts hca, hz_parties hp, mtl_material_transactions mmt
                               where      oel.sold_to_org_id = hca.cust_account_id
                                      and hca.party_id = hp.party_id
                                      and xx.cst_transaction_id = mmt.transaction_id
                                      and mmt.trx_source_line_id = oel.line_id
                                      and (mmt.transaction_source_type_id in (2, 8, 12)
                                           or (mmt.transaction_source_type_id = 13 and mmt.transaction_type_id in (10, 11, 13, 14))))
    where      (source_id_int_2 in (2, 8, 12) or (source_id_int_2 = 13 and source_id_int_3 in (10, 11, 13, 14)))
           and application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Purchase order number
    debug('------<<Update script for PO Number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select poh.segment1
                                from   po_headers_all poh, mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and poh.po_header_id = mmt.transaction_source_id
                                       and mmt.transaction_source_type_id = 1)
    where      application_id = 707
           and entity_code in ('MTL_ACCOUNTING_EVENTS', 'RCV_ACCOUNTING_EVENTS')
           and cst_transaction_source_type_id = 1
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Sales Order Number
    debug('------<<Update script for SO Number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select mso.concatenated_segments
                                from   mtl_sales_orders_kfv mso, mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mso.sales_order_id = mmt.transaction_source_id
                                       and mmt.transaction_source_type_id in (2, 8, 12))
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id in (2, 8, 12)
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Move Order Number
    debug('------<<Update script for Move Order Number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select concatenated_segments
                                from   mtl_txn_request_headers mrh, mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mrh.header_id = mmt.transaction_source_id
                                       and mmt.transaction_source_type_id = 4)
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 4
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Work Order Number for WIP Completion
    debug('------<<Update script for WO Number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = nvl(cst_wip_entity
                                 , (select max(wip_entity_name)
                                    from   wip_entities we, mtl_material_transactions mmt
                                    where      xx.cst_transaction_id = mmt.transaction_id
                                           and we.wip_entity_id = mmt.transaction_source_id
                                           and mmt.transaction_source_type_id = 5))
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 5
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Account Alias
    debug('------<<Update script for Account Alias for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select max(mgd.concatenated_segments)
                                from   mtl_generic_dispositions_kfv mgd, mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mgd.disposition_id = mmt.transaction_source_id
                                       and mgd.organization_id = mmt.organization_id
                                       and mmt.transaction_source_type_id = 6)
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 6
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Internal Requisition number
    debug('------<<Update script for internal requisition Number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select max(prh.segment1)
                                from   po_requisition_headers_all prh
                                     , mtl_material_transactions mmt
                                     , po_requisition_lines_all prl
                                     , rcv_transactions rcv
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mmt.rcv_transaction_id = rcv.transaction_id
                                       and rcv.requisition_line_id = prl.requisition_line_id
                                       and prl.requisition_header_id = prh.requisition_header_id
                                       and rcv.source_document_code = 'REQ'
                                       and mmt.transaction_source_type_id = 7)
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 7
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Cycle Counting ref number
    debug('------<<Update script for Cycle Counting number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select max(cycle_count_header_name)
                                from   mtl_cycle_count_headers mcc, mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mmt.transaction_source_id = mcc.cycle_count_header_id
                                       and mmt.organization_id = mcc.organization_id
                                       and mmt.transaction_source_type_id = 9)
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 9
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Physical Inventory
    debug('------<<Update script for Physical Inventory Counting number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select max(physical_inventory_name)
                                from   mtl_physical_inventories mpi, mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mmt.transaction_source_id = mpi.physical_inventory_id
                                       and mmt.organization_id = mpi.organization_id
                                       and mmt.transaction_source_type_id = 10)
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 10
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Logical SO Nmber?
    debug('------<<Update script for Sales Order number for Logical transactions in Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select max(mso.concatenated_segments)
                                from   mtl_material_transactions mmt, mtl_sales_orders_kfv mso
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mmt.transaction_source_type_id = 13
                                       and mmt.transaction_type_id in (10, 11, 13, 14)
                                       and mso.sales_order_id = mmt.transaction_source_id)
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 13
           and cst_transaction_type in (select transaction_type_name
                                        from   mtl_transaction_types
                                        where  transaction_type_id in (10, 11, 13, 14))
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --Shipment Number
    debug('------<<Update script for Shipment number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select nvl(mmt.shipment_number, mmt.source_code)
                                from   mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mmt.transaction_source_type_id = 13
                                       and mmt.transaction_type_id in (3, 12, 21))
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 13
           and cst_transaction_type in (select transaction_type_name
                                        from   mtl_transaction_types
                                        where  transaction_type_id in (3, 12, 21))
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    --generic transaction reference number
    debug('------<<Update script for transaction reference number for Cost management>>------');
    update xx_sla_ae_lines xx
    set    cst_source_number = (select max(transaction_reference)
                                from   mtl_material_transactions mmt
                                where      xx.cst_transaction_id = mmt.transaction_id
                                       and mmt.transaction_source_type_id = 13
                                       and mmt.transaction_type_id = 2)
    where      application_id = 707
           and entity_code = 'MTL_ACCOUNTING_EVENTS'
           and cst_transaction_source_type_id = 13
           and cst_transaction_type in (select transaction_type_name
                                        from   mtl_transaction_types
                                        where  transaction_type_id = 2)
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('----<<Exiting update_cst_info>>------------');
  exception
    when others then
      debug('----<<exception in update_cst_info>>------------');
      debug(sqlerrm);
      debug('----<<Exiting update_cst_info>>------------');
  end;

  procedure update_ap_info is
  begin
    debug('----------------<<entering update_ap_info>>-------------------------------');
    debug('----------------<<entering vendor information for invoices>>-------------------------------');
    update xx_sla_ae_lines a
    set    (ap_vendor_number
          , ap_voucher_number
          , ap_vendor_name) = (select vendor_number, doc_sequence_value, vendor_name
                               from   ap_invoices_v ap
                               where  a.ap_invoice_id = ap.invoice_id)
    where  entity_code = 'AP_INVOICES' and a.application_id = 200 and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('----------------<<entering vendor information for checks>>-------------------------------');
    update xx_sla_ae_lines a
    set    (ap_vendor_number
          , ap_check_voucher_number
          , ap_vendor_name) = (select vendor_number, check_voucher_num, vendor_name
                               from   ap_checks_v ap
                               where  a.ap_check_id = ap.check_id)
    where  entity_code = 'AP_PAYMENTS' and application_id = 200 and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('----------------<<Update Matched PO Numbers>>-------------------------------');
    update xx_sla_ae_lines xx
    set    (ap_po_number
          , ap_po_line_number) = (select max(poh.segment1), max(pol.line_num)
                                  from   po_distributions_all pod
                                       , po_line_locations_all poll
                                       , po_lines_all pol
                                       , po_headers_all poh
                                       , ap_invoice_distributions_all apid
                                       , ap_invoice_lines_all ail ----added fo rthe CASE #10362 
                                  where      xx.ap_invoice_id = apid.invoice_id 
                                         and pod.po_distribution_id = apid.po_distribution_id
                                         and pod.line_location_id = poll.line_location_id
                                         and poll.po_line_id = pol.po_line_id
                                         and pol.po_header_id = poh.po_header_id
                                         and apid.invoice_id = ail.invoice_id ----added forthe CASE #10362 
                                         and ail.line_number = xx.ae_line_num  ----added fo rthe CASE #10362 
                                         and ail.po_header_id = poh.po_header_id(+) ----added forthe CASE #10362 
                                           and ail.po_line_id = pol.po_line_id(+) ----added forthe CASE #10362 
                                           )
    where  application_id = 200 and entity_code = 'AP_INVOICES' and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('----------------<<Update P O E T Information for AP>>-------------------------------');
    update xx_sla_ae_lines xx
    set    (ap_project_number
          , ap_task_number
          , ap_expenditure_type
          , ap_expenditure_org_name) = (select max(intg_sla_details_rpt_pkg.get_project_number(apid.project_id))
                                             , max(intg_sla_details_rpt_pkg.get_task_number(apid.task_id)), max(apid.expenditure_type)
                                             , max(intg_sla_details_rpt_pkg.get_exp_org_name(apid.expenditure_organization_id))
                                        from   ap_invoice_distributions_all apid
                                        where  xx.ap_invoice_id = apid.invoice_id)
    --where  xx.source_distribution_id_num_1 = apid.invoice_distribution_id)
    where  application_id = 200 --and source_distribution_type = 'AP_INV_DIST'
           and entity_code = 'AP_INVOICES' and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('-----------------<<exiting update_ap_info>>-----------------------');
  exception
    when others then
      debug('-----------<<exception occured in update_ap_info>>-----------------------');
      debug('Exception is: ' || sqlerrm);
  end;

  procedure update_ar_info is
    cursor c is
      select distinct ar_customer_trx_id
      from   xx_sla_ae_lines
      where  entity_code = 'TRANSACTIONS' and application_id = 222 and parent_request_id = g_parent_request_id and worker_id = g_worker_id;

    l_tracking_nos varchar2(4000);
  begin
    debug('----------------<<entering update_ar_trx_info>>-------------------------------');
    update xx_sla_ae_lines a
    set    ar_trx_reference = (select case
                                        when rab.default_reference = 1 then rat.interface_header_attribute1
                                        when rab.default_reference = 2 then rat.interface_header_attribute2
                                        when rab.default_reference = 3 then rat.interface_header_attribute3
                                        when rab.default_reference = 4 then rat.interface_header_attribute4
                                        when rab.default_reference = 5 then rat.interface_header_attribute5
                                        when rab.default_reference = 6 then rat.interface_header_attribute6
                                        when rab.default_reference = 7 then rat.interface_header_attribute7
                                        when rab.default_reference = 8 then rat.interface_header_attribute8
                                        when rab.default_reference = 9 then rat.interface_header_attribute9
                                        when rab.default_reference = 10 then rat.interface_header_attribute10
                                        when rab.default_reference = 11 then rat.interface_header_attribute11
                                        when rab.default_reference = 12 then rat.interface_header_attribute12
                                        when rab.default_reference = 13 then rat.interface_header_attribute13
                                        when rab.default_reference = 14 then rat.interface_header_attribute14
                                        when rab.default_reference = 15 then rat.interface_header_attribute15
                                      end
                               from   ra_customer_trx_all rat, ra_batch_sources_all rab
                               where      a.ar_customer_trx_id = rat.customer_trx_id
                                      and rat.batch_source_id = rab.batch_source_id
                                      and rab.default_reference is not null)
    where  entity_code = 'TRANSACTIONS' and application_id = 222 and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    update xx_sla_ae_lines a
    set    (ar_cash_receipt_batch_name
          , ar_cash_receipt_batch_date) = (select arb.name, arb.batch_date
                                           from   ar_cash_receipts_v arc, ar_batches_all arb
                                           where  a.ar_cash_receipt_id = arc.cash_receipt_id and arc.batch_id = arb.batch_id)
    where  entity_code = 'RECEIPTS' and a.application_id = 222 and parent_request_id = g_parent_request_id and worker_id = g_worker_id;

    for i in c loop
      l_tracking_nos := null;
      l_tracking_nos := tracking_numbers(i.ar_customer_trx_id);
      update xx_sla_ae_lines a
      set    ar_tracking_numbers = l_tracking_nos
      where      entity_code = 'TRANSACTIONS'
             and application_id = 222
             and parent_request_id = g_parent_request_id
             and worker_id = g_worker_id
             and entity_id = i.ar_customer_trx_id;
    end loop;
  end;

  procedure update_fa_info is
  begin
    debug('----------------<<entering update_fa_info>>-------------------------------');
    debug('----------------<<deleting non-postable entries>>-------------------------------');
    delete xx_sla_ae_lines xx
    where      exists
                 (select 1
                  from   fa_book_controls fa
                  where  xx.fa_book_type_code = fa.book_type_code and fa.gl_posting_allowed_flag = 'NO')
           and parent_request_id = g_parent_request_id
           and worker_id = g_worker_id;
    debug('----------------<<entering Updating FA info>>-------------------------------');
    update xx_sla_ae_lines xx
    set    (fa_asset_category_id
          , fa_asset_category
          , fa_asset_serial_number
          , fa_asset_type) = (select max(asset_category_id), max(concatenated_segments), max(serial_number), max(asset_type)
                              from   fa_additions_b a, fa_categories_b_kfv b
                              where  xx.fa_asset_id = a.asset_id and a.asset_category_id = b.category_id)
    where  application_id = 140 and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
    debug('----------------<<entering Asset Key Info>>-------------------------------');
    update xx_sla_ae_lines xx
    set    (fa_asset_key) = (select max(concatenated_segments)
                             from   fa_asset_keywords_kfv a, fa_additions_b b
                             where  xx.fa_asset_id = b.asset_id and b.asset_key_ccid = a.code_combination_id)
    where  application_id = 140 and parent_request_id = g_parent_request_id and worker_id = g_worker_id;
  end;

  procedure get_ledger_accts is
    c integer;
    t integer;
    l_where varchar2(1000);
    l_sql clob;
    l_primary_sql clob
      := 'insert into xx_sla_gl_ccids(code_combination_id
                                , concatenated_segments
                                , company
                                , department
                                , account
                                , sub_account
                                , region
                                , product
                                , intercompany
                                , parent_request_id
                                , date_from
                                , date_to
                                , ledger_id
                                , period_num_from
                                , period_name_from
                                , period_num_to
                                , period_name_to)
        select code_combination_id, concatenated_segments, segment1, segment2, segment3, segment4, segment6, segment5, segment7
             , :g_report_request_id, :g_date_from, :g_date_to, :g_ledger_id, :g_period_num_from, :g_period_from, :g_period_num_to
             , :g_period_to
        from   gl_code_combinations_kfv
        where segment1 = :g_company_code
        and chart_of_accounts_id = (select chart_of_accounts_id
                                           from   gl_ledgers
                                           where  ledger_id = :g_ledger_id)';
    l_sec_sql clob
      := 'insert into xx_sla_gl_ccids(code_combination_id
                                , concatenated_segments
                                , company
                                , account
                                , sub_account
                                , parent_request_id
                                , date_from
                                , date_to
                                , ledger_id
                                , period_num_from
                                , period_name_from
                                , period_num_to
                                , period_name_to)
        select code_combination_id, concatenated_segments, segment1, segment2, segment3
             , :g_report_request_id, :g_date_from, :g_date_to, :g_ledger_id, :g_period_num_from, :g_period_from, :g_period_num_to
             , :g_period_to
        from   gl_code_combinations_kfv
        where segment1 = :g_company_code
        and chart_of_accounts_id = (select chart_of_accounts_id
                                           from   gl_ledgers
                                           where  ledger_id = :g_ledger_id)';
  begin
    debug('-------<<Entering get_secondary_ledger_accts>>>--------------------');

    if (g_reporting_center_from is null and g_reporting_center_to is not null) then
      debug('If you pass Reporting Center To, then you MUST pass Reporting Center From ');
      return;
    end if;

    if (g_reporting_center_from is not null and g_reporting_center_to is null) then
      debug('If you pass Reporting Center From, then you MUST pass Reporting Center To ');
      return;
    end if;

    if (g_natural_acct_from is null and g_natural_acct_to is not null) then
      debug('If you pass Natural Account To, then you MUST pass Natural Account From ');
      return;
    end if;

    if (g_natural_acct_from is not null and g_natural_acct_to is null) then
      debug('If you pass Natural Account From, then you MUST pass Natural Account To ');
      return;
    end if;

    if (g_sub_acct_from is null and g_sub_acct_to is not null) then
      debug('If you pass Sub Account To, then you MUST pass Sub Account From ');
      return;
    end if;

    if (g_sub_acct_from is not null and g_sub_acct_to is null) then
      debug('If you pass Sub Account From, then you MUST pass Sub Account To ');
      return;
    end if;

    if g_ledger_category_code = 'PRIMARY' then
      l_sql := l_primary_sql;
    elsif g_ledger_category_code = 'SECONDARY' then
      l_sql := l_sec_sql;
    end if;

    l_sql := l_sql || crlf;

    if (g_reporting_center_from is not null and g_reporting_center_to is not null) then
      if g_ledger_category_code = 'PRIMARY' then
        l_where := l_where || 'and segment2 between :g_reporting_center_from and :g_reporting_center_to' || crlf;
      elsif g_ledger_category_code = 'SECONDARY' then
        l_where := l_where || 'and 1=1' || crlf;
      end if;
    end if;

    if (g_natural_acct_from is not null and g_natural_acct_to is not null) then
      if g_ledger_category_code = 'PRIMARY' then
        l_where := l_where || 'and segment3 between :g_natural_acct_from and :g_natural_acct_to' || crlf;
      elsif g_ledger_category_code = 'SECONDARY' then
        l_where := l_where || 'and segment2 between :g_natural_acct_from and :g_natural_acct_to' || crlf;
      end if;
    end if;

    if (g_sub_acct_from is not null and g_sub_acct_to is not null) then
      if g_ledger_category_code = 'PRIMARY' then
        l_where := l_where || 'and segment4 between :g_sub_acct_from and :g_sub_acct_to' || crlf;
      elsif g_ledger_category_code = 'SECONDARY' then
        l_where := l_where || 'and segment3 between :g_sub_acct_from and :g_sub_acct_to' || crlf;
      end if;
    end if;

    l_where := l_where || 'and 1=1';
    l_sql := l_sql || l_where;
    debug(l_sql);
    c := dbms_sql.open_cursor;
    dbms_sql.parse(c, l_sql, dbms_sql.native);
    dbms_sql.bind_variable(c, 'g_report_request_id', g_report_request_id);
    dbms_sql.bind_variable(c, 'g_date_from', g_date_from);
    dbms_sql.bind_variable(c, 'g_date_to', g_date_to);
    dbms_sql.bind_variable(c, 'g_ledger_id', g_ledger_id);
    dbms_sql.bind_variable(c, 'g_period_num_from', g_period_num_from);
    dbms_sql.bind_variable(c, 'g_period_from', g_period_from);
    dbms_sql.bind_variable(c, 'g_period_num_to', g_period_num_to);
    dbms_sql.bind_variable(c, 'g_period_to', g_period_to);
    dbms_sql.bind_variable(c, 'g_company_code', g_company_code);

    if (g_reporting_center_from is not null and g_reporting_center_to is not null) then
      dbms_sql.bind_variable(c, 'g_reporting_center_from', g_reporting_center_from);
      dbms_sql.bind_variable(c, 'g_reporting_center_to', g_reporting_center_to);
    end if;

    if (g_natural_acct_from is not null and g_natural_acct_to is not null) then
      dbms_sql.bind_variable(c, 'g_natural_acct_from', g_natural_acct_from);
      dbms_sql.bind_variable(c, 'g_natural_acct_to', g_natural_acct_to);
    end if;

    if (g_sub_acct_from is not null and g_sub_acct_to is not null) then
      dbms_sql.bind_variable(c, 'g_sub_acct_from', g_sub_acct_from);
      dbms_sql.bind_variable(c, 'g_sub_acct_to', g_sub_acct_to);
    end if;

    t := dbms_sql.execute(c);
    dbms_sql.close_cursor(c);
    debug('-------<<Existing get_primary_ledger_accts>>>--------------------');
  exception
    when others then
      debug('-------<<Exception in get_primary_ledger_accts>>>--------------------');
      debug(sqlerrm);
      debug('-------<<Existing get_primary_ledger_accts>>>--------------------');

      if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
      end if;
  end;

  procedure generate_xml(error_string   out varchar2
                       , return_status   out number
                       , p_ledger_id in number
                       , p_company_code in varchar2
                       , p_reporting_center_from in varchar2
                       , p_reporting_center_to in varchar2
                       , p_natural_acct_from in varchar2
                       , p_natural_acct_to in varchar2
                       , p_sub_acct_from in varchar2
                       , p_sub_acct_to in varchar2
                       , p_period_from in varchar2
                       , p_period_to in varchar2
                       , p_number_of_workers in number
                       , p_output_format in varchar2) is
    l_application_id number;
    l_apps_select varchar2(32767);
    l_application_name varchar2(100);
    l_request_id number;
    l_table_name varchar2(30);
    l_worker_tbl dbms_sql.number_table;
    k integer := 1;
    gl_count number;
    report_count number;

    cursor c(pc_ledger_id in number
           , p_from_date in date
           , p_to_date in date
           , p_request_id in number) is
      select distinct application_id
      from   xla_ae_lines a, xx_sla_gl_ccids b
      where      a.ledger_id = pc_ledger_id
             and a.accounting_date between p_from_date and p_to_date
             and a.code_combination_id = b.code_combination_id
             and b.parent_request_id = p_request_id;

    cursor workers_rec is
      select distinct worker_id
      from   xx_sla_ae_lines_gt;
  begin
    g_report_request_id := nvl(fnd_global.conc_request_id(), -911);
    g_sub_acct_from := p_sub_acct_from;
    g_sub_acct_to := p_sub_acct_to;
    g_natural_acct_from := p_natural_acct_from;
    g_natural_acct_to := p_natural_acct_to;
    g_company_code := p_company_code;
    g_ledger_id := p_ledger_id;
    g_reporting_center_from := p_reporting_center_from;
    g_reporting_center_to := p_reporting_center_to;
    g_period_from := p_period_from;
    g_period_to := p_period_to;
    select name, ledger_category_code
    into   g_ledger_name, g_ledger_category_code
    from   gl_ledgers
    where  ledger_id = p_ledger_id;
    select start_date, effective_period_num
    into   g_date_from, g_period_num_from
    from   gl_period_statuses
    where  ledger_id = p_ledger_id and period_name = p_period_from and application_id = 101;
    select end_date, effective_period_num
    into   g_date_to, g_period_num_to
    from   gl_period_statuses
    where  ledger_id = p_ledger_id and period_name = p_period_to and application_id = 101;
    --if g_ledger_category_code = 'PRIMARY' then
    g_primary_ledger_id := g_ledger_id;
    --get_primary_ledger_accts;
    get_ledger_accts;
    --elsif g_ledger_category_code = 'SECONDARY' then
    --select primary_ledger_id
    --into   g_primary_ledger_id
    --from   gl_secondary_ledger_rships_v
    --where  ledger_id = g_ledger_id;
    --get_secondary_ledger_accts;
    --end if;
    insert into xx_sla_ae_lines_gt(parent_request_id
                                 , child_request_id
                                 , worker_id
                                 , application_id
                                 , code_combination_id
                                 , concatenated_segments
                                 , company
                                 , department
                                 , account
                                 , sub_account
                                 , region
                                 , product
                                 , intercompany
                                 , je_source
                                 , je_batch_id
                                 , gl_batch_name
                                 , je_category
                                 , je_header_id
                                 , je_line_num
                                 , journal_name
                                 , je_line_description
                                 , accounting_date
                                 , accounting_period
                                 , gl_doc_sequence_value
                                 , gl_sl_link_id
                                 , gl_sl_link_table
                                 , gl_project_number
                                 , gl_task_number
                                 , gl_expenditure_type
                                 , gl_expenditure_org
                                 , entered_dr
                                 , entered_cr
                                 , entered_net
                                 , accounted_dr
                                 , accounted_cr
                                 , accounted_net
                                 , reporting_sequence_number
                                 , currency_code)
      select xglcc.parent_request_id, -1 * xglcc.parent_request_id
           , decode(p_number_of_workers, 1, 1, mod(rownum, p_number_of_workers) + 1) worker_id, null, glcc.code_combination_id
           , glcc.concatenated_segments, segment1 company, segment2 department, segment3 account, segment4 sub_account, segment6 region
           , segment5 product, segment7 intercompany, b.je_source, c.je_batch_id, c.name gl_batch_name, b.je_category, a.je_header_id
           , a.je_line_num je_line_num, b.name journal_name, a.description je_line_description, a.effective_date accounting_date
           , a.period_name accounting_period, b.doc_sequence_value, d.gl_sl_link_id, d.gl_sl_link_table, a.attribute1, a.attribute2
           , a.attribute3, a.attribute4, 0, 0, 0, 0, 0, 0, b.close_acct_seq_value, null
      from   gl_je_lines a
           , gl_je_headers b
           , gl_je_batches c
           , gl_import_references d
           , gl_code_combinations_kfv glcc
           , xx_sla_gl_ccids xglcc
           , gl_period_statuses gps
      where      glcc.chart_of_accounts_id = (select chart_of_accounts_id
                                              from   gl_ledgers
                                              where  ledger_id = g_ledger_id)
             and glcc.code_combination_id = xglcc.code_combination_id
             and xglcc.parent_request_id = g_report_request_id
             and a.period_name = gps.period_name
             and gps.ledger_id = p_ledger_id
             and gps.application_id = 101
             and gps.effective_period_num between g_period_num_from and g_period_num_to
             and a.je_header_id = b.je_header_id
             and b.status = 'P'
             and b.je_batch_id = c.je_batch_id
             and a.je_header_id = d.je_header_id
             and a.je_line_num = d.je_line_num
             and a.code_combination_id = glcc.code_combination_id
      union all
      select xglcc.parent_request_id, -1 * xglcc.parent_request_id
           , decode(p_number_of_workers, 1, 1, mod(rownum, p_number_of_workers) + 1) worker_id, 101, glcc.code_combination_id
           , glcc.concatenated_segments, segment1 company, segment2 department, segment3 account, segment4 sub_account, segment6 region
           , segment5 product, segment7 intercompany, b.je_source, c.je_batch_id, c.name gl_batch_name, b.je_category, a.je_header_id
           , a.je_line_num je_line_num, b.name journal_name, a.description je_line_description, a.effective_date accounting_date
           , a.period_name accounting_period, b.doc_sequence_value, null gl_sl_link_id, null gl_sl_link_table, a.attribute1, a.attribute2
           , a.attribute3, a.attribute4, nvl(a.entered_dr, 0), nvl(a.entered_cr, 0)
           , nvl(abs(a.entered_dr), 0) - nvl(abs(a.entered_cr), 0) entered_net, nvl(a.accounted_dr, 0), nvl(a.accounted_cr, 0)
           , nvl(abs(a.accounted_dr), 0) - nvl(abs(a.accounted_cr), 0) accounted_net, b.close_acct_seq_value, b.currency_code
      from   gl_je_lines a
           , gl_je_headers b
           , gl_je_batches c
           , gl_code_combinations_kfv glcc
           , gl_je_categories gjc
           , gl_je_sources gjs
           , xx_sla_gl_ccids xglcc
           , gl_period_statuses gps
      where      glcc.chart_of_accounts_id = (select chart_of_accounts_id
                                              from   gl_ledgers
                                              where  ledger_id = g_ledger_id)
             and glcc.code_combination_id = xglcc.code_combination_id
             and xglcc.parent_request_id = g_report_request_id
             and a.period_name = gps.period_name
             and gps.ledger_id = p_ledger_id
             and gps.application_id = 101
             and gps.effective_period_num between g_period_num_from and g_period_num_to
             and a.je_header_id = b.je_header_id
             and b.status = 'P'
             and b.je_batch_id = c.je_batch_id
             and a.code_combination_id = glcc.code_combination_id
             and a.status = 'P'
             and a.je_header_id = b.je_header_id
             and b.je_batch_id = c.je_batch_id
             and b.je_category = gjc.je_category_name
             and b.je_source = gjs.je_source_name
             and journal_reference_flag = 'N';
    fnd_stats.gather_table_stats('xxintg', 'xx_sla_ae_lines_gt', 40);
    insert into xx_sla_ae_lines
      select *
      from   xx_sla_ae_lines_gt;
    fnd_stats.gather_table_stats('xxintg', 'xx_sla_ae_lines', 40);
    commit;

    for workers in workers_rec loop
      l_worker_tbl(k) := workers.worker_id;
      k := k + 1;
    end loop;

    debug('------------<Printing Total Number of Workers>-------------');
    debug('Number of workers is :' || l_worker_tbl.count);

    if l_worker_tbl.count = 0 then
      debug('No Subledger accounting entries found for the combination of parameters passed. Looking for manual journals.');
    end if;

    commit;

    if l_worker_tbl.count > 0 then
      launch_child_requests(g_report_request_id, l_worker_tbl);
    end if;

    if p_output_format = 'EXCEL' then
      launch_report(g_report_request_id, 'INTG_SLA_ACCT_DETAILS', p_output_format);
    else
      launch_report(g_report_request_id, 'INTG_SLA_ACCT_DETAILS_CSV', p_output_format);
    end if;
   cleanup_staging_tables(error_string, return_status, g_report_request_id); 
  exception
    when others then
      debug('In Exception in getting apps in generate_xml' || sqlerrm);
  end;

  function get_view_columns(p_reporting_view in varchar2)
    return varchar2 is
    type t_array_char is table of varchar2(80)
                           index by binary_integer;

    l_conc_seg_delimiter varchar2(80);
    l_concat_segment varchar2(4000);
    l_array t_array_char;

    cursor c is
      select column_name
      from   dba_tab_columns a
      where  table_name = p_reporting_view;
  begin
    open c;
    fetch c
    bulk collect into l_array;
    close c;

    for i in 1 .. l_array.count loop
      l_concat_segment := l_concat_segment || l_array(i);

      if i < l_array.count then
        l_concat_segment := l_concat_segment || crlf || ' , ';
      end if;
    end loop;

    return l_concat_segment;
  exception
    when others then
      return null;
  end get_view_columns;

  function get_app_view_columns(p_app_id in number, p_reporting_view in varchar2)
    return varchar2 is
    type t_array_char is table of varchar2(80)
                           index by binary_integer;

    l_conc_seg_delimiter varchar2(80);
    l_concat_segment varchar2(4000);
    l_array t_array_char;

    cursor c is
      select case
               when p_app_id = 200 then 'AP_'
               when p_app_id = 222 then 'AR_'
               when p_app_id = 260 then 'CE_'
               when p_app_id = 275 then 'PA_'
               when p_app_id = 140 then 'FA_'
               when p_app_id = 707 then 'CST_'
             end
             || column_name
      from   dba_tab_columns a
      where  table_name = p_reporting_view;
  begin
    open c;
    fetch c
    bulk collect into l_array;
    close c;

    for i in 1 .. l_array.count loop
      l_concat_segment := l_concat_segment || l_array(i);

      if i < l_array.count then
        l_concat_segment := l_concat_segment || crlf || ' , ';
      end if;
    end loop;

    return l_concat_segment;
  exception
    when others then
      return null;
  end get_app_view_columns;

  procedure wait_for_requests(p_array_request_id in dbms_sql.number_table
                            , p_error_status   out nocopy varchar2
                            , p_warning_status   out nocopy varchar2) is
    l_phase varchar2(30);
    l_status varchar2(30);
    l_dphase varchar2(30);
    l_dstatus varchar2(30);
    l_message varchar2(240);
    l_btemp boolean;
    l_log_module varchar2(240);
  begin
    debug(p_msg => 'BEGIN of procedure WAIT_FOR_REQUESTS');

    if p_array_request_id.count > 0 then
      for i in 1 .. p_array_request_id.count loop
        debug(p_msg => 'waiting for request id = ' || p_array_request_id(i));
        l_btemp := fnd_concurrent.wait_for_request(request_id => p_array_request_id(i)
                                                 , interval => 30
                                                 , phase => l_phase
                                                 , status => l_status
                                                 , dev_phase => l_dphase
                                                 , dev_status => l_dstatus
                                                 , message => l_message);

        if not l_btemp then
          debug(   'Technical problem : FND_CONCURRENT.WAIT_FOR_REQUEST returned FALSE '
                || 'while executing for request id '
                || p_array_request_id(i));
        else
          debug(p_msg => 'request completed with status = ' || l_status);
        end if;

        if l_dstatus = 'WARNING' then
          p_warning_status := 'Y';
        elsif l_dstatus = 'ERROR' then
          p_error_status := 'Y';
        end if;
      end loop;
    end if;

    debug(p_msg => 'END of procedure WAIT_FOR_REQUESTS');
  exception
    when xla_exceptions_pkg.application_exception then
      raise;
    when others then
      debug(p_msg => 'wait_for_requests');
  end wait_for_requests;

  procedure launch_child_requests(p_parent_request_id in number, p_worker_tbl dbms_sql.number_table) is
    l_ep_request_ids dbms_sql.number_table;
    x_error_status varchar2(400);
    x_warning_status varchar2(400);
    l_app_name varchar2(400);
  begin
    debug('----------<Number of workers : ' || p_worker_tbl.count || '>---------------');

    if p_worker_tbl.count > 0 then
      for i in 1 .. (p_worker_tbl.count) loop
        l_ep_request_ids(i) := fnd_request.submit_request(application => 'XXINTG'
                                                        , program => 'INTG_SLA_DETAIL_CHILD'
                                                        , description => 'Worker ' || p_worker_tbl(i) || ' Collecting Data'
                                                        , start_time => null
                                                        , sub_request => false
                                                        , argument1 => p_parent_request_id
                                                        , argument2 => p_worker_tbl(i));

        if l_ep_request_ids(i) = 0 then
          debug(p_msg => 'Technical Error : Unable to submit child requests.');
        else
          debug('Submitted child request:' || l_ep_request_ids(i) || ' for worker number: ' || p_worker_tbl(i));
          update xx_sla_ae_lines
          set    child_request_id = l_ep_request_ids(i)
          where  worker_id = p_worker_tbl(i) and parent_request_id = p_parent_request_id;
        end if;
      end loop;
    end if;

    commit;
    g_ep_request_ids := l_ep_request_ids;
    wait_for_requests(g_ep_request_ids, x_error_status, x_warning_status);
  end;

  procedure worker_collection(xerrbuf out varchar2, xretcode out varchar2, p_parent_request_id in number, p_worker_id in number) is
    l_cols varchar2(32000);
    l_app_cols varchar2(32000);
    l_reporting_view varchar2(300);
    l_update_sql clob;
    l_where_clause varchar2(300);
    l_cursor integer;
    l_execute integer;

    cursor c1 is
      select distinct application_id, entity_code, reporting_view_name
      from   xx_sla_ae_lines
      where      parent_request_id = p_parent_request_id
             and worker_id = p_worker_id
             and reporting_view_name is not null
             and application_id <> 101;

    cursor c(p_app_id in number, p_entity_code in varchar2) is
      select entity_code, transaction_id_col_name_1, transaction_id_col_name_2, transaction_id_col_name_3, transaction_id_col_name_4
           , source_id_col_name_1, source_id_col_name_2, source_id_col_name_3, source_id_col_name_4
      from   xla_entity_id_mappings
      where  application_id = p_app_id and entity_code = p_entity_code;
  begin
    g_parent_request_id := p_parent_request_id;
    g_worker_id := p_worker_id;

    begin
      mo_global.set_org_context(null, '63', 'SQLAP');
    exception
      when others then
        null;
    end;

    update xx_sla_ae_lines xx
    set    (application_id
          , ae_header_id
          , ae_line_num
          , event_id
          , entity_id
          , entered_dr
          , entered_cr
          , entered_net
          , accounted_dr
          , accounted_cr
          , accounted_net
          , currency_code
          , accounting_class) = (select distinct xah.application_id, xah.ae_header_id, xal.ae_line_num, xah.event_id, xah.entity_id
                                               , nvl(xal.entered_dr, 0), nvl(xal.entered_cr, 0)
                                               , nvl(xal.entered_dr, 0) - nvl(xal.entered_cr, 0), nvl(xal.accounted_dr, 0)
                                               , nvl(xal.accounted_cr, 0), nvl(xal.accounted_dr, 0) - nvl(xal.accounted_cr, 0)
                                               , xal.currency_code, xal.accounting_class_code
                                 from   xla_ae_lines xal, xla_ae_headers xah
                                 where      xx.gl_sl_link_id = xal.gl_sl_link_id
                                        and xx.gl_sl_link_table = xal.gl_sl_link_table
                                        and xal.ae_header_id = xah.ae_header_id)
    where      parent_request_id = p_parent_request_id
           and worker_id = p_worker_id
           and (gl_sl_link_id is not null and gl_sl_link_table is not null);
    update xx_sla_ae_lines xx
    set    (entity_code
          , source_id_int_1
          , source_id_int_2
          , source_id_int_3
          , source_id_int_4
          , source_id_char_1
          , source_id_char_2
          , source_id_char_3
          , source_id_char_4) = (select entity_code, source_id_int_1, source_id_int_2, source_id_int_3, source_id_int_4, source_id_char_1
                                      , source_id_char_2, source_id_char_3, source_id_char_4
                                 from   xla_transaction_entities_upg xte
                                 where  xx.entity_id = xte.entity_id)
    where      parent_request_id = p_parent_request_id
           and worker_id = p_worker_id
           and (gl_sl_link_id is not null and gl_sl_link_table is not null);
    update xx_sla_ae_lines xx
    set    (event_type_code
          , event_class_code
          , event_type_name) = (select xetv.event_type_code, xetv.event_class_code, xetv.name
                                from   xla_events xe, xla_event_types_vl xetv
                                where      xx.event_id = xe.event_id
                                       and xe.event_type_code = xetv.event_type_code
                                       and xe.application_id = xetv.application_id)
    where      parent_request_id = p_parent_request_id
           and worker_id = p_worker_id
           and (gl_sl_link_id is not null and gl_sl_link_table is not null);
    update xx_sla_ae_lines xx
    set    (event_class_name) = (select xecv.name
                                 from   xla_event_classes_vl xecv
                                 where  xx.event_class_code = xecv.event_class_code and xx.application_id = xecv.application_id)
    where      parent_request_id = p_parent_request_id
           and worker_id = p_worker_id
           and (gl_sl_link_id is not null and gl_sl_link_table is not null);
    update xx_sla_ae_lines xx
    set    accounting_class = (select meaning
                               from   fnd_lookup_values_vl xlk
                               where  xlk.lookup_type = 'XLA_ACCOUNTING_CLASS' and xlk.lookup_code = xx.accounting_class)
    where      parent_request_id = p_parent_request_id
           and worker_id = p_worker_id
           and (gl_sl_link_id is not null and gl_sl_link_table is not null);
    update xx_sla_ae_lines xx
    set    reporting_view_name = (select reporting_view_name
                                  from   xla_event_class_attrs xeca
                                  where      xx.application_id = xeca.application_id
                                         and xx.entity_code = xeca.entity_code
                                         and xx.event_class_code = xeca.event_class_code)
    where      parent_request_id = p_parent_request_id
           and worker_id = p_worker_id
           and (gl_sl_link_id is not null and gl_sl_link_table is not null);
    update xx_sla_ae_lines a
    set    (transaction_id_col_name_1
          , transaction_id_col_name_2
          , transaction_id_col_name_3
          , transaction_id_col_name_4
          , source_id_col_name_1
          , source_id_col_name_2
          , source_id_col_name_3
          , source_id_col_name_4) = (select transaction_id_col_name_1, transaction_id_col_name_2, transaction_id_col_name_3
                                          , transaction_id_col_name_4, source_id_col_name_1, source_id_col_name_2, source_id_col_name_3
                                          , source_id_col_name_4
                                     from   xla_entity_id_mappings b
                                     where  a.application_id = b.application_id and a.entity_code = b.entity_code)
    where      parent_request_id = p_parent_request_id
           and worker_id = p_worker_id
           and (gl_sl_link_id is not null and gl_sl_link_table is not null);

    for j in c1 loop
      for i in c(j.application_id, j.entity_code) loop
        if i.transaction_id_col_name_1 is not null then
          l_where_clause := ' where a.' || i.source_id_col_name_1 || '=b.' || i.transaction_id_col_name_1;
        end if;

        if i.transaction_id_col_name_2 is not null then
          l_where_clause := l_where_clause || crlf;
          l_where_clause := l_where_clause || ' and a.' || i.source_id_col_name_2 || '=b.' || i.transaction_id_col_name_2;
        end if;

        if i.transaction_id_col_name_3 is not null then
          l_where_clause := l_where_clause || crlf;
          l_where_clause := l_where_clause || ' and a.' || i.source_id_col_name_3 || '=b.' || i.transaction_id_col_name_3;
        end if;

        if i.transaction_id_col_name_4 is not null then
          l_where_clause := l_where_clause || crlf;
          l_where_clause := l_where_clause || ' and a.' || i.source_id_col_name_4 || '=b.' || i.transaction_id_col_name_4;
        end if;
      end loop;

      l_reporting_view := j.reporting_view_name;
      l_cols := get_view_columns(l_reporting_view);
      l_app_cols := get_app_view_columns(j.application_id, l_reporting_view);
      l_update_sql := 'update xx_sla_ae_lines a set (';
      l_update_sql := l_update_sql || l_app_cols || ')' || '=' || crlf;
      l_update_sql := l_update_sql || '(select ' || l_cols;
      l_update_sql := l_update_sql || ' from ' || l_reporting_view || ' b';
      l_update_sql := l_update_sql || crlf;
      l_update_sql := l_update_sql || l_where_clause || ' )';
      l_update_sql := l_update_sql || 'where reporting_view_name=''' || l_reporting_view || '''';
      l_update_sql := l_update_sql || crlf;
      l_update_sql := l_update_sql || 'and parent_request_id=:p_parent_request_id';
      l_update_sql := l_update_sql || crlf;
      l_update_sql := l_update_sql || 'and worker_id=:p_worker_id';
      debug(l_reporting_view);
      debug('-----------------------');
      debug(l_update_sql);
      l_cursor := dbms_sql.open_cursor;
      dbms_sql.parse(l_cursor, l_update_sql, dbms_sql.native);
      dbms_sql.bind_variable(l_cursor, ':p_parent_request_id', p_parent_request_id);
      dbms_sql.bind_variable(l_cursor, ':p_worker_id', p_worker_id);
      l_execute := dbms_sql.execute(l_cursor);
      dbms_sql.close_cursor(l_cursor);
    end loop;

    update_cst_info;
    update_ap_info;
    update_ar_info;
    update_fa_info;
  exception
    when others then
      debug(sqlerrm);

      if dbms_sql.is_open(l_cursor) then
        dbms_sql.close_cursor(l_cursor);
      end if;
  end;

  function before_report
    return boolean is
  begin
    lp_where_clause := 'parent_request_id = ' || p_parent_request_id;
    return true;
  exception
    when no_data_found then
      debug('ERROR IN before_report TRIGGER: ' || sqlerrm);
      return false;
    when others then
      debug('ERROR IN before_report TRIGGER: ' || sqlerrm);
      return false;
  end before_report;

  function return_quantity(p_quantity IN NUMBER, p_accounted_net IN NUMBER)
  return NUMBER
  IS
  v_quantity NUMBER := 0;
  BEGIN
  IF p_quantity > 0 and p_accounted_net < 0 THEN
  v_quantity :=  p_quantity * -1;
  ELSIF p_quantity < 0 and p_accounted_net > 0 THEN
   v_quantity :=  p_quantity * -1;
   ELSE
   v_quantity :=  p_quantity;
   END IF;
   RETURN v_quantity;

   EXCEPTION
   WHEN OTHERS THEN
   RETURN(p_quantity);
  END;

  procedure generate_csv_report(errbuf out varchar2, retcode out varchar2, p_request_id in number, p_output_format in varchar2) is
    cursor c(pc_output_format in varchar2) is
      select      case
                    when application_id = 101 then 'General Ledger'
                    when application_id = 140 then 'Assets'
                    when application_id = 200 then 'Payables'
                    when application_id = 222 then 'Receivables'
                    when application_id = 260 then 'Cash Management'
                    when application_id = 275 then 'Projects'
                    when application_id = 707 then 'Cost Management'
                  end
               || pc_output_format
               || sla.accounting_date
               || pc_output_format
               || sla.accounting_period
               || pc_output_format
               || sla.sl_concatenated_segments
               || pc_output_format
               || sla.concatenated_segments
               || pc_output_format
               || sla.company
               || pc_output_format
               || sla.department
               || pc_output_format
               || sla.account
               || pc_output_format
               || sla.sub_account
               || pc_output_format
               || sla.product
               || pc_output_format
               || sla.region
               || pc_output_format
               || sla.intercompany
               || pc_output_format
               || sla.gl_batch_name
               || pc_output_format
               || sla.gl_doc_sequence_value
               || pc_output_format
               || sla.reporting_sequence_number
               || pc_output_format
               || sla.journal_name
               || pc_output_format
               || REPLACE(RTRIM(je_line_description,chr(13)),chr(32),'')
               || pc_output_format
               || sla.je_source
               || pc_output_format
               || sla.je_category
               || pc_output_format
               || sla.event_class_name
               || pc_output_format
               || sla.event_type_name
               || pc_output_format
               || nvl(sla.accounting_class, 'Manual')
               || pc_output_format
               || sum(sla.entered_dr)
               || pc_output_format
               || sum(sla.entered_cr)
               || pc_output_format
               || sum(sla.entered_net)
               || pc_output_format
               || sum(sla.accounted_dr)
               || pc_output_format
               || sum(sla.accounted_cr)
               || pc_output_format
               || sum(sla.accounted_net)
               || pc_output_format
               || sla.currency_code
               || pc_output_format
               || gl_project_number
               || pc_output_format
               || gl_task_number
               || pc_output_format
               || gl_expenditure_type
               || pc_output_format
               || gl_expenditure_org
               || pc_output_format
               || ar_customer_number
               || pc_output_format
               || ar_customer_name
               || pc_output_format
               || ar_trx_type
               || pc_output_format
               || ar_trx_batch_source
               || pc_output_format
               || ar_trx_date
               || pc_output_format
               || ar_trx_number
               || pc_output_format
               || ar_trx_reference
               || pc_output_format
               || ar_tracking_numbers
               || pc_output_format
               || ar_adjustment_creation_date
               || pc_output_format
               || ar_adjustment_number
               || pc_output_format
               || ar_cash_receipt_batch_date
               || pc_output_format
               || ar_cash_receipt_batch_name
               || pc_output_format
               || ar_receipt_creation_date
               || pc_output_format
               || ar_receipt_number
               || pc_output_format
               || ar_receipt_method
               || pc_output_format
               || ap_vendor_number
               || pc_output_format
               || ap_vendor_name
               || pc_output_format
               || ap_invoice_type_lookup_code
               || pc_output_format
               || ap_invoice_date
               || pc_output_format
               || ap_invoice_num
               || pc_output_format
               || ap_voucher_number
               || pc_output_format
               || ap_po_number
               || pc_output_format
               || ap_po_line_number
               || pc_output_format
               || ap_invoice_description
               || pc_output_format
               || ap_project_number
               || pc_output_format
               || ap_task_number
               || pc_output_format
               || ap_expenditure_type
               || pc_output_format
               || ap_expenditure_org_name
               || pc_output_format
               || ap_check_date
               || pc_output_format
               || ap_check_number
               || pc_output_format
               || ap_check_voucher_number
               || pc_output_format
               || ap_payment_method_code
               || pc_output_format
               || sla.cst_party_type
               || pc_output_format
               || sla.cst_party_number
               || pc_output_format
               || sla.cst_party_name
               || pc_output_format
               || sla.cst_organization_code
               || pc_output_format
               || cst_subinventory_code
               || pc_output_format
               || trunc(sla.cst_transaction_date)
               || pc_output_format
               || sla.cst_transaction_type
               || pc_output_format
               || sla.cst_trx_source_type
               || pc_output_format
               || sla.cst_source_number
               || pc_output_format
               || sla.cst_po_number
               || pc_output_format
               || sla.cst_po_line_number
               || pc_output_format
               || sla.cst_receipt_num
               || pc_output_format
               || sla.cst_receipt_date
               || pc_output_format
               || sla.cst_item_name
               || pc_output_format
               || REGEXP_REPLACE(sla.cst_item_description,chr(32)||'{2}|'||chr(100)||'|'||chr(10)||'|'||chr(13)||'{2}'||'|'||chr(6),'')  ---ADDED for ticket 10006
               || pc_output_format
               || return_quantity(sla.cst_primary_quantity,sum(sla.accounted_net))
               || pc_output_format
               || sla.cst_primary_unit_of_measure
               || pc_output_format
               || sla.cst_project_number
               || pc_output_format
               || sla.cst_po_task_number
               || pc_output_format
               || sla.cst_po_exp_org_name
               || pc_output_format
               || cst_po_exp_type
               || pc_output_format
               || fa_asset_number
               || pc_output_format
               || fa_description
               || pc_output_format
               || fa_asset_category
               || pc_output_format
               || fa_asset_key
               || pc_output_format
               || fa_asset_serial_number
               || pc_output_format
               || fa_asset_type
               || pc_output_format
               || fa_transaction_type_code
               || pc_output_format
               || fa_trx_reference_id
               || pc_output_format
               || pa_project_name_num_concat
               || pc_output_format
               || pa_task_name_num_concat
               || pc_output_format
               || pa_expenditure_type
               || pc_output_format
               || pa_exp_organization_name
               || pc_output_format
               || pa_budget_type_code
               || pc_output_format
               || pa_budget_version_name
               || pc_output_format
               || ce_cashflow_number
               || pc_output_format
               || ce_cf_bank_account_name
               || pc_output_format
               || ce_cf_bank_account_num
               || pc_output_format
               || ce_cf_currency
               || pc_output_format
               || ce_cf_ba_currency
               || pc_output_format
               || ce_payment_trx_reference_num
               || pc_output_format
               || ce_statement_date
               || pc_output_format
               || ce_statement_number
               || pc_output_format
               || cst_transaction_id
                 val
      from     xx_sla_ae_lines sla
      where    parent_request_id = p_request_id
      group by sla.application_id
             , sla.accounting_date
             , sla.accounting_period
             , sla.sl_concatenated_segments
             , sla.concatenated_segments
             , sla.company
             , sla.department
             , sla.account
             , sla.sub_account
             , sla.region
             , sla.product
             , sla.intercompany
             , sla.gl_batch_name
             , sla.gl_doc_sequence_value
             , sla.reporting_sequence_number
             , sla.journal_name
             , sla.je_line_description
             , sla.je_source
             , sla.je_category
             , sla.event_class_name
             , sla.event_type_name
             , sla.accounting_class
             , sla.currency_code
             , gl_project_number
             , gl_task_number
             , gl_expenditure_type
             , gl_expenditure_org
             , ar_customer_number
             , ar_customer_name
             , ar_trx_type
             , ar_trx_batch_source
             , ar_trx_date
             , ar_trx_number
             , ar_trx_reference
             , ar_tracking_numbers
             , ar_adjustment_creation_date
             , ar_adjustment_number
             , ar_cash_receipt_batch_date
             , ar_cash_receipt_batch_name
             , ar_receipt_creation_date
             , ar_receipt_number
             , ar_receipt_method
             , ap_vendor_number
             , ap_vendor_name
             , ap_invoice_type_lookup_code
             , ap_invoice_date
             , ap_invoice_num
             , ap_voucher_number
             , ap_po_number
             , ap_po_line_number
             , ap_invoice_description
             , ap_project_number
             , ap_task_number
             , ap_expenditure_type
             , ap_expenditure_org_name
             , ap_check_date
             , ap_check_number
             , ap_check_voucher_number
             , ap_payment_method_code
             , sla.cst_party_type
             , sla.cst_party_number
             , sla.cst_party_name
             , sla.cst_organization_code
             , cst_subinventory_code
             , trunc(sla.cst_transaction_date)
             , sla.cst_transaction_type
             , sla.cst_trx_source_type
             , sla.cst_po_number
             , sla.cst_source_number
             , sla.cst_po_line_number
             , sla.cst_receipt_num
             , sla.cst_receipt_date
             , sla.cst_item_name
             , sla.cst_item_description
             , sla.cst_primary_quantity
             , sla.cst_primary_unit_of_measure
             , sla.cst_project_number
             , sla.cst_po_task_number
             , sla.cst_po_exp_org_name
             , cst_po_exp_type
             , fa_asset_number
             , fa_description
             , fa_asset_category
             , fa_asset_key
             , fa_asset_serial_number
             , fa_transaction_type_code
             , fa_trx_reference_id
             , fa_asset_type
             , pa_project_name_num_concat
             , pa_task_name_num_concat
             , pa_expenditure_type
             , pa_exp_organization_name
             , pa_budget_type_code
             , pa_budget_version_name
             , ce_cashflow_number
             , ce_cf_bank_account_name
             , ce_cf_bank_account_num
             , ce_cf_currency
             , ce_cf_ba_currency
             , ce_payment_trx_reference_num
             , ce_statement_date
             , ce_statement_number
             , cst_transaction_id;
   ---   having   nvl(sum(accounted_net), 0) <> 0;  --- commented for the ticket #100110  

    hdr long;
    l_output_format varchar2(10);
  begin
    l_output_format := '~';

    if p_output_format = 'CSV' then
      l_output_format := ',';
    elsif p_output_format = 'TILDE' then
      l_output_format := '~';
    elsif p_output_format = 'PIPE' then
      l_output_format := '|';
    end if;

    select    'Application'
           || l_output_format
           || 'GL Date'
           || l_output_format
           || 'GL Period'
           || l_output_format
           || 'Secondary Ledger Account'
           || l_output_format
           || 'Primary Ledger Account'
           || l_output_format
           || 'Company'
           || l_output_format
           || 'Department'
           || l_output_format
           || 'Account'
           || l_output_format
           || 'Sub Account'
           || l_output_format
           || 'Product'
           || l_output_format
           || 'Region'
           || l_output_format
           || 'Intercompany'
           || l_output_format
           || 'GL Batch Name'
           || l_output_format
           || 'JE Document Number'
           || l_output_format
           || 'Reporting Sequence Number'
           || l_output_format
           || 'GL Journal Name'
           || l_output_format
           || 'GL Journal Line Description'
           || l_output_format
           || 'Journal Source'
           || l_output_format
           || 'Journal Category'
           || l_output_format
           || 'Event Class'
           || l_output_format
           || 'Event Type'
           || l_output_format
           || 'Accounting Class'
           || l_output_format
           || 'Entered Dr'
           || l_output_format
           || 'Entered Cr'
           || l_output_format
           || 'Entered Net'
           || l_output_format
           || 'Accounted Dr'
           || l_output_format
           || 'Accounted Cr'
           || l_output_format
           || 'Accounted Net'
           || l_output_format
           || 'Currency'
           || l_output_format
           || 'GL Project #'
           || l_output_format
           || 'GL Task #'
           || l_output_format
           || 'GL Expenditure Type'
           || l_output_format
           || 'GL Expenditure Org'
           || l_output_format
           || 'Customer Number'
           || l_output_format
           || 'Customer Name'
           || l_output_format
           || 'Transaction Type'
           || l_output_format
           || 'Batch Source'
           || l_output_format
           || 'Transaction Date'
           || l_output_format
           || 'Transaction Number'
           || l_output_format
           || 'Reference'
           || l_output_format
           || 'Tracking Numbers'
           || l_output_format
           || 'Adjustment Date'
           || l_output_format
           || 'Adjustment Number'
           || l_output_format
           || 'Receipt Batch Date'
           || l_output_format
           || 'Receipt Batch Name'
           || l_output_format
           || 'Receipt Date'
           || l_output_format
           || 'Receipt Number'
           || l_output_format
           || 'Receipt Method'
           || l_output_format
           || 'Supplier Number'
           || l_output_format
           || 'Supplier Name'
           || l_output_format
           || 'Invoice Type'
           || l_output_format
           || 'Invoice Date'
           || l_output_format
           || 'Invoice Number'
           || l_output_format
           || 'Voucher Number'
           || l_output_format
           || 'PO Number'
           || l_output_format
           || 'PO Line'
           || l_output_format
           || 'Invoice Description'
           || l_output_format
           || 'AP Project #'
           || l_output_format
           || 'AP Task Number #'
           || l_output_format
           || 'AP Exp Type'
           || l_output_format
           || 'AP Exp Org'
           || l_output_format
           || 'Payment Date'
           || l_output_format
           || 'Payment Number'
           || l_output_format
           || 'Payment Voucher#'
           || l_output_format
           || 'Payment Method'
           || l_output_format
           || 'Party Type'
           || l_output_format
           || 'Party Number'
           || l_output_format
           || 'Party Name'
           || l_output_format
           || 'Inventory Org'
           || l_output_format
           || 'Subinventory'
           || l_output_format
           || 'Transaction Date'
           || l_output_format
           || 'Transaction Type'
           || l_output_format
           || 'Source Type'
           || l_output_format
           || 'Source'
           || l_output_format
           || 'PO Number'
           || l_output_format
           || 'PO Line'
           || l_output_format
           || 'Receipt#'
           || l_output_format
           || 'Receipt Date'
           || l_output_format
           || 'Item#'
           || l_output_format
           || 'Item Description'
           || l_output_format
           || 'Qty'
           || l_output_format
           || 'UOM'
           || l_output_format
           || 'PO Project#'
           || l_output_format
           || 'PO Task#'
           || l_output_format
           || 'PO Exp Type'
           || l_output_format
           || 'PO Exp Org'
           || l_output_format
           || 'Asset Number'
           || l_output_format
           || 'Asset Description'
           || l_output_format
           || 'Category'
           || l_output_format
           || 'Asset Key'
           || l_output_format
           || 'Serial Number'
           || l_output_format
           || 'Asset Type'
           || l_output_format
           || 'Transaction Type'
           || l_output_format
           || 'Reference Number'
           || l_output_format
           || 'Project#'
           || l_output_format
           || 'Task#'
           || l_output_format
           || 'Exp Type'
           || l_output_format
           || 'Exp org'
           || l_output_format
           || 'Budget Type'
           || l_output_format
           || 'Budget Version'
           || l_output_format
           || 'Cashflow#'
           || l_output_format
           || 'Bank Account Name'
           || l_output_format
           || 'Bank Account#'
           || l_output_format
           || 'Cashflow Currecny'
           || l_output_format
           || 'Bank Account Currency'
           || l_output_format
           || 'Trx Reference#'
           || l_output_format
           || 'Statement Date'
           || l_output_format
           || 'Statement#'
           || l_output_format
           || 'TransactionID'
    into   hdr
    from   dual;
    fnd_file.put_line(fnd_file.output, hdr);

    for i in c(l_output_format) loop
      fnd_file.put_line(fnd_file.output, i.val);
    end loop;
  end;

  procedure launch_report(p_parent_request_id in number, p_report_name in varchar2, p_output_format in varchar2) is
    l_ep_request_ids dbms_sql.number_table;
    x_error_status varchar2(400);
    x_warning_status varchar2(400);
    l_layout_status boolean := false;
  begin
    l_ep_request_ids.delete;
    g_ep_request_ids.delete;

    if p_output_format = 'EXCEL' then
      l_layout_status := fnd_request.add_layout(template_appl_name => 'XXINTG'
                                              , template_code => 'INTG_SLA_ACCT_DETAILS'
                                              , template_language => 'en'
                                              , template_territory => 'US'
                                              , output_format => 'EXCEL');
      debug('----------<Launching XML Report : ' || p_report_name || '>---------------');
      l_ep_request_ids(1) := fnd_request.submit_request(application => 'XXINTG'
                                                      , program => p_report_name
                                                      , start_time => null
                                                      , sub_request => false
                                                      , argument1 => p_parent_request_id
                                                      , argument2 => p_output_format
                                                      , argument3 => 'Y');
    else
      debug('----------<Launching CSV Report : ' || p_report_name || '>---------------');
      l_ep_request_ids(1) := fnd_request.submit_request(application => 'XXINTG'
                                                      , program => p_report_name
                                                      , start_time => null
                                                      , sub_request => false
                                                      , argument1 => p_parent_request_id
                                                      , argument2 => p_output_format);
    end if;

    if l_ep_request_ids(1) = 0 then
      debug(p_msg => 'Technical Error : Unable to submit report');
    else
      debug('Submitted Report: ' || l_ep_request_ids(1) || ' for Report: ' || p_report_name);
    end if;

    commit;
    g_ep_request_ids := l_ep_request_ids;
    wait_for_requests(g_ep_request_ids, x_error_status, x_warning_status);
  end;
end intg_sla_details_rpt_pkg;
/
