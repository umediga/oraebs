DROP PACKAGE BODY APPS.XX_QP_MOD_LIST_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_MOD_LIST_CNV_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By    : Debjani Roy
 Creation Date : 06-Jun-2013
 File Name     : XXPRCMDFIERVL.pkb
 Description   : This script creates the package body of xx_price_modifier_valid_pkg

 Change History:

 Version Date        Name                  Remarks
-------- ----------- ------------          ---------------------------------------
 1.0     06-Jun-2013 Debjani Roy   Initial development.
*/
----------------------------------------------------------------------

    FUNCTION find_max (
        p_error_code1 IN VARCHAR2,
        p_error_code2 IN VARCHAR2) RETURN VARCHAR2
    IS
        x_return_value VARCHAR2(100);
    BEGIN
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


   FUNCTION pre_validations
   (
      p_batch_id    IN VARCHAR2
   ) RETURN NUMBER IS

    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    CURSOR c_print_error_mdf_rec IS
    SELECT record_number
         ,name
         ,list_type_code
         ,orig_sys_header_ref
         ,description
         ,error_desc
     FROM xx_qp_mdpr_list_hdr_stg
    WHERE 1=1
      AND batch_id   = p_batch_id
      AND error_code = xx_emf_cn_pkg.cn_rec_err
      ;

    CURSOR c_print_error_lines_mdf_rec IS
    SELECT record_number
         ,orig_sys_header_ref
         ,orig_sys_line_ref
         ,list_line_type_code
         ,pricing_phase_name
         ,error_desc
         ,orig_sys_pricing_attr_ref
     FROM xx_qp_mdpr_list_lines_stg
    WHERE 1=1
      AND batch_id   = p_batch_id
      AND error_code = xx_emf_cn_pkg.cn_rec_err
      ;

    CURSOR c_print_error_qlf_rec IS
    SELECT record_number
         ,orig_sys_header_ref
         ,orig_sys_line_ref
         ,qualifier_context
         ,error_desc
         ,orig_sys_qualifier_ref
     FROM xx_qp_mdpr_list_qlf_stg
    WHERE 1=1
      AND batch_id   = p_batch_id
      AND error_code = xx_emf_cn_pkg.cn_rec_err
      ;
    -- Start of the main function perform_batch_validations
    -- This will only have calls to the individual functions.

   BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Pre-Validations');


    /****** Modifier Header Level Validation *****/
    --
    -- validation of List Type
    --
    UPDATE xx_qp_mdpr_list_hdr_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Hdr - List Type Is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (list_type_code IS NULL)-- AND list_type IS NULL);
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Number
    --
    UPDATE xx_qp_mdpr_list_hdr_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Hdr - Number is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND name IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Name
    --
    UPDATE xx_qp_mdpr_list_hdr_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Hdr - Name is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND description IS NULL
       AND DESELECT_FLAG IS NULL;

--
    -- validation of Orig Sys
    --
    UPDATE xx_qp_mdpr_list_hdr_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Hdr - Orig Sys Header Ref is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND orig_sys_header_ref IS NULL
       AND DESELECT_FLAG IS NULL;

--
    -- validation of Active Flag
    --
    UPDATE xx_qp_mdpr_list_hdr_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Hdr - Active Flag is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND active_flag IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Pricing Transaction Entity
    --
    -- To Be Picked From Profile if NULL
--    UPDATE xx_qp_mdpr_list_lines_stg oih
--       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
--           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
--           oih.error_desc = oih.error_desc || '~Modifier - Pricing Extension Entity is NULL'
--     WHERE oih.batch_id = p_batch_id
--       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
--       AND pte_code IS NULL;

    --
    -- validation of Source System Code
    --
    -- To Be Picked From Profile if NULL
