DROP PACKAGE BODY APPS.XX_AR_CUST_ATTACH_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_CUST_ATTACH_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 17-Jun-2013
 File Name      : XXARCUSTATT.pkb
 Description    : This script creates the body of the package XX_AR_CUST_ATTACH_PKG
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
17-June-2013     ABhargava    Initial development.
01-Aug-2013      ABhargava    Commented the logic to fetch BLOB data as it is being transmitted directly
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
    UPDATE XX_AR_CUST_ATTACH
    set REQUEST_ID = xx_emf_pkg.G_REQUEST_ID
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
PROCEDURE update_cust_record_status ( p_cust_rel_rec   IN OUT  g_xx_ar_cust_att_rec_type,
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
FUNCTION update_cust_attach_stg (
                                  p_stage_rec   IN OUT NOCOPY   xxconv.XX_AR_CUST_attach%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                                 )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'update_cust_attach_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    UPDATE XX_AR_CUST_ATTACH
    SET  BATCH_ID                   = p_stage_rec.BATCH_ID
        ,SOURCE_SYSTEM_NAME         = p_stage_rec.SOURCE_SYSTEM_NAME
        ,DOCUMENT_ID                = p_stage_rec.DOCUMENT_ID
        ,ATTACHED_DOCUMENT_ID       = p_stage_rec.ATTACHED_DOCUMENT_ID
        ,MEDIA_ID                   = p_stage_rec.MEDIA_ID
        ,ENTITY_NAME                = p_stage_rec.ENTITY_NAME
        ,DOCUMENT_ENTITY_ID         = p_stage_rec.DOCUMENT_ENTITY_ID
        ,ACCOUNT_NUMBER             = p_stage_rec.ACCOUNT_NUMBER
        ,CUST_ACCOUNT_ID            = p_stage_rec.CUST_ACCOUNT_ID
        ,SEQ_NUM                    = p_stage_rec.SEQ_NUM
        ,DATATYPE_NAME              = p_stage_rec.DATATYPE_NAME
        ,DATATYPE_ID                = p_stage_rec.DATATYPE_ID
        ,CATEGORY_NAME              = p_stage_rec.CATEGORY_NAME
        ,CATEGORY_ID                = p_stage_rec.CATEGORY_ID
        ,SECURITY_TYPE              = p_stage_rec.SECURITY_TYPE
        ,TITLE                      = p_stage_rec.TITLE
        ,DESCRIPTION                = p_stage_rec.DESCRIPTION
        ,URL                        = p_stage_rec.URL
        ,SHORT_TEXT                 = p_stage_rec.SHORT_TEXT
        ,LONG_TEXT                  = p_stage_rec.LONG_TEXT
        ,FILE_NAME                  = p_stage_rec.FILE_NAME
        ,ATTRIBUTE_CATEGORY         = p_stage_rec.ATTRIBUTE_CATEGORY
        ,ATTRIBUTE1                 = p_stage_rec.ATTRIBUTE1
        ,ATTRIBUTE2                 = p_stage_rec.ATTRIBUTE2
        ,ATTRIBUTE3                 = p_stage_rec.ATTRIBUTE3
        ,ATTRIBUTE4                 = p_stage_rec.ATTRIBUTE4
        ,ATTRIBUTE5                 = p_stage_rec.ATTRIBUTE5
        ,ATTRIBUTE6                 = p_stage_rec.ATTRIBUTE6
        ,ATTRIBUTE7                 = p_stage_rec.ATTRIBUTE7
        ,ATTRIBUTE8                 = p_stage_rec.ATTRIBUTE8
        ,ATTRIBUTE9                 = p_stage_rec.ATTRIBUTE9
        ,ATTRIBUTE10                = p_stage_rec.ATTRIBUTE10
        ,RECORD_NUMBER              = p_stage_rec.RECORD_NUMBER
        ,REQUEST_ID                 = xx_emf_pkg.G_REQUEST_ID
        ,LAST_UPDATED_BY            = x_last_updated_by
        ,LAST_UPDATE_DATE           = x_last_update_date
        ,PHASE_CODE                 = p_stage_rec.PHASE_CODE
        ,ERROR_CODE                 = p_stage_rec.ERROR_CODE
        ,ERROR_MSG                  = p_stage_rec.ERROR_MSG
    WHERE batch_id          =   p_batch_id
    and   record_number     =   p_stage_rec.record_number
    and   ACCOUNT_NUMBER    =   p_stage_rec.ACCOUNT_NUMBER
    and   SEQ_NUM           =   p_stage_rec.SEQ_NUM;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    COMMIT;
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_cust_attach_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_cust_attach_stg;


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
    from XX_AR_CUST_ATTACH
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID;

    select count(1)
    into l_suc
    from XX_AR_CUST_ATTACH
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '0';

    select count(1)
    into l_err
    from XX_AR_CUST_ATTACH
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
FUNCTION doc_derivations (p_doc_rec   IN OUT NOCOPY   xxconv.XX_AR_CUST_ATTACH%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
BEGIN
    g_api_name := 'doc_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    -- Deriving Cust Account ID
    BEGIN
        select cust_account_id
        into p_doc_rec.CUST_ACCOUNT_ID
        from hz_cust_accounts_all
        where orig_system_reference = p_doc_rec.account_number;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Customer for A/C NUMBER :'||p_doc_rec.account_number);
        l_msg := 'Error Deriving Customer for A/C NUMBER ';
        RAISE l_error_transaction;
    END;

    -- Deriving Data Type ID
    BEGIN
        select DATATYPE_ID
        into p_doc_rec.DATATYPE_ID
        from FND_DOCUMENT_DATATYPES
        where UPPER(NAME) = p_doc_rec.DATATYPE_NAME
        and language = 'US';
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Data Type ID for  :'||p_doc_rec.DATATYPE_NAME);
        l_msg := 'Error Deriving Data Type ID for  :'||p_doc_rec.DATATYPE_NAME;
        RAISE l_error_transaction;
    END;

    -- Deriving Category  ID
    BEGIN
        select CATEGORY_ID
        into p_doc_rec.CATEGORY_ID
        from FND_DOCUMENT_CATEGORIES
        where UPPER(NAME) = p_doc_rec.CATEGORY_NAME;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Category ID for  :'||p_doc_rec.CATEGORY_NAME);
        l_msg := 'Error Deriving Category ID for  :'||p_doc_rec.CATEGORY_NAME;
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
     p_doc_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_doc_rec.error_msg   := g_api_name || ': ' || l_msg;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg,
                       p_doc_rec.record_number,
                       p_doc_rec.account_number,
                       p_doc_rec.DATATYPE_NAME
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'doc_derivations Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_doc_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_doc_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_doc_rec.record_number,
                       p_doc_rec.account_number,
                       p_doc_rec.DATATYPE_NAME
                      );
     RETURN FALSE;
END doc_derivations;


-------------------------------------------------------------------------------------
---------------------------------- Attach File --------------------------------------
-------------------------------------------------------------------------------------
FUNCTION doc_attach (p_doc_rec   IN OUT NOCOPY   xxconv.XX_AR_CUST_ATTACH%ROWTYPE)
      RETURN BOOLEAN
IS
  --PRAGMA AUTONOMOUS_TRANSACTION;
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);


  l_rowid                   ROWID;
  l_attached_document_id    NUMBER;
  l_document_id             NUMBER;
  l_media_id                NUMBER;

  l_dir_name                VARCHAR2(100);
  l_fils                    BFILE;
  blob_length               INTEGER;
  x_blob                    BLOB;

