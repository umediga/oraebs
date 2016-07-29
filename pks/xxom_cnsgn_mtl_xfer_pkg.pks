DROP PACKAGE APPS.XXOM_CNSGN_MTL_XFER_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_CNSGN_MTL_XFER_PKG" 
/*************************************************************************************
*
*   HEADER
* 	 Source control header
*
*   PROGRAM NAME
* 	XXOM_CNSGN_MTL_XFER_PKG.pks
*
*   DESCRIPTION - This will perform various inventory transactions based on the 
*   transaction_type_id that is passed in. Primarily, it is used for interorg and 
*   subinventory transfers, but also will support miscellaneous gains and issues.
*
*   Currently, it has been tested throughroughly with:
*   8  - Physical Inventory Adjustment
*   12 - Subinventory Transfer
*   31 - Alias Issue
* 
* 
*   USAGE
* 
*    PARAMETERS
*    ==========
*    NAME 	               DESCRIPTION
*    ----------------      ------------------------------------------------------
* 
*   DEPENDENCIES
*  
*   CALLED BY
* 
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)  	DESCRIPTION
* ------- ----------- --------------- 	---------------------------------------------------
*     2.0 18-SEP-2013 Brian Stadnik
* 
******************************************************************************************/
IS

l_secondary_inventory_name VARCHAR2(50);
l_division                 VARCHAR2(10);

PROCEDURE Create_Transfer_Request
            (      p_user_id          IN  VARCHAR2,
                   p_salesrep_id      IN VARCHAR2,
                   
                   p_source_system IN VARCHAR2,
                   p_external_transaction_id IN VARCHAR2,
                   
                   p_source_code      IN  VARCHAR2,
                   p_reason_id        IN  NUMBER,                               
                   p_division         IN  VARCHAR2,

                   p_transaction_type IN  VARCHAR2,
                   
                   p_container        IN  VARCHAR2,
                   
                   p_to_division      IN  VARCHAR2,
                   p_to_salesrep_id   IN  VARCHAR2,                   

                   p_to_serial        IN  VARCHAR2,
                   p_to_container     IN  VARCHAR2,
                
                   p_tranaction_items IN xxintg_t_trx_line_t,

                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_code			IN  OUT	 VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
            );
            
PROCEDURE consignment_transaction
            (
                   p_source_code      IN  VARCHAR2,
                   p_transaction_source_id IN NUMBER,
                   p_header_id        IN NUMBER,
                   p_line_id          IN NUMBER,
                   p_organization_id  IN  NUMBER,
                   p_transaction_type_id IN NUMBER,
                   p_subinventory     IN  VARCHAR2,
                   p_inventory_location_id          IN  VARCHAR2,
                   p_lpn              IN VARCHAR2,
                   p_xfer_item        IN  VARCHAR2,
                   p_xfer_quantity    IN  NUMBER,
                   p_xfer_uom         IN  VARCHAR2,
                   p_lot_number       IN VARCHAR2,
                   p_serial_number    IN VARCHAR2,
                   p_to_organization_id  IN  NUMBER,
                   p_to_subinventory  IN  VARCHAR2,
                   p_to_inventory_location_id       IN  VARCHAR2,
                   p_to_lpn           IN VARCHAR,
                   p_reason_id        IN  NUMBER,
                   p_user_id          IN  NUMBER,
                   p_return_status    IN  OUT  VARCHAR2,
                   p_return_message   IN  OUT  VARCHAR2
            );            
    
END XXOM_CNSGN_MTL_XFER_PKG;
/
