DROP PACKAGE APPS.XX_BOM_DEPARTMENT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BOM_DEPARTMENT_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 08-Dec-2013
File Name     : XXBOMDEPT.pks
Description   : This script creates the specification of the package xx_bom_department_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
08-Dec-2013  NARENDRA YADAV         Initial Draft.
*/
----------------------------------------------------------------------

   -- Global Variables
   G_STAGE               VARCHAR2 (2000);
   G_BATCH_ID            VARCHAR2 (200);
   G_API_NAME            VARCHAR2 (100);
   G_VALIDATE_AND_LOAD   VARCHAR2 (100)          := 'VALIDATE_AND_LOAD';
   G_CREATED_BY_MODULE   CONSTANT VARCHAR2 (20)  := 'TCA_V2_API';

   TYPE g_xx_bom_department_rec_type
   IS
   RECORD (
		BATCH_ID			      VARCHAR2(50 BYTE),
		SOURCE_SYSTEM_NAME 	VARCHAR2(10 BYTE),
		RECORD_NUMBER 		  NUMBER,
		DEPARTMENT_CODE		  VARCHAR2(10 BYTE),
		DEPARTMENT_ID		    NUMBER,
		DESCRIPTION			    VARCHAR2(100 BYTE),
		ORG_CODE			      VARCHAR2(100 BYTE),
		ORG_ID				      NUMBER,
		DEPT_COST_CAT		    VARCHAR2(50 BYTE),
		DEPT_COST_CAT_CODE	VARCHAR2(50 BYTE),
		DEPT_CLASS_CODE		  VARCHAR2(50 BYTE),
		LOCATION			      VARCHAR2(100 BYTE),
		LOCATION_ID			    NUMBER,
		PROJ_EXP_ORG		    VARCHAR2(100 BYTE),
		PROJ_EXP_ORG_ID		  NUMBER,
		INACTIVE_DATE		    DATE,
		ATTRIBUTE_CATEGORY	VARCHAR2(50 BYTE),
		ATTRIBUTE1			    VARCHAR2(100 BYTE),
		ATTRIBUTE2			    VARCHAR2(100 BYTE),
		ATTRIBUTE3			    VARCHAR2(100 BYTE),
		ATTRIBUTE4			    VARCHAR2(100 BYTE),
		ATTRIBUTE5			    VARCHAR2(100 BYTE),
		ATTRIBUTE6			    VARCHAR2(100 BYTE),
		ATTRIBUTE7			    VARCHAR2(100 BYTE),
		ATTRIBUTE8			    VARCHAR2(100 BYTE),
		ATTRIBUTE9			    VARCHAR2(100 BYTE),
		ATTRIBUTE10			    VARCHAR2(100 BYTE),
		ATTRIBUTE11			    VARCHAR2(100 BYTE),
		ATTRIBUTE12			    VARCHAR2(100 BYTE),
		ATTRIBUTE13			    VARCHAR2(100 BYTE),
		ATTRIBUTE14			    VARCHAR2(100 BYTE),
		ATTRIBUTE15			    VARCHAR2(100 BYTE),
		REQUEST_ID			    NUMBER,
		LAST_UPDATED_BY		  NUMBER,
		LAST_UPDATE_DATE	  DATE,
		PHASE_CODE			    VARCHAR2(50 BYTE),
		ERROR_CODE			    VARCHAR2(10 BYTE),
		ERROR_MSG			      VARCHAR2(240 BYTE)
      );


   TYPE xx_bom_department_tab_type IS TABLE OF xxconv.xxbom_department_stg%ROWTYPE
   INDEX BY BINARY_INTEGER;

    g_miss_bom_department_tab        xx_bom_department_tab_type;

    g_miss_bom_department_rec        xxconv.xxbom_department_stg%ROWTYPE;

   -- Main Procedure
   PROCEDURE main (errbuf                   OUT VARCHAR2,
                   retcode                  OUT VARCHAR2,
                   p_batch_id               IN  VARCHAR2,
                   p_restart_flag           IN  VARCHAR2,
                   p_validate_and_load      IN  VARCHAR2);


END xx_bom_department_pkg;
/
