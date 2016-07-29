DROP PACKAGE BODY APPS.XXSS_WSH_WSHRDBSR_XMLP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.XXSS_WSH_WSHRDBSR_XMLP_PKG AS
/* $Header: WSHRDBSRB.pls 120.3 2008/02/20 07:31:51 dwkrishn noship $ */
  FUNCTION BEFOREREPORT RETURN BOOLEAN IS
  BEGIN
    BEGIN
      P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
      /*SRW.USER_EXIT('FND SRWINIT')*/NULL;
    EXCEPTION
      WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
        /*SRW.MESSAGE(1
                   ,'Failed FND SRWINIT.')*/NULL;
        /*RAISE SRW.PROGRAM_ABORT*/RAISE_APPLICATION_ERROR(-20101,null);
    END;
    BEGIN
      DECLARE
        L_REPORT_NAME VARCHAR2(240);
      BEGIN
        SELECT
          CP.USER_CONCURRENT_PROGRAM_NAME
        INTO L_REPORT_NAME
        FROM
          FND_CONCURRENT_PROGRAMS_VL CP,
          FND_CONCURRENT_REQUESTS CR
        WHERE CR.REQUEST_ID = P_CONC_REQUEST_ID
          AND CP.APPLICATION_ID = CR.PROGRAM_APPLICATION_ID
          AND CP.CONCURRENT_PROGRAM_ID = CR.CONCURRENT_PROGRAM_ID;
        RP_REPORT_NAME := L_REPORT_NAME;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RP_REPORT_NAME := 'Backorder Summary Report';
      END;
    END;
    IF P_ORDER_NUM_HIGH IS NOT NULL THEN
      RP_ORDER_NUM_HIGH := P_ORDER_NUM_HIGH;
    END IF;
    IF P_ORDER_NUM_LOW IS NOT NULL THEN
      RP_ORDER_NUM_LOW := P_ORDER_NUM_LOW;
    END IF;
    RETURN (TRUE);
  END BEFOREREPORT;

  FUNCTION AFTERREPORT RETURN BOOLEAN IS
  BEGIN
    BEGIN
    P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
      /*SRW.USER_EXIT('FND SRWEXIT')*/NULL;
    EXCEPTION
      WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
        /*SRW.MESSAGE(1
                   ,'Failed in SRWEXIT')*/NULL;
        RAISE;
    end;

     BEGIN
    DECLARE
    N_REQUEST_ID NUMBER;
