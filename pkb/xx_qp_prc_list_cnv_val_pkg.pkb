DROP PACKAGE BODY APPS.XX_QP_PRC_LIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_PRC_LIST_CNV_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Debjani Roy
 Creation Date : 24-May-13
 File Name     : XXQPPRICELISTCNVVL.pkb
 Description   : This script creates the body of the package xx_qp_prc_list_cnv_val_pkg
 CCID00

 Change History:

 Version Date        Name       Remarks
-------- ----------- ----       ---------------------------------------
 1.0     24-May-13 Debjani Roy   Initial development.
*/
----------------------------------------------------------------------


--**********************************************************************
  --Function to Find Max.
--**********************************************************************

FUNCTION find_max (
    p_error_code1 IN VARCHAR2,
    p_error_code2 IN VARCHAR2
    )
RETURN VARCHAR2
IS
    x_return_value VARCHAR2(100);
BEGIN
    --x_return_value := xx_asl_common_pkg.find_max(p_error_code1, p_error_code2);
    SELECT DECODE(SIGN (to_number(p_error_code1)-(p_error_code2))
                  ,1
                  ,p_error_code1
                  ,-1
                  ,p_error_code2
                  ,p_error_code1)
    INTO   x_return_value
    FROM DUAL;

    RETURN x_return_value;
END find_max;



--**********************************************************************
  --Function to return lookup values.
--**********************************************************************

FUNCTION find_lookup_value (
    p_lookup_type IN VARCHAR2,
    p_lookup_value IN VARCHAR2,
    p_lookup_text IN VARCHAR2,
    p_record_number IN VARCHAR2,
    p_orig_sys_header_ref IN VARCHAR2,
    p_orig_sys_line_ref    IN VARCHAR2 DEFAULT NULL,
    p_orig_sys_pricing_attr_ref IN VARCHAR2 DEFAULT NULL
    )
RETURN VARCHAR2
IS
    x_lookup_value VARCHAR2(30);
BEGIN
       SELECT b.lookup_code
        INTO x_lookup_value
        FROM fnd_lookup_types a,
        fnd_lookup_values b
        WHERE
        a.lookup_type=b.lookup_type
        AND a.lookup_type=p_lookup_type
        AND language=UserEnv('LANG')
    AND UPPER(meaning)=UPPER(p_lookup_value);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_lookup_value ' || x_lookup_value);
    RETURN x_lookup_value;
EXCEPTION
    WHEN TOO_MANY_ROWS THEN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
       --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
       x_lookup_value:='';
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                        ,p_error_text  => 'Invalid '||p_lookup_text||'=>'||xx_emf_cn_pkg.CN_TOO_MANY
                        ,p_record_identifier_1 => p_record_number
                        ,p_record_identifier_2 => p_orig_sys_header_ref
                        ,p_record_identifier_3 => p_orig_sys_line_ref
                        ,p_record_identifier_4 => p_orig_sys_pricing_attr_ref
                        ,p_record_identifier_5 => p_lookup_value
                          );
                        --RETURN x_error_code;
       RETURN x_lookup_value;
    WHEN NO_DATA_FOUND THEN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
       --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
       x_lookup_value:='';
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                        ,p_error_text  => 'Invalid '||p_lookup_text||'=>'||xx_emf_cn_pkg.CN_NO_DATA
                        ,p_record_identifier_1 => p_record_number
                        ,p_record_identifier_2 => p_orig_sys_header_ref
                        ,p_record_identifier_3 => p_orig_sys_line_ref
                        ,p_record_identifier_4 => p_orig_sys_pricing_attr_ref
                        ,p_record_identifier_5 => p_lookup_value
                         );

     --RETURN x_error_code;
     RETURN x_lookup_value;
    WHEN OTHERS THEN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In  '||p_lookup_text||' Validation ' || SQLCODE);
       --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
       x_lookup_value:='';
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                        ,p_error_text  => 'Errors In  '||p_lookup_text||' Validation ' ||SQLERRM
                        ,p_record_identifier_1 => p_record_number
                        ,p_record_identifier_2 => p_orig_sys_header_ref
                        ,p_record_identifier_3 => p_orig_sys_line_ref
                        ,p_record_identifier_4 => p_orig_sys_pricing_attr_ref
                        ,p_record_identifier_5 => p_lookup_value
                         );
     RETURN x_lookup_value;
END find_lookup_value;


--**********************************************************************
  --Function to Pre Validations .
--**********************************************************************

