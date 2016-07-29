DROP PACKAGE BODY APPS.XX_AP_DEBIT_MEMO_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AP_DEBIT_MEMO_PKG" as
  main_query clob := 'select  zp.party_name  C_vendor_name,
           zl.address1  C_address_line1,
           zl.address2   C_address_line2,
           zl.address3   C_address_line3,
           zl.city || '', '' || nvl(zl.state, zl.province)
                   || ''  '' || zl.postal_code   C_city_state_zip,
           zl.country  C_country,
           inv.invoice_id  C_invoice_id,
           nvl(to_char(inv.doc_sequence_value),inv.invoice_num)  C_invoice_num,
           --inv.invoice_num  C_invoice_num,
           inv.invoice_currency_code  C_currency_code,
           nvl(inv.invoice_amount,0) C_invoice_amount,
           inv.description  C_invoice_descr,
           inv.invoice_date  C_invoice_date,
           inv.creation_date  C_inv_entered_date,
           inv.invoice_type_lookup_code  C_invoice_type,
           decode(l.lookup_code, ''DEBIT'', l.displayed_field,
                  ''CREDIT'', l.displayed_field,
                  ''EXPENSE REPORT'', l.displayed_field,
                  ''PREPAYMENT'', l.displayed_field,
                  l.lookup_code)  C_dsp_inv_type,
           inv.terms_id,
           zps.language,
           inv.party_id,
           inv.legal_entity_id,
           aps.segment1 vendor_num,
           inv.vendor_site_id
from       ap_invoices inv,
           hz_parties zp,
           hz_party_sites zps,
           hz_locations zl,
           ap_suppliers aps,
           ap_lookup_codes l
