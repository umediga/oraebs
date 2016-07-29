DROP PACKAGE BODY APPS.XX_CN_ORTHO_CREDIT_TRANSFER;

CREATE OR REPLACE PACKAGE BODY APPS.XX_CN_ORTHO_CREDIT_TRANSFER AS
-- Global variables
--  g_org_id NUMBER := 101; --149; --101; -- := fnd_profile.VALUE ('ORG_ID'); - Testing
  g_org_id NUMBER := fnd_profile.VALUE ('ORG_ID'); -- To run
  g_conc_request_id NUMBER := fnd_global.conc_request_id;
  g_process VARCHAR2(50);
  g_sysdate DATE := SYSDATE;
--  g_user_id NUMBER := 1711; --fnd_profile.Value ('USER_ID'); 'DIANA.KIM' - Testing
  g_user_id NUMBER := fnd_profile.Value ('USER_ID');  -- To run
  g_error_msg VARCHAR2 (4000);
  g_resp_id NUMBER := apps.fnd_global.resp_id;
  g_application_id NUMBER;
  g_debug_flag VARCHAR2(1) := 'Y';
  g_exception   EXCEPTION;

  PROCEDURE set_org_context(p_org_id in number) is
    BEGIN
      apps.mo_global.set_policy_context('S',p_org_id);
  END set_org_context;

  PROCEDURE write_output (p_type IN VARCHAR2, p_string IN VARCHAR2) AS
    BEGIN
      IF fnd_global.conc_request_id > 1 THEN
        IF p_type = 'OUT' THEN
          fnd_file.put_line (fnd_file.output, p_string);
        ELSE
          fnd_file.put_line (fnd_file.LOG, p_string);
        END IF;
      ELSE
