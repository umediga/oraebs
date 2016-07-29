DROP PACKAGE BODY APPS.XX_FND_UTILS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_FND_UTILS_PKG" 
IS
/* +===================================================================+
-- | Name  : xx_fnd_util_pkg.sql
-- | Description : This procedure is used to define new FND users, define
-- |               a copy of seed responsibility and assign responsibility
-- |               to the user.
-- | Parameters : Accept data in an excel sheet in pre-defined format
-- | Purpose:     This parameters determines how many years to go back and fetch item related
-- |              activities.
-- | Returns :
-- |              None.
-- | Created By : Jbhosale.
-- | Creation Date : 10/28/2011
-- | Modification History:
-- |          Modified By    Date         Description
-- |          Jbhosale       10/28/2011   Initial Creation.
-- |          Jbhosale       22/02/2012   Added password lifespan param.
-- |
-- +==================================================================*/
     PROCEDURE create_user
     IS
          v_user_check                  NUMBER;
          v_debug                       VARCHAR2 (200);

          CURSOR get_user
          IS
               SELECT DISTINCT user_name,                  --employee_type || employee description,
                                         employee_type description, email_address, start_date,
                               employee_id                                       -- Added Person Id
                                          ,
                               attribute2                                -- Added Password Lifespan
                          FROM xx_fnd_user_resp                                      --xx_fnd_user;
                         WHERE attribute4 = 'NEW';
     -- Added by Jagdish 02/22/2012 for excluding certain data.
     BEGIN
          INSERT INTO xx_debug
               VALUES ('FND:USER_CREATION', SYSDATE || 'Start - User Creation Process');

          FOR i IN get_user
          LOOP
-------------------------------------------------
-- Check if user already exists --
-------------------------------------------------
               BEGIN
                    SELECT 1
                      INTO v_user_check
                      FROM fnd_user
                     WHERE user_name = i.user_name || g_prefix;

                    UPDATE xx_fnd_user_resp x
                       SET attribute5 = attribute5 || '-' || 'DUPLICATE_USR'
                     WHERE user_name = i.user_name AND attribute4 = 'NEW';
               EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                         BEGIN
                              fnd_user_pkg.createuser (x_user_name                     =>    i.user_name
                                                                                          || g_prefix,
                                                       x_owner                         => 'CUST',
                                                       x_unencrypted_password          => 'integra.0',
                                                       x_description                   => i.description,
                                                       x_email_address                 => i.email_address,
                                                       x_start_date                    => i.start_date,
                                                       x_employee_id                   => i.employee_id,
                                                       x_password_lifespan_days        => i.attribute2
                                                      --> 22/02/2012 Added by Jagdish
                                                      );

                              UPDATE xx_fnd_user_resp x
                                 SET attribute1 = i.user_name || g_prefix
                               WHERE user_name = i.user_name AND attribute4 = 'NEW';

                              COMMIT;
                         EXCEPTION
                              WHEN OTHERS
                              THEN
                                   v_debug := SUBSTR (SQLERRM,
                                                      1,
                                                      100
                                                     );

                                   INSERT INTO xx_debug
                                        VALUES ('FND:USER_CREATION',
                                                   SYSDATE
                                                || ' - '
                                                || v_debug
                                                || 'Error while creating users '
                                                || i.user_name
                                                || g_prefix);

                                   UPDATE xx_fnd_user_resp x
                                      SET attribute5 = attribute5 || '-' || 'ERROR_USR_CREATE'
                                    WHERE user_name = i.user_name AND attribute4 = 'NEW';
                         END;
               END;
          END LOOP;
     EXCEPTION
          WHEN OTHERS
          THEN
               INSERT INTO xx_debug
                    VALUES ('FND:USER_CREATION', SYSDATE || 'Error while creating users ');
     END create_user;

     PROCEDURE xx_copy_responsibility
     IS
          v_rowid                       VARCHAR2 (500);
          v_web_host_name               VARCHAR2 (500) := NULL;
          v_web_agent_name              VARCHAR2 (500) := NULL;
          v_version                     VARCHAR2 (500) := 4;
          v_responsibility_id           NUMBER;
          v_debug                       VARCHAR2 (500);
          v_resp_check                  NUMBER;

          CURSOR get_resp
          IS
               /*
               SELECT DISTINCT frt.responsibility_name, fr.responsibility_key, fr.application_id,
                               fr.data_group_id, fr.menu_id, fr.request_group_id,
                               fr.group_application_id
                          FROM fnd_responsibility fr,
                               xx_fnd_user_resp xfr,
                               fnd_responsibility_tl frt
                         WHERE fr.responsibility_key = xfr.responsibility_key
                           AND frt.responsibility_name = xfr.responsibility_name
                           AND frt.LANGUAGE = 'US'
                           AND fr.responsibility_id = frt.responsibility_id;
               */
               SELECT DISTINCT frt.responsibility_name, fr.responsibility_key, fr.application_id,
                               fr.data_group_id, fr.menu_id, fr.request_group_id,
                               fr.group_application_id, fr.VERSION
                          FROM fnd_responsibility fr,
                               xx_fnd_user_resp xfr,
                               fnd_responsibility_tl frt
                         WHERE 1 = 1
