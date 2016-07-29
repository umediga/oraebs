DROP PACKAGE APPS.XXOM_SET_BKDN_SER_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_SET_BKDN_SER_PKG" AS

/*************************************************************************************
*   PROGRAM NAME
*     XXOM_SET_BKDN_PKG.sql
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
*     1.0 22-DEC-2013 Brian Stadnik
*
* ISSUES:
* 
* 
******************************************************************************************/

l_proc_date VARCHAR2 (50)
         := TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS') ;
      l_int_seq_no        NUMBER;
      
PROCEDURE INTG_SET_BKDN_EXT_PRC(errbuf                 OUT VARCHAR2,
                                           retcode            OUT VARCHAR2,
                                           p_from_orgn_id       IN  NUMBER,
                                           p_to_orgn_id       IN  NUMBER,
                                           p_to_subinv_code    IN  VARCHAR2,
                                           p_trans_date        IN  VARCHAR2,
                                           p_rec_acc_alias_name    IN  VARCHAR2,
                                           p_rec_tran_type_name    IN  VARCHAR2,
                                           p_set_subinv_code    IN  VARCHAR2,
                                           p_serial_number      IN  VARCHAR2
                                           );
PROCEDURE INTG_SET_BKDN_EXP_PRC;
PROCEDURE INTG_SET_BKDN_INS_PRC(   l_from_orgn_id       IN  NUMBER,
                                           l_to_orgn_id       IN  NUMBER,
                                           l_to_subinv_code    IN  VARCHAR2,
                                           l_trans_date        IN  DATE,
                                           l_rec_acc_alias_name    IN  VARCHAR2,
                                           l_rec_tran_type_name    IN  VARCHAR2,
                                           l_set_subinv_code    IN  VARCHAR2);
END XXOM_SET_BKDN_SER_PKG; 
/
