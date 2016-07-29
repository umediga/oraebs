DROP PACKAGE APPS.XX_MTL_STOCKLOC_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_MTL_STOCKLOC_CONVERSION_PKG" AS
/* $Header: XXMTLSTOCKLOCCNV.pks 1.0.0 2012/03/15 00:00:00$ */ 
--=================================================================================
  -- Created By     : Arjun.K 
  -- Creation Date  : 14-MAR-2012
  -- Filename       : XXMTLSTOCKLOCCNV.pks
  -- Description    : Package specification for Inventory stock locator conversion.

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ----------------------------
  -- 14-MAR-2012   1.0         Arjun.K             Initial Development.
  -- 30-MAY-2013   1.1         Mou Mukherjee       Added the field source_system_name in g_xxmtl_stockloc_stg_rec_type
--==================================================================================

   -- Global Variables
   G_STAGE                        VARCHAR2(2000);
   G_BATCH_ID                     VARCHAR2(200);
   G_COMP_BATCH_ID                VARCHAR2(200);
   G_VALIDATE_AND_LOAD            VARCHAR2(100) := 'VALIDATE_AND_LOAD';
   G_VALIDATE_FLAG                BOOLEAN       := TRUE;
   G_REQUEST_ID                   NUMBER        := fnd_profile.value('CONC_REQUEST_ID');
   G_USER_ID                      NUMBER        := fnd_global.user_id;
   G_RESP_ID                      NUMBER        := fnd_profile.VALUE('RESP_ID');
   G_API_NAME                     VARCHAR2(200);
   G_LOCATOR_TYPE                 VARCHAR2(200) := 'INTG_INV_LOCATOR_TYPE';
   G_LOCATOR_CLASS                VARCHAR2(200) := 'INTG_INV_LOCATOR_ABC_CLASS';
   
   TYPE g_xxmtl_stockloc_stg_rec_type  IS RECORD 
                 (organization_code           VARCHAR2(3)
                 ,organization_id             NUMBER
                 ,subinventory_code           VARCHAR2(10)
                 ,loc_segment1                VARCHAR2(40)
                 ,loc_segment2                VARCHAR2(40)
                 ,loc_segment3                VARCHAR2(40)
                 ,loc_segment3a               VARCHAR2(40)
                 ,loc_segment3b               VARCHAR2(40)
                 ,conc_segment                VARCHAR2 (150)
                 ,status_code                 VARCHAR2(80)
                 ,status_id                   NUMBER
                 ,inventory_location_type     VARCHAR2(80)
                 ,inventory_location_type_id  NUMBER
                 ,picking_order               NUMBER
                 ,dimension_uom               VARCHAR2(3)
                 ,length                      NUMBER
                 ,width                       NUMBER
                 ,height                      NUMBER
                 ,dff_locator_segment1        VARCHAR2(150)
                 ,dff_locator_segment2        VARCHAR2(150)
                 ,alias                       VARCHAR2(150)
                 ,inventory_location_id       NUMBER
                 ,batch_id                    VARCHAR2(150)
                 ,record_number               NUMBER(15,0)
		 ,source_system_name          VARCHAR2(150)
                 ,process_code                VARCHAR2(100)
                 ,error_code                  VARCHAR2(100)
                 ,created_by                  NUMBER(15,0)
                 ,creation_date               DATE
                 ,last_update_date            DATE
                 ,last_updated_by             NUMBER(15,0)
                 ,last_update_login           NUMBER(15,0)
                 ,request_id                  NUMBER(15,0)
                 ,program_application_id      NUMBER(15,0)
                 ,program_id                  NUMBER(15,0)
                 ,program_update_date         DATE
                 );

   -- Stock Locator Staging Table Type
   TYPE g_xxmtl_stockloc_stg_tab_type IS TABLE OF g_xxmtl_stockloc_stg_rec_type 
   INDEX BY BINARY_INTEGER;

   PROCEDURE main(x_errbuf              OUT   VARCHAR2
                 ,x_retcode             OUT   VARCHAR2
                 ,p_batch_id            IN    VARCHAR2
                 ,p_restart_flag        IN    VARCHAR2
                 ,p_validate_and_load   IN    VARCHAR2
                 );

END xx_mtl_stockloc_conversion_pkg;
/


GRANT EXECUTE ON APPS.XX_MTL_STOCKLOC_CONVERSION_PKG TO INTG_XX_NONHR_RO;
