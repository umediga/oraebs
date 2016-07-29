DROP PACKAGE BODY APPS.XX_PO_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_po_cnv_validations_pkg
AS
   ----------------------------------------------------------------------
   /*
    Created By    : IBM Development Team
    Creation Date : 23-FEB-2012
    File Name     : XXPOOPENPOVAL.pkb
    Description   : This script creates the body of the package
                    xx_po_cnv_validations_pkg
    Change History:
    Date         Name                   Remarks
    -----------  -------------          -----------------------------------
    23-FEB-2012  IBM Development Team   Initial Draft.
	15-JUL-2013	 ABHARGAVA				WAVE1 Changes
  07-JAN-2014  ABHARGAVA        Added logic to handle multiple OU in single file
  21-Feb-2014  ABHARGAVA        Added logic to check Charge A/C and Freight Carrier
  09-MAR-2015  Sharath Babu             Modified as per Wave2 to fix batch id issue
   */
   -----------------------------------------------------------------------
   /**
 * FUNCTION xx_po_conv_ven
 *
 * DESCRIPTION
 *     Find the vendor number.
 *
 * ARGUMENTS
 *   IN:
 *     p_att1                         Attribute1 .
 *     p_att2                        Attribute2.
 *     p_src                         Legacy Source System
 *
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Vendor Number .
 */
  FUNCTION xx_po_conv_ven(p_att1 VARCHAR2, p_att2 VARCHAR2,p_src VARCHAR2)
      RETURN VARCHAR2
    IS
      l_str   VARCHAR2(10) := '|';
          l_pos1 NUMBER;
          l_pos2 NUMBER;
          l_CNT_OCC NUMBER;
          l_CNT_OCC_src NUMBER;
          l_ret_val VARCHAR2(100);
        BEGIN
          -- Check if the Source System Name exists in Attribute 1 only then proceed , if not return NULL
          IF INSTR(p_att1,p_src) > 0 THEN
              -- Count the number of occurence of | in the String
              SELECT regexp_count(REPLACE(p_att1,'|','XXX'),'XXX')
              INTO l_CNT_OCC
              FROM dual;

              -- Count of number of pipes before the source system
              SELECT NVL(regexp_count(REPLACE(SUBSTR(p_att1,1,INSTR(p_att1,p_src)-1),l_str,'XXX'),'XXX'),0)
              INTO l_CNT_OCC_src
              FROM dual;

              -- If the source system is the FIRST Set before pipe then get attribute 2 value from 1 st position to the 1st occurence of pipe
              IF l_CNT_OCC_src =0 THEN
                  SELECT SUBSTR(p_att2,1,decode(INSTR(p_att2,'|',1,1),0,length(p_att2),INSTR(p_att2,'|',1,1)-1))
                  INTO l_ret_val
                  FROM dual;
              -- If the source system is the LAST Set before pipe then get attribute 2 value from 1 st position to the nth occurence of pipe
              ELSIF l_cnt_occ_src =   l_CNT_OCC  THEN
                  SELECT SUBSTR(p_att2,instr(p_att2,'|',1,regexp_count(REPLACE(SUBSTR(p_att1,1,INSTR(p_att1,p_src)-1),l_str,'XXX'),'XXX'))+1,LENGTH(p_att2))
                  INTO l_ret_val
                  FROM dual;
              -- If the source system is the BETWEEN  Set before pipe then get attribute 2 value from nth position to n+1 th position  of pipe
              ELSIF INSTR(p_att1,p_src) > 0 THEN
                  SELECT SUBSTR(p_att2,instr(p_att2,'|',1,regexp_count(REPLACE(SUBSTR(p_att1,1,INSTR(p_att1,p_src)-1),l_str,'XXX'),'XXX'))+1,
                  INSTR(p_att2,'|',1,regexp_count(REPLACE(SUBSTR(p_att1,1,INSTR(p_att1,p_src)-1),l_str,'XXX'),'XXX')+1)-
                  INSTR(p_att2,'|',1,regexp_count(REPLACE(SUBSTR(p_att1,1,INSTR(p_att1,p_src)-1),l_str,'XXX'),'XXX'))-1)
                  INTO l_ret_val
                  FROM dual;
              -- If nothting matches return NULL
              ELSE
                  RETURN(NULL);
              END IF;
              RETURN(l_ret_val);
          ELSE
              RETURN (NULL);
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            RETURN(NULL);
      END;
