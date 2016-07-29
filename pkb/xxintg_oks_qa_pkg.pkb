DROP PACKAGE BODY APPS.XXINTG_OKS_QA_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_OKS_QA_PKG" AS
/*******************************************************************************
Name: XXINTG_OKS_QA_PKG
Description:  This is add additional validations for QA check in contracts-
History:  17-OCT-2014    Shankar Narayanan orignal version
 
******************************************************************************/
    --Procedure Name : CHECK_SOURCE_LIC_PRICE_USED
PROCEDURE CHECK_PO_NUMBER_ENTERED(
        x_return_status OUT NOCOPY VARCHAR2,
        p_chr_id IN NUMBER) IS
        l_return_status    VARCHAR2(1) := OKL_API.G_RET_STS_SUCCESS;
        CURSOR l_cur IS SELECT cust_po_number FROM OKC_K_HEADERS_ALL_V WHERE id = p_chr_id;
        l_po_error     CONSTANT VARCHAR2(2000) := 'Customer PO Number is missing';
    BEGIN
        -- initialize return status
        l_return_status := OKL_API.G_RET_STS_SUCCESS;
        FOR l_rec IN l_cur LOOP
            If ( l_rec.cust_po_number IS NULL) Then
                l_return_status := OKL_API.G_RET_STS_ERROR;
            End If;
        END LOOP;
 x_return_status := l_return_status;
        IF x_return_status = OKL_API.G_RET_STS_SUCCESS THEN
            OKL_API.set_message(
            p_app_name => OKL_QA_DATA_INTEGRITY.G_APP_NAME,
            p_msg_name => OKL_QA_DATA_INTEGRITY.G_QA_SUCCESS);
        ELSE
     OKL_API.set_message(
     p_app_name => OKL_QA_DATA_INTEGRITY.G_APP_NAME,
     p_msg_name => l_po_error); --OKL_API.G_RET_STS_ERROR);
     END IF;
    EXCEPTION
        WHEN OTHERS THEN
         x_return_status := OKL_API.G_RET_STS_UNEXP_ERROR;
 End CHECK_PO_NUMBER_ENTERED ;
 
END XXINTG_OKS_QA_PKG;
/
