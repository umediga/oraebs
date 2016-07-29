DROP VIEW APPS.XX_BI_FI_INV_SUP_V;

/* Formatted on 6/6/2016 4:59:53 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_INV_SUP_V
(
   CREATION_DATE,
   EXPECTED_DELIVERY_DATE,
   FROM_ORGANIZATION_CODE,
   FROM_ORGANIZATION_NAME,
   FROM_SUBINVENTORY_NAME,
   INTRANSIT_OWNING_ORG_CODE,
   INTRANSIT_OWNING_ORG_NAME,
   LAST_UPDATE_DATE,
   NEED_BY_DATE,
   PO_DISTRIBUTION_NUMBER,
   PO_LINE_NUMBER,
   PO_NUMBER,
   PO_RELEASE_NUMBER,
   PO_SHIPMENT_NUMBER,
   RCV_SHIPMENT_LINE_NUMBER,
   RCV_SHIPMENT_NUMBER,
   RCV_TRANSACTION_ID,
   RECEIPT_DATE,
   REQUISITION_LINE_NUMBER,
   REQUISITION_NUMBER,
   REVISION,
   SUPPLY_SOURCE_ID,
   SUPPLY_TYPE_CODE,
   TO_ORGANIZATION_CODE,
   TO_ORGANIZATION_NAME,
   TO_ORG_PRIMARY_UOM,
   TO_SUBINVENTORY_NAME,
   UNIT_OF_MEASURE,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   EXPECTED_DELIVERY_DATE_DAY,
   EXPECTED_DELIVERY_DATE_MONTH,
   EXPECTED_DELIVERY_DATE_QUARTER,
   EXPECTED_DELIVERY_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   NEED_BY_DATE_DAY,
   NEED_BY_DATE_MONTH,
   NEED_BY_DATE_QUARTER,
   NEED_BY_DATE_YEAR,
   RECEIPT_DATE_DAY,
   RECEIPT_DATE_MONTH,
   RECEIPT_DATE_QUARTER,
   RECEIPT_DATE_YEAR,
   INVENTORY_ITEM_NAME,
   DESTINATION_TYPE,
   INVENTORY_LOCATION_NAME,
   TO_ORG_PRIMARY_QUANTITY,
   QUANTITY
)
AS
   SELECT mts.creation_date,
          mts.expected_delivery_date,
          mp1.organization_code,
          hou1.NAME AS FROM_ORGANIZATION_NAME,
          mts.from_subinventory,
          mp3.organization_code,
          hou3.NAME AS INTRANSIT_OWNING_ORG_NAME,
          mts.last_update_date,
          mts.need_by_date,
          TO_NUMBER (NULL) AS PO_DISTRIBUTION_NUMBER,
          TO_NUMBER (NULL) AS PO_LINE_NUMBER,
          NULL AS Po_Number,
          TO_NUMBER (NULL) AS PO_RELEASE_NUMBER,
          TO_NUMBER (NULL) AS PO_SHIPMENT_NUMBER,
          TO_NUMBER (NULL) AS RCV_SHIPMENT_LINE_NUMBER,
          NULL AS RCV_SHIPMENT_NUMBER,
          mts.rcv_transaction_id,
          mts.receipt_date,
          prl.line_num AS REQUISITION_LINE_NUMBER,
          prh.segment1 AS Requisition_Number,
          mts.item_revision,
          mts.supply_source_id,
          mts.supply_type_code,
          mp2.organization_code,
          hou2.NAME AS TO_ORGANIZATION_NAME,
          mts.to_org_primary_uom,
          mts.to_subinventory,
          mts.unit_of_measure,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Expected_Delivery_Date_Day,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Month,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Quarter,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Expected_Delivery_Date_Year,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Last_Update_Date_Day,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Month,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Quarter,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Last_Update_Date_Year,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Need_By_Date_Day,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Month,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Quarter,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Need_By_Date_Year,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Receipt_Date_Day,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Month,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Quarter,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Receipt_Date_Year,
          NULL AS Inventory_Item_Name,
          DECODE (
             mts.destination_type_code,
             'EXPENSE', 'Goods are expensed from the system upon delivery',
             'INVENTORY', 'Goods are received into inventory upon delivery',
             'SHOP FLOOR', 'Goods are received into an outside operation upon delivery',
             NULL)
             AS Destination_Type,
          NULL AS Inventory_Location_Name,
          mts.to_org_primary_quantity,
          mts.quantity
     FROM hr_all_organization_units hou1,
          hr_all_organization_units hou2,
          hr_all_organization_units hou3,
          mtl_parameters mp1,
          mtl_parameters mp2,
          mtl_parameters mp3,
          mtl_item_locations mil,
          mtl_system_items msi,
          po_requisition_headers_all prh,
          po_requisition_lines_all prl,
          mtl_supply mts,
          org_organization_definitions ood
    WHERE     mts.supply_type_code = 'REQ'
          AND prl.requisition_line_id = mts.req_line_id
          AND prh.requisition_header_id = mts.req_header_id
          AND hou1.organization_id(+) = mts.from_organization_id
          AND hou2.organization_id(+) = mts.to_organization_id
          AND hou3.organization_id(+) = mts.intransit_owning_org_id
          AND mp1.organization_id(+) = mts.from_organization_id
          AND mp2.organization_id(+) = mts.to_organization_id
          AND mp3.organization_id(+) = mts.intransit_owning_org_id
          AND msi.inventory_item_id(+) = mts.item_id
          AND msi.organization_id(+) = mts.from_organization_id
          AND mil.inventory_location_id(+) = mts.location_id
          AND mil.organization_id(+) = mts.from_organization_id
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND mts.from_organization_id = ood.ORGANIZATION_ID
          AND '_SEC:MTS.TO_ORGANIZATION_ID' IS NOT NULL
   UNION ALL                                                 /* This for PO */
   SELECT mts.creation_date,
          mts.expected_delivery_date,
          mp1.organization_code,
          hou1.NAME AS FROM_ORGANIZATION_NAME,
          mts.from_subinventory,
          mp3.organization_code,
          hou3.NAME AS INTRANSIT_OWNING_ORG_NAME,
          mts.last_update_date,
          mts.need_by_date,
          pod.distribution_num AS PO_DISTRIBUTION_NUMBER,
          pol.line_num AS PO_LINE_NUMBER,
          poh.segment1 AS Po_Number,
          por.release_num AS PO_RELEASE_NUMBER,
          pll.shipment_num AS PO_SHIPMENT_NUMBER,
          TO_NUMBER (NULL) AS RCV_SHIPMENT_LINE_NUMBER,
          NULL AS RCV_SHIPMENT_NUMBER,
          mts.rcv_transaction_id,
          mts.receipt_date,
          TO_NUMBER (NULL) AS REQUISITION_LINE_NUMBER,
          NULL AS REQUISITION_Number,
          mts.item_revision,
          mts.supply_source_id,
          mts.supply_type_code,
          mp2.organization_code,
          hou2.NAME AS TO_ORGANIZATION_NAME,
          mts.to_org_primary_uom,
          mts.to_subinventory,
          mts.unit_of_measure,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Expected_Delivery_Date_Day,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Month,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Quarter,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Expected_Delivery_Date_Year,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Last_Update_Date_Day,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Month,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Quarter,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Last_Update_Date_Year,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Need_By_Date_Day,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Month,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Quarter,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Need_By_Date_Year,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Receipt_Date_Day,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Month,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Quarter,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Receipt_Date_Year,
          NULL AS Inventory_Item_Name,
          DECODE (
             mts.destination_type_code,
             'EXPENSE', 'Goods are expensed from the system upon delivery',
             'INVENTORY', 'Goods are received into inventory upon delivery',
             'SHOP FLOOR', 'Goods are received into an outside operation upon delivery',
             NULL)
             AS Destination_Type,
          NULL AS Inventory_Location_Name,
          mts.to_org_primary_quantity,
          mts.quantity
     FROM hr_all_organization_units hou1,
          hr_all_organization_units hou2,
          hr_all_organization_units hou3,
          mtl_parameters mp1,
          mtl_parameters mp2,
          mtl_parameters mp3,
          mtl_item_locations mil,
          mtl_system_items msi,
          po_headers_all poh,
          po_lines_all pol,
          po_line_locations_all pll,
          po_distributions_all pod,
          po_releases_all por,
          mtl_supply mts,
          org_organization_definitions ood
    WHERE     mts.supply_type_code = 'PO'
          AND poh.po_header_id = mts.po_header_id
          AND pol.po_line_id = mts.po_line_id
          AND pod.po_distribution_id(+) = mts.po_distribution_id
          AND pll.line_location_id(+) = mts.po_line_location_id
          AND por.po_release_id(+) = mts.po_release_id
          AND hou1.organization_id(+) = mts.from_organization_id
          AND hou2.organization_id(+) = mts.to_organization_id
          AND hou3.organization_id(+) = mts.intransit_owning_org_id
          AND mp1.organization_id(+) = mts.from_organization_id
          AND mp2.organization_id(+) = mts.to_organization_id
          AND mp3.organization_id(+) = mts.intransit_owning_org_id
          AND msi.inventory_item_id(+) = mts.item_id
          AND msi.organization_id(+) = mts.from_organization_id
          AND mil.inventory_location_id(+) = mts.location_id
          AND mil.organization_id(+) = mts.from_organization_id
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND mts.from_organization_id = ood.ORGANIZATION_ID
          AND '_SEC:MTS.TO_ORGANIZATION_ID' IS NOT NULL /* RECEVING is made form two SELECTS*/
   /* This is for RECEIVING AND there are NO DISTRIBUTIONS */
   UNION ALL
   SELECT mts.creation_date,
          mts.expected_delivery_date,
          mp1.organization_code,
          hou1.NAME AS FROM_ORGANIZATION_NAME,
          mts.from_subinventory,
          mp3.organization_code,
          hou3.NAME AS INTRANSIT_OWNING_ORG_NAME,
          mts.last_update_date,
          mts.need_by_date,
          TO_NUMBER (NULL) AS PO_DISTRIBUTION_NUMBER,
          TO_NUMBER (NULL) AS PO_LINE_NUMBER,
          NULL AS Po_Number,
          TO_NUMBER (NULL) AS PO_RELEASE_NUMBER,
          TO_NUMBER (NULL) AS PO_SHIPMENT_NUMBER,
          rsl.line_num AS RCV_SHIPMENT_LINE_NUMBER,
          rsh.shipment_num AS RCV_SHIPMENT_NUMBER,
          mts.rcv_transaction_id,
          mts.receipt_date,
          prl.line_num AS REQUISITION_LINE_NUMBER,
          prh.segment1 AS Requisition_Number,
          mts.item_revision,
          mts.supply_source_id,
          mts.supply_type_code,
          mp2.organization_code,
          hou2.NAME AS TO_ORGANIZATION_NAME,
          mts.to_org_primary_uom,
          mts.to_subinventory,
          mts.unit_of_measure,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Expected_Delivery_Date_Day,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Month,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Quarter,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Expected_Delivery_Date_Year,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Last_Update_Date_Day,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Month,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Quarter,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Last_Update_Date_Year,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Need_By_Date_Day,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Month,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Quarter,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Need_By_Date_Year,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Receipt_Date_Day,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Month,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Quarter,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Receipt_Date_Year,
          NULL AS Inventory_Item_Name,
          DECODE (
             mts.destination_type_code,
             'EXPENSE', 'Goods are expensed from the system upon delivery',
             'INVENTORY', 'Goods are received into inventory upon delivery',
             'SHOP FLOOR', 'Goods are received into an outside operation upon delivery',
             NULL)
             AS Destination_Type,
          NULL AS Inventory_Location_Name,
          mts.to_org_primary_quantity,
          mts.quantity
     FROM hr_all_organization_units hou1,
          hr_all_organization_units hou2,
          hr_all_organization_units hou3,
          mtl_parameters mp1,
          mtl_parameters mp2,
          mtl_parameters mp3,
          mtl_item_locations mil,
          mtl_system_items msi,
          rcv_transactions rct,
          rcv_shipment_headers rsh,
          rcv_shipment_lines rsl,
          po_requisition_lines_all prl,
          po_requisition_headers_all prh,
          mtl_supply mts,
          org_organization_definitions ood
    WHERE     mts.supply_type_code = 'RECEIVING'
          AND mts.po_distribution_id IS NULL
          AND rct.transaction_id = mts.rcv_transaction_id
          AND rsl.shipment_line_id = mts.shipment_line_id
          AND rsh.shipment_header_id = mts.shipment_header_id
          AND prl.requisition_line_id(+) = mts.req_line_id
          AND prh.requisition_header_id(+) = mts.req_header_id
          AND hou1.organization_id(+) = mts.from_organization_id
          AND hou2.organization_id(+) = mts.to_organization_id
          AND hou3.organization_id(+) = mts.intransit_owning_org_id
          AND mp1.organization_id(+) = mts.from_organization_id
          AND mp2.organization_id(+) = mts.to_organization_id
          AND mp3.organization_id(+) = mts.intransit_owning_org_id
          AND msi.inventory_item_id(+) = mts.item_id
          AND msi.organization_id(+) = mts.from_organization_id
          AND mil.inventory_location_id(+) = mts.location_id
          AND mil.organization_id(+) = mts.from_organization_id
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND mts.from_organization_id = ood.ORGANIZATION_ID
          AND '_SEC:MTS.TO_ORGANIZATION_ID' IS NOT NULL /* This is for RECEIVING AND DISTRIBUTIONS EXISTS */
   UNION ALL
   SELECT mts.creation_date,
          mts.expected_delivery_date,
          mp1.organization_code,
          hou1.NAME AS FROM_ORGANIZATION_NAME,
          mts.from_subinventory,
          mp3.organization_code,
          hou3.NAME AS INTRANSIT_OWNING_ORG_NAME,
          mts.last_update_date,
          mts.need_by_date,
          pod.distribution_num AS PO_DISTRIBUTION_NUMBER,
          pol.line_num AS PO_LINE_NUMBER,
          poh.segment1 AS Po_Number,
          por.release_num AS PO_RELEASE_NUMBER,
          pll.shipment_num AS PO_SHIPMENT_NUMBER,
          rsl.line_num AS RCV_SHIPMENT_LINE_NUMBER,
          rsh.shipment_num AS RCV_SHIPMENT_NUMBER,
          mts.rcv_transaction_id,
          mts.receipt_date,
          prl.line_num AS Requisition_Line_Number,
          prh.segment1 AS Requisition_Number,
          mts.item_revision,
          mts.supply_source_id,
          mts.supply_type_code,
          mp2.organization_code,
          hou2.NAME AS TO_ORGANIZATION_NAME,
          mts.to_org_primary_uom,
          mts.to_subinventory,
          mts.unit_of_measure,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Expected_Delivery_Date_Day,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Month,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Quarter,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Expected_Delivery_Date_Year,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Last_Update_Date_Day,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Month,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Quarter,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Last_Update_Date_Year,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Need_By_Date_Day,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Month,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Quarter,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Need_By_Date_Year,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Receipt_Date_Day,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Month,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Quarter,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Receipt_Date_Year,
          NULL AS Inventory_Item_Name,
          DECODE (
             mts.destination_type_code,
             'EXPENSE', 'Goods are expensed from the system upon delivery',
             'INVENTORY', 'Goods are received into inventory upon delivery',
             'SHOP FLOOR', 'Goods are received into an outside operation upon delivery',
             NULL)
             AS Destination_Type,
          NULL AS Inventory_Location_Name,
          mts.to_org_primary_quantity,
          mts.quantity
     FROM hr_all_organization_units hou1,
          hr_all_organization_units hou2,
          hr_all_organization_units hou3,
          mtl_parameters mp1,
          mtl_parameters mp2,
          mtl_parameters mp3,
          mtl_item_locations mil,
          mtl_system_items msi,
          rcv_transactions rct,
          rcv_shipment_headers rsh,
          rcv_shipment_lines rsl,
          po_headers_all poh,
          po_lines_all pol,
          po_line_locations_all pll,
          po_distributions_all pod,
          po_releases_all por,
          po_requisition_lines_all prl,
          po_requisition_headers_all prh,
          mtl_supply mts,
          org_organization_definitions ood
    WHERE     mts.supply_type_code = 'RECEIVING'
          AND mts.po_distribution_id IS NOT NULL
          AND rct.transaction_id = mts.rcv_transaction_id
          AND rsl.shipment_line_id = mts.shipment_line_id
          AND rsh.shipment_header_id = mts.shipment_header_id
          AND prl.requisition_line_id(+) = mts.req_line_id
          AND prh.requisition_header_id(+) = mts.req_header_id
          AND por.po_release_id(+) = mts.po_release_id
          AND poh.po_header_id = mts.po_header_id
          AND pol.po_line_id = mts.po_line_id
          AND pod.po_distribution_id = mts.po_distribution_id
          AND pll.line_location_id(+) = mts.po_line_location_id
          AND hou1.organization_id(+) = mts.from_organization_id
          AND hou2.organization_id(+) = mts.to_organization_id
          AND hou3.organization_id(+) = mts.intransit_owning_org_id
          AND mp1.organization_id(+) = mts.from_organization_id
          AND mp2.organization_id(+) = mts.to_organization_id
          AND mp3.organization_id(+) = mts.intransit_owning_org_id
          AND msi.inventory_item_id(+) = mts.item_id
          AND msi.organization_id(+) = mts.from_organization_id
          AND mil.inventory_location_id(+) = mts.location_id
          AND mil.organization_id(+) = mts.from_organization_id
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND mts.from_organization_id = ood.ORGANIZATION_ID
          AND '_SEC:MTS.TO_ORGANIZATION_ID' IS NOT NULL
   UNION ALL                                      /*-- This is for SHIPMENT */
   SELECT mts.creation_date,
          mts.expected_delivery_date,
          mp1.organization_code,
          hou1.NAME AS FROM_ORGANIZATION_NAME,
          mts.from_subinventory,
          mp3.organization_code,
          hou3.NAME AS INTRANSIT_OWNING_ORG_NAME,
          mts.last_update_date,
          mts.need_by_date,
          TO_NUMBER (NULL) AS PO_DISTRIBUTION_NUMBER,
          TO_NUMBER (NULL) AS PO_LINE_NUMBER,
          NULL AS Po_Number,
          TO_NUMBER (NULL) AS PO_RELEASE_NUMBER,
          TO_NUMBER (NULL) AS PO_SHIPMENT_NUMBER,
          rsl.line_num AS RCV_SHIPMENT_LINE_NUMBER,
          rsh.shipment_num AS RCV_SHIPMENT_NUMBER,
          mts.rcv_transaction_id,
          mts.receipt_date,
          prl.line_num AS REQUISITION_LINE_NUMBER,
          prh.segment1 AS Requisition_Number,
          mts.item_revision,
          mts.supply_source_id,
          mts.supply_type_code,
          mp2.organization_code,
          hou2.NAME AS TO_ORGANIZATION_NAME,
          mts.to_org_primary_uom,
          mts.to_subinventory,
          mts.unit_of_measure,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Expected_Delivery_Date_Day,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Month,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Quarter,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Expected_Delivery_Date_Year,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Last_Update_Date_Day,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Month,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Quarter,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Last_Update_Date_Year,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Need_By_Date_Day,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Month,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Quarter,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Need_By_Date_Year,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Receipt_Date_Day,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Month,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Quarter,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Receipt_Date_Year,
          NULL AS Inventory_Item_Name,
          DECODE (
             mts.destination_type_code,
             'EXPENSE', 'Goods are expensed from the system upon delivery',
             'INVENTORY', 'Goods are received into inventory upon delivery',
             'SHOP FLOOR', 'Goods are received into an outside operation upon delivery',
             NULL)
             AS Destination_Type,
          NULL AS Inventory_Location_Name,
          mts.to_org_primary_quantity,
          mts.quantity
     FROM hr_all_organization_units hou1,
          hr_all_organization_units hou2,
          hr_all_organization_units hou3,
          mtl_parameters mp1,
          mtl_parameters mp2,
          mtl_parameters mp3,
          mtl_item_locations mil,
          mtl_system_items msi,
          rcv_shipment_headers rsh,
          rcv_shipment_lines rsl,
          po_requisition_lines_all prl,
          po_requisition_headers_all prh,
          mtl_supply mts,
          org_organization_definitions ood
    WHERE     mts.supply_type_code = 'SHIPMENT'
          AND mts.po_distribution_id IS NULL
          AND rsl.shipment_line_id = mts.shipment_line_id
          AND rsh.shipment_header_id = mts.shipment_header_id
          AND prl.requisition_line_id(+) = mts.req_line_id
          AND prh.requisition_header_id(+) = mts.req_header_id
          AND hou1.organization_id(+) = mts.from_organization_id
          AND hou2.organization_id(+) = mts.to_organization_id
          AND hou3.organization_id(+) = mts.intransit_owning_org_id
          AND mp1.organization_id(+) = mts.from_organization_id
          AND mp2.organization_id(+) = mts.to_organization_id
          AND mp3.organization_id(+) = mts.intransit_owning_org_id
          AND msi.inventory_item_id(+) = mts.item_id
          AND msi.organization_id(+) = mts.from_organization_id
          AND mil.inventory_location_id(+) = mts.location_id
          AND mil.organization_id(+) = mts.from_organization_id
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND mts.from_organization_id = ood.ORGANIZATION_ID
          AND '_SEC:MTS.TO_ORGANIZATION_ID' IS NOT NULL
   UNION ALL
   SELECT mts.creation_date,
          mts.expected_delivery_date,
          mp1.organization_code,
          hou1.NAME AS FROM_ORGANIZATION_NAME,
          mts.from_subinventory,
          mp3.organization_code,
          hou3.NAME AS INTRANSIT_OWNING_ORG_NAME,
          mts.last_update_date,
          mts.need_by_date,
          pod.distribution_num AS PO_DISTRIBUTION_NUMBER,
          pol.line_num AS PO_LINE_NUMBER,
          poh.segment1 AS Po_Number,
          por.release_num AS PO_RELEASE_NUMBER,
          pll.shipment_num AS PO_SHIPMENT_NUMBER,
          rsl.line_num AS RCV_SHIPMENT_LINE_NUMBER,
          rsh.shipment_num AS RCV_SHIPMENT_NUMBER,
          mts.rcv_transaction_id,
          mts.receipt_date,
          prl.line_num AS Requisition_Line_Number,
          prh.segment1 AS Requisition_Number,
          mts.item_revision,
          mts.supply_source_id,
          mts.supply_type_code,
          mp2.organization_code,
          hou2.NAME AS TO_ORGANIZATION_NAME,
          mts.to_org_primary_uom,
          mts.to_subinventory,
          mts.unit_of_measure,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              mts.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Expected_Delivery_Date_Day,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Month,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             AS Expected_Delivery_Date_Quarter,
          (DECODE (
              mts.EXPECTED_DELIVERY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.EXPECTED_DELIVERY_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Expected_Delivery_Date_Year,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Last_Update_Date_Day,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Month,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_Date_Quarter,
          (DECODE (
              mts.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mts.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Last_Update_Date_Year,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Need_By_Date_Day,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Month,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Need_By_Date_Quarter,
          (DECODE (
              mts.NEED_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.NEED_BY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Need_By_Date_Year,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Receipt_Date_Day,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Month,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Receipt_Date_Quarter,
          (DECODE (
              mts.RECEIPT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mts.RECEIPT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Receipt_Date_Year,
          NULL AS Inventory_Item_Name,
          DECODE (
             mts.destination_type_code,
             'EXPENSE', 'Goods are expensed from the system upon delivery',
             'INVENTORY', 'Goods are received into inventory upon delivery',
             'SHOP FLOOR', 'Goods are received into an outside operation upon delivery',
             NULL)
             AS Destination_Type,
          NULL AS Inventory_Location_Name,
          mts.to_org_primary_quantity,
          mts.quantity
     FROM hr_all_organization_units hou1,
          hr_all_organization_units hou2,
          hr_all_organization_units hou3,
          mtl_parameters mp1,
          mtl_parameters mp2,
          mtl_parameters mp3,
          mtl_item_locations mil,
          mtl_system_items msi,
          rcv_shipment_headers rsh,
          rcv_shipment_lines rsl,
          po_headers_all poh,
          po_lines_all pol,
          po_line_locations_all pll,
          po_distributions_all pod,
          po_releases_all por,
          po_requisition_lines_all prl,
          po_requisition_headers_all prh,
          mtl_supply mts,
          org_organization_definitions ood
    WHERE     mts.supply_type_code = 'SHIPMENT'
          AND mts.po_distribution_id IS NOT NULL
          AND rsl.shipment_line_id = mts.shipment_line_id
          AND rsh.shipment_header_id = mts.shipment_header_id
          AND prl.requisition_line_id(+) = mts.req_line_id
          AND prh.requisition_header_id(+) = mts.req_header_id
          AND por.po_release_id(+) = mts.po_release_id
          AND poh.po_header_id = mts.po_header_id
          AND pol.po_line_id = mts.po_line_id
          AND pod.po_distribution_id = mts.po_distribution_id
          AND pll.line_location_id(+) = mts.po_line_location_id
          AND hou1.organization_id(+) = mts.from_organization_id
          AND hou2.organization_id(+) = mts.to_organization_id
          AND hou3.organization_id(+) = mts.intransit_owning_org_id
          AND mp1.organization_id(+) = mts.from_organization_id
          AND mp2.organization_id(+) = mts.to_organization_id
          AND mp3.organization_id(+) = mts.intransit_owning_org_id
          AND msi.inventory_item_id(+) = mts.item_id
          AND msi.organization_id(+) = mts.from_organization_id
          AND mil.inventory_location_id(+) = mts.location_id
          AND mil.organization_id(+) = mts.from_organization_id
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND mts.from_organization_id = ood.ORGANIZATION_ID
          AND '_SEC:MTS.TO_ORGANIZATION_ID' IS NOT NULL;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_INV_SUP_V FOR APPS.XX_BI_FI_INV_SUP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_INV_SUP_V FOR APPS.XX_BI_FI_INV_SUP_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_INV_SUP_V FOR APPS.XX_BI_FI_INV_SUP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_INV_SUP_V FOR APPS.XX_BI_FI_INV_SUP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_SUP_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_SUP_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_SUP_V TO XXINTG;
