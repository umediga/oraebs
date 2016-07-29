DROP PACKAGE APPS.XXO2CEXPRRPTPKG;

CREATE OR REPLACE PACKAGE APPS.XXO2CEXPRRPTPKG
AS
----------------------------------------------------------------------
/*
 Created By    : Shiny George
 Creation Date : 21-JAN-2015
 File Name     : XXO2CEXPRRPTPKG.pks
 Description   : This script creates the spec of the package
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
                 P_format         IN   VARCHAR2,
                 p_email          IN   VARCHAR2
               );

END XXO2CEXPRRPTPKG;

/
