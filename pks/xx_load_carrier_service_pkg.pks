DROP PACKAGE APPS.XX_LOAD_CARRIER_SERVICE_PKG;

CREATE OR REPLACE PACKAGE APPS.XX_LOAD_CARRIER_SERVICE_PKG IS
/*+=====================================================================================*
| Header: XX_LOAD_CARRIER_SERVICE_PKG.pks                                                    |
+=======================================================================================+
| NTTDATA Inc                                                                           |
|                                                                                       |
+=======================================================================================+
| DESCRIPTION                                                                           |
| This Package spec is used to load the data for Carriers and Services.                 |
|                                                                                       |
|                                                                                       |
| MODIFICATION HISTORY                                                                  |
| version     Date         Modified By             Remarks                              |
| 1.0         26-Feb-2015  Venkat Kumar S          File Creation                        |
+======================================================================================*/
PROCEDURE XX_LOAD_MAIN_PRC  (
                                errorbuf         OUT  VARCHAR2
                               ,retcode          OUT  NUMBER 
                               ,pc_freight_code      IN  VARCHAR2							   
                              );


END XX_LOAD_CARRIER_SERVICE_PKG;
/
