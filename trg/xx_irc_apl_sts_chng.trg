DROP TRIGGER APPS.XX_IRC_APL_STS_CHNG;

CREATE OR REPLACE TRIGGER APPS.XX_IRC_APL_STS_CHNG 
----------------------------------------------------------------------
/*
 Created By    : Yogesh Rudrasetty
 Creation Date : 29-MAY-2012
 File Name     : xx_irc_apl_sts_chng.trg
 Description   : This script creates the Body definition of the package
		 xx_irc_notif_be_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 07-MAY-2012 Yogesh Rudrasetty     Initial Development
*/
----------------------------------------------------------------------
   AFTER INSERT
   ON hr.irc_assignment_statuses
   FOR EACH ROW
DECLARE
       x_ret_msg                   VARCHAR2(2000);
   BEGIN
       x_ret_msg:=xx_irc_notif_trg_pkg.applicant_sts_change_notif(:new.assignment_id,:new.assignment_status_type_id);
   EXCEPTION
      WHEN OTHERS
	THEN
         NULL;
   END;
/
