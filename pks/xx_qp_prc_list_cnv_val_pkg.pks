DROP PACKAGE APPS.XX_QP_PRC_LIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_PRC_LIST_CNV_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By    : DebJANI Roy
 Creation Date : 24-May-13
 File Name     : XXQPPRICELISTCNVVL.pks
 Description   : This script creates the specification of the package xx_qp_price_list_cnv_val_pkg
 CCID00

 Change History:

 Version Date        Name       Remarks
-------- ----------- ----       ---------------------------------------
 1.0     24-May-13 Debjani Roy   Initial development.
*/
----------------------------------------------------------------------
   FUNCTION find_max
   (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
   )
   RETURN VARCHAR2;

   FUNCTION find_lookup_value (
       p_lookup_type         IN VARCHAR2,
       p_lookup_value         IN VARCHAR2,
       p_lookup_text         IN VARCHAR2,
       p_record_number         IN VARCHAR2,
       p_orig_sys_header_ref IN VARCHAR2,
       p_orig_sys_line_ref    IN VARCHAR2 DEFAULT NULL,
       p_orig_sys_pricing_attr_ref IN VARCHAR2 DEFAULT NULL
   )
   RETURN VARCHAR2;

   FUNCTION pre_validations
   (
      p_batch_id IN VARCHAR2
   )
   RETURN NUMBER;

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT xx_qp_pr_list_hdr_pre%ROWTYPE
      --,p_header_line IN VARCHAR2
   )
   RETURN NUMBER;

   FUNCTION data_validations
   (
      p_batch_id IN VARCHAR2
      --,p_header_line IN VARCHAR2
   )
   RETURN NUMBER;

   /************************ Overloaded Function *****************************/
   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY xx_qp_pr_list_qlf_pre%ROWTYPE
   ) RETURN NUMBER;

   FUNCTION post_validations(p_batch_id IN VARCHAR2)
   RETURN NUMBER;


   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT xx_qp_pr_list_hdr_pre%ROWTYPE
   ) RETURN NUMBER;

   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT xx_qp_pr_list_lines_pre%ROWTYPE
   ) RETURN NUMBER;

   /************************ Overloaded Function *****************************/
    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT xx_qp_pr_list_qlf_pre%ROWTYPE
    ) RETURN NUMBER;
   END xx_qp_prc_list_cnv_val_pkg;
/
