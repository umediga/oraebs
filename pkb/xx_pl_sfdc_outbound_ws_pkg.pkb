DROP PACKAGE BODY APPS.XX_PL_SFDC_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PL_SFDC_OUTBOUND_WS_PKG" 
IS
  ----------------------------------------------------------------------
  /*
  Created By    : Arvind Mishra
  Creation Date : 07-Apr-2014
  File Name     : XXPLSFDCOUTWSPKG.pkb
  Description   : This package is being called from FMW,
                  which is being used to send Price List
                  List Price from EBS to SFDC,
  -------------------------------------------------------------------------
  /* High level approach
  1. Update instance Id to control Table for a batch : UPDATE_INSTANCE
  2. Run the View to extract data for a batch making join to control table
  3. Insert the extracted data in staging table.
  4. Run the multyset view with batch and load data out variable
  5. Populate the error status

  Change History
===================
------------------------------------------------------------------------
Date          VER     Name   | Remarks
-------------|----|----------|------------------------------------------
28-Feb-2014  | 1.0 |AMishra  | Initial development.
-------------|-----|---------|-----------------------------------------
09-Jul-2014  | 1.1 |AMishra  | Modified logic for Start date and End date
             |     |         | to restrict future dated records.
-------------|-----|---------|------------------------------------------
21-Aug-2014  | 1.2 |Bedabrata| Modified logic to filter inactive items and
             |     |         | send only active records. case# 9410
25-Sep-2014  | 1.3 |Bedabrata| Modified inactive logic for Wave2
-------------|-----|---------|------------------------------------------
05-Sep-2014  | 1.4 |Vishal   | Fixed bug for multiple pricelist
-------------|-----|---------|------------------------------------------
 */

  --- Variables used across Procedures
   x_user_id        NUMBER        := fnd_global.user_id;
   x_resp_id        NUMBER        := fnd_global.resp_id;
   x_resp_appl_id   NUMBER        := fnd_global.resp_appl_id;
   x_login_id       NUMBER        := fnd_global.login_id;
   x_request_id     NUMBER        := fnd_global.conc_request_id;

   g_object_name    VARCHAR2 (30) := 'XXSFDCPRLIST';
   G_stage	        VARCHAR2(60);
   G_MODE           VARCHAR2(10) := 'LOG';
---
---
PROCEDURE update_lookup (p_pl_name VARCHAR2, p_curr_pl_id NUMBER, p_old_pl_id NUMBER)
is
  cursor cur (cp_pl_name VARCHAR2)
  is
  select * from fnd_lookup_values flv
   where flv.lookup_type = 'XX_PL_TO_SFDC_INTEGRATION' -- Added for wave2
  AND flv.description = cp_pl_name --'ILS LIST PRICE'
  AND flv.language = userenv('LANG')
  AND flv.enabled_flag = 'Y'
  and SYSDATE between flv.start_date_active and nvl(flv.end_date_active,sysdate+1);
begin
  for rec in cur (p_pl_name)
  loop
  fnd_lookup_values_pkg.UPDATE_ROW (
    X_LOOKUP_TYPE=> 'XX_PL_TO_SFDC_INTEGRATION',
    X_SECURITY_GROUP_ID => rec.SECURITY_GROUP_ID,
    X_VIEW_APPLICATION_ID => rec.VIEW_APPLICATION_ID,
    X_LOOKUP_CODE => rec.lookup_code,
    X_TAG => rec.tag,
    X_ATTRIBUTE_CATEGORY => rec.ATTRIBUTE_CATEGORY,
    X_ATTRIBUTE1 => rec.ATTRIBUTE1,
    X_ATTRIBUTE2 => rec.ATTRIBUTE2,
    X_ATTRIBUTE3 => rec.ATTRIBUTE3,
    X_ATTRIBUTE4 => rec.ATTRIBUTE4,
    X_ENABLED_FLAG => rec.ENABLED_FLAG,
    X_START_DATE_ACTIVE => rec.START_DATE_ACTIVE,
    X_END_DATE_ACTIVE => rec.END_DATE_ACTIVE,
    X_TERRITORY_CODE => rec.TERRITORY_CODE,
    X_ATTRIBUTE5 => rec.ATTRIBUTE5,
    X_ATTRIBUTE6 => rec.ATTRIBUTE6,
    X_ATTRIBUTE7 => rec.ATTRIBUTE7,
    X_ATTRIBUTE8 => rec.ATTRIBUTE8,
    X_ATTRIBUTE9 => rec.ATTRIBUTE9,
    X_ATTRIBUTE10 => rec.ATTRIBUTE10,
    X_ATTRIBUTE11 => rec.ATTRIBUTE11,
    X_ATTRIBUTE12 => rec.ATTRIBUTE12,
    X_ATTRIBUTE13 => rec.ATTRIBUTE13,
    X_ATTRIBUTE14 => p_curr_pl_id, -- Current PL Id
    X_ATTRIBUTE15 => p_old_pl_id, --  Old PL Id
    X_MEANING => rec.MEANING,
    X_DESCRIPTION => rec.description,
    X_LAST_UPDATE_DATE => SYSDATE,
    X_LAST_UPDATED_BY => x_user_id,
    X_LAST_UPDATE_LOGIN => x_login_id
    );
   end loop;
 commit;
