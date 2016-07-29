DROP PACKAGE APPS.XXOM_CNSGN_SOI_PKG;

CREATE OR REPLACE PACKAGE APPS.XXOM_CNSGN_SOI_PKG
IS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_CNSGN_SOI_PKG.sql
*
*   DESCRIPTION
* 
*   USAGE
* 
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
* 
*   DEPENDENCIES
*  
*   CALLED BY
* 
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     2.0 18-OCT-2013 Brian Stadnik
******************************************************************************************/

PROCEDURE create_sales_order_request
            (
                   p_user_id           IN VARCHAR2, -- new
                   p_external_ord_no   IN VARCHAR2,
                   p_sales_rep_number  IN VARCHAR2,
                   p_email_address     IN VARCHAR2,
                   p_order_type        IN VARCHAR2,
                   p_cust_po_number    IN VARCHAR2,
                   p_ship_to_acct_num  IN NUMBER,
                   p_invoice_to_acct_num IN NUMBER,
                   p_ship_to_site_id   IN NUMBER,
                   p_invoice_to_site_id IN NUMBER,
                   p_party_site_id     IN NUMBER,
                   p_dt_party_site_id  IN NUMBER, -- new
                   p_dt_attn_contact   IN VARCHAR2, -- new
                   p_dt_attn_company   IN VARCHAR2, -- new
                   p_dt_address_1      IN VARCHAR2,
                   p_dt_address_2      IN VARCHAR2,
                   p_dt_city           IN VARCHAR2,
                   p_dt_state          IN VARCHAR2,
                   p_dt_postal_code    IN VARCHAR2,
                   p_date_needed       IN VARCHAR2,
                   p_ship_method       IN VARCHAR2,
                   p_ship_priority     IN VARCHAR2,
                   p_surgery_date      IN VARCHAR2,
                   p_surgery_type IN VARCHAR2,
                   p_surgeon_id   IN VARCHAR2,
                   p_external_surgeon_id IN VARCHAR2,
                   p_surgeon_name   IN VARCHAR2,
                   p_patient_id IN VARCHAR2,
                   p_case_number IN VARCHAR2,
                   p_internal_notes IN VARCHAR2,
                   p_external_notes IN VARCHAR2,
                   p_shipping_notes IN VARCHAR2,
                   p_ship_complete IN VARCHAR2,
                   p_construct_pricing IN VARCHAR2,
                   p_third_party_billing IN VARCHAR2,
                   p_third_party_billing_note IN VARCHAR2,
                   p_cc_code  IN VARCHAR2,  -- new
                   p_cc_holder_name IN VARCHAR2,  -- new
                   p_cc_number IN VARCHAR2, --new
                   p_cc_expiration_date VARCHAR2, --new
                   p_so_lines     IN   xxintg_t_so_line_t,
                   p_return_status    IN  OUT  VARCHAR2,
                                     p_return_code            IN  OUT     VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
            );
  
END XXOM_CNSGN_SOI_PKG; 
/