BEGIN
N_REQUEST_ID := FND_REQUEST.SUBMIT_REQUEST('XDO'
,'XDOBURSTREP'
,NULL
,NULL
,FALSE
,'Y'
,P_CONC_REQUEST_ID
,'N'
);
END;
END;

    RETURN (TRUE);
  END AFTERREPORT;

  FUNCTION P_ORGANIZATION_IDVALIDTRIGGER RETURN BOOLEAN IS
  BEGIN
    RETURN (TRUE);
  END P_ORGANIZATION_IDVALIDTRIGGER;

  FUNCTION P_ITEM_FLEX_CODEVALIDTRIGGER RETURN BOOLEAN IS
  BEGIN
    RETURN (TRUE);
  END P_ITEM_FLEX_CODEVALIDTRIGGER;

  FUNCTION AFTERPFORM RETURN BOOLEAN IS
  BEGIN
    DECLARE
      CURSOR STRUCT_NUM(FLEX_CODE IN VARCHAR2) IS
        SELECT
          ID_FLEX_NUM
        FROM
          FND_ID_FLEX_STRUCTURES
        WHERE ID_FLEX_CODE = FLEX_CODE;
      STRUCT_NUMBER NUMBER;
    BEGIN
      BEGIN
        P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
        /*SRW.USER_EXIT('FND SRWINIT')*/NULL;
      EXCEPTION
        WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
          /*SRW.MESSAGE(1000
                     ,'Failed in After Form trigger')*/NULL;
          RETURN (FALSE);
      END;
      IF P_ORGANIZATION_ID IS NOT NULL THEN
        LP_ORGANIZATION_ID := '  and  wdd.organization_id = :p_organization_id ';
      END IF;
      IF P_ORDER_NUM_HIGH IS NOT NULL AND P_ORDER_NUM_LOW IS NOT NULL THEN
        LP_HEADER_NUMBER := ' AND  to_number(wdd.source_header_number) between :p_order_num_low' || ' and :p_order_num_high ';
      ELSIF (P_ORDER_NUM_LOW IS NOT NULL) THEN
        LP_HEADER_NUMBER := ' and to_number(wdd.source_header_number) >= :p_order_num_low ';
      ELSIF (P_ORDER_NUM_HIGH IS NOT NULL) THEN
        LP_HEADER_NUMBER := ' and to_number(wdd.source_header_number) <= :p_order_num_high ';
      END IF;
      IF (P_TRANSACTION_TYPE_ID IS NOT NULL) THEN
        BEGIN
          SELECT
            NAME
          INTO RP_ORDER_TYPE_NAME
          FROM
            OE_TRXT_TYPES_NOORGS_VL
          WHERE TRANSACTION_TYPE_ID = P_TRANSACTION_TYPE_ID;
          LP_ORDER_TYPE := ' and wdd.source_header_type_id = :p_transaction_type_id ';
        END;
      END IF;
      IF P_ITEM_DISPLAY = 'D' THEN
        LP_ITEM_DISPLAY_VALUE := 'wdd.item_description';
      ELSE
        LP_ITEM_DISPLAY_VALUE := 'to_char(wdd.inventory_item_id)';
      END IF;
      OPEN STRUCT_NUM(P_ITEM_FLEX_CODE);
      FETCH STRUCT_NUM
       INTO STRUCT_NUMBER;
      CLOSE STRUCT_NUM;
      LP_STRUCTURE_NUM := STRUCT_NUMBER;
    END;
    RETURN (TRUE);
  END AFTERPFORM;

  FUNCTION C_SET_LBLFORMULA RETURN VARCHAR2 IS
  BEGIN
    DECLARE
      L_DATE VARCHAR2(11);
      H_DATE VARCHAR2(11);
    BEGIN
      IF P_HEADER_ID_LOW IS NOT NULL OR P_HEADER_ID_HIGH IS NOT NULL THEN
        DECLARE
          L_ORDER_NUM_LOW VARCHAR2(80);
          L_ORDER_NUM_HIGH VARCHAR2(80);
        BEGIN
          IF P_HEADER_ID_LOW IS NOT NULL THEN
            SELECT
              ORDER_NUMBER
            INTO L_ORDER_NUM_LOW
            FROM
              OE_ORDER_HEADERS_ALL
            WHERE HEADER_ID = P_HEADER_ID_LOW;
          END IF;
          IF P_HEADER_ID_HIGH IS NOT NULL THEN
            SELECT
              ORDER_NUMBER
            INTO L_ORDER_NUM_HIGH
            FROM
              OE_ORDER_HEADERS_ALL
            WHERE HEADER_ID = P_HEADER_ID_HIGH;
          END IF;
          RP_ORDER_RANGE := 'From ' || NVL(L_ORDER_NUM_LOW
                               ,'     ') || ' To ' || NVL(L_ORDER_NUM_HIGH
                               ,'     ');
          RP_ORDER_NUM_LOW := L_ORDER_NUM_LOW;
          RP_ORDER_NUM_HIGH := L_ORDER_NUM_HIGH;
        END;
      END IF;
      DECLARE
        ITEM_DISPLAY_MEANING VARCHAR2(80);
      BEGIN
        SELECT
          MEANING
        INTO ITEM_DISPLAY_MEANING
        FROM
          SO_LOOKUPS
        WHERE LOOKUP_TYPE = 'ITEM_DISPLAY'
          AND LOOKUP_CODE = P_ITEM_DISPLAY;
        RP_FLEX_OR_DESC := ITEM_DISPLAY_MEANING;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RP_FLEX_OR_DESC := NULL;
      END;
      IF P_ORGANIZATION_ID IS NOT NULL THEN
        DECLARE
          WAREHOUSE_NAME HR_ORGANIZATION_UNITS.NAME%TYPE;
        BEGIN
          SELECT
            NAME
          INTO WAREHOUSE_NAME
          FROM
            HR_ORGANIZATION_UNITS
          WHERE ORGANIZATION_ID = P_ORGANIZATION_ID;
          RP_WAREHOUSE := WAREHOUSE_NAME;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RP_WAREHOUSE := NULL;
        END;
      END IF;
      RETURN (1);
    END;
    RETURN NULL;
  END C_SET_LBLFORMULA;
