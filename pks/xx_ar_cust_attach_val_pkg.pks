DROP PACKAGE APPS.XX_AR_CUST_ATTACH_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUST_ATTACH_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 17-June-2013
File Name     : XXARCUSTATTVAL.pks
Description   : This script creates the specification of the package xx_ar_cust_attach_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
17-June-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------

-- Customer Relationship  Data-Validations
FUNCTION data_validations_att
         (
         p_cnv_cust_att_rec   IN OUT xx_ar_cust_attach_pkg.g_xx_ar_cust_att_rec_type
         )
RETURN NUMBER;


END xx_ar_cust_attach_val_pkg;
/
