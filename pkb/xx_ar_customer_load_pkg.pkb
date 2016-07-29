DROP PACKAGE BODY APPS.XX_AR_CUSTOMER_LOAD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_CUSTOMER_LOAD_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 14-May-2013
 File Name      : XXARCUSTLOAD.pkb
 Description    : This script creates the body of the package XX_AR_CUSTOMER_LOAD_PKG
----------------------------*------------------------------------------------------------------
----------------------------*------------------------------------------------------------------
COMMON GUIDELINES REGARDING EMF
-------------------------------
1. All low level emf messages can be retained
2. Hard coding of emf messages are allowed in the code
3. Any other hard coding should be dealt by constants package
4. Exception handling should be left as is most of the places unless specified
 
Change History:
---------------------------------------------------------------------------------------------
Date            Name          Remarks
---------------------------------------------------------------------------------------------
14-May-2013     ABhargava    Initial development.
19-Jun-2013     ABhargava    Changes to Append 011 to A/C Number and Party Number
05-SEP-2014     Sharath Babu Modified to add new field as per account_estd_date
---------------------------------------------------------------------------------------------
*/

-- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
-- START RESTRICTIONS

-------------------------------------------------------------------------------------
------------< Procedure for setting Environment >------------
-------------------------------------------------------------------------------------

PROCEDURE set_cnv_env (
  p_batch_id        VARCHAR2,
  p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
)
IS
  x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
BEGIN
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Start of set_cnv_env');
  g_batch_id := p_batch_id;
  
  -- Set the environment
  x_error_code := xx_emf_pkg.set_env;

  IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
  THEN
     xx_emf_pkg.propagate_error (x_error_code);
  END IF;
  
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'End of set_cnv_env');
  
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                           ' Error Message in  EMF :' || SQLERRM
                          );
     RAISE xx_emf_pkg.g_e_env_not_set;
END set_cnv_env;   


-------------------------------------------------------------------------------------
------------< Procedure for Marking Records >------------
-------------------------------------------------------------------------------------
PROCEDURE mark_records_for_processing (p_batch_id     IN   VARCHAR2
                                     , p_restart_flag IN   VARCHAR2)

IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,  'Start of mark_records_for_processing');
    UPDATE XX_AR_CUST_STG 
    set REQUEST_ID = xx_emf_pkg.G_REQUEST_ID
       --,ERROR_CODE = xx_emf_cn_pkg.CN_NULL
       ,PHASE_CODE = xx_emf_cn_pkg.CN_NEW
    WHERE batch_id = p_batch_id  
    AND   ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR ) 
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));
          
    UPDATE XX_AR_ADDRESS_STG 
    set REQUEST_ID = xx_emf_pkg.G_REQUEST_ID
       --,ERROR_CODE = xx_emf_cn_pkg.cn_null
       ,PHASE_CODE = xx_emf_cn_pkg.CN_NEW
    WHERE batch_id = p_batch_id  
    AND   ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR ) 
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));                     

    COMMIT;
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark_records_for_processing');
END;      


--------------------------------------------------------------------------------
------------< Set Stage >------------
--------------------------------------------------------------------------------
PROCEDURE set_stage (p_stage VARCHAR2)
IS
BEGIN
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Start of set_stage:');
  g_stage := p_stage;
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'End of set_stage:');
END set_stage;

--------------------------------------------------------------------------------
------------< Update Count >------------
--------------------------------------------------------------------------------
PROCEDURE update_cnt (p_mode in VARCHAR)
IS
l_suc    NUMBER := 0;
l_err    NUMBER := 0;
l_tot    NUMBER := 0;

l_tot_cnt_cust NUMBER := 0;
l_tot_cnt_addr NUMBER := 0;

l_suc_cust NUMBER := 0;
l_err_cust NUMBER := 0;

l_suc_addr NUMBER := 0;
l_err_addr NUMBER := 0;

BEGIN
    IF p_mode = 'VALIDATE_ONLY' THEN 
    
        select count(1)
        into l_tot_cnt_cust
        from xx_ar_cust_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID;
        
        select count(1)
        into l_tot_cnt_addr
        from xx_ar_address_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID;
        
        select count(1)
        into  l_suc_cust
        from  xx_ar_cust_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID
        and   error_code = '0';
        
        select count(1)
        into  l_suc_addr
        from  xx_ar_address_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID
        and   error_code = '0';

        select count(1)
        into  l_err_cust
        from  xx_ar_cust_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID
        and   error_code = '2';
        
        select count(1)
        into  l_err_addr
        from  xx_ar_address_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID
        and   error_code = '2';
        
        l_tot := l_tot_cnt_cust + l_tot_cnt_addr;
        l_suc := l_suc_cust + l_suc_addr;
        l_err := l_err_cust + l_err_addr;
        
        xx_emf_pkg.update_recs_cnt
        (
            p_total_recs_cnt   => l_tot,
            p_success_recs_cnt => l_suc,
            p_warning_recs_cnt => 0,
            p_error_recs_cnt   => l_err
        );
    ELSE
        select count(1)
        into l_tot
        from xx_ar_cust_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID;
        
        select count(1)
        into  l_suc
        from  xx_ar_cust_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID
        and   error_code = '0';
        
        select count(1)
        into  l_err
        from  xx_ar_cust_stg
        where batch_id   =  g_batch_id 
        and   request_id =  xx_emf_pkg.G_REQUEST_ID
        and   error_code = '2';
        
        xx_emf_pkg.update_recs_cnt
        (
            p_total_recs_cnt   => l_tot,
            p_success_recs_cnt => l_suc,
            p_warning_recs_cnt => 0,
            p_error_recs_cnt   => l_err
        );
    
    END IF;    
        
EXCEPTION 
WHEN OTHERS THEN 
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_cnt '||SQLERRM);
END;

--------------------------------------------------------------------------------
------------< Update Customer Table Status >------------
--------------------------------------------------------------------------------
PROCEDURE update_cust_record_status ( p_conv_cust_rec  IN OUT  g_xx_ar_cust_rec_type,
                                      p_error_code     IN      VARCHAR2
                                    ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_cust_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_conv_cust_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_conv_cust_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_cust_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;
    
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_cust_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_cust_record_status '||SQLERRM);
END update_cust_record_status;

--------------------------------------------------------------------------------
------------< Update Address Table Status >------------
--------------------------------------------------------------------------------
PROCEDURE update_address_record_status ( p_conv_addr_rec  IN OUT  g_xx_ar_address_rec_type,
                                         p_error_code     IN      VARCHAR2
                                       ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_address_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_conv_addr_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_conv_addr_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_addr_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;
    
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_address_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_address_record_status '||SQLERRM);
END update_address_record_status;

--------------------------------------------------------------------------------
------------< Mark Customer Records Complete >------------
--------------------------------------------------------------------------------
PROCEDURE mark_cust_rec_complete (p_process_code   IN   VARCHAR2,
                                  p_conv_cust_rec  IN   g_xx_ar_cust_rec_type
                                 ) IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;

    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of mark_cust_rec_complete');
    
    update xx_ar_cust_stg
    set phase_code        = G_STAGE
       ,ERROR_CODE        = p_conv_cust_rec.error_code
       ,last_updated_by   = x_last_updated_by
       ,last_update_date  = x_last_update_date
    WHERE batch_id      = G_BATCH_ID
    AND request_id      = xx_emf_pkg.G_REQUEST_ID
    AND orig_system_ref = p_conv_cust_rec.orig_system_ref;   
    
    COMMIT;        
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of mark_cust_rec_complete');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_records_complete '||SQLERRM);
END mark_cust_rec_complete;    

--------------------------------------------------------------------------------
------------< Mark Address Records Complete >------------
--------------------------------------------------------------------------------
PROCEDURE mark_address_rec_complete (p_process_code   IN   VARCHAR2,
                                     p_conv_addr_rec  IN   g_xx_ar_address_rec_type
                                     ) IS 
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;

    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of mark_address_rec_complete - '||p_conv_addr_rec.ORIG_SYS_SITE_USE_REF);
    
    update xx_ar_address_stg
    set phase_code        = G_STAGE
       ,ERROR_CODE        = p_conv_addr_rec.error_code
       ,last_updated_by   = x_last_updated_by
       ,last_update_date  = x_last_update_date
    WHERE batch_id            = G_BATCH_ID
    AND request_id            = xx_emf_pkg.G_REQUEST_ID
    AND orig_system_ref       = p_conv_addr_rec.orig_system_ref
    AND ORIG_SYS_ADDR_REF     = p_conv_addr_rec.ORIG_SYS_ADDR_REF
    AND ORIG_SYS_SITE_USE_REF = p_conv_addr_rec.ORIG_SYS_SITE_USE_REF;   
    
    COMMIT;        
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of mark_address_rec_complete');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_address_rec_complete '||SQLERRM);
END mark_address_rec_complete;

--------------------------------------------------------------------------------
------------< Update Customer Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_cust_hdr_cnv_stg (
                                  p_stage_rec   IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                                 )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
  PRAGMA AUTONOMOUS_TRANSACTION; 
BEGIN
    g_api_name := 'update_cust_hdr_cnv_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    UPDATE xxconv.xx_ar_cust_stg
     SET batch_id           = p_stage_rec.batch_id
       , orig_system_ref    = p_stage_rec.orig_system_ref
       , person_flag        = p_stage_rec.person_flag
       , SOURCE_SYSTEM_NAME = p_stage_rec.SOURCE_SYSTEM_NAME
       , customer_id        = p_stage_rec.customer_id
       , customer_type      = p_stage_rec.customer_type
       , party_type         = p_stage_rec.party_type
       , customer_first_name= p_stage_rec.customer_first_name
       , customer_last_name = p_stage_rec.customer_last_name
       , customer_title     = p_stage_rec.customer_title
       , customer_status    = p_stage_rec.customer_status
       , dob                = p_stage_rec.dob
       , gender             = p_stage_rec.gender
       , nationality        = p_stage_rec.nationality
       , customer_name      = p_stage_rec.customer_name
       , organization_name  = p_stage_rec.organization_name
       , LANGUAGE           = p_stage_rec.LANGUAGE
       , category_code      = p_stage_rec.category_code
       , customer_class     = p_stage_rec.customer_class
       , payment_term       = p_stage_rec.payment_term
       , payment_term_id    = p_stage_rec.payment_term_id
       , org_id             = p_stage_rec.org_id
       , cust_account_id    = p_stage_rec.cust_account_id
       , account_number     = p_stage_rec.account_number
       , party_id           = p_stage_rec.party_id
       , party_number       = p_stage_rec.party_number
       , profile_class      = p_stage_rec.profile_class
       , profile_class_id   = p_stage_rec.profile_class_id
       , profile            = p_stage_rec.profile
       , profile_id         = p_stage_rec.profile_id
       , send_statements    = p_stage_rec.send_statements
       , statement_cycle_id = p_stage_rec.statement_cycle_id
       , statement_cycle_name = p_stage_rec.statement_cycle_name
       , attribute_category = p_stage_rec.attribute_category
       , attribute1         = p_stage_rec.attribute1
       , attribute2         = p_stage_rec.attribute2
       , attribute3         = p_stage_rec.attribute3
       , attribute4         = p_stage_rec.attribute4
       , attribute5         = p_stage_rec.attribute5
       , attribute6         = p_stage_rec.attribute6
       , attribute7         = p_stage_rec.attribute7
       , attribute8         = p_stage_rec.attribute8
       , attribute9         = p_stage_rec.attribute9
       , attribute10        = p_stage_rec.attribute10
       , overall_credit_limit = p_stage_rec.overall_credit_limit
       , currency_code      = p_stage_rec.currency_code
       , credit_checking    = p_stage_rec.credit_checking
       , collector_id       = p_stage_rec.collector_id
       , collector_name     = p_stage_rec.collector_name
       , discount_terms     = p_stage_rec.discount_terms
       , auto_rec_incl_disputed_flag = p_stage_rec.auto_rec_incl_disputed_flag
       , grouping_rule      = p_stage_rec.grouping_rule
       , grouping_rule_id   = p_stage_rec.grouping_rule_id
       , tolerance          = p_stage_rec.tolerance
       , account_estd_date  = p_stage_rec.account_estd_date  --Added as per Wave2
       , request_id         = xx_emf_pkg.G_REQUEST_ID
       , LAST_UPDATED_BY    = x_last_updated_by
       , LAST_UPDATE_DATE   = x_last_update_date
       , phase_code         = p_stage_rec.phase_code
       , error_code         = p_stage_rec.error_code
       , error_msg          = p_stage_rec.error_msg 
   WHERE orig_system_ref    = p_stage_rec.orig_system_ref
   AND batch_id             = p_batch_id;
   
  
         
   IF p_stage_rec.error_code = xx_emf_cn_pkg.CN_REC_ERR THEN
      UPDATE xx_ar_address_stg 
      set error_code =  p_stage_rec.error_code  
         ,phase_code =  p_stage_rec.phase_code
      where  orig_system_ref = p_stage_rec.orig_system_ref
      and nvl(error_code,'1') <> p_stage_rec.error_code;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Updating Address for '||p_stage_rec.orig_system_ref||' Error Code '||p_stage_rec.error_code );
   END IF;      

   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
   COMMIT;
   RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_cust_hdr_cnv_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_cust_hdr_cnv_stg;


