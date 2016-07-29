DROP PACKAGE BODY APPS.XX_SDC_ORDER_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_SDC_ORDER_OUTBOUND_WS_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By	: Renjith
 Creation Date	: 12-Feb-2014
 File Name	: XX_SDC_ORDER_INT.pkb
 Description	: This script creates the specification of the package

 Change History:

 Date          Name           Remarks
 -----------   ----           ---------------------------------------
 12-Feb-2014   Renjith        Initial development.
*/
----------------------------------------------------------------------

   ----------------------------------------------------------------------
   PROCEDURE get_del_details    ( p_mode               IN              VARCHAR2
                                 ,p_publish_batch_id   IN              NUMBER
                                 ,p_instance_id        IN              NUMBER
                                 ,x_del_out_tab        OUT NOCOPY      xx_sfdc_order_del_out_tabtyp
                                 ,x_return_status      OUT NOCOPY      VARCHAR2
                                 ,x_return_message     OUT NOCOPY      VARCHAR2
                                )
   IS
      CURSOR c_del_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xoops.publish_batch_id,xoops.record_id,xoops.status_flag,xoohw.*
           FROM xx_sdc_order_del_v xoohw,
                (SELECT DISTINCT  record_id,publish_batch_id,status_flag,header_id,line_id,delivery_detail_id
                            FROM  xx_om_sfdc_del_control_tbl
                           WHERE  publish_batch_id = cp_publish_batch_id
                             AND  status_flag = 'NEW' ) xoops
          WHERE xoohw.header_id = xoops.header_id
            AND xoohw.line_id = xoops.line_id
            AND xoohw.delivery_detail_id = xoops.delivery_detail_id;

      x_error_code             VARCHAR2(1)   := xx_emf_cn_pkg.CN_SUCCESS;
      x_incorrect_mode         EXCEPTION;
      x_publish_batch_id       NUMBER        := NULL;

      TYPE oe_order_del_tbl IS TABLE OF xx_sdc_order_delivery_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_oe_order_del_tbl   oe_order_del_tbl;

   BEGIN
      x_publish_batch_id := p_publish_batch_id;
      x_return_status := xx_emf_cn_pkg.cn_success;
      -- Emf Env initialization
      x_error_code := xx_emf_pkg.set_env;

      IF p_mode IS NULL OR p_mode NOT IN ('BATCH')
      THEN
         RAISE x_incorrect_mode;
      END IF;

      UPDATE  xx_om_sfdc_del_control_tbl
         SET  instance_id  = p_instance_id
             --,status_flag  ='INPROGRESS'
             ,publish_time = SYSDATE
       WHERE  publish_batch_id = x_publish_batch_id
         AND  status_flag = 'NEW';

      OPEN c_del_info (x_publish_batch_id);
      FETCH c_del_info
      BULK COLLECT INTO x_oe_order_del_tbl;
      CLOSE c_del_info;

      IF x_oe_order_del_tbl.COUNT > 0
      THEN
         FORALL i_rec IN 1 .. x_oe_order_del_tbl.COUNT
            INSERT INTO xx_sdc_order_delivery_stg
                 VALUES x_oe_order_del_tbl (i_rec);
      END IF;

      SELECT CAST
                (MULTISET (SELECT *
                             FROM xx_sdc_order_del_mst_v
                            WHERE publish_batch_id = x_publish_batch_id) AS xx_sfdc_order_del_out_tabtyp
                )
        INTO x_del_out_tab
        FROM DUAL;

      x_return_status := 'S';
      x_return_message := NULL;
   EXCEPTION
      WHEN x_incorrect_mode THEN
         x_return_status := 'E';
         x_return_message := 'Mode is mandatory and can be BATCH or LIST';
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END get_del_details;
   ----------------------------------------------------------------------
   PROCEDURE get_line_details   ( p_mode               IN              VARCHAR2
                                 ,p_publish_batch_id   IN              NUMBER
                                 ,p_instance_id        IN              NUMBER
                                 ,x_line_out_tab       OUT NOCOPY      xx_sfdc_order_line_out_tabtyp
                                 ,x_return_status      OUT NOCOPY      VARCHAR2
                                 ,x_return_message     OUT NOCOPY      VARCHAR2
                                )
   IS
      CURSOR c_line_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xoops.publish_batch_id,xoops.record_id,xoops.status_flag,xoohw.*
           FROM xx_sdc_order_line_v xoohw,
                (SELECT DISTINCT  record_id,publish_batch_id,status_flag,header_id,line_id
                            FROM  xx_om_sfdc_line_control_tbl
                           WHERE  publish_batch_id = cp_publish_batch_id
                             AND  status_flag = 'NEW' ) xoops
          WHERE xoohw.header_id = xoops.header_id
            AND xoohw.line_id = xoops.line_id;

      x_error_code             VARCHAR2(1)   := xx_emf_cn_pkg.CN_SUCCESS;
      x_incorrect_mode         EXCEPTION;
      x_publish_batch_id       NUMBER        := NULL;

      TYPE oe_order_line_tbl IS TABLE OF xx_sdc_order_line_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_oe_order_line_tbl   oe_order_line_tbl;

   BEGIN
      x_publish_batch_id := p_publish_batch_id;
      x_return_status := xx_emf_cn_pkg.cn_success;
      -- Emf Env initialization
      x_error_code := xx_emf_pkg.set_env;

      IF p_mode IS NULL OR p_mode NOT IN ('BATCH')
      THEN
         RAISE x_incorrect_mode;
      END IF;

      UPDATE  xx_om_sfdc_line_control_tbl
         SET  instance_id  = p_instance_id
             --,status_flag  ='INPROGRESS'
             ,publish_time = SYSDATE
       WHERE  publish_batch_id = x_publish_batch_id
         AND  status_flag = 'NEW';

      OPEN c_line_info (x_publish_batch_id);
      FETCH c_line_info
      BULK COLLECT INTO x_oe_order_line_tbl;
      CLOSE c_line_info;

      IF x_oe_order_line_tbl.COUNT > 0
      THEN
         FORALL i_rec IN 1 .. x_oe_order_line_tbl.COUNT
            INSERT INTO xx_sdc_order_line_stg
                 VALUES x_oe_order_line_tbl (i_rec);
      END IF;

      SELECT CAST
                (MULTISET (SELECT *
                             FROM xx_sdc_order_line_mst_v
                            WHERE publish_batch_id = x_publish_batch_id) AS xx_sfdc_order_line_out_tabtyp
                )
        INTO x_line_out_tab
        FROM DUAL;

      x_return_status := 'S';
      x_return_message := NULL;
   EXCEPTION
      WHEN x_incorrect_mode THEN
         x_return_status := 'E';
         x_return_message := 'Mode is mandatory and can be BATCH or LIST';
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END get_line_details;

   ----------------------------------------------------------------------

   PROCEDURE get_header_details ( p_mode               IN              VARCHAR2
                                 ,p_publish_batch_id   IN              NUMBER
                                 ,p_instance_id        IN              NUMBER
                                 ,x_head_out_tab       OUT NOCOPY      xx_sfdc_order_head_out_tabtyp
                                 ,x_return_status      OUT NOCOPY      VARCHAR2
                                 ,x_return_message     OUT NOCOPY      VARCHAR2
                                )
   IS
      CURSOR c_header_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xoops.publish_batch_id,xoops.record_id,xoops.status_flag,xoohw.*
           FROM xx_sdc_order_header_v xoohw,
                (SELECT DISTINCT  record_id,publish_batch_id,status_flag,header_id
                            FROM  xx_om_sfdc_head_control_tbl
                           WHERE  publish_batch_id = cp_publish_batch_id
                             AND  status_flag = 'NEW' ) xoops
          WHERE xoohw.header_id = xoops.header_id;

      x_error_code             VARCHAR2(1)   := xx_emf_cn_pkg.CN_SUCCESS;
      x_incorrect_mode         EXCEPTION;
      x_publish_batch_id       NUMBER        := NULL;

      TYPE oe_order_headers_tbl IS TABLE OF xx_sdc_order_header_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_oe_order_headers_tbl   oe_order_headers_tbl;

   BEGIN
      x_publish_batch_id := p_publish_batch_id;
      x_return_status := xx_emf_cn_pkg.cn_success;
      -- Emf Env initialization
      x_error_code := xx_emf_pkg.set_env;

      IF p_mode IS NULL OR p_mode NOT IN ('BATCH')
      THEN
         RAISE x_incorrect_mode;
      END IF;

      UPDATE  xx_om_sfdc_head_control_tbl
         SET  instance_id  = p_instance_id
             --,status_flag  ='INPROGRESS'
             ,publish_time = SYSDATE
       WHERE  publish_batch_id = x_publish_batch_id
         AND  status_flag = 'NEW';

      OPEN c_header_info (x_publish_batch_id);
      FETCH c_header_info
      BULK COLLECT INTO x_oe_order_headers_tbl;
      CLOSE c_header_info;

      IF x_oe_order_headers_tbl.COUNT > 0
      THEN
         FORALL i_rec IN 1 .. x_oe_order_headers_tbl.COUNT
            INSERT INTO xx_sdc_order_header_stg
                 VALUES x_oe_order_headers_tbl (i_rec);
      END IF;

      SELECT CAST
                (MULTISET (SELECT *
                             FROM xx_sdc_order_head_mst_v
                            WHERE publish_batch_id = x_publish_batch_id) AS xx_sfdc_order_head_out_tabtyp
                )
        INTO x_head_out_tab
        FROM DUAL;

      x_return_status := 'S';
      x_return_message := NULL;

   EXCEPTION
      WHEN x_incorrect_mode THEN
         x_return_status := 'E';
         x_return_message := 'Mode is mandatory and can be BATCH or LIST';
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END get_header_details;
-- --------------------------------------------------------------------- --

   PROCEDURE header_status_update( p_head_status_tab    IN              xx_sfdc_order_hd_status_tabtyp
                                  ,x_return_status      OUT NOCOPY      VARCHAR2
                                  ,x_return_message     OUT NOCOPY      VARCHAR2
                                )
   IS
   BEGIN
      FOR rec IN p_head_status_tab.first .. p_head_status_tab.last
      LOOP

         UPDATE  xx_om_sfdc_head_control_tbl
            SET  status_flag      = p_head_status_tab(rec).status_flag
                ,response_message = p_head_status_tab(rec).response_message
                ,sfdc_id          = p_head_status_tab(rec).sfdc_id
                ,last_update_date = SYSDATE
          WHERE  publish_batch_id = p_head_status_tab(rec).publish_batch_id
            AND  record_id        = p_head_status_tab(rec).record_id
            AND  status_flag = 'NEW';

         /*IF p_head_status_tab(rec).status_flag = 'FAILED' THEN
            UPDATE  xx_om_sfdc_line_control_tbl
               SET  status_flag      = p_head_status_tab(rec).status_flag
                   ,response_message = p_head_status_tab(rec).response_message
                   ,sfdc_id          = p_head_status_tab(rec).sfdc_id
                   ,last_update_date = SYSDATE
             WHERE  header_id IN (SELECT header_id
                                    FROM xx_om_sfdc_head_control_tbl
                                   WHERE publish_batch_id = p_head_status_tab(rec).publish_batch_id
                                     AND record_id        = p_head_status_tab(rec).record_id)
               AND  status_flag = 'NEW';

            UPDATE  xx_om_sfdc_del_control_tbl
               SET  status_flag      = p_head_status_tab(rec).status_flag
                   ,response_message = p_head_status_tab(rec).response_message
                   ,sfdc_id          = p_head_status_tab(rec).sfdc_id
                   ,last_update_date = SYSDATE
             WHERE  header_id IN (SELECT header_id
                                    FROM xx_om_sfdc_head_control_tbl
                                   WHERE publish_batch_id = p_head_status_tab(rec).publish_batch_id
                                     AND record_id        = p_head_status_tab(rec).record_id)
               AND  status_flag = 'NEW';
         END IF;*/
      END LOOP;
   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END header_status_update;
