DROP FUNCTION APPS.XX_BI_O2C_MTL_CATEGORIES;

CREATE OR REPLACE FUNCTION APPS."XX_BI_O2C_MTL_CATEGORIES" (P_VALUE IN VARCHAR, P_VALUE_SET_NAME IN VARCHAR, P_PARENT_VAL IN VARCHAR)
RETURN VARCHAR
AS
l_desc VARCHAR2(200);
BEGIN

    IF P_PARENT_VAL IS NULL THEN
      SELECT C.description
      into l_desc
      FROM FND_FLEX_VALUE_SETS A
          ,FND_FLEX_VALUES B
          ,FND_FLEX_VALUES_TL C
      WHERE A.FLEX_VALUE_SET_NAME = P_VALUE_SET_NAME
      AND A.FLEX_VALUE_SET_ID  = B.FLEX_VALUE_SET_ID
      AND B.FLEX_VALUE_ID = C.FLEX_VALUE_ID
      and c.flex_value_meaning = P_VALUE
      and c.language = 'US' ;

    ELSIF P_PARENT_VAL IS NOT NULL THEN

      SELECT C.description
      into l_desc
      FROM FND_FLEX_VALUE_SETS A
          ,FND_FLEX_VALUES B
          ,FND_FLEX_VALUES_TL C
      WHERE A.FLEX_VALUE_SET_NAME = P_VALUE_SET_NAME
      AND A.FLEX_VALUE_SET_ID  = B.FLEX_VALUE_SET_ID
      AND B.FLEX_VALUE_ID = C.FLEX_VALUE_ID
      and c.flex_value_meaning = P_VALUE
      AND b.parent_flex_value_low = P_PARENT_VAL
      and c.language = 'US' ;

    END IF;

    RETURN (l_desc);
EXCEPTION
WHEN OTHERS THEN
     return NULL;
END;
/
