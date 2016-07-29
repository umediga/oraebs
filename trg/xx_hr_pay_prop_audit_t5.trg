DROP TRIGGER APPS.XX_HR_PAY_PROP_AUDIT_T5;

CREATE OR REPLACE TRIGGER APPS.XX_HR_PAY_PROP_AUDIT_T5 
   AFTER INSERT OR UPDATE
   ON HR.PER_PAY_PROPOSALS
   FOR EACH ROW
DECLARE
  x_table_name VARCHAR2(200) := 'PER_PAY_PROPOSALS';
  x_person_id  NUMBER;
  x_gre_id     NUMBER;
BEGIN

  BEGIN
    SELECT  papf.person_id,paaf.soft_coding_keyflex_id
      INTO  x_person_id,x_gre_id
      FROM  per_all_people_f papf
           ,per_all_assignments_f paaf
     WHERE  papf.person_id = paaf.person_id
       AND  paaf.assignment_id = NVL(:new.assignment_id,:old.assignment_id)
       AND  SYSDATE BETWEEN papf.effective_start_date  AND papf.effective_end_date
       AND  SYSDATE BETWEEN paaf.effective_start_date  AND paaf.effective_end_date;
  EXCEPTION
     WHEN OTHERS THEN
       x_person_id := NULL;
  END;

  IF (:new.proposed_salary_n <> :old.proposed_salary_n OR
     (:new.proposed_salary_n IS NULL AND :old.proposed_salary_n IS NOT NULL) OR
     (:new.proposed_salary_n IS NOT NULL AND :old.proposed_salary_n IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (   x_person_id                 -- person_id
                                          ,:new.pay_proposal_id         -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'PROPOSED_SALARY_N'          -- data_element
                                          ,:old.proposed_salary_n       -- data_value_old
                                          ,:new.proposed_salary_n       -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.change_date             -- effective_start_date
                                          ,:new.date_to                 -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                            );
  END IF;

  IF (:new.proposed_salary_n <> :old.proposed_salary_n OR
     (:new.proposed_salary_n IS NULL AND :old.proposed_salary_n IS NOT NULL) OR
     (:new.proposed_salary_n IS NOT NULL AND :old.proposed_salary_n IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (   x_person_id                 -- person_id
                                          ,:new.pay_proposal_id         -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'PROPOSED_SALARY_RATE'       -- data_element
                                          ,:old.proposed_salary_n       -- data_value_old
                                          ,:new.proposed_salary_n       -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.change_date             -- effective_start_date
                                          ,:new.date_to                 -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                            );

  END IF;

  IF (:new.change_date <> :old.change_date OR
     (:new.change_date IS NULL AND :old.change_date IS NOT NULL) OR
     (:new.change_date IS NOT NULL AND :old.change_date IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (   x_person_id                 -- person_id
                                          ,:new.pay_proposal_id         -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'CHANGE_DATE'                -- data_element
                                          ,:old.change_date             -- data_value_old
                                          ,:new.change_date             -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.change_date             -- effective_start_date
                                          ,:new.date_to                 -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                            );

  END IF;

  IF (:new.attribute1 <> :old.attribute1 OR
     (:new.attribute1 IS NULL AND :old.attribute1 IS NOT NULL) OR
     (:new.attribute1 IS NOT NULL AND :old.attribute1 IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (   x_person_id                 -- person_id
                                          ,:new.pay_proposal_id         -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'ATTRIBUTE1'                 -- data_element
                                          ,:old.attribute1              -- data_value_old
                                          ,:new.attribute1              -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.change_date             -- effective_start_date
                                          ,:new.date_to                 -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                            );

  END IF;

  IF (:new.attribute2 <> :old.attribute2 OR
     (:new.attribute2 IS NULL AND :old.attribute2 IS NOT NULL) OR
     (:new.attribute2 IS NOT NULL AND :old.attribute2 IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (   x_person_id                 -- person_id
                                          ,:new.pay_proposal_id         -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'ATTRIBUTE2'                 -- data_element
                                          ,:old.attribute2              -- data_value_old
                                          ,:new.attribute2              -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.change_date             -- effective_start_date
                                          ,:new.date_to                 -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                            );

  END IF;

  IF (:new.proposal_reason <> :old.proposal_reason OR
     (:new.proposal_reason IS NULL AND :old.proposal_reason IS NOT NULL) OR
     (:new.proposal_reason IS NOT NULL AND :old.proposal_reason IS NULL) )  THEN

      xx_hr_audit_trig_pkg.insert_audit_date (   x_person_id                 -- person_id
                                          ,:new.pay_proposal_id         -- table_prim_id
                                          , x_table_name                -- table_name
                                          ,'PROPOSAL_REASON'            -- data_element
                                          ,:old.proposal_reason         -- data_value_old
                                          ,:new.proposal_reason         -- data_value_new
                                          ,:new.last_update_date        -- data_element_upd_date
                                          ,:new.change_date             -- effective_start_date
                                          ,:new.date_to                 -- effective_end_date
                                          , NVL(:new.creation_date,:old.creation_date)
                                            );

  END IF;

EXCEPTION
  WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR (-20160, SQLERRM);
END;
/
