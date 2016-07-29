DROP PACKAGE APPS.XX_PTP_COMMON_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_PTP_COMMON_PKG" 
AS
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-2012
 File Name     : XXPTPCOMMON.pks
 Description   : This script creates package specification xx_ptp_common_pkg

 Change History:

 Date        Name             Remarks
 ----------- -----------      ---------------------------------------
 07-MAR-2012 IBM Development  Initial development
 */
--------------------------------------------------------------------------------------

--  Procedure to Validate and fetch Vendor and Vendor Site Level Information.
 PROCEDURE GET_VENDOR_INFO (
  p_vendor_name              IN OUT po_vendors.vendor_name%type
  , p_vendor_number          IN OUT po_vendors.segment1%type
  , p_vendor_site_code       IN OUT po_vendor_sites.vendor_site_code%type
  , p_org_id                 IN    po_vendor_sites.org_id%type
  , pr_vendor_record         OUT    po_vendors%rowtype
  , pr_site_code_record      OUT    po_vendor_sites%rowtype
  , p_process_status         OUT    NUMBER
  , p_error_message          OUT    VARCHAR2
  );


-- Procedure to get corrosponding Vendor Number Name and ID for Employee number
 PROCEDURE GET_EMPLOYEE_VENDOR_INFO (
  p_employee_num         IN per_people_f.employee_number%type
  , p_vendor_number           OUT po_vendors.segment1%type
  , p_vendor_name             OUT po_vendors.vendor_name%type
  , p_vendor_id               OUT po_vendors.vendor_id%type
  , p_process_status          OUT NUMBER
  , p_error_message           OUT VARCHAR2
  );


-- Validating the PO Number with Po line number
  PROCEDURE VALIDATE_PO  (
        p_po_number                  IN  po_headers.segment1%type
        , p_po_line                  IN  po_lines.line_num%type
        , p_process_status           OUT NUMBER
        , p_error_message            OUT VARCHAR2
  );



-- Validating the Inventory Item
  FUNCTION VALIDATE_INVENTORY_ITEM  (
        p_item_number                IN  mtl_system_items_b.segment1%type
        , p_inventory_org            IN  org_organization_definitions.organization_id%type
        , p_error_message           OUT VARCHAR2
  )     RETURN NUMBER;



-- Validating the UOM
  FUNCTION VALIDATE_UOM  (
        p_uom_code                  IN  mtl_units_of_measure_tl.uom_code%type
        , p_error_message            OUT VARCHAR2
  ) RETURN NUMBER;




-- Validating Inventory Organization
  FUNCTION VALIDATE_INVENTORY_ORG  (
        p_inventory_org                  IN  org_organization_definitions.organization_code%type
        , p_error_message            OUT VARCHAR2
  ) RETURN NUMBER;



-- Validating Item template
  FUNCTION VALIDATE_ITEM_TEMPLATE  (
        p_template_name                 IN  mtl_item_templates_b.template_name%type
        , p_error_message               OUT VARCHAR2
  ) RETURN NUMBER;


-- Validating Sub Inventory Organization
  FUNCTION VALIDATE_SUBINV  (
        p_secondary_inventory_name      IN  mtl_secondary_inventories.secondary_inventory_name%type
        , p_inv_organization_id           IN  mtl_secondary_inventories.organization_id%type
        , p_error_message               OUT VARCHAR2
  ) RETURN NUMBER;



-- Validating Item Catogory
  FUNCTION VALIDATE_ITEM_CATEGORY  (
          P_inventory_item              IN  mtl_system_items_b.segment1%type
        , p_organization_id             IN  mtl_secondary_inventories.organization_id%type
        , P_Category_set_id             IN  mtl_item_categories.category_set_id%type
        , p_error_message               OUT VARCHAR2
  ) RETURN NUMBER;



--  Procedure to Validate and fetch Item and Item Level Attribute Information.
 PROCEDURE GET_ITEM_INFO (
          p_item_number              IN OUT mtl_system_items_b.segment1%type
          , p_organization_id        IN OUT mtl_system_items_b.organization_id%type
          , pr_Item_record           OUT    mtl_system_items_b%rowtype
          , p_process_status         OUT    NUMBER
          , p_error_message          OUT    VARCHAR2
  );


-- Procedure to get the Item Cost
  PROCEDURE GET_ITEM_COST  (
          p_Item_id                  IN  NUMBER
        , p_cost_type                IN  VARCHAR2
        , p_organization_id          IN  NUMBER
        , P_item_cost                OUT NUMBER
        , p_process_status           OUT NUMBER
        , p_error_message            OUT VARCHAR2
  );




-- Procedure to get the Item On hand quantity
  PROCEDURE  GET_ITEM_ONHAND_QUANTITY  (
          p_Item_id                  IN  NUMBER
        , p_organization_id          IN  NUMBER
        , p_subinventory_code        IN  VARCHAR2
        , p_locator_id               IN  NUMBER
        , P_onhand_quantity          OUT NUMBER
        , p_process_status           OUT NUMBER
        , p_error_message            OUT VARCHAR2
  );



-- Procedure to get the Item On hand quantity Orperating Unit basis
  PROCEDURE  GET_ITEM_ONHANDQTY_AFFILIT (
          p_Item_id                  IN  NUMBER
        , p_org_id                   IN  NUMBER
        , P_tot_onhand_qty           OUT NUMBER
        , p_process_status           OUT NUMBER
        , p_error_message            OUT VARCHAR2
  );



END XX_PTP_COMMON_PKG;
/


GRANT EXECUTE ON APPS.XX_PTP_COMMON_PKG TO INTG_XX_NONHR_RO;
