DROP PACKAGE BODY APPS.XX_P2P_HCP_EXTN;

CREATE OR REPLACE PACKAGE BODY APPS."XX_P2P_HCP_EXTN" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 19-June-2013
File Name     : XXP2PHCPEXT.pkb
Description   : This script creates the body of the package xx_p2p_hcp_extn
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
19-June-2013  ABHARGAVA            Initial Draft.
02-Dec-2014   Dhiren               WAVE2 Additions : attribute8 to attribute13
----------------------------------------------------------------------

COMMON GUIDELINES REGARDING EMF
-------------------------------
1. All low level emf messages can be retained
2. Hard coding of emf messages are allowed in the code
3. Any other hard coding should be dealt by constants package
4. Exception handling should be left as is most of the places unless specified


-- DO NOT CHANGE ANYTHING IN THE PROCEDURES set_cnv_env
-- START RESTRICTIONS
*/
-------------------------------------------------------------------------------------
------------< Procedure for setting Environment >------------
-------------------------------------------------------------------------------------

PROCEDURE set_cnv_env
IS
  x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
BEGIN
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Start of set_cnv_env');
  -- Set the environment
  x_error_code := xx_emf_pkg.set_env;

  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'End of set_cnv_env');

EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                           ' Error Message in  EMF :' || SQLERRM
                          );
     RAISE xx_emf_pkg.g_e_env_not_set;
END set_cnv_env;


-------------------------------------------------------------------------------------
----------------------------------Procedure main-------------------------------------
-------------------------------------------------------------------------------------
PROCEDURE main (
                errbuf                OUT NOCOPY      VARCHAR2,
                retcode               OUT NOCOPY      VARCHAR2
               )
IS
-- Cursor to Pick Valid PO's that have been created after the last update
CURSOR C1_CURR IS
select poh.po_header_id, poh.segment1 ,pol.line_num,poll.LINE_LOCATION_ID,poll.attribute1 ATT1_PO,prl.attribute1 ATT1_REQ
      ,prl.attribute8
      ,prl.attribute9
      ,prl.attribute10
      ,prl.attribute11
      ,prl.attribute12
      ,prl.attribute13
from po_headers poh,
     po_lines pol,
     po_line_locations poll,
     po_requisition_lines prl
where /*poh.creation_date > = (select to_date(b.PARAMETER_VALUE,'MM/DD/YYYY HH:MI:SS AM')
                             from xx_emf_process_setup a
                                 ,xx_emf_process_parameters b
                             where a.process_id = b.process_id
                             and a.process_name = 'XXP2PHCPEXT'
                             and b.parameter_name = 'LAST_UPDATE')
and*/ poh.po_header_id = poll.po_header_id
and pol.po_line_id = poll.po_line_id
and pol.po_header_id = poh.po_header_id
and poll.line_location_id = prl.line_location_id
and prl.attribute1 = 'Y'
and nvl(poll.attribute1,'N') <> 'Y';

l_suc_cnt     NUMBER := 0;
l_err_cnt     NUMBER := 0;

BEGIN
     retcode := xx_emf_cn_pkg.CN_SUCCESS;

     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Set_cnv_env');
     set_cnv_env;

     FOR C1 in C1_CURR
     LOOP
        BEGIN
            update po_line_locations
            set attribute1 = 'Y'
               ,attribute8 = C1.attribute8
               ,attribute9 = C1.attribute9
               ,attribute10 = C1.attribute10
               ,attribute11 = C1.attribute11
               ,attribute12 = C1.attribute12
               ,attribute13 = C1.attribute13
            where line_location_id = C1.LINE_LOCATION_ID;

            xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Updated Line -'||C1.LINE_LOCATION_ID);
            l_suc_cnt := l_suc_cnt +1;
        EXCEPTION
        WHEN OTHERS THEN
            xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                              xx_emf_cn_pkg.CN_STG_DATADRV,
                              'Updating Line Location '|| ': ' || SQLERRM,
                              c1.SEGMENT1,
                              c1.LINE_NUM,
                              c1.LINE_LOCATION_ID
                              );

            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Updating Line -'||C1.LINE_LOCATION_ID);
            l_err_cnt := l_err_cnt +1 ;
            retcode := xx_emf_cn_pkg.CN_REC_WARN;
        END;
     END LOOP;

     IF l_suc_cnt >= 1 THEN
         UPDATE xx_emf_process_parameters
         set PARAMETER_VALUE = to_char(sysdate,'MM/DD/YYYY HH:MI:SS AM')
         where parameter_name = 'LAST_UPDATE'
         and process_id = (select process_id from xx_emf_process_setup where process_name = 'XXP2PHCPEXT');
     END IF;

     xx_emf_pkg.update_recs_cnt
        (
            p_total_recs_cnt   => l_suc_cnt+l_err_cnt,
            p_success_recs_cnt => l_suc_cnt,
            p_warning_recs_cnt => 0,
            p_error_recs_cnt   => l_err_cnt
        );

     xx_emf_pkg.create_report;

EXCEPTION
     WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;
     WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'REC_ERROR');
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;
    WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'PRC_ERROR');
         retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         xx_emf_pkg.create_report;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS');
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.create_report;
END main;

END xx_p2p_hcp_extn;
/
