DROP TRIGGER APPS.XX_HR_PER_ADDR_AUDIT_T4;

CREATE OR REPLACE TRIGGER APPS.XX_HR_PER_ADDR_AUDIT_T4 
   AFTER INSERT OR UPDATE
   ON HR.PER_ADDRESSES
   FOR EACH ROW
DECLARE
  x_table_name VARCHAR2(200) := 'PER_ADDRESSES';
BEGIN

  IF (:new.address_line1 <> :old.address_line1 OR
     (:new.address_line1 IS NULL AND :old.address_line1 IS NOT NULL) OR
     (:new.address_line1 IS NOT NULL AND :old.address_line1 IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (  :new.person_id               -- person_id
                                          ,:new.address_id              -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'ADDRESS_LINE1'              -- data_element
                                          ,:old.address_line1           -- data_value_old
                                          ,:new.address_line1           -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.date_from              -- effective_start_date
                                          ,:new.date_to                -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  IF (:new.address_line2 <> :old.address_line2 OR
     (:new.address_line2 IS NULL AND :old.address_line2 IS NOT NULL) OR
     (:new.address_line2 IS NOT NULL AND :old.address_line2 IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (  :new.person_id               -- person_id
                                          ,:new.address_id              -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'ADDRESS_LINE2'              -- data_element
                                          ,:old.address_line2           -- data_value_old
                                          ,:new.address_line2           -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.date_from              -- effective_start_date
                                          ,:new.date_to                -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  IF (:new.town_or_city <> :old.town_or_city OR
     (:new.town_or_city IS NULL AND :old.town_or_city IS NOT NULL) OR
     (:new.town_or_city IS NOT NULL AND :old.town_or_city IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (  :new.person_id               -- person_id
                                          ,:new.address_id              -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'TOWN_OR_CITY'               -- data_element
                                          ,:old.town_or_city            -- data_value_old
                                          ,:new.town_or_city            -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.date_from              -- effective_start_date
                                          ,:new.date_to                -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  IF (:new.postal_code <> :old.postal_code OR
     (:new.postal_code IS NULL AND :old.postal_code IS NOT NULL) OR
     (:new.postal_code IS NOT NULL AND :old.postal_code IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (  :new.person_id               -- person_id
                                          ,:new.address_id              -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'POSTAL_CODE'                -- data_element
                                          ,:old.postal_code             -- data_value_old
                                          ,:new.postal_code             -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.date_from              -- effective_start_date
                                          ,:new.date_to                -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  IF (:new.country <> :old.country OR
     (:new.country IS NULL AND :old.country IS NOT NULL) OR
     (:new.country IS NOT NULL AND :old.country IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (  :new.person_id               -- person_id
                                          ,:new.address_id              -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'COUNTRY'                    -- data_element
                                          ,:old.country                 -- data_value_old
                                          ,:new.country                 -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.date_from              -- effective_start_date
                                          ,:new.date_to                -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  IF (:new.region_2 <> :old.region_2 OR
     (:new.region_2 IS NULL AND :old.region_2 IS NOT NULL) OR
     (:new.region_2 IS NOT NULL AND :old.region_2 IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (  :new.person_id               -- person_id
                                          ,:new.address_id              -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'REGION_2'                   -- data_element
                                          ,:old.region_2                -- data_value_old
                                          ,:new.region_2                -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.date_from              -- effective_start_date
                                          ,:new.date_to                -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

EXCEPTION
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR (-20160, SQLERRM);
END;
/
