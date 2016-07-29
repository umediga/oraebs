DROP PACKAGE BODY APPS.XX_INTG_COMMON_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INTG_COMMON_PKG" 
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-2012
 File Name     : XXINTGCOMMON.pkb
 Description   : This Package contain different validation functions and procedures
                 which can be used by Finance People across the development of Integra
 Change History:

 Date        Name          Remarks
 ----------- -----------   ---------------------------------------
 07-MAR-2012   IBM Development    Initial development
 11-OCT-2014 IBM Development Added launch_bursting - the program will wait for the parent 
                             request to complete before submitting the bursting program.
 11-OCT-2014   IBM Development    Added get_ou_specific_templ for OU specific changes in wave2
  */
--------------------------------------------------------------------------------------
AS
   -- Constant Variable Declarations
   --Start Need to verify below constant values
   g_dflt_debug_constant     CONSTANT NUMBER                                         := 3;
   g_dflt_message_constant   CONSTANT NUMBER                                         := 1;
   g_hard_error_constant     CONSTANT NUMBER                                         := 2;
   g_warning_constant        CONSTANT NUMBER                                         := 3;
   g_dflt_vs_constant        CONSTANT fnd_flex_value_sets.flex_value_set_name%TYPE   := 'XX_TRCFILE_PATH';
--End Need to verify above constant values
   g_open_file_status                 BOOLEAN;
   g_save_point_ctr                   NUMBER                                         := 1;
   g_event_ctr                        NUMBER                                         := 1;

   TYPE g_save_point_rec IS RECORD (
      save_point   VARCHAR2 (80),
      SEQUENCE     NUMBER
   );

   --
   -- This is used to gather the data concerning the request_id.  Many of the functions use information
   -- placed in this record to return to the user of the function.
   TYPE g_conc_rec IS RECORD (
      request_id                     fnd_concurrent_requests.request_id%TYPE                        := NULL,
      program_application_id         fnd_application.application_id%TYPE,
      application_short_name         fnd_application.application_short_name%TYPE,
      application_name               fnd_application_tl.application_name%TYPE,
      application_top                fnd_application.basepath%TYPE,
      concurrent_program_id          fnd_concurrent_programs.concurrent_program_id%TYPE,
      concurrent_program_name        fnd_concurrent_programs.concurrent_program_name%TYPE,
      user_concurrent_program_name   fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE,
      executable_id                  fnd_executables.executable_id%TYPE,
      executable_name                fnd_executables.execution_file_name%TYPE,
      responsibility_id              fnd_responsibility.responsibility_id%TYPE,
      responsibility_name            fnd_responsibility_tl.responsibility_name%TYPE,
      log_file_location              fnd_concurrent_requests.logfile_name%TYPE,
      log_file_name                  fnd_concurrent_requests.logfile_name%TYPE,
      log_file_handle                UTL_FILE.file_type                                             := NULL,
      out_file_location              fnd_concurrent_requests.outfile_name%TYPE,
      out_file_name                  fnd_concurrent_requests.outfile_name%TYPE,
      out_file_handle                UTL_FILE.file_type                                             := NULL,
      user_id                        fnd_user.user_name%TYPE,
      user_name                      fnd_user.user_name%TYPE,
      debug_level                    NUMBER,
      org_id                         NUMBER,
      message_level                  NUMBER,
      trc_file_location              fnd_concurrent_requests.logfile_name%TYPE,
      trc_file_name                  fnd_concurrent_requests.logfile_name%TYPE,
      trc_file_handle                UTL_FILE.file_type                                             := NULL,
      db_name                        v$database.NAME%TYPE,
      session_id                     NUMBER,
      write_flag                     BOOLEAN
   );

   --
   --
   TYPE g_save_point_tab IS TABLE OF g_save_point_rec
      INDEX BY BINARY_INTEGER;

   --
   g_cp_rec                           g_conc_rec;
   g_sp_tab                           g_save_point_tab;

   --
   FUNCTION validate_currency_code (p_curr_code_in IN fnd_currencies.currency_code%TYPE)
      RETURN BOOLEAN
   IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to Validate Currency Code
-- Input Parameters Description:
--
-- p_curr_code_in  : Currency Code
----------------------------------------------------------------------
      x_currency_code   fnd_currencies.currency_code%TYPE;
   BEGIN
      SELECT currency_code
        INTO x_currency_code
        FROM fnd_currencies_vl
       WHERE currency_code = p_curr_code_in AND enabled_flag = 'Y';

      RETURN TRUE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN FALSE;
      WHEN TOO_MANY_ROWS
      THEN
         raise_message_error ('validate_currency_code',
                              g_hard_error_constant,
                              'Multiple Currency Codes Exist for currency code ' || p_curr_code_in
                             );
      WHEN OTHERS
      THEN
         raise_message_error ('validate_currency_code', g_hard_error_constant, SQLERRM);
   END validate_currency_code;

   FUNCTION get_uom_conversion (
      p_current_uom   IN   mtl_uom_conversions.uom_code%TYPE,
      p_current_qty   IN   NUMBER,
      p_new_uom       IN   mtl_uom_conversions.uom_code%TYPE
   )
      RETURN NUMBER
   IS
 ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Converts quantity in a unit of measure to a new unit of measure.
--                   The function returns the new unit of measure quantity.
-- Input Parameters Description:
--
-- p_current_uom  : Current Unit of Measure
-- p_current_qty  : Current Quantity
-- p_new_uom      : Quantity in new Unit of Measure
----------------------------------------------------------------------
      x_curr_uom_class         mtl_uom_conversions.uom_class%TYPE;
      x_curr_conversion_rate   mtl_uom_conversions.conversion_rate%TYPE;
      x_new_conversion_rate    mtl_uom_conversions.conversion_rate%TYPE;
      x_new_quantity           NUMBER;
      x_loop_count             NUMBER;

      -- getting the uom class and conversion rate for the current uom code
      CURSOR c_get_uom_class (cp_current_uom mtl_uom_conversions.uom_code%TYPE)
      IS
         SELECT uom_class, conversion_rate
           FROM mtl_uom_conversions
          WHERE uom_code = cp_current_uom AND disable_date IS NULL;

      --get new unit of measure
      CURSOR c_conversion_rate (
         cp_new_uom          mtl_uom_conversions.uom_code%TYPE,
         cp_curr_uom_class   mtl_uom_conversions.uom_class%TYPE
      )
      IS
         SELECT conversion_rate
           FROM mtl_uom_conversions
          WHERE uom_code = cp_new_uom AND uom_class = cp_curr_uom_class;
   BEGIN
      -- initializing the loop count to zero
      x_loop_count := 0;

      -- Checking whether any Input Argument is NULL
      IF p_current_uom IS NULL
      THEN
         raise_message_error ('get_uom_conversion', g_hard_error_constant, 'current input uom can not be null');
      ELSIF p_current_qty IS NULL
      THEN
         raise_message_error ('get_uom_conversion', g_hard_error_constant, 'current input quantity can not be null');
      ELSIF p_new_uom IS NULL
      THEN
         raise_message_error ('get_uom_conversion', g_hard_error_constant, 'new input uom can not be null');
      END IF;

      -- Openening the Cursor with For Loop
      FOR c_uom_class_rec IN c_get_uom_class (p_current_uom)
      LOOP
         x_curr_uom_class := c_uom_class_rec.uom_class;
         x_curr_conversion_rate := c_uom_class_rec.conversion_rate;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 0
      THEN
         raise_message_error ('GET_UOM_CONVERSION',
                              g_hard_error_constant,
                              'No data found for the invalid input UOM  ' || p_current_uom
                             );
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('GET_UOM_CONVERSION',
                              g_hard_error_constant,
                              'Too many rows found for UOM Code ' || p_current_uom
                             );
      END IF;

      -- initializing the loop count to zero
      x_loop_count := 0;

      FOR c_conversion_rate_rec IN c_conversion_rate (p_new_uom, x_curr_uom_class)
      LOOP
         x_new_conversion_rate := c_conversion_rate_rec.conversion_rate;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 0
      THEN
         x_new_conversion_rate := NULL;
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('GET_UOM_CONVERSION',
                              g_hard_error_constant,
                              'Too many rows found for UOM Code ' || p_new_uom || ' under UOM Class '
                              || x_curr_uom_class
                             );
      END IF;

      -- calculating the new quantity for the new uom code
      x_new_quantity := x_curr_conversion_rate / x_new_conversion_rate * p_current_qty;
      RETURN x_new_quantity;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('get_uom_conversion', g_hard_error_constant, SQLERRM);
   END get_uom_conversion;

   FUNCTION validate_period (
      p_app_short_name   IN   fnd_application.application_short_name%TYPE,
      p_org_id           IN   hr_operating_units.organization_id%TYPE,
      p_date             IN   DATE,
      p_period_name      IN   gl_period_statuses_v.period_name%TYPE
   )
      RETURN BOOLEAN
 ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to check whether a given Period exist and Open for different Modules like --                   AR,AP,GL,PO etc....
-- Input Parameters Description:
--
-- p_app_short_name  : Application Short Name
-- p_org_id          : Organization Id
-- p_date            : date against which we need to check the period
-- p_period_name     : Period Name
----------------------------------------------------------------------
   IS
      CURSOR c_period_exist (
         cp_appl_short_name   fnd_application.application_short_name%TYPE,
         cp_org_id            hr_operating_units.organization_id%TYPE,
         cp_date              DATE,
         cp_period_name       gl_period_statuses_v.period_name%TYPE
      )
      IS
         SELECT gps.period_name period_name
           FROM gl_period_statuses_v gps, fnd_application fa, hr_operating_units hou
          WHERE gps.application_id = fa.application_id
            AND gps.set_of_books_id = hou.set_of_books_id
            AND hou.organization_id = cp_org_id
            AND gps.adjustment_period_flag = 'N'
            AND gps.closing_status = 'O'
            AND fa.application_short_name = cp_appl_short_name
            AND gps.period_name = cp_period_name
            AND cp_date BETWEEN TRUNC (gps.start_date) AND TRUNC (NVL (gps.end_date, SYSDATE));

      x_period_name   gl_period_statuses_v.period_name%TYPE;
      x_loop_count    NUMBER;
   BEGIN
      -- Initializing the loop count to zero
      x_loop_count := 0;

      FOR c_period_exist_rec IN c_period_exist (p_app_short_name, p_org_id, p_date, p_period_name)
      LOOP
         x_period_name := c_period_exist_rec.period_name;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 1
      THEN
         RETURN TRUE;
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('VALIDATE_PERIOD',
                              g_hard_error_constant,
                              'Multiple Rows exist for the period - ' || p_period_name
                             );
      ELSIF x_loop_count = 0
      THEN
         RETURN FALSE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('VALIDATE_PERIOD', g_hard_error_constant, SQLERRM);
   END validate_period;

   FUNCTION get_period (
      p_app_short_name   IN   fnd_application.application_short_name%TYPE,
      p_org_id           IN   hr_operating_units.organization_id%TYPE,
      p_date             IN   DATE
   )
      RETURN VARCHAR2
 ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to return Open Period Name for the Given Application ,date and organization
-- Input Parameters Description:
--
-- p_app_short_name  : Application Short Name
-- p_org_id          : Organization Id
-- p_date            : date against which we need to check the period
----------------------------------------------------------------------
   IS
      CURSOR c_period (
         cp_appl_short_name   fnd_application.application_short_name%TYPE,
         cp_org_id            hr_operating_units.organization_id%TYPE,
         cp_date              DATE
      )
      IS
         SELECT gps.period_name period_name
           FROM gl_period_statuses_v gps, fnd_application fa, hr_operating_units hou
          WHERE gps.application_id = fa.application_id
            AND gps.set_of_books_id = hou.set_of_books_id
            AND hou.organization_id = cp_org_id
            AND gps.adjustment_period_flag = 'N'
            AND gps.closing_status = 'O'
            AND fa.application_short_name = cp_appl_short_name
            AND cp_date BETWEEN TRUNC (gps.start_date) AND TRUNC (NVL (gps.end_date, SYSDATE));

      x_period_name   gl_period_statuses_v.period_name%TYPE;
      x_loop_count    NUMBER;
   BEGIN
      -- initializing the loop count to zero
      x_loop_count := 0;

      FOR c_period_rec IN c_period (p_app_short_name, p_org_id, p_date)
      LOOP
         x_period_name := c_period_rec.period_name;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 1
      THEN
         RETURN x_period_name;
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('get_period',
                              g_hard_error_constant,
                                 'Multiple Open periods exist for Org Id - '
                              || p_org_id
                              || ' under Application - '
                              || p_app_short_name
                             );
      ELSIF x_loop_count = 0
      THEN
         RETURN NULL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_PERIOD', g_hard_error_constant, SQLERRM);
   END get_period;

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
   )
   IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to return Concatenated Segments as well as Individual segment values for a given --                   CCID value
-- Input Parameters Description:
--
-- p_org_name              : Organization Name
-- p_ccid                  : Code Combination Id
-- x_concatenated_segment  : Concatenated Segments
-- x_segment1              : Segment1 Value
-- x_segment2              : Segment2 Value
-- x_segment3              : Segment3 Value
-- x_segment4              : Segment4 Value
-- x_segment5              : Segment5 Value
-- x_segment6              : Segment6 Value
-- x_segment7              : Segment7 Value
----------------------------------------------------------------------
      CURSOR c_coa_segments (
         cp_org_name   hr_operating_units.NAME%TYPE,
         cp_ccid       gl_code_combinations_kfv.code_combination_id%TYPE
      )
      IS
         SELECT gcc.concatenated_segments concatenated_segments, gcc.segment1 segment1, gcc.segment2 segment2,
                gcc.segment3 segment3, gcc.segment4 segment4, gcc.segment5 segment5, gcc.segment6 segment6,
                gcc.segment7 segment7
           FROM hr_operating_units hou, gl_sets_of_books sob, gl_code_combinations_kfv gcc
          WHERE hou.NAME = cp_org_name
            AND hou.set_of_books_id = sob.set_of_books_id
            AND sob.chart_of_accounts_id = gcc.chart_of_accounts_id
            AND gcc.code_combination_id = cp_ccid;

      x_loop_count   NUMBER;
   BEGIN
      -- initializing the loop count to zero
      x_loop_count := 0;

      FOR c_coa_segments_rec IN c_coa_segments (p_org_name, p_ccid)
      LOOP
         x_concatenated_segment := c_coa_segments_rec.concatenated_segments;
         x_segment1 := c_coa_segments_rec.segment1;
         x_segment2 := c_coa_segments_rec.segment2;
         x_segment3 := c_coa_segments_rec.segment3;
         x_segment4 := c_coa_segments_rec.segment4;
         x_segment5 := c_coa_segments_rec.segment5;
         x_segment6 := c_coa_segments_rec.segment6;
         x_segment7 := c_coa_segments_rec.segment7;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 0
      THEN
         x_concatenated_segment := NULL;
         x_segment1 := NULL;
         x_segment2 := NULL;
         x_segment3 := NULL;
         x_segment4 := NULL;
         x_segment5 := NULL;
         x_segment6 := NULL;
         x_segment7 := NULL;
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('GET_COA_SEGMENTS',
                              g_hard_error_constant,
                              'Multiple Entries exist against CCID - ' || p_ccid
                             );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_COA_SEGMENTS', g_hard_error_constant, SQLERRM);
   END get_coa_segments;

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
      RETURN NUMBER
   IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function to return code combination id for the Concatenated Segments as well as Individual segment values.
--                   If the Concatenated Segment Value is NULL then function will form the concatenated segment
--                   with individual segment values and proper segment delimiter.
-- Input Parameters Description:
--
-- p_org_name              : Organization Name
-- p_ccid                  : Code Combination Id
-- p_concatenated_segment  : Concatenated Segments
-- p_segment1              : Segment1 Value
-- p_segment2              : Segment2 Value
-- p_segment3              : Segment3 Value
-- p_segment4              : Segment4 Value
-- p_segment5              : Segment5 Value
-- p_segment6              : Segment6 Value
-- p_segment7              : Segment7 Value
------------------------------------------------------------------------------------
      x_concatenated_segment   gl_code_combinations_kfv.concatenated_segments%TYPE;
      x_ccid                   gl_code_combinations_kfv.code_combination_id%TYPE;
      x_coa_id                 gl_sets_of_books.chart_of_accounts_id%TYPE;
      x_segment_delimeter      fnd_id_flex_structures_vl.concatenated_segment_delimiter%TYPE;
      x_loop_count             NUMBER;

      -- cursor to get the chart of account id for the given Operating Unit
      CURSOR c_chart_of_acct (cp_org_name hr_operating_units.NAME%TYPE)
      IS
         SELECT sob.chart_of_accounts_id chart_of_accounts_id
           FROM gl_sets_of_books sob, hr_operating_units hou
          WHERE hou.NAME = cp_org_name AND hou.set_of_books_id = sob.set_of_books_id;

      -- cursor for getting the concatenated segment delimiter and auto creation of gl account flag value
      CURSOR c_concat_seg_dlmtr (cp_coa_id gl_code_combinations_kfv.code_combination_id%TYPE)
      IS
         SELECT fifs.concatenated_segment_delimiter AS segment_delimiter
           FROM fnd_id_flex_structures_vl fifs
          WHERE fifs.id_flex_code = 'GL#' AND fifs.id_flex_num = cp_coa_id;
   BEGIN
      -- Initializing the loop count to zero.
      x_loop_count := 0;

      -- Opening the cursor to get chart of accounts Id for the given Operating Unit.
      FOR c_chart_of_acct_rec IN c_chart_of_acct (p_org_name)
      LOOP
         x_coa_id := c_chart_of_acct_rec.chart_of_accounts_id;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 0
      THEN
         x_coa_id := NULL;
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('GET_COA_CCID',
                              g_hard_error_constant,
                              'Too Many rows found in Table gl_sets_of_books for the Operating Unit ' || p_org_name
                             );
      END IF;

      -- If the value of parameter p_concatenated_segment is null then
      -- form the concatenated segment with individual segments and proper segment delimiter
      IF p_concatenated_segment IS NULL
      THEN
         -- initializing the loop count to zero
         x_loop_count := 0;

         -- Opening the cursor to Get concatinated segment delimiter value.
         FOR c_concat_seg_rec IN c_concat_seg_dlmtr (x_coa_id)
         LOOP
            x_segment_delimeter := c_concat_seg_rec.segment_delimiter;
            x_loop_count := x_loop_count + 1;
         END LOOP;

         IF x_loop_count = 0
         THEN
            x_segment_delimeter := NULL;
         ELSIF x_loop_count > 1
         THEN
            raise_message_error ('get_coa_ccid',
                                 g_hard_error_constant,
                                    'More than one entry found in fnd_id_flex_structures_vl for chart of account id: '
                                 || x_coa_id
                                );
         END IF;

          --  code commented to make changes as told by James Moore ( Jim).
         --  Commented on 26-Feb-2008
          --  x_concatenated_segment :=
         --                        p_segment1
          --                      || x_segment_delimeter
         --                   || p_segment2
         --                      || x_segment_delimeter
         --                   || p_segment3
         --                      || x_segment_delimeter
         --                   || p_segment4
         --                      || x_segment_delimeter
          --                      || p_segment5
         --                      || x_segment_delimeter
         --                      || p_segment6
          --                      || x_segment_delimeter
         --                      || p_segment7;
         -- Code Added on 26-Feb-2008 to make this function handle segment1 - 10.
         -- Segment1 is Mandatory and segment 2 - 10 can be blank and if any segment
         -- is blnak that will not be concatinated while forming the concatinated string.
         x_concatenated_segment := p_segment1;

         IF p_segment2 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment2;
         END IF;

         IF p_segment3 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment3;
         END IF;

         IF p_segment4 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment4;
         END IF;

         IF p_segment5 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment5;
         END IF;

         IF p_segment6 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment6;
         END IF;

         IF p_segment7 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment7;
         END IF;

         IF p_segment8 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment8;
         END IF;

         IF p_segment9 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment9;
         END IF;

         IF p_segment10 IS NOT NULL
         THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment10;
         END IF;
       --
          -- Code change ends here
      --
      ELSIF p_concatenated_segment IS NOT NULL
      THEN
         -- If the value of parameter p_concatenated_segment is not null then
         -- directely assign its value to variable x_concatenated_segment
         x_concatenated_segment := p_concatenated_segment;
      END IF;

      -- Calling the Oracle Standard Function Get_Ccid
      -- This function will just return the code combination id ,if the Code Combination already exist.
      -- Otherwise the function will create a new code combination and return the new code combination id
      x_ccid := gl_code_combinations_pkg.get_ccid (x_coa_id, SYSDATE, x_concatenated_segment);
      RETURN x_ccid;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_COA_CCID', g_hard_error_constant, SQLERRM);
   END get_coa_ccid;

   FUNCTION get_currency_rate (
      p_query_date        IN   DATE,
      p_from_currency     IN   gl_daily_rates.from_currency%TYPE,
      p_to_currency       IN   gl_daily_rates.to_currency%TYPE,
      p_conversion_type   IN   gl_daily_rates.conversion_type%TYPE
   )
      RETURN NUMBER
   IS
-------------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : function retrieves the currency rate for currency code on a certain date.
-- Input Parameters Description:
--
-- p_query_date       : Date desired for currency rate
-- p_from_currency    : Currency being converted from
-- p_to_currency      : Currency being converted to
-- p_conversion_type  : Conversion type
-------------------------------------------------------------------------
     CURSOR c_conversion_rate(
         cp_query_date             DATE,
         cp_from_currency     IN   gl_daily_rates.from_currency%TYPE,
         cp_to_currency       IN   gl_daily_rates.to_currency%TYPE,
         cp_conversion_type   IN   gl_daily_rates.conversion_type%TYPE
                               )
     IS
     SELECT conversion_rate
       FROM gl_daily_rates
      WHERE from_currency   = cp_from_currency
        AND to_currency     = cp_to_currency
        AND conversion_date = cp_query_date
        AND conversion_type = cp_conversion_type
      ;

     CURSOR c_get_previous_rate(
         cp_query_date             DATE,
         cp_from_currency     IN   gl_daily_rates.from_currency%TYPE,
         cp_to_currency       IN   gl_daily_rates.to_currency%TYPE,
         cp_conversion_type   IN   gl_daily_rates.conversion_type%TYPE
                               )
     IS
     SELECT conversion_rate
           ,conversion_date
       FROM gl_daily_rates
      WHERE from_currency   = cp_from_currency
        AND to_currency     = cp_to_currency
        AND conversion_date < cp_query_date
        AND conversion_type = cp_conversion_type
      ORDER BY conversion_date DESC
      ;

      x_conversion_rate   gl_daily_rates.conversion_rate%TYPE;
      x_loop_count        NUMBER;
      x_conversion_date   DATE;
   BEGIN
      -- initializing the loop count to zero
      x_loop_count := 0;

      FOR c_conv_rate_rec IN c_conversion_rate (p_query_date, p_from_currency, p_to_currency, p_conversion_type)
      LOOP
         x_conversion_rate := c_conv_rate_rec.conversion_rate;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 1
      THEN
         RETURN x_conversion_rate;
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('get_currency_rate', g_hard_error_constant, 'Too many rows found');
      ELSIF x_loop_count = 0
      THEN
         OPEN c_get_previous_rate(p_query_date, p_from_currency, p_to_currency, p_conversion_type);
         FETCH c_get_previous_rate INTO x_conversion_rate,x_conversion_date;
         CLOSE c_get_previous_rate;

         IF x_conversion_rate IS NOT NULL THEN
            RETURN x_conversion_rate;
         ELSE
            RETURN NULL;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('get_currency_rate', g_hard_error_constant, SQLERRM);
   END get_currency_rate;

   PROCEDURE raise_message_error (p_proc_name VARCHAR2, p_error_level NUMBER, p_message VARCHAR2)
   IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure raise error message
