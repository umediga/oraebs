DROP VIEW APPS.XXINTG_OM_HDR_ADD_INFO_KFV;

/* Formatted on 6/6/2016 5:00:16 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_OM_HDR_ADD_INFO_KFV
(
   ROW_ID,
   CODE_COMBINATION_ID,
   STRUCTURE_ID,
   CONCATENATED_SEGMENTS,
   PADDED_CONCATENATED_SEGMENTS,
   SEGMENT_ATTRIBUTE38,
   SEGMENT_ATTRIBUTE39,
   SEGMENT_ATTRIBUTE40,
   SEGMENT_ATTRIBUTE41,
   SEGMENT_ATTRIBUTE42,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   ENABLED_FLAG,
   SUMMARY_FLAG,
   SEGMENT1,
   SEGMENT2,
   SEGMENT3,
   SEGMENT4,
   SEGMENT5,
   SEGMENT6,
   SEGMENT7,
   SEGMENT8,
   SEGMENT9,
   SEGMENT10,
   SEGMENT11,
   SEGMENT12,
   SEGMENT13,
   SEGMENT14,
   SEGMENT15,
   SEGMENT16,
   SEGMENT17,
   SEGMENT18,
   SEGMENT19,
   SEGMENT20,
   SEGMENT21,
   SEGMENT22,
   SEGMENT23,
   SEGMENT24,
   SEGMENT25,
   SEGMENT26,
   SEGMENT27,
   SEGMENT28,
   SEGMENT29,
   SEGMENT30,
   DESCRIPTION,
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
   SEGMENT_ATTRIBUTE37
)
AS
   SELECT ROWID,
          CODE_COMBINATION_ID,
          STRUCTURE_ID,
          (DECODE (
              STRUCTURE_ID,
              50449,    SEGMENT1
                     || '|'
                     || SEGMENT2
                     || '|'
                     || SEGMENT3
                     || '|'
                     || SEGMENT4
                     || '|'
                     || SEGMENT11
                     || '|'
                     || SEGMENT12
                     || '|'
                     || SEGMENT13
                     || '|'
                     || SEGMENT14
                     || '|'
                     || SEGMENT15
                     || '|'
                     || SEGMENT16
                     || '|'
                     || SEGMENT17
                     || '|'
                     || SEGMENT18
                     || '|'
                     || SEGMENT19
                     || '|'
                     || SEGMENT20
                     || '|'
                     || SEGMENT30,
              50450,    SEGMENT2
                     || '|'
                     || SEGMENT11
                     || '|'
                     || SEGMENT20
                     || '|'
                     || SEGMENT30
                     || '|'
                     || SEGMENT21,
              NULL)),
          (DECODE (
              STRUCTURE_ID,
              50449,    RPAD (NVL (SEGMENT1, ' '), 20)
                     || '|'
                     || LPAD (NVL (SEGMENT2, ' '), 2)
                     || '|'
                     || LPAD (NVL (SEGMENT3, ' '), 2)
                     || '|'
                     || LPAD (NVL (SEGMENT4, ' '), 2)
                     || '|'
                     || RPAD (NVL (SEGMENT11, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT12, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT13, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT14, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT15, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT16, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT17, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT18, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT19, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT20, ' '), 240)
                     || '|'
                     || RPAD (NVL (SEGMENT30, ' '), 240),
              50450,    RPAD (NVL (SEGMENT2, ' '), 240)
                     || '|'
                     || RPAD (NVL (SEGMENT11, ' '), 25)
                     || '|'
                     || RPAD (NVL (SEGMENT20, ' '), 240)
                     || '|'
                     || RPAD (NVL (SEGMENT30, ' '), 240)
                     || '|'
                     || RPAD (NVL (SEGMENT21, ' '), 240),
              NULL)),
          SEGMENT_ATTRIBUTE38,
          SEGMENT_ATTRIBUTE39,
          SEGMENT_ATTRIBUTE40,
          SEGMENT_ATTRIBUTE41,
          SEGMENT_ATTRIBUTE42,
          LAST_UPDATE_DATE,
          LAST_UPDATED_BY,
          ENABLED_FLAG,
          SUMMARY_FLAG,
          SEGMENT1,
          SEGMENT2,
          SEGMENT3,
          SEGMENT4,
          SEGMENT5,
          SEGMENT6,
          SEGMENT7,
          SEGMENT8,
          SEGMENT9,
          SEGMENT10,
          SEGMENT11,
          SEGMENT12,
          SEGMENT13,
          SEGMENT14,
          SEGMENT15,
          SEGMENT16,
          SEGMENT17,
          SEGMENT18,
          SEGMENT19,
          SEGMENT20,
          SEGMENT21,
          SEGMENT22,
          SEGMENT23,
          SEGMENT24,
          SEGMENT25,
          SEGMENT26,
          SEGMENT27,
          SEGMENT28,
          SEGMENT29,
          SEGMENT30,
          DESCRIPTION,
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
          SEGMENT_ATTRIBUTE37
     FROM XXINTG_OM_HDR_ADD_INFO;
