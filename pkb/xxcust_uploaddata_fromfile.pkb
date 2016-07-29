DROP PACKAGE BODY APPS.XXCUST_UPLOADDATA_FROMFILE;

CREATE OR REPLACE PACKAGE BODY APPS."XXCUST_UPLOADDATA_FROMFILE" 
IS
/* $Header: xxcust_uploaddata_fromfile.pls 115.01 2008/12/05 23:19:39 Sushil Kumar $ */

  FLEX_DELIMITER_ESCAPE CONSTANT VARCHAR2(1) := '\';
  MAX_SEG_SIZE		CONSTANT NUMBER := 240;


/* ----------------------------------------------------------------------- */
/*	Breaks up concatenated segments into segment array.		   */
/*	Returns number of segments found.				   */
/*	Truncates segments longer than MAX_SEG_SIZE bytes.		   */
/*	Raises unhandled exception if any errors.			   */
/* ----------------------------------------------------------------------- */
  FUNCTION breakup_columns(p_concat_cols  IN  VARCHAR2
			   ,p_delimiter	  IN  VARCHAR2
			   ,p_columns	  OUT ColumnArray)
    RETURN NUMBER
    IS
      n_cols	 NUMBER;
      str        StringArray;
  BEGIN
     n_cols := to_stringarray(p_concat_cols,p_delimiter, str);
     FOR i IN 1..n_cols LOOP
	p_columns(i) := SUBSTRB(str(i), 1, MAX_SEG_SIZE);
     END LOOP;
     RETURN(n_cols);
  EXCEPTION
     WHEN OTHERS THEN
	--insert_Error_details(SQLERRM);
	RAISE;
  END breakup_columns;

