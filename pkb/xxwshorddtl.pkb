DROP PACKAGE BODY APPS.XXWSHORDDTL;

CREATE OR REPLACE PACKAGE BODY APPS.XXWSHORDDTL AS


  FUNCTION BEFOREREPORT RETURN BOOLEAN IS
  BEGIN
    P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
    /*SRW.USER_EXIT('FND SRWINIT')*/NULL;
    P_ORG_ID := MO_GLOBAL.GET_CURRENT_ORG_ID;
    BEGIN
      NULL;
      /*SRW.REFERENCE(P_ITEM_STRUCTURE_NUM)*/NULL;
    EXCEPTION
      WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
        /*SRW.MESSAGE(1
                   ,'Failed in before report trigger:MSTK')*/NULL;
    END;


      BEGIN
        NULL;
        LP_DIVISION_WHERE := ' AND division = ''' || P_DIVISION || ''' ' ;

        --**********

        LP_ORDER_TYPE_WHERE := ' -- ' || P_ORDER_TYPE  ;


        IF P_ORDER_TYPE IS NOT NULL THEN

          LP_ORDER_TYPE_WHERE :=
          ' AND ORDER_TYPE_ID = ' || P_ORDER_TYPE   ;
        END IF;

       --**********
       LP_CREATED_BY_WHERE := ' -- ' || P_CREATED_BY_FROM  ;
       IF P_CREATED_BY_FROM IS NOT NULL THEN
          IF P_CREATED_BY_TO IS NOT NULL THEN
             LP_CREATED_BY_WHERE :=
             ' AND CREATED_BY_ID BETWEEN ' || P_CREATED_BY_FROM   ||   ' AND '  ||  P_CREATED_BY_TO ;
          ELSE
              LP_CREATED_BY_WHERE :=
             ' AND CREATED_BY_ID >= ' || P_CREATED_BY_FROM   ;
          END IF;
       ELSIF 2=2 AND P_CREATED_BY_TO IS NOT NULL THEN
         LP_CREATED_BY_WHERE :=
         ' AND CREATED_BY_ID <= ' || P_CREATED_BY_TO   ;
       END IF;
      --**********

      --**********
      LP_SHIP_TO_CUSTOMER_WHERE := ' -- ' || P_SHIP_TO_CUSTOMER  ;
        IF P_SHIP_TO_CUSTOMER IS NOT NULL THEN
         -- IF P_SHIP_TO_CUSTOMER_TO IS NOT NULL THEN
         LP_SHIP_TO_CUSTOMER_WHERE :=
            ' AND SHIP_TO_ACCOUNT_NUMBER = ''' || P_SHIP_TO_CUSTOMER  || ''' ' ;
       END IF;

       --**********
             LP_BILL_TO_CUSTOMER_WHERE := ' -- ' || P_BILL_TO_CUSTOMER  ;
        IF P_BILL_TO_CUSTOMER IS NOT NULL THEN
         -- IF P_SHIP_TO_CUSTOMER_TO IS NOT NULL THEN
         LP_BILL_TO_CUSTOMER_WHERE :=
            ' AND SOLD_TO_ACCOUNT_NUMBER = ''' || P_BILL_TO_CUSTOMER  || ''' ' ;
       END IF;

       --**********
       LP_ORDER_DATE_WHERE := ' -- ' || P_ORDER_DATE_FROM  || ' -- ' || P_ORDER_DATE_TO  ;
       IF P_ORDER_DATE_FROM IS NOT NULL THEN
          IF P_ORDER_DATE_TO IS NOT NULL THEN
             LP_ORDER_DATE_WHERE :=
             ' AND SHIP_TO_STATE BETWEEN ' || P_ORDER_DATE_FROM   ||   ' AND '  ||  P_ORDER_DATE_TO ;
          ELSE
              LP_ORDER_DATE_WHERE :=
             ' AND SHIP_TO_STATE >= ' || P_ORDER_DATE_FROM   ;
         END IF;
       ELSIF 2=2 AND P_ORDER_DATE_TO IS NOT NULL THEN
         LP_ORDER_DATE_WHERE :=
         ' AND SHIP_TO_STATE <= ' || P_ORDER_DATE_TO   ;
       END IF;
       --**********
       --**********
       LP_SALES_REP_WHERE := ' -- ' || P_SALES_REP_FROM  || ' - - ' || P_SALES_REP_TO;
       IF P_SALES_REP_FROM IS NOT NULL THEN
          IF P_SALES_REP_TO IS NOT NULL THEN
             LP_SALES_REP_WHERE :=
             ' AND EXISTS (SELECT 1
                            FROM  oe_sales_credits sc , jtf_rs_salesreps rs
                           WHERE rs.salesrep_id = sc.salesrep_id
                             AND rs.name >= ''' || P_SALES_REP_FROM || ''' AND rs.name <= ''' || P_SALES_REP_TO ||
                         ''' AND (sc.line_id = line_id OR sc.header_id = header_id ))' ;
           ELSE
               LP_SALES_REP_WHERE :=
               ' AND EXISTS (SELECT 1
                               FROM  oe_sales_credits sc , jtf_rs_salesreps rs
                              WHERE rs.salesrep_id = sc.salesrep_id
                                AND rs.name >= ''' || P_SALES_REP_FROM  ||
                            ''' AND (sc.line_id = line_id OR sc.header_id = header_id ))' ;
           END IF;
       ELSIF 2=2 AND P_SALES_REP_TO IS NOT NULL THEN
               LP_SALES_REP_WHERE :=
               ' AND EXISTS (SELECT 1
                               FROM  oe_sales_credits sc , jtf_rs_salesreps rs
                              WHERE rs.salesrep_id = sc.salesrep_id
                                AND rs.name <= ''' || P_SALES_REP_TO  ||
                            ''' AND (sc.line_id = line_id OR sc.header_id = header_id ))' ;
       END IF;
       --**********
       --**********
       LP_TERRITORY_WHERE := ' --FROM:  ' || P_TERRITORY_FROM ||' TO: ' ||  P_TERRITORY_TO ;
       IF P_TERRITORY_FROM IS NOT NULL THEN
          IF P_TERRITORY_TO IS NOT NULL THEN
             LP_TERRITORY_WHERE :=
             ' AND TERRITORY BETWEEN ''' || P_TERRITORY_FROM   ||   ''' AND '''  ||  P_TERRITORY_TO || ''' ';
           ELSE
              LP_TERRITORY_WHERE :=
             ' AND TERRITORY >= ''' || P_TERRITORY_FROM  ||''' ' ;
          END IF;
       ELSIF 2=2 AND P_TERRITORY_TO IS NOT NULL THEN
         LP_TERRITORY_WHERE :=
         ' AND TERRITORY <= ''' || P_TERRITORY_TO || ''' ' ;
       END IF;
      --**********
            --**********
      LP_REGION_WHERE := ' --FROM:  ' || P_REGION_FROM ||' TO: ' ||  P_REGION_TO ;
      IF P_REGION_FROM IS NOT NULL THEN
         IF P_REGION_TO IS NOT NULL THEN
            LP_REGION_WHERE :=
            ' AND REGION BETWEEN ''' || P_REGION_FROM   ||   ''' AND '''  ||  P_REGION_TO || ''' ';
         ELSE
            LP_REGION_WHERE :=
            ' AND REGION >= ''' || P_REGION_FROM  ||''' ' ;
         END IF;
      ELSIF 2=2 AND P_REGION_TO IS NOT NULL THEN
         LP_REGION_WHERE :=
         ' AND REGION <= ''' || P_REGION_TO || ''' ' ;
      END IF;
      --**********

      --**********
      LP_SHIP_TO_STATE_WHERE := ' -- State FROM:  ' || P_SHIP_TO_STATE_FROM ||' TO: ' ||  P_SHIP_TO_STATE_TO ;
      IF P_SHIP_TO_STATE_FROM IS NOT NULL THEN
         IF P_SHIP_TO_STATE_TO IS NOT NULL THEN
            LP_SHIP_TO_STATE_WHERE :=
            ' AND SHIP_TO_STATE BETWEEN ''' || P_SHIP_TO_STATE_FROM   ||   ''' AND '''  ||  P_SHIP_TO_STATE_TO || ''' ';
         ELSE
            LP_SHIP_TO_STATE_WHERE :=
            ' AND SHIP_TO_STATE >= ''' || P_SHIP_TO_STATE_FROM  ||''' ' ;
         END IF;
      ELSIF 2=2 AND P_SHIP_TO_STATE_TO IS NOT NULL THEN
         LP_SHIP_TO_STATE_WHERE :=
         ' AND SHIP_TO_STATE <= ''' || P_SHIP_TO_STATE_TO || ''' ' ;
      END IF;
      --**********
      -- TO_DATE('2014/11/01 00:00:00','YYYY/MM/DD HH24:MI:SS');
            --**********
      LP_ORDER_DATE_WHERE := ' -- dATE### FROM:  ''' || P_ORDER_DATE_FROM ||''' TO: ''' ||  P_ORDER_DATE_TO ||''' ';
     IF  P_ORDER_DATE_FROM IS NOT NULL THEN
         IF P_ORDER_DATE_TO IS NOT NULL THEN
            LP_ORDER_DATE_WHERE :=
            ' AND ORDERED_DATE BETWEEN TO_DATE('''||P_ORDER_DATE_FROM||''',''YYYY/MM/DD HH24:MI:SS'') AND TO_DATE('''||P_ORDER_DATE_TO||''',''YYYY/MM/DD HH24:MI:SS'')';
         ELSE
            LP_ORDER_DATE_WHERE :=
            ' AND ORDERED_DATE >=  TO_DATE('''||P_ORDER_DATE_FROM||''',''YYYY/MM/DD HH24:MI:SS'') ';
         END IF;
      ELSIF 2=2 AND P_ORDER_DATE_TO IS NOT NULL THEN
         LP_ORDER_DATE_WHERE :=
         ' AND ORDERED_DATE <=  TO_DATE('''||P_ORDER_DATE_TO||''',''YYYY/MM/DD HH24:MI:SS'')' ;
      END IF;

      --**********
      LP_C_CODE_WHERE := ' -- ' || P_C_CODE_FROM  || ' -- ' || P_C_CODE_TO  ;
      IF P_C_CODE_FROM IS NOT NULL THEN
         IF P_C_CODE_TO IS NOT NULL THEN
             LP_C_CODE_WHERE :=
             ' AND CCODE BETWEEN ''' || P_C_CODE_FROM   ||   ''' AND '''  ||  P_C_CODE_TO || ''' ' ;
         ELSE
             LP_C_CODE_WHERE :=
             ' AND  CCODE >= ''' || P_C_CODE_FROM || ''' ' ;
         END IF;
      ELSIF 2=2 AND P_C_CODE_TO IS NOT NULL THEN
         LP_C_CODE_WHERE :=
         ' AND CCODE <= ''' || P_C_CODE_TO || ''' ' ;
      END IF;
      --**********
      --**********
      LP_D_CODE_WHERE := ' -- ' || P_D_CODE_FROM  || ' -- ' || P_D_CODE_TO || ''' ' ;
      IF P_D_CODE_FROM IS NOT NULL THEN
          IF P_D_CODE_TO IS NOT NULL THEN
             LP_D_CODE_WHERE :=
             ' AND DCODE BETWEEN ''' || P_D_CODE_FROM   ||  ''' AND '''  ||  P_D_CODE_TO || ''' ' ;
          ELSE
             LP_D_CODE_WHERE :=
             ' AND  DCODE >= ''' || P_D_CODE_FROM  || ''' ' ;
          END IF;
      ELSIF 2=2 AND P_D_CODE_TO IS NOT NULL THEN
          LP_D_CODE_WHERE :=
          ' AND DCODE <= ''' || P_D_CODE_TO  || ''' ' ;
      END IF;
      --**********
      --**********
      LP_HEADER_HOLD_WHERE  := ' -- ' || P_HEADER_HOLD_FROM  || ' - - ' || P_HEADER_HOLD_TO;
      IF P_HEADER_HOLD_FROM IS NOT NULL THEN
          IF P_HEADER_HOLD_TO IS NOT NULL THEN
             LP_HEADER_HOLD_WHERE :=
             ' AND EXISTS (SELECT 1
                            FROM apps.oe_order_holds_all  oh  , oe_hold_definitions hd
                           WHERE oh.order_hold_id = hd.hold_id
                             AND oh.header_id = rout.header_id
                             AND hd.name BETWEEN ''' || P_HEADER_HOLD_FROM|| ''' AND ''' || P_HEADER_HOLD_TO || ''')'
                                 ;
          ELSE
              LP_HEADER_HOLD_WHERE :=
              ' AND EXISTS (SELECT 1
                              FROM  apps.oe_order_holds_all  oh  , oe_hold_definitions hd
                             WHERE oh.order_hold_id = hd.hold_id
                               AND oh.header_id = rout.header_id
                               AND hd.name >= ''' || P_HEADER_HOLD_FROM  ||  ''')'
                                   ;
          END IF;
       ELSIF 2=2 AND P_HEADER_HOLD_TO IS NOT NULL THEN
               LP_HEADER_HOLD_WHERE:=
               ' AND EXISTS (SELECT 1
                               FROM  apps.oe_order_holds_all  oh  , oe_hold_definitions hd
                              WHERE oh.order_hold_id = hd.hold_id
                                 AND oh.header_id = rout.header_id
                                 AND hd.name <= ''' || P_HEADER_HOLD_TO  || ''')'
                              ;
       END IF;

     --**********
     --**********
     LP_LINE_HOLD_WHERE  := ' -- ' || P_SALES_REP_FROM  || ' - - ' || P_SALES_REP_TO;
     IF P_LINE_HOLD_FROM IS NOT NULL THEN
          IF P_LINE_HOLD_TO IS NOT NULL THEN
             LP_LINE_HOLD_WHERE :=
             ' AND EXISTS (SELECT 1
                            FROM  apps.oe_order_holds_all  oh  , oe_hold_definitions hd
                           WHERE oh.order_hold_id = hd.hold_id
                             AND oh.header_id = rout.header_id
                            AND hd.name BETWEEN ''' || P_LINE_HOLD_FROM|| ''' AND ''' || P_LINE_HOLD_TO ||  ''')'
                          ;
          ELSE
             LP_LINE_HOLD_WHERE :=
             ' AND EXISTS (SELECT 1
                             FROM  apps.oe_order_holds_all  oh  , oe_hold_definitions hd
                            WHERE oh.order_hold_id  = hd.hold_id
                              AND oh.header_id = rout.header_id
                              AND hd.name >= ''' || P_LINE_HOLD_FROM  ||  ''')'
                                  ;
          END IF;
     ELSIF 2=2 AND P_LINE_HOLD_TO  IS NOT NULL THEN
              LP_LINE_HOLD_WHERE :=
               ' AND EXISTS (SELECT 1
                               FROM  apps.oe_order_holds_all  oh  , oe_hold_definitions hd
                              WHERE oh.order_hold_id  = rout.hold_id
                                 AND oh.header_id  = rout.header_id
                                 AND oh.name <= ''' || P_LINE_HOLD_TO  ||  ''')'
                              ;
     END IF;
     --**********
     LP_RELEASE_STATUS_WHERE  := ' -- ' || P_RELEASE_STATUS ;
     IF P_RELEASE_STATUS IS NOT NULL THEN
        LP_RELEASE_STATUS_WHERE :=
        ' AND EXISTS (SELECT 1
                        FROM wsh_delivery_details wdd
                       WHERE  RELEASED_STATUS = ''' || P_RELEASE_STATUS || '''
                         AND wdd.source_line_id = line_id )';
     END IF;
         --**********
     LP_LINE_STATUS_WHERE  := ' -- ' || P_LINE_STATUS ;
     IF P_LINE_STATUS IS NOT NULL THEN
        LP_LINE_STATUS_WHERE :=
        ' AND LINE_STATUS = ''' || P_LINE_STATUS || ''' ' ;
     END IF;
     --*******
           LP_WAREHOUSE_WHERE := '-- p_warehouse -> ' || P_WAREHOUSE;
     IF P_WAREHOUSE IS NOT NULL THEN
       LP_WAREHOUSE_WHERE := ' AND ORGANIZATION_ID = ' || P_WAREHOUSE || ' --';
     END IF;

     ---------------------
       LP_WHSE_WHERE  := ' -- ..  ' || P_WHSE ;
     IF P_WHSE IS NOT NULL THEN
        LP_WHSE_WHERE :=
        ' AND organization_id = ''' || P_WHSE || ''' ' ;
     END IF;
     --:*:******************
     IF P_SORT_ORDER = 'Order Date' THEN
       LP_SORT_ORDER := 'ORDER BY ordered_date, line_number';
     ELSE
       LP_SORT_ORDER := 'ORDER BY release_date, line_number';
    END IF;


    EXCEPTION
      WHEN /*SRW.USER_EXIT_FAILURE*/OTHERS THEN
           /*SRW.MESSAGE(2
                     ,'Failed in before report trigger:where:MSTK')*/NULL;
      LP_SALES_REP_WHERE :=  '* BEFOREREPORT TRIGGER FAILED *';
    END;


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





  FUNCTION AFTERPFORM RETURN BOOLEAN IS
  BEGIN
    /*SRW.MESSAGE(99999
               ,'$Header: ONT_OEXOHOHS_XMLP_PKG.rdf 120.4 2005/08/26 05:29 maysriva ship
           $')*/NULL;

   RETURN (TRUE);

    EXCEPTION
        WHEN OTHERS Then
        null;
        --xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,'Error while building LP_ITEM_WHERE.');

  END AFTERPFORM;


END XXWSHORDDTL;
/
