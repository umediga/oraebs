DROP PACKAGE BODY APPS.XX_AR_CUSTCONT_LOAD_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_CUSTCONT_LOAD_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 14-May-2013
 File Name      : XXARCUSTCONTLOAD.pkb
 Description    : This script creates the body of the package xx_ar_custcont_load_pkg
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
    UPDATE XX_AR_CONTACT_STG
    set REQUEST_ID = xx_emf_pkg.G_REQUEST_ID
       ,ERROR_CODE = xx_emf_cn_pkg.CN_NULL
       ,PHASE_CODE = xx_emf_cn_pkg.CN_NEW
    WHERE batch_id = p_batch_id
    AND   (p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR ) = xx_emf_cn_pkg.CN_REC_ERR )
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS));

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
------------< Update Customer Contact Error Code Status >------------
--------------------------------------------------------------------------------
PROCEDURE update_cont_record_status ( p_conv_cont_rec  IN OUT  g_xx_ar_cust_cont_rec_type,
                                      p_error_code     IN      VARCHAR2
                                    ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_cont_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_conv_cont_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_conv_cont_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_conv_cont_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_cont_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_cont_record_status '||SQLERRM);
END update_cont_record_status;

--------------------------------------------------------------------------------
------------< Mark Customer Contact Records Complete >------------
--------------------------------------------------------------------------------
PROCEDURE mark_cont_rec_complete (p_process_code   IN   VARCHAR2,
                                  p_conv_cont_rec  IN   g_xx_ar_cust_cont_rec_type
                                 ) IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;

    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of mark_cont_rec_complete');

    update xx_ar_contact_stg
    set phase_code        = G_STAGE
       ,ERROR_CODE        = p_conv_cont_rec.error_code
       ,last_updated_by   = x_last_updated_by
       ,last_update_date  = x_last_update_date
    WHERE batch_id      = G_BATCH_ID
    AND request_id      = xx_emf_pkg.G_REQUEST_ID
    AND orig_system_ref = p_conv_cont_rec.orig_system_ref
    AND ORIG_SYS_ADDR_REF     = p_conv_cont_rec.ORIG_SYS_ADDR_REF
    AND ORIG_SYS_CONTACT_REF  = p_conv_cont_rec.ORIG_SYS_CONTACT_REF;

    COMMIT;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of mark_cont_rec_complete');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in Update of mark_cont_rec_complete '||SQLERRM);
END mark_cont_rec_complete;

FUNCTION update_cust_cont_cnv_stg (
                                   p_stage_rec   IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                                 , p_batch_id    IN              VARCHAR2
                                    )
  RETURN BOOLEAN
IS
  x_last_update_date       DATE   := SYSDATE;
  x_last_updated_by        NUMBER := fnd_global.user_id;
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'update_cust_cont_cnv_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));



    UPDATE xxconv.xx_ar_contact_stg
     SET batch_id               = p_stage_rec.batch_id
       , orig_system_ref        = p_stage_rec.orig_system_ref
       , orig_sys_addr_ref      = p_stage_rec.orig_sys_addr_ref
       , orig_sys_contact_ref   = p_stage_rec.orig_sys_contact_ref
       , contact_type           = p_stage_rec.contact_type
       , contact_id             = p_stage_rec.contact_id
       , party_rel_id           = p_stage_rec.party_rel_id
       , customer_id            = p_stage_rec.customer_id
       , job_title              = p_stage_rec.job_title
       , department_code        = p_stage_rec.department_code
       , pre_name               = p_stage_rec.pre_name
       , first_name             = p_stage_rec.first_name
       , middle_name            = p_stage_rec.middle_name
       , last_name              = p_stage_rec.last_name
       , address_id             = p_stage_rec.address_id
       , address1               = p_stage_rec.address1
       , address2               = p_stage_rec.address2
       , address3               = p_stage_rec.address3
       , address4               = p_stage_rec.address4
       , city                   = p_stage_rec.city
       , state                  = p_stage_rec.state
       , postal_code            = p_stage_rec.postal_code
       , county                 = p_stage_rec.county
       , province               = p_stage_rec.province
       , country                = p_stage_rec.country
       , country_code           = p_stage_rec.country_code
       , mail_stop              = p_stage_rec.mail_stop
       , phone_purpose          = p_stage_rec.phone_purpose
       , phone                  = p_stage_rec.phone
       , phone_ext              = p_stage_rec.phone_ext
       , fax_purpose            = p_stage_rec.fax_purpose
       , fax                    = p_stage_rec.fax
       , mobile                 = p_stage_rec.mobile
       , email_purpose          = p_stage_rec.email_purpose
       , email                  = p_stage_rec.email
       , usage_type             = p_stage_rec.usage_type
       , org_comp_code          = p_stage_rec.org_comp_code
       , party_id               = p_stage_rec.party_id
       , party_id2              = p_stage_rec.party_id2
       , party_site_id          = p_stage_rec.party_site_id
       , party_site_number      = p_stage_rec.party_site_number
       , cust_account_role_id   = p_stage_rec.cust_account_role_id
       , responsibility_type    = p_stage_rec.responsibility_type
       , responsibility_id      = p_stage_rec.responsibility_id
       , party_number           = p_stage_rec.party_number
       , attribute_category     = p_stage_rec.attribute_category
       , attribute1             = p_stage_rec.attribute1
       , attribute2             = p_stage_rec.attribute2
       , attribute3             = p_stage_rec.attribute3
       , attribute4             = p_stage_rec.attribute4
       , attribute5             = p_stage_rec.attribute5
       , attribute6             = p_stage_rec.attribute6
       , attribute7             = p_stage_rec.attribute7
       , attribute8             = p_stage_rec.attribute8
       , attribute9             = p_stage_rec.attribute9
       , attribute10            = p_stage_rec.attribute10
       , profile_id             = p_stage_rec.profile_id
       , request_id             = xx_emf_pkg.G_REQUEST_ID
       , LAST_UPDATED_BY        = x_last_updated_by
       , LAST_UPDATE_DATE       = x_last_update_date
       , phase_code             = p_stage_rec.phase_code
       , error_code             = p_stage_rec.error_code
       , error_msg              = p_stage_rec.error_msg
   WHERE orig_system_ref        = p_stage_rec.orig_system_ref
   AND   orig_sys_contact_ref   = p_stage_rec.orig_sys_contact_ref;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  COMMIT;
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_cust_cont_cnv_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_cust_cont_cnv_stg;

