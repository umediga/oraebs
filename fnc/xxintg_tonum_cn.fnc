DROP FUNCTION APPS.XXINTG_TONUM_CN;

CREATE OR REPLACE FUNCTION APPS."XXINTG_TONUM_CN" (in_str varchar2) return number is
  v_out_str varchar2(32000);
  begin
  --for i in 1..length(in_str) loop
  v_out_str := TO_NUMBER(regexp_replace(in_str, '[[:alpha:]]', 1));
  --end loop;
 return v_out_str;
EXCEPTION
WHEN others THEN
v_out_str := 99999999;
return v_out_str;
end;
/
