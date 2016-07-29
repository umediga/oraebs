DROP PACKAGE BODY APPS.XX_PO_AUTO_CREATE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PO_AUTO_CREATE_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 25-MAR-14
 File Name     : XXPOAUTOCREATEBE.pkb
 Description   : This script creates package body for xx_po_auto_create_pkg
 Change History:

 Date        Name                Remarks
 ----------- ------------        -------------------------------------
 25-MAR-14    Sharath Babu       Initial Version 
*/
----------------------------------------------------------------------

   FUNCTION xx_upd_note_to_sup(
                               p_subscription_guid   IN              RAW,
                               p_event               IN OUT NOCOPY   wf_event_t
                              )
      RETURN VARCHAR2
   IS
      CURSOR c_fetch_line
      IS
      SELECT pol.po_line_id, oeh.cust_po_number
        FROM po_lines_all pol,
             oe_order_lines_all oel,
             oe_drop_ship_sources ods,
             oe_order_headers_all oeh
       WHERE oeh.header_id = oel.header_id
         AND oel.cancelled_flag <> 'Y'
         AND oel.source_type_code = 'EXTERNAL'
         AND oel.line_id = ods.line_id
         AND oeh.header_id = ods.header_id
         AND ods.po_line_id = pol.po_line_id
         AND ods.po_header_id = pol.po_header_id
         AND pol.po_header_id = ( SELECT MAX(ph.po_header_id) FROM po_headers_all ph );
     
   BEGIN
      --Fetch eligible lines and update
      FOR r_fetch_line IN c_fetch_line LOOP
         UPDATE po_lines_all
            SET note_to_vendor = r_fetch_line.cust_po_number
          WHERE po_line_id = r_fetch_line.po_line_id;
      END LOOP;
      COMMIT;
      RETURN 'SUCCESS';
   EXCEPTION
      WHEN OTHERS THEN
         RETURN 'FAILURE';
   END xx_upd_note_to_sup;
END xx_po_auto_create_pkg;
/
