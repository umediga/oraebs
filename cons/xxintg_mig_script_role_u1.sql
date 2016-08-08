ALTER TABLE APPS.XXINTG_MIG_SCRIPT_ROLE
  DROP CONSTRAINT XXINTG_MIG_SCRIPT_ROLE_U1;

ALTER TABLE APPS.XXINTG_MIG_SCRIPT_ROLE ADD (
  CONSTRAINT XXINTG_MIG_SCRIPT_ROLE_U1
  UNIQUE (ROLE_CODE)
  ENABLE VALIDATE);
