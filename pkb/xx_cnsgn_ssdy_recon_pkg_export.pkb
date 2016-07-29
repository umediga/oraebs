DROP PACKAGE BODY APPS.XX_CNSGN_SSDY_RECON_PKG_EXPORT;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CNSGN_SSDY_RECON_PKG_EXPORT" 
IS
    ----------------------------------------------------------------------
    /*
     Created By    : Omkar (IBM Development)
     Creation Date : 27-Jun-2014
     File Name     : XX_CNSGN_SSDY_RECON_PKG_EXPORT.pkb
     Description   : This script creates the body of the package
                     XX_CNSGN_SSDY_RECON_PKG_EXPORT
     Change History:
     Date        Name                  Remarks
     ----------- -------------         -----------------------------------
     27-Jun-2014 Omkar                 Initial Version
    */
    ----------------------------------------------------------------------
    PROCEDURE XX_CNSGN_RECON_R12_EXPORT        (  errbuf          OUT  VARCHAR2,
                                                  retcode         OUT  NUMBER
                                               )
    is

    cursor C_R12_EXPORT
    IS
    select ORGANIZATION_CODE,
ORG_ID,
ITEM,
ITEM_ID,
PRIMARY_UOM_CODE,
SUBINVENTORY_CODE,
LOCATOR_ID,
LOCATOR,
LOT,
SERIAL,
ONHAND,
LPN,
LPN_ID,
LOT_EXPIRY_DATE,
C_CODE,
D_CODE,
CONTROL_FLAG,
SNM_DIVISION,
ITEM_COST,
PARTY_TYPE,
SALES_PERSON_NUMBER,
C_CODE_DESC,
D_CODE_DESC
from
APPS.XX_MTL_MWB_GTMP
ORDER BY snm_division,subinventory_code, item;

  L_REPORT_TITLE                             varchar2(100) := 'INTG Field Inv Reconciliation and SSDLY - R12 Export';
  l_count number;

    BEGIN

    BEGIN

    select COUNT(1)
    into l_count
      from
      APPS.XX_MTL_MWB_GTMP;

     EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found!');
    end;

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,L_REPORT_TITLE||' as on '||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');


    if L_COUNT > 0 then

    FND_FILE.PUT_LINE (FND_FILE.OUTPUT, 'ORGANIZATION_CODE'||'|'||'ORG_ID'||'|'||'ITEM'||'|'||'ITEM_ID'||'|'||'PRIMARY_UOM_CODE'||'|'||'SUBINVENTORY_CODE'||'|'||'LOCATOR_ID'||'|'||
'LOCATOR'||'|'||'LOT'||'|'||'SERIAL'||'|'||'ONHAND'||'|'||'LPN'||'|'||'LPN_ID'||'|'||'LOT_EXPIRY_DATE'||'|'||'C_CODE'||'|'||'D_CODE'||'|'||'CONTROL_FLAG'||'|'||
'SNM_DIVISION'||'|'||'ITEM_COST'||'|'||'PARTY_TYPE'||'|'||'SALES_PERSON_NUMBER'||'|'||'C_CODE_DESC'||'|'||'D_CODE_DESC');

    FOR R_R12_EXPORT IN C_R12_EXPORT
       LOOP

       FND_FILE.PUT_LINE (FND_FILE.OUTPUT, R_R12_EXPORT.ORGANIZATION_CODE||'|'||R_R12_EXPORT.ORG_ID||'|'||R_R12_EXPORT.ITEM||'|'||R_R12_EXPORT.ITEM_ID||'|'||R_R12_EXPORT.PRIMARY_UOM_CODE||'|'||R_R12_EXPORT.SUBINVENTORY_CODE||'|'||R_R12_EXPORT.LOCATOR_ID||'|'||R_R12_EXPORT.locator||'|'||R_R12_EXPORT.LOT||'|'||R_R12_EXPORT.SERIAL||'|'||R_R12_EXPORT.ONHAND||'|'||R_R12_EXPORT.LPN||'|'||R_R12_EXPORT.LPN_ID||'|'||R_R12_EXPORT.LOT_EXPIRY_DATE||'|'||R_R12_EXPORT.C_CODE||'|'||R_R12_EXPORT.D_CODE||'|'||R_R12_EXPORT.CONTROL_FLAG||'|'||R_R12_EXPORT.SNM_DIVISION||'|'||R_R12_EXPORT.ITEM_COST||'|'||R_R12_EXPORT.PARTY_TYPE||'|'||R_R12_EXPORT.SALES_PERSON_NUMBER||'|'||R_R12_EXPORT.C_CODE_DESC||'|'||R_R12_EXPORT.D_CODE_DESC);

       END LOOP;

    else

    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'No Data Found!');

  end if;