--------------------------------------------------------------------------------
------------< Update Address Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_cust_addr_cnv_stg (
                                  p_stage_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                                 )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
  PRAGMA AUTONOMOUS_TRANSACTION; 
BEGIN
    g_api_name := 'update_cust_addr_cnv_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    UPDATE xxconv.xx_ar_address_stg
       SET batch_id = p_stage_rec.batch_id
         , orig_system_ref          = p_stage_rec.orig_system_ref
         , ORIG_SYS_ADDR_REF        = p_stage_rec.ORIG_SYS_ADDR_REF
         , SOURCE_SYSTEM_NAME       = p_stage_rec.SOURCE_SYSTEM_NAME
         , address_id               = p_stage_rec.address_id
         , address1                 = p_stage_rec.address1
         , address2                 = p_stage_rec.address2
         , address3                 = p_stage_rec.address3
         , address4                 = p_stage_rec.address4
         , city                     = p_stage_rec.city
         , state                    = p_stage_rec.state
         , postal_code              = p_stage_rec.postal_code
         , county                   = p_stage_rec.county
         , province                 = p_stage_rec.province
         , country                  = p_stage_rec.country
         , country_code             = p_stage_rec.country_code
         , address_style            = p_stage_rec.address_style
         , site_use_operating_unit  = p_stage_rec.site_use_operating_unit
         , org_id                   = p_stage_rec.org_id
         , global_location_number   = p_stage_rec.global_location_number
         , party_site_id            = p_stage_rec.party_site_id
         , party_site_number        = p_stage_rec.party_site_number
         , party_number             = p_stage_rec.party_number
         , cust_acct_site_id        = p_stage_rec.cust_acct_site_id            
         , attribute_category       = p_stage_rec.attribute_category
         , attribute1               = p_stage_rec.attribute1
         , attribute2               = p_stage_rec.attribute2
         , attribute3               = p_stage_rec.attribute3
         , attribute4               = p_stage_rec.attribute4
         , attribute5               = p_stage_rec.attribute5
         , attribute6               = p_stage_rec.attribute6
         , attribute7               = p_stage_rec.attribute7
         , attribute8               = p_stage_rec.attribute8
         , attribute9               = p_stage_rec.attribute9
         , attribute10              = p_stage_rec.attribute10
         , attribute11              = p_stage_rec.attribute11
         , request_id               = xx_emf_pkg.G_REQUEST_ID
         , LAST_UPDATED_BY          = x_last_updated_by
         , LAST_UPDATE_DATE         = x_last_update_date
         , phase_code               = p_stage_rec.phase_code
         , error_code               = p_stage_rec.error_code
         , error_msg                = p_stage_rec.error_msg 
   WHERE orig_system_ref        = p_stage_rec.orig_system_ref
   AND   orig_sys_addr_ref      = p_stage_rec.orig_sys_addr_ref
   AND batch_id                 = p_batch_id;
  
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
   COMMIT;
   RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_cust_addr_cnv_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_cust_addr_cnv_stg;


--------------------------------------------------------------------------------
------------< Update Address Staging Site Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_cust_site_cnv_stg (
                                  p_stage_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                                 )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
  PRAGMA AUTONOMOUS_TRANSACTION; 
BEGIN
    g_api_name := 'update_cust_site_cnv_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    UPDATE xxconv.xx_ar_address_stg
       SET batch_id = p_stage_rec.batch_id
         , orig_system_ref          = p_stage_rec.orig_system_ref
         , ORIG_SYS_ADDR_REF        = p_stage_rec.ORIG_SYS_ADDR_REF
         , ORIG_SYS_SITE_USE_REF    = p_stage_rec.ORIG_SYS_SITE_USE_REF
         , SOURCE_SYSTEM_NAME       = p_stage_rec.SOURCE_SYSTEM_NAME
         , address_id               = p_stage_rec.address_id
         , primary_address          = p_stage_rec.primary_address
         , identifying_flag         = p_stage_rec.identifying_flag
         , address_type             = p_stage_rec.address_type
         , LOCATION                 = p_stage_rec.LOCATION
         , address1                 = p_stage_rec.address1
         , address2                 = p_stage_rec.address2
         , address3                 = p_stage_rec.address3
         , address4                 = p_stage_rec.address4
         , city                     = p_stage_rec.city
         , state                    = p_stage_rec.state
         , postal_code              = p_stage_rec.postal_code
         , county                   = p_stage_rec.county
         , province                 = p_stage_rec.province
         , country                  = p_stage_rec.country
         , country_code             = p_stage_rec.country_code
         , address_style            = p_stage_rec.address_style
         , site_use_operating_unit  = p_stage_rec.site_use_operating_unit
         , org_id                   = p_stage_rec.org_id
         , global_location_number   = p_stage_rec.global_location_number
         , party_site_id            = p_stage_rec.party_site_id
         , party_site_number        = p_stage_rec.party_site_number
         , party_number             = p_stage_rec.party_number
         , cust_acct_site_id        = p_stage_rec.cust_acct_site_id            
         , site_use_id              = p_stage_rec.site_use_id  
         , attribute_category       = p_stage_rec.attribute_category
         , attribute1               = p_stage_rec.attribute1
         , attribute2               = p_stage_rec.attribute2
         , attribute3               = p_stage_rec.attribute3
         , attribute4               = p_stage_rec.attribute4
         , attribute5               = p_stage_rec.attribute5
         , attribute6               = p_stage_rec.attribute6
         , attribute7               = p_stage_rec.attribute7
         , attribute8               = p_stage_rec.attribute8
         , attribute9               = p_stage_rec.attribute9
         , attribute10              = p_stage_rec.attribute10
         , attribute11              = p_stage_rec.attribute11
         , org_comp_code            = p_stage_rec.org_comp_code  
         , site_freight_terms       = p_stage_rec.site_freight_terms
         , ship_method              = p_stage_rec.ship_method
         , fob_code                 = p_stage_rec.fob_code
         , site_use_attribute_category  = p_stage_rec.site_use_attribute_category
         , site_use_attribute1      = p_stage_rec.site_use_attribute1
         , site_use_attribute2      = p_stage_rec.site_use_attribute2  
         , site_use_attribute3      = p_stage_rec.site_use_attribute3
         , site_use_attribute4      = p_stage_rec.site_use_attribute4
         , site_use_attribute5      = p_stage_rec.site_use_attribute5
         , site_use_attribute6      = p_stage_rec.site_use_attribute6
         , site_use_attribute7      = p_stage_rec.site_use_attribute7
         , site_use_attribute8      = p_stage_rec.site_use_attribute8
         , site_use_attribute9      = p_stage_rec.site_use_attribute9
         , site_use_attribute10     = p_stage_rec.site_use_attribute10
         , site_use_attribute19     = p_stage_rec.site_use_attribute19
         , request_id               = xx_emf_pkg.G_REQUEST_ID
         , LAST_UPDATED_BY          = x_last_updated_by
         , LAST_UPDATE_DATE         = x_last_update_date
         , phase_code               = p_stage_rec.phase_code
         , error_code               = p_stage_rec.error_code
         , error_msg                = p_stage_rec.error_msg 
   WHERE orig_system_ref        = p_stage_rec.orig_system_ref
   AND   orig_sys_addr_ref      = p_stage_rec.orig_sys_addr_ref
   AND   orig_sys_site_use_ref  = p_stage_rec.orig_sys_site_use_ref
   AND batch_id                 = p_batch_id;
  
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
   xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
   COMMIT;
   RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_cust_addr_cnv_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_cust_site_cnv_stg;

