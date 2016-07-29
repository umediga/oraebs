DROP PACKAGE BODY APPS.XX_AP_UNRECORD_LIAB_RPT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_UNRECORD_LIAB_RPT_PKG" 
as
   procedure debug(p_type in number, p_msg in varchar2)
   is
   begin
      --dbms_output.put_line(p_msg);
      fnd_file.put_line(fnd_file.output, p_msg);
   end;
   procedure print_xml_element(p_field in varchar2, p_value in varchar2)
   is
   begin
      fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
      --debug(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
   --debug('fnd_file.put_line( fnd_file.output,'|| '''<' || upper(p_field) || '><![CDATA[''||' || upper(p_field) || '||'']]></' || upper(p_field) || '>'')');
   end;

   procedure print_xml_element(p_field in varchar2, p_value in number)
   is
   begin
      fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '>' || p_value || '</' || upper(p_field) || '>');
      --debug(fnd_file.output, '<' || upper(p_field) || '>' || p_value || '</' || upper(p_field) || '>');
   --debug('fnd_file.put_line( fnd_file.output,'|| '''<' || upper(p_field) || '><![CDATA[''||' || upper(p_field) || '||'']]></' || upper(p_field) || '>'')');
   end;

   procedure print_xml_element(p_field in varchar2, p_value in date)
   is
   begin
      fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
      --debug(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
   --debug('fnd_file.put_line( fnd_file.output,'|| '''<' || upper(p_field) || '><![CDATA[''||' || upper(p_field) || '||'']]></' || upper(p_field) || '>'')');
   end;
   procedure print_report(errbuf             out varchar2,
                          retcode            out varchar2,
                          p_ledger_id     in     number,
                          p_period_name   in     varchar2,
                          p_show_all_dist in varchar2)
   is
      l_ledger_name   varchar2(100);
      cursor c
      is
         select ap.invoice_num,
                ap.invoice_id,
                ap.last_update_date,
                lkp.displayed_field invoice_type,
                ap.description,
                ap.gl_date,
                ap.invoice_date,
                aps.vendor_name,
                aps.segment1,
                apsa.vendor_site_code,
                ap.invoice_currency_code,
                alc.displayed_field distribution_type,
                apad.amount amount_dr,
                apad.amount amount_cr,
                liab.concatenated_segments account_cr,
                chg.concatenated_segments account_dr,
                fa_rx_flex_pkg.get_description(101,
                                               'GL#',
                                               liab.chart_of_accounts_id,
                                               '3',
                                               liab.segment3)
                   acct_cr_desc,
                fa_rx_flex_pkg.get_description(101,
                                               'GL#',
                                               liab.chart_of_accounts_id,
                                               '3',
                                               chg.segment3)
                   acct_dr_desc,
                null intercompany,
                liab.segment1 cr_company,
                chg.segment1 dr_company,
                nvl((select max(segment1)
                       from pa_projects_all a
                      where a.project_id = apad.project_id),
                    'No Project')
                   project,
                nvl((  select max(segment1)
                         from po_headers_all po, po_distributions_all pod
                        where po.po_header_id = pod.po_header_id and pod.po_distribution_id = apad.po_distribution_id
                     group by segment1),
                    'No PO')
                   po_num,
              nvl((SELECT POCHG.CONCATENATED_SEGMENTS FROM  PO_DISTRIBUTIONS_ALL POD,GL_CODE_COMBINATIONS_KFV POCHG
              WHERE POCHG.CODE_COMBINATION_ID = POD.CODE_COMBINATION_ID
              AND POD.PO_DISTRIBUTION_ID = APAD.PO_DISTRIBUTION_ID),'No PO Charge Account') PO_CHARGE_ACCOUNT,
              nvl((select  fa_rx_flex_pkg.get_description(101,
                                               'GL#',
                                               pochg.chart_of_accounts_id,
                                               '3',
                                               POCHG.SEGMENT3)
                                               FROM  PO_DISTRIBUTIONS_ALL POD,GL_CODE_COMBINATIONS_KFV POCHG
                                                WHERE POCHG.CODE_COMBINATION_ID = POD.CODE_COMBINATION_ID
                                              AND POD.PO_DISTRIBUTION_ID = APAD.PO_DISTRIBUTION_ID),'No Description') PO_CHARGE_ACCOUNT_DESC
           from ap_invoices_all ap,
                ap_lookup_codes lkp,
                ap_suppliers aps,
                ap_supplier_sites_all apsa,
                ap_invoice_distributions_all apad,
                ap_lookup_codes alc,
                gl_code_combinations_kfv liab,
                gl_code_combinations_kfv chg
          where     ap.set_of_books_id = p_ledger_id
                and ap.invoice_type_lookup_code = lkp.lookup_code
                and lkp.lookup_type = 'INVOICE TYPE'
                and ap.vendor_id = aps.vendor_id
                and ap.vendor_site_id = apsa.vendor_site_id
                and aps.vendor_id = apsa.vendor_id
                and ap.invoice_id = apad.invoice_id
                and alc.lookup_type = 'INVOICE DISTRIBUTION TYPE'
                and alc.lookup_code = apad.line_type_lookup_code
             ---   and alc.lookup_code not like '%TAX%'  --- Removed Case # 007562
                and ap.accts_pay_code_combination_id = liab.code_combination_id
                and apad.dist_code_combination_id = chg.code_combination_id
                and ap.gl_date between (select start_date
                                          from gl_period_statuses
                                         where application_id = 200 and period_name = p_period_name and ledger_id = p_ledger_id)
                                   and (select end_date
                                          from gl_period_statuses
                                         where application_id = 200 and period_name = p_period_name and ledger_id = p_ledger_id)
                and case when  p_show_all_dist='Y' then
                (select start_date-1
                                             from gl_period_statuses
                                            where application_id = 200 and period_name = p_period_name and ledger_id = p_ledger_id)
                else
                trunc(invoice_date) end
                 < (select start_date
                                             from gl_period_statuses
                                            where application_id = 200 and period_name = p_period_name and ledger_id = p_ledger_id);
   begin
      begin

         select name
           into l_ledger_name
           from gl_ledgers
          where ledger_id = p_ledger_id;

      exception
         when others
         then
            l_ledger_name := null;
      end;
      debug(fnd_file.output, '<?xml version="1.0" encoding="UTF-8"?>');
      debug(1, '<REPORT>');
      debug(1, '<PARAMETERS>');
      print_xml_element('LEDGER_NAME', l_ledger_name);
      print_xml_element('PERIOD_NAME', '@' || p_period_name);
      debug(1, '</PARAMETERS>');

      for i in c
      loop
         debug(1, '<SUMMARY>');
         print_xml_element('INVOICE_NUM', '@'||i.invoice_num);
         print_xml_element('INVOICE_ID', i.invoice_id);
         print_xml_element('LAST_UPDATE_DATE', i.last_update_date);
         print_xml_element('INVOICE_TYPE', i.invoice_type);
         print_xml_element('INVOICE_DESC', i.description);
         print_xml_element('INVOICE_GL_DATE', i.gl_date);
         print_xml_element('INVOICE_DATE', i.invoice_date);
         print_xml_element('VENDOR_NAME', i.vendor_name);
         print_xml_element('VENDOR_NUM', i.segment1);
         print_xml_element('VENDOR_SITE', i.vendor_site_code);
         print_xml_element('INVOICE_CURRENCY', i.invoice_currency_code);
         print_xml_element('INVOICE_TYPE', i.invoice_type);
         print_xml_element('INVOICE_DIST_TYPE', i.distribution_type);
         print_xml_element('AMOUNT_DR', i.amount_dr);
         print_xml_element('AMOUNT_CR', i.amount_cr);
         print_xml_element('ACCOUNT_DR', i.account_dr);
         print_xml_element('ACCOUNT_CR', i.account_cr);
         print_xml_element('ACCOUNT_CR_DSC', i.acct_cr_desc);
         print_xml_element('ACCOUNT_DR_DSC', i.acct_dr_desc);
         print_xml_element('INTERCOMPANY', i.intercompany);
         print_xml_element('CR_COMPANY', i.cr_company);
         print_xml_element('DR_COMPANY', i.dr_company);
         print_xml_element('PROJECT', i.project);
         print_xml_element('PO_NUM', i.po_num);
         print_xml_element('PO_CHARGE_ACCOUNT', i.po_charge_account);
         print_xml_element('PO_CHARGE_ACCOUNT_DESC', i.po_charge_account_desc);
         debug(1, '</SUMMARY>');
      end loop;
      debug(1, '</REPORT>');

   end;
end;
/
