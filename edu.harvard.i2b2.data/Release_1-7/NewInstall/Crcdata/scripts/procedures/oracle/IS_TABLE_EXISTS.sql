CREATE OR REPLACE FUNCTION ISTABLEEXISTS(tableName IN VARCHAR) 
    RETURN VARCHAR
IS 
	 cursor c is select table_name from user_tables where table_name = tableName;
	  x varchar(100);
	  flag varchar(10) := 'FALSE';
BEGIN 
	open c;
    fetch c into x;
    if (c%NOTFOUND) then
		flag := 'FALSE';
	else
		flag := 'TRUE';
	end if;		
	close c;	
	return flag;
		
EXCEPTION
WHEN OTHERS THEN
      raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);		
END;