exception
when others then
 logme('Failed while updating Lookup XX_PL_TO_SFDC_INTEGRATION. Error: '||sqlerrm);
end update_lookup;
---
    PROCEDURE get_price_list (
							 p_batch_id         IN       NUMBER,
							 p_instance_id      IN       NUMBER,
							 x_pl_output        OUT      xx_pl_sfdc_outbound_tab_typ,
							 x_return_status    OUT      VARCHAR2,
							 x_return_message   OUT      VARCHAR2
							)
   IS
   -- used pl_data since sequence.nextval doesn't work for union
      CURSOR pl_details_c
      IS select xx_pl_sfdc_staging_recid_s.NEXTVAL AS record_id,
                pl_data.control_record_id,
                pl_data.publish_batch_id,
                pl_data.LIST_HEADER_ID,
                pl_data.PRICE_LIST_NAME,
                pl_data.price_list_status,
                pl_data.use_standard_price,
                pl_data.price_list_line_id,
                pl_data.item_product,
                pl_data.currency_code,
                pl_data.list_price,
                pl_data.start_date,
                pl_data.end_date,
                pl_data.creation_date,
                pl_data.created_by,
                pl_data.last_update_date,
                pl_data.last_update_by,
                pl_data.last_update_login FROM
         (SELECT ctl.record_id AS control_record_id,
                ctl.publish_batch_id AS publish_batch_id,
                plv.pl_header_id as LIST_HEADER_ID,
                PLV.pl_primary AS PRICE_LIST_NAME,
                DECODE(SIGN(SYSDATE - nvl(plv.end_date, SYSDATE)),1,'F','T') AS price_list_status,
                'T' AS use_standard_price,
                TO_NUMBER (PLV.line_id) AS price_list_line_id,
                PLV.item     AS item_product,
                PLV.currency_code AS currency_code,
                PLV.unit_price AS list_price,
                plv.start_date as start_date,
                plv.end_date as end_date,
                SYSDATE AS creation_date,
                x_user_id  AS created_by,
                SYSDATE AS last_update_date,
                x_user_id  AS last_update_by,
                x_login_id AS last_update_login
           FROM
		        xx_price_list_sfdc_control ctl,
                xx_pl_sfdc_detail_v        PLV
          WHERE 1 = 1
            AND ctl.publish_batch_id = p_batch_id
            AND ctl.pl_line_id = PLV.line_id
			AND nvl(ctl.status,'NEW') <> 'SUCCESS'
		 UNION
         SELECT ctl.record_id AS control_record_id,
                ctl.publish_batch_id AS publish_batch_id,
                ctl.pl_header_id as LIST_HEADER_ID,
                qlh.name AS PRICE_LIST_NAME,
                'F' AS price_list_status, -- all Items from inactive PL
                'T' AS use_standard_price,
                ctl.pl_line_id AS price_list_line_id,
                msib.segment1     AS item_product,
                qlh.currency_code AS currency_code,
                0 AS list_price,
                SYSDATE as start_date,
                SYSDATE as end_date,
                SYSDATE AS creation_date,
                x_user_id  AS created_by,
                SYSDATE AS last_update_date,
                x_user_id  AS last_update_by,
                x_login_id AS last_update_login
           FROM xx_price_list_sfdc_control ctl,
                qp_pricing_attributes qpa,
                mtl_system_items_b msib,
                QP_list_headers qlh,  -- added for wave2
                FND_LOOKUP_VALUES flv
          WHERE 1 = 1
            AND ctl.publish_batch_id = p_batch_id
            AND qlh.list_header_id = ctl.pl_header_id
            AND flv.lookup_type = 'XX_PL_TO_SFDC_INTEGRATION'
            AND to_number(flv.attribute15) = qlh.list_header_id -- inactive PL id stored in attribute15 for query service
            AND upper(qlh.name) = flv.description --'ILS CANADA LIST PRICE'
            AND flv.language = userenv('LANG')
            AND flv.enabled_flag = 'Y'
            and SYSDATE between flv.start_date_active and nvl(flv.end_date_active,sysdate+1)
            AND qlh.list_header_id = qpa.list_header_id
            AND ctl.pl_line_id = qpa.list_line_id
      			AND nvl(ctl.status,'NEW') <> 'SUCCESS'
            AND qpa.product_attribute_context = 'ITEM'
            AND msib.inventory_item_id = decode (length(trim(translate(qpa.product_attr_value,'0123456789',' '))),null,qpa.product_attr_value,NULL)
            AND msib.organization_id   = (SELECT UNIQUE master_organization_id FROM mtl_parameters)
			AND not exists
            (select 1 from qp_pricing_attributes qpa
	where qpa.list_header_id = to_number(flv.attribute14) -- Current PL ID stored in attribute14 for query service
	 AND decode (length(trim(translate(qpa.product_attr_value,'0123456789',' '))),null,qpa.product_attr_value,NULL) = msib.inventory_item_id
	 AND qpa.product_attribute_context = 'ITEM')
) pl_data
where not exists (select 1 from XX_PRICE_LIST_SFDC_STAGING plst1
where plst1.control_record_id = pl_data.control_record_id )
			;

      TYPE c_details IS TABLE OF xx_price_list_sfdc_staging%ROWTYPE;

      pl_details_data   c_details;

  	  x_record_limit 	NUMBER := 500;

   BEGIN
      x_return_status := 'S';
      G_stage := 'GPL-1';

	 -- Updating the FMW Instance to control table
	  update_instance (
				        p_instance_id      => p_instance_id  ,
					    p_out_batch_id     => p_batch_id     ,
				        x_update_status    => x_return_status,
				        x_update_message   => x_return_message
					   );

	    IF  x_return_status != 'S' THEN
		     Return;  -- Instance Update Failed Returning
		END IF;


     BEGIN

         OPEN pl_details_c ;
         G_stage := 'GPL-2';

		 -- Read the details data from view and load in staging TABLE
         LOOP
            FETCH pl_details_c
            BULK COLLECT INTO pl_details_data LIMIT x_record_limit;

			G_stage := 'GPL-2.1';

            FORALL i IN 1 .. pl_details_data.COUNT
               INSERT INTO xx_price_list_sfdc_staging
                    VALUES pl_details_data (i);

            EXIT WHEN pl_details_c%NOTFOUND;
         END LOOP;

		 G_stage := 'GPL-3';

         CLOSE pl_details_c;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status := 'E';
            x_return_message :=
                               'Insert Failed : at '||G_stage||' Error : ' || SUBSTR (SQLERRM, 1, 200);
      END;

      ---- Select the Data from Populated TABLE
      SELECT CAST
                (MULTISET (SELECT *
                             FROM xx_price_list_sfdc_publish_v
                            WHERE publish_batch_id = TO_NUMBER (p_batch_id)) AS xx_pl_sfdc_outbound_tab_typ
                )
        INTO x_pl_output
        FROM DUAL;
		G_stage := 'GPL-4';
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_message := 'Error at : '||G_stage ||' Error : '||SUBSTR (SQLERRM, 1, 200);
   END get_price_list;