--fr.responsibility_key = xfr.responsibility_key -- 02/22/2012:Jbhosle Commented as excel supplied by users will not have responsibility Key.
                           AND frt.responsibility_name = xfr.responsibility_name
                           AND frt.LANGUAGE = 'US'
                           AND fr.responsibility_id = frt.responsibility_id
                           AND attribute4 = 'NEW';

          CURSOR c2
          IS
               SELECT DISTINCT responsibility_name
                          FROM xx_fnd_user_resp
                         WHERE attribute4 = 'NEW';
     BEGIN
-- get current responsibility_id

          ----------------------------------------------
-- Update Responsibility Key column --
----------------------------------------------
          FOR j IN c2
          LOOP
               BEGIN
                    UPDATE xx_fnd_user_resp x
                       SET responsibility_key = (SELECT DISTINCT responsibility_key
                                                            FROM fnd_responsibility_vl
                                                           WHERE responsibility_name =
                                                                               x.responsibility_name)
                     WHERE responsibility_key IS NULL
                       AND x.responsibility_name = j.responsibility_name
                       AND attribute4 = 'NEW';

                    COMMIT;
               EXCEPTION
                    WHEN OTHERS
                    THEN
                         UPDATE xx_fnd_user_resp
                            SET attribute5 = attribute5 || ' Error: Unable to Update Resp Key'
                          WHERE responsibility_name = j.responsibility_name AND attribute4 = 'NEW';
               END;
          -- END;
          END LOOP;

          INSERT INTO xx_debug
               VALUES ('FND:RESP_CREATION', SYSDATE || 'Updated Responsibility_key');

          FOR i IN get_resp
          LOOP
               --  INSERT INTO xx_debug
               --       VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || i.responsibility_name);
               BEGIN
                    SELECT 1
                      INTO v_resp_check
                      FROM fnd_responsibility_vl
                     WHERE responsibility_name =
                                REPLACE ('INTG ' || g_prefix || ' ' || i.responsibility_name,
                                         '_',
                                         ' '
                                        );
                                  /* SUBSTR (i.responsibility_name,
                                                                       1,
                                                                       23
                                                                      );*/
               --      INSERT INTO xx_debug--          VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || 'Responsibility Found');
               EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                         --    INSERT INTO xx_debug
                         --         VALUES ('FND:RESP_CREATION',
                         --                 SYSDATE || ' ' || 'Responsibility Not Found');
                         BEGIN
                              SELECT fnd_responsibility_s.NEXTVAL
                                INTO v_responsibility_id
                                FROM DUAL;

                              --      INSERT INTO xx_debug
                              --           VALUES ('FND:RESP_CREATION',
                              --                   SYSDATE || ' ' || 'Sequence ' || v_responsibility_id);

                              -- run API
                              BEGIN
                                   fnd_responsibility_pkg.insert_row
                                         (x_rowid                            => v_rowid,
                                          x_responsibility_id                => v_responsibility_id,
                                          x_application_id                   => i.application_id,
                                          x_web_host_name                    => v_web_host_name,
                                          x_web_agent_name                   => v_web_agent_name,
                                          x_data_group_application_id        => i.application_id,
                                          x_data_group_id                    => i.data_group_id,
                                          x_menu_id                          => i.menu_id,
                                          x_start_date                       => SYSDATE,
                                          x_end_date                         => NULL,
                                          x_group_application_id             => i.group_application_id,
                                          x_request_group_id                 => i.request_group_id,
                                          x_version                          => i.VERSION,
                                          x_responsibility_key               =>    'INTG'
                                                                                || g_prefix
                                                                                || '_'
                                                                                || SUBSTR
                                                                                        (i.responsibility_key,
                                                                                         1,
                                                                                         21
                                                                                        ),
                                          x_responsibility_name              => REPLACE
                                                                                     (   'INTG'
                                                                                      || g_prefix
                                                                                      || ' '
                                                                                      || i.responsibility_name,
                                                                                      '_',
                                                                                      ' '
                                                                                     ),
                                          x_description                      => '',
                                          x_creation_date                    => SYSDATE,
                                          x_created_by                       => -1,
                                          x_last_update_date                 => SYSDATE,
                                          x_last_updated_by                  => -1,
                                          x_last_update_login                => 0
                                         );
                                   COMMIT;

                                   --     INSERT INTO xx_debug
                                   --          VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || 'After API');
                                   UPDATE xx_fnd_user_resp
                                      SET new_responsibility_name =
                                               REPLACE (   'INTG'
                                                        || g_prefix
                                                        || ' '
                                                        || i.responsibility_name,
                                                        '_',
                                                        ' '
                                                       ),
                                          new_resp_key =
                                                  'INTG'
                                               || g_prefix
                                               || '_'
                                               || SUBSTR (i.responsibility_key,
                                                          1,
                                                          21
                                                         )
                                    WHERE responsibility_name = i.responsibility_name
                                      AND responsibility_key = i.responsibility_key;
