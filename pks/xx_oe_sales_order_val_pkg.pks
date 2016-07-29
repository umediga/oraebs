DROP PACKAGE APPS.XX_OE_SALES_ORDER_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_SALES_ORDER_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Samir Singha Mahapatra
 Creation Date : 14-MAR-2012
 File Name     : XXOESOHDRVAL.pks
 Description   : This script creates the body of the package
                 xx_oe_sales_order_val_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 14-MAR-2012 Samir                 Initial development.
*/
----------------------------------------------------------------------
   FUNCTION find_max
   (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
   )
   RETURN VARCHAR2;

   FUNCTION pre_validations
   RETURN NUMBER;

  /* FUNCTION batch_validations(p_batch_id VARCHAR2)
   RETURN NUMBER;*/


   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT  xx_oe_sales_order_conv_pkg.G_XX_SO_CNV_PRE_STD_REC_TYPE
   ) RETURN NUMBER;

   FUNCTION data_validations_line
   (
      p_cnv_line_rec IN OUT  xx_oe_sales_order_conv_pkg.G_XX_SO_LINE_PRE_STD_REC_TYPE
   ) RETURN NUMBER;

   FUNCTION post_validations
   RETURN NUMBER;

   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT  xx_oe_sales_order_conv_pkg.G_XX_SO_CNV_PRE_STD_REC_TYPE
   ) RETURN NUMBER;

   FUNCTION data_derivations_line
   (
      p_cnv_line_rec IN OUT  xx_oe_sales_order_conv_pkg.G_XX_SO_LINE_PRE_STD_REC_TYPE
   ) RETURN NUMBER;

END xx_oe_sales_order_val_pkg;
/


GRANT EXECUTE ON APPS.XX_OE_SALES_ORDER_VAL_PKG TO INTG_XX_NONHR_RO;
