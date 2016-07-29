DROP PACKAGE APPS.XX_JPMC_SUA_MVL_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_JPMC_SUA_MVL_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : Mou Mukherjee
 Creation Date  : 16-July-2013
 File Name      : XXAPJPMCSUAMVL.pks
 Description    : This script creates the specification of the package xx_jpmc_sua_mvl_pkg

Change History:

Version Date        Name		Remarks
------- --------- ------------		---------------------------------------
1.0     16-Jul-2013 Mou Mukherjee        Initial development.
*/
----------------------------------------------------------------------
   PROCEDURE main (
      p_errbuf                OUT    VARCHAR2,
      p_retcode               OUT    NUMBER
   );
END xx_jpmc_sua_mvl_pkg;
/
