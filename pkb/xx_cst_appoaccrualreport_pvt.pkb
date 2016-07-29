DROP PACKAGE BODY APPS.XX_CST_APPOACCRUALREPORT_PVT;

CREATE OR REPLACE PACKAGE BODY APPS."XX_CST_APPOACCRUALREPORT_PVT" AS

 G_PKG_NAME CONSTANT VARCHAR2(30) := 'CST_ApPoAccrualReport_PVT';
 G_LOG_LEVEL CONSTANT NUMBER := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
 G_LOG_HEADER CONSTANT VARCHAR2(100) := 'cst.plsql.CST_ACCRUAL_MISC_REPORT';

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
            p_sort_by                   IN              VARCHAR2 )
IS
        l_qryCtx                        NUMBER;
        l_ref_cur                       SYS_REFCURSOR;
        l_xml_doc                       CLOB;
        l_amount                        NUMBER;
        l_offset                        NUMBER;
        l_buffer                        VARCHAR2(32767);
        l_length                        NUMBER;
        l_current_org_id                NUMBER;

        l_api_name      CONSTANT        VARCHAR2(100)   := 'Generate_APPOReportXml';
        l_api_version   CONSTANT        NUMBER          := 1.0;

        l_return_status                 VARCHAR2(1);
        l_msg_count                     NUMBER;
        l_msg_data                      VARCHAR2(2000);
        l_stmt_num                      NUMBER;
        l_success                       BOOLEAN;
    l_error_message                 VARCHAR2(300);

        l_full_name     CONSTANT        VARCHAR2(2000)  := G_PKG_NAME || '.' || l_api_name;
        l_module        CONSTANT        VARCHAR2(2000)  := 'cst.plsql.' || l_full_name;

        l_uLog          CONSTANT        BOOLEAN         := FND_LOG.LEVEL_UNEXPECTED >= G_LOG_LEVEL AND FND_LOG.TEST (FND_LOG.LEVEL_UNEXPECTED,
l_module);
        l_errorLog      CONSTANT        BOOLEAN         := l_uLog AND (FND_LOG.LEVEL_ERROR >= G_LOG_LEVEL);
        l_eventLog      CONSTANT        BOOLEAN         := l_errorLog AND (FND_LOG.LEVEL_EVENT >= G_LOG_LEVEL);
        l_pLog          CONSTANT        BOOLEAN         := l_eventLog AND (FND_LOG.LEVEL_PROCEDURE >= G_LOG_LEVEL);
    l_sLog          CONSTANT        BOOLEAN         := l_pLog and (FND_LOG.LEVEL_STATEMENT >= G_LOG_LEVEL);

    l_conc_request         BOOLEAN;
     /*Bug 7000786*/
        l_encoding             VARCHAR2(20);
    l_xml_header           VARCHAR2(100);

 BEGIN

