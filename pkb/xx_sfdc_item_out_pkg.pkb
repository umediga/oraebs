DROP PACKAGE BODY APPS.XX_SFDC_ITEM_OUT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SFDC_ITEM_OUT_PKG" AS
/* $Header: XXSFDCITEMOUT.pkb 1.0.0 2014/02/28 00:00:00  noship $ */
--------------------------------------------------------------------------------
 /*
 Created By     : Dipankar Bagchi
 Creation Date  : 28-FEB-2014
 Filename       : XXSFDCITEMOUT.pkb
 Description    : Item Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 28-Feb-2014   1.0       Dipankar Bagchi     Initial development.
 23-May-2014   1.1       Renjith             Added p_instance_id
 */
--------------------------------------------------------------------------------
  PROCEDURE get_item ( p_mode          IN      VARCHAR2
                      ,p_batch_id      IN      NUMBER
                      ,p_instance_id   IN      NUMBER
                      ,p_inv_id_ls     IN      x_sfdc_list_in_tabtyp
                      ,x_out_item      OUT     x_sfdc_item_out_tabtyp
                      ,x_ret_status    OUT     VARCHAR2
                      ,x_ret_msg       OUT     VARCHAR2)
  IS
    CURSOR c_item_batch (cp_batch_id NUMBER)
    IS
    SELECT xsioc.batch_id
          ,xsioc.record_id
          ,xsiov.inventory_item_id
          ,xsiov.item_code
          ,xsiov.long_description
          ,xsiov.description
          ,xsiov.item_status
          ,xsiov.comms_nl_trackable_flag
          ,xsiov.division
          ,xsiov.product_segment
          ,xsiov.brand
          ,xsiov.product_class
          ,xsiov.product_class_desc
          ,xsiov.product_type
          ,xsiov.product_type_desc
          ,xsiov.subdivision
          ,xsiov.product_use
          ,xsiov.product_use_desc
          ,xsiov.product_family
          ,xsiov.product_family_desc
          ,xsiov.inv_product_type
          ,xsiov.inv_product_type_desc
          ,SYSDATE
          ,FND_GLOBAL.USER_ID
          ,SYSDATE
          ,FND_GLOBAL.USER_ID
          ,FND_GLOBAL.USER_ID
          ,xsiov.item_cost
    FROM xx_sfdc_item_out_v xsiov
       ,(SELECT DISTINCT batch_id, record_id, inventory_item_id
          FROM xx_sfdc_item_out_ctl
         WHERE batch_id = cp_batch_id
         --AND status = 'NEW'
        ) xsioc
    WHERE xsiov.inventory_item_id = xsioc.inventory_item_id;

    CURSOR c_item_list (cp_rec_id NUMBER, cp_inv_id NUMBER)
    IS
      SELECT xsioc.batch_id
            ,xsioc.record_id
            ,xsiov.inventory_item_id
            ,xsiov.item_code
            ,xsiov.long_description
            ,xsiov.description
            ,xsiov.item_status
            ,xsiov.comms_nl_trackable_flag
            ,xsiov.division
            ,xsiov.product_segment
            ,xsiov.brand
            ,xsiov.product_class
            ,xsiov.product_class_desc
            ,xsiov.product_type
            ,xsiov.product_type_desc
            ,xsiov.subdivision
            ,xsiov.product_use
            ,xsiov.product_use_desc
            ,xsiov.product_family
            ,xsiov.product_family_desc
            ,xsiov.inv_product_type
            ,xsiov.inv_product_type_desc
            ,SYSDATE
            ,FND_GLOBAL.USER_ID
            ,SYSDATE
            ,FND_GLOBAL.USER_ID
            ,FND_GLOBAL.USER_ID
             ,xsiov.item_cost
       FROM xx_sfdc_item_out_v xsiov
          ,(SELECT DISTINCT batch_id, record_id, inventory_item_id
              FROM xx_sfdc_item_out_ctl
      WHERE record_id = cp_rec_id
        AND inventory_item_id = cp_inv_id) xsioc
      WHERE xsiov.inventory_item_id = xsioc.inventory_item_id;

    TYPE sfdc_item_tbl IS TABLE OF XX_SFDC_ITEM_OUT_STG%ROWTYPE
    INDEX BY BINARY_INTEGER;

    x_sfdc_item_tbl       sfdc_item_tbl;
    e_incorrect_mode      EXCEPTION;

  BEGIN
    IF p_mode IS NULL OR p_mode NOT IN ('BATCH', 'LIST') THEN
      RAISE e_incorrect_mode;
    END IF;

    IF p_mode = 'BATCH' THEN
       OPEN c_item_batch (p_batch_id);
       FETCH c_item_batch
       BULK COLLECT INTO x_sfdc_item_tbl;
       CLOSE c_item_batch;

      IF x_sfdc_item_tbl.COUNT >0 THEN
         FORALL i IN 1..x_sfdc_item_tbl.COUNT
             INSERT INTO xx_sfdc_item_out_stg
             VALUES x_sfdc_item_tbl (i);
      END IF;

      UPDATE  xx_sfdc_item_out_ctl
         SET  instance_id = p_instance_id
       WHERE  batch_id = p_batch_id;

      SELECT CAST (MULTISET (SELECT batch_id
                               ,record_id
                               ,inventory_item_id
                               ,item_code
                               ,long_description
                               ,description
                               ,item_status
                               ,comms_nl_trackable_flag
                               ,division
                               ,product_segment
                               ,brand
                               ,product_class
                               ,product_class_desc
                               ,product_type
                               ,product_type_desc
                               ,subdivision
                               ,product_use
                               ,product_use_desc
                               ,product_family
                               ,product_family_desc
                               ,inv_product_type
                               ,inv_product_type_desc
                               ,item_cost
                        FROM xx_sfdc_item_out_stg
                       WHERE batch_id = p_batch_id) AS x_sfdc_item_out_tabtyp)
                        INTO x_out_item
                        FROM DUAL;

      x_ret_status := 'S';
      x_ret_msg := NULL;

    ELSIF p_mode = 'LIST' THEN
       FOR n IN 1..p_inv_id_ls.COUNT
       LOOP
           OPEN c_item_list (p_inv_id_ls(n).record_id, p_inv_id_ls(n).inventory_item_id);
           FETCH c_item_list
           BULK COLLECT INTO x_sfdc_item_tbl;
           CLOSE c_item_list;

           IF x_sfdc_item_tbl.COUNT >0 THEN
              FORALL i IN 1..x_sfdc_item_tbl.COUNT
              INSERT INTO xx_sfdc_item_out_stg
              VALUES x_sfdc_item_tbl (i);
           END IF;
       END LOOP;

       SELECT CAST (MULTISET (SELECT batch_id
                                   ,record_id
                                   ,inventory_item_id
                                   ,item_code
                                   ,long_description
                                   ,description
                                   ,item_status
                                   ,comms_nl_trackable_flag
                                   ,division
                                   ,product_segment
                                   ,brand
                                   ,product_class
                                   ,product_class_desc
                                   ,product_type
                                   ,product_type_desc
                                   ,subdivision
                                   ,product_use
                                   ,product_use_desc
                                   ,product_family
                                   ,product_family_desc
                                   ,inv_product_type
                                   ,inv_product_type_desc
                                   ,item_cost
                              FROM xx_sfdc_item_out_stg
       WHERE batch_id = p_batch_id) AS x_sfdc_item_out_tabtyp)
       INTO x_out_item
       FROM DUAL;

       x_ret_status := 'S';
       x_ret_msg := NULL;
    END IF;
  EXCEPTION
      WHEN e_incorrect_mode THEN
        x_ret_status := 'E';
        x_ret_msg := 'Mode is mandatory and can be BATCH or LIST';
      WHEN OTHERS THEN
        x_ret_status := 'E';
        x_ret_msg := SQLERRM;
  END get_item;