/**
 * FUNCTION find_max
 *
 * DESCRIPTION
 *     Find maximum of error code.
 *
 * ARGUMENTS
 *   IN:
 *     p_error_code1                  Error Code.
 *     p_error_code1                  Error Code Template.
 *
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Maximum of Error Code.
 */
   FUNCTION find_max (p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2
   IS
      x_return_value   VARCHAR2 (100);
   BEGIN
      x_return_value :=
         xx_intg_common_pkg.find_max (p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

/**
 * FUNCTION pre_validations
 *
 * DESCRIPTION
 *     Data Prevalidations.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Error Code.
 */
   FUNCTION pre_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

-- Header Level Data-Validations
/**
 * FUNCTION data_validations_hdr
 *
 * DESCRIPTION
 *     Data Prevalidations.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *          p_cnv_hdr_rec           Header Record Type
 *   OUT:
 *   RETURN:                        Error Code.
 */
   FUNCTION data_validations_hdr (
      p_cnv_hdr_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_HDR_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;


 /**
 * FUNCTION get_operating_unit
 *
 * DESCRIPTION
 *     Function to Get Org_id from legacy Organization Code.
 *
 * ARGUMENTS
 *   IN:
 *     p_organization_code           Legacy Organization Code.
 *
 *   IN/OUT:
 *   OUT:
 *      p_org_id                     Org ID
 *   RETURN:                         Error Code.
 */
FUNCTION get_operating_unit (p_organization_code IN  VARCHAR2
                      ,p_org_id         OUT NUMBER
                      ) RETURN NUMBER
     IS
            x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_operating_unit    VARCHAR2(240);
            x_variable          VARCHAR2(10);

     BEGIN
       BEGIN

        /*x_operating_unit := xx_intg_common_pkg.get_mapping_value (
                                      p_mapping_type     => 'OPERATING_UNIT',
                                      p_source           => NULL,
                                      p_old_value        => trim(p_organization_code),
                                      p_date_effective   => SYSDATE);
               xx_emf_pkg.write_log (
                  xx_emf_cn_pkg.CN_LOW,
                  'Derived Operating Unit: ' || x_operating_unit );

        SELECT organization_id
          INTO p_org_id
          FROM hr_operating_units
         WHERE name = x_operating_unit;*/

        -- Modified by ABHARGAVA on 7th Jan 2014 due to multiple OU in a single file
        --x_operating_unit := XX_EMF_PKG.get_paramater_value('XXINTGPOOPENPOCNV','OPERATING_UNIT');
        x_operating_unit := p_organization_code;
        SELECT organization_id
          INTO p_org_id
          FROM hr_operating_units
         WHERE name = x_operating_unit;

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Derived Org ID: '||p_org_id);
        G_ORG_ID := p_org_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'NO DATA FOUND for Operating Unit: '||p_org_id);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM
                                ,xx_emf_cn_pkg.CN_STG_DATAVAL
                                ,xx_emf_cn_pkg.CN_NO_DATA||' for Operating Unit; '
                                ,p_cnv_hdr_rec.batch_id
                                ,p_cnv_hdr_rec.record_number
                                ,p_cnv_hdr_rec.legacy_po_number
                                ,p_org_id
                                );
                   RETURN x_error_code;
          WHEN TOO_MANY_ROWS THEN
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'TOOMANY for Operating Unit: '||p_org_id);
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM
                                    ,xx_emf_cn_pkg.CN_STG_DATAVAL
                                    ,xx_emf_cn_pkg.CN_TOO_MANY||' for Operating Unit: '
                                    ,p_cnv_hdr_rec.batch_id
                                    ,p_cnv_hdr_rec.record_number
                                    ,p_cnv_hdr_rec.legacy_po_number
                                    ,p_org_id
                                    );
                   RETURN x_error_code;
          WHEN OTHERS THEN
                   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Operating Unit: '||SQLERRM);
                   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM
                                    ,xx_emf_cn_pkg.CN_STG_DATAVAL
                                    ,'Error in Operating Unit: '||SQLERRM
                                    ,p_cnv_hdr_rec.batch_id
                                    ,p_cnv_hdr_rec.record_number
                                    ,p_cnv_hdr_rec.legacy_po_number
                                    ,G_DOCUMENT_TYPE_CODE
                                    );
                   RETURN x_error_code;
       END;
       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Operating Unit => SUCCESS::Org ID: '||p_org_id);
       RETURN x_error_code;
     EXCEPTION
       WHEN OTHERS THEN
        IF x_error_code = xx_emf_cn_pkg.CN_SUCCESS THEN
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM
                            ,xx_emf_cn_pkg.CN_STG_DATAVAL
                            ,xx_emf_cn_pkg.CN_EXP_UNHAND||' Operating Unit: '||SQLERRM
                            ,p_cnv_hdr_rec.batch_id
                            ,p_cnv_hdr_rec.record_number
                            ,p_cnv_hdr_rec.legacy_po_number
                            ,G_DOCUMENT_TYPE_CODE
                            );
        END IF;
       RETURN x_error_code;
     END get_operating_unit;
 /**
 * FUNCTION check_po_number
 *
 * DESCRIPTION
 *     Find whether the Legacy PO has already converted to R12 or not.
 *
 * ARGUMENTS
 *   IN:
 *     p_legacy_po_number             Legacy PO Number.
 *
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION check_po_number (p_legacy_po_number IN VARCHAR2, p_org_id IN NUMBER )
         RETURN CHAR
      IS
         x_po_num       VARCHAR2 (50);
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         SELECT   segment1
           INTO   x_po_num
           FROM   po_headers_all
          WHERE   vendor_order_num = p_legacy_po_number
           AND    org_id = p_org_id;                    --- Changed on 28-SEP-2012

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
               'Derived Existing PO Number: '
            || NVL (x_po_num, 'is null')
            || ' For Legacy PO Number:'
            || p_legacy_po_number
         );

         IF x_po_num IS NULL
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'PO Record already Exist in Oracle for Legacy PO number: '
               || p_legacy_po_number
            );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Existing PO Number in ORACLE: ' || x_po_num
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'PO Record already Exist in Oracle for Header Legacy PO number: ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_legacy_po_number
            );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END check_po_number;

 /**
 * FUNCTION is_po_line_exist
 *
 * DESCRIPTION
 *     Find whether the Legacy PO has atleast a Line or not.
 *
 * ARGUMENTS
 *   IN:
 *     p_legacy_po_number             Legacy PO Number.
 *
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_po_line_exist (p_legacy_po_number IN VARCHAR2)
         RETURN CHAR
      IS
         x_line_count   NUMBER;
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         SELECT COUNT ( * )
           INTO x_line_count
           FROM xx_po_lines_stg
          WHERE legacy_po_number = p_legacy_po_number
            AND batch_id = p_cnv_hdr_rec.batch_id;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
               'PO Line(s) Exists for Legacy PO Number:'
            || p_legacy_po_number
         );

         IF x_line_count > 0
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'There should be at least one line per document: '
               || p_legacy_po_number
            );

            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'There should be at least one line per document: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_legacy_po_number
            );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END is_po_line_exist;

 /**
 * FUNCTION is_document_type_valid
 *
 * DESCRIPTION
 *     Function to find legacy document type code is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_document_type              Legacy Document type code
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_document_type_valid (p_document_type IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for document type code: ' || p_document_type
         );
         p_document_type := XX_EMF_PKG.get_paramater_value('XXINTGPOOPENPOCNV','DOCUMENT_TYPE_CODE');

         RETURN x_error_code;
      END is_document_type_valid;

 /**
 * FUNCTION is_currency_code_valid
 *
 * DESCRIPTION
 *     Function to find legacy Currency Code is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *      p_organization_id            Org Id
 *   IN/OUT:
 *      p_currency_code              Currency code
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_currency_code_valid (p_organization_id IN NUMBER,
         p_currency_code   IN OUT ap_suppliers.invoice_currency_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
         x_variable        VARCHAR2 (40);
         x_currency_code   VARCHAR2 (10);
      BEGIN
         BEGIN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Validation for currency code: ' || p_currency_code
            );

            IF p_currency_code IS NOT NULL
            THEN
               x_currency_code :=
                  xx_intg_common_pkg.get_mapping_value (
                     p_mapping_type     => 'VENDOR_CURRENCY',
                     p_source           => NULL,
                     p_old_value        => p_currency_code,
                     p_date_effective   => SYSDATE
                  );
               xx_emf_pkg.write_log (
                  xx_emf_cn_pkg.CN_LOW,
                  'Derived Currency Code: ' || x_currency_code
               );

               SELECT 'X'
                 INTO x_variable
                 FROM fnd_currencies
                WHERE currency_code = x_currency_code
                  AND NVL (end_date_active, ADD_MONTHS (SYSDATE, 1)) >=
                           ADD_MONTHS (SYSDATE, 1)
                  AND enabled_flag = 'Y';

               p_currency_code := x_currency_code;
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                     'p_currency_code: ' || p_currency_code);
            ELSE

            SELECT gl.currency_code
              INTO p_currency_code
              FROM financials_system_params_all fspa,
                   gl_ledgers gl
             WHERE fspa.set_of_books_id = gl.ledger_id
               AND fspa.org_id = p_organization_id;

            END IF;

            RETURN x_error_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               xx_emf_pkg.write_log (
                  xx_emf_cn_pkg.CN_LOW,
                  'NO DATA FOUND for Currency Code: ' || p_currency_code
               );
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
                  xx_emf_cn_pkg.CN_MEDIUM,
                  xx_emf_cn_pkg.CN_STG_DATAVAL,
                     xx_emf_cn_pkg.CN_NO_DATA
                  || ' for Currency Code: '
                  ,
                  p_cnv_hdr_rec.batch_id,
                  p_cnv_hdr_rec.record_number,
                  p_cnv_hdr_rec.legacy_po_number,
                  p_currency_code
               );
               RETURN x_error_code;
            WHEN TOO_MANY_ROWS
            THEN
               xx_emf_pkg.write_log (
                  xx_emf_cn_pkg.CN_LOW,
                  'TOOMANY for Currency Code: ' || p_currency_code
               );
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
                  xx_emf_cn_pkg.CN_MEDIUM,
                  xx_emf_cn_pkg.CN_STG_DATAVAL,
                     xx_emf_cn_pkg.CN_TOO_MANY
                  || ' for Currency Code: '
                  ,
                  p_cnv_hdr_rec.batch_id,
                  p_cnv_hdr_rec.record_number,
                  p_cnv_hdr_rec.legacy_po_number,
                  p_currency_code
               );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                     'Error in Currency Code: ' || SQLERRM);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
                  xx_emf_cn_pkg.CN_MEDIUM,
                  xx_emf_cn_pkg.CN_STG_DATAVAL,
                  'Error in Currency Code Validation: ' || SQLERRM,
                  p_cnv_hdr_rec.batch_id,
                  p_cnv_hdr_rec.record_number,
                  p_cnv_hdr_rec.legacy_po_number,
                  G_DOCUMENT_TYPE_CODE
               );
               RETURN x_error_code;
         END;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Currency Code validation => SUCCESS::Currency Code: '
            || p_currency_code
         );
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.CN_SUCCESS
            THEN
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
                  xx_emf_cn_pkg.CN_MEDIUM,
                  xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_EXP_UNHAND || '-' || SQLERRM,
                  p_cnv_hdr_rec.batch_id,
                  p_cnv_hdr_rec.record_number,
                  p_cnv_hdr_rec.legacy_po_number,
                  G_DOCUMENT_TYPE_CODE
               );
            END IF;

            RETURN x_error_code;
      END is_currency_code_valid;

 /**
 * FUNCTION is_conversion_type_valid
 *
 * DESCRIPTION
 *     Function to find legacy Conversion type is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *      p_organization_id            Org Id
 *   IN/OUT:
 *      p_conversion_type            Conversion type
 *      p_conversion_date            Conversion date
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_conversion_type_valid (
         p_conversion_type   IN OUT gl_daily_rates.conversion_type%TYPE,
         p_conversion_date   IN OUT DATE,
         p_conversion_rate   IN OUT NUMBER,
         p_currency_code     IN     VARCHAR2,
         p_organization_id   IN     NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         v_rate_type    VARCHAR2 (30);
         l_currency_code VARCHAR2 (30);
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for daily Conversion Type: ' || p_conversion_type
         );

            SELECT gl.currency_code
              INTO l_currency_code
              FROM financials_system_params_all fspa,
                   gl_ledgers gl
             WHERE fspa.set_of_books_id = gl.ledger_id
               AND fspa.org_id = p_organization_id;

        IF NVL(p_currency_code,l_currency_code) = l_currency_code
          THEN
            p_conversion_type := NULL;
            p_conversion_date := NULL;
            p_conversion_rate := NULL;
        ELSIF NVL(p_currency_code,l_currency_code) <> l_currency_code ---AND p_conversion_type IS NOT NULL
         THEN
            /*SELECT   UPPER (conversion_type)
              INTO   v_rate_type
              FROM   gl_daily_rates
             WHERE   UPPER (conversion_type) = UPPER (p_conversion_type);*/

            p_conversion_type := 'User';--p_conversion_type;--'Corporate';--v_rate_type;
            p_conversion_date := p_conversion_date;
            p_conversion_rate := p_conversion_rate;

            /*SELECT conversion_rate
              INTO p_conversion_rate
              FROM gl_daily_rates
             WHERE conversion_date = p_conversion_date
               AND from_currency = p_currency_code
               AND to_currency = l_currency_code
               AND conversion_type = p_conversion_type;*/


            --p_conversion_date := SYSDATE;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'p_conversion_type: ' || p_conversion_type);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Conversion Date: ' || p_conversion_date);
           -- IF p_conversion_rate IS NULL THEN
             --   RAISE NO_DATA_FOUND;
            --END IF;
        END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for daily Conversion Rate: '
               || p_conversion_rate
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for daily Conversion Rate: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_conversion_type
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for daily Conversion Type: ' || p_conversion_type
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for daily Conversion Type: '
               || p_conversion_type,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in daily Conversion Type: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in daily Conversion Type Validation: ' || SQLERRM,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_conversion_type_valid;

 /**
 * FUNCTION is_agent_name_valid
 *
 * DESCRIPTION
 *     Function to find legacy Agent is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_agent_name                 Agent Name
 *   OUT:
 *      p_agent_id                   Derived Agent Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_agent_name_valid (p_agent_name    IN OUT VARCHAR2,
                                    p_agent_id         OUT NUMBER)
         RETURN NUMBER
      IS
         x_error_code            NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_agent_name            VARCHAR2(240);

      BEGIN
         BEGIN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Validation for Agent: ' || p_agent_name);
           BEGIN
            SELECT   poa.agent_id, poa.agent_name
              INTO   p_agent_id, p_agent_name
              FROM   po_agents_v poa
             WHERE   upper(poa.agent_name) = upper(p_agent_name);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived Agent ID: ' || p_agent_id);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived Agent Name: ' || p_agent_name);
           EXCEPTION
              WHEN NO_DATA_FOUND
               THEN
                --Added on 11-Jul-2012
                 x_agent_name :=
                     xx_intg_common_pkg.get_mapping_value (
                        p_mapping_type     => 'BUYER_NAME',
                        p_source           => NULL,
                        p_old_value        => p_agent_name,
                        p_date_effective   => SYSDATE );

                 xx_emf_pkg.write_log (
                   xx_emf_cn_pkg.CN_LOW,
                   'Derived Agent Name: ' || x_agent_name );

                 SELECT poa.agent_id, poa.agent_name
                   INTO p_agent_id, p_agent_name
                   FROM po_agents_v poa
                  WHERE upper(poa.agent_name) = upper(x_agent_name);

                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived Agent ID: ' || p_agent_id);
                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived Agent Name: ' || p_agent_name);
              --RETURN x_error_code;
           END;

         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               xx_emf_pkg.write_log (
                  xx_emf_cn_pkg.CN_LOW,
                  'NO DATA FOUND for Agent: ' || p_agent_name
               );
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
                  xx_emf_cn_pkg.CN_MEDIUM,
                  xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA || ' for Agent: ' ,
                  p_cnv_hdr_rec.batch_id,
                  p_cnv_hdr_rec.record_number,
                  p_cnv_hdr_rec.legacy_po_number,
                  p_agent_name
               );
               RETURN x_error_code;
            WHEN TOO_MANY_ROWS
            THEN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                     'TOOMANY for Agent: ' || p_agent_name);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
                  xx_emf_cn_pkg.CN_MEDIUM,
                  xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY || ' for Agent: ' ,
                  p_cnv_hdr_rec.batch_id,
                  p_cnv_hdr_rec.record_number,
                  p_cnv_hdr_rec.legacy_po_number,
                  p_agent_name
               );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               xx_emf_pkg.write_log (
                  xx_emf_cn_pkg.CN_LOW,
                  'Error in Agent Validation: ' || SQLERRM
               );
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                                 xx_emf_cn_pkg.CN_STG_DATAVAL,
                                 'Error in Agent Validation: ' || SQLERRM,
                                 p_cnv_hdr_rec.batch_id,
                                 p_cnv_hdr_rec.record_number,
                                 p_cnv_hdr_rec.legacy_po_number,
                                 G_DOCUMENT_TYPE_CODE
                                 );
               RETURN x_error_code;
         END;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
               'Agent validation => SUCCESS::Agent Name: '
            || p_agent_name
            || ' Agent ID: '
            || p_agent_id
         );
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF x_error_code = xx_emf_cn_pkg.CN_SUCCESS
            THEN
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
                  xx_emf_cn_pkg.CN_MEDIUM,
                  xx_emf_cn_pkg.CN_STG_DATAVAL,
                     xx_emf_cn_pkg.CN_EXP_UNHAND
                  || ' in Agent Validation: '
                  || SQLERRM,
                  p_cnv_hdr_rec.batch_id,
                  p_cnv_hdr_rec.record_number,
                  p_cnv_hdr_rec.legacy_po_number,
                  G_DOCUMENT_TYPE_CODE
               );
            END IF;

            RETURN x_error_code;
      END is_agent_name_valid;

 /**
 * FUNCTION is_vendor_name_valid
 *
 * DESCRIPTION
 *     Function to find legacy Vendor is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_vendor_number              Vendor Number
 *   OUT:
 *      p_vendor_name                Derived Vendor Name.
 *      p_vendor_id                  Derived Vendor Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_vendor_name_valid (
         p_vendor_number   IN OUT VARCHAR2,
         p_source_system_name IN VARCHAR2,                 -- Added on 20-sep-2012
         p_vendor_name        OUT ap_suppliers.vendor_name%TYPE,
         p_vendor_id          OUT VARCHAR2
      )
         RETURN NUMBER
      IS
         p_ven_num  VARCHAR2(100);
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
        p_ven_num := Null;
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for vendor Number: ' || p_vendor_number
         );
         --Added as per Wave2
         BEGIN
            SELECT sup.segment1,
                   sup.vendor_name,
                   sup.vendor_id
              INTO p_ven_num,
                   p_vendor_name,
                   p_vendor_id
              FROM ap_suppliers sup
             WHERE xx_po_conv_ven(sup.attribute1,sup.attribute2,p_source_system_name)= p_vendor_number
	       AND sup.end_date_active is null
               AND ROWNUM = 1;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
            SELECT sup.segment1,
                   sup.vendor_name,
                   sup.vendor_id
              INTO p_ven_num,
                   p_vendor_name,
                   p_vendor_id
              FROM ap_suppliers sup
             WHERE sup.segment1 = p_vendor_number
               AND ROWNUM = 1;
         END;
          p_vendor_number :=   p_ven_num;


         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Derived Vendor Number: ' || p_vendor_number);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Derived Vendor Name: ' || p_vendor_name);
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Derived Vendor ID: ' || p_vendor_id);
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Vendor: ' || p_vendor_number
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_NO_DATA || ' for Vendor: ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_vendor_number
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'TOOMANY for Vendor: ' );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Vendor: '
               || p_vendor_number,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_vendor_number
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in Vendor Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                              xx_emf_cn_pkg.CN_STG_DATAVAL,
                              'Error in Vendor Validation: ' || SQLERRM,
                              p_cnv_hdr_rec.batch_id,
                              p_cnv_hdr_rec.record_number,
                              p_cnv_hdr_rec.legacy_po_number,
                              G_DOCUMENT_TYPE_CODE
                              );
            RETURN x_error_code;
      END is_vendor_name_valid;

 /**
 * FUNCTION is_vendor_site_code_valid
 *
 * DESCRIPTION
 *     Function to find legacy Vendor site is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *      p_organization_id            Org ID
 *      p_vendor_number              Vendor Number
 *   IN/OUT:
 *      p_vendor_site_code           Vendor site code.
 *   OUT:
 *      p_vendor_site_id             Derived Vendor Site Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_vendor_site_code_valid (
         p_vendor_site_code   IN OUT VARCHAR2,
         p_vendor_site_id        OUT NUMBER,
         p_organization_id    IN     NUMBER,
         p_vendor_id          IN     NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for vendor site code: ' || p_vendor_site_code
         );
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Vendor ID: ' || p_vendor_id
         );
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for vendor site code: Organization ID'
            || p_organization_id
         );

         SELECT vendor_site_code,--MAX (vendor_site_code),
                vendor_site_id--MAX (vendor_site_id)
           INTO p_vendor_site_code, p_vendor_site_id
           FROM ap_supplier_sites_all--po_vendor_sites_all
          WHERE vendor_id = p_vendor_id
            AND vendor_site_code = NVL (p_vendor_site_code, vendor_site_code)
            AND org_id = nvl(p_organization_id, org_id)
            AND purchasing_site_flag = 'Y'
            AND SYSDATE < NVL (inactive_date, SYSDATE + 1)
            AND NVL (rfq_only_site_flag, 'N') <> 'Y'
            AND rownum = 1;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived vendor site code: ' || p_vendor_site_code
         );
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived vendor site id: ' || p_vendor_site_id
         );
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Vendor Site: ' || p_vendor_site_code
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Vendor Site: ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_vendor_site_code
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Vendor Site: ' || p_vendor_site_code
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Vendor Site Code: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_vendor_site_code
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Vendor Site Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                              xx_emf_cn_pkg.CN_STG_DATAVAL,
                              'Error in Vendor Site Validation: ' || SQLERRM,
                              p_cnv_hdr_rec.batch_id,
                              p_cnv_hdr_rec.record_number,
                              p_cnv_hdr_rec.legacy_po_number,
                              G_DOCUMENT_TYPE_CODE
                              );
            RETURN x_error_code;
      END is_vendor_site_code_valid;

/**
 * FUNCTION is_ship_to_location_valid
 *
 * DESCRIPTION
 *     Function to find legacy ship to location is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_ship_to_location           Location code.
 *   OUT:
 *      p_ship_to_location_id        Derived Location Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_ship_to_location_valid (
         p_ship_to_location      IN OUT VARCHAR2,
         p_ship_to_location_id      OUT NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Ship to Location: ' || p_ship_to_location
         );

        IF p_ship_to_location IS NOT NULL
            THEN
         SELECT ship_to_location_id, location_code
           INTO p_ship_to_location_id, p_ship_to_location
           FROM hr_locations_all
          WHERE UPPER (location_code) = UPPER (p_ship_to_location)
            AND ship_to_site_flag = 'Y'
            AND NVL (inactive_date, SYSDATE + 1) >= SYSDATE;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived Ship to Location ID: ' || p_ship_to_location_id
         );
        ELSE
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Ship To Location is NULL '
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  'Ship To Location is NULL ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_ship_to_location
            );
            RETURN x_error_code;
        END IF;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Ship To Location: ' || p_ship_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Ship to Location: ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_ship_to_location
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Ship To Location: ' || p_ship_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Ship to Location: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_ship_to_location
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Ship To Location Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Ship to Location Validation: ' || SQLERRM,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_ship_to_location_valid;


/**
 * FUNCTION is_bill_to_location_valid
 *
 * DESCRIPTION
 *     Function to find legacy bill to location is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_bill_to_location           Location code.
 *   OUT:
 *      p_bill_to_location_id        Derived Location Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_bill_to_location_valid (
         p_bill_to_location      IN OUT hr_locations_all.location_code%TYPE,
         p_bill_to_location_id      OUT VARCHAR2,
         p_org_id                IN     NUMBER,
         p_vendor_site_id        IN     NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code          NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Bill to Location: ' || p_bill_to_location
         );

        IF p_bill_to_location IS NOT NULL THEN

         SELECT ship_to_location_id, location_code
           INTO p_bill_to_location_id, p_bill_to_location
           FROM hr_locations_all
          WHERE UPPER (location_code) = UPPER (p_bill_to_location)
            AND bill_to_site_flag = 'Y'
            AND NVL (inactive_date, SYSDATE + 1) >= SYSDATE;
        ELSE

          SELECT hl.location_id,
                 hl.location_code
            INTO p_bill_to_location_id,
                 p_bill_to_location
            FROM ap_supplier_sites_all aps,
                 hr_locations_all hl
           WHERE aps.vendor_site_id = p_vendor_site_id
             AND aps.bill_to_location_id = hl.location_id;

         /*SELECT fs.bill_to_location_id,hl.location_code
           INTO p_bill_to_location_id, p_bill_to_location
           FROM financials_system_params_all fs,
                org_organization_definitions ood,
                hr_locations_all hl
          WHERE fs.inventory_organization_id = ood.organization_id
            AND fs.org_id = p_org_id
            AND hl.location_id =   fs.bill_to_location_id
            AND hl.bill_to_site_flag = 'Y'
            AND NVL (hl.inactive_date, SYSDATE + 1) >= SYSDATE;*/

        END IF;
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived Bill to Location: ' || p_bill_to_location
         );

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived bill to Location ID: ' || p_bill_to_location_id
         );
        RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Bill To Location: ' || p_bill_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Bill to Location: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_bill_to_location
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Bill To Location: ' || p_bill_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Bill to Location: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_bill_to_location
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Bill To Location Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Bill to Location Validation: ' || SQLERRM,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_bill_to_location_valid;