--                                   INSERT INTO xx_debug
--                                        VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || 'After Update');
                              -- fnd_responsibility_pkg.resp_synch(v_application_id , v_responsibility_id );
                              EXCEPTION
                                   WHEN OTHERS
                                   THEN
                                        BEGIN
                                             v_debug := SUBSTR (SQLERRM,
                                                                1,
                                                                200
                                                               );

                                             INSERT INTO xx_debug
                                                  VALUES ('FND:RESP_CREATION', v_debug);
                                        END;
                              END;
                         END;
               END;
          END LOOP;
     END xx_copy_responsibility;

     PROCEDURE xx_copy_responsibility_xns
     IS
          v_rowid                       VARCHAR2 (500);
          v_web_host_name               VARCHAR2 (500) := NULL;
          v_web_agent_name              VARCHAR2 (500) := NULL;
          v_version                     VARCHAR2 (500) := 4;
          v_responsibility_id           NUMBER;
          v_debug                       VARCHAR2 (500);
          v_resp_check                  NUMBER;

          CURSOR get_resp
          IS
               SELECT DISTINCT frt.responsibility_name, fr.responsibility_key, fr.application_id,
                               fr.data_group_id, fr.menu_id, fr.request_group_id,
                               fr.group_application_id, fr.VERSION
                          FROM fnd_responsibility fr,
                               xx_fnd_user_resp xfr,
                               fnd_responsibility_tl frt
                         WHERE 1 = 1
                           --fr.responsibility_key = replace(xfr.responsibility_key,'INTG_','')
                           AND frt.responsibility_name =
                                                      REPLACE (xfr.responsibility_name,
                                                               'INTG ',
                                                               ''
                                                              )
                           AND frt.LANGUAGE = 'US'
                           AND fr.responsibility_id = frt.responsibility_id;
     BEGIN
-- get current responsibility_id

          ----------------------------------------------
