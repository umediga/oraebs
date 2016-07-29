DROP TABLE APPS.XX_XTRX_CUS_ALERTS_MASTER_T CASCADE CONSTRAINTS;

CREATE TABLE APPS.XX_XTRX_CUS_ALERTS_MASTER_T
(
  APPLICATION_NAME        VARCHAR2(240 BYTE)    NOT NULL,
  ALERT_ID                NUMBER                NOT NULL,
  ALERT_NAME              VARCHAR2(50 BYTE)     NOT NULL,
  DESCRIPTION             VARCHAR2(240 BYTE),
  ALERT_CONDITION_TYPE    VARCHAR2(80 BYTE),
  ENABLED_FLAG            VARCHAR2(1 BYTE)      NOT NULL,
  FREQUENCY_TYPE          VARCHAR2(80 BYTE),
  WEEKLY_CHECK_DAY        VARCHAR2(3 BYTE),
  LAST_UPDATE_DATE        DATE                  NOT NULL,
  LAST_UPDATED_BY         NUMBER                NOT NULL,
  CREATION_DATE           DATE                  NOT NULL,
  MONTHLY_CHECK_DAY_NUM   NUMBER,
  DAYS_BETWEEN_CHECKS     NUMBER,
  CHECK_BEGIN_DATE        DATE,
  DATE_LAST_CHECKED       DATE,
  INSERT_FLAG             VARCHAR2(1 BYTE),
  UPDATE_FLAG             VARCHAR2(1 BYTE),
  DELETE_FLAG             VARCHAR2(1 BYTE),
  MAINTAIN_HISTORY_DAYS   NUMBER,
  CHECK_TIME              NUMBER,
  CHECK_START_TIME        NUMBER,
  CHECK_END_TIME          NUMBER,
  SECONDS_BETWEEN_CHECKS  NUMBER,
  CHECK_ONCE_DAILY_FLAG   VARCHAR2(1 BYTE)
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