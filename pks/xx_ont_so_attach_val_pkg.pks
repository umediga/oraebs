DROP PACKAGE APPS.XX_ONT_SO_ATTACH_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_ont_so_attach_val_pkg
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 23-Sep-2013
File Name     : XXONTSOATTVAL.pks
Description   : This script creates the specification of the package xx_ont_so_attach_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
23-Sep-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------

-- Customer Relationship  Data-Validations
FUNCTION data_validations_att
         (
         p_cnv_so_att_rec   IN OUT xx_ont_so_attach_pkg.g_xx_ont_so_att_rec_type
         )
RETURN NUMBER;


END xx_ont_so_attach_val_pkg;
/