-- Update Responsibility Key column --
----------------------------------------------
          BEGIN
               UPDATE xx_fnd_user_resp x
                  SET responsibility_key = (SELECT DISTINCT responsibility_key
                                                       FROM fnd_responsibility_vl
                                                      WHERE responsibility_name =
                                                                               x.responsibility_name)
                WHERE responsibility_key IS NULL;
          EXCEPTION
               WHEN OTHERS
               THEN
                    RAISE;
          END;

          INSERT INTO xx_debug
               VALUES ('FND:RESP_CREATION', SYSDATE || 'Updated Responsibility_key');

          FOR i IN get_resp
          LOOP
               --  INSERT INTO xx_debug
               --       VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || i.responsibility_name);
               BEGIN
                    SELECT 1
                      INTO v_resp_check
                      FROM fnd_responsibility_vl
                     WHERE responsibility_key =
                                'INTG_XNS ' || g_prefix || '_'
                                || SUBSTR (i.responsibility_key,
                                           1,
                                           21
                                          );
               --      INSERT INTO xx_debug
                --          VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || 'Responsibility Found');
               EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                         --    INSERT INTO xx_debug
                         --         VALUES ('FND:RESP_CREATION',
                         --                 SYSDATE || ' ' || 'Responsibility Not Found');
                         BEGIN
                              SELECT fnd_responsibility_s.NEXTVAL
                                INTO v_responsibility_id
                                FROM DUAL;

                              --      INSERT INTO xx_debug
                              --           VALUES ('FND:RESP_CREATION',
                              --                   SYSDATE || ' ' || 'Sequence ' || v_responsibility_id);

                              -- run API
                              BEGIN
                                   fnd_responsibility_pkg.insert_row
                                            (x_rowid                            => v_rowid,
                                             x_responsibility_id                => v_responsibility_id,
                                             x_application_id                   => i.application_id,
                                             x_web_host_name                    => v_web_host_name,
                                             x_web_agent_name                   => v_web_agent_name,
                                             x_data_group_application_id        => i.application_id,
                                             x_data_group_id                    => i.data_group_id,
                                             x_menu_id                          => i.menu_id,
                                             x_start_date                       => SYSDATE,
                                             x_end_date                         => NULL,
                                             x_group_application_id             => i.group_application_id,
                                             x_request_group_id                 => i.request_group_id,
                                             x_version                          => i.VERSION,
                                             x_responsibility_key               =>    'INTG_TXN'
                                                                                   || g_prefix
                                                                                   || '_'
                                                                                   || SUBSTR
                                                                                           (i.responsibility_key,
                                                                                            1,
                                                                                            21
                                                                                           ),
                                             x_responsibility_name              =>    'INTG TXN '
                                                                                   || g_prefix
                                                                                   || ' '
                                                                                   || i.responsibility_name,
                                             x_description                      => '',
                                             x_creation_date                    => SYSDATE,
                                             x_created_by                       => -1,
                                             x_last_update_date                 => SYSDATE,
                                             x_last_updated_by                  => -1,
                                             x_last_update_login                => 0
                                            );
                                   COMMIT;

                                   --     INSERT INTO xx_debug
                                   --          VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || 'After API');
                                   UPDATE xx_fnd_user_resp
                                      SET new_responsibility_name =
                                               'INTG TXN ' || g_prefix || ' '
                                               || i.responsibility_name,
                                          new_resp_key =
                                                  'INTG_TXN'
                                               || g_prefix
                                               || '_'
                                               || SUBSTR (i.responsibility_key,
                                                          1,
                                                          21
                                                         )
                                    WHERE responsibility_name = i.responsibility_name
                                      AND responsibility_key = i.responsibility_key;
