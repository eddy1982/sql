/*************************************************************************
	計算使用者過去每個月的發文篇數
	給python用的(python已經可以直接使用)

*************************************************************************/

use plsport_playsport;

/*(1)整理forum*/
create table plsport_playsport._forum engine = myisam
select c.subjectid, c.allianceid, c.alliancename, c.postuser, d.nickname, c.m, c.replycount
from (
	SELECT a.subjectid, a.allianceid, b.alliancename, a.postuser, substr(a.posttime,1,7) as m, a.replycount
	FROM plsport_playsport.forum a left join plsport_playsport.alliance b on a.allianceid = b.allianceid
	where substr(posttime,1,7) between '2012-01' and '2016-12'
	order by posttime desc) as c left join plsport_playsport.member d on c.postuser = d.userid;
/*(2)新增第1個月*/
create table plsport_playsport._forum_top25_ranking engine = myisam
select a.m, a.postuser, a.nickname, a.c
from (
	SELECT m, postuser, nickname, count(subjectid) as c 
	FROM plsport_playsport._forum
	group by m, postuser) as a
where m = '2012-01' order by a.c desc limit 1,25;
/*(3)插入其它月份*/
insert ignore into _forum_top25_ranking
select a.m, a.postuser, a.nickname, a.c
from (
	SELECT m, postuser, nickname, count(subjectid) as c 
	FROM plsport_playsport._forum
	group by m, postuser) as a
where m = '2014-03' order by a.c desc limit 1,25;

/*	最近120天內的貼文次數和影響度*/
create table user_cluster._user_post_and_influence engine = myisam
select b.postuser as userid, b.post_count, round((b.replied_count/b.post_count),1) as influence
from (
	select a.postuser, count(a.postuser) as post_count, sum(a.replycount) as replied_count
	from (
		SELECT subjectid, postuser, posttime, replycount, pushcount 
		FROM plsport_playsport.forum
		where posttime between subdate(now(),120) and now()
		order by posttime) as a 
	group by a.postuser) b; 

/*	最近120天內的回文次數*/
create table user_cluster._user_reply engine = myisam
select a.userid, count(a.subjectid) as reply_count
from (
	SELECT subjectid, userid, postdate 
	FROM plsport_playsport.forumcontent /*目前就直接捉全部的*/
	where contenttype=1 and postdate between subdate(now(),120) and now()) as a
group by a.userid;


/*************************************************************************
	update: 2014/3/20 
	研究過去的貼文紅人
*************************************************************************/
/*
    準備好member, forum
	step(1) 先跑(pyhton)1_calculate_top50_poster_for_each_month.py
    step(2) 再跑以下...

		use plsport_playsport;

*/	

		-- create table plsport_playsport._forum_heavy_poster engine = myisam /*排除重覆的人*/
		-- SELECT userid, nickname, count(c) as c 
		-- FROM plsport_playsport._forum_top50_ranking
		-- group by userid, nickname;

		-- 	ALTER TABLE plsport_playsport._forum_heavy_poster ADD INDEX (`userid`);
		-- 	ALTER TABLE plsport_playsport.member ADD INDEX (`userid`);
		-- 	ALTER TABLE plsport_playsport._forum ADD INDEX (`postuser`);
		-- 	ALTER TABLE  plsport_playsport.member CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
		-- 	ALTER TABLE  plsport_playsport._forum CHANGE  `postuser`  `postuser` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
		-- 	ALTER TABLE  plsport_playsport._forum_heavy_poster CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

		-- /*_forum join _forum_heavy_poster*/
		-- create table plsport_playsport._from_heavy_poster_each_month engine = myisam
		-- select b.m, c.id, b.userid, b.nickname, b.c
		-- from (
		-- 	select a.m, a.userid, a.nickname, count(a.subjectid) as c
		-- 	from (
		-- 		SELECT a.subjectid, a.allianceid, a.alliancename, a.postuser as userid, a.nickname, a.m
		-- 		FROM plsport_playsport._forum a inner join plsport_playsport._forum_heavy_poster b on a.postuser = b.userid) as a
		-- 	group by a.m, a.userid) b left join plsport_playsport.member c on b.userid = c.userid;


		-- UPDATE plsport_playsport._from_heavy_poster_each_month set userid = TRIM(userid);     #刪掉空白字完
		-- UPDATE plsport_playsport._from_heavy_poster_each_month set nickname = TRIM(nickname); #刪掉空白字完
		-- /*清除nickname奇怪的符號*/
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '.','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, ',','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, 'php','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, 'admin','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, ';','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '%','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '/','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '\\','_');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '+','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '-','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '*','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '#','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '&','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '$','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '^','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '~','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '!','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '?','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '"','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, ' ','_');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '@','at');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, ':','');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '','_');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '∼','_');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, 'циндаогрыжа','_');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '','_');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '�','_');
		-- update plsport_playsport._from_heavy_poster_each_month set nickname = replace(nickname, '▽','_');

		-- /*輸出給R使用*/
		-- select 'month', 'id', 'userid', 'nickname', 'posts' union(
		-- SELECT * 
		-- into outfile 'C:/Python27/eddy_python/www_process/top_posters_for_each_month.csv' 
		-- fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
		-- FROM plsport_playsport._from_heavy_poster_each_month);

/*---------------------------------------------------------------------------------------------*/
#  以上都已經寫成python
/*---------------------------------------------------------------------------------------------*/


/*-------任務2014/4/14--------*/
# (1)先把cluster的名單匯進mysql
# (2)再run以下產生沒有損壞的userid

# _forum_heavy_poster是前幾個月中各月前50名貼文者, 然後對映出nickname
create table plsport_playsport._who_is_heavy_poster_in_cluster engine = myisam
SELECT a.userid, a.nickname, b.g  #排除掉沒有在分群的重度發文者
FROM plsport_playsport._forum_heavy_poster a inner join user_cluster.cluster_with_real_userid b on a.userid = b.userid;


# popular是被定義的知名度
# 這段要join的_forum為最近n個月 (和前幾個月中各月前50名貼文者是一樣的table)
create table plsport_playsport._forum_heavy_poster_in_cluster engine = myisam
SELECT a.subjectid, a.allianceid, a.alliancename, a.postuser, a.nickname, a.m, a.viewtimes, a.replycount, a.pushcount, 
       ((a.viewtimes*0.02)+ a.replycount+ (a.pushcount*0.3)) as popular, b.g
FROM plsport_playsport._forum a inner join plsport_playsport._who_is_heavy_poster_in_cluster b on a.postuser = b.userid;

create table plsport_playsport._forum_heavy_poster_in_cluster_score engine = myisam
SELECT postuser, nickname, count(subjectid) as total_posts,
                           round(avg(viewtimes),1) as avg_views, round(avg(replycount),1) as avg_reply, 
                           round(avg(pushcount),1) as avg_push, round(avg(popular),1) as avg_popular, g
FROM plsport_playsport._forum_heavy_poster_in_cluster
group by postuser;

SELECT *
FROM plsport_playsport._forum_heavy_poster_in_cluster_score
order by avg_popular desc;




/*************************************************************************
    只計算出最近7天的儲值總額
	to select certian peried time

*************************************************************************/

select 'date', 'revenue' union(
select a.d, sum(price) as total_redeem
into outfile 'C:/Python27/eddy_python/www_process.csv'
from (
	SELECT id, userid, date(createon) as d, price 
	FROM www.order_data
	where sellconfirm = 1
	and createon between subdate(date(now()),7) and subdate(date(now()),0)) as a/*7 days*/
group by a.d); 





/*************************************************************************
	update:2014/3/26
	調察爺爺泡的茶log

**************************************************************************/
select b.uri_2, b.platform_type, count(b.id) as c
from (
	select a.id, a.userid, (case when (a.uri_1='') then 'index' else a.uri_1 end ) as uri_2, a.time, a.platform_type
	from (
		SELECT id, userid, uri, substr(uri,2, (locate('.php',uri))-2) as uri_1, time, platform_type 
		FROM actionlog._grandpa) as a) as b
group by b.uri_2, b.platform_type;



/*************************************************************************
	2014/4/1儲值優惠活動
	update:2014/3/26
	福利班D2,D3簡訊名單
	去年 4~10月，儲值金額超過199的名單

**************************************************************************/
use plsport_playsport;

#列出order_data中所有有手機號碼的使用者
create table plsport_playsport._user_with_phone engine = myisam
select a.id, a.userid, a.name, a.phone
from (
	SELECT b.id, a.userid, a.name, a.phone
	FROM plsport_playsport.order_data a left join plsport_playsport.member b on a.userid = b.userid
	where a.sellconfirm = 1) as a
