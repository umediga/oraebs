DROP PACKAGE APPS.XXOM_MAT_ISS_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_MAT_ISS_PKG" IS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_MAT_ISS_PKG.sql
*
*   DESCRIPTION
*
*   USAGE
*
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
*
*   DEPENDENCIES
*
*   CALLED BY
*
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     1.0  29-DEC-2013 Brian Stadnik
*
* ISSUES:
*
******************************************************************************************/
PROCEDURE INTG_INV_ISSUE (errbuf             OUT VARCHAR2,
                          retcode            OUT VARCHAR2,
                          p_orgn_id          IN  NUMBER,
                          p_subinv_code      IN  VARCHAR2,
                          p_trans_date        IN  VARCHAR2,
                          p_set_org_id        IN  NUMBER);

PROCEDURE INTG_ERROR_MESSAGE(  p_msg         IN VARCHAR2,
                               p_status      IN VARCHAR2,
                               p_trans_id    IN NUMBER);

PROCEDURE INTG_INV_ISSUE_EXP_PRC;

END XXOM_MAT_ISS_PKG;
/
