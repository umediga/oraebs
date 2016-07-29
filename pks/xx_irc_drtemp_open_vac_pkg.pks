DROP PACKAGE APPS.XX_IRC_DRTEMP_OPEN_VAC_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_IRC_DRTEMP_OPEN_VAC_PKG" is

/*------------------------------------------------------------------------------
-- Module Name  : Oracle IRecurietment - Open Vancancy Report- Direct Employee.                                      --
-- File Name    : xx_irc_drtemp_open_vac_pkg.pks                                                                     --
-- Description  : This package is package header.                                                                    --
-- Parameters   :                                                                                                    --
--                                                                                                                   --
-- Created By   : Yogesh Rudrasetty.                                                                                 --
-- Creation Date: 02/01/2012                                                                                         --
-- History      : Initial Creation.                                                                                  --
--                                                                                                                   --
--                                                                                                                   --
------------------------------------------------------------------------------*/


g_stage			            VARCHAR2(2000);

PROCEDURE main ( errbuf      OUT   VARCHAR2,
                 retcode     OUT   NUMBER,
                 p_eff_date  IN    VARCHAR2,
                 p_file_name IN    VARCHAR2);
end;
/
