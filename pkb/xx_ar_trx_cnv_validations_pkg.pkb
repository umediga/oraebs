DROP PACKAGE BODY APPS.XX_AR_TRX_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_TRX_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 10-JAN-2012
 File Name     : XXARTRXVAL.pkb
 Description   : This script creates the body of the package
                 xx_ar_trx_cnv_validations_pkg
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 10-JAN-2012   Sharath Babu          Initial Development
 20-MAR-2012   Sharath Babu          Modified to add mapping value function
 27-APR-2012   Sharath Babu          Commented pre-validation for currency
                                     added lang check cond for gl query
 18-MAY-2012   Sharath Babu          Added CASE condition of dist amt check
                                     ,commented gl date validation and modified 
                                     trx type validation query
 27-JUN-2012   Sharath Babu          Modifed Sales Rep mapping logic, Customer Addr
                                     fetch, ship via as per change request
 06-JUL-2012   Sharath Babu          Commented validations for Accounting and Invoicing 
                                     rule validation 
 10-JUL-2012   Sharath Babu          Modified uom_code validation
 12-JUL-2012   Sharath Babu          Commented dist data validation logic to invoke 
                                     autoaccounting
 09-MAY-2013   Sharath Babu          Modified as per Wave1 cust and cust address
 01-OCT-2013   Sharath Babu          Modified customer validation logic as per 11i Wave1
*/
----------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
                   xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

   --Function to perform Pre-validations
   FUNCTION pre_validations (
      p_trx_stg_rec   IN   xx_trx_conversion_pkg.g_xx_ar_cnv_stg_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      -- Check for Customer Open Transactions Not Null Columns
      FUNCTION is_customer_number_null (p_customer_number IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_customer_number IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_customer_number_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Customer Number => '
                                              || p_customer_number
                                              || '-'
                                              || xx_emf_cn_pkg.cn_customer_number_null,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_customer_number  --p_trx_stg_rec.orig_system_bill_customer_ref as per Wave1
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In is_customer_number_null '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_customer_number_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Customer Number => '
                                              || p_customer_number
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_customer_number  --p_trx_stg_rec.orig_system_bill_customer_ref as per Wave1
               );
            RETURN x_error_code;
      END is_customer_number_null;
      
      -- Check for description
      FUNCTION is_description_null (p_description IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_description IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                              || ' - Invalid : Description IS NULL => '
                                              || p_description,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.description
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;
      
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In is_description_null '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                              || ' - Invalid : Description IS NULL => '
                                              || p_description
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.description
               );
            RETURN x_error_code;
      END is_description_null;
      
      -- Check for line type
      FUNCTION is_line_type_null (p_line_type IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_line_type IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                              || ' - Invalid : Line Type IS NULL => '
                                              || p_line_type,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.line_type
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;
      
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In is_line_type_null '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                              || ' - Invalid : Line Type IS NULL => '
                                              || p_line_type
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.line_type
               );
            RETURN x_error_code;
      END is_line_type_null;

      FUNCTION is_cust_trx_type_null (p_cust_trx_type IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_cust_trx_type IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_cust_trx_type_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Cust Trx type Name => '
                                              || p_cust_trx_type
                                              || '-'
                                              || xx_emf_cn_pkg.cn_cust_trx_null,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.cust_trx_type_name
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In is_cust_trx_type_null '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_cust_trx_type_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Cust Trx type Name => '
                                              || p_cust_trx_type
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.cust_trx_type_name
               );
            RETURN x_error_code;
      END is_cust_trx_type_null;

      FUNCTION is_iface_line_context_null (p_iface_line_context IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_iface_line_context IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_iface_line_context_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid IFace Line Context => '
                                              || p_iface_line_context
                                              || '-'
                                              || xx_emf_cn_pkg.cn_iface_line_context_null,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.interface_line_context
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In is_iface_line_context_null '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_iface_line_context_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid IFace Line Context => '
                                              || p_iface_line_context
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.interface_line_context
               );
            RETURN x_error_code;
      END is_iface_line_context_null;

      --
      FUNCTION is_iface_line_attribute1_null (
         p_iface_line_attribute1   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
      BEGIN
         IF p_iface_line_attribute1 IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_iface_line_attribute1_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid IFace Line Attribute1 => '
                                              || p_iface_line_attribute1
                                              || '-'
                                              || xx_emf_cn_pkg.cn_iface_line_attribute1_null,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.interface_line_attribute1
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Errors In is_iface_line_attribute1_null '
                                || SQLCODE
                               );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_iface_line_attribute1_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid IFace Line Attribute1 => '
                                              || p_iface_line_attribute1
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.interface_line_attribute1
               );
            RETURN x_error_code;
      END is_iface_line_attribute1_null;
      
      FUNCTION is_iface_line_attribute2_null (
               p_iface_line_attribute2   IN   VARCHAR2
            )
               RETURN NUMBER
            IS
            BEGIN
               IF p_iface_line_attribute2 IS NULL
               THEN
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_iface_line_attribute2_valid,
                      p_error_text               =>    p_trx_stg_rec.trx_number
                                                    || ' - Invalid IFace Line attribute2 => '
                                                    || p_iface_line_attribute2
                                                    || '-'
                                                    || xx_emf_cn_pkg.cn_iface_line_attribute2_null,
                      p_record_identifier_1      => p_trx_stg_rec.record_number,
                      p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute2,
                      p_record_identifier_3      => p_trx_stg_rec.interface_line_attribute2
                     );
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
               END IF;
      
               RETURN x_error_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.write_log
                                     (xx_emf_cn_pkg.cn_low,
                                         'Errors In is_iface_line_attribute2_null '
                                      || SQLCODE
                                     );
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_iface_line_attribute2_valid,
                      p_error_text               =>    p_trx_stg_rec.trx_number
                                                    || ' - Invalid IFace Line attribute2 => '
                                                    || p_iface_line_attribute2
                                                    || '-'
                                                    || SQLERRM,
                      p_record_identifier_1      => p_trx_stg_rec.record_number,
                      p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute2,
                      p_record_identifier_3      => p_trx_stg_rec.interface_line_attribute2
                     );
                  RETURN x_error_code;
      END is_iface_line_attribute2_null;

      FUNCTION is_currency_code_null (p_currency_code IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_currency_code IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_currency_code_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Currency Code => '
                                              || p_currency_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_currency_code_null,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.currency_code
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In is_currency_code_null '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_currency_code_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Currency Code => '
                                              || p_currency_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.currency_code
               );
            RETURN x_error_code;
      END is_currency_code_null;

      ---
      FUNCTION is_batch_source_name_null (p_batch_source_name IN VARCHAR2)
         RETURN NUMBER
      IS
      BEGIN
         IF p_batch_source_name IS NULL
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Batch Source Name => '
                                              || p_batch_source_name
                                              || '-'
                                              || 'Batch Source Name is NULL',
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.batch_source_name
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In is_batch_source_name_null '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Batch Source Name => '
                                              || p_batch_source_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.batch_source_name
               );
            RETURN x_error_code;
      END is_batch_source_name_null;

      ---
      FUNCTION is_term_name_null (p_term_name IN VARCHAR2)
         RETURN NUMBER
      IS
         x_cm_flag VARCHAR2(10);
      BEGIN
         --Added for Credit Memo check as per Wave1
         x_cm_flag := 'N';
         BEGIN
            SELECT 'Y'
              INTO x_cm_flag	    
              FROM ra_cust_trx_types_all rctt
              WHERE UPPER (rctt.NAME) = UPPER (p_trx_stg_rec.cust_trx_type_name) 	                
                AND TRUNC(SYSDATE) >= TRUNC(NVL(rctt.start_date, SYSDATE))
                AND TRUNC(SYSDATE) <= TRUNC(NVL(rctt.end_date, SYSDATE + 1))
                AND rctt.type = 'CM'
                AND ROWNUM = 1;
         EXCEPTION 
            WHEN OTHERS THEN
               x_cm_flag := 'N';
         END;
         IF p_term_name IS NULL AND x_cm_flag <> 'Y'
         THEN
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_term_name_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Term Name => '
                                              || p_term_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_term_name_null,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.term_name
               );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In is_term_name_null ' || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_term_name_valid,
                p_error_text               =>    p_trx_stg_rec.trx_number
                                              || ' - Invalid Term Name => '
                                              || p_term_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trx_stg_rec.record_number,
                p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trx_stg_rec.term_name
               );
            RETURN x_error_code;
      END is_term_name_null;
      
   -- Start of the main function pre_validations_customer_hdr
   -- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Inside PRE-Validations');
      
      x_error_code_temp :=
         is_customer_number_null (p_trx_stg_rec.orig_system_bill_customer_ref);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      
      x_error_code_temp :=
               is_description_null (p_trx_stg_rec.description);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      
      x_error_code_temp :=
                     is_line_type_null (p_trx_stg_rec.line_type);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      
      x_error_code_temp :=
                     is_cust_trx_type_null (p_trx_stg_rec.cust_trx_type_name);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      --Commented as per Wave2
      /*x_error_code_temp :=
            is_iface_line_context_null (p_trx_stg_rec.interface_line_context);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      
      x_error_code_temp :=
         is_iface_line_attribute1_null
                                     (p_trx_stg_rec.interface_line_attribute1);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      
      x_error_code_temp :=
               is_iface_line_attribute2_null
                                           (p_trx_stg_rec.interface_line_attribute2);
      x_error_code := find_max (x_error_code, x_error_code_temp);*/
      
      /*x_error_code_temp :=
                          is_currency_code_null (p_trx_stg_rec.currency_code);
      x_error_code := find_max (x_error_code, x_error_code_temp);*/
      
      x_error_code_temp :=
                  is_batch_source_name_null (p_trx_stg_rec.batch_source_name);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      
      --IF p_trx_stg_rec.cust_trx_type_name <> 'Credit Memo' THEN     --Added for Credit memo  Commented if as per Wave1
         x_error_code_temp :=
                           is_term_name_null (p_trx_stg_rec.term_name);
         x_error_code := find_max (x_error_code, x_error_code_temp);
      --END IF;
      
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After PRE-Validations x_error_code= '
                            || x_error_code
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
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