--                                   INSERT INTO xx_debug
--                                        VALUES ('FND:RESP_CREATION', SYSDATE || ' ' || 'After Update');
                              -- fnd_responsibility_pkg.resp_synch(v_application_id , v_responsibility_id );
                              EXCEPTION
                                   WHEN OTHERS
                                   THEN
                                        BEGIN
                                             v_debug := SUBSTR (SQLERRM,
                                                                1,
                                                                200
                                                               );

                                             INSERT INTO xx_debug
                                                  VALUES ('FND:RESP_CREATION', v_debug);
                                        END;
                              END;
                         END;
               END;
          END LOOP;
     END xx_copy_responsibility_xns;

     PROCEDURE assign_responsibility
     IS
          l_user_id                     NUMBER;

          CURSOR cur_rec (p_user_name IN VARCHAR)
          IS
               SELECT new_resp_key,
                                   --a.RESPONSIBILITY_KEY,
                                   a.responsibility_id, a.application_id, a.data_group_id,
                      b.attribute1, c.application_short_name
                 FROM fnd_responsibility_vl a, xx_fnd_user_resp b, fnd_application c
                WHERE 1 = 1
                  AND a.responsibility_name = b.responsibility_name
                  AND a.application_id = c.application_id
                  AND UPPER (b.attribute1) = UPPER (p_user_name)
                  AND attribute4 = 'NEW';

          CURSOR cur_user
          IS
               SELECT DISTINCT a.user_id, b.attribute1
                          FROM fnd_user a, xx_fnd_user_resp b
                         WHERE a.user_name = UPPER (b.attribute1);

          --AND a.user_name = 'JAGBHOSALE';
          v_user_id                     NUMBER;
          v_resp_id                     NUMBER;
          v_app_id                      NUMBER;
     BEGIN
          SELECT user_id
            INTO v_user_id
            FROM fnd_user
           WHERE user_name = 'SYSADMIN';

          SELECT responsibility_id, application_id                            --, responsibility_key
            INTO v_resp_id, v_app_id
            FROM fnd_responsibility
           WHERE responsibility_key = 'SYSTEM_ADMINISTRATOR';

          fnd_global.apps_initialize (v_user_id,                                        /*sysdamin*/
                                      v_resp_id,                            /*SYSTEM_ADMINISTRATOR*/
                                      v_app_id,
                                      0,
                                      -1
                                     );

          FOR rec_user IN cur_user
          LOOP
               FOR rec_cur IN cur_rec (rec_user.attribute1)
               LOOP
                    /*   fnd_user_resp_groups_api.insert_assignment
                                                       (user_id                              => l_user_id,
                                                        responsibility_id                    => rec_cur.responsibility_id,
                                                        responsibility_application_id        => rec_cur.application_id,
                                                        security_group_id                    => rec_cur.DATA_GROUP_ID,
                                                        start_date                           => SYSDATE - 1,
                                                        end_date                             => NULL,
                                                        description                          => NULL
                                                       );
                       --COMMIT;
                     */
                    IF (    rec_cur.attribute1 IS NOT NULL
                        AND rec_cur.application_short_name IS NOT NULL
                        AND rec_cur.new_resp_key IS NOT NULL
                       )
                    THEN
                         BEGIN
                              fnd_user_pkg.addresp (username              => UPPER
                                                                                  (rec_cur.attribute1),
                                                    resp_app              => rec_cur.application_short_name,
                                                    resp_key              => rec_cur.new_resp_key
                                                                                                 --'FNDWF_ADMIN_WEB'
                              ,
                                                    security_group        => 'STANDARD',
                                                    description           => NULL,
                                                    start_date            => SYSDATE - 1,
                                                    end_date              => NULL
                                                   );
                              COMMIT;
                         EXCEPTION
                              WHEN OTHERS
                              THEN
                                   INSERT INTO xx_debug
                                        VALUES ('FND:RESP_ASSIGN',
                                                   SYSDATE
                                                || ' '
                                                || 'Error while adding responsibility to user '
                                                || UPPER (rec_cur.attribute1)
                                                || ' with responsibility '
                                                || rec_cur.new_resp_key);

                                   UPDATE xx_fnd_user_resp x
                                      SET attribute5 = attribute5 || '-' || 'ERROR_RESP_ASSIGN'
                                    WHERE attribute1 = rec_cur.attribute1
                                      AND new_resp_key = rec_cur.new_resp_key;
                         END;
                    --END IF;
                    END IF;
               END LOOP;
          END LOOP;
     END assign_responsibility;

     PROCEDURE xx_copy_menu
     IS
          x_menu_name                   VARCHAR2 (200) := 'XX_HR_ACTIONS_MENU';

          CURSOR c2
          IS
               SELECT DISTINCT c.menu_name, d.user_menu_name, d.TYPE, d.description
                          FROM xx_fnd_user_resp a,
                               fnd_responsibility_vl b,
                               fnd_menus c,
                               fnd_menus_vl d
                         WHERE a.responsibility_key = b.responsibility_key
                           AND b.menu_id = c.menu_id
                           AND c.menu_id = d.menu_id;

          CURSOR c1 (p_menu_name IN VARCHAR2)
          IS
               SELECT   a.*, b.menu_name sub_menu_name, c.function_name
                   FROM fnd_menu_entries_vl a, fnd_menus b, fnd_form_functions c
                  WHERE a.sub_menu_id = b.menu_id(+)
                    AND a.function_id = c.function_id(+)
                    AND a.menu_id = (SELECT menu_id
                                       FROM fnd_menus_vl
                                      WHERE menu_name = p_menu_name)
               ORDER BY entry_sequence;
     BEGIN
          FOR r2 IN c2
          LOOP
               x_menu_name := 'INTG_' || r2.menu_name;
               fnd_menus_pkg.load_row (x_menu_name             => 'INTG_' || r2.menu_name,
                                       x_menu_type             => r2.TYPE,
                                       x_user_menu_name        => 'INTG ' || r2.user_menu_name,
                                       x_description           => 'INTG ' || r2.description,
                                       x_owner                 => 'SEED',
                                       x_custom_mode           => 'FORCE'
                                      );

               FOR r1 IN c1 (r2.menu_name)
               LOOP
                    fnd_menu_entries_pkg.load_row (x_mode                    => 'REPLACE',
                                                   x_ent_sequence            => r1.entry_sequence,
                                                   x_menu_name               => x_menu_name,
                                                   x_sub_menu_name           => r1.sub_menu_name,
                                                   x_function_name           => r1.function_name,
                                                   x_grant_flag              => r1.grant_flag,
                                                   x_prompt                  => r1.prompt,
                                                   x_description             => r1.description,
                                                   x_owner                   => 'SEED',
                                                   x_custom_mode             => 'FORCE',
                                                   x_last_update_date        => NULL
                                                  );
               END LOOP;
          END LOOP;
     END xx_copy_menu;

     PROCEDURE xx_copy_menu_ex_setup
     IS
          x_menu_name                   VARCHAR2 (200) := 'XX_HR_ACTIONS_MENU';

          CURSOR c2
          IS
               SELECT DISTINCT c.menu_name, d.user_menu_name, d.TYPE, d.description
                          FROM xx_fnd_user_resp a,
                               fnd_responsibility_vl b,
                               fnd_menus c,
                               fnd_menus_vl d
                         WHERE a.responsibility_key = b.responsibility_key
                           AND b.menu_id = c.menu_id
                           AND c.menu_id = d.menu_id;

          CURSOR c1 (p_menu_name IN VARCHAR2)
          IS
               SELECT   a.*, b.menu_name sub_menu_name, c.function_name
                   FROM fnd_menu_entries_vl a, fnd_menus b, fnd_form_functions c
                  WHERE a.sub_menu_id = b.menu_id(+)
                    AND a.function_id = c.function_id(+)
                    AND (b.menu_name NOT LIKE ('%SET%UP%') OR UPPER (a.prompt) NOT LIKE
                                                                                       ('%SET%UP%'
                                                                                       )
                        )
                    AND a.menu_id = (SELECT menu_id
                                       FROM fnd_menus_vl
                                      WHERE menu_name = p_menu_name)
               ORDER BY entry_sequence;
     BEGIN
          FOR r2 IN c2
          LOOP
               x_menu_name := 'INTG_TXN_' || r2.menu_name;
               fnd_menus_pkg.load_row (x_menu_name             => 'INTG_TXN_' || r2.menu_name,
                                       x_menu_type             => r2.TYPE,
                                       x_user_menu_name        => 'INTG TXN ' || r2.user_menu_name,
                                       x_description           => 'INTG TXN ' || r2.description,
                                       x_owner                 => 'SEED',
                                       x_custom_mode           => 'FORCE'
                                      );

               FOR r1 IN c1 (r2.menu_name)
               LOOP
                    fnd_menu_entries_pkg.load_row (x_mode                    => 'REPLACE',
                                                   x_ent_sequence            => r1.entry_sequence,
                                                   x_menu_name               => x_menu_name,
                                                   x_sub_menu_name           => r1.sub_menu_name,
                                                   x_function_name           => r1.function_name,
                                                   x_grant_flag              => r1.grant_flag,
                                                   x_prompt                  => r1.prompt,
                                                   x_description             => r1.description,
                                                   x_owner                   => 'SEED',
                                                   x_custom_mode             => 'FORCE',
                                                   x_last_update_date        => NULL
                                                  );
               END LOOP;
          END LOOP;
     END xx_copy_menu_ex_setup;

     PROCEDURE xx_copy_menu_ex_xns
     IS
          x_menu_name                   VARCHAR2 (200) := 'XX_HR_ACTIONS_MENU';

          CURSOR c2
          IS
               SELECT DISTINCT c.menu_name, d.user_menu_name, d.TYPE, d.description
                          FROM xx_fnd_user_resp a,
                               fnd_responsibility_vl b,
                               fnd_menus c,
                               fnd_menus_vl d
                         WHERE a.responsibility_key = b.responsibility_key
                           AND b.menu_id = c.menu_id
                           AND c.menu_id = d.menu_id;

          CURSOR c1 (p_menu_name IN VARCHAR2)
          IS
               SELECT   a.*, b.menu_name sub_menu_name, c.function_name
                   FROM fnd_menu_entries_vl a, fnd_menus b, fnd_form_functions c
                  WHERE a.sub_menu_id = b.menu_id(+)
                    AND a.function_id = c.function_id(+)
                    AND (b.menu_name LIKE ('%SET%UP%') OR UPPER (a.prompt) LIKE ('%SET%UP%'))
                    AND a.menu_id = (SELECT menu_id
                                       FROM fnd_menus_vl
                                      WHERE menu_name = p_menu_name)
               ORDER BY entry_sequence;
     BEGIN
          FOR r2 IN c2
          LOOP
               x_menu_name := 'INTG_SETUP_' || r2.menu_name;
               fnd_menus_pkg.load_row (x_menu_name             => 'INTG_SETUP_' || r2.menu_name,
                                       x_menu_type             => r2.TYPE,
                                       x_user_menu_name        => 'INTG SETUP ' || r2.user_menu_name,
                                       x_description           => 'INTG SETUP ' || r2.description,
                                       x_owner                 => 'SEED',
                                       x_custom_mode           => 'FORCE'
                                      );

               FOR r1 IN c1 (r2.menu_name)
               LOOP
                    fnd_menu_entries_pkg.load_row (x_mode                    => 'REPLACE',
                                                   x_ent_sequence            => r1.entry_sequence,
                                                   x_menu_name               => x_menu_name,
                                                   x_sub_menu_name           => r1.sub_menu_name,
                                                   x_function_name           => r1.function_name,
                                                   x_grant_flag              => r1.grant_flag,
                                                   x_prompt                  => r1.prompt,
                                                   x_description             => r1.description,
                                                   x_owner                   => 'SEED',
                                                   x_custom_mode             => 'FORCE',
                                                   x_last_update_date        => NULL
                                                  );
               END LOOP;
          END LOOP;
     END xx_copy_menu_ex_xns;

     PROCEDURE xx_copy_rbac_menu (p_top_menu_name IN VARCHAR)
     IS
          x_menu_name                   VARCHAR2 (200) := NULL;             --'XX_HR_ACTIONS_MENU';
          v_menu_exists                 NUMBER;
          v_sub_menu_name               fnd_menus_vl.menu_name%TYPE;
          v_menu_id                     NUMBER;

          CURSOR c2
          IS
               SELECT DISTINCT c.menu_name, d.user_menu_name, d.TYPE, d.description
                          FROM                                          -- xx_fnd_user_resp a,
                                                                        -- fnd_responsibility_vl b,
                               fnd_menus c, fnd_menus_vl d
                         WHERE 1 = 1                 -- a.responsibility_key = b.responsibility_key
                           -- AND b.menu_id = c.menu_id
                           AND c.menu_id = d.menu_id
                           AND d.menu_name = p_top_menu_name;

          CURSOR c1 (p_menu_name IN VARCHAR2)
          IS
               SELECT   a.*, b.menu_name sub_menu_name, c.function_name
                   FROM fnd_menu_entries_vl a, fnd_menus b, fnd_form_functions c
                  WHERE a.sub_menu_id = b.menu_id(+)
                    AND a.function_id = c.function_id(+)
                    -- AND (b.menu_name LIKE ('%SET%UP%') OR UPPER (a.prompt) LIKE ('%SET%UP%'))
                    AND a.menu_id = (SELECT menu_id
                                       FROM fnd_menus_vl
                                      WHERE menu_name = p_menu_name)
               ORDER BY entry_sequence;
     BEGIN
          FOR r2 IN c2
          LOOP
               x_menu_name := 'INTG_' || SUBSTR (r2.menu_name,
                                                 1,
                                                 25
                                                );
               v_menu_id := NULL;

               BEGIN
                    SELECT menu_id
                      INTO v_menu_id
                      FROM fnd_menus_vl
                     WHERE menu_name = x_menu_name;
               EXCEPTION
                    WHEN OTHERS
                    THEN
                         v_menu_id := -1;
               END;

               IF (v_menu_id = -1)
               THEN
                    fnd_menus_pkg.load_row (x_menu_name             => x_menu_name,
                                            x_menu_type             => r2.TYPE,
                                            x_user_menu_name        => 'INTG ' || r2.user_menu_name,
                                            x_description           => 'INTG ' || r2.description,
                                            x_owner                 => 'SEED',
                                            x_custom_mode           => 'FORCE'
                                           );

                    FOR r1 IN c1 (r2.menu_name)
                    LOOP
                         v_sub_menu_name := NULL;