/**
 * FUNCTION is_terms_name_valid
 *
 * DESCRIPTION
 *     Function to find legacy payment terms is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_terms_name                 Terms Name.
 *   OUT:
 *      p_terms_id                   Derived Term Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_terms_name_valid (
         p_terms_name   IN OUT        ap_suppliers_int.terms_name%TYPE,
         p_terms_id        OUT NOCOPY NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_term_name    VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Payment Terms: ' || p_terms_name
         );

         IF p_terms_name IS NOT NULL
         THEN
            x_term_name :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'PAYMENT_TERM',
                  p_source           => NULL,
                  p_old_value1        => p_terms_name,
                  p_old_value2        => 'AP',
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Payment Terms Name: ' || x_term_name
            );

            SELECT term_id
              INTO p_terms_id
              FROM ap_terms_tl
             WHERE upper(name) = upper(x_term_name)
               AND enabled_flag = 'Y'
               AND language = 'US'
               AND NVL(end_date_active,SYSDATE+1) >= SYSDATE;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived Payment Terms ID: ' || p_terms_id);
            p_terms_name := initcap(x_term_name);
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Payment Terms: ' || p_terms_name);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Payment Terms: ' || p_terms_name
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Payment Terms: ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_terms_name
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Payment Terms: ' || p_terms_name
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Payment Terms: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_terms_name
            );

            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Payment Terms Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Payment Terms Validation: ' || SQLERRM,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_terms_name_valid;

/**
 * FUNCTION is_freight_carrier_valid
 *
 * DESCRIPTION
 *     Function to find legacy freight carrier is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_freight_carrier            Freight carrier.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_freight_carrier_valid (
         p_freight_carrier   IN OUT wsh_carriers.freight_code%TYPE,
         p_ship_to_loc_id    IN NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_freight_carrier   VARCHAR2 (50);
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Freight Carriers: ' || p_freight_carrier
         );

         IF p_freight_carrier IS NOT NULL
         THEN

            x_freight_carrier :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'SHIP_VIA',
                  p_source           => NULL,
                  p_old_value        => p_freight_carrier,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived freight carrier: ' || x_freight_carrier
            );
            select freight_code
            INTO   p_freight_carrier
            from org_freight_code_val_v
            where organization_id = (SELECT inventory_organization_id FROM  PO_LOCATIONS_VAL_V where location_id = p_ship_to_loc_id)
            and freight_code = x_freight_carrier;
         ELSE
            p_freight_carrier := NULL;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Freight Carrier Code: ' || p_freight_carrier);
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Freight Carrier: ' || p_freight_carrier
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Freight Carrier: ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_freight_carrier
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Freight Carrier: ' || p_freight_carrier
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Freight Carrier: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
              p_freight_carrier
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Freight Carrier Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Freight Carrier Validation: ' || SQLERRM,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_freight_carrier_valid;

/**
 * FUNCTION is_fob_code_valid
 *
 * DESCRIPTION
 *     Function to find legacy FOB is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_fob_code                   FOB Code.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_fob_code_valid (
         p_fob_code   IN OUT fnd_lookup_values.lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_fob_code     VARCHAR2(240);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Validation for FOB: ' || p_fob_code);

         IF p_fob_code IS NOT NULL
         THEN
            x_fob_code :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'FOB_POINT',
                  p_source           => NULL,
                  p_old_value        => p_fob_code,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived fob code: ' || x_fob_code
            );

            SELECT DISTINCT lookup_code
              INTO p_fob_code
              FROM fnd_lookup_values
             WHERE upper(lookup_code) = upper(x_fob_code)
               AND lookup_type = 'FOB'
               AND enabled_flag = 'Y'
               AND language = 'US'
               AND VIEW_APPLICATION_ID = 201
               AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived FOB: ' || p_fob_code);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'NO DATA FOUND for FOB: ' || p_fob_code);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_NO_DATA || ' for FOB: ',
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_fob_code
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Toomany for FOB: ' || p_fob_code);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_TOO_MANY || ' for FOB: ' ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_fob_code
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in FOB Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                              xx_emf_cn_pkg.CN_STG_DATAVAL,
                              'Error in FOB Validation: ' || SQLERRM,
                              p_cnv_hdr_rec.batch_id,
                              p_cnv_hdr_rec.record_number,
                              p_cnv_hdr_rec.legacy_po_number,
                              G_DOCUMENT_TYPE_CODE
                              );
            RETURN x_error_code;
      END is_fob_code_valid;

/**
 * FUNCTION is_freight_terms_valid
 *
 * DESCRIPTION
 *     Function to find legacy freight terms is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_freight_terms              Freight Terms.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_freight_terms_valid (
         p_freight_terms   IN OUT NOCOPY fnd_lookup_values.lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
         x_freight_terms   VARCHAR2 (60);
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Freight Terms: ' || p_freight_terms
         );

         IF p_freight_terms IS NOT NULL
         THEN

            x_freight_terms :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'FREIGHT_TERMS',
                  p_source           => NULL,
                  p_old_value        => p_freight_terms,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived freight terms: ' || x_freight_terms
            );

            SELECT lookup_code
              INTO p_freight_terms
              FROM fnd_lookup_values
             WHERE upper(lookup_code) = upper(x_freight_terms)
               AND lookup_type = xx_emf_cn_pkg.cn_freight_terms_code
               AND enabled_flag = 'Y'
               AND language = 'US'
               AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Freight Terms Code: ' || p_freight_terms);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Freight Terms: ' || p_freight_terms);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Freight Terms: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               p_freight_terms
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Freight Terms: ' || p_freight_terms
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Freight Terms: '
               ,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
              p_freight_terms
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Freight Terms Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Freight Terms Validation: ' || SQLERRM,
               p_cnv_hdr_rec.batch_id,
               p_cnv_hdr_rec.record_number,
               p_cnv_hdr_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_freight_terms_valid;

/**
 * FUNCTION is_approval_status_valid
 *
 * DESCRIPTION
 *     Function to find legacy Approval Status is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_approval_status            Approval Status Code.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_approval_status_valid (p_approval_status IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_approval_status VARCHAR2(100) := 'APPROVED';

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Approval Status: ' || p_approval_status
         );

         p_approval_status := x_approval_status;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived Approval Status: ' || p_approval_status
         );

         RETURN x_error_code;
      END is_approval_status_valid;

/**
 * FUNCTION legacy_po_mand
 *
 * DESCRIPTION
 *     Function to find legacy PO Number is valid or not.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_legacy_po                  Legacy po Number.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION legacy_po_mand (p_legacy_po IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Legacy PO Number: ' || p_legacy_po
         );

         IF p_legacy_po IS NOT NULL
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Legacy PO Number is NULL');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                              xx_emf_cn_pkg.CN_STG_DATAVAL,
                              'Legacy PO Number is NULL',
                              p_cnv_hdr_rec.batch_id,
                              p_cnv_hdr_rec.record_number,
                              p_cnv_hdr_rec.legacy_po_number,
                              G_DOCUMENT_TYPE_CODE
                              );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      END legacy_po_mand;
   -- Start of the main function data_validations
   -- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Header Level Data-Validations');

      x_error_code_temp :=
         get_operating_unit (p_cnv_hdr_rec.organization_code,p_cnv_hdr_rec.org_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code); -- Changed on 28-SEP-2012

      x_error_code_temp := check_po_number (p_cnv_hdr_rec.legacy_po_number,p_cnv_hdr_rec.org_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := is_po_line_exist (p_cnv_hdr_rec.legacy_po_number);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_document_type_valid (p_cnv_hdr_rec.document_type_code);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_currency_code_valid (p_cnv_hdr_rec.org_id,p_cnv_hdr_rec.currency_code);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_conversion_type_valid (p_cnv_hdr_rec.rate_type,
                                   p_cnv_hdr_rec.rate_date,
                                   p_cnv_hdr_rec.rate,
                                   p_cnv_hdr_rec.currency_code,
                                   p_cnv_hdr_rec.org_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_agent_name_valid (p_cnv_hdr_rec.agent_name,
                              p_cnv_hdr_rec.agent_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_vendor_name_valid (p_cnv_hdr_rec.vendor_number,
                               p_cnv_hdr_rec.source_system_name, -- Added on 20-sep-2012
                               p_cnv_hdr_rec.vendor_name,
                               p_cnv_hdr_rec.vendor_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_vendor_site_code_valid (p_cnv_hdr_rec.vendor_site_code,
                                    p_cnv_hdr_rec.vendor_site_id,
                                    p_cnv_hdr_rec.org_id,
                                    p_cnv_hdr_rec.vendor_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_ship_to_location_valid (p_cnv_hdr_rec.ship_to_location,
                                    p_cnv_hdr_rec.ship_to_location_id
                                   );
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_bill_to_location_valid (p_cnv_hdr_rec.bill_to_location,
                                    p_cnv_hdr_rec.bill_to_location_id,
                                    p_cnv_hdr_rec.org_id,
                                    p_cnv_hdr_rec.vendor_site_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_terms_name_valid (p_cnv_hdr_rec.payment_terms,
                              p_cnv_hdr_rec.terms_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_freight_carrier_valid (p_cnv_hdr_rec.freight_carrier,p_cnv_hdr_rec.ship_to_location_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := is_fob_code_valid (p_cnv_hdr_rec.fob);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_freight_terms_valid (p_cnv_hdr_rec.freight_terms);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_approval_status_valid (p_cnv_hdr_rec.approval_status);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := legacy_po_mand (p_cnv_hdr_rec.legacy_po_number);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Completed Header Level Data-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
   END data_validations_hdr;
-- End of Header Level Data-Validations

/**
 * FUNCTION data_validations_line
 *
 * DESCRIPTION
 *     Function Line Level Data Validation.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_cnv_line_rec               Line Record type variable.
 *   OUT:
 *   RETURN:                         Error Code.
 */

   FUNCTION data_validations_line (
      p_cnv_line_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_LINE_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      l_org_id            NUMBER ;

/**
 * FUNCTION get_document_type
 *
 * DESCRIPTION
 *     Function to get document type code.
 *
 * ARGUMENTS
 *   IN:
 *      p_legacy_po_number           Legacy PO Number.
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION get_document_type (p_legacy_po_number IN VARCHAR2)
         RETURN CHAR
      IS
         x_doc_type   VARCHAR2 (25);
      BEGIN
         SELECT   document_type_code
           INTO   x_doc_type
           FROM   xx_po_headers_stg
          WHERE   legacy_po_number = p_legacy_po_number;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived Document Type for Line: ' || x_doc_type
         );
         RETURN x_doc_type;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END get_document_type;
/**
 * FUNCTION check_po_number
 *
 * DESCRIPTION
 *     Function to find whether the legacy po has converted or not to R12.
 *
 * ARGUMENTS
 *   IN:
 *      p_legacy_po_number           Legacy PO Number.
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION check_po_number (p_legacy_po_number IN VARCHAR2)
         RETURN CHAR
      IS
         x_po_num       VARCHAR2 (50) := NULL;
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         SELECT   segment1
           INTO   x_po_num
           FROM   po_headers_all
          WHERE   vendor_order_num = p_legacy_po_number
          AND    org_id = G_ORG_ID;                    --- Changed on 28-SEP-2012

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
               'Derived Existing PO Number : '
            || NVL (x_po_num, 'is null')
            || ' For Legacy PO Number:'
            || p_legacy_po_number
         );

         IF x_po_num IS NULL
         THEN
            xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
               'PO Number does not exist'
         );
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'PO Record already Exist in Oracle for Legacy PO number: '
               || p_legacy_po_number
            );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Existing PO Number in ORACLE: ' || x_po_num
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;

            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END check_po_number;

/**
 * FUNCTION is_po_dist_exist
 *
 * DESCRIPTION
 *     Find whether the Legacy PO Line has a Distribution Line or not.
 *
 * ARGUMENTS
 *   IN:
 *     p_legacy_po_number             Legacy PO Number.
 *
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_po_dist_exist (p_legacy_po_number IN VARCHAR2,p_line_num NUMBER,p_batch_id VARCHAR,p_shipment_num NUMBER)
         RETURN CHAR
      IS
         x_line_count   NUMBER;
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         SELECT COUNT ( * )
           INTO x_line_count
           FROM xx_po_distributions_stg
          WHERE attribute2 = p_legacy_po_number
            AND line_num = p_line_num
            AND SHIPMENT_NUM = p_shipment_num
            AND batch_id = p_batch_id;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
               'PO Distribution Line(s) validation for Legacy PO Number:'
            || p_legacy_po_number||' '||x_line_count||' Line Num '||p_line_num||'Batch ID '||p_batch_id
         );

         IF x_line_count > 0
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'There should be at least one distribution line per document line: '
               || 'Line_Num: '||p_cnv_line_rec.line_num
               || ' Legacy_PO_Number: '||p_legacy_po_number
            );

            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'There should be at least one distribution line per document line: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_cnv_line_rec.line_num
            );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END is_po_dist_exist;

/**
 * FUNCTION is_po_line_no_valid
 *
 * DESCRIPTION
 *     Function to find whether the legacy po line no is valid or not.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_line_no                    PO Line Number
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_po_line_no_valid (p_line_no IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for PO Line Number: ' || p_line_no
         );

         IF p_line_no IS NOT NULL
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'PO Line Number cannot be NULL');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'PO Line Number cannot be NULL',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      END is_po_line_no_valid;

/**
 * FUNCTION is_po_line_type_valid
 *
 * DESCRIPTION
 *     Function to find whether the legacy po line type is valid or not.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_po_line_type               PO Line type
 *   OUT:
 *      p_po_line_type_id            PO Line type Id
 *   RETURN:                         Error Code.
 */
      FUNCTION is_po_line_type_valid (
         p_po_line_type      IN OUT po_line_types.line_type%TYPE,
         p_po_line_type_id      OUT NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_line_type    VARCHAR2 (25);
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for PO Line Type: ' || p_po_line_type
         );

         IF p_po_line_type IS NOT NULL
         THEN
            x_line_type :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'PO_LINE_TYPE',
                  p_source           => NULL,
                  p_old_value        => p_po_line_type,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived PO Line Type: ' || x_line_type);

            SELECT   line_type, line_type_id
              INTO   p_po_line_type, p_po_line_type_id
              FROM   po_line_types
             WHERE   UPPER (line_type) = UPPER (x_line_type);

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived PO Line Type: ' || p_po_line_type);
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived PO Line Type ID: ' || p_po_line_type_id
            );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for PO Line Type: ' || p_po_line_type
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for PO Line Type: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
                p_po_line_type
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for PO Line Type: ' || p_po_line_type
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for PO Line Type: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_po_line_type
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in PO Line Type Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in PO Line Type Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_po_line_type_valid;

