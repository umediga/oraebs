DROP PACKAGE BODY APPS.XX_AR_CUSTOMER_VAL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_CUSTOMER_VAL_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 14-May-2013
File Name     : XXARCUSTVAL.pkb
Description   : This script creates the specification of the package XX_AR_CUSTOMER_VAL_PKG
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
14-May-2013  ABhargava              Initial Draft.
05-SEP-2014  Sharath Babu           Modified as per Wave2 to add condition for party number
*/
----------------------------------------------------------------------

  

FUNCTION data_validations_cust (
         p_cnv_cust_rec   IN OUT xx_ar_customer_load_pkg.g_xx_ar_cust_rec_type
        )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate if Orig System is valid 
FUNCTION orig_system_validation (p_orig_system IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER;
BEGIN
    select count(1)
    into l_cnt
    from HZ_ORIG_SYSTEMS_B
    where upper(ORIG_SYSTEM) = upper(p_cnv_cust_rec.source_system_name);
    IF l_cnt >= 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Orig System '||p_orig_system||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Orig System  Invalid',
                          p_cnv_cust_rec.BATCH_ID,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_orig_system
                          );
        RETURN x_error_code;
    END IF;  
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Orig System Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_orig_system
                     );
   RETURN x_error_code;                         
END orig_system_validation;

-- Validate Account Number Values (if they already exist then send Error) 
FUNCTION acc_no_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from hz_cust_accounts_all
    where account_number = l_value;
    
    IF l_cnt = 0 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Already Exist with Account Number '||l_value);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Already Exist with Account Number ',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Account Number Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value
                     );
   RETURN x_error_code;        
END acc_no_validation;


-- Validate Party Number Values (if they already exist then send Error) 
FUNCTION party_no_validation (l_value IN VARCHAR2, l_bat_id in VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from xx_ar_cust_stg
    where party_number = l_value
    and batch_id = l_bat_id;
    
    IF l_cnt = 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'More than one Party exists with the Party Number '||l_value);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'More than one Party exists with the Party Number ',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Party Number Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value
                     );
   RETURN x_error_code;        
END party_no_validation;

-- Validate Orig System Ref Values (if they already exist then send Error) 
FUNCTION orig_ref_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from hz_cust_accounts_all
    where ORIG_SYSTEM_REFERENCE = l_value;
    
    IF l_cnt = 0 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Already Exist with ORIG_SYSTEM_REFERENCE '||l_value);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Already Exist with ORIG_SYSTEM_REFERENCE ',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Orig_Ref Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value
                     );
   RETURN x_error_code;        
END orig_ref_validation;


-- Validate Customer Name Values (if they already exist then send Error) 
FUNCTION cust_name_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from hz_cust_accounts_all
    where ACCOUNT_NAME = l_value;
    
    IF l_cnt = 0 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Already Exist with Name '||l_value);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Already Exist with Name ',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Name Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value
                     );
   RETURN x_error_code;        
END cust_name_validation;

-- Validate Customer Currency has value 
FUNCTION cust_curr_validation (l_value1 IN VARCHAR2,l_value2 IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    
    IF l_value1 IS NOT NULL AND l_value2 IS NOT NULL THEN 
        RETURN  x_error_code;
    ELSIF l_value1 IS NOT NULL AND l_value2 IS NULL THEN
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Currency is NULL');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Currency is NULL',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value1
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Currency Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value1
                     );
   RETURN x_error_code;        
END cust_curr_validation;
 


-- Validate Customer Name for Duplicate Values  in the staging table 
FUNCTION cust_dup_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from xx_ar_cust_stg
    where organization_name = l_value;
    
    IF l_cnt = 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'More than One Customer Exist with the Name '||l_value);
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'More than One Customer Exist with the Name ',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Duplicate Check Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value
                     );
   RETURN x_error_code;        
END cust_dup_validation;

-- Validate Customer Type  Values 
FUNCTION customer_type_validation (p_cust_type IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'CUSTOMER_TYPE'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_cust_type;
    
    IF l_cnt >= 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Type '||p_cust_type ||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Type  Invalid',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_cust_type
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Type Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_cust_type
                     );
   RETURN x_error_code;        
END customer_type_validation; 


