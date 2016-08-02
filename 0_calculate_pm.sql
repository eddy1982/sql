
drop table if exists calculate_pm._temp;
create table calculate_pm._temp engine = myisam
SELECT * 
FROM calculate_pm.action_log_filtered_2015
where uri regexp '^(/visit_member[[.period.]]php).*(rp=USE).*';
drop table if exists calculate_pm._temp_1;
create table calculate_pm._temp_1 engine = myisam
select a.d, a.p, a.platform_type, count(a.p) as click
from (
	SELECT userid, substr(uri,locate('rp=',uri)+3,7) as p, date(time) as d, platform_type 
	FROM calculate_pm._temp) as a
group by a.d, a.p, a.platform_type;
update calculate_pm._temp_1 set p = replace(p,'&','');
drop table if exists calculate_pm._p_visitmember_use_2015;
create table calculate_pm._p_visitmember_use_2015 engine = myisam
select a.d, a.platform_type, a.p1, sum(a.click) as click
from (
	SELECT d, p, platform_type, click, substr(p, locate('_',p)+1,2) as p1 
	FROM calculate_pm._temp_1
	where p regexp '.*(_SB|_RS|_RV|_HB)$') as a
group by a.d, a.platform_type, a.p1;

drop table if exists calculate_pm._temp;
create table calculate_pm._temp engine = myisam
SELECT * 
FROM calculate_pm.action_log_filtered_2016
where uri regexp '^(/visit_member[[.period.]]php).*(rp=USE).*';
drop table if exists calculate_pm._temp_1;
create table calculate_pm._temp_1 engine = myisam
select a.d, a.p, a.platform_type, count(a.p) as click
from (
	SELECT userid, substr(uri,locate('rp=',uri)+3,7) as p, date(time) as d, platform_type 
	FROM calculate_pm._temp) as a
group by a.d, a.p, a.platform_type;
update calculate_pm._temp_1 set p = replace(p,'&','');
drop table if exists calculate_pm._p_visitmember_use_2016;
create table calculate_pm._p_visitmember_use_2016 engine = myisam
select a.d, a.platform_type, a.p1, sum(a.click) as click
from (
	SELECT d, p, platform_type, click, substr(p, locate('_',p)+1,2) as p1 
	FROM calculate_pm._temp_1
	where p regexp '.*(_SB|_RS|_RV|_HB)$') as a
group by a.d, a.platform_type, a.p1;


drop table if exists calculate_pm._temp;
create table calculate_pm._temp engine = myisam
SELECT userid, uri, date(time) as d, platform_type  
FROM calculate_pm.action_log_filtered_2015
where uri regexp '^(/usersearch[[.period.]]php).*(searchuser).*';
drop table if exists calculate_pm._p_usersearch_2015;
create table calculate_pm._p_usersearch_2015 engine = myisam
SELECT d, platform_type, count(uri) as search_count 
FROM calculate_pm._temp
group by d, platform_type;

drop table if exists calculate_pm._temp;
create table calculate_pm._temp engine = myisam
SELECT userid, uri, date(time) as d, platform_type  
FROM calculate_pm.action_log_filtered_2016
where uri regexp '^(/usersearch[[.period.]]php).*(searchuser).*';
drop table if exists calculate_pm._p_usersearch_2016;
create table calculate_pm._p_usersearch_2016 engine = myisam
SELECT d, platform_type, count(uri) as search_count 
FROM calculate_pm._temp
group by d, platform_type;












drop table if exists calculate_pm._p_predict_scale_2015;
create table calculate_pm._p_predict_scale_2015 engine = myisam
SELECT * 
FROM calculate_pm.action_log_filtered_2015
where uri regexp '^(/predictgame[[.period.]]php).*(action=scale).*';

drop table if exists calculate_pm._temp;
create table calculate_pm._temp engine = myisam
SELECT * 
FROM calculate_pm.action_log_filtered_2016
where uri regexp '^(/predictgame[[.period.]]php).*(action=scale).*';

drop table if exists calculate_pm._p_predict_scale_2016;
create table calculate_pm._p_predict_scale_2016 engine = myisam
select a.d, a.platform_type, a.sid, count(a.uri) as click
from (
	SELECT userid, uri, date(time) as d, platform_type,
		   substr((case when (locate('sid',uri)>0) then substr(uri,locate('sid',uri),length(uri)) else '' end),5,1) as sid
	FROM calculate_pm._temp) as a
group by a.d, a.platform_type, a.sid;


SELECT * 
FROM calculate_pm._p_predict_scale_2016 
where platform_type = 2 
and sid = '0' 
and date(d) between '2016-07-08' AND '2016-07-28';















