DROP PACKAGE APPS.XX_AR_RECEIPT_CONV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_RECEIPT_CONV_PKG" 
AS
  -- ---------------------------------------------------------------------------------
  -- Created By     : Renjith
  -- Creation Date  : 04-JUN-2013
  -- Filename       : XXARCASHREPT.pks
  -- Description    : Package specification for AR Receipt Conversion

  -- Change History:

  -- Date          Version#    Name                Remarks
  -- -----------   --------    ---------------     ------------------------------------
  -- 04-JUN-2013   1.0         Renjith             Initial version
  -- ---------------------------------------------------------------------------------
  TYPE g_rcpt_rec_type IS RECORD
(  batch_id                       VARCHAR2(200)
  ,source_system_name             VARCHAR2(500)
  ,receipt_batch_source           VARCHAR2(100)
  ,receipt_batch_source_id        NUMBER
  ,currency_code                  VARCHAR2(15)
  ,usr_exchange_rate_type         VARCHAR2(30)
  ,exchange_rate                  NUMBER
  ,amount                         NUMBER
  ,receipt_number                 VARCHAR2(30)
  ,receipt_date                   DATE
  ,receipt_status                 VARCHAR2(30)
  ,gl_date                        DATE
  ,customer_id                    NUMBER
  ,customer_number                VARCHAR2(30)
  ,customer_acc_id                NUMBER
  ,receipt_method_name            VARCHAR2(30)
  ,receipt_method_id              NUMBER
  ,comments                       VARCHAR2(2000)
  ,status                         VARCHAR2(2)
  ,org_id                         NUMBER
  ,fuct_currency_code             VARCHAR2(15)
  ,record_number                  VARCHAR2(30)
  ,process_code                   VARCHAR2(100)
  ,error_code                     VARCHAR2(100)
  ,request_id                     NUMBER
  ,creation_date                  DATE
  ,created_by                     NUMBER(15)
  ,last_update_date               DATE
  ,last_updated_by                NUMBER(15)
  ,last_update_login              NUMBER(15)
);

  TYPE g_rcpt_tbl_type IS TABLE OF g_rcpt_rec_type
      INDEX BY BINARY_INTEGER;

    -- Global Variables
  G_STAGE		   VARCHAR2(2000);
  G_BATCH_ID		   VARCHAR2(200);
  G_RCPT_METHOD		   VARCHAR2(60);
  G_COMP_BATCH_ID          VARCHAR2(200);
  G_VALIDATE_AND_LOAD	   VARCHAR2(100) := 'VALIDATE_AND_LOAD';
  G_API_NAME		   VARCHAR2(200);
  G_TRANSACTION_TYPE	   VARCHAR2(10) := NULL;
  G_PROCESS_FLAG	   NUMBER    := 1;
  G_REQUEST_ID             NUMBER    := FND_GLOBAL.CONC_REQUEST_ID;--FND_PROFILE.VALUE('CONC_REQUEST_ID');
  G_USER_ID                NUMBER    := FND_GLOBAL.USER_ID; --FND_PROFILE.VALUE('USER_ID');
  G_RESP_ID                NUMBER    := FND_GLOBAL.RESP_ID;--FND_PROFILE.VALUE('RESP_ID');
  G_RESP_APPL_ID           NUMBER    := FND_GLOBAL.RESP_APPL_ID;

   PROCEDURE main(   x_errbuf              OUT      VARCHAR2
   		    ,x_retcode             OUT      VARCHAR2
   		    ,p_batch_id            IN       VARCHAR2
   		    ,p_restart_flag        IN       VARCHAR2
                    ,p_override_flag       IN       VARCHAR2
		    ,p_validate_and_load   IN       VARCHAR2
		    ,p_gl_date             IN       VARCHAR2
                    ,p_rcpt_method         IN       VARCHAR2);

END xx_ar_receipt_conv_pkg;
/
