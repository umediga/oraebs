DROP PACKAGE BODY APPS.XXINTG_HR_POS_HIERARCHY_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_HR_POS_HIERARCHY_PKG" 
AS
   g_user_id          NUMBER       := fnd_global.user_id;
   g_login_id         NUMBER       := fnd_global.login_id;
   g_request_id       NUMBER       := fnd_global.conc_request_id;
   g_max_request_id   NUMBER       := NULL;
   g_debug_on         VARCHAR2 (1) := 'N';

   PROCEDURE debug_log (p_text IN VARCHAR2)
   IS
   BEGIN
      IF g_debug_on = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_text);
      END IF;
   END debug_log;

   PROCEDURE insert_staging_data (
      p_request_id                 NUMBER,
      p_person_id                  NUMBER,
      p_employee_number            VARCHAR2,
      p_full_name                  VARCHAR2,
      p_position_id                NUMBER,
      p_position_name              VARCHAR2,
      p_organization_id            NUMBER,
      p_organization_name          VARCHAR2,
      p_cost_string                VARCHAR2,
      p_supervisor_id              NUMBER,
      p_supervisor_name            VARCHAR2,
      p_supervisor_position_id     VARCHAR2,
      p_supervisor_position_name   VARCHAR2,
      p_change_type                VARCHAR2,
      p_created_by                 NUMBER,
      p_creation_date              DATE,
      p_last_update_date           DATE,
      p_last_updated_by            NUMBER
   )
   IS
   BEGIN
      INSERT INTO xxintg_hr_pos_data
                  (request_id, person_id, employee_number,
                   full_name, position_id, position_name,
                   organization_id, organization_name, cost_string,
                   supervisor_id, supervisor_name,
                   supervisor_position_id, supervisor_position_name,
                   change_type, created_by, creation_date,
                   last_update_date, last_updated_by
                  )
           VALUES (p_request_id, p_person_id, p_employee_number,
                   p_full_name, p_position_id, p_position_name,
                   p_organization_id, p_organization_name, p_cost_string,
                   p_supervisor_id, p_supervisor_name,
                   p_supervisor_position_id, p_supervisor_position_name,
                   p_change_type, p_created_by, p_creation_date,
                   p_last_update_date, p_last_updated_by
                  );
   END insert_staging_data;

   PROCEDURE process_data_changes
   IS
      CURSOR csr_emp_data
      IS
         SELECT papf.person_id, papf.employee_number, papf.full_name,
                hapf.position_id, hapf.NAME position_name,
                haou.organization_id, haou.NAME org_name,
                pcak.concatenated_segments, paaf.supervisor_id
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_service ppos,
                hr_all_positions_f hapf,
                hr_all_organization_units haou,
                pay_cost_allocation_keyflex pcak
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = ppos.person_id
            AND paaf.position_id = hapf.position_id
            AND paaf.organization_id = haou.organization_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND paaf.assignment_type IN ('E')
            AND ppos.period_of_service_id =
                   (SELECT MAX (period_of_service_id)
                      --For re-hires, select the latest period of service
                    FROM   per_periods_of_service ppos2
                     WHERE ppos2.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND NVL (ppos.actual_termination_date, TRUNC (SYSDATE) + 1) >
                                                               TRUNC (SYSDATE)
            AND paaf.primary_flag = 'Y'
            AND NVL (papf.attribute5, 'X') <> 'N'
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                    AND hapf.effective_end_date
         UNION
         SELECT papf.person_id, papf.npw_number, papf.full_name,
                hapf.position_id, hapf.NAME position_name,
                haou.organization_id, haou.NAME org_name,
                pcak.concatenated_segments, paaf.supervisor_id
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                per_periods_of_placement ppos,
                hr_all_positions_f hapf,
                hr_all_organization_units haou,
                pay_cost_allocation_keyflex pcak
          WHERE papf.person_id = paaf.person_id
            AND papf.person_id = ppos.person_id
            AND paaf.position_id = hapf.position_id
            AND paaf.organization_id = haou.organization_id
            AND haou.cost_allocation_keyflex_id =
                                               pcak.cost_allocation_keyflex_id
            AND paaf.assignment_type IN ('C')
            AND ppos.period_of_placement_id =
                   (SELECT MAX (period_of_placement_id)
                      --For re-hires, select the latest period of service
                    FROM   per_periods_of_placement ppos2
                     WHERE ppos2.person_id = papf.person_id
                       AND date_start <= TRUNC (SYSDATE))
            AND NVL (ppos.actual_termination_date, TRUNC (SYSDATE) + 1) >
                                                               TRUNC (SYSDATE)
            AND paaf.primary_flag = 'Y'
            AND NVL (papf.attribute5, 'X') <> 'N'
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                    AND hapf.effective_end_date;

      CURSOR csr_supervisor_details (p_person_id IN NUMBER)
      IS
         SELECT papf.full_name supervisor_name,
                hapf.position_id supervisor_position_id,
                hapf.NAME supervisor_position_name
           FROM per_all_people_f papf,
                per_all_assignments_f paaf,
                hr_all_positions_f hapf
          WHERE papf.person_id = paaf.person_id
            AND paaf.assignment_type IN ('E', 'C')
            AND papf.person_id = p_person_id
            AND paaf.position_id = hapf.position_id
            AND TRUNC (SYSDATE) BETWEEN papf.effective_start_date
                                    AND papf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN paaf.effective_start_date
                                    AND paaf.effective_end_date
            AND TRUNC (SYSDATE) BETWEEN hapf.effective_start_date
                                    AND hapf.effective_end_date;

      CURSOR csr_latest_data
      IS
         SELECT *
           FROM xxintg_hr_pos_data
          WHERE request_id = g_request_id;

      CURSOR csr_previous_run_data (p_person_id NUMBER)
      IS
         SELECT DISTINCT person_id, organization_id, position_id,
                         supervisor_id, supervisor_name, organization_name,
                         position_name, supervisor_position_name
                    FROM xxintg_hr_pos_data
                   WHERE request_id = NVL (g_max_request_id, g_request_id)
                     AND person_id = p_person_id;

      l_supervisor_name            VARCHAR2 (400);
      l_supervisor_position_id     NUMBER;
      l_supervisor_position_name   VARCHAR2 (400);
      l_change_type                VARCHAR2 (10);
      l_changed_data               VARCHAR2 (4000);
      l_person_count               NUMBER;
      l_changed                    VARCHAR2 (1);
      l_file_handle                UTL_FILE.file_type;
      l_dir                        VARCHAR2 (50)      := 'XXHRLRN';
      l_field_chg_data_head        VARCHAR2 (4000);        -- added for header
      x_error_msg                  VARCHAR2 (3000);
      l_burst                      VARCHAR2 (1)       := 'N';
      x_reqid                      NUMBER;
      x_smtp_server_name           VARCHAR2 (200);
      x_email_from                 VARCHAR2 (200);
      x_email_recipients           VARCHAR2 (1000)    := NULL;
   BEGIN
      BEGIN
         SELECT MAX (request_id)
           INTO g_max_request_id
           FROM xxintg_hr_pos_data;
      EXCEPTION
         WHEN OTHERS
         THEN
            g_max_request_id := NULL;
      END;

      FOR rec_emp_data IN csr_emp_data
      LOOP
         l_supervisor_name := NULL;
         l_supervisor_position_id := NULL;
         l_supervisor_position_name := NULL;
         l_change_type := NULL;

         OPEN csr_supervisor_details (rec_emp_data.supervisor_id);

         FETCH csr_supervisor_details
          INTO l_supervisor_name, l_supervisor_position_id,
               l_supervisor_position_name;

         CLOSE csr_supervisor_details;

         l_person_count := 0;

         BEGIN
            SELECT COUNT (person_id)
              INTO l_person_count
              FROM xxintg_hr_pos_data
             WHERE person_id = rec_emp_data.person_id
               AND request_id = g_max_request_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_person_count := 0;
         END;

         IF l_person_count > 0
         THEN
            l_change_type := 'UPDATE';
         ELSE
            l_change_type := 'NEW';
         END IF;

         debug_log (   'The Change Type for-'
                    || rec_emp_data.person_id
                    || ' is -'
                    || l_change_type
                   );
         insert_staging_data (g_request_id,
                              rec_emp_data.person_id,
                              rec_emp_data.employee_number,
                              rec_emp_data.full_name,
                              rec_emp_data.position_id,
                              rec_emp_data.position_name,
                              rec_emp_data.organization_id,
                              rec_emp_data.org_name,
                              rec_emp_data.concatenated_segments,
                              rec_emp_data.supervisor_id,
                              l_supervisor_name,
                              l_supervisor_position_id,
                              l_supervisor_position_name,
                              l_change_type,
                              g_user_id,
                              TRUNC (SYSDATE),
                              TRUNC (SYSDATE),
                              g_user_id
                             );
         COMMIT;
      END LOOP;

      IF g_max_request_id IS NOT NULL
      THEN
         FOR rec_latest_data IN csr_latest_data
         LOOP
            FOR rec_previous_run_data IN
               csr_previous_run_data (rec_latest_data.person_id)
            LOOP
               IF NVL (rec_previous_run_data.position_id, 'XXXX') !=
                                    NVL (rec_latest_data.position_id, 'XXXX')
               THEN
                  l_changed := 'Y';
               ELSIF NVL (rec_previous_run_data.organization_id, 'XXXX') !=
                                 NVL (rec_latest_data.organization_id, 'XXXX')
               THEN
                  l_changed := 'Y';
               ELSIF NVL (rec_previous_run_data.supervisor_id, 'XXXX') !=
                                   NVL (rec_latest_data.supervisor_id, 'XXXX')
               THEN
                  l_changed := 'Y';
               ELSE
                  l_changed := 'N';
               END IF;

               IF l_changed = 'Y'
               THEN
                  BEGIN
                     INSERT INTO xxintg_pos_changes
                          VALUES (rec_latest_data.employee_number,
                                  rec_latest_data.full_name,
                                  rec_previous_run_data.position_name,
                                  rec_latest_data.position_name,
                                  rec_previous_run_data.supervisor_name,
                                  rec_latest_data.supervisor_name,
                                  rec_latest_data.supervisor_position_name,
                                  'UPDATE', SYSDATE,
                                  rec_latest_data.position_id,
                                  rec_latest_data.request_id, 'F');

                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                             (fnd_file.LOG,
                                 'ERROR in insert xxintg_pos_changes Update '
                              || SQLERRM
                             );
                  END;
               END IF;
            END LOOP;

            IF (rec_latest_data.change_type = 'NEW')
            THEN
               BEGIN
                  INSERT INTO xxintg_pos_changes
                       VALUES (rec_latest_data.employee_number,
                               rec_latest_data.full_name, NULL,
                               rec_latest_data.position_name, NULL,
                               rec_latest_data.supervisor_name,
                               rec_latest_data.supervisor_position_name,
                               'NEW', SYSDATE, rec_latest_data.position_id,
                               rec_latest_data.request_id, 'F');

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                                (fnd_file.LOG,
                                    'ERROR in insert xxintg_pos_changes New '
                                 || SQLERRM
                                );
               END;
            END IF;
         END LOOP;
      END IF;

      BEGIN
         INSERT INTO xxintg_hr_pos_data_hist
            SELECT *
              FROM xxintg_hr_pos_data
             WHERE creation_date < SYSDATE;

         DELETE FROM xxintg_hr_pos_data
               WHERE request_id < g_request_id;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG, 'ERRORS: ' || SQLERRM);
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'ERRORS: ' || SQLERRM);
         ROLLBACK;
   END process_data_changes;

   PROCEDURE create_pos_hier_proc (
      p_parent_pos         VARCHAR2,
      p_sub_pos            VARCHAR2,
      flag           OUT   VARCHAR2
   )