where a.phone <> ' '
group by a.id;

	ALTER TABLE plsport_playsport._user_with_phone ADD INDEX (`id`); 
	ALTER TABLE user_cluster.cluster_with_real_userid ADD INDEX (`id`); 

#和分群配對
create table plsport_playsport._user_with_phone_and_cluster engine = myisam
SELECT a.id, b.userid, a.name, a.phone, b.g
FROM plsport_playsport._user_with_phone a left join user_cluster.cluster_with_real_userid b on a.id = b.id
where b.g is not null;

#找出D2,D3名單
create table plsport_playsport._user_with_phone_all engine = myisam
SELECT userid, name, phone, count(id) as c # D2, D3名單
FROM plsport_playsport._user_with_phone_and_cluster
where g in ('D2','D3') and phone <> ' '
group by userid, name, phone;

insert ignore into plsport_playsport._user_with_phone_all
select a.userid, a.name, a.phone, count(a.userid) as c # 去年4~10月有儲值過的人
from (
	SELECT userid, name, phone 
	FROM plsport_playsport.order_data
	where sellconfirm = 1 and phone <> ' '
	and createon between '2013-04-01 00:00:00' and '2013-10-01 23:59:59') as a
group by a.userid, a.name, a.phone;

create table plsport_playsport._user_with_phone_all_ok engine = myisam
SELECT userid, name, phone, count(phone) as c
FROM plsport_playsport._user_with_phone_all
group by userid;

# ---------------------------------------------------------------------
# update 2014-05-02追蹤分析(柔雅的任務)
# ---------------------------------------------------------------------

# 匯入簡訊發送有無成功名單
TRUNCATE TABLE `plsport_playsport`.`0401_text_campaign`;
LOAD DATA LOW_PRIORITY LOCAL INFILE 'C:\\Users\\1-7_ASUS\\Documents\\0401_text_campaign.csv' 
REPLACE INTO TABLE `plsport_playsport`.`0401_text_campaign` 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES (`phone_num`, `status`);
/* 6,288 rows imported in 0.094 seconds. */

# 比對出userid到底有無收到簡訊
create table plsport_playsport._user_with_phone_all_ok_1 engine = myisam
SELECT a.userid, a.name, a.phone, b.status 
FROM plsport_playsport._user_with_phone_all_ok a left join plsport_playsport.0401_text_campaign b on a.phone = b.phone_num;

create table plsport_playsport._who_redeem_in_apr1 engine = myisam
select a.userid, a.name, sum(a.price) as redeem
from (
	SELECT userid, createon, name, price
	FROM plsport_playsport.order_data
	where createon between '2014-04-01 00:00:00' and '2014-04-01 23:59:59'
	and payway in (1,2,3,4,5,6) and sellconfirm = 1) as a
group by a.userid;

create table plsport_playsport._who_redeem_before_apr1 engine = myisam
select a.userid, a.name, sum(a.price) as redeem
from (
	SELECT userid, createon, name, price
	FROM plsport_playsport.order_data
	where createon between '2012-01-01 00:00:00' and '2014-03-31 23:59:59'
	and payway in (1,2,3,4,5,6) and sellconfirm = 1) as a
group by a.userid;

create table plsport_playsport._who_redeem_after_apr1 engine = myisam
select a.userid, a.name, sum(a.price) as redeem
from (
	SELECT userid, createon, name, price
	FROM plsport_playsport.order_data
	where createon between '2014-04-02 00:00:00' and '2014-04-30 23:59:59'
	and payway in (1,2,3,4,5,6) and sellconfirm = 1) as a
group by a.userid;

	ALTER TABLE plsport_playsport._who_redeem_in_apr1 ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._who_redeem_before_apr1 ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._who_redeem_after_apr1 ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._who_redeem_in_apr1 CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE plsport_playsport._who_redeem_before_apr1 CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE plsport_playsport._who_redeem_after_apr1 CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

#收到簡訊的人, 當天第是否為第一次消費
create table plsport_playsport._user_with_phone_all_ok_2 engine = myisam 
select e.userid, e.phone, e.status, e.redeem_before, e.redeem_apr1, f.redeem as redeem_after
from (
    select c.userid, c.phone, c.status, c.redeem_before, d.redeem as redeem_apr1
	from (
		SELECT a.userid, a.phone, a.status, b.redeem as redeem_before
		FROM plsport_playsport._user_with_phone_all_ok_1 a left join plsport_playsport._who_redeem_before_apr1 b on a.userid = b.userid) as c 
        left join plsport_playsport._who_redeem_in_apr1 d on c.userid = d.userid) as e 
    left join plsport_playsport._who_redeem_after_apr1 as f on e.userid = f.userid;

#所有會員, 當天第是否為第一次消費
create table plsport_playsport._member_redeem_apr1 engine = myisam 
select e.userid, e.nickname, e.redeem_before, e.redeem_apr1, f.redeem as redeem_after
from (
    select c.userid, c.nickname, c.redeem_before, d.redeem as redeem_apr1
	from (
		SELECT a.userid, a.nickname, b.redeem as redeem_before
		FROM plsport_playsport.member a left join plsport_playsport._who_redeem_before_apr1 b on a.userid = b.userid) as c 
        left join plsport_playsport._who_redeem_in_apr1 d on c.userid = d.userid) as e 
    left join plsport_playsport._who_redeem_after_apr1 as f on e.userid = f.userid
where e.redeem_before is not null 
or e.redeem_apr1 is not null
or f.redeem is not null;

#所有人在4/1前最後一次登入的時間
create table plsport_playsport._last_signin_before_apr1 engine = myisam
select a.userid, date(max(a.signin_time)) as least_sign_in
from (
	SELECT userid, signin_time 
	FROM plsport_playsport.member_signin_log_archive
	where signin_time between '2009-01-01 00:00:00' and '2014-03-31 23:59:59') as a
group by a.userid
order by userid;

	ALTER TABLE plsport_playsport._last_signin_before_apr1 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE plsport_playsport._last_signin_before_apr1 ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._member_redeem_apr1 ADD INDEX (`userid`);

#完整的名單, 和4/1之前, 4/1當天, 4/1之後的儲值金額列表
create table plsport_playsport._member_redeem_apr2 engine = myisam 
select c.userid, c.nickname, date(d.createon) as createon, c.least_sign_in, c.redeem_before, c.redeem_apr1, c.redeem_after 
from (
	SELECT a.userid, a.nickname, b.least_sign_in, a.redeem_before, a.redeem_apr1, a.redeem_after 
	FROM plsport_playsport._member_redeem_apr1 a left join plsport_playsport._last_signin_before_apr1 b on a.userid = b.userid) as c
    left join plsport_playsport.member as d on c.userid = d.userid;

	ALTER TABLE plsport_playsport._member_redeem_apr2 ADD INDEX (`userid`);

#4/1當天有使用儲值優惠的人
create table plsport_playsport._member_redeem_apr3 engine = myisam 
SELECT * FROM plsport_playsport._member_redeem_apr2
where redeem_apr1 is not null
and redeem_apr1 not in (199,228,699,803); #不含儲值999以下的人

	#who_redeem_before_apr1 4/1之前的儲值
    create table plsport_playsport._who_redeem_before_apr1_nogroup engine = myisam 
	SELECT userid, createon, name, price
	FROM plsport_playsport.order_data
	where createon between '2012-01-01 00:00:00' and '2014-03-31 23:59:59'
	and payway in (1,2,3,4,5,6) and sellconfirm = 1;
	#who_redeem_after_apr1  4/1之後的儲值
    create table plsport_playsport._who_redeem_after_apr1_nogroup engine = myisam 
	SELECT userid, createon, name, price
	FROM plsport_playsport.order_data
	where createon between '2014-04-02 00:00:00' and '2014-04-30 23:59:59'
	and payway in (1,2,3,4,5,6) and sellconfirm = 1;

	ALTER TABLE plsport_playsport._who_redeem_before_apr1_nogroup ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._who_redeem_after_apr1_nogroup ADD INDEX (`userid`);

	#4/1當天有使用儲值優惠的人, 前一次的儲值
	create table plsport_playsport._temp1 engine = myisam 
	select c.userid, max(c.createon) as before_apr1_redeem, c.price
	from (
		SELECT a.userid, a.createon, a.price 
		FROM plsport_playsport._who_redeem_before_apr1_nogroup a inner join plsport_playsport._member_redeem_apr3 b on a.userid = b.userid) as c
	group by c.userid;

	#4/1當天有使用儲值優惠的人, 後一次的儲值
	create table plsport_playsport._temp2 engine = myisam 
	select c.userid, min(c.createon) as after_apr1_redeem, c.price
	from (
		SELECT a.userid, a.createon, a.price 
		FROM plsport_playsport._who_redeem_after_apr1_nogroup a inner join plsport_playsport._member_redeem_apr3 b on a.userid = b.userid) as c
	group by c.userid;

	ALTER TABLE plsport_playsport._temp1 ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._temp2 ADD INDEX (`userid`);

