DROP TRIGGER APPS.XX_HR_ASSGN_AUDIT_UP_T2;

CREATE OR REPLACE TRIGGER APPS.XX_HR_ASSGN_AUDIT_UP_T2 
   AFTER INSERT OR UPDATE
   ON HR.PER_ALL_ASSIGNMENTS_F
   FOR EACH ROW
DECLARE
  x_table_name VARCHAR2(200) := 'PER_ALL_ASSIGNMENTS_F';
BEGIN

  IF (:new.location_id <> :old.location_id OR
     (:new.location_id IS NULL AND :old.location_id IS NOT NULL) OR
     (:new.location_id IS NOT NULL AND :old.location_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'LOCATION_ID'                -- data_element
                                          ,:old.location_id             -- data_value_old
                                          ,:new.location_id             -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.location_id <> :old.location_id OR
     (:new.location_id IS NULL AND :old.location_id IS NOT NULL) OR
     (:new.location_id IS NOT NULL AND :old.location_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'LOCATION_ID_C'              -- data_element
                                          ,:old.location_id             -- data_value_old
                                          ,:new.location_id             -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  -- GRE
  IF (:new.soft_coding_keyflex_id <> :old.soft_coding_keyflex_id OR
     (:new.soft_coding_keyflex_id IS NULL AND :old.soft_coding_keyflex_id IS NOT NULL) OR
     (:new.soft_coding_keyflex_id IS NOT NULL AND :old.soft_coding_keyflex_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'SOFT_CODING_KEYFLEX_ID'     -- data_element
                                          ,:old.soft_coding_keyflex_id  -- data_value_old
                                          ,:new.soft_coding_keyflex_id  -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  -- Time Card Approver
  IF (:new.soft_coding_keyflex_id <> :old.soft_coding_keyflex_id OR
     (:new.soft_coding_keyflex_id IS NULL AND :old.soft_coding_keyflex_id IS NOT NULL) OR
     (:new.soft_coding_keyflex_id IS NOT NULL AND :old.soft_coding_keyflex_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'SOFT_CODING_KEYFLEX_ID_T'   -- data_element
                                          ,:old.soft_coding_keyflex_id  -- data_value_old
                                          ,:new.soft_coding_keyflex_id  -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  -- Shift
  IF (:new.soft_coding_keyflex_id <> :old.soft_coding_keyflex_id OR
     (:new.soft_coding_keyflex_id IS NULL AND :old.soft_coding_keyflex_id IS NOT NULL) OR
     (:new.soft_coding_keyflex_id IS NOT NULL AND :old.soft_coding_keyflex_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'SOFT_CODING_KEYFLEX_ID_S'   -- data_element
                                          ,:old.soft_coding_keyflex_id  -- data_value_old
                                          ,:new.soft_coding_keyflex_id  -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  -- Workers Compensation code
  IF (:new.soft_coding_keyflex_id <> :old.soft_coding_keyflex_id OR
     (:new.soft_coding_keyflex_id IS NULL AND :old.soft_coding_keyflex_id IS NOT NULL) OR
     (:new.soft_coding_keyflex_id IS NOT NULL AND :old.soft_coding_keyflex_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'SOFT_CODING_KEYFLEX_ID_W'   -- data_element
                                          ,:old.soft_coding_keyflex_id  -- data_value_old
                                          ,:new.soft_coding_keyflex_id  -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.supervisor_id <> :old.supervisor_id OR
     (:new.supervisor_id IS NULL AND :old.supervisor_id IS NOT NULL) OR
     (:new.supervisor_id IS NOT NULL AND :old.supervisor_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id                -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'SUPERVISOR_ID'              -- data_element
                                          ,:old.supervisor_id           -- data_value_old
                                          ,:new.supervisor_id           -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.supervisor_id <> :old.supervisor_id OR
     (:new.supervisor_id IS NULL AND :old.supervisor_id IS NOT NULL) OR
     (:new.supervisor_id IS NOT NULL AND :old.supervisor_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit ( :new.person_id                -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'SUPERVISOR_ID_N'            -- data_element
                                          ,:old.supervisor_id           -- data_value_old
                                          ,:new.supervisor_id           -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.organization_id <> :old.organization_id OR
     (:new.organization_id IS NULL AND :old.organization_id IS NOT NULL) OR
     (:new.organization_id IS NOT NULL AND :old.organization_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'ORGANIZATION_ID'            -- data_element
                                          ,:old.organization_id         -- data_value_old
                                          ,:new.organization_id         -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.default_code_comb_id <> :old.default_code_comb_id OR
     (:new.default_code_comb_id IS NULL AND :old.default_code_comb_id IS NOT NULL) OR
     (:new.default_code_comb_id IS NOT NULL AND :old.default_code_comb_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'DEFAULT_CODE_COMB_ID'       -- data_element
                                          ,:old.default_code_comb_id    -- data_value_old
                                          ,:new.default_code_comb_id    -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.default_code_comb_id <> :old.default_code_comb_id OR
     (:new.default_code_comb_id IS NULL AND :old.default_code_comb_id IS NOT NULL) OR
     (:new.default_code_comb_id IS NOT NULL AND :old.default_code_comb_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'DEFAULT_CODE_COMB_ID_D'     -- data_element
                                          ,:old.default_code_comb_id    -- data_value_old
                                          ,:new.default_code_comb_id    -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.default_code_comb_id <> :old.default_code_comb_id OR
     (:new.default_code_comb_id IS NULL AND :old.default_code_comb_id IS NOT NULL) OR
     (:new.default_code_comb_id IS NOT NULL AND :old.default_code_comb_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'DEFAULT_CODE_COMB_ID_P'     -- data_element
                                          ,:old.default_code_comb_id    -- data_value_old
                                          ,:new.default_code_comb_id    -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.default_code_comb_id <> :old.default_code_comb_id OR
     (:new.default_code_comb_id IS NULL AND :old.default_code_comb_id IS NOT NULL) OR
     (:new.default_code_comb_id IS NOT NULL AND :old.default_code_comb_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'DEFAULT_CODE_COMB_ID_R'     -- data_element
                                          ,:old.default_code_comb_id    -- data_value_old
                                          ,:new.default_code_comb_id    -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.job_id <> :old.job_id OR
     (:new.job_id IS NULL AND :old.job_id IS NOT NULL) OR
     (:new.job_id IS NOT NULL AND :old.job_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'JOB_ID'                     -- data_element
                                          ,:old.job_id                  -- data_value_old
                                          ,:new.job_id                  -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
  IF (:new.payroll_id <> :old.payroll_id OR
     (:new.payroll_id IS NULL AND :old.payroll_id IS NOT NULL) OR
     (:new.payroll_id IS NOT NULL AND :old.payroll_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id               -- person_id
                                          ,:new.assignment_id           -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'PAYROLL_ID'                 -- data_element
                                          ,:old.payroll_id              -- data_value_old
                                          ,:new.payroll_id              -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.effective_start_date    -- effective_start_date
                                          ,:new.effective_end_date      -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.assignment_status_type_id <> :old.assignment_status_type_id OR
     (:new.assignment_status_type_id IS NULL AND :old.assignment_status_type_id IS NOT NULL) OR
     (:new.assignment_status_type_id IS NOT NULL AND :old.assignment_status_type_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id                   -- person_id
                                          ,:new.assignment_id               -- table_prim_id
                                          , x_table_name                    -- table_name
                                          ,'ASSIGNMENT_STATUS_TYPE_ID'      -- data_element
                                          ,:old.assignment_status_type_id   -- data_value_old
                                          ,:new.assignment_status_type_id   -- data_value_new
                                          ,:new.last_update_date            -- data_element_upd_date
                                          ,:new.effective_start_date        -- effective_start_date
                                          ,:new.effective_end_date          -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.normal_hours <> :old.normal_hours OR
     (:new.normal_hours IS NULL AND :old.normal_hours IS NOT NULL) OR
     (:new.normal_hours IS NOT NULL AND :old.normal_hours IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id                   -- person_id
                                          ,:new.assignment_id               -- table_prim_id
                                          , x_table_name                    -- table_name
                                          ,'NORMAL_HOURS'                   -- data_element
                                          ,:old.normal_hours                -- data_value_old
                                          ,:new.normal_hours                -- data_value_new
                                          ,:new.last_update_date            -- data_element_upd_date
                                          ,:new.effective_start_date        -- effective_start_date
                                          ,:new.effective_end_date          -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.pay_basis_id <> :old.pay_basis_id OR
     (:new.pay_basis_id IS NULL AND :old.pay_basis_id IS NOT NULL) OR
     (:new.pay_basis_id IS NOT NULL AND :old.pay_basis_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id                   -- person_id
                                          ,:new.assignment_id               -- table_prim_id
                                          , x_table_name                    -- table_name
                                          ,'PAY_BASIS_ID'                   -- data_element
                                          ,:old.pay_basis_id                -- data_value_old
                                          ,:new.pay_basis_id                -- data_value_new
                                          ,:new.last_update_date            -- data_element_upd_date
                                          ,:new.effective_start_date        -- effective_start_date
                                          ,:new.effective_end_date          -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.position_id <> :old.position_id OR
     (:new.position_id IS NULL AND :old.position_id IS NOT NULL) OR
     (:new.position_id IS NOT NULL AND :old.position_id IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id                   -- person_id
                                          ,:new.assignment_id               -- table_prim_id
                                          , x_table_name                    -- table_name
                                          ,'POSITION_ID'                    -- data_element
                                          ,:old.position_id                 -- data_value_old
                                          ,:new.position_id                 -- data_value_new
                                          ,:new.last_update_date            -- data_element_upd_date
                                          ,:new.effective_start_date        -- effective_start_date
                                          ,:new.effective_end_date          -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.assignment_category <> :old.assignment_category OR
     (:new.assignment_category IS NULL AND :old.assignment_category IS NOT NULL) OR
     (:new.assignment_category IS NOT NULL AND :old.assignment_category IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id                   -- person_id
                                          ,:new.assignment_id               -- table_prim_id
                                          , x_table_name                    -- table_name
                                          ,'ASSIGNMENT_CATEGORY'            -- data_element
                                          ,:old.assignment_category         -- data_value_old
                                          ,:new.assignment_category         -- data_value_new
                                          ,:new.last_update_date            -- data_element_upd_date
                                          ,:new.effective_start_date        -- effective_start_date
                                          ,:new.effective_end_date          -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.employment_category <> :old.employment_category OR
     (:new.employment_category IS NULL AND :old.employment_category IS NOT NULL) OR
     (:new.employment_category IS NOT NULL AND :old.employment_category IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id                   -- person_id
                                          ,:new.assignment_id               -- table_prim_id
                                          , x_table_name                    -- table_name
                                          ,'EMPLOYMENT_CATEGORY'            -- data_element
                                          ,:old.employment_category         -- data_value_old
                                          ,:new.employment_category         -- data_value_new
                                          ,:new.last_update_date            -- data_element_upd_date
                                          ,:new.effective_start_date        -- effective_start_date
                                          ,:new.effective_end_date          -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.hourly_salaried_code <> :old.hourly_salaried_code OR
     (:new.hourly_salaried_code IS NULL AND :old.hourly_salaried_code IS NOT NULL) OR
     (:new.hourly_salaried_code IS NOT NULL AND :old.hourly_salaried_code IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit (  :new.person_id                   -- person_id
                                          ,:new.assignment_id               -- table_prim_id
                                          , x_table_name                    -- table_name
                                          ,'HOURLY_SALARIED_CODE'           -- data_element
                                          ,:old.hourly_salaried_code        -- data_value_old
                                          ,:new.hourly_salaried_code        -- data_value_new
                                          ,:new.last_update_date            -- data_element_upd_date
                                          ,:new.effective_start_date        -- effective_start_date
                                          ,:new.effective_end_date          -- effective_end_date
                                          ,NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR (-20160, SQLERRM);
END;
/
