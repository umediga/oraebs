DROP PACKAGE APPS.XX_AR_CUST_RELATE_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUST_RELATE_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 12-June-2013
File Name     : XXARCUSTRELVAL.pks
Description   : This script creates the specification of the package xx_ar_cust_relate_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
12-June-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------

-- Customer Relationship  Data-Validations
FUNCTION data_validations_rel
         (
         p_cnv_cust_rel_rec   IN OUT xx_ar_cust_relate_pkg.g_xx_ar_cust_rel_rec_type
         )
RETURN NUMBER;


END xx_ar_cust_relate_val_pkg;
/
