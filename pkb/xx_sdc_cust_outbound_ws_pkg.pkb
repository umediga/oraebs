DROP PACKAGE BODY APPS.XX_SDC_CUST_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_CUST_OUTBOUND_WS_PKG" 
AS
/* $Header: XXSDCCUSTOUTWS.pks 1.0.0 2014/02/12 00:00:00  noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Yogesh
 Creation Date  : 12-FEB-2014
 Filename       : XXSDCCUSTOUTWS.pks
 Description    : Customer Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 12-Feb-2014   1.0       Yogesh              Initial development.

 */
--------------------------------------------------------------------------------
   PROCEDURE xx_get_customer (
         p_mode                 IN              VARCHAR2,
         p_publish_batch_id     IN              NUMBER,
         p_cust_accont_id_ls    IN              xx_sdc_in_cust_ws_ot_tabtyp,
         x_output_Customer      OUT NOCOPY      xx_sdc_cust_otbound_ws_tabtyp,
         x_return_status        OUT NOCOPY      VARCHAR2,
         x_return_message       OUT NOCOPY      VARCHAR2
   )
   IS
     CURSOR c_cust_account_batch_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xscps.publish_batch_id,0 record_id,xsca.*
           FROM xx_sdc_cust_account_ws_v xsca,
                (SELECT DISTINCT cust_account_id,publish_batch_id,0 record_id
                            FROM xx_sdc_customer_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id
						     AND nvl(status, 'NEW') <> 'SUCCESS') xscps
          WHERE xsca.customer_account_id = xscps.cust_account_id;

      CURSOR c_cust_sites_batch_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xscps.publish_batch_id,xscps.record_id,xscas.*
           FROM xx_sdc_cust_acc_sites_ws_v xscas,
                (SELECT DISTINCT cust_account_id,cust_acc_site_id,publish_batch_id,record_id
                            FROM xx_sdc_customer_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id
						     AND nvl(status, 'NEW') <> 'SUCCESS') xscps
          WHERE xscas.customer_account_id = xscps.cust_account_id
            AND xscas.customer_account_site_id=xscps.cust_acc_site_id;

     CURSOR c_cust_account_list_info (cp_cust_account_id NUMBER,
                                      cp_record_Id       NUMBER)
      IS
         SELECT xscps.publish_batch_id,xscps.record_id,xsca.*
           FROM xx_sdc_cust_account_ws_v xsca,
                (SELECT DISTINCT cust_account_id,publish_batch_id,record_id
                            FROM xx_sdc_customer_publish_stg
                           WHERE cust_account_id = cp_cust_account_id
                             AND record_id  = cp_record_Id) xscps
          WHERE xsca.customer_account_id = xscps.cust_account_id;

      CURSOR c_cust_sites_list_info (cp_cust_account_id NUMBER,
                                     cp_record_Id       NUMBER)
      IS
         SELECT xscps.publish_batch_id,xscps.record_id,xscas.*
           FROM xx_sdc_cust_acc_sites_ws_v xscas,
                (SELECT DISTINCT cust_account_id,publish_batch_id,record_id
                            FROM xx_sdc_customer_publish_stg
                           WHERE cust_account_id = cp_cust_account_id
                             AND record_id  = cp_record_Id) xscps
          WHERE xscas.customer_account_id = xscps.cust_account_id;

      x_publish_batch_id       NUMBER               := NULL;
      e_incorrect_mode         EXCEPTION;

      TYPE sdc_customer_publish_tbl IS TABLE OF xx_sdc_customer_publish_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_sdc_customer_publish_tbl   sdc_customer_publish_tbl;

      TYPE sdc_cust_account_tbl IS TABLE OF xx_sdc_cust_account_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_sdc_cust_account_tbl       sdc_cust_account_tbl;

      TYPE sdc_cust_acc_sites_stg_tbl IS TABLE OF xx_sdc_cust_acc_sites_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_sdc_cust_acc_sites_stg_tbl  sdc_cust_acc_sites_stg_tbl;

   BEGIN
         mo_global.set_policy_context('S',82);
         x_publish_batch_id := p_publish_batch_id;

         IF p_mode IS NULL OR p_mode NOT IN ('BATCH', 'LIST')
         THEN
            RAISE e_incorrect_mode;
         END IF;

         IF p_mode = 'BATCH'
         THEN
            OPEN c_cust_account_batch_info (x_publish_batch_id);
            FETCH c_cust_account_batch_info
            BULK COLLECT INTO x_sdc_cust_account_tbl;

            CLOSE c_cust_account_batch_info;

            IF x_sdc_cust_account_tbl.COUNT > 0
            THEN
               FORALL i_rec IN 1 .. x_sdc_cust_account_tbl.COUNT
                  INSERT INTO xx_sdc_cust_account_stg
                       VALUES x_sdc_cust_account_tbl (i_rec);
            END IF;

            OPEN c_cust_sites_batch_info (x_publish_batch_id);
            FETCH c_cust_sites_batch_info
            BULK COLLECT INTO x_sdc_cust_acc_sites_stg_tbl;
            CLOSE c_cust_sites_batch_info;

            IF x_sdc_cust_acc_sites_stg_tbl.COUNT > 0
            THEN
               FORALL i_rec IN 1 .. x_sdc_cust_acc_sites_stg_tbl.COUNT
                  INSERT INTO xx_sdc_cust_acc_sites_stg
                       VALUES x_sdc_cust_acc_sites_stg_tbl (i_rec);
            END IF;


            SELECT CAST
                      (MULTISET (SELECT *
                                   FROM xx_sdc_customer_ws_v
                                  WHERE publish_batch_id = x_publish_batch_id) AS xx_sdc_cust_otbound_ws_tabtyp
                      )
              INTO x_output_Customer
              FROM DUAL;

            x_return_status := 'S';
            x_return_message := NULL;
         END IF;

         IF p_mode = 'LIST'
         THEN
            FOR i IN 1 .. p_cust_accont_id_ls.COUNT
            LOOP
                OPEN c_cust_account_list_info (p_cust_accont_id_ls(i).record_id,p_cust_accont_id_ls(i).cust_account_id );
                FETCH c_cust_account_list_info
                BULK COLLECT INTO x_sdc_cust_account_tbl;

                CLOSE c_cust_account_list_info;

                IF x_sdc_cust_account_tbl.COUNT > 0
                THEN
                   FORALL i_rec IN 1 .. x_sdc_cust_account_tbl.COUNT
                      INSERT INTO xx_sdc_cust_account_stg
                           VALUES x_sdc_cust_account_tbl (i_rec);
                END IF;

                OPEN c_cust_sites_list_info (p_cust_accont_id_ls(i).record_id,p_cust_accont_id_ls(i).cust_account_id );
                FETCH c_cust_sites_list_info
                BULK COLLECT INTO x_sdc_cust_acc_sites_stg_tbl;

                CLOSE c_cust_sites_list_info;

                IF x_sdc_cust_acc_sites_stg_tbl.COUNT > 0
                THEN
                   FORALL i_rec IN 1 .. x_sdc_cust_acc_sites_stg_tbl.COUNT
                      INSERT INTO xx_sdc_cust_acc_sites_stg
                           VALUES x_sdc_cust_acc_sites_stg_tbl (i_rec);
                END IF;

                SELECT DISTINCT PUBLISH_BATCH_ID
		  INTO x_publish_batch_id
		  FROM xx_sdc_customer_publish_stg
                 WHERE record_id = p_cust_accont_id_ls(i).record_id;
            END LOOP;

            SELECT CAST
                      (MULTISET (SELECT *
                                   FROM xx_sdc_customer_ws_v
                                  WHERE publish_batch_id = x_publish_batch_id) AS xx_sdc_cust_otbound_ws_tabtyp
                      )
              INTO x_output_Customer
              FROM DUAL;

            x_return_status := 'S';
            x_return_message := NULL;

         END IF;
      EXCEPTION
         WHEN e_incorrect_mode
         THEN
            x_return_status := 'E';
            x_return_message := 'Mode is mandatory and can be BATCH or LIST';
         WHEN OTHERS
         THEN
            x_return_status := 'E';
            x_return_message := SQLERRM;


      END xx_get_customer;
