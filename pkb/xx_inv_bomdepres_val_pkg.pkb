DROP PACKAGE BODY APPS.XX_INV_BOMDEPRES_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_BOMDEPRES_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMDEPRESVAL.pkb
Description   : This script creates the package body of the package xx_inv_BOMDEPRES_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
06-Dec-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------

FUNCTION data_validations_BOMDEPRES
         (
         p_cnv_BOMDEPRES_rec   IN OUT xx_inv_BOMDEPRES_pkg.g_xx_inv_BOMDEPRES_rec_type
         )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate if ORG_CODE is valide
FUNCTION orgcode_validation (l_value IN VARCHAR2)
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
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Org_Code  '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'ORG_CODE Does Not Exist',
                          p_cnv_BOMDEPRES_rec.record_number,
                          p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'orgcode_validation Unhandled Exception',
                     p_cnv_BOMDEPRES_rec.record_number,
                     p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                     l_value
                     );
   RETURN x_error_code;
END orgcode_validation;

-- Validate if Department Code  is valid
FUNCTION dep_validation (l_value IN VARCHAR2,l_org_code in VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(a.department_id)
    into l_cnt
    FROM BOM_DEPARTMENTS A,
         ORG_ORGANIZATION_DEFINITIONS B
    WHERE A.ORGANIZATION_ID = B.ORGANIZATION_ID
    AND A.department_code = l_value
    and b.organization_code = l_org_code;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Department  '||l_value||' does not exist in Org '||l_org_code );
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Invalid Item',
                          p_cnv_BOMDEPRES_rec.record_number,
                          p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                          l_value||' - '||l_org_code
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Invalid Department',
                     p_cnv_BOMDEPRES_rec.record_number,
                     p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                     l_value||' - '||l_org_code
                     );
   RETURN x_error_code;
END dep_validation;

-- Validate if Resource Code  is valid
FUNCTION res_validation (l_value IN VARCHAR2,l_org_code in VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(a.resource_id)
    into l_cnt
    FROM BOM_RESOURCES A,
         ORG_ORGANIZATION_DEFINITIONS B
    WHERE A.ORGANIZATION_ID = B.ORGANIZATION_ID
    AND A.resource_code = l_value
    and b.organization_code = l_org_code;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Resource  '||l_value||' does not exist in Org '||l_org_code );
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Invalid Item',
                          p_cnv_BOMDEPRES_rec.record_number,
                          p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                          l_value||' - '||l_org_code
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Invalid Resource',
                     p_cnv_BOMDEPRES_rec.record_number,
                     p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                     l_value||' - '||l_org_code
                     );
   RETURN x_error_code;
END res_validation;

-- Validate if Resource Code  is valid
FUNCTION atp_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(a.rule_id)
    into l_cnt
    FROM mtl_atp_rules A
    WHERE A.rule_name= l_value;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'ATP RULE Is Invalid' );
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'ATP RULE Is Invalid',
                          p_cnv_BOMDEPRES_rec.record_number,
                          p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'ATP RULE Is Invalid',
                     p_cnv_BOMDEPRES_rec.record_number,
                     p_cnv_BOMDEPRES_rec.DEPT_CODE||' - '||p_cnv_BOMDEPRES_rec.RES_CODE,
                     l_value
                     );
   RETURN x_error_code;
END atp_validation;

BEGIN

    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting BOM Resources Data-Validations');

    x_error_code_temp := orgcode_validation (p_cnv_BOMDEPRES_rec.ORG_CODE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  orgcode_validation ' || x_error_code);

    x_error_code_temp := Dep_validation(p_cnv_BOMDEPRES_rec.DEPT_CODE,p_cnv_BOMDEPRES_rec.ORG_CODE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  Dep_validation ' || x_error_code);

    x_error_code_temp := res_validation(p_cnv_BOMDEPRES_rec.RES_CODE,p_cnv_BOMDEPRES_rec.ORG_CODE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  res_validation ' || x_error_code);

    IF p_cnv_BOMDEPRES_rec.ATP_RULE IS NOT NULL THEN
      x_error_code_temp := atp_validation(p_cnv_BOMDEPRES_rec.ATP_RULE);
      x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  atp_validation ' || x_error_code);
    END IF;

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
END data_validations_BOMDEPRES;

END xx_inv_BOMDEPRES_val_pkg;
/
