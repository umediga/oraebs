DROP PACKAGE APPS.XX_OM_CONSIGNMENT_ORDER_PKG;

CREATE OR REPLACE PACKAGE APPS.XX_OM_CONSIGNMENT_ORDER_PKG AUTHID CURRENT_USER
----------------------------------------------------------------------
/* $Header: XX_OM_CONSIGNMENT_ORDER_PKG.pks 1.0 2012/12/19 12:00:00 dparida noship $ */
/*
 Created By     : IBM Development Team
 Creation Date  : 19-Dec-2012
 File Name      : XX_OM_CONSIGNMENT_ORDER_PKG.pks
 Description    : This script creates the specification of the xx_om_consignment_order package

 Change History:

 Version Date        Name                    Remarks
 ------- ----------- ----                    ----------------------
 1.0     19-Dec-2012 IBM Development Team    Initial development.
 1.1     02-FEB-2016 Vinod                   Case Number 9141. Added procedure xx_om_iso_eligible to check if order is elgible for
                                             ISO
*/
----------------------------------------------------------------------
 AS
  -- =================================================================================
  -- These Global Variables are used to extract value from the process setup form
  -- =================================================================================

  -- =================================================================================
  -- Name           : xx_om_import_req
  -- Description    : Procedure To Create Req Records In Oracle Base Table
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  PROCEDURE xx_om_import_req(p_errbuf   OUT VARCHAR2,
                             p_retcode  OUT VARCHAR2,
                             p_org_id   IN NUMBER,
                             p_user_id  IN NUMBER,
                             p_resp_id  IN NUMBER,
                             p_app_id   IN NUMBER,
                             p_item_key IN VARCHAR2);

  -- =================================================================================
  -- Name           : xx_om_insert_req_line
  -- Description    : Procedure To Insert Data Into Req Interface Table
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  PROCEDURE xx_om_insert_req_line(itemtype  IN VARCHAR2,
                                  itemkey   IN VARCHAR2,
                                  actid     IN NUMBER,
                                  funcmode  IN VARCHAR2,
                                  resultout OUT NOCOPY VARCHAR2);

  -- =================================================================================
  -- Name           : xx_om_insert_req_line_prag
  -- Description    : Procedure To Insert Data Into Req Interface Table With PRAGMA
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  PROCEDURE xx_om_insert_req_line_prag(p_interface_source_code       varchar2,
                                       p_org_id                      number,
                                       p_source_organization_id      number,
                                       p_requisition_type            varchar2,
                                       p_destination_type_code       varchar2,
                                       p_authorization_status        varchar2,
                                       p_preparer_id                 number,
                                       p_source_type_code            varchar2,
                                       p_uom_code                    varchar2,
                                       p_line_type_id                number,
                                       p_quantity                    number,
                                       p_unit_price                  number,
                                       p_currency_code               varchar2,
                                       p_destination_organization_id number,
                                       p_deliver_to_location_id      number,
                                       p_deliver_to_requestor_id     number,
                                       p_item_id                     number,
                                       p_need_by_date                date,
                                       p_header_attribute15          varchar2,
                                       p_line_attribute15            varchar2,
                                       p_destination_subinventory    varchar2,
                                       p_error_flag                  OUT varchar2);

  -- =================================================================================
  -- Name           : xx_om_import_internal_so
  -- Description    : Procedure To Create Internal Sales Orders In Oracle
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  PROCEDURE xx_om_import_internal_so;

  -- =================================================================================
  -- Name           : xx_om_import_internal_ord
  -- Description    : Procedure To Create Internal Orders In Interface Table
  -- Parameters description       :
  --
  -- No user parameter
  -- ==================================================================================
  PROCEDURE xx_om_import_internal_ord;

  -- =================================================================================================
  -- Name           : xx_om_update_sales_line
  -- Description    : Procedure To Update Sales Order Line Status
  -- Parameters description       :
  --
  -- No user parameter
  -- ====================================================================================================
  PROCEDURE xx_om_update_sales_line(p_status_code varchar2,
                                    p_org_id      NUMBER,
                                    p_line_id     NUMBER);

  -- ==============================================================================================
  -- Name           : xx_om_update_sales_ord
  -- Description    : Procedure To Update attribute14 of Sales Order with the internal order number
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_update_sales_ord;

  -- ==============================================================================================
  -- Name           : xx_om_update_isales_ord
  -- Description    : Procedure To Update attribute14 of Internal Sales Order with the Original order number
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_update_isales_ord;

  -- ==============================================================================================
  -- Name           : xx_om_ord_line_closed_count
  -- Description    : Procedure To Count No Of Lines Closed
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_closed_lines_count(itemtype  IN VARCHAR2,
                                     itemkey   IN VARCHAR2,
                                     actid     IN NUMBER,
                                     funcmode  IN VARCHAR2,
                                     resultout OUT NOCOPY VARCHAR2);

  -- ==============================================================================================
  -- Name           : xx_om_get_iso_number
  -- Description    : Procedure To Get ISO Number Created
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_get_iso_number(itemtype  IN VARCHAR2,
                                 itemkey   IN VARCHAR2,
                                 actid     IN NUMBER,
                                 funcmode  IN VARCHAR2,
                                 resultout OUT NOCOPY VARCHAR2);

  -- 1.1 Case 9141
