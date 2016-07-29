DROP PACKAGE APPS.XXINTG_COST_UPDATE;

CREATE OR REPLACE PACKAGE APPS."XXINTG_COST_UPDATE" AUTHID CURRENT_USER AS

PROCEDURE xxintg_cost_import_update (
   errbuf    OUT VARCHAR2,
   retcode   OUT VARCHAR2,
    p_batch_id            IN              VARCHAR2,
   p_organization_code IN VARCHAR2,
   p_cost_type IN VARCHAR2
  );

   end xxintg_cost_update;
/
