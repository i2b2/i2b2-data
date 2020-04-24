-- EndTime is a simple helper procedure to assist with printing timestamped debug messages
-- Example usage:
--   EXEC EndTime @startime,'dimension','ontology';
--   set @startime = getdate();
CREATE PROCEDURE EndTime @startime datetime,@label varchar(100),@label2 varchar(100)
AS
    declare @duration varchar(30);
BEGIN
    --set @duration = format(getdate()-@startime, 'ss.fff'); -- OLD MSSQL VERSIONS - ONVERT( VARCHAR(24), getdate()-@startime, 121) ;
    set @duration = datediff(second,@startime,getdate());
    RAISERROR('(BENCH) %s,%s,%s',0,1,@label,@label2,@duration) WITH NOWAIT;
END;