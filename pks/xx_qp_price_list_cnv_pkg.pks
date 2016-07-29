DROP PACKAGE APPS.XX_QP_PRICE_LIST_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_QP_PRICE_LIST_CNV_PKG" AS
----------------------------------------------------------------------
/*
 Created By     : Samir
 Creation Date  : 27-FEB-2012
 File Name      : XXQPPRICELISTCNVTL.pks
 Description    : This script creates the specification of the package xx_qp_price_list_cnv_pkg


Change History:

Version Date          Name        Remarks
------- -----------   --------    -------------------------------
1.0     27-FEB-2012   Samir       Initial development.
*/
----------------------------------------------------------------------

        G_STAGE         VARCHAR2(2000);
        G_BATCH_ID      VARCHAR2(200);

        --Added for Integra
  g_process_name          VARCHAR2(60)  := 'XXQPPRICELISTCNV';
  g_formal_pl             VARCHAR2(60)  := '-YORK';
  g_informal_pl           VARCHAR2(60)  := 'INFORMAL - ';
  g_validate_and_load     VARCHAR2(100) := 'VALIDATE_AND_LOAD';
  g_currency_header_id    NUMBER;
  G_ACTIVE_FLAG           VARCHAR2(1);-- := 'Y';
  G_GLOBAL_FLAG           VARCHAR2(1);-- := 'Y';
	G_ATOMATIC_FLAG         VARCHAR2(1);-- := 'Y';
	G_CURRENCY              VARCHAR2(3);-- := 'USD';
	--G_GMBH_CURRENCY         VARCHAR2(3);-- := 'EUR';
	G_END_DATE_ACTIVE       DATE;      --:= '31-DEC-2012';
	G_LIST_TYPE_CODE        VARCHAR2(3);-- := 'PRL';
	G_MOBILE_DOWNLOAD       VARCHAR2(1);-- := 'N';
	G_PRODUCT_ATTR_CONTEXT  VARCHAR2(10);--:= 'ITEM';
	G_PRODUCT_ATTR_CODE     VARCHAR2(30);--:= 'ITEM NUMBER';
	G_LIST_LINE_TYPE        VARCHAR2(10);--:= 'PLL';
  G_ARITHMETIC_OPERATOR   VARCHAR2(30);--:= 'UNIT_PRICE';
  G_PRODUCT_PRECEDENCE    NUMBER      ;--:= 220;

        TYPE G_XX_QP_PL_STG_REC_TYPE IS RECORD
        (
              ACTIVE_FLAG                VARCHAR2(1 BYTE),
          HDR_ATTRIBUTE1             VARCHAR2(240 BYTE),
          HDR_ATTRIBUTE2             VARCHAR2(240 BYTE),
          GLOBAL_FLAG                VARCHAR2(1 BYTE),
          OPERATING_UNIT             VARCHAR2(240 BYTE),
          AUTOMATIC_FLAG             VARCHAR2(1 BYTE),
          COMMENTS                   VARCHAR2(2000 BYTE),
          CONTEXT                    VARCHAR2(30 BYTE),
          CURRENCY_CODE              VARCHAR2(30 BYTE),
          DELETE_FLAG                VARCHAR2(2 BYTE),
          DESCRIPTION                VARCHAR2(2000 BYTE),
          END_DATE_ACTIVE_HDR        DATE,
          END_DATE_ACTIVE_DTL        DATE,
          FREIGHT_TERMS_CODE         VARCHAR2(30 BYTE),
          LANGUAGE                   VARCHAR2(4 BYTE),
          LIST_SOURCE_CODE           VARCHAR2(30 BYTE),
          LIST_TYPE_CODE             VARCHAR2(100 BYTE),
          LOCK_FLAG                  VARCHAR2(2 BYTE),
          MOBILE_DOWNLOAD            VARCHAR2(1 BYTE),
          NAME                       VARCHAR2(240 BYTE),
          ORIG_SYS_HEADER_REF        VARCHAR2(50 BYTE),
          PROCESS_TYPE               VARCHAR2(30 BYTE),
          PTE_CODE                   VARCHAR2(30 BYTE),
          ROUNDING_FACTOR            NUMBER,
          SHIP_METHOD_CODE           VARCHAR2(30 BYTE),
          SOURCE_SYSTEM_CODE         VARCHAR2(30 BYTE),
          START_DATE_ACTIVE_HDR      DATE,
          START_DATE_ACTIVE_DTL      DATE,
          TERMS                      VARCHAR2(50 BYTE),
          VERSION_NO                 VARCHAR2(30 BYTE),
          ARITHMETIC_OPERATOR        VARCHAR2(100 BYTE),
          LEGACY_ITEM_NUMBER         VARCHAR2(240 BYTE),
          LIST_LINE_NO               VARCHAR2(30 BYTE),
          LIST_LINE_TYPE_CODE        VARCHAR2(100 BYTE),
          LIST_PRICE                 NUMBER,
          OPERAND                    NUMBER,
          ORGANIZATION_CODE          NUMBER,
          ORIG_SYS_LINE_REF          VARCHAR2(50 BYTE),
          PRIMARY_UOM_FLAG           VARCHAR2(4 BYTE),
          PRODUCT_PRECEDENCE         NUMBER,
          PRODUCT_ATTRIBUTE_CONTEXT  VARCHAR2(30 BYTE),
          PRODUCT_ATTR_CODE          VARCHAR2(50 BYTE),
          PRODUCT_ATTR_VALUE         VARCHAR2(240 BYTE),
          PRODUCT_UOM_CODE           VARCHAR2(3 BYTE),
          INTERFACE_ACTION_CODE      VARCHAR2(30 BYTE),
          PROCESS_FLAG               VARCHAR2(2 BYTE),
          PROCESS_STATUS_FLAG        VARCHAR2(2 BYTE),
          RECORD_NUMBER              NUMBER,
          BATCH_ID                   VARCHAR2(200 BYTE),
          PROCESS_CODE               VARCHAR2(240 BYTE),
          ERROR_CODE                 VARCHAR2(240 BYTE),
          CREATED_BY                 NUMBER,
          CREATION_DATE              DATE,
          LAST_UPDATE_DATE           DATE,
          LAST_UPDATED_BY            NUMBER,
          LAST_UPDATE_LOGIN          NUMBER,
              REQUEST_ID                 NUMBER
       );

        TYPE G_XX_QP_PL_STG_TAB_TYPE IS TABLE OF G_XX_QP_PL_STG_REC_TYPE
        INDEX BY BINARY_INTEGER;


     TYPE G_XX_QP_PL_PRE_REC_TYPE IS RECORD
    (
        ROW_ID                     ROWID,
        ACTIVE_FLAG                VARCHAR2(1 BYTE),
        HDR_ATTRIBUTE1             VARCHAR2(240 BYTE),
        HDR_ATTRIBUTE2             VARCHAR2(240 BYTE),
        GLOBAL_FLAG                VARCHAR2(1 BYTE),
        OPERATING_UNIT             VARCHAR2(240 BYTE),
        ORIG_ORG_ID                NUMBER,
        AUTOMATIC_FLAG             VARCHAR2(1 BYTE),
        COMMENTS                   VARCHAR2(2000 BYTE),
        CONTEXT                    VARCHAR2(30 BYTE),
        CURRENCY_CODE              VARCHAR2(30 BYTE),
        CURRENCY_HEADER_ID         NUMBER,
        DELETE_FLAG                VARCHAR2(2 BYTE),
        DESCRIPTION                VARCHAR2(2000 BYTE),
        END_DATE_ACTIVE_HDR        DATE,
        END_DATE_ACTIVE_DTL        DATE,
        FREIGHT_TERMS_CODE         VARCHAR2(30 BYTE),
        LANGUAGE                   VARCHAR2(4 BYTE),
        LIST_SOURCE_CODE           VARCHAR2(30 BYTE),
        LIST_TYPE_CODE             VARCHAR2(30 BYTE),
        LIST_TYPE_CODE_TEXT        VARCHAR2(100 BYTE),
        LOCK_FLAG                  VARCHAR2(2 BYTE),
        MOBILE_DOWNLOAD            VARCHAR2(1 BYTE),
        NAME                       VARCHAR2(240 BYTE),
        LIST_HEADER_ID             NUMBER,
        ORIG_SYS_HEADER_REF        VARCHAR2(50 BYTE),
        PROCESS_TYPE               VARCHAR2(30 BYTE),
        PTE_CODE                   VARCHAR2(30 BYTE),
        ROUNDING_FACTOR            NUMBER,
        SHIP_METHOD_CODE           VARCHAR2(30 BYTE),
        SOURCE_SYSTEM_CODE         VARCHAR2(30 BYTE),
        START_DATE_ACTIVE_HDR      DATE,
        START_DATE_ACTIVE_DTL      DATE,
        TERMS                      VARCHAR2(50 BYTE),
        VERSION_NO                 VARCHAR2(30 BYTE),
        ARITHMETIC_OPERATOR        VARCHAR2(30 BYTE),
        ARITHMETIC_OPERATOR_TEXT   VARCHAR2(100 BYTE),
        LEGACY_ITEM_NUMBER         VARCHAR2(240 BYTE),
        LIST_LINE_NO               VARCHAR2(30 BYTE),
        LIST_LINE_TYPE_CODE        VARCHAR2(30 BYTE),
        LIST_LINE_TYPE_CODE_TEXT   VARCHAR2(100 BYTE),
        LIST_PRICE                 NUMBER,
        OPERAND                    NUMBER,
        ORGANIZATION_CODE          NUMBER,
        ORIG_SYS_LINE_REF          VARCHAR2(50 BYTE),
        PRIMARY_UOM_FLAG           VARCHAR2(1 BYTE),
        PRODUCT_PRECEDENCE         NUMBER,
        PRODUCT_ATTRIBUTE_CONTEXT  VARCHAR2(30 BYTE),
        PRODUCT_ATTR_CODE          VARCHAR2(50 BYTE),
        product_attribute          VARCHAR2(240 BYTE),
        PRODUCT_ATTR_VALUE         VARCHAR2(240 BYTE),
        PRODUCT_UOM_CODE           VARCHAR2(3 BYTE),
        INTERFACE_ACTION_CODE      VARCHAR2(30 BYTE),
        PROCESS_FLAG               VARCHAR2(2 BYTE),
        PROCESS_STATUS_FLAG        VARCHAR2(2 BYTE),
        BATCH_ID                   VARCHAR2(200 BYTE),
        RECORD_NUMBER              NUMBER,
        PROCESS_CODE               VARCHAR2(240 BYTE),
        ERROR_CODE                 VARCHAR2(240 BYTE),
        CREATED_BY                 NUMBER,
        CREATION_DATE              DATE,
        LAST_UPDATE_DATE           DATE,
        LAST_UPDATED_BY            NUMBER,
        LAST_UPDATE_LOGIN          NUMBER,
        REQUEST_ID                 NUMBER
        );

        TYPE G_XX_QP_PL_PRE_TAB_TYPE IS TABLE OF G_XX_QP_PL_PRE_REC_TYPE
        INDEX BY BINARY_INTEGER;
       FUNCTION get_price_list_name(p_attribute1 IN VARCHAR2,
                                   p_attribute2 IN VARCHAR2,
				   p_currency    IN VARCHAR2)
      RETURN VARCHAR2;
      FUNCTION process_data_insert_mode (
            p_list_header_id  IN   NUMBER
           ,p_name            IN   VARCHAR2
      )
      RETURN NUMBER;

       FUNCTION process_data_update_mode (
             p_header_line     IN  VARCHAR2
            ,p_list_header_id  IN   NUMBER
      )
      RETURN NUMBER;



      PROCEDURE main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2,
            p_validate_and_load     IN  VARCHAR2
        );

	PROCEDURE submit_main (
            errbuf OUT VARCHAR2,
            retcode OUT VARCHAR2,
            p_batch_id IN VARCHAR2,
            p_restart_flag IN VARCHAR2,
            p_override_flag IN VARCHAR2,
            p_validate_and_load     IN  VARCHAR2
        );
-- Constants defined for version control of all the files of the components
        CN_XXQPPRICELISTCNVVL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXQPPRICELISTCNVVL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXQPPRICELISTCNVTL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXQPPRICELISTCNVTL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';


END xx_qp_price_list_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_QP_PRICE_LIST_CNV_PKG TO INTG_XX_NONHR_RO;
