DROP PACKAGE APPS.XX_AR_CUSTOMER_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUSTOMER_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 14-May-2013
File Name     : XXARCUSTVAL.pks
Description   : This script creates the specification of the package XX_AR_CUSTOMER_VAL_PKG
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
14-May-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------

-- Customer Header Level Data-Validations
FUNCTION data_validations_cust
         (
         p_cnv_cust_rec   IN OUT xx_ar_customer_load_pkg.g_xx_ar_cust_rec_type
         )
RETURN NUMBER;


-- Address Level Data-Validations
FUNCTION data_validations_address
         (
         p_cnv_addr_rec   IN OUT xx_ar_customer_load_pkg.g_xx_ar_address_rec_type
         )
RETURN NUMBER;

--  Contact Level Data-Validations
FUNCTION data_validations_contact
         (
         p_cnv_cont_rec   IN OUT xx_ar_custcont_load_pkg.g_xx_ar_cust_cont_rec_type
         )
RETURN NUMBER;


END xx_ar_customer_val_pkg;
/
