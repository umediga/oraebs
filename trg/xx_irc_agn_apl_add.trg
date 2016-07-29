DROP TRIGGER APPS.XX_IRC_AGN_APL_ADD;

CREATE OR REPLACE TRIGGER APPS.XX_IRC_AGN_APL_ADD 
----------------------------------------------------------------------
/*
 Created By    : Yogesh Rudrasetty
 Creation Date : 30-MAY-2012
 File Name     : xx_irc_agn_apl_add.trg
 Description   : This script creates the trigger for insert on
                 per_all_assignments_f table
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-MAY-2012 Yogesh Rudrasetty     Initial Development
*/
----------------------------------------------------------------------
   AFTER INSERT
   ON hr.per_all_assignments_f
   FOR EACH ROW
DECLARE
       x_ret_msg                   VARCHAR2(500);
   BEGIN
       x_ret_msg:=xx_irc_notif_trg_pkg.agn_add_applicant_notif( :new.assignment_id
	       						             ,:new.person_id
       							             ,:new.assignment_type
       							             ,:new.assignment_status_type_id
       							             ,:new.vacancy_id
       							             ,:new.created_by
       							            );
   EXCEPTION
      WHEN OTHERS
	THEN
         NULL;
   END;
/
