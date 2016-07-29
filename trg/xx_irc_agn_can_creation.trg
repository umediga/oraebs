DROP TRIGGER APPS.XX_IRC_AGN_CAN_CREATION;

CREATE OR REPLACE TRIGGER APPS.XX_IRC_AGN_CAN_CREATION 
----------------------------------------------------------------------
/*
 Created By    : Yogesh Rudrasetty
 Creation Date : 30-May-2012
 File Name     : xx_irc_agn_can_creation.trg
 Description   : This script creates the trigger for every insert on
                 table per_all_people_f
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-MAY-2012 Yogesh Rudrasetty     Initial Development
*/
----------------------------------------------------------------------
   AFTER INSERT
   ON hr.per_all_people_f
   FOR EACH ROW
DECLARE
       x_ret_msg                   VARCHAR2(2000);
   BEGIN
       x_ret_msg:=xx_irc_notif_trg_pkg.agn_candidate_reg_notif( :new.created_by
                                                               ,:new.person_id
                                                               ,:new.person_type_id
                                                               ,:new.full_name
                                                               ,:new.email_address
                                                              );
   EXCEPTION
      WHEN OTHERS
	THEN
         NULL;
   END;
/