-- -------------------------------------------------------------------------------------------

  FUNCTION sfdc_publish_item    ( p_subscription_guid   IN              RAW,
                                  p_event               IN OUT NOCOPY   wf_event_t
                                )
  RETURN VARCHAR2 IS
  PRAGMA AUTONOMOUS_TRANSACTION;

    x_inv_item_id      NUMBER;
    x_org_id           NUMBER;
	x_org_code         VARCHAR2(3);
    x_rec_id           NUMBER;
	x_view_rec         xx_sfdc_item_out_v%ROWTYPE;
	x_stg_rec          xx_sfdc_item_out_stg%ROWTYPE;
	x_event_name       VARCHAR2(240);

  BEGIN

    x_inv_item_id   := p_event.getvalueforparameter('INVENTORY_ITEM_ID');
    x_org_id        := p_event.getvalueforparameter('ORGANIZATION_ID');

	SELECT organization_code
	INTO x_org_code
	FROM org_organization_definitions
	WHERE organization_id = x_org_id;

	IF (x_org_code = 'MST') THEN

	  IF (p_event.getEventName() = 'oracle.apps.ego.item.postItemUpdate') THEN

      SELECT *
	  INTO x_view_rec
      FROM xx_sfdc_item_out_v
      WHERE inventory_item_id = x_inv_item_id;

	  SELECT *
      INTO x_stg_rec
	  FROM xx_sfdc_item_out_stg
      WHERE inventory_item_id = x_inv_item_id
      AND last_update_date = (SELECT MAX(last_update_date)
                              FROM xx_sfdc_item_out_stg
                              WHERE inventory_item_id = x_inv_item_id);

      IF (x_view_rec.item_code                               !=   x_stg_rec.item_code
          OR NVL(x_view_rec.long_description, 'A')           !=   NVL(x_stg_rec.long_description, 'A')
		  OR x_view_rec.description                          !=   x_stg_rec.description
		  OR x_view_rec.item_status                          !=   x_stg_rec.item_status
		  OR NVL(x_view_rec.comms_nl_trackable_flag, 'A')    !=   NVL(x_stg_rec.comms_nl_trackable_flag, 'A')
		  OR NVL(x_view_rec.division, 'A')                   !=   NVL(x_stg_rec.division, 'A')
		  OR NVL(x_view_rec.product_segment, 'A')            !=   NVL(x_stg_rec.product_segment, 'A')
		  OR NVL(x_view_rec.brand, 'A')                      !=   NVL(x_stg_rec.brand, 'A')
		  OR NVL(x_view_rec.product_class, 'A')              !=   NVL(x_stg_rec.product_class, 'A')
		  OR NVL(x_view_rec.product_class_desc, 'A')         !=   NVL(x_stg_rec.product_class_desc, 'A')
		  OR NVL(x_view_rec.product_type, 'A')               !=   NVL(x_stg_rec.product_type, 'A')
		  OR NVL(x_view_rec.product_type_desc, 'A')          !=   NVL(x_stg_rec.product_type_desc, 'A')
		  OR NVL(x_view_rec.subdivision, 'A')                !=   NVL(x_stg_rec.subdivision, 'A')
		  OR NVL(x_view_rec.product_use, 'A')                !=   NVL(x_stg_rec.product_use, 'A')
		  OR NVL(x_view_rec.product_use_desc, 'A')           !=   NVL(x_stg_rec.product_use_desc, 'A')
		  OR NVL(x_view_rec.product_family, 'A')             !=   NVL(x_stg_rec.product_family, 'A')
		  OR NVL(x_view_rec.product_family_desc, 'A')        !=   NVL(x_stg_rec.product_family_desc, 'A')
		  OR NVL(x_view_rec.inv_product_type, 'A')           !=   NVL(x_stg_rec.inv_product_type, 'A')
		  OR NVL(x_view_rec.inv_product_type_desc, 'A')      !=   NVL(x_stg_rec.inv_product_type_desc, 'A')
		 ) THEN

      SELECT XXINTG.XX_SFDC_ITEM_OUT_CTL_S1.NEXTVAL
	  INTO x_rec_id
	  FROM DUAL;

	  INSERT INTO xx_sfdc_item_out_ctl ( batch_id
             					        ,record_id
             					        ,inventory_item_id
             					        ,publish_time
                 				        ,publish_system
                                        ,target_system
             					        ,status
             					        ,ack_time
             					        ,aia_proc_inst_id
             					        ,creation_date
             					        ,created_by
             					        ,last_update_date
             					        ,last_updated_by
             					        ,last_update_login
									   )
      VALUES( NULL
             ,x_rec_id
             ,NVL(x_inv_item_id, 1)
             ,SYSDATE
             ,'EBS'
			 ,NULL
             ,'NEW'
             ,NULL
             ,NULL
             ,SYSDATE
             ,fnd_global.user_id
             ,SYSDATE
             ,fnd_global.user_id
             ,fnd_global.user_id);
      END IF;

      ELSE

	  SELECT XXINTG.XX_SFDC_ITEM_OUT_CTL_S1.NEXTVAL
	  INTO x_rec_id
	  FROM DUAL;

	  INSERT INTO xx_sfdc_item_out_ctl ( batch_id
             					        ,record_id
             					        ,inventory_item_id
             					        ,publish_time
                 				        ,publish_system
                                        ,target_system
             					        ,status
             					        ,ack_time
             					        ,aia_proc_inst_id
             					        ,creation_date
             					        ,created_by
             					        ,last_update_date
             					        ,last_updated_by
             					        ,last_update_login
									   )
      VALUES( NULL
             ,x_rec_id
             ,NVL(x_inv_item_id, 1)
             ,SYSDATE
             ,'EBS'
			 ,NULL
             ,'NEW'
             ,NULL
             ,NULL
             ,SYSDATE
             ,fnd_global.user_id
             ,SYSDATE
             ,fnd_global.user_id
             ,fnd_global.user_id);
      END IF;

	END IF;

    COMMIT;
    RETURN ('SUCCESS');
  END sfdc_publish_item  ;

END xx_sfdc_item_out_pkg;
/
