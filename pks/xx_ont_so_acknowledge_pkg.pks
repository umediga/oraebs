DROP PACKAGE APPS.XX_ONT_SO_ACKNOWLEDGE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_SO_ACKNOWLEDGE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-APR-2012
 File Name     : XX_ONT_SO_ACKNOWLEDGE_PKG.pks
 Description   : This script creates the specification of the package
		 xx_ont_so_acknowledge_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-APR-2012 Sharath Babu        Initial Development
*/
----------------------------------------------------------------------

   FUNCTION send_so_ack_email ( p_subscription_guid   IN              RAW,
                                p_event               IN OUT NOCOPY   wf_event_t
                              )
   RETURN VARCHAR2;

END xx_ont_so_acknowledge_pkg;
/