/**
 * FUNCTION is_po_line_qty_valid
 *
 * DESCRIPTION
 *     Function to find whether the legacy po line quantity is valid or not.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_po_line_qty               PO Line qty
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_po_line_qty_valid (
         p_po_line_qty      IN NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

      BEGIN

         IF nvl(p_po_line_qty, 0) <= 0
          THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'PO Line Quantity should be greater than Zero: '
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'PO Line Quantity should be greater than Zero: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in PO Line Quantity Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in PO Line Quantity Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_po_line_qty_valid;

------------------------
FUNCTION is_po_line_dist_qty_valid (
                                    p_po_line_qty      IN NUMBER,
                                    p_po_line_num      IN NUMBER,
                                    p_legacy_po_number IN VARCHAR2,
                                    p_shipment_num     IN NUMBER
                                   )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_dist_qty     NUMBER;
         x_line_qty     NUMBER;

      BEGIN

        SELECT SUM(quantity_ordered)
          INTO x_dist_qty
          FROM xx_po_distributions_stg
         WHERE attribute2 = p_legacy_po_number
           AND batch_id = p_cnv_line_rec.batch_id
           AND shipment_num = p_shipment_num
           AND line_num = p_po_line_num;

        SELECT SUM(quantity)
          INTO x_line_qty
          FROM xx_po_lines_stg
         WHERE legacy_po_number = p_legacy_po_number
           AND line_num = p_po_line_num
           AND SHIPMENT_NUM = p_shipment_num;

         IF nvl(x_line_qty, 0) <> nvl(x_dist_qty,0)
          THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'PO Line Quantity and Sum of PO Distribution Quantity miss matched of Line Num: '||p_po_line_num
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'PO Line Quantity and Sum of PO Distribution Quantity miss matched of Line Num: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_po_line_num
            );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'PO Line Quantity and Sum of PO Distribution Quantity miss matched of Line Num: '||p_po_line_num
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || 'PO Line Quantity and Sum of PO Distribution Quantity miss matched of Line Num: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_po_line_num
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in PO Line and Distribution Quantity Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in PO Line and Distribution Quantity Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_po_line_dist_qty_valid;
------------------------
/**
 * FUNCTION is_shipment_num_valid
 *
 * DESCRIPTION
 *     Function to find whether the shipment number is valid or not.
 *
 * ARGUMENTS
 *   IN:
 *      p_line_no                    PO Line Number
 *   IN/OUT:
 *      p_shipment_num               PO shipment number
 *   OUT:
 *      p_shipment_type              PO Shipment Type
 *   RETURN:                         Error Code.
 */
      FUNCTION is_shipment_num_valid (p_shipment_num    IN OUT VARCHAR2,
                                      p_line_no         IN VARCHAR2,
                                      p_shipment_type   OUT VARCHAR2
                                     )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         IF get_document_type (p_cnv_line_rec.legacy_po_number) = 'BLANKET'
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Validation for Shipment Number: ' || p_shipment_num
            );

               p_shipment_num   := p_line_no ||'.'||p_shipment_num;
                                   --XX_EMF_PKG.get_paramater_value('XXINTGPOOPENPOCNV','PO_SHIPMENT_NUM');
               p_shipment_type  := XX_EMF_PKG.get_paramater_value('XXINTGPOOPENPOCNV','PO_SHIPMENT_TYPE');

               xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Shipment Number: ' || p_shipment_num);
               xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Shipment Type: ' || p_shipment_type);
            RETURN x_error_code;

         END IF;

         RETURN x_error_code;
      EXCEPTION
        WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in Shipment Number and Shipment Type Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Shipment Number and Shipment Type Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_shipment_num_valid;

