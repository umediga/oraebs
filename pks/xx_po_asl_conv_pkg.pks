DROP PACKAGE APPS.XX_PO_ASL_CONV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PO_ASL_CONV_PKG" 
AS
--==================================================================================
  -- Created By     : Kirthana Ramesh
  -- Creation Date  : 23-APR-2013
  -- Filename       : XX_PO_ASL_CONV_PKG.pks
  -- Description    : Package specification for Approved Supplier List Conversion

   -- Change History:

   -- Date           Version#    Name                Remarks
  -- -----------    --------    ---------------     ------------------------------------
  -- 23-APR-2013    1.0         Kirthana Ramesh     Initial version
  -- 30-MAY-2013    1.1         Yogesh              Changed the rec type 'g_asl_rec_type'
--====================================================================================

   --
   --Approved Supplier List Record Type inline with Approved Supplier List record in staging table
   --
   TYPE g_asl_rec_type IS RECORD (
      batch_id                  VARCHAR2 (200),
      record_number             NUMBER,
      source_system_name        VARCHAR2 (30),
      asl_id                    NUMBER,
      using_organization        VARCHAR2 (30),
      using_organization_id     NUMBER,
      owning_organization       VARCHAR2 (30),
      OWNING_ORGANIZATION_ID    NUMBER,
      vendor_business_type      VARCHAR2 (25),
      asl_status                VARCHAR2 (25),
      asl_status_id             NUMBER,
      old_vendor_num            VARCHAR2 (30),
      vendor_id                 NUMBER,
      vendor_site_code          VARCHAR2 (15),
      vendor_site_id            NUMBER,
      item_num                  VARCHAR2 (40),
      item_id                   NUMBER,
      item_category             VARCHAR2 (245),
      category_id               NUMBER,
      primary_vendor_item       VARCHAR2 (25),
      attribute_category        VARCHAR2 (30),
      attribute1                VARCHAR2 (150),
      attribute2                VARCHAR2 (150),
      attribute3                VARCHAR2 (150),
      attribute4                VARCHAR2 (150),
      attribute5                VARCHAR2 (150),
      attribute6                VARCHAR2 (150),
      attribute7                VARCHAR2 (150),
      attribute8                VARCHAR2 (150),
      attribute9                VARCHAR2 (150),
      attribute10               VARCHAR2 (150),
      attribute11               VARCHAR2 (150),
      attribute12               VARCHAR2 (150),
      attribute13               VARCHAR2 (150),
      attribute14               VARCHAR2 (150),
      attribute15               VARCHAR2 (150),
      disable_flag              VARCHAR2 (1),
      process_code              VARCHAR2 (100),
      ERROR_CODE                VARCHAR2 (100),
      request_id                NUMBER,
      program_id                NUMBER,
      program_application_id    NUMBER,
      program_update_date       DATE,
      creation_date             DATE,
      created_by                NUMBER (15),
      last_update_date          DATE,
      last_updated_by           NUMBER (15),
      last_update_login         NUMBER (15),
      vendor_address               VARCHAR2(250),
      VENDOR_NAME            VARCHAR2(100),
      OU_ORGANIZATION_ID        NUMBER
   );

   --
   --Approved Suplier List Table Type for Approved Suplier List Record Type
   --
   TYPE g_asl_tbl_type IS TABLE OF g_asl_rec_type
      INDEX BY BINARY_INTEGER;

   -- Global Variables
   g_stage               VARCHAR2 (2000);
   g_batch_id            VARCHAR2 (200);
   g_comp_batch_id       VARCHAR2 (200);
   g_validate_and_load   VARCHAR2 (100)  := 'VALIDATE_AND_LOAD';
   g_api_name            VARCHAR2 (200);
   g_transaction_type    VARCHAR2 (10)   := NULL;
   g_process_flag        NUMBER          := 1;
   g_request_id          NUMBER       := fnd_profile.VALUE ('CONC_REQUEST_ID');
   g_user_id             NUMBER          := fnd_global.user_id;
   --FND_PROFILE.VALUE('USER_ID');
   g_resp_id             NUMBER          := fnd_profile.VALUE ('RESP_ID');

----------------------------------------------------------------
--Public Procedure/Function Declaration Section
--Purpose-Main calling Procedure to Import Purchase quotations
----------------------------------------------------------------
   PROCEDURE main (
      x_errbuf              OUT      VARCHAR2,
      x_retcode             OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2
   );
END xx_po_asl_conv_pkg;
/
