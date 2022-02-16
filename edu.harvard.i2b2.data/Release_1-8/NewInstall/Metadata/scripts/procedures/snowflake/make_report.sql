-----------------------------------------------------------------------------------------------------------------
/*********************************************************
*         SNOWFLAKE IMPLEMENATION FOR RUNNING BuildTotalnumReport FUNCTION
*         Based on implementation from Postgresql
*         MD SABER HOSSAIN	7/14/2023
/*        University of Missouri-Columbia			
**********************************************************/

CREATE OR REPLACE PROCEDURE BuildTotalnumReport(
    threshold int, 
    sigma float
) 
RETURNS INT NULL 
LANGUAGE SQL
AS
DECLARE
    rand_normal FLOAT;
BEGIN
    truncate table totalnum_report;
    call random_normal(0,:sigma,:threshold) into :rand_normal;
    insert into totalnum_report(c_fullname, agg_count, agg_date)
    select 
        c_fullname
        , case sign(agg_count - :threshold + 1 )
        when 1 then (round(agg_count/5.0,0)*5)+round(:rand_normal)
        else -1 
    end agg_count
    , to_char(agg_date,'YYYY-MM-DD') agg_date 
    from (
        select * from (
            select row_number() over (
                partition by c_fullname order by agg_date desc
            ) rn,
            c_fullname
            , agg_count
            , agg_date 
            from totalnum 
            where typeflag_cd like 'P%'
        ) x 
        where rn=1
    ) y;

    update totalnum_report set agg_count=-1 where agg_count<:threshold;
END;
            