DROP PACKAGE APPS.XX_OIC_COMMISSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OIC_COMMISSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Renjith
 Creation Date : 18-JAN-2014
 File Name     : XX_OIC_COMMISSION_PKG.pks
 Description   : This script creates the specification of the package
		 xx_oic_commission_pkg
 Change History:
 Date        Name                Remarks
 ----------- -------------       -----------------------------------
 18-JAN-2014 Renjith             Initial Development
*/
----------------------------------------------------------------------

   PROCEDURE main (  errbuf          OUT  VARCHAR2
                    ,retcode         OUT  NUMBER
                    ,p_pay_group_id  in   number
                    ,p_salesrep_id   in   number
                    ,p_email_req     in   varchar2
                    ,p_email_yn      in   varchar2
                    ,p_email_id      in   varchar2
                    ,p_layout        in   varchar2);

END xx_oic_commission_pkg;
/
