DROP PACKAGE APPS.XX_HR_CWK_ASG_VALIDATION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_CWK_ASG_VALIDATION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 08-Feb-2010
 File Name     : XXHRCWAVAL.pks
 Description   : This script creates the body of the package specs for
                 xx_hr_cwkasg_cnv_valid_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 08-May-2010 IBM Development       Initial development.
 25-Jan-2012 Deepika Jain          Modified for Integra
 04-JUN-2012 Arjun K.              Added g_accounting_flex global variable
*/
----------------------------------------------------------------------
   g_accounting_flex VARCHAR2 (150)    := 'INTG_ACCOUNTING_FLEXFIELD';
   g_change_reason_type VARCHAR2 (150) := 'EMP_ASSIGN_REASON';

   FUNCTION find_max
                   (p_error_code1    IN     VARCHAR2
                   ,p_error_code2    IN     VARCHAR2
                   ) RETURN VARCHAR2;
   FUNCTION pre_validations(p_cnv_hdr_rec IN OUT NOCOPY xx_hr_asg_conversion_pkg.G_XX_ASG_CNV_PRE_REC_TYPE
                           ) RETURN NUMBER;
   FUNCTION data_validations
                   (p_cnv_hdr_rec IN OUT NOCOPY xx_hr_asg_conversion_pkg.G_XX_ASG_CNV_PRE_REC_TYPE
                   ) RETURN NUMBER;
   FUNCTION post_validations
                   RETURN NUMBER;
   FUNCTION data_derivations
                  (p_cnv_pre_std_hdr_rec IN OUT nocopy xx_hr_asg_conversion_pkg.G_XX_ASG_CNV_PRE_REC_TYPE
                  ) RETURN NUMBER;
END xx_hr_cwk_asg_validation_pkg; 
/
