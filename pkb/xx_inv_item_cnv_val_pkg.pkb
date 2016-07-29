DROP PACKAGE BODY APPS.XX_INV_ITEM_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_ITEM_CNV_VAL_PKG" 
AS
----------------------------------------------------------------------
/* $Header: XXINVITEMCNVVL.pkb 1.2 2012/02/15 12:00:00 dsengupta noship $ */
/*
 Created By    : IBM Development Team
 Creation Date : 30-Dec-2011
 File Name     : XXINVITEMCNVVL.pks
 Description   : This script creates the body for the Item Conversion Validation package

 Change History:

 Version Date        Name			Remarks
 ------- ----------- ----			-------------------------------
 1.0     30-Dec-11   IBM Development Team	Initial development.
 2.0	 19-Feb-11   ABHARGAVA		Added on 19th Feb to change logic for ILS Pre-Production Template
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
    x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);

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
    p_segment1 IN VARCHAR2,
    p_organization_code    IN VARCHAR2

    )
RETURN NUMBER
IS
    x_lookup_value NUMBER;
BEGIN
       SELECT b.lookup_code
        INTO x_lookup_value
        FROM fnd_lookup_types a,
        fnd_lookup_values b
        WHERE
        a.lookup_type=b.lookup_type
        AND a.lookup_type=p_lookup_type
        AND language=UserEnv('LANG')
	AND NVL(b.enabled_flag,'Y') = 'Y'
        AND UPPER(meaning)=UPPER(p_lookup_value);

    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_lookup_value ' || x_lookup_value);
    RETURN x_lookup_value;
EXCEPTION
    WHEN TOO_MANY_ROWS THEN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
       --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
       x_lookup_value:=0;
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid '||p_lookup_text||'=>'||xx_emf_cn_pkg.CN_TOO_MANY
              ,p_record_identifier_1 => p_record_number
              ,p_record_identifier_2 => p_segment1
              ,p_record_identifier_3 => p_organization_code
         );
       --RETURN x_error_code;
       RETURN x_lookup_value;
    WHEN NO_DATA_FOUND THEN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
       --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
       x_lookup_value:=0;
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Invalid '||p_lookup_text||'=>'||xx_emf_cn_pkg.CN_NO_DATA
              ,p_record_identifier_1 => p_record_number
              ,p_record_identifier_2 => p_segment1
              ,p_record_identifier_3 => p_organization_code
         );

     --RETURN x_error_code;
     RETURN x_lookup_value;
    WHEN OTHERS THEN
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In  '||p_lookup_text||' Validation ' || SQLCODE);
       --x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
       x_lookup_value:=0;
       xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
              ,p_category    => xx_emf_cn_pkg.CN_VALID
              ,p_error_text  => 'Errors In  '||p_lookup_text||' Validation ' ||SQLERRM
              ,p_record_identifier_1 => p_record_number
              ,p_record_identifier_2 => p_segment1
              ,p_record_identifier_3 => p_organization_code
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
       UPDATE xx_inv_mtl_sys_item_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
       WHERE batch_id = p_batch_id
         AND segment1 is null;

     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Item Number is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'Item Number is null for' || x_count ||' Records'
                 );
     END IF;

     RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in Item Number Validation  ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in Item Number Validation=>'||SQLERRM
                  );
      RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_inv_mtl_sys_item_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
       WHERE batch_id = p_batch_id
        AND build_in_wip_flag is null;


     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'BUILD_IN_WIP_FLAG is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'BUILD_IN_WIP_FLAG is null for' || x_count||' Records'
                 );
     END IF;

     RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in BUILD_IN_WIP_FLAG Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in BUILD_IN_WIP_FLAG Validation=>'||SQLERRM
                  );
      RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_inv_mtl_sys_item_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
        WHERE batch_id = p_batch_id
         AND atp_components is null;



     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ATP_COMPONENTS is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'ATP_COMPONENTS is null for ' || x_count ||' Records'
                 );
     END IF;
     RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in ATP_COMPONENTS Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in ATP_COMPONENTS Validation=>'||SQLERRM
                  );
      RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_inv_mtl_sys_item_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
        WHERE batch_id = p_batch_id
         AND bom_item_type is null;

     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'BOM_ITEM_TYPE is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'BOM_ITEM_TYPE is null for ' || x_count ||' Records'
                 );
     END IF;
     RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in BOM_ITEM_TYPE Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in BOM_ITEM_TYPE Validation=>'||SQLERRM
                  );
      RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_inv_mtl_sys_item_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
        WHERE batch_id = p_batch_id
         AND organization_code is null ;


     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Organization Code is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'Organization Code is null for ' || x_count ||' Records'
                 );
     END IF;
     RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in Organization Code Validation ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in Organization Code Validation=>'||SQLERRM
                  );
      RETURN x_error_code;
  END;


  BEGIN
         UPDATE xx_inv_mtl_sys_item_stg
         SET
          process_code = xx_emf_cn_pkg.CN_PREVAL,
          error_code = xx_emf_cn_pkg.CN_REC_ERR
         WHERE batch_id = p_batch_id
           AND atp_flag is null ;


       IF SQL%ROWCOUNT > 0
       THEN
           x_count:=SQL%ROWCOUNT;
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ATP_FLAG is null for ' || x_count ||' Records');
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                   ,p_error_text  => 'ATP_FLAG is null for ' || x_count ||' Records'
                   );

       END IF;
       RETURN x_error_code;
    EXCEPTION
      WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in ATP_FLAG Validation ' || SQLCODE);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                    ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'Errors in ATP_FLAG Validation=>'||SQLERRM
                    );
      RETURN x_error_code;
  END;

  BEGIN
          SELECT count(*)
          INTO r_count
          FROM xx_inv_mtl_sys_item_stg
          WHERE
           batch_id = p_batch_id
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Total Number of Errored Records in Item Staging Table=> ' || r_count);
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'Total Number of Errored Records in Item Staging Table=> ' || r_count
                 );
        RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in getting errored items record count ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in getting errored items record count =>'||SQLERRM
                  );


  END;

  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code before returning'||x_error_code);
  COMMIT;
  xx_emf_pkg.propagate_error (x_error_code);
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

FUNCTION data_validations (
                           p_cnv_hdr_rec IN OUT xx_inv_item_cnv_pkg.G_XX_INV_ITEM_PRE_STD_REC_TYPE
                          )
RETURN NUMBER
IS

x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
x_template_name VARCHAR2(30);
--x_org_id	VARCHAR2(3) := fnd_profile.value('MSD_MASTER_ORG');

 --- Local functions for all batch level validations
 --- Add as many functions as required in here

  --**********************************************************************
  --Function to validate and derive Organization Code
  --**********************************************************************

    FUNCTION is_organization_valid (p_organization_id IN VARCHAR2)
                       RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_err_code   VARCHAR2(30);
        x_err_msg    VARCHAR2(200);
    x_org_code   VARCHAR2(10);

    BEGIN

      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid: Success Organization_ID=>'||p_organization_id);

      SELECT organization_code
        INTO x_org_code
        FROM mtl_parameters
       WHERE organization_id=p_organization_id;

       p_cnv_hdr_rec.organization_code := x_org_code;
       RETURN x_error_code;

    EXCEPTION
       WHEN OTHERS THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Organization Code derive ' || SQLCODE);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Error in Organization Code derive =>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                  ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
    RETURN x_error_code;
    END is_organization_valid;


  --**********************************************************************
  --Function to validate  ITEM_NUMBER
  --**********************************************************************

    FUNCTION is_item_number_valid (
              p_segment1      IN VARCHAR2
                      ,p_organization_id IN NUMBER
                      )
        RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        x_variable    VARCHAR2(4);
        x_count      NUMBER;
        x_space       VARCHAR2(10);
        n_itemnumber  NUMBER;
        l_itemfnd     NUMBER;
    BEGIN

       SELECT count(*)
         INTO x_count
         FROM mtl_system_items_b
        WHERE segment1 = p_segment1
          AND organization_id = p_organization_id;

        IF (x_count=0) THEN
          x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
        ELSE
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'ITEM NUMBER present in master=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                  ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                 );
        END IF;
        RETURN x_error_code;

    EXCEPTION
          WHEN OTHERS THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Item Number Validation ' || SQLCODE);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Errors ITEM NUMBER Validation=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                  ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
          RETURN x_error_code;

        END is_item_number_valid;

  -- Added on 19-nov-2013

  --**********************************************************************
  --Function to validate  Description
  --**********************************************************************

    FUNCTION is_item_desc_valid (
              p_description      IN VARCHAR2
                      )
        RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    BEGIN

      IF p_description is NULL THEN
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'ITEM Description is NULL in master=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                  ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                 );
        END IF;
        RETURN x_error_code;

    EXCEPTION
          WHEN OTHERS THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Item Description Validation=>' || SQLCODE);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Errors In Item Description Validation=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                  ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                  ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
          RETURN x_error_code;

     END is_item_desc_valid;

  --**********************************************************************
  --Function to validate MARK_ITEM_ORG_ASSGN_DUP_RECORDS
  --**********************************************************************

    FUNCTION mark_itemorgassgn_dup_record( p_segment1 IN VARCHAR2
                                          ,p_organization_id    IN NUMBER
                                         )
    RETURN NUMBER
    IS
       x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       x_dup_fnd    NUMBER := 0;

    BEGIN
       SELECT count(1)
         INTO x_dup_fnd
         FROM xx_inv_mtl_sys_item_pre
        WHERE segment1 = p_segment1
          AND organization_id    = p_organization_id
        ;

       IF x_dup_fnd >= 1
       THEN

      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Duplicate Item Org Assignment ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                ,p_category    => xx_emf_cn_pkg.CN_VALID
                ,p_error_text  => 'Duplicate Item Org Assignment '
                ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
               );
       END IF;

       RETURN x_error_code;


    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in duplicate assignment Validation ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.CN_VALID
                   ,p_error_text  => 'Errors in duplicate assignment Validation=>'||SQLERRM
                   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
          RETURN x_error_code;
    END mark_itemorgassgn_dup_record;

  --**********************************************************************
  --Function to validate BUILD_IN_WIP_FLAG
  --**********************************************************************

    FUNCTION is_build_in_wip_flag_valid(
                                         p_build_in_wip_flag IN VARCHAR2
                                       )
    RETURN NUMBER
    IS
       x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
       x_build_in_wip_flag VARCHAR2(10);

    BEGIN
       IF p_build_in_wip_flag !='Y' AND p_build_in_wip_flag !='N'
           THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid build_in_wip_flag ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                ,p_category    => xx_emf_cn_pkg.CN_VALID
                ,p_error_text  => 'Invalid build_in_wip_flag '
                ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
               );
       END IF;

       RETURN x_error_code;


    EXCEPTION
       WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in build_in_wip_flag Validation ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.CN_VALID
                   ,p_error_text  => 'Errors in build_in_wip_flag Validation=>'||SQLERRM
                   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
          RETURN x_error_code;
    END is_build_in_wip_flag_valid;

   --**********************************************************************
  --Function to validate LOT_CONTROL_CODE
  --**********************************************************************
    FUNCTION is_lot_control_code(
                     p_lot_control_code_text IN VARCHAR2
		    ,p_lot_control_code  OUT NUMBER
                  )
     RETURN NUMBER
     IS
       x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

    BEGIN

	IF p_lot_control_code_text IS NOT NULL THEN
	    IF p_lot_control_code_text = 'R' THEN
		p_lot_control_code := 2;
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid lot_control_code ' || SQLCODE);
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			,p_category    => xx_emf_cn_pkg.CN_VALID
			,p_error_text  => 'Invalid lot_control_code '
			,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			,p_record_identifier_2 => p_cnv_hdr_rec.segment1
			,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
		       );
	    END IF;
	ELSE
	    p_lot_control_code := 1;
	END IF;

	RETURN x_error_code;

    END is_lot_control_code;

    --**********************************************************************
    --Function to validate SHELF_LIFE_CODE
    --**********************************************************************
    FUNCTION is_shelf_life_code(
                         p_shelf_life_code_text IN VARCHAR2
			,p_shelf_life_code  OUT NUMBER
                      )
	RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    BEGIN

	IF p_shelf_life_code_text IS NOT NULL THEN
	    IF p_shelf_life_code_text = 'Y' THEN
		p_shelf_life_code := 4;
	    ELSE
		xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid shelf_life_code ' || SQLCODE);
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			,p_category    => xx_emf_cn_pkg.CN_VALID
			,p_error_text  => 'Invalid shelf_life_code '
			,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			,p_record_identifier_2 => p_cnv_hdr_rec.segment1
			,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
		       );
	    END IF;
	END IF;
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'shelf_life_code => ' || p_shelf_life_code);
	RETURN x_error_code;

    EXCEPTION
      WHEN OTHERS THEN
	   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		   ,p_category    => xx_emf_cn_pkg.CN_VALID
		   ,p_error_text  => 'Errors In SHELF_LIFE_CODE Validation=>'||SQLERRM
		   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
		   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
		  );
	RETURN x_error_code;
    END is_shelf_life_code;


      --**********************************************************************
      --Function to validate ALLOWED_UNITS_LOOKUP_CODE
      --**********************************************************************
     FUNCTION is_allowed_units_lookup_code(
                  p_allowed_units_lookup_txt IN VARCHAR2
                  ,p_allowed_units_lookup_code  OUT NUMBER
               )
     RETURN NUMBER
     IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_allowed_units_lookup_code NUMBER;
    x_count      NUMBER;

    BEGIN

    x_allowed_units_lookup_code := find_lookup_value(p_lookup_type           =>'MTL_CONVERSION_TYPE'
                         ,p_lookup_value     =>p_allowed_units_lookup_txt
                         ,p_lookup_text          =>'ALLOWED_UNITS_LOOKUP_CODE'
                         ,p_record_number     =>p_cnv_hdr_rec.record_number
                         ,p_segment1 =>p_cnv_hdr_rec.segment1
                         ,p_organization_code  =>p_cnv_hdr_rec.organization_code
                        );

    IF(x_allowed_units_lookup_code=0) THEN
        x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
        RETURN x_error_code;
    ELSE
        p_allowed_units_lookup_code:=x_allowed_units_lookup_code;
        x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
        RETURN x_error_code;
    END IF;

    EXCEPTION
      WHEN OTHERS THEN
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.CN_VALID
                   ,p_error_text  => 'Errors In ALLOWED_UNITS_LOOKUP_CODE Validation=>'||SQLERRM
                   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
             RETURN x_error_code;


    END is_allowed_units_lookup_code;
  --**********************************************************************
  --Function to validate DEFAULT_SO_SOURCE_TYPE
  --**********************************************************************

    FUNCTION is_default_so_source_type( p_default_so_source_type IN VARCHAR2
                ) RETURN NUMBER
    IS
     x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
     x_default_so_source_type VARCHAR2(10);
     x_count NUMBER;

    BEGIN

       IF p_default_so_source_type !='INTERNAL' and p_default_so_source_type !='EXTERNAL' THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, ' Invalid DEFAULT_SO_SOURCE_TYPE ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                ,p_category    => xx_emf_cn_pkg.CN_VALID
                ,p_error_text  => ' Invalid DEFAULT_SO_SOURCE_TYPE '
                ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
               );
       END IF;

       RETURN x_error_code;
       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'DEFAULT_SO_SOURCE_TYPE - error '||x_error_code);

    EXCEPTION
    WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in DEFAULT_SO_SOURCE_TYPE Validation ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.CN_VALID
                   ,p_error_text  => 'Errors in DEFAULT_SO_SOURCE_TYPE Validation=>'||SQLERRM
                   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
          RETURN x_error_code;
    END is_default_so_source_type;

    --**********************************************************************
     --Function to validate ATP_COMPONENTS
     --**********************************************************************
        FUNCTION is_atp_components(
                        p_atp_components_text IN VARCHAR2
                     ,p_atp_components_code  OUT NUMBER
                     )
        RETURN NUMBER
        IS
          x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
          x_atp_components_code NUMBER;
          x_count      NUMBER;

        BEGIN
                 x_atp_components_code := find_lookup_value(
                 --p_lookup_type       =>'MSC_ATP_COMPONENTS_FLAG'
                                                          p_lookup_type       =>'ATP_FLAG'
                                 ,p_lookup_value     =>p_atp_components_text
                                 ,p_lookup_text          =>'ATP_COMPONENTS'
                             ,p_record_number     =>p_cnv_hdr_rec.record_number
                             ,p_segment1 =>p_cnv_hdr_rec.segment1
                             ,p_organization_code  =>p_cnv_hdr_rec.organization_code
                                );
            IF(x_atp_components_code=0) THEN
        x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
        RETURN x_error_code;
        else
        p_atp_components_code:=x_atp_components_code;
        x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
        RETURN x_error_code;
        end if;
    EXCEPTION
         WHEN OTHERS THEN
             xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In ATP_COMPONENTS Validation ' || SQLCODE);
             x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
             xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                      ,p_category    => xx_emf_cn_pkg.CN_VALID
                      ,p_error_text  => 'Errors In ATP_COMPONENTS Validation=>'||SQLERRM
                      ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                      ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                      ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                     );
              RETURN x_error_code;


       END is_atp_components;

   --**********************************************************************
     --Function to validate SERIAL_NUMBER_CONTROL_CODE
     --**********************************************************************
        FUNCTION is_serial_number_cntrl_code(
                         p_serial_no_cntrl_code_text IN VARCHAR2
			,p_serial_no_control_code OUT NUMBER
                     )
        RETURN NUMBER
        IS
          x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        BEGIN
	    IF p_serial_no_cntrl_code_text IS NOT NULL THEN
		IF p_serial_no_cntrl_code_text = 'Y' THEN
		    p_serial_no_control_code := 5;
		ELSE
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Invalid serial_no_cntrl_code ' || SQLCODE);
		    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_VALID
			    ,p_error_text  => 'Invalid serial_no_cntrl_code '
			    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			    ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
			    ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
			   );
		END IF;
	    END IF;

	    RETURN x_error_code;

       END is_serial_number_cntrl_code;


    --**********************************************************************
    --Function to validate LOCATION_CONTROL_CODE
    --**********************************************************************
     FUNCTION is_location_control_code(
                  p_location_control_code_text IN VARCHAR2
                  ,p_location_control_code OUT NUMBER
               )
     RETURN NUMBER
     IS
    x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    x_location_control_code VARCHAR2(100);
    x_serial_number_control_code NUMBER;
    x_count      NUMBER;


     BEGIN
        x_location_control_code := find_lookup_value(p_lookup_type       =>'MTL_LOCATION_CONTROL'
                         ,p_lookup_value     =>p_location_control_code_text
                         ,p_lookup_text          =>'LOCATION_CONTROL_CODE'
                         ,p_record_number     =>p_cnv_hdr_rec.record_number
                         ,p_segment1 =>p_cnv_hdr_rec.segment1
                         ,p_organization_code  =>p_cnv_hdr_rec.organization_code
                     );
        IF(x_location_control_code=0) THEN
            x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
                RETURN x_error_code;

        else
        p_location_control_code:=x_location_control_code;
        x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
        RETURN x_error_code;
        end if;

     EXCEPTION
      WHEN OTHERS THEN
          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In LOCATION_CONTROL_CODE Validation ' || SQLCODE);
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                   ,p_category    => xx_emf_cn_pkg.CN_VALID
                   ,p_error_text  => 'Errors In LOCATION_CONTROL_CODE Validation=>'||SQLERRM
                   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                  );
           RETURN x_error_code;


    END is_location_control_code;

    --**********************************************************************
	--Function to validate ITEM_TYPE
    --**********************************************************************
    FUNCTION is_item_type(
		  p_item_type IN OUT VARCHAR2,
      p_item_status IN VARCHAR2,
		  p_template_name OUT VARCHAR2
	       )
     RETURN NUMBER
     IS
	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_item_type VARCHAR2(100);
	x_count      NUMBER;
	x_template_name    VARCHAR2(30);

    BEGIN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ITEM_TYPE - ' || p_item_type);
	IF(p_item_type is null) THEN
	    p_item_type := 'FGD'; -- DS: If Item Type is null it has to be considered as 'Finished Good'
	END IF;

	x_item_type := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ITEM_TYPE'
				      ,p_source      =>NULL
				      ,p_old_value   =>p_item_type
				      ,p_date_effective => sysdate
				      );
	p_item_type:=x_item_type;

  -- Added on 19th Feb to change logic for ILS Pre-Production Template
  IF UPPER(p_item_status) IN ('PROTOTYPE','PILOT') AND p_item_type = 'FG' THEN
      select a.PARAMETER_VALUE
      into x_template_name
      from XX_EMF_PROCESS_PARAMETERS a,
           XX_EMF_PROCESS_SETUP B
      where a.PROCESS_ID = B.PROCESS_ID
      and b.PROCESS_NAME = 'XXINVITEMCNV'
      and a.parameter_name = 'TEMPLATE_TYPE';

     	p_template_name := x_template_name;
     	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_template_name - ' || p_template_name);
     	x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
     	RETURN x_error_code;
   ELSE

	x_template_name := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'ITEM_TYPE_TO_TEMPLATE_NAME'
				      ,p_source      =>NULL
				      ,p_old_value   =>x_item_type
				      ,p_date_effective => sysdate
				      );
	p_template_name := x_template_name;
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_template_name - ' || p_template_name);
	x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
	RETURN x_error_code;
  END IF;
    EXCEPTION
      WHEN OTHERS THEN
	  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In ITEM_TYPE Validation ' || SQLCODE);
	  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		   ,p_category    => xx_emf_cn_pkg.CN_VALID
		   ,p_error_text  => 'Errors In ITEM_TYPE Validation=>'||SQLERRM
		   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
		   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
		  );
	RETURN x_error_code;

    END is_item_type;

    --**********************************************************************
	--Function to validate PRIMARY_UOM_CODE
    --**********************************************************************
    FUNCTION is_primary_uom_code(
		p_primary_uom_code IN OUT VARCHAR2
	       )
     RETURN NUMBER
     IS
	x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	x_primary_uom_code  VARCHAR2(100);
    BEGIN
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'PRIMARY_UOM - ' || p_primary_uom_code);

	x_primary_uom_code := xx_intg_common_pkg.get_mapping_value(p_mapping_type =>'PRIMARY_UOM'
				      ,p_source      =>NULL
				      ,p_old_value   =>p_primary_uom_code
				      ,p_date_effective => sysdate
				      );

	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'PRIMARY_UOM - ' || x_primary_uom_code);
	p_primary_uom_code := x_primary_uom_code;

	x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
	RETURN x_error_code;

    EXCEPTION
      WHEN OTHERS THEN
	  xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In PRIMARY_UOM_CODE Validation ' || SQLCODE);
	  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		   ,p_category    => xx_emf_cn_pkg.CN_VALID
		   ,p_error_text  => 'Errors In PRIMARY_UOM_CODE Validation=>'||SQLERRM
		   ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		   ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
		   ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
		  );
	RETURN x_error_code;

    END is_primary_uom_code;

    --**********************************************************************
           --Function to validate TEMPLATE_NAME
    --**********************************************************************

    FUNCTION is_template_exist( p_item_type    IN VARCHAR2 -- ***DS: to update parameters passed
                         ,p_template_name IN VARCHAR2
                         ,p_template_id  OUT   NUMBER
                     )RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_template_name VARCHAR2(30);
        x_count NUMBER;
    BEGIN

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'TEMPLATE_NAME ' || p_template_name);
       BEGIN

        SELECT template_id
        INTO p_template_id
        FROM mtl_item_templates muom
        WHERE upper(muom.template_name)=upper(p_template_name);

       EXCEPTION
          WHEN TOO_MANY_ROWS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE TOOMANY ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                        ,p_category    => xx_emf_cn_pkg.CN_VALID
                       ,p_error_text  => 'Invalid TEMPLATE_NAME =>'||xx_emf_cn_pkg.CN_TOO_MANY
                           ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                           ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                           ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                          );
              RETURN x_error_code;
          WHEN NO_DATA_FOUND THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'SQLCODE NODATA ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_VALID
                       ,p_error_text  => 'Invalid TEMPLATE_NAME Not Exists in Master =>'||xx_emf_cn_pkg.CN_NO_DATA
                           ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                           ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                           ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                          );
              RETURN x_error_code;
          WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In TEMPLATE_NAME Validation ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_VALID
                       ,p_error_text  => 'Errors In TEMPLATE_NAME Validation=>'||SQLERRM
                           ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                           ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                           ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                          );
              RETURN x_error_code;
       END;

       RETURN x_error_code;
    EXCEPTION
       WHEN OTHERS THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In TEMPLATE_NAME Validation ' || SQLCODE);
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_VALID
                       ,p_error_text  => 'Errors In TEMPLATE_NAME Validation=>'||SQLERRM
                           ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
                           ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
                           ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
                          );
              RETURN x_error_code;
    END is_template_exist;

    -- Added on 10-JUL-2013 for mrp_planning_code starts

    --**********************************************************************
	--Function to validate is_mrp_planning_code
    --**********************************************************************
    FUNCTION is_mrp_planning_code(
		              p_mrp_plann_code_text IN VARCHAR2
                  ,p_mrp_planning_code OUT NUMBER
	                 )
     RETURN NUMBER
     IS
	      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
	      x_mrp_planning_code  NUMBER;
    BEGIN
	   xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Original mrp_planning_code' || p_mrp_plann_code_text);

     IF p_mrp_plann_code_text = 'Not planned' THEN
           x_mrp_planning_code := 6;
     ELSIF p_mrp_plann_code_text = 'MRP planning'THEN
           x_mrp_planning_code := 3;
     ELSIF p_mrp_plann_code_text = 'MPS planning' THEN
           x_mrp_planning_code := 4;
     ELSIF p_mrp_plann_code_text = 'MRP/MPP Planned' THEN
           x_mrp_planning_code := 7;
     ELSIF p_mrp_plann_code_text = 'MPS/MPP Planned' THEN
           x_mrp_planning_code := 8;
     ELSIF p_mrp_plann_code_text = 'MPP Planned' THEN
            x_mrp_planning_code := 9;
	   END IF;

	    p_mrp_planning_code := x_mrp_planning_code;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Derive mrp_planning_code' || p_mrp_planning_code);
	    x_error_code:=xx_emf_cn_pkg.CN_SUCCESS;
	    RETURN x_error_code;

    EXCEPTION
      WHEN OTHERS THEN
	     xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In MRP_PLANNING_CODE Validation ' || SQLCODE);
	     x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	     xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
		     ,p_category    => xx_emf_cn_pkg.CN_VALID
		     ,p_error_text  => 'Errors In MRP_PLANNING_CODE Validation=>'||SQLERRM
		     ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
		     ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
		     ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
		    );
	    RETURN x_error_code;

    END is_mrp_planning_code;

   -- Added on 10-JUL-2013 for mrp_planning_code Ends

   -- Added for UAT on 13-dec-2013
    FUNCTION is_eng_item_flag(
                           p_inventory_item_status_code IN VARCHAR2
                          ,p_source_system IN VARCHAR2
			                    ,p_eng_item_flag OUT VARCHAR2

                     )
        RETURN NUMBER
        IS
          x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

        BEGIN
	      IF p_source_system ='O11' THEN
          IF UPPER(p_inventory_item_status_code) IN ('PROTOTYPE','PILOT') THEN
		        p_eng_item_flag := 'Y';
          ELSE
            p_eng_item_flag := 'N';
          END IF;
        END IF;
         RETURN x_error_code;
      EXCEPTION
       WHEN OTHERS THEN
		    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Error in deriving eng_item_flag ' || SQLCODE);
		    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		    xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
			    ,p_category    => xx_emf_cn_pkg.CN_VALID
			    ,p_error_text  => 'Error in deriving eng_item_flag '
			    ,p_record_identifier_1 => p_cnv_hdr_rec.record_number
			    ,p_record_identifier_2 => p_cnv_hdr_rec.segment1
			    ,p_record_identifier_3 => p_cnv_hdr_rec.organization_code
			   );
      RETURN x_error_code;
     END is_eng_item_flag;

        ------------------------ Start the BEGIN part of Data Validations ----------------------------------

        BEGIN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

	      p_cnv_hdr_rec.organization_id := fnd_profile.value('MSD_MASTER_ORG');
	      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'before serial ---'||p_cnv_hdr_rec.serial_number_control_code);
              --Fetch Organization Code for default Master Org profile value
              x_error_code_temp := is_organization_valid(p_cnv_hdr_rec.organization_id);

              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_orgn_code_valid - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           IF(p_cnv_hdr_rec.organization_code IS NULL)
           THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid error due to unavailable Organization information');
           END IF;

           IF(p_cnv_hdr_rec.segment1 IS NOT NULL)
           THEN
              x_error_code_temp := is_item_number_valid(p_cnv_hdr_rec.segment1
                                                       ,p_cnv_hdr_rec.organization_id);
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid not called as segment1 is null ');
           END IF;

           -- Description Validation 19-NOV-2013
           x_error_code_temp := is_item_desc_valid(p_cnv_hdr_rec.description);
           x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           -- End

           IF(p_cnv_hdr_rec.lot_control_code_text IS NOT NULL)
           THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_lot_control_code_text ' || p_cnv_hdr_rec.lot_control_code_text);
              x_error_code_temp := is_lot_control_code(p_cnv_hdr_rec.lot_control_code_text
                                                      ,p_cnv_hdr_rec.lot_control_code
                                                       );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_lot_control_code - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           END IF;

	   IF(p_cnv_hdr_rec.shelf_life_code_text IS NOT NULL)
           THEN
	      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'p_shelf_life_code_text ' || p_cnv_hdr_rec.shelf_life_code_text);
              x_error_code_temp := is_shelf_life_code(p_cnv_hdr_rec.shelf_life_code_text
                                                     ,p_cnv_hdr_rec.shelf_life_code
                                                     );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_shelf_life_code - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           END IF;

           IF(p_cnv_hdr_rec.serial_number_cntrl_code_text IS NOT NULL)
           THEN
              x_error_code_temp := is_serial_number_cntrl_code(p_cnv_hdr_rec.serial_number_cntrl_code_text
                                                              ,p_cnv_hdr_rec.serial_number_control_code
                                                              );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_serial_number_control_code - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           END IF;

           --IF(p_cnv_hdr_rec.item_type IS NOT NULL)
           --THEN
              x_error_code_temp := is_item_type(p_cnv_hdr_rec.item_type,p_cnv_hdr_rec.inventory_item_status_code, x_template_name
                                                             );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_type - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);

           --END IF;

           IF(p_cnv_hdr_rec.primary_uom_code IS NOT NULL)
           THEN
              x_error_code_temp := is_primary_uom_code(p_cnv_hdr_rec.primary_uom_code
                                                             );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_primary_uom_code - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_primary_uom_code not called as primary_uom_code is null ');
	            x_error_code:=xx_emf_cn_pkg.CN_REC_ERR;
           END IF;

           IF(x_template_name IS NOT NULL)
           THEN
              x_error_code_temp := is_template_exist(p_cnv_hdr_rec.item_type
                                                    ,x_template_name
                                                    ,p_cnv_hdr_rec.template_id
                                                    );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_template_exist - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	         ELSE
	            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_template_exist as template_name is null ');
           END IF;



     -- Added on 10-JUL-2013 for mrp_planning_code  Start
          IF(p_cnv_hdr_rec.mrp_planning_code_text IS NOT NULL)
           THEN
              x_error_code_temp := is_mrp_planning_code(p_cnv_hdr_rec.mrp_planning_code_text,
                                                        p_cnv_hdr_rec.mrp_planning_code
                                                             );
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_mrp_planning_code - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           END IF;
      -- Added on 10-JUL-2013 for mrp_planning_code  End

      -- Added on 13-dec-2013 for UAT
         x_error_code_temp := is_eng_item_flag(p_cnv_hdr_rec.inventory_item_status_code
			                                       ,p_cnv_hdr_rec.source_system_reference
                                             ,p_cnv_hdr_rec.eng_item_flag
                                             );
         x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
        -- Added on 13-dec-2013 for UAT END

          xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code_temp---'||x_error_code_temp);
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code---'||x_error_code);

           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'after serial ---'||p_cnv_hdr_rec.serial_number_control_code);

           RETURN x_error_code;
   END data_validations;

    FUNCTION post_validations(p_batch_id IN VARCHAR2)
                  RETURN NUMBER
      IS
             x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
             x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Post-Validations');
        UPDATE xx_inv_mtl_sys_item_pre xip
       SET error_code   = xx_emf_cn_pkg.CN_REC_ERR,
           process_code = xx_emf_cn_pkg.CN_VALID
     WHERE xip.batch_id = p_batch_id
       AND error_code IN
                     (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
       AND EXISTS
                (
                  SELECT 1
                    FROM mtl_system_items_b msi
                   WHERE msi.segment1        = xip.segment1
                     AND msi.organization_id = xip.organization_id
                )
      ;
    -- commented on 11-sep-2013
    /*FOR cur_rec IN (SELECT segment1,organization_code,record_number
                      FROM xx_inv_mtl_sys_item_pre xip
                     WHERE error_code=xx_emf_cn_pkg.CN_REC_ERR
                       AND process_code=xx_emf_cn_pkg.CN_VALID
                       AND batch_id = p_batch_id
		       AND EXISTS
			    (
			      SELECT 1
				FROM mtl_system_items_b msi
			       WHERE msi.segment1        = xip.segment1
				 AND msi.organization_id = xip.organization_id
			    )
                    )
    LOOP
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                       ,p_category    => xx_emf_cn_pkg.CN_VALID
                       ,p_error_text  => 'Item already exists'
                       ,p_record_identifier_1 => cur_rec.record_number
                       ,p_record_identifier_2 => cur_rec.segment1
                       ,p_record_identifier_3 => cur_rec.organization_code
                       );
         END LOOP;
         */
         COMMIT;
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
          p_cnv_pre_std_hdr_rec IN OUT xx_inv_item_cnv_pkg.G_XX_INV_ITEM_PRE_STD_REC_TYPE
   ) RETURN NUMBER
    IS
            x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
            x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        BEGIN

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivation');

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

END xx_inv_item_cnv_val_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEM_CNV_VAL_PKG TO INTG_XX_NONHR_RO;
