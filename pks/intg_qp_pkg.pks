DROP PACKAGE APPS.INTG_QP_PKG;

CREATE OR REPLACE PACKAGE APPS."INTG_QP_PKG" IS
/*
 Created By     : IBM Development Team
 Creation Date  : 08-Feb-2012
 File Name      : XXQPPKG.pks
 Description    : This script creates the package of the intg_qp_pkg package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ---------------------   ----------------------
 1.0     08-Oct-12   IBM Development Team    Initial development.
*/
   FUNCTION get_ship_to_country(p_headerid IN NUMBER
                               ,p_lineid   IN NUMBER)
   RETURN VARCHAR2;

END intg_qp_pkg;
/
