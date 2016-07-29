DROP PACKAGE BODY APPS.XX_O2C_DOCTOR_CERT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_O2C_DOCTOR_CERT_PKG" IS
  /* $Header: XXO2CDOCTORCERTPKG.pkb 1.0.0 2013/03/29 700:00:00 riqbal noship $ */
  --------------------------------------------------------------------------------
  /*
  Created By     : Raquib Iqbal
  Creation Date  : 29-Mar-2013
  Filename       : XXO2CDOCTORCERTPKG.pkb
  Description    : This package is used to validate the order line eligibility and to apply hold using seeded API

  Change History:

  Date        Version#    Name                Remarks
  ----------- --------    ---------------     -----------------------------------
  29-Mar-2013   1.0       Raquib Iqbal        Initial development.

  */
  --------------------------------------------------------------------------------
  -------------------------------------------------------------------------------  /*

  --**********************************************************************
  ----Procedure to set environment.
  --**********************************************************************
  PROCEDURE set_cnv_env(p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes) IS
    x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
  BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_low, 'Inside set_cnv_env...');
    -- Set the environment
    x_error_code := xx_emf_pkg.set_env(p_process_name => 'XXOEDOCCERT');

    IF NVL(p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no THEN
      xx_emf_pkg.propagate_error(x_error_code);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE xx_emf_pkg.g_e_env_not_set;
  END set_cnv_env;

  FUNCTION xx_val_ord_line_eligibility(p_item_id         IN NUMBER,
                                       p_organization_id IN NUMBER)
    RETURN VARCHAR2 is
    --x_segment4   mtl_categories_b.segment4%TYPE;
    x_count number;
  BEGIN
    --Get the Segment4
    /*SELECT NVL (mc.segment4, 'XXX')
      INTO x_segment4
      FROM mtl_category_sets mcs,
           mtl_item_categories mic,
           mtl_categories_b mc
     WHERE mcs.category_set_name = 'Inventory'
       AND mcs.category_set_id = mic.category_set_id
       AND mic.inventory_item_id = p_item_id
       AND mic.organization_id = p_organization_id
       AND mc.category_id = mic.category_id
       AND mc.enabled_flag = 'Y'
       AND NVL (mc.disable_date, SYSDATE + 1) > SYSDATE;

    --Get the description for segemnt4 values
    SELECT NVL(description,'XXX')
      INTO x_segment4
      FROM fnd_flex_values_vl
     WHERE flex_value = x_segment4;*/

    select COUNT(1)
      into X_COUNT
      FROM FND_LOOKUP_VALUES_VL FLVV,
           FND_LOOKUP_TYPES_VL  FLTV,
           MTL_SYSTEM_ITEMS     mc
     WHERE FLVV.LOOKUP_TYPE = FLTV.LOOKUP_TYPE
       AND FLVV.ENABLED_FLAG = 'Y'
       AND sysdate BETWEEN FLVV.START_DATE_ACTIVE AND
           NVL(FLVV.END_DATE_ACTIVE, sysdate)
       AND FLVV.LOOKUP_TYPE = 'XX_DOC_CERT_ITEMS'
       AND FLVV.LOOKUP_CODE = MC.SEGMENT1
       AND MC.INVENTORY_ITEM_ID = p_item_id
       and MC.ORGANIZATION_ID = p_organization_id;

    IF X_COUNT != 0 THEN
      RETURN 'Y';
    ELSE
      RETURN 'N';
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'N';
    WHEN OTHERS THEN
      RETURN 'N';
  END xx_val_ord_line_eligibility;

  FUNCTION xx_validate_order_line(p_attribute8      IN VARCHAR2,
                                  p_item_id         IN NUMBER,
                                  p_organization_id IN NUMBER,
                                  p_ordered_item    IN VARCHAR2)
    RETURN VARCHAR2 IS
    x_status     VARCHAR2(1);
    x_attribute8 oe_order_lines_all.attribute8%TYPE;
  BEGIN
    x_status := xx_val_ord_line_eligibility(p_item_id         => p_item_id,
                                            p_organization_id => p_organization_id);

    IF x_status = 'Y' AND p_attribute8 IS NULL THEN
      RETURN 'The Item# ' || p_ordered_item || ' is Skin Item need doctor certification.';
    ELSE
      RETURN 'Proceed to next line';
    END IF;
  END xx_validate_order_line;

  PROCEDURE xx_apply_hold_on_order_line(itemtype  IN VARCHAR2,
                                        itemkey   IN VARCHAR2,
                                        actid     IN NUMBER,
                                        funcmode  IN VARCHAR2,
                                        resultout IN OUT NOCOPY VARCHAR2) IS
    x_order_eligible   VARCHAR2(1) := NULL;
    x_header_id        oe_order_headers_all.header_id%TYPE;
    x_item_id          oe_order_lines_all.line_id%TYPE;
    x_ship_from_org_id oe_order_lines_all.ship_from_org_id%TYPE;
    x_org_id           oe_order_lines_all.org_id%TYPE;
    x_attribute8       oe_order_lines_all.attribute8%TYPE;
    x_hold_id          oe_hold_definitions.hold_id%TYPE;
    x_return_status    VARCHAR2(30);
    x_msg_data         VARCHAR2(256);
    x_msg_count        NUMBER;
    x_data             VARCHAR2(2000);
    x_order_number     VARCHAR2(2000);
    x_hold_source_rec  oe_holds_pvt.hold_source_rec_type;
  BEGIN

    set_cnv_env;

    --Get order line details
    SELECT a.header_id,
           a.org_id,
           a.inventory_item_id,
           a.ship_from_org_id,
           a.attribute8,
           b.order_number
      INTO x_header_id,
           x_org_id,
           x_item_id,
           x_ship_from_org_id,
           x_attribute8,
           x_order_number
      FROM oe_order_lines_all a, oe_order_headers_all b
     WHERE a.line_id = itemkey
       AND a.header_id= b.header_id;

    xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                     p_category            => 'O2CEXT080',
                     p_error_text          => 'Doctor Certification Hold Process Starts',
                     p_record_identifier_1 => x_order_number);

    SELECT hold_id
      INTO x_hold_id
      FROM oe_hold_definitions
     WHERE NAME = 'Doctor Certification Hold';

    x_order_eligible := xx_val_ord_line_eligibility(p_item_id         => x_item_id,
                                                    p_organization_id => x_ship_from_org_id);

    IF x_order_eligible = 'Y' AND x_attribute8 IS NULL THEN

      xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                       p_category            => 'O2CEXT080',
                       p_error_text          => 'Line Eligible For Hold',
                       p_record_identifier_1 => x_order_number);
      --Apply hold
      /***************** Start:INITIALIZE ENVIRONMENT*************************************/
      fnd_global.apps_initialize(fnd_global.user_id,
                                 fnd_global.resp_id,
                                 fnd_global.resp_appl_id);
      mo_global.init('ONT');
      mo_global.set_policy_context('S', x_org_id);
      /***************** End:INITIALIZE ENVIRONMENT*************************************/
      --Define Variables
      oe_msg_pub.initialize;
      x_hold_source_rec                  := oe_holds_pvt.g_miss_hold_source_rec;
      x_hold_source_rec.hold_id          := x_hold_id;
      x_hold_source_rec.hold_entity_code := 'O';
      x_hold_source_rec.hold_entity_id   := x_header_id;
      x_hold_source_rec.header_id        := x_header_id;
      x_hold_source_rec.line_id          := itemkey;
      oe_holds_pub.apply_holds(p_api_version      => 1.0,
                               p_commit           => fnd_api.g_true,
                               p_validation_level => fnd_api.g_valid_level_none,
                               p_hold_source_rec  => x_hold_source_rec,
                               x_return_status    => x_return_status,
                               x_msg_count        => x_msg_count,
                               x_msg_data         => x_msg_data);

      -- Check Return Status
      IF x_return_status = fnd_api.g_ret_sts_success THEN
        COMMIT;
        xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                         p_category            => 'O2CEXT080',
                         p_error_text          => 'HOLD Applied : Successfully',
                         p_record_identifier_1 => x_order_number);

      ELSE
        --Show Error message
        ROLLBACK;
        wf_core.CONTEXT('xx_o2c_doctor_cert_pkg',
                        'xx_apply_hold_on_order_line ',
                        itemtype,
                        itemkey,
                        TO_CHAR(itemkey),
                        funcmode,
                        'Failed to apply hold in the order line ' ||
                        x_msg_data);
        xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                         p_category            => 'O2CEXT080',
                         p_error_text          => 'Failed to apply hold in the order line ' ||
                                                  x_msg_data,
                         p_record_identifier_1 => x_order_number);
      END IF;

      xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                       p_category            => 'O2CEXT080',
                       p_error_text          => 'Line Not Eligible For Hold',
                       p_record_identifier_1 => x_order_number);

    END IF;

    xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                     p_category            => 'O2CEXT080',
                     p_error_text          => 'Doctor Certification Hold Process End',
                     p_record_identifier_1 => x_order_number);

    resultout := 'COMPLETE:COMPLETE';
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT('xx_o2c_doctor_cert_pkg',
                      'xx_apply_hold_on_order_line ',
                      itemtype,
                      itemkey,
                      TO_CHAR(itemkey),
                      funcmode,
                      'ERROR : ' || SQLERRM);

      xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                       p_category            => 'O2CEXT080',
                       p_error_text          => 'Unexpected Error In Procedure ' ||
                                                SQLERRM,
                       p_record_identifier_1 => x_order_number);

      xx_emf_pkg.error(p_severity            => xx_emf_cn_pkg.cn_medium,
                       p_category            => 'O2CEXT080',
                       p_error_text          => 'Doctor Certification Hold Process End',
                       p_record_identifier_1 => x_order_number);

  END xx_apply_hold_on_order_line;
  -------------------------------------------------------------------------------  /*
END xx_o2c_doctor_cert_pkg;
/
