DROP FUNCTION APPS.XX_OE_ORDER_TOTAL_RETURN;

CREATE OR REPLACE FUNCTION APPS."XX_OE_ORDER_TOTAL_RETURN" (P_HEADER_ID NUMBER)
   RETURN NUMBER
AS
--------------------------------------------------------------------------------
 /*
 Created By     : Vishal Rathore
 Creation Date  : 16-Sep-2012
 Filename       : XXOEORDERTOTALRETURN.fnc
 Description    : This function is used to return order total

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 16-Sep-2012   1.0       Vishal Rathore      Initial development.

 */
--------------------------------------------------------------------------------
   x_tot_amount   NUMBER;
BEGIN
   -- Return SUM of Unit Price and Quantity
   SELECT SUM (OEL.UNIT_SELLING_PRICE * OEL.PRICING_QUANTITY)
     INTO x_tot_amount
     FROM OE_ORDER_HEADERS_ALL OEH, OE_ORDER_LINES_ALL OEL
    WHERE OEH.HEADER_ID = OEL.HEADER_ID
      AND OEH.HEADER_ID = P_HEADER_ID;

   RETURN x_tot_amount;
EXCEPTION
   WHEN OTHERS
   THEN
      X_TOT_AMOUNT := NULL;
      RETURN x_tot_amount;
END;
/
