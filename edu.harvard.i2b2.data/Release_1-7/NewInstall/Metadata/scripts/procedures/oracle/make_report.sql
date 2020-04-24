-- Build the totalnum report in the totalnum_report table
-- Uses the most recent value for each path name in the totalnum table, and obfuscates with the specified censoring threshold and Gaussian sigma
-- e.g., to censor counts under ten and add Gaussian noise with a sigma of 2.8 - exec BuildTotalnumReport 9, 2.8
-- Oracle version
-- Run by runtotalnum, but example usage:
-- BEGIN
--BuildTotalnumReport(9, 2.8);
--END;
-- By Jeff Klann, PhD

CREATE OR REPLACE PROCEDURE BuildTotalnumReport(threshold in number, sigma in number) AUTHID CURRENT_USER IS
BEGIN

    execute immediate 'truncate table totalnum_report';

    execute immediate 'insert into totalnum_report(c_fullname, agg_count, agg_date)
     select c_fullname, case sign(agg_count - '||threshold||') when 1 then agg_count+round(dbms_random.normal*'||sigma||',0) else -1 end agg_count, agg_date from 
       (select row_number() over (partition by c_fullname order by agg_date desc) rn,c_fullname, agg_count,agg_date from totalnum where typeflag_cd like ''P%'') x where rn=1';

END;
GO