/**
 * FUNCTION is_item_number_valid
 *
 * DESCRIPTION
 *     Function to find whether the Item is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_legacy_item_number         legacy item number
 *      p_item_description           Inventory Item Description
 *   OUT:
 *      p_inventory_item_id          Inventory Item Id
 *   RETURN:                         Error Code.
 */
      FUNCTION is_item_number_valid (p_legacy_item_number   IN OUT VARCHAR2,
                                     p_inventory_item_id       OUT NUMBER,
                                     p_item_description     IN OUT VARCHAR2,
                                     p_ship_to_organization_id  IN NUMBER,
                                     p_ship_to_organization     IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         --x_err_code     VARCHAR2 (30);
         --x_err_msg      VARCHAR2 (200);
         x_item         VARCHAR2(250);
         ITEM_NO_DATA_FOUND EXCEPTION;

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Item: Legacy Inventory item: '
            || p_legacy_item_number
         );

         IF p_legacy_item_number IS NOT NULL
         THEN
            SELECT segment1, description, inventory_item_id
              INTO p_legacy_item_number,
                   p_item_description,
                   p_inventory_item_id
              FROM mtl_system_items_b
             WHERE segment1 = p_legacy_item_number
               AND organization_id IN
                         (SELECT DISTINCT master_organization_id
                            FROM mtl_parameters)
               AND enabled_flag = 'Y'
               AND purchasing_item_flag = 'Y';

            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Inventory Item: ' || p_legacy_item_number
            );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Inventory Item Description: ' || p_item_description
            );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Inventory Item ID: ' || p_inventory_item_id
            );

            -----  ORG Check -------
           BEGIN
            SELECT segment1
              INTO x_item
              FROM mtl_system_items_b
             WHERE segment1 = p_legacy_item_number
               AND organization_id = p_ship_to_organization_id
               AND enabled_flag = 'Y'
               AND purchasing_item_flag = 'Y';

            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Inventory Item: ' || x_item ||' for assigned organization: '||p_ship_to_organization);

           EXCEPTION
            WHEN NO_DATA_FOUND
             THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Item: ' || p_legacy_item_number || ' is not assigned to the Organization: '||p_ship_to_organization
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' Item: is not assigned to the Organization: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
                p_legacy_item_number||'-'||p_ship_to_organization
            );
            RETURN x_error_code;
            WHEN OTHERS
             THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in Item assigned Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Item assigned Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
           END;
            ------Check For OSP Item-----
           BEGIN
            SELECT segment1
              INTO x_item
              FROM mtl_system_items_b
             WHERE segment1 = p_legacy_item_number
               AND organization_id = p_ship_to_organization_id
               AND enabled_flag = 'Y'
               AND purchasing_item_flag = 'Y'
               AND outside_operation_flag = 'N';

            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived OSP Item: ' || x_item );

           EXCEPTION
            WHEN NO_DATA_FOUND
             THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Item: ' || p_legacy_item_number ||
               ' is a OSP Item, Hence can not be Purchase, Line Num: '||p_cnv_line_rec.line_num
               ||' Legacy PO Number: '||p_cnv_line_rec.legacy_po_number
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_NO_DATA|| ' Item: is an OSP Item, Hence can not be Purchased  ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_legacy_item_number
            );
            RETURN x_error_code;
            WHEN OTHERS
             THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in OSP Item Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in OSP Item Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_legacy_item_number
            );
            RETURN x_error_code;
           END;
            ------

         ELSIF p_legacy_item_number IS NULL AND p_item_description IS NOT NULL
            THEN
            p_item_description := p_item_description;
         ELSE
            RAISE ITEM_NO_DATA_FOUND;
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Item: ' || p_legacy_item_number
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Item: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_legacy_item_number
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOO MANY for Item: ' || p_legacy_item_number
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Item: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_legacy_item_number
            );
            RETURN x_error_code;
         WHEN ITEM_NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Item or Description should not be null'
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_NO_DATA
               || ' Item or Item Description should not be NULL for Line Number: '
               ||p_cnv_line_rec.line_num,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in Item Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Item Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_item_number_valid;

--Issue #2093 start

/**
 * FUNCTION is_item_revision_valid
 *
 * DESCRIPTION
 *     Function to find whether the Item revision is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *      p_item_revision
 *      p_item_id
 *      p_ship_to_organization_id
 *   RETURN:                         Error Code.
 */

FUNCTION is_item_revision_valid (    p_inventory_item_id       IN NUMBER,
                                     p_ship_to_organization_id  IN NUMBER,
                                     p_item_revision     IN VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_revision     VARCHAR2 (3);

    BEGIN
                 xx_emf_pkg.write_log (
	             xx_emf_cn_pkg.CN_LOW,
	             'Validation for Item Revision: p_item_revision '
	             || p_item_revision
         );

       IF p_item_revision IS NOT NULL
       THEN
           BEGIN
            SELECT revision
             INTO X_REVISION
             FROM MTL_ITEM_REVISIONS
             WHERE INVENTORY_ITEM_ID = p_inventory_item_id --121389
             AND ORGANIZATION_ID = p_ship_to_organization_id --2101
             AND EFFECTIVITY_DATE = (SELECT MAX(EFFECTIVITY_DATE) FROM MTL_ITEM_REVISIONS WHERE INVENTORY_ITEM_ID = p_inventory_item_id AND ORGANIZATION_ID = p_ship_to_organization_id)
             and revision = nvl(p_item_revision,revision);

         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Derived revision: ' || x_revision);
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived revision ' || p_item_revision
         );

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'NO DATA FOUND for Revision: ' || p_item_revision);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_NO_DATA || ' for Revision: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_item_revision
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'TOOMANY for revision: ' || p_item_revision);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_TOO_MANY || ' for Revision: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_item_revision
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in Item Revision Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in UOM Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_item_revision
            );
            RETURN x_error_code;
            END;
            END IF;
            RETURN x_error_code;
      END is_item_revision_valid;

--Issue #2093 End

/**
 * FUNCTION is_uom_valid
 *
 * DESCRIPTION
 *     Function to find whether the Item is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_uom_code                   legacy UOM Code
 *   OUT:
 *      p_unit_of_measure            UOM Code
 *   RETURN:                         Error Code.
 */
      FUNCTION is_uom_valid (p_uom_code          IN OUT VARCHAR2,
                             p_unit_of_measure      OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_uom_code     VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Validation for UOM Code: ' || p_uom_code);

        --IF p_uom_code IS NOT NULL
            --THEN
         x_uom_code :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'PRIMARY_UOM',
                  p_source           => NULL,
                  p_old_value        => p_uom_code,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived UOM Code: ' || x_uom_code
            );

         SELECT uom_code, unit_of_measure
           INTO p_uom_code, p_unit_of_measure
           FROM mtl_units_of_measure
          WHERE UPPER (uom_code) = UPPER (x_uom_code)
            AND TRUNC (NVL (disable_date, SYSDATE)) >= TRUNC (SYSDATE);

         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Derived UOM Code: ' || p_uom_code);
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived Unit of Measure: ' || p_unit_of_measure
         );
        --END IF;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'NO DATA FOUND for UOM: ' || p_uom_code);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_NO_DATA || ' for UOM: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_uom_code
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'TOOMANY for UOM: ' || p_uom_code);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_TOO_MANY || ' for UOM: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_uom_code
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in UOM Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in UOM Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_uom_valid;

/**
 * FUNCTION is_terms_name_valid
 *
 * DESCRIPTION
 *     Function to find whether the payment terms is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_terms_name                 Payment Term.
 *   OUT:
 *      p_terms_id                   Term Id
 *   RETURN:                         Error Code.
 */
      FUNCTION is_terms_name_valid (
         p_terms_name   IN OUT        ap_suppliers_int.terms_name%TYPE,
         p_terms_id     OUT NOCOPY NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_term_name    VARCHAR2 (40);
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Payment Terms: ' || p_terms_name
         );

         IF p_terms_name IS NOT NULL
         THEN
            x_term_name :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'PAYMENT_TERM',
                  p_source           => NULL,
                  p_old_value1        => p_terms_name,
                  p_old_value2        => 'AP',
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Payment Terms Name: ' || x_term_name
            );

            SELECT term_id
              INTO p_terms_id
              FROM ap_terms_tl
             WHERE upper(name) = upper(x_term_name)
               AND enabled_flag = 'Y'
               AND language = 'US'
               AND NVL(end_date_active,SYSDATE+1) >= SYSDATE;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived Payment Terms ID: ' || p_terms_id);
            p_terms_name := x_term_name;
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Payment Terms: ' || p_terms_name);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Payment Terms: ' || p_terms_name
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Payment Terms: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_terms_name
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Payment Terms: ' || p_terms_name
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Payment Terms: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_terms_name
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Payment Terms Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Payment Terms Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_terms_name_valid;

