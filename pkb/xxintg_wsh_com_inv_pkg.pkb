DROP PACKAGE BODY APPS.XXINTG_WSH_COM_INV_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_WSH_COM_INV_PKG" 
IS
/*$Header: XXINTGWSHCOMINVRPT.pkb 1.0.0 2013/04/08 00:00:00 partha ibm $ */

/**********************************************************************************/
/*                    P A C K A G E   BODY                             */
/***********************************************************************/
/* ======================================================================
    P A C K A G E   D E F I N I T I O N
   ======================================================================
    Description : Package Body for calling report according to output format
   ======================================================================
   T A B L E S    I M P A C T S
   ======================================================================
   Tables     :
   ======================================================================
   P A C K A G E   H I S T O R Y
   ======================================================================
  Date            Name                 Version  Remarks
-------------     ----------------     -------- -------------
  08-Apr-2013     Ibm Developer           1.0      Initial version
/*================================================================================*/
/**********************************************************************************/


-- =====================================================================
-- P R O C E D U R E  submit_conc_prog
-- =====================================================================
-- Description : main procedure for calling report program
-- =====================================================================
-- I N P U T
-- =====================================================================
--     Name            Description
-- =====================================================================

--     P_TRIP_STOP_ID           Trip Stop
--     P_DEPARTURE_DATE_LOW	Departure Date (Low)
--     P_DEPARTURE_DATE_HIGH    Departure Date (High)
--     P_FREIGHT_CODE   	Freight Carrier
--     P_ORGANIZATION_ID	Warehouse
--     P_DELIVERY_ID    	Delivery Name
--     P_ITEM_DISPLAY   	Item Display
--     P_ITEM_FLEX_CODE  	Item Flex Code
--     P_CURRENCY_CODE   	Currency Code
--     P_PRINT_CUST_ITEM        Print Customer Item
--     P_VALUE_SET_NAME  	Value Set Name
--     P_CONTEXT_VALUE		Context Value
--     P_PROFILE_OPTION   	Master Organization


   PROCEDURE submit_conc_prog (
      errbuf			          OUT	NOCOPY	VARCHAR2
    , retcode			          OUT	NOCOPY	NUMBER
    , P_TRIP_STOP_ID		    IN		NUMBER
    , P_DEPARTURE_DATE_LOW  IN    DATE
    , P_DEPARTURE_DATE_HIGH	IN		DATE
    , P_FREIGHT_CODE		    IN		VARCHAR2
    , P_ORGANIZATION_ID	    IN		NUMBER
    , P_DELIVERY_ID		      IN		NUMBER
    , P_ITEM_DISPLAY		    IN		VARCHAR2
    , P_ITEM_FLEX_CODE      IN		VARCHAR2
    , P_CURRENCY_CODE    	  IN		VARCHAR2
    , P_PRINT_CUST_ITEM     IN    VARCHAR2
    , P_VALUE_SET_NAME   	  IN		VARCHAR2
    , P_CONTEXT_VALUE		    IN		VARCHAR2
    , P_PROFILE_OPTION		  IN		VARCHAR2
    , P_VALUE_SET_NAME2     IN		VARCHAR2
    , P_FORMAT			        IN		VARCHAR2
   )
   IS
      l_request_id          NUMBER;
      l_set_layout_option   BOOLEAN;
   BEGIN
     -- fnd_file.put_line (fnd_file.LOG, 'Running');

      IF p_format = 'EXCEL'
      THEN
         -- Set the xml template for excel output
         l_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => 'XXINTG'
                                  , template_code           => 'XXINTGWSHCOMINVREPTEXCEL'
                                  , template_language       => 'en'
                                  , template_territory      => 'US'
                                  , output_format           => 'EXCEL'
                                   );
     fnd_file.put_line (fnd_file.LOG, 'Running for excel');
      ELSIF p_format = 'PDF'
      THEN
         -- Set the xml template for pdf output
         l_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => 'XXINTG'
                                  , template_code           => 'XXINTGWSHCOMINVREPL'
                                  , template_language       => 'en'
                                  , template_territory      => 'US'
                                  , output_format           => 'PDF'
                                   );
     fnd_file.put_line (fnd_file.LOG, 'Running for pdf');
      END IF;

      IF (l_set_layout_option) THEN
         fnd_file.put_line
                       (fnd_file.LOG
                      ,    'Layout Set for INTG Commercial Invoice in PDF/Excel Format  :  '
                       );

      END IF;

