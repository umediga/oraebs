DROP PACKAGE APPS.XX_P2M_MATREQREP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_P2M_MATREQREP_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 24-May-2013
 File Name     : xx_p2m_matreqrep_pkg.pks
 Description   : This script creates the specification of the package
                 xx_p2m_matreqrep_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 24-May-2013 Rajesh Kendhuli       Initial Version
*/
----------------------------------------------------------------------

PROCEDURE main_prc(p_org IN VARCHAR2
                  ,P_FORECAST_NAME IN VARCHAR2
                  ,p_shipto_org    IN VARCHAR2
                  ,x_error_code    OUT   NUMBER
                  ,x_error_msg     OUT   VARCHAR2);

end XX_P2M_MATREQREP_PKG;
/
