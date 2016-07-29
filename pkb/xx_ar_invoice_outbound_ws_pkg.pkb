DROP PACKAGE BODY APPS.XX_AR_INVOICE_OUTBOUND_WS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_AR_INVOICE_OUTBOUND_WS_PKG" 
AS

--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain
 Creation Date  : 05-APR-2012
 Filename       : XXARINVOUTWS.pkb
 Description    : Invoice Outbound Web Service API.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 05-APR-2012   1.0       Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------
   PROCEDURE get_invoice_details (
      p_mode               IN              VARCHAR2,
      p_publish_batch_id   IN              NUMBER,
      p_ar_input_invoice     IN              xx_ar_input_inv_ws_out_tabtyp,
      x_ar_output_invoice    OUT NOCOPY      xx_ar_inv_outbound_ws_tabtyp,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   )
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain
 Creation Date  : 05-APR-2012
 Description    : This procedure is called by the AIA Web Service
                  to fetch Invoice details.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 05-APR-2012   1.0       Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------
      CURSOR c_invoice_header_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xaihw.*
           FROM xx_ar_invoice_headers_ws_v xaihw,
                (SELECT DISTINCT customer_trx_id
                            FROM xx_ar_invoice_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id) xaips
          WHERE xaihw.customer_trx_id = xaips.customer_trx_id;

      CURSOR c_invoice_line_info (cp_publish_batch_id NUMBER)
      IS
         SELECT xailw.*
           FROM xx_ar_invoice_lines_ws_v xailw,
                (SELECT DISTINCT customer_trx_id
                            FROM xx_ar_invoice_publish_stg
                           WHERE publish_batch_id = cp_publish_batch_id) xaips
          WHERE xailw.customer_trx_id = xaips.customer_trx_id;

      x_publish_batch_id       NUMBER               := NULL;
      e_incorrect_mode         EXCEPTION;

      TYPE ar_invoice_publish_tbl IS TABLE OF xx_ar_invoice_publish_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_ar_invoice_publish_tbl   ar_invoice_publish_tbl;

      TYPE ar_invoice_headers_tbl IS TABLE OF xx_ar_invoice_headers_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_ar_invoice_headers_tbl   ar_invoice_headers_tbl;

      TYPE ar_invoice_lines_tbl IS TABLE OF xx_ar_invoice_lines_stg%ROWTYPE
         INDEX BY BINARY_INTEGER;

      x_ar_invoice_lines_tbl     ar_invoice_lines_tbl;
   BEGIN
      x_publish_batch_id := p_publish_batch_id;

      IF p_mode IS NULL OR p_mode NOT IN ('BATCH', 'LIST')
      THEN
         RAISE e_incorrect_mode;
      END IF;

      IF p_mode = 'LIST'
      THEN
         SELECT xx_ar_invoice_publish_stg_s1.NEXTVAL
           INTO x_publish_batch_id
           FROM DUAL;

         x_ar_invoice_publish_tbl.DELETE;

         FOR i IN 1 .. p_ar_input_invoice.COUNT
         LOOP
            x_ar_invoice_publish_tbl (i).publish_batch_id := x_publish_batch_id;
            x_ar_invoice_publish_tbl (i).customer_trx_id :=
                                               p_ar_input_invoice (i).customer_trx_id;
            x_ar_invoice_publish_tbl (i).publish_time := SYSDATE;
            x_ar_invoice_publish_tbl (i).publish_system := NULL;
            x_ar_invoice_publish_tbl (i).ack_status := NULL;
            x_ar_invoice_publish_tbl (i).ack_time := NULL;
            x_ar_invoice_publish_tbl (i).aia_proc_inst_id := NULL;
            x_ar_invoice_publish_tbl (i).creation_date := SYSDATE;
            x_ar_invoice_publish_tbl (i).created_by := fnd_global.user_id;
            x_ar_invoice_publish_tbl (i).last_update_date := SYSDATE;
            x_ar_invoice_publish_tbl (i).last_updated_by := fnd_global.user_id;
            x_ar_invoice_publish_tbl (i).last_update_login :=
                                                           fnd_global.user_id;
         END LOOP;

         IF x_ar_invoice_publish_tbl.COUNT > 0
         THEN
            FORALL i_rec IN 1 .. x_ar_invoice_publish_tbl.COUNT
               INSERT INTO xx_ar_invoice_publish_stg
                    VALUES x_ar_invoice_publish_tbl (i_rec);
         END IF;
      END IF;

      OPEN c_invoice_header_info (x_publish_batch_id);

      FETCH c_invoice_header_info
      BULK COLLECT INTO x_ar_invoice_headers_tbl;

      CLOSE c_invoice_header_info;

      IF x_ar_invoice_headers_tbl.COUNT > 0
      THEN
         FOR i IN x_ar_invoice_headers_tbl.FIRST .. x_ar_invoice_headers_tbl.LAST
         LOOP
            x_ar_invoice_headers_tbl (i).publish_batch_id := x_publish_batch_id;
         END LOOP;

         FORALL i_rec IN 1 .. x_ar_invoice_headers_tbl.COUNT
            INSERT INTO xx_ar_invoice_headers_stg
                 VALUES x_ar_invoice_headers_tbl (i_rec);
      END IF;

      OPEN c_invoice_line_info (x_publish_batch_id);

      FETCH c_invoice_line_info
      BULK COLLECT INTO x_ar_invoice_lines_tbl;

      CLOSE c_invoice_line_info;

      IF x_ar_invoice_lines_tbl.COUNT > 0
      THEN
         FOR i IN x_ar_invoice_lines_tbl.FIRST .. x_ar_invoice_lines_tbl.LAST
         LOOP
            x_ar_invoice_lines_tbl (i).publish_batch_id := x_publish_batch_id;
         END LOOP;

         FORALL i_rec IN 1 .. x_ar_invoice_lines_tbl.COUNT
            INSERT INTO xx_ar_invoice_lines_stg
                 VALUES x_ar_invoice_lines_tbl (i_rec);
      END IF;

      SELECT CAST
                (MULTISET (SELECT *
                             FROM xx_ar_invoice_outbound_ws_v
                            WHERE publish_batch_id = x_publish_batch_id) AS xx_ar_inv_outbound_ws_tabtyp
                )
        INTO x_ar_output_invoice
        FROM DUAL;

      x_return_status := 'S';
      x_return_message := NULL;
   EXCEPTION
      WHEN e_incorrect_mode
      THEN
         x_return_status := 'E';
         x_return_message := 'Mode is mandatory and can be BATCH or LIST';
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END get_invoice_details;

   PROCEDURE update_ack (
      p_publish_batch_id   IN              NUMBER,
      p_publish_system     IN              VARCHAR2,
      p_ack_status         IN              VARCHAR2,
      p_aia_proc_inst_id   IN              VARCHAR2,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_return_message     OUT NOCOPY      VARCHAR2
   )
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain
 Creation Date  : 05-APR-2012
 Description    : This procedure is called by the AIA Web Service
                  to update the Acknowledgement Status to Ebiz.

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 05-APR-2012   1.0       Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------
   BEGIN
      IF p_publish_batch_id IS NOT NULL
      THEN
         UPDATE xx_ar_invoice_publish_stg
            SET ack_status = p_ack_status,
                ack_time = SYSDATE,
                aia_proc_inst_id = p_aia_proc_inst_id,
                last_update_date = SYSDATE,
                last_updated_by = fnd_global.user_id,
                last_update_login = fnd_global.user_id
          WHERE publish_batch_id = p_publish_batch_id
            AND NVL(publish_system,'XX') = NVL(p_publish_system,'XX');
      END IF;

      x_return_status := 'S';
      x_return_message := NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_message := SQLERRM;
   END update_ack;

   --------------------------------------------------------------------------------
   FUNCTION get_order_header_id (
      p_customer_trx_id   NUMBER
   )
      RETURN NUMBER
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain
 Creation Date  : 23-Apr-2012
 Filename       :
 Description    : This function returns the sales order header id for the current transaction

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 23-Apr-2012   1.0       Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------
      x_order_header_id   NUMBER := NULL;
   BEGIN

      SELECT ooh.header_id INTO x_order_header_id
      FROM oe_order_headers_all ooh
		  ,oe_order_lines_all ool
		  ,ra_customer_trx_lines_all rctl
      WHERE ooh.header_id = ool.header_id
      AND ool.line_id = rctl.interface_line_attribute6
      AND rctl.customer_trx_id = p_customer_trx_id
      AND rownum = 1;

      RETURN x_order_header_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_order_header_id;


      --------------------------------------------------------------------------------
   FUNCTION get_notes (
      p_customer_trx_id   NUMBER
   )
      RETURN VARCHAR2
   IS
