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

    truncate table totalnum_report;

    insert into totalnum_report(c_fullname, agg_count, agg_date)
    select c_fullname, case sign(agg_count - @threshold) when 1 then agg_count+dbo.normalrand(@sigma, 0) else -1 end agg_count, agg_date from 
        (select row_number() over (partition by c_fullname order by agg_date desc) rn,c_fullname, agg_count,agg_date from totalnum where typeflag_cd like 'P%') x where rn=1

END
GO