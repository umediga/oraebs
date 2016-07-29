DROP PACKAGE APPS.XX_FASSETS_TAX_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_FASSETS_TAX_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 20-Mar-2012
 File Name     : XXFASSTTAXVAL.pks
 Description   : This script creates the spec of the package spec for xx_fa_assets_val_pkg
 Change History:
 ----------------------------------------------------------------------
 Date        Name       Remarks
 ----------- ----       -----------------------------------------------
 18-May-10 Venu GR.Tanniru   Initial development.
*/
-----------------------------------------------------------------------
/************************************************************************************/
FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2;
----------------------------------------------------------------------------------------------
/*FUNCTION pre_validations (
      p_receipt_hdr_rec   IN OUT NOCOPY   xx_fassets_tax_cnv_pkg.G_XX_FAASST_TAX_PIFACE_REC
                           )  RETURN NUMBER;  */

----------------------------------------------------------------------------------------------

FUNCTION post_validations
   RETURN NUMBER;

----------------------------------------------------------------------------------------------

FUNCTION data_validations (
         p_rcpt_hdr_rec   IN OUT NOCOPY   xx_fassets_tax_cnv_pkg.G_XX_FAASST_TAX_PIFACE_REC
                          )     RETURN NUMBER;
-----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

  FUNCTION data_derivations  (p_cnv_pre_std_hdr_rec
       IN OUT xx_fassets_tax_cnv_pkg.G_XX_FAASST_TAX_PIFACE_REC
                              ) RETURN NUMBER;

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

 /* FUNCTION get_r12_asset_num  (p_legacy_asset_num IN VARCHAR2
                              ,p_fas_num          IN VARCHAR2)
  RETURN NUMBER;
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

  FUNCTION get_deprn_method_code(
                                 p_legacy_asset_num IN VARCHAR2
                                ,p_fas_num          IN VARCHAR2
                                ,p_book_type_code   IN VARCHAR2
                              )
  RETURN VARCHAR2;*/

----------------------------------------------------------------------------------------------

/*FUNCTION receipt_appl_data_validations (
         p_receipt_appl_piface_rec   IN OUT NOCOPY   xx_fassets_tax_cnv_pkg.G_XX_FAASST_TAX_PIFACE_REC
   )     RETURN NUMBER;*/
END  xx_fassets_tax_val_pkg;
/


GRANT EXECUTE ON APPS.XX_FASSETS_TAX_VAL_PKG TO INTG_XX_NONHR_RO;
