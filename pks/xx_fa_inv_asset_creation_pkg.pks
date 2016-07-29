DROP PACKAGE APPS.XX_FA_INV_ASSET_CREATION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_FA_INV_ASSET_CREATION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 15-JUN-2013
 File Name     : XXFAINVASSTCREATE.pks
 Description   : This script creates the specification of the package
                 xx_fa_inv_asset_creation_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 15-JUN-2013 Sharath Babu          Initial development.
*/
----------------------------------------------------------------------

   --Global Variables
   g_retcode NUMBER;
   g_errmsg  VARCHAR2(1000);
   g_error_flag   VARCHAR2(10) := 'E';
   g_process_flag VARCHAR2(10) := 'P';
   g_ready_flag   VARCHAR2(10) := 'R';

   g_ou_us  VARCHAR2(50);
   g_us_book_code VARCHAR2(50);
   g_surg_item_type  VARCHAR2(50);
   g_pool_item_type  VARCHAR2(50);
   g_surg_maj_cat    VARCHAR2(50);
   g_pool_maj_cat    VARCHAR2(50);
   g_pool_min_cat    VARCHAR2(50);

   g_creation_date         DATE   := SYSDATE;
   g_created_by            NUMBER := fnd_global.user_id;
   g_last_update_date      DATE   := SYSDATE;
   g_last_updated_by       NUMBER := fnd_global.user_id;
   g_last_update_login     NUMBER := fnd_global.login_id;
   g_request_id            NUMBER := fnd_global.conc_request_id;
   g_user_id               NUMBER := fnd_global.user_id;
   g_resp_id               NUMBER := fnd_global.resp_id;
   g_resp_appl_id          NUMBER := fnd_global.resp_appl_id;

   TYPE transaction_rec IS RECORD
   (
    mtl_txn_id             NUMBER,
    mtl_txn_date           DATE,
    mtl_txn_qty            NUMBER,
    mtl_txn_type           VARCHAR2(200),
    compl_txn_id           NUMBER,
    txn_reference          VARCHAR2(200),
    capex_number           VARCHAR2(500),
    inventory_item_id      NUMBER,
    item                   VARCHAR2(200),
    item_description       VARCHAR2(500),
    item_type              VARCHAR2(200),
    primary_uom_code       VARCHAR2(50),
    organization_id        NUMBER,
    organization_code      VARCHAR2(100),
    wip_entity_id          NUMBER,
    wrk_order_num          VARCHAR2(200),
    serial_number          VARCHAR2(100),
    lot_number             VARCHAR2(100),
    location_type_code     VARCHAR2(100),
    asset_number           VARCHAR2(200),
    asset_quantity         NUMBER,
    asset_type             VARCHAR2(100),
    asset_description      VARCHAR2(200),
    asset_unit_cost        NUMBER,
    asset_cost             NUMBER,
    asset_category         VARCHAR2(100),
    asset_category_id      NUMBER,
    book_type_code         VARCHAR2(100),
    date_placed_in_service DATE,
    asset_location_id      NUMBER,
    asset_key_ccid         NUMBER,
    deprn_expense_ccid     NUMBER,
    payables_ccid          NUMBER,
    tag_number             VARCHAR2(100),
    group_asset_id         NUMBER,
    --depreciable_flag       VARCHAR2(10),
    record_number          NUMBER,
    process_flag           VARCHAR2(50),
    derivation_flag        VARCHAR2(50),
    error_message          VARCHAR2(4000),
    request_id             NUMBER,
    created_by             NUMBER,
    creation_date          DATE,
    last_update_date       DATE,
    last_updated_by        NUMBER,
    last_update_login      NUMBER
    );

   TYPE transaction_tbl IS TABLE of transaction_rec INDEX BY BINARY_INTEGER;


   PROCEDURE main (
                    errbuf                OUT      VARCHAR2,
                    retcode               OUT      VARCHAR2,
                    p_from_trx_date       IN       VARCHAR2,
                    p_to_trx_date         IN       VARCHAR2,
                    p_run_mode            IN       VARCHAR2,
                    p_request_id          IN       NUMBER,
                    p_disp_trx            IN       VARCHAR2,
                    p_capex_num           IN       VARCHAR2
                   );

END xx_fa_inv_asset_creation_pkg; 
/