-- Parameters Description
-- p_proc_name        :
-- p_error_level               :
-- p_message                   :
----------------------------------------------------------------------
   BEGIN
      IF p_error_level = g_hard_error_constant
      THEN
         --   generate_warning (
         --         'EXITING FROM : '
         --      || p_proc_name
         --      || ' : '
         --      || p_message
         --   );
         write_log ('EXITING FROM : ' || p_proc_name || ' : ' || p_message);
         raise_application_error (-20001, p_proc_name || ':' || p_message);
      ELSIF g_warning_constant = g_hard_error_constant
      THEN
         --  generate_warning (   p_proc_name
         --                    || '.........'
         --                    || p_message);
         write_log (p_proc_name || ' : ' || p_message);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END raise_message_error;

--Start 14 Feb VishnuPerala:The following functions and procedures that are in the code have been placed in hold for
--the present time.  In the future if we find a need for any of the functions or procedures,
-- we will review the those required and make them functional.
   --commenting out below procedures/functions
   --   FUNCTION get_value (
--      p_name             fnd_flex_values.flex_value%TYPE,
--      p_value_set_name   VARCHAR2 DEFAULT NULL
--   )
--      RETURN VARCHAR2
--   IS
--
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Function returns with the trace file location.
--                  If the valueset name is not passed as parameter , it takes default value set name from --                  G_DFLT_VS_CONSTANT
-- Parameters Description
-- p_name             : Name of flexifiled value that stores the trace file location
-- p_value_set_name            : Name of the valueset
-- RETURN                      : Trace file location
----------------------------------------------------------------------
   --      CURSOR c_unix_path (
--         cp_value_set_name   fnd_flex_value_sets.flex_value_set_name%TYPE
--      )
--      IS
--         SELECT ffv.description
--           FROM fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
--          WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
--            AND ffvs.flex_value_set_name = cp_value_set_name
--            AND ffv.flex_value = p_name;
--
--      x_unix_path            fnd_flex_values_vl.description%TYPE;
--      x_value_set_name       fnd_flex_value_sets.flex_value_set_name%TYPE;
--      e_unix_path_notfound   EXCEPTION;
--   BEGIN
--      --Check the parameter p_value_set_name
--      x_value_set_name := NVL (p_value_set_name, g_dflt_vs_constant);
--
--      --Open cursor to get the file location
--      FOR c_unix_path_rec IN c_unix_path (x_value_set_name)
--      LOOP
--         x_unix_path := c_unix_path_rec.description;
--      END LOOP;
   --      --Check whether Unix path has been defined or not
--      IF x_unix_path IS NULL
--      THEN
--         RAISE e_unix_path_notfound;
--      ELSE
--         RETURN x_unix_path;
--      END IF;
--   EXCEPTION
--      WHEN e_unix_path_notfound
--      THEN
--         raise_message_error (
--            'GET_VALUE',
--            g_hard_error_constant,
--               'Record Not Found For Value Set Name : '
--            || x_value_set_name
--            || ' Variable Name : '
--            || p_name
--         );
--      WHEN OTHERS
--      THEN
--         raise_message_error ('GET_VALUE', g_hard_error_constant, SQLERRM);
--   END get_value;
   PROCEDURE initialization
   IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to get current environment details and opens a
--                  file and appends heading to the file.
----------------------------------------------------------------------
      --extracts environment details for a request ID
      CURSOR c_cp_info (cp_request_id fnd_concurrent_requests.request_id%TYPE)
      IS
         SELECT con.request_id req_id, con.program_application_id p_app_id, app.application_short_name app_sname,
                app.application_name app_name, con.concurrent_program_id cp_id, pgm.concurrent_program_name cp_name,
                pgm.user_concurrent_program_name cp_user_name, exe.executable_id exe_id,
                NVL (exe.execution_file_name, exe.executable_name) exe_name, con.responsibility_id resp_id,
                res.responsibility_name resp_name,
                SUBSTR (logfile_name, INSTR (logfile_name, '/', -1) + 1, LENGTH (logfile_name)),
                SUBSTR (logfile_name, 1, INSTR (logfile_name, '/', -1) - 1),
                SUBSTR (outfile_name, INSTR (outfile_name, '/', -1) + 1, LENGTH (outfile_name)),
                SUBSTR (outfile_name, 1, INSTR (outfile_name, '/', -1) - 1), LOWER (db.NAME) db, USERENV ('SESSIONID'),
                   '$'
                || app.basepath
                || DECODE (exe.execution_method_code, 'I', '/src', 'L', '/bin', 'Q', '/sql', 'R', '/srw', NULL),
                NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1),
                                        ' ', NULL,
                                        SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                       )
                               ),
                     -99
                    )
           FROM fnd_concurrent_requests con,
                fnd_application_vl app,
                fnd_concurrent_programs_vl pgm,
                fnd_executables exe,
                fnd_responsibility_tl res,
                v$database db
          WHERE con.responsibility_id = res.responsibility_id
            AND con.program_application_id = app.application_id
            AND con.concurrent_program_id = pgm.concurrent_program_id
            AND con.program_application_id = pgm.application_id
            AND pgm.executable_application_id = exe.application_id
            AND pgm.executable_id = exe.executable_id
            AND con.request_id = cp_request_id;

      --To fetch db name
      CURSOR c_db_info
      IS
         SELECT db.NAME db
           FROM v$database db;
   -- x_open_file_status   BOOLEAN := FALSE;
   BEGIN
      --Set the initialise global variable vaue
      --g_isinitialise := TRUE;
      --get the reuqest id
      g_cp_rec.request_id := NVL (g_cp_rec.request_id, fnd_global.conc_request_id);

      --Check whether calling program concurrent program or not
      IF g_cp_rec.request_id IS NOT NULL AND g_cp_rec.request_id != -1
      THEN
         --Calling Program is concurrent program
         FOR c_cp_info_rec IN c_cp_info (g_cp_rec.request_id)
         LOOP
            --Store environment values in global record
            g_cp_rec.program_application_id := c_cp_info_rec.p_app_id;
            g_cp_rec.application_short_name := c_cp_info_rec.app_sname;
            g_cp_rec.application_name := c_cp_info_rec.app_name;
            g_cp_rec.concurrent_program_id := c_cp_info_rec.cp_id;
            g_cp_rec.concurrent_program_name := c_cp_info_rec.cp_name;
            g_cp_rec.user_concurrent_program_name := c_cp_info_rec.cp_user_name;
            g_cp_rec.executable_id := c_cp_info_rec.exe_id;
            g_cp_rec.executable_name := c_cp_info_rec.exe_name;
            g_cp_rec.responsibility_id := c_cp_info_rec.resp_id;
            g_cp_rec.responsibility_name := c_cp_info_rec.resp_name;
            g_cp_rec.log_file_name := NULL;
            g_cp_rec.log_file_location := NULL;
            g_cp_rec.out_file_name := NULL;
            g_cp_rec.out_file_location := NULL;
            g_cp_rec.db_name := c_cp_info_rec.db;
            g_cp_rec.user_name := fnd_profile.VALUE ('USERNAME');
            g_cp_rec.user_id := NVL (fnd_profile.VALUE ('USER_ID'), -1);
            g_cp_rec.write_flag := g_write_flag;
         END LOOP;
      ELSE
         --Calling Program is not a concurrent program
         g_cp_rec.request_id := 0;
         g_cp_rec.program_application_id := NVL (fnd_profile.VALUE ('RESP_APPL_ID'), -1);
         g_cp_rec.application_short_name := NULL;
         g_cp_rec.application_name := NULL;
         g_cp_rec.concurrent_program_id := -1;
         g_cp_rec.concurrent_program_name := 'NonConcPgm';
         g_cp_rec.user_concurrent_program_name := 'NonConcPgm';
         g_cp_rec.executable_id := -1;
         g_cp_rec.executable_name := 'NonConcPgm';
         g_cp_rec.responsibility_id := NVL (fnd_profile.VALUE ('RESP_ID'), -1);
         g_cp_rec.responsibility_name := NULL;
         g_cp_rec.log_file_name := NULL;
         g_cp_rec.log_file_location := NULL;
         g_cp_rec.out_file_name := NULL;
         g_cp_rec.out_file_location := NULL;
         g_cp_rec.db_name := NULL;
         g_cp_rec.user_name := fnd_profile.VALUE ('USERNAME');
         g_cp_rec.user_id := NVL (fnd_profile.VALUE ('USER_ID'), -1);
         g_cp_rec.write_flag := g_write_flag;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('INITIALIZATION', g_hard_error_constant, SQLERRM);
   END initialization;

   PROCEDURE message_enable
   IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Procedure to enable messaging. It would be used while
--                   calling from non Concurrent Programs.
----------------------------------------------------------------------
   BEGIN
      -- Check to run initialisation  if not initialise
      IF NOT (g_isinitialise)
      THEN
         initialization;
      END IF;
      --Enable messages with default values
--      message_enable (g_dflt_debug_constant, g_dflt_message_constant);
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('MESSAGE_ENABLE', g_hard_error_constant, SQLERRM);
   END message_enable;

   PROCEDURE message_enable (p_request_id NUMBER)
   IS
----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to enable messaging for a specific concurrent program.
--                  This would be the first procedure needs to be called for setting messages.
-- Parameters Description
-- p_request_id          : Request ID of the concurrent program
----------------------------------------------------------------------
   BEGIN
      --Store the request id in global variable
      g_cp_rec.request_id := p_request_id;
      --Initialise the environment
      initialization;
      --Enable messages with default values
--      message_enable (g_dflt_debug_constant, g_dflt_message_constant);
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('MESSAGE_ENABLE', g_hard_error_constant, SQLERRM);
   END message_enable;

--   PROCEDURE message_enable (p_debug_level IN NUMBER, p_message_level IN NUMBER)
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to set debug level and message level
-- Parameters Description
-- p_debug_level         : Debug level to set
-- p_message_level             : Message level to set
----------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
   --      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --      --Set the message and debug levels
--      g_cp_rec.debug_level := p_debug_level;
--      g_cp_rec.message_level := p_message_level;
      --Call log_heading to write heading messages to the files
--      log_heading;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'MESSAGE_ENABLE',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END message_enable;
   --   PROCEDURE message_save_point (p_save_point IN VARCHAR2)
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to issue save points and writes save point details to file
-- Parameters Description
-- p_save_point          : Savepoint name
---------------------------------------------------------------------
   --      x_sql_statement   VARCHAR2 (2000);
--      x_sql_cursor      NUMBER;
--      x_sql_return      NUMBER;
--      x_sp_exist        BOOLEAN         := FALSE;
--   BEGIN
--      --Check whether savepoint name existed in the savepoint table.
--      FOR x_sp IN 1 .. g_sp_tab.COUNT
--      LOOP
--         IF (UPPER (g_sp_tab (x_sp).save_point) = UPPER (p_save_point))
--         THEN
--            x_sp_exist := TRUE;
--            EXIT;
--         END IF;
--      END LOOP;
   --Store savepoint info in savepoint tab.
--      IF NOT (x_sp_exist)
--      THEN
--         g_sp_tab (g_save_point_ctr).save_point := UPPER (p_save_point);
--         g_sp_tab (g_save_point_ctr).SEQUENCE := g_save_point_ctr;
--         g_save_point_ctr :=   g_save_point_ctr
--                             + 1;
--      END IF;
   --
      --Prepare statement to issue savepoint
--      x_sql_statement :=    'SAVEPOINT '
--                         || UPPER (p_save_point);
      --Write savepoint info into file
--      write_log (   'Issueing Save Point '
--                 || x_sql_statement);
      --open cursor to issue savepoint
--      x_sql_cursor := DBMS_SQL.open_cursor;
      --parse the sql statement
--      DBMS_SQL.parse (x_sql_cursor, x_sql_statement, DBMS_SQL.v7);
      --issue savepoint
--      x_sql_return := DBMS_SQL.EXECUTE (x_sql_cursor);
      --close the cursor
--      DBMS_SQL.close_cursor (x_sql_cursor);
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'MESSAGE_SAVE_POINT',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END message_save_point;
   --   PROCEDURE message_rollback_to (p_save_point IN VARCHAR2)
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to rollback to specific savepoint
-- Parameters Description
-- p_save_point          : Savepoint name
---------------------------------------------------------------------
   --      x_sql_statement      VARCHAR2 (2000);
--      x_sql_cursor         NUMBER;
--      x_sql_return         NUMBER;
--      x_save_point_list    VARCHAR2 (2000);
--      x_save_point_found   BOOLEAN         := FALSE;
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Check whether savepoint name existed in the savepoint table.
--      FOR x_sp IN 1 .. g_sp_tab.COUNT
--      LOOP
--         BEGIN
--            IF (g_sp_tab (x_sp).save_point = UPPER (p_save_point))
--            THEN
--               x_save_point_found := TRUE;
--               write_log (   'Rollbacking till '
--                          || p_save_point);
   --We need to remove all the savepoints which were issued before savepoint param value
--               IF (g_sp_tab (x_sp).SEQUENCE != g_sp_tab.COUNT)
--               THEN
                  --Loop thru till savepoint param value
--                  FOR x_dup_ctr IN 1 .. g_sp_tab (x_sp).SEQUENCE
--                  LOOP
                     --Write savepoint info to a variable
--                     x_save_point_list :=    x_save_point_list
--                                          || CHR (10)
--                                          || g_sp_tab (x_dup_ctr).save_point;
                     --Mark savepoint for deletion
--                     g_sp_tab (x_dup_ctr).save_point := '#DELETE#';
--                  END LOOP;
   --Mark savepoint for deletion
--                  g_sp_tab (x_sp).save_point := '#DELETE#';
                  --Write to be rolled back savepoint info to file
--                  write_log ('Rollingback Following Save Points : ');
--                  write_log (p_save_point);
--               END IF;
   --Prepare sql stmt
--               x_sql_statement :=    'ROLLBACK TO '
--                                  || UPPER (p_save_point);
--               write_log (   ' Rollback Statement  '
--                          || x_sql_statement);
               --Open cursor to issue rollbacl
--               x_sql_cursor := DBMS_SQL.open_cursor;
--               DBMS_SQL.parse (x_sql_cursor, x_sql_statement, DBMS_SQL.v7);
               --issue rollback stmt
--               x_sql_return := DBMS_SQL.EXECUTE (x_sql_cursor);
--               DBMS_SQL.close_cursor (x_sql_cursor);
--               EXIT;
--            END IF;
--         END;
--      END LOOP;
   --if savepoint not found raise error message
--      IF NOT (x_save_point_found)
--      THEN
--         raise_message_error (
--            'MESSAGE_ROLLBACK_TO',
--            g_hard_error_constant,
--               'Invalid Save Point : '
--            || p_save_point
--         );
--      END IF;
   --if savepoint found delete save points from save point table
--      IF (x_save_point_found)
--      THEN
--         FOR x_sp2 IN 1 .. g_sp_tab.COUNT
--         LOOP
--            IF (g_sp_tab (x_sp2).save_point = '#DELETE#')
--            THEN
--               g_sp_tab.DELETE (x_sp2);
--            END IF;
         --
--         END LOOP;
   --
         -- Initialise Counter
         --
--         g_save_point_ctr :=   g_sp_tab.COUNT
--                             + 1;
      --
      --
--      END IF;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'MESSAGE_ROLLLBACK_TO',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END message_rollback_to;
   --   PROCEDURE message_close (px_file_handle IN OUT UTL_FILE.file_type)
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to flushes the data to file and closes the file.
-- Parameters Description
-- px_file_handle        : File handle
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --close the files
--      UTL_FILE.fclose (px_file_handle);
--   EXCEPTION
--      WHEN UTL_FILE.invalid_filehandle
--      THEN
--         raise_message_error (
--            'MESSAGE_CLOSE',
--            g_hard_error_constant,
--               ' Invalid File Handle: '
--            || SQLERRM
--         );
--      WHEN UTL_FILE.write_error
--      THEN
--         raise_message_error (
--            'MESSAGE_CLOSE',
--            g_hard_error_constant,
--               ' Error while writing to the file: '
--            || SQLERRM
--         );
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'MESSAGE_CLOSE',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END message_close;
   --   PROCEDURE message_rollback
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to rollback changes database and closes the file.
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --rollback the changes
--      ROLLBACK;
      --Flushes the data to file and close the file
--      message_close (g_log_file_handle);
--      COMMIT;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'MESSAGE_ROLLBACK',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END message_rollback;
   --   PROCEDURE message_commit
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to commit changes database and closes the file
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Flushes the data to file and close the file
--      message_close (g_log_file_handle);
--      COMMIT;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'MESSAGE_COMMIT',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END message_commit;
--   PROCEDURE message_flush (px_file_handle IN OUT UTL_FILE.file_type)
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to flushes the data from the buffer to file.
-- Parameters Description
-- px_file_handle        : File handle
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Flushes the data to file using util file API
--      UTL_FILE.fflush (px_file_handle);
--   EXCEPTION
--      WHEN UTL_FILE.invalid_operation
--      THEN
--         raise_message_error (
--            'MESSAGE_FLUSH',
--            g_hard_error_constant,
--            ' Invalid operation on the file'
--         );
--      WHEN UTL_FILE.invalid_filehandle
--      THEN
--         raise_message_error (
--            'MESSAGE_FLUSH',
--            g_hard_error_constant,
--               ' Invalid File Handle: '
--            || SQLERRM
--         );
--      WHEN UTL_FILE.write_error
--      THEN
--         raise_message_error (
---            'MESSAGE_FLUSH',
--            g_hard_error_constant,
--               ' Error while writing to the file: '
--            || SQLERRM
--         );
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'MESSAGE_FLUSH',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END message_flush;
   --   PROCEDURE write_log_file (
--      p_message       IN   VARCHAR2,
--      p_file_handle   IN   UTL_FILE.file_type
--   )
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to writes messages to log file.
-- Parameters Description
-- p_message             : message that needs to write to file
-- p_file_handle         : File handle
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Compare the debug level and message level
--      IF (g_cp_rec.debug_level >= g_cp_rec.message_level)
--      THEN
--         IF    (NVL (g_cp_rec.request_id, 0) = 0)
--            OR g_cp_rec.request_id = -1
--         THEN
            --If calling program is not CP append with session id
--            UTL_FILE.put_line (
--               p_file_handle,
--                  TO_CHAR (g_cp_rec.session_id)
--               || ' '
--               || p_message
--            );
--         ELSE
--            UTL_FILE.put_line (p_file_handle, p_message);
--         END IF;
--      END IF;
   --Flushes the data to file using util file API
--      UTL_FILE.fflush (p_file_handle);
--   EXCEPTION
--      WHEN UTL_FILE.invalid_filehandle
--      THEN
--         raise_message_error (
--            'WRITE_LOG_FILE',
--            g_hard_error_constant,
--            'Invalid Flat File Handle'
--         );
--      WHEN UTL_FILE.write_error
--      THEN
--         raise_message_error (
--            'WRITE_LOG_FILE',
--            g_hard_error_constant,
--            'Error WHEN writing to flat file'
--         );
--      WHEN UTL_FILE.invalid_operation
--      THEN
--         raise_message_error (
--            'WRITE_LOG_FILE',
--            g_hard_error_constant,
--            ' Invalid operation on the file'
--         );
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'WRITE_LOG_FILE',
--            g_hard_error_constant,
--               'Error WHEN write to flat file: '
--            || SQLERRM
--         );
--   END write_log_file;
   --   PROCEDURE write_text_file (
--      p_message       IN   VARCHAR2,
--      p_file_handle   IN   UTL_FILE.file_type
--   )
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to writes messages to specific file and flushes the data.
-- Parameters Description
-- p_message             : message that needs to write to file
-- p_file_handle         : File handle
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Write the message to file and flush the buffer to file using util file api
--      UTL_FILE.put_line (p_file_handle, p_message);
--      UTL_FILE.fflush (p_file_handle);
--   EXCEPTION
--      WHEN UTL_FILE.invalid_filehandle
--      THEN
--         raise_message_error (
--            'WRITE_TEXT_FILE',
--            g_hard_error_constant,
--            'Invalid Flat File Handle'
--         );
--      WHEN UTL_FILE.write_error
--      THEN
--         raise_message_error (
--            'WRITE_TEXT_FILE',
--            g_hard_error_constant,
--            'Error WHEN writing to flat file'
--         );
--      WHEN UTL_FILE.invalid_operation
--      THEN
--         raise_message_error (
--            'WRITE_TEXT_FILE',
--            g_hard_error_constant,
--            ' Invalid operation on the file'
--         );
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'WRITE_TEXT_FILE',
--            g_hard_error_constant,
--               'Error WHEN write to flat file: '
--            || SQLERRM
--         );
--   END write_text_file;
   --   FUNCTION read_text_file (
--      x_message       OUT      VARCHAR2,
--      p_file_handle   IN       UTL_FILE.file_type
--   )
--      RETURN BOOLEAN
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure reads specific file.
-- Parameters Description
-- x_message             : message that needs to write to file
-- p_file_handle         : File handle
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --get the util file line for reading
--      UTL_FILE.get_line (p_file_handle, x_message);
--      RETURN TRUE;
--   EXCEPTION
--      WHEN NO_DATA_FOUND
--      THEN
--         RETURN FALSE;
--      WHEN VALUE_ERROR
--      THEN
--         raise_message_error (
--            'READ_TEXT_FILE',
--            g_hard_error_constant,
--            ' Line is too long to read '
--         );
--      WHEN UTL_FILE.invalid_operation
--      THEN
--         raise_message_error (
--            'READ_TEXT_FILE',
--            g_hard_error_constant,
--            'Invalid Operation Handle'
--         );
--      WHEN UTL_FILE.invalid_filehandle
--      THEN
--         raise_message_error (
--            'READ_TEXT_FILE',
--            g_hard_error_constant,
--            'Invalid Flat File Handle'
--         );
--      WHEN UTL_FILE.read_error
--      THEN
--         raise_message_error (
--            'READ_TEXT_FILE',
--            g_hard_error_constant,
--            'Error WHEN reading flat file'
--         );
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'READ_TEXT_FILE',
--            g_hard_error_constant,
--               'Error WHEN trying to read flat file'
--            || SQLERRM
--         );
--   END read_text_file;
   --   PROCEDURE log_heading (p_file_handle IN UTL_FILE.file_type)
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure appends heading to log file.
-- Parameters Description
-- p_file_handle         : File handle
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --      write_text_file (
--            '         Oracle Application Name : '
--         || g_cp_rec.application_name,
--         p_file_handle
--      );
--      write_text_file (
--            '         Concurrent Program Name : '
--         || g_cp_rec.user_concurrent_program_name,
--         p_file_handle
--      );
--      write_text_file (
--            '           Concurrent Short Name : '
--         || g_cp_rec.concurrent_program_name,
--         p_file_handle
--      );
--      write_text_file (
--            '                Program Location : '
--         || g_cp_rec.application_top,
--         p_file_handle
--      );
--      write_text_file (
--            '                  Unix File Name : '
--         || g_cp_rec.executable_name,
--         p_file_handle
--      );
--      write_text_file (
--            '                       User Name : '
--         || g_cp_rec.user_name,
--         p_file_handle
--      );
--      write_text_file (
--            '                      Request Id : '
--         || g_cp_rec.request_id,
--         p_file_handle
--      );
--      write_text_file (
--            '                   Date and Time : '
--         || TO_CHAR (SYSDATE, 'DD-Mon-YYYY HH24:MI:SS'),
--         p_file_handle
--      );
--      write_text_file (LTRIM (RPAD (' ', 79, ' ')), p_file_handle);
--      write_text_file (LTRIM (RPAD (' ', 79, '-')), p_file_handle);
--      write_text_file (LTRIM (RPAD (' ', 79, ' ')), p_file_handle);
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error ('LOG_HEADING', g_hard_error_constant, SQLERRM);
--   END log_heading;
   --   PROCEDURE log_heading (p_file_type IN VARCHAR2 DEFAULT NULL)
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure appends heading to file handle file.
-- Parameters Description
-- p_file_type        : Null is for LOG all others is OUT.
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Check whether do we need to write the log to file
--      IF g_cp_rec.write_flag = TRUE
--      THEN
--         IF (p_file_type IS NULL)
--         THEN
--            log_heading (g_log_file_handle);
--         ELSE
--            log_heading (g_out_file_handle);
--         END IF;
--      END IF;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error ('LOG_HEADING', g_hard_error_constant, SQLERRM);
--   END log_heading;
   --   PROCEDURE generate_warning (
--      p_warning_message   IN   VARCHAR2,
--      p_file_handle       IN   UTL_FILE.file_type
--   )
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to generate and write warning message to file.
-- Parameters Description
-- p_warning_message        : Message needs to be generated.
-- p_file_handle            : UTIL File handle
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Check whether file is open or not
--      IF (UTL_FILE.is_open (p_file_handle))
--      THEN
--         write_text_file ('* * * * * * * * * * * * * * *', p_file_handle);
--         write_text_file ('*       W A R N I N G       *', p_file_handle);
--         write_text_file ('* * * * * * * * * * * * * * *', p_file_handle);
--         write_text_file (p_warning_message, p_file_handle);
--         write_text_file ('* * * * * * * * * * * * * * *', p_file_handle);
--      END IF;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'GENERATE_WARNING',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END generate_warning;
   --   PROCEDURE generate_warning (
--      p_warning_message   IN   VARCHAR2,
--      p_file_flag         IN   VARCHAR2 DEFAULT NULL
--   )
--   IS
   ----------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to generate and write warning message to file.