FUNCTION contact_derivations (
                               p_cont_rec   IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                             , p_addr_rec   IN OUT NOCOPY   xxconv.xx_ar_address_stg%ROWTYPE
                             )
RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
BEGIN
    g_api_name := 'contact_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    p_cont_rec.responsibility_type  :=  p_cont_rec.contact_type;
    p_cont_rec.address1             := NVL (p_cont_rec.address1, 'Address1');
    p_cont_rec.country_code         := NVL (p_cont_rec.country_code, p_addr_rec.country_code);



    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'Unhandled Exception:  ' || SQLERRM);
     p_cont_rec.error_msg := g_api_name||' '||' Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       p_cont_rec.error_msg,
                       p_cont_rec.batch_id,
                       p_cont_rec.record_number,
                       p_cont_rec.ORIG_SYSTEM_REF||' - '||p_cont_rec.ORIG_SYS_CONTACT_REF
                      );
     RETURN FALSE;
END contact_derivations;

-------------------------------------------------------------------------------------
------------< Initialise PARAMETERS for Contact Person  >------------
-------------------------------------------------------------------------------------

FUNCTION init_contact_person (
                              x_create_person_rec   IN OUT NOCOPY   hz_party_v2pub.person_rec_type
                            , p_contact_rec         IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                             )
RETURN BOOLEAN
IS
   l_cnt NUMBER := 0;
BEGIN
    g_api_name := 'init_contact_person';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    x_create_person_rec.person_pre_name_adjunct := p_contact_rec.pre_name;
    x_create_person_rec.person_first_name       := p_contact_rec.first_name;
    x_create_person_rec.person_last_name        := p_contact_rec.last_name;
    x_create_person_rec.created_by_module       := g_created_by_module;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     p_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_contact_rec.batch_id,
                       p_contact_rec.record_number,
                       p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_contact_person;

-------------------------------------------------------------------------------------
--------------------------------  Create Person  ------------------------------------
-------------------------------------------------------------------------------------
FUNCTION create_contact_person (
                                p_create_person_rec   IN OUT NOCOPY   hz_party_v2pub.person_rec_type
                              , x_contact_rec         IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                               )
RETURN BOOLEAN
IS
  lx_party_id        NUMBER;
  lx_party_number    VARCHAR2 (2000);
  lx_profile_id      NUMBER;
  lx_return_status   VARCHAR2 (2000);
  lx_msg_count       NUMBER;
  lx_msg_data        VARCHAR2 (2000);
BEGIN
    g_api_name := 'create_contact_person';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    hz_party_v2pub.create_person (  p_init_msg_list      => fnd_api.g_true
                                  , p_person_rec         => p_create_person_rec
                                  , x_party_id           => lx_party_id
                                  , x_party_number       => lx_party_number
                                  , x_profile_id         => lx_profile_id
                                  , x_return_status      => lx_return_status
                                  , x_msg_count          => lx_msg_count
                                  , x_msg_data           => lx_msg_data
                                 );
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status  : ' || lx_return_status);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_id       : ' || lx_party_id);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_party_number   : ' || lx_party_number);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_profile_id     : ' || lx_profile_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_contact_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;

            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                              xx_emf_cn_pkg.CN_STG_DATADRV,
                              x_contact_rec.error_msg,
                              x_contact_rec.batch_id,
                              x_contact_rec.record_number,
                              x_contact_rec.ORIG_SYSTEM_REF
                             );

         RETURN FALSE;
      END IF;

    x_contact_rec.party_id       := lx_party_id;
    x_contact_rec.party_number   := lx_party_number;
    x_contact_rec.profile_id     := lx_profile_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     x_contact_rec.error_msg := g_api_name||' '||' Unhandled Exception:  ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                         xx_emf_cn_pkg.CN_STG_DATADRV,
                         x_contact_rec.error_msg,
                         x_contact_rec.batch_id,
                         x_contact_rec.record_number,
                         x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                        );
     RETURN FALSE;
END create_contact_person;

-------------------------------------------------------------------------------------
---------------------Initialise Parameters for Relationship -------------------------
-------------------------------------------------------------------------------------
FUNCTION init_relation (
                         x_org_contact_rec         IN OUT NOCOPY   hz_party_contact_v2pub.org_contact_rec_type
                       , p_otc_cust_hdr_cnv_rec    IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                       , p_contact_rec             IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                       )
  RETURN BOOLEAN
IS
  lx_return_status   VARCHAR2 (2000);
  lx_msg_count       NUMBER;
  lx_msg_data        VARCHAR2 (2000);
