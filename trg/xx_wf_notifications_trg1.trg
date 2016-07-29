DROP TRIGGER APPS.XX_WF_NOTIFICATIONS_TRG1;

CREATE OR REPLACE TRIGGER APPS.XX_WF_NOTIFICATIONS_TRG1 
   BEFORE INSERT
   ON applsys.wf_notifications
   REFERENCING NEW AS new OLD AS old
   FOR EACH ROW
DISABLE
WHEN (
new.recipient_role <> 'SYSADMIN'
      )
DECLARE
BEGIN
   IF xx_fnd_isitok_2sendemail_fnc (:new.recipient_role) = 'FALSE'
   THEN
      :new.recipient_role := 'SYSADMIN';
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      :new.recipient_role := 'SYSADMIN';
END xx_wf_notifications_trg1;
/