/* ----------------------------------------------------------------------- */
/*               Converts concatenated segments to segment array           */
/*      Segment array is 1-based containing entries for 1 <= i <= nsegs    */
/* ----------------------------------------------------------------------- */
  FUNCTION to_stringarray(catsegs  IN  VARCHAR2
                          ,sepchar IN  VARCHAR2
                          ,segs    OUT NOCOPY StringArray)
    RETURN NUMBER
    IS
       l_wc         VARCHAR2(10);
       l_flex_value VARCHAR2(2000);
       i            NUMBER;
       l_segnum     NUMBER;
       l_delimiter  VARCHAR2(10);
  BEGIN
     l_delimiter := SUBSTR(sepchar, 1, 1);

     --
     -- Make sure delimiter is valid.
     --
     IF ((l_delimiter IS NULL) OR (l_delimiter = FLEX_DELIMITER_ESCAPE)) THEN
        RAISE_APPLICATION_ERROR(-20001,
                                'SV2.to_stringarray. Invalid delimiter:''' ||
                                NVL(sepchar, '<NULL>') || '''');
     END IF;

     --
     -- If catsegs is NULL then assume there is only one segment.
     --
     IF (catsegs IS NULL) THEN
        l_segnum := 1;
        segs(1) := catsegs;
        GOTO return_success;
     END IF;

     l_segnum := 0;
     i := 1;

     --
     -- Loop for each segment.
     --
     LOOP
        l_flex_value := NULL;

        --
        -- Un-escaping loop.
        --
        LOOP

           l_wc := SUBSTR(catsegs, i, 1);
           i := i + 1;

           IF (l_wc IS NULL) THEN
              EXIT;
            ELSIF (l_wc = l_delimiter) THEN
              EXIT;
            ELSIF (l_wc = FLEX_DELIMITER_ESCAPE) THEN

              l_wc := SUBSTR(catsegs, i, 1);
              i := i + 1;

              IF (l_wc IS NULL) THEN
                 EXIT;
              END IF;

           END IF;

           l_flex_value := l_flex_value || l_wc;

        END LOOP;

        l_segnum := l_segnum + 1;
        segs(l_segnum) := l_flex_value;
        IF (l_wc IS NULL) THEN
           EXIT;
        END IF;
     END LOOP;

     <<return_success>>
       RETURN(l_segnum);

  EXCEPTION
     WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'SV2.to_stringarray. SQLERRM : ' ||
                                SQLERRM);
  END to_stringarray;

/* ----------------------------------------------------------------------- */
/* This procedures will insert the error messages into error details table */
/* ----------------------------------------------------------------------- */
  PROCEDURE insert_error_details(p_rownum  IN NUMBER
                                 ,p_errstr IN VARCHAR2
                                 ,p_erdata IN VARCHAR2
                                 ,p_pid    IN NUMBER)
  IS
     PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     INSERT INTO xxcust_uploaddata_fromfile_err
                                       (record_id
                                        ,err_msg
                                        ,err_data
                                        ,process_id
                                       )
                                 VALUES(p_rownum
                                       ,p_errstr
                                       ,p_erdata
                                       ,p_pid);
     COMMIT;
  END;

/* ----------------------------------------------------------------------- */
/* This procedures will delete the records from the target Table based on  */
/* Upload Mode                                                             */
/* ----------------------------------------------------------------------- */
  PROCEDURE upmode_based_delete (p_upmode     IN VARCHAR2
                                 ,p_targetTab IN VARCHAR2
                                 )

  IS
     v_sqlText  VARCHAR2(200);
  BEGIN
     insert_error_details(1,'delete the records from the target Table based on Upload Mode=>1','upmode_based_delete',1);
     IF p_upmode = 'REPLACE' THEN
        v_sqlText := 'DELETE FROM '||p_targetTab;

        EXECUTE IMMEDIATE v_sqlText;
     END IF;
     insert_error_details(1,'delete the records from the target Table based on Upload Mode=>2','upmode_based_delete',1);
  END upmode_based_delete;

/* ----------------------------------------------------------------------- */
/* VALIDATECOLS()  						           */
/* This function will validate the first row of the CSV file against the   */
/* target table columns                                                    */
/* ----------------------------------------------------------------------- */
  FUNCTION validatecols        (p_lineArray  IN  ColumnArray
                                ,p_targetTab IN  VARCHAR2
                                ,p_ncols     IN  NUMBER
                                ,p_pid       IN  NUMBER
                                ,p_sqlText   OUT VARCHAR2
                                )
    RETURN BOOLEAN
    IS
      v_colarray ColumnArray;
      n_tcols    NUMBER;
      b_status   BOOLEAN := TRUE;
      n_matched  NUMBER  := 0;
      e_invalid_col     EXCEPTION;
  BEGIN
     -- Validate the target Table

     --insert_error_details(1,'Validate the target Table =>1','validatecols',p_pid);
     SELECT 1
       INTO n_matched
       FROM dba_objects
      WHERE object_name = p_targetTab
        AND object_type = 'TABLE';

     -- insert_error_details(1,'BULK collect the target table columns =>2','validatecols',p_pid);
     -- BULK collect the target table columns
     SELECT column_name BULK COLLECT
       INTO v_colarray
       FROM all_tab_columns
      WHERE table_name = p_targetTab
      ;

     --insert_error_details(1,'Prepare the DML statement SQLTex =>2','validatecols',p_pid);
     -- Prepare the DML statement SQLText

     p_sqlText := 'INSERT INTO '||p_targetTab||'(';
     -- Loop to compare the column names
     IF p_lineArray.count<=0 THEN
        RAISE e_invalid_col;
     END IF;

     FOR lp_ctr IN 1..p_lineArray.count
     LOOP
        FOR ilp_ctr IN 1..v_colarray.count
        LOOP
           IF upper(trim(p_lineArray(lp_ctr))) = upper(trim(v_colarray(ilp_ctr))) THEN
              n_matched := 0;
              p_sqlText := p_sqlText||p_lineArray(lp_ctr)||',';
              DBMS_OUTPUT.PUT_LINE('Matched p_linearray('||lp_ctr||')->'||p_linearray(lp_ctr)||'=='||v_colarray(ilp_ctr));
              EXIT;
           ELSE
              n_matched := 1;
              DBMS_OUTPUT.PUT_LINE('Not Matched p_linearray('||lp_ctr||')->'||trim(p_lineArray(lp_ctr))||'<>'||v_colarray(ilp_ctr));
           END IF;
        END LOOP;
        IF n_matched = 1 THEN
          insert_error_details(1,'Column name entered in source file are invalid',p_lineArray(lp_ctr),p_pid);
          b_status := FALSE;
        END IF;
     END LOOP;
     p_sqlText := SUBSTR(p_sqlText,1,LENGTH(p_sqlText) - 1)||') VALUES(';
     RETURN b_status;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        insert_error_details(0,'Invalid Target Table -> '||p_targetTab,p_targetTab,p_pid);
        RETURN FALSE; -- Return Error
     WHEN OTHERS THEN
        RETURN FALSE;
  END validatecols;

/* ----------------------------------------------------------------------- */
/* This procedure will read the BLOB file stored in the database          .*/
/* ----------------------------------------------------------------------- */
  PROCEDURE readblob            (p_recordid   IN  NUMBER
                                 ,p_processid IN  NUMBER
                                 ,p_delimiter IN  VARCHAR2
                                 ,p_targetTab IN  VARCHAR2
                                 ,p_dtformat  IN  VARCHAR2
                                 ,p_upmode    IN  VARCHAR2
                                 ,p_srecord   OUT NUMBER
                                 ,p_precord   OUT NUMBER
                                 ,p_status    OUT VARCHAR2
                                 )
   IS
     v_blob_data       BLOB;
     v_blob_len        NUMBER;
     v_position        NUMBER;
     v_raw_chunk       RAW(10000);
     v_char            CHAR(1);
     c_chunk_len       NUMBER             := 1;
     v_line            VARCHAR2 (32767)   := NULL;
     v_data_array      ColumnArray;
     n_lpcntr          NUMBER             := 0;
     n_status          NUMBER             := 0;
     n_rcdcntr         NUMBER             := 0;
     e_invalid_col     EXCEPTION;
     e_invalid_tab     EXCEPTION;
     n_cols            NUMBER;
     v_sqlText         VARCHAR2(32767)    := NULL;
     v_sqlText2        VARCHAR2(32767)    := NULL;
     v_dataTxt         VARCHAR2(2000)     := NULL;
     v_dtformat        VARCHAR2(100)      := NULL;
     n_matched         NUMBER;
  BEGIN
     -- set the cursor_sharing mode to force for this session
     EXECUTE IMMEDIATE 'alter session set cursor_sharing=force';

     -- set the date format for this session
     v_sqlText := 'alter session set nls_date_format ='''||p_dtformat||'''';
     EXECUTE IMMEDIATE v_sqlText;
     v_sqlText := NULL;

     p_status  := 'S';
     dbms_output.put_line('Validate the target Table =>STG_READLOB');
     -- Validate the target Table
     BEGIN
       SELECT 1
         INTO n_matched
         FROM dba_objects
        WHERE upper(object_name) = upper(p_targetTab)
          AND object_type = 'TABLE'
        ;
     dbms_output.put_line('Validate the target Table =>STG_READLOB=>SUCCESS');
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
          RAISE e_invalid_tab;
     END;
     --insert_error_details(n_lpcntr,'Call procedure to delete the data from Target Table','STG_DELETE',p_processid);
     -- Call procedure to delete the data from Target Table
     dbms_output.put_line('delete the data from Target Table =>STG_READLOB');
     upmode_based_delete(p_upmode, p_targetTab);
     dbms_output.put_line('delete the data from Target Table =>STG_READLOB=>SUCCESS');
     --insert_error_details(n_lpcntr,'After =>',''STG_DELETE'',p_processid);
     -- Read data from xxcust_uploaddata_fromfile_tab
     BEGIN
        --insert_error_details(n_lpcntr,'Read data from xxcust_uploaddata_fromfile_tab =>1','STG_READBLOB',p_processid);
        dbms_output.put_line('Read data from xxcust_uploaddata_fromfile_tab =>STG_READLOB');
        SELECT xls_blob
          INTO v_blob_data
          FROM xxcust_uploaddata_fromfile_tab
         WHERE record_id = p_recordid
         ;
         dbms_output.put_line('Read data from xxcust_uploaddata_fromfile_tab =>STG_READLOB=>SUCCESS');
        --insert_error_details(n_lpcntr,'Read data from xxcust_uploaddata_fromfile_tab =>2','STG_READBLOB',p_processid);
     EXCEPTION
        WHEN OTHERS THEN
            insert_error_details(n_lpcntr,'Read data from xxcust_uploaddata_fromfile_tab'||SQLERRM,SQLCODE,p_processid);
            RAISE;
     END;

     v_blob_len := dbms_lob.getlength(v_blob_data);
     v_position := 1;

     dbms_output.put_line('Read data from xxcust_uploaddata_fromfile_tab =>STG_READLOB=>BLOB_LEN=>'||v_blob_len);
     -- Read and convert binary to char
     WHILE ( v_position <= v_blob_len )
     LOOP
       v_raw_chunk := dbms_lob.substr(v_blob_data,c_chunk_len,v_position);
       v_char      := utl_raw.cast_to_varchar2(v_raw_chunk);
       v_line      := v_line || v_char;
       v_position  := v_position + c_chunk_len;
       --dbms_output.put_line(v_line||'~~~~'||v_char);
       -- When a whole line is retrieved
       IF v_char = CHR(10) THEN
          -- Convert comma to : to use wwv_flow_utilities
          -- v_line := REPLACE (v_line, ',', ':');
          v_line := REPLACE(REPLACE(v_line,CHR(13),''),CHR(10),'');
          -- Convert each column separated by : into array of data
          dbms_output.put_line('Convert each column separated by : into array of data'||n_cols);
          n_cols   := breakup_columns (v_line,p_delimiter,v_data_array);
          n_lpcntr := n_lpcntr + 1;

          dbms_output.put_line('Convert each column separated by : into array of data=>SUCCESS'||n_cols);

          -- Validate the first row of the CSV for Valid Column Name.
          IF n_lpcntr = 1 THEN
             dbms_output.put_line('Validate the first row of the CSV for Valid Column Name.=>'||n_lpcntr);
             IF NOT validatecols(v_data_array,p_targetTab,n_cols,p_processid,v_sqlText2) THEN
                dbms_output.put_line('Validate the first row of the CSV for Valid Column Name.=>RAISE'||n_lpcntr);
                RAISE e_invalid_col;
             END IF;
             dbms_output.put_line('Validate the first row of the CSV for Valid Column Name.=>SUCCESS'||n_cols);
          ELSE
             v_sqlText := v_sqlText2;
             v_dataTxt := NULL;
             FOR lp_ctr IN 1..n_cols
             LOOP
                v_data_array(lp_ctr) := replace(v_data_array(lp_ctr),chr(39),chr(39)||chr(39));
                v_sqlText := ltrim(rtrim(v_sqlText))||''''||ltrim(rtrim(v_data_array(lp_ctr)))||''',';
                v_dataTxt := ltrim(rtrim(v_dataTxt))||''''||ltrim(rtrim(v_data_array(lp_ctr)))||''',';
             END LOOP;

             v_sqlText := SUBSTR(v_sqlText,1,LENGTH(v_sqlText) - 1)||')';
             -- Insert data into target table
             BEGIN
               DBMS_OUTPUT.PUT_LINE('SQLQuery ->'||ltrim(rtrim(v_sqlText)));
               EXECUTE IMMEDIATE v_sqlText;
               n_rcdcntr := n_rcdcntr + 1;
             EXCEPTION
               WHEN OTHERS THEN
                 insert_error_details(n_lpcntr,SQLERRM,SUBSTR(v_dataTxt,1,1000),p_processid);
                 p_status := 'E';
             END;
          END IF;

          -- Clear out
          v_line := NULL;
       END IF;
     END LOOP;
     p_srecord:=n_rcdcntr;
     p_precord:=n_lpcntr - 1;
     -- Reset the cursor_sharing mode to force for this session
     EXECUTE IMMEDIATE 'alter session set cursor_sharing=exact';

  EXCEPTION
     WHEN e_invalid_tab THEN
        -- Reset the cursor_sharing mode to force for this session
        insert_error_details(n_lpcntr,'	Target table not found ',p_targetTab,p_processid);
        EXECUTE IMMEDIATE 'alter session set cursor_sharing=exact';
        DBMS_OUTPUT.PUT_LINE('Target Table Validation Failed');
        p_status := 'E';
     WHEN e_invalid_col THEN
        insert_error_details(n_lpcntr,'Column name mismatch, check the source file Header Row',v_line,p_processid);
        EXECUTE IMMEDIATE 'alter session set cursor_sharing=exact';
        DBMS_OUTPUT.PUT_LINE('Record Header Validation Failed');
        p_status := 'E';
     WHEN NO_DATA_FOUND THEN
        insert_error_details(n_lpcntr,'Input file not found for record id#'||p_recordid,NULL,p_processid);
        EXECUTE IMMEDIATE 'alter session set cursor_sharing=exact';
        DBMS_OUTPUT.PUT_LINE('Input file not found for record id#'||p_recordid);
        p_status := 'E';
     WHEN OTHERS THEN
        -- Reset the cursor_sharing mode to force for this session
        insert_error_details(n_lpcntr,'Problem in Reading the File '||SQLERRM||'=>'||v_sqlText,NULL,p_processid);
        EXECUTE IMMEDIATE 'alter session set cursor_sharing=exact';
        DBMS_OUTPUT.PUT_LINE('Problem in Reading the File'||SQLERRM);
        p_status := 'E';
  END readblob;
  -----------------------------------------------
  PROCEDURE initialize (p_file_name VARCHAR2)
  IS
  BEGIN
    g_file_name := p_file_name;
  END initialize;
  -----------------------------------------------
  FUNCTION getFileName RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_file_name;
  END getFileName;
  -----------------------------------------------
END xxcust_uploaddata_fromfile;
/


GRANT EXECUTE ON APPS.XXCUST_UPLOADDATA_FROMFILE TO INTG_XX_NONHR_RO;
