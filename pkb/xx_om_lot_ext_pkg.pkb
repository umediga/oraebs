DROP PACKAGE BODY APPS.XX_OM_LOT_EXT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_OM_LOT_EXT_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : IBM Development
 Creation Date : 30-Jul-2013
 File Name     : xx_om_lot_ext.pkb
 Description   : This script creates the body of the package
                 xx_om_lot_ext_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 30-Jul-2013 Renjith               Initial Version
 18-Mar-2014 Renjith               Added lot filteration
*/
----------------------------------------------------------------------
   x_user_id          NUMBER := FND_GLOBAL.USER_ID;
   x_login_id         NUMBER := FND_GLOBAL.LOGIN_ID;
   x_request_id       NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
   x_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
   x_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
  ----------------------------------------------------------------------


  PROCEDURE lot_extract( p_errbuf            OUT   VARCHAR2
                        ,p_retcode           OUT   VARCHAR2
                        ,p_organization_id   IN    NUMBER
                        ,p_date_from         IN    VARCHAR2
                        ,p_date_to           IN    VARCHAR2)

  --PROCEDURE lot_extract
  IS

    x_date_from        VARCHAR2(20);
    x_date_to          VARCHAR2(20);

    x_application      VARCHAR2(10) := 'XXINTG';
    x_program_name     VARCHAR2(20) := 'XXOMLOTEXTRACT';
    x_program_desc     VARCHAR2(50) := 'INTG Jarit Lot Number Extract';
    x_phase            VARCHAR2(2000);
    x_status           VARCHAR2(80);
    x_devphase         VARCHAR2(80);
    x_devstatus        VARCHAR2(80);
    x_message          VARCHAR2(2000);
    x_check            BOOLEAN;
    x_reqid            NUMBER;

    x_country          VARCHAR2(100);

    x_layout_status    BOOLEAN := FALSE;
    x_ter              fnd_languages.iso_territory%TYPE := 'US';
    x_lang             fnd_languages.iso_language%TYPE := 'en';

    CURSOR c_po (p_fdate VARCHAR2,p_tdate VARCHAR2)
    IS
      SELECT  NVL(wp.lot_number,wip_entity_name) lot_no
             ,wip_entity_name job
             ,poh.vendor_id
             ,UPPER(SUBSTR(pnd.vendor_name,1,5)) vendor
             ,mtl.segment1 cat_no
             ,poh.segment1 order_no
             ,poh.creation_date order_date
             ,mtl.attribute24 whs
             ,pol.quantity
             ,pol.unit_price
             ,pol.item_description
             ,wp.wip_entity_id
             ,wp.organization_id
             ,wp.primary_item_id
             ,po_distribution_id
             ,poh.po_header_id
             ,pol.po_line_id
       FROM   apps.po_headers_all poh
             ,apps.po_lines_all pol
             ,apps.mtl_system_items_b mtl
             ,apps.wip_discrete_jobs_v wp
             ,apps.po_distributions_all pdrt
             ,apps.po_vendors pnd
             ,apps.po_line_types pltt
      WHERE   poh.po_header_id = pol.po_header_id
        AND   poh.po_header_id = pdrt.po_header_id
        AND   pol.po_line_id = pdrt.po_line_id
        AND   wp.primary_item_id = mtl.inventory_item_id(+)
        AND   pdrt.wip_entity_id = wp.wip_entity_id
        AND   poh.vendor_id = pnd.vendor_id
        AND   pol.line_type_id = pltt.line_type_id(+)
        AND   mtl.organization_id = wp.organization_id
        AND   pltt.line_type = 'Outside processing'
        AND   NVL(pol.cancel_flag,'N') <> 'Y'
        AND   wp.organization_id = p_organization_id
        AND   poh.creation_date BETWEEN p_fdate AND p_tdate;
        --AND   wp.wip_entity_id = 162248;

     CURSOR c_comp (p_entity_id NUMBER)
     IS
       SELECT  inventory_item_id
              ,organization_id
              ,component_sequence_id
        FROM   apps.wip_requirement_operations
       WHERE   wip_entity_id = p_entity_id
       ORDER BY component_sequence_id;

     CURSOR c_lot (p_entity_id NUMBER,p_item_id NUMBER,p_org_id NUMBER)
     IS
     SELECT  DISTINCT mtln.lot_number
       FROM  apps.wip_discrete_jobs_v dj,
             apps.mtl_material_transactions mmt,
             apps.mtl_transaction_lot_numbers mtln
      WHERE  dj.organization_id = p_org_id
        AND  dj.organization_id = mmt.organization_id
        AND  dj.wip_entity_id = mmt.transaction_source_id
        AND  mmt.transaction_id = mtln.transaction_id
        AND  mmt.organization_id = mtln.organization_id
        AND  mmt.transaction_type_id in ('35','43') --wip component issue and return
        AND  mmt.inventory_item_id = p_item_id
        AND  dj.wip_entity_id = p_entity_id;

     CURSOR c_inv (p_item_id NUMBER, p_org_id NUMBER, p_lot VARCHAR2)
     IS
     SELECT  inv.invoice_id
            ,inv.invoice_num
            --,inv.invoice_amount
            ,inl.amount invoice_amount
            ,inv.invoice_currency_code
       FROM  apps.mtl_material_transactions mmt
            ,apps.rcv_transactions rct
            ,apps.rcv_shipment_headers rch
            ,apps.ap_invoices_all inv
            ,apps.ap_invoice_lines_all inl
            ,apps.mtl_transaction_lot_numbers lot
      WHERE mmt.rcv_transaction_id = rct.transaction_id
        AND rct.shipment_header_id = rch.shipment_header_id
        AND rch.packing_slip = inv.invoice_num
        AND inv.invoice_id = inl.invoice_id
        AND mmt.transaction_type_id = 18
        AND rct.transaction_type = 'DELIVER'
        AND inl.inventory_item_id = mmt.inventory_item_id
        AND mmt.transaction_id = lot.transaction_id
        AND mmt.inventory_item_id = lot.inventory_item_id
        AND mmt.organization_id = lot.organization_id
        AND mmt.inventory_item_id = p_item_id
        AND mmt.organization_id   = p_org_id
        AND lot.lot_number = p_lot;

     x_invoice_id1     NUMBER;
     x_invoice_num1    VARCHAR2(50);
     x_invoice_amt1    NUMBER;
     x_invoice_cur1    VARCHAR2(15);

     x_invoice_id2     NUMBER;
     x_invoice_num2    VARCHAR2(50);
     x_invoice_amt2    NUMBER;
     x_invoice_cur2    VARCHAR2(15);

     x_invoice_id3     NUMBER;
     x_invoice_num3    VARCHAR2(50);
     x_invoice_amt3    NUMBER;
     x_invoice_cur3    VARCHAR2(15);

     x_invoice_id4     NUMBER;
     x_invoice_num4    VARCHAR2(50);
     x_invoice_amt4    NUMBER;
     x_invoice_cur4    VARCHAR2(15);

     x_invoice_id5     NUMBER;
     x_invoice_num5    VARCHAR2(50);
     x_invoice_amt5    NUMBER;
     x_invoice_cur5    VARCHAR2(15);

     x_amt_eur         NUMBER;
     x_amt_usd         NUMBER;

     x_record_id       NUMBER;
     x_count           NUMBER;
  BEGIN
     FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_organization_id  ->'||p_organization_id);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_date_from        ->'||p_date_from);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'p_date_to          ->'||p_date_to);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'-------------------------------------------------------');

     x_date_from := TO_CHAR(TRUNC(TO_DATE(p_date_from,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');
     x_date_to   := TO_CHAR(TRUNC(TO_DATE(p_date_to,'YYYY-MM-DD HH24:MI:SS')),'DD-MON-YYYY');

     FND_FILE.PUT_LINE( FND_FILE.LOG,'x_date_from        ->'||x_date_from);
     FND_FILE.PUT_LINE( FND_FILE.LOG,'x_date_to          ->'||x_date_to);

     FOR po_rec IN c_po (x_date_from,x_date_to)
     LOOP
         x_count   := 1;
         x_amt_eur := 0;
         x_amt_usd := 0;

         FOR comp_rec IN c_comp(po_rec.wip_entity_id)
         LOOP
            FND_FILE.PUT_LINE( FND_FILE.LOG,'x_count            ->'||x_count);
            FND_FILE.PUT_LINE( FND_FILE.LOG,'inventory_item_id  ->'||comp_rec.inventory_item_id);
            FND_FILE.PUT_LINE( FND_FILE.LOG,'organization_id    ->'||comp_rec.organization_id);

            FOR lot_rec IN c_lot (po_rec.wip_entity_id, comp_rec.inventory_item_id, comp_rec.organization_id)
            LOOP
               FND_FILE.PUT_LINE( FND_FILE.LOG,'Lot ->'||lot_rec.lot_number);

               FOR inv_rec IN c_inv (comp_rec.inventory_item_id, comp_rec.organization_id, lot_rec.lot_number)
               LOOP

                 FND_FILE.PUT_LINE( FND_FILE.LOG,'comp invoice_id    ->'||inv_rec.invoice_id);
                 FND_FILE.PUT_LINE( FND_FILE.LOG,'comp invoice_num   ->'||inv_rec.invoice_num);
                 FND_FILE.PUT_LINE( FND_FILE.LOG,'comp invoice_amt   ->'||inv_rec.invoice_amount);
                 FND_FILE.PUT_LINE( FND_FILE.LOG,'comp invoice_curr  ->'||inv_rec.invoice_currency_code);

                  IF x_count = 1 THEN
                     x_invoice_id1    := inv_rec.invoice_id;
                     x_invoice_num1   := inv_rec.invoice_num;
                     x_invoice_amt1   := inv_rec.invoice_amount;
                     x_invoice_cur1   := inv_rec.invoice_currency_code;
                     IF x_invoice_cur1 = 'USD' THEN
                        x_amt_usd := x_amt_usd + x_invoice_amt1;
                     ELSIF x_invoice_cur1 = 'EUR' THEN
                        x_amt_eur := x_amt_eur + x_invoice_amt1;
                     END IF;
                  ELSIF x_count = 2 THEN
                     x_invoice_id2    := inv_rec.invoice_id;
                     x_invoice_num2   := inv_rec.invoice_num;
                     x_invoice_amt2   := inv_rec.invoice_amount;
                     x_invoice_cur2   := inv_rec.invoice_currency_code;
                     IF x_invoice_cur2 = 'USD' THEN
                        x_amt_usd := x_amt_usd + x_invoice_amt2;
                     ELSIF x_invoice_cur2 = 'EUR' THEN
                        x_amt_eur := x_amt_eur + x_invoice_amt2;
                     END IF;
                  ELSIF x_count = 3 THEN
                     x_invoice_id3    := inv_rec.invoice_id;
                     x_invoice_num3   := inv_rec.invoice_num;
                     x_invoice_amt3   := inv_rec.invoice_amount;
                     x_invoice_cur3   := inv_rec.invoice_currency_code;
                     IF x_invoice_cur3 = 'USD' THEN
                       x_amt_usd := x_amt_usd + x_invoice_amt3;
                     ELSIF x_invoice_cur3 = 'EUR' THEN
                       x_amt_eur := x_amt_eur + x_invoice_amt3;
                     END IF;
                  ELSIF x_count = 4 THEN
                     x_invoice_id4    := inv_rec.invoice_id;
                     x_invoice_num4   := inv_rec.invoice_num;
                     x_invoice_amt4   := inv_rec.invoice_amount;
                     x_invoice_cur4   := inv_rec.invoice_currency_code;
                  ELSIF x_count = 5 THEN
                     x_invoice_id5    := inv_rec.invoice_id;
                     x_invoice_num5   := inv_rec.invoice_num;
                     x_invoice_amt5   := inv_rec.invoice_amount;
                     x_invoice_cur5   := inv_rec.invoice_currency_code;
                  END IF;
                  x_count := x_count + 1;
               END LOOP; -- c_inv
            END LOOP; -- c_lot
         END LOOP;-- c_comp

         FND_FILE.PUT_LINE( FND_FILE.LOG, 'x_amt_usd         ->'||x_amt_usd);
         FND_FILE.PUT_LINE( FND_FILE.LOG, 'x_amt_eur         ->'||x_amt_eur);

         SELECT apps.xx_om_lot_ext_s.NEXTVAL
           INTO x_record_id
           FROM dual;

         INSERT INTO XXINTG.XX_OM_LOT_EXT
           ( record_id
            ,request_id
            ,wip_entity_id
            ,lotno
            ,vendor_id
            ,vendor
            ,po_header_id
            ,po_number
            ,po_date
            ,primary_item_id
            ,cat_no
            ,whs
            ,fc
            ,quantity
            ,price
            --
            ,rwinv_id1
            ,rwinv1
            ,rwinv1_amt
            ,rwinv1_cur
            --
            ,rwinv_id2
            ,rwinv2
            ,rwinv2_amt
            ,rwinv2_cur
            --
            ,rwinv_id3
            ,rwinv3
            ,rwinv3_amt
            ,rwinv3_cur
            --
            ,rwinv_id4
            ,rwinv4
            ,rwinv4_amt
            ,rwinv4_cur
            --
            ,rwinv_id5
            ,rwinv5
            ,rwinv5_amt
            ,rwinv5_cur
            --
            ,total_eur
            ,total_usd
            ,date_from
            ,date_to
            ,organization_id
            ,created_by
            ,creation_date
            ,last_update_date
            ,last_updated_by
            ,last_update_login
           )
         VALUES
           ( x_record_id                    -- record_id
            ,x_request_id                   -- request_id
            ,po_rec.wip_entity_id           -- wip_entity_id
            ,po_rec.lot_no                  -- lotno
            ,po_rec.vendor_id               -- vendor_id
            ,po_rec.vendor                  -- vendor
            ,po_rec.po_header_id            -- po_header_id
            ,po_rec.order_no                -- po_number
            ,po_rec.order_date              -- po_date
            ,po_rec.primary_item_id         -- primary_item_id
            ,po_rec.cat_no                  -- cat_no
            ,po_rec.whs                     -- whs
            ,NULL                           -- fc
            ,po_rec.quantity                -- quantity
            ,po_rec.unit_price              -- price
            --
            ,x_invoice_id1                  --rwinv_id1
            ,x_invoice_num1                 --rwinv1
            ,x_invoice_amt1                 --rwinv1_amt
            ,x_invoice_cur1                 --rwinv1_cur
            --
	    ,x_invoice_id2                  --rwinv_id2
	    ,x_invoice_num2                 --rwinv2
	    ,x_invoice_amt2                 --rwinv2_amt
	    ,x_invoice_cur2                 --rwinv2_cur
	    --
	    ,x_invoice_id3                  --rwinv_id3
	    ,x_invoice_num3                 --rwinv3
	    ,x_invoice_amt3                 --rwinv3_amt
	    ,x_invoice_cur3                 --rwinv3_cur
	    --
	    ,x_invoice_id4                  --rwinv_id4
	    ,x_invoice_num4                 --rwinv4
	    ,x_invoice_amt4                 --rwinv4_amt
	    ,x_invoice_cur4                 --rwinv4_cur
	    --
	    ,x_invoice_id5                  --rwinv_id5
	    ,x_invoice_num5                 --rwinv5
	    ,x_invoice_amt5                 --rwinv5_amt
	    ,x_invoice_cur5                 --rwinv5_cur
	    --
            ,x_amt_eur                      --total_eur
            ,x_amt_usd                      --total_usd
            ,x_date_from                    --date_from
            ,x_date_to                      --date_to
            ,po_rec.organization_id         --organization_id
            ,x_user_id                      --created_by
            ,SYSDATE                        --creation_date
            ,SYSDATE                        --last_update_date
            ,x_user_id                      --last_updated_by
            ,x_login_id                     --last_update_login
           );
     END LOOP;
     COMMIT;

     FND_GLOBAL.APPS_INITIALIZE(  x_user_id        --User id
                                 ,x_resp_id        --responsibility_id
                                 ,x_resp_appl_id); --application_id


     x_layout_status := FND_REQUEST.ADD_LAYOUT ( template_appl_name =>  x_application
                                                ,template_code      => 'XXOMLOTEXTRACT'
                                                ,template_language  =>  x_lang
                                                ,template_territory =>  x_ter
                                                ,output_format      => 'EXCEL');

     x_reqid := FND_REQUEST.SUBMIT_REQUEST( application     => x_application
                                           ,program         => x_program_name
                                           ,description     => x_program_desc
                                           ,start_time      => SYSDATE
                                           ,sub_request     => FALSE
                                           ,argument1       => x_request_id
                                           );
     COMMIT;

  EXCEPTION WHEN OTHERS THEN
    FND_FILE.PUT_LINE( FND_FILE.LOG,'Error ->'||SQLERRM);
  END lot_extract;
  ----------------------------------------------------------------------
END xx_om_lot_ext_pkg;
/
