DROP PACKAGE BODY APPS.XX_FASSETS_TAX_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_FASSETS_TAX_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 20-Mar-2012
 File Name     : XXFAASSTTAXVAL.pkb
 Description   : This script creates the body of the package xx_ar_receipt_val_pkg
 Change History:
 ----------------------------------------------------------------------
 Date        Name       Remarks
 ----------- ----       -----------------------------------------------
 19-may-10 Venu G Tanniru   Initial development.
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
   FUNCTION pre_validations (p_cnv_hdr_rec IN OUT nocopy xx_fassets_tax_cnv_pkg.G_XX_FAASST_TAX_PIFACE_REC
                            ) RETURN NUMBER   IS
       x_error_code      NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
       x_error_code_temp NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations');
       RETURN x_error_code;
      EXCEPTION
       WHEN xx_emf_pkg.G_E_REC_ERROR THEN
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           RETURN x_error_code;
       WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
           x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
           RETURN x_error_code;
       WHEN OTHERS THEN
           x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
           RETURN x_error_code;
   END pre_validations;
  ---------------------------------------------------------------------------------------------

   /***********************************************************************************
    This function is used for Data validations for XX_FA_TAX_INT_STG table records
    It will validate the record which we passed as an input parameter column by column
    and will return the validation status column by column
    Parameter :
    p_cuscnv_hdr_rec  --> the record which we need to validate.
   *************************************************************************************/

  FUNCTION data_validations(
      p_rcpt_hdr_rec IN OUT NOCOPY xx_fassets_tax_cnv_pkg.G_XX_FAASST_TAX_PIFACE_REC )
    RETURN NUMBER
  IS
    x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
    x_sqlerrm         VARCHAR2(2000);


  ------------------------------------------------------------------------------------------
  ---------- Function for ASSET NUMBER -----------------------------------------------------
  ------------------------------------------------------------------------------------------
        /* FUNCTION asset_number_valid(
                            p_asset_number IN VARCHAR2 ,
                            p_book_type_code IN VARCHAR2
                                     )
             RETURN NUMBER
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
           BEGIN

             --IF p_asset_number IS  NOT NULL THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Asst Num Validaion =>p_asset_number=>'|| p_asset_number||'p_book_type_code=>'||p_book_type_code||'p_description=>'||p_description );
          SELECT fa.asset_number
            INTO p_rcpt_hdr_rec.asset_number
            FROM fa_additions fa,fa_books fb
           WHERE fa.asset_id = fb.asset_id
             AND fa.asset_number = p_asset_number
             AND fb.book_type_code = p_book_type_code;


           xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Asst Num Validaion SUCCESS=>'|| p_rcpt_hdr_rec.asset_number );
      --  END IF;

             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside Asset Number data val' || x_error_code);
             RETURN x_error_code;
             EXCEPTION

       WHEN NO_DATA_FOUND THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low ,
                           p_category   => xx_emf_cn_pkg.cn_valid
                          ,p_error_text => 'No Asset found for this asset'
                          ,p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3
                    ,p_record_identifier_2 => p_rcpt_hdr_rec.asset_number
                          ,p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                           );
         RETURN x_error_code;
            WHEN TOO_MANY_ROWS THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                          ,p_category   => xx_emf_cn_pkg.cn_valid
                          ,p_error_text =>'Multiple Assets  found'
                          ,p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3
                    ,p_record_identifier_2 => p_rcpt_hdr_rec.asset_number
                          ,p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                           );
         RETURN x_error_code;
       WHEN OTHERS THEN
           x_sqlerrm    := SUBSTR(sqlerrm,200);
           x_error_code := xx_emf_cn_pkg.cn_rec_err;
           xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low
                          ,p_category => xx_emf_cn_pkg.cn_valid
                          ,p_error_text => 'Error in Asset is t'|| sqlerrm
                          ,p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3
                    ,p_record_identifier_2 => p_rcpt_hdr_rec.asset_number
                          ,p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                            );
                    RETURN x_error_code;
           END asset_number_valid;*/


    ----------------------------------------------------------------------------------------
    ----------Function for Asset Book_type_code----------------------------------------------
    -------------------------------------------------------------------------------------------

      FUNCTION check_book_type_code(p_book_type_code IN VARCHAR2
                                   )
      RETURN NUMBER
      IS
        x_error_code  NUMBER := xx_emf_cn_pkg.cn_success;

        x_string                  VARCHAR2(40);
        x_book_type_code          VARCHAR2(40);
        x_book_type               VARCHAR2(40);

      BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Book_Type_Code Validation=>'||p_book_type_code);

        IF p_book_type_code IS  NOT NULL
        THEN
         -- IF p_batch_id LIKE 'PRMS%' then

          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Book_Type_Code Validation Company _code =>'|| x_book_type_code);

           /* select xx_asl_common_pkg.get_mapping_value
                                 ('COMPANY_ASSET_BOOK_TYPE'
                                  ,NULL
                                  ,p_book_type_code
                             ,SYSDATE
                            )
                     INTO p_rcpt_hdr_rec.book_type_code
              from dual;*/
              SELECT BOOK_TYPE_CODE
                INTO  x_book_type_code
                FROM fa_book_controls
               WHERE  BOOK_TYPE_CODE = p_book_type_code;

         END IF;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Book_Type_Code Validation SUCCESS=>'|| x_book_type_code);

        RETURN x_error_code;
      EXCEPTION

      WHEN NO_DATA_FOUND THEN
        x_error_code := xx_emf_cn_pkg.cn_rec_err;
        xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low ,
                          p_category   => xx_emf_cn_pkg.cn_valid
                         ,p_error_text => 'No book_type_code found for this asset'
                         ,p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3
                         ,p_record_identifier_2 => p_rcpt_hdr_rec.asset_number
                         ,p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                            );
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'No data found for book_type_code');

        RETURN x_error_code;
         WHEN TOO_MANY_ROWS THEN
        x_error_code := xx_emf_cn_pkg.cn_rec_err;
        xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                         ,p_category   => xx_emf_cn_pkg.cn_valid
                         ,p_error_text =>'Multiple book_type_code found'
                         ,p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3
                         ,p_record_identifier_2 => p_rcpt_hdr_rec.asset_number
                         ,p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                           );
        RETURN x_error_code;
      WHEN OTHERS THEN
          x_sqlerrm    := SUBSTR(sqlerrm,200);
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low
                         ,p_category => xx_emf_cn_pkg.cn_valid
                         ,p_error_text => 'Error in book_type_code'|| sqlerrm
                         ,p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3
                         ,p_record_identifier_2 => p_rcpt_hdr_rec.asset_number
                         ,p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                           );
          RETURN x_error_code;
      END check_book_type_code;

  ------------------------------------------------------------------------------------------
  ----------Function for DEPRECIATE_FLAG-------------------------------------------------------
  ------------------------------------------------------------------------------------------
        FUNCTION depreciate_flag(
               p_depreciate_flag IN VARCHAR2 )
             RETURN NUMBER
           IS
             x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
           BEGIN
             IF p_depreciate_flag not in ('YES','NO')
             THEN
               --x_error_code      := xx_emf_cn_pkg.cn_success;
               x_error_code      := xx_emf_cn_pkg.cn_rec_err;
             --ELSE

               xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low,
                                 p_category => xx_emf_cn_pkg.cn_valid,
                                 p_error_text => 'Depreciate flag is not Valid',
                                 p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3
                                ,p_record_identifier_2 => p_rcpt_hdr_rec.asset_number
                         ,p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                           );
             END IF;
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Depreciate flag Validation=>' || x_error_code);
             RETURN x_error_code;
           END depreciate_flag;

   ------------------------------------------------------------------------------------------
   ------------------------------------------------------------------------------------------
   ----------Function for date_placed_in_service validation----------------------------------
   ------------------------------------------------------------------------------------------
         FUNCTION date_placed_in_svc_check(
                p_date_placed_in_svc IN DATE
               ,p_book_type_code     IN VARCHAR2)
              RETURN NUMBER
            IS
              x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
              x_period_counter    NUMBER := 0;
              x_curr_period_counter NUMBER := 0;
            BEGIN
              IF p_date_placed_in_svc is NOT NULL THEN
                 BEGIN
                 SELECT TO_NUMBER (TO_CHAR (start_date, 'YYYY')) * 12 + period_num
           INTO x_period_counter
           FROM fa_calendar_periods fcp
          WHERE p_date_placed_in_svc BETWEEN start_date AND end_date
                    AND UPPER(fcp.calendar_type) = 'INTG MONTH';
                  EXCEPTION WHEN OTHERS THEN
                    x_error_code      := xx_emf_cn_pkg.cn_rec_err;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'This date placed is service does not fall in a valid period.Date placed in service -->'||to_char(p_date_placed_in_svc,'MM/DD/YYYY'));
                    RETURN x_error_code;
                  END;
              ELSE
                RETURN x_error_code;
              END IF;
              -- find the current period for the tax book
              IF x_period_counter <> 0 THEN
              BEGIN
               SELECT last_period_counter
                 INTO x_curr_period_counter
                 FROM fa_book_controls
                WHERE book_type_code = p_book_type_code;
              EXCEPTION WHEN OTHERS THEN
                    x_error_code      := xx_emf_cn_pkg.cn_rec_err;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'This book type code '||p_book_type_code||' is not a valid one.');
                    RETURN x_error_code;
              END;
              END IF;
              IF x_curr_period_counter <> 0 THEN
                 IF x_curr_period_counter >= x_period_counter THEN
                    x_error_code  := xx_emf_cn_pkg.cn_success;
                 ELSE
                    x_error_code      := xx_emf_cn_pkg.cn_rec_err;
                    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Date Placed in Service lies in a period later than current period of the tax book.Date placed in service must be in a prior period.');
                    xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low,
                              p_category => xx_emf_cn_pkg.cn_valid,
                              p_error_text => 'Date Placed in Service lies in a period later than current period of the tax book.',
                              p_record_identifier_1 => p_rcpt_hdr_rec.attribute2 || '-'|| p_rcpt_hdr_rec.attribute3,
                              p_record_identifier_2 => p_rcpt_hdr_rec.asset_number,
                              p_record_identifier_3 => p_rcpt_hdr_rec.book_type_code
                                     );
                 END IF;
               END IF;
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, '~Date Placed in Service Validation=>' || x_error_code);
              RETURN x_error_code;
            END date_placed_in_svc_check;



    ------------------------------------------------------------------------------------------------
    --- Start of the main function perform_batch_validations
    --- This will only have calls to the individual functions.


      BEGIN -- begin of data_validations
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'In start of Data-Validations');
      ------------------------------------------------------------------------------------------
      ------------------------------------------------------------------------------------------
      /*x_error_code_temp := asset_number_valid(p_rcpt_hdr_rec.asset_number
                           ,p_rcpt_hdr_rec.global_attribute20
                                             ,p_rcpt_hdr_rec.book_type_code );*/
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling  Asset error temp' ||x_error_code_temp);
      --x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling  asset error' ||x_error_code);
      --xx_emf_pkg.propagate_error(x_error_code_temp);
          ------------------------------------------------------------------------------------------

      x_error_code_temp := check_book_type_code(p_rcpt_hdr_rec.book_type_code);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling  Asset error temp' ||x_error_code_temp);
        x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling  asset error' ||x_error_code);
      --xx_emf_pkg.propagate_error(x_error_code_temp);
          ------------------------------------------------------------------------------------------
      ------------------------------------------------------------------------------------------
      /*x_error_code_temp := check_deprn_method_code(p_rcpt_hdr_rec.deprn_method_code
                                                  ,p_rcpt_hdr_rec.deprn_method_code
                                                  ,p_rcpt_hdr_rec.prorate_convention_code);*/
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling dept method code' ||x_error_code_temp);
      --x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling dept method code' ||x_error_code);
          --xx_emf_pkg.propagate_error(x_error_code_temp);
          -----------------------------------------------------------------------------------------------
          ------------------------------------------------------------------------------------------
      x_error_code_temp := depreciate_flag(p_rcpt_hdr_rec.depreciate_flag);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling depreciate_flag' ||x_error_code_temp);
      x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling depreciate_flag' ||x_error_code);
          --xx_emf_pkg.propagate_error(x_error_code_temp);
          -----------------------------------------------------------------------------------------------
      x_error_code_temp := date_placed_in_svc_check(p_rcpt_hdr_rec.date_placed_in_service,p_rcpt_hdr_rec.book_type_code);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling depreciate_flag' ||x_error_code_temp);
      x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'after calling depreciate_flag' ||x_error_code);
          --xx_emf_pkg.propagate_error(x_error_code_temp);
          -----------------------------------------------------------------------------------------------

          --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After data validations' ||x_error_code);
        RETURN x_error_code;
      EXCEPTION
      WHEN xx_emf_pkg.g_e_rec_error THEN
        x_error_code := xx_emf_cn_pkg.cn_rec_err;
        RETURN x_error_code;
      WHEN xx_emf_pkg.g_e_prc_error THEN
        x_error_code := xx_emf_cn_pkg.cn_prc_err;
        RETURN x_error_code;
      WHEN OTHERS THEN
        x_error_code := xx_emf_cn_pkg.cn_rec_err;
        RETURN x_error_code;
          END data_validations;