fnd_file.put_line(fnd_file.LOG, 'P_TRIP_STOP_ID:' || P_TRIP_STOP_ID);
fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_LOW:' || P_DEPARTURE_DATE_LOW);
fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_HIGH:' || P_DEPARTURE_DATE_HIGH);
fnd_file.put_line(fnd_file.LOG, 'P_FREIGHT_CODE:' || P_FREIGHT_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_ORGANIZATION_ID:' || P_ORGANIZATION_ID);
fnd_file.put_line(fnd_file.LOG, 'P_DELIVERY_ID:' || P_DELIVERY_ID);
fnd_file.put_line(fnd_file.LOG, 'P_ITEM_DISPLAY:' || P_ITEM_DISPLAY);
fnd_file.put_line(fnd_file.LOG, 'P_ITEM_FLEX_CODE:' || P_ITEM_FLEX_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_CURRENCY_CODE:' || P_CURRENCY_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_PRINT_CUST_ITEM:' || P_PRINT_CUST_ITEM);
fnd_file.put_line(fnd_file.LOG, 'P_VALUE_SET_NAME:' || P_VALUE_SET_NAME);
fnd_file.put_line(fnd_file.LOG, 'P_VALUE_SET_NAME2:' || P_VALUE_SET_NAME2);
fnd_file.put_line(fnd_file.LOG, 'P_CONTEXT_VALUE:' || P_CONTEXT_VALUE);
fnd_file.put_line(fnd_file.LOG, 'P_PROFILE_OPTION:' || P_PROFILE_OPTION);
fnd_file.put_line(fnd_file.LOG, 'P_FORMAT:' || P_FORMAT);

	 -- Submit the Concurrent Program
      l_request_id :=
            fnd_request.submit_request (application => 'XXINTG'
                                      , program => 'XXINTGWSHCOMINV'
                                      , description => NULL
                                      , start_time => NULL
                                      , sub_request => FALSE
                                      , argument1 => P_TRIP_STOP_ID
                                      , argument2 => P_DEPARTURE_DATE_LOW
                                      , argument3 => P_DEPARTURE_DATE_HIGH
                                      , argument4 => P_FREIGHT_CODE
                                      , argument5 => P_ORGANIZATION_ID
                                      , argument6 => P_DELIVERY_ID
                                      , argument7 => P_ITEM_DISPLAY
                                      , argument8 => P_ITEM_FLEX_CODE
                                      , argument9 => P_CURRENCY_CODE
                                      , argument10 => P_PRINT_CUST_ITEM
                                      , argument11 => P_VALUE_SET_NAME
                                      , argument12 => P_CONTEXT_VALUE
                                      , argument13 => P_PROFILE_OPTION
                                      , argument14 => P_VALUE_SET_NAME2
                                       );
      COMMIT;

      fnd_file.put_line
                       (fnd_file.LOG
                      ,    'INTG Commercial Invoice in PDF/Excel Format  :  '
                        || l_request_id
                       );

   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected error when running INTG Commercial Invoice :' || SQLERRM);
   END submit_conc_prog;

   PROCEDURE submit_conc_prog_exp (
      errbuf			          OUT	NOCOPY	VARCHAR2
    , retcode			          OUT	NOCOPY	NUMBER
    , P_TRIP_STOP_ID		    IN		NUMBER
    , P_DEPARTURE_DATE_LOW  IN    DATE
    , P_DEPARTURE_DATE_HIGH	IN		DATE
    , P_FREIGHT_CODE		    IN		VARCHAR2
    , P_ORGANIZATION_ID	    IN		NUMBER
    , P_DELIVERY_ID		      IN		NUMBER
    , P_ITEM_DISPLAY		    IN		VARCHAR2
    , P_ITEM_FLEX_CODE      IN		VARCHAR2
    , P_CURRENCY_CODE    	  IN		VARCHAR2
    , P_PRINT_CUST_ITEM     IN    VARCHAR2
    , P_VALUE_SET_NAME   	  IN		VARCHAR2
    , P_CONTEXT_VALUE		    IN		VARCHAR2
    , P_PROFILE_OPTION		  IN		VARCHAR2
    , P_VALUE_SET_NAME2     IN		VARCHAR2
    , P_FORMAT			        IN		VARCHAR2
   )
   IS
      l_request_id          NUMBER;
      l_set_layout_option   BOOLEAN;
   BEGIN
     -- fnd_file.put_line (fnd_file.LOG, 'Running');

      IF p_format = 'EXCEL'
      THEN
         -- Set the xml template for excel output
         l_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => 'XXINTG'
                                  , template_code           => 'XXINTGWSHEXPCOMINVREPLEX'
                                  , template_language       => 'en'
                                  , template_territory      => 'US'
                                  , output_format           => 'EXCEL'
                                   );
     fnd_file.put_line (fnd_file.LOG, 'Running for excel');
      ELSIF p_format = 'PDF'
      THEN
         -- Set the xml template for pdf output
         l_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => 'XXINTG'
                                  , template_code           => 'XXINTGWSHEXPCOMINVREPL'
                                  , template_language       => 'en'
                                  , template_territory      => 'US'
                                  , output_format           => 'PDF'
                                   );
     fnd_file.put_line (fnd_file.LOG, 'Running for pdf');
      END IF;

      IF (l_set_layout_option) THEN
         fnd_file.put_line
                       (fnd_file.LOG
                      ,    'Layout Set for INTG Exp Commercial Invoice in PDF/Excel Format  :  '
                       );

      END IF;

