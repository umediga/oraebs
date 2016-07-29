DROP PACKAGE APPS.XXOM_CNSGN_ITEM_PRICE_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_CNSGN_ITEM_PRICE_PKG" 
/*************************************************************************************
*   PROGRAM NAME
* 	XXOM_CNSGN_ITEM_PRICE_PKG.sql
*
*   DESCRIPTION
* 
*   USAGE
* 
*    PARAMETERS
*    ==========
*    NAME 	               DESCRIPTION
*    ----------------      ------------------------------------------------------
* 
*   DEPENDENCIES
*  
*   CALLED BY
* 
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)  	DESCRIPTION
* ------- ----------- --------------- 	---------------------------------------------------
*     1.0 18-OCT-2013 Brian Stadnik
*
* ISSUES:
* 
******************************************************************************************/
   AUTHID CURRENT_USER
IS
   l_orgn_code      VARCHAR2 (3);
   l_orgn_name      VARCHAR2 (240);
   l_user_name      VARCHAR2 (100);
   l_user_id        NUMBER := fnd_profile.VALUE ('USER_ID');
   l_resp_id        NUMBER := fnd_profile.VALUE ('RESP_ID');
   l_resp_appl_id   NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');
   l_rec_cnt        NUMBER;
   l_errmsg         VARCHAR2 (3000);
   l_proc_date VARCHAR2 (50) := TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS') ;
   l_fname          VARCHAR2 (500);
   l_fname1         VARCHAR2 (500);
   l_file_dir       VARCHAR2 (1000);
   l_file_dir_arch  VARCHAR2 (1000);
   l_proc_status    VARCHAR2 (1) := 'P';
   l_price_seq_no   NUMBER;
   l_comm_seq_no    NUMBER;


   PROCEDURE intg_item_price_transform (
                                       errbuf              OUT VARCHAR2,
                                       retcode             OUT VARCHAR2,
                                       p_price_list        IN VARCHAR2,
                                       p_organization_id   IN NUMBER
                                       );
END XXOM_CNSGN_ITEM_PRICE_PKG;
/