--    UPDATE xx_qp_mdpr_list_lines_stg oih
--       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
--           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
--           oih.error_desc = oih.error_desc || '~Modifier - Source System Code is NULL'
--     WHERE oih.batch_id = p_batch_id
--       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
--       AND source_system_code IS NULL;


    -- validation of Line Existence
    --
    UPDATE xx_qp_mdpr_list_hdr_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Hdr - Lines does not exist'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND NOT EXISTS (SELECT 1
                         FROM xx_qp_mdpr_list_lines_stg oil
                        WHERE oil.orig_sys_header_ref = oih.orig_sys_header_ref
                         AND  oil.batch_id = p_batch_id
                         AND DESELECT_FLAG IS NULL
                       )
       AND DESELECT_FLAG IS NULL;

    /****** Modifier Line Level Validation *****/
    --
    -- validation of Modifier Level Code
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Level Code is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (modifier_level_code IS NULL)-- AND modifier_level IS NULL);
       AND DESELECT_FLAG IS NULL;

    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Orig Sys is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (orig_sys_header_ref IS NULL
           OR orig_sys_line_ref IS NULL)
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Modifier Type
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Modifier Type is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (list_line_type_code IS NULL)-- AND list_line_type IS NULL);
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Pricing Phase
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Pricing Phase is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND pricing_phase_name IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Active Flag
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Active Flag is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND active_flag IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Product Attribute for Price Break Header
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Product Attribute for Price Break Header is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (product_attribute IS NULL
            AND (list_line_type_code = 'PBH' --OR UPPER(list_line_type) = 'Price Break Header'
                 ))
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Product Attribute Value for Price Break Header
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Product Attribute Value for Price Break Header is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (product_attr_value IS NULL
            AND (list_line_type_code = 'PBH' --OR UPPER(list_line_type) = 'Price Break Header'
                 ))
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Volume Type for Price Break Header
    --
    /*UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line- Volume Type for Price Break Header is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (volume_type IS NULL
            AND (list_line_type_code = 'PBH' --OR UPPER(list_line_type) = 'Price Break Header'));    */   --DROY

    --
    -- validation of Price Break Type for Price Break Header
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Price Break Type for Price Break Header is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (price_break_type_code IS NULL
            AND (list_line_type_code = 'PBH' --OR UPPER(list_line_type) = 'Price Break Header'
                ))
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of UOM for Price Break Header
    --
    UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - UOM for Price Break Header is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (price_break_type_code IS NULL
            AND (list_line_type_code = 'PBH' --OR UPPER(list_line_type) = 'Price Break Header'
                ))
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of From Value for Price Break Header
    --
    /*UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier Line - Value From for Price Break Header is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (pricing_attr_value_from IS NULL
            AND (list_line_type_code = 'PBH' --OR UPPER(list_line_type) = 'Price Break Header'));   */--DROY

    --
    -- validation of Arithmetic Operator for Price Break Header
    --
    /*UPDATE xx_qp_mdpr_list_lines_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Modifier - Arithmetic Operator for Price Break Header is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (arithmetic_operator IS NULL
            AND (list_line_type_code = 'PBH' --OR UPPER(list_line_type) = 'Price Break Header')); */ --DROY

    --
    -- Validation for Qualifiers
    --
    --
    -- validation of Modifier Name on Qualifier
    --
    UPDATE xx_qp_mdpr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Modifier Name is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND orig_sys_header_ref IS NULL
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Qualifier Context
    --
    UPDATE xx_qp_mdpr_list_qlf_stg oih
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
    UPDATE xx_qp_mdpr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Attribute is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (qualifier_attribute IS NULL)-- AND qualifier_attribute_code IS NULL);
       AND DESELECT_FLAG IS NULL;

    --
    -- validation of Qualifier Grouping Number
    --
    UPDATE xx_qp_mdpr_list_qlf_stg oih
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
    UPDATE xx_qp_mdpr_list_qlf_stg oih
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
    UPDATE xx_qp_mdpr_list_qlf_stg oih
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
    UPDATE xx_qp_mdpr_list_qlf_stg oih
       SET oih.process_code = xx_emf_cn_pkg.cn_preval,
           oih.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oih.error_desc = oih.error_desc || '~Qualifier - Attribute Value is NULL'
     WHERE oih.batch_id = p_batch_id
       AND NVL (oih.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND (qualifier_attr_value IS NULL )--AND qlfr_attr_value_code IS NULL);
       AND DESELECT_FLAG IS NULL;

       -- validation of Line Existence
    --
    UPDATE xx_qp_mdpr_list_qlf_stg qlf
       SET qlf.process_code = xx_emf_cn_pkg.cn_preval,
           qlf.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           qlf.error_desc = qlf.error_desc || '~Qualifier - Lines does not exist'
     WHERE qlf.batch_id = p_batch_id
       AND NVL (qlf.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND NOT EXISTS (SELECT 1
                         FROM xx_qp_mdpr_list_lines_stg oil
                        WHERE oil.orig_sys_header_ref = qlf.orig_sys_header_ref
                         AND  oil.batch_id = p_batch_id
                         AND  DESELECT_FLAG IS NULL
                       )
       AND DESELECT_FLAG IS NULL;

    /*UPDATE xx_qp_mdpr_list_qlf_stg qlf
       SET qlf.process_code = xx_emf_cn_pkg.cn_preval,
           qlf.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           qlf.error_desc = qlf.error_desc || '~Qualifier - Duplicate context, attribute, grouping_no'
     WHERE qlf.batch_id = p_batch_id
       AND NVL (qlf.ERROR_CODE, 0) = xx_emf_cn_pkg.CN_SUCCESS
       AND EXISTS              (SELECT 1
                                   FROM xx_qp_mdpr_list_qlf_stg qlf1
                                   WHERE qlf1.batch_id = p_batch_id
                                    AND  qlf1.qualifier_context = qlf.qualifier_context
                                    AND  qlf1.orig_sys_header_ref = qlf.orig_sys_header_ref
                                    AND  qlf1.qualifier_grouping_no = qlf.qualifier_grouping_no
                                    AND  qlf1.orig_sys_line_ref = qlf.orig_sys_line_ref
                                    AND  qlf1.qualifier_attribute = qlf.qualifier_attribute
                                  GROUP BY orig_sys_header_ref
                                          ,orig_sys_line_ref
                                          ,qualifier_context
                                          ,qualifier_attribute
                                          ,qualifier_grouping_no
                                  HAVING COUNT(record_number) > 1
                                  )
       AND DESELECT_FLAG IS NULL;

    FOR cur_rec IN c_print_error_mdf_rec LOOP
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
            ,p_category    => xx_emf_cn_pkg.cn_preval
            ,p_error_text  => cur_rec.error_desc
           ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     --,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                    -- ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                        );
    END LOOP;*/

    FOR cur_rec IN c_print_error_lines_mdf_rec LOOP
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
            ,p_category    => xx_emf_cn_pkg.cn_preval
            ,p_error_text  => cur_rec.error_desc
            ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                  --   ,p_record_identifier_4 => cur_rec.orig_sys_pricing_attr_ref
                  --   ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                        );
    END LOOP;

    FOR cur_rec IN c_print_error_qlf_rec LOOP
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
            ,p_category    => xx_emf_cn_pkg.cn_preval
            ,p_error_text  => cur_rec.error_desc
           ,p_record_identifier_1 => cur_rec.record_number
                     ,p_record_identifier_2 => cur_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => cur_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => cur_rec.orig_sys_qualifier_ref
                   --  ,p_record_identifier_5  => cur_rec.orig_sys_qualifier_ref
                        );
    END LOOP;


    COMMIT;
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

   /************************ Batch Level Validation for Modifiers *****************************/
   /************************ Overloaded Function *****************************/

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY xx_qp_mdpr_list_hdr_pre%ROWTYPE
   ) RETURN NUMBER IS

    x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    --- Local functions for all batch level validations
            --- Add as many functions as required in here
           ----------------------------------------------------------------------------
   /*--------------------------------------------------------------------------
   -- Function to validate the Modifier Number
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

    FUNCTION does_mdf_exist( p_mdf_number       IN      qp_list_headers_all.name%TYPE
                            ,p_mdf_name         IN      qp_list_headers_all.description%TYPE)
    RETURN NUMBER IS

      x_count           NUMBER          := 0;
      x_qlf_list_count  NUMBER    :=0;
      x_qlf_stg_count   NUMBER    :=0;

    BEGIN

        SELECT count(1) INTO x_count
        FROM   qp_list_headers_all
        WHERE  (name = p_mdf_number)-- OR description = p_mdf_name)
          AND list_type_code <> 'PRL';
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Count In Modifier Exist Validation ' || x_count);

        IF x_count > 0 THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Modifier already exists ');
            SELECT count(1)
            INTO x_qlf_list_count
            FROM qp_qualifiers
            WHERE list_header_id IN
                                (SELECT list_header_id
                                 FROM   qp_list_headers_all
                                  WHERE  (name = p_mdf_number)
                                  AND list_type_code <> 'PRL');
            SELECT count(1)
            INTO x_qlf_stg_count
            FROM xx_qp_mdpr_list_qlf_pre qlf
            WHERE orig_sys_header_ref IN
                                (SELECT orig_sys_header_ref
                                 FROM   xx_qp_mdpr_list_hdr_pre hdr
                                  WHERE  (name = p_mdf_number)
                                   AND hdr.batch_id = qlf.batch_id
                                  AND list_type_code <> 'PRL')
             AND batch_id = p_cnv_hdr_rec.batch_id;

             IF x_qlf_list_count = 0 AND x_qlf_stg_count >0 THEN
                x_error_code := xx_emf_cn_pkg.CN_REC_WARN;
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Modifier already exists but qualifiers need to be loaded');
             ELSE
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error
                  (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Modifier already exists=>'
                     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                 --    ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                 --    ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                       ,p_record_identifier_5  => p_mdf_number
                );
             END IF;


        ELSE
            x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
        END IF;

    RETURN x_error_code;

    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Modifier Exist Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Modifier Exist Validation =>'||SQLERRM
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                --     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                --     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                --     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
        RETURN x_error_code;
    END does_mdf_exist;

   /*--------------------------------------------------------------------------
   -- Function to validate the Currency Code
   --@params  - p_currency_code
   ---------------------------------------------------------------------------*/

    FUNCTION is_currency_code_valid(p_currency_code     IN      fnd_currencies.currency_code%TYPE)
    RETURN NUMBER IS

    x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_count           NUMBER          := 0;
    BEGIN

        SELECT 1 INTO x_count
        FROM fnd_currencies
        WHERE currency_code = p_currency_code;

    x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
    RETURN x_error_code;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid currency code =>'||xx_emf_cn_pkg.CN_NO_DATA
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                 --    ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                --     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_currency_code
                  );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid currency code =>'||xx_emf_cn_pkg.CN_TOO_MANY
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                   --  ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                   --  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                   --  ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Currency Code Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Currency Code Validation =>'||SQLERRM
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                 --    ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                 --    ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                 --    ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
        RETURN x_error_code;
    END is_currency_code_valid;

   /*--------------------------------------------------------------------------
   -- Function to validate the List Type
   --@params  - p_list_type, p_list_type_code
   ---------------------------------------------------------------------------*/
   FUNCTION is_list_type_valid (/*p_list_type             IN      VARCHAR2
                               ,*/p_list_type_code        IN OUT  VARCHAR2)
   RETURN NUMBER IS

    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_count      NUMBER := 0;
   BEGIN
    /*IF p_list_type IS NOT NULL THEN
        SELECT lookup_code INTO p_list_type_code
        FROM qp_lookups
        WHERE lookup_type = 'LIST_TYPE_CODE'
        AND   meaning = p_list_type
        AND enabled_flag = 'Y';
     ELSE*/
        SELECT 1 INTO x_count
        FROM qp_lookups
        WHERE lookup_type = 'LIST_TYPE_CODE'
        AND   lookup_code = p_list_type_code
        AND enabled_flag = 'Y';
     /*END IF;*/

   x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
   RETURN x_error_code;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid List Type =>'||xx_emf_cn_pkg.CN_NO_DATA
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                   --  ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                   --  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_list_type_code
           );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid List Type =>'||xx_emf_cn_pkg.CN_TOO_MANY
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In List Type Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Currency Code Validation =>'||SQLERRM
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
   END is_list_type_valid;

   /*--------------------------------------------------------------------------
   -- Function to validate the Pricing Transaction Entity
   --@params  - p_pte, p_pte_code
   ---------------------------------------------------------------------------*/
   FUNCTION is_pte_valid (p_pte         IN          VARCHAR2
                         ,p_pte_code    OUT         VARCHAR2)
   RETURN NUMBER IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
    SELECT lookup_code INTO p_pte_code
    FROM qp_lookups
    WHERE lookup_type = 'QP_PTE_TYPE'
    AND   lookup_code = p_pte;--DROY changed meaning to code

   x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
   RETURN x_error_code;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Transaction Entity =>'||xx_emf_cn_pkg.CN_NO_DATA
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    -- ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                    -- ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_pte
                   );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Transaction Entity =>'||xx_emf_cn_pkg.CN_TOO_MANY
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Pricing Transaction Entity Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Pricing Transaction Entity Validation =>'||SQLERRM
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
   END is_pte_valid;

   /*--------------------------------------------------------------------------
   -- Function to Get and Validate the Pricing Transaction Entity From Profile
   -- QP: Pricing Transaction Entity
   --@params  - p_pte, p_pte_code
   ---------------------------------------------------------------------------*/
   FUNCTION get_pte_code (p_pte_code    OUT         VARCHAR2)
   RETURN NUMBER IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
    SELECT pov.profile_option_value INTO p_pte_code
    FROM   fnd_profile_options po
          ,fnd_profile_option_values pov
    WHERE po.profile_option_name = 'QP_PRICING_TRANSACTION_ENTITY'
    AND   pov.profile_option_id = po.profile_option_id
    AND   pov.level_id = 10001;

   x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
   RETURN x_error_code;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Pricing Transaction Entity Profile Invalid=>'||xx_emf_cn_pkg.CN_NO_DATA
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                   --  ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                   --  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_pte_code
                   );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Pricing Transaction Entity Profile Invalid=>'||xx_emf_cn_pkg.CN_TOO_MANY
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Pricing Transaction Entity Profile Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Pricing Transaction Entity Validation =>'||SQLERRM
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
   END get_pte_code;

   /*--------------------------------------------------------------------------
   -- Function to validate the Source System
   --@params  - p_src_system, p_src_system_code
   ---------------------------------------------------------------------------*/
   FUNCTION is_src_system_valid (p_src_system         IN          VARCHAR2
                                ,p_src_system_code    OUT         VARCHAR2)
   RETURN NUMBER IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
    SELECT lookup_code INTO p_src_system_code
    FROM qp_lookups
    WHERE lookup_type = 'SOURCE_SYSTEM'
    AND   meaning = p_src_system;

   x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
   RETURN x_error_code;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Source System =>'||xx_emf_cn_pkg.CN_NO_DATA
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    -- ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                   --  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_src_system
                   );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Source System =>'||xx_emf_cn_pkg.CN_TOO_MANY
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Source System Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Source System Validation =>'||SQLERRM
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
   END is_src_system_valid;

   /*--------------------------------------------------------------------------
   -- Function to validate the Source System From Profile
   --@params  - p_src_system, p_src_system_code
   ---------------------------------------------------------------------------*/
   FUNCTION get_src_system_code (p_src_system_code    OUT         VARCHAR2)
   RETURN NUMBER IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
    SELECT pov.profile_option_value INTO p_src_system_code
    FROM   fnd_profile_options po
          ,fnd_profile_option_values pov
    WHERE po.profile_option_name = 'QP_SOURCE_SYSTEM_CODE'
    AND   pov.profile_option_id = po.profile_option_id
    AND   pov.level_id = 10001;

   x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
   RETURN x_error_code;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Source System Profile Invalid =>'||xx_emf_cn_pkg.CN_NO_DATA
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                   --  ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                   --  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                   --  ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                   );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Source System Profile Invalid =>'||xx_emf_cn_pkg.CN_TOO_MANY
              ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Source System Profile Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Source System Validation =>'||SQLERRM
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
   END get_src_system_code;

    /*--------------------------------------------------------------------------
   -- Function to validate the Operating Unit
   --@params  - p_src_system, p_src_system_code
   ---------------------------------------------------------------------------*/
   FUNCTION is_ou_valid  (p_ou_name          IN          VARCHAR2
                         ,p_org_id           OUT          VARCHAR2)
   RETURN NUMBER IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

   BEGIN
     SELECT organization_id INTO  p_org_id
     FROM hr_operating_units
     WHERE name = p_ou_name;

   x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
   RETURN x_error_code;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Operating Unit =>'||xx_emf_cn_pkg.CN_NO_DATA
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                  --   ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                  --   ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_ou_name
                   );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Operating Unit =>'||xx_emf_cn_pkg.CN_TOO_MANY
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Operating Unit Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Operating Unit Validation =>'||SQLERRM
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    /* ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref*/
                   );
        RETURN x_error_code;
   END is_ou_valid;


    -- Start of the main function perform_batch_validations
    -- This will only have calls to the individual functions.
   BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations For Modifiers');

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Check whether Modifier Already Exists');
    x_error_code_temp := does_mdf_exist(p_cnv_hdr_rec.name
                                       ,p_cnv_hdr_rec.description);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Currency Code');
    x_error_code_temp := is_currency_code_valid(p_cnv_hdr_rec.currency_code);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate List Type');
    x_error_code_temp := is_list_type_valid (/*p_cnv_hdr_rec.list_type
                                            ,*/p_cnv_hdr_rec.list_type_code);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Pricing Transaction Entity');
    IF p_cnv_hdr_rec.pte_code IS NOT NULL THEN
        x_error_code_temp := is_pte_valid (p_cnv_hdr_rec.pte_code
                                          ,p_cnv_hdr_rec.pte_code);
        x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    ELSE
        x_error_code_temp := get_pte_code (p_cnv_hdr_rec.pte_code);
        x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    END IF;

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Source System Code');
    --IF p_cnv_hdr_rec.source_system IS NOT NULL THEN
    IF p_cnv_hdr_rec.source_system_name IS NOT NULL THEN
        x_error_code_temp := is_src_system_valid (p_cnv_hdr_rec.source_system_name
                                                 ,p_cnv_hdr_rec.source_system_code);
        x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    ELSE
        x_error_code_temp := get_src_system_code (p_cnv_hdr_rec.source_system_code);
        x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    END IF;

    IF p_cnv_hdr_rec.orig_org_name IS NOT NULL THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Validate Operating Unit ');
        x_error_code_temp := is_ou_valid (p_cnv_hdr_rec.orig_org_name
                                         ,p_cnv_hdr_rec.org_id);
        x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    END IF;

    RETURN x_error_code;
   END data_validations;