-- Validate Customer STATUS  Values 
FUNCTION customer_status_validation (p_cust_status IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'CUSTOMER_STATUS'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_cust_status;
    
    IF l_cnt >= 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Status '||p_cust_status ||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Status Invalid',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_cust_status
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Status Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_cust_status
                     );
   RETURN x_error_code;        
END customer_status_validation;


-- Validate Customer Class  Values 
FUNCTION customer_class_validation (p_cust_class IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'CUSTOMER CLASS'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_cust_class;
    
    IF l_cnt >= 1 OR p_cust_class is NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Class '||p_cust_class ||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Class  Invalid',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_cust_class
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Class Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_cust_class
                     );
   RETURN x_error_code;        
END customer_class_validation;

-- Validate Customer Category Code Values 
FUNCTION customer_cat_validation (p_cust_cat IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'CUSTOMER CLASS'
    and language = 'US'
    and enabled_flag = 'Y'
    and UPPER(LOOKUP_CODE) = UPPER(p_cust_cat);
    
    IF l_cnt >= 1 OR p_cust_cat is NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Category '||p_cust_cat ||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Category Invalid',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_cust_cat
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Category Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_cust_cat
                     );
   RETURN x_error_code;        
END customer_cat_validation;

-- Validate Profile Class Values 
FUNCTION profile_class_validation (p_profile_class IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    SELECT count(1)
    into l_cnt
    FROM HZ_CUST_PROFILE_CLASSES
    WHERE UPPER (NAME) = UPPER(p_profile_class);
    
    IF l_cnt >= 1 OR p_profile_class is NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Profile Class '||p_profile_class||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Profile Class Invalid',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_profile_class
                          );
        RETURN x_error_code;
    END IF; 
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Profile Class Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_profile_class
                     );
   RETURN x_error_code;        
END profile_class_validation;    


-- Statement Cycle Values Validation  
FUNCTION send_statemt_validation (p_send_stmt IN VARCHAR2, p_cycle_nm IN VARCHAR )
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    IF p_send_stmt = 'N' THEN 
        
        RETURN  x_error_code;
        
    ELSIF p_send_stmt = 'Y' and p_cycle_nm is NULL THEN 
        
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Statement Cycle Name Can Not be NULL ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Statement Cycle Name Can Not be NULL ',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF
                          );
        RETURN x_error_code;
            
    ELSIF p_send_stmt = 'Y' and p_cycle_nm is NOT NULL THEN
        
        SELECT count(1)
        INTO l_cnt
        FROM ar_statement_cycles
        WHERE UPPER (NAME) = UPPER (p_cycle_nm);
        
        IF l_cnt >= 1 THEN 
            RETURN  x_error_code;
        ELSE
            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Statement Cycle Name '||p_cycle_nm|| 'Invalid ');
            x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Statement Cycle Name Invalid ',
                          p_cnv_cust_rec.batch_id,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_cycle_nm
                          );
            RETURN x_error_code;
        END IF;
            
    END IF;
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Statement Cycle Name Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_cycle_nm
                     );
   RETURN x_error_code;        
END send_statemt_validation;  
 

-- Validate if Payment  Terms is valid 
FUNCTION cust_pay_term_validation (p_pay_term IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from ra_terms
    where UPPER(NAME) = UPPER(p_pay_term);
    
    IF l_cnt >= 1 OR p_pay_term is NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer A/C Payment Term '||p_pay_term ||' is Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer A/C Payment Term  is Invalid',
                          p_cnv_cust_rec.BATCH_ID,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          p_pay_term
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer A/C Payment Terms Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     p_pay_term
                     );
   RETURN x_error_code;    
END cust_pay_term_validation;   
  

-- Validate if Collector Name is Valid 
FUNCTION cust_collector_validation (l_value IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    FROM AR_COLLECTORS
    WHERE UPPER (NAME) = UPPER(l_value);
    
    IF l_cnt >= 1 OR l_value is NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Collector Name '||l_value ||' is Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Collector Name  is Invalid',
                          p_cnv_cust_rec.BATCH_ID,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Collector Name Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value
                     );
   RETURN x_error_code;    
END cust_collector_validation;