/**
 * FUNCTION is_ship_to_organization_valid
 *
 * DESCRIPTION
 *     Function to find whether the ship to organization is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *      p_org_id                     ORG ID
 *   IN/OUT:
 *      p_ship_to_organization       Inventory Organization.
 *   OUT:
 *      p_ship_to_organization_id    Inventory Organization Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_ship_to_organization_valid (
         p_ship_to_organization      IN OUT VARCHAR2,
         p_ship_to_organization_id      OUT NUMBER,
         p_org_id                    IN     NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code           NUMBER := xx_emf_cn_pkg.cn_success;
         x_ship_to_organization VARCHAR2 (60);

      BEGIN
         IF p_ship_to_organization IS NOT NULL
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Validation for Ship to Organization: '
               || p_ship_to_organization
            );

            x_ship_to_organization :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'ORGANIZATION_CODE',
                  p_source           => NULL,
                  p_old_value1        => p_ship_to_organization,
                  p_old_value2        => 'XXINVITEMCOSTCNV',
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Ship to organization: ' || x_ship_to_organization
            );

            SELECT   organization_id
              INTO   p_ship_to_organization_id
              FROM   mtl_parameters
             WHERE   organization_code = x_ship_to_organization;

            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Ship to Organization: ' || p_ship_to_organization
            );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Ship to Organization ID: '
               || p_ship_to_organization_id
            );
         ELSE
            SELECT   fs.inventory_organization_id, ood.organization_code
              INTO   p_ship_to_organization_id, p_ship_to_organization
              FROM   financials_system_params_all fs,
                     org_organization_definitions ood
             WHERE   fs.inventory_organization_id = ood.organization_id
                     AND fs.org_id = p_org_id;

            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Default Ship to Organization: '
               || p_ship_to_organization
            );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Default Ship to Organization ID: '
               || p_ship_to_organization_id
            );
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Ship To Organization: '
               || p_ship_to_organization
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Ship to Organization: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_ship_to_organization
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Ship To Organization: ' || p_ship_to_organization
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Ship to Organization: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_ship_to_organization
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Ship To Organization Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Ship to Organization Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_ship_to_organization_valid;

/**
 * FUNCTION is_ship_to_location_valid
 *
 * DESCRIPTION
 *     Function to find whether the ship to location is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_ship_to_location           Location Code.
 *   OUT:
 *      p_ship_to_location_id        Location Id.
 *   RETURN:                         Error Code.
 */
      FUNCTION is_ship_to_location_valid (
         p_ship_to_location      IN OUT VARCHAR2,
         p_ship_to_location_id      OUT NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code          NUMBER := xx_emf_cn_pkg.cn_success;

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Ship to Location: ' || p_ship_to_location
         );
        IF p_ship_to_location IS NOT NULL
            THEN
         SELECT ship_to_location_id, location_code
           INTO p_ship_to_location_id, p_ship_to_location
           FROM hr_locations_all
          WHERE UPPER (location_code) = UPPER (p_ship_to_location)
            AND ship_to_site_flag = 'Y'
            AND NVL (inactive_date, SYSDATE + 1) >= SYSDATE;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived Ship to Location ID: ' || p_ship_to_location_id
         );
        END IF;
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Ship To Location: ' || p_ship_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Ship to Location: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_ship_to_location
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Ship To Location: ' || p_ship_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Ship to Location: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_ship_to_location
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Ship To Location Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Ship to Location Validation' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_ship_to_location_valid;

/**
 * FUNCTION is_freight_carrier_valid
 *
 * DESCRIPTION
 *     Function to find whether the freight carrier is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_freight_carrier            Freight Carrier.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_freight_carrier_valid (
         p_freight_carrier   IN OUT wsh_carriers.freight_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_freight_carrier   VARCHAR2(60);

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Freight Carriers: ' || p_freight_carrier
         );

         IF p_freight_carrier IS NOT NULL
         THEN

            x_freight_carrier :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'SHIP_VIA',
                  p_source           => NULL,
                  p_old_value        => p_freight_carrier,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived freight carrier: ' || x_freight_carrier
            );

            SELECT   wc.freight_code
              INTO   p_freight_carrier
              FROM   wsh_carriers wc
             WHERE   wc.freight_code = x_freight_carrier;
         ELSE
            p_freight_carrier := NULL;
         END IF;

         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Freight Carrier Code: ' || p_freight_carrier);
         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Freight Carrier: ' || p_freight_carrier
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Freight Carrier: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_freight_carrier
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Freight Carrier: ' || p_freight_carrier
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Freight Carrier: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_freight_carrier
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Freight Carrier Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Freight Carrier Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_freight_carrier_valid;

/**
 * FUNCTION is_fob_code_valid
 *
 * DESCRIPTION
 *     Function to find whether the FOB is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_fob_code                   fob code.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_fob_code_valid (
         p_fob_code   IN OUT fnd_lookup_values.lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
         x_fob_code     VARCHAR2(60);
      BEGIN
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                               'Validation for FOB: ' || p_fob_code);

         IF p_fob_code IS NOT NULL
         THEN

            x_fob_code :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'FOB_POINT',
                  p_source           => NULL,
                  p_old_value        => p_fob_code,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived fob code: ' || x_fob_code
            );

            SELECT DISTINCT lookup_code
              INTO p_fob_code
              FROM fnd_lookup_values
             WHERE upper(lookup_code) = upper(x_fob_code)
               AND lookup_type = xx_emf_cn_pkg.cn_fob_lookup_code
               AND enabled_flag = 'Y'
               AND language = 'US'
               AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Derived FOB: ' || p_fob_code);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'NO DATA FOUND for FOB: ' || p_fob_code);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_NO_DATA || ' for FOB: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_fob_code
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'TOOMANY for FOB: ' || p_fob_code);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               xx_emf_cn_pkg.CN_TOO_MANY || ' for FOB: ',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_fob_code
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Error in FOB Validation: ' || SQLERRM);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in FOB Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_fob_code_valid;

/**
 * FUNCTION is_freight_terms_valid
 *
 * DESCRIPTION
 *     Function to find whether the Freight term is valid or not in R12.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_freight_terms              freight terms.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_freight_terms_valid (
         p_freight_terms   IN OUT NOCOPY fnd_lookup_values.lookup_code%TYPE
      )
         RETURN NUMBER
      IS
         x_error_code       NUMBER := xx_emf_cn_pkg.cn_success;
         x_freight_terms    VARCHAR2(60);

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Freight Terms: ' || p_freight_terms
         );

         IF p_freight_terms IS NOT NULL
         THEN

            x_freight_terms :=
               xx_intg_common_pkg.get_mapping_value (
                  p_mapping_type     => 'FREIGHT_TERMS',
                  p_source           => NULL,
                  p_old_value        => p_freight_terms,
                  p_date_effective   => SYSDATE
               );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived freight terms: ' || x_freight_terms
            );

            SELECT lookup_code
              INTO p_freight_terms
              FROM fnd_lookup_values
             WHERE upper(lookup_code) = upper(x_freight_terms)
               AND lookup_type = xx_emf_cn_pkg.cn_freight_terms_code
               AND enabled_flag = 'Y'
               AND language = 'US'
               AND NVL (end_date_active, SYSDATE + 1) >= SYSDATE;

            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Freight Terms Code: ' || p_freight_terms);
         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for Freight Terms: ' || p_freight_terms
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for Freight Terms: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_freight_terms
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for Freight Terms: ' || p_freight_terms
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for Freight Terms: '
               ,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               p_freight_terms
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in Freight Terms Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in Freight Terms Validation: ' || SQLERRM,
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_freight_terms_valid;

/**
 * FUNCTION legacy_po_num_mand
 *
 * DESCRIPTION
 *     Function to find whether the legacy po number is valid or not.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_legacy_po_num              legacy po number.
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION legacy_po_num_mand (p_legacy_po_num IN OUT VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for Legacy PO Number: ' || p_legacy_po_num
         );

         IF p_legacy_po_num IS NOT NULL
         THEN
            RETURN x_error_code;
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Legacy PO Number is NULL');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Legacy PO Number is NULL',
               p_cnv_line_rec.batch_id,
               p_cnv_line_rec.record_number,
               p_cnv_line_rec.legacy_po_number,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      END legacy_po_num_mand;
   -- Start of the main function line data_validations
   -- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Inside Line Level Data-Validations');

      SELECT B.organization_id
      into l_org_id
      FROM XX_PO_HEADERS_STG  a, hr_operating_units b
      WHERE A.LEGACY_PO_NUMBER = p_cnv_line_rec.legacy_po_number
      and a.organization_code = b.name
      and a.batch_id = p_cnv_line_rec.batch_id;   --Added as per Wave2 09-MAR-15


      x_error_code_temp := check_po_number (p_cnv_line_rec.legacy_po_number);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := is_po_dist_exist (p_cnv_line_rec.legacy_po_number,p_cnv_line_rec.line_num,p_cnv_line_rec.batch_id,p_cnv_line_rec.shipment_num);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := is_po_line_no_valid (p_cnv_line_rec.line_num);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_po_line_type_valid (p_cnv_line_rec.line_type,
                                p_cnv_line_rec.line_type_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_po_line_qty_valid (p_cnv_line_rec.quantity);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_po_line_dist_qty_valid (p_cnv_line_rec.quantity,
                                    p_cnv_line_rec.line_num,
                                    p_cnv_line_rec.legacy_po_number,
                                    p_cnv_line_rec.shipment_num);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := is_shipment_num_valid (p_cnv_line_rec.shipment_num,
                                                  p_cnv_line_rec.line_num,
                                                  p_cnv_line_rec.shipment_type);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_uom_valid (p_cnv_line_rec.uom_code,
                       p_cnv_line_rec.unit_of_measure);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_terms_name_valid (p_cnv_line_rec.payment_terms,
                              p_cnv_line_rec.terms_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_ship_to_organization_valid (
            p_cnv_line_rec.ship_to_organization_code,
            p_cnv_line_rec.ship_to_organization_id,
            l_org_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_item_number_valid (p_cnv_line_rec.item,
                               p_cnv_line_rec.item_id,
                               p_cnv_line_rec.item_description,
                               p_cnv_line_rec.ship_to_organization_id,
                               p_cnv_line_rec.ship_to_organization_code);
      ---Issue #2093
      x_error_code_temp :=
               is_item_revision_valid (p_cnv_line_rec.item_id,
                                     p_cnv_line_rec.ship_to_organization_id,
                               p_cnv_line_rec.item_revision);
      ---Issue #2093
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_ship_to_location_valid (p_cnv_line_rec.ship_to_location,
                                    p_cnv_line_rec.ship_to_location_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_freight_carrier_valid (p_cnv_line_rec.freight_carrier);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := is_fob_code_valid (p_cnv_line_rec.fob);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_freight_terms_valid (p_cnv_line_rec.freight_terms);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         legacy_po_num_mand (p_cnv_line_rec.legacy_po_number);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Completed Line Level Data-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
   END data_validations_line;            -- End of Line Level Data-Validations

/**
 * FUNCTION data_validations_dist
 *
 * DESCRIPTION
 *     Function Distribution Level Data-Validations.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_cnv_dist_rec               Distribution Record Type Variable.
 *   OUT:
 *   RETURN:                         Error Code.
 */
   FUNCTION data_validations_dist (
      p_cnv_dist_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_DIST_REC_TYPE,
      p_acct_mapping_req VARCHAR2
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

/**
 * FUNCTION get_document_type
 *
 * DESCRIPTION
 *     Function get document type code.
 *
 * ARGUMENTS
 *   IN:
 *      p_legacy_po_number           legacy po number
 *   IN/OUT:
 *   OUT:
 *   RETURN:                         Document Type Code.
 */
      FUNCTION get_document_type (p_legacy_po_number IN VARCHAR2)
         RETURN CHAR
      IS
         x_doc_type   VARCHAR2 (25);
      BEGIN
         SELECT   document_type_code
           INTO   x_doc_type
           FROM   xx_po_headers_stg
          WHERE   legacy_po_number = p_legacy_po_number;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived Document Type for Line: ' || x_doc_type
         );
         RETURN x_doc_type;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END get_document_type;

