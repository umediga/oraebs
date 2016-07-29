DROP PACKAGE APPS.XX_ONT_SO_CONFIRM_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_SO_CONFIRM_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 05-APR-2012
 File Name     : XX_ONT_SO_CONFIRM_PKG.pks
 Description   : This script creates the specification of the package
		 xx_ont_so_confirm_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-APR-2012 Sharath Babu        Initial Development
 10-MAY-2012 Sharath Babu        Modified to add parmeters to main
 02-Aug-2012 Renjith             added parameter p_title as per CR
 09-APR-2013 Sharath Babu        Added param p_out_type as per DCR
  03-MAR-2014 Mou	         Added the function get_avail_revsqty for wave1 change
*/
----------------------------------------------------------------------

   PROCEDURE main ( errbuf          OUT  VARCHAR2,
                    retcode         OUT  NUMBER,
                    p_title         IN   VARCHAR2,
                    p_header_id     IN   NUMBER,
                    p_email_send    IN   VARCHAR2,
                    p_email         IN   VARCHAR2,
                    p_language      IN   VARCHAR2,
                    p_out_type      IN   VARCHAR2 );

   FUNCTION get_email_id (p_header_id IN NUMBER) RETURN VARCHAR2;

   FUNCTION get_report_language(p_header_id IN VARCHAR2) RETURN VARCHAR2;

   FUNCTION get_avail_revsqty(p_organization_id IN NUMBER , p_inventory_item_id IN NUMBER) RETURN NUMBER;

END xx_ont_so_confirm_pkg;
/