-- Parameters Description
-- p_warning_message        : Message needs to be generated.
-- p_file_flag           : Null is for LOG all others is OUT.
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --Check for the file flag
--      IF (p_file_flag IS NULL)
--      THEN
--         generate_warning (p_warning_message, g_log_file_handle);
--      ELSE
--         generate_warning (p_warning_message, g_out_file_handle);
--      END IF;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'GENERATE_WARNING',
--            g_hard_error_constant,
--            SQLERRM
--         );
--   END generate_warning;
   --   PROCEDURE write_log (
--      p_message         IN   VARCHAR2,
--      p_message_level   IN   NUMBER DEFAULT NULL
--   )
--   IS
   ---------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : This PUBLIC procedure will writes 'message' to Log File
-- Input Parameters Description:
--
-- p_message       : message to be written to Log File
-- p_message_level : message level
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --      g_cp_rec.message_level := NVL (p_message_level, g_dflt_message_constant);
      -- calling  write_log_file procedure
--      write_log_file (p_message, g_log_file_handle);
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'write_log',
--            g_hard_error_constant,
--            SUBSTR (SQLERRM, 1, 500)
---         );
--   END write_log;
   --   PROCEDURE write_out (p_message IN VARCHAR2)
--   IS
   ---------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : This PUBLIC procedure will writes 'message' to Out File
-- Input Parameters Description:
--
-- message         : message to be written to OUT File
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   -- calling write_text_file procedure
--      write_text_file (p_message, g_out_file_handle);
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error ('WRITE_OUT', g_hard_error_constant, SQLERRM);
--   END write_out;
   --   FUNCTION get_trc_location
--      RETURN VARCHAR2
--   IS
   ---------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : function to get Default Message Location
-- Input Parameters Description:
--
---------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   --      RETURN (get_value ('Path'));
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'GET_TRC_LOCATION',
--            g_hard_error_constant,
--            SUBSTR (SQLERRM, 1, 500)
--         );
--   END get_trc_location;
   --   FUNCTION get_trc_file
--      RETURN VARCHAR2
--   IS
   ---------------------------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date    : 07-MAR-2012
-- Description      : Function will retuns the default file name defined in the value set
-- Input Parameters Description:
--
---------------------------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   -- calling the get_value function
--      RETURN (get_value ('trc_file'));
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         raise_message_error ('get_trc_file', g_hard_error_constant, SQLERRM);
--   END get_trc_file;
   --   FUNCTION open_text_file (
--      x_file_handle     OUT NOCOPY      UTL_FILE.file_type,
--      p_file_location   IN              VARCHAR2,
--      p_file_name       IN              VARCHAR2,
--      p_open_mode       IN              VARCHAR2
--   )
--      RETURN BOOLEAN
--   IS
   ---------------------------------------------------------------------------------------
 -- Created By      : IBM Development
 -- Creation Date    : 07-MAR-2012
 -- Description      : Based on input parameters function will open a file.
 --                    If the file opens successfully it returns the File Handle
 --                    and status as True .Otherwise it returns false.
 -- Input Parameters Description:
 --
 -- x_file_handle     : File Handle
 -- p_file_location   : file location
 -- p_file_name       : file name
 -- p_open_mode       : Mode in which file need to be Open
---------------------------------------------------------------------------------------
--   BEGIN
      -- Check to run initialisation  if not initialise
--      IF NOT (g_isinitialise)
--      THEN
--         initialization;
--      END IF;
   -- Opening a file using input parameter values using UTL_FILE
--      x_file_handle :=
--                    UTL_FILE.fopen (p_file_location, p_file_name, p_open_mode);
--      RETURN (TRUE);
--   EXCEPTION
--      WHEN UTL_FILE.invalid_path
--      THEN
--         raise_message_error (
--            'open_text_file',
--            g_hard_error_constant,
--               'Invalid Path : '
--            || p_file_location
--            || ' Flat File Open'
--         );
--      WHEN UTL_FILE.invalid_mode
--      THEN
--         raise_message_error (
--            'open_text_file',
--            g_hard_error_constant,
--               'Invalid Mode '
--            || p_open_mode
--            || ' for  File Open'
--         );
--      WHEN UTL_FILE.invalid_operation
--      THEN
--         raise_message_error (
--            'open_text_file',
--            g_hard_error_constant,
--            ' Invalid Operation on Flat File '
--         );
--      WHEN OTHERS
--      THEN
--         raise_message_error (
--            'open_text_file',
--            g_hard_error_constant,
--            SUBSTR (SQLERRM, 1, 500)
--         );
--   END open_text_file;
   --End 14 Feb IBM Development:The following functions and procedures that are in the code have been placed in hold for
