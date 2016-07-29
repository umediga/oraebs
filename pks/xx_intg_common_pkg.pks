DROP PACKAGE APPS.XX_INTG_COMMON_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INTG_COMMON_PKG" 
AS
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-2012
 File Name     : XXXINTGCOMMON.pks
 Description   : This Package contain different validation functions and procedures
                 which can be used by Finance People across the development of Integra

 Change History:

 Date        Name            Remarks
 ----------- -----------     ---------------------------------------
 07-MAR-2012 IBM Development Initial development
 11-OCT-2014 IBM Development Added launch_bursting - the program will wait for the parent 
                             request to complete before submitting the bursting program.
 11-OCT-2014 IBM Development    Added get_ou_specific_templ for OU specific changes in wave2
 */
--------------------------------------------------------------------------------------

   g_log_file_path     VARCHAR2 (200);
   g_out_file_path     VARCHAR2 (200);
   g_trc_file_path     VARCHAR2 (200);
--End Need to verify below constant values
   g_log_file_handle   UTL_FILE.file_type;
   g_out_file_handle   UTL_FILE.file_type;
   g_isinitialise      BOOLEAN            := FALSE;
   g_write_flag        BOOLEAN            := FALSE;
   g_fnd_flag          BOOLEAN            := TRUE;
   TYPE Conv_Cat_Rec_Type IS RECORD (lookup_code         varchar2(240)
                                    ,lookup_meaning      varchar2(240)
                                    ,table_name          varchar2(240)
                                    ,column_name         varchar2(240)
                                    ,conv_cat_name       varchar2(240)
                                    ,ln_identifier       varchar2(50)
                                    );
   --
   TYPE Conv_Cat_Tbl_Type is TABLE of Conv_Cat_Rec_Type index by binary_integer;
   --
-- Function to Validate Currency Code
   FUNCTION validate_currency_code (
      p_curr_code_in   IN   fnd_currencies.currency_code%TYPE
   )
      RETURN BOOLEAN;
   --  Converts quantity in a unit of measure to a new unit of measure.
   --  The function returns the new unit of measure quantity.
   FUNCTION get_uom_conversion (
      p_current_uom   IN   mtl_uom_conversions.uom_code%TYPE,
      p_current_qty   IN   NUMBER,
      p_new_uom       IN   mtl_uom_conversions.uom_code%TYPE
   )
      RETURN NUMBER;
-- Function to check whether a given Period exist and Open for different Modules like AR,AP,GL,PO etc....
   FUNCTION validate_period (
      p_app_short_name   IN   fnd_application.application_short_name%TYPE,
      p_org_id           IN   hr_operating_units.organization_id%TYPE,
      p_date             IN   DATE,
      p_period_name      IN   gl_period_statuses_v.period_name%TYPE
   )
      RETURN BOOLEAN;
-- Function to return Open Period Name for the Given Application ,date and organization
   FUNCTION get_period (
      p_app_short_name   IN   fnd_application.application_short_name%TYPE,
      p_org_id           IN   hr_operating_units.organization_id%TYPE,
      p_date             IN   DATE
   )
      RETURN VARCHAR2;
-- Function to return Concatenated Segments as well as Individual segment values for a given CCID value
   PROCEDURE get_coa_segments (
      p_org_name               IN              hr_operating_units.NAME%TYPE,
      p_ccid                   IN              gl_code_combinations_kfv.code_combination_id%TYPE,
      x_concatenated_segment   OUT NOCOPY      gl_code_combinations_kfv.concatenated_segments%TYPE,
      x_segment1               OUT NOCOPY      gl_code_combinations_kfv.segment1%TYPE,
      x_segment2               OUT NOCOPY      gl_code_combinations_kfv.segment2%TYPE,
      x_segment3               OUT NOCOPY      gl_code_combinations_kfv.segment3%TYPE,
      x_segment4               OUT NOCOPY      gl_code_combinations_kfv.segment4%TYPE,
      x_segment5               OUT NOCOPY      gl_code_combinations_kfv.segment5%TYPE,
      x_segment6               OUT NOCOPY      gl_code_combinations_kfv.segment6%TYPE,
      x_segment7               OUT NOCOPY      gl_code_combinations_kfv.segment7%TYPE
   );
-- Function to return CCID for the Concatenated Segments as well as Individual segment values
   FUNCTION get_coa_ccid (
      p_org_name               IN   hr_operating_units.NAME%TYPE,
      p_concatenated_segment   IN   gl_code_combinations_kfv.concatenated_segments%TYPE,
      p_segment1               IN   gl_code_combinations_kfv.segment1%TYPE,
      p_segment2               IN   gl_code_combinations_kfv.segment2%TYPE DEFAULT NULL,
      p_segment3               IN   gl_code_combinations_kfv.segment3%TYPE DEFAULT NULL,
      p_segment4               IN   gl_code_combinations_kfv.segment4%TYPE DEFAULT NULL,
      p_segment5               IN   gl_code_combinations_kfv.segment5%TYPE DEFAULT NULL,
      p_segment6               IN   gl_code_combinations_kfv.segment6%TYPE DEFAULT NULL,
      p_segment7               IN   gl_code_combinations_kfv.segment7%TYPE DEFAULT NULL,
      p_segment8               IN   gl_code_combinations_kfv.segment8%TYPE DEFAULT NULL,
      p_segment9               IN   gl_code_combinations_kfv.segment9%TYPE DEFAULT NULL,
      p_segment10              IN   gl_code_combinations_kfv.segment10%TYPE DEFAULT NULL
   )
      RETURN NUMBER;

-- function retrieves the currency rate for currency code on a certain date.
   FUNCTION get_currency_rate (
      p_query_date        IN   DATE,
      p_from_currency     IN   gl_daily_rates.from_currency%TYPE,
      p_to_currency       IN   gl_daily_rates.to_currency%TYPE,
      p_conversion_type   IN   gl_daily_rates.conversion_type%TYPE
   )
      RETURN NUMBER;
-- Procedure raise error message
   PROCEDURE raise_message_error (
      p_proc_name     IN   VARCHAR2,
      p_error_level   IN   NUMBER,
      p_message       IN   VARCHAR2
   );
--Start IBM Development:The following functions and procedures that are in the code have been placed in hold for
--the present time.  In the future if we find a need for any of the functions or procedures,
-- we will review the those required and make them functional.
--commenting out below procedures/functions
   -- Procedure to enable messaging. It would be used while
   PROCEDURE message_enable;
