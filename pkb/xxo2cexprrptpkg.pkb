DROP PACKAGE BODY APPS.XXO2CEXPRRPTPKG;

CREATE OR REPLACE PACKAGE BODY APPS.XXO2CEXPRRPTPKG
AS
----------------------------------------------------------------------
/*
 Created By    : Shiny George
 Creation Date : 21-JAN-2015
 File Name     : XXO2CEXPRRPTPKG.pkb
 Description   : This script creates the body of the package
                 XXO2CEXPRRPTPKG
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
21-JAN-2015  Shiny George          Initial Creation
----------------------------------------------------------------------
*/
PROCEDURE main ( errbuf          OUT  VARCHAR2,
                 RETCODE         OUT  NUMBER,
                 P_RUN_DATE       IN   VARCHAR2,
                 P_NO_OF_DAYS     IN   NUMBER,
                 P_DIVISION       IN   VARCHAR2,
                 P_SALES_TER      IN   VARCHAR2,
                 P_OU             IN   VARCHAR2,
                 P_FORMAT         IN   VARCHAR2,
                 P_EMAIL          IN   VARCHAR2
               )
IS

   x_application      VARCHAR2(10) := 'XXINTG';

   x_program_name1    VARCHAR2(100) := 'XXO2CEXPMODRPT';
   x_program_desc1    VARCHAR2(100) := 'INTG Expiring Modifiers Pricing Report';

   x_program_name2    VARCHAR2(100) := 'XXO2CEXPQUALRPT';
   x_program_desc2    VARCHAR2(100) := 'INTG Expiring Qualifiers Pricing Report';

   x_program_name3    VARCHAR2(100) := 'XXO2CEXPRRPTMAIL';
   x_program_desc3    VARCHAR2(100) := 'INTG Expiring Pricing Email Program';

   x_conc_request_id1  NUMBER;
   x_conc_request_id2  NUMBER;
   x_conc_request_id3  NUMBER;
   x_layout_status    BOOLEAN      := FALSE;
   x_user_id          NUMBER        := fnd_global.user_id;
   x_resp_id          NUMBER        := fnd_global.resp_id;
   x_resp_appl_id     NUMBER        := fnd_global.resp_appl_id;


BEGIN

   FND_FILE.PUT_LINE( FND_FILE.LOG,'P_RUN_DATE    -> '||P_RUN_DATE);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'P_NO_OF_DAYS  -> '||P_NO_OF_DAYS);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'P_DIVISION    -> '||P_DIVISION);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'P_SALES_TER:  -> '||P_SALES_TER);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'P_OU:         -> '||P_OU);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'P_EMAIL:      -> '||P_EMAIL);
   FND_FILE.PUT_LINE( FND_FILE.LOG,'P_FORMAT:     -> '||P_FORMAT);


