DROP FUNCTION APPS.XX_FND_RESET_PWD;

CREATE OR REPLACE FUNCTION APPS."XX_FND_RESET_PWD" (p_user_name IN VARCHAR2, p_prefix IN VARCHAR2) return VARCHAR IS
v_flag boolean;
v_lst4ssn varchar2(4);
v_status varchar2(10);
v_tmp_pwd varchar2(20);
pragma autonomous_transaction;
cursor c is 
select substr(national_identifier,8,11) from per_people_x where 
person_id IN (select employee_id from fnd_user where user_name = upper(p_user_name));
begin
v_tmp_pwd := NULL;
v_lst4ssn := '0000';
OPEN C;
FETCH C INTO v_lst4ssn;
CLOSE C;
v_tmp_pwd := p_prefix||'.'||v_lst4ssn;
v_flag := fnd_user_pkg.CHANGEPASSWORD(p_user_name,v_tmp_pwd);
commit;
IF v_flag then
    v_status := 'SUCCESS';
else
v_status := 'FAILURE';
end if;
return v_status;
end; 
/
