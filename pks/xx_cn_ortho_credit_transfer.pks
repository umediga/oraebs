DROP PACKAGE APPS.XX_CN_ORTHO_CREDIT_TRANSFER;

CREATE OR REPLACE PACKAGE APPS.XX_CN_ORTHO_CREDIT_TRANSFER AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  PROCEDURE ORTHO_SALES_CREDIT_TRANSFER (
      	errbuf                  	OUT       VARCHAR2,
      	retcode                 	OUT       VARCHAR2,
        p_period 	      		IN	  VARCHAR2
   );


END XX_CN_ORTHO_CREDIT_TRANSFER;
/
