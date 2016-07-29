DROP PROCEDURE APPS.XX_FND_WF_ABORT_UTIL;

CREATE OR REPLACE PROCEDURE APPS."XX_FND_WF_ABORT_UTIL" 
AS
   CURSOR c_wf
   IS
      SELECT c.item_type, c.item_key
        FROM wf_items p, wf_items c, wf_item_attribute_values v
       WHERE p.item_type(+) = c.parent_item_type
         AND p.item_key(+) = c.parent_item_key
         AND c.item_type = 'WFERROR'
         AND c.parent_item_type IS NULL
         AND c.END_DATE IS NULL
         AND c.item_key = v.item_key
         AND v.NAME IN ('EVENT_NAME')
         --AND c.ITEM_KEY IN ('331680','331681')
         AND (v.text_value = 'oracle.apps.ont.genesis.outbound.update'
              OR
              v.text_value = 'oracle.apps.ar.applications.CashApp.apply'
              OR
              v.text_value = 'oracle.apps.ont.oi.xml_int.status'
              OR
              v.text_value = 'oracle.apps.ar.transaction.DebitMemo.complete'
              OR
              v.text_value = 'oracle.apps.ar.transaction.CreditMemo.complete'
              OR
              v.text_value = 'oracle.apps.per.irc.common.notifications'
              OR 
              v.text_value = 'oracle.apps.ar.transaction.Invoice.complete'
              OR 
              v.text_value = 'oracle.apps.gl.CurrencyConversionRates.dailyRate.completeImport'
              );

   TYPE ty_wf IS TABLE OF c_wf%ROWTYPE
      INDEX BY PLS_INTEGER;

   l_wf   ty_wf;
BEGIN
   OPEN c_wf;

   LOOP
      FETCH c_wf
      BULK COLLECT INTO l_wf LIMIT 1000;

      FOR i IN 1 .. l_wf.COUNT
      LOOP
----------------------------------------
-- Call Create User API --
-- -------------------------------------
         wf_engine.abortprocess ('WFERROR', l_wf (i).item_key);
      END LOOP;

      COMMIT;
      EXIT WHEN l_wf.COUNT = 0;
   END LOOP;
   CLOSE c_wf;
END;
/