/* Added by Prasanna Sunkad for ticket 2751*/
  FUNCTION CF_EMAIL_ID RETURN VARCHAR2  IS
  v_mail_id varchar2(2000);
  CURSOR EC IS SELECT MEANING FROM FND_LOOKUP_VALUES_VL WHERE LOOKUP_TYPE='XXSS_BOS_MAILID' AND ENABLED_FLAG = 'Y';
  C_MAIL FND_LOOKUP_VALUES_VL.MEANING%TYPE;
  BEGIN
OPEN EC;
 LOOP
 FETCH EC INTO C_MAIL;
 EXIT WHEN EC%NOTFOUND;
 V_MAIL_ID:=RTRIM((C_MAIL||','||V_MAIL_ID),',');
 END LOOP;
 RETURN V_MAIL_ID;
 END CF_EMAIL_ID;

 FUNCTION CF_EMAIL_SERVER RETURN VARCHAR2  IS
  V_EMAIL_SERVER VARCHAR2(2000);
  BEGIN
   SELECT  PARAMETER_VALUE             --azorasmtp000
        INTO  V_EMAIL_SERVER
        FROM  fnd_svc_comp_param_vals pv
             ,fnd_svc_comp_params_b pb
       WHERE  PV.PARAMETER_ID = PB.PARAMETER_ID
         AND  PARAMETER_NAME = 'OUTBOUND_SERVER';
 RETURN V_EMAIL_SERVER;
 END CF_EMAIL_SERVER;

 FUNCTION CF_MESSAGE RETURN VARCHAR2  IS
  V_MESSAGE VARCHAR2(5000);
  BEGIN
   V_MESSAGE:='Hi,

Please find your Back Order Summary Report attached.

Thanks';
 RETURN V_MESSAGE;
 END CF_MESSAGE;