--the present time.  In the future if we find a need for any of the functions or procedures,
-- we will review the those required and make them functional.
   --commenting out above procedures/functions
   FUNCTION get_dff_user_names (
      p_table_name_in             IN   VARCHAR2,
      p_column_name_in            IN   VARCHAR2,
      p_context_column_name_in    IN   VARCHAR2,
      p_context_column_value_in   IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Pass in the table name, context field name, context value, and column
--                                             name to get the user name for the attribute column
-- Input Parameters           :                Description
-- p_table_name_in  :         :                Table Name
-- p_column_name              :                Column Name
-- p_context_column_name_in   :                Context Column Name
-- p_context_column_value_in  :                Context Column Value
--------------------------------------------------------------------------------------------------------------------
      CURSOR c_get_dff_user_names (
         cp_table_name_in             VARCHAR2,
         cp_column_name_in            VARCHAR2,
         cp_context_column_name_in    VARCHAR2,
         cp_context_column_value_in   VARCHAR2
      )
      IS
         SELECT usa.end_user_column_name
           FROM fnd_descr_flex_col_usage_vl usa, fnd_descriptive_flexs_vl fdf
          WHERE fdf.descriptive_flexfield_name = usa.descriptive_flexfield_name
            AND usa.application_column_name = cp_column_name_in
            AND usa.descriptive_flex_context_code = cp_context_column_value_in
            AND fdf.context_column_name = cp_context_column_name_in
            AND fdf.application_table_name = cp_table_name_in;

      c_dff_usernames_rec   fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE;
      x_dff_user_name       fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE;
      x_loop_count          NUMBER                                                  := 0;
      e_no_data_found       EXCEPTION;
   BEGIN
      FOR c_dff_usernames_rec IN c_get_dff_user_names (p_table_name_in,
                                                       p_column_name_in,
                                                       p_context_column_name_in,
                                                       p_context_column_value_in
                                                      )
      LOOP
         x_dff_user_name := c_dff_usernames_rec.end_user_column_name;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 1
      THEN
         RETURN x_dff_user_name;
      ELSIF x_loop_count = 0
      THEN
         RAISE e_no_data_found;
      ELSE
         raise_message_error ('GET_DFF_USER_NAMES',
                              g_hard_error_constant,
                              'Too many user names was found for given attribute column name'
                             );
      END IF;
   EXCEPTION
      WHEN e_no_data_found
      THEN
         raise_message_error ('GET_DFF_USER_NAMES',
                              g_warning_constant,
                              'No user name was found for given attribute column name'
                             );
         RETURN NULL;
      WHEN OTHERS
      THEN
         raise_message_error ('GET_DFF_USER_NAMES', g_hard_error_constant, 'Un Expected Error');
   END get_dff_user_names;

   FUNCTION get_kff_user_names (
      p_table_name_in               IN   VARCHAR2,
      p_id_flex_code_in             IN   VARCHAR2,
      p_id_flex_structure_code_in   IN   VARCHAR2,
      p_column_name_in              IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
---------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Pass in the table name and the id_flex_code or id_flex_name to
--                                             receive the segment user name
-- Input Parameters           :                Description
-- p_table_name_in  :         :                Table Name
-- p_column_name              :                Column Name
-- p_id_flex_code_in   :                       Id Flex Code
-- p_id_flex_structure_code_in  :              Id Flex Name
---------------------------------------------------------------------------------------------------------------
      CURSOR c_get_kff_user_names (
         cp_table_name_in               VARCHAR2,
         cp_id_flex_code_in             VARCHAR2,
         cp_id_flex_structure_code_in   VARCHAR2,
         cp_column_name_in              VARCHAR2
      )
      IS
         SELECT fs.segment_name
           FROM fnd_id_flex_structures_vl fst, fnd_id_flex_segments_vl fs, fnd_id_flexs fif
          WHERE fs.id_flex_num = fst.id_flex_num
            AND fs.id_flex_code = fst.id_flex_code
            AND fif.id_flex_code = fst.id_flex_code
            AND fs.id_flex_code = cp_id_flex_code_in
            AND fif.application_table_name = cp_table_name_in
            AND fs.application_column_name = cp_column_name_in
            AND fst.id_flex_structure_code = cp_id_flex_structure_code_in;

      c_kff_usernames_rec   fnd_id_flex_segments_vl.segment_name%TYPE;
      x_kff_user_name       fnd_id_flex_segments_vl.segment_name%TYPE;
      x_loop_count          NUMBER                                      := 0;
      e_no_data_found       EXCEPTION;
   BEGIN
      FOR c_kff_usernames_rec IN c_get_kff_user_names (p_table_name_in,
                                                       p_id_flex_code_in,
                                                       p_id_flex_structure_code_in,
                                                       p_column_name_in
                                                      )
      LOOP
         x_kff_user_name := c_kff_usernames_rec.segment_name;
         x_loop_count := x_loop_count + 1;
      END LOOP;

      IF x_loop_count = 1
      THEN
         RETURN x_kff_user_name;
      ELSIF x_loop_count = 0
      THEN
         RAISE e_no_data_found;
      ELSE
         raise_message_error ('GET_KFF_USER_NAMES', g_hard_error_constant, 'Too many segment names were found');
      END IF;
   EXCEPTION
      WHEN e_no_data_found
      THEN
         raise_message_error ('GET_KFF_USER_NAMES', g_warning_constant, 'No segment name was found');
         RETURN NULL;
      WHEN OTHERS
      THEN
         raise_message_error ('GET_KFF_USER_NAMES', g_hard_error_constant, 'Un Expected Error');
   END get_kff_user_names;

   FUNCTION get_request_id
      RETURN fnd_concurrent_requests.request_id%TYPE
   IS
---------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Return the current concurrent request id
---------------------------------------------------------------------------------------------------------------
   BEGIN
      -- Check to run initialisation  if not initialise
      IF NOT (g_isinitialise)
      THEN
         initialization;
      END IF;

      RETURN (g_cp_rec.request_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_REQUEST_ID', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END get_request_id;

   FUNCTION get_conc_user_name
      RETURN fnd_user.user_name%TYPE
   IS
---------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Return the Concurrent Request Submitted User Name
---------------------------------------------------------------------------------------------------------------
   BEGIN
      -- Check to run initialisation  if not initialise
      IF NOT (g_isinitialise)
      THEN
         initialization;
      END IF;

      RETURN (g_cp_rec.user_name);
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_CONC_USER_NAME', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END get_conc_user_name;

   FUNCTION get_conc_user_id
      RETURN fnd_user.user_id%TYPE
   IS
---------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Return the Concurrent Request Submitted User Id
---------------------------------------------------------------------------------------------------------------
   BEGIN
      -- Check to run initialisation  if not initialise
      IF NOT (g_isinitialise)
      THEN
         initialization;
      END IF;

      RETURN (g_cp_rec.user_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_CONC_USER_ID', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END get_conc_user_id;

   FUNCTION get_responsibility_name
      RETURN fnd_responsibility_vl.responsibility_name%TYPE
   IS
---------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Return Concurrent Request Submitted Responsibility Name
---------------------------------------------------------------------------------------------------------------
   BEGIN
      -- Check to run initialisation  if not initialise
      IF NOT (g_isinitialise)
      THEN
         initialization;
      END IF;

      RETURN (g_cp_rec.responsibility_name);
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_RESPONSIBILITY_NAME', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END get_responsibility_name;

   FUNCTION get_user_program_name
      RETURN fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE
   IS
---------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Get Concurrent Program Name
---------------------------------------------------------------------------------------------------------------
   BEGIN
      -- Check to run initialisation  if not initialise
      IF NOT (g_isinitialise)
      THEN
         initialization;
      END IF;

      RETURN (g_cp_rec.concurrent_program_name);
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('GET_USER_PROGRAM_NAME', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END get_user_program_name;

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
      RETURN NUMBER
   IS
---------------------------------------------------------------------------------------------------------------
-- Created By                 :                IBM Development
-- Creation Date              :                07-MAR-2012
-- Description                :                Used to submit a concurrent program to the concurrent manager through SQL or PL/SQL
-- Input Parameters           :                Description
-- p_user_name                :                User Name
-- p_responsiblity_name       :                Responsibility Name
-- p_conc_prog_name           :                Concurrent program name
---------------------------------------------------------------------------------------------------------------
      -- Cursor will select the values of application id and application short name for the given responsibilty name.
      CURSOR c_responsibility (cp_responsiblity_name fnd_responsibility_vl.responsibility_name%TYPE)
      IS
         SELECT a.application_id, a.responsibility_id, b.application_short_name
           FROM fnd_responsibility_vl a, fnd_application b
          WHERE a.responsibility_name = cp_responsiblity_name AND a.application_id = b.application_id;

-- Cursor will select the user id of the given user name.
      CURSOR c_user_id (cp_user_name fnd_user.user_name%TYPE)
      IS
         SELECT user_id
           FROM fnd_user
          WHERE user_name = cp_user_name;

-- Cursor will select the short name of given concurrent program name.
      CURSOR c_concurrent_program_name (
         cp_conc_prog_name   fnd_concurrent_programs_vl.concurrent_program_name%TYPE,
         cp_resp_appl_id     fnd_concurrent_programs_vl.application_id%TYPE
      )
      IS
         SELECT concurrent_program_name
           FROM fnd_concurrent_programs_vl
          WHERE application_id = cp_resp_appl_id AND user_concurrent_program_name = cp_conc_prog_name;

      x_user_id              fnd_user.user_id%TYPE;
      x_resp_appl_id         fnd_responsibility_vl.application_id%TYPE;
      x_resp_id              fnd_responsibility_vl.responsibility_id%TYPE;
      c_program_name_rec     fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
      x_user                 fnd_user.user_id%TYPE;
      c_responsibility_rec   c_responsibility%ROWTYPE;
      x_resp_appl_id_1       fnd_responsibility_vl.application_id%TYPE;
      x_resp_id_1            fnd_responsibility_vl.responsibility_id%TYPE;
      c_user_id_rec          fnd_user.user_id%TYPE;
      x_loop_count           NUMBER                                                    := 0;
      x_conc_prog_name_1     fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
      x_conc_req_id          fnd_concurrent_requests.request_id%TYPE                   := 0;
      x_appl_short_name      fnd_application.application_short_name%TYPE;
      x_user_id_1            fnd_user.user_id%TYPE;
      e_no_data_found        EXCEPTION;
   BEGIN
      -- Below statement to take current values of user id ,responsibility details.
      BEGIN
         SELECT fnd_global.user_id, fnd_global.resp_appl_id, fnd_global.resp_id
           INTO x_user_id, x_resp_appl_id, x_resp_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
      END;

-- Below loop is to get new application id , application short name and responsibility id for given -- responsibility name
      BEGIN
         x_loop_count := 0;

         FOR c_responsibility_rec IN c_responsibility (p_responsiblity_name)
         LOOP
            x_resp_appl_id_1 := c_responsibility_rec.application_id;
            x_resp_id_1 := c_responsibility_rec.responsibility_id;
            x_appl_short_name := c_responsibility_rec.application_short_name;
            x_loop_count := x_loop_count + 1;
         END LOOP;

         IF x_loop_count = 1
         THEN
            NULL;
         ELSIF x_loop_count = 0
         THEN
            RAISE e_no_data_found;
         ELSE
            raise_message_error ('SUBMIT_CONC_PROGRAM',
                                 g_hard_error_constant,
                                 'Too many application id were found for given responsibility'
                                );
         END IF;
      EXCEPTION
         WHEN e_no_data_found
         THEN
            raise_message_error ('SUBMIT_CONC_PROGRAM',
                                 g_warning_constant,
                                 'No responsibility id is found for given responsibility'
                                );
            x_resp_appl_id_1 := x_resp_appl_id;
            x_resp_id_1 := x_resp_id;
         WHEN OTHERS
         THEN
            raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
      END;

-- Below loop is to get userid for given user name
      BEGIN
         x_loop_count := 0;

         FOR c_user_id_rec IN c_user_id (p_user_name)
         LOOP
            x_user_id_1 := c_user_id_rec.user_id;
            x_loop_count := x_loop_count + 1;
         END LOOP;

         IF x_loop_count = 1
         THEN
            NULL;
         ELSIF x_loop_count = 0
         THEN
            RAISE e_no_data_found;
         ELSE
            raise_message_error ('SUBMIT_CONC_PROGRAM',
                                 g_hard_error_constant,
                                 'Too many user id were found for given user name'
                                );
         END IF;
      EXCEPTION
         WHEN e_no_data_found
         THEN
            raise_message_error ('SUBMIT_CONC_PROGRAM', g_warning_constant, 'No user id is found for given user name');
            x_user_id_1 := x_user_id;
         WHEN OTHERS
         THEN
            raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
      END;

      --Initialize the session with new values of user id,responsibility id and application id.
      fnd_global.apps_initialize (x_user_id_1, x_resp_id_1, x_resp_appl_id_1);

      --Get the short name for the concurrent Program
      BEGIN
         x_loop_count := 0;

         FOR c_program_name_rec IN c_concurrent_program_name (p_conc_prog_name, x_resp_appl_id_1)
         LOOP
            x_conc_prog_name_1 := c_program_name_rec.concurrent_program_name;
            x_loop_count := x_loop_count + 1;
         END LOOP;

         IF x_loop_count = 1
         THEN
            NULL;
         ELSIF x_loop_count = 0
         THEN
            RAISE e_no_data_found;
         ELSE
            raise_message_error ('SUBMIT_CONC_PROGRAM',
                                 g_hard_error_constant,
                                 'Too many concurrent program short names were found for given program name'
                                );
         END IF;
      EXCEPTION
         WHEN e_no_data_found
         THEN
            raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, 'no data found for given program name');
         WHEN OTHERS
         THEN
            raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
      END;

      --Submit the request with the correct parameters
      x_conc_req_id :=
         fnd_request.submit_request (x_appl_short_name,
                                     x_conc_prog_name_1,
                                     '',
                                     '',
                                     FALSE,
                                     NVL (p_param00, ''),
                                     NVL (p_param01, ''),
                                     NVL (p_param02, ''),
                                     NVL (p_param03, ''),
                                     NVL (p_param04, ''),
                                     NVL (p_param05, ''),
                                     NVL (p_param06, ''),
                                     NVL (p_param07, ''),
                                     NVL (p_param08, ''),
                                     NVL (p_param09, ''),
                                     NVL (p_param10, ''),
                                     NVL (p_param11, ''),
                                     NVL (p_param12, ''),
                                     NVL (p_param13, ''),
                                     NVL (p_param14, ''),
                                     NVL (p_param15, ''),
                                     NVL (p_param16, ''),
                                     NVL (p_param17, ''),
                                     NVL (p_param18, ''),
                                     NVL (p_param19, ''),
                                     NVL (p_param20, ''),
                                     NVL (p_param21, ''),
                                     NVL (p_param22, ''),
                                     NVL (p_param23, ''),
                                     NVL (p_param24, ''),
                                     NVL (p_param25, ''),
                                     NVL (p_param26, ''),
                                     NVL (p_param27, ''),
                                     NVL (p_param28, ''),
                                     NVL (p_param29, ''),
                                     NVL (p_param30, ''),
                                     NVL (p_param31, ''),
                                     NVL (p_param32, ''),
                                     NVL (p_param33, ''),
                                     NVL (p_param34, ''),
                                     NVL (p_param35, ''),
                                     NVL (p_param36, ''),
                                     NVL (p_param37, ''),
                                     NVL (p_param38, ''),
                                     NVL (p_param39, ''),
                                     NVL (p_param40, ''),
                                     NVL (p_param41, ''),
                                     NVL (p_param42, ''),
                                     NVL (p_param43, ''),
                                     NVL (p_param44, ''),
                                     NVL (p_param45, ''),
                                     NVL (p_param46, ''),
                                     NVL (p_param47, ''),
                                     NVL (p_param48, ''),
                                     NVL (p_param49, ''),
                                     NVL (p_param50, ''),
                                     NVL (p_param51, ''),
                                     NVL (p_param52, ''),
                                     NVL (p_param53, ''),
                                     NVL (p_param54, ''),
                                     NVL (p_param55, ''),
                                     NVL (p_param56, ''),
                                     NVL (p_param57, ''),
                                     NVL (p_param58, ''),
                                     NVL (p_param59, ''),
                                     NVL (p_param60, ''),
                                     NVL (p_param61, ''),
                                     NVL (p_param62, ''),
                                     NVL (p_param63, ''),
                                     NVL (p_param64, ''),
                                     NVL (p_param65, ''),
                                     NVL (p_param66, ''),
                                     NVL (p_param67, ''),
                                     NVL (p_param68, ''),
                                     NVL (p_param69, ''),
                                     NVL (p_param70, ''),
                                     NVL (p_param71, ''),
                                     NVL (p_param72, ''),
                                     NVL (p_param73, ''),
                                     NVL (p_param74, ''),
                                     NVL (p_param75, ''),
                                     NVL (p_param76, ''),
                                     NVL (p_param77, ''),
                                     NVL (p_param78, ''),
                                     NVL (p_param79, ''),
                                     NVL (p_param80, ''),
                                     NVL (p_param81, ''),
                                     NVL (p_param82, ''),
                                     NVL (p_param83, ''),
                                     NVL (p_param84, ''),
                                     NVL (p_param85, ''),
                                     NVL (p_param86, ''),
                                     NVL (p_param87, ''),
                                     NVL (p_param88, ''),
                                     NVL (p_param89, ''),
                                     NVL (p_param90, ''),
                                     NVL (p_param91, ''),
                                     NVL (p_param92, ''),
                                     NVL (p_param93, ''),
                                     NVL (p_param94, ''),
                                     NVL (p_param95, ''),
                                     NVL (p_param96, ''),
                                     NVL (p_param97, ''),
                                     NVL (p_param98, ''),
                                     NVL (p_param99, '')
                                    );
      RETURN x_conc_req_id;
      --Re Initialize session with original values of user id,responsibility id and application id.
      fnd_global.apps_initialize (x_user_id, x_resp_id, x_resp_appl_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         --If program errors out with some reason we need to reset the environment.
         fnd_global.apps_initialize (x_user_id, x_resp_id, x_resp_appl_id);
         raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END submit_conc_program;

   PROCEDURE write_log (p_message IN VARCHAR2)
   IS
--------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to write messages to either fnd log file or DBMS OUTPUT based on the value of
--                  G_FND_FLAG variable. If the G_FND_FLAG value is TRUE then it writes the message to log file --                  otherwise
--                  writes message to dbms output.
-- Parameters Description
-- p_message   : Message needs to be write.
---------------------------------------------------------------------
      l_str_len   NUMBER := 1;
      l_str       NUMBER;
   BEGIN
      IF g_fnd_flag = TRUE
      THEN
         fnd_file.put_line (fnd_file.LOG, p_message);
      ELSE
         l_str := CEIL (LENGTH (p_message) / 230);

         FOR c_cntr IN 1 .. l_str
         LOOP
            DBMS_OUTPUT.put_line (' Log: ' || SUBSTR (p_message, l_str_len, 230));
            l_str_len := c_cntr * 230;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END write_log;

   PROCEDURE write_out (p_message IN VARCHAR2)
   IS
  -----------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description   :  Procedure to write messages to either fnd log file or DBMS OUTPUT based on the value of
--                  G_FND_FLAG variable. If the G_FND_FLAG value is TRUE then it writes the message to out file --                  otherwise
--                  writes message to dbms output.
-- Parameters Description
-- p_message      : Message needs to be write.
--------------------------------------------------------------------
      l_str_len   NUMBER := 1;
      l_str       NUMBER;
   BEGIN
      IF g_fnd_flag = TRUE
      THEN
         fnd_file.put_line (fnd_file.output, p_message);
      ELSE
         l_str := CEIL (LENGTH (p_message) / 230);

         FOR c_cntr IN 1 .. l_str
         LOOP
            DBMS_OUTPUT.put_line (' Log: ' || SUBSTR (p_message, l_str_len, 230));
            l_str_len := c_cntr * 230;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('SUBMIT_CONC_PROGRAM', g_hard_error_constant, SUBSTR (SQLERRM, 1, 500));
   END write_out;

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
   )
   IS
-----------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     :  Procedure to submit Concurrent Program from ODI.
-- Parameters Description
-- p_user_id       : User id.
-- p_responsibility_id ; User responsibility.
-- p_application_id   : User Application
-- p_module           :  Short name of application under which the program is registered
-- p_conc             : Concurrent program name for which the request has to be submitted
--------------------------------------------------------------------
      x_request_id       NUMBER;
      x_interval         NUMBER          := 3;
      x_phase            VARCHAR2 (240);
      x_prog_status      VARCHAR2 (240);
      x_request_phase    VARCHAR2 (240);
      x_request_status   VARCHAR2 (240);
      x_finished         BOOLEAN;
      x_message          VARCHAR2 (1000);
   BEGIN
      -- initilizing the apps environment.
      fnd_global.apps_initialize (p_user_id, p_responsibility_id, p_application_id);
      -- Submitting the concurrent request.
      x_request_id :=
         fnd_request.submit_request (p_module,
                                     p_conc,
                                     NULL,
                                     SYSDATE,
                                     FALSE,
                                     argument1       => p_param1,
                                     argument2       => p_param2,
                                     argument3       => p_param3,
                                     argument4       => p_param4,
                                     argument5       => p_param5,
                                     argument6       => p_param6,
                                     argument7       => p_param7,
                                     argument8       => p_param8,
                                     argument9       => p_param9,
                                     argument10      => p_param10,
                                     argument11      => p_param11,
                                     argument12      => p_param12,
                                     argument13      => p_param13,
                                     argument14      => p_param14,
                                     argument15      => p_param15,
                                     argument16      => p_param16,
                                     argument17      => p_param17,
                                     argument18      => p_param18,
                                     argument19      => p_param19,
                                     argument20      => p_param20
                                    );
      x_req_id := x_request_id;

      IF x_request_id = 0
      THEN
         x_status := 'ERROR';
      ELSE
         COMMIT;

         IF p_wait = 'Y'
         THEN
            LOOP
               x_finished :=
                  fnd_concurrent.wait_for_request (request_id      => x_request_id,
                                                   INTERVAL        => x_interval,
                                                   max_wait        => 0,
                                                   phase           => x_phase,
                                                   status          => x_prog_status,
                                                   dev_phase       => x_request_phase,
                                                   dev_status      => x_request_status,
                                                   MESSAGE         => x_message
                                                  );

               IF (UPPER (x_request_phase) = 'COMPLETE')
               THEN
                  x_status := x_request_status;
                  EXIT;
               END IF;
            END LOOP;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_status := SQLERRM;
   END submit_conc_program_from_odi;

   PROCEDURE call_web_service (
      p_soap_request     IN       VARCHAR2,
      p_ws_uri           IN       VARCHAR2,
      p_ws_action        IN       VARCHAR2,
      p_timeout_second   IN       NUMBER DEFAULT NULL,
      x_status_code      OUT      NUMBER,
      x_status_desc      OUT      VARCHAR2,
      x_soap_respond     OUT      VARCHAR2
   )
   IS
-----------------------------------------------------------------
-- Created By          : IBM Development
-- Creation Date       : 07-MAR-2012
-- Description         : Procedure to call web service.
-- Parameters Description
-- p_soap_request      : SOAP Message
-- p_ws_uri            ; URI of the web service.
-- p_ws_action         : Web service SOAP action
--------------------------------------------------------------------
      soap_request   VARCHAR2 (30000);
      soap_respond   VARCHAR2 (30000);
      http_req       UTL_HTTP.req;
      http_resp      UTL_HTTP.resp;
      l_timeout      PLS_INTEGER;
      e_null_input   EXCEPTION;
   BEGIN
      IF p_timeout_second IS NOT NULL
      THEN
         UTL_HTTP.get_transfer_timeout (l_timeout);
         --set user specified timeout
         UTL_HTTP.set_transfer_timeout (p_timeout_second);
      END IF;

      x_status_code := 0;
      soap_request := p_soap_request;

      IF (p_soap_request IS NULL)
      THEN
         x_status_desc := 'The Input SOAP-Request is null';
         RAISE e_null_input;
      ELSIF (p_ws_uri IS NULL)
      THEN
         x_status_desc := 'The Input Web-Service URI is null';
         RAISE e_null_input;
      ELSIF (p_ws_action IS NULL)
      THEN
         x_status_desc := 'The Input Web-Service Action is null';
         RAISE e_null_input;
      END IF;

      http_req := UTL_HTTP.begin_request (p_ws_uri, 'POST', 'HTTP/1.1');
      UTL_HTTP.set_header (http_req, 'Content-Type', 'text/xml');
      UTL_HTTP.set_header (http_req, 'Content-Length', LENGTH (soap_request));
      UTL_HTTP.set_header (http_req, 'SOAPAction', '"' || p_ws_action || '"');
      UTL_HTTP.write_text (http_req, soap_request);
      http_resp := UTL_HTTP.get_response (http_req);
      UTL_HTTP.read_text (http_resp, soap_respond);
      UTL_HTTP.end_response (http_resp);
      x_soap_respond := soap_respond;

      IF p_timeout_second IS NOT NULL
      THEN
         --revert HTTP timeout
         UTL_HTTP.set_transfer_timeout (l_timeout);
      END IF;
   EXCEPTION
      WHEN e_null_input
      THEN
         x_status_code := 1;
      WHEN OTHERS
      THEN
         x_status_code := 1;
         x_status_desc := SQLERRM;
   END call_web_service;

-- Procedure to call web service.
-- Overloaded by Oscar.
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
   )
   IS
      soap_request   VARCHAR2 (30000);
      soap_respond   VARCHAR2 (30000);
      http_req       UTL_HTTP.req;
      http_resp      UTL_HTTP.resp;
      l_timeout      PLS_INTEGER;
      e_null_input   EXCEPTION;
   BEGIN
      x_error_code := NULL;
      x_error_message := NULL;

      IF p_timeout_second IS NOT NULL
      THEN
         UTL_HTTP.get_transfer_timeout (l_timeout);
         --set user specified timeout
         UTL_HTTP.set_transfer_timeout (p_timeout_second);
      END IF;

      x_status_code := 0;
      soap_request := p_soap_request;

      IF (p_soap_request IS NULL)
      THEN
         x_status_desc := 'The Input SOAP-Request is null';
         RAISE e_null_input;
      ELSIF (p_ws_uri IS NULL)
      THEN
         x_status_desc := 'The Input Web-Service URI is null';
         RAISE e_null_input;
      ELSIF (p_ws_action IS NULL)
      THEN
         x_status_desc := 'The Input Web-Service Action is null';
         RAISE e_null_input;
      END IF;

      http_req := UTL_HTTP.begin_request (p_ws_uri, 'POST', 'HTTP/1.1');
      UTL_HTTP.set_header (http_req, 'Content-Type', 'text/xml');
      UTL_HTTP.set_header (http_req, 'Content-Length', LENGTH (soap_request));
      UTL_HTTP.set_header (http_req, 'SOAPAction', '"' || p_ws_action || '"');
      UTL_HTTP.write_text (http_req, soap_request);
      http_resp := UTL_HTTP.get_response (http_req);
      UTL_HTTP.read_text (http_resp, soap_respond);
      UTL_HTTP.end_response (http_resp);
      x_soap_respond := soap_respond;

      IF p_timeout_second IS NOT NULL
      THEN
         --revert HTTP timeout
         UTL_HTTP.set_transfer_timeout (l_timeout);
      END IF;
   EXCEPTION
      WHEN e_null_input
      THEN
         x_status_code := 1;
      WHEN OTHERS
      THEN
         x_error_code := SQLCODE;   --return original error code
         x_error_message := SQLERRM;   --return original error message
         x_status_code := 1;
         x_status_desc := SQLERRM;
   END call_web_service;


-- Procedure to call web service.
-- Overloaded by Faizal.
-- Logic is the same with above procedure, change x_soap_respond OUT datatype to CLOB to accommodate the large volume for payload.
-- 26-Mac-2009
   PROCEDURE call_web_service (
      p_soap_request     IN       VARCHAR2,
      p_ws_uri           IN       VARCHAR2,
      p_ws_action        IN       VARCHAR2,
      p_timeout_second   IN       NUMBER DEFAULT NULL,
      x_error_code       OUT      NUMBER,
      x_error_message    OUT      VARCHAR2,
      x_status_code      OUT      NUMBER,
      x_status_desc      OUT      VARCHAR2,
      x_soap_respond     OUT      CLOB
   )
   IS
      soap_request          VARCHAR2 (30000);
      soap_respond          VARCHAR2 (30000);
      soap_respond_clob     CLOB:= ' ';
      http_req              UTL_HTTP.req;
      http_resp             UTL_HTTP.resp;
      l_timeout             PLS_INTEGER;
      e_null_input          EXCEPTION;
   BEGIN
      x_error_code := NULL;
      x_error_message := NULL;

      IF p_timeout_second IS NOT NULL
      THEN
         UTL_HTTP.get_transfer_timeout (l_timeout);
         --set user specified timeout
         UTL_HTTP.set_transfer_timeout (p_timeout_second);
      END IF;

      x_status_code := 0;
      soap_request := p_soap_request;

      IF (p_soap_request IS NULL)
      THEN
         x_status_desc := 'The Input SOAP-Request is null';
         RAISE e_null_input;
      ELSIF (p_ws_uri IS NULL)
      THEN
         x_status_desc := 'The Input Web-Service URI is null';
         RAISE e_null_input;
      ELSIF (p_ws_action IS NULL)
      THEN
         x_status_desc := 'The Input Web-Service Action is null';
         RAISE e_null_input;
      END IF;

      http_req := UTL_HTTP.begin_request (p_ws_uri, 'POST', 'HTTP/1.1');
      UTL_HTTP.set_header (http_req, 'Content-Type', 'text/xml');
      UTL_HTTP.set_header (http_req, 'Content-Length', LENGTH (soap_request));
      UTL_HTTP.set_header (http_req, 'SOAPAction', '"' || p_ws_action || '"');
      UTL_HTTP.write_text (http_req, soap_request);
      http_resp := UTL_HTTP.get_response (http_req);
--      UTL_HTTP.read_text (http_resp, soap_respond);
        BEGIN
            LOOP
                UTL_HTTP.read_text (
                                    r       => http_resp,
                                    data    => soap_respond
                                    );
                dbms_lob.writeappend(soap_respond_clob, LENGTH(soap_respond), soap_respond);
            END LOOP;
            EXCEPTION
            WHEN UTL_HTTP.end_of_body
                THEN
            NULL;
        END;

      UTL_HTTP.end_response (http_resp);
      x_soap_respond := soap_respond_clob;

      IF p_timeout_second IS NOT NULL
      THEN
         --revert HTTP timeout
         UTL_HTTP.set_transfer_timeout (l_timeout);
      END IF;
   EXCEPTION
      WHEN e_null_input
      THEN
         x_status_code := 1;
      WHEN OTHERS
      THEN
         x_error_code := SQLCODE;   --return original error code
         x_error_message := SQLERRM;   --return original error message
         x_status_code := 1;
         x_status_desc := SQLERRM;
   END call_web_service;


-----------------------------------------------------------------
-- Created By             : IBM Development
-- Creation Date          : 07-MAR-2012
-- Description            : Function to convert date to XML format.
-- Parameter
-- p_date                 : date
-- Return
-- result value           : VARCHAR2
--------------------------------------------------------------------
   FUNCTION convert_date_time (p_date IN TIMESTAMP)
      RETURN VARCHAR2
   AS
   BEGIN
      --RETURN TO_CHAR (p_date, 'YYYY-MM-DD') || 'T' || TO_CHAR (p_date, 'HH24:MI:SS') || DBTIMEZONE;
      RETURN TO_CHAR (p_date, 'YYYY-MM-DD') || 'T' || TO_CHAR (p_date, 'HH24:MI:SS') || to_char(systimestamp,'TZR');--Added for defect 2768--

   END;

-----------------------------------------------------------------
-- Created By             : IBM Development
-- Creation Date          : 07-MAR-2012
-- Description            : Procedure to print out SOAP message.
-- Parameter
-- p_date                 : date
--------------------------------------------------------------------
   PROCEDURE show_envelope (p_env IN VARCHAR2, p_line_width IN PLS_INTEGER DEFAULT 60)
   AS
      i       PLS_INTEGER;
      l_len   PLS_INTEGER;
   BEGIN
      i := 1;
      l_len := LENGTH (p_env);

      WHILE (i <= l_len)
      LOOP
         DBMS_OUTPUT.put_line (SUBSTR (p_env, i, p_line_width));
         i := i + p_line_width;
      END LOOP;
   END;
--------------------------------------------------------------------
-- Created By      : IBM Development
-- Creation Date   : 07-MAR-2012
-- Description     : Function for getting Client Timezone from Server Timezone
----------------------------------------------------------------------
FUNCTION xx_timezone_converter (
   p_date     IN   DATE,
   p_org_id   IN   NUMBER DEFAULT NULL
)
   RETURN DATE--VARCHAR2
IS
/*   l_date                   VARCHAR2 (50)
      := TO_CHAR (TO_DATE (p_date, 'RRRR/MM/DD HH24:MI:SS'),
                  'DD-MON-RRRR HH24:MI:SS'
                 ); */
   l_server_timezone_id     NUMBER;
   l_client_timezone_id     NUMBER;
   l_server_timezone_code   VARCHAR2 (100);
   l_client_timezone_code   VARCHAR2 (100);
   l_appl_short_name        VARCHAR2 (10);
   x_return_date            DATE;
   l_return_date            VARCHAR2 (100);
BEGIN
   /*fnd_global.apps_initialize (user_id           => fnd_global.user_id,
                               resp_id           => fnd_global.resp_id,
                               resp_appl_id      => fnd_global.resp_appl_id
                              );*/
   /*BEGIN
      SELECT application_short_name
        INTO l_appl_short_name
        FROM fnd_application
       WHERE application_id = fnd_global.resp_appl_id;
   EXCEPTION
   WHEN OTHERS THEN
     l_appl_short_name := 'ONT';
   END;*/
   --mo_global.set_org_context (p_org_id, '', 'ONT');
   --mo_global.set_org_context (p_org_id, '', l_appl_short_name);
   --COMMIT;
   l_server_timezone_id := fnd_profile.VALUE ('SERVER_TIMEZONE_ID');
   l_client_timezone_id := fnd_profile.VALUE ('CLIENT_TIMEZONE_ID');
   IF l_client_timezone_id IS NULL
   THEN
      l_client_timezone_id := l_server_timezone_id;
   END IF;
--Getting Server Timezone--
   BEGIN
      SELECT timezone_code
        INTO l_server_timezone_code
        FROM fnd_timezones_vl
       WHERE upgrade_tz_id = l_server_timezone_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_server_timezone_code := NULL;
   END;
--Getting Client Timezone--
   BEGIN
      SELECT timezone_code
        INTO l_client_timezone_code
        FROM fnd_timezones_vl
       WHERE upgrade_tz_id = l_client_timezone_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_client_timezone_id := NULL;
   END;
--Calling the Timezone Converter API --
   x_return_date :=
      fnd_timezone_pub.adjust_datetime (p_date,
                                        l_server_timezone_code,
                                        l_client_timezone_code
                                       );
   fnd_file.put_line (fnd_file.LOG,
                      'Input Date..' || p_date
                     );
   fnd_file.put_line (fnd_file.LOG,
                      'Server Timezone..' || l_server_timezone_code
                     );
   fnd_file.put_line (fnd_file.LOG,
                      'Client Timezone..' || l_client_timezone_code
                     );
   --fnd_file.put_line (fnd_file.LOG, 'Return Converted Date..' || x_return_date);
    RETURN x_return_date;
   l_return_date := TO_CHAR (x_return_date, 'DD-MON-RRRR HH24:MI:SS');
   --RETURN l_return_date;
END xx_timezone_converter;

   ------------------------------------------------------------------------------
--  Function Name:          VALIDATE_CREDIT_CARD_NUMBER
--  Description : This Function Validates the credit card number and Expiry Date and returns VALID or INVALID
--  I/P parameters :
--  p_cc_num_stripped         in Varchar2 : Card number
--------------------------------------------------------------------------------

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
    RETURN VARCHAR2
    IS
        TYPE numeric_tab_typ IS TABLE of number INDEX BY BINARY_INTEGER;
        TYPE character_tab_typ IS TABLE of char(1) INDEX BY BINARY_INTEGER;
        l_stripped_num_table numeric_tab_typ; /* Holds credit card number stripped of white spaces */
        l_product_table numeric_tab_typ; /* Table of cc digits multiplied by 2 or 1,for validity check */
        l_len_credit_card_num number := 0; /* Length of credit card number stripped of white spaces */
        l_product_tab_sum number := 0; /* Sum of digits in product table */
        l_actual_cc_check_digit number := 0; /* First digit of credit card, numbered from right to left */
        l_mod10_check_digit number := 0; /* Check digit after mod10 algorithm is applied */
        j number := 0; /* Product table index */

    BEGIN
        SELECT lengthb(p_cc_num_stripped)
        INTO l_len_credit_card_num
        FROM dual;

        FOR i in 1..l_len_credit_card_num LOOP
            SELECT to_number(substrb(p_cc_num_stripped,i,1))
            INTO l_stripped_num_table(i)
            FROM dual;
        END LOOP;
        l_actual_cc_check_digit := l_stripped_num_table(l_len_credit_card_num);

        FOR i in 1..l_len_credit_card_num-1 LOOP
            IF ( mod(l_len_credit_card_num+1-i,2) > 0 ) THEN
            -- Odd numbered digit. Store as is, in the product table.
            j := j+1;
            l_product_table(j) := l_stripped_num_table(i);
            ELSE
            -- Even numbered digit. Multiply digit by 2 and store in the product table.
            -- Numbers beyond 5 result in 2 digits when multiplied by 2. So handled seperately.
                IF (l_stripped_num_table(i) >= 5) THEN
                    j := j+1;
                    l_product_table(j) := 1;
                    j := j+1;
                    l_product_table(j) := (l_stripped_num_table(i) - 5) * 2;
                ELSE
                    j := j+1;
                    l_product_table(j) := l_stripped_num_table(i) * 2;
                END IF;
            END IF;
        END LOOP;

        -- Sum up the product table's digits
        FOR k in 1..j LOOP
            l_product_tab_sum := l_product_tab_sum + l_product_table(k);
        END LOOP;

        l_mod10_check_digit := mod( (10 - mod( l_product_tab_sum, 10)), 10);

        -- If actual check digit and check_digit after mod10 don't match, the credit card is an invalid one.
        IF ( l_mod10_check_digit <> l_actual_cc_check_digit) THEN
            return('INVALID');
        ELSE

            IF to_date(p_expiry_date,'DD-MON-RRRR') < to_date(SYSDATE,'DD-MON-RRRR') THEN
                 return('INVALID');
            ELSE
                return('VALID');
            END IF;

        END IF;

    END validate_credit_card_number;

----------------------------------------------------------------------------------------------
--  Procedure Name: XX_VALIDATE_CREDIT_CARD
--  Description   : This Procedure Validates the credit card number,card type and Expiry Date.
----------------------------------------------------------------------------------------------

    PROCEDURE xx_validate_credit_card        (  p_cc_number        IN VARCHAR2,
                                                p_expiry_date      IN DATE,
                                                p_card_brand       IN VARCHAR2,
                                                p_card_holder_Name IN VARCHAR2 DEFAULT NULL,
                                                x_return_status    OUT VARCHAR2,
                                                x_return_message   OUT VARCHAR2
                                              )
    IS

        l_msg_count              NUMBER;
        imsgcntr                 NUMBER  := 0;
        l_chr_msg_data           VARCHAR2 (800);
        l_msg_index_out          NUMBER;
        l_msg_data               VARCHAR2(3000);
        l_ord_imc_id             NUMBER := 5278;
        l_card_id                iby_creditcard.instrid%TYPE := null;
        l_response               iby_fndcpt_common_pub.Result_rec_type;
        l_card_instrument        iby_fndcpt_setup_pub.CreditCard_rec_type;
        l_api_version_no         CONSTANT NUMBER := 1.0;
        l_api_commit             CONSTANT Varchar2(1) := 'F'; --:= fnd_api.g_false;
        l_result_code            VARCHAR2(2000);
        l_return_status          VARCHAR2(10);
        l_card_issuer            VARCHAR2(100);
        l_error_code             VARCHAR2(500);

    BEGIN
        --Start of code Added on 19-NOV-2009 for INC000000215223
          BEGIN
            SELECT r.card_issuer_code /*,cc_issuer_range_id,
                     card_number_prefix, NVL(digit_check_flag,'N')*/
              INTO l_card_issuer
              FROM iby_cc_issuer_ranges r, iby_creditcard_issuers_b i
             WHERE (card_number_length = length(p_cc_number))
               AND (INSTR(p_cc_number, card_number_prefix) = 1)
               AND (r.card_issuer_code = i.card_issuer_code);
          EXCEPTION
            WHEN OTHERS THEN
              l_card_issuer := p_card_brand;
          END;

      IF ( (NOT p_card_brand IS NULL) AND (p_card_brand <> l_card_issuer) ) THEN
        l_error_code := iby_creditcard_pkg.G_RC_INVALID_CARD_ISSUER;
        x_return_status := 'E';
        x_return_message := 'Invalid Credit Card Details :'||l_error_code ;
      ELSE --End of code Added on 19-NOV-2009 for INC000000215223

       l_card_instrument.Owner_Id                    := NULL;
       l_card_instrument.Card_Holder_Name            := p_card_holder_Name;
       l_card_instrument.Billing_Address_Id          := NULL;
       l_card_instrument.Address_Type                := 'U';
       l_card_instrument.Billing_Postal_Code         := null;
       l_card_instrument.Billing_Address_Territory   := null;
       l_card_instrument.Card_Number                 := p_cc_number;
       l_card_instrument.Expiration_Date             := p_expiry_date;
       l_card_instrument.Instrument_Type             := 'CREDITCARD';
       l_card_instrument.PurchaseCard_Flag           := null;
       l_card_instrument.PurchaseCard_SubType        := null;
       l_card_instrument.FI_Name                     := null;
       l_card_instrument.Single_Use_Flag             := 'N';
       l_card_instrument.Info_Only_Flag              := 'N';
       l_card_instrument.Card_Purpose                := null;
       l_card_instrument.Card_Description            := null;
       l_card_instrument.Active_Flag                 := 'Y';
       l_card_instrument.Inactive_Date               := null;
       l_card_instrument.card_issuer                 := p_card_brand;
       l_card_instrument.attribute_category          := null;
       l_card_instrument.attribute1                  := null;
       l_card_instrument.attribute2                  := null;
       l_card_instrument.attribute3                  := null;
       l_card_instrument.attribute4                  := null;
       l_card_instrument.attribute5                  := null;
       l_card_instrument.attribute6                  := null;
       l_card_instrument.attribute7                  := null;
       l_card_instrument.attribute8                  := null;
       l_card_instrument.attribute9                  := null;
       l_card_instrument.attribute10                 := null;
       l_card_instrument.attribute11                 := null;
       l_card_instrument.attribute12                 := null;
       l_card_instrument.attribute13                 := null;
       l_card_instrument.attribute14                 := null;
       l_card_instrument.attribute15                 := null;
       l_card_instrument.attribute16                 := null;
       l_card_instrument.attribute17                 := null;
       l_card_instrument.attribute18                 := null;
       l_card_instrument.attribute19                 := null;
       l_card_instrument.attribute20                 := null;
       l_card_instrument.attribute21                 := null;
       l_card_instrument.attribute22                 := null;
       l_card_instrument.attribute23                 := null;
       l_card_instrument.attribute24                 := null;
       l_card_instrument.attribute25                 := null;
       l_card_instrument.attribute26                 := null;
       l_card_instrument.attribute27                 := null;
       l_card_instrument.attribute28                 := null;
       l_card_instrument.attribute29                 := null;
       l_card_instrument.attribute30                 := null;

     savepoint A;
        -- call Create_Card
        iby_fndcpt_setup_pub.Create_Card(
                                            p_api_version       => l_api_version_no,
                                            p_init_msg_list     => l_api_commit, --fnd_api.g_false,
                                            p_commit            => l_api_commit, --fnd_api.g_false,
                                            x_return_status     => l_return_status,
                                            x_msg_count         => l_msg_count,
                                            x_msg_data          => l_msg_data,
                                            p_card_instrument   => l_card_instrument,
                                            x_card_id           => l_card_id,
                                            x_response          => l_response
                                        );
      rollback to A ;

        l_result_code := l_response.Result_Code;
        x_return_status := l_return_status ;
        x_return_message := l_result_code ;

         IF nvl(l_return_status,'X') <> 'S'
          THEN
            x_return_status := 'E';
            x_return_message := 'Invalid Credit Card Details :'||l_result_code ;
         END IF;
     END IF;

    Exception when others then
     x_return_status := 'E';
     x_return_message := 'Exception in Credit Card Validation :'||substr(SQLERRM,1,200);
    END xx_validate_credit_card ;
-- ----------------------------------------------------
--  Function to do apps_initialize
-- ----------------------------------------------------
    FUNCTION init_apps ( p_responsibility_id IN NUMBER
                , p_application_id IN NUMBER)
    RETURN NUMBER
    IS
       x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       x_user_id NUMBER := FND_GLOBAL.USER_ID;
    BEGIN
       --xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Initialzation of APPS  for responsibility id ' || p_responsibility_id );
       fnd_global.apps_initialize ( x_user_id , p_responsibility_id , p_application_id ) ;
       RETURN x_error_code ;
    EXCEPTION
        WHEN OTHERS THEN
          x_error_code := xx_emf_cn_pkg.cn_prc_err;
          xx_emf_pkg.error (xx_emf_cn_pkg.cn_low,
                    xx_emf_cn_pkg.cn_valid,
                    xx_emf_cn_pkg.cn_exp_unhand,
                    SQLERRM
                    );
          RETURN x_error_code ;
    END init_apps;

   FUNCTION find_max (p_error_code1 VARCHAR2, p_error_code2 VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      SELECT MAX (ERROR_CODE)
        INTO x_return_value
        FROM (SELECT p_error_code1 ERROR_CODE
                FROM DUAL
              UNION
              SELECT p_error_code2 ERROR_CODE
                FROM DUAL);
      RETURN x_return_value;
   END find_max;
--
 /*  FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                          , p_source       IN VARCHAR2 DEFAULT NULL
              , p_old_value    IN VARCHAR2
              , p_date_effective IN DATE
                          )   RETURN VARCHAR2 AS

    x_new_value   VARCHAR2 (200);
    BEGIN
        SELECT DISTINCT new_value1
        INTO x_new_value
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value
               --  AND source_system = NVL(p_source,source_system)
         AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;

     RETURN x_new_value;

    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         RETURN p_old_value;
        WHEN OTHERS   THEN
         RETURN p_old_value;

   END get_mapping_value; */

      FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                          , p_source       IN VARCHAR2 DEFAULT NULL
              , p_old_value    IN VARCHAR2
              , p_date_effective IN DATE
                          )   RETURN VARCHAR2 AS

    x_new_value   VARCHAR2 (200);
    /* Added for wave1 approach - Start*/
    x_lookup_code VARCHAR2(200);
    BEGIN

        SELECT lookup_code
        INTO x_lookup_code 
	FROM fnd_lookup_values
        WHERE lookup_type = 'XX_TRANSLATION_MAPPING_LKP'
        AND language = USERENV('LANG')
        AND LOOKUP_CODE = p_mapping_type;
    /* Added for wave1 approach - END*/
    BEGIN
        SELECT DISTINCT new_value1
        INTO x_new_value
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value
               --  AND source_system = NVL(p_source,source_system)
         AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;

     RETURN x_new_value;

    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         RETURN p_old_value;
        WHEN OTHERS   THEN
         RETURN p_old_value;
    END;
     /* Added for wave1 approach - Start*/
     EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         RETURN p_old_value;
        WHEN OTHERS   THEN
          RETURN p_old_value;
    /* Added for wave1 approach - END*/
   END get_mapping_value;


 /*  FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                          , p_source       IN VARCHAR2 DEFAULT NULL
              , p_old_value1    IN VARCHAR2
              , p_old_value2    IN VARCHAR2
              , p_date_effective IN DATE
                          )   RETURN VARCHAR2 AS

    x_new_value   VARCHAR2 (200);
    BEGIN
        SELECT DISTINCT new_value1
        INTO x_new_value
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value1
         AND old_value2     = p_old_value2
               --  AND source_system = NVL(p_source,source_system)
           -- AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;

     RETURN x_new_value;

    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         RETURN p_old_value1;
        WHEN OTHERS   THEN
         RETURN p_old_value1;

   END get_mapping_value; */


   FUNCTION get_mapping_value (p_mapping_type IN VARCHAR2
                          , p_source       IN VARCHAR2 DEFAULT NULL
              , p_old_value1    IN VARCHAR2
              , p_old_value2    IN VARCHAR2
              , p_date_effective IN DATE
                          )   RETURN VARCHAR2 AS

    x_new_value   VARCHAR2 (200);
    /* Added for wave1 approach - Start*/
    x_lookup_code VARCHAR2(200);
    BEGIN

        SELECT lookup_code
        INTO x_lookup_code 
	FROM fnd_lookup_values
        WHERE lookup_type = 'XX_TRANSLATION_MAPPING_LKP'
        AND language = USERENV('LANG')
        AND LOOKUP_CODE = p_mapping_type;

   /* Added for wave1 approach - End*/

    BEGIN
        SELECT DISTINCT new_value1
        INTO x_new_value
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value1
         AND old_value2     = p_old_value2
               --  AND source_system = NVL(p_source,source_system)
            AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;

     RETURN x_new_value;

    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         RETURN p_old_value1;
        WHEN OTHERS   THEN
         RETURN p_old_value1;

     END;
     /* Added for wave1 approach - Start*/
     EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         RETURN p_old_value1;
        WHEN OTHERS   THEN
          RETURN p_old_value1;
    /* Added for wave1 approach - End*/
   END get_mapping_value;


 /*  PROCEDURE get_mapping_value (  p_mapping_type IN VARCHAR2
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
				  )

    AS

    x_new_value   VARCHAR2 (200);
    BEGIN
        SELECT DISTINCT new_value1,new_value2,new_value3
        INTO p_new_value1,p_new_value2,p_new_value3
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value1
         AND (p_old_value2 IS NULL OR old_value2     = p_old_value2)
         AND (p_old_value3 IS NULL OR old_value3     = p_old_value3)
         AND (p_old_value4 IS NULL OR old_value4     = p_old_value4)
         AND (p_old_value5 IS NULL OR old_value5     = p_old_value5)
         AND (p_old_value6 IS NULL OR old_value6     = p_old_value6)
         AND (p_old_value7 IS NULL OR old_value7     = p_old_value7)
               --  AND source_system = NVL(p_source,source_system)
         AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;


    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
        WHEN OTHERS   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
   END get_mapping_value; */

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
				  )

    AS

    x_new_value   VARCHAR2 (200);
    /* Added for wave1 approach - Start*/
    x_lookup_code VARCHAR2(200);
    BEGIN

        SELECT lookup_code
        INTO x_lookup_code 
	FROM fnd_lookup_values
        WHERE lookup_type = 'XX_TRANSLATION_MAPPING_LKP'
        AND language = USERENV('LANG')
        AND LOOKUP_CODE = p_mapping_type;
/* Added for wave1 approach - End*/
    BEGIN
   SELECT DISTINCT new_value1,new_value2,new_value3
        INTO p_new_value1,p_new_value2,p_new_value3
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value1
         AND (p_old_value2 IS NULL OR old_value2     = p_old_value2)
         AND (p_old_value3 IS NULL OR old_value3     = p_old_value3)
         AND (p_old_value4 IS NULL OR old_value4     = p_old_value4)
         AND (p_old_value5 IS NULL OR old_value5     = p_old_value5)
         AND (p_old_value6 IS NULL OR old_value6     = p_old_value6)
         AND (p_old_value7 IS NULL OR old_value7     = p_old_value7)
               --  AND source_system = NVL(p_source,source_system)
         AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;


    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
        WHEN OTHERS   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;

     END;

     /* Added for wave1 approach - Start*/
     EXCEPTION
     WHEN NO_DATA_FOUND   THEN
        p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
        WHEN OTHERS   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
	 /* Added for wave1 approach - End*/
   END get_mapping_value;

  /*
   PROCEDURE get_mapping_value (  p_mapping_type IN VARCHAR2
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
				  )

    AS

    x_new_value   VARCHAR2 (200);
    BEGIN
        SELECT DISTINCT new_value1,new_value2,new_value3,new_value4,new_value5,new_value6,new_value7
        INTO p_new_value1,p_new_value2,p_new_value3,p_new_value4,p_new_value5,p_new_value6,p_new_value7
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value1
         AND (p_old_value2 IS NULL OR old_value2     = p_old_value2)
         AND (p_old_value3 IS NULL OR old_value3     = p_old_value3)
         AND (p_old_value4 IS NULL OR old_value4     = p_old_value4)
         AND (p_old_value5 IS NULL OR old_value5     = p_old_value5)
         AND (p_old_value6 IS NULL OR old_value6     = p_old_value7)
         AND (p_old_value7 IS NULL OR old_value7     = p_old_value7)
               --  AND source_system = NVL(p_source,source_system)
         AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;


    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
         p_new_value4 := p_old_value4;
         p_new_value5 := p_old_value5;
         p_new_value6 := p_old_value6;
         p_new_value7 := p_old_value7;
        WHEN OTHERS   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
         p_new_value4 := p_old_value4;
         p_new_value5 := p_old_value5;
         p_new_value6 := p_old_value6;
         p_new_value7 := p_old_value7;

   END get_mapping_value;
   */

   PROCEDURE get_mapping_value (  p_mapping_type IN VARCHAR2
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
				  )

    AS

    x_new_value   VARCHAR2 (200);
    /* Added for wave1 approach - Start*/
    x_lookup_code VARCHAR2(200);
    BEGIN

        SELECT lookup_code
        INTO x_lookup_code 
	FROM fnd_lookup_values
        WHERE lookup_type = 'XX_TRANSLATION_MAPPING_LKP'
        AND language = USERENV('LANG')
        AND LOOKUP_CODE = p_mapping_type;

  /* Added for wave1 approach - End*/
    BEGIN
        SELECT DISTINCT new_value1,new_value2,new_value3,new_value4,new_value5,new_value6,new_value7
        INTO p_new_value1,p_new_value2,p_new_value3,p_new_value4,p_new_value5,p_new_value6,p_new_value7
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value1
         AND (p_old_value2 IS NULL OR old_value2     = p_old_value2)
         AND (p_old_value3 IS NULL OR old_value3     = p_old_value3)
         AND (p_old_value4 IS NULL OR old_value4     = p_old_value4)
         AND (p_old_value5 IS NULL OR old_value5     = p_old_value5)
         AND (p_old_value6 IS NULL OR old_value6     = p_old_value7)
         AND (p_old_value7 IS NULL OR old_value7     = p_old_value7)
               --  AND source_system = NVL(p_source,source_system)
         AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;


    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
         p_new_value4 := p_old_value4;
         p_new_value5 := p_old_value5;
         p_new_value6 := p_old_value6;
         p_new_value7 := p_old_value7;
        WHEN OTHERS   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
         p_new_value4 := p_old_value4;
         p_new_value5 := p_old_value5;
         p_new_value6 := p_old_value6;
         p_new_value7 := p_old_value7;
     END;

       /* Added for wave1 approach - Start*/
	EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
         p_new_value4 := p_old_value4;
         p_new_value5 := p_old_value5;
         p_new_value6 := p_old_value6;
         p_new_value7 := p_old_value7;
        WHEN OTHERS   THEN
         p_new_value1 := p_old_value1;
         p_new_value2 := p_old_value2;
         p_new_value3 := p_old_value3;
         p_new_value4 := p_old_value4;
         p_new_value5 := p_old_value5;
         p_new_value6 := p_old_value6;
         p_new_value7 := p_old_value7;

	 /* Added for wave1 approach - End*/
   END get_mapping_value;

FUNCTION get_account_mapping_value (p_mapping_type IN VARCHAR2
          , p_source       IN VARCHAR2 DEFAULT NULL
          , p_old_value    IN VARCHAR2
          , p_date_effective IN DATE
          , p_new_value    OUT VARCHAR2
             )   RETURN NUMBER AS

x_new_value   VARCHAR2 (200);
BEGIN

       -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'Enetered get_account_mapping_value ');
       -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'p_mapping_type = '||p_mapping_type);
       -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'p_source ='||p_source);
       -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'p_old_value = '||p_old_value);


       IF p_source = 'PRMS' THEN

     SELECT DISTINCT new_value1||'-'||new_value2||'-'||new_value3||'-'||new_value4||'-'||new_value5||'-'||new_value6||'-'||new_value7
     INTO x_new_value
     --FROM xx_intg_account_mapping
     FROM xx_gl_account_mapping
     WHERE mapping_type = p_mapping_type
     AND old_value1||old_value2||old_value3||old_value4 = p_old_value
     AND source_system = NVL(p_source,source_system)
     --AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
     AND ROWNUM        = 1;

       ELSIF p_source = 'HWKY' THEN

            SELECT DISTINCT new_value1||'-'||new_value2||'-'||new_value3||'-'||new_value4||'-'||new_value5||'-'||new_value6||'-'||new_value7
            INTO x_new_value
            --FROM xx_intg_account_mapping
            FROM xx_gl_account_mapping
            WHERE mapping_type = p_mapping_type
            AND old_value1||old_value2 = p_old_value
            AND source_system = NVL(p_source,source_system)
           -- AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
            AND ROWNUM        = 1;
       END IF;

 p_new_value  := x_new_value;
 RETURN xx_emf_cn_pkg.CN_SUCCESS;

