DROP PACKAGE APPS.XXOM_CUST_ADDR_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_CUST_ADDR_PKG" AS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CUST_ADDR_PKG.sql
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
*     1.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
*
******************************************************************************************/
l_proc_date VARCHAR2 (50)
         := TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS') ;
PROCEDURE intg_cust_addr_extract ( errbuf       OUT NOCOPY VARCHAR2,
                                   retcode      OUT NOCOPY NUMBER);

--(p_category VARCHAR2);
PROCEDURE intg_log_message (  p_msg         IN VARCHAR2,
                              p_status      IN VARCHAR2);
                               --  p_trans_id    IN NUMBER);

END XXOM_CUST_ADDR_PKG; 
/
