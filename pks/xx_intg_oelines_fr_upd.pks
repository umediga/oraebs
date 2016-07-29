DROP PACKAGE APPS.XX_INTG_OELINES_FR_UPD;

CREATE OR REPLACE PACKAGE APPS."XX_INTG_OELINES_FR_UPD" 
AS
/******************************************************************************
-- Filename:  XX_INTG_OELINES_FR_UPD.pks
-- DCR to Update Freight Terms for Order Lines
-- Usage: Concurrent Program ( Type PL/SQL Procedure)
-- Caution:
-- Copyright (c) IBM
-- All rights reserved.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  28-Nov-2012  ABhargava          Created
-- 7.0  04-Oct-2013  Narendra Yadav     Added some i/p parameters and API to update freight_term_code at Delivery
--
******************************************************************************/
PROCEDURE XX_INTG_OELINES_FR_UPDATE (p_errbuff OUT VARCHAR2,p_retcode OUT VARCHAR2,p_order_number IN NUMBER,p_status VARCHAR2,p_operating_unit NUMBER,p_inv_org NUMBER,p_validate IN VARCHAR);

END;
/
