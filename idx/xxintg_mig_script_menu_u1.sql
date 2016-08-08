DROP INDEX APPS.XXINTG_MIG_SCRIPT_MENU_U1;

CREATE UNIQUE INDEX APPS.XXINTG_MIG_SCRIPT_MENU_U1 ON APPS.XXINTG_MIG_SCRIPT_MENU
(RESP_CODE, MENU_CODE)
LOGGING
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           );