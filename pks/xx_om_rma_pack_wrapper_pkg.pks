DROP PACKAGE APPS.XX_OM_RMA_PACK_WRAPPER_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_RMA_PACK_WRAPPER_PKG" 
AS
   ----------------------------------------------------------------------
   /*
    Created By    : Kunal Seal
    Creation Date : 05-Sep-2012
    File Name     : XXOMOEXOEACKWRAP.pks
    Description   : This script submits the RMA Pack Slip Report
                    and submits Send Mail program
    Change History:
    Date        Name                  Remarks
    ----------- -------------         -----------------------------------
    05-Sep-2012  Kunal Seal          Initial Development

   */
   -----------------------------------------------------------------------
   PROCEDURE main_proc (o_errbuf              OUT VARCHAR2,
                        o_retcode             OUT VARCHAR2,
                        --p_sob_id           IN     NUMBER,
                        --p_item_flex_code   IN     VARCHAR2,
                        p_print_description       IN     VARCHAR2,
                        --p_booked_status    IN     VARCHAR2,
                        p_order_type       IN     NUMBER, -- mandatory display
                        p_order_number     IN     NUMBER,
                        --p_order_category   IN     VARCHAR2,
                        --p_line_category     IN    VARCHAR2,
                        --p_open_orders       IN    VARCHAR2,
                        --p_show_hdr_atch     IN    VARCHAR2,
                        --p_show_bdy_atch     IN    VARCHAR2,
                        --p_show_ftr_atch     IN    VARCHAR2,
                        p_email            IN     VARCHAR2);
END xx_om_rma_pack_wrapper_pkg;
/
