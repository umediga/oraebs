DROP PACKAGE APPS.XX_H2R_FINAL_PROCESS_DATE;

CREATE OR REPLACE PACKAGE APPS."XX_H2R_FINAL_PROCESS_DATE" AS
/* $Header: XXH2RFINALPRSDAT.pks 1.0.0 2012/05/31 00:00:00$ */
--=============================================================================
-- Created By     : MuthuKumar Chandran
-- Creation Date  : 31-MAY-2012
-- Filename       : XXH2RFINALPRSDAT.pkb
-- Description    : Package spec for Final Process Date.
-- Change History:
-- Date          Version#    Name                    Remarks
-- -----------   --------    ---------------         ------------------------
-- 31-MAY-2012   1.0         MuthuKumar Chandran     Initial Development.
--=============================================================================

   g_lookup_type       VARCHAR2(100) := 'XXINTG_NO_OF_DAYS';

   PROCEDURE xx_final_process_date
                 (o_errbuf              OUT   VARCHAR2
                 ,o_retcode             OUT   VARCHAR2
                 ,p_no_of_days          IN    VARCHAR2
                 );
END xx_h2r_final_process_date;
/
