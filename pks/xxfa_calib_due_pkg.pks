DROP PACKAGE APPS.XXFA_CALIB_DUE_PKG;

CREATE OR REPLACE PACKAGE APPS."XXFA_CALIB_DUE_PKG" AUTHID CURRENT_USER
AS
   p_set_name          VARCHAR2 (360);
   p_asset_number      VARCHAR2 (360);
   p_serial_number     VARCHAR2 (30);
   p_asset_group       VARCHAR2 (30);
   p_due_from_date     DATE;
   p_due_to_date       DATE;
   p_wo_status         VARCHAR2 (30);   --Added for SFDC Case 002281
   p_curent_location   VARCHAR2 (30);   --Added for SFDC Case 002281
   lp_due_date_range   VARCHAR2 (500);

   FUNCTION afterpform
      RETURN BOOLEAN;
END xxfa_calib_due_pkg;
/
