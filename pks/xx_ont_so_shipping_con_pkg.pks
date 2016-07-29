DROP PACKAGE APPS.XX_ONT_SO_SHIPPING_CON_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_SO_SHIPPING_CON_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Pawan Kumar
 Creation Date : 05-APR-2012
 File Name     : XX_ONT_SO_SHIPPING_CON_PKG.pks
 Description   : This script creates the specification of the package
         xx_ont_so_shipping_con_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 23-APR-2012 Pawan Kumar        Initial Development
*/
----------------------------------------------------------------------

   PROCEDURE main ( errbuf          OUT  VARCHAR2,
                    retcode         OUT  NUMBER,
                    p_header_id     IN   NUMBER,
                    p_email_send    IN   VARCHAR2,
                    p_email_address IN   VARCHAR2,
                    p_language      IN   VARCHAR2,
                    p_pri_pen_lines IN   VARCHAR2,
                    p_delivery_id   IN   NUMBER   );

   FUNCTION get_email_id (p_header_id IN NUMBER) RETURN VARCHAR2;

   FUNCTION get_report_language(p_header_id IN VARCHAR2) RETURN VARCHAR2;

END xx_ont_so_shipping_con_pkg;
/
