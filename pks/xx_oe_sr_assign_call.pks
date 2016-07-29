DROP PACKAGE APPS.XX_OE_SR_ASSIGN_CALL;

CREATE OR REPLACE PACKAGE APPS."XX_OE_SR_ASSIGN_CALL" AUTHID CURRENT_USER
AS
/* $Header: XX_OE_SR_ASSIGN_CALL.pks 1.0.0 2013/08/02 Sanjeev Kumar Gajula    $ */
  --------------------------------------------------------------------------------
  /*
  Created By     : Sanjeev Kumar Gajula
  Creation Date  : 02-AUG-2013
  Filename       : XX_OE_SR_ASSIGN_CALL.pks
  Description    : Salesrep Assgingnemt 
  Change History:
  Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
  02-AUG-2013   1.0       Sanjeev Kumar       Initial development.
 -------------------------------------------------------------------------------- */
procedure xx_oe_sr_assign_call_proc( itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2);
end xx_oe_sr_assign_call; 
/
