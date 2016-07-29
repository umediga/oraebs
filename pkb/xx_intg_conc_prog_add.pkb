DROP PACKAGE BODY APPS.XX_INTG_CONC_PROG_ADD;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INTG_CONC_PROG_ADD" 
AS
   ----------------------------------------------------------------------
   /*
    Created By    : IBM Development Team
    Creation Date : 24-JUL-2013
    File Name     : XX_INTG_CONC_PROG_ADD.pkb
    Description   : This script creates the body of the package
                    xx_intg_conc_prog_add
    Change History:
    Date         Name                    Remarks
    -----------  -------------           -----------------------------------
    24-JUL-2013  IBM Development Team      Initial Draft.
    */
   ----------------------------------------------------------------------

   ------------------< add_prgrm_to_rqst_grp >------------------------------------------------------
   /**
   * PROCEDURE main
   *
   * DESCRIPTION
   *     procedure to add concurrent program to the request group
   *
   * ARGUMENTS
   *   IN:
   *      p_resp_name              Responsibility Name
   *      p_conc_prgrm_name        Concurrent program Name
   *
   *   OUT:
   *      errbuf                  Error
   *      retcode                 Code
   */
   --------------------------------------------------------------------------------

   PROCEDURE add_prgrm_to_rqst_grp (errbuf                 OUT VARCHAR2,
                                    retcode                OUT NUMBER,
                                    p_resp_name         IN     VARCHAR2,
                                    p_conc_prgrm_name   IN     VARCHAR2
                                    )
   IS
      l_program_short_name    VARCHAR2 (200);
      l_program_application   VARCHAR2 (200);
      l_request_group         VARCHAR2 (200);
      l_group_application     VARCHAR2 (200);
      l_proc                  VARCHAR2 (10) := 'Y';
      l_err                   VARCHAR2(200);

      CURSOR c_conc_prog_select
      IS
         SELECT   prog_id,
                  conc_program_name,
                  responsibility_name,
                  creation_date status,
                  created_by,
                  last_update_date,
                  last_update_by,
                  err_msg
           FROM   xx_conc_prog_uplaod
          WHERE   nvl(status,'E') = 'E';
   BEGIN
      IF p_resp_name IS NOT NULL AND p_conc_prgrm_name IS NOT NULL
      THEN
         BEGIN
            SELECT   frg.request_group_name, fapp.application_short_name
              INTO   l_request_group, l_group_application
              FROM   apps.fnd_request_groups frg,
                     apps.fnd_application_tl fapptl,
                     apps.fnd_application fapp,
                     apps.fnd_responsibility fnr,
                     apps.fnd_responsibility_tl fnrtl
             WHERE       frg.application_id = fapp.application_id
                     AND frg.request_group_id = fnr.request_group_id
                     AND frg.application_id = fnr.application_id
                     AND fnr.responsibility_id = fnrtl.responsibility_id
                     AND fnrtl.responsibility_name = p_resp_name
                     AND fnrtl.language = 'US'
                     AND fapptl.language = 'US'
                     AND fapptl.application_id = fapp.application_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               FND_FILE.PUT_LINE (fnd_file.LOG,
                  'No Requst group fonud for the given responsibility'||p_resp_name
               );
               dbms_output.put_line('No Requst group fonud for the given responsibility '||p_resp_name);
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (fnd_file.LOG,
                  'When others exception in finding request group'
               );
               dbms_output.put_line('When others exception in finding request group '||p_resp_name);
         END;

         BEGIN
            SELECT   fcp.concurrent_program_name, fapp.application_short_name
              INTO   l_program_short_name, l_program_application
              FROM   apps.fnd_concurrent_programs_tl fcpl,
                     apps.fnd_concurrent_programs fcp,
                     apps.fnd_application_tl fapptl,
                     apps.fnd_application fapp
             WHERE   fcpl.concurrent_program_id = fcp.concurrent_program_id
                     AND fcpl.application_id = fcp.application_id
                     AND fcpl.application_id = fapptl.application_id
                     AND fcpl.user_concurrent_program_name =
                           p_conc_prgrm_name
                     AND fcpl.language = 'US'
                     AND fapptl.language = 'US'
                     AND fapptl.application_id = fapp.application_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
              FND_FILE.PUT_LINE (fnd_file.LOG,'No Concurrent Progarm, Application found for the given Program Name');
              dbms_output.put_line('No Concurrent Progarm, Application found for the given Program Name '||p_conc_prgrm_name);
            WHEN OTHERS
            THEN
               FND_FILE.PUT_LINE (fnd_file.LOG,'When others exception in finding concurrent program application');
               dbms_output.put_line('When others exception in finding concurrent program application');
         END;

         BEGIN
            apps.fnd_program.add_to_group (
               program_short_name    => l_program_short_name,
               program_application   => l_program_application,
               request_group         => l_request_group,
               group_application     => l_group_application
            );


            FND_FILE.PUT_LINE (fnd_file.LOG, 'API called');
            dbms_output.put_line('API called');

            insert into  xx_conc_prog_uplaod (conc_program_name,responsibility_name,CREATION_DATE,CREATED_BY,LAST_UPDATE_DATE,LAST_UPDATE_BY,STATUS)
            VALUES (p_conc_prgrm_name,p_resp_name,sysdate,fnd_global.user_id,sysdate,fnd_global.user_id,'L');
            COMMIT;

            FND_FILE.PUT_LINE (fnd_file.OUTput,'Program : '||l_program_short_name||' Attached to Request Group '||l_request_group);
            dbms_output.put_line('Program : '||l_program_short_name||' Attached to Request Group '||l_request_group);

            EXCEPTION
              WHEN OTHERS THEN
                FND_FILE.PUT_LINE (fnd_file.LOG,SQLERRM);
                l_err := SQLERRM;
                IF l_err = 'ORA-00001: unique constraint (APPLSYS.FND_REQUEST_GROUP_UNITS_U1) violated' THEN
                   dbms_output.put_line('Program : '||l_program_short_name||' Attached to Request Group '||l_request_group);
                   FND_FILE.PUT_LINE (fnd_file.OUTput,'Program : '||l_program_short_name||' Attached to Request Group '||l_request_group);
                ELSE
                   FND_FILE.PUT_LINE(fnd_file.log,'Exception Attaching Program '||l_err);
                   dbms_output.put_line('Exception Attaching Program '||l_err);
               END IF;
               COMMIT;
            END;


      ELSIF p_resp_name IS NULL AND p_conc_prgrm_name IS NULL
      THEN
         FND_FILE.PUT_LINE (fnd_file.LOG,'Input parameters are NULL');
         FOR x_conc_prog_select IN c_conc_prog_select
         LOOP
            l_proc := 'Y';
            BEGIN
               SELECT   frg.request_group_name, fapp.application_short_name
                 INTO   l_request_group, l_group_application
                 FROM   apps.fnd_request_groups frg,
                        apps.fnd_application_tl fapptl,
                        apps.fnd_application fapp,
                        apps.fnd_responsibility fnr,
                        apps.fnd_responsibility_tl fnrtl
                WHERE       frg.application_id = fapp.application_id
                        AND frg.request_group_id = fnr.request_group_id
                        AND frg.application_id = fnr.application_id
                        AND fnr.responsibility_id = fnrtl.responsibility_id
                        AND fnrtl.responsibility_name =
                              x_conc_prog_select.responsibility_name
                        AND fnrtl.language = 'US'
                        AND fapptl.language = 'US'
                        AND fapptl.application_id = fapp.application_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  FND_FILE.PUT_LINE (fnd_file.LOG,
                  'No Requst group fonud for the given responsibility'||p_resp_name);
                  l_proc := 'N';
                  UPDATE   xx_conc_prog_uplaod
                     SET   ERR_MSG ='No Requst group fonud for the given responsibility',
                           STATUS = 'E',
                           CREATION_DATE = sysdate,
                           CREATED_BY = fnd_global.user_id,
                           LAST_UPDATE_DATE = SYSDATE,
                           LAST_UPDATE_BY = fnd_global.user_id
                   WHERE  prog_id  = x_conc_prog_select.prog_id;

                  COMMIT;
               WHEN OTHERS
               THEN
                  FND_FILE.PUT_LINE (fnd_file.LOG, 'When others exception in finding request group');
                  l_proc := 'N';
                  UPDATE   xx_conc_prog_uplaod
                     SET   ERR_MSG ='When others exception in finding request group',
                           STATUS = 'E',
                           CREATION_DATE = sysdate,
                           CREATED_BY = fnd_global.user_id,
                           LAST_UPDATE_DATE = SYSDATE,
                           LAST_UPDATE_BY = fnd_global.user_id
                   WHERE  prog_id  = x_conc_prog_select.prog_id;

                  COMMIT;
            END;
            IF l_proc = 'Y' THEN
            BEGIN
               SELECT   fcp.concurrent_program_name,
                        fapp.application_short_name
                 INTO   l_program_short_name, l_program_application
                 FROM   apps.fnd_concurrent_programs_tl fcpl,
                        apps.fnd_concurrent_programs fcp,
                        apps.fnd_application_tl fapptl,
                        apps.fnd_application fapp
                WHERE   fcpl.concurrent_program_id =
                           fcp.concurrent_program_id
                        AND fcpl.application_id = fcp.application_id
                        AND fcpl.application_id = fapptl.application_id
                        AND fcpl.user_concurrent_program_name =
                              x_conc_prog_select.conc_program_name
                        AND fcpl.language = 'US'
                        AND fapptl.language = 'US'
                        AND fapptl.application_id = fapp.application_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  FND_FILE.PUT_LINE (fnd_file.LOG,'No Concurrent Progarm, Application found for the given Program Name'||x_conc_prog_select.conc_program_name);
                  l_proc := 'N';
                  UPDATE   xx_conc_prog_uplaod
                     SET   ERR_MSG ='No Concurrent Progarm, Application found for the given Program Name',
                           STATUS = 'E',
                           CREATION_DATE = sysdate,
                           CREATED_BY = fnd_global.user_id,
                           LAST_UPDATE_DATE = SYSDATE,
                           LAST_UPDATE_BY = fnd_global.user_id
                   WHERE  prog_id  = x_conc_prog_select.prog_id;
                  COMMIT;
               WHEN OTHERS
               THEN
                  FND_FILE.PUT_LINE (fnd_file.LOG,'When others exception in finding concurrent program application');
                  l_proc := 'N';
                  UPDATE   xx_conc_prog_uplaod
                     SET   ERR_MSG ='When others exception in finding concurrent program application',
                           STATUS = 'E',
                           CREATION_DATE = sysdate,
                           CREATED_BY = fnd_global.user_id,
                           LAST_UPDATE_DATE = SYSDATE,
                           LAST_UPDATE_BY = fnd_global.user_id
                  WHERE  prog_id  = x_conc_prog_select.prog_id;
                  COMMIT;
            END;
           END IF;
           IF l_proc = 'Y' THEN

           BEGIN
            apps.fnd_program.add_to_group (
               program_short_name    => l_program_short_name,
               program_application   => l_program_application,
               request_group         => l_request_group,
               group_application     => l_group_application
            );

            UPDATE   xx_conc_prog_uplaod
               SET   STATUS = 'L',
                     ERR_MSG = NULL,
                     CREATION_DATE = sysdate,
                     CREATED_BY = fnd_global.user_id,
                     LAST_UPDATE_DATE = SYSDATE,
                     LAST_UPDATE_BY = fnd_global.user_id
             WHERE  prog_id  = x_conc_prog_select.prog_id;

            COMMIT;

            EXCEPTION

              WHEN OTHERS THEN
                FND_FILE.PUT_LINE (fnd_file.LOG,SQLERRM);
                l_err := SQLERRM;
                IF l_err = 'ORA-00001: unique constraint (APPLSYS.FND_REQUEST_GROUP_UNITS_U1) violated' THEN
                   UPDATE   xx_conc_prog_uplaod
                     SET   ERR_MSG = NULL,
                           STATUS = 'L',
                           CREATION_DATE = sysdate,
                           CREATED_BY = fnd_global.user_id,
                           LAST_UPDATE_DATE = SYSDATE,
                           LAST_UPDATE_BY = fnd_global.user_id
                   WHERE  prog_id  = x_conc_prog_select.prog_id;
                ELSE
                   UPDATE   xx_conc_prog_uplaod
                     SET   ERR_MSG = l_err,
                           STATUS = 'E',
                           CREATION_DATE = sysdate,
                           CREATED_BY = fnd_global.user_id,
                           LAST_UPDATE_DATE = SYSDATE,
                           LAST_UPDATE_BY = fnd_global.user_id
                   WHERE  prog_id  = x_conc_prog_select.prog_id;
               END IF;
               COMMIT;
            END;
           END IF;
         END LOOP;
      ELSIF ( (p_resp_name IS NOT NULL AND p_conc_prgrm_name IS NULL) OR (p_resp_name IS NULL AND p_conc_prgrm_name IS NOT NULL))
      THEN
         retcode := 2;
         FND_FILE.PUT_LINE (fnd_file.LOG,'Please enter both the parameters ');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         FND_FILE.PUT_LINE (fnd_file.LOG,'Adding Concurrent Program to Request Group Failed');
         retcode := 2;
   END add_prgrm_to_rqst_grp;
END xx_intg_conc_prog_add;
/