create table plsport_playsport._member_redeem_apr4 engine = myisam 
select c.userid, c.nickname, c.createon, c.least_sign_in, c.redeem_before, c.redeem_apr1, c.redeem_after, 
       date(c.before_apr1_redeem) as d_1, c._apr1_before, date(d.after_apr1_redeem) as d_2 ,d.price as _apr1_after
from (
	SELECT a.userid, a.nickname, a.createon, a.least_sign_in, a.redeem_before, a.redeem_apr1, a.redeem_after, b.before_apr1_redeem ,b.price as _apr1_before 
	FROM plsport_playsport._member_redeem_apr3 a left join plsport_playsport._temp1 b on a.userid = b.userid) as c 
    left join plsport_playsport._temp2 as d on c.userid = d.userid;

	drop table plsport_playsport._temp1;
	drop table plsport_playsport._temp2;


/*...............................................*/
/*   福利班追加任務 2014/4/11                    */
/*...............................................*/

# 誰在福利班的條件下有儲值過噱幣?
create table plsport_playsport._who_redeem_last_year engine = myisam
select userid, name, count(phone) as c, (case when (userid is not null) then 'yes' end) as whoredeemlastyear
from (
	SELECT userid, name, phone 
	FROM plsport_playsport.order_data
	where sellconfirm = 1 and phone <> ' '
	and createon between '2013-04-01 00:00:00' and '2013-10-01 23:59:59') as a
group by userid, name;

# 最後一次登入的記錄
create table plsport_playsport._who_last_sign_in_before_Apr1 engine = myisam
select a.userid, a.last_sign_in, substr(a.last_sign_in,1,7) as m
from (
	SELECT userid, max(signin_time) as last_sign_in 
	FROM plsport_playsport.member_signin_log_archive
	where date(signin_time) between '2013-01-01' and '2014-03-31'
	group by userid
	order by signin_time desc) as a;

    ALTER TABLE plsport_playsport._who_redeem_last_year         CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE plsport_playsport._who_last_sign_in_before_Apr1 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE plsport_playsport._who_redeem_last_year         ADD INDEX (`userid`); 
	ALTER TABLE plsport_playsport._who_last_sign_in_before_Apr1 ADD INDEX (`userid`); 

create table plsport_playsport._who_redeem_last_year_1 engine = myisam
SELECT a.userid, a.name, a.c, a.whoredeemlastyear, b.last_sign_in, substr(b.last_sign_in,1,7) as m
FROM plsport_playsport._who_redeem_last_year a left join plsport_playsport._who_last_sign_in_before_apr1 b on a.userid = b.userid;

create table plsport_playsport._who_redeem_last_year_2 engine = myisam
SELECT userid, name, c, whoredeemlastyear, (case when (m is null) then '2013-06' else m end) as m
FROM plsport_playsport._who_redeem_last_year_1;

create table plsport_playsport._who_redeem_at_apr1 engine = myisam
select a.userid, count(a.price) as redeem_count, sum(a.price) as redeem_total
from (
	SELECT userid, price 
	FROM plsport_playsport.order_data
	where sellconfirm = 1
	and createon between '2014-04-01 00:00:00' and '2014-04-01 23:59:59') as a
group by a.userid;

    ALTER TABLE plsport_playsport._who_redeem_at_apr1 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE plsport_playsport._who_redeem_at_apr1 ADD INDEX (`userid`); 

create table plsport_playsport._who_redeem_last_year_3 engine = myisam
SELECT a.userid, a.name, a.c, a.whoredeemlastyear, a.m, b.redeem_count, b.redeem_total
FROM plsport_playsport._who_redeem_last_year_2 a left join plsport_playsport._who_redeem_at_apr1 b on a.userid = b.userid;


SELECT m, count(userid) as user_count
FROM plsport_playsport._who_redeem_last_year_3
where redeem_count is not null
group by m;

SELECT m, sum(redeem_count) as redeem_count, sum(redeem_total) as redeem_total
FROM plsport_playsport._who_redeem_last_year_3
where redeem_count is not null
group by m;




/*************************************************************************
	update:2014/4/3
	分析文觀看比例
	請調查 2014/1/9, 3/6有觀看最讚分析文的會員比例
	舉例來說：3/6共有 2000人觀看當日發表的最讚分析文，佔當日有看討論區會員的 20%
**************************************************************************/
use actionlog;

create table actionlog._forum_log_JAN engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201401
where time between '2014-01-05 00:00:00' and '2014-01-11 23:59:59'
and userid <> ''
and uri like '%forum%';

create table actionlog._forum_log_MAR engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201403
where time between '2014-03-02 00:00:00' and '2014-03-08 23:59:59'
and userid <> ''
and uri like '%forum%';

	insert ignore into actionlog._forum_log_JAN select * from actionlog._forum_log_MAR;
	rename table actionlog._forum_log_JAN to actionlog._forum_log;
	drop table actionlog._forum_log_MAR;

# 所有看討論區的完整log
create table actionlog._forum_log_allviwers engine = myisam
SELECT id, userid, uri, substr(uri,2, (locate('.php',uri))-2) as uri_1, time  
FROM actionlog._forum_log;

# 所有看文章內文的完整log並捉出subjectid
create table actionlog._forumdetail_log_allviwers engine = myisam
select b.id, b.userid, b.uri, b.uri1, b.e, b.time
from (
	select a.id, a.userid, a.uri, a.uri1, locate('&', a.uri1)-1 as e, a.time #&之前的字串位置
	from (
		SELECT id, userid, uri, substr(uri,(locate('subjectid=',uri) +10)) as uri1,time #捉出subjectid的內容
		FROM actionlog._forum_log
		where uri like '%subjectid=%') as a) as b 
where b.e in (-1, 15);

create table actionlog._forumdetail_log_allviwers1 engine = myisam
SELECT id, userid, substr(uri,2, (locate('.php',uri))-2) as s_uri, substr(uri1,1,15) as subjectid, time 
FROM actionlog._forumdetail_log_allviwers;

# 處理分析王的文章表格, 要指定好區間 
create table plsport_playsport._analysis_king engine = myisam 
select id, userid, allianceid, subjectid, reply_count, push_count, d, gamedate,
	   (case when (subjectid is not null) then 'ana_post' end) as isana
from (
	SELECT id, userid, allianceid, subjectid, reply_count, push_count, date(got_time) as d, gamedate
	FROM plsport_playsport.analysis_king) as a 
