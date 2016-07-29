DROP PACKAGE APPS.XX_BOM_DEPARTMENT_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BOM_DEPARTMENT_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 09-Dec-2013
File Name     : XXBOMDEPTVAL.pks
Description   : This script creates the specification of the package xx_bom_department_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
09-Dec-2013  Narendra Yadav         Initial Draft.
*/
----------------------------------------------------------------------

-- BOM Department Data-Validations
FUNCTION data_validations_att
         (
         p_cnv_bom_dept_rec   IN OUT xx_bom_department_pkg.g_xx_bom_department_rec_type
         )
RETURN NUMBER;

END xx_bom_department_val_pkg;
/