----------------------------------------------------
--- Procedure to update the FMW Instance
----------------------------------------------------
   PROCEDURE update_instance (
							   p_instance_id      IN       NUMBER,
							   p_out_batch_id     IN       NUMBER,
							   x_update_status    OUT      VARCHAR2,
							   x_update_message   OUT      VARCHAR2
   )
   IS
   BEGIN

       G_stage         := 'UI-1';
       x_update_status := 'S';

      UPDATE xx_price_list_sfdc_control
         SET proc_inst_id      = p_instance_id,
             last_update_date  = SYSDATE,
             last_update_login = x_login_id,
             last_updated_by   = x_user_id,
             publish_time      = sysdate,
             status            = 'INPROGRESS'
       WHERE publish_batch_id = p_out_batch_id;

   --IF SQL%COUNT = 0 THEN
    --   x_update_Message := ' Nothing to Update for : '||p_out_batch_id;
     --  x_update_status  := 'W';
   --END IF;

  G_stage := 'UI-2';

  EXCEPTION
      WHEN OTHERS
      THEN
         x_update_status := 'E';
         x_update_message := 'Error at '||G_stage||' Error : '||SUBSTR (SQLERRM, 1, 200);
   END update_instance;

---------------------------------------------------------
--- Procedure to update the response from SFDC Gateway
----------------------------------------------------------

   PROCEDURE update_response (p_error_tab        IN  xx_pl_sfdc_err_mess_tab_typ,
                              x_response_status  OUT VARCHAR2,
                              x_response_message OUT VARCHAR2
							  )
   IS

   BEGIN
      G_stage := 'UR-1';
	  x_response_status  := 'S';

      FOR rec IN p_error_tab.FIRST .. p_error_tab.LAST
      LOOP
         UPDATE xx_price_list_sfdc_control
            SET status            = p_error_tab (rec).status,
                response_message  = response_message ||  '-' || p_error_tab (rec).error_message,
                sfdc_id           = sfdc_id || '-' || p_error_tab (rec).sfdc_id,
                ack_time          = SYSDATE,
                last_update_date  = SYSDATE,
                last_update_login = x_login_id,                          --x_login_id,
                last_updated_by   = x_login_id                           --x_user_id
          WHERE
		       record_id = p_error_tab (rec).record_id;

		G_stage := 'UR-2 Rec#'||p_error_tab (rec).record_id;

	  END LOOP;
	  G_stage := 'UR-3';
