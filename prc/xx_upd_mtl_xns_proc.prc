DROP PROCEDURE APPS.XX_UPD_MTL_XNS_PROC;

CREATE OR REPLACE PROCEDURE APPS."XX_UPD_MTL_XNS_PROC" (p_from_id IN NUMBER, p_to_id IN NUMBER)
IS
   l_sequence   NUMBER;
   l_count      NUMBER;
BEGIN
   SELECT mtl_material_transactions_s.NEXTVAL
     INTO l_sequence
     FROM DUAL;

   UPDATE mtl_transactions_interface
      SET transaction_header_id = l_sequence
    WHERE transaction_interface_id BETWEEN p_from_id AND p_to_id;

   UPDATE mtl_transactions_interface
      SET process_flag = 1,
          lock_flag = NULL,
          transaction_mode = 3,
          ERROR_CODE = NULL,
          error_explanation = NULL,
          transaction_source_id = 366,
          distribution_account_id = 335563
    WHERE transaction_interface_id BETWEEN p_from_id AND p_from_id - 1;

   l_count                    := SQL%ROWCOUNT;
   DBMS_OUTPUT.put_line ('Records Updated - ' || l_count);
END; 
/
