DROP PACKAGE BODY APPS.XXO2C_RECALL_TRACE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXO2C_RECALL_TRACE_PKG" AS
/* $Header: OEXOHOHSB.pls 120.2 2008/05/05 06:39:36 dwkrishn noship $ */

  FUNCTION ORG_NAMEFORMULA RETURN VARCHAR2 IS
  BEGIN
    DECLARE
      ORG_NAME VARCHAR2(50);


   BEGIN

      -- Added by Meghana:
      SELECT name
        INTO ORG_NAME
        FROM hr_operating_units
       WHERE organization_id = p_org_id ;



      RETURN (ORG_NAME);
      EXCEPTION
        WHEN OTHERS Then
        RETURN NULL;
    END;
    RETURN NULL;
  END ORG_NAMEFORMULA;

  FUNCTION BEFOREREPORT RETURN BOOLEAN IS



  BEGIN

    --P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
    /*SRW.USER_EXIT('FND SRWINIT')*/NULL;
    BEGIN
      --P_ORG_ID := MO_GLOBAL.GET_CURRENT_ORG_ID;
      NULL;
    END;

    BEGIN
      NULL;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

    RETURN (TRUE);
  END BEFOREREPORT;



    FUNCTION AFTERPFORM RETURN BOOLEAN IS
  BEGIN
    /*SRW.MESSAGE(99999
               ,'$Header: ONT_OEXOHOHS_XMLP_PKG.rdf 120.4 2005/08/26 05:29 maysriva ship
           $')*/NULL;

    --Added by Meghana:
    BEGIN

        IF (P_ORDER_TYPE1 IS NOT NULL) OR (P_ORDER_TYPE2 IS NOT NULL) OR (P_ORDER_TYPE3 IS NOT NULL) OR (P_ORDER_TYPE4 IS NOT NULL)
                              OR (P_ORDER_TYPE5 IS NOT NULL) THEN
            LP_ORDTYPE_WHERE := 'and upper(oeh.order_type) in (upper(:P_ORDER_TYPE1) ,upper(:P_ORDER_TYPE2), upper(:P_ORDER_TYPE3), upper(:P_ORDER_TYPE4), upper(:P_ORDER_TYPE5))';

          ELSE
            LP_ORDTYPE_WHERE := NULL;
          END IF;
        IF (LP_ORDTYPE_WHERE IS NULL) THEN

        LP_ORDTYPE_WHERE := ' '; --Should print for all orders if Order Type is not mentioned by the user.
        END IF;

    END;


    BEGIN

        IF (P_ITEM_NUMBER1 IS NOT NULL) OR (P_ITEM_NUMBER2 IS NOT NULL) OR (P_ITEM_NUMBER3 IS NOT NULL) OR (P_ITEM_NUMBER4 IS NOT NULL)
                              OR (P_ITEM_NUMBER5 IS NOT NULL) THEN
            LP_ITEMNUM_WHERE := 'and upper(oel.ordered_item) in (upper(:P_ITEM_NUMBER1) ,upper(:P_ITEM_NUMBER2), upper(:P_ITEM_NUMBER3), upper(:P_ITEM_NUMBER4), upper(:P_ITEM_NUMBER5))';
          ELSE
            LP_ITEMNUM_WHERE := NULL;

          END IF;
        IF (LP_ITEMNUM_WHERE IS NULL) THEN

        LP_ITEMNUM_WHERE := ' '; --Should print for all Items if Item number is not mentioned by the user.
        END IF;

    END;


    BEGIN

        IF (P_LOT_NUMBER1 IS NOT NULL) OR (P_LOT_NUMBER2 IS NOT NULL) OR (P_LOT_NUMBER3 IS NOT NULL) OR (P_LOT_NUMBER4 IS NOT NULL)
                              OR (P_LOT_NUMBER5 IS NOT NULL) THEN
            LP_LOTNUM_WHERE := 'and upper(mtln.lot_number) in (upper(:P_LOT_NUMBER1) ,upper(:P_LOT_NUMBER2), upper(:P_LOT_NUMBER3), upper(:P_LOT_NUMBER4), upper(:P_LOT_NUMBER5))';

          ELSE
            LP_LOTNUM_WHERE := NULL;
          END IF;
        IF (LP_LOTNUM_WHERE IS NULL) THEN

        LP_LOTNUM_WHERE := ' '; --Should print for all lots if lot num is not mentioned by the user.
        END IF;

    END;

    BEGIN

        IF (P_SERIAL_NUMBER1 IS NOT NULL) OR (P_SERIAL_NUMBER2 IS NOT NULL) OR (P_SERIAL_NUMBER3 IS NOT NULL) OR (P_SERIAL_NUMBER4 IS NOT NULL)
                              OR (P_SERIAL_NUMBER5 IS NOT NULL) THEN
            LP_SERIALNUM_WHERE := 'and upper(mut.serial_number) in (upper(:P_SERIAL_NUMBER1) ,upper(:P_SERIAL_NUMBER2), upper(:P_SERIAL_NUMBER3), upper(:P_SERIAL_NUMBER4), upper(:P_SERIAL_NUMBER5))';

          ELSE
            LP_SERIALNUM_WHERE := NULL;
          END IF;
        IF (LP_SERIALNUM_WHERE IS NULL) THEN

        LP_SERIALNUM_WHERE := ' '; --Should print for all serials if serial num is not mentioned by the user.
        END IF;

    END;


    BEGIN

    IF P_ORDER_FROM_DATE IS NOT NULL AND P_ORDER_TO_DATE IS NOT NULL THEN

     LP_DATE_RANGE := ' and to_date(oeh.ordered_date,''DD-MON-YY'') between ' || 'to_date(''' || P_ORDER_FROM_DATE || ''',' || '''DD-MON-YY''' || ')' || ' and ' || 'to_date(''' || P_ORDER_TO_DATE || ''',' || '''DD-MON-YY''' || ')';

      ELSIF P_ORDER_FROM_DATE IS NOT NULL AND P_ORDER_TO_DATE IS NULL THEN
        LP_DATE_RANGE := 'and to_date(oeh.ordered_date,''DD-MON-YY'') >= ' || 'to_date(''' || P_ORDER_FROM_DATE || ''',' || '''DD-MON-YY''' || ')';
      ELSIF P_ORDER_FROM_DATE IS NULL AND P_ORDER_TO_DATE IS NOT NULL THEN
        LP_DATE_RANGE := 'and to_date(oeh.ordered_date,''DD-MON-YY'') <=  ' || 'to_date(''' || P_ORDER_TO_DATE || ''',' || '''DD-MON-YY''' || ')';
      ELSE
        LP_DATE_RANGE := ' ';
      END IF;

    IF (LP_DATE_RANGE IS NULL) THEN
    LP_DATE_RANGE := ' ';
    END IF;

    END;
    -- End of addition



    RETURN (TRUE);
  END AFTERPFORM;


END XXO2C_RECALL_TRACE_PKG;
/
