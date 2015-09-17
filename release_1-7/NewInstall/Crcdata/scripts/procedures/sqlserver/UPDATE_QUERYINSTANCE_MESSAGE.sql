create procedure UPDATE_QUERYINSTANCE_MESSAGE (@message text, @instanceId int , @errorMsg varchar(max) = NULL OUTPUT) as 
begin 
declare @ptrval binary(16), @i int

BEGIN TRY
BEGIN TRANSACTION

select @ptrval = TEXTPTR(message), 
 @i=  datalength(message)
from qt_query_instance
where query_instance_id = @instanceId
 
updatetext qt_query_instance.message @ptrval @i 0 @message

 COMMIT
 END TRY 
 BEGIN CATCH
   if @@TRANCOUNT > 0 
      ROLLBACK
   declare @errMsg nvarchar(4000), @errSeverity int
   select @errMsg = ERROR_MESSAGE(), @errSeverity = ERROR_SEVERITY();
   set @errorMsg = @errMsg;
   RAISERROR(@errMsg,@errSeverity,1);
 END CATCH
end
