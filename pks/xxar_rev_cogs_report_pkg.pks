DROP PACKAGE APPS.XXAR_REV_COGS_REPORT_PKG;

CREATE OR REPLACE PACKAGE APPS."XXAR_REV_COGS_REPORT_PKG" 
AS
/**************************************************************************************
*             Copyright (c) Integra LifeSciences
*            All rights reserved
***************************************************************************************
*
*   HEADER
*   Package Specification
*
*   PROGRAM NAME
*   xxar_rev_cogs_report_pkg.pks
*
*   DESCRIPTION
*   Creation Script of Package Specification for Revenue COGS reconciliation report
*
*   USAGE
*   To create Package specification of the package xxar_rev_cogs_report_pkg
*
*   PARAMETERS
*   ==========
*   NAME                DESCRIPTION
*   ----------------- ------------------------------------------------------------------
*   NA
*
*   DEPENDENCIES
*   ------------
*   None
*
*   CALLED BY
*
*
*   HISTORY
*   =======
*
*   VERSION  DATE        AUTHOR(S)           DESCRIPTION
*   -------  ----------- ---------------     ---------------------------------------------
*   1.0      27-Jan-2010 Naga Uppara          Creation
*
***************************************************************************************/

--+=====================================================================+
--|                                                                     |
--|                                                                     |
--| Global Variables  ref in XXREVCOGSRPT.xml                          |
--|                                                                     |
--|                                                                     |
--+=====================================================================+

   --======================================================================+
--                                                                      |
-- Report Lexical Parameters                                            |
--                                                                      |
--======================================================================+
--======================================================================+
--                                                                      |
-- Displayed Parameter Values                                           |
--                                                                      |
--======================================================================+


/*======================================================================+
|                                                                       |
| Public Function                                                       |
|                                                                       |
| BeforeReport                                                          |
|                                                                       |
| Logic for Before Report Trigger                                       |
|                                                                       |
+======================================================================*/
   FUNCTION before_report RETURN BOOLEAN;
   --======================================================================+
--                                                                      |
-- Report Input Parameters                                              |
--                                                                      |
--======================================================================+
   p_ledger_id                      NUMBER;
   p_bal_segment                    VARCHAR2 (100);
   p_balance_type                   VARCHAR2 (100);
   p_period_name                    VARCHAR2 (100);
   p_customer_id                    number;
END xxar_rev_cogs_report_pkg; 
/