EXCEPTION
    WHEN NO_DATA_FOUND   THEN
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'NO DATA FOUND - get_account_mapping_value');
     RETURN xx_emf_cn_pkg.cn_rec_err;
    WHEN OTHERS   THEN
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,SQLERRM ||' - get_account_mapping_value');
     RETURN xx_emf_cn_pkg.cn_rec_err;

END get_account_mapping_value;


--  SOB
FUNCTION get_new_sob( p_legacy_sob_name IN VARCHAR2
                     ,p_new_sob_id    OUT NUMBER
                    )
RETURN NUMBER IS

  x_error_code       NUMBER := xx_emf_cn_pkg.cn_success;
  x_set_of_books_id  GL_SETS_OF_BOOKS.set_of_books_id%TYPE;

BEGIN

    IF p_legacy_sob_name IS NOT NULL THEN
      BEGIN

        SELECT set_of_books_id
    INTO   x_set_of_books_id
    FROM   GL_SETS_OF_BOOKS
    WHERE  NAME = p_legacy_sob_name;

        p_new_sob_id := x_set_of_books_id;
        x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
        return x_error_code;
      Exception WHEN NO_DATA_FOUND THEN
        x_error_code := xx_emf_cn_pkg.cn_rec_err;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Error Occured while deriving the NEW SOB - Not Found');
        return x_error_code;
           WHEN OTHERS THEN
        x_error_code := xx_emf_cn_pkg.cn_rec_err;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Error Occured while deriving the NEW SOB - '||SQLERRM);
        return x_error_code;
      END;
    END IF;

END get_new_sob;

-- End of SOB

 -- Split the segments into 2 segments with first delimeter as the separator

 FUNCTION split_segments_2(
                         p_concat_segment IN VARCHAR2
                        ,p_delimiter IN VARCHAR2
                        ,p_segment1  OUT VARCHAR2
                        ,p_segment2  OUT VARCHAR2
                        ) RETURN NUMBER
 IS
 x_instr NUMBER;
 BEGIN

   x_instr := INSTR (p_concat_segment, p_delimiter);
     IF x_instr > 0 THEN
       p_segment2 := SUBSTR (p_concat_segment,INSTR (p_concat_segment, p_delimiter)+1, LENGTH(p_concat_segment));
       p_segment1 := SUBSTR(p_concat_segment,1,INSTR (p_concat_segment,p_delimiter)-1);
     ELSE
       p_segment1  := p_concat_segment;
       p_segment2 := NULL;
     END IF;
     RETURN 0;
END split_segments_2;



FUNCTION get_org_id(
                     p_operating_unit IN  VARCHAR2
                    ,p_org_id         OUT NUMBER
                   ) RETURN NUMBER
 IS
   x_error_code       NUMBER := xx_emf_cn_pkg.cn_success;
   x_org_id           NUMBER;
 BEGIN

    SELECT ORGANIZATION_ID
      INTO x_org_id
      FROM hr_operating_units
     WHERE NAME =  p_operating_unit;

     p_org_id := x_org_id;

     return x_error_code;

 EXCEPTION WHEN OTHERS THEN
  x_error_code := xx_emf_cn_pkg.cn_rec_err;
  return  x_error_code;
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Error Occured while deriving the org id - '||SQLERRM);

 END ;
--

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
                    ) RETURN NUMBER
IS
  x_concatenated_segment   gl_code_combinations_kfv.concatenated_segments%TYPE;
  x_ccid                   gl_code_combinations_kfv.code_combination_id%TYPE;
  x_coa_id                 gl_sets_of_books.chart_of_accounts_id%TYPE;
  x_segment_delimeter      fnd_id_flex_structures_vl.concatenated_segment_delimiter%TYPE;
  x_loop_count             NUMBER;
  x_instr                  NUMBER;
  x_leg_segment1           gl_code_combinations_kfv.segment1%TYPE;
  x_leg_segment2           gl_code_combinations_kfv.segment1%TYPE;
  x_leg_segment3           gl_code_combinations_kfv.segment1%TYPE;
  x_leg_segment4           gl_code_combinations_kfv.segment1%TYPE;
  x_leg_segment5           gl_code_combinations_kfv.segment1%TYPE;
  x_leg_segment6           gl_code_combinations_kfv.segment1%TYPE;
  x_leg_segment7           gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment1       gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment2       gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment3       gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment4       gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment5       gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment6       gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment7       gl_code_combinations_kfv.segment1%TYPE;
  x_derived_segment        VARCHAR2(200);

  x_leg_concatenated_segment   gl_code_combinations_kfv.concatenated_segments%TYPE;
  x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_derived_new_value  VARCHAR2(200);
  x_old_value   VARCHAR2(100);


BEGIN

  IF p_source = 'PRMS' THEN

    x_old_value := p_leg_segment1||p_leg_segment2||p_leg_segment3||p_leg_segment4;
  ELSIF p_source = 'HWKY' THEN
    x_old_value := p_leg_segment1||p_leg_segment2;
  END IF;

 x_error_code_temp := xx_intg_common_pkg.get_account_mapping_value (
                                                                    'ACCT_CODE_COMBINATION'
                                                                    ,p_source
                                                                    ,x_old_value
                                                                    ,sysdate
                                                                    ,x_derived_new_value
                                                                    );

   -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'x_derived_new_value ='||x_derived_new_value);

   x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );

   x_error_code_temp := split_segments_2( x_derived_new_value
                                         ,p_leg_seg_delimiter
                                         ,x_derived_segment1
                                         ,x_derived_new_value
                                         ) ;
   p_segment1 := x_derived_segment1;
   x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );

   -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'x_derived_segment1 ='||x_derived_segment1);


   x_error_code_temp := split_segments_2( x_derived_new_value
                                         ,p_leg_seg_delimiter
                                         ,x_derived_segment2
                                         ,x_derived_new_value
                                         ) ;
   p_segment2 := x_derived_segment2;
   x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
   -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'x_derived_segment2 ='||x_derived_segment2);


      x_error_code_temp := split_segments_2( x_derived_new_value
                                            ,p_leg_seg_delimiter
                                            ,x_derived_segment3
                                            ,x_derived_new_value
                                            ) ;
      p_segment3 := x_derived_segment3;
   x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
   -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'x_derived_segment3 ='||x_derived_segment3);

   x_error_code_temp := split_segments_2( x_derived_new_value
                                         ,p_leg_seg_delimiter
                                         ,x_derived_segment4
                                         ,x_derived_new_value
                                         ) ;
   p_segment4 := x_derived_segment4;
   x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );

   -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'x_derived_segment4 ='||x_derived_segment4);


   x_error_code_temp := split_segments_2( x_derived_new_value
                                         ,p_leg_seg_delimiter
                                         ,x_derived_segment5
                                         ,x_derived_new_value
                                         ) ;
   p_segment5 := x_derived_segment5;
   x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
   -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'x_derived_segment5 ='||x_derived_segment5);


   x_error_code_temp := split_segments_2( x_derived_new_value
                                         ,p_leg_seg_delimiter
                                         ,x_derived_segment6
                                         ,x_derived_new_value
                                         ) ;
   p_segment6 := x_derived_segment6;
   x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
   -- xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'x_derived_segment6 ='||x_derived_segment6);


   x_error_code_temp := split_segments_2( x_derived_new_value
                                         ,p_leg_seg_delimiter
                                         ,x_derived_segment7
                                         ,x_derived_new_value
                                        ) ;
      p_segment7 := x_derived_segment7;
     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );


  p_concatenated_segment := p_segment1||p_leg_seg_delimiter||p_segment2||p_leg_seg_delimiter||p_segment3||p_leg_seg_delimiter||
                            p_segment4||p_leg_seg_delimiter||p_segment5||p_leg_seg_delimiter||p_segment6||p_leg_seg_delimiter||
                            p_segment7 ;

xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'Completed Segment mappings');
return x_error_code;
EXCEPTION WHEN OTHERS
THEN
xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high,'Error = '||sqlerrm);
return 2;
END get_oracle_segment_ccid;

 --
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
   )
   IS

      x_concatenated_segment   gl_code_combinations_kfv.concatenated_segments%TYPE;
      x_ccid                   gl_code_combinations_kfv.code_combination_id%TYPE;
      x_coa_id                 gl_sets_of_books.chart_of_accounts_id%TYPE;
      x_segment_delimeter      fnd_id_flex_structures_vl.concatenated_segment_delimiter%TYPE;
      x_loop_count             NUMBER;
      x_instr                  NUMBER;
      x_leg_segment1           gl_code_combinations_kfv.segment1%TYPE;
      x_leg_segment2           gl_code_combinations_kfv.segment1%TYPE;
      x_leg_segment3           gl_code_combinations_kfv.segment1%TYPE;
      x_leg_segment4           gl_code_combinations_kfv.segment1%TYPE;
      x_leg_segment5           gl_code_combinations_kfv.segment1%TYPE;
      x_leg_segment6           gl_code_combinations_kfv.segment1%TYPE;
      x_leg_segment7           gl_code_combinations_kfv.segment1%TYPE;
      x_leg_concatenated_segment   gl_code_combinations_kfv.concatenated_segments%TYPE;


      -- cursor to get the chart of account id for the given Operating Unit
      CURSOR c_chart_of_acct (cp_org_name hr_operating_units.NAME%TYPE)
      IS
         SELECT sob.chart_of_accounts_id chart_of_accounts_id
           FROM gl_sets_of_books sob, hr_operating_units hou
          WHERE hou.NAME = cp_org_name AND hou.set_of_books_id = sob.set_of_books_id;

      -- cursor for getting the concatenated segment delimiter and auto creation of gl account flag value
      CURSOR c_concat_seg_dlmtr (cp_coa_id gl_code_combinations_kfv.code_combination_id%TYPE)
      IS
         SELECT fifs.concatenated_segment_delimiter AS segment_delimiter
           FROM fnd_id_flex_structures_vl fifs
          WHERE fifs.id_flex_code = 'GL#' AND fifs.id_flex_num = cp_coa_id;

---
    FUNCTION get_oracle_mapping (p_mapping_type IN VARCHAR2
              , p_source       IN VARCHAR2 DEFAULT NULL
              , p_old_value    IN VARCHAR2
              , p_date_effective IN DATE
                          )   RETURN VARCHAR2 AS

    x_new_value   VARCHAR2 (200);
    BEGIN
        SELECT DISTINCT new_value1
        INTO x_new_value
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND old_value1     = p_old_value
             --    AND source_system = NVL(p_source,source_system)
         AND p_date_effective between effective_start_date and effective_end_date
         AND ROWNUM        = 1;

     RETURN x_new_value;

    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
            raise_message_error ('Legacy Value not found', g_hard_error_constant, SQLERRM);
        WHEN OTHERS   THEN
            raise_message_error ('Legacy Value error', g_hard_error_constant, SQLERRM);

   END get_oracle_mapping;
---

   BEGIN
      -- Initializing the loop count to zero.
      x_loop_count := 0;
      p_concatenated_segment := NULL;
      -- Opening the cursor to get chart of accounts Id for the given Operating Unit.
      FOR c_chart_of_acct_rec IN c_chart_of_acct (p_org_name)
      LOOP
         x_coa_id := c_chart_of_acct_rec.chart_of_accounts_id;
         x_loop_count := x_loop_count + 1;
      END LOOP;
        IF p_source = 'PRMS'  THEN
                  --COMPANY,DIV, DEPT,ACCOUNT, SUB, IC, FUTURE
              IF p_leg_segment1 IS NOT NULL THEN
              p_segment1 := get_oracle_mapping('COMPANY','PRMS',p_leg_segment1,sysdate);
              END IF;
              IF p_leg_segment2 IS NOT NULL THEN
              p_segment2 := get_oracle_mapping('DIV','PRMS',p_leg_segment2,sysdate);
              END IF;
              IF p_leg_segment3 IS NOT NULL THEN
              p_segment3 := get_oracle_mapping('DEPT','PRMS',p_leg_segment3,sysdate);
              END IF;
              IF p_leg_segment4 IS NOT NULL THEN
              p_segment4 := get_oracle_mapping('ACCOUNT','PRMS',p_leg_segment4,sysdate);
              END IF;
              IF p_leg_segment5 IS NOT NULL THEN
              p_segment5 := get_oracle_mapping('SUB','PRMS',p_leg_segment5,sysdate);
              END IF;
              IF p_leg_segment6 IS NOT NULL THEN
              p_segment6 := get_oracle_mapping('IC','PRMS',p_leg_segment6,sysdate);
              END IF;
              IF p_leg_segment7 IS NOT NULL THEN
              p_segment7 := get_oracle_mapping('FUURE','PRMS',p_leg_segment7,sysdate);
              END IF;
    ELSIF p_source = 'HWKY' THEN

        IF p_leg_concatenated_segment IS NOT NULL THEN
                x_concatenated_segment := get_oracle_mapping('CODE_COMBINATION','HWKY',p_leg_concatenated_segment,sysdate);
                x_instr := INSTR (x_concatenated_segment, p_leg_seg_delimiter);
        IF x_instr > 0 THEN
            p_segment1 := SUBSTR (x_concatenated_segment,1,  INSTR (x_concatenated_segment, p_leg_seg_delimiter)-1) ;
            x_concatenated_segment := SUBSTR (x_concatenated_segment,
                                      INSTR (x_concatenated_segment, p_leg_seg_delimiter, -1)+1,
                                      length(x_concatenated_segment));
        END IF;
        --
        x_instr := INSTR (x_concatenated_segment, p_leg_seg_delimiter);
        IF x_instr > 0 THEN
            p_segment2 :=             SUBSTR (x_concatenated_segment,1,  INSTR (x_concatenated_segment, p_leg_seg_delimiter)-1) ;
            x_concatenated_segment := SUBSTR (x_concatenated_segment, INSTR (x_concatenated_segment, p_leg_seg_delimiter, -1)+1, length(x_concatenated_segment));
        END IF;
        --
        x_instr := INSTR (x_concatenated_segment, p_leg_seg_delimiter);
        IF x_instr > 0 THEN
            p_segment3 := SUBSTR (x_concatenated_segment,1,  INSTR (x_concatenated_segment, p_leg_seg_delimiter)-1) ;
            x_concatenated_segment := SUBSTR (x_concatenated_segment, INSTR (x_concatenated_segment, p_leg_seg_delimiter, -1)+1, length(x_concatenated_segment));
        END IF;
        --
        x_instr := INSTR (x_concatenated_segment, p_leg_seg_delimiter);
        IF x_instr > 0 THEN
            p_segment4 := SUBSTR (x_concatenated_segment,1,  INSTR (x_concatenated_segment, p_leg_seg_delimiter)-1) ;
            x_concatenated_segment := SUBSTR (x_concatenated_segment, INSTR (x_concatenated_segment, p_leg_seg_delimiter, -1)+1, length(x_concatenated_segment));
        END IF;
        --
        x_instr := INSTR (x_concatenated_segment, p_leg_seg_delimiter);
        IF x_instr > 0 THEN
            p_segment5 := SUBSTR (x_concatenated_segment,1,  INSTR (x_concatenated_segment, p_leg_seg_delimiter)-1) ;
            x_concatenated_segment := SUBSTR (x_concatenated_segment, INSTR (x_concatenated_segment, p_leg_seg_delimiter, -1)+1, length(x_concatenated_segment));
        END IF;
        --
        x_instr := INSTR (x_concatenated_segment, p_leg_seg_delimiter);
        IF x_instr > 0 THEN
            p_segment6 := SUBSTR (x_concatenated_segment,1,  INSTR (x_concatenated_segment, p_leg_seg_delimiter)-1) ;
            x_concatenated_segment := SUBSTR (x_concatenated_segment, INSTR (x_concatenated_segment, p_leg_seg_delimiter, -1)+1, length(x_concatenated_segment));
        END IF;
        --
        x_instr := INSTR (x_concatenated_segment, p_leg_seg_delimiter);
        IF x_instr > 0 THEN
            p_segment7 := SUBSTR (x_concatenated_segment,1,  INSTR (x_concatenated_segment, p_leg_seg_delimiter)-1) ;
            x_concatenated_segment := SUBSTR (x_concatenated_segment, INSTR (x_concatenated_segment, p_leg_seg_delimiter, -1)+1, length(x_concatenated_segment));
        END IF;

        END IF;


    END IF;



      IF x_loop_count = 0
      THEN
         x_coa_id := NULL;
      ELSIF x_loop_count > 1
      THEN
         raise_message_error ('GET_COA_CCID',
                              g_hard_error_constant,
                              'Too Many rows found in Table gl_sets_of_books for the Operating Unit ' || p_org_name
                             );
      END IF;

         -- initializing the loop count to zero
         x_loop_count := 0;

         -- Opening the cursor to Get concatinated segment delimiter value.
         FOR c_concat_seg_rec IN c_concat_seg_dlmtr (x_coa_id)
         LOOP
            x_segment_delimeter := c_concat_seg_rec.segment_delimiter;
            x_loop_count := x_loop_count + 1;
         END LOOP;

         IF x_loop_count = 0
         THEN
            x_segment_delimeter := NULL;
         ELSIF x_loop_count > 1
         THEN
            raise_message_error ('get_coa_ccid',
                                 g_hard_error_constant,
                                    'More than one entry found in fnd_id_flex_structures_vl for chart of account id: '
                                 || x_coa_id
                                );
         END IF;

         x_concatenated_segment := p_segment1;

        IF p_segment2 IS NOT NULL
        THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment2;
        END IF;

        IF p_segment3 IS NOT NULL
        THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment3;
        END IF;

        IF p_segment4 IS NOT NULL
        THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment4;
        END IF;

        IF p_segment5 IS NOT NULL
        THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment5;
        END IF;

        IF p_segment6 IS NOT NULL
        THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment6;
        END IF;

        IF p_segment7 IS NOT NULL
        THEN
            x_concatenated_segment := x_concatenated_segment || x_segment_delimeter || p_segment7;
        END IF;
        --
        p_concatenated_segment := x_concatenated_segment;
        --

        x_ccid := gl_code_combinations_pkg.get_ccid (x_coa_id, SYSDATE, x_concatenated_segment);
        p_ccid := x_ccid;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_message_error ('get_ccid_using_legacy', g_hard_error_constant, SQLERRM);
   END get_ccid_using_legacy;

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
                                    )
   IS
      x_organization_name hr_all_organization_units.name%TYPE;
      x_organization_code mtl_parameters.organization_code%TYPE;

   BEGIN
      /* call black box function and fetch the oracle organization
      -- code based on Integra organization code
      */

    x_organization_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value   =>p_legacy_org_name
                                  ,p_date_effective => sysdate
                                  );
       SELECT mp.organization_id
     INTO p_inv_organization_id
     FROM mtl_parameters mp
         --,hr_all_organization_units haou
    WHERE 1 = 1
     -- AND haou.organization_id = mp.organization_id
      AND mp.organization_code    = x_organization_code
      --AND haou.name            = x_organization_name
      AND (process_enabled_flag = 'Y'
           OR x_organization_code='000'
          )
      ;
   EXCEPTION
       WHEN TOO_MANY_ROWS THEN
     p_error_code := xx_emf_cn_pkg.CN_TOO_MANY;
     p_error_msg  := 'Invalid organization code =>'||xx_emf_cn_pkg.CN_TOO_MANY;
     p_inv_organization_id:=NULL;
       WHEN NO_DATA_FOUND THEN
     p_error_code := xx_emf_cn_pkg.CN_NO_DATA;
     p_error_msg  := 'Invalid organization code =>'||xx_emf_cn_pkg.CN_NO_DATA;
     p_inv_organization_id:=NULL;
       WHEN OTHERS THEN
     p_error_code := xx_emf_cn_pkg.CN_OTHERS;
     p_error_msg  := 'Errors Deriving Organization ID' || SQLCODE;
     p_inv_organization_id:=NULL;
   END get_inv_organization_id;

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
                          )
   IS
   BEGIN
      SELECT mcr.inventory_item_id
      INTO p_inventory_item_id
      FROM mtl_cross_references_b mcr,
           mtl_system_items_b msib --base item table used for fetching inventory_item_id corresponding to oraganization_id
      WHERE
      --mcr.cross_reference_type = 'Legacy Item Number'
       mcr.cross_reference_type =xx_emf_cn_pkg.CN_LEGACY_ITEM_XREF_LEGACY
       AND mcr.inventory_item_id=msib.inventory_item_id
       AND msib.organization_id=p_organization_id
       AND mcr.cross_reference   = p_legacy_item_name
      ;
   EXCEPTION
       WHEN TOO_MANY_ROWS THEN
     p_error_code := xx_emf_cn_pkg.CN_TOO_MANY;
     p_error_msg  := 'Invalid Legacy Item Number =>'||xx_emf_cn_pkg.CN_TOO_MANY;
     p_inventory_item_id := NULL;
       WHEN NO_DATA_FOUND THEN
     p_error_code := xx_emf_cn_pkg.CN_NO_DATA;
     p_error_msg  := 'Invalid Legacy Item Number =>'||xx_emf_cn_pkg.CN_NO_DATA;
     p_inventory_item_id := NULL;
       WHEN OTHERS THEN
     p_error_code := xx_emf_cn_pkg.CN_OTHERS;
     p_error_msg  := 'Errors Deriving Inventory Iten ID' || SQLCODE;
     p_inventory_item_id := NULL;
   END get_inventory_item_id;

   /* -----------------------------------------------------------------
   -- FUNCTION get_inv_organization_id
   -- This will be used to derive the Oracle inventory organization
   -- based on the legacy organization name
   -- @p_legacy_org_name       --> Integra Legacy Item Name
   -------------------------------------------------------------------*/

   FUNCTION get_inv_organization_id(p_legacy_org_name  IN VARCHAR2
                                    )RETURN NUMBER
   IS
      p_inv_organization_id NUMBER := 0;
      x_organization_name   hr_all_organization_units.name%TYPE;
      x_organization_code mtl_parameters.organization_code%TYPE;
   BEGIN
      /* call black box function and fetch the oracle organization
      -- code based on Integra organization code
      */

    x_organization_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ORGANIZATION_CODE'
                                  ,p_source      =>NULL
                                  ,p_old_value   =>p_legacy_org_name
                                  ,p_date_effective => sysdate
                                  );
       SELECT mp.organization_id
     INTO p_inv_organization_id
     FROM mtl_parameters mp
         --,hr_all_organization_units haou
    WHERE 1 = 1
      --AND haou.organization_id = mp.organization_id
      AND mp.organization_code    = x_organization_code
      --AND haou.name            = x_organization_name
      AND (process_enabled_flag = 'Y'
                 OR x_organization_code ='000'
          )
      ;
      RETURN p_inv_organization_id;
   EXCEPTION
       WHEN OTHERS THEN
            p_inv_organization_id := 0;
            RETURN p_inv_organization_id;
   END get_inv_organization_id;
   /* -----------------------------------------------------------------
   -- FUNCTION get_inventory_item_id
   -- This will be used to derive the Oracle inventory Item ID
   -- based on the legacy Item name using the X'ref table information
   -- @p_legacy_item_name       --> Integra Legacy Item Name
   -- @p_organization_id        --> Oracle Inventory Organization ID
   -------------------------------------------------------------------*/

   FUNCTION get_inventory_item_id(p_legacy_item_name   IN  VARCHAR2
                                  ,p_organization_id   IN  NUMBER
                       )RETURN NUMBER
   IS
      p_inventory_item_id NUMBER := 0;
   BEGIN
      SELECT mcr.inventory_item_id
      INTO p_inventory_item_id
      FROM mtl_cross_references_b mcr,
             mtl_system_items_b msib  --base item table used for fetching inventory_item_id corresponding to oraganization_id
      WHERE
      --mcr.cross_reference_type = 'Legacy Item Number'
       mcr.cross_reference_type =xx_emf_cn_pkg.CN_LEGACY_ITEM_XREF_LEGACY
       AND mcr.inventory_item_id=msib.inventory_item_id
       AND msib.organization_id=p_organization_id
       AND mcr.cross_reference   = p_legacy_item_name
      ;
      RETURN p_inventory_item_id;
   EXCEPTION
       WHEN OTHERS THEN
     p_inventory_item_id := NULL;
     RETURN p_inventory_item_id;
   END get_inventory_item_id;
   /* -----------------------------------------------------------------
   -- FUNCTION get_uom_code
   -- This will be used to derive the Oracle UOM CODE
   -- @p_legacy_uom_code       --> Integra Legacy Unit of measure
   -------------------------------------------------------------------*/
   FUNCTION get_uom_code(p_legacy_uom_code   IN  VARCHAR2
                        ,p_error_code        OUT VARCHAR2
                        ,p_error_msg         OUT VARCHAR2
                       )RETURN VARCHAR2
   IS
     x_uom_code mtl_units_of_measure.uom_code%TYPE;
   BEGIN
   /* Fetch the organization code using the black box logic
       */
       /*x_uom_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type  =>'UNIT_OF_MEASURE'
                                                        ,p_source        =>NULL
                                    ,p_old_value     =>p_legacy_uom_code
                                ,p_date_effective=>SYSDATE
                                );
       */
       -- get the actual uom code
       SELECT uom_code
     INTO x_uom_code
     FROM mtl_units_of_measure mum
    WHERE UPPER(mum.uom_code)     = UPPER(p_legacy_uom_code)
      AND NVL(mum.disable_date,SYSDATE) >= SYSDATE
       ;
       RETURN x_uom_code;
   EXCEPTION
       WHEN TOO_MANY_ROWS THEN
     p_error_code := xx_emf_cn_pkg.CN_TOO_MANY;
     p_error_msg  := 'Invalid UOM Code =>'||xx_emf_cn_pkg.CN_TOO_MANY;
     RETURN x_uom_code;
       WHEN NO_DATA_FOUND THEN
     p_error_code := xx_emf_cn_pkg.CN_NO_DATA;
     p_error_msg  := 'Invalid UOM Code =>'||xx_emf_cn_pkg.CN_NO_DATA;
     RETURN x_uom_code;
       WHEN OTHERS THEN
     p_error_code := xx_emf_cn_pkg.CN_OTHERS;
     p_error_msg  := 'Errors Deriving UOM Code' || SQLCODE;
     RETURN x_uom_code;
   END get_uom_code;

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
                  )
   IS
      x_extn_sys_short_name   VARCHAR2(12);
      x_default_directory     VARCHAR2(30);
      x_program_name          VARCHAR2(30) :=p_program_name ;
      x_file_name             VARCHAR2(30) :=p_file_name;
      x_creation_date         DATE         :=SYSDATE;
      x_created_by            VARCHAR2(20) :=FND_GLOBAL.USER_ID;
      x_file_status           VARCHAR2(10) :='Ready';
      x_trans_mode            VARCHAR2(10) :=p_trans_mode ;
      x_schedule_time         DATE         :=p_schedule_time;
      x_input_directory       VARCHAR2(1000) :=p_input_directory;
      x_output_directory      VARCHAR2(1000) :=p_output_directory;
      x_arch_directory        VARCHAR2(1000) :=NULL;
      x_ftp_type              VARCHAR2(12) :=p_ftp_type;
      x_user_email_address    VARCHAR2(100);
      l_out                   VARCHAR2(200):= NULL;
      x_out                   VARCHAR2(200):= NULL;
      l_input_directory       VARCHAR2(1000);
   BEGIN

            BEGIN
             SELECT extn_sys_short_name
                   ,default_directory
               INTO x_extn_sys_short_name
                   ,x_default_directory
               FROM xx_fnd_sftp_server_details
              WHERE host_name=p_host_name
                AND program = p_program_name;

            EXCEPTION
               WHEN OTHERS
               THEN
                  l_out  := 'Define the host name in xx_fnd_sftp_server_details.';

            END;

                IF x_extn_sys_short_name IS NULL
                THEN
                    RAISE_APPLICATION_ERROR(-20999,'Define the host name in xx_fnd_sftp_server_details.');
                END IF;

           BEGIN
                SELECT email_address
                INTO x_user_email_address
                FROM fnd_user
                WHERE user_id=x_created_by;
                EXCEPTION WHEN OTHERS
                THEN
                    l_out := 'Email Address is not defined for user :'||fnd_global.user_name;
           END;

                IF x_user_email_address IS NULL
                THEN
                    BEGIN
                        SELECT notification_group
                        INTO x_user_email_address
                        FROM xx_emf_process_setup
                        WHERE process_name=p_program_name;
                    EXCEPTION WHEN OTHERS
                    THEN
                      x_user_email_address:=NULL;
                    END;
                END IF;




                fnd_file.put_line(fnd_file.LOG
                        ,' x_input_directory:'||x_input_directory);

                 l_input_directory:=   substr(x_input_directory ,
                  instr(x_input_directory, '/xxint_data/')-7,22);

                   fnd_file.put_line(fnd_file.LOG
                        ,' x_input_directory:'||l_input_directory);

                IF l_input_directory = '/xxdata/xxint_data/edi'

                THEN

                       x_arch_directory :=substr(x_input_directory,1,instr(x_input_directory,'/',-1))||'arch'||substr(x_input_directory,instr(x_input_directory,'/',-1),length(x_input_directory));
                                ------Change as per GOLD directory structure
                ELSIF l_input_directory = '/xxdata/xxint_data/in/'
                OR  l_input_directory = '/xxdata/xxint_data/out'
                THEN
                        x_arch_directory := substr(x_input_directory,1,instr(x_input_directory,'/',1,10))||'arch/'||substr(x_input_directory,instr(x_input_directory,'/',-2)+1,length(x_input_directory));

                ELSE
                         RAISE_APPLICATION_ERROR(-20997,'Pass the proper input directory');
                END IF;





       --The XX_TRANS_DETAILS table is called by Java Concurrent Progarm and it's status updated

           BEGIN
            INSERT INTO xx_fnd_sftp_file_details
                   ( x_interface_key,
                     extn_sys_short_name ,
                     program_name       ,
                     file_name          ,
                     last_update_date   ,
                     last_updated_by    ,
                     creation_date      ,
                     created_by         ,
                     last_update_login  ,
                     file_status        ,
                     trans_mode         ,
                     schedule_time      ,
                     input_directory    ,
                     arch_directory   ,
                     output_directory   ,
                     ftp_type           ,
                     user_email_address
                   )
           VALUES  ( XX_FTP_INTERFACE_S.NEXTVAL,
                     x_extn_sys_short_name,
                     x_program_name,
                     x_file_name,
                     sysdate,
                     fnd_global.user_id,
                     x_creation_date,
                     x_created_by,
                     fnd_global.login_id,
                     x_file_status,
                     x_trans_mode,
                     x_schedule_time,
                     x_input_directory,
                     x_arch_directory,
                     DECODE(x_output_directory,NULL,x_default_directory,x_output_directory),
                     x_ftp_type,
                     x_user_email_address
                   );
         EXCEPTION
            WHEN OTHERS
            THEN
                x_out := 'Some error occur during insertion in the table';

         END;

          IF x_out IS NOT NULL
                THEN
                    RAISE_APPLICATION_ERROR(-20997,x_out);
          END IF;

         p_out := l_out;
   END xx_fnd_ftp_file;



   /* -----------------------------------------------------------------
   -- FUNCTION set_message
   -- This will be used to set the error message by passing token values to the error message
   -- defined under XXINTG application.
   -- @p_message_name       --> Message name defined under XXINTG application.
   -- @p_token_value1       --> Token value1 to be passed for TOKEN1.
   -- @p_token_value2       --> Token value2 to be passed for TOKEN2.
   -- @p_token_value3       --> Token value2 to be passed for TOKEN3.
   -------------------------------------------------------------------*/