fnd_file.put_line(fnd_file.LOG, 'P_TRIP_STOP_ID:' || P_TRIP_STOP_ID);
fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_LOW:' || P_DEPARTURE_DATE_LOW);
fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_HIGH:' || P_DEPARTURE_DATE_HIGH);
fnd_file.put_line(fnd_file.LOG, 'P_FREIGHT_CODE:' || P_FREIGHT_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_ORGANIZATION_ID:' || P_ORGANIZATION_ID);
fnd_file.put_line(fnd_file.LOG, 'P_DELIVERY_ID:' || P_DELIVERY_ID);
fnd_file.put_line(fnd_file.LOG, 'P_ITEM_DISPLAY:' || P_ITEM_DISPLAY);
fnd_file.put_line(fnd_file.LOG, 'P_ITEM_FLEX_CODE:' || P_ITEM_FLEX_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_CURRENCY_CODE:' || P_CURRENCY_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_PRINT_CUST_ITEM:' || P_PRINT_CUST_ITEM);
fnd_file.put_line(fnd_file.LOG, 'P_VALUE_SET_NAME:' || P_VALUE_SET_NAME);
fnd_file.put_line(fnd_file.LOG, 'P_CONTEXT_VALUE:' || P_CONTEXT_VALUE);
fnd_file.put_line(fnd_file.LOG, 'P_PROFILE_OPTION:' || P_PROFILE_OPTION);
fnd_file.put_line(fnd_file.LOG, 'P_FORMAT:' || P_FORMAT);

	 -- Submit the Concurrent Program
      l_request_id :=
            fnd_request.submit_request (application => 'XXINTG'
                                      , program => 'XXINTGWSHEXPCOMINV'
                                      , description => NULL
                                      , start_time => NULL
                                      , sub_request => FALSE
                                      , argument1 => P_TRIP_STOP_ID
                                      , argument2 => P_DEPARTURE_DATE_LOW
                                      , argument3 => P_DEPARTURE_DATE_HIGH
                                      , argument4 => P_FREIGHT_CODE
                                      , argument5 => P_ORGANIZATION_ID
                                      , argument6 => P_DELIVERY_ID
                                      , argument7 => P_ITEM_DISPLAY
                                      , argument8 => P_ITEM_FLEX_CODE
                                      , argument9 => P_CURRENCY_CODE
                                      , argument10 => P_PRINT_CUST_ITEM
                                      , argument11 => P_VALUE_SET_NAME
                                      , argument12 => P_CONTEXT_VALUE
                                      , argument13 => P_PROFILE_OPTION
                                      , argument14 => P_VALUE_SET_NAME2
                                       );
      COMMIT;

      fnd_file.put_line
                       (fnd_file.LOG
                      ,    'INTG Exp Commercial Invoice in PDF/Excel Format  :  '
                        || l_request_id
                       );

   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected error when running INTG Exp Commercial Invoice :' || SQLERRM);
   END submit_conc_prog_exp;

   PROCEDURE submit_conc_prog_imp (
      errbuf			          OUT	NOCOPY	VARCHAR2
    , retcode			          OUT	NOCOPY	NUMBER
    , P_TRIP_STOP_ID		    IN		NUMBER
    , P_DEPARTURE_DATE_LOW  IN    DATE
    , P_DEPARTURE_DATE_HIGH	IN		DATE
    , P_FREIGHT_CODE		    IN		VARCHAR2
    , P_ORGANIZATION_ID	    IN		NUMBER
    , P_DELIVERY_ID		      IN		NUMBER
    , P_ITEM_DISPLAY		    IN		VARCHAR2
    , P_ITEM_FLEX_CODE      IN		VARCHAR2
    , P_CURRENCY_CODE    	  IN		VARCHAR2
    , P_PRINT_CUST_ITEM     IN    VARCHAR2
    , P_VALUE_SET_NAME   	  IN		VARCHAR2
    , P_CONTEXT_VALUE		    IN		VARCHAR2
    , P_PROFILE_OPTION		  IN		VARCHAR2
    , P_VALUE_SET_NAME2     IN		VARCHAR2
    , P_FORMAT			        IN		VARCHAR2
   )
   IS
      l_request_id          NUMBER;
      l_set_layout_option   BOOLEAN;
   BEGIN
     -- fnd_file.put_line (fnd_file.LOG, 'Running');

      IF p_format = 'EXCEL'
      THEN
         -- Set the xml template for excel output
         l_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => 'XXINTG'
                                  , template_code           => 'XXINTGWSHIMPCOMINVREPLEX'
                                  , template_language       => 'en'
                                  , template_territory      => 'US'
                                  , output_format           => 'EXCEL'
                                   );
     fnd_file.put_line (fnd_file.LOG, 'Running for excel');
      ELSIF p_format = 'PDF'
      THEN
         -- Set the xml template for pdf output
         l_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => 'XXINTG'
                                  , template_code           => 'XXINTGWSHIMPCOMINVREPL'
                                  , template_language       => 'en'
                                  , template_territory      => 'US'
                                  , output_format           => 'PDF'
                                   );
     fnd_file.put_line (fnd_file.LOG, 'Running for pdf');
      END IF;

      IF (l_set_layout_option) THEN
         fnd_file.put_line
                       (fnd_file.LOG
                      ,    'Layout Set for INTG Imp Commercial Invoice in PDF/Excel Format  :  '
                       );

      END IF;