/************************ Overloaded Function *****************************/

   FUNCTION data_validations
   (
      p_batch_id    IN VARCHAR2
   ) RETURN NUMBER IS


    x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    --- Local functions for all batch level validations
            --- Add as many functions as required in here
           ----------------------------------------------------------------------------

    -- Start of the main function perform_batch_validations
    -- This will only have calls to the individual functions.
   BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations For Modifier Lines');

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Modifier Level');


    BEGIN
    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Modifier Level code',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                   FROM qp_lookups qll
                   WHERE lookup_type = 'MODIFIER_LEVEL_CODE'
                     AND   lookup_code = oil.modifier_level_code
                     AND enabled_flag = 'Y'
                  );

      IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Modifier Level code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                    -- ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.modifier_level_code
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
      END IF;

    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Modifier Level');
    END;

    --x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Modifier Type');
    BEGIN
     UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid List Line Type code',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                       FROM qp_lookups qll
                       WHERE lookup_type = 'LIST_LINE_TYPE_CODE'
                         AND   lookup_code = oil.list_line_type_code
                         AND enabled_flag = 'Y'
                      );
     IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid List Line Type code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                     --,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.list_line_type_code
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;

    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Modifier Type');
    END;
    --x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Pricing Phase');
    BEGIN
     UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.pricing_phase_id = (SELECT pricing_phase_id
                                   FROM qp_pricing_phases qpp
                                   WHERE UPPER(qpp.name) = UPPER(oil.pricing_phase_name) )
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND oil.pricing_phase_name IS NOT NULL;

   UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Pricing Phase',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND oil.pricing_phase_name IS NULL;

     IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Phase'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                    -- ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_phase_name
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Pricing Phase');
    END;
    --x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    BEGIN
       UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Pricing Attribute Context',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                       FROM qp_prc_contexts_b qpcb
                       WHERE qpcb.prc_context_type = 'PRICING_ATTRIBUTE'
                       AND qpcb.prc_context_code = oil.pricing_attribute_context
                      )
       AND oil.pricing_attribute_context IS NOT NULL;

     IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Attribute Context'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                    -- ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute_context
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
    END IF;

    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Pricing Attribute Column',
           oil.error_flag_temp = 'Y'
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
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Attribute Column'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;

    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Pricing Attribute is NULL',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND oil.pricing_attribute_context IS NOT NULL
       AND oil.pricing_attribute IS NULL;


   IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Pricing Attribute is NULL'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                    -- ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';

   END IF;

   UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Pricing Attribute Context is NULL',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND oil.pricing_attribute_context IS NULL
       AND oil.pricing_attribute IS NOT NULL;

    IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Pricing Attribute Context is NULL'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_attribute_context
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
    END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Pricing Attribute');
    END;

        --x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    BEGIN
       /*UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Product Attribute Context is NULL',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND oil.product_attribute_context IS NULL;

     IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Product Attribute Context is NULL'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                  --   ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attribute_context
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;*/--Commented on 5th Feb since this validation is not true

       UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Product Attribute Context',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_prc_contexts_b qpcb
                        WHERE qpcb.prc_context_type = 'PRODUCT'
                          AND qpcb.prc_context_code = oil.product_attribute_context
                      )
       AND oil.product_attribute_context IS NOT NULL;

     IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Product Attribute Context'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attribute_context
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;

   UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Product Attribute Column ',
           oil.error_flag_temp = 'Y'
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
     FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Product Attribute Column'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attribute
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
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
       UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Item Number',
           oil.error_flag_temp = 'Y'
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
                      ); */
       FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Item Number'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                     --,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
    END IF;

    -----------------------Checking Customer Orderable flag -------------------------------------
    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Item Number does not have Customer Orderable Flag  Checked',
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

      FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Item Number does not have Customer Orderable Flag  Checked'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                 --    ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                     --,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';

    END IF;
    -----------------------Checking Oredrable flag end------------------------------------------

    UPDATE xx_qp_mdpr_list_lines_pre oil
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


    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid All Items Option',
           oil.error_flag_temp = 'Y'
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
                          AND   ffv.flex_value = oil.product_attr_value
                      )
