DROP PACKAGE BODY APPS.XX_GL_CONS_FFIELD_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_GL_CONS_FFIELD_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 29-Mar-2012
 File Name     : XXGLCONFLEXMAPVAL.pks
 Description   : This script creates the body of the package xx_gl_cons_ffield_val_pkg
 Change History:
 ----------------------------------------------------------------------
 Date        Name       Remarks
 ----------- ----       -----------------------------------------------
 29-Mar-2012 IBM Development Team   Initial development.
*/
-----------------------------------------------------------------------
/***********************************************************************************
 Function find_max is used to compare the error code
    Error_Code :  CN_SUCCESS       =  '0';
                  CN_REC_WARN      =  '1';
                  CN_REC_ERR       =  '2';
                  CN_PRC_ERR       =  '3';
    to get the maximum error code by comparing the existing error _code for a specific record
    with the latest error code occured during validation/derivation process for another
    column of the same record , so that once the whole record's columns gets vaidated/derived
    we should get the maximum error  code to indicate the proper error status of it
    Parameter : p_error_code1  --> existing error code in the record
                p_error_code2  --> current error code
                                   generated for next column validation/derivation
   ***********************************************************************************/
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

/***********************************************************************************
 This function is used for Pre validations for XXCNV.XX_FA_MASS_ADD_STG table records
 It will validate the record which we passed as an input parameter column by column
 and will return the validation status column by column
 Parameter :
 p_cuscnv_hdr_rec  --> the record which we need to validate.
*************************************************************************************/
   FUNCTION pre_validations (
      p_cnv_hdr_rec   IN OUT NOCOPY   xx_gl_cons_ffield_load_pkg.g_xxgl_ffield_map_piface_rec
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Pre-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

---------------------------------------------------------------------------------------------

   /***********************************************************************************
    This function is used for Data validations for XX_GL_CONS_FFIELD_MAP_STG table records
    It will validate the record which we passed as an input parameter column by column
    and will return the validation status column by column
    Parameter :
    p_cuscnv_hdr_rec  --> the record which we need to validate.
   *************************************************************************************/
   FUNCTION data_validations (
      p_gl_map_rec   IN OUT NOCOPY   xx_gl_cons_ffield_load_pkg.g_xxgl_ffield_map_piface_rec
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER          := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER          := xx_emf_cn_pkg.cn_success;
      x_sqlerrm           VARCHAR2 (2000);

------------------------------------------------------------------------------------------
---------- check for duplicate records-----------------------------------------------------
------------------------------------------------------------------------------------------
      FUNCTION check_dups_source
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         l_count        NUMBER := 0;
      BEGIN
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  '~Duplicate source account range validaion'
                                 );

            SELECT COUNT (1)
              INTO l_count
              FROM xx_gl_cons_ffield_map_stg
             WHERE segment1_low = p_gl_map_rec.segment1_low
               AND segment1_high = p_gl_map_rec.segment1_high
               AND segment2_low = p_gl_map_rec.segment2_low
               AND segment2_high = p_gl_map_rec.segment2_high
               AND segment3_low = p_gl_map_rec.segment3_low
               AND segment3_high = p_gl_map_rec.segment3_high
               AND segment4_low = p_gl_map_rec.segment4_low
               AND segment4_high = p_gl_map_rec.segment4_high
               AND segment5_low = p_gl_map_rec.segment5_low
               AND segment5_high = p_gl_map_rec.segment5_high
               AND segment6_low = p_gl_map_rec.segment6_low
               AND segment6_high = p_gl_map_rec.segment6_high
               AND segment7_low = p_gl_map_rec.segment7_low
               AND segment7_high = p_gl_map_rec.segment7_high
               AND segment8_low = p_gl_map_rec.segment8_low
               AND segment8_high = p_gl_map_rec.segment8_high;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, SQLERRM);
         END;

         IF l_count = 1 AND x_error_code = xx_emf_cn_pkg.cn_success
         THEN
            xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   '~Duplicate source account range Validaion SUCCESS for record number =>'
                || p_gl_map_rec.record_number
               );
         ELSIF l_count > 0
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_low,
                    p_category                 => xx_emf_cn_pkg.cn_valid,
                    p_error_text               => 'Duplicate source account range exists.',
                    p_record_identifier_1      => p_gl_map_rec.record_number,
                    p_record_identifier_2      => NULL,
                    p_record_identifier_3      => NULL
                   );
         END IF;

         RETURN x_error_code;
      END check_dups_source;
------------------------------------------------------------------------------------------------
--- Start of the main function perform_batch_validations
--- This will only have calls to the individual functions.
   BEGIN                                          -- begin of data_validations
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'In start of Data-Validations'
                           );
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
      x_error_code_temp := check_dups_source;
      x_error_code := find_max (x_error_code, x_error_code_temp);
