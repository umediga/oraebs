DROP PACKAGE BODY APPS.XX_AR_CUST_RELATE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_CUST_RELATE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 12-Jun-2013
 File Name      : XXARCUSTREL.pkb
 Description    : This script creates the body of the package XX_AR_CUST_RELATE_PKG
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
12-June-2013     ABhargava    Initial development.
04-SEP-2014      Sharath Babu Modified as per Wave2 to take ORG_ID value from process setup
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
    UPDATE XX_AR_CUST_RELATE 
    set REQUEST_ID = xx_emf_pkg.G_REQUEST_ID
       --,ERROR_CODE = xx_emf_cn_pkg.CN_NULL
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
------------< Update Customer Table Status after Validation >------------
--------------------------------------------------------------------------------
PROCEDURE update_cust_record_status ( p_cust_rel_rec   IN OUT  g_xx_ar_cust_rel_rec_type,
                                      p_error_code     IN      VARCHAR2
                                    ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_cust_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_cust_rel_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_cust_rel_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_cust_rel_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;
    
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_cust_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_cust_record_status '||SQLERRM);
END update_cust_record_status;

--------------------------------------------------------------------------------
------------< Update Customer Relation Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_cust_relate_stg (
                                  p_stage_rec   IN OUT NOCOPY   xxconv.XX_AR_CUST_RELATE%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                                 )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
    PRAGMA AUTONOMOUS_TRANSACTION; 
BEGIN
    g_api_name := 'update_cust_relate_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    UPDATE XX_AR_CUST_RELATE
    SET  id_number                   = p_stage_rec.id_number
       , api_type                    = p_stage_rec.api_type
       , cust_acct_relate_id         = p_stage_rec.cust_acct_relate_id
       , cust_account_id             = p_stage_rec.cust_account_id
       , org_id                      = p_stage_rec.org_id
       , related_id_number           = p_stage_rec.related_id_number
       , related_cust_account_id     = p_stage_rec.related_cust_account_id
       , relationship_type           = p_stage_rec.relationship_type
       , relationship_code           = p_stage_rec.relationship_code
       , customer_reciporical_flag   = p_stage_rec.customer_reciporical_flag 
       , bill_to_flag                = p_stage_rec.bill_to_flag
       , ship_to_flag                = p_stage_rec.ship_to_flag
       , start_date                  = p_stage_rec.start_date
       , end_date                    = p_stage_rec.end_date
       , comments                    = p_stage_rec.comments   
       , request_id                  = xx_emf_pkg.G_REQUEST_ID
       , LAST_UPDATED_BY             = x_last_updated_by
       , LAST_UPDATE_DATE            = x_last_update_date
       , phase_code                  = p_stage_rec.phase_code
       , error_code                  = p_stage_rec.error_code
       , error_msg                   = p_stage_rec.error_msg
    WHERE batch_id          =   p_batch_id
    and   record_number     =   p_stage_rec.record_number
    and   id_number         =   p_stage_rec.id_number 
    and   related_id_number =   p_stage_rec.related_id_number;   
    
    
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    COMMIT;
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_cust_relate_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_cust_relate_stg;        


--------------------------------------------------------------------------------
------------< Update Count >------------
--------------------------------------------------------------------------------
PROCEDURE update_cnt 
IS
l_suc    NUMBER := 0;
l_err    NUMBER := 0;
l_tot    NUMBER := 0;
BEGIN
   
    select count(1)
    into l_tot
    from XX_AR_CUST_RELATE
    where batch_id   =  g_batch_id 
    and   request_id =  xx_emf_pkg.G_REQUEST_ID;
        
    select count(1)
    into l_suc
    from XX_AR_CUST_RELATE
    where batch_id   =  g_batch_id 
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '0';
        
    select count(1)
    into l_err
    from XX_AR_CUST_RELATE
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

EXCEPTION 
WHEN OTHERS THEN 
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_cnt '||SQLERRM);
END;

-------------------------------------------------------------------------------------
---------------------------------- Customer Derivation ------------------------------
-------------------------------------------------------------------------------------
FUNCTION customer_derivations (p_cust_rec   IN OUT NOCOPY   xxconv.XX_AR_CUST_RELATE%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
BEGIN
    g_api_name := 'customer_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    BEGIN 
        select cust_account_id
        into p_cust_rec.cust_account_id
        from hz_cust_accounts_all 
        where orig_system_reference = p_cust_rec.id_number;
    EXCEPTION
    WHEN OTHERS THEN 
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Customer for ID NUMBER :'||p_cust_rec.id_number);
        l_msg := 'Error Deriving Customer for ID NUMBER :'||p_cust_rec.id_number;
        RAISE l_error_transaction;
    END; 
    
    
    BEGIN 
        select cust_account_id
        into p_cust_rec.RELATED_CUST_ACCOUNT_ID
        from hz_cust_accounts_all 
        where orig_system_reference = p_cust_rec.RELATED_ID_NUMBER;
    EXCEPTION
    WHEN OTHERS THEN 
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Customer for Related ID NUMBER :'||p_cust_rec.RELATED_ID_NUMBER);
        l_msg := 'Error Deriving Customer for Related ID NUMBER :'||p_cust_rec.RELATED_ID_NUMBER;
        RAISE l_error_transaction;
    END;        
    
    p_cust_rec.org_id := NVL(xx_emf_pkg.get_paramater_value('XXARCUSTREL','ORG_ID'),'82'); --82; Modified as per Wave2
    
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
                       p_cust_rec.record_number,
                       p_cust_rec.ID_NUMBER,
                       p_cust_rec.RELATED_ID_NUMBER
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
                       p_cust_rec.record_number,
                       p_cust_rec.ID_NUMBER,
                       p_cust_rec.RELATED_ID_NUMBER
                      );
     RETURN FALSE;
END customer_derivations;     

-------------------------------------------------------------------------------------
---------------------------------- Party Derivation ------------------------------
-------------------------------------------------------------------------------------
FUNCTION party_derivations (p_cust_rec   IN OUT NOCOPY   xxconv.XX_AR_CUST_RELATE%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
BEGIN
    g_api_name := 'party_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    BEGIN 
        select party_id
        into p_cust_rec.cust_account_id
        from hz_parties 
        where orig_system_reference = p_cust_rec.id_number;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN 
         BEGIN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'In NO DATA FOUND');
              select party_id
              into p_cust_rec.cust_account_id
              from hz_parties 
              where ( orig_system_reference = 'O11_'||substr(p_cust_rec.id_number,5)||'011' 
                   OR orig_system_reference = 'O11_'||substr(p_cust_rec.id_number,5)||'012'
                   OR orig_system_reference = substr(p_cust_rec.id_number,1,length(p_cust_rec.id_number)-3));
         EXCEPTION
         WHEN OTHERS THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Party for ID NUMBER :'||p_cust_rec.id_number);
            l_msg := 'Error Deriving Party for ID NUMBER ';
            RAISE l_error_transaction;
         END;     
    WHEN OTHERS THEN 
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Party for ID NUMBER :'||p_cust_rec.id_number);
        l_msg := 'Error Deriving Party for ID NUMBER ';
        RAISE l_error_transaction;
    END; 
    
    
    BEGIN 
        select party_id
        into p_cust_rec.RELATED_CUST_ACCOUNT_ID
        from hz_parties
        where orig_system_reference = p_cust_rec.RELATED_ID_NUMBER;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN 
         BEGIN
              xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'In NO DATA FOUND');
              select party_id
              into p_cust_rec.RELATED_CUST_ACCOUNT_ID
              from hz_parties 
              where ( orig_system_reference = 'O11_'||substr(p_cust_rec.RELATED_ID_NUMBER,5)||'011' 
                   OR orig_system_reference = 'O11_'||substr(p_cust_rec.RELATED_ID_NUMBER,5)||'012'
                   OR orig_system_reference = substr(p_cust_rec.RELATED_ID_NUMBER,1,length(p_cust_rec.RELATED_ID_NUMBER)-3));
         EXCEPTION
         WHEN OTHERS THEN 
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Party for Related ID NUMBER :'||p_cust_rec.RELATED_ID_NUMBER);
            l_msg := 'Error Deriving Party for Related ID NUMBER ';
            RAISE l_error_transaction;
         END;
    WHEN OTHERS THEN 
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Party for Related ID NUMBER :'||p_cust_rec.RELATED_ID_NUMBER);
        l_msg := 'Error Deriving Party for Related ID NUMBER ';
        RAISE l_error_transaction;
    END;        
    
    p_cust_rec.org_id := NVL(xx_emf_pkg.get_paramater_value('XXARCUSTREL','ORG_ID'),'82'); --82; Modified as per Wave2
    
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
                       p_cust_rec.record_number,
                       p_cust_rec.ID_NUMBER,
                       p_cust_rec.RELATED_ID_NUMBER
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Party_Derivations Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_cust_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_cust_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_cust_rec.record_number,
                       p_cust_rec.ID_NUMBER,
                       p_cust_rec.RELATED_ID_NUMBER
                      );
     RETURN FALSE;