--       AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE3';
    IF SQL%ROWCOUNT > 0 THEN
        FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid All Items Option'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                  --   ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
    END IF;

    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.product_attr_value = (SELECT ffv.flex_value
                         FROM fnd_flex_value_sets fvs
                             ,fnd_flex_values     ffv
                             ,fnd_flex_values_tl  ffvt
                        WHERE fvs.flex_value_set_name = 'QP:ITEM_ALL'
                          AND   ffv.flex_value_set_id = fvs.flex_value_set_id
                          AND   ffvt.flex_value_id = ffv.flex_value_id
                          AND   ffvt.language = 'US'
                          AND   ffv.flex_value = oil.product_attr_value
                                 )
     WHERE oil.batch_id = p_batch_id
       AND oil.product_attr_value IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE3';


    UPDATE xx_qp_mdpr_list_lines_pre oil
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
--       AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE2';

      IF SQL%ROWCOUNT > 0 THEN
      /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                       ,p_error_text  => ' No of records in error for Validate Product Attribute - Item Category  =>'||SQL%ROWCOUNT
                       ,p_record_identifier_1 => 'MULTIPLE RECORDS'
                      );  */
       FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Item Category'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                    -- ,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
      END IF;

    UPDATE xx_qp_mdpr_list_lines_pre oil
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

    /*UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.product_attr_value = oil.inventory_item
     WHERE oil.batch_id = p_batch_id;
       AND oil.inventory_item IS NOT NULL;*/
    ---------------------------Add Validation for DCODE (Product Type)--------------------------
    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Item DCODE',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM   fnd_flex_values_vl fvl
                               ,fnd_flex_value_sets fvs
                         WHERE fvl.flex_value_set_id = fvs.flex_value_set_id
                          AND   fvs.flex_value_set_name = 'INTG_PRODUCT_TYPE'
                          AND flex_value = oil.product_attr_value
                       )
