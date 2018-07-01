create or replace function APPS.XXSS_COMM_NOTES (P_PAYRUN_ID IN NUMBER, P_SALESREP_ID IN NUMBER)return VARCHAR2 is
  x_note VARCHAR2(5000);
begin
  FOR cur_note IN (SELECT notes
                   FROM apps.XXSS_CN_NOTES_mv CPW
                   WHERE 1=1
                   AND cpW.payrun_id = P_PAYRUN_ID
                   AND cpw.salesrep_id = P_SALESREP_ID
                  
                  )
  LOOP
	  x_note := x_note || cur_note.notes;
  END LOOP;
  RETURN x_note;
exception
  WHEN OTHERS THEN
  RETURN NULL;	
end;
/