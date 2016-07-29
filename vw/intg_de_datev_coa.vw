DROP VIEW APPS.INTG_DE_DATEV_COA;

/* Formatted on 6/6/2016 5:00:35 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.INTG_DE_DATEV_COA
(
   ROW_ID,
   CODE_COMBINATION_ID,
   COMPANY,
   ACCOUNT,
   SUBACCOUNT,
   GL_ACCOUNT_TYPE,
   GL_CONTROL_ACCOUNT,
   RECONCILIATION_FLAG,
   DETAIL_BUDGETING_ALLOWED,
   DETAIL_POSTING_ALLOWED,
   COMPANY_COST_CENTER_ORG_ID,
   ALTERNATE_CODE_COMBINATION_ID,
   REVALUATION_ID,
   IGI_BALANCED_BUDGET_FLAG,
   ENABLED_FLAG,
   SUMMARY_FLAG,
   DESCRIPTION,
   TEMPLATE_ID,
   ALLOCATION_CREATE_FLAG,
   START_DATE_ACTIVE,
   END_DATE_ACTIVE,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE4,
   ATTRIBUTE5,
   ATTRIBUTE6,
   ATTRIBUTE7,
   ATTRIBUTE8,
   ATTRIBUTE9,
   ATTRIBUTE10,
   CONTEXT,
   SEGMENT_ATTRIBUTE1,
   SEGMENT_ATTRIBUTE2,
   SEGMENT_ATTRIBUTE3,
   SEGMENT_ATTRIBUTE4,
   SEGMENT_ATTRIBUTE5,
   SEGMENT_ATTRIBUTE6,
   SEGMENT_ATTRIBUTE7,
   SEGMENT_ATTRIBUTE8,
   SEGMENT_ATTRIBUTE9,
   SEGMENT_ATTRIBUTE10,
   SEGMENT_ATTRIBUTE11,
   SEGMENT_ATTRIBUTE12,
   SEGMENT_ATTRIBUTE13,
   SEGMENT_ATTRIBUTE14,
   SEGMENT_ATTRIBUTE15,
   SEGMENT_ATTRIBUTE16,
   SEGMENT_ATTRIBUTE17,
   SEGMENT_ATTRIBUTE18,
   SEGMENT_ATTRIBUTE19,
   SEGMENT_ATTRIBUTE20,
   SEGMENT_ATTRIBUTE21,
   SEGMENT_ATTRIBUTE22,
   SEGMENT_ATTRIBUTE23,
   SEGMENT_ATTRIBUTE24,
   SEGMENT_ATTRIBUTE25,
   SEGMENT_ATTRIBUTE26,
   SEGMENT_ATTRIBUTE27,
   SEGMENT_ATTRIBUTE28,
   SEGMENT_ATTRIBUTE29,
   SEGMENT_ATTRIBUTE30,
   SEGMENT_ATTRIBUTE31,
   SEGMENT_ATTRIBUTE32,
   SEGMENT_ATTRIBUTE33,
   SEGMENT_ATTRIBUTE34,
   SEGMENT_ATTRIBUTE35,
   SEGMENT_ATTRIBUTE36,
   SEGMENT_ATTRIBUTE37,
   SEGMENT_ATTRIBUTE38,
   SEGMENT_ATTRIBUTE39,
   SEGMENT_ATTRIBUTE40,
   SEGMENT_ATTRIBUTE41,
   SEGMENT_ATTRIBUTE42,
   REFERENCE1,
   REFERENCE2,
   REFERENCE4,
   REFERENCE5,
   JGZZ_RECON_CONTEXT,
   PRESERVE_FLAG,
   REFRESH_FLAG,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY
)
AS
   SELECT ROWID,
          CODE_COMBINATION_ID,
          SEGMENT1,
          SEGMENT2,
          SEGMENT3,
          ACCOUNT_TYPE,
          REFERENCE3,
          JGZZ_RECON_FLAG,
          DETAIL_BUDGETING_ALLOWED_FLAG,
          DETAIL_POSTING_ALLOWED_FLAG,
          COMPANY_COST_CENTER_ORG_ID,
          ALTERNATE_CODE_COMBINATION_ID,
          REVALUATION_ID,
          IGI_BALANCED_BUDGET_FLAG,
          ENABLED_FLAG,
          SUMMARY_FLAG,
          DESCRIPTION,
          TEMPLATE_ID,
          ALLOCATION_CREATE_FLAG,
          START_DATE_ACTIVE,
          END_DATE_ACTIVE,
          ATTRIBUTE1,
          ATTRIBUTE2,
          ATTRIBUTE3,
          ATTRIBUTE4,
          ATTRIBUTE5,
          ATTRIBUTE6,
          ATTRIBUTE7,
          ATTRIBUTE8,
          ATTRIBUTE9,
          ATTRIBUTE10,
          CONTEXT,
          SEGMENT_ATTRIBUTE1,
          SEGMENT_ATTRIBUTE2,
          SEGMENT_ATTRIBUTE3,
          SEGMENT_ATTRIBUTE4,
          SEGMENT_ATTRIBUTE5,
          SEGMENT_ATTRIBUTE6,
          SEGMENT_ATTRIBUTE7,
          SEGMENT_ATTRIBUTE8,
          SEGMENT_ATTRIBUTE9,
          SEGMENT_ATTRIBUTE10,
          SEGMENT_ATTRIBUTE11,
          SEGMENT_ATTRIBUTE12,
          SEGMENT_ATTRIBUTE13,
          SEGMENT_ATTRIBUTE14,
          SEGMENT_ATTRIBUTE15,
          SEGMENT_ATTRIBUTE16,
          SEGMENT_ATTRIBUTE17,
          SEGMENT_ATTRIBUTE18,
          SEGMENT_ATTRIBUTE19,
          SEGMENT_ATTRIBUTE20,
          SEGMENT_ATTRIBUTE21,
          SEGMENT_ATTRIBUTE22,
          SEGMENT_ATTRIBUTE23,
          SEGMENT_ATTRIBUTE24,
          SEGMENT_ATTRIBUTE25,
          SEGMENT_ATTRIBUTE26,
          SEGMENT_ATTRIBUTE27,
          SEGMENT_ATTRIBUTE28,
          SEGMENT_ATTRIBUTE29,
          SEGMENT_ATTRIBUTE30,
          SEGMENT_ATTRIBUTE31,
          SEGMENT_ATTRIBUTE32,
          SEGMENT_ATTRIBUTE33,
          SEGMENT_ATTRIBUTE34,
          SEGMENT_ATTRIBUTE35,
          SEGMENT_ATTRIBUTE36,
          SEGMENT_ATTRIBUTE37,
          SEGMENT_ATTRIBUTE38,
          SEGMENT_ATTRIBUTE39,
          SEGMENT_ATTRIBUTE40,
          SEGMENT_ATTRIBUTE41,
          SEGMENT_ATTRIBUTE42,
          REFERENCE1,
          REFERENCE2,
          REFERENCE4,
          REFERENCE5,
          JGZZ_RECON_CONTEXT,
          PRESERVE_FLAG,
          REFRESH_FLAG,
          LAST_UPDATE_DATE,
          LAST_UPDATED_BY
     FROM GL_CODE_COMBINATIONS
    WHERE CHART_OF_ACCOUNTS_ID = 50358;


CREATE OR REPLACE SYNONYM ETLEBSUSER.INTG_DE_DATEV_COA FOR APPS.INTG_DE_DATEV_COA;


GRANT SELECT ON APPS.INTG_DE_DATEV_COA TO INTG_NONHR_NONXX_RO;

GRANT SELECT ON APPS.INTG_DE_DATEV_COA TO SS_ETL_RO;
