DROP VIEW APPS.XXINTG_PAY_DISB_REQID_V;

/* Formatted on 6/6/2016 5:00:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_PAY_DISB_REQID_V
(
   REQUEST_ID,
   ARGUMENT2,
   REQ_INFO
)
AS
   SELECT b.request_id,
          c.argument2,
          d.user_name || '/' || TRUNC (b.REQUESTED_START_DATE) "REQ_INFO"
     FROM FND_CONCURRENT_PROGRAMS a,
          FND_CONCURRENT_REQUESTS b,
          FND_CONCURRENT_REQUESTS c,
          fnd_user d
    WHERE     a.concurrent_program_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
          AND b.CONCURRENT_PROGRAM_ID = a.CONCURRENT_PROGRAM_ID
          AND c.request_id = b.PARENT_REQUEST_ID
          AND d.user_id = b.requested_by
   UNION
   -- Fetch Request ID and Payment Process Name for Quick Payments
   SELECT b.request_id,
          f.PAYMENT_PROCESS_REQUEST_NAME,
          d.user_name || '/' || TRUNC (b.REQUESTED_START_DATE) "REQ_INFO"
     FROM apps.FND_CONCURRENT_PROGRAMS a,
          apps.FND_CONCURRENT_REQUESTS b,
          apps.fnd_user d,
          apps.IBY_TRXN_DOCUMENTS e,
          apps.iby_payments_all f
    WHERE     a.concurrent_program_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
          AND b.CONCURRENT_PROGRAM_ID = a.CONCURRENT_PROGRAM_ID
          AND b.PARENT_REQUEST_ID = -1
          AND e.TRXNMID = TO_NUMBER (b.argument1)
          AND e.payment_instruction_id = f.payment_instruction_id
          AND d.user_id = b.requested_by
   ORDER BY request_id DESC;
