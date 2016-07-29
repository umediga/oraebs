DROP PACKAGE BODY APPS.XX_INV_BOMRES_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_BOMRES_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMRESVAL.pkb
Description   : This script creates the package body of the package xx_inv_bomres_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
06-Dec-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------

FUNCTION data_validations_bomres
         (
         p_cnv_bomres_rec   IN OUT xx_inv_bomres_pkg.g_xx_inv_bomres_rec_type
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
                          p_cnv_bomres_rec.record_number,
                          p_cnv_bomres_rec.RESOURCE_CODE,
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
                     p_cnv_bomres_rec.record_number,
                     p_cnv_bomres_rec.RESOURCE_CODE,
                     l_value
                     );
   RETURN x_error_code;
END orgcode_validation;


-- Validate if Unique Constraint is not voilated
FUNCTION uc_validation (l_org_code IN VARCHAR2,l_cc_type IN VARCHAR2, l_res_code in VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from org_organization_definitions a, bom_resources b
    where a.organization_code = l_org_code
    and a.organization_id = b.organization_id
    and b.resource_code = l_res_code
    and b.cost_code_type = decode(nvl(l_cc_type,'N'),'Y',4,3);

    IF l_cnt = 0 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Org_Code , Res Code 	     @/u01/app/oracle/PROD/apps/apps_st/appl/xxintg/12.0.0/patch/115/sql/XXBOMDEPT.pks; Code Type Combination already exists '||l_org_code||' - '||l_cc_type||' - '||l_res_code);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Org_Code , Res Code 		 @/u01/app/oracle/PROD/apps/apps_st/appl/xxintg/12.0.0/patch/115/sql/XXBOMDEPTVAL.pks; Code Type Combination already exists ',
                          p_cnv_bomres_rec.record_number,
                          p_cnv_bomres_rec.RESOURCE_CODE,
                          l_org_code||' - '||l_cc_type||' - '||l_res_code
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'uc_validation Unhandled Exception ',
                     p_cnv_bomres_rec.record_number,
                     p_cnv_bomres_rec.RESOURCE_CODE,
                     l_org_code||' - '||l_cc_type||' - '||l_res_code
                     );
   RETURN x_error_code;
END uc_validation;

-- Validate if Resource Type  is valid
FUNCTION rtype_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN

    IF l_value in ('Person','Miscellaneous','Machine','Currency','Amount') THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Resource Type is not Valid ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Resource Type is not Valid ',
                          p_cnv_bomres_rec.record_number,
                          p_cnv_bomres_rec.RESOURCE_CODE,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'rtype_validation  Unhandled Exception',
                     p_cnv_bomres_rec.record_number,
                     p_cnv_bomres_rec.RESOURCE_CODE,
                     l_value
                     );
   RETURN x_error_code;
END rtype_validation;

-- Validate if Charge Type  is valid
FUNCTION ctype_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN

    IF l_value in ('PO Move','WIP Move','PO Receipt','Manual') THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Charge Type is not Valid ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Charge Type is not Valid ',
                          p_cnv_bomres_rec.record_number,
                          p_cnv_bomres_rec.RESOURCE_CODE,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'ctype_validation  Unhandled Exception',
                     p_cnv_bomres_rec.record_number,
                     p_cnv_bomres_rec.RESOURCE_CODE,
                     l_value
                     );
   RETURN x_error_code;
END ctype_validation;

-- Validate if Item Type  is valid
FUNCTION item_validation (l_value IN VARCHAR2,l_org_code in VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(a.inventory_item_id)
    into l_cnt
    FROM MTL_SYSTEM_ITEMS_B A,
         ORG_ORGANIZATION_DEFINITIONS B
    WHERE A.ORGANIZATION_ID = B.ORGANIZATION_ID
    AND A.SEGMENT1 = l_value
    and b.organization_code = l_org_code;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Item   '||l_value||' does not exist in Org '||l_org_code );
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Invalid Item',
                          p_cnv_bomres_rec.record_number,
                          p_cnv_bomres_rec.RESOURCE_CODE,
                          l_value||' - '||l_org_code
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Invalid Item',
                     p_cnv_bomres_rec.record_number,
                     p_cnv_bomres_rec.RESOURCE_CODE,
                     l_value||' - '||l_org_code
                     );
   RETURN x_error_code;
END item_validation;

-- Validate if Account Combination  is valid
FUNCTION acc_validation (l_value IN VARCHAR2,l_type in VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    FROM gl_code_combinations_kfv
    where concatenated_segments  = l_value;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,l_type || ' Account Combination   '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          l_type||' Account Combination is Invalid  ',
                          p_cnv_bomres_rec.record_number,
                          p_cnv_bomres_rec.RESOURCE_CODE,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'acc_validation Unhandled Exception',
                     p_cnv_bomres_rec.record_number,
                     p_cnv_bomres_rec.RESOURCE_CODE,
                     l_value
                     );
   RETURN x_error_code;
END acc_validation;


BEGIN

    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting BOM Resources Data-Validations');

    x_error_code_temp := orgcode_validation (p_cnv_bomres_rec.ORG_CODE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  orgcode_validation ' || x_error_code);

    x_error_code_temp := uc_validation (p_cnv_bomres_rec.ORG_CODE,p_cnv_bomres_rec.RESOURCE_CODE,p_cnv_bomres_rec.COST_CODE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  uc_validation ' || x_error_code);

    x_error_code_temp := rtype_validation (p_cnv_bomres_rec.RESOURCE_TYPE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  rtype_validation ' || x_error_code);

    x_error_code_temp := ctype_validation (p_cnv_bomres_rec.CHARGE_TYPE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  ctype_validation ' || x_error_code);

    x_error_code_temp := item_validation(p_cnv_bomres_rec.PURCHASE_ITEM,p_cnv_bomres_rec.ORG_CODE);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  item_validation ' || x_error_code);

    x_error_code_temp := acc_validation(p_cnv_bomres_rec.ABSORPTION_ACCOUNT	,'ABSORPTION Account');
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  acc_validation - ABSORPTION ' || x_error_code);

    x_error_code_temp := acc_validation(p_cnv_bomres_rec.RATE_VARIANCE_ACCOUNT 	,'RATE_VARIANCE Account');
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  acc_validation - RATE VARIANCE ' || x_error_code);

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
END data_validations_bomres;

END xx_inv_bomres_val_pkg;
/
