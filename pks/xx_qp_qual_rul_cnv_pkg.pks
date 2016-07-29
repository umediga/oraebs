DROP PACKAGE APPS.XX_QP_QUAL_RUL_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_QUAL_RUL_CNV_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : DebJANI Roy
 Creation Date  : 02-jUN-2013
 File Name      : XXQPPRCQUALTL.pks
 Description    : This script creates the specification of the package xx_price_list_qualifier_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------

----------------------------*------------------------------------------------------------------

 Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ---------------------------------------
1.0     02-JUN-2013 DebJANI Roy  Initial development.
-------------------------------------------------------------------------
*/

    CN_MDF_PARENT_IND       CONSTANT    NUMBER := 1;
    CN_API_VER_NO           CONSTANT    NUMBER := 1.0;
    CN_ONE                  CONSTANT    NUMBER := 1;

    G_STAGE         VARCHAR2(2000);
    G_BATCH_ID      VARCHAR2(200);

    g_validate_and_load                    VARCHAR2(100) := 'VALIDATE_AND_LOAD';

    G_XX_QLF_PRE_REC_TYPE                  XX_QP_RULES_QLF_PRE%ROWTYPE;

    TYPE g_xx_qlf_pre_tab_type IS TABLE OF XX_QP_RULES_QLF_PRE%ROWTYPE
    INDEX BY BINARY_INTEGER;

    PROCEDURE main (
                     errbuf          OUT VARCHAR2,
                     retcode         OUT VARCHAR2,
                     p_batch_id      IN VARCHAR2,
                     p_restart_flag  IN VARCHAR2,
                     p_override_flag IN VARCHAR2,
                     p_validate_and_load   IN VARCHAR2
                    );

END xx_qp_qual_rul_cnv_pkg;
/