EXCEPTION
      WHEN OTHERS
      THEN
         x_response_status := 'E';
         x_response_message := 'Error at '||G_stage||' Error : '||SUBSTR (SQLERRM, 1, 200);

   END update_response;

  /* */

   PROCEDURE xx_republish_price_list
  (
    p_errbuf OUT nocopy  VARCHAR2,
    p_retcode OUT nocopy VARCHAR2,
    p_type             IN VARCHAR2,
    p_hidden1          IN VARCHAR2,
    p_pl_item_from     IN mtl_system_items_b.segment1%TYPE DEFAULT NULL,
    p_pl_item_to       IN mtl_system_items_b.segment1%TYPE DEFAULT NULL,
	p_hidden2          IN              VARCHAR2,
    p_date_from        IN VARCHAR2 DEFAULT NULL,
    p_date_to          IN VARCHAR2 DEFAULT NULL
  )
IS
-- cursor ro fetch distinct PL along with inactive PL
  CURSOR c_distinct_PL
  IS
  select distinct
       nvl(xpsdv.PL_SEC_NAME, xpsdv.PL_PRIMARY) pl_name
     , xpsdv.PL_SEC_ID PL_sec_id
     , xpsdv.pl_header_id PL_id
     , xpsdv.CURRENCY_CODE pl_currency
     , flv.meaning lookup_meaning
     , flv.lookup_code lookup_code
     , flv.description current_pl
     , to_number(flv.attribute14) old_PL_id --  to store old PL id
  from XX_PRICE_LIST_SFDC_TEMP xpsdv
     , fnd_lookup_values flv
 where flv.lookup_type = 'XX_PL_TO_SFDC_INTEGRATION' -- Added for wave2
 AND upper(xpsdv.PL_PRIMARY) = flv.description --'ILS LIST PRICE'
 AND flv.language = userenv('LANG')
 AND flv.enabled_flag = 'Y'
 and SYSDATE between flv.start_date_active and nvl(flv.end_date_active,sysdate+1)
 ;
-- Cursor to fetch PL data
  CURSOR c_new_pl ( cp_type VARCHAR2,
                    cp_date_from DATE,
                    cp_date_to DATE,
                    cp_pl_item_from mtl_system_items_b.segment1%TYPE,
                    cp_pl_item_to   mtl_system_items_b.segment1%TYPE,
					          cp_sec_inactive_pl_id NUMBER,
                    cp_sec_curr_pl_id NUMBER,
                    cp_currency VARCHAR2,
                    cp_pl_header_id NUMBER,
                    cp_inactive_pl_id NUMBER)
  IS
  SELECT
   pl_header_id AS pl_header_id
  ,LINE_ID    AS line_id