--------------------------------------------------------------------------------
 /*
 Created By     : Deepika Jain
 Creation Date  : 26-Apr-2012
 Filename       :
 Description    : This function returns the notes from ar_notes for the current transaction

 Change History:

 Date        Version#    Name                Remarks
 ----------- --------    ---------------     -----------------------------------
 26-Apr-2012   1.0       Deepika Jain         Initial development.

 */
--------------------------------------------------------------------------------
      CURSOR get_ar_notes(p_customer_trx_id IN NUMBER)
	  IS
	  SELECT text
	  FROM ar_notes
	  WHERE customer_trx_id = p_customer_trx_id;

	  x_notes   VARCHAR2(4000) := NULL;
	  x_sqlcode                NUMBER;
      x_sqlerrm                VARCHAR2 (2000);
   BEGIN
	  FOR ar_notes_rec IN get_ar_notes(p_customer_trx_id)
	  LOOP
		x_notes := x_notes||ar_notes_rec.text;
	  END LOOP;
      RETURN SUBSTR(x_notes,1,80);
   EXCEPTION
      WHEN OTHERS
      THEN
         x_sqlcode := SQLCODE;
         x_sqlerrm := SUBSTR (SQLERRM, 1, 2000);
         RETURN 'ERROR';
   END get_notes;

END xx_ar_invoice_outbound_ws_pkg;
/
