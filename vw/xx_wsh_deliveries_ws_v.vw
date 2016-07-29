DROP VIEW APPS.XX_WSH_DELIVERIES_WS_V;

/* Formatted on 6/6/2016 4:57:58 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_WSH_DELIVERIES_WS_V
(
   PUBLISH_BATCH_ID,
   TRANSACTION_DATE,
   DOCUMENT_CODE,
   TP_LOCATION_CODE_EXT,
   TRANSLATED_CUSTOMER_NAME,
   CUSTOMER_NUMBER,
   ORGANIZATION_ID,
   TRIP_ID,
   TRIP_NAME,
   DEPARTURE_DATE,
   DELIVERY_ID,
   DELIVERY_NAME,
   TIME_STAMP_SEQUENCE_NUMBER,
   TIME_STAMP_DATE,
   INITIAL_PICKUP_DATE,
   EARLIEST_PICKUP_DATE,
   LATEST_PICKUP_DATE,
   DELIVERED_DATE,
   EARLIEST_DROPOFF_DATE,
   LATEST_DROPOFF_DATE,
   EQUIPMENT_PREFIX,
   EQUIPMENT_NUMBER,
   EQUIPMENT_SEAL,
   CARRIER_NAME_INT,
   PICK_UP_LOCAION_ID,
   PICK_UP_STOP_ID,
   DROP_OFF_LOCATION_ID,
   DROP_OFF_STOP_ID,
   DEPARTURE_GROSS_WEIGHT,
   DEPARTURE_GROSS_WEIGHT_UOM_INT,
   DEPARTURE_NET_WEIGHT,
   DEPARTURE_NET_WEIGHT_UOM_INT,
   DEPARTURE_TARE_WEIGHT,
   DEPARTURE_TARE_WEIGHT_UOM_INT,
   DEPARTURE_VOLUME,
   DEPARTURE_VOLUME_UOM_INT,
   ROUTING_INSTRUCTIONS1,
   ROUTING_INSTRUCTIONS2,
   ROUTING_INSTRUCTIONS3,
   ROUTING_INSTRUCTIONS4,
   ROUTING_INSTRUCTIONS5,
   WAREHOUSE_LOCATION_ID,
   WAREHOUSE_CODE_INT,
   WAREHOUSE_EDI_LOC_CODE,
   WAREHOUSE_NAME,
   WAREHOUSE_ADDRESS1,
   WAREHOUSE_ADDRESS2,
   WAREHOUSE_ADDRESS3,
   WAREHOUSE_CITY,
   WAREHOUSE_POSTAL_CODE,
   WAREHOUSE_COUNTRY_INT,
   WAREHOUSE_REGION1_INT,
   WAREHOUSE_REGION2_INT,
   WAREHOUSE_REGION3_INT,
   WAREHOUSE_TELEPHONE_1,
   WAREHOUSE_TELEPHONE_2,
   WAREHOUSE_TELEPHONE_3,
   DELIVERY_ADDRESS_ID,
   DELIVERY_CODE_INT,
   DELIVERY_EDI_LOC_CODE,
   DELIVERY_CUST_NAME,
   DELIVERY_ADDRESS1,
   DELIVERY_ADDRESS2,
   DELIVERY_ADDRESS3,
   DELIVERY_ADDRESS4,
   DELIVERY_CITY,
   DELIVERY_POSTAL_CODE,
   DELIVERY_COUNTRY_INT,
   DELIVERY_STATE_INT,
   DELIVERY_PROVINCE_INT,
   DELIVERY_COUNTY,
   DELIVERY_AREA_CODE,
   DELIVERY_TELEPHONE,
   DESTINATION_ADDRESS_ID,
   DESTINATION_CUSTOMER_ID,
   DESTINATION_SITE_USE_ID,
   DESTINATION_CODE_INT,
   DESTINATION_EDI_LOC_CODE,
   DESTINATION_NAME,
   DESTINATION_ADDRESS1,
   DESTINATION_ADDRESS2,
   DESTINATION_ADDRESS3,
   DESTINATION_ADDRESS4,
   DESTINATION_CITY,
   DESTINATION_POSTAL_CODE,
   DESTINATION_COUNTRY_INT,
   DESTINATION_STATE_INT,
   DESTINATION_PROVINCE_INT,
   DESTINATION_COUNTY,
   DESTINATION_AREA_CODE,
   DESTINATION_TELEPHONE,
   SHIPPER_NUMBER,
   WAYBILL_NUMBER,
   BILL_OF_LADING,
   PACKING_SLIP_NUMBER,
   ACTUAL_SHIP_DATE,
   DELIVERY_GROSS_WEIGHT,
   DELIVERY_GROSS_WEIGHT_UOM_INT,
   DELIVERY_VOLUME,
   DELIVERY_VOLUME_UOM_INT,
   DELIVERY_NET_WEIGHT,
   DELIVERY_NET_WEIGHT_UOM_INT,
   DELIVERY_TARE_WEIGHT,
   DELIVERY_TARE_WEIGHT_UOM_INT,
   EXPECTED_ARRIVAL_DATE,
   FREIGHT_TERMS_CODE_INT,
   NUMBER_OF_LPN,
   SHIP_METHOD_CODE_INT,
   FOB_POINT_CODE_INT,
   FOB_LOCATION_ID,
   POOLED_SHIP_TO_LOCATION_ID,
   INTMED_SHIP_TO_LOCATION_ID,
   VEHICLE_ORGANIZATION_ID,
   VEHICLE_ITEM_ID,
   CONTACT_ID,
   SHIP_METHOD_NAME_INT,
   ORDER_SOURCE
)
AS
   SELECT /*+ ORDERED USE_NL(HCAS) USE_NL(HCSU) */
          DISTINCT
          NULL publish_batch_id,
          SYSDATE transaction_date,
          wnd.NAME document_code --, hcas.ece_tp_location_code tp_location_code_ext ----Commented as per DCR#100912
                                ,
          hcas.attribute5 tp_location_code_ext     ----Added as per DCR#100912
                                              --, hcas.translated_customer_name translated_customer_name ----Commented as per DCR#100912
          ,
          hcas.attribute4 translated_customer_name ----Added as per DCR#100912
                                                  ,
          cust_acct1.account_number customer_number,
          wnd.organization_id organization_id,
          wtp.trip_id trip_id,
          wtp.NAME trip_name,
          wts.actual_departure_date departure_date,
          wnd.delivery_id delivery_id,
          wnd.NAME delivery_name,
          wnd.asn_seq_number time_stamp_sequence_number,
          wnd.asn_date_sent time_stamp_date,
          wnd.initial_pickup_date initial_pickup_date,
          wnd.earliest_pickup_date earliest_pickup_date,
          wnd.latest_pickup_date latest_pickup_date,
          wnd.delivered_date delivered_date,
          wnd.earliest_dropoff_date earliest_dropoff_date,
          wnd.latest_dropoff_date latest_dropoff_date,
          wtp.vehicle_num_prefix equipment_prefix,
          wtp.vehicle_number equipment_number,
          wts.departure_seal_code equipment_seal,
          wtp.carrier_id carrier_name_int    --, wc.scac_code carrier_name_int
                                         ,
          wts.stop_location_id pick_up_locaion_id,
          wts.stop_id pick_up_stop_id,
          wts2.stop_location_id drop_off_location_id,
          wts2.stop_id drop_off_stop_id,
          wts.departure_gross_weight departure_gross_weight,
          wts.weight_uom_code departure_gross_weight_uom_int,
          wts.departure_net_weight departure_net_weight,
          wts.weight_uom_code departure_net_weight_uom_int,
          (wts.departure_gross_weight - wts.departure_net_weight)
             departure_tare_weight,
          wts.weight_uom_code departure_tare_weight_uom_int,
          wts.departure_volume departure_volume,
          wts.volume_uom_code departure_volume_uom_int,
          SUBSTR (wtp.routing_instructions, 0, 400) routing_instructions1,
          SUBSTR (wtp.routing_instructions, 401, 400) routing_instructions2,
          SUBSTR (wtp.routing_instructions, 801, 400) routing_instructions3,
          SUBSTR (wtp.routing_instructions, 1201, 400) routing_instructions4,
          SUBSTR (wtp.routing_instructions, 1601, 400) routing_instructions5,
          wnd.initial_pickup_location_id warehouse_location_id,
          mtp.organization_code warehouse_code_int    -- Inv Organization Code
                                                  ,
          hrl.ece_tp_location_code warehouse_edi_loc_code,
          hou.NAME warehouse_name,
          wshl.address1 warehouse_address1,
          wshl.address2 warehouse_address2,
          wshl.address3 warehouse_address3,
          wshl.city warehouse_city,
          wshl.postal_code warehouse_postal_code,
          wshl.country warehouse_country_int,
          wshl.county warehouse_region1_int,
          wshl.state warehouse_region2_int,
          hrl.region_3 warehouse_region3_int,
          hrl.telephone_number_1 warehouse_telephone_1,
          hrl.telephone_number_2 warehouse_telephone_2,
          hrl.telephone_number_3 warehouse_telephone_3,
          delivery_addr.deliver_to_org_id delivery_address_id,
          delivery_addr.location_id delivery_code_int -- , hcas.ece_tp_location_code delivery_edi_loc_code ----Commented as per DCR#100912
                                                     ,
          hcas.attribute5 delivery_edi_loc_code    --- Added as per DCR#100912
                                               ,
          SUBSTRB (delivery_addr.delivery_party, 1, 50) delivery_cust_name,
          delivery_addr.address1 delivery_address1,
          delivery_addr.address2 delivery_address2,
          delivery_addr.address3 delivery_address3,
          delivery_addr.address4 delivery_address4,
          delivery_addr.city delivery_city,
          delivery_addr.postal_code delivery_postal_code,
          delivery_addr.country delivery_country_int,
          delivery_addr.state delivery_state_int,
          delivery_addr.province delivery_province_int,
          delivery_addr.county delivery_county,
          wsh_ece_views_def.get_cust_area_code (cust_acct1.cust_account_id)
             delivery_area_code,
          wsh_ece_views_def.get_cust_phone_number delivery_telephone,
          hcas.cust_acct_site_id destination_address_id,
          wnd.customer_id destination_customer_id,
          hcsu.site_use_id destination_site_use_id,
          hcsu.LOCATION destination_code_int --, hcas.ece_tp_location_code destination_edi_loc_code ----Commented as per DCR#100912
                                            ,
          hcas.attribute5 destination_edi_loc_code --- Added as per DCR#100912
                                                  ,
          SUBSTRB (party1.party_name, 1, 50) destination_name,
          wshl2.address1 destination_address1,
          wshl2.address2 destination_address2,
          wshl2.address3 destination_address3,
          wshl2.address4 destination_address4,
          wshl2.city destination_city,
          wshl2.postal_code destination_postal_code,
          wshl2.country destination_country_int,
          wshl2.state destination_state_int,
          wshl2.province destination_province_int,
          wshl2.county destination_county,
          wsh_ece_views_def.get_cont_area_code (hcsu.contact_id)
             destination_area_code,
          wsh_ece_views_def.get_cont_phone_number destination_telephone,
          wnd.delivery_id shipper_number,
          wnd.waybill waybill_number,
          wdi.sequence_number bill_of_lading,
          wdoc.sequence_number packing_slip_number,
          wts.actual_departure_date actual_ship_date,
          wnd.gross_weight delivery_gross_weight,
          wnd.weight_uom_code delivery_gross_weight_uom_int,
          wnd.volume delivery_volume,
          wnd.volume_uom_code delivery_volume_uom_int,
          wnd.net_weight delivery_net_weight,
          wnd.weight_uom_code delivery_net_weight_uom_int,
          (wnd.gross_weight - wnd.net_weight) delivery_tare_weight,
          wnd.weight_uom_code delivery_tare_weight_uom_int,
          wts2.planned_arrival_date expected_arrival_date,
          wnd.freight_terms_code freight_terms_code_int,
          wnd.number_of_lpn number_of_lpn --, wnd.ship_method_code ship_method_code_int
                                    --, wnd.service_level ship_method_code_int
          ,
          wc.scac_code ship_method_code_int,
          wnd.fob_code fob_point_code_int,
          wnd.fob_location_id fob_location_id,
          wnd.pooled_ship_to_location_id pooled_ship_to_location_id,
          NVL (wnd.intmed_ship_to_location_id,
               wnd.ultimate_dropoff_location_id)
             intmed_ship_to_location_id,
          wtp.vehicle_organization_id vehicle_organization_id,
          wtp.vehicle_item_id vehicle_item_id,
          hcsu.contact_id contact_id --, wcs.ship_method_meaning ship_method_name_int
                                    ,
          (SELECT meaning
             FROM wsh_lookups
            WHERE     lookup_type = 'WSH_SERVICE_LEVELS'
                  AND lookup_code = wnd.service_level)
             ship_method_name_int,
          del_org_id.name order_source                        -- Added for GHX
     FROM wsh_trip_stops wts,
          wsh_trips wtp,
          wsh_trip_stops wts2,
          wsh_delivery_legs wdl,
          wsh_new_deliveries wnd,
          wsh_locations wshl,
          wsh_locations wshl2,
          hr_locations_all hrl,
          hr_organization_units hou,
          mtl_parameters mtp,
          wsh_document_instances wdoc,
          wsh_document_instances wdi,
          hz_party_sites hps,
          hz_cust_acct_sites_all hcas,
          hz_cust_site_uses_all hcsu,
          hz_cust_accounts cust_acct1,
          hz_parties party1,
          wsh_carrier_services wcs,
          wsh_carriers wc,
          (SELECT loc.country,
                  loc.province,
                  loc.county,
                  loc.postal_code,
                  loc.state,
                  loc.city,
                  loc.address4,
                  loc.address3,
                  loc.address2,
                  loc.address1,
                  loc.location_id,
                  NVL (
                     (SELECT hp1.party_name
                        FROM hz_parties hp1,
                             hz_party_sites hps,
                             hz_party_relationship_v hpr
                       WHERE     hp1.party_id = hps.party_id
                             AND hp1.party_type = 'PERSON'
                             AND hps.location_id = loc.location_id
                             AND hpr.object_id = hp.party_id
                             AND hpr.subject_id = hp1.party_id
                             AND hpr.relationship_type_code = 'CONTACT_OF'
                             AND hpr.subject_party_type = 'PERSON'
                             AND ROWNUM < 2) -- Added to restrict data when there is duplicate Contact Persons
                                            ,
                     SUBSTR (hp.party_name, 1, 50))
                     delivery_party,
                  hcsu.site_use_id deliver_to_org_id
             FROM hz_locations loc,
                  hz_cust_site_uses_all hcsu,
                  hz_cust_acct_sites_all hcas,
                  hz_party_sites hps,
                  hz_parties hp,
                  hz_cust_acct_sites_all ra1,
                  hz_cust_accounts rc1
            WHERE     loc.location_id = hps.location_id
                  AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                  AND hcas.party_site_id = hps.party_site_id
                  AND hp.party_id = rc1.party_id
                  AND ra1.cust_acct_site_id = hcsu.cust_acct_site_id
                  AND rc1.cust_account_id = ra1.cust_account_id
                  AND ra1.party_site_id = hps.party_site_id) delivery_addr,
          (SELECT DISTINCT ool.deliver_to_org_id, ool.header_id, oos.name
             FROM oe_order_lines_all ool,
                  oe_order_headers_all ooh,
                  oe_order_sources oos
            WHERE     ool.header_id = ooh.header_id
                  AND oos.order_source_id = ooh.order_source_id) del_org_id -- Query Modified for GHX to include Order Source
    WHERE     wnd.initial_pickup_location_id = wshl.wsh_location_id
          AND wshl.source_location_id = hrl.location_id
          AND wshl.location_source_code = 'HR'
          AND hou.organization_id = wnd.organization_id
          AND hou.organization_id = mtp.organization_id
          AND wtp.trip_id = wts.trip_id
          AND wtp.trip_id = wts2.trip_id
          AND wts.trip_id = wts2.trip_id
          AND wnd.ultimate_dropoff_location_id = wts2.stop_location_id
          AND wnd.ultimate_dropoff_location_id = wshl2.wsh_location_id
          AND wshl2.location_source_code = 'HZ'
          AND wshl2.source_location_id = hps.location_id
          AND hps.party_site_id = hcas.party_site_id
          AND cust_acct1.cust_account_id = hcas.cust_account_id
          AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
          AND (   hcas.org_id IS NULL
               OR hcas.org_id IN
                     (  SELECT FIRST_VALUE (wdd.org_id)
                                  OVER (ORDER BY COUNT (wdd.org_id) DESC)
                                  AS org_id
                          FROM wsh_delivery_assignments_v wda,
                               wsh_delivery_details wdd
                         WHERE     wdd.delivery_detail_id =
                                      wda.delivery_detail_id
                               AND wda.delivery_id = wnd.delivery_id
                               AND wdd.container_flag = 'N'
                      GROUP BY org_id))
          AND NVL (hcas.org_id, -999) = NVL (hcsu.org_id, -999)
          AND hcsu.site_use_code = 'SHIP_TO'
          AND hcsu.status = 'A'
          AND cust_acct1.status = 'A'
          AND wcs.ship_method_code(+) = wnd.ship_method_code
          AND wc.carrier_id(+) = wcs.carrier_id
          AND wnd.delivery_id = wdl.delivery_id
          AND wnd.delivery_id = wdoc.entity_id(+)
          AND wdoc.entity_name(+) = 'WSH_NEW_DELIVERIES'
          AND wdoc.document_type(+) = 'PACK_TYPE'
          AND wts2.stop_id = wdl.drop_off_stop_id
          AND wdl.pick_up_stop_id = wts.stop_id
          AND wdl.delivery_leg_id = wdi.entity_id(+)
          AND wdi.entity_name(+) = 'WSH_DELIVERY_LEGS'
          AND wdi.status(+) <> 'CANCELLED'
          AND hps.party_id = cust_acct1.party_id
          AND cust_acct1.party_id = party1.party_id
          AND NVL (wnd.shipment_direction, 'O') IN ('O', 'IO')
          AND wts2.stop_location_id = hps.location_id
          AND wnd.delivery_type = 'STANDARD'
          AND del_org_id.header_id(+) =
                 xx_wsh_publish_asn_pkg.xx_source_header_id (wnd.delivery_id) -- changed for wave1 since one delivery can have multiple lines -- wnd.source_header_id
          AND delivery_addr.deliver_to_org_id(+) =
                 del_org_id.deliver_to_org_id;


GRANT SELECT ON APPS.XX_WSH_DELIVERIES_WS_V TO XXAPPSREAD;