-------------------------------------------------------------------------------------
---------------------------------- Customer Derivation ------------------------------
-------------------------------------------------------------------------------------
FUNCTION customer_derivations (p_cust_rec   IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
  l_value               VARCHAR2 (100);
  l_profile_class       VARCHAR2 (100);
  l_cat_code            VARCHAR2 (100);
  l_cnt                 NUMBER := 0;
  l_cnt_p               NUMBER := 0;
  l_cnt_a               NUMBER := 0;
BEGIN
    g_api_name := 'customer_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    -- Added on 19th June by ABHARGAVA as per the request to Add 011 in case A/C Number or Party Number already exists 
    BEGIN
        select count(1)
        into l_cnt_a
        from hz_cust_accounts_all
        where account_number = p_cust_rec.account_number;
        
        IF l_cnt_a >=1 THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'A/C Number already exists ! Appending 011');
            p_cust_rec.account_number := p_cust_rec.account_number||'011';
        END IF;    
    
    EXCEPTION
        WHEN OTHERS THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unable to Append 011 To A/C Number');
            l_msg := 'Unable to Append 011 To A/C Number';
            RAISE l_error_transaction;
    END;
    
    BEGIN
        select count(1)
        into l_cnt_p
        from hz_parties
        where PARTY_NUMBER = p_cust_rec.party_number;
        
        IF l_cnt_p >=1 THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Party Number already exists ! Appending 011');
            p_cust_rec.party_number := p_cust_rec.party_number||'011';
        END IF;    
    
    EXCEPTION
        WHEN OTHERS THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unable to Append 011 To Party Number');
            l_msg := 'Unable to Append 011 To Party Number';
            RAISE l_error_transaction;
    END;
    -- End of Modification on 19th June
    
    IF p_cust_rec.PROFILE_CLASS IS NOT NULL THEN
        BEGIN
            SELECT profile_class_id
            INTO p_cust_rec.profile_class_id
            FROM HZ_CUST_PROFILE_CLASSES
            WHERE UPPER (NAME) = UPPER(p_cust_rec.PROFILE_CLASS);
        EXCEPTION
        WHEN OTHERS THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unable to derive Profile Class ID');
            l_msg := 'Unable to derive Profile Class ID';
            RAISE l_error_transaction;
        END;
    ELSE
        p_cust_rec.profile_class_id := NULL;
    END IF;    
    
    
    IF p_cust_rec.COLLECTOR_NAME IS NOT NULL THEN 
        BEGIN
            SELECT COLLECTOR_ID
            INTO p_cust_rec.collector_id
            FROM AR_COLLECTORS
            WHERE UPPER (NAME) = UPPER(p_cust_rec.COLLECTOR_NAME);
        EXCEPTION
        WHEN OTHERS THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unable to derive Collector ID');
            l_msg := 'Unable to derive Collector ID';
            RAISE l_error_transaction;
        END;
    ELSE
        p_cust_rec.collector_id := NULL;
    END IF;
    
    IF p_cust_rec.PAYMENT_TERM IS NOT NULL THEN 
    BEGIN
        SELECT TERM_ID
        INTO p_cust_rec.payment_term_id
        FROM RA_TERMS
        WHERE UPPER (NAME) = UPPER(p_cust_rec.PAYMENT_TERM);
    EXCEPTION
    WHEN OTHERS THEN 
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unable to derive Payment Term ID');
        l_msg := 'Unable to derive Payment Term ID';
        RAISE l_error_transaction;
    END;
    ELSE
        p_cust_rec.payment_term_id := NULL;
    END IF;    
    
    IF p_cust_rec.GROUPING_RULE IS NOT NULL THEN 
    BEGIN
        SELECT grouping_rule_id
        INTO p_cust_rec.grouping_rule_id
        FROM ra_grouping_rules
        WHERE UPPER (NAME) = UPPER(p_cust_rec.GROUPING_RULE);
    EXCEPTION
    WHEN OTHERS THEN 
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unable to derive Grouping Rule ID');
        l_msg := 'Unable to derive Grouping Rule ID';
        RAISE l_error_transaction;
    END;
    ELSE
        p_cust_rec.grouping_rule_id := NULL;
    END IF;
    
    
    IF NVL (p_cust_rec.send_statements, 'N') = 'Y'
      THEN
         IF  p_cust_rec.statement_cycle_name IS NULL THEN 
             l_msg := 'Statement Cycle Name Not Provided ';
               RAISE l_error_transaction;              
         ELSE         
             BEGIN
                SELECT statement_cycle_id
                  INTO p_cust_rec.statement_cycle_id
                  FROM ar_statement_cycles
                 WHERE UPPER (NAME) = UPPER (p_cust_rec.statement_cycle_name)
                   AND p_cust_rec.statement_cycle_name IS NOT NULL;
             EXCEPTION
                WHEN OTHERS
                THEN
                   l_msg := 'Unable to derive statement cycle id for: '|| p_cust_rec.statement_cycle_name;
                   RAISE l_error_transaction;
             END;
         END IF;
    ELSE
        p_cust_rec.statement_cycle_id := NULL;         
    END IF;
    
    
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    RETURN TRUE;
EXCEPTION
  WHEN l_error_transaction
  THEN
     p_cust_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_cust_rec.error_msg   := g_api_name || ': ' || l_msg;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg,
                       p_cust_rec.batch_id,
                       p_cust_rec.record_number,
                       p_cust_rec.ORIG_SYSTEM_REF
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Customer_Derivations Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_cust_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_cust_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_cust_rec.batch_id,
                       p_cust_rec.record_number,
                       p_cust_rec.ORIG_SYSTEM_REF
                      );
     RETURN FALSE;
END customer_derivations; 


-------------------------------------------------------------------------------------
---------------------------------- Address Derivation ------------------------------
-------------------------------------------------------------------------------------
FUNCTION address_derivations (p_addr_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                            , p_cust_rec   IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
  l_value               VARCHAR2 (100);
  l_cnt                 NUMBER := 0;
BEGIN
    g_api_name := 'address_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    -- Added on 19th June by ABHARGAVA as per the request to add 011 if party site number already exists 
    BEGIN 
        SELECT count(1)
        into l_cnt
        FROM hz_party_sites
        WHERE party_site_number = p_addr_rec.party_site_number;
        
        IF l_cnt >= 1 THEN 
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Appending 011 to Party Site Number');
             p_addr_rec.party_site_number :=  p_addr_rec.party_site_number||'011';
        END IF;     
    EXCEPTION
    WHEN OTHERS
    THEN
       l_msg := 'Error Appending 011 to Party Site Number ' || SQLERRM;
       RAISE l_error_transaction;
    END;
    
       
    BEGIN  
        SELECT territory_code, address_style
        INTO p_addr_rec.country_code,p_addr_rec.address_style 
        FROM fnd_territories_vl
       where TERRITORY_CODE = UPPER(p_addr_rec.country);
    EXCEPTION
    WHEN OTHERS
    THEN
       l_msg := 'Error derving country code ' || SQLERRM;
       RAISE l_error_transaction;
    END;
    
    BEGIN  
        SELECT ORGANIZATION_ID
        INTO p_addr_rec.org_id
        FROM hr_operating_units
        WHERE UPPER(NAME) = UPPER(p_addr_rec.site_use_operating_unit);
    EXCEPTION
    WHEN OTHERS
    THEN
       l_msg := 'Error derving Org ID ' || SQLERRM;
       RAISE l_error_transaction;
    END;
    

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    RETURN TRUE;
EXCEPTION
  WHEN l_error_transaction
  THEN
     p_addr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_addr_rec.error_msg   := g_api_name || ': ' || l_msg;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg,
                       p_addr_rec.batch_id,
                       p_addr_rec.record_number,
                       p_addr_rec.ORIG_SYSTEM_REF||' - '||p_addr_rec.ORIG_SYS_ADDR_REF||' - '||p_addr_rec.ORIG_SYS_SITE_USE_REF
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'address_derivations Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_addr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_addr_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_addr_rec.batch_id,
                       p_addr_rec.record_number,
                       p_addr_rec.ORIG_SYSTEM_REF||' - '||p_addr_rec.ORIG_SYS_ADDR_REF||' - '||p_addr_rec.ORIG_SYS_SITE_USE_REF
                      );
     RETURN FALSE;
END address_derivations;    

-------------------------------------------------------------------------------------
   ------------------- Initialise Location Type Parameteres --------------
------------------------------------------------------------------------------------- 

FUNCTION init_location (
                        x_location_rec            IN OUT NOCOPY   hz_location_v2pub.location_rec_type
                      , p_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                       )
RETURN BOOLEAN
IS
    l_otc_cust_hdr_cnv_rec   xxconv.xx_ar_cust_stg%ROWTYPE;
BEGIN
    g_api_name := 'init_location';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    x_location_rec.orig_system_reference := p_otc_cust_addr_cnv_rec.orig_sys_addr_ref;
    x_location_rec.orig_system           := p_otc_cust_addr_cnv_rec.source_system_name;
    x_location_rec.country               := p_otc_cust_addr_cnv_rec.country_code;
    x_location_rec.address1              := p_otc_cust_addr_cnv_rec.address1;
    x_location_rec.address2              := p_otc_cust_addr_cnv_rec.address2;
    x_location_rec.address3              := p_otc_cust_addr_cnv_rec.address3;
    x_location_rec.address4              := p_otc_cust_addr_cnv_rec.address4;
    x_location_rec.city                  := p_otc_cust_addr_cnv_rec.city;
    x_location_rec.postal_code           := p_otc_cust_addr_cnv_rec.postal_code;
    x_location_rec.state                 := p_otc_cust_addr_cnv_rec.state;
    x_location_rec.province              := p_otc_cust_addr_cnv_rec.province;
    x_location_rec.county                := p_otc_cust_addr_cnv_rec.county;
    x_location_rec.address_style         := p_otc_cust_addr_cnv_rec.address_style;
    x_location_rec.created_by_module     := g_created_by_module;
  
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     p_otc_cust_addr_cnv_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_otc_cust_addr_cnv_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_otc_cust_addr_cnv_rec.batch_id,
                       p_otc_cust_addr_cnv_rec.record_number,
                       p_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||p_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_location;


-------------------------------------------------------------------------------------
   ------------------- Create  Location -----------------
------------------------------------------------------------------------------------- 
FUNCTION create_location (
                          p_location_rec            IN OUT NOCOPY   hz_location_v2pub.location_rec_type
                        , x_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                         )
RETURN BOOLEAN
IS
  lx_return_status   VARCHAR2 (1);
  lx_msg_count       NUMBER;
  lx_msg_data        VARCHAR2 (2000);
  l_location_rec     hz_location_v2pub.location_rec_type;
  lx_location_id     NUMBER;
BEGIN
    g_api_name := 'create_location';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    l_location_rec := p_location_rec;
  /* =======================================================================
     Purpose : This API take the Location info'n from the staging
   table as input, and outputs the unique id's (location_id)
   and pushes the whole   data into r12 hz tables.
   ========================================================================*/
    hz_location_v2pub.create_location (p_init_msg_list      => fnd_api.g_true
                                     , p_location_rec       => l_location_rec
                                     , x_location_id        => lx_location_id
                                     , x_return_status      => lx_return_status
                                     , x_msg_count          => lx_msg_count
                                     , x_msg_data           => lx_msg_data
                                       );
                                       
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status  :' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_location_id    :' || lx_location_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_otc_cust_addr_cnv_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_otc_cust_addr_cnv_rec.error_msg,
                           x_otc_cust_addr_cnv_rec.batch_id,
                           x_otc_cust_addr_cnv_rec.record_number,
                           x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                          );
         RETURN FALSE;
      END IF;

    x_otc_cust_addr_cnv_rec.address_id := lx_location_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
      x_otc_cust_addr_cnv_rec.error_msg := g_api_name||' '||' Unhandled Exception:  ' || SQLERRM;
      xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_otc_cust_addr_cnv_rec.error_msg,
                           x_otc_cust_addr_cnv_rec.batch_id,
                           x_otc_cust_addr_cnv_rec.record_number,
                           x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                          );
     RETURN FALSE;
END create_location;

-------------------------------------------------------------------------------------
   ------------------- Initialise Party Site Record Type  -----------------
------------------------------------------------------------------------------------- 

FUNCTION init_party_site (
                          x_party_site_rec          IN OUT NOCOPY   hz_party_site_v2pub.party_site_rec_type
                        , p_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                        , p_otc_cust_hdr_cnv_rec    IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                        )
RETURN BOOLEAN
IS
BEGIN
    g_api_name := 'init_party_site';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    x_party_site_rec.party_id                 := p_otc_cust_hdr_cnv_rec.party_id;
    x_party_site_rec.location_id              := p_otc_cust_addr_cnv_rec.address_id;
    x_party_site_rec.identifying_address_flag := p_otc_cust_addr_cnv_rec.identifying_flag;
    x_party_site_rec.created_by_module        := g_created_by_module;
    x_party_site_rec.global_location_number   := p_otc_cust_addr_cnv_rec.global_location_number;
    x_party_site_rec.party_site_number        := p_otc_cust_addr_cnv_rec.party_site_number;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Identifying Flag :'||x_party_site_rec.identifying_address_flag);
  
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     p_otc_cust_addr_cnv_rec.error_msg := g_api_name||' '||' Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       p_otc_cust_addr_cnv_rec.error_msg,
                       p_otc_cust_addr_cnv_rec.batch_id,
                       p_otc_cust_addr_cnv_rec.record_number,
                       p_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||p_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_party_site;