--xx_emf_pkg.propagate_error(x_error_code_temp);
------------------------------------------------------------------------------------------
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After data validations' || x_error_code
                           );
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END data_validations;

/***********************************************************************************
 This function is used for Post validations for XX_AR_PROFILE_STG table records
 It will validate the record which we passed as an input parameter column by column
 and will return the validation status column by column
 Parameter :
 p_profile_cnv_dtl_rec  --> the record which we need to validate.
*************************************************************************************/--**********************************************************************
   --Function to Post Validations .
   --**********************************************************************
   FUNCTION post_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside Post-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END post_validations;

--**********************************************************************
  --Function to Data Derivations.
--**********************************************************************
   FUNCTION data_derivations (
      p_cnv_pre_std_hdr_rec   IN OUT NOCOPY   xx_gl_cons_ffield_load_pkg.g_xxgl_ffield_map_piface_rec,
      p_ledger_id             IN              NUMBER
   )
      RETURN NUMBER
   IS
      x_error_code               NUMBER   := xx_emf_cn_pkg.cn_success;
      x_error_code_temp          NUMBER   := xx_emf_cn_pkg.cn_success;
      l_to_code_combination_id   NUMBER;
      l_delim                    CHAR (1);
      l_coa_id                   NUMBER;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'In Data Derivation logic section'
                           );

      BEGIN
         SELECT chart_of_accounts_id
           INTO l_coa_id
           FROM gl_ledgers
          WHERE ledger_id = p_ledger_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Error while fetching CoA ID ' || SQLERRM
                                 );
      END;

      IF l_coa_id IS NOT NULL
      THEN
         l_delim := fnd_flex_ext.get_delimiter ('SQLGL', 'GL#', l_coa_id);
      END IF;

      --------------Derivation of to_code_combination_id----------------------------------------------------
      l_to_code_combination_id :=
         fnd_flex_ext.get_ccid ('SQLGL',
                                'GL#',
                                l_coa_id,
                                TO_CHAR (SYSDATE, 'DD-MON-YYYY'),
                                   p_cnv_pre_std_hdr_rec.to_segment1
                                || l_delim
                                || p_cnv_pre_std_hdr_rec.to_segment2
                                || l_delim
                                || p_cnv_pre_std_hdr_rec.to_segment3
                                || l_delim
                                || p_cnv_pre_std_hdr_rec.to_segment4
                                || l_delim
                                || p_cnv_pre_std_hdr_rec.to_segment5
                                || l_delim
                                || p_cnv_pre_std_hdr_rec.to_segment6
                                || l_delim
                                || p_cnv_pre_std_hdr_rec.to_segment7
                                || l_delim
                                || p_cnv_pre_std_hdr_rec.to_segment8
                                --NPANDA|| l_delim
                                --NPANDA|| p_cnv_pre_std_hdr_rec.to_segment9
                               );

      IF l_to_code_combination_id <= 0
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.error
              (p_severity                 => xx_emf_cn_pkg.cn_low,
               p_category                 => xx_emf_cn_pkg.cn_valid,
               p_error_text               => fnd_message.get,
               p_record_identifier_1      => p_cnv_pre_std_hdr_rec.record_number,
               p_record_identifier_2      =>    p_cnv_pre_std_hdr_rec.to_segment1
                                             || l_delim
                                             || p_cnv_pre_std_hdr_rec.to_segment2
                                             || l_delim
                                             || p_cnv_pre_std_hdr_rec.to_segment3
                                             || l_delim
                                             || p_cnv_pre_std_hdr_rec.to_segment4
                                             || l_delim
                                             || p_cnv_pre_std_hdr_rec.to_segment5
                                             || l_delim
                                             || p_cnv_pre_std_hdr_rec.to_segment6
                                             || l_delim
                                             || p_cnv_pre_std_hdr_rec.to_segment7
                                             || l_delim
                                             || p_cnv_pre_std_hdr_rec.to_segment8,--NPANDA added comma
                                             --NPANDA|| l_delim
                                             --NPANDA|| p_cnv_pre_std_hdr_rec.to_segment9,
               p_record_identifier_3      => l_coa_id
              );
         RETURN x_error_code;
      ELSE
         p_cnv_pre_std_hdr_rec.to_code_combination_id :=
                                                     l_to_code_combination_id;
      END IF;

      x_error_code := find_max (x_error_code, x_error_code_temp);
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
   END data_derivations;
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
END xx_gl_cons_ffield_val_pkg;
/


GRANT EXECUTE ON APPS.XX_GL_CONS_FFIELD_VAL_PKG TO INTG_XX_NONHR_RO;