-- Procedure to enable messaging for a specific concurrent program.
-- This would be the first procedure needs to be called for setting messages.
   PROCEDURE message_enable (p_request_id IN NUMBER);
-- Procedure to set debug level and message level
-- PROCEDURE message_enable (p_debug_level IN NUMBER, p_message_level IN NUMBER);
   -- Procedure to issue save points and writes save point details to file
--   PROCEDURE message_save_point (p_save_point IN VARCHAR2);
   -- Procedure to flushes the data to file and closes the file.
--   PROCEDURE message_close (px_file_handle IN OUT UTL_FILE.file_type);
   -- Procedure to rollback changes database and closes the file.
--   PROCEDURE message_rollback;
   -- Procedure to commit changes database and closes the file
--   PROCEDURE message_commit;
   -- Procedure to flushes the data from the buffer to file.
--   PROCEDURE message_flush (px_file_handle IN OUT UTL_FILE.file_type);
   -- Procedure to writes messages to log file.
--   PROCEDURE write_log_file (
--      p_message       IN   VARCHAR2,
--      p_file_handle   IN   UTL_FILE.file_type
--   );
   -- Procedure to writes messages to specific file and flushes the data
--   PROCEDURE write_text_file (
--      p_message       IN   VARCHAR2,
--      p_file_handle   IN   UTL_FILE.file_type
--   );
   -- Procedure reads specific file.
--   FUNCTION read_text_file (
--      x_message       OUT      VARCHAR2,
--      p_file_handle   IN       UTL_FILE.file_type
--   )
--      RETURN BOOLEAN;
   -- Procedure appends heading to log file.
-- PROCEDURE log_heading (p_file_handle IN UTL_FILE.file_type);
   -- Procedure appends heading to file handle file.
--   PROCEDURE log_heading (p_file_type IN VARCHAR2 DEFAULT NULL);
   -- Procedure to generate and write warning message to file.
--   PROCEDURE generate_warning (
--      p_warning_message   IN   VARCHAR2,
--      p_file_handle       IN   UTL_FILE.file_type
--   );
   -- Procedure to generate and write warning message to file.
--   PROCEDURE generate_warning (
--      p_warning_message   IN   VARCHAR2,
--      p_file_flag         IN   VARCHAR2 DEFAULT NULL
--   );
   -- This PUBLIC procedure will writes 'message' to Log File
--   PROCEDURE write_log (
--      p_message         IN   VARCHAR2,
--      p_message_level   IN   NUMBER DEFAULT NULL
--   );
   -- This PUBLIC procedure will writes 'message' to Out File
   --   PROCEDURE write_out (p_message IN VARCHAR2);
   -- function to get Default Message Location
 --   FUNCTION get_trc_location
--      RETURN VARCHAR2;
   -- Function will retuns the default file name defined in the value set
 --   FUNCTION get_trc_file
--      RETURN VARCHAR2;
   --  Based on input parameters function will open a file.
 --  If the file opens successfully it returns the File Handle
 --  and status as True .Otherwise it returns false.
 --   FUNCTION open_text_file (
--      x_file_handle     OUT      UTL_FILE.file_type,
--      p_file_location   IN       VARCHAR2,
--      p_file_name       IN       VARCHAR2,
--      p_open_mode       IN       VARCHAR2
--   )
--      RETURN BOOLEAN;
   --End IBM Development:The following functions and procedures that are in the code have been placed in hold for
--the present time.  In the future if we find a need for any of the functions or procedures,
-- we will review the those required and make them functional.
   --commenting out above procedures/functions
   -- Pass in the table name, context field name, context value, and column
-- name to get the user name for the attribute column
   FUNCTION get_dff_user_names (
      p_table_name_in             IN   VARCHAR2,
      p_column_name_in            IN   VARCHAR2,
      p_context_column_name_in    IN   VARCHAR2,
      p_context_column_value_in   IN   VARCHAR2
   )
      RETURN VARCHAR2;
-- Pass in the table name and the id_flex_code or id_flex_name to
   FUNCTION get_kff_user_names (
      p_table_name_in               IN   VARCHAR2,
      p_id_flex_code_in             IN   VARCHAR2,
      p_id_flex_structure_code_in   IN   VARCHAR2,
      p_column_name_in              IN   VARCHAR2
   )
      RETURN VARCHAR2;
-- Return the current concurrent request id
   FUNCTION get_request_id
      RETURN fnd_concurrent_requests.request_id%TYPE;
-- Return the Concurrent Request Submitted User Name
   FUNCTION get_conc_user_name
      RETURN fnd_user.user_name%TYPE;
-- Return the Concurrent Request Submitted User Id
   FUNCTION get_conc_user_id
      RETURN fnd_user.user_id%TYPE;
-- Return Concurrent Request Submitted Responsibility Name
   FUNCTION get_responsibility_name
      RETURN fnd_responsibility_vl.responsibility_name%TYPE;
-- Get Concurrent Program Name
   FUNCTION get_user_program_name
      RETURN fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;