/**
 * FUNCTION is_po_line_no_valid
 *
 * DESCRIPTION
 *     Function to validate po line no
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_line_no                    PO Line Number
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_po_line_no_valid (p_line_no IN OUT VARCHAR2,p_po_num in VARCHAR2)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         l_cnt NUMBER := 0;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for PO Line Number: ' || p_line_no
         );

         IF p_line_no IS NOT NULL
         THEN
            select count(1)
            into l_cnt
            from xx_po_lines_stg
            where legacy_po_number = p_po_num
            and line_num = p_line_no;

            IF l_cnt >=1 THEN
                RETURN x_error_code;
            ELSE
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'Line Number in Distributions does not exist in PO Lines Staging Table');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Line Number in Distributions does not exist in PO Lines Staging Table',
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_line_no
            );
            RETURN x_error_code;

            END IF;
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'PO Line Number cannot be NULL');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'PO Line Number cannot be NULL',
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_line_no
            );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      END is_po_line_no_valid;

/**
 * FUNCTION is_po_shipment_no_valid
 *
 * DESCRIPTION
 *     Function to find whether the legacy po shipment no is valid or not.
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_line_no                    PO Shipment Number
 *   OUT:
 *   RETURN:                         Error Code.
 */
      FUNCTION is_po_shipment_no_valid (p_shipment_no IN OUT VARCHAR2,p_po_num IN VARCHAR2,p_line_num in NUMBER)
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         l_cnt NUMBER :=0;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for PO Shipment Number: ' || p_shipment_no
         );

         IF p_shipment_no IS NOT NULL
         THEN
            select count(1)
            into l_cnt
            from xx_po_lines_stg
            where legacy_po_number = p_po_num
            and line_num = p_line_num
            and shipment_num = p_shipment_no;

            IF l_cnt >=1 THEN
                RETURN x_error_code;
            ELSE
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'PO Shipment Number does not exist in PO Lines Staging Table');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'PO Shipment Number does not exist in PO Lines Staging Table',
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_shipment_no
            );
            RETURN x_error_code;

            END IF;
         ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                                  'PO Shipment Number cannot be NULL');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'PO Shipment Number cannot be NULL',
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_shipment_no
            );
            RETURN x_error_code;
         END IF;

         RETURN x_error_code;
      END is_po_shipment_no_valid;

/**
 * FUNCTION is_deliver_to_location_valid
 *
 * DESCRIPTION
 *     Function to validate Delivery Location Code
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_deliver_to_location        Location Code
 *   OUT:
 *      p_deliver_to_location_id     Location ID
 *   RETURN:                         Error Code.
 */
      FUNCTION is_deliver_to_location_valid (
         p_deliver_to_location      IN OUT VARCHAR2,
         p_deliver_to_location_id      OUT NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for deliver to Location: ' || p_deliver_to_location
         );
        IF p_deliver_to_location IS NOT NULL
            THEN
         SELECT ship_to_location_id, location_code
           INTO p_deliver_to_location_id, p_deliver_to_location
           FROM hr_locations_all
          WHERE UPPER (location_code) = UPPER (p_deliver_to_location)
            AND ship_to_site_flag = 'Y'
            AND NVL (inactive_date, SYSDATE + 1) >= SYSDATE;

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived deliver to Location ID: ' || p_deliver_to_location_id
         );
        END IF;
        RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for deliver To Location: '
               || p_deliver_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for deliver to Location: ',
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_deliver_to_location,
               p_deliver_to_location
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for deliver To Location: ' || p_deliver_to_location
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for deliver to Location: '
               ,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_deliver_to_location
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in deliver To Location Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in deliver to Location Validation' || SQLERRM,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_deliver_to_location_valid;

/**
 * FUNCTION is_charge_account_valid
 *
 * DESCRIPTION
 *     Function to validate Legacy Charge Account
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_charge_account             Charge Account
 *   OUT:
 *      p_charge_account_id          Charge Account ID
 *   RETURN:                         Error Code.
 */
      FUNCTION is_charge_account_valid (
         p_legacy_po_number    IN     VARCHAR2,
         p_batch_id            IN     VARCHAR2,
         p_charge_account      IN OUT VARCHAR2,
         p_charge_account_id      OUT NUMBER,
         p_acct_map_required      IN VARCHAR2
         )
         RETURN NUMBER
      IS
         x_error_code       NUMBER := xx_emf_cn_pkg.cn_success;
         x_charge_account   VARCHAR2(2000);
         x_source           VARCHAR2(50);
         l_source_system    VARCHAR2(240);

         x_segment1 VARCHAR2(1000);
         x_segment2 VARCHAR2(1000);
         x_segment3 VARCHAR2(1000);
         x_segment4 VARCHAR2(1000);
         x_segment5 VARCHAR2(1000);
         x_segment6 VARCHAR2(1000);
         x_segment7 VARCHAR2(1000);
         x_segment8 VARCHAR2(1000);
         --l_segment1         VARCHAR2(150);
         --l_segment2         VARCHAR2(150);
         --l_segment3         VARCHAR2(150);
         --l_lookup_code      VARCHAR2(150);

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for charge account: ' || p_charge_account );
       BEGIN
        --l_lookup_code := XX_EMF_PKG.get_paramater_value('XXINTGPOOPENPOCNV','CHARGE_ACCT_LOOKUP_CODE');
          /*
          SELECT SUBSTR(p_charge_account,1,DECODE(INSTR(p_charge_account,'.',1,1),
                                                   0,
                                                   LENGTH(p_charge_account),
                                                   INSTR(p_charge_account,'.',1,1)-1))
            INTO l_segment1
            FROM dual;

          SELECT DECODE ( INSTR (p_charge_account,'.',1,1),
                          0,
                          NULL,
                          SUBSTR (p_charge_account, INSTR (p_charge_account,
                            '.',
                            1,
                            1)
                     + 1, DECODE (INSTR (p_charge_account,
                                         '.',
                                         1,
                                         2),
                                  0, LENGTH (p_charge_account),
                                  (INSTR (p_charge_account,
                                          '.',
                                          1,
                                          2))
                                  - (INSTR (p_charge_account,
                                           '.',
                                            1,
                                            1)
                                     + 1))))
            INTO l_segment2
            FROM DUAL;

          SELECT SUBSTR(p_charge_account,INSTR(p_charge_account,'.',1,2)
                      +1,DECODE(INSTR(p_charge_account,
                                      '.',
                                      1,
                                      2),
                                      0,
                                      0,LENGTH(p_charge_account)))
            INTO l_segment3
            FROM dual;
         */

      IF UPPER(p_acct_map_required) = 'Y' THEN  ------------- Account map required new CR

         SELECT source_system_name
           INTO l_source_system
           FROM xx_po_headers_stg bb
          WHERE legacy_po_number = p_legacy_po_number
            AND batch_id = p_batch_id;

         xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Source System Name: ' || l_source_system
            );

         x_source := xx_intg_common_pkg.get_mapping_value (
                        p_mapping_type     => 'LEGACY_SYSTEM',
                        p_source           => NULL,
                        p_old_value        => l_source_system,
                        p_date_effective   => SYSDATE
                      );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Source: ' || x_source
            );

            x_segment1 := substr(p_charge_account,1,(instr(p_charge_account,'-',1,1)-1));
            x_segment2 := substr(p_charge_account,(instr(p_charge_account,'-',1,1)+1),((instr(p_charge_account,'-',1,2)-instr(p_charge_account,'-',1,1)-1)));
            x_segment3 := substr(p_charge_account,(instr(p_charge_account,'-',1,2)+1),(instr(p_charge_account,'-',1,3)-instr(p_charge_account,'-',1,2)-1));
            x_segment4 := substr(p_charge_account,(instr(p_charge_account,'-',1,3)+1),(instr(p_charge_account,'-',1,4)-instr(p_charge_account,'-',1,3)-1));
            x_segment5 := substr(p_charge_account,(instr(p_charge_account,'-',1,4)+1),(instr(p_charge_account,'-',1,5)-instr(p_charge_account,'-',1,4)-1));
            x_segment6 := substr(p_charge_account,(instr(p_charge_account,'-',1,5)+1),(instr(p_charge_account,'-',1,6)-instr(p_charge_account,'-',1,5)-1));
            x_segment7 := substr(p_charge_account,(instr(p_charge_account,'-',1,6)+1),(instr(p_charge_account,'-',1,7)-instr(p_charge_account,'-',1,6)-1));
            x_segment8 := substr(p_charge_account,(instr(p_charge_account,'-',1,7)+1),(length(p_charge_account)-instr(p_charge_account,'-',1,7)));

         p_charge_account_id := xx_gl_cons_ffield_load_pkg.get_ccid(x_segment1,
                                                                    x_segment2,
                                                                    x_segment3,
                                                                    x_segment4,
                                                                    x_segment5,
                                                                    x_segment6,
                                                                    x_segment7,
                                                                    x_segment8,
                                                                    x_source,
                                                                    G_COMPONENT_NAME);

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived charge account: ' || p_charge_account );
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived charge account id: ' || p_charge_account_id );

         IF p_charge_account_id > 0 THEN
            RETURN x_error_code;
         ELSE
            RAISE NO_DATA_FOUND;
         END IF;
     ELSIF UPPER(p_acct_map_required) = 'N' THEN   ------------- Account map required new CR

           SELECT code_combination_id INTO p_charge_account_id
            FROM gl_code_combinations
            WHERE trim(segment1||'-'||segment2||'-'||segment3||'-'||segment4||'-'||segment5||'-'||segment6||'-'||segment7||'-'||segment8)= trim(p_charge_account)
                  AND rownum = 1;

            xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived charge account: ' || p_charge_account );
            xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived charge account id: ' || p_charge_account_id );
           RETURN x_error_code;
     END IF;    ------------- Account map required new CR
       EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for charge account: '
               || p_charge_account
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for charge account: '
               ,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_charge_account
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for charge account: ' || p_charge_account
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for charge account: '
               ,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_charge_account
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in charge account Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in charge account Validation' || SQLERRM,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
       END;

      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in charge account Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in charge account Validation' || SQLERRM,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_charge_account_valid;

