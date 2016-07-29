DROP PACKAGE APPS.XX_ASO_PRICE_ALERT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ASO_PRICE_ALERT_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXASOPRCALRT.pks 1.0 2012/05/10 12:00:00 dparida noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 10-May-2012
 File Name     : XXASOMSRPUPD.pks
 Description   : This script creates the specification of the package
                 xx_aso_price_alert_pkg
 Change History:
 Date         Name                   Remarks
 -----------  -------------          -----------------------------------
 10-May-2012  IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------
AS
-- Global Variable Declaration
-- =================================================================================
-- Name           : xx_aso_prc_alert
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will check the price protected flag at Price List DFF.
-- Parameters description       :
--
-- p_header_id     : Parameter To Store Quote Header ID (IN)
-- p_line_id       : Parameter To Store Quote Header ID (IN)
-- ==============================================================================
   FUNCTION xx_aso_prc_alert (p_header_id NUMBER, p_line_id NUMBER)
      RETURN VARCHAR2;

-- =================================================================================
-- Name           : xx_aso_org_pl_price
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will Fetch the List Price For The Item in Quote Line.
-- Parameters description       :
--
-- p_header_id     : Parameter To Store Quote Header ID (IN)
-- p_line_id       : Parameter To Store Quote Header ID (IN)
-- ==============================================================================
   FUNCTION xx_aso_org_pl_price (p_header_id NUMBER, p_line_id NUMBER)
      RETURN VARCHAR2;

-- =================================================================================
-- Name           : xx_aso_org_pl_percent
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will Fetch the List Percent For The Item in Quote Line.
-- Parameters description       :
--
-- p_header_id     : Parameter To Store Quote Header ID (IN)
-- p_line_id       : Parameter To Store Quote Header ID (IN)
-- ==============================================================================
   FUNCTION xx_aso_org_pl_percent (p_header_id NUMBER, p_line_id NUMBER)
      RETURN VARCHAR2;

-- =================================================================================
-- Name           : xx_aso_org_line_adj_prc
-- Description    : This Function Will Invoked From The HTML Quoting AM Class
--                  This will Calculate the Total Price For a Quote Line.
-- Parameters description       :
--
-- p_header_id     : Parameter To Store Quote Header ID (IN)
-- p_line_id       : Parameter To Store Quote Line ID (IN)
-- p_qty           : Parameter To Store Quote Line Qty (IN)
-- p_list_price    : Parameter To Store Quote Line List Price (IN)
-- ==============================================================================
   FUNCTION xx_aso_org_line_adj_prc (
      p_header_id   NUMBER,
      p_line_id     NUMBER,
      p_qty         VARCHAR2,
      p_list_price  VARCHAR2
   )
      RETURN VARCHAR2;
END xx_aso_price_alert_pkg;
/
