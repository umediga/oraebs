DROP PACKAGE BODY APPS.XX_PO_UTIL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XX_PO_UTIL_PKG AS
/*------------------------------------------------------------------------------

 Created By     : IBM Development Team
 Creation Date  : 19-Oct-2012
 File Name      : XXPOUTILPKG.pkb
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
   RETURN VARCHAR2
   IS
      x_width                 NUMBER := 60;
      x_height_min            NUMBER := 8;
      x_height_max            NUMBER := 8;
      x_address               VARCHAR2(2000);

   --   x_address1              VARCHAR2(240);
   --   x_address2              VARCHAR2(240);
   --   x_address3              VARCHAR2(240);
   --   x_address4              VARCHAR2(240);

   BEGIN
      -- Special cases for the DE address
     /* IF p_country_code = 'DE' THEN
         x_address1 := p_address1 ||' '|| p_address2;

         IF p_city IS NULL THEN
            x_address3 := p_postal_code ||' '|| p_address3 ||' '|| NVL(p_state,p_province);
            x_address2 := p_address4 ||' '|| p_county;

         ELSE
            x_address3 := p_postal_code ||' '|| p_city ||' '|| NVL(p_state,p_province);
            x_address2 := p_address3 ||' '|| p_address4 ||' '|| p_county;
         END IF;

         x_address4 := p_territory_short_name;

         x_address := TRIM(x_address1) ||chr(10)||
                      TRIM(x_address2) ||chr(10)||
                      TRIM(x_address3) ||chr(10)||
                      TRIM(x_address4);

         x_address := REPLACE(x_address, chr(10)||chr(10), chr(10));
         RETURN x_address;
      END IF; */

      x_address := ARP_ADDR_LABEL_PKG.format_address
                       ( address_style             => p_address_style
                        ,address1                  => p_address1
                        ,address2                  => p_address2
                        ,address3                  => p_address3
                        ,address4                  => p_address4
                        ,city                      => p_city
                        ,county                    => p_county
                        ,state                     => p_state
                        ,province                  => p_province
                        ,postal_code               => p_postal_code
                        ,territory_short_name      => p_territory_short_name
                        ,country_code              => p_country_code
                        ,customer_name             => p_customer_name
                        ,first_name                => p_first_name
                        ,last_name                 => p_last_name
                        ,mail_stop                 => NULL
                        ,default_country_code      => NULL
                        ,default_country_desc      => NULL
                        ,print_home_country_flag   => NULL
                        ,print_default_attn_flag   => NULL
                        ,width                     => x_width
                        ,height_min                => x_height_min
                        ,height_max                => x_height_max
                       );

   -- Trim Address
--   x_address := REPLACE(REPLACE(x_address,' ',NULL),chr(10)||chr(10),chr(10));

   RETURN x_address;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_address := p_address1 ||chr(10)||
                      p_address2 ||chr(10)||
                      p_city ||' '|| p_state ||' '|| p_postal_code ||chr(10)||
                      p_country_code;

         RETURN x_address;
   END format_address;

-- Function to return supplier item
   FUNCTION get_supplier_item (p_po_line_id IN NUMBER)
   RETURN VARCHAR2
   IS
   BEGIN
      -- Fetch supplier item from ASL
      FOR rec IN ( SELECT pasl.primary_vendor_item
                     FROM po_lines_all pla
                         ,po_headers_all pha
                         ,po_approved_supplier_list pasl
                    WHERE pla.po_line_id = p_po_line_id
                      AND pla.po_header_id = pha.po_header_id
                      AND pasl.item_id = pla.item_id
                      AND pasl.vendor_id = pha.vendor_id
                      AND (pasl.vendor_site_id = pha.vendor_site_id OR
                           pasl.vendor_site_id IS NULL)
                    ORDER BY pasl.vendor_site_id
                 )
      LOOP
         RETURN rec.primary_vendor_item;
      END LOOP;

      -- When no data found
      RETURN NULL;

   EXCEPTION
      WHEN OTHERS THEN
         -- Function will return null
         RETURN NULL;
   END get_supplier_item;

