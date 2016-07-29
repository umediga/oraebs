DROP PACKAGE APPS.XX_IRC_NOTIF_TRG_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_IRC_NOTIF_TRG_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Yogesh
 Creation Date : 28-MAY-2012
 File Name     : xx_irc_notif_trg_pkg.pks
 Description   : This script creates the specification of the package
		 xx_irc_notif_trg_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 28-MAY-2012 Yogesh        Initial Development
*/
----------------------------------------------------------------------

    FUNCTION applicant_status_chg_notif ( p_assignment_id   IN      NUMBER
    					 ,p_appl_status     IN      VARCHAR2
    					)
    RETURN VARCHAR2;

----------------------------------------------------------------------

    FUNCTION applicant_asg_terminate_notif( p_assignment_id   IN      NUMBER
                                           ,p_appl_status     IN      VARCHAR2
                                          )
    RETURN VARCHAR2;

----------------------------------------------------------------------

    FUNCTION recuriter_add_applicant_notif ( p_assignment_id    IN      NUMBER
	                                    ,p_person_id        IN      NUMBER
                                            ,p_assignment_type  IN      VARCHAR2
                                            ,p_asst_sts_typ_id  IN      NUMBER
                                            ,p_vacancy_id       IN      NUMBER
                                            ,p_old_vacancy_id   IN      NUMBER
                                            ,p_created_by_id    IN      NUMBER
                                           )
    RETURN VARCHAR2;

----------------------------------------------------------------------

    FUNCTION agn_add_applicant_notif ( p_assignment_id    IN      NUMBER
	                              ,p_person_id        IN      NUMBER
                                      ,p_assignment_type  IN      VARCHAR2
                                      ,p_asst_sts_typ_id  IN      NUMBER
                                      ,p_vacancy_id       IN      NUMBER
                                      ,p_created_by_id    IN      NUMBER
                                     )
    RETURN VARCHAR2;
----------------------------------------------------------------------

    FUNCTION applicant_sts_change_notif( p_assignment_id       IN      NUMBER
                                        ,p_assignment_type_id  IN      NUMBER
                                       )
    RETURN VARCHAR2;

----------------------------------------------------------------------

    FUNCTION agn_candidate_reg_notif ( p_created_by_id   IN    NUMBER
                                      ,p_person_id       IN    NUMBER
                                      ,p_person_type_id  IN    NUMBER
                                      ,p_can_name        IN    VARCHAR2
                                      ,p_can_email       IN    VARCHAR2
                                     )
    RETURN VARCHAR2;

END xx_irc_notif_trg_pkg;
/