-- Used to submit a concurrent program to the concurrent manager through SQL or PL/SQL
   FUNCTION submit_conc_program (
      p_user_name            IN   VARCHAR2 DEFAULT NULL,
      p_responsiblity_name   IN   VARCHAR2 DEFAULT NULL,
      p_conc_prog_name       IN   VARCHAR2,
      p_param00              IN   VARCHAR2 DEFAULT NULL,
      p_param01              IN   VARCHAR2 DEFAULT NULL,
      p_param02              IN   VARCHAR2 DEFAULT NULL,
      p_param03              IN   VARCHAR2 DEFAULT NULL,
      p_param04              IN   VARCHAR2 DEFAULT NULL,
      p_param05              IN   VARCHAR2 DEFAULT NULL,
      p_param06              IN   VARCHAR2 DEFAULT NULL,
      p_param07              IN   VARCHAR2 DEFAULT NULL,
      p_param08              IN   VARCHAR2 DEFAULT NULL,
      p_param09              IN   VARCHAR2 DEFAULT NULL,
      p_param10              IN   VARCHAR2 DEFAULT NULL,
      p_param11              IN   VARCHAR2 DEFAULT NULL,
      p_param12              IN   VARCHAR2 DEFAULT NULL,
      p_param13              IN   VARCHAR2 DEFAULT NULL,
      p_param14              IN   VARCHAR2 DEFAULT NULL,
      p_param15              IN   VARCHAR2 DEFAULT NULL,
      p_param16              IN   VARCHAR2 DEFAULT NULL,
      p_param17              IN   VARCHAR2 DEFAULT NULL,
      p_param18              IN   VARCHAR2 DEFAULT NULL,
      p_param19              IN   VARCHAR2 DEFAULT NULL,
      p_param20              IN   VARCHAR2 DEFAULT NULL,
      p_param21              IN   VARCHAR2 DEFAULT NULL,
      p_param22              IN   VARCHAR2 DEFAULT NULL,
      p_param23              IN   VARCHAR2 DEFAULT NULL,
      p_param24              IN   VARCHAR2 DEFAULT NULL,
      p_param25              IN   VARCHAR2 DEFAULT NULL,
      p_param26              IN   VARCHAR2 DEFAULT NULL,
      p_param27              IN   VARCHAR2 DEFAULT NULL,
      p_param28              IN   VARCHAR2 DEFAULT NULL,
      p_param29              IN   VARCHAR2 DEFAULT NULL,
      p_param30              IN   VARCHAR2 DEFAULT NULL,
      p_param31              IN   VARCHAR2 DEFAULT NULL,
      p_param32              IN   VARCHAR2 DEFAULT NULL,
      p_param33              IN   VARCHAR2 DEFAULT NULL,
      p_param34              IN   VARCHAR2 DEFAULT NULL,
      p_param35              IN   VARCHAR2 DEFAULT NULL,
      p_param36              IN   VARCHAR2 DEFAULT NULL,
      p_param37              IN   VARCHAR2 DEFAULT NULL,
      p_param38              IN   VARCHAR2 DEFAULT NULL,
      p_param39              IN   VARCHAR2 DEFAULT NULL,
      p_param40              IN   VARCHAR2 DEFAULT NULL,
      p_param41              IN   VARCHAR2 DEFAULT NULL,
      p_param42              IN   VARCHAR2 DEFAULT NULL,
      p_param43              IN   VARCHAR2 DEFAULT NULL,
      p_param44              IN   VARCHAR2 DEFAULT NULL,
      p_param45              IN   VARCHAR2 DEFAULT NULL,
      p_param46              IN   VARCHAR2 DEFAULT NULL,
      p_param47              IN   VARCHAR2 DEFAULT NULL,
      p_param48              IN   VARCHAR2 DEFAULT NULL,
      p_param49              IN   VARCHAR2 DEFAULT NULL,
      p_param50              IN   VARCHAR2 DEFAULT NULL,
      p_param51              IN   VARCHAR2 DEFAULT NULL,
      p_param52              IN   VARCHAR2 DEFAULT NULL,
      p_param53              IN   VARCHAR2 DEFAULT NULL,
      p_param54              IN   VARCHAR2 DEFAULT NULL,
      p_param55              IN   VARCHAR2 DEFAULT NULL,
      p_param56              IN   VARCHAR2 DEFAULT NULL,
      p_param57              IN   VARCHAR2 DEFAULT NULL,
      p_param58              IN   VARCHAR2 DEFAULT NULL,
      p_param59              IN   VARCHAR2 DEFAULT NULL,
      p_param60              IN   VARCHAR2 DEFAULT NULL,
      p_param61              IN   VARCHAR2 DEFAULT NULL,
      p_param62              IN   VARCHAR2 DEFAULT NULL,
      p_param63              IN   VARCHAR2 DEFAULT NULL,
      p_param64              IN   VARCHAR2 DEFAULT NULL,
      p_param65              IN   VARCHAR2 DEFAULT NULL,
      p_param66              IN   VARCHAR2 DEFAULT NULL,
      p_param67              IN   VARCHAR2 DEFAULT NULL,
      p_param68              IN   VARCHAR2 DEFAULT NULL,
      p_param69              IN   VARCHAR2 DEFAULT NULL,
      p_param70              IN   VARCHAR2 DEFAULT NULL,
      p_param71              IN   VARCHAR2 DEFAULT NULL,
      p_param72              IN   VARCHAR2 DEFAULT NULL,
      p_param73              IN   VARCHAR2 DEFAULT NULL,
      p_param74              IN   VARCHAR2 DEFAULT NULL,
      p_param75              IN   VARCHAR2 DEFAULT NULL,
      p_param76              IN   VARCHAR2 DEFAULT NULL,
      p_param77              IN   VARCHAR2 DEFAULT NULL,
      p_param78              IN   VARCHAR2 DEFAULT NULL,
      p_param79              IN   VARCHAR2 DEFAULT NULL,
      p_param80              IN   VARCHAR2 DEFAULT NULL,
      p_param81              IN   VARCHAR2 DEFAULT NULL,
      p_param82              IN   VARCHAR2 DEFAULT NULL,
      p_param83              IN   VARCHAR2 DEFAULT NULL,
      p_param84              IN   VARCHAR2 DEFAULT NULL,
      p_param85              IN   VARCHAR2 DEFAULT NULL,
      p_param86              IN   VARCHAR2 DEFAULT NULL,
      p_param87              IN   VARCHAR2 DEFAULT NULL,
      p_param88              IN   VARCHAR2 DEFAULT NULL,
      p_param89              IN   VARCHAR2 DEFAULT NULL,
      p_param90              IN   VARCHAR2 DEFAULT NULL,
      p_param91              IN   VARCHAR2 DEFAULT NULL,
      p_param92              IN   VARCHAR2 DEFAULT NULL,
      p_param93              IN   VARCHAR2 DEFAULT NULL,
      p_param94              IN   VARCHAR2 DEFAULT NULL,
      p_param95              IN   VARCHAR2 DEFAULT NULL,
      p_param96              IN   VARCHAR2 DEFAULT NULL,
      p_param97              IN   VARCHAR2 DEFAULT NULL,
      p_param98              IN   VARCHAR2 DEFAULT NULL,
      p_param99              IN   VARCHAR2 DEFAULT NULL
   )
      RETURN NUMBER;
-- Procedure to write messages to either fnd log file or DBMS OUTPUT based on the value of
-- G_FND_FLAG variable. If the G_FND_FLAG value is TRUE then it writes the message to log file otherwise
-- writes message to dbms output.
   PROCEDURE write_log (p_message IN VARCHAR2);
