DROP PACKAGE BODY APPS.XX_AR_CUST_RELATE_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_CUST_RELATE_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 12-June-2013
File Name     : XXARCUSTRELVAL.pkb
Description   : This script creates the package body of the package xx_ar_cust_relate_val_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
12-June-2013  ABhargava              Initial Draft.
*/
----------------------------------------------------------------------



FUNCTION data_validations_rel (
         p_cnv_cust_rel_rec   IN OUT xx_ar_cust_relate_pkg.g_xx_ar_cust_rel_rec_type
        )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate if A/C Number is valid
FUNCTION cust_validation (l_value IN VARCHAR2,l_api IN VARCHAR2, l_type IN VARCHAR)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    IF l_api = 'ACCOUNT' THEN
        select count(1)
        into l_cnt
        from hz_cust_accounts_all
        where orig_system_reference = l_value;
    ELSIF  l_api = 'PARTY' THEN
        select count(1)
        into l_cnt
        from hz_parties
        where orig_system_reference = l_value;
        IF l_cnt = 0 THEN
          select count(1)
          into l_cnt
          from hz_parties
          where ( orig_system_reference = 'O11_'||substr(l_value,5)||'011'
               OR orig_system_reference = 'O11_'||substr(l_value,5)||'012'
               OR orig_system_reference = substr(l_value,1,length(L_VALUE)-3));
        END IF;
    END IF;

    IF l_cnt >= 1 THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,l_type ||' - '||l_value||' does not exist ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          p_cnv_cust_rel_rec.api_type||' -- '||l_type||' Does Not Exist',
                          p_cnv_cust_rel_rec.record_number,
                          p_cnv_cust_rel_rec.id_number,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'cust_validation '||l_type||' Unhandled Exception',
                     p_cnv_cust_rel_rec.record_number,
                     p_cnv_cust_rel_rec.id_number,
                     l_value
                     );
   RETURN x_error_code;
END cust_validation;

-- Validate if Relationship Type is valid
FUNCTION relationship_type (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'HZ_RELATIONSHIP_TYPE'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = l_value;

    IF l_cnt >= 1 OR l_value IS NULL THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Relationship Type '||l_value||' is not valid ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Relationship Type is Invalid',
                          p_cnv_cust_rel_rec.record_number,
                          p_cnv_cust_rel_rec.id_number,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'relationship_type Unhandled Exception',
                     p_cnv_cust_rel_rec.record_number,
                     p_cnv_cust_rel_rec.id_number,
                     l_value
                     );
   RETURN x_error_code;
END relationship_type;

-- Validate if Relationship Code is valid
FUNCTION relationship_code (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'PARTY_RELATIONS_TYPE'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = l_value;

    IF l_cnt >= 1 OR l_value IS NULL THEN
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Relationship Code '||l_value||' is not valid ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Relationship Code is Invalid',
                          p_cnv_cust_rel_rec.record_number,
                          p_cnv_cust_rel_rec.id_number,
                          l_value
                          );
        RETURN x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'relationship_code Unhandled Exception',
                     p_cnv_cust_rel_rec.record_number,
                     p_cnv_cust_rel_rec.id_number,
                     l_value
                     );
   RETURN x_error_code;
END relationship_code;

-- Validate if Relationship already exists
FUNCTION relation_exist (l_value1 IN VARCHAR2,l_value2 IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(a.RELATED_CUST_ACCOUNT_ID)
    into l_cnt
    from hz_cust_acct_relate_all a
        , hz_cust_accounts_all b
        , hz_cust_accounts_all c
    where a.cust_account_id = b.cust_account_id
    and   a.RELATED_CUST_ACCOUNT_ID = c.cust_account_id
    and   b.orig_system_reference = l_value1
    and   c.orig_system_reference = l_value2
    and   a.status = 'A';

    IF l_cnt >= 1  THEN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Relation Already Exists between'||l_value1||' & '||l_value2);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Relation Already Exists between Customer Accounts',
                          p_cnv_cust_rel_rec.record_number,
                          p_cnv_cust_rel_rec.id_number,
                          l_value1||'-'||l_value2
                          );
        RETURN x_error_code;
    ELSE
        RETURN  x_error_code;
    END IF;
EXCEPTION
WHEN OTHERS THEN
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'relation_exist Unhandled Exception',
                     p_cnv_cust_rel_rec.record_number,
                     p_cnv_cust_rel_rec.id_number,
                     l_value1||'-'||l_value2
                     );
   RETURN x_error_code;
END relation_exist;

BEGIN
    IF p_cnv_cust_rel_rec.api_type = 'ACCOUNT' THEN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting Customer Level Data-Validations');

        x_error_code_temp := cust_validation (p_cnv_cust_rel_rec.id_number,p_cnv_cust_rel_rec.api_type,'ID_NUMBER');
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_validation - ID_NUMBER ' || x_error_code);

        x_error_code_temp := cust_validation (p_cnv_cust_rel_rec.RELATED_ID_NUMBER,p_cnv_cust_rel_rec.api_type,'RELATED_ID_NUMBER');
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_validation - RELATED_ID_NUMBER ' || x_error_code);

        x_error_code_temp := relation_exist (p_cnv_cust_rel_rec.id_number, p_cnv_cust_rel_rec.RELATED_ID_NUMBER);
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  relation_exist '|| x_error_code);


    ELSIF p_cnv_cust_rel_rec.api_type = 'PARTY' THEN

        x_error_code_temp := cust_validation (p_cnv_cust_rel_rec.id_number,p_cnv_cust_rel_rec.api_type,'ID_NUMBER');
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  party_validation - ID_NUMBER ' || x_error_code);

        x_error_code_temp := cust_validation (p_cnv_cust_rel_rec.RELATED_ID_NUMBER,p_cnv_cust_rel_rec.api_type,'RELATED_ID_NUMBER');
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  party_validation - RELATED_ID_NUMBER ' || x_error_code);

        x_error_code_temp := relationship_type (p_cnv_cust_rel_rec.relationship_type);
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  relationship_type ' || x_error_code);

        x_error_code_temp := relationship_code (p_cnv_cust_rel_rec.relationship_code);
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  relationship_code ' || x_error_code);


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
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code - '||SQLERRM);
    x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
    RETURN x_error_code;
END data_validations_rel;

END xx_ar_cust_relate_val_pkg;
/