where a.d between '2014-01-05' and '2014-03-08';

	ALTER TABLE plsport_playsport._analysis_king      ADD INDEX (`subjectid`); 
	ALTER TABLE actionlog._forumdetail_log_allviwers1 ADD INDEX (`subjectid`); 
	ALTER TABLE actionlog._forumdetail_log_allviwers1 CHANGE  `subjectid`  `subjectid` VARCHAR( 15 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT  '';
    ALTER TABLE plsport_playsport._analysis_king      CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table actionlog._forumdetail_log_allviwers1_with_ana engine = myisam
SELECT a.id, a.userid, a.s_uri, a.subjectid, a.time, b.isana
FROM actionlog._forumdetail_log_allviwers1 a left join plsport_playsport._analysis_king b on a.subjectid = b.subjectid;

create table actionlog._forumdetail_log_allviwers1_with_ana1 engine = myisam
select a.userid, a.s_uri, a.subjectid, a.d, a.isana, count(subjectid) as c
from (
	SELECT userid, s_uri, subjectid, date(time) as d, isana
	FROM actionlog._forumdetail_log_allviwers1_with_ana) as a
group by a.userid, a.s_uri, a.subjectid, a.d;

/*-----------------------------------------------------
	查詢: 每天有看討論區的人數
-----------------------------------------------------*/
select a.d, count(a.userid) as viwer_count
from (
	SELECT d, userid, count(subjectid) as c 
	FROM actionlog._forumdetail_log_allviwers1_with_ana1
	group by d, userid) as a
group by a.d;
/*-----------------------------------------------------
	查詢: 每天有看分析王文章的人數
-----------------------------------------------------*/
select a.d, count(a.userid) as viwer_count
from (
	SELECT d, userid, count(subjectid) as c 
	FROM actionlog._forumdetail_log_allviwers1_with_ana1
    where isana is not null # 該文被評選為分析王
	group by d, userid) as a
group by a.d;

/*-----------------------------------------------------
	追加任務:2014/4/10 當天有多少人登入
-----------------------------------------------------*/
create table actionlog._log_JAN engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201401
where time between '2014-01-05 00:00:00' and '2014-01-11 23:59:59'
and userid <> '';

create table actionlog._log_MAR engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201403
where time between '2014-03-02 00:00:00' and '2014-03-08 23:59:59'
and userid <> '';

	insert ignore into actionlog._log_JAN select * from actionlog._log_MAR;
	rename table actionlog._log_JAN to actionlog._log;
	drop table actionlog._log_MAR;

create table actionlog._log_1 engine = myisam
SELECT id, userid, uri, date(time) as d
FROM actionlog._log;

create table actionlog._log_2 engine = myisam
SELECT d, userid, count(id) as c 
FROM actionlog._log_1
group by d, userid;

SELECT d, count(userid) as c 
FROM actionlog._log_2
group by d;



/*************************************************************************
	update:2014/4/10
	任務: [201404-A-2] 販售分析文 - 訪談名單
	名單條件
		1. 愛看分析文的人
			2014/1~3月觀看最讚分析文章次數較多者，並列出其總儲值金額
		1.1追加補充 (2014-05-01)
			2014/2~3月觀看最讚分析文章次數較多者，並列出其總儲值金額


		2. 分析文寫手
			請提供2013/4 ~ 2014/3有當過優質分析王的使用者，並列出個別使用
			者的最讚分析文總數及最讚分析文平均推數、回文數
**************************************************************************/
use actionlog;
/*先整理log找出有在看文章的人*/
create table actionlog._forum_log_JAN engine = myisam # 1月
SELECT id, userid, uri, time 
FROM actionlog.action_201401
where userid <> '' and uri like '%forumdetail%';

create table actionlog._forum_log_FEB engine = myisam # 2月
SELECT id, userid, uri, time 
FROM actionlog.action_201402
where userid <> '' and uri like '%forumdetail%';

create table actionlog._forum_log_MAR engine = myisam # 3月
SELECT id, userid, uri, time 
FROM actionlog.action_201403
where userid <> '' and uri like '%forumdetail%';

create table actionlog._forum_log_APR engine = myisam # 4月
SELECT id, userid, uri, time 
FROM actionlog.action_201404
where userid <> '' and uri like '%forumdetail%';

	insert ignore into actionlog._forum_log_JAN select * from actionlog._forum_log_FEB;
	insert ignore into actionlog._forum_log_JAN select * from actionlog._forum_log_MAR;
	insert ignore into actionlog._forum_log_JAN select * from actionlog._forum_log_APR;
	drop table actionlog._forum_log_FEB;
	drop table actionlog._forum_log_MAR;
	drop table actionlog._forum_log_APR;
	rename table actionlog._forum_log_JAN to actionlog._forum_log; # 合併成一個

create table actionlog._forum_log_1 engine = myisam # 開始分析subjectid
SELECT id, userid, uri, substr(uri,(locate('subjectid=',uri) +10)) as uri1,time
FROM actionlog._forum_log;

create table actionlog._forum_log_2 engine = myisam # 取出subjectid, 並移掉奇怪的subjectid
select a.id, a.userid, a.uri, a.uri1, a.e, a.time
from (
	SELECT id, userid, uri, uri1, locate('&', uri1)-1 as e, time 
    FROM actionlog._forum_log_1) as a
where a.e in (-1, 15);

create table actionlog._forum_log_3 engine = myisam # 整理subjectid
SELECT id, userid, substr(uri1,1,15) as subjectid, date(time) as d
FROM actionlog._forum_log_2;

/*匯入analysis_king*/
/*找出FEB到APR之間的最讚分析文*/
create table plsport_playsport._analysis_king_feb_apr engine = myisam 
SELECT userid, subjectid, got_time, gamedate, 
	   (case when (subjectid is not null) then 'y' end) as isanalysispost
FROM plsport_playsport.analysis_king
where got_time between '2014-02-01 00:00:00' and '2014-04-30 23:59:59'
order by got_time desc;

	ALTER TABLE plsport_playsport._analysis_king_feb_apr ADD INDEX (`subjectid`); 
	ALTER TABLE actionlog._forum_log_3 ADD INDEX (`subjectid`); 
    ALTER TABLE plsport_playsport._analysis_king_feb_apr CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE actionlog._forum_log_3 CHANGE  `subjectid`  `subjectid` VARCHAR( 15 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT  '';

create table actionlog._forum_log_4_with_post engine = myisam # join
select a.id, a.userid, a.subjectid, a.d, b.isanalysispost
from actionlog._forum_log_3 a left join plsport_playsport._analysis_king_feb_apr b on a.subjectid = b.subjectid;

create table actionlog._forum_log_5_who_read_analysis engine = myisam # 留下有看過分析文的log
SELECT id, userid, subjectid, d, substr(d,1,7) as m, isanalysispost 
FROM actionlog._forum_log_4_with_post
where isanalysispost is not null;

create table actionlog._forum_log_5_who_read_analysis_1 engine = myisam # 排除閱讀重覆的subjectid
SELECT userid, subjectid, count(id) as c 
FROM actionlog._forum_log_5_who_read_analysis
group by userid, subjectid;

create table actionlog._forum_log_6 engine = myisam # 實際上每個user看到多少文析文
select a.userid, a.c
from (
	SELECT userid, count(subjectid) as c 
	FROM actionlog._forum_log_5_who_read_analysis_1
	group by userid) as a 
order by a.c desc;

	ALTER TABLE actionlog._forum_log_6 ADD INDEX (`userid`); 
    ALTER TABLE actionlog._forum_log_6 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table actionlog._forum_log_7_with_nickname engine = myisam
select a.userid, b.nickname, date(b.createon) as d ,a.c
from actionlog._forum_log_6 a left join plsport_playsport.member b on a.userid = b.userid;

#加入2月~4月的儲值金額
create table plsport_playsport._order_data_feb_apr engine = myisam
select a.userid, sum(a.price) as redeem_total
from (
	SELECT userid, price, substr(createon,1,7) as m
	FROM plsport_playsport.order_data
	where sellconfirm = 1 and payway in (1,2,3,4,5,6)
	and createon between '2014-02-01 00:00:00' and '2014-04-30 23:59:59') as a 
group by a.userid;

#加入全歷史的儲值金額
create table plsport_playsport._order_data_all_time engine = myisam
select a.userid, sum(a.price) as redeem_total
from (
	SELECT userid, price, substr(createon,1,7) as m
	FROM plsport_playsport.order_data
	where sellconfirm = 1 and payway in (1,2,3,4,5,6)) as a 
group by a.userid;

	ALTER TABLE plsport_playsport._order_data_feb_apr  ADD INDEX (userid); 
	ALTER TABLE plsport_playsport._order_data_all_time ADD INDEX (userid); 
	ALTER TABLE actionlog._forum_log_7_with_nickname   ADD INDEX (userid); 

create table actionlog._forum_log_8 engine = myisam
select c.userid, c.nickname, c.d, c.c, c.redeem_total, d.redeem_total as redeem_total_all_time
from (
	select a.userid, a.nickname, a.d, a.c, b.redeem_total
	from actionlog._forum_log_7_with_nickname a left join plsport_playsport._order_data_feb_apr b 
	on a.userid = b.userid) c left join plsport_playsport._order_data_all_time d on c.userid = d.userid;

UPDATE actionlog._forum_log_8 set nickname = TRIM(nickname);            #刪掉空白字完
update actionlog._forum_log_8 set nickname = replace(nickname, '.',''); #清除nickname奇怪的符號...
update actionlog._forum_log_8 set nickname = replace(nickname, ',','');
update actionlog._forum_log_8 set nickname = replace(nickname, ';','');
update actionlog._forum_log_8 set nickname = replace(nickname, '%','');
update actionlog._forum_log_8 set nickname = replace(nickname, '/','');
update actionlog._forum_log_8 set nickname = replace(nickname, '\\','_');
update actionlog._forum_log_8 set nickname = replace(nickname, '*','');
update actionlog._forum_log_8 set nickname = replace(nickname, '#','');
update actionlog._forum_log_8 set nickname = replace(nickname, '&','');
update actionlog._forum_log_8 set nickname = replace(nickname, '$','');

    # 輸出csv到桌面
	select 'userid', 'nickname', 'createon', 'read_count', 'redeem', 'redeem_all_time' union (
	SELECT * 
	into outfile 'C:/Users/1-7_ASUS/Desktop/who_love_to_read_analysis_post.csv' 
	fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
	FROM actionlog._forum_log_8);


/*...............................................*/
/*   PART 2                                      */
/*...............................................*/

use plsport_playsport;
#誰是優質分析王
create table plsport_playsport._analysis_king_whoisbest engine = myisam
select b.userid, b.m, b.subjectid_count, (case when (b.userid is not null) then 'y' end) as best_analysis_king
from (
	select a.userid, a.m, count(a.subjectid) as subjectid_count
	from (
		SELECT userid, subjectid, substr(gamedate,1,6) as m 
		FROM plsport_playsport.analysis_king
		where substr(gamedate,1,6) between '201304' and '201403') as a
	group by a.userid, a.m
	order by a.m) as b 
where b.subjectid_count >11
order by b.m, b.subjectid_count desc;

create table plsport_playsport._analysis_king_13apr_14mar engine = myisam #201304~201403
SELECT userid, allianceid, subjectid, reply_count, push_count, gamedate, substr(gamedate,1,6) as m
FROM plsport_playsport.analysis_king
where substr(gamedate,1,6) between '201304' and '201403';

ALTER TABLE  `_analysis_king_whoisbest`   CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_analysis_king_13apr_14mar` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table plsport_playsport._analysis_king_whoisbest_post_detail engine = myisam
SELECT a.userid, a.allianceid, a.subjectid, a.reply_count, a.push_count, a.gamedate, a.m, b.best_analysis_king 
FROM plsport_playsport._analysis_king_13apr_14mar a inner join plsport_playsport._analysis_king_whoisbest b on a.userid = b.userid
order by a.userid, a.m;

create table plsport_playsport._analysis_king_whoisbest_post_detail_with_name engine = myisam
SELECT a.userid, b.nickname, a.allianceid, a.subjectid, a.reply_count, a.push_count, a.gamedate, a.m, a.best_analysis_king
FROM plsport_playsport._analysis_king_whoisbest_post_detail a left join plsport_playsport.member b on a.userid = b.userid;

SELECT userid,  nickname, count(subjectid) as c, round(avg(reply_count),1) as avg_reply, round(avg(push_count),1) as avg_push
FROM plsport_playsport._analysis_king_whoisbest_post_detail_with_name
group by userid;



/*************************************************************************
	update:2014/4/3
	即時比分加上殺手推薦 - 研究未登入使用者路徑
	1. 每天有多少未登入使用者是直接進到即時比分頁
	2. 呈上題，多少未登入使用者除了即時比分外，沒有使用其他功能
**************************************************************************/

create table actionlog._not_login_log engine = myisam
SELECT id, userid, uri, time, cookie_stamp 
FROM actionlog.action_201403
where time between '2014-03-23 00:00:00' and '2014-03-31 23:59:59'
and userid =''
order by cookie_stamp desc, time desc;

create table actionlog._not_login_log_edited engine = myisam
SELECT id, userid, substr(uri,2, (locate('.php',uri))-2) as uri_1, time, cookie_stamp 
FROM actionlog._not_login_log;

create table actionlog._not_login_log_edited_1 engine = myisam
SELECT id, uri_1, time, cookie_stamp, 
       (case when (uri_1 = '')             then 'index'
		     when (uri_1 = '/buy_predict') then 'buy_predict'
		     when (uri_1 = '/forum')       then 'forum'
		     when (uri_1 = '/forumdetail') then 'forumdetail'
		     when (uri_1 = '/games_data')  then 'games_data'
		     when (uri_1 = '/livescore')   then 'livescore'
		     when (uri_1 = '/predictgame') then 'predictgame'
		     when (uri_1 = '/usersearch')  then 'usersearch' else uri_1 end) as uri_2
FROM actionlog._not_login_log_edited;

# [未登入]先只篩1天就好, 要不然SQL執行很久
create table actionlog._not_login_log_edited_2 engine = myisam
SELECT id, date(time) as d, cookie_stamp, uri_2 
FROM actionlog._not_login_log_edited_1
where time between '2014-03-23 00:00:00' and '2014-03-26 23:59:59';

create table actionlog._not_login_log_edited_2_1 engine = myisam
SELECT d, cookie_stamp, uri_2, count(id) as c 
FROM actionlog._not_login_log_edited_2
where cookie_stamp <> ''
group by d, cookie_stamp, uri_2;

	# 查詢當天有多少cookie是未登入的
	select a.d, count(a.cookie_stamp) as e
	from (
		SELECT d, cookie_stamp, count(uri_2) as c 
		FROM actionlog._not_login_log_edited_2_1
		group by d, cookie_stamp) as a
	group by a.d;

# 誰造訪過livescore
create table actionlog._who_use_livescore engine = myisam
SELECT cookie_stamp, count(id) as c
FROM actionlog._not_login_log_edited_2
where uri_2 like '%livescore%'
group by cookie_stamp;

	ALTER TABLE actionlog._who_use_livescore ADD INDEX (`cookie_stamp`); 
	ALTER TABLE actionlog._not_login_log_edited_2 ADD INDEX (`cookie_stamp`); 

# [未登入]先找出曾經用過livescore的log
create table actionlog._not_login_log_edited_3 engine = myisam
SELECT a.id, a.d, a.cookie_stamp, a.uri_2 
FROM actionlog._not_login_log_edited_2 a inner join actionlog._who_use_livescore b on a.cookie_stamp = b.cookie_stamp;

	select count(a.cookie_stamp) as c
	from (
		SELECT cookie_stamp, count(id) 
		FROM actionlog._not_login_log_edited_3
		group by cookie_stamp) as a;

/*輸出給excel使用*/
select 'cookie', 'd', 'uri', 'c' union(
SELECT cookie_stamp, d,  uri_2, count(id) as c 
into outfile 'C:/Users/1-7_ASUS/Desktop/0323-0326_log.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM actionlog._not_login_log_edited_3
group by cookie_stamp, d, uri_2);



/*************************************************************************
	2014/4/29
	購牌專區的問券

**************************************************************************/
create table plsport_playsport._questionnaire engine = myisam
SELECT userid, write_time, spend_minute, sort, fixinfo, recommend 
FROM plsport_playsport.questionnaire_buypredict_answer
where spend_minute > 0.3
and fixinfo <> "1,2,3,4,5,6,7";

create table plsport_playsport._who_paid_before engine = myisam
SELECT buyerid, sum(buy_price) as total_revenue 
FROM plsport_playsport.predict_buyer
group by buyerid;

	ALTER TABLE plsport_playsport._who_paid_before ADD INDEX (`buyerid`); 
	ALTER TABLE plsport_playsport._questionnaire ADD INDEX (`userid`); 

create table plsport_playsport._questionnaire_with_revenue engine = myisam
select a.userid, a.write_time, a.spend_minute, a.sort, a.fixinfo, a.recommend, b.total_revenue 
from plsport_playsport._questionnaire a left join plsport_playsport._who_paid_before b on b.buyerid = a.userid;

	ALTER TABLE plsport_playsport._questionnaire_with_revenue ADD INDEX (`userid`); 

create table plsport_playsport._questionnaire_with_revenue_and_nickname engine = myisam
select a.userid, b.nickname, a.write_time, a.spend_minute, a.sort, a.fixinfo, a.recommend, a.total_revenue
from plsport_playsport._questionnaire_with_revenue a left join plsport_playsport.member b on a.userid = b.userid;


update plsport_playsport._questionnaire_with_revenue set recommend = TRIM(recommend);  #刪掉空白字完
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '.',''); 
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, ';','');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '/','');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '\\','_');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '"','');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '&','');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '#','');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, ' ','');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '*','');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '\r','_');
update plsport_playsport._questionnaire_with_revenue set recommend = replace(recommend, '\n','_');

ALTER TABLE  `_questionnaire_with_revenue_and_nickname` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

select 'userid', 'nickname','date', 'Q1', 'Q2', 'a1', 'a2','a3','a4','a5','a6','a7','total_revenue','feedback' union (
select userid, nickname, date(write_time) as d, sort, fixinfo,
	   (case when (fixinfo like '%1%') then 1 else 0 end) as a1,
	   (case when (fixinfo like '%2%') then 1 else 0 end) as a2,
	   (case when (fixinfo like '%3%') then 1 else 0 end) as a3,
	   (case when (fixinfo like '%4%') then 1 else 0 end) as a4,
	   (case when (fixinfo like '%5%') then 1 else 0 end) as a5,
	   (case when (fixinfo like '%6%') then 1 else 0 end) as a6,
	   (case when (fixinfo like '%7%') then 1 else 0 end) as a7,
	    total_revenue, recommend
into outfile 'C:/Users/1-7_ASUS/Desktop/buy_predict_questionnaire.csv' 
fields terminated by ';' enclosed by '"' lines terminated by '\r\n' 
from plsport_playsport._questionnaire_with_revenue_and_nickname);


/*************************************************************************
	action_log url解析的SQL
**************************************************************************/
create table actionlog._user_log_stevenash1520_1 engine = myisam
SELECT id, userid, uri, substr(uri,2, (locate('.php',uri))-2) as uri_1, time
FROM actionlog._user_log_stevenash1520;

SELECT id, userid, time, uri, uri_1,
	   (case when (uri_1 = '') then '首頁'
			when (uri_1 = 'analysis_king')      then '本日最讚分析文'
			when (uri_1 = 'billboard')          then '勝率主推榜'
			when (uri_1 = 'buy_pcash_step_one') then '儲值噱幣1'
			when (uri_1 = 'buy_pcash_step_two') then '儲值噱幣1'
			when (uri_1 = 'buy_predict')        then '購牌專區'
			when (uri_1 = 'forum')              then '文章列表'
			when (uri_1 = 'forumdetail')        then '文章內頁'
			when (uri_1 = 'games_data')         then '賽事數據'
			when (uri_1 = 'livescore')          then '即時比分'
			when (uri_1 = 'mailbox_pcash')      then '帳戶'
			when (uri_1 = 'medal_fire_rank')    then '殺手榜'
			when (uri_1 = 'predictgame')        then '預測'
			when (uri_1 = 'shopping_list')      then '購牌清單'
			when (uri_1 = 'usersearch')         then '玩家搜尋'
			when (uri_1 = 'visit_member')       then '個人頁' else '???' end) as des
into outfile 'C:/Users/1-7_ASUS/Desktop/user_log.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM actionlog._user_log_stevenash1520_1;


/*************************************************************************
	購牌位置代碼解析
    需要的tables
	(1)predict_buyer
	(2)predict_seller
	(3)predict_buyer_cons_split
**************************************************************************/
    use plsport_playsport;
	drop table if exists plsport_playsport._predict_buyer;
	drop table if exists plsport_playsport._predict_buyer_with_cons;

    #先predict_buyer + predict_buyer_cons_split
	create table plsport_playsport._predict_buyer engine = myisam
	SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
	FROM plsport_playsport.predict_buyer a left join plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
	where a.buy_price <> 0
	and a.buy_date between '2014-03-04 00:00:00' and '2016-12-31 23:59:59'; #2014/03/04是開始有購牌追蹤代碼的日子

		ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

    #再join predict_seller
	create table plsport_playsport._predict_buyer_with_cons engine = myisam
	select c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
	from plsport_playsport._predict_buyer c left join plsport_playsport.predict_seller d on c.id_bought = d.id
	order by buy_date desc;

	select a.d
	from (
		SELECT date(buy_date) as d 
		FROM plsport_playsport._predict_buyer_with_cons
		order by buy_date) as a
	group by a.d;

#version 2 (只有看單日的收益)
select date(b.buy_date) as buy_date, b.p, sum(b.revenue) as revenue
from (
	select a.buy_date, a.position, a.revenue, 
		   (case when (substr(a.position,1,3) = 'BRC')  then '購買後推專'
				 when (substr(a.position,1,2) = 'BZ')   then '購牌專區' 
				 when (substr(a.position,1,4) = 'FRND') then '明燈' 
				 when (substr(a.position,1,2) = 'FR')   then '討論區' 
				 when (substr(a.position,1,3) = 'WPB')  then '勝率榜' 
				 when (substr(a.position,1,3) = 'MPB')  then '主推榜' 
				 when (substr(a.position,1,3) = 'IDX')  then '首頁' 
				 when (substr(a.position,1,2) = 'HT')   then '頭三標' 
				 when (substr(a.position,1,2) = 'US')   then '玩家搜尋' 
				 when (a.position is null)              then '無' else '有問題' end) as p 
	from (
		SELECT buy_date, position, sum(buy_price) as revenue 
		FROM plsport_playsport._predict_buyer_with_cons
		where date(buy_date) = '2014-04-28'
		group by position) as a) as b
group by b.p 
order by b.revenue desc;

#對照收益金額是否有誤
SELECT sum(buy_price)
FROM plsport_playsport._predict_buyer
where buy_date between '2014-04-28 00:00:00' and '2014-04-29 23:59:59';

create table plsport_playsport._revenue_made_by_position engine = myisam
select a.d, a.p, sum(a.price) as revenue
from (
  SELECT date(buy_date) as d, buy_price as price, 
		 (case when (substr(position,1,3) = 'BRC')  then 'after_purchase'
			   when (substr(position,1,2) = 'BZ')   then 'buy_predict' 
			   when (substr(position,1,4) = 'FRND') then 'friend' 
			   when (substr(position,1,2) = 'FR')   then 'forum' 
			   when (substr(position,1,3) = 'WPB')  then 'win_rank' 
			   when (substr(position,1,3) = 'MPB')  then 'month_rank' 
			   when (substr(position,1,3) = 'IDX')  then 'index' 
			   when (substr(position,1,2) = 'HT')   then 'head3' 
			   when (substr(position,1,2) = 'US')   then 'user_search' 
			   when (position is null)  then 'none' else 'got problem' end) as p
FROM plsport_playsport._predict_buyer_with_cons) as a
group by a.d, a.p;


/*************************************************************************
	2014/4/29
	個人頁的預測表格分析
    
    實驗觀察區間: 2014/4/15~5/7
    組別: 1,2,3
**************************************************************************/

#簡單的觀察
use plsport_playsport;

drop table if exists plsport_playsport._member_with_group;
drop table if exists plsport_playsport._predict_buyer_visitmember_predict_table;
drop table if exists plsport_playsport._predict_buyer_visitmember_predict_table_with_group;

create table plsport_playsport._member_with_group engine = myisam
SELECT ((id%10)+1) as g, userid 
FROM plsport_playsport.member;

create table plsport_playsport._predict_buyer_visitmember_predict_table engine = myisam
SELECT buyerid, sum(buy_price) as spent, count(buy_price) as spent_times #消費者在某段期間內的購買總金額和總次數
FROM plsport_playsport.predict_buyer #購買預測的消費者
where buy_date between '2014-04-15 00:00:00' and '2014-05-07 23:59:59'
and buy_price <> 0
group by buyerid;

	ALTER TABLE plsport_playsport._member_with_group ADD INDEX (`userid`); 
	ALTER TABLE plsport_playsport._predict_buyer_visitmember_predict_table ADD INDEX (`buyerid`);

create table plsport_playsport._predict_buyer_visitmember_predict_table_with_group engine = myisam
select a.buyerid, a.spent, a.spent_times, b.g
from plsport_playsport._predict_buyer_visitmember_predict_table a left join plsport_playsport._member_with_group b on a.buyerid = b.userid;

select 'buyerid', 'spent', 'spent_times', 'g' union (
SELECT buyerid, spent, spent_times, g
into outfile 'C:/proc/r/abtest/predict_buyer_visitmember_predict_table_with_group.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._predict_buyer_visitmember_predict_table_with_group);


# =================================================================================================
# 
# 2014/5/16 靜怡購牌專區MVP名單任務
# 要直接找人來公司訪談, 所以要對映到居住地
# 居住地的資料有:
# 	(1)udata
# 	(2)user_living_city
# 
# =================================================================================================

create table plsport_playsport._mycity_from_user_living_city engine = myisam
SELECT userid, city, 
       (case when (city = 14) then 'TNN'
             when (city = 16) then 'KHH'
			 when (city = 18) then 'PNG' end ) as city1
FROM plsport_playsport.user_living_city
where action=1 and city in (14,16,18);

create table plsport_playsport._mycity_from_udata engine = myisam
SELECT userid, city, 
       (case when (city < 16) then 'TNN'
             when (city < 18) then 'KHH'
			 when (city = 18) then 'PNG' end ) as city1
FROM plsport_playsport.udata
where city in (14,15,16,17,18);


create table plsport_playsport._mycity engine = myisam
select  * from plsport_playsport._mycity_from_user_living_city; 
insert ignore into plsport_playsport._mycity select * from plsport_playsport._mycity_from_udata;

create table plsport_playsport._mycity1 engine = myisam
SELECT userid, city, city1, count(userid) as c 
FROM plsport_playsport._mycity
group by userid, city, city1;

create table plsport_playsport._mycity2 engine = myisam
SELECT userid, city, city1 
FROM plsport_playsport._mycity1
group by userid;

create table plsport_playsport._mycity_order_data engine = myisam
SELECT userid, sum(price) as revenue 
FROM plsport_playsport.order_data
where sellconfirm = 1
and createon between '2014-02-01 00:00:00' and '2014-05-31 23:59:59'
group by userid;

create table plsport_playsport._mycity3 engine = myisam
SELECT a.userid, a.city, a.city1, b.revenue
FROM plsport_playsport._mycity2 a left join plsport_playsport._mycity_order_data b on a.userid = b.userid
where revenue is not null;

create table plsport_playsport._users_daily_pv_buy_predict engine = myisam
SELECT userid, sum(pv_buy_predict) as pv_buy_predict 
FROM actionlog_users_pv._users_daily_pv_buy_predict
group by userid;

create table plsport_playsport._mycity4 engine = myisam
SELECT a.userid, a.city, a.city1, a.revenue, b.pv_buy_predict
FROM plsport_playsport._mycity3 a left join plsport_playsport._users_daily_pv_buy_predict b on a.userid = b.userid
where pv_buy_predict is not null;

ALTER TABLE  `_mycity4` CHANGE  `userid`  `userid` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table plsport_playsport._mycity5 engine = myisam
SELECT a.userid, b.nickname, a.city, a.city1, a.revenue, a.pv_buy_predict 
FROM plsport_playsport._mycity4 a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._last_time_login engine = myisam
SELECT userid, max(signin_time) as signin_time 
FROM plsport_playsport.member_signin_log_archive
group by userid;

ALTER TABLE  `_last_time_login` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table plsport_playsport._mycity6 engine = myisam
SELECT a.userid, a.nickname, a.city, a.city1, a.revenue, a.pv_buy_predict, b.signin_time
FROM plsport_playsport._mycity5 a left join plsport_playsport._last_time_login b on a.userid = b.userid;

SELECT * FROM plsport_playsport._mycity6
where city1 = 'KHH';

# ==================================================
# 2014/5/21 追加任務 - 要補上電腦和手機的使用情況
# ==================================================

use actionlog;
	ALTER TABLE  `action_201312` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE  `action_201401` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE  `action_201402` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE  `action_201403` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE  `action_201404` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE  `action_201405` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

	ALTER TABLE plsport_playsport._mycity6 ADD INDEX (`userid`); 

create table actionlog._temp_action_201312 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201312 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
create table actionlog._temp_action_201401 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201401 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
create table actionlog._temp_action_201402 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201402 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
create table actionlog._temp_action_201403 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201403 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
create table actionlog._temp_action_201404 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201404 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
create table actionlog._temp_action_201405 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201405 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;

create table actionlog._temp_action engine = myisam select * from actionlog._temp_action_201312;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201401;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201402;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201403;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201404;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201405;


use plsport_playsport;

create table plsport_playsport._mycity7 engine = myisam
SELECT userid, platform_type, count(userid) as c
FROM actionlog._temp_action
group by userid, platform_type;

create table plsport_playsport._mycity7_desktop engine = myisam
select a.userid, a.p, sum(a.c) as c_desktop
from (
	SELECT userid, platform_type, 
		(case when (platform_type = 1) then '1' 
			  when (platform_type = 2) then '2' else '2' end) as p, c
	FROM plsport_playsport._mycity7) as a
where a.p = '1'
group by a.userid, a.p;

create table plsport_playsport._mycity7_mobile engine = myisam
select a.userid, a.p, sum(a.c) as c_mobile
from (
	SELECT userid, platform_type, 
		(case when (platform_type = 1) then '1' 
			  when (platform_type = 2) then '2' else '2' end) as p, c
	FROM plsport_playsport._mycity7) as a
where a.p = '2'
group by a.userid, a.p;

select c.userid, c.nickname, c.city1, c.revenue, c.pv_buy_predict, c.signin_time, c.c_desktop, d.c_mobile
from (
	SELECT a.userid, a.nickname, a.city, a.city1, a.revenue, a.pv_buy_predict, a.signin_time, b.c_desktop
	FROM plsport_playsport._mycity6 a left join plsport_playsport._mycity7_desktop b on a.userid = b.userid) as c
    left join plsport_playsport._mycity7_mobile as d on c.userid = d.userid
where c.city1 = 'KHH';


# =================================================================================================
# 
# 2014/5/16 消費者儲值金額分布比例(福利班
#- Eddy，為了執行優惠活動，需要消費者儲值金額的資料，想瞭解儲值多少錢的人可以界定為VIP，分別需要
#
#- 1. 儲值金額的分布，需要知道儲值總金額多少錢，約是站上的前幾%，人數有多少？ 
#-     時間維度可以 a. 開站至今。b. 依年度
#
#- 2. 在上述報表中，需要撈出一筆名單用做訪談，請撈開站至今儲值總金額前30名消費者。需要以下資料，
#-     a. 儲值總金額
#-     b. 一年內儲值總金額
#-     c. 最大筆儲值金額
#-     d. 上次登入時間
#
#- 排序時，請依上次登入時間排列。
# 
# =================================================================================================

create table plsport_playsport._order_data_redeem_level engine = myisam
select a.userid, a.y, a.m, sum(price) as redeem
from (
	SELECT userid, createon, substr(createon,1,4) as y, substr(createon,1,7) as m, price, payway
	FROM plsport_playsport.order_data
	where payway in (1,2,3,4,5,6) 
	and sellconfirm = 1) as a
group by a.userid, a.y, a.m;

create table plsport_playsport._order_data_redeem_level_1 engine = myisam
SELECT a.userid, b.nickname, b.createon as join_date ,a.y, a.m, a.redeem
FROM plsport_playsport._order_data_redeem_level a left join plsport_playsport.member b on a.userid = b.userid;

#-     時間維度可以 a. 開站至今。b. 依年度
create table plsport_playsport._order_data_redeem_level_all_time engine = myisam
select a.userid, a.nickname, a.join_date ,a.total_redeem
from (
	SELECT userid, nickname, join_date, sum(redeem) as total_redeem
	FROM plsport_playsport._order_data_redeem_level_1
	group by userid) as a
order by a.total_redeem desc;

#-     時間維度可以 a. 開站至今。b. 依年度
create table plsport_playsport._order_data_redeem_level_by_year engine = myisam
select a.userid, a.nickname, a.join_date, a.y, a.total_redeem
from (
	SELECT userid, nickname, join_date, y, sum(redeem) as total_redeem
	FROM plsport_playsport._order_data_redeem_level_1
	group by userid, y) as a
order by a.total_redeem desc;

ALTER TABLE  `_order_data_redeem_level_all_time` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_order_data_redeem_level_by_year` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

select 'userid', 'nickname', 'join_date', 'total_redeem' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_all_time.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._order_data_redeem_level_all_time);

select 'userid', 'nickname', 'join_date', 'y','total_redeem' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_by_year.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._order_data_redeem_level_by_year);