END party_derivations;

-------------------------------------------------------------------------------------
   ------------------- Initialise Customer Relationship Record Type  -----------------
------------------------------------------------------------------------------------- 

FUNCTION init_cust_acct_relate (
                               x_cust_acct_relate_rec    IN OUT NOCOPY   hz_cust_account_v2pub.cust_acct_relate_rec_type
                             , p_otc_cust_relate_rec     IN OUT NOCOPY   xxconv.XX_AR_CUST_RELATE%ROWTYPE
                               )
RETURN BOOLEAN
IS
BEGIN
    g_api_name := 'init_cust_acct_relate';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    x_cust_acct_relate_rec.CUST_ACCOUNT_ID           := p_otc_cust_relate_rec.CUST_ACCOUNT_ID;
    x_cust_acct_relate_rec.RELATED_CUST_ACCOUNT_ID   := p_otc_cust_relate_rec.RELATED_CUST_ACCOUNT_ID;
    x_cust_acct_relate_rec.ORG_ID                    := p_otc_cust_relate_rec.ORG_ID;
    x_cust_acct_relate_rec.CUSTOMER_RECIPROCAL_FLAG  := p_otc_cust_relate_rec.CUSTOMER_RECIPORICAL_FLAG;
    x_cust_acct_relate_rec.BILL_TO_FLAG              := p_otc_cust_relate_rec.BILL_TO_FLAG;
    x_cust_acct_relate_rec.SHIP_TO_FLAG              := p_otc_cust_relate_rec.SHIP_TO_FLAG;
    x_cust_acct_relate_rec.COMMENTS                  := p_otc_cust_relate_rec.COMMENTS;
    x_cust_acct_relate_rec.CREATED_BY_MODULE         := g_created_by_module;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     p_otc_cust_relate_rec.error_msg := g_api_name||' '||' Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       p_otc_cust_relate_rec.error_msg,
                       p_otc_cust_relate_rec.RECORD_NUMBER,
                       p_otc_cust_relate_rec.ID_NUMBER,
                       p_otc_cust_relate_rec.RELATED_ID_NUMBER
                      );
     RETURN FALSE;
