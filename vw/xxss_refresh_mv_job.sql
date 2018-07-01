DECLARE
  X NUMBER;
BEGIN
  begin
    SYS.DBMS_JOB.SUBMIT
      (
        job        => X
       ,what       => 'DBMS_MVIEW.REFRESH(''XXSS_CN_NOTES_MV'');
   '
       ,next_date  => SYSDATE+60/1440 
       ,interval   => 'SYSDATE+60/1440'
       ,no_parse   => FALSE
    );
  dbms_output.put_line('Job Number:'||to_char(X));
  exception
    when others then
    begin
      raise;
    end;
  end;
END;
/
