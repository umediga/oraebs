DROP FUNCTION APPS.XXSS_PO_NUMBER;

CREATE OR REPLACE FUNCTION APPS.XXSS_PO_NUMBER(p_item_id number)
return varchar2
as
l_po_number varchar2(200);
begin
SELECT   PO_NUM into l_po_number
              FROM   (SELECT   PHA.SEGMENT1 PO_NUM,
                               MSI.INVENTORY_ITEM_ID INVENTORY_ITEM,
                               ORGANIZATION_ID ORGANIZATION,
                               RANK ()
                                  over (partition by msi.segment1
                                        ORDER BY PLL.NEED_BY_DATE, pll.creation_date
                                        ASC)
                                  AS RANK
                        FROM   APPS.PO_HEADERS_ALL PHA,
                               APPS.PO_LINES_ALL PLA,
                               APPS.PO_LINE_LOCATIONS_ALL PLL,
                               APPS.MTL_SYSTEM_ITEMS MSI
                       WHERE       1 = 1
                               AND PHA.PO_HEADER_ID = PLA.PO_HEADER_ID
                               AND PLA.PO_LINE_ID = PLL.PO_LINE_ID
                               AND MSI.INVENTORY_ITEM_ID = PLA.ITEM_ID
                               AND MSI.ORGANIZATION_ID = 103
                               AND PLL.SHIPMENT_TYPE IN
                                        ('STANDARD', 'SCHEDULED', 'BLANKET')
                               AND NVL (PLL.APPROVED_FLAG, 'N') = 'Y'
                               AND NVL (PLL.CANCEL_FLAG, 'N') = 'N'
                               AND NVL (PLL.CLOSED_CODE, 'OPEN') IN ('OPEN')
                               AND NVL (PLL.QUANTITY, 0)
                                  - NVL (PLL.QUANTITY_CANCELLED, 0) >
                                     NVL (PLL.QUANTITY_RECEIVED, 0)) A
             WHERE       A.ORGANIZATION = 103
                    AND A.INVENTORY_ITEM = p_item_id
                     AND RANK = 1;
                     return l_po_number;
                     exception
                    when too_many_rows then
                   --  dbms_output.put_line('Two PO Numbers');
                   l_po_number:='Two PO Numbers for same need by dates';
                   return l_po_number;
end XXSS_PO_NUMBER;
/
