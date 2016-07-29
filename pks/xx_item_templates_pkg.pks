DROP PACKAGE APPS.XX_ITEM_TEMPLATES_PKG;

CREATE OR REPLACE PACKAGE APPS.XX_ITEM_TEMPLATES_PKG IS
/*+=====================================================================================*
| Header: XX_ITEM_TEMPLATES_PKG.pks                                                     |
+=======================================================================================+
| NTTDATA Inc                                                                           |
|                                                                                       |
+=======================================================================================+
| DESCRIPTION                                                                           |
| This Package spec is used to load the data for Item Templates.                        |
|                                                                                       |
|                                                                                       |
| MODIFICATION HISTORY                                                                  |
| version     Date         Modified By             Remarks                              |
| 1.0         05-Mar-2015  Venkat Kumar S          File Creation                        |
+======================================================================================*/
PROCEDURE XX_LOAD_MAIN_PRC  ( errorbuf         OUT  VARCHAR2
                            , retcode          OUT  NUMBER 
                            );


END XX_ITEM_TEMPLATES_PKG;
/