/*Added for bug 8787827,
If the NLS_NUMERIC_CHARACTER=,. then report total will be displayed as NaN*/

 EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''';
-- Initialze variables

        l_amount        := 16383;
        l_offset        := 1;
        l_return_status := fnd_api.g_ret_sts_success;
        l_msg_count     := 0;

/* check if to_amount is greater than or equal to from_amount */

 If (p_from_amount is not null and p_to_amount < p_from_amount ) then

      l_error_message := 'CST_INVALID_TO_AMOUNT';
      fnd_message.set_name('BOM','CST_INVALID_TO_AMOUNT');
      RAISE fnd_api.g_exc_error;
    End If;


/* check if aging bucket is greater than zero */

 If (p_aging_days < 0 ) then

      l_error_message := 'CST_INVALID_AGE';
      fnd_message.set_name('BOM','CST_INVALID_AGE');
      RAISE fnd_api.g_exc_error;
    End If;


-- select the operating unit for which the program is launched.

l_stmt_num := 10;

        l_current_org_id := MO_GLOBAL.get_current_org_id;

 -- Write the module name and user parameters to fnd log file

  IF (l_pLog) THEN
       FND_LOG.STRING (FND_LOG.LEVEL_PROCEDURE,
                       l_module || '.begin',
                       '>>> ' || l_api_name || ':Parameters:
                        Org id:'||  l_current_org_id
                        || 'Title: '  || p_title
                        || ' Sort Option: ' || p_sort_by
                        || ' Aging Days: ' || p_aging_days
                        || ' From Item: ' || p_from_item
                        || ' To Item: ' ||p_to_item
                        || ' From Vendor: ' || p_from_vendor
                        || ' To Vendor:' || p_to_vendor
                        || ' Min Amount: ' || p_from_amount
                        || ' Max Amount: ' || p_to_amount
                        || ' Balancing Segment From: ' || p_bal_segment_from
                        || ' Balancing Segment To: ' || p_bal_segment_to );
  END IF;

-- Initialze variables for storing XML Data

        DBMS_LOB.createtemporary(l_xml_doc, TRUE);

        /*Bug 7000786 - This fix ensures that XML data generated here uses the right encoding*/
    l_encoding       := fnd_profile.value('ICX_CLIENT_IANA_ENCODING');
    l_xml_header     := '<?xml version="1.0" encoding="'|| l_encoding ||'"?>';
    DBMS_LOB.writeappend (l_xml_doc, length(l_xml_header), l_xml_header);

        DBMS_LOB.writeappend (l_xml_doc, 8, '<REPORT>');

 -- Initialize message stack

        FND_MSG_PUB.initialize;

-- Standard call to get message count and if count is 1, get message info.

        FND_MSG_PUB.Count_And_Get
        (       p_count    =>      l_msg_count,
                p_data     =>      l_msg_data
        );

l_stmt_num := 20;

/*========================================================================*/
-- Call to Procedure Add Parameters. To Add user entered Parameters to
-- XML data
/*========================================================================*/

        Add_Parameters  (p_api_version          => l_api_version,
                         p_init_msg_list        => FND_API.G_FALSE,
                         p_validation_level     => FND_API.G_VALID_LEVEL_FULL,
                         x_return_status        => l_return_status,
                         x_msg_count            => l_msg_count,
                         x_msg_data             => l_msg_data,
                         i_title                => p_title,
                         i_sort_by              => p_sort_by,
                         i_aging_days           => p_aging_days   ,
                         i_from_item            => p_from_item,
                         i_to_item              => p_to_item,
                         i_from_vendor          => p_from_vendor,
                         i_to_vendor            => p_to_vendor,
                         i_from_amount          => p_from_amount,
                         i_to_amount            => p_to_amount,
                         i_bal_segment_from     => p_bal_segment_from,
                         i_bal_segment_to       => p_bal_segment_to,
                         x_xml_doc              => l_xml_doc);

-- Standard call to check the return status from API called

        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


l_stmt_num := 30;

/*========================================================================*/
-- Call to Procedure Add Parameters. To Add AP and PO data to XML data
/*========================================================================*/

        Add_ApPoData    (p_api_version          => l_api_version,
                         p_init_msg_list        => FND_API.G_FALSE,
                         p_validation_level     => FND_API.G_VALID_LEVEL_FULL,
                         x_return_status        => l_return_status,
                         x_msg_count            => l_msg_count,
                         x_msg_data             => l_msg_data,
                         i_title                => p_title,
                         i_sort_by              => p_sort_by,
                         i_aging_days           => p_aging_days   ,
                         i_from_item            => p_from_item,
                         i_to_item              => p_to_item,
                         i_from_vendor          => p_from_vendor,
                         i_to_vendor            => p_to_vendor,
                         i_from_amount          => p_from_amount,
                         i_to_amount            => p_to_amount,
                         i_bal_segment_from     => p_bal_segment_from,
                         i_bal_segment_to       => p_bal_segment_to,
                         x_xml_doc              => l_xml_doc);

-- Standard call to check the return status from API called

        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

-- write the closing tag to the XML data

        DBMS_LOB.writeappend (l_xml_doc, 9, '</REPORT>');

-- write xml data to the output file

        l_length := nvl(dbms_lob.getlength(l_xml_doc),0);
        LOOP
                EXIT WHEN l_length <= 0;
                dbms_lob.read (l_xml_doc, l_amount, l_offset, l_buffer);
                FND_FILE.PUT (FND_FILE.OUTPUT, l_buffer);
                l_length := l_length - l_amount;
                l_offset := l_offset + l_amount;
      END LOOP;

      DBMS_XMLGEN.closeContext(l_qryCtx);

-- Write the event log to fnd log file

      IF (l_eventLog) THEN
                FND_LOG.STRING (FND_LOG.LEVEL_EVENT,
                l_module || '.' || l_stmt_num,
                'Completed writing to output file');
      END IF;

-- free temporary memory

        DBMS_LOB.FREETEMPORARY (l_xml_doc);

        l_success := FND_CONCURRENT.SET_COMPLETION_STATUS('NORMAL', 'Request Completed Successfully');

-- Write the module name to fnd log file

        IF (l_pLog) THEN
                FND_LOG.STRING (FND_LOG.LEVEL_PROCEDURE,
                l_module || '.end',
                '<<< ' || l_api_name);
        END IF;

 EXCEPTION
          WHEN FND_API.G_EXC_ERROR THEN
   ROLLBACK;
   l_return_status := FND_API.g_ret_sts_error;
   If l_errorLog then
     fnd_log.message(FND_LOG.LEVEL_ERROR,
                    G_LOG_HEADER || '.' || l_api_name || '(' ||to_char(l_stmt_num)||')',
                    FALSE
                    );
   end If;

   fnd_msg_pub.add;

   If l_slog then
     fnd_log.string(FND_LOG.LEVEL_STATEMENT,
                    G_LOG_HEADER || '.'||l_api_name||'('||to_char(l_stmt_num)||')',
                    l_error_message
                   );
   End If;

   FND_MSG_PUB.count_and_get
             (  p_count => l_msg_count
              , p_data  => l_msg_data
              );


 CST_UTILITY_PUB.writelogmessages
                (       p_api_version   => l_api_version,
                        p_msg_count     => l_msg_count,
                        p_msg_data      => l_msg_data,
                        x_return_status => l_return_status);

                l_msg_data      := SUBSTRB (SQLERRM,1,240);
                l_success       := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR', l_msg_data);

   l_conc_request := fnd_concurrent.set_completion_status('ERROR',substr(fnd_message.get_string('BOM',l_error_message),1,240));

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                FND_MSG_PUB.Count_And_Get
                (       p_count => l_msg_count,
                        p_data  => l_msg_data
                );

                CST_UTILITY_PUB.writelogmessages
                (       p_api_version   => 1.0,
                        p_msg_count     => l_msg_count,
                        p_msg_data      => l_msg_data,
                        x_return_status => l_return_status);

                l_msg_data      := SUBSTRB (SQLERRM,1,240);
                l_success       := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR', l_msg_data);

        WHEN OTHERS THEN
                IF (l_uLog) THEN
                        FND_LOG.STRING (FND_LOG.LEVEL_UNEXPECTED,
                        l_module || '.' || l_stmt_num,
                        SUBSTRB (SQLERRM , 1 , 240));
                END IF;

                IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
                THEN
                        FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME,l_api_name);
                END IF;

                FND_MSG_PUB.Count_And_Get
                (       p_count  =>  l_msg_count,
                        p_data   =>  l_msg_data
                );

                CST_UTILITY_PUB.writelogmessages
                (       p_api_version   => l_api_version,
                        p_msg_count     => l_msg_count,
                        p_msg_data      => l_msg_data,
                        x_return_status => l_return_status);

                l_msg_data      := SUBSTRB (SQLERRM,1,240);
                l_success       := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR', l_msg_data);

END Generate_APPOReportXml;

PROCEDURE Add_Parameters
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

                x_xml_doc               IN OUT NOCOPY   CLOB)
IS
        l_api_name      CONSTANT        VARCHAR2(30)    := 'ADD_PARAMETERS';
        l_api_version   CONSTANT        NUMBER          := 1.0;

        l_full_name     CONSTANT        VARCHAR2(2000)  := G_PKG_NAME || '.' || l_api_name;
        l_module        CONSTANT        VARCHAR2(2000)  := 'cst.plsql.' || l_full_name;

        l_ref_cur                       SYS_REFCURSOR;
        l_qryCtx                        NUMBER;
        l_xml_temp                      CLOB;
        l_age_option                    NUMBER;
        l_offset                        PLS_INTEGER;
        l_org_code                      VARCHAR2(300);
    l_org_name                      VARCHAR2(300);
        l_stmt_num                      NUMBER;
        l_current_org_id                NUMBER;

        l_uLog          CONSTANT        BOOLEAN         := FND_LOG.LEVEL_UNEXPECTED >= G_LOG_LEVEL AND FND_LOG.TEST (FND_LOG.LEVEL_UNEXPECTED,
l_module);
        l_errorLog      CONSTANT        BOOLEAN         := l_uLog AND (FND_LOG.LEVEL_ERROR >= G_LOG_LEVEL);
        l_eventLog      CONSTANT        BOOLEAN         := l_errorLog AND (FND_LOG.LEVEL_EVENT >= G_LOG_LEVEL);
        l_pLog          CONSTANT        BOOLEAN         := l_eventLog AND (FND_LOG.LEVEL_PROCEDURE >= G_LOG_LEVEL);

BEGIN

 -- Write the module name to fnd log file

        IF (l_pLog) THEN
                FND_LOG.STRING (FND_LOG.LEVEL_PROCEDURE,
                l_module || '.begin',
                '>>> ' || l_api_name);
        END IF;

-- Standard call to check for call compatibility.

        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

-- Initialize message list if p_init_msg_list is set to TRUE.

        IF FND_API.to_Boolean( p_init_msg_list ) THEN
                FND_MSG_PUB.initialize;
        END IF;

--  Initialize API return status to success

        x_return_status := FND_API.G_RET_STS_SUCCESS;

-- Initialize temporary variable to hold xml data

         DBMS_LOB.createtemporary(l_xml_temp, TRUE);
         l_offset := 21;

l_stmt_num := 10;

-- Get the proile value to determine the aging basis

        fnd_profile.get('CST_ACCRUAL_AGE_IN_DAYS', l_age_option);

-- select the operating unit for which the program is launched.

l_stmt_num := 20;

        l_current_org_id := MO_GLOBAL.get_current_org_id;

-- select the operating unit code for which the program is launched.

l_stmt_num := 30;

begin
        select mp.organization_code
        into   l_org_code
        from   mtl_parameters                  mp
        where  mp.organization_id  = l_current_org_id;

exception
when no_data_found then
l_org_code := NULL;

end;
-- select the operating unit name for which the program is launched.

l_stmt_num := 40;

        select hr.NAME
        into   l_org_name
        from   HR_ALL_ORGANIZATION_UNITS       hr
        where  hr.ORGANIZATION_ID  = l_current_org_id;

l_stmt_num := 50;

-- Open Ref Cursor to collect the report parameters

        OPEN l_ref_cur FOR 'select :l_org_code                          org_code,
                                   :l_org_name                          org_name,
                                   xla.NAME                             ledger_name,
                                   xla.currency_code                    CUR_CODE,
                                   :i_title                             TITLE_NAME,
                                   crs.displayed_field                  sort_option,
                                   :i_aging_days                        age_days,
                                   :i_from_item                         from_item,
                                   :i_to_item                           to_item,
                                   :i_from_vendor                       from_vendor,
                                   :i_to_vendor                         to_vendor,
                                   :i_from_amount                       from_amount,
                                   :i_to_amount                         to_amount,
                                   :i_bal_segment_from                  bal_seg_from,
                                   :i_bal_segment_to                    bal_seg_to,
                                   decode(:l_age_option,
                                           1,
                                           ''Last Receipt Date'',
                                           ''Last Activity Date'')      age_option
                            FROM   cst_reconciliation_codes             crs,
                                   XLA_GL_LEDGERS_V                     xla,
                                   HR_ORGANIZATION_INFORMATION          hoi
                            WHERE  hoi.ORGANIZATION_ID = :l_current_org_id
                            and    hoi.ORG_INFORMATION_CONTEXT = ''Operating Unit Information''
                            and    xla.LEDGER_ID = hoi.ORG_INFORMATION3
                            AND    crs.lookup_type      = ''SRS ACCRUAL ORDER BY''
                            AND    crs.LOOKUP_CODE      = :i_sort_by'
                            USING  l_org_code,
                       l_org_name,
                       i_title,
                                   i_aging_days,
                                   i_from_item ,
                                   i_to_item ,
                                   i_from_vendor,
                                   i_to_vendor,
                                   i_from_amount,
                                   i_to_amount,
                                   i_bal_segment_from,
                                   i_bal_segment_to,
                                   l_age_option,
                                   l_current_org_id,
                                   i_sort_by;

-- create new context

l_stmt_num := 60;

        l_qryCtx := DBMS_XMLGEN.newContext (l_ref_cur);
        DBMS_XMLGEN.setRowSetTag (l_qryCtx,'PARAMETERS');
        DBMS_XMLGEN.setRowTag (l_qryCtx,NULL);

l_stmt_num := 70;

-- get XML into the temporary clob variable

        DBMS_XMLGEN.getXML (l_qryCtx, l_xml_temp, DBMS_XMLGEN.none);

-- remove the header (21 characters) and append the rest to xml output

        IF (DBMS_XMLGEN.getNumRowsProcessed(l_qryCtx) > 0) THEN
                DBMS_LOB.erase (l_xml_temp, l_offset,1);
                DBMS_LOB.append (x_xml_doc, l_xml_temp);
        END IF;

-- close context and free memory

        DBMS_XMLGEN.closeContext(l_qryCtx);
        CLOSE l_ref_cur;
        DBMS_LOB.FREETEMPORARY (l_xml_temp);

-- Standard call to get message count and if count is 1, get message info.

   FND_MSG_PUB.Count_And_Get
   (    p_count         =>       x_msg_count,
        p_data          =>       x_msg_data);

-- Write the module name to fnd log file

   IF (l_pLog) THEN
        FND_LOG.STRING (FND_LOG.LEVEL_PROCEDURE,
                        l_module || '.end',
                        '<<< ' || l_api_name);
   END IF;

 EXCEPTION
        WHEN FND_API.G_EXC_ERROR THEN
                x_return_status := FND_API.G_RET_STS_ERROR ;
                FND_MSG_PUB.Count_And_Get
                (       p_count         =>      x_msg_count,
                        p_data          =>      x_msg_data
                );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                FND_MSG_PUB.Count_And_Get
                (       p_count         =>      x_msg_count,
                        p_data          =>      x_msg_data
                );

        WHEN OTHERS THEN
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                IF (l_uLog) THEN
                        FND_LOG.STRING(FND_LOG.LEVEL_UNEXPECTED,
                                       l_module || '.' || l_stmt_num,
                                       SUBSTRB (SQLERRM , 1 , 240));
                END IF;

                IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
                THEN
                        FND_MSG_PUB.Add_Exc_Msg
                        (       G_PKG_NAME,
                                l_api_name
                        );
                END IF;

                FND_MSG_PUB.Count_And_Get
                (       p_count         =>      x_msg_count,
                        p_data          =>      x_msg_data
                );

END Add_Parameters;

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

                x_xml_doc               IN OUT NOCOPY   CLOB)
IS
        l_api_name      CONSTANT        VARCHAR2(100)   := 'AP_PO_REPORT_DATA';
        l_api_version   CONSTANT        NUMBER          := 1.0;

        l_ref_cur                       SYS_REFCURSOR;
        l_qryCtx                        NUMBER;
        l_xml_temp                      CLOB;
        l_offset                        PLS_INTEGER;
        l_bal_segment                   VARCHAR2(50);
        l_items_null                    VARCHAR2(1);
        l_vendors_null                  VARCHAR2(1);
        l_age_option                    NUMBER;
        l_age_days                      NUMBER;
        l_age_div                       NUMBER;
        l_count                         NUMBER;
        l_stmt_num                      NUMBER;
        l_current_org_id                NUMBER;
        l_account_range                 NUMBER;
        l_currency                      VARCHAR2(50);

        l_full_name     CONSTANT        VARCHAR2(2000)  := G_PKG_NAME || '.' || l_api_name;
        l_module        CONSTANT        VARCHAR2(2000)  := 'cst.plsql.' || l_full_name;


        l_uLog          CONSTANT        BOOLEAN         := FND_LOG.LEVEL_UNEXPECTED >= G_LOG_LEVEL AND FND_LOG.TEST (FND_LOG.LEVEL_UNEXPECTED,
l_module);
        l_errorLog      CONSTANT        BOOLEAN         := l_uLog AND (FND_LOG.LEVEL_ERROR >= G_LOG_LEVEL);
        l_eventLog      CONSTANT        BOOLEAN         := l_errorLog AND (FND_LOG.LEVEL_EVENT >= G_LOG_LEVEL);
        l_pLog          CONSTANT        BOOLEAN         := l_eventLog AND (FND_LOG.LEVEL_PROCEDURE >= G_LOG_LEVEL);

BEGIN

-- Write the module name to fnd log file

         IF (l_pLog) THEN
                FND_LOG.STRING (FND_LOG.LEVEL_PROCEDURE,
                                l_module || '.begin',
                                '>>> ' || l_api_name);
         END IF;

-- Standard call to check for call compatibility.

        IF NOT FND_API.Compatible_API_Call ( l_api_version,
                                             p_api_version,
                                             l_api_name,
                                             G_PKG_NAME )
        THEN
                RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

-- Initialize message list if p_init_msg_list is set to TRUE.

        IF FND_API.to_Boolean( p_init_msg_list ) THEN
                FND_MSG_PUB.initialize;
        END IF;

--  Initialize API return status to success

        x_return_status := FND_API.G_RET_STS_SUCCESS;

-- Initialize temporary variable to hold xml data

        DBMS_LOB.createtemporary(l_xml_temp, TRUE);
        l_offset := 21;

-- select the operating unit for which the program is launched.

l_stmt_num := 10;

        l_current_org_id := MO_GLOBAL.get_current_org_id;

-- Check if item range is given

l_stmt_num := 20;

        IF (  (i_from_item IS NULL)  AND  (i_to_item IS NULL)  ) THEN

                l_items_null := 'Y';

        ELSE
                l_items_null := 'N';

        END IF;

-- Check if vendor range is given

l_stmt_num := 30;

         IF((i_from_vendor IS NULL) AND (i_to_vendor IS NULL)) THEN

                l_vendors_null := 'Y';

            ELSE
                 l_vendors_null := 'N';

          END IF;

-- select the balancing segment value

l_stmt_num := 40;

        SELECT  fav.application_column_name
        INTO    l_bal_segment
        FROM    gl_sets_of_books                gl,
                fnd_segment_attribute_values    fav,
                hr_organization_information     hr
        WHERE   hr.org_information_context      = 'Operating Unit Information'
        AND     hr.organization_id              = l_current_org_id
        AND     to_number(hr.org_information3)  = gl.set_of_books_id
        AND     fav.segment_attribute_type      = 'GL_BALANCING'
        AND     fav.attribute_value             = 'Y'
        AND     fav.application_id              = 101
        AND     fav.id_flex_code                = 'GL#'
        AND     id_flex_num                     = gl.chart_of_accounts_id;

-- get the proile value to determine the aging basis

        fnd_profile.get('CST_ACCRUAL_AGE_IN_DAYS', l_age_option);

-- to check if the value of agings is not null or zero

l_stmt_num := 50;

        IF (i_aging_days IS NULL) OR (i_aging_days = 0)
        THEN
                l_age_days := 0;
                l_age_div := 1;
        ELSE
                l_age_days := i_aging_days;
                l_age_div := i_aging_days;
        END IF;

-- find if balancing segment range is given

 IF (  (i_bal_segment_from IS NULL)   AND   (i_bal_segment_to IS NULL)  ) THEN

       l_account_range := 0;

 ELSIF (  (i_bal_segment_from IS NOT NULL)   AND   (i_bal_segment_to IS NULL)  ) THEN

                l_account_range := 1;

         ELSIF (  (i_bal_segment_from IS NULL)   AND   (i_bal_segment_to IS NOT NULL)  ) THEN

                        l_account_range := 2;
         ELSE

                        l_account_range := 3;
END IF;


-- select the currency code

select   xla.currency_code
into     l_currency
from     XLA_GL_LEDGERS_V                             xla,
         HR_ORGANIZATION_INFORMATION                  hoi
where    hoi.ORGANIZATION_ID = l_current_org_id
and      hoi.ORG_INFORMATION_CONTEXT = 'Operating Unit Information'
and      xla.LEDGER_ID = hoi.ORG_INFORMATION3;

-- open ref cur to fetch ap and po data

l_stmt_num := 60;

        OPEN l_ref_cur FOR 'SELECT   :l_age_days                                age_days,
                                     gcc.concatenated_segments                  account,
                                     decode(:l_age_days, 0, 0,
                                     floor( ( sysdate - decode(:l_age_option,
                                     1,
                                     nvl(crs.last_receipt_date,crs.LAST_INVOICE_DIST_DATE),
                                     greatest(nvl(last_receipt_date,LAST_INVOICE_DIST_DATE),
                     nvl(LAST_INVOICE_DIST_DATE, last_receipt_date))
                     )) /  :l_age_div)*:l_age_days)             bkt_start_date,
                     decode(:l_age_days, 0, 0,
                     ceil(( sysdate - decode(:l_age_option,
                                     1,
                                     nvl(crs.last_receipt_date,crs.LAST_INVOICE_DIST_DATE),
                                     greatest(nvl(last_receipt_date,LAST_INVOICE_DIST_DATE),
                     nvl(LAST_INVOICE_DIST_DATE, last_receipt_date))
                     ) ) / :l_age_div)*:l_age_days-1)           bkt_end_date,
                     NVL(poh.CLM_DOCUMENT_NUMBER,poh.SEGMENT1)  po_number, --Changed as a part of CLM
                                     por.release_num                            po_release,
                                     nvl(POL.LINE_NUM_DISPLAY,
                     to_char(POL.LINE_NUM))                     po_line,--Changed as a part of CLM
                                     poll.shipment_num                          po_shipment,
                                     pod.distribution_num                       po_distribution_num,
                                     crs.po_distribution_id                     po_distribution,
                                     crs.po_balance                             po_balance,
                                     crs.ap_balance                             ap_balance,
                                     crs.write_off_balance                      wo_balance,
                                     :l_currency                                l_currency,
                                     (nvl(crs.po_balance,0) + nvl(crs.ap_balance,0)
                                     + nvl(crs.write_off_balance,0))            total_balance,
                                     trunc(sysdate - decode(:l_age_option,
                                     1,
                                     nvl(crs.last_receipt_date,crs.LAST_INVOICE_DIST_DATE),
                                      greatest(nvl(last_receipt_date,LAST_INVOICE_DIST_DATE), nvl(LAST_INVOICE_DIST_DATE, last_receipt_date))
                     )
                     )              age_in_days,
                                     decode(crs.inventory_item_id, null, null,
                                           (select msi.concatenated_segments from
                                            mtl_system_items_vl msi
                                            where inventory_item_id = crs.inventory_item_id
                                           and rownum <2)
                                           )                                    item,
                                     decode(capr.write_off_id,
                                          NULL, pol.UNIT_MEAS_LOOKUP_CODE,
                      NULL )                                uom,
                                     pov.vendor_name                            vendor,
                                     pdt.displayed_field                        destination,
                                     decode(capr.invoice_distribution_id,
                                     NULL,
                                     decode(capr.write_off_id,
                                          NULL,
                                          ''PO'',
                                          ''WO''),
                                     ''AP'')                                    transaction_source ,
                                     crc.displayed_field                        transaction_type,
                                     capr.transaction_date                      transaction_date,
                                     apia.invoice_num                           invoice_number,
                                     aida.invoice_line_number                   invoice_line,
                                     capr.quantity                              quantity,
                                     capr.amount                                amount,
                                     capr.entered_amount                        entered_amount,
                                     capr.currency_code                         currency_code,
                                     capr.write_off_id                          write_off_id,
                                     decode(capr.inventory_organization_id,
                                     NULL,
                                     NULL,
                                     mp.organization_code)                      org,
                                     rsh.receipt_num                            receipt_number,
                                     gcc1.concatenated_segments                 charge_account
                            FROM     cst_reconciliation_codes                   crc,
                                     cst_ap_po_reconciliation                   capr,
                                     ap_invoices_all                            apia,
                                     ap_invoice_distributions_all               aida,
                                     mtl_parameters                             mp,
                                     rcv_transactions                           rct,
                                     rcv_shipment_headers                       rsh,
                                     cst_reconciliation_summary                 crs,
                                     po_distributions_all                       pod,
                                     po_line_locations_all                      poll,
                                     po_releases_all                            por,
                                     po_lines_all                               pol,
                                     po_headers_all                             poh,
                                     po_vendors                                 pov,
                                     po_destination_types_all_v                 pdt,
                                     gl_code_combinations_kfv                   gcc,
                                     gl_code_combinations_kfv                   gcc1
                            WHERE    crc.lookup_code = to_char(capr.transaction_type_code)
                            AND      crc.lookup_type in ( ''RCV TRANSACTION TYPE'',
                                             ''ACCRUAL WRITE-OFF ACTION'',''ACCRUAL TYPE'')
                            AND       aida.invoice_distribution_id(+) = capr.invoice_distribution_id
                            AND       apia.invoice_id(+) = aida.invoice_id
                            AND       mp.organization_id(+) = capr.inventory_organization_id
                            AND       rct.transaction_id(+) = capr.rcv_transaction_id
                            AND       rsh.shipment_header_id(+) = rct.shipment_header_id
                            AND       capr.po_distribution_id = crs.po_distribution_id
                            and       crs.accrual_account_id = capr.accrual_account_id
                            AND       pod.po_distribution_id = crs.po_distribution_id
                            AND       poll.line_location_id = pod.line_location_id
                            AND       pod.po_release_id = por.po_release_id(+)
                            AND       pol.po_line_id = pod.po_line_id
                            AND       poh.po_header_id = pod.po_header_id
                            AND       pdt.lookup_code(+) = crs.destination_type_code
                            AND       pov.vendor_id(+) = crs.vendor_id
                            AND       crs.accrual_account_id = gcc.code_combination_id
                            AND       pod.code_combination_id = gcc1.code_combination_id
                            AND       crs.operating_unit_id  = :l_current_org_id
                            AND       capr.operating_unit_id  = :l_current_org_id
                            AND       (nvl(crs.po_balance,0) + nvl(crs.ap_balance,0)
                                             + nvl(crs.write_off_balance,0))
                                      BETWEEN   nvl(:i_from_amount,(nvl(crs.po_balance,0)
                                                + nvl(crs.ap_balance,0) + nvl(crs.write_off_balance,0)))
                                      AND       nvl(:i_to_amount,(nvl(crs.po_balance,0) +
                                                nvl(crs.ap_balance,0) + nvl(crs.write_off_balance,0)))
                           AND       (( :l_account_range = 0 )
                                                OR (  :l_account_range = 1 AND
                                                      gcc.' || l_bal_segment || ' >=  :i_bal_segment_from)
                                                OR  (  :l_account_range = 2 AND
                                                      gcc.' || l_bal_segment || ' <=  :i_bal_segment_to)
                                                OR (  :l_account_range = 3 AND
                                                      gcc.' || l_bal_segment || ' BETWEEN :i_bal_segment_from
                                                AND :i_bal_segment_to   )    )
                            AND       (:l_items_null  = ''Y''
                                      OR (:l_items_null  = ''N''
                                      AND decode(crs.inventory_item_id, null, null,
                                           (select msi.concatenated_segments
                                            from mtl_system_items_vl msi
                                            where inventory_item_id = crs.inventory_item_id
                                            and rownum <2))
                                      between nvl(:i_from_item, decode(crs.inventory_item_id, null,
                                                                       null,
                                                                       (select msi.concatenated_segments
                                                                        from mtl_system_items_vl msi
                                                                        where inventory_item_id = crs.inventory_item_id
                                                                        and rownum <2)))
                                      and nvl(:i_to_item ,decode(crs.inventory_item_id, null, null,
                                                                (select msi.concatenated_segments
                                                                 from mtl_system_items_vl msi
                                                                 where inventory_item_id = crs.inventory_item_id
                                                                 and rownum <2)))
                                          ))
                            AND       (:l_vendors_null  = ''Y''
                                      OR ( :l_vendors_null = ''N''
                                           and pov.vendor_name between nvl( :i_from_vendor, pov.vendor_name )
                                                  and nvl( :i_to_vendor, pov.vendor_name )
                                          )
                                       )
                            ORDER BY  decode(   :i_sort_by ,
                                                ''ITEM'', item,
                                                ''AGE IN DAYS'', decode(sign(age_in_days),-1,
                                                                   chr(0) || translate( to_char(abs(age_in_days), ''000000000999.999''),
                                                                    ''0123456789'', ''9876543210''), to_char(age_in_days , ''000000000999.999'' ) ),
                                                ''VENDOR'', pov.vendor_name,
                                                ''TOTAL BALANCE'', decode(sign(total_balance),-1,
                                                                   chr(0) || translate( to_char(abs(total_balance), ''000000000999.999''),
                                                                    ''0123456789'', ''9876543210''),to_char(total_balance, ''000000000999.999'' ) ),
                                                ''PO NUMBER'',  NVL(poh.CLM_DOCUMENT_NUMBER,poh.SEGMENT1))  '
                            USING       l_age_days,
                    l_age_days,
                        l_age_option,
                        l_age_div,
                        l_age_days,
                        l_age_days,
                        l_age_option,
                        l_age_div,
                        l_age_days,
                    l_currency,
                                        l_age_option,
                                        l_current_org_id,
                                        l_current_org_id,
                                        i_from_amount,
                                        i_to_amount,
                                        l_account_range,
                                        l_account_range,
                                        i_bal_segment_from,
                                        l_account_range,
                                        i_bal_segment_to,
                                        l_account_range,
                                        i_bal_segment_from,
                                        i_bal_segment_to,
                                        l_items_null,
                                        l_items_null,
                                        i_from_item,
                                        i_to_item,
                                        l_vendors_null,
                                        l_vendors_null,
                                        i_from_vendor,
                                        i_to_vendor,
                                        i_sort_by;

-- create new context

l_stmt_num := 70;

        l_qryCtx := DBMS_XMLGEN.newContext (l_ref_cur);
        DBMS_XMLGEN.setRowSetTag (l_qryCtx,'AP_PO_DATA');
        DBMS_XMLGEN.setRowTag (l_qryCtx,'AP_PO');

-- get XML into the temporary clob variable

l_stmt_num := 80;

        DBMS_XMLGEN.getXML (l_qryCtx, l_xml_temp, DBMS_XMLGEN.none);

-- remove the header (21 characters) and append the rest to xml output

        l_count := DBMS_XMLGEN.getNumRowsProcessed(l_qryCtx);

        IF (DBMS_XMLGEN.getNumRowsProcessed(l_qryCtx) > 0) THEN
                DBMS_LOB.erase (l_xml_temp, l_offset,1);
                DBMS_LOB.append (x_xml_doc, l_xml_temp);
        END IF;

-- close context and free memory

        DBMS_XMLGEN.closeContext(l_qryCtx);
        CLOSE l_ref_cur;
        DBMS_LOB.FREETEMPORARY (l_xml_temp);

-- to add number of rows processed

    DBMS_LOB.createtemporary(l_xml_temp, TRUE);

-- open ref cursor to get the number of rows processed

l_stmt_num := 90;

        OPEN l_ref_cur FOR SELECT l_count l_count FROM dual ;

-- create new context

 l_stmt_num := 100;

        l_qryCtx := DBMS_XMLGEN.newContext (l_ref_cur);
        DBMS_XMLGEN.setRowSetTag (l_qryCtx,'RECORD_NUM');
        DBMS_XMLGEN.setRowTag (l_qryCtx,NULL);

-- get XML to add the number of rows processed

l_stmt_num := 110;

         DBMS_XMLGEN.getXML (l_qryCtx, l_xml_temp, DBMS_XMLGEN.none);

-- remove the header (21 characters) and append the rest to xml output

        IF ( DBMS_XMLGEN.getNumRowsProcessed(l_qryCtx) > 0 ) THEN
                DBMS_LOB.erase (l_xml_temp, l_offset,1);
                DBMS_LOB.append (x_xml_doc, l_xml_temp);
        END IF;

-- close context and free memory

        DBMS_XMLGEN.closeContext(l_qryCtx);
        CLOSE l_ref_cur;
        DBMS_LOB.FREETEMPORARY (l_xml_temp);

-- Standard call to get message count and if count is 1, get message info.

        FND_MSG_PUB.Count_And_Get
        (       p_count         =>      x_msg_count,
                p_data          =>      x_msg_data
        );

-- Write the module name to fnd log file

        IF (l_pLog) THEN
                FND_LOG.STRING (FND_LOG.LEVEL_PROCEDURE,
                                l_module || '.end',
                                '<<< ' || l_api_name);
        END IF;

EXCEPTION
        WHEN FND_API.G_EXC_ERROR THEN
                x_return_status := FND_API.G_RET_STS_ERROR ;
                FND_MSG_PUB.Count_And_Get
                (       p_count         =>      x_msg_count,
                        p_data          =>      x_msg_data
                );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                FND_MSG_PUB.Count_And_Get
                (       p_count         =>      x_msg_count,
                        p_data          =>      x_msg_data);

        WHEN OTHERS THEN
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                IF (l_uLog) THEN
                        FND_LOG.STRING (FND_LOG.LEVEL_UNEXPECTED,
                                        l_module || '.' || l_stmt_num,
                                        SUBSTRB (SQLERRM , 1 , 240));
                END IF;

          IF FND_MSG_PUB.Check_Msg_Level (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
          THEN
                  FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, l_api_name);
          END IF;

          FND_MSG_PUB.Count_And_Get
          (     p_count         =>      x_msg_count,
                p_data          =>      x_msg_data
          );

END Add_ApPoData;

END XX_CST_ApPoAccrualReport_PVT ;
/
