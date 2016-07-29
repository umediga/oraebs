DROP FUNCTION APPS.INTG_SCHEDULED_PRG;

CREATE OR REPLACE FUNCTION APPS.intg_scheduled_prg (lv_in_str IN VARCHAR2)
   RETURN VARCHAR
IS
  -- lv_in_str    VARCHAR2 (2000);
   lv_in_str1    VARCHAR2 (2000);
   lv_out_str   VARCHAR2 (2000) := NULL;
   
   I NUMBER := 0;
   J NUMBER := 0;
   a number;
   
BEGIN
  
    Loop
    
      j := j+1;
      
      --lv_out_str := lv_out_str||',,,'||j;
               
      lv_in_str1 := to_number(substr( lv_in_str,j,1));      
      
       if lv_in_str1 = 1 AND J= 1 THEN      
        lv_out_str := lv_in_str1;   
      END IF;
      
      if lv_in_str1 = 1 AND J > 1 and J<31 THEN 
        lv_out_str := lv_out_str||','||j;        
      END IF;
      
      if lv_in_str1 = 1 AND J = 31 THEN      
        lv_out_str := lv_out_str||','||j;        
      END IF; 
      
     exit when j>31;  
      
     End Loop; 
     
     if substr(lv_out_str,1,1) = ',' then
      lv_out_str := substr(lv_out_str,2);
     end if;
   
   If lv_out_str is not null then 
   
    RETURN 'Day '||lv_out_str||' of the month';
   
   end if;
   
   lv_in_str1 := substr(lv_in_str,32,7);
   
   if lv_out_str is null then 
   
        RETURN 'Check Days Column';
   end if;
   
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN null;
END; 
/


GRANT EXECUTE ON APPS.INTG_SCHEDULED_PRG TO XXAPPSREAD;