FROM XX_PRICE_LIST_SFDC_TEMP tmp
WHERE 1 = 1
  AND tmp.pl_header_id = cp_pl_header_id -- run for one PL at a time -- added for wave2
  AND tmp.start_date = (select max(stg.start_date) -- added conditiion for case# 9410
         from apps.XX_PRICE_LIST_SFDC_TEMP stg
        where tmp. item_id = stg.item_id
        AND stg.start_date <= sysdate)
  AND (((trunc(tmp.qpl_last_update_date) BETWEEN trunc(NVL(cp_date_from,tmp.qpl_last_update_date)) AND trunc(NVL(cp_date_to,tmp.qpl_last_update_date))
      OR
	  trunc(tmp.qphp_last_update_date) BETWEEN trunc(NVL(cp_date_from,tmp.qphp_last_update_date)) AND trunc(NVL(cp_date_to,tmp.qphp_last_update_date))
	  OR
	  trunc(NVL(tmp.qps_last_update_date,SYSDATE)) BETWEEN trunc(NVL(cp_date_from,NVL(tmp.qps_last_update_date,SYSDATE))) AND trunc(NVL(cp_date_to,NVL(tmp.qps_last_update_date,SYSDATE))) -- added nvl to qps date for wave2
	  OR
	  TRUNC(tmp.START_DATE) = TRUNC(SYSDATE) -- Send records starting today irrespective of last update date
      OR
      TRUNC(tmp.END_DATE) = TRUNC(SYSDATE) -- Send records ending today irrespective of last update date
	  )
	  AND cp_type IN ('NEW') -- New can be send only for a given date
	  AND TRUNC(tmp.START_DATE) <= TRUNC(SYSDATE) -- Send only active records - no future dated records
	)
    OR (tmp.item BETWEEN NVL(cp_pl_item_from,tmp.item) AND NVL(cp_pl_item_to,tmp.item)
        AND cp_type IN ('RESEND')
	    )
    ) -- Re-Sent is only for given items
	UNION -- select inactivated item from last price list for US
	SELECT qphp.list_header_id AS pl_header_id
          ,qpl.list_line_id  AS INACTIVE_LINE_ID
	FROM  QP_list_headers qphp ,
		  qp_secondary_price_lists_v qps ,
		  apps.qp_list_lines qpl ,
		  apps.qp_pricing_attributes qpp ,
		  apps.mtl_system_items_b mtl
	WHERE qphp.list_header_id = cp_pl_header_id -- for US only secondary PL changes Primary stays same
	AND qphp.currency_code = cp_currency
	AND qps.parent_price_list_id = TO_CHAR(qphp.list_header_id)
	--AND qps.name = 'ILS LIST PRICE JAN 2014' -- Inactive PL Name
	AND qps.list_header_id  = cp_sec_inactive_pl_id -- Inactive Sec PL ID
	AND qps.list_header_id    = qpl.list_header_id
	AND qps.list_header_id    = qpp.list_header_id
	AND qpl.list_line_id      = qpp.list_line_id
	AND mtl.inventory_item_id = decode (length(trim(translate(qpp.product_attr_value,'0123456789',' '))),null,qpp.product_attr_value,NULL)
	AND mtl.organization_id   =
	  (SELECT UNIQUE master_organization_id FROM mtl_parameters
	  )
	AND mtl.item_type IN ('FG','RPR','TLIN') -- only finished Goods, Repair Items and tools instruments are sent by Item master interface
	AND qpp.product_attribute_context = 'ITEM'
	AND NOT EXISTS
	(select 1 from qp_pricing_attributes qpa
	where qpa.list_header_id = cp_sec_curr_pl_id -- Current Sec PL ID
	 AND decode (length(trim(translate(qpa.product_attr_value,'0123456789',' '))),null,qpa.product_attr_value,NULL) = mtl.inventory_item_id
	 AND qpa.product_attribute_context = 'ITEM')
   UNION -- select inactivated item from last price list for Non US
	SELECT qphp.list_header_id AS pl_header_id
          ,qpl.list_line_id  AS INACTIVE_LINE_ID
	FROM  QP_list_headers qphp ,
		  apps.qp_list_lines qpl ,
		  apps.qp_pricing_attributes qpp ,
		  apps.mtl_system_items_b mtl
	WHERE 1 = 1
	AND qphp.currency_code = cp_currency
  AND qphp.list_header_id = cp_inactive_pl_id
	--AND qphp.name = 'ILS AUSTRALIA LIST PRICE' -- Inactive PL Name
	AND qphp.list_header_id    = qpl.list_header_id
	AND qphp.list_header_id    = qpp.list_header_id
	AND qpl.list_line_id      = qpp.list_line_id
	AND mtl.inventory_item_id = decode (length(trim(translate(qpp.product_attr_value,'0123456789',' '))),null,qpp.product_attr_value,NULL)
	AND mtl.organization_id   =
	  (SELECT UNIQUE master_organization_id FROM mtl_parameters
	  )
	AND mtl.item_type IN ('FG','RPR','TLIN') -- only finished Goods, Repair Items and tools instruments are sent by Item master interface
	AND qpp.product_attribute_context = 'ITEM'
	AND NOT EXISTS
	(select 1 from qp_pricing_attributes qpa
	where qpa.list_header_id = cp_pl_header_id -- Current PL ID
	 AND decode (length(trim(translate(qpa.product_attr_value,'0123456789',' '))),null,qpa.product_attr_value,NULL) = mtl.inventory_item_id
	 AND qpa.product_attribute_context = 'ITEM')
   ;

 CURSOR c_republish_pl ( cp_type VARCHAR2, cp_date_from DATE, cp_date_to DATE )
  IS
    SELECT DISTINCT publish_batch_id
    FROM XX_PRICE_LIST_SFDC_CONTROL plc
    WHERE TRUNC(plc.last_update_date) BETWEEN TRUNC(nvl(cp_date_from,plc.last_update_date)) AND TRUNC(nvl(cp_date_to,plc.last_update_date))
    AND cp_type IN ('Reprocess')  -- Re process all non success records
    AND nvl(status,'NEW')   != 'SUCCESS';

  x_type     			VARCHAR2 (20);
  x_new_type 			VARCHAR2 (10);

  x_pl_item_from      mtl_system_items_b.segment1%TYPE;
  x_pl_item_to        mtl_system_items_b.segment1%TYPE;

  x_date_from 			DATE;
  x_date_to 			DATE;
  x_publish_batch_id 	NUMBER;
  x_record_id        	NUMBER;
  x_date 				VARCHAR2(50);
  l_parameter_list 		wf_parameter_list_t;

  l_batch 		  NUMBER;
  l_count         NUMBER :=0;
  l_batch_size    NUMBER :=0;
  l_in_loop       VARCHAR2(1) :='N';

  x_sec_inactive_pl_id    NUMBER := NULL;
  x_curr_pl_name      VARCHAR2(250) := NULL;
  x_sec_curr_pl_id        NUMBER := NULL;
  x_currency VARCHAR2(10) := NULL;
  x_pl_header_id NUMBER := NULL;
  x_inactive_pl_id NUMBER := NULL;

  BEGIN

     x_date             := fnd_date.date_to_canonical (sysdate);
     x_type             := p_type;
     x_pl_item_from     := p_pl_item_from;
     x_pl_item_to       := p_pl_item_to;
     l_batch_size := NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'BATCH_SIZE'), 150);

     logme( '---------------- Parameters --------------------');
     logme( '================================================ ');

     logme ('                      Type : ' || p_type);
     logme ('      Price List Item From : ' || p_pl_item_from);
     logme ('      Price List Item To   : ' || p_pl_item_from);
     logme ('Price List Change Date From: ' || p_date_from);
     logme ('Price List Change Date To  : ' || p_date_to);
     logme ('================================================ ' );

     logme ('                Batch Size : ' ||l_batch_size);

    -- Change for case# 9410
    -- use temporary table for the view data to filter duplicate records
    -- this method is faster compared to modification of the view query
    BEGIN
      insert into XX_PRICE_LIST_SFDC_TEMP
      SELECT * from XX_PL_SFDC_DETAIL_V;
    EXCEPTION
      WHEN OTHERS THEN
       logme ('Error while inserting into Temp table. Error: ' ||sqlerrm);
    END;


    IF p_type                = 'New' THEN
          IF x_pl_item_from IS NOT NULL OR x_pl_item_to IS NOT NULL THEN

	            x_new_type          := 'RESEND'; -- Resend only takes Item number to and from

          ELSE -- New only takes null date or input parameter date
		   logme('Considering date Entries from parameter');
		   x_new_type           := 'NEW';
		   x_date_to := to_date(p_date_to,'DD-MON-RR');
           logme('To date : '|| x_date_to);
		   IF p_date_from IS NOT NULL THEN
		     logme('From date is not null');
		     x_date_from := to_date(p_date_from,'DD-MON-RR');
			 logme('From date: '||x_date_from);
		   ELSE
		     logme('From date before call: '||x_date_from);
             x_date_from := TO_DATE(xx_emf_pkg.get_paramater_value (g_object_name, 'LAST_RUN_DATE'),'DD-MON-RRRR HH24:MI:SS');
			 logme('From date: '||x_date_from);
              IF x_date_from IS NULL THEN
				logme('Missing PSF Entry of XXSFDCPRLIST and or LAST_RUN_DATE');
	            logme('Fix the Entry in Process Setupform...Program Existing...');
	            p_retcode := 2;
	            RETURN;
	            END IF;
		   END IF;
             logme ('Picking Up new/modified After : ' ||to_CHAR(x_date_from,'DD-MON-RRRR HH24:MI:SS'));
         END IF;
         logme('after date pickup ');
 -- Inactive and Active unique PL
  FOR unique_pl_rec IN c_distinct_PL
  LOOP
     -- for US if current secondary PL id doesn't match with previous secondary PL id
     logme('Comparing Current Secondary PL : '||unique_pl_rec.PL_sec_id||' and old PL Id : '||unique_pl_rec.old_PL_id );
       x_sec_curr_pl_id := NULL;
       x_sec_inactive_pl_id := NULL;
       x_currency := NULL;
       x_pl_header_id := NULL;
       x_inactive_pl_id := NULL;
     IF unique_pl_rec.pl_currency = 'USD' AND unique_pl_rec.old_PL_id <> unique_pl_rec.PL_sec_id AND unique_pl_rec.old_PL_id IS NOT NULL
     THEN
       x_sec_curr_pl_id := unique_pl_rec.PL_sec_id;
       x_sec_inactive_pl_id := unique_pl_rec.old_PL_id;
       x_currency := unique_pl_rec.pl_currency;
       x_pl_header_id := unique_pl_rec.PL_id;
       x_inactive_pl_id := NULL;
     -- for Non US if current PL id doesn't match with previous PL id
     logme('Comparing Current PL for  US : '||unique_pl_rec.PL_id||' and old PL Id : '||unique_pl_rec.old_PL_id );
     --ELSIF unique_pl_rec.pl_currency <> 'USD' AND unique_pl_rec.PL_id <> unique_pl_rec.old_PL_id  AND unique_pl_rec.old_PL_id IS NOT NULL --Commented by Vishal
     ELSIF unique_pl_rec.pl_currency <> 'USD' AND unique_pl_rec.old_PL_id IS NOT NULL --Commented by Vishal
     THEN
       x_sec_curr_pl_id := NULL;
       x_sec_inactive_pl_id := NULL;
       x_currency := unique_pl_rec.pl_currency;
       x_pl_header_id := unique_pl_rec.PL_id;
       x_inactive_pl_id := unique_pl_rec.old_PL_id;
       logme('Comparing Current PL for non US : '||unique_pl_rec.PL_id||' and old PL Id : '||unique_pl_rec.old_PL_id );
     END IF;
    logme('End of Inactive PL logic');
    --
    logme(' x_new_type : ' ||  x_new_type);
    logme(' x_date_from : ' ||   x_date_from);
    logme(' x_date_to : ' ||   x_date_to);
    logme(' x_sec_inactive_pl_id : ' ||   x_sec_inactive_pl_id);
    logme(' x_sec_curr_pl_id : ' ||   x_sec_curr_pl_id);
    logme(' x_currency : ' ||   x_currency);
    logme(' x_pl_header_id : ' ||  x_pl_header_id);
    logme(' x_inactive_pl_id : ' ||   x_inactive_pl_id);
    begin
    select count(1) into x_sec_inactive_pl_id
    from XX_PRICE_LIST_SFDC_TEMP
    where pl_header_id = x_pl_header_id;
    logme(' count : ' ||   x_sec_inactive_pl_id);
    exception
    when others then
    null;
    end;
    logme(' Total Count : ' ||   x_sec_inactive_pl_id);
    FOR new_pl_rec IN c_new_pl (x_new_type, x_date_from, x_date_to,x_pl_item_from,x_pl_item_to, x_sec_inactive_pl_id, x_sec_curr_pl_id,x_currency,x_pl_header_id, x_inactive_pl_id )
    LOOP
	  IF l_in_loop = 'N' -- Logic to generate new batch only if there is data to interface
	  THEN
		--- Getting new batch Id;
		x_publish_batch_id := NEXT_BATCH;
		logme('New Batch is '||x_publish_batch_id);
	  END IF;
	  --
    logme('x_publish_batch_id '|| x_publish_batch_id);
      l_count := l_count + 1;
	  l_in_loop := 'Y';
      BEGIN
        INSERT
        INTO XX_PRICE_LIST_SFDC_CONTROL
          (
           RECORD_ID         ,
		   PUBLISH_BATCH_ID  ,
           PL_HEADER_ID      ,
           PL_LINE_ID        ,
		   PUBLISH_TIME      ,
		   SOURCE_SYSTEM     ,
		   TARGET_SYSTEM     ,
		   STATUS            ,
           REQUEST_ID        ,
		   CREATION_DATE     ,
           CREATED_BY        ,
           LAST_UPDATE_DATE  ,
           LAST_UPDATED_BY   ,
           LAST_UPDATE_LOGIN
          )
          VALUES
          (
		    xx_pl_sfdc_control_recid_s.NEXTVAL,
            x_publish_batch_id,
            new_pl_rec.pl_header_id,
			new_pl_rec.line_id,
			SYSDATE,
            NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'SOURCE_SYSTEM'), 'EBIZ'),
            NVL(xx_emf_pkg.get_paramater_value (g_object_name, 'TARGET_SYSTEM'),'SFDC'),
           'NEW',
		    x_request_id,
  		    SYSDATE,
            x_user_id,
            SYSDATE,
            x_user_id,
            x_login_id
          );
      EXCEPTION
         WHEN OTHERS THEN
            logme( 'Exception occurred while inserting data...' );
            logme( SQLCODE || '-' || sqlerrm);
      END;

	  IF l_count >= nvl(l_batch_size,150) THEN -- SFDC Max Batch can not be greater than 200

	      logme( 'Raising business event xxintg.oracle.apps.pl.sfdc for batch ID '||to_char(x_publish_batch_id));

          l_parameter_list := wf_parameter_list_t ( wf_parameter_t ('SEND_DATE', x_date), wf_parameter_t ('PUBLISH_BATCH_ID', x_publish_batch_id) );

          wf_event.raise ( p_event_name => 'xxintg.oracle.apps.pl.sfdc', p_event_key => sys_guid (), p_parameters => l_parameter_list );

	      logme( 'After business event .xxintg.oracle.apps.pl.sfdc ');

          COMMIT;
          DBMS_LOCK.SLEEP(20);

 	      l_count := 0;
		  x_publish_batch_id := NEXT_BATCH;

	  END IF;
    END LOOP;

   	-- Processing the leftover records in control table

	 IF ((l_count > 0) AND l_count < nvl(l_batch_size,150)) THEN -- SFDC Max Batch can not be greater than 200

	      logme( 'Raising business event xxintg.oracle.apps.pl.sfdc for batch ID '||to_char(x_publish_batch_id));

          l_parameter_list := wf_parameter_list_t ( wf_parameter_t ('SEND_DATE', x_date), wf_parameter_t ('PUBLISH_BATCH_ID', x_publish_batch_id) );

          wf_event.raise ( p_event_name => 'xxintg.oracle.apps.pl.sfdc', p_event_key => sys_guid (), p_parameters => l_parameter_list );

	      logme( 'After Last business event .xxintg.oracle.apps.pl.sfdc ');

        COMMIT;
		 l_in_loop := 'N';
	  END IF;  -- End if for last batch logic


	IF x_new_type = 'NEW' THEN
  -- updating the current Price List name to process Setup Form
  update_lookup (unique_pl_rec.pl_name, nvl(unique_pl_rec.PL_sec_id, unique_pl_rec.PL_id) , unique_pl_rec.old_PL_id);
  -- attribute14 will hold pl id and next run it will be passed on to attribute15 so that query service can link old to new
  --
	END IF;

  END LOOP; -- loop for unique PL

    -- Updating the PS form only in case new
	  UPDATE xx_emf_process_parameters
      SET parameter_value  = TO_CHAR (NVL(x_date_to,SYSDATE),'DD-MON-YYYY HH24:MI:SS')
      WHERE parameter_name = 'LAST_RUN_DATE'
      AND process_id       =
        (SELECT xeps.process_id
        FROM xx_emf_process_setup xeps
        WHERE xeps.process_name = 'XXSFDCPRLIST'
        );
  ELSE

    x_date_from          := to_date(p_date_from,'DD-MON-RR');
    x_date_to            := to_date(p_date_to,'DD-MON-RR');

	 logme(' Republish Date From ' || x_date_from );
     logme(' Republish Date To ' || x_date_to );
     logme(' Republish Type ' || x_type);
    FOR republish_pl_rec IN c_republish_pl (x_type, x_date_from, x_date_to )
  	LOOP

     	logme(' Republish Batch ID ...' || republish_pl_rec.publish_batch_id );
        --- Getting new batch Id;
        x_publish_batch_id := NEXT_BATCH;

        UPDATE XX_PRICE_LIST_SFDC_CONTROL   -- Setting all the records to New for reprocessing
        SET
	      status             = 'NEW',
          last_update_date    = SYSDATE,
          last_update_login   = x_login_id,
          last_updated_by     = x_user_id,
		  response_message    = null,
		  proc_inst_id        = null,
		  publish_batch_id    = x_publish_batch_id
      WHERE
	      publish_batch_id = republish_pl_rec.publish_batch_id
      AND nvl(status,'NEW') !='SUCCESS';
        logme( 'Raising business event xxintg.oracle.apps.pl.sfdc for New Batch ID '||to_char(x_publish_batch_id));
  	    l_parameter_list  := wf_parameter_list_t ( wf_parameter_t ('SEND_DATE', x_date), wf_parameter_t ('PUBLISH_BATCH_ID', x_publish_batch_id) );
        wf_event.raise ( p_event_name => 'xxintg.oracle.apps.pl.sfdc', p_event_key => sys_guid (), p_parameters => l_parameter_list );
        COMMIT;
	END LOOP;

  END IF;  --- End if for x_new_type
