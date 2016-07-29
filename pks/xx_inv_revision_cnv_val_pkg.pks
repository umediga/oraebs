DROP PACKAGE APPS.XX_INV_REVISION_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_REVISION_CNV_VAL_PKG" AUTHID CURRENT_USER AS
----------------------------------------------------------------------
/* $Header: XXINVREVCNVVL.pks 1.2 2012/02/15 12:00:00 dsengupta noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 30-Dec-2011
 File Name     : XXINVREVCNVVL.pks
 Description   : This script creates the specification of the Item Revision Conversion validation package

 Change History:

 Version Date        Name			Remarks
 ------- ----------- ----			-------------------------------
 1.0     30-Dec-11   IBM Development Team	Initial development.
*/
----------------------------------------------------------------------
   FUNCTION find_max
   (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
   )
   RETURN VARCHAR2;

   FUNCTION find_lookup_value (
       p_lookup_type 		IN VARCHAR2,
       p_lookup_value 		IN VARCHAR2,
       p_lookup_text 		IN VARCHAR2,
       p_record_number 		IN VARCHAR2,
       p_revision	 	IN VARCHAR2,
       p_organization_code	IN VARCHAR2

   )
   RETURN NUMBER;

   FUNCTION pre_validations
   (
      p_batch_id IN VARCHAR2
   )
   RETURN NUMBER;

   FUNCTION data_validations
   (
      p_cnv_rev_rec IN OUT xx_inv_revision_cnv_pkg.G_XX_INV_REV_PRE_REC_TYPE
   )
   RETURN NUMBER;

   FUNCTION post_validations(p_batch_id IN VARCHAR2)
   RETURN NUMBER;


   FUNCTION data_derivations
   (
      p_cnv_pre_rev_rec IN OUT xx_inv_revision_cnv_pkg.G_XX_INV_REV_PRE_REC_TYPE
   ) RETURN NUMBER;
   END xx_inv_revision_cnv_val_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_REVISION_CNV_VAL_PKG TO INTG_XX_NONHR_RO;
