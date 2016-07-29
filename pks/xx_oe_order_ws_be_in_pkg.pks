DROP PACKAGE APPS.XX_OE_ORDER_WS_BE_IN_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_ORDER_WS_BE_IN_PKG" AUTHID CURRENT_USER IS

  ----------------------------------------------------------------------------------
  /* $Header: XXOERESUBORDERWSIN.pks 1.0 2012/04/04 12:00:00 Damd noship $ */
  /*
  Created By    : IBM Technical Team
  Creation Date : 04-Apr-2012
  File Name     : XXOERESUBORDERWSIN.pks
  Description   : Sales Order Resubmission Public API.

  Change History:

  Version Date        Name                   Remarks
  ------- ----------- -------------------    -----------------------------------------
  1.0     04-Apr-2012   IBM Technical Team   Initial development.
  1.1     24-Oct-2012   IBM Technical Team   Added G_DISCARD_MSG to handle discarded Orders
  1.2     20-Mar-2013   IBM Technical Team   Added G_PROCESSING_MSG to handle intermediate status

  */
  -------------------------------------------------------------------------------------

  --Global variables holding transaction status messages
  G_SUCCESS_MSG VARCHAR2(10) := 'Success';
  G_FAILED_MSG VARCHAR2(10) := 'Failed';
  G_DISCARD_MSG VARCHAR2(10) := 'Discarded';
  G_PROCESSING_MSG VARCHAR2(10) := 'Processing';

  PROCEDURE xx_submit_event(p_header_id IN NUMBER);

  PROCEDURE xx_raise_resub_event(errbuf          OUT VARCHAR2,
                                 retcode         OUT NUMBER,
                                 p_headerid_from IN NUMBER,
                                 p_headerid_to   IN NUMBER,
                                 p_date_from     IN VARCHAR2,
                                 p_date_to       IN VARCHAR2);

END xx_oe_order_ws_be_in_pkg;
/
