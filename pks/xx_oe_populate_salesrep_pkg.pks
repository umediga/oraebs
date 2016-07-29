DROP PACKAGE APPS.XX_OE_POPULATE_SALESREP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OE_POPULATE_SALESREP_PKG" 
AUTHID CURRENT_USER AS
/* $Header: XX_OE_POPULATE_SALESREP_PKG.pkb 1.0.0 2012/05/08 00:00:00 riqbal noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Raquib Iqbal
 Creation Date  : 08-MAY-2012
 Filename       : XX_OE_POPULATE_SALESREP_PKG.pks
 Description    : Populate Salesrep Assigment public API. This package is used to populate Salesrep from Territory Manager for a given Sales Order line

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 08-May-2012   1.0       Raquib Iqbal        Initial development.

 */--------------------------------------------------------------------------------
   g_category_name   mtl_category_sets_tl.category_set_name%TYPE;
   g_total_cnt     NUMBER ;
   g_error_cnt     NUMBER ;
   g_success_cnt   NUMBER ;
   g_warn_cnt      NUMBER ;
-------------------------------------------------------------------------------  /*
   PROCEDURE xx_oe_populate_salesrep (
      o_errbuf            OUT      VARCHAR2,
      o_retcode           OUT      VARCHAR2,
      p_order_number      IN       NUMBER DEFAULT NULL,
      p_order_dt_from   IN       VARCHAR2 DEFAULT NULL,
      p_order_dt_to     IN       VARCHAR2 DEFAULT NULL
   );
-------------------------------------------------------------------------------  /*
END xx_oe_populate_salesrep_pkg;
/
