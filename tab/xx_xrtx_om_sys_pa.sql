DROP TABLE APPS.XX_XRTX_OM_SYS_PA CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XRTX_OM_SYS_PA
(
  ORG_NAME                        VARCHAR2(200 BYTE),
  RECURRING_CHARGES               VARCHAR2(100 BYTE),
  OE_INVENTORY_ITEM_FOR_FREIGHT   VARCHAR2(100 BYTE),
  OE_INVOICE_FREIGHT_AS_LINE      VARCHAR2(100 BYTE),
  OE_INVOICE_TRANSACTION_TYPE_ID  VARCHAR2(100 BYTE),
  OE_CREDIT_TRANSACTION_TYPE_ID   VARCHAR2(100 BYTE),
  OE_NON_DELIVERY_INVOICE_SOURCE  VARCHAR2(100 BYTE),
  INSTALLMENT_OPTIONS             VARCHAR2(100 BYTE),
  OE_INVOICE_SOURCE               VARCHAR2(100 BYTE),
  OE_OVERSHIP_INVOICE_BASIS       VARCHAR2(100 BYTE),
  OE_DISCOUNT_DETAILS_ON_INVOICE  VARCHAR2(100 BYTE),
  ONT_RESERVATION_TIME_FENCE      VARCHAR2(100 BYTE),
  ONT_SCHEDULE_LINE_ON_HOLD       VARCHAR2(100 BYTE),
  WSH_CR_SREP_FOR_FREIGHT         VARCHAR2(100 BYTE),
  ONT_GSA_VIOLATION_ACTION        VARCHAR2(100 BYTE),
  ONT_EMP_ID_FOR_SS_ORDERS        VARCHAR2(100 BYTE),
  ENABLE_FULFILLMENT_ACCEPTANCE   VARCHAR2(100 BYTE),
  MASTER_ORGANIZATION             VARCHAR2(100 BYTE),
  AUDIT_TRAIL_ENABLE_FLAG         VARCHAR2(100 BYTE),
  CUSTOMER_RELATIONSHIPS_FLAG     VARCHAR2(100 BYTE),
  COMPUTE_MARGIN                  VARCHAR2(100 BYTE),
  FREIGHT_RATING_ENABLED_FLAG     VARCHAR2(100 BYTE),
  FTE_SHIP_METHOD_ENABLED_FLAG    VARCHAR2(100 BYTE),
  LATEST_ACCEPTABLE_DATE_FLAG     VARCHAR2(100 BYTE),
  RESCHEDULE_REQUEST_DATE_FLAG    VARCHAR2(100 BYTE),
  ONT_PRC_AVA_DEFAULT_HINT        VARCHAR2(100 BYTE),
  RESCHEDULE_SHIP_METHOD_FLAG     VARCHAR2(100 BYTE),
  PROMISE_DATE_FLAG               VARCHAR2(100 BYTE),
  PARTIAL_RESERVATION_FLAG        VARCHAR2(100 BYTE),
  FIRM_DEMAND_EVENTS              VARCHAR2(100 BYTE),
  MULTIPLE_PAYMENTS               VARCHAR2(100 BYTE),
  ACCOUNT_FIRST_INSTALLMENT_ONLY  VARCHAR2(100 BYTE),
  ONT_CONFIG_EFFECTIVITY_DATE     VARCHAR2(100 BYTE),
  RETROBILL_REASONS               VARCHAR2(100 BYTE),
  RETROBILL_DEFAULT_ORDER_TYPE    VARCHAR2(100 BYTE),
  ENABLE_RETROBILLING             VARCHAR2(100 BYTE),
  NO_RESPONSE_FROM_APPROVER       VARCHAR2(100 BYTE),
  COPY_LINE_DFF_EXT_API           VARCHAR2(100 BYTE),
  COPY_COMPLETE_CONFIG            VARCHAR2(100 BYTE),
  TRX_DATE_FOR_INV_IFACE          VARCHAR2(100 BYTE),
  CREDIT_HOLD_ZERO_VALUE_ORDER    VARCHAR2(100 BYTE),
  ONT_CASCADE_HOLD_NONSMC_PTO     VARCHAR2(100 BYTE),
  OE_ADDR_VALID_OIMP              VARCHAR2(100 BYTE),
  OE_HOLD_LINE_SEQUENCE           VARCHAR2(100 BYTE),
  OE_CC_CANCEL_PARAM              VARCHAR2(100 BYTE),
  ONT_AUTO_SCH_SETS               VARCHAR2(100 BYTE),
  CUST_RELATIONSHIPS_FLAG_SVC     VARCHAR2(100 BYTE)
)
TABLESPACE APPS_TS_TX_DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;
