DROP PACKAGE APPS.XX_AR_PUBLISH_INVOICE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_PUBLISH_INVOICE_PKG" 
AS
/* $Header: $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain/Payel Banerjee
 Creation Date  : 04-APR-2012
 Filename       : XXARPUBLISHINV.pks
 Description    : Invoice Publish Public API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 04-Apr-2012   1.0       Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------

   -- This is a subscription function for oracle.apps.ar.batch.AutoInvoice.run
   -- business event
   FUNCTION publish_autoinvoice_run (
      p_subscription_guid   IN              RAW,
      p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2;

   -- This is a subscription function for oracle.apps.ar.transaction.Invoice.complete
   -- business event
   FUNCTION publish_invoice_complete (
      p_subscription_guid   IN              RAW,
      p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2;

   -- This is a subscription function for oracle.apps.ar.transaction.CreditMemo.complete
   -- business event
   FUNCTION publish_creditmemo_complete (
      p_subscription_guid   IN              RAW,
      p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2;

   -- This is a subscription function for oracle.apps.ar.transaction.DebitMemo.complete
   -- business event
   FUNCTION publish_debitmemo_complete (
      p_subscription_guid   IN              RAW,
      p_event               IN OUT NOCOPY   wf_event_t
   )
      RETURN VARCHAR2;

   -- This procedure is used by the republish concurrent program
   PROCEDURE republish_invoice (
      p_errbuf       OUT NOCOPY      VARCHAR2,
      p_retcode      OUT NOCOPY      VARCHAR2,
      p_type         IN              VARCHAR2,
      p_invoice_from   IN              VARCHAR2,
      p_invoice_to     IN              VARCHAR2,
      p_date_from    IN              VARCHAR2,
      p_date_to      IN              VARCHAR2
   );

   --This function will check if the invoice requires publishing.
  FUNCTION require_publish_check(p_cust_trx_id IN ra_customer_trx_all.customer_trx_id%TYPE,
                                 p_tran_type   IN VARCHAR2) RETURN VARCHAR2;

END xx_ar_publish_invoice_pkg;
/
