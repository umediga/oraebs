DROP PACKAGE BODY APPS.XX_JPMC_SUA_MVL_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_JPMC_SUA_MVL_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 16-Jul-2013
 File Name      : XXAPJPMCSUAMVL.pkb
 Description    : This script creates the body of the package xx_jpmc_sua_mvl_pkg

 Change History:

Version Date         Name                Remarks
------- ----------- ---------        ------------------------------------------------------------------------
1.0     16-Jul-2013 Mou Mukherjee        Initial development.
-------------------------------------------------------------------------------------------------------------
*/
PROCEDURE main (
                p_errbuf OUT VARCHAR2,
                p_retcode OUT NUMBER
        ) IS
      -- ------------------------------------------------------------------------------

      -- Cursor Definition : c_get_mvl
      --
      --
      --                     To select data for master vendor list
      --
      --                     Parameters : N/A
      --
      -- ------------------------------------------------------------------------------

      CURSOR c_get_mvl
      IS
           select aps.segment1 supplier_number,
       apssa.org_id org_id,
       decode(instr(NVL(aps.vendor_name,0),','),0,aps.vendor_name,'"'||aps.vendor_name||'"')supplier_name,
       aps.num_1099 taxpayer_id,
       decode(instr(NVL(apssa.vendor_site_code,0),','),0,apssa.vendor_site_code,'"'||apssa.vendor_site_code||'"')site_code,
       decode(instr(NVL(hps.party_site_name,0),','),0,hps.party_site_name,'"'||hps.party_site_name||'"')suplier_site_name,
       decode(instr(NVL(apssa.address_line1,0),','),0,apssa.address_line1,'"'||apssa.address_line1||'"')address_line1,
       decode(instr(NVL(apssa.address_line2,0),','),0,apssa.address_line2,'"'||apssa.address_line2||'"')address_line2,
       decode(instr(NVL(apssa.address_line3,0),','),0,apssa.address_line3,'"'||apssa.address_line3||'"')address_line3,
       decode(instr(NVL(apssa.city,0),','),0,apssa.city,'"'||apssa.city||'"')city,
       decode(instr(NVL(apssa.state,0),','),0,apssa.state,'"'||apssa.state||'"')state,
       decode(instr(NVL(apssa.zip,0),','),0,apssa.zip,'"'||apssa.zip||'"')zip,
       decode(instr(NVL(apssa.country,0),','),0,apssa.country,'"'||apssa.country||'"')country,
       apssa.area_code||apssa.phone phone,
       apssa.fax_area_code||apssa.fax fax,
       apsc.vendor_contact_id contact_id,
       decode(instr(NVL(apsc.first_name||apsc.last_name,0),','),0,apsc.first_name || apsc.last_name,'"'||apsc.first_name || apsc.last_name||'"')contact_name,
       decode(instr(NVL(apsc.email_address,'null@null.com'),','),0,NVL(apsc.email_address,'null@null.com'),'"'||NVL(apsc.email_address,'null@null.com')||'"')contact_email
from ap_suppliers aps,
     ap_supplier_sites_all apssa,
     AP_SUPPLIER_CONTACTS apsc,
     IBY_EXT_PARTY_PMT_MTHDS ieppm,
     IBY_EXTERNAL_PAYEES_ALL iepa,
     hz_party_sites hps
where aps.vendor_id = apssa.vendor_id
     and apssa.party_site_id = apsc.org_party_site_id(+)
     and apssa.party_site_id = hps.party_site_id
     and ieppm.ext_pmt_party_id = iepa.ext_payee_id
     AND iepa.supplier_site_id = apssa.vendor_site_id
     and iepa.payee_party_id = aps.party_id
   --  and iepa.supplier_site_id IS NULL
     and ieppm.payment_method_code = 'JPMC SUA'
     AND ieppm.primary_flag = 'Y'
     AND apssa.inactive_date IS NULL;


 BEGIN

    FND_FILE.PUT_LINE ( FND_FILE.OUTPUT,'CSVVENDOR');
   -- Get the vendor list
   FOR c_get_mvl_rec IN c_get_mvl
   LOOP

   FND_FILE.PUT_LINE (
            FND_FILE.OUTPUT,
               c_get_mvl_rec.supplier_number
            ||','
	    ||c_get_mvl_rec.org_id
            ||','
            ||c_get_mvl_rec.supplier_name
	    ||','
	    ||'' -- Blank
	    ||','
	    ||c_get_mvl_rec.taxpayer_id
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||'A'
	    ||','
	    ||c_get_mvl_rec.site_code
	    ||','
	    ||c_get_mvl_rec.supplier_name
	    ||','
	    ||c_get_mvl_rec.address_line1
	    ||','
	    ||c_get_mvl_rec.address_line2
	    ||','
	    ||c_get_mvl_rec.address_line3
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||c_get_mvl_rec.city
	    ||','
	    ||c_get_mvl_rec.state
	    ||','
	    ||c_get_mvl_rec.zip
	    ||','
	    ||c_get_mvl_rec.country
	    ||','
	    ||c_get_mvl_rec.phone
	    ||','
	    ||c_get_mvl_rec.fax
	    ||','
	    ||'A'
	    ||','
	    ||'C'
	    ||','
	    ||'Public'
	    ||','
	    ||''  -- Blank
	    ||','
	    ||'0'
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||'N'
	    ||','
	    ||'' -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||'0'
	    ||','
	    ||'1'
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||'1'
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||'A'
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||''  -- Blank
	    ||','
	    ||c_get_mvl_rec.contact_id
	    ||','
	    ||c_get_mvl_rec.contact_name
	    ||','
	    ||c_get_mvl_rec.contact_email
	    ||','
	    ||'A'
	    ||','
	    ||''  -- Blank
	    ||','
	    ||'Y'
	    ||','
	    ||'Other'
	    ||','
	    ||'null@jpmchase.com'
	);
END LOOP;

   EXCEPTION
     WHEN OTHERS
      THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, SQLERRM);
   END main;

END xx_jpmc_sua_mvl_pkg;
/
