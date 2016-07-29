DROP PACKAGE APPS.XX_INTG_QUOTE_LINE_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_intg_quote_line_pkg
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-JUL-2013
 File Name     : XXINTGQUOTELINE.pks
 Description   : This script creates the specification of the package
                 xx_intg_quote_line_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-JUL-2013 Sharath Babu          Initial development.
*/
----------------------------------------------------------------------

   FUNCTION create_quote_line_new
                                ( p_quote_num        IN  NUMBER,
                                  p_quote_name       IN  VARCHAR2,
                                  p_cust_name        IN  VARCHAR2,
                                  p_qline_item       IN  VARCHAR2,
                                  p_quantity         IN  NUMBER,
                                  p_selling_price    IN  NUMBER,
                                  p_discount         IN  NUMBER
                                )
   RETURN VARCHAR2;
END xx_intg_quote_line_pkg;
/