-------------------------------------------------------------------------------------
   ------------------- Create Party Site  -----------------
-------------------------------------------------------------------------------------
FUNCTION create_party_site (
                           p_party_site_rec          IN OUT NOCOPY   hz_party_site_v2pub.party_site_rec_type
                         , x_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                           )
RETURN BOOLEAN
IS
  lx_return_status       VARCHAR2 (1);
  lx_msg_count           NUMBER;
  lx_msg_data            VARCHAR2 (2000);
  l_party_site_rec       hz_party_site_v2pub.party_site_rec_type;
  lx_party_site_id       NUMBER;
  lx_party_site_number   VARCHAR2 (2000);
BEGIN
    g_api_name := 'create_party_site';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_party_site_rec    := p_party_site_rec;
  /* =======================================================================
     Purpose : This API take the Party Site info'n from the staging
   table as input, and outputs the party_site_id, party_site_number
   and pushes the whole data into r12 hz tables.
   ========================================================================*/
    hz_party_site_v2pub.create_party_site
                            (p_init_msg_list          => fnd_api.g_true
                           , p_party_site_rec         => l_party_site_rec
                           , x_party_site_id          => lx_party_site_id
                           , x_party_site_number      => lx_party_site_number
                           , x_return_status          => lx_return_status
                           , x_msg_count              => lx_msg_count
                           , x_msg_data               => lx_msg_data
                            );
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status     :' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_site_id     :' || lx_party_site_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_site_number :' || lx_party_site_number);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_otc_cust_addr_cnv_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_otc_cust_addr_cnv_rec.error_msg,
                           x_otc_cust_addr_cnv_rec.batch_id,
                           x_otc_cust_addr_cnv_rec.record_number,
                           x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                          );
         RETURN FALSE;
      END IF;

    x_otc_cust_addr_cnv_rec.party_site_id     := lx_party_site_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     x_otc_cust_addr_cnv_rec.error_msg := g_api_name||' '||'Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       x_otc_cust_addr_cnv_rec.error_msg,
                       x_otc_cust_addr_cnv_rec.batch_id,
                       x_otc_cust_addr_cnv_rec.record_number,
                       x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END create_party_site;

-------------------------------------------------------------------------------------
   ------------------- Initialise Cust Acct Site Record Type  -----------------
------------------------------------------------------------------------------------- 

FUNCTION init_cust_acct_site (
                              x_cust_acct_site_rec      IN OUT NOCOPY   hz_cust_account_site_v2pub.cust_acct_site_rec_type
                            , p_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                            , p_otc_cust_hdr_cnv_rec    IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                            )
RETURN BOOLEAN
IS
     l_name VARCHAR2(100);
BEGIN
    g_api_name := 'init_cust_acct_site';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    x_cust_acct_site_rec.cust_account_id          := p_otc_cust_hdr_cnv_rec.cust_account_id;
    x_cust_acct_site_rec.party_site_id            := p_otc_cust_addr_cnv_rec.party_site_id;
    x_cust_acct_site_rec.org_id                   := p_otc_cust_addr_cnv_rec.org_id;
    x_cust_acct_site_rec.orig_system_reference    := p_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF;                             
    x_cust_acct_site_rec.attribute_category       := p_otc_cust_addr_cnv_rec.attribute_category;
    x_cust_acct_site_rec.attribute1               := p_otc_cust_addr_cnv_rec.attribute1;
    x_cust_acct_site_rec.attribute2               := p_otc_cust_addr_cnv_rec.attribute2;
    x_cust_acct_site_rec.attribute3               := p_otc_cust_addr_cnv_rec.attribute3;
    x_cust_acct_site_rec.attribute4               := p_otc_cust_addr_cnv_rec.attribute4;
    x_cust_acct_site_rec.attribute5               := p_otc_cust_addr_cnv_rec.attribute5;
    x_cust_acct_site_rec.attribute6               := p_otc_cust_addr_cnv_rec.attribute6;
    x_cust_acct_site_rec.attribute7               := p_otc_cust_addr_cnv_rec.attribute7;
    x_cust_acct_site_rec.attribute8               := p_otc_cust_addr_cnv_rec.attribute8;
    x_cust_acct_site_rec.attribute9               := p_otc_cust_addr_cnv_rec.attribute9;
    x_cust_acct_site_rec.attribute10              := p_otc_cust_addr_cnv_rec.attribute10;
    x_cust_acct_site_rec.attribute11              := p_otc_cust_addr_cnv_rec.attribute11;   
    x_cust_acct_site_rec.created_by_module        := g_created_by_module;
      
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     p_otc_cust_addr_cnv_rec.error_msg := g_api_name||' '||'Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       p_otc_cust_addr_cnv_rec.error_msg,
                       p_otc_cust_addr_cnv_rec.batch_id,
                       p_otc_cust_addr_cnv_rec.record_number,
                       p_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||p_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_cust_acct_site;

-------------------------------------------------------------------------------------
   ------------------- Create Cust Acct Site  -----------------
-------------------------------------------------------------------------------------

FUNCTION create_cust_acct_site (
                                p_cust_acct_site_rec      IN OUT NOCOPY   hz_cust_account_site_v2pub.cust_acct_site_rec_type
                              , x_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                               )
RETURN BOOLEAN
IS
  lx_return_status       VARCHAR2 (1);
  lx_msg_count           NUMBER;
  lx_msg_data            VARCHAR2 (2000);
  l_cust_acct_site_rec   hz_cust_account_site_v2pub.cust_acct_site_rec_type;
  lx_cust_acct_site_id   NUMBER;
BEGIN
    g_api_name := 'create_cust_acct_site';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_cust_acct_site_rec := p_cust_acct_site_rec;
  /* =======================================================================
     Purpose : This API take the Party Site info'n from the staging
   table as input, and outputs the party_site_id, party_site_number
   and pushes the whole data into r12 hz tables.
   ========================================================================*/
    hz_cust_account_site_v2pub.create_cust_acct_site
                           (p_init_msg_list           => fnd_api.g_true
                          , p_cust_acct_site_rec      => l_cust_acct_site_rec
                          , x_cust_acct_site_id       => lx_cust_acct_site_id
                          , x_return_status           => lx_return_status
                          , x_msg_count               => lx_msg_count
                          , x_msg_data                => lx_msg_data
                           );
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status  :' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_cust_acct_site_id   :' || lx_cust_acct_site_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_otc_cust_addr_cnv_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_otc_cust_addr_cnv_rec.error_msg,
                           x_otc_cust_addr_cnv_rec.batch_id,
                           x_otc_cust_addr_cnv_rec.record_number,
                           x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                          );

         RETURN FALSE;
      END IF;

    x_otc_cust_addr_cnv_rec.cust_acct_site_id := lx_cust_acct_site_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     x_otc_cust_addr_cnv_rec.error_msg := g_api_name||' '||'Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       x_otc_cust_addr_cnv_rec.error_msg,
                       x_otc_cust_addr_cnv_rec.batch_id,
                       x_otc_cust_addr_cnv_rec.record_number,
                       x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END create_cust_acct_site;

-------------------------------------------------------------------------------------
   ------------------- Initialise Cust Site Use Record Type  -----------------
------------------------------------------------------------------------------------- 

FUNCTION init_cust_site_use (
                              x_cust_site_use_rec       IN OUT NOCOPY   hz_cust_account_site_v2pub.cust_site_use_rec_type
                            , x_customer_profile_rec    IN OUT NOCOPY   hz_customer_profile_v2pub.customer_profile_rec_type
                            , p_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                            , p_otc_cust_hdr_cnv_rec    IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                            )
RETURN BOOLEAN
IS
  lx_return_status         VARCHAR2 (1);
  lx_msg_count             NUMBER;
  lx_msg_data              VARCHAR2 (2000);
  l_cust_site_use_rec      hz_cust_account_site_v2pub.cust_site_use_rec_type;
  l_customer_profile_rec   hz_customer_profile_v2pub.customer_profile_rec_type;
  lx_site_use_id           NUMBER;
BEGIN
    g_api_name := 'init_cust_site_use ';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Status :'||p_otc_cust_addr_cnv_rec.site_use_status);
    
    x_cust_site_use_rec.cust_acct_site_id :=  p_otc_cust_addr_cnv_rec.cust_acct_site_id;
    x_cust_site_use_rec.site_use_code     :=  p_otc_cust_addr_cnv_rec.address_type;
    x_cust_site_use_rec.primary_flag      :=  p_otc_cust_addr_cnv_rec.primary_address;
    x_cust_site_use_rec.status            :=  p_otc_cust_addr_cnv_rec.site_use_status;    
    x_cust_site_use_rec.freight_term      :=  p_otc_cust_addr_cnv_rec.SITE_FREIGHT_TERMS;
    x_cust_site_use_rec.ship_via          :=  p_otc_cust_addr_cnv_rec.SHIP_METHOD;
    x_cust_site_use_rec.fob_point         :=  p_otc_cust_addr_cnv_rec.FOB_CODE;
    x_cust_site_use_rec.payment_term_id   :=  NULL;
    x_cust_site_use_rec.orig_system_reference := p_otc_cust_addr_cnv_rec.ORIG_SYS_SITE_USE_REF;
    
    x_cust_site_use_rec.attribute_category:=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE_CATEGORY;
    x_cust_site_use_rec.attribute1        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE1;
    x_cust_site_use_rec.attribute2        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE2;
    x_cust_site_use_rec.attribute3        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE3;
    x_cust_site_use_rec.attribute4        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE4;
    x_cust_site_use_rec.attribute5        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE5;
    x_cust_site_use_rec.attribute6        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE6;
    x_cust_site_use_rec.attribute7        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE7;
    x_cust_site_use_rec.attribute8        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE8;
    --x_cust_site_use_rec.attribute9        :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE9;
    x_cust_site_use_rec.attribute10       :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE10;
    x_cust_site_use_rec.attribute19       :=  p_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE19;
    
    x_cust_site_use_rec.created_by_module :=  g_created_by_module;
      
    x_customer_profile_rec.profile_class_id := NULL;
    
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     p_otc_cust_addr_cnv_rec.error_msg := g_api_name||' '||'Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       p_otc_cust_addr_cnv_rec.error_msg,
                       p_otc_cust_addr_cnv_rec.batch_id,
                       p_otc_cust_addr_cnv_rec.record_number,
                       p_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||p_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_cust_site_use;


-------------------------------------------------------------------------------------
   ------------------- Create Cust Site Use -----------------
-------------------------------------------------------------------------------------
FUNCTION create_cust_site_use (
                               p_cust_site_use_rec       IN OUT NOCOPY   hz_cust_account_site_v2pub.cust_site_use_rec_type
                             , p_customer_profile_rec    IN OUT NOCOPY   hz_customer_profile_v2pub.customer_profile_rec_type
                             , x_otc_cust_addr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                             , p_otc_cust_hdr_cnv_rec    IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                              )
RETURN BOOLEAN
IS
  lx_return_status         VARCHAR2 (1);
  lx_msg_count             NUMBER;
  lx_msg_data              VARCHAR2 (2000);
  l_cust_site_use_rec      hz_cust_account_site_v2pub.cust_site_use_rec_type;
  l_customer_profile_rec   hz_customer_profile_v2pub.customer_profile_rec_type;
  lx_site_use_id           NUMBER;
  l_cust_acct_relate_rec   hz_cust_account_v2pub.cust_acct_relate_rec_type;
  l_cnt                    NUMBER :=0;
  l_related_to             NUMBER ;
