DROP PACKAGE APPS.XX_HR_SAL_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_SAL_CONVERSION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Arjun K
 Creation Date : 11-JAN-2012
 File Name     : XXHRSALCNV.pks
 Description   : This script creates the specification of the package
                 xx_hr_sal_conversion_pkg
 Change History:
 Date           Name               Remarks
 -----------    -------------      -----------------------------------
 11-JAN-2012    Arjun K            Initial Development
 */
----------------------------------------------------------------------
G_STAGE         VARCHAR2(2000);
G_BATCH_ID      VARCHAR2(200);
TYPE G_XX_HR_CNV_HDR_REC_TYPE IS RECORD
        (
    employee_number        VARCHAR2(15),
    unique_id              VARCHAR2(30),
    change_date            DATE,
    proposal_reason        VARCHAR2(900),
    proposed_salary_n      NUMBER,
    approved               VARCHAR2(30),
    next_sal_review_date   DATE,
    date_to                DATE,
    business_group_name    VARCHAR2(150),
    attribute1             VARCHAR2(150),
    attribute2             VARCHAR2(150),
    attribute3             VARCHAR2(150),
    attribute4             VARCHAR2(150),
    attribute5             VARCHAR2(150),
    attribute6             VARCHAR2(150),
    attribute7             VARCHAR2(150),
    attribute8             VARCHAR2(150),
    attribute9             VARCHAR2(150),
    attribute10            VARCHAR2(150),
    attribute11            VARCHAR2(150),
    attribute12            VARCHAR2(150),
    attribute13            VARCHAR2(150),
    attribute14            VARCHAR2(150),
    attribute15            VARCHAR2(150),
    attribute16            VARCHAR2(150),
    attribute17            VARCHAR2(150),
    attribute18            VARCHAR2(150),
    attribute19            VARCHAR2(150),
    attribute20            VARCHAR2(150),
    attribute21            VARCHAR2(150),
    attribute22            VARCHAR2(150),
    attribute23            VARCHAR2(150),
    attribute24            VARCHAR2(150),
    attribute25            VARCHAR2(150),
    attribute26            VARCHAR2(150),
    attribute27            VARCHAR2(150),
    attribute28            VARCHAR2(150),
    attribute29            VARCHAR2(150),
    attribute30            VARCHAR2(150),
    salary_basis           VARCHAR2(100),
    tax_unit_id            NUMBER(10),
    pay_basis_id           NUMBER(10),
    batch_id	           VARCHAR2(200),
    record_number	   NUMBER,
    process_code	   VARCHAR2(100),
    error_code	           VARCHAR2(100),
    request_id	           NUMBER,
    created_by	           NUMBER,
    creation_date	   DATE,
    last_update_date       DATE,
    last_updated_by        NUMBER(15),
    last_update_login      NUMBER(15),
    program_application_id NUMBER(15),
    program_id             NUMBER(15),
    program_update_date    DATE
	);

TYPE G_XX_HR_CNV_HDR_TAB_TYPE IS TABLE OF G_XX_HR_CNV_HDR_REC_TYPE
INDEX BY BINARY_INTEGER;
TYPE G_XX_HR_CNV_PRE_REC_TYPE IS RECORD
        (
    pay_proposal_id        NUMBER(15),
    assignment_id          NUMBER(10),
    person_id              NUMBER,
    business_group_id      NUMBER(15),
    business_group_name    VARCHAR2(60),
    unique_id              VARCHAR2(30),
    employee_number        VARCHAR2(15),
    change_date            DATE,
    next_perf_review_date  DATE,
    next_sal_review_date   DATE,
    performance_rating     VARCHAR2(30),
    proposal_reason        VARCHAR2(900),
    proposed_salary        VARCHAR2(60),
    date_to                DATE,
    attribute_category     VARCHAR2(30),
    approved               VARCHAR2(30),
    multiple_components    VARCHAR2(30),
    forced_ranking         NUMBER,
    performance_review_id  NUMBER(15),
    proposed_salary_n      NUMBER,
    attribute1             VARCHAR2(150),
    attribute2             VARCHAR2(150),
    attribute3             VARCHAR2(150),
    attribute4             VARCHAR2(150),
    attribute5             VARCHAR2(150),
    attribute6             VARCHAR2(150),
    attribute7             VARCHAR2(150),
    attribute8             VARCHAR2(150),
    attribute9             VARCHAR2(150),
    attribute10            VARCHAR2(150),
    attribute11            VARCHAR2(150),
    attribute12            VARCHAR2(150),
    attribute13            VARCHAR2(150),
    attribute14            VARCHAR2(150),
    attribute15            VARCHAR2(150),
    attribute16            VARCHAR2(150),
    attribute17            VARCHAR2(150),
    attribute18            VARCHAR2(150),
    attribute19            VARCHAR2(150),
    attribute20            VARCHAR2(150),
    attribute21            VARCHAR2(150),
    attribute22            VARCHAR2(150),
    attribute23            VARCHAR2(150),
    attribute24            VARCHAR2(150),
    attribute25            VARCHAR2(150),
    attribute26            VARCHAR2(150),
    attribute27            VARCHAR2(150),
    attribute28            VARCHAR2(150),
    attribute29            VARCHAR2(150),
    attribute30            VARCHAR2(150),
    salary_basis           VARCHAR2(100),
    tax_unit_id            NUMBER(10),
    pay_basis_id           NUMBER(10),
    batch_id	           VARCHAR2(200),
    record_number          NUMBER,
    process_code           VARCHAR2(100),
    error_code	           VARCHAR2(100),
    request_id	           NUMBER,
    created_by	           NUMBER,
    creation_date          DATE,
    last_update_date       DATE,
    last_updated_by        NUMBER(15),
    last_update_login      NUMBER(15),
    program_application_id NUMBER(15),
    program_id             NUMBER(15),
    program_update_date    DATE
    );

TYPE G_XX_HR_CNV_PRE_TAB_TYPE IS TABLE OF G_XX_HR_CNV_PRE_REC_TYPE
INDEX BY BINARY_INTEGER;

--Added for Integra
   g_validate_and_load VARCHAR2(100) := 'VALIDATE_AND_LOAD';
   g_validate_flag boolean := TRUE;

PROCEDURE main (
                errbuf                    OUT NOCOPY VARCHAR2,
                retcode                   OUT NOCOPY VARCHAR2,
                p_batch_id                IN         VARCHAR2,
                p_restart_flag            IN         VARCHAR2,
                p_override_flag           IN         VARCHAR2,
                p_validate_and_load       IN         VARCHAR2
        );
--
        CN_XXHRSALSTG_TBL              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRSALSTG_SYN              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRSALPRE_TBL              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRSALPRE_SYN              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRSALVAL_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRSALVAL_PKB              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRSALCNV_PKS              CONSTANT VARCHAR2 (6)    := '1.0';
        CN_XXHRSALCNV_PKB              CONSTANT VARCHAR2 (6)    := '1.0';
--
END XX_HR_SAL_CONVERSION_PKG;
/
