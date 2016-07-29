DROP PACKAGE APPS.XX_INV_CROSS_REF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_CROSS_REF_PKG" AUTHID CURRENT_USER AS
  /* $Header: XXINTGBOMCNV.pks 1.0.0 2012/10/18 00:00:00 partha noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 18-OCT-2012
  -- Filename       : XXINVCROSSREF.pks
  -- Description    : Package body for Item cross reference conversion

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 18-OCT-2012   1.0       Partha S Mohanty    Initial development.
--====================================================================================

   -- Global Variables

    G_BATCH_SIZE		    NUMBER(15) :=10000;
    G_API_NAME          VARCHAR2(2000);
    G_REC_NEW			      VARCHAR2(10):='NEW';

    TYPE xxcrossRecordType IS RECORD (
          batch_id                        xx_inv_cross_ref_stg.batch_id%TYPE,
          record_number                   xx_inv_cross_ref_stg.record_number%TYPE,
          part_number                     xx_inv_cross_ref_stg.part_number%TYPE,
          error_flag                      xx_inv_cross_ref_stg.error_flag%TYPE,
          record_status                   xx_inv_cross_ref_stg.record_status%TYPE,
          error_message                   xx_inv_cross_ref_stg.error_message%TYPE,
          organization_id                 xx_inv_cross_ref_stg.organization_id%TYPE,
          cross_reference_id              xx_inv_cross_ref_stg.cross_reference_id%TYPE,
          inventory_item_id               xx_inv_cross_ref_stg.inventory_item_id%TYPE,
          cross_reference_type            xx_inv_cross_ref_stg.cross_reference_type%TYPE,
          cross_reference                 xx_inv_cross_ref_stg.cross_reference%TYPE,
          org_independent_flag            xx_inv_cross_ref_stg.org_independent_flag%TYPE,
          transaction_type                xx_inv_cross_ref_stg.transaction_type%TYPE,
          external_part_num               xx_inv_cross_ref_stg.external_part_num%TYPE
        );

    xxcrossrefRec           xxcrossRecordType;

    TYPE xxcrossrefRecord_tab IS TABLE OF xxcrossrefRec%TYPE
    INDEX BY BINARY_INTEGER;

    t_crossref_rec    xxcrossrefRecord_tab;

 PROCEDURE main( errbuf            OUT VARCHAR2
                 ,retcode          OUT VARCHAR2
                 ,p_cross_ref_type IN VARCHAR2
               );

END xx_inv_cross_ref_pkg;
/
