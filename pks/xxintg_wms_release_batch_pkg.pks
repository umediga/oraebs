DROP PACKAGE APPS.XXINTG_WMS_RELEASE_BATCH_PKG;

CREATE OR REPLACE PACKAGE APPS."XXINTG_WMS_RELEASE_BATCH_PKG" 
AS
PROCEDURE release_batch(errbuf OUT VARCHAR2, retcode OUT VARCHAR2,p_order_number NUMBER,p_ship_confirm_flag VARCHAR2);
PROCEDURE pick_ship_confirm(p_order_number NUMBER);

END xxintg_wms_release_batch_pkg; 
/
