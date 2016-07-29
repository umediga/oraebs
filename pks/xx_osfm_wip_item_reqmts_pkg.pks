DROP PACKAGE APPS.XX_OSFM_WIP_ITEM_REQMTS_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_OSFM_WIP_ITEM_REQMTS_PKG"
AS
  ----------------------------------------------------------------------
  /*
  Created By     : Mou Mukherjee
  Creation Date  : 11-Sep-2012
  File Name      : xx_wip_item_requirements_pkg.pks
  Description    : This script creates the specification of the package xx_wip_item_requirements_pkg
  Change History:
  Version Date        Name  Remarks
  ------- --------- ------------  ---------------------------------------
  1.0     11-Sep-2012 Mou Mukherjee       Initial development.
  2.0     11-Sep-2015 Prasanna Sunkad     Ticket4358#
  */
  ----------------------------------------------------------------------
PROCEDURE load_item_requirements(
    P_WIP_ENTITY_ID in number ,
    x_status OUT VARCHAR2 ,
    X_MSG OUT varchar2 );
END xx_osfm_wip_item_reqmts_pkg;
/