/*-----------------------------------------------------*/
  FUNCTION CF_ITEM_DESCRIPTIONFORMULA(INVENTORY_ITEM_ID1 IN NUMBER
                                     ,ORGANIZATION_ID IN NUMBER
                                     ,ITEM_DESCRIPTION IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    DECLARE
      CURSOR INVENTORY_LABEL(ID IN NUMBER,ORG_ID IN NUMBER) IS
        SELECT
          DESCRIPTION
        FROM
          MTL_SYSTEM_ITEMS_VL
        WHERE INVENTORY_ITEM_ID = ID
          AND ORGANIZATION_ID = ORG_ID;
      NAME VARCHAR2(800);
    BEGIN
      IF P_ITEM_DISPLAY = 'D' THEN
        IF INVENTORY_ITEM_ID1 IS NOT NULL THEN
          OPEN INVENTORY_LABEL(INVENTORY_ITEM_ID1,ORGANIZATION_ID);
          FETCH INVENTORY_LABEL
           INTO NAME;
          CLOSE INVENTORY_LABEL;
        ELSE
          NAME := ITEM_DESCRIPTION;
        END IF;
      ELSIF P_ITEM_DISPLAY = 'F' THEN
        NAME := WSH_UTIL_CORE.GET_ITEM_NAME(INVENTORY_ITEM_ID1
                                           ,ORGANIZATION_ID
                                           ,P_ITEM_FLEX_CODE
                                           ,LP_STRUCTURE_NUM);
      ELSE
        IF INVENTORY_ITEM_ID1 IS NOT NULL THEN
          OPEN INVENTORY_LABEL(INVENTORY_ITEM_ID1,ORGANIZATION_ID);
          FETCH INVENTORY_LABEL
           INTO NAME;
          CLOSE INVENTORY_LABEL;
        ELSE
          NAME := ITEM_DESCRIPTION;
        END IF;
        NAME := WSH_UTIL_CORE.GET_ITEM_NAME(INVENTORY_ITEM_ID1
                                           ,ORGANIZATION_ID
                                           ,P_ITEM_FLEX_CODE
                                           ,LP_STRUCTURE_NUM) || '     ' || NAME;
      END IF;
      RETURN NAME;
    END;
    RETURN NULL;
  END CF_ITEM_DESCRIPTIONFORMULA;

  FUNCTION CF_BO_AMTFORMULA(BACKORDERED_QUANTITY IN NUMBER
                           ,UNIT_PRICE IN NUMBER) RETURN NUMBER IS
    BO_AMT NUMBER;
  BEGIN
    BO_AMT := TRUNC((NVL(BACKORDERED_QUANTITY
                       ,0) * NVL(UNIT_PRICE
                       ,0))
                   ,4);
    RETURN (BO_AMT);
  END CF_BO_AMTFORMULA;

  FUNCTION CF_SHIPPED_AMTFORMULA(CF_SHIPPED_QTY IN NUMBER
                                ,UNIT_PRICE IN NUMBER) RETURN NUMBER IS
    SHIPPED_AMT NUMBER;
  BEGIN
    SHIPPED_AMT := TRUNC((NVL(CF_SHIPPED_QTY
                            ,0) * NVL(UNIT_PRICE
                            ,0))
                        ,4);
    RETURN (SHIPPED_AMT);
  END CF_SHIPPED_AMTFORMULA;

  --FUNCTION CF_WAREHOUSEFORMULA(ORGANIZATION_ID IN NUMBER) RETURN CHAR IS
  FUNCTION CF_WAREHOUSEFORMULA(ORGANIZATION_ID_V IN NUMBER) RETURN CHAR IS
    WAREHOUSE_NAME HR_ORGANIZATION_UNITS.NAME%TYPE;
  BEGIN
    SELECT
      NAME
    INTO WAREHOUSE_NAME
    FROM
      HR_ORGANIZATION_UNITS
    WHERE ORGANIZATION_ID = ORGANIZATION_ID_V;
    RETURN (WAREHOUSE_NAME);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN (NULL);
  END CF_WAREHOUSEFORMULA;

  FUNCTION CF_SHIPPED_QTYFORMULA(CURRENCY_CODE_V IN VARCHAR2
                                ,ORGANIZATION_ID_V IN NUMBER
                                ,INVENTORY_ITEM_ID1 IN NUMBER
                                ,SOURCE_HEADER_NUMBER_V IN VARCHAR2
                                ,ORDER_TYPE IN VARCHAR2
                                ,REQUESTED_QUANTITY_UOM_V IN VARCHAR2
                                ,UNIT_PRICE_V IN NUMBER) RETURN NUMBER IS
    SHP_QTY NUMBER;
  BEGIN
    IF CURRENCY_CODE_V IS NOT NULL THEN
      SELECT
        SUM(NVL(SHIPPED_QUANTITY
               ,0))
      INTO SHP_QTY
      FROM
        WSH_DELIVERY_DETAILS
      WHERE ORGANIZATION_ID = ORGANIZATION_ID_V
        AND INVENTORY_ITEM_ID = INVENTORY_ITEM_ID1
        AND SOURCE_HEADER_NUMBER = SOURCE_HEADER_NUMBER_V
        AND SOURCE_HEADER_TYPE_NAME = ORDER_TYPE
        AND RELEASED_STATUS = 'C'
        AND SOURCE_CODE = 'OE'
        AND REQUESTED_QUANTITY_UOM = REQUESTED_QUANTITY_UOM_V
        AND CURRENCY_CODE = CURRENCY_CODE_V
        AND UNIT_PRICE = UNIT_PRICE_V;
      RETURN (SHP_QTY);
    ELSE
      SELECT
        SUM(NVL(SHIPPED_QUANTITY
               ,0))
      INTO SHP_QTY
      FROM
        WSH_DELIVERY_DETAILS
      WHERE ORGANIZATION_ID = ORGANIZATION_ID_V
        AND INVENTORY_ITEM_ID = INVENTORY_ITEM_ID1
        AND SOURCE_HEADER_NUMBER = SOURCE_HEADER_NUMBER_V
        AND SOURCE_HEADER_TYPE_NAME = ORDER_TYPE
        AND RELEASED_STATUS = 'C'
        AND SOURCE_CODE = 'OE'
        AND REQUESTED_QUANTITY_UOM = REQUESTED_QUANTITY_UOM_V
        AND UNIT_PRICE = UNIT_PRICE_V;
      RETURN (SHP_QTY);
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN (0);
  END CF_SHIPPED_QTYFORMULA;

  FUNCTION CF_LAST_SHIPPED_DATEFORMULA(ORGANIZATION_ID IN NUMBER
                                      ,SOURCE_HEADER_NUMBER IN VARCHAR2) RETURN DATE IS
    CURSOR C_LAST_SHIPPED_DATE(P_ORGANIZATION_ID IN NUMBER,P_SOURCE_HEADER_NUMBER IN VARCHAR2) IS
      SELECT
        MAX(WTS.ACTUAL_DEPARTURE_DATE) LAST_SHIPPED_DATE
      FROM
        WSH_DELIVERY_DETAILS WDD,
        WSH_DELIVERY_ASSIGNMENTS_V WDA,
        WSH_DELIVERY_LEGS WDL,
        WSH_TRIP_STOPS WTS
      WHERE WDD.RELEASED_STATUS in ( 'C' , 'I' )
        AND WDD.SOURCE_CODE = 'OE'
        AND WDD.DELIVERY_DETAIL_ID = WDA.DELIVERY_DETAIL_ID
        AND NVL(WDD.LINE_DIRECTION
         ,'O') IN ( 'O' , 'IO' )
        AND WDA.DELIVERY_ID = wdl.delivery_id (+)
        AND WDL.PICK_UP_STOP_ID = wts.stop_id (+)
        AND WDD.ORGANIZATION_ID = P_ORGANIZATION_ID
        AND WDD.SOURCE_HEADER_NUMBER = P_SOURCE_HEADER_NUMBER;
    L_LAST_SHIPPED_DATE DATE;
  BEGIN
    OPEN C_LAST_SHIPPED_DATE(ORGANIZATION_ID,SOURCE_HEADER_NUMBER);
    FETCH C_LAST_SHIPPED_DATE
     INTO L_LAST_SHIPPED_DATE;
    CLOSE C_LAST_SHIPPED_DATE;
    RETURN L_LAST_SHIPPED_DATE;
  END CF_LAST_SHIPPED_DATEFORMULA;

  FUNCTION RP_REPORT_NAME_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_REPORT_NAME;
  END RP_REPORT_NAME_P;

  FUNCTION RP_SUB_TITLE_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_SUB_TITLE;
  END RP_SUB_TITLE_P;

  FUNCTION RP_COMPANY_NAME_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_COMPANY_NAME;
  END RP_COMPANY_NAME_P;

  FUNCTION RP_DATA_FOUND_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_DATA_FOUND;
  END RP_DATA_FOUND_P;

  FUNCTION RP_ITEM_FLEX_ALL_SEG_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_ITEM_FLEX_ALL_SEG;
  END RP_ITEM_FLEX_ALL_SEG_P;

  FUNCTION RP_ORDER_RANGE_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_ORDER_RANGE;
  END RP_ORDER_RANGE_P;

  FUNCTION RP_ORDER_BY_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_ORDER_BY;
  END RP_ORDER_BY_P;

  FUNCTION RP_FLEX_OR_DESC_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_FLEX_OR_DESC;
  END RP_FLEX_OR_DESC_P;

  FUNCTION RP_WAREHOUSE_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_WAREHOUSE;
  END RP_WAREHOUSE_P;

  FUNCTION RP_ORDER_NUM_LOW_P RETURN NUMBER IS
  BEGIN
    RETURN RP_ORDER_NUM_LOW;
  END RP_ORDER_NUM_LOW_P;

  FUNCTION RP_ORDER_NUM_HIGH_P RETURN NUMBER IS
  BEGIN
    RETURN RP_ORDER_NUM_HIGH;
  END RP_ORDER_NUM_HIGH_P;

  PROCEDURE SET_NAME(APPLICATION IN VARCHAR2
                    ,NAME IN VARCHAR2) IS
  BEGIN
/*    STPROC.INIT('begin FND_MESSAGE.SET_NAME(:APPLICATION, :NAME); end;');
    STPROC.BIND_I(APPLICATION);
    STPROC.BIND_I(NAME);
    STPROC.EXECUTE;*/null;
  END SET_NAME;

  PROCEDURE SET_TOKEN(TOKEN IN VARCHAR2
                     ,VALUE IN VARCHAR2
                     ,TRANSLATE IN BOOLEAN) IS
  BEGIN
    /*STPROC.INIT('declare TRANSLATE BOOLEAN; begin TRANSLATE := sys.diutil.int_to_bool(:TRANSLATE); FND_MESSAGE.SET_TOKEN(:TOKEN, :VALUE, TRANSLATE); end;');
    STPROC.BIND_I(TRANSLATE);
    STPROC.BIND_I(TOKEN);
    STPROC.BIND_I(VALUE);
    STPROC.EXECUTE;*/null;
  END SET_TOKEN;

  PROCEDURE RETRIEVE(MSGOUT OUT NOCOPY VARCHAR2) IS
  BEGIN
    /*STPROC.INIT('begin FND_MESSAGE.RETRIEVE(:MSGOUT); end;');
    STPROC.BIND_O(MSGOUT);
    STPROC.EXECUTE;
    STPROC.RETRIEVE(1
                   ,MSGOUT);*/null;
  END RETRIEVE;

  PROCEDURE CLEAR IS
  BEGIN
    /*STPROC.INIT('begin FND_MESSAGE.CLEAR; end;');
    STPROC.EXECUTE;*/null;
  END CLEAR;

  FUNCTION GET_STRING(APPIN IN VARCHAR2
                     ,NAMEIN IN VARCHAR2) RETURN VARCHAR2 IS
    X0 VARCHAR2(2000);
  BEGIN
   /* STPROC.INIT('begin :X0 := FND_MESSAGE.GET_STRING(:APPIN, :NAMEIN); end;');
    STPROC.BIND_O(X0);
    STPROC.BIND_I(APPIN);
    STPROC.BIND_I(NAMEIN);
    STPROC.EXECUTE;
    STPROC.RETRIEVE(1
                   ,X0);*/null;
    RETURN X0;
  END GET_STRING;

  FUNCTION GET_NUMBER(APPIN IN VARCHAR2
                     ,NAMEIN IN VARCHAR2) RETURN NUMBER IS
    X0 NUMBER;
  BEGIN
    /*STPROC.INIT('begin :X0 := FND_MESSAGE.GET_NUMBER(:APPIN, :NAMEIN); end;');
    STPROC.BIND_O(X0);
    STPROC.BIND_I(APPIN);
    STPROC.BIND_I(NAMEIN);
    STPROC.EXECUTE;
    STPROC.RETRIEVE(1
                   ,X0);*/null;
    RETURN X0;
  END GET_NUMBER;

  FUNCTION GET RETURN VARCHAR2 IS
    X0 VARCHAR2(2000);
  BEGIN
    /*STPROC.INIT('begin :X0 := FND_MESSAGE.GET; end;');
    STPROC.BIND_O(X0);
    STPROC.EXECUTE;
    STPROC.RETRIEVE(1
                   ,X0);*/null;
    RETURN X0;
  END GET;

  FUNCTION GET_ENCODED RETURN VARCHAR2 IS
    X0 VARCHAR2(2000);
  BEGIN
    /*STPROC.INIT('begin :X0 := FND_MESSAGE.GET_ENCODED; end;');
    STPROC.BIND_O(X0);
    STPROC.EXECUTE;
    STPROC.RETRIEVE(1
                   ,X0);*/null;
    RETURN X0;
  END GET_ENCODED;

  PROCEDURE PARSE_ENCODED(ENCODED_MESSAGE IN VARCHAR2
                         ,APP_SHORT_NAME OUT NOCOPY VARCHAR2
                         ,MESSAGE_NAME OUT NOCOPY VARCHAR2) IS
  BEGIN
   /* STPROC.INIT('begin FND_MESSAGE.PARSE_ENCODED(:ENCODED_MESSAGE, :APP_SHORT_NAME, :MESSAGE_NAME); end;');
    STPROC.BIND_I(ENCODED_MESSAGE);
    STPROC.BIND_O(APP_SHORT_NAME);
    STPROC.BIND_O(MESSAGE_NAME);
    STPROC.EXECUTE;
    STPROC.RETRIEVE(2
                   ,APP_SHORT_NAME);
    STPROC.RETRIEVE(3
                   ,MESSAGE_NAME);*/null;
  END PARSE_ENCODED;

  PROCEDURE SET_ENCODED(ENCODED_MESSAGE IN VARCHAR2) IS
  BEGIN
    /*STPROC.INIT('begin FND_MESSAGE.SET_ENCODED(:ENCODED_MESSAGE); end;');
    STPROC.BIND_I(ENCODED_MESSAGE);
    STPROC.EXECUTE;*/null;
  END SET_ENCODED;

  PROCEDURE RAISE_ERROR IS
  BEGIN
    /*STPROC.INIT('begin FND_MESSAGE.RAISE_ERROR; end;');
    STPROC.EXECUTE;*/null;
  END RAISE_ERROR;

END XXSS_WSH_WSHRDBSR_XMLP_PKG;
/