DROP VIEW APPS.OKL_LA_SERV_INTGR_UV;

/* Formatted on 6/6/2016 5:00:31 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.OKL_LA_SERV_INTGR_UV
(
   CLE_ID,
   START_DATE,
   END_DATE,
   ITEM_NAME,
   SUPPLIER_NAME,
   DNZ_CHR_ID,
   SERVICE_CONTRACT_NUMBER,
   K_REL_OBJS_ID,
   K_REL_OBJS_CLE_ID,
   K_REL_OBJS_CHR_ID,
   K_REL_OBJS_RTY_CODE,
   K_REL_OBJS_OBJECT1_ID1,
   K_REL_OBJS_OBJECT1_ID2,
   K_REL_OBJS_JTOT_OBJECT1_CODE,
   L_REL_OBJS_ID,
   L_REL_OBJS_CLE_ID,
   L_REL_OBJS_CHR_ID,
   L_REL_OBJS_RTY_CODE,
   L_REL_OBJS_OBJECT1_ID1,
   L_REL_OBJS_OBJECT1_ID2,
   L_REL_OBJS_JTOT_OBJECT1_CODE,
   AMOUNT,
   AUTHORING_ORG_ID,
   INV_ORGANIZATION_ID,
   CURRENCY_CODE,
   CUST_OBJECT1_ID1,
   CUST_OBJECT1_ID2,
   BTO_OBJECT1_ID1,
   BTO_OBJECT1_ID2,
   SUPPLIER_NUMBER,
   SUPPLIER_ID
)
AS
   SELECT cle.id cle_id,
          cle.start_date start_date,
          cle.end_date end_date,
          OKX_SERVICE_B.concatenated_segments item_name,
          OKX_VENDOR.VENDOR_NAME supplier_name,
          cle.dnz_chr_id dnz_chr_id,
          chrb.contract_number service_contract_number,
          chr_CRJB.ID k_rel_objs_ID,
          chr_CRJB.CLE_ID k_rel_objs_CLE_ID,
          chr_CRJB.CHR_ID k_rel_objs_CHR_ID,
          chr_CRJB.RTY_CODE k_rel_objs_RTY_CODE,
          chr_CRJB.OBJECT1_ID1 k_rel_objs_object1_id1,
          chr_CRJB.OBJECT1_ID2 k_rel_objs_object1_id2,
          chr_CRJB.JTOT_OBJECT1_CODE k_rel_objs_JTOT_OBJECT1_CODE,
          cle_CRJB.ID l_rel_objs_ID,
          cle_CRJB.CLE_ID l_rel_objs_CLE_ID,
          cle_CRJB.CHR_ID l_rel_objs_CHR_ID,
          cle_CRJB.RTY_CODE l_rel_objs_RTY_CODE,
          cle_CRJB.OBJECT1_ID1 l_rel_objs_object1_id1,
          cle_CRJB.OBJECT1_ID2 l_rel_objs_object1_id2,
          cle_CRJB.JTOT_OBJECT1_CODE l_rel_objs_JTOT_OBJECT1_CODE,
          kle.amount amount,
          'authoring_org_id' authoring_org_id,
          'inv_organization_id' inv_organization_id,
          'currency_code' currency_code,
          'cust_object1_id1' cust_object1_id1,
          'cust_object1_id2' cust_object1_id2,
          'bto_object1_id1' bto_object1_id1,
          'bto_object1_id2' bto_object1_id2,
          OKX_VENDOR.segment1 SUPPLIER_NUMBER,
          OKX_VENDOR.vendor_id SUPPLIER_ID
     FROM OKC_K_REL_OBJS CHR_CRJB,
          OKC_K_REL_OBJS CLE_CRJB,
          OKC_K_HEADERS_B CHRB,
          OKC_K_HEADERS_TL CHRT,
          OKC_K_LINES_B CLE,
          OKL_K_LINES KLE,
          OKC_LINE_STYLES_B LSE,
          OKC_K_ITEMS CIT,
          OKC_K_PARTY_ROLES_B CPL,
          MTL_SYSTEM_ITEMS_B_KFV OKX_SERVICE_B,
          MTL_SYSTEM_ITEMS_TL OKX_SERVICE_T,
          PO_VENDORS OKX_VENDOR
    WHERE     chr_crjb.chr_id = cle_crjb.chr_id
          AND CHRB.ID = CHRT.ID
          AND CHRT.LANGUAGE = USERENV ('LANG')
          AND chr_CRJB.OBJECT1_ID1 = TO_CHAR (CHRT.ID)
          AND chr_CRJB.OBJECT1_ID1 = TO_CHAR (CHRB.ID)
          AND chr_CRJB.OBJECT1_ID2 = '#'
          AND chr_crjb.cle_id IS NULL
          AND cle_crjb.object1_id1 = TO_CHAR (cle.id)
          AND cle_crjb.object1_id2 = '#'
          AND lse.id = cle.lse_id
          AND lse.lty_code = 'SERVICE'
          AND cit.cle_id = cle.id
          AND TO_CHAR (OKX_SERVICE_B.INVENTORY_ITEM_ID) = cit.object1_id1
          AND TO_CHAR (OKX_SERVICE_B.ORGANIZATION_ID) = cit.object1_id2
          AND cit.dnz_chr_id = cle.dnz_chr_id
          AND OKX_SERVICE_B.INVENTORY_ITEM_ID =
                 OKX_SERVICE_T.INVENTORY_ITEM_ID
          AND OKX_SERVICE_B.ORGANIZATION_ID = OKX_SERVICE_T.ORGANIZATION_ID
          AND OKX_SERVICE_B.VENDOR_WARRANTY_FLAG = 'N'
          AND OKX_SERVICE_B.SERVICE_ITEM_FLAG = 'Y'
          AND OKX_SERVICE_B.ORGANIZATION_ID =
                 SYS_CONTEXT ('OKC_CONTEXT', 'ORGANIZATION_ID')
          AND OKX_SERVICE_T.LANGUAGE = USERENV ('LANG')
          AND kle.id = cle_crjb.cle_id
          AND cpl.cle_id = cle_crjb.cle_id
          AND cpl.dnz_chr_id = cle_crjb.chr_id
          AND cpl.dnz_chr_id = chr_crjb.chr_id
          AND cpl.rle_code = 'OKL_VENDOR'
          AND cpl.object1_id1 = TO_CHAR (OKX_VENDOR.VENDOR_ID)
          AND cpl.object1_id2 = '#';


CREATE OR REPLACE SYNONYM ETLEBSUSER.OKL_LA_SERV_INTGR_UV FOR APPS.OKL_LA_SERV_INTGR_UV;


GRANT SELECT ON APPS.OKL_LA_SERV_INTGR_UV TO INTG_NONHR_NONXX_RO;

GRANT SELECT ON APPS.OKL_LA_SERV_INTGR_UV TO SS_ETL_RO;
