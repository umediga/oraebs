DROP PACKAGE APPS.XX_QP_QUAL_RUL_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_QUAL_RUL_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : DebJANI Roy
 Creation Date  : 1-jUNE-2013
 File Name      : XXQPPRCQUALVL.pks
 Description    : This script creates the specification of the validation package xx_price_list_qual_val_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------

----------------------------*------------------------------------------------------------------

 Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ---------------------------------------
1.0     1-JUN-2013 Debjani Roy  Initial development.
-------------------------------------------------------------------------
*/
   FUNCTION find_max (
        p_error_code1 IN VARCHAR2,
        p_error_code2 IN VARCHAR2) RETURN VARCHAR2;


   FUNCTION pre_validations
   (
      p_batch_id    IN VARCHAR2/*,
      p_prog        IN VARCHAR2*/
   ) RETURN NUMBER;


   /************************ Batch Level Validation for Qualifiers *****************************/
   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY XX_QP_RULES_QLF_PRE%ROWTYPE
   ) RETURN NUMBER;

    FUNCTION post_validations (p_batch_id IN VARCHAR2/*,p_prog IN VARCHAR2*/)
             RETURN NUMBER;


   /************************ Data Derivation for Qualifiers *****************************/
   FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT XX_QP_RULES_QLF_PRE%ROWTYPE
    ) RETURN NUMBER;

END xx_qp_qual_rul_val_pkg;
/
