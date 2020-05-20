-- Build the totalnum report in the totalnum_report table
-- Uses the most recent value for each path name in the totalnum table, and obfuscates with the specified censoring threshold and Gaussian sigma
-- e.g., to censor counts under ten and add Gaussian noise with a sigma of 2.8 - exec BuildTotalnumReport 9, 2.8
-- Postgres version, dependent on normal-curve random helper function in the same directory
-- Run by runtotalnum, but example usage:
--     select BuildTotalnumReport(9, 2.8);
-- By Jeff Klann, PhD

     -- Implements SHRINE's obfuscation (with user-specified threshold and sigma)
    -- If the result is less than 10
    --                10 or fewer
    -- else  
     -- Generate some gaussian noise with standard deviation of 6.5
     -- If the absolute value of the noise is greater than 10, use 10
     -- Round the result to the nearest 5
     -- Add the noise to the rounded result
     --  Round the noised result
     -- If the rounded result is less than 10
     --     10 or fewer
     --  Else
     -- The rounded result

CREATE OR REPLACE FUNCTION BuildTotalnumReport(threshold int, sigma float) RETURNS void AS
$BODY$
BEGIN

    truncate table totalnum_report;

    insert into totalnum_report(c_fullname, agg_count, agg_date)
     select c_fullname, case sign(agg_count - threshold + 1 ) when 1 then (round(agg_count/5.0,0)*5)+round(random_normal(1,0,sigma,threshold)) else -1 end agg_count, 
       to_char(agg_date,'YYYY-MM-DD') agg_date from 
       (select row_number() over (partition by c_fullname order by agg_date desc) rn,c_fullname, agg_count,agg_date from totalnum where typeflag_cd like 'P%') x where rn=1;

    update totalnum_report set agg_count=-1 where agg_count<threshold;

END;
$BODY$
 LANGUAGE plpgsql VOLATILE SECURITY DEFINER;