DROP PACKAGE APPS.XX_QP_MOD_LIST_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_MOD_LIST_CNV_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : Debjani Roy
 Creation Date  : 03-Jun-2013
 File Name      : XXPRCMDFIERTL.pks
 Description    : This script creates the specification of the package xx_price_modifier_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------

----------------------------*------------------------------------------------------------------

 Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ---------------------------------------
1.0     03-Jun-2013 Debjani Roy  Initial development.
-------------------------------------------------------------------------
*/

    CN_MDF_PARENT_IND       CONSTANT    NUMBER := 1;
    CN_API_VER_NO           CONSTANT    NUMBER := 1.0;
    CN_ONE                  CONSTANT    NUMBER := 1;

    G_STAGE         VARCHAR2(2000);
    G_BATCH_ID      VARCHAR2(200);

--    TYPE G_XX_MDF_PRE_REC_TYPE IS RECORD
--    (
--   --
--   -- Add XX_QP_MDFR_LIST_LINES_STG Table Columns
--   --
--       batch_id               VARCHAR2(200),
--       record_number       NUMBER(15),
--       process_code               VARCHAR2(100),
--       error_code               VARCHAR2(100),
--       error_desc              VARCHAR2(1000),
--       created_by               NUMBER,
--       creation_date       DATE,
--       last_update_date	   DATE,
--       last_updated_by	   NUMBER,
--       last_update_login	   NUMBER,
--       request_id	           NUMBER
--       );

    G_XX_MDPR_LINES_PRE_REC_TYPE                  xx_qp_mdpr_list_lines_pre%ROWTYPE;

    G_XX_MDPR_HDR_PRE_REC_TYPE                    xx_qp_mdpr_list_hdr_pre%ROWTYPE;

    g_validate_and_load                           VARCHAR2(100) := 'VALIDATE_AND_LOAD';

    TYPE g_xx_mdpr_lines_pre_tab_type IS TABLE OF xx_qp_mdpr_list_lines_pre%ROWTYPE
    INDEX BY BINARY_INTEGER;

    TYPE g_xx_mdpr_hdr_pre_tab_type   IS TABLE OF xx_qp_mdpr_list_hdr_pre%ROWTYPE
    INDEX BY BINARY_INTEGER;


--    TYPE G_XX_QLF_PRE_REC_TYPE IS RECORD
--    (
--   --
--   -- Add XX_QP_MDFR_LIST_QLF_STG Table Columns
--   --
--       batch_id	           VARCHAR2(200),
--       record_number	   NUMBER(15),
--       process_code	           VARCHAR2(100),
--       error_code	           VARCHAR2(100),
--       error_desc              VARCHAR2(1000),
--       created_by	           NUMBER,
--       creation_date	   DATE,
--       last_update_date	   DATE,
--       last_updated_by	   NUMBER,
--       last_update_login	   NUMBER,
--       request_id	           NUMBER
--       );

    -- Record Type Variable
    G_XX_QLF_PRE_REC_TYPE                  xx_qp_mdpr_list_qlf_pre%ROWTYPE;

    TYPE g_xx_qlf_pre_tab_type IS TABLE OF xx_qp_mdpr_list_qlf_pre%ROWTYPE
    INDEX BY BINARY_INTEGER;

    PROCEDURE process_data_insert_mode (

                errbuf                 OUT VARCHAR2
               ,retcode                OUT  NUMBER
               ,p_batch_id             IN   VARCHAR2
               ,p_custom_batch_no      IN   NUMBER
      );

    PROCEDURE main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2,
            p_validate_and_load IN VARCHAR2
    );

END xx_qp_mod_list_cnv_pkg;
/
