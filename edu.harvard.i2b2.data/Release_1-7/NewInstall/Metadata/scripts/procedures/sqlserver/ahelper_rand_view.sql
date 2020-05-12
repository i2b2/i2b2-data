-- Used to get random numbers in a select statement
-- See this blog post for more information: https://weblogs.sqlteam.com/jeffs/2004/11/22/2927/

IF OBJECT_ID('vRandNumber', 'V') IS NOT NULL
DROP VIEW vRandNumber;
GO

CREATE VIEW vRandNumber
AS
SELECT RAND() as RandNumber;
GO