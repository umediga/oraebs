DROP PACKAGE APPS.XX_OM_LOT_EXT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_LOT_EXT_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 30-Jul-2013
 File Name     : XX_OM_LOT_EXT.pks
 Description   : This script creates the specification of the package
                 xx_om_lot_ext_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Jul-2013 Renjith               Initial Version
*/
----------------------------------------------------------------------

  PROCEDURE lot_extract( p_errbuf            OUT   VARCHAR2
                        ,p_retcode           OUT   VARCHAR2
                        ,p_organization_id   IN    NUMBER
                        ,p_date_from         IN    VARCHAR2
                        ,p_date_to           IN    VARCHAR2);

--PROCEDURE lot_extract;
END xx_om_lot_ext_pkg;
/
