DROP PACKAGE BODY APPS.XX_HR_SAL_CNV_VALIDATIONS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_HR_SAL_CNV_VALIDATIONS_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Arjun K
 Creation Date : 11-JAN-2012
 File Name     : XXHRSALVAL.pkb
 Description   : This script creates the body of the package
                 XX_HR_SAL_CNV_VALIDATIONS_PKG
 Change History:
 Date           Name            Remarks
 -----------    -----------     -----------------------------------
 11-JAN-2012    Arjun K         Initial development.
 11-JAN-2012    Arjun K         Reason Code Validation modified and
                                Check for duplicate change date added
 11-JAN-2012    Arjun K         Get_person_id and get_assignment_id functions
                                modified to remove the current_employee_flag check.
 11-JAN-2012    Arjun K         get_assignment_id modified to get the latest assignment record.
 11-JAN-2012    Arjun K         get_business_group_id Procedure modified.
 11-JAN-2012    Arjun K         enable flag filter removed while getting the lookup code from PROPOSAL REASON
 11-JAN-2012    Arjun K         Change made as per Ansell requirement
*/
----------------------------------------------------------------------
   /**** Remove this comment at delivery
   Not touching the following function
   *****/
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
   FUNCTION pre_validations (p_cnv_hdr_rec IN OUT nocopy xx_hr_sal_conversion_pkg.G_XX_HR_CNV_PRE_REC_TYPE
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
		x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
		RETURN x_error_code;
   END pre_validations;

   FUNCTION data_validations (
	p_cnv_hdr_rec IN OUT nocopy xx_hr_sal_conversion_pkg.G_XX_HR_CNV_PRE_REC_TYPE)
   RETURN NUMBER
   IS
	x_error_code        NUMBER := xx_emf_cn_pkg.cn_success;
	x_error_code_temp   NUMBER := xx_emf_cn_pkg.cn_success;
	x_party_id          NUMBER;
	--- Local functions for all batch level validations
	--- Add as many functions as required in here
         -----------------------------------------------------------------------------------------------------
         ----------( Stage 2: Reason Code Validation)---------------------------------------------------------
         ------------------------------------------------------------------------------------------------------


     FUNCTION is_reason_code_valid (p_proposal_reason IN OUT NOCOPY VARCHAR2)
        RETURN NUMBER
	IS
		x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
		x_variable     VARCHAR2 (40);
                x_proposal_reason_meaning VARCHAR2(900);
	BEGIN
         BEGIN
            IF p_proposal_reason IS NOT NULL
            THEN
                --x_proposal_reason_meaning :=  xx_hr_common_pkg.get_mapping_value('PROPOSAL_REASON', p_proposal_reason);
                SELECT lookup_code
                 INTO x_variable
                 FROM fnd_lookup_values
                WHERE lookup_type = 'PROPOSAL_REASON'
                  AND UPPER(meaning) = UPPER(p_proposal_reason)
                  AND TRUNC(sysdate) BETWEEN NVL(start_date_active,trunc(sysdate))
                                         AND NVL(end_date_active,sysdate)
		  AND language = userenv('LANG');
                   p_proposal_reason := x_variable;

            ELSE
	         p_proposal_reason := NULL;
	         RETURN x_error_code;
	    END IF;
         EXCEPTION
            WHEN TOO_MANY_ROWS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_proposalreason_valid,
                                     p_error_text => 'proposalReason code  toomany rows',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_proposal_reason
                    );
	    WHEN NO_DATA_FOUND
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_proposalreason_valid,
                                     p_error_text => 'proposalReason code nodatafound',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_proposal_reason
                    );
            WHEN OTHERS
            THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_proposalreason_valid,
                                     p_error_text => 'proposalReason code invalid',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_proposal_reason
                    );
         END;
         RETURN x_error_code;
      EXCEPTION
         WHEN OTHERS
            THEN
               IF x_error_code = xx_emf_cn_pkg.cn_success
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_proposalreason_valid,
                                     p_error_text =>'proposalReason unhandle excep',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_proposal_reason
                    );
               END IF;
		RETURN x_error_code;

      END is_reason_code_valid;

   ---------------------------------------------------------------------------------------------------
   -------------------< Check for duplicate change date (record already exists)  >---------------------
   ---------------------------------------------------------------------------------------------------
    FUNCTION chk_dup_change_date (p_assignment_id IN NUMBER
                                  ,p_business_group_id IN NUMBER
                                  ,p_change_date IN DATE)
        RETURN NUMBER
    IS
        x_error_code   NUMBER   := xx_emf_cn_pkg.cn_success;
        x_dummy        VARCHAR2 (2);
       CURSOR csr_dup_change_date is
     SELECT 1
       FROM per_pay_proposals
      WHERE assignment_id         = p_assignment_id
        AND business_group_id + 0 = p_business_group_id
        AND change_date           = p_change_date;
    BEGIN
        BEGIN
            OPEN csr_dup_change_date;
	    FETCH csr_dup_change_date INTO x_dummy;
	    IF csr_dup_change_date%NOTFOUND THEN
                NULL;
	    ELSE
                x_error_code := xx_emf_cn_pkg.cn_rec_err;
                xx_emf_pkg.error (p_severity  => xx_emf_cn_pkg.cn_low,
                                 p_category   => xx_emf_cn_pkg.cn_preval,
                                 p_error_text => 'Record with the same Change Date already exists',
                                 p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                 p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                 p_record_identifier_3 => p_change_date);
            END IF;
	    CLOSE csr_dup_change_date;
	EXCEPTION
            WHEN OTHERS
            THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error (p_severity  => xx_emf_cn_pkg.cn_low,
                                 p_category   => xx_emf_cn_pkg.cn_preval,
                                 p_error_text => 'Record with the same Change Date already exists',
                                 p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                 p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                 p_record_identifier_3 => p_change_date);
      END;
      RETURN x_error_code;
    EXCEPTION
        WHEN OTHERS
            THEN
               IF x_error_code = xx_emf_cn_pkg.cn_success
               THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                        p_category   => xx_emf_cn_pkg.cn_preval,
                                        p_error_text => 'Record with the same Change Date already exists',
                                        p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                        p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                        p_record_identifier_3 => p_change_date);
               END IF;
        RETURN x_error_code;

    END chk_dup_change_date;

         --------------------------------------------------------------------------------------------------------------
         --------------( Stage 2: Derivation for Business Group Id-----------------------------------------------------
	 --------------------------------------------------------------------------------------------------------------

      FUNCTION get_business_group_id (p_business_group_name  IN OUT NOCOPY  VARCHAR2
                                    , p_business_group_id    OUT    NOCOPY  NUMBER
                                    , p_record_number        IN             NUMBER
                                    ) RETURN NUMBER IS
         x_error_code   NUMBER        := xx_emf_cn_pkg.cn_success;
         x_bg_id       VARCHAR2 (40);
	 x_business_group_name per_business_groups.name%type;
      BEGIN
         p_business_group_id := null;
         BEGIN
            IF p_business_group_name IS NOT NULL THEN

                SELECT pbg.business_group_id, pbg.name
		  INTO p_business_group_id, x_business_group_name
		  FROM per_business_groups pbg
                 WHERE UPPER (pbg.name) = UPPER(p_business_group_name)--Commented for Integra upper(xx_hr_common_pkg.get_mapping_value('BUSINESS_GROUP',p_business_group_name))
                   AND trunc(sysdate) between date_from and nvl(date_to,sysdate)
                   AND enabled_flag = 'Y';
                   p_business_group_name := x_business_group_name;

                UPDATE xx_hr_pay_prop_pre
                   SET business_group_id   = p_business_group_id
                 WHERE record_number = p_record_number;
		COMMIT;
                RETURN x_error_code;

            ELSE

               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_busgrp_valid,
                                     p_error_text => xx_emf_cn_pkg.cn_business_grp_miss,
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_business_group_name
                                    );
	       RETURN x_error_code;

	    END IF;
	 EXCEPTION
            WHEN TOO_MANY_ROWS THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_busgrp_valid,
                                     p_error_text => xx_emf_cn_pkg.cn_business_grp_toomany,
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_business_group_name
                                    );
               RETURN x_error_code;
	    WHEN NO_DATA_FOUND THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_busgrp_valid,
                                     p_error_text => xx_emf_cn_pkg.cn_busigrp_nodta_fnd,
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_business_group_name
                                    );
               RETURN x_error_code;
	    WHEN OTHERS THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_busgrp_valid,
                                     p_error_text => xx_emf_cn_pkg.cn_business_grp_invalid,
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_business_group_name
                                    );
               RETURN x_error_code;
	 END;
      EXCEPTION
         WHEN OTHERS THEN
               IF x_error_code = xx_emf_cn_pkg.cn_success THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_busgrp_valid,
                                     p_error_text => xx_emf_cn_pkg.cn_exp_unhand,
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_business_group_name );
                  RETURN x_error_code;
               ELSE
                  RETURN x_error_code;
               END IF;

      END get_business_group_id;

         --------------------------------------------------------------------------------------------------------------
         --------------( Stage 2: Derivation for Assignment ID --------------------------------------------------------
	 --------------------------------------------------------------------------------------------------------------
      FUNCTION get_assignment_id(p_person_id        IN NUMBER
                               , p_assignment_id    OUT    NOCOPY NUMBER
                               , p_record_number    IN            NUMBER
                               ) RETURN NUMBER IS
         x_error_code       NUMBER        := xx_emf_cn_pkg.cn_success;
         x_assignment_id    NUMBER;
      BEGIN
        p_assignment_id := null;
         BEGIN
            IF p_person_id  IS NOT NULL THEN
              SELECT  paaf.assignment_id
		INTO  p_assignment_id
		FROM  per_all_people_f      papf
                     ,per_all_assignments_f paaf
               WHERE  papf.person_id = p_person_id
                 AND  papf.person_id = paaf.person_id
		 AND  papf.effective_start_date = (SELECT MAX(effective_start_date)
                                                     FROM per_all_people_f x
                                                    WHERE x.person_id = papf.person_id)
		 AND  paaf.effective_start_date = (SELECT MAX(y.effective_start_date)
                                                     FROM per_all_assignments_f y
                                                    WHERE y.person_id = paaf.person_id)
                 AND  paaf.primary_flag = 'Y';

	       UPDATE  xx_hr_pay_prop_pre
                  SET person_id       = p_person_id
                    , assignment_id   = p_assignment_id
                WHERE record_number   = p_record_number;
		COMMIT;

                RETURN x_error_code;

	    ELSE
	       p_assignment_id:=NULL;
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_assignmnt_id_id_valid,
                                     p_error_text => 'Assignment id is missing',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_person_id
                                    );
	       RETURN x_error_code;
	    END IF;
	 EXCEPTION
            WHEN TOO_MANY_ROWS THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   =>xx_emf_cn_pkg.cn_assignmnt_id_id_valid,
                                     p_error_text => 'Assignment id is returning toomany rows',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_person_id
                                    );
               RETURN x_error_code;
        WHEN NO_DATA_FOUND THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_assignmnt_id_id_valid,
                                     p_error_text => 'Assignment id is nodata found',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_person_id
                                    );
               RETURN x_error_code;
        WHEN OTHERS THEN
               x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_title_valid,
                                     p_error_text => xx_emf_cn_pkg.cn_business_grp_invalid,
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_person_id
                                    );
               RETURN x_error_code;
     END;
      EXCEPTION
         WHEN OTHERS THEN
               IF x_error_code = xx_emf_cn_pkg.cn_success THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
               xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                                     p_category   => xx_emf_cn_pkg.cn_assignmnt_id_id_valid,
                                     p_error_text => 'Assignment id is unhandle excep',
                                     p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                                     p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                                     p_record_identifier_3 => p_person_id );
                  RETURN x_error_code;
               ELSE
                  RETURN x_error_code;
               END IF;
      END get_assignment_id;
      --- Start of the main function perform_batch_validations
      --- This will only have calls to the individual functions.

      -- ******************************************************************************
      --                           Function to get_target_payroll_id
      -- ******************************************************************************
      FUNCTION get_target_payroll_id(p_payroll_name IN VARCHAR2,
                                     p_person_id    IN NUMBER,
				     p_bus_grp_id   IN NUMBER,
                                     p_payroll_id OUT nocopy NUMBER)
         RETURN NUMBER IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
	 x_address_id NUMBER :=NULL;
        BEGIN
	  p_payroll_id := NULL;
          IF p_payroll_name IS NOT NULL THEN
	      SELECT pay_basis_id
              INTO p_payroll_id
              FROM per_pay_bases
              WHERE upper(name) = upper(p_payroll_name)
               --WHERE upper(name) = upper(xx_hr_common_pkg.get_mapping_value('PAY_BASIS', upper(p_payroll_name)))
	       AND business_group_id = p_bus_grp_id;
          END IF;
	  RETURN x_error_code;
        EXCEPTION
          WHEN too_many_rows THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,   p_category => xx_emf_cn_pkg.cn_payroll_valid,   p_error_text => 'W:'||xx_emf_cn_pkg.cn_payroll_id_toomany,   p_record_identifier_1 => p_cnv_hdr_rec.employee_number,   p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,   p_record_identifier_3 => p_payroll_name);
            RETURN x_error_code;
          WHEN no_data_found THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,   p_category => xx_emf_cn_pkg.cn_payroll_valid,   p_error_text => 'W:'||xx_emf_cn_pkg.cn_payroll_id_nodata,   p_record_identifier_1 => p_cnv_hdr_rec.employee_number,   p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,   p_record_identifier_3 => p_payroll_name);
            RETURN x_error_code;
          WHEN others THEN
            x_error_code := xx_emf_cn_pkg.cn_rec_err;
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,   p_category => xx_emf_cn_pkg.cn_payroll_valid,   p_error_text => 'W:'||xx_emf_cn_pkg.cn_payroll_id_invalid,   p_record_identifier_1 => p_cnv_hdr_rec.employee_number,   p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,   p_record_identifier_3 => p_payroll_name);
            RETURN x_error_code;
      END get_target_payroll_id;

      -- ******************************************************************************
      --                           Function to Get Target Tax Unit as GRE
      -- ******************************************************************************
      --KP
      /*FUNCTION get_target_tax_unit_id(p_gre_name VARCHAR2
                                  ,   p_tax_unit_id OUT nocopy NUMBER
                                  ) RETURN NUMBER IS
       x_error_code NUMBER := xx_emf_cn_pkg.cn_success;

       BEGIN
	p_tax_unit_id := null;
        IF p_gre_name IS NOT NULL  THEN
          SELECT htuv.tax_unit_id
          INTO p_tax_unit_id
          FROM hr_tax_units_v htuv
          WHERE htuv.name = xx_hr_common_pkg.get_mapping_value('GRE_NAME',   p_gre_name);
	END IF;
	RETURN x_error_code;
       EXCEPTION
          WHEN too_many_rows THEN
	     x_error_code := xx_emf_cn_pkg.cn_rec_err;
             --Changed by rojain on 18-Dec-2007 as required by FD.
             xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
	                      p_category => xx_emf_cn_pkg.cn_tax_unit_valid,
			      p_error_text => 'E:'||xx_emf_cn_pkg.cn_tax_unit_toomany,
	                      p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
			      p_record_identifier_2 => NULL,
			      p_record_identifier_3 => p_gre_name);
             RETURN x_error_code;
          WHEN no_data_found THEN
	     x_error_code := xx_emf_cn_pkg.cn_rec_err;
             xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
	                      p_category => xx_emf_cn_pkg.cn_tax_unit_valid,
			      p_error_text => 'E:'||xx_emf_cn_pkg.cn_tax_unit_nodata,
	                      p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
			      p_record_identifier_2 => NULL,
			      p_record_identifier_3 => p_gre_name);
             RETURN x_error_code;
          WHEN others THEN
	     x_error_code := xx_emf_cn_pkg.cn_rec_err;
             xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
	                      p_category => xx_emf_cn_pkg.cn_tax_unit_valid,
			      p_error_text => 'E:'||xx_emf_cn_pkg.cn_tax_unit_invalid,
			      p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
			      p_record_identifier_2 => NULL,
			      p_record_identifier_3 => p_gre_name);
             RETURN x_error_code;
        END get_target_tax_unit_id;*/
        --KP

      BEGIN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Validations');
         x_error_code_temp := get_business_group_id (p_cnv_hdr_rec.business_group_name
                                                 ,p_cnv_hdr_rec.business_group_id
                                                 , p_cnv_hdr_rec.record_number
                                                 );
     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );

     xx_hr_common_pkg.get_ids (
                  p_first_name       => NULL ,
                  p_last_name        => NULL ,
                  p_employee_number  => p_cnv_hdr_rec.unique_id ,
                  p_npw_number       =>  NULL,
                  p_business_group_name    =>  p_cnv_hdr_rec.business_group_name,
                  p_person_type      => NULL,
                  p_date_of_birth    => NULL ,
     	          p_source_prog      => 'EMPSAL VAL',
                  p_person_id        => p_cnv_hdr_rec.person_id ,
                  p_party_id         => x_party_id ,
                  p_error_code       => x_error_code_temp
             );

     x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );

     IF p_cnv_hdr_rec.person_id IS NOT NULL THEN
        x_error_code_temp := get_assignment_id( p_cnv_hdr_rec.person_id
                                              , p_cnv_hdr_rec.assignment_id
                                              , p_cnv_hdr_rec.record_number
                                              );
        x_error_code := FIND_MAX ( x_error_code, x_error_code_temp );
     END IF;

    IF p_cnv_hdr_rec.change_date IS NULL THEN
       x_error_code_temp := xx_emf_cn_pkg.cn_rec_err;
       xx_emf_pkg.error (p_severity   => xx_emf_cn_pkg.cn_low,
                             p_category   => 'DVAL-001',
                             p_error_text => 'Change date is Null',
                             p_record_identifier_1 => p_cnv_hdr_rec.employee_number,
                             p_record_identifier_2 => p_cnv_hdr_rec.business_group_name,
                             p_record_identifier_3 => p_cnv_hdr_rec.proposed_salary_n
                            );
     END IF;

     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );

     x_error_code_temp  := is_reason_code_valid(p_cnv_hdr_rec.proposal_reason);
     x_error_code       := FIND_MAX ( x_error_code, x_error_code_temp );

     x_error_code_temp := chk_dup_change_date(p_cnv_hdr_rec.assignment_id
                                              ,p_cnv_hdr_rec.business_group_id
                                              ,p_cnv_hdr_rec.change_date);
     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );

     --x_error_code_temp := get_target_tax_unit_id(p_cnv_hdr_rec.gre_name,--KP
     --                                        p_cnv_hdr_rec.tax_unit_id);--KP
     --x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
     --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' GRE  Derived ' );

     x_error_code_temp :=  get_target_payroll_id(p_cnv_hdr_rec.salary_basis,
	                                         p_cnv_hdr_rec.person_id,
						 p_cnv_hdr_rec.business_group_id,
	                                         p_cnv_hdr_rec.pay_basis_id);

     x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );

     --xx_emf_pkg.propagate_error ( x_error_code_temp );
     RETURN x_error_code;
     EXCEPTION
        WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                RETURN x_error_code;
          WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
              x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
              RETURN x_error_code;
          WHEN OTHERS THEN
               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                  RETURN x_error_code;
      END data_validations;
-------------------------------------------------------------------------
-----------< post_validations >----------------------------------------------
-------------------------------------------------------------------------
  FUNCTION post_validations
   RETURN NUMBER
        IS
        x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
        x_error_code_temp NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
         BEGIN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Post-Validations');
     RETURN x_error_code;
    EXCEPTION
        WHEN xx_emf_pkg.G_E_REC_ERROR THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            RETURN x_error_code;
        WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
            x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
            RETURN x_error_code;
        WHEN OTHERS THEN
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            RETURN x_error_code;
    END post_validations;
-------------------------------------------------------------------------
-----------< data_derivations >----------------------------------------------
-------------------------------------------------------------------------
       FUNCTION data_derivations (
                    p_cnv_pre_std_hdr_rec   IN OUT nocopy  xx_hr_sal_conversion_pkg.G_XX_HR_CNV_PRE_REC_TYPE
                    ) RETURN NUMBER   IS
      x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
   BEGIN
      RETURN x_error_code;
   END data_derivations;
END XX_HR_SAL_CNV_VALIDATIONS_PKG;
/
