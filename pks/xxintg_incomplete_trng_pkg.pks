DROP PACKAGE APPS.XXINTG_INCOMPLETE_TRNG_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_INCOMPLETE_TRNG_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Shekhar Nikam
 Creation Date : 7-MAR-2014
 File Name     : xxintg_incomplete_trng_pkg
 Description   : This script creates the specification of the package
                 xxintg_incomplete_trng_pkg
 Change History:
 Date        Name                     Remarks
 ----------- -------------------      -----------------------------------
 07-Mar-2014 Shekhar Nikam             Initial Version
*/
----------------------------------------------------------------------
   PROCEDURE main (
      p_errbuf        OUT   VARCHAR2,
      p_retcode       OUT   VARCHAR2,
      p_category_id         NUMBER,
      p_course_id           NUMBER,
      p_event_id            NUMBER,
      p_lang                VARCHAR2
   );
END xxintg_incomplete_trng_pkg;
/