-- Procedure used to submit a concurrent program to the concurrent manager from ODI
 PROCEDURE submit_conc_program_from_odi (
      p_user_id             IN       NUMBER,
      p_responsibility_id   IN       NUMBER,
      p_application_id      IN       NUMBER,
      p_module              IN       VARCHAR2,
      p_conc                IN       VARCHAR2,
      p_param1              IN       VARCHAR2 DEFAULT CHR (0),
      p_param2              IN       VARCHAR2 DEFAULT CHR (0),
      p_param3              IN       VARCHAR2 DEFAULT CHR (0),
      p_param4              IN       VARCHAR2 DEFAULT CHR (0),
      p_param5              IN       VARCHAR2 DEFAULT CHR (0),
      p_param6              IN       VARCHAR2 DEFAULT CHR (0),
      p_param7              IN       VARCHAR2 DEFAULT CHR (0),
      p_param8              IN       VARCHAR2 DEFAULT CHR (0),
      p_param9              IN       VARCHAR2 DEFAULT CHR (0),
      p_param10             IN       VARCHAR2 DEFAULT CHR (0),
      p_param11             IN       VARCHAR2 DEFAULT CHR (0),
      p_param12             IN       VARCHAR2 DEFAULT CHR (0),
      p_param13             IN       VARCHAR2 DEFAULT CHR (0),
      p_param14             IN       VARCHAR2 DEFAULT CHR (0),
      p_param15             IN       VARCHAR2 DEFAULT CHR (0),
      p_param16             IN       VARCHAR2 DEFAULT CHR (0),
      p_param17             IN       VARCHAR2 DEFAULT CHR (0),
      p_param18             IN       VARCHAR2 DEFAULT CHR (0),
      p_param19             IN       VARCHAR2 DEFAULT CHR (0),
      p_param20             IN       VARCHAR2 DEFAULT CHR (0),
      p_wait                IN       VARCHAR2 DEFAULT 'N',
      x_req_id              OUT      NUMBER,
      x_status              OUT      VARCHAR2
   );
--
   ---- Procedure to call web service.
   PROCEDURE call_web_service (
      p_soap_request     IN       VARCHAR2,
      p_ws_uri           IN       VARCHAR2,
      p_ws_action        IN       VARCHAR2,
      p_timeout_second   IN       NUMBER DEFAULT NULL,
      x_status_code      OUT      NUMBER,
      x_status_desc      OUT      VARCHAR2,
      x_soap_respond     OUT      VARCHAR2
   );

-- Logic is the same with above procedure, added x_error_code and x_error_message to return original error information.
-- Use for identify timeout error with error code -29276
   PROCEDURE call_web_service (
      p_soap_request     IN       VARCHAR2,
      p_ws_uri           IN       VARCHAR2,
      p_ws_action        IN       VARCHAR2,
      p_timeout_second   IN       NUMBER DEFAULT NULL,
      x_error_code       OUT      NUMBER,
      x_error_message    OUT      VARCHAR2,
      x_status_code      OUT      NUMBER,
      x_status_desc      OUT      VARCHAR2,
      x_soap_respond     OUT      VARCHAR2
   );

   --FUNCTION xx_apps_initialize (p_ricew_id IN VARCHAR2, p_org_id IN NUMBER DEFAULT NULL)      RETURN NUMBER;

--
--  Function for getting Client Timezone from Server Timezone
--
FUNCTION xx_timezone_converter (
   p_date     IN   DATE,
   p_org_id   IN   NUMBER DEFAULT NULL
)
   RETURN DATE;

--This Function Validates the credit card number and Expiry Date and returns VALID or INVALID
--
    FUNCTION validate_credit_card_number (p_cc_num_stripped  IN VARCHAR2,
                                          p_expiry_date      IN DATE,
                                          p_card_brand       IN VARCHAR2 DEFAULT NULL,
                                          p_card_holder_Name IN VARCHAR2 DEFAULT NULL,
                                          p_param1           IN VARCHAR2 DEFAULT NULL,
                                          p_param2           IN VARCHAR2 DEFAULT NULL,
                                          p_param3           IN VARCHAR2 DEFAULT NULL,
                                          p_param4           IN VARCHAR2 DEFAULT NULL,
                                          p_param5           IN VARCHAR2 DEFAULT NULL
                                                                            )
    RETURN VARCHAR2;

--This Procedure Validates the credit card number,card type and Expiry Date.
----------------------------------------------------------------------------------------------

    PROCEDURE xx_validate_credit_card        (  p_cc_number        IN VARCHAR2,
                                                p_expiry_date      IN DATE,
                                                p_card_brand       IN VARCHAR2,
                                                p_card_holder_Name IN VARCHAR2 DEFAULT NULL,
                                                x_return_status    OUT VARCHAR2,
                                                x_return_message   OUT VARCHAR2
                                              );

  FUNCTION init_apps (  p_responsibility_id IN NUMBER
                        , p_application_id IN NUMBER) RETURN NUMBER  ;

  FUNCTION find_max (p_error_code1 VARCHAR2, p_error_code2 VARCHAR2) RETURN VARCHAR2;


FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                            ,p_source        IN VARCHAR2 DEFAULT NULL
                            , p_old_value    IN VARCHAR2
                            , p_date_effective IN DATE
                          )   RETURN VARCHAR2;

FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                            ,p_source        IN VARCHAR2 DEFAULT NULL
                            , p_old_value1    IN VARCHAR2
                            , p_old_value2    IN VARCHAR2
                            , p_date_effective IN DATE
                          )   RETURN VARCHAR2;


PROCEDURE get_mapping_value (p_mapping_type IN VARCHAR2
                          , p_old_value1    IN VARCHAR2
                          , p_old_value2    IN VARCHAR2 DEFAULT NULL
                          , p_old_value3    IN VARCHAR2 DEFAULT NULL
                          , p_old_value4    IN VARCHAR2 DEFAULT NULL
                          , p_old_value5    IN VARCHAR2 DEFAULT NULL
                          , p_old_value6    IN VARCHAR2 DEFAULT NULL
                          , p_old_value7    IN VARCHAR2 DEFAULT NULL
                          , p_new_value1    OUT VARCHAR2
                          , p_new_value2    OUT VARCHAR2
                          , p_new_value3    OUT VARCHAR2
                          , p_new_value4    OUT VARCHAR2
                          , p_new_value5    OUT VARCHAR2
                          , p_new_value6    OUT VARCHAR2
                          , p_new_value7    OUT VARCHAR2
                          , p_date_effective IN DATE
                          ) ;

