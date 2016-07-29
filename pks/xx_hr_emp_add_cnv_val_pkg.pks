DROP PACKAGE APPS.XX_HR_EMP_ADD_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_EMP_ADD_CNV_VAL_PKG" 
AS
---------------------------------------------------------------------------------------------
/*
 Created By    : Monali Ashtankar
 Creation Date : 28-NOV-2007
 File Name     : XXHRADDVAL.pks
 Description   : This script creates the body of the package specs for
                 xx_hr_emp_add_cnv_val_pkg
 Change History:
 Date           Name                         Remarks
------------   ----------------------       -----------------------------------
28-NOV-2007     Monali Ashtankar             Initial development.
*/
----------------------------------------------------------------------------------------------
   FUNCTION find_max
   (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
   )
   RETURN VARCHAR2;


  FUNCTION pre_validations( p_cnv_hdr_rec IN OUT nocopy
                            xx_hr_emp_add_conversion_pkg.g_xx_hr_add_cnv_pre_rec_type
                          ) RETURN NUMBER;

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT xx_hr_emp_add_conversion_pkg.G_XX_HR_ADD_CNV_PRE_REC_TYPE--changeg by Monali
   )
   RETURN NUMBER;


   FUNCTION post_validations
   RETURN NUMBER;


   FUNCTION data_derivations
   (
      p_cnv_pre_std_hdr_rec IN OUT xx_hr_emp_add_conversion_pkg.G_XX_HR_ADD_CNV_PRE_REC_TYPE--changeg by Monali
   ) RETURN NUMBER;


END XX_HR_EMP_ADD_CNV_VAL_PKG;
/
