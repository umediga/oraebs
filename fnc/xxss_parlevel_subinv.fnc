DROP FUNCTION APPS.XXSS_PARLEVEL_SUBINV;

CREATE OR REPLACE FUNCTION APPS.XXSS_PARLEVEL_SUBINV(
      P_CUST_NO   VARCHAR2,
      P_CUST_NAME VARCHAR2)
    RETURN VARCHAR2
  IS
    V_RETURN VARCHAR2(100):=NULL;
  BEGIN
    IF V_RETURN IS NULL THEN
      BEGIN
        SELECT SECONDARY_INVENTORY_NAME
        INTO V_RETURN
        FROM MTL_SECONDARY_INVENTORIES
        WHERE 1                      =1
        AND ORGANIZATION_ID          =104
        AND SECONDARY_INVENTORY_NAME =P_CUST_NO ;
      EXCEPTION
      WHEN OTHERS THEN
        V_RETURN:=NULL;
      END;
    END IF;
    --    RETURN V_RETURN;
    IF V_RETURN IS NULL THEN
      BEGIN
        SELECT SECONDARY_INVENTORY_NAME
        INTO V_RETURN
        FROM MTL_SECONDARY_INVENTORIES
        WHERE 1                =1
        AND ORGANIZATION_ID    =104
        AND UPPER(DESCRIPTION) =UPPER(P_CUST_NAME);
      EXCEPTION
      WHEN OTHERS THEN
        V_RETURN:=NULL;
      END;
    END IF;
    --    RETURN V_RETURN;
    IF V_RETURN IS NULL THEN
      BEGIN
        SELECT SECONDARY_INVENTORY_NAME
        INTO V_RETURN
        FROM MTL_SECONDARY_INVENTORIES
        WHERE 1                            =1
        AND ORGANIZATION_ID                =104
        AND UPPER(SECONDARY_INVENTORY_NAME)= UPPER(SUBSTR(P_CUST_NAME,INSTR(P_CUST_NAME,' ',1,1)+1,9)
          ||SUBSTR(P_CUST_NAME,1,1));
      EXCEPTION
      WHEN OTHERS THEN
        V_RETURN:=NULL;
      END ;
    END IF;
    --    RETURN V_RETURN;
    IF V_RETURN IS NULL THEN
      BEGIN
        SELECT SECONDARY_INVENTORY_NAME
        INTO V_RETURN
        FROM MTL_SECONDARY_INVENTORIES
        WHERE 1                  =1
        AND ORGANIZATION_ID      =104
        AND ( UPPER(DESCRIPTION) = UPPER('DEALER-'
          ||P_CUST_NAME)
        OR UPPER(SUBSTR(DESCRIPTION,1,12))=
          (SELECT UPPER(SUBSTR(('DEALER-'
            ||ACCOUNT_NAME),1,12))
          FROM HZ_CUST_ACCOUNTS_ALL
          WHERE ACCOUNT_NUMBER=P_CUST_NO
          ));
      EXCEPTION
      WHEN OTHERS THEN
        V_RETURN:=NULL;
      END;
    END IF;
    --      RETURN V_RETURN;
    IF V_RETURN IS NULL THEN
      BEGIN
        SELECT SECONDARY_INVENTORY_NAME
    INTO V_RETURN
    FROM MTL_SECONDARY_INVENTORIES
    WHERE 1                      =1
    AND ORGANIZATION_ID          =104  
    AND( SUBSTR(SECONDARY_INVENTORY_NAME,1,LENGTH(SECONDARY_INVENTORY_NAME))=UPPER(SUBSTR(REPLACE(P_CUST_NAME,' ',''),1,LENGTH(SECONDARY_INVENTORY_NAME)))
    OR SUBSTR(SECONDARY_INVENTORY_NAME,1,LENGTH(SECONDARY_INVENTORY_NAME))=UPPER(SUBSTR(REPLACE(P_CUST_NAME,',',''),1,LENGTH(SECONDARY_INVENTORY_NAME)) ));
    EXCEPTION
    WHEN OTHERS THEN
    V_RETURN:=NULL;
    END;
    end if;
    RETURN V_RETURN;
   EXCEPTION   
   WHEN OTHERS THEN
   V_RETURN:=null;
    RETURN V_RETURN;
    --  DBMS_OUTPUT.PUT_LINE(V_RETURN);
  END;
/
