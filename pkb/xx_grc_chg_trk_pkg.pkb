DROP PACKAGE BODY APPS.XX_GRC_CHG_TRK_PKG;

CREATE OR REPLACE PACKAGE BODY APPS.xx_grc_chg_trk_pkg
IS
  -------------------------------------------------------------------------------
  --| Program:    INTG GRC Change Tracking Reports
  --| Author:     Integra Development
  --| Created:    06-JUN-2014
  --|
  --| Description: Package with procedures that can be run as concurrent requests
  --|              to produce Change History captured by Oracle GRC.
  --|
  --| Modifications:
  --| -------------
  --| Date       Name                  		Version     Description
  --| ---------  ---------------       		-------     -----------
  --| 06-JUN-2014  Integra development      1.0         Created
  --| 04-Aug-2014  MAHESH SHARMA GRC        1.1         Modified as per Ticket 009117
  --| 30-Mar-2015  Mahesh Sharma GRC		1.2		    Modified as requested by Eileen Case#014416
  --| 17-Apr-2015  Sukanya Chatterjee		1.3	Modified as requested by Eileen
  -------------------------------------------------------------------------------
   --
  -- Procedure to generate Vendor Change History
  --
PROCEDURE vendor_change_data_report(
    errbuf OUT VARCHAR2,
    retcode OUT NUMBER,
    p_oper_unit      VARCHAR2,
    p_start_date     VARCHAR2,
    p_end_date       VARCHAR2,
    p_changed_by     VARCHAR2,
    p_vendor_id      VARCHAR2,
    p_vendor_site_id VARCHAR2,
    p_field          VARCHAR2 )
IS
  CURSOR vendor_data
  IS
    SELECT *
    FROM
      (SELECT p_oper_unit Operating_Unit,
        pov.vendor_name,
        pov.segment1 "VENDOR_NUM",
        NULL "VENDOR_SITE_CODE",
        TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
        lat.login_user_name,
        lat.db_user_name,
        lat.responsibility_name,
        lat.user_column_name,
        lat.user_old_value,
        lat.user_new_value
      FROM laud_audit_transactions lat,
        po_vendors pov
      WHERE 1            = DECODE(p_vendor_site_id, NULL, 1, 0) -- If Vendor Site is provided, report only vendor site changes
      AND lat.table_name = 'AP_SUPPLIERS'
      AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
      AND lat.login_user_name  = NVL(p_changed_by, lat.login_user_name)
      AND lat.pk_val1_id       = NVL(p_vendor_id, lat.pk_val1_id)
      AND lat.user_column_name = NVL(p_field, lat.user_column_name)
      AND lat.pk_val1_id       = pov.vendor_id
    UNION ALL
    SELECT p_oper_unit Operating_Unit,
      pov.vendor_name,
      pov.segment1 "VENDOR_NUM",
      povs.vendor_site_code,
      TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
      lat.login_user_name,
      lat.db_user_name,
      lat.responsibility_name,
      lat.user_column_name,
      lat.user_old_value,
      lat.user_new_value
    FROM laud_audit_transactions lat,
      po_vendor_sites_all povs,
      po_vendors pov
    WHERE lat.table_name = 'AP_SUPPLIER_SITES_ALL'
    AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
    AND lat.login_user_name  = NVL(p_changed_by, lat.login_user_name)
    AND lat.pk_val1_id       = NVL(p_vendor_site_id, lat.pk_val1_id)
    AND lat.user_column_name = NVL(p_field, lat.user_column_name)
    AND lat.pk_val1_id       = povs.vendor_site_id
    AND povs.vendor_id       = pov.vendor_id
    AND povs.vendor_id       = NVL(p_vendor_id,povs.vendor_id)
      )
    ORDER BY transaction_date ASC,
      vendor_name ASC,
      user_column_name ASC;
    l_vendor_name VARCHAR2(250) := 'All Vendors';
    l_vendor_site VARCHAR2(250) := 'All Vendor Sites';
    l_index       NUMBER        := 0;
  BEGIN
    IF p_vendor_id IS NOT NULL THEN
      SELECT vendor_name
      INTO l_vendor_name
      FROM po_vendors
      WHERE vendor_id = p_vendor_id;
    END IF;
    IF p_vendor_site_id IS NOT NULL THEN
      SELECT vendor_site_code
      INTO l_vendor_site
      FROM po_vendor_sites_all
      WHERE vendor_site_id = p_vendor_site_id;
    END IF;
    fnd_file.put_line (fnd_file.output, 'INTG Vendor Change Tracking History Report');
    --fnd_file.put_line (fnd_file.output, 'Operating Unit: ' || p_oper_unit);
    fnd_file.put_line (fnd_file.output, 'History Start Date: ' || NVL(p_start_date, 'Any'));
    fnd_file.put_line (fnd_file.output, 'History End Date: ' || NVL(p_end_date, 'Any'));
    fnd_file.put_line (fnd_file.output, 'Changed By: ' || NVL(p_changed_by, 'All Users'));
    fnd_file.put_line (fnd_file.output, 'Vendor Name: ' || l_vendor_name);
    fnd_file.put_line (fnd_file.output, 'Vendor Site: ' || l_vendor_site);
    fnd_file.put_line (fnd_file.output, 'Field Name: ' || NVL(p_field, 'All fields'));
    FOR vendor_rec IN vendor_data
    LOOP
      l_index   := l_index + 1;
      IF l_index = 1 THEN
        fnd_file.put_line (fnd_file.output, 'Vendor Name;Vendor Number;Vendor Site Code;Changed On;Changed By;Responsibility;Field;Old Value;New Value');
      END IF;
      /*fnd_file.put_line (fnd_file.output, --vendor_rec.Operating_Unit      || ';     ' ||
      vendor_rec.vendor_name         || ';     ' ||
      vendor_rec.vendor_num          || ';     ' ||
      vendor_rec.vendor_site_code    || ';     ' ||
      vendor_rec.transaction_date    || ';     ' ||
      vendor_rec.login_user_name     || ';     ' ||
      vendor_rec.responsibility_name || ';     ' ||
      --vendor_rec.db_user_name        || ';     ' ||
      vendor_rec.user_column_name    || ';     ' ||
      vendor_rec.user_old_value      || ';     ' ||
      vendor_rec.user_new_value);*/
      -- Commented By Mahesh on 04-Aug-2014
      --Added By Mahesh on 04-Aug-2014 After Removing SPACE
      fnd_file.put_line (fnd_file.output, --vendor_rec.Operating_Unit      || ';     ' ||
      vendor_rec.vendor_name || ';' || vendor_rec.vendor_num || ';' || vendor_rec.vendor_site_code || ';' || vendor_rec.transaction_date || ';' || vendor_rec.login_user_name || ';' || vendor_rec.responsibility_name || ';' ||
      --vendor_rec.db_user_name        || ';     ' ||
      vendor_rec.user_column_name || ';' || vendor_rec.user_old_value || ';' || vendor_rec.user_new_value);
    END LOOP;
    IF l_index = 0 THEN
      fnd_file.put_line (fnd_file.output, '*** No change history found for the given criteria ***');
    END IF;
  END vendor_change_data_report;