-- ==============================================================================================
  -- Name           : xx_om_iso_eligible
  -- Description    : Procedure to check if order is eligible for iso
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_iso_eligible(itemtype  IN VARCHAR2,
                               itemkey   IN VARCHAR2,
                               actid     IN NUMBER,
                               funcmode  IN VARCHAR2,
                               resultout OUT NOCOPY VARCHAR2);

  -- ==============================================================================================

  -- ==============================================================================================
  -- Name           : xx_om_create_iso
  -- Description    : Procedure To Create ISO
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_create_iso(itemtype  IN VARCHAR2,
                             itemkey   IN VARCHAR2,
                             actid     IN NUMBER,
                             funcmode  IN VARCHAR2,
                             resultout OUT NOCOPY VARCHAR2);

  -- ==============================================================================================
  -- Name           : xx_om_create_iso_prag
  -- Description    : Procedure To Create ISO
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_create_iso_prag(p_argument1 NUMBER,
                                  p_argument2 NUMBER,
                                  p_argument3 NUMBER,
                                  p_argument4 NUMBER,
                                  p_argument5 VARCHAR2,
                                  p_con_reqid OUT NUMBER);

  -- ==============================================================================================
  -- Name           : xx_om_validate_po
  -- Description    : Procedure To Check Cust PO Number
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_validate_po(itemtype  IN VARCHAR2,
                              itemkey   IN VARCHAR2,
                              actid     IN NUMBER,
                              funcmode  IN VARCHAR2,
                              resultout OUT NOCOPY VARCHAR2);
  -- ==============================================================================================
  -- Name           : xx_om_apply_cust_po_hold
  -- Description    : Procedure To Put Cust PO Number HOLD
  -- Parameters description       :
  --
  -- No user parameter
  -- =================================================================================================
  PROCEDURE xx_om_custpo_hold(itemtype  IN VARCHAR2,
                              itemkey   IN VARCHAR2,
                              actid     IN NUMBER,
                              funcmode  IN VARCHAR2,
                              resultout IN OUT NOCOPY VARCHAR2);

  ----------------------------------------------------------------------------------------
  -- Description: New procedure to verify Booking eligibility for
  -- ILS Product Request Order Type Only.
  -- This procedure along with new Order header Workflow Branch validates eligibility.
  -- OEOH : XXOM_PROD_REQ_HEADER -- XXOM Order Flow - Product Request
  -- Date : 02/25/2014 --
  ----------------------------------------------------------------------------------------
  PROCEDURE xxom_verify_wsh(itemtype  IN VARCHAR2,
                                  itemkey   IN VARCHAR2,
                                  actid     IN NUMBER,
                                  funcmode  IN VARCHAR2,
                                  resultout OUT NOCOPY VARCHAR2);

  PROCEDURE xx_om_create_ir_iso(itemtype  IN VARCHAR2,
                              itemkey   IN VARCHAR2,
                              actid     IN NUMBER,
                              funcmode  IN VARCHAR2,
                              resultout IN OUT NOCOPY VARCHAR2);


END xx_om_consignment_order_pkg;
/
