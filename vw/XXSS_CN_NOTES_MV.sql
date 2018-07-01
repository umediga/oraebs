CREATE MATERIALIZED VIEW apps.XXSS_CN_NOTES_MV 
  NOLOGGING
  CACHE
  BUILD IMMEDIATE 
  REFRESH  ON demand 
  AS
    SELECT cp.payrun_id, cpw.salesrep_id,jnb.source_object_id,jnt.notes,  jnb.rowid jnb_rowid, jnt.rowid jnt_rowid
                   FROM cn.cn_payment_worksheets_all cpw
                       ,cn.cn_payruns_all cp
                       ,jtf.JTF_NOTES_B JNB,
          JTF.JTF_NOTES_TL JNT
                   WHERE 
                   --AND cp.payrun_id = P_PAYRUN_ID
                   cp.payrun_id = cpw.payrun_id
                   --AND cpw.salesrep_id = P_SALESREP_ID
                   AND cpw.pmt_amount_adj > 0
                   AND cpw.quota_id is null
                   AND cpw.payment_worksheet_id = jnb.source_object_id
                   AND jnb.note_type IN ('CN_USER')
                   and JNB.JTF_NOTE_ID = JNT.JTF_NOTE_ID
          AND JNT.LANGUAGE = USERENV ('LANG');
