DROP PACKAGE APPS.XX_SDC_OIC_SP_DET_OUT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_SDC_OIC_SP_DET_OUT_PKG" 
IS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 04-APR-2014
 File Name     : XXSDCOICSPOUTWS.pks
 Description   : This script creates the specification of the package
                 xx_sdc_oic_sp_det_out_pkg
 Change History:
 Date        Name                  Remarks
 ----------- -------------         -----------------------------------
 04-APR-2014 Sharath Babu          Initial Development
 */
----------------------------------------------------------------------
   PROCEDURE xx_get_oic_details (
         p_mode                 IN              VARCHAR2,
         p_publish_batch_id     IN              NUMBER,
         p_sale_person_num_ls   IN              xx_sdc_oic_sp_det_ls_ot_tabtyp,
         x_output_oic_det       OUT NOCOPY      xx_sdc_oic_sp_det_ot_tabtyp,
         x_return_status        OUT NOCOPY      VARCHAR2,
         x_return_message       OUT NOCOPY      VARCHAR2
   );

END xx_sdc_oic_sp_det_out_pkg;
/
