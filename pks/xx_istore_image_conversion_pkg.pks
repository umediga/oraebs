DROP PACKAGE APPS.XX_ISTORE_IMAGE_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ISTORE_IMAGE_CONVERSION_PKG" AS
/* $Header: xx_istore_image_conversion_pkg.pks 1.0.0 2012/04/03 00:00:00$ */
--=================================================================================
  -- Created By     : Meghana R
  -- Creation Date  : 3-APR-2012
  -- Filename       : xx_istore_image_conversion_pkg.pks
  -- Description    : Package specification for Istore Image conversion.

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ----------------------------
  -- 3-APR-2012   1.0         Meghana R             Initial Development.
--==================================================================================

   -- Global Variables
   G_STAGE                        VARCHAR2(2000);
   G_BATCH_ID                     VARCHAR2(200);
   G_COMP_BATCH_ID                VARCHAR2(200);

   G_VALIDATE_FLAG                BOOLEAN       := TRUE;
   G_REQUEST_ID                   NUMBER        := fnd_profile.value('CONC_REQUEST_ID');
   G_USER_ID                      NUMBER        := fnd_global.user_id;
   G_RESP_ID                      NUMBER        := fnd_profile.VALUE('RESP_ID');
   G_API_NAME                     VARCHAR2(200);

   G_VALIDATE_AND_LOAD            VARCHAR2(100); --:= 'VALIDATE_AND_LOAD';
   GV_ITEM_APPLICABLE_TO          VARCHAR2(200); -- := 'CATEGORY';
   G_API_VERSION                  NUMBER; --:= 1.0;
   GV_OBJECT_TYPE_CODE            VARCHAR2(200);  --:= 'I';
   GV_CONTEXT_ID                  NUMBER ; --:= 7006;
   G_MASTER_ORG                   mtl_parameters.organization_code%TYPE; --:='MST';
   G_LANGUAGE                     VARCHAR2(50);

   --g_xxistore_img_stg_rec_type  xx_istore_img_stg% ROWTYPE;

   TYPE g_xxistore_img_stg_rec_type  IS RECORD
         (SEGMENT1                VARCHAR2(250 BYTE),
          IMAGE_FILE_NAME         VARCHAR2(600 BYTE),
          SITE_CODE               VARCHAR2(150 BYTE),
          LANG_CODE               VARCHAR2(150 BYTE),
          SITE_ID                 NUMBER,
          BATCH_ID                VARCHAR2(150 BYTE),
          RECORD_NUMBER           NUMBER(15),
          PROCESS_CODE            VARCHAR2(100 BYTE),
          ERROR_CODE              VARCHAR2(100 BYTE),
          ERROR_DESC              VARCHAR2(4000 BYTE),
          CREATED_BY              NUMBER(15),
          CREATION_DATE           DATE,
          LAST_UPDATE_DATE        DATE,
          LAST_UPDATED_BY         NUMBER(15),
          LAST_UPDATE_LOGIN       NUMBER(15),
          REQUEST_ID              NUMBER(15),
          PROGRAM_APPLICATION_ID  NUMBER(15),
          PROGRAM_ID              NUMBER(15),
          PROGRAM_UPDATE_DATE     DATE,
          INVENTORY_ITEM_ID       NUMBER,
          deliverable_id          NUMBER);


   TYPE g_xxistore_img_stg_tab_type IS TABLE OF g_xxistore_img_stg_rec_type --xx_istore_img_stg%ROWTYPE --g_xxistore_img_stg_rec_type
   INDEX BY BINARY_INTEGER;

   PROCEDURE main(x_errbuf              OUT   VARCHAR2
                 ,x_retcode             OUT   VARCHAR2
                 ,p_batch_id            IN    VARCHAR2
                 ,p_restart_flag        IN    VARCHAR2
                 ,p_validate_and_load   IN    VARCHAR2
                 );

END xx_istore_image_conversion_pkg;
/


GRANT EXECUTE ON APPS.XX_ISTORE_IMAGE_CONVERSION_PKG TO INTG_XX_NONHR_RO;