BEGIN
    g_api_name := 'create_cust_site_use';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_cust_site_use_rec               := p_cust_site_use_rec;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Status :'||l_cust_site_use_rec.status);                                             
    l_cust_site_use_rec.site_use_code := x_otc_cust_addr_cnv_rec.ADDRESS_TYPE;
    l_customer_profile_rec            := p_customer_profile_rec;
      /* =======================================================================
         Purpose : This API take the Customer Site use info'n
        from the staging table as input, and outputs the site_use_id
        and pushes the whole data into r12 hz tables.
       ========================================================================*/
      hz_cust_account_site_v2pub.create_cust_site_use
                           (p_init_msg_list             => fnd_api.g_true
                          , p_cust_site_use_rec         => l_cust_site_use_rec
                          , p_customer_profile_rec      => l_customer_profile_rec
                          , p_create_profile            => fnd_api.g_false--fnd_api.g_true
                          , p_create_profile_amt        => fnd_api.g_false
                          , x_site_use_id               => lx_site_use_id
                          , x_return_status             => lx_return_status
                          , x_msg_count                 => lx_msg_count
                          , x_msg_data                  => lx_msg_data
                           );
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status  :' || lx_return_status);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_site_use_id   :' || lx_site_use_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_otc_cust_addr_cnv_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_otc_cust_addr_cnv_rec.error_msg,
                           x_otc_cust_addr_cnv_rec.batch_id,
                           x_otc_cust_addr_cnv_rec.record_number,
                           x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                          );
         RETURN FALSE;
      END IF;

    x_otc_cust_addr_cnv_rec.site_use_id := lx_site_use_id;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     x_otc_cust_addr_cnv_rec.error_msg := g_api_name||' '||'Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       x_otc_cust_addr_cnv_rec.error_msg,
                       x_otc_cust_addr_cnv_rec.batch_id,
                       x_otc_cust_addr_cnv_rec.record_number,
                       x_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF||' - '||x_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END create_cust_site_use;
-------------------------------------------------------------------------------------
   ------------------- Create Customer Profile --------------
-------------------------------------------------------------------------------------  
FUNCTION create_customer_profile (p_otc_cust_hdr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE)
  RETURN BOOLEAN
IS
    lx_return_status              VARCHAR2 (1);
    lx_msg_count                  NUMBER;
    lx_msg_data                   VARCHAR2 (2000);
    l_customer_profile_rec        hz_customer_profile_v2pub.customer_profile_rec_type;
    l_cust_profile_amt_rec        hz_customer_profile_v2pub.cust_profile_amt_rec_type;
    lx_cust_account_profile_id    NUMBER;
    lx_cust_acct_profile_amt_id   NUMBER;
    l_version_number              VARCHAR2 (5);
BEGIN
    g_api_name := 'create_customer_profile';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_cust_profile_amt_rec.overall_credit_limit    := p_otc_cust_hdr_cnv_rec.overall_credit_limit;
    l_cust_profile_amt_rec.currency_code           := p_otc_cust_hdr_cnv_rec.currency_code;
    l_cust_profile_amt_rec.cust_account_profile_id := p_otc_cust_hdr_cnv_rec.profile_id;
    l_cust_profile_amt_rec.cust_account_id         := p_otc_cust_hdr_cnv_rec.cust_account_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Call API- create_customer_profile_amt');
    hz_customer_profile_v2pub.create_cust_profile_amt
              (p_init_msg_list                 => fnd_api.g_true
             , p_check_foreign_key             => fnd_api.g_true
             , p_cust_profile_amt_rec          => l_cust_profile_amt_rec
             , x_cust_acct_profile_amt_id      => lx_cust_acct_profile_amt_id
             , x_return_status                 => lx_return_status
             , x_msg_count                     => lx_msg_count
             , x_msg_data                      => lx_msg_data
              );
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'lx_return_status  :' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'lx_cust_acct_profile_amt_id :' || lx_cust_acct_profile_amt_id);

    IF lx_return_status != 'S'
    THEN
       IF NVL (lx_msg_count, 0) > 0
       THEN
          p_otc_cust_hdr_cnv_rec.error_msg :=
             g_api_name || ': '
             || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);
         FOR i IN 1 .. lx_msg_count
          LOOP
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Error:  ' || fnd_msg_pub.get (i, 'F'));
          END LOOP;
       END IF;
         
          xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                            xx_emf_cn_pkg.CN_STG_DATADRV,
                            p_otc_cust_hdr_cnv_rec.error_msg,
                            p_otc_cust_hdr_cnv_rec.batch_id,
                            p_otc_cust_hdr_cnv_rec.record_number,
                            p_otc_cust_hdr_cnv_rec.ORIG_SYSTEM_REF
                           );
      RETURN FALSE;
    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                            xx_emf_cn_pkg.CN_STG_DATADRV,
                            g_api_name||' - '||'Unhandled Exception:  ' || SQLERRM,
                            p_otc_cust_hdr_cnv_rec.batch_id,
                            p_otc_cust_hdr_cnv_rec.record_number,
                            p_otc_cust_hdr_cnv_rec.ORIG_SYSTEM_REF
                           );
     RETURN FALSE;
END create_customer_profile;


-------------------------------------------------------------------------------------
   ------------------- Initialise Account Type Parameteres --------------
-------------------------------------------------------------------------------------  
FUNCTION init_account_org_type (
                                p_otc_cust_hdr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                              , x_cust_account_rec       IN OUT NOCOPY   hz_cust_account_v2pub.cust_account_rec_type
                              , x_organization_rec       IN OUT NOCOPY   hz_party_v2pub.organization_rec_type
                              , x_person_rec             IN OUT NOCOPY   hz_party_v2pub.person_rec_type
                              , x_customer_profile_rec   IN OUT NOCOPY   hz_customer_profile_v2pub.customer_profile_rec_type
                                )
  RETURN BOOLEAN
IS
  l_otc_cust_hdr_cnv_rec   xxconv.xx_ar_cust_stg%ROWTYPE;
  l_term_id                NUMBER;
  l_term                   VARCHAR2(100);
BEGIN
    
    g_api_name := 'init_account_org_type';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_otc_cust_hdr_cnv_rec := p_otc_cust_hdr_cnv_rec;
    
    x_cust_account_rec.account_name          := l_otc_cust_hdr_cnv_rec.organization_name;
    x_cust_account_rec.created_by_module     := g_created_by_module;
    x_cust_account_rec.customer_class_code   := UPPER(l_otc_cust_hdr_cnv_rec.category_code);
    x_cust_account_rec.customer_type         := l_otc_cust_hdr_cnv_rec.customer_type;
    x_cust_account_rec.orig_system_reference := l_otc_cust_hdr_cnv_rec.orig_system_ref;                            
    x_cust_account_rec.orig_system           := l_otc_cust_hdr_cnv_rec.source_system_name;
    x_cust_account_rec.status                := l_otc_cust_hdr_cnv_rec.customer_status;
    x_cust_account_rec.account_number        := l_otc_cust_hdr_cnv_rec.account_number;                      
    x_cust_account_rec.attribute_category    := l_otc_cust_hdr_cnv_rec.attribute_category;
    x_cust_account_rec.attribute1            := l_otc_cust_hdr_cnv_rec.attribute1;
    x_cust_account_rec.attribute2            := l_otc_cust_hdr_cnv_rec.attribute2;
    x_cust_account_rec.attribute3            := l_otc_cust_hdr_cnv_rec.attribute3;
    x_cust_account_rec.attribute4            := l_otc_cust_hdr_cnv_rec.attribute4;
    x_cust_account_rec.attribute5            := l_otc_cust_hdr_cnv_rec.attribute5;
    x_cust_account_rec.attribute6            := l_otc_cust_hdr_cnv_rec.attribute6;
    x_cust_account_rec.attribute7            := l_otc_cust_hdr_cnv_rec.attribute7;
    x_cust_account_rec.attribute8            := l_otc_cust_hdr_cnv_rec.attribute8;
    --x_cust_account_rec.attribute9            := l_otc_cust_hdr_cnv_rec.attribute9;
    x_cust_account_rec.attribute10           := l_otc_cust_hdr_cnv_rec.attribute10;
    x_cust_account_rec.account_established_date := l_otc_cust_hdr_cnv_rec.account_estd_date;  --Added as per Wave2
    
    IF l_otc_cust_hdr_cnv_rec.PARTY_TYPE = 'ORGANIZATION' THEN  
        x_organization_rec.party_rec.party_number   := l_otc_cust_hdr_cnv_rec.party_number;
        IF l_otc_cust_hdr_cnv_rec.party_number like '%011' THEN 
           x_organization_rec.party_rec.orig_system_reference   := 'O11_'||substr(l_otc_cust_hdr_cnv_rec.party_number,1,length(l_otc_cust_hdr_cnv_rec.party_number)-3);
        ELSE
           x_organization_rec.party_rec.orig_system_reference   := 'O11_'||l_otc_cust_hdr_cnv_rec.party_number;
        END IF;   
        x_organization_rec.organization_name        := l_otc_cust_hdr_cnv_rec.organization_name;
        x_organization_rec.known_as                 := l_otc_cust_hdr_cnv_rec.customer_name;
    ELSIF  l_otc_cust_hdr_cnv_rec.PARTY_TYPE = 'PERSON' THEN     
        x_person_rec.person_first_name              := l_otc_cust_hdr_cnv_rec.customer_first_name;
        x_person_rec.person_last_name               := l_otc_cust_hdr_cnv_rec.customer_last_name;
        x_person_rec.person_title                   := l_otc_cust_hdr_cnv_rec.customer_title;
        x_person_rec.known_as                       := l_otc_cust_hdr_cnv_rec.customer_name;
        x_person_rec.date_of_birth                  := l_otc_cust_hdr_cnv_rec.dob;
        x_person_rec.gender                         := l_otc_cust_hdr_cnv_rec.gender;
        x_person_rec.party_rec.party_number         := l_otc_cust_hdr_cnv_rec.party_number;
        IF l_otc_cust_hdr_cnv_rec.party_number like '%011' THEN 
           x_person_rec.party_rec.orig_system_reference   := 'O11_'||substr(l_otc_cust_hdr_cnv_rec.party_number,1,length(l_otc_cust_hdr_cnv_rec.party_number)-3);
        ELSE
           x_person_rec.party_rec.orig_system_reference   := 'O11_'||l_otc_cust_hdr_cnv_rec.party_number;
        END IF; 
        
    END IF; 
  
    x_customer_profile_rec.created_by_module := g_created_by_module;
    x_customer_profile_rec.credit_checking   := l_otc_cust_hdr_cnv_rec.credit_checking;                              
    x_customer_profile_rec.profile_class_id  := l_otc_cust_hdr_cnv_rec.profile_class_id;
    x_customer_profile_rec.grouping_rule_id  := l_otc_cust_hdr_cnv_rec.grouping_rule_id;
    x_customer_profile_rec.collector_id      := l_otc_cust_hdr_cnv_rec.collector_id;
    x_customer_profile_rec.tolerance         := l_otc_cust_hdr_cnv_rec.tolerance;
    x_customer_profile_rec.standard_terms    := l_otc_cust_hdr_cnv_rec.payment_term_id;      
    x_customer_profile_rec.discount_terms    := l_otc_cust_hdr_cnv_rec.discount_terms;  
    x_customer_profile_rec.send_statements   := l_otc_cust_hdr_cnv_rec.send_statements;                                                      
    x_customer_profile_rec.statement_cycle_id:= l_otc_cust_hdr_cnv_rec.statement_cycle_id;
    x_customer_profile_rec.auto_rec_incl_disputed_flag := l_otc_cust_hdr_cnv_rec.auto_rec_incl_disputed_flag;
    
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     p_otc_cust_hdr_cnv_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_otc_cust_hdr_cnv_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       l_otc_cust_hdr_cnv_rec.batch_id,
                       l_otc_cust_hdr_cnv_rec.record_number,
                       l_otc_cust_hdr_cnv_rec.ORIG_SYSTEM_REF
                      );
     RETURN FALSE;
