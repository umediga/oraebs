DROP FUNCTION APPS.XXSS_NEED_BY_DATE;

CREATE OR REPLACE FUNCTION APPS.XXSS_NEED_BY_DATE(P_ITEM_ID NUMBER,P_RANK_NUM NUMBER)
RETURN varchar2
as
L_NEED_BY varchar2(200);
begin
SELECT   NEED_BY  INTO L_NEED_BY
              FROM   (SELECT   to_char(PLL.NEED_BY_DATE,'MM-DD-YY') NEED_BY,
                               MSI.INVENTORY_ITEM_ID INVENTORY_ITEM,
                               ORGANIZATION_ID ORGANIZATION,
                               RANK ()
                                  OVER (PARTITION BY MSI.SEGMENT1
                                        ORDER BY PLL.NEED_BY_DATE,PLL.CREATION_DATE)
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
                     AND A.INVENTORY_ITEM = P_ITEM_ID
                     AND RANK = P_RANK_NUM ;
RETURN L_NEED_BY;
    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
     --raise_application_error(-20001,'This need by date is having two po numbers - '||SQLCODE||' -ERROR- '||SQLERRM);
     l_need_by :='More than one PO Same Need By Date';
   return l_need_by;
end XXSS_NEED_BY_DATE; 
/


GRANT EXECUTE ON APPS.XXSS_NEED_BY_DATE TO XXAPPSREAD;