BEGIN
    g_api_name := 'doc_attach';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    BEGIN
        l_msg := 'Error Deriving Document ID';
        select FND_DOCUMENTS_S.nextval
        into   l_document_id
        from   dual;

        l_msg := 'Error Deriving Attached Document ID';
        select FND_ATTACHED_DOCUMENTS_S.nextval
        into   l_attached_document_id
        from   dual;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg);
        RAISE l_error_transaction;
    END;

    IF p_doc_rec.DATATYPE_NAME = 'FILE' THEN
    BEGIN
        l_msg:= 'Error Deriving Media ID ';
        SELECT MAX (file_id) + 1
        INTO l_media_id
        FROM fnd_lobs;
        /*
        l_msg:= 'Error Deriving Database Directory Name ';
        select PARAMETER_VALUE
        into l_dir_name
        from  xx_emf_process_setup a
             ,xx_emf_process_parameters b
        where a.process_id = b.process_id
        and   a.process_name = 'XXARCUSTATT'
        and   b.PARAMETER_NAME = 'DIR_NAME';

        l_msg:= 'Error Deriving BFILENAME ';
        l_fils :=  BFILENAME (l_dir_name, p_doc_rec.file_name);

        l_msg:= 'Error Deriving Size of BLOB File';
        -- Obtain the size of the blob file
        DBMS_LOB.fileopen (l_fils, DBMS_LOB.file_readonly);
        blob_length := DBMS_LOB.getlength (l_fils);
        DBMS_LOB.fileclose (l_fils);
        */

        -- Insert a new record into the table containing the
        -- filename you have specified and a LOB LOCATOR.
        -- Return the LOB LOCATOR and assign it to x_blob.
        l_msg:= 'Error Inserting New Record in FND_LOBS ';
        INSERT INTO fnd_lobs
        (file_id, file_name, file_content_type, upload_date,
        expiration_date, program_name, program_tag, file_data,
        LANGUAGE, oracle_charset, file_format
        )
        VALUES (l_media_id, p_doc_rec.file_name,p_doc_rec.file_content_type,SYSDATE,
        NULL, NULL, NULL, p_doc_rec.file_data, --EMPTY BLOB()
        'US', 'UTF8', 'binary'
        )
        RETURNING file_data
        INTO x_blob;

        /*
        -- Load the file into the database as a BLOB
        l_msg:= 'Error Loading File Into DB as BLOB ';
        DBMS_LOB.OPEN (l_fils, DBMS_LOB.lob_readonly);
        DBMS_LOB.OPEN (x_blob, DBMS_LOB.lob_readwrite);
        DBMS_LOB.loadfromfile (x_blob, l_fils, blob_length);
        -- Close handles to blob and file
        DBMS_LOB.CLOSE (x_blob);
        DBMS_LOB.CLOSE (l_fils);
        */
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'FND_LOBS File Id Created is ' || l_media_id);

        --COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg);
        l_msg := l_msg||' '||SQLERRM;
        --DBMS_LOB.CLOSE (x_blob);
        --DBMS_LOB.CLOSE (l_fils);
        RAISE l_error_transaction;
    END;
    END IF;



    BEGIN
        l_msg := 'Error Inserting Data using fnd_documents_pkg.insert_row';

        fnd_documents_pkg.insert_row
                            ( X_ROWID                        => l_rowid
                            , X_DOCUMENT_ID                  => l_document_id
                            , X_CREATION_DATE                => sysdate
                            , X_CREATED_BY                   => fnd_profile.value('USER_ID')
                            , X_LAST_UPDATE_DATE             => sysdate
                            , X_LAST_UPDATED_BY              => fnd_profile.value('USER_ID')
                            , X_LAST_UPDATE_LOGIN            => fnd_profile.value('LOGIN_ID')
                            , X_DATATYPE_ID                  => p_doc_rec.DATATYPE_ID
                            , X_CATEGORY_ID                  => p_doc_rec.CATEGORY_ID
                            , X_SECURITY_TYPE                => p_doc_rec.SECURITY_TYPE
                            , X_PUBLISH_FLAG                 => 'Y'
                            , X_USAGE_TYPE                   => 'O'
                            , X_LANGUAGE                     => 'US'
                            , X_TITLE                        => p_doc_rec.TITLE
                            , X_DESCRIPTION                  => p_doc_rec.DESCRIPTION
                            , X_FILE_NAME                    => p_doc_rec.FILE_NAME
                            , X_URL                          => p_doc_rec.URL
                            , X_MEDIA_ID                     => l_media_id
                            );

        IF p_doc_rec.DATATYPE_NAME = 'SHORT_TEXT'
        THEN
            l_msg := 'Error Inserting Data Into fnd_documents_short_text';

            INSERT INTO fnd_documents_short_text (media_id,short_text)
            VALUES(l_media_id,p_doc_rec.SHORT_TEXT);

           -- COMMIT;
        ELSIF  p_doc_rec.DATATYPE_NAME = 'LONG_TEXT'
        THEN
            l_msg := 'Error Inserting Data Into fnd_documents_short_text';

            INSERT INTO fnd_documents_long_text (media_id,long_text)
            VALUES(l_media_id,p_doc_rec.LONG_TEXT);

          --  COMMIT;
        END IF;

        l_msg := 'Error Inserting Data using fnd_documents_pkg.insert_tl_row';
        fnd_documents_pkg.insert_tl_row
                        ( X_DOCUMENT_ID                  => l_document_id
                        , X_CREATION_DATE                => sysdate
                        , X_CREATED_BY                   => fnd_profile.value('USER_ID')
                        , X_LAST_UPDATE_DATE             => sysdate
                        , X_LAST_UPDATED_BY              => fnd_profile.value('USER_ID')
                        , X_LAST_UPDATE_LOGIN            => fnd_profile.value('LOGIN_ID')
                        , X_LANGUAGE                     => 'US'
                        , X_DESCRIPTION                  => p_doc_rec.DESCRIPTION
                        );

         l_msg := 'Error Inserting Data using fnd_attached_documents_pkg.insert_row';
         fnd_attached_documents_pkg.insert_row
                        ( X_ROWID                        => l_rowid
                        , X_ATTACHED_DOCUMENT_ID         => l_attached_document_id
                        , X_DOCUMENT_ID                  => l_document_id
                        , X_CREATION_DATE                => sysdate
                        , X_CREATED_BY                   => fnd_profile.value('USER_ID')
                        , X_LAST_UPDATE_DATE             => sysdate
                        , X_LAST_UPDATED_BY              => fnd_profile.value('USER_ID')
                        , X_LAST_UPDATE_LOGIN            => fnd_profile.value('LOGIN_ID')
                        , X_SEQ_NUM                      => p_doc_rec.SEQ_NUM
                        , X_ENTITY_NAME                  => p_doc_rec.ENTITY_NAME
                        , X_COLUMN1                      => NULL
                        , X_PK1_VALUE                    => p_doc_rec.CUST_ACCOUNT_ID
                        , X_PK2_VALUE                    => NULL
                        , X_PK3_VALUE                    => NULL
                        , X_PK4_VALUE                    => NULL
                        , X_PK5_VALUE                    => NULL
                        , X_AUTOMATICALLY_ADDED_FLAG     => 'N'
                        , X_DATATYPE_ID                  => p_doc_rec.DATATYPE_ID
                        , X_CATEGORY_ID                  => p_doc_rec.CATEGORY_ID
                        , X_SECURITY_TYPE                => p_doc_rec.SECURITY_TYPE
                        , X_PUBLISH_FLAG                 => 'Y'
                        , X_LANGUAGE                     => 'US'
                        , X_DESCRIPTION                  => p_doc_rec.DESCRIPTION
                        , X_MEDIA_ID                     => l_media_id
                        );

        p_doc_rec.DOCUMENT_ID           :=  l_document_id;
        p_doc_rec.ATTACHED_DOCUMENT_ID  :=  l_attached_document_id;
        p_doc_rec.MEDIA_ID              :=  l_media_id;

    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg||' '||SQLERRM);
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
     p_doc_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_doc_rec.error_msg   := g_api_name || ': ' || l_msg||' '||SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg||' '||SQLERRM,
                       p_doc_rec.record_number,
                       p_doc_rec.account_number,
                       p_doc_rec.DATATYPE_NAME
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'doc_attach Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_doc_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_doc_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_doc_rec.record_number,
                       p_doc_rec.account_number,
                       p_doc_rec.DATATYPE_NAME
                      );
     RETURN FALSE;
