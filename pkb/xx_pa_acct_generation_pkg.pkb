DROP PACKAGE BODY APPS.XX_PA_ACCT_GENERATION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_PA_ACCT_GENERATION_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By    : Sharath Babu
 Creation Date : 10-JUN-2012
 File Name     : XXPAACCTGENR.pkb
 Description   : This script creates the body of the package
                 xx_pa_acct_generation_pkg
 Change History:
 Date          Name                  Remarks
 -----------   -------------         -----------------------------------
 10-JUN-2012   Sharath Babu          Initial Development
*/
----------------------------------------------------------------------

--Procedure to generate account for capitalizable task
PROCEDURE get_capt_acct_cc(p_itemtype  IN  VARCHAR2,
                           p_itemkey   IN  VARCHAR2,
                           p_actid     IN  NUMBER,
                           p_funcmode  IN  VARCHAR2,
                           x_result    OUT VARCHAR2)
IS

   x_project_id      pa_projects_all.project_id%TYPE;
   x_task_id         pa_tasks.task_id%TYPE;
   x_company         VARCHAR2(25);
   x_department      VARCHAR2(25);
   x_account         VARCHAR2(25);
   x_classification  VARCHAR2(25);
   x_product         VARCHAR2(25);
   x_region          VARCHAR2(25);
   x_intercompany    VARCHAR2(25);
   x_future          VARCHAR2(25);
   x_concatenated_segments VARCHAR2(207);
   x_ccid            NUMBER;
   x_error_code      NUMBER;
   x_err_code        NUMBER;
   x_variable        VARCHAR2(10) := NULL;
   x_coa_id          NUMBER;
   x_eff_date        DATE := SYSDATE;

