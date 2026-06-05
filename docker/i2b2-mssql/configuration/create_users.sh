for X in i2b2demodata i2b2hive i2b2imdata i2b2metadata i2b2pm i2b2workdata; do
echo "use $X;CREATE LOGIN $X WITH PASSWORD ='Demouser123';
CREATE USER [$X] FOR LOGIN [$X] ;
EXEC sp_addrolemember [db_owner], [$X];"
done
