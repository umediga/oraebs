DROP PACKAGE APPS.XX_AR_INV_PRINT_WRAP_SS_PKG;

CREATE OR REPLACE PACKAGE APPS.XX_AR_INV_PRINT_WRAP_SS_PKG
AS
   ----------------------------------------------------------------------
   /*
   Created By    : Deepta
   Creation Date : 18-JAN-2014
   File Name     : XX_AR_INV_PRINT_WRAP_SS_PKG.pks
   Description   : This script creates the body of the package
   xx_ar_inv_print_wrap_pkg
   Change History:
   Date        Name                  Remarks
   ----------- -------------         -----------------------------------
   05-MAR-2015 Deepta               Initial Development
   */
   ----------------------------------------------------------------------
   PROCEDURE submit_new_invoice (
         errbuf OUT VARCHAR2,
         retcode OUT NUMBER,
         p_order_by                IN VARCHAR2,
         p_cust_trx_class          IN VARCHAR2,
         p_cust_trx_type_id        IN NUMBER,
         p_dates_low               IN VARCHAR2,
         p_dates_high              IN VARCHAR2,
         p_installment_number      IN NUMBER,
         p_open_invoice            IN VARCHAR2,
         p_check_for_taxyn         IN VARCHAR2,
         p_tax_registration_number IN VARCHAR2,
         p_choice                  IN VARCHAR2,
         p_header_pages            IN NUMBER,
         p_debug_flag              IN VARCHAR2,
         p_message_level           IN NUMBER,
         p_ship_from_warehouse     IN VARCHAR2,
         p_region                  IN VARCHAR2,
         p_print_on_pitney_bowes   IN VARCHAR2,
         P_CONTEXT_VALUE           IN VARCHAR2,
         P_PROFILE_OPTION          IN VARCHAR2,
         P_CONC_PGM_SHORT_NAME     IN VARCHAR2) ;
   PROCEDURE submit_select_invoice (
         errbuf OUT VARCHAR2,
         retcode OUT NUMBER,
         p_order_by                IN VARCHAR2,
         p_cust_trx_class          IN VARCHAR2,
         p_cust_trx_type_id        IN VARCHAR2, --
         p_trx_number_low          IN VARCHAR2,
         p_trx_number_high         IN VARCHAR2,
         p_dates_low               IN VARCHAR2, --
         p_dates_high              IN VARCHAR2, --
         p_customer_class_code     IN VARCHAR2, --
         p_customer_id             IN NUMBER,
         p_installment_number      IN NUMBER,
         p_open_invoice            IN VARCHAR2,
         p_check_for_taxyn         IN VARCHAR2,
         p_tax_registration_number IN VARCHAR2,
         p_choice                  IN VARCHAR2,
         p_header_pages            IN NUMBER,
         p_debug_flag              IN VARCHAR2,
         p_message_level           IN NUMBER,
         p_random_invoices_flag    IN VARCHAR2,
         p_invoice_list_string     IN VARCHAR2,
         p_ship_from_warehouse     IN NUMBER, --
         p_region                  IN VARCHAR2,
         p_print_on_pitney_bowes   IN VARCHAR2,
         P_CONTEXT_VALUE           IN VARCHAR2,
         P_PROFILE_OPTION          IN VARCHAR2,
         P_CONC_PGM_SHORT_NAME     IN VARCHAR2) ;


   FUNCTION get_template (
         p_org_name      IN VARCHAR2,
         p_Conc_pgm_name IN VARCHAR2)
      RETURN VARCHAR;
END;
/
