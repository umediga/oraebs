DROP FUNCTION APPS.XXSS_PO_REC_QTY;

CREATE OR REPLACE FUNCTION APPS.XXSS_PO_REC_QTY(P_ITEM_ID NUMBER,P_RANK_NUM NUMBER)
RETURN number
as
L_PO_NUM varchar2(200);
begin
SELECT   SUM (QUANT) INTO L_PO_NUM
                          FROM   (SELECT   PLL.QUANTITY_RECEIVED QUANT,
                                           MSI.INVENTORY_ITEM_ID INVENTORY_ITEM,
                                           ORGANIZATION_ID ORGANIZATION,
                                           RANK ()
                                              OVER (
                                                 partition by msi.segment1
                                                 ORDER BY PLL.NEED_BY_DATE, pll.creation_date ASC
                                              )
                                              AS RANK
                                    FROM   APPS.PO_HEADERS_ALL PHA,
                                           APPS.PO_LINES_ALL PLA,
                                           APPS.PO_LINE_LOCATIONS_ALL PLL,
                                           APPS.MTL_SYSTEM_ITEMS MSI
                                   WHERE   1 = 1
                                           AND PHA.PO_HEADER_ID =
                                                 PLA.PO_HEADER_ID
                                           AND PLA.PO_LINE_ID = PLL.PO_LINE_ID
                                           AND MSI.INVENTORY_ITEM_ID =
                                                 PLA.ITEM_ID
                                           AND MSI.ORGANIZATION_ID = 103
                                           AND PLL.SHIPMENT_TYPE IN
                                                    ('STANDARD',
                                                     'SCHEDULED',
                                                     'BLANKET')
                                           AND NVL (PLL.APPROVED_FLAG, 'N') = 'Y'
                                           AND NVL (PLL.CANCEL_FLAG, 'N') = 'N'
                                           AND NVL (PLL.CLOSED_CODE, 'OPEN') IN
                                                    ('OPEN')
                                           AND NVL (PLL.QUANTITY, 0)
                                              - NVL (PLL.QUANTITY_CANCELLED, 0) >
                                                 NVL (PLL.QUANTITY_RECEIVED, 0))
                                 A
                         WHERE       A.ORGANIZATION = 103
                                 AND A.INVENTORY_ITEM = P_ITEM_ID
                                 AND RANK = P_RANK_NUM;
RETURN L_PO_NUM;
    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
     L_PO_NUM :='Same PO Rec Quantity';
   return l_po_num;
end XXSS_PO_REC_QTY;
/


GRANT EXECUTE ON APPS.XXSS_PO_REC_QTY TO XXAPPSREAD;
