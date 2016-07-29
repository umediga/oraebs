DROP PACKAGE APPS.XX_HR_CONF_LETTER_OAF_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_HR_CONF_LETTER_OAF_PKG" 
AS
   FUNCTION gethrrepname (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2;
   FUNCTION getdirname (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2;
   FUNCTION getdirtitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2;
   FUNCTION gethrreptitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2;
   FUNCTION gethiringmngtitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2;
   FUNCTION getrectitle (x_vacancy_id IN NUMBER)
      RETURN VARCHAR2;
END;
/