END init_account_org_type;

-------------------------------------------------------------------------------------
   ------------------- Create Account Type -----------------
------------------------------------------------------------------------------------- 

FUNCTION create_account_org_type (
                                  p_cust_account_rec       IN OUT NOCOPY   hz_cust_account_v2pub.cust_account_rec_type
                                , p_organization_rec       IN OUT NOCOPY   hz_party_v2pub.organization_rec_type
                                , p_person_rec             IN OUT NOCOPY   hz_party_v2pub.person_rec_type
                                , p_customer_profile_rec   IN OUT NOCOPY   hz_customer_profile_v2pub.customer_profile_rec_type
                                , p_otc_cust_hdr_cnv_rec   IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                                )
  RETURN BOOLEAN
IS
  lx_return_status         VARCHAR2 (1);
  lx_msg_count             NUMBER;
  lx_msg_data              VARCHAR2 (2000);
  l_cust_account_rec       hz_cust_account_v2pub.cust_account_rec_type;
  l_organization_rec       hz_party_v2pub.organization_rec_type;
  l_person_rec             hz_party_v2pub.person_rec_type; 
  l_customer_profile_rec   hz_customer_profile_v2pub.customer_profile_rec_type;
  l_otc_cust_hdr_cnv_rec   xxconv.xx_ar_cust_stg%ROWTYPE;
  lx_cust_account_id       NUMBER;
  lx_account_number        VARCHAR2 (2000);
  lx_party_id              NUMBER;
  lx_party_number          VARCHAR2 (2000);
  lx_profile_id            NUMBER;
BEGIN
    g_api_name := 'create_account_org_type';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_cust_account_rec      := p_cust_account_rec;
    l_organization_rec      := p_organization_rec;
    l_person_rec            := p_person_rec;
    l_customer_profile_rec  := p_customer_profile_rec;
    l_otc_cust_hdr_cnv_rec  := p_otc_cust_hdr_cnv_rec;
    
 
 /* =======================================================================
     Purpose : This API take the customer information from the staging
    table as input, and outputs the unique id's (party_id,cust_account_id,
     account_number) and pushes the whole   data into r12 hz tables.
   ========================================================================*/
    IF l_otc_cust_hdr_cnv_rec.PARTY_TYPE = 'ORGANIZATION' THEN
    hz_cust_account_v2pub.create_cust_account
                       (p_init_msg_list             => fnd_api.g_true
                      , p_cust_account_rec          => l_cust_account_rec
                      , p_organization_rec          => l_organization_rec
                      , p_customer_profile_rec      => l_customer_profile_rec
                      , p_create_profile_amt        => fnd_api.g_false
                      , x_cust_account_id           => lx_cust_account_id
                      , x_account_number            => lx_account_number
                      , x_party_id                  => lx_party_id
                      , x_party_number              => lx_party_number
                      , x_profile_id                => lx_profile_id
                      , x_return_status             => lx_return_status
                      , x_msg_count                 => lx_msg_count
                      , x_msg_data                  => lx_msg_data
                       );
    ELSIF l_otc_cust_hdr_cnv_rec.PARTY_TYPE = 'PERSON' THEN
    hz_cust_account_v2pub.create_cust_account
                       (p_init_msg_list             => fnd_api.g_true
                      , p_cust_account_rec          => l_cust_account_rec
                      , p_person_rec                => l_person_rec
                      , p_customer_profile_rec      => l_customer_profile_rec
                      , p_create_profile_amt        => fnd_api.g_false
                      , x_cust_account_id           => lx_cust_account_id
                      , x_account_number            => lx_account_number
                      , x_party_id                  => lx_party_id
                      , x_party_number              => lx_party_number
                      , x_profile_id                => lx_profile_id
                      , x_return_status             => lx_return_status
                      , x_msg_count                 => lx_msg_count
                      , x_msg_data                  => lx_msg_data
                       );
    END IF;                                         
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status  :' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_cust_account_id:' || lx_cust_account_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_account_number :' || lx_account_number);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_id       :' || lx_party_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_number   :' || lx_party_number);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_profile_id     :' || lx_profile_id);

    IF lx_return_status != 'S'
    THEN
       IF NVL (lx_msg_count, 0) > 0
       THEN
          l_otc_cust_hdr_cnv_rec.error_msg :=
             g_api_name || ': '
             || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

          FOR i IN 1 .. lx_msg_count
          LOOP
             xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Error:  ' || fnd_msg_pub.get (i, 'F'));
          END LOOP;
       END IF;
           
       xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                         xx_emf_cn_pkg.CN_STG_DATADRV,
                         l_otc_cust_hdr_cnv_rec.error_msg,
                         l_otc_cust_hdr_cnv_rec.batch_id,
                         l_otc_cust_hdr_cnv_rec.record_number,
                         l_otc_cust_hdr_cnv_rec.ORIG_SYSTEM_REF
                        );
         
       p_otc_cust_hdr_cnv_rec := l_otc_cust_hdr_cnv_rec;
       RETURN FALSE;
    END IF;

    l_otc_cust_hdr_cnv_rec.cust_account_id := lx_cust_account_id;
    l_otc_cust_hdr_cnv_rec.account_number  := lx_account_number;
    l_otc_cust_hdr_cnv_rec.party_id        := lx_party_id;
    l_otc_cust_hdr_cnv_rec.party_number    := lx_party_number;
    l_otc_cust_hdr_cnv_rec.profile_id      := lx_profile_id;

    p_otc_cust_hdr_cnv_rec := l_otc_cust_hdr_cnv_rec;

  

    DECLARE
       l_temp_profile_id   NUMBER;
    BEGIN
       SELECT cust_account_profile_id
       INTO l_temp_profile_id
       FROM hz_customer_profiles
       WHERE cust_account_id = lx_cust_account_id;

       xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_low,'l_temp_profile_id :  ' || l_temp_profile_id);
       l_otc_cust_hdr_cnv_rec.profile_id := l_temp_profile_id;
    EXCEPTION
       WHEN OTHERS
       THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'l_temp_profile_id not found');
    END;


    IF create_customer_profile (l_otc_cust_hdr_cnv_rec)
    THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'create_customer_profile Successful');
    ELSE
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'create_customer_profile Failed');
        p_otc_cust_hdr_cnv_rec := l_otc_cust_hdr_cnv_rec;
        RETURN FALSE;
    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     l_otc_cust_hdr_cnv_rec.error_msg := g_api_name||' '||' Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                         xx_emf_cn_pkg.CN_STG_DATADRV,
                         l_otc_cust_hdr_cnv_rec.error_msg,
                         l_otc_cust_hdr_cnv_rec.batch_id,
                         l_otc_cust_hdr_cnv_rec.record_number,
                         l_otc_cust_hdr_cnv_rec.ORIG_SYSTEM_REF
                        );
     RETURN FALSE;
END create_account_org_type;




