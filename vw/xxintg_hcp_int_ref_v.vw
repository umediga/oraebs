DROP VIEW APPS.XXINTG_HCP_INT_REF_V;

/* Formatted on 6/6/2016 5:00:21 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_HCP_INT_REF_V
(
   ORGNAME,
   ADDRESS1,
   ADDRESS2,
   CITY,
   STATE,
   NPI,
   HMS_PIID,
   DOCTORS_LAST_NAME,
   DOCTORS_FIRST_NAME,
   DOCTORS_MIDDLE_NAME,
   REC_ID
)
AS
   SELECT REF.orgname,
          REF.address1,
          REF.address2,
          REF.city,
          REF.state,
          REF.npi,
          REF.hms_piid,
          REF.doctors_last_name,
          REF.doctors_first_name,
          REF.doctors_middle_name,
          mst.rec_id
     FROM xxintg_hcp_int_ref REF, xxintg_hcp_int_main mst
    WHERE REF.npi = mst.npi AND NVL (mst.active_flag, 'N') = 'Y'
   UNION
   SELECT REF.orgname,
          REF.address1,
          REF.address2,
          REF.city,
          REF.state,
          REF.npi,
          REF.hms_piid,
          REF.doctors_last_name,
          REF.doctors_first_name,
          REF.doctors_middle_name,
          mst.rec_id
     FROM xxintg_hcp_int_ref REF, xxintg_hcp_int_main mst
    WHERE REF.hms_piid = mst.hms_piid AND NVL (mst.active_flag, 'N') = 'Y';