--        fnd_file.put_line (fnd_file.LOG, p_string);
        DBMS_OUTPUT.put_line (p_string);
 --        null;
      END IF;
  END write_output;

  PROCEDURE check_record_count(p_period_id IN NUMBER,x_record_count OUT NOCOPY NUMBER) AS

    l_record_count NUMBER;

    BEGIN
      IF g_debug_flag = 'Y' then
        write_output('LOG', 'Start - check_record_count procedure');
      END IF;

      l_record_count := 0;

      SELECT COUNT(*)
      INTO l_record_count
      --select cch.invoice_number,cch.attribute41 order_number,cch.commission_header_id,cch.comm_lines_api_id,cch.status,cch.adjust_status,cch.attribute72,jrd.resource_name
      FROM apps.cn_commission_headers_all cch,
           apps.jtf_rs_salesreps jrs,
           apps.jtf_rs_defresources_v jrd,
           apps.jtf_rs_salesreps jrsa,
           apps.jtf_rs_defresources_v jrda
      WHERE 1=1
      AND cch.processed_period_id = p_period_id --2015006
      AND cch.attribute4 IN ('ORTHO','SPINE') --KM20160325 INCLUDED SPINE
      AND cch.attribute72 is not NULL
      AND UPPER(cch.attribute72) NOT IN ('NO SALES REP','NO SALES CREDIT')
      AND cch.adjust_status NOT IN ('FROZEN','REVERSAL')
      AND cch.status IN ('ROLL')
      AND trx_type NOT IN ('ITD','GRP','THR')
      AND jrs.salesrep_id = cch.direct_salesrep_id
      AND jrd.resource_id = jrs.resource_id
      AND jrs.salesrep_number not in ('-3') -- KM20160405 EARLIER IT WAS like   in ('-3','-9999')
      AND TRIM(cch.attribute72) <> jrd.resource_name
      AND jrda.resource_name = TRIM(cch.attribute72)
      AND jrsa.resource_id = jrda.resource_id;

      x_record_count := l_record_count;

      if g_debug_flag = 'Y' then
        write_output('LOG', 'End - check_record_count procedure');
      end if;

  END check_record_count;

  PROCEDURE create_alt_salesrep_api_record (p_comm_header_id IN NUMBER,
                                            p_adjusted_by IN VARCHAR2,
                                            p_adjust_comments IN VARCHAR2) AS

    l_api_rec   cn_comm_lines_api_pkg.comm_lines_api_rec_type;

    l_comm_lines_api_id NUMBER;
    l_record_count NUMBER;
    l_adjust_status VARCHAR2(20);
    l_adjust_date   DATE := SYSDATE;

    CURSOR header_cur (p_comm_header_id IN NUMBER) IS
      SELECT jrs.salesrep_id alt_salesrep_id,cch.*
      FROM apps.cn_commission_headers_all cch,
          apps.jtf_rs_defresources_v jrd,
           apps.jtf_rs_salesreps jrs
      WHERE cch.commission_header_id = p_comm_header_id
      AND jrd.resource_name = cch.attribute72
      AND jrs.resource_id = jrd.resource_id;

    BEGIN
       IF g_debug_flag = 'Y' then
        write_output('LOG', 'Start - create_alt_salesrep_api_record procedure');
      END IF;
      l_record_count := 0;

      FOR api_curs_rec IN header_cur(p_comm_header_id)
	    LOOP
	       --
	       SELECT cn_comm_lines_api_s.NEXTVAL
	         INTO l_comm_lines_api_id
	         FROM dual;
	       --
         l_api_rec.salesrep_id			:= api_curs_rec.alt_salesrep_id;
         l_api_rec.processed_date			:= api_curs_rec.processed_date;
         l_api_rec.processed_period_id		:= api_curs_rec.processed_period_id;
         l_api_rec.transaction_amount		:= api_curs_rec.transaction_amount;
         l_api_rec.trx_type			:= api_curs_rec.trx_type;
         l_api_rec.revenue_class_id		:= api_curs_rec.revenue_class_id;
         l_api_rec.load_status			:= 'UNLOADED';
         l_api_rec.attribute1			:= api_curs_rec.attribute1;
         l_api_rec.attribute2			:= api_curs_rec.attribute2;
         l_api_rec.attribute3			:= api_curs_rec.attribute3;
         l_api_rec.attribute4			:= api_curs_rec.attribute4;
         l_api_rec.attribute5			:= api_curs_rec.attribute5;
         l_api_rec.attribute6			:= api_curs_rec.attribute6;
         l_api_rec.attribute7			:= api_curs_rec.attribute7;
         l_api_rec.attribute8			:= api_curs_rec.attribute8;
         l_api_rec.attribute9			:= api_curs_rec.attribute9;
         l_api_rec.attribute10			:= api_curs_rec.attribute10;
         l_api_rec.attribute11			:= api_curs_rec.attribute11;
         l_api_rec.attribute12			:= api_curs_rec.attribute12;
         l_api_rec.attribute13			:= api_curs_rec.attribute13;
         l_api_rec.attribute14			:= api_curs_rec.attribute14;
         l_api_rec.attribute15			:= api_curs_rec.attribute15;
         l_api_rec.attribute16			:= api_curs_rec.attribute16;
         l_api_rec.attribute17			:= api_curs_rec.attribute17;
         l_api_rec.attribute18			:= api_curs_rec.attribute18;
         l_api_rec.attribute19			:= api_curs_rec.attribute19;
         l_api_rec.attribute20			:= api_curs_rec.attribute20;
         l_api_rec.attribute21			:= api_curs_rec.attribute21;
         l_api_rec.attribute22			:= api_curs_rec.attribute22;
         l_api_rec.attribute23			:= api_curs_rec.attribute23;
         l_api_rec.attribute24			:= api_curs_rec.attribute24;
         l_api_rec.attribute25			:= api_curs_rec.attribute25;
         l_api_rec.attribute26			:= api_curs_rec.attribute26;
         l_api_rec.attribute27			:= api_curs_rec.attribute27;
         l_api_rec.attribute28			:= api_curs_rec.attribute28;
         l_api_rec.attribute29			:= api_curs_rec.attribute29;
         l_api_rec.attribute30			:= api_curs_rec.attribute30;
         l_api_rec.attribute31			:= api_curs_rec.attribute31;
         l_api_rec.attribute32			:= api_curs_rec.attribute32;
         l_api_rec.attribute33			:= api_curs_rec.attribute33;
         l_api_rec.attribute34			:= api_curs_rec.attribute34;
         l_api_rec.attribute35			:= api_curs_rec.attribute35;
         l_api_rec.attribute36			:= api_curs_rec.attribute36;
         l_api_rec.attribute37			:= api_curs_rec.attribute37;
         l_api_rec.attribute38			:= api_curs_rec.attribute38;
         l_api_rec.attribute39			:= api_curs_rec.attribute39;
         l_api_rec.attribute40			:= api_curs_rec.attribute40;
         l_api_rec.attribute41			:= api_curs_rec.attribute41;
         l_api_rec.attribute42			:= api_curs_rec.attribute42;
         l_api_rec.attribute43			:= api_curs_rec.attribute43;
         l_api_rec.attribute44			:= api_curs_rec.attribute44;
         l_api_rec.attribute45			:= api_curs_rec.attribute45;
         l_api_rec.attribute46			:= api_curs_rec.attribute46;
         l_api_rec.attribute47			:= api_curs_rec.attribute47;
         l_api_rec.attribute48			:= api_curs_rec.attribute48;
         l_api_rec.attribute49			:= api_curs_rec.attribute49;
         l_api_rec.attribute50			:= api_curs_rec.attribute50;
         l_api_rec.attribute51			:= api_curs_rec.attribute51;
         l_api_rec.attribute52			:= api_curs_rec.attribute52;
         l_api_rec.attribute53			:= api_curs_rec.attribute53;
         l_api_rec.attribute54			:= api_curs_rec.attribute54;
         l_api_rec.attribute55			:= api_curs_rec.attribute55;
         l_api_rec.attribute56			:= api_curs_rec.attribute56;
         l_api_rec.attribute57			:= api_curs_rec.attribute57;
         l_api_rec.attribute58			:= api_curs_rec.attribute58;
         l_api_rec.attribute59			:= api_curs_rec.attribute59;
         l_api_rec.attribute60			:= api_curs_rec.attribute60;
         l_api_rec.attribute61			:= api_curs_rec.attribute61;
         l_api_rec.attribute62			:= api_curs_rec.attribute62;
         l_api_rec.attribute63			:= api_curs_rec.attribute63;
         l_api_rec.attribute64			:= api_curs_rec.attribute64;
         l_api_rec.attribute65			:= api_curs_rec.attribute65;
         l_api_rec.attribute66			:= api_curs_rec.attribute66;
         l_api_rec.attribute67			:= api_curs_rec.attribute67;
         l_api_rec.attribute68			:= api_curs_rec.attribute68;
         l_api_rec.attribute69			:= api_curs_rec.attribute69;
         l_api_rec.attribute70			:= api_curs_rec.attribute70;
         l_api_rec.attribute71			:= api_curs_rec.attribute71;
         l_api_rec.attribute72			:= api_curs_rec.attribute72;
         l_api_rec.attribute73			:= api_curs_rec.attribute73;
         l_api_rec.attribute74			:= api_curs_rec.attribute74;
         l_api_rec.attribute75			:= api_curs_rec.attribute75;
         l_api_rec.attribute76			:= api_curs_rec.attribute76;
         l_api_rec.attribute77			:= api_curs_rec.attribute77;
         l_api_rec.attribute78			:= api_curs_rec.attribute78;
         l_api_rec.attribute79			:= api_curs_rec.attribute79;
         l_api_rec.attribute80			:= api_curs_rec.attribute80;
         l_api_rec.attribute81			:= api_curs_rec.attribute81;
         l_api_rec.attribute82			:= api_curs_rec.attribute82;
         l_api_rec.attribute83			:= api_curs_rec.attribute83;
         l_api_rec.attribute84			:= api_curs_rec.attribute84;
         l_api_rec.attribute85			:= api_curs_rec.attribute85;
         l_api_rec.attribute86			:= api_curs_rec.attribute86;
         l_api_rec.attribute87			:= api_curs_rec.attribute87;
         l_api_rec.attribute88			:= api_curs_rec.attribute88;
         l_api_rec.attribute89			:= api_curs_rec.attribute89;
         l_api_rec.attribute90			:= api_curs_rec.attribute90;
         l_api_rec.attribute91			:= api_curs_rec.attribute91;
         l_api_rec.attribute92			:= api_curs_rec.attribute92;
         l_api_rec.attribute93			:= api_curs_rec.attribute93;
         l_api_rec.attribute94			:= api_curs_rec.attribute94;
         l_api_rec.attribute95			:= api_curs_rec.attribute95;
         l_api_rec.attribute96			:= api_curs_rec.attribute96;
         l_api_rec.attribute97			:= api_curs_rec.attribute97;
         l_api_rec.attribute98			:= api_curs_rec.attribute98;
         l_api_rec.attribute99			:= api_curs_rec.attribute99;
         l_api_rec.attribute100			:= api_curs_rec.attribute100;