-- Validate if Collector Name is Valid 
FUNCTION cust_grouping_validation (l_value IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    FROM RA_GROUPING_RULES
    WHERE UPPER (NAME) = UPPER(l_value);
    
    IF l_cnt >= 1 OR l_value is NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Customer Grouping Rule  '||l_value ||' is Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Customer Grouping Rule  is Invalid',
                          p_cnv_cust_rec.BATCH_ID,
                          p_cnv_cust_rec.record_number,
                          p_cnv_cust_rec.ORIG_SYSTEM_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Customer Grouping Rule Unhandled Exception',
                     p_cnv_cust_rec.BATCH_ID,
                     p_cnv_cust_rec.record_number,
                     p_cnv_cust_rec.ORIG_SYSTEM_REF,
                     l_value
                     );
   RETURN x_error_code;    
END cust_grouping_validation;

BEGIN
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting Customer Level Data-Validations');
    
    x_error_code_temp := orig_system_validation (p_cnv_cust_rec.SOURCE_SYSTEM_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  orig_system_validation ' || x_error_code);
    
    -- Commented on 19th June as per the request to Add 011 before Account Number if it already exist 
    --x_error_code_temp := acc_no_validation (p_cnv_cust_rec.ACCOUNT_NUMBER);
    --x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  acc_no_validation ' || x_error_code);
    IF p_cnv_cust_rec.party_number IS NOT NULL THEN  --Added as per Wave2
       x_error_code_temp := party_no_validation (p_cnv_cust_rec.PARTY_NUMBER,p_cnv_cust_rec.BATCH_ID);
       x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  party_no_validation ' || x_error_code);
    END IF;
    
    x_error_code_temp := orig_ref_validation (p_cnv_cust_rec.ORIG_SYSTEM_REF);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  orig_ref_validation ' || x_error_code);
    
    --x_error_code_temp := cust_name_validation (p_cnv_cust_rec.ORGANIZATION_NAME);
    --x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_name_validation ' || x_error_code);
    
    --x_error_code_temp := cust_dup_validation (p_cnv_cust_rec.ORGANIZATION_NAME);
    --x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_dup_validation ' || x_error_code);
    
    x_error_code_temp := cust_curr_validation (p_cnv_cust_rec.profile_class,p_cnv_cust_rec.currency_code);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  customer_type_validation ' || x_error_code);
    
    x_error_code_temp := customer_type_validation (p_cnv_cust_rec.customer_type);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  customer_type_validation ' || x_error_code);
    
    x_error_code_temp := customer_status_validation (p_cnv_cust_rec.customer_status);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  customer_status_validation ' || x_error_code);
    
    x_error_code_temp := customer_class_validation (p_cnv_cust_rec.customer_class);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  customer_class_validation ' || x_error_code);
    
    x_error_code_temp := customer_cat_validation (p_cnv_cust_rec.category_code);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  customer_cat_validation ' || x_error_code);
    
    x_error_code_temp := profile_class_validation (p_cnv_cust_rec.PROFILE_CLASS);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  profile_class_validation ' || x_error_code);
    
    x_error_code_temp := send_statemt_validation (nvl(p_cnv_cust_rec.SEND_STATEMENTS,'N'),p_cnv_cust_rec.STATEMENT_CYCLE_NAME);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  send_statemt_validation ' || x_error_code);
    
    x_error_code_temp := cust_pay_term_validation (p_cnv_cust_rec.payment_term);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_pay_term_validation ' || x_error_code);
    
    x_error_code_temp := cust_collector_validation (p_cnv_cust_rec.collector_name);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_collector_validation ' || x_error_code);
    
    x_error_code_temp := cust_grouping_validation (p_cnv_cust_rec.grouping_rule);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  cust_grouping_validation ' || x_error_code);
    
    
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Completed Customer Level Data-Validations');
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
END data_validations_cust; 


FUNCTION data_validations_address (
         p_cnv_addr_rec   IN OUT xx_ar_customer_load_pkg.g_xx_ar_address_rec_type
        )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate if Address Type is valid 
FUNCTION address_type_validation (p_addr_type IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'SITE_USE_CODE'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_addr_type;
    
    IF l_cnt >= 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Address Type '||p_addr_type||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Address Type  Invalid',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                          p_addr_type
                          );
        RETURN x_error_code;
    END IF; 
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Address Type Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                     p_addr_type
                     );
   RETURN x_error_code;         