IF P_FORMAT = 'REPORT' THEN
-----------------------------modifier request --------------------------------------
BEGIN
FND_FILE.PUT_LINE( FND_FILE.LOG,'********Request for REPORT Submitted ************************* ');
FND_FILE.PUT_LINE( FND_FILE.LOG,'');
FND_FILE.PUT_LINE( FND_FILE.LOG,'');
FND_FILE.PUT_LINE( FND_FILE.LOG,'********Submitting the Request for Expiring Modifier Report ************************* ');
           x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                      ,template_code      => 'XXO2CEXPMODRPT'
                                                      ,template_language  => 'en'
                                                      ,template_territory => 'US'
                                                      ,output_format      => 'EXCEL');

           x_conc_request_id1 := FND_REQUEST.SUBMIT_REQUEST
              ( application    => x_application
               ,program        => 'XXO2CEXPMODRPT'
               ,sub_request    =>  FALSE
               ,argument1      =>  P_RUN_DATE
               ,argument2      =>  P_NO_OF_DAYS
               ,argument3      =>  P_DIVISION
               ,argument4      =>  P_SALES_TER
               ,argument5      =>  P_OU
              );

           COMMIT;

        IF x_conc_request_id1 !=0 THEN
            FND_FILE.PUT_LINE( FND_FILE.LOG,'********Request ID '||x_conc_request_id1||' for '||x_program_desc1||' submitted successfully to generate report');
        ELSE
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Request '||x_program_desc1||' Not Submitted due to ' || fnd_message.get);
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Error while submiting request. ' || ' User id' || fnd_global.user_id|| SQLERRM);
        END IF;
         FND_FILE.PUT_LINE( FND_FILE.LOG,'**************************************************************');
         FND_FILE.PUT_LINE( FND_FILE.LOG,'');
         FND_FILE.PUT_LINE( FND_FILE.LOG,'');

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Exception occured in request submission block of modifier');
      END;
      ---------------------end of modifier request----------------------------------
      ------qualifier request----------------------------------
      BEGIN
           FND_FILE.PUT_LINE( FND_FILE.LOG,'');
           FND_FILE.PUT_LINE( FND_FILE.LOG,'');
           FND_FILE.PUT_LINE( FND_FILE.LOG,'');
           FND_FILE.PUT_LINE( FND_FILE.LOG,'********Submitting the Request for Expiring Qualifier Report ************************* ');
           x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name => x_application
                                                      ,template_code      => 'XXO2CEXPQUALRPT'
                                                      ,template_language  => 'en'
                                                      ,template_territory => 'US'
                                                      ,output_format      => 'EXCEL');

           x_conc_request_id2 := FND_REQUEST.SUBMIT_REQUEST
              ( application    => x_application
               ,program        => 'XXO2CEXPQUALRPT'
               ,sub_request    =>  FALSE
               ,argument1      =>  P_RUN_DATE
               ,argument2      =>  P_NO_OF_DAYS
               ,argument3      =>  P_DIVISION
               ,argument4      =>  P_SALES_TER
               ,argument5      =>  P_OU
              );

           COMMIT;

        IF x_conc_request_id2 !=0 THEN
            FND_FILE.PUT_LINE( FND_FILE.LOG,'********Request '||x_conc_request_id2||' for '|| x_program_desc2 ||' Submitted Successfully to generate report');
        ELSE
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Request '|| x_program_desc2 ||' Not Submitted due to ' || fnd_message.get);
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Error while submiting request. ' || ' User id' || fnd_global.user_id|| SQLERRM);
        END IF;
         FND_FILE.PUT_LINE( FND_FILE.LOG,'**************************************************************');
         FND_FILE.PUT_LINE( FND_FILE.LOG,'');
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Exception occured in request submission block of qualifier');
      END;
	  -----------------end of qualifier request-----------------
   END IF;
   -----------------end of REPORT request-----------------
   --------------------start of email request---------------------------------
IF P_FORMAT = 'EMAIL' THEN
BEGIN
 FND_FILE.PUT_LINE( FND_FILE.LOG,'********Request for EMAIL Submitted ************************* ');
           x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name =>  x_application
                                                      ,template_code      => 'XXO2CEXPQUALRPT'
                                                      ,template_language  => 'en'
                                                      ,template_territory => 'US'
                                                      ,output_format      => 'EXCEL');

            x_conc_request_id3 := FND_REQUEST.SUBMIT_REQUEST
              ( application    =>  x_application
               ,program        => 'XXO2CEXPRRPTMAIL'
               ,sub_request    =>  FALSE
               ,argument1      =>  P_RUN_DATE
               ,argument2      =>  P_NO_OF_DAYS
               ,argument3      =>  P_DIVISION
               ,ARGUMENT4      =>  P_SALES_TER
               ,ARGUMENT5      =>  P_OU
               ,ARGUMENT6      =>  P_EMAIL);

           COMMIT;


        IF x_conc_request_id3 !=0 THEN
            FND_FILE.PUT_LINE( FND_FILE.LOG,'********Request '||x_conc_request_id3||' for '|| x_program_desc3 ||' Submitted Successfully to generate report');
        ELSE
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Request '|| x_program_desc3 ||' Not Submitted due to ' || fnd_message.get);
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Error while submiting request. ' || ' User id' || fnd_global.user_id|| SQLERRM);
        END IF;
         FND_FILE.PUT_LINE( FND_FILE.LOG,'**************************************************************');
         FND_FILE.PUT_LINE( FND_FILE.LOG,'');
      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE( FND_FILE.LOG,'Exception occured in request submission block for email');
      END;
      -----------------------------end of email------------------------------------------
   END IF;
   END;


END XXO2CEXPRRPTPKG;

/
