DROP PACKAGE BODY APPS.XX_QP_PRICE_LIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_PRICE_LIST_CNV_VAL_PKG" AS
   ----------------------------------------------------------------------
   /*
    Created By     : Samir
    Creation Date  : 27-FEB-2012
    File Name      : XXQPPRICELISTCNVVL.pkb
    Description    : This script creates the body of the package xx_qp_price_list_cnv_val_pkg

   Change History:

   Version Date          Name        Remarks
   ------- -----------   --------    -------------------------------
   1.0     27-FEB-2012   Samir     Initial development.
   */
   ----------------------------------------------------------------------

   --**********************************************************************
   --Function to Find Max.
   --**********************************************************************

   FUNCTION find_max(p_error_code1 IN VARCHAR2, p_error_code2 IN VARCHAR2)
      RETURN VARCHAR2 IS
      x_return_value VARCHAR2(100);
   BEGIN
      x_return_value := xx_intg_common_pkg.find_max(p_error_code1,
                                                    p_error_code2);

      RETURN x_return_value;
   END find_max;
   --**********************************************************************
   --Function to return lookup values.
   --**********************************************************************
   FUNCTION find_lookup_value(p_lookup_type         IN VARCHAR2,
                              p_lookup_value        IN VARCHAR2,
                              p_lookup_text         IN VARCHAR2,
                              p_record_number       IN VARCHAR2,
                              p_orig_sys_header_ref IN VARCHAR2,
                              p_orig_sys_line_ref   IN VARCHAR2)
      RETURN VARCHAR2 IS
      x_lookup_value VARCHAR2(30);
   BEGIN
      SELECT b.lookup_code
        INTO x_lookup_value
        FROM fnd_lookup_types a, fnd_lookup_values b
       WHERE a.lookup_type = b.lookup_type
         AND a.lookup_type = p_lookup_type
         AND language = UserEnv('LANG')
         AND UPPER(meaning) = UPPER(p_lookup_value);

      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'x_lookup_value ' || x_lookup_value);
      RETURN x_lookup_value;
   EXCEPTION
      WHEN TOO_MANY_ROWS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'SQLCODE TOOMANY ' || SQLCODE);
         --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         x_lookup_value := '';
         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                          p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                          p_error_text          => 'Invalid ' ||
                                                   p_lookup_text || '=>' ||
                                                   xx_emf_cn_pkg.CN_TOO_MANY,
                          p_record_identifier_1 => p_record_number,
                          p_record_identifier_2 => p_orig_sys_header_ref,
                          p_record_identifier_3 => p_orig_sys_line_ref);
         --RETURN x_error_code;
         RETURN x_lookup_value;
      WHEN NO_DATA_FOUND THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'SQLCODE NODATA ' || SQLCODE);
         --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         x_lookup_value := '';
         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                          p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                          p_error_text          => 'Invalid ' ||
                                                   p_lookup_text || '=>' ||
                                                   xx_emf_cn_pkg.CN_NO_DATA,
                          p_record_identifier_1 => p_record_number,
                          p_record_identifier_2 => p_orig_sys_header_ref,
                          p_record_identifier_3 => p_orig_sys_line_ref);

         --RETURN x_error_code;
         RETURN x_lookup_value;
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Errors In  ' || p_lookup_text ||
                              ' Validation ' || SQLCODE);
         --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         x_lookup_value := '';
         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                          p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                          p_error_text          => 'Errors In  ' ||
                                                   p_lookup_text ||
                                                   ' Validation ' || SQLERRM,
                          p_record_identifier_1 => p_record_number,
                          p_record_identifier_2 => p_orig_sys_header_ref,
                          p_record_identifier_3 => p_orig_sys_line_ref);
         RETURN x_lookup_value;
   END find_lookup_value;

   --**********************************************************************
   --Function to Pre Validations .
   --**********************************************************************
   FUNCTION pre_validations(p_batch_id IN VARCHAR2) RETURN NUMBER IS
      x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_count           NUMBER;
      r_count           NUMBER;

   BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,
                           'Inside Pre-Validations');
      BEGIN
         UPDATE xx_qp_price_list_stg
            SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                error_code   = xx_emf_cn_pkg.CN_REC_ERR
          WHERE batch_id = p_batch_id
            AND legacy_item_number is null;
         IF SQL%ROWCOUNT > 0 THEN
            x_count := SQL%ROWCOUNT;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Legacy_item_number is null for ' ||
                                 x_count || ' Records');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'Legacy_item_number is null for ' ||
                                             x_count || ' Records');
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors in Legacy_item_number Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'Errors in Legacy_item_number Validation=>' ||
                                             SQLERRM);
      END;
      BEGIN
         UPDATE xx_qp_price_list_stg
            SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                error_code   = xx_emf_cn_pkg.CN_REC_ERR
          WHERE batch_id = p_batch_id
            AND LIST_PRICE is null;
         IF SQL%ROWCOUNT > 0 THEN
            x_count := SQL%ROWCOUNT;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'LIST_PRICE is null for ' || x_count ||
                                 ' Records');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'LIST_PRICE Code is null for ' ||
                                             x_count || ' Records');
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors in LIST_PRICE Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'Errors in LIST_PRICE Validation=>' ||
                                             SQLERRM);
      END;

      BEGIN
         UPDATE xx_qp_price_list_stg
            SET process_code = xx_emf_cn_pkg.CN_PREVAL,
                error_code   = xx_emf_cn_pkg.CN_REC_ERR
          WHERE batch_id = p_batch_id
            AND hdr_attribute1 IS NULL
            AND hdr_attribute2 IS NULL;
         IF SQL%ROWCOUNT > 0 THEN
            x_count := SQL%ROWCOUNT;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'hdr_attribute1 and hdr_attribute2 null for ' ||
                                 x_count || ' Records');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'hdr_attribute1 and hdr_attribute2 is null for ' ||
                                             x_count || ' Records');
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors in hdr_attribute1 and hdr_attribute2 Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'Errors in hdr_attribute1 and hdr_attribute2 Validation=>' ||
                                             SQLERRM);
      END;
      --
      BEGIN
         SELECT count(*)
           INTO r_count
           FROM xx_qp_price_list_stg
          WHERE batch_id = p_batch_id
            AND process_code = xx_emf_cn_pkg.CN_PREVAL
            AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Total Number of Errored Records in Staging Table=> ' ||
                              r_count);
         xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                          p_category   => xx_emf_cn_pkg.CN_PREVAL,
                          p_error_text => 'Total Number of Errored Records in Staging Table=> ' ||
                                          r_count);
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors in getting errored record count ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'Errors in getting errored record count =>' ||
                                             SQLERRM);

      END;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'x_error_code before returning' || x_error_code);
      COMMIT;
      xx_emf_pkg.propagate_error(x_error_code);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, x_error_code);
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, x_error_code);
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, x_error_code);
         RETURN x_error_code;
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, x_error_code);
         RETURN x_error_code;
   END pre_validations;
    --**********************************************************************
   --Function for common data validations.
   --**********************************************************************
   FUNCTION common_data_validations(p_batch_id IN VARCHAR2) RETURN NUMBER IS
      x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      CURSOR c_price_list_rec
      IS
      SELECT DISTINCT operating_unit,
                      currency_code,
                      arithmetic_operator,
		      list_type_code,
		      list_line_type_code,
		      product_attribute_context,
		      product_attr_code,
		      product_attribute
		 FROM xx_qp_price_list_pre
		WHERE batch_id=p_batch_id;
      x_operating_unit xx_qp_price_list_pre.operating_unit%TYPE;
      x_orig_org_id    xx_qp_price_list_pre.orig_org_id%TYPE;
      x_currency_code xx_qp_price_list_pre.currency_code%TYPE;
      x_currency_header_id xx_qp_price_list_pre.currency_header_id%TYPE;
      x_arithmetic_operator xx_qp_price_list_pre.arithmetic_operator%TYPE;
      x_list_type_code xx_qp_price_list_pre.list_type_code%TYPE;
      x_list_line_type_code xx_qp_price_list_pre.list_line_type_code%TYPE;
      x_product_attribute_context xx_qp_price_list_pre.product_attribute_context%TYPE;
      x_product_attr_code xx_qp_price_list_pre.product_attr_code%TYPE;
      x_product_attribute  xx_qp_price_list_pre.product_attribute%TYPE;
      --**********************************************************************
      --Function to derive and validate Product Context
      --**********************************************************************
      FUNCTION is_product_attr_context_valid(p_product_attr_context IN OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_err_code   VARCHAR2(30);
         x_err_msg    VARCHAR2(200);
         x_count      NUMBER;

      BEGIN

         SELECT prc_context_code
           INTO p_product_attr_context
           FROM qp_prc_contexts_v
          WHERE prc_context_type = 'PRODUCT'
            AND upper(user_prc_context_name) =
                upper(p_product_attr_context);
         RETURN x_error_code;

      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE TOOMANY ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Product Context =>' ||
                                                      xx_emf_cn_pkg.CN_TOO_MANY,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
         WHEN NO_DATA_FOUND THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE NODATA ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Product Context =>' ||
                                                      xx_emf_cn_pkg.CN_NO_DATA,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In Product Context Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In Product Context Validation=>' ||
                                                      SQLERRM,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;

      END is_product_attr_context_valid;

      --**********************************************************************
      --Function to derive and validate Product Code
      --**********************************************************************
      FUNCTION is_product_attr_code_valid(p_product_attr_context IN VARCHAR2,
                                          p_product_attr_code    IN OUT VARCHAR2,
                                          p_product_attribute    OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_err_code   VARCHAR2(30);
         x_err_msg    VARCHAR2(200);
         x_count      NUMBER;

      BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'p_product_attr_context' ||
                              p_product_attr_context);
         IF (p_product_attr_context = 'ITEM') THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'p_product_attr_code1' ||
                                 p_product_attr_code);

            SELECT segment_code, seg.segment_mapping_column
              INTO p_product_attr_code, p_product_attribute
              FROM qp_prc_contexts_v cntx, qp_segments_v seg
             WHERE cntx.prc_context_id = seg.prc_context_id
               AND upper(seg.user_segment_name) =
                   upper(p_product_attr_code)
               AND cntx.prc_context_code = p_product_attr_context;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'p_product_attr_code2' ||
                                 p_product_attr_code);
            RETURN x_error_code;
         END IF;

      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE TOOMANY ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Product Context code =>' ||
                                                      xx_emf_cn_pkg.CN_TOO_MANY,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
         WHEN NO_DATA_FOUND THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE NODATA ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Product Context Code=>' ||
                                                      xx_emf_cn_pkg.CN_NO_DATA,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In Product Context Code Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In Product Context Code Validation=>' ||
                                                      SQLERRM,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;

      END is_product_attr_code_valid;
      --**********************************************************************
      --Function to derive and validate Operating Unit
      --**********************************************************************
      FUNCTION is_operating_unit_valid(p_organization_code IN VARCHAR2,
                                       p_orig_org_id       OUT NUMBER,
                                       p_operating_unit    IN OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_err_code   VARCHAR2(30);
         x_err_msg    VARCHAR2(200);

      BEGIN
         IF (p_operating_unit IS NOT NULL AND
            p_operating_unit <> NVL(p_organization_code,'-99')) THEN
            SELECT organization_id, name
              INTO p_orig_org_id, p_operating_unit
              FROM hr_operating_units
             WHERE upper(name) = upper(p_operating_unit);
         ELSIF (p_organization_code IS NOT NULL) THEN
            SELECT ou.organization_id, ou.name
              INTO p_orig_org_id, p_operating_unit
              FROM hr_operating_units ou, XXINTG.xx_intg_mapping xam
             WHERE xam.old_value1 = p_organization_code
               AND upper(xam.new_value1) = upper(ou.name)
               AND xam.mapping_type = 'OPERATING_UNIT';

         END IF;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE TOOMANY ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Opertaing Unit Org_Id =>' ||
                                                      xx_emf_cn_pkg.CN_TOO_MANY,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
         WHEN NO_DATA_FOUND THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE NODATA ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Opertaing Unit Org_Id =>' ||
                                                      xx_emf_cn_pkg.CN_NO_DATA,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL
                            );
            RETURN x_error_code;
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In Opertaing Unit Org_Id Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In Opertaing Unit Org_Id Validation=>' ||
                                                      SQLERRM,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL
                             );
            RETURN x_error_code;
            RETURN x_error_code;

      END is_operating_unit_valid;

      --**********************************************************************
      --Function to derive and validate Currency Code
      --**********************************************************************
      FUNCTION is_currency_code_valid(p_currency_code      IN VARCHAR2,
                                      p_currency_header_id OUT NUMBER)
         RETURN NUMBER IS
         x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_err_code   VARCHAR2(30);
         x_err_msg    VARCHAR2(200);

      BEGIN

         SELECT currency_header_id
           INTO p_currency_header_id
           FROM qp_currency_lists_b
          WHERE upper(base_currency_code) = upper(p_currency_code)
            AND rownum < 2;

         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE TOOMANY ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Currency Code =>' ||
                                                      xx_emf_cn_pkg.CN_TOO_MANY,
                              p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
         WHEN NO_DATA_FOUND THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE NODATA ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Currency Code =>' ||
                                                      xx_emf_cn_pkg.CN_NO_DATA,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors Currency Code Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In Currency Code Validation=>' ||
                                                      SQLERRM,
                              p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
            RETURN x_error_code;

      END is_currency_code_valid;

      --**********************************************************************
      --Function to validate LIST_TYPE_CODE
      --**********************************************************************
      FUNCTION is_list_type_code(p_list_type_code_text IN VARCHAR2,
                                 p_list_type_code      OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code     NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_list_type_code VARCHAR2(30);
         x_count          NUMBER;

      BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'p_list_type_code_text ' ||
                              p_list_type_code_text);

         x_list_type_code := find_lookup_value(p_lookup_type         => 'LIST_TYPE_CODE',
                                               p_lookup_value        => p_list_type_code_text,
                                               p_lookup_text         => 'LIST_TYPE_CODE',
                                               p_record_number       => NULL,
                                               p_orig_sys_header_ref => NULL,
                                               p_orig_sys_line_ref   => NULL);

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'x_list_type_code ' || x_list_type_code);
         IF (x_list_type_code = '') THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            RETURN x_error_code;

         else
            p_list_type_code := x_list_type_code;
            x_error_code     := xx_emf_cn_pkg.CN_SUCCESS;
            RETURN x_error_code;
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In list_type_code Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In list_type_code Validation=>' ||
                                                      SQLERRM,
                              p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
      END is_list_type_code;

      --**********************************************************************
      --Function to validate LIST_LINE_TYPE_CODE
      --**********************************************************************
      FUNCTION is_list_line_type_code(p_list_line_type_code_text IN VARCHAR2,
                                      p_list_line_type_code      OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code          NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_list_line_type_code VARCHAR2(30);
         x_count               NUMBER;
      BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'p_list_line_type_code_text ' ||
                              p_list_line_type_code_text);

         x_list_line_type_code := find_lookup_value(p_lookup_type         => 'LIST_LINE_TYPE_CODE',
                                                    p_lookup_value        => p_list_line_type_code_text,
                                                    p_lookup_text         => 'LIST_LINE_TYPE_CODE',
                                                    p_record_number       => NULL,
                                                    p_orig_sys_header_ref => NULL,
                                                    p_orig_sys_line_ref   => NULL);

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'x_list_line_type_code ' ||
                              x_list_line_type_code);
         IF (x_list_line_type_code = '') THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            RETURN x_error_code;

         else
            p_list_line_type_code := x_list_line_type_code;
            x_error_code          := xx_emf_cn_pkg.CN_SUCCESS;
            RETURN x_error_code;
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In list_line_type_code Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In list_line_type_code Validation=>' ||
                                                      SQLERRM,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
      END is_list_line_type_code;

      FUNCTION is_arithmetic_operator(p_arithmetic_operator_text IN VARCHAR2,
                                      p_arithmetic_operator      OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code          NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_arithmetic_operator VARCHAR2(30);
         x_count               NUMBER;

      BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'p_arithmetic_operator_text ' ||
                              p_arithmetic_operator_text);

         x_arithmetic_operator := find_lookup_value(p_lookup_type         => 'ARITHMETIC_OPERATOR',
                                                    p_lookup_value        => p_arithmetic_operator_text,
                                                    p_lookup_text         => 'ARITHMETIC_OPERATOR',
                                                    p_record_number       => NULL,
                                                    p_orig_sys_header_ref => NULL,
                                                    p_orig_sys_line_ref   => NULL);

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'x_arithmetic_operator ' ||
                              x_arithmetic_operator);
         IF (x_arithmetic_operator = '') THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            RETURN x_error_code;

         else
            p_arithmetic_operator := x_arithmetic_operator;
            x_error_code          := xx_emf_cn_pkg.CN_SUCCESS;
            RETURN x_error_code;
         END IF;

      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In arithmetic_operator  Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In arithmetic_operator  Validation=>' ||
                                                      SQLERRM,
                             p_record_identifier_1 => NULL,
                             p_record_identifier_2 => NULL,
                             p_record_identifier_3 => NULL,
                             p_record_identifier_4 => NULL);
            RETURN x_error_code;
      END is_arithmetic_operator;
   BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_medium,
                           'Inside common_data_validations');
      x_currency_code := NULL;
      x_currency_header_id := NULL;
      x_arithmetic_operator := NULL;
      x_list_line_type_code := NULL;
      x_list_line_type_code := NULL;
      x_product_attribute_context := NULL;
      x_product_attr_code := NULL;
      x_product_attribute  := NULL;
      x_operating_unit     := NULL;
      FOR r_price_list_rec IN c_price_list_rec
      LOOP
         x_operating_unit := r_price_list_rec.operating_unit;
         x_currency_code := r_price_list_rec.currency_code;
         x_currency_header_id := NULL;
         x_arithmetic_operator := r_price_list_rec.arithmetic_operator;
         x_list_type_code := r_price_list_rec.list_type_code;
         x_list_line_type_code := r_price_list_rec.list_line_type_code;
	 x_product_attribute_context := r_price_list_rec.product_attribute_context;
         x_product_attr_code := r_price_list_rec.product_attr_code;
         x_product_attribute  := r_price_list_rec.product_attribute;
         IF (x_currency_code IS NOT NULL) THEN
             x_error_code_temp := is_currency_code_valid(x_currency_code,
                                                        x_currency_header_id);
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_currency_code_valid - error ' ||
                              x_error_code_temp);
             x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
         ELSE
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_currency_code_valid not called as currency_code is null ');
         END IF;
         IF (x_operating_unit IS NOT NULL) THEN

            x_error_code_temp := is_operating_unit_valid('NULL',
                                                         x_orig_org_id,
                                                         x_operating_unit);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'is_operating_unit_valid - error ' ||
                                 x_error_code_temp);
            x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
         ELSE
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_operating_unit_valid not called as global_flag is Y ');

         END IF;
         -- Start of the Line Data validation--
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                             'Inside Line level data validation....');
         IF (x_product_attribute_context IS NOT NULL) THEN
         -- to stop data validation
         x_error_code_temp := is_product_attr_context_valid(x_product_attribute_context);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_product_attr_context_valid - error ' ||
                              x_error_code_temp);
         x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_product_attr_context_valid not called as product_attribute_context is null ');
      END IF;

      IF (x_product_attr_code IS NOT NULL) THEN
         -- to stop data validation
         x_error_code_temp := is_product_attr_code_valid(x_product_attribute_context,
                                                         x_product_attr_code,
                                                         x_product_attribute);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_product_attr_code_valid - error ' ||
                              x_error_code_temp);
         x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_product_attr_code_valid not called as product_attr_code is null ');
      END IF;
      UPDATE xx_qp_price_list_pre
         SET currency_code = x_currency_code,
	     currency_header_id= x_currency_header_id,
	     arithmetic_operator=x_arithmetic_operator,
	     orig_org_id=x_orig_org_id,
             product_attribute_context=x_product_attribute_context,
             product_attr_code=x_product_attr_code,
             product_attribute=x_product_attribute
       WHERE batch_id=p_batch_id
        AND  (operating_unit is NULL OR operating_unit=x_operating_unit);
       COMMIT;
     END LOOP;
     RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors in common_data_validations ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity   => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category   => xx_emf_cn_pkg.CN_PREVAL,
                             p_error_text => 'Errors in common_data_validations=>' ||
                                             SQLERRM);
	    RETURN x_error_code;
      END;
   --**********************************************************************
   --Function to Data Validations .
   --**********************************************************************

   FUNCTION data_validations(p_cnv_hdr_rec IN OUT xx_qp_price_list_cnv_pkg.G_XX_QP_PL_PRE_REC_TYPE)
      RETURN NUMBER IS

      x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

      --- Local functions for all batch level validations
      --- Add as many functions as required in here

      --**********************************************************************
      --Function to derive and validate Price LIST
      --**********************************************************************

      FUNCTION is_price_list_exists(p_name           IN VARCHAR2,
                                    p_attr2          IN VARCHAR2,
                                    p_list_header_id OUT NUMBER
                                    --,p_interface_action_code OUT VARCHAR2
                                    ) RETURN NUMBER IS
         x_error_code     NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_err_code       VARCHAR2(30);
         x_err_msg        VARCHAR2(200);
         x_list_header_id NUMBER;

      BEGIN

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'List name After derive ' || p_name);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'List name length ' || length(p_name));
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'User Language ' || USERENV('LANG'));
         IF p_name IS NOT NULL THEN
         SELECT b.list_header_id
           INTO p_list_header_id
           FROM qp_list_headers_b a, qp_list_headers_tl b
          WHERE 1 = 1
            AND a.list_header_id = b.list_header_id
            AND language = USERENV('LANG')
            AND a.list_type_code = 'PRL' -- This is added on 14 jan bcos to distinguish Price List and Modifier
            AND TRIM(UPPER(b.name)) = TRIM(UPPER(p_name))
            AND ROWNUM < 2;
          ELSE
	     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	     IF p_attr2 IS NULL THEN
	       xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Unable to Derive Price List Name From Attribute1',
                             p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                             p_record_identifier_2 => p_cnv_hdr_rec.name,
                             p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                             p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
	     ELSE
	         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Unable to Derive Price List Name Attribute2 should have a valid customer account',
                             p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                             p_record_identifier_2 => p_cnv_hdr_rec.name,
                             p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                             p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
	     END IF;
      END IF;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'List Header Id After derive ' ||
                              p_list_header_id);

         /*  IF(x_list_header_id IS NULL) THEN
          p_interface_action_code:='INSERT';
          RETURN x_error_code;
         ELSE
          p_interface_action_code:='UPDATE';
          RETURN x_error_code;
         END IF;*/
         RETURN x_error_code;
      EXCEPTION
         WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE TOOMANY ' || SQLCODE);
            x_error_code     := xx_emf_cn_pkg.CN_REC_ERR;
            p_list_header_id := '';
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Invalid Pricelist Name=>' ||
                                                      xx_emf_cn_pkg.CN_TOO_MANY,
                             p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                             p_record_identifier_2 => p_cnv_hdr_rec.name,
                             p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                             p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
            RETURN x_error_code;
         WHEN NO_DATA_FOUND THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'SQLCODE NODATA for Price list ID');
            p_list_header_id := '';
            x_error_code     := xx_emf_cn_pkg.CN_SUCCESS;
            /*x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Invalid Pricelist Name =>'||xx_emf_cn_pkg.CN_NO_DATA
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.ORIG_SYS_HEADER_REF
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                    );*/
            RETURN x_error_code;
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In Product Context Validation ' ||
                                 SQLCODE);
            x_error_code     := xx_emf_cn_pkg.CN_REC_ERR;
            p_list_header_id := '';
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In Pricelist Name Validation=>' ||
                                                      SQLERRM,
                             p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                             p_record_identifier_2 => p_cnv_hdr_rec.name,
                             p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                             p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
            RETURN x_error_code;
            RETURN x_error_code;
      END is_price_list_exists;

      --**********************************************************************
      --Function to validate ITEM_NUMBER
      --**********************************************************************

      FUNCTION is_item_number_valid(p_legacy_item_number IN OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_err_code          VARCHAR2(30);
         x_err_msg           VARCHAR2(200);
         x_organization_id   NUMBER;
	 x_customer_order_flag     VARCHAR2(2);
         x_inventory_item_id VARCHAR2(30);
      BEGIN
         BEGIN
            SELECT organization_id
              INTO x_organization_id
              FROM mtl_parameters
             WHERE master_organization_id = organization_id;
         EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Invalid Master Organization ');

              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Derive Organization from QP: Item Validation Organization profile ');
              x_organization_id := NVL(fnd_profile.value('QP_ORGANIZATION_ID'), fnd_profile.value('QP_ORGANIZATION_ID'));
	    WHEN TOO_MANY_ROWS THEN
	      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Invalid Master Organization ');

              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Derive Organization from QP: Item Validation Organization profile ');
              x_organization_id := NVL(fnd_profile.value('QP_ORGANIZATION_ID'), fnd_profile.value('QP_ORGANIZATION_ID'));
            WHEN OTHERS THEN
	       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Invalid Master Organization ');
	       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Derive Organization from QP: Item Validation Organization profile ');
               x_organization_id := NVL(fnd_profile.value('QP_ORGANIZATION_ID'), fnd_profile.value('QP_ORGANIZATION_ID'));
         END;
	 xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'x_organization: ' ||x_organization_id);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_item_number_valid: ' ||
                              p_legacy_item_number || '-' ||
                              x_organization_id);
         -- get the Oracle Item Number if cross exists between Legacy Item Number and Oracle Item Number
         /*xx_intg_common_pkg.get_inventory_item_id(p_legacy_item_name  =>p_legacy_item_number
              ,p_organization_id   =>x_organization_id
              ,p_inventory_item_id =>x_inventory_item_id
              ,p_error_code        =>x_err_code
              ,p_error_msg         =>x_err_msg
         );*/
         BEGIN
            SELECT msi.inventory_item_id , msi.customer_order_flag
              INTO x_inventory_item_id , x_customer_order_flag
              FROM mtl_system_items_b msi
             WHERE msi.organization_id = x_organization_id
               AND msi.segment1 = p_legacy_item_number;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               x_inventory_item_id := NULL;
               x_err_code          := xx_emf_cn_pkg.CN_NO_DATA;
            WHEN OTHERS THEN
               x_inventory_item_id := NULL;
               x_err_code          := xx_emf_cn_pkg.CN_OTHERS;
         END;
         IF (x_inventory_item_id IS NOT NULL) THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'is_item_number_valid: ' ||
                                 p_legacy_item_number || '-' ||
                                 x_organization_id);
            p_legacy_item_number := x_inventory_item_id;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'is_item_number_valid2: ' ||
                                 p_legacy_item_number);

	     IF (x_customer_order_flag <> 'Y') THEN  -- Added on 21st-sep-12
	        x_inventory_item_id := NULL;
	        x_err_code := xx_emf_cn_pkg.CN_OTHERS;
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                    'The Item is having Customer Order flag = N');
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                                p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                                p_error_text          => 'The Item is having Customer Order flag = N',
                                p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                                p_record_identifier_2 => p_cnv_hdr_rec.name,
                                p_record_identifier_3 => p_legacy_item_number
                                );
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                    'X_ERROR_CODE legacy item number ' ||
                                    x_error_code);
               RETURN x_error_code;
            END IF;   -- Added on 21st-sep-12
         END IF;
         IF x_inventory_item_id IS NULL THEN
            IF x_err_code = xx_emf_cn_pkg.CN_TOO_MANY THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                    'SQLCODE TOOMANY ' || SQLCODE);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                                p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                                p_error_text          => 'Invalid legacy item number=>' ||
                                                         xx_emf_cn_pkg.CN_TOO_MANY,
                                p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                                p_record_identifier_2 => p_cnv_hdr_rec.name,
                                p_record_identifier_3 => p_legacy_item_number
                                );
               RETURN x_error_code;
            ELSIF x_err_code = xx_emf_cn_pkg.CN_NO_DATA THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                    'SQLCODE NODATA ' || SQLCODE);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                                p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                                p_error_text          => 'Invalid legacy item number =>' ||
                                                         xx_emf_cn_pkg.CN_NO_DATA,
                                p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                                p_record_identifier_2 => p_cnv_hdr_rec.name,
                                p_record_identifier_3 => p_legacy_item_number
                                );
               RETURN x_error_code;
            ELSIF x_err_code = xx_emf_cn_pkg.CN_OTHERS THEN
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                    'SQLCODE OTHERS ' || SQLCODE);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                                p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                                p_error_text          => 'Invalid legacy item number=>' ||
                                                         SQLERRM,
                                p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                                p_record_identifier_2 => p_cnv_hdr_rec.name,
                                p_record_identifier_3 => p_legacy_item_number
                                );
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                    'X_ERROR_CODE legacy item number ' ||
                                    x_error_code);
               RETURN x_error_code;
            END IF;
         ELSE
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 '~Item# Validation Success=>' ||
                                 x_inventory_item_id);
            RETURN x_error_code;
         END IF;
      END is_item_number_valid;

      --**********************************************************************
      --Function to validate PRODUCT_UOM_CODE
      --**********************************************************************

      FUNCTION is_product_uom_code_exist(p_product_uom_code IN OUT VARCHAR2)
         RETURN NUMBER IS
         x_error_code           NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_err_code             VARCHAR2(30);
         x_err_msg              VARCHAR2(200);
         x_transaction_uom_code VARCHAR2(10);
      BEGIN
         -- get the Oracle UOM from the mapping table

         IF (p_product_uom_code IS NOT NULL) THEN
            /* Fetch the organization code using the black box logic
            */
            p_product_uom_code := xx_intg_common_pkg.get_uom_code(p_product_uom_code,
                                                                  x_err_code,
                                                                  x_err_msg);
            -- get the actual uom code

            IF p_product_uom_code IS NULL THEN
               IF x_err_code = xx_emf_cn_pkg.CN_TOO_MANY THEN
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                       'SQLCODE TOOMANY ' || SQLCODE);
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                                   p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                                   p_error_text          => 'Invalid Product UOM=>' ||
                                                            xx_emf_cn_pkg.CN_TOO_MANY,
                                   p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                                   p_record_identifier_2 => p_cnv_hdr_rec.name,
                                   p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                                   p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
                  RETURN x_error_code;
               ELSIF x_err_code = xx_emf_cn_pkg.CN_NO_DATA THEN
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                       'SQLCODE NODATA ' || SQLCODE);
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                                   p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                                   p_error_text          => 'Invalid Product UOM =>' ||
                                                            xx_emf_cn_pkg.CN_NO_DATA,
                                   p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                                   p_record_identifier_2 => p_cnv_hdr_rec.name,
                                   p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                                   p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
                  RETURN x_error_code;
               ELSIF x_err_code = xx_emf_cn_pkg.CN_OTHERS THEN
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                       'SQLCODE OTHERS ' || SQLCODE);
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                                   p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                                   p_error_text          => 'IInvalid Product UOM=>' ||
                                                            SQLERRM,
                                   p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                                   p_record_identifier_2 => p_cnv_hdr_rec.name,
                                   p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                                   p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                       'X_ERROR_CODE Product UOM ' ||
                                       x_error_code);
                  RETURN x_error_code;
               END IF;
            ELSE
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                    'Product UOM SUCCESS=>' ||
                                    p_product_uom_code);
               RETURN x_error_code;
            END IF;
         END IF;
         RETURN x_error_code;
      END is_product_uom_code_exist;
      FUNCTION is_record_exists(p_list_header_id        IN NUMBER,
                                p_name                  IN VARCHAR2,
                                p_list_line_type_code   IN VARCHAR2,
                                p_operand               IN NUMBER,
                                p_start_date_active_dtl IN DATE,
                                p_end_date_active_dtl   IN DATE,
                                p_product_attribute     IN VARCHAR2,
                                p_product_attr_value    IN NUMBER,
                                p_product_uom_code      IN VARCHAR2)
         RETURN NUMBER IS
         x_error_code    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         x_customer_name VARCHAR2(30);
         x_count         NUMBER;

      BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'p_list_header_id ' || p_list_header_id ||
                              ' ,p_operand ' || p_operand ||
                              ' ,p_list_line_type_code ' ||
                              p_list_line_type_code ||
                              ' ,p_product_attribute ' ||
                              p_product_attribute ||
                              ' ,p_product_attr_value ' ||
                              p_product_attr_value ||
                              ' ,p_product_uom_code ' || p_product_uom_code);
          SELECT COUNT(*)
           INTO x_count
           FROM qp_list_lines a, qp_pricing_attributes b
          WHERE a.list_header_id = b.list_header_id
            AND a.list_line_type_code = p_list_line_type_code
            AND a.list_line_id = b.list_line_id
            AND b.product_attribute = p_product_attribute
            AND b.product_attr_value = p_product_attr_value
            AND b.list_header_id = p_list_header_id;

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'x_count ' || x_count);

         IF (x_count > 0) THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'x_error_code ' || x_error_code);
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Record exist in Base table for Price List=> ' ||
                                                      p_name,
                             p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                             p_record_identifier_2 => p_cnv_hdr_rec.name,
                             p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                             p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
            --RETURN x_error_code;
         ELSE
            x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'x_error_code ' || x_error_code);
            --RETURN x_error_code;
         END IF;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'Errors In is_record_exists  Validation ' ||
                                 SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                             p_category            => xx_emf_cn_pkg.CN_STG_DATAVAL,
                             p_error_text          => 'Errors In is_record_exists Validation=>' ||
                                                      SQLERRM,
                             p_record_identifier_1 => p_cnv_hdr_rec.record_number,
                             p_record_identifier_2 => p_cnv_hdr_rec.name,
                             p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_header_ref,
                             p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_line_ref);
            RETURN x_error_code;

         --RETURN x_error_code;
      END is_record_exists;

      ------------------------ Start the BEGIN part of Data Validations ----------------------------------

   BEGIN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'Inside header level data validation...');
      --IF (p_cnv_hdr_rec.name IS NOT NULL) THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Price list name; ' || p_cnv_hdr_rec.name);
         x_error_code_temp := is_price_list_exists(p_cnv_hdr_rec.name,
                                                   p_cnv_hdr_rec.hdr_attribute2,
                                                   p_cnv_hdr_rec.list_header_id);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_price_list_exists - error ' ||
                              x_error_code_temp);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'List_header_id => ' ||
                              p_cnv_hdr_rec.list_header_id);
         x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      --END IF;
      ---
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'product_attr_code is after product_attr_code_validation ' ||
                           p_cnv_hdr_rec.product_attr_code);

      IF (p_cnv_hdr_rec.product_attr_code = 'INVENTORY_ITEM_ID') THEN
         IF (p_cnv_hdr_rec.product_attr_value IS NOT NULL) THEN
            -- to stop data validation
            x_error_code_temp := is_item_number_valid(p_cnv_hdr_rec.product_attr_value);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'is_item_number_valid - error ' ||
                                 x_error_code_temp);
            x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
         ELSE
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                                 'is_item_number_valid not called as product_attr_value is null ');
         END IF;
      END IF;
      IF p_cnv_hdr_rec.product_attr_value IS NOT NULL THEN
         BEGIN
            SELECT primary_uom_code
              INTO p_cnv_hdr_rec.product_uom_code
              FROM mtl_system_items_b
             WHERE inventory_item_id = p_cnv_hdr_rec.product_attr_value
               AND rownum = 1;
         EXCEPTION
            WHEN OTHERS THEN
               p_cnv_hdr_rec.product_uom_code := NULL;
         END;

      END IF;
      IF (p_cnv_hdr_rec.product_uom_code IS NOT NULL) THEN
         -- to stop data validation
         x_error_code_temp := is_product_uom_code_exist(p_cnv_hdr_rec.product_uom_code);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_product_uom_code_exist - error ' ||
                              x_error_code_temp);
         x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_product_uom_code_exist not called as product_uom_code is null ');
      END IF;

      IF (p_cnv_hdr_rec.list_header_id IS NOT NULL) THEN
         x_error_code_temp := is_record_exists(p_cnv_hdr_rec.list_header_id,
                                               p_cnv_hdr_rec.name,
                                               p_cnv_hdr_rec.list_line_type_code,
                                               p_cnv_hdr_rec.operand,
                                               p_cnv_hdr_rec.start_date_active_dtl,
                                               p_cnv_hdr_rec.end_date_active_dtl,
                                               p_cnv_hdr_rec.product_attribute,
                                               p_cnv_hdr_rec.product_attr_value,
                                               p_cnv_hdr_rec.product_uom_code);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_record_exists - error ' ||
                              x_error_code_temp);
         x_error_code := FIND_MAX(x_error_code, x_error_code_temp);
      ELSE
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'is_record_exists - Record eligible for Insert....' ||
                              x_error_code_temp);
      END IF;
      -- End of Line Data validations --
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'x_error_code_temp---' || x_error_code_temp);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'x_error_code---' || x_error_code);
      -- commented to stop a propagate error , It is called in main package after data validation
      --xx_emf_pkg.propagate_error ( x_error_code_temp);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'x_error_code_temp---' || x_error_code_temp);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                           'x_error_code---' || x_error_code);
      RETURN x_error_code;
   EXCEPTION
      WHEN OTHERS THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,
                              'Exception in data_validations function. ' ||
                              SQLERRM);
         RETURN x_error_code;
   END data_validations;

   FUNCTION post_validations(p_batch_id IN VARCHAR2) RETURN NUMBER IS
      x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
      x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
      CURSOR c_print_error_rec IS
         SELECT pre.record_number, pre.name, pre.legacy_item_number
           FROM xx_qp_price_list_pre pre
          WHERE pre.process_code = xx_emf_cn_pkg.cn_postval
            AND pre.error_code = xx_emf_cn_pkg.CN_REC_ERR
            AND pre.batch_id = p_batch_id
            AND pre.request_id = xx_emf_pkg.g_request_id;

   BEGIN
      --xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Post-Validations');
      /*UPDATE xx_qp_price_list_pre pre
         SET pre.process_code = xx_emf_cn_pkg.cn_postval,
             pre.error_code   = xx_emf_cn_pkg.CN_REC_ERR
       WHERE pre.name in
             (SELECT DISTINCT xqp.name
                FROM xx_qp_price_list_pre xqp
               WHERE xqp.error_code = xx_emf_cn_pkg.CN_REC_ERR
                 AND xqp.batch_id = p_batch_id
                 AND xqp.request_id = xx_emf_pkg.g_request_id)
         AND pre.batch_id = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id;
      COMMIT;*/

      FOR cur_rec IN c_print_error_rec LOOP
         xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.CN_MEDIUM,
                          p_category            => xx_emf_cn_pkg.cn_postval,
                          p_error_text          => 'Price List Erroed out due error exists in Line',
                          p_record_identifier_1 => cur_rec.record_number,
                          p_record_identifier_2 => cur_rec.name,
                          p_record_identifier_3 => cur_rec.legacy_item_number);

      END LOOP;

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

   ----------------------------------------------------------------------
   -------------------< DATA DERIVATIONS >--------------------------
   ----------------------------------------------------------------------
   FUNCTION data_derivations(p_cnv_pre_std_hdr_rec IN OUT xx_qp_price_list_cnv_pkg.G_XX_QP_PL_PRE_REC_TYPE)
      RETURN NUMBER IS
      --This function is kept for EMF structure
      x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN

      --xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivation');

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
   END data_derivations;
END xx_qp_price_list_cnv_val_pkg;
/


GRANT EXECUTE ON APPS.XX_QP_PRICE_LIST_CNV_VAL_PKG TO INTG_XX_NONHR_RO;
