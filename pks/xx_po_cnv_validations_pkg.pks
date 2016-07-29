DROP PACKAGE APPS.XX_PO_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PO_CNV_VALIDATIONS_PKG" 
AS
   ----------------------------------------------------------------------
   /*
    Created By    : IBM Development Team
    Creation Date : 23-FEB-2012
    File Name     : XXPOOPENPOVAL.pks
    Description   : This script creates the specification of the package
                    xx_po_cnv_validations_pkg
    Change History:
    Date         Name                   Remarks
    -----------  -------------          -----------------------------------
    23-FEB-2012  IBM Development Team   Initial Draft.
	15-JUL-2013	 ABHARGAVA				WAVE1 Changes
   */
   ----------------------------------------------------------------------
    G_ORG_ID                NUMBER;
    G_DOCUMENT_TYPE_CODE    VARCHAR2 (240) := XX_EMF_PKG.get_paramater_value
                                    ('XXINTGPOOPENPOCNV','DOCUMENT_TYPE_CODE');
    G_COMPONENT_NAME        VARCHAR2(10) := 'PO';
    ---To find the vendor number
    FUNCTION xx_po_conv_ven (p_att1 VARCHAR2, p_att2 VARCHAR2,p_src VARCHAR2)
      RETURN VARCHAR2;
   -- To find Max of error code
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2;

   -- Pre-Validations
   FUNCTION pre_validations
      RETURN NUMBER;

   -- Header Level Data-Validations
   FUNCTION data_validations_hdr (
      p_cnv_hdr_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_HDR_REC_TYPE
   )
      RETURN NUMBER;

   -- Line Level Data-Validations
   FUNCTION data_validations_line (
      p_cnv_line_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_LINE_REC_TYPE
   )
      RETURN NUMBER;

   -- Distribution Level Data-Validations --added
   FUNCTION data_validations_dist (
      p_cnv_dist_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_DIST_REC_TYPE,
      p_acct_mapping_req VARCHAR2
   )
      RETURN NUMBER;

   -- Header Level Data-Derivations
   FUNCTION data_derivations_hdr (
      p_cnv_pre_hdr_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_HDR_REC_TYPE
   )
      RETURN NUMBER;

   -- Line Level Data-Derivations
   FUNCTION data_derivations_line (
      p_cnv_pre_line_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_LINE_REC_TYPE
   )
      RETURN NUMBER;

   -- Distribution Level Data-Derivations
   FUNCTION data_derivations_dist (
      p_cnv_pre_dist_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_DIST_REC_TYPE
   )
      RETURN NUMBER;

   -- Post-Validations
   FUNCTION post_validations
      RETURN NUMBER;
END xx_po_cnv_validations_pkg;
/


GRANT EXECUTE ON APPS.XX_PO_CNV_VALIDATIONS_PKG TO INTG_XX_NONHR_RO;
