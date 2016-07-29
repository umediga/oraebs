DROP PACKAGE APPS.XX_CE_BANK_RECON_WRAPP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_CE_BANK_RECON_WRAPP_PKG" 
----------------------------------------------------------------------
/* $Header: xxcebankreconwrapp.pks 1.0 2012/02/08 12:00:00 schakraborty noship $ */
/*
Created By     : IBM Development Team
Creation Date  : 22-Apr-2012
File Name      : xxcebankreconwrapp.pks
Description    : This script creates the specification of the xx_ce_bank_recon_wrapp_pkg package
Change History:
Version Date        Name                    Remarks
------- ----------- ----                    ----------------------
1.0     22-Apr-12   IBM Development Team    Initial development.
*/
/*----------------------------------------------------------------------*/
AUTHID CURRENT_USER AS
   /* ------ Global variable declaration ---------*/
   G_RETCODE      VARCHAR2 (1) := NULL;
   G_ERRBUF       VARCHAR2 (200) := NULL;
   G_REQUEST_ID   VARCHAR2 (10);
   E_FATAL_ERROR EXCEPTION;


   /*------------------------------*/
   PROCEDURE xx_ce_bank_recon_wrapper (p_errbuf                OUT VARCHAR2,
                                       p_retcode               OUT VARCHAR2,
                                       x_file_name          IN     VARCHAR2,
                                       p_source_directory   IN     VARCHAR2);

   /*  ---------------------------------------------------------------------- */
   /* --- This function is to initiate First Concurrent Program : Process Lockbox             */
   /*  ---------------------------------------------------------------------- */
   FUNCTION xx_ce_initiate (p_data_filename      IN VARCHAR2,
                            p_source_directory   IN VARCHAR2)
      RETURN BOOLEAN;
END xx_ce_bank_recon_wrapp_pkg;
/
