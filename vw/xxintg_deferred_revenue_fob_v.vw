DROP VIEW APPS.XXINTG_DEFERRED_REVENUE_FOB_V;

/* Formatted on 6/6/2016 5:00:22 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_DEFERRED_REVENUE_FOB_V
(
   BATCHSOURCE,
   TRANSACTIONNUMBER,
   ORDERNUMBER,
   INVOICEDATE,
   GLDATE,
   INVOICETYPE,
   CURRENCY,
   AMOUNTDUEUSD,
   AMOUNTDUELOCAL,
   INVOICEAMOUNTUSD,
   CUSTOMERNAME,
   CUSTOMERNUMBER,
   CUSTOMERCATEGORY,
   SHIPDATE,
   ORDERFOB,
   CUSTOMERFOB,
   FREIGHTCARRIER,
   SHIPMETHODCODE,
   FREIGHTACCOUNTNUMBER,
   DESTINATIONCOUNTRY,
   SHIPTOCOUNTRY,
   BILLTOCOUNTRY,
   DELIVERTOCOUNTRY,
   WAREHOUSE,
   WAYBILL,
   MOREWAYBILLS,
   COGS,
   LINETYPE,
   ORDERTYPE
)
AS
   SELECT rb.name BatchSource,
          rat.trx_number TransactionNumber,
          rat.interface_header_attribute1 OrderNumber,
          rat.trx_date InvoiceDate,
          ragl.gl_date GLDate,
          rtt.name InvoiceType,
          rat.invoice_currency_code Currency,
          aps.ACCTD_AMOUNT_DUE_REMAINING AmountDueUSD,
          aps.amount_due_remaining AmountDueLocal,
          (aps.amount_due_original * NVL (aps.exchange_rate, 1))
             InvoiceAmountUSD,
          hp.party_name CustomerName,
          hca.account_number CustomerNumber,
          (SELECT meaning
             FROM apps.ar_lookups cust_class
            WHERE     cust_class.lookup_type = 'CUSTOMER CLASS'
                  AND cust_class.lookup_code = hca.customer_class_code)
             CustomerCategory,
          rat.ship_date_actual ShipDate,
          (SELECT fob.meaning
             FROM apps.ar_lookups fob
            WHERE rat.fob_point = fob.lookup_code AND fob.lookup_type = 'FOB')
             OrderFOB,
          (SELECT fob.meaning
             FROM apps.ar_lookups fob
            WHERE hca.fob_point = fob.lookup_code AND fob.lookup_type = 'FOB')
             CustomerFOB,
          (SELECT MAX (NVL (oeh.freight_carrier_code, wsh.freight_code))
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.WSH_CARRIER_SHIP_METHODS_V wsh
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oeh.shipping_method_code = wsh.ship_method_code
                  AND oel.ship_from_org_id = wsh.organization_Id
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             FreightCarrier,
          (SELECT MAX (wsh.SHIP_METHOD_CODE_MEANING)
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.WSH_CARRIER_SHIP_METHODS_V wsh
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oeh.shipping_method_code = wsh.ship_method_code
                  AND oel.ship_from_org_id = wsh.organization_Id
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             ShipMethodCode,
          (SELECT MAX (oeh.tp_attribute1)
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oeh.tp_context = 'Shipping'
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             FreightAccountNumber,
          (SELECT MAX (terr.TERRITORY_SHORT_NAME)
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.fnd_territories_vl terr
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oeh.tp_context = 'Shipping'
                  AND terr.TERRITORY_CODE = oeh.TP_ATTRIBUTE3
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             DestinationCountry,
          (SELECT MAX (terr.TERRITORY_SHORT_NAME)
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.fnd_territories_vl terr,
                  apps.XXINTG_SHIP_TO_ORGS_V shipto
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oel.ship_to_org_id = shipto.organization_id
                  AND terr.TERRITORY_CODE = shipto.country
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             ShipToCountry,
          (SELECT MAX (terr.TERRITORY_SHORT_NAME)
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.fnd_territories_vl terr,
                  apps.XXINTG_INVOICE_TO_ORGS_V shipto
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oel.invoice_to_org_id = shipto.organization_id
                  AND terr.TERRITORY_CODE = shipto.country
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             BillToCountry,
          (SELECT MAX (terr.TERRITORY_SHORT_NAME)
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.fnd_territories_vl terr,
                  apps.XXINTG_DELIVER_TO_ORGS_V shipto
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oel.deliver_to_org_id = shipto.organization_id
                  AND terr.TERRITORY_CODE = shipto.country
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             DeliverToCountry,
          (SELECT MAX (hr.name)
             FROM apps.oe_order_headers_all oeh,
                  apps.oe_order_lines_all oel,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.hr_organization_units hr
            WHERE     ratl.interface_line_attribute1 = (oeh.order_number)
                  AND oeh.header_id = oel.header_id
                  AND ratl.interface_line_attribute6 = (line_id)
                  AND rat.customer_trx_id = ratl.customer_trx_Id
                  AND ratl.line_type = 'LINE'
                  AND ratl.sales_order_line > 0
                  AND oel.ship_from_org_id = hr.organization_id
                  AND ratl.interface_line_context = 'ORDER ENTRY')
             Warehouse,
          LTRIM (RTRIM (rat.waybill_number)) Waybill,
          (SELECT CASE
                     WHEN COUNT (DISTINCT interface_line_attribute4) > 1
                     THEN
                        'Yes'
                     ELSE
                        'No'
                  END
             FROM apps.ra_customer_trx_lines_all ratl
            WHERE     line_type = 'LINE'
                  AND ratl.interface_line_context = 'ORDER ENTRY'
                  AND NVL (interface_line_attribute4, '0') <> '0'
                  AND ratl.customer_trx_id = rat.customer_trx_id
                  AND ratl.line_type = 'LINE')
             MoreWaybills,
          (SELECT SUM (base_transaction_value)
             FROM apps.mtl_transaction_accounts mta,
                  apps.mtl_material_transactions mmt,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.mtl_sales_orders mso
            WHERE     mta.accounting_line_type = 35
                  AND mta.transaction_id = mmt.transaction_Id
                  AND TO_CHAR (mmt.trx_source_line_id) =
                         ratl.interface_line_attribute6
                  AND ratl.customer_trx_id = rat.customer_trx_id
                  AND ratl.interface_line_attribute1 = mso.segment1
                  AND ratl.interface_line_context = 'ORDER ENTRY'
                  AND mmt.transaction_source_id = mso.sales_order_id)
             COGS,
          (SELECT CASE WHEN COUNT (*) > 1 THEN 'Shipped' ELSE 'Bill Only' END
             FROM apps.mtl_material_transactions mmt,
                  apps.ra_customer_trx_lines_all ratl,
                  apps.mtl_sales_orders mso
            WHERE     TO_CHAR (mmt.trx_source_line_id) =
                         ratl.interface_line_attribute6
                  AND NVL (ratl.sales_order_line, 0) > 0
                  AND ratl.customer_trx_id = rat.customer_trx_id
                  AND ratl.interface_line_attribute1 = mso.segment1
                  AND ratl.interface_line_context = 'ORDER ENTRY'
                  AND mmt.transaction_source_id = mso.sales_order_id)
             LineType,
          rat.interface_header_attribute2 OrderType
     FROM apps.ra_cust_trx_line_gl_dist_all ragl,
          apps.ra_customer_trx_all rat,
          apps.ra_batch_sources_all rb,
          apps.ra_cust_trx_types_all rtt,
          apps.ar_lookups inv_type,
          apps.ra_terms rt,
          apps.ar_payment_schedules_all aps,
          apps.hz_cust_accounts hca,
          apps.hz_parties hp
    WHERE     rat.customer_trx_id = ragl.customer_trx_id
          AND ragl.account_class = 'REC'
          AND ragl.latest_rec_flag = 'Y'
          AND rat.interface_header_context = 'ORDER ENTRY'
          --and ragl.gl_date between '01-JUN-2014' and '30-JUN-2014'
          AND rat.batch_source_id = rb.batch_source_id
          AND rtt.cust_trx_type_id = rat.cust_trx_type_id
          AND inv_type.lookup_type = 'INV/CM'
          AND inv_type.lookup_code = rtt.TYPE
          AND rat.term_id = rt.term_id
          AND rat.customer_trx_id = aps.customer_trx_id
          AND rat.bill_to_customer_id = hca.cust_account_Id
          AND rat.org_id = rtt.ORG_ID
          AND hca.party_id = hp.party_id
          AND UPPER (rb.name) NOT LIKE '%INTERCOMPANY%';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_DEFERRED_REVENUE_FOB_V FOR APPS.XXINTG_DEFERRED_REVENUE_FOB_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXINTG_DEFERRED_REVENUE_FOB_V FOR APPS.XXINTG_DEFERRED_REVENUE_FOB_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_DEFERRED_REVENUE_FOB_V FOR APPS.XXINTG_DEFERRED_REVENUE_FOB_V;


CREATE OR REPLACE SYNONYM XXINTG.XXINTG_DEFERRED_REVENUE_FOB_V FOR APPS.XXINTG_DEFERRED_REVENUE_FOB_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_DEFERRED_REVENUE_FOB_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_DEFERRED_REVENUE_FOB_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_DEFERRED_REVENUE_FOB_V TO XXINTG;
