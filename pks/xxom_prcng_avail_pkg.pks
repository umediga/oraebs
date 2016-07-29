DROP PACKAGE APPS.XXOM_PRCNG_AVAIL_PKG;

CREATE OR REPLACE PACKAGE APPS."XXOM_PRCNG_AVAIL_PKG" 
AS
/*************************************************************************************
*   PROGRAM NAME
*     XXOM_PRCNG_AVAIL_PKG.sql
*
*   DESCRIPTION
*
*   USAGE
*
*    PARAMETERS
*    ==========
*    NAME                    DESCRIPTION
*    ----------------      ------------------------------------------------------
*
*   DEPENDENCIES
*
*   CALLED BY
*
*   HISTORY
*   =======
*
* VERSION    DATE        AUTHOR(S)      DESCRIPTION
* ------- ----------- ---------------     ---------------------------------------------------
*     1.0 18-SEP-2013 Brian Stadnik
*
* ISSUES:
*
******************************************************************************************/

PROCEDURE Get_Item_Information(
    p_part_number         IN VARCHAR2,
    p_organization_code   IN VARCHAR2,
    x_inventory_item_id   OUT NOCOPY NUMBER,
    x_primary_uom_code    OUT NOCOPY VARCHAR2,
    x_uom_conversion_rate OUT NOCOPY NUMBER,
    x_lot_control         OUT NOCOPY BOOLEAN,
    x_serial_control      OUT NOCOPY BOOLEAN,
    x_business_unit       OUT NOCOPY VARCHAR2,
    x_category_id         OUT NOCOPY NUMBER,
    x_product_segment     OUT NOCOPY VARCHAR2,
    x_product_brand       OUT NOCOPY VARCHAR2,
    x_product_class       OUT NOCOPY VARCHAR2,
    x_product_type        OUT NOCOPY VARCHAR2,
    x_return_status       OUT NOCOPY VARCHAR2,
    x_msg_data            OUT NOCOPY VARCHAR2 );

PROCEDURE Get_Item_Pricing (
    p_country           IN VARCHAR2,
    p_party_site_number IN VARCHAR2,
    p_construct_pricing IN VARCHAR2,
    p_product_info      IN  xxintg_t_product_t,
    x_pricing_tbl       OUT qp_preq_grp.line_tbl_type,
    x_return_status     OUT VARCHAR2,
    x_return_code       OUT VARCHAR2,
    x_msg_data          OUT VARCHAR2);

PROCEDURE Get_Item_Pricing_XML(
    p_country          IN VARCHAR2,
    p_account_number   IN VARCHAR2,
    p_construct_pricing IN VARCHAR2,
    p_product_info     IN  xxintg_t_product_t,
    x_item_pricing_xml IN  OUT NOCOPY XMLTYPE,
    x_return_status    IN  OUT NOCOPY VARCHAR2,
    x_return_code             IN  OUT     VARCHAR2,
    x_msg_data         IN  OUT NOCOPY VARCHAR2 );

PROCEDURE Get_Item_Availability_XML(
    p_country          IN VARCHAR2,
    p_account_number   IN VARCHAR2,
    p_product_info     IN  xxintg_t_product_t,
    x_item_availability_xml IN OUT NOCOPY XMLTYPE,
    x_return_status    IN  OUT NOCOPY VARCHAR2,
    x_return_code             IN  OUT     VARCHAR2,
    x_msg_data         IN  OUT NOCOPY VARCHAR2 );

END XXOM_PRCNG_AVAIL_PKG;
/
