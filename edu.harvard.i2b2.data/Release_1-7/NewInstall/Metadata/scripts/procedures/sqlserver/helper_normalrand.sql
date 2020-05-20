-- Generate a random number from a normal distribution. Specify the desired sigma and precision.
-- Also, if the noise is greater than threshold, returns the threshold.
-- Dependent on the helper view for random numbers, in the same directory.
-- Inspired by: 
--   Returning random numbers in select statements - https://weblogs.sqlteam.com/jeffs/2004/11/22/2927/
--   Generating a normal distribution in MSSQL - https://www.mssqltips.com/sqlservertip/4233/sql-server-tsql-code-to-generate-a-normal-distribution/
-- By Jeff Klann, PhD

IF OBJECT_ID('vRandNumber', 'V') IS NOT NULL
DROP VIEW vRandNumber;
GO

CREATE VIEW vRandNumber
AS
SELECT RAND() as RandNumber;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NormalRand]') AND type in (N'FN', N'IF',N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[NormalRand]
GO

CREATE FUNCTION NormalRand(@sigma float, @precision int, @threshold int)
RETURNS float
AS
  BEGIN
  DECLARE @noise float;
  SET @noise = (SELECT round((sqrt(-2.0*log(r1.RandNumber))*cos(2*pi()*r2.RandNumber))*@sigma, @precision) FROM vRandNumber r1 cross join vRandNumber r2);
  -- NEWER APPROACH THAT DOESN'T QUITE WORK: SET @noise = (SELECT round((sqrt(-2.0*log(ABS(BINARY_CHECKSUM(NEWID())/2147483648.0)))*cos(2*pi()*ABS(BINARY_CHECKSUM(NEWID())/2147483648.0)))*@sigma, @precision) );
  IF @noise>@threshold SET @noise=@threshold;
  IF @noise<-1*@threshold SET @noise=-1*@threshold;
  
  RETURN @noise 
  END;
 
GO