FUNCTION pre_validations (p_batch_id IN VARCHAR2)
RETURN NUMBER
IS
 x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
 x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
 x_count NUMBER;
 r_count NUMBER;

 BEGIN
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium,'Inside Pre-Validations');

 BEGIN
       UPDATE xx_qp_pr_list_hdr_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
       WHERE batch_id = p_batch_id
         AND currency_code is null
         AND DESELECT_FLAG IS NULL;


     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'CURRENCY_CODE is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'CURRENCY_CODE is null for' || x_count ||' Records'
                 );
     END IF;

     --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in CURRENCY_CODE Validation  ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in CURRENCY_CODE Validation=>'||SQLERRM
                  );
      --RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_qp_pr_list_hdr_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
       WHERE batch_id = p_batch_id
        AND list_type_code is null
        AND DESELECT_FLAG IS NULL;


     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'LIST_TYPE_CODE is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                         ,p_error_text  => 'LIST_TYPE_CODE is null for' || x_count||' Records'
                         );
     END IF;

     --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in LIST_TYPE_CODE Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                       ,p_error_text  => 'Errors in LIST_TYPE_CODE Validation=>'||SQLERRM
                       );
      --RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_qp_pr_list_hdr_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
        WHERE batch_id = p_batch_id
         AND name is null
         AND DESELECT_FLAG IS NULL;



     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Price List NAME is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                         ,p_error_text  => 'Price List NAME is null for ' || x_count ||' Records'
                         );
     END IF;
     --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in Price List NAME Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                       ,p_error_text  => 'Errors in Price List NAME Validation=>'||SQLERRM
                  );
      --RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_qp_pr_list_hdr_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
        WHERE batch_id = p_batch_id
         AND orig_sys_header_ref is null
         AND DESELECT_FLAG IS NULL;

     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ORIG_SYS_HEADER_REF is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                         ,p_error_text  => 'ORIG_SYS_HEADER_REF is null for ' || x_count ||' Records'
                         );
     END IF;
     --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in ORIG_SYS_HEADER_REF Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                       ,p_error_text  => 'Errors in ORIG_SYS_HEADER_REF Validation=>'||SQLERRM
                       );
      --RETURN x_error_code;
  END;


  BEGIN
       UPDATE xx_qp_pr_list_lines_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
        WHERE batch_id = p_batch_id
         AND LIST_LINE_TYPE_CODE is null
         AND DESELECT_FLAG IS NULL;


     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'LIST_LINE_TYPE_CODE is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                         ,p_error_text  => 'LIST_LINE_TYPE_CODE Code is null for ' || x_count ||' Records'
                         );
     END IF;
     --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in LIST_LINE_TYPE_CODE Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                       ,p_error_text  => 'Errors in LIST_LINE_TYPE_CODE Validation=>'||SQLERRM
                       );
      --RETURN x_error_code;
  END;


  BEGIN
         UPDATE xx_qp_pr_list_lines_stg
         SET
          process_code = xx_emf_cn_pkg.CN_PREVAL,
          error_code = xx_emf_cn_pkg.CN_REC_ERR
         WHERE batch_id = p_batch_id
           AND (ORIG_SYS_LINE_REF is null
               OR ORIG_SYS_HEADER_REF is null )
           AND DESELECT_FLAG IS NULL;


         IF SQL%ROWCOUNT > 0
         THEN
             x_count:=SQL%ROWCOUNT;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ORIG_SYS_LINE_REF is null for ' || x_count ||' Records');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                             ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                             ,p_error_text  => 'ORIG_SYS_LINE_REF is null for ' || x_count ||' Records'
                             );

         END IF;
         --RETURN x_error_code;
      EXCEPTION
        WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in ORIG_SYS_LINE_REF Validation ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                      ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                   ,p_error_text  => 'Errors in ORIG_SYS_LINE_REF Validation=>'||SQLERRM
                      );
        --RETURN x_error_code;
  END;

  BEGIN
         UPDATE xx_qp_pr_list_lines_stg
         SET
          process_code = xx_emf_cn_pkg.CN_PREVAL,
          error_code = xx_emf_cn_pkg.CN_REC_ERR
         WHERE batch_id = p_batch_id
           AND orig_sys_line_ref in (SELECT orig_sys_line_ref
                                     FROM xx_qp_pr_list_lines_stg
                                     WHERE orig_sys_line_ref <> '-1'
                                       AND batch_id = p_batch_id
                                     GROUP BY orig_sys_line_ref
                                     HAVING count(record_number) > 1
                                    )
           AND DESELECT_FLAG IS NULL
           ;


         IF SQL%ROWCOUNT > 0
         THEN
             x_count:=SQL%ROWCOUNT;
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ORIG_SYS_LINE_REF is duplicate for ' || x_count ||' Records');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                             ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                             ,p_error_text  => 'ORIG_SYS_LINE_REF is duplicate for ' || x_count ||' Records'
                             );

         END IF;
         --RETURN x_error_code;
      EXCEPTION
        WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in ORIG_SYS_LINE_REF duplicate Validation ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                      ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                   ,p_error_text  => 'Errors in ORIG_SYS_LINE_REF duplicate Validation=>'||SQLERRM
                      );
        --RETURN x_error_code;
  END;


  --
    -- Validation for Qualifiers
    --
    --
    -- validation of Modifier Name on Qualifier
    --
    UPDATE xx_qp_pr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Modifier Name is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND orig_sys_header_ref IS NULL
       AND DESELECT_FLAG IS NULL;

    BEGIN
       UPDATE xx_qp_pr_list_qlf_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR,
        error_desc = error_desc || '~Qualifier - Orig Sys Line Ref is populated'
        WHERE batch_id = p_batch_id
         AND NVL(orig_sys_line_ref,'-1') <> '-1'
         AND DESELECT_FLAG IS NULL;


     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ORIG_SYS_LINE_REF in Qualifier is not null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                         ,p_error_text  => 'ORIG_SYS_LINE_REF in Qualifier is not null for ' || x_count ||' Records'
                         );
     END IF;
     --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in Orig Sys Line ref Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                       ,p_error_text  => 'ORIG_SYS_LINE_REF is not null in qualifier for =>'||SQLERRM
                       );
      --RETURN x_error_code;
  END;



    --
    -- validation of Qualifier Context
    --
    UPDATE xx_qp_pr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Context is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND qualifier_context IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Qualifier Attribute
    --
    UPDATE xx_qp_pr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Attribute is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (qualifier_attribute IS NULL)
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Qualifier Grouping Number
    --
    UPDATE xx_qp_pr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Grouping Number is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND qualifier_grouping_no IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Qualifier Precedence
    --
    UPDATE xx_qp_pr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Precedence is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND qualifier_precedence IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Qualifier Operator
    --
    UPDATE xx_qp_pr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Operator is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND comparison_operator_code IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Qualifier Attribute Value
    --
    UPDATE xx_qp_pr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Attribute Value is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (qualifier_attr_value_disp IS NULL )
       AND DESELECT_FLAG IS NULL;


  BEGIN
          SELECT count(*)
          INTO r_count
          FROM
              xx_qp_pr_list_hdr_stg
          WHERE
           batch_id = p_batch_id
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Total Number of Errored Records in PLH Staging Table=> ' || r_count);
           /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                            ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                            ,p_error_text  => 'Total Number of Errored Records in Staging Table=> ' || r_count
                            );*/
        --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in getting errored record count ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                       ,p_error_text  => 'Errors in getting errored record count =>'||SQLERRM
                       );


  END;
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code before returning'||x_error_code);

  BEGIN
          SELECT count(*)
          INTO r_count
          FROM
              xx_qp_pr_list_lines_stg
          WHERE
           batch_id = p_batch_id
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Total Number of Errored Records in PLL Staging Table=> ' || r_count);
          /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                           ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                           ,p_error_text  => 'Total Number of Errored Records in Staging Table=> ' || r_count
                            );*/
        --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in getting errored record count ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in getting errored record count =>'||SQLERRM
                  );


  END;
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code before returning'||x_error_code);


  BEGIN
          SELECT count(*)
          INTO r_count
          FROM
              xx_qp_pr_list_qlf_stg
          WHERE
           batch_id = p_batch_id
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Total Number of Errored Records in PLQ Staging Table=> ' || r_count);
          /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                   ,p_error_text  => 'Total Number of Errored Records in Staging Table=> ' || r_count
                   );*/
        --RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in getting errored record count ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in getting errored record count =>'||SQLERRM
                  );


  END;
  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code before returning'||x_error_code);

  COMMIT;
  --xx_emf_pkg.propagate_error (x_error_code);
  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_error_code);
  RETURN x_error_code;
 EXCEPTION
        WHEN xx_emf_pkg.G_E_REC_ERROR THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_error_code);
            RETURN x_error_code;
        WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_error_code);
            RETURN x_error_code;
        WHEN OTHERS THEN
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,x_error_code);
            RETURN x_error_code;
 END pre_validations;


--**********************************************************************
--Function to Data Validations .
--**********************************************************************

FUNCTION data_validations (p_cnv_hdr_rec IN OUT xx_qp_pr_list_hdr_pre%ROWTYPE
                          --,p_header_line IN VARCHAR2
                          )
RETURN NUMBER
IS

