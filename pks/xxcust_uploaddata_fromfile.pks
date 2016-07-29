DROP PACKAGE APPS.XXCUST_UPLOADDATA_FROMFILE;

CREATE OR REPLACE PACKAGE APPS."XXCUST_UPLOADDATA_FROMFILE" 
AUTHID CURRENT_USER IS
/* $Header: xxcust_uploaddata_fromfile.pls 115.01 2008/12/05 23:19:39 Sushil Kumar $ */

  TYPE ColumnArray IS TABLE OF VARCHAR2(240)  INDEX BY BINARY_INTEGER;
  TYPE StringArray IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

  g_file_name   VARCHAR2(100);

/* ----------------------------------------------------------------------- */
/* This procedures will initialize the file name global variable for the   */
/* Current Session                                                         */
/* ----------------------------------------------------------------------- */

  PROCEDURE initialize (p_file_name VARCHAR2);
/* ----------------------------------------------------------------------- */
/* This procedures will delete the records from the target Table based on  */
/* Upload Mode                                                             */
/* ----------------------------------------------------------------------- */
  PROCEDURE upmode_based_delete (p_upmode     IN VARCHAR2
                                 ,p_targetTab IN VARCHAR2
                                 );

/* ----------------------------------------------------------------------- */
/* This procedures will insert the error messages into error details table */
/* ----------------------------------------------------------------------- */
  PROCEDURE insert_error_details(p_rownum  IN NUMBER
                                 ,p_errstr IN VARCHAR2
                                 ,p_erdata IN VARCHAR2
                                 ,p_pid    IN NUMBER);

/* ----------------------------------------------------------------------- */
/* This procedure will read the BLOB file stored in the database          .*/
/* ----------------------------------------------------------------------- */
  PROCEDURE readblob            (p_recordid   IN NUMBER
                                 ,p_processid IN  NUMBER
                                 ,p_delimiter IN VARCHAR2
                                 ,p_targetTab IN VARCHAR2
                                 ,p_dtformat  IN VARCHAR2
                                 ,p_upmode    IN VARCHAR2
                                 ,p_srecord   OUT NUMBER
                                 ,p_precord   OUT NUMBER
                                 ,p_status    OUT VARCHAR2
                                 );

/* ----------------------------------------------------------------------- */
/*	BREAKUP_COLUMNS():						   */
/*	Breaks up concatenated columns into column array.		   */
/*	Returns number of columns found.				   */
/*	Truncates columns longer than MAX_SEG_SIZE bytes.		   */
/*	Raises unhandled exception if any errors.			   */
/* ----------------------------------------------------------------------- */
  FUNCTION breakup_columns      (p_concat_cols  IN  VARCHAR2
			         ,p_delimiter	IN  VARCHAR2
			         ,p_columns	OUT ColumnArray
			         ) RETURN NUMBER;

/* ----------------------------------------------------------------------- */
/*	TO_STRINGARRAY():						   */
/*               Converts concatenated segments to segment array           */
/*      Segment array is 1-based containing entries for 1 <= i <= nsegs    */
/* ----------------------------------------------------------------------- */
  FUNCTION to_stringarray       (catsegs  IN  VARCHAR2
                                 ,sepchar IN  VARCHAR2
                                 ,segs    OUT NOCOPY StringArray
                                 ) RETURN NUMBER;

/* ----------------------------------------------------------------------- */
/* VALIDATECOLS()  						           */
/* This function will validate the first row of the CSV file against the   */
/* target table columns                                                    */
/* ----------------------------------------------------------------------- */
  FUNCTION validatecols        (p_lineArray  IN ColumnArray
                                ,p_targetTab IN VARCHAR2
                                ,p_ncols     IN NUMBER
                                ,p_pid       IN  NUMBER
                                ,p_sqlText   OUT VARCHAR2
                                 )RETURN BOOLEAN;

/* ----------------------------------------------------------------------- */
/* GetFileName()  						           */
/* This function will validate the first row of the CSV file against the   */
/* target table columns                                                    */
/* ----------------------------------------------------------------------- */
  FUNCTION getFileName RETURN VARCHAR2;


END xxcust_uploaddata_fromfile;
/


GRANT EXECUTE ON APPS.XXCUST_UPLOADDATA_FROMFILE TO INTG_XX_NONHR_RO;
