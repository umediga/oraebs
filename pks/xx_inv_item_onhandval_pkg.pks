DROP PACKAGE APPS.XX_INV_ITEM_ONHANDVAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_ITEM_ONHANDVAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By    : Mou Mukherjee
 Creation Date : 27-Feb-2012
 File Name     : XXINVITEMONHANDVL.pks
 Description   : This script creates the specification of the package xx_inv_item_onhandval_pkg

 CCID00

 Change History:

 Version Date        Name		Remarks
-------- ----------- ----		---------------------------------------
 1.0     27-Feb-2012  Mou Mukherjee     Initial development.
*/
----------------------------------------------------------------------
   FUNCTION pre_validations
   RETURN NUMBER;

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY xx_inv_itemonhandqty_pkg.G_XX_INV_ITEMQOH_PRE_REC_TYPE
   ) RETURN NUMBER;

   FUNCTION post_validations
   RETURN NUMBER;

   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT xx_inv_itemonhandqty_pkg.G_XX_INV_ITEMQOH_PRE_REC_TYPE
   ) RETURN NUMBER;

   CN_DISTACCT_NODATA      CONSTANT VARCHAR2 (200)  := 'No Distribution Account Found';
   CN_DISTACCT_TOOMANY     CONSTANT VARCHAR2 (200)  := 'More then 1 Distribution Account Found';
   CN_DISTACCT_VALID       CONSTANT VARCHAR2 (200)  := 'Distribution Account Derivation';
   CN_DAT_VALID            CONSTANT VARCHAR2 (200)  := 'Data Validation';

END xx_inv_item_onhandval_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEM_ONHANDVAL_PKG TO INTG_XX_NONHR_RO;
