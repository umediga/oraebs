DROP PACKAGE APPS.XX_EMF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_EMF_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development
 Creation Date  : 07-MAR-2012
 File Name      : XX_EMF_PKG.pks
 File Version   : 1
 Description    : This script creates the specification of the package xx_emf_pkg
 Change History:
 Date         Name              Remarks
 -----------  ----              ---------------------------------------
 07-MAR-2012  IBM Development   Initial development
 03-AUG-2012  IBM Development   Modified CREATE_REPORT and added CREATE_REPORT_TEXT
                                as a backup to the exisitng CREATE_REPORT procedure
                                for Integra
 11-JUN-2013   IBM Development   Added generate_report to display distinct errors for 
                                 AR Open Invoice,Open SO and Supplier conversions                                
*/
----------------------------------------------------------------------
   -- Define all the constants and global variables that will be used in the package
        CN_ENV_NOT_SET     CONSTANT VARCHAR2 (31)   := 'EMF Environment is not properly';
        -- Site level global
        G_DEBUG_ON_OFF_IND          VARCHAR2 (100);
        -- Process level globals
    G_PROCESS_NAME              VARCHAR2 (100);
        G_PROCESS_ID                NUMBER;
        G_SESSION_ID                NUMBER;
        G_DEBUG_ID                  NUMBER;

        G_REQUEST_ID                NUMBER;
        G_DEBUG_LEVEL               NUMBER;
        G_DEBUG_TYPE                VARCHAR2 (100);
        G_ERROR_TAB_IND             VARCHAR2 (100);
        G_ERROR_LOG_IND             VARCHAR2 (100);
        G_PRE_VALID_FLAG            VARCHAR2 (100);
        G_POST_VALID_FLAG           VARCHAR2 (100);
        G_ERROR_HEADER_ID           NUMBER;
        G_ERR_ID                    NUMBER;
        G_TRANSACTION_ID            VARCHAR2 (2000);
        -- Concurrent Request Id
        G_CONC_REQUEST_ID           NUMBER;
        SET_ENV_CONSTANT   CONSTANT CHAR (10)       := ' SET_ENV';
        G_E_REC_ERROR               EXCEPTION;
        G_E_PRC_ERROR               EXCEPTION;
        G_E_ENV_NOT_SET             EXCEPTION;
        --
        TYPE G_XX_EMF_IDENT_REC_TYPE IS RECORD
        (
            record_identifier_1    VARCHAR2 (240),
            record_identifier_2    VARCHAR2 (240),
            record_identifier_3    VARCHAR2 (240),
            record_identifier_4    VARCHAR2 (240),

            record_identifier_5    VARCHAR2 (240)
        );

        TYPE G_XX_EMF_IDENT_TAB_TYPE IS TABLE OF G_XX_EMF_IDENT_REC_TYPE
        INDEX BY BINARY_INTEGER;

        FUNCTION SET_ENV
                RETURN NUMBER;
        FUNCTION SET_ENV (P_PROCESS_NAME VARCHAR2
                         )
                RETURN NUMBER;
        FUNCTION SET_ENV (P_PROCESS_NAME VARCHAR2
                         ,P_REQUEST_ID   NUMBER
                         )
                RETURN NUMBER;
        PROCEDURE SET_TRANSACTION_ID (P_TRANSACTION_ID VARCHAR2);
        PROCEDURE WRITE_LOG (
                P_DEBUG_LEVEL   IN   NUMBER,
                P_DEBUG_TEXT    IN   VARCHAR2,
                P_ATTRIBUTE1    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE2    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE3    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE4    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE5    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE6    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE7    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE8    IN   VARCHAR2 DEFAULT NULL,
                P_ATTRIBUTE9    IN   VARCHAR2 DEFAULT NULL,

                P_ATTRIBUTE10   IN   VARCHAR2 DEFAULT NULL
        );

    PROCEDURE error (
        p_severity               IN   VARCHAR2,
        p_category               IN   VARCHAR2,
        p_error_text             IN   VARCHAR2,
        p_record_identifier_1    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_2    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_3    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_4    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_5    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_6    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_7    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_8    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_9    IN   VARCHAR2 DEFAULT NULL,
        p_record_identifier_10   IN   VARCHAR2 DEFAULT NULL
        );

        PROCEDURE CREATE_REPORT (ERRBUF OUT VARCHAR2, RETCODE OUT VARCHAR2, P_REQUEST_ID IN NUMBER);
        PROCEDURE CREATE_REPORT;
        -- Added by IBM on 03-AUG-2012 as backup to the existing CREATE_REPORT for Integra
        PROCEDURE CREATE_REPORT_TEXT (ERRBUF OUT VARCHAR2, RETCODE OUT VARCHAR2, P_REQUEST_ID IN NUMBER);
        PROCEDURE CREATE_REPORT_TEXT; 
        --Added Added generate_report to display distinct errors for AR Open Invoice,Open SO and Supplier conversions
        PROCEDURE GENERATE_REPORT;
        PROCEDURE GENERATE_REPORT(ERRBUF OUT VARCHAR2, RETCODE OUT VARCHAR2, P_REQUEST_ID IN NUMBER);                        
        PROCEDURE ARCH_PURGE (P_NO_OF_DAYS IN NUMBER);
        PROCEDURE PURGE_ERRORS (ERRBUF OUT VARCHAR2, RETCODE OUT VARCHAR2);
        PROCEDURE PURGE_ERRORS;
        PROCEDURE ARCH_PURGE_ERRORS (ERRBUF OUT VARCHAR2, RETCODE OUT VARCHAR2, P_NO_OF_DAYS IN NUMBER);
        PROCEDURE PROPAGATE_ERROR (P_ERROR_CODE IN VARCHAR2);
        PROCEDURE UPDATE_RECS_CNT (P_TOTAL_RECS_CNT NUMBER, P_SUCCESS_RECS_CNT NUMBER, P_WARNING_RECS_CNT NUMBER, P_ERROR_RECS_CNT NUMBER);
        PROCEDURE bulk_error ( p_severity IN VARCHAR2, p_category IN VARCHAR2, p_error_text IN VARCHAR2,p_rec_ident IN G_XX_EMF_IDENT_TAB_TYPE);

    PROCEDURE put_line ( p_buffer VARCHAR2 );
    PROCEDURE print_debug_log(p_request_id NUMBER);

    FUNCTION  get_paramater_value(p_process_name VARCHAR2,p_parameter_name VARCHAR2) RETURN VARCHAR2;
END XX_EMF_PKG;
/


GRANT EXECUTE ON APPS.XX_EMF_PKG TO INTG_XX_NONHR_RO;
