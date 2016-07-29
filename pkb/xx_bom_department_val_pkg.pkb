DROP PACKAGE BODY APPS.XX_BOM_DEPARTMENT_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_BOM_DEPARTMENT_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 09-DEC-2013
File Name     : XXBOMDEPTVAL.pkb
Description   : This script creates the package body of the package xx_bom_department_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
09-DEC-2013  Narendra Yadav         Initial Draft.
*/
-----------------------------------------------------------------------


FUNCTION data_validations_att (
         p_cnv_bom_dept_rec   IN OUT xx_bom_department_pkg.g_xx_bom_department_rec_type
        )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate whether Organization Code is valid or not
FUNCTION org_code_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from org_organization_definitions
    where organization_code = l_value;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Organization Code  - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Organization Code Does Not Exist',
                          p_cnv_bom_dept_rec.record_number,
                          p_cnv_bom_dept_rec.department_code,
                          p_cnv_bom_dept_rec.org_code
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'org_code_validation Unhandled Exception',
                     p_cnv_bom_dept_rec.record_number,
                     p_cnv_bom_dept_rec.department_code,
                     p_cnv_bom_dept_rec.org_code
                     );
   RETURN x_error_code;
END org_code_validation;

-- Validate whether Department cost category is valid or not
FUNCTION cost_cat_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
	INTO l_cnt
	FROM mfg_lookups
	WHERE lookup_type = 'BOM_EAM_COST_CATEGORY'
		  AND enabled_flag = 'Y'
		  AND UPPER(meaning) = UPPER(l_value);

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Department cost category does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Department cost category does not exist ',
                          p_cnv_bom_dept_rec.record_number,
                          p_cnv_bom_dept_rec.department_code,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'cost_cat_validation Unhandled Exception',
                     p_cnv_bom_dept_rec.record_number,
                     p_cnv_bom_dept_rec.department_code,
                     l_value
                     );
   RETURN x_error_code;
END cost_cat_validation;

-- Validate whether Location Code is valid or not
FUNCTION loc_code_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT COUNT(1)
	INTO l_cnt
	FROM hr_locations
	WHERE UPPER(location_code) = UPPER(l_value);
    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Location code does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Location code does not exist ',
                          p_cnv_bom_dept_rec.record_number,
                          p_cnv_bom_dept_rec.department_code,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'location code Unhandled Exception',
                     p_cnv_bom_dept_rec.record_number,
                     p_cnv_bom_dept_rec.department_code,
                     l_value
                     );
   RETURN x_error_code;
END loc_code_validation;

-- Validate whether Organization Code is valid or not
FUNCTION proj_exp_org_val (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
	FROM   hr_organization_units hrorg, pa_all_organizations paorg
	WHERE  paorg.organization_id = hrorg.organization_id
		   AND PAORG.PA_ORG_USE_TYPE = 'EXPENDITURES'
	       AND PAORG.INACTIVE_DATE IS NULL
		   AND trunc(sysdate) between hrorg.date_from and nvl(hrorg.date_to, trunc(sysdate))
		   AND upper(hrorg.name) = upper(l_value);

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Project Exp. Organization  - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Project Exp. Org is Invalid ',
                          p_cnv_bom_dept_rec.record_number,
                          p_cnv_bom_dept_rec.department_code,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Project Exp Organization  Unhandled Exception',
                     p_cnv_bom_dept_rec.record_number,
                     p_cnv_bom_dept_rec.department_code,
                     l_value
                     );
   RETURN x_error_code;
END proj_exp_org_val;

Function data_duplication_val(l_dept varchar2, l_org VARCHAR2)
         RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
     IF l_org is not null THEN
        SELECT COUNT(1)
        INTO l_cnt
        FROM BOM_DEPARTMENTS bdept,
             ORG_ORGANIZATION_DEFINITIONS ood
        WHERE ood.ORGANIZATION_CODE = l_org
              AND bdept.DEPARTMENT_CODE = l_dept
              AND bdept.ORGANIZATION_ID = ood.organization_id;
     END IF;
     IF l_cnt >= 1 THEN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Dept Already in Table for particular Organization - '||l_org);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Department already in table for this Organization ',
                          p_cnv_bom_dept_rec.record_number,
                          p_cnv_bom_dept_rec.department_code,
                          l_org
                          );
        RETURN x_error_code;
    ELSE
       RETURN  x_error_code;
    END IF;
END data_duplication_val;

BEGIN

    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting BOM Department Data-Validations');
    -- Modified by Narendra Yadav on 9th Dec 2013
    IF (p_cnv_bom_dept_rec.org_code is not null) THEN
      x_error_code_temp := org_code_validation (p_cnv_bom_dept_rec.org_code);
      x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  org_code_validation ' || x_error_code);
	ELSE
	  x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
	  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  org_code_validation failed by null value ' || x_error_code);
    END IF;

    --If Department Cost Category is not null then only validate
    IF  p_cnv_bom_dept_rec.dept_cost_cat is not NULL THEN
    x_error_code_temp := cost_cat_validation (p_cnv_bom_dept_rec.dept_cost_cat);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cost_cat_validation ' || x_error_code);
    END IF;

    --IF LOCATION is not null then only validate
    IF p_cnv_bom_dept_rec.location is not NULL THEN
      x_error_code_temp := loc_code_validation (p_cnv_bom_dept_rec.location);
      x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code - loc_code_validation ' || x_error_code);
    END IF;

    --If Project Expenditure Org is not null then only validate
    IF p_cnv_bom_dept_rec.proj_exp_org is not NULL THEN
      x_error_code_temp := proj_exp_org_val (p_cnv_bom_dept_rec.proj_exp_org);
      x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  proj_exp_org_val ' || x_error_code);
    END IF;

    x_error_code_temp := data_duplication_val (p_cnv_bom_dept_rec.DEPARTMENT_CODE, p_cnv_bom_dept_rec.ORG_CODE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code - Department for Organization already present in Table ' || x_error_code);

    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Completed Data-Validations');
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
END data_validations_att;

END xx_bom_department_val_pkg;
/
