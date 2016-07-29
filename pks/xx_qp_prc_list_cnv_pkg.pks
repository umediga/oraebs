DROP PACKAGE APPS.XX_QP_PRC_LIST_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_PRC_LIST_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : Debjani Roy
 Creation Date  : 24-MAY-2013
 File Name      : XXQPPRICELISTCNVTL.pks
 Description    : This script creates the specification of the package xx_qp_price_list_cnv_pkg
----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------
-- CCID004                  *  Change the package name in line number 9 and 90 of this file  --
----------------------------*------------------------------------------------------------------
-- CCID005                  *  Change the columns in Type defnitions line 40, 56             --
----------------------------*------------------------------------------------------------------
-- CCID006                  *  Modify the parameters to procedure main line 79               --
--                          *  Retain p_batch_id, p_restart_flag, p_override_flag            --
----------------------------*------------------------------------------------------------------

 Change History:

Version Date        Name               Remarks
------- ----------- ----               ---------------------------------------
1.0     24-MAY-2013   Debjani Roy       Initial development.
*/
----------------------------------------------------------------------


        G_STAGE         VARCHAR2(2000);
        G_BATCH_ID      VARCHAR2(200);
        g_validate_and_load                    VARCHAR2(100) := 'VALIDATE_AND_LOAD';

        G_XX_QP_PL_HDR_STG_REC_TYPE   xx_qp_pr_list_hdr_stg%ROWTYPE;
        G_XX_QP_PL_LINES_STG_REC_TYPE xx_qp_pr_list_lines_stg%ROWTYPE;
        G_XX_QP_PL_QLF_STG_REC_TYPE   xx_qp_pr_list_qlf_stg%ROWTYPE;

        TYPE G_XX_QP_PL_HDR_STG_TAB_TYPE IS TABLE OF G_XX_QP_PL_HDR_STG_REC_TYPE%ROWTYPE
        INDEX BY BINARY_INTEGER;

        TYPE G_XX_QP_PL_LINES_STG_TAB_TYPE IS TABLE OF G_XX_QP_PL_LINES_STG_REC_TYPE%ROWTYPE
        INDEX BY BINARY_INTEGER;

        TYPE G_XX_QP_PL_QLF_STG_TAB_TYPE IS TABLE OF G_XX_QP_PL_QLF_STG_REC_TYPE%ROWTYPE
        INDEX BY BINARY_INTEGER;

        G_XX_QP_PL_HDR_PRE_REC_TYPE      xx_qp_pr_list_hdr_pre%ROWTYPE;
        G_XX_QP_PL_LINES_PRE_REC_TYPE    xx_qp_pr_list_lines_pre%ROWTYPE;
        G_XX_QP_PL_QLF_PRE_REC_TYPE      xx_qp_pr_list_qlf_pre%ROWTYPE;


        TYPE G_XX_QP_PL_HDR_PRE_TAB_TYPE IS TABLE OF G_XX_QP_PL_HDR_PRE_REC_TYPE%ROWTYPE
        INDEX BY BINARY_INTEGER;

        TYPE G_XX_QP_PL_LINES_PRE_TAB_TYPE IS TABLE OF G_XX_QP_PL_LINES_PRE_REC_TYPE%ROWTYPE
        INDEX BY BINARY_INTEGER;

        TYPE G_XX_QP_PL_QLF_PRE_TAB_TYPE IS TABLE OF G_XX_QP_PL_QLF_PRE_REC_TYPE%ROWTYPE
        INDEX BY BINARY_INTEGER;

      PROCEDURE process_data_insert_mode (

     errbuf                 OUT VARCHAR2
               ,retcode                OUT  NUMBER
               ,p_batch_id             IN   VARCHAR2
               ,p_custom_batch_no      IN   NUMBER
      );
      --RETURN NUMBER;

       FUNCTION process_data_update_mode (
             /*p_header_line     IN  VARCHAR2
            ,*/p_list_header_id  IN   NUMBER
      )
      RETURN NUMBER;



      PROCEDURE main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2,
            p_validate_and_load   IN VARCHAR2
        );


END xx_qp_prc_list_cnv_pkg;
/
