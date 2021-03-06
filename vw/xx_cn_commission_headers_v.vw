DROP VIEW APPS.XX_CN_COMMISSION_HEADERS_V;

/* Formatted on 6/6/2016 4:58:51 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_COMMISSION_HEADERS_V
(
   "Customer",
   "Sales Division",
   "Customer Account",
   "Sub Division",
   "Sale Type",
   "Employee Number",
   "Product Commission",
   "Operating Unit",
   "Ship To Address",
   "D-Code",
   "Payment Source Type",
   "Payment_Incentive_Type",
   "City",
   "Country",
   "Postal_Code",
   "State",
   "GL Code Segment",
   "Item Number",
   "Item Description",
   "Area",
   "Region",
   "Territory Name",
   "Territory ASsign Start_Date",
   "Territory ASsign End_Date",
   "Distributor",
   "Payment Source",
   "Sales Role",
   "Customer Category",
   "Contract Category",
   "Sales Mkt Segment",
   "Intg Compensation Type",
   "Bonus Bronze Prior Year Sales",
   "Reward Level",
   "Bid Bonus Prior Year Bid Total",
   "Order Line Number",
   "Order Line Id",
   "Organization Code",
   "Organization Id",
   "Order Type",
   "Unit Selling Price",
   "Unit List Price",
   "Item Cost",
   "Ordered Quantity",
   "Gross Profit",
   "Header SalesRep Id",
   "SalesRep Id",
   "SalesRep Number",
   "Line SalesRep Id",
   "Cust Trx Line SalesRep Id",
   "Discount",
   ATTRIBUTE58,
   ATTRIBUTE59,
   ATTRIBUTE60,
   COMMISSION_LINE_ID,
   LAST_UPDATE_DATE,
   CREDITED_SALESREP_ID,
   COMMISSION_AMOUNT,
   COMMISSION_RATE,
   POSTING_STATUS,
   PENDING_STATUS,
   ERROR_REASON,
   STATUS,
   PROCESSED_DATE
)
AS
   SELECT cch.attribute1 AS "Customer",
          cch.attribute2 AS "Sales Division",
          cch.attribute3 AS "Customer Account",
          cch.attribute4 AS "Sub Division",
          'Sales' AS "Sale Type",
          cch.attribute6 AS "Employee Number",
          NULL AS "Product Commission",
          cch.attribute8 AS "Operating Unit",
          cch.attribute9 AS "Ship To Address",
          cch.attribute10 AS "D-Code",
          NULL AS "Payment Source Type",
          NULL AS "Payment_Incentive_Type",
          hl.city AS "City",
          hl.country AS "Country",
          hl.postal_code AS "Postal_Code",
          hl.State AS "State",
          cldv.code_combination AS "GL Code Segment",
          cch.Attribute19 AS "Item Number",
          cch.Attribute20 AS "Item Description",
          cch.Attribute21 AS "Area",
          cch.Attribute22 AS "Region",
          cch.Attribute23 AS "Territory Name",
          cch.Attribute24 AS "Territory ASsign Start_Date",
          cch.Attribute25 AS "Territory ASsign End_Date",
          cch.Attribute29 AS "Distributor",
          NULL AS "Payment Source",
          cch.Attribute32 AS "Sales Role",
          NULL AS "Customer Category",
          cch.Attribute34 AS "Contract Category",
          NULL AS "Sales Mkt Segment",
          NULL AS "Intg Compensation Type",
          NULL AS "Bonus Bronze Prior Year Sales",
          NULL AS "Reward Level",
          NULL AS "Bid Bonus Prior Year Bid Total",
          cch.ATTRIBUTE42 AS "Order Line Number",
          cch.ATTRIBUTE43 AS "Order Line Id",
          cch.ATTRIBUTE44 AS "Organization Code",
          cch.ATTRIBUTE45 AS "Organization Id",
          cch.ATTRIBUTE46 AS "Order Type",
          cch.ATTRIBUTE47 AS "Unit Selling Price",
          cch.ATTRIBUTE48 AS "Unit List Price",
          cch.ATTRIBUTE49 AS "Item Cost",
          cch.ATTRIBUTE50 AS "Ordered Quantity",
          cch.ATTRIBUTE51 AS "Gross Profit",
          cch.ATTRIBUTE52 AS "Header SalesRep Id",
          cch.ATTRIBUTE53 AS "SalesRep Id",
          cch.ATTRIBUTE54 AS "SalesRep Number",
          cch.ATTRIBUTE55 AS "Line SalesRep Id",
          cch.ATTRIBUTE56 AS "Cust Trx Line SalesRep Id",
          cch.ATTRIBUTE57 AS "Discount",
          ATTRIBUTE58,
          ATTRIBUTE59,
          ATTRIBUTE60,
          ccl.Commission_Line_Id,
          ccl.LASt_Update_Date,
          ccl.Credited_Salesrep_Id,
          ccl.Commission_Amount,
          ccl.Commission_Rate,
          ccl.Posting_Status,
          ccl.Pending_Status,
          ccl.Error_ReASon,
          ccl.Status,
          ccl.Processed_Date
     FROM cn_commission_headers_all cch,
          oe_order_lines_all ool,
          hz_cust_site_uses_all hcsu,
          hz_cust_acct_sites_all hcAS,
          hz_party_sites hps,
          hz_locations hl,
          cn_commission_lines_all ccl,
          xx_cn_line_dist_v cldv
    WHERE     ool.line_id = cch.attribute43
          AND hcsu.site_use_id = ool.ship_to_org_id
          AND hcsu.cust_acct_site_id = hcAS.cust_acct_site_id
          AND hcAS.party_site_id = hps.party_site_id
          AND hl.location_id = hps.location_id
          AND ccl.commission_header_id = cch.commission_header_id
          AND cldv.trx_line_id = cch.source_trx_line_id;
