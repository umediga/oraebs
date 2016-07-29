DROP PACKAGE APPS.XXINTG_SO_DET_SUM_RPT_PKG;

CREATE OR REPLACE PACKAGE APPS.XXINTG_SO_DET_SUM_RPT_PKG
AS
/******************************************************************************
-- Filename:  XXINTG_SO_DET_SUM_RPT_PKG
-- RICEW Object id : O2C-RPT_EXT_188
-- Purpose :  Package Specification for SAles Order Det/Sum Report
--
-- Usage: Report ( Type PL/SQL Procedure)

-- Caution:
-- Copyright (c) IBM
-- All rights reserved.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  30-Oct-2014  Shiny George       Created
-- 2.0  30-Jun-2015  Basha              Added P_division IN parameter
--
******************************************************************************/

PROCEDURE XXINTG_SO_DET_SUM_RPT_PROC
(
   errbuf                     OUT      VARCHAR2,
   retcode                    OUT      VARCHAR2,
   P_ORDER_TYPE_ID            IN       VARCHAR2,
   P_CREATED_BY               IN       VARCHAR2,
   P_DIVISION                 IN       VARCHAR2,
   P_SHIP_TO_CUSTOMER_ID      IN       NUMBER,
   P_STATE                    IN       VARCHAR2,
   P_COUNTRY                  IN       VARCHAR2,
   P_LINE_STATUS              IN       VARCHAR2,
   P_FROM_ORDERED_DATE        IN       DATE,
   P_TO_ORDERED_DATE          IN       DATE
);

END XXINTG_SO_DET_SUM_RPT_PKG;
/
