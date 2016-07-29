DROP PACKAGE BODY APPS.XX_OM_SHIP_OUT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_SHIP_OUT_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date :
 File Name     : xx_om_ship_out_pkg.pkb
 Description   : This script creates the body of the package
                 xx_om_ship_out_pkg
 Change History:
 Date        Name            Remarks
 ----------- -------------   -----------------------------------
 28-Feb-2013 Renjith         Initial Version
 14-Jun-2013 Renjith         Added get_proactive_flag
*/
----------------------------------------------------------------------
   FUNCTION get_fright_acc_no( p_tp_attribute1    IN VARCHAR2
                              ,p_site_use_id      IN NUMBER
                              ,p_ship_method_code IN VARCHAR2)
   RETURN VARCHAR2
   IS
     x_attribute3     VARCHAR2(150);
     x_attribute4     VARCHAR2(150);
     x_freight_code   VARCHAR2(30);
     x_freight_acc3   VARCHAR2(150);
     x_freight_acc4   VARCHAR2(150);
   BEGIN
      BEGIN
         SELECT  car.freight_code
           INTO  x_freight_code
           FROM  wsh_carrier_services cas
                ,wsh_carriers car
          WHERE  cas.carrier_id = car.carrier_id
            AND  cas.ship_method_code = p_ship_method_code;
      EXCEPTION
         WHEN OTHERS THEN
            x_freight_code := NULL;
      END;

      IF TRIM(p_tp_attribute1) IS NULL THEN
         BEGIN
            SELECT  UPPER(SUBSTR(attribute3,1,INSTR(attribute3,'#')-1))
                   ,UPPER(SUBSTR(attribute4,1,INSTR(attribute4,'#')-1))
                   ,SUBSTR(attribute3,INSTR(attribute3,'#')+1)
                   ,SUBSTR(attribute4,INSTR(attribute4,'#')+1)
              INTO  x_attribute3
                   ,x_attribute4
                   ,x_freight_acc3
                   ,x_freight_acc4
              FROM  hz_cust_site_uses_all
             WHERE  site_use_id = p_site_use_id;
         EXCEPTION
            WHEN OTHERS THEN
               x_attribute3 := NULL;
               x_attribute4 := NULL;
         END;

         IF x_attribute3 IS NOT NULL THEN
            IF x_freight_code = x_attribute3 THEN
               RETURN(x_freight_acc3);
            ELSE
               IF x_attribute4 IS NOT NULL THEN
                  IF x_freight_code = x_attribute4 THEN
                     RETURN(x_freight_acc4);
                  ELSE
                     RETURN(NVL(x_freight_acc3,x_freight_acc4));
                  END IF;
               ELSE
                 RETURN(NVL(x_freight_acc3,x_freight_acc4));
               END IF;
            END IF;
         ELSE
            IF x_attribute4 IS NOT NULL THEN
               IF x_freight_code = x_attribute4 THEN
                  RETURN(x_freight_acc4);
               ELSE
                  RETURN(NVL(x_freight_acc3,x_freight_acc4));
               END IF;
            ELSE
               RETURN(NVL(x_freight_acc3,x_freight_acc4));
            END IF;
         END IF;
      ELSE -- p_tp_attribute1 is null
        IF UPPER(SUBSTR(p_tp_attribute1,1,INSTR(p_tp_attribute1,'#')-1)) = x_freight_code THEN
           RETURN(SUBSTR(p_tp_attribute1,INSTR(p_tp_attribute1,'#')+1));
        ELSE
           RETURN(p_tp_attribute1);
        END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN(' ');
   END;

-- --------------------------------------------------------------------- --

   FUNCTION get_proactive_flag(p_delivery_id   IN VARCHAR2)
   RETURN VARCHAR2
   IS
     x_proactive  VARCHAR2(1);
   BEGIN
     BEGIN
       SELECT 'Y'
         INTO  x_proactive
         FROM  wsh_delivery_details wdd
              ,wsh_delivery_assignments wda
              ,mtl_system_items_b itm
              ,fnd_lookup_values_vl lk
        WHERE  wdd.delivery_detail_id = wda.delivery_detail_id
          AND  wdd.inventory_item_id  = itm.inventory_item_id
          AND  wdd.organization_id    = itm.organization_id
          AND  wda.delivery_id = p_delivery_id
          AND  itm.segment1 = lk.lookup_code
          --AND  itm.organization_id = NVL(lk.description,itm.organization_id)
          AND  lk.lookup_type = 'XX_OM_MANIFEST_PROACTIVE_ITEMS'
          AND  NVL(lk.enabled_flag,'X')='Y'
          AND  SYSDATE BETWEEN NVL(lk.start_date_active,SYSDATE) AND NVL(lk.end_date_active,SYSDATE);

     EXCEPTION WHEN NO_DATA_FOUND THEN
        x_proactive := 'N';
     WHEN OTHERS THEN
        x_proactive := 'Y';
     END;
     RETURN x_proactive;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN(' ');
   END get_proactive_flag;

   FUNCTION get_days_restrict(p_delivery_id   IN VARCHAR2)
   RETURN VARCHAR2
   IS
     x_days_restrict  VARCHAR2(2);
   BEGIN
     BEGIN
       SELECT  min(lk.description)  INTO  x_days_restrict
         FROM  wsh_delivery_details wdd
              ,wsh_delivery_assignments wda
              ,mtl_system_items_b itm
              ,fnd_lookup_values_vl lk
        WHERE  wdd.delivery_detail_id = wda.delivery_detail_id
          AND  wdd.inventory_item_id  = itm.inventory_item_id
          AND  wdd.organization_id    = itm.organization_id
          AND  wda.delivery_id = p_delivery_id
          AND  itm.segment1 = lk.lookup_code
          AND  lk.lookup_type like 'XXINTG_ITEM_SHIP_METHOD'
          AND  NVL(lk.enabled_flag,'X')='Y'
          AND  SYSDATE BETWEEN NVL(lk.start_date_active,SYSDATE) AND NVL(lk.end_date_active,SYSDATE);

     EXCEPTION WHEN others THEN
        x_days_restrict := null;
     END;
     RETURN x_days_restrict;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN(' ');
   END get_days_restrict;

END xx_om_ship_out_pkg;
/
