DROP PACKAGE APPS.XX_ONT_ITEMORD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_ITEMORD_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 21-MAY-2012
 File Name      : XXONTITEMORDTL.pks
 Description    : This script creates the specification of the package xx_ont_itemord_pkg

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
1.0     21-MAY-2012	IBM Development Team	Initial development.
*/
----------------------------------------------------------------------


        G_STAGE         VARCHAR2(2000);
        G_BATCH_ID      VARCHAR2(200);
	G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';

        TYPE G_XX_ONT_ITEMORD_HDR_REC_TYPE IS RECORD
        (
	    operating_unit	    VARCHAR2(240),
	    criteria		    VARCHAR2(40),
	    item_number		    VARCHAR2(40),
	    category_name           VARCHAR2(100),
	    general_available       VARCHAR2(10),
	    rule_level		    VARCHAR2(40),
	    rule_level_value	    VARCHAR2(400),
	    enabled		    VARCHAR2(40),
	    context		    VARCHAR2(250),
	    attribute1		    VARCHAR2(250),
	    attribute2		    VARCHAR2(250),
	    attribute3		    VARCHAR2(250),
	    attribute4		    VARCHAR2(250),
	    attribute5		    VARCHAR2(250),
	    attribute6		    VARCHAR2(250),
	    attribute7		    VARCHAR2(250),
	    attribute8		    VARCHAR2(250),
	    attribute9		    VARCHAR2(250),
	    attribute10		    VARCHAR2(250),
	    attribute11		    VARCHAR2(250),
	    attribute12		    VARCHAR2(250),
	    attribute13		    VARCHAR2(250),
	    attribute14		    VARCHAR2(250),
	    attribute15		    VARCHAR2(250),
	    attribute16		    VARCHAR2(250),
	    attribute17		    VARCHAR2(250),
	    attribute18		    VARCHAR2(250),
	    attribute19		    VARCHAR2(250),
	    attribute20		    VARCHAR2(250),
	    batch_id                VARCHAR2(200),
	    record_number           NUMBER,
	    process_code            VARCHAR2(100),
	    error_code              VARCHAR2(100),
	    creation_date           DATE,
	    created_by              NUMBER,
	    last_update_date        DATE,
	    last_updated_by         NUMBER,
	    last_update_login       NUMBER,
	    request_id              NUMBER
	);

        TYPE G_XX_ONT_ITEMORD_TAB_TYPE IS TABLE OF G_XX_ONT_ITEMORD_HDR_REC_TYPE
        INDEX BY BINARY_INTEGER;


        TYPE G_XX_ONT_ITEMORD_PRE_REC_TYPE IS RECORD
        (
	    operating_unit	    VARCHAR2(240),
	    org_id		    NUMBER,
	    criteria		    VARCHAR2(40),
	    item_number		    VARCHAR2(40),
	    inventory_item_id	    NUMBER,
	    category_name           VARCHAR2(100),
	    category_id		    NUMBER,
	    general_available       VARCHAR2(10),
	    rule_level		    VARCHAR2(40),
	    rule_level_value	    VARCHAR2(400),
	    rule_value_id	    NUMBER,
	    enabled		    VARCHAR2(40),
	    context		    VARCHAR2(250),
	    attribute1		    VARCHAR2(250),
	    attribute2		    VARCHAR2(250),
	    attribute3		    VARCHAR2(250),
	    attribute4		    VARCHAR2(250),
	    attribute5		    VARCHAR2(250),
	    attribute6		    VARCHAR2(250),
	    attribute7		    VARCHAR2(250),
	    attribute8		    VARCHAR2(250),
	    attribute9		    VARCHAR2(250),
	    attribute10		    VARCHAR2(250),
	    attribute11		    VARCHAR2(250),
	    attribute12		    VARCHAR2(250),
	    attribute13		    VARCHAR2(250),
	    attribute14		    VARCHAR2(250),
	    attribute15		    VARCHAR2(250),
	    attribute16		    VARCHAR2(250),
	    attribute17		    VARCHAR2(250),
	    attribute18		    VARCHAR2(250),
	    attribute19		    VARCHAR2(250),
	    attribute20		    VARCHAR2(250),
	    batch_id                VARCHAR2(200),
	    record_number           NUMBER,
	    process_code            VARCHAR2(100),
	    error_code              VARCHAR2(100),
	    creation_date           DATE,
	    created_by              NUMBER,
	    last_update_date        DATE,
	    last_updated_by         NUMBER,
	    last_update_login       NUMBER,
	    request_id              NUMBER
	);

        TYPE G_XX_ONT_ITEMORD_PRE_TAB_TYPE IS TABLE OF G_XX_ONT_ITEMORD_PRE_REC_TYPE
        INDEX BY BINARY_INTEGER;


        PROCEDURE main (
                errbuf OUT VARCHAR2,
                retcode OUT VARCHAR2,
                p_batch_id IN VARCHAR2,
                p_restart_flag IN VARCHAR2,
                p_override_flag IN VARCHAR2,
		p_validate_and_load IN VARCHAR2);

END xx_ont_itemord_pkg;
/


GRANT EXECUTE ON APPS.XX_ONT_ITEMORD_PKG TO INTG_XX_NONHR_RO;
