DROP VIEW APPS.XX_EMF_PROCESS_PARAMETERS_V;

/* Formatted on 6/6/2016 4:58:42 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_EMF_PROCESS_PARAMETERS_V
(
   ROW_ID,
   PROCESS_ID,
   PROCESS_NAME,
   PARAMETER_ID,
   PARAM_SEQ,
   PARAMETER_NAME,
   PARAMETER_VALUE,
   ENABLED_FLAG,
   ORG_ID,
   CREATED_BY,
   CREATION_DATE,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN
)
AS
   SELECT pp.ROWID AS row_id,
          pp.process_id,
          ps.process_name,
          pp.parameter_id,
          pp.param_seq,
          pp.parameter_name,
          pp.parameter_value,
          pp.enabled_flag,
          pp.org_id,
          pp.created_by,
          pp.creation_date,
          pp.last_update_date,
          pp.last_updated_by,
          pp.last_update_login
     FROM xx_emf_process_parameters pp, xx_emf_process_setup ps
    WHERE pp.process_id = ps.process_id;


GRANT SELECT ON APPS.XX_EMF_PROCESS_PARAMETERS_V TO INTG_XX_NONHR_RO;