-------------------------------------------------------------------------------------
----------------------------------Procedure main-------------------------------------
-------------------------------------------------------------------------------------
PROCEDURE main (
  errbuf                OUT NOCOPY      VARCHAR2,
  retcode               OUT NOCOPY      VARCHAR2,
  p_batch_id            IN              VARCHAR2,
  p_restart_flag        IN              VARCHAR2,
  p_validate_and_load   IN              VARCHAR2
)
IS
  -- Customer Header Cursor Definition 
  CURSOR c_cust_hdr_cur
  IS
     SELECT *
     FROM xxconv.xx_ar_cust_stg
     WHERE batch_id = p_batch_id
     --AND account_number = '101069'
     --AND orig_system_ref in ('O11_76858')
     --AND rownum <=10
     AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR ) 
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));
         
  -- Address Header Cursor Definition 
  CURSOR c_cust_addr_cur_val (p_orig_system_ref VARCHAR2)
  IS
     SELECT *
     FROM xxconv.xx_ar_address_stg
     WHERE batch_id = p_batch_id
     AND   orig_system_ref = p_orig_system_ref
     AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR ) 
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));
          
  CURSOR c_cust_addr_cur_load (p_orig_system_ref VARCHAR2)
  IS 
     SELECT distinct
            "BATCH_ID",
            "ORIG_SYSTEM_REF",
            "ORIG_SYS_ADDR_REF",
            NULL "ORIG_SYS_SITE_USE_REF",
            "SOURCE_SYSTEM_NAME",
            "ADDRESS_ID",
            NULL "PRIMARY_ADDRESS",
            "IDENTIFYING_FLAG",
            NULL "SITE_USE_STATUS",
            NULL "ADDRESS_TYPE",
            NULL "LOCATION",
            "ADDRESS1",
            "ADDRESS2",
            "ADDRESS3",
            "ADDRESS4",
            "CITY",
            "STATE",
            "POSTAL_CODE",
            "COUNTY",
            "PROVINCE",
            "COUNTRY",
            "COUNTRY_CODE",
            "ADDRESS_STYLE",
            "SITE_USE_OPERATING_UNIT",
            "ORG_ID",
            "GLOBAL_LOCATION_NUMBER",
            "PARTY_SITE_ID",
            "PARTY_SITE_NUMBER",
            "PARTY_NUMBER",
            "CUST_ACCT_SITE_ID",
            NULL "SITE_USE_ID",
            "ATTRIBUTE_CATEGORY",
            "ATTRIBUTE1",
            "ATTRIBUTE2",
            "ATTRIBUTE3",
            "ATTRIBUTE4",
            "ATTRIBUTE5",
            "ATTRIBUTE6",
            "ATTRIBUTE7",
            "ATTRIBUTE8",
            "ATTRIBUTE9",
            "ATTRIBUTE10",
            "ATTRIBUTE11",
            NULL "ORG_COMP_CODE",
            NULL "SITE_FREIGHT_TERMS",
            NULL "SHIP_METHOD",
            NULL "FOB_CODE",
            NULL "SITE_USE_ATTRIBUTE_CATEGORY",
            NULL "SITE_USE_ATTRIBUTE1",
            NULL "SITE_USE_ATTRIBUTE2",
            NULL "SITE_USE_ATTRIBUTE3",
            NULL "SITE_USE_ATTRIBUTE4",
            NULL "SITE_USE_ATTRIBUTE5",
            NULL "SITE_USE_ATTRIBUTE6",
            NULL "SITE_USE_ATTRIBUTE7",
            NULL "SITE_USE_ATTRIBUTE8",
            NULL "SITE_USE_ATTRIBUTE9",
            NULL "SITE_USE_ATTRIBUTE10",
            NULL "SITE_USE_ATTRIBUTE19",
            NULL "FILE_NAME",
            NULL "RECORD_NUMBER",
            NULL "REQUEST_ID",
            NULL "LAST_UPDATED_BY",
            NULL "LAST_UPDATE_DATE",
            NULL "PHASE_CODE",
            NULL "ERROR_CODE",
            NULL "ERROR_MSG"
     FROM   xx_ar_address_stg    
     WHERE  orig_system_ref = p_orig_system_ref
     AND  batch_id = p_batch_id
     AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR ) 
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));             
          
    CURSOR c_cust_site_cur (p_orig_system_ref VARCHAR2,p_orig_sys_addr_ref VARCHAR2)
    IS
    SELECT  "ORIG_SYS_SITE_USE_REF",
            "PRIMARY_ADDRESS",
            "SITE_USE_STATUS",
            "ADDRESS_TYPE",
            "LOCATION",
            "SITE_USE_ID",
            "ORG_COMP_CODE",
            "SITE_FREIGHT_TERMS",
            "SHIP_METHOD",
            "FOB_CODE",
            "SITE_USE_ATTRIBUTE_CATEGORY",
            "SITE_USE_ATTRIBUTE1",
            "SITE_USE_ATTRIBUTE2",
            "SITE_USE_ATTRIBUTE3",
            "SITE_USE_ATTRIBUTE4",
            "SITE_USE_ATTRIBUTE5",
            "SITE_USE_ATTRIBUTE6",
            "SITE_USE_ATTRIBUTE7",
            "SITE_USE_ATTRIBUTE8",
            "SITE_USE_ATTRIBUTE9",
            "SITE_USE_ATTRIBUTE10",
            "SITE_USE_ATTRIBUTE19",
            "FILE_NAME",
            "RECORD_NUMBER",
            "REQUEST_ID",
            "LAST_UPDATED_BY",
            "LAST_UPDATE_DATE",
            "PHASE_CODE",
            "ERROR_CODE",
            "ERROR_MSG"
     FROM   xx_ar_address_stg 
     where  ORIG_SYS_ADDR_REF =   p_orig_sys_addr_ref
     AND batch_id = p_batch_id
     AND    ORIG_SYSTEM_REF = p_orig_system_ref        
     AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR ) 
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));

      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;
      
      l_otc_cust_hdr_cnv_tab     xx_otc_cust_hdr_cnv_tab_type;
      l_otc_cust_addr_cnv_tab    xx_otc_cust_addr_cnv_tab_type;

      l_otc_cust_hdr_cnv_rec     xxconv.xx_ar_cust_stg%ROWTYPE;
      l_otc_cust_addr_cnv_rec    xxconv.xx_ar_address_stg%ROWTYPE;

      lx_otc_cust_hdr_cnv_rec    xxconv.xx_ar_cust_stg%ROWTYPE;
      lx_otc_cust_addr_cnv_rec   xxconv.xx_ar_address_stg%ROWTYPE;

      l_cust_account_rec         hz_cust_account_v2pub.cust_account_rec_type;
      l_organization_rec         hz_party_v2pub.organization_rec_type;
      l_customer_profile_rec     hz_customer_profile_v2pub.customer_profile_rec_type;
      l_location_rec             hz_location_v2pub.location_rec_type;
      lx_cust_account_rec        hz_cust_account_v2pub.cust_account_rec_type;
      lx_organization_rec        hz_party_v2pub.organization_rec_type;
      lx_person_rec              hz_party_v2pub.person_rec_type;
      lx_customer_profile_rec    hz_customer_profile_v2pub.customer_profile_rec_type;
      lx_location_rec            hz_location_v2pub.location_rec_type;
      l_party_site_rec           hz_party_site_v2pub.party_site_rec_type;
      l_cust_acct_site_rec       hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      l_cust_site_use_rec        hz_cust_account_site_v2pub.cust_site_use_rec_type;


      l_create_person_rec        hz_party_v2pub.person_rec_type;
      l_org_contact_rec          hz_party_contact_v2pub.org_contact_rec_type;
      l_cr_cust_acc_role_rec     hz_cust_account_role_v2pub.cust_account_role_rec_type;
      e_customer_trx_exception   EXCEPTION;
      e_address_trx_exception    EXCEPTION;
      e_site_trx_exception       EXCEPTION;

