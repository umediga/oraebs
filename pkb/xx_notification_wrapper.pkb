DROP PACKAGE BODY APPS.XX_NOTIFICATION_WRAPPER;

CREATE OR REPLACE PACKAGE BODY APPS."XX_NOTIFICATION_WRAPPER" 
IS
   FUNCTION notify_user (p_subscription_guid   IN            RAW,
                         p_event               IN OUT NOCOPY WF_EVENT_T)
      RETURN VARCHAR2
   IS
      p_request_id   NUMBER;
      L_SQLERRM      varchar2 (4000);
      p_test         varchar2 (2000);
   BEGIN
      p_request_id :=
         SUBSTR (p_event.geteventkey (),
                 1,
                 INSTR (p_event.geteventkey (), ':') - 1);


      BEGIN
         XX_COMMON_PROCESS_EMAIL.NOTIFY_USER (p_request_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            L_SQLERRM := SQLERRM;

            INSERT INTO xxintg.XX_EMF_DEBUG_TRACE (
                                                     debug_text,
                                                     creation_date
                       )
              VALUES   (  'ERROR in Notification Wrapper while calling Notify User '
                           || L_SQLERRM,
                           SYSDATE
                       );
      END;


      INSERT INTO xxintg.XX_EMF_DEBUG_TRACE (
                                               debug_text,
                                               creation_date
                 )
        VALUES   (
                        'Event '
                     || p_event.getEventName ()
                     || ' received for Key=>'
                     || p_event.geteventkey ()
                     || p_request_id,
                     SYSDATE
                 );


      COMMIT;


      RETURN 'SUCCESS';
   EXCEPTION
      WHEN OTHERS
      THEN
         L_SQLERRM := L_SQLERRM || SQLERRM;

         INSERT INTO xxintg.XX_EMF_DEBUG_TRACE (
                                                  debug_text,
                                                  creation_date
                    )
           VALUES   (
                        'ERROR in Notification Wrapper ' || L_SQLERRM,
                        SYSDATE
                    );

         COMMIT;
         RETURN 'ERROR';
   END notify_user;
END xx_notification_wrapper;
/


GRANT EXECUTE ON APPS.XX_NOTIFICATION_WRAPPER TO INTG_XX_NONHR_RO;
