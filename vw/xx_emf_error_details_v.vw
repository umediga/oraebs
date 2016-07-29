DROP VIEW APPS.XX_EMF_ERROR_DETAILS_V;

/* Formatted on 6/6/2016 4:58:43 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_EMF_ERROR_DETAILS_V
(
   HEADER_ID,
   ERR_ID,
   ERR_TEXT,
   ERR_TYPE,
   ERR_SEVERITY,
   RECORD_IDENTIFIER_1,
   RECORD_IDENTIFIER_2,
   RECORD_IDENTIFIER_3,
   RECORD_IDENTIFIER_4,
   RECORD_IDENTIFIER_5,
   CREATION_DATE,
   CREATED_BY,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN,
   RECORD_IDENTIFIER_6,
   RECORD_IDENTIFIER_7,
   RECORD_IDENTIFIER_8,
   RECORD_IDENTIFIER_9,
   RECORD_IDENTIFIER_10,
   PROCESS_ID,
   PROCESS_NAME,
   CREATED_BY_USER,
   REQUEST_ID
)
AS
   SELECT det."HEADER_ID",
          det."ERR_ID",
          det."ERR_TEXT",
          det."ERR_TYPE",
          det."ERR_SEVERITY",
          det."RECORD_IDENTIFIER_1",
          det."RECORD_IDENTIFIER_2",
          det."RECORD_IDENTIFIER_3",
          det."RECORD_IDENTIFIER_4",
          det."RECORD_IDENTIFIER_5",
          det."CREATION_DATE",
          det."CREATED_BY",
          det."LAST_UPDATE_DATE",
          det."LAST_UPDATED_BY",
          det."LAST_UPDATE_LOGIN",
          det."RECORD_IDENTIFIER_6",
          det."RECORD_IDENTIFIER_7",
          det."RECORD_IDENTIFIER_8",
          det."RECORD_IDENTIFIER_9",
          det."RECORD_IDENTIFIER_10",
          hdr.process_id,
          hdr.process_name,
          hdr.created_by_user,
          hdr.request_id
     FROM xx_emf_error_details det, xx_emf_error_headers hdr
    WHERE det.header_id = hdr.header_id;


GRANT SELECT ON APPS.XX_EMF_ERROR_DETAILS_V TO INTG_XX_NONHR_RO;