-- --------------------------------------------------------------------- --

   PROCEDURE line_status_update  ( p_line_status_tab    IN              xx_sfdc_order_ln_status_tabtyp
                                  ,x_return_status      OUT NOCOPY      VARCHAR2
                                  ,x_return_message     OUT NOCOPY      VARCHAR2
                                )
   IS
   BEGIN

      FOR rec IN p_line_status_tab.first .. p_line_status_tab.last
      LOOP
         UPDATE  xx_om_sfdc_line_control_tbl
            SET  status_flag      = p_line_status_tab(rec).status_flag
                ,response_message = p_line_status_tab(rec).response_message
                ,sfdc_id          = p_line_status_tab(rec).sfdc_id
                ,last_update_date = SYSDATE
          WHERE  publish_batch_id = p_line_status_tab(rec).publish_batch_id
            AND  record_id        = p_line_status_tab(rec).record_id
            AND  status_flag = 'NEW';

        /*IF p_line_status_tab(rec).status_flag = 'FAILED' THEN
            UPDATE  xx_om_sfdc_del_control_tbl
               SET  status_flag      = p_line_status_tab(rec).status_flag
                   ,response_message = p_line_status_tab(rec).response_message
                   ,sfdc_id          = p_line_status_tab(rec).sfdc_id
                   ,last_update_date = SYSDATE
             WHERE  line_id IN (SELECT line_id
                                  FROM xx_om_sfdc_line_control_tbl
                                 WHERE publish_batch_id = p_line_status_tab(rec).publish_batch_id
                                   AND record_id        = p_line_status_tab(rec).record_id)
               AND  status_flag = 'NEW';
        END IF;*/
      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END line_status_update;
-- --------------------------------------------------------------------- --

   PROCEDURE del_status_update   ( p_del_status_tab     IN              xx_sfdc_order_dl_status_tabtyp
                                  ,x_return_status      OUT NOCOPY      VARCHAR2
                                  ,x_return_message     OUT NOCOPY      VARCHAR2
                                )
   IS
   BEGIN

      FOR rec IN p_del_status_tab.first .. p_del_status_tab.last
      LOOP
        UPDATE  xx_om_sfdc_del_control_tbl
           SET  status_flag      = p_del_status_tab(rec).status_flag
               ,response_message = p_del_status_tab(rec).response_message
               ,sfdc_id          = p_del_status_tab(rec).sfdc_id
               ,last_update_date = SYSDATE
         WHERE  publish_batch_id = p_del_status_tab(rec).publish_batch_id
           AND  record_id        = p_del_status_tab(rec).record_id
           AND  status_flag = 'NEW';
      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END del_status_update;
-- --------------------------------------------------------------------- --

END xx_sdc_order_outbound_ws_pkg;
/