--               l_api_rec.employee_number		:= api_curs_rec.employee_number;
         l_api_rec.comm_lines_api_id		:= l_comm_lines_api_id;
         l_api_rec.conc_batch_id			:= NULL;
         l_api_rec.process_batch_id		:= NULL;
         -- l_api_rec.salesrep_number
         -- := api_curs_rec.employee_number;
         -- obsoleted column bug2131915
         l_api_rec.salesrep_number        := NULL;
         l_api_rec.rollup_date			:= api_curs_rec.rollup_date;
         --l_api_rec.rollup_period_id		:= NULL;
         l_api_rec.source_doc_id			:= NULL;
         l_api_rec.source_doc_type		:= api_curs_rec.source_doc_type;
         l_api_rec.transaction_currency_code	:= api_curs_rec.orig_currency_code;
         l_api_rec.exchange_rate			:= api_curs_rec.exchange_rate;
         l_api_rec.acctd_transaction_amount	:= api_curs_rec.transaction_amount;
         l_api_rec.trx_id				    := NULL; --api_curs_rec.trx_id;
         l_api_rec.trx_line_id 			:= NULL; --api_curs_rec.trx_line_id;
         l_api_rec.trx_sales_line_id		:= NULL; --api_curs_rec.trx_sales_line_id;
         l_api_rec.quantity			:= api_curs_rec.quantity;
         l_api_rec.source_trx_number		:= api_curs_rec.source_trx_number;
         l_api_rec.discount_percentage	:= api_curs_rec.discount_percentage;
         l_api_rec.margin_percentage 		:= api_curs_rec.margin_percentage;
         l_api_rec.pre_defined_rc_flag	:= NULL;
         l_api_rec.rollup_flag			:= NULL;
         l_api_rec.forecast_id			:= api_curs_rec.forecast_id;
         l_api_rec.upside_quantity 		:= api_curs_rec.upside_quantity;
         l_api_rec.upside_amount			:= api_curs_rec.upside_amount;
         l_api_rec.uom_code  			    := api_curs_rec.uom_code;
         l_api_rec.source_trx_id 			:= api_curs_rec.source_trx_id;
         l_api_rec.source_trx_line_id		:= api_curs_rec.source_trx_line_id;
         l_api_rec.source_trx_sales_line_id 	:= api_curs_rec.source_trx_sales_line_id;
         l_api_rec.negated_flag			:= NULL;
         l_api_rec.customer_id			:= api_curs_rec.customer_id;
         l_api_rec.inventory_item_id		:= api_curs_rec.inventory_item_id;
         l_api_rec.order_number			:= api_curs_rec.order_number;
         l_api_rec.booked_date 			:= api_curs_rec.booked_date;
         l_api_rec.invoice_number			:= api_curs_rec.invoice_number;
         l_api_rec.invoice_date			:= api_curs_rec.invoice_date;
         l_api_rec.bill_to_address_id		:= api_curs_rec.bill_to_address_id;
         l_api_rec.ship_to_address_id		:= api_curs_rec.ship_to_address_id;
         l_api_rec.bill_to_contact_id		:= api_curs_rec.bill_to_contact_id;
         l_api_rec.ship_to_contact_id		:= api_curs_rec.ship_to_contact_id;
         l_api_rec.adj_comm_lines_api_id	:= api_curs_rec.comm_lines_api_id;
         l_api_rec.adjust_date			:= l_adjust_date;
         l_api_rec.adjusted_by 			:= p_adjusted_by;
         l_api_rec.revenue_type 			:= api_curs_rec.revenue_type;
         l_api_rec.adjust_rollup_flag 	:= NULL;
         l_api_rec.adjust_comments		:= p_adjust_comments;
         l_api_rec.adjust_status 			:= NVL(l_adjust_status,'NEW');
         l_api_rec.line_number 			:= api_curs_rec.line_number;
   /* codeCheck: Is it correct? */
         l_api_rec.reason_code			:= api_curs_rec.reason_code;
         l_api_rec.attribute_category 	:= api_curs_rec.attribute_category;
         l_api_rec.type  				    := api_curs_rec.type;
         l_api_rec.pre_processed_code 	:= api_curs_rec.pre_processed_code;
         l_api_rec.quota_id 			    := api_curs_rec.quota_id;
         l_api_rec.srp_plan_assign_id 	:= api_curs_rec.srp_plan_assign_id;
         l_api_rec.role_id  			    := api_curs_rec.role_id;
         l_api_rec.comp_group_id 			:= api_curs_rec.comp_group_id;
   /* codeCheck: Is it correct? */
         l_api_rec.commission_amount		:= NULL;
         l_api_rec.reversal_flag			:= NULL;
         l_api_rec.reversal_header_id		:= NULL;
         l_api_rec.sales_channel 			:= api_curs_rec.sales_channel;
         l_api_rec.split_pct 		       	:= api_curs_rec.split_pct;
         l_api_rec.split_status 		    := api_curs_rec.split_status;
         l_api_rec.org_id               := api_curs_rec.org_id; -- vensrini.
         l_api_rec.terr_id              := NULL;
         l_api_rec.terr_name            := NULL;
         l_api_rec.preserve_credit_override_flag  := 'N';
	       --
         cn_comm_lines_api_pkg.insert_row(l_api_rec);
       END LOOP;

       IF g_debug_flag = 'Y' then
        write_output('LOG', 'End - create_alt_salesrep_api_record procedure');
      END IF;

  END create_alt_salesrep_api_record;

  PROCEDURE process_credit_transfer (p_period_id IN NUMBER, p_adjusted_by IN VARCHAR2,
                                      p_adjust_comments IN VARCHAR2) AS

      l_record_count NUMBER;
      l_commission_header_id NUMBER;
      l_comm_lines_api_id NUMBER;
      l_invoice_number VARCHAR2(20);
      l_line_number NUMBER;
      l_order_number VARCHAR2(20);
      l_alt_salesrep_name VARCHAR2(100);
      l_alt_salesrep_number NUMBER;
      l_alt_salesrep_id NUMBER;
      l_curr_salesrep_name VARCHAR2(100);
      l_curr_salesrep_number NUMBER;
      l_curr_salesrep_id NUMBER;

      CURSOR comm_header_cur (p_period_id IN NUMBER) IS
      SELECT  --count(*) record_count
        cch.commission_header_id,cch.comm_lines_api_id,
        cch.invoice_number,cch.line_number,cch.attribute41 order_number, --cch.status,cch.adjust_status,
        cch.attribute72 alt_salesrep_name,jrsa.salesrep_number alt_salesrep_number,jrsa.salesrep_id alt_salesrep_id,
        jrd.resource_name curr_salesrep_name,jrs.salesrep_number curr_salesrep_number,jrs.salesrep_id curr_salesrep_id
      FROM apps.cn_commission_headers_all cch,
           apps.jtf_rs_salesreps jrs,
           apps.jtf_rs_defresources_v jrd,
           apps.jtf_rs_salesreps jrsa,
           apps.jtf_rs_defresources_v jrda
      WHERE 1=1
      AND cch.processed_period_id = p_period_id --2015006
      AND cch.attribute4 IN  ('ORTHO','SPINE') -- KM20160325 INCLUDED SPINE
      AND cch.attribute72 is not NULL
      AND UPPER(cch.attribute72) NOT IN ('NO SALES REP','NO SALES CREDIT')
      AND cch.adjust_status NOT IN ('FROZEN','REVERSAL')
      AND cch.status IN ('ROLL')
      AND trx_type NOT IN ('ITD','GRP','THR')
      AND jrs.salesrep_id = cch.direct_salesrep_id
      AND jrd.resource_id = jrs.resource_id
      AND jrs.salesrep_number not in ('-3') -- KM20160405 EARLIER IT WAS like   in ('-3','-9999')
      AND TRIM(cch.attribute72) <> jrd.resource_name
      AND jrda.resource_name = TRIM(cch.attribute72)
      AND jrsa.resource_id = jrda.resource_id;

    BEGIN
      IF g_debug_flag = 'Y' then
        write_output('LOG', 'Start - process_credit_transfer procedure');
      END IF;

      l_record_count := 0;