END init_cust_acct_relate;


-------------------------------------------------------------------------------------
   ------------------- Create Customer Relationship  -----------------
-------------------------------------------------------------------------------------
FUNCTION create_cust_acct_relate (
                           p_cust_acct_relate_rec    IN  hz_cust_account_v2pub.cust_acct_relate_rec_type
                         , x_otc_cust_relate_rec     IN OUT NOCOPY   xxconv.XX_AR_CUST_RELATE%ROWTYPE
                           )
RETURN BOOLEAN
IS
    lx_return_status         VARCHAR2 (1);
    lx_msg_count             NUMBER;
    lx_msg_data              VARCHAR2 (2000);
    l_cust_acct_relate_rec   hz_cust_account_v2pub.cust_acct_relate_rec_type;
    lx_cust_acct_relate_id   NUMBER;
BEGIN
    g_api_name := 'create_cust_acct_relate';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_cust_acct_relate_rec    := p_cust_acct_relate_rec;
  /* =======================================================================
     Purpose : This API take the Party Site info'n from the staging
   table as input, and outputs the party_site_id, party_site_number
   and pushes the whole data into r12 hz tables.
   ========================================================================*/
    hz_cust_account_v2pub.create_cust_acct_relate
                (
                 p_init_msg_list        => fnd_api.g_true,
                 p_cust_acct_relate_rec => l_cust_acct_relate_rec,
                 x_cust_acct_relate_id  => lx_cust_acct_relate_id,
                 x_return_status        => lx_return_status,
                 x_msg_count            => lx_msg_count,
                 x_msg_data             => lx_msg_data
                );
                
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status     :' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_cust_acct_relate_id     :' || lx_cust_acct_relate_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_otc_cust_relate_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_otc_cust_relate_rec.error_msg,
                           x_otc_cust_relate_rec.record_number,
                           x_otc_cust_relate_rec.id_number,
                           x_otc_cust_relate_rec.related_id_number
                          );
         RETURN FALSE;
      END IF;

    x_otc_cust_relate_rec.CUST_ACCT_RELATE_ID     := lx_cust_acct_relate_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     x_otc_cust_relate_rec.error_msg := g_api_name||' '||'Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       x_otc_cust_relate_rec.error_msg,
                       x_otc_cust_relate_rec.record_number,
                       x_otc_cust_relate_rec.id_number,
                       x_otc_cust_relate_rec.related_id_number
                      );
     RETURN FALSE;
