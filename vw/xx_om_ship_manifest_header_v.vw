DROP VIEW APPS.XX_OM_SHIP_MANIFEST_HEADER_V;

/* Formatted on 6/6/2016 4:58:19 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OM_SHIP_MANIFEST_HEADER_V
(
   ORG_ID,
   ORG_CODE,
   HEADER_ID,
   ORDER_NUMBER,
   DELIVERY_ID,
   DELIVERY_NUMBER,
   STATUS_CODE,
   ORDER_TYPE,
   ORDERED_DATE,
   ORDER_SOURCE_NAME,
   FREIGHT_ACCOUNT,
   FREIGHT_ACCT_NUM,
   ORDER_ATTENTION,
   SHIPTO_CONTACT,
   SHIP_ACCOUNT,
   SHIP_ORG_ID,
   SHIP_ACCOUNT_NAME,
   SHIP_SITE_ID,
   SHIP_CITY,
   SHIP_STATE,
   SHIP_COUNTRY,
   SHIP_SITE_NAME,
   SHIP_ADDRESS1,
   SHIP_ADDRESS2,
   SHIP_ADDRESS3,
   SHIP_ADDRESS4,
   SHIP_POSTAL_CODE,
   SHIP_PHONE,
   SHIP_EMAIL,
   SHIP_CURRENCY,
   SHIP_CURRENCY_RATE,
   DEL_ACCOUNT,
   DEL_CONTACT,
   DEL_ACCOUNT_NAME_OLD,
   DEL_ACCOUNT_NAME,
   DEL_SITE_ID,
   DEL_CITY,
   DEL_STATE,
   DEL_COUNTRY,
   DEL_SITE_NAME,
   DEL_ADDRESS1,
   DEL_ADDRESS2,
   DEL_ADDRESS3,
   DEL_ADDRESS4,
   DEL_POSTAL_CODE,
   DEL_PHONE,
   DEL_EMAIL,
   DEL_CURRENCY,
   DEL_CURRENCY_RATE,
   BILL_ACCOUNT_NAME,
   BILL_ACCOUNT,
   BILL_SITE_ID,
   BILL_CITY,
   BILL_STATE,
   BILL_COUNTRY,
   BILL_SITE_NAME,
   BILL_ADDRESS1,
   BILL_ADDRESS2,
   BILL_ADDRESS3,
   BILL_ADDRESS4,
   BILL_POSTAL_CODE,
   BILL_PHONE,
   BILL_EMAIL,
   BILL_CONTACT,
   BILL_CURRENCY,
   BILL_CURRENCY_RATE,
   SHIPPING_METHOD,
   FREIGHT_TERMS_CODE,
   INCO_TERM,
   CUST_PO_NUMBER,
   END_CUSTOMER_PO,
   SHIPPER_PROACTIVE_FLAG,
   DAY_RESTRICT,
   FREIGHT_MARKUP,
   FREIGHT_INSURANCE,
   CHARGE_DROP_SHIP,
   SHIPPING_INSTRUCTIONS,
   REQUEST_DATE,
   WAREHOUSE,
   NO_OF_PICKED_LINES,
   NO_OF_DEL_LINES
)
AS
   SELECT DISTINCT
          ooh.org_id,
          hro.short_code org_code,
          ooh.header_id                                   --,hro.name org_name
                       ,
          ooh.order_number,
          wnd.delivery_id,
          wnd.name delivery_number,
          wnd.status_code,
          oht.name order_type,
          ooh.ordered_date,
          ohs.name order_source_name,
          ooh.tp_attribute1 freight_account --,TRIM(xx_om_ship_out_pkg.get_fright_acc_no(ooh.tp_attribute1,ooh.ship_to_org_id,wnd.ship_method_code)) freight_account_no2
                                           ,
          DECODE (
             NVL (wnd.freight_terms_code, ooh.freight_terms_code),
             'THIRD_PARTY', TRIM (
                               xx_om_ship_out_pkg.get_fright_acc_no (
                                  ooh.tp_attribute1,
                                  ooh.ship_to_org_id,
                                  wnd.ship_method_code)),
             ooh.tp_attribute1)
             freight_acct_num /*         ,NVL(ooh.attribute1,(SELECT DISTINCT ship_party.person_first_name||' '||ship_party.person_last_name
                                                                  FROM hz_cust_account_roles ship_roles,
                                                                       hz_parties ship_party,
                                                                       hz_relationships ship_rel,
                                                                       hz_cust_accounts ship_acct
                                                                 WHERE ship_roles.party_id             = ship_rel.party_id(+)
                                                                   AND ship_roles.role_type(+)         = 'CONTACT'
                                                                   AND ship_roles.cust_account_id      = ship_acct.cust_account_id(+)
                                                                   AND NVL(ship_rel.object_id, -1)     = NVL (ship_acct.party_id, -1)
                                                                   AND ship_rel.subject_id             = ship_party.party_id(+)
                                                                   --AND ship_roles.cust_account_role_id = ooh.sold_to_contact_id)) order_attention
                                                                   AND ship_roles.cust_account_role_id = nvl(ooh.deliver_to_contact_id, ooh.ship_to_contact_id))) order_attention*/
                             ,
          ooh.attribute1 order_attention,
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
             shipto_contact,
          ship_acc.account_number ship_account,
          ooh.ship_from_org_id ship_org_id,
          ship_acc.account_name ship_account_name,
          ship_use.site_use_id ship_site_id,
          ship_loc.city ship_city,
          NVL (ship_loc.state, ship_loc.province) ship_state,
          ship_loc.country ship_country,
          ship_psite.party_site_name ship_site_name,
          ship_loc.address1 ship_address1,
          ship_loc.address2 ship_address2,
          ship_loc.address3 ship_address3,
          ship_loc.address4 ship_address4,
          ship_loc.postal_code ship_postal_code,
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
             ship_email,
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
            WHERE     rt.from_currency = wnd.currency_code
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
          del_acc.account_number del_account,
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
          del_use.location del_account_name_old,
          ooh.attribute20 del_account_name,
          del_use.site_use_id del_site_id,
          del_loc.city del_city,
          NVL (del_loc.state, del_loc.province) del_state,
          del_loc.country del_country,
          del_psite.party_site_name del_site_name,
          del_loc.address1 del_address1,
          del_loc.address2 del_address2,
          del_loc.address3 del_address3,
          del_loc.address4 del_address4,
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
             del_email,
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
            WHERE     rt.from_currency = wnd.currency_code
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
             del_currency_rate,
          invoice_acc.account_name bill_account_name,
          invoice_acc.account_number bill_account,
          invoice_use.site_use_id bill_site_id,
          invoice_loc.city bill_city,
          NVL (invoice_loc.state, invoice_loc.province) bill_state,
          invoice_loc.country bill_country,
          invoice_psite.party_site_name bill_site_name,
          invoice_loc.address1 bill_address1,
          invoice_loc.address2 bill_address2,
          invoice_loc.address3 bill_address3,
          invoice_loc.address4 bill_address4,
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
            WHERE     rt.from_currency = wnd.currency_code
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
             bill_currency_rate,
          car.ship_method_meaning shipping_method,
          NVL (wnd.freight_terms_code, ooh.freight_terms_code)
             freight_terms_code,
          (SELECT meaning
             FROM ar_lookups
            WHERE     lookup_type = 'FOB'
                  AND enabled_flag = 'Y'
                  AND UPPER (lookup_code) =
                         UPPER (NVL (wnd.fob_code, ooh.fob_point_code))
                  AND TRUNC (SYSDATE) >=
                         TRUNC (NVL (start_date_active, SYSDATE))
                  AND TRUNC (SYSDATE) <=
                         TRUNC (NVL (end_date_active, SYSDATE + 1)))
             inco_term,
          ooh.cust_po_number,
          ooh.attribute5 end_customer_po --,ooh.tp_attribute2 shipper_proactive_flag
                                        ,
          DECODE (
             ooh.tp_attribute2,
             'Y', 'Proactive',
             NULL, DECODE (
                      xx_om_ship_out_pkg.get_proactive_flag (wnd.delivery_id),
                      'Y', 'Proactive',
                      NULL))
             shipper_proactive_flag,
          xx_om_ship_out_pkg.get_days_restrict (wnd.delivery_id) day_restrict,
          ship_use.attribute7 freight_markup,
          ooh.tp_attribute4 freight_insurance,
          ooh.tp_attribute3 charge_drop_ship,
          DECODE (ooh.shipping_instructions,
                  NULL, ooh.packing_instructions,
                  ooh.shipping_instructions)
             shipping_instructions,
          ooh.request_date,
          (SELECT organization_code
             FROM mtl_parameters
            WHERE organization_id = ooh.ship_from_org_id)
             warehouse,
          (SELECT COUNT (*)
             FROM wsh_delivery_details wdd1, wsh_delivery_assignments wda1
            WHERE     wdd1.delivery_detail_id = wda1.delivery_detail_id
                  AND wda1.delivery_id = wnd.delivery_id
                  AND wdd1.released_status IN ('Y', 'X')
                  AND wdd1.source_code = 'OE'
                  AND wdd1.container_flag = 'N')
             no_of_picked_lines,
          (SELECT COUNT (*)
             FROM wsh_delivery_details wdd2, wsh_delivery_assignments wda2
            WHERE     wdd2.delivery_detail_id = wda2.delivery_detail_id
                  AND wda2.delivery_id = wnd.delivery_id
                  AND wdd2.source_code = 'OE'
                  AND wdd2.container_flag = 'N')
             no_of_del_lines
     FROM oe_order_headers_all ooh,
          wsh_new_deliveries wnd,
          wsh_delivery_assignments wad,
          wsh_delivery_details wdd                                          --
                                  ,
          hr_operating_units hro,
          oe_transaction_types_tl oht,
          oe_order_sources ohs,
          wsh_carrier_services_v car                                -- Ship to
                                    ,
          hz_cust_acct_sites_all ship_site,
          hz_cust_site_uses_all ship_use,
          hz_party_sites ship_psite,
          hz_locations ship_loc,
          hz_cust_accounts ship_acc                              -- Deliver to
                                   ,
          hz_cust_acct_sites_all del_site,
          hz_cust_site_uses_all del_use,
          hz_party_sites del_psite,
          hz_locations del_loc,
          hz_cust_accounts del_acc                               -- invoice to
                                  ,
          hz_cust_acct_sites_all invoice_site,
          hz_cust_site_uses_all invoice_use,
          hz_party_sites invoice_psite,
          hz_locations invoice_loc,
          hz_cust_accounts invoice_acc
    WHERE     oht.transaction_type_id = ooh.order_type_id
          AND oht.language = USERENV ('LANG')
          AND ohs.order_source_id = ooh.order_source_id(+)
          AND car.ship_method_code =
                 NVL (wnd.ship_method_code, ooh.shipping_method_code)
          AND NVL (wnd.source_header_id, wdd.source_header_id) =
                 ooh.header_id
          AND wnd.delivery_id = wad.delivery_id
          AND wad.delivery_detail_id = wdd.delivery_detail_id
          AND hro.organization_id = ooh.org_id
          -- Ship to
          AND ooh.ship_to_org_id = ship_use.site_use_id
          AND ship_use.cust_acct_site_id = ship_site.cust_acct_site_id(+)
          AND ship_site.party_site_id = ship_psite.party_site_id(+)
          --AND  ship_psite.location_id = ship_loc.location_id(+)
          AND wnd.ultimate_dropoff_location_id = ship_loc.location_id(+)
          AND ship_site.cust_account_id = ship_acc.cust_account_id(+)
          -- Deliver to
          AND ooh.deliver_to_org_id = del_use.site_use_id(+)
          AND del_use.cust_acct_site_id = del_site.cust_acct_site_id(+)
          AND del_site.party_site_id = del_psite.party_site_id(+)
          AND del_psite.location_id = del_loc.location_id(+)
          AND del_site.cust_account_id = del_acc.cust_account_id(+)
          -- Invoice to
          AND ooh.invoice_to_org_id = invoice_use.site_use_id
          AND invoice_use.cust_acct_site_id =
                 invoice_site.cust_acct_site_id(+)
          AND invoice_site.party_site_id = invoice_psite.party_site_id(+)
          AND invoice_psite.location_id = invoice_loc.location_id(+)
          AND invoice_site.cust_account_id = invoice_acc.cust_account_id(+)
/*
    AND  (SELECT COUNT(*)
            FROM wsh_delivery_details wdd1, wsh_delivery_assignments wda1
           WHERE wdd1.delivery_detail_id = wda1.delivery_detail_id
             AND wda1.delivery_id = wnd.delivery_id
             AND wdd1.released_status IN ('Y','X')
             AND wdd1.source_code = 'OE'
             AND wdd1.container_flag = 'N')
       = (SELECT count(*)
            FROM wsh_delivery_details wdd2, wsh_delivery_assignments wda2
           WHERE wdd2.delivery_detail_id = wda2.delivery_detail_id
             AND wda2.delivery_id = wnd.delivery_id
             AND wdd2.source_code = 'OE'
             AND wdd2.container_flag = 'N'
         )*/
;


CREATE OR REPLACE SYNONYM XX_SHPRO.XX_OM_SHIP_MANIFEST_HEADER_V FOR APPS.XX_OM_SHIP_MANIFEST_HEADER_V;


GRANT SELECT ON APPS.XX_OM_SHIP_MANIFEST_HEADER_V TO XXAPPSREAD;

GRANT SELECT ON APPS.XX_OM_SHIP_MANIFEST_HEADER_V TO XX_SHPRO;
