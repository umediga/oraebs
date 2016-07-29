DROP PACKAGE APPS.XX_QP_GEN_INS_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_GEN_INS_CNV_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : DebJANI Roy
 Creation Date  : 02-jUN-2013
 File Name      : XXQPINSERT.pks
 Description    : This script creates the specification of the package xx_qp_gen_ins_cnv_pkg

----------------------------*------------------------------------------------------------------
-- Conversion Checklist ID  *  Change Required By Developer                                  --
----------------------------*------------------------------------------------------------------

----------------------------*------------------------------------------------------------------

 Change History:

Version Date        Name                  Remarks
------- ----------- ---------            ---------------------------------------
1.0     02-JUN-2013 DebJANI Roy  Initial development.
-------------------------------------------------------------------------
*/

    PROCEDURE main (
                     errbuf          OUT VARCHAR2,
                     retcode         OUT VARCHAR2,
                     p_batch_id      IN VARCHAR2,
                     p_pricelist     IN VARCHAR2,
                     p_modifier      IN VARCHAR2,
                     p_qualgroups    IN VARCHAR2
                    );

END xx_qp_gen_ins_cnv_pkg;
/
