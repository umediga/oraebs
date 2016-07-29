DROP PACKAGE APPS.XX_HR_UPDATE_POS_DFF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_UPDATE_POS_DFF_PKG" AUTHID CURRENT_USER
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XX_HR_UPDATE_POS_DFF.pks
 Description   : This script creates the specification of the package
                 XX_HR_UPDATE_POS_DFF_PKG
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Mar-2012 VASAVI               Initial Version
 01-Aug-2012 Vasavi               Removed the utl_read_insert_stg proc
*/
----------------------------------------------------------------------
g_stage            VARCHAR2(2000);
g_data_dir         VARCHAR2(200);
g_arch_dir         VARCHAR2(200);
g_email_id         VARCHAR2(200);
g_group_id         NUMBER;
g_data_file_name   VARCHAR2(60);
g_ftp_data_dir_name VARCHAR2(60);
g_ftp_data_dir_arch VARCHAR2(60);

TYPE G_XX_HR_UPDATE_POSDFF_REC_TYPE IS RECORD
(
     EFFECTIVE_DATE                 DATE,
     BUSINESS_GROUP	            VARCHAR2(240),
     POSITION_NAME		    VARCHAR2(100),
     HR_REP_POSITION                VARCHAR2(100),
     HR_DIR_POSITION                VARCHAR2(100),
     POSITION_ID		    NUMBER,
     POSITION_DEFINITION_ID         NUMBER,
     OBJECT_VERSION_NUMBER	    NUMBER,
     BUSINESS_GROUP_ID		    NUMBER,
     RECORD_ID	                    NUMBER,
     FILE_NAME                      VARCHAR2(50),
     REQUEST_ID               	    NUMBER,
     PROCESS_CODE                   VARCHAR2(100),
     ERROR_CODE                     VARCHAR2(100),
     ERROR_MESSAGE                  VARCHAR2(4000),
     CREATED_BY                     NUMBER,
     CREATION_DATE                  DATE,
     LAST_UPDATE_DATE               DATE,
     LAST_UPDATED_BY                NUMBER,
     LAST_UPDATE_LOGIN              NUMBER


);

TYPE G_XX_HR_UPDATE_POSDFF_TAB_TYPE IS TABLE OF G_XX_HR_UPDATE_POSDFF_REC_TYPE
INDEX BY BINARY_INTEGER;

-- Api proc
PROCEDURE main_prc ( p_errbuf        OUT VARCHAR2
                    ,p_retcode       OUT VARCHAR2
                    ,p_business_group IN VARCHAR2
                    ,p_reprocess     IN  VARCHAR2
                    ,p_dummy         IN  VARCHAR2
                    ,p_requestid     IN  NUMBER
                   -- ,p_file_name     IN  VARCHAR2
                    ,p_restart_flag  IN  VARCHAR2);


END XX_HR_UPDATE_POS_DFF_PKG;
/
