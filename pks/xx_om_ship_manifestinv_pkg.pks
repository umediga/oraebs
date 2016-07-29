DROP PACKAGE APPS.XX_OM_SHIP_MANIFESTINV_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_om_ship_manifestinv_pkg AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 16-May-2012
 File Name     : XX_OM_SHIP_MANIFESTOUT_INT.pks
 Description   : This script creates the specification of the package
                 xx_om_ship_manifest_pkg
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 16-May-2012   Renjith               Initial Version
 24-Jul-2013   Renjith               Added org, inv org and delay parameters
                                     for processing
*/
----------------------------------------------------------------------


   PROCEDURE error_report( p_errbuf            OUT   VARCHAR2
                          ,p_retcode           OUT   VARCHAR2
                          ,p_header_id         IN    NUMBER
                          ,p_delivery_id       IN    NUMBER
                          ,p_date_from         IN    VARCHAR2
                          ,p_date_to           IN    VARCHAR2
                          ,p_status            IN    VARCHAR2);


   PROCEDURE manifest_inreprocess( p_errbuf            OUT   VARCHAR2
                                  ,p_retcode           OUT   VARCHAR2
                                  ,p_org_id            IN    NUMBER
                                  ,p_organization      IN    NUMBER
                                  ,p_delay             IN    NUMBER
                                  ,p_restart_flag      IN    VARCHAR2
                                  ,p_dummy             IN    VARCHAR2
                                  ,p_header_id         IN    NUMBER
                                  ,p_delivery_id       IN    NUMBER
                                  ,p_date_from         IN    VARCHAR2
                                  ,p_date_to           IN    VARCHAR2);
PROCEDURE ship_confirm   ( p_organization_id     IN     NUMBER
                          ,p_delivery_name       IN     VARCHAR2
                          ,p_delivery_id         IN     NUMBER
                          ,x_return_status       OUT    VARCHAR2
                          ,x_error_msg           OUT    VARCHAR2);
END xx_om_ship_manifestinv_pkg;
/