/*
      SELECT  --count(*) record_count
      cch.commission_header_id,cch.comm_lines_api_id,
      cch.invoice_number,cch.line_number,cch.attribute41 order_number, --cch.status,cch.adjust_status,
      cch.attribute72 atl_salesrep,jrsa.salesrep_number,jrsa.salesrep_id,
      jrd.resource_name,jrs.salesrep_number,jrs.salesrep_id
      INTO
      l_commission_header_id,l_comm_lines_api_id,l_invoice_number,l_line_number,l_order_number,
      l_alt_salesrep_name,l_alt_salesrep_number,l_alt_salesrep_id,
      l_curr_salesrep_name,l_curr_salesrep_number,l_curr_salesrep_id
      --cch.* --distinct Status, adjust_status
      FROM apps.cn_commission_headers_all cch,
           apps.jtf_rs_salesreps jrs,
           apps.jtf_rs_defresources_v jrd,
           apps.jtf_rs_salesreps jrsa,
           apps.jtf_rs_defresources_v jrda
      WHERE 1=1
      AND cch.processed_period_id = 2015006
      AND cch.attribute4 = 'ORTHO'
      AND cch.attribute72 is not NULL
      AND UPPER(cch.attribute72) NOT IN ('NO SALES REP','NO SALES CREDIT')
      AND cch.adjust_status NOT IN ('FROZEN','REVERSAL')
      --AND cch.status IN ('ROLL')
      AND trx_type NOT IN ('ITD','GRP','THR')
      AND jrs.salesrep_id = cch.direct_salesrep_id
      AND jrd.resource_id = jrs.resource_id
      AND jrs.salesrep_number not in ('-3','-9999')
      AND trim(cch.attribute72) <> jrd.resource_name
      AND jrda.resource_name = trim(cch.attribute72)
*/

      FOR comm_header_rec IN comm_header_cur(p_period_id)
	    LOOP

        EXIT WHEN comm_header_cur%NOTFOUND;
        l_record_count := l_record_count + 1;

        l_commission_header_id := comm_header_rec.commission_header_id;
        l_comm_lines_api_id := comm_header_rec.comm_lines_api_id;
        l_invoice_number  := comm_header_rec.invoice_number;
        l_line_number := comm_header_rec.line_number;
        l_order_number := comm_header_rec.order_number;
        l_alt_salesrep_name := comm_header_rec.alt_salesrep_name;
        l_alt_salesrep_number := comm_header_rec.alt_salesrep_number;
        l_alt_salesrep_id := comm_header_rec.alt_salesrep_id;
        l_curr_salesrep_name := comm_header_rec.curr_salesrep_name;
        l_curr_salesrep_number := comm_header_rec.curr_salesrep_number;
        l_curr_salesrep_id := comm_header_rec.curr_salesrep_id;

        write_output('LOG', 'Processing Invoice#: ' || l_invoice_number || ' Line#: ' || l_line_number);
        write_output('LOG', 'Current Salesrep: ' || l_curr_salesrep_name);
        write_output('LOG', 'Alternate Salesrep: ' || l_alt_salesrep_name);

        create_alt_salesrep_api_record (l_commission_header_id,p_adjusted_by,p_adjust_comments);

        cn_adjustments_pkg.api_negate_record(
                    l_comm_lines_api_id,
                    p_adjusted_by,
                    p_adjust_comments,
                    l_curr_salesrep_number);
      END LOOP;

      write_output('LOG', 'Total Record processed Count: ' || l_record_count);

      IF g_debug_flag = 'Y' then
        write_output('LOG', 'End - process_credit_transfer procedure');
      END IF;

  END process_credit_transfer;

  PROCEDURE ORTHO_SALES_CREDIT_TRANSFER (
      	errbuf                  	OUT       VARCHAR2,
      	retcode                 	OUT       VARCHAR2,
        p_period 	      		      IN	      VARCHAR2
   ) AS

    l_user_id NUMBER := -1;
    l_resp_id NUMBER := -1;
    l_application_id NUMBER := -1;
    l_user_name VARCHAR2(30) := 'DIANA.KIM';
    l_resp_name VARCHAR2(30) := 'INTG_US_CN_INC_COMP_MANAGER';
    l_param_error_flg NUMBER;
    l_transfer_req_id NUMBER;
    l_period  VARCHAR2(20);
    l_period_id NUMBER;
    l_adjusted_by VARCHAR2(50);
    l_adjust_comments VARCHAR2(100);
    x_last_updated_invoice_number NUMBER;
    x_last_updated_invoice_line NUMBER;
    x_record_count NUMBER;


