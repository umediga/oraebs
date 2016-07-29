DROP PACKAGE APPS.XXINTG_DAILY_SLS_ONHAND_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_DAILY_SLS_ONHAND_PKG" as
----------------------------------------------------------------------
/*
 Created By    : Ravi Vishnu
 Creation Date : 26-Aug-2014
 File Name     : XXINTG_DAILY_SLS_ONHAND_PKG
 Description   : This code is being written Onhand report for Daily Sales Reports

 Change History:
 Date         Name                  Remarks
 ----------- -------------         -----------------------------------
 26-Aug-2014  Ravi Vishnu          Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE Main(pERRBUF OUT VARCHAR2,
                  pRETCODE OUT VARCHAR2,
                  pReportName IN VARCHAR,
                  pFromDate IN VARCHAR2,
                  pToDate IN VARCHAR2,
                  pEmail IN VARCHAR2,
                  pSalesRep IN NUMBER);
END;
/
