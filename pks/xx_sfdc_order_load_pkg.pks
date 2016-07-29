DROP PACKAGE APPS.XX_SFDC_ORDER_LOAD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SFDC_ORDER_LOAD_PKG" authid current_user
AS
----------------------------------------------------------------------
/*
 Created By    : Vishal
 Creation Date : 19-MAY-2014
 File Name     : XX_SFDC_ORDER_LOAD_PKG.pks
 Description   : This script creates the specification of the package
		 xx_sfdc_order_load_pkg
 Change History:
 Date        Name          Remarks
 ----------- ------------- -----------------------------------
 19-MAY-2014 Vishal        Initial Development
*/
----------------------------------------------------------------------

PROCEDURE submit_order_details( x_return_status  OUT nocopy  VARCHAR2 ,
                                x_return_message OUT nocopy  VARCHAR2 );
END xx_sfdc_order_load_pkg;
/