BEGIN
   --Set EMF Environment
   x_err_code := xx_emf_pkg.set_env('XXPAACCTGENR');

   x_project_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                                 itemkey    => p_itemkey,
                                                 aname      => 'PROJECT_ID');

   x_task_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                              itemkey    => p_itemkey,
                                              aname      => 'TASK_ID');

   x_coa_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                             itemkey    => p_itemkey,
                                             aname      => 'CHART_OF_ACCOUNTS_ID');

   --Fetch Value for Company and Region
   BEGIN
      SELECT pcak.segment1,pcak.segment6
        INTO x_company,x_region
        FROM pa_projects_all ppa
            ,hr_all_organization_units haou
            ,pay_cost_allocation_keyflex pcak
      WHERE 1=1
        AND ppa.carrying_out_organization_id = haou.organization_id
        AND haou.cost_allocation_keyflex_id = pcak.cost_allocation_keyflex_id
        AND ppa.project_id = x_project_id;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Company and Region if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'Account Generator failed to retrive the values for Segments '||
                            'Comapany and Region. ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Fetch Value for Department
   BEGIN
      SELECT xpp.parameter_value
        INTO x_department
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'CAPT_DEPARTMENT'
         AND xps.process_name = 'XXPAACCTGENR';

   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Department if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;
   --Fetch Value for Account
   BEGIN
      SELECT xpp.parameter_value
        INTO x_account
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'CAPT_ACCOUNT'
         AND xps.process_name = 'XXPAACCTGENR';

   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Account if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;
   --Fetch Value for Classification
   BEGIN
      SELECT xpp.parameter_value
        INTO x_classification
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'CAPT_CLASSIFICATION'
         AND xps.process_name = 'XXPAACCTGENR';

   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Classification if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;
   --Fetch Value for Product
   BEGIN
      SELECT xpp.parameter_value
        INTO x_product
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'CAPT_PRODUCT'
         AND xps.process_name = 'XXPAACCTGENR';

   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Product if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;
   --Fetch Value for Intercompany
   BEGIN
      SELECT xpp.parameter_value
        INTO x_intercompany
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'CAPT_INTERCOMPANY'
         AND xps.process_name = 'XXPAACCTGENR';

   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Intercompany if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;
   --Fetch Value for Future
   BEGIN
      SELECT xpp.parameter_value
        INTO x_future
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'CAPT_FUTURE'
         AND xps.process_name = 'XXPAACCTGENR';

   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Future if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;

   --Validate the Segments
   --Validate Company
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code = 'GL#'
         AND UPPER (ffs.segment_name) = UPPER ('Company')
         AND ffv.flex_value_set_id = ffs.flex_value_set_id
         AND ffv.flex_value = x_company
         AND ffv.enabled_flag = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
         WHEN OTHERS THEN
         xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                         ,p_category             => 'PA Account Generation'
                         ,p_error_text           => 'Error while Validating Company if Capitalizable'
                         ,p_record_identifier_1  => p_itemtype
                         ,p_record_identifier_2  => x_project_id
                         ,p_record_identifier_3  => x_company
                         );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(1) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Department
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values      ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Department')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_department
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Department if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_department
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(2) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Account
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values      ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Account')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_account
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Account if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_account
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(3) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Classification
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values      ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Classification')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_classification
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Classification if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_classification
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(4) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;
   --Validate Product
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values      ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Product')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_product
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Product if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_product
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(5) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Region
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values      ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Region')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_region
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Region if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_region
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(6) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Intercompany
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values      ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Intercompany')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_intercompany
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Intercompany if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_intercompany
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(7) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Future
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments ffs,
             fnd_flex_values      ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Future')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_future
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Future if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_future
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(8) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Form Concatenated Segments
   x_concatenated_segments := x_company||'-'||x_department||'-'||x_account||'-'||x_classification||'-'||x_product||'-'||x_region||'-'||x_intercompany||'-'||x_future;

   x_ccid := NULL;
   --Call function to derive code combination id
   BEGIN
      x_ccid := fnd_flex_ext.get_ccid ('SQLGL',
                                       'GL#',
                                       x_coa_id,
                                       TO_CHAR (x_eff_date, 'YYYY/MM/DD HH24:MI:SS'),
                                       x_concatenated_segments
                                      );
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while calling fnd_flex_ext.get_ccid if Capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_coa_id
                     );
   END;

   IF x_ccid IS NULL OR x_ccid <= 0 THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Unable to Create Code Combination by Oracle Standard API '
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                     );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'Unable to Create Account Code Combination '||
                            'by Oracle Standard API. ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END IF;

   --Set CC ID
   wf_engine.SetItemAttrNumber ( itemtype     => p_itemtype,
                                 itemkey      => p_itemkey,
                                 aname        => 'INTG_CODE_COMBINATION_ID',
                                 avalue       => x_ccid);

   x_result := 'COMPLETE:SUCCESS';
   RETURN;
   EXCEPTION
      WHEN OTHERS THEN
         x_result := 'COMPLETE:FAILURE';
         xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                         ,p_category             => 'PA Account Generation'
                         ,p_error_text           => 'Error at level xx_pa_acct_generation_pkg.get_capt_acct_cc if Capitalizable'
                         ,p_record_identifier_1  => p_itemtype
                         ,p_record_identifier_2  => x_project_id
                         ,p_record_identifier_3  => x_task_id
                        );
         RAISE;
END get_capt_acct_cc;

--Procedure to generate account for Expense or Non-capitalizable  task
PROCEDURE get_exp_acct_cc(p_itemtype  IN  VARCHAR2,
                          p_itemkey   IN  VARCHAR2,
                          p_actid     IN  NUMBER,
                          p_funcmode  IN  VARCHAR2,
                          x_result    OUT VARCHAR2)
IS

   x_project_id      pa_projects_all.project_id%TYPE;
   x_task_id         pa_tasks.task_id%TYPE;
   x_company         VARCHAR2(25);
   x_department      VARCHAR2(25);
   x_account         VARCHAR2(25);
   x_classification  VARCHAR2(25);
   x_product         VARCHAR2(25);
   x_region          VARCHAR2(25);
   x_intercompany    VARCHAR2(25);
   x_future          VARCHAR2(25);
   x_expenditure_type VARCHAR2(100);
   x_ccid            NUMBER;
   x_error_code      NUMBER;
   x_err_code        NUMBER;
   x_variable        VARCHAR2(10) := NULL;
   x_concatenated_segments VARCHAR2(207);
   x_coa_id          NUMBER;
   x_eff_date        DATE := SYSDATE;