END doc_attach;
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

CURSOR c_cust_attach
IS
  select *
  from XX_AR_CUST_Attach
  WHERE batch_id = p_batch_id
  AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR )
       OR
        (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));


  x_error_code              NUMBER := xx_emf_cn_pkg.cn_success;
  l_otc_cust_attach_tab     xx_otc_cust_attach_tab_type;
  l_otc_cust_attach_rec     xxconv.XX_AR_CUST_ATTACH%ROWTYPE;

  e_cust_attach_exception   EXCEPTION;

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
         OPEN c_cust_attach;
         LOOP
            FETCH c_cust_attach
            BULK COLLECT INTO l_otc_cust_attach_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. l_otc_cust_attach_tab.COUNT
            LOOP
                l_otc_cust_attach_rec := l_otc_cust_attach_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion Customer for '||l_otc_cust_attach_rec.ACCOUNT_NUMBER);
                x_error_code  := xx_ar_cust_attach_val_pkg.data_validations_att(l_otc_cust_attach_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_otc_cust_attach_rec.record_number||'  is ' || x_error_code);
                l_otc_cust_attach_rec.phase_code := G_STAGE;
                l_otc_cust_attach_rec.error_code := x_error_code;
                IF update_cust_attach_stg (l_otc_cust_attach_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_attach_stg updated');
                ELSE
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_attach_stg update FAILED');
                END IF;
            END LOOP;
            l_otc_cust_attach_tab.DELETE;
            EXIT WHEN c_cust_attach%NOTFOUND;
         END LOOP;
         CLOSE c_cust_attach;
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables.
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        -- IF Customer Cursor is Open Close the same
        IF c_cust_attach%ISOPEN
        THEN
             CLOSE c_cust_attach;
        END IF;

        OPEN c_cust_attach;

        FETCH c_cust_attach
        BULK COLLECT INTO l_otc_cust_attach_tab;

        FOR i IN 1 .. l_otc_cust_attach_tab.COUNT
        LOOP
            BEGIN
                SAVEPOINT skip_transaction;

                l_otc_cust_attach_rec := l_otc_cust_attach_tab (i);
                l_otc_cust_attach_rec.phase_code := g_stage;

                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_otc_cust_attach_rec.RECORD_NUMBER);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));

                IF NOT doc_derivations (p_doc_rec => l_otc_cust_attach_rec)
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'doc_derivations Failed');
                   RAISE e_cust_attach_exception;
                END IF; -- doc_derivations

                IF NOT doc_attach (p_doc_rec => l_otc_cust_attach_rec)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'doc_attach Failed');
                   RAISE e_cust_attach_exception;
                END IF; -- doc_attach

                l_otc_cust_attach_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_otc_cust_attach_rec.error_msg  := NULL;
                IF update_cust_attach_stg (l_otc_cust_attach_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_cust_attach_stg updated');
                END IF;

                COMMIT;
            EXCEPTION
            WHEN e_cust_attach_exception
            THEN
                l_otc_cust_attach_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_cust_attach_stg (l_otc_cust_attach_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'cust_attach_stg updated');
                END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction;
            END;
        END LOOP;

        l_otc_cust_attach_tab.DELETE;
        CLOSE c_cust_attach;

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
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS');
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.create_report;
END main;

END xx_ar_cust_attach_pkg;
/