-- testing
    x_roleid         NUMBER;
    x_msg_count      NUMBER;
    x_msg_data       VARCHAR2(400);
    x_return_status  VARCHAR2(1);
    x_invoice_count   NUMBER;
    x_transfer_req_id NUMBER;

  BEGIN
    g_process :='0001-0010';
    errbuf := 'Start - ORTHO_SALES_CREDIT_TRANSFER';
    write_output('LOG', g_process || '; ' || retcode || '-' || errbuf);
    write_output('LOG', '----------------------------------------------');
    write_output('LOG', 'Parameters:');
    write_output('LOG', ' --Login Org id: ' || g_org_id);
    write_output('LOG', ' --Concurrent program id: ' || g_conc_request_id);
    write_output('LOG', ' --Input Param p_period: ' || p_period);
    write_output('LOG', '----------------------------------------------');

--    set_org_context(g_org_id);
    l_adjust_comments := 'Ortho Sales Credit Transafer for: ' || p_period;
--   Start of for testing only -- setup for Org context, responsibility, application and user id
/*
    -- Get the user_id
    SELECT user_id
    INTO l_user_id
    FROM fnd_user
    WHERE user_name = l_user_name;
    l_adjusted_by := l_user_name;

    -- Get the application_id and responsibility_id
    SELECT application_id, responsibility_id
    INTO l_application_id, l_resp_id
    FROM fnd_responsibility
    WHERE responsibility_key = l_resp_name;
    g_application_id := l_application_id;
    FND_GLOBAL.APPS_INITIALIZE(l_user_id, l_resp_id, l_application_id);
-- End of for Testing
*/
-- Start - To Run
/**/
    l_user_id := g_user_id;
    SELECT user_name
    INTO l_adjusted_by
    FROM apps.fnd_user
    WHERE user_id = l_user_id;


    SELECT application_id, responsibility_id
    INTO l_application_id, l_resp_id
    FROM fnd_responsibility
    WHERE responsibility_id = g_resp_id;