BEGIN
   --Set EMF Environment
   x_err_code := xx_emf_pkg.set_env('XXPAACCTGENR');

   x_project_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                                 itemkey    => p_itemkey,
                                                 aname      => 'PROJECT_ID');

   x_task_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                              itemkey    => p_itemkey,
                                              aname      => 'TASK_ID');

   x_expenditure_type := wf_engine.GetItemAttrText ( itemtype   => p_itemtype,
                                                     itemkey    => p_itemkey,
                                                     aname      => 'EXPENDITURE_TYPE');

   x_coa_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                             itemkey    => p_itemkey,
                                             aname      => 'CHART_OF_ACCOUNTS_ID');

   --Fetch the values for Company,Department,Product,Region
   BEGIN
      SELECT pcak.segment1,pcak.segment2,pcak.segment5,pcak.segment6
        INTO x_company,x_department,x_product,x_region
        FROM pa_projects_all ppa
            ,hr_all_organization_units haou
            ,pay_cost_allocation_keyflex pcak
       WHERE 1=1
         AND ppa.carrying_out_organization_id = haou.organization_id
         AND haou.cost_allocation_keyflex_id = pcak.cost_allocation_keyflex_id
         AND ppa.project_id = x_project_id;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Company and Region if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'Account Generator failed to retrive the values for Segments '||
                            'Comapany, Department, Product and Region. ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;
   --Fetch the Value for Account
   BEGIN
      SELECT pvl.segment_value
        INTO x_account
        FROM pa_segment_value_lookup_sets pvls
            ,pa_segment_value_lookups pvl
       WHERE pvls.segment_value_lookup_set_id = pvl.segment_value_lookup_set_id
         AND pvls.segment_value_lookup_set_name = 'Exp Type to Account'
         AND pvl.segment_value_lookup = x_expenditure_type;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for account if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'Account Generator failed to retrive the value for Account Segment. '||
                            'Please choose correct Project Expenditure Type ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Fetch Value for Classification
   BEGIN
      SELECT xpp.parameter_value
        INTO x_classification
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'EXP_CLASSIFICATION'
         AND xps.process_name = 'XXPAACCTGENR';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Classification if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;

   --Fetch Value for Intercompany
   BEGIN
      SELECT xpp.parameter_value
        INTO x_intercompany
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'EXP_INTERCOMPANY'
         AND xps.process_name = 'XXPAACCTGENR';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Intercompany if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;

   --Fetch Value for Future
   BEGIN
      SELECT xpp.parameter_value
        INTO x_future
        FROM xx_emf_process_parameters xpp,
             xx_emf_process_setup xps
       WHERE 1 = 1
         AND xps.process_id = xpp.process_id
         AND xpp.parameter_name = 'EXP_FUTURE'
         AND xps.process_name = 'XXPAACCTGENR';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while fetching value for Future if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
   END;

   --Validate the Segments
   --Validate Company
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Company')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_company
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
         WHEN OTHERS THEN
         xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                         ,p_category             => 'PA Account Generation'
                         ,p_error_text           => 'Error while Validating Company if Expense'
                         ,p_record_identifier_1  => p_itemtype
                         ,p_record_identifier_2  => x_project_id
                         ,p_record_identifier_3  => x_company
                         );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(1) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Department
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Department')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_department
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Department if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_department
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(2) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Account
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Account')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_account
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Account if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_account
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(3) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Classification
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Classification')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_classification
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Classification if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_classification
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(4) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;
   --Validate Product
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Product')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_product
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Product if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_product
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(5) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Region
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Region')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_region
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Region if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_region
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(6) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Intercompany
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Intercompany')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_intercompany
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Intercompany if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_intercompany
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(7) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Validate Future
   x_variable := NULL;
   BEGIN
      SELECT 'X'
        INTO x_variable
        FROM fnd_id_flex_segments   ffs,
             fnd_flex_values        ffv,
             fnd_id_flex_structures fifs
       WHERE ffs.id_flex_code         = 'GL#'
         AND UPPER(ffs.segment_name)  = UPPER('Future')
         AND ffv.flex_value_set_id    = ffs.flex_value_set_id
         AND ffv.flex_value           = x_future
         AND ffv.enabled_flag         = 'Y'
         AND fifs.id_flex_code = ffs.id_flex_code
         AND ffs.id_flex_num = fifs.id_flex_num
         AND UPPER(fifs.id_flex_structure_code) = 'INTG_ACCOUNTING_FLEXFIELD';
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Validating Future if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_future
                      );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'The derived value for Segment(8) is invalid ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END;

   --Concateating the Segs
   x_concatenated_segments := x_company||'-'||x_department||'-'||x_account||'-'||x_classification||'-'||x_product||'-'||x_region||'-'||x_intercompany||'-'||x_future;

   x_ccid := NULL;
   --Call function to derive code combination id
   BEGIN
      x_ccid := fnd_flex_ext.get_ccid ('SQLGL',
                                       'GL#',
                                       x_coa_id,
                                       TO_CHAR (x_eff_date, 'YYYY/MM/DD HH24:MI:SS'),
                                       x_concatenated_segments
                                      );
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while calling fnd_flex_ext.get_ccid if Expense'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_coa_id
                     );
   END;

   IF x_ccid IS NULL OR x_ccid <= 0 THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Unable to Create Code Combination by Oracle Standard API'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                     );
      FND_MESSAGE.set_name('FND', 'ERROR_MESSAGE');
      FND_MESSAGE.set_token('MESSAGE',
                            'Unable to Create Account Code Combination '||
                            'by Oracle Standard API. ');
      wf_engine.SetItemAttrText
                     ( itemtype=> p_itemtype,
                       itemkey => p_itemkey,
                       aname   => 'ERROR_MESSAGE',
                       avalue  => fnd_message.get_encoded);
      x_result := 'COMPLETE:FAILURE';
      RETURN;
   END IF;

   --Set CC ID
   wf_engine.SetItemAttrNumber ( itemtype     => p_itemtype,
                                 itemkey      => p_itemkey,
                                 aname        => 'INTG_CODE_COMBINATION_ID',
                                 avalue       => x_ccid);

   x_result := 'COMPLETE:SUCCESS';
   RETURN;
   EXCEPTION
      WHEN OTHERS THEN
         x_result := 'COMPLETE:FAILURE';
         xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                         ,p_category             => 'PA Account Generation'
                         ,p_error_text           => 'Error at level xx_pa_acct_generation_pkg.get_exp_acct_cc if Expense'
                         ,p_record_identifier_1  => p_itemtype
                         ,p_record_identifier_2  => x_project_id
                         ,p_record_identifier_3  => x_task_id
                        );
      RAISE;
