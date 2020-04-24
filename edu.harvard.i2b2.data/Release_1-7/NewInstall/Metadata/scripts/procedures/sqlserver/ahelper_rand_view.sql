-- Used to get random numbers in a select statement
-- See this blog post for more information: https://weblogs.sqlteam.com/jeffs/2004/11/22/2927/

CREATE VIEW vRandNumber
AS
SELECT RAND() as RandNumber;