/**/
-- End to Run
    g_application_id := l_application_id;
    if g_debug_flag = 'Y' then
      write_output('LOG', 'User detail: '|| l_user_id || ' '|| l_resp_id ||' '|| l_application_id );
    end if;

--    FND_GLOBAL.APPS_INITIALIZE(l_user_id, l_resp_id, l_application_id);

--    fnd_profile.put('AFLOG_ENABLED', 'N');
--    fnd_profile.put('AFLOG_MODULE', '%');
--    fnd_profile.put('AFLOG_LEVEL','1');
--    fnd_log_repository.init;
    write_output('LOG', 'Initialized applications context1: '|| l_user_id || ' '|| l_resp_id ||' '|| l_application_id );
     SELECT period_id
     INTO l_period_id
     FROM apps.cn_periods
     WHERE period_name = p_period;
     check_record_count (l_period_id,x_record_count);
      write_output('LOG', 'Record Counts: ' || x_record_count);

     IF x_record_count = 0 THEN
       write_output('LOG', '** Message - No record for update: ' || x_record_count);
--        raise g_exception;
    ELSE
       write_output('LOG', 'Processing  - Credit Transfer: ' || x_record_count);
       process_credit_transfer(l_period_id,l_adjusted_by,l_adjust_comments);
    END IF;

    EXCEPTION
      WHEN OTHERS THEN
        write_output('LOG', 'Rollback done');
        rollback;
        write_output('LOG', 'ERRORS: ' || sqlerrm);
        retcode := 2;
        errbuf := substr(sqlerrm,1,240);
  END;

END XX_CN_ORTHO_CREDIT_TRANSFER;
/
