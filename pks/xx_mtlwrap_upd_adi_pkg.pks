DROP PACKAGE APPS.XX_MTLWRAP_UPD_ADI_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_MTLWRAP_UPD_ADI_PKG" as
g_header_id NUMBER;
g_interface_id NUMBER;
g_aquisition_flag VARCHAR2(1);
FUNCTION get_locator(p_subinv VARCHAR2, p_org_code VARCHAR2)
RETURN VARCHAR2;
 FUNCTION upd_mtl_xns
          (p_header_id IN NUMBER,
          p_org_code IN VARCHAR2,
 p_Transaction_Type IN VARCHAR2,
 p_Item             IN VARCHAR2,
 p_Revision         IN VARCHAR2,
 p_From_Subinventory IN VARCHAR2,
 p_From_Locator      IN VARCHAR2,
 p_From_LPN      IN VARCHAR2,
 p_To_Subinventory   IN VARCHAR2,
 p_To_Locator        IN VARCHAR2,
  p_TO_LPN      IN VARCHAR2,
 p_UOM               IN VARCHAR2,
 p_Quantity          IN Number,
 p_Lot_number        IN VARCHAR2,
 p_Serial_serial_number IN VARCHAR2,
 p_Sales_Rep           IN VARCHAR2,
 p_Account_Alias_Name  IN VARCHAR2,
 p_Reason              IN VARCHAR2,
 p_Reference           IN VARCHAR2,
 p_Lot_Expiry          IN date,
 p_attribute1          IN VARCHAR2,
 P_attribute2          IN VARCHAR2,
 P_attribute3          IN VARCHAR2,
 P_attribute4          IN VARCHAR2,
 P_attribute5          IN VARCHAR2,
 P_attribute6          IN VARCHAR2,
 P_attribute7          IN VARCHAR2,
 P_attribute8          IN VARCHAR2,
 P_attribute9          IN VARCHAR2,
 P_attribute10         IN VARCHAR2)
 RETURN VARCHAR2;
 procedure log_message (p_message IN VARCHAR2);
 procedure execute_wrapper(p_errbuf varchar2, p_error_code number,p_aquisition_flag IN VARCHAR2);
 end xx_mtlwrap_upd_adi_pkg;
/