where  zps.party_site_id = inv.party_site_id
and    zp.party_id = inv.party_id
and    zl.location_id = zps.location_id
and    inv.vendor_id = aps.vendor_id(+)
and     inv.invoice_type_lookup_code = l.lookup_code
and     l.lookup_type = ''INVOICE TYPE''
$C_LANGUAGE_WHERE$
$C_VENDOR_ID_PREDICATE$
$C_INVOICE_TYPE_PREDICATE$
$C_INVOICE_ID_PREDICATE$
$C_START_DATE_PREDICATE$
$C_END_DATE_PREDICATE$
order by zp.party_name,  inv.invoice_num';

  procedure debug(p_type in number, p_msg in varchar2) is
  begin
    dbms_output.put_line(p_msg);
    fnd_file.put_line(fnd_file.output, p_msg);
  end;

  procedure print_xml_element(p_field in varchar2, p_value in varchar2) is
  begin
    fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
  --debug(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
  --debug('fnd_file.put_line( fnd_file.output,'|| '''<' || upper(p_field) || '><![CDATA[''||' || upper(p_field) || '||'']]></' || upper(p_field) || '>'')');
  end;

  procedure print_xml_element(p_field in varchar2, p_value in number) is
  begin
    fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '>' || p_value || '</' || upper(p_field) || '>');
  --debug(fnd_file.output, '<' || upper(p_field) || '>' || p_value || '</' || upper(p_field) || '>');
  --debug('fnd_file.put_line( fnd_file.output,'|| '''<' || upper(p_field) || '><![CDATA[''||' || upper(p_field) || '||'']]></' || upper(p_field) || '>'')');
  end;

  procedure print_xml_element(p_field in varchar2, p_value in date) is
  begin
    fnd_file.put_line(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
  --debug(fnd_file.output, '<' || upper(p_field) || '><![CDATA[' || p_value || ']]></' || upper(p_field) || '>');
  --debug('fnd_file.put_line( fnd_file.output,'|| '''<' || upper(p_field) || '><![CDATA[''||' || upper(p_field) || '||'']]></' || upper(p_field) || '>'')');
  end;

  function get_msg_value(p_msg_name in varchar2, p_language in varchar2)
    return varchar2 is
    l_msg_text fnd_new_messages.message_text%type;
  begin
    select message_text
    into   l_msg_text
    from   fnd_new_messages
    where      message_name = p_msg_name
           and language_code = p_language
           and application_id = (select application_id
                                 from   fnd_application
                                 where  application_short_name = 'XXINTG');

    if p_msg_name in ('INTG_AP_DEBIT_MEMO_SUPP_TAX' --, 'INTG_AP_DEBIT_MEMO_LE_TAX'
                                                    --, 'INTG_AP_DEBIT_MEMO_LEGAL_FOOT'
                      , 'INTG_AP_DEBIT_MEMO_DEL_INV_DAT') and p_language <> 'D' then
      l_msg_text := null;
    end if;

    return l_msg_text;
  exception
    when others then
      return null;
  end;

  function print_labels
    return number is
    l_language varchar2(1000);
    l_msg_text varchar2(1000);
    session_language varchar2(100);

    cursor c is
      select 'INTG_AP_DEBIT_MEMO_TYPE' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_ADDRESS' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_SUPP_NAME' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_SHIP_TO' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_INVOICE_TO' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_DATE' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_SUPP_NUM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PO_DATE' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PO_REV' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_TERMS' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PO_ORDER' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PO_REV_NUM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PO_REL_NUM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PO_INV_NUM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PO_NOTES' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_REQUESTER' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_CONTACT' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_LINE_NUM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_ITEM_NUM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_PROM_DATE' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_LINE_QTY' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_LINE_UOM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_LINE_PRICE' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_LINE_VALUE' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_LINE_TAX' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_COMMENTS' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_TOTAL' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_BUYER' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_BUYER_EMAIL' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_BUYER_TEL' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_SUPP_ITEM' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_SUPP_TAX' msg_name
      from   dual
      /*union
      select 'INTG_AP_DEBIT_MEMO_LE_TAX' msg_name
      from   dual*/
      union
      select 'INTG_AP_DEBIT_MEMO_DEL_INV_DAT' msg_name
      from   dual
      /*union
      select 'INTG_AP_DEBIT_MEMO_LEGAL_FOOT' msg_name
      from   dual*/
      union
      select 'INTG_AP_DEBIT_MEMO_DEDUCT_PAY' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_ITEM_TOT' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_TAX' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_SUPP_CNAME' msg_name
      from   dual
      union
      select 'INTG_AP_DEBIT_MEMO_SUPP_CNUM' msg_name
      from   dual;
  begin
    if g_supp_site_lang is not null then
      l_language := g_supp_site_lang;
    elsif g_supp_site_lang is null and g_language is not null then
      l_language := g_language;
    elsif g_supp_site_lang is null and g_language is null then
      select substr(userenv('LANGUAGE'), 1, instr(userenv('LANGUAGE'), '_') - 1)
      into   session_language
      from   dual;

      begin
        select language_code
        into   l_language
        from   fnd_languages
        where  nls_language = session_language;
      exception
        when others then
          select language_code
          into   l_language
          from   fnd_languages
          where  installed_flag = 'B';
      end;
    end if;

    debug(fnd_file.output, '<G_LABELS>');

    for i in c loop
      l_msg_text := null;
      
      fnd_file.put_line( fnd_file.log, i.msg_name || ' '|| l_language); 
     
      
      l_msg_text := get_msg_value(i.msg_name, l_language);
      print_xml_element(i.msg_name, l_msg_text);
    end loop;

    debug(fnd_file.output, '</G_LABELS>');
    return 1;
  exception
    when others then
      return 0;
  end;

  function getvendoraddressline1(p_vendor_site_id in number)
    return varchar2 is
    l_city po_vendor_sites.city%type := null;
    l_state po_vendor_sites.state%type := null;
    l_zip po_vendor_sites.zip%type := null;
    l_address_line_1 po_vendor_sites.address_line1%type := null;
    l_address_line_2 po_vendor_sites.address_line2%type := null;
    l_address_line_3 po_vendor_sites.address_line3%type := null;
    l_address_line_4 po_vendor_sites.address_line4%type := null;
    l_country fnd_territories_vl.territory_short_name%type := null;
    l_city_state_zipinfo varchar2(200);
    l_site_country varchar2(100);
    l_address_info varchar2(4000);
  begin
    select pvs.address_line1
         , pvs.address_line2
         , pvs.address_line3
         , pvs.city
         , decode(pvs.state, null, decode(pvs.province, null, pvs.county, pvs.province), pvs.state)
         , pvs.zip
         , fte.territory_short_name
         , pvs.address_line4
         , pvs.country
    into   l_address_line_1
         , l_address_line_2
         , l_address_line_3
         , l_city
         , l_state
         , l_zip
         , l_country
         , l_address_line_4
         , l_site_country
    from   po_vendor_sites_all pvs, fnd_territories_vl fte
    where  pvs.country = fte.territory_code --and decode(fte.territory_code, null, '1') = decode(fte.territory_code, null, '1')
                                           and pvs.vendor_site_id = p_vendor_site_id;

    if (l_city is null) then
      l_city_state_zipinfo := l_state || ' ' || l_zip;
    else
      l_city_state_zipinfo := l_city || ',' || l_state || ' ' || l_zip;
    end if;

    if l_site_country = 'DE' then
      select    case
                  when loc.address_line1 is null then '*'
                  when loc.address_line1 = '-' then ' '
                  else loc.address_line1
                end
             || ' '
             || case
                  when loc.address_line2 is null then '*'
                  when loc.address_line2 = '-' then ' '
                  else loc.address_line2
                end
             || chr(13)
             || case
                  when loc.address_line3 is null then '*'
                  when loc.address_line3 = '-' then null
                  else loc.address_line3 || chr(13)
                end
             || loc.zip
             || ' '
             || case
                  when loc.city is null then '*'
                  when loc.city = '-' then ' '
                  else city
                end
             || chr(13)
             || territory_short_name
      into   l_address_info
      from   po_vendor_sites_all loc, fnd_territories_vl fte
      where  loc.country = fte.territory_code --and decode(fte.territory_code, null, '1') = decode(fte.territory_code, null, '1')
                                             and loc.vendor_site_id = p_vendor_site_id;
    elsif l_site_country <> 'DE' then
      select    case
                  when loc.address_line1 is null then null
                  when loc.address_line1 = '-' then ''
                  else loc.address_line1 || chr(13)
                end
             || case
                  when loc.address_line2 is null then null
                  when loc.address_line2 = '-' then ''
                  else loc.address_line2 || chr(13)
                end
             || case
                  when loc.address_line3 is null then null
                  when loc.address_line3 = '-' then ''
                  else loc.address_line3 || chr(13)
                end
             || case
                  when loc.city is null then ' '
                  when loc.city = '-' then ' '
                  else city
                end
             || ' '
             || loc.state
             || ' '
             || loc.zip
             || ' '
             || chr(13)
             || territory_short_name
      into   l_address_info
      from   po_vendor_sites_all loc, fnd_territories_vl fte
      where  loc.country = fte.territory_code --and decode(fte.territory_code, null, '1') = decode(fte.territory_code, null, '1')
                                             and loc.vendor_site_id = p_vendor_site_id;
    end if;

    select replace(l_address_info, '*', '') -- Sankar Narayanan added 25-MAR-2013
    into   l_address_info
    from   dual; -- Sankar Narayanan added 25-MAR-2013
    print_xml_element('SUPP_ADD_1', l_address_info);
    print_xml_element('SUPP_ADD_2', l_address_line_2);
    print_xml_element('SUPP_ADD_3', l_address_line_3);
    print_xml_element('SUPP_ADD_4', l_address_line_4);
    print_xml_element('SUPP_CITY_ZIP', l_city_state_zipinfo);
    print_xml_element('SUPP_COUNTRY', l_country);
    return l_address_line_1;
  exception
    when others then
      return null;
  end;

  function getphone(p_agent_id in number)
    return varchar2 is
    l_buyer_email varchar2(100);
    l_buyer_phone varchar2(100);
    l_buyer_fax varchar2(100);
  begin
    select pap.email_address, pph.phone_number
    into   l_buyer_email, l_buyer_phone
    from   per_phones pph, per_all_people_f pap
    where      pph.parent_id(+) = pap.person_id
           and pph.parent_table(+) = 'PER_ALL_PEOPLE_F'
           and pph.phone_type(+) = 'W1'
           and pap.person_id = p_agent_id
           and trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
           and trunc(sysdate) between nvl(pph.date_from, trunc(sysdate)) and nvl(pph.date_to, trunc(sysdate))
           and rownum = 1;
    select pph.phone_number
    into   l_buyer_fax
    from   per_phones pph, per_all_people_f pap
    where      pph.parent_id(+) = pap.person_id
           and pph.parent_table(+) = 'PER_ALL_PEOPLE_F'
           and pph.phone_type(+) = 'WF'
           and pap.person_id = p_agent_id
           and trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
           and trunc(sysdate) between nvl(pph.date_from, trunc(sysdate)) and nvl(pph.date_to, trunc(sysdate))
           and rownum = 1;
    print_xml_element('PO_BUYER_TEL', l_buyer_phone);
    print_xml_element('PO_BUYER_EMAIL', l_buyer_email);
    return l_buyer_phone;
  exception
    when others then
      return null;
  end;

  function getlocationinfo(p_location_id in number, p_type in varchar2, p_le_id in number default null)
    return number is
    l_address_line1 varchar2(100);
    l_address_line2 varchar2(100);
    l_address_line3 varchar2(100);
    l_territory_short_name varchar2(100);
    l_address_info varchar2(100);
    l_location_name varchar2(100);
    l_phone varchar2(100);
    l_fax varchar2(100);
    l_address_line4 varchar2(100);
    l_town_or_city varchar2(100);
    l_postal_code varchar2(100);
    l_state_or_province varchar2(100);
    l_city_state_zipinfo varchar2(100);
    l_address_style varchar2(100);
    l_address varchar2(5000);
    l_addres2_numornot varchar2(20); -- Sankar Narayanan added 25-MAR-2013
  begin
    select style
    into   l_address_style
    from   hr_locations
    where  location_id = p_location_id;
    po_hr_location.get_alladdress_lines(p_location_id
                                      , l_address_line1
                                      , l_address_line2
                                      , l_address_line3
                                      , l_territory_short_name
                                      , l_address_info
                                      , l_location_name
                                      , l_phone
                                      , l_fax
                                      , l_address_line4
                                      , l_town_or_city
                                      , l_postal_code
                                      , l_state_or_province);

    if (l_town_or_city is null) then
      l_city_state_zipinfo := l_state_or_province || ' ' || l_postal_code;
    else
      l_city_state_zipinfo := l_town_or_city || ',' || l_state_or_province || ' ' || l_postal_code;
    end if;

    /*if p_type = 'SHIP_TO'
    then
       print_xml_element('SHIP_LOC_NAME', l_location_name);
       print_xml_element('SHIP_ADD_1', l_address_line1);
       print_xml_element('SHIP_ADD_2', l_address_line2);
       print_xml_element('SHIP_ADD_3', l_address_line3);
       print_xml_element('SHIP_ADD_4', l_address_line4);
       print_xml_element('SHIP_CITY_ZIP', l_city_state_zipinfo);
       print_xml_element('SHIP_COUNTRY', l_territory_short_name);
    elsif p_type = 'BILL_TO'
    then
       print_xml_element('BILL_LOC_NAME', l_location_name);
       print_xml_element('BILL_ADD_1', l_address_line1);
       print_xml_element('BILL_ADD_2', l_address_line2);
       print_xml_element('BILL_ADD_3', l_address_line3);
       print_xml_element('BILL_ADD_4', l_address_line4);
       print_xml_element('BILL_CITY_ZIP', l_city_state_zipinfo);
       print_xml_element('BILL_COUNTRY', l_territory_short_name);*/
    if p_type = 'LE_ADDRESS' then
      select name
      into   l_location_name
      from   xle_entity_profiles
      where  legal_entity_id = p_le_id;
    end if;

    if l_address_style <> 'DE' then
      select    l_location_name
             || chr(13)
             || decode(nvl(loc.address_line_1, '*'), '*', '', loc.address_line_1 || chr(13))
             || decode(nvl(loc.address_line_2, '*'), '*', '', loc.address_line_2 || ',')
             || decode(nvl(loc.address_line_3, '*'), '*', '', loc.address_line_3 || ', ')
             || decode(nvl(loc.town_or_city, '*'), '*', '', loc.town_or_city || ', ')
             || decode(nvl(loc.region_2, '*'), '*', '', loc.region_2 || ' ')
             || loc.postal_code
             || chr(13)
             || l_territory_short_name
      into   l_address
      from   hr_locations loc
      where  location_id = p_location_id;
    elsif l_address_style = 'DE' then
      -- 1st find if the address_line_2 is a number or a non-number -- Sankar Narayanan added 25-MAR-2013
      select decode(replace(translate(loc.address_line_2, '1234567890', '##########'), '#'), null, 'NUMBER', 'NONNUMER')
      into   l_addres2_numornot -- Sankar Narayanan added 25-MAR-2013
      from   hr_locations loc
      where  location_id = p_location_id;

      -- if address_line_2 is a non-number then print on a separate line
      if (l_addres2_numornot = 'NONNUMER') -- Sankar Narayanan added 25-MAR-2013
                                          then
        select    l_location_name
               || chr(13)
               || decode(nvl(loc.address_line_1, '*'), '*', '', loc.address_line_1 || chr(13))
               || decode(nvl(loc.address_line_2, '*'), '*', '', loc.address_line_2 || chr(13))
               || loc.postal_code
               || ' '
               || decode(nvl(loc.address_line_3, '*'), '*', '', loc.address_line_3 || ' ')
               || decode(nvl(loc.town_or_city, '*'), '*', '', loc.town_or_city || chr(13))
               || decode(loc.region_2, '', l_territory_short_name, loc.region_2 || chr(13) || l_territory_short_name)
        into   l_address
        from   hr_locations loc
        where  location_id = p_location_id;
      else -- if address_line_2 is a number then print on the same line -- Sankar Narayanan added 25-MAR-2013
        -- ' ' indicates same line
        select l_location_name || chr(13)
               || decode(nvl(loc.address_line_1, '*')
                       , '*', ''
                       ,    loc.address_line_1
                         || ' '
                         || decode(nvl(loc.address_line_2, '*'), '*', '', loc.address_line_2 || chr(13))
                         || loc.postal_code
                         || ' '
                         || decode(nvl(loc.address_line_3, '*'), '*', '', loc.address_line_3 || ' ')
                         || decode(nvl(loc.town_or_city, '*'), '*', '', loc.town_or_city || chr(13))
                         || decode(loc.region_2, '', l_territory_short_name, loc.region_2 || chr(13) || l_territory_short_name))
        into   l_address
        from   hr_locations loc
        where  location_id = p_location_id;
      end if;
    end if;

    if p_type = 'SHIP_TO' then
      print_xml_element('SHIP_LOC_NAME', l_address);
    elsif p_type = 'BILL_TO' then
      print_xml_element('BILL_LOC_NAME', l_address);
    elsif p_type = 'LE_ADDRESS' then
      print_xml_element('LE_LOC_NAME', l_address);
    end if;

    --print_xml_element('LE_ADD_1', l_address_line1);
    --print_xml_element('LE_ADD_2', l_address_line2);
    --print_xml_element('LE_ADD_3', l_address_line3);
    -- print_xml_element('LE_ADD_4', l_address_line4);
    -- print_xml_element('LE_CITY_ZIP', l_city_state_zipinfo);
    -- print_xml_element('LE_COUNTRY', l_territory_short_name);
    return p_location_id;
  exception
    when others then
      return null;
  end;

  procedure get_tax(p_invoice_id in number, x_tax_rate out number, x_tax_amount out number) is
    l_tax_rate number;
    l_tax_amount number;
  begin
    select max(tax_rate), sum(tax_amt) -- Sankar Narayanan added 01-MAR-2013
    --max(tax_rate / 100), sum(tax_amt)
    into   x_tax_rate, x_tax_amount
    from   zx_lines
    where  application_id = 200 and trx_id = p_invoice_id;
  exception
    when others then
      x_tax_rate := null;
      x_tax_amount := 0;
  end;

  function get_tax_profile(p_party_id in number, p_party_type in varchar2)
    return varchar2 is
    l_tax_profile zx_party_tax_profile.rep_registration_number%type;
    l_party_id number;
  begin
    if p_party_type = 'THIRD_PARTY' then
      l_party_id := p_party_id;
      select rep_registration_number
      into   l_tax_profile
      from   zx_party_tax_profile
      where  party_id = p_party_id and party_type_code = p_party_type;
    elsif p_party_type = 'FIRST_PARTY' then
      select max(registration_number)
      into   l_tax_profile
      from   xle_registrations_v
      where  legal_entity_id = p_party_id and identifying = 'Y';
    end if;

    return l_tax_profile;
  exception
    when others then
      l_tax_profile := null;
      return l_tax_profile;
  end;

  function get_scar_number(p_invoice_id in number)
    return varchar2 is
    l_scar_number varchar2(400);
    l_rcv_transaction_id number;
    l_trx_date date;
    l_qty number;
    l_no_returns number;
    l_return_trx_id number;
  begin
    l_scar_number := null;

    begin
      select max(rcv_shipment_line_id), max(trunc(accounting_date)), max(abs(quantity_invoiced))
      into   l_rcv_transaction_id, l_trx_date, l_qty
      from   ap_invoice_lines_all
      where  invoice_id = p_invoice_id and line_type_lookup_code = 'ITEM';
    exception
      when others then
        l_scar_number := null;
        return l_scar_number;
    end;

    begin
      select count(*)
      into   l_no_returns
      from   rcv_transactions
      where      shipment_line_id = l_rcv_transaction_id
             and transaction_type = 'RETURN TO VENDOR'
             and invoice_status_code = 'INVOICED'
             and trunc(transaction_date) = l_trx_date
             and quantity = l_qty;

      if l_no_returns = 1 then
        select transaction_id
        into   l_return_trx_id
        from   rcv_transactions
        where  shipment_line_id = l_rcv_transaction_id and transaction_type = 'RETURN TO VENDOR';
      elsif l_no_returns > 1 then
        select max(transaction_id)
        into   l_return_trx_id
        from   rcv_transactions
        where  shipment_line_id = l_rcv_transaction_id and transaction_type = 'RETURN TO VENDOR';
      end if;
    exception
      when others then
        l_no_returns := 0;
        l_scar_number := null;
        return l_scar_number;
    end;

    begin
      select max(comments)
      into   l_scar_number
      from   rcv_transactions
      where  transaction_id = l_return_trx_id and transaction_type = 'RETURN TO VENDOR';
    exception
      when others then
        l_scar_number := null;
        return l_scar_number;
    end;

    return l_scar_number;
  exception
    when others then
      l_scar_number := null;
      return l_scar_number;
  end;

  procedure print_invoice_lines(p_invoice_id in number) is
    cursor c is
      select line_number, round(quantity_invoiced, 2) quantity, unit_price, amount, unit_meas_lookup_code uom, inventory_item_id
      from   ap_invoice_lines_all
      where  invoice_id = p_invoice_id and line_type_lookup_code = 'ITEM';

    l_item mtl_system_items_b.segment1%type;
    l_item_desc mtl_system_items_b.description%type;
    l_taxable varchar2(10);
    l_vendor_product varchar2(100);
  begin
    for i in c loop
      if i.inventory_item_id is not null then
        select segment1, description
        into   l_item, l_item_desc
        from   mtl_system_items_b
        where  inventory_item_id = i.inventory_item_id
               and organization_id = (select inventory_organization_id
                                      from   financials_system_parameters);
      end if;

      begin
        select 'Yes'
        into   l_taxable
        from   ap_invoice_lines_all a
        where      a.invoice_id = p_invoice_id
               and line_number = i.line_number
               and exists
                     (select 1
                      from   zx_lines b
                      where  application_id = 200 and a.invoice_id = b.trx_id and a.line_number = b.trx_line_id);
      exception
        when others then
          l_taxable := 'No';
      end;

      debug(fnd_file.output, '<G_LINES>');
      print_xml_element('LINE_NUMBER', i.line_number);
      print_xml_element('QUANTITY', i.quantity);
      print_xml_element('UNIT_PRICE', i.unit_price);
      print_xml_element('EXTENDED_PRICE', i.amount);
      print_xml_element('UOM', i.uom);
      print_xml_element('ITEM', l_item);
      print_xml_element('ITEM_DESC', l_item_desc);
      print_xml_element('VENDOR_PRODUCT_NUM', l_vendor_product);
      print_xml_element('TAXABLE', l_taxable);
      debug(fnd_file.output, '</G_LINES>');
    end loop;
  end;

  function get_inv_num(p_po_header_id in number, p_rcv_trx_id in number)
    return varchar2 is
    l_ap_invs varchar2(32000);
    crlf constant varchar2(1) := '
';

    cursor c is
      select invoice_num
      from   ap_invoices a
      where  invoice_type_lookup_code = 'STANDARD'
             and exists
                   (select 1
                    from   ap_invoice_lines_all b
                    where      po_header_id = p_po_header_id
                           and case
                                 when rcv_transaction_id is not null then rcv_transaction_id
                                 else -1
                               end = p_rcv_trx_id
                           and line_type_lookup_code = 'ITEM'
                           and a.invoice_id = b.invoice_id);

    type t_array_char is table of varchar2(80)
                           index by binary_integer;

    l_conc_seg_delimiter varchar2(80);
    l_concat_segment varchar2(4000);
    l_array t_array_char;
  begin
    open c;
    fetch c
    bulk collect into l_array;
    close c;

    for i in 1 .. l_array.count loop
      l_concat_segment := l_concat_segment || l_array(i);

      if i < l_array.count then
        l_concat_segment := l_concat_segment || ' , ';
      end if;
    end loop;

    return l_concat_segment;
  exception
    when others then
      return null;
  end;

  procedure get_po_info(p_invoice_id in number) is
    l_match_type varchar2(30);
    l_po_release_id number;
    l_po_num varchar2(30);
    l_po_header_id number;
    l_release_num number;
    l_approved_date date;
    l_rev_num number;
    l_rev_date date;
    l_agent_id number;
    l_promise_date date;
    l_buyer varchar2(400);
    l_telephone varchar2(400);
    l_po_dist_id number;
    l_shipment_id number;
    l_email varchar2(100);
    l_inv_num varchar2(4000);
    l_supp_contact_id number;
    l_supp_contact_name varchar2(400);
    l_supp_contact_phone varchar2(400);
    l_revised_by varchar2(400);
    l_bill_to number;
    l_ship_to number;
    l_location number;
    l_rcv_transaction_id number;
  begin
    begin
      select max(match_type)
      into   l_match_type
      from   ap_invoice_lines_all
      where  invoice_id = p_invoice_id and line_type_lookup_code = 'ITEM' and match_type <> 'NOT_MATCHED';
    exception
      when others then
        l_match_type := 'NOT_MATCHED';
    end;

    if l_match_type <> 'NOT_MATCHED' then
      begin
        select max(po_release_id), max(po_distribution_id), max(po_line_location_id)
        into   l_po_release_id, l_po_dist_id, l_shipment_id
        from   ap_invoice_lines_all
        where  invoice_id = p_invoice_id and line_type_lookup_code = 'ITEM';
      exception
        when others then
          l_po_release_id := null;
      end;

      if l_po_release_id is not null then
        select a.segment1
             , b.po_header_id
             , b.release_num
             , trunc(b.approved_date)
             , b.revision_num
             , trunc(b.revised_date)
             , b.agent_id
             , a.vendor_contact_id
        into   l_po_num, l_po_header_id, l_release_num, l_approved_date, l_rev_num, l_rev_date, l_agent_id, l_supp_contact_id
        from   po_headers_all a, po_releases_all b
        where  po_release_id = l_po_release_id and a.po_header_id = b.po_header_id;
        select max(promised_date)
        into   l_promise_date
        from   po_line_locations_all
        where  po_header_id = l_po_header_id and po_release_id = l_po_release_id;
        select   full_name
        into     l_revised_by
        from     per_all_people_f
        where    person_id = (select employee_id
                              from   fnd_user
                              where  user_id = (select agent_id
                                                from   po_headers_archive_all
                                                where  po_header_id = l_po_header_id and revision_num = l_rev_num))
        group by full_name;
        select   full_name, office_number, email_address
        into     l_buyer, l_telephone, l_email
        from     per_all_people_f
        where    person_id = l_agent_id and trunc(sysdate) between effective_start_date and effective_end_date
        group by full_name, office_number, email_address;
      else
        begin
          select max(po_header_id), max(po_line_location_id), max(rcv_transaction_id)
          into   l_po_header_id, l_shipment_id, l_rcv_transaction_id
          from   ap_invoice_lines_all
          where  invoice_id = p_invoice_id and line_type_lookup_code = 'ITEM';
        exception
          when others then
            l_po_header_id := null;
        end;

        if l_po_header_id is not null then
          select segment1
               , trunc(approved_date)
               , revision_num
               , trunc(revised_date)
               , vendor_contact_id
               , agent_id
               , bill_to_location_id
               , ship_to_location_id
          into   l_po_num, l_approved_date, l_rev_num, l_rev_date, l_supp_contact_id, l_agent_id, l_bill_to, l_ship_to
          from   po_headers_all
          where  po_header_id = l_po_header_id;

          begin
            select   full_name
            into     l_revised_by
            from     per_all_people_f
            where    person_id = (select agent_id
                                  from   po_headers_archive_all
                                  where  po_header_id = l_po_header_id and revision_num = l_rev_num)
            group by full_name;
          exception
            when others then
              l_revised_by := null;
          end;

          begin
            select   full_name, office_number, email_address
            into     l_buyer, l_telephone, l_email
            from     per_all_people_f
            where    person_id = l_agent_id and trunc(sysdate) between effective_start_date and effective_end_date
            group by full_name, office_number, email_address;
          exception
            when others then
              l_buyer := null;
              l_telephone := null;
              l_email := null;
          end;

          begin
            select max(promised_date)
            into   l_promise_date
            from   po_line_locations_all
            where  line_location_id = l_shipment_id;
          exception
            when others then
              l_promise_date := null;
          end;
        end if;
      end if;
    end if;

    if l_supp_contact_id is not null then
      begin
        select last_name || ',' || first_name, area_code || ' ' || phone
        into   l_supp_contact_name, l_supp_contact_phone
        from   po_vendor_contacts
        where  vendor_contact_id = l_supp_contact_id;
      exception
        when others then
          l_supp_contact_name := null;
          l_supp_contact_phone := null;
      end;
    else
      begin
        select a.area_code || ' ' || a.phone
        into   l_supp_contact_phone
        from   po_vendor_sites_all a, ap_invoices b
        where  b.invoice_id = p_invoice_id and a.vendor_site_id = b.vendor_site_id;
      exception
        when others then
          l_supp_contact_phone := null;
      end;
    end if;

    begin
      l_rcv_transaction_id := nvl(l_rcv_transaction_id, -1);
      l_inv_num := get_inv_num(l_po_header_id, l_rcv_transaction_id);
    exception
      when others then
        l_inv_num := null;
    end;

    l_location := getlocationinfo(l_bill_to, 'BILL_TO');
    l_location := null;
    l_location := getlocationinfo(l_ship_to, 'SHIP_TO');
    print_xml_element('PO_NUMBER', l_po_num);
    print_xml_element('PO_DATE', l_approved_date);
    print_xml_element('PO_REV_NUM', l_rev_num);
    print_xml_element('PO_REV_DATE', l_rev_date);
    print_xml_element('PO_REVISED_BY', l_revised_by);
    print_xml_element('PO_BUYER', l_buyer);
    l_telephone := getphone(l_agent_id);
    print_xml_element('PO_PROMISE_DATE', l_promise_date);
    print_xml_element('ORIGINAL_INV_NUM', l_inv_num);
    print_xml_element('SUPP_CONTACT_NAME', l_supp_contact_name);
    print_xml_element('SUPP_CONTACT_PHONE', l_supp_contact_phone);
  exception
    when others then
      debug(fnd_file.log, sqlerrm);
  end;

  function get_language_predicate
    return varchar2 is
    session_language fnd_languages.nls_language%type;
    base_language fnd_languages.nls_language%type;
    g_language_where varchar2(4000);
  begin
    session_language := '';
    base_language := '';
    select substr(userenv('LANGUAGE'), 1, instr(userenv('LANGUAGE'), '_') - 1)
    into   session_language
    from   dual;
    select nls_language
    into   base_language
    from   fnd_languages
    where  installed_flag = 'B';

    if g_language is not null then
      g_language_where :=    ' and nvl(zps.language,'
                          || ''''
                          || g_language
                          || ''')= nvl('
                          || ''''
                          || g_language
                          || ''''
                          || ','
                          || ''''
                          || session_language
                          || ''''
                          || ')';
    end if;

    g_language_where :=    ' and nvl(zps.language,'
                        || ''''
                        || base_language
                        || ''')= nvl('
                        || ''''
                        || g_language
                        || ''''
                        || ','
                        || ''''
                        || session_language
                        || ''''
                        || ')';
    return (g_language_where);
  exception
    when others then
      return null;
  end;

  -----------------------------------------------------------------------------
  -- Start of comments                                                       --
  -- Hierarchy of search                                                     --
  -- first check is whether the Debit is matched to PO (original AP Invoice  --
  -- If it is matched then inventory org is fetched using PO distribution    --
  -- If the org is 116 or 404 then the LE is Always Jarit GmbH               --
  -- if th org is 117 then it is J Jamner                                    --
  -- If the otherwise it the LE associated with the Org is fetched           --
  -- IF the OU is Germany the LE is always the one associated with Invoice   --
  -----------------------------------------------------------------------------
  function search_le(p_invoice_id in number, p_legal_entity_id in number, p_location_id in number)
    return number is
    l_legal_entity_id number;
    l_po_distribution_id number;
    l_organization_id number;
    l_match_type varchar2(30);
    l_bsv varchar2(10);
    l_organization_code varchar2(30);
    l_location_code varchar2(100);
  begin
    l_legal_entity_id := p_legal_entity_id;

    if g_operating_unit = 84 then
      -- case for Germany
      fnd_file.put_line(fnd_file.log, 'p_legal_entity_id:' || p_legal_entity_id);
      fnd_file.put_line(fnd_file.log, 'l_legal_entity_id:' || l_legal_entity_id);
      return l_legal_entity_id;
    end if;

    begin
      select max(match_type)
      into   l_match_type
      from   ap_invoice_lines_all
      where  invoice_id = p_invoice_id and line_type_lookup_code = 'ITEM' and match_type <> 'NOT_MATCHED';
    exception
      when others then
        l_match_type := 'NOT_MATCHED';
    end;

    if l_match_type = 'NOT_MATCHED' then
      begin
        select location_code
        into   l_location_code
        from   hr_locations
        where  location_id = p_location_id;
      exception
        when others then
          l_location_code := null;
      end;

      if l_location_code is not null then
        if (l_location_code like '%116%' or l_location_code like '%404%') then
          l_legal_entity_id := 26294;
        elsif (l_location_code like '%117%') then
          -- this is J Jamner Case
          l_legal_entity_id := 24301;
        end if;

        fnd_file.put_line(fnd_file.log, 'p_legal_entity_id:' || p_legal_entity_id);
        fnd_file.put_line(fnd_file.log, 'l_legal_entity_id:' || l_legal_entity_id);
        return l_legal_entity_id;
      end if;

      begin
        select distinct b.segment1
        into   l_bsv
        from   ap_invoice_distributions_all a, gl_code_combinations_kfv b
        where      invoice_id = p_invoice_id
               and a.dist_code_combination_id = b.code_combination_id
               and line_type_lookup_code in ('ACCRUAL', 'ITEM', 'TRV');
      exception
        when too_many_rows then
          null;
          l_bsv := null;
        when others then
          null;
          l_bsv := null;
      end;

      if l_bsv is not null then
        begin
          select distinct legal_entity_id
          into   l_legal_entity_id
          from   (select gllegalentitiesbsvseo.legal_entity_id
                       , gllegalentitiesbsvseo.flex_value_set_id
                       , gllegalentitiesbsvseo.flex_segment_value company
                       , gllegalentitiesbsvseo.start_date
                       , gllegalentitiesbsvseo.end_date
                       , nvl(xle.name
                           , decode(f.flex_value_set_id
                                  , null, gl_ledgers_pkg.
                                          get_bsv_desc('LE'
                                                     , gllegalentitiesbsvseo.flex_value_set_id
                                                     , gllegalentitiesbsvseo.flex_segment_value)
                                  , xle.name, f.description))
                           description
                       , decode((select completion_status_code
                                 from   gl_ledger_configurations
                                 where  configuration_id =
                                          (select configuration_id
                                           from   gl_ledger_config_details
                                           where  object_id = gllegalentitiesbsvseo.legal_entity_id
                                                  and object_type_code = 'LEGAL_ENTITY'))
                              , 'CONFIRMED', 'N'
                              , 'Y')
                           remove_enabled
                  from   gl_legal_entities_bsvs gllegalentitiesbsvseo, fnd_flex_values_vl f, xle_entity_profiles xle
                  where      f.flex_value_set_id(+) = gllegalentitiesbsvseo.flex_value_set_id
                         and f.flex_value(+) = gllegalentitiesbsvseo.flex_segment_value
                         and gllegalentitiesbsvseo.legal_entity_id = xle.legal_entity_id) q
          where  company = l_bsv
                 and flex_value_set_id = (select flex_value_set_id
                                          from   fnd_flex_value_sets
                                          where  flex_value_set_name = 'INTG_COMPANY');
        exception
          when others then
            null;
        end;

        fnd_file.put_line(fnd_file.log, 'p_legal_entity_id:' || p_legal_entity_id);
        fnd_file.put_line(fnd_file.log, 'l_legal_entity_id:' || l_legal_entity_id);
        return l_legal_entity_id;
      else
        return l_legal_entity_id;
      end if;
    else
      begin
        select max(po_distribution_id)
        into   l_po_distribution_id
        from   ap_invoice_lines_all
        where  invoice_id = p_invoice_id and po_distribution_id is not null;
      exception
        when others then
          l_po_distribution_id := null;
          return l_legal_entity_id;
      end;

      select destination_organization_id, organization_code
      into   l_organization_id, l_organization_code
      from   po_distributions_all a, mtl_parameters b
      where  po_distribution_id = l_po_distribution_id
      and a.destination_organization_Id=b.organization_id;

      if l_organization_code in ('116', '404') then
        l_legal_entity_id := 26294;
      else
        select org_information2
        into   l_legal_entity_id
        from   hr_organization_information
        where  org_information_context = 'Accounting Information' and organization_id = l_organization_id;
      end if;
    end if;

    fnd_file.put_line(fnd_file.log, 'p_legal_entity_id:' || p_legal_entity_id);
    fnd_file.put_line(fnd_file.log, 'l_legal_entity_id:' || l_legal_entity_id);
    return l_legal_entity_id;
  exception
    when others then
    fnd_file.put_line(fnd_file.log, 'l_legal_entity_id:' || sqlerrm);
      return l_legal_entity_id;
  end;

  function which_address(p_operating_unit in number, p_le_id in number, p_inventory_org_id in number, p_location_id in number)
    return varchar2 is
    l_address varchar2(1000);
    l_org_code varchar2(30);
    l_location_code varchar2(100);
  begin
    l_address := 'INTG_AP_DEBIT_' || p_le_id || '_ADDRESS';

    begin
      select organization_code
      into   l_org_code
      from   mtl_parameters
      where  organization_id = p_inventory_org_id;
    exception
      when others then
        l_org_code := '99999';
    end;

    begin
      select location_code
      into   l_location_code
      from   hr_locations
      where  location_id = p_location_id;
    exception
      when others then
        l_location_code := 'No Location';
    end;

    dbms_output.put_line(l_org_code);
    dbms_output.put_line(l_location_code);

    --if p_operating_unit = 82 then
    IF p_operating_unit = xxintg_get_ou_us_id THEN
      /*if (l_org_code ='404' OR l_location_code like '%404%') then
        -- this Jartit GmbH Case
        l_address := 'INTG_AP_DEBIT_26294_ADDRESS';
        -- thisJ Jamner DE Case
      elsif (l_org_code='116' OR l_location_code like '%116%') then
      l_address:='INTG_AP_DEBIT_26294_ADDRESS_J';
       elsif (l_org_code = '117' OR l_location_code like '%117%') then
        -- this is J Jamner US Case
        l_address := 'INTG_AP_DEBIT_24301_ADDRESS';
      else
        l_address := 'INTG_AP_DEBIT_' || p_le_id || '_ADDRESS';
      end if;*/
      l_address := 'INTG_AP_DEBIT_24298_ADDRESS';
      
    else
      -- Miltex, Integra German Holdings
      l_address := 'INTG_AP_DEBIT_' || p_le_id || '_ADDRESS';
    end if;

    return l_address;
  exception
    when others then
      return l_address;
  end;

  function which_one(p_operating_unit in number, p_le_id in number, p_inventory_org_id in number, p_location_id in number,p_type in varchar2)
    return varchar2 is
    l_footer varchar2(1000);
    l_org_code varchar2(30);
    l_location_code varchar2(100);
  begin
    l_footer := 'INTG_AP_DEBIT_' || p_le_id || '_'||p_type;

    begin
      select organization_code
      into   l_org_code
      from   mtl_parameters
      where  organization_id = p_inventory_org_id;
    exception
      when others then
        l_org_code := '99999';
    end;

    begin
      select location_code
      into   l_location_code
      from   hr_locations
      where  location_id = p_location_id;
    exception
      when others then
        l_location_code := 'No Location';
    end;

    dbms_output.put_line(l_org_code);
    dbms_output.put_line(l_location_code);

    --if p_operating_unit = 82 then
   IF p_operating_unit = xxintg_get_ou_us_id THEN
      
      l_footer:='INTG_AP_DEBIT_24298_ADDRESS';
    else
      -- Miltex, Integra German Holdings
      l_footer := 'INTG_AP_DEBIT_' || p_le_id || '_'||p_type;
    end if;

    return l_footer;
  exception
    when others then
      return l_footer;
  end;

  procedure print_report(xerrbuf   out varchar2
                       , xretcode   out varchar2
                       , p_operating_unit in number
                       , p_vendor_id in number
                       , p_invoice_type in varchar2
                       , p_invoice_id in number
                       , p_invoice_date_from in varchar2
                       , p_invoice_date_to in varchar2
                       , p_language in varchar2) is
    c integer;
    t integer;
    rows_updated number;
    l_invoice_num varchar2(100);
    l_vendor_name varchar2(400);
    l_invoice_id number;
    l_invoice_curr varchar2(100);
    l_invoice_amt number;
    l_term_id number;
    l_term_name varchar2(400);
    g_supp_site_lang varchar2(100);
    l_print_labels number;
    x_tax_rate number;
    x_tax_amt number;
    l_party_id number;
    l_legal_entity_id number;
    l_supp_tax_number varchar2(100);
    l_le_tax_number varchar2(100);
    l_line_amt number;
    l_vendor_num varchar2(100);
    l_vendor_site_id number;
    l_address varchar2(100);
    l_le_location_id number;
    l_loc_id number;
    l_invoice_date date;
    l_invoice_date_chr varchar2(100);
    l_scar_number varchar2(400);
    l_ship_to_location_id number;
    l_ship_to_organization_id number;
    l_language varchar2(20);
    l_le_address varchar2(4000);
    session_language varchar2(30);
    l_address_msg varchar2(4000);
    l_footer varchar2(4000);
    l_footer_msg varchar(4000);
    l_le_tax_number_msg varchar2(400);
  begin
    g_language := p_language;
    g_invoice_type := p_invoice_type;
    g_vendor_id := p_vendor_id;
    g_invoice_id := p_invoice_id;
    --g_start_date := fnd_date.canonical_to_date('2012/01/30');
    g_start_date := fnd_date.canonical_to_date(p_invoice_date_from);
    g_end_date := fnd_date.canonical_to_date(p_invoice_date_to);
    -- g_end_date := fnd_date.canonical_to_date('2012/10/17');
    g_operating_unit := p_operating_unit;
    main_query := replace(main_query, '$C_LANGUAGE_WHERE$', 'and 1 = 1');

    if g_vendor_id is not null then
      main_query := replace(main_query, '$C_VENDOR_ID_PREDICATE$', 'and inv.vendor_id = ' || g_vendor_id);
    else
      main_query := replace(main_query, '$C_VENDOR_ID_PREDICATE$', 'and 1 = 1');
    end if;

    if g_invoice_type is not null then
      main_query := replace(main_query, '$C_INVOICE_TYPE_PREDICATE$', 'and l.lookup_code = ''' || g_invoice_type || '''');
    else
      main_query := replace(main_query, '$C_INVOICE_TYPE_PREDICATE$', 'and 1 = 1');
    end if;

    if g_invoice_id is not null then
      main_query := replace(main_query, '$C_INVOICE_ID_PREDICATE$', 'and inv.invoice_id=' || g_invoice_id);
    else
      main_query := replace(main_query, '$C_INVOICE_ID_PREDICATE$', 'and 1 = 1');
    end if;

    if g_start_date is not null then
      main_query := replace(main_query, '$C_START_DATE_PREDICATE$', 'and trunc(inv.invoice_date) >=''' || g_start_date || '''');
    else
      main_query := replace(main_query, '$C_START_DATE_PREDICATE$', 'and 1 = 1');
    end if;

    if g_end_date is not null then
      main_query := replace(main_query, '$C_END_DATE_PREDICATE$', 'and trunc(inv.invoice_date) <=''' || g_end_date || '''');
    else
      main_query := replace(main_query, '$C_END_DATE_PREDICATE$', 'and 1 = 1');
    end if;

    --dbms_output.put_line(main_query);
    mo_global.set_policy_context('S', p_operating_unit);
    c := dbms_sql.open_cursor;
    dbms_sql.parse(c, main_query, dbms_sql.native);
    dbms_sql.define_column(c, 1, l_vendor_name, 400);
    dbms_sql.define_column(c, 7, l_invoice_id);
    dbms_sql.define_column(c, 8, l_invoice_num, 100);
    dbms_sql.define_column(c, 9, l_invoice_curr, 100);
    dbms_sql.define_column(c, 10, l_invoice_amt);
    dbms_sql.define_column(c, 13, l_invoice_date);
    dbms_sql.define_column(c, 16, l_term_id);
    dbms_sql.define_column(c, 17, g_supp_site_lang, 400);
    dbms_sql.define_column(c, 18, l_party_id);
    dbms_sql.define_column(c, 19, l_legal_entity_id);
    dbms_sql.define_column(c, 20, l_vendor_num, 400);
    dbms_sql.define_column(c, 21, l_vendor_site_id);
    t := dbms_sql.execute(c);

    --fnd_file.put_line(fnd_file.output, '<?xml version="1.0" encoding="UTF-8"?>');
    if g_supp_site_lang is not null then
      l_language := g_supp_site_lang;
    elsif g_supp_site_lang is null and g_language is not null then
      l_language := g_language;
    elsif g_supp_site_lang is null and g_language is null then
      select substr(userenv('LANGUAGE'), 1, instr(userenv('LANGUAGE'), '_') - 1)
      into   session_language
      from   dual;

      begin
        select language_code
        into   l_language
        from   fnd_languages
        where  nls_language = session_language;
      exception
        when others then
          select language_code
          into   l_language
          from   fnd_languages
          where  installed_flag = 'B';
      end;
    end if;

    debug(fnd_file.output, '<?xml version="1.0" encoding="UTF-8"?>');
    --fnd_file.put_line(fnd_file.output, '<REPORT>');
    debug(fnd_file.output, '<REPORT>');

    loop
      if dbms_sql.fetch_rows(c) > 0 then
        debug(fnd_file.output, '<G_INVOICES>');
        dbms_sql.column_value(c, 1, l_vendor_name);
        dbms_sql.column_value(c, 7, l_invoice_id);
        dbms_sql.column_value(c, 8, l_invoice_num);
        dbms_sql.column_value(c, 9, l_invoice_curr);
        dbms_sql.column_value(c, 10, l_invoice_amt);
        dbms_sql.column_value(c, 13, l_invoice_date);
        dbms_sql.column_value(c, 16, l_term_id);
        dbms_sql.column_value(c, 17, g_supp_site_lang);
        dbms_sql.column_value(c, 18, l_party_id);
        dbms_sql.column_value(c, 19, l_legal_entity_id);
        dbms_sql.column_value(c, 20, l_vendor_num);
        dbms_sql.column_value(c, 21, l_vendor_site_id);

        begin
          select name
          into   l_term_name
          from   ap_terms
          where  term_id = l_term_id;
        exception
          when others then
            l_term_name := null;
        end;

        begin
          select sum(amount)
          into   l_line_amt
          from   ap_invoice_lines_all
          where  invoice_id = l_invoice_id and line_type_lookup_code = 'ITEM';
        exception
          when others then
            l_line_amt := 0;
        end;

        begin
          select max(ship_to_location_id)
          into   l_ship_to_location_id
          from   ap_invoice_lines_all
          where  invoice_id = l_invoice_id and line_type_lookup_code = 'ITEM';
        exception
          when others then
            l_ship_to_location_id := null;
        end;

        begin
          select max(destination_organization_id)
          into   l_ship_to_organization_id
          from   ap_invoice_lines_all a, po_distributions_all b
          where  invoice_id = l_invoice_id and a.po_distribution_id = b.po_distribution_id and line_type_lookup_code = 'ITEM';
        exception
          when others then
            l_ship_to_organization_id := null;
        end;

        if g_operating_unit <> 84 then
          l_legal_entity_id := search_le(l_invoice_id, l_legal_entity_id, l_ship_to_location_id);
        end if;

        fnd_file.put_line(fnd_file.log, 'Legal Entity ID: ' || l_legal_entity_id);
        select location_id
        into   l_le_location_id
        from   xle_registrations_v
        where  legal_entity_id = l_legal_entity_id and identifying = 'Y';
        l_invoice_date_chr := fnd_date.date_to_displaydt(l_invoice_date);
        print_xml_element('INVOICE_NUM', l_invoice_num);
        print_xml_element('TERMS', l_term_name);
        print_xml_element('VENDOR_NAME', l_vendor_name);
        print_xml_element('INVOICE_CURRENCY', l_invoice_curr);
        print_xml_element('INVOICE_AMOUNT', l_line_amt);
        print_xml_element('INVOICE_TOT_AMOUNT', l_invoice_amt);
        print_xml_element('VENDOR_NUM', l_vendor_num);
        print_xml_element('INVOICE_DATE', l_invoice_date);
        l_address := getvendoraddressline1(l_vendor_site_id);
        l_address_msg := which_address(g_operating_unit, l_legal_entity_id, l_ship_to_organization_id, l_ship_to_location_id);
        fnd_file.put_line(fnd_file.log, l_address_msg);
        l_le_address := get_msg_value(l_address_msg, l_language);
        fnd_file.put_line(fnd_file.log, l_le_address);
        print_xml_element('LE_LOC_NAME', l_le_address);
        --l_loc_id := getlocationinfo(l_le_location_id, 'LE_ADDRESS', l_legal_entity_id);
        --dbms_output.put_line('---<<Invoice Num :' || l_invoice_num || '>>-----');
        get_po_info(l_invoice_id);
        print_invoice_lines(l_invoice_id);

        --dbms_output.put_line('-------------------------------------');
        --dbms_output.put_line('---<<Vendor Name :' || l_vendor_name || '>>-----');
        begin
          get_tax(l_invoice_id, x_tax_rate, x_tax_amt);

          if x_tax_amt is null then
            x_tax_amt := 0;
            x_tax_rate := 0;
          end if;
        exception
          when others then
            x_tax_rate := 0;
            x_tax_amt := 0;
        end;

        print_xml_element('TAX_RATE', x_tax_rate);
        print_xml_element('TAX_AMOUNT', x_tax_amt);
        l_supp_tax_number := get_tax_profile(l_party_id, 'THIRD_PARTY');
        --l_le_tax_number := get_tax_profile(l_legal_entity_id, 'FIRST_PARTY');
        fnd_file.put_line(fnd_file.log, 'l_language: ' || l_language);
        fnd_file.put_line(fnd_file.log, 'INTG_AP_DEBIT_' || l_legal_entity_id || '_VAT_ID');
        fnd_file.put_line(fnd_file.log, 'INTG_AP_DEBIT_' || l_legal_entity_id || '_FOOTER');

        --if l_language = 'D' then
          l_le_tax_number := get_msg_value('INTG_AP_DEBIT_' || l_legal_entity_id || '_VAT_ID', l_language);
          l_footer:=which_one(g_operating_unit, l_legal_entity_id, l_ship_to_organization_id, l_ship_to_location_id,'FOOTER');
          l_footer_msg := get_msg_value(l_footer, l_language);
          fnd_file.put_line(fnd_file.log, l_footer);
          L_LE_TAX_NUMBER_MSG:=WHICH_ONE(G_OPERATING_UNIT, L_LEGAL_ENTITY_ID, L_SHIP_TO_ORGANIZATION_ID, L_SHIP_TO_LOCATION_ID,'VAT_ID');
          fnd_file.put_line(fnd_file.log,'l_le_tax_number_msg : '||l_le_tax_number_msg);
          L_LE_TAX_NUMBER := GET_MSG_VALUE(L_LE_TAX_NUMBER_MSG, L_LANGUAGE);
          L_LE_TAX_NUMBER := GET_MSG_VALUE('INTG_AP_DEBIT_26294_VAT_ID_J',L_LANGUAGE);
          fnd_file.put_line(fnd_file.log, l_le_tax_number);
          PRINT_XML_ELEMENT('VENDOR_TAX_REG_NUMBER', L_SUPP_TAX_NUMBER);
          PRINT_XML_ELEMENT('LE_TAX_REG_NUMBER', L_LE_TAX_NUMBER);
          --print_xml_element('LE_TAX_REG_NUMBER', null);
          print_xml_element('INTG_AP_DEBIT_MEMO_LEGAL_FOOT', l_footer_msg);
       -- end if;

        begin
          l_scar_number := null;
          l_scar_number := get_scar_number(l_invoice_id);
        exception
          when others then
            l_scar_number := null;
        end;

        print_xml_element('SCAR_NUMBER', l_scar_number);
        l_print_labels := print_labels;
        debug(fnd_file.output, '</G_INVOICES>');
      else
        exit;
      end if;
    end loop;

    debug(fnd_file.output, '</REPORT>');
    dbms_sql.close_cursor(c);
  exception
    when others then
      fnd_file.put_line(fnd_file.log, '---<<exception :' || sqlerrm || '>>-----');

      if dbms_sql.is_open(c) then
        dbms_sql.close_cursor(c);
      end if;
  end;
end; 
/