BEGIN 
     retcode := xx_emf_cn_pkg.CN_SUCCESS;

     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Set_cnv_env');
     set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);
     
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id          '    || p_batch_id);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag      '    || p_restart_flag);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '    || p_validate_and_load);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
     
     -- Call procedure to update records with the current request_id
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
     mark_records_for_processing(p_batch_id, p_restart_flag);
     
     
     IF p_validate_and_load = 'VALIDATE_ONLY' THEN
     -- This section is executed when the user selects to VALIDATE_ONLY mode. The section pertains to validation of data given
         set_stage (xx_emf_cn_pkg.CN_VALID);
         -- Start Data Validation
         OPEN c_cust_hdr_cur;
         LOOP
            FETCH c_cust_hdr_cur 
            BULK COLLECT INTO l_otc_cust_hdr_cnv_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;
            
            FOR i IN 1 .. l_otc_cust_hdr_cnv_tab.COUNT
            LOOP
                l_otc_cust_hdr_cnv_rec := l_otc_cust_hdr_cnv_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion Customer for '||l_otc_cust_hdr_cnv_rec.ORIG_SYSTEM_REF);
                x_error_code  := xx_ar_customer_val_pkg.data_validations_cust(l_otc_cust_hdr_cnv_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_otc_cust_hdr_cnv_rec.record_number||'  is ' || x_error_code);
                update_cust_record_status (l_otc_cust_hdr_cnv_rec, x_error_code);
                
                IF c_cust_addr_cur_val%ISOPEN
                THEN
                   CLOSE c_cust_addr_cur_val;
                END IF;
                
                OPEN c_cust_addr_cur_val (l_otc_cust_hdr_cnv_rec.ORIG_SYSTEM_REF);
                LOOP
                    FETCH c_cust_addr_cur_val
                    BULK COLLECT INTO l_otc_cust_addr_cnv_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;
                        
                    FOR n IN 1 .. l_otc_cust_addr_cnv_tab.COUNT
                    LOOP
                        l_otc_cust_addr_cnv_rec := l_otc_cust_addr_cnv_tab (n);
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion Address');
                        x_error_code  := xx_ar_customer_val_pkg.data_validations_address(l_otc_cust_addr_cnv_rec);
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_otc_cust_addr_cnv_rec.record_number||'  is ' || x_error_code);
                        update_address_record_status (l_otc_cust_addr_cnv_rec, x_error_code);
                        mark_address_rec_complete(xx_emf_cn_pkg.CN_VALID,l_otc_cust_addr_cnv_rec);
                    END LOOP;
                    
                    l_otc_cust_addr_cnv_tab.DELETE;
                    EXIT WHEN c_cust_addr_cur_val%NOTFOUND;
                END LOOP;    
                
                CLOSE c_cust_addr_cur_val;
                update_cnt (p_validate_and_load);
                mark_cust_rec_complete(xx_emf_cn_pkg.CN_VALID,l_otc_cust_hdr_cnv_rec);
            END LOOP;
            
            l_otc_cust_hdr_cnv_tab.DELETE;
            EXIT WHEN c_cust_hdr_cur%NOTFOUND;
         END LOOP;
         CLOSE c_cust_hdr_cur;
     
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables. 
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
        
        -- IF Customer Cursor is Open Close the same
        IF c_cust_hdr_cur%ISOPEN
        THEN
             CLOSE c_cust_hdr_cur;
        END IF;
        
        OPEN c_cust_hdr_cur;

        FETCH c_cust_hdr_cur
        BULK COLLECT INTO l_otc_cust_hdr_cnv_tab;
        
        FOR i IN 1 .. l_otc_cust_hdr_cnv_tab.COUNT
        LOOP
            BEGIN
                l_otc_cust_hdr_cnv_rec  := g_miss_cust_hdr_cnv_rec;
                l_cust_account_rec      := g_miss_cust_account_rec;
                l_organization_rec      := g_miss_organization_rec;
                l_customer_profile_rec  := g_miss_customer_profile_rec;
                lx_cust_account_rec     := g_miss_cust_account_rec;
                lx_organization_rec     := g_miss_organization_rec;
                lx_customer_profile_rec := g_miss_customer_profile_rec;


                SAVEPOINT skip_transaction;
                l_otc_cust_hdr_cnv_rec := l_otc_cust_hdr_cnv_tab (i);
                l_otc_cust_hdr_cnv_rec.phase_code := g_stage;
                
                
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_otc_cust_hdr_cnv_rec.organization_name);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
            
                IF NOT customer_derivations (p_cust_rec      => l_otc_cust_hdr_cnv_rec)
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'customer_derivations Failed');
                   RAISE e_customer_trx_exception;
                END IF; -- customer_derivations
                
                IF init_account_org_type
                            (p_otc_cust_hdr_cnv_rec      => l_otc_cust_hdr_cnv_rec
                           , x_cust_account_rec          => lx_cust_account_rec
                           , x_organization_rec          => lx_organization_rec
                           , x_person_rec                => lx_person_rec
                           , x_customer_profile_rec      => lx_customer_profile_rec
                            )
                THEN
                    IF create_account_org_type
                          (p_cust_account_rec          => lx_cust_account_rec
                         , p_organization_rec          => lx_organization_rec
                         , p_person_rec                => lx_person_rec
                         , p_customer_profile_rec      => lx_customer_profile_rec
                         , p_otc_cust_hdr_cnv_rec      => l_otc_cust_hdr_cnv_rec
                          )
                    THEN
                        
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' Customer A/C Created Successfully ');
                        IF c_cust_addr_cur_load%ISOPEN
                        THEN
                           CLOSE c_cust_addr_cur_load;
                        END IF;

                        OPEN c_cust_addr_cur_load (l_otc_cust_hdr_cnv_rec.orig_system_ref);

                        FETCH c_cust_addr_cur_load
                        BULK COLLECT INTO l_otc_cust_addr_cnv_tab;
                        
                        FOR j IN 1 .. l_otc_cust_addr_cnv_tab.COUNT
                        LOOP
                             l_otc_cust_addr_cnv_rec            := g_miss_cust_addr_cnv_rec;
                             l_location_rec                     := g_miss_location_rec;
                             l_otc_cust_addr_cnv_rec            := l_otc_cust_addr_cnv_tab (j);
                             l_otc_cust_addr_cnv_rec.phase_code := g_stage;
                             
                             xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'address_derivations For - '||l_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF);
                             xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Identifying Flag '||l_otc_cust_addr_cnv_rec.identifying_flag);
                             IF NOT address_derivations
                                      (p_addr_rec      => l_otc_cust_addr_cnv_rec
                                     , p_cust_rec      => l_otc_cust_hdr_cnv_rec
                                      )
                             THEN
                                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'address_derivations Failed');
                                RAISE e_address_trx_exception;
                             END IF; -- address_derivations
                             
                             IF init_location
                                     (x_location_rec               => l_location_rec
                                    , p_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                     )
                             THEN
                                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_location Successful');
                                  IF create_location
                                        (p_location_rec               => l_location_rec
                                       , x_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                        )
                                  THEN
                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_location Successful');
                                        l_party_site_rec    := g_miss_party_site_rec;
                                        IF init_party_site
                                                         (x_party_site_rec             => l_party_site_rec
                                                        , p_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                                        , p_otc_cust_hdr_cnv_rec       => l_otc_cust_hdr_cnv_rec
                                                         )
                                        THEN
                                              xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_party_site Successful');
                                              IF create_party_site
                                                                 (p_party_site_rec             => l_party_site_rec
                                                                , x_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                                                 )
                                              THEN 
                                                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_party_site Successful');
                                                  l_cust_acct_site_rec  := g_miss_cust_acct_site_rec;
                                                  
                                                  IF init_cust_acct_site
                                                                       (x_cust_acct_site_rec         => l_cust_acct_site_rec
                                                                      , p_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                                                      , p_otc_cust_hdr_cnv_rec       => l_otc_cust_hdr_cnv_rec
                                                                       )
                                                  THEN
                                                      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_cust_acct_site Successful');
                                                      IF create_cust_acct_site
                                                                    (p_cust_acct_site_rec         => l_cust_acct_site_rec
                                                                   , x_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                                                    )
                                                      THEN
                                                          xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_cust_acct_site Successful');
                                                          FOR c1 in c_cust_site_cur (l_otc_cust_addr_cnv_rec.ORIG_SYSTEM_REF,l_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF)
                                                          LOOP
                                                              xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Site Use Create for ADDR - '||l_otc_cust_addr_cnv_rec.ORIG_SYS_ADDR_REF||'- '||c1.ORIG_SYS_SITE_USE_REF);
                                                              l_otc_cust_addr_cnv_rec.ORIG_SYS_SITE_USE_REF := c1.ORIG_SYS_SITE_USE_REF;
                                                              l_otc_cust_addr_cnv_rec.PRIMARY_ADDRESS       := c1.PRIMARY_ADDRESS;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_STATUS       := c1.SITE_USE_STATUS;                                                              
                                                              l_otc_cust_addr_cnv_rec.ADDRESS_TYPE          := c1.ADDRESS_TYPE;
                                                              l_otc_cust_addr_cnv_rec.LOCATION              := c1.LOCATION;
                                                              l_otc_cust_addr_cnv_rec.ORG_COMP_CODE         := c1.ORG_COMP_CODE;    
                                                              l_otc_cust_addr_cnv_rec.SITE_FREIGHT_TERMS    := c1.SITE_FREIGHT_TERMS;
                                                              l_otc_cust_addr_cnv_rec.SHIP_METHOD           := c1.ship_method;
                                                              l_otc_cust_addr_cnv_rec.FOB_CODE              := c1.fob_code;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE_CATEGORY := c1.SITE_USE_ATTRIBUTE_CATEGORY;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE1   := c1.SITE_USE_ATTRIBUTE1;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE2   := c1.SITE_USE_ATTRIBUTE2;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE3   := c1.SITE_USE_ATTRIBUTE3;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE4   := c1.SITE_USE_ATTRIBUTE4;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE5   := c1.SITE_USE_ATTRIBUTE5;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE6   := c1.SITE_USE_ATTRIBUTE6;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE7   := c1.SITE_USE_ATTRIBUTE7;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE8   := c1.SITE_USE_ATTRIBUTE8;
                                                              --l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE9   := c1.SITE_USE_ATTRIBUTE9;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE10  := c1.SITE_USE_ATTRIBUTE10;
                                                              l_otc_cust_addr_cnv_rec.SITE_USE_ATTRIBUTE19  := c1.SITE_USE_ATTRIBUTE19;

                                                              
                                                              l_cust_site_use_rec    := g_miss_cust_site_use_rec;
                                                              l_customer_profile_rec := g_miss_customer_profile_rec;
                                                              
                                                              IF init_cust_site_use
                                                                     (x_cust_site_use_rec          => l_cust_site_use_rec
                                                                    , x_customer_profile_rec       => l_customer_profile_rec
                                                                    , p_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                                                    , p_otc_cust_hdr_cnv_rec       => l_otc_cust_hdr_cnv_rec
                                                                     )
                                                              THEN
                                                                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_cust_site_use Successful');
                                                                  IF create_cust_site_use
                                                                        (p_cust_site_use_rec          => l_cust_site_use_rec
                                                                       , p_customer_profile_rec       => l_customer_profile_rec
                                                                       , x_otc_cust_addr_cnv_rec      => l_otc_cust_addr_cnv_rec
                                                                       , p_otc_cust_hdr_cnv_rec       => l_otc_cust_hdr_cnv_rec
                                                                        )
                                                                  THEN
                                                                       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_cust_site_use Successful');      
                                                                  
                                                                  ELSE -- create_cust_site_use
                                                                  
                                                                       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_cust_site_use Failed');
                                                                       RAISE e_site_trx_exception;
                                                                  
                                                                  END IF; -- create_cust_site_use
                                                              
                                                              ELSE -- init_cust_site_use
                                                             
                                                                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_cust_site_use Failed');
                                                                  RAISE e_site_trx_exception;
                                                             
                                                              END IF; -- init_cust_site_use
                                                              
                                                              l_otc_cust_addr_cnv_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                                                              l_otc_cust_addr_cnv_rec.error_msg  := NULL;
                                                              l_otc_cust_addr_cnv_rec.phase_code := g_stage;
                                                              xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Identifying Flag :'||  l_otc_cust_addr_cnv_rec.identifying_flag);                                 
                                                              IF update_cust_site_cnv_stg
                                                                               (p_stage_rec      => l_otc_cust_addr_cnv_rec
                                                                              , p_batch_id       => p_batch_id
                                                                               )
                                                              THEN
                                                                 xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_addr_cnv_stg updated');
                                                              END IF;
                                                          
                                                          
                                                          END LOOP; -- c_cust_site_cur 
                                                      
                                                      ELSE -- create_cust_acct_site
                                                      
                                                          xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_cust_acct_site Failed');
                                                          RAISE e_address_trx_exception;
                                                          
                                                      END IF; -- create_cust_acct_site
                                                      
                                                  
                                                  ELSE -- init_cust_acct_site
                                                      xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_cust_acct_site Failed');
                                                      RAISE e_address_trx_exception;                                                      
                                                  END IF; -- init_cust_acct_site                    
                                                  
                                              ELSE -- create_party_site
                                              
                                                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_party_site Failed');
                                                  RAISE e_address_trx_exception;
                                                  
                                              END IF; -- create_party_site
                                        ELSE -- init_party_site
                                        
                                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_party_site Failed');
                                            RAISE e_address_trx_exception;
                                        
                                        END IF; -- init_party_site
                                         
                                  ELSE -- create_location
                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_location Failed');
                                        RAISE e_address_trx_exception;
                                  END IF; -- create_location
                                
                             ELSE -- init_location
                              
                                  xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_location Failed');
                                  RAISE e_address_trx_exception;
                                
                             END IF; -- init_location     
                             
                             --l_otc_cust_addr_cnv_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                             --l_otc_cust_addr_cnv_rec.error_msg  := NULL;
                             --l_otc_cust_addr_cnv_rec.phase_code := g_stage;
                             /*
                             IF update_cust_addr_cnv_stg
                                              (p_stage_rec      => l_otc_cust_addr_cnv_rec
                                             , p_batch_id       => p_batch_id
                                              )
                             THEN
                                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_addr_cnv_stg updated');
                             END IF;                             
                            */
                        END LOOP; -- End Loop for l_otc_cust_addr_cnv_rec 
                        
                        l_otc_cust_addr_cnv_tab.DELETE;
                        CLOSE c_cust_addr_cur_load;
                         
                    ELSE -- create_account_org_type
                        
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_account_org_type Failed');
                        RAISE e_customer_trx_exception;
                        
                    END IF; -- create_account_org_type
                    
                ELSE -- init_account_org_type
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_account_org_type Failed');
                    RAISE e_customer_trx_exception;
                END IF; -- init_account_org_type  
                
                l_otc_cust_hdr_cnv_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_otc_cust_hdr_cnv_rec.error_msg  := NULL;
                IF update_cust_hdr_cnv_stg (l_otc_cust_hdr_cnv_rec,p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_hdr_cnv_stg updated');
                END IF;

                COMMIT;         
            EXCEPTION
            WHEN e_customer_trx_exception
            THEN
                l_otc_cust_hdr_cnv_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                
                IF l_otc_cust_hdr_cnv_rec.account_number like '%011' THEN
                   l_otc_cust_hdr_cnv_rec.account_number := substr(l_otc_cust_hdr_cnv_rec.account_number,1,length(l_otc_cust_hdr_cnv_rec.account_number)-3);
                END IF;
                
                IF l_otc_cust_hdr_cnv_rec.party_number like '%011' THEN
                   l_otc_cust_hdr_cnv_rec.party_number := substr(l_otc_cust_hdr_cnv_rec.party_number,1,length(l_otc_cust_hdr_cnv_rec.party_number)-3);
                END IF;   
                
                IF update_cust_hdr_cnv_stg (l_otc_cust_hdr_cnv_rec,p_batch_id) 
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_hdr_cnv_stg updated');    
                END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction; 
                
            WHEN e_address_trx_exception
            THEN                  
                l_otc_cust_hdr_cnv_rec.error_code  := xx_emf_cn_pkg.CN_REC_ERR;
                l_otc_cust_addr_cnv_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                
                IF l_otc_cust_addr_cnv_rec.party_site_number like '%011' THEN
                   l_otc_cust_addr_cnv_rec.party_site_number := substr(l_otc_cust_addr_cnv_rec.party_site_number,1,length(l_otc_cust_addr_cnv_rec.party_site_number)-3);
                END IF;
                
                IF update_cust_addr_cnv_stg(l_otc_cust_addr_cnv_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_addr_cnv_stg updated');
                END IF;
                
                IF l_otc_cust_hdr_cnv_rec.account_number like '%011' THEN
                   l_otc_cust_hdr_cnv_rec.account_number := substr(l_otc_cust_hdr_cnv_rec.account_number,1,length(l_otc_cust_hdr_cnv_rec.account_number)-3);
                END IF;
                
                IF l_otc_cust_hdr_cnv_rec.party_number like '%011' THEN
                   l_otc_cust_hdr_cnv_rec.party_number := substr(l_otc_cust_hdr_cnv_rec.party_number,1,length(l_otc_cust_hdr_cnv_rec.party_number)-3);
                END IF;
                
                IF update_cust_hdr_cnv_stg (l_otc_cust_hdr_cnv_rec,p_batch_id) 
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_hdr_cnv_stg updated');    
                END IF;
                
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction; 
            

            WHEN e_site_trx_exception
            THEN                  
                l_otc_cust_hdr_cnv_rec.error_code  := xx_emf_cn_pkg.CN_REC_ERR;
                l_otc_cust_addr_cnv_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                
                IF update_cust_site_cnv_stg(l_otc_cust_addr_cnv_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_site_cnv_stg updated');
                END IF;
                /* 
                IF update_cust_addr_cnv_stg(l_otc_cust_addr_cnv_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_addr_cnv_stg updated');
                END IF;
                */
                IF update_cust_hdr_cnv_stg (l_otc_cust_hdr_cnv_rec,p_batch_id) 
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_hdr_cnv_stg updated');    
                END IF;
                
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction; 
            
            END;
        END LOOP; -- End Loop for l_otc_cust_hdr_cnv_rec
        
        l_otc_cust_hdr_cnv_tab.DELETE;
        CLOSE c_cust_hdr_cur;
        
     END IF; -- Validate_and_load condition 
    update_cnt (p_validate_and_load); 
    xx_emf_pkg.create_report;
    
EXCEPTION
    WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;
    WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'REC_ERROR');
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;
    WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'PRC_ERROR');
         retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         xx_emf_pkg.create_report;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS');
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.create_report;
END main;

END xx_ar_customer_load_pkg;
/
