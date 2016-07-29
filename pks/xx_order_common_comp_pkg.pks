DROP PACKAGE APPS.XX_ORDER_COMMON_COMP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ORDER_COMMON_COMP_PKG" 
--------------------------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 07-MAR-2012
 File Name     : XXOMCOMMON.pks
 Description   : Common Components to be used for OM related interfaces and extensions

 Change History:

 Date        Name             Remarks
 ----------- -----------      ---------------------------------------
 07-MAR-2012 IBM Development  Initial development
 */
--------------------------------------------------------------------------------------
AS
   --
   TYPE ship_to_info_rec IS RECORD (
      ship_to              oe_order_lines_v.ship_to%TYPE,
      ship_to_address1     oe_order_lines_v.ship_to_address1%TYPE,
      ship_to_address2     oe_order_lines_v.ship_to_address2%TYPE,
      ship_to_address3     oe_order_lines_v.ship_to_address3%TYPE,
      ship_to_address4     oe_order_lines_v.ship_to_address4%TYPE,
      ship_to_address5     oe_order_lines_v.ship_to_address5%TYPE,
      ship_to_contact      oe_order_lines_v.ship_to_contact%TYPE,
      ship_to_contact_id   oe_order_lines_v.ship_to_contact_id%TYPE,
      ship_to_location     oe_order_lines_v.ship_to_location%TYPE,
      ship_to_org_id       oe_order_lines_v.ship_to_org_id%TYPE
   );

   --
   TYPE bill_to_info_rec IS RECORD (
      invoice_to              oe_order_lines_v.invoice_to%TYPE,
      invoice_to_address1     oe_order_lines_v.invoice_to_address1%TYPE,
      invoice_to_address2     oe_order_lines_v.invoice_to_address2%TYPE,
      invoice_to_address3     oe_order_lines_v.invoice_to_address3%TYPE,
      invoice_to_address4     oe_order_lines_v.invoice_to_address4%TYPE,
      invoice_to_address5     oe_order_lines_v.invoice_to_address5%TYPE,
      invoice_to_contact      oe_order_lines_v.invoice_to_contact%TYPE,
      invoice_to_contact_id   oe_order_lines_v.invoice_to_contact_id%TYPE,
      invoice_to_location     oe_order_lines_v.invoice_to_location%TYPE,
      invoice_to_org_id       oe_order_lines_v.invoice_to_org_id%TYPE
   );

   --
   TYPE sold_to_info_rec IS RECORD (
      sold_to              hz_parties.party_name%TYPE,
      sold_to_address1     hz_parties.address1%TYPE,
      sold_to_address2     hz_parties.address2%TYPE,
      sold_to_address3     hz_parties.address3%TYPE,
      sold_to_address4     hz_parties.address4%TYPE,
      sold_to_contact      oe_order_lines_v.invoice_to_contact%TYPE,
      sold_to_contact_id   oe_order_lines_v.invoice_to_contact_id%TYPE,
      sold_to_location     oe_order_lines_v.invoice_to_location%TYPE,
      sold_to_org_id       oe_order_lines_v.sold_to_org_id%TYPE
   );

   --
   TYPE deliver_to_info_rec IS RECORD (
      deliver_to              oe_order_lines_v.deliver_to%TYPE,
      deliver_to_address1     oe_order_lines_v.deliver_to_address1%TYPE,
      deliver_to_address2     oe_order_lines_v.deliver_to_address2%TYPE,
      deliver_to_address3     oe_order_lines_v.deliver_to_address3%TYPE,
      deliver_to_address4     oe_order_lines_v.deliver_to_address4%TYPE,
      deliver_to_contact      oe_order_lines_v.deliver_to_contact%TYPE,
      deliver_to_contact_id   oe_order_lines_v.deliver_to_contact_id%TYPE,
      deliver_to_location     oe_order_lines_v.deliver_to_location%TYPE,
      deliver_to_org_id       oe_order_lines_v.deliver_to_org_id%TYPE
   );

   --
   TYPE shipment_info_rec IS RECORD (
      shipment_number            oe_order_lines_v.shipment_number%TYPE,
      shipment_priority_code     oe_order_lines_v.shipment_priority_code%TYPE,
      shipped_quantity           oe_order_lines_v.shipped_quantity%TYPE,
      shipped_quantity2          oe_order_lines_v.shipped_quantity2%TYPE,
      shipping_instructions      oe_order_lines_v.shipping_instructions%TYPE,
      shipping_interfaced_flag   oe_order_lines_v.shipping_interfaced_flag%TYPE,
      shipping_method_code       oe_order_lines_v.shipping_method_code%TYPE,
      shipping_quantity          oe_order_lines_v.shipping_quantity%TYPE,
      shipping_quantity2         oe_order_lines_v.shipping_quantity2%TYPE,
      shipping_quantity_uom      oe_order_lines_v.shipping_quantity_uom%TYPE,
      shipping_quantity_uom2     oe_order_lines_v.shipping_quantity_uom2%TYPE,
      ship_from                  oe_order_lines_v.ship_from%TYPE,
      ship_from_location         oe_order_lines_v.ship_from_location%TYPE,
      ship_from_org_id           oe_order_lines_v.ship_from_org_id%TYPE,
      ship_model_complete_flag   oe_order_lines_v.ship_model_complete_flag%TYPE,
      ship_set                   oe_order_lines_v.ship_set%TYPE,
      ship_set_id                oe_order_lines_v.ship_set_id%TYPE
   );

   --
   /*
   Purpose        : This Function will returns the line_id.
   Input          : order number , line_number
   Output         : It will return the order line_id
   Special Logic  : This API function can only be called after a call to initialize the Multi Org Access
   */
   --
   FUNCTION get_line_id (p_order_number NUMBER, p_line_number VARCHAR2)
      RETURN NUMBER;

   --
   /*
   Purpose        : This procedure will returns the customer demographic information.
   Input          : Customer Number
   Output         : It will return a row from the HZ_CUSTOMER_PARTY_FIND_V view
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_cust_demographics (
      p_customer_number     IN       VARCHAR2,
      p_party_site_number   IN       VARCHAR2,
      x_customer_rec        OUT      hz_customer_party_find_v%ROWTYPE
   );

   --
   /*
   Purpose        : This Function will returns the customer_status
   Input          : Customer Number
   Output         : It will return Customer Status
   Special Logic  : None
   */
   --
   FUNCTION get_cust_status (p_customer_number IN VARCHAR2)
      RETURN VARCHAR2;

   --
   /*
   Purpose        : This Procedure will returns the payment options that have been set up for that customer.
   Input          : Customer Number
   Output         : payment options
   Special Logic  : None

   */
   --
   PROCEDURE get_cust_payment_options (
      p_customer_number        IN       VARCHAR2,
      x_customer_profile_rec   OUT      hz_customer_profiles%ROWTYPE
   );

   --
   /*
   Purpose        : This Function will returns the order type
   Input          : Order Number
   Output         : Order Type
   Special Logic  : This API function can only be called after a call to initialize the Multi Org Access
   */
   --
   FUNCTION get_order_type (p_order_number IN VARCHAR2)
      RETURN VARCHAR2;

   --
   /*
   Purpose        : This Function will returns the total order amount. This should be inclusive of freight, taxes, fees, etc
   Input          : Order Number
   Output         : Total Order Amount
   Special Logic  : This API function can only be called after a call to initialize the Multi Org Access
   */
   --
   FUNCTION get_order_amount (p_order_number IN VARCHAR2)
      RETURN NUMBER;

   --
   /*
   Purpose        : This Function will returns the order line type.
   Input          : Order Number
   Output         : Order Line Type
   Special Logic  : None
   */
   --
   FUNCTION get_line_type (p_line_id IN NUMBER)
      RETURN VARCHAR2;

   --
   /*
   Purpose        : This Procedure will returns the ship-to information for the line.
   Input          : Order Number , line number
   Output         : It will return Customer Status
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_shipto_info (
      p_line_id        IN       NUMBER,
      x_ship_to_info   OUT      ship_to_info_rec
   );

   --
   /*
   Purpose        : This Procedure will returns the Bill-to information for the line.
   Input          : Order Number , line number
   Output         : It will return one row corresponding to the Bill-to information details

   */
   --
   PROCEDURE get_line_billto_info (
      p_line_id        IN       NUMBER,
      x_bill_to_info   OUT      bill_to_info_rec
   );

   --
   /*
   Purpose        : This Procedure will returns the Sold-to information for the line.
   Input          : Order Number , line number
   Output         : It will return one row corresponding to the SOld-to information details
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_soldto_info (
      p_line_id        IN       NUMBER,
      x_sold_to_info   OUT      sold_to_info_rec
   );

   --
   /*
   Purpose        : This Procedure will returns the Deliver-to information for the line.
   Input          : Order Number , line number
   Output         : It will return one row corresponding to the Deliver-to information details
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_deliverto_info (
      p_line_id           IN       NUMBER,
      x_deliver_to_info   OUT      deliver_to_info_rec
   );

   --
   /*
   Purpose        : This Procedure will returns information about the item on the line
   Input          : Order number, inventory organization id and line number
   Output         : It will return Customer Status
   Special Logic  : None
   */
   --
   PROCEDURE get_line_item_info (
      p_line_id           IN       NUMBER,
      p_organization_id   IN       NUMBER,
      x_item_rec          OUT      mtl_system_items_b%ROWTYPE
   );

   --
   /*
   Purpose        : This Function will returns the payment method used for the line.
   Input          : Order Number,line Number
   Output         : Payment Method
   */
   --
   FUNCTION get_line_payment_method (p_line_id IN NUMBER)
      RETURN VARCHAR2;

   --
   /*
   Purpose        : This Function will returns the status of the line.
   Input          : Order Number,line Number
   Output         : It will return the line status
   Special Logic  : None
   */
   --
   FUNCTION get_line_status (p_line_id IN NUMBER)
      RETURN VARCHAR2;

   --
   /*
   Purpose        : This Procedure will returns the shipment information for the line.
   Input          : COrder Number,line Number
   Output         : It will return one row with the shipment related details
   Special Logic  : This API procedure can only be called after a call to initialize the Multi Org Access
   */
   --
   PROCEDURE get_line_shipment_info (
      p_line_id         IN       NUMBER,
      x_shipment_info   OUT      shipment_info_rec
   );