FUNCTION set_message(
    p_message_name IN VARCHAR2,
    p_token_value1 IN VARCHAR2 DEFAULT NULL,
    p_token_value2 IN VARCHAR2 DEFAULT NULL,
    p_token_value3 IN VARCHAR2 DEFAULT NULL)
  RETURN VARCHAR2
IS
  x_mesg_name    VARCHAR2(90) := NULL;
  x_appl_name    VARCHAR2(50) := 'XXINTG';
  token1 CONSTANT VARCHAR2(50) := 'TOKEN1';
  token2 CONSTANT VARCHAR2(50) := 'TOKEN2';
  token3 CONSTANT VARCHAR2(50) := 'TOKEN3';
  x_token_value1 VARCHAR2(2000);
  x_token_value2 VARCHAR2(2000);
  x_token_value3 VARCHAR2(2000);
  x_token_out    VARCHAR2(2000);

BEGIN
  x_mesg_name    := UPPER(p_message_name);
  x_token_value1 := p_token_value1;
  x_token_value2 := p_token_value2;
  x_token_value3 := p_token_value3;
  fnd_message.clear;
  fnd_message.set_name ( x_appl_name,x_mesg_name);
  IF ( x_token_value1 IS NOT NULL ) THEN
    fnd_message.set_token (token1,x_token_value1 );
  END IF;

  IF ( x_token_value2 IS NOT NULL ) THEN
    fnd_message.set_token (token2,x_token_value2);
  END IF;

  IF ( x_token_value3 IS NOT NULL ) THEN
    fnd_message.set_token (token3,x_token_value3 );
  END IF;

  x_token_out := fnd_message.get;
  fnd_file.put_line (fnd_file.log,x_token_out);
  RETURN x_token_out;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.log,SQLERRM);
  RETURN x_mesg_name;
END set_message;
  /* -----------------------------------------------------------------
   -- FUNCTION set_token_message
   -- This will be used to set the error messages by passing token values to the
   -- History Function Added by:Renjith on 05-May-2012
   -- error message defined under the XXINTG application .
   -- @p_message_name       --> Message name defined under XXINTG application.
   -- @p_token_value1       --> Token value1 to be passed for TOKEN1.
   -- @p_token_value2       --> Token value2 to be passed for  TOKEN2.
   -- @p_token_value3       --> Token value3 to be passed for TOKEN3.
   -- @p_token_value4       --> Token value4 to be passed for TOKEN4.
   -- @p_token_value5       --> Token value5 to be passed for TOKEN5.
   -------------------------------------------------------------------*/
FUNCTION set_token_message(
            p_message_name  IN VARCHAR2,
            p_token_value1  IN VARCHAR2 DEFAULT NULL,
            p_token_value2  IN VARCHAR2 DEFAULT NULL,
            p_token_value3  IN VARCHAR2 DEFAULT NULL,
            p_token_value4  IN VARCHAR2 DEFAULT NULL,
            p_token_value5  IN VARCHAR2 DEFAULT NULL,
            p_no_of_tokens  IN NUMBER)
  RETURN VARCHAR2
IS
  x_mesg_name    VARCHAR2(90)   := NULL;
  x_appl_name    VARCHAR2(50)   := 'XXINTG';
  token1  CONSTANT VARCHAR2(50) := 'TOKEN1';
  token2  CONSTANT VARCHAR2(50) := 'TOKEN2';
  token3  CONSTANT VARCHAR2(50) := 'TOKEN3';
  token4  CONSTANT VARCHAR2(50) := 'TOKEN4';
  token5  CONSTANT VARCHAR2(50) := 'TOKEN5';

  x_token_value1  VARCHAR2(2000);
  x_token_value2  VARCHAR2(2000);
  x_token_value3  VARCHAR2(2000);
  x_token_value4  VARCHAR2(2000);
  x_token_value5  VARCHAR2(2000);

  x_token_out    VARCHAR2(2000);

BEGIN
  x_mesg_name     := UPPER(p_message_name);
  x_token_value1  := p_token_value1;
  x_token_value2  := p_token_value2;
  x_token_value3  := p_token_value3;
  x_token_value4  := p_token_value4;
  x_token_value5  := p_token_value5;

  fnd_message.clear;
  fnd_message.set_name ( x_appl_name,x_mesg_name);
  IF NVL(p_no_of_tokens,1) = 1 THEN
     fnd_message.set_token (token1,x_token_value1 );
  END IF;

  IF NVL(p_no_of_tokens,1) = 2 THEN
     fnd_message.set_token (token1,x_token_value1 );
     fnd_message.set_token (token2,x_token_value2 );
  END IF;


  IF NVL(p_no_of_tokens,1) = 3 THEN
     fnd_message.set_token (token1,x_token_value1 );
     fnd_message.set_token (token2,x_token_value2 );
     fnd_message.set_token (token3,x_token_value3 );
  END IF;


  IF NVL(p_no_of_tokens,1) = 4 THEN
     fnd_message.set_token (token1,x_token_value1 );
     fnd_message.set_token (token2,x_token_value2 );
     fnd_message.set_token (token3,x_token_value3 );
     fnd_message.set_token (token4,x_token_value4 );
  END IF;


  IF NVL(p_no_of_tokens,1) = 5 THEN
     fnd_message.set_token (token1,x_token_value1 );
     fnd_message.set_token (token2,x_token_value2 );
     fnd_message.set_token (token3,x_token_value3 );
     fnd_message.set_token (token4,x_token_value4 );
     fnd_message.set_token (token5,x_token_value5 );
  END IF;

  x_token_out := fnd_message.get;
  fnd_file.put_line (fnd_file.log,x_token_out);
  RETURN x_token_out;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.log,SQLERRM);
  RETURN x_mesg_name;
END set_token_message;

  /* -----------------------------------------------------------------
   -- FUNCTION set_long_message
   -- This will be used to set the error messages by passing token values to the
   -- History Function Added by:Renjith on 05-May-2012
   -- error message defined under the XXINTG application .
   -- @p_message_name       --> Message name defined under XXINTG application.
   -- @p_token_value1       --> Token value1 to be passed for TOKEN1.
   -- @p_token_value2       --> Token value2 to be passed for TOKEN2.
   -- @p_token_value3       --> Token value3 to be passed for TOKEN3.
   -- @p_token_value4       --> Token value4 to be passed for TOKEN4.
   -- @p_token_value5       --> Token value5 to be passed for TOKEN5.
   -- @p_token_value6       --> Token value6 to be passed for TOKEN6.
   -- @p_token_value7       --> Token value7 to be passed for TOKEN7.
   -- @p_token_value8       --> Token value8 to be passed for TOKEN8.
   -- @p_token_value9       --> Token value9 to be passed for TOKEN9.
   -- @p_token_value10       -->Token value10 to be passed for TOKEN10.
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
  RETURN VARCHAR2
IS
  x_mesg_name    VARCHAR2(90)   := NULL;
  x_appl_name    VARCHAR2(50)   := 'XXINTG';
  token1  CONSTANT VARCHAR2(50) := 'TOKEN1';
  token2  CONSTANT VARCHAR2(50) := 'TOKEN2';
  token3  CONSTANT VARCHAR2(50) := 'TOKEN3';
  token4  CONSTANT VARCHAR2(50) := 'TOKEN4';
  token5  CONSTANT VARCHAR2(50) := 'TOKEN5';
  token6  CONSTANT VARCHAR2(50) := 'TOKEN6';
  token7  CONSTANT VARCHAR2(50) := 'TOKEN7';
  token8  CONSTANT VARCHAR2(50) := 'TOKEN8';
  token9  CONSTANT VARCHAR2(50) := 'TOKEN9';
  token10 CONSTANT VARCHAR2(50) := 'TOKEN10';

  x_token_value1  VARCHAR2(2000);
  x_token_value2  VARCHAR2(2000);
  x_token_value3  VARCHAR2(2000);
  x_token_value4  VARCHAR2(2000);
  x_token_value5  VARCHAR2(2000);
  x_token_value6  VARCHAR2(2000);
  x_token_value7  VARCHAR2(2000);
  x_token_value8  VARCHAR2(2000);
  x_token_value9  VARCHAR2(2000);
  x_token_value10 VARCHAR2(2000);

  x_token_out    VARCHAR2(2000);

BEGIN
  x_mesg_name     := UPPER(p_message_name);
  x_token_value1  := p_token_value1;
  x_token_value2  := p_token_value2;
  x_token_value3  := p_token_value3;
  x_token_value4  := p_token_value4;
  x_token_value5  := p_token_value5;
  x_token_value6  := p_token_value6;
  x_token_value7  := p_token_value7;
  x_token_value8  := p_token_value8;
  x_token_value9  := p_token_value9;
  x_token_value10 := p_token_value10;

  fnd_message.clear;
  fnd_message.set_name ( x_appl_name,x_mesg_name);
  IF ( x_token_value1 IS NOT NULL ) THEN
    fnd_message.set_token (token1,x_token_value1 );
  END IF;

  IF ( x_token_value2 IS NOT NULL ) THEN
    fnd_message.set_token (token2,x_token_value2);
  END IF;

  IF ( x_token_value3 IS NOT NULL ) THEN
    fnd_message.set_token (token3,x_token_value3 );
  END IF;

  IF ( x_token_value4 IS NOT NULL ) THEN
    fnd_message.set_token (token4,x_token_value4 );
  END IF;

  IF ( x_token_value5 IS NOT NULL ) THEN
    fnd_message.set_token (token5,x_token_value5 );
  END IF;

  IF ( x_token_value6 IS NOT NULL ) THEN
    fnd_message.set_token (token6,x_token_value6 );
  END IF;

  IF ( x_token_value7 IS NOT NULL ) THEN
    fnd_message.set_token (token7,x_token_value7 );
  END IF;

  IF ( x_token_value8 IS NOT NULL ) THEN
    fnd_message.set_token (token8,x_token_value8 );
  END IF;

  IF ( x_token_value9 IS NOT NULL ) THEN
    fnd_message.set_token (token9,x_token_value9 );
  END IF;

  IF ( x_token_value10 IS NOT NULL ) THEN
    fnd_message.set_token (token10,x_token_value10 );
  END IF;
  x_token_out := fnd_message.get;
  fnd_file.put_line (fnd_file.log,x_token_out);
  RETURN x_token_out;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.log,SQLERRM);
  RETURN x_mesg_name;
END set_long_message;


/*********************************
  -- FUNCTION get_old_mapping_value
   -- This will be used to get the old value(legacy) for each new value passed (Oralce) from the  mapping
   -- table
   -- @p_mapping_type       --> Mapping Type.
   -- @p_new_value          --> Oracle Value.
   -- @p_effective_date     --> Effective date.
**********************************/

 FUNCTION get_old_mapping_value (p_mapping_type IN VARCHAR2
                  , p_new_value    IN VARCHAR2
                  , p_date_effective IN DATE
                )   RETURN VARCHAR2 AS

    x_old_value   VARCHAR2 (200);
    BEGIN
        SELECT DISTINCT old_value1
        INTO x_old_value
        FROM xx_intg_mapping
        WHERE mapping_type = p_mapping_type
         AND new_value1     = p_new_value
         AND p_date_effective between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate+1)
         AND ROWNUM        = 1;

     RETURN x_old_value;

    EXCEPTION
        WHEN NO_DATA_FOUND   THEN
         RETURN p_new_value;
        WHEN OTHERS   THEN
         RETURN p_new_value;

   END get_old_mapping_value;

   /* -----------------------------------------------------------------
   -- FUNCTION file_archive
   -- This will be used to archive the data files from the data top to the archive folder.
   -- @p_src_location       --> Source Location of the datafile.
   -- @p_src_filename       --> Datafile name to be moved.
   -- @p_dest_location      --> Destination Location of the datafile.
   -- @p_overwrite          --> Boolean variable to set whether the datafile has to be overwritten in destination location.
   -------------------------------------------------------------------*/
  FUNCTION file_archive(
    p_src_location  IN VARCHAR2,
    p_src_filename  IN VARCHAR2,
    p_dest_location IN VARCHAR2,
    p_dest_filename IN VARCHAR2,
    p_overwrite     IN BOOLEAN DEFAULT FALSE)
  RETURN NUMBER
IS
  x_src_location  VARCHAR2(200);
  x_src_filename  VARCHAR2(200);
  x_dest_location VARCHAR2(200);
  x_dest_filename VARCHAR2(200);
BEGIN
  x_src_location  := p_src_location ;
  x_src_filename  := p_src_filename;
  x_dest_location := p_dest_location;
  x_dest_filename := p_dest_filename;
  -- xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Moving File ');

  UTL_FILE.FRENAME ( x_src_location, x_src_filename, x_dest_location, x_dest_filename||'_arch', TRUE );
  RETURN 0;

EXCEPTION
WHEN UTL_FILE.invalid_operation THEN
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'MOVING FILE SQLERRM '||SQLERRM);
  raise_message_error ( 'WRITE_LOG_FILE', g_hard_error_constant, ' Invalid operation on the file' ||SQLERRM );
  RETURN -1 ;
WHEN OTHERS THEN
  xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'MOVING FILE SQLERRM '||SQLERRM);
  raise_message_error ( 'WRITE_LOG_FILE', g_hard_error_constant, 'Error WHEN moving the file: ' || SQLERRM );
  RETURN -1 ;
END file_archive;



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
                                    )
   IS

   BEGIN

    BEGIN
    SELECT cust.account_number,par.party_id,cust.cust_account_id,loc.location_id
     INTO p_customer_number,p_party_id,p_cust_account_id,p_location_id
      FROM   hz_parties par,
             hz_locations loc,
             hz_cust_acct_sites_all cas,
             hz_party_sites ps,
             hz_cust_accounts cust,
             ece_tp_headers eth
            -- ,ece_tp_details etd
      WHERE cas.tp_header_id = eth.tp_header_id
      AND ps.party_site_id = cas.party_site_id
      AND par.party_id = ps.party_id
      AND par.party_id =cust.party_id
      AND cust.cust_account_id=cas.cust_account_id
      AND loc.location_id = ps.location_id
      AND eth.TP_REFERENCE_EXT1=p_sender_interchange_isaid
      --AND eth.tp_header_id=etd.tp_header_id               /*commented By ashis*/
      --AND etd.translator_code=p_sender_interchange_isaid
      AND rownum=1;

   EXCEPTION WHEN OTHERS
   THEN
      p_customer_number:=null;
      p_party_id:=null;
      p_cust_account_id:=null;
      p_location_id:=null;

   END;

 END get_customer_details;
--
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
                               )
IS
--
BEGIN
--
SELECT flv.meaning
      ,flv.lookup_code
      ,flv.attribute1    table_name
      ,flv.attribute2    column_name
      ,flv.attribute3    conv_category
      ,flv.attribute4    ln_identifier
BULK COLLECT INTO x_ConvCatOutTbl
FROM   fnd_lookup_values flv
WHERE  flv.lookup_type   = p_lookup_type
AND    flv.LANGUAGE      = USERENV ('LANG')
AND    flv.attribute1    = p_tablename
AND    flv.enabled_flag  = 'Y';
--
--xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Data from lookup XX_INTEGRA_WMS_TRANSFORMATIONS collected');
--x_return_status :=
--
EXCEPTION
WHEN OTHERS THEN
xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Error in GET_ALL_CATEGORY_CONV procedure: '||SQLERRM);
END;
--
     /* -----------------------------------------------------------------
   -- Function get_conv_category_name
   -- Function Checks if p_table_name, p_column_name exists in p_ConvCatInTbl table type,
   -- if so then returns the Corresponding Code Conversion name
   -- @p_tablename                        --> Interface/Staging Table name
   -- @p_column_name                      --> Column name
   -- @p_identifier                       --> Header or line identifier
   -- @x_ConvCatOutTbl                    --> Conv_Cat_Tbl_Type Table Type
   -- Returns Code Conversion Category name/ NULL
   -------------------------------------------------------------------*/
FUNCTION get_conv_category_name (p_table_name         VARCHAR2
                                ,p_column_name        VARCHAR2
                                ,p_identifier         VARCHAR2  DEFAULT NULL
                                ,p_ConvCatInTbl       Conv_Cat_Tbl_Type
                                )
RETURN VARCHAR2
IS
lt_convcat_tbl       Conv_Cat_Tbl_Type;
BEGIN
  lt_convcat_tbl := p_ConvCatInTbl;
  --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Number records fetched: '||lt_convcat_tbl.count);
  --dbms_output.put_line('Number records fetched: '||lt_convcat_tbl.count);
  IF lt_convcat_tbl.count >0 THEN
  FOR i in lt_convcat_tbl.first..lt_convcat_tbl.last
  LOOP
  --
    IF (lt_convcat_tbl(i).table_name = p_table_name AND lt_convcat_tbl(i).column_name = p_column_name AND NVL(lt_convcat_tbl(i).ln_identifier,'XXX') = NVL(p_identifier,'XXX'))
    THEN
    --
      --dbms_output.put_line('Number records fetched: '||lt_convcat_tbl.count);
      RETURN lt_convcat_tbl(i).conv_cat_name;
    --
    END IF;
  --
  END LOOP;
END IF;
--
RETURN NULL;
--
EXCEPTION
WHEN OTHERS THEN
xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Error in get_conv_category_name: '||SQLERRM);
RETURN NULL;
END;
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
FUNCTION get_external_oracle_value(p_code_conv_cat       IN   VARCHAR2
                                  ,p_external_system     IN   VARCHAR2
                                  ,p_value               IN   VARCHAR2
                                  ,p_mode                IN   VARCHAR2
                                  ,p_parameter1          VARCHAR2       DEFAULT NULL
                                  ,p_parameter2          VARCHAR2       DEFAULT NULL
                                  ,p_parameter3          VARCHAR2       DEFAULT NULL
                                 )
RETURN VARCHAR2
IS
--
CURSOR cu_get_external_value
IS
SELECT  XREF_EXT_VALUE1
FROM    ECE_XREF_DATA
WHERE   XREF_CATEGORY_CODE = p_code_conv_cat
AND     XREF_KEY1          = p_external_system
AND     XREF_INT_VALUE     = p_value;
--
CURSOR cu_get_oracle_value
IS
SELECT  XREF_INT_VALUE
FROM    ECE_XREF_DATA
WHERE   XREF_CATEGORY_CODE  = p_code_conv_cat
AND     XREF_KEY1           = p_external_system
AND     XREF_EXT_VALUE1     = p_value;

--
lv_external_value    VARCHAR2(500);
lv_oracle_value      VARCHAR2(500);
BEGIN
--
IF  p_mode = 'OUTBOUND' THEN
--
  OPEN  cu_get_external_value;
  FETCH cu_get_external_value INTO lv_external_value;
  CLOSE cu_get_external_value;
  --
  RETURN lv_external_value;
--
ELSE
--
  OPEN  cu_get_oracle_value;
  FETCH cu_get_oracle_value INTO lv_oracle_value;
  CLOSE cu_get_oracle_value;
  --
  RETURN lv_oracle_value;
--
END IF;
--
--
EXCEPTION
WHEN OTHERS THEN
--
RETURN NULL;
xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Error in get_external_oracle_value: '||SQLERRM);
--
END get_external_oracle_value;
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
                                  )
IS
lv_wms_tp_ref1    VARCHAR2(200);
lv_wms_tp_ref2    VARCHAR2(200);
ln_org_id           number;
BEGIN
if p_org_id is null
then
  ln_org_id := -1;
else
  ln_org_id := p_org_id;
end if;
--
select eth.tp_reference_ext1 wms_tp_ref1
      ,eth.tp_reference_ext2 wms_tp_ref2
into   lv_wms_tp_ref1,lv_wms_tp_ref2
from ECE_TP_GROUP    etg
    ,ECE_TP_HEADERS  eth
where etg.tp_group_code         = p_group_code
and   etg.tp_group_id           = eth.tp_group_id
and   nvl(eth.org_id,ln_org_id) = ln_org_id
and   eth.tp_code               = p_tp_code;
--
x_reference1 := lv_wms_tp_ref1;
x_reference2 := lv_wms_tp_ref2;
--
exception
when others then
--
xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high, 'Error in get_trading_partner_ref: '||SQLERRM);
--
end get_trading_partner_ref;
--
/*-----------------------------------------------------------------
-- PROCEDURE get_process_param_value
-- Procedure to get process parameter value of any conc program
-- @p_process_name           --> Process Name
-- @p_param_name             --> Parameter Name
-- @x_param_value            --> Parameter Value
------------------------------------------------------------------*/
PROCEDURE get_process_param_value(p_process_name    IN  VARCHAR2
                                 ,p_param_name      IN  VARCHAR2
                                 ,x_param_value     OUT VARCHAR2
                                 )
IS

BEGIN
  SELECT parameter_value
    INTO x_param_value
    FROM xx_emf_process_parameters xepp
        ,xx_emf_process_setup      xeps
   WHERE xeps.process_name   = p_process_name
     AND xeps.process_id     = xepp.process_id
     AND xepp.parameter_name = p_param_name
     ;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    x_param_value := NULL;
  WHEN OTHERS
  THEN
    x_param_value := NULL;
END get_process_param_value;
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
                                    )RETURN NUMBER
IS
  x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
BEGIN
  IF p_process_name IS NOT NULL
  THEN
    UPDATE xx_emf_process_parameters xepp
       SET parameter_value = p_param_value
     WHERE xepp.parameter_name = p_param_name
       AND xepp.process_id = (SELECT process_id
                                FROM xx_emf_process_setup
                               WHERE process_name = p_process_name
                              );
    IF SQL%ROWCOUNT = 0
    THEN
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
    END IF;
  ELSE
    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
  END IF;
  RETURN x_error_code;
END update_process_param_value;
------------------------------------------------------------
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
                                 )
IS
BEGIN
  IF p_param_name IS NULL
  THEN
    BEGIN
      SELECT MIN(TO_DATE(parameter_value,'DD-MON-YYYY HH24:MI:SS'))
        INTO x_param_value
        FROM xx_emf_process_parameters xepp
            ,xx_emf_process_setup      xeps
       WHERE xeps.process_name   = p_process_name
         AND xeps.process_id     = xepp.process_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        x_param_value := NULL;
      WHEN OTHERS
      THEN
        x_param_value := NULL;
    END;
  ELSE
    get_process_param_value(p_process_name,p_param_name,x_param_value);
  END IF;
EXCEPTION
  WHEN OTHERS
  THEN
    x_param_value := NULL;
END get_prog_last_run_date;
---------------------------------------------------------------------
/*-----------------------------------------------------------------
-- FUNCTION update_run_date
-- FUNCTION to Update the last run date of the respective file name
-- in xx_emf_process_files table
-- @p_process_name           --> Process Name
-- @p_run_date               --> Run Date
-- @p_system_name            --> File Name
-- @p_request_id             --> Request id
------------------------------------------------------------------*/
FUNCTION update_run_date
              (p_process_name  IN VARCHAR2
	      ,p_run_date      IN DATE
              ,p_system_name   IN VARCHAR2 DEFAULT NULL
	      ,p_request_id    IN NUMBER DEFAULT NULL
               )
RETURN NUMBER
IS
  x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

  CURSOR get_file_name IS
   SELECT xepf.process_file_name
         ,xepf.process_id
     FROM xx_emf_process_files xepf
         ,xx_emf_process_setup xeps
    WHERE xepf.process_id = xeps.process_id
      AND xeps.process_name = p_process_name
      AND xepf.process_file_name = NVL(p_system_name,xepf.process_file_name);