/***********************************************************************************
 This function is used for Data validations for Pre interface table records
 It will validate the record which we passed as an input parameter column by column
 and will return the validation status column by column
 Parameter :
 p_trxcnv_preiface_rec  --> the record which we need to validate.
*************************************************************************************/
   FUNCTION data_validations (
      p_trxcnv_preiface_rec   IN OUT   xx_trx_conversion_pkg.g_xx_ar_cnv_pre_std_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER        := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER        := xx_emf_cn_pkg.cn_success;
      x_operating_unit    VARCHAR2 (50);
      x_org_id            NUMBER;

      --- Local functions for all batch level validations
      --- Add as many functions as required in her
      --- Added by Sunil
      FUNCTION is_curr_code_valid (p_curr_code IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_cur_code     VARCHAR2 (10);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Currency Code Validation ' || p_curr_code
                              );

         SELECT currency_code
           INTO x_cur_code
           FROM fnd_currencies fc
          WHERE UPPER (fc.currency_code) = UPPER (p_curr_code)
            AND fc.enabled_flag = 'Y'
            AND TRUNC (SYSDATE) >= TRUNC (NVL (start_date_active, SYSDATE))
            AND TRUNC (SYSDATE) <= TRUNC (NVL (end_date_active, SYSDATE + 1));

         p_curr_code := x_cur_code;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_curr_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Currency Code => '
                                              || p_curr_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.currency_code
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_curr_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Currency Code => '
                                              || p_curr_code
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.currency_code
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Currency Code Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_curr_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Currency Code => '
                                              || p_curr_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.currency_code
               );
            RETURN x_error_code;
      END is_curr_code_valid;

      FUNCTION is_operating_unit_valid (
         p_operating_unit_name   IN OUT VARCHAR2,
         p_org_id                IN     NUMBER         
      )
         RETURN NUMBER
      IS
         x_error_code       NUMBER        := xx_emf_cn_pkg.cn_success;         
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Validations for Operating Unit Name'
                              );

         IF p_org_id IS NOT NULL
         THEN            

            SELECT name
              INTO p_operating_unit_name
              FROM hr_operating_units
             WHERE organization_id = p_org_id;
                       
         ELSE
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || '- Invalid : Operating Unit IS NULL => ',
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.org_id
               );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Operating Unit Name => '
                                              || p_operating_unit_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.operating_unit_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Operating Unit Name => '
                                              || p_operating_unit_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.operating_unit_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Errors In Operating Unit Name Validation '
                               || SQLCODE
                              );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Operating Unit Name => '
                                              || p_operating_unit_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.operating_unit_name
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'X_ERROR_CODE Operating Unit Name: '
                                  || x_error_code
                                 );
            RETURN x_error_code;
      END is_operating_unit_valid;

      FUNCTION is_cust_trx_type_valid (
         p_operating_unit_name   IN       VARCHAR2,
         p_cust_trx_type         IN OUT   VARCHAR2,
         p_cust_trx_type_id      OUT      NUMBER,
         p_org_id                IN       NUMBER         
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER         := xx_emf_cn_pkg.cn_success;
         x_cust_trx_type   VARCHAR2 (100);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Deriving Cust TRX TYPE for : '
                               || p_cust_trx_type
                              );
         x_cust_trx_type :=
            xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'CUST_TRX_TYPE'                                                                                               
                                                  ,p_old_value1 => p_cust_trx_type
                                                  ,p_old_value2 => p_operating_unit_name
                                                  ,p_date_effective => SYSDATE
                                                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'derived value of  x_cust_trx_type'
                               || x_cust_trx_type
                              );

         SELECT NAME, cust_trx_type_id
           INTO p_cust_trx_type, p_cust_trx_type_id
           FROM ra_cust_trx_types_all rctt
          WHERE UPPER (rctt.NAME) = UPPER (x_cust_trx_type) 
            --AND rctt.status = 'A'
            AND TRUNC(SYSDATE) >= TRUNC(NVL(rctt.start_date, SYSDATE))
            AND TRUNC(SYSDATE) <= TRUNC(NVL(rctt.end_date, SYSDATE + 1))
            AND rctt.org_id = p_org_id;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_cust_trx_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Cust Trx Type => '
                                              || p_cust_trx_type
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.cust_trx_type_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_cust_trx_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Cust Trx Type => '
                                              || p_cust_trx_type
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.cust_trx_type_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Cust Trx Type Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_cust_trx_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Cust Trx Type => '
                                              || p_cust_trx_type
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.cust_trx_type_name
               );
            RETURN x_error_code;
      END is_cust_trx_type_valid;

      FUNCTION is_term_name_valid (
         p_term_name             IN OUT   VARCHAR2,
         p_term_id               OUT      NUMBER         
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_term_name    VARCHAR2 (50);
      BEGIN
         x_term_name :=
            xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'PAYMENT_TERM'                                                                                               
                                                  ,p_old_value1 => p_term_name
                                                  ,p_old_value2 => 'AR'
                                                  ,p_date_effective => SYSDATE
                                                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Derived Term Name = ' || x_term_name
                              );

         BEGIN
            IF p_term_name IS NOT NULL
            THEN
               SELECT rt.NAME, rt.term_id
                 INTO p_term_name, p_term_id
                 FROM ra_terms rt
                WHERE UPPER (rt.NAME) = UPPER (x_term_name)  
                  AND TRUNC (SYSDATE) >=
                                   TRUNC (NVL (rt.start_date_active, SYSDATE))
                  AND TRUNC (SYSDATE) <=
                                 TRUNC (NVL (rt.end_date_active, SYSDATE + 1));
            ELSE
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_term_name_nexist,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Term Name Is NULL ',
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.term_name
                  );
            END IF;

            RETURN x_error_code;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLCODE TOOMANY ' || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_term_name_valid,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Term Name => '
                                                 || p_term_name
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_too_many,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.term_name
                  );
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLCODE NODATA ' || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_term_name_valid,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Term Name => '
                                                 || p_term_name
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_no_data,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.term_name
                  );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Errors In Term Name Validation '
                                     || SQLCODE
                                    );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_term_name_valid,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Term Name => '
                                                 || p_term_name
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.term_name
                  );
               RETURN x_error_code;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_term_name_valid,
                p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.term_name
               );
            RETURN x_error_code;
      END is_term_name_valid;

      FUNCTION is_customer_number_valid (
         p_customer_number   IN       VARCHAR2,
         p_customer_id       OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'p_Customer_Number =' || p_customer_number
                              );

         SELECT DISTINCT hzcust.cust_account_id
                    INTO p_customer_id
                    FROM apps.hz_cust_accounts hzcust
                   WHERE hzcust.orig_system_reference = p_customer_number
                     AND ROWNUM = 1;

         xx_emf_pkg.write_log
               (xx_emf_cn_pkg.cn_low,
                   ' after the validation of Customer Number p_customer_id = '
                || p_customer_id
               );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_customer_number_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Number => '
                                              || p_customer_number
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_customer_number  --p_trxcnv_preiface_rec.orig_system_bill_customer_ref As per Wave1
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN   --Added as per 11i Wave1 01-OCT-13
            BEGIN
               SELECT hzcust.cust_account_id
	         INTO p_customer_id
	         FROM apps.hz_cust_accounts hzcust
                WHERE hzcust.account_number = p_customer_number
                  AND ROWNUM = 1;
               
               RETURN x_error_code;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN                 
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_customer_number_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Number => '
                                              || p_customer_number
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_customer_number  --p_trxcnv_preiface_rec.orig_system_bill_customer_ref As per Wave1
               );
               RETURN x_error_code;
            WHEN OTHERS
	    THEN
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_customer_number_valid,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Customer Number => '
                                                 || p_customer_number
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_customer_number --p_trxcnv_preiface_rec.orig_system_bill_customer_ref As per Wave1
                  );
               RETURN x_error_code;
            END;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Customer Number Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_customer_number_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Number => '
                                              || p_customer_number
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_customer_number --p_trxcnv_preiface_rec.orig_system_bill_customer_ref As per Wave1
               );
            RETURN x_error_code;
      END is_customer_number_valid;

      FUNCTION is_accrule_name_valid (
         p_accrule_name   IN OUT   VARCHAR2,
         p_accrule_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code     NUMBER        := xx_emf_cn_pkg.cn_success;
         x_accrule_name   VARCHAR2 (40);
      BEGIN
         IF p_accrule_name IS NOT NULL
         THEN
            SELECT accrule.NAME, rule_id
              INTO x_accrule_name, p_accrule_id
              FROM ra_rules accrule
             WHERE UPPER (accrule.NAME) = UPPER (p_accrule_name)
               AND accrule.status = 'A';
         END IF;

         p_accrule_name := x_accrule_name;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_acctrule_nam_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Accounting Rule Name => '
                                              || p_accrule_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.accounting_rule_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_acctrule_nam_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Accounting Rule Name => '
                                              || p_accrule_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.accounting_rule_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'Errors In Accounting Rule Name Validation '
                              || SQLCODE
                             );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_acctrule_nam_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Accounting Rule Name => '
                                              || p_accrule_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.accounting_rule_name
               );
            RETURN x_error_code;
      END is_accrule_name_valid;

      FUNCTION is_invrule_name_valid (
         p_invrule_name   IN OUT   VARCHAR2,
         p_invrule_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code     NUMBER        := xx_emf_cn_pkg.cn_success;
         x_invrule_name   VARCHAR2 (40);
      BEGIN
         IF p_invrule_name IS NOT NULL
         THEN
            SELECT invrule.NAME, rule_id
              INTO x_invrule_name, p_invrule_id
              FROM ra_rules invrule
             WHERE UPPER (invrule.NAME) = UPPER (p_invrule_name)
               AND invrule.status = 'A';
         END IF;

         p_invrule_name := x_invrule_name;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_invrule_nam_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Invoice Rule Name => '
                                              || p_invrule_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.invoicing_rule_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_invrule_nam_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Invoice Rule Name => '
                                              || p_invrule_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.invoicing_rule_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'Errors In Invoice Rule Name Validation '
                                 || SQLCODE
                                );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_invrule_nam_valid,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Invoice Rule Name => '
                                              || p_invrule_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.invoicing_rule_name
               );
            RETURN x_error_code;
      END is_invrule_name_valid;

      --Function validate line type
      FUNCTION is_line_type_valid (p_line_type IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (20);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Line type Validation ' || p_line_type
                              );
         p_line_type := UPPER (p_line_type);

         SELECT 'X'
           INTO x_variable
           FROM DUAL
          WHERE p_line_type IN ('LINE', 'TAX', 'FREIGHT', 'CHARGES');

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Line Type => '
                                              || p_line_type
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.line_type
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Line Type => '
                                              || p_line_type
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.line_type
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In Line Type Validation ' || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Line Type => '
                                              || p_line_type
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.line_type
               );
            RETURN x_error_code;
      END is_line_type_valid;

      --Function to check batch source name validation 
      FUNCTION is_batch_source_valid (
         p_batch_source_name   IN OUT   VARCHAR2,
         p_org_id              IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code     NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bsource_name   VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Batch Source Name Validation '
                               || p_batch_source_name
                              );

         SELECT name, org_id
           INTO x_bsource_name, p_org_id
           FROM ra_batch_sources_all
          WHERE UPPER (NAME) = UPPER (p_batch_source_name)            
            AND status = 'A'
            AND TRUNC (SYSDATE) >= TRUNC (NVL (start_date, SYSDATE))
            AND TRUNC (SYSDATE) <= TRUNC (NVL (end_date, SYSDATE + 1));

         p_batch_source_name := x_bsource_name;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Batch Source Name => '
                                              || p_batch_source_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.batch_source_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Batch Source Name => '
                                              || p_batch_source_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.batch_source_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'Errors In Batch Source Name Validation '
                                 || SQLCODE
                                );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Batch Source Name => '
                                              || p_batch_source_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.batch_source_name
               );
            RETURN x_error_code;
      END is_batch_source_valid;

      --Function to validate bill and ship to address
      FUNCTION is_cust_address_valid (
         p_org_id          IN       NUMBER,
         p_cust_ref        IN       NUMBER,  --VARCHAR2,  --Modified as per 11i Wave1 01-OCT-13
         p_addr_ref        IN       VARCHAR2,
         p_cust_addr_id    OUT      NUMBER,
         p_site_use_code   IN       VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_site_use_code = 'BILL_TO'
         THEN
            --Modified as per Wave1
            --Modified query to use the original system reference of the account as per change request
            SELECT DISTINCT hzsites.cust_acct_site_id
                       INTO p_cust_addr_id
                       FROM apps.hz_cust_accounts hzcust,
                            apps.hz_cust_acct_sites_all hzsites,
                            apps.hz_cust_site_uses_all hzsitesu,
                            apps.hz_party_sites hps
                      WHERE hzcust.cust_account_id = hzsites.cust_account_id
                        AND hzsites.cust_acct_site_id =
                                                    hzsitesu.cust_acct_site_id
                        AND hzsites.org_id = p_org_id
                        --AND hzcust.orig_system_reference = p_cust_ref  --Modified as per 11i Wave1 01-OCT-13
                        AND hzcust.cust_account_id = p_cust_ref
                        AND hzsites.party_site_id = hps.party_site_id
                        --AND hps.orig_system_reference = p_addr_ref
                        --AND hzsites.orig_system_reference = p_addr_ref  
                        --and   hzsitesu.location          = substr(p_addr_ref,1,decode(sign(lengthb(p_addr_ref)-40),1,38,lengthb(p_addr_ref)))
                        AND hzsitesu.orig_system_reference = p_addr_ref
                        AND hzsitesu.site_use_code = 'BILL_TO'
                        AND ROWNUM < 2;
         ELSIF p_site_use_code = 'SHIP_TO'
         THEN
            --Modified as per Wave1
            --Modified query to use the original system reference of the account as per change request
            SELECT DISTINCT hzsites.cust_acct_site_id
                       INTO p_cust_addr_id
                       FROM apps.hz_cust_accounts hzcust,
                            apps.hz_cust_acct_sites_all hzsites,
                            apps.hz_cust_site_uses_all hzsitesu,
                            apps.hz_party_sites hps
                      WHERE hzcust.cust_account_id = hzsites.cust_account_id
                        AND hzsites.cust_acct_site_id =
                                                    hzsitesu.cust_acct_site_id
                        AND hzsites.org_id = p_org_id
                        --AND hzcust.orig_system_reference = p_cust_ref  --Modified as per 11i Wave1 01-OCT-13
                        AND hzcust.cust_account_id = p_cust_ref
                        AND hzsites.party_site_id = hps.party_site_id
                        --AND hps.orig_system_reference = p_addr_ref
                        --AND hzsites.orig_system_reference = p_addr_ref
                        --and   hzsitesu.location          = substr(p_addr_ref,1,decode(sign(lengthb(p_addr_ref)-40),1,38,lengthb(p_addr_ref)))
                        AND hzsitesu.orig_system_reference = p_addr_ref
                        AND hzsitesu.site_use_code = 'SHIP_TO'
                        AND ROWNUM < 2;
         END IF;

         xx_emf_pkg.write_log
             (xx_emf_cn_pkg.cn_low,
                 ' after the validation of Customer Address p_cust_addr_id = '
              || p_cust_addr_id
             );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Address => '
                                              || p_site_use_code
                                              || '-'
                                              || p_addr_ref
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_addr_ref
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Address => '
                                              || p_site_use_code
                                              || '-'
                                              || p_addr_ref
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_addr_ref
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Customer Address Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Address => '
                                              || p_site_use_code
                                              || '-'
                                              || p_addr_ref
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_addr_ref
               );
            RETURN x_error_code;
      END is_cust_address_valid;

      --Function to validate bill and ship to contact
      FUNCTION is_customer_contact_valid (
         p_org_id            IN       NUMBER,
         p_cust_ref          IN       VARCHAR2,
         p_addr_ref          IN       VARCHAR2,
         p_contact_ref       IN       VARCHAR2,
         p_cust_contact_id   OUT      NUMBER,
         p_site_use_code     IN       VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         IF p_site_use_code = 'BILL_TO'
         THEN
            SELECT DISTINCT hcar.cust_account_role_id
                       INTO p_cust_contact_id
                       FROM apps.hz_cust_accounts hzcust,
                            apps.hz_cust_acct_sites_all hzsites,
                            apps.hz_cust_site_uses_all hzsitesu,
                            apps.hz_party_sites hps,
                            apps.hz_cust_account_roles hcar
                      WHERE hzcust.cust_account_id = hzsites.cust_account_id
                        AND hzsites.cust_acct_site_id =
                                                    hzsitesu.cust_acct_site_id
                        AND hzcust.cust_account_id = hcar.cust_account_id
                        AND hzsites.cust_acct_site_id = hcar.cust_acct_site_id
                        AND hcar.role_type = 'CONTACT'
                        AND hcar.current_role_state = 'A'
                        AND hcar.status = 'A'
                        AND hcar.orig_system_reference = p_contact_ref
                        AND hzsites.org_id = p_org_id
                        AND hzcust.orig_system_reference = p_cust_ref
                        AND hzsites.party_site_id = hps.party_site_id
                        AND hzsites.orig_system_reference = p_addr_ref
                        --AND hps.orig_system_reference = p_addr_ref
                        AND site_use_code = 'BILL_TO';
         ELSIF p_site_use_code = 'SHIP_TO'
         THEN
            SELECT DISTINCT hcar.cust_account_role_id
                       INTO p_cust_contact_id
                       FROM apps.hz_cust_accounts hzcust,
                            apps.hz_cust_acct_sites_all hzsites,
                            apps.hz_cust_site_uses_all hzsitesu,
                            apps.hz_party_sites hps,
                            apps.hz_cust_account_roles hcar
                      WHERE hzcust.cust_account_id = hzsites.cust_account_id
                        AND hzsites.cust_acct_site_id =
                                                    hzsitesu.cust_acct_site_id
                        AND hzcust.cust_account_id = hcar.cust_account_id
                        AND hzsites.cust_acct_site_id = hcar.cust_acct_site_id
                        AND hcar.role_type = 'CONTACT'
                        AND hcar.current_role_state = 'A'
                        AND hcar.status = 'A'
                        AND hcar.orig_system_reference = p_contact_ref
                        AND hzsites.org_id = p_org_id
                        AND hzcust.orig_system_reference = p_cust_ref
                        AND hzsites.party_site_id = hps.party_site_id
                        AND hzsites.orig_system_reference = p_addr_ref
                        --AND hps.orig_system_reference = p_addr_ref
                        AND site_use_code = 'SHIP_TO';
         END IF;

         xx_emf_pkg.write_log
            (xx_emf_cn_pkg.cn_low,
                ' after the validation of Customer Contact p_cust_contact_id= '
             || p_cust_contact_id
            );
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Contact => '
                                              || p_site_use_code
                                              || '-'
                                              || p_contact_ref
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_contact_ref
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Contact => '
                                              || p_site_use_code
                                              || '-'
                                              || p_contact_ref
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_contact_ref
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Customer Address Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Customer Contact => '
                                              || p_site_use_code
                                              || '-'
                                              || p_contact_ref
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_contact_ref
               );
            RETURN x_error_code;
      END is_customer_contact_valid;

      FUNCTION is_receipt_method_valid (
         p_receipt_method_name   IN OUT   VARCHAR2,
         p_receipt_method_id     OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code       NUMBER        := xx_emf_cn_pkg.cn_success;
         x_receipt_method   VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Receipt Method Name Validation '
                               || p_receipt_method_name
                              );

         SELECT NAME, receipt_method_id
           INTO x_receipt_method, p_receipt_method_id
           FROM ar_receipt_methods
          WHERE UPPER (NAME) = UPPER (x_receipt_method)
            AND TRUNC (SYSDATE) BETWEEN TRUNC (start_date)
                                    AND TRUNC (NVL (end_date, SYSDATE + 1));

         p_receipt_method_name := x_receipt_method;
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Receipt Method Name => '
                                              || p_receipt_method_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.receipt_method_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Receipt Method Name => '
                                              || p_receipt_method_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.receipt_method_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                              (xx_emf_cn_pkg.cn_low,
                                  'Errors In Receipt Method Name Validation '
                               || SQLCODE
                              );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Receipt Method Name => '
                                              || p_receipt_method_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.receipt_method_name
               );
            RETURN x_error_code;
      END is_receipt_method_valid;

      FUNCTION is_gl_date_valid (
         p_gl_date               IN   DATE,
         p_operating_unit_name   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (40);
         x_sob_id       NUMBER;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Getting sob ID for ' || p_operating_unit_name
                              );

         BEGIN
            SELECT set_of_books_id
              INTO x_sob_id
              FROM hr_operating_units
             WHERE NAME = p_operating_unit_name;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               => 'Invalid : Error while fetching set_of_books_id inside GL Date Validation => ',
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.gl_date
                  );
         END;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'x_sob_id = ' || x_sob_id);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'GL Date Validation ' || p_gl_date
                              );

         SELECT 'X'
           INTO x_variable
           FROM gl.gl_period_statuses gs, apps.fnd_application_tl fa
          WHERE fa.application_id = gs.application_id
            AND fa.application_name IN ('Receivables')
            AND gs.set_of_books_id = x_sob_id
            AND fa.language = USERENV('LANG')
            AND TRUNC (p_gl_date) BETWEEN TRUNC (gs.start_date)
                                      AND TRUNC (NVL (gs.end_date, SYSDATE))
            AND gs.closing_status = 'O';

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid GL Date => '
                                              || p_gl_date
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.gl_date
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid GL Date => '
                                              || p_gl_date
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.gl_date
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In GL Date Validation ' || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid GL Date => '
                                              || p_gl_date
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.gl_date
               );
            RETURN x_error_code;
      END is_gl_date_valid;

      FUNCTION is_sales_rep_valid (
         p_sales_rep_num         IN    VARCHAR2,
         p_salesrep_id           IN OUT   NUMBER,
         --p_legacy_system         IN       VARCHAR2,
         --p_operating_unit_name   IN       VARCHAR2,
         p_org_id                IN       NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code     NUMBER        := xx_emf_cn_pkg.cn_success;
         x_salesrep_num   VARCHAR2(30);         
      BEGIN
         --Added check for mapping value as per Change Request
         x_salesrep_num :=
            xx_intg_common_pkg.get_mapping_value (p_mapping_type => 'SALESREP_NUM',
                                                  p_old_value => p_sales_rep_num,
                                                  p_date_effective => SYSDATE
                                                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'derived value of  x_salesrep_num'
                               || x_salesrep_num
                              );  
                              
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Sales Rep Validation ' || p_sales_rep_num
                                 );

            SELECT salesrep_id
              INTO p_salesrep_id
              FROM jtf_rs_salesreps
             WHERE 1 = 1
               AND salesrep_number = x_salesrep_num  --p_sales_rep_num 
               AND org_id = p_org_id
               AND status = 'A'
               AND TRUNC (SYSDATE) >= TRUNC (NVL (start_date_active, SYSDATE))
               AND TRUNC (SYSDATE) <=
                                    TRUNC (NVL (end_date_active, SYSDATE + 1));
         
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLCODE TOOMANY ' || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Salesrep Number => '
                                                 || x_salesrep_num
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_too_many,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.primary_salesrep_number
                  );
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLCODE NODATA ' || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Salesrep Number => '
                                                 || x_salesrep_num
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_no_data,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.primary_salesrep_number
                  );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log
                                  (xx_emf_cn_pkg.cn_low,
                                      'Errors In Salesrep Number Validation '
                                   || SQLCODE
                                  );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Salesrep Number => '
                                                 || x_salesrep_num
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.primary_salesrep_number
                  );
               RETURN x_error_code;
         END;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               => xx_emf_cn_pkg.cn_exp_unhand,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.primary_salesrep_number
               );
            RETURN x_error_code;
      END is_sales_rep_valid;

      FUNCTION is_interface_dist_exits (
         p_int_line_ctxt    IN   VARCHAR2,
         p_int_line_attr1   IN   VARCHAR2,
         p_int_line_attr2   IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (10);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Check for Distribution line ' || p_int_line_attr2
                              );

         SELECT 'X'
           INTO x_variable
           FROM xx_ar_inv_trx_dist_stg
          WHERE interface_line_attribute1 = p_int_line_attr1
            AND interface_line_attribute2 = p_int_line_attr2
            AND interface_line_context = p_int_line_ctxt
            AND batch_id = p_trxcnv_preiface_rec.batch_id;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_success;
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid : Distribution Line Check => '
                                              || p_int_line_attr2
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_context
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Distribution Line Check '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid : Distribution Line Check => '
                                              || p_int_line_attr2
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_context
               );
            RETURN x_error_code;
      END is_interface_dist_exits;

      FUNCTION is_line_dist_amount_valid (
         p_int_line_ctxt    IN   VARCHAR2,
         p_int_line_attr1   IN   VARCHAR2,
         p_int_line_attr2   IN   VARCHAR2,
         p_trx_type         IN   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code     NUMBER := xx_emf_cn_pkg.cn_success;
         l_rec_amount     NUMBER;
         l_dist_amt_sum   NUMBER;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Trx Line Distribution Amount Validation '
                               || p_int_line_attr2
                              );

         BEGIN  
            IF p_trx_type = 'Credit Memo' THEN
               SELECT CASE WHEN NVL (amount, 0) < 0 
                           THEN NVL (amount, 0)*-1 
                           ELSE NVL (amount, 0) 
                       END rec_amount
                 INTO l_rec_amount
                 FROM xx_ar_inv_trx_dist_stg
                WHERE interface_line_attribute1 = p_int_line_attr1
                  AND interface_line_attribute2 = p_int_line_attr2
                  AND interface_line_context = p_int_line_ctxt
                  AND account_class = 'REC'
                  AND batch_id = p_trxcnv_preiface_rec.batch_id;
            ELSE
               SELECT NVL (amount, 0)
	         INTO l_rec_amount
	         FROM xx_ar_inv_trx_dist_stg
	        WHERE interface_line_attribute1 = p_int_line_attr1
	          AND interface_line_attribute2 = p_int_line_attr2
	          AND interface_line_context = p_int_line_ctxt
                  AND account_class = 'REC'
                  AND batch_id = p_trxcnv_preiface_rec.batch_id;
            END IF;
            IF p_trx_type = 'Credit Memo' THEN
               SELECT CASE WHEN NVL (amount, 0) < 0 
                           THEN NVL (amount, 0)*-1 
                           ELSE NVL (amount, 0) 
                       END rec_amount
                 INTO l_dist_amt_sum
                 FROM xx_ar_inv_trx_dist_stg
                WHERE interface_line_attribute1 = p_int_line_attr1
                  AND interface_line_attribute2 = p_int_line_attr2
                  AND interface_line_context = p_int_line_ctxt
                  AND account_class IN ('REV', 'TAX', 'FREIGHT')
                  AND batch_id = p_trxcnv_preiface_rec.batch_id;
            ELSE
               SELECT NVL (amount, 0)
                 INTO l_dist_amt_sum
                 FROM xx_ar_inv_trx_dist_stg
                WHERE interface_line_attribute1 = p_int_line_attr1
                  AND interface_line_attribute2 = p_int_line_attr2
                  AND interface_line_context = p_int_line_ctxt
                  AND account_class IN ('REV', 'TAX', 'FREIGHT')
                  AND batch_id = p_trxcnv_preiface_rec.batch_id;               
            END IF;
               
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLCODE TOOMANY ' || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Distributions => '
                                                 || p_int_line_attr2
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_too_many,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_context
                  );
               RETURN x_error_code;
            WHEN NO_DATA_FOUND
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'SQLCODE NODATA ' || SQLCODE
                                    );
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Distributions => '
                                                 || p_int_line_attr2
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_no_data,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_context
                  );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Errors In Distributions Validation '
                                     || SQLCODE
                                    );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                                 || ' - Invalid Distributions => '
                                                 || p_int_line_attr2
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                   p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_context
                  );
               RETURN x_error_code;
         END;

         IF l_rec_amount <> l_dist_amt_sum
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               => '- Invalid : Total of line distributions not equal to REC line amount => ',
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_context
               );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'Errors In Distributions Validation exception'
                            || SQLCODE
                           );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid Distributions => '
                                              || p_int_line_attr2
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_context
               );
            RETURN x_error_code;
      END is_line_dist_amount_valid;

      FUNCTION is_mtl_item_seg1_valid (
         p_mtl_item_seg1         IN OUT   VARCHAR2,
         p_inv_item_id           IN OUT   NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER         := xx_emf_cn_pkg.cn_success;         
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Validating MTL_SYSTEM_ITEMS_SEG1 for : '
                               || p_mtl_item_seg1
                              );

         SELECT DISTINCT segment1, inventory_item_id
                    INTO p_mtl_item_seg1, p_inv_item_id
                    FROM mtl_system_items_b
                   WHERE UPPER (segment1) = UPPER (p_mtl_item_seg1)  
                     AND enabled_flag = 'Y';

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid MTL_SYSTEM_ITEMS_SEG1 => '
                                              || p_mtl_item_seg1
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.mtl_system_items_seg1
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid MTL_SYSTEM_ITEMS_SEG1 => '
                                              || p_mtl_item_seg1
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.mtl_system_items_seg1
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'Errors In MTL_SYSTEM_ITEMS_SEG1 Validation '
                             || SQLCODE
                            );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid MTL_SYSTEM_ITEMS_SEG1 => '
                                              || p_mtl_item_seg1
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.mtl_system_items_seg1
               );
            RETURN x_error_code;
      END is_mtl_item_seg1_valid;

      FUNCTION is_uom_code_valid (         
         p_inv_item_id           IN    NUMBER
        ,p_uom_code              OUT   VARCHAR2 
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         --x_uom_name     VARCHAR2 (25);
         --x_variable     VARCHAR2(10);
      BEGIN                                 
         --IF p_uom_code IS NOT NULL THEN
            /*x_uom_name :=
	                  xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'UOM_NAME'                                                  
	                                                        ,p_old_value => p_uom_code                                                  
	                                                        ,p_date_effective => SYSDATE
	                                                       );
	               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	                                     'derived value of  x_uom_name: ' || x_uom_name
                             );  
            SELECT DISTINCT uom_code
              INTO p_uom_code
	        FROM mtl_units_of_measure
             WHERE UPPER(uom_code) = UPPER(x_uom_name)
               AND NVL(disable_date,SYSDATE+1) > SYSDATE;*/
               
         SELECT primary_uom_code
           INTO p_uom_code
           FROM mtl_system_items_b 
          WHERE inventory_item_id = p_inv_item_id                        
            AND ROWNUM < 2;                  
            
         /*ELSE
	       x_error_code := xx_emf_cn_pkg.cn_rec_err;
	       xx_emf_pkg.error
	          (p_severity                 => xx_emf_cn_pkg.cn_medium,
	           p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	           p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	                                         || '- Invalid : UOM CODE IS NULL => ',
	           p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	           p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	           p_record_identifier_3      => p_trxcnv_preiface_rec.uom_name
	          );
         END IF;*/
	 RETURN x_error_code;
	   EXCEPTION
		 WHEN TOO_MANY_ROWS
		 THEN
		    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
					   'SQLCODE TOOMANY ' || SQLCODE
					  );
		    x_error_code := xx_emf_cn_pkg.cn_rec_err;
		    xx_emf_pkg.error
			(p_severity                 => xx_emf_cn_pkg.cn_medium,
			 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
			 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
						       || ' - Invalid UOM CODE => '
						       || p_uom_code
						       || '-'
						       || xx_emf_cn_pkg.cn_too_many,
			 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
			 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
			 p_record_identifier_3      => p_trxcnv_preiface_rec.uom_name
			);
		    RETURN x_error_code;
		 WHEN NO_DATA_FOUND
		 THEN
		    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
					   'SQLCODE NODATA ' || SQLCODE
					  );
		    x_error_code := xx_emf_cn_pkg.cn_rec_err;
		    xx_emf_pkg.error
			(p_severity                 => xx_emf_cn_pkg.cn_medium,
			 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
			 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
						       || ' - Invalid UOM CODE => '
						       || p_uom_code
						       || '-'
						       || xx_emf_cn_pkg.cn_no_data,
			 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
			 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
			 p_record_identifier_3      => p_trxcnv_preiface_rec.uom_name
			);
		    RETURN x_error_code;
		 WHEN OTHERS
		 THEN
		    x_error_code := xx_emf_cn_pkg.cn_rec_err;
		    xx_emf_pkg.write_log
				     (xx_emf_cn_pkg.cn_low,
					 'Errors In uom_name Validation '
				      || SQLCODE
				     );
		    xx_emf_pkg.error
			(p_severity                 => xx_emf_cn_pkg.cn_medium,
			 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
			 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
						       || ' - Invalid UOM CODE => '
						       || p_uom_code
						       || '-'
						       || SQLERRM,
			 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
			 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
			 p_record_identifier_3      => p_trxcnv_preiface_rec.uom_name
			);
		   RETURN x_error_code;
      END is_uom_code_valid;

      FUNCTION is_ship_via_valid (
         p_ship_via              IN OUT   VARCHAR2
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_ship_via     VARCHAR2 (25);
      BEGIN
         x_ship_via :=
            xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'SHIP_VIA'                                                  
                                                  ,p_old_value => p_ship_via                                                                                                   
                                                  ,p_date_effective => SYSDATE
                                                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'derived value of  x_ship_via: ' || x_ship_via
                              );
         BEGIN                 
            SELECT DISTINCT freight_code
              INTO p_ship_via
              FROM org_freight 
             WHERE UPPER(freight_code) = UPPER(x_ship_via);
          
            RETURN x_error_code;
            EXCEPTION
	    	WHEN TOO_MANY_ROWS
	    	THEN
	    	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	    				   'SQLCODE TOOMANY ' || SQLCODE
	    				  );
	    	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	    xx_emf_pkg.error
	    		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	    		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	    		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	    					       || ' - Invalid ship_via => '
	    					       || p_ship_via
	    					       || '-'
	    					       || xx_emf_cn_pkg.cn_too_many,
	    		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	    		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	    		 p_record_identifier_3      => p_trxcnv_preiface_rec.ship_via
	    		);
	    	    RETURN x_error_code;
	    	WHEN NO_DATA_FOUND
	    	THEN
	    	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	    				   'SQLCODE NODATA ' || SQLCODE
	    				  );
	    	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	    xx_emf_pkg.error
	    		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	    		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	    		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	    					       || ' - Invalid ship_via => '
	    					       || p_ship_via
	    					       || '-'
	    					       || xx_emf_cn_pkg.cn_no_data,
	    		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	    		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	    		 p_record_identifier_3      => p_trxcnv_preiface_rec.ship_via
	    		);
	    	    RETURN x_error_code;
	    	WHEN OTHERS
	    	THEN
	    	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	    xx_emf_pkg.write_log
	    			     (xx_emf_cn_pkg.cn_low,
	    				 'Errors In ship_via Validation '
	    			      || SQLCODE
	    			     );
	    	    xx_emf_pkg.error
	    		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	    		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	    		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	    					       || ' - Invalid ship_via => '
	    					       || p_ship_via
	    					       || '-'
	    					       || SQLERRM,
	    		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	    		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	    		 p_record_identifier_3      => p_trxcnv_preiface_rec.ship_via
	    		);
		     RETURN x_error_code;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'Errors In is_ship_via_valid Validation '
                                 || SQLCODE
                                );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - SHIP VIA Validation => '
                                              || p_ship_via
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.ship_via
               );
            RETURN x_error_code;
      END is_ship_via_valid;

      FUNCTION is_tax_code_valid (
         p_tax_code              IN OUT   VARCHAR2,
         --p_legacy_system         IN       VARCHAR2,
         --p_operating_unit_name   IN       VARCHAR2,
         p_org_id                IN       NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_tax_code     VARCHAR2 (25);
      BEGIN
         /*x_tax_code :=
            xx_intg_common_pkg.get_mapping_value ('TAX_CODE',
                                                  p_legacy_system,                                                  
                                                  p_tax_code,
                                                  p_operating_unit_name,
                                                  SYSDATE
                                                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'derived value of  x_tax_code: ' || x_tax_code
                              );     */    
         
         BEGIN
             SELECT tax_code
               INTO x_tax_code
	       FROM ar_vat_tax
	      WHERE UPPER(tax_code) = UPPER(p_tax_code)
	        AND org_id =  p_org_id
	        AND TRUNC (SYSDATE) >= TRUNC (NVL (start_date, SYSDATE))
                AND TRUNC (SYSDATE) <= TRUNC (NVL (end_date, SYSDATE + 1));
                
              p_tax_code := x_tax_code;
            
            RETURN x_error_code;
            EXCEPTION
	    	WHEN TOO_MANY_ROWS
	    	THEN
	    	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	    				   'SQLCODE TOOMANY ' || SQLCODE
	    				  );
	    	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	    xx_emf_pkg.error
	    		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	    		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	    		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	    					       || ' - Invalid tax_code => '
	    					       || p_tax_code
	    					       || '-'
	    					       || xx_emf_cn_pkg.cn_too_many,
	    		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	    		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	    		 p_record_identifier_3      => p_trxcnv_preiface_rec.tax_code
	    		);
	    	    RETURN x_error_code;
	    	WHEN NO_DATA_FOUND
	    	THEN
	    	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	    				   'SQLCODE NODATA ' || SQLCODE
	    				  );
	    	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	    xx_emf_pkg.error
	    		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	    		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	    		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	    					       || ' - Invalid tax_code => '
	    					       || p_tax_code
	    					       || '-'
	    					       || xx_emf_cn_pkg.cn_no_data,
	    		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	    		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	    		 p_record_identifier_3      => p_trxcnv_preiface_rec.tax_code
	    		);
	    	    RETURN x_error_code;
	    	WHEN OTHERS
	    	THEN
	    	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	    	    xx_emf_pkg.write_log
	    			     (xx_emf_cn_pkg.cn_low,
	    				 'Errors In tax_code Validation '
	    			      || SQLCODE
	    			     );
	    	    xx_emf_pkg.error
	    		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	    		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	    		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	    					       || ' - Invalid tax_code => '
	    					       || p_tax_code
	    					       || '-'
	    					       || SQLERRM,
	    		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	    		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	    	    		 p_record_identifier_3      => p_trxcnv_preiface_rec.tax_code
	    	    		);
		   RETURN x_error_code;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                                (xx_emf_cn_pkg.cn_low,
                                    'Errors In is_tax_code_valid Validation '
                                 || SQLCODE
                                );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - TAX CODE Validation => '
                                              || p_tax_code
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.tax_code
               );
            RETURN x_error_code;
      END is_tax_code_valid;

      FUNCTION is_fob_point_valid (
                                    p_fob_point  IN OUT  VARCHAR2
                                  )
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_fob_point    VARCHAR2 (25);
      BEGIN
         x_fob_point :=
            xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'FOB_POINT'                                                  
                                                  ,p_old_value => p_fob_point                                                  
                                                  ,p_date_effective => SYSDATE
                                                 );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'derived value of  x_fob_point: '
                               || x_fob_point
                              );         
         BEGIN
            SELECT lookup_code 
              INTO p_fob_point
	      FROM ar_lookups 
	     WHERE lookup_type = 'FOB' 
	       AND enabled_flag = 'Y'
	       AND UPPER(lookup_code) = UPPER(x_fob_point)
	       AND TRUNC (SYSDATE) >= TRUNC (NVL (start_date_active, SYSDATE))
               AND TRUNC (SYSDATE) <= TRUNC (NVL (end_date_active, SYSDATE + 1));               
               
            RETURN x_error_code;
         EXCEPTION
	     WHEN TOO_MANY_ROWS
	 	THEN
	 	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	 				   'SQLCODE TOOMANY ' || SQLCODE
	 				  );
	 	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	 	    xx_emf_pkg.error
	 		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	 		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	 		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	 					       || ' - Invalid fob_point => '
	 					       || p_fob_point
	 					       || '-'
	 					       || xx_emf_cn_pkg.cn_too_many,
	 		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	 		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	 		 p_record_identifier_3      => p_trxcnv_preiface_rec.fob_point
	 		);
	 	    RETURN x_error_code;
	 	WHEN NO_DATA_FOUND
	 	THEN
	 	    xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
	 				   'SQLCODE NODATA ' || SQLCODE
	 				  );
	 	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	 	    xx_emf_pkg.error
	 		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	 		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	 		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	 					       || ' - Invalid fob_point => '
	 					       || p_fob_point
	 					       || '-'
	 					       || xx_emf_cn_pkg.cn_no_data,
	 		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	 		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	 		 p_record_identifier_3      => p_trxcnv_preiface_rec.fob_point
	 		);
	 	    RETURN x_error_code;
	 	WHEN OTHERS
	 	THEN
	 	    x_error_code := xx_emf_cn_pkg.cn_rec_err;
	 	    xx_emf_pkg.write_log
	 			     (xx_emf_cn_pkg.cn_low,
	 				 'Errors In fob_point Validation '
	 			      || SQLCODE
	 			     );
	 	    xx_emf_pkg.error
	 		(p_severity                 => xx_emf_cn_pkg.cn_medium,
	 		 p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
	 		 p_error_text               =>    p_trxcnv_preiface_rec.trx_number
	 					       || ' - Invalid fob_point => '
	 					       || p_fob_point
	 					       || '-'
	 					       || SQLERRM,
	 		 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	 		 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	 	    		 p_record_identifier_3      => p_trxcnv_preiface_rec.fob_point
	 	    	    		);
		  RETURN x_error_code;
         END;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log
                               (xx_emf_cn_pkg.cn_low,
                                   'Errors In is_fob_point_valid Validation '
                                || SQLCODE
                               );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - FOB Point Validation => '
                                              || p_fob_point
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.fob_point
               );
            RETURN x_error_code;
      END is_fob_point_valid;
      
      --Check for Intercompany Transaction Type for a Non-Intercompany Customer
      FUNCTION is_inter_comp_trx_type_valid ( p_cust_trx_type_id        IN  NUMBER
                                             ,p_orig_sys_bill_cust_ref  IN  VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_variable     VARCHAR2 (10) := NULL;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Intercompany Transaction Type Validation ' || p_orig_sys_bill_cust_ref
                              );

         SELECT 'X'
           INTO x_variable
	   FROM ra_cust_trx_types_all rctt, 
	        gl_code_combinations glcc
	  WHERE rctt.cust_trx_type_id = p_cust_trx_type_id
	    AND rctt.gl_id_rec = glcc.code_combination_id
	    AND glcc.segment3 = '127100'
	    AND NOT EXISTS
	                 ( SELECT 1 
	                     FROM apps.ar_lookups d
	                    WHERE lookup_type = 'INTG_INTERCOMPANY_ACCOUNTS'
	                      AND ( lookup_code = SUBSTR(p_orig_sys_bill_cust_ref, 5, LENGTH(p_orig_sys_bill_cust_ref))
	                           OR lookup_code = p_orig_sys_bill_cust_ref )  --Added as per 11i Wave1 for intercompany customers 01-OCT-13
	                 )
	    AND ROWNUM = 1;            

         IF x_variable IS NOT NULL THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               => 'Invalid : Intercompany Transaction Type for a Non-Intercompany Customer => ',
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.orig_system_bill_customer_ref,
                p_record_identifier_3      => p_trxcnv_preiface_rec.trx_number
               );            
         END IF;
         
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            x_error_code := xx_emf_cn_pkg.cn_success;
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'Errors In Intercompany Transaction Type Validation '
                                  || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Intercompany Transaction Type for a Non-Intercompany Customer => '
                                              || p_orig_sys_bill_cust_ref
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.orig_system_bill_customer_ref,
                p_record_identifier_3      => p_trxcnv_preiface_rec.trx_number
               );
            RETURN x_error_code;
      END is_inter_comp_trx_type_valid;
      
   ------------------------Begin To Call Data Validation Functions----------------------
   -- Start of the main function perform data_validations
   -- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside Data-Validations RECORD NUMBER: '
                            || p_trxcnv_preiface_rec.record_number
                           );
      
      --Batch Source Name Validation
      x_error_code_temp :=
               is_batch_source_valid ( p_trxcnv_preiface_rec.batch_source_name   
                                      ,p_trxcnv_preiface_rec.org_id
                                     );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                     'After is_batch_source_valid Errord code=: '
                                  || x_error_code
                           );
      
      --Operating Unit validation
      x_error_code_temp :=
         is_operating_unit_valid (p_trxcnv_preiface_rec.operating_unit_name,
                                  p_trxcnv_preiface_rec.org_id                                  
                                 );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_operating_unit_valid Errord code=: '
                            || x_error_code
                           );
      --Line type validation
      x_error_code_temp :=
                          is_line_type_valid (p_trxcnv_preiface_rec.line_type);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_line_type_valid Errord code=: '
                            || x_error_code
                           );
      --Currency code validation
      x_error_code_temp :=
                      is_curr_code_valid (p_trxcnv_preiface_rec.currency_code);
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_curr_code_valid Errord code=: '
                            || x_error_code
                           );
      --Transaction type validation
      x_error_code_temp :=
         is_cust_trx_type_valid (p_trxcnv_preiface_rec.operating_unit_name,
                                 p_trxcnv_preiface_rec.cust_trx_type_name,
                                 p_trxcnv_preiface_rec.cust_trx_type_id,
                                 p_trxcnv_preiface_rec.org_id                                 
                                );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'After Trx Type Errord code=' || x_error_code
                           );

      --Term Name Validation
      IF p_trxcnv_preiface_rec.term_name IS NOT NULL         
      THEN
         x_error_code_temp :=
            is_term_name_valid (p_trxcnv_preiface_rec.term_name,
                                p_trxcnv_preiface_rec.term_id
                               );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After is_term_name_valid Errord code=: '
                               || x_error_code
                              );
      END IF;
      
      --Bill to Customer Validation
      x_error_code_temp :=
         is_customer_number_valid
                         (p_trxcnv_preiface_rec.orig_system_bill_customer_ref,
                          p_trxcnv_preiface_rec.orig_system_bill_customer_id
                         );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                   (xx_emf_cn_pkg.cn_low,
                       'After validating bill_to_Customer_Number Error Code: '
                    || x_error_code
                   );

      --Bill to Address Validation
      IF     p_trxcnv_preiface_rec.orig_system_bill_customer_id IS NOT NULL
         AND p_trxcnv_preiface_rec.orig_system_bill_address_ref IS NOT NULL
      THEN  --Modiifed as per 11i Wave1  01-OCT-13
         x_error_code_temp :=
            is_cust_address_valid
                        (p_trxcnv_preiface_rec.org_id,
                         p_trxcnv_preiface_rec.orig_system_bill_customer_id,  --p_trxcnv_preiface_rec.orig_system_bill_customer_ref,
                         p_trxcnv_preiface_rec.orig_system_bill_address_ref,
                         p_trxcnv_preiface_rec.orig_system_bill_address_id,
                         'BILL_TO'
                        );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'After validating bill_to_address Error Code: '
                            || x_error_code
                           );
      END IF;

      --Bill to Contact Validation
      /*IF     p_trxcnv_preiface_rec.orig_system_bill_customer_ref IS NOT NULL
         AND p_trxcnv_preiface_rec.orig_system_bill_address_ref IS NOT NULL
         AND p_trxcnv_preiface_rec.orig_system_bill_contact_ref IS NOT NULL
      THEN
         x_error_code_temp :=
            is_customer_contact_valid
                        (p_trxcnv_preiface_rec.org_id,
                         p_trxcnv_preiface_rec.orig_system_bill_customer_ref,
                         p_trxcnv_preiface_rec.orig_system_bill_address_ref,
                         p_trxcnv_preiface_rec.orig_system_bill_contact_ref,
                         p_trxcnv_preiface_rec.orig_system_bill_contact_id,
                         'BILL_TO'
                        );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'After validating bill_to_contact Error Code: '
                            || x_error_code
                           );
      END IF;*/

      --Ship To customer Validation
      IF p_trxcnv_preiface_rec.orig_system_ship_customer_ref IS NOT NULL
      THEN
         x_error_code_temp :=
            is_customer_number_valid
                        (p_trxcnv_preiface_rec.orig_system_ship_customer_ref,
                         p_trxcnv_preiface_rec.orig_system_ship_customer_id
                        );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                   (xx_emf_cn_pkg.cn_low,
                       'After validating Ship_to_Customer_Number Error Code: '
                    || x_error_code
                   );
      END IF;

      --Ship to Address Validation
      IF     p_trxcnv_preiface_rec.orig_system_ship_customer_id IS NOT NULL
         AND p_trxcnv_preiface_rec.orig_system_ship_address_ref IS NOT NULL
      THEN  --Modiifed as per 11i Wave1  01-OCT-13
         x_error_code_temp :=
            is_cust_address_valid
                        (p_trxcnv_preiface_rec.org_id,
                         p_trxcnv_preiface_rec.orig_system_ship_customer_id, --p_trxcnv_preiface_rec.orig_system_ship_customer_ref,
                         p_trxcnv_preiface_rec.orig_system_ship_address_ref,
                         p_trxcnv_preiface_rec.orig_system_ship_address_id,
                         'SHIP_TO'
                        );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'After validating ship_to_address Error Code: '
                            || x_error_code
                           );
      END IF;

      --Ship to Contact Validation
      /*IF     p_trxcnv_preiface_rec.orig_system_ship_customer_ref IS NOT NULL
         AND p_trxcnv_preiface_rec.orig_system_ship_address_ref IS NOT NULL
         AND p_trxcnv_preiface_rec.orig_system_ship_contact_ref IS NOT NULL
      THEN
         x_error_code_temp :=
            is_customer_contact_valid
                        (p_trxcnv_preiface_rec.org_id,
                         p_trxcnv_preiface_rec.orig_system_ship_customer_ref,
                         p_trxcnv_preiface_rec.orig_system_ship_address_ref,
                         p_trxcnv_preiface_rec.orig_system_ship_contact_ref,
                         p_trxcnv_preiface_rec.orig_system_ship_contact_id,
                         'SHIP_TO'
                        );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                           (xx_emf_cn_pkg.cn_low,
                               'After validating ship_to_contact Error Code: '
                            || x_error_code
                           );
      END IF;*/

      --Receipt Method Validation
      IF p_trxcnv_preiface_rec.receipt_method_name IS NOT NULL
      THEN
         x_error_code_temp :=
            is_receipt_method_valid
                                  (p_trxcnv_preiface_rec.receipt_method_name,
                                   p_trxcnv_preiface_rec.receipt_method_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                            (xx_emf_cn_pkg.cn_low,
                                'After is_receipt_method_valid Errord code=: '
                             || x_error_code
                            );
      END IF;

      --GL Date Validation
      /*x_error_code_temp :=
         is_gl_date_valid (p_trxcnv_preiface_rec.gl_date,
                           p_trxcnv_preiface_rec.operating_unit_name
                          );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_gl_date_valid Errord code=: '
                            || x_error_code
                           );*/
      --Commented as per Mock Test
      --Invoicing Rule Name Validation
      /*IF p_trxcnv_preiface_rec.invoicing_rule_name IS NOT NULL         
      THEN
         x_error_code_temp :=
            is_invrule_name_valid (p_trxcnv_preiface_rec.invoicing_rule_name,
                                   p_trxcnv_preiface_rec.invoicing_rule_id
                                  );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After is_invrule_name_valid Errord code=: '
                               || x_error_code
                              );
      END IF;*/

      --Accounting Rule Name Validation
      /*IF p_trxcnv_preiface_rec.accounting_rule_name IS NOT NULL
      THEN
         x_error_code_temp :=
            is_accrule_name_valid
                                 (p_trxcnv_preiface_rec.accounting_rule_name,
                                  p_trxcnv_preiface_rec.accounting_rule_id
                                 );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After is_accrule_name_valid Errord code=: '
                               || x_error_code
                              );
      END IF;*/

      --Sales Rep Validation
      IF p_trxcnv_preiface_rec.primary_salesrep_number IS NOT NULL
      THEN
         x_error_code_temp :=
            is_sales_rep_valid
                              (p_trxcnv_preiface_rec.primary_salesrep_number,
                               p_trxcnv_preiface_rec.primary_salesrep_id,
                               --p_trxcnv_preiface_rec.source_system_name,
                               --p_trxcnv_preiface_rec.operating_unit_name,
                               p_trxcnv_preiface_rec.org_id
                              );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After is_sales_rep_valid Errord code=: '
                               || x_error_code
                              );
      END IF;

      --Commented to invoke autoaccounting
      --Distribution Line Check
      /*x_error_code_temp :=
         is_interface_dist_exits
                             (p_trxcnv_preiface_rec.interface_line_context,
                              p_trxcnv_preiface_rec.interface_line_attribute1,
                              p_trxcnv_preiface_rec.interface_line_attribute2
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'After is_interface_dist_exits Errord code=: '
                            || x_error_code
                           );
      --Check for total of line distributions with REC line amount
      x_error_code_temp :=
         is_line_dist_amount_valid
                             (p_trxcnv_preiface_rec.interface_line_context,
                              p_trxcnv_preiface_rec.interface_line_attribute1,
                              p_trxcnv_preiface_rec.interface_line_attribute2,
                              p_trxcnv_preiface_rec.cust_trx_type_name
                             );
      x_error_code := find_max (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log
                          (xx_emf_cn_pkg.cn_low,
                              'After is_line_dist_amount_valid Errord code=: '
                           || x_error_code
                          );*/

      --Check for mtl sys item segment1
      IF p_trxcnv_preiface_rec.mtl_system_items_seg1 IS NOT NULL
      THEN
         x_error_code_temp :=
            is_mtl_item_seg1_valid
                                (p_trxcnv_preiface_rec.mtl_system_items_seg1,
                                 p_trxcnv_preiface_rec.inventory_item_id
                                );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log
                             (xx_emf_cn_pkg.cn_low,
                                 'After Is_mtl_item_seg1_valid Errord code=: '
                              || x_error_code
                             );
      END IF;

      --Check for uom name
      IF p_trxcnv_preiface_rec.inventory_item_id IS NOT NULL THEN
         x_error_code_temp :=
            is_uom_code_valid ( p_trxcnv_preiface_rec.inventory_item_id,
                                p_trxcnv_preiface_rec.uom_code                               
                              );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After is_uom_code_valid Errord code=: '
                               || x_error_code
                              );
      END IF;

      --Check for ship via
      --Modified to set ship via to NULL as per change request
      IF p_trxcnv_preiface_rec.ship_via IS NOT NULL
      THEN
         p_trxcnv_preiface_rec.ship_via := NULL;
         /*x_error_code_temp :=
            is_ship_via_valid (p_trxcnv_preiface_rec.ship_via
                              );
         x_error_code := find_max (x_error_code, x_error_code_temp);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'After is_ship_via_valid Errord code=: '
                               || x_error_code
                              );*/
      END IF;
      
      --Check for tax code
      /*IF p_trxcnv_preiface_rec.tax_code IS NOT NULL
      THEN
	 x_error_code_temp :=
	   is_tax_code_valid (p_trxcnv_preiface_rec.tax_code,
	                      --p_trxcnv_preiface_rec.source_system_name,
	                      --p_trxcnv_preiface_rec.operating_unit_name,	                      
	                      p_trxcnv_preiface_rec.org_id
				    );
	 x_error_code := find_max (x_error_code, x_error_code_temp);
	 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
					'After is_tax_code_valid Errord code=: '
				     || x_error_code
				    );
      END IF;*/
      
      --Check for fob point
      IF p_trxcnv_preiface_rec.fob_point IS NOT NULL
      THEN
      	 x_error_code_temp :=
      	   is_fob_point_valid (p_trxcnv_preiface_rec.fob_point
      				    );
      	 x_error_code := find_max (x_error_code, x_error_code_temp);
      	 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
      					'After is_fob_point_valid Errord code=: '
      				     || x_error_code
      				    );
      END IF;
      
      --Check for Intercompany Transaction Type for a Non-Intercompany Customer     
      IF p_trxcnv_preiface_rec.cust_trx_type_id IS NOT NULL AND 
         p_trxcnv_preiface_rec.orig_system_bill_customer_id IS NOT NULL THEN         
         x_error_code_temp :=
              is_inter_comp_trx_type_valid(  p_trxcnv_preiface_rec.cust_trx_type_id
                                            ,p_trxcnv_preiface_rec.orig_system_bill_customer_ref );
      	 x_error_code := find_max (x_error_code, x_error_code_temp);
      	 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
      					'After is_inter_comp_trx_type_valid Errord code : '
      				     || x_error_code
      				    );
      END IF;                                            

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
   END data_validations;

   --Functio to perform Data-derivations
   FUNCTION data_derivations (
      p_trxcnv_preiface_rec   IN OUT   xx_trx_conversion_pkg.g_xx_ar_cnv_pre_std_rec_type
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

      FUNCTION get_sob_id (
         p_operating_unit_name   IN       VARCHAR2,
         p_sob_id                OUT      NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SOB ID derivation for '
                               || p_operating_unit_name
                              );

         SELECT set_of_books_id
           INTO p_sob_id
           FROM hr_operating_units
          WHERE NAME = p_operating_unit_name;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'p_sob_id =' || p_sob_id);
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE TOOMANY ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid SOB ID => '
                                              || p_operating_unit_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_too_many,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.operating_unit_name
               );
            RETURN x_error_code;
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'SQLCODE NODATA ' || SQLCODE
                                 );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid SOB ID => '
                                              || p_operating_unit_name
                                              || '-'
                                              || xx_emf_cn_pkg.cn_no_data,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.operating_unit_name
               );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                  'Errors In SOB ID Derivation ' || SQLCODE
                                 );
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               =>    p_trxcnv_preiface_rec.trx_number
                                              || ' - Invalid SOB ID => '
                                              || p_operating_unit_name
                                              || '-'
                                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.operating_unit_name
               );
            RETURN x_error_code;
      END get_sob_id;
   ----------------------------Begin To Call Derive Functions------------------------------
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                               'Inside DATA DERIVATION..Record Number: '
                            || p_trxcnv_preiface_rec.record_number
                           );
      --SOB Id Derivation
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'Before get_sob_id: ' || x_error_code
                           );
      x_error_code_temp :=
         get_sob_id (p_trxcnv_preiface_rec.operating_unit_name,
                     p_trxcnv_preiface_rec.set_of_books_id
                    );
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                            'after get_sob_id: ' || x_error_code_temp
                           );
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
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END data_derivations;
   
   --Function to perform Post-validations
   FUNCTION post_validations
      RETURN NUMBER
   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      RETURN x_error_code;
   END post_validations;
   
END xx_ar_trx_cnv_validations_pkg;
/


GRANT EXECUTE ON APPS.XX_AR_TRX_CNV_VALIDATIONS_PKG TO INTG_XX_NONHR_RO;