/**
 * FUNCTION is_accural_account_valid
 *
 * DESCRIPTION
 *     Function to validate Legacy Accural Account
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_accural_account             Charge Account
 *   OUT:
 *      p_accrual_account_id          Charge Account ID
 *   RETURN:                         Error Code.
 */
      FUNCTION is_accural_account_valid (
         p_legacy_po_number    IN     VARCHAR2,
         p_batch_id            IN     VARCHAR2,
         p_accural_account      IN OUT VARCHAR2,
         p_accrual_account_id      OUT NUMBER,
         p_acct_map_required      IN VARCHAR2
         )
         RETURN NUMBER
      IS
         x_error_code       NUMBER := xx_emf_cn_pkg.cn_success;
         x_accural_account   VARCHAR2(2000);
         x_source           VARCHAR2(50);
         l_source_system    VARCHAR2(240);

         x_segment1 VARCHAR2(1000);
         x_segment2 VARCHAR2(1000);
         x_segment3 VARCHAR2(1000);
         x_segment4 VARCHAR2(1000);
         x_segment5 VARCHAR2(1000);
         x_segment6 VARCHAR2(1000);
         x_segment7 VARCHAR2(1000);
         x_segment8 VARCHAR2(1000);

      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for accural account: ' || p_accural_account );

       BEGIN
        IF p_accural_account IS NOT NULL
            THEN

         IF UPPER(p_acct_map_required) = 'Y' THEN ------------- Account map required new CR

           SELECT source_system_name
            INTO l_source_system
            FROM xx_po_headers_stg
           WHERE legacy_po_number = p_legacy_po_number
            AND batch_id = p_batch_id;

         xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Source System Name: ' || l_source_system
            );

         x_source := xx_intg_common_pkg.get_mapping_value (
                        p_mapping_type     => 'LEGACY_SYSTEM',
                        p_source           => NULL,
                        p_old_value        => l_source_system,
                        p_date_effective   => SYSDATE
                      );
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Derived Source: ' || x_source
            );

            x_segment1 := substr(p_accural_account,1,(instr(p_accural_account,'-',1,1)-1));
            x_segment2 := substr(p_accural_account,(instr(p_accural_account,'-',1,1)+1),((instr(p_accural_account,'-',1,2)-instr(p_accural_account,'-',1,1)-1)));
            x_segment3 := substr(p_accural_account,(instr(p_accural_account,'-',1,2)+1),(instr(p_accural_account,'-',1,3)-instr(p_accural_account,'-',1,2)-1));
            x_segment4 := substr(p_accural_account,(instr(p_accural_account,'-',1,3)+1),(instr(p_accural_account,'-',1,4)-instr(p_accural_account,'-',1,3)-1));
            x_segment5 := substr(p_accural_account,(instr(p_accural_account,'-',1,4)+1),(instr(p_accural_account,'-',1,5)-instr(p_accural_account,'-',1,4)-1));
            x_segment6 := substr(p_accural_account,(instr(p_accural_account,'-',1,5)+1),(instr(p_accural_account,'-',1,6)-instr(p_accural_account,'-',1,5)-1));
            x_segment7 := substr(p_accural_account,(instr(p_accural_account,'-',1,6)+1),(instr(p_accural_account,'-',1,7)-instr(p_accural_account,'-',1,6)-1));
            x_segment8 := substr(p_accural_account,(instr(p_accural_account,'-',1,7)+1),(length(p_accural_account)-instr(p_accural_account,'-',1,7)));

         p_accrual_account_id := xx_gl_cons_ffield_load_pkg.get_ccid(x_segment1,
                                                                    x_segment2,
                                                                    x_segment3,
                                                                    x_segment4,
                                                                    x_segment5,
                                                                    x_segment6,
                                                                    x_segment7,
                                                                    x_segment8,
                                                                    x_source,
                                                                    G_COMPONENT_NAME);

         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived accural account: ' || p_accural_account );
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived accural account id: ' || p_accrual_account_id );
        x_error_code := xx_emf_cn_pkg.cn_success;


         IF p_accrual_account_id > 0 THEN
            RETURN x_error_code;
         ELSE
            RAISE NO_DATA_FOUND;
         END IF;

       ELSIF UPPER(p_acct_map_required) = 'N' THEN   ------------- Account map required new CR

           SELECT code_combination_id INTO p_accrual_account_id
            FROM gl_code_combinations
            WHERE trim(segment1||'-'||segment2||'-'||segment3||'-'||segment4||'-'||segment5||'-'||segment6||'-'||segment7||'-'||segment8)= trim(p_accural_account)
                  AND rownum = 1;
            xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived accural account: ' || p_accural_account );
            xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Derived accural account id: ' || p_accrual_account_id );
            x_error_code := xx_emf_cn_pkg.cn_success;
           RETURN x_error_code;
        END IF;    ------------- Account map required new CR

       ELSE
          RETURN x_error_code;
       END IF;
       EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for accural account: '
               || p_accural_account
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for accural account: ',
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_accural_account
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'TOOMANY for accural account: ' || p_accural_account
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_TOO_MANY
               || ' for accural account: '
               ,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               p_accural_account
            );
            RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in accural account Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in accural account Validation' || SQLERRM,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               G_DOCUMENT_TYPE_CODE
            );
          RETURN x_error_code;
       END;

      EXCEPTION
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in accural account Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in accural account Validation' || SQLERRM,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               G_DOCUMENT_TYPE_CODE
            );
          RETURN x_error_code;
      END is_accural_account_valid;

/**
 * FUNCTION is_del_person_full_name_valid
 *
 * DESCRIPTION
 *     Function to validate Person Full Name
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_deliver_to_person_full_name   Person Full Name
 *   OUT:
 *      p_deliver_to_person_id          deliver to person id
 *   RETURN:                            Error Code.
 */
      FUNCTION is_del_person_full_name_valid (
         p_deliver_to_person_full_name      IN OUT VARCHAR2,
         p_deliver_to_person_id                OUT NUMBER
      )
         RETURN NUMBER
      IS
         x_error_code       NUMBER := xx_emf_cn_pkg.cn_success;
         x_charge_account   VARCHAR2(2000);
         l_cnt              NUMBER := 0;
      BEGIN
         xx_emf_pkg.write_log (
            xx_emf_cn_pkg.CN_LOW,
            'Validation for deliver to person full name: ' || p_deliver_to_person_full_name );
        IF p_deliver_to_person_full_name IS NOT NULL
        THEN
         select count(1)
         into l_cnt
         from per_all_people_f a
         WHERE a.full_name = p_deliver_to_person_full_name
         AND sysdate BETWEEN NVL (a.effective_start_date, sysdate) AND NVL (a.effective_end_date, sysdate);

         IF l_cnt = 1 THEN
             xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'1 row in HR Table');
             SELECT a.full_name,
                  a.person_id
             INTO p_deliver_to_person_full_name,
                  p_deliver_to_person_id
             FROM per_all_people_f a
            WHERE a.full_name = p_deliver_to_person_full_name
              AND sysdate BETWEEN NVL (a.effective_start_date, sysdate) AND NVL (a.effective_end_date, sysdate);
         ELSIF l_Cnt >1 THEN
             xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'More than 1 row in HR Table');
             SELECT a.full_name,
                  a.person_id
             INTO p_deliver_to_person_full_name,
                  p_deliver_to_person_id
             FROM per_all_people_f a, per_person_types b
            WHERE a.full_name = p_deliver_to_person_full_name
              AND sysdate BETWEEN NVL (a.effective_start_date, sysdate) AND NVL (a.effective_end_date, sysdate)
              AND a.person_type_id = b.person_type_id
              AND b.user_person_type = 'Employee';
         ELSE
             xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'NO DATA FOUND for deliver to person full name: '|| p_deliver_to_person_full_name);
             x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
             xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,xx_emf_cn_pkg.CN_STG_DATAVAL,xx_emf_cn_pkg.CN_NO_DATA|| ' for deliver to person full name: ',
                               p_cnv_dist_rec.batch_id,p_cnv_dist_rec.record_number,p_deliver_to_person_full_name,p_deliver_to_person_full_name);
        END IF;
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'deliver_to_person_full_name: ' || p_deliver_to_person_full_name );
         xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'p_deliver_to_person_id: ' || p_deliver_to_person_id );
        END IF;
       RETURN x_error_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'NO DATA FOUND for deliver to person full name: '
               || p_deliver_to_person_full_name
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
                  xx_emf_cn_pkg.CN_NO_DATA
               || ' for deliver to person full name: ',
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_deliver_to_person_full_name,
               p_deliver_to_person_full_name
            );
            RETURN x_error_code;
         WHEN TOO_MANY_ROWS
         THEN
                xx_emf_pkg.write_log (
                   xx_emf_cn_pkg.CN_LOW,
                   'TOOMANY for deliver to person full name: ' || p_deliver_to_person_full_name
                );
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (
                   xx_emf_cn_pkg.CN_MEDIUM,
                   xx_emf_cn_pkg.CN_STG_DATAVAL,
                      xx_emf_cn_pkg.CN_TOO_MANY
                   || ' for deliver to person full name: '
                   ,
                   p_cnv_dist_rec.batch_id,
                   p_cnv_dist_rec.record_number,
                   p_cnv_dist_rec.attribute2,
                   p_deliver_to_person_full_name
                );
                RETURN x_error_code;
         WHEN OTHERS
         THEN
            xx_emf_pkg.write_log (
               xx_emf_cn_pkg.CN_LOW,
               'Error in deliver to person full name Validation: ' || SQLERRM
            );
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (
               xx_emf_cn_pkg.CN_MEDIUM,
               xx_emf_cn_pkg.CN_STG_DATAVAL,
               'Error in deliver to person full name Validation' || SQLERRM,
               p_cnv_dist_rec.batch_id,
               p_cnv_dist_rec.record_number,
               p_cnv_dist_rec.attribute2,
               G_DOCUMENT_TYPE_CODE
            );
            RETURN x_error_code;
      END is_del_person_full_name_valid;
   -- Start of the main function line data_validations
   -- This will only have calls to the individual functions.
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Inside Distribution Level Data-Validations');

      x_error_code_temp := is_po_line_no_valid (p_cnv_dist_rec.line_num,p_cnv_dist_rec.attribute2);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp := is_po_shipment_no_valid (p_cnv_dist_rec.shipment_num,p_cnv_dist_rec.attribute2,p_cnv_dist_rec.line_num);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_deliver_to_location_valid (p_cnv_dist_rec.deliver_to_location,
                                       p_cnv_dist_rec.deliver_to_location_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);
      IF p_cnv_dist_rec.charge_account IS NOT NULL THEN
      x_error_code_temp :=
         is_charge_account_valid (p_cnv_dist_rec.attribute2,
                                  p_cnv_dist_rec.batch_id,
                                  p_cnv_dist_rec.charge_account,
                                  p_cnv_dist_rec.charge_account_id,
                                  p_acct_mapping_req);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);
      END IF;
      x_error_code_temp :=
         is_accural_account_valid (p_cnv_dist_rec.attribute2,
                                  p_cnv_dist_rec.batch_id,
                                  p_cnv_dist_rec.accural_account,
                                   p_cnv_dist_rec.accrual_account_id,
                                   p_acct_mapping_req);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      x_error_code_temp :=
         is_del_person_full_name_valid (p_cnv_dist_rec.deliver_to_person_full_name,
                                        p_cnv_dist_rec.deliver_to_person_id);
      x_error_code := FIND_MAX (x_error_code, x_error_code_temp);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code1 ' || x_error_code);

      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Completed Distribution Level Data-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
   END data_validations_dist;    -- End of Distribution Level Data-Validations

/**
 * FUNCTION post_validations
 *
 * DESCRIPTION
 *     Function post validations
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *   OUT:
 *   RETURN:                   Error Code.
 */
   FUNCTION post_validations
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
   END post_validations;                            -- End of Post-Validations

/**
 * FUNCTION data_derivations_hdr
 *
 * DESCRIPTION
 *     Function Header Level Data-Derivations
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_cnv_pre_hdr_rec      Header Level Data Record Type
 *   OUT:
 *   RETURN:                   Error Code.
 */
   FUNCTION data_derivations_hdr (
      p_cnv_pre_hdr_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_HDR_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_org_id            NUMBER;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Inside Header Level Data-Derivations');

      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
   END data_derivations_hdr;
-- End of Header Level Data-Derivations

/**
 * FUNCTION data_derivations_line
 *
 * DESCRIPTION
 *     Function Line Level Data-Derivations
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_cnv_pre_line_rec     Line Level Data Record Type
 *   OUT:
 *   RETURN:                   Error Code.
 */
   FUNCTION data_derivations_line (
      p_cnv_pre_line_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_LINE_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Inside Line Level Data-Derivations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
   END data_derivations_line;
-- End of Line Level Data-Derivations

/**
 * FUNCTION data_derivations_dist
 *
 * DESCRIPTION
 *     Function Distribution Level Data-Derivations
 *
 * ARGUMENTS
 *   IN:
 *   IN/OUT:
 *      p_cnv_pre_dist_rec     Distribution Level Data Record Type
 *   OUT:
 *   RETURN:                   Error Code.
 */
   FUNCTION data_derivations_dist (
      p_cnv_pre_dist_rec   IN OUT xx_po_conversion_pkg.G_XX_PO_CNV_PRE_DIST_REC_TYPE
   )
      RETURN NUMBER
   IS
      x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,
                            'Inside Distribution Level Data-Derivations');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
      WHEN OTHERS
      THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         RETURN x_error_code;
   END data_derivations_dist;
-- End of Distribution Level Data-Derivations
END xx_po_cnv_validations_pkg;
/


GRANT EXECUTE ON APPS.XX_PO_CNV_VALIDATIONS_PKG TO INTG_XX_NONHR_RO;
