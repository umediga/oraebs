DROP PACKAGE APPS.XX_BI_SHIP_REP_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BI_SHIP_REP_PKG" 
AS
FUNCTION get_total_by_delvery(p_src_hdr_num VARCHAR2,p_delivery_id NUMBER) return NUMBER;
FUNCTION get_release_date(p_move_ord_line_id NUMBER,p_source_line_id NUMBER) return DATE;
FUNCTION get_invoice_no(p_src_header_number VARCHAR2,p_org_id NUMBER) return VARCHAR2;
FUNCTION get_revenue_cost(p_line_id NUMBER) return NUMBER;
FUNCTION get_freight_cost(p_delevery_id NUMBER) return NUMBER;
FUNCTION get_ship_date(p_delivery_det_id NUMBER) return DATE;

END XX_BI_SHIP_REP_PKG;
/