x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

 --- Local functions for all batch level validations
 --- Add as many functions as required in here

  --**********************************************************************
     --Function to derive and validate Price LIST
  --**********************************************************************

 FUNCTION is_price_list_exists(p_name IN VARCHAR2
                             -- ,p_list_header_id OUT NUMBER
                              --,p_interface_action_code OUT VARCHAR2
                              )
 RETURN NUMBER
 IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_err_code   VARCHAR2(30);
    x_err_msg    VARCHAR2(200);
    x_list_header_id      NUMBER;
    x_qlf_list_count      NUMBER;
    x_qlf_stg_count       NUMBER;


 BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'List name After derive ' || p_name);
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'List name length ' || length(p_name));
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'User Language ' || USERENV('LANG'));
    SELECT b.list_header_id
    INTO x_list_header_id
    FROM
    qp_list_headers_b a,
    qp_list_headers_tl b
    WHERE 1=1
    AND a.list_header_id=b.list_header_id
    AND language=USERENV('LANG')
    AND a.list_type_code = 'PRL'
    AND b.name=p_name
    AND ROWNUM<2
    ;
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'List Header Id After derive ');-- || p_list_header_id);

      /*  IF(x_list_header_id IS NULL) THEN
         p_interface_action_code:='INSERT';
         RETURN x_error_code;
        ELSE
         p_interface_action_code:='UPDATE';
         RETURN x_error_code;
        END IF;*/
        IF x_list_header_id IS NOT NULL THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Pricelist already exists ');
            SELECT count(1)
            INTO x_qlf_list_count
            FROM qp_qualifiers
            WHERE list_header_id IN
                                (SELECT list_header_id
                                 FROM   qp_list_headers_all
                                  WHERE  name = p_name
                                  AND list_type_code = 'PRL');
            SELECT count(1)
            INTO x_qlf_stg_count
            FROM xx_qp_pr_list_qlf_pre qlf
            WHERE orig_sys_header_ref IN
                                (SELECT orig_sys_header_ref
                                 FROM   xx_qp_pr_list_hdr_pre hdr
                                  WHERE  name = p_name
                                   AND hdr.batch_id = qlf.batch_id
                                  AND list_type_code = 'PRL')
             AND batch_id = p_cnv_hdr_rec.batch_id;

             IF x_qlf_list_count = 0 AND x_qlf_stg_count >0 THEN
                x_error_code := xx_emf_cn_pkg.CN_REC_WARN;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Pricelist already exists but qualifiers need to be loaded');
             ELSE
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                        ,p_error_text  => 'PriceList already exists=> '||p_name
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                        ,p_record_identifier_5 => p_name
                       );
             END IF;

        END IF;
   RETURN x_error_code;
   EXCEPTION
           WHEN TOO_MANY_ROWS THEN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               --p_list_header_id:='';
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                        ,p_error_text  => 'Invalid Pricelist Name=>'||xx_emf_cn_pkg.CN_TOO_MANY
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                       );
               RETURN x_error_code;
           WHEN NO_DATA_FOUND THEN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA for Price list ID' );
               --p_list_header_id:='';
               x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
               /*x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                        ,p_error_text  => 'Invalid Pricelist Name =>'||xx_emf_cn_pkg.CN_NO_DATA
                        ,p_record_identifier_1 => p_record_number
                        ,p_record_identifier_2 => p_orig_sys_header_ref
                       );*/
               RETURN x_error_code;
           WHEN OTHERS THEN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Product Context Validation ' || SQLCODE);
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
               --p_list_header_id:='';
               xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                        ,p_error_text  => 'Errors In Pricelist Name Validation=>'||SQLERRM
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                       );
             RETURN x_error_code;
 RETURN x_error_code;
 END is_price_list_exists;





  --**********************************************************************
    --Function to derive and validate Operating Unit
  --**********************************************************************
  FUNCTION is_operating_unit_valid (/*p_organization_code IN VARCHAR2
                                    ,*/p_org_id   OUT NUMBER
                                    ,p_operating_unit IN OUT VARCHAR2
                                    )
  RETURN NUMBER
  IS
          x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
          x_err_code   VARCHAR2(30);
          x_err_msg    VARCHAR2(200);

  BEGIN

        SELECT organization_id , name
        INTO p_org_id,p_operating_unit
        FROM hr_operating_units
        WHERE upper(name)= upper(p_operating_unit)
        ;
  RETURN x_error_code;
  EXCEPTION
  WHEN TOO_MANY_ROWS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
               ,p_error_text  => 'Invalid Opertaing Unit Org_Id =>'||xx_emf_cn_pkg.CN_TOO_MANY
               ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
               ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref

              );
      RETURN x_error_code;
  WHEN NO_DATA_FOUND THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
               ,p_error_text  => 'Invalid Opertaing Unit Org_Id =>'||xx_emf_cn_pkg.CN_NO_DATA
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                        ,p_record_identifier_5 => p_operating_unit
              );
      RETURN x_error_code;
  WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Opertaing Unit Org_Id Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
               ,p_error_text  => 'Errors In Opertaing Unit Org_Id Validation=>'||SQLERRM
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
             );
       RETURN x_error_code;
   RETURN x_error_code;

  END is_operating_unit_valid;


  --**********************************************************************
      --Function to derive and validate Currency Code
 --**********************************************************************
    FUNCTION is_currency_code_valid (p_currency_code IN VARCHAR2
                         --,p_currency_header_id OUT NUMBER
                         )
    RETURN NUMBER
    IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_err_code   VARCHAR2(30);
            x_err_msg    VARCHAR2(200);
            x_currency_header_id NUMBER;

    BEGIN

      SELECT currency_header_id
      INTO x_currency_header_id
      FROM qp_currency_lists_b
      WHERE upper(base_currency_code)= upper(p_currency_code)
      AND rownum<2
      ;

    RETURN x_error_code;
    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                 ,p_error_text  => 'Invalid Currency Code =>'||xx_emf_cn_pkg.CN_TOO_MANY
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                );
        RETURN x_error_code;
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                 ,p_error_text  => 'Invalid Currency Code =>'||xx_emf_cn_pkg.CN_NO_DATA
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                        ,p_record_identifier_5 => p_currency_code
                );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors Currency Code Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                 ,p_error_text  => 'Errors In Currency Code Validation=>'||SQLERRM
                        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                        ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                );
         RETURN x_error_code;
     RETURN x_error_code;

    END is_currency_code_valid;

   --**********************************************************************
  --Function to validate LIST_TYPE_CODE
  --**********************************************************************
    FUNCTION is_list_type_code(
                          p_list_type_code_text IN VARCHAR2
                      ,p_list_type_code  OUT VARCHAR2
                          )
         RETURN NUMBER
         IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           x_list_type_code VARCHAR2(30);
           x_count      NUMBER;

         BEGIN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_list_type_code_text ' || p_list_type_code_text);

        x_list_type_code := find_lookup_value(p_lookup_type            =>'LIST_TYPE_CODE'
                             ,p_lookup_value       => p_list_type_code_text
                             ,p_lookup_text           =>'LIST_TYPE_CODE'
                             ,p_record_number      => p_cnv_hdr_rec.record_number
                             ,p_orig_sys_header_ref => p_cnv_hdr_rec.ORIG_SYS_HEADER_REF
                             --,p_orig_sys_line_ref  => p_cnv_hdr_rec.orig_sys_line_ref DROY
                             --,p_orig_sys_pricing_attr_ref  => p_cnv_hdr_rec.orig_sys_pricing_attr_ref DROY
                            );


        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_list_type_code ' || x_list_type_code);
        IF(x_list_type_code='') THEN
            x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
            RETURN x_error_code;

        else
            p_list_type_code:=x_list_type_code;
            x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
            RETURN x_error_code;
            END IF;

        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In list_type_code Validation ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Errors In list_type_code Validation=>'||SQLERRM
                               ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                               ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                             );
                   RETURN x_error_code;
    END is_list_type_code;

       --**********************************************************************
  --Function to validate whether line exists
  --**********************************************************************
    FUNCTION is_line_exists(
                          p_orig_sys_header_ref IN VARCHAR2
                          )
         RETURN NUMBER
         IS
           x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
           x_list_type_code VARCHAR2(30);
           x_count      NUMBER;

         BEGIN

             SELECT count(orig_sys_line_ref)
             INTO x_count
             FROM xx_qp_pr_list_lines_pre
             WHERE orig_sys_header_ref= p_orig_sys_header_ref
              AND  batch_id = p_cnv_hdr_rec.batch_id
              AND  request_id = p_cnv_hdr_rec.request_id
      ;


        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Lines Count' || x_count);
        IF x_count = 0  THEN
           x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'No lines exist for pricelist'
                               ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                               ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                               ,p_record_identifier_5 => p_cnv_hdr_rec.name
                             );
        END IF;

        EXCEPTION
          WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In count lines Validation ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                               ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                               ,p_error_text  => 'Errors In list_type_code Validation=>'||SQLERRM
                               ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                               ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                             );
                   RETURN x_error_code;
    END is_line_exists;



        ------------------------ Start the BEGIN part of Data Validations ----------------------------------

        BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside header level data validation:');--||p_header_line);
           IF(p_cnv_hdr_rec.name IS NOT NULL)
           THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Price list name; '||p_cnv_hdr_rec.name);
           x_error_code_temp := is_price_list_exists(p_cnv_hdr_rec.name
                                                     --,p_cnv_hdr_rec.list_header_id
                                                     --,p_cnv_hdr_rec.interface_action_code
                                                     );
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_price_list_exists - error '||x_error_code_temp);
           --xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'List_header_id => '||p_cnv_hdr_rec.list_header_id);
           x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           END IF;

           IF(p_cnv_hdr_rec.currency_code IS NOT NULL)
           THEN

              x_error_code_temp := is_currency_code_valid(p_cnv_hdr_rec.currency_code
                                                         -- ,p_cnv_hdr_rec.currency_header_id
                                                         );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_currency_code_valid - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_currency_code_valid not called as currency_code is null ');
           END IF;

            IF (p_cnv_hdr_rec.global_flag='N') THEN

              x_error_code_temp := is_operating_unit_valid(/* p_cnv_hdr_rec.organization_code
                                         ,*/p_cnv_hdr_rec.org_id
                                                           ,p_cnv_hdr_rec.orig_org_name
                                                       );
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_operating_unit_valid - error '||x_error_code_temp);
            x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_operating_unit_valid not called as global_flag is Y ');

           END IF;

          /*x_error_code_temp := is_line_exists(p_cnv_hdr_rec.orig_sys_header_ref
                                             );

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_line_exists - error '||x_error_code_temp);
           x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);*/

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code_temp---'||x_error_code_temp);
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code---'||x_error_code);
         -- commented to stop a propagate error , It is called in main package after data validation
         --xx_emf_pkg.propagate_error ( x_error_code_temp);
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code_temp---'||x_error_code_temp);
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code---'||x_error_code);
         RETURN x_error_code;



   END data_validations;

---oVERLOADED FUNC FOR PRICELIST LINE
FUNCTION data_validations (p_batch_id IN VARCHAR2
                          --,p_header_line IN VARCHAR2
                          )
RETURN NUMBER
IS

