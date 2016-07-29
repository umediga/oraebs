DROP PACKAGE APPS.XXQP_PRICE_CONSTRUCT;

CREATE OR REPLACE PACKAGE APPS."XXQP_PRICE_CONSTRUCT" AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 07-NOV-2013
File Name     : XXQPPRCCONSTR.pkb
Description   : This script creates the package of the package XXQP_FREIGHT_CONFIG
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
07-NOV-2013  Debjani Roy           Initial Draft.
*/
----------------------------------------------------------------------
    FUNCTION XXINTG_ORD_TOTAL_CONST(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER;
    FUNCTION XXINTG_ORD_CONST_ITEM_PRC(xx_line_record IN oe_order_pub.g_line%type) RETURN NUMBER;
END XXQP_PRICE_CONSTRUCT;
/