EXCEPTION
WHEN OTHERS THEN
  logme('Exception occurred while Submitting...' );
  logme( SQLCODE || '-' || sqlerrm);
  p_retcode := 2;
END xx_republish_price_list;
---------------------------------------------------
-- Procedure to log the messages
---------------------------------------------------
PROCEDURE LOGME(p_text IN varchar2)

IS
BEGIN
	IF G_MODE = 'LOG' THEN
			fnd_file.put_line (fnd_file.log, p_text);

	ELSIF G_MODE = 'OUTPUT' THEN
			fnd_file.put_line (fnd_file.output, p_text);

	ELSE
			fnd_file.put_line (fnd_file.log, p_text);
			fnd_file.put_line (fnd_file.output, p_text);
END IF;

 END LOGME;
 ------

FUNCTION NEXT_BATCH RETURN NUMBER IS

l_new_batch number;

 BEGIN
             SELECT xx_pl_sfdc_control_batid_s.NEXTVAL INTO l_new_batch FROM DUAL;
             Return l_new_batch;
        EXCEPTION
            When Others then
           --  RETCODE := 2;

             logme('Error while getting next Batch ID...');
             logme('Check Sequence xx_pl_sfdc_control_batid_s for corruption..');
             logme('Program quiting....');
             RETURN 9999999;

 END NEXT_BATCH;

---
END xx_pl_sfdc_outbound_ws_pkg;
/