/***********************************************************************************
 This function is used for Post validations for XX_AR_PROFILE_STG table records
 It will validate the record which we passed as an input parameter column by column
 and will return the validation status column by column
 Parameter :
 p_profile_cnv_dtl_rec  --> the record which we need to validate.
*************************************************************************************/
  --**********************************************************************
   --Function to Post Validations .
   --**********************************************************************
   FUNCTION post_validations
               RETURN NUMBER
   IS
          x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
          x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Post-Validations');
     RETURN x_error_code;

   EXCEPTION
   WHEN xx_emf_pkg.g_e_rec_error THEN
     x_error_code := xx_emf_cn_pkg.cn_rec_err;
     RETURN x_error_code;

   WHEN xx_emf_pkg.g_e_prc_error THEN
     x_error_code := xx_emf_cn_pkg.cn_prc_err;
     RETURN x_error_code;

   WHEN others THEN
     x_error_code := xx_emf_cn_pkg.cn_rec_err;
     RETURN x_error_code;

   END post_validations;

--**********************************************************************
  --Function to Data Derivations.
--**********************************************************************

FUNCTION data_derivations(
    p_cnv_pre_std_hdr_rec IN OUT NOCOPY xx_fassets_tax_cnv_pkg.G_XX_FAASST_TAX_PIFACE_REC )
  RETURN NUMBER
