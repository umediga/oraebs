DROP PACKAGE BODY APPS.XX_ONT_SO_ATTACH_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_ont_so_attach_pkg
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 23-Sep-2013
 File Name      : XXONTSOATT.pkb
 Description    : This script creates the body of the package xx_ont_so_attach_pkg
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
23-Sep-2013     ABhargava    Initial development.
13-May-2015     Deepta N     Modified to include attachments for PO
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
    UPDATE XX_ONT_SO_ATTACH
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
------------< Update Sales Order Table Status after Validation >------------
--------------------------------------------------------------------------------
PROCEDURE update_so_record_status   ( p_so_att_rec     IN OUT  g_xx_ont_so_att_rec_type,
                                      p_error_code     IN      VARCHAR2
                                    ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_cust_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_so_att_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_so_att_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_so_att_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_cust_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_cust_record_status '||SQLERRM);
END update_so_record_status;

--------------------------------------------------------------------------------
------------< Update Sales Order Relation Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_so_attach_stg (
                                  p_stage_rec   IN OUT NOCOPY   xxconv.XX_ONT_SO_ATTACH%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                                 )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'update_so_attach_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    UPDATE XX_ONT_SO_ATTACH
    SET  BATCH_ID                   = p_stage_rec.BATCH_ID
        ,SOURCE_SYSTEM_NAME         = p_stage_rec.SOURCE_SYSTEM_NAME
        ,DOCUMENT_ID                = p_stage_rec.DOCUMENT_ID
        ,ATTACHED_DOCUMENT_ID       = p_stage_rec.ATTACHED_DOCUMENT_ID
        ,MEDIA_ID                   = p_stage_rec.MEDIA_ID
        ,ENTITY_NAME                = p_stage_rec.ENTITY_NAME
        ,DOCUMENT_ENTITY_ID         = p_stage_rec.DOCUMENT_ENTITY_ID
        ,ORIG_SYS_DOCUMENT_REF      = p_stage_rec.ORIG_SYS_DOCUMENT_REF
        ,ORIG_SYS_LINE_REF          = p_stage_rec.ORIG_SYS_LINE_REF
        ,PK1_ID                     = p_stage_rec.PK1_ID
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
    WHERE batch_id                  =   p_batch_id
    and   record_number             =   p_stage_rec.record_number
    and   ORIG_SYS_DOCUMENT_REF     =   p_stage_rec.ORIG_SYS_DOCUMENT_REF
    and   nvl(ORIG_SYS_LINE_REF,'A')=   nvl(p_stage_rec.ORIG_SYS_LINE_REF, nvl(ORIG_SYS_LINE_REF,'A'))
    and   SEQ_NUM                   =   p_stage_rec.SEQ_NUM;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    COMMIT;
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_so_attach_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_so_attach_stg;


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
    from XX_ONT_SO_ATTACH
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID;

    select count(1)
    into l_suc
    from XX_ONT_SO_ATTACH
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '0';

    select count(1)
    into l_err
    from XX_ONT_SO_ATTACH
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
---------------------------------- Sales Order Derivation ---------------------------
-------------------------------------------------------------------------------------
FUNCTION doc_derivations (p_doc_rec   IN OUT NOCOPY   xxconv.XX_ONT_SO_ATTACH%ROWTYPE)
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

    -- Deriving Sales Order PK1 ID
    IF p_doc_rec.entity_name = 'OE_ORDER_HEADERS' THEN
      BEGIN
          select header_id
          into p_doc_rec.pk1_id
          from oe_order_headers_all
          where ORIG_SYS_DOCUMENT_REF = p_doc_rec.ORIG_SYS_DOCUMENT_REF;
      EXCEPTION
      WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Sales Order Header ID :'||p_doc_rec.ORIG_SYS_DOCUMENT_REF);
          l_msg := 'Error Deriving Sales Order Header ID ';
          RAISE l_error_transaction;
      END;
    ELSIF p_doc_rec.entity_name = 'OE_ORDER_LINES' THEN
      BEGIN
          select line_id
          into p_doc_rec.pk1_id
          from oe_order_lines_all
          where ORIG_SYS_DOCUMENT_REF = p_doc_rec.ORIG_SYS_DOCUMENT_REF
          and   ORIG_SYS_LINE_REF  = p_doc_rec.ORIG_SYS_LINE_REF;
      EXCEPTION
      WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Sales Order Line ID :'||p_doc_rec.ORIG_SYS_DOCUMENT_REF||' '||p_doc_rec.ORIG_SYS_LINE_REF);
          l_msg := 'Error Deriving Sales Order Line ID ';
          RAISE l_error_transaction;
      END;
       -- Added for PO attachments : Start
       ELSIF p_doc_rec.entity_name in ('PO_HEAD','PO_HEADERS') THEN
                  BEGIN
                      select po_header_id
                      into p_doc_rec.pk1_id
                      from  po_headers_all
            where segment1 = p_doc_rec.ORIG_SYS_DOCUMENT_REF;
                  EXCEPTION
                  WHEN OTHERS THEN
                      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Sales Order Line ID :'||p_doc_rec.ORIG_SYS_DOCUMENT_REF||' '||p_doc_rec.ORIG_SYS_LINE_REF);
                      l_msg := 'Error Deriving Sales Order Line ID ';
                      RAISE l_error_transaction;
                  END;

          ELSIF p_doc_rec.entity_name = 'PO_LINES' THEN
            BEGIN
                select po_line_id
                into p_doc_rec.pk1_id
                from po_lines_all
      	              where po_header_id in (select Po_header_id
      from po_headers_all
      where segment1 = p_doc_rec.ORIG_SYS_DOCUMENT_REF)
            and   line_num  = p_doc_rec.ORIG_SYS_LINE_REF;
            EXCEPTION
            WHEN OTHERS THEN
                xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Sales Order Line ID :'||p_doc_rec.ORIG_SYS_DOCUMENT_REF||' '||p_doc_rec.ORIG_SYS_LINE_REF);
                l_msg := 'Error Deriving Sales Order Line ID ';
                RAISE l_error_transaction;
            END;

 -- Added for PO attachments : End

    END IF;
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
                       p_doc_rec.ORIG_SYS_DOCUMENT_REF,
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
                       p_doc_rec.ORIG_SYS_DOCUMENT_REF,
                       p_doc_rec.DATATYPE_NAME
                      );
     RETURN FALSE;
