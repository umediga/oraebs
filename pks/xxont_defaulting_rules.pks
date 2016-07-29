DROP PACKAGE APPS.XXONT_DEFAULTING_RULES;

CREATE OR REPLACE PACKAGE APPS."XXONT_DEFAULTING_RULES" 
IS
/******************************************************************************
-- Filename:  XXONT_DEFAULTING_RULES.pks
-- RICEW Object id : O2C-EXT_081
-- Purpose :  Package Spec for IDefaulting Rule Setups
--
-- Usage: Type PL/SQL Procedure
-- Caution:
-- Copyright (c) IBM
-- All rights reserved.
-- Ver  Date         Author             Modification
-- ---- -----------  ------------------ --------------------------------------
-- 1.0  04-Apr-2013  ABhargava          Created

********************************************************************************************/


FUNCTION SHIPMENT_PRIORITY ( p_database_object_name  VARCHAR2,
                             p_attribute_code        VARCHAR2 )
RETURN VARCHAR2;

FUNCTION CURRENCY     ( p_database_object_name  VARCHAR2,
                        p_attribute_code        VARCHAR2 )
RETURN VARCHAR2;

FUNCTION ITEM_SHIP_METHOD     ( p_database_object_name  VARCHAR2,
                        p_attribute_code        VARCHAR2 )
RETURN VARCHAR2;

FUNCTION ITEM_SHIP_METHOD_PRC     ( p_database_object_name  VARCHAR2,
                        p_attribute_code        VARCHAR2 )
RETURN VARCHAR2;

END XXONT_DEFAULTING_RULES;
/
