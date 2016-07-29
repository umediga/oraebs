DROP PACKAGE APPS.XX_WIP_ITEM_REQUIREMENTS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_WIP_ITEM_REQUIREMENTS_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : Mou Mukherjee
 Creation Date  : 11-Sep-2012
 File Name      : xx_wip_item_requirements_pkg.pks
 Description    : This script creates the specification of the package xx_wip_item_requirements_pkg

Change History:

Version Date        Name		Remarks
------- --------- ------------		---------------------------------------
1.0     11-Sep-2012 Mou Mukherjee       Initial development.
*/
----------------------------------------------------------------------

PROCEDURE load_item_requirements       ( p_wip_entity_id IN NUMBER
                                        ,x_status        OUT VARCHAR2
					,x_msg           OUT VARCHAR2
			               );

END xx_wip_item_requirements_pkg;
/