END XX_CNSGN_RECON_R12_EXPORT;

--Added for Detail report
PROCEDURE xx_cnsgn_recon_ss_export_detl(
                                         cp_division  IN  VARCHAR2
                                        )
IS

   CURSOR c_ss_export(cp_division VARCHAR2)
   IS
   SELECT
          transaction_id
         ,transaction_date
         ,product_number
         ,inventory_id
         ,lot_serial
         ,stock_id
         ,qty
         ,party_responsible
         ,location
         ,REPLACE(REGEXP_REPLACE( keeperpool, '\s'), CHR(0)) keeperpool
         ,pending_receipt
         ,indispute
         ,iskit
         ,inkit
         ,parent_product
         ,parent_lotserial
         ,pending_reconciliation
         ,in_inventory
         ,date_received
         ,receipt_error
         ,issue_error
         ,division
         ,lot_expiry_date
         ,c_code
         ,d_code
         ,item_cost
         ,lot_number
         ,serial_number
         ,attribute1
         ,attribute2
         ,attribute3
         ,attribute4
         ,attribute5
         ,attribute6
         ,lpn
         ,c_code_desc
         ,d_code_desc
         ,inventory_item_id
    FROM apps.xx_consgmt_ssdy_xns
   WHERE 1=1
     AND division = NVL(cp_division,division)
     ORDER BY transaction_id;

   l_report_title  VARCHAR2(100) := 'INTG Field Inv Reconciliation and SSDLY - SS Export';
   l_count         NUMBER;

BEGIN

   BEGIN
      fnd_file.put_line(fnd_file.log,'DIVISION '||cp_division);

      SELECT COUNT(1)
        INTO l_count
        FROM apps.xx_consgmt_ssdy_xns
       WHERE 1=1
         AND division = NVL(cp_division,division);

      fnd_file.put_line(fnd_file.log,'NO. OF RECORDS '||l_count);

   EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'No Data Found!');
   END;

   fnd_file.put_line(fnd_file.output,l_report_title||' as on '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
   fnd_file.put_line (fnd_file.output,' ');

   IF l_count > 0 THEN
      fnd_file.put_line(fnd_file.output,'TRANSACTION_ID'||'|'||
                                        'TRANSACTION_DATE'||'|'||
                                        'PRODUCT_NUMBER'||'|'||
                                        'INVENTORY_ID'||'|'||
                                        'LOT_SERIAL'||'|'||
                                        'STOCK_ID'||'|'||
                                        'QUANTITY'||'|'||
                                        'PARTY_RESPONSIBLE'||'|'||
                                        'LOCATION'||'|'||
                                        'KEEPERPOOL'||'|'||
                                        'PENDING_RECEIPT'||'|'||
                                        'INDISPUTE'||'|'||
                                        'ISKIT'||'|'||
                                        'INKIT'||'|'||
                                        'PARENT_PRODUCT'||'|'||
                                        'PARENT_LOTSERIAL'||'|'||
                                        'PENDING_RECONCILIATION'||'|'||
                                        'IN_INVENTORY'||'|'||
                                        'DATE_RECEIVED'||'|'||
                                        'RECEIPT_ERROR'||'|'||
                                        'ISSUE_ERROR'||'|'||
                                        'DIVISION'||'|'||
                                        'LOT_EXPIRY_DATE'||'|'||
                                        'C_CODE'||'|'||
                                        'D_CODE'||'|'||
                                        'ITEM_COST'||'|'||
                                        'LOT_NUMBER'||'|'||
                                        'SERIAL_NUMBER'||'|'||
                                        'ATTRIBUTE1'||'|'||
                                        'ATTRIBUTE2'||'|'||
                                        'ATTRIBUTE3'||'|'||
                                        'ATTRIBUTE4'||'|'||
                                        'ATTRIBUTE5'||'|'||
                                        'ATTRIBUTE6'||'|'||
                                        'LPN'||'|'||
                                        'C_CODE_DESC'||'|'||
                                        'D_CODE_DESC'||'|'||
                                        'INVENTORY_ITEM_ID');

      FOR r_ss_export IN c_ss_export(cp_division)
      LOOP
          fnd_file.put_line(fnd_file.output,r_ss_export.transaction_id||'|'||
                                            r_ss_export.transaction_date||'|'||
                                            r_ss_export.product_number||'|'||
                                            r_ss_export.inventory_id||'|'||
                                            r_ss_export.lot_serial||'|'||
                                            r_ss_export.stock_id||'|'||
                                            r_ss_export.qty||'|'||
                                            r_ss_export.party_responsible||'|'||
                                            r_ss_export.location||'|'||
                                            r_ss_export.keeperpool||'|'||
                                            r_ss_export.pending_receipt||'|'||
                                            r_ss_export.indispute||'|'||
                                            r_ss_export.iskit||'|'||
                                            r_ss_export.inkit||'|'||
                                            r_ss_export.parent_product||'|'||
                                            r_ss_export.parent_lotserial||'|'||
                                            r_ss_export.pending_reconciliation||'|'||
                                            r_ss_export.in_inventory||'|'||
                                            r_ss_export.date_received||'|'||
                                            r_ss_export.receipt_error||'|'||
                                            r_ss_export.issue_error||'|'||
                                            r_ss_export.division||'|'||
                                            r_ss_export.lot_expiry_date||'|'||
                                            r_ss_export.c_code||'|'||
                                            r_ss_export.d_code||'|'||
                                            r_ss_export.item_cost||'|'||
                                            r_ss_export.lot_number||'|'||
                                            r_ss_export.serial_number||'|'||
                                            r_ss_export.attribute1||'|'||
                                            r_ss_export.attribute2||'|'||
                                            r_ss_export.attribute3||'|'||
                                            r_ss_export.attribute4||'|'||
                                            r_ss_export.attribute5||'|'||
                                            r_ss_export.attribute6||'|'||
                                            r_ss_export.lpn||'|'||
                                            r_ss_export.c_code_desc||'|'||
                                            r_ss_export.d_code_desc||'|'||
                                            r_ss_export.inventory_item_id);
      END LOOP;
   ELSE
      fnd_file.put_line(fnd_file.output,'No Data Found!');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.output,'Error in xx_cnsgn_recon_ss_export_detl');
