DROP PACKAGE APPS.XX_HR_SAL_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_SAL_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Arjun K
 Creation Date : 11-JAN-2012
 File Name     :XXHRSALVAL.pks
 Description   :This script creates the body of the package specs for
                 xx_hr_sal_cnv_validations_pkg
 Change History:
 Date           Name               Remarks
 -----------    -------------      -----------------------------------
 11-JAN-2012    Arjun K            Initial Development
*/
----------------------------------------------------------------------
   FUNCTION find_max
                   (p_error_code1    IN     VARCHAR2
                   ,p_error_code2    IN     VARCHAR2
                   ) RETURN VARCHAR2;


   FUNCTION pre_validations(p_cnv_hdr_rec IN OUT NOCOPY xx_hr_sal_conversion_pkg.G_XX_HR_CNV_PRE_REC_TYPE
                           ) RETURN NUMBER;


   FUNCTION data_validations
                   (p_cnv_hdr_rec IN OUT NOCOPY xx_hr_sal_conversion_pkg.G_XX_HR_CNV_PRE_REC_TYPE
                   ) RETURN NUMBER;


   FUNCTION post_validations
                   RETURN NUMBER;


   FUNCTION data_derivations
                  (p_cnv_pre_std_hdr_rec IN OUT nocopy xx_hr_sal_conversion_pkg.G_XX_HR_CNV_PRE_REC_TYPE
                  ) RETURN NUMBER;


END xx_hr_sal_cnv_validations_pkg;
/
