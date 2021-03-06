DROP VIEW APPS.XX_BI_PER_PAY_PROPOSALS;

/* Formatted on 6/6/2016 4:59:04 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_PER_PAY_PROPOSALS
(
   PAY_PROPOSAL_ID,
   OBJECT_VERSION_NUMBER,
   ASSIGNMENT_ID,
   EVENT_ID,
   BUSINESS_GROUP_ID,
   CHANGE_DATE,
   LAST_CHANGE_DATE,
   NEXT_PERF_REVIEW_DATE,
   NEXT_SAL_REVIEW_DATE,
   PERFORMANCE_RATING,
   PROPOSAL_REASON,
   PROPOSED_SALARY_N,
   REVIEW_DATE,
   APPROVED,
   MULTIPLE_COMPONENTS,
   FORCED_RANKING,
   PERFORMANCE_REVIEW_ID,
   ATTRIBUTE_CATEGORY,
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
   ATTRIBUTE11,
   ATTRIBUTE12,
   ATTRIBUTE13,
   ATTRIBUTE14,
   ATTRIBUTE15,
   ATTRIBUTE16,
   ATTRIBUTE17,
   ATTRIBUTE18,
   ATTRIBUTE19,
   ATTRIBUTE20,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN,
   CREATED_BY,
   CREATION_DATE,
   PROPOSED_SALARY,
   COMMENTS,
   DATE_TO
)
AS
   SELECT "PAY_PROPOSAL_ID",
          "OBJECT_VERSION_NUMBER",
          "ASSIGNMENT_ID",
          "EVENT_ID",
          "BUSINESS_GROUP_ID",
          "CHANGE_DATE",
          "LAST_CHANGE_DATE",
          "NEXT_PERF_REVIEW_DATE",
          "NEXT_SAL_REVIEW_DATE",
          "PERFORMANCE_RATING",
          "PROPOSAL_REASON",
          100000 "PROPOSED_SALARY_N",
          "REVIEW_DATE",
          "APPROVED",
          "MULTIPLE_COMPONENTS",
          "FORCED_RANKING",
          "PERFORMANCE_REVIEW_ID",
          "ATTRIBUTE_CATEGORY",
          "ATTRIBUTE1",
          "ATTRIBUTE2",
          "ATTRIBUTE3",
          "ATTRIBUTE4",
          "ATTRIBUTE5",
          "ATTRIBUTE6",
          "ATTRIBUTE7",
          "ATTRIBUTE8",
          "ATTRIBUTE9",
          "ATTRIBUTE10",
          "ATTRIBUTE11",
          "ATTRIBUTE12",
          "ATTRIBUTE13",
          "ATTRIBUTE14",
          "ATTRIBUTE15",
          "ATTRIBUTE16",
          "ATTRIBUTE17",
          "ATTRIBUTE18",
          "ATTRIBUTE19",
          "ATTRIBUTE20",
          "LAST_UPDATE_DATE",
          "LAST_UPDATED_BY",
          "LAST_UPDATE_LOGIN",
          "CREATED_BY",
          "CREATION_DATE",
          "PROPOSED_SALARY",
          "COMMENTS",
          "DATE_TO"
     FROM per_pay_proposals;


CREATE OR REPLACE SYNONYM ETLEBSUSER.PER_PAY_PROPOSALS FOR APPS.XX_BI_PER_PAY_PROPOSALS;


GRANT SELECT ON APPS.XX_BI_PER_PAY_PROPOSALS TO SS_ETL_RO;
