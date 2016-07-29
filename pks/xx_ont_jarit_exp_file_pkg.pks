DROP PACKAGE APPS.XX_ONT_JARIT_EXP_FILE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_JARIT_EXP_FILE_PKG" AUTHID CURRENT_USER AS
   /* $Header: XXONTJARITEXPORTFILE.pks 1.0.0 2013/09/12 00:00:00 ibm noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 12-Sep-2013
  -- Filename       : XXONTJARITEXPORTFILE.pks
  -- Description    : Package spec for getting amount for OSP Items

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 12-Sep-2013   1.0       Partha S Mohanty    Initial development.
--====================================================================================


FUNCTION get_line_value(p_wip_entity_id wip_entities.wip_entity_id%TYPE
                        ,p_org_id NUMBER) RETURN number;

FUNCTION get_related_invoice(p_wip_entity_id wip_entities.wip_entity_id%TYPE
                            ,p_org_id NUMBER) RETURN VARCHAR2;
END xx_ont_jarit_exp_file_pkg;
/