-- Function for ship to location existance flag (Added by IBM Development Team on 18th Feb 2013 for Change# 001860)
   FUNCTION ship_to_exist ( p_ship_to_name IN VARCHAR2
                          )
   RETURN VARCHAR2
   IS
      x_flag NUMBER := 0;
   BEGIN
      IF SUBSTR(p_ship_to_name,1,23) = xx_emf_pkg.get_paramater_value('XXPOCOMM','SHIP_TO_SITE')
         THEN
        x_flag := 1;
      END IF;

    RETURN x_flag;

    EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
    END ship_to_exist;

-- Function to retrun WIP components for OSP Lines
   FUNCTION list_components ( p_wip_entity_id     IN NUMBER
                             ,p_operation_seq_num IN NUMBER
                            )
   RETURN VARCHAR2
   IS
      x_list_of_comp VARCHAR2(4000) := NULL;

   BEGIN
      -- Return null for non-osp lines
      IF p_wip_entity_id IS NULL THEN
         RETURN NULL;
      END IF;

      -- Fetch list of components from WIP material requirements view
      FOR rec IN ( SELECT *
                     FROM wip_requirement_operations_v
                    WHERE wip_entity_id = p_wip_entity_id
                      AND operation_seq_num = p_operation_seq_num
                 )
      LOOP
         IF x_list_of_comp IS NULL THEN
            x_list_of_comp := rec.concatenated_segments;
         ELSE
            x_list_of_comp := x_list_of_comp||chr(10)||rec.concatenated_segments;
         END IF;
      END LOOP;

      RETURN x_list_of_comp;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END list_components;

-- Function to return "Finish" attribute
   FUNCTION get_finish_attribute (p_item_id IN NUMBER)
   RETURN VARCHAR2
   IS
   BEGIN
      FOR rec IN ( SELECT attribute11
                     FROM mtl_cross_references_b
                    WHERE cross_reference_type = xx_emf_pkg.get_paramater_value('XXPOCOMM','XREF_TYPE')
                      AND inventory_item_id = p_item_id
                 )
      LOOP
         RETURN rec.attribute11;
      END LOOP;

      -- when no data found
      RETURN NULL;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END get_finish_attribute;

-- Function to return "Marking" attribute
   FUNCTION get_marking_attribute (p_item_id IN NUMBER)
   RETURN VARCHAR2
   IS
   BEGIN
      FOR rec IN ( SELECT attribute10
                     FROM mtl_cross_references_b
                    WHERE cross_reference_type = xx_emf_pkg.get_paramater_value('XXPOCOMM','XREF_TYPE')
                      AND inventory_item_id = p_item_id
                 )
      LOOP
         RETURN rec.attribute10;
      END LOOP;

      -- when no data found
      RETURN NULL;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END get_marking_attribute;

-- Function to return test material
   FUNCTION get_test_material (p_line_location_id IN NUMBER)
   RETURN VARCHAR2
   IS
      x_column_name  VARCHAR2(40);
      x_column_name1  VARCHAR2(40);
      x_column_name2  VARCHAR2(40);
      x_column_val   VARCHAR2(2000);
      x_column_val1   VARCHAR2(2000);
      x_column_val2   VARCHAR2(2000);
      x_item_id      NUMBER;
      x_sql          VARCHAR2(4000);
      x_sql1          VARCHAR2(4000);
      c_ref_cursor   SYS_REFCURSOR;
      c_ref_cursor1   SYS_REFCURSOR;

   BEGIN
      -- Validate ship to location to display this value
      FOR loc IN ( SELECT hla.location_code
                         ,pla.item_id
                     FROM po_line_locations_all plla
                         ,hr_locations_all hla
                         ,po_lines_all pla
                    WHERE plla.line_location_id = p_line_location_id
                      AND plla.ship_to_location_id = hla.location_id
                      AND plla.po_line_id = pla.po_line_id
                 )
      LOOP
         IF INSTR(loc.location_code,'401') = 0 THEN
            RETURN NULL;
         ELSE
            x_item_id := loc.item_id;
         END IF;
      END LOOP;


      -- Get the collection plan column name
      FOR rec IN ( SELECT *
                     FROM qa_plan_chars_v
                    WHERE plan_name = xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_NAME')
                      AND char_name = xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_CHAR_NAME')
                 )
      LOOP
         x_column_name := rec.result_column_name;
      END LOOP; -- The above query will return single row only

      -- Based on the column name create the SQL dynamically.
      x_sql := 'SELECT '||x_column_name||
               '  FROM qa_results_v
                 WHERE item_id = '||x_item_id||
               '   AND name = '||''''||xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_NAME')||'''';

      OPEN c_ref_cursor FOR x_sql;
      FETCH c_ref_cursor INTO x_column_val;

      FOR rec1 IN ( SELECT *
                     FROM qa_plan_chars_v
                    WHERE plan_name = xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_NAME1') --'401 PRUEFANWEISUNG'
                      AND char_name = xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_CHAR_NAME1') --'401 PRUEFANWEISUNG'
                 )
      LOOP
         x_column_name1 := rec1.result_column_name;
      END LOOP;

      FOR rec2 IN ( SELECT *
                     FROM qa_plan_chars_v
                    WHERE plan_name = xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_NAME1') --'401 PRUEFANWEISUNG'
                      AND char_name = xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_CHAR_NAME2') --'401 PRUEFANWEISUNG TEXT1'
                 )
      LOOP
         x_column_name2 := rec2.result_column_name;
      END LOOP;

      x_sql1 := 'SELECT '||x_column_name2||
               '  FROM qa_results_v
                 WHERE '||x_column_name1||' = '||''''||x_column_val||''''||
               '   AND name = '||''''||xx_emf_pkg.get_paramater_value('XXPOCOMM','PLAN_NAME1')||'''';
      OPEN c_ref_cursor1 FOR x_sql1;
      FETCH c_ref_cursor1 INTO x_column_val1;

      RETURN x_column_val1;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END get_test_material;

   -- Function to return "Revision" -- Added for the "Revision Number" display enhancement on 5th June 2013
   FUNCTION get_revision (p_item_id IN NUMBER , p_creation_date IN DATE, p_ship_to_org IN NUMBER) -- NM: 18/11/14: Added parameter p_ship_to_org
   RETURN VARCHAR2
   IS
   x_rev VARCHAR2(100);
   BEGIN
      SELECT  mir.revision
       INTO x_rev
                       FROM mtl_item_revisions mir
                        WHERE mir.inventory_item_id = p_item_id
                        AND implementation_date IS NOT NULL -- NM: Added on 21st-Oct-2014
                        AND mir.organization_id = NVL(p_ship_to_org, fnd_profile.value('MSD_MASTER_ORG')) -- NM: 18/11/14: Added parameter instead of using master org -- fnd_profile.value('MSD_MASTER_ORG') -- Added on 6th-Feb-2014
                        AND TRUNC (p_creation_date) >= TRUNC (mir.effectivity_date) -- Added on 27-Mar-2014
                        AND mir.effectivity_date = (select max(effectivity_date) from mtl_item_revisions where inventory_item_id = mir.inventory_item_id
                                                                                                 AND TRUNC (p_creation_date) >= TRUNC (effectivity_date)
                                                                                                 and organization_id = mir.organization_id);

         RETURN x_rev;

     EXCEPTION
      WHEN TOO_MANY_ROWS THEN -- Added on 27-Mar-2014
       SELECT  max(mir.revision)
       INTO x_rev
                       FROM mtl_item_revisions mir
                        WHERE mir.inventory_item_id = p_item_id
              AND mir.organization_id = fnd_profile.value('MSD_MASTER_ORG') -- Added on 6th-Feb-2014
                          AND TRUNC (p_creation_date) >= TRUNC (mir.effectivity_date)
                          AND mir.effectivity_date = (select max(effectivity_date) from mtl_item_revisions where inventory_item_id = mir.inventory_item_id
                                                          AND TRUNC (p_creation_date) >= TRUNC (effectivity_date)
                                                                                                 and organization_id = mir.organization_id);
     RETURN x_rev;
    WHEN OTHERS THEN
         RETURN NULL;
   END get_revision;

     -- Function to return buyer/ship to/bill to address for ship to org - 116,403,404
      FUNCTION le_address
   RETURN VARCHAR2
   IS
      x_address               VARCHAR2(2000);
   BEGIN

         x_address := xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_ADD_LINE_1') ||chr(10)||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_ADD_LINE_2') ||chr(10)||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_ADD_LINE_3');

   RETURN x_address;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_address := NULL;
         RETURN x_address;
   END le_address;