BEGIN
    g_api_name := 'init_relation';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    x_org_contact_rec.department_code                   := p_contact_rec.department_code;
    x_org_contact_rec.job_title                         := p_contact_rec.JOB_TITLE;
    x_org_contact_rec.created_by_module                 := g_created_by_module;
    x_org_contact_rec.party_rel_rec.subject_id          := p_contact_rec.party_id;
    x_org_contact_rec.party_rel_rec.subject_type        := 'PERSON';
    x_org_contact_rec.party_rel_rec.subject_table_name  := 'HZ_PARTIES';
    x_org_contact_rec.party_rel_rec.object_id           := p_otc_cust_hdr_cnv_rec.party_id;
    x_org_contact_rec.party_rel_rec.object_type         := 'ORGANIZATION';
    x_org_contact_rec.party_rel_rec.object_table_name   := 'HZ_PARTIES';
    x_org_contact_rec.party_rel_rec.relationship_code   := 'CONTACT_OF';
    x_org_contact_rec.party_rel_rec.relationship_type   := 'CONTACT';
    x_org_contact_rec.party_rel_rec.start_date          := SYSDATE;
    x_org_contact_rec.attribute_category                := p_contact_rec.attribute_category;
    x_org_contact_rec.attribute1                        := p_contact_rec.attribute1;
    x_org_contact_rec.attribute2                        := p_contact_rec.attribute2;
    x_org_contact_rec.attribute3                        := p_contact_rec.attribute3;
    x_org_contact_rec.attribute4                        := p_contact_rec.attribute4;
    x_org_contact_rec.attribute5                        := p_contact_rec.attribute5;
    x_org_contact_rec.attribute6                        := p_contact_rec.attribute6;
    x_org_contact_rec.attribute7                        := p_contact_rec.attribute7;
    x_org_contact_rec.attribute8                        := p_contact_rec.attribute8;
    x_org_contact_rec.attribute9                        := p_contact_rec.attribute9;
    x_org_contact_rec.attribute10                       := p_contact_rec.attribute10;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     p_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_contact_rec.batch_id,
                       p_contact_rec.record_number,
                       p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_relation;

-------------------------------------------------------------------------------------
         ---------------------Create Relationship -------------------------
-------------------------------------------------------------------------------------

FUNCTION create_relation (
                          p_org_contact_rec   IN OUT NOCOPY   hz_party_contact_v2pub.org_contact_rec_type
                        , x_contact_rec       IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                         )
RETURN BOOLEAN
IS
  lx_party_rel_id     NUMBER;
  lx_org_contact_id   NUMBER;
  lx_party_id         NUMBER;
  lx_party_number     VARCHAR2 (2000);
  lx_return_status    VARCHAR2 (2000);
  lx_msg_count        NUMBER;
  lx_msg_data         VARCHAR2 (2000);
BEGIN
    g_api_name := 'create_relation';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    hz_party_contact_v2pub.create_org_contact
                                 (p_init_msg_list        => fnd_api.g_true
                                , p_org_contact_rec      => p_org_contact_rec
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
            x_contact_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                              xx_emf_cn_pkg.CN_STG_DATADRV,
                              x_contact_rec.error_msg,
                              x_contact_rec.batch_id,
                              x_contact_rec.record_number,
                              x_contact_rec.ORIG_SYSTEM_REF
                             );

         RETURN FALSE;
      END IF;

    x_contact_rec.party_id2         := lx_party_id;
    x_contact_rec.party_rel_id      := lx_party_rel_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     x_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     x_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       x_contact_rec.batch_id,
                       x_contact_rec.record_number,
                       x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END create_relation;

-------------------------------------------------------------------------------------
 ---------------------Initialise Assig Contact Parameters -------------------------
-------------------------------------------------------------------------------------
FUNCTION init_assign_contact (
                              x_cr_cust_acc_role_rec    IN OUT NOCOPY   hz_cust_account_role_v2pub.cust_account_role_rec_type
                            , p_contact_rec             IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                            , p_otc_cust_hdr_cnv_rec    IN OUT NOCOPY   xxconv.xx_ar_cust_stg%ROWTYPE
                            )
RETURN BOOLEAN
IS
BEGIN
    g_api_name := 'init_assign_contact';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    x_cr_cust_acc_role_rec.party_id             := p_contact_rec.party_id2;
    x_cr_cust_acc_role_rec.cust_account_id      := p_otc_cust_hdr_cnv_rec.cust_account_id;
    x_cr_cust_acc_role_rec.cust_acct_site_id    := NULL;
    x_cr_cust_acc_role_rec.orig_system_reference:= p_contact_rec.ORIG_SYS_CONTACT_REF;
    x_cr_cust_acc_role_rec.role_type            := 'CONTACT';
    x_cr_cust_acc_role_rec.created_by_module    := g_created_by_module;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     p_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_contact_rec.batch_id,
                       p_contact_rec.record_number,
                       p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_assign_contact;

-------------------------------------------------------------------------------------
     --------------------- Assign Contact -------------------------
-------------------------------------------------------------------------------------
FUNCTION assign_contact (
                          p_cr_cust_acc_role_rec   IN OUT NOCOPY   hz_cust_account_role_v2pub.cust_account_role_rec_type
                        , x_contact_rec            IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                        )
RETURN BOOLEAN
IS
  lx_return_status          VARCHAR2 (2000);
  lx_msg_count              NUMBER;
  lx_msg_data               VARCHAR2 (2000);
  lx_cust_account_role_id   NUMBER;