--creating new position/updating employee position where supervisor remains same
   IS
      v_validate                   BOOLEAN         := NULL;
      v_parent_position_id         NUMBER;                        --Mandatory
      v_pos_structure_version_id   NUMBER          := 1061;       --Mandatory
      v_subordinate_position_id    NUMBER;                        --Mandatory
      v_business_group_id          NUMBER          := 81;         --Mandatory
      v_hr_installed               VARCHAR2 (2000) := 'Y';        --Mandatory
      v_effective_date             DATE            := SYSDATE;    --Mandatory
      -- Output Variables
      v_pos_structure_element_id   NUMBER;
      v_object_version_number      NUMBER;
      --user defined Exception
      pos_doesnot_exist            EXCEPTION;
   BEGIN
      BEGIN
         --parent position id
         SELECT DISTINCT position_id
                    INTO v_parent_position_id
                    FROM hr_all_positions_f
                   WHERE UPPER (NAME) = UPPER (p_parent_pos)
                     AND effective_end_date >= TRUNC (SYSDATE);
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Error in Parent Position '
                               || p_parent_pos
                               || ' Subordinate Position '
                               || p_sub_pos
                              );
            v_parent_position_id := NULL;
            flag := 'E';
            RETURN;
      END;

      BEGIN
         --subordinate position id
         SELECT DISTINCT position_id
                    INTO v_subordinate_position_id
                    FROM hr_all_positions_f
                   WHERE UPPER (NAME) = UPPER (p_sub_pos)
                     AND effective_end_date >= TRUNC (SYSDATE);
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Error in Subordinate Position '
                               || p_sub_pos
                               || ' Parent Position '
                               || p_parent_pos
                              );
            v_subordinate_position_id := NULL;
            flag := 'E';
            RETURN;
      END;

      --  Calling API HR_POS_HIERARCHY_ELE_API.CREATE_POS_HIERARCHY_ELE
      hr_pos_hierarchy_ele_api.create_pos_hierarchy_ele
                                                  (v_validate,
                                                   v_parent_position_id,
                                                   v_pos_structure_version_id,
                                                   v_subordinate_position_id,
                                                   v_business_group_id,
                                                   v_hr_installed,
                                                   v_effective_date,
                                                   v_pos_structure_element_id,
                                                   v_object_version_number
                                                  );
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                            'CREATED new pos hierarchy!! sup Pos: '
                         || p_parent_pos
                         || ' Sub Position '
                         || p_sub_pos
                        );
      flag := 'S';
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'Error in API Call!! sup Pos: '
                            || p_parent_pos
                            || ' Sub Pos '
                            || p_sub_pos
                           );
         flag := 'E';
         RETURN;
   END create_pos_hier_proc;

   PROCEDURE update_sup_pos_changed (
      --Procedure for updating supervisor of a employee
      p_new_parent_position_name          VARCHAR2,
      p_subordinate_position_name         VARCHAR2,
      flag                          OUT   VARCHAR2
   )
   IS
      -- Input Variables
      v_validate                   BOOLEAN   := NULL;
      v_pos_structure_element_id   NUMBER;                        --Mandatory
      v_effective_date             DATE      := SYSDATE;          --Mandatory
      v_new_parent_position_id     NUMBER;
      v_subordinate_position_id    NUMBER;
      -- In Out Variables
      v_object_version_number      NUMBER;                        --Mandatory
      --USER DEFINED
      pos_doesnot_exist            EXCEPTION;
      no_old_par_child_relation    EXCEPTION;
   BEGIN
      --new parent position id
      BEGIN
         SELECT DISTINCT position_id
                    INTO v_new_parent_position_id
                    FROM hr_all_positions_f
                   WHERE UPPER (NAME) = UPPER (p_new_parent_position_name)
                     AND effective_end_date >= TRUNC (SYSDATE);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_new_parent_position_id := NULL;
            fnd_file.put_line (fnd_file.LOG,
                                  'Error in Sup Pos '
                               || p_new_parent_position_name
                               || ' Sub Pos '
                               || p_subordinate_position_name
                              );
            flag := 'E';
            RETURN;
      END;

      --subordinate position id
      BEGIN
         SELECT DISTINCT position_id
                    INTO v_subordinate_position_id
                    FROM hr_all_positions_f
                   WHERE UPPER (NAME) = UPPER (p_subordinate_position_name)
                     AND effective_end_date >= TRUNC (SYSDATE);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_subordinate_position_id := NULL;
            fnd_file.put_line (fnd_file.LOG,
                                  'Error in Sub Pos '
                               || p_subordinate_position_name
                               || ' Super Pos '
                               || p_new_parent_position_name
                              );
            flag := 'E';
            RETURN;
      END;

      BEGIN
         SELECT DISTINCT pos_structure_element_id
                    INTO v_pos_structure_element_id
                    FROM per_pos_structure_elements
                   WHERE subordinate_position_id = v_subordinate_position_id
                     AND pos_structure_version_id = '1061';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_pos_structure_element_id := NULL;
            fnd_file.put_line (fnd_file.LOG,
                                  'Error in Pos Struct Ele Id!! Sup Pos '
                               || p_new_parent_position_name
                               || ' Sub Pos '
                               || p_subordinate_position_name
                              );
            flag := 'E';
            RETURN;
      END;

      --object_ver_number
      BEGIN
         SELECT DISTINCT object_version_number
                    INTO v_object_version_number
                    FROM per_pos_structure_elements
                   WHERE subordinate_position_id = v_subordinate_position_id
                     AND pos_structure_version_id = '1061';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_object_version_number := NULL;
            fnd_file.put_line (fnd_file.LOG,
                                  'Error in Obj Ver Num!! Sup Pos '
                               || p_new_parent_position_name
                               || ' Sub Pos '
                               || p_subordinate_position_name
                              );
            flag := 'E';
            RETURN;
      END;

      --IF OLD PARENT CHILD RELATIONSHIP DOESNOT EXIST SO NO POS_STRUCTURE_ELEMENT_ID
      IF v_pos_structure_element_id IS NULL
      THEN
         RAISE no_old_par_child_relation;
      END IF;

      --  Calling API HR_POS_HIERARCHY_ELE_API.UPDATE_POS_HIERARCHY_ELE
      hr_pos_hierarchy_ele_api.update_pos_hierarchy_ele
                                                  (v_validate,
                                                   v_pos_structure_element_id,
                                                   v_effective_date,
                                                   v_new_parent_position_id,
                                                   v_subordinate_position_id,
                                                   v_object_version_number
                                                  );
      COMMIT;
      fnd_file.put_line (fnd_file.LOG,
                            'UPDATED SUP_POS_CHANGED!! Sup Pos '
                         || p_new_parent_position_name
                         || ' Sub Pos '
                         || p_subordinate_position_name
                        );
      flag := 'S';
   EXCEPTION
      WHEN no_old_par_child_relation
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
                'Error OLD PARENT CHILD RELATIONSHIP DOESNOT EXIST!! Super Pos '
             || p_new_parent_position_name
             || ' Sub Pos '
             || p_subordinate_position_name
            );
         flag := 'E';
         RETURN;
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'Error in SUP_POS_CHANGED!! Super Pos '
                            || p_new_parent_position_name
                            || ' Sub Pos '
                            || p_subordinate_position_name
                           );
         flag := 'E';
         RETURN;
   END update_sup_pos_changed;

   FUNCTION num_of_sub (p_emp_number VARCHAR2)
