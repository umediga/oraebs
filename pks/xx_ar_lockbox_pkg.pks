DROP PACKAGE APPS.XX_AR_LOCKBOX_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_LOCKBOX_PKG" AUTHID CURRENT_USER
  ----------------------------------------------------------------------
  /* $Header: XXARLOCKBOXINT.pks 1.0 2012/02/08 12:00:00 schakraborty noship $ */
  /*
  Created By     : IBM Development Team
  Creation Date  : 22-Feb-2012
  File Name      : XX_AR_LOCKBOX_PKG.pks
  Description    : This script creates the specification of the XX_AR_LOCKBOX_PKG package
  Change History:
  Version Date        Name                    Remarks
  ------- ----------- ----                    ----------------------
  1.0     22-Feb-12   IBM Development Team    Initial development.
  */
  ----------------------------------------------------------------------
AS
  /* ------ Global variable declaration ---------*/
  G_RETCODE                VARCHAR2(1)   := NULL;
  G_ERRBUF                 VARCHAR2(200) := NULL;
  G_TRANSMISSION_FORMAT_ID NUMBER;
  G_LOCKBOX_ID             NUMBER;
  G_TRANS_NAME             VARCHAR2(100);
  G_API_NAME               VARCHAR2(200) := 'main.XX_AR_LOCKBOX';
  G_REQUEST_ID             VARCHAR2(10);
  G_OPERATING_UNIT         VARCHAR2(100);
  E_FATAL_ERROR              EXCEPTION;


  /*------------------------------*/
PROCEDURE xx_ar_process_lockbox(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    x_format_name    IN VARCHAR2 ,
    p_data_filename  IN VARCHAR2 ,
    x_operating_unit IN VARCHAR2) ;
  /*  ---------------------------------------------------------------------- */
  /* --- This function is to initiate First Concurrent Program : Process Lockbox             */
  /*  ---------------------------------------------------------------------- */
  FUNCTION xx_ar_initiate(
      p_transmission_format_id IN NUMBER ,
      p_data_filename          IN VARCHAR2 )
    RETURN BOOLEAN;
  END XX_AR_LOCKBOX_PKG;
/