--       AND oil.inventory_item IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE25';

      IF SQL%ROWCOUNT > 0 THEN

       FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Item Dcode'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_attr_value
                    -- ,p_record_identifier_6 => rec_err.product_attr_value
              );
       END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
      END IF;

    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.product_attr_value_code = oil.product_attr_value --no need to update product_attr_value since it is the same value
     WHERE oil.batch_id = p_batch_id
       AND oil.product_attr_value IS NOT NULL
       AND oil.product_attribute = 'PRICING_ATTRIBUTE25';
    ---------------------------End Validation for DCODE (Product Type)--------------------------

    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Product Attribute Value');
    END;

    BEGIN
       UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Price Break Type Code',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_lookups
                        WHERE lookup_type = 'PRICE_BREAK_TYPE_CODE'
                          AND   lookup_code = oil.price_break_type_code
                       )
       AND oil.price_break_type_code IS NOT NULL;

       IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Price Break Type Code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.price_break_type_code
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
       END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Price Break Type');
    END;




    BEGIN
        UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Comparison Operator Code',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_lookups
                        WHERE lookup_type = 'COMPARISON_OPERATOR'
                          AND lookup_code = oil.comparison_operator_code
                       )
       AND oil.comparison_operator_code IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Comparison Operator Code'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.comparison_operator_code
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Comparison Operator');
    END;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Validate UOM Code ');
    BEGIN
        UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid/NULL Unit Of Measure',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND (
            NOT EXISTS (SELECT 1
                         FROM mtl_units_of_measure
                        WHERE uom_code = oil.product_uom_code
                       ))
       AND oil.product_uom_code IS NOT NULL;
      IF SQL%ROWCOUNT > 0 THEN
      /*xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                       ,p_error_text  => ' No of records in error for Validate UOM  =>'||SQL%ROWCOUNT
                       ,p_record_identifier_1 => 'MULTIPLE RECORDS'
                      );  */
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalide UOM'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.product_uom_code
                   --  ,p_record_identifier_6 => rec_err.product_uom_code
              );
       END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
      END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate UOM');
    END;
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);


    BEGIN
        UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Arithmetic Operator',
           oil.error_flag_temp = 'Y'
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
       FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Arithmetic Operator'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.arithmetic_operator
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
       END IF;

    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Arithmetic Operator');
    END;


    BEGIN
        UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Related Modifier Group Type',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_lookups
                        WHERE lookup_type = 'RLTD_MODIFIER_GRP_TYPE'
                          AND lookup_code = oil.rltd_modifier_grp_type
                       )
       AND oil.rltd_modifier_grp_type IS NOT NULL;
     IF SQL%ROWCOUNT > 0 THEN
         FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Related Modifier Group Type'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.rltd_modifier_grp_type
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Rltd Modifier Group Type');
    END;

    BEGIN

    UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modifier Line - Invalid Pricing Group Sequence',
           oil.error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND NOT EXISTS (SELECT 1
                         FROM qp_lookups
                        WHERE lookup_type = 'PRICING_GROUP_SEQUENCE'
                        --AND meaning = oil.pricing_group_sequence
                          AND lookup_code = oil.pricing_group_sequence
                          AND enabled_flag = 'Y'
                        )
       AND oil.pricing_group_sequence IS NOT NULL;
       IF SQL%ROWCOUNT > 0 THEN
          FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Pricing Group Sequence'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.pricing_group_sequence
              );
           END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
       END IF;

    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Pricing Group Sequence');
    END;

    BEGIN
        UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modlist Line - Start Date for line is greater than end date of Header',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND EXISTS (SELECT 1
                     FROM xx_qp_mdpr_list_hdr_pre qpl
                    WHERE qpl.orig_sys_header_ref = oil.orig_sys_header_ref
                      AND qpl.end_date_active < oil.start_date_active
                      AND qpl.end_date_active IS NOT NULL
                      AND  oil.batch_id = qpl.batch_id
                       );

     IF SQL%ROWCOUNT > 0 THEN
   FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Start Date for line is greater than end date of Header'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                  --   ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.end_date_active
              );
       END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Start Date for line is greater');
    END;

    /*IF NVL(p_cnv_hdr_rec.global_flag, 'Y') = 'N' THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Validate Organization ');
        x_error_code_temp := is_org_valid (p_cnv_hdr_rec.organization_name
                                          ,p_cnv_hdr_rec.org_id);
        x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    END IF;*/--DROY

    --Price Break additional information
    BEGIN
        UPDATE xx_qp_mdpr_list_lines_pre oil
       SET oil.process_code = xx_emf_cn_pkg.CN_STG_DATAVAL,
           oil.ERROR_CODE = xx_emf_cn_pkg.cn_rec_err,
           oil.error_desc = oil.error_desc || '~Modlist Line - Insufficient Price Break Information',
           error_flag_temp = 'Y'
     WHERE oil.batch_id = p_batch_id
       --AND ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
       AND price_break_type_code IS NOT NULL
       AND from_orig_sys_hdr_ref IS NULL
       AND list_line_type_code = 'PBH'
     ;
     IF SQL%ROWCOUNT > 0 THEN
   FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
             xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Insufficient Price Break Information'
              ,p_record_identifier_1 => rec_err.record_number
                     ,p_record_identifier_2 => rec_err.orig_sys_header_ref
                     ,p_record_identifier_3 => rec_err.orig_sys_line_ref
                   --  ,p_record_identifier_4 => rec_err.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => rec_err.from_orig_sys_hdr_ref
              );
       END LOOP;
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Price Break Information');
    END;


    BEGIN
        UPDATE xx_qp_mdpr_list_lines_pre oil
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
         FOR rec_err IN (SELECT * FROM xx_qp_mdpr_list_lines_pre WHERE error_flag_temp = 'Y') LOOP
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
        UPDATE xx_qp_mdpr_list_lines_pre
        SET error_flag_temp = 'N';
     END IF;
    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'When Others in Validate Incompatibility Group Code');
    END;

    COMMIT;




    --Add ou_name validation --droy
    --Add Start Date validation -- droy
    --Add End Date Validation -- droy

    RETURN x_error_code;
   END data_validations;

   /************************ Batch Level Validation for Qualifiers *****************************/
   /************************ Overloaded Function *****************************/

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY xx_qp_mdpr_list_qlf_pre%ROWTYPE
   ) RETURN NUMBER IS

    x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    --- Local functions for all batch level validations
            --- Add as many functions as required in here
           ----------------------------------------------------------------------------

   /*--------------------------------------------------------------------------
   -- Function to validate the Modifier Number
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

    FUNCTION does_mdf_exist( p_mdf_number       IN      qp_list_headers_all.name%TYPE
                            ,p_request_id       IN      NUMBER
                            ,p_batch_id          IN      VARCHAR2)
    RETURN NUMBER IS

      x_count           NUMBER          := 0;
      x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN

        SELECT 1 INTO x_count
        FROM   xx_qp_mdpr_list_hdr_pre
        WHERE  name = p_mdf_number
          AND  request_id = p_request_id
          AND  batch_id = p_batch_id
          AND  rownum = 1;

        RETURN x_error_code;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Modifier Name in Qualifier=>'||xx_emf_cn_pkg.CN_NO_DATA
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                    -- ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_mdf_number
                   );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Modifier Name in Qualifier=>'||xx_emf_cn_pkg.CN_TOO_MANY
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     --,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     --,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Modifier Name Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Errors In Modifier Name in Qualifier Validation =>'||SQLERRM
               ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     --,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     --,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
        RETURN x_error_code;
    END does_mdf_exist;

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
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_qlf_context
              );        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Qualifier Context =>'||xx_emf_cn_pkg.CN_NO_DATA
            ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
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
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
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
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_qlf_attr_desc
              );
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
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
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
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                 --    ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
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

       IF (p_qlf_context = 'CUSTOMER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE2')
          OR   (p_qlf_context = 'SHIP_TO_CUST' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE40') --Ship to Cust

       THEN --Customer Name
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                 );
          END;
       END IF;

       IF p_qlf_context = 'CUSTOMER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE11'  THEN --Customer Ship to
          BEGIN
             -- Validation Logic from Deb
            SELECT site_use_id
             INTO p_qlf_attr_val
             FROM HZ_CUST_SITE_USES_ALL
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                 );
          END;
       END IF;

       IF p_qlf_context = 'CUSTOMER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE14'  THEN --Customer Bill to
          BEGIN
             -- Validation Logic from Deb
            SELECT site_use_id
             INTO p_qlf_attr_val
             FROM HZ_CUST_SITE_USES_ALL
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                 );
          END;
       END IF;

       IF p_qlf_context = 'CUSTOMER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE17'  THEN --Customer Bill to
          BEGIN
             -- Validation Logic from Deb

             SELECT b.party_site_id
             INTO p_qlf_attr_val
             FROM HZ_PARTIES a, HZ_PARTY_SITES b, HZ_PARTY_SITE_USES c, HZ_LOCATIONS d
             WHERE c.site_use_type = 'SHIP_TO'
             AND      c.party_site_id  = b.party_site_id
             AND      b.party_id         = a.party_id
             AND      d.location_id    =  b.location_id
             AND b.party_site_number=p_qlf_attr_val_disp;

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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
             AND   name = p_qlf_attr_val_disp;*/

             SELECT name
             INTO p_qlf_attr_val
             FROM qp_list_headers qlh
             WHERE qlh.list_type_code IN ('PRL','AGR')
             AND   view_flag = 'Y'
             AND   orig_system_header_ref = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                BEGIN
                   /*SELECT name
                   INTO p_qlf_attr_val
                   FROM xx_qp_pr_list_hdr_stg
                   WHERE orig_sys_header_ref = p_qlf_attr_val_disp
                    --AND  batch_id = g_batch_id
                    AND  request_id = xx_emf_pkg.g_request_id;*/
                    SELECT name
                    INTO p_qlf_attr_val
                    FROM xx_qp_pr_list_hdr_stg
                    WHERE list_type_code IN ('PRL','AGR')
                    --AND   view_flag = 'Y'
                      AND   orig_sys_header_ref = p_qlf_attr_val_disp;
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
                 );
          END;
       END IF;

       IF p_qlf_context = 'ORDER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE18'  THEN -- Ship From Organization
          BEGIN
             -- Validation Logic from Deb
             SELECT organization_id
             INTO p_qlf_attr_val
             FROM OE_SHIP_FROM_ORGS_V
             WHERE ORGANIZATION_CODE = p_qlf_attr_val_disp;

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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                                  ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                               ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
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
                         ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                           ,p_record_identifier_5  => p_qlf_context ||'-'||p_qlf_attr_val_disp
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
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Invalid Comparison Operator =>'||xx_emf_cn_pkg.CN_NO_DATA
             ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
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
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );
        RETURN x_error_code;
    END is_comp_op_valid;

   BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations For Qualifiers');

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Check for Existing Modifier');
    /*x_error_code_temp := does_mdf_exist(p_cnv_hdr_rec.modifier_name
                                       ,p_cnv_hdr_rec.request_id
                                       ,p_cnv_hdr_rec.batch_id);*/
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

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

    -- Put Qualifier Attribute Value Validation if Context and Attribute is within a known set.

    RETURN x_error_code;
   END data_validations;


   /************************ Data Derivation for Modifiers *****************************/