--------------------------------------------------------------------------------

    FUNCTION sdc_publish_customer ( p_subscription_guid   IN              RAW,
                                    p_event               IN OUT NOCOPY   wf_event_t
                                  )
    RETURN VARCHAR2
    IS
       x_xml_event_data            XMLTYPE;
       x_key                       varchar2(20);
       x_record_id                 NUMBER;

           PRAGMA                      AUTONOMOUS_TRANSACTION;
    BEGIN
    x_xml_event_data:=SYS.XMLTYPE.createxml(p_event.geteventdata());
     x_key:=p_event.getvalueforparameter ('event_key');

               SELECT EXTRACTVALUE (x_xml_event_data,'/default/event_key')
                 INTO x_key
            FROM dual;

             SELECT xxintg.xx_sdc_customer_publish_stg_s1.NEXTVAL
               INTO x_record_id
               FROM DUAL;

             INSERT INTO xx_sdc_customer_publish_stg ( publish_batch_id,
             					       record_id,
             					       cust_account_id,
             					       publish_time,
                 				       publish_system,
             					       status,
             					       ack_time,
             					       aia_proc_inst_id,
             					       creation_date,
             					       created_by,
             					       last_update_date,
             					       last_updated_by,
             					       last_update_login)
             values( NULL,
                     x_record_id,
                     nvl(to_number(x_key),1),
                     SYSDATE,
                     'EBS',
                     'NEW',
                     NULL,
                     NULL,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id,
                     fnd_global.user_id);
                     Commit;

    --Insert into temp2 values (substr(x_xml_event_data,1,3999));
    --commit;
    RETURN 'SUCCESS';
    END sdc_publish_customer;
    --Function to fetch territories
    FUNCTION get_territories( p_country             VARCHAR2 ,
                                 p_customer_id         NUMBER ,
                                 p_site_number         NUMBER,
                                 p_cust_account        VARCHAR2,
                                 p_county              VARCHAR2,
                                 p_postal_code         VARCHAR2,
                                 p_province            VARCHAR2,
                                 p_state               VARCHAR2,
                                 p_cust_name           VARCHAR2
                               )
    RETURN VARCHAR2
    IS
       CURSOR c_fetch_terr
       IS
       select distinct --terr_id ,
               --rank ,
               name
               --,qualifier_name,
              -- low_value_char
             FROM
               (/*SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
               AND jtqa.qual_usg_id         = jqua.qual_usg_id
               AND jqua.org_id              = jtqa.org_id
               AND jqua.enabled_flag        = 'Y'
               AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
               AND qual_type_usg_id         = -1001
               AND jtqa.terr_id             = jta.terr_id
               AND jsqa.name                = 'Country'
               AND jtva.comparison_operator = '='
               AND jtva.low_value_char      = p_country
               UNION ALL*/
               SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
               AND jtqa.qual_usg_id         = jqua.qual_usg_id
               AND jqua.org_id              = jtqa.org_id
               AND jqua.enabled_flag        = 'Y'
               AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
               AND qual_type_usg_id         = -1001
               AND jtqa.terr_id             = jta.terr_id
               AND jsqa.name                = 'Customer Name'
               AND jtva.comparison_operator = '='
               AND jtva.low_value_char_id   = p_customer_id
               UNION
               SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
               AND jtqa.qual_usg_id         = jqua.qual_usg_id
               AND jqua.org_id              = jtqa.org_id
               AND jqua.enabled_flag        = 'Y'
               AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
               AND qual_type_usg_id         = -1001
               AND jtqa.terr_id             = jta.terr_id
               AND jsqa.name                = 'Site Number'
               AND jtva.comparison_operator = '='
               AND jtva.low_value_char_id   = p_site_number
               UNION
               SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
               AND jtqa.qual_usg_id            = jqua.qual_usg_id
               AND jqua.org_id                 = jtqa.org_id
               AND jqua.enabled_flag           = 'Y'
               AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
               AND qual_type_usg_id            = -1001
               AND jtqa.terr_id                = jta.terr_id
               AND jsqa.name                   = 'Customer Account Number'
               AND ( (jtva.comparison_operator = 'LIKE'
               AND p_cust_account LIKE '%'
                 || jtva.low_value_char
                 || '%')
               OR (jtva.comparison_operator = '='
               AND p_cust_account           = jtva.low_value_char )
               OR (JTVA.COMPARISON_OPERATOR = 'BETWEEN'
               and p_cust_account between jtva.low_value_char and jtva.high_value_char) )
               UNION
               SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
               AND jtqa.qual_usg_id         = jqua.qual_usg_id
               AND jqua.org_id              = jtqa.org_id
               AND jqua.enabled_flag        = 'Y'
               AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
               AND qual_type_usg_id         = -1001
               AND jtqa.terr_id             = jta.terr_id
               AND jsqa.name                = 'County'
               AND jtva.comparison_operator = '='
               AND jtva.low_value_char      = p_county
               UNION
               SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
               AND jtqa.qual_usg_id         = jqua.qual_usg_id
               AND jqua.org_id              = jtqa.org_id
               AND jqua.enabled_flag        = 'Y'
               AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
               AND qual_type_usg_id         = -1001
               AND jtqa.terr_id             = jta.terr_id
               AND jsqa.name                = 'Province'
               AND jtva.comparison_operator = '='
               AND jtva.low_value_char      = p_province
               UNION
               SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id         = jtqa.terr_qual_id
               AND jtqa.qual_usg_id            = jqua.qual_usg_id
               AND jqua.org_id                 = jtqa.org_id
               AND jqua.enabled_flag           = 'Y'
               AND jqua.seeded_qual_id         = jsqa.seeded_qual_id
               AND qual_type_usg_id            = -1001
               AND jtqa.terr_id                = jta.terr_id
               AND jsqa.name                   = 'Postal Code'
               AND ( (jtva.comparison_operator = 'LIKE'
               AND p_postal_code LIKE '%'
                 || jtva.low_value_char
                 || '%')
               OR (jtva.comparison_operator = '='
               AND p_postal_code            = jtva.low_value_char )
               OR (jtva.comparison_operator = 'BETWEEN'
               AND p_postal_code BETWEEN jtva.low_value_char AND jtva.high_value_char) )
               UNION
               SELECT jtqa.terr_id ,
                 rank ,
                 jta.name,
                 jsqa.name qualifier_name,
                 jtva.low_value_char
               FROM jtf_terr_values jtva ,
                 jtf_terr_qual jtqa ,
                 jtf_qual_usgs jqua ,
                 jtf_seeded_qual jsqa ,
                 apps.jtf_terr jta
               WHERE jtva.terr_qual_id      = jtqa.terr_qual_id
               AND jtqa.qual_usg_id         = jqua.qual_usg_id
               AND jqua.org_id              = jtqa.org_id
               AND jqua.enabled_flag        = 'Y'
               AND jqua.seeded_qual_id      = jsqa.seeded_qual_id
               AND qual_type_usg_id         = -1001
               AND jtqa.terr_id             = jta.terr_id
               AND jsqa.name                = 'State'
               AND jtva.comparison_operator = '='
               AND jtva.low_value_char      = p_state
               UNION
               SELECT jtqa.terr_id ,
	              rank ,
	              jta.name,
	              jsqa.name qualifier_name,
	              jtva.low_value_char
	         FROM jtf_terr_values jtva ,
	              jtf_terr_qual jtqa ,
	              jtf_qual_usgs jqua ,
	              jtf_seeded_qual jsqa ,
	              apps.jtf_terr jta
	        WHERE jtva.terr_qual_id = jtqa.terr_qual_id
	          AND jtqa.qual_usg_id    = jqua.qual_usg_id
	          AND jqua.org_id         = jtqa.org_id
	          AND jqua.enabled_flag   = 'Y'
	          AND jqua.seeded_qual_id = jsqa.seeded_qual_id
	          AND qual_type_usg_id    = -1001
	          AND jtqa.terr_id        = jta.terr_id
	          AND jsqa.name           = 'Customer Name Range'
	          -- Condition splited for Ticket  # 2381
	          AND ((jtva.comparison_operator = 'LIKE'
	                 AND p_cust_name LIKE '%'
	                 || jtva.low_value_char
	                 || '%')
	              OR (jtva.comparison_operator = '='
	                 AND p_cust_name    = jtva.low_value_char )
	              OR (jtva.comparison_operator = 'BETWEEN'
	                  AND p_cust_name BETWEEN jtva.low_value_char AND jtva.high_value_char) )
               );
      --ORDER BY rank ;

      x_terr       VARCHAR2(2400);
      x_terr_name  VARCHAR2(2400);
    BEGIN
       x_terr := NULL;
       FOR r_fetch_terr IN c_fetch_terr
       LOOP
          X_TERR_NAME := SUBSTR(R_FETCH_TERR.name,1,INSTR(R_FETCH_TERR.name,' ')-1);
          if SUBSTR(X_TERR_NAME,1,1) = '3' then
          X_TERR_NAME := SUBSTR(x_terr_name,LENGTH(x_terr_name)-4);
          end if;
          IF SUBSTR(x_terr_name,LENGTH(x_terr_name)-2) != '000' THEN
             IF x_terr IS NULL THEN
                x_terr := x_terr||x_terr_name;
             ELSE
                if instr( x_terr,x_terr_name) =0 then
                         x_terr := x_terr||chr(44)||x_terr_name;
                end if;
             END IF;
          END IF;
       END LOOP;

       RETURN x_terr;
    EXCEPTION
    WHEN OTHERS THEN
       RETURN NULL;
    END get_territories;

END xx_sdc_cust_outbound_ws_pkg;
/
