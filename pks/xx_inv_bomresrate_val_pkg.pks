DROP PACKAGE APPS.XX_INV_BOMRESRATE_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_BOMRESRATE_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-DEC-2013
File Name     : XXINVBOMRESRATEVAL.pks
Description   : This script creates the specification of the package xx_inv_bomresrate_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
06-DEC-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------

-- Customer Relationship  Data-Validations
FUNCTION data_validations_bomresrate
         (
         p_cnv_bomresrate_rec   IN OUT xx_inv_bomresrate_pkg.g_xx_inv_bomresrate_rec_type
         )
RETURN NUMBER;


END xx_inv_bomresrate_val_pkg;
/
