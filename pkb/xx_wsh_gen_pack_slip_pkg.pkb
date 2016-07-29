DROP PACKAGE BODY APPS.XX_WSH_GEN_PACK_SLIP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_WSH_GEN_PACK_SLIP_PKG" 
  ----------------------------------------------------------------------
  /* $Header: XXWSHGENERATEPACKSLIPNO.pks 1.0 2012/07/09 12:00:00 $ */
  /*
  Created By     : IBM Development Team
  Creation Date  : 09-Jul-2012
  File Name      : XXWSHGENERATEPACKSLIPNO.pkb
  Description    : This package generates the package slip number and submit the
  INTG Pack Slip Report
  Change History:
  Version Date        Name                    Remarks
  ------- ----------- ----                    ----------------------
  1.0     09-Jul-12   IBM Development Team    Initial development.
  2.0     11-Apr-13   IBM Development Team    Changes made for new RICE ID O2C-RPT_009_W0
  2.1     21-Jan-14   IBM Development Team    Change in the language query
  3.0     13-Oct-14   IBM Development Team    Different templates for different OU(O2C_RPT_009_W2)
  */
  /*----------------------------------------------------------------------*/
AS
FUNCTION get_report_language(
    p_delivery_id IN NUMBER)
  RETURN VARCHAR2
AS
  CURSOR c_get_language (p_delivery_id IN VARCHAR2)
  IS
    --Cursor to fetch language, if null then English
    SELECT NVL (ship_loc.LANGUAGE, 'US') lang_print
    FROM apps.oe_order_headers_all ooha,
      Apps.Hz_Cust_Site_Uses_All Ship_Su,
      apps.hz_party_sites ship_ps,
      apps.hz_locations ship_loc,
      Apps.Hz_Cust_Acct_Sites_All Ship_Cas,
      Apps.Wsh_New_Deliveries Wnd,
      Apps.Wsh_Delivery_Details Wdd,
      apps.wsh_delivery_assignments wda
    WHERE ooha.ship_to_org_id     = ship_su.site_use_id(+)
    AND ship_su.cust_acct_site_id = ship_cas.cust_acct_site_id(+)
    AND Ship_Cas.Party_Site_Id    = Ship_Ps.Party_Site_Id(+)
    AND Ship_Loc.Location_Id(+)   = Ship_Ps.Location_Id
      --And Ooha.Header_Id = Wnd.Source_Header_Id
    AND Ooha.Order_Number      = Wdd.Source_Header_Number
    AND wda.delivery_id        = wnd.delivery_id
    AND wda.delivery_detail_id = wdd.delivery_detail_id
    AND wnd.delivery_id        = p_delivery_id;
  x_language hz_locations.LANGUAGE%TYPE;
BEGIN
  --Fetch language
  OPEN c_get_language (p_delivery_id);
  FETCH c_get_language INTO x_language;
  CLOSE c_get_language;
  RETURN x_language;
EXCEPTION
WHEN OTHERS THEN
  x_language := 'US';
  fnd_file.put_line (fnd_file.LOG, 'Error fetching Customer Account Site Language for the delivery ' || p_delivery_id );
END;
PROCEDURE generate_pack_slip_no(
    o_retcode OUT VARCHAR2,
    o_errbuf OUT VARCHAR2,
    p_organization_id    IN NUMBER,
    p_delivery_id        IN NUMBER,
    p_print_cust_item    IN VARCHAR2,
    p_item_display       IN VARCHAR2,
    p_print_mode         IN VARCHAR2,
    p_sort               IN VARCHAR2,
    p_delivery_date_low  IN VARCHAR2,
    p_delivery_date_high IN VARCHAR2,
    p_freight_code       IN VARCHAR2,
    p_quantity_precision IN VARCHAR2,
    p_display_unshipped  IN VARCHAR2,
    p_print_pending      IN VARCHAR2,
    --added for new RICE ID O2C-RPT_009_W0
    p_output_format IN VARCHAR2 ) --added for new RICE ID O2C-RPT_009_W0
