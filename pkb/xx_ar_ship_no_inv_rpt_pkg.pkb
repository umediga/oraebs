DROP PACKAGE BODY APPS.XX_AR_SHIP_NO_INV_RPT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_SHIP_NO_INV_RPT_PKG" 
as
   /******************************************************************************
   -- Filename:  xxarshipnoinv.pkb
   -- RICEW Object id : R2R-RPT-071
   -- Purpose :  Package Body for Printing Shipped Not Invoiced Report
   --
   -- Usage: Concurrent Program ( Type PL/SQL Procedure)
   -- Caution:
   -- Copyright (c) IBM
   -- All rights reserved.
   -- Ver  Date         Author             Modification
   -- ---- -----------  ------------------ --------------------------------------
   -- 1.0  10-NOV-2012  NUPPARA            Created
   --
   --
   ******************************************************************************/
   function get_inv_activity(p_function in varchar2)
      return varchar2
   is
      type t_array_char is table of varchar2(80)
                              index by binary_integer;
      l_conc_seg_delimiter   varchar2(80);
      l_concat_segment       varchar2(4000);
      l_array                t_array_char;
      cursor c
      is
         select distinct '''' || p.process_name || ''''
           from wf_process_activities p, wf_activities wa
          where     p.process_item_type = 'OEOL'
                and wa.function = p_function
                and p.activity_item_type = wa.item_type
                and p.activity_name = wa.name
                and wa.type = 'FUNCTION'
                and p.process_version = (select max(p1.process_version)
                                           from wf_process_activities p1
                                          where p1.process_item_type = p.process_item_type and p1.process_name = p.process_name)
                and wa.version = (select max(wa1.version)
                                    from wf_activities wa1
                                   where wa1.item_type = wa.item_type and wa1.name = wa.name);
   begin

      open c;

      fetch c
      bulk collect into l_array;

      close c;

      for i in 1 .. l_array.count
      loop
         l_concat_segment := l_concat_segment || l_array(i);
         if i < l_array.count
         then
            l_concat_segment := l_concat_segment || ' , ';
         end if;
      end loop;
      return ' in (' || l_concat_segment || ' )';
   exception
      when others
      then
         return null;
   end get_inv_activity;

   function get_inv_function(p_function in varchar2)
      return varchar2
   is
      type t_array_char is table of varchar2(80)
                              index by binary_integer;
      l_conc_seg_delimiter   varchar2(80);
      l_concat_segment       varchar2(4000);
      l_array                t_array_char;
      cursor c
      is
         select distinct '''' || p.activity_name || ''''
           from wf_process_activities p, wf_activities wa
          where     p.process_item_type = 'OEOL'
                and wa.function = p_function
                and p.activity_item_type = wa.item_type
                and p.activity_name = wa.name
                and wa.type = 'FUNCTION'
                and p.process_version = (select max(p1.process_version)
                                           from wf_process_activities p1
                                          where p1.process_item_type = p.process_item_type and p1.process_name = p.process_name)
                and wa.version = (select max(wa1.version)
                                    from wf_activities wa1
                                   where wa1.item_type = wa.item_type and wa1.name = wa.name);
   begin

      open c;

      fetch c
      bulk collect into l_array;

      close c;

      for i in 1 .. l_array.count
      loop
         l_concat_segment := l_concat_segment || l_array(i);
         if i < l_array.count
         then
            l_concat_segment := l_concat_segment || ' , ';
         end if;
      end loop;
      return ' in (' || l_concat_segment || ' )';
   exception
      when others
      then
         return null;
   end get_inv_function;
   procedure print_report
   is
      cursor c1
      is
           select distinct order_number,
                           line_number,
                           '''' || item_number || '''' item,
                           item_description,
                           quantity,
                           unit_selling_price,
                           value,
                           customer_name,
                           line_type_name,
                           line_shippable_flag,
                           line_invoiceable_flag,
                           line_status,
                           line_ship_status,
                           line_return_status,
                           actual_shipment_date,
                           order_currency
             from xx_ar_no_invoice_lines
         group by order_number,
                  line_number,
                  '''' || item_number || '''',
                  item_description,
                  quantity,
                  unit_selling_price,
                  value,
                  customer_name,
                  line_type_name,
                  line_shippable_flag,
                  line_invoiceable_flag,
                  line_status,
                  line_ship_status,
                  line_return_status,
                  actual_shipment_date,
                  order_currency
         order by order_number, line_number;
   begin
      fnd_file.put_line(fnd_file.output, '<?xml version="1.0" encoding="UTF-8"?>');
      fnd_file.put_line(fnd_file.output, '<REPORT>');
      fnd_file.put_line(fnd_file.output, '<PARAMETERS>');
      fnd_file.put_line(fnd_file.output, '<OPERATING_UNIT><![CDATA[' || g_operating_unit || ']]></OPERATING_UNIT>');
      fnd_file.put_line(fnd_file.output, '</PARAMETERS>');
      for i in c1
      loop
         fnd_file.put_line(fnd_file.output, '<SUMMARY>');
         fnd_file.put_line(fnd_file.output, '<ORDER_NUMBER><![CDATA[' || i.order_number || ']]></ORDER_NUMBER>');
         fnd_file.put_line(fnd_file.output, '<LINE_NUMBER><![CDATA[' || i.line_number || ']]></LINE_NUMBER>');
         fnd_file.put_line(fnd_file.output, '<ITEM><![CDATA[' || i.item || ']]></ITEM>');
         fnd_file.put_line(fnd_file.output, '<ITEM_DESCRIPTION><![CDATA[' || i.item_description || ']]></ITEM_DESCRIPTION>');
         fnd_file.put_line(fnd_file.output, '<QUANTITY><![CDATA[' || i.quantity || ']]></QUANTITY>');
         fnd_file.put_line(fnd_file.output, '<UNIT_SELLING_PRICE><![CDATA[' || i.unit_selling_price || ']]></UNIT_SELLING_PRICE>');
         fnd_file.put_line(fnd_file.output, '<VALUE><![CDATA[' || i.value || ']]></VALUE>');
         fnd_file.put_line(fnd_file.output, '<CUSTOMER_NAME><![CDATA[' || i.customer_name || ']]></CUSTOMER_NAME>');
         fnd_file.put_line(fnd_file.output, '<LINE_TYPE_NAME><![CDATA[' || i.line_type_name || ']]></LINE_TYPE_NAME>');
         fnd_file.put_line(fnd_file.output, '<LINE_SHIPPABLE_FLAG><![CDATA[' || i.line_shippable_flag || ']]></LINE_SHIPPABLE_FLAG>');
         fnd_file.put_line(fnd_file.output, '<LINE_INVOICEABLE_FLAG><![CDATA[' || i.line_invoiceable_flag || ']]></LINE_INVOICEABLE_FLAG>');
         fnd_file.put_line(fnd_file.output, '<LINE_STATUS><![CDATA[' || i.line_status || ']]></LINE_STATUS>');
         fnd_file.put_line(fnd_file.output, '<LINE_SHIP_STATUS><![CDATA[' || i.line_ship_status || ']]></LINE_SHIP_STATUS>');
         fnd_file.put_line(fnd_file.output, '<LINE_RETURN_STATUS><![CDATA[' || i.line_return_status || ']]></LINE_RETURN_STATUS>');
         fnd_file.put_line(fnd_file.output, '<ACTUAL_SHIPMENT_DATE><![CDATA[' || i.actual_shipment_date || ']]></ACTUAL_SHIPMENT_DATE>');
         fnd_file.put_line(fnd_file.output, '<ORDER_CURRENCY><![CDATA[' || i.order_currency || ']]></ORDER_CURRENCY>');
         fnd_file.put_line(fnd_file.output, '</SUMMARY>');
      end loop;
      fnd_file.put_line(fnd_file.output, '</REPORT>');
   exception
      when others
      then
         fnd_file.put_line(fnd_file.log, 'Error Occured in Printing Report');
   end print_report;
   procedure generate_report(errcode out varchar2, return_status out varchar2, p_operating_unit in number)
   is
      l_char            varchar2(32767);
      l_activity_name   varchar2(100);
      l_activity_type   varchar2(100);
      l_wa_type         varchar2(100);
      l_status          varchar2(100);
      l_return_status   varchar2(100);
      l_return_date     date;
      x_count           number := 0;
      x_error_code      varchar2(400);
      type refcursor is ref cursor;
      c1                refcursor;
      cursor c
      is
         select distinct process_name from xx_ar_no_invoice_lines;
      cursor c2
      is
         select line_id from xx_ar_no_invoice_lines;
      cursor c3
      is
         select line_id
           from xx_ar_no_invoice_lines
          where line_category_code = 'RETURN';
   begin
      x_error_code := xx_emf_pkg.set_env;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Start of report');
      mo_global.set_policy_context('S', p_operating_unit);
      begin

         select name
           into g_operating_unit
           from hr_operating_units
          where organization_id = p_operating_unit;

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in getting OU information');
      end;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Report of the Operating Unit :' || g_operating_unit);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Collecting all booked but open lines.');

      begin

         insert into xx_ar_no_invoice_lines(line_id,
                                            line_type_id,
                                            line_type_name,
                                            process_name,
                                            inventory_item_id,
                                            order_number,
                                            line_number,
                                            quantity,
                                            unit_selling_price,
                                            value,
                                            customer_name,
                                            actual_shipment_date,
                                            order_source_id,
                                            order_currency)
            select a.line_id,
                   a.line_type_id,
                   c.name,
                   b.process_name,
                   a.inventory_item_id,
                   d.order_number,
                   decode(a.line_number, null, null, a.line_number) || decode(a.shipment_number, null, null, '.' || a.shipment_number) ||
                   decode(
                   a.option_number,
                   null, null,
                   '.' || a.option_number) || decode(a.component_number, null, null, '.' || a.component_number) || decode(a.service_number
                   ,
                   null, null,
                   '.' || a.service_number),
                   (a.ordered_quantity - nvl(a.cancelled_quantity, 0)),
                   a.unit_selling_price,
                   (a.ordered_quantity - nvl(a.cancelled_quantity, 0)) * a.unit_selling_price,
                   party_name,
                   nvl(a.actual_shipment_date, booked_date),
                   a.source_document_type_id,
                   d.transactional_curr_code
              from oe_order_lines_all a,
                   oe_workflow_assignments b,
                   oe_line_types_v c,
                   oe_order_headers_all d,
                   hz_cust_accounts e,
                   hz_parties f
             where     b.line_type_id = c.line_type_id
                   and d.order_type_id=b.order_type_id
                    and trunc(sysdate) between nvl(trunc(b.start_date_active),trunc(sysdate)) and nvl(trunc(b.end_date_active),trunc(sysdate+1)) 
                   and a.booked_flag = 'Y'
                   and a.open_flag = 'Y'
                   and a.cancelled_flag = 'N'
                   and a.line_type_id = c.line_type_id
                   and a.header_id = d.header_id
                   and d.order_type_id = b.order_type_id
                   and a.sold_to_org_id = e.cust_account_id
                   and e.party_id = f.party_id;

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in inserting');
      end;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records collected :' || sql%rowcount);
      x_count := 0;
      for i in c
      loop

         l_activity_name := null;
         l_activity_type := null;
         l_wa_type := null;

         open c1 for
            'select p.activity_name, p.activity_item_type, wa.type
           from wf_process_activities p, wf_activities wa
          where     p.process_item_type = ''OEOL''
                and p.process_name = ''' || i.process_name ||
            '''
                and p.activity_item_type = wa.item_type
                and p.activity_name = wa.name
                and ( (wa.type = ''PROCESS'' and p.activity_name ' || get_inv_activity('OE_INVOICE_WF.INVOICE_INTERFACE') ||
            ')
          or (wa.type = ''FUNCTION'' and p.activity_name ' || get_inv_function('OE_INVOICE_WF.INVOICE_INTERFACE') ||
            '))
       and p.process_version = (select max (p1.process_version)
                                  from wf_process_activities p1
                                 where p1.process_item_type = p.process_item_type and p1.process_name = p.process_name)
       and wa.version = (select max (wa1.version)
                           from wf_activities wa1
                          where wa1.item_type = wa.item_type and wa1.name = wa.name)';

         fetch c1
         into l_activity_name, l_activity_type, l_wa_type;

         close c1;

         --dbms_output.put_line(l_activity_name);
         --dbms_output.put_line(l_activity_type);
         --dbms_output.put_line(l_wa_type);
         if l_activity_name is not null
         then
            begin

               update xx_ar_no_invoice_lines
                  set line_has_inv_activity = 'Yes',
                      inv_activity_name = l_activity_name,
                      inv_activity_item_type = l_activity_type,
                      inv_activity_type = l_wa_type
                where process_name = i.process_name;

            exception
               when others
               then
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in updating the invoice activity update');
            end;

            x_count := x_count + 1;

         end if;
      end loop;
      for i in c
      loop

         l_activity_name := null;
         l_activity_type := null;
         l_wa_type := null;

         open c1 for
            'select p.activity_name, p.activity_item_type, wa.type
           from wf_process_activities p, wf_activities wa
          where     p.process_item_type = ''OEOL''
                and p.process_name = ''' || i.process_name ||
            '''
                and p.activity_item_type = wa.item_type
                and p.activity_name = wa.name
                and ( (wa.type = ''PROCESS'' and p.activity_name ' || get_inv_activity('OE_SHIPPING_WF.START_SHIPPING') ||
            ')
          or (wa.type = ''FUNCTION'' and p.activity_name ' || get_inv_function('OE_SHIPPING_WF.START_SHIPPING') ||
            '))
       and p.process_version = (select max (p1.process_version)
                                  from wf_process_activities p1
                                 where p1.process_item_type = p.process_item_type and p1.process_name = p.process_name)
       and wa.version = (select max (wa1.version)
                           from wf_activities wa1
                          where wa1.item_type = wa.item_type and wa1.name = wa.name)';

         fetch c1
         into l_activity_name, l_activity_type, l_wa_type;

         close c1;

         if l_activity_name is not null
         then
            begin

               update xx_ar_no_invoice_lines
                  set line_has_ship_activity = 'Yes',
                      ship_activity_name = l_activity_name,
                      ship_activity_item_type = l_activity_type,
                      ship_activity_type = l_wa_type
                where process_name = i.process_name;

            exception
               when others
               then
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in updating shipping activity');
            end;
            x_count := x_count + 1;
         end if;
      end loop;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated as invoiceable ' || x_count);
      begin

         update xx_ar_no_invoice_lines a
            set (inventory_item_id, line_category_code) =
                   (select inventory_item_id, line_category_code
                      from oe_order_lines_all c
                     where a.line_id = c.line_id);

         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in updating the item_id information');
      end;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for item ' || sql%rowcount);
      begin

         update xx_ar_no_invoice_lines a
            set (item_number, item_description) =
                   (select segment1, description
                      from mtl_system_items_b b
                     where organization_id = oe_sys_parameters.value('MASTER_ORGANIZATION_ID', null)
                           and b.inventory_item_id = a.inventory_item_id);

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception updating the item number information');
      end;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for item description ' || sql%rowcount);
      begin

         update xx_ar_no_invoice_lines a
            set line_shippable_flag = 'Yes'
          where line_has_ship_activity = 'Yes' and line_category_code = 'ORDER'
                and exists
                       (select 1
                          from mtl_system_items_b b, oe_order_lines_all c
                         where     b.organization_id = nvl(ship_from_org_id, oe_sys_parameters.value('MASTER_ORGANIZATION_ID', null))
                               and b.inventory_item_id = c.inventory_item_id
                               and a.line_id = c.line_id
                               and shippable_item_flag = 'Y'
                               and c.source_type_code = 'INTERNAL');

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exeception occured in updaing shippable flag');
      end;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for shippable flag ' || sql%rowcount);
      begin

         update xx_ar_no_invoice_lines a
            set line_invoiceable_flag = 'Yes'
          where line_has_inv_activity = 'Yes'
                and exists
                       (select 1
                          from mtl_system_items_b b, oe_order_lines_all c
                         where     b.organization_id = nvl(ship_from_org_id, oe_sys_parameters.value('MASTER_ORGANIZATION_ID', null))
                               and b.inventory_item_id = c.inventory_item_id
                               and a.line_id = c.line_id
                               and invoiceable_item_flag = 'Y');

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in updating invoiceable flag');
      end;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for invoiceable flag ' || sql%rowcount);
      begin

         update xx_ar_no_invoice_lines a
            set shipped_or_returned_flag = 'Yes'
          where exists
                   (select 1
                      from oe_order_lines_all b
                     where a.line_id = b.line_id and b.shipped_quantity <> 0);

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception when others then shipped or returned flags');
      end;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for shipped or returnd flag ' || sql%rowcount);
      begin

         update xx_ar_no_invoice_lines a
            set line_ship_status =
                   (select distinct released_status_name
                      from wsh_deliverables_v b
                     where a.line_id = b.source_line_id and b.source_code = 'OE' and released_status not in ('D', 'B'));

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in updating line shipping status');
      end;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for shipping status  ' || sql%rowcount);
      x_count := 0;
      for i in c2
      loop
         l_status := null;
         l_status := oe_line_status_pub.get_line_status(i.line_id, null);
         begin

            update xx_ar_no_invoice_lines
               set line_status = l_status
             where line_id = i.line_id;

         exception
            when others
            then
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in updating line status');
         end;
         x_count := x_count + 1;

      end loop;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for line status  ' || x_count);
      x_count := 0;
      for i in c3
      loop
         l_return_status := null;
         oe_line_status_pub.get_received_status(i.line_id, l_return_status, l_return_date);
         begin

            update xx_ar_no_invoice_lines
               set line_return_status = l_return_status
             where line_id = i.line_id;

         exception
            when others
            then
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in updating line return status');
         end;
         x_count := x_count + 1;
      end loop;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records updated for return status  ' || sql%rowcount);
      begin

         delete xx_ar_no_invoice_lines
          where nvl(line_has_inv_activity, 'No') <> 'Yes';

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in deleting the lines that are not invoiceable');
      end;

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Deleted lines from global temporary table that are not invoiceable');
      begin

         delete xx_ar_no_invoice_lines
          where (line_shippable_flag is not null OR line_has_ship_activity ='Yes') 
          and line_category_code = 'ORDER' and nvl(line_ship_status, 'X') <> 'Shipped';
         
          delete xx_ar_no_invoice_lines
          where line_status in ('Booked','Picked')
          and line_category_code = 'ORDER'
          and line_ship_status is null; 

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in deleting the lines that are shippable but not shipped');
      end;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,
                           'Deleted lines from global temporary table that are not shipped yet. This is only for shippable lines');
      begin

         delete xx_ar_no_invoice_lines
          where line_has_inv_activity = 'Yes' and line_category_code = 'RETURN' and nvl(line_return_status, 'X') <> 'Y';

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in deleting the lines that are returnable but not returned yet');
      end;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Deleted lines from global temporary table that are not returned yet');

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Collecting all the records in AR interface that have been processed yet');
      begin

         delete xx_ar_no_invoice_lines a
          where order_source_id = 10
                and exists
                       (select 1
                          from oe_order_lines_all b,
                               po_requisition_headers_all c,
                               po_requisition_lines_all d,
                               cst_organization_definitions e,
                               cst_organization_definitions f
                         where     b.org_id = p_operating_unit
                               and a.line_id = b.line_id
                               and c.type_lookup_code = 'INTERNAL'
                               and b.orig_sys_document_ref = c.segment1
                               and b.orig_sys_line_ref = d.line_num
                               and b.org_id = c.org_id
                               and c.requisition_header_id = d.requisition_header_id
                               and b.order_source_id = 10
                               and d.source_organization_id = e.organization_id
                               and d.destination_organization_id = f.organization_id
                               and e.operating_unit = f.operating_unit);

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in deleting the lines that internal within the same OU');
      end;
      begin

         insert into xx_ar_no_invoice_lines(order_number,
                                            line_id,
                                            line_number,
                                            quantity,
                                            unit_selling_price,
                                            value,
                                            customer_name,
                                            inventory_item_id,
                                            item_number,
                                            item_description,
                                            order_currency,
                                            actual_shipment_date,
                                            LINE_INVOICEABLE_FLAG,line_type_name)
            select f.order_number,
                   e.line_id,
                   (decode(e.line_number, null, null, e.line_number) || decode(e.shipment_number, null, null, '.' || e.shipment_number) ||
                    decode(
                    e.option_number,
                    null, null,
                    '.' || e.option_number) || decode(e.component_number, null, null, '.' || e.component_number) || decode(e.service_number
                    ,
                    null, null,
                    '.' || e.service_number)),
                   quantity,
                   a.unit_selling_price,
                   a.quantity * a.unit_selling_price,
                   c.party_name,
                   d.inventory_item_id,
                   d.segment1,
                   d.description,
                   f.transactional_curr_code,
                   e.actual_shipment_date,
                   'Yes',
                   g.name
              from ra_interface_lines_all a,
                   hz_cust_accounts b,
                   hz_parties c,
                   mtl_system_items_b d,
                   oe_order_lines_all e,
                   oe_order_headers_all f,
                   oe_line_types_v g
             where     a.org_id = p_operating_unit
                   and a.interface_line_context in ('ORDER ENTRY', 'INTERCOMPANY')
                   and a.orig_system_bill_customer_id = b.cust_account_id
                   and b.party_id = c.party_id
                   and a.inventory_item_id = d.inventory_item_id
                   and a.line_type = 'LINE'
                   and a.interface_line_attribute6 = e.line_id
                   and e.header_id = f.header_id
                   and e.line_type_id=g.line_type_id
                   and d.organization_id = nvl(a.warehouse_id, oe_sys_parameters.value('MASTER_ORGANIZATION_ID', null));

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in collecting records from AR interface');
      end;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of records collected from AR interface :' || sql%rowcount);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,
                           'Collecting all the intercompany records in MMT that have been processed yet by create intercompany
      AR invoices program');
      begin

         insert into xx_ar_no_invoice_lines(order_number,
                                            line_id,
                                            line_number,
                                            quantity,
                                            unit_selling_price,
                                            value,
                                            customer_name,
                                            inventory_item_id,
                                            item_number,
                                            item_description,
                                            order_currency,
                                            actual_shipment_date,
                                            line_invoiceable_flag,
                                            line_type_name)
            select f.order_number,
                   e.line_id,
                   (decode(e.line_number, null, null, e.line_number) || decode(e.shipment_number, null, null, '.' || e.shipment_number) ||
                    decode(
                    e.option_number,
                    null, null,
                    '.' || e.option_number) || decode(e.component_number, null, null, '.' || e.component_number) || decode(e.service_number
                    ,
                    null, null,
                    '.' || e.service_number)),
                   abs(a.transaction_quantity),
                   a.transfer_price,
                   abs(a.transaction_quantity * a.transfer_price),
                   c.party_name,
                   d.inventory_item_id,
                   d.segment1,
                   d.description,
                   f.transactional_curr_code,
                   e.actual_shipment_date,
                   case when d.invoiceable_item_flag='Y' then 'Yes' else 'No' end,
                   i.name
              from mtl_material_transactions a,
                   hz_cust_accounts b,
                   hz_parties c,
                   mtl_system_items_b d,
                   oe_order_lines_all e,
                   oe_order_headers_all f,
                   cst_organization_definitions g,
                   cst_organization_definitions h,
                   oe_line_types_v i
             where     g.operating_unit = p_operating_unit
                   and nvl(a.invoiced_flag, 'Y') = 'N'
                   and a.transaction_type_id in (62, 10)
                   and e.sold_to_org_id = b.cust_account_id
                   and b.party_id = c.party_id
                   and a.inventory_item_id = d.inventory_item_id
                   and a.organization_id = g.organization_id
                   and a.transfer_organization_id = h.organization_id
                   and g.operating_unit <> h.operating_unit
                   and a.trx_source_line_id = e.line_id
                   and e.header_id = f.header_id
                   and d.organization_id = a.organization_id
                   and i.line_type_Id=e.line_type_id;

      exception
         when others
         then
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Exception occured in collecting records from MMT');
      end;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number of intercompany records collected from MMTe :' || sql%rowcount);

      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Printing Report');
      print_report;
   exception
      when others
      then
         fnd_file.put_line(fnd_file.log, 'Error in Generating Report : ' || sqlerrm);
   end generate_report;
end xx_ar_ship_no_inv_rpt_pkg; 
/
