DROP PACKAGE APPS.XX_INV_REVISION_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_REVISION_CNV_PKG" AUTHID CURRENT_USER AS
----------------------------------------------------------------------
/* $Header: XXINVREVCNVTL.pks 1.2 2012/02/15 12:00:00 dsengupta noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 30-Dec-2011
 File Name      : XXINVREVCNVTL.pks
 Description    : This script creates the specification of the Item Revision Conversion translation package

 Change History:

 Version Date        Name			Remarks
 ------- ----------- ----			-------------------------------
 1.0     30-Dec-11   IBM Development Team	Initial development.
*/
----------------------------------------------------------------------


        G_STAGE			VARCHAR2(2000);
        G_BATCH_ID		VARCHAR2(200);
        G_SET_PROCESS_ID	NUMBER;
	G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD'; --DS: Added 30-Jan-12

	TYPE G_XX_INV_REV_STG_REC_TYPE IS RECORD
        (
	  BATCH_ID                   VARCHAR2(240 BYTE),
	  RECORD_NUMBER              NUMBER,
	  INVENTORY_ITEM_ID          NUMBER,
	  ORGANIZATION_ID            NUMBER,
	  REVISION                   VARCHAR2(3),
	  LAST_UPDATE_DATE           DATE,
	  LAST_UPDATED_BY            NUMBER,
	  CREATION_DATE              DATE,
	  CREATED_BY                 NUMBER,
	  LAST_UPDATE_LOGIN          NUMBER,
	  CHANGE_NOTICE              VARCHAR2(10 BYTE),
	  ECN_INITIATION_DATE        DATE,
	  IMPLEMENTATION_DATE        DATE,
	  IMPLEMENTED_SERIAL_NUMBER  VARCHAR2(30 BYTE),
	  EFFECTIVITY_DATE           DATE,
	  ATTRIBUTE_CATEGORY         VARCHAR2(30 BYTE),
	  ATTRIBUTE1                 VARCHAR2(150 BYTE),
	  ATTRIBUTE2                 VARCHAR2(150 BYTE),
	  ATTRIBUTE3                 VARCHAR2(150 BYTE),
	  ATTRIBUTE4                 VARCHAR2(150 BYTE),
	  ATTRIBUTE5                 VARCHAR2(150 BYTE),
	  ATTRIBUTE6                 VARCHAR2(150 BYTE),
	  ATTRIBUTE7                 VARCHAR2(150 BYTE),
	  ATTRIBUTE8                 VARCHAR2(150 BYTE),
	  ATTRIBUTE9                 VARCHAR2(150 BYTE),
	  ATTRIBUTE10                VARCHAR2(150 BYTE),
	  ATTRIBUTE11                VARCHAR2(150 BYTE),
	  ATTRIBUTE12                VARCHAR2(150 BYTE),
	  ATTRIBUTE13                VARCHAR2(150 BYTE),
	  ATTRIBUTE14                VARCHAR2(150 BYTE),
	  ATTRIBUTE15                VARCHAR2(150 BYTE),
	  REVISED_ITEM_SEQUENCE_ID   NUMBER,
	  DESCRIPTION                VARCHAR2(150 BYTE),
	  ITEM_NUMBER                VARCHAR2(700 BYTE),
	  ORGANIZATION_CODE          VARCHAR2(3 BYTE),
	  TRANSACTION_ID	     NUMBER,
	  TRANSACTION_TYPE           VARCHAR2(10 BYTE),
	  PROCESS_CODE               VARCHAR2(240 BYTE),
	  ERROR_CODE                 VARCHAR2(240 BYTE),
	  REQUEST_ID                 NUMBER
	);

      TYPE G_XX_INV_REV_STG_TAB_TYPE IS TABLE OF G_XX_INV_REV_STG_REC_TYPE
      INDEX BY BINARY_INTEGER;

      TYPE G_XX_INV_REV_PRE_REC_TYPE IS RECORD
        (
	  INVENTORY_ITEM_ID          NUMBER,
	  ORGANIZATION_ID            NUMBER,
	  REVISION                   VARCHAR2(3),
	  LAST_UPDATE_DATE           DATE,
	  LAST_UPDATED_BY            NUMBER,
	  CREATION_DATE              DATE,
	  CREATED_BY                 NUMBER,
	  LAST_UPDATE_LOGIN          NUMBER,
	  CHANGE_NOTICE              VARCHAR2(10 BYTE),
	  ECN_INITIATION_DATE        DATE,
	  IMPLEMENTATION_DATE        DATE,
	  IMPLEMENTED_SERIAL_NUMBER  VARCHAR2(30 BYTE),
	  EFFECTIVITY_DATE           DATE,
	  ATTRIBUTE_CATEGORY         VARCHAR2(30 BYTE),
	  ATTRIBUTE1                 VARCHAR2(150 BYTE),
	  ATTRIBUTE2                 VARCHAR2(150 BYTE),
	  ATTRIBUTE3                 VARCHAR2(150 BYTE),
	  ATTRIBUTE4                 VARCHAR2(150 BYTE),
	  ATTRIBUTE5                 VARCHAR2(150 BYTE),
	  ATTRIBUTE6                 VARCHAR2(150 BYTE),
	  ATTRIBUTE7                 VARCHAR2(150 BYTE),
	  ATTRIBUTE8                 VARCHAR2(150 BYTE),
	  ATTRIBUTE9                 VARCHAR2(150 BYTE),
	  ATTRIBUTE10                VARCHAR2(150 BYTE),
	  ATTRIBUTE11                VARCHAR2(150 BYTE),
	  ATTRIBUTE12                VARCHAR2(150 BYTE),
	  ATTRIBUTE13                VARCHAR2(150 BYTE),
	  ATTRIBUTE14                VARCHAR2(150 BYTE),
	  ATTRIBUTE15                VARCHAR2(150 BYTE),
	  REVISED_ITEM_SEQUENCE_ID   NUMBER,
	  DESCRIPTION                VARCHAR2(150 BYTE),
	  ITEM_NUMBER                VARCHAR2(700 BYTE),
	  ORGANIZATION_CODE          VARCHAR2(3 BYTE),
	  TRANSACTION_ID	     NUMBER,
	  TRANSACTION_TYPE           VARCHAR2(10 BYTE),
	  SET_PROCESS_ID             NUMBER,
	  REQUEST_ID                 NUMBER,
	  PROCESS_FLAG               NUMBER,
	  BATCH_ID                   VARCHAR2(240 BYTE),
	  RECORD_NUMBER              NUMBER,
	  PROCESS_CODE               VARCHAR2(240 BYTE),
	  ERROR_CODE                 VARCHAR2(240 BYTE)
	);

      TYPE G_XX_INV_REV_PRE_TAB_TYPE IS TABLE OF G_XX_INV_REV_PRE_REC_TYPE
      INDEX BY BINARY_INTEGER;


        PROCEDURE main (
			errbuf OUT VARCHAR2,
			retcode OUT VARCHAR2,
			p_batch_id IN VARCHAR2,
			p_restart_flag IN VARCHAR2,
			p_override_flag IN VARCHAR2,
			p_validate_and_load IN VARCHAR2
        );

-- Constants defined for version control of all the files of the components
        CN_XXINVITEMCNVVL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXINVITEMCNVVL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXINVITEMCNVTL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXINVITEMCNVTL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';


END xx_inv_revision_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_REVISION_CNV_PKG TO INTG_XX_NONHR_RO;
