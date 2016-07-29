DROP PACKAGE APPS.XX_PO_UTIL_PKG;

CREATE OR REPLACE PACKAGE APPS.XX_PO_UTIL_PKG AS
/*------------------------------------------------------------------------------

 Created By     : IBM Development Team
 Creation Date  : 19-Oct-2012
 File Name      : XXPOUTILPKG.pks
 Description    : This script creates the body of the package XX_PO_UTIL_PKG

 Version Date        Name           Remarks
 ------- ----------- ---------      --------------------------------------------
 1.0     19-Oct-2012 Sujan Datta    Initial development.
------------------------------------------------------------------------------*/
-- Function to return formatted addres based on the address style of the country
   FUNCTION format_address
      (p_address_style        IN VARCHAR2 DEFAULT NULL
      ,p_address1             IN VARCHAR2 DEFAULT NULL
      ,p_address2             IN VARCHAR2 DEFAULT NULL
      ,p_address3             IN VARCHAR2 DEFAULT NULL
      ,p_address4             IN VARCHAR2 DEFAULT NULL
      ,p_city                 IN VARCHAR2 DEFAULT NULL
      ,p_county               IN VARCHAR2 DEFAULT NULL
      ,p_state                IN VARCHAR2 DEFAULT NULL
      ,p_province             IN VARCHAR2 DEFAULT NULL
      ,p_postal_code          IN VARCHAR2 DEFAULT NULL
      ,p_territory_short_name IN VARCHAR2 DEFAULT NULL
      ,p_country_code         IN VARCHAR2 DEFAULT NULL
      ,p_customer_name        IN VARCHAR2 DEFAULT NULL
      ,p_first_name           IN VARCHAR2 DEFAULT NULL
      ,p_last_name            IN VARCHAR2 DEFAULT NULL
      )
   RETURN VARCHAR2;

-- Function to return supplier item
   FUNCTION get_supplier_item (p_po_line_id IN NUMBER)
   RETURN VARCHAR2;

-- Function for ship to location existance flag(Added by IBM Development Team on 18th Feb 2013 for Change# 001860)
   FUNCTION ship_to_exist (p_ship_to_name IN VARCHAR2)
   RETURN VARCHAR2;

-- Function to retrun WIP components for OSP Lines
   FUNCTION list_components ( p_wip_entity_id     IN NUMBER
                             ,p_operation_seq_num IN NUMBER
                            )
   RETURN VARCHAR2;

-- Function to return "Finish" attribute
   FUNCTION get_finish_attribute (p_item_id IN NUMBER)
   RETURN VARCHAR2;

-- Function to return "Marking" attribute
   FUNCTION get_marking_attribute (p_item_id IN NUMBER)
   RETURN VARCHAR2;

-- Function to return test material
   FUNCTION get_test_material (p_line_location_id IN NUMBER)
   RETURN VARCHAR2;

-- Function to return revision -- Added for the "Revision Number" display enhancement on 5th June 2013
   FUNCTION get_revision (p_item_id IN NUMBER , p_creation_date IN DATE, p_ship_to_org IN NUMBER) -- NM: 18/11/14: Added parameter p_ship_to_org
   RETURN VARCHAR2;

-- Function to return buyer/ship to/bill to address for ship to org - 116,403,404 -- Added for the wave1 enhancement on 5th Dec 2013
   FUNCTION le_address
   RETURN VARCHAR2;

-- Function to return buyer/ship to/bill to address for ship to org - 116,403,404 (Eng,French and spanish) -- Added for the wave1 enhancement on 5th Dec 2013
   FUNCTION le_address1
   RETURN VARCHAR2;

-- Function to return bill to address for ship to org - 116 -- Added for the wave1 enhancement on 5th Dec 2013
   FUNCTION le_bill_to_address
   RETURN VARCHAR2;

 -- Function to return note for ship to org - 116
   FUNCTION note
   RETURN VARCHAR2;

 -- Function to return bill to location name for ship to org - 116 and inv PO
   FUNCTION bill_loc_name_inv
   RETURN VARCHAR2;

 -- Function to return vat id for ship to org - 116
   FUNCTION vat_id_116
   RETURN VARCHAR2;

 -- Function to return vat id for ship to org - 403
   FUNCTION vat_id_403
   RETURN VARCHAR2;

 -- Function to return vat id for ship to org - 404
   FUNCTION vat_id_404
   RETURN VARCHAR2;

 -- Function to return vat addr1
   FUNCTION vat_addr1
   RETURN VARCHAR2;

 -- Function to return vat addr2
   FUNCTION vat_addr2
   RETURN VARCHAR2;

   -- Function to retrun last user name  -- Added on 21-May-14
   FUNCTION last_user_name (p_header_id     IN NUMBER
                             ,p_rev_num IN NUMBER
                            )
   RETURN VARCHAR2;

 -- Function to retrun last updated date  -- Added on 21-May-14
   FUNCTION last_updt_date ( p_header_id     IN NUMBER
                             ,p_rev_num IN NUMBER
                            )
   RETURN DATE;

END XX_PO_UTIL_PKG;
/
