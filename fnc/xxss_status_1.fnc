DROP FUNCTION APPS.XXSS_STATUS_1;

CREATE OR REPLACE FUNCTION APPS.XXSS_STATUS_1(P_ITEM_ID NUMBER)
RETURN varchar2
as
L_STATUS varchar2(200);
begin
SELECT   DECODE(NEED_BY,'Jan','JANUARY','Feb','FEBRUARY','Mar','MARCH','Apr','APRIL','May','MAY','Jun','JUNE','Jul','JULY',
              'Aug','AUGUST','Sep','SEPTEMBER','Oct','OCTOBER','Nov','NOVEMBER','Dec','DECEMBER') INTO L_STATUS
              FROM   (SELECT   TO_CHAR(PLL.NEED_BY_DATE,'Mon') NEED_BY,
                               MSI.INVENTORY_ITEM_ID INVENTORY_ITEM,
                               ORGANIZATION_ID ORGANIZATION,
                               RANK ()
                                  OVER (PARTITION BY MSI.SEGMENT1
                                        ORDER BY PLL.NEED_BY_DATE)
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
                     AND A.INVENTORY_ITEM =P_ITEM_ID
                     AND RANK = 1;
RETURN L_status;
    EXCEPTION
    WHEN TOO_MANY_ROWS THEN
     --raise_application_error(-20001,'This need by date is having two po numbers - '||SQLCODE||' -ERROR- '||SQLERRM);
     l_status :='More than one PO Same Need By Date';
   RETURN L_STATUS;
end XXSS_STATUS_1;
/


GRANT EXECUTE ON APPS.XXSS_STATUS_1 TO XXAPPSREAD;
