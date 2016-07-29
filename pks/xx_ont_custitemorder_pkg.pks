DROP PACKAGE APPS.XX_ONT_CUSTITEMORDER_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_CUSTITEMORDER_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 30-AUG-2013
 File Name      : XXONTITEMORDERTL.pks
 Description    : This script creates the specification of the package xx_ont_custitemorder_pkg

Change History:

Version Date		Name			Remarks
------- -----------	----			---------------------------------------
1.0     30-AUG-2013	Mou Mukherjee	Initial development.
*/
----------------------------------------------------------------------


        G_STAGE         VARCHAR2(2000);
        G_BATCH_ID      VARCHAR2(200);
	G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';

        TYPE G_XX_ITEMORDER_HDR_REC_TYPE IS RECORD
        (
BATCH_ID                NUMBER,
SEQUENCE_NUM               NUMBER,
CRITERIA                VARCHAR2(1),
ITEM_NUMBER                VARCHAR2(100),
CAT_SEG1               VARCHAR2(50),
CAT_SEG2               VARCHAR2(50),
CAT_SEG3               VARCHAR2(50),
CAT_SEG4               VARCHAR2(50),
CAT_SEG5               VARCHAR2(50),
CAT_SEG6               VARCHAR2(50),
RULE_LEVEL              VARCHAR2(100),
RULE_LEVEL_VALUE	VARCHAR2(400),
SOURCE_INV_CODE         VARCHAR2(100),
START_DATE              DATE,
END_DATE                DATE,
RESTRICTION_TYPE        VARCHAR2(100),
REGISTRATION_NUM        VARCHAR2(100),
NOTE                    VARCHAR2(240),
ATTRIBUTE1              VARCHAR2(240),
ATTRIBUTE2              VARCHAR2(240),
ATTRIBUTE3              VARCHAR2(240),
ATTRIBUTE4              VARCHAR2(240),
ATTRIBUTE5              VARCHAR2(240),
ATTRIBUTE6              VARCHAR2(240),
ATTRIBUTE7              VARCHAR2(240),
ATTRIBUTE8              VARCHAR2(240),
ATTRIBUTE9              VARCHAR2(240),
ATTRIBUTE10             VARCHAR2(240),
PROCESS_CODE                VARCHAR2(100),
ERROR_CODE                  VARCHAR2(100),
REQUEST_ID                  NUMBER,
CREATED_BY              NUMBER,
CREATION_DATE           DATE,
LAST_UPDATED_BY         NUMBER,
LAST_UPDATE_DATE        DATE
	);

        TYPE G_XX_ITEMORDER_TAB_TYPE IS TABLE OF G_XX_ITEMORDER_HDR_REC_TYPE
        INDEX BY BINARY_INTEGER;


        TYPE G_XX_ITEMORDER_PRE_REC_TYPE IS RECORD
        (
	    BATCH_ID                NUMBER,
SEQUENCE_NUM                NUMBER,
CRITERIA                VARCHAR2(1),
ITEM_NUMBER                VARCHAR2(100),
INVENTORY_ITEM_ID	    NUMBER,
CAT_SEG1               VARCHAR2(50),
CAT_SEG2               VARCHAR2(50),
CAT_SEG3               VARCHAR2(50),
CAT_SEG4               VARCHAR2(50),
CAT_SEG5               VARCHAR2(50),
CAT_SEG6               VARCHAR2(50),
RULE_LEVEL		    VARCHAR2(100),
RULE_LEVEL_VALUE	    VARCHAR2(400),
CUSTOMER_ID           NUMBER,
CUSTOMER_CLASS_ID     NUMBER,
END_CUSTOMER_ID       NUMBER,
CUSTOMER_CATEGORY_CODE  VARCHAR2(100),
CUSTOMER_CLASS_CODE	  VARCHAR2(100),
ORDER_TYPE_ID         NUMBER,
SALES_CHANNEL_CODE    VARCHAR2(100),
SALES_PERSON_ID       NUMBER,
SHIP_TO_LOCATION_ID   NUMBER,
BILL_TO_LOCATION_ID   NUMBER,
DELIVER_TO_LOCATION_ID NUMBER,
REGION_ID             NUMBER,
SOURCE_INV_CODE         VARCHAR2(100),
START_DATE              DATE,
END_DATE                DATE,
RESTRICTION_TYPE        VARCHAR2(100),
REGISTRATION_NUM        VARCHAR2(100),
NOTE                    VARCHAR2(240),
ATTRIBUTE1		    VARCHAR2(250),
ATTRIBUTE2		    VARCHAR2(250),
ATTRIBUTE3		    VARCHAR2(250),
ATTRIBUTE4		    VARCHAR2(250),
ATTRIBUTE5		    VARCHAR2(250),
ATTRIBUTE6		    VARCHAR2(250),
ATTRIBUTE7		    VARCHAR2(250),
ATTRIBUTE8		    VARCHAR2(250),
ATTRIBUTE9		    VARCHAR2(250),
ATTRIBUTE10		    VARCHAR2(250),
PROCESS_CODE                VARCHAR2(100),
ERROR_CODE                  VARCHAR2(100),
REQUEST_ID                  NUMBER,
CREATED_BY              NUMBER,
CREATION_DATE           DATE,
LAST_UPDATED_BY         NUMBER,
LAST_UPDATE_DATE        DATE
	);

        TYPE G_XX_ITEMORDER_PRE_TAB_TYPE IS TABLE OF G_XX_ITEMORDER_PRE_REC_TYPE
        INDEX BY BINARY_INTEGER;


        PROCEDURE main (
                errbuf OUT VARCHAR2,
                retcode OUT VARCHAR2,
                p_batch_id IN VARCHAR2,
                p_restart_flag IN VARCHAR2,
                p_override_flag IN VARCHAR2,
		p_validate_and_load IN VARCHAR2);

END xx_ont_custitemorder_pkg;
/
