DROP PACKAGE APPS.XXINTG_WSH_COM_INV_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_WSH_COM_INV_PKG" 
AUTHID CURRENT_USER IS
/*$Header: XXINTGWSHCOMINVRPT.pks 1.0.0 2013/04/08 00:00:00 partha ibm $ */

/**********************************************************************************/
/*                    P A C K A G E   BODY                             */
/***********************************************************************/
/* ======================================================================
    P A C K A G E   D E F I N I T I O N
   ======================================================================
    Description : Package specification for calling report according to output format
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
   );

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
   );

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
   );
   --INTG Exp Commercial Invoice Print Ship Doc Set
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
                                  );
   --INTG Exp Commercial Invoice Print Program
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
                              );

END xxintg_wsh_com_inv_pkg;
/