END xx_cnsgn_recon_ss_export_detl;

procedure XX_CNSGN_RECON_SS_EXPORT_SUMM       (
                                                  cp_division     IN VARCHAR2
                                               )
    is

CURSOR C_SS_EXPORT(cp_division VARCHAR2)
    IS
select
DIVISION,
PRODUCT_NUMBER,
INVENTORY_ID,
LOT_SERIAL,
QUANTITY_SUM,
PARTY_RESPONSIBLE,
location,
KEEPERPOOL,
PENDING_RECEIPT,
INDISPUTE,
ISKIT,
INKIT,
PARENT_PRODUCT,
PARENT_LOTSERIAL,
PENDING_RECONCILIATION,
IN_INVENTORY,
DATE_RECEIVED,
RECEIPT_ERROR,
ISSUE_ERROR,
LOT_EXPIRY_DATE,
C_CODE,
D_CODE,
ITEM_COST,
LOT_NUMBER,
SERIAL_NUMBER,
ATTRIBUTE1,
ATTRIBUTE2,
ATTRIBUTE3,
ATTRIBUTE4,
ATTRIBUTE5,
ATTRIBUTE6,
LPN,
C_CODE_DESC,
D_CODE_DESC,
INVENTORY_ITEM_ID
from APPS.XX_CONSGMT_SSDY_SUM_XNS
where
1= 1
and DIVISION = NVL(cp_division,DIVISION)
order by DIVISION, PRODUCT_NUMBER, PARTY_RESPONSIBLE;

L_REPORT_TITLE                             varchar2(100) := 'INTG Field Inv Reconciliation and SSDLY - SS Export';
l_count number;

begin

 begin

 FND_FILE.PUT_LINE(FND_FILE.log,'DIVISION '||cp_division);

 select COUNT(1)
    into l_count
      from
      APPS.XX_CONSGMT_SSDY_SUM_XNS
      where
      1=1
      and division = nvl(cp_division,division);

      FND_FILE.PUT_LINE(FND_FILE.LOG,'NO. OF RECORDS '||l_count);

     EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found!');
    end;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,L_REPORT_TITLE||' as on '||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));
  FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');


    if L_COUNT > 0 then

    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'DIVISION'||'|'||'PRODUCT_NUMBER'||'|'||'INVENTORY_ID'||'|'||'LOT_SERIAL'||'|'||'QUANTITY_SUM'||'|'||'PARTY_RESPONSIBLE'||'|'||'LOCATION'||'|'||'KEEPERPOOL'||'|'||'PENDING_RECEIPT'||'|'||
