DROP TRIGGER APPS.XX_HR_PER_SER_AUDIT_T3;

CREATE OR REPLACE TRIGGER APPS.XX_HR_PER_SER_AUDIT_T3 
   AFTER INSERT OR UPDATE
   ON HR.PER_PERIODS_OF_SERVICE
   FOR EACH ROW
DECLARE
  x_table_name VARCHAR2(200) := 'PER_PERIODS_OF_SERVICE';
BEGIN

  -- Hire Date
  IF (:new.date_start <> :old.date_start OR
     (:new.date_start IS NULL AND :old.date_start IS NOT NULL) OR
     (:new.date_start IS NOT NULL AND :old.date_start IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.period_of_service_id    -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'DATE_START'                 -- data_element
                                          ,:old.date_start              -- data_value_old
                                          ,:new.date_start              -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          , NULL                        -- effective_start_date
                                          , NULL                        -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  IF (:new.actual_termination_date <> :old.actual_termination_date OR
     (:new.actual_termination_date IS NULL AND :old.actual_termination_date IS NOT NULL) OR
     (:new.actual_termination_date IS NOT NULL AND :old.actual_termination_date IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.period_of_service_id    -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'ACTUAL_TERMINATION_DATE'    -- data_element
                                          ,:old.actual_termination_date -- data_value_old
                                          ,:new.actual_termination_date -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          , NULL                        -- effective_start_date
                                          , NULL                        -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  -- Termination Reason
  IF (:new.leaving_reason <> :old.leaving_reason OR
     (:new.leaving_reason IS NULL AND :old.leaving_reason IS NOT NULL) OR
     (:new.leaving_reason IS NOT NULL AND :old.leaving_reason IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.period_of_service_id    -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'LEAVING_REASON'             -- data_element
                                          ,:old.leaving_reason          -- data_value_old
                                          ,:new.leaving_reason          -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          , NULL                        -- effective_start_date
                                          , NULL                        -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

  -- Adjusted Service Date
  IF (:new.adjusted_svc_date <> :old.adjusted_svc_date OR
     (:new.adjusted_svc_date IS NULL AND :old.adjusted_svc_date IS NOT NULL) OR
     (:new.adjusted_svc_date IS NOT NULL AND :old.adjusted_svc_date IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.period_of_service_id    -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'ADJUSTED_SVC_DATE'          -- data_element
                                          ,:old.adjusted_svc_date       -- data_value_old
                                          ,:new.adjusted_svc_date       -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          , NULL                        -- effective_start_date
                                          , NULL                        -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                        );
  END IF;

EXCEPTION
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR (-20160, SQLERRM);
END;
/