PROCEDURE customer_change_data_report(
    errbuf OUT VARCHAR2,
    retcode OUT NUMBER,
    p_start_date VARCHAR2,
    p_end_date   VARCHAR2,
    p_changed_by VARCHAR2,
    p_party_id   VARCHAR2,
    p_field      VARCHAR2 )
IS
  CURSOR customer_data
  IS
    SELECT *
    FROM
      (SELECT hzp.party_name,
        hzp.party_number,
        TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
        lat.login_user_name,
        lat.responsibility_name,
        lat.db_user_name,
        lat.user_column_name,
        lat.user_old_value,
        lat.user_new_value,
        lat.table_name
      FROM laud_audit_transactions lat,
        hz_parties hzp
      WHERE lat.table_name = 'HZ_PARTIES'
      AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
      AND lat.login_user_name  = NVL(p_changed_by, lat.login_user_name)
      AND lat.pk_val1_id       = NVL(p_party_id, lat.pk_val1_id)
      AND lat.user_column_name = NVL(p_field, lat.user_column_name)
      AND lat.pk_val1_id       = hzp.party_id
        -- Modified by atul Gupte on Feb 05 2009
      AND hzp.PARTY_TYPE = 'ORGANIZATION'
    UNION
    SELECT hzp.party_name,
      hzp.party_number,
      TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
      lat.login_user_name,
      lat.responsibility_name,
      lat.db_user_name,
      lat.user_column_name,
      lat.user_old_value,
      lat.user_new_value,
      lat.table_name
    FROM laud_audit_transactions lat,
      hz_parties hzp,
      hz_customer_profiles hzcp
    WHERE lat.table_name = 'HZ_CUSTOMER_PROFILES'
    AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
    AND lat.login_user_name  = NVL(p_changed_by, lat.login_user_name)
    AND lat.user_column_name = NVL(p_field, lat.user_column_name)
    AND lat.pk_val1_id       = hzcp.cust_account_profile_id
    AND hzcp.party_id        = NVL(p_party_id, hzcp.party_id)
    AND hzcp.party_id        = hzp.party_id
      -- Modified by atul Gupte on Feb 05 2009
    AND hzp.PARTY_TYPE = 'ORGANIZATION'
    UNION
    SELECT hzp.party_name,
      hzp.party_number,
      TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
      lat.login_user_name,
      lat.responsibility_name,
      lat.db_user_name,
      lat.user_column_name,
      lat.user_old_value,
      lat.user_new_value,
      lat.table_name
    FROM laud_audit_transactions lat,
      hz_parties hzp,
      hz_customer_profiles hzcp,
      hz_cust_profile_amts hzcpa
    WHERE lat.table_name = 'HZ_CUST_PROFILE_AMTS'
    AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
    AND lat.login_user_name           = NVL(p_changed_by, lat.login_user_name)
    AND lat.user_column_name          = NVL(p_field, lat.user_column_name)
    AND lat.pk_val1_id                = hzcpa.cust_acct_profile_amt_id
    AND hzcpa.cust_account_profile_id = hzcp.cust_account_profile_id
    AND hzcp.party_id                 = NVL(p_party_id, hzcp.party_id)
    AND hzcp.party_id                 = hzp.party_id
      -- Modified by atul Gupte on Feb 05 2009
    AND hzp.PARTY_TYPE = 'ORGANIZATION'
    UNION
    SELECT hzp.party_name,
      hzp.party_number,
      TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
      lat.login_user_name,
      lat.responsibility_name,
      lat.db_user_name,
      lat.user_column_name,
      lat.user_old_value,
      lat.user_new_value,
      lat.table_name
    FROM laud_audit_transactions lat,
      hz_parties hzp
    WHERE lat.table_name = 'HZ_CUST_ACCT_SITES_ALL' -- This table added by balaji on 27-Jun-2013
    AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
    AND lat.login_user_name  = NVL(p_changed_by, lat.login_user_name)
    AND lat.pk_val1_id       = NVL(p_party_id, lat.pk_val1_id)
    AND lat.user_column_name = NVL(p_field, lat.user_column_name)
    AND lat.pk_val1_id       = hzp.party_id
      -- Modified by atul Gupte on Feb 05 2009
    AND hzp.PARTY_TYPE = 'ORGANIZATION'
    UNION -- Added By Mahesh on 04-Aug-2014
    SELECT hzp.party_name,
      hzp.party_number,
      TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
      lat.login_user_name,
      lat.responsibility_name,
      lat.db_user_name,
      lat.user_column_name,
      lat.user_old_value,
      lat.user_new_value,
      lat.table_name
    FROM laud_audit_transactions lat,
      hz_parties hzp,
      hz_cust_acct_sites_all hcsa,
      hz_cust_accounts hca,
      hz_cust_site_uses_all hcua
    WHERE 1            =1
    AND lat.table_name = 'HZ_CUST_SITE_USES_ALL'
    AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
    AND lat.login_user_name    = NVL(p_changed_by, lat.login_user_name)
    AND hzp.party_id           = NVL(p_party_id, hzp.party_id)
    AND lat.user_column_name   = NVL(p_field, lat.user_column_name)
    AND lat.pk_val1_id         = HCUA.SITE_USE_ID
    AND hca.party_id           = hzp.party_id
    AND hca.cust_account_id    = HCSA.cust_account_id
    AND hcsa.cust_acct_site_id = HCUA.cust_acct_site_id
    AND hzp.PARTY_TYPE         = 'ORGANIZATION'
	UNION -- Added By Mahesh on 30-Mar-2015
	SELECT hzp.party_name,
			hzp.party_number,
			TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
			lat.login_user_name,
			lat.responsibility_name,
			lat.db_user_name,
			HCUA.site_use_code ||'-'||lat.user_column_name user_column_name,
			lat.user_old_value,
			lat.user_new_value,
			lat.table_name
	FROM laud_audit_transactions LAT,
		hz_locations HZL,
		hz_cust_acct_sites_all HCSA,
		hz_party_sites HPS,
		hz_cust_site_uses_all HCUA,
		hz_parties hzp
	WHERE LAT.table_name       = 'HZ_LOCATIONS'
	AND lat.pk_val1_id         = HZL.location_id
	AND HCSA.party_site_id     = HPS.party_site_id
	AND HPS.location_id        = HZL.location_id
	AND HCSA.cust_acct_site_id = HCUA.cust_acct_site_id
	AND hps.party_id           = hzp.party_id
	AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
	AND lat.login_user_name  = NVL(p_changed_by, lat.login_user_name)
	AND hzp.party_id         = NVL(p_party_id, hzp.party_id)
	AND lat.user_column_name = NVL(p_field, lat.user_column_name)
    UNION -- Added By Sukanya on 17-Apr-2015
    SELECT hzp.party_name,
        hzp.party_number,
        TO_CHAR(lat.transaction_date, 'DD-MON-YYYY HH24:MI:SS') transaction_date,
        lat.login_user_name,
        lat.responsibility_name,
        lat.db_user_name,
        lat.user_column_name,
        lat.user_old_value,
        lat.user_new_value,
        lat.table_name
      FROM laud_audit_transactions lat,
        hz_parties hzp,
        hz_cust_accounts hca
      WHERE lat.table_name = 'HZ_CUST_ACCOUNTS'
      AND (lat.transaction_date BETWEEN fnd_conc_date.string_to_date(NVL(p_start_date, sysdate - 1000)) AND fnd_conc_date.string_to_date(NVL(p_end_date, sysdate + 1)))
      AND lat.login_user_name  = NVL(p_changed_by, lat.login_user_name)
      AND lat.pk_val1_id       = NVL(p_party_id, lat.pk_val1_id)
      AND lat.user_column_name = NVL(p_field, lat.user_column_name)
      AND lat.pk_val1_id       = hca.cust_account_id
      AND hca.party_id = hzp.party_id
      AND hzp.PARTY_TYPE = 'ORGANIZATION'
	)
    ORDER BY transaction_date ASC,
      party_name ASC,
      user_column_name ASC;
    l_index             NUMBER         := 0;
    l_party_name        VARCHAR2(200)  := 'All Customers';
    l_cust_number       VARCHAR2(200)  := NULL ; -- Added By Bhaskar
    lv_user_column_name VARCHAR2(2000) := NULL;  -- Added by Balaji
  BEGIN
    IF p_party_id IS NOT NULL THEN
      SELECT party_name
      INTO l_party_name
      FROM HZ_PARTIES
      WHERE party_id = p_party_id;
    END IF;
    fnd_file.put_line (fnd_file.output, 'INTG Customer Change Tracking History Report');
    fnd_file.put_line (fnd_file.output, 'History Start Date: ' || NVL(p_start_date, 'Any'));
    fnd_file.put_line (fnd_file.output, 'History End Date: ' || NVL(p_end_date, 'Any'));
    fnd_file.put_line (fnd_file.output, 'Changed By: ' || NVL(p_changed_by, 'All Users'));
    fnd_file.put_line (fnd_file.output, 'Customer Name: ' || l_party_name);
    fnd_file.put_line (fnd_file.output, 'Field Name: ' || NVL(p_field, 'All fields'));
    FOR customer_rec IN customer_data
    LOOP
      -- Addition of Code by Bhaskar starts
      BEGIN
        SELECT hca.account_number
        INTO l_cust_number
        FROM hz_cust_accounts hca,
          hz_parties hp
        WHERE hca.party_id  = hp.party_id
        AND hp.party_number = customer_rec.party_number;
      EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        l_cust_number := 'There are more than One Customer Accounts for this Party';
      WHEN OTHERS THEN
        l_cust_number := NULL;
      END ;
      -- End of addition of code by Bhaskar
      l_index   := l_index + 1;
      IF l_index = 1 THEN
        fnd_file.put_line (fnd_file.output, 'Customer Name ;Customer Number ; Customer Account Number ;Changed On ;Changed By ;Responsibility ; User_Name ; Field ;Old Value;New Value');
      END IF;
      IF customer_rec.user_column_name='Attribute7' AND customer_rec.table_name='HZ_CUST_ACCT_SITES_ALL' THEN
        lv_user_column_name          := 'Territory';
      ELSE
        lv_user_column_name := customer_rec.user_column_name;
      END IF; -- This logic is added by balaji
      /*fnd_file.put_line (fnd_file.output, customer_rec.party_name          || ';       ' ||
      customer_rec.party_number        || ';       ' ||
      l_cust_number                    || ';       ' ||  -- Added By Bhaskar
      customer_rec.transaction_date    || ';       ' ||
      customer_rec.login_user_name     || ';       ' ||
      customer_rec.responsibility_name || ';       ' ||
      customer_rec.db_user_name        || ';       ' ||
      --customer_rec.user_column_name    || ';' || -- Commented by balaji
      lv_user_column_name              || ';       ' ||  -- added by Balaji
      customer_rec.user_old_value      || ';       ' ||
      customer_rec.user_new_value);*/
      -- Commented By MAHESH on 04-Aug-2014
      -- Added By Mahesh on 04-Aug-2014 After Removing SPACE
      fnd_file.put_line (fnd_file.output, customer_rec.party_name || ';' || customer_rec.party_number || ';' || l_cust_number || ';' || -- Added By Bhaskar
      customer_rec.transaction_date || ';' || customer_rec.login_user_name || ';' || customer_rec.responsibility_name || ';' || customer_rec.db_user_name || ';' ||
      --customer_rec.user_column_name    || ';' || -- Commented by balaji
      lv_user_column_name || ';' || -- added by Balaji
      customer_rec.user_old_value || ';' || customer_rec.user_new_value);
    END LOOP;
    IF l_index = 0 THEN
      fnd_file.put_line (fnd_file.output, '*** No change history found for the given criteria ***');
    END IF;
  END customer_change_data_report;
END xx_grc_chg_trk_pkg;
/
