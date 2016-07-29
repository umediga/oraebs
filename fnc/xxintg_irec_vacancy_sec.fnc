DROP FUNCTION APPS.XXINTG_IREC_VACANCY_SEC;

CREATE OR REPLACE FUNCTION APPS."XXINTG_IREC_VACANCY_SEC" (p_user_id NUMBER,p_vac_id NUMBER,p_sec_type VARCHAR)
RETURN NUMBER IS
    l_emp_id   NUMBER;
    l_cnt      NUMBER := 0;
BEGIN
    IF p_sec_type = 'T' THEN
        select employee_id
        into l_emp_id
        from fnd_user
        where user_id = p_user_id;

        select count(1)
        into l_cnt
        from IRC_REC_TEAM_MEMBERS
        where vacancy_id = p_vac_id
        and person_id = l_emp_id;

        IF l_cnt >= 1 THEN
            return(1);
        ELSE
            return(0);
        END IF;

    ELSE
        return(1);
    END IF;
EXCEPTION
WHEN OTHERS THEN
    return(0);
END;
/
