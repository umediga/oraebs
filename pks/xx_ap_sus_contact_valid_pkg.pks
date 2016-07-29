DROP PACKAGE APPS.XX_AP_SUS_CONTACT_VALID_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AP_SUS_CONTACT_VALID_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2011
 File Name     : XXAPSUSCONTVAL.pks
 Description   : This script creates the specification of the package
                 xx_ap_sus_contact_valid_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2011 Sharath Babu          Initial Version
*/
----------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION pre_validations (
      p_cnv_stg_rec   IN   xx_ap_sus_contact_cnv_pkg.g_xx_sus_cont_stg_rec_type
   )
      RETURN NUMBER;

   FUNCTION batch_validations (p_batch_id VARCHAR2)
      RETURN NUMBER;

   FUNCTION data_validations (
      p_cnv_hdr_rec   IN OUT   xx_ap_sus_contact_cnv_pkg.g_xx_sus_cont_pre_std_rec_type
   )
      RETURN NUMBER;

   FUNCTION post_validations
      RETURN NUMBER;

   FUNCTION data_derivations (
      p_cnv_hdr_rec   IN OUT   xx_ap_sus_contact_cnv_pkg.g_xx_sus_cont_pre_std_rec_type
   )
      RETURN NUMBER;
END xx_ap_sus_contact_valid_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUS_CONTACT_VALID_PKG TO INTG_XX_NONHR_RO;