BEGIN
    g_api_name := 'assign_contact';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    hz_cust_account_role_v2pub.create_cust_account_role
                      (p_init_msg_list              => 'T'
                     , p_cust_account_role_rec      => p_cr_cust_acc_role_rec
                     , x_cust_account_role_id       => lx_cust_account_role_id
                     , x_return_status              => lx_return_status
                     , x_msg_count                  => lx_msg_count
                     , x_msg_data                   => lx_msg_data
                      );

      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status  : ' || lx_return_status);
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Account_role_id   : ' || lx_cust_account_role_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_contact_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           x_contact_rec.error_msg,
                           x_contact_rec.batch_id,
                           x_contact_rec.record_number,
                           x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                          );
         RETURN FALSE;
      END IF;

    x_contact_rec.cust_account_role_id := lx_cust_account_role_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     x_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     x_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       x_contact_rec.batch_id,
                       x_contact_rec.record_number,
                       x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END assign_contact;

-------------------------------------------------------------------------------------
     --------------------- Create Contact -----------------------
-------------------------------------------------------------------------------------
FUNCTION create_contact_role (
                              p_contact_rec   IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                             )
RETURN BOOLEAN
IS
  l_role_responsibility_rec   hz_cust_account_role_v2pub.role_responsibility_rec_type;
  lx_responsibility_id        NUMBER;
  lx_return_status            VARCHAR2 (2000);
  lx_msg_count                NUMBER;
  lx_msg_data                 VARCHAR2 (2000);
BEGIN
    g_api_name := 'create_contact_role';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    l_role_responsibility_rec.cust_account_role_id:= p_contact_rec.cust_account_role_id;
    l_role_responsibility_rec.responsibility_type := p_contact_rec.responsibility_type;
    l_role_responsibility_rec.created_by_module   := g_created_by_module;

    hz_cust_account_role_v2pub.create_role_responsibility
                 (p_init_msg_list                => fnd_api.g_true
                , p_role_responsibility_rec      => l_role_responsibility_rec
                , x_responsibility_id            => lx_responsibility_id
                , x_return_status                => lx_return_status
                , x_msg_count                    => lx_msg_count
                , x_msg_data                     => lx_msg_data
                 );
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status       : ' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_responsibility_id   : ' || lx_responsibility_id);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            p_contact_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           p_contact_rec.error_msg,
                           p_contact_rec.batch_id,
                           p_contact_rec.record_number,
                           p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                          );

         RETURN FALSE;
      END IF;

    p_contact_rec.responsibility_id     := lx_responsibility_id;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     p_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_contact_rec.batch_id,
                       p_contact_rec.record_number,
                       p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END create_contact_role;

-------------------------------------------------------------------------------------
     --------------------- Create Communication  -------------------------
-------------------------------------------------------------------------------------
FUNCTION create_communication (
                                  p_contact_rec   IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                              )
  RETURN BOOLEAN
IS
  l_contact_point_rec   hz_contact_point_v2pub.contact_point_rec_type;
  l_phone_rec           hz_contact_point_v2pub.phone_rec_type;
  l_edi_rec             hz_contact_point_v2pub.edi_rec_type;
  l_email_rec           hz_contact_point_v2pub.email_rec_type;
  l_telex_rec           hz_contact_point_v2pub.telex_rec_type;
  l_web_rec             hz_contact_point_v2pub.web_rec_type;
  lx_contact_point_id   NUMBER;
  lx_return_status      VARCHAR2 (2000);
  lx_msg_count          NUMBER;
  lx_msg_data           VARCHAR2 (2000);
