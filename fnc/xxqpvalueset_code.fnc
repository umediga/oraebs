DROP FUNCTION APPS.XXQPVALUESET_CODE;

CREATE OR REPLACE FUNCTION APPS."XXQPVALUESET_CODE" (value_set_name IN VARCHAR2,code IN VARCHAR2, depn IN VARCHAR2) return CHAR
IS
xx_description VARCHAR2(200);
BEGIN

IF depn is null THEN
    SELECT ffvv.description
        INTO xx_description
            FROM fnd_flex_values_vl ffvv,
                 fnd_flex_value_sets ffvs
            WHERE 1=1
                  AND ffvs.flex_value_set_name = value_set_name
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.flex_value = code;
ELSE
    SELECT ffvv.description
        INTO xx_description
            FROM fnd_flex_values_vl ffvv,
                 fnd_flex_value_sets ffvs
            WHERE 1=1
                  AND ffvs.flex_value_set_name = value_set_name
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.flex_value = code
                  AND ffvv.parent_flex_value_low = depn;
END IF;
    RETURN xx_description;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
         RETURN null;
    WHEN OTHERS THEN
	 RETURN null;
END;
/
