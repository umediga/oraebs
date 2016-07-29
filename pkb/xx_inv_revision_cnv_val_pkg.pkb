DROP PACKAGE BODY APPS.XX_INV_REVISION_CNV_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_REVISION_CNV_VAL_PKG" 
AS
----------------------------------------------------------------------
/* $Header: XXINVREVCNVVL.pkb 1.2 2012/02/15 12:00:00 dsengupta noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 30-Dec-2011
 File Name      : XXINVREVCNVVL.pkb
 Description    : This script creates the body of the Item Revision Conversion validation package

 Change History:

 Version Date        Name			Remarks
 ------- ----------- ----			-------------------------------
 1.0     30-Dec-11   IBM Development Team	Initial development.
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
    p_revision IN VARCHAR2,
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
              ,p_record_identifier_2 => p_revision
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
              ,p_record_identifier_2 => p_revision
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
              ,p_record_identifier_2 => p_revision
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
       UPDATE xx_inv_mtl_rev_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
       WHERE batch_id = p_batch_id
         AND organization_code is null;

     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Organization Code is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'Organization Code is null for' || x_count ||' Records'
                 );
     END IF;

     RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in Organization Code Validation  ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in Organization Code Validation=>'||SQLERRM
                  );
      RETURN x_error_code;
  END;

  BEGIN
       UPDATE xx_inv_mtl_rev_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
       WHERE batch_id = p_batch_id
         AND item_number is null;

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
	UPDATE xx_inv_mtl_rev_stg
       SET
        process_code = xx_emf_cn_pkg.CN_PREVAL,
        error_code = xx_emf_cn_pkg.CN_REC_ERR
       WHERE batch_id = p_batch_id
         AND revision is null;

     IF SQL%ROWCOUNT > 0
     THEN
         x_count:=SQL%ROWCOUNT;
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Revision is null for ' || x_count ||' Records');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'Revision is null for' || x_count ||' Records'
                 );
     END IF;

     RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in Revision Validation  ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in Revision Validation=>'||SQLERRM
                  );
      RETURN x_error_code;
  END;

  BEGIN
          SELECT count(*)
          INTO r_count
          FROM xx_inv_mtl_rev_stg
          WHERE
           batch_id = p_batch_id
           AND process_code = xx_emf_cn_pkg.CN_PREVAL
           AND error_code = xx_emf_cn_pkg.CN_REC_ERR;

        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Total Number of Errored Records in Revision Staging Table=> ' || r_count);
        xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                 ,p_category    => xx_emf_cn_pkg.CN_PREVAL
                 ,p_error_text  => 'Total Number of Errored Records in Revision Staging Table=> ' || r_count
                 );
        RETURN x_error_code;
  EXCEPTION
    WHEN OTHERS THEN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors in getting errored revisions record count ' || SQLCODE);
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_PREVAL
               ,p_error_text  => 'Errors in getting errored revisions record count =>'||SQLERRM
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
                           p_cnv_rev_rec IN OUT xx_inv_revision_cnv_pkg.G_XX_INV_REV_PRE_REC_TYPE
                          )
RETURN NUMBER
IS

x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

 --- Local functions for all batch level validations
 --- Add as many functions as required in here

  --**********************************************************************
  --Function to validate and derive Organization Code
  --**********************************************************************

    FUNCTION is_organization_valid (p_organization_code IN VARCHAR2)--, p_organization_id   OUT NUMBER)
                       RETURN NUMBER
    IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        --x_err_code   VARCHAR2(30);
        x_err_msg    VARCHAR2(200);
	x_org_code   VARCHAR2(10);
	x_org_id     NUMBER;

    BEGIN

      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid: Success Organization_Code=>'||p_organization_code);

      SELECT organization_id
        INTO x_org_id
        FROM mtl_parameters
       WHERE organization_code=p_organization_code;

       p_cnv_rev_rec.organization_id := x_org_id;

       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid: Success Organization_ID=>'||p_cnv_rev_rec.organization_id);

       RETURN x_error_code;

    EXCEPTION
       WHEN OTHERS THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors encountered in validating Organization ' || SQLCODE);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Error in Organization Code derive =>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_rev_rec.record_number
                  ,p_record_identifier_2 => p_cnv_rev_rec.revision
                  ,p_record_identifier_3 => p_cnv_rev_rec.organization_code
                  );
    RETURN x_error_code;
    END is_organization_valid;


  --**********************************************************************
  --Function to validate Item
  --**********************************************************************

    FUNCTION is_item_number_valid (
		      p_item_id      IN VARCHAR2
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
	x_item_id     NUMBER;
    BEGIN
        -- get the Oracle Item Number if cross exists between Legacy Item Number and Oracle Item Number
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid: ITEM_NUMBER=>'||p_item_id);
	xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid: Success Organization_ID=>'||p_organization_id);

       SELECT count(*)
         INTO x_count
         FROM mtl_system_items_b
        WHERE segment1 = p_item_id
          AND organization_id = p_organization_id;

        IF (x_count>0) THEN
	    x_error_code := xx_emf_cn_pkg.CN_SUCCESS;

	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ITEM ID => ' ||p_cnv_rev_rec.inventory_item_id);

	    SELECT inventory_item_id
	     INTO x_item_id
	     FROM mtl_system_items_b
	    WHERE segment1 = p_item_id
	      AND organization_id = p_organization_id;

	    p_cnv_rev_rec.inventory_item_id := x_item_id;

	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ITEM ID => ' ||x_item_id);

	    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'ITEM ID => ' ||p_cnv_rev_rec.inventory_item_id);

        ELSE
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Item not present in Organization=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_rev_rec.record_number
                  ,p_record_identifier_2 => p_cnv_rev_rec.revision
                  ,p_record_identifier_3 => p_cnv_rev_rec.organization_code
                 );
        END IF;

        RETURN x_error_code;

    EXCEPTION
          WHEN OTHERS THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Item Validation ' || SQLCODE);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Errors ITEM Validation=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_rev_rec.record_number
                  ,p_record_identifier_2 => p_cnv_rev_rec.revision
                  ,p_record_identifier_3 => p_cnv_rev_rec.organization_code
                  );
          RETURN x_error_code;

    END is_item_number_valid;

  --**********************************************************************
  --Function to validate Revision
  --**********************************************************************

    FUNCTION is_revision_valid (
		      p_revision      IN VARCHAR2
		      ,p_item_id      IN VARCHAR2
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
         FROM mtl_item_revisions
        WHERE inventory_item_id = (select inventory_item_id from mtl_system_items_b msi
				    where msi.segment1 = p_item_id
				      and organization_id = p_organization_id)
	  AND revision = p_revision
          AND organization_id = p_organization_id;

        IF (x_count=0) THEN
          x_error_code := xx_emf_cn_pkg.CN_SUCCESS;
        ELSE
          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
          xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Item already has the same Revision=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_rev_rec.record_number
                  ,p_record_identifier_2 => p_cnv_rev_rec.revision
                  ,p_record_identifier_3 => p_cnv_rev_rec.organization_code
                 );
        END IF;
        RETURN x_error_code;

    EXCEPTION
          WHEN OTHERS THEN
           xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Errors In Revision Validation ' || SQLCODE);
           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
           xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
                  ,p_category    => xx_emf_cn_pkg.CN_VALID
                  ,p_error_text  => 'Errors Revision Validation=>'||SQLERRM
                  ,p_record_identifier_1 => p_cnv_rev_rec.record_number
                  ,p_record_identifier_2 => p_cnv_rev_rec.revision
                  ,p_record_identifier_3 => p_cnv_rev_rec.organization_code
                  );
          RETURN x_error_code;

    END is_revision_valid;

        ------------------------ Start the BEGIN part of Data Validations ----------------------------------

        BEGIN
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');

            IF(p_cnv_rev_rec.organization_code IS NOT NULL)
               THEN
                  x_error_code_temp := is_organization_valid(p_cnv_rev_rec.organization_code);
                                                       --,p_cnv_rev_rec.organization_id);
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_orgn_code_valid - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_orgn_code_valid not called as organization_code is null ');
            END IF;

	    /*p_cnv_rev_rec.organization_id := fnd_profile.value('MSD_MASTER_ORG');
            --Fetch Organization Code for default Master Org profile value
            x_error_code_temp := is_organization_valid(p_cnv_rev_rec.organization_id);

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_orgn_code_valid - error '||x_error_code_temp);
            x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
	    IF(p_cnv_rev_rec.organization_code IS NULL)
	    THEN
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_organization_valid error due to unavailable Organization information');
	    END IF;*/

	       xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid - call :'||p_cnv_rev_rec.organization_id);

               IF(p_cnv_rev_rec.item_number IS NOT NULL)
               THEN
              x_error_code_temp := is_item_number_valid(p_cnv_rev_rec.item_number
                                                       ,p_cnv_rev_rec.organization_id);
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_item_number_valid not called as item number is null ');
               END IF;

               IF(p_cnv_rev_rec.revision IS NOT NULL)
               THEN
              x_error_code_temp := is_revision_valid(p_cnv_rev_rec.revision
						     ,p_cnv_rev_rec.item_number
                                                     ,p_cnv_rev_rec.organization_id);
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_revision_valid - error '||x_error_code_temp);
              x_error_code := FIND_MAX ( x_error_code, x_error_code_temp);
           ELSE
              xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'is_revision_valid not called as revision is null ');
           END IF;

               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code_temp---'||x_error_code_temp);
               xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'x_error_code---'||x_error_code);

               RETURN x_error_code;

   END data_validations;

    FUNCTION post_validations(p_batch_id IN VARCHAR2)
                  RETURN NUMBER
      IS
             x_error_code      NUMBER := xx_emf_cn_pkg.cn_success;
             x_error_code_temp NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low,'Inside Post-Validations');
        UPDATE xx_inv_mtl_rev_pre xip
	   SET error_code   = xx_emf_cn_pkg.CN_REC_ERR,
	       process_code = xx_emf_cn_pkg.CN_VALID
	 WHERE xip.batch_id = p_batch_id
	   AND error_code IN
                     (xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
	   AND EXISTS
	            (
	              SELECT 1
	                FROM mtl_item_revisions mir
	               WHERE mir.inventory_item_id = xip.inventory_item_id
	                 AND mir.revision = xip.revision
			 AND mir.organization_id = xip.organization_id
	            )
	  ;

	FOR cur_rec IN (SELECT revision,organization_code,record_number
	                  FROM xx_inv_mtl_rev_pre xip
	                 WHERE error_code=xx_emf_cn_pkg.CN_REC_ERR
	                   AND process_code=xx_emf_cn_pkg.CN_VALID
	                   AND batch_id = p_batch_id
	                )
	LOOP
	  xx_emf_pkg.error (p_severity    => xx_emf_cn_pkg.CN_MEDIUM
	                   ,p_category    => xx_emf_cn_pkg.CN_VALID
	                   ,p_error_text  => 'Revision already exists for the same item'
	                   ,p_record_identifier_1 => cur_rec.record_number
	                   ,p_record_identifier_2 => cur_rec.revision
	                   ,p_record_identifier_3 => cur_rec.organization_code
	                   );
         END LOOP;
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
          p_cnv_pre_rev_rec IN OUT xx_inv_revision_cnv_pkg.G_XX_INV_REV_PRE_REC_TYPE
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

END xx_inv_revision_cnv_val_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_REVISION_CNV_VAL_PKG TO INTG_XX_NONHR_RO;
