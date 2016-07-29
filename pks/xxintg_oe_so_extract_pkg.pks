DROP PACKAGE APPS.XXINTG_OE_SO_EXTRACT_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_OE_SO_EXTRACT_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXINTG_ORD_DETAIL.pks 1.0 2012/05/10 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 20-Mar-2014
 File Name     : XXINTG_ORD_DETAIL.pks
 Description   : This script creates the specification of the package
                 xxintg_ord_detail_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
20-Mar-2014   IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------
AS

   FUNCTION GET_MODIFIER_NUMBER (p_header_id IN NUMBER, p_line_id IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION GET_MODIFIER_NAME (p_header_id IN NUMBER, p_line_id IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION GET_HOLD_NAME (p_header_id IN NUMBER, p_line_id IN NUMBER)
      RETURN VARCHAR2;

END xxintg_oe_so_extract_pkg;
/