BEGIN
    g_api_name := 'create_communication';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    -- Create Telephone
    l_contact_point_rec   := g_miss_contact_point_rec;

      IF p_contact_rec.phone IS NOT NULL
      THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating General Phone');
         -- for contact of type phone
         l_contact_point_rec.contact_point_type     := 'PHONE';
         --to create contact at site level
         l_contact_point_rec.owner_table_name       := 'HZ_PARTIES';
         -- value for party_site_id from HZ_PARTY_SITES
         l_contact_point_rec.owner_table_id         := p_contact_rec.party_id2;
         l_contact_point_rec.created_by_module      := g_created_by_module;
         l_phone_rec.phone_number                   := p_contact_rec.phone;
         l_phone_rec.phone_extension                := p_contact_rec.phone_ext;
         l_phone_rec.phone_line_type                := 'GEN';

         hz_contact_point_v2pub.create_contact_point
                                 (p_init_msg_list          => fnd_api.g_true
                                , p_contact_point_rec      => l_contact_point_rec
                                , p_edi_rec                => l_edi_rec
                                , p_email_rec              => l_email_rec
                                , p_phone_rec              => l_phone_rec
                                , p_telex_rec              => l_telex_rec
                                , p_web_rec                => l_web_rec
                                , x_contact_point_id       => lx_contact_point_id
                                , x_return_status          => lx_return_status
                                , x_msg_count              => lx_msg_count
                                , x_msg_data               => lx_msg_data
                                 );
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status       : ' || lx_return_status);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_contact_point_id    : ' || lx_contact_point_id);

         IF lx_return_status != 'S'
         THEN
            IF NVL (lx_msg_count, 0) > 0
            THEN
               p_contact_rec.error_msg :=
                     g_api_name
                  || ': '
                  || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

               FOR i IN 1 .. lx_msg_count
               LOOP
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
               END LOOP;
            END IF;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                               xx_emf_cn_pkg.CN_STG_DATADRV,
                               p_contact_rec.error_msg,
                               p_contact_rec.batch_id,
                               p_contact_rec.record_number,
                               p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                              );

            RETURN FALSE;
         END IF;
      END IF;

    -- Create FAX
    l_contact_point_rec     := g_miss_contact_point_rec;
    lx_return_status        := NULL;

      IF p_contact_rec.fax IS NOT NULL
      THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating FAX');
         -- for contact of type phone
         l_contact_point_rec.contact_point_type     := 'PHONE';
         --to create contact at site level
         l_contact_point_rec.owner_table_name       := 'HZ_PARTIES';
         -- value for party_site_id from HZ_PARTY_SITES
         l_contact_point_rec.owner_table_id         := p_contact_rec.party_id2;
         l_contact_point_rec.created_by_module      := g_created_by_module;
         l_phone_rec.phone_number                   := p_contact_rec.fax;
         l_phone_rec.phone_line_type                := 'FAX';

         hz_contact_point_v2pub.create_contact_point
                                 (p_init_msg_list          => fnd_api.g_true
                                , p_contact_point_rec      => l_contact_point_rec
                                , p_edi_rec                => l_edi_rec
                                , p_email_rec              => l_email_rec
                                , p_phone_rec              => l_phone_rec
                                , p_telex_rec              => l_telex_rec
                                , p_web_rec                => l_web_rec
                                , x_contact_point_id       => lx_contact_point_id
                                , x_return_status          => lx_return_status
                                , x_msg_count              => lx_msg_count
                                , x_msg_data               => lx_msg_data
                                 );
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status       : ' || lx_return_status);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_contact_point_id    : ' || lx_contact_point_id);

         IF lx_return_status != 'S'
         THEN
            IF NVL (lx_msg_count, 0) > 0
            THEN
               p_contact_rec.error_msg :=
                     g_api_name
                  || ': '
                  || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

               FOR i IN 1 .. lx_msg_count
               LOOP
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
               END LOOP;
            END IF;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                               xx_emf_cn_pkg.CN_STG_DATADRV,
                               p_contact_rec.error_msg,
                               p_contact_rec.batch_id,
                               p_contact_rec.record_number,
                               p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                              );

            RETURN FALSE;
         END IF;
      END IF;

    -- Create MOBILE
    l_contact_point_rec  := g_miss_contact_point_rec;
    lx_return_status     := NULL;

      IF p_contact_rec.mobile IS NOT NULL
      THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Mobile');
         -- for contact of type phone
         l_contact_point_rec.contact_point_type     := 'PHONE';
         --to create contact at site level
         l_contact_point_rec.owner_table_name       := 'HZ_PARTIES';
         -- value for party_site_id from HZ_PARTY_SITES
         l_contact_point_rec.owner_table_id         := p_contact_rec.party_id2;
         l_contact_point_rec.created_by_module      := g_created_by_module;
         l_phone_rec.phone_number                   := p_contact_rec.mobile;
         l_phone_rec.phone_line_type                := 'MOBILE';

         hz_contact_point_v2pub.create_contact_point
                                 (p_init_msg_list          => fnd_api.g_true
                                , p_contact_point_rec      => l_contact_point_rec
                                , p_edi_rec                => l_edi_rec
                                , p_email_rec              => l_email_rec
                                , p_phone_rec              => l_phone_rec
                                , p_telex_rec              => l_telex_rec
                                , p_web_rec                => l_web_rec
                                , x_contact_point_id       => lx_contact_point_id
                                , x_return_status          => lx_return_status
                                , x_msg_count              => lx_msg_count
                                , x_msg_data               => lx_msg_data
                                 );

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status       : ' || lx_return_status);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_contact_point_id    : ' || lx_contact_point_id);

         IF lx_return_status != 'S'
         THEN
            IF NVL (lx_msg_count, 0) > 0
            THEN
               p_contact_rec.error_msg :=
                     g_api_name
                  || ': '
                  || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

               FOR i IN 1 .. lx_msg_count
               LOOP
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
               END LOOP;
            END IF;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                               xx_emf_cn_pkg.CN_STG_DATADRV,
                               p_contact_rec.error_msg,
                               p_contact_rec.batch_id,
                               p_contact_rec.record_number,
                               p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                              );

            RETURN FALSE;
         END IF;
      END IF;

    -- Create EMAIL
    l_contact_point_rec := g_miss_contact_point_rec;
    lx_return_status    := NULL;

      IF p_contact_rec.email IS NOT NULL
      THEN
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Creating Email');
         -- for contact of type phone
         l_contact_point_rec.contact_point_type     := 'EMAIL';
         --to create contact at site level
         l_contact_point_rec.owner_table_name       := 'HZ_PARTIES';
         -- value for party_site_id from HZ_PARTY_SITES
         l_contact_point_rec.owner_table_id         := p_contact_rec.party_id2;
         l_contact_point_rec.created_by_module      := g_created_by_module;
         l_email_rec.email_address                  := p_contact_rec.email;
         l_email_rec.email_format                   := 'MAILTEXT';

         hz_contact_point_v2pub.create_contact_point
                                 (p_init_msg_list          => fnd_api.g_true
                                , p_contact_point_rec      => l_contact_point_rec
                                , p_edi_rec                => l_edi_rec
                                , p_email_rec              => l_email_rec
                                , p_phone_rec              => l_phone_rec
                                , p_telex_rec              => l_telex_rec
                                , p_web_rec                => l_web_rec
                                , x_contact_point_id       => lx_contact_point_id
                                , x_return_status          => lx_return_status
                                , x_msg_count              => lx_msg_count
                                , x_msg_data               => lx_msg_data
                                 );
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_return_status       : ' || lx_return_status);
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'lx_contact_point_id    : ' || lx_contact_point_id);

         IF lx_return_status != 'S'
         THEN
            IF NVL (lx_msg_count, 0) > 0
            THEN
               p_contact_rec.error_msg :=
                     g_api_name
                  || ': '
                  || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

               FOR i IN 1 .. lx_msg_count
               LOOP
                  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
               END LOOP;
            END IF;
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                               xx_emf_cn_pkg.CN_STG_DATADRV,
                               p_contact_rec.error_msg,
                               p_contact_rec.batch_id,
                               p_contact_rec.record_number,
                               p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                              );

            RETURN FALSE;
         END IF;
      END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     p_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_contact_rec.batch_id,
                       p_contact_rec.record_number,
                       p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END create_communication;