-- Function to return buyer/ship to/bill to address for ship to org - 116,403,404 (Eng,French,Spanish)
      FUNCTION le_address1
   RETURN VARCHAR2
   IS
      x_address1               VARCHAR2(2000);
   BEGIN

         x_address1 := xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_ADD_LINE_1') ||chr(10)||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_ADD_LINE_2') ||chr(10)||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_ADD_LINE_4');

   RETURN x_address1;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_address1 := NULL;
         RETURN x_address1;
   END le_address1;

 -- Function to return bill to address for ship to org - 116
      FUNCTION le_bill_to_address
   RETURN VARCHAR2
   IS
      x_addressbill               VARCHAR2(2000);
   BEGIN

         x_addressbill := xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_BILL_TO_ADD_LINE_1') ||chr(10)||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_BILL_TO_ADD_LINE_2') ||chr(10)||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_BILL_TO_ADD_LINE_3');

   RETURN x_addressbill;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_addressbill := NULL;
         RETURN x_addressbill;
   END le_bill_to_address;

    -- Function to return note for ship to org - 116
      FUNCTION note
   RETURN VARCHAR2
   IS
      x_addressnote               VARCHAR2(2000);
   BEGIN

         x_addressnote := xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_BILL_TO_ADD_LINE_1')||', '||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_BILL_TO_ADD_LINE_2') ||'-'||
                      xx_emf_pkg.get_paramater_value('XXPOCOMM','LE_BILL_TO_ADD_LINE_3');

   RETURN x_addressnote;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_addressnote := NULL;
         RETURN x_addressnote;
   END note;

   -- Function to return bill to location name for ship to org - 116 and inv PO
      FUNCTION bill_loc_name_inv
   RETURN VARCHAR2
   IS
      x_bill_to_name               VARCHAR2(2000);
   BEGIN

         x_bill_to_name := xx_emf_pkg.get_paramater_value('XXPOCOMM','INVOICE_TO');

   RETURN x_bill_to_name;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_bill_to_name := NULL;
         RETURN x_bill_to_name;
   END bill_loc_name_inv;


   -- Function to return vat id for ship to org - 116
      FUNCTION vat_id_116
   RETURN VARCHAR2
   IS
      x_vat_id_116               VARCHAR2(2000);
   BEGIN

         x_vat_id_116 := xx_emf_pkg.get_paramater_value('XXPOCOMM','VAT_ID_116');

   RETURN x_vat_id_116;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_vat_id_116 := NULL;
         RETURN x_vat_id_116;
   END vat_id_116;

