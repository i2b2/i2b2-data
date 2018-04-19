create table pm_user_login 
	(
		user_id varchar(50) not null,
		attempt_cd varchar(50) not null,
		entry_date timestamp not null,
		changeby_char varchar(50),
		status_cd varchar(50) constraint pm_user_login_pk primary key(entry_date, user_id) 
	)
;


--==================================================================
-- PostgreSQL Database Script to upgrade CRC from 1.7.09c to 1.7.10                  
--==================================================================

-- Drop primary key and add new index

alter table pm_user_login
	drop constraint if exists pm_user_login_pk cascade 
;

create index pm_user_login_idx on pm_user_login(user_id, entry_date)
;
