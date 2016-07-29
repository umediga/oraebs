DROP PACKAGE APPS.XXINTG_CUSTOM_IORD;

CREATE OR REPLACE PACKAGE APPS.XXINTG_CUSTOM_IORD is
----------------------------------------------------------------------
/*
 Created By    : IBM Development Team
 Creation Date : 28-Aug-13
 File Name     : XXONTITEMORDER.pks
 Description   : This script creates package specification for XXINTG_CUSTOM_IORD
 Change History:

 Date        Name                Remarks
 ----------- ------------        -------------------------------------
 28-Aug-13    Aabhas             Initial Version
*/
----------------------------------------------------------------------

FUNCTION XXINTG_IOR_RULEVALUE (L_RULE_LEVEL in VARCHAR,L_RULE_LEVEL_ID IN VARCHAR) RETURN VARCHAR2;
FUNCTION XXINTG_IOR_VALUE_SET (L_VAL_SET_NM IN VARCHAR2,L_CODE IN VARCHAR2) RETURN VARCHAR2;
FUNCTION XXINTG_IOR_ITEM_SEG1 (L_INV_ID IN NUMBER) RETURN VARCHAR2;
FUNCTION XXINTG_IOR_ITEM_DESC (L_INV_ID IN NUMBER) RETURN VARCHAR2;

end XXINTG_CUSTOM_IORD;
/
