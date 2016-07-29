DROP PACKAGE APPS.XX_HR_EX_EMP_CNV_VALIDATE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_EX_EMP_CNV_VALIDATE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Vasavi Chaikam
 Creation Date : 09-Mar-2012
 File Name     : XX_HR_EX_EMP_VAL.pks
 Description   : This script creates the body of the package specs for
                 xx_hr_emp_cnv_validations_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Oct-2007 IBM development                  Initial development.
 09-Mar-2012 Vasavi Chaikam        Changed as per Integra
*/
----------------------------------------------------------------------

   g_lookup_type VARCHAR2(30) :='LEAV_REAS';
   g_person_type VARCHAR2(30) :='EX_EMP';
   g_yes         VARCHAR2(1)  := 'Y';


   FUNCTION find_max
                   (p_error_code1    IN     VARCHAR2
                   ,p_error_code2    IN     VARCHAR2
                   ) RETURN VARCHAR2;


   FUNCTION pre_validations
    RETURN NUMBER;


   FUNCTION data_validations
                   (p_cnv_hdr_rec IN OUT NOCOPY xx_hr_ex_emp_conversion_pkg.G_XX_HR_EX_CNV_PRE_REC_TYPE
                   ) RETURN NUMBER;


   FUNCTION post_validations
                   RETURN NUMBER;


   FUNCTION data_derivations
                  (p_cnv_pre_std_hdr_rec IN OUT nocopy xx_hr_ex_emp_conversion_pkg.G_XX_HR_EX_CNV_PRE_REC_TYPE
                  ) RETURN NUMBER;


END XX_HR_EX_EMP_CNV_VALIDATE_PKG;
/