-------------------------------------------------------------------------------------
  --------------------- Initialise Contact Location Param -------------------------
-------------------------------------------------------------------------------------
FUNCTION init_contact_location (
                                x_location_rec   IN OUT NOCOPY   hz_location_v2pub.location_rec_type
                              , p_contact_rec    IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                               )
RETURN BOOLEAN
IS
  l_otc_cust_hdr_cnv_rec   xxconv.xx_ar_cust_stg%ROWTYPE;
BEGIN
    g_api_name := 'init_contact_location';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

      IF p_contact_rec.mail_stop IS NULL
      THEN
         RETURN TRUE;
      END IF;

    x_location_rec.orig_system_reference        := NULL;
    x_location_rec.orig_system                  := NULL;
    x_location_rec.country                      := p_contact_rec.country_code;
    x_location_rec.address1                     := p_contact_rec.address1;
    x_location_rec.address2                     := p_contact_rec.address2;
    x_location_rec.address3                     := p_contact_rec.address3;
    x_location_rec.address4                     := p_contact_rec.address4;
    x_location_rec.city                         := p_contact_rec.city;
    x_location_rec.postal_code                  := p_contact_rec.postal_code;
    x_location_rec.state                        := p_contact_rec.state;
    x_location_rec.province                     := p_contact_rec.province;
    x_location_rec.county                       := p_contact_rec.county;
    x_location_rec.created_by_module            := g_created_by_module;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     p_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_contact_rec.batch_id,
                       p_contact_rec.record_number,
                       p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_contact_location;

-------------------------------------------------------------------------------------
     --------------------- Create Contact Location  -------------------------
-------------------------------------------------------------------------------------
FUNCTION create_contact_location (
                                  p_location_rec   IN OUT NOCOPY   hz_location_v2pub.location_rec_type
                                , x_contact_rec    IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                                )
RETURN BOOLEAN
IS
  lx_return_status   VARCHAR2 (1);
  lx_msg_count       NUMBER;
  lx_msg_data        VARCHAR2 (2000);
  l_location_rec     hz_location_v2pub.location_rec_type;
  lx_location_id     NUMBER;
BEGIN
    g_api_name := 'create_contact_location';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    IF x_contact_rec.mail_stop IS NULL
    THEN
       RETURN TRUE;
    END IF;

    l_location_rec   := p_location_rec;
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
            x_contact_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
               xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       x_contact_rec.batch_id,
                       x_contact_rec.record_number,
                       x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                      );
         RETURN FALSE;
      END IF;

    x_contact_rec.address_id    := lx_location_id;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     x_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     x_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       x_contact_rec.batch_id,
                       x_contact_rec.record_number,
                       x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END create_contact_location;

-------------------------------------------------------------------------------------
--------------------- Initialise Contact Party Site Params -------------------------
-------------------------------------------------------------------------------------
FUNCTION init_contact_party_site (
                                  x_party_site_rec   IN OUT NOCOPY   hz_party_site_v2pub.party_site_rec_type
                                , p_contact_rec      IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
                                 )
RETURN BOOLEAN
IS
BEGIN
    g_api_name := 'init_contact_party_site';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    IF p_contact_rec.mail_stop IS NULL
    THEN
       RETURN TRUE;
    END IF;

    x_party_site_rec.party_id                     := p_contact_rec.party_id2;
    x_party_site_rec.location_id                  := p_contact_rec.address_id;
    x_party_site_rec.identifying_address_flag     := 'Y';
    x_party_site_rec.created_by_module            := g_created_by_module;
    x_party_site_rec.mailstop                     := p_contact_rec.mail_stop;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     p_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       p_contact_rec.batch_id,
                       p_contact_rec.record_number,
                       p_contact_rec.ORIG_SYSTEM_REF||' - '||p_contact_rec.ORIG_SYS_ADDR_REF
                      );
     RETURN FALSE;
END init_contact_party_site;

-------------------------------------------------------------------------------------
    --------------------- Create Contact Party Site  -------------------------
-------------------------------------------------------------------------------------
FUNCTION create_contact_party_site (
                                    p_party_site_rec   IN OUT NOCOPY   hz_party_site_v2pub.party_site_rec_type
                                  , x_contact_rec      IN OUT NOCOPY   xxconv.xx_ar_contact_stg%ROWTYPE
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
  g_api_name := 'create_contact_party_site';
  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'');
  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,RPAD ('=', 40, '='));
  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'create_contact_party_site +');
  xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,RPAD ('=', 40, '='));

    IF x_contact_rec.mail_stop IS NULL
    THEN
         RETURN TRUE;
    END IF;

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
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'lx_return_status     :' || lx_return_status);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'lx_party_site_id     :' || lx_party_site_id);
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'lx_party_site_number :' || lx_party_site_number);

      IF lx_return_status != 'S'
      THEN
         IF NVL (lx_msg_count, 0) > 0
         THEN
            x_contact_rec.error_msg :=
               g_api_name || ': '
               || SUBSTR (fnd_msg_pub.get (1, 'F'), 1, 450);

            FOR i IN 1 .. lx_msg_count
            LOOP
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error:  ' || fnd_msg_pub.get (i, 'F'));
            END LOOP;
         END IF;
         xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                           xx_emf_cn_pkg.CN_STG_DATADRV,
                           g_api_name || ' : ' || SQLERRM,
                           x_contact_rec.batch_id,
                           x_contact_rec.record_number,
                           x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                          );
         RETURN FALSE;
      END IF;

    x_contact_rec.party_site_id         := lx_party_site_id;
    x_contact_rec.party_site_number     := lx_party_site_number;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'create_contact_party_site -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,RPAD ('=', 40, '='));
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Unhandled Exception:  ' || SQLERRM);
     x_contact_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     x_contact_rec.error_msg  := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ' : ' || SQLERRM,
                       x_contact_rec.batch_id,
                       x_contact_rec.record_number,
                       x_contact_rec.ORIG_SYSTEM_REF||' - '||x_contact_rec.ORIG_SYS_ADDR_REF
                      );
