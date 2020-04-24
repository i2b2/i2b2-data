-- Generate a random number from a normal distribution. Specify the desired sigma and precision.
-- Dependent on the helper view for random numbers, in the same directory.
-- Inspired by: 
--   Returning random numbers in select statements - https://weblogs.sqlteam.com/jeffs/2004/11/22/2927/
--   Generating a normal distribution in MSSQL - https://www.mssqltips.com/sqlservertip/4233/sql-server-tsql-code-to-generate-a-normal-distribution/
-- By Jeff Klann, PhD
CREATE FUNCTION NormalRand(@sigma float, @precision int)
RETURNS float
AS
  BEGIN
  RETURN (SELECT round((sqrt(-2.0*log(r1.RandNumber))*cos(2*pi()*r2.RandNumber))*@sigma, @precision) FROM vRandNumber r1 cross join vRandNumber r2) 
  END;
  