-------------------------------------------
-- Copy sub Menu
-------------------------------------------
                         IF (r1.sub_menu_name IS NOT NULL)
                         THEN
                              xx_copy_rbac_menu (r1.sub_menu_name);

                              BEGIN
                                   SELECT 1, d.menu_name
                                     INTO v_menu_exists, v_sub_menu_name
                                     FROM fnd_menus_vl d
                                    WHERE 1 = 1       -- a.responsibility_key = b.responsibility_key
                                      --AND c.menu_id = d.menu_id
                                      AND d.menu_name = 'INTG_' || SUBSTR (r1.sub_menu_name,
                                                                           1,
                                                                           25
                                                                          );
                              EXCEPTION
                                   WHEN OTHERS
                                   THEN
                                        NULL;
                              END;
                         ELSE
                              v_menu_exists := 1;
                         END IF;

-------------------------------------------
-- Copy sub Menu - END.
-------------------------------------------
                         IF (v_menu_exists = 1)
                         THEN
                              fnd_menu_entries_pkg.load_row
                                            (x_mode                    => 'REPLACE',
                                             x_ent_sequence            => r1.entry_sequence,
                                             x_menu_name               => x_menu_name,
                                             x_sub_menu_name           => v_sub_menu_name,
                                                                                 --r1.sub_menu_name,
                                             x_function_name           => r1.function_name,
                                             x_grant_flag              => 'N',     -- r1.grant_flag,
                                             x_prompt                  => r1.prompt,
                                             x_description             => r1.description,
                                             x_owner                   => 'SEED',
                                             x_custom_mode             => 'FORCE',
                                             x_last_update_date        => NULL
                                            );
                         END IF;
                    END LOOP;
               END IF;
          END LOOP;
     END xx_copy_rbac_menu;

     PROCEDURE xx_data_cleanup
     IS
     BEGIN