END create_cust_acct_relate;

-------------------------------------------------------------------------------------
   ------------------- Initialise Party Relationship Record Type  -----------------
------------------------------------------------------------------------------------- 

FUNCTION init_relation (
                        x_org_contact_rec         IN OUT NOCOPY   hz_party_contact_v2pub.org_contact_rec_type
                       ,p_otc_cust_relate_rec     IN OUT NOCOPY   xxconv.XX_AR_CUST_RELATE%ROWTYPE
                       )
RETURN BOOLEAN
IS
BEGIN
    g_api_name := 'init_relation';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    
    X_ORG_CONTACT_REC.CREATED_BY_MODULE                 := G_CREATED_BY_MODULE;
    X_ORG_CONTACT_REC.PARTY_REL_REC.SUBJECT_ID          := P_OTC_CUST_RELATE_REC.CUST_ACCOUNT_ID;
    X_ORG_CONTACT_REC.PARTY_REL_REC.SUBJECT_TYPE        := 'ORGANIZATION';
    X_ORG_CONTACT_REC.PARTY_REL_REC.SUBJECT_TABLE_NAME  := 'HZ_PARTIES';
    X_ORG_CONTACT_REC.PARTY_REL_REC.OBJECT_ID           := P_OTC_CUST_RELATE_REC.RELATED_CUST_ACCOUNT_ID;
    X_ORG_CONTACT_REC.PARTY_REL_REC.OBJECT_TYPE         := 'ORGANIZATION';
    X_ORG_CONTACT_REC.PARTY_REL_REC.OBJECT_TABLE_NAME   := 'HZ_PARTIES';
    X_ORG_CONTACT_REC.PARTY_REL_REC.RELATIONSHIP_CODE   := P_OTC_CUST_RELATE_REC.RELATIONSHIP_CODE;
    X_ORG_CONTACT_REC.PARTY_REL_REC.RELATIONSHIP_TYPE   := P_OTC_CUST_RELATE_REC.RELATIONSHIP_TYPE;
    X_ORG_CONTACT_REC.PARTY_REL_REC.START_DATE          := P_OTC_CUST_RELATE_REC.START_DATE;
    X_ORG_CONTACT_REC.PARTY_REL_REC.END_DATE            := P_OTC_CUST_RELATE_REC.END_DATE;
    X_ORG_CONTACT_REC.PARTY_REL_REC.COMMENTS            := P_OTC_CUST_RELATE_REC.COMMENTS;
    X_ORG_CONTACT_REC.PARTY_REL_REC.STATUS              := 'A';                                   

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     p_otc_cust_relate_rec.error_msg := g_api_name||' '||' Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       p_otc_cust_relate_rec.error_msg,
                       p_otc_cust_relate_rec.RECORD_NUMBER,
                       p_otc_cust_relate_rec.ID_NUMBER,
                       p_otc_cust_relate_rec.RELATED_ID_NUMBER
                      );
     RETURN FALSE;