FUNCTION get_account_mapping_value (p_mapping_type IN VARCHAR2
                          , p_source       IN VARCHAR2 DEFAULT NULL
                          , p_old_value    IN VARCHAR2
                          , p_date_effective IN DATE
                          , p_new_value    OUT VARCHAR2
                          )   RETURN NUMBER;

FUNCTION get_new_sob( p_legacy_sob_name IN VARCHAR2
                     ,p_new_sob_id    OUT NUMBER
                    ) RETURN NUMBER;

FUNCTION split_segments_2(
                           p_concat_segment IN VARCHAR2
                          ,p_delimiter IN VARCHAR2
                          ,p_segment1  OUT VARCHAR2
                          ,p_segment2  OUT VARCHAR2
                         ) RETURN NUMBER ;

FUNCTION get_org_id(
                     p_operating_unit IN  VARCHAR2
                    ,p_org_id         OUT NUMBER
                   ) RETURN NUMBER ;

FUNCTION get_oracle_segment_ccid(
                        p_source                   IN   VARCHAR2,
                        p_leg_seg_delimiter        IN   VARCHAR2 DEFAULT NULL,
                        p_leg_segment1             IN   gl_code_combinations_kfv.segment1%TYPE DEFAULT NULL,
                        p_leg_segment2             IN   gl_code_combinations_kfv.segment2%TYPE DEFAULT NULL,
                        p_leg_segment3             IN   gl_code_combinations_kfv.segment3%TYPE DEFAULT NULL,
                        p_leg_segment4             IN   gl_code_combinations_kfv.segment4%TYPE DEFAULT NULL,
                        p_leg_segment5             IN   gl_code_combinations_kfv.segment5%TYPE DEFAULT NULL,
                        p_leg_segment6             IN   gl_code_combinations_kfv.segment6%TYPE DEFAULT NULL,
                        p_leg_segment7             IN   gl_code_combinations_kfv.segment7%TYPE DEFAULT NULL,
                        p_concatenated_segment     OUT  gl_code_combinations_kfv.concatenated_segments%TYPE,
                        p_segment1                 OUT  gl_code_combinations_kfv.segment1%TYPE,
                        p_segment2                 OUT  gl_code_combinations_kfv.segment2%TYPE,
                        p_segment3                 OUT  gl_code_combinations_kfv.segment3%TYPE,
                        p_segment4                 OUT  gl_code_combinations_kfv.segment4%TYPE,
                        p_segment5                 OUT  gl_code_combinations_kfv.segment5%TYPE,
                        p_segment6                 OUT  gl_code_combinations_kfv.segment6%TYPE,
                        p_segment7                 OUT  gl_code_combinations_kfv.segment7%TYPE,
                        p_ccid                     OUT  NUMBER
                      ) RETURN NUMBER;



  PROCEDURE get_ccid_using_legacy (
      p_org_name                 IN   hr_operating_units.NAME%TYPE,
      p_source                   IN   VARCHAR2,
      p_leg_concatenated_segment IN   gl_code_combinations_kfv.concatenated_segments%TYPE DEFAULT NULL,
      p_leg_seg_delimiter        IN   VARCHAR2 DEFAULT NULL,
      p_leg_segment1             IN   gl_code_combinations_kfv.segment1%TYPE DEFAULT NULL,
      p_leg_segment2             IN   gl_code_combinations_kfv.segment2%TYPE DEFAULT NULL,
      p_leg_segment3             IN   gl_code_combinations_kfv.segment3%TYPE DEFAULT NULL,
      p_leg_segment4             IN   gl_code_combinations_kfv.segment4%TYPE DEFAULT NULL,
      p_leg_segment5             IN   gl_code_combinations_kfv.segment5%TYPE DEFAULT NULL,
      p_leg_segment6             IN   gl_code_combinations_kfv.segment6%TYPE DEFAULT NULL,
      p_leg_segment7             IN   gl_code_combinations_kfv.segment7%TYPE DEFAULT NULL,
      p_concatenated_segment     OUT  gl_code_combinations_kfv.concatenated_segments%TYPE,
      p_segment1                 OUT  gl_code_combinations_kfv.segment1%TYPE,
      p_segment2                 OUT  gl_code_combinations_kfv.segment2%TYPE,
      p_segment3                 OUT  gl_code_combinations_kfv.segment3%TYPE,
      p_segment4                 OUT  gl_code_combinations_kfv.segment4%TYPE,
      p_segment5                 OUT  gl_code_combinations_kfv.segment5%TYPE,
      p_segment6                 OUT  gl_code_combinations_kfv.segment6%TYPE,
      p_segment7                 OUT  gl_code_combinations_kfv.segment7%TYPE,
      p_ccid                     OUT  NUMBER
   );

   PROCEDURE get_mapping_value (  p_mapping_type IN VARCHAR2
                                  , p_old_value1    IN VARCHAR2
                                  , p_old_value2    IN VARCHAR2 DEFAULT NULL
                                  , p_old_value3    IN VARCHAR2 DEFAULT NULL
                                  , p_old_value4    IN VARCHAR2 DEFAULT NULL
                                  , p_old_value5    IN VARCHAR2 DEFAULT NULL
                                  , p_old_value6    IN VARCHAR2 DEFAULT NULL
                                  , p_old_value7    IN VARCHAR2 DEFAULT NULL
                                  , p_date_effective IN DATE    DEFAULT NULL
                                  , p_new_value1    OUT VARCHAR2
                                  , p_new_value2    OUT VARCHAR2
                                  , p_new_value3    OUT VARCHAR2
                                  );

   /* -----------------------------------------------------------------
   -- PROCEDURE get_inv_organization_id
   -- This will be used to derive the Oracle inventory organization
   -- based on the legacy organization name
   -- @p_legacy_org_name       --> Integra Legacy Item Name
   -- @p_inv_organization_id   --> Oracle Inventory Organization ID
   -- @p_error_code            --> Error Code
   -- @p_error_msg             --> Error Message
   -------------------------------------------------------------------*/
   PROCEDURE get_inv_organization_id(p_legacy_org_name  IN VARCHAR2
                                    ,p_inv_organization_id OUT NUMBER
                                    ,p_error_code          OUT VARCHAR2
                                    ,p_error_msg           OUT VARCHAR2
                                    );
   /* -----------------------------------------------------------------
   -- PROCEDURE get_inventory_item_id
   -- This will be used to derive the Oracle inventory Item ID
   -- based on the legacy Item name using the X'ref table information
   -- @p_legacy_item_name       --> Integra Legacy Item Name
   -- @p_organization_id        --> Oracle Inventory Organization ID
   -- @p_inventory_item_id      --> Oracle Inventory Item ID
   -- @p_error_code             --> Error Code
   -- @p_error_msg              --> Error Message
   -------------------------------------------------------------------*/
   PROCEDURE get_inventory_item_id(p_legacy_item_name   IN  VARCHAR2
                                  ,p_organization_id    IN  NUMBER
                                  ,p_inventory_item_id  OUT NUMBER
                                  ,p_error_code         OUT VARCHAR2
                                  ,p_error_msg          OUT VARCHAR2
                                  );
   /* -----------------------------------------------------------------
   -- FUNCTION get_inv_organization_id
   -- This will be used to derive the Oracle inventory organization
   -- based on the legacy organization name
   -- @p_legacy_org_name       --> Integra Legacy Item Name
   -------------------------------------------------------------------*/
   FUNCTION get_inv_organization_id(p_legacy_org_name  IN VARCHAR2
                                    )RETURN NUMBER;
   /* -----------------------------------------------------------------
   -- FUNCTION get_inventory_item_id
   -- This will be used to derive the Oracle inventory Item ID
   -- based on the legacy Item name using the X'ref table information
   -- @p_legacy_item_name       --> Integra Legacy Item Name
   -- @p_organization_id        --> Oracle Inventory Organization ID
   -------------------------------------------------------------------*/
   FUNCTION get_inventory_item_id(p_legacy_item_name   IN  VARCHAR2
                                  ,p_organization_id   IN  NUMBER
                                  )RETURN NUMBER;
   /* -----------------------------------------------------------------
   -- FUNCTION get_uom_code
   -- This will be used to derive the Oracle UOM CODE
   -- @p_legacy_uom_code       --> Integra Legacy Unit of measure
   -------------------------------------------------------------------*/
   FUNCTION get_uom_code(p_legacy_uom_code   IN  VARCHAR2
                        ,p_error_code        OUT VARCHAR2
                        ,p_error_msg         OUT VARCHAR2
                        )RETURN VARCHAR2;

   /* -----------------------------------------------------------------
   -- PROCEDURE xx_fnd_ftp_file
   -- This will be used to FTP the files onto Remote servers
   -- @p_host_name         --> Rempote server host name
   -- @p_program_name      -->
   -- @p_file_name         --> File Name
   -- @p_trans_mode        --> Transfer mode
   -- @p_schedule_time     --> Transfer Time
   -- @p_input_directory   --> File Input directory
   -- @p_output_directory  --> File Output directory
   -- @p_ftp_type          --> FTP Type
   -- @p_out               --> Error Msg
   -------------------------------------------------------------------*/
   PROCEDURE xx_fnd_ftp_file  (p_host_name            IN VARCHAR2,
                               p_program_name         IN VARCHAR2,
                               p_file_name            IN VARCHAR2,
                               p_trans_mode           IN VARCHAR2 DEFAULT 'Immediate',
                               p_schedule_time        IN DATE DEFAULT SYSDATE,
                               p_input_directory      IN VARCHAR2 DEFAULT  '/home',
                               p_output_directory     IN VARCHAR2 DEFAULT NULL,
                               p_ftp_type             IN VARCHAR2,
                               p_out                  OUT VARCHAR2
                              );
  /* -----------------------------------------------------------------
   -- FUNCTION set_message
   -- This will be used to set the error messages by passing token values to the
   -- error message defined under the XXINTG application .
   -- @p_message_name       --> Message name defined under XXINTG application.
   -- @p_token_value1       --> Token value1 to be passed for TOKEN1.
   -- @p_token_value2      --> Token value2 to be passed for  TOKEN2.
   -- @p_token_value3       --> Token value2 to be passed for TOKEN3.
   -------------------------------------------------------------------*/
   FUNCTION set_message(
            p_message_name IN VARCHAR2,
            p_token_value1 IN VARCHAR2 DEFAULT NULL,
            p_token_value2 IN VARCHAR2 DEFAULT NULL,
            p_token_value3 IN VARCHAR2 DEFAULT NULL)
  RETURN VARCHAR2;
  
    /* -----------------------------------------------------------------
     -- FUNCTION set_long_message
     -- This will be used to set the error messages by passing token values to the
     -- History Function Added by:Renjith on 05-May-2012     
     -- error message defined under the XXINTG application .
     -- @p_message_name       --> Message name defined under XXINTG application.
     -- @p_token_value1       --> Token value1 to be passed for TOKEN1.
     -- @p_token_value2      --> Token value2 to be passed for  TOKEN2.
     -- @p_token_value3       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value4       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value5       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value6       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value7       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value8       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value9       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value10       --> Token value2 to be passed for TOKEN3.
     -------------------------------------------------------------------*/
    FUNCTION set_long_message(
              p_message_name  IN VARCHAR2,
              p_token_value1  IN VARCHAR2 DEFAULT NULL,
              p_token_value2  IN VARCHAR2 DEFAULT NULL,
              p_token_value3  IN VARCHAR2 DEFAULT NULL,
              p_token_value4  IN VARCHAR2 DEFAULT NULL,
              p_token_value5  IN VARCHAR2 DEFAULT NULL,
              p_token_value6  IN VARCHAR2 DEFAULT NULL,
              p_token_value7  IN VARCHAR2 DEFAULT NULL,
              p_token_value8  IN VARCHAR2 DEFAULT NULL,
              p_token_value9  IN VARCHAR2 DEFAULT NULL,
              p_token_value10 IN VARCHAR2 DEFAULT NULL)
    RETURN VARCHAR2;
  
    /* -----------------------------------------------------------------
     -- FUNCTION set_token_message
     -- This will be used to set the error messages by passing token values to the
     -- History Function Added by:Renjith on 05-May-2012
     -- error message defined under the XXINTG application .
     -- @p_message_name       --> Message name defined under XXINTG application.
     -- @p_token_value1       --> Token value1 to be passed for TOKEN1.
     -- @p_token_value2      --> Token value2 to be passed for  TOKEN2.
     -- @p_token_value3       --> Token value2 to be passed for TOKEN3.
     -- @p_token_value4       --> Token value2 to be passed for TOKEN4.
     -- @p_token_value5       --> Token value2 to be passed for TOKEN5.
     -------------------------------------------------------------------*/
    FUNCTION set_token_message(
              p_message_name  IN VARCHAR2,
              p_token_value1  IN VARCHAR2 DEFAULT NULL,
              p_token_value2  IN VARCHAR2 DEFAULT NULL,
              p_token_value3  IN VARCHAR2 DEFAULT NULL,
              p_token_value4  IN VARCHAR2 DEFAULT NULL,
              p_token_value5  IN VARCHAR2 DEFAULT NULL,
              p_no_of_tokens  IN NUMBER)
    RETURN VARCHAR2;
  
  /*-----------------------------------------------------------------
   -- FUNCTION get_old_mapping_value
   -- This will be used to get the old value(legacy) for each new value passed (Oralce) from the  mapping
   -- table
   -- @p_mapping_type       --> Mapping Type.
   -- @p_new_value          --> Oracle Value.
   -- @p_effective_date     --> Effective date.
-----------------------------------------------------------------*/

 FUNCTION get_old_mapping_value (p_mapping_type IN VARCHAR2
                                  , p_new_value    IN VARCHAR2
                                  , p_date_effective IN DATE
                                )   RETURN VARCHAR2;
   /* -----------------------------------------------------------------
   -- FUNCTION file_archive
   -- This will be used to archive the data files from the data top to the archive folder.
   -- @p_src_location       --> Source Location of the datafile.
   -- @p_src_filename       --> Datafile name to be moved.
   -- @p_dest_location      --> Destination Location of the datafile.
   -- @p_overwrite          --> Boolean variable to set whether the datafile has to be overwritten in destination location.
   -------------------------------------------------------------------*/
      FUNCTION file_archive( p_src_location  IN VARCHAR2,
                             p_src_filename  IN VARCHAR2,
                             p_dest_location IN VARCHAR2,
                             p_dest_filename IN VARCHAR2,
                             p_overwrite IN BOOLEAN DEFAULT FALSE)
          RETURN NUMBER ;

     /* -----------------------------------------------------------------
   -- PROCEDURE get_customer_details
   -- This will be used to get customer details for a specific sender_interchange_isaid.
   -- This sender_interchange_isaid is defined in Trading Partner screen in E-Commerce Gateway.
   -- @p_sender_interchange_isaid         --> Sender Interchange ISAID
   -- @p_customer_number                  --> Customer Account Number
   -- @p_cust_account_id                  --> Customer Account ID
   -- @p_location_id                       --> Location ID
   -------------------------------------------------------------------*/
   PROCEDURE get_customer_details  (p_sender_interchange_isaid          IN VARCHAR2,
                                    p_customer_number                   OUT VARCHAR2,
                                    p_party_id                          OUT NUMBER,
                                    p_cust_account_id                   OUT NUMBER,
                                    p_location_id                       OUT NUMBER
                                    );
     /* -----------------------------------------------------------------
   -- PROCEDURE get_all_category_conv
   -- Procedure to get all the lookup values of lookup 'XX_INTEGRA_WMS_TRANSFORMATIONS' and load into Conv_Cat_Tbl_Type
   -- @p_tablename                        --> Interface/Staging Table name
   -- @x_ConvCatOutTbl                    --> Out Table Type
   -- @x_return_status                    --> Return Status
   -- @x_msg_data                         --> Output Message
   -------------------------------------------------------------------*/
