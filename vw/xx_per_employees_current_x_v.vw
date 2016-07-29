DROP VIEW APPS.XX_PER_EMPLOYEES_CURRENT_X_V;

/* Formatted on 6/6/2016 4:58:16 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_PER_EMPLOYEES_CURRENT_X_V
(
   BUSINESS_GROUP_ID,
   ORGANIZATION_ID,
   EMPLOYEE_ID,
   ASSIGNMENT_ID,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN,
   CREATION_DATE,
   CREATED_BY,
   EMPLOYEE_NUM,
   FULL_NAME,
   FIRST_NAME,
   MIDDLE_NAME,
   LAST_NAME,
   PREFIX,
   LOCATION_ID,
   SUPERVISOR_ID,
   SET_OF_BOOKS_ID,
   DEFAULT_CODE_COMBINATION_ID,
   EXPENSE_CHECK_ADDRESS_FLAG,
   INACTIVE_DATE,
   EMAIL_ADDRESS,
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
   ATTRIBUTE21,
   ATTRIBUTE22,
   ATTRIBUTE23,
   ATTRIBUTE24,
   ATTRIBUTE25,
   ATTRIBUTE26,
   ATTRIBUTE27,
   ATTRIBUTE28,
   ATTRIBUTE29,
   ATTRIBUTE30,
   ATTRIBUTE_CATEGORY,
   PARTY_ID,
   GLOBAL_NAME,
   LOCAL_NAME,
   LIST_NAME
)
AS
   SELECT P.BUSINESS_GROUP_ID,
          A.ORGANIZATION_ID,
          P.PERSON_ID,
          A.ASSIGNMENT_ID,
          P.LAST_UPDATE_DATE,
          P.LAST_UPDATED_BY,
          P.LAST_UPDATE_LOGIN,
          P.CREATION_DATE,
          P.CREATED_BY,
          NVL (P.EMPLOYEE_NUMBER, P.NPW_NUMBER),
          P.FULL_NAME,
          P.FIRST_NAME,
          P.MIDDLE_NAMES,
          P.LAST_NAME,
          P.TITLE,
          A.LOCATION_ID,
          A.SUPERVISOR_ID,
          A.SET_OF_BOOKS_ID,
          A.DEFAULT_CODE_COMB_ID,
          P.EXPENSE_CHECK_SEND_TO_ADDRESS,
          NULL,
          P.EMAIL_ADDRESS,
          P.ATTRIBUTE1,
          P.ATTRIBUTE2,
          P.ATTRIBUTE3,
          P.ATTRIBUTE4,
          P.ATTRIBUTE5,
          P.ATTRIBUTE6,
          P.ATTRIBUTE7,
          P.ATTRIBUTE8,
          P.ATTRIBUTE9,
          P.ATTRIBUTE10,
          P.ATTRIBUTE11,
          P.ATTRIBUTE12,
          P.ATTRIBUTE13,
          P.ATTRIBUTE14,
          P.ATTRIBUTE15,
          P.ATTRIBUTE16,
          P.ATTRIBUTE17,
          P.ATTRIBUTE18,
          P.ATTRIBUTE19,
          P.ATTRIBUTE20,
          P.ATTRIBUTE21,
          P.ATTRIBUTE22,
          P.ATTRIBUTE23,
          P.ATTRIBUTE24,
          P.ATTRIBUTE25,
          P.ATTRIBUTE26,
          P.ATTRIBUTE27,
          P.ATTRIBUTE28,
          P.ATTRIBUTE29,
          P.ATTRIBUTE30,
          P.ATTRIBUTE_CATEGORY,
          P.PARTY_ID,
          P.GLOBAL_NAME,
          P.LOCAL_NAME,
          P.LIST_NAME
     FROM PER_PEOPLE_F P, PER_ALL_ASSIGNMENTS_F A
    WHERE     A.PERSON_ID = P.PERSON_ID
          AND A.PRIMARY_FLAG = 'Y'
          AND A.ASSIGNMENT_TYPE = 'C'
          AND TRUNC (SYSDATE) BETWEEN P.EFFECTIVE_START_DATE
                                  AND P.EFFECTIVE_END_DATE
          AND TRUNC (SYSDATE) BETWEEN A.EFFECTIVE_START_DATE
                                  AND A.EFFECTIVE_END_DATE
          AND P.NPW_NUMBER IS NOT NULL;
