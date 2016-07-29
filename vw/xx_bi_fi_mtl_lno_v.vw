DROP VIEW APPS.XX_BI_FI_MTL_LNO_V;

/* Formatted on 6/6/2016 4:59:48 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_MTL_LNO_V
(
   INVENTORY_ITEM_ID,
   ORGANIZATION_ID,
   LOT_NUMBER,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   CREATION_DATE,
   CREATED_BY,
   LAST_UPDATE_LOGIN,
   EXPIRATION_DATE,
   DISABLE_FLAG,
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
   REQUEST_ID,
   PROGRAM_APPLICATION_ID,
   PROGRAM_ID,
   PROGRAM_UPDATE_DATE,
   GEN_OBJECT_ID,
   DESCRIPTION,
   VENDOR_NAME,
   SUPPLIER_LOT_NUMBER,
   COUNTRY_OF_ORIGIN,
   GRADE_CODE,
   ORIGINATION_DATE,
   DATE_CODE,
   STATUS_ID,
   CHANGE_DATE,
   AGE,
   RETEST_DATE,
   MATURITY_DATE,
   LOT_ATTRIBUTE_CATEGORY,
   ITEM_SIZE,
   COLOR,
   VOLUME,
   VOLUME_UOM,
   PLACE_OF_ORIGIN,
   KILL_DATE,
   BEST_BY_DATE,
   LENGTH,
   LENGTH_UOM,
   RECYCLED_CONTENT,
   THICKNESS,
   THICKNESS_UOM,
   WIDTH,
   WIDTH_UOM,
   CURL_WRINKLE_FOLD,
   C_ATTRIBUTE1,
   C_ATTRIBUTE2,
   C_ATTRIBUTE3,
   C_ATTRIBUTE4,
   C_ATTRIBUTE5,
   C_ATTRIBUTE6,
   C_ATTRIBUTE7,
   C_ATTRIBUTE8,
   C_ATTRIBUTE9,
   C_ATTRIBUTE10,
   C_ATTRIBUTE11,
   C_ATTRIBUTE12,
   C_ATTRIBUTE13,
   C_ATTRIBUTE14,
   C_ATTRIBUTE15,
   C_ATTRIBUTE16,
   C_ATTRIBUTE17,
   C_ATTRIBUTE18,
   C_ATTRIBUTE19,
   C_ATTRIBUTE20,
   C_ATTRIBUTE21,
   C_ATTRIBUTE22,
   C_ATTRIBUTE23,
   C_ATTRIBUTE24,
   C_ATTRIBUTE25,
   C_ATTRIBUTE26,
   C_ATTRIBUTE27,
   C_ATTRIBUTE28,
   C_ATTRIBUTE29,
   C_ATTRIBUTE30,
   D_ATTRIBUTE1,
   D_ATTRIBUTE2,
   D_ATTRIBUTE3,
   D_ATTRIBUTE4,
   D_ATTRIBUTE5,
   D_ATTRIBUTE6,
   D_ATTRIBUTE7,
   D_ATTRIBUTE8,
   D_ATTRIBUTE9,
   D_ATTRIBUTE10,
   D_ATTRIBUTE11,
   D_ATTRIBUTE12,
   D_ATTRIBUTE13,
   D_ATTRIBUTE14,
   D_ATTRIBUTE15,
   D_ATTRIBUTE16,
   D_ATTRIBUTE17,
   D_ATTRIBUTE18,
   D_ATTRIBUTE19,
   D_ATTRIBUTE20,
   N_ATTRIBUTE1,
   N_ATTRIBUTE2,
   N_ATTRIBUTE3,
   N_ATTRIBUTE4,
   N_ATTRIBUTE5,
   N_ATTRIBUTE6,
   N_ATTRIBUTE7,
   N_ATTRIBUTE8,
   N_ATTRIBUTE9,
   N_ATTRIBUTE10,
   N_ATTRIBUTE11,
   N_ATTRIBUTE12,
   N_ATTRIBUTE13,
   N_ATTRIBUTE14,
   N_ATTRIBUTE15,
   N_ATTRIBUTE16,
   N_ATTRIBUTE17,
   N_ATTRIBUTE18,
   N_ATTRIBUTE19,
   N_ATTRIBUTE20,
   N_ATTRIBUTE21,
   N_ATTRIBUTE22,
   N_ATTRIBUTE23,
   N_ATTRIBUTE24,
   N_ATTRIBUTE25,
   N_ATTRIBUTE26,
   N_ATTRIBUTE27,
   N_ATTRIBUTE28,
   N_ATTRIBUTE29,
   N_ATTRIBUTE30,
   VENDOR_ID,
   TERRITORY_CODE,
   LAST_UPDATE_DATE_YEAR,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_DAY,
   CREATION_DATE_YEAR,
   CREATION_DATE_QUARTER,
   CREATION_DATE_MONTH,
   CREATION_DATE_DAY,
   EXPIRATION_DATE_YEAR,
   EXPIRATION_DATE_QUARTER,
   EXPIRATION_DATE_MONTH,
   EXPIRATION_DATE_DAY,
   PROGRAM_UPDATE_DATE_YEAR,
   PROGRAM_UPDATE_DATE_QUARTER,
   PROGRAM_UPDATE_DATE_MONTH,
   PROGRAM_UPDATE_DATE_DAY,
   ORIGINATION_DATE_YEAR,
   ORIGINATION_DATE_QUARTER,
   ORIGINATION_DATE_MONTH,
   ORIGINATION_DATE_DAY,
   CHANGE_DATE_YEAR,
   CHANGE_DATE_QUARTER,
   CHANGE_DATE_MONTH,
   CHANGE_DATE_DAY,
   RETEST_DATE_YEAR,
   RETEST_DATE_QUARTER,
   RETEST_DATE_MONTH,
   RETEST_DATE_DAY,
   MATURITY_DATE_YEAR,
   MATURITY_DATE_QUARTER,
   MATURITY_DATE_MONTH,
   MATURITY_DATE_DAY,
   KILL_DATE_YEAR,
   KILL_DATE_QUARTER,
   KILL_DATE_MONTH,
   KILL_DATE_DAY,
   BEST_BY_DATE_YEAR,
   BEST_BY_DATE_QUARTER,
   BEST_BY_DATE_MONTH,
   BEST_BY_DATE_DAY,
   D_ATTRIBUTE1_YEAR,
   D_ATTRIBUTE1_QUARTER,
   D_ATTRIBUTE1_MONTH,
   D_ATTRIBUTE1_DAY,
   D_ATTRIBUTE2_YEAR,
   D_ATTRIBUTE2_QUARTER,
   D_ATTRIBUTE2_MONTH,
   D_ATTRIBUTE2_DAY,
   D_ATTRIBUTE3_YEAR,
   D_ATTRIBUTE3_QUARTER,
   D_ATTRIBUTE3_MONTH,
   D_ATTRIBUTE3_DAY,
   D_ATTRIBUTE4_YEAR,
   D_ATTRIBUTE4_QUARTER,
   D_ATTRIBUTE4_MONTH,
   D_ATTRIBUTE4_DAY,
   D_ATTRIBUTE5_YEAR,
   D_ATTRIBUTE5_QUARTER,
   D_ATTRIBUTE5_MONTH,
   D_ATTRIBUTE5_DAY,
   D_ATTRIBUTE6_YEAR,
   D_ATTRIBUTE6_QUARTER,
   D_ATTRIBUTE6_MONTH,
   D_ATTRIBUTE6_DAY,
   D_ATTRIBUTE7_YEAR,
   D_ATTRIBUTE7_QUARTER,
   D_ATTRIBUTE7_MONTH,
   D_ATTRIBUTE7_DAY,
   D_ATTRIBUTE8_YEAR,
   D_ATTRIBUTE8_QUARTER,
   D_ATTRIBUTE8_MONTH,
   D_ATTRIBUTE8_DAY,
   D_ATTRIBUTE9_YEAR,
   D_ATTRIBUTE9_QUARTER,
   D_ATTRIBUTE9_MONTH,
   D_ATTRIBUTE9_DAY,
   D_ATTRIBUTE10_YEAR,
   D_ATTRIBUTE10_QUARTER,
   D_ATTRIBUTE10_MONTH,
   D_ATTRIBUTE10_DAY,
   D_ATTRIBUTE11_YEAR,
   D_ATTRIBUTE11_QUARTER,
   D_ATTRIBUTE11_MONTH,
   D_ATTRIBUTE11_DAY,
   D_ATTRIBUTE12_YEAR,
   D_ATTRIBUTE12_QUARTER,
   D_ATTRIBUTE12_MONTH,
   D_ATTRIBUTE12_DAY,
   D_ATTRIBUTE13_YEAR,
   D_ATTRIBUTE13_QUARTER,
   D_ATTRIBUTE13_MONTH,
   D_ATTRIBUTE13_DAY,
   D_ATTRIBUTE14_YEAR,
   D_ATTRIBUTE14_QUARTER,
   D_ATTRIBUTE14_MONTH,
   D_ATTRIBUTE14_DAY,
   D_ATTRIBUTE15_YEAR,
   D_ATTRIBUTE15_QUARTER,
   D_ATTRIBUTE15_MONTH,
   D_ATTRIBUTE15_DAY,
   D_ATTRIBUTE16_YEAR,
   D_ATTRIBUTE16_QUARTER,
   D_ATTRIBUTE16_MONTH,
   D_ATTRIBUTE16_DAY,
   D_ATTRIBUTE17_YEAR,
   D_ATTRIBUTE17_QUARTER,
   D_ATTRIBUTE17_MONTH,
   D_ATTRIBUTE17_DAY,
   D_ATTRIBUTE18_YEAR,
   D_ATTRIBUTE18_QUARTER,
   D_ATTRIBUTE18_MONTH,
   D_ATTRIBUTE18_DAY,
   D_ATTRIBUTE19_YEAR,
   D_ATTRIBUTE19_QUARTER,
   D_ATTRIBUTE19_MONTH,
   D_ATTRIBUTE19_DAY,
   D_ATTRIBUTE20_YEAR,
   D_ATTRIBUTE20_QUARTER,
   D_ATTRIBUTE20_MONTH,
   D_ATTRIBUTE20_DAY
)
AS
   SELECT inventory_item_id,
          organization_id,
          lot_number,
          last_update_date,
          last_updated_by,
          creation_date,
          created_by,
          last_update_login,
          expiration_date,
          disable_flag,
          attribute_category,
          attribute1,
          attribute2,
          attribute3,
          attribute4,
          attribute5,
          attribute6,
          attribute7,
          attribute8,
          attribute9,
          attribute10,
          attribute11,
          attribute12,
          attribute13,
          attribute14,
          attribute15,
          request_id,
          program_application_id,
          program_id,
          program_update_date,
          gen_object_id,
          description,
          vendor_name,
          supplier_lot_number,
          country_of_origin,
          grade_code,
          origination_date,
          date_code,
          status_id,
          change_date,
          age,
          retest_date,
          maturity_date,
          lot_attribute_category,
          item_size,
          color,
          volume,
          volume_uom,
          place_of_origin,
          kill_date,
          best_by_date,
          LENGTH,
          length_uom,
          recycled_content,
          thickness,
          thickness_uom,
          width,
          width_uom,
          curl_wrinkle_fold,
          c_attribute1,
          c_attribute2,
          c_attribute3,
          c_attribute4,
          c_attribute5,
          c_attribute6,
          c_attribute7,
          c_attribute8,
          c_attribute9,
          c_attribute10,
          c_attribute11,
          c_attribute12,
          c_attribute13,
          c_attribute14,
          c_attribute15,
          c_attribute16,
          c_attribute17,
          c_attribute18,
          c_attribute19,
          c_attribute20,
          c_attribute21,
          c_attribute22,
          c_attribute23,
          c_attribute24,
          c_attribute25,
          c_attribute26,
          c_attribute27,
          c_attribute28,
          c_attribute29,
          c_attribute30,
          d_attribute1,
          d_attribute2,
          d_attribute3,
          d_attribute4,
          d_attribute5,
          d_attribute6,
          d_attribute7,
          d_attribute8,
          d_attribute9,
          d_attribute10,
          d_attribute11,
          d_attribute12,
          d_attribute13,
          d_attribute14,
          d_attribute15,
          d_attribute16,
          d_attribute17,
          d_attribute18,
          d_attribute19,
          d_attribute20,
          n_attribute1,
          n_attribute2,
          n_attribute3,
          n_attribute4,
          n_attribute5,
          n_attribute6,
          n_attribute7,
          n_attribute8,
          n_attribute9,
          n_attribute10,
          n_attribute11,
          n_attribute12,
          n_attribute13,
          n_attribute14,
          n_attribute15,
          n_attribute16,
          n_attribute17,
          n_attribute18,
          n_attribute19,
          n_attribute20,
          n_attribute21,
          n_attribute22,
          n_attribute23,
          n_attribute24,
          n_attribute25,
          n_attribute26,
          n_attribute27,
          n_attribute28,
          n_attribute29,
          n_attribute30,
          vendor_id,
          territory_code,
          (DECODE (
              LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (CREATION_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (CREATION_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (EXPIRATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             EXPIRATION_DATE_YEAR,
          (DECODE (
              EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (EXPIRATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             EXPIRATION_DATE_QUARTER,
          (DECODE (
              EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (EXPIRATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             EXPIRATION_DATE_MONTH,
          (DECODE (
              EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (EXPIRATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             EXPIRATION_DATE_DAY,
          (DECODE (
              PROGRAM_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (PROGRAM_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             PROGRAM_UPDATE_DATE_YEAR,
          (DECODE (
              PROGRAM_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (PROGRAM_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             PROGRAM_UPDATE_DATE_QUARTER,
          (DECODE (
              PROGRAM_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (PROGRAM_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             PROGRAM_UPDATE_DATE_MONTH,
          (DECODE (
              PROGRAM_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (PROGRAM_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             PROGRAM_UPDATE_DATE_DAY,
          (DECODE (
              ORIGINATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (ORIGINATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             ORIGINATION_DATE_YEAR,
          (DECODE (
              ORIGINATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (ORIGINATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             ORIGINATION_DATE_QUARTER,
          (DECODE (
              ORIGINATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (ORIGINATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             ORIGINATION_DATE_MONTH,
          (DECODE (
              ORIGINATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (ORIGINATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             ORIGINATION_DATE_DAY,
          (DECODE (
              CHANGE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (CHANGE_DATE, 'YYYY'), 'YYYY') || '01',
                       'YYYYMM')))
             CHANGE_DATE_YEAR,
          (DECODE (
              CHANGE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (CHANGE_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             CHANGE_DATE_QUARTER,
          (DECODE (
              CHANGE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (CHANGE_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             CHANGE_DATE_MONTH,
          (DECODE (
              CHANGE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (CHANGE_DATE, 'DD'), 'DD') || '190001',
                       'DDYYYYMM')))
             CHANGE_DATE_DAY,
          (DECODE (
              RETEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (RETEST_DATE, 'YYYY'), 'YYYY') || '01',
                       'YYYYMM')))
             RETEST_DATE_YEAR,
          (DECODE (
              RETEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (RETEST_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             RETEST_DATE_QUARTER,
          (DECODE (
              RETEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (RETEST_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             RETEST_DATE_MONTH,
          (DECODE (
              RETEST_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (RETEST_DATE, 'DD'), 'DD') || '190001',
                       'DDYYYYMM')))
             RETEST_DATE_DAY,
          (DECODE (
              MATURITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MATURITY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             MATURITY_DATE_YEAR,
          (DECODE (
              MATURITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (MATURITY_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             MATURITY_DATE_QUARTER,
          (DECODE (
              MATURITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (MATURITY_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             MATURITY_DATE_MONTH,
          (DECODE (
              MATURITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MATURITY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             MATURITY_DATE_DAY,
          (DECODE (
              KILL_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (KILL_DATE, 'YYYY'), 'YYYY') || '01',
                       'YYYYMM')))
             KILL_DATE_YEAR,
          (DECODE (
              KILL_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (KILL_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             KILL_DATE_QUARTER,
          (DECODE (
              KILL_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (KILL_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             KILL_DATE_MONTH,
          (DECODE (
              KILL_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (KILL_DATE, 'DD'), 'DD') || '190001',
                       'DDYYYYMM')))
             KILL_DATE_DAY,
          (DECODE (
              BEST_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BEST_BY_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             BEST_BY_DATE_YEAR,
          (DECODE (
              BEST_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (BEST_BY_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             BEST_BY_DATE_QUARTER,
          (DECODE (
              BEST_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (BEST_BY_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             BEST_BY_DATE_MONTH,
          (DECODE (
              BEST_BY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BEST_BY_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             BEST_BY_DATE_DAY,
          (DECODE (
              D_ATTRIBUTE1,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE1, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE1_YEAR,
          (DECODE (
              D_ATTRIBUTE1,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE1, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE1_QUARTER,
          (DECODE (
              D_ATTRIBUTE1,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE1, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE1_MONTH,
          (DECODE (
              D_ATTRIBUTE1,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE1, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE1_DAY,
          (DECODE (
              D_ATTRIBUTE2,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE2, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE2_YEAR,
          (DECODE (
              D_ATTRIBUTE2,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE2, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE2_QUARTER,
          (DECODE (
              D_ATTRIBUTE2,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE2, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE2_MONTH,
          (DECODE (
              D_ATTRIBUTE2,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE2, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE2_DAY,
          (DECODE (
              D_ATTRIBUTE3,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE3, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE3_YEAR,
          (DECODE (
              D_ATTRIBUTE3,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE3, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE3_QUARTER,
          (DECODE (
              D_ATTRIBUTE3,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE3, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE3_MONTH,
          (DECODE (
              D_ATTRIBUTE3,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE3, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE3_DAY,
          (DECODE (
              D_ATTRIBUTE4,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE4, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE4_YEAR,
          (DECODE (
              D_ATTRIBUTE4,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE4, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE4_QUARTER,
          (DECODE (
              D_ATTRIBUTE4,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE4, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE4_MONTH,
          (DECODE (
              D_ATTRIBUTE4,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE4, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE4_DAY,
          (DECODE (
              D_ATTRIBUTE5,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE5, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE5_YEAR,
          (DECODE (
              D_ATTRIBUTE5,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE5, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE5_QUARTER,
          (DECODE (
              D_ATTRIBUTE5,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE5, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE5_MONTH,
          (DECODE (
              D_ATTRIBUTE5,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE5, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE5_DAY,
          (DECODE (
              D_ATTRIBUTE6,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE6, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE6_YEAR,
          (DECODE (
              D_ATTRIBUTE6,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE6, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE6_QUARTER,
          (DECODE (
              D_ATTRIBUTE6,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE6, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE6_MONTH,
          (DECODE (
              D_ATTRIBUTE6,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE6, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE6_DAY,
          (DECODE (
              D_ATTRIBUTE7,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE7, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE7_YEAR,
          (DECODE (
              D_ATTRIBUTE7,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE7, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE7_QUARTER,
          (DECODE (
              D_ATTRIBUTE7,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE7, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE7_MONTH,
          (DECODE (
              D_ATTRIBUTE7,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE7, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE7_DAY,
          (DECODE (
              D_ATTRIBUTE8,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE8, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE8_YEAR,
          (DECODE (
              D_ATTRIBUTE8,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE8, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE8_QUARTER,
          (DECODE (
              D_ATTRIBUTE8,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE8, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE8_MONTH,
          (DECODE (
              D_ATTRIBUTE8,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE8, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE8_DAY,
          (DECODE (
              D_ATTRIBUTE9,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE9, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE9_YEAR,
          (DECODE (
              D_ATTRIBUTE9,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE9, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE9_QUARTER,
          (DECODE (
              D_ATTRIBUTE9,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE9, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE9_MONTH,
          (DECODE (
              D_ATTRIBUTE9,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE9, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE9_DAY,
          (DECODE (
              D_ATTRIBUTE10,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE10, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE10_YEAR,
          (DECODE (
              D_ATTRIBUTE10,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE10, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE10_QUARTER,
          (DECODE (
              D_ATTRIBUTE10,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE10, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE10_MONTH,
          (DECODE (
              D_ATTRIBUTE10,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE10, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE10_DAY,
          (DECODE (
              D_ATTRIBUTE11,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE11, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE11_YEAR,
          (DECODE (
              D_ATTRIBUTE11,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE11, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE11_QUARTER,
          (DECODE (
              D_ATTRIBUTE11,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE11, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE11_MONTH,
          (DECODE (
              D_ATTRIBUTE11,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE11, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE11_DAY,
          (DECODE (
              D_ATTRIBUTE12,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE12, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE12_YEAR,
          (DECODE (
              D_ATTRIBUTE12,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE12, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE12_QUARTER,
          (DECODE (
              D_ATTRIBUTE12,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE12, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE12_MONTH,
          (DECODE (
              D_ATTRIBUTE12,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE12, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE12_DAY,
          (DECODE (
              D_ATTRIBUTE13,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE13, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE13_YEAR,
          (DECODE (
              D_ATTRIBUTE13,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE13, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE13_QUARTER,
          (DECODE (
              D_ATTRIBUTE13,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE13, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE13_MONTH,
          (DECODE (
              D_ATTRIBUTE13,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE13, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE13_DAY,
          (DECODE (
              D_ATTRIBUTE14,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE14, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE14_YEAR,
          (DECODE (
              D_ATTRIBUTE14,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE14, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE14_QUARTER,
          (DECODE (
              D_ATTRIBUTE14,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE14, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE14_MONTH,
          (DECODE (
              D_ATTRIBUTE14,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE14, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE14_DAY,
          (DECODE (
              D_ATTRIBUTE15,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE15, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE15_YEAR,
          (DECODE (
              D_ATTRIBUTE15,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE15, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE15_QUARTER,
          (DECODE (
              D_ATTRIBUTE15,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE15, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE15_MONTH,
          (DECODE (
              D_ATTRIBUTE15,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE15, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE15_DAY,
          (DECODE (
              D_ATTRIBUTE16,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE16, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE16_YEAR,
          (DECODE (
              D_ATTRIBUTE16,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE16, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE16_QUARTER,
          (DECODE (
              D_ATTRIBUTE16,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE16, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE16_MONTH,
          (DECODE (
              D_ATTRIBUTE16,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE16, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE16_DAY,
          (DECODE (
              D_ATTRIBUTE17,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE17, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE17_YEAR,
          (DECODE (
              D_ATTRIBUTE17,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE17, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE17_QUARTER,
          (DECODE (
              D_ATTRIBUTE17,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE17, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE17_MONTH,
          (DECODE (
              D_ATTRIBUTE17,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE17, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE17_DAY,
          (DECODE (
              D_ATTRIBUTE18,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE18, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE18_YEAR,
          (DECODE (
              D_ATTRIBUTE18,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE18, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE18_QUARTER,
          (DECODE (
              D_ATTRIBUTE18,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE18, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE18_MONTH,
          (DECODE (
              D_ATTRIBUTE18,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE18, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE18_DAY,
          (DECODE (
              D_ATTRIBUTE19,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE19, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE19_YEAR,
          (DECODE (
              D_ATTRIBUTE19,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE19, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE19_QUARTER,
          (DECODE (
              D_ATTRIBUTE19,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE19, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE19_MONTH,
          (DECODE (
              D_ATTRIBUTE19,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE19, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE19_DAY,
          (DECODE (
              D_ATTRIBUTE20,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE20, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             D_ATTRIBUTE20_YEAR,
          (DECODE (
              D_ATTRIBUTE20,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE20, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE20_QUARTER,
          (DECODE (
              D_ATTRIBUTE20,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (D_ATTRIBUTE20, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             D_ATTRIBUTE20_MONTH,
          (DECODE (
              D_ATTRIBUTE20,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (D_ATTRIBUTE20, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             D_ATTRIBUTE20_DAY
     FROM mtl_lot_numbers;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_MTL_LNO_V FOR APPS.XX_BI_FI_MTL_LNO_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_MTL_LNO_V FOR APPS.XX_BI_FI_MTL_LNO_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_MTL_LNO_V FOR APPS.XX_BI_FI_MTL_LNO_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_MTL_LNO_V FOR APPS.XX_BI_FI_MTL_LNO_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_MTL_LNO_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_MTL_LNO_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_MTL_LNO_V TO XXINTG;