PROCEDURE get_all_category_conv(p_tablename       IN  VARCHAR2
                               ,p_lookup_type     IN  VARCHAR2
                               ,p_parameter1          VARCHAR2 DEFAULT NULL
                               ,p_parameter2          VARCHAR2 DEFAULT NULL
                               ,p_parameter3          VARCHAR2 DEFAULT NULL
                               ,x_ConvCatOutTbl   OUT Conv_Cat_Tbl_Type
                               ,x_return_status   OUT VARCHAR2
                               ,x_msg_data        OUT VARCHAR2
                               );
--
     /* -----------------------------------------------------------------
   -- Function get_conv_category_name
   -- Function Checks if p_table_name, p_column_name exists in p_ConvCatInTbl table type,
   -- if so then returns the Corresponding Code Conversion name
   -- @p_tablename                        --> Interface/Staging Table name
   -- @p_column_name                      --> Column name
   -- @p_identifier                       --> Header or Line identifier
   -- @x_ConvCatOutTbl                    --> Conv_Cat_Tbl_Type Table Type
   -- Returns Code Conversion Category name/ NULL
   -------------------------------------------------------------------*/
FUNCTION get_conv_category_name (p_table_name         VARCHAR2
                                ,p_column_name        VARCHAR2
                                ,p_identifier         VARCHAR2  DEFAULT NULL
                                ,p_ConvCatInTbl       Conv_Cat_Tbl_Type
                                )
