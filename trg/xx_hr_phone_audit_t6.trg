DROP TRIGGER APPS.XX_HR_PHONE_AUDIT_T6;

CREATE OR REPLACE TRIGGER APPS.XX_HR_PHONE_AUDIT_T6 
   AFTER INSERT OR UPDATE
   ON HR.PER_PHONES
   FOR EACH ROW
DECLARE
  x_table_name VARCHAR2(200) := 'PER_PHONES';
BEGIN
  IF (NVL(:new.phone_type,:old.phone_type) ='H1' AND NVL(:new.parent_table,:old.parent_table) = 'PER_ALL_PEOPLE_F') THEN
     IF (:new.phone_number <> :old.phone_number OR
        (:new.phone_number IS NULL AND :old.phone_number IS NOT NULL) OR
        (:new.phone_number IS NOT NULL AND :old.phone_number IS NULL) )  THEN

         xx_hr_audit_trig_pkg.insert_audit (  :new.parent_id               -- person_id
                                             ,:new.phone_id                -- table_prim_id
                                             , x_table_name                -- table_name
                                             ,'PHONE_NUMBER1'               -- data_element
                                             ,:old.phone_number            -- data_value_old
                                             ,:new.phone_number            -- data_value_new
                                             ,:new.last_update_date        -- data_element_upd_date
                                             , NULL                        -- effective_start_date
                                             , NULL                        -- effective_end_date
                                             , NVL(:new.creation_date,:old.creation_date)
                                            );

     END IF;
  ELSIF (NVL(:new.phone_type,:old.phone_type) = 'M' AND NVL(:new.parent_table,:old.parent_table) = 'PER_ALL_PEOPLE_F') THEN
     IF (:new.phone_number <> :old.phone_number OR
        (:new.phone_number IS NULL AND :old.phone_number IS NOT NULL) OR
        (:new.phone_number IS NOT NULL AND :old.phone_number IS NULL) )  THEN

         xx_hr_audit_trig_pkg.insert_audit (  :new.parent_id               -- person_id
                                             ,:new.phone_id                -- table_prim_id
                                             , x_table_name                -- table_name
                                             ,'PHONE_NUMBER2'               -- data_element
                                             ,:old.phone_number            -- data_value_old
                                             ,:new.phone_number            -- data_value_new
                                             ,:new.last_update_date        -- data_element_upd_date
                                             , NULL                        -- effective_start_date
                                             , NULL                        -- effective_end_date
                                             , NVL(:new.creation_date,:old.creation_date)
                                            );

     END IF;
  ELSIF (NVL(:new.phone_type,:old.phone_type) = 'W1' AND NVL(:new.parent_table,:old.parent_table) = 'PER_ALL_PEOPLE_F') THEN
     IF (:new.phone_number <> :old.phone_number OR
        (:new.phone_number IS NULL AND :old.phone_number IS NOT NULL) OR
        (:new.phone_number IS NOT NULL AND :old.phone_number IS NULL) )  THEN

         xx_hr_audit_trig_pkg.insert_audit (  :new.parent_id               -- person_id
                                             ,:new.phone_id                -- table_prim_id
                                             , x_table_name                -- table_name
                                             ,'PHONE_NUMBER3'               -- data_element
                                             ,:old.phone_number            -- data_value_old
                                             ,:new.phone_number            -- data_value_new
                                             ,:new.last_update_date        -- data_element_upd_date
                                             , NULL                        -- effective_start_date
                                             , NULL                        -- effective_end_date
                                             , NVL(:new.creation_date,:old.creation_date)
                                            );

     END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR (-20160, SQLERRM);
END;
/