'INDISPUTE'||'|'||'ISKIT'||'|'||'INKIT'||'|'||'PARENT_PRODUCT'||'|'||'PARENT_LOTSERIAL'||'|'||'PENDING_RECONCILIATION'||'|'||'IN_INVENTORY'||'|'||'DATE_RECEIVED'||'|'||
'RECEIPT_ERROR'||'|'||'ISSUE_ERROR'||'|'||'LOT_EXPIRY_DATE'||'|'||'C_CODE'||'|'||'D_CODE'||'|'||'ITEM_COST'||'|'||'LOT_NUMBER'||'|'||'SERIAL_NUMBER'||'|'||'ATTRIBUTE1'||'|'||
'ATTRIBUTE2'||'|'||'ATTRIBUTE3'||'|'||'ATTRIBUTE4'||'|'||'ATTRIBUTE5'||'|'||'ATTRIBUTE6'||'|'||'LPN'||'|'||'C_CODE_DESC'||'|'||'D_CODE_DESC'||'|'||'INVENTORY_ITEM_ID');

  FOR R_SS_EXPORT IN C_SS_EXPORT(cp_division)
       LOOP

       FND_FILE.PUT_LINE (FND_FILE.OUTPUT,R_SS_EXPORT.DIVISION||'|'||R_SS_EXPORT.PRODUCT_NUMBER||'|'||R_SS_EXPORT.INVENTORY_ID||'|'||R_SS_EXPORT.LOT_SERIAL||'|'||R_SS_EXPORT.QUANTITY_SUM||'|'||R_SS_EXPORT.PARTY_RESPONSIBLE||'|'||R_SS_EXPORT.location||'|'||R_SS_EXPORT.KEEPERPOOL||'|'||R_SS_EXPORT.PENDING_RECEIPT||'|'||R_SS_EXPORT.INDISPUTE||'|'||R_SS_EXPORT.ISKIT||'|'||R_SS_EXPORT.INKIT||'|'||R_SS_EXPORT.PARENT_PRODUCT||'|'||R_SS_EXPORT.PARENT_LOTSERIAL||'|'||R_SS_EXPORT.PENDING_RECONCILIATION||'|'||R_SS_EXPORT.IN_INVENTORY||'|'||R_SS_EXPORT.DATE_RECEIVED||'|'||R_SS_EXPORT.RECEIPT_ERROR||'|'||R_SS_EXPORT.ISSUE_ERROR||'|'||R_SS_EXPORT.LOT_EXPIRY_DATE||'|'||R_SS_EXPORT.C_CODE||'|'||R_SS_EXPORT.D_CODE||'|'||R_SS_EXPORT.ITEM_COST||'|'||R_SS_EXPORT.LOT_NUMBER||'|'||R_SS_EXPORT.SERIAL_NUMBER||'|'||R_SS_EXPORT.ATTRIBUTE1||'|'||R_SS_EXPORT.ATTRIBUTE2||'|'||R_SS_EXPORT.ATTRIBUTE3||'|'||R_SS_EXPORT.ATTRIBUTE4||'|'||R_SS_EXPORT.ATTRIBUTE5||'|'||R_SS_EXPORT.ATTRIBUTE6||'|'||R_SS_EXPORT.LPN||'|'||R_SS_EXPORT.C_CODE_DESC||'|'||R_SS_EXPORT.D_CODE_DESC||'|'||R_SS_EXPORT.INVENTORY_ITEM_ID);

    END LOOP;

   else

    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'No Data Found!');

  end if;

END XX_CNSGN_RECON_SS_EXPORT_SUMM;

PROCEDURE xx_cnsgn_recon_ss_export(
                                     ERRBUF          OUT  varchar2,
                                     RETCODE         OUT  number,
                                     cp_division     IN   VARCHAR2,
                                     cp_report_type  IN   VARCHAR2
                                  )
IS

BEGIN
    IF cp_report_type = 'DETAIL' THEN
       xx_cnsgn_recon_ss_export_detl(cp_division);
    ELSE
       xx_cnsgn_recon_ss_export_summ(cp_division);
    END IF;
EXCEPTION
   WHEN OTHERS THEN
   fnd_file.put_line(fnd_file.output,'Error in xx_cnsgn_recon_ss_export');
END xx_cnsgn_recon_ss_export;


END XX_CNSGN_SSDY_RECON_PKG_EXPORT;
/
