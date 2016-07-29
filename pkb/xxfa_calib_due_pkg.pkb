DROP PACKAGE BODY APPS.XXFA_CALIB_DUE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXFA_CALIB_DUE_PKG" AS

  FUNCTION AFTERPFORM RETURN BOOLEAN IS


    BEGIN



    --Added by Meghana:
    BEGIN

    IF P_DUE_FROM_DATE IS NOT NULL AND P_DUE_TO_DATE IS NOT NULL THEN

     LP_DUE_DATE_RANGE := ' and to_date(wo.scheduled_start_date,''DD-MON-YY'') between ' || 'to_date(''' || P_DUE_FROM_DATE || ''',' || '''DD-MON-YY''' || ')' || ' and ' || 'to_date(''' || P_DUE_TO_DATE || ''',' || '''DD-MON-YY''' || ')';

      ELSIF P_DUE_FROM_DATE IS NOT NULL AND P_DUE_TO_DATE IS NULL THEN
        LP_DUE_DATE_RANGE := 'and to_date(wo.scheduled_start_date,''DD-MON-YY'') >= ' || 'to_date(''' || P_DUE_FROM_DATE || ''',' || '''DD-MON-YY''' || ')';
      ELSIF P_DUE_FROM_DATE IS NULL AND P_DUE_TO_DATE IS NOT NULL THEN
        LP_DUE_DATE_RANGE := 'and to_date(wo.scheduled_start_date,''DD-MON-YY'') <=  ' || 'to_date(''' || P_DUE_TO_DATE || ''',' || '''DD-MON-YY''' || ')';
      ELSE
        LP_DUE_DATE_RANGE := ' and 1 = 1';
      END IF;

    IF (LP_DUE_DATE_RANGE IS NULL) THEN
    LP_DUE_DATE_RANGE := ' ';
    END IF;

    END;
    -- End of addition



    RETURN (TRUE);
  END AFTERPFORM;

END XXFA_CALIB_DUE_PKG;
/