END get_exp_acct_cc;

--Procedure to find whether task is capitalizable task
PROCEDURE is_task_capitalizable( p_itemtype  IN  VARCHAR2,
                                 p_itemkey   IN  VARCHAR2,
                                 p_actid     IN  NUMBER,
                                 p_funcmode  IN  VARCHAR2,
                                 x_result    OUT VARCHAR2)
IS

      x_task_id pa_tasks.task_id%TYPE;
      x_varaiable VARCHAR2(10) := NULL;
      x_project_id pa_projects_all.project_id%TYPE;
      x_err_code NUMBER;
BEGIN
   --Set EMF Environment
   x_err_code := xx_emf_pkg.set_env('XXPAACCTGENR');
   x_project_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                                 itemkey    => p_itemkey,
                                                 aname      => 'PROJECT_ID');
   x_task_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                              itemkey    => p_itemkey,
                                              aname      => 'TASK_ID');
   BEGIN
      SELECT 'X'
        INTO x_varaiable
        FROM pa_tasks pt
       WHERE 1=1
         AND pt.billable_flag = 'Y'
         AND pt.task_id = x_task_id;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error while Checking if task is capitalizable'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );

   END;
   IF x_varaiable IS NOT NULL THEN
      x_result := 'COMPLETE:T';
   ELSE
      x_result := 'COMPLETE:F';
   END IF;
   RETURN;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error(p_severity             => xx_emf_cn_pkg.cn_medium
                      ,p_category             => 'PA Account Generation'
                      ,p_error_text           => 'Error At Procedure xx_pa_acct_generation_pkg.is_task_capitalizable level'
                      ,p_record_identifier_1  => p_itemtype
                      ,p_record_identifier_2  => x_project_id
                      ,p_record_identifier_3  => x_task_id
                      );
      RAISE;
