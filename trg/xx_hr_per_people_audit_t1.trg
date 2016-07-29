DROP TRIGGER APPS.XX_HR_PER_PEOPLE_AUDIT_T1;

CREATE OR REPLACE TRIGGER APPS.XX_HR_PER_PEOPLE_AUDIT_T1 
   AFTER INSERT OR UPDATE
   ON HR.PER_ALL_PEOPLE_F
   FOR EACH ROW
DECLARE
 x_table_name VARCHAR2(200) := 'PER_ALL_PEOPLE_F';
BEGIN

  IF (:new.employee_number <> :old.employee_number OR
     (:new.employee_number IS NULL AND :old.employee_number IS NOT NULL) OR
     (:new.employee_number IS NOT NULL AND :old.employee_number IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.person_id               -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'EMPLOYEE_NUMBER'            -- data_element
                                          ,:old.employee_number         -- data_value_old
                                          ,:new.employee_number         -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.last_name <> :old.last_name OR
     (:new.last_name IS NULL AND :old.last_name IS NOT NULL) OR
     (:new.last_name IS NOT NULL AND :old.last_name IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.person_id               -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'LAST_NAME'                  -- data_element
                                          ,:old.last_name               -- data_value_old
                                          ,:new.last_name               -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.first_name <> :old.first_name OR
     (:new.first_name IS NULL AND :old.first_name IS NOT NULL) OR
     (:new.first_name IS NOT NULL AND :old.first_name IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.person_id               -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'FIRST_NAME'                 -- data_element
                                          ,:old.first_name              -- data_value_old
                                          ,:new.first_name              -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.middle_names <> :old.middle_names OR
     (:new.middle_names IS NULL AND :old.middle_names IS NOT NULL) OR
     (:new.middle_names IS NOT NULL AND :old.middle_names IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.person_id               -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'MIDDLE_NAMES'               -- data_element
                                          ,:old.middle_names            -- data_value_old
                                          ,:new.middle_names            -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;
  IF (:new.sex <> :old.sex OR
     (:new.sex IS NULL AND :old.sex IS NOT NULL) OR
     (:new.sex IS NOT NULL AND :old.sex IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                         ,:new.person_id               -- table_prim_id
                                         , x_table_name                -- table_name
                                         ,'SEX'                        -- data_element
                                         ,:old.sex                     -- data_value_old
                                         ,:new.sex                     -- data_value_new
                                         ,:new.last_update_date        -- data_element_upd_date
                                         ,:new.effective_start_date    -- effective_start_date
                                         ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;

  IF (:new.title <> :old.title OR
     (:new.title IS NULL AND :old.title IS NOT NULL) OR
     (:new.title IS NOT NULL AND :old.title IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                         ,:new.person_id               -- table_prim_id
                                         , x_table_name                -- table_name
                                         ,'TITLE'                      -- data_element
                                         ,:old.title                   -- data_value_old
                                         ,:new.title                   -- data_value_new
                                         ,:new.last_update_date        -- data_element_upd_date
                                         ,:new.effective_start_date    -- effective_start_date
                                         ,:new.effective_end_date      -- effective_end_date
                                         ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;

  IF (:new.date_of_birth <> :old.date_of_birth OR
     (:new.date_of_birth IS NULL AND :old.date_of_birth IS NOT NULL) OR
     (:new.date_of_birth IS NOT NULL AND :old.date_of_birth IS NULL) )  THEN

     xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                        ,:new.person_id               -- table_prim_id
                                        , x_table_name                -- table_name
                                        ,'DATE_OF_BIRTH'              -- data_element
                                        ,:old.date_of_birth           -- data_value_old
                                        ,:new.date_of_birth           -- data_value_new
                                        ,:new.last_update_date        -- data_element_upd_date
                                        ,:new.effective_start_date    -- effective_start_date
                                        ,:new.effective_end_date      -- effective_end_date
                                        ,NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  IF (:new.nationality <> :old.nationality OR
     (:new.nationality IS NULL AND :old.nationality IS NOT NULL) OR
     (:new.nationality IS NOT NULL AND :old.nationality IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                         ,:new.person_id               -- table_prim_id
                                         , x_table_name                -- table_name
                                         ,'NATIONALITY'                -- data_element
                                         ,:old.nationality             -- data_value_old
                                         ,:new.nationality             -- data_value_new
                                         ,:new.last_update_date        -- data_element_upd_date
                                         ,:new.effective_start_date    -- effective_start_date
                                         ,:new.effective_end_date      -- effective_end_date
                                         ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;

  IF (:new.national_identifier <> :old.national_identifier OR
     (:new.national_identifier IS NULL AND :old.national_identifier IS NOT NULL) OR
     (:new.national_identifier IS NOT NULL AND :old.national_identifier IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                         ,:new.person_id               -- table_prim_id
                                         , x_table_name                -- table_name
                                         ,'NATIONAL_IDENTIFIER'        -- data_element
                                         ,:old.national_identifier     -- data_value_old
                                         ,:new.national_identifier     -- data_value_new
                                         ,:new.last_update_date        -- data_element_upd_date
                                         ,:new.effective_start_date    -- effective_start_date
                                         ,:new.effective_end_date      -- effective_end_date
                                         ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;

  IF (:new.email_address <> :old.email_address OR
     (:new.email_address IS NULL AND :old.email_address IS NOT NULL) OR
     (:new.email_address IS NOT NULL AND :old.email_address IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                         ,:new.person_id               -- table_prim_id
                                         , x_table_name                -- table_name
                                         ,'EMAIL_ADDRESS'              -- data_element
                                         ,:old.email_address           -- data_value_old
                                         ,:new.email_address           -- data_value_new
                                         ,:new.last_update_date        -- data_element_upd_date
                                         ,:new.effective_start_date    -- effective_start_date
                                         ,:new.effective_end_date      -- effective_end_date
                                         ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;

  IF (:new.town_of_birth <> :old.town_of_birth OR
     (:new.town_of_birth IS NULL AND :old.town_of_birth IS NOT NULL) OR
     (:new.town_of_birth IS NOT NULL AND :old.town_of_birth IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                         ,:new.person_id               -- table_prim_id
                                         , x_table_name                -- table_name
                                         ,'TOWN_OF_BIRTH'              -- data_element
                                         ,:old.town_of_birth           -- data_value_old
                                         ,:new.town_of_birth           -- data_value_new
                                         ,:new.last_update_date        -- data_element_upd_date
                                         ,:new.effective_start_date    -- effective_start_date
                                         ,:new.effective_end_date      -- effective_end_date
                                         ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;

  IF (:new.marital_status <> :old.marital_status OR
     (:new.marital_status IS NULL AND :old.marital_status IS NOT NULL) OR
     (:new.marital_status IS NOT NULL AND :old.marital_status IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id               -- person_id
                                         ,:new.person_id               -- table_prim_id
                                         , x_table_name                -- table_name
                                         ,'MARITAL_STATUS'             -- data_element
                                         ,:old.marital_status          -- data_value_old
                                         ,:new.marital_status          -- data_value_new
                                         ,:new.last_update_date        -- data_element_upd_date
                                         ,:new.effective_start_date    -- effective_start_date
                                         ,:new.effective_end_date      -- effective_end_date
                                         ,NVL(:new.creation_date,:old.creation_date)
                                         );
  END IF;

EXCEPTION
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR (-20160, SQLERRM);
END;
/
