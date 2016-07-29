DROP PACKAGE APPS.XX_GL_CONS_FFIELD_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_GL_CONS_FFIELD_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 29-Mar-2012
 File Name     : XXGLCONFLEXMAPVAL.pks
 Description   : This script creates the spec of the package spec for xx_gl_cons_ffield_val_pkg
 Change History:
 ----------------------------------------------------------------------
 Date        Name       Remarks
 ----------- ----       -----------------------------------------------
 29-Mar-2012 IBM Development Team   Initial development.
*/
-----------------------------------------------------------------------
/************************************************************************************/
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2;

----------------------------------------------------------------------------------------------
/*FUNCTION pre_validations (
      p_receipt_hdr_rec   IN OUT NOCOPY   xx_gl_cons_ffield_load_pkg.g_xxgl_ffield_map_piface_rec
                           )  RETURN NUMBER;  */

   ----------------------------------------------------------------------------------------------
   FUNCTION post_validations
      RETURN NUMBER;

----------------------------------------------------------------------------------------------
   FUNCTION data_validations (
      p_gl_map_rec   IN OUT NOCOPY   xx_gl_cons_ffield_load_pkg.g_xxgl_ffield_map_piface_rec
   )
      RETURN NUMBER;

-----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT   xx_gl_cons_ffield_load_pkg.g_xxgl_ffield_map_piface_rec,
      p_ledger_id             IN       NUMBER
   )
      RETURN NUMBER;
----------------------------------------------------------------------------------------------
END xx_gl_cons_ffield_val_pkg;
/


GRANT EXECUTE ON APPS.XX_GL_CONS_FFIELD_VAL_PKG TO INTG_XX_NONHR_RO;
