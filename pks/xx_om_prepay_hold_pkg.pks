DROP PACKAGE APPS.XX_OM_PREPAY_HOLD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OM_PREPAY_HOLD_PKG" AUTHID CURRENT_USER
-----------------------------------------------------------------------------------
/* $Header: XXOMPREPAYHOLD.pks 1.2 2014/01/08 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 08-Jan-2014
 File Name      : XXOMPREPAYHOLD.pks
 Description    : This script creates the specification of the xx_om_prepay_hold_pkg package

 Change History:

 Version Date        Name                     Remarks
 ------- ----------- ---------------------    -------------------------------------
 1.0     21-Jun-2012 IBM Development Team     Initial development.
*/
-----------------------------------------------------------------------------------
 AS
  -- =================================================================================
  -- These Global Variables are used to extract value from the process setup form
  -- =================================================================================
  g_prepay_hold_name VARCHAR2(50) := 'PREPAY_HOLD_NAME';
  g_process_name     VARCHAR2(50) := 'XXOMPREPAYHOLD';
  g_prepay_term_name VARCHAR2(50) := 'PREPAY_TERM_NAME';
  g_prepay_trans_1   VARCHAR2(50) := 'PREPAY_TRANS_1';
  g_prepay_trans_2   VARCHAR2(50) := 'PREPAY_TRANS_2';
  g_prepay_trans_3   VARCHAR2(50) := 'PREPAY_TRANS_3';
  g_prepay_trans_4   VARCHAR2(50) := 'PREPAY_TRANS_4';
  g_prepay_trans_5   VARCHAR2(50) := 'PREPAY_TRANS_5';
  g_prepay_trans_6   VARCHAR2(50) := 'PREPAY_TRANS_6';
  g_prepay_trans_7   VARCHAR2(50) := 'PREPAY_TRANS_7';
  g_prepay_trans_8   VARCHAR2(50) := 'PREPAY_TRANS_8';
  g_prepay_trans_9   VARCHAR2(50) := 'PREPAY_TRANS_9';

  -- =================================================================================
  -- Name           : xx_om_apply_prepay_hold
  -- Description    : Procedure To Apply The PRE-PAY HOLD To Order Header
  -- Parameters description       :
  --
  -- itemtype                    : Parameter To Store itemtype (IN)
  -- itemkey                     : Parameter To Store itemkey  (IN)
  -- actid                       : Parameter To Store actid    (IN)
  -- funcmode                    : Parameter To Store funcmode (IN)
  -- resultout                   : Parameter To Store resultout(IN OUT)
  -- ==============================================================================
  PROCEDURE xx_om_apply_prepay_hold(itemtype  IN VARCHAR2,
                                    itemkey   IN VARCHAR2,
                                    actid     IN NUMBER,
                                    funcmode  IN VARCHAR2,
                                    resultout IN OUT NOCOPY VARCHAR2);

  FUNCTION chk_prepay_hold(headerid IN NUMBER) RETURN VARCHAR2;

END xx_om_prepay_hold_pkg;
/