AS
  CURSOR get_all_delivery
  IS
    SELECT del.delivery_id
    FROM wsh_new_deliveries del
    WHERE 1                                = 1
    AND del.organization_id                = p_organization_id
    AND del.delivery_id                    = NVL (p_delivery_id, del.delivery_id)
    AND del.delivery_type                  = 'STANDARD'
    AND NVL (del.shipment_direction, 'O') IN ('O', 'IO')
    AND del.status_code                   != 'CA'
    AND EXISTS
      (SELECT 1
      FROM wsh_delivery_assignments wda
      WHERE wda.delivery_id = del.delivery_id
      )
  AND NVL (del.confirm_date, SYSDATE) BETWEEN NVL (fnd_date.canonical_to_date (p_delivery_date_low), NVL (del.confirm_date, (SYSDATE - 1)) ) AND NVL (( fnd_date.canonical_to_date (p_delivery_date_high) + (86399 / 86400) ), NVL (del.confirm_date, (SYSDATE + 1)) )
  ORDER BY delivery_id;
  x_pack_sl_no     VARCHAR2 (20);
  x_conc_req_id    NUMBER (10);
  x_return_status  VARCHAR2 (200);
  x_msg_count      NUMBER;
  x_msg_data       VARCHAR2 (500);
  x_doc_no         VARCHAR2 (100);
  x_ledger_id      NUMBER;
  x_add_layout     BOOLEAN;
  x_application_id NUMBER;
  x_submit_flag    BOOLEAN;
  x_tmpl_code      VARCHAR2(100);                                -- O2C-RPT_009_W2
  x_language_code  hz_locations.LANGUAGE%TYPE;
  hou_name         hr_operating_units.name%TYPE;                 -- O2C-RPT_009_W2
  x_language       fnd_languages.iso_language%TYPE   := 'en';
  x_territory      fnd_languages.iso_territory%TYPE := 'US';