#-     b. 一年內儲值總金額
create table plsport_playsport._order_data_redeem_within_one_year engine = myisam
select b.userid, sum(b.redeem) as redeem_in_one_year
from (
	select a.userid, a.y, a.m, sum(price) as redeem
	from (
		SELECT userid, createon, substr(createon,1,4) as y, substr(createon,1,7) as m, price, payway
		FROM plsport_playsport.order_data
		where payway in (1,2,3,4,5,6) 
		and sellconfirm = 1
		and createon between subdate(now(),356) and now() ) as a
	group by a.userid, a.y, a.m) as b
group by b.userid;

ALTER TABLE  `_order_data_redeem_within_one_year` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

#-     c. 最大筆儲值金額
create table plsport_playsport._order_data_redeem_max_and_min engine = myisam
SELECT userid, min(price) as min_redeem, max(price) as max_redeem
FROM plsport_playsport.order_data
where payway in (1,2,3,4,5,6) 
and sellconfirm = 1
group by userid;

ALTER TABLE  `_order_data_redeem_max_and_min` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

#-     d. 上次登入時間
create table plsport_playsport._last_time_login engine = myisam
SELECT userid, max(signin_time) as signin_time 
FROM plsport_playsport.member_signin_log_archive
group by userid;

ALTER TABLE  `_last_time_login` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;


	ALTER TABLE plsport_playsport._order_data_redeem_within_one_year ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._order_data_redeem_max_and_min ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);