BEGIN
  IF p_process_name IS NOT NULL  THEN
    FOR rec_file_name IN get_file_name
    LOOP
        UPDATE xx_emf_process_files xepf
           SET last_run_date = to_date(to_char(p_run_date,'DD-MON-RRRR HH24:MI:SS'),'DD-MON-RRRR HH24:MI:SS')
               ,last_request_id = LTRIM(RTRIM(p_request_id)) --1049258
	       ,last_updated_by  = fnd_global.user_id
   	       ,last_update_date  = SYSDATE
   	       ,last_update_login = fnd_global.login_id
         WHERE xepf.process_file_name = NVL(rec_file_name.process_file_name,xepf.process_file_name)
           AND xepf.process_id = rec_file_name.process_id;

    END LOOP;
       COMMIT;
  ELSE
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      --ROLLBACK;
  END IF;
  RETURN x_error_code;
    EXCEPTION
      WHEN OTHERS THEN
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	   dbms_output.put_line('error in update_run_date procedure : Others=>' || SQLERRM);
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.cn_high, 'error in update_run_date procedure : Others=>' || SQLERRM);
	  --ROLLBACK;
	  RETURN x_error_code;
END update_run_date;
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
RETURN NUMBER
IS
  x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
BEGIN
  IF p_process_name IS NOT NULL
  THEN
      SELECT last_run_date
        INTO p_run_date
	FROM xx_emf_process_files epf, xx_emf_process_setup eps
       WHERE epf.process_id = eps.process_id
	 AND eps.process_name = p_process_name
	 AND epf.process_file_name = NVL(p_system_name,epf.process_file_name);
    IF SQL%ROWCOUNT = 0
    THEN
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
    END IF;
  ELSE
    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
  END IF;
  RETURN x_error_code;
-- Should return a date if run for the first time
EXCEPTION
    WHEN NO_DATA_FOUND THEN
	p_run_date := TO_DATE ('01-JAN-1901', 'DD-MON-YYYY');
	x_error_code := xx_emf_cn_pkg.CN_REC_WARN;
	RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
	p_run_date := TO_DATE ('01-JAN-1901', 'DD-MON-YYYY');
	SELECT MIN(last_run_date)
          INTO p_run_date
	  FROM xx_emf_process_files epf, xx_emf_process_setup eps
         WHERE epf.process_id = eps.process_id
	   AND eps.process_name = p_process_name
	   AND epf.process_file_name = NVL(p_system_name,epf.process_file_name);
	x_error_code := xx_emf_cn_pkg.CN_REC_WARN;
	RETURN x_error_code;
    WHEN OTHERS THEN
	p_run_date := null;
	x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	RETURN x_error_code;
END get_last_run_date;
-----------------------------------------------------------------------
 ---------------------<  insert_fmw_ctl  >-------------------------
 -----------------------------------------------------------------------
 PROCEDURE insert_fmw_ctl ( p_file_name   IN varchar2
                               , p_event_name   IN varchar2 DEFAULT NULL)
IS
    -- Local variables
    x_created_by number := fnd_global.user_id;
    x_creation_date date := SYSDATE;
    x_last_updated_by number := fnd_global.user_id;
    x_last_update_date date := SYSDATE;
    x_last_update_login number := fnd_global.login_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO xx_emf_fmw_status_ctl (session_id
				  , file_name
				  , event_name
				  , process_code
				  , request_id
				  , created_by
				  , creation_date
				  , last_updated_by
				  , last_update_date
				  , last_update_login
				   )
			     VALUES (xx_emf_pkg.g_session_id
				   , p_file_name
				   , p_event_name
				   , 'START' -- p_process_code
				   , xx_emf_pkg.g_request_id
				   , x_created_by
				   , x_creation_date
				   , x_last_updated_by
				   , x_last_update_date
				   , x_last_update_login
				    );

    COMMIT;
EXCEPTION
    WHEN OTHERS
    THEN
	  -- Log it in log file and continue
	  fnd_file.put_line (fnd_file.LOG
			   , xx_emf_cn_pkg.cn_exp_unhand || xx_emf_pkg.g_request_id || p_file_name || SQLERRM
			    );
	  fnd_file.put_line (fnd_file.LOG
			   , 'Error = ' || SQLERRM
			    );
END insert_fmw_ctl;

-----------------------------------------------------------------------
 ---------------------<  update_fmw_ctl  >-------------------------
 -----------------------------------------------------------------------
 PROCEDURE update_fmw_ctl (p_file_name     IN varchar2
                               ,p_request_id    IN NUMBER
			       ,p_process_code  IN VARCHAR2
			       ,p_error_message IN VARCHAR2 DEFAULT NULL)
IS
    -- Local variables
    x_last_updated_by number := fnd_global.user_id;
    x_last_update_date date := SYSDATE;
    x_last_update_login number := fnd_global.login_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    UPDATE xx_emf_fmw_status_ctl
       SET process_code = p_process_code
         , error_message = p_error_message
	 , last_updated_by = x_last_updated_by
	 , last_update_date= x_last_update_date
     WHERE file_name  = p_file_name
       AND request_id = p_request_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS
    THEN
	  -- Log it in log file and continue
	  fnd_file.put_line (fnd_file.LOG
			   , xx_emf_cn_pkg.cn_exp_unhand ||p_request_id || p_file_name || SQLERRM
			    );
	  fnd_file.put_line (fnd_file.LOG
			   , 'Error = ' || SQLERRM
			    );
END update_fmw_ctl;
 -----------------------------------------------------------------------
 ---------------------------<  wait_for_fmw  >--------------------------
 -----------------------------------------------------------------------
function wait_for_fmw(p_request_id IN NUMBER,
		      p_error_message OUT VARCHAR2,
		      interval   IN number default 30,
		      max_wait   IN number default 0)
 return  VARCHAR2 is
	dev_phase      VARCHAR2(30);
	Time_Out       boolean := FALSE;
	pipename       varchar2(60);
	req_phase      varchar2(15);
	STime	       number(30);
	ETime	       number(30);
	Rid            number := p_request_id;
	i	       number;
	ORAERRMESG     VARCHAR2(80);
	l_error_msg    VARCHAR2(4000);
	l_error_msg1   VARCHAR2(32000);
	l_file_name   xx_emf_fmw_status_ctl.file_name%type;
	l_count  NUMBER;
	l_total_interval NUMBER := 0;
	l_max_interval   NUMBER := 5400;


	CURSOR get_message IS
	SELECT error_message, file_name
          FROM xx_emf_fmw_status_ctl
	 WHERE request_id = p_request_id
	   AND error_message IS NOT NULL;

	   CURSOR get_process_code IS
	SELECT process_code
          FROM xx_emf_fmw_status_ctl
	 WHERE request_id = p_request_id;

  begin
    if ( max_wait > 0 ) then
	Time_Out := TRUE;
	Select To_Number(((To_Char(Sysdate, 'J') - 1 ) * 86400) +
		 To_Char(Sysdate, 'SSSSS'))
	  Into STime From Sys.Dual;
    end if;

    LOOP

        SELECT count(file_name) INTO l_count
            FROM xx_emf_fmw_status_ctl
           WHERE request_id = p_request_id
	     AND process_code = 'START';
	IF l_count =0 THEN
		   OPEN get_message;
		   LOOP
                        FETCH get_message INTO l_error_msg, l_file_name;
                        l_error_msg1 := l_file_name||SUBSTR(l_error_msg,1,200) ||Chr(10)||l_error_msg1;
                        EXIT WHEN get_message%NOTFOUND;
                   END LOOP;
		   CLOSE get_message;
                   p_error_message := l_error_msg1;
		   OPEN get_process_code;
		   LOOP
		      FETCH get_process_code INTO dev_phase;
                      EXIT WHEN (get_process_code%NOTFOUND OR dev_phase = 'ERROR' OR dev_phase = 'COMPLETE' OR dev_phase = 'PROCESSED');
                   END LOOP;
		   CLOSE get_process_code;
                   return dev_phase;
		if ( Time_Out ) then
		   Select To_Number(((To_Char(Sysdate, 'J') - 1 ) * 86400) +
			  To_Char(Sysdate, 'SSSSS'))
		     Into ETime From Sys.Dual;

		   if ( (ETime - STime) >= max_wait ) then
		      return dev_phase;
		   end if;
		end if;
         END IF;
	   dbms_lock.sleep(interval);
	   l_total_interval := l_total_interval + interval;
	   IF l_total_interval > l_max_interval THEN
	       IF p_error_message IS NULL THEN
	           p_error_message := 'Process Time Out';
	       END IF;
	       RETURN 'ERROR';
	   END IF ;


    END LOOP;

    exception
       when others then
	  oraerrmesg := substr(SQLERRM, 1, 80);
	  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'error in wait_for_fmw '|| oraerrmesg);
          return 'COMPLETE';
  end wait_for_fmw;

 -----------------------------------------------------------------------
 ----------------------<  wait_for_file_in_fmw  >--------------------------
 -----------------------------------------------------------------------
function wait_for_file_in_fmw(p_request_id IN NUMBER,
                      p_file_name  IN VARCHAR2,
		      p_error_message OUT VARCHAR2,
		      interval   IN number default 30,
		      max_wait   IN number default 0)
 return  VARCHAR2 is
	dev_phase      VARCHAR2(30);
	Time_Out       boolean := FALSE;
	pipename       varchar2(60);
	req_phase      varchar2(15);
	STime	       number(30);
	ETime	       number(30);
	Rid            number := p_request_id;
	i	       number;
	ORAERRMESG     VARCHAR2(80);
	l_error_msg    VARCHAR2(4000);
	l_error_msg1   VARCHAR2(32000);
	l_file_name   xx_emf_fmw_status_ctl.file_name%type;
	l_count  NUMBER;
	l_total_interval NUMBER := 0;
	l_max_interval   NUMBER := 900;


	CURSOR get_message IS
	SELECT error_message, file_name
          FROM xx_emf_fmw_status_ctl
	 WHERE request_id = p_request_id
	   AND file_name = p_file_name
	   AND error_message IS NOT NULL;

	CURSOR get_process_code IS
	SELECT process_code
          FROM xx_emf_fmw_status_ctl
	 WHERE request_id = p_request_id
	   AND file_name = p_file_name;

  begin
    if ( max_wait > 0 ) then
	Time_Out := TRUE;
	Select To_Number(((To_Char(Sysdate, 'J') - 1 ) * 86400) +
		 To_Char(Sysdate, 'SSSSS'))
	  Into STime From Sys.Dual;
    end if;

    LOOP

        SELECT count(file_name) INTO l_count
            FROM xx_emf_fmw_status_ctl
           WHERE request_id = p_request_id
	     AND process_code = 'START'
	     AND file_name = p_file_name;
	IF l_count =0 THEN
		   OPEN get_message;
		   LOOP
                        FETCH get_message INTO l_error_msg, l_file_name;
                        l_error_msg1 := l_file_name||SUBSTR(l_error_msg,1,200) ||Chr(10)||l_error_msg1;


                   EXIT WHEN get_message%NOTFOUND;
                   END LOOP;
		   CLOSE get_message;
                   p_error_message := l_error_msg1;
		   OPEN get_process_code;
		   LOOP
		      FETCH get_process_code INTO dev_phase;
                      EXIT WHEN (get_process_code%NOTFOUND OR dev_phase = 'ERROR' OR dev_phase = 'COMPLETE' OR dev_phase = 'PROCESSED');
                   END LOOP;
		   CLOSE get_process_code;
                   return dev_phase;
		if ( Time_Out ) then
		   Select To_Number(((To_Char(Sysdate, 'J') - 1 ) * 86400) +
			  To_Char(Sysdate, 'SSSSS'))
		     Into ETime From Sys.Dual;

		   if ( (ETime - STime) >= max_wait ) then
		       return dev_phase;
		   end if;
		end if;
         END IF;
	   dbms_lock.sleep(interval);
	   l_total_interval := l_total_interval + interval;
	   IF l_total_interval > l_max_interval THEN
	       IF p_error_message IS NULL THEN
	           p_error_message := 'Process Time Out';
	       END IF;
	       RETURN 'ERROR';
	   END IF ;


    END LOOP;

    exception
       when others then
	  oraerrmesg := substr(SQLERRM, 1, 80);
	  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high, 'error in wait_for_file_in_fmw '|| oraerrmesg);
          return 'COMPLETE';
  end wait_for_file_in_fmw;
  ------------------------------------------------------
  PROCEDURE xx_single_batch_submit(x_errbuf       OUT   VARCHAR2
                                  ,x_retcode      OUT   NUMBER
                                  ,p_event_name   IN    VARCHAR2
                                  ,p_request_id   IN    NUMBER
                                  ,p_batch_number IN    NUMBER)
  AS
    x_item_key   NUMBER;
    --v_conc_request_id             NUMBER := fnd_global.conc_request_id;
    x_parameter_list              wf_parameter_list_t := wf_parameter_list_t ();
  BEGIN
    SELECT apps.oe_xml_message_seq_s.NEXTVAL
      INTO x_item_key
      FROM DUAL;

    fnd_file.put_line (fnd_file.LOG, 'Starting Event for batch number  :'||p_batch_number||'  at this time  :'||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
    fnd_file.put_line (fnd_file.LOG, 'Concurrent Request Id: ' || p_request_id);
    fnd_file.put_line (fnd_file.LOG, 'Iten_key: ' || x_item_key);

    wf_event.addparametertolist (p_name               => 'request_id'
                               , p_value              => p_request_id
                               , p_parameterlist      => x_parameter_list);
    wf_event.addparametertolist (p_name => 'batch_id'
                                ,p_value => p_batch_number
                                ,p_parameterlist => x_parameter_list);
    wf_event.RAISE (p_event_name      => p_event_name
                  , p_event_key       => x_item_key
                  , p_parameters      => x_parameter_list
                   );
    COMMIT;
  END xx_single_batch_submit;
 -----------------------------------------------------------------------
 -----------------------<  rem_special_char  >--------------------------
 -----------------------------------------------------------------------
FUNCTION rem_special_char(p_string IN VARCHAR2)
RETURN VARCHAR2 IS

l_string VARCHAR2(2000);
 BEGIN
    --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'rem_special_char ');
    l_string := p_string;
    FOR I IN 0..31 LOOP
        l_string := REPLACE(l_string,CHR(I),'');
    END LOOP;
        l_string := REPLACE(l_string,CHR(35),'');  --Removing character'#'
        l_string := REPLACE(l_string,CHR(58),'');    --Removing character ':'
        l_string := REPLACE(l_string,CHR(59),'');     --Removing character ';'
        l_string := REPLACE(l_string,CHR(127),'');
        l_string := REPLACE(l_string,CHR(129),'');
        l_string := REPLACE(l_string,CHR(136),'');   --Removing character '¿'
        l_string := REPLACE(l_string,CHR(137),'');   --Removing character '¿'
        l_string := REPLACE(l_string,CHR(38),'and');   --Replacing character '&' with 'and'
        l_string := REPLACE(l_string,CHR(46),'');   --Removing character '.'
        l_string := REPLACE(l_string,CHR(45),'');   --Removing character '-'
        l_string := REPLACE(l_string,CHR(37),'');   --Removing character '%'


    RETURN l_string;
 EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_high, 'rem_special_char  Others=>' || SQLERRM);
        RETURN l_string;
END rem_special_char;
--
---------------------------------------------------------------------------------
-- Procedure to show the files which has errored during FMW procession in Output
---------------------------------------------------------------------------------
PROCEDURE alert_error_files(p_request_id IN NUMBER)
IS
 CURSOR get_fmw_error_status IS
 SELECT file_name
      , error_message
   FROM xx_emf_fmw_status_ctl
  WHERE request_id = p_request_id
    AND process_code = 'ERROR';
--
x_count NUMBER;
x_sr_no NUMBER := 0;
x_dis_buffer varchar2(2000);
--
BEGIN
    SELECT count(file_name)
      INTO x_count
      FROM xx_emf_fmw_status_ctl
     WHERE request_id = p_request_id
       AND process_code = 'ERROR';
  IF x_count > 0 THEN
      xx_emf_pkg.put_line('+-----------------------------------------------------------------------------------+');
      xx_emf_pkg.put_line('+ Request ID : '|| p_request_id ||'                                                                   +');
      xx_emf_pkg.put_line('+ Following files has error during FMW processing :                                 +');
      xx_emf_pkg.put_line('+-----------------------------------------------------------------------------------+');
      xx_emf_pkg.put_line(' ');
      x_dis_buffer := RPAD (' Sr No.'
                         , 7
                         , '  '
                          )
                  || RPAD (' File Name'
                         , 50
                         , '  '
                          )
                  || RPAD (' Error Message'
                         , 70
                         , '  '
                          );
      xx_emf_pkg.put_line(x_dis_buffer);
      xx_emf_pkg.put_line(RPAD('-',127,'-'));
      FOR rec_fmw_error_status IN get_fmw_error_status  LOOP
          x_sr_no :=   x_sr_no + 1;
	  x_dis_buffer := RPAD(x_sr_no,7) || RPAD(rec_fmw_error_status.file_name,50) || RPAD(rec_fmw_error_status.error_message,70);
	  xx_emf_pkg.put_line(x_dis_buffer);
      END LOOP;
      xx_emf_pkg.put_line(' ');
      xx_emf_pkg.put_line('+-----------------------------------------------------------------------------------+');
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.LOG, 'Error Code:  ' || SQLCODE);
        fnd_file.put_line (fnd_file.LOG, 'Error Description:  ' || SQLERRM);
END alert_error_files;
---------------------------------------------------------------------------------
-- Procedure to set langauge at session level
---------------------------------------------------------------------------------
PROCEDURE set_session_language( p_email_id IN VARCHAR2 DEFAULT NULL
                               ,p_user_id  IN VARCHAR2 DEFAULT NULL )
IS
   CURSOR c_get_language(p_email_id IN VARCHAR2)
   IS
   SELECT DISTINCT wlr.language
     FROM per_all_people_f ppf
         ,fnd_user fu
         ,wf_local_roles wlr
    WHERE ppf.person_id = fu.employee_id
      AND fu.user_name = wlr.name
      AND wlr.status = 'ACTIVE'
      AND ppf.email_address = p_email_id
      AND SYSDATE  BETWEEN ppf.effective_start_date AND NVL(ppf.effective_end_date,SYSDATE)
      AND SYSDATE  BETWEEN fu.start_date AND NVL(fu.end_date,SYSDATE);

   CURSOR c_get_language2(p_user_id  IN VARCHAR2)
   IS
   SELECT DISTINCT wlr.language
     FROM wf_local_roles wlr
    WHERE wlr.status = 'ACTIVE'
      AND wlr.name = p_user_id;

   CURSOR c_get_language3(p_email_id IN VARCHAR2)
   IS
       SELECT nls_language
         FROM fnd_languages_vl
        WHERE nls_language =
                 fnd_profile.value_specific ('ICX_LANGUAGE',(SELECT person_id
                                                               FROM per_all_people_f ppf
                                                              WHERE ppf.email_address = p_email_id
                                                                AND SYSDATE  BETWEEN ppf.effective_start_date AND NVL(ppf.effective_end_date,SYSDATE)));
   x_language VARCHAR2(50):=NULL;
   x_count    NUMBER;

BEGIN

   IF p_email_id IS NOT NULL THEN
      --Fetch language
       OPEN c_get_language(p_email_id);
       FETCH c_get_language
        INTO x_language;
	IF c_get_language%NOTFOUND
        THEN
          BEGIN
          SELECT count(1)
            INTO x_count
            FROM per_all_people_f ppf
           WHERE ppf.email_address = p_email_id
             AND SYSDATE  BETWEEN ppf.effective_start_date AND NVL(ppf.effective_end_date,SYSDATE);
          EXCEPTION
          WHEN OTHERS THEN
             x_count:=0;
             x_language:=NULL;
          END;
          IF x_count > 0
          THEN
             OPEN c_get_language3(p_email_id);
            FETCH c_get_language3
             INTO x_language;
            CLOSE c_get_language3;
          END IF;
        END IF;
      CLOSE c_get_language;

      x_language := ''''||x_language||'''';
      --Set session level language
      DBMS_SESSION.SET_NLS('NLS_LANGUAGE',NVL(x_language,'AMERICAN'));
   ELSIF p_user_id IS NOT NULL THEN
      --Fetch language
       OPEN c_get_language2(p_user_id);
      FETCH c_get_language2
       INTO x_language;
      CLOSE c_get_language2;

      x_language := ''''||x_language||'''';
      --Set session level language
      DBMS_SESSION.SET_NLS('NLS_LANGUAGE',NVL(x_language,'AMERICAN'));
   ELSE
      --Set session level language to English
      DBMS_SESSION.SET_NLS('NLS_LANGUAGE','AMERICAN');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_SESSION.SET_NLS('NLS_LANGUAGE','AMERICAN');
      fnd_file.put_line (fnd_file.LOG, 'Inside set_session_language');
      fnd_file.put_line (fnd_file.LOG, 'Error Code:  ' || SQLCODE);
      fnd_file.put_line (fnd_file.LOG, 'Error Description:  ' || SQLERRM);
END set_session_language;
---------------------------------------------------------------------------------
-- Procedure to get OU specific template for reports
---------------------------------------------------------------------------------
FUNCTION get_ou_specific_templ(
    P_OU_NAME            VARCHAR2,
    P_CNC_PGM_SHORT_NAME VARCHAR2)
  RETURN VARCHAR
IS
  V_TEMP VARCHAR2(150);
BEGIN
  SELECT description
  INTO V_TEMP
  FROM fnd_lookup_values
  WHERE LOOKUP_TYPE = 'XX_INTG_RPT_OU_TEMPLATE'
  AND MEANING       = P_OU_NAME||'|'||p_cnc_pgm_short_name
 -- AND tag           = p_cnc_pgm_short_name
  AND LANGUAGE      = 'US';
  RETURN V_TEMP;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  SELECT description
  INTO V_TEMP
  FROM fnd_lookup_values
  WHERE LOOKUP_TYPE = 'XX_INTG_RPT_OU_TEMPLATE'
  AND MEANING       = 'DEFAULT'||'|'||P_CNC_PGM_SHORT_NAME
 -- AND tag           = p_cnc_pgm_short_name
  AND LANGUAGE      = 'US';
  RETURN v_temp;
WHEN OTHERS THEN
  RETURN NULL;
END;


-- The beow procedure launch_bursting has to be part of wave1 change.
-- Added for use in M2C-RPT-111 Commissions Report
---------------------------------------------------------------------------------
-- Procedure to launch custom bursting for reports
---------------------------------------------------------------------------------
PROCEDURE launch_bursting( errbuf          OUT  VARCHAR2,
                              retcode         OUT  NUMBER,
                              p_request_id    IN   NUMBER)
   IS
      x_reqid              NUMBER;
      x_phase              VARCHAR2(80);
      x_status             VARCHAR2(80);
      x_devphase           VARCHAR2(80);
      x_devstatus          VARCHAR2(80);
      x_message            VARCHAR2(80);
      x_check              BOOLEAN;
   BEGIN

         IF p_request_id IS NOT NULL THEN

            x_check:=FND_CONCURRENT.WAIT_FOR_REQUEST(p_request_id,1,0,x_phase,x_status,x_devphase,x_devstatus,x_message);


            x_reqid := FND_REQUEST.SUBMIT_REQUEST ('XDO',
                                                   'XDOBURSTREP',
                                                    NULL,
                                                    NULL,
                                                    FALSE,
                                                    'Y',
                                                    p_request_id,
                                                   'N'
                                                  );
            COMMIT;

         END IF;
   EXCEPTION
      WHEN OTHERS THEN
         retcode := 1;
   END;
  
END XX_INTG_COMMON_PKG;
/


GRANT EXECUTE ON APPS.XX_INTG_COMMON_PKG TO INTG_XX_NONHR_RO;
