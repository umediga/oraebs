DROP VIEW APPS.XX_SFDC_SO_REPRO_DATE_V;

/* Formatted on 6/6/2016 4:58:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SFDC_SO_REPRO_DATE_V
(
   LAST_UPDATE_DATE
)
AS
     SELECT DISTINCT TRUNC (creation_date) last_update_date
       FROM ( (SELECT DISTINCT creation_date
                 FROM xx_om_sfdc_head_control_tbl)
             UNION
             (SELECT DISTINCT creation_date
                FROM xx_om_sfdc_line_control_tbl)
             UNION
             (SELECT DISTINCT creation_date
                FROM xx_om_sfdc_del_control_tbl))
   ORDER BY last_update_date DESC;