END init_relation;

-------------------------------------------------------------------------------------
   ------------------- Create Customer Relationship  -----------------
-------------------------------------------------------------------------------------
FUNCTION create_relation (
                           p_org_contact_rec         IN OUT NOCOPY   hz_party_contact_v2pub.org_contact_rec_type
                         , x_otc_cust_relate_rec     IN OUT NOCOPY   xxconv.XX_AR_CUST_RELATE%ROWTYPE
                           )
RETURN BOOLEAN
IS
    lx_return_status         VARCHAR2 (1);
    lx_msg_count             NUMBER;
    lx_msg_data              VARCHAR2 (2000);
    lx_party_rel_id          NUMBER;
    lx_org_contact_id        NUMBER;
    lx_party_id              NUMBER;
    lx_party_number          VARCHAR2 (2000);
    l_org_contact_rec        HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
BEGIN
    g_api_name := 'create_relation';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_org_contact_rec    := p_org_contact_rec;

    HZ_PARTY_CONTACT_V2PUB.CREATE_ORG_CONTACT
                                     (p_init_msg_list        => fnd_api.g_true
                                    , p_org_contact_rec      => l_org_contact_rec
                                    , x_org_contact_id       => lx_org_contact_id
                                    , x_party_rel_id         => lx_party_rel_id
                                    , x_party_id             => lx_party_id
                                    , x_party_number         => lx_party_number
                                    , x_return_status        => lx_return_status
                                    , x_msg_count            => lx_msg_count
                                    , x_msg_data             => lx_msg_data
                                     );
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status  : ' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_id       : ' || lx_party_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_rel_id   : ' || lx_party_rel_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_otc_cust_relate_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_otc_cust_relate_rec.error_msg,
                           x_otc_cust_relate_rec.record_number,
                           x_otc_cust_relate_rec.id_number,
                           x_otc_cust_relate_rec.related_id_number
                          );
         RETURN FALSE;
      END IF;

    x_otc_cust_relate_rec.CUST_ACCT_RELATE_ID     := lx_party_rel_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     x_otc_cust_relate_rec.error_msg := g_api_name||' '||'Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       x_otc_cust_relate_rec.error_msg,
                       x_otc_cust_relate_rec.record_number,
                       x_otc_cust_relate_rec.id_number,
                       x_otc_cust_relate_rec.related_id_number
                      );
     RETURN FALSE;
END create_relation;

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

