DROP PACKAGE APPS.XX_ONT_CUSTITEMORDER_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_CUSTITEMORDER_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 21-MAY-2012
 File Name     : XXONTITEMORDERVL.pks
 Description   : This script creates the specification of the package xx_ont_custitemorder_val_pkg


 Change History:

 Version Date        Name		    Remarks
-------- ----------- --------------	---------------------------------------
 1.0     30-AUG-2013 Mou Mukherjee         Initial development.
*/
---------------------------------------------------------------------------
   FUNCTION pre_validations
    RETURN NUMBER;

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT xx_ont_custitemorder_pkg.G_XX_ITEMORDER_PRE_REC_TYPE
   ) RETURN NUMBER;

   FUNCTION post_validations
    RETURN NUMBER;

   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT xx_ont_custitemorder_pkg.G_XX_ITEMORDER_PRE_REC_TYPE
   ) RETURN NUMBER;

   cn_orgnaization_valid       CONSTANT VARCHAR2(30) := 'CN_ORGNAIZATION_VALID';
   cn_orgnaization_miss        CONSTANT VARCHAR2(30) := 'Organization code Invalid';
   cn_organization_toomany     CONSTANT VARCHAR2(30) := 'Too Many Organization Found';
   cn_organization_nodta_fnd   CONSTANT VARCHAR2(30) := 'No Record Found';
   cn_exp_unhand               CONSTANT VARCHAR2(30) := 'Unhandled Exception';
   cn_no_valid                 CONSTANT VARCHAR2(30) := 'Not a valid data';
END xx_ont_custitemorder_val_pkg;
/
