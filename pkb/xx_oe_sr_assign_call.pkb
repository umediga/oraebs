DROP PACKAGE BODY APPS.XX_OE_SR_ASSIGN_CALL;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OE_SR_ASSIGN_CALL" 
AS
/* $Header: XX_OE_SR_ASSIGN_CALL.pkb 1.0.0 2013/08/02 Sanjeev Kumar Gajula    $ */
  --------------------------------------------------------------------------------
  /*
  Created By     : Sanjeev Kumar Gajula
  Creation Date  : 02-AUG-2013
  Filename       : XX_OE_SR_ASSIGN_CALL.pkb
  Description    : Salesrep Assgingnemt 
  Change History:
  Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
  02-AUG-2013   1.0       Sanjeev Kumar       Initial development.
 -------------------------------------------------------------------------------- */
   PROCEDURE xx_oe_sr_assign_call_proc (
      itemtype    IN              VARCHAR2,
      itemkey     IN              VARCHAR2,
      actid       IN              NUMBER,
      funcmode    IN              VARCHAR2,
      resultout   IN OUT NOCOPY   VARCHAR2
   )
   IS
      l_header_id   NUMBER;
      l_line_id     NUMBER;
      l_status      VARCHAR2 (30);
      l_errormess   VARCHAR2 (1000);
--
   BEGIN
      IF funcmode = 'RUN'
      THEN
         l_line_id := TO_NUMBER (itemkey);

         BEGIN
            SELECT header_id
              INTO l_header_id
              FROM oe_order_lines_all
             WHERE line_id = l_line_id;
         END;

         
         xx_oe_salesrep_assign_ext_pkg.xx_oe_assign_salesrep_line
                                                                 (l_header_id,
                                                                  l_line_id,
                                                                  l_status,
                                                                  l_errormess
                                                                 );
          IF l_status = 'Success' then 
          resultout := 'COMPLETE';
          return;
          elsif
          l_status = 'Error' then 
           wf_core.CONTEXT ('xx_oe_salesrep_assign_ext_pkg',
                          'xx_oe_assign_salesrep_line ',
                          itemtype,
                          itemkey,
                          TO_CHAR (actid),
                          funcmode,
                          'ERROR : ' || l_errormess
                         );
               resultout := 'COMPLETE';          
           end if;             
                                                                 
                                                                 
                                                                 
                     
         
      END IF;
      
      
         IF (funcmode = 'CANCEL')
         THEN
            NULL;
            resultout := 'COMPLETE';
            RETURN;
         END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         wf_core.CONTEXT ('xx_oe_sr_assign_call',
                          'xx_oe_sr_assign_call_proc ',
                          itemtype,
                          itemkey,
                          TO_CHAR (actid),
                          funcmode,
                          'ERROR : ' || l_errormess
                         );
            resultout := 'COMPLETE';             
         RAISE;
         
            end XX_OE_SR_ASSIGN_CALL_PROC;
END xx_oe_sr_assign_call; 
/
