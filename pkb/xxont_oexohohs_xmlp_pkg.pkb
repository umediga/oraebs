DROP PACKAGE BODY APPS.XXONT_OEXOHOHS_XMLP_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXONT_OEXOHOHS_XMLP_PKG" AS
/* $Header: OEXOHOHSB.pls 120.2 2008/05/05 06:39:36 dwkrishn noship $ */
function Item_dspFormula(item_identifier_type_L varchar2,
                         c_master_org_L varchar2 ,
              inventory_item_id_L number,
              ordered_item_id_L number,
              ordered_item_L varchar2,
              ORGANIZATION_ID_L number) return Char is
v_item varchar2(2000);
v_description varchar2(500);
begin

  if (item_identifier_type_L is null or item_identifier_type_L = 'INT')
       or (p_flex_or_desc in ('I','D','F')) then
    select sitems.segment1, sitems.description description
    into   v_item,v_description
    from   mtl_system_items_vl sitems
    Where    nvl(sitems.organization_id,0) = c_master_org_L
    and    sitems.inventory_item_id = inventory_item_id_L;
/*         srw.reference (:item_flex);
         srw.reference (:p_item_flex_code);
         srw.reference (:Item_dsp);
         srw.reference (:p_item_structure_num);
         srw.user_exit (' FND FLEXIDVAL
            CODE=":p_item_flex_code"
            NUM=":p_item_structure_num"
            APPL_SHORT_NAME="INV"
            DATA= ":item_flex"
            VALUE=":Item_dsp"
            DISPLAY="ALL"'
        );   */

        -- removed by meg:
    --v_item := fnd_flex_xml_publisher_apis.process_kff_combination_1('Item_dsp', 'INV',p_item_flex_code,p_item_structure_num,ORGANIZATION_ID_L,INVENTORY_ITEM_ID_L, 'ALL', 'Y', 'VALUE');
    elsif (item_identifier_type_L = 'CUST' and p_flex_or_desc in ('C','P','O')) then
    select citems.customer_item_number item,
           nvl(citems.customer_item_desc,sitems.description) description
    into   v_item,v_description
    from   mtl_customer_items citems,
           mtl_customer_item_xrefs cxref,
           mtl_system_items_vl sitems
    where  citems.customer_item_id = cxref.customer_item_id
    and    cxref.inventory_item_id = sitems.inventory_item_id
    and    citems.customer_item_id = ordered_item_id_L
    and    nvl(sitems.organization_id,0) = c_master_org_L
    and    sitems.inventory_item_id = inventory_item_id_L;
--    and    sitems.customer_order_enabled_flag = 'Y'
--    and    sitems.bom_item_type in (1,4)
  elsif (p_flex_or_desc in ('C','P','O')) then
    Begin
    select items.cross_reference item,
           nvl(items.description,sitems.description) description
    into   v_item,v_description
    from   mtl_cross_reference_types xtypes,
           mtl_cross_references items,
           mtl_system_items_vl sitems
    where  xtypes.cross_reference_type = items.cross_reference_type
    and    items.inventory_item_id = sitems.inventory_item_id
    and    items.cross_reference = ordered_item_L
    and    items.cross_reference_type = item_identifier_type_L
    and    nvl(sitems.organization_id,0) = c_master_org_L
    and    sitems.inventory_item_id = inventory_item_id_L
-- Bug 3433353 Begin
    and items.org_independent_flag = 'N'
    and items.organization_id = c_master_org_L;
--    and    sitems.customer_order_enabled_flag = 'Y'
--    and    sitems.bom_item_type in (1,4)
    Exception When NO_DATA_FOUND Then
    select items.cross_reference item,
    nvl(items.description,sitems.description) description
    into v_item,v_description
    from mtl_cross_reference_types xtypes,
    mtl_cross_references items,
    mtl_system_items_vl sitems
    where xtypes.cross_reference_type =
    items.cross_reference_type
    and items.inventory_item_id =
     sitems.inventory_item_id
    and items.cross_reference = ordered_item_L
    and items.cross_reference_type = item_identifier_type_L
    and nvl(sitems.organization_id,0) = c_master_org_L
    and sitems.inventory_item_id = inventory_item_id_L
    and items.org_independent_flag = 'Y';
    End;
-- Bug 3422253 End
  end if;

  if (p_flex_or_desc in ('I','C')) then
    return(v_item||' - '||v_description);
  elsif (p_flex_or_desc in ('D','P')) then
    return(v_description);
  else
    return(v_item);
  end if;
RETURN NULL;
Exception
   When Others Then
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while fetching Item Display Formula');
        return('Item Not Found');
