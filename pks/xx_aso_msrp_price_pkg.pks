DROP PACKAGE APPS.XX_ASO_MSRP_PRICE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ASO_MSRP_PRICE_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXASOMSRPUPD.pks 1.0 2012/03/22 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 23-Mar-2012
 File Name     : XXASOMSRPUPD.pks
 Description   : This script creates the specification of the package
                 xx_aso_msrp_price_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 23-Mar-2012  IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------
AS
-- Global Variable Declaration
   g_pl_mid_string  varchar2(100) := 'PL_MID_STRING';
   g_process_name   varchar2(100) := 'XXQOTMSRPEXT';
-- =================================================================================
-- Name           : XXASO_MSRP_PRC_UPD
-- Description    : This Function Will Invoked At Form Personalization Level
--                  This will return MSRP Price for the Item Entered in Quote Line.
--                  If there is no MSRP Price for the Item then It will Return Null
-- Parameters description       :
--
-- p_header_id    : Parameter To Store Quote Header ID (IN)
-- p_item_id      : Parameter To Store Item ID (IN)
-- ==============================================================================
FUNCTION XXASO_MSRP_PRC_UPD (p_header_id      NUMBER,
                             p_item_id        NUMBER
               	            ) RETURN VARCHAR2;
END xx_aso_msrp_price_pkg;
/