-- Function to return vat id for ship to org - 403
      FUNCTION vat_id_403
   RETURN VARCHAR2
   IS
      x_vat_id_403               VARCHAR2(2000);
   BEGIN

         x_vat_id_403 := xx_emf_pkg.get_paramater_value('XXPOCOMM','VAT_ID_403');

   RETURN x_vat_id_403;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_vat_id_403 := NULL;
         RETURN x_vat_id_403;
   END vat_id_403;

   -- Function to return vat id for ship to org - 404
      FUNCTION vat_id_404
   RETURN VARCHAR2
   IS
      x_vat_id_404               VARCHAR2(2000);
   BEGIN

         x_vat_id_404 := xx_emf_pkg.get_paramater_value('XXPOCOMM','VAT_ID_404');

   RETURN x_vat_id_404;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_vat_id_404 := NULL;
         RETURN x_vat_id_404;
   END vat_id_404;

    -- Function to return vat addr1
      FUNCTION vat_addr1
   RETURN VARCHAR2
   IS
      x_vat_addr1               VARCHAR2(2000);
   BEGIN

         x_vat_addr1 := xx_emf_pkg.get_paramater_value('XXPOCOMM','VAT_ADDR1');

   RETURN x_vat_addr1;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_vat_addr1 := NULL;
         RETURN x_vat_addr1;
   END vat_addr1;

       -- Function to return vat addr2
      FUNCTION vat_addr2
   RETURN VARCHAR2
   IS
      x_vat_addr2               VARCHAR2(2000);
   BEGIN

         x_vat_addr2 := xx_emf_pkg.get_paramater_value('XXPOCOMM','VAT_ADDR2');

   RETURN x_vat_addr2;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_vat_addr2 := NULL;
         RETURN x_vat_addr2;
   END vat_addr2;

-- Function to retrun last user name  -- Added on 21-May-14
         FUNCTION last_user_name (p_header_id     IN NUMBER
                             ,p_rev_num IN NUMBER
                            )
   RETURN VARCHAR2
   IS
      CURSOR c_name
      IS
       SELECT fusr.user_name FROM PO_ACTION_HISTORY pah , fnd_user fusr
        WHERE pah.object_id = p_header_id
        AND pah.object_revision_num = p_rev_num
        AND pah.action_code = 'SUBMIT'
        AND fusr.user_id = pah.last_updated_by
        order by pah.last_update_date desc;

      x_name               VARCHAR2(2000);
      x_count NUMBER := 1;
   BEGIN

      for rec_c_name IN c_name loop
         if x_count = 1 then
         x_name := rec_c_name.user_name;
         end if;
         x_count := 0;
           end loop;
   RETURN x_name;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_name := NULL;
         RETURN x_name;
   END last_user_name;

   -- Function to retrun last updated date  -- Added on 21-May-14
         FUNCTION last_updt_date (p_header_id     IN NUMBER
                             ,p_rev_num IN NUMBER
                            )
   RETURN DATE
   IS
      CURSOR c_date
      IS
       SELECT pah.last_update_date FROM PO_ACTION_HISTORY pah
        WHERE pah.object_id = p_header_id
        AND pah.object_revision_num = p_rev_num
        AND pah.action_code = 'SUBMIT'
        order by pah.last_update_date desc;

      x_date               DATE;
      x_count NUMBER := 1;
   BEGIN

      for rec_c_date IN c_date loop
         if x_count = 1 then
         x_date := rec_c_date.last_update_date;
         end if;
         x_count := 0;
           end loop;
   RETURN x_date;

   EXCEPTION
      WHEN OTHERS THEN
         -- Return a default format
         x_date := NULL;
         RETURN x_date;
   END last_updt_date;

END XX_PO_UTIL_PKG;
/
