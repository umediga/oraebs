DROP PACKAGE APPS.XXOM_MAT_RCPT_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_MAT_RCPT_PKG" AS

/*************************************************************************************
*   PROGRAM NAME
*     XXOM_MAT_RCPT_PKG.sql
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
*     1.0  05-JAN-2014 Brian Stadnik
*
* ISSUES:
*
******************************************************************************************/

l_proc_date VARCHAR2 (50)
         := TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS') ;
      l_int_seq_no        NUMBER:=0;
PROCEDURE INTG_INV_RCPT_EXT_PRC(errbuf                 OUT VARCHAR2,
                                           retcode            OUT VARCHAR2,
                                           p_orgn_id       IN  NUMBER,
                                           p_subinv_code    IN  VARCHAR2,
                                           p_trans_date    IN  VARCHAR2,
                                        --   p_tran_type    IN  VARCHAR2,
                                           p_set_org_id    IN  NUMBER
                                           );
PROCEDURE INTG_INV_RCPT_ERR_PRC (p_msg         IN VARCHAR2,
                                        p_status      IN VARCHAR2,
                                        p_trans_id    IN NUMBER);


PROCEDURE INTG_INV_RCPT_EXP_PRC;

/***Vishy: 07/28/2014 Added xmrs transaction ID to get the lot and serial number for processing****/

PROCEDURE unpackFloater( p_transaction_id IN NUMBER,
                         p_xmrs_transaction_id IN NUMBER,
                            x_return_status OUT NOCOPY VARCHAR2,
                            x_return_message OUT NOCOPY VARCHAR2);

PROCEDURE unpack_noss_multi_level(p_lpn_id in NUMBER,
              x_return_status OUT NOCOPY VARCHAR2,
              x_return_message OUT NOCOPY VARCHAR2);

END XXOM_MAT_RCPT_PKG;
/
