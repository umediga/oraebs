DROP PACKAGE APPS.XX_WSH_GEN_PACK_SLIP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_WSH_GEN_PACK_SLIP_PKG" 
----------------------------------------------------------------------
/* $Header: XXWSHGENERATEPACKSLIPNO.pks 1.0 2012/07/09 12:00:00 $ */
/*
Created By     : IBM Development Team
Creation Date  : 09-Jul-2012
File Name      : XXWSHGENERATEPACKSLIPNO.pks
Description    : This package generates the package slip number and submit the
                 INTG Pack Slip Report
Change History:
Version Date        Name                    Remarks
------- ----------- ----                    ----------------------
1.0     09-Jul-12   IBM Development Team    Initial development.
2.0     11-Apr-13   IBM Development Team    Changes made for new RICE ID O2C-RPT_009_W0

/*----------------------------------------------------------------------*/
AUTHID CURRENT_USER AS
   FUNCTION get_report_language (p_delivery_id IN NUMBER)
      RETURN VARCHAR2;

   PROCEDURE generate_pack_slip_no (
      o_retcode              OUT      VARCHAR2,
      o_errbuf               OUT      VARCHAR2,
      p_organization_id      IN       NUMBER,
      p_delivery_id          IN       NUMBER,
      p_print_cust_item      IN       VARCHAR2,
      p_item_display         IN       VARCHAR2,
      p_print_mode           IN       VARCHAR2,
      p_sort                 IN       VARCHAR2,
      p_delivery_date_low    IN       VARCHAR2,
      p_delivery_date_high   IN       VARCHAR2,
      p_freight_code         IN       VARCHAR2,
      p_quantity_precision   IN       VARCHAR2,
      p_display_unshipped    IN       VARCHAR2,
      p_print_pending        IN       VARCHAR2,
                                       --added for new RICE ID O2C-RPT_009_W0
      p_output_format        IN       VARCHAR2
   );                                  --added for new RICE ID O2C-RPT_009_W0
END xx_wsh_gen_pack_slip_pkg;
/
