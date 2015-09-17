CREATE OR REPLACE  PROCEDURE REMOVE_TEMP_TABLE(tempTableName VARCHAR) 
IS
BEGIN 
	execute immediate 'drop table ' || tempTableName || ' cascade constraints';
	
EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line(SQLCODE|| ' - ' ||SQLERRM);
END;

