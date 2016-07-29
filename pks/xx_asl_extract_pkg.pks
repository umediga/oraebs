DROP PACKAGE APPS.XX_ASL_EXTRACT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ASL_EXTRACT_PKG" 
IS
   ----------------------------------------------------------------------
   /*
    Created By    : Renjith
    Creation Date : 13-Jul-2012
    File Name     : XX_ASL_EXTRACT_PKG.pkb
    Description   : This script creates the specification of the package
                    xx_asl_extract_pkg
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    13-Jul-2012 Renjith               Initial Version
   */
    ----------------------------------------------------------------------
   --PROCEDURE write_data_file (p_approved_vendor IN  VARCHAR2);
   PROCEDURE write_data_file( x_error_code      OUT    NUMBER
                             ,x_error_msg       OUT    VARCHAR2
                             ,p_file_dir        IN     VARCHAR2
                             ,p_file_name       IN     VARCHAR2
                             ,p_operating_unit  IN     NUMBER
                             ,p_approved_vendor IN     VARCHAR2);
END xx_asl_extract_pkg;
/


GRANT EXECUTE ON APPS.XX_ASL_EXTRACT_PKG TO INTG_XX_NONHR_RO;
