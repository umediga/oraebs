DROP PACKAGE APPS.XX_GL_CONS_FFIELD_LOAD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_GL_CONS_FFIELD_LOAD_PKG" 
AS
-----------------------------------------------------------------------------------------------
/*
 Created By     : IBM Development Team

 Creation Date  : 29-Mar-2012
 File Name      : XXGLCONFLEXMAPLOAD.pks
 Description    : This script creates the Specification of the package xx_gl_cons_ffield_load_pkg
 Change History :
 -----------------------------------------------------------------------------------------------
 Date        Name          Remarks
 -----------------------------------------------------------------------------------------------
 29-Mar-2012   IBM Development Team  Initial development.
 11-Jun-2012   IBM Development Team   Added overloaded function get_ccid
 -----------------------------------------------------------------------------------------------
*/
   g_stage               VARCHAR2 (2000);
   g_batch_id            VARCHAR2 (200);
   g_validate_and_load   VARCHAR2 (100)  := 'VALIDATE_AND_LOAD';

   ---------Defining Type for stage table---------------------------
   TYPE g_xxgl_ffield_map_stg_rec IS RECORD (
      flexfield_map_id         NUMBER,
      consolidation_id_11i     NUMBER,
      last_update_date         DATE,
      last_updated_by          NUMBER,
      to_code_combination_id   NUMBER,
      to_segment1              VARCHAR2 (25),
      to_segment2              VARCHAR2 (25),
      to_segment3              VARCHAR2 (25),
      to_segment4              VARCHAR2 (25),
      to_segment5              VARCHAR2 (25),
      to_segment6              VARCHAR2 (25),
      to_segment7              VARCHAR2 (25),
      to_segment8              VARCHAR2 (25),
     --NPANDA to_segment9              VARCHAR2 (25),
      creation_date            DATE,
      created_by               NUMBER,
      last_update_login        NUMBER,
      segment1_low             VARCHAR2 (25),
      segment1_high            VARCHAR2 (25),
      segment2_low             VARCHAR2 (25),
      segment2_high            VARCHAR2 (25),
      segment3_low             VARCHAR2 (25),
      segment3_high            VARCHAR2 (25),
      segment4_low             VARCHAR2 (25),
      segment4_high            VARCHAR2 (25),
      segment5_low             VARCHAR2 (25),
      segment5_high            VARCHAR2 (25),
      segment6_low             VARCHAR2 (25),
      segment6_high            VARCHAR2 (25),
      segment7_low             VARCHAR2 (25),
      segment7_high            VARCHAR2 (25),
      segment8_low             VARCHAR2 (25),
      segment8_high            VARCHAR2 (25),
      attribute1               VARCHAR2 (150),
      attribute2               VARCHAR2 (150),
      attribute3               VARCHAR2 (150),
      attribute4               VARCHAR2 (150),
      attribute5               VARCHAR2 (150),
      CONTEXT                  VARCHAR2 (150),
      coa_mapping_id           NUMBER,
      batch_id                 VARCHAR2 (200),
      record_number            NUMBER,
      process_code             VARCHAR2 (100),
      ERROR_CODE               VARCHAR2 (100),
      request_id               NUMBER,
      program_application_id   NUMBER,
      program_id               NUMBER,
      program_update_date      DATE
   );

   TYPE g_xxgl_ffield_map_stg_tab IS TABLE OF g_xxgl_ffield_map_stg_rec
      INDEX BY BINARY_INTEGER;

   TYPE g_xxgl_ffield_map_piface_rec IS RECORD (
      flexfield_map_id         NUMBER,
      consolidation_id_11i     NUMBER,
      last_update_date         DATE,
      last_updated_by          NUMBER,
      to_code_combination_id   NUMBER,
      to_segment1              VARCHAR2 (25),
      to_segment2              VARCHAR2 (25),
      to_segment3              VARCHAR2 (25),
      to_segment4              VARCHAR2 (25),
      to_segment5              VARCHAR2 (25),
      to_segment6              VARCHAR2 (25),
      to_segment7              VARCHAR2 (25),
      to_segment8              VARCHAR2 (25),
     --NPANDA to_segment9              VARCHAR2 (25),
      creation_date            DATE,
      created_by               NUMBER,
      last_update_login        NUMBER,
      segment1_low             VARCHAR2 (25),
      segment1_high            VARCHAR2 (25),
      segment2_low             VARCHAR2 (25),
      segment2_high            VARCHAR2 (25),
      segment3_low             VARCHAR2 (25),
      segment3_high            VARCHAR2 (25),
      segment4_low             VARCHAR2 (25),
      segment4_high            VARCHAR2 (25),
      segment5_low             VARCHAR2 (25),
      segment5_high            VARCHAR2 (25),
      segment6_low             VARCHAR2 (25),
      segment6_high            VARCHAR2 (25),
      segment7_low             VARCHAR2 (25),
      segment7_high            VARCHAR2 (25),
      segment8_low             VARCHAR2 (25),
      segment8_high            VARCHAR2 (25),
      attribute1               VARCHAR2 (150),
      attribute2               VARCHAR2 (150),
      attribute3               VARCHAR2 (150),
      attribute4               VARCHAR2 (150),
      attribute5               VARCHAR2 (150),
      CONTEXT                  VARCHAR2 (150),
      coa_mapping_id           NUMBER,
      batch_id                 VARCHAR2 (200),
      record_number            NUMBER,
      process_code             VARCHAR2 (100),
      ERROR_CODE               VARCHAR2 (100),
      request_id               NUMBER,
      program_application_id   NUMBER,
      program_id               NUMBER,
      program_update_date      DATE
   );

   TYPE g_xxgl_ffield_map_piface_tab IS TABLE OF g_xxgl_ffield_map_piface_rec
      INDEX BY BINARY_INTEGER;

   PROCEDURE main (
      errbuf                OUT      VARCHAR2,
      retcode               OUT      VARCHAR2,
      p_batch_id            IN       VARCHAR2,
      p_coa_mapping_id      IN       VARCHAR2,
      p_restart_flag        IN       VARCHAR2,
      p_override_flag       IN       VARCHAR2,
      p_purge_flag          IN       VARCHAR2,
      p_process_mode        IN       VARCHAR2,
      p_validate_and_load   IN       VARCHAR2,
      p_ledger_id           IN       VARCHAR2
   );
