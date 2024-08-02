--==============================================================
-- Database Script to upgrade ONT from 1.8.0 to 1.8.1                 
--==============================================================

Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (72,'T','CRC','edu.harvard.i2b2.crc.exportcsv.defaultescapecharacter','"',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (73,'T','CRC','edu.harvard.i2b2.crc.exportcsv.maxfetchrows','-1',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (74,'T','CRC','edu.harvard.i2b2.crc.exportcsv.defaultlineend','\n',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (75,'T','CRC','edu.harvard.i2b2.crc.exportcsv.defaultseperator','\t',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (76,'T','CRC','edu.harvard.i2b2.crc.exportcsv.resultfetchsize','50000',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (77,'T','CRC','edu.harvard.i2b2.crc.exportcsv.filename','/tmp/{{{PROJECT_ID}}}/{{{DATE_yyyyMMdd}}}_{{{FULL_NAME}}}.csv',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (78,'T','CRC','edu.harvard.i2b2.crc.exportcsv.defaultquotechar','"',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (79,'T','CRC','edu.harvard.i2b2.crc.exportcsv.workfolder','/tmp/i2b2',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (80,'T','CRC','edu.harvard.i2b2.crc.exportcsv.zipencryptmethod','none',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (81,'T','CRC','edu.harvard.i2b2.crc.smtp.host','smtp.site.org',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (82,'T','CRC','edu.harvard.i2b2.crc.smtp.port','25',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (83,'T','CRC','edu.harvard.i2b2.crc.smtp.ssl.enable','false',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (84,'T','CRC','edu.harvard.i2b2.crc.smtp.auth','none',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (85,'T','CRC','edu.harvard.i2b2.crc.smtp.username','none',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (86,'T','CRC','edu.harvard.i2b2.crc.smtp.password','none',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (87,'T','CRC','edu.harvard.i2b2.crc.exportcsv.datamanageremail','datamanager@site.org',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (88,'T','CRC','edu.harvard.i2b2.crc.smtp.enabled','true',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (89,'T','CRC','edu.harvard.i2b2.crc.smtp.from.fullname','Data Manager',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (90,'T','CRC','edu.harvard.i2b2.crc.smtp.from.email','datamanager@site.org',null,null,null,'A');
Insert into HIVE_CELL_PARAMS (ID,DATATYPE_CD,CELL_ID,PARAM_NAME_CD,VALUE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values (91,'T','CRC','edu.harvard.i2b2.crc.smtp.subject','i2b2 Data Request',null,null,null,'A');
  

