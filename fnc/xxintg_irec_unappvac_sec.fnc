DROP FUNCTION APPS.XXINTG_IREC_UNAPPVAC_SEC;

CREATE OR REPLACE FUNCTION APPS."XXINTG_IREC_UNAPPVAC_SEC" (p_user_id NUMBER,p_vac_nm VARCHAR,p_sec_type VARCHAR)
RETURN NUMBER IS
l_str         VARCHAR2(400);

l_pos1        NUMBER := 0;
l_pos2        NUMBER := 0;

l_char1       NUMBER := 1;
l_char2       NUMBER := 1;

l_per_id         VARCHAR2(10);
l_emp_id         NUMBER;

BEGIN
    IF p_sec_type = 'T' THEN
        BEGIN
            select
            xmltype(t.TRANSACTION_DOCUMENT).extract('//TransCache/AM/TXN/EO/PerRequisitionsEORow/CEO/EO/PerAllVacanciesEORow/CEO/EO/IrcRecTeamMembersEORow/PersonId').getStringVal() PERSON_ID
            into l_str
            from hr_api_transactions t
            where t.API_ADDTNL_INFO = p_vac_nm;
        EXCEPTION
        WHEN OTHERS THEN
            l_str := NULL;
        END;

        IF l_str IS NOT NULL THEN
            LOOP
                select instr(l_str,'>',1,l_char1),instr(l_str,'</',1,l_char2)
                into l_pos1,l_pos2
                from dual;

                IF l_pos1 = 0 or l_pos2 = 0 THEN
                    return(0);
                    EXIT;
                END IF;

                select substr(l_str,l_pos1+1,l_pos2-(l_pos1+1))
                into l_per_id
                from dual;

                select employee_id
                into l_emp_id
                from fnd_user
                where user_id = p_user_id;


                IF l_emp_id = to_number(l_per_id) THEN
                    return(1);
                END IF;

                l_char1 := l_char1 +2;
                l_char2 := l_char2 +1;


            END LOOP;
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