/*
 Created By     : IBM Development Team

 Creation Date  : 29-Mar-2012
 Function Name  : get_ccid
 Description    : This function receives coa_id and 8 segment account code combination as input parameter - and returns R12 code_combination_id and all 9 segments in out parameters.
 Change History :
 -----------------------------------------------------------------------------------------------
 Date        Name          Remarks
 -----------------------------------------------------------------------------------------------
 29-Mar-2012   IBM Development Team  Initial development.
 -----------------------------------------------------------------------------------------------
*/
   FUNCTION get_ccid (
      x_segment1       IN       VARCHAR2,
      x_segment2       IN       VARCHAR2,
      x_segment3       IN       VARCHAR2,
      x_segment4       IN       VARCHAR2,
      x_segment5       IN       VARCHAR2,
      x_segment6       IN       VARCHAR2,
      x_segment7       IN       VARCHAR2,
      x_segment8       IN       VARCHAR2,
      x_source         IN       VARCHAR2,
      x_segment1_out   OUT      VARCHAR2,
      x_segment2_out   OUT      VARCHAR2,
      x_segment3_out   OUT      VARCHAR2,
      x_segment4_out   OUT      VARCHAR2,
      x_segment5_out   OUT      VARCHAR2,
      x_segment6_out   OUT      VARCHAR2,
      x_segment7_out   OUT      VARCHAR2,
      x_segment8_out   OUT      VARCHAR2,
      x_segment9_out   OUT      VARCHAR2
   )
      RETURN NUMBER;

  /*
   Created By     : IBM Development Team

   Creation Date  : 29-Mar-2012
   Function Name  : get_ccid overloaded function
   Description    : This function receives coa_id and 8 segment account code combination as input parameter - and returns R12 code_combination_id.
   Change History :
   -----------------------------------------------------------------------------------------------
   Date        Name          Remarks
   -----------------------------------------------------------------------------------------------
   29-Mar-2012   IBM Development Team  Initial development.
   -----------------------------------------------------------------------------------------------
  */
     FUNCTION get_ccid (
        x_segment1       IN       VARCHAR2,
        x_segment2       IN       VARCHAR2,
        x_segment3       IN       VARCHAR2,
        x_segment4       IN       VARCHAR2,
        x_segment5       IN       VARCHAR2,
        x_segment6       IN       VARCHAR2,
        x_segment7       IN       VARCHAR2,
        x_segment8       IN       VARCHAR2,
        x_source         IN       VARCHAR2
        ) RETURN NUMBER;

  /*
   Created By     : IBM Development Team

   Creation Date  : 29-Mar-2012
   Function Name  : get_ccid overloaded function
   Description    : This function receives coa_id and 8 segment account code combination as input parameter - and returns R12 code_combination_id.
   Change History :
   -----------------------------------------------------------------------------------------------
   Date        Name          Remarks
   -----------------------------------------------------------------------------------------------
   29-Mar-2012   IBM Development Team  Initial development.
   -----------------------------------------------------------------------------------------------
  */
     FUNCTION get_ccid (
        x_segment1       IN       VARCHAR2,
        x_segment2       IN       VARCHAR2,
        x_segment3       IN       VARCHAR2,
        x_segment4       IN       VARCHAR2,
        x_segment5       IN       VARCHAR2,
        x_segment6       IN       VARCHAR2,
        x_segment7       IN       VARCHAR2,
        x_segment8       IN       VARCHAR2,
        x_source         IN       VARCHAR2,
        x_component_name IN       VARCHAR2
        ) RETURN NUMBER;
-- Constants defined for version control of all the files of the components --
END xx_gl_cons_ffield_load_pkg;
/


GRANT EXECUTE ON APPS.XX_GL_CONS_FFIELD_LOAD_PKG TO INTG_XX_NONHR_RO;
