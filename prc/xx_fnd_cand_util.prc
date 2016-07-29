DROP PROCEDURE APPS.XX_FND_CAND_UTIL;

CREATE OR REPLACE PROCEDURE APPS.XX_FND_CAND_UTIL as
   CURSOR c_candidates
   IS
      SELECT ROWID row_id, a.*
        FROM xxintg_new_candidate_user a
        where not exists (select 1 from fnd_user where user_name = upper(user_name_email));
       
   TYPE ty_candidate IS TABLE OF c_candidates%ROWTYPE
      INDEX BY PLS_INTEGER;

   l_candidates   ty_candidate;
BEGIN
   OPEN c_candidates;

   LOOP
      FETCH c_candidates
      BULK COLLECT INTO l_candidates LIMIT 500;

      FOR i IN 1 .. l_candidates.COUNT
      LOOP
----------------------------------------
-- Call Create User API --
-- -------------------------------------
         BEGIN
            fnd_user_pkg.createuser
                             (x_user_name                       => l_candidates
                                                                           (i).user_name_email,
                              x_owner                           => 'CUST',
                              x_unencrypted_password            => 'M1ltex.987',
                              x_session_number                  => 0,
                              x_start_date                      => '26-MAY-2013',
                              x_end_date                        => NULL,
                              x_last_logon_date                 => NULL,
                              x_description                     => 'External Candidate',
                              x_password_date                   => NULL,
                              x_password_accesses_left          => NULL,
                              x_password_lifespan_accesses      => NULL,
                              --x_password_lifespan_days     => 45, -- ?
                              x_employee_id                     => l_candidates
                                                                           (i).person_id
                             );

            BEGIN
               fnd_user_pkg.addresp (username            => upper(l_candidates
                                                                           (i).user_name_email),
                                     resp_app            => 'PER',
                                     resp_key            => 'IRC_EXT_CANDIDATE',
                                     security_group      => 'STANDARD',
                                     description         => 'PROD Configuration',
                                     start_date          => '26-MAY-2013',
                                     end_date            => NULL
                                    );
            EXCEPTION
               WHEN OTHERS
               THEN
                  UPDATE xxintg_new_candidate_user
                     SET attribute2 = 'RESP_ASSIGN_ERROR1'
                   WHERE unique_id = l_candidates (i).unique_id;
            END;
          
         ----------------------------------------------------
         -- Update Success For all--
         ----------------------------------------------------
          UPDATE xxintg_new_candidate_user
                     SET STATUS = 'SUCCESS2'
                   WHERE unique_id = l_candidates (i).unique_id;   
         EXCEPTION
            WHEN OTHERS
            THEN
               UPDATE xxintg_new_candidate_user
                  SET attribute1 = 'USER_CREATE_ERROR1'
                WHERE unique_id = l_candidates (i).unique_id;
         END;
      END LOOP;

      COMMIT;
      EXIT WHEN l_candidates.COUNT =0;
   END LOOP;

   CLOSE c_candidates;
END; 
/
