DROP PACKAGE APPS.XX_INV_ORG_TRANSFER_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_ORG_TRANSFER_PKG" AUTHID CURRENT_USER AS
/******************************************************************************
-- Filename:  XXOINVORGTRANSFERPKG.pks
-- RICEW Object id : o2C_INT_070
-- Purpose :  Package Body for Automated Direct Org Transfer
--
-- Usage: Concurrent Program ( Type PL/SQL Procedure)
-- Caution:
-- Copyright (c) IBM
-- All rights reserved.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  18-Jul-2012  SDatta             Created
--
--
******************************************************************************/

   PROCEDURE main ( o_errbuf            OUT VARCHAR2
                   ,o_retcode           OUT VARCHAR2
                   ,p_from_inv_org_id   IN NUMBER
                   ,p_from_subinventory IN VARCHAR2
                   ,p_to_inv_org_id     IN NUMBER
                   ,p_to_subinventory   IN VARCHAR2
                  );

END xx_inv_org_transfer_pkg;
/