END create_contact_party_site;

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
  CURSOR c_cust_cont_cur
  IS
     SELECT *
     FROM xxconv.xx_ar_contact_stg
     WHERE batch_id = p_batch_id
     AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR ) = xx_emf_cn_pkg.CN_REC_ERR )
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS)));


      x_error_code          NUMBER                := xx_emf_cn_pkg.cn_success;

      l_otc_cust_hdr_cnv_tab     xx_otc_cust_hdr_cnv_tab_type;
      l_otc_cust_addr_cnv_tab    xx_otc_cust_addr_cnv_tab_type;
      l_otc_cust_cont_cnv_tab    xx_otc_cust_cont_cnv_tab_type;

      l_otc_cust_hdr_cnv_rec     xxconv.xx_ar_cust_stg%ROWTYPE;
      l_otc_cust_addr_cnv_rec    xxconv.xx_ar_address_stg%ROWTYPE;
      l_otc_cust_cont_cnv_rec    xxconv.xx_ar_contact_stg%ROWTYPE;

      l_cust_account_rec         hz_cust_account_v2pub.cust_account_rec_type;
      l_organization_rec         hz_party_v2pub.organization_rec_type;
      l_customer_profile_rec     hz_customer_profile_v2pub.customer_profile_rec_type;
      l_location_rec             hz_location_v2pub.location_rec_type;
      lx_cust_account_rec        hz_cust_account_v2pub.cust_account_rec_type;
      lx_organization_rec        hz_party_v2pub.organization_rec_type;
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
      e_contact_trx_exception    EXCEPTION;

