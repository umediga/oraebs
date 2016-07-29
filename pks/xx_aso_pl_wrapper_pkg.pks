DROP PACKAGE APPS.XX_ASO_PL_WRAPPER_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ASO_PL_WRAPPER_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By     : Partha
 Creation Date  : 24-JUL-2013
 File Name      : XXASOPRICELISTWRAP.pks
 Description    : This script creates the specification of the package xx_aso_modifier_wrapper_pkg


Change History:

Version Date          Name        Remarks
------- -----------   --------    -------------------------------
1.0     24-JUL-2013   Partha       Initial development.
*/
----------------------------------------------------------------------
   PROCEDURE crt_updt_pl_wrap (o_errbuf OUT VARCHAR2, o_retcode OUT VARCHAR2);
END xx_aso_pl_wrapper_pkg;
/
