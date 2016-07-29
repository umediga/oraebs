DROP PACKAGE APPS.XX_OM_LINE_HOLD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_LINE_HOLD_PKG" AUTHID CURRENT_USER
-----------------------------------------------------------------------------------
/* $Header: XXOMLINEHOLDWF.pks 1.2 2013/05/13 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 21-Jun-2012
 File Name      : XXOMLINEHOLDWF.pks
 Description    : This script creates the specification of the xx_om_line_hold_pkg package

 Change History:

 Version Date        Name                     Remarks
 ------- ----------- ---------------------    -------------------------------------
 1.0     21-Jun-2012 IBM Development Team     Initial development.
 1.1     07-May-2013 Bedabrata Bhattacharjee  Logic addition/modification for GHX
 1.2     13-May-2013 Dhiren Parida            New Procedures Added for New HOLDs
 1.3     23-Oct-2013 Dhiren Parida            New HOLD Added : xx_om_hdr_dropship_hold_chk
                                              New Global Variable : g_hdr_dpship_hold_name
*/
-----------------------------------------------------------------------------------
AS
-- =================================================================================
-- These Global Variables are used to extract value from the process setup form
-- =================================================================================
   g_hdr_hold_name         VARCHAR2 (50) := 'HEADER_HOLD_NAME';
   g_lnr_uom_hold_name     VARCHAR2 (50) := 'LNR_UOM_HOLD_NAME';
   g_lnr_price_hold_name   VARCHAR2 (50) := 'LNR_PRC_HOLD_NAME';
   g_hdr_price_hold_name   VARCHAR2 (50) := 'HDR_PRC_HOLD_NAME';
   g_hdr_qtr_hold_name     VARCHAR2 (50) := 'HDR_QTREND_HOLD_NAME';
   g_hdr_dpship_hold_name  VARCHAR2 (50) := 'HDR_DSHP_HOLD_NAME';
   g_process_name          VARCHAR2 (50) := 'XXOEORDERWSIN';
   g_hold_type             VARCHAR2 (50) := 'HOLD_TYPE';
   g_hdr_item_type         VARCHAR2 (50) := 'HEADER_ITEM_TYPE';
   g_lnr_item_type         VARCHAR2 (50) := 'LINE_ITEM_TYPE';
   g_dup_po_comnt          VARCHAR2 (50) := 'DUP_PO_HOLD_COMNT';
   g_order_source          VARCHAR2 (50) := 'ORDER_SOURCE_NAME';
   g_hold_lmt_prc          VARCHAR2 (50) := 'HOLD_LIMIT_PRCNT';
   g_hold_lmt_diff         VARCHAR2 (50) := 'HOLD_LIMIT_DIFF';
   g_ediinvalid_item       VARCHAR2 (50) := 'GHX_EDIINVALID_ITEM';

-- =================================================================================
-- Name           : xx_om_dup_cust_po_chk
-- Description    : Procedure To Check the count the DUP PO Reference and Apply The HOLD
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_om_dup_cust_po_chk (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   );


-- =================================================================================
-- Name           : xx_om_quater_end_hold_chk
-- Description    : Procedure To  Apply The QUATER END HOLD
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_om_quater_end_hold_chk (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   );


-- =================================================================================
-- Name           : xx_om_uom_hold_chk
-- Description    : Procedure To Check the File UOM With Item UOM and Apply The HOLD
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_om_uom_hold_chk (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   );

-- =================================================================================
-- Name           : xx_om_item_net_prc_hold_chk
-- Description    : Procedure To Check the File Item Net Price With Item Unit Selling Price and Apply The HOLD
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_om_item_net_prc_hold_chk (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   );

-- =================================================================================
-- Name           : xx_om_hdr_prc_hold_chk
-- Description    : Procedure To Check the total order amount with file line total
--                  if mismatch then apply the HOLD
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_om_hdr_prc_hold_chk (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   );

   PROCEDURE xx_line_hold_send_mail (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   OUT NOCOPY      VARCHAR2
   );

   PROCEDURE xx_hdr_hold_send_mail (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   OUT NOCOPY      VARCHAR2
   );

-- =================================================================================
-- Name           : xx_om_hdr_dropship_hold_chk
-- Description    : Procedure To Check the total order amount with file line total
--                  if mismatch then apply the HOLD
-- Parameters description       :
--
-- itemtype                    : Parameter To Store itemtype (IN)
-- itemkey                     : Parameter To Store itemkey  (IN)
-- actid                       : Parameter To Store actid    (IN)
-- funcmode                    : Parameter To Store funcmode (IN)
-- resultout                   : Parameter To Store resultout(IN OUT)
-- ==============================================================================
   PROCEDURE xx_om_hdr_dropship_hold_chk (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   );

END xx_om_line_hold_pkg;
/
