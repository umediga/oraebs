DROP PACKAGE APPS.XX_MRP_FORECAST_INT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_MRP_FORECAST_INT_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XXMRPFORECASTINT.pks
 Description   : This script creates the specification of the package
                 xx_mrp_forecast_int_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 19-JAN-2012 Renjith               Initial Version
*/
----------------------------------------------------------------------
g_stage			            VARCHAR2(2000);

-- Interface Population
PROCEDURE main_prc( x_errbuf          OUT VARCHAR2
                   ,X_RETCODE         OUT VARCHAR2
                  -- ,p_load_method     IN  VARCHAR2
                 --  ,P_FILE_NAME       IN  VARCHAR2
                   ,p_designator      IN  VARCHAR2
                  );
-- Error Report
PROCEDURE error_report ( x_errbuf  OUT VARCHAR2
                        ,x_retcode OUT VARCHAR2
                        ,p_type    IN  VARCHAR2);

-- Forecast Purge
PROCEDURE forecast_purge ( x_errbuf       OUT  VARCHAR2
                          ,x_retcode      OUT  VARCHAR2
                          ,p_user_id    IN   NUMBER
                          ,p_designator IN   VARCHAR2
                          ,p_org_id     IN   NUMBER
                          ,p_item_id    IN   NUMBER);

END xx_mrp_forecast_int_pkg;
/