# 最後名單-完成
create table plsport_playsport._order_data_redeem_full_list engine = myisam
select e.userid, e.nickname, e.join_date, e.total_redeem, e.redeem_in_one_year, e.min_redeem, e.max_redeem, f.signin_time
from (
	select c.userid, c.nickname, c.join_date, c.total_redeem, c.redeem_in_one_year, d.min_redeem, d.max_redeem
	from (
		select a.userid, a.nickname, a.join_date, a.total_redeem, b.redeem_in_one_year
		from plsport_playsport._order_data_redeem_level_all_time a left join plsport_playsport._order_data_redeem_within_one_year b on a.userid = b.userid) as c
		left join plsport_playsport._order_data_redeem_max_and_min as d on c.userid = d.userid) as e 
    left join plsport_playsport._last_time_login as f on e.userid = f.userid;

ALTER TABLE  `_order_data_redeem_full_list` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

select 'userid', 'nickname', '加入會員', '總儲值', '近一年儲值', '最低儲值', '最高儲值', '最後一次登入時間' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_full_list.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._order_data_redeem_full_list);



# =================================================================================================
# 購買預測APP-研究各消費階層使用信用卡的比例
# 說明
#   目的：了解各消費階層使用信用卡的比例
#   時間：5/16前提供
#
# 內容
#  - 撈取在站上有使用過信用卡儲值，佔各消費階層的比例
#  - 撈取時間2012.01~2014.04
#  - 需設定消費額度階層(由EDDY設定)
#  - 了解哪種金額是使用信用卡最多的
# 
# =================================================================================================

