DROP VIEW APPS.XX_BI_M2C_CRM_V;

/* Formatted on 6/6/2016 4:59:31 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_CRM_V
(
   RESOURCE_NAME,
   RESOURCE_NUMBER,
   RESOURCE_CATEGORY,
   RESOURCE_START_DATE,
   RESOURCE_END_DATE,
   SALES_PERSON_NUMBER,
   OPERATING_UNIT,
   SALES_PERSON_START_DATE,
   SALES_PERSON_END_DATE,
   EMAIL_ADDRESS,
   FRIEGHT_ACCOUNT,
   REVENUE_ACCOUNT,
   RECEVABLE_ACCOUNT,
   ROLE_TYPE,
   ROLE_NAME,
   ROLE_START_DATE,
   ROLE_END_DATE,
   GROUP_NAME,
   GROUP_MEMBER_ROLE,
   GROUP_START_DATE,
   GROUP_END_DATE,
   TEAM_NAME,
   TEAM_MEMBER_ROLE,
   TEAM_START_DATE,
   TEAM_END_DATE
)
AS
   SELECT JRV.RESOURCE_NAME,
          JRV.RESOURCE_NUMBER,
          JRV.RESOURCE_TYPE,
          JRV.START_DATE_ACTIVE,
          JRV.END_DATE_ACTIVE,
          JRS.SALESREP_NUMBER,
          HOU.name,
          JRS.START_DATE_ACTIVE,
          JRS.END_DATE_ACTIVE,
          JRV.EMAIL,
          JRS.GL_ID_FREIGHT,
          JRS.GL_ID_REV,
          JRS.GL_ID_REC,
          JRD.ROLE_TYPE_CODE,
          JRD.ROLE_TYPE_NAME,
          JRD.RES_RL_START_DATE,
          JRD.RES_RL_END_DATE,
          JFG.GROUP_NAME,
          JRG.ROLE_NAME,
          JRG.START_DATE_ACTIVE,
          JRG.END_DATE_ACTIVE,
          JRT.TEAM_NAME,
          JRD.ROLE_NAME,
          JRT.TEAM_START_DATE,
          JRT.TEAM_END_DATE
     FROM JTF_RS_RESOURCES_VL JRV,
          JTF_RS_SALESREPS JRS,
          hr_operating_units HOU,
          JTF_RS_DEFRESROLES_VL JRD,
          JTF_FM_GROUPS_ALL JFG,
          JTF_RS_GROUP_MBR_ROLE_VL JRG,
          JTF_RS_DEFRESTEAMS_VL JRT
    WHERE     JRV.RESOURCE_ID = JRS.RESOURCE_ID
          AND JRV.RESOURCE_NUMBER = JRS.SALESREP_NUMBER
          AND JRV.ORG_ID = HOU.BUSINESS_GROUP_ID
          AND JRV.RESOURCE_ID = JRD.ROLE_RESOURCE_ID
          AND JRV.RESOURCE_ID = JRG.RESOURCE_ID
          AND JFG.GROUP_ID(+) = JRG.GROUP_ID
          AND JRD.ROLE_ID = JRG.ROLE_ID
          AND JRT.TEAM_RESOURCE_ID = JRD.ROLE_RESOURCE_ID
          AND JRT.RESOURCE_TYPE = 'INDIVIDUAL';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_CRM_V FOR APPS.XX_BI_M2C_CRM_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_CRM_V FOR APPS.XX_BI_M2C_CRM_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_CRM_V FOR APPS.XX_BI_M2C_CRM_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_CRM_V FOR APPS.XX_BI_M2C_CRM_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_CRM_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_CRM_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_CRM_V TO XXINTG;
