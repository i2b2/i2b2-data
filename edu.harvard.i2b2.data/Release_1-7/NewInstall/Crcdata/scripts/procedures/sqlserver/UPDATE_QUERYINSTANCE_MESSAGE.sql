IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(UPDATE_QUERYINSTANCE_MESSAGE')
                    AND type IN ( N'P', N'PC' ) ) 
DROP PROCEDURE UPDATE_QUERYINSTANCE_MESSAGE;
GO

create procedure UPDATE_QUERYINSTANCE_MESSAGE (@message  varchar(MAX), @instanceId int , @errorMsg varchar(MAX) = NULL OUTPUT) as 
begin 

BEGIN TRY
BEGIN TRANSACTION

update qt_query_instance set message = @message where query_instance_id = @instanceId

 COMMIT
 END TRY 
 BEGIN CATCH
   if @@TRANCOUNT > 0 
      ROLLBACK
   declare @errMsg nvarchar(MAX), @errSeverity int
   select @errMsg = ERROR_MESSAGE(), @errSeverity = ERROR_SEVERITY();
   set @errorMsg = @errMsg;
   RAISERROR(@errMsg,@errSeverity,1);
 END CATCH
end
