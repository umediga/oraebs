DROP PACKAGE BODY APPS.XX_QP_QUAL_RUL_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_QP_QUAL_RUL_VAL_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : Debjani Roy
 Creation Date  : 11-Jun-2013
 File Name      : XXQPPRCQUALVL.pkb
 Description    : This script creates the specification of the validation package xx_price_list_qual_val_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------

----------------------------*------------------------------------------------------------------

 Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ---------------------------------------
1.0     11-Jun-2013 Debjani Roy          Initial development.
-------------------------------------------------------------------------
*/

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
      p_batch_id    IN VARCHAR2/*,
      p_prog        IN VARCHAR2*/
   ) RETURN NUMBER IS

    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    -- Start of the main function perform_batch_validations
    -- This will only have calls to the individual functions.

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

   /************************ Batch Level Validation for Qualifiers *****************************/

   FUNCTION data_validations
   (
      p_cnv_hdr_rec IN OUT NOCOPY XX_QP_RULES_QLF_PRE%ROWTYPE
   ) RETURN NUMBER IS

    x_error_code      NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    --- Local functions for all batch level validations
            --- Add as many functions as required in here
           ----------------------------------------------------------------------------

   /*--------------------------------------------------------------------------
   -- Function to validate the Qualifier Rule Name Name
   --@params  - p_name, p_list_header_id
   ---------------------------------------------------------------------------*/
      FUNCTION is_qlf_rule_exist( p_name IN VARCHAR2
                                 )
        RETURN NUMBER IS
          x_count           NUMBER          := 0;
          x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN


         SELECT count(name)
        INTO x_count
        FROM qp_qualifier_rules
        WHERE name = p_name
         ;

         IF x_count >0 THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier DUP RULE ');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Qualifier duplicate Rule '
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                  ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                  ,p_record_identifier_4 => p_name
                     );
         END IF;

          RETURN x_error_code;
        EXCEPTION

        WHEN OTHERS THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier Errors In Qualifier Context Validation ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error
                  (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Errors In Qualifier Context Validation =>'||SQLERRM
                    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
            RETURN x_error_code;
        END is_qlf_rule_exist;

    /*--------------------------------------------------------------------------
   -- Function to validate the Qualifier Context
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/
      FUNCTION is_qlf_context_valid(/* p_name IN VARCHAR2
                                   ,*/ p_qlf_context       IN OUT  VARCHAR2)
        RETURN NUMBER IS
          x_count           NUMBER          := 0;
          x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN


         SELECT prc_context_code
        INTO p_qlf_context
        FROM qp_prc_contexts_v
        WHERE
        upper(prc_context_type)='QUALIFIER'
        AND upper(prc_context_code)=upper(p_qlf_context)
         ;

          RETURN x_error_code;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier SQLCODE NODATA ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Invalid Qualifier Context =>'||xx_emf_cn_pkg.CN_NO_DATA
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                  ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                  ,p_record_identifier_4 => p_qlf_context
                     );

            RETURN x_error_code;
        WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier SQLCODE TOOMANY ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Invalid Qualifier Context =>'||xx_emf_cn_pkg.CN_TOO_MANY
                    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );

            RETURN x_error_code;
        WHEN OTHERS THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier Errors In Qualifier Context Validation ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error
                  (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Errors In Qualifier Context Validation =>'||SQLERRM
                    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
            RETURN x_error_code;
        END is_qlf_context_valid;


   /*--------------------------------------------------------------------------
   -- Function to validate the Qualifier Attribute
   --@params  - p_mdf_num, p_mdf_name
   ---------------------------------------------------------------------------*/

      FUNCTION is_qlf_attr_valid(/*p_name             IN       VARCHAR2
                               ,*/p_qlf_context       IN       VARCHAR2
                               ,p_qlf_attr          IN OUT   VARCHAR2
                               ,p_qlf_attr_code     OUT      VARCHAR2
                               )
        RETURN NUMBER IS
          x_count           NUMBER          := 0;
          x_error_code      NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN

          SELECT
          segment_code,segment_mapping_column
          INTO p_qlf_attr_code,p_qlf_attr
          FROM
          qp_prc_contexts_v cntx
          , qp_segments_v seg
          WHERE
          cntx.prc_context_id=seg.prc_context_id
          AND upper(seg.segment_mapping_column)=upper(p_qlf_attr)
          AND upper(cntx.prc_context_code)=upper(p_qlf_context)
          ;

             RETURN x_error_code;

        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier SQLCODE NODATA ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Invalid Qualifier Attribute =>'||xx_emf_cn_pkg.CN_NO_DATA
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                  ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                  ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr
                  --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                     );

            RETURN x_error_code;
        WHEN TOO_MANY_ROWS THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier SQLCODE TOOMANY ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Invalid Qualifier Attribute =>'||xx_emf_cn_pkg.CN_TOO_MANY
  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
            RETURN x_error_code;
        WHEN OTHERS THEN
            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier Errors In Qualifier Attribute Validation ' || SQLCODE);
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error
                  (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                  ,p_error_text  => 'Errors In Qualifier Attribute Validation =>'||SQLERRM
  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
            RETURN x_error_code;
        END is_qlf_attr_valid;

   /*--------------------------------------------------------------------------
   -- Function to validate the Qualifier Attribute Value
   -- Assumption - Attribute are of specific types
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'CUSTOMER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE11'  THEN --Customer Ship To Site Use
          BEGIN
             -- Validation Logic from Deb
             SELECT site_use_id
             INTO p_qlf_attr_val
             FROM HZ_CUST_SITE_USES_ALL
             WHERE orig_system_reference = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                 );
          END;
       END IF;


       IF p_qlf_context = 'MODLIST' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE4'  THEN -- Price List
          BEGIN
             -- Validation Logic from Deb
             SELECT list_header_id
             INTO p_qlf_attr_val
             FROM qp_secu_list_headers_vl
             WHERE list_type_code IN ('PRL','AGR')
             AND   view_flag = 'Y'
             AND   name = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                               ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                 );
          END;
       END IF;


       IF p_qlf_context = 'ORDER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE11'  THEN -- Shipped Flag
          BEGIN
             -- Validation Logic from Deb
             SELECT LOOKUP_CODE
             INTO p_qlf_attr_val
             FROM FND_LOOKUPS
             WHERE ENABLED_FLAG = 'Y'
             AND LOOKUP_TYPE = 'YES_NO'
             AND MEANING = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                 );
          END;
       END IF;

       IF p_qlf_context = 'ORDER' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE18'  THEN -- Ship From Org Id
          BEGIN
             -- Validation Logic from Deb
             SELECT organization_id
             INTO p_qlf_attr_val
             FROM OE_SHIP_FROM_ORGS_V
             WHERE NAME = p_qlf_attr_val_disp;

             RETURN x_error_code;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                               ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                               ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 );
                RETURN x_error_code;
             WHEN TOO_MANY_ROWS THEN
                xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
                x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                                 ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                                 ,p_error_text  => 'Invalid Qualifier Attribute Value=>'||xx_emf_cn_pkg.CN_NO_DATA
                                 ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
                                 ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                                 ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                                 ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                                 --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
                 );
          END;
       END IF;

       IF (p_qlf_context = 'INTG' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE31') -- Custom Attribute contract Terms
         OR( p_qlf_context = 'INTG' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE32' ) -- Custom Attribute Order Price list
         OR (p_qlf_context = 'INTG_SHIP_FROM_ORG' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE31' ) -- Custom Attribute SHIP FROM
         OR (p_qlf_context = 'RAD INT QUAL' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE31' ) -- Country Code
         OR (p_qlf_context = 'VOLUME' AND p_qlf_attr = 'QUALIFIER_ATTRIBUTE10')  -- Volume (Seeded Attribute)
         THEN
            --xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Deb Generic If stmt');
            p_qlf_attr_val := p_qlf_attr_val_disp;
       ELSE
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                           ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
                           ,p_error_text  => 'Unidentified Qualifier Attribute Value. New value needs to be mapped'
                                             ||' in the custom code'
                           ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                           ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                           ,p_record_identifier_3 => p_cnv_hdr_rec.qualifier_name
                           ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
                          --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
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
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Qualifier SQLCODE NODATA ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Qualifier Invalid Comparison Operator =>'||xx_emf_cn_pkg.CN_NO_DATA
  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
        RETURN x_error_code;
    WHEN TOO_MANY_ROWS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Qualifier Invalid Comparison Operator =>'||xx_emf_cn_pkg.CN_TOO_MANY
  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
        RETURN x_error_code;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Qualifier Comparision Operator Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error
              (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_STG_DATAVAL
              ,p_error_text  => 'Qualifier Errors In Comparison Operator Validation =>'||SQLERRM
  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                     ,p_record_identifier_2 => p_cnv_hdr_rec.orig_sys_qualifier_rule_ref
                     ,p_record_identifier_3 => p_cnv_hdr_rec.orig_sys_qualifier_ref
                     );
        RETURN x_error_code;
    END is_comp_op_valid;

   BEGIN

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations For Qualifiers');

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Check for Existing Rule List');
    x_error_code_temp := is_qlf_rule_exist(p_cnv_hdr_rec.qualifier_name
                                             );
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Qualifier Context');
    x_error_code_temp := is_qlf_context_valid(/*p_cnv_hdr_rec.price_list_name,*/p_cnv_hdr_rec.qualifier_context);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Qualifier Attribute');
    x_error_code_temp := is_qlf_attr_valid(/*p_cnv_hdr_rec.price_list_name
                                          ,*/p_cnv_hdr_rec.qualifier_context
                                          ,p_cnv_hdr_rec.qualifier_attribute
                                          ,p_cnv_hdr_rec.qualifier_attribute_code);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    --IF(upper(p_cnv_hdr_rec.qualifier_attribute_code)='SOLD_TO_ORG_ID') THEN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Qualifier Attribute Value');

    x_error_code_temp   := is_attr_value_valid(p_cnv_hdr_rec.qualifier_context
                                            ,p_cnv_hdr_rec.qualifier_attribute
                                            ,p_cnv_hdr_rec.qualifier_attr_value_disp
                                            ,p_cnv_hdr_rec.qualifier_attr_value);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
    --END IF;

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Validate Comparison Operator');
    x_error_code_temp := is_comp_op_valid (p_cnv_hdr_rec.comparison_operator_code);
    x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

    -- Put Qualifier Attribute Value Validation if Context and Attribute is within a known set.

    RETURN x_error_code;
   END data_validations;


   /************************ Data Derivation for Qualifiers *****************************/
   FUNCTION data_derivations (
        p_cnv_pre_std_hdr_rec IN OUT XX_QP_RULES_QLF_PRE%ROWTYPE
    ) RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data - Derivations For Qualifiers');
           RETURN x_error_code;
    END data_derivations;


    FUNCTION post_validations (p_batch_id IN VARCHAR2
                              /*,p_prog IN VARCHAR2*/)
             RETURN NUMBER
    IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    CURSOR c_print_error_rec
           IS
              SELECT pre.record_number,
                     pre.orig_sys_qualifier_rule_ref,
                     pre.orig_sys_qualifier_ref,
                     pre.qualifier_name
                       FROM XX_QP_RULES_QLF_PRE pre
                       WHERE pre.process_code    = xx_emf_cn_pkg.cn_postval
                         AND pre.error_code        = xx_emf_cn_pkg.CN_REC_ERR
                         AND pre.batch_id          = p_batch_id
                         AND pre.request_id        = xx_emf_pkg.g_request_id
                     ;

    -- Start of the main function perform_batch_validations
    -- This will only have calls to the individual functions.
    BEGIN
     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');
     --IF(p_prog='QUAL')  THEN
       /*** For Qualifier ***********/
       /*  This line is addd by kalam
       AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
       */
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Start Post Val for Qualifier');
       UPDATE XX_QP_RULES_QLF_PRE xgcc
          SET process_code = xx_emf_cn_pkg.cn_postval
             ,error_code   = xx_emf_cn_pkg.CN_REC_ERR
             --,error_desc   = '~Qualifier: having one/all invalid component'
        WHERE batch_id   = p_batch_id
          AND request_id = xx_emf_pkg.G_REQUEST_ID
          AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
          AND xgcc.orig_sys_qualifier_rule_ref in  (SELECT xgcc2.orig_sys_qualifier_rule_ref
                        FROM XX_QP_RULES_QLF_PRE xgcc2
                       WHERE xgcc2.batch_id    = p_batch_id
                         AND xgcc2.request_id  = xx_emf_pkg.G_REQUEST_ID
                         --AND xgcc2.list_type_code = xgcc.list_type_code
                         --AND xgcc2.list_line_type_code     = xgcc.list_line_type_code
                         AND error_code              = xx_emf_cn_pkg.CN_REC_ERR
                      )
        ;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, '~Post-Validations:Number of Records Updated=>'||SQL%ROWCOUNT);

        COMMIT;

        /*FOR cur_rec IN c_print_error_rec
        LOOP
         xx_emf_pkg.error(p_severity    => xx_emf_cn_pkg.CN_MEDIUM
               ,p_category    => xx_emf_cn_pkg.cn_postval
               ,p_error_text  => '~Qualifier: having one/all invalid component'
               ,p_record_identifier_1 => cur_rec.record_number
               ,p_record_identifier_2 => cur_rec.orig_sys_qualifier_ref
               ,p_record_identifier_3 => cur_rec.qualifier_name
              -- ,p_record_identifier_4 => p_qlf_context||'-'||p_qlf_attr_val_disp
               --,p_record_identifier_5  => p_qlf_context||'-'||p_qlf_attr_val_disp
             );


        END LOOP;*/
      --END IF;
       /*** For Qualifiers ***********/

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

END xx_qp_qual_rul_val_pkg;
/