fnd_file.put_line(fnd_file.LOG, 'P_TRIP_STOP_ID:' || P_TRIP_STOP_ID);
fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_LOW:' || P_DEPARTURE_DATE_LOW);
fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_HIGH:' || P_DEPARTURE_DATE_HIGH);
fnd_file.put_line(fnd_file.LOG, 'P_FREIGHT_CODE:' || P_FREIGHT_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_ORGANIZATION_ID:' || P_ORGANIZATION_ID);
fnd_file.put_line(fnd_file.LOG, 'P_DELIVERY_ID:' || P_DELIVERY_ID);
fnd_file.put_line(fnd_file.LOG, 'P_ITEM_DISPLAY:' || P_ITEM_DISPLAY);
fnd_file.put_line(fnd_file.LOG, 'P_ITEM_FLEX_CODE:' || P_ITEM_FLEX_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_CURRENCY_CODE:' || P_CURRENCY_CODE);
fnd_file.put_line(fnd_file.LOG, 'P_PRINT_CUST_ITEM:' || P_PRINT_CUST_ITEM);
fnd_file.put_line(fnd_file.LOG, 'P_VALUE_SET_NAME:' || P_VALUE_SET_NAME);
fnd_file.put_line(fnd_file.LOG, 'P_CONTEXT_VALUE:' || P_CONTEXT_VALUE);
fnd_file.put_line(fnd_file.LOG, 'P_PROFILE_OPTION:' || P_PROFILE_OPTION);
fnd_file.put_line(fnd_file.LOG, 'P_VALUE_SET_NAME2:' || P_VALUE_SET_NAME2);
fnd_file.put_line(fnd_file.LOG, 'P_FORMAT:' || P_FORMAT);

	 -- Submit the Concurrent Program
      l_request_id :=
            fnd_request.submit_request (application => 'XXINTG'
                                      , program => 'XXINTGWSHIMPCOMINV'
                                      , description => NULL
                                      , start_time => NULL
                                      , sub_request => FALSE
                                      , argument1 => P_TRIP_STOP_ID
                                      , argument2 => P_DEPARTURE_DATE_LOW
                                      , argument3 => P_DEPARTURE_DATE_HIGH
                                      , argument4 => P_FREIGHT_CODE
                                      , argument5 => P_ORGANIZATION_ID
                                      , argument6 => P_DELIVERY_ID
                                      , argument7 => P_ITEM_DISPLAY
                                      , argument8 => P_ITEM_FLEX_CODE
                                      , argument9 => P_CURRENCY_CODE
                                      , argument10 => P_PRINT_CUST_ITEM
                                      , argument11 => P_VALUE_SET_NAME
                                      , argument12 => P_CONTEXT_VALUE
                                      , argument13 => P_PROFILE_OPTION
                                      , argument14 => P_VALUE_SET_NAME2
                                       );
      COMMIT;

      fnd_file.put_line
                       (fnd_file.LOG
                      ,    'INTG Imp Commercial Invoice in PDF/Excel Format  :  '
                        || l_request_id
                       );

   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected error when running INTG Imp Commercial Invoice :' || SQLERRM);
   END submit_conc_prog_imp;
   --Added as per Wave2 to validate report submission for Shipping Document Sets
   FUNCTION check_rpt_ship_doc_set( p_delivery_id   IN    NUMBER
                                   ,p_header_id     OUT   NUMBER
                                   )
   RETURN VARCHAR2
   IS
      x_flag                VARCHAR2(10) := 'N';
      x_deliver_country     VARCHAR2(50);
      x_header_id           NUMBER       := NULL;
      x_ship_priority_code  VARCHAR2(50);
      x_delivery_id         NUMBER;
      x_from_country        VARCHAR2(50);
      x_to_country          VARCHAR2(50);
      x_country_of_origin   VARCHAR2(50);
   BEGIN
      --Get Delivery id
      BEGIN
         SELECT wnd.delivery_id
           INTO x_delivery_id
           FROM wsh_new_deliveries wnd
          WHERE nvl(wnd.shipment_direction, 'O') IN ('O', 'IO')
            AND wnd.delivery_type = 'STANDARD'
            AND wnd.delivery_id = P_DELIVERY_ID;
      EXCEPTION
         WHEN OTHERS THEN
         x_delivery_id := NULL;
      END;
      fnd_file.put_line (fnd_file.LOG, 'Delivery Id: '||x_delivery_id);
      --Get shipment_priority_code, header_id
      BEGIN
         SELECT ooh.shipment_priority_code, ooh.header_id
           INTO x_ship_priority_code, x_header_id
           FROM oe_order_headers_all ooh
               ,wsh_new_deliveries wsh
          WHERE ooh.header_id = wsh.source_header_id
            AND delivery_id = x_delivery_id;
      EXCEPTION
         WHEN OTHERS THEN
         BEGIN
            SELECT DISTINCT ooh.shipment_priority_code, ooh.header_id
              INTO x_ship_priority_code, x_header_id
              FROM oe_order_headers_all ooh,
                   wsh_delivery_details wdd,
                   wsh_delivery_assignments wds,
                   wsh_new_deliveries wnd
             WHERE ooh.header_id = wdd.source_header_id
               AND wds.delivery_detail_id=wdd.delivery_detail_id
               AND wds.delivery_id =wnd.delivery_id(+)
               AND wnd.delivery_id =  x_delivery_id;
         EXCEPTION
            WHEN OTHERS THEN
            x_ship_priority_code := NULL;
            x_header_id := NULL;
         END;
      END;
      fnd_file.put_line (fnd_file.LOG, 'Shipping Priority Code: '||x_ship_priority_code);
      --Get Deliver to country
      p_header_id := x_header_id;
      fnd_file.put_line (fnd_file.LOG, 'Order Header Id: '||p_header_id);
      BEGIN
         SELECT hl.country
           INTO x_deliver_country
           FROM oe_order_headers_all oe,
                hz_cust_site_uses_all su,
                hz_cust_acct_sites_all cs,
                hz_party_sites ps,
                hz_locations hl,
                hz_cust_accounts hc,
                hz_parties hp
          WHERE oe.header_id = x_header_id
            AND su.site_use_id = oe.deliver_to_org_id
            AND su.cust_acct_site_id = cs.cust_acct_site_id
            AND cs.party_site_id = ps.party_site_id
            AND ps.location_id = hl.location_id
            AND cs.cust_account_id = hc.cust_account_id
            AND hc.party_id = hp.party_id
            AND hp.party_id = ps.party_id;
      EXCEPTION
         WHEN OTHERS THEN
         x_deliver_country := NULL;
      END;
      fnd_file.put_line (fnd_file.LOG, 'Deliver to Country: '||x_deliver_country);
      BEGIN
         SELECT DISTINCT loc.country from_country
	       ,loc1.country to_country
	       ,loc.country country_of_origin
	   INTO x_from_country
	       ,x_to_country
	       ,x_country_of_origin
	   FROM wsh_delivery_assignments_v wda
	       ,wsh_delivery_details wdd
	       ,wsh_locations loc
	       ,wsh_locations loc1
	  WHERE 1=1
	    AND wdd.ship_to_location_id = loc1.wsh_location_id
	    AND wdd.ship_from_location_id = loc.wsh_location_id
	    AND wda.delivery_id is NOT NULL
	    AND wdd.delivery_detail_id = wda.delivery_detail_id
	    AND wdd.container_flag IN ('N', 'Y')
	    AND (wdd.requested_quantity > 0  OR  wdd.released_status != 'D')
            AND  wda.delivery_id = x_delivery_id;
      EXCEPTION
         WHEN OTHERS THEN
         x_from_country := NULL;
         x_to_country := NULL;
         x_country_of_origin := NULL;
      END;
      fnd_file.put_line (fnd_file.LOG, 'Ship From Country: '||x_from_country);
      fnd_file.put_line (fnd_file.LOG, 'Ship to Country: '||x_to_country);

      --Ship from country is different from ship to country
      IF x_from_country IS NOT NULL AND x_to_country IS NOT NULL THEN
         IF x_from_country <> x_to_country THEN
            x_flag := 'Y';
         END IF;
      END IF;

      --Ship from country is different from deliver to country
      IF x_from_country IS NOT NULL AND x_deliver_country IS NOT NULL THEN
         IF x_from_country <> x_deliver_country THEN
            x_flag := 'Y';
         END IF;
      END IF;

      IF NVL(x_ship_priority_code,'XXXX') IN ('INTR','INT') THEN
         x_flag := 'Y';
      END IF;

      IF x_flag = 'Y' THEN
         RETURN 'T';
      ELSE
         RETURN 'F';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected error when running INTG Exp Commercial Invoice Print Ship Doc Set:check_rpt_ship_doc_set :' || SQLERRM);
   END check_rpt_ship_doc_set;

   --Added as per Wave2 Program to add Shipping Document Sets
   PROCEDURE generate_rpt_ship_doc_set (
                                    errbuf                  OUT  NOCOPY  VARCHAR2
                                   ,retcode                 OUT  NOCOPY  NUMBER
                                   ,P_TRIP_STOP_ID          IN    NUMBER
                                   ,P_DEPARTURE_DATE_LOW    IN    DATE
                                   ,P_DEPARTURE_DATE_HIGH   IN    DATE
                                   ,P_FREIGHT_CODE          IN    VARCHAR2
                                   ,P_ORGANIZATION_ID       IN    NUMBER
                                   ,P_DELIVERY_ID           IN    NUMBER
                                   ,P_ITEM_DISPLAY          IN    VARCHAR2
                                   ,P_ITEM_FLEX_CODE        IN    VARCHAR2
                                   ,P_CURRENCY_CODE         IN    VARCHAR2
                                   ,P_PRINT_CUST_ITEM       IN    VARCHAR2
                                   ,P_VALUE_SET_NAME        IN    VARCHAR2
                                   ,P_CONTEXT_VALUE         IN    VARCHAR2
                                   ,P_PROFILE_OPTION        IN    VARCHAR2
                                   ,P_VALUE_SET_NAME2       IN    VARCHAR2
                                  )
   IS
      x_request_id          NUMBER;
      x_set_layout_option   BOOLEAN;
      x_run_flag            VARCHAR2(10) := 'F';
      x_header_id           NUMBER;
      x_conc_short_name  VARCHAR2(40) := 'XXWSHEXPCOMINVSDS';
      x_ou_name          VARCHAR2(240);
      x_tmpl_code        VARCHAR2(240);
      x_application      VARCHAR2(10) := 'XXINTG';
      x_ter              fnd_languages.iso_territory%TYPE := 'US';
      x_lang             fnd_languages.iso_language%TYPE := 'en';

      x_templ_none_exp   EXCEPTION;
      x_prog_run_exp     EXCEPTION;

   BEGIN
      fnd_file.put_line(fnd_file.LOG, 'P_TRIP_STOP_ID:' || P_TRIP_STOP_ID);
      fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_LOW:' || P_DEPARTURE_DATE_LOW);
      fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_HIGH:' || P_DEPARTURE_DATE_HIGH);
      fnd_file.put_line(fnd_file.LOG, 'P_FREIGHT_CODE:' || P_FREIGHT_CODE);
      fnd_file.put_line(fnd_file.LOG, 'P_ORGANIZATION_ID:' || P_ORGANIZATION_ID);
      fnd_file.put_line(fnd_file.LOG, 'P_DELIVERY_ID:' || P_DELIVERY_ID);
      fnd_file.put_line(fnd_file.LOG, 'P_ITEM_DISPLAY:' || P_ITEM_DISPLAY);
      fnd_file.put_line(fnd_file.LOG, 'P_ITEM_FLEX_CODE:' || P_ITEM_FLEX_CODE);
      fnd_file.put_line(fnd_file.LOG, 'P_CURRENCY_CODE:' || P_CURRENCY_CODE);
      fnd_file.put_line(fnd_file.LOG, 'P_PRINT_CUST_ITEM:' || P_PRINT_CUST_ITEM);
      fnd_file.put_line(fnd_file.LOG, 'P_VALUE_SET_NAME:' || P_VALUE_SET_NAME);
      fnd_file.put_line(fnd_file.LOG, 'P_CONTEXT_VALUE:' || P_CONTEXT_VALUE);
      fnd_file.put_line(fnd_file.LOG, 'P_PROFILE_OPTION:' || P_PROFILE_OPTION);

      fnd_file.put_line (fnd_file.LOG, 'Before Calling check_rpt_ship_doc_set x_run_flag: '||x_run_flag);
      x_run_flag := check_rpt_ship_doc_set(P_DELIVERY_ID, x_header_id);
      fnd_file.put_line (fnd_file.LOG, 'After Calling check_rpt_ship_doc_set x_run_flag: '||x_run_flag);

      IF x_run_flag = 'F' THEN
         RAISE x_prog_run_exp;
      END IF;

      --Fetch OU name Added as per Wave2
      IF x_header_id IS NOT NULL THEN
         BEGIN
            SELECT hou.name
              INTO x_ou_name
              FROM hr_operating_units hou
                  ,oe_order_headers_all ooh
             WHERE hou.organization_id = ooh.org_id
               AND ooh.header_id = x_header_id;
         EXCEPTION
            WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, 'Error while fetching OU name '|| SQLERRM);
            x_ou_name := 'OU United States';
         END;
      ELSE
         BEGIN
         SELECT hou.name
           INTO x_ou_name
	   FROM org_organization_definitions ood
	       ,hr_operating_units hou
	  WHERE hou.organization_id = ood.operating_unit
            AND ood.organization_id = P_ORGANIZATION_ID;
         EXCEPTION
            WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, 'Error while fetching OU name '|| SQLERRM);
            x_ou_name := 'OU United States';
         END;
      END IF;

      --Fetch template name
      x_tmpl_code := xx_intg_common_pkg.get_ou_specific_templ(x_ou_name,x_conc_short_name);
      fnd_file.put_line (fnd_file.LOG,'Template name '||x_tmpl_code);
      --If template defined as none raise exception
      IF UPPER(x_tmpl_code) = 'NONE' THEN
         RAISE x_templ_none_exp;
      END IF;

      IF x_tmpl_code IS NULL THEN
         x_tmpl_code := 'XXINTGWSHEXPCOMINVREPL';
      END IF;

      -- Set the xml template for pdf output
      x_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => x_application
                                  , template_code           => x_tmpl_code
                                  , template_language       => x_lang
                                  , template_territory      => x_ter
                                  , output_format           => 'PDF'
                                   );


      IF (x_set_layout_option) THEN
         fnd_file.put_line
                       (fnd_file.LOG
                      ,    'Layout Set for INTG Exp Commercial Invoice Print Ship Doc Set'
                       );

      END IF;

      -- Submit the Concurrent Program
      x_request_id :=
            fnd_request.submit_request (application => x_application
                                      , program => 'XXINTGWSHEXPCOMINV'
                                      , description => NULL
                                      , start_time => NULL
                                      , sub_request => FALSE
                                      , argument1 => P_TRIP_STOP_ID
                                      , argument2 => P_DEPARTURE_DATE_LOW
                                      , argument3 => P_DEPARTURE_DATE_HIGH
                                      , argument4 => P_FREIGHT_CODE
                                      , argument5 => P_ORGANIZATION_ID
                                      , argument6 => P_DELIVERY_ID
                                      , argument7 => P_ITEM_DISPLAY
                                      , argument8 => P_ITEM_FLEX_CODE
                                      , argument9 => P_CURRENCY_CODE
                                      , argument10 => P_PRINT_CUST_ITEM
                                      , argument11 => P_VALUE_SET_NAME
                                      , argument12 => P_CONTEXT_VALUE
                                      , argument13 => P_PROFILE_OPTION
                                      , argument14 => P_VALUE_SET_NAME2
                                       );
      COMMIT;

      fnd_file.put_line
                       (fnd_file.LOG
                      ,    'INTG Exp Commercial Invoice Print Ship Doc Set  :  '
                        || x_request_id
                       );

   EXCEPTION
      WHEN x_prog_run_exp THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Validation criteria failed to run program for INTG Shipping Document');
            retcode := 1;
      WHEN x_templ_none_exp THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Template Code is None for '||x_ou_name);
            retcode := 1;
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected error when running INTG Exp Commercial Invoice Print Ship Doc Set :' || SQLERRM);
         retcode := 2;
   END generate_rpt_ship_doc_set;
   --Added as per Wave2 for Org Specific templates
   PROCEDURE generate_exp_rpt (
                                errbuf               OUT  NOCOPY  VARCHAR2
                               ,retcode              OUT  NOCOPY  NUMBER
                               ,P_TRIP_STOP_ID        IN  NUMBER
                               ,P_DEPARTURE_DATE_LOW  IN  DATE
                               ,P_DEPARTURE_DATE_HIGH IN  DATE
                               ,P_FREIGHT_CODE        IN  VARCHAR2
                               ,P_ORGANIZATION_ID     IN  NUMBER
                               ,P_DELIVERY_ID         IN  NUMBER
                               ,P_ITEM_DISPLAY        IN  VARCHAR2
                               ,P_ITEM_FLEX_CODE      IN  VARCHAR2
                               ,P_CURRENCY_CODE       IN  VARCHAR2
                               ,P_PRINT_CUST_ITEM     IN  VARCHAR2
                               ,P_VALUE_SET_NAME      IN  VARCHAR2
                               ,P_CONTEXT_VALUE       IN  VARCHAR2
                               ,P_PROFILE_OPTION      IN  VARCHAR2
                               ,P_VALUE_SET_NAME2     IN  VARCHAR2
                              )
   IS
      x_request_id          NUMBER;
      x_set_layout_option   BOOLEAN;
      x_conc_short_name     VARCHAR2(40) := 'XXWSHEXPCOMINVSDS';
      x_ou_name             VARCHAR2(240);
      x_tmpl_code           VARCHAR2(240);
      x_application         VARCHAR2(10) := 'XXINTG';
      x_ter                 fnd_languages.iso_territory%TYPE := 'US';
      x_lang                fnd_languages.iso_language%TYPE := 'en';
      x_header_id           NUMBER;

      x_templ_none_exp   EXCEPTION;

   BEGIN

      fnd_file.put_line(fnd_file.LOG, 'P_TRIP_STOP_ID:' || P_TRIP_STOP_ID);
      fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_LOW:' || P_DEPARTURE_DATE_LOW);
      fnd_file.put_line(fnd_file.LOG, 'P_DEPARTURE_DATE_HIGH:' || P_DEPARTURE_DATE_HIGH);
      fnd_file.put_line(fnd_file.LOG, 'P_FREIGHT_CODE:' || P_FREIGHT_CODE);
      fnd_file.put_line(fnd_file.LOG, 'P_ORGANIZATION_ID:' || P_ORGANIZATION_ID);
      fnd_file.put_line(fnd_file.LOG, 'P_DELIVERY_ID:' || P_DELIVERY_ID);
      fnd_file.put_line(fnd_file.LOG, 'P_ITEM_DISPLAY:' || P_ITEM_DISPLAY);
      fnd_file.put_line(fnd_file.LOG, 'P_ITEM_FLEX_CODE:' || P_ITEM_FLEX_CODE);
      fnd_file.put_line(fnd_file.LOG, 'P_CURRENCY_CODE:' || P_CURRENCY_CODE);
      fnd_file.put_line(fnd_file.LOG, 'P_PRINT_CUST_ITEM:' || P_PRINT_CUST_ITEM);
      fnd_file.put_line(fnd_file.LOG, 'P_VALUE_SET_NAME:' || P_VALUE_SET_NAME);
      fnd_file.put_line(fnd_file.LOG, 'P_CONTEXT_VALUE:' || P_CONTEXT_VALUE);
      fnd_file.put_line(fnd_file.LOG, 'P_PROFILE_OPTION:' || P_PROFILE_OPTION);

      --Get Header Id
      BEGIN
         SELECT source_header_id
         INTO x_header_id
         FROM wsh_new_deliveries
         WHERE delivery_id = P_DELIVERY_ID;
      EXCEPTION
         WHEN OTHERS THEN
         x_header_id := null;
      END;
      --Fetch OU name Added as per Wave2
      IF x_header_id IS NOT NULL THEN
         BEGIN
            SELECT hou.name
              INTO x_ou_name
              FROM hr_operating_units hou
                  ,oe_order_headers_all ooh
             WHERE hou.organization_id = ooh.org_id
               AND ooh.header_id = x_header_id;
         EXCEPTION
            WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, 'Error while fetching OU name '|| SQLERRM);
            x_ou_name := 'OU United States';
         END;
      ELSE
         BEGIN
         SELECT hou.name
           INTO x_ou_name
	   FROM org_organization_definitions ood
	       ,hr_operating_units hou
	  WHERE hou.organization_id = ood.operating_unit
            AND ood.organization_id = P_ORGANIZATION_ID;
         EXCEPTION
            WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG, 'Error while fetching OU name '|| SQLERRM);
            x_ou_name := 'OU United States';
         END;
      END IF;

      --Fetch template name
      x_tmpl_code := xx_intg_common_pkg.get_ou_specific_templ(x_ou_name,x_conc_short_name);
      fnd_file.put_line (fnd_file.LOG,'Template name '||x_tmpl_code);
      --If template defined as none raise exception
      IF UPPER(x_tmpl_code) = 'NONE' THEN
         RAISE x_templ_none_exp;
      END IF;

      IF x_tmpl_code IS NULL THEN
         x_tmpl_code := 'XXINTGWSHEXPCOMINVREPL';
      END IF;

      -- Set the xml template for pdf output
      x_set_layout_option :=
            fnd_request.add_layout (template_appl_name      => x_application
                                  , template_code           => x_tmpl_code
                                  , template_language       => x_lang
                                  , template_territory      => x_ter
                                  , output_format           => 'PDF'
                                   );


      IF (x_set_layout_option) THEN
         fnd_file.put_line
                       (fnd_file.LOG
                      ,    'Layout Set for INTG Exp Commercial Invoice Print Program'
                       );
      END IF;

      -- Submit the Concurrent Program
      x_request_id :=
            fnd_request.submit_request (application => x_application
                                      , program     => 'XXINTGWSHEXPCOMINV'
                                      , description => NULL
                                      , start_time  => NULL
                                      , sub_request => FALSE
                                      , argument1   => P_TRIP_STOP_ID
                                      , argument2   => P_DEPARTURE_DATE_LOW
                                      , argument3   => P_DEPARTURE_DATE_HIGH
                                      , argument4   => P_FREIGHT_CODE
                                      , argument5   => P_ORGANIZATION_ID
                                      , argument6   => P_DELIVERY_ID
                                      , argument7   => P_ITEM_DISPLAY
                                      , argument8   => P_ITEM_FLEX_CODE
                                      , argument9   => P_CURRENCY_CODE
                                      , argument10  => P_PRINT_CUST_ITEM
                                      , argument11  => P_VALUE_SET_NAME
                                      , argument12  => P_CONTEXT_VALUE
                                      , argument13  => P_PROFILE_OPTION
                                      , argument14  => P_VALUE_SET_NAME2
                                       );
      COMMIT;

      fnd_file.put_line
                       (fnd_file.LOG
                      ,    'INTG Exp Commercial Invoice Print Program :  '
                        || x_request_id
                       );

   EXCEPTION
      WHEN x_templ_none_exp THEN
            fnd_file.put_line(fnd_file.log,'Template Code is None for '||x_ou_name);
            retcode := 1;
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log, 'Unexpected error when running INTG Exp Commercial Invoice Print Program :' || SQLERRM);
         retcode := 2;
   END generate_exp_rpt;

END xxintg_wsh_com_inv_pkg;
/