CURSOR c_cust_relate 
IS
  select * 
  from XX_AR_CUST_RELATE
  WHERE batch_id = p_batch_id
  AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR ) 
       OR
        (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));
        
        
  x_error_code              NUMBER := xx_emf_cn_pkg.cn_success;
  l_otc_cust_relate_tab     xx_otc_cust_relate_tab_type;
  l_otc_cust_relate_rec     xxconv.XX_AR_CUST_RELATE%ROWTYPE;
  l_cust_acct_relate_rec    hz_cust_account_v2pub.cust_acct_relate_rec_type;
  l_org_contact_rec         hz_party_contact_v2pub.org_contact_rec_type;
  
  e_cust_relate_exception   EXCEPTION;
  
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
         OPEN c_cust_relate;
         LOOP
            FETCH c_cust_relate 
            BULK COLLECT INTO l_otc_cust_relate_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;
            
            FOR i IN 1 .. l_otc_cust_relate_tab.COUNT
            LOOP
                l_otc_cust_relate_rec := l_otc_cust_relate_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion Customer for '||l_otc_cust_relate_rec.ID_NUMBER);
                x_error_code  := xx_ar_cust_relate_val_pkg.data_validations_rel(l_otc_cust_relate_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_otc_cust_relate_rec.record_number||'  is ' || x_error_code);
                l_otc_cust_relate_rec.phase_code := G_STAGE;
                l_otc_cust_relate_rec.error_code := x_error_code;
                IF update_cust_relate_stg (l_otc_cust_relate_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_relate_stg updated');
                ELSE
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_relate_stg update FAILED');    
                END IF;
            END LOOP;
            l_otc_cust_relate_tab.DELETE;
            EXIT WHEN c_cust_relate%NOTFOUND;
         END LOOP;
         CLOSE c_cust_relate; 
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables. 
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);
        
        -- IF Customer Cursor is Open Close the same
        IF c_cust_relate%ISOPEN
        THEN
             CLOSE c_cust_relate;
        END IF;
        
        OPEN c_cust_relate;

        FETCH c_cust_relate
        BULK COLLECT INTO l_otc_cust_relate_tab;
        
        FOR i IN 1 .. l_otc_cust_relate_tab.COUNT
        LOOP
            BEGIN
                l_otc_cust_relate_rec   := g_miss_cust_relate_rec;
                l_cust_acct_relate_rec  := g_miss_cust_acct_relate_rec;
                
                SAVEPOINT skip_transaction;
                
                l_otc_cust_relate_rec := l_otc_cust_relate_tab (i);
                l_otc_cust_relate_rec.phase_code := g_stage;
                
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_otc_cust_relate_rec.RECORD_NUMBER);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                IF  l_otc_cust_relate_rec.API_TYPE = 'ACCOUNT' THEN 
                   
                    IF NOT customer_derivations (p_cust_rec      => l_otc_cust_relate_rec)
                    THEN
                       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'customer_derivations Failed');
                       RAISE e_cust_relate_exception;
                    END IF; -- customer_derivations
                    
                    IF init_cust_acct_relate (l_cust_acct_relate_rec,l_otc_cust_relate_rec) 
                    THEN
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_cust_acct_relate Successful');
                        IF create_cust_acct_relate (l_cust_acct_relate_rec,l_otc_cust_relate_rec) 
                        THEN 
                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_cust_acct_relate Successful');  
                        ELSE -- create_cust_acct_relate                                           
                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_cust_acct_relate Failed');
                            RAISE e_cust_relate_exception;
                        END IF;
                    ELSE
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_cust_acct_relate Failed');
                        RAISE e_cust_relate_exception;
                    END IF; -- init_cust_acct_relate
                    
                ELSIF  l_otc_cust_relate_rec.API_TYPE = 'PARTY' THEN
                
                    IF NOT party_derivations (p_cust_rec      => l_otc_cust_relate_rec)
                    THEN
                       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'party_derivations Failed');
                       RAISE e_cust_relate_exception;
                    END IF; -- party_derivations
                    
                    IF init_relation (l_org_contact_rec,l_otc_cust_relate_rec) 
                    THEN
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_relation Successful');
                        
                        IF create_relation (l_org_contact_rec,l_otc_cust_relate_rec) 
                        THEN 
                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_relation Successful');  
                        ELSE                                            
                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_relation Failed');
                            RAISE e_cust_relate_exception;
                        END IF; -- create_relation
                       
                    ELSE
                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_relation Failed');
                        RAISE e_cust_relate_exception;
                    END IF; -- init_relation  
                      
                END IF; -- API_TYPE validation
                
                l_otc_cust_relate_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_otc_cust_relate_rec.error_msg  := NULL;
                IF update_cust_relate_stg (l_otc_cust_relate_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_cust_relate_stg updated');
                END IF;

                COMMIT;             
            EXCEPTION
            WHEN e_cust_relate_exception 
            THEN
                l_otc_cust_relate_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_cust_relate_stg (l_otc_cust_relate_rec,p_batch_id) 
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_relate_stg updated');    
                END IF;
                --xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                --ROLLBACK TO SAVEPOINT skip_transaction;
            END;
        END LOOP;
        
        l_otc_cust_relate_tab.DELETE;
        CLOSE c_cust_relate;    
                            
     END IF;  -- Validate and Load Condition   

     update_cnt;
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
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS '||SQLERRM);
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.create_report;
END main;

END xx_ar_cust_relate_pkg;
/