RETURN VARCHAR2;
--
     /* -----------------------------------------------------------------
   -- FUNCTION get_external_oracle_value
   -- Function that returns the Oracle Value if the Mode is INBOUND or External/Legacy system value if the Mode is OUTBOUND
   -- It takes Code Conversion category name, External/Legacy system name, Value for which mapping is required and Mode
   -- @p_code_conv_cat            --> Code Conversion category name
   -- @p_external_system          --> External/Legacy system name
   -- @p_value                    --> Value for which mapping is required (Oracle Value or External Value)
   -- @p_mode                     --> INBOUND or OUTBOUND
   -- @p_parameter1               --> Future Use
   -- @p_parameter2               --> Future Use
   -- @p_parameter3               --> Future Use
   -------------------------------------------------------------------*/
--
FUNCTION get_external_oracle_value(p_code_conv_cat       IN   VARCHAR2
                                  ,p_external_system     IN   VARCHAR2
                                  ,p_value               IN   VARCHAR2
                                  ,p_mode                IN   VARCHAR2
                                  ,p_parameter1          VARCHAR2       DEFAULT NULL
                                  ,p_parameter2          VARCHAR2       DEFAULT NULL
                                  ,p_parameter3          VARCHAR2       DEFAULT NULL
                                  )
RETURN VARCHAR2;
--
     /* -----------------------------------------------------------------
   -- PROCEDURE get_trading_partner_ref
   -- Procedure to get Reference Text1 and Reference Text2 of Trading Partner
   -- @p_tp_code                        --> Trading Partner Code / WMS System name
   -- @p_group_code                     --> Trading Partner Group Code
   -- @p_org_id                         --> Operating unit id
   -- @x_reference1                     --> Reference Text1
   -- @x_reference2                     --> REference Text2
   -------------------------------------------------------------------*/
