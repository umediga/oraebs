DROP PACKAGE APPS.XX_TABLES_ARCHIVE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_TABLES_ARCHIVE_PKG" 
--------------------------------------------------------------------------------
/* $Header: XXTBLAR.pks 2012/12/16 00:00:00 dsengupta noship $ */
/*
   Created By   : IBM Development Team
   Creation Date: 16-Dec-11
   File Name    : XXTBLAR.pkb
   Description  : Point to point interface Tables Archive Package developed AUTHID CURRENT_USER as part
                  of Interface Template for Integra Delphi R12 Implementation Project.

   Change History:
      Date                Name			Remarks
      ---------           ----------		-----------------------------------------
      16-Dec-11           IBM Development Team	Initial Development

*/
--------------------------------------------------------------------------------

AS
Procedure Main(o_errbuf out varchar2,
               o_retcode out Number
);

Procedure purge_archived_data;

End XX_TABLES_ARCHIVE_PKG;
/


GRANT EXECUTE ON APPS.XX_TABLES_ARCHIVE_PKG TO INTG_XX_NONHR_RO;
