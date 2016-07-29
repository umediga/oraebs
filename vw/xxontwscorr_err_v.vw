DROP VIEW APPS.XXONTWSCORR_ERR_V;

/* Formatted on 6/6/2016 5:00:06 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXONTWSCORR_ERR_V
(
   HEADER_ID,
   LINE_ID,
   SOURCE_TYPE,
   ERROR_MSSG,
   CREATION_DATE,
   CREATED_BY,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN
)
AS
   SELECT "HEADER_ID",
          "LINE_ID",
          "SOURCE_TYPE",
          "ERROR_MSSG",
          "CREATION_DATE",
          "CREATED_BY",
          "LAST_UPDATE_DATE",
          "LAST_UPDATED_BY",
          "LAST_UPDATE_LOGIN"
     FROM xx_oe_order_ws_in_error_stg;