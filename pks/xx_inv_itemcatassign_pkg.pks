DROP PACKAGE APPS.XX_INV_ITEMCATASSIGN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_ITEMCATASSIGN_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 28-MAR-2012
 File Name      : XXINVITEMCATASSIGNTL.pks
 Description    : This script creates the specification of the package xx_inv_itemcatassign_pkg

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

Version Date		Name			Remarks
------- -----------	----			---------------------------------------
1.0     28-MAR-2012	IBM Development Team	Initial development.
*/
----------------------------------------------------------------------


        G_STAGE         VARCHAR2(2000);
        G_BATCH_ID      VARCHAR2(200);
	G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';
	G_TRANSACTION_TYPE	VARCHAR2(20) := null;

        TYPE G_XX_INV_ITEMCAT_HDR_REC_TYPE IS RECORD
        (
                batch_id                VARCHAR2(200),
                record_number           NUMBER,
                inventory_item_number   NUMBER,
                organization_code       VARCHAR2(10),
                category_set_name       VARCHAR2(30),
                category_name           VARCHAR2(240),
                transaction_type        VARCHAR2(10),
                old_category_name       VARCHAR2(81),
                process_code            VARCHAR2(100),
                error_code              VARCHAR2(100),
                request_id              NUMBER
        );

        TYPE G_XX_INV_ITEMCAT_TAB_TYPE IS TABLE OF G_XX_INV_ITEMCAT_HDR_REC_TYPE
        INDEX BY BINARY_INTEGER;


        TYPE G_XX_INV_ITEMCAT_PRE_REC_TYPE IS RECORD
        (
                batch_id                VARCHAR2(200),
                record_number           NUMBER,
                inventory_item_number   VARCHAR2(40),
                organization_code       VARCHAR2(10),
                category_set_name       VARCHAR2(40),
                category_name           VARCHAR2(240),
                transaction_type        VARCHAR2(10),
                --old_category_name       VARCHAR2(40),
                set_process_id          NUMBER,
                inventory_item_id       NUMBER,
                organization_id         NUMBER,
                category_id             NUMBER,
                category_set_id         NUMBER,
                --old_category_id         NUMBER,
                process_code            VARCHAR2(100),
                error_code              VARCHAR2(100),
                request_id              NUMBER
        );

        TYPE G_XX_INV_ITEMCAT_PRE_TAB_TYPE IS TABLE OF G_XX_INV_ITEMCAT_PRE_REC_TYPE
        INDEX BY BINARY_INTEGER;


        PROCEDURE main (
                errbuf OUT VARCHAR2,
                retcode OUT VARCHAR2,
                p_batch_id IN VARCHAR2,
                p_restart_flag IN VARCHAR2,
                p_override_flag IN VARCHAR2,
		p_validate_and_load IN VARCHAR2,
		p_transaction_type IN VARCHAR2);
/*
-- Constants defined for version control of all the files of the components
        CN_XXASLCNVVL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXASLCNVVL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXASLCNVTL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXASLCNVTL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXASLCNVT1_TBL              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXASLCNVT1_SYN              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXASLCNVT2_TBL              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXASLCNVT2_SYN              CONSTANT VARCHAR2 (6)    := '1.0';
*/


END xx_inv_itemcatassign_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEMCATASSIGN_PKG TO INTG_XX_NONHR_RO;