PROCEDURE  get_trading_partner_ref(p_tp_code             VARCHAR2
                                  ,p_group_code          VARCHAR2
                                  ,p_org_id              VARCHAR2
                                  ,x_reference1    OUT   VARCHAR2
                                  ,x_reference2    OUT   VARCHAR2
                                  );
/*-----------------------------------------------------------------
-- PROCEDURE get_process_param_value
-- Procedure to get prcoess parameter value of any concurrent program
-- @p_process_name             --> Process Name
-- @p_param_name               --> Parameter Name
-- @x_param_value              --> Parameter Value
------------------------------------------------------------------*/
PROCEDURE get_process_param_value(p_process_name    IN  VARCHAR2
                                 ,p_param_name      IN  VARCHAR2
                                 ,x_param_value     OUT VARCHAR2
                                 );

/*-----------------------------------------------------------------
-- FUNCTION update_process_param_value
-- Procedure to Update Parameter value of any concurrent program
-- @p_process_name           --> Process Name
-- @p_param_name             --> Parameter Name
-- @p_param_value            --> Parameter Value
------------------------------------------------------------------*/
FUNCTION  update_process_param_value(p_process_name    IN  VARCHAR2
                                    ,p_param_name      IN  VARCHAR2
                                    ,p_param_value     IN  VARCHAR2
                                    )RETURN NUMBER;

/*-----------------------------------------------------------------
-- PROCEDURE get_prog_last_run_date
-- Procedure to get last run date value of any conc program
-- @p_process_name           --> Process Name
-- @p_param_name             --> Parameter Name
-- @x_param_value            --> Parameter Value
------------------------------------------------------------------*/
PROCEDURE get_prog_last_run_date (p_process_name    IN  VARCHAR2
                                 ,p_param_name      IN  VARCHAR2
                                 ,x_param_value     OUT VARCHAR2
                                 );
 /*-----------------------------------------------------------------
-- FUNCTION update_run_date
-- FUNCTION to Update the last run date of the respective file name
-- in xx_emf_process_files table
-- @p_process_name           --> Process Name
-- @p_system_name            --> File Name
-- @p_request_id             --> Request id
-- @p_run_date               --> Run Date
------------------------------------------------------------------*/
FUNCTION update_run_date
              (p_process_name  IN VARCHAR2
              ,p_run_date      IN DATE
              ,p_system_name   IN VARCHAR2 DEFAULT NULL
              ,p_request_id    IN NUMBER DEFAULT NULL
               )
RETURN NUMBER;
--
/*-----------------------------------------------------------------
-- FUNCTION get_last_run_date
-- Procedure to get the kast run date for the process name from
-- xx_emf_process_files table
-- @p_process_name           --> Process Name
-- @p_run_date               --> Run Date
-- @p_system_name            --> System Name
------------------------------------------------------------------*/
FUNCTION get_last_run_date
              (p_process_name  IN VARCHAR2,
               p_run_date      OUT DATE,
               p_system_name   IN VARCHAR2 DEFAULT NULL
                )
RETURN NUMBER;
--
 -----------------------------------------------------------------------
 ---------------------<  insert_into_fmw_ctl  >-------------------------
 -----------------------------------------------------------------------
 PROCEDURE insert_fmw_ctl ( p_file_name   IN varchar2
                               , p_event_name   IN varchar2 DEFAULT NULL);
-----------------------------------------------------------------------
 ---------------------<  update_into_fmw_ctl  >-------------------------
 -----------------------------------------------------------------------
 PROCEDURE update_fmw_ctl (p_file_name     IN varchar2
                               ,p_request_id    IN NUMBER 
			       ,p_process_code  IN VARCHAR2
			       ,p_error_message IN VARCHAR2 DEFAULT NULL);
 -----------------------------------------------------------------------
 ---------------------------<  wait_for_fmw  >--------------------------
 -----------------------------------------------------------------------
function wait_for_fmw(p_request_id IN NUMBER,
                  p_error_message OUT VARCHAR2,
		  interval   IN number default 30,
		  max_wait   IN number default 0
		 )  return  VARCHAR2 ;
 -----------------------------------------------------------------------
 ---------------------------<  wait_for_file_in_fmw  >------------------
 -----------------------------------------------------------------------
function wait_for_file_in_fmw(p_request_id IN NUMBER,
                              p_file_name  IN VARCHAR2,
		              p_error_message OUT VARCHAR2,
		              interval   IN number default 30,
		              max_wait   IN number default 0) 
 return  VARCHAR2;

PROCEDURE xx_single_batch_submit(x_errbuf         OUT   VARCHAR2
                                  ,x_retcode      OUT   NUMBER
                                  ,p_event_name   IN    VARCHAR2
                                  ,p_request_id   IN    NUMBER
                                  ,p_batch_number IN    NUMBER
                               );
 -----------------------------------------------------------------------
 -----------------------<  rem_special_char  >--------------------------
 -----------------------------------------------------------------------
FUNCTION rem_special_char(p_string IN VARCHAR2)
RETURN VARCHAR2;
 -----------------------------------------------------------------------
 -----------------------<  alert_error_files  >-------------------------
 -----------------------------------------------------------------------
PROCEDURE alert_error_files(p_request_id IN NUMBER);
   -----------------------------------------------------------------------
   -----------------------<  set_session_language  >-------------------------
   -----------------------------------------------------------------------
PROCEDURE set_session_language( p_email_id IN VARCHAR2 DEFAULT NULL
                               ,p_user_id  IN VARCHAR2 DEFAULT NULL );
   -----------------------------------------------------------------------
   -----------------------<  get_ou_specific_templ  >-------------------------
   -----------------------------------------------------------------------                               
function get_ou_specific_templ(p_ou_name VARCHAR2
                              ,p_cnc_pgm_short_name VARCHAR2)
RETURN VARCHAR; 

-- The below procedure launch_bursting has to be part of wave1 change.
-- Added for use in M2C-RPT-111 Commissions Report
---------------------------------------------------------------------------------
-- Procedure to launch custom bursting for reports
---------------------------------------------------------------------------------
----------------------------------------------------------------------
-----------------------<  launch_bursting  >-------------------------
-----------------------------------------------------------------------  

   PROCEDURE launch_bursting( errbuf          OUT  VARCHAR2,
                              retcode         OUT  NUMBER,
                              p_request_id    IN   NUMBER);
                             

END xx_intg_common_pkg;
/


GRANT EXECUTE ON APPS.XX_INTG_COMMON_PKG TO INTG_XX_NONHR_RO;
