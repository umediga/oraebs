DROP PACKAGE APPS.XX_QP_PRICE_LIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_PRICE_LIST_CNV_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : Samir
 Creation Date  : 27-FEB-2012
 File Name      : XXQPPRICELISTCNVVL.pks
 Description    : This script creates the specification of the package xx_qp_price_list_cnv_val_pkg


Change History:

Version Date          Name        Remarks
------- -----------   --------    -------------------------------
1.0     27-FEB-2012   Samir       Initial development.
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
       p_orig_sys_line_ref    IN VARCHAR2
   )
   RETURN VARCHAR2;

   FUNCTION pre_validations
   (
      p_batch_id IN VARCHAR2
   )
   RETURN NUMBER;

   FUNCTION common_data_validations
   (
      p_batch_id IN VARCHAR2
   )
   RETURN NUMBER;

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT xx_qp_price_list_cnv_pkg.G_XX_QP_PL_PRE_REC_TYPE
   )
   RETURN NUMBER;

   FUNCTION post_validations(p_batch_id IN VARCHAR2)
   RETURN NUMBER;


   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT xx_qp_price_list_cnv_pkg.G_XX_QP_PL_PRE_REC_TYPE
   ) RETURN NUMBER;
   END xx_qp_price_list_cnv_val_pkg;
/


GRANT EXECUTE ON APPS.XX_QP_PRICE_LIST_CNV_VAL_PKG TO INTG_XX_NONHR_RO;
