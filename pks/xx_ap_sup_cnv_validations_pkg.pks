DROP PACKAGE APPS.XX_AP_SUP_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AP_SUP_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2012
 File Name     : XXAPSUPVAL.pks
 Description   : This script creates the specification of the package
                 xx_ap_sup_cnv_validations_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2012 Sharath Babu          Initial development.
 23-MAY-2013 Sharath Babu          Added p_validate_and_load as per Wave1
*/
----------------------------------------------------------------------
   --Added to check validation only as per Wave1
   g_validate_and_load   VARCHAR2 (100)  := 'VALIDATE_AND_LOAD';

   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION pre_validations
      RETURN NUMBER;

   FUNCTION batch_validations (p_batch_id VARCHAR2)
      RETURN NUMBER;

   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT   xx_ap_sup_conversion_pkg.g_xx_sup_cnv_pre_std_rec_type
     ,p_validate_and_load   IN       VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION post_validations
      RETURN NUMBER;

   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT   xx_ap_sup_conversion_pkg.g_xx_sup_cnv_pre_std_rec_type
   )
      RETURN NUMBER;
END xx_ap_sup_cnv_validations_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUP_CNV_VALIDATIONS_PKG TO INTG_XX_NONHR_RO;
