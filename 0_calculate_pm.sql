
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








# 下面是用來處理回文通知的query
drop table if exists actionlog._notif_click;
create table actionlog._notif_click engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201605
where uri regexp '^/forumdetail.*php.*from=notify.*';
insert ignore into actionlog._notif_click
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201606
where uri regexp '^/forumdetail.*php.*from=notify.*';
insert ignore into actionlog._notif_click
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201607
where uri regexp '^/forumdetail.*php.*from=notify.*';
insert ignore into actionlog._notif_click
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201608
where uri regexp '^/forumdetail.*php.*from=notify.*';

drop table if exists calculate_pm.notify_click_2016;
create table calculate_pm.notify_click_2016 engine = myisam
select b.userid, b.d, b.platform_type, b.f
from (
	select a.userid, a.d, a.platform_type, (case when (locate('&',a.f)=0) then f else substr(a.f, 1, locate('&',a.f)-1) end) as f
	from (
		SELECT userid, uri, date(time) as d, platform_type,
			   substr(uri, locate('from=',uri)+5, length(uri)) as f
		FROM actionlog._notif_click
		order by time) as a) as b
where b.f in ('notify_reply_dropdown',
              'notify_reply_page',
			  'notify_trace_dropdown',
			  'notify_trace_page');

drop table if exists calculate_pm._notify_click_2016;
create table calculate_pm._notify_click_2016
SELECT d, platform_type, f, count(d) as click 
FROM calculate_pm.notify_click_2016
group by d, platform_type, f;

drop table if exists calculate_pm._notify_click_2016_1;
create table calculate_pm._notify_click_2016_1
select a.d, a.platform_type, sum(notify_trace_dropdown) as notify_trace_dropdown,
                             sum(notify_reply_dropdown) as notify_reply_dropdown,
                             sum(notify_trace_page) as notify_trace_page,
                             sum(notify_reply_page) as notify_reply_page
from (
	SELECT d, platform_type, 
		   (case when (f='notify_trace_dropdown') then click else 0 end) as notify_trace_dropdown,
		   (case when (f='notify_reply_dropdown') then click else 0 end) as notify_reply_dropdown,
		   (case when (f='notify_trace_page') then click else 0 end) as notify_trace_page,
		   (case when (f='notify_reply_page') then click else 0 end) as notify_reply_page
	FROM calculate_pm._notify_click_2016) as a
group by a.d, a.platform_type;








drop table if exists calculate_pm._predict_buyer;
CREATE TABLE calculate_pm._predict_buyer engine = myisam
SELECT a.id, a.buyerid, a.id_bought, a.buy_date, a.buy_price, b.position, b.allianceid
FROM plsport_playsport.predict_buyer a LEFT JOIN plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
WHERE a.buy_date between '2016-01-01 00:00:00' AND now();

drop table if exists calculate_pm._predict_buyer_1;
CREATE TABLE calculate_pm._predict_buyer_1 engine = myisam
SELECT id, date(buy_date) as d, substr(buy_date,1,7) as ym, buy_price, position, substr(position,1,3) as p 
FROM calculate_pm._predict_buyer;

UPDATE calculate_pm._predict_buyer_1 SET p = REPLACE(p, '1', '') WHERE p LIKE '%HT%';
UPDATE calculate_pm._predict_buyer_1 SET p = REPLACE(p, '2', '') WHERE p LIKE '%HT%';
UPDATE calculate_pm._predict_buyer_1 SET p = REPLACE(p, '3', '') WHERE p LIKE '%HT%';
UPDATE calculate_pm._predict_buyer_1 SET p = REPLACE(p, '_', '') WHERE p LIKE '%HT%';
UPDATE calculate_pm._predict_buyer_1 SET p = REPLACE(p, '_', '') WHERE p LIKE '%BZ%';
UPDATE calculate_pm._predict_buyer_1 SET p = REPLACE(p, '_', '') WHERE p LIKE '%US%';
UPDATE calculate_pm._predict_buyer_1 SET p = 'EMP' WHERE p is null;


SELECT p, count(id) 
FROM calculate_pm._predict_buyer_1
group by p;