x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

 --- Local functions for all batch level validations
 --- Add as many functions as required in here




        ------------------------ Start the BEGIN part of Data Validations ----------------------------------

     BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');


           -- Start of the Line Data validation--
         --IF p_header_line = 'Y'  THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Line level data validation:');--||p_header_line);
    BEGIN
       UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Product Attribute Context',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_prc_contexts_b qpcb
                        WHERE qpcb.prc_context_type = 'PRODUCT'
                          AND qpcb.prc_context_code = oil.product_attribute_context
                      )
       AND oil.product_attribute_context IS NOT NULL;

     IF SQL%ROWCOUNT > 0 THEN
     FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Product Attribute Context'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attribute_context
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;

   UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Product Attribute Column ',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_segments_tl qst
                             ,qp_segments_b qsb
                             ,qp_prc_contexts_b qpc
                        WHERE UPPER(qsb.segment_mapping_column) = UPPER(oil.product_attribute)
                          AND qst.language = 'US'
                          AND qst.segment_id = qsb.segment_id
                          AND qsb.prc_context_id = qpc.prc_context_id
                          AND qpc.PRC_CONTEXT_CODE = oil.product_attribute_context
                          AND qpc.prc_context_type = 'PRODUCT'
                      )
       AND oil.product_attribute IS NOT NULL
       AND oil.product_attribute_context IS NOT NULL;

    IF SQL%ROWCOUNT > 0 THEN
    FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Product Attribute Column'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attribute
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
    END IF;

   /*UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.product_attribute_code = oil.product_attribute
     WHERE oil.batch_id = p_batch_id
       AND oil.product_attribute IS NOT NULL
       AND oil.product_attribute_context IS NOT NULL;*/
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Product Attribute');
    END;

    BEGIN
       UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Item Number',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM mtl_system_items_b msi
                        WHERE msi.organization_id = (SELECT organization_id
                                                       FROM mtl_parameters
                                                      WHERE master_organization_id = organization_id)
                          AND msi.segment1 = oil.product_attr_value
                      )
       --AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE1';
    IF SQL%ROWCOUNT > 0 THEN
    /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                       ,p_error_text  => ' No of records in error for Validate Item Number  =>'||SQL%ROWCOUNT
                       ,p_record_identifier_1 => 'MULTIPLE RECORDS'
                      );  */
      FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Item Number'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                     --,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';

    END IF;
    -----------------------Checking Customer Orderable flag -------------------------------------
    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Item Number does not have Customer Orderable Flag  Checked',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND EXISTS (SELECT 1
                         FROM mtl_system_items_b msi
                        WHERE msi.organization_id = (SELECT organization_id
                                                       FROM mtl_parameters
                                                      WHERE master_organization_id = organization_id)
                          AND msi.segment1 = oil.product_attr_value
                          AND NVL(customer_order_flag,'N') = 'N'
                      )
       --AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE1';
    IF SQL%ROWCOUNT > 0 THEN
      /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                       ,p_error_text  => ' No of records in error for Customer Orderable Flag  =>'||SQL%ROWCOUNT
                       ,p_record_identifier_1 => 'MULTIPLE RECORDS'
                      );  */
      FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Item Number does not have Customer Orderable Flag  Checked'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                     --,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';

    END IF;
    -----------------------Checking Oredrable flag end------------------------------------------

    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.product_attr_value_code = oil.product_attr_value,
           oil.product_attr_value = (SELECT inventory_item_id
                                     FROM mtl_system_items_b msi
                                     WHERE  msi.organization_id = (SELECT organization_id
                                                                   FROM mtl_parameters
                                                                   WHERE master_organization_id = organization_id)
                                    AND msi.segment1 = oil.product_attr_value
                                 )
     WHERE oil.batch_id = p_batch_id
       AND oil.product_attr_value IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE1';


    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid All Items Option',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM fnd_flex_value_sets fvs
                             ,fnd_flex_values     ffv
                             ,fnd_flex_values_tl  ffvt
                        WHERE fvs.flex_value_set_name = 'QP:ITEM_ALL'
                          AND   ffv.flex_value_set_id = fvs.flex_value_set_id
                          AND   ffvt.flex_value_id = ffv.flex_value_id
                          AND   ffvt.language = 'US'
                          AND   ffvt.description = oil.product_attr_value
                      )
       --AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE3';

    IF SQL%ROWCOUNT > 0 THEN
     FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid All Items Option'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
    END IF;

    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.product_attr_value_code = oil.product_attr_value,
           oil.product_attr_value = (SELECT ffvt.description
                         FROM fnd_flex_value_sets fvs
                             ,fnd_flex_values     ffv
                             ,fnd_flex_values_tl  ffvt
                        WHERE fvs.flex_value_set_name = 'QP:ITEM_ALL'
                          AND   ffv.flex_value_set_id = fvs.flex_value_set_id
                          AND   ffvt.flex_value_id = ffv.flex_value_id
                          AND   ffvt.language = 'US'
                          AND   ffvt.description = oil.product_attr_value
                                 )
     WHERE oil.batch_id = p_batch_id
       AND oil.product_attr_value IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE3';

    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Item Category',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_item_categories_v
                        WHERE category_name = oil.product_attr_value
                          AND functional_area_id IN (
                                                     SELECT DISTINCT functional_area_id
                                                       FROM qp_sourcesystem_fnarea_map
                                                      WHERE enabled_flag = 'Y')
                       )
       --AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE2';

      IF SQL%ROWCOUNT > 0 THEN
      /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                       ,p_error_text  => ' No of records in error for Validate Product Attribute - Item Category  =>'||SQL%ROWCOUNT
                       ,p_record_identifier_1 => 'MULTIPLE RECORDS'
                      ); */
       FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Item Category'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                     --,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
      END IF;

    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.product_attr_value_code = oil.product_attr_value,
           oil.product_attr_value = (SELECT category_id
                         FROM qp_item_categories_v
                        WHERE category_name = oil.product_attr_value
                          AND functional_area_id IN (
                                                     SELECT DISTINCT functional_area_id
                                                       FROM qp_sourcesystem_fnarea_map
                                                      WHERE enabled_flag = 'Y')
                                 )
     WHERE oil.batch_id = p_batch_id
       AND oil.product_attr_value IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE2';

     ----------------------Item DCODE mods starts----------------------------------------
         UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Item DCODE',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS  (SELECT 1
                         FROM   fnd_flex_values_vl fvl
                               ,fnd_flex_value_sets fvs
                        WHERE fvl.flex_value_set_id = fvs.flex_value_set_id
                          AND   fvs.flex_value_set_name = 'INTG_PRODUCT_TYPE'
                          AND flex_value            = oil.product_attr_value
                       )
       --AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE25';

      IF SQL%ROWCOUNT > 0 THEN
       FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Item DCODE'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                     --,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
      END IF;

    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.product_attr_value_code = oil.product_attr_value --no need to update product_attr_value since it is the same value
     WHERE oil.batch_id = p_batch_id
       AND oil.product_attr_value IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE25';

     ----------------------Item DCODE mods ends------------------------------------------

    /*UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.product_attr_value = oil.inventory_item
     WHERE oil.batch_id = p_batch_id;
       --AND oil.inventory_item IS NOT NULL;*/

     /*UPDATE xx_qp_pr_list_lines_pre
               SET    product_attribute_code = (SELECT seg.user_segment_name
                                                FROM   qp_prc_contexts_v cntx, qp_segments_v seg
                                                WHERE cntx.prc_context_id = seg.prc_context_id
                                                AND seg.segment_mapping_column = product_attribute
                                                AND cntx.prc_context_code = product_attribute_context)
               WHERE batch_id = p_batch_id;*/
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Product Attribute Value');
    END;

    BEGIN
       UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Pricing Attribute Context',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                       FROM qp_prc_contexts_b qpcb
                       WHERE qpcb.prc_context_type = 'PRICING_ATTRIBUTE'
                       AND qpcb.prc_context_code = oil.pricing_attribute_context
                      )
       AND oil.pricing_attribute_context IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
    FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Attribute Context'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute_context
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;

    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Pricing Attribute Column',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_segments_tl qst
                             ,qp_segments_b qsb
                             ,qp_prc_contexts_b qpc
                        WHERE qsb.segment_mapping_column = oil.pricing_attribute
                          AND qst.language = 'US'
                          AND qst.segment_id = qsb.segment_id
                          AND qsb.prc_context_id = qpc.prc_context_id
                          AND qpc.prc_context_code = oil.pricing_attribute_context
                        )
       AND oil.pricing_attribute_context IS NOT NULL
       AND oil.pricing_attribute IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
     FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Attribute Column'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute_context
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;

    UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Pricing Attribute is NULL',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND oil.pricing_attribute_context IS NOT NULL
       AND oil.pricing_attribute IS NULL;

   IF SQL%ROWCOUNT > 0 THEN
   FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Pricing Attribute is NULL'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
   END IF;

   UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Pricing Attribute Context is NULL',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND oil.pricing_attribute_context IS NULL
       AND (oil.pricing_attribute IS NOT NULL OR oil.pricing_attribute_name IS NOT NULL);

    IF SQL%ROWCOUNT > 0 THEN
    FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Pricing Attribute Context is NULL'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute_context
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Pricing Attribute');
    END;




  BEGIN
     UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid List Line Type code',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                       FROM qp_lookups qll
                       WHERE lookup_type = 'LIST_LINE_TYPE_CODE'
                         AND   lookup_code = oil.list_line_type_code
                         AND enabled_flag = 'Y'
                      );
     IF SQL%ROWCOUNT > 0 THEN
      FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid List Line Type code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.list_line_type_code
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;

    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Pricelist Type');
    END;


    BEGIN
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Arithmetic Operator',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_lookups
                        WHERE lookup_type = 'ARITHMETIC_OPERATOR'
                          AND   lookup_code = oil.arithmetic_operator
                          AND   enabled_flag = 'Y'
                       )
       AND oil.arithmetic_operator IS NOT NULL;

       IF SQL%ROWCOUNT > 0 THEN
       FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Arithmetic Operator'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.arithmetic_operator
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
       END IF;

    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Arithmetic Operator');
    END;

     BEGIN
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid/NULL Unit Of Measure',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND (oil.product_uom_code IS NULL OR
            NOT EXISTS (SELECT 1
                         FROM mtl_units_of_measure
                        WHERE uom_code = oil.product_uom_code
                       ))
       AND oil.product_uom_code IS NOT NULL;

      IF SQL%ROWCOUNT > 0 THEN
      FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid/NULL Unit Of Measure'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_uom_code
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
      END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate UOM');
    END;

    BEGIN
       UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Price Break Type Code',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_lookups
                        WHERE lookup_type = 'PRICE_BREAK_TYPE_CODE'
                          AND   lookup_code = oil.price_break_type_code
                       )
       AND oil.price_break_type_code IS NOT NULL;

       IF SQL%ROWCOUNT > 0 THEN
       FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Price Break Type Code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.price_break_type_code
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
       END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Price Break Type');
    END;

   BEGIN
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Comparison Operator Code',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_lookups
                        WHERE lookup_type = 'COMPARISON_OPERATOR'
                          AND lookup_code = oil.comparison_operator_code
                       )
       AND oil.comparison_operator_code IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
     FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Comparison Operator Code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.comparison_operator_code
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Comparison Operator');
    END;

    BEGIN

        BEGIN
           FOR hdr_rec in (SELECT * from xx_qp_pr_list_hdr_pre
                           WHERE batch_id = p_batch_id
                             AND start_date_active IS NOT NULL) LOOP
              UPDATE xx_qp_pr_list_lines_pre prl
                 SET prl.start_date_active = hdr_rec.start_date_active
               WHERE prl.batch_id = hdr_rec.batch_id
                 AND prl.orig_sys_header_ref = hdr_rec.orig_sys_header_ref
                 AND prl.start_date_active IS NOT NULL
                 AND prl.start_date_active < hdr_rec.start_date_active;

           END LOOP;
        EXCEPTION
           WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in updating Start Date Range');

        END;
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid Start Date Range of Line',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND EXISTS (SELECT 1
                     FROM xx_qp_pr_list_hdr_pre qpl
                    WHERE qpl.orig_sys_header_ref = oil.orig_sys_header_ref
                      AND qpl.start_date_active > oil.start_date_active
                      AND qpl.start_date_active IS NOT NULL
                      AND  oil.batch_id = qpl.batch_id
                       )
       AND oil.start_date_active IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
    FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Start Date Range of Line'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.start_date_active
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Start Date Range');
    END;

    BEGIN
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Invalid End Date Range of Line',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND EXISTS (SELECT 1
                     FROM xx_qp_pr_list_hdr_pre qpl
                    WHERE qpl.orig_sys_header_ref = oil.orig_sys_header_ref
                      AND qpl.end_date_active < oil.end_date_active
                      AND qpl.end_date_active IS NOT NULL
                      AND  oil.batch_id = qpl.batch_id
                       )
       AND oil.end_date_active IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
   FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid End Date Range of Line'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.end_date_active
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate End Date Range');
    END;
    ---Update starting range from 1 to 0 since in R12 price break should start from 0
    /*BEGIN
       UPDATE xx_qp_pr_list_lines_pre xpl
          SET   pricing_attr_value_from = 0
        WHERE pricing_attr_value_from = 1
          AND  NOT EXISTS (SELECT 1
                             FROM xx_qp_pr_list_lines_pre xpl1
                            WHERE xpl1.batch_id = xpl.batch_id
                              AND  xpl1.orig_sys_header_ref = xpl.orig_sys_header_ref
                              AND  xpl1.from_orig_sys_hdr_ref = xpl.from_orig_sys_hdr_ref
                              AND  xpl1.pricing_attr_value_from < xpl.pricing_attr_value_from
                            )
         AND xpl.from_orig_sys_hdr_ref IS NOT NULL
         AND xpl.batch_id = p_batch_id;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Updating Pricing Break starting value');
    END; */

    BEGIN
       UPDATE xx_qp_pr_list_lines_pre xpl
          SET   xpl.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
                xpl.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
                xpl.error_desc = xpl.error_desc || '~Pricelist Line - Price Break should start with zero',
                error_flag_temp = 'Y'
        WHERE pricing_attr_value_from = 1
          AND  NOT EXISTS (SELECT 1
                             FROM xx_qp_pr_list_lines_pre xpl1
                            WHERE xpl1.batch_id = xpl.batch_id
                              AND  xpl1.orig_sys_header_ref = xpl.orig_sys_header_ref
                              AND  xpl1.from_orig_sys_hdr_ref = xpl.from_orig_sys_hdr_ref
                              AND  xpl1.pricing_attr_value_from < xpl.pricing_attr_value_from
                            )
         AND xpl.from_orig_sys_hdr_ref IS NOT NULL
         AND xpl.batch_id = p_batch_id;

       IF SQL%ROWCOUNT > 0 THEN
       FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Price Break should start with zero'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attr_value_from
              );
        END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Pricing Break starting value');
    END;

    BEGIN
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Start Date for line is greater than end date of Header',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND EXISTS (SELECT 1
                     FROM xx_qp_pr_list_hdr_pre qpl
                    WHERE qpl.orig_sys_header_ref = oil.orig_sys_header_ref
                      AND qpl.end_date_active < oil.start_date_active
                      AND qpl.end_date_active IS NOT NULL
                      AND  oil.batch_id = qpl.batch_id
                       );

     IF SQL%ROWCOUNT > 0 THEN
   FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Start Date for line is greater than end date of Header'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.end_date_active
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Start Date for line is greater');
    END;
    --Price Break additional information
    BEGIN
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Pricelist Line - Insufficient Price Break Information',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND price_break_type_code IS NOT NULL
       AND from_orig_sys_hdr_ref IS NOT NULL
       AND NOT EXISTS (SELECT 1
                       FROM xx_qp_pr_list_lines_pre oil1
                       WHERE oil1.batch_id = oil.batch_id
                       AND   oil1.orig_sys_header_ref = oil.orig_sys_header_ref
                       AND   oil1.orig_sys_line_ref = oil.from_orig_sys_hdr_ref
                       AND   oil1.list_line_type_code = 'PBH')
       ;
     IF SQL%ROWCOUNT > 0 THEN
   FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Insufficient Price Break Information'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.from_orig_sys_hdr_ref
              );
       END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Price Break Information');
    END;

    BEGIN
        UPDATE xx_qp_pr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Incompatibility Group Code',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                       FROM   fnd_lookup_values
                       WHERE  lookup_type = 'INCOMPATIBILITY_GROUPS'
                       and lookup_code = oil.incompatibility_grp_code
                       and language = userenv('LANG')
                       )
       AND oil.incompatibility_grp_code IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
         FOR rec_err IN (SELECT * FROM xx_qp_pr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Incompatibility Group Code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.incompatibility_grp_code
              );
           END LOOP;
        UPDATE xx_qp_pr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Incompatibility Group Code');
    END;



                  -- End of Line Data validations --
       --END IF; -- If p_header_line  = 'Y'

         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code_temp---'||x_error_code_temp);
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code---'||x_error_code);
         -- commented to stop a propagate error , It is called in main package after data validation
         --xx_emf_pkg.propagate_error ( x_error_code_temp);
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code_temp---'||x_error_code_temp);
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code---'||x_error_code);
         RETURN x_error_code;



   END data_validations;

   /************************ Batch Level Validation for Qualifiers *****************************/
   /************************ Overloaded Function *****************************/

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY xx_qp_pr_list_qlf_pre%ROWTYPE
   ) RETURN NUMBER IS

    x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    --- Local functions for all batch level validations
            --- Add as many functions as required in here
           ----------------------------------------------------------------------------

   /*--------------------------------------------------------------------------
   -- Function to validate the Qualifier Context
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

    FUNCTION is_qlf_context_valid( /*p_qlf_context_desc  IN      qp_prc_contexts_tl.user_prc_context_name%TYPE
                                  ,*/p_qlf_context       IN OUT  qp_prc_contexts_b.prc_context_code%TYPE)
    RETURN NUMBER IS
      x_count           NUMBER          := 0;
      x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
      /*IF p_qlf_context_desc IS NOT NULL THEN
          SELECT qpcb.prc_context_code INTO p_qlf_context
          FROM qp_prc_contexts_tl qpc
              ,qp_prc_contexts_b qpcb
          WHERE qpc.user_prc_context_name = p_qlf_context_desc
            AND qpc.language = 'US'
            AND qpcb.prc_context_id = qpc.prc_context_id
            AND qpcb.prc_context_type = 'QUALIFIER';
      ELSE*/
          SELECT 1 INTO x_count
          FROM qp_prc_contexts_b qpcb
          WHERE qpcb.prc_context_code = p_qlf_context
            AND qpcb.prc_context_type = 'QUALIFIER';
      --END IF;

      RETURN x_error_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Invalid Qualifier Context =>'||xx_emf_cn_pkg.CN_NO_DATA
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                     ,p_record_identifier_5 => p_cnv_hdr_rec.qualifier_attr_value_disp
                    );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Invalid Qualifier Context =>'||xx_emf_cn_pkg.CN_NO_DATA
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                     ,p_record_identifier_5 => p_cnv_hdr_rec.qualifier_attr_value_disp);
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Context Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
                     (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Errors In Qualifier Context Validation =>'||SQLERRM
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                     ,p_record_identifier_5 => p_cnv_hdr_rec.qualifier_attr_value_disp);
        RETURN x_error_code;
    END is_qlf_context_valid;

   /*--------------------------------------------------------------------------
   -- Function to validate the Qualifier Attribute
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

    FUNCTION is_qlf_attr_valid( p_qlf_attr_desc     IN       qp_prc_contexts_tl.user_prc_context_name%TYPE
                               ,p_qlf_context       IN       qp_prc_contexts_b.prc_context_code%TYPE
                               ,p_qlf_attr          IN OUT   qp_segments_b.segment_mapping_column%TYPE)
    RETURN NUMBER IS
      x_count           NUMBER          := 0;
      x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN

        SELECT qsb.segment_mapping_column INTO p_qlf_attr
        FROM qp_segments_tl qst
            ,qp_segments_b qsb
            ,qp_prc_contexts_b qpc
        WHERE --UPPER(qst.user_segment_name) = UPPER(p_qlf_attr_desc)
              qsb.segment_mapping_column = p_qlf_attr_desc
          AND qst.language = 'US'
          AND qst.segment_id = qsb.segment_id
          AND qsb.prc_context_id = qpc.prc_context_id
          AND qpc.prc_context_code = p_qlf_context;

         RETURN x_error_code;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                         ,p_error_text  => 'Invalid Qualifier Attribute =>'||xx_emf_cn_pkg.CN_NO_DATA
                         ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                         ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                         ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                         --,p_record_identifier_4 => NULL
                         ,p_record_identifier_5 => p_cnv_hdr_rec.qualifier_attr_value_disp);
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Qualifier Attribute =>'||xx_emf_cn_pkg.CN_NO_DATA
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
              ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
              ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
              --,p_record_identifier_4 => NULL
              ,p_record_identifier_5 => p_cnv_hdr_rec.qualifier_attr_value_disp);
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
                     (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Errors In Qualifier Attribute Validation =>'||SQLERRM
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                     ,p_record_identifier_5 => p_cnv_hdr_rec.qualifier_attr_value_disp);
        RETURN x_error_code;
    END is_qlf_attr_valid;

   /*--------------------------------------------------------------------------
   -- Function to validate the Qualifier Attribute Value
   -- Assumption - Attribute is of Type Customer Name Only
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

    FUNCTION is_attr_value_valid  ( p_qlf_context       IN       qp_prc_contexts_b.prc_context_code%TYPE
                                 ,p_qlf_attr          IN       qp_segments_b.segment_mapping_column%TYPE
                                 ,p_qlf_attr_val_disp IN       VARCHAR2
                                 ,p_qlf_attr_val      OUT      VARCHAR2)
    RETURN NUMBER IS
      x_count           NUMBER          := 0;
      x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN

       IF p_qlf_context = 'CUSTOMER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE2'  THEN --Customer Name
          BEGIN
             -- Validation Logic from Deb
             SELECT cust_account_id
             INTO p_qlf_attr_val
             FROM hz_cust_accounts_all
             WHERE orig_system_reference=p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;
             WHEN OTHERS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                                 (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Errors In Qualifier Attribute Value Validation =>'||SQLERRM
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'CUSTOMER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE1'  THEN --Customer Class
          BEGIN
             -- Validation Logic from Deb
             SELECT lookup_code
             INTO p_qlf_attr_val
             FROM ar_lookups
             WHERE lookup_code = p_qlf_attr_val_disp
             AND   lookup_type = 'CUSTOMER CLASS';

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;
             WHEN OTHERS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                                 (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Errors In Qualifier Attribute Value Validation =>'||SQLERRM
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'MODLIST' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE4'  THEN -- Price List
          BEGIN
             -- Validation Logic from Deb
             /*SELECT list_header_id
             INTO p_qlf_attr_val
             FROM qp_secu_list_headers_vl
             WHERE list_type_code IN ('PRL','AGR')
             AND   view_flag = 'Y'
             AND   name = p_qlf_attr_val_disp;  */
             BEGIN
                /*SELECT name
                INTO p_qlf_attr_val
                FROM qp_list_headers
                WHERE list_type_code IN ('PRL','AGR')
                  --AND   view_flag = 'Y'
                  AND   orig_system_header_ref = p_qlf_attr_val_disp;*/
                SELECT name
                   INTO p_qlf_attr_val
                   FROM xx_qp_pr_list_hdr_stg
                   WHERE orig_sys_header_ref = p_qlf_attr_val_disp
                    --AND  batch_id = g_batch_id
                    AND  request_id = xx_emf_pkg.g_request_id;
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Searching for secondary pricelist in current header file');
                   BEGIN
                   /*SELECT name
                   INTO p_qlf_attr_val
                   FROM xx_qp_pr_list_hdr_stg
                   WHERE orig_sys_header_ref = p_qlf_attr_val_disp
                    --AND  batch_id = g_batch_id
                    AND  request_id = xx_emf_pkg.g_request_id;*/
                    SELECT name
                    INTO p_qlf_attr_val
                    FROM qp_list_headers
                    WHERE list_type_code IN ('PRL','AGR')
                    --AND   view_flag = 'Y'
                      AND   orig_system_header_ref = p_qlf_attr_val_disp
                      AND rownum < 2;

                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                       x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                        RETURN x_error_code;
                        WHEN TOO_MANY_ROWS THEN
                           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                            RETURN x_error_code;
                   END;
                WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;

             END ;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;
             WHEN OTHERS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                                 (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Errors In Qualifier Attribute Value Validation =>'||SQLERRM
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'ORDER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE9'  THEN -- Order Type
          BEGIN
             -- Validation Logic from Deb
             SELECT ota.transaction_type_id
             INTO p_qlf_attr_val
             FROM OE_TRANSACTION_TYPES_ALL ota,
                  OE_TRANSACTION_TYPES_TL ott
             WHERE ota.transaction_type_id = ott.transaction_type_id
             AND   ott.language = userenv('LANG')
             AND   ota.transaction_type_code='ORDER'
             AND   ott.name = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;
             WHEN OTHERS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                                 (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Errors In Qualifier Attribute Value Validation =>'||SQLERRM
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'ORDER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE20'  THEN -- Freight Cost Type
          BEGIN
             -- Validation Logic from Deb
             SELECT LOOKUP_CODE
             INTO p_qlf_attr_val
             FROM WSH_LOOKUPS
             WHERE ENABLED_FLAG = 'Y'
             AND LOOKUP_TYPE = 'FREIGHT_COST_TYPE'
             AND LOOKUP_CODE = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;
             WHEN OTHERS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                                 (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Errors In Qualifier Attribute Value Validation =>'||SQLERRM
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'TERMS' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE10'  THEN -- Freight Terms
          BEGIN
             -- Validation Logic from Deb
             SELECT FREIGHT_TERMS_CODE
             INTO p_qlf_attr_val
             FROM OE_FRGHT_TERMS_ACTIVE_V
             WHERE FREIGHT_TERMS = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;
             WHEN OTHERS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                                 (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Errors In Qualifier Attribute Value Validation =>'||SQLERRM
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'TERMS' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE11'  THEN -- Shipping Terms
          BEGIN
             -- Validation Logic from Deb
             SELECT LOOKUP_CODE
             INTO p_qlf_attr_val
             FROM OE_SHIP_METHODS_V
             WHERE LOOKUP_CODE = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                                  --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                                  );
                RETURN x_error_code;
             WHEN OTHERS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Attribute Validation ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                                 (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Errors In Qualifier Attribute Value Validation =>'||SQLERRM
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                               --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.qualifier_attr_value_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'INTG' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE31' -- Custom Attribute contract Terms
         OR p_qlf_context = 'INTG' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE32'  -- Custom Attribute Order Price list
         OR p_qlf_context = 'INTG_SHIP_FROM_ORG' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE31'  -- Custom Attribute SHIP FROM
         OR p_qlf_context = 'RAD INT QUAL' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE31'  -- Country Code
         OR p_qlf_context = 'VOLUME' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE10'  -- Volume (Seeded Attribute)
         THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Deb Generic If stmt');
            p_qlf_attr_val := p_qlf_attr_val_disp;
       ELSE
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                           ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                           ,p_error_text  => 'Unidentified Qualifier Attribute Value. New value needs to be mapped'
                                             ||' in the custom code'
                           ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                           ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                           ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                         --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                           ,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr
                           );
       END IF;



        RETURN x_error_code;
    END is_attr_value_valid;


   /*--------------------------------------------------------------------------
   -- Function to validate the Comparison Operator
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

    FUNCTION is_comp_op_valid( p_comp_op_code       IN      qp_lookups.lookup_code%TYPE)
    RETURN NUMBER IS
      x_count           NUMBER          := 0;
      x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
        SELECT 1 INTO x_count
        FROM qp_lookups
        WHERE lookup_type = 'COMPARISON_OPERATOR'
          AND lookup_code = p_comp_op_code
          AND enabled_flag = 'Y';

        RETURN x_error_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                         ,p_error_text  => 'Invalid Comparison Operator =>'||xx_emf_cn_pkg.CN_NO_DATA
                         ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                         ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                         ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                         --,p_record_identifier_4 => NULL
                         ,p_record_identifier_5 => p_comp_op_code);
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                         ,p_error_text  => 'Invalid Comparison Operator =>'||xx_emf_cn_pkg.CN_NO_DATA                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                         ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                         ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                         --,p_record_identifier_4 => NULL
                         ,p_record_identifier_5 => p_comp_op_code);
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Comparision Operator Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
                     (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Errors In Comparison Operator Validation =>'||SQLERRM              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                     ,p_record_identifier_5 => p_comp_op_code);
        RETURN x_error_code;
    END is_comp_op_valid;

       /*--------------------------------------------------------------------------
   -- Function to validate the Comparison Operator
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

    /*FUNCTION is_sec_pricelist_valid( p_sec_pricelist IN       VARCHAR2
                                    ,p_pri_pricelist_id       OUT      NUMBER
                                    )
    RETURN NUMBER IS
      x_list_header_id                  NUMBER          := NULL;
      x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
        SELECT list_header_id INTO x_list_header_id
        FROM qp_list_headers
        WHERE orig_system_header_ref = p_sec_pricelist
          AND list_type_code = 'PRL';

        p_pri_pricelist_id  := x_list_header_id;

        RETURN x_error_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Invalid Secondary Price List =>'||xx_emf_cn_pkg.CN_NO_DATA
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                     ,p_record_identifier_5 => p_cnv_hdr_rec.orig_sys_qualifier_ref);
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                         ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                         ,p_error_text  => 'Invalid Secondary Price List =>'||xx_emf_cn_pkg.CN_NO_DATA
                         ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                         ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                         ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                         --,p_record_identifier_4 => NULL
                         ,p_record_identifier_5 => p_cnv_hdr_rec.orig_sys_qualifier_ref);
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Comparision Operator Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
                     (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                     ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                     ,p_error_text  => 'Errors In Comparison Operator Validation =>'||SQLERRM
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                     ,p_record_identifier_5 => p_cnv_hdr_rec.orig_sys_qualifier_ref);
        RETURN x_error_code;
    END is_sec_pricelist_valid;    */


   BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations For Qualifiers');


    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    --IF p_cnv_hdr_rec.sec_prc_list_orig_sys_hdr_ref IS NULL THEN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Qualifier Context');
    x_error_code_temp := is_qlf_context_valid(/*p_cnv_hdr_rec.qualifier_context_desc
                                             ,*/p_cnv_hdr_rec.qualifier_context);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Qualifier Attribute');
    x_error_code_temp := is_qlf_attr_valid(p_cnv_hdr_rec.qualifier_attribute
                                          ,p_cnv_hdr_rec.qualifier_context
                                          ,p_cnv_hdr_rec.qualifier_attribute);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Qualifier Attribute Value');
    x_error_code_temp := is_attr_value_valid(p_cnv_hdr_rec.qualifier_context
                                            ,p_cnv_hdr_rec.qualifier_attribute
                                            ,p_cnv_hdr_rec.qualifier_attr_value_disp
                                            ,p_cnv_hdr_rec.qualifier_attr_value);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Comparison Operator');
    x_error_code_temp := is_comp_op_valid (p_cnv_hdr_rec.comparison_operator_code);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    --END IF;

    /*xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Secondary Price List');
    x_error_code_temp :=  is_sec_pricelist_valid(p_cnv_hdr_rec.sec_prc_list_orig_sys_hdr_ref
                                          ,p_cnv_hdr_rec.sec_prc_list_orig_list_id);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);*/

    -- Put Qualifier Attribute Value Validation if Context and Attribute is within a known set.

    RETURN x_error_code;
   END data_validations;

--------------------End Data Validations for Price Lists---------------------------------------


    FUNCTION post_validations(p_batch_id IN VARCHAR2) ---DROY ADD FOR LINES/QUALIFIERS?
                  RETURN NUMBER
      IS
             x_error_code       NUMBER := xx_emf_cn_pkg.cn_success;
             x_error_code_temp  NUMBER := xx_emf_cn_pkg.cn_success;
             x_lines_threshold  NUMBER;
             x_lines_thresh_rem NUMBER ;
             x_batch_no         NUMBER;
             x_subbatch_no      NUMBER;

      CURSOR c_print_err_hdr_rec
       IS
          SELECT pre.record_number,
                 pre.name,
                 pre.orig_sys_header_ref/*,
                 pre.orig_sys_line_ref*/
                   FROM XX_QP_PR_LIST_HDR_PRE pre
                   WHERE pre.process_code    = xx_emf_cn_pkg.cn_postval
                     AND pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
                     AND pre.batch_id          = p_batch_id
                     AND pre.request_id        = xx_emf_pkg.g_request_id
                     ;

       CURSOR c_print_err_lines_rec
    IS
	  SELECT pre.record_number, --ADD FOR HEADER
		 --pre.name,
		 pre.orig_sys_header_ref,
                 pre.orig_sys_line_ref,
                 pre.orig_sys_pricing_attr_ref
		   FROM xx_qp_pr_list_lines_pre pre
		   WHERE pre.process_code    = xx_emf_cn_pkg.cn_postval
		     AND pre.error_code        = xx_emf_cn_pkg.cn_rec_err
		     AND pre.batch_id          = p_batch_id
		     AND pre.request_id        = xx_emf_pkg.g_request_id
	     ;

     CURSOR c_print_err_qual_rec
         IS
     	  SELECT pre.record_number,
     		 --pre.modifier_name,
     		 pre.qualifier_context,
     		 pre.qualifier_attribute,
                 pre.orig_sys_header_ref,
                 pre.orig_sys_line_ref,
                 pre.orig_sys_qualifier_ref
     		   FROM xx_qp_pr_list_qlf_pre pre
     		   WHERE pre.process_code    = xx_emf_cn_pkg.cn_postval
     		     AND pre.error_code        = xx_emf_cn_pkg.cn_rec_err
     		     AND pre.batch_id          = p_batch_id
     		     AND pre.request_id        = xx_emf_pkg.g_request_id
	     ;
     CURSOR c_hdr_batch
         IS
          SELECT *
          FROM  xx_qp_pr_list_hdr_pre pre
          WHERE /*process_code      = xx_emf_cn_pkg.cn_postval
            AND*/ ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
            AND batch_id          = p_batch_id
            AND request_id        = xx_emf_pkg.g_request_id
            AND custom_batch_no IS NULL
          ORDER BY custom_lines_count;

    CURSOR c_sec_prclist
IS
SELECT DISTINCT qpr.orig_sys_header_ref,qpr.qualifier_attr_value_disp secondary, level
FROM   xx_qp_pr_list_qlf_pre qpr
WHERE /*qpr.process_code      = xx_emf_cn_pkg.cn_postval
 AND*/  qpr.ERROR_CODE IN     ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
 AND  qpr.batch_id          = p_batch_id
 AND  qpr.request_id        = xx_emf_pkg.g_request_id
 AND  qpr.qualifier_context = 'MODLIST'
 AND  qpr.qualifier_attribute = 'QUALIFIER_ATTRIBUTE4'
CONNECT BY PRIOR qualifier_attr_value_disp = orig_sys_header_ref
ORDER by level desc;



      BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Post-Validations');

         UPDATE xx_qp_pr_list_hdr_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_HEADER_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_pr_list_lines_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Deb Update hdr due to lines error'||SQL%ROWCOUNT);

         UPDATE xx_qp_pr_list_hdr_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_HEADER_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_pr_list_qlf_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;

          xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Deb Update hdr due to qlf error'||SQL%ROWCOUNT);

         UPDATE xx_qp_pr_list_lines_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_header_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_pr_list_hdr_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Deb Update lines due to hdr error'||SQL%ROWCOUNT);

        UPDATE xx_qp_pr_list_qlf_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_header_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_pr_list_hdr_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;
         xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Deb Update qlf due to hdr error'||SQL%ROWCOUNT);
         --Uncomment above when we have good files

        COMMIT;

        /*FOR cur_rec IN c_print_err_hdr_rec
        LOOP
             xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.cn_postval
                   ,p_error_text  => 'List Header Group Erroed out due error exists in Line'
                   ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                    -- ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => NULL
                   --  ,p_record_identifier_5 => cur_rec.orig_sys_qualifier_ref
                         );


        END LOOP;

        FOR cur_rec IN c_print_err_lines_rec
        LOOP
             xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.cn_postval
                   ,p_error_text  => 'List Line Group Erroed out due error exists in Header'
                  ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => cur_rec.orig_sys_pricing_attr_ref
                     --,p_record_identifier_5 => cur_rec.orig_sys_qualifier_ref
                         );


        END LOOP;

        FOR cur_rec IN c_print_err_qual_rec
        LOOP
             xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.cn_postval
                   ,p_error_text  => 'List Qualifier Group Erroed out due error exists in Header'
                  ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => cur_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5 => cur_rec.orig_sys_qualifier_ref
                         );


        END LOOP;*/
        --DROY ADD FOR QUALIFIERS BOTH UPDATE AND CURSOR

        --Begin batching process------------------------
        BEGIN
            x_batch_no         := 1;
            x_subbatch_no      := 1;
            x_lines_threshold := xx_emf_pkg.get_paramater_value ('XXQPPRCLISTCNV', 'BATCH_SIZE');
            UPDATE xx_qp_pr_list_hdr_pre xph
            SET    custom_lines_count = (SELECT COUNT(record_number)
                                         FROM   xx_qp_pr_list_lines_pre xpl
                                         WHERE  xph.orig_sys_header_ref = xpl.orig_sys_header_ref
                                           AND  ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
                                           AND  xph.batch_id = xpl.batch_id
                                          AND  xph.request_id = xpl.request_id
                                        )
              WHERE  batch_id          = p_batch_id
             AND   request_id        = xx_emf_pkg.g_request_id;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After custom lines count update for records :'||SQL%ROWCOUNT);
            -----------------------------------------------------------------------------------------------------------
            /*FOR cur_sec_prclist IN c_sec_prclist LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Updating table for secondary pricelist');
            UPDATE xx_qp_pr_list_hdr_pre
             SET custom_batch_no  = x_batch_no
              ,custom_subbatch_no  = x_subbatch_no
             WHERE  orig_sys_header_ref    = cur_sec_prclist.secondary
             AND  batch_id          = p_batch_id
           AND  request_id        = xx_emf_pkg.g_request_id
           AND  ERROR_CODE IN     ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
           AND  custom_batch_no IS NULL;


          IF SQL%ROWCOUNT >0 THEN
             x_subbatch_no := X_subbatch_no + 1;
          END IF;

         END LOOP;

         FOR cur_sec_prclist IN c_sec_prclist LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Updating table for remaining primary pricelist');
            UPDATE xx_qp_pr_list_hdr_pre
             SET custom_batch_no  = x_batch_no
              ,custom_subbatch_no  = x_subbatch_no
             WHERE  orig_sys_header_ref    = cur_sec_prclist.orig_sys_header_ref
             AND  batch_id          = p_batch_id
           AND  request_id        = xx_emf_pkg.g_request_id
           AND  ERROR_CODE IN     ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
           AND  custom_batch_no IS NULL;


          IF SQL%ROWCOUNT >0 THEN
             x_subbatch_no := X_subbatch_no + 1;
          END IF;

         END LOOP;*/



            x_lines_thresh_rem := x_lines_threshold;

            /*IF x_subbatch_no >1 THEN
               x_batch_no := X_batch_no + 1;
            END IF;*/
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'x_batch_no :'||x_batch_no);
            FOR cur_rec in c_hdr_batch LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'x_lines_thresh_rem :'||x_lines_thresh_rem);
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'cur_rec.custom_lines_count :'||cur_rec.custom_lines_count);
               IF x_lines_thresh_rem < cur_rec.custom_lines_count THEN
                  x_batch_no := X_batch_no + 1;
                  x_lines_thresh_rem := x_lines_threshold;
               END IF;


               UPDATE xx_qp_pr_list_hdr_pre
               SET    custom_batch_no  = x_batch_no
               WHERE  record_number    = cur_rec.record_number
                AND   batch_id          = p_batch_id
                AND   request_id        = xx_emf_pkg.g_request_id;

               x_lines_thresh_rem := x_lines_thresh_rem - cur_rec.custom_lines_count;

           END LOOP;
           xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'x_error_code :'||x_error_code);
           COMMIT;


        /*EXCEPTION
           WHEN OTHERS THEN
              WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              RETURN x_error_code;*/
        END;
        --End   batching process------------------------
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


     FUNCTION data_derivations
       (
          p_cnv_pre_std_hdr_rec IN OUT xx_qp_pr_list_hdr_pre%ROWTYPE
   ) RETURN NUMBER
    IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
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


   FUNCTION data_derivations
   (
          p_cnv_pre_std_hdr_rec IN OUT xx_qp_pr_list_lines_pre%ROWTYPE
   ) RETURN NUMBER
    IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN

            --xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivation');
            --ADD THIS CALL IN PKG
            --ADD QUALIFIER VALIDATION/DERIVATION

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

    /************************ Overloaded Function *****************************/
    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT xx_qp_pr_list_qlf_pre%ROWTYPE
    ) RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data - Derivations For Qualifiers');
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




END xx_qp_prc_list_cnv_val_pkg;
/
