DROP FUNCTION APPS.XXINTG_GET_OU_US_ID;

CREATE OR REPLACE FUNCTION APPS.xxintg_get_ou_us_id RETURN NUMBER
IS
p_org_id NUMBER := NULL;
BEGIN

    SELECT organization_id INTO p_org_id
    FROM hr_operating_units
    WHERE name = 'OU United States';

    RETURN p_org_id;
    
END xxintg_get_ou_us_id; 
/