END address_type_validation;  

-- Validate if Identifying FLAG is Unique for Sites 
FUNCTION ident_flag_validation 
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(distinct identifying_flag)
    into l_cnt
    from XX_AR_ADDRESS_STG
    WHERE ORIG_SYSTEM_REF = p_cnv_addr_rec.ORIG_SYSTEM_REF
    and orig_sys_addr_ref = p_cnv_addr_rec.ORIG_SYS_ADDR_REF;
    
    IF l_cnt = 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Same Site has Different Identifying FLAG');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Same Site has Different Identifying FLAG',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                          p_cnv_addr_rec.identifying_flag
                          );
        RETURN x_error_code;
    END IF; 
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Identifying FLAG UnHandled Exception ',
                      p_cnv_addr_rec.batch_id,
                      p_cnv_addr_rec.record_number,
                      p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                      p_cnv_addr_rec.identifying_flag
                     );
   RETURN x_error_code;         
END ident_flag_validation;  

-- Validate if Status Code is valid 
FUNCTION status_code_validation (p_status IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'CODE_STATUS'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_status;
    
    IF l_cnt >= 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Status Code '||p_status||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Status Code Invalid',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                          p_status
                          );
        RETURN x_error_code;
    END IF; 
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Status Code Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                     p_status
                     );
   RETURN x_error_code;         
END status_code_validation; 

-- Validate if Status Code and Primary Flag Combo is valid 
FUNCTION status_pr_validation (p_status IN VARCHAR2, p_primary_flag IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    IF p_status = 'I' AND p_primary_flag = 'Y' THEN 
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'An Inactive Site cannot be a Primary Site');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'An Inactive Site cannot be a Primary Site',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                          p_status||' - '||p_primary_flag
                          );
        RETURN x_error_code;
    ELSE
        RETURN x_error_code;     
    END IF; 
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'status_pr_validation Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                     p_status||' - '||p_primary_flag
                     );
   RETURN x_error_code;         
END status_pr_validation; 

-- Validate if Operating Unit is valid 
FUNCTION op_unit_validation (l_value IN VARCHAR2)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER;
BEGIN
    SELECT count(1)
    into l_cnt
    FROM hr_operating_units
    WHERE UPPER(NAME) = UPPER(l_value);
    
    IF l_cnt = 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Operating Unit '||l_value||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Operating Unit  Invalid',
                          p_cnv_addr_rec.BATCH_ID,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;  
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Operating Unit Validation Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                     l_value
                     );
   RETURN x_error_code;                         
END op_unit_validation;

-- Validate if Operating Unit is valid 
FUNCTION party_site_validation (l_value IN NUMBER)
    RETURN NUMBER
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER;
BEGIN
    SELECT count(1)
    into l_cnt
    FROM hz_party_sites
    WHERE party_site_number = l_value;
    
    IF l_cnt = 0 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Party Site Number '||l_value||' Already Exist');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Party Site Number Already Exist',
                          p_cnv_addr_rec.BATCH_ID,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                          l_value
                          );
        RETURN x_error_code;
    END IF;  
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Party Site Validation Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF||'-'||p_cnv_addr_rec.ORIG_SYS_ADDR_REF||'-'||p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF,
                     l_value
                     );
   RETURN x_error_code;                         
END party_site_validation;

-- Validate Address 1is NOT NULL 
FUNCTION null_validation (l_value IN VARCHAR2,l_field IN VARCHAR2 )
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    IF l_value is NOT NULL THEN  
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,l_field||' can not be  NULL ');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          l_field||' can not be  NULL ',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF,
                          p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||l_value
                          );
        RETURN x_error_code;
    END IF;    
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Unhandled Exception in NULL Validation for field '||l_field,
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF,
                     p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||l_value
                     );
   RETURN x_error_code;      
END null_validation;


