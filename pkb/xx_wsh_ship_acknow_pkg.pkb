DROP PACKAGE BODY APPS.XX_WSH_SHIP_ACKNOW_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_WSH_SHIP_ACKNOW_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XXWSHACKNOWLEDGE.pks
 Description   : This script creates the specification of the package
                 xx_wsh_ship_acknow_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 11-Apr-2012 Renjith               Initial Version
 16-Apr-2013 Yogesh                Changes as per the new DCR to pass Delivery_id
 10-Jul-2013 Renjith               Changes as per Wave1
*/
----------------------------------------------------------------------
   FUNCTION launch_acknowledge( p_subscription_guid   IN              RAW
                               ,p_event               IN OUT NOCOPY   wf_event_t
                              ) RETURN VARCHAR2
   IS
      x_param_list         wf_parameter_list_t;
      x_param_name         VARCHAR2 (250);
      x_param_value        VARCHAR2 (250);
      x_header_id          NUMBER;
      x_trip_id            NUMBER;
      x_rel_status         VARCHAR2(1);

      x_application        VARCHAR2(10) := 'XXINTG';
      x_program_name       VARCHAR2(20) := 'XXONTSHIPPINGACKMAIN';
      x_program_desc       VARCHAR2(50) := 'INTG Shipping Acknowledgement Program';
      x_reqid              NUMBER;
      x_phase              VARCHAR2(80);
      x_status             VARCHAR2(80);
      x_devphase           VARCHAR2(80);
      x_devstatus          VARCHAR2(80);
      x_message            VARCHAR2(80);
      x_check              BOOLEAN;
      x_delivery_id        NUMBER;   -- Added as part of DCR
      x_order_number       NUMBER;
      x_sotype_name        VARCHAR2(240);
      x_exception_flag     VARCHAR2(1) := 'N';
      x_lookup_meaning     VARCHAR2(80);

   BEGIN
      x_param_list := p_event.getparameterlist;

      IF x_param_list IS NOT NULL THEN
         FOR i IN x_param_list.FIRST .. x_param_list.LAST
         LOOP
            x_param_name := x_param_list (i).getname;
            x_param_value := x_param_list (i).getvalue;

            IF (x_param_name = 'TRIP_ID') THEN
               x_trip_id := x_param_value;
            END IF;
         END LOOP;

         BEGIN
             SELECT  wdt.source_header_id,wdt.released_status,wda.delivery_id
               INTO  x_header_id,x_rel_status,x_delivery_id
               FROM  wsh_delivery_details wdt,
                     wsh_delivery_assignments wda
              WHERE  wda.delivery_detail_id = wdt.delivery_detail_id
                AND  ROWNUM = 1
                and wdt.source_header_id is not null -- Added by Vishal for bug
                AND  wda.delivery_id IN (SELECT  wdl.delivery_id
                                           FROM  wsh_trips wt
                                                ,wsh_trip_stops wts
                                                ,wsh_delivery_legs  wdl
                                          WHERE  wts.stop_id = wdl.pick_up_stop_id
                                            AND  wts.trip_id = wt.trip_id
                                            AND  wts.trip_id = x_trip_id);
         EXCEPTION
           WHEN OTHERS THEN
               x_header_id := NULL;
         END;

         BEGIN
            SELECT  ooh.order_number
                   ,typ.name
              INTO  x_order_number
                   ,x_sotype_name
              FROM  oe_order_headers_all ooh
                   ,oe_transaction_types_tl typ
             WHERE  ooh.order_type_id  = typ.transaction_type_id
               AND  typ.language = 'US'
               AND  ooh.header_id = x_header_id
               AND  ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS THEN
               x_order_number := NULL;
               x_sotype_name    := NULL;
         END;

         BEGIN
            SELECT  meaning
              INTO  x_lookup_meaning
              FROM  fnd_lookup_values_vl
             WHERE  lookup_type = 'XXOM_SHIP_ACK_EXCEPTIONS'
               AND  NVL(enabled_flag,'X')='Y'
               AND  meaning = x_sotype_name
               AND  SYSDATE BETWEEN NVL(start_date_active,SYSDATE) AND NVL(end_date_active,SYSDATE);
            x_exception_flag := 'Y';
         EXCEPTION
              WHEN OTHERS THEN
                x_exception_flag := 'N';
         END;

         IF x_header_id IS NOT NULL AND NVL(x_exception_flag,'N') <> 'Y' THEN
            --Submit request
            x_reqid := fnd_request.submit_request( application     => x_application
                                                  ,program         => x_program_name
                                                  ,description     => x_program_desc
                                                  ,start_time      => SYSDATE
                                                  ,sub_request     => FALSE
                                                  ,argument1       => x_header_id
                                                  ,argument2       => 'Y'
                                                  ,argument3       => NULL
                                                  ,argument4       => NULL
                                                  ,argument5       => 'Y'
                                                  ,argument6       => x_delivery_id
                                                 );
            COMMIT;
         END IF;

      END IF;
      RETURN 'SUCCESS';
   EXCEPTION
      WHEN OTHERS THEN
         RETURN 'ERROR';
   END;
-- --------------------------------------------------------------------- --
END xx_wsh_ship_acknow_pkg;
/