-----------------------------------------
-- Remove Special Characters --
-----------------------------------------
          UPDATE xx_fnd_user_resp
             SET user_name = LTRIM (RTRIM (user_name)),
                 responsibility_name = LTRIM (RTRIM (responsibility_name)),
                 employee = LTRIM (RTRIM (employee)),
                 employee_type = LTRIM (RTRIM (employee_type)),
                 responsibility_key = LTRIM (RTRIM (responsibility_key)),
                 new_responsibility_name = LTRIM (RTRIM (new_responsibility_name)),
                 new_resp_key = LTRIM (RTRIM (new_resp_key)),
                 role_key = LTRIM (RTRIM (role_key))
           WHERE attribute4 = 'NEW';

--------------------------------------------
-- Remove dirty carraiage return from data
--------------------------------------------
          UPDATE xx_fnd_user_resp
             SET user_name = REPLACE (user_name,
                                      CHR (10),
                                      ''
                                     ),
                 responsibility_name = REPLACE (responsibility_name,
                                                CHR (10),
                                                ''
                                               ),
                 employee = REPLACE (employee,
                                     CHR (10),
                                     ''
                                    ),
                 employee_type = REPLACE (employee_type,
                                          CHR (10),
                                          ''
                                         ),
                 responsibility_key = REPLACE (responsibility_key,
                                               CHR (10),
                                               ''
                                              ),
                 new_responsibility_name = REPLACE (new_responsibility_name,
                                                    CHR (10),
                                                    ''
                                                   ),
                 new_resp_key = REPLACE (new_resp_key,
                                         CHR (10),
                                         ''
                                        ),
                 role_key = REPLACE (role_key,
                                     CHR (10),
                                     ''
                                    )
           WHERE attribute4 = 'NEW';
     END;
END xx_fnd_utils_pkg; 
/


GRANT EXECUTE ON APPS.XX_FND_UTILS_PKG TO INTG_XX_NONHR_RO;
