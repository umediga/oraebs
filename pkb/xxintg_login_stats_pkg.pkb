DROP PACKAGE BODY APPS.XXINTG_LOGIN_STATS_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XXINTG_LOGIN_STATS_PKG" 
AS

PROCEDURE insert_stg_prc 
            (errbuf  out varchar2, 
             errcode out varchar2
            ) 
IS
   
CURSOR  log_stats_info_cur
IS
     SELECT DISTINCT icx.session_id,f.RESPONSIBILITY_NAME, icx.user_id,fu.user_name,fu.description, atl.application_name
     FROM   apps.icx_sessions icx, apps.fnd_user fu, apps.fnd_responsibility_vl f, apps.fnd_application_tl atl
     WHERE  disabled_flag   != 'Y'
     AND    icx.pseudo_flag  = 'N'
     AND    f.responsibility_id = icx.responsibility_id
     AND    (last_connect + 
               DECODE (fnd_profile.VALUE ('ICX_SESSION_TIMEOUT'),
                       NULL, limit_time,
                       0   , limit_time,
                       apps.fnd_profile.VALUE ('ICX_SESSION_TIMEOUT')/60) / 24) > SYSDATE
     AND    icx.counter          < limit_connects
     AND    icx.user_id          = fu.user_id
     AND    atl.language         = 'US'
     AND    atl.application_id  = f.application_id;
     
   
       a                     varchar2(2400) := '';
       b                     varchar2(2400) := '';



       e_exception            exception;

   
BEGIN

     FOR G IN log_stats_info_cur LOOP

           BEGIN --  begin1

            -- Initialize Values


             BEGIN   --  begin2   
             
                INSERT INTO xxintg_login_stats_tbl
            (
            session_id            ,
            responsibility_name   ,
            user_id               ,
            user_name             ,
            description           ,
            application_name      ,
            creation_date         ,
            created_by            ,
            last_updated_by       ,
            last_update_date      ,
            time_stamp          ,
            extra_segment1        ,
            extra_segment2        ,
            extra_segment3        ,
            extra_segment4        
            )
            VALUES
            (
            G.session_id          ,
            G.responsibility_name ,
            G.user_id          ,
            G.user_name           ,
            G.description         ,
            G.application_name    ,
            sysdate               ,
            -1              ,
            -1              ,
            sysdate              ,
            --TO_CHAR(Sysdate,'HH12:MI:SS PM'),
            trunc(sysdate) || ' - ' || TO_CHAR(Sysdate,'HH12:MI:SS PM'),
            null              ,
            null              ,
            null              ,
            null
            );
            
            
             COMMIT;    


            EXCEPTION
            WHEN OTHERS THEN
            
              RAISE e_exception;               
             
             END; --  begin2


        EXCEPTION
        
        WHEN   e_exception THEN
        
          fnd_file.put_line(fnd_file.output,'In e_exception');
        
        WHEN OTHERS THEN
                         
          fnd_file.put_line(fnd_file.output,'When others error while inserting into xxintg_login_stats_tbl');
          fnd_file.put_line(fnd_file.output,'Error is ... '||sqlerrm);
          fnd_file.put_line(fnd_file.output,' SQLCODE = '||sqlcode);
          fnd_file.put_line(fnd_file.output,'SQLERRM = '||substr(sqlerrm,1,150));    
           
           END; -- begin1
           
           
     END LOOP;   
     
  EXCEPTION
  WHEN OTHERS THEN
  
          fnd_file.put_line(fnd_file.output,'When Others error in insert_stg_prc!');
          fnd_file.put_line(fnd_file.output,'Error is ... '||sqlerrm);
          fnd_file.put_line(fnd_file.output,' SQLCODE = '||sqlcode);
          fnd_file.put_line(fnd_file.output,'SQLERRM = '||substr(sqlerrm,1,150));

END;

END XXINTG_Login_Stats_Pkg; 
/
