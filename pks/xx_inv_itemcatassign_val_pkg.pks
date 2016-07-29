DROP PACKAGE APPS.XX_INV_ITEMCATASSIGN_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_ITEMCATASSIGN_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 28-MAR-2012
 File Name     : XXINVITEMCATASSIGNVALVL.pks
 Description   : This script creates the specification of the package xx_inv_itemcatassign_val_pkg

 CCID00

 Change History:

 Version Date        Name		    Remarks
-------- ----------- ----		    ---------------------------------------
 1.0     28-MAR-2012 IBM Development Team   Initial development.
*/
---------------------------------------------------------------------------
   FUNCTION pre_validations
    RETURN NUMBER;

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT xx_inv_itemcatassign_pkg.G_XX_INV_ITEMCAT_PRE_REC_TYPE
   ) RETURN NUMBER;

   FUNCTION post_validations
    RETURN NUMBER;

   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT xx_inv_itemcatassign_pkg.G_XX_INV_ITEMCAT_PRE_REC_TYPE
   ) RETURN NUMBER;

   FUNCTION checkassignmentexistence(p_organization_id   IN NUMBER,
                                          p_inventory_item_id IN NUMBER,
                                          p_category_set_id   IN NUMBER,
                                          p_category_id       IN NUMBER
                                         ) RETURN NUMBER;

   FUNCTION checksetassignment(p_organization_id   IN NUMBER,
                                    p_inventory_item_id IN NUMBER,
                                    p_category_set_id   IN NUMBER,
                                    p_category_id       IN NUMBER
                                   ) RETURN NUMBER;

   cn_orgnaization_valid       CONSTANT VARCHAR2(30) := 'CN_ORGNAIZATION_VALID';
   cn_orgnaization_miss        CONSTANT VARCHAR2(30) := 'Organization code Invalid';
   cn_organization_toomany     CONSTANT VARCHAR2(30) := 'Too Many Organization Found';
   cn_organization_nodta_fnd   CONSTANT VARCHAR2(30) := 'No Record Found';
   cn_exp_unhand               CONSTANT VARCHAR2(30) := 'Unhandled Exception';
   cn_no_valid                 CONSTANT VARCHAR2(30) := 'Not a valid data';
END xx_inv_itemcatassign_val_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEMCATASSIGN_VAL_PKG TO INTG_XX_NONHR_RO;