# 產生主要資料表
create table plsport_playsport._order_data_card_user engine = myisam
SELECT userid, createon, substr(createon,1,4) as y, substr(createon,1,7) as m, price, payway
FROM plsport_playsport.order_data
where payway in (1,2,3,4,5,6) 
and sellconfirm = 1
and createon between '2012-01-01 00:00:00' and '2014-04-30 23:59:59';

# 依年度來算
SELECT y, payway, sum(price) as total_redeem 
FROM plsport_playsport._order_data_card_user
group by y, payway;

# 總共有多少人儲值過 - 11831
select count(a.userid) 
from (
	SELECT userid, sum(price) 
	FROM plsport_playsport._order_data_card_user
	group by userid) as a;

# 總共有多少人儲值過(用信用卡) - 2807
select count(a.userid)
from (
	SELECT userid, sum(price)  
	FROM plsport_playsport._order_data_card_user
	where payway = 6
	group by userid) as a;

# a
create table plsport_playsport._order_data_card_user_a engine = myisam
select a.userid, a.total_redeem
from (
	SELECT userid, sum(price) as total_redeem 
	FROM plsport_playsport._order_data_card_user
	group by userid) as a 
order by a.total_redeem desc;

# b
create table plsport_playsport._order_data_card_user_b engine = myisam
select a.userid, a.pay, (case when (a.pay is not null) then 'credit' end ) as ifpaycredit
from (
	SELECT userid, sum(price) as pay
	FROM plsport_playsport._order_data_card_user
	where payway = 1
	group by userid) as a;

