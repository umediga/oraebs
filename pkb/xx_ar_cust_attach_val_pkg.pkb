DROP PACKAGE BODY APPS.XX_AR_CUST_ATTACH_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_CUST_ATTACH_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 17-June-2013
File Name     : XXARCUSTATTVAL.pkb
Description   : This script creates the package body of the package xx_ar_cust_attach_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
12-June-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------



FUNCTION data_validations_att (
         p_cnv_cust_att_rec   IN OUT xx_ar_cust_attach_pkg.g_xx_ar_cust_att_rec_type
        )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate if A/C Number is valid
FUNCTION cust_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from hz_cust_accounts_all
    where orig_system_reference = l_value;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Account Number  - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Account Number Does Not Exist',
                          p_cnv_cust_att_rec.record_number,
                          p_cnv_cust_att_rec.account_number,
                          p_cnv_cust_att_rec.account_number
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'cust_validation  Unhandled Exception',
                     p_cnv_cust_att_rec.record_number,
                     p_cnv_cust_att_rec.account_number,
                     p_cnv_cust_att_rec.DATATYPE_NAME
                     );
   RETURN x_error_code;
END cust_validation;

-- Validate if Entityt Name is valid
FUNCTION entity_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN

    IF l_value = 'AR_CUSTOMERS' THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Entity Name should be AR_CUSTOMERS ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Entity Name should be AR_CUSTOMERS ',
                          p_cnv_cust_att_rec.record_number,
                          p_cnv_cust_att_rec.account_number,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'entity_validation  Unhandled Exception',
                     p_cnv_cust_att_rec.record_number,
                     p_cnv_cust_att_rec.account_number,
                     l_value
                     );
   RETURN x_error_code;
END entity_validation;

-- Validate if Entityt Name is valid
FUNCTION security_type (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN

    IF l_value is NOT NULL  THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Security Type can not be null ! ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Security Type can not be null ! ',
                          p_cnv_cust_att_rec.record_number,
                          p_cnv_cust_att_rec.account_number,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'security_type  Unhandled Exception',
                     p_cnv_cust_att_rec.record_number,
                     p_cnv_cust_att_rec.account_number,
                     l_value
                     );
   RETURN x_error_code;
END security_type;

-- Validate if Datatype Name is Valid
FUNCTION datatype_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from FND_DOCUMENT_DATATYPES
    where upper(NAME) = upper(l_value)
    and language = 'US';

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Data Type Name  - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Data Type Name is Invalid ',
                          p_cnv_cust_att_rec.record_number,
                          p_cnv_cust_att_rec.account_number,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'datatype_validation  Unhandled Exception',
                     p_cnv_cust_att_rec.record_number,
                     p_cnv_cust_att_rec.account_number,
                     l_value
                     );
   RETURN x_error_code;
END datatype_validation;

-- Validate if Category Name is Valid
FUNCTION category_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from FND_DOCUMENT_CATEGORIES
    where upper(NAME) = upper(l_value);

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Category Name  - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Category Name is Invalid ',
                          p_cnv_cust_att_rec.record_number,
                          p_cnv_cust_att_rec.account_number,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'category_validation  Unhandled Exception',
                     p_cnv_cust_att_rec.record_number,
                     p_cnv_cust_att_rec.account_number,
                     l_value
                     );
   RETURN x_error_code;
END category_validation;


BEGIN

    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting Customer Level Data-Validations');

    x_error_code_temp := cust_validation (p_cnv_cust_att_rec.ACCOUNT_NUMBER);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_validation ' || x_error_code);

    x_error_code_temp := entity_validation (p_cnv_cust_att_rec.ENTITY_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  entity_validation ' || x_error_code);

    x_error_code_temp := security_type (p_cnv_cust_att_rec.security_type);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  security_type ' || x_error_code);

    x_error_code_temp := datatype_validation (p_cnv_cust_att_rec.DATATYPE_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  datatype_validation ' || x_error_code);

    x_error_code_temp := category_validation(p_cnv_cust_att_rec.CATEGORY_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  category_validation ' || x_error_code);


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

END xx_ar_cust_attach_val_pkg;
/
