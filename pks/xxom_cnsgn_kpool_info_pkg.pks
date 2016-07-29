DROP PACKAGE APPS.XXOM_CNSGN_KPOOL_INFO_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_CNSGN_KPOOL_INFO_PKG" AS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CNSGN_KPOOL_INFO_PKG.sql
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
*     1.0  21-DEC-2013 Brian Stadnik
*
* ISSUES:
* 
******************************************************************************************/

l_proc_date VARCHAR2 (50)
         := TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS') ;
l_int_seq_no        NUMBER:=0;
PROCEDURE INTG_SER_INFO_EXT_PRC( errbuf         OUT VARCHAR2,
                                        retcode        OUT VARCHAR2,
                                        p_orgn_id        IN  NUMBER);
PROCEDURE INTG_SER_INFO_ERR_PRC (p_msg         IN VARCHAR2,
                                        p_status      IN VARCHAR2,
                                        p_trans_id    IN NUMBER);

PROCEDURE INTG_SER_INFO_EXP_PRC(l_to_orgn_id       IN  NUMBER);
END XXOM_CNSGN_KPOOL_INFO_PKG; 
/
