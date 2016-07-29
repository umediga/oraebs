DROP PACKAGE APPS.XX_ASO_GROSS_MARGIN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ASO_GROSS_MARGIN_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXASOGROSSMARGIN.pks 1.0 2012/04/02 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 28-Apr-2012
 File Name     : XXASOGROSSMARGIN.pks
 Description   : This script creates the specification of the package
                 xx_aso_gross_margin_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 28-Apr-2012  IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------
AS
-- Global Variable Declaration
   g_cost_type      VARCHAR2 (100) := 'COST_TYPE';
   g_lookup_type    VARCHAR2 (100) := 'LOOKUP_TYPE';
   g_role_flag      VARCHAR2 (100) := 'ROLE_FLAG';
   g_process_name   VARCHAR2 (100) := 'XXOMGROSSMAREXT';

-- =================================================================================
-- Name           : xx_aso_grossmargin_line_calc
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will calculate the gross margin of the product and return
--                  the same to the AM Class.
-- Parameters description       :
--
-- p_quote_lnr_id  : Parameter To Store Quote Line ID (IN)
-- p_org_id        : Parameter To Org ID (IN)
-- p_quote_price   : Parameter To Store Unit Selling Price (IN)
-- ==============================================================================
   FUNCTION xx_aso_grossmargin_line_calc (
      p_quote_lnr_id   NUMBER,
      p_org_id         NUMBER,
      p_quote_price    NUMBER
   )
      RETURN VARCHAR2;

-- =================================================================================
-- Name           : xx_aso_grossmargin_role
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will Verify whether the login user is eligable to View the
--                  gross margin field in the quote form.
-- Parameters description       :
--
-- p_user_name   : Parameter To Store Log In User Name (IN)
-- ==============================================================================
   FUNCTION xx_aso_grossmargin_role (p_user_name VARCHAR2)
      RETURN VARCHAR2;

-- =================================================================================
-- Name           : xx_aso_grossmargin_header_calc
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will calculate the gross margin of all the product at line
--                  level and return the same to the AM Class.
-- Parameters description       :
--
-- p_quote_hdr_id  : Parameter To Store Quote Header ID (IN)
-- p_org_id        : Parameter To Org ID (IN)
-- ==============================================================================
   FUNCTION xx_aso_grossmargin_header_calc (
      p_quote_hdr_id   NUMBER,
      p_org_id         NUMBER
   )
      RETURN VARCHAR2;
END xx_aso_gross_margin_pkg;
/