--Procedure for getting no. of subordinates(both direct and indirect) of a employee
   RETURN NUMBER
   IS
      v_count   NUMBER;
   BEGIN
      SELECT     COUNT (1)
            INTO v_count
            FROM apps.per_assignments_x paaf,
                 apps.per_people_x papf,
                 apps.hr_locations_all loc,
                 apps.hr_all_organization_units org,
                 apps.per_jobs job
           WHERE 1 = 1
             AND papf.person_id = paaf.person_id
             AND paaf.assignment_status_type_id = 1
             AND loc.location_id = paaf.location_id
             AND org.organization_id = paaf.organization_id
             AND job.job_id = paaf.job_id
      START WITH 1 = 1 AND papf.employee_number = p_emp_number
      CONNECT BY PRIOR paaf.person_id = paaf.supervisor_id;

      RETURN v_count;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_count := 0;
         fnd_file.put_line (fnd_file.LOG, 'Error in num_of_sub ' || SQLERRM);
         RETURN v_count;
   END num_of_sub;

   PROCEDURE xx_gen_xls_sup
   -- Procedure for getting supervisor list those are not in Hierarchy---
   IS
      CURSOR c_pos_name
      IS
         SELECT DISTINCT p_supr_pos
                    FROM xxintg_pos_changes
                   WHERE TRUNC (created_date) = TRUNC (SYSDATE);

      CURSOR c_not_single
      IS
         SELECT pc.p_empno, pc.p_empname, pc.p_prev_pos, pc.p_curr_pos,
                pc.p_prev_supr, pc.p_curr_supr, pc.p_supr_pos, pc.p_status,
                pc.created_date
           FROM xxintg_pos_changes pc
          WHERE TRUNC (pc.created_date) = TRUNC (SYSDATE)
            AND (   pc.p_supr_pos IN (
                       SELECT DISTINCT pos.NAME
                                  FROM hr_positions_x pos
                                 WHERE UPPER (pos.position_type) != 'SINGLE'
                                   AND pos.NAME = pc.p_supr_pos
                                   AND pos.effective_end_date >=
                                                               TRUNC (SYSDATE))
                 OR pc.p_curr_pos IN (
                       SELECT DISTINCT pos.NAME
                                  FROM hr_positions_x pos
                                 WHERE UPPER (pos.position_type) != 'SINGLE'
                                   AND pos.NAME = pc.p_curr_pos
                                   AND pos.effective_end_date >=
                                                               TRUNC (SYSDATE))
                );

      CURSOR c_shared
      IS
         SELECT *
           FROM xxintg_shared_pos;

      obj_c_shared       c_shared%ROWTYPE;
      obj_c_not_single   c_not_single%ROWTYPE;
      pos_id             NUMBER;
      obj_pos_name       c_pos_name%ROWTYPE;
      u_sup_id           NUMBER;
   BEGIN
      OPEN c_pos_name;

      fnd_file.put_line (fnd_file.output,
                         '<?xml version="1.0" encoding="UTF-8"?>'
                        );
      fnd_file.put_line (fnd_file.output, '<PERDUMMY1>');

      LOOP
         FETCH c_pos_name
          INTO obj_pos_name;

         EXIT WHEN c_pos_name%NOTFOUND;

         BEGIN
            SELECT DISTINCT position_id
                       INTO pos_id
                       FROM hr_all_positions_f
                      WHERE NAME = obj_pos_name.p_supr_pos
                        AND effective_end_date >= TRUNC (SYSDATE);
         EXCEPTION
            WHEN OTHERS
            THEN
               pos_id := NULL;
               fnd_file.put_line (fnd_file.LOG,
                                  'Error in pos_id ' || SQLERRM);
         END;

         BEGIN
            SELECT DISTINCT parent_position_id
                       INTO u_sup_id
                       FROM per_pos_structure_elements
                      WHERE subordinate_position_id = pos_id
                        AND pos_structure_version_id = '1061';
         EXCEPTION
            WHEN OTHERS
            THEN
               DECLARE
                  CURSOR sup_det
                  IS
                     SELECT *
                       FROM xxintg_pos_changes
                      WHERE p_supr_pos = obj_pos_name.p_supr_pos
                        AND TRUNC (created_date) = TRUNC (SYSDATE);

                  obj_sup_det   sup_det%ROWTYPE;
               BEGIN
                  OPEN sup_det;

                  LOOP
                     FETCH sup_det
                      INTO obj_sup_det;

                     EXIT WHEN sup_det%NOTFOUND;
                     fnd_file.put_line (fnd_file.output,
                                        '<SUPERVISOR_DETAILS>'
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           '<EMP_NUM>'
                                        || obj_sup_det.p_empno
                                        || '</EMP_NUM>'
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           '<POS_NAME>'
                                        || obj_sup_det.p_empname
                                        || '</POS_NAME>'
                                       );

                     IF obj_sup_det.p_prev_pos = obj_sup_det.p_curr_pos
                     THEN
                        fnd_file.put_line (fnd_file.output,
                                              '<PRE_POSIT>'
                                           || ' '
                                           || '</PRE_POSIT>'
                                          );
                     ELSE
                        fnd_file.put_line (fnd_file.output,
                                              '<PRE_POSIT>'
                                           || REPLACE (obj_sup_det.p_prev_pos,
                                                       '&',
                                                       '&' || 'amp;'
                                                      )
                                           || '</PRE_POSIT>'
                                          );
                     END IF;

                     fnd_file.put_line (fnd_file.output,
                                           '<POSIT_NAME>'
                                        || REPLACE (obj_sup_det.p_curr_pos,
                                                    '&',
                                                    '&' || 'amp;'
                                                   )
                                        || '</POSIT_NAME>'
                                       );

                     IF obj_sup_det.p_prev_supr = obj_sup_det.p_curr_supr
                     THEN
                        fnd_file.put_line (fnd_file.output,
                                              '<PRE_SUP_NAME>'
                                           || ' '
                                           || '</PRE_SUP_NAME>'
                                          );
                     ELSE
                        fnd_file.put_line (fnd_file.output,
                                              '<PRE_SUP_NAME>'
                                           || obj_sup_det.p_prev_supr
                                           || '</PRE_SUP_NAME>'
                                          );
                     END IF;

                     fnd_file.put_line (fnd_file.output,
                                           '<SUP_NAME>'
                                        || obj_sup_det.p_curr_supr
                                        || '</SUP_NAME>'
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           '<SUP_POS>'
                                        || REPLACE (obj_sup_det.p_supr_pos,
                                                    '&',
                                                    '&' || 'amp;'
                                                   )
                                        || '</SUP_POS>'
                                       );
                     fnd_file.put_line (fnd_file.output,
                                           '<CHG_STATUS>'
                                        || obj_sup_det.p_status
                                        || '</CHG_STATUS>'
                                       );
                     fnd_file.put_line (fnd_file.output,
                                        '<STATUS>' || ' ' || '</STATUS>'
                                       );
                     fnd_file.put_line (fnd_file.output,
                                        '</SUPERVISOR_DETAILS>'
                                       );
                  END LOOP;

                  CLOSE sup_det;
               END;
         END;
      END LOOP;

      CLOSE c_pos_name;

      OPEN c_not_single;

      BEGIN
         LOOP
            FETCH c_not_single
             INTO obj_c_not_single;

            EXIT WHEN c_not_single%NOTFOUND;
            fnd_file.put_line (fnd_file.output, '<SUPERVISOR_DETAILS>');
            fnd_file.put_line (fnd_file.output,
                                  '<EMP_NUM>'
                               || obj_c_not_single.p_empno
                               || '</EMP_NUM>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<POS_NAME>'
                               || obj_c_not_single.p_empname
                               || '</POS_NAME>'
                              );

            IF obj_c_not_single.p_prev_pos = obj_c_not_single.p_curr_pos
            THEN
               fnd_file.put_line (fnd_file.output,
                                  '<PRE_POSIT>' || ' ' || '</PRE_POSIT>'
                                 );
            ELSE
               fnd_file.put_line (fnd_file.output,
                                     '<PRE_POSIT>'
                                  || REPLACE (obj_c_not_single.p_prev_pos,
                                              '&',
                                              '&' || 'amp;'
                                             )
                                  || '</PRE_POSIT>'
                                 );
            END IF;

            fnd_file.put_line (fnd_file.output,
                                  '<POSIT_NAME>'
                               || REPLACE (obj_c_not_single.p_curr_pos,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</POSIT_NAME>'
                              );

            IF obj_c_not_single.p_prev_supr = obj_c_not_single.p_curr_supr
            THEN
               fnd_file.put_line (fnd_file.output,
                                  '<PRE_SUP_NAME>' || ' ' || '</PRE_SUP_NAME>'
                                 );
            ELSE
               fnd_file.put_line (fnd_file.output,
                                     '<PRE_SUP_NAME>'
                                  || obj_c_not_single.p_prev_supr
                                  || '</PRE_SUP_NAME>'
                                 );
            END IF;

            fnd_file.put_line (fnd_file.output,
                                  '<SUP_NAME>'
                               || obj_c_not_single.p_curr_supr
                               || '</SUP_NAME>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<SUP_POS>'
                               || REPLACE (obj_c_not_single.p_supr_pos,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</SUP_POS>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<CHG_STATUS>'
                               || obj_c_not_single.p_status
                               || '</CHG_STATUS>'
                              );
            fnd_file.put_line (fnd_file.output,
                               '<STATUS>' || 'SHARED' || '</STATUS>'
                              );
            fnd_file.put_line (fnd_file.output, '</SUPERVISOR_DETAILS>');
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'ERRORS in c_not_single: ' || SQLERRM
                              );
      END;

      CLOSE c_not_single;

      OPEN c_shared;

      BEGIN
         LOOP
            FETCH c_shared
             INTO obj_c_shared;

            EXIT WHEN c_shared%NOTFOUND;
            fnd_file.put_line (fnd_file.output, '<SUPERVISOR_DETAILS>');
            fnd_file.put_line (fnd_file.output,
                                  '<EMP_NUM>'
                               || obj_c_shared.p_empno
                               || '</EMP_NUM>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<POS_NAME>'
                               || obj_c_shared.p_empname
                               || '</POS_NAME>'
                              );

            IF obj_c_shared.p_prev_pos = obj_c_shared.p_curr_pos
            THEN
               fnd_file.put_line (fnd_file.output,
                                  '<PRE_POSIT>' || ' ' || '</PRE_POSIT>'
                                 );
            ELSE
               fnd_file.put_line (fnd_file.output,
                                     '<PRE_POSIT>'
                                  || REPLACE (obj_c_shared.p_prev_pos,
                                              '&',
                                              '&' || 'amp;'
                                             )
                                  || '</PRE_POSIT>'
                                 );
            END IF;

            fnd_file.put_line (fnd_file.output,
                                  '<POSIT_NAME>'
                               || REPLACE (obj_c_shared.p_curr_pos,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</POSIT_NAME>'
                              );

            IF obj_c_shared.p_prev_supr = obj_c_shared.p_curr_supr
            THEN
               fnd_file.put_line (fnd_file.output,
                                  '<PRE_SUP_NAME>' || ' ' || '</PRE_SUP_NAME>'
                                 );
            ELSE
               fnd_file.put_line (fnd_file.output,
                                     '<PRE_SUP_NAME>'
                                  || obj_c_shared.p_prev_supr
                                  || '</PRE_SUP_NAME>'
                                 );
            END IF;

            fnd_file.put_line (fnd_file.output,
                                  '<SUP_NAME>'
                               || obj_c_shared.p_curr_supr
                               || '</SUP_NAME>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<SUP_POS>'
                               || REPLACE (obj_c_shared.p_supr_pos,
                                           '&',
                                           '&' || 'amp;'
                                          )
                               || '</SUP_POS>'
                              );
            fnd_file.put_line (fnd_file.output,
                                  '<CHG_STATUS>'
                               || obj_c_shared.p_status
                               || '</CHG_STATUS>'
                              );
            fnd_file.put_line (fnd_file.output,
                               '<STATUS>' || 'SHARED' || '</STATUS>'
                              );
            fnd_file.put_line (fnd_file.output, '</SUPERVISOR_DETAILS>');
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'ERRORS in c_shared: ' || SQLERRM
                              );
      END;

      CLOSE c_shared;

      fnd_file.put_line (fnd_file.output, '</PERDUMMY1>');
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'ERRORS: ' || SQLERRM);
   END xx_gen_xls_sup;

   PROCEDURE main (p_errbuf OUT VARCHAR2, p_retcode OUT VARCHAR2)
   IS
      v_errbuf           VARCHAR2 (2000);
      v_retcode          VARCHAR2 (2000);
      po_id              NUMBER;
      par_po_id          NUMBER;
      p_name             VARCHAR2 (200);
      pos_str_id         NUMBER;

      CURSOR c1
      IS
         SELECT   num_of_sub (pc.p_empno), pc.p_empno, pc.p_empname,
                  pc.p_prev_pos, pc.p_curr_pos, pc.p_prev_supr,
                  pc.p_curr_supr, pc.p_supr_pos, pc.p_status,
                  pc.created_date
             FROM xxintg_pos_changes pc,
                  hr_positions_x pos,
                  hr_positions_x pos1
            WHERE TRUNC (pc.created_date) = TRUNC (SYSDATE)
              AND pc.p_supr_pos = pos.NAME
              AND pc.p_curr_pos = pos1.NAME
              AND pos.position_type = 'SINGLE'
              AND pos1.position_type = 'SINGLE'
              AND pos.effective_end_date >= SYSDATE
              AND pos1.effective_end_date >= SYSDATE
         ORDER BY 1 DESC NULLS LAST;          --Positions Which Are Not Shared

      CURSOR c_insert_error
      IS
         SELECT *
           FROM xxintg_pos_status
          WHERE st_flag IN ('E', 'P');

      obj_insert_error   c_insert_error%ROWTYPE;
      obj                c1%ROWTYPE;
      flag               VARCHAR2 (1);
   BEGIN
      process_data_changes;

      OPEN c_insert_error;

      --INSERTING THE DATA FROM ERROR TABLE TO POS_CHANGES
      LOOP
         FETCH c_insert_error
          INTO obj_insert_error;

         EXIT WHEN c_insert_error%NOTFOUND;

         IF (obj_insert_error.status = 'NEW')
         THEN
            BEGIN
               INSERT INTO xxintg_pos_changes
                    VALUES (99997, 'NA', obj_insert_error.prev_emp_pos,
                            obj_insert_error.curr_emp_pos, 'NA', 'NA',
                            obj_insert_error.curr_sup_pos, 'NEW', SYSDATE, 1,
                            1, 'E');

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                              (fnd_file.LOG,
                               'ERROR in INSERTING IN xxintg_pos_changes NEW'
                              );
            END;
         ELSIF (obj_insert_error.status = 'UPDATE')
         THEN
            IF     (obj_insert_error.prev_emp_pos =
                                                 obj_insert_error.prev_emp_pos
                   )
               AND (obj_insert_error.prev_sup_pos !=
                                                 obj_insert_error.curr_sup_pos
                   )
            THEN                                              --SUP POS CHANGE
               BEGIN
                  INSERT INTO xxintg_pos_changes
                       VALUES (99997, 'NA', obj_insert_error.prev_emp_pos,
                               obj_insert_error.curr_emp_pos, 'NA', 'NA1',
                               obj_insert_error.curr_sup_pos, 'UPDATE',
                               SYSDATE, 1, 1, 'E');

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR in INSERTING IN xxintg_pos_changes UPDATE SUP POS CHANGE'
                        );
               END;
            ELSIF     (obj_insert_error.prev_emp_pos !=
                                                 obj_insert_error.prev_emp_pos
                      )
                  AND (obj_insert_error.prev_sup_pos =
                                                 obj_insert_error.curr_sup_pos
                      )
            THEN                                              --EMP POS CHANGE
               BEGIN
                  INSERT INTO xxintg_pos_changes
                       VALUES (99997, 'NA', obj_insert_error.prev_emp_pos,
                               obj_insert_error.curr_emp_pos, 'NA', 'NA',
                               obj_insert_error.curr_sup_pos, 'UPDATE',
                               SYSDATE, 1, 1, 'E');

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR in INSERTING IN xxintg_pos_changes UPDATE EMP POS CHANGE'
                        );
               END;
            ELSIF     (obj_insert_error.prev_emp_pos !=
                                                 obj_insert_error.prev_emp_pos
                      )
                  AND (obj_insert_error.prev_sup_pos !=
                                                 obj_insert_error.curr_sup_pos
                      )
            THEN                                                 --BOTH CHANGE
               BEGIN
                  INSERT INTO xxintg_pos_changes
                       VALUES (99997, 'NA', obj_insert_error.prev_emp_pos,
                               obj_insert_error.curr_emp_pos, 'NA', 'NA1',
                               obj_insert_error.curr_sup_pos, 'UPDATE',
                               SYSDATE, 1, 1, 'E');

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR in INSERTING IN xxintg_pos_changes UPDATE BOTH CHANGE'
                        );
               END;
            END IF;

            COMMIT;
         END IF;
      END LOOP;

      CLOSE c_insert_error;

      --DELETING ERROR TABLE
      BEGIN
         DELETE FROM xxintg_pos_status;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'ERROR in DELETING XXINTG_POS_STATUS'
                              );
      END;
      
            --DELETING shared TABLE
      BEGIN
         DELETE FROM XXINTG_SHARED_POS;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'ERROR in DELETING XXINTG_SHARED_POS'
                              );
      END;


      OPEN c1;

      LOOP
         FETCH c1
          INTO obj;

         EXIT WHEN c1%NOTFOUND;

         BEGIN
            SELECT DISTINCT pos_structure_element_id
                       INTO pos_str_id
                       FROM per_pos_structure_elements
                      WHERE subordinate_position_id =
                               (SELECT DISTINCT position_id
                                           FROM hr_all_positions_f
                                          WHERE UPPER (NAME) =
                                                        UPPER (obj.p_curr_pos)
                                            AND effective_end_date >=
                                                               TRUNC (SYSDATE))
                        AND parent_position_id =
                               (SELECT DISTINCT position_id
                                           FROM hr_all_positions_f
                                          WHERE UPPER (NAME) =
                                                        UPPER (obj.p_supr_pos)
                                            AND effective_end_date >=
                                                               TRUNC (SYSDATE))
                        AND pos_structure_version_id = '1061';
         EXCEPTION
            WHEN OTHERS
            THEN
               pos_str_id := NULL;
         END;

         IF pos_str_id IS NULL
         THEN
            IF UPPER (obj.p_status) = 'NEW'                       --New Hires
            THEN
               IF (obj.p_curr_pos != obj.p_supr_pos)
               THEN
                  BEGIN
                     INSERT INTO xxintg_pos_status
                          VALUES (obj.p_curr_pos, obj.p_curr_pos,
                                  obj.p_supr_pos, obj.p_supr_pos, 'NEW',
                                  SYSDATE, 'P');

                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Error In Inserting In Xxintg_Pos_Status New Sup Pos '
                            || obj.p_supr_pos
                            || ' Sub Pos '
                            || obj.p_curr_pos
                           );
                  END;

                  BEGIN
                     create_pos_hier_proc (obj.p_supr_pos,
                                           obj.p_curr_pos,
                                           flag
                                          );

                     IF flag = 'S'
                     THEN
                        BEGIN
                           UPDATE xxintg_pos_status
                              SET st_flag = 'S'
                            WHERE prev_emp_pos = obj.p_curr_pos
                              AND curr_emp_pos = obj.p_curr_pos
                              AND prev_sup_pos = obj.p_supr_pos
                              AND curr_sup_pos = obj.p_supr_pos
                              AND status = 'NEW'
                              AND TRUNC (created_date) = TRUNC (SYSDATE);

                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              fnd_file.put_line
                                 (fnd_file.LOG,
                                     'ERROR in UPDATING XXINTG_POS_STATUS S NEW Sup Pos '
                                  || obj.p_supr_pos
                                  || ' Sub Pos '
                                  || obj.p_curr_pos
                                 );
                        END;
                     ELSIF flag = 'E'
                     THEN
                        BEGIN
                           UPDATE xxintg_pos_status
                              SET st_flag = 'E'
                            WHERE prev_emp_pos = obj.p_curr_pos
                              AND curr_emp_pos = obj.p_curr_pos
                              AND prev_sup_pos = obj.p_supr_pos
                              AND curr_sup_pos = obj.p_supr_pos
                              AND status = 'NEW'
                              AND TRUNC (created_date) = TRUNC (SYSDATE);

                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              fnd_file.put_line
                                 (fnd_file.LOG,
                                     'ERROR in UPDATING XXINTG_POS_STATUS E NEW Sup Pos '
                                  || obj.p_supr_pos
                                  || ' Sub Pos '
                                  || obj.p_curr_pos
                                 );
                        END;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line (fnd_file.LOG,
                                              'ERROR in NEW Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );

                        BEGIN
                           UPDATE xxintg_pos_status
                              SET st_flag = 'E'
                            WHERE prev_emp_pos = obj.p_curr_pos
                              AND curr_emp_pos = obj.p_curr_pos
                              AND prev_sup_pos = obj.p_supr_pos
                              AND curr_sup_pos = obj.p_supr_pos
                              AND status = 'NEW'
                              AND TRUNC (created_date) = TRUNC (SYSDATE);

                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              fnd_file.put_line
                                 (fnd_file.LOG,
                                     'ERROR in UPDATING XXINTG_POS_STATUS S NEW Sup Pos '
                                  || obj.p_supr_pos
                                  || ' Sub Pos '
                                  || obj.p_curr_pos
                                 );
                        END;
                  END;
               ELSE
                  BEGIN
                     INSERT INTO xxintg_shared_pos
                          VALUES (obj.p_empno, obj.p_empname, obj.p_prev_pos,
                                  obj.p_curr_pos, obj.p_prev_supr,
                                  obj.p_curr_supr, obj.p_supr_pos,
                                  obj.p_status);

                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                               (fnd_file.LOG,
                                   'ERROR in INSERTING XXINTG_SHARED_POS NEW'
                                || SQLERRM
                                || ' Sup Pos '
                                || obj.p_supr_pos
                                || ' Sub Pos '
                                || obj.p_curr_pos
                               );
                  END;
               END IF;
            ELSIF UPPER (obj.p_status) = 'UPDATE'
            THEN
               IF     (obj.p_prev_pos = obj.p_curr_pos)
                  AND (obj.p_prev_supr != obj.p_curr_supr
                      )                                   --Supervisor changed
               THEN
                  IF (obj.p_curr_pos != obj.p_supr_pos)
                  THEN
                     DECLARE
                        prev_sup     VARCHAR2 (1000);
                        pos_ele_id   NUMBER;
                     BEGIN
                        BEGIN
                           SELECT DISTINCT pos_structure_element_id
                                      INTO pos_ele_id
                                      FROM per_pos_structure_elements
                                     WHERE subordinate_position_id =
                                              (SELECT DISTINCT position_id
                                                          FROM hr_all_positions_f
                                                         WHERE UPPER (NAME) =
                                                                  UPPER
                                                                     (obj.p_curr_pos
                                                                     )
                                                           AND effective_end_date >=
                                                                  TRUNC
                                                                      (SYSDATE))
                                       AND pos_structure_version_id = '1061';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              pos_ele_id := NULL;
                        END;

                        IF pos_ele_id IS NULL
                        THEN
                           BEGIN
                              INSERT INTO xxintg_pos_status
                                   VALUES (obj.p_prev_pos, obj.p_curr_pos,
                                           NULL, obj.p_supr_pos, 'UPDATE',
                                           SYSDATE, 'P');

                              COMMIT;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                        'ERROR in INSERTING IN XXINTG_POS_STATUS New Sup Pos '
                                     || obj.p_supr_pos
                                     || ' Sub Pos '
                                     || obj.p_curr_pos
                                    );
                           END;

                           DECLARE
                              CURSOR c_sub
                              IS
                                 SELECT *
                                   FROM per_pos_structure_elements
                                  WHERE parent_position_id =
                                           (SELECT DISTINCT position_id
                                                       FROM hr_all_positions_f
                                                      WHERE UPPER (NAME) =
                                                               UPPER
                                                                  (obj.p_curr_pos
                                                                  )
                                                        AND effective_end_date >=
                                                               TRUNC (SYSDATE))
                                    AND pos_structure_version_id = '1061';

                              obj_c_sub   c_sub%ROWTYPE;
                              sub_pos     VARCHAR2 (500);
                           BEGIN
                              create_pos_hier_proc (obj.p_supr_pos,
                                                    obj.p_curr_pos,
                                                    flag
                                                   );

                              IF flag = 'S'
                              THEN
                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'S'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS S UPDATE SUP CHANGE Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                              ELSIF flag = 'E'
                              THEN
                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'E'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS E UPDATE SUP CHANGE Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                              END IF;

                              OPEN c_sub;

                              LOOP
                                 FETCH c_sub
                                  INTO obj_c_sub;

                                 EXIT WHEN c_sub%NOTFOUND;

                                 BEGIN
                                    SELECT DISTINCT NAME
                                               INTO sub_pos
                                               FROM hr_all_positions_f
                                              WHERE position_id =
                                                       obj_c_sub.subordinate_position_id
                                                AND effective_end_date >=
                                                               TRUNC (SYSDATE);
                                 END;

                                 BEGIN
                                    INSERT INTO xxintg_pos_status
                                         VALUES (sub_pos, sub_pos,
                                                 obj.p_prev_pos,
                                                 obj.p_curr_pos, 'UPDATE',
                                                 SYSDATE, 'P');

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in INSERTING IN XXINTG_POS_STATUS New Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;

                                 BEGIN
                                    update_sup_pos_changed (obj.p_curr_pos,
                                                            sub_pos,
                                                            flag
                                                           );

                                    IF flag = 'S'
                                    THEN
                                       BEGIN
                                          UPDATE xxintg_pos_status
                                             SET st_flag = 'S'
                                           WHERE prev_emp_pos = sub_pos
                                             AND curr_emp_pos = sub_pos
                                             AND prev_sup_pos = obj.p_curr_pos
                                             AND curr_sup_pos = obj.p_curr_pos
                                             AND status = 'UPDATE'
                                             AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                          COMMIT;
                                       EXCEPTION
                                          WHEN OTHERS
                                          THEN
                                             fnd_file.put_line
                                                (fnd_file.LOG,
                                                    'ERROR in UPDATING XXINTG_POS_STATUS S UPDATE SUP CHANGE Sup Pos '
                                                 || obj.p_supr_pos
                                                 || ' Sub Pos '
                                                 || obj.p_curr_pos
                                                );
                                       END;
                                    ELSIF flag = 'E'
                                    THEN
                                       BEGIN
                                          UPDATE xxintg_pos_status
                                             SET st_flag = 'E'
                                           WHERE prev_emp_pos = sub_pos
                                             AND curr_emp_pos = sub_pos
                                             AND prev_sup_pos = obj.p_curr_pos
                                             AND curr_sup_pos = obj.p_curr_pos
                                             AND status = 'UPDATE'
                                             AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                          COMMIT;
                                       EXCEPTION
                                          WHEN OTHERS
                                          THEN
                                             fnd_file.put_line
                                                (fnd_file.LOG,
                                                    'ERROR in UPDATING XXINTG_POS_STATUS E UPDATE SUP CHANGE Sup Pos '
                                                 || obj.p_supr_pos
                                                 || ' Sub Pos '
                                                 || obj.p_curr_pos
                                                );
                                       END;
                                    END IF;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in Sup Change New Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Subordinate Position '
                                           || obj.p_curr_pos
                                          );

                                       BEGIN
                                          UPDATE xxintg_pos_status
                                             SET st_flag = 'E'
                                           WHERE prev_emp_pos = sub_pos
                                             AND curr_emp_pos = sub_pos
                                             AND prev_sup_pos = obj.p_curr_pos
                                             AND curr_sup_pos = obj.p_curr_pos
                                             AND status = 'UPDATE'
                                             AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                          COMMIT;
                                       EXCEPTION
                                          WHEN OTHERS
                                          THEN
                                             fnd_file.put_line
                                                (fnd_file.LOG,
                                                    'ERROR in UPDATING XXINTG_POS_STATUS E UPDATE SUP CHANGE Sup Pos '
                                                 || obj.p_supr_pos
                                                 || ' Sub Pos '
                                                 || obj.p_curr_pos
                                                );
                                       END;
                                 END;
                              END LOOP;

                              CLOSE c_sub;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                       (fnd_file.LOG,
                                           'ERROR in Sup Change New Sup Pos '
                                        || obj.p_supr_pos
                                        || ' Subordinate Position '
                                        || obj.p_curr_pos
                                       );

                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'E'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS E UPDATE SUP CHANGE Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                           END;
                        ELSE
                           BEGIN
                              SELECT DISTINCT hapf1.NAME
                                         INTO prev_sup
                                         FROM hr_all_positions_f hapf1
                                        WHERE hapf1.position_id =
                                                 (SELECT DISTINCT parent_position_id
                                                             FROM per_pos_structure_elements ppse
                                                            WHERE ppse.pos_structure_version_id =
                                                                        '1061'
                                                              AND ppse.subordinate_position_id =
                                                                     (SELECT DISTINCT position_id
                                                                                 FROM hr_all_positions_f
                                                                                WHERE UPPER
                                                                                         (NAME
                                                                                         ) =
                                                                                         UPPER
                                                                                            (obj.p_prev_pos
                                                                                            )
                                                                                  AND effective_end_date >=
                                                                                         TRUNC
                                                                                            (SYSDATE
                                                                                            )))
                                          AND hapf1.effective_end_date >=
                                                               TRUNC (SYSDATE);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                        'ERROR in finding prev Sup New Sup Pos '
                                     || obj.p_supr_pos
                                     || ' Sub Pos '
                                     || obj.p_curr_pos
                                    );
                           END;

                           BEGIN
                              INSERT INTO xxintg_pos_status
                                   VALUES (obj.p_prev_pos, obj.p_curr_pos,
                                           prev_sup, obj.p_supr_pos,
                                           'UPDATE', SYSDATE, 'P');

                              COMMIT;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                        'ERROR in INSERTING IN XXINTG_POS_STATUS New Sup Pos '
                                     || obj.p_supr_pos
                                     || ' Sub Pos '
                                     || obj.p_curr_pos
                                    );
                           END;

                           BEGIN
                              update_sup_pos_changed (obj.p_supr_pos,
                                                      obj.p_curr_pos,
                                                      flag
                                                     );

                              IF flag = 'S'
                              THEN
                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'S'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND prev_sup_pos = prev_sup
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS S UPDATE SUP CHANGE Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                              ELSIF flag = 'E'
                              THEN
                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'E'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND prev_sup_pos = prev_sup
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS E UPDATE SUP CHANGE Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                              END IF;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                       (fnd_file.LOG,
                                           'ERROR in Sup Change New Sup Pos '
                                        || obj.p_supr_pos
                                        || ' Subordinate Position '
                                        || obj.p_curr_pos
                                       );

                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'E'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND prev_sup_pos = prev_sup
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS E UPDATE SUP CHANGE Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                           END;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                                           (fnd_file.LOG,
                                               'ERROR in SUP CHANGE Sup Pos '
                                            || obj.p_supr_pos
                                            || ' Sub Pos '
                                            || obj.p_curr_pos
                                           );
                     END;
                  ELSE
                     BEGIN
                        INSERT INTO xxintg_shared_pos
                             VALUES (obj.p_empno, obj.p_empname,
                                     obj.p_prev_pos, obj.p_curr_pos,
                                     obj.p_prev_supr, obj.p_curr_supr,
                                     obj.p_supr_pos, obj.p_status);

                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                                  'ERROR in INSERTING XXINTG_SHARED_POS SUP CHANGE UPDATE Sup Pos '
                               || obj.p_supr_pos
                               || ' Sub Pos '
                               || obj.p_curr_pos
                              );
                     END;
                  END IF;
               ELSIF     (obj.p_prev_supr = obj.p_curr_supr)
                     AND (obj.p_prev_pos != obj.p_curr_pos
                         )                         --Employee Position changed
               THEN
                  IF (obj.p_curr_pos != obj.p_supr_pos)
                  THEN
                     DECLARE
                        pos_t       VARCHAR2 (500);
                        sub_pos_t   VARCHAR2 (500);
                     BEGIN
                        SELECT DISTINCT position_type
                                   INTO pos_t
                                   FROM hr_positions_x
                                  WHERE NAME = obj.p_prev_pos
                                    AND effective_end_date >= SYSDATE;

                        IF pos_t = 'SINGLE'
                        THEN
                           DECLARE
                              CURSOR c2
                              IS
                                 SELECT *
                                   FROM per_pos_structure_elements
                                  WHERE parent_position_id =
                                           (SELECT DISTINCT position_id
                                                       FROM hr_all_positions_f
                                                      WHERE UPPER (NAME) =
                                                               UPPER
                                                                  (obj.p_prev_pos
                                                                  )
                                                        AND effective_end_date >=
                                                               TRUNC (SYSDATE))
                                    AND pos_structure_version_id = '1061';

                              --SUBORDINATES OF PREV_POS
                              obj2       c2%ROWTYPE;
                              pos_name   VARCHAR2 (500);
                           BEGIN
                              OPEN c2;

                              BEGIN
                                 INSERT INTO xxintg_pos_status
                                      VALUES (obj.p_prev_pos, obj.p_curr_pos,
                                              obj.p_supr_pos, obj.p_supr_pos,
                                              'UPDATE', SYSDATE, 'P');

                                 COMMIT;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    fnd_file.put_line
                                       (fnd_file.LOG,
                                           'ERROR in INSERTING IN XXINTG_POS_STATUS Sup Pos '
                                        || obj.p_supr_pos
                                        || ' Sub Pos '
                                        || obj.p_curr_pos
                                       );
                              END;

                              create_pos_hier_proc (obj.p_supr_pos,
                                                    obj.p_curr_pos,
                                                    flag
                                                   );

                              IF flag = 'S'
                              THEN
                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'S'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND prev_sup_pos = obj.p_supr_pos
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS S NEW Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                              ELSIF flag = 'E'
                              THEN
                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'E'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND prev_sup_pos = obj.p_supr_pos
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS E NEW Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );
                                 END;
                              END IF;

                              LOOP
                                 FETCH c2
                                  INTO obj2;

                                 EXIT WHEN c2%NOTFOUND;
                                 pos_name := NULL;

                                 BEGIN
                                    SELECT DISTINCT NAME
                                               INTO pos_name
                                               FROM hr_all_positions_f
                                              WHERE position_id =
                                                       obj2.subordinate_position_id
                                                AND effective_end_date >=
                                                               TRUNC (SYSDATE);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR inside Emp Pos changed pos_name sup pos '
                                           || obj.p_curr_pos
                                           || ' sub pos '
                                           || pos_name
                                          );
                                 END;

                                 BEGIN
                                    SELECT DISTINCT position_type
                                               INTO sub_pos_t
                                               FROM hr_positions_x
                                              WHERE NAME = pos_name
                                                AND effective_end_date >=
                                                                       SYSDATE;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR inside Emp Pos changed shared pos pos_name sup pos '
                                           || obj.p_curr_pos
                                           || ' sub pos '
                                           || pos_name
                                          );
                                 END;

                                 IF (    (sub_pos_t = 'SINGLE')
                                     AND (pos_name != obj.p_curr_pos)
                                     AND (pos_name != obj.p_supr_pos)
                                    )
                                 THEN
                                    BEGIN
                                       INSERT INTO xxintg_pos_status
                                            VALUES (pos_name, pos_name,
                                                    obj.p_prev_pos,
                                                    obj.p_curr_pos, 'UPDATE',
                                                    SYSDATE, 'P');

                                       COMMIT;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR in INSERTING IN XXINTG_POS_STATUS'
                                              || ' Supervisor Position '
                                              || obj.p_curr_pos
                                              || ' Subordinate Position '
                                              || pos_name
                                             );
                                    END;

                                    BEGIN
                                       update_sup_pos_changed
                                                             (obj.p_curr_pos,
                                                              pos_name,
                                                              flag
                                                             );

                                       IF flag = 'S'
                                       THEN
                                          BEGIN
                                             UPDATE xxintg_pos_status
                                                SET st_flag = 'S'
                                              WHERE prev_emp_pos = pos_name
                                                AND curr_emp_pos = pos_name
                                                AND prev_sup_pos =
                                                                obj.p_prev_pos
                                                AND curr_sup_pos =
                                                                obj.p_curr_pos
                                                AND status = 'UPDATE'
                                                AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                             COMMIT;
                                          EXCEPTION
                                             WHEN OTHERS
                                             THEN
                                                fnd_file.put_line
                                                   (fnd_file.LOG,
                                                       'ERROR in UPDATING XXINTG_POS_STATUS S NEW'
                                                    || SQLERRM
                                                    || ' Supervisor Position '
                                                    || obj.p_curr_pos
                                                    || ' Subordinate Position '
                                                    || pos_name
                                                   );
                                          END;
                                       ELSIF flag = 'E'
                                       THEN
                                          BEGIN
                                             UPDATE xxintg_pos_status
                                                SET st_flag = 'E'
                                              WHERE prev_emp_pos = pos_name
                                                AND curr_emp_pos = pos_name
                                                AND prev_sup_pos =
                                                                obj.p_prev_pos
                                                AND curr_sup_pos =
                                                                obj.p_curr_pos
                                                AND status = 'UPDATE'
                                                AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                             COMMIT;
                                          EXCEPTION
                                             WHEN OTHERS
                                             THEN
                                                fnd_file.put_line
                                                   (fnd_file.LOG,
                                                       'ERROR in UPDATING XXINTG_POS_STATUS E NEW'
                                                    || SQLERRM
                                                    || ' Supervisor Position '
                                                    || obj.p_supr_pos
                                                    || ' Subordinate Position '
                                                    || obj.p_curr_pos
                                                   );
                                          END;
                                       END IF;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR inside loop Emp Pos changed'
                                              || SQLERRM
                                              || ' supervisor position '
                                              || obj.p_curr_pos
                                              || ' subordinate postion '
                                              || pos_name
                                             );

                                          BEGIN
                                             UPDATE xxintg_pos_status
                                                SET st_flag = 'E'
                                              WHERE prev_emp_pos = pos_name
                                                AND curr_emp_pos = pos_name
                                                AND prev_sup_pos =
                                                                obj.p_prev_pos
                                                AND curr_sup_pos =
                                                                obj.p_curr_pos
                                                AND status = 'UPDATE'
                                                AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                             COMMIT;
                                          EXCEPTION
                                             WHEN OTHERS
                                             THEN
                                                fnd_file.put_line
                                                   (fnd_file.LOG,
                                                       'ERROR in UPDATING XXINTG_POS_STATUS E NEW'
                                                    || SQLERRM
                                                    || ' Supervisor Position '
                                                    || obj.p_supr_pos
                                                    || ' Subordinate Position '
                                                    || obj.p_curr_pos
                                                   );
                                          END;
                                    END;
                                 ELSE
                                    BEGIN
                                       INSERT INTO xxintg_shared_pos
                                            VALUES (NULL, NULL, pos_name,
                                                    pos_name, NULL, NULL,
                                                    obj.p_curr_pos,
                                                    obj.p_status);

                                       COMMIT;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR in INSERTING XXINTG_SHARED_POS SUP CHANGE UPDATE Sup Pos '
                                              || obj.p_supr_pos
                                              || ' Sub Pos '
                                              || pos_name
                                             );
                                    END;
                                 END IF;
                              END LOOP;

                              CLOSE c2;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                     (fnd_file.LOG,
                                         'ERROR in Emp Pos changed  Sup Pos '
                                      || obj.p_supr_pos
                                      || ' Sub Pos '
                                      || obj.p_curr_pos
                                     );

                                 BEGIN
                                    UPDATE xxintg_pos_status
                                       SET st_flag = 'E'
                                     WHERE prev_emp_pos = obj.p_prev_pos
                                       AND curr_emp_pos = obj.p_curr_pos
                                       AND prev_sup_pos = obj.p_supr_pos
                                       AND curr_sup_pos = obj.p_supr_pos
                                       AND status = 'UPDATE'
                                       AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                    COMMIT;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in UPDATING XXINTG_POS_STATUS S NEW'
                                           || SQLERRM
                                           || ' Supervisor Position '
                                           || obj.p_supr_pos
                                           || ' Subordinate Position '
                                           || obj.p_curr_pos
                                          );
                                 END;
                           END;
                        ELSE
                           BEGIN
                              INSERT INTO xxintg_shared_pos
                                   VALUES (obj.p_empno, obj.p_empname,
                                           obj.p_prev_pos, obj.p_curr_pos,
                                           obj.p_prev_supr, obj.p_curr_supr,
                                           obj.p_supr_pos, obj.p_status);

                              COMMIT;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                        'ERROR in INSERTING XXINTG_SHARED_POS SUP CHANGE UPDATE Sup Pos '
                                     || obj.p_supr_pos
                                     || ' Sub Pos '
                                     || obj.p_curr_pos
                                    );
                           END;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                                  'ERROR in POSITION_TYPE OF EMP POS CHANGE PREV POS Sup Pos '
                               || obj.p_supr_pos
                               || ' Sub Pos '
                               || obj.p_curr_pos
                              );
                     END;
                  ELSE
                     BEGIN
                        INSERT INTO xxintg_shared_pos
                             VALUES (obj.p_empno, obj.p_empname,
                                     obj.p_prev_pos, obj.p_curr_pos,
                                     obj.p_prev_supr, obj.p_curr_supr,
                                     obj.p_supr_pos, obj.p_status);

                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                                  'ERROR in INSERTING XXINTG_SHARED_POS SUP CHANGE UPDATE Sup Pos '
                               || obj.p_supr_pos
                               || ' Sub Pos '
                               || obj.p_curr_pos
                              );
                     END;
                  END IF;
               ELSIF     (obj.p_prev_supr != obj.p_curr_supr)
                     AND (obj.p_prev_pos != obj.p_curr_pos
                         )     --Employee Position and supervisor both changed
               THEN
                  IF (obj.p_curr_pos != obj.p_supr_pos)
                  THEN
                     DECLARE
                        pos_t       VARCHAR2 (100);
                        sub_pos_t   VARCHAR2 (100);
                     BEGIN
                        SELECT DISTINCT position_type
                                   INTO pos_t
                                   FROM hr_positions_x
                                  WHERE NAME = obj.p_prev_pos
                                    AND effective_end_date >= SYSDATE;

                        IF pos_t = 'SINGLE'
                        THEN
                           DECLARE
                              CURSOR c3
                              IS
                                 SELECT *
                                   FROM per_pos_structure_elements
                                  WHERE parent_position_id =
                                           (SELECT DISTINCT position_id
                                                       FROM hr_all_positions_f
                                                      WHERE UPPER (NAME) =
                                                               UPPER
                                                                  (obj.p_prev_pos
                                                                  )
                                                        AND effective_end_date >=
                                                               TRUNC (SYSDATE))
                                    AND pos_structure_version_id = '1061';

                              -- Subordinates of Prev Pos
                              obj3       c3%ROWTYPE;
                              pos_name   VARCHAR2 (500);
                              prev_sup   VARCHAR2 (500);
                           BEGIN
                              OPEN c3;

                              BEGIN
                                 SELECT DISTINCT hapf1.NAME
                                            INTO prev_sup
                                            FROM hr_all_positions_f hapf1
                                           WHERE hapf1.position_id =
                                                    (SELECT DISTINCT parent_position_id
                                                                FROM per_pos_structure_elements ppse
                                                               WHERE ppse.pos_structure_version_id =
                                                                        '1061'
                                                                 AND ppse.subordinate_position_id =
                                                                        (SELECT DISTINCT position_id
                                                                                    FROM hr_all_positions_f
                                                                                   WHERE UPPER
                                                                                            (NAME
                                                                                            ) =
                                                                                            UPPER
                                                                                               (obj.p_prev_pos
                                                                                               )
                                                                                     AND effective_end_date >=
                                                                                            TRUNC
                                                                                               (SYSDATE
                                                                                               )))
                                             AND hapf1.effective_end_date >=
                                                               TRUNC (SYSDATE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    fnd_file.put_line
                                       (fnd_file.LOG,
                                           'ERROR in both finding prev Sup New Sup Pos '
                                        || obj.p_supr_pos
                                        || ' New Sub Pos '
                                        || obj.p_curr_pos
                                       );
                              END;

                              BEGIN
                                 INSERT INTO xxintg_pos_status
                                      VALUES (obj.p_prev_pos, obj.p_curr_pos,
                                              prev_sup, obj.p_supr_pos,
                                              'UPDATE', SYSDATE, 'P');

                                 COMMIT;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    fnd_file.put_line
                                       (fnd_file.LOG,
                                           'ERROR in INSERTING IN XXINTG_POS_STATUS Sup Pos '
                                        || obj.p_supr_pos
                                        || ' Sub Pos '
                                        || obj.p_curr_pos
                                       );
                              END;

                              BEGIN
                                 create_pos_hier_proc (obj.p_supr_pos,
                                                       obj.p_curr_pos,
                                                       flag
                                                      );

                                 IF flag = 'S'
                                 THEN
                                    BEGIN
                                       UPDATE xxintg_pos_status
                                          SET st_flag = 'S'
                                        WHERE prev_emp_pos = obj.p_prev_pos
                                          AND curr_emp_pos = obj.p_curr_pos
                                          AND prev_sup_pos = prev_sup
                                          AND curr_sup_pos = obj.p_supr_pos
                                          AND status = 'UPDATE'
                                          AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                       COMMIT;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR in UPDATING XXINTG_POS_STATUS S NEW Sup Pos '
                                              || obj.p_supr_pos
                                              || ' Sub Pos '
                                              || obj.p_curr_pos
                                             );
                                    END;
                                 ELSIF flag = 'E'
                                 THEN
                                    BEGIN
                                       UPDATE xxintg_pos_status
                                          SET st_flag = 'E'
                                        WHERE prev_emp_pos = obj.p_prev_pos
                                          AND curr_emp_pos = obj.p_curr_pos
                                          AND prev_sup_pos = prev_sup
                                          AND curr_sup_pos = obj.p_supr_pos
                                          AND status = 'UPDATE'
                                          AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                       COMMIT;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR in UPDATING XXINTG_POS_STATUS E NEW Sup Pos '
                                              || obj.p_supr_pos
                                              || ' Sub Pos '
                                              || obj.p_curr_pos
                                             );
                                    END;
                                 END IF;

                                 LOOP
                                    FETCH c3
                                     INTO obj3;

                                    EXIT WHEN c3%NOTFOUND;
                                    pos_name := NULL;

                                    BEGIN
                                       SELECT DISTINCT NAME
                                                  INTO pos_name
                                                  FROM hr_all_positions_f
                                                 WHERE position_id =
                                                          obj3.subordinate_position_id
                                                   AND effective_end_date >=
                                                               TRUNC (SYSDATE);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR in BOTH POS_NAME Sup Pos '
                                              || obj.p_supr_pos
                                              || ' Sub Pos '
                                              || obj.p_curr_pos
                                             );
                                    END;

                                    BEGIN
                                       SELECT DISTINCT position_type
                                                  INTO sub_pos_t
                                                  FROM hr_positions_x
                                                 WHERE NAME = pos_name
                                                   AND effective_end_date >=
                                                                       SYSDATE;

                                       IF (    (sub_pos_t = 'SINGLE')
                                           AND (pos_name != obj.p_curr_pos)
                                           AND (pos_name != obj.p_supr_pos)
                                          )
                                       THEN
                                          BEGIN
                                             INSERT INTO xxintg_pos_status
                                                  VALUES (pos_name, pos_name,
                                                          obj.p_prev_pos,
                                                          obj.p_curr_pos,
                                                          'UPDATE', SYSDATE,
                                                          'P');

                                             COMMIT;
                                          EXCEPTION
                                             WHEN OTHERS
                                             THEN
                                                fnd_file.put_line
                                                   (fnd_file.LOG,
                                                       'ERROR in INSERTING IN XXINTG_POS_STATUS Sup Pos '
                                                    || obj.p_curr_pos
                                                    || ' Sub Pos '
                                                    || pos_name
                                                   );
                                          END;

                                          BEGIN
                                             update_sup_pos_changed
                                                             (obj.p_curr_pos,
                                                              pos_name,
                                                              flag
                                                             );

                                             IF flag = 'S'
                                             THEN
                                                BEGIN
                                                   UPDATE xxintg_pos_status
                                                      SET st_flag = 'S'
                                                    WHERE prev_emp_pos =
                                                                      pos_name
                                                      AND curr_emp_pos =
                                                                      pos_name
                                                      AND prev_sup_pos =
                                                                obj.p_prev_pos
                                                      AND curr_sup_pos =
                                                                obj.p_curr_pos
                                                      AND status = 'UPDATE'
                                                      AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                                   COMMIT;
                                                EXCEPTION
                                                   WHEN OTHERS
                                                   THEN
                                                      fnd_file.put_line
                                                         (fnd_file.LOG,
                                                             'ERROR in UPDATING XXINTG_POS_STATUS S NEW'
                                                          || SQLERRM
                                                          || ' Supervisor Position '
                                                          || obj.p_curr_pos
                                                          || ' Subordinate Position '
                                                          || pos_name
                                                         );
                                                END;
                                             ELSIF flag = 'E'
                                             THEN
                                                BEGIN
                                                   UPDATE xxintg_pos_status
                                                      SET st_flag = 'E'
                                                    WHERE prev_emp_pos =
                                                                      pos_name
                                                      AND curr_emp_pos =
                                                                      pos_name
                                                      AND prev_sup_pos =
                                                                obj.p_prev_pos
                                                      AND curr_sup_pos =
                                                                obj.p_curr_pos
                                                      AND status = 'UPDATE'
                                                      AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                                   COMMIT;
                                                EXCEPTION
                                                   WHEN OTHERS
                                                   THEN
                                                      fnd_file.put_line
                                                         (fnd_file.LOG,
                                                             'ERROR in UPDATING XXINTG_POS_STATUS S NEW'
                                                          || SQLERRM
                                                          || ' Supervisor Position '
                                                          || obj.p_curr_pos
                                                          || ' Subordinate Position '
                                                          || pos_name
                                                         );
                                                END;
                                             END IF;
                                          EXCEPTION
                                             WHEN OTHERS
                                             THEN
                                                fnd_file.put_line
                                                   (fnd_file.LOG,
                                                       'ERROR in UPDATING XXINTG_POS_STATUS S NEW'
                                                    || SQLERRM
                                                    || ' Supervisor Position '
                                                    || obj.p_curr_pos
                                                    || ' Subordinate Position '
                                                    || pos_name
                                                   );

                                                BEGIN
                                                   UPDATE xxintg_pos_status
                                                      SET st_flag = 'E'
                                                    WHERE prev_emp_pos =
                                                                      pos_name
                                                      AND curr_emp_pos =
                                                                      pos_name
                                                      AND prev_sup_pos =
                                                                obj.p_prev_pos
                                                      AND curr_sup_pos =
                                                                obj.p_curr_pos
                                                      AND status = 'UPDATE'
                                                      AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                                   COMMIT;
                                                EXCEPTION
                                                   WHEN OTHERS
                                                   THEN
                                                      fnd_file.put_line
                                                         (fnd_file.LOG,
                                                             'ERROR in UPDATING XXINTG_POS_STATUS S NEW'
                                                          || SQLERRM
                                                          || ' Supervisor Position '
                                                          || obj.p_curr_pos
                                                          || ' Subordinate Position '
                                                          || pos_name
                                                         );
                                                END;
                                          END;
                                       ELSE
                                          BEGIN
                                             INSERT INTO xxintg_shared_pos
                                                  VALUES (NULL, NULL,
                                                          pos_name, pos_name,
                                                          NULL, NULL,
                                                          obj.p_curr_pos,
                                                          obj.p_status);

                                             COMMIT;
                                          EXCEPTION
                                             WHEN OTHERS
                                             THEN
                                                fnd_file.put_line
                                                   (fnd_file.LOG,
                                                       'ERROR in INSERTING XXINTG_SHARED_POS BOTH CHANGE Sup Pos '
                                                    || obj.p_curr_pos
                                                    || ' Sub Pos '
                                                    || pos_name
                                                   );
                                          END;
                                       END IF;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR in BOTH SUB POS TYPE Sup Pos '
                                              || obj.p_curr_pos
                                              || ' Sub Pos '
                                              || pos_name
                                             );
                                    END;
                                 END LOOP;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    fnd_file.put_line
                                          (fnd_file.LOG,
                                              'ERROR in BOTH CHANGE Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub Pos '
                                           || obj.p_curr_pos
                                          );

                                    BEGIN
                                       UPDATE xxintg_pos_status
                                          SET st_flag = 'E'
                                        WHERE prev_emp_pos = obj.p_prev_pos
                                          AND curr_emp_pos = obj.p_curr_pos
                                          AND prev_sup_pos = prev_sup
                                          AND curr_sup_pos = obj.p_supr_pos
                                          AND status = 'UPDATE'
                                          AND TRUNC (created_date) =
                                                               TRUNC (SYSDATE);

                                       COMMIT;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          fnd_file.put_line
                                             (fnd_file.LOG,
                                                 'ERROR in UPDATING XXINTG_POS_STATUS S NEW Sup Pos '
                                              || obj.p_supr_pos
                                              || ' Sub Pos '
                                              || obj.p_curr_pos
                                             );
                                    END;
                              END;

                              CLOSE c3;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                          (fnd_file.LOG,
                                              'Error in both change Sup Pos '
                                           || obj.p_supr_pos
                                           || ' Sub pos '
                                           || obj.p_curr_pos
                                          );
                           END;
                        ELSE
                           BEGIN
                              INSERT INTO xxintg_shared_pos
                                   VALUES (obj.p_empno, obj.p_empname,
                                           obj.p_prev_pos, obj.p_curr_pos,
                                           obj.p_prev_supr, obj.p_curr_supr,
                                           obj.p_supr_pos, obj.p_status);

                              COMMIT;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                        'ERROR in INSERTING XXINTG_SHARED_POS SUP CHANGE UPDATE Sup Pos '
                                     || obj.p_supr_pos
                                     || ' Sub Pos '
                                     || obj.p_curr_pos
                                    );
                           END;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                                 (fnd_file.LOG,
                                     'ERROR in POS_TYPE BOTH CHANGE Sup Pos '
                                  || obj.p_supr_pos
                                  || ' Sub Pos '
                                  || obj.p_curr_pos
                                 );
                     END;
                  ELSE
                     BEGIN
                        INSERT INTO xxintg_shared_pos
                             VALUES (obj.p_empno, obj.p_empname,
                                     obj.p_prev_pos, obj.p_curr_pos,
                                     obj.p_prev_supr, obj.p_curr_supr,
                                     obj.p_supr_pos, obj.p_status);

                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                                  'ERROR in INSERTING XXINTG_SHARED_POS SUP CHANGE UPDATE Sup Pos '
                               || obj.p_supr_pos
                               || ' Sub Pos '
                               || obj.p_curr_pos
                              );
                     END;
                  END IF;
               END IF;
            END IF;
         END IF;
      END LOOP;

      CLOSE c1;

      xx_gen_xls_sup;

      -- calling the procedure to get the update of supervisor who are notin the hierarchy
      DECLARE
         x_reqid    NUMBER;
         v_layout   BOOLEAN;
      BEGIN
         v_layout :=
            fnd_request.add_layout (template_appl_name      => 'XXINTG',
                                    template_code           => 'XXINTG_APPROVAL_GROUP',
                                    template_language       => 'en',
                                    template_territory      => 'US',
                                    output_format           => 'EXCEL'
                                   );
         x_reqid :=
            fnd_request.submit_request (application      => 'XXINTG',
                                        program          => 'XXINTG_APPROVAL_GROUP',
                                        description      => NULL,
                                        start_time       => NULL,
                                        sub_request      => FALSE
                                       );

         IF x_reqid = 0
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Failed in submitting the other conc program'
                              );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line
                             (fnd_file.LOG,
                                 'ERROR in submitting the other conc program'
                              || SQLERRM
                             );
      END;

      DELETE FROM xxintg_pos_changes
            WHERE TRUNC (created_date) < TRUNC (SYSDATE) - 30;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'ERROR in Main Procedure' || SQLERRM
                           );
   END main;
END; 
/
