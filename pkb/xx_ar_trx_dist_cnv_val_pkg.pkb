DROP PACKAGE BODY APPS.XX_AR_TRX_DIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_TRX_DIST_CNV_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 10-JAN-2012
 File Name     : XXARTRXDISTVAL.pkb
 Description   : This script creates the body of the package
                 xx_ar_trx_cnv_validations_pkg
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 10-JAN-2012   Sharath Babu          Initial Development
 20-MAR-2012   Sharath Babu          Modified to add mapping value function
 18-MAY-2012   Sharath Babu          Added CASE condition of dist amt check
                                     modified segemnt derivation logic
 15-JUN-2012   Sharath Babu          Modfied GL Black Box func calling proc
*/
----------------------------------------------------------------------
   FUNCTION find_max (
      p_error_code1 IN VARCHAR2,
      p_error_code2 IN VARCHAR2
   )
      RETURN VARCHAR2
   IS
      x_return_value VARCHAR2(100);
   BEGIN
      x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);
      RETURN x_return_value;
   END find_max;

   --Function to perform Pre-validations
   FUNCTION pre_validations(
                           p_trx_stg_rec IN xx_inv_trx_dist_cnv_pkg.G_XX_AR_CNV_STG_REC_TYPE
                          )
   RETURN NUMBER
   IS
     x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

  FUNCTION is_iface_line_context_null(p_iface_line_context IN VARCHAR2)
  RETURN NUMBER
  IS
    BEGIN
      IF p_iface_line_context is NULL THEN
           xx_emf_pkg.error
                      (p_severity                 => xx_emf_cn_pkg.cn_medium,
                       p_category                 => xx_emf_cn_pkg.cn_iface_line_context_valid,
                       p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
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
                      p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
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
                   p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                                 || ' - Invalid : IFace Line Attribute1 IS NULL => '
                                                 || p_iface_line_attribute1
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_iface_line_attribute1_null,
                   p_record_identifier_1      => p_trx_stg_rec.record_number,
                   p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute2,
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
                   p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                                 || ' - Invalid IFace Line Attribute1 => '
                                                 || p_iface_line_attribute1
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_trx_stg_rec.record_number,
                   p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trx_stg_rec.interface_line_attribute2
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
                  p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                                || ' - Invalid : IFace Line Attribute2 IS NULL => '
                                                || p_iface_line_attribute2
                                                || '-'
                                                || xx_emf_cn_pkg.cn_iface_line_attribute2_null,
                  p_record_identifier_1      => p_trx_stg_rec.record_number,
                  p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
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
                  p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                                || ' - Invalid IFace Line Attribute2 => '
                                                || p_iface_line_attribute2
                                                || '-'
                                                || SQLERRM,
                  p_record_identifier_1      => p_trx_stg_rec.record_number,
                  p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                  p_record_identifier_3      => p_trx_stg_rec.interface_line_attribute2
                 );
              RETURN x_error_code;
      END is_iface_line_attribute2_null;

  FUNCTION is_amount_null (
             p_amount   IN   VARCHAR2
          )
          RETURN NUMBER
          IS
          BEGIN
             IF p_amount IS NULL
             THEN
                xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                    p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                                  || ' - Invalid : Amount IS NULL => '
                                                  || p_amount ,
                    p_record_identifier_1      => p_trx_stg_rec.record_number,
                    p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                    p_record_identifier_3      => p_trx_stg_rec.amount
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
                                       'Errors In is_amount_null '
                                    || SQLCODE
                                   );
                xx_emf_pkg.error
                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
                    p_category                 => xx_emf_cn_pkg.cn_stg_preval,
                    p_error_text               =>    p_trx_stg_rec.interface_line_attribute2
                                                  || ' - Invalid Amount => '
                                                  || p_amount
                                                  || '-'
                                                  || SQLERRM,
                    p_record_identifier_1      => p_trx_stg_rec.record_number,
                    p_record_identifier_2      => p_trx_stg_rec.interface_line_attribute1,
                    p_record_identifier_3      => p_trx_stg_rec.amount
                   );
                RETURN x_error_code;
      END is_amount_null;

   BEGIN

     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside Pre-Validation Record Number = '||p_trx_stg_rec.record_number);

     x_error_code_temp := is_iface_line_context_null(p_trx_stg_rec.interface_line_context);
     x_error_code      := find_max ( x_error_code, x_error_code_temp);
     --xx_emf_pkg.propagate_error( x_error_code_temp);

     x_error_code_temp :=is_iface_line_attribute1_null(p_trx_stg_rec.interface_line_attribute1);
     x_error_code      := find_max ( x_error_code, x_error_code_temp);
     --xx_emf_pkg.propagate_error( x_error_code_temp);

     --IF p_trx_stg_rec.account_class = 'REV' THEN         --Modified as data file having one REC line for each REV line
        x_error_code_temp := is_iface_line_attribute2_null(p_trx_stg_rec.interface_line_attribute2);
        x_error_code      := find_max ( x_error_code, x_error_code_temp);
        --xx_emf_pkg.propagate_error( x_error_code_temp);
     --END IF;

     x_error_code_temp := is_amount_null(p_trx_stg_rec.amount);
     x_error_code      := find_max ( x_error_code, x_error_code_temp);

     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of PRE-Validations x_error_code= '||x_error_code);
     RETURN x_error_code;

   END pre_validations;

   --Function to perform Data-validations
   FUNCTION  data_validations (p_trx_piface_rec IN OUT xx_inv_trx_dist_cnv_pkg.g_xx_ar_cnv_pre_std_rec_type )
   RETURN NUMBER
   IS

     x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;

     FUNCTION is_operating_unit_valid (
               p_operating_unit_name   IN OUT   VARCHAR2
              ,p_org_id                IN OUT      NUMBER
              ,p_account_class   IN VARCHAR2
              ,p_int_line_contxt IN VARCHAR2
	      ,p_int_line_attr1  IN VARCHAR2
	      ,p_int_line_attr2  IN VARCHAR2
           )
              RETURN NUMBER
           IS
              x_error_code       NUMBER        := xx_emf_cn_pkg.cn_success;
              x_bsource_name   VARCHAR2 (40);
           BEGIN
              xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                    'Validations for Operating Unit Name'
                                   );

                 SELECT DISTINCT batch_source_name
                   INTO x_bsource_name
                   FROM xx_ar_inv_trx_stg
                  WHERE interface_line_attribute1 = p_int_line_attr1
                    AND interface_line_attribute2 = p_int_line_attr2
                    AND interface_line_context    = p_int_line_contxt
                    AND batch_id = p_trx_piface_rec.batch_id;

               SELECT org_id
                 INTO p_org_id
                 FROM ra_batch_sources_all
                WHERE UPPER (NAME) = UPPER (x_bsource_name)
                  AND status = 'A'
                  AND TRUNC (SYSDATE) >= TRUNC (NVL (start_date, SYSDATE))
                  AND TRUNC (SYSDATE) <= TRUNC (NVL (end_date, SYSDATE + 1));

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
                     p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                   || ' - Invalid : Operating Unit IS NULL',
                     p_record_identifier_1      => p_trx_piface_rec.record_number,
                     p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                     p_record_identifier_3      => p_trx_piface_rec.operating_unit_name
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
                     p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                   || ' - Invalid Operating Unit Name =>'
                                                   || p_operating_unit_name
                                                   || '-'
                                                   || xx_emf_cn_pkg.cn_too_many,
                     p_record_identifier_1      => p_trx_piface_rec.record_number,
                     p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                     p_record_identifier_3      => p_trx_piface_rec.operating_unit_name
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
                     p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                   || ' - Invalid Operating Unit Name =>'
                                                   || p_operating_unit_name
                                                   || '-'
                                                   || xx_emf_cn_pkg.cn_no_data,
                     p_record_identifier_1      => p_trx_piface_rec.record_number,
                     p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                     p_record_identifier_3      => p_trx_piface_rec.operating_unit_name
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
                     p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                   || ' - Invalid Operating Unit Name =>'
                                                   || p_operating_unit_name
                                                   || '-'
                                                   || SQLERRM,
                     p_record_identifier_1      => p_trx_piface_rec.record_number,
                     p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                     p_record_identifier_3      => p_trx_piface_rec.operating_unit_name
                    );
                 xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                          'X_ERROR_CODE Operating Unit Name: '
                                       || x_error_code
                                      );
                 RETURN x_error_code;
      END is_operating_unit_valid;

     FUNCTION is_line_attr_valid ( p_int_line_contxt IN VARCHAR2
                                  ,p_int_line_attr1  IN VARCHAR2
                                  ,p_int_line_attr2  IN VARCHAR2
                                  ,p_account_class   IN VARCHAR2)
      RETURN NUMBER
      IS
        x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
        x_variable     VARCHAR2 (40);
      BEGIN

        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Interface Line Attr1-2 Validation ');

                SELECT 'X'
                INTO x_variable
                FROM xx_ar_inv_trx_stg
                WHERE interface_line_attribute1 = p_int_line_attr1
                  AND interface_line_attribute2 = p_int_line_attr2
                  AND interface_line_context    = p_int_line_contxt
                  AND batch_id = p_trx_piface_rec.batch_id;

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
                   p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                 || ' - Invalid Interface Line Attr1-2 => '
                                                 || p_int_line_contxt
                                                 || '-'
                                                 || xx_emf_cn_pkg.cn_no_data,
                   p_record_identifier_1      => p_trx_piface_rec.record_number,
                   p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trx_piface_rec.interface_line_context
                  );
               RETURN x_error_code;
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.write_log
                                  (xx_emf_cn_pkg.cn_low,
                                      'Errors In Interface Line Attr1-2 Validation '
                                   || SQLCODE
                                  );
               xx_emf_pkg.error
                  (p_severity                 => xx_emf_cn_pkg.cn_medium,
                   p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                   p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                 || ' - Invalid Interface Line Attr1-2 => '
                                                 || p_int_line_contxt
                                                 || '-'
                                                 || SQLERRM,
                   p_record_identifier_1      => p_trx_piface_rec.record_number,
                   p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                   p_record_identifier_3      => p_trx_piface_rec.interface_line_context
                  );
               RETURN x_error_code;

      END is_line_attr_valid;

      FUNCTION is_line_dist_amount_valid (
               p_int_line_ctxt    IN   VARCHAR2,
               p_int_line_attr1   IN   VARCHAR2,
               p_int_line_attr2   IN   VARCHAR2
            )
               RETURN NUMBER
            IS
               x_error_code     NUMBER := xx_emf_cn_pkg.cn_success;
               l_rec_amount     NUMBER;
               l_dist_amt_sum   NUMBER;
               l_cust_trx_type  VARCHAR2(50);
            BEGIN
               xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                        'Distribution Amount Validation '
                                     || p_int_line_attr2
                                    );

               BEGIN
                  --Fetch trx type
                  SELECT cust_trx_type_name
		    INTO l_cust_trx_type
		    FROM xx_ar_inv_trx_stg
		   WHERE interface_line_attribute1 = p_int_line_attr1
		     AND interface_line_attribute2 = p_int_line_attr2
                     AND interface_line_context    = p_int_line_ctxt
                     AND batch_id = p_trx_piface_rec.batch_id;

                  IF l_cust_trx_type = 'Credit Memo' THEN  --Added for Credit Memo
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
                        AND batch_id = p_trx_piface_rec.batch_id;
                  ELSE
                     SELECT NVL (amount, 0)
		       INTO l_rec_amount
		       FROM xx_ar_inv_trx_dist_stg
		      WHERE interface_line_attribute1 = p_int_line_attr1
		        AND interface_line_attribute2 = p_int_line_attr2
		     	AND interface_line_context = p_int_line_ctxt
                        AND account_class = 'REC'
                        AND batch_id = p_trx_piface_rec.batch_id;
                  END IF;
                  IF l_cust_trx_type = 'Credit Memo' THEN  --Added for Credit Memo
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
                        AND batch_id = p_trx_piface_rec.batch_id;
                  ELSE
                     SELECT NVL (amount, 0)
                       INTO l_dist_amt_sum
                       FROM xx_ar_inv_trx_dist_stg
                      WHERE interface_line_attribute1 = p_int_line_attr1
                        AND interface_line_attribute2 = p_int_line_attr2
                        AND interface_line_context = p_int_line_ctxt
                        AND account_class IN ('REV', 'TAX', 'FREIGHT')
                        AND batch_id = p_trx_piface_rec.batch_id;
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
                         p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                       || ' - Invalid Distributions => '
                                                       || p_int_line_attr2
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_trx_piface_rec.record_number,
                         p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                         p_record_identifier_3      => p_trx_piface_rec.interface_line_context
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
                         p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                       || ' - Invalid Distributions => '
                                                       || p_int_line_attr2
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_trx_piface_rec.record_number,
                         p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                         p_record_identifier_3      => p_trx_piface_rec.interface_line_context
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
                         p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                       || ' - Invalid Distributions => '
                                                       || p_int_line_attr2
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_trx_piface_rec.record_number,
                         p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                         p_record_identifier_3      => p_trx_piface_rec.interface_line_context
                        );
                     RETURN x_error_code;
               END;

               IF l_rec_amount <> l_dist_amt_sum
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error
                     (p_severity                 => xx_emf_cn_pkg.cn_medium,
                      p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                      p_error_text               => ' - Invalid : Total distributions not equal to REC dist amount => ',
                      p_record_identifier_1      => p_trx_piface_rec.record_number,
                      p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                      p_record_identifier_3      => p_trx_piface_rec.interface_line_context
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
                      p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                    || ' - Invalid Distributions => '
                                                    || p_int_line_attr2
                                                    || '-'
                                                    || SQLERRM,
                      p_record_identifier_1      => p_trx_piface_rec.record_number,
                      p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                      p_record_identifier_3      => p_trx_piface_rec.interface_line_context
                     );
                  RETURN x_error_code;
      END is_line_dist_amount_valid;

      FUNCTION is_account_class_valid ( p_account_class IN OUT VARCHAR2
                                      )
            RETURN NUMBER
            IS
              x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
              x_variable     VARCHAR2 (40);
            BEGIN

              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Account Class Validation ');

                      p_account_class := UPPER(p_account_class);

                      SELECT 'X'
                      INTO x_variable
                      FROM dual
                      WHERE p_account_class IN ('REC','REV','TAX','FREIGHT');

                      IF p_account_class = 'TAX' THEN
                         SELECT 'X'
			   INTO x_variable
			   FROM xx_ar_inv_trx_stg
			  WHERE interface_line_attribute1 = p_trx_piface_rec.interface_line_attribute1
			    AND interface_line_attribute2 = p_trx_piface_rec.interface_line_attribute2
                            AND interface_line_context    = p_trx_piface_rec.interface_line_context
                            AND line_type = 'TAX'
                            AND batch_id = p_trx_piface_rec.batch_id;
                      ELSIF p_account_class = 'REV' THEN
                         SELECT 'X'
			   INTO x_variable
			   FROM xx_ar_inv_trx_stg
			  WHERE interface_line_attribute1 = p_trx_piface_rec.interface_line_attribute1
			    AND interface_line_attribute2 = p_trx_piface_rec.interface_line_attribute2
			    AND interface_line_context    = p_trx_piface_rec.interface_line_context
                            AND line_type = 'LINE'
                            AND batch_id = p_trx_piface_rec.batch_id;
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
                         p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                       || ' - Invalid Account Class => '
                                                       || p_account_class
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_too_many,
                         p_record_identifier_1      => p_trx_piface_rec.record_number,
                         p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                         p_record_identifier_3      => p_trx_piface_rec.account_class
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
                         p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                       || ' - Invalid Account Class => '
                                                       || p_account_class
                                                       || '-'
                                                       || xx_emf_cn_pkg.cn_no_data,
                         p_record_identifier_1      => p_trx_piface_rec.record_number,
                         p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                         p_record_identifier_3      => p_trx_piface_rec.account_class
                        );
                     RETURN x_error_code;
                  WHEN OTHERS
                  THEN
                     x_error_code := xx_emf_cn_pkg.cn_rec_err;
                     xx_emf_pkg.write_log
                                        (xx_emf_cn_pkg.cn_low,
                                            'Errors In Account Class Validation '
                                         || SQLCODE
                                        );
                     xx_emf_pkg.error
                        (p_severity                 => xx_emf_cn_pkg.cn_medium,
                         p_category                 => xx_emf_cn_pkg.cn_stg_dataval,
                         p_error_text               =>    p_trx_piface_rec.interface_line_attribute2
                                                       || ' - Invalid Account Class => '
                                                       || p_account_class
                                                       || '-'
                                                       || SQLERRM,
                         p_record_identifier_1      => p_trx_piface_rec.record_number,
                         p_record_identifier_2      => p_trx_piface_rec.interface_line_attribute1,
                         p_record_identifier_3      => p_trx_piface_rec.account_class
                        );
                     RETURN x_error_code;

      END is_account_class_valid;

   BEGIN

     --Operating Unit Name Validation
     x_error_code_temp := is_operating_unit_valid( p_trx_piface_rec.operating_unit_name
                                                  ,p_trx_piface_rec.org_id
                                                  ,p_trx_piface_rec.account_class
                                                  ,p_trx_piface_rec.interface_line_context
                                                  ,p_trx_piface_rec.interface_line_attribute1
                                                  ,p_trx_piface_rec.interface_line_attribute2);
     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After is_operating_unit_valid Errord code=: '||  x_error_code);

     --Line Attributes Validation
     x_error_code_temp := is_line_attr_valid(p_trx_piface_rec.interface_line_context
                                            ,p_trx_piface_rec.interface_line_attribute1
                                            ,p_trx_piface_rec.interface_line_attribute2
                                            ,p_trx_piface_rec.account_class);
     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After is_line_attr_valid Errord code=: '||  x_error_code);

     --Line Dist Amount Validation Validation
     x_error_code_temp := is_line_dist_amount_valid( p_trx_piface_rec.interface_line_context
                                                    ,p_trx_piface_rec.interface_line_attribute1
                                                    ,p_trx_piface_rec.interface_line_attribute2);
     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After is_line_dist_amount_valid Errord code=: '||  x_error_code);

     --Account Class Validation
     x_error_code_temp := is_account_class_valid( p_trx_piface_rec.account_class );
     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After is_account_class_valid Errord code=: '||  x_error_code);

     RETURN   x_error_code;
   END data_validations ;

   --Function to perform Data-derivations
   FUNCTION  data_derivations (p_trxcnv_preiface_rec IN OUT xx_inv_trx_dist_cnv_pkg.G_XX_AR_CNV_PRE_STD_REC_TYPE )
   RETURN NUMBER
   IS
      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

       --Function to fetch code combination id
      FUNCTION get_oracle_segment_ccid (p_trxcnv_preiface_rec IN OUT xx_inv_trx_dist_cnv_pkg.G_XX_AR_CNV_PRE_STD_REC_TYPE)
      RETURN NUMBER
      IS

         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_derived_segment1 VARCHAR2(50);
         x_derived_segment2 VARCHAR2(50);
         x_derived_segment3 VARCHAR2(50);
         x_derived_segment4 VARCHAR2(50);
         x_derived_segment5 VARCHAR2(50);
         x_derived_segment6 VARCHAR2(50);
         x_derived_segment7 VARCHAR2(50);
         x_derived_segment8 VARCHAR2(50);
         x_derived_segment9 VARCHAR2(50);
         x_source_name     VARCHAR2(100);
         x_cc_id            NUMBER := NULL;
         x_legacy_system   VARCHAR2(100);

      BEGIN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Account Segment CCID derivation ');
         --Fetch source system name
         BEGIN
            SELECT DISTINCT source_system_name
       	      INTO x_source_name
	      FROM xx_ar_inv_trx_stg
	     WHERE interface_line_attribute1 = p_trxcnv_preiface_rec.interface_line_attribute1
	       AND interface_line_attribute2 = p_trxcnv_preiface_rec.interface_line_attribute2
	       AND interface_line_context    = p_trxcnv_preiface_rec.interface_line_context
	       AND batch_id = p_trxcnv_preiface_rec.batch_id;
	 EXCEPTION
	     WHEN TOO_MANY_ROWS THEN
	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
	        xx_emf_pkg.error
	                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
	                    p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
	                    p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
	                                  || ' - Invalid : Error while fetching source system name =>'
	                                  || p_trxcnv_preiface_rec.batch_id
	                                  || '-'
	                                  || xx_emf_cn_pkg.cn_too_many,
	                    p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	                    p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	                    p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_attribute2
                              );
                 RETURN x_error_code;
             WHEN NO_DATA_FOUND THEN
	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
	        xx_emf_pkg.error
	                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
	                    p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
	                    p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
	                                  || ' - Invalid : Error while fetching source system name =>'
	                                  || p_trxcnv_preiface_rec.batch_id
	                                  || '-'
	                                  || xx_emf_cn_pkg.cn_no_data,
	                    p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	                    p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	                    p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_attribute2
                              );
                 RETURN x_error_code;
             WHEN OTHERS THEN
	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
	        xx_emf_pkg.error
	                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
	                    p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
	                    p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
	                                  || ' - Invalid : Error while fetching source system name =>'
	                                  || p_trxcnv_preiface_rec.batch_id
	                                  || '-'
	                                  || SQLERRM,
	                    p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	                    p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	                    p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_attribute2
                              );
                 RETURN x_error_code;
	 END;
	 --Ftech maaping value for source
         x_legacy_system :=
	             xx_intg_common_pkg.get_mapping_value ( p_mapping_type => 'LEGACY_SYSTEM'
	                                                   ,p_old_value => x_source_name
	                                                   ,p_date_effective => SYSDATE
                                                          );

         --x_legacy_system := 'DATAFLOW';
         --Call Function to get CC ID
         x_cc_id := NULL;
         BEGIN
            x_cc_id := xx_gl_cons_ffield_load_pkg.get_ccid( p_trxcnv_preiface_rec.segment1
	    	  				           ,p_trxcnv_preiface_rec.segment2
	    						   ,p_trxcnv_preiface_rec.segment3
	    						   ,p_trxcnv_preiface_rec.segment4
	    						   ,p_trxcnv_preiface_rec.segment5
	    						   ,p_trxcnv_preiface_rec.segment6
	    						   ,p_trxcnv_preiface_rec.segment7
	    						   ,p_trxcnv_preiface_rec.segment8
	    						   ,x_legacy_system
	    						   ,'AR'
                                                          );
          EXCEPTION
             WHEN OTHERS THEN
	        x_error_code := xx_emf_cn_pkg.cn_rec_err;
	        xx_emf_pkg.error
	                   (p_severity                 => xx_emf_cn_pkg.cn_medium,
	                    p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
	                    p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
	                                  || ' - Invalid : Error after xx_gl_cons_ffield_load_pkg.get_ccid =>'
	                                  || x_cc_id
	                                  || '-'
	                                  || SQLERRM,
	                    p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	                    p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	                    p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_attribute2
                              );
                 RETURN x_error_code;
          END;
          --If CC ID null
          IF x_cc_id IS NULL OR x_cc_id = 0 THEN
             x_error_code := xx_emf_cn_pkg.cn_rec_err;
	     xx_emf_pkg.error
	                (p_severity                 => xx_emf_cn_pkg.cn_medium,
	                 p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
	                 p_error_text               => p_trxcnv_preiface_rec.interface_line_attribute2
	                               || ' - Invalid : Segment Derivation Failed =>'
	                               || p_trxcnv_preiface_rec.segment1,
	                 p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
	                 p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
	                 p_record_identifier_3      => p_trxcnv_preiface_rec.segment2
                            );
          ELSE --If CC ID is not null then fetech segment values
	     BEGIN
	        SELECT gcc.segment1,gcc.segment2,gcc.segment3,gcc.segment4,
	               gcc.segment5,gcc.segment6,gcc.segment7,gcc.segment8
	          INTO x_derived_segment1,x_derived_segment2,x_derived_segment3,x_derived_segment4,
	               x_derived_segment5,x_derived_segment6,x_derived_segment7,x_derived_segment8
	          FROM gl_code_combinations gcc
	         WHERE gcc.code_combination_id = x_cc_id;
	     EXCEPTION
	        WHEN TOO_MANY_ROWS THEN
                   x_error_code := xx_emf_cn_pkg.cn_rec_err;
                   xx_emf_pkg.error
                           (p_severity                 => xx_emf_cn_pkg.cn_medium,
                            p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                            p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
					  || ' - Invalid : Error while fetching Segment Values =>'
					  || x_cc_id
					  || '-'
					  || xx_emf_cn_pkg.cn_too_many,
			    p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
			    p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
			    p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_attribute2
		          );
		RETURN x_error_code;
	        WHEN NO_DATA_FOUND THEN
		   x_error_code := xx_emf_cn_pkg.cn_rec_err;
		   xx_emf_pkg.error
			   (p_severity                 => xx_emf_cn_pkg.cn_medium,
			    p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
			    p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
					  || ' - Invalid : Error while fetching Segment Values =>'
					  || x_cc_id
					  || '-'
					  || xx_emf_cn_pkg.cn_no_data,
			    p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
			    p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
			    p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_attribute2
			   );
		RETURN x_error_code;
	        WHEN OTHERS THEN
		   x_error_code := xx_emf_cn_pkg.cn_rec_err;
		   xx_emf_pkg.error
		   	   (p_severity                 => xx_emf_cn_pkg.cn_medium,
			    p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
			    p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
					  || ' - Invalid : Error while fetching Segment Values =>'
					  || x_cc_id
					  || '-'
					  || SQLERRM,
			    p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
			    p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
			    p_record_identifier_3      => p_trxcnv_preiface_rec.interface_line_attribute2
		           );
		RETURN x_error_code;
	     END;
	     --Assign values
             p_trxcnv_preiface_rec.code_combination_id := x_cc_id;
             p_trxcnv_preiface_rec.segment1 := x_derived_segment1;
             p_trxcnv_preiface_rec.segment2 := x_derived_segment2;
             p_trxcnv_preiface_rec.segment3 := x_derived_segment3;
             p_trxcnv_preiface_rec.segment4 := x_derived_segment4;
             p_trxcnv_preiface_rec.segment5 := x_derived_segment5;
             p_trxcnv_preiface_rec.segment6 := x_derived_segment6;
             p_trxcnv_preiface_rec.segment7 := x_derived_segment7;
             p_trxcnv_preiface_rec.segment8 := x_derived_segment8;
          END IF;
      RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS THEN
            xx_emf_pkg.write_log
                      (xx_emf_cn_pkg.cn_low,
                          'Errors In Code Combination Id Derivation '
                       || SQLCODE
                      );
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error
               (p_severity                 => xx_emf_cn_pkg.cn_medium,
                p_category                 => xx_emf_cn_pkg.cn_stg_datadrv,
                p_error_text               =>    p_trxcnv_preiface_rec.interface_line_attribute2
                              || ' - Invalid Code Combination Id =>'
                              || p_trxcnv_preiface_rec.code_combination_id
                              || '-'
                              || SQLERRM,
                p_record_identifier_1      => p_trxcnv_preiface_rec.record_number,
                p_record_identifier_2      => p_trxcnv_preiface_rec.interface_line_attribute1,
                p_record_identifier_3      => p_trxcnv_preiface_rec.code_combination_id
               );
            xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                                 'X_ERROR_CODE Code Combination Id: '
                                 || x_error_code
                                 );
            RETURN x_error_code;
      END get_oracle_segment_ccid;

   BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data Derivation');

    --Code Combination Id Derivation
    x_error_code_temp := get_oracle_segment_ccid( p_trxcnv_preiface_rec );
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After get_oracle_segment_ccid Errord code=: '||  x_error_code);

        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Completed Data Derivation');
    RETURN x_error_code;

   EXCEPTION
   WHEN OTHERS THEN
     x_error_code := xx_emf_cn_pkg.cn_rec_err;
     xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Error in Data Derivatoin = '||SQLERRM);
     RETURN x_error_code;
   END data_derivations;

   --Function to perform Post validations
   FUNCTION post_validations
         RETURN NUMBER
      IS
         x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
         RETURN x_error_code;
   END post_validations;

END xx_ar_trx_dist_cnv_val_pkg;
/


GRANT EXECUTE ON APPS.XX_AR_TRX_DIST_CNV_VAL_PKG TO INTG_XX_NONHR_RO;
