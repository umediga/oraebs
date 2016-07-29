DROP PACKAGE APPS.XX_WSH_SHIP_ACKNOW_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_WSH_SHIP_ACKNOW_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XXWSHACKNOWLEDGE.pks
 Description   : This script creates the specification of the package
                 xx_wsh_ship_acknow_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 11-Apr-2012 Renjith               Initial Version
*/
----------------------------------------------------------------------

   FUNCTION launch_acknowledge( p_subscription_guid   IN              RAW
                               ,p_event               IN OUT NOCOPY   wf_event_t
                              ) RETURN VARCHAR2;

END xx_wsh_ship_acknow_pkg;
/
