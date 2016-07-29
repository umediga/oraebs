DROP PACKAGE APPS.XXOM_CNSGN_CUST_INTF_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_CNSGN_CUST_INTF_PKG" AS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CNSGN_CUST_INTF_PKG.sql
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

   PROCEDURE intg_log_message (
      p_msg        IN   VARCHAR2,
      p_status     IN   VARCHAR2
     -- p_trans_id   IN   NUMBER
   );

PROCEDURE intg_customer_translate
   (errbuf       OUT NOCOPY VARCHAR2,
    retcode      OUT NOCOPY NUMBER);
END XXOM_CNSGN_CUST_INTF_PKG; 
/
