DROP TRIGGER APPS.XX_JTF_USER_REG_TRG;

CREATE OR REPLACE TRIGGER APPS.XX_JTF_USER_REG_TRG 
----------------------------------------------------------------------
/* $Header: XXJTF_USER_REG_TRG.trg 1.0 2012/07/20 12:00:00 pnarva noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 20-Jul-2012
 File Name      : XXJTF_USER_REG_TRG.trg
 Description    : This script creates the Trigger xx_jtf_user_reg_trg
                  on the custom table to Lunch custom approval WF

 Change History:

 Version Date          Name                    Remarks
 ------- -----------   ----                    ----------------------
 1.0     20-Jul-2012   IBM Development Team    Initial development.
*/
----------------------------------------------------------------------
   AFTER INSERT
   ON xxintg.xxjtf_user_reg_tbl
   FOR EACH ROW
DECLARE
   x_error_msg         VARCHAR2 (2000);
   x_item_type         VARCHAR2 (1000) := 'XXIBEAPR';
   x_item_key          NUMBER;
   x_user_key          VARCHAR2 (500);
   x_workflowprocess   VARCHAR2 (1000) := 'XXIBE_USER_APPROVAL';
BEGIN
   SELECT xxjtf_user_reg_s.NEXTVAL
     INTO x_item_key
     FROM DUAL;

   x_user_key := 'USERKEY:' || x_item_key;
   wf_engine.createprocess (itemtype      => x_item_type,
                            itemkey       => x_item_key,
                            process       => x_workflowprocess
                           );
   wf_engine.setitemuserkey (itemtype      => x_item_type,
                             itemkey       => x_item_key,
                             userkey       => x_user_key
                            );
   wf_engine.setitemowner (itemtype      => x_item_type,
                           itemkey       => x_item_key,
                           owner         => fnd_profile.VALUE ('USER_NAME')
                          );
   wf_engine.setitemattrtext (x_item_type,
                              x_item_key,
                              'USER_NAME',
                              :NEW.account_name
                             );
   wf_engine.setitemattrtext (x_item_type,
                              x_item_key,
                              'XXIBE_SEQ_NUM',
                              :NEW.seq_num
                             );
   wf_engine.startprocess (x_item_type, x_item_key);
EXCEPTION
   WHEN OTHERS
   THEN
      x_error_msg := 'Error In WF Submitting ' || SUBSTR (SQLERRM, 11, 200);
      raise_application_error (-20000, x_error_msg);
END;
/
