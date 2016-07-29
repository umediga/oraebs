DROP PACKAGE BODY APPS.XXINTG_IRC_OFFER_UPDATES;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_IRC_OFFER_UPDATES" 
AS
/*------------------------------------------------------------------------------
 Module Name  : AME Offer Approval                              
 File Name    : xxintg_irc_offer_updates.pkb                                                                     
 Description  : This package will be called from AME attributes.                                                                   
                                                                                                                   
 Parameters   : N/A                                                                     
                                                                                                                   
 Created By   : Shekhar Nikam                                                                                 
 Creation Date: 07/15/2013                                                                                         
 History      : Initial Creation.                                                                                  
 -----------------------------------------------------------------------------*/
FUNCTION get_offer_transaction_mode(
    transaction_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  --
  l_retval VARCHAR2(200);
BEGIN
  --
  l_retval:=irc_approvals.get_transaction_data (p_transaction_id=>transaction_id ,p_path => '/Transaction/TransCtx/CNode/FlowMode');
  --
  RETURN l_retval;
END get_offer_transaction_mode;

-------------------------------------------------------------------------------------------------------------------------------------

FUNCTION get_offer_spe_comp_changed(
    p_transaction_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  l_new_salary           NUMBER;
  l_old_salary           NUMBER;
  l_old_target_bonus     VARCHAR2(10);
  l_new_target_bonus     VARCHAR2(10);
  l_target_bonus_changed VARCHAR2(10);
  l_salary_changed       VARCHAR2(10);
  l_sc_changed           VARCHAR2(10);
  l_old_sc_value         VARCHAR2(200);
  l_new_sc_value         VARCHAR2(200);
  l_retval               VARCHAR2(30);
  CURSOR csr_chk_hat
  IS
    SELECT 'Yes'
    FROM hr_api_transactions hat
    WHERE XMLTYPE(TRANSACTION_DOCUMENT).existsNode('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate') = 1
    AND hat.transaction_id                                                                                                                             =p_transaction_id;
  CURSOR csr_old_salary
  IS
    SELECT ppp.proposed_salary_n
    FROM per_pay_proposals ppp ,
      per_all_assignments_f paaf ,
      irc_offers iof ,
      hr_api_transactions hat
    WHERE iof.offer_assignment_id=ppp.assignment_id
    AND hat.assignment_id        = paaf.assignment_id
      --and iof.offer_status = 'APPROVED'
    AND iof.offer_id =
      (SELECT irc_approvals.get_transaction_data (p_transaction_id ,'/Transaction/TransCtx/CNode/PreviousOfferId')
      FROM dual
      )
  AND TRUNC(sysdate) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
  AND HAT.TRANSACTION_ID = p_transaction_id;
  CURSOR csr_new_salary
  IS
    SELECT TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.per.schema.server.PerPayProposalsEO"]/PerPayProposalsEORow/ProposedSalaryN/text()')) new_sal
    FROM hr_api_transactions
    WHERE transaction_id                                                                                                                                                                            =p_transaction_id
    AND TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.per.schema.server.PerPayProposalsEO"]/PerPayProposalsEORow/ProposedSalaryN/text()')) IS NOT NULL
  UNION
  SELECT ppp.proposed_salary_n
  FROM HR_API_TRANSACTIONS HAT,
    PER_ALL_ASSIGNMENTS_F ASG,
    IRC_OFFERS IOF,
    PER_PAY_PROPOSALS PPP
  WHERE ASG.ASSIGNMENT_ID     = HAT.ASSIGNMENT_ID
  AND HAT.TRANSACTION_REF_ID  = IOF.OFFER_ID
  AND IOF.OFFER_ASSIGNMENT_ID = PPP.ASSIGNMENT_ID
  AND TRUNC(SYSDATE) BETWEEN ASG.EFFECTIVE_START_DATE AND ASG.EFFECTIVE_END_DATE
    --AND IOF.OFFER_STATUS = 'APPROVED'
  AND HAT.TRANSACTION_ID = p_transaction_id;
  CURSOR csr_old_target_bonus
  IS
    SELECT to_number(iof.attribute5)
    FROM irc_offers iof ,
      hr_api_transactions hat
    WHERE iof.applicant_assignment_id=hat.assignment_id
      --and offer_status = 'APPROVED'
    AND iof.offer_id =
      (SELECT irc_approvals.get_transaction_data (p_transaction_id ,'/Transaction/TransCtx/CNode/PreviousOfferId')
      FROM dual
      )
  AND hat.transaction_id=p_transaction_id;
  CURSOR csr_new_target_bonus
  IS
    SELECT to_number(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO
[@Name="oracle.apps.irc.schema.server.IrcOffersEO"]/IrcOffersEORow/Attribute5/text()')) NEW_TAR_BONUS
    FROM hr_api_transactions hat
    WHERE hat.transaction_id                                                                                                                                                        =p_transaction_id
    AND to_number(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO
[@Name="oracle.apps.irc.schema.server.IrcOffersEO"]/IrcOffersEORow/Attribute5/text()')) IS NOT NULL
  UNION
  SELECT to_number(iof.attribute5)
  FROM HR_API_TRANSACTIONS HAT,
    PER_ALL_ASSIGNMENTS_F ASG,
    IRC_OFFERS IOF
  WHERE ASG.ASSIGNMENT_ID    = HAT.ASSIGNMENT_ID
  AND HAT.TRANSACTION_REF_ID = IOF.OFFER_ID
  AND TRUNC(SYSDATE) BETWEEN ASG.EFFECTIVE_START_DATE AND ASG.EFFECTIVE_END_DATE
    --AND IOF.OFFER_ASSIGNMENT_ID = PPP.ASSIGNMENT_ID
    --AND IOF.OFFER_STATUS = 'APPROVED'
  AND HAT.TRANSACTION_ID = p_transaction_id;
  CURSOR csr_special_comp_plans
  IS
    SELECT meaning
    FROM hr_lookups flv
    WHERE lookup_type ='INTG_SPECIAL_COMP_PLANS'
    AND TRUNC(sysdate) BETWEEN flv.start_date_active AND NVL(flv.end_date_active,to_date('31-DEC-4712','DD-MON-YYYY'));
  CURSOR csr_special_comp_old_val(p_pl_name IN VARCHAR2)
  IS
    SELECT ecr_epe.val
    FROM ben_elig_per_elctbl_chc epe,
      ben_pil_elctbl_chc_popl pel,
      ben_per_in_ler pil,
      ben_oipl_f cop,
      ben_opt_f opt,
      ben_pl_f pl,
      ben_pl_typ_f ptp,
      ben_ler_f ler,
      BEN_ENRT_RT ECR_EPE,
      HR_API_TRANSACTIONS HAT
    WHERE PIL.PER_IN_LER_ID        = EPE.PER_IN_LER_ID
    AND pel.pil_elctbl_chc_popl_id = epe.pil_elctbl_chc_popl_id
    AND pel.pl_id                  = epe.pl_id
    AND epe.pl_typ_id              = ptp.pl_typ_id
    AND ptp.pl_typ_stat_cd         = 'A'
    AND TRUNC (SYSDATE) BETWEEN ptp.effective_start_date AND ptp. effective_end_date
    AND epe.oipl_id = cop.oipl_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (cop.effective_start_date, TRUNC (SYSDATE)) AND NVL (cop.effective_end_date, TRUNC (SYSDATE))
    AND cop.oipl_stat_cd(+) = 'A'
    AND cop.opt_id          = opt.opt_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (opt.effective_start_date, TRUNC (SYSDATE)) AND NVL (opt.effective_end_date, TRUNC (SYSDATE))
    AND pl.pl_id      = epe.pl_id
    AND pl.pl_stat_cd = 'A'
    AND TRUNC (SYSDATE) BETWEEN pl.effective_start_date AND pl. effective_end_date
    AND pl.name         = p_pl_name
    AND epe.elctbl_flag = 'Y'
    AND NOT EXISTS
      (SELECT 1
      FROM ben_plip_f plip
      WHERE plip.pl_id      = pl.pl_id
      AND plip.plip_stat_cd = 'A'
      AND TRUNC (SYSDATE) BETWEEN plip.effective_start_date AND plip.effective_end_date
      )
  AND ler.ler_id = pil.ler_id
  AND ler.typ_cd = 'IREC'
  AND TRUNC (SYSDATE) BETWEEN ler.effective_start_date AND ler. effective_end_date
  AND ECR_EPE.ELIG_PER_ELCTBL_CHC_ID(+)= EPE.ELIG_PER_ELCTBL_CHC_ID
  AND ( PIL.PERSON_ID                  = SELECTED_PERSON_ID
  AND pil.assignment_id                = hat.assignment_id
  AND pil.per_in_ler_stat_cd          IN ('BCKDT')
  AND PEL.PIL_ELCTBL_POPL_STAT_CD     IN ('BCKDT') )
  AND pil.per_in_ler_id                =
    (SELECT MAX(per_in_ler_id)
    FROM ben_per_in_ler pil1
    WHERE person_id       =hat.selected_person_id
    AND per_in_ler_stat_cd='BCKDT'
    )
  AND pil.prvs_stat_cd   IN('STRTD')
  AND APPROVAL_STATUS_CD IS NOT NULL
  AND VAL                IS NOT NULL
  AND HAT.TRANSACTION_ID  = p_transaction_id;
  CURSOR csr_special_comp_new_val(p_pl_name IN VARCHAR2)
  IS
    SELECT to_number(extractvalue(VALUE(xx_row),'/EnrollmentRatesEORow/Val')) New_Val --TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate/text()')) New_Val
    FROM ben_elig_per_elctbl_chc epe,
      ben_pil_elctbl_chc_popl pel,
      ben_per_in_ler pil,
      ben_oipl_f cop,
      ben_opt_f opt,
      ben_pl_f pl,
      ben_pl_typ_f ptp,
      ben_ler_f ler,
      BEN_ENRT_RT ECR_EPE,
      HR_API_TRANSACTIONS HAT,
      TABLE(xmlsequence(extract(xmlparse(document transaction_document wellformed), '/Transaction/TransCache/AM/TXN/EO/EnrollmentRatesEORow'))) xx_row
    WHERE PIL.PER_IN_LER_ID        = EPE.PER_IN_LER_ID
    AND pel.pil_elctbl_chc_popl_id = epe.pil_elctbl_chc_popl_id
    AND pel.pl_id                  = epe.pl_id
    AND epe.pl_typ_id              = ptp.pl_typ_id
    AND ptp.pl_typ_stat_cd         = 'A'
    AND TRUNC (SYSDATE) BETWEEN ptp.effective_start_date AND ptp. effective_end_date
    AND epe.oipl_id = cop.oipl_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (cop.effective_start_date, TRUNC (SYSDATE)) AND NVL (cop.effective_end_date, TRUNC (SYSDATE))
    AND cop.oipl_stat_cd(+) = 'A'
    AND cop.opt_id          = opt.opt_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (opt.effective_start_date, TRUNC (SYSDATE)) AND NVL (opt.effective_end_date, TRUNC (SYSDATE))
    AND pl.pl_id      = epe.pl_id
    AND pl.pl_stat_cd = 'A'
    AND TRUNC (SYSDATE) BETWEEN pl.effective_start_date AND pl. effective_end_date
    AND pl.name         = p_pl_name
    AND epe.elctbl_flag = 'Y'
    AND NOT EXISTS
      (SELECT 1
      FROM ben_plip_f plip
      WHERE plip.pl_id      = pl.pl_id
      AND plip.plip_stat_cd = 'A'
      AND TRUNC (SYSDATE) BETWEEN plip.effective_start_date AND plip.effective_end_date
      )
  AND ler.ler_id = pil.ler_id
  AND ler.typ_cd = 'IREC'
  AND TRUNC (SYSDATE) BETWEEN ler.effective_start_date AND ler. effective_end_date
  AND ECR_EPE.ELIG_PER_ELCTBL_CHC_ID(+)                                                                                                                            = EPE.ELIG_PER_ELCTBL_CHC_ID
  AND ( PIL.PERSON_ID                                                                                                                                              = SELECTED_PERSON_ID
  AND pil.assignment_id                                                                                                                                            = hat.assignment_id
  AND pil.per_in_ler_stat_cd                                                                                                                                      IN ('STRTD', 'PROCD')
  AND PEL.PIL_ELCTBL_POPL_STAT_CD                                                                                                                                 IN ('STRTD', 'PROCD') )
  AND TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate/text()')) IS NOT NULL
  AND XMLTYPE(TRANSACTION_DOCUMENT).existsNode('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate')                 = 1
  AND extractvalue(VALUE(xx_row),'/EnrollmentRatesEORow/EnrtRtId')                                                                                                 = ECR_EPE.enrt_rt_id
    -- AND APPROVAL_STATUS_CD  IS NOT NULL
    -- AND VAL IS NOT NULL
  AND HAT.TRANSACTION_ID = p_transaction_id
  UNION
  SELECT ecr_epe.val New_Val
  FROM ben_elig_per_elctbl_chc epe,
    ben_pil_elctbl_chc_popl pel,
    ben_per_in_ler pil,
    ben_oipl_f cop,
    ben_opt_f opt,
    ben_pl_f pl,
    ben_pl_typ_f ptp,
    ben_ler_f ler,
    BEN_ENRT_RT ECR_EPE,
    HR_API_TRANSACTIONS HAT
  WHERE PIL.PER_IN_LER_ID        = EPE.PER_IN_LER_ID
  AND pel.pil_elctbl_chc_popl_id = epe.pil_elctbl_chc_popl_id
  AND pel.pl_id                  = epe.pl_id
  AND epe.pl_typ_id              = ptp.pl_typ_id
  AND ptp.pl_typ_stat_cd         = 'A'
  AND TRUNC (SYSDATE) BETWEEN ptp.effective_start_date AND ptp. effective_end_date
  AND epe.oipl_id = cop.oipl_id(+)
  AND TRUNC (SYSDATE) BETWEEN NVL (cop.effective_start_date, TRUNC (SYSDATE)) AND NVL (cop.effective_end_date, TRUNC (SYSDATE))
  AND cop.oipl_stat_cd(+) = 'A'
  AND cop.opt_id          = opt.opt_id(+)
  AND TRUNC (SYSDATE) BETWEEN NVL (opt.effective_start_date, TRUNC (SYSDATE)) AND NVL (opt.effective_end_date, TRUNC (SYSDATE))
  AND pl.pl_id      = epe.pl_id
  AND pl.pl_stat_cd = 'A'
  AND TRUNC (SYSDATE) BETWEEN pl.effective_start_date AND pl. effective_end_date
  AND pl.name         = p_pl_name
  AND epe.elctbl_flag = 'Y'
  AND NOT EXISTS
    (SELECT 1
    FROM ben_plip_f plip
    WHERE plip.pl_id      = pl.pl_id
    AND plip.plip_stat_cd = 'A'
    AND TRUNC (SYSDATE) BETWEEN plip.effective_start_date AND plip.effective_end_date
    )
  AND ler.ler_id = pil.ler_id
  AND ler.typ_cd = 'IREC'
  AND TRUNC (SYSDATE) BETWEEN ler.effective_start_date AND ler. effective_end_date
  AND ECR_EPE.ELIG_PER_ELCTBL_CHC_ID(+)                                                                                                                            = EPE.ELIG_PER_ELCTBL_CHC_ID
  AND ( PIL.PERSON_ID                                                                                                                                              = SELECTED_PERSON_ID
  AND pil.assignment_id                                                                                                                                            = hat.assignment_id
  AND pil.per_in_ler_stat_cd                                                                                                                                      IN ('STRTD', 'PROCD')
  AND PEL.PIL_ELCTBL_POPL_STAT_CD                                                                                                                                 IN ('STRTD', 'PROCD') )
  AND TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate/text()')) IS NULL
  AND XMLTYPE(TRANSACTION_DOCUMENT).existsNode('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate')                != 1
  AND APPROVAL_STATUS_CD                                                                                                                                          IS NOT NULL
  AND VAL                                                                                                                                                         IS NOT NULL
  AND HAT.TRANSACTION_ID                                                                                                                                           = p_transaction_id;
BEGIN
  l_retval               := 'false';
  l_salary_changed       :='N';
  l_sc_changed           :='N';
  l_target_bonus_changed := 'N';
  FOR rec_special_comp_plans IN csr_special_comp_plans
  LOOP
    BEGIN
      OPEN csr_special_comp_old_val (rec_special_comp_plans.meaning);
      FETCH csr_special_comp_old_val INTO l_old_sc_value;
      CLOSE csr_special_comp_old_val;
      OPEN csr_special_comp_new_val (rec_special_comp_plans.meaning);
      FETCH csr_special_comp_new_val INTO l_new_sc_value;
      CLOSE csr_special_comp_new_val;
      IF xxintg_irc_offer_updates.get_offer_transaction_mode(p_transaction_id) = 'Update' THEN
        IF(NVL(l_new_sc_value,'XXXX')                                         <> NVL(l_old_sc_value,'XXXX')) THEN
          l_sc_changed                                                        :='Y';
        END IF;
      END IF;
      IF l_sc_changed ='Y' THEN
        EXIT;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      l_sc_changed :='N';
    END;
  END LOOP;
  OPEN csr_old_salary;
  FETCH csr_old_salary INTO l_old_salary;
  CLOSE csr_old_salary;
  OPEN csr_new_salary;
  FETCH csr_new_salary INTO l_new_salary;
  CLOSE csr_new_salary;
  OPEN csr_old_target_bonus;
  FETCH csr_old_target_bonus INTO l_old_target_bonus;
  CLOSE csr_old_target_bonus;
  OPEN csr_new_target_bonus;
  FETCH csr_new_target_bonus INTO l_new_target_bonus;
  CLOSE csr_new_target_bonus;
  IF xxintg_irc_offer_updates.get_offer_transaction_mode(p_transaction_id) = 'Update' THEN
    IF(NVL(l_new_salary,hr_api.g_number)                                  <> NVL(l_old_salary,hr_api.g_number) ) THEN
      l_salary_changed                                                    := 'Y';
    END IF;
    IF(NVL(l_new_target_bonus,hr_api.g_number) <> NVL(l_old_target_bonus,hr_api.g_number) ) THEN
      l_target_bonus_changed                   := 'Y';
    END IF;
  END IF;
  IF l_salary_changed = 'Y' OR l_sc_changed ='Y' OR l_target_bonus_changed = 'Y' THEN
    l_retval         := 'true';
  END IF;
  RETURN l_retval;
END get_offer_spe_comp_changed;

------------------------------------------------------------------------------------------------------------------------------------

FUNCTION get_lti_on_offer(
    p_transaction_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  l_is_lti VARCHAR2(10);
  l_retval VARCHAR2(10);
  CURSOR csr_is_lti_on_offer
  IS
    SELECT 1
    FROM ben_elig_per_elctbl_chc epe,
      ben_pil_elctbl_chc_popl pel,
      ben_per_in_ler pil,
      ben_oipl_f cop,
      ben_opt_f opt,
      ben_pl_f pl,
      ben_pl_typ_f ptp,
      ben_ler_f ler,
      BEN_ENRT_RT ECR_EPE,
      HR_API_TRANSACTIONS HAT,
      TABLE(xmlsequence(extract(xmlparse(document transaction_document wellformed), '/Transaction/TransCache/AM/TXN/EO/EnrollmentRatesEORow'))) xx_row
    WHERE PIL.PER_IN_LER_ID        = EPE.PER_IN_LER_ID
    AND pel.pil_elctbl_chc_popl_id = epe.pil_elctbl_chc_popl_id
    AND pel.pl_id                  = epe.pl_id
    AND epe.pl_typ_id              = ptp.pl_typ_id
    AND ptp.pl_typ_stat_cd         = 'A'
    AND TRUNC (SYSDATE) BETWEEN ptp.effective_start_date AND ptp. effective_end_date
    AND epe.oipl_id = cop.oipl_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (cop.effective_start_date, TRUNC (SYSDATE)) AND NVL (cop.effective_end_date, TRUNC (SYSDATE))
    AND cop.oipl_stat_cd(+) = 'A'
    AND cop.opt_id          = opt.opt_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (opt.effective_start_date, TRUNC (SYSDATE)) AND NVL (opt.effective_end_date, TRUNC (SYSDATE))
    AND pl.pl_id      = epe.pl_id
    AND pl.pl_stat_cd = 'A'
    AND TRUNC (SYSDATE) BETWEEN pl.effective_start_date AND pl. effective_end_date
    AND pl.name         = 'US Sign on Equity'
    AND epe.elctbl_flag = 'Y'
    AND NOT EXISTS
      (SELECT 1
      FROM ben_plip_f plip
      WHERE plip.pl_id      = pl.pl_id
      AND plip.plip_stat_cd = 'A'
      AND TRUNC (SYSDATE) BETWEEN plip.effective_start_date AND plip.effective_end_date
      )
  AND ler.ler_id = pil.ler_id
  AND ler.typ_cd = 'IREC'
  AND TRUNC (SYSDATE) BETWEEN ler.effective_start_date AND ler. effective_end_date
  AND ECR_EPE.ELIG_PER_ELCTBL_CHC_ID(+)                                                                                                                             = EPE.ELIG_PER_ELCTBL_CHC_ID
  AND ( PIL.PERSON_ID                                                                                                                                               = SELECTED_PERSON_ID
  AND pil.assignment_id                                                                                                                                             = hat.assignment_id
  AND pil.per_in_ler_stat_cd                                                                                                                                       IN ('STRTD', 'PROCD')
  AND PEL.PIL_ELCTBL_POPL_STAT_CD                                                                                                                                  IN ('STRTD', 'PROCD') )
  AND TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate/text
()')) IS NOT NULL
  AND XMLTYPE(TRANSACTION_DOCUMENT).existsNode('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate')                  = 1
  AND extractvalue(VALUE(xx_row),'/EnrollmentRatesEORow/EnrtRtId')                                                                                                  = ECR_EPE.enrt_rt_id
    --AND APPROVAL_STATUS_CD
    --  IS NOT NULL
    -- AND VAL
    --  IS NOT NULL
  AND HAT.TRANSACTION_ID =p_transaction_id
  UNION
  SELECT 1
  FROM ben_elig_per_elctbl_chc epe,
    ben_pil_elctbl_chc_popl pel,
    ben_per_in_ler pil,
    ben_oipl_f cop,
    ben_opt_f opt,
    ben_pl_f pl,
    ben_pl_typ_f ptp,
    ben_ler_f ler,
    BEN_ENRT_RT ECR_EPE,
    HR_API_TRANSACTIONS HAT
  WHERE PIL.PER_IN_LER_ID        = EPE.PER_IN_LER_ID
  AND pel.pil_elctbl_chc_popl_id = epe.pil_elctbl_chc_popl_id
  AND pel.pl_id                  = epe.pl_id
  AND epe.pl_typ_id              = ptp.pl_typ_id
  AND ptp.pl_typ_stat_cd         = 'A'
  AND TRUNC (SYSDATE) BETWEEN ptp.effective_start_date AND ptp. effective_end_date
  AND epe.oipl_id = cop.oipl_id(+)
  AND TRUNC (SYSDATE) BETWEEN NVL (cop.effective_start_date, TRUNC (SYSDATE)) AND NVL (cop.effective_end_date, TRUNC (SYSDATE))
  AND cop.oipl_stat_cd(+) = 'A'
  AND cop.opt_id          = opt.opt_id(+)
  AND TRUNC (SYSDATE) BETWEEN NVL (opt.effective_start_date, TRUNC (SYSDATE)) AND NVL (opt.effective_end_date, TRUNC (SYSDATE))
  AND pl.pl_id      = epe.pl_id
  AND pl.pl_stat_cd = 'A'
  AND TRUNC (SYSDATE) BETWEEN pl.effective_start_date AND pl. effective_end_date
  AND pl.name         = 'US Sign on Equity'
  AND epe.elctbl_flag = 'Y'
  AND NOT EXISTS
    (SELECT 1
    FROM ben_plip_f plip
    WHERE plip.pl_id      = pl.pl_id
    AND plip.plip_stat_cd = 'A'
    AND TRUNC (SYSDATE) BETWEEN plip.effective_start_date AND plip.effective_end_date
    )
  AND ler.ler_id = pil.ler_id
  AND ler.typ_cd = 'IREC'
  AND TRUNC (SYSDATE) BETWEEN ler.effective_start_date AND ler. effective_end_date
  AND ECR_EPE.ELIG_PER_ELCTBL_CHC_ID(+)                                                                                                                             = EPE.ELIG_PER_ELCTBL_CHC_ID
  AND ( PIL.PERSON_ID                                                                                                                                               = SELECTED_PERSON_ID
  AND pil.assignment_id                                                                                                                                             = hat.assignment_id
  AND pil.per_in_ler_stat_cd                                                                                                                                       IN ('STRTD', 'PROCD')
  AND PEL.PIL_ELCTBL_POPL_STAT_CD                                                                                                                                  IN ('STRTD', 'PROCD') )
  AND TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate/text
()')) IS NULL
  AND XMLTYPE(TRANSACTION_DOCUMENT).existsNode('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate')                 != 1
  AND APPROVAL_STATUS_CD                                                                                                                                           IS NOT NULL
  AND VAL                                                                                                                                                          IS NOT NULL
  AND HAT.TRANSACTION_ID                                                                                                                                            = p_transaction_id;
BEGIN
  --  l_is_lti := 'No';
  l_retval := 'false';
  BEGIN
    OPEN csr_is_lti_on_offer;
    FETCH csr_is_lti_on_offer INTO l_is_lti;
    CLOSE csr_is_lti_on_offer;
  EXCEPTION
  WHEN OTHERS THEN
    l_retval := 'false';
  END;
  IF l_is_lti IS NOT NULL THEN
    l_retval  := 'true';
  ELSE
    l_retval := 'false';
  END IF;
  RETURN l_retval;
END get_lti_on_offer;

----------------------------------------------------------------------------------------------------------------------------------

FUNCTION get_mb_or_nonlti_comps(
    p_transaction_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  l_retval    VARCHAR2(20);
  l_spec_comp VARCHAR2(10);
  l_incentval VARCHAR2(10);
  l_curval    VARCHAR2(10);
  CURSOR csr_special_comp_nonlti_plans
  IS
    SELECT meaning
    FROM hr_lookups flv
    WHERE lookup_type ='INTG_SPECIAL_COMP_NON_LTI'
    AND TRUNC(sysdate) BETWEEN flv.start_date_active AND NVL(flv.end_date_active,to_date('31-DEC-4712','DD-MON-YYYY'));
  CURSOR csr_spe_comp_nonlti(p_pl_name IN VARCHAR2)
  IS
    SELECT 'Y'
    FROM ben_elig_per_elctbl_chc epe,
      ben_pil_elctbl_chc_popl pel,
      ben_per_in_ler pil,
      ben_oipl_f cop,
      ben_opt_f opt,
      ben_pl_f pl,
      ben_pl_typ_f ptp,
      ben_ler_f ler,
      BEN_ENRT_RT ECR_EPE,
      HR_API_TRANSACTIONS HAT,
      TABLE(xmlsequence(extract(xmlparse(document transaction_document wellformed), '/Transaction/TransCache/AM/TXN/EO/EnrollmentRatesEORow'))) xx_row
    WHERE PIL.PER_IN_LER_ID        = EPE.PER_IN_LER_ID
    AND pel.pil_elctbl_chc_popl_id = epe.pil_elctbl_chc_popl_id
    AND pel.pl_id                  = epe.pl_id
    AND epe.pl_typ_id              = ptp.pl_typ_id
    AND ptp.pl_typ_stat_cd         = 'A'
    AND TRUNC (SYSDATE) BETWEEN ptp.effective_start_date AND ptp. effective_end_date
    AND epe.oipl_id = cop.oipl_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (cop.effective_start_date, TRUNC (SYSDATE)) AND NVL (cop.effective_end_date, TRUNC (SYSDATE))
    AND cop.oipl_stat_cd(+) = 'A'
    AND cop.opt_id          = opt.opt_id(+)
    AND TRUNC (SYSDATE) BETWEEN NVL (opt.effective_start_date, TRUNC (SYSDATE)) AND NVL (opt.effective_end_date, TRUNC (SYSDATE))
    AND pl.pl_id      = epe.pl_id
    AND pl.pl_stat_cd = 'A'
    AND TRUNC (SYSDATE) BETWEEN pl.effective_start_date AND pl. effective_end_date
    AND pl.name         = p_pl_name
    AND epe.elctbl_flag = 'Y'
    AND NOT EXISTS
      (SELECT 1
      FROM ben_plip_f plip
      WHERE plip.pl_id      = pl.pl_id
      AND plip.plip_stat_cd = 'A'
      AND TRUNC (SYSDATE) BETWEEN plip.effective_start_date AND plip.effective_end_date
      )
  AND ler.ler_id = pil.ler_id
  AND ler.typ_cd = 'IREC'
  AND TRUNC (SYSDATE) BETWEEN ler.effective_start_date AND ler. effective_end_date
  AND ECR_EPE.ELIG_PER_ELCTBL_CHC_ID(+)                                                                                                                             = EPE.ELIG_PER_ELCTBL_CHC_ID
  AND ( PIL.PERSON_ID                                                                                                                                               = SELECTED_PERSON_ID
  AND pil.assignment_id                                                                                                                                             = hat.assignment_id
  AND pil.per_in_ler_stat_cd                                                                                                                                       IN ('STRTD', 'PROCD')
  AND PEL.PIL_ELCTBL_POPL_STAT_CD                                                                                                                                  IN ('STRTD', 'PROCD') )
  AND TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate/text
()')) IS NOT NULL
  AND XMLTYPE(TRANSACTION_DOCUMENT).existsNode('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate')                  = 1
  AND extractvalue(VALUE(xx_row),'/EnrollmentRatesEORow/EnrtRtId')                                                                                                  = ECR_EPE.enrt_rt_id
    --AND APPROVAL_STATUS_CD
    --  IS NOT NULL
    -- AND VAL
    --  IS NOT NULL
  AND HAT.TRANSACTION_ID =p_transaction_id
  UNION
  SELECT 'Y'
  FROM ben_elig_per_elctbl_chc epe,
    ben_pil_elctbl_chc_popl pel,
    ben_per_in_ler pil,
    ben_oipl_f cop,
    ben_opt_f opt,
    ben_pl_f pl,
    ben_pl_typ_f ptp,
    ben_ler_f ler,
    BEN_ENRT_RT ECR_EPE,
    HR_API_TRANSACTIONS HAT
  WHERE PIL.PER_IN_LER_ID        = EPE.PER_IN_LER_ID
  AND pel.pil_elctbl_chc_popl_id = epe.pil_elctbl_chc_popl_id
  AND pel.pl_id                  = epe.pl_id
  AND epe.pl_typ_id              = ptp.pl_typ_id
  AND ptp.pl_typ_stat_cd         = 'A'
  AND TRUNC (SYSDATE) BETWEEN ptp.effective_start_date AND ptp. effective_end_date
  AND epe.oipl_id = cop.oipl_id(+)
  AND TRUNC (SYSDATE) BETWEEN NVL (cop.effective_start_date, TRUNC (SYSDATE)) AND NVL (cop.effective_end_date, TRUNC (SYSDATE))
  AND cop.oipl_stat_cd(+) = 'A'
  AND cop.opt_id          = opt.opt_id(+)
  AND TRUNC (SYSDATE) BETWEEN NVL (opt.effective_start_date, TRUNC (SYSDATE)) AND NVL (opt.effective_end_date, TRUNC (SYSDATE))
  AND pl.pl_id      = epe.pl_id
  AND pl.pl_stat_cd = 'A'
  AND TRUNC (SYSDATE) BETWEEN pl.effective_start_date AND pl. effective_end_date
  AND pl.name         = p_pl_name
  AND epe.elctbl_flag = 'Y'
  AND NOT EXISTS
    (SELECT 1
    FROM ben_plip_f plip
    WHERE plip.pl_id      = pl.pl_id
    AND plip.plip_stat_cd = 'A'
    AND TRUNC (SYSDATE) BETWEEN plip.effective_start_date AND plip.effective_end_date
    )
  AND ler.ler_id = pil.ler_id
  AND ler.typ_cd = 'IREC'
  AND TRUNC (SYSDATE) BETWEEN ler.effective_start_date AND ler. effective_end_date
  AND ECR_EPE.ELIG_PER_ELCTBL_CHC_ID(+)                                                                                                                             = EPE.ELIG_PER_ELCTBL_CHC_ID
  AND ( PIL.PERSON_ID                                                                                                                                               = SELECTED_PERSON_ID
  AND pil.assignment_id                                                                                                                                             = hat.assignment_id
  AND pil.per_in_ler_stat_cd                                                                                                                                       IN ('STRTD', 'PROCD')
  AND PEL.PIL_ELCTBL_POPL_STAT_CD                                                                                                                                  IN ('STRTD', 'PROCD') )
  AND TO_NUMBER(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate/text
()')) IS NULL
  AND XMLTYPE(TRANSACTION_DOCUMENT).existsNode('/Transaction/TransCache/AM/TXN/EO[@Name="oracle.apps.ben.schema.server.PlansEO"]/PlansEORow/Rate')                 != 1
  AND APPROVAL_STATUS_CD                                                                                                                                           IS NOT NULL
  AND VAL                                                                                                                                                          IS NOT NULL
  AND HAT.TRANSACTION_ID                                                                                                                                            = p_transaction_id;
  CURSOR csr_incentive_level
  IS
    SELECT 'Y'
    FROM apps.HR_API_TRANSACTIONS HAT ,
      apps.hr_lookups flv
    WHERE hat.transaction_id                                                                                                                                                       = p_transaction_id
    AND to_number(XMLTYPE(TRANSACTION_DOCUMENT).EXTRACT('/Transaction/TransCache/AM/TXN/EO
[@Name="oracle.apps.irc.schema.server.IrcOffersEO"]/IrcOffersEORow/Attribute5/text()')) = flv.meaning
    AND lookup_type                                                                                                                                                                = 'INTG_INCENTIVE_TAR_BONUS_MAP'
    AND TRUNC(sysdate) BETWEEN flv.start_date_active AND NVL(flv.end_date_active,to_date('31-DEC-4712','DD-MON-YYYY'))
  UNION
  SELECT 'Y'
  FROM apps.HR_API_TRANSACTIONS HAT ,
    apps.hr_lookups flv ,
    apps.irc_offers iof
  WHERE hat.transaction_id   = p_transaction_id
  AND iof.attribute5         = flv.meaning
  AND HAT.TRANSACTION_REF_ID = IOF.OFFER_ID
  AND lookup_type            = 'INTG_INCENTIVE_TAR_BONUS_MAP'
  AND TRUNC(sysdate) BETWEEN flv.start_date_active AND NVL(flv.end_date_active,to_date('31-DEC-4712','DD-MON-YYYY'));
BEGIN
  l_retval    := 'false';
  l_spec_comp := 'N';
  l_incentval := 'N';
  BEGIN
    FOR rec_special_comp_nonlti_plans IN csr_special_comp_nonlti_plans
    LOOP
      OPEN csr_spe_comp_nonlti(rec_special_comp_nonlti_plans.meaning);
      FETCH csr_spe_comp_nonlti INTO l_curval;
      CLOSE csr_spe_comp_nonlti;
      IF l_curval    = 'Y' THEN
        l_spec_comp := 'Y';
        EXIT;
      END IF;
    END LOOP;
    OPEN csr_incentive_level;
    FETCH csr_incentive_level INTO l_incentval;
    CLOSE csr_incentive_level;
    IF l_incentval = 'Y' OR l_spec_comp = 'Y' THEN
      l_retval    := 'true';
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_retval := 'false';
  END;
  RETURN l_retval;
END get_mb_or_nonlti_comps;
END xxintg_irc_offer_updates;
/
