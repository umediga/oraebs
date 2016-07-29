DROP PACKAGE APPS.XX_OM_SHIP_OUT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_SHIP_OUT_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XX_OM_SHIP_OUT_PKG.pks
 Description   : This script creates the specification of the package
                 xx_om_ship_out_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 28-Feb-2013 Renjith               Initial Version
 14-Jun-2013 Renjith               Added get_proactive_flag
*/
----------------------------------------------------------------------

   FUNCTION get_fright_acc_no( p_tp_attribute1    IN VARCHAR2
                              ,p_site_use_id      IN NUMBER
                              ,p_ship_method_code IN VARCHAR2)
   RETURN VARCHAR2;

   FUNCTION get_proactive_flag( p_delivery_id   IN VARCHAR2)
   RETURN VARCHAR2;

   FUNCTION get_days_restrict( p_delivery_id   IN VARCHAR2)
   RETURN VARCHAR2;

END xx_om_ship_out_pkg;
/
