DROP PACKAGE APPS.XX_QP_MOD_LIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_MOD_LIST_CNV_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By    : Debjani Roy
 Creation Date : 06-Jun-2013
 File Name     : XXQPMODLISTCNVVL.pks
 Description   : This script creates the package xx_qp_mod_list_cnv_val_pkg

 Change History:

 Version Date        Name                  Remarks
-------- ----------- ------------          ---------------------------------------
 1.0     06-Jun-2013 Debjani Roy  Initial development.
*/
----------------------------------------------------------------------

   FUNCTION pre_validations
   (
      p_batch_id    IN VARCHAR2
   ) RETURN NUMBER;


   /************************ Batch Level Validation for Modifiers *****************************/
   /************************ Overloaded Function *****************************/
   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY xx_qp_mdpr_list_hdr_pre%ROWTYPE
   ) RETURN NUMBER;

   FUNCTION data_validations
   (
      p_batch_id    IN VARCHAR2
   ) RETURN NUMBER;


   /************************ Batch Level Validation for Qualifiers *****************************/
   /************************ Overloaded Function *****************************/
   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY xx_qp_mdpr_list_qlf_pre%ROWTYPE
   ) RETURN NUMBER;

    FUNCTION post_validations (p_batch_id IN VARCHAR2)
             RETURN NUMBER;

   /************************ Data Derivation for Modifiers *****************************/
   /************************ Overloaded Function *****************************/
    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec   IN OUT xx_qp_mdpr_list_hdr_pre%ROWTYPE
    ) RETURN NUMBER;

    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT xx_qp_mdpr_list_lines_pre%ROWTYPE
    ) RETURN NUMBER;

   /************************ Data Derivation for Qualifiers *****************************/
   /************************ Overloaded Function *****************************/
    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT xx_qp_mdpr_list_qlf_pre%ROWTYPE
    ) RETURN NUMBER;

END xx_qp_mod_list_cnv_val_pkg;
/
