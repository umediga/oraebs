DROP FUNCTION APPS.XX_LEDGER_STATUS;

CREATE OR REPLACE FUNCTION APPS.xx_ledger_status (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2)
RETURN VARCHAR2
IS
--
lv_status   VARCHAR2(30) := NULL;
--
CURSOR ledger_status_cur
IS
SELECT *
  FROM XXX_ledger_status_v
 WHERE period_name = p_period
   AND ledger_name = p_ledger_name;
--
BEGIN
   lv_status  := NULL;
   --
   FOR ledger_status_rec IN ledger_status_cur
   LOOP
      --
      IF ledger_status_rec.status = 'OPEN' THEN
         lv_status := 'OPEN';
         dbms_output.put_line('Debug1...lv_status: ' ||lv_status);
         exit;
      ELSIF ledger_status_rec.status = 'CLOSED' THEN
         --
         lv_status := 'CLOSED';
         --
      ELSE
         IF lv_status IS NULL THEN
         --IF lv_status <> 'OPEN' OR lv_status <> 'CLOSED' THEN
            lv_status := 'OTHERS';
         END IF;
      END IF;
      --
   END LOOP;
   --
   RETURN lv_status;
   --
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      lv_status := 'OTHERS';
   WHEN OTHERS
   THEN
      lv_status := 'OTHERS';
END;
/
