DROP VIEW APPS.XX_IB_SFDC_DETAIL_V;

/* Formatted on 6/6/2016 4:58:28 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_IB_SFDC_DETAIL_V
(
   ITEM,
   ITEM_DESC,
   SERIAL_NUMBER,
   LOT_NUMBER,
   SITE_NUMBER,
   SHIPPED_DATE,
   QUANTITY,
   SALES_ORDER_NUMBER,
   PURCHASE_ORDER_NUMBER,
   WARRANTY_NAME,
   CONTRACT_NUMBER,
   WARRANTY_STATUS,
   WARRANTY_START_DATE,
   WARRANTY_END_DATE,
   IB_INSTANCE_ID,
   CNTRCT_LAST_UPD_DATE
)
AS
   SELECT msib.segment1 item,
          msib.description item_desc,
          cii.serial_number serial_number,
          cii.lot_number lot_number,                        -- added for wave2
          hps.party_site_number site_number,
          oola.actual_shipment_date shipped_date,
          cii.quantity quantity,
          ooha.order_number sales_order_number,
          oola.cust_po_number purchase_order_number,
          msi1.segment1 warranty_name,
          okh.contract_number contract_number,
          okh.sts_code warranty_status,
          okh.start_date warranty_start_date,
          okh.end_date warranty_end_date,
          cii.instance_id ib_instance_id,
          okh.last_update_date cntrct_last_upd_date         -- added for wave2
     FROM apps.csi_item_instances cii,
          apps.mtl_system_items_b msib,
          apps.oe_order_lines_all oola,
          apps.oe_order_headers_all ooha,
          apps.hz_cust_site_uses_all hcsu,
          apps.hz_cust_acct_sites_all hcas,
          apps.hz_party_sites hps,
          apps.hz_locations hl,
          apps.hz_parties hp,
          okc_k_headers_all_b okh,
          okc_k_lines_b sl,
          okc_k_lines_b cl,
          okc_k_items oki,
          okc_k_items oki1,
          okc_k_lines_b okl1,
          mtl_system_items msi1,
          okc_k_headers_all_b okhin,
          hz_cust_accounts ship_acc
    WHERE     cii.last_oe_order_line_id = oola.line_id(+)
          AND ooha.header_id = oola.header_id
          AND cii.inventory_item_id = msib.inventory_item_id
          AND hcsu.site_use_id = oola.ship_to_org_id         -- ship to org id
          AND hcsu.site_use_code = 'SHIP_TO'
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
          AND hcas.party_site_id = hps.party_site_id(+)
          AND hl.location_id(+) = hps.location_id
          AND hp.party_id = hps.party_id
          AND okh.id = sl.chr_id
          AND cl.cle_id = sl.id
          AND cl.id = oki.cle_id
          AND oki.jtot_object1_code = 'OKX_CUSTPROD'       -- for covered PROD
          AND oki.object1_id1 = cii.instance_id
          AND okh.scs_code = 'WARRANTY'
          AND oki1.dnz_chr_id = okl1.dnz_chr_id
          AND okhin.id = okl1.dnz_chr_id
          AND okhin.contract_number = okh.contract_number
          AND oki1.JTOT_OBJECT1_CODE = 'OKX_WARRANTY'
          AND msi1.inventory_item_id = oki1.OBJECT1_ID1
          AND msi1.organization_id = (SELECT organization_id
                                        FROM mtl_parameters
                                       WHERE organization_code = 'MST')
          AND okl1.lse_id = 18
          AND okl1.line_number = sl.line_number
          AND msib.organization_id =
                 (SELECT organization_id
                    FROM apps.mtl_parameters
                   WHERE organization_id = master_organization_id)
          --  AND NVL(hl.country,'XXXX')                        = 'US'  -- commented out for wave2
          AND msib.item_type IN ('FG', 'RPR', 'TLIN')
          AND NVL (ship_acc.customer_class_code, 'XXXX') NOT IN
                 ('INTERCOMPANY', 'INTEGRA EMPLOYEE')
          AND ship_acc.customer_type = 'R'
          AND hcas.cust_account_id = ship_acc.cust_account_id(+);


GRANT SELECT ON APPS.XX_IB_SFDC_DETAIL_V TO XXAPPSREAD;
