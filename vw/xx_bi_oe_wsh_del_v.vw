DROP VIEW APPS.XX_BI_OE_WSH_DEL_V;

/* Formatted on 6/6/2016 4:59:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_WSH_DEL_V
(
   DELIVERY_NAME,
   DROP_OFF_STOP_LOCATION,
   LOADING_ORDER_FLAG,
   PICK_UP_STOP_LOCATION,
   SEQUENCE_NUMBER,
   VOLUME_UOM_CODE,
   WEIGHT_UOM_CODE,
   LOAD_TENDER_STATUS,
   VOLUME,
   NET_WEIGHT,
   GROSS_WEIGHT
)
AS
   SELECT wnd.NAME delivery_name,
          loc1.ui_location_code drop_off_stop_location,
          wdl.loading_order_flag,
          loc.ui_location_code pick_up_stop_location,
          wdl.sequence_number,
          wdl.volume_uom_code,
          wdl.weight_uom_code,
          DECODE (wdl.load_tender_status,
                  'A', 'Accepted',
                  'D', 'Retender',
                  'L', 'Tendered',
                  'N', 'Not Tendered',
                  'R', 'Rejected',
                  'X', 'Not Applicable',
                  NULL)
             AS Load_Tender_Status,
          wdl.VOLUME,
          wdl.NET_WEIGHT,
          wdl.GROSS_WEIGHT
     FROM wsh_delivery_legs wdl,
          wsh_new_deliveries wnd,
          wsh_trip_stops wts1,
          wsh_trip_stops wts2,
          wsh_locations loc,
          wsh_locations loc1
    WHERE     wnd.delivery_id = wdl.delivery_id
          AND wdl.pick_up_stop_id = wts1.stop_id
          AND wdl.drop_off_stop_id = wts2.stop_id
          AND wts1.stop_location_id = loc.wsh_location_id
          AND wts2.stop_location_id = loc1.wsh_location_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_WSH_DEL_V FOR APPS.XX_BI_OE_WSH_DEL_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_WSH_DEL_V FOR APPS.XX_BI_OE_WSH_DEL_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_WSH_DEL_V FOR APPS.XX_BI_OE_WSH_DEL_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_WSH_DEL_V FOR APPS.XX_BI_OE_WSH_DEL_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_WSH_DEL_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_WSH_DEL_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_WSH_DEL_V TO XXINTG;