END is_task_capitalizable;

--Procedure to find whether project is capitalizable
PROCEDURE is_project_capitalizable( p_itemtype  IN  VARCHAR2,
                                    p_itemkey   IN  VARCHAR2,
                                    p_actid     IN  NUMBER,
                                    p_funcmode  IN  VARCHAR2,
                                    x_result    OUT VARCHAR2)
IS
   x_project_id                  pa_projects_all.project_id%TYPE;
   x_project_type_class_code     pa_project_types_all.project_type_class_code%TYPE;
   x_err_code                    NUMBER;
BEGIN
   --Set EMF Environment
   x_err_code := xx_emf_pkg.set_env('XXPAACCTGENR');
   x_project_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                                 itemkey    => p_itemkey,
                                                 aname      => 'PROJECT_ID');


   BEGIN
      SELECT ppta.project_type_class_code
        INTO x_project_type_class_code
        FROM pa_projects_all ppa
            ,pa_project_types_all ppta
       WHERE ppa.project_type = ppta.project_type
         AND ppa.org_id = ppta.org_id
         AND TRUNC(SYSDATE) BETWEEN ppta.start_date_active AND NVL(ppta.end_date_active,TO_DATE('12/31/4712','MM/DD/RRRR'))
         AND ppa.project_id = x_project_id;
   EXCEPTION
      WHEN OTHERS THEN
      xx_emf_pkg.error( p_severity             => xx_emf_cn_pkg.cn_medium
                       ,p_category            => 'PA Account GenerationS'
                       ,p_error_text           => 'Error while identifying if project is capitalizable.'
                       ,p_record_identifier_1  => p_itemtype
                       ,p_record_identifier_2  => x_project_id
                      );
      RAISE;
   END;

   IF x_project_type_class_code ='CAPITAL' THEN
      x_result := 'COMPLETE:T';
   ELSE
      x_result := 'COMPLETE:F';
   END IF;

   RETURN;
EXCEPTION
   WHEN OTHERS THEN
      xx_emf_pkg.error(  p_severity             => xx_emf_cn_pkg.cn_medium
                        ,p_category            => 'PA Account GenerationS'
                        ,p_error_text           => 'Error at procedure xx_pa_acct_generation_pkg.is_project_capitalizable level'
                        ,p_record_identifier_1  => p_itemtype
                        ,p_record_identifier_2  => x_project_id
                      );
      RAISE;
END is_project_capitalizable;

--Procedure to check project related or not
PROCEDURE is_project_related ( p_itemtype  IN  VARCHAR2,
                               p_itemkey   IN  VARCHAR2,
                               p_actid     IN  NUMBER,
                               p_funcmode  IN  VARCHAR2,
                               x_result    OUT VARCHAR2
                             )
IS
   x_project_id  pa_projects_all.project_id%TYPE := NULL;
   x_err_code    NUMBER;
BEGIN
   --Set EMF Environment
   x_err_code := xx_emf_pkg.set_env('XXPAACCTGENR');
   x_project_id := wf_engine.GetItemAttrNumber ( itemtype   => p_itemtype,
                                                 itemkey    => p_itemkey,
                                                 aname      => 'PROJECT_ID');

   IF x_project_id IS NOT NULL THEN
      x_result := 'COMPLETE:T';
   ELSE
      x_result := 'COMPLETE:F';
   END IF;
   RETURN;
EXCEPTION
   WHEN OTHERS THEN
   xx_emf_pkg.error( p_severity             => xx_emf_cn_pkg.cn_medium
                    ,p_category             => 'PA Account Generation'
                    ,p_error_text           => 'Error At Procedure xx_pa_acct_generation_pkg.is_project_related level'
                    ,p_record_identifier_1  => p_itemtype
                    ,p_record_identifier_2  => x_project_id
                   );
   RAISE;
END is_project_related;

END xx_pa_acct_generation_pkg;
/