IS
  x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
  x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
  x_unique_const    EXCEPTION;
  x_delete          VARCHAR2(15);

BEGIN

    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'In Data Derivation logic section');
    --------------Derivation of Asset Number----------------------------------------------------
    BEGIN

        SELECT fab.asset_number
          INTO p_cnv_pre_std_hdr_rec.asset_number
          FROM fa_additions_b fab
         WHERE fab.attribute2 = p_cnv_pre_std_hdr_rec.attribute2
           AND fab.attribute3 = p_cnv_pre_std_hdr_rec.attribute3;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
             x_error_code := xx_emf_cn_pkg.cn_rec_err;
             xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                              ,p_category   => xx_emf_cn_pkg.cn_valid
                              ,p_error_text => 'No Asset Number found for this legacy asset'
                              ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                              ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                              ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code
                               );

             WHEN TOO_MANY_ROWS THEN
             x_error_code := xx_emf_cn_pkg.cn_rec_err;
             xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                              ,p_category   => xx_emf_cn_pkg.cn_valid
                              ,p_error_text =>'No unique Asset Number  found for this legacy asset'
                              ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                              ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                              ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code
                               );

           WHEN OTHERS THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low
                              ,p_category => xx_emf_cn_pkg.cn_valid
                              ,p_error_text => 'Error in Asset is ' || SUBSTR(sqlerrm,1,200)
                              ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                              ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                              ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code
                                );
           END;
 --------------------------------------------------------------------------------------------
 x_error_code_temp := x_error_code;
 --------------------------------------------------------------------------------------------
 -------------------------Deprn Method Code Derivation---------------------------------------
 --------------------------------------------------------------------------------------------
 BEGIN
   SELECT tag
     INTO p_cnv_pre_std_hdr_rec.deprn_method_code
     FROM fnd_lookup_values
    WHERE upper(lookup_type) = 'DEPRECIATION_METHOD'
      AND LANGUAGE = 'US'
      AND UPPER(lookup_code) = UPPER(p_cnv_pre_std_hdr_rec.deprn_method_code);

 EXCEPTION
 WHEN NO_DATA_FOUND THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                           ,p_category   => xx_emf_cn_pkg.cn_valid
                           ,p_error_text => 'No Depreciation Method Code found for this asset in this tax book'
                           ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                           ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                           ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code);
          WHEN TOO_MANY_ROWS THEN
          x_error_code := xx_emf_cn_pkg.cn_rec_err;
          xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                           ,p_category   => xx_emf_cn_pkg.cn_valid
                           ,p_error_text =>'No unique Depreciation Method Code  found for this legacy asset'
                           ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                           ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                           ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code                            );
        WHEN OTHERS THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low
                           ,p_category => xx_emf_cn_pkg.cn_valid
                           ,p_error_text => 'Error in retrieving Depreciation Method Code is ' || SUBSTR(sqlerrm,1,200)
                           ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                           ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                           ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code                            );
        END ;
 x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
 x_error_code_temp := x_error_code;
  --------------------------------------------------------------------------------------------
  --------------Check already posted records to avoid unique constraint violation-------------
  --------------------------------------------------------------------------------------------
  BEGIN
    SELECT DECODE(posting_status,'ERROR','Y','N')
      INTO x_delete
      FROM fa_tax_interface ft
     WHERE upper(ft.book_type_code) = UPPER(p_cnv_pre_std_hdr_rec.book_type_code)
       AND ft.asset_number = p_cnv_pre_std_hdr_rec.asset_number;

    IF x_delete = 'Y' THEN
       DELETE FROM fa_tax_interface ft
       WHERE upper(ft.book_type_code) = UPPER(p_cnv_pre_std_hdr_rec.book_type_code)
         AND ft.asset_number = p_cnv_pre_std_hdr_rec.asset_number;
    ELSE
        RAISE x_unique_const;
    END IF;

  EXCEPTION
           WHEN NO_DATA_FOUND THEN
                NULL; -- this is required as we should take no action if the record do not exist
           WHEN X_UNIQUE_CONST THEN
           x_error_code := xx_emf_cn_pkg.cn_rec_err;
           xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                            ,p_category   => xx_emf_cn_pkg.cn_valid
                            ,p_error_text =>'This record already processed successfully for this asset in this tax book'
                            ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                            ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                            ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code);

           WHEN TOO_MANY_ROWS THEN
           x_error_code := xx_emf_cn_pkg.cn_rec_err;
           xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                            ,p_category   => xx_emf_cn_pkg.cn_valid
                            ,p_error_text =>'No unique constraint  found on fa_tax_interface table'
                            ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                            ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                            ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code                            );
         WHEN OTHERS THEN
             x_error_code := xx_emf_cn_pkg.cn_rec_err;
             xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low
                            ,p_category => xx_emf_cn_pkg.cn_valid
                            ,p_error_text => 'Error in checking duplicate records in fa_tax_interface ' || SUBSTR(sqlerrm,1,200)
                            ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                            ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.asset_number
                            ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.book_type_code                            );
         END ;
  x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
 x_error_code_temp := x_error_code;
  --------------------------------------------------------------------------------------------
  -------------------------Deprn Method Code and life_in_months Validation--------------------
  --------------------------------------------------------------------------------------------

  BEGIN

      SELECT xx_emf_cn_pkg.cn_success
        INTO x_error_code
        FROM fa_methods fm
       WHERE fm.method_code = p_cnv_pre_std_hdr_rec.deprn_method_code
         AND fm.life_in_months = p_cnv_pre_std_hdr_rec.life_in_months;

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
           x_error_code := xx_emf_cn_pkg.cn_rec_err;
           xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                            ,p_category   => xx_emf_cn_pkg.cn_valid
                            ,p_error_text => 'No Method Code defined for this deprn_method_code and life_in_months in fa_methods'
                            ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                            ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.deprn_method_code
                            ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.life_in_months);
           WHEN TOO_MANY_ROWS THEN
           x_error_code := xx_emf_cn_pkg.cn_rec_err;
           xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low
                            ,p_category   => xx_emf_cn_pkg.cn_valid
                            ,p_error_text =>'No unique Method Code defined for this deprn_method_code and life_in_months in fa_methods'
                            ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                            ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.deprn_method_code
                            ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.life_in_months                            );
         WHEN OTHERS THEN
             x_error_code := xx_emf_cn_pkg.cn_rec_err;
             xx_emf_pkg.error (p_severity => xx_emf_cn_pkg.cn_low
                            ,p_category => xx_emf_cn_pkg.cn_valid
                            ,p_error_text => 'Error in checking Depreciation Method Code  and life_in_months is ' || SUBSTR(sqlerrm,1,200)
                            ,p_record_identifier_1 => p_cnv_pre_std_hdr_rec.attribute2 || '-'|| p_cnv_pre_std_hdr_rec.attribute3
                 	    ,p_record_identifier_2 => p_cnv_pre_std_hdr_rec.deprn_method_code
                            ,p_record_identifier_3 => p_cnv_pre_std_hdr_rec.life_in_months                            );
        END ;

 x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
 RETURN x_error_code;
EXCEPTION
WHEN xx_emf_pkg.g_e_rec_error THEN
  x_error_code := xx_emf_cn_pkg.cn_rec_err;
  RETURN x_error_code;
WHEN xx_emf_pkg.g_e_prc_error THEN
  x_error_code := xx_emf_cn_pkg.cn_prc_err;
  RETURN x_error_code;
WHEN OTHERS THEN
  x_error_code := xx_emf_cn_pkg.cn_rec_err;
  RETURN x_error_code;
END data_derivations;
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
END xx_fassets_tax_val_pkg;
/


GRANT EXECUTE ON APPS.XX_FASSETS_TAX_VAL_PKG TO INTG_XX_NONHR_RO;