-- Validate if Site USe Orig Ref Already exists in the system  
FUNCTION site_use_validation (l_code IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from hz_cust_site_uses_all
    where orig_system_reference = l_code;
    
    IF l_cnt = 0 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Site Use Orig Ref : '||l_code||' already exists !');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Site Use Orig Ref :already exists !',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF,
                          l_code
                          );
        RETURN x_error_code;
    END IF; 
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Site Use Validation Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF,
                     l_code
                     );
   RETURN x_error_code;         
END site_use_validation; 



-- Validate if Country Code is valid 
FUNCTION country_code_validation (p_Code IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    FROM fnd_territories_vl           
    where TERRITORY_CODE = p_Code;
    
    IF l_cnt >= 1 THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Country Code'||p_code||' Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Country Code Invalid',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF,
                          p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_code
                          );
        RETURN x_error_code;
    END IF;    
    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Country Code Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF,
                     p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_code
                     );
   RETURN x_error_code;      
END country_code_validation;

-- Validate if FOB Code is valid 
FUNCTION fob_code_validation (p_fob_code IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'FOB'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_fob_code;
    
    IF l_cnt >= 1 OR p_fob_code IS NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'FOB Code '||p_fob_code||' is Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'FOB Code is Invalid',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF,
                          p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_fob_code
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'FOB Code Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF,
                     p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_fob_code
                     );
   RETURN x_error_code;    
END fob_code_validation;

-- Validate if Ship Method is valid 
FUNCTION ship_method_validation (p_ship_method IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'SHIP_METHOD'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_ship_method;
    
    IF l_cnt >= 1 OR p_ship_method IS NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Ship Method '||p_ship_method||' is Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Ship Method  is Invalid',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF,
						  p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_ship_method
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Ship Method Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF,
                     p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_ship_method
                     );
   RETURN x_error_code;    
END ship_method_validation;

-- Validate if Freight Terms is valid 
FUNCTION freight_term_validation (p_freight_term IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'FREIGHT_TERMS'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_freight_term;
    
    IF l_cnt >= 1 OR p_freight_term is NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Freight Term Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Freight Term Invalid',
                          p_cnv_addr_rec.batch_id,
                          p_cnv_addr_rec.record_number,
                          p_cnv_addr_rec.ORIG_SYSTEM_REF,
                          p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_freight_term
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Freight Terms Unhandled Exception',
                     p_cnv_addr_rec.batch_id,
                     p_cnv_addr_rec.record_number,
                     p_cnv_addr_rec.ORIG_SYSTEM_REF,
                     p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF||'-'||p_freight_term
                     );
   RETURN x_error_code;    
END freight_term_validation;      

  
BEGIN
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting Address Level Data-Validations');
    
    x_error_code_temp := address_type_validation (p_cnv_addr_rec.address_type);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  address_type_validation ' || x_error_code);
    
    x_error_code_temp := ident_flag_validation;
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  ident_flag_validation ' || x_error_code);
    
    
    x_error_code_temp := op_unit_validation (p_cnv_addr_rec.SITE_USE_OPERATING_UNIT);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  op_unit_validation ' || x_error_code);
    
    -- Commented as per the request to add 011 to Party Site Number if it already exists 
    --x_error_code_temp := party_site_validation (p_cnv_addr_rec.PARTY_SITE_NUMBER);
    --x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  party_site_validation ' || x_error_code);

    x_error_code_temp := status_code_validation (p_cnv_addr_rec.site_use_status);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  status_code_validation ' || x_error_code);
    
    x_error_code_temp := status_pr_validation (p_cnv_addr_rec.site_use_status,p_cnv_addr_rec.primary_address);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  status_pr_validation ' || x_error_code);

    x_error_code_temp := site_use_validation (p_cnv_addr_rec.ORIG_SYS_SITE_USE_REF);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  site_use_validation ' || x_error_code);
    
    x_error_code_temp := null_validation (p_cnv_addr_rec.ADDRESS1, 'ADDRESS1');
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  null_validation - Address ' || x_error_code);
    
    IF p_cnv_addr_rec.country IN ('US','CA') 
    THEN
        x_error_code_temp := null_validation (p_cnv_addr_rec.CITY, 'CITY');
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  null_validation - City ' || x_error_code);
        
        x_error_code_temp := null_validation (p_cnv_addr_rec.POSTAL_CODE, 'POSTAL_CODE');
        x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  null_validation - POSTAL_CODE ' || x_error_code);
    END IF;
    
    x_error_code_temp := country_code_validation (p_cnv_addr_rec.country);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  country_code_validation ' || x_error_code);
    
    x_error_code_temp := fob_code_validation (p_cnv_addr_rec.fob_code);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  fob_code_validation ' || x_error_code);
    
    x_error_code_temp := ship_method_validation (p_cnv_addr_rec.ship_method);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  ship_method_validation ' || x_error_code);
    
    x_error_code_temp := freight_term_validation (p_cnv_addr_rec.SITE_FREIGHT_TERMS);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  freight_term_validation ' || x_error_code);
    
    
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Completed Address Level Data-Validations');
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
END data_validations_address;


