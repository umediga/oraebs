DROP PACKAGE APPS.XX_OM_MIN_ORD_QTY_CHECK_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_MIN_ORD_QTY_CHECK_PKG" AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XXOMMINORDQTY.pks 1.0 2012/03/23 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 23-Mar-2012
 File Name      : XXOMMINORDQTY.pks
 Description    : This script creates the specification of the xx_om_min_ord_qty_check_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     23-Mar-12   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
AS
-- Global Variable Declaration
   g_label_name     VARCHAR2 (100)     := 'LABEL_NAME';
   g_process_name   VARCHAR2 (100)     := 'XXOMMINORDQTYEXT';

   TYPE xx_pc_msg_rec_type IS RECORD (
      pc_id   NUMBER
   );

   TYPE xx_pc_msg_tab_type IS TABLE OF xx_pc_msg_rec_type
      INDEX BY BINARY_INTEGER;

   p_pc_msg_table   xx_pc_msg_tab_type;

-- =================================================================================
-- Name           : xx_om_chk_qty_pc
-- Description    : This Procedure Will Invoked At Processing Constraint Level
--                  This will return either 1(fail) if the order quantity is less than Minimum Qty
--                  and for all other cases it will return 0(sucess)
--
-- Parameters description       :
--
-- p_application_id                    : Parameter To Store application id (IN)
-- p_entity_short_name                 : Parameter To Entity Short Name  (IN)
-- p_validation_entity_short_name      : Parameter To Validation Entity Short Name (IN)
-- p_validation_tmplt_short_name       : Parameter (IN)
-- p_record_set_tmplt_short_name       : Parameter (IN)
-- p_scope                             : Parameter (IN)
-- p_result                            : Parameter To Return Value (OUT)
-- ==============================================================================
   PROCEDURE xx_om_chk_qty_pc (
      p_application_id                 IN              NUMBER,
      p_entity_short_name              IN              VARCHAR2,
      p_validation_entity_short_name   IN              VARCHAR2,
      p_validation_tmplt_short_name    IN              VARCHAR2,
      p_record_set_tmplt_short_name    IN              VARCHAR2,
      p_scope                          IN              VARCHAR2,
      p_result                         OUT NOCOPY      NUMBER
   );

-- =================================================================================
-- Name           : xx_om_chk_qty_form
-- Description    : This Function Will Invoked At Form Personalization Level
--                  This will return message if quantity is defined for the Item in DFF attribute
--                  else it will return a null message.
-- Parameters description       :
--
-- p_price_list_name  : Parameter To Store Price List Name (IN)
-- p_inv_item_id      : Parameter To Store Item ID (IN)
-- ==============================================================================
   FUNCTION xx_om_chk_qty_form (
      p_price_list_name   IN   VARCHAR2,
      p_inv_item_id       IN   NUMBER
   )
      RETURN VARCHAR2;
END xx_om_min_ord_qty_check_pkg;
/