BEGIN
     retcode := xx_emf_cn_pkg.CN_SUCCESS;

     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Set_cnv_env');
     set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);

     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id          '    || p_batch_id);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag      '    || p_restart_flag);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '    || p_validate_and_load);

     -- Call procedure to update records with the current request_id
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
     mark_records_for_processing(p_batch_id, p_restart_flag);


     IF p_validate_and_load = 'VALIDATE_ONLY' THEN
         set_stage (xx_emf_cn_pkg.CN_VALID);
         -- Start Data Validation
         OPEN c_cust_cont_cur;
         LOOP
            FETCH c_cust_cont_cur
            BULK COLLECT INTO l_otc_cust_cont_cnv_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. l_otc_cust_cont_cnv_tab.COUNT
            LOOP
                l_otc_cust_cont_cnv_rec := l_otc_cust_cont_cnv_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, '**********************************');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion Customer for '||l_otc_cust_cont_cnv_rec.ORIG_SYSTEM_REF||' - ' ||l_otc_cust_cont_cnv_rec.ORIG_SYS_CONTACT_REF);
                x_error_code  := xx_ar_customer_val_pkg.data_validations_contact(l_otc_cust_cont_cnv_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_otc_cust_cont_cnv_rec.record_number||'  is ' || x_error_code);
                update_cont_record_status (l_otc_cust_cont_cnv_rec, x_error_code);
                mark_cont_rec_complete(xx_emf_cn_pkg.CN_VALID,l_otc_cust_cont_cnv_rec);
            END LOOP;

            l_otc_cust_cont_cnv_tab.DELETE;
            EXIT WHEN c_cust_cont_cur%NOTFOUND;
         END LOOP;
         CLOSE c_cust_cont_cur;

    ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
        -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables.
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        -- IF Customer Cursor is Open Close the same
        IF c_cust_cont_cur%ISOPEN
        THEN
             CLOSE c_cust_cont_cur;
        END IF;

        OPEN c_cust_cont_cur;

        FETCH c_cust_cont_cur
        BULK COLLECT INTO l_otc_cust_cont_cnv_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

        FOR k IN 1 .. l_otc_cust_cont_cnv_tab.COUNT
        LOOP
            BEGIN

               l_otc_cust_cont_cnv_rec            := g_miss_cust_cont_cnv_rec;
               l_create_person_rec                := g_miss_create_person_rec;
               l_org_contact_rec                  := g_miss_org_contact_rec;
               l_cr_cust_acc_role_rec             := g_miss_cr_cust_acc_role_rec;

               SAVEPOINT skip_transaction;

               l_otc_cust_cont_cnv_rec            := l_otc_cust_cont_cnv_tab(k);
               l_otc_cust_cont_cnv_rec.phase_code := g_stage;

               IF NOT contact_derivations(
                                          p_cont_rec      => l_otc_cust_cont_cnv_rec
                                        , p_addr_rec      => l_otc_cust_addr_cnv_rec
                                         )
               THEN
                    RAISE e_contact_trx_exception;
               END IF;

               select *
               into l_otc_cust_hdr_cnv_rec
               from xx_ar_cust_stg
               where orig_system_ref = l_otc_cust_cont_cnv_rec.ORIG_SYSTEM_REF;



               IF init_contact_person(
                                      x_create_person_rec      => l_create_person_rec
                                    , p_contact_rec            => l_otc_cust_cont_cnv_rec
                                     )
               THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_contact_person Successful');
                   IF create_contact_person(
                                            p_create_person_rec      => l_create_person_rec
                                          , x_contact_rec            => l_otc_cust_cont_cnv_rec
                                            )
                   THEN
                       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_contact_person Successful');
                       IF init_relation(
                                        x_org_contact_rec            => l_org_contact_rec
                                      , p_otc_cust_hdr_cnv_rec       => l_otc_cust_hdr_cnv_rec
                                      , p_contact_rec                => l_otc_cust_cont_cnv_rec
                                       )
                       THEN
                           xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_relation Successful');
                           IF create_relation(
                                              p_org_contact_rec      => l_org_contact_rec
                                            , x_contact_rec          => l_otc_cust_cont_cnv_rec
                                             )
                           THEN
                               xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_relation Successful');
                               IF init_assign_contact(
                                                      x_cr_cust_acc_role_rec       => l_cr_cust_acc_role_rec
                                                    , p_contact_rec                => l_otc_cust_cont_cnv_rec
                                                    , p_otc_cust_hdr_cnv_rec       => l_otc_cust_hdr_cnv_rec
                                                     )
                               THEN
                                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_assign_contact Successful');
                                   IF assign_contact(
                                                     p_cr_cust_acc_role_rec      => l_cr_cust_acc_role_rec
                                                   , x_contact_rec               => l_otc_cust_cont_cnv_rec
                                                    )
                                   THEN
                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'assign_contact Successful');
                                        IF create_contact_role(
                                                               p_contact_rec      => l_otc_cust_cont_cnv_rec
                                                              )
                                        THEN

                                            IF create_communication(
                                                                    p_contact_rec      => l_otc_cust_cont_cnv_rec
                                                                   )
                                            THEN
                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_communication Successful');
                                                l_location_rec      :=g_miss_location_rec;
                                                IF init_contact_location(
                                                                        x_location_rec      => l_location_rec
                                                                      , p_contact_rec       => l_otc_cust_cont_cnv_rec
                                                                        )
                                                THEN
                                                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_contact_location Successful');
                                                    IF create_contact_location(
                                                                               p_location_rec      => l_location_rec
                                                                             , x_contact_rec       => l_otc_cust_cont_cnv_rec
                                                                               )
                                                    THEN
                                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_contact_location Successful');
                                                        IF init_contact_party_site(
                                                                                   x_party_site_rec      => l_party_site_rec
                                                                                 , p_contact_rec         => l_otc_cust_cont_cnv_rec
                                                                                  )
                                                        THEN
                                                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_contact_party_site Successful');
                                                            IF create_contact_party_site(
                                                                                        p_party_site_rec      => l_party_site_rec
                                                                                      , x_contact_rec         => l_otc_cust_cont_cnv_rec
                                                                                        )
                                                            THEN
                                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_contact_party_site Successful');
                                                            ELSE -- create_contact_party_site
                                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_contact_party_site Failed');
                                                                RAISE e_contact_trx_exception;

                                                            END IF; -- create_contact_party_site

                                                        ELSE -- init_contact_party_site

                                                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_contact_party_site Failed');
                                                            RAISE e_contact_trx_exception;

                                                        END IF;  -- init_contact_party_site

                                                    ELSE  -- create_contact_location
                                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_contact_location Failed');
                                                        RAISE e_contact_trx_exception;

                                                    END IF; -- create_contact_location

                                                ELSE -- init_contact_location
                                                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_contact_location Failed');
                                                    RAISE e_contact_trx_exception;

                                                END IF; -- init_contact_location
                                            ELSE -- create_communication

                                                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_communication Failed');
                                                RAISE e_contact_trx_exception;

                                            END IF; -- create_communication

                                        ELSE -- create_contact_role
                                            xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_contact_role Failed');
                                            RAISE e_contact_trx_exception;

                                        END IF; -- create_contact_role
                                   ELSE -- assign_contact

                                        xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'assign_contact Failed');
                                        RAISE e_contact_trx_exception;

                                   END IF; -- assign_contact
                               ELSE -- init_assign_contact

                                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'assign_contact Failed');
                                   RAISE e_contact_trx_exception;

                               END IF; -- init_assign_contact

                           ELSE -- create_relation

                                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_relation Failed');
                                RAISE e_contact_trx_exception;

                           END IF; -- create_relation
                      ELSE -- init_relation

                           xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'init_relation Failed');
                           RAISE e_contact_trx_exception;

                      END IF; -- init_relation


                   ELSE -- create_contact_person

                       xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_contact_person Failed');
                       RAISE e_contact_trx_exception;

                   END  IF; -- create_contact_person
               ELSE -- init_contact_person

                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'create_contact_person Failed');
                   RAISE e_contact_trx_exception;

               END IF;  -- init_contact_person

               l_otc_cust_cont_cnv_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
               l_otc_cust_cont_cnv_rec.error_msg  := NULL;
               l_otc_cust_cont_cnv_rec.phase_code := g_stage;

               IF update_cust_cont_cnv_stg(l_otc_cust_cont_cnv_rec,p_batch_id)
               THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_cont_cnv_stg updated');
               END IF;


            EXCEPTION
            WHEN e_contact_trx_exception
            THEN
                l_otc_cust_cont_cnv_rec.error_code  := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_cust_cont_cnv_stg(l_otc_cust_cont_cnv_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_cont_cnv_stg updated');
                END IF;

                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction;

            END;
        END LOOP; -- l_otc_cust_hdr_cnv_tab

        l_otc_cust_cont_cnv_tab.DELETE;
        CLOSE c_cust_cont_cur;

    END IF;
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

END xx_ar_custcont_load_pkg;
/
