DROP PROCEDURE APPS.XX_USER_UTIL;

CREATE OR REPLACE PROCEDURE APPS."XX_USER_UTIL" as
   CURSOR c
   IS
      SELECT b.user_name, a.email_address email_address_hr
        FROM per_people_x a, fnd_user b
       WHERE a.person_id = b.employee_id
         AND a.person_type_id IN (1125, 1120, 1122, 1118, 1121)
         AND b.email_address IS NULL
         AND a.email_address IS NOT NULL;-- AND rownum < 10;

   TYPE ty_c IS TABLE OF c%ROWTYPE
      INDEX BY PLS_INTEGER;

   l_c   ty_c;
BEGIN
   OPEN c;

   LOOP
      FETCH c
      BULK COLLECT INTO l_c LIMIT 1000;

      FOR i IN 1 .. l_c.COUNT
      LOOP
         fnd_user_pkg.updateuser (x_user_name                       => l_c (i).user_name,
                                  x_owner                           => NULL,
                                  x_unencrypted_password            => NULL,
                                  x_session_number                  => 0,
                                  x_start_date                      => NULL,
                                  x_end_date                        => NULL,
                                  x_last_logon_date                 => NULL,
                                  x_description                     => NULL,
                                  x_password_date                   => NULL,
                                  x_password_accesses_left          => NULL,
                                  x_password_lifespan_accesses      => NULL,
                                  x_password_lifespan_days          => NULL,
                                  x_employee_id                     => NULL,
                                  x_email_address                   => l_c (i).email_address_hr,
                                  x_fax                             => NULL,
                                  x_customer_id                     => NULL,
                                  x_supplier_id                     => NULL,
                                  x_user_guid                       => NULL,
                                  x_change_source                   => NULL
                                 );
      END LOOP;

      COMMIT;
      EXIT WHEN l_c.COUNT = 0;
   END LOOP;

   CLOSE c;
END; 
/
