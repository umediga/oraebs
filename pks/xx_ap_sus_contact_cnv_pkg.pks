DROP PACKAGE APPS.XX_AP_SUS_CONTACT_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AP_SUS_CONTACT_CNV_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 06-FEB-2011
 File Name     : XXAPSUSCONTCNV.pks
 Description   : This script creates the specification of the package
                 XX_AP_SUS_CONTACT_CNV_PKG
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 06-FEB-2011 Sharath Babu          Initial Version
*/
----------------------------------------------------------------------
   g_stage               VARCHAR2 (2000);
   g_batch_id            VARCHAR2 (200);
   --Validate only check
   g_validate_and_load   VARCHAR2 (100)  := 'VALIDATE_AND_LOAD';

   TYPE g_xx_sus_cont_stg_rec_type IS RECORD (
      batch_id                 VARCHAR2 (200),
      record_number            NUMBER,
      vendor_site_code         VARCHAR2 (30),
      operating_unit_name      VARCHAR2 (300),
      inactive_date            DATE,
      first_name               VARCHAR2 (30),
      middle_name              VARCHAR2 (30),
      last_name                VARCHAR2 (60),
      prefix                   VARCHAR2 (30),
      title                    VARCHAR2 (30),
      mail_stop                VARCHAR2 (40),
      area_code                VARCHAR2 (30),
      phone                    VARCHAR2 (40),
      department               VARCHAR2 (250),
      email_address            VARCHAR2 (2000),
      url                      VARCHAR2 (2000),
      alt_area_code            VARCHAR2 (30),
      alt_phone                VARCHAR2 (30),
      fax_area_code            VARCHAR2 (30),
      fax                      VARCHAR2 (40),
      legacy_supplier_number   VARCHAR2 (30),
      process_code             VARCHAR2 (100),
      ERROR_CODE               VARCHAR2 (100),
      created_by               NUMBER,
      creation_date            DATE,
      last_update_date         DATE,
      last_updated_by          NUMBER,
      last_update_login        NUMBER,
      request_id               NUMBER
   );

   TYPE g_xx_sus_cont_stg_tab_type IS TABLE OF g_xx_sus_cont_stg_rec_type
      INDEX BY BINARY_INTEGER;

   TYPE g_xx_sus_cont_pre_std_rec_type IS RECORD (
      vendor_site_id                   NUMBER,
      org_id                           NUMBER (15),
      operating_unit_name              VARCHAR2 (240),
      inactive_date                    DATE,
      first_name                       VARCHAR2 (15),
      middle_name                      VARCHAR2 (15),
      last_name                        VARCHAR2 (60),
      prefix                           VARCHAR2 (30),
      title                            VARCHAR2 (30),
      mail_stop                        VARCHAR2 (35),
      area_code                        VARCHAR2 (10),
      phone                            VARCHAR2 (40),
      program_application_id           NUMBER,
      program_id                       NUMBER,
      program_update_date              DATE,
      request_id                       NUMBER,
      contact_name_alt                 VARCHAR2 (320),
      first_name_alt                   VARCHAR2 (230),
      last_name_alt                    VARCHAR2 (230),
      department                       VARCHAR2 (230),
      email_address                    VARCHAR2 (2000),
      url                              VARCHAR2 (2000),
      alt_area_code                    VARCHAR2 (10),
      alt_phone                        VARCHAR2 (15),
      fax_area_code                    VARCHAR2 (10),
      fax                              VARCHAR2 (40),
      vendor_interface_id              NUMBER (15),
      vendor_id                        NUMBER (15),
      vendor_contact_interface_id      NUMBER (15),
      party_site_id                    NUMBER (15),
      party_site_name                  VARCHAR2 (240),
      party_orig_system                VARCHAR2 (30),
      party_orig_system_reference      VARCHAR2 (255),
      party_site_orig_system           VARCHAR2 (30),
      party_site_orig_sys_reference    VARCHAR2 (255),
      supplier_site_orig_system        VARCHAR2 (30),
      sup_site_orig_system_reference   VARCHAR2 (255),
      contact_orig_system              VARCHAR2 (30),
      contact_orig_system_reference    VARCHAR2 (255),
      party_id                         NUMBER (15),
      per_party_id                     NUMBER (15),
      rel_party_id                     NUMBER (15),
      relationship_id                  NUMBER (15),
      org_contact_id                   NUMBER (15),
      vendor_site_code                 VARCHAR2 (15),
      legacy_supplier_number           VARCHAR2 (30),
      process_code                     VARCHAR2 (100),
      ERROR_CODE                       VARCHAR2 (100),
      record_number                    NUMBER,
      batch_id                         VARCHAR2 (200),
      creation_date                    DATE,
      created_by                       NUMBER (15),
      last_update_date                 DATE,
      last_updated_by                  NUMBER (15),
      last_update_login                NUMBER (15)
   );

   TYPE g_xx_sus_cont_pre_std_tab_type IS TABLE OF g_xx_sus_cont_pre_std_rec_type
      INDEX BY BINARY_INTEGER;

   PROCEDURE main (
      errbuf                OUT      VARCHAR2,
      retcode               OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2
   );
END xx_ap_sus_contact_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_AP_SUS_CONTACT_CNV_PKG TO INTG_XX_NONHR_RO;
