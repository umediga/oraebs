DROP PACKAGE APPS.XX_UNIQUE_CAT_CODE_COMB;

CREATE OR REPLACE PACKAGE APPS."XX_UNIQUE_CAT_CODE_COMB" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : Omkar (IBM Development)
 Creation Date : 16-DEC-2013
 File Name     : XXUNIQUECATCODECOMB.pks
 Description   : This script creates the specification of the package
                 XX_UNIQUE_CAT_CODE_COMB
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 16-DEC-2013 Omkar                Initial Version
*/ 
----------------------------------------------------------------------
PROCEDURE LOAD_CAT_CODE_COMB         ( errbuf          OUT  VARCHAR2,
                              RETCODE         OUT  NUMBER,
                              P_CATEGORY_SET_NAME IN VARCHAR2
                                 );
                                                                                                                            
END XX_UNIQUE_CAT_CODE_COMB; 
/
