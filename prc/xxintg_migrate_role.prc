DROP PROCEDURE APPS.XXINTG_MIGRATE_ROLE;

CREATE OR REPLACE PROCEDURE APPS."XXINTG_MIGRATE_ROLE" (ROLE_KEY IN VARCHAR2) IS
r_seq NUMBER;
s_flag NUMBER;
BEGIN
 BEGIN
    SELECT NVL(max(role_sequence),0) INTO r_seq FROM xxintg_mig_script_role;
 EXCEPTION
    WHEN OTHERS THEN
    r_seq := 0;
    raise_application_error(-20004,'Custom Error');
 END;
 
 r_seq := nvl(r_seq,0) + 1;
  DECLARE
   r_name VARCHAR2(50);
  BEGIN
   s_flag := 0;
   SELECT display_name into r_name from wf_roles where name=role_key;
     INSERT INTO XXINTG_mig_script_role VALUES ( r_seq,r_name,role_key,'N');
   COMMIT;
    s_flag := 0;
  EXCEPTION
   WHEN OTHERS THEN
    dbms_output.put_line('xxintg_mig_script_role failed for '||role_key||r_seq||' '||r_name);
     raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
    s_flag := 1;
  END;
   IF s_flag =0 THEN 
  DECLARE
   CURSOR c1 is 
        SELECT xmsro.role_sequence seq,xmsro.role_code role,frt.responsibility_name resp,fr.responsibility_key resp_key
       FROM fnd_responsibility fr,
       wf_local_roles wlr,
       wf_role_hierarchies wrh,
       xxintg_mig_script_role xmsro,
       fnd_responsibility_tl frt
 WHERE fr.responsibility_id = wlr.orig_system_id
   AND wlr.orig_system = 'FND_RESP'
   AND wlr.NAME = wrh.super_name
   AND wrh.sub_name = xmsro.role_code
   AND xmsro.migrated = 'N'
   AND xmsro.role_sequence = r_seq
   AND frt.language='US' 
   AND frt.responsibility_id=fr.responsibility_id 
   AND xmsro.role_code=role_key
   AND fr.responsibility_key not in (SELECT resp_code from xxintg_mig_script_resp);
         BEGIN
          for c1rec in c1 loop
                  INSERT INTO xxintg_mig_script_resp VALUES (c1rec.seq,c1rec.role,c1rec.resp,c1rec.resp_key,'N');
                  COMMIT;
                  END LOOP;
         EXCEPTION 
         WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('UNIQUE CONSTRAINT VIOLATED ');
       END;
   DECLARE
    CURSOR c2 is 
      SELECT xmsre.resp_code resp,fmt.user_menu_name menu,fm.menu_name menu_code
  FROM fnd_menus fm,
       xxintg_mig_script_resp xmsre,
       fnd_menus_tl fmt,
       fnd_responsibility fr,
       xxintg_mig_script_role xmsro
 WHERE fm.menu_id = fmt.menu_id
   AND xmsre.migrated = 'N'
   AND fmt.language='US' 
   AND xmsre.resp_code=fr.responsibility_key
   AND fr.menu_id=fm.menu_id
   AND xmsro.role_code=role_key 
   AND xmsro.migrated='N'
   AND fm.menu_name not in (SELECT menu_code from xxintg_mig_script_menu);  
   BEGIN
     for c2rec in c2 loop
     INSERT INTO xxintg_mig_script_menu VALUES (c2rec.resp,c2rec.menu,c2rec.menu_code,'N');
     COMMIT;
     END LOOP; 
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('UNIQUE CONSTRAINT VIOLATED ');
    END;
  declare
   cursor c3 is 
    SELECT xmsro.role_code role,fm.menu_name menu
  FROM fnd_menus fm,
       fnd_menus_tl fmt,
       xxintg_mig_script_role xmsro,
       fnd_grants fg
 WHERE fm.menu_id = fmt.menu_id
   AND xmsro.migrated = 'N'
   AND fmt.language='US' 
   AND fg.grantee_key=role_key
   AND fg.menu_id=fm.menu_id
   AND fm.menu_name not in (SELECT ps_code from xxintg_mig_script_ps);
   begin
    for c3rec in c3 loop
            INSERT INTO xxintg_mig_script_ps VALUES (c3rec.role,c3rec.menu,'N');
            COMMIT;
            END loop;
    EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('UNIQUE CONSTRAINT VIOLATED ');
       END;
   END IF;
  END; 
/