-- Function to get the conversion rate with Base UOM code
FUNCTION get_conversion_rate (p_inventory_item_id IN number
			     ,p_uom     IN varchar2)
    RETURN number;
--
----------------------------------------------------------------------------
--------------------<   get_case_details   >--------------------------------
----------------------------------------------------------------------------
-- Function to get the Masterpack details, case details and partial case details
-- Parameters:
-- p_inv_org_name      Inventory organizations i.e. 'IO_AHP_DOTHAN'
-- p_item_number       Item Number
-- p_uom_code          Unit of measure of the shipped quantity
-- p_shipped_quantity  shipped quantity
-- p_ip                Customer specific innerpack conversion ratio
-- p_no_of_mp          Number of Master Packs
-- p_no_of_ca          Number of Cases
-- p_no_of_incmp_ca    Number of Imcomplete Cases
-- p_total_no_of_label Total number of labels to be printed
-- p_mp_qty            Masterpack quantity in inner pack/retail pack/customer qty for each label
-- p_mp_qty_in_alt_uom Masterpack quantity in alternate uom each for each label
-- p_ca_qty            Case quantity in inner pack/retail pack/customer qty for each label
-- p_ca_qty_in_alt_uom Case quantity in alternate uom each for each label
-- p_ip_qty            Partial Case quantity in inner pack/retail pack/customer qty for each label
-- p_ip_qty_in_alt_uom Partial Case quantity in alternate uom each for each label
-- This Function will work with following assumptions
-- 1. All UOM's referred should have conversion rate with base UOM
-- 2. UOM for Master Pack is 'MP'
-- 3. UOM for Case is 'CA'
-- 4. UOM for Inner Case/Pack is 'IP'
-- 5. UOM for Retail Pack is 'RP'
--------------------------------------------------------------------------------------------
   FUNCTION get_case_details (
      p_inv_org_name        IN       VARCHAR2,
      p_item_number         IN       VARCHAR2,
      p_uom_code            IN       VARCHAR2,
      p_shipped_quantity    IN       NUMBER,
      p_ip                  IN       NUMBER,
      p_no_of_mp            OUT      NUMBER,
      p_no_of_ca            OUT      NUMBER,
      p_no_of_incmp_ca      OUT      NUMBER,
      p_total_no_of_label   OUT      NUMBER,
      p_mp_qty              OUT      NUMBER,
      p_mp_qty_in_inv_uom   OUT      NUMBER,--AK
      p_mp_qty_in_alt_uom   OUT      NUMBER,
      p_ca_qty              OUT      NUMBER,
      p_ca_qty_in_alt_uom   OUT      NUMBER,
      p_ip_qty              OUT      NUMBER,
      p_ip_qty_in_alt_uom   OUT      NUMBER
   )
      RETURN NUMBER;
--
END xx_order_common_comp_pkg;
/


GRANT EXECUTE ON APPS.XX_ORDER_COMMON_COMP_PKG TO INTG_XX_NONHR_RO;
