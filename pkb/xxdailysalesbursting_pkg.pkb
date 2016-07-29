DROP PACKAGE BODY APPS.XXDAILYSALESBURSTING_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXDAILYSALESBURSTING_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : XX_AR_CUSTCRD_BURST_PKG.pkb
 Description   : This script creates the body of the package
                 xx_ar_custcrd_burst_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 17-Jun-2013 Rajesh Kendhuli       Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE launch_bursting( errbuf          OUT  VARCHAR2,
                              retcode         OUT  NUMBER,
                              p_request_id    IN   NUMBER)
   IS
      x_reqid              NUMBER;
      x_phase              VARCHAR2(80);
      x_status             VARCHAR2(80);
      x_devphase           VARCHAR2(80);
      x_devstatus          VARCHAR2(80);
      x_message            VARCHAR2(80);
      x_check              BOOLEAN;
   BEGIN

         IF p_request_id IS NOT NULL THEN

            x_check:=FND_CONCURRENT.WAIT_FOR_REQUEST(p_request_id,1,0,x_phase,x_status,x_devphase,x_devstatus,x_message);


            x_reqid := FND_REQUEST.SUBMIT_REQUEST ('XDO',
                                                   'XDOBURSTREP',
                                                    NULL,
                                                    NULL,
                                                    FALSE,
                                                    'Y',
                                                    p_request_id,
                                                   'N'
                                                  );
            COMMIT;
         END IF;
   EXCEPTION
      WHEN OTHERS THEN
         retcode := 1;
   END;

-- --------------------------------------------------------------------- --
END xxdailysalesbursting_pkg;
/