END doc_derivations;


-------------------------------------------------------------------------------------
---------------------------------- Attach File --------------------------------------
-------------------------------------------------------------------------------------
FUNCTION doc_attach (p_doc_rec   IN OUT NOCOPY   xxconv.XX_ONT_SO_ATTACH%ROWTYPE)
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

         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'FND_LOBS File Id Created is ' || l_media_id);

        --COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg);
        l_msg := l_msg||' '||SQLERRM;
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
                        , X_PK1_VALUE                    => p_doc_rec.PK1_ID
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
                       p_doc_rec.orig_sys_document_ref,
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
                       p_doc_rec.orig_sys_document_ref,
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

CURSOR c_so_attach
IS
  select *
  from XX_ONT_SO_ATTACH
  WHERE batch_id = p_batch_id
  AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR )
       OR
        (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));


  x_error_code              NUMBER := xx_emf_cn_pkg.cn_success;
  l_ont_so_attach_tab     xx_ont_so_attach_tab_type;
  l_ont_so_attach_rec     xxconv.XX_ONT_SO_ATTACH%ROWTYPE;

  e_so_attach_exception   EXCEPTION;

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
         OPEN c_so_attach;
         LOOP
            FETCH c_so_attach
            BULK COLLECT INTO l_ont_so_attach_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. l_ont_so_attach_tab.COUNT
            LOOP
                l_ont_so_attach_rec := l_ont_so_attach_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion Sales Order for '||l_ont_so_attach_rec.orig_sys_document_ref);
                x_error_code  := XX_ONT_SO_ATTACH_val_pkg.data_validations_att(l_ont_so_attach_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_ont_so_attach_rec.record_number||'  is ' || x_error_code);
                l_ont_so_attach_rec.phase_code := G_STAGE;
                l_ont_so_attach_rec.error_code := x_error_code;
                IF update_so_attach_stg (l_ont_so_attach_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'so_attach_stg updated');
                ELSE
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'so_attach_stg update FAILED');
                END IF;
            END LOOP;
            l_ont_so_attach_tab.DELETE;
            EXIT WHEN c_so_attach%NOTFOUND;
         END LOOP;
         CLOSE c_so_attach;
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables.
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        -- IF Customer Cursor is Open Close the same
        IF c_so_attach%ISOPEN
        THEN
             CLOSE c_so_attach;
        END IF;

        OPEN c_so_attach;

        FETCH c_so_attach
        BULK COLLECT INTO l_ont_so_attach_tab;

        FOR i IN 1 .. l_ont_so_attach_tab.COUNT
        LOOP
            BEGIN
                SAVEPOINT skip_transaction;

                l_ont_so_attach_rec := l_ont_so_attach_tab (i);
                l_ont_so_attach_rec.phase_code := g_stage;

                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_ont_so_attach_rec.RECORD_NUMBER);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));

                IF NOT doc_derivations (p_doc_rec => l_ont_so_attach_rec)
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'doc_derivations Failed');
                   RAISE e_so_attach_exception;
                END IF; -- doc_derivations

                IF NOT doc_attach (p_doc_rec => l_ont_so_attach_rec)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'doc_attach Failed');
                   RAISE e_so_attach_exception;
                END IF; -- doc_attach

                l_ont_so_attach_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_ont_so_attach_rec.error_msg  := NULL;
                IF update_so_attach_stg (l_ont_so_attach_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_so_attach_stg updated');
                END IF;

                COMMIT;
            EXCEPTION
            WHEN e_so_attach_exception
            THEN
                l_ont_so_attach_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_so_attach_stg (l_ont_so_attach_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'so_attach_stg updated');
                END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction;
            END;
        END LOOP;

        l_ont_so_attach_tab.DELETE;
        CLOSE c_so_attach;

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

END xx_ont_so_attach_pkg;
/
