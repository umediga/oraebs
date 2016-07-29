DROP PACKAGE BODY APPS.XX_OIC_COMMISSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OIC_COMMISSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Renjith
 Creation Date : 18-JAN-2014
 File Name     : XX_OIC_COMMISSION_PKG.pkb
 Description   : This script creates the body of the package
                 xx_oic_commission_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 05-APR-2012 Renjith               Initial Development
 19-JUN-2015 Sunil                 Case# 15237
*/
----------------------------------------------------------------------
PROCEDURE main (  errbuf          OUT  VARCHAR2
                 ,retcode         OUT  NUMBER
                 ,p_pay_group_id  IN   NUMBER
                 ,p_salesrep_id   IN   NUMBER
                 ,p_email_req     in   VARCHAR2
                 ,p_email_yn      IN   VARCHAR2
                 ,p_email_id      IN   VARCHAR2
                 ,p_layout        IN   VARCHAR2)
IS

   x_application      VARCHAR2(10) := 'XXINTG';

   x_program_name1    VARCHAR2(100) := 'XXOICCOMMSPLIT';
   x_program_desc1    VARCHAR2(100) := 'INTG OIC Commissions Statement Report With Split - '||p_layout;

   x_program_name2    VARCHAR2(100) := 'XXOICCOMMSPLITOTH';
   x_program_desc2    VARCHAR2(100) := 'INTG OIC Commissions Statement Report With Split - '||p_layout;

   x_program_name3    VARCHAR2(100) := 'XXOICCOMMISSION';
   x_program_desc3    VARCHAR2(100) := 'INTG OIC Commissions Statement Report Full - '||p_layout;

   x_program_name4    VARCHAR2(100) := 'XXOICCOMMISSIONOTH';
   x_program_desc4    VARCHAR2(100) := 'INTG OIC Commissions Statement Report Full - '||p_layout;

   x_layout_status    BOOLEAN      := FALSE;
   x_user_id          NUMBER       := fnd_global.user_id;
   x_resp_id          NUMBER       := fnd_global.resp_id;
   x_resp_appl_id     NUMBER       := fnd_global.resp_appl_id;
   x_reqid1           NUMBER;
   x_reqid            NUMBER;

   x_org_id number := MO_GLOBAL.get_current_org_id;
BEGIN

   FND_FILE.PUT_LINE( FND_FILE.LOG,'p_payrun_id    -> '||p_pay_group_id);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'p_salesrep_id  -> '||p_salesrep_id);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'p_email_req    -> '||p_email_req);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'p_email_yn:    -> '||p_email_yn);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'p_email_id:    -> '||p_email_id);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'p_layout:      -> '||p_layout);

   FND_FILE.PUT_LINE( FND_FILE.LOG,'x_org_id:      -> '||x_org_id);

   fnd_global.apps_initialize( x_user_id,       --User id
                               x_resp_id,       --responsibility_id
                               x_resp_appl_id); --application_id

   --mo_global.set_policy_context('S', x_org_id);
   --mo_global.init('ONT');

   fnd_request.set_org_id(x_org_id)                         ;

   IF NVL(p_email_yn,'Y') = 'Y' THEN
       IF p_layout = 'Spine' THEN
            -- Call Split Spine
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Call Split Spine');
            x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                       ,template_code      => x_program_name1
                                                       ,template_language  => 'en'
                                                       ,template_territory => 'US'
                                                       ,output_format      => 'EXCEL');

            x_reqid := fnd_request.submit_request( application      => x_application
                                                   ,program         => x_program_name1
                                                   ,description     => x_program_desc1
                                                   ,start_time      => SYSDATE
                                                   ,sub_request     => FALSE
                                                   ,argument1       => p_pay_group_id
                                                   ,argument2       => p_salesrep_id
                                                   ,argument3       => p_email_req
                                                   ,argument4       => p_email_yn
                                                   ,argument5       => p_email_id
                                                   ,argument6       => p_layout);
       ELSE
            -- Call Split Others
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Call Split Others');
            x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                       ,template_code      => x_program_name2
                                                       ,template_language  => 'en'
                                                       ,template_territory => 'US'
                                                       ,output_format      => 'EXCEL');

            x_reqid := fnd_request.submit_request( application      => x_application
                                                   ,program         => x_program_name2
                                                   ,description     => x_program_desc2
                                                   ,start_time      => SYSDATE
                                                   ,sub_request     => FALSE
                                                   ,argument1       => p_pay_group_id
                                                   ,argument2       => p_salesrep_id
                                                   ,argument3       => p_email_req
                                                   ,argument4       => p_email_yn
                                                   ,argument5       => p_email_id
                                                   ,argument6       => p_layout);
       END IF;
   ELSE
       IF p_layout = 'Spine' THEN
            -- Call Full Spine
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Call Full Spine');
            x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                       ,template_code      => x_program_name3
                                                       ,template_language  => 'en'
                                                       ,template_territory => 'US'
                                                       ,output_format      => 'EXCEL');

            x_reqid := fnd_request.submit_request( application     => x_application
                                                  ,program         => x_program_name3
                                                  ,description     => x_program_desc3
                                                  ,start_time      => SYSDATE
                                                  ,sub_request     => FALSE
                                                  ,argument1       => p_pay_group_id
                                                  ,argument2       => p_salesrep_id
                                                  ,argument3       => p_email_req
                                                  ,argument4       => p_email_yn
                                                  ,argument5       => p_email_id
                                                  ,argument6       => p_layout);
       ELSE
            -- Call Full Others
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Call Full Others');
            x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                       ,template_code      => x_program_name4
                                                       ,template_language  => 'en'
                                                       ,template_territory => 'US'
                                                       ,output_format      => 'EXCEL');

            x_reqid := fnd_request.submit_request( application     => x_application
                                                  ,program         => x_program_name4
                                                  ,description     => x_program_desc4
                                                  ,start_time      => SYSDATE
                                                  ,sub_request     => FALSE
                                                  ,argument1       => p_pay_group_id
                                                  ,argument2       => p_salesrep_id
                                                  ,argument3       => p_email_req
                                                  ,argument4       => p_email_yn
                                                  ,argument5       => p_email_id
                                                  ,argument6       => p_layout);
       END IF;
   END IF;
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE( FND_FILE.LOG, SUBSTR (SQLERRM, 1, 2000));
      retcode := 2;
END main;
END xx_oic_commission_pkg;

/