end;
  FUNCTION ORG_NAMEFORMULA RETURN VARCHAR2 IS
  BEGIN
    DECLARE
      ORG_NAME VARCHAR2(50);
      SOB_ID  VARCHAR2(30);--Added by Meg

    /*BEGIN
      select set_of_books_id
        into SOB_ID
        from hr_operating_units
       WHERE organization_id = p_org_id ;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;  */

   BEGIN

      -- Added by Meghana:
      SELECT name
        INTO ORG_NAME
        FROM hr_operating_units
       WHERE organization_id = p_org_id ;


      /*SELECT NAME
        INTO SOB_NAME
        FROM GL_SETS_OF_BOOKS
       WHERE SET_OF_BOOKS_ID = SOB_ID;*/

      RETURN (ORG_NAME);
      EXCEPTION
        WHEN OTHERS Then
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while fetching SOB Name.');
        RETURN NULL;
    END;
    RETURN NULL;
  END ORG_NAMEFORMULA;

  FUNCTION BEFOREREPORT RETURN BOOLEAN IS
  BEGIN
    P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
    /*SRW.USER_EXIT('FND SRWINIT')*/NULL;
    BEGIN
      P_ORG_ID := MO_GLOBAL.GET_CURRENT_ORG_ID;
    END;
    BEGIN
      NULL;
      /*SRW.REFERENCE(P_ITEM_STRUCTURE_NUM)*/NULL;
    EXCEPTION
      WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
        /*SRW.MESSAGE(1
                   ,'Failed in before report trigger:MSTK')*/NULL;
    END;
    IF P_ITEM_HI IS NULL AND P_ITEM_LO IS NULL THEN
      NULL;
    ELSE
      BEGIN
        NULL;
      EXCEPTION
        WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
          /*SRW.MESSAGE(2
                     ,'Failed in before report trigger:where:MSTK')*/NULL;
      END;
    END IF;
    RETURN (TRUE);
  END BEFOREREPORT;

  FUNCTION AFTERREPORT RETURN BOOLEAN IS
  BEGIN
    /*SRW.USER_EXIT('FND SRWEXIT')*/NULL;
    RETURN (TRUE);
  EXCEPTION
    WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
      /*SRW.MESSAGE(1
                 ,'FAILED IN AFTER REPORT TRIGGER')*/NULL;
      RETURN (FALSE);
  END AFTERREPORT;

  FUNCTION ITEM_DISPLAY_MEANINGFORMULA RETURN VARCHAR2 IS
  BEGIN
    DECLARE
      ITEM_DISPLAY_MEANING VARCHAR2(80);
    BEGIN
      SELECT
        MEANING
      INTO ITEM_DISPLAY_MEANING
      FROM
        OE_LOOKUPS
      WHERE LOOKUP_TYPE = 'ITEM_DISPLAY_CODE'
        AND LOOKUP_CODE = P_FLEX_OR_DESC;
      RETURN (ITEM_DISPLAY_MEANING);
    EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while fetching Item Display Meaning.');
    END;
    RETURN NULL;
  END ITEM_DISPLAY_MEANINGFORMULA;

  FUNCTION C_CUSTOMER_WHERE RETURN VARCHAR2 IS
  BEGIN
    IF P_CUST_NAME_LO IS NOT NULL AND P_CUST_NAME_HI IS NOT NULL THEN
      RETURN ('and org.name between ''' || P_CUST_NAME_LO || '''
                      and ''' || P_CUST_NAME_HI || ''' ');
    ELSE
      IF P_CUST_NAME_LO IS NULL AND P_CUST_NAME_HI IS NOT NULL THEN
        RETURN ('and org.name <= ''' || P_CUST_NAME_HI || ''' ');
      ELSE
        IF P_CUST_NAME_LO IS NOT NULL AND P_CUST_NAME_HI IS NULL THEN
          RETURN ('and org.name >= ''' || P_CUST_NAME_LO || ''' ');
        ELSE
          RETURN (NULL);
        END IF;
      END IF;
    END IF;
    RETURN NULL;
    EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in c_customer_where.');
  END C_CUSTOMER_WHERE;

  FUNCTION C_HOLD_WHERE RETURN VARCHAR2 IS
  BEGIN
    IF P_HOLD_NAME_LO IS NOT NULL AND P_HOLD_NAME_HI IS NOT NULL THEN
      RETURN ('and nvl(ho.name, ''ZZZ'') between :P_hold_name_lo
                                 and :P_hold_name_hi ');
    ELSE
      IF P_HOLD_NAME_LO IS NULL AND P_HOLD_NAME_HI IS NOT NULL THEN
        RETURN ('and nvl(ho.name, ''zzz'') <= :P_hold_name_hi');
      ELSE
        IF P_HOLD_NAME_LO IS NOT NULL AND P_HOLD_NAME_HI IS NULL THEN
          RETURN ('and nvl(ho.name, ''zzz'') >= :P_hold_name_lo ');
        ELSE
          RETURN (NULL);
        END IF;
      END IF;
    END IF;
    RETURN NULL;
    EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error in C_HOLD_WHERE.');
  END C_HOLD_WHERE;

  FUNCTION AFTERPFORM RETURN BOOLEAN IS
  BEGIN
    /*SRW.MESSAGE(99999
               ,'$Header: ONT_OEXOHOHS_XMLP_PKG.rdf 120.4 2005/08/26 05:29 maysriva ship
           $')*/NULL;
    BEGIN
      IF P_HOLD_NAME_LO IS NOT NULL AND P_HOLD_NAME_HI IS NOT NULL THEN
        LP_HOLD_WHERE := 'and ho.name between :P_hold_name_lo and :P_hold_name_hi';
        IF (P_HOLD_NAME_LO = P_HOLD_NAME_HI) THEN
          LP_HOLD_WHERE := 'and ho.name = :P_hold_name_lo ';
        END IF;
      ELSIF P_HOLD_NAME_LO IS NULL AND P_HOLD_NAME_HI IS NOT NULL THEN
        LP_HOLD_WHERE := 'and ho.name <= :P_hold_name_hi';
      ELSIF P_HOLD_NAME_LO IS NOT NULL AND P_HOLD_NAME_HI IS NULL THEN
        LP_HOLD_WHERE := 'and ho.name >= :P_hold_name_lo';
      ELSE
        LP_HOLD_WHERE := NULL;
      END IF;
    IF (LP_HOLD_WHERE IS NULL) THEN
    LP_HOLD_WHERE := ' ';
    END IF;

      IF P_CUST_NAME_LO IS NOT NULL AND P_CUST_NAME_HI IS NOT NULL THEN
        LP_CUSTOMER_WHERE := ' org.name between :P_cust_name_lo and :P_cust_name_hi';
        IF (P_CUST_NAME_LO = P_CUST_NAME_HI) THEN
          LP_CUSTOMER_WHERE := ' org.name = :P_cust_name_lo ';
        END IF;
      ELSIF P_CUST_NAME_LO IS NULL AND P_CUST_NAME_HI IS NOT NULL THEN
        LP_CUSTOMER_WHERE := ' org.name <= :P_cust_name_hi';
      ELSIF P_CUST_NAME_LO IS NOT NULL AND P_CUST_NAME_HI IS NULL THEN
        LP_CUSTOMER_WHERE := ' org.name >= :P_cust_name_lo';
      ELSE
        LP_CUSTOMER_WHERE := ' 1 = 1'; --NULL;
      END IF;
      EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while building LP_CUSTOMER_WHERE.');
    END;
    IF (LP_CUSTOMER_WHERE IS NULL) THEN
    LP_CUSTOMER_WHERE := ' ';
    END IF;

    --Added by Meghana:
    BEGIN

    IF P_ITEM_LO IS NOT NULL AND P_ITEM_HI IS NOT NULL THEN
        LP_ITEM_WHERE := ' and si.segment1 between :P_ITEM_LO and :P_ITEM_HI';
        IF (P_ITEM_LO = P_ITEM_HI) THEN
          LP_ITEM_WHERE := ' and si.segment1 = :P_ITEM_LO ';
        END IF;
      ELSIF P_ITEM_LO IS NULL AND P_ITEM_HI IS NOT NULL THEN
        LP_ITEM_WHERE := ' and si.segment1 <= :P_ITEM_HI';
      ELSIF P_ITEM_LO IS NOT NULL AND P_ITEM_HI IS NULL THEN
        LP_ITEM_WHERE := ' and si.segment1 >= :P_ITEM_LO';
      ELSE
        LP_ITEM_WHERE := NULL; --NULL;
      END IF;

    IF (LP_ITEM_WHERE IS NULL) THEN
    LP_ITEM_WHERE := ' ';
    END IF;
    EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while building LP_ITEM_WHERE.');
    END;
    -- End of addition


    --Added by Meghana:
    BEGIN

    IF P_ORDER_FROM_DATE IS NOT NULL AND P_ORDER_TO_DATE IS NOT NULL THEN

     LP_DATE_RANGE := ' and to_date(h.ordered_date,''DD-MON-YY'') between ' || 'to_date(''' || P_ORDER_FROM_DATE || ''',' || '''DD-MON-YY''' || ')' || ' and ' || 'to_date(''' || P_ORDER_TO_DATE || ''',' || '''DD-MON-YY''' || ')';

      ELSIF P_ORDER_FROM_DATE IS NOT NULL AND P_ORDER_TO_DATE IS NULL THEN
        LP_DATE_RANGE := 'and to_date(h.ordered_date,''DD-MON-YY'') >= ' || 'to_date(''' || P_ORDER_FROM_DATE || ''',' || '''DD-MON-YY''' || ')';
      ELSIF P_ORDER_FROM_DATE IS NULL AND P_ORDER_TO_DATE IS NOT NULL THEN
        LP_DATE_RANGE := 'and to_date(h.ordered_date,''DD-MON-YY'') <=  ' || 'to_date(''' || P_ORDER_TO_DATE || ''',' || '''DD-MON-YY''' || ')';
      ELSE
        LP_DATE_RANGE := ' ';
      END IF;

    IF (LP_DATE_RANGE IS NULL) THEN
    LP_DATE_RANGE := ' ';
    END IF;

    EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while building LP_DATE_RANGE.');
    END;
    -- End of addition



    RETURN (TRUE);
  END AFTERPFORM;

  FUNCTION C_LINE_OR_ORDERFORMULA(P_ORDER_HOLD_ID IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    /*SRW.REFERENCE(ORDER_HOLD_ID)*/NULL;
    DECLARE
      LINE_ID NUMBER;
    BEGIN
      SELECT
        LINE_ID
      INTO LINE_ID
      FROM
        OE_ORDER_HOLDS
      WHERE ORDER_HOLD_ID = P_ORDER_HOLD_ID;
      IF LINE_ID IS NOT NULL THEN
        RETURN ('LINE');
      ELSE
        RETURN ('ORDER');
      END IF;
      EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while selecting Line/Order.');
    END;
    RETURN NULL;
  END C_LINE_OR_ORDERFORMULA;

  FUNCTION C_SHOW_AMOUNTFORMULA(HEADER_ID IN NUMBER
                               ,C_LINE_OR_ORDER IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    DECLARE
      HEADER_ID_VAR NUMBER;
    BEGIN
      /*SRW.REFERENCE(HEADER_ID)*/NULL;
      /*SRW.REFERENCE(C_LINE_OR_ORDER)*/NULL;
      IF C_LINE_OR_ORDER = 'LINE' THEN
        SELECT
          HEADER_ID
        INTO HEADER_ID_VAR
        FROM
          OE_ORDER_HOLDS
        WHERE HEADER_ID = HEADER_ID
          AND LINE_ID is NULL
          AND HOLD_RELEASE_ID is NULL;
      END IF;
      IF HEADER_ID_VAR IS NOT NULL THEN
        RETURN ('N');
      ELSE
        RETURN ('Y');
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'No Data Found while deriving Header_id.');
        RETURN ('Y');
      WHEN TOO_MANY_ROWS THEN
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Too many rows while deriving Header Id.');
        RETURN ('N');
    END;
    RETURN NULL;
  END C_SHOW_AMOUNTFORMULA;

  FUNCTION C_MASTER_ORGFORMULA RETURN CHAR IS
    V_MASTER_ORG VARCHAR2(20);
  BEGIN
    /*SELECT
      NVL(OE_SYS_PARAMETERS.VALUE('MASTER_ORGANIZATION_ID'
                                 ,MO_GLOBAL.GET_CURRENT_ORG_ID)
         ,0)
    INTO V_MASTER_ORG
    FROM
      DUAL;*/ --commented by meg remove later

      SELECT organization_id
        INTO V_MASTER_ORG
        FROM mtl_parameters
       WHERE organization_code = 'MST';

    RETURN V_MASTER_ORG;
    EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while deriving Master Org.');
  END C_MASTER_ORGFORMULA;

  FUNCTION C_AMOUNTFORMULA(AMOUNT IN NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN (NVL(AMOUNT
              ,0));
  END C_AMOUNTFORMULA;

 /* FUNCTION C_FORMATTED_FLEX_VALUE_P RETURN VARCHAR2 IS
  BEGIN
    RETURN C_FORMATTED_FLEX_VALUE;
  END C_FORMATTED_FLEX_VALUE_P;

  FUNCTION RP_ITEM_FLEX_ALL_SEG_P RETURN VARCHAR2 IS
  BEGIN
    RETURN RP_ITEM_FLEX_ALL_SEG;
  END RP_ITEM_FLEX_ALL_SEG_P;*/

END XXONT_OEXOHOHS_XMLP_PKG;
/
