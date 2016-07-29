DROP PACKAGE APPS.XX_WMS_CAROUSEL_INBND_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_WMS_CAROUSEL_INBND_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : Yogesh
 Creation Date : 05-JUN-2012
 File Name     : xxwmscarinbndpkg.pks
 Description   : This script creates the specification of the package
		 xx_wms_carousel_inbnd_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-JUN-2012 Yogesh                Initial Development
*/
----------------------------------------------------------------------

FUNCTION carousel_inbd_task_load(  p_divertcode_user_id   IN      VARCHAR2
			          ,p_order_no             IN      NUMBER
			          ,p_carton_id            IN      VARCHAR2
			          ,p_item                 IN      VARCHAR2
              			  ,p_bin                  IN      VARCHAR2
              			  ,p_trx_quantity         IN      NUMBER
				  ,p_short                IN      NUMBER
				  ,p_lot                  IN      VARCHAR2
				  ,p_pick_id              IN      NUMBER
              			 )
RETURN VARCHAR2;
----------------------------------------------------------------------

END xx_wms_carousel_inbnd_pkg;
/