FUNCTION data_validations_contact (
         p_cnv_cont_rec   IN OUT xx_ar_custcont_load_pkg.g_xx_ar_cust_cont_rec_type
        )
RETURN NUMBER
IS
  x_error_code        NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
  x_error_code_temp   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

-- Validate if Contact Type  is valid 
FUNCTION contact_type_validation (p_con_type IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'CONTACT_ROLE_TYPE'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = p_con_type;
    
    IF l_cnt >= 1  THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Contact Type '||p_con_type||' is Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Contact Type '||p_con_type||' is Invalid',
                          p_cnv_cont_rec.batch_id,
                          p_cnv_cont_rec.record_number,
                          p_cnv_cont_rec.ORIG_SYSTEM_REF||'-'||p_cnv_cont_rec.ORIG_SYS_CONTACT_REF
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Contact Type Unhandled Exception',
                     p_cnv_cont_rec.batch_id,
                     p_cnv_cont_rec.record_number,
                     p_cnv_cont_rec.ORIG_SYSTEM_REF||'-'||p_cnv_cont_rec.ORIG_SYS_CONTACT_REF
                     );
   RETURN x_error_code;    
END contact_type_validation;

-- Validate if Contact Pre Name is valid 
FUNCTION contact_pre_name_validation (l_value IN VARCHAR2)
    RETURN NUMBER    
IS
    x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
    l_cnt          NUMBER := 0;
BEGIN
    select count(1)
    into l_cnt
    from fnd_lookup_values
    where lookup_type = 'CONTACT_TITLE'
    and language = 'US'
    and enabled_flag = 'Y'
    and LOOKUP_CODE = l_value;
    
    IF l_cnt >= 1 OR l_value IS NULL THEN 
        RETURN  x_error_code;
    ELSE
        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Contact Pre Name '||l_value||' is Invalid');
        x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
        xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'Contact Pre Name '||l_value||' is Invalid',
                          p_cnv_cont_rec.batch_id,
                          p_cnv_cont_rec.record_number,
                          p_cnv_cont_rec.ORIG_SYSTEM_REF||'-'||p_cnv_cont_rec.ORIG_SYS_CONTACT_REF
                          );
        RETURN x_error_code;
    END IF;    
EXCEPTION
WHEN OTHERS THEN 
   x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
   xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                     xx_emf_cn_pkg.CN_STG_DATAVAL,
                     'Contact Pre Name Unhandled Exception',
                     p_cnv_cont_rec.batch_id,
                     p_cnv_cont_rec.record_number,
                     p_cnv_cont_rec.ORIG_SYSTEM_REF||'-'||p_cnv_cont_rec.ORIG_SYS_CONTACT_REF
                     );
   RETURN x_error_code;    
END contact_pre_name_validation;

BEGIN
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Starting Contact Level Data-Validations');
    
    x_error_code_temp := contact_type_validation (p_cnv_cont_rec.contact_type);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  contact_type_validation ' || x_error_code);
    
    x_error_code_temp := contact_pre_name_validation (p_cnv_cont_rec.pre_name);
    x_error_code      := xx_intg_common_pkg.find_max (x_error_code_temp, x_error_code);
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Error Code -  contact_pre_name_validation ' || x_error_code);
    
    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Completed Contact Level Data-Validations');
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
END DATA_VALIDATIONS_CONTACT;

END xx_ar_customer_val_pkg;
/