# a left join b = c
create table plsport_playsport._order_data_card_user_c engine = myisam
select a.userid, a.total_redeem, b.pay, b.ifpaycredit
from plsport_playsport._order_data_card_user_a as a left join plsport_playsport._order_data_card_user_b  as b on a.userid = b.userid;

select 'userid', 'total_redeem', 'pay', 'ifpaycredit' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_card_user_c.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._order_data_card_user_c);


# =================================================================================================
# 2014/5/26
# 討論區重度發文者訪談 - 訪談名單
# 說明: 訪談名單直接從user_complete.csv匯入excel即可, 但額外欄位需新另外增
#
# 新增 D2、D5 資料欄位
#	 請新增下列欄位
#	 - 分身 (是否有分身記錄)
#	 - 居住地 (問卷、udata、現金認證)
#	 - 禁文次數
#
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# a:禁文次數
create table plsport_playsport._gobucket_count engine = myisam
select b.userid, b.nickname, count(b.userid) as gobucket_count
from (
	select a.userid, a.nickname, a.d, count(a.userid) as c
	from (
		SELECT userid, nickname, subjectid, date(startdate) as d 
		FROM plsport_playsport.gobucket
		where type in (1,2,3,99)) as a
	group by a.userid, a.nickname, a.d) as b
group by b.userid, b.nickname;

create table plsport_playsport._gobucket_forever engine = myisam
select c.userid, c.nickname, (case when (c.gobucket_forever > 0) then 'yes' end) as gobucket_forever
from (
	select b.userid, b.nickname, count(b.userid) as gobucket_forever
	from (
		select a.userid, a.nickname, a.d, count(a.userid) as c
		from (
			SELECT userid, nickname, subjectid, date(startdate) as d 
			FROM plsport_playsport.gobucket
			where type in (99)) as a
		group by a.userid, a.nickname, a.d) as b
	group by b.userid, b.nickname) as c;

create table plsport_playsport._gobucket_count_with_forever engine = myisam
select a.userid, a.nickname, a.gobucket_count, b.gobucket_forever
from plsport_playsport._gobucket_count a left join plsport_playsport._gobucket_forever b on a.userid = b.userid;

drop table plsport_playsport._gobucket_count, plsport_playsport._gobucket_forever;

# -------------------------------------------------------------------------------------------------
# b:分身 (是否有分身記錄)
create table plsport_playsport._sell_deny engine = myisam
SELECT master_userid 
FROM plsport_playsport.sell_deny;

insert ignore into plsport_playsport._sell_deny SELECT slave_userid FROM plsport_playsport.sell_deny;

create table plsport_playsport._sell_deny_remove_duplicate engine = myisam
SELECT master_userid as multiid, count(master_userid) as c
FROM plsport_playsport._sell_deny
group by master_userid;

# -------------------------------------------------------------------------------------------------
# c:住址1 - exchange_validate
create table plsport_playsport._city_info engine = myisam
SELECT userid, city FROM plsport_playsport.exchange_validate;

# 住址2 - user_living_city
insert ignore into plsport_playsport._city_info
SELECT userid, city
FROM plsport_playsport.user_living_city
where action = 1 ;

# 住址3 - udata
insert ignore into plsport_playsport._city_info
SELECT userid, city
FROM plsport_playsport.udata;

create table plsport_playsport._city_info_ok engine = myisam
SELECT userid, city
FROM plsport_playsport._city_info
group by userid;

create table plsport_playsport._city_info_ok_with_chinese engine = myisam
SELECT userid, city, 
			(case when (city =1)  then'臺北市'
			when (city       =2)  then'新北市'
			when (city       =3)  then'桃園縣'
			when (city       =4)  then'新竹市'
			when (city       =5)  then'新竹縣'
			when (city       =6)  then'苗栗縣'
			when (city       =7)  then'臺中市'
			when (city       =8)  then'臺中市'
			when (city       =9)  then'彰化縣'
			when (city       =10) then'南投縣'
			when (city       =11) then'嘉義市'
			when (city       =12) then'嘉義縣'
			when (city       =13) then'雲林縣'
			when (city       =14) then'臺南市'
			when (city       =15) then'臺南市'
			when (city       =16) then'高雄市'
			when (city       =17) then'高雄市'
			when (city       =18) then'屏東縣'
			when (city       =19) then'宜蘭縣'
			when (city       =20) then'花蓮縣'
			when (city       =21) then'臺東縣'
			when (city       =22) then'澎湖縣'
			when (city       =23) then'金門縣'
			when (city       =24) then'連江縣'
			when (city       =25) then'南海諸島' else '不明' end) as city1
FROM plsport_playsport._city_info_ok;
# -------------------------------------------------------------------------------------------------
# a+b+c
ALTER TABLE  `_city_info_ok_with_chinese` CHANGE  `userid`  `userid` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_sell_deny_remove_duplicate` CHANGE  `multiid`  `multiid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_gobucket_count_with_forever` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table plsport_playsport._multiid_city_sell_deny engine = myisam
select e.id, e.userid, e.g, e.multi_id, e.city1, f.gobucket_count, f.gobucket_forever
from (
	select c.id, c.userid, c.g, c.multi_id, d.city1
	from (
		SELECT a.id, a.userid, a.g, b.c as multi_id
		FROM user_cluster.cluster_with_real_userid a left join plsport_playsport._sell_deny_remove_duplicate b on a.userid = b.multiid) c
		left join plsport_playsport._city_info_ok_with_chinese d on c.userid = d.userid) e
    left join plsport_playsport._gobucket_count_with_forever f on e.userid = f.userid;

# 輸出csv
select 'id', 'userid', 'g', 'multi_id', 'city1', 'gobucket_count', 'gobucket_forever' union (
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/_multiid_city_sell_deny.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._multiid_city_sell_deny);



# =================================================================================================
# 2014/5/26
# 販售分析文 - 問卷名單
# 1. 提供名單
# 篩選條件：2011/5至今寫過10篇以上最讚分析文 
# 最讚分析文是被收錄在analysis_king中
# =================================================================================================

/*找出FEB到APR之間的最讚分析文*/
create table plsport_playsport._analysis_king engine = myisam 
SELECT userid, subjectid, got_time, gamedate, 
	   (case when (subjectid is not null) then 'y' end) as isanalysispost
FROM plsport_playsport.analysis_king
where got_time between '2011-05-01 00:00:00' and '2014-05-25 23:59:59'
order by got_time desc;

create table plsport_playsport._analysis_king_count engine = myisam 
select a.userid, b.nickname, a.analysis_c
from (
	SELECT userid, count(userid) as analysis_c 
	FROM plsport_playsport._analysis_king
	group by userid) a left join plsport_playsport.member b on a.userid = b.userid;

select 'userid', 'nickname','analysis_king_count' union (
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_king_count.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._analysis_king_count);