/************************ Overloaded Function *****************************/
    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT xx_qp_mdpr_list_hdr_pre%ROWTYPE
    ) RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
           x_error_code := p_cnv_pre_std_hdr_rec.error_code;
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data - Derivations For Modifiers');
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,'Error Code -'||x_error_code);
           RETURN x_error_code;
    END data_derivations;

   /************************ Overloaded Function *****************************/
    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT xx_qp_mdpr_list_lines_pre%ROWTYPE
    ) RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data - Derivations For Modifiers');
           RETURN x_error_code;
    END data_derivations;

   /************************ Data Derivation for Qualifiers *****************************/
   /************************ Overloaded Function *****************************/
    FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT xx_qp_mdpr_list_qlf_pre%ROWTYPE
    ) RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data - Derivations For Qualifiers');
           RETURN x_error_code;
    END data_derivations;


    FUNCTION post_validations (p_batch_id IN VARCHAR2)
             RETURN NUMBER
    IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_lines_threshold  NUMBER;
    x_lines_thresh_rem NUMBER ;
    x_batch_no         NUMBER;

    CURSOR c_print_err_mod_rec
    IS
	  SELECT pre.record_number, --ADD FOR HEADER
		 --pre.name,
		 pre.list_line_type_code,
		 pre.pricing_phase_name
		   FROM xx_qp_mdpr_list_lines_pre pre
		   WHERE pre.process_code    = xx_emf_cn_pkg.CN_STG_DATAVAL
		     AND pre.error_code        = xx_emf_cn_pkg.cn_rec_err
		     AND pre.batch_id          = p_batch_id
		     AND pre.request_id        = xx_emf_pkg.g_request_id
	     ;

     CURSOR c_print_err_qual_rec
         IS
     	  SELECT pre.record_number,
     		 --pre.modifier_name,
     		 pre.qualifier_context,
     		 pre.qualifier_attribute
     		   FROM xx_qp_mdpr_list_qlf_pre pre
     		   WHERE pre.process_code    = xx_emf_cn_pkg.CN_STG_DATAVAL
     		     AND pre.error_code        = xx_emf_cn_pkg.cn_rec_err
     		     AND pre.batch_id          = p_batch_id
     		     AND pre.request_id        = xx_emf_pkg.g_request_id
	     ;

      CURSOR c_hdr_batch
         IS
          SELECT *
          FROM  xx_qp_mdpr_list_hdr_pre pre
          WHERE /*process_code      = xx_emf_cn_pkg.cn_postval
            AND*/ ERROR_CODE IN ( xx_emf_cn_pkg.cn_success, xx_emf_cn_pkg.cn_rec_warn )
            AND batch_id          = p_batch_id
            AND request_id        = xx_emf_pkg.g_request_id
          ORDER BY custom_lines_count;



    -- Start of the main function perform_batch_validations
    -- This will only have calls to the individual functions.
    BEGIN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');

       UPDATE xx_qp_mdpr_list_hdr_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_HEADER_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_mdpr_list_lines_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;

         UPDATE xx_qp_mdpr_list_lines_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_header_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_mdpr_list_hdr_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;

        UPDATE xx_qp_mdpr_list_qlf_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_header_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_mdpr_list_hdr_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;

          UPDATE xx_qp_mdpr_list_hdr_pre pre
         SET pre.process_code      = xx_emf_cn_pkg.cn_postval,
             pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
         WHERE
         pre.ORIG_SYS_HEADER_REF in
            (
              SELECT DISTINCT xqp.ORIG_SYS_HEADER_REF
              FROM xx_qp_mdpr_list_qlf_pre xqp
              WHERE
               xqp.error_code        = xx_emf_cn_pkg.CN_REC_ERR
               AND xqp.batch_id         = p_batch_id
               AND xqp.request_id = xx_emf_pkg.g_request_id
            )
         AND pre.batch_id         = p_batch_id
         AND pre.request_id = xx_emf_pkg.g_request_id
         ;

       /*** For Modifier ***********/
      /* xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Start Post Val for Modifiers');
       UPDATE xx_qp_mdpr_list_lines_pre xgcc
          SET process_code = xx_emf_cn_pkg.CN_STG_DATAVAL
             ,error_code   = xx_emf_cn_pkg.CN_REC_ERR
             ,error_desc   = '~Modifier: having one/all invalid component'
        WHERE batch_id   = p_batch_id
          AND request_id = xx_emf_pkg.G_REQUEST_ID
          --AND error_code = xx_emf_cn_pkg.CN_SUCCESS
          AND xgcc.name IN (SELECT distinct xgcc2.name
                        FROM xx_qp_mdpr_list_lines_pre xgcc2
                       WHERE
                             xgcc2.batch_id    = p_batch_id
                         AND xgcc2.request_id  = xx_emf_pkg.G_REQUEST_ID
                         AND xgcc2.error_code  = xx_emf_cn_pkg.CN_REC_ERR
                      )
        ;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Post-Validations:For Modifiers Number of Records Updated=>'||SQL%ROWCOUNT);

        COMMIT;

        FOR cur_rec1 IN c_print_err_mod_rec
	LOOP
	     xx_emf_pkg.error(p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			   ,p_category    => xx_emf_cn_pkg.cn_postval
			   ,p_error_text  => '~Modifier: having one/all invalid component'
                           ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     ,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              			 );


        END LOOP;*/
        /*** For Modifier ***********/

       /*** For Qualifiers ***********/
      /* xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Start Post Val for Modifiers');
              UPDATE xx_qp_mdpr_list_qlf_pre xgcc
                 SET process_code = xx_emf_cn_pkg.CN_STG_DATAVAL
                    ,error_code   = xx_emf_cn_pkg.CN_REC_ERR
                    ,error_desc   = '~Modifier: having one/all invalid component'
               WHERE batch_id   = p_batch_id
                 AND request_id = xx_emf_pkg.G_REQUEST_ID
                 --AND error_code = xx_emf_cn_pkg.CN_SUCCESS
                 AND xgcc.modifier_name IN (SELECT distinct xgcc2.modifier_name
                               FROM xx_qp_mdpr_list_qlf_pre xgcc2
                              WHERE
                                    xgcc2.batch_id    = p_batch_id
                                AND xgcc2.request_id  = xx_emf_pkg.G_REQUEST_ID
                                AND xgcc2.error_code  = xx_emf_cn_pkg.CN_REC_ERR
                             )
               ;
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Post-Validations:For Modifiers Number of Records Updated=>'||SQL%ROWCOUNT);

               COMMIT;

               FOR cur_rec2 IN c_print_err_qual_rec
       	LOOP
       	     xx_emf_pkg.error(p_severity    => xx_emf_cn_pkg.CN_MEDIUM
       			   ,p_category    => xx_emf_cn_pkg.cn_postval
       			   ,p_error_text  => '~Modifier: having one/all invalid component'
        ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_header_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_line_ref
                     --,p_record_identifier_4 => p_cnv_hdr_rec.orig_sys_pricing_attr_ref
                     ,p_record_identifier_5  => p_cnv_hdr_rec.orig_sys_qualifier_ref
              );

        END LOOP;*/
       /*** For Qualifiers ***********/




       --Begin batching process------------------------
        BEGIN
            x_lines_threshold := xx_emf_pkg.get_paramater_value ('XXQPMODLISTCNV', 'BATCH_SIZE');
            UPDATE xx_qp_mdpr_list_hdr_pre xph
            SET    custom_lines_count = (SELECT COUNT(record_number)
                                         FROM   xx_qp_mdpr_list_lines_pre xpl
                                         WHERE  xph.orig_sys_header_ref = xpl.orig_sys_header_ref
                                          AND  xph.batch_id = xpl.batch_id
                                          AND  xph.request_id = xpl.request_id
                                        )
             WHERE  batch_id          = p_batch_id
             AND   request_id        = xx_emf_pkg.g_request_id;
            xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'After custom lines count update for records :'||SQL%ROWCOUNT);

            x_lines_thresh_rem := x_lines_threshold;
            x_batch_no         := 1;

            FOR cur_rec in c_hdr_batch LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'x_lines_thresh_rem :'||x_lines_thresh_rem);
               xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'cur_rec.custom_lines_count :'||cur_rec.custom_lines_count);

               IF x_lines_thresh_rem < cur_rec.custom_lines_count THEN
                  x_batch_no := X_batch_no + 1;
                  x_lines_thresh_rem := x_lines_threshold;
               END IF;


               UPDATE xx_qp_mdpr_list_hdr_pre
               SET    custom_batch_no  = x_batch_no
               WHERE  record_number    = cur_rec.record_number
                AND   batch_id          = p_batch_id
                AND   request_id        = xx_emf_pkg.g_request_id;

               x_lines_thresh_rem := x_lines_thresh_rem - cur_rec.custom_lines_count;

           END LOOP;
           COMMIT;
        END;


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
END post_validations;

END xx_qp_mod_list_cnv_val_pkg
;
/
