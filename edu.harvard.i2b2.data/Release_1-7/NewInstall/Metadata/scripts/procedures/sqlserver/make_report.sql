-- Build the totalnum report in the totalnum_report table
-- Uses the most recent value for each path name in the totalnum table, and obfuscates with the specified censoring threshold and Gaussian sigma
-- e.g., to censor counts under ten and add Gaussian noise with a sigma of 2.8 - exec BuildTotalnumReport 9, 2.8
-- Dependent on the random helper functions in this directory
-- By Jeff Klann, PhD

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'BuildTotalnumReport')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE BuildTotalnumReport;
GO

CREATE PROCEDURE [dbo].[BuildTotalnumReport](@threshold int, @sigma float) AS
BEGIN

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
         
    truncate table totalnum_report;

    insert into totalnum_report(c_fullname, agg_count, agg_date)
    select c_fullname, case sign(agg_count+1 - @threshold) when 1 then round(agg_count/5.0,0)*5+dbo.normalrand(@sigma, 0, @threshold) else -1 end agg_count, agg_date from 
        (select row_number() over (partition by c_fullname order by agg_date desc) rn,c_fullname, agg_count,agg_date from totalnum where typeflag_cd like 'P%') x where rn=1;
        
    update totalnum_report set agg_count=-1 where agg_count<@threshold;

END
GO