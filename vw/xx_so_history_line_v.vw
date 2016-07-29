DROP VIEW APPS.XX_SO_HISTORY_LINE_V;

/* Formatted on 6/6/2016 4:58:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SO_HISTORY_LINE_V
(
   LINE_ID,
   HEADER_ID,
   SOURCE,
   SALES_ORDER_NUMBER,
   ORDER_LINE_NUMBER,
   REQUESTED_DATE,
   WAREHOUSE,
   RMA_NUMBER,
   RETURNED_DATE,
   ITEM,
   ITEM_DESCRIPTION,
   ORDER_QUANTITY,
   UNIT_PRICE,
   TOTAL_PRICE,
   PRICE_LIST,
   SHIPPED_QUANTITY,
   SCHEDULED_SHIPPED_DATE,
   LOT_NUMBER,
   SERIAL_NUMBER,
   SHIP_TO_NAME,
   TRACKING_NUMBER,
   BILL_TO_NAME,
   ACTUAL_SHIP_DATE,
   INVOICE_NUMBER,
   INVOICE_DATE,
   LINE_CHARGES,
   LINE_TAX,
   LINE_TOTAL,
   PATIENT_NAME
)
AS
   (SELECT line.line_id,
           hdr.header_id,
           line.SOURCE,
           line.sales_order_number,
           line.order_line_number,
           line.requested_date,
           line.warehouse,
           line.rma_number,
           line.returned_date,
           line.item,
           line.item_description,
           line.order_quantity,
           line.unit_price,
           line.total_price,
           line.price_list,
           line.shipped_quantity,
           line.scheduled_shipped_date,
           line.lot_number,
           line.serial_number,
           line.ship_to_name,
           line.tracking_number,
           line.bill_to_name,
           line.actual_ship_date,
           line.invoice_number,
           line.invoice_date,
           line.line_charges,
           line.line_tax,
           line.line_total,
           line.patient_name
      FROM xx_sales_order_history_line line,
           xx_sales_order_history_header hdr
     WHERE     1 = 1
           AND line.SOURCE = hdr.SOURCE
           AND line.sales_order_number = hdr.sales_order_number
           AND line.header_id = hdr.header_id);