BEGIN
  -- Get the Ledger ID
  SELECT set_of_books_id
  INTO x_ledger_id
  FROM org_organization_definitions
  WHERE organization_id = p_organization_id;
  -- Get the Application ID of the Document Category
  SELECT application_id
  INTO x_application_id
  FROM wsh_doc_sequence_categories_v
  WHERE document_type = 'PACK_TYPE';
  FOR delivery       IN get_all_delivery
  LOOP
    x_pack_sl_no  := NULL;
    x_conc_req_id := NULL;
    x_submit_flag := TRUE;
    fnd_file.put_line (fnd_file.LOG, '---------------------------------------------------------' );
    fnd_file.put_line (fnd_file.LOG, 'Processing Delivery : ' || delivery.delivery_id );
    -- Check whether package slip number already exists
    BEGIN
      SELECT sequence_number
      INTO x_pack_sl_no
      FROM wsh_document_instances
      WHERE entity_id   = delivery.delivery_id
      AND document_type = 'PACK_TYPE';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL; -- Do Nothing
    WHEN OTHERS THEN
      o_retcode := '1';
      fnd_file.put_line (fnd_file.LOG, 'Error fetching Packing Slip Number ' );
      fnd_file.put_line (fnd_file.LOG, SQLERRM);
    END;
    IF (x_pack_sl_no IS NULL) THEN
      BEGIN
        wsh_document_pvt.create_document (p_api_version => 1.0, p_commit => fnd_api.g_true, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data => x_msg_data, p_entity_name => 'WSH_NEW_DELIVERIES', p_entity_id => delivery.delivery_id, p_application_id => x_application_id, p_location_id => NULL, p_document_type => 'PACK_TYPE', p_document_sub_type => NULL, p_ledger_id => x_ledger_id, x_document_number => x_doc_no );
        IF (x_return_status = 'S') THEN
          fnd_file.put_line (fnd_file.LOG, 'Generated Pack Slip Number : ' || x_doc_no );
        ELSE
          fnd_file.put_line (fnd_file.LOG, 'Error msg from API : ' || x_msg_data );
          o_retcode     := '1';
          x_submit_flag := FALSE;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        o_retcode     := '1';
        x_submit_flag := FALSE;
        fnd_file.put_line (fnd_file.LOG, 'Error generating Packing Slip Number' );
        fnd_file.put_line (fnd_file.LOG, SQLERRM);
      END;
    END IF;
    --Added for new RICE ID O2C-RPT_009_W0
    x_language_code := get_report_language (p_delivery_id);
    BEGIN
      SELECT LOWER (iso_language),
        iso_territory
      INTO x_language,
        x_territory
      FROM fnd_languages
      WHERE UPPER (language_code) = UPPER (x_language_code);
    EXCEPTION
    WHEN OTHERS THEN
      o_retcode     := '1';
      x_submit_flag := FALSE;
      fnd_file.put_line (fnd_file.LOG, 'Error determining user environment language and territory' );
      fnd_file.put_line (fnd_file.LOG, SQLERRM);
    END;
    --Addition ends for new RICE ID O2C-RPT_009_W0
    -- Submit INTG Pack Slip Report for this delivery
    IF (x_submit_flag) THEN
      BEGIN
        --Commented out for new RICE ID O2C-RPT_009_W0
        /*x_add_layout :=
        fnd_request.add_layout (
        template_appl_name   => 'XXINTG',
        template_code        => 'XX_WSH_PACK_SLIP_RPT_TEMP',
        template_language    => 'EN',
        template_territory   => 'US',
        output_format        => 'PDF'
        );*/
        --Comment ends
        -- Start of O2C-RPT_009_W2 (WAVE 2 changes)
                BEGIN
                      SELECT hou.name
                        INTO hou_name
                        FROM hr_operating_units hou
                            ,org_organization_definitions ood
                       WHERE ood.operating_unit  = hou.organization_id
                         AND ood.organization_id = p_organization_id;
                EXCEPTION
                   WHEN others THEN
                        hou_name := 'OU United States';
                        fnd_file.put_line (fnd_file.LOG, 'Error determining name of the operating unit - picked "OU United States"' );
                END;
                BEGIN
                   SELECT xx_intg_common_pkg.get_ou_specific_templ(hou_name,'XX_WSH_PACK_SLIP_RPT')
                     INTO x_tmpl_code
                     FROM dual;
                EXCEPTION
                   WHEN others THEN
                        x_tmpl_code := 'XX_WSH_PACK_SLIP_RPT_TEMP';
                END;
        -- End of O2C-RPT_009_W2 (WAVE 2 changes)
                --Added for new RICE ID O2C-RPT_009_W0
        x_add_layout := fnd_request.add_layout (template_appl_name => 'XXINTG', template_code => x_tmpl_code, template_language => x_language, template_territory => x_territory, output_format => p_output_format );
        --Addition ends
        x_conc_req_id := fnd_request.submit_request (application => 'XXINTG', program => 'XX_WSH_PACK_SLIP_RPT', description => NULL, start_time => NULL, sub_request => NULL, argument1 => p_organization_id, argument2 => delivery.delivery_id, argument3 => p_print_cust_item, argument4 => p_item_display, argument5 => p_print_mode, argument6 => p_sort, argument7 => p_delivery_date_low, argument8 => p_delivery_date_high, argument9 => p_freight_code, argument10 => p_quantity_precision, argument11 => p_display_unshipped, argument12 => p_print_pending,
        --added for new RICE ID O2C-RPT_009_W0
        argument13 => p_output_format
        --added for new RICE ID O2C-RPT_009_W0
        );
        fnd_file.put_line (fnd_file.LOG, 'Pack Slip Report Request submitted with Req Id : ' || x_conc_req_id );
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.LOG, 'Error submitting Pack Slip Report' || x_conc_req_id );
        fnd_file.put_line (fnd_file.LOG, SQLERRM);
        o_retcode := '1';
      END;
    END IF;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  o_retcode := '1';
  fnd_file.put_line (fnd_file.LOG, 'Unexpected Error ');
  fnd_file.put_line (fnd_file.LOG, SQLERRM);
END generate_pack_slip_no;
END xx_wsh_gen_pack_slip_pkg;
/
