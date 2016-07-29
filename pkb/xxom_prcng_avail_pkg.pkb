DROP PACKAGE BODY APPS.XXOM_PRCNG_AVAIL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXOM_PRCNG_AVAIL_PKG" 
AS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_PRCNG_AVAIL_PKG.sql
*
*   DESCRIPTION
*
*   USAGE
*
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
*
*   DEPENDENCIES           Pricing Web Service - OSB Web Service.
*
*   CALLED BY              Surgi-Soft Web App while raising charge sheet.
*
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     2.0 18-SEP-2013 Brian Stadnik     Changed to use the Party_site_number first, then
*                                       if you cannot find, use the account info.
*     2.1  25-FEB-2014 Jagdish bhosale  1. defined new Profile INTG Surgisoft Default Price List
*                                         to derive price list id it fails to get price list from cust hierarchy.
*     2.2  25-FEB-2014 Jagdish Bhosale  Bug Fix: Multiple product request for price was not working properly.
*                                       Change made to call Pricing API individually rather than clubiing together in PL/SQL tbl.
*     2.3  16-APR-2014 Brian Stadnik    Modified Bill To lookup information to include the relationship logic, including the comments
*                                          lookup
* ISSUES:
*     2.4  09-JUL-2014 Sri Venkataraman Added check to validate the item in the customer price list. If not present, ILS List Price is passed.
*     2.5  09-Apr-2015 Sri Venkataraman Operating Unit Id changed to 101 from 82 
******************************************************************************************/
   PROCEDURE log_message (p_log_message IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO xxintg_cnsgn_cmn_log_tbl
           VALUES (xxintg_cnsgn_cmn_log_seq.NEXTVAL,
                   'PRICE-WS',
                   p_log_message,
                   SYSDATE
                  );

      COMMIT;
      --DBMS_OUTPUT.PUT_LINE (p_log_message);
   END log_message;

   PROCEDURE get_item_information (
      p_part_number           IN              VARCHAR2,
      p_organization_code     IN              VARCHAR2,
      x_inventory_item_id     OUT NOCOPY      NUMBER,
      x_primary_uom_code      OUT NOCOPY      VARCHAR2,
      x_uom_conversion_rate   OUT NOCOPY      NUMBER,
      x_lot_control           OUT NOCOPY      BOOLEAN,
      x_serial_control        OUT NOCOPY      BOOLEAN,
      x_business_unit         OUT NOCOPY      VARCHAR2,
      x_category_id           OUT NOCOPY      NUMBER,
      x_product_segment       OUT NOCOPY      VARCHAR2,
      x_product_brand         OUT NOCOPY      VARCHAR2,
      x_product_class         OUT NOCOPY      VARCHAR2,
      x_product_type          OUT NOCOPY      VARCHAR2,
      x_return_status         OUT NOCOPY      VARCHAR2,
      x_msg_data              OUT NOCOPY      VARCHAR2
   )
   IS
      l_lot_control        NUMBER;
      l_serial_control     NUMBER;
      l_primary_uom_code   VARCHAR2 (20);
   BEGIN
      -- Find the inventory_item_id and primary_uom_code
      -- based on the passed in item for use in queries and API calls
      SELECT msib.inventory_item_id,
             msib.primary_uom_code,
             msib.lot_control_code,
             msib.serial_number_control_code,
             -- removed UOM logic; always use primary per current business rules
             1,                                                                                  -- muc.conversion_rate,
             mc.segment4,
             mc.segment10,
             mc.segment7,
             mc.segment8,
             mc.segment9,
             mc.category_id
        INTO x_inventory_item_id,
             x_primary_uom_code,
             l_lot_control,
             l_serial_control,
             x_uom_conversion_rate,
             x_business_unit,
             x_product_segment,
             x_product_brand,
             x_product_class,
             x_product_type,
             x_category_id
        FROM mtl_system_items_b msib,
             mtl_parameters mp,
             -- mtl_uom_conversions muc,
             mtl_item_categories mic,
             mtl_category_sets mcs,
             mtl_categories mc
       WHERE msib.segment1 = p_part_number
         AND msib.organization_id = mp.organization_id
         AND mp.organization_code = p_organization_code
         AND mic.inventory_item_id = msib.inventory_item_id
         AND mic.organization_id = mp.organization_id
         AND mcs.category_set_id(+) = mic.category_set_id
         AND mic.category_id = mc.category_id
         AND UPPER (mcs.category_set_name) = 'SALES AND MARKETING';

      IF (l_lot_control = 1)
      THEN
         x_lot_control              := FALSE;
      ELSE
         x_lot_control              := TRUE;
      END IF;

      IF (l_serial_control = 1)
      THEN
         x_serial_control           := FALSE;
      ELSE
         x_serial_control           := TRUE;
      END IF;

      x_return_status            := 'S';
      x_msg_data                 := 'Successfully Retrieved Item Information.';
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status            := 'E';
         x_msg_data                 := SQLCODE || ': ' || SQLERRM;
   END get_item_information;

   PROCEDURE get_item_pricing_xml (
      p_country             IN              VARCHAR2,
      p_account_number      IN              VARCHAR2,
      p_construct_pricing   IN              VARCHAR2,
      p_product_info        IN              xxintg_t_product_t,
      x_item_pricing_xml    IN OUT NOCOPY   XMLTYPE,
      x_return_status       IN OUT NOCOPY   VARCHAR2,
      x_return_code         IN OUT          VARCHAR2,
      x_msg_data            IN OUT NOCOPY   VARCHAR2
   )
   IS
      l_pricing_tbl              qp_preq_grp.line_tbl_type;
      l_temp_xml                 VARCHAR2 (2000) := NULL;
   BEGIN

      log_message ('Pricing request for ' || p_product_info.COUNT || ' items.');

      Get_Item_Pricing (p_country           => p_country,
                        --We receive p_account_number, but it is actually a party_site_number.
                        p_party_site_number => p_account_number,
                        p_construct_pricing => p_construct_pricing,
                        p_product_info      => p_product_info,
                        x_pricing_tbl       => l_pricing_tbl,
                        x_return_status     => x_return_status,
                        x_return_code       => x_return_code,
                        x_msg_data          => x_msg_data);

      log_message ('Pricing returned for ' || l_pricing_tbl.COUNT || ' items.');

      IF x_return_status = fnd_api.g_ret_sts_success THEN
         --The price can now be formatted into the return xml

         /*
         || Calling with multiple products in a single call has been re-enabled.
         ||
         ---------------------------------------------------------------------------
         -- 02/25 Jagdish
         -- Below Loop Commneted as we are making Pricing call for
         -- individual product rather than passing all product to PL/SQL table
         -- and collecting data,
         ---------------------------------------------------------------------------

         log_message ('--------------------------');
         l_temp_xml                 :=
               l_temp_xml
            || '<PartNumber>'
            || p_product_info (p_product_info.FIRST).item
            || '</PartNumber>'
            || '<Price>'
            || l_pricing_tbl(l_pricing_tbl.FIRST).adjusted_unit_price
            || '</Price>';
         log_message ('l_temp_xml' || l_temp_xml);
         -- l_part_number := l_product_info(n).item;       l_primary_uom_code :=  l_product_info(n).uom;       l_item_quantity := l_product_info(n).quantity;
         --END LOOP;
         --END LOOP;                                                                                          -- Product Loop

         -- add cdata
         l_temp_xml                 := '<PricingInfo>' || l_temp_xml || '</PricingInfo>';
         log_message ('l_temp_xml - After Loop ' || l_temp_xml);
         */

         FOR m IN p_product_info.First..p_product_info.Last
         LOOP
            log_message ('m: '||m);
            log_message ('--------------------------');
            l_temp_xml := l_temp_xml || '<PartNumber>' || p_product_info(m).item || '</PartNumber>'  ||
                                       '<Price>' || l_pricing_tbl(m).adjusted_unit_price || '</Price>';
            log_message ('l_temp_xml ' ||    l_temp_xml);
         END LOOP;
         l_temp_xml := '<PricingInfo>' || l_temp_xml || '</PricingInfo>';
         log_message ('l_temp_xml - After Loop ' || l_temp_xml);

         -- create the XML
         -- Need to add XMLAGG and XMLFOREST TO DO THIS PROPERLY
         -- round and pad to the currency precision
         SELECT XMLELEMENT ("FetchPricingInfoResponse", XMLCDATA (l_temp_xml)
                              -- XMLELEMENT("PricingInfo",l_temp_xml)
                               /*
                              XMLELEMENT("PricingInfo", XMLELEMENT("PartNumber", l_part_number), XMLELEMENT("PRICE", TO_CHAR( ROUND(l_adjusted_price_t(2).price,l_currency_precision), 'fm999999999.90' )
              -- substr(l_adjusted_price, 0, instr--
              -- to_char,l_currency_precision)
              ),
                              XMLELEMENT("CurrencyCode", l_currency_code),
                              XMLELEMENT("UOM", l_primary_uom_code)
                              ) */
                              --  Can loop through here for each return value
                              /*
                              ,

                              XMLELEMENT("PricingInfo", XMLELEMENT("PartNumber", l_part_number), XMLELEMENT("PRICE", TO_CHAR( ROUND(l_adjusted_prices(2),l_currency_precision), 'fm999999999.90' )
              -- substr(l_adjusted_price, 0, instr--
              -- to_char,l_currency_precision)
              ),
                              XMLELEMENT("CurrencyCode", l_currency_code),
                              XMLELEMENT("UOM", l_primary_uom_code)

                              )
                                   */
             )
         INTO x_item_pricing_xml
         FROM DUAL;

         x_msg_data                 := 'Successfully constructed Item Pricing XML';

      ELSE
         --Just pass back the error status and message from the called API.
         NULL;
      END IF;

   END get_item_pricing_xml;




   PROCEDURE Get_Item_Pricing (
       p_country           IN VARCHAR2,
       p_party_site_number IN VARCHAR2,
       p_construct_pricing IN VARCHAR2,
       p_product_info      IN  xxintg_t_product_t,
       x_pricing_tbl       OUT qp_preq_grp.line_tbl_type,
       x_return_status     OUT VARCHAR2,
       x_return_code       OUT VARCHAR2,
       x_msg_data          OUT VARCHAR2)
   IS
      l_part_number              VARCHAR2 (30);
      l_item_quantity            NUMBER;
      l_product_info             xxintg_t_product_t;
      l_inventory_item_id        NUMBER;
      l_primary_uom_code         mtl_system_items_b.primary_uom_code%TYPE;
      l_uom_conversion_rate      NUMBER;
      l_return_status            VARCHAR2 (20);
      l_msg_data                 VARCHAR2 (2000);
      v_line_tbl_cnt             INTEGER;
      i                          BINARY_INTEGER;
      j                          NUMBER                                       := 1;
      k                          NUMBER;
      m                          NUMBER;
      n                          NUMBER;
      l_version                  VARCHAR2 (240);
      l_file_val                 VARCHAR2 (1000); -- Increased the variable size by K Ayalavarapu on 6/5/2014
      l_debug                    BOOLEAN                                      := TRUE;
      l_account_number           VARCHAR2 (30);
      l_bill_to_site_id          NUMBER;
      l_ship_to_site_id          NUMBER;
      l_bill_to_site_use_id      NUMBER;
      l_party_site_id            NUMBER;
      l_party_site_number        VARCHAR2 (50);
      l_price_list_id            NUMBER;
      l_customer_id              NUMBER;
      l_customer_class_code      VARCHAR2 (240);
      l_sales_channel_code       VARCHAR2 (240);
      l_account_name             VARCHAR2 (240);
      l_temp_price               NUMBER;
      l_adjusted_price_t         intg_t_adjusted_price_t;
      l_adjusted_price           NUMBER                                       := 0;
      l_lot_control              BOOLEAN                                      := FALSE;
      l_serial_control           BOOLEAN                                      := FALSE;
      l_category_id              NUMBER;
--    l_operating_unit           NUMBER                                       := 82;
      l_operating_unit           NUMBER                                       := 101;
      l_organization_id          NUMBER;
      l_organization_code        VARCHAR2 (10)                                := '150';
      l_business_unit            VARCHAR2 (40);
      l_product_brand            VARCHAR2 (40);
      l_product_segment          VARCHAR2 (40);
      l_product_class            VARCHAR2 (40);
      l_product_type             VARCHAR2 (40);
      l_currency_code            gl_currencies.currency_code%TYPE;
      l_currency_precision       gl_currencies.PRECISION%TYPE;
      l_sales_organization       VARCHAR2 (240);
      price_not_found            EXCEPTION;
      p_line_tbl                 qp_preq_grp.line_tbl_type;
      p_qual_tbl                 qp_preq_grp.qual_tbl_type;
      p_line_attr_tbl            qp_preq_grp.line_attr_tbl_type;
      p_line_detail_tbl          qp_preq_grp.line_detail_tbl_type;
      p_line_detail_qual_tbl     qp_preq_grp.line_detail_qual_tbl_type;
      p_line_detail_attr_tbl     qp_preq_grp.line_detail_attr_tbl_type;
      p_related_lines_tbl        qp_preq_grp.related_lines_tbl_type;
      p_control_rec              qp_preq_grp.control_record_type;
      x_line_tbl                 qp_preq_grp.line_tbl_type;
      x_line_qual                qp_preq_grp.qual_tbl_type;
      x_line_attr_tbl            qp_preq_grp.line_attr_tbl_type;
      x_line_detail_tbl          qp_preq_grp.line_detail_tbl_type;
      x_line_detail_qual_tbl     qp_preq_grp.line_detail_qual_tbl_type;
      x_line_detail_attr_tbl     qp_preq_grp.line_detail_attr_tbl_type;
      x_related_lines_tbl        qp_preq_grp.related_lines_tbl_type;
      x_return_status_text       VARCHAR2 (240);
      qual_rec                   qp_preq_grp.qual_rec_type;
      line_attr_rec              qp_preq_grp.line_attr_rec_type;
      line_rec                   qp_preq_grp.line_rec_type;
      detail_rec                 qp_preq_grp.line_detail_rec_type;
      ldet_rec                   qp_preq_grp.line_detail_rec_type;
      rltd_rec                   qp_preq_grp.related_lines_rec_type;
      l_pricing_contexts_tbl     qp_attr_mapping_pub.contexts_result_tbl_type;
      l_qualifier_contexts_tbl   qp_attr_mapping_pub.contexts_result_tbl_type;
      l_ship_to_cust_acct_id     number;
      l_dcode varchar2(100);
      l_relationship_count       NUMBER;
      l_relationship_where       VARCHAR2(30) := '%';
   BEGIN
      l_product_info             := xxintg_t_product_t ();
      l_product_info             := p_product_info;
      l_adjusted_price_t         := intg_t_adjusted_price_t ();
      -- The signature has the account number, but we actually have changed
      -- to pass in the party_site_number
      l_party_site_number        := p_party_site_number;
      l_price_list_id            := NULL;

      -- Get Customer Ship To information
      -- BXS ** ship_to qualifer **
      BEGIN
         SELECT hca.account_number,
                hcsu.site_use_id,
                hps.party_site_id,
                hcsu.bill_to_site_use_id,
                hcsu.org_id
           INTO l_account_number,
                l_ship_to_site_id,
                l_party_site_id,
                l_bill_to_site_use_id,
                l_organization_id
           FROM hz_party_sites hps,
                hz_locations l,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsu,
                hz_cust_accounts hca
          WHERE hps.location_id = l.location_id
            AND hps.party_site_number = l_party_site_number
            AND hcas.party_site_id = hps.party_site_id
            AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
            AND hcsu.site_use_code = 'SHIP_TO'
            AND hcsu.primary_flag = 'Y'
            AND hcas.status = 'A'
            AND hcsu.status = 'A'
            AND hcsu.org_id = l_operating_unit
            AND hca.party_id = hps.party_id;

         log_message ('Got Ship To and Bill to Reference: ' || l_bill_to_site_use_id);
      EXCEPTION
         /*  -- combine, same logic
         WHEN TOO_MANY_ROWS THEN
           -- ignore, we'll try to figure out another way
           l_msg_data := 'Multiple Active Ship To Found 1.';
           log_message(l_msg_data);
           -- RAISE price_not_found;
           select hca.account_number
           into l_account_number
           from hz_cust_accounts hca, hz_party_sites hps
           where hca.party_id = hps.party_id
           and   hps.party_site_number = l_party_site_number;
           */
         WHEN OTHERS
         THEN
            -- ignore, we'll try to figure out another way
            l_msg_data                 := 'No Active Primary Ship To Found.';
            log_message (l_msg_data);

            -- BXS RAISE price_not_found; -- BXS Why not????
            SELECT hca.account_number
              INTO l_account_number
              FROM hz_cust_accounts hca,
                   hz_party_sites hps
             WHERE hca.party_id = hps.party_id AND hps.party_site_number = l_party_site_number;

            log_message ('l_account_number: ' || l_account_number);
      END;

      -- Get Customer Ship To information
      BEGIN
         SELECT hcsu.site_use_id,
                hps.party_site_id,
                hcsu.bill_to_site_use_id,
                hcsu.org_id
           INTO l_ship_to_site_id,
                l_party_site_id,
                l_bill_to_site_use_id,
                l_organization_id
           FROM hz_party_sites hps,
                hz_locations l,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsu,
                hz_cust_accounts hca
          WHERE hps.location_id = l.location_id
            AND hps.party_site_id = hcas.party_site_id
            AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
            AND hcsu.site_use_code = 'SHIP_TO'
            AND hcsu.primary_flag = 'Y'
            AND hcas.status = 'A'
            AND hcsu.status = 'A'
            AND hcsu.org_id = l_operating_unit
            AND hca.party_id = hps.party_id
            AND hca.account_number = l_account_number;                                     -- TO_CHAR(p_account_number);

         log_message ('Got Ship To and Bill to Reference: ' || l_bill_to_site_use_id);
      EXCEPTION
         WHEN TOO_MANY_ROWS
         THEN
            -- ignore, we'll try to figure out another way
            l_msg_data                 := 'Multiple Active Ship To Found.';
            log_message (l_msg_data);
            log_message ('l_account_number: ' || l_account_number);
         WHEN OTHERS
         THEN
            -- ignore, we'll try to figure out another way
            l_msg_data                 := 'No Active Primary Ship To Found.';
            log_message (l_msg_data);
            log_message ('l_account_number: ' || l_account_number);
      END;
/* Code added by K Ayalavarapu  on 5/6/2014 to get the default price list starts here*/
---------------------------------------
-- Get price List from Profile Option--
---------------------------------------

                    fnd_profile.get ('INTG_SURGISOFT_DEF_PRICE_LIST', l_price_list_id);
                    log_message ('2 - Price List From Profile   ' || l_price_list_id);
                    --Gather required bits from Price List
                    SELECT qlh.currency_code,
                           gc.PRECISION
                      INTO l_currency_code,
                           l_currency_precision
                      FROM gl_currencies gc,
                           qp_list_headers_b qlh
                     WHERE gc.currency_code = qlh.currency_code
                       AND qlh.list_header_id = l_price_list_id;
/* Code added by K Ayalavarapu  on 5/6/2014 to get the default price list starts here*/
      -- Get the customer bill to information
      IF (l_bill_to_site_use_id IS NOT NULL)
      THEN
         BEGIN
            SELECT hca.cust_account_id,
                   hcsu.site_use_id,
                   nvl(NVL (hcsu.price_list_id, hca.price_list_id),l_price_list_id) price_list_id, -- added NVL with l_price_list_id by K Ayalavarapu on 5/6/2014
                   qlh.currency_code,
                   gc.PRECISION,
                   hca.customer_class_code,
                   hca.sales_channel_code,
                   hca.account_name,
                   hcsu.org_id
              INTO l_customer_id,
                   l_bill_to_site_id,
                   l_price_list_id,
                   l_currency_code,
                   l_currency_precision,
                   l_customer_class_code,
                   l_sales_channel_code,
                   l_account_name,
                   l_sales_organization
              FROM gl_currencies gc,
                   qp_list_headers_b qlh,
                   hz_party_sites hps,
                   hz_locations l,
                   hz_cust_acct_sites_all hcas,
                   hz_cust_site_uses_all hcsu,
                   hz_cust_accounts hca
             WHERE gc.currency_code = qlh.currency_code
               AND gc.enabled_flag = 'Y'
               AND qlh.active_flag = 'Y'
               AND qlh.list_header_id = nvl(NVL (hcsu.price_list_id, hca.price_list_id),l_price_list_id) -- added NVL with l_price_list_id by K Ayalavarapu on 5/6/2014
               AND hps.location_id = l.location_id
               AND hps.party_site_id = hcas.party_site_id
               AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
               AND hcsu.site_use_code = 'BILL_TO'
               AND hcsu.primary_flag = 'Y'
               AND hcas.status = 'A'
               AND hcsu.status = 'A'
               AND hcsu.org_id = l_operating_unit
               AND hcsu.site_use_id = l_bill_to_site_use_id
               AND hca.party_id = hps.party_id;
             log_message (' in qry 1');
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data                 := 'No Bill To Found.';
               log_message (l_msg_data);
--  RAISE price_not_found;
---------------------------------------
-- Get price List from Profile Option--
---------------------------------------
               fnd_profile.get ('INTG_SURGISOFT_DEF_PRICE_LIST', l_price_list_id);
               log_message ('1 - Price List From Profile   ' || l_price_list_id);
                 --Gather required bits from Price List
                 SELECT qlh.currency_code,
                        gc.PRECISION
                   INTO l_currency_code,
                        l_currency_precision
                   FROM gl_currencies gc,
                        qp_list_headers_b qlh
                  WHERE gc.currency_code = qlh.currency_code
                    AND qlh.list_header_id = l_price_list_id;
         END;
      END IF;

      IF (l_bill_to_site_use_id IS NULL)
      THEN
         log_message ('Looking at Active Bill To Site Usage.');

         BEGIN
            SELECT hca.cust_account_id,
                   hcsu.site_use_id,
                   nvl(NVL (hcsu.price_list_id, hca.price_list_id),l_price_list_id) price_list_id,-- added NVL with l_price_list_id by K Ayalavarapu on 5/6/2014
                   NVL (qlh.currency_code, 'USD'),
                   gc.PRECISION,
                   hca.customer_class_code,
                   hca.sales_channel_code,
                   hca.account_name,
                   hcsu.org_id
              INTO l_customer_id,
                   l_bill_to_site_id,
                   l_price_list_id,
                   l_currency_code,
                   l_currency_precision,
                   l_customer_class_code,
                   l_sales_channel_code,
                   l_account_name,
                   l_sales_organization
              FROM gl_currencies gc,
                   qp_list_headers_b qlh,
                   hz_party_sites hps,
                   hz_locations l,
                   hz_cust_acct_sites_all hcas,
                   hz_cust_site_uses_all hcsu,
                   hz_cust_accounts hca
             WHERE gc.currency_code = NVL (qlh.currency_code, 'USD')
               AND qlh.list_header_id = nvl(NVL (hcsu.price_list_id, hca.price_list_id),l_price_list_id)-- added NVL with l_price_list_id by K Ayalavarapu on 5/6/2014
               AND hps.location_id = l.location_id
               AND hps.party_site_id = hcas.party_site_id
               AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
               AND hcsu.site_use_code = 'BILL_TO'
               AND hcsu.primary_flag = 'Y'
               AND hcas.status = 'A'
               AND hcsu.status = 'A'
               AND hcsu.org_id = l_operating_unit
               AND hca.party_id = hps.party_id
               AND hca.account_number = l_account_number;
            --   AND hcsu.price_list_id IS NOT NULL;              -- Added by Jagdish 03/04                     -- TO_CHAR(p_account_number);
       -- log_message (' in qry 2');
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               log_message ('Not the primary Bill To.  Check the Ship To now: ' || p_party_site_number || '/' || l_account_number);

               BEGIN
                  --Count relationships.  If more than 1, create a condition for the following SQL.
                  SELECT count(*)
                    INTO l_relationship_count
                    FROM hz_cust_acct_relate_all hcar,
                         hz_party_sites hps,
                         hz_locations l,
                         hz_cust_acct_sites_all hcas,
                         hz_cust_site_uses_all hcsu,
                         hz_cust_accounts hca
                   WHERE hcar.status = 'A'
                     --AND UPPER(hcar.comments) like 'PARENT%BILLER'
                     AND hcar.cust_account_id = hca.cust_account_id
                     AND hps.location_id = l.location_id
                     AND hps.party_site_id = hcas.party_site_id
                     AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcsu.site_use_code = 'SHIP_TO'
                     AND hcas.status = 'A'
                     AND hcsu.status = 'A'
                     AND hcsu.org_id = l_operating_unit
                     AND hca.party_id = hps.party_id
                     AND hca.account_number = l_account_number;
                  IF l_relationship_count > 1
                  THEN
                     l_relationship_where := 'PARENT%BILLER';
                  ELSE
                     l_relationship_where := '%';
                  END IF;

                  log_message ('Related customer count: ' || l_relationship_count || ' where clause = ' || l_relationship_where);
            --   log_message (' before qry 3');
                  SELECT hca.cust_account_id,
                         hcsu.site_use_id,
                        nvl(NVL (hcsu.price_list_id, hca.price_list_id),l_price_list_id) price_list_id,-- added NVL with l_price_list_id by K Ayalavarapu on 5/6/2014
                         qlh.currency_code,
                         gc.PRECISION,
                         hca.customer_class_code,
                         hca.sales_channel_code,
                         hca.account_name,
                         hcsu.org_id
                    INTO l_customer_id,
                         l_bill_to_site_id,
                         l_price_list_id,
                         l_currency_code,
                         l_currency_precision,
                         l_customer_class_code,
                         l_sales_channel_code,
                         l_account_name,
                         l_sales_organization
                    FROM gl_currencies gc,
                         qp_list_headers_b qlh,
                         hz_party_sites hps,
                         hz_locations l,
                         hz_cust_acct_sites_all hcas,
                         hz_cust_site_uses_all hcsu,
                         hz_cust_accounts hca
                   WHERE gc.currency_code = qlh.currency_code
                     AND qlh.list_header_id = nvl(NVL (hcsu.price_list_id, hca.price_list_id),l_price_list_id)-- added NVL with l_price_list_id by K Ayalavarapu on 5/6/2014
                     AND hps.location_id = l.location_id
                     AND hps.party_site_id = hcas.party_site_id
                     AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcsu.site_use_code = 'BILL_TO'
                     AND hcsu.primary_flag = 'Y'
                     AND hcas.status = 'A'
                     AND hcsu.status = 'A'
                     AND hcsu.org_id = l_operating_unit
                     AND hca.party_id = hps.party_id
                    -- AND hcsu.price_list_id IS NOT NULL     -- Added by Jagdish 03/04
                     AND hca.cust_account_id =
                            (                                                            -- this assumes a single record
                             SELECT DISTINCT hcar.related_cust_account_id
                                        FROM hz_cust_acct_relate_all hcar,
                                             hz_party_sites hps,
                                             hz_locations l,
                                             hz_cust_acct_sites_all hcas,
                                             hz_cust_site_uses_all hcsu,
                                             hz_cust_accounts hca
                                       WHERE --hcar.bill_to_flag = 'Y'
                                         --AND
                                         hcar.status = 'A'
                                         AND NVL (UPPER(hcar.comments), 'x') like l_relationship_where--'PARENT%BILLER'
                                         AND hcar.cust_account_id = hca.cust_account_id
                                         AND hps.location_id = l.location_id
                                         AND hps.party_site_id = hcas.party_site_id
                                         AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                                         AND hcsu.site_use_code = 'SHIP_TO'
                                         AND hcas.status = 'A'
                                         AND hcsu.status = 'A'
                                         AND hcsu.org_id = l_operating_unit
                                         AND hca.party_id = hps.party_id
                                         AND hca.account_number = l_account_number         -- TO_CHAR( p_account_number)
                                                                                  );
         --  log_message (' in qry 3');
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     l_msg_data                 := 'No Bill To Found from the ship to.';
                     log_message (l_msg_data);
 --  RAISE price_not_found;
---------------------------------------
-- Get price List from Profile Option--
---------------------------------------

                    fnd_profile.get ('INTG_SURGISOFT_DEF_PRICE_LIST', l_price_list_id);
                    log_message ('2 - Price List From Profile   ' || l_price_list_id);
                    --Gather required bits from Price List
                    SELECT qlh.currency_code,
                           gc.PRECISION
                      INTO l_currency_code,
                           l_currency_precision
                      FROM gl_currencies gc,
                           qp_list_headers_b qlh
                     WHERE gc.currency_code = qlh.currency_code
                       AND qlh.list_header_id = l_price_list_id;

               END;
            WHEN OTHERS
            THEN
               l_msg_data                 := 'No Bill To Found.';
               log_message (l_msg_data);
               log_message (SQLERRM);
     ---------------------------------------
     --  RAISE price_not_found;
     ---------------------------------------
     -- Get price List from Profile Option--
     ---------------------------------------

                fnd_profile.get ('INTG_SURGISOFT_DEF_PRICE_LIST', l_price_list_id);
                log_message ('3 - Price List From Profile   ' || l_price_list_id);
                 --Gather required bits from Price List
                 SELECT qlh.currency_code,
                        gc.PRECISION
                   INTO l_currency_code,
                        l_currency_precision
                   FROM gl_currencies gc,
                        qp_list_headers_b qlh
                  WHERE gc.currency_code = qlh.currency_code
                    AND qlh.list_header_id = l_price_list_id;

         END;
      END IF;

      log_message ('Turning on debugging if set...');

      IF l_price_list_id IS NULL THEN
       BEGIN    -- Added by Jagdish 03/04
        SELECT price_list_id INTO l_price_list_id
        FROM hz_cust_accounts_all WHERE account_number = l_account_number;-- and NVL(org_id, l_operating_unit)  = l_operating_unit ;
        log_message ('Found ' || l_price_list_id || ' for ' || l_account_number);
           --Gather required bits from Price List
           SELECT qlh.currency_code,
                  gc.PRECISION
             INTO l_currency_code,
                  l_currency_precision
             FROM gl_currencies gc,
                  qp_list_headers_b qlh
            WHERE gc.currency_code = qlh.currency_code
              AND qlh.list_header_id = l_price_list_id;
       EXCEPTION
        WHEN OTHERS THEN
        fnd_profile.get ('INTG_SURGISOFT_DEF_PRICE_LIST', l_price_list_id);
        log_message ('4 - Price List From Profile   ' || l_price_list_id);
           --Gather required bits from Price List
           SELECT qlh.currency_code,
                  gc.PRECISION
             INTO l_currency_code,
                  l_currency_precision
             FROM gl_currencies gc,
                  qp_list_headers_b qlh
            WHERE gc.currency_code = qlh.currency_code
              AND qlh.list_header_id = l_price_list_id;
       END;     --
      END IF;

       log_message ('Price List to API - '||l_price_list_id);

      -- Turn on Debugging if desired
      IF (l_debug)
      THEN
         oe_debug_pub.debug_on;
         oe_debug_pub.initialize;
    --     dbms_output.put_line('l_file_val '||l_file_val);
         l_file_val                 := oe_debug_pub.set_debug_mode ('FILE');
    --     dbms_output.put_line('l_file_val '||l_file_val);
         oe_debug_pub.setdebuglevel (5);
    --     dbms_output.put_line('l_file_val '||l_file_val);
         log_message ('File : ' || l_file_val);
      END IF;

      log_message ('Building the Contexts...');
      qp_attr_mapping_pub.build_contexts (p_request_type_code              => 'ONT',
                                          p_pricing_type                   => 'L',
                                          x_price_contexts_result_tbl      => l_pricing_contexts_tbl,
                                          x_qual_contexts_result_tbl       => l_qualifier_contexts_tbl
                                         );
      v_line_tbl_cnt             := 1;
      ---- Control Record
      p_control_rec.pricing_event := 'LINE';                                                                 -- 'BATCH';
      p_control_rec.calculate_flag := 'Y';                                           --QP_PREQ_GRP.G_SEARCH_N_CALCULATE;
      p_control_rec.simulation_flag := 'N';
      p_control_rec.rounding_flag := 'Q';
      p_control_rec.manual_discount_flag := 'Y';
      p_control_rec.request_type_code := 'ONT';
      p_control_rec.temp_table_insert_flag := 'Y';
      l_adjusted_price_t.DELETE;

      -- BXS LOOP THROUGH HERE
      FOR n IN l_product_info.FIRST .. l_product_info.LAST
      LOOP
         l_part_number              := l_product_info (n).item;
         l_primary_uom_code         := l_product_info (n).uom;
         l_item_quantity            := l_product_info (n).quantity;
         -- Find the inventory_item_id and primary_uom_code
         -- based on the passed in item for use in queries and API calls
         get_item_information (p_part_number              => l_part_number,
                               p_organization_code        => l_organization_code,
                               x_inventory_item_id        => l_inventory_item_id,
                               x_primary_uom_code         => l_primary_uom_code,
                               x_uom_conversion_rate      => l_uom_conversion_rate,
                               x_lot_control              => l_lot_control,
                               x_serial_control           => l_serial_control,
                               x_category_id              => l_category_id,
                               x_business_unit            => l_business_unit,
                               x_product_segment          => l_product_segment,
                               x_product_brand            => l_product_brand,
                               x_product_class            => l_product_class,
                               x_product_type             => l_product_type,
                               x_return_status            => l_return_status,
                               x_msg_data                 => l_msg_data
                              );

         IF (l_return_status = 'E')
         THEN
            l_msg_data                 := 'ITEM_INFO: ' || l_msg_data;
            RAISE price_not_found;
         END IF;

         p_line_tbl.DELETE;                                              -- 02/25 Jagdish Flush out previous product. --
         ---- Line Records ---------
         -- this is for each line in the order...in this case, we are only pricing one line/item
         -- p_line_tbl used to be hard coded to 1
         line_rec.request_type_code := 'ONT';
         line_rec.line_id           := 9999;                     -- Order Line Id. This can be any thing for this script
         line_rec.line_index        := n;                                   -- '1';                -- Request Line Index
         line_rec.line_type_code    := 'LINE';                                            -- LINE or ORDER(Summary Line)
         line_rec.pricing_effective_date := SYSDATE;                                        -- Pricing as of what date ?
         line_rec.active_date_first := SYSDATE;                                      -- Can be Ordered Date or Ship Date
         line_rec.active_date_second := SYSDATE;                                     -- Can be Ordered Date or Ship Date
         line_rec.active_date_first_type := 'NO TYPE';                                                       -- ORD/SHIP
         line_rec.active_date_second_type := 'NO TYPE';                                                      -- ORD/SHIP
         line_rec.line_quantity     := l_item_quantity;                                         --1; -- Ordered Quantity
         line_rec.line_uom_code     := l_primary_uom_code;                                   --'EA'; -- Ordered UOM Code
         line_rec.currency_code     := l_currency_code;                                                 -- Currency Code
         line_rec.price_flag        := 'Y';                    -- Price Flag can have 'Y' , 'N'(No pricing) , 'P'(Phase)
         p_line_tbl (n)             := line_rec;
         ---- Line Attribute Record
         -- Pricing Contexts
         p_line_attr_tbl.DELETE;

         IF (l_inventory_item_id IS NOT NULL)
         THEN
            line_attr_rec.line_index   := n;
            line_attr_rec.pricing_context := 'ITEM';
            line_attr_rec.pricing_attribute := 'PRICING_ATTRIBUTE1';
            line_attr_rec.pricing_attr_value_from := l_inventory_item_id;
            line_attr_rec.validated_flag := 'N';
            p_line_attr_tbl (j)        := line_attr_rec;
/*Code fix for Price List by Sri V on 09-Jul-2014 Starts here*/
--Assumption is price list is defined at the inventory item id only.
--If the item is not on the customer price list, exception will be raised and the ILS list price will be passed to the pricing engine
            IF fnd_profile.value('INTG_SURGISOFT_DEF_PRICE_LIST') <> l_price_list_id
            AND l_price_list_id IS NOT NULL
            THEN
               BEGIN
                  SELECT list_header_id
                    INTO l_price_list_id
                    FROM apps.qp_list_lines_v
                   WHERE list_header_id = l_price_list_id
                     AND product_attribute = 'PRICING_ATTRIBUTE1'
                     AND product_attr_value = l_inventory_item_id
                     AND sysdate between NVL(start_date_active,sysdate) and NVL(end_date_active,sysdate);
               EXCEPTION
                  WHEN OTHERS THEN
                      fnd_profile.get ('INTG_SURGISOFT_DEF_PRICE_LIST', l_price_list_id);
               END;
            END IF;
/*Code fix for Price List by Sri V on 09-Jul-2014 ends here*/
         END IF;
          /* Code by K AYalavarapu on 5/23/2014 to pass in DCODE context to the API starts here  */
          if l_inventory_item_id is not null then
          begin
              select segment9 into l_dcode from apps.mtl_item_categories_v
            where inventory_item_id=l_inventory_item_id  and organization_id=83 and category_set_name='Sales and Marketing';
            exception
            when others then
            null;
          end;
          end if;

         IF (l_dcode IS NOT NULL)
         THEN

            line_attr_rec.line_index   := n;
            line_attr_rec.pricing_context := 'ITEM';
            line_attr_rec.pricing_attribute := 'PRICING_ATTRIBUTE25';
            line_attr_rec.pricing_attr_value_from := l_dcode;
            line_attr_rec.validated_flag := 'N';
              j                          := j + 1;
            p_line_attr_tbl (j)        := line_attr_rec;
         END IF;
/* Code by K AYalavarapu on 5/23/2014 to pass in DCODE context to the API starts here  */
         IF (l_category_id IS NOT NULL)
         THEN
            line_attr_rec.line_index   := n;
            line_attr_rec.pricing_context := 'ITEM';
            line_attr_rec.pricing_attribute := 'PRICING_ATTRIBUTE2';
            line_attr_rec.pricing_attr_value_from := l_category_id;
            line_attr_rec.validated_flag := 'N';
            j                          := j + 1;
            p_line_attr_tbl (j)        := line_attr_rec;
         END IF;

         line_attr_rec.line_index   := n;                                                                          -- 1;
         line_attr_rec.pricing_context := 'ITEM';                                                                      --
         line_attr_rec.pricing_attribute := 'PRICING_ATTRIBUTE3';
         line_attr_rec.pricing_attr_value_from := 'ALL';
         line_attr_rec.validated_flag := 'N';
         j                          := j + 1;
         p_line_attr_tbl (j)        := line_attr_rec;
         log_message ('Building the Attributes...');
         p_qual_tbl.DELETE;                                                              ---- Qualifier Attribute Record

         IF (l_price_list_id IS NOT NULL)
         THEN
            qual_rec.line_index        := n;
            -- 1; -- Attributes for the above line. Attributes are attached with the line index
            qual_rec.qualifier_context := 'MODLIST';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE4';
            qual_rec.qualifier_attr_value_from := l_price_list_id;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (1)             := qual_rec;
         END IF;

         IF (l_bill_to_site_id IS NOT NULL)
         THEN
            qual_rec.line_index        := n;                                                                      -- 1;
            qual_rec.qualifier_context := 'CUSTOMER';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE14';
            qual_rec.qualifier_attr_value_from := l_bill_to_site_id;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (2)             := qual_rec;
         END IF;

         IF (l_ship_to_site_id IS NOT NULL)
         THEN
            qual_rec.line_index        := n;                                                                      -- 1;
            qual_rec.qualifier_context := 'CUSTOMER';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE11';
            qual_rec.qualifier_attr_value_from := l_ship_to_site_id;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (3)             := qual_rec;
         END IF;

         IF (l_party_site_id IS NOT NULL)
         THEN
            qual_rec.line_index        := 1;
            qual_rec.qualifier_context := 'CUSTOMER';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE17';
            qual_rec.qualifier_attr_value_from := l_party_site_id;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (4)             := qual_rec;
         END IF;


         IF (l_customer_id IS NOT NULL)
         THEN
            qual_rec.line_index        := n;                                                                      -- 1;
            qual_rec.qualifier_context := 'CUSTOMER';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE2';
            qual_rec.qualifier_attr_value_from := l_customer_id;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (5)             := qual_rec;
         END IF;

         IF (l_sales_channel_code IS NOT NULL)
         THEN
            qual_rec.line_index        := n;                                                                      -- 1;
            qual_rec.qualifier_context := 'CUSTOMER';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE13';
            qual_rec.qualifier_attr_value_from := l_sales_channel_code;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (6)             := qual_rec;
         END IF;

         IF (l_customer_class_code IS NOT NULL)
         THEN
            qual_rec.line_index        := n;                                                                      -- 1;
            qual_rec.qualifier_context := 'CUSTOMER';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE1';
            qual_rec.qualifier_attr_value_from := l_customer_class_code;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (7)             := qual_rec;
         END IF;

         IF (l_sales_organization IS NOT NULL)
         THEN
            qual_rec.line_index        := n;                                                                      -- 1;
            qual_rec.qualifier_context := 'PARTY';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE3';
            qual_rec.qualifier_attr_value_from := l_sales_organization;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (8)             := qual_rec;
         END IF;


  /* Code change by K Ayalavarapu on 5/22 to introduce ship to cust no qualifier starts here */
        IF ( l_account_number is not null )  and (l_customer_id IS NOT NULL) then
            select cust_account_id into l_ship_to_cust_acct_id from hz_cust_accounts where account_number=l_account_number;
            if (l_customer_id <>l_ship_to_cust_acct_id) then  -- if Bill to account and ship to account are different pass in the ship to acct  qualifier
                 qual_rec.line_index        := n;                                                                      -- 1;
            qual_rec.qualifier_context := 'SHIP_TO_CUST';
            qual_rec.qualifier_attribute := 'QUALIFIER_ATTRIBUTE40';
            qual_rec.qualifier_attr_value_from := l_ship_to_cust_acct_id;
            qual_rec.comparison_operator_code := '=';
            qual_rec.validated_flag    := 'Y';
            p_qual_tbl (9)             := qual_rec;
            end if;
        end if;
        /* Code change by K Ayalavarapu on 5/22 to introduce ship to cust no qualifier ends here */



         --  END LOOP;     -- 02/25 Jag -- Commented so that for each product will make individual pricing call. --

         -- 02/25 Jagdish: Initialize output tables to release leftovers.
         x_line_tbl.DELETE;
         x_line_qual.DELETE;
         x_line_attr_tbl.DELETE;
         x_line_detail_tbl.DELETE;
         x_line_detail_qual_tbl.DELETE;
         x_line_detail_attr_tbl.DELETE;
         x_related_lines_tbl.DELETE;

         -- Addl Comments by Krishna Ayalavarapu starts here
         log_message ('Calling the Price Request with parameters...');
         log_message ('Parameters : p_party_site_number     ' || p_party_site_number);
         log_message ('Parameters : l_account_number        ' || l_account_number);
         log_message ('Parameters : l_ship_to_cust_acct_id     ' || l_ship_to_cust_acct_id);
         log_message ('Parameters : cust account id         ' || l_customer_id);
         log_message ('Parameters : Customer classification ' || l_customer_class_code);
         log_message ('Parameters : l_sales_organization    ' || l_sales_organization);
         log_message ('Parameters : l_sales_channel_code    ' || l_sales_channel_code);
         log_message ('Parameters : l_party_site_id         ' || l_party_site_id);
         log_message ('Parameters : l_bill_to_site_id       ' || l_bill_to_site_id);
         log_message ('Parameters : l_ship_to_site_id       ' || l_ship_to_site_id);
         log_message ('Parameters : l_category_id           ' || l_category_id);
         log_message ('Parameters : l_price_list_id         ' || l_price_list_id);
         log_message ('Parameters : l_inventory_item_id     ' || l_inventory_item_id);
         log_message ('Parameters : l_dcode     ' || l_dcode);
         log_message ('Parameters : l_currency_code         ' || l_currency_code);
         log_message ('Parameters : l_primary_uom_code      ' || l_primary_uom_code);
         log_message ('Parameters : l_item_quantity         ' || l_item_quantity);
         --log_message ('Parameters : l_ship_to_site_id       ' || l_ship_to_site_id);
         -- Addl Comments by Krishna Ayalavarapu ends here

         log_message ('Input Item to API Count ' || p_line_tbl.COUNT);
         qp_preq_pub.price_request (p_line_tbl,
                                    p_qual_tbl,
                                    p_line_attr_tbl,
                                    p_line_detail_tbl,
                                    p_line_detail_qual_tbl,
                                    p_line_detail_attr_tbl,
                                    p_related_lines_tbl,
                                    p_control_rec,
                                    x_line_tbl,
                                    x_line_qual,
                                    x_line_attr_tbl,
                                    x_line_detail_tbl,
                                    x_line_detail_qual_tbl,
                                    x_line_detail_attr_tbl,
                                    x_related_lines_tbl,
                                    x_return_status,
                                    x_return_status_text
                                   );

      -- Return Status Information ..
--      log_message ('Price List ID ' || l_price_list_id);
--      log_message ('Return Status text ' || x_return_status_text);
--      log_message ('Return Status  ' || x_return_status);
         IF (x_return_status <> fnd_api.g_ret_sts_success)
         THEN
            l_msg_data                 := 'PRICE_REQUEST: ' || x_return_status_text;
            RAISE price_not_found;
         END IF;

--      log_message ('+---------Information Returned to Caller---------------------+ ');
--      log_message ('-------------Request Line Information-------------------');
         i                          := x_line_tbl.FIRST;
         log_message ('************I: ' || i);
         log_message ('************LAST: ' || x_line_tbl.LAST);
         log_message ('Number of rec in Line Out ' || l_part_number || ' ' || x_line_tbl.COUNT);

         IF i IS NOT NULL
         THEN
            LOOP
               log_message ('****Line Index 1: ' || x_line_tbl (i).line_index);
               log_message ('****Unit_price 1: ' || x_line_tbl (i).unit_price);
               log_message ('Line Index: ' || x_line_tbl (i).line_index);
               log_message ('Unit_price: ' || x_line_tbl (i).unit_price);
               log_message ('Number of rec in Line Out ' || x_line_tbl.COUNT);
               log_message ('Percent price: ' || x_line_tbl (i).percent_price);
               log_message ('Adjusted Unit Price: ' || x_line_tbl (i).adjusted_unit_price);
               l_adjusted_price           := l_adjusted_price + x_line_tbl (i).adjusted_unit_price;
               l_adjusted_price_t.EXTEND;
               l_adjusted_price_t (l_adjusted_price_t.COUNT) := intg_t_adjusted_price (l_adjusted_price);
               -- log_message ('Pricing status code: ' || x_line_tbl (i).status_code);
               -- log_message ('Pricing status text: ' || x_line_tbl (i).status_text);
               l_adjusted_price           := 0;

               IF (x_line_tbl (i).status_code = fnd_api.g_ret_sts_error)
               THEN
                  l_msg_data                 := 'REQUEST_LINE: ' || x_line_tbl (i).status_text;
                  RAISE price_not_found;
               END IF;

               EXIT WHEN i = x_line_tbl.LAST;
               i                          := x_line_tbl.NEXT (i);
            END LOOP;
         END IF;

--      log_message ('-----------Pricing Attributes Information-------------');
         i                          := x_line_detail_attr_tbl.FIRST;

         IF i IS NOT NULL
         THEN
            LOOP
               --  log_message ('Line detail Index ' || x_line_detail_attr_tbl (i).line_detail_index);
               --  log_message ('Context ' || x_line_detail_attr_tbl (i).pricing_context);
               --  log_message ('Attribute ' || x_line_detail_attr_tbl (i).pricing_attribute);
               --  log_message ('Value ' || x_line_detail_attr_tbl (i).pricing_attr_value_from);
               --  log_message ('Status Code ' || x_line_detail_attr_tbl (i).status_code);
               --  log_message ('Status Text ' || x_line_detail_attr_tbl (i).status_text);
               --  log_message ('---------------------------------------------------');
               IF (x_line_detail_attr_tbl (i).status_code = fnd_api.g_ret_sts_error)
               THEN
                  l_msg_data                 := 'LINE_DETAIL: ' || x_line_detail_attr_tbl (i).status_text;
                  RAISE price_not_found;
               END IF;

               EXIT WHEN i = x_line_detail_attr_tbl.LAST;
               i                          := x_line_detail_attr_tbl.NEXT (i);
            END LOOP;
         END IF;

--      log_message ('-----------Qualifier Attributes Information-------------');
         i                          := x_line_detail_qual_tbl.FIRST;

         IF i IS NOT NULL
         THEN
            LOOP
                         /*  log_message ('Line Detail Index ' || x_line_detail_qual_tbl (i).line_detail_index);
                           log_message ('Context ' || x_line_detail_qual_tbl (i).qualifier_context);
                           log_message ('Attribute ' || x_line_detail_qual_tbl (i).qualifier_attribute);
                           log_message ('Value ' || x_line_detail_qual_tbl (i).qualifier_attr_value_from);
                           log_message ('Status Code ' || x_line_detail_qual_tbl (i).status_code);
                           log_message ('Status Text ' || x_line_detail_qual_tbl (i).status_text);
                           log_message ('---------------------------------------------------');
               */
               IF (x_line_detail_qual_tbl (i).status_code = fnd_api.g_ret_sts_error)
               THEN
                  l_msg_data                 := 'QUAL ATTR: ' || x_line_detail_qual_tbl (i).status_text;
                  RAISE price_not_found;
               END IF;

               EXIT WHEN i = x_line_detail_qual_tbl.LAST;
               i                          := x_line_detail_qual_tbl.NEXT (i);
            END LOOP;
         END IF;

--      log_message ('------------Price List/Discount Information------------');
         i                          := x_line_detail_tbl.FIRST;

         IF i IS NOT NULL
         THEN
            LOOP
               /*
                log_message ('Line Index: ' || x_line_detail_tbl (i).line_index);
                log_message ('Line Detail Index: ' || x_line_detail_tbl (i).line_detail_index);
                log_message ('Line Detail Type:' || x_line_detail_tbl (i).line_detail_type_code);
                log_message ('List Header Id: ' || x_line_detail_tbl (i).list_header_id);
                log_message ('List Line Id: ' || x_line_detail_tbl (i).list_line_id);
                log_message ('List Line Type Code: ' || x_line_detail_tbl (i).list_line_type_code);
                log_message ('Adjustment Amount : ' || x_line_detail_tbl (i).adjustment_amount);
                log_message ('Line Quantity : ' || x_line_detail_tbl (i).line_quantity);
                log_message ('Operand Calculation Code: ' || x_line_detail_tbl (i).operand_calculation_code);
                log_message ('Operand value: ' || x_line_detail_tbl (i).operand_value);
                log_message ('Automatic Flag: ' || x_line_detail_tbl (i).automatic_flag);
                log_message ('Override Flag: ' || x_line_detail_tbl (i).override_flag);
                log_message ('status_code: ' || x_line_detail_tbl (i).status_code);
                log_message ('status text: ' || x_line_detail_tbl (i).status_text);
                log_message ('-------------------------------------------');
                */
               IF (x_line_detail_tbl (i).status_code = fnd_api.g_ret_sts_error)
               THEN
                  l_msg_data                 := 'DISCOUNT INFO: ' || x_line_detail_tbl (i).status_text;
                  RAISE price_not_found;
               END IF;

               EXIT WHEN i = x_line_detail_tbl.LAST;
               i                          := x_line_detail_tbl.NEXT (i);
            END LOOP;
         END IF;

--      log_message ('--------------Related Lines Information for Price Breaks/Service Items---------------');
         i                          := x_related_lines_tbl.FIRST;

         IF i IS NOT NULL
         THEN
            LOOP
                          /* log_message ('Line Index :' || x_related_lines_tbl (i).line_index);
                           log_message ('Line Detail Index: ' || x_related_lines_tbl (i).line_detail_index);
                           log_message ('Relationship Type Code: ' || x_related_lines_tbl (i).relationship_type_code);
                           log_message ('Related Line Index: ' || x_related_lines_tbl (i).related_line_index);
                           log_message ('Related Line Detail Index: ' || x_related_lines_tbl (i).related_line_detail_index);
                           log_message ('Status Code: ' || x_related_lines_tbl (i).status_code);
                           log_message ('Status Text: ' || x_related_lines_tbl (i).status_text);
               */
               IF (x_related_lines_tbl (i).status_code = fnd_api.g_ret_sts_error)
               THEN
                  l_msg_data                 := 'RELATED LINES: ' || x_related_lines_tbl (i).status_text;
                  RAISE price_not_found;
               END IF;

               EXIT WHEN i = x_related_lines_tbl.LAST;
               i                          := x_related_lines_tbl.NEXT (i);
            END LOOP;
         END IF;

         i                          := l_pricing_contexts_tbl.FIRST;
         log_message ('Logging the context information for '||p_party_site_number);
         IF i IS NOT NULL
         THEN
            LOOP
                 log_message ('-----Next Pricing Context-----');
                 log_message ('Context Name    : ' || l_pricing_contexts_tbl (i).context_name);
                 log_message ('Attribute Name  : ' || l_pricing_contexts_tbl (i).attribute_name);
                 log_message ('Attribute Value : ' || l_pricing_contexts_tbl (i).attribute_value);
               EXIT WHEN i = l_pricing_contexts_tbl.LAST;
               i                          := l_pricing_contexts_tbl.NEXT (i);
            END LOOP;
         END IF;

         i                          := l_qualifier_contexts_tbl.FIRST;

         IF i IS NOT NULL
         THEN
            LOOP
                 log_message ('----Next Qualifier Context----');
                 log_message ('Context Name    : ' || l_qualifier_contexts_tbl (i).context_name);
                 log_message ('Attribute Name  : ' || l_qualifier_contexts_tbl (i).attribute_name);
                 log_message ('Attribute Value : ' || l_qualifier_contexts_tbl (i).attribute_value);
               EXIT WHEN i = l_qualifier_contexts_tbl.LAST;
               i                          := l_qualifier_contexts_tbl.NEXT (i);
            END LOOP;
         END IF;

--- Jag End --
         IF (l_adjusted_price IS NULL)
         THEN
            RAISE price_not_found;
         END IF;

         --END LOOP;

         --NEW procedure passes back the line_rec.
         --XML assembly is relegated to the wrapper procedure Get_Item_Pricing_XML
         x_pricing_tbl (n) := x_line_tbl (x_line_tbl.FIRST);
      END LOOP; --Looping throug incoming product records.

      x_return_status            := 'S';
      x_msg_data                 := 'Successfully constructed Item Pricing';
   EXCEPTION
      WHEN price_not_found
      THEN
         x_return_status            := 'E';
         x_msg_data                 :=
               'Error (price_not_found) while generating the XML pricing output for the part number '
            || l_part_number
            || ' due to: '
            || l_msg_data;
      WHEN OTHERS
      THEN
         x_return_status            := 'E';
         x_msg_data                 :=
               'Error (Others) while generating the XML pricing output for the part number '
            || l_part_number
            || ' due to : '
            || SQLERRM;
   END get_item_pricing;

   PROCEDURE get_item_availability_xml (
      p_country                 IN              VARCHAR2,
      p_account_number          IN              VARCHAR2,
      -- p_part_number      IN VARCHAR2,
      -- p_item_quantity    IN NUMBER,
      -- p_primary_uom_code IN OUT NOCOPY VARCHAR2,
      p_product_info            IN              xxintg_t_product_t,
      x_item_availability_xml   IN OUT NOCOPY   XMLTYPE,
      x_return_status           IN OUT NOCOPY   VARCHAR2,
      x_return_code             IN OUT          VARCHAR2,
      x_msg_data                IN OUT NOCOPY   VARCHAR2
   )
   IS
      availability_not_found   EXCEPTION;
      l_part_number            VARCHAR2 (30);
      l_product_info           xxintg_t_product_t;
      l_item_quantity          NUMBER;
      l_inventory_item_id      NUMBER;
      l_organization_code      VARCHAR2 (10)                                     := '150';
      l_primary_uom_code       mtl_system_items_b.primary_uom_code%TYPE;
      l_uom_conversion_rate    NUMBER;
      l_return_status          VARCHAR2 (200);
      l_msg_data               VARCHAR2 (200);
      l_msg_count              NUMBER;
      l_org_id                 NUMBER;
      l_operating_unit         NUMBER                                            := 82;
      l_customer_id            NUMBER;
      l_customer_site_id       NUMBER;
      l_lot_control            BOOLEAN                                           := FALSE;
      l_serial_control         BOOLEAN                                           := FALSE;
      l_category_id            NUMBER;
      l_business_unit          VARCHAR2 (40);
      l_product_brand          VARCHAR2 (40);
      l_product_segment        VARCHAR2 (40);
      l_product_class          VARCHAR2 (40);
      l_product_type           VARCHAR2 (40);
      x_qoh                    NUMBER;
      x_rqoh                   NUMBER;
      x_qr                     NUMBER;
      x_qs                     NUMBER;
      x_att                    NUMBER;
      x_atr                    NUMBER;
      x_sqoh                   NUMBER;
      x_srqoh                  NUMBER;
      x_sqr                    NUMBER;
      x_sqs                    NUMBER;
      x_satt                   NUMBER;
      x_sqtr                   NUMBER;
      x_msg_count              NUMBER;
      l_source_orgs_table      apps.oe_oe_pricing_availability.source_orgs_table;
   BEGIN
      -- Right now just get the first element.  We'll loop through later
      l_product_info             := xxintg_t_product_t ();
      l_product_info             := p_product_info;
      l_part_number              := l_product_info (1).item;
      l_primary_uom_code         := l_product_info (1).uom;
      l_item_quantity            := l_product_info (1).quantity;
      log_message ('l_part_number:' || l_part_number);
      log_message ('l_org_code:' || l_organization_code);
      -- Find the inventory_item_id and primary_uom_code
      -- based on the passed in item for use in queries and API calls
      -- add serial_control and lot_control
      get_item_information (p_part_number              => l_part_number,
                            p_organization_code        => l_organization_code,
                            x_inventory_item_id        => l_inventory_item_id,
                            x_primary_uom_code         => l_primary_uom_code,
                            x_uom_conversion_rate      => l_uom_conversion_rate,
                            x_lot_control              => l_lot_control,
                            x_serial_control           => l_serial_control,
                            x_category_id              => l_category_id,
                            x_business_unit            => l_business_unit,
                            x_product_segment          => l_product_segment,
                            x_product_brand            => l_product_brand,
                            x_product_class            => l_product_class,
                            x_product_type             => l_product_type,
                            x_return_status            => l_return_status,
                            x_msg_data                 => l_msg_data
                           );

      IF (l_return_status = 'E')
      THEN
         l_msg_data                 := 'ITEM_INFO: ' || l_msg_data;
         RAISE availability_not_found;
      END IF;

      -- Get the customer Ship To information
      BEGIN
         SELECT hca.cust_account_id,
                hcsu.site_use_id
           INTO l_customer_id,
                l_customer_site_id
           FROM hz_party_sites hps,
                hz_locations l,
                hz_cust_acct_sites_all hcas,
                hz_cust_site_uses_all hcsu,
                hz_cust_accounts hca
          WHERE hps.location_id = l.location_id
            AND hps.party_site_id = hcas.party_site_id
            AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
            AND hcsu.primary_flag = 'Y'
            AND hcsu.site_use_code = 'SHIP_TO'
            AND hcas.status = 'A'
            AND hcsu.status = 'A'
            AND hcsu.org_id = l_operating_unit
            AND hca.party_id = hps.party_id
            AND hca.account_number = TO_CHAR (p_account_number);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data                 := 'No Active Primary Ship To Found.';
            log_message (l_msg_data);
            RAISE availability_not_found;
      END;

      log_message ('Got Customer.');
      oe_oe_pricing_availability.get_global_availability (in_customer_id            => l_customer_id,
                                                          in_customer_site_id       => l_customer_site_id,
                                                          in_inventory_item_id      => l_inventory_item_id,
                                                          in_org_id                 => l_org_id,
                                                          x_return_status           => l_return_status,
                                                          x_msg_data                => l_msg_data,
                                                          x_msg_count               => l_msg_count,
                                                          l_source_orgs_table       => l_source_orgs_table
                                                         );

      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN
         l_msg_data                 := 'GET_GLOBAL_AVAILABILITY: ' || l_msg_data;
         RAISE availability_not_found;
      END IF;

      log_message ('Got Warehouse: ' || l_source_orgs_table (1).org_id);
      -- Look up the available quantity for the primary unit of measure (UOM)
      inv_globals.set_org_id (l_operating_unit);
      inv_quantity_tree_pub.clear_quantity_cache;
      inv_quantity_tree_pub.query_quantities (p_api_version_number       => 1.0,
                                              x_return_status            => l_return_status,
                                              x_msg_count                => x_msg_count,
                                              x_msg_data                 => l_msg_data,
                                              p_organization_id          => l_source_orgs_table (1).org_id,
                                              p_inventory_item_id        => l_inventory_item_id,
                                              p_tree_mode                => 1,
                                              p_is_revision_control      => FALSE,
                                              p_is_lot_control           => l_lot_control,
                                              p_is_serial_control        => l_serial_control,
                                              p_grade_code               => NULL,
                                              p_revision                 => NULL,
                                              p_lot_number               => NULL,
                                              p_subinventory_code        => NULL,
                                              p_locator_id               => NULL,
                                              x_qoh                      => x_qoh,                            -- on hand
                                              x_rqoh                     => x_rqoh,
                                              x_qr                       => x_qr,
                                              x_qs                       => x_qs,
                                              x_att                      => x_att,
                                              x_atr                      => x_atr,               -- available to reserve
                                              x_sqoh                     => x_sqoh,
                                              x_srqoh                    => x_srqoh,
                                              x_sqr                      => x_sqr,
                                              x_sqs                      => x_sqs,
                                              x_satt                     => x_satt,
                                              x_satr                     => x_sqtr
                                             );

      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN
         l_msg_data                 := 'QUERY QUANTITY: ' || l_msg_data;
         RAISE availability_not_found;
      END IF;

      SELECT XMLELEMENT ("FetchAvailabilityInfoResponse",
                         XMLELEMENT ("PartNumber", l_part_number),
                         XMLELEMENT ("AvailabilityInfo",
                                     XMLELEMENT ("QUANTITY_AVAILABLE", TO_CHAR (x_atr)),
                                     XMLELEMENT ("UOM", l_primary_uom_code)
                                    )
                        )
        INTO x_item_availability_xml
        FROM DUAL;

      /*
        SELECT XMLELEMENT("ITEM_PRICING_XML", XMLELEMENT("PartNumber", l_part_number), XMLELEMENT("AvailabilityInfo", XMLELEMENT("QUANTITY_AVAILABLE", TO_CHAR(x_atr)), XMLELEMENT("UOM", l_primary_uom_code) ) )
      INTO x_item_availability_xml
      FROM DUAL;
      */
      x_return_status            := fnd_api.g_ret_sts_success;
      x_msg_data                 := 'Successfully constructed Item Availability XML';
   EXCEPTION
      WHEN availability_not_found
      THEN
         x_return_status            := 'E';
         x_msg_data                 :=
               'Error while generating the XML availability output for the part number '
            || l_part_number
            || ' due to : '
            || l_msg_data;
         NULL;
      WHEN OTHERS
      THEN
         x_return_status            := 'E';
         x_msg_data                 :=
               'Error while generating the XML availability output for the part number '
            || l_part_number
            || ' due to : '
            || SQLERRM;
   END get_item_availability_xml;
END xxom_prcng_avail_pkg;
/
