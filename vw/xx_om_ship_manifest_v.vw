DROP VIEW APPS.XX_OM_SHIP_MANIFEST_V;

/* Formatted on 6/6/2016 4:58:18 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OM_SHIP_MANIFEST_V
(
   ORG_ID,
   HEADER_ID,
   LINE_ID,
   ORG_CODE,
   ORG_NAME,
   ORDER_NUMBER,
   DELIVERY_ID,
   DELIVERY_NUMBER,
   DELIVERY_DETAIL_ID,
   ORDER_TYPE,
   ORDERED_DATE,
   REQUEST_DATE,
   SCHEDULE_SHIP_DATE,
   PROMISE_DATE,
   ORDER_SOURCE_NAME,
   SHIP_TO_ORG_ID,
   DELIVER_TO_ORG_ID,
   INVOICE_TO_ORG_ID,
   SHIPPING_METHOD,
   INCO_TERM,
   FREIGHT_TERMS_CODE,
   CUST_PO_NUMBER,
   SHIPMENT_PRIORITY,
   PAYMENT_TERM,
   PRICE_LIST_NAME,
   GPO_INFO,
   END_CUSTOMER_PO,
   FREIGHT_ACCT_NUM,
   CHARGE_DROP_SHIP,
   FREIGHT_INSURANCE,
   SHIPPER_PROACTIVE_FLAG,
   CHARGE_SHIP_METHOD,
   SHIPPING_INSTRUCTIONS,
   ORDER_LINE_TYPE,
   SHIP_ORG_ID,
   WAREHOUSE,
   SHIP_ACCOUNT,
   SHIP_ACCOUNT_NAME,
   SHIP_SITE_ID,
   SHIP_SITE_NAME,
   SHIP_ADDRESS1,
   SHIP_ADDRESS2,
   SHIP_ADDRESS3,
   SHIP_ADDRESS4,
   SHIP_CITY,
   SHIP_STATE,
   SHIP_COUNTRY,
   SHIP_POSTAL_CODE,
   FREIGHT_MARKUP,
   SHIP_PHONE,
   SHIP_EMAIL,
   SHIP_CONTACT,
   ORDER_ATTENTION,
   SHIP_CURRENCY,
   SHIP_CURRENCY_RATE,
   CONV_TO_USD,
   DEL_ACCOUNT,
   DEL_ACCOUNT_NAME,
   DEL_SITE_ID,
   DEL_SITE_NAME,
   DEL_ADDRESS1,
   DEL_ADDRESS2,
   DEL_ADDRESS3,
   DEL_ADDRESS4,
   DEL_CITY,
   DEL_STATE,
   DEL_COUNTRY,
   DEL_POSTAL_CODE,
   DEL_PHONE,
   DEL_EMAIL,
   DEL_CONTACT,
   DEL_CURRENCY,
   DEL_CURRENCY_RATE,
   BILL_ACCOUNT,
   BILL_ACCOUNT_NAME,
   BILL_SITE_ID,
   BILL_SITE_NAME,
   BILL_ADDRESS1,
   BILL_ADDRESS2,
   BILL_ADDRESS3,
   BILL_ADDRESS4,
   BILL_CITY,
   BILL_STATE,
   BILL_COUNTRY,
   BILL_POSTAL_CODE,
   BILL_PHONE,
   BILL_EMAIL,
   BILL_CONTACT,
   BILL_CURRENCY,
   BILL_CURRENCY_RATE,
   LICENSE_PLATE_NUMBER,
   ORGANIZATION_ID,
   INVENTORY_ITEM_ID,
   SHIPPED_QUANTITY,
   UOM,
   SELLING_PRICE,
   CURRENCY_CODE,
   LOT_NUMBER,
   SHIP_CREATED_BY,
   SHIP_CREATED_DATE,
   ITEM_NUMBER,
   ITEM_DESC,
   ITEM_INV_CATEGORY_SET,
   ITEM_HAZARD_CLASS,
   ITEM_UN_NUMBER,
   ITEM_ATTR_CONTEXT,
   ITEM_ATTRIBUTE1,
   ITEM_ATTRIBUTE2,
   ITEM_ATTRIBUTE3,
   ITEM_ATTRIBUTE4,
   ITEM_ATTRIBUTE5,
   ITEM_ATTRIBUTE6,
   ITEM_ATTRIBUTE7,
   ITEM_ATTRIBUTE8,
   ITEM_ATTRIBUTE9,
   ITEM_ATTRIBUTE10,
   ITEM_ATTRIBUTE11,
   ITEM_ATTRIBUTE12,
   ITEM_ATTRIBUTE13,
   ITEM_ATTRIBUTE14,
   ITEM_ATTRIBUTE15,
   ITEM_ATTRIBUTE16,
   ITEM_ATTRIBUTE17,
   ITEM_ATTRIBUTE18,
   ITEM_ATTRIBUTE19,
   ITEM_ATTRIBUTE20,
   ITEM_ATTRIBUTE21,
   ITEM_ATTRIBUTE22,
   ITEM_ATTRIBUTE23,
   ITEM_ATTRIBUTE24,
   ITEM_ATTRIBUTE25,
   ITEM_ATTRIBUTE26,
   ITEM_ATTRIBUTE27,
   ITEM_ATTRIBUTE28,
   ITEM_ATTRIBUTE29,
   ITEM_ATTRIBUTE30
)
AS
     SELECT ooh.org_id,
            ooh.header_id,
            ool.line_id,
            (SELECT short_code
               FROM hr_operating_units
              WHERE organization_id = ooh.org_id)
               org_code,
            (SELECT name
               FROM hr_operating_units
              WHERE organization_id = ooh.org_id)
               org_name,
            ooh.order_number,
            wnd.delivery_id,
            wnd.name delivery_number,
            wdd.delivery_detail_id                        --,ooh.order_type_id
                                  ,
            (SELECT name
               FROM oe_transaction_types_tl
              WHERE     transaction_type_id = ooh.order_type_id
                    AND language = USERENV ('LANG'))
               order_type,
            ooh.ordered_date,
            NVL (ool.request_date, ooh.request_date) request_date,
            ool.schedule_ship_date,
            ool.promise_date                            --,ooh.order_source_id
                            ,
            (SELECT name
               FROM oe_order_sources
              WHERE order_source_id = ooh.order_source_id)
               order_source_name,
            NVL (ool.ship_to_org_id, ooh.ship_to_org_id) ship_to_org_id,
            NVL (ool.deliver_to_org_id, ooh.deliver_to_org_id)
               deliver_to_org_id,
            NVL (ool.invoice_to_org_id, ooh.invoice_to_org_id) invoice_to_org_id --,NVL(ool.ship_to_contact_id,ooh.ship_to_contact_id) ship_to_contact_id
                                                     --,ooh.sold_to_contact_id
 --,NVL(ool.deliver_to_contact_id,ooh.deliver_to_contact_id) deliver_to_contact_id
 --,NVL(ool.invoice_to_contact_id,ooh.invoice_to_contact_id) invoice_to_contact_id
            ,
            (SELECT ship_method_meaning
               FROM wsh_carrier_services_v
              WHERE ship_method_code =
                       NVL (ool.shipping_method_code, ooh.shipping_method_code))
               shipping_method --,NVL(ool.fob_point_code,ooh.fob_point_code) inco_term_code
                              ,
            (SELECT meaning
               FROM ar_lookups
              WHERE     lookup_type = 'FOB'
                    AND enabled_flag = 'Y'
                    AND UPPER (lookup_code) =
                           UPPER (NVL (ool.fob_point_code, ooh.fob_point_code))
                    AND TRUNC (SYSDATE) >=
                           TRUNC (NVL (start_date_active, SYSDATE))
                    AND TRUNC (SYSDATE) <=
                           TRUNC (NVL (end_date_active, SYSDATE + 1)))
               inco_term,
            NVL (ool.freight_terms_code, ooh.freight_terms_code)
               freight_terms_code,
            ooh.cust_po_number                   --,ooh.shipment_priority_code
                              ,
            (SELECT meaning
               FROM fnd_lookup_values_vl
              WHERE     lookup_type = 'SHIPMENT_PRIORITY'
                    AND lookup_code =
                           NVL (ool.shipment_priority_code,
                                ooh.shipment_priority_code)
                    AND NVL (enabled_flag, 'X') = 'Y'
                    AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                    AND NVL (end_date_active, SYSDATE))
               shipment_priority --,NVL(ool.payment_term_id,ooh.payment_term_id) payment_term_id
                                ,
            (SELECT name
               FROM ra_terms
              WHERE term_id = NVL (ool.payment_term_id, ooh.payment_term_id))
               payment_term --,NVL(ool.price_list_id,ooh.price_list_id) price_list_id
                           ,
            (SELECT name
               FROM qp_list_headers
              WHERE list_header_id = NVL (ool.price_list_id, ooh.price_list_id))
               price_list_name,
            (SELECT attribute3
               FROM qp_list_headers
              WHERE list_header_id = NVL (ool.price_list_id, ooh.price_list_id))
               gpo_info,
            ooh.attribute5 end_customer_po,
            ooh.tp_attribute1 freight_acct_num,
            ooh.tp_attribute3 charge_drop_ship,
            ooh.tp_attribute4 freight_insurance,
            ooh.tp_attribute2 shipper_proactive_flag,
            NVL (ool.attribute1, ooh.attribute1) charge_ship_method,
            DECODE (
               NVL (ool.shipping_instructions, ooh.shipping_instructions),
               NULL, NVL (ool.packing_instructions, ooh.packing_instructions),
                  NVL (ool.shipping_instructions, ooh.shipping_instructions)
               || ','
               || NVL (ool.packing_instructions, ooh.packing_instructions))
               shipping_instructions                                   -- Line
                                                           --,ool.line_type_id
                                                  --,ool.shipping_quantity_uom
            ,
            (SELECT name
               FROM oe_transaction_types_tl
              WHERE     TRANSACTION_TYPE_ID = ool.line_type_id
                    AND language = USERENV ('LANG'))
               order_line_type                                         -- Ship
                              ,
            ool.ship_from_org_id ship_org_id --ooh.ship_from_org_id ship_org_id
                                            ,
            (SELECT organization_code
               FROM mtl_parameters
              WHERE organization_id =
                       NVL (ool.ship_from_org_id, ooh.ship_from_org_id))
               warehouse,
            ship_acc.account_number ship_account,
            ship_acc.account_name ship_account_name,
            ship_use.site_use_id ship_site_id,
            ship_psite.party_site_name ship_site_name,
            ship_loc.address1 ship_address1,
            ship_loc.address2 ship_address2,
            ship_loc.address3 ship_address3,
            ship_loc.address4 ship_address4,
            ship_loc.city ship_city               --,ship_loc.state ship_state
                                   ,
            NVL (ship_loc.state, ship_loc.province) ship_state,
            ship_loc.country ship_country,
            ship_loc.postal_code ship_postal_code,
            ship_use.attribute7 freight_markup,
            (SELECT    rel_party.primary_phone_area_code
                    || '-'
                    || rel_party.primary_phone_number
                       phone
               FROM hz_contact_points cont_point,
                    hz_cust_account_roles acct_role,
                    hz_parties party,
                    hz_parties rel_party,
                    hz_relationships rel,
                    hz_cust_accounts role_acct
              WHERE     acct_role.party_id = rel.party_id
                    AND acct_role.role_type = 'CONTACT'
                    AND rel.subject_id = party.party_id
                    AND rel_party.party_id = rel.party_id
                    AND cont_point.owner_table_id(+) = rel_party.party_id
                    AND acct_role.cust_account_id = role_acct.cust_account_id
                    AND role_acct.party_id = rel.object_id
                    AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                    AND cont_point.contact_point_type = 'PHONE'
                    AND cont_point.primary_flag = 'Y'
                    AND cont_point.status = 'A'
                    AND acct_role.cust_account_role_id = ooh.ship_to_contact_id)
               ship_phone,
            (SELECT rel_party.email_address email_address
               FROM hz_contact_points cont_point,
                    hz_cust_account_roles acct_role,
                    hz_parties party,
                    hz_parties rel_party,
                    hz_relationships rel,
                    hz_cust_accounts role_acct
              WHERE     acct_role.party_id = rel.party_id
                    AND acct_role.role_type = 'CONTACT'
                    AND rel.subject_id = party.party_id
                    AND rel_party.party_id = rel.party_id
                    AND cont_point.owner_table_id(+) = rel_party.party_id
                    AND acct_role.cust_account_id = role_acct.cust_account_id
                    AND role_acct.party_id = rel.object_id
                    AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                    AND cont_point.contact_point_type = 'EMAIL'
                    AND cont_point.primary_flag = 'Y'
                    AND cont_point.status = 'A'
                    AND acct_role.cust_account_role_id = ooh.ship_to_contact_id)
               ship_email --,(SELECT DISTINCT ship_party.person_last_name||' ,'||ship_party.person_first_name
                         ,
            (SELECT DISTINCT
                       ship_party.person_first_name
                    || ' '
                    || ship_party.person_last_name
               FROM hz_cust_account_roles ship_roles,
                    hz_parties ship_party,
                    hz_relationships ship_rel,
                    hz_cust_accounts ship_acct
              WHERE     ship_roles.party_id = ship_rel.party_id(+)
                    AND ship_roles.role_type(+) = 'CONTACT'
                    AND ship_roles.cust_account_id =
                           ship_acct.cust_account_id(+)
                    AND NVL (ship_rel.object_id, -1) =
                           NVL (ship_acct.party_id, -1)
                    AND ship_rel.subject_id = ship_party.party_id(+)
                    AND ship_roles.cust_account_role_id =
                           ooh.ship_to_contact_id)
               ship_contact --,NVL(ooh.attribute1,(SELECT DISTINCT ship_party.person_last_name||' ,'||ship_party.person_first_name
                           ,
            NVL (
               ooh.attribute1,
               (SELECT DISTINCT
                          ship_party.person_first_name
                       || ' '
                       || ship_party.person_last_name
                  FROM hz_cust_account_roles ship_roles,
                       hz_parties ship_party,
                       hz_relationships ship_rel,
                       hz_cust_accounts ship_acct
                 WHERE     ship_roles.party_id = ship_rel.party_id(+)
                       AND ship_roles.role_type(+) = 'CONTACT'
                       AND ship_roles.cust_account_id =
                              ship_acct.cust_account_id(+)
                       AND NVL (ship_rel.object_id, -1) =
                              NVL (ship_acct.party_id, -1)
                       AND ship_rel.subject_id = ship_party.party_id(+)
                       --AND ship_roles.cust_account_role_id = ooh.sold_to_contact_id)) order_attention
                       AND ship_roles.cust_account_role_id =
                              NVL (ooh.deliver_to_contact_id,
                                   ooh.ship_to_contact_id)))
               order_attention,
            (SELECT currency_code
               FROM fnd_currencies_vl
              WHERE     issuing_territory_code = ship_loc.country
                    AND enabled_flag = 'Y'
                    AND iso_flag = 'Y'
                    AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                    AND NVL (end_date_active, SYSDATE))
               ship_currency,
            (SELECT rt.show_conversion_rate
               FROM gl_daily_rates_v rt, fnd_currencies_vl cr
              WHERE     rt.from_currency = wdd.currency_code
                    AND rt.to_currency = cr.currency_code
                    AND cr.issuing_territory_code = ship_loc.country
                    AND cr.enabled_flag = 'Y'
                    AND cr.iso_flag = 'Y'
                    AND SYSDATE BETWEEN NVL (cr.start_date_active, SYSDATE)
                                    AND NVL (cr.end_date_active, SYSDATE)
                    AND ROWNUM = 1
                    AND rt.conversion_date IN
                           (SELECT MAX (conversion_date)
                              FROM gl_daily_rates_v
                             WHERE     from_currency = rt.from_currency
                                   AND to_currency = rt.to_currency))
               ship_currency_rate,
            (SELECT rt.show_conversion_rate
               FROM gl_daily_rates_v rt
              WHERE     rt.from_currency = wdd.currency_code
                    AND rt.to_currency = 'USD'
                    AND ROWNUM = 1
                    AND rt.conversion_date IN
                           (SELECT MAX (conversion_date)
                              FROM gl_daily_rates_v
                             WHERE     from_currency = rt.from_currency
                                   AND to_currency = rt.to_currency))
               conv_to_usd                                          -- Deliver
                          ,
            del_acc.account_number del_account --,del_acc.account_name del_account_name
                                              ,
            del_use.location del_account_name,
            del_use.site_use_id del_site_id,
            del_psite.party_site_name del_site_name,
            del_loc.address1 del_address1,
            del_loc.address2 del_address2,
            del_loc.address3 del_address3,
            del_loc.address4 del_address4,
            del_loc.city del_city                   --,del_loc.state del_state
                                 ,
            NVL (del_loc.state, del_loc.province) del_state,
            del_loc.country del_country,
            del_loc.postal_code del_postal_code,
            (SELECT    rel_party.primary_phone_area_code
                    || '-'
                    || rel_party.primary_phone_number
                       phone
               FROM hz_contact_points cont_point,
                    hz_cust_account_roles acct_role,
                    hz_parties party,
                    hz_parties rel_party,
                    hz_relationships rel,
                    hz_cust_accounts role_acct
              WHERE     acct_role.party_id = rel.party_id
                    AND acct_role.role_type = 'CONTACT'
                    AND rel.subject_id = party.party_id
                    AND rel_party.party_id = rel.party_id
                    AND cont_point.owner_table_id(+) = rel_party.party_id
                    AND acct_role.cust_account_id = role_acct.cust_account_id
                    AND role_acct.party_id = rel.object_id
                    AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                    AND cont_point.contact_point_type = 'PHONE'
                    AND cont_point.primary_flag = 'Y'
                    AND cont_point.status = 'A'
                    AND acct_role.cust_account_role_id =
                           ooh.deliver_to_contact_id)
               del_phone,
            (SELECT rel_party.email_address email_address
               FROM hz_contact_points cont_point,
                    hz_cust_account_roles acct_role,
                    hz_parties party,
                    hz_parties rel_party,
                    hz_relationships rel,
                    hz_cust_accounts role_acct
              WHERE     acct_role.party_id = rel.party_id
                    AND acct_role.role_type = 'CONTACT'
                    AND rel.subject_id = party.party_id
                    AND rel_party.party_id = rel.party_id
                    AND cont_point.owner_table_id(+) = rel_party.party_id
                    AND acct_role.cust_account_id = role_acct.cust_account_id
                    AND role_acct.party_id = rel.object_id
                    AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                    AND cont_point.contact_point_type = 'EMAIL'
                    AND cont_point.primary_flag = 'Y'
                    AND cont_point.status = 'A'
                    AND acct_role.cust_account_role_id =
                           ooh.deliver_to_contact_id)
               del_email --,(SELECT DISTINCT ship_party.person_last_name||' ,'||ship_party.person_first_name
                        ,
            (SELECT DISTINCT
                       ship_party.person_first_name
                    || ' '
                    || ship_party.person_last_name
               FROM hz_cust_account_roles ship_roles,
                    hz_parties ship_party,
                    hz_relationships ship_rel,
                    hz_cust_accounts ship_acct
              WHERE     ship_roles.party_id = ship_rel.party_id(+)
                    AND ship_roles.role_type(+) = 'CONTACT'
                    AND ship_roles.cust_account_id =
                           ship_acct.cust_account_id(+)
                    AND NVL (ship_rel.object_id, -1) =
                           NVL (ship_acct.party_id, -1)
                    AND ship_rel.subject_id = ship_party.party_id(+)
                    AND ship_roles.cust_account_role_id =
                           ooh.deliver_to_contact_id)
               del_contact,
            (SELECT currency_code
               FROM fnd_currencies_vl
              WHERE     issuing_territory_code = del_loc.country
                    AND enabled_flag = 'Y'
                    AND iso_flag = 'Y'
                    AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                    AND NVL (end_date_active, SYSDATE))
               del_currency,
            (SELECT rt.show_conversion_rate
               FROM gl_daily_rates_v rt, fnd_currencies_vl cr
              WHERE     rt.from_currency = wdd.currency_code
                    AND rt.to_currency = cr.currency_code
                    AND cr.issuing_territory_code = del_loc.country
                    AND cr.enabled_flag = 'Y'
                    AND cr.iso_flag = 'Y'
                    AND SYSDATE BETWEEN NVL (cr.start_date_active, SYSDATE)
                                    AND NVL (cr.end_date_active, SYSDATE)
                    AND ROWNUM = 1
                    AND rt.conversion_date IN
                           (SELECT MAX (conversion_date)
                              FROM gl_daily_rates_v
                             WHERE     from_currency = rt.from_currency
                                   AND to_currency = rt.to_currency))
               del_currency_rate                                    -- Invoice
                                ,
            invoice_acc.account_number bill_account,
            invoice_acc.account_name bill_account_name,
            invoice_use.site_use_id bill_site_id,
            invoice_psite.party_site_name bill_site_name,
            invoice_loc.address1 bill_address1,
            invoice_loc.address2 bill_address2,
            invoice_loc.address3 bill_address3,
            invoice_loc.address4 bill_address4,
            invoice_loc.city bill_city         --,invoice_loc.state bill_state
                                      ,
            NVL (invoice_loc.state, invoice_loc.province) bill_state,
            invoice_loc.country bill_country,
            invoice_loc.postal_code bill_postal_code,
            (SELECT    rel_party.primary_phone_area_code
                    || '-'
                    || rel_party.primary_phone_number
                       phone
               FROM hz_contact_points cont_point,
                    hz_cust_account_roles acct_role,
                    hz_parties party,
                    hz_parties rel_party,
                    hz_relationships rel,
                    hz_cust_accounts role_acct
              WHERE     acct_role.party_id = rel.party_id
                    AND acct_role.role_type = 'CONTACT'
                    AND rel.subject_id = party.party_id
                    AND rel_party.party_id = rel.party_id
                    AND cont_point.owner_table_id(+) = rel_party.party_id
                    AND acct_role.cust_account_id = role_acct.cust_account_id
                    AND role_acct.party_id = rel.object_id
                    AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                    AND cont_point.contact_point_type = 'PHONE'
                    AND cont_point.primary_flag = 'Y'
                    AND cont_point.status = 'A'
                    AND acct_role.cust_account_role_id =
                           ooh.invoice_to_contact_id)
               bill_phone,
            (SELECT rel_party.email_address email_address
               FROM hz_contact_points cont_point,
                    hz_cust_account_roles acct_role,
                    hz_parties party,
                    hz_parties rel_party,
                    hz_relationships rel,
                    hz_cust_accounts role_acct
              WHERE     acct_role.party_id = rel.party_id
                    AND acct_role.role_type = 'CONTACT'
                    AND rel.subject_id = party.party_id
                    AND rel_party.party_id = rel.party_id
                    AND cont_point.owner_table_id(+) = rel_party.party_id
                    AND acct_role.cust_account_id = role_acct.cust_account_id
                    AND role_acct.party_id = rel.object_id
                    AND cont_point.owner_table_name(+) = 'HZ_PARTIES'
                    AND cont_point.contact_point_type = 'EMAIL'
                    AND cont_point.primary_flag = 'Y'
                    AND cont_point.status = 'A'
                    AND acct_role.cust_account_role_id =
                           ooh.invoice_to_contact_id)
               bill_email --,(SELECT DISTINCT ship_party.person_last_name||' ,'||ship_party.person_first_name
                         ,
            (SELECT DISTINCT
                       ship_party.person_first_name
                    || ' '
                    || ship_party.person_last_name
               FROM hz_cust_account_roles ship_roles,
                    hz_parties ship_party,
                    hz_relationships ship_rel,
                    hz_cust_accounts ship_acct
              WHERE     ship_roles.party_id = ship_rel.party_id(+)
                    AND ship_roles.role_type(+) = 'CONTACT'
                    AND ship_roles.cust_account_id =
                           ship_acct.cust_account_id(+)
                    AND NVL (ship_rel.object_id, -1) =
                           NVL (ship_acct.party_id, -1)
                    AND ship_rel.subject_id = ship_party.party_id(+)
                    AND ship_roles.cust_account_role_id =
                           ooh.invoice_to_contact_id)
               bill_contact,
            (SELECT currency_code
               FROM fnd_currencies_vl
              WHERE     issuing_territory_code = invoice_loc.country
                    AND enabled_flag = 'Y'
                    AND iso_flag = 'Y'
                    AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                    AND NVL (end_date_active, SYSDATE))
               bill_currency,
            (SELECT rt.show_conversion_rate
               FROM gl_daily_rates_v rt, fnd_currencies_vl cr
              WHERE     rt.from_currency = wdd.currency_code
                    AND rt.to_currency = cr.currency_code
                    AND cr.issuing_territory_code = invoice_loc.country
                    AND cr.enabled_flag = 'Y'
                    AND cr.iso_flag = 'Y'
                    AND SYSDATE BETWEEN NVL (cr.start_date_active, SYSDATE)
                                    AND NVL (cr.end_date_active, SYSDATE)
                    AND ROWNUM = 1
                    AND rt.conversion_date IN
                           (SELECT MAX (conversion_date)
                              FROM gl_daily_rates_v
                             WHERE     from_currency = rt.from_currency
                                   AND to_currency = rt.to_currency))
               bill_currency_rate                                           --
                                                                 --,wdd.lpn_id
            ,
            lpn.license_plate_number,
            wdd.organization_id,
            wdd.inventory_item_id                          --,wdd.subinventory
                                 ,
            wdd.shipped_quantity,
            wdd.requested_quantity_uom uom     --,wdd.unit_price selling_price
                                          ,
            ool.unit_selling_price selling_price,
            wdd.currency_code,
            wdd.lot_number,
            wdd.created_by ship_created_by,
            wnd.ultimate_dropoff_date ship_created_date                -- Item
                                                       ,
            itm.segment1 item_number,
            itm.description item_desc,
            (SELECT category_concat_segs
               FROM mtl_item_categories_v
              WHERE     inventory_item_id = itm.inventory_item_id
                    AND organization_id = itm.organization_id
                    AND category_set_name = 'Inventory')
               item_inv_category_set,
            (SELECT description
               FROM po_hazard_classes_tl
              WHERE     hazard_class_id = itm.hazard_class_id
                    AND language = USERENV ('LANG'))
               item_hazard_class,
            (SELECT un_number
               FROM po_un_numbers_tl
              WHERE     un_number_id = itm.un_number_id
                    AND language = USERENV ('LANG'))
               item_un_number,
            NVL (itm.attribute_category, itm_mst.attribute_category)
               item_attr_context,
            NVL (itm.attribute1, itm_mst.attribute1) item_attribute1,
            NVL (itm.attribute2, itm_mst.attribute2) item_attribute2,
            NVL (itm.attribute3, itm_mst.attribute3) item_attribute3,
            NVL (itm.attribute4, itm_mst.attribute4) item_attribute4,
            NVL (itm.attribute5, itm_mst.attribute5) item_attribute5,
            NVL (itm.attribute6, itm_mst.attribute6) item_attribute6,
            NVL (itm.attribute7, itm_mst.attribute7) item_attribute7,
            NVL (itm.attribute8, itm_mst.attribute8) item_attribute8,
            NVL (itm.attribute9, itm_mst.attribute9) item_attribute9,
            NVL (itm.attribute10, itm_mst.attribute10) item_attribute10,
            NVL (itm.attribute11, itm_mst.attribute11) item_attribute11,
            NVL (itm.attribute12, itm_mst.attribute12) item_attribute12 --,NVL(itm.attribute13,itm_mst.attribute13) item_attribute13
                                                                       ,
            NVL (itm.attribute17, itm_mst.attribute17) item_attribute13,
            NVL (itm.attribute14, itm_mst.attribute14) item_attribute14,
            NVL (itm.attribute15, itm_mst.attribute15) item_attribute15,
            NVL (itm.attribute16, itm_mst.attribute16) item_attribute16,
            NVL (itm.attribute17, itm_mst.attribute17) item_attribute17,
            NVL (itm.attribute18, itm_mst.attribute18) item_attribute18,
            NVL (itm.attribute19, itm_mst.attribute19) item_attribute19,
            NVL (itm.attribute20, itm_mst.attribute20) item_attribute20,
            NVL (itm.attribute21, itm_mst.attribute21) item_attribute21,
            NVL (itm.attribute22, itm_mst.attribute22) item_attribute22,
            NVL (itm.attribute23, itm_mst.attribute23) item_attribute23,
            NVL (itm.attribute24, itm_mst.attribute24) item_attribute24,
            NVL (itm.attribute25, itm_mst.attribute25) item_attribute25,
            NVL (itm.attribute26, itm_mst.attribute26) item_attribute26,
            NVL (itm.attribute27, itm_mst.attribute27) item_attribute27,
            NVL (itm.attribute28, itm_mst.attribute28) item_attribute28,
            NVL (itm.attribute29, itm_mst.attribute29) item_attribute29,
            NVL (itm.attribute30, itm_mst.attribute30) item_attribute30
       FROM oe_order_headers_all ooh,
            oe_order_lines_all ool,
            (SELECT NVL (ool.deliver_to_org_id, ooh.deliver_to_org_id)
                       deliver_to_org_id,
                    ooh.header_id,
                    ool.line_id
               FROM oe_order_headers_all ooh, oe_order_lines_all ool
              WHERE ooh.header_id = ool.header_id) deliver,
            mtl_system_items_b msi,
            wsh_delivery_details wdd,
            wsh_delivery_assignments wds,
            wsh_new_deliveries wnd                                     -- Item
                                  ,
            mtl_system_items_b itm,
            mtl_system_items_b itm_mst,
            mtl_parameters pram_mast                                -- Ship to
                                    ,
            hz_cust_acct_sites_all ship_site,
            hz_cust_site_uses_all ship_use,
            hz_party_sites ship_psite,
            hz_locations ship_loc,
            hz_cust_accounts ship_acc                            -- Deliver to
                                     ,
            hz_cust_acct_sites_all del_site,
            hz_cust_site_uses_all del_use,
            hz_party_sites del_psite,
            hz_locations del_loc,
            hz_cust_accounts del_acc                             -- invoice to
                                    ,
            hz_cust_acct_sites_all invoice_site,
            hz_cust_site_uses_all invoice_use,
            hz_party_sites invoice_psite,
            hz_locations invoice_loc,
            hz_cust_accounts invoice_acc,
            wms_license_plate_numbers lpn,
            mtl_parameters pram
      WHERE     ooh.header_id = ool.header_id
            AND msi.inventory_item_id = ool.inventory_item_id
            AND ool.ship_from_org_id = msi.organization_id
            AND itm_mst.organization_id = pram_mast.organization_id
            AND pram_mast.organization_code = 'MST'
            AND itm_mst.inventory_item_id = msi.inventory_item_id
            --
            AND wdd.source_line_id = ool.line_id
            AND wdd.source_header_id = ooh.header_id
            AND wds.delivery_detail_id = wdd.delivery_detail_id
            AND wds.delivery_id = wnd.delivery_id
            AND wdd.organization_id = itm.organization_id
            AND wdd.inventory_item_id = itm.inventory_item_id
            -- Ship to
            AND NVL (ool.ship_to_org_id, ooh.ship_to_org_id) =
                   ship_use.site_use_id
            AND ship_use.cust_acct_site_id = ship_site.cust_acct_site_id(+)
            AND ship_site.party_site_id = ship_psite.party_site_id(+)
            AND ship_psite.location_id = ship_loc.location_id(+)
            AND ship_site.cust_account_id = ship_acc.cust_account_id(+)
            -- Deliver to
            AND deliver.header_id = ooh.header_id
            AND deliver.line_id = ool.line_id
            AND deliver.deliver_to_org_id = del_use.site_use_id(+)
            --AND  ool.deliver_to_org_id =  del_use.site_use_id(+)
            AND del_use.cust_acct_site_id = del_site.cust_acct_site_id(+)
            AND del_site.party_site_id = del_psite.party_site_id(+)
            AND del_psite.location_id = del_loc.location_id(+)
            AND del_site.cust_account_id = del_acc.cust_account_id(+)
            -- Invoice to
            AND NVL (ool.invoice_to_org_id, ooh.invoice_to_org_id) =
                   invoice_use.site_use_id
            AND invoice_use.cust_acct_site_id =
                   invoice_site.cust_acct_site_id(+)
            AND invoice_site.party_site_id = invoice_psite.party_site_id(+)
            AND invoice_psite.location_id = invoice_loc.location_id(+)
            AND invoice_site.cust_account_id = invoice_acc.cust_account_id(+)
            --
            AND wdd.lpn_id = lpn.lpn_id(+)
            AND wdd.organization_id = pram.organization_id
            AND wdd.released_status = 'Y'
   ORDER BY ooh.header_id DESC;


CREATE OR REPLACE SYNONYM XX_SHPRO.XX_OM_SHIP_MANIFEST_V FOR APPS.XX_OM_SHIP_MANIFEST_V;


GRANT SELECT ON APPS.XX_OM_SHIP_MANIFEST_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_OM_SHIP_MANIFEST_V TO XX_SHPRO;
