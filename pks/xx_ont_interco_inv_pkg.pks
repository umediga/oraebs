DROP PACKAGE APPS.XX_ONT_INTERCO_INV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_ONT_INTERCO_INV_PKG" as
  /******************************************************************************
  -- Filename:  XXONTINTERCOINV.pks
  -- RICEW Object id : R2R-EXT_019
  -- Purpose :  Package Specification for Intercompany Invoicing
  --
  -- Usage: Concurrent Program ( Type PL/SQL Procedure)
  -- Caution:
  -- Copyright (c) IBM
  -- All rights reserved.
  -- Ver  Date         Author             Modification
  -- ---- -----------  ------------------ --------------------------------------
  -- 1.0  28-May-2012  ABhargava          Created
  -- 1.1 27-Feb-2013  ABhargava          Added ISNUMBER function to accomodate the error in cursor for TRANSACTION_REFERENCE
  --
  --
  ******************************************************************************/
  -- Global Variables
  g_err_msg varchar2(2000);
  g_stage varchar2(2000);
  g_comp_batch_id varchar2(200);
  g_api_name varchar2(200);
  g_batch_id varchar2(100);
  g_source varchar2(100) := 'Intercompany';
  g_request_id number := fnd_global.conc_request_id;
  g_requested_by number := fnd_global.user_id;
  g_requested_date date := sysdate;
  g_status_new constant varchar2(3) := 'N';
  g_status_success constant varchar2(3) := 'S';
  g_status_error constant varchar2(3) := 'E';

  function isnumber(val in varchar2)
    return number;

  procedure manual_correction(x_errbuf out varchar2, x_retcode out varchar2, l_batch_id in number, l_header_id in number);

  procedure interco_get_list_price(p_price_list_id in number
                                 , p_organization in number
                                 , p_item_id in number
                                 , p_item_qty in number
                                 , p_item_uom in varchar2
                                 , p_currency in varchar2
                                 , p_cust_acct_id in number
                                 , o_list_price   out number
                                 , o_status   out varchar2
                                 , o_msg   out varchar2);

  procedure create_ap(x_errbuf out varchar2, x_retcode out varchar2);

  procedure create_ar(x_errbuf out varchar2, x_retcode out varchar2);

  procedure insert_staging(x_errbuf out varchar2, x_retcode out varchar2);

  function get_basic_price(p_transaction_id in number
                         , p_price_list_id in number
                         , p_inventory_item_id in number
                         , p_transaction_uom in varchar2
                         , p_trf_price_date in date
                         , x_invoice_currency_code   out varchar2
                         , l_return_status   out varchar2)
    return number;

  procedure print_debug(p_msg in varchar2);
end xx_ont_interco_inv_pkg; 
/
