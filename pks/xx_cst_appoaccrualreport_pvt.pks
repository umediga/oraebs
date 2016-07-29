DROP PACKAGE APPS.XX_CST_APPOACCRUALREPORT_PVT;

CREATE OR REPLACE PACKAGE APPS."XX_CST_APPOACCRUALREPORT_PVT" AS

/*===========================================================================*/
--      API name        : Generate_APPOReportXml
--      Type            : Private
--      Function        : Generate XML Data for AP PO Accrual Reconciliation
--                        Report
--      Pre-reqs        : None.
--      Parameters      :
--      IN              : p_Chart_of_accounts_id  IN NUMBER     Required
--                      : p_title                 IN VARCHAR2
--                      : p_bal_segment_from      IN VARCHAR2
--                      : p_bal_segment_to        IN VARCHAR2
--                      : p_aging_days            IN NUMBER
--                      : p_from_amount           IN NUMBER
--                      : p_to_amount             IN NUMBER
--                      : p_from_item             IN VARCHAR2
--                      : p_to_item               IN VARCHAR2
--                      : p_from_vendor           IN VARCHAR2
--                      : p_to_vendor             IN VARCHAR2
--                      : p_sort_by               IN VARCHAR2
--
--     OUT              :
--                      : errcode                 OUT VARCHAR2
--                      : errno                   OUT NUMBER
--
--      Version         : Current version         1.0
--                      : Initial version         1.0
--      Notes           : This Procedure is called by the Ap and PO Accrual
--                        Reconcilition Report. This is the wrapper procedure
--                        that calls the other procedures to generate XML data
--                        according to report parameters.
-- End of comments
/*===========================================================================*/

PROCEDURE Generate_APPOReportXml (
            errcode                     OUT NOCOPY      VARCHAR2,
            err_code                    OUT NOCOPY      NUMBER,

            p_Chart_of_accounts_id      IN              NUMBER,
            p_bal_seg_val               IN              NUMBER,
            p_title                     IN              VARCHAR2,
            p_bal_segment_from          IN              VARCHAR2,
            p_bal_segment_to            IN              VARCHAR2,
            p_aging_days                IN              NUMBER,
            p_from_amount               IN              NUMBER,
            p_to_amount                 IN              NUMBER,
            p_from_item                 IN              VARCHAR2,
            p_to_item                   IN              VARCHAR2,
            p_from_vendor               IN              VARCHAR2,
            p_to_vendor                 IN              VARCHAR2,
            p_sort_by                   IN              VARCHAR2 );

/*===========================================================================*/
--      API name        : add_parameters
--      Type            : Private
--      Function        : Generate XML data for Parameters and append it to
--                        output
--      Pre-reqs        : None.
--      Parameters      :
--      IN              : p_api_version           IN NUMBER
--                      : p_init_msg_list         IN VARCHAR2
--                      : p_validation_level      IN NUMBER
--                      : i_title                 IN VARCHAR2
--                      : i_sort_by               IN VARCHAR2
--                      : i_aging_days            IN NUMBER
--                      : i_from_item             IN VARCHAR2
--                      : i_to_item               IN VARCHAR2
--                      : i_from_vendor           IN VARCHAR2
--                      : i_to_vendor             IN VARCHAR2
--                      : i_from_amount           IN NUMBER
--                      : i_to_amount             IN NUMBER
--                      : i_bal_segment_from      IN VARCHAR2
--                      : i_bal_segment_to        IN VARCHAR2
--
--      OUT             :
--                      : x_return_status         OUT VARCHAR2
--                      : x_msg_count             OUT NUMBER
--                      : x_msg_data              OUT VARCHAR2
--
--      IN OUT          :
--                      : x_xml_doc               IN OUT NOCOPY CLOB
--
--      Version         : Current version         1.0
--                      : Initial version         1.0
--      Notes           : This Procedure is called by Generate_APPOReportXml
--                        procedure. The procedure generates XML data for the
--                        report parameters and appends it to the report
--                        output.
-- End of comments
/*===========================================================================*/

PROCEDURE Add_Parameters
                (p_api_version          IN              NUMBER,
                p_init_msg_list         IN              VARCHAR2 ,
                p_validation_level      IN              NUMBER,

                x_return_status         OUT NOCOPY      VARCHAR2,
                x_msg_count             OUT NOCOPY      NUMBER,
                x_msg_data              OUT NOCOPY      VARCHAR2,

                i_title                 IN              VARCHAR2,
                i_sort_by               IN              VARCHAR2,
                i_aging_days            IN              NUMBER,
                i_from_item             IN              VARCHAR2,
                i_to_item               IN              VARCHAR2,
                i_from_vendor           IN              VARCHAR2,
                i_to_vendor             IN              VARCHAR2,
                i_from_amount           IN              NUMBER,
                i_to_amount             IN              NUMBER,
                i_bal_segment_from      IN              VARCHAR2,
                i_bal_segment_to        IN              VARCHAR2,

                x_xml_doc               IN OUT NOCOPY   CLOB);

/*===========================================================================*/
--      API name        : Add_ApPoData
--      Type            : Private
--      Function        : Generate XML data from sql query and append it to
--                        output
--      Pre-reqs        : None.
--      Parameters      :
--      IN              : p_api_version           IN NUMBER
--                      : p_init_msg_list         IN VARCHAR2
--                      : p_validation_level      IN NUMBER
--                      : i_title                 IN VARCHAR2
--                      : i_sort_by               IN VARCHAR2
--                      : i_aging_days            IN NUMBER
--                      : i_from_item             IN VARCHAR2
--                      : i_to_item               IN VARCHAR2
--                      : i_from_vendor           IN VARCHAR2
--                      : i_to_vendor             IN VARCHAR2
--                      : i_from_amount           IN NUMBER
--                      : i_to_amount             IN NUMBER
--                      : i_bal_segment_from      IN VARCHAR2
--                      : i_bal_segment_to        IN VARCHAR2
--
--     OUT              :
--                      : x_return_status         OUT VARCHAR2
--                      : x_msg_count             OUT NUMBER
--                      : x_msg_data              OUT VARCHAR2
--
--      IN OUT          :
--                      : x_xml_doc               IN OUT NOCOPY CLOB
--
--      Version         : Current version         1.0
--                      : Initial version         1.0
--      Notes           : This Procedure is called by Generate_APPOReportXml
--                        procedure. The procedure generates XML data from
--                        sql query and appends it to the report output.
-- End of comments
/*===========================================================================*/

PROCEDURE Add_ApPoData
                (p_api_version          IN              NUMBER,
                p_init_msg_list         IN              VARCHAR2,
                p_validation_level      IN              NUMBER,

                x_return_status         OUT NOCOPY      VARCHAR2,
                x_msg_count             OUT NOCOPY      NUMBER,
                x_msg_data              OUT NOCOPY      VARCHAR2,

                i_title                 IN              VARCHAR2,
                i_sort_by               IN              VARCHAR2,
                i_aging_days            IN              NUMBER,
                i_from_item             IN              VARCHAR2,
                i_to_item               IN              VARCHAR2,
                i_from_vendor           IN              VARCHAR2,
                i_to_vendor             IN              VARCHAR2,
                i_from_amount           IN              NUMBER,
                i_to_amount             IN              NUMBER,
                i_bal_segment_from      IN              VARCHAR2,
                i_bal_segment_to        IN              VARCHAR2,

                x_xml_doc               IN OUT NOCOPY   CLOB);

END XX_CST_ApPoAccrualReport_PVT ;
/
