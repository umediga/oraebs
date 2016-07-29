DROP PACKAGE APPS.XXSS_SUPP_PERFORM_PKG;

CREATE OR REPLACE PACKAGE APPS.XXSS_SUPP_PERFORM_PKG
AS
/* *************************************************************************
     Package              : XXSS_SUPP_PERFORM_PKG
     Description          : This package is for SeaSpine Oracle Supplier Performance Report


     Change List:
     ------------
     Name            Date        Version  Description
     --------------  ----------- -------  ------------------------------
     Ravisankar Ram  28-Dec-2015  1.0      Initial Version
     Ravisankar Ram  02-Feb-2016  1.1      Additional Changes
***************************************************************************/
g_user_id        		NUMBER := nvl(FND_GLOBAL.USER_ID,-2);
g_retcode NUMBER;
g_errmsg  VARCHAR2(2000);


 PN_SUPPLIER_ID NUMBER;
 PD_END_DATE DATE;
 PD_START_DATE DATE;
 PN_ORGANIZATION_ID NUMBER;

 gc_supplier_name AP_SUPPLIERS.vendor_name%type;
 gc_org_code org_organization_definitions.organization_code%type;

 gc_request_id NUMBER := FND_GLOBAL.CONC_REQUEST_ID;

 FUNCTION beforeReport
 RETURN BOOLEAN;

 FUNCTION xx_get_next_workday (p_organization_id  IN NUMBER
                              ,p_from_date        IN DATE
                              ,P_delay_hours      IN NUMBER)
 RETURN DATE;

 FUNCTION is_lot_on_time ( pn_organization_id   IN NUMBER
                              ,pd_promised_date IN DATE
                              ,pd_need_by_date  IN DATE
                              ,pd_received_date IN DATE
) RETURN VARCHAR2;

FUNCTION is_lot_complete( pn_received_quantity   IN NUMBER
, pn_ordered_quantity IN NUMBER
)
RETURN VARCHAR2;

PROCEDURE  xx_populate_transactions(
  PN_SUPPLIER_ID IN NUMBER
, PN_ORGANIZATION_ID IN NUMBER
, PD_START_DATE IN DATE
, PD_END_DATE IN DATE
, xc_status OUT NOCOPY VARCHAR2
);

END XXSS_SUPP_PERFORM_PKG;
/
