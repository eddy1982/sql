
-- ███████╗██████╗ ██████╗ ██╗   ██╗    ███████╗ ██████╗ ██╗     
-- ██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔════╝██╔═══██╗██║     
-- █████╗  ██║  ██║██║  ██║ ╚████╔╝     ███████╗██║   ██║██║     
-- ██╔══╝  ██║  ██║██║  ██║  ╚██╔╝      ╚════██║██║▄▄ ██║██║     
-- ███████╗██████╔╝██████╔╝   ██║       ███████║╚██████╔╝███████╗
-- ╚══════╝╚═════╝ ╚═════╝    ╚═╝       ╚══════╝ ╚══▀▀═╝ ╚══════╝

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

/*  最近120天內的貼文次數和影響度*/
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

/*  最近120天內的回文次數*/
create table user_cluster._user_reply engine = myisam
select a.userid, count(a.subjectid) as reply_count
from (
    SELECT subjectid, userid, postdate 
    FROM plsport_playsport.forumcontent /*目前就直接捉全部的*/
    where contenttype=1 and postdate between subdate(now(),120) and now()) as a
group by a.userid;


#===========================================================================================
#    update: 2014/3/20 
#    研究過去的貼文紅人
#===========================================================================================
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

        --  ALTER TABLE plsport_playsport._forum_heavy_poster ADD INDEX (`userid`);
        --  ALTER TABLE plsport_playsport.member ADD INDEX (`userid`);
        --  ALTER TABLE plsport_playsport._forum ADD INDEX (`postuser`);
        --  ALTER TABLE  plsport_playsport.member CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        --  ALTER TABLE  plsport_playsport._forum CHANGE  `postuser`  `postuser` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        --  ALTER TABLE  plsport_playsport._forum_heavy_poster CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

        -- /*_forum join _forum_heavy_poster*/
        -- create table plsport_playsport._from_heavy_poster_each_month engine = myisam
        -- select b.m, c.id, b.userid, b.nickname, b.c
        -- from (
        --  select a.m, a.userid, a.nickname, count(a.subjectid) as c
        --  from (
        --      SELECT a.subjectid, a.allianceid, a.alliancename, a.postuser as userid, a.nickname, a.m
        --      FROM plsport_playsport._forum a inner join plsport_playsport._forum_heavy_poster b on a.postuser = b.userid) as a
        --  group by a.m, a.userid) b left join plsport_playsport.member c on b.userid = c.userid;


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


#===========================================================================================
#    只計算出最近7天的儲值總額
#    to select certian peried time
#===========================================================================================

select 'date', 'revenue' union(
select a.d, sum(price) as total_redeem
into outfile 'C:/Python27/eddy_python/www_process.csv'
from (
    SELECT id, userid, date(createon) as d, price 
    FROM www.order_data
    where sellconfirm = 1
    and createon between subdate(date(now()),7) and subdate(date(now()),0)) as a/*7 days*/
group by a.d); 


#===========================================================================================
#    update:2014/3/26
#    調察爺爺泡的茶log
#===========================================================================================
select b.uri_2, b.platform_type, count(b.id) as c
from (
    select a.id, a.userid, (case when (a.uri_1='') then 'index' else a.uri_1 end ) as uri_2, a.time, a.platform_type
    from (
        SELECT id, userid, uri, substr(uri,2, (locate('.php',uri))-2) as uri_1, time, platform_type 
        FROM actionlog._grandpa) as a) as b
group by b.uri_2, b.platform_type;



#===========================================================================================
#    2014/4/1儲值優惠活動
#    update:2014/3/26
#    福利班D2,D3簡訊名單
#    去年 4~10月，儲值金額超過199的名單
#===========================================================================================
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

#=============================================
#   update 2014-05-02追蹤分析(柔雅的任務)
#=============================================

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


#=============================================
#    福利班追加任務 2014/4/11    
#=============================================

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


#=============================================
#   柔雅追加任務 2014/7/8                     
#=============================================

create table plsport_playsport._who_redeem_in_apr_1 engine = myisam  #誰在4/1當日儲值
SELECT userid, createon, ordernumber, sum(price) as redeem, payway, create_from
FROM plsport_playsport.order_data
where sellconfirm = 1 
and create_from = 8
and createon between '2014-04-01 00:00:00' and '2014-04-01 23:59:59'
group by userid;

        create table plsport_playsport._who_redeem_in_apr_1_max engine = myisam  #誰在4/1當日儲值(最大金額)
        SELECT userid, createon, ordernumber, max(price) as redeem_max, payway, create_from
        FROM plsport_playsport.order_data
        where sellconfirm = 1 
        and create_from = 8
        and createon between '2014-04-01 00:00:00' and '2014-04-01 23:59:59'
        group by userid;

create table plsport_playsport._who_redeem_before_apr_1 engine = myisam  #誰在4/1之前儲值
SELECT userid, sum(price) as redeem_before_apr_1  
FROM plsport_playsport.order_data
where sellconfirm = 1
and createon between '2010-01-01 00:00:00' and '2014-03-31 23:59:59'
group by userid;

        create table plsport_playsport._who_redeem_before_apr_1_max engine = myisam  #誰在4/1之前儲值(最大金額)
        SELECT userid, max(price) as redeem_before_apr_1_max  
        FROM plsport_playsport.order_data
        where sellconfirm = 1
        and createon between '2010-01-01 00:00:00' and '2014-03-31 23:59:59'
        group by userid;

create table plsport_playsport._who_redeem_after_apr_1 engine = myisam  #誰在4/1之後當日儲值
SELECT userid, sum(price) as redeem_after_apr_1  
FROM plsport_playsport.order_data
where sellconfirm = 1
and createon between '2014-04-02 00:00:00' and '2014-06-30 23:59:59'
group by userid;

        create table plsport_playsport._who_redeem_after_apr_1_max engine = myisam  #誰在4/1之後當日儲值(最大金額)
        SELECT userid, max(price) as redeem_after_apr_1_max 
        FROM plsport_playsport.order_data
        where sellconfirm = 1
        and createon between '2014-04-02 00:00:00' and '2014-06-30 23:59:59'
        group by userid;

ALTER TABLE plsport_playsport._who_redeem_in_apr_1 ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._who_redeem_in_apr_1_max ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_before_apr_1 ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_before_apr_1_max ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_after_apr_1 ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_after_apr_1_max ADD INDEX (`userid`); 


create table plsport_playsport._main_redeem_1 engine = myisam
select c.userid, c.createon, c.ordernumber, c.redeem_before_apr_1_max, c.redeem_max, d.redeem_after_apr_1_max
from (
    SELECT a.userid, a.createon, a.ordernumber, b.redeem_before_apr_1_max, a.redeem_max
    FROM plsport_playsport._who_redeem_in_apr_1_max a left join plsport_playsport._who_redeem_before_apr_1_max b on a.userid = b.userid) as c
    left join plsport_playsport._who_redeem_after_apr_1_max d on c.userid = d.userid;

create table plsport_playsport._main_redeem_2 engine = myisam
select c.userid, c.createon, c.ordernumber, c.redeem_before_apr_1, c.redeem, d.redeem_after_apr_1
from (
    SELECT a.userid, a.createon, a.ordernumber, b.redeem_before_apr_1, a.redeem
    FROM plsport_playsport._who_redeem_in_apr_1 a left join plsport_playsport._who_redeem_before_apr_1 b on a.userid = b.userid) as c
    left join plsport_playsport._who_redeem_after_apr_1 d on c.userid = d.userid;

create table plsport_playsport._main_redeem_3 engine = myisam
SELECT a.userid, a.createon, a.ordernumber, a.redeem_before_apr_1_max, a.redeem_max, a.redeem_after_apr_1_max, 
       b.redeem_before_apr_1, b.redeem, b.redeem_after_apr_1
FROM plsport_playsport._main_redeem_1 a left join plsport_playsport._main_redeem_2 b on a.userid = b.userid;


create table plsport_playsport._who_redeem_when_next_time engine = myisam  #誰在4/1之後當日儲值
SELECT userid, min(createon) as next_time, price as next_redeem
FROM plsport_playsport.order_data
where sellconfirm = 1
and createon between '2014-04-02 00:00:00' and '2014-06-30 23:59:59'
group by userid;

create table plsport_playsport._main_redeem_4 engine = myisam
SELECT a.userid, a.createon, a.ordernumber, a.redeem_before_apr_1_max, a.redeem_max, a.redeem_after_apr_1_max, 
       a.redeem_before_apr_1, a.redeem, a.redeem_after_apr_1, b.next_time, b.next_redeem
FROM plsport_playsport._main_redeem_3 a left join plsport_playsport._who_redeem_when_next_time b on a.userid = b.userid;

#===========================================================================================
# 麻煩再幫我們分析: 2014-07-14
# 使用者活動前後的arpu，查看該使用者在活動結束後的arpu是否有增高。
# 1. 有用到優惠的人
# 2. 沒有用到優惠的人
#===========================================================================================

create table plsport_playsport._who_redeem_in_apr_1_max engine = myisam  #誰在4/1當日儲值(最大金額)
SELECT userid, createon, ordernumber, max(price) as redeem_max, payway, create_from
FROM plsport_playsport.order_data
where sellconfirm = 1 
and create_from = 8
and createon between '2014-04-01 00:00:00' and '2014-04-01 23:59:59'
group by userid;

create table plsport_playsport._who_redeem_in_apr_1_max_14_days engine = myisam  #誰在4/1當日儲值(最大金額)
SELECT userid, createon, ordernumber, max(price) as redeem_max, payway, create_from
FROM plsport_playsport.order_data
where sellconfirm = 1 
and createon between '2014-03-25 00:00:00' and '2014-04-05 23:59:59'
group by userid;

create table plsport_playsport._who_not_redeem_in_apr_1_max engine = myisam
SELECT a.userid, a.createon, a.ordernumber, a.redeem_max, a.payway, a.create_from 
FROM plsport_playsport._who_redeem_in_apr_1_max_14_days a left join plsport_playsport._who_redeem_in_apr_1_max b on a.userid = b.userid
where b.userid is null;


create table plsport_playsport._list_A engine = myisam
SELECT userid, (case when (userid is not null) then 'A' end) as g 
FROM plsport_playsport._who_redeem_in_apr_1_max;

create table plsport_playsport._list_B engine = myisam
SELECT userid, (case when (userid is not null) then 'B' end) as g
FROM plsport_playsport._who_not_redeem_in_apr_1_max;


create table plsport_playsport._list engine = myisam SELECT * FROM plsport_playsport._list_A;
insert ignore into plsport_playsport._list SELECT * FROM plsport_playsport._list_B;


create table plsport_playsport._redeem_next_3_months engine = myisam  
SELECT userid, substr(createon,1,7) as m, sum(price) as redeem, count(price) as redeem_count
FROM plsport_playsport.order_data
where sellconfirm = 1 
and createon between '2014-04-06 00:00:00' and '2014-07-05 23:59:59'
group by userid, m;

select c.g, c.m, sum(c.redeem) as redeem, count(c.userid) as users
from (
    SELECT a.userid, a.m, a.redeem, a.redeem_count, b.g 
    FROM plsport_playsport._redeem_next_3_months a left join plsport_playsport._list b on a.userid = b.userid
    where b.g is not null and a.redeem < 17000) as c 
group by c.g, c.m;


select d.g, sum(d.redeem) as redeem , count(d.userid) as users
from (
    select c.userid, sum(c.redeem) as redeem, c.g
    from (
        SELECT a.userid, a.m, a.redeem, a.redeem_count, b.g 
        FROM plsport_playsport._redeem_next_3_months a left join plsport_playsport._list b on a.userid = b.userid
        where b.g is not null and a.redeem < 17000) as c
    group by c.userid) as d
group by d.g;


#===========================================================================================
#    update:2014/4/3
#    分析文觀看比例
#    請調查 2014/1/9, 3/6有觀看最讚分析文的會員比例
#    舉例來說：3/6共有 2000人觀看當日發表的最讚分析文，佔當日有看討論區會員的 20%
#===========================================================================================
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


#===========================================================================================
#    update:2014/4/10
#    任務: [201404-A-2] 販售分析文 - 訪談名單
#    名單條件
#        1. 愛看分析文的人
#            2014/1~3月觀看最讚分析文章次數較多者，並列出其總儲值金額
#        1.1追加補充 (2014-05-01)
#            2014/2~3月觀看最讚分析文章次數較多者，並列出其總儲值金額
#
#        2. 分析文寫手
#            請提供2013/4 ~ 2014/3有當過優質分析王的使用者，並列出個別使用
#            者的最讚分析文總數及最讚分析文平均推數、回文數
#===========================================================================================
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



#===========================================================================================
#    update:2014/4/3
#    即時比分加上殺手推薦 - 研究未登入使用者路徑
#    1. 每天有多少未登入使用者是直接進到即時比分頁
#    2. 呈上題，多少未登入使用者除了即時比分外，沒有使用其他功能
#===========================================================================================

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



#===========================================================================================
#    2014/4/29
#    購牌專區的問券
#===========================================================================================

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


#=============================================
#         action_log url解析的SQL
#=============================================
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


#===========================================================================================
#    購牌位置代碼解析
#    需要的tables
#    (1)predict_buyer
#    (2)predict_seller
#    (3)predict_buyer_cons_split
#===========================================================================================
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

#version 2 (只有看單月的收益)
select b.p, sum(b.revenue) as revenue
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
        where buy_date between '2014-04-19 00:00:00' and '2014-04-30 23:59:59'
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


#===========================================================================================
#    2014/4/29
#    個人頁的預測表格分析
#    
#    實驗觀察區間: 2014/4/15~5/7
#    組別: 1,2,3
#===========================================================================================

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
#   (1)udata
#   (2)user_living_city
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
    ALTER TABLE  `action_201406` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE  `action_201407` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

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
create table actionlog._temp_action_201406 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201406 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
create table actionlog._temp_action_201407 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201407 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;

create table actionlog._temp_action engine = myisam select * from actionlog._temp_action_201312;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201401;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201402;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201403;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201404;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201405;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201406;
insert ignore into actionlog._temp_action select * from actionlog._temp_action_201407;

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

create table plsport_playsport._mycity8 engine = myisam
select c.userid, c.nickname, c.city1, c.revenue, c.pv_buy_predict, c.signin_time, c.c_desktop, d.c_mobile
from (
    SELECT a.userid, a.nickname, a.city, a.city1, a.revenue, a.pv_buy_predict, a.signin_time, b.c_desktop
    FROM plsport_playsport._mycity6 a left join plsport_playsport._mycity7_desktop b on a.userid = b.userid) as c
    left join plsport_playsport._mycity7_mobile as d on c.userid = d.userid
where c.city1 = 'KHH';

# ==================================================
# 2014/5/26 追加任務 - 要補上購牌專區的左右區塊pv
# ==================================================

create table actionlog._temp_action_201405 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri),length(uri)) as p, time
FROM actionlog.action_201405
where uri like '%rp=BZ%'
and userid <> '';

create table actionlog._temp_action_201404 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri),length(uri)) as p, time
FROM actionlog.action_201404
where uri like '%rp=BZ%'
and userid <> '';

create table actionlog._temp_action_201404_05_buypredict engine = myisam select * from actionlog._temp_action_201404;
insert ignore into actionlog._temp_action_201404_05_buypredict select * from actionlog._temp_action_201405;
drop table actionlog._temp_action_201405, actionlog._temp_action_201404;

create table actionlog._temp_action_201404_05_buypredict_1 engine = myisam
SELECT * 
FROM actionlog._temp_action_201404_05_buypredict
where right(p,1) <> '.'
and p <> 'rp=BZ_RCTB'
and length(p) < 15;

create table actionlog._temp_action_201404_05_buypredict_2 engine = myisam
SELECT userid, p, time, (case when (p = 'rp=BZ_MF') then 'area_L'
                              when (p = 'rp=BZ_SK') then 'area_L' else 'area_R' end) as p1
FROM actionlog._temp_action_201404_05_buypredict_1;


# 左邊區塊
create table actionlog._user_buypredict_pv_area_L
SELECT userid, count(userid) as pv_area_L 
FROM actionlog._temp_action_201404_05_buypredict_2
where p1 = 'area_L'
group by userid;

# 右邊區塊
create table actionlog._user_buypredict_pv_area_R
SELECT userid, count(userid) as pv_area_R 
FROM actionlog._temp_action_201404_05_buypredict_2
where p1 = 'area_R'
group by userid;


select c.userid, c.nickname, c.city1, c.revenue, c.pv_buy_predict, c.signin_time, c.c_desktop, c.c_mobile, c.pv_area_L, d.pv_area_R
from (
    SELECT a.userid, a.nickname, a.city1, a.revenue, a.pv_buy_predict, a.signin_time, a.c_desktop, a.c_mobile, b.pv_area_L
    FROM plsport_playsport._mycity8 a left join actionlog._user_buypredict_pv_area_L b on a.userid = b.userid) c
    left join actionlog._user_buypredict_pv_area_R d on c.userid = d.userid;



# =================================================================================================
# 
# 2014/5/16 VIP消費者儲值金額分布比例(福利班)
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


# 任務: 儲值金額分佈資料撈取 [新建] 2014-09-25
# 
# TO EDDY:
#   
#   煩請協助撈取
# 
# 1.開站以來與每年的儲值金額分佈，更新至今年8月。 
# 2.將前1%的詳細儲值金額另外制成一個表，想了解前1%的消費者，儲值的差距有多大。
# 以上資料將用於VIP制度規劃，可查看此文件。


            select 'userid', 'join_date', 'total_redeem' union (
            SELECT userid, join_date, total_redeem
            into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_all_time.csv' 
            fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
            FROM plsport_playsport._order_data_redeem_level_all_time);

            select 'userid', 'join_date', 'y','total_redeem' union (
            SELECT userid, join_date, y, total_redeem
            into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_by_year.csv' 
            fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
            FROM plsport_playsport._order_data_redeem_level_by_year);

            ALTER TABLE plsport_playsport._order_data_redeem_level_all_time ADD INDEX (`userid`);
            ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);

            create table plsport_playsport._last_signin engine = myisam # 最近一次登入
            SELECT userid, max(signin_time) as last_signin
            FROM plsport_playsport.member_signin_log_archive
            group by userid;

            SELECT a.userid, a.nickname, a.join_date, b.last_signin, a.total_redeem  
            FROM plsport_playsport._order_data_redeem_level_all_time a left join plsport_playsport._last_signin b on a.userid = b.userid
            order by a.total_redeem desc
            limit 0, 100;


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
#    請新增下列欄位
#    - 分身 (是否有分身記錄)
#    - 居住地 (問卷、udata、現金認證)
#    - 禁文次數
#
# =================================================================================================

use plsport_playsport;
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
            when (city       =25) then'南海諸島' else '不明' end) as city1 #0是基隆市或真的沒有,所以標不明
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
select a.userid, b.nickname, date(b.createon) as join_date, a.analysis_c
from (
    SELECT userid, count(userid) as analysis_c 
    FROM plsport_playsport._analysis_king
    group by userid) a left join plsport_playsport.member b on a.userid = b.userid;

select 'userid', 'nickname','analysis_king_count' union (
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_king_count.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._analysis_king_count);

# 2014-06-09分析問卷的任務

create table plsport_playsport._analysis_king_count_1 engine = myisam
SELECT * FROM plsport_playsport._analysis_king_count
where analysis_c > 4
order by analysis_c desc;

ALTER TABLE  `_analysis_king_count_1` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_analysis_king_count_1` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

create table plsport_playsport._analysis_king_count_2 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.analysis_c, b.spend_minute, b.iswillingto, b.ruleaggrement, b.rulesuggestion, b.ruleencouraged, b.price, b.reasonstopwriting
FROM plsport_playsport._analysis_king_count_1 a left join plsport_playsport.questionnaire_sellanalysis_answer b on a.userid = b.userid;


UPDATE plsport_playsport._analysis_king_count_2 set rulesuggestion = TRIM(rulesuggestion);  #刪掉空白字完
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '.',''); 
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, ';','');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '/','');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '\\','_');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '"','');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '&','');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '#','');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, ' ','');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '\r','');
update plsport_playsport._analysis_king_count_2 set rulesuggestion = replace(rulesuggestion, '\n','');

select 'userid', 'nickname','join_date','analysis_count','spend_minute','iswillingto','ruleaggrement','rulesuggestion','ruleencouraged','price','reasonstopwriting' union (
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_king_count_2.csv'
fields terminated by ';' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._analysis_king_count_2);


# =================================================================================================
# 殺手簡訊發送名單的產生與效益追蹤 (福利班)
#   
# 名單篩選條件
# 
# 1. 2013年起至今，曾儲值過
# 2. 已有三個月未登入、購買、儲值
# 3. 依照儲值總金額排序，越高的優先發送
# 4. 每次至多2000筆，匯出CSV或txt
# 5. 每一筆有效號碼，不要連續傳送，相隔一個月以上
# 6. 電話號碼必須排除分身、拒收簡訊、無效號碼、+886、海外電話、市話
# 7. 其他
#
# 需要的資料表: (1) order_data, (2) member_signin_log_archive
# =================================================================================================

create database textcampaign;

use textcampaign;

drop table if exists _list1, _list2, _list3, _list4, _recent_login, _who_dont_want_text; 

# 主名單: 近550天內曾經儲值過的人, 並有符合電話格式(10碼)
create table textcampaign._list1 engine = myisam
select a.userid, a.phone, sum(a.price) as total_redeem
from (
    SELECT userid, phone, createon, price 
    FROM plsport_playsport.order_data
    where sellconfirm = 1 and payway in (1,2,3,4,5,6)
    and createon between subdate(now(),720) and now()) as a
where length(phone) = 10 and substr(phone,1,2) = '09' and phone regexp '^[[:digit:]]{10}$'
group by a.userid
order by a.userid;

# 拒收簡訊名單
create table textcampaign._who_dont_want_text engine = myisam
select a.phone
from (
    SELECT userid, phone 
    FROM plsport_playsport.order_data
    where receive_ad = 0) as a
group by a.phone;

# 近3個月內有登入的人(如果人數很多的話, 視情況可修改為近1個月)
create table textcampaign._recent_login engine = myisam
select a.userid, count(a.userid) as c, (case when (a.userid is not null) then 'yes' end) as recent_login
from (
    SELECT * 
    FROM plsport_playsport.member_signin_log_archive
    where signin_time between subdate(now(),31) and now() # 設定為3個月(如果人數很多的話, 視情況可修改為近1個月, 預設31)
    order by signin_time) as a
group by a.userid;

# 每個人最後一次登入是何日
create table textcampaign._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
group by userid;

    ALTER TABLE `_list1` CHANGE `userid` `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE `_recent_login` CHANGE `userid` `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE `_last_time_login` CHANGE `userid` `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE _last_time_login ADD INDEX (`userid`);

# 主名單: 加入誰近3個月內有登入
create table textcampaign._list2 engine = myisam
SELECT a.userid, a.phone, a.total_redeem, b.recent_login
FROM textcampaign._list1 a left join textcampaign._recent_login b on a.userid = b.userid;

# 主名單: 排除掉拒收簡訊名單
create table textcampaign._list3 engine = myisam
SELECT a.userid, a.phone, total_redeem, a.recent_login
FROM textcampaign._list2 a left join textcampaign._who_dont_want_text b on a.phone = b.phone
where b.phone is null;

# 主名單: 排除最近有登入的人
create table textcampaign._list4 engine = myisam
SELECT * 
FROM textcampaign._list3
where recent_login is null;

# 主名單: 完整版(加入使用者id, 和最近一次登入日期)
create table textcampaign._list5 engine = myisam
select c.phone, d.id, c.total_redeem, c.last_time_login, (case when (d.id is not null) then 'retention_201406' end) as text_campaign, ((d.id%2)+1) as abtest_group
from (
    SELECT a.userid, a.phone, a.total_redeem, b.last_time_login
    FROM textcampaign._list4 a left join textcampaign._last_time_login b on a.userid = b.userid) as c 
left join plsport_playsport.member as d on c.userid = d.userid; 

# 檢查名單數用
create table textcampaign._count engine = myisam
SELECT phone, count(id)
FROM textcampaign._list5
group by phone;


select 'phone', '使用者編號id', '簡訊行銷', '總儲值金額', '最後一次登入',  'abtest組別' union (
SELECT phone, id, text_campaign, total_redeem, last_time_login, abtest_group 
into outfile 'C:/Users/1-7_ASUS/Desktop/retention_201406.csv'
CHARACTER SET big5 fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM textcampaign._list5);
# 一定要設定為big編碼, yoyo8規定的


# --------------------------------------------
# 8月底了, 開始追蹤 (2014-08-29) 
# 當初是6月2日發送的簡訊 2014-06-02~2014-08-24
# note: 第一次追蹤
# --------------------------------------------

# 開始製作追蹤的名單

create table textcampaign._check_list_1 engine = myisam
SELECT a.phone, a.id, b.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group 
FROM textcampaign._list5 a left join plsport_playsport.member b on a.id = b.id;

create table textcampaign._user_spent engine = myisam
SELECT userid, sum(amount) as spent  
FROM plsport_playsport.pcash_log
where date(date) between '2014-06-02' and '2014-08-24'
and payed = 1 and type = 1
group by userid;

create table textcampaign._user_redeem engine = myisam
SELECT userid, sum(amount) as redeem  
FROM plsport_playsport.pcash_log
where date(date) between '2014-06-02' and '2014-08-24'
and payed = 1 and type in (3,4)
group by userid;

                create table textcampaign._last_time_login_1 engine = myisam
                SELECT userid, date(signin_time) as d 
                FROM plsport_playsport.member_signin_log_archive
                where date(signin_time) between '2014-06-02' and '2014-08-24';

                        ALTER TABLE textcampaign._last_time_login_1 ADD INDEX (`userid`);
                        ALTER TABLE textcampaign._last_time_login_1 ADD INDEX (`d`);

                create table textcampaign._last_time_login_2 engine = myisam
                SELECT userid, d, count(userid) as c 
                FROM textcampaign._last_time_login_1
                group by userid, d;

                create table textcampaign._last_time_login_3 engine = myisam
                SELECT userid, count(d) as signin_days_count
                FROM textcampaign._last_time_login_2
                group by userid;

                drop table textcampaign._last_time_login_1;
                drop table textcampaign._last_time_login_2;

        ALTER TABLE textcampaign._check_list_1 ADD INDEX (`userid`);
        ALTER TABLE textcampaign._user_spent ADD INDEX (`userid`);
        ALTER TABLE textcampaign._user_redeem ADD INDEX (`userid`);
        ALTER TABLE textcampaign._last_time_login_3 ADD INDEX (`userid`);

create table textcampaign._check_list_2 engine = myisam
select c.phone, c.id, c.userid, c.total_redeem, c.last_time_login, c.text_campaign, c.abtest_group, c.spent, d.redeem
from (
    SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, b.spent
    FROM textcampaign._check_list_1 a left join textcampaign._user_spent b on a.userid = b.userid) as c
left join textcampaign._user_redeem as d on c.userid = d.userid;

create table textcampaign._check_list_3 engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, a.spent, a.redeem, b.signin_days_count
FROM textcampaign._check_list_2 a left join textcampaign._last_time_login_3 b on a.userid = b.userid;


select a.m, a.abtest_group, sum(spent), sum(redeem)
from (
    SELECT substr(last_time_login,1,7) as m, abtest_group, spent, redeem 
    FROM textcampaign._check_list_3) as a
group by a.m, a.abtest_group;

# ==================NEW任務==================
# 簡訊流失客延任務 (柔雅) 2014-10-15
# TO EDDY
# 
# 下次流失客簡訊發送日期為10/2號，
# 測試的方向為: (1)重覆發送4000(2000/2000) + (2)殺手報牌2000(1000/1000)
# (1)重覆發送: 與上次相同的名單，發送相同的內容，追蹤成效。
# (2)殺手報牌: 重新撈一組名單(需排除與"重覆發送"相同名單)，
#                  簡訊內容:發送日當天，選擇MLB板標前幾名的殺手，提供殺手免費的預測給流失客。
# 煩請EDDY提供名單與後續的追蹤。
# 名單篩選條件

# 1. 2013年起至今，曾儲值過550天 (和柔雅討論後:從1年半延長至2年-730天)
# 2. 已有1個月未登入、購買、儲值 (和柔雅討論後:維持31天)
# 3. 依照儲值總金額排序，越高的優先發送
# 4. 每次至多2000筆，匯出CSV或txt
# 5. 每一筆有效號碼，不要連續傳送，相隔一個月以上
# 6. 電話號碼必須排除分身、拒收簡訊、無效號碼、+886、海外電話、市話
# 7. 其他


# 要先執行完_list1~_list5
create table textcampaign._list5_to_see_how_many_candidate_available engine = myisam
SELECT a.phone, a.id, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, b.abtest_group as abtest_group1
FROM textcampaign._list5 a left join textcampaign.retention_201406_full_list_dont_delete b on a.id = b.id
where b.abtest_group is null;

create table textcampaign._list6 engine = myisam
SELECT phone, id, total_redeem, last_time_login, (case when (text_campaign is not null) then 'retention_201410b' end) as text_campaign, abtest_group 
FROM textcampaign._list5_to_see_how_many_candidate_available;


select 'phone', '使用者編號id', '簡訊行銷', '總儲值金額', '最後一次登入',  'abtest組別' union (
SELECT phone, id, text_campaign, total_redeem, last_time_login, abtest_group 
into outfile 'C:/Users/1-7_ASUS/Desktop/retention_201410b.csv'
CHARACTER SET big5 fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM textcampaign._list6);
# 一定要設定為big編碼, 
















# =================================================================================================
#  [201401-J-11] 購買後推薦專區 - 優化訪談名單
#   
# 名單篩選條件
# 
# 1. 名單條件
# 5/1至今有用過首頁及購買後推薦專區購買預測的使用者
# 請列出暱稱、噱幣總儲值金額、近三月購買金額、首頁購買金額、購買後推薦專區購買金額、加入會員時間
# =================================================================================================

# 程式碼同960~981
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
# ------------------------------------------------------------------------------------------------

# 先撈出符合的records
create table plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT id, buyerid, id_bought, sellerid, buy_date, buy_price, position, cons, allianceid, substr(position,1,3) as p
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-05-01 00:00:00' and '2014-06-30 23:59:59' # 區間
and position is not null; # 過瀘掉沒有records

create table plsport_playsport._list_1 engine = myisam # 主名單
SELECT buyerid, count(buyerid) as c 
FROM plsport_playsport._predict_buyer_with_cons_1
where p in ('IDX', 'BRC')
group by buyerid;

create table plsport_playsport._list_pay_idx engine = myisam # 用首頁買的人
SELECT buyerid, sum(buy_price) as pay_idx 
FROM plsport_playsport._predict_buyer_with_cons_1
where p in ('IDX')
group by buyerid;

create table plsport_playsport._list_pay_brc engine = myisam # 用購牌後推廌專區買的人
SELECT buyerid, sum(buy_price) as pay_brc 
FROM plsport_playsport._predict_buyer_with_cons_1
where p in ('BRC')
group by buyerid;

create table plsport_playsport._list_order_data engine = myisam # 總儲值金額
SELECT userid, sum(price) as total_redeem 
FROM plsport_playsport.order_data
where payway in (1,2,3,4,5,6) 
and sellconfirm = 1
group by userid;

create table plsport_playsport._list_pcash_log engine = myisam # 近3個月購買金額
SELECT userid, sum(amount) as total_paid 
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1 
and date between subdate(now(),93) and now() # 近3個月
group by userid;

create table plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
group by userid;

    ALTER TABLE plsport_playsport._list_1 ADD INDEX (`buyerid`); 
    ALTER TABLE plsport_playsport._list_pay_idx ADD INDEX (`buyerid`); 
    ALTER TABLE plsport_playsport._list_pay_brc ADD INDEX (`buyerid`); 
    ALTER TABLE plsport_playsport._list_order_data ADD INDEX (`userid`); 
    ALTER TABLE plsport_playsport._list_pcash_log ADD INDEX (`userid`); 

    ALTER TABLE  `_list_1` CHANGE  `buyerid`  `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';
    ALTER TABLE  `_list_pay_brc` CHANGE  `buyerid`  `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';
    ALTER TABLE  `_list_pay_idx` CHANGE  `buyerid`  `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';
    ALTER TABLE  `_list_order_data` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE  `member_signin_log_archive` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;


create table plsport_playsport._list_2 engine = myisam # 主名單
select i.buyerid, i.nickname, i.join_date, i.total_redeem, i.total_paid, i.pay_idx, j.pay_brc
from (
    select g.buyerid, g.nickname, g.join_date, g.total_redeem, g.total_paid, h.pay_idx 
    from (
        select e.buyerid, e.nickname, e.join_date, e.total_redeem, f.total_paid 
        from (
            select c.buyerid, c.nickname, c.join_date, d.total_redeem 
            from (
                SELECT a.buyerid, b.nickname, date(b.createon) as join_date
                FROM plsport_playsport._list_1 a left join plsport_playsport.member b on a.buyerid = b.userid) as c
                left join plsport_playsport._list_order_data as d on c.buyerid = d.userid) as e
            left join plsport_playsport._list_pcash_log as f on e.buyerid = f.userid) as g
        left join plsport_playsport._list_pay_idx as h on g.buyerid = h.buyerid) as i
    left join plsport_playsport._list_pay_brc as j on i.buyerid = j.buyerid;

    ALTER TABLE plsport_playsport._list_2 ADD INDEX (`buyerid`); 
    ALTER TABLE  `_list_2` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

select 'userid', 'nickname', 'join_date', 'total_redeem', 'total_paid', 'pay_idx', 'pay_brc', 'last_signin' union (
SELECT a.buyerid, a.nickname, a.join_date, a.total_redeem, a.total_paid, a.pay_idx, a.pay_brc, b.last_signin
into outfile 'C:/Users/1-7_ASUS/Desktop/survey_list_20140603.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._list_2 as a left join plsport_playsport._last_signin as b on a.buyerid = b.userid);

        # 檢查
        SELECT a.phone, a.id, a.text_campaign, a.abtest_group, b.text_campaign 
        FROM textcampaign._list6 a left join textcampaign.retention_201406_full_list_dont_delete b on a.id = b.id
        where b.text_campaign is not null;




# =================================================================================================
#  [201402-B-1] 加高國際讓分、主推版標比重 - A/B testing
#   
# 1. 提供測試名單
#    30%為實驗組
# 2. 測試報告
#   觀察指標點擊數和購買預測營業額，僅觀察頭三標、購牌專區推薦專區的購買記錄
# =================================================================================================

# ------------------------------------------------------------------------------------------------
# 程式碼同960~981
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
# ------------------------------------------------------------------------------------------------

# 先撈出符合的records
create table plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT id, buyerid, id_bought, sellerid, buy_date, buy_price, position, cons, allianceid, substr(position,1,2) as p
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-05-01 00:00:00' and '2014-05-31 23:59:59' # 區間
and position is not null; # 過瀘掉沒有records

create table plsport_playsport._list_1 engine = myisam 
SELECT *
FROM plsport_playsport._predict_buyer_with_cons_1
where p in ('HT','BZ') 
and position not in ('BZ_MF','BZ_SK'); #排除掉購牌專區左邊欄位

create table plsport_playsport._list_2 engine = myisam 
SELECT ((b.id%10)+1) as g, a.buyerid, a.sellerid, a.buy_date, a.buy_price, a.position, a.cons, a.allianceid, a.p 
FROM plsport_playsport._list_1 a left join plsport_playsport.member b on a.buyerid = b.userid;


create table plsport_playsport._list_3 engine = myisam 
SELECT g, buyerid, sellerid, buy_date, buy_price, position, cons, allianceid, p, 
       (case when (position = 'BZ_RCT') then 'BZ_raw'
             when (position = 'BZ_RC2') then 'BZ_raw'
             when (position = 'BZ_RC1') then 'BZ_raw'
             when (position = 'BZRCTB') then 'BZ_edited'
             when (position = 'BZRC2B') then 'BZ_edited'
             when (position = 'BZRC1B') then 'BZ_edited'
             when (position = 'HT1_A') then 'HT_raw'
             when (position = 'HT2_A') then 'HT_raw'
             when (position = 'HT3_A') then 'HT_raw'
             when (position = 'HT1_B') then 'HT_edited'
             when (position = 'HT2_B') then 'HT_edited'
             when (position = 'HT3_B') then 'HT_edited' end) as e
FROM plsport_playsport._list_2;

create table plsport_playsport._list_4 engine = myisam
SELECT g, position, p, e, buyerid, sum(buy_price) as revenue 
FROM plsport_playsport._list_3
group by buyerid;

select 'g', 'position', 'p', 'e', 'buyerid', 'revenue' union (
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/title_change_measure.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._list_4
order by revenue desc);

select 'userid', 'nickname', 'join_date', 'total_redeem', 'total_paid', 'pay_idx', 'pay_brc', 'last_signin' union (
SELECT a.buyerid, a.nickname, a.join_date, a.total_redeem, a.total_paid, a.pay_idx, a.pay_brc, b.last_signin
into outfile 'C:/Users/1-7_ASUS/Desktop/survey_list_20140603.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._list_2 as a left join plsport_playsport._last_signin as b on a.buyerid = b.userid);





# =================================================================================================
#  2014-06-05 (阿達)
#  [201402-B-1] 加高國際讓分、主推版標比重 - A/B testing
#  計算點擊pv的情況
# =================================================================================================

create table actionlog._change_action_201405 engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201405
where userid <> ''
and uri like '%rp=%';

create table actionlog._change_action_201405_1 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri)+3,length(uri)) as p, time 
FROM actionlog._change_action_201405;

create table actionlog._change_action_201405_2 engine = myisam
SELECT userid, p, time
FROM actionlog._change_action_201405_1
where substr(p,1,2) in ('BZ','HT')
and p not in ('BZ_MF','BZ_SK');

ALTER TABLE  `_change_action_201405_2` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table actionlog._change_action_201405_3 engine = myisam
SELECT ((b.id%10)+1) as g, a.userid, a.p, a.time
FROM actionlog._change_action_201405_2 a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog._change_action_201405_4 engine = myisam
SELECT g, userid, p, substr(p,1,2) as pp, 
       (case when (p = 'HT1_A') then 'raw'
             when (p = 'HT2_A') then 'raw'
             when (p = 'HT3_A') then 'raw'
             when (p = 'HT1_B') then 'edited'
             when (p = 'HT2_B') then 'edited'
             when (p = 'HT3_B') then 'edited'
             when (p = 'BZ_RCT') then 'raw'
             when (p = 'BZ_RC2') then 'raw'
             when (p = 'BZ_RC1') then 'raw'
             when (p = 'BZRCTBB') then 'edited'
             when (p = 'BZRC2BB') then 'edited'
             when (p = 'BZRC1BB') then 'edited' else 'XXXXX' end) as ver, time
FROM actionlog._change_action_201405_3;

# -----------------------------------------------
#  2014-07-07補充追蹤
#  第二次 A/B testing已下架，請於 7/7(一)完成報告
#  測試內容：調整主推版標權重
#  測試時間：6/10 ~ 6/23
# 
#  測試名單應該為: (userid%10)+1 in (8,9,10)
# -----------------------------------------------

create table actionlog._change_action_201406 engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201406
where userid <> ''
and uri like '%rp=%';

create table actionlog._change_action_201406_1 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri)+3,length(uri)) as p, time 
FROM actionlog._change_action_201406;

create table actionlog._change_action_201406_2 engine = myisam
SELECT userid, p, time
FROM actionlog._change_action_201406_1
where substr(p,1,2) in ('BZ','HT')
and p not in ('BZ_MF','BZ_SK');

ALTER TABLE  actionlog._change_action_201406_2 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table actionlog._change_action_201406_3 engine = myisam
SELECT ((b.id%10)+1) as g, a.userid, a.p, a.time
FROM actionlog._change_action_201406_2 a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog._change_action_201406_4 engine = myisam
SELECT * FROM actionlog._change_action_201406_3
where time between '2014-06-10 00:00:00' and '2014-06-22 23:59:59'; #--------------主要篩選區間


create table actionlog._change_action_201406_5 engine = myisam
SELECT g, userid, p, substr(p,1,2) as pp, 
       (case when (p = 'HT1_A') then 'raw'
             when (p = 'HT2_A') then 'raw'
             when (p = 'HT3_A') then 'raw'
             when (p = 'HT1_B') then 'edited' #權重加重
             when (p = 'HT2_B') then 'edited' #權重加重
             when (p = 'HT3_B') then 'edited' #權重加重
             when (p = 'BZ_RCT') then 'raw'
             when (p = 'BZ_RC2') then 'raw'
             when (p = 'BZ_RC1') then 'raw'
             when (p = 'BZRCTBB') then 'edited' #權重加重
             when (p = 'BZRC2BB') then 'edited' #權重加重
             when (p = 'BZRC1BB') then 'edited' else 'XXXXX' end) as ver, time
FROM actionlog._change_action_201406_4;


create table actionlog._change_action_201406_6 engine = myisam 
SELECT * #----------------------------------------------------沒參加實驗的
FROM actionlog._change_action_201406_5
where g in (1,2,3,4,5,6,10) and ver = 'raw';
insert ignore into actionlog._change_action_201406_6
SELECT * #----------------------------------------------------有參加實驗的
FROM actionlog._change_action_201406_5
where g in (7,8,9) and ver = 'edited';

select a.g, count(a.userid) as c #-------------點頭3標的人數
from (
    SELECT g, pp, userid, count(userid) as c
    FROM actionlog._change_action_201406_6
    where pp = 'HT'
    group by g, ver, userid) as a
group by a.g;

select a.g, count(a.userid) as c #-------------點推廌專區的人數
from (
    SELECT g, pp, userid, count(userid) as c
    FROM actionlog._change_action_201406_6
    where pp = 'BZ'
    group by g, ver, userid) as a
group by a.g;


create table actionlog._change_action_201406_7_for_r engine = myisam 
SELECT g, pp, userid, count(userid) as c
FROM actionlog._change_action_201406_6
where pp = 'HT'
group by g, ver, userid;
insert ignore into actionlog._change_action_201406_7_for_r
SELECT g, pp, userid, count(userid) as c
FROM actionlog._change_action_201406_6
where pp = 'BZ'
group by g, ver, userid;

# 輸出給R, 跑a/b testing檢定
select 'g', 'p', 'userid', 'c' union(
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/change_action_201406_7_for_r.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM actionlog._change_action_201406_7_for_r);

#-----------2014/07/07---------------------------------------------------------------------

create table plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-06-10 00:00:00' and '2014-06-22 23:59:59'
and substr(position,1,2) in ('HT','BZ');

create table plsport_playsport._predict_buyer_with_cons_2 engine = myisam
select *
from (
    SELECT id, buyerid, id_bought, sellerid, buy_date, buy_price, position, cons, allianceid, 
           (case when (position = 'HT1_A') then 'raw'
                 when (position = 'HT2_A') then 'raw'
                 when (position = 'HT3_A') then 'raw'
                 when (position = 'HT1_B') then 'edited' #權重加重
                 when (position = 'HT2_B') then 'edited' #權重加重
                 when (position = 'HT3_B') then 'edited' #權重加重
                 when (position = 'BZ_RCT') then 'raw'
                 when (position = 'BZ_RC2') then 'raw'
                 when (position = 'BZ_RC1') then 'raw'
                 when (position = 'BZRCTB') then 'edited' #權重加重
                 when (position = 'BZRC2B') then 'edited' #權重加重
                 when (position = 'BZRC1B') then 'edited' else 'XXXXX' end) as ver,
           substr(position,1,2) as p
    FROM plsport_playsport._predict_buyer_with_cons_1) as a 
where a.ver <> 'XXXXX';

create table plsport_playsport._predict_buyer_with_cons_3 engine = myisam
SELECT (b.id%10)+1 as g, a.buyerid, a.buy_price, a.position, a.ver, a.p 
FROM plsport_playsport._predict_buyer_with_cons_2 a left join plsport_playsport.member b on a.buyerid = b.userid;

SELECT g, p, ver, sum(buy_price) as revenue 
FROM plsport_playsport._predict_buyer_with_cons_3
group by g, p, ver
order by p, g;

create table plsport_playsport._predict_buyer_with_cons_4 engine = myisam 
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons_3
where g in (1,2,3,4,5,6,10) and ver = 'raw';
insert ignore into plsport_playsport._predict_buyer_with_cons_4
SELECT *
FROM plsport_playsport._predict_buyer_with_cons_3
where g in (7,8,9) and ver = 'edited';

create table plsport_playsport._predict_buyer_with_cons_5 engine = myisam
SELECT g, p, buyerid as userid, sum(buy_price) as revenue
FROM plsport_playsport._predict_buyer_with_cons_4
where p = 'HT'
group by g, ver, buyerid;
insert ignore into plsport_playsport._predict_buyer_with_cons_5
SELECT g, p, buyerid as userid, sum(buy_price) as revenue
FROM plsport_playsport._predict_buyer_with_cons_4
where p = 'BZ'
group by g, ver, buyerid;


# 輸出給R, 跑a/b testing檢定
select 'g', 'p', 'userid', 'revenue' union(
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/predict_buyer_with_cons_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._predict_buyer_with_cons_5);


SELECT g, count(userid) as c 
FROM plsport_playsport._predict_buyer_with_cons_5
where p = 'BZ'
group by g;

SELECT g, sum(revenue) as c 
FROM plsport_playsport._predict_buyer_with_cons_5
where p = 'BZ'
group by g;


#-----------2014/08/19---------------------------------------------------------------------
# to Eddy :
# 已上第三階段 A/B testing，預計測試時間 7/29 ~ 8/26
# 麻煩再評估一下報告時間
# p.s. 這次只動到頭三標，沒有影響到購牌專區推薦專區，故只需做頭三標報告即可

create table actionlog._action_201405_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201405
where userid <> '' and uri like '%rp=%';

create table actionlog._action_201406_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201406
where userid <> '' and uri like '%rp=%';

create table actionlog._action_201407_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201407
where userid <> '' and uri like '%rp=%';

create table actionlog._action_201408_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201408_edited
where userid <> '' and uri like '%rp=%';

create table actionlog._action_position engine = myisam SELECT * FROM actionlog._action_201405_position;
insert ignore into actionlog._action_position SELECT * FROM actionlog._action_201406_position;
insert ignore into actionlog._action_position SELECT * FROM actionlog._action_201407_position;
insert ignore into actionlog._action_position SELECT * FROM actionlog._action_201408_position;

# (1) 先捉出代碼和篩出時間區間
create table actionlog._action_position_1 engine = myisam
SELECT userid, uri, substr(uri, locate('&rp=',uri)+4, length(uri)) as rp, time 
FROM actionlog._action_position
where time between '2014-05-12 12:00:00' and '2014-08-19 00:00:00';

# (2) 再去掉代碼&之後的string
create table actionlog._action_position_2 engine = myisam
SELECT userid, uri, (case when (locate('&',rp)=0) then rp else substr(rp,1,(locate('&',rp))) end) as rp, time
FROM actionlog._action_position_1;

# (3) 最後比對第1碼是大寫的,排除掉一些有的沒的string, user"abc36611"的string很奇怪, 直接排掉此人
create table actionlog._action_position_3 engine = myisam
SELECT * 
FROM actionlog._action_position_2
where substr(rp,1,1) REGEXP BINARY '[A-Z]' 
or userid <> 'abc36611'; #words which have 1 capital letters consecutively

# Regexp - How to find capital letters in MySQL only
# http://stackoverflow.com/questions/8666796/regexp-how-to-find-capital-letters-in-mysql-only
# WHERE names REGEXP BINARY '[A-Z]{2}'
# REGEXP is not case sensitive, except when used with binary strings.
# 要順便檢查一下目前到底有多少位置

# (4) 最後, 所有目前的位置代碼表, 只要查詢就好
SELECT rp, count(userid) as c 
FROM actionlog._action_position_3
group by rp;



# 這個部分才開始做任務的研究

create table actionlog._action_position_3_HT_only engine = myisam
SELECT * 
FROM actionlog._action_position_3
where substr(rp,1,2) = 'HT' 
and time between '2014-07-29 12:00:00' and '2014-08-31: 00:00:00';


create table actionlog._action_position_3_HT_only_ok engine = myisam
select d.g, d.userid, d.rp, d.version, d.time
from (
    select c.g, c.userid, c.rp, c.version, c.time, (case when (g>13) then 'B' else 'A' end) as chk
    from (
        SELECT (b.id%20)+1 as g, a.userid, a.rp, substr(a.rp,5,1) as version, a.time
        FROM actionlog._action_position_3_ht_only a left join plsport_playsport.member b on a.userid = b.userid) as c) as d
where d.version = d.chk;


SELECT version, count(g) as c 
FROM actionlog._action_position_3_ht_only_ok
group by version;

select a.rp, count(a.userid) as c
from (
    SELECT * FROM actionlog._action_position_3
    where substr(rp,1,2) = 'US'
    and time between '2014-08-15 18:00:00' and '2014-08-18 12:00:00') as a
group by a.rp;


# 每個使用者點擊頭3標的次數, 可輸出.csv
create table actionlog._action_position_3_HT_only_click_count engine = myisam
SELECT g, userid, version, count(userid) as click 
FROM actionlog._action_position_3_ht_only_ok
group by g, userid, version;


create table plsport_playsport._predict_buyer_with_cons_only_ht engine = myisam
SELECT buyerid as userid, buy_date, buy_price, position, substr(position,5,1) as version
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-07-29 12:00:00' and '2014-08-31: 00:00:00'
and substr(position,1,2) = 'HT'
order by buy_date desc;


create table plsport_playsport._predict_buyer_with_cons_only_ht_revenue engine = myisam
select d.g, d.userid, d.buy_date, d.buy_price, d.position, d.version
from (
    select c.g, c.userid, c.buy_date, c.buy_price, c.position, c.version, (case when (c.g>13) then 'B' else 'A' end) as chk
    from (
        SELECT (b.id%20)+1 as g, a.userid, a.buy_date, a.buy_price, a.position, a.version 
        FROM plsport_playsport._predict_buyer_with_cons_only_ht a left join plsport_playsport.member b on a.userid = b.userid) as c) as d
where d.version = d.chk;

# 每個使用者購買頭3標的金額, 可輸出.csv
create table plsport_playsport._predict_buyer_with_cons_only_ht_revenue_ok engine = myisam
SELECT g, userid, version, sum(buy_price) as spent
FROM plsport_playsport._predict_buyer_with_cons_only_ht_revenue
group by g, userid, version;




SELECT version, count(userid), sum(click)  
FROM actionlog._action_position_3_ht_only_click_count
group by version;


SELECT version, count(userid), sum(spent) 
FROM plsport_playsport._predict_buyer_with_cons_only_ht_revenue_ok
group by version;



















# =================================================================================================
#  2014-06-10
#　[201406-A-1] 個人預測頁左下欄位改成戰績 - 數據研究
#  1. 近半年有消費者的使用者，半年內看個分類戰績的比例 ( 戰績總覽、本月、上月、本週、上週、本賽季、總計 )
#  2. 請排除自己看自己的戰績記錄
# =================================================================================================

# 這個任務是要撈出個人頁>戰績頁中的所有log, 並利用uri來分析使用者都是怎麼使用戰績貢
# 先撈出1月~5月的個人頁log
create table actionlog.action_201405_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201405 where userid <> '' and uri like '%visit_member.php%';
create table actionlog.action_201404_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201404 where userid <> '' and uri like '%visit_member.php%';
create table actionlog.action_201403_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201403 where userid <> '' and uri like '%visit_member.php%';
create table actionlog.action_201402_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201402 where userid <> '' and uri like '%visit_member.php%';
create table actionlog.action_201401_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201401 where userid <> '' and uri like '%visit_member.php%';

# 再把1月~5月的個人頁log合併成一個檔
    create table actionlog.action_visit_member engine = myisam SELECT * FROM actionlog.action_201401_visit_member;
    insert ignore into actionlog.action_visit_member select * from actionlog.action_201402_visit_member;
    insert ignore into actionlog.action_visit_member select * from actionlog.action_201403_visit_member;
    insert ignore into actionlog.action_visit_member select * from actionlog.action_201404_visit_member;
    insert ignore into actionlog.action_visit_member select * from actionlog.action_201405_visit_member;


# 接下來的步驟就是在解析uri, 把uri中的變數一個個分出來
# (1) 分出visit
    create table actionlog.action_visit_member_1 engine = myisam
    SELECT userid, uri, substr(uri,locate('visit=',uri)+6) as u, time
    FROM actionlog.action_visit_member;

    create table actionlog.action_visit_member_2 engine = myisam
    SELECT userid, uri, 
           (case when (locate('&',u) = 0) then u
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as visit, time
    FROM actionlog.action_visit_member_1;
# (2) 分出action
    create table actionlog.action_visit_member_3 engine = myisam
    SELECT userid, uri, visit,
           (case when (locate('action=',uri) = 0) then null
                 when (locate('action=',uri) > 0) then substr(uri,locate('action=',uri)+7) end) as u, time
    FROM actionlog.action_visit_member_2;

    create table actionlog.action_visit_member_4 engine = myisam
    SELECT userid, uri, visit,
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as action, time 
    FROM actionlog.action_visit_member_3;
# (3) 分出type
    create table actionlog.action_visit_member_5 engine = myisam
    SELECT userid, uri, visit, action,
           (case when (locate('&type=',uri) = 0) then null
                 when (locate('&type=',uri) > 0) then substr(uri,locate('&type=',uri)+6) end) as u, time
    FROM actionlog.action_visit_member_4;

    create table actionlog.action_visit_member_6 engine = myisam
    SELECT userid, uri, visit, action,
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as type, time 
    FROM actionlog.action_visit_member_5;
# (4) 分出during
    create table actionlog.action_visit_member_7 engine = myisam
    SELECT userid, uri, visit, action, type,
           (case when (locate('during=',uri) = 0) then null
                 when (locate('during=',uri) > 0) then substr(uri,locate('during=',uri)+7) end) as u, time
    FROM actionlog.action_visit_member_6;

    create table actionlog.action_visit_member_8 engine = myisam
    SELECT userid, uri, visit, action, type,
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as during, time 
    FROM actionlog.action_visit_member_7;
# (5) 分出vol
    create table actionlog.action_visit_member_9 engine = myisam
    SELECT userid, uri, visit, action, type, during,
           (case when (locate('vol=',uri) = 0) then null
                 when (locate('vol=',uri) > 0) then substr(uri,locate('vol=',uri)+4) end) as u, time
    FROM actionlog.action_visit_member_8;

    create table actionlog.action_visit_member_10 engine = myisam
    SELECT userid, uri, visit, action, type, during, 
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as vol, time 
    FROM actionlog.action_visit_member_9;
# (6) 分出gameday
    create table actionlog.action_visit_member_11 engine = myisam
    SELECT userid, uri, visit, action, type, during, vol, 
           (case when (locate('gameday=',uri) = 0) then null
                 when (locate('gameday=',uri) > 0) then substr(uri,locate('gameday=',uri)+8) end) as u, time
    FROM actionlog.action_visit_member_10;

    create table actionlog.action_visit_member_12 engine = myisam
    SELECT userid, uri, visit, action, type, during, vol,
           (case when (locate('&',u) = 0) then u
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as gameday, time 
    FROM actionlog.action_visit_member_11;

    rename table actionlog.action_visit_member_12 to actionlog.action_visit_member_edited;
# 在這個步驟要把textfield換成其它字串類型的變數, 要不然下group會很久
# action_visit_member_edited為此任務主要的log檔
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `visit` `visit` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `action` `action` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `type` `type` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `during` `during` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `vol` `vol` CHAR(10) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `gameday` `gameday` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';

# 把戰績頁都獨立出來
create table actionlog.action_visit_member_edited_tab_records engine = myisam
SELECT * FROM actionlog.action_visit_member_edited
where action = 'records';

    ALTER TABLE actionlog.action_visit_member_edited_tab_records CHANGE COLUMN `userid` `userid` CHAR(22) NOT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited_tab_records CHANGE COLUMN `visit` `visit` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';

# 近6個月內有消費的人
create table plsport_playsport._who_spent_in_six_months engine = myisam
select a.userid, count(a.userid) as c
from (
    SELECT userid, date
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1
    and date between subdate(now(),180) and now()
    order by date) as a
group by a.userid;

    ALTER TABLE plsport_playsport._who_spent_in_six_months ADD INDEX (`userid`);  

# [1]戰績頁的記錄_近6個月有消費過的人
create table actionlog.action_visit_member_edited_tab_records_who_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c 
FROM actionlog.action_visit_member_edited_tab_records a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
where a.userid <> a.visit; #排除掉自己看自己

        # 計算戰績頁中的各tab點擊(本月, 上月, 本週, 上週, 本賽季, 總計)
        select a.during, count(a.userid) as c
        from (
            SELECT * 
            FROM actionlog.action_visit_member_edited_tab_records_who_spent
            where type = 'all') as a #戰績頁
        group by a.during;

            SELECT count(userid)
            FROM actionlog.action_visit_member_edited_tab_records_who_spent
            where type = 'sk'; # 可以換成 all勝率, index總覽, mf莊殺資格, sk單殺資訊


# [2]戰績頁的記錄_近6個月沒消費的人
create table actionlog.action_visit_member_edited_tab_records_who_not_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c
FROM actionlog.action_visit_member_edited_tab_records a left join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
where a.userid <> a.visit #排除掉自己看自己
and b.c is null; 

        # 計算戰績頁中的各tab點擊(本月, 上月, 本週, 上週, 本賽季, 總計)
        select a.during, count(a.userid) as c
        from (
            SELECT * 
            FROM actionlog.action_visit_member_edited_tab_records_who_not_spent
            where type = 'all') as a #戰績頁
        group by a.during;

            SELECT count(userid)
            FROM actionlog.action_visit_member_edited_tab_records_who_not_spent
            where type = 'sf'; # 可以換成 all勝率, index總覽, mf莊殺資格, sk單殺資訊


# [3]戰績頁的記錄
create table actionlog.action_visit_member_edited_tab_records_everyone engine = myisam
SELECT userid, uri, visit, action, type, during, vol, gameday, time 
FROM actionlog.action_visit_member_edited_tab_records
where userid <> visit; #排除掉自己看自己

        # 計算戰績頁中的各tab點擊(本月, 上月, 本週, 上週, 本賽季, 總計)
        select a.during, count(a.userid) as c
        from (
            SELECT * 
            FROM actionlog.action_visit_member_edited_tab_records_everyone
            where type = 'all') as a #戰績頁
        group by a.during;

            SELECT count(userid)
            FROM actionlog.action_visit_member_edited_tab_records_everyone
            where type = 'mf'; # 可以換成 all勝率, index總覽, mf莊殺資格, sk單殺資訊


# [1]主個人頁log記錄 (排除自己看自己的)
create table actionlog.action_visit_member_edited_all_tab engine = myisam
SELECT userid, uri, visit, action, type, during, vol, gameday, time 
FROM actionlog.action_visit_member_edited
where userid <> visit; #排除掉自己看自己

        # 全部的版本統計
        SELECT action, count(userid) as c  
        FROM actionlog.action_visit_member_edited
        group by action;

        # 排除自己看自己的統計
        SELECT action, count(userid) as c 
        FROM actionlog.action_visit_member_edited_all_tab
        group by action;


# [2]主個人頁log記錄-有消費的人 (排除自己看自己的)
create table actionlog.action_visit_member_edited_all_tab_who_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c 
FROM actionlog.action_visit_member_edited a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
where a.userid <> a.visit; #排除掉自己看自己

        SELECT action, count(userid) as c  
        FROM actionlog.action_visit_member_edited_all_tab_who_spent
        group by action;


# [3]主個人頁log記錄-沒有消費的人 (排除自己看自己的)
create table actionlog.action_visit_member_edited_all_tab_who_not_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c 
FROM actionlog.action_visit_member_edited a left join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
where a.userid <> a.visit
and b.c is null; #排除掉自己看自己

        SELECT action, count(userid) as c  
        FROM actionlog.action_visit_member_edited_all_tab_who_not_spent
        group by action;


# ---------------------------------------------
# 新增任務 2014-07-14
# 2. 統計個人預測頁感謝文、發文欄位點擊記錄
# 統計時間：6/20 ~ 7/3
# 報告時間：7/9
# 備註：兩個欄位分別有文章及"看全部"
# 任務狀態: 新建
# ---------------------------------------------

# 先撈出6月20日~7月13日的個人頁log
create table actionlog.action_201406_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 where userid <> '' and uri like '%visit_member.php%';
create table actionlog.action_201407_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 where userid <> '' and uri like '%visit_member.php%';

        # 再把6月20日~7月13日的個人頁log合併成一個檔
        create table actionlog.action_visit_member engine = myisam SELECT * FROM actionlog.action_201406_visit_member
        where time between '2014-06-20 00:00:00' and '2014-06-30 23:59:59';
        insert ignore into actionlog.action_visit_member select * from actionlog.action_201407_visit_member;

# 先撈出6月20日~7月13日的文章內頁log
create table actionlog.action_201406_forumdetail engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 where userid <> '' and uri like '%forumdetail.php%';
create table actionlog.action_201407_forumdetail engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 where userid <> '' and uri like '%forumdetail.php%';

        # 再把6月20日~7月13日的文章內頁log合併成一個檔
        create table actionlog.action_forumdetail engine = myisam SELECT * FROM actionlog.action_201406_forumdetail
        where time between '2014-06-20 00:00:00' and '2014-06-30 23:59:59';
        insert ignore into actionlog.action_forumdetail select * from actionlog.action_201407_forumdetail;

#以上SQL產生的是:
#    (1) actionlog.action_visit_member
#    (2) actionlog.action_forumdetail

#接下來執行上一段程式解uri

#個人頁的點擊數直接count action_visit_member_edited
#戰績頁的點擊數直接count action_visit_member_edited_tab_records

#在討論區的部分(看殺手的分析文+感謝文)
create table actionlog.action_forumdetail_edited engine = myisam
SELECT userid, uri,
       (case when locate("&post_from=",uri) = 0 then ''
       else substr(uri, locate("&post_from=",uri)+11, length(uri)) end) as s 
FROM actionlog.action_forumdetail;
#在個人頁的部分(看殺手全部的分析文+全部的感謝文)
create table actionlog.action_visit_member_edited_post_from engine = myisam
SELECT userid, uri, time,
       (case when locate("&post_from=",uri) = 0 then ''
       else substr(uri, locate("&post_from=",uri)+11, length(uri)) end) as s
FROM actionlog.action_visit_member_edited
where uri like '%post_from=%';


# (1)
SELECT count(userid) as c 
FROM actionlog.action_visit_member_edited;
# (2)
SELECT count(userid) as c 
FROM actionlog.action_visit_member_edited_tab_records;
# (3)
SELECT s, count(userid) as c 
FROM actionlog.action_forumdetail_edited
group by s;
# (4)
SELECT s, count(userid) as c 
FROM actionlog.action_visit_member_edited_post_from
group by s;

# (1)
select count(a.userid) as user_count
from (
    SELECT userid, count(userid) as c 
    FROM actionlog.action_visit_member_edited
    group by userid) as a;
# (2)
select count(a.userid) as user_count
from (
    SELECT userid, count(userid) as c 
    FROM actionlog.action_visit_member_edited_tab_records
    group by userid) as a;
# (3)
select a.s, count(a.userid) as user_count
from (
    SELECT userid, s, count(userid) as c 
    FROM actionlog.action_forumdetail_edited
    where s <> ''
    group by userid, s) as a
group by a.s;
# (4)
select a.s, count(a.userid) as user_count
from (
    SELECT userid, s, count(userid) as c
    FROM actionlog.action_visit_member_edited_post_from
    group by userid, s) as a
group by a.s;


# 下面的部分是補上條件:
#     (1)排除自己看自己
#     (2)近6個月內有消費的人
#
# 需要再重新產生: 2014/7/21
#     (1) actionlog.action_visit_member_edited
#     (2) actionlog.action_forumdetail


# 套用條件 (1)排除自己看自己 (2)近6個月內有消費過的人
create table actionlog.action_visit_member_without_see_himself_1 engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time
FROM actionlog.action_visit_member_edited a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
where a.userid <> a.visit;

create table actionlog.action_visit_member_without_see_himself_tab_records_1 engine = myisam
SELECT * 
FROM actionlog.action_visit_member_without_see_himself_1
where action = 'records';

# 個人頁的點擊數直接count action_visit_member_edited
# 戰績頁的點擊數直接count action_visit_member_edited_tab_records

# action_forumdetail_edited需要比對出是誰發的文, 並排除自己看自己的文章

# (1) 分出subjectid
    create table actionlog.action_forumdetail_edited_1 engine = myisam
    SELECT userid, uri, s, substr(uri,locate('subjectid=',uri)+10) as u
    FROM actionlog.action_forumdetail_edited;

    create table actionlog.action_forumdetail_edited_2 engine = myisam
    SELECT userid, uri, s,
           (case when (locate('&',u) = 0) then u
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as subjectid
    FROM actionlog.action_forumdetail_edited_1;

    ALTER TABLE plsport_playsport.forum ADD INDEX (`subjectid`);  
    ALTER TABLE actionlog.action_forumdetail_edited_2 CHANGE  `subjectid`  `subjectid` LONGTEXT CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
    ALTER TABLE actionlog.action_forumdetail_edited_2 CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
    ALTER TABLE actionlog.action_forumdetail_edited_2 ADD INDEX (`subjectid`); 

create table actionlog.action_forumdetail_edited_3 engine = myisam
SELECT a.userid, a.uri, a.s, a.subjectid, b.postuser
FROM actionlog.action_forumdetail_edited_2 a left join plsport_playsport.forum b on a.subjectid = b.subjectid;

    ALTER TABLE  actionlog.action_forumdetail_edited_3 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE  actionlog.action_forumdetail_edited_3 CHANGE  `postuser`  `postuser` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
    ALTER TABLE  actionlog.action_forumdetail_edited_3 ADD INDEX (`userid`); 
    ALTER TABLE  plsport_playsport._who_spent_in_six_months ADD INDEX (`userid`); 

# 套用條件(第一次忘了這步驟)
create table actionlog.action_forumdetail_edited_4 engine = myisam
SELECT a.userid, a.uri, a.s, a.subjectid, a.postuser 
FROM actionlog.action_forumdetail_edited_3 a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
where a.userid <> a.postuser;


create table actionlog.action_visit_member_without_see_himself_2 engine = myisam
SELECT userid, uri, 
      (case when locate("&post_from=",uri) = 0 then ''
            else substr(uri, locate("&post_from=",uri)+11, length(uri)) end) as s
FROM actionlog.action_visit_member_without_see_himself_1
where uri like '%post_from=%';




# (1)
SELECT count(userid) as c FROM actionlog.action_visit_member_without_see_himself_1;
# (2)
SELECT count(userid) as c FROM actionlog.action_visit_member_without_see_himself_tab_records_1;
# (3)
select a.s, count(a.userid) as c
from (
    SELECT *
    FROM actionlog.action_forumdetail_edited_4
    where s <> ''
    and userid <> postuser) as a
group by a.s;
# (4)
SELECT s, count(userid) as c 
FROM actionlog.action_visit_member_without_see_himself_2
group by s;

# (1)
select count(a.userid) as user_count
from (
    SELECT userid, count(userid) as c
    FROM actionlog.action_visit_member_without_see_himself_1
    group by userid) as a;
# (2)
select count(a.userid) as user_count
from (
    SELECT userid, count(userid) as c
    FROM actionlog.action_visit_member_without_see_himself_tab_records_1
    group by userid) as a;
# (3)
select a.s, count(a.userid) as user_count
from (
    SELECT userid, s, count(userid) as a
    FROM actionlog.action_forumdetail_edited_4
    where s <> ''
    and userid <> postuser
    group by userid, s) as a
group by a.s;
# (4)
select a.s, count(a.userid) as user_count
from (
    SELECT s, userid, count(userid) as c 
    FROM actionlog.action_visit_member_without_see_himself_2
    group by s, userid) as a
group by a.s;



# =================================================================================================
#  2014-06-16
# 任務: 購買噱幣-儲值回饋使用狀況報告 [新建](靜怡)
# 
# 說明
# 目的：了解儲值回饋的使用狀況
# 快速結帳啟用時間：3/14
# 
# 內容
# - 快速結帳的使用率
# - 儲值回饋使用率
# - 是否有提升儲值金額
# =================================================================================================

select a.create_from, a.m, sum(a.price) as total_redeem
from (
    SELECT userid, name, substr(createon,1,7) as m, price, create_from 
    FROM plsport_playsport.order_data
    where payway in (1,2,3,4,5,6) and sellconfirm = 1
    and createon between '2013-01-01 00:00:00' and '2014-12-31 23:59:59'
    order by createon desc) as a
group by a.create_from, a.m ;

select a.create_from, a.m, count(a.price) as total_redeem_count
from (
    SELECT userid, name, substr(createon,1,7) as m, price, create_from 
    FROM plsport_playsport.order_data
    where payway in (1,2,3,4,5,6) and sellconfirm = 1
    and createon between '2013-01-01 00:00:00' and '2014-12-31 23:59:59'
    order by createon desc) as a
group by a.create_from, a.m ;


# 誰有用過快速儲值噱幣

select count(b.userid) as c
from (
    select a.userid, a.name, count(a.userid) as c
    from (
        SELECT userid, name, substr(createon,1,7) as m, price, create_from 
        FROM plsport_playsport.order_data
        where payway in (1,2,3,4,5,6) and sellconfirm = 1
        and createon between '2014-04-01 00:00:00' and '2014-04-30 23:59:59'
        and create_from = 3
        order by createon desc) as a
    group by a.userid) as b;



# -----------------------------------------------
# 2014-6-27 數據補充
#     (1)快速結帳的轉換率
#     (2)使用儲值優惠的下一筆儲值金額
#
# note: 快速結帳的記錄表是quick_order_bonus_today
# -----------------------------------------------


select a.m, count(a.userid) as c
from (
    SELECT userid, bonus_for_price, create_time, substr(create_time,1,7) as m, order_data_id
    FROM plsport_playsport.quick_order_bonus_today
    order by create_time desc) as a
group by a.m;

select a.m, count(a.userid) as c
from (
    SELECT userid, bonus_for_price, create_time, substr(create_time,1,7) as m, order_data_id
    FROM plsport_playsport.quick_order_bonus_today
    where order_data_id is not null
    order by create_time desc) as a
group by a.m;


SELECT userid, bonus_for_price, create_time, substr(create_time,1,7) as m, order_data_id
FROM plsport_playsport.quick_order_bonus_today
where order_data_id is not null
order by create_time desc;

        create table plsport_playsport._who_accept_fast_checkout_offer engine = myisam
        SELECT userid, order_data_id, (case when (userid is not null) then 'accept_offer' end) as fast_checkout
        FROM plsport_playsport.quick_order_bonus_today
        where order_data_id is not null
        order by create_time desc;

        create table plsport_playsport._who_accept_fast_checkout_offer_namelist engine = myisam
        SELECT userid, count(userid) as c 
        FROM plsport_playsport._who_accept_fast_checkout_offer
        group by userid;




create table plsport_playsport._who_accept_fast_checkout_offer_complete_order_history engine = myisam
SELECT a.id, a.userid, a.name, a.createon, a.ordernumber, a.price, a.sellconfirm, a.payway, a.create_from, a.platform_type
FROM plsport_playsport.order_data a inner join plsport_playsport._who_accept_fast_checkout_offer_namelist b on a.userid = b.userid
order by a.userid;

create table plsport_playsport._who_accept_fast_checkout_offer_complete_order_history_done engine = myisam
SELECT a.id, a.userid, a.name, a.createon, a.ordernumber, a.price, 
       (case when (a.payway = 1) then '信用卡'
             when (a.payway = 2) then 'ATM'
             when (a.payway = 3) then '超商'
             when (a.payway = 4) then '支付寶'
             when (a.payway = 5) then 'Paypal'
             when (a.payway = 6) then 'MyCard' else '有問題' end) as payway,
       (case when (a.create_from = 0) then '一般儲值'
             when (a.create_from = 1) then '噱幣不足'
             when (a.create_from = 2) then '噱幣不足-優惠'
             when (a.create_from = 3) then '快速結帳'
             when (a.create_from = 4) then '快速結帳-優惠'
             when (a.create_from = 5) then '手機'
             when (a.create_from = 6) then '推廌999'
             when (a.create_from = 7) then '新手優化路徑'
             when (a.create_from = 8) then '行銷活動' end) as create_from,
       (case when (a.platform_type = 1) then '電腦'
             when (a.platform_type = 2) then '手機'
             when (a.platform_type = 3) then '平板' end ) as platform,
       (case when (a.sellconfirm = 1) then '' else '沒繳費' end) as sellconfirm, b.fast_checkout
FROM plsport_playsport._who_accept_fast_checkout_offer_complete_order_history a 
     left join plsport_playsport._who_accept_fast_checkout_offer b on a.id = b.order_data_id
order by a.userid, a.createon;


# =================================================================================================
#  2014-06-20
# 任務: [201405-A-7] 購買預測APP - 測試名單(阿達)
# 時間：6/23 (一)
# 條件：
# a. 近三個月有消費的使用者
# b. 使用手機比率超過 60%
# c. 有在使用購牌專區購牌
# 欄位：暱稱、ID、總儲值金額、近三個月儲值金額、購牌專區消費金額、居住地、最近登入時間
#
# 任務: [201406-B-1]強化玩家搜尋-使用者訪談名單撈取(靜怡)
# 條件
#    -族群：D1~D5
#    -近三個月有消費的使用者
#    -經常使用玩家搜尋
# 欄位：暱稱、ID、總儲值金額、近三個月儲值金額、玩家搜尋PV、電腦與手機使用比率、最近登入時間
# 透由玩家搜尋買預測比
# =================================================================================================


create table actionlog.action_201404_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201404 where userid <> '';
create table actionlog.action_201405_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201405 where userid <> '';
create table actionlog.action_201406_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201406 where userid <> '';
create table actionlog.action_201407_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201407 where userid <> '';

create table actionlog.action_201404_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201404_platform group by userid, platform_type;
create table actionlog.action_201405_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201405_platform group by userid, platform_type;
create table actionlog.action_201406_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201406_platform group by userid, platform_type;
create table actionlog.action_201407_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201407_platform group by userid, platform_type;

        create table actionlog.action_platform_group engine = myisam SELECT * FROM actionlog.action_201404_platform_group;
        insert ignore into actionlog.action_platform_group SELECT * FROM actionlog.action_201405_platform_group;
        insert ignore into actionlog.action_platform_group SELECT * FROM actionlog.action_201406_platform_group;
        insert ignore into actionlog.action_platform_group SELECT * FROM actionlog.action_201407_platform_group;

        # 桌上/手機/平板 等平台登入的pv計算
        create table actionlog._actionlog_platform_visit engine = myisam
        select d.userid, d.desktop, d.mobile, d.tablet, round(d.desktop/d.total,3) as desktop_p, round(d.mobile/d.total,3) as mobile_p, round(d.tablet/d.total,3) as tablet_p
        from (
            select c.userid, c.desktop, c.mobile, c.tablet, (c.desktop+c.mobile+c.tablet) as total
            from (
                select b.userid, sum(b.desktop) as desktop, sum(b.mobile) as mobile, sum(b.tablet) as tablet
                from (
                    select a.userid, 
                           (case when (a.platform_type = 1) then c else 0 end) as desktop, #桌上
                           (case when (a.platform_type = 2) then c else 0 end) as mobile,  #手機
                           (case when (a.platform_type = 3) then c else 0 end) as tablet   #平板
                    from (
                        SELECT userid, platform_type, sum(c) as c
                        FROM actionlog.action_platform_group
                        group by userid, platform_type
                        order by userid) as a) as b
                group by b.userid) as c) as d;

drop table actionlog.action_201404_platform, actionlog.action_201404_platform_group;
drop table actionlog.action_201405_platform, actionlog.action_201405_platform_group;
drop table actionlog.action_201406_platform, actionlog.action_201406_platform_group;
drop table actionlog.action_201407_platform, actionlog.action_201407_platform_group;

use plsport_playsport;
        #2選1
        #(1)使用分群資料
        create table plsport_playsport._list_1 engine = myisam
        SELECT a.userid, b.nickname, date(b.createon) as join_date, a.g as cluster
        FROM user_cluster.cluster_with_real_userid a left join plsport_playsport.member b on a.userid = b.userid;
        #(2)不用分群資料
        create table plsport_playsport._list_1 engine = myisam
        SELECT userid, nickname, date(createon) as join_date
        FROM plsport_playsport.member;

        # 最近一次的登入時間
        create table plsport_playsport._last_login_time engine = myisam
        SELECT userid, max(signin_time) as last_login
        FROM plsport_playsport.member_signin_log_archive
        group by userid;

        ALTER TABLE  `_last_login_time` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

        ALTER TABLE plsport_playsport._list_1 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);  

create table plsport_playsport._list_2 engine = myisam
SELECT a.userid, a.nickname, a.join_date, date(b.last_login) as last_login
FROM plsport_playsport._list_1 a left join plsport_playsport._last_login_time b on a.userid = b.userid;

        # 開站以來總儲值金額
        create table plsport_playsport._total_redeem engine = myisam
        SELECT userid, sum(price) as total_redeem 
        FROM plsport_playsport.order_data
        where payway in (1,2,3,4,5,6) and sellconfirm = 1
        group by userid;

        # 近3個月的儲值金額
        create table plsport_playsport._total_redeem_in_three_month engine = myisam
        SELECT userid, sum(price) as redeem_3_months
        FROM plsport_playsport.order_data
        where payway in (1,2,3,4,5,6) and sellconfirm = 1
        and createon between subdate(now(),93) and now() #近3個月
        group by userid;

        ALTER TABLE  `_total_redeem` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        ALTER TABLE  `_total_redeem_in_three_month` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

        ALTER TABLE plsport_playsport._list_2 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._total_redeem ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._total_redeem_in_three_month ADD INDEX (`userid`);  

create table plsport_playsport._list_3 engine = myisam
select c.userid, c.nickname, c.join_date, c.last_login, c.total_redeem, d.redeem_3_months
from (
    SELECT a.userid, a.nickname, a.join_date, a.last_login, b.total_redeem
    FROM plsport_playsport._list_2 a left join plsport_playsport._total_redeem b on a.userid = b.userid) as c
    left join plsport_playsport._total_redeem_in_three_month as d on c.userid = d.userid;

        drop table if exists plsport_playsport._predict_buyer;
        drop table if exists plsport_playsport._predict_buyer_with_cons;

        #此段SQL是計算各購牌位置記錄的金額
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

        #計算各購牌位置記錄的金額
        create table plsport_playsport._buy_position engine = myisam
        select d.buyerid, d.BRC, d.BZ, d.FRND, d.FR, d.WPB, d.MPB, d.IDX, d.HT, d.US, d.NONE, 
               (d.BRC+d.BZ+d.FRND+d.FR+d.WPB+d.MPB+d.IDX+d.HT+d.US+d.NONE) as total #把所有的金額加起來
        from (
                select c.buyerid, sum(c.BRC) as BRC, sum(c.BZ) as BZ, sum(c.FRND) as FRND, sum(c.FR) as FR, 
                                  sum(c.WPB) as WPB, sum(c.MPB) as MPB, sum(c.IDX) as IDX, sum(c.HT) as HT,
                                  sum(c.US) as US, sum(c.NONE) as NONE
                from (
                        select b.buyerid, 
                               (case when (b.p = 'BRC') then spent else 0 end) as 'BRC',
                               (case when (b.p = 'BZ') then spent else 0 end) as 'BZ',
                               (case when (b.p = 'FRND') then spent else 0 end) as 'FRND',
                               (case when (b.p = 'FR') then spent else 0 end) as 'FR',
                               (case when (b.p = 'WPB') then spent else 0 end) as 'WPB',
                               (case when (b.p = 'MPB') then spent else 0 end) as 'MPB',
                               (case when (b.p = 'IDX') then spent else 0 end) as 'IDX',
                               (case when (b.p = 'HT') then spent else 0 end) as 'HT',
                               (case when (b.p = 'US') then spent else 0 end) as 'US',
                               (case when (b.p = 'NONE') then spent else 0 end) as 'NONE'
                        from (
                                select a.buyerid, a.p, sum(a.buy_price) as spent
                                from (
                                    SELECT buyerid, buy_date, buy_price,  
                                               (case when (substr(position,1,3) = 'BRC')  then 'BRC' #購買後推專
                                                     when (substr(position,1,2) = 'BZ')   then 'BZ' #購牌專區
                                                     when (substr(position,1,4) = 'FRND') then 'FRND' #明燈
                                                     when (substr(position,1,2) = 'FR')   then 'FR' #討論區
                                                     when (substr(position,1,3) = 'WPB')  then 'WPB' #勝率榜
                                                     when (substr(position,1,3) = 'MPB')  then 'MPB' #主推榜
                                                     when (substr(position,1,3) = 'IDX')  then 'IDX' #首頁
                                                     when (substr(position,1,2) = 'HT')   then 'HT' #頭三標
                                                     when (substr(position,1,2) = 'US')   then 'US' #玩家搜尋
                                                     when (position is null)              then 'NONE' else 'PROBLEM' end) as p 
                                    FROM plsport_playsport._predict_buyer_with_cons) as a
                                group by a.buyerid, a.p) as b) as c
                group by c.buyerid) as d;
        ALTER TABLE  `_buy_position` CHANGE  `buyerid`  `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';

        ALTER TABLE plsport_playsport._list_3 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._buy_position ADD INDEX (`buyerid`); 

create table plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       b.BRC, b.BZ, b.FRND, b.FR, b.WPB, b.MPB, b.IDX, b.HT, b.US, b.NONE, b.total
FROM plsport_playsport._list_3 a left join plsport_playsport._buy_position b on a.userid = b.buyerid;

        # (1)計算玩家搜尋的pv
        create table actionlog.action_usersearch engine = myisam
        SELECT userid, uri, time FROM actionlog.action_201404 where uri like '%usersearch.php%' and userid <> '';

        insert ignore into actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201405 where uri like '%usersearch.php%' and userid <> '';
        insert ignore into actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201406 where uri like '%usersearch.php%' and userid <> '';
        insert ignore into actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201407 where uri like '%usersearch.php%' and userid <> '';

        create table plsport_playsport._usersearch_count engine = myisam
        SELECT userid, count(userid) as us_pv
        FROM actionlog.action_usersearch
        group by userid;

        # (2)計算購牌專區的pv - 2014-06-24補充
        create table actionlog.action_buypredict engine = myisam
        SELECT userid, uri, time FROM actionlog.action_201404 where uri like '%buy_predict.php%' and userid <> '';

        insert ignore into actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201405 where uri like '%buy_predict.php%' and userid <> '';
        insert ignore into actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201406 where uri like '%buy_predict.php%' and userid <> '';
        insert ignore into actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201407 where uri like '%buy_predict.php%' and userid <> '';

        create table plsport_playsport._buypredict_count engine = myisam
        SELECT userid, count(userid) as bp_pv
        FROM actionlog.action_buypredict
        group by userid;

        ALTER TABLE plsport_playsport._list_4 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._usersearch_count ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._buypredict_count ADD INDEX (`userid`); 

create table plsport_playsport._list_5 engine = myisam
select c.userid, c.nickname, c.join_date, c.last_login, c.total_redeem, c.redeem_3_months,
       c.BRC, c.BZ, c.FRND, c.FR, c.WPB, c.MPB, c.IDX, c.HT, c.US, c.NONE, c.total, c.us_pv, d.bp_pv
from (
        SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
               a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, b.us_pv
        FROM plsport_playsport._list_4 a left join plsport_playsport._usersearch_count b on a.userid = b.userid) as c
        left join plsport_playsport._buypredict_count as d on c.userid = d.userid;


        # ========================================
        # 可以直接用之前寫的居住地查詢, 往上找就有
        # 產生_city_info_ok_with_chinese
        # 搜尋keyword "地址"
        # line: 1536
        # ========================================
        ALTER TABLE  `_city_info_ok_with_chinese` CHANGE  `userid`  `userid` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

        ALTER TABLE plsport_playsport._list_5 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);  

create table plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, b.city1
FROM plsport_playsport._list_5 a left join plsport_playsport._city_info_ok_with_chinese b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._list_6 ADD INDEX (`userid`);  
        ALTER TABLE actionlog._actionlog_platform_visit ADD INDEX (`userid`);  

create table plsport_playsport._list_7 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city1,
       b.desktop, b.mobile, b.tablet, b.desktop_p, b.mobile_p, b.tablet_p 
FROM plsport_playsport._list_6 a left join actionlog._actionlog_platform_visit b on a.userid = b.userid;

        ALTER TABLE  `_list_7` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;



#--------------------------------------------------------------------------------------------------------------------

create table plsport_playsport._pcash_log engine = myisam
SELECT userid, amount, date 
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1;

# 在3天內有消費的使用者
create table plsport_playsport._who_have_spent_in_three_day engine = myisam
SELECT userid, sum(amount) as spent_in_3_days
FROM plsport_playsport._pcash_log
where date between subdate(now(),4) and now()
group by userid;

        ALTER TABLE plsport_playsport._list_7 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._who_have_spent_in_three_day ADD INDEX (`userid`); 

create table plsport_playsport._list_8 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city1,
       a.desktop, a.mobile, a.tablet, a.desktop_p, a.mobile_p, a.tablet_p, b.spent_in_3_days
FROM plsport_playsport._list_7 a left join plsport_playsport._who_have_spent_in_three_day b on a.userid = b.userid;

# 結束
create table plsport_playsport._list_9 engine = myisam
SELECT * FROM plsport_playsport._list_8
where redeem_3_months is not null;

# ------------------------------
# 補充購買合牌的資訊
# ------------------------------

create table plsport_playsport._buy_match_prediction engine = myisam
select a.userid, sum(a.amount) as buy_match_predcition
from (
    SELECT userid, amount, date 
    FROM plsport_playsport.pcash_log
    where payed = 1 and type in (7,9)) as a
group by a.userid;

# ------------------------------
# 有在使用觀看預測比例的人
# ------------------------------
        # (2)計算購牌專區的pv - 2014-06-24補充
        create table actionlog.action_predict_game engine = myisam
        SELECT userid, uri, time FROM actionlog.action_201404 where uri like '%action=scale%' and userid <> '';

        insert ignore into actionlog.action_predict_game SELECT userid, uri, time FROM actionlog.action_201405 where uri like '%action=scale%' and userid <> '';
        insert ignore into actionlog.action_predict_game SELECT userid, uri, time FROM actionlog.action_201406 where uri like '%action=scale%' and userid <> '';
        insert ignore into actionlog.action_predict_game SELECT userid, uri, time FROM actionlog.action_201407 where uri like '%action=scale%' and userid <> '';

        create table plsport_playsport._predict_game_count engine = myisam
        SELECT userid, count(userid) as predict_game_pv
        FROM actionlog.action_predict_game
        group by userid;

        ALTER TABLE plsport_playsport._list_9 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._predict_game_count ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._buy_match_prediction ADD INDEX (`userid`); 

create table plsport_playsport._list_10 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city1,
       a.desktop, a.mobile, a.tablet, a.desktop_p, a.mobile_p, a.tablet_p, a.spent_in_3_days,
       b.buy_match_predcition
FROM plsport_playsport._list_9 a left join plsport_playsport._buy_match_prediction b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._list_10 ADD INDEX (`userid`);  

create table plsport_playsport._list_11 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city1,
       a.desktop, a.mobile, a.tablet, a.desktop_p, a.mobile_p, a.tablet_p, a.spent_in_3_days,
       a.buy_match_predcition, b.predict_game_pv
FROM plsport_playsport._list_10 a left join plsport_playsport._predict_game_count b on a.userid = b.userid;




# =================================================================================================
# 任務: [201401-M-5] 優化新使用者購買路徑 - 轉換率報告 [重新開啟] 2014-06-24(阿達)
# 
# 說明
# 整理新使用者買牌路徑各個環節的轉換率，供之後優化參考
# 
# 請於6/27(五)完成第二次轉換率報告，統計時間為 3/17 ~ 6/23
# 謝謝！
# 備註：不用整理事件5轉換率
# =================================================================================================

# 誰是從新使用者買牌路徑過來的訂單
create table plsport_playsport._who_is_from_new_user_path engine = myisam
SELECT userid, name, date(createon) as pay_date, price, payway, platform_type
FROM plsport_playsport.order_data
where create_from = 7 #產生的訂單是從新使用者買牌路徑過來的
and sellconfirm = 1
order by createon desc;

ALTER TABLE  `_who_is_from_new_user_path` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

# 這些人的加入會員時間點
create table plsport_playsport._who_is_from_new_user_path_1 engine = myisam
SELECT a.userid, a.name, a.pay_date, date(b.createon) as join_date, a.price, a.payway, a.platform_type
FROM plsport_playsport._who_is_from_new_user_path a left join plsport_playsport.member b on a.userid = b.userid;

# 每一個人曾經儲值過多少錢?
create table plsport_playsport._total_redeem_every_one engine = myisam
select a.userid, sum(a.price) as total_redeem
from (
    SELECT userid, price 
    FROM plsport_playsport.order_data
    where sellconfirm = 1
    and create_from in (0,1,2,3,4,5,6) # 記得要把0算進去
    and payway in (1,2,3,4,5,6)) as a
group by a.userid;

ALTER TABLE  `_total_redeem_every_one` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

# 從新使用者買牌路徑過來的人,在第一次儲值之後, 有沒有再度儲值?
create table plsport_playsport._who_is_from_new_user_path_2 engine = myisam
SELECT a.userid, a.name, a.pay_date, a.join_date, a.price, a.payway, a.platform_type, b.total_redeem
FROM plsport_playsport._who_is_from_new_user_path_1 a left join plsport_playsport._total_redeem_every_one b on a.userid = b.userid;


# =================================================================================================
# 請協助產生發送VIP優惠活動的問卷的受測名單(福利班)
# 
# 條件：
#   1. 300人
#   2. 依儲值總金額排序
#   3. 排除近期沒有登入的使用者（依照之前的名單，應該最近一天沒登入就會被排掉了）
# 
# 此名單要提供給工程，作為丟入問券用，如果可以的話，順便產生此格式
# 
#     任務狀態: 新建
# =================================================================================================

# 歷史儲值金額排名
create table plsport_playsport._redeem_ranking_1 engine = myisam
select b.userid, b.nickname, a.name, date(b.createon) as join_date, a.redeem
from ( 
    SELECT userid, name, sum(price) as redeem 
    FROM plsport_playsport.order_data
    where sellconfirm = 1
    group by userid) as a left join plsport_playsport.member b on a.userid = b.userid
order by a.redeem desc;


        # 最近一次的登入時間
        create table plsport_playsport._last_login_time engine = myisam
        SELECT userid, max(signin_time) as last_login
        FROM plsport_playsport.member_signin_log_archive
        group by userid;

        ALTER TABLE plsport_playsport._redeem_ranking_1 ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);

# 歷史儲值金額排名 + 最近一次的登入時間
create table plsport_playsport._redeem_ranking_2 engine = myisam
SELECT a.userid, a.nickname, a.name, a.join_date, a.redeem, date(b.last_login) as last_login
FROM plsport_playsport._redeem_ranking_1 a left join plsport_playsport._last_login_time b on a.userid = b.userid
where b.last_login is not null;

# 最後名單, 用貼上的就好
select a.userid, a.nickname, a.name, a.join_date, a.redeem, a.last_login, a.recent_login_day
from (
    SELECT userid, nickname, name, join_date, redeem, last_login, datediff(now(), last_login) as recent_login_day
    FROM plsport_playsport._redeem_ranking_2) as a
where a.recent_login_day < 10 # 要近10天內登入的人
order by a.redeem desc
limit 0, 320; # 只要320筆


# =================================================================================================
# 任務: 追蹤分析文點擊成效 [新建](福利班)
# 
#  分析文的三處將上追蹤網址，請Eddy追蹤一下點擊成效
# 
#     討論區文章最上方的最讚分析文列表
#     每篇文章最下方的最讚分析文列表
#     所有當日最讚分析文的分析文畫面
# 
# 目的：
# 1. 瞭解點擊分析文瀏覽的來源
# 2. 每篇文章最下方的最讚分析文列表是否有用
# 再請安排追蹤時間、於社群會議上報告時間，謝謝 
#
# 標題                    代碼 post_from=
# 討論區列表分析王區塊    FLA
# 討論區內頁分析王區塊    FDA
# 更多分析王列表          AL
# =================================================================================================

# 先撈出6月27日~7月13日的post_from=的所有LOG
create table actionlog.action_201406_post_from engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 where userid <> '' and uri like '%post_from=%';
create table actionlog.action_201407_post_from engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 where userid <> '' and uri like '%post_from=%';

        # 再把6月20日~7月13日的文章內頁log合併成一個檔
        create table actionlog.action_post_from engine = myisam SELECT * FROM actionlog.action_201406_post_from
        where time between '2014-06-27 00:00:00' and '2014-06-30 23:59:59';
        insert ignore into actionlog.action_post_from select * from actionlog.action_201407_post_from;

# 接下來的步驟就是在解析uri, 把uri中的變數一個個分出來
# 分出post_from
    create table actionlog.action_post_from_1 engine = myisam
    SELECT userid, uri, substr(uri,locate('post_from=',uri)+10) as u, time
    FROM actionlog.action_post_from;


# -----------------------------------------------------------

/*找出6月1日到7月13日之間的最讚分析文*/
create table plsport_playsport._analysis_king engine = myisam 
SELECT userid, subjectid, got_time, gamedate, 
       (case when (subjectid is not null) then 'y' end) as isanalysispost
FROM plsport_playsport.analysis_king
where got_time between '2011-06-12 00:00:00' and '2014-07-13 23:59:59'
order by got_time desc;

# 期間內最讚分析分 + 閱覽數viewtimes
create table plsport_playsport._analysis_king_viewtimes engine = myisam
SELECT a.userid, a.subjectid, a.got_time, a.gamedate, a.isanalysispost, b.viewtimes
FROM plsport_playsport._analysis_king a left join plsport_playsport.forum b on a.subjectid = b.subjectid
order by got_time;

        # 解析subjectid
        create table actionlog._who_see_analysis_king engine = myisam
        SELECT userid, uri, substr(uri,locate('subjectid=',uri)+10) as u, time 
        FROM actionlog.action_forumdetail;
        # 排除"&"之後多餘的字串
        create table actionlog._who_see_analysis_king_1 engine = myisam
        SELECT userid, uri, 
               (case when (locate('&',u) = 0) then u
                     when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as subjectid, time
        FROM actionlog._who_see_analysis_king;

        ALTER TABLE actionlog._who_see_analysis_king_1 CHANGE  `subjectid`  `subjectid` VARCHAR( 50 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
        ALTER TABLE plsport_playsport._analysis_king CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        ALTER TABLE actionlog._who_see_analysis_king_1 ADD INDEX (`subjectid`);
        ALTER TABLE plsport_playsport._analysis_king ADD INDEX (`subjectid`);

# 最讚分析文是被那些users看
create table actionlog._who_see_analysis_king_2 engine = myisam
SELECT a.userid, a.uri, a.subjectid, a.time, b.isanalysispost
FROM actionlog._who_see_analysis_king_1 a left join plsport_playsport._analysis_king b on a.subjectid = b.subjectid
where b.isanalysispost is not null;


        # 要觀察的區間是6/12~6/27和6/28~7/13
        # 計算出最讚分析文的數量, 和總被閱覽數
        # 前-
        SELECT count(subjectid) as subjectid_count, sum(viewtimes) as total_viewtimes 
        FROM plsport_playsport._analysis_king_viewtimes
        where got_time between '2014-06-12 00:00:00' and '2014-06-27 23:59:59';
        # 後-
        SELECT count(subjectid) as subjectid_count, sum(viewtimes) as total_viewtimes 
        FROM plsport_playsport._analysis_king_viewtimes
        where got_time between '2014-06-28 00:00:00' and '2014-07-13 23:59:59';

        # 計算出看最讚分析文的人有多少人
        # 前-
        select count(a.userid) as user_count
        from (
            SELECT userid, count(subjectid) as c
            FROM actionlog._who_see_analysis_king_2
            where time between '2014-06-12 00:00:00' and '2014-06-27 23:59:59'
            group by userid) as a;
        # 後-
        select count(a.userid) as user_count
        from (
            SELECT userid, count(subjectid) as c
            FROM actionlog._who_see_analysis_king_2
            where time between '2014-06-28 00:00:00' and '2014-07-13 23:59:59'
            group by userid) as a;


# 目的：
# 1. 瞭解點擊分析文瀏覽的來源
# 2. 每篇文章最下方的最讚分析文列表是否有用
# 再請安排追蹤時間、於社群會議上報告時間，謝謝 
#
# 標題                        代碼 post_from=
# 討論區列表分析王區塊        FLA
# 討論區文章內頁分析王區塊    FDA (新增)
# 更多分析王列表              AL

create table actionlog.action_201407_post_from engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 where userid <> '' and uri like '%post_from=%';

# 已分成20組, 1~10有看到, 11~20沒看到

create table actionlog.action_201407_post_from_1 engine = myisam
SELECT * FROM actionlog.action_201407_post_from
where time between '2014-07-22 18:00:00' and '2014-07-28 23:59:59';

# 接下來的步驟就是在解析uri, 把uri中的變數一個個分出來
# 分出post_from
create table actionlog.action_201407_post_from_2 engine = myisam
SELECT userid, uri, substr(uri,locate('post_from=',uri)+10) as u, time
FROM actionlog.action_201407_post_from_1;

        ALTER TABLE actionlog.action_201407_post_from_2 ADD INDEX (`userid`);
        ALTER TABLE actionlog.action_201407_post_from_2 CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog.action_201407_post_from_3 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.u, a.time 
FROM actionlog.action_201407_post_from_2 a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog.action_201407_post_from_4 engine = myisam
SELECT g, (case when (g<11) then 'A' else 'B' end) as abtest, userid, uri, u, time 
FROM actionlog.action_201407_post_from_3;

SELECT abtest, u, count(userid) as c 
FROM actionlog.action_201407_post_from_4
group by abtest, u;

create table actionlog.action_201407_post_from_5 engine = myisam
SELECT abtest, userid, u, count(userid) as c
FROM actionlog.action_201407_post_from_4
where substr(u,1,3) <> 'VMP'
group by abtest, userid, u;

select *
from (
    SELECT abtest, userid, sum(c) as c 
    FROM actionlog.action_201407_post_from_5
    group by abtest, userid) as a
order by a.c desc;


select a.abtest, sum(a.c) as c
from (
    SELECT abtest, userid, sum(c) as c 
    FROM actionlog.action_201407_post_from_5
    group by abtest, userid) as a 
group by a.abtest;


select a.abtest, count(a.userid) as user_count
from (
    SELECT abtest, userid, sum(c) as c 
    FROM actionlog.action_201407_post_from_5
    group by abtest, userid) as a
group by a.abtest;



# 輸出給R, 跑a/b testing檢定
select 'abtest', 'userid', 'u', 'c' union(
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/action_201407_post_from_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_201407_post_from_5);


select 'abtest', 'usreid', 'c' union (
SELECT abtest, userid, sum(c) as c
into outfile 'C:/Users/1-7_ASUS/Desktop/action_201407_post_from_6.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_201407_post_from_5
group by abtest, userid);



# =================================================================================================
# 任務: 個人頁顯示更多天預測 - A/B testing [新建] 2014-07-16(阿達)
# 
# 說明
# 提供 A/B testing名單及分析報告
# 負責人：Eddy 
# 
# 內容
# 1. 名單
# 2. 報告
# 觀察指標為購買預測營業額
# 區間6/17~7/13
# =================================================================================================


# 先撈出6月17日~7月13日的個人頁log
create table actionlog.action_201406_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 where userid <> '' and uri like '%visit_member.php%';
create table actionlog.action_201407_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 where userid <> '' and uri like '%visit_member.php%';

        # 再把6月17日~7月13日的個人頁log合併成一個檔
        create table actionlog.action_visit_member engine = myisam SELECT * FROM actionlog.action_201406_visit_member
        where time between '2014-06-17 00:00:00' and '2014-06-30 23:59:59';
        insert ignore into actionlog.action_visit_member select * from actionlog.action_201407_visit_member;

        # -------------------------------------
        # 再來執行code line 2398或搜尋"解析uri"
        # -------------------------------------

        ALTER TABLE actionlog.action_visit_member_edited CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        ALTER TABLE actionlog.action_visit_member_edited ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport.member ADD INDEX (`userid`);

# 加入分組資訊
create table actionlog.action_visit_member_edited_1 engine = myisam
SELECT (b.id%10)+1 as g, a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time
FROM actionlog.action_visit_member_edited a left join plsport_playsport.member b on a.userid = b.userid;

# 弄成群組grouped
create table actionlog.action_visit_member_edited_1_grouped engine = myisam
SELECT g, userid, gameday, count(userid) as c 
FROM actionlog.action_visit_member_edited_1
where userid <> visit
group by g, userid, gameday;

#  組1,2,3總共有多少人?
select count(a.userid) as user_count
from (
    SELECT userid, sum(c) as c 
    FROM actionlog.action_visit_member_edited_1_grouped
    where g in (1,2,3)
    group by userid) as a;

# 組1,2,3有多少人去點新增的按紐(2天前/3天前/4天前)
select count(a.userid) as user_count
from (
    SELECT userid, sum(c) as c 
    FROM actionlog.action_visit_member_edited_1_grouped
    where gameday in ("2daysAgo", "3daysAgo", "4daysAgo")
    and g in (1,2,3)
    group by userid) as a;

create table plsport_playsport._user_spent_0617_0713 engine = myisam
select c.g, c.userid, sum(c.spent) as total_spent
from (
    SELECT (b.id%10)+1 as g, a.userid, a.amount as spent, a.date
    FROM plsport_playsport.pcash_log a left join plsport_playsport.member b on a.userid = b.userid
    where a.date between '2014-06-17 00:00:00' and '2014-07-13 23:59:59'
    and a.payed = 1 and a.type = 1) as c
group by c.userid;


SELECT g, sum(total_spent) as total_spent
FROM plsport_playsport._user_spent_0617_0713
group by g;

SELECT g, count(userid) as user_count 
FROM plsport_playsport._user_spent_0617_0713
group by g;


# 輸出給R, 跑a/b testing檢定
select 'g', 'userid', 'total_spent' union(
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/user_spent_0617_0713.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._user_spent_0617_0713);





# =================================================================================================
# to Eddy : (阿達)
# 第二階段優化( 非殺手個人頁顯示購買後推薦專區) A/B testing已上線，再麻煩於 7/25(五)提交報告，謝謝。
# 實驗時間：6/23 ~ 7/21 <<< 記得不要撈錯
# =================================================================================================

# 先看點擊
create table actionlog.action_visit_member_edited_1_recommand engine = myisam
select a.g, a.userid, a.p, count(a.userid) as c
from (
    SELECT g, userid, uri, substr(uri,locate("&rp=",uri)+4,length(uri)) as p, time
    FROM actionlog.action_visit_member_edited_1
    where uri like '%rp=BRC%'
    and time between '2014-06-23 00:00:00' and '2014-07-13 23:59:59') as a
group by a.g, a.userid, a.p;

SELECT g, p, sum(c) as c
FROM actionlog.action_visit_member_edited_1_recommand
group by g, p;

# 查閱收益by position
# 因為_predict_buyer_with_cons每天固定都會產生, 所以不用再做了

create table plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT (b.id%10)+1 as g, a.buyerid, a.buy_date, a.buy_price, a.position 
FROM plsport_playsport._predict_buyer_with_cons a left join plsport_playsport.member b on a.buyerid = b.userid
where a.buy_date between '2014-06-23 00:00:00' and '2014-07-13 23:59:59'
order by buy_date desc;

        # 所有位置的各組購買情況
        SELECT g, sum(buy_price) as revenue 
        FROM plsport_playsport._predict_buyer_with_cons_1
        #where substr(position,1,3) = 'BRC'
        group by g;

        # 購牌專區的各組購買情況
        SELECT g, sum(buy_price) as revenue 
        FROM plsport_playsport._predict_buyer_with_cons_1
        where substr(position,1,3) = 'BRC'
        group by g;

        SELECT g, position, sum(buy_price) as total_spent
        FROM plsport_playsport._predict_buyer_with_cons_1
        where substr(position,1,3) = 'BRC'
        and buy_date between '2014-06-23 00:00:00' and '2014-07-13 23:59:59'
        group by g, position;

        SELECT g, sum(buy_price) as total_spent 
        FROM plsport_playsport._predict_buyer_with_cons_1
        where buy_date between '2014-06-23 00:00:00' and '2014-07-13 23:59:59'
        group by g;


# -------------輸出給R, 跑a/b testing檢定-------------
# 只有BRC購買後推廌專區
select 'g', 'userid', 'v', 'total_spent' union(
select a.g, a.buyerid, a.v, sum(a.buy_price) as total_spent
into outfile 'C:/Users/1-7_ASUS/Desktop/user_spent_0617_0713_for_recommand_only_brc.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
from (
    SELECT g, buyerid, buy_price, substr(position,6,1) as v 
    FROM plsport_playsport._predict_buyer_with_cons_1
    where substr(position,1,3) = 'BRC'
    and buy_date between '2014-06-23 00:00:00' and '2014-07-13 23:59:59') as a
group by a.buyerid);

# 所有的位置
select 'g', 'userid', 'total_spent' union(
SELECT g, buyerid, sum(buy_price) as total_spent 
into outfile 'C:/Users/1-7_ASUS/Desktop/user_spent_0617_0713_for_recommand_all.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._predict_buyer_with_cons_1
where buy_date between '2014-06-23 00:00:00' and '2014-07-13 23:59:59'
group by buyerid);


# =================================================================================================
# 任務: 撈取分析文與最讚分析文數量 [新建](柔雅)
# 麻煩你，協助撈取以下時間(2014年)內的:
# a.分析文(亮分析標籤的)數量
# b.最讚分析文(有被工友選上的)數量
# 時間:
# 
# 1.4月全月
# 2.05/01-05/15
# 3.05/16-05/31
# 4.06/01-06/15
# 5.06/19-07/02
# 6.07/03-07/16
# 
# 不急的小任務，你有空再做就好，
# 麻煩你了，感謝。
# =================================================================================================

select a.m, a.allianceid, count(a.subjectid) as best_ana_post_count
from (
    SELECT userid, subjectid, allianceid ,date(got_time) as d, substr(got_time,1,7) as m, year(got_time) as y
    FROM plsport_playsport.analysis_king
    where got_time between '2012-01-01 00:00:00' and '2014-12-31 23:59:59') as a
group by a.m, a.allianceid;

create table plsport_playsport._3 engine = myisam
select a.d, a.allianceid, count(a.subjectid) as best_ana_post_count
from (
    SELECT userid, subjectid, allianceid, date(got_time) as d, substr(got_time,1,7) as m, year(got_time) as y
    FROM plsport_playsport.analysis_king
    where got_time between '2014-01-01 00:00:00' and '2014-12-31 23:59:59') as a
group by a.d, a.allianceid;

create table plsport_playsport._2 engine = myisam
select a.m, a.allianceid, count(a.subjectid) as ana_post_count
from (
    SELECT subjectid, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    where gametype = 1
    and posttime between '2012-01-01 00:00:00' and '2014-12-31 23:59:59'
    order by posttime) as a
group by a.m, a.allianceid;

create table plsport_playsport._4 engine = myisam
select a.d, a.allianceid, count(a.subjectid) as ana_post_count
from (
    SELECT subjectid, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    where gametype = 1
    and posttime between '2014-01-01 00:00:00' and '2014-12-31 23:59:59'
    order by posttime) as a
group by a.d, a.allianceid;


# =================================================================================================
# 任務: 蘋果日報成效追蹤 [新建] (柔雅)
# 
#  TO EDDY:
# 我們於720、7/22、7/23這三天，在蘋果日報上面打廣告，
# 附件是這三天有回傳簡訊的使用者，
# 請幫我們分析:
# 1.當天是否有登入網站?
# 2.當天是否有使用贈送的兌換券，觀看預測
# 3.活動結束後，後續是否有持續登入?
# 4.是否有儲值噱幣?
# =================================================================================================

# 要先準備好apple名單(要自行匯入)
use plsport_playsport;

        ALTER TABLE plsport_playsport.applelist ADD INDEX (`userid`);

create table plsport_playsport._applelist1 engine = myisam
SELECT a.userid, a.sent_text, b.nickname, b.browses, b.createon
FROM plsport_playsport.applelist a left join plsport_playsport.member b on a.userid = b.userid;

# 最後一次登入的記錄
create table plsport_playsport._who_last_signin engine = myisam
select a.userid, a.last_sign_in, substr(a.last_sign_in,1,7) as m
from (
    SELECT userid, max(signin_time) as last_sign_in 
    FROM plsport_playsport.member_signin_log_archive
    group by userid
    order by signin_time desc) as a;

        ALTER TABLE `_who_last_signin` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._who_last_signin ADD INDEX (`userid`);

create table plsport_playsport._applelist2 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.createon, b.last_sign_in
FROM plsport_playsport._applelist1 a left join plsport_playsport._who_last_signin b on a.userid = b.userid;

# 登入的次數
create table plsport_playsport._signin_count engine = myisam
SELECT userid, count(signin_time) as sign_in_count
FROM plsport_playsport.member_signin_log_archive
group by userid
order by signin_time desc;

        ALTER TABLE `_signin_count` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._signin_count ADD INDEX (`userid`);

create table plsport_playsport._applelist3 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.createon, a.last_sign_in, b.sign_in_count
FROM plsport_playsport._applelist2 a left join plsport_playsport._signin_count b on a.userid = b.userid;

# 使用抵用券的次數
create table plsport_playsport._coupon_used_count engine = myisam
SELECT userid, count(id) as coupon_used_count
FROM plsport_playsport.coupon_used_detail
where type = 1
group by userid;

        ALTER TABLE `_coupon_used_count` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._coupon_used_count ADD INDEX (`userid`);

create table plsport_playsport._applelist4 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.createon, a.last_sign_in, a.sign_in_count, b.coupon_used_count
FROM plsport_playsport._applelist3 a left join plsport_playsport._coupon_used_count b on a.userid = b.userid;

# 花了多少噱幣
create table plsport_playsport._pcash_log engine = myisam
SELECT userid, sum(amount) as total_spent
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
group by userid;

# 儲值了多少噱幣
create table plsport_playsport._order_data engine = myisam
SELECT userid, sum(price) as redeem_total 
FROM plsport_playsport.order_data
where sellconfirm = 1
group by userid;

        ALTER TABLE `_pcash_log` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._pcash_log ADD INDEX (`userid`);
        ALTER TABLE `_order_data` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._order_data ADD INDEX (`userid`);

create table plsport_playsport._applelist5 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.createon, a.last_sign_in, a.sign_in_count, a.coupon_used_count, b.total_spent
FROM plsport_playsport._applelist4 a left join plsport_playsport._pcash_log b on a.userid = b.userid;

create table plsport_playsport._applelist6 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.createon, a.last_sign_in, a.sign_in_count, a.coupon_used_count, a.total_spent, b.redeem_total
FROM plsport_playsport._applelist5 a left join plsport_playsport._order_data b on a.userid = b.userid;




# =================================================================================================
# 任務: 預測不佳補償機制問券名單 [新建] (福利班)
# 
# Eddy ，煩請產生問券名單，並且提供給壯兔，此名單需求時間為
# 7/30
# 工程任務為 http://pm.playsport.cc/index.php/tasksComments?tasksId=3266&projectId=1
# 消費者
#     條件：近一個月內有消費紀錄的人
# 殺手
#     條件：(1)近6個月內有販售的人
#           (2)要賺超過1000元
# 請再比對兩名單內有重疊的數量，再討論如何排除
# =================================================================================================

# 誰在近1個月內有消費
create table plsport_playsport._who_buy_in_one_month engine = myisam
select a.userid, sum(a.amount) as total_spent
from (
    SELECT * 
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1
    and date between subdate(now(),31) and now()) as a # 區間1個月
group by a.userid;

        # 結合perdict_buyer和predict_seller
        create table plsport_playsport._predict_buyer engine = myisam
        SELECT buyerid, buy_date, buy_price, id_bought 
        FROM plsport_playsport.predict_buyer
        where year(buy_date) = 2014;

        create table plsport_playsport._predict_seller engine = myisam
        SELECT id, sellerid, sale_date  
        FROM plsport_playsport.predict_seller
        where year(sale_date) = 2014;

                ALTER TABLE plsport_playsport._predict_buyer  ADD INDEX (`buyerid`);
                ALTER TABLE plsport_playsport._predict_seller ADD INDEX (`id`);

        create table plsport_playsport._predict_buyer_and_seller engine = myisam
        SELECT a.buyerid, a.buy_date, a.buy_price, b.sellerid, b.sale_date 
        FROM plsport_playsport._predict_buyer a left join plsport_playsport._predict_seller b on a.id_bought = b.id;


# 誰在近6個月內有賣牌
create table plsport_playsport._who_earn_in_three_month engine = myisam
select b.sellerid, b.total_earn
from (
    select a.sellerid, sum(a.buy_price) as total_earn
    from (
        SELECT sellerid, buy_date, buy_price, buyerid
        FROM plsport_playsport._predict_buyer_and_seller
        where buy_date between subdate(now(),186) and now() # 區間6個月
        order by buy_date desc) as a 
    group by a.sellerid) as b
order by b.total_earn desc;

# perfrom outer join in mysql
# SELECT * FROM t1
# LEFT JOIN t2 ON t1.id = t2.id
# UNION
# SELECT * FROM t1
# RIGHT JOIN t2 ON t1.id = t2.id

# merge (1)誰在近1個月內有消費和(2)誰在近6個月內有賣牌
create table plsport_playsport._outer_join_full_list engine = myisam
select * from plsport_playsport._who_buy_in_one_month a left join plsport_playsport._who_earn_in_three_month b on a.userid = b.sellerid
union
select * from plsport_playsport._who_buy_in_one_month a right join plsport_playsport._who_earn_in_three_month b on a.userid = b.sellerid;

# 輸出.txt
select 'userid', 'total_spent', 'sellerid', 'total_earn' union(
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_outer_join_full_list.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._outer_join_full_list);



# =================================================================================================
# 任務: [201407-A-3] 殺手合牌燒券 - 分析合牌開賣時間 [新建] (阿達) 2014-08-05
# 說明
# 分析各聯盟開放時間，以便專案人員評估是否要調整規則
# 
# 負責人：Eddy 
# 
# 時間：8/4 (一)
# 分析報告
# 聯盟：MLB、日本職棒
# 分析區間（開賽日)：7/23 ~ 28
# 分析內容：
# 1. 統計 MLB、日本職棒每個時間點開賣場次百分比  ex : 晚上六點有 30%的MLB比賽開賣
# 2. MLB 統計時間點為開賽前一日的 15:00 , 18:00 , 21:00
# 3. 日本職棒 統計時間點為開賽當日的 11:00 , 13:00 , 15:00
# 資料表：predict_seller_team_new (sellable_time是開賣時間)
# 
# =================================================================================================

create table plsport_playsport._predict_seller_team_new engine = myisam
SELECT id, mode, allianceid, gamedate, gameid, is_sellable, sellers_count, create_time, date(create_time) as d,
       hour(create_time) as h, sellable_time
FROM plsport_playsport.predict_seller_team_new
where allianceid in (1,2)
order by create_time, allianceid;




# =================================================================================================
# 任務: [201401-K-7]網站首頁改版-優化ABTESEING [進行中] (靜怡) 2014-08-06
# 
# (a)購買沒有成功例子(沒登入去按購買, 有登入但沒噱幣)
# 去撈action_log
# /click_buy_button_from_index.php?from=IDX
# /click_buy_button_from_index.php?from=IDX_C
# 
# (b)購買成功的例子
# 直接撈predict_buyer購買位置追蹤的購買次數
# 
# 點擊率的統計就是(a) + (b)
# =================================================================================================


create table actionlog._action_201407_click_buy_button_from_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201407
where uri like '%click_buy_button_from_index.php?from=IDX%';

create table actionlog._action_201408_click_buy_button_from_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201408
where uri like '%click_buy_button_from_index.php?from=IDX%';

create table actionlog._action_click_buy_button_from_index engine = myisam
select * from actionlog._action_201407_click_buy_button_from_index;
insert ignore into actionlog._action_click_buy_button_from_index 
select * from actionlog._action_201408_click_buy_button_from_index;

create table actionlog._action_click_buy_button_from_index_edited engine = myisam
SELECT id, userid, uri, substr(uri,locate('from=',uri)+5,length(uri)) as p, time
FROM actionlog._action_click_buy_button_from_index
where time between '2014-07-19 00:00:00' and '2014-08-01 12:00:00';

create table plsport_playsport._predict_buyer_with_cons_edited engine = myisam
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-07-19 00:00:00' and '2014-08-01 12:00:00'
and substr(position,1,3) = 'IDX';


# 查詢計數 - 未成功的購買
SELECT p, count(userid) as c 
FROM actionlog._action_click_buy_button_from_index_edited
group by p;

# 查詢計數 - 有成功的購買
select a.position, count(a.buyerid) as c, sum(a.buy_price) as spent
from (
    SELECT * 
    FROM plsport_playsport._predict_buyer_with_cons
    where buy_date between '2014-07-19 00:00:00' and '2014-08-01 12:00:00'
    and substr(position,1,3) = 'IDX') as a
group by a.position;


create table actionlog._action_click_buy_button_from_index_edited_all engine = myisam
SELECT userid, p, time
FROM actionlog._action_click_buy_button_from_index_edited
union
SELECT buyerid as userid, position as p, buy_date as time
FROM plsport_playsport._predict_buyer_with_cons_edited;

    ALTER TABLE `_action_click_buy_button_from_index_edited_all` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '';

create table actionlog._action_click_buy_button_from_index_edited_all_member engine = myisam
SELECT a.userid, b.createon, a.p, a.time 
FROM actionlog._action_click_buy_button_from_index_edited_all a left join plsport_playsport.member b on a.userid = b.userid
where a.userid <> '';


SELECT * 
FROM actionlog._action_click_buy_button_from_index_edited_all_member
order by createon desc;


select b.p, b.join_m, count(b.userid) as c
from (
    select a.userid, a.join_m, a.p, count(a.userid) as c
    from (
        SELECT userid, substr(createon,1,7) as join_m, p
        FROM actionlog._action_click_buy_button_from_index_edited_all_member
        order by createon desc) as a
    group by a.userid, a.join_m, a.p) as b 
group by b.p, b.join_m;


select a.p, a.join_m, count(a.userid) as c
from (
    SELECT userid, substr(createon,1,7) as join_m, p
    FROM actionlog._action_click_buy_button_from_index_edited_all_member
    order by createon desc) as a
group by a.p, a.join_m;


select *
from (
    select a.userid, a.join_m, a.p, count(a.userid) as c
    from (
        SELECT userid, substr(createon,1,7) as join_m, p
        FROM actionlog._action_click_buy_button_from_index_edited_all_member
        order by createon desc) as a
    group by a.userid, a.join_m, a.p) as b
order by b.c desc;


create table actionlog._action_201407_goforum_from_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201407
where uri like '%forumdetail.php%'
and time between '2014-07-19 00:00:00' and '2014-08-01 12:00:00';

create table actionlog._action_201408_goforum_from_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201408
where uri like '%forumdetail.php%'
and time between '2014-07-19 00:00:00' and '2014-08-01 12:00:00';


create table actionlog._action_goforum_from_index engine = myisam
SELECT * FROM actionlog._action_201407_goforum_from_index;
insert ignore into actionlog._action_goforum_from_index
SELECT * FROM actionlog._action_201408_goforum_from_index;

create table actionlog._action_goforum_from_index_1 engine = myisam
SELECT * 
FROM actionlog._action_goforum_from_index
where uri like '%from=I%';

create table actionlog._action_goforum_from_index_2 engine = myisam
SELECT userid, uri, substr(uri,locate('from=',uri)+5,length(uri)) as p, substr(time,1,7) as m 
FROM actionlog._action_goforum_from_index_1;

    ALTER TABLE `_action_goforum_from_index_2` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '';

create table actionlog._action_goforum_from_index_3 engine = myisam
SELECT a.userid, substr(b.createon,1,7) as join_month, a.uri, a.p, a.m
FROM actionlog._action_goforum_from_index_2 a left join plsport_playsport.member b on a.userid = b.userid;


SELECT p, join_month, count(userid) as c 
FROM actionlog._action_goforum_from_index_3
where userid <> ''
group by p, join_month;


select b.pp, b.join_month, count(b.userid) as c
from (
    select a.pp, a.join_month, a.userid, count(a.userid) as c
    from (
        SELECT userid, join_month, p, 
               (case when (p = 'ID') then 'IDX'
                     when (p = 'IDX_C') then 'IDX_C'
                     else 'IDX' end) as pp, m
        FROM actionlog._action_goforum_from_index_3
        where userid <> '') as a 
    group by a.pp, a.join_month, a.userid) as b
group by b.pp, b.join_month;



# =================================================================================================
# 任務: [201407-E-1] 即時比分使用者訪談 - 訪談名單 [新建] (阿達)
# 
# 說明
# 請提供訪談名單，供文婷約訪
# 時間：8/8(五)
# 負責人：Eddy
# 
# --訪談名單1
# 1. 統計區間
# 2014/6/15起
# 2. 篩選條件
# 即時比分 pv佔全站前 50%
# 3. 資料欄位
# 帳號、暱稱、**PV及全站佔比(總PV、MLB1、日本職棒2、中華職棒6)、即時比分問卷評價、居住地、**手機/電腦使用比率、
# 
# --訪談名單2
# 1. 統計區間
# 2014/4/1起
# 2. 篩選條件
# 即時比分問卷評價低於平均
# 3. 資料欄位
# 帳號、暱稱、PV及全站佔比(總PV、MLB、日本職棒、中華職棒)、即時比分問卷評價、手機/電腦使用比率
# =================================================================================================

create table actionlog_users_pv.action_livescore_201404 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201404
where userid <> '' and uri like '%livescore.php%';

create table actionlog_users_pv.action_livescore_201405 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201405
where userid <> '' and uri like '%livescore.php%';

create table actionlog_users_pv.action_livescore_201406 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201406
where userid <> '' and uri like '%livescore.php%';

create table actionlog_users_pv.action_livescore_201407 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201407
where userid <> '' and uri like '%livescore.php%';

create table actionlog_users_pv.action_livescore engine = myisam
select * from actionlog_users_pv.action_livescore_201404;
insert ignore into actionlog_users_pv.action_livescore select * from actionlog_users_pv.action_livescore_201405;
insert ignore into actionlog_users_pv.action_livescore select * from actionlog_users_pv.action_livescore_201406;
insert ignore into actionlog_users_pv.action_livescore select * from actionlog_users_pv.action_livescore_201407;

drop table actionlog_users_pv.action_livescore_201404;
drop table actionlog_users_pv.action_livescore_201405;
drop table actionlog_users_pv.action_livescore_201406;
drop table actionlog_users_pv.action_livescore_201407;

create table actionlog_users_pv.action_livescore_1 engine = myisam
SELECT userid, uri, (case when (locate('aid=',uri))=0 then 0 else substr(uri,locate('aid=',uri)+4,length(uri)) end) as m, time, platform 
FROM actionlog_users_pv.action_livescore;

create table actionlog_users_pv.action_livescore_2 engine = myisam
SELECT userid, uri, m, (case when (locate('&',m)=0) then m else substr(m,1,locate('&',m)-1) end) as aid, time, platform
FROM actionlog_users_pv.action_livescore_1;

create table actionlog_users_pv.action_livescore_3 engine = myisam
SELECT userid, uri, (case when (aid=0) then 1 else aid end) as aid, time, platform 
FROM actionlog_users_pv.action_livescore_2;

# --名單區--
# (1)取得問券中使用者對即時比分的評價
create table plsport_playsport._livescore_score engine = myisam
SELECT userid, livescore_score, livescore_improve
FROM plsport_playsport.satisfactionquestionnaire_answer
where livescore_notused = 0;

# (2)產生_city_info_ok_with_chinese居住地資訊
#    --執行之前寫的SQL

# (3)nickname


# (4)最後一次登入的時間
create table plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
group by userid;

        ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._livescore_score ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);

        ALTER TABLE `_livescore_score` CHANGE `userid` `userid` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE `_city_info_ok_with_chinese` CHANGE `userid` `userid` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE `_last_signin` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

# --------------------------------------------
# 從這裡開始製作名單 (第二份名單就直接改日期) 
# --------------------------------------------

create table actionlog_users_pv._action_livescore_3_pv_total engine = myisam # 即時比分的pv
SELECT userid, count(userid) as pv_total 
FROM actionlog_users_pv.action_livescore_3
where time between '2014-06-15 00:00:00' and '2014-07-31 23:59:59'
group by userid;

        create table actionlog_users_pv._action_livescore_3_pv_mlb engine = myisam # 即時比分的pv - MLB
        SELECT userid, count(userid) as pv_total 
        FROM actionlog_users_pv.action_livescore_3
        where time between '2014-06-15 00:00:00' and '2014-07-31 23:59:59' and aid = 1
        group by userid;

        create table actionlog_users_pv._action_livescore_3_pv_jpb engine = myisam # 即時比分的pv - 日棒
        SELECT userid, count(userid) as pv_total 
        FROM actionlog_users_pv.action_livescore_3
        where time between '2014-06-15 00:00:00' and '2014-07-31 23:59:59' and aid = 2
        group by userid;

        create table actionlog_users_pv._action_livescore_3_pv_cpb engine = myisam # 即時比分的pv - 中職
        SELECT userid, count(userid) as pv_total 
        FROM actionlog_users_pv.action_livescore_3
        where time between '2014-06-15 00:00:00' and '2014-07-31 23:59:59' and aid = 6
        group by userid;

        create table actionlog_users_pv._action_livescore_3_pv_device engine = myisam # 即時比分的pv - 裝罝
        select b.userid, sum(b.pv_PC) as pv_PC, sum(b.pv_mobile) as pv_mobile
        from (
            select a.userid, (case when (a.platform='PC') then c else 0 end) as pv_PC, (case when (a.platform='mobile') then c else 0 end) as pv_mobile
            from (
                SELECT userid, platform, count(userid) as c
                FROM actionlog_users_pv.action_livescore_3
                where time between '2014-06-15 00:00:00' and '2014-07-31 23:59:59'
                group by userid, platform) as a) as b
        group by b.userid;

        create table actionlog_users_pv._action_livescore_3_pv_device_1 engine = myisam # 即時比分的pv - 裝罝比例(使用這個)
        SELECT userid, pv_PC, pv_mobile, round(pv_PC/(pv_PC+pv_mobile),2) as PC_precent, round(pv_mobile/(pv_PC+pv_mobile),2) as Mobile_precent
        FROM actionlog_users_pv._action_livescore_3_pv_device;

                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_total ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_mlb ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_jpb ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_cpb ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_device_1 ADD INDEX (`userid`);


create table actionlog_users_pv.action_livescore_4 engine = myisam
select c.userid, c.nickname, date(c.createon) as join_date, date(d.last_signin) as last_signin, c.pv_total
from (
    SELECT a.userid, b.nickname, b.createon, a.pv_total  
    FROM actionlog_users_pv._action_livescore_3_pv_total a left join plsport_playsport.member b on a.userid = b.userid) as c
    left join plsport_playsport._last_signin d on c.userid = d.userid;

create table actionlog_users_pv.action_livescore_5 engine = myisam
select e.userid, e.nickname, e.join_date, e.last_signin, e.pv_total, e.pv_mlb, e.pv_jpb, f.pv_total as pv_cpb
from (
    select c.userid, c.nickname, c.join_date, c.last_signin, c.pv_total, c.pv_mlb, d.pv_total as pv_jpb
    from (
        SELECT a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, b.pv_total as pv_mlb
        FROM actionlog_users_pv.action_livescore_4 a left join actionlog_users_pv._action_livescore_3_pv_mlb b on a.userid = b.userid) as c
        left join actionlog_users_pv._action_livescore_3_pv_jpb d on c.userid = d.userid) as e
    left join actionlog_users_pv._action_livescore_3_pv_cpb as f on e.userid = f.userid;


# 名單1
create table actionlog_users_pv.action_livescore_6_list1 engine = myisam
select e.userid, e.nickname, e.join_date, e.last_signin, e.pv_total, e.pv_mlb, e.pv_jpb, e.pv_cpb, 
       e.pv_PC, e.pv_mobile, e.PC_precent, e.Mobile_precent, e.city, f.livescore_score, f.livescore_improve
from (
    select c.userid, c.nickname, c.join_date, c.last_signin, c.pv_total, c.pv_mlb, c.pv_jpb, c.pv_cpb, 
           c.pv_PC, c.pv_mobile, c.PC_precent, c.Mobile_precent, d.city1 as city
    from (
        SELECT a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, b.pv_PC, b.pv_mobile, b.PC_precent, b.Mobile_precent
        FROM actionlog_users_pv.action_livescore_5 a left join actionlog_users_pv._action_livescore_3_pv_device_1 b on a.userid = b.userid) as c 
    left join plsport_playsport._city_info_ok_with_chinese as d on c.userid = d.userid) as e
left join plsport_playsport._livescore_score as f on e.userid = f.userid;

# 名單2
create table actionlog_users_pv.action_livescore_6_list2 engine = myisam
select e.userid, e.nickname, e.join_date, e.last_signin, e.pv_total, e.pv_mlb, e.pv_jpb, e.pv_cpb, 
       e.pv_PC, e.pv_mobile, e.PC_precent, e.Mobile_precent, e.city, f.livescore_score, f.livescore_improve
from (
    select c.userid, c.nickname, c.join_date, c.last_signin, c.pv_total, c.pv_mlb, c.pv_jpb, c.pv_cpb, 
           c.pv_PC, c.pv_mobile, c.PC_precent, c.Mobile_precent, d.city1 as city
    from (
        SELECT a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, b.pv_PC, b.pv_mobile, b.PC_precent, b.Mobile_precent
        FROM actionlog_users_pv.action_livescore_5 a left join actionlog_users_pv._action_livescore_3_pv_device_1 b on a.userid = b.userid) as c 
    left join plsport_playsport._city_info_ok_with_chinese as d on c.userid = d.userid) as e
left join plsport_playsport._livescore_score as f on e.userid = f.userid;


create table actionlog_users_pv.action_livescore_6_list1_edited engine = myisam
SELECT b.id, a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, a.pv_PC, a.pv_mobile, a.PC_precent, a.Mobile_precent,
       a.city, a.livescore_score, a.livescore_improve 
FROM actionlog_users_pv.action_livescore_6_list1 a left join plsport_playsport.member b on a.userid = b.userid;


create table actionlog_users_pv.action_livescore_6_list2_edited engine = myisam
SELECT b.id, a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, a.pv_PC, a.pv_mobile, a.PC_precent, a.Mobile_precent,
       a.city, a.livescore_score, a.livescore_improve 
FROM actionlog_users_pv.action_livescore_6_list2 a left join plsport_playsport.member b on a.userid = b.userid;



# =================================================================================================
# 任務: [201406-B-5]強化玩家搜尋-MVP名單撈取 [新建] (靜怡)
# 說明
# 提供MVP名單
#  
# 內容
# - 族群：D1~D5
# - 近三個月有消費的使用者<-用這個當主名單
# - 經常使用玩家搜尋
# -欄位：暱稱、ID、總儲值金額、近三個月儲值金額、玩家搜尋消費金額、玩家搜尋PV、電腦與手機使用比率、最近登入時間、最近購買預測時間
# =================================================================================================


create table actionlog.action_usersearch_201405 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201405 where userid <> '' and uri like '%usersearch.php%';
create table actionlog.action_usersearch_201406 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201406 where userid <> '' and uri like '%usersearch.php%';
create table actionlog.action_usersearch_201407 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201407 where userid <> '' and uri like '%usersearch.php%';
create table actionlog.action_usersearch_201408 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201408 where userid <> '' and uri like '%usersearch.php%';

create table actionlog.action_usersearch engine = myisam
SELECT * FROM actionlog.action_usersearch_201405;
insert ignore into actionlog.action_usersearch SELECT * FROM actionlog.action_usersearch_201406;
insert ignore into actionlog.action_usersearch SELECT * FROM actionlog.action_usersearch_201407;
insert ignore into actionlog.action_usersearch SELECT * FROM actionlog.action_usersearch_201408;

create table actionlog._action_usersearch engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'pc' else 'mobile' end) as platform
FROM actionlog.action_usersearch;



# 使用玩家搜尋pv
create table plsport_playsport._user_use_usersearch_count engine = myisam
SELECT userid, count(uri) as us_count 
FROM actionlog.action_usersearch
where time between subdate(now(),93) and now()
group by userid;

# 使用玩家搜尋pv-裝置devices
create table plsport_playsport._user_use_usersearch_platform engine = myisam
select c.userid, sum(c.pc_pv) as pc_pv, sum(c.mobile_pv) as mobile_pv
from (
    select b.userid, (case when (b.pc_pv is not null) then b.pc_pv else 0 end) as pc_pv, (case when (b.mobile_pv is not null) then b.mobile_pv else 0 end) as mobile_pv
    from (
        select a.userid, (case when (a.platform_type=1) then c end) as pc_pv, (case when (a.platform_type>1) then c end) as mobile_pv
        from (
            SELECT userid, platform_type, count(uri) as c 
            FROM actionlog.action_usersearch
            where time between subdate(now(),93) and now()
            group by userid, platform_type) as a) as b) as c
group by c.userid;

# 最近一次的登入時間
create table plsport_playsport._last_login_time engine = myisam
SELECT userid, max(signin_time) as last_login
FROM plsport_playsport.member_signin_log_archive
group by userid;

ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);  

# 近3個月有消費名單
create table plsport_playsport._user_spent_in_three_month engine = myisam
SELECT userid, sum(amount) as spent_pcash 
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between subdate(now(),93) and now()
group by userid;

# 最後一次購買預測的時間
create table plsport_playsport._user_spent_last_time engine = myisam
select userid, amount, max(date) as last_pay_date
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
group by userid;

ALTER TABLE plsport_playsport._user_spent_last_time ADD INDEX (`userid`);  


        # 玩家搜尋消費金額<-使用之前的code line:3067
        drop table if exists plsport_playsport._predict_buyer;
        drop table if exists plsport_playsport._predict_buyer_with_cons;

        #此段SQL是計算各購牌位置記錄的金額
        #先predict_buyer + predict_buyer_cons_split
        create table plsport_playsport._predict_buyer engine = myisam
        SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
        FROM plsport_playsport.predict_buyer a left join plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
        where a.buy_price <> 0
        and a.buy_date between subdate(now(),93) and now(); #2014/03/04是開始有購牌追蹤代碼的日子

        ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

        #再join predict_seller
        create table plsport_playsport._predict_buyer_with_cons engine = myisam
        select c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
        from plsport_playsport._predict_buyer c left join plsport_playsport.predict_seller d on c.id_bought = d.id
        order by buy_date desc;

        #計算各購牌位置記錄的金額
        create table plsport_playsport._buy_position engine = myisam
        select d.buyerid, d.BRC, d.BZ, d.FRND, d.FR, d.WPB, d.MPB, d.IDX, d.HT, d.US, d.NONE, 
               (d.BRC+d.BZ+d.FRND+d.FR+d.WPB+d.MPB+d.IDX+d.HT+d.US+d.NONE) as total #把所有的金額加起來
        from (
                select c.buyerid, sum(c.BRC) as BRC, sum(c.BZ) as BZ, sum(c.FRND) as FRND, sum(c.FR) as FR, 
                                  sum(c.WPB) as WPB, sum(c.MPB) as MPB, sum(c.IDX) as IDX, sum(c.HT) as HT,
                                  sum(c.US) as US, sum(c.NONE) as NONE
                from (
                        select b.buyerid, 
                               (case when (b.p = 'BRC') then spent else 0 end) as 'BRC',
                               (case when (b.p = 'BZ') then spent else 0 end) as 'BZ',
                               (case when (b.p = 'FRND') then spent else 0 end) as 'FRND',
                               (case when (b.p = 'FR') then spent else 0 end) as 'FR',
                               (case when (b.p = 'WPB') then spent else 0 end) as 'WPB',
                               (case when (b.p = 'MPB') then spent else 0 end) as 'MPB',
                               (case when (b.p = 'IDX') then spent else 0 end) as 'IDX',
                               (case when (b.p = 'HT') then spent else 0 end) as 'HT',
                               (case when (b.p = 'US') then spent else 0 end) as 'US',
                               (case when (b.p = 'NONE') then spent else 0 end) as 'NONE'
                        from (
                                select a.buyerid, a.p, sum(a.buy_price) as spent
                                from (
                                    SELECT buyerid, buy_date, buy_price,  
                                               (case when (substr(position,1,3) = 'BRC')  then 'BRC' #購買後推專
                                                     when (substr(position,1,2) = 'BZ')   then 'BZ' #購牌專區
                                                     when (substr(position,1,4) = 'FRND') then 'FRND' #明燈
                                                     when (substr(position,1,2) = 'FR')   then 'FR' #討論區
                                                     when (substr(position,1,3) = 'WPB')  then 'WPB' #勝率榜
                                                     when (substr(position,1,3) = 'MPB')  then 'MPB' #主推榜
                                                     when (substr(position,1,3) = 'IDX')  then 'IDX' #首頁
                                                     when (substr(position,1,2) = 'HT')   then 'HT' #頭三標
                                                     when (substr(position,1,2) = 'US')   then 'US' #玩家搜尋
                                                     when (position is null)              then 'NONE' else 'PROBLEM' end) as p 
                                    FROM plsport_playsport._predict_buyer_with_cons) as a
                                group by a.buyerid, a.p) as b) as c
                group by c.buyerid) as d;
        ALTER TABLE  `_buy_position` CHANGE  `buyerid`  `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';
        ALTER TABLE plsport_playsport._buy_position ADD INDEX (`buyerid`); 



create table plsport_playsport._list_1 engine = myisam
SELECT b.id, a.userid, b.nickname, a.spent_pcash 
FROM plsport_playsport._user_spent_in_three_month a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._list_2 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, b.BRC, b.BZ, b.FRND, b.FR, b.WPB, b.MPB, b.IDX, b.HT, b.US, b.NONE, b.total 
FROM plsport_playsport._list_1 a left join plsport_playsport._buy_position b on a.userid = b.buyerid;

create table plsport_playsport._list_3 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, b.us_count
FROM plsport_playsport._list_2 a left join plsport_playsport._user_use_usersearch_count b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._user_use_usersearch_platform ADD INDEX (`userid`); 

create table plsport_playsport._list_4 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_count, b.pc_pv, b.mobile_pv
FROM plsport_playsport._list_3 a left join plsport_playsport._user_use_usersearch_platform b on a.userid = b.userid;

create table plsport_playsport._list_5 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_count, a.pc_pv, a.mobile_pv,
       b.last_pay_date
FROM plsport_playsport._list_4 a left join plsport_playsport._user_spent_last_time b on a.userid = b.userid;

create table plsport_playsport._list_6 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_count, a.pc_pv, a.mobile_pv,
       date(a.last_pay_date) as last_pay_date, date(b.last_login) as last_login_date
FROM plsport_playsport._list_5 a left join plsport_playsport._last_login_time b on a.userid = b.userid
where a.us_count is not null
order by a.us_count desc;


# =================================================================================================
# 任務: 預測不佳補償機制 [新建] 2014-08-15 (福利班)
# 
# 前提：
# 
#    要瞭解殺手的多數意向
#    要瞭解消費者的多數意向
#    提出不損害公司利潤的方案
#    有結果之後，讓所有使用者知道投票結果，以及最後決定
# =================================================================================================

SELECT * FROM plsport_playsport.questionnaire_badwinningbuyersuggestions_answer;
SELECT * FROM plsport_playsport.questionnaire_badwinningsellersuggestions_answer;

create table plsport_playsport._user_total_spent engine = myisam
SELECT userid, sum(amount) as total_spent 
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1 
group by userid;

        ALTER TABLE plsport_playsport.pcash ADD INDEX (`id_this_type`); 
        ALTER TABLE plsport_playsport.predict_seller ADD INDEX (`id`); 

create table plsport_playsport._user_total_earn engine = myisam
select c.sellerid as userid, sum(c.sale_price) as total_earn
from (
    SELECT a.userid, a.amount, b.sellerid, b.sale_price 
    FROM plsport_playsport.pcash_log a left join plsport_playsport.predict_seller b on a.id_this_type = b.id
    where a.payed = 1 and a.type = 1) as c
where c.sellerid is not null
group by c.sellerid;

        ALTER TABLE plsport_playsport._user_total_earn ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._user_total_spent ADD INDEX (`userid`); 

create table plsport_playsport._user_spent_and_earn engine = myisam
select c.id, c.userid, c.nickname, c.createon, c.total_spent, d.total_earn
from (
    SELECT a.id, a.userid, a.nickname, a.createon, b.total_spent
    FROM plsport_playsport.member a left join plsport_playsport._user_total_spent b on a.userid = b.userid) as c
    left join plsport_playsport._user_total_earn as d on c.userid = d.userid
where c.total_spent is not null or d.total_earn is not null;

        ALTER TABLE plsport_playsport._user_spent_and_earn ADD INDEX (`userid`); 

# (1)殺手
create table plsport_playsport._qu_seller_answer engine = myisam
SELECT a.userid, b.nickname, date(b.createon) as createon, date(a.write_time) as write_time, b.total_spent, b.total_earn, a.spend_minute, 
       a.question01, a.question02, a.question03, a.question04, a.question05, a.question06, a.question07
FROM plsport_playsport.questionnaire_badwinningsellersuggestions_answer a left join plsport_playsport._user_spent_and_earn b on a.userid = b.userid
where spend_minute > 0.5
order by question07 desc;

# (2)消費者
create table plsport_playsport._qu_buyer_answer engine = myisam
SELECT a.userid, b.nickname, date(b.createon) as createon, date(a.write_time) as write_time, b.total_spent, b.total_earn, a.spend_minute, 
       a.question01, a.question02, a.question03, a.question04, a.question05, a.question06, a.question07
FROM plsport_playsport.questionnaire_badwinningbuyersuggestions_answer a left join plsport_playsport._user_spent_and_earn b on a.userid = b.userid
where spend_minute > 0.5
order by question07 desc;



# =================================================================================================
# 任務: [201407-F-1] 即時比分APP使用者訪談 - 訪談名單 [新建] 2014-08-25 (阿達)
# 說明
# 請提供訪談名單，供文婷約訪
# 時間：8/27 (三) 
# 訪談名單
# 1. 統計區間
# 2014/5/21起
# 2. 篩選條件
# 有點選過 iOS或Android即時比分APP版標廣告的使用者
# 3. 資料欄位
#        帳號、暱稱、手機系統( Android or iOS)、最近登入時間、版標點選天數、版標點選次數、即時比分問卷評價、
#        即時比分網頁版pv、手機/電腦使用比率、居住地
# =================================================================================================

create table actionlog._action_201405 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201405 where userid <> '' and date(time) between '2014-05-21' and '2014-05-30';
create table actionlog._action_201406 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201406 where userid <> '';
create table actionlog._action_201407 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201407 where userid <> '';
create table actionlog._action_201408 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201408 where userid <> '';
create table actionlog._action_201409 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201409_28 where userid <> '';

# (1)先把網頁版即時比分的pv捉出: _action_livescore
create table actionlog._action_livescore engine = myisam SELECT * FROM actionlog._action_201405 where uri like '%livescore.php%';
insert ignore into actionlog._action_livescore select * from actionlog._action_201406 where uri like '%livescore.php%';
insert ignore into actionlog._action_livescore select * from actionlog._action_201407 where uri like '%livescore.php%';
insert ignore into actionlog._action_livescore select * from actionlog._action_201408 where uri like '%livescore.php%';
insert ignore into actionlog._action_livescore select * from actionlog._action_201409 where uri like '%livescore.php%';

# 1
create table actionlog._action_livescore_0 engine = myisam
SELECT * FROM actionlog._action_livescore
where date(time) between '2014-06-28' and '2014-09-28'; # 近3個月

# 2
create table actionlog._action_livescore_1 engine = myisam
select a.userid, a.devices, count(a.userid) as c
from (
    SELECT userid, (case when (platform_type<2) then 'desktop_pv' else 'mobile_pv' end) as devices
    FROM actionlog._action_livescore_0) as a
group by a.userid, a.devices;

# 3
create table actionlog._action_livescore_2 engine = myisam
select a.userid, sum(a.desktop_pv) as desktop_pv, sum(a.mobile_pv) as mobile_pv
from (
    SELECT userid, (case when (devices='desktop_pv') then c else 0 end) as desktop_pv, 
                   (case when (devices='mobile_pv') then c else 0 end) as mobile_pv
    FROM actionlog._action_livescore_1) as a
group by a.userid;

# 4
create table actionlog._action_livescore_3 engine = myisam
SELECT userid, desktop_pv, mobile_pv, round(desktop_pv/(desktop_pv+mobile_pv),2) as desktop_p, 
                                      round(mobile_pv/(desktop_pv+mobile_pv),2) as mobile_p
FROM actionlog._action_livescore_2;


# (2)再處理購牌位置rp=
create table actionlog._action_rp engine = myisam SELECT * FROM actionlog._action_201405 where uri like '%rp=%';
insert ignore into actionlog._action_rp select * from actionlog._action_201406 where uri like '%rp=%';
insert ignore into actionlog._action_rp select * from actionlog._action_201407 where uri like '%rp=%';
insert ignore into actionlog._action_rp select * from actionlog._action_201408 where uri like '%rp=%';
insert ignore into actionlog._action_rp select * from actionlog._action_201409 where uri like '%rp=%';

create table actionlog._action_rp_0 engine = myisam
SELECT * FROM actionlog._action_rp
where date(time) between '2014-06-28' and '2014-09-28';

create table actionlog._action_rp_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri, locate('rp=',uri)+3, length(uri)) as rp
FROM actionlog._action_rp_0;

create table actionlog._action_rp_2 engine = myisam
SELECT userid, uri, time, platform_type, rp
FROM actionlog._action_rp_1
where substr(rp,1,3) in ('MSA','MSI'); # 只要即時比分就好了

create table actionlog._action_rp_3 engine = myisam
select d.userid, d.title_hit_android, d.title_hit_ios, (d.title_hit_android+d.title_hit_ios) as title_hit_total
from (
    select c.userid, sum(c.android) as title_hit_android, sum(c.ios) as title_hit_ios
    from (
        select b.userid, (case when (b.device='A') then c else 0 end) as android, (case when (b.device='I') then c else 0 end) as ios
        from (
            select a.userid, a.device, count(a.userid) as c
            from (
                SELECT userid, platform_type, substr(rp,1,3) as rp, substr(rp,3,1) as device
                FROM actionlog._action_rp_2) as a
            group by a.userid, a.device) as b) as c
    group by c.userid) as d;

create table actionlog._action_rp_3_hit_days engine = myisam
select b.userid, count(b.d) as hit_days
from (
    select a.userid, a.d, count(a.userid) as c
    from (
        SELECT userid, date(time) as d 
        FROM actionlog._action_rp_2) as a
    group by a.userid, a.d) as b
group by b.userid;


# (3)取得問券中使用者對即時比分的評價
create table plsport_playsport._livescore_score engine = myisam
SELECT userid, livescore_score, livescore_improve
FROM plsport_playsport.satisfactionquestionnaire_answer
where livescore_notused = 0;

# (4)產生_city_info_ok_with_chinese居住地資訊, 用之前的SQL

# (5)最後一次登入的時間
create table plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
group by userid;

        ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._livescore_score ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_rp_3_hit_days ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_rp_3 ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_livescore_3 ADD INDEX (`userid`);

create table plsport_playsport._list1 engine = myisam
select c.id, c.userid, c.nickname, c.title_hit_android, c.title_hit_ios, c.title_hit_total, d.livescore_score, d.livescore_improve
from (
    SELECT b.id, b.userid, b.nickname, a.title_hit_android, a.title_hit_ios, a.title_hit_total
    FROM actionlog._action_rp_3 a left join plsport_playsport.member b on a.userid = b.userid) as c 
    left join plsport_playsport._livescore_score as d on c.userid = d.userid;

create table plsport_playsport._list2 engine = myisam
select c.id, c.userid, c.nickname, c.last_signin, c.title_hit_android, c.title_hit_ios, c.title_hit_total, d.hit_days ,c.livescore_score, c.livescore_improve
from (
    SELECT a.id, a.userid, a.nickname, date(b.last_signin) as last_signin, 
           a.title_hit_android, a.title_hit_ios, a.title_hit_total, a.livescore_score, a.livescore_improve
    FROM plsport_playsport._list1 a left join plsport_playsport._last_signin b on a.userid = b.userid) as c
    left join actionlog._action_rp_3_hit_days as d on c.userid = d.userid;

# 完成
create table plsport_playsport._list3 engine = myisam
select c.id, c.userid, c.nickname, c.last_signin, c.title_hit_android, c.title_hit_ios, c.title_hit_total, c.hit_days, 
       c.desktop_pv, c.mobile_pv, c.desktop_p, c.mobile_p, d.city1, c.livescore_score, c.livescore_improve
from (
    SELECT a.id, a.userid, a.nickname, a.last_signin, a.title_hit_android, a.title_hit_ios, a.title_hit_total, a.hit_days, 
           b.desktop_pv, b.mobile_pv, b.desktop_p, b.mobile_p, a.livescore_score, a.livescore_improve
    FROM plsport_playsport._list2 a left join actionlog._action_livescore_3 b on a.userid = b.userid) as c
    left join plsport_playsport._city_info_ok_with_chinese as d on c.userid = d.userid;




# =================================================================================================
# 任務: [201403-D-19]購牌專區改版-ABtesting [新建] (靜怡) 2014-09-03
# 說明
# 目的：了解排序功能是否吸引使用者
# 目標：提升整體業績
# 
# 內容:
# - 測試時間：8/6~8/27
# - 使用兩個版本，原版(A)與原版加上排序功能(B)
# - 設定測試組別
# - 觀察指標：整體業績與排序功能點擊
# - 報告時間：9/4
# =================================================================================================


create table actionlog._action_201408_buy_predict engine = myisam
SELECT * FROM actionlog._action_201408
where uri like '%buy_predict%'
and userid <> ''
and time between '2014-08-06 14:00:00' and '2014-08-27 23:59:59';


create table actionlog._action_201408_buy_predict_1 engine = myisam
SELECT userid, uri, time, (case when (locate("sort=", uri)>0) then substr(uri, locate("sort=", uri), length(uri)) else "" end) as sort, 
                          (case when (locate("killertype=", uri)>0) then substr(uri, locate("killertype=", uri), length(uri)) else "" end) as killertype
FROM actionlog._action_201408_buy_predict;

create table actionlog._action_201408_buy_predict_2 engine = myisam
SELECT userid, uri, time, sort, (case when (locate("&",killertype)>0) then substr(killertype, 1,locate("&",killertype)-1) else "" end) as killertype
FROM actionlog._action_201408_buy_predict_1;


create table actionlog._action_201408_buy_predict_click_sort engine = myisam
SELECT * FROM actionlog._action_201408_buy_predict_2
where sort <> "";


# 單純看各排序sort的點擊次數
SELECT sort, killertype, count(userid) as c 
FROM actionlog._action_201408_buy_predict_click_sort
group by sort, killertype;

# 接受測試的人有多少人? 1566人
select count(a.userid)
from (
    SELECT userid, count(userid) as c
    FROM actionlog._action_201408_buy_predict_2
    where uri like '%buy_predict_b.php%'
    group by userid) as a;

select count(a.userid)
from (
    SELECT userid, count(userid) as c 
    FROM actionlog._action_201408_buy_predict_click_sort
    where sort = 'sort=6'
    and killertype = 'killertype=singlekiller'
    group by userid) as a;

# 有多少人點過排序? 573人
select count(a.userid)
from (
    SELECT userid, count(userid) as c 
    FROM actionlog._action_201408_buy_predict_click_sort
    where sort is not null
    group by userid) as a;


create table plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT buyerid, sellerid, buy_date, buy_price, position 
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-08-06 14:00:00' and '2014-08-27 23:59:59';


create table plsport_playsport._predict_buyer_with_cons_2 engine = myisam
select c.g, (case when (c.g in (8,9,10,11,12,13)) then 'A' else 'B' end) as abtest ,c.userid, c.sellerid, c.buy_date, c.buy_price, c.position
from (
    SELECT (b.id%20)+1 as g, b.userid, a.sellerid, a.buy_date, a.buy_price, a.position 
    FROM plsport_playsport._predict_buyer_with_cons_1 a left join plsport_playsport.member b on a.buyerid = b.userid) as c;

# 全站消費者的abtesting
create table plsport_playsport._list_all engine = myisam
SELECT abtest, userid, sum(buy_price) as spent 
FROM plsport_playsport._predict_buyer_with_cons_2
group by abtest, userid;

# 只在購牌專區消費者的abtesting
create table plsport_playsport._list_BZ_area engine = myisam
SELECT abtest, userid, sum(buy_price) as spent 
FROM plsport_playsport._predict_buyer_with_cons_2
where substr(position,1,3) = 'BZ_'
group by abtest, userid;

# 在購牌專區消費者的全站消費金額abtesting (2014-09-05會議後補充)
create table plsport_playsport._list_BZ_area_with_all engine = myisam
SELECT a.abtest, a.userid, a.spent as spent_bz, b.spent as spent_all
FROM plsport_playsport._list_bz_area a left join plsport_playsport._list_all b on a.userid = b.userid;


# =================================================================================================
# 任務: 30倍亮單活動成效分析 [新建] (福利班)
# 
# 7/31~8/13 於討論區進行亮單活動，請協助瞭解活動期間，亮單文章數是否增加，以便決定是否持續執行
# 比較時間：7/31~8/13  活動期間 
#           8/14~27 未執行活動期間
# 比較對象：討論區各聯盟的亮單文數量，只要有標上「亮單」標籤的文章就是了。
# 
# 期望能有結果時間： 9/3 
# 1. 活動網址
# 2. 亮單變化會以(1)各聯盟 (2)全討論 來統計
# =================================================================================================

create table plsport_playsport._forum_gametype3 engine = myisam
SELECT subjectid, forumtype, allianceid, gametype, postuser, date(posttime) as posttime
FROM plsport_playsport.forum
where date(posttime) between '2014-07-31' and '2014-08-27'
and gametype = 3;

create table plsport_playsport._forum_gametype_all engine = myisam
SELECT subjectid, forumtype, allianceid, gametype, postuser, date(posttime) as posttime
FROM plsport_playsport.forum
where date(posttime) between '2014-07-31' and '2014-08-27';

SELECT posttime, allianceid, count(subjectid) as post_count 
FROM plsport_playsport._forum_gametype3
group by posttime, allianceid;

SELECT posttime, allianceid, count(subjectid) as post_count 
FROM plsport_playsport._forum_gametype_all
group by posttime, allianceid;


# =================================================================================================
# 任務: 2014年亞運販售殺手人選 [新建] (福利班) 2014-09-10
# 
# 需求時間：9/12 
# 
# 殺手條件：請參考
# 亞運籃球：
#     50名，
#     當過中籃or 韓籃or 日籃殺手 (94,92,97)
#     近六期評選勝率曾達70%以上
# 亞運棒球：
#     50名，
#     當過中職or 日棒 or 韓棒殺手 (6,2,9)
#     近六期評選勝率曾達70%以上
# 
# =================================================================================================

create table plsport_playsport._medal_fire_baseball_twn engine = myisam
SELECT * FROM plsport_playsport.medal_fire
where vol >119 
and allianceid in (6,2,9)
and winpercentage > 69
and mode = 1
order by vol desc;

create table plsport_playsport._medal_fire_baseball_int engine = myisam
SELECT * FROM plsport_playsport.medal_fire
where vol >119 
and allianceid in (6,2,9)
and winpercentage > 69
and mode = 2
order by vol desc;

# 抽出中籃
create table plsport_playsport._medal_fire_basketball_int_94 engine = myisam
SELECT * FROM plsport_playsport.medal_fire
where vol in (113,112,111,110,109,108)
and allianceid in (94)
and winpercentage > 69
and mode = 2
order by vol desc;

# 抽出韓籃
create table plsport_playsport._medal_fire_basketball_int_92 engine = myisam
SELECT * FROM plsport_playsport.medal_fire
where vol in (114,113,112,111,110,109)
and allianceid in (92)
and winpercentage > 69
and mode = 2
order by vol desc;

# 抽出日籃
create table plsport_playsport._medal_fire_basketball_int_97 engine = myisam
SELECT * FROM plsport_playsport.medal_fire
where vol in (116,115,114,113,112,111)
and allianceid in (97)
and winpercentage > 69
and mode = 2
order by vol desc;

# merge3個籃球聯盟
create table plsport_playsport._medal_fire_basketball_int engine = myisam select * from plsport_playsport._medal_fire_basketball_int_94;
insert ignore into plsport_playsport._medal_fire_basketball_int select * from plsport_playsport._medal_fire_basketball_int_92;
insert ignore into plsport_playsport._medal_fire_basketball_int select * from plsport_playsport._medal_fire_basketball_int_97;

# 候選名單(亞籃殺手)
create table plsport_playsport._medal_fire_basketball_int_ok engine = myisam
select * 
from (
    SELECT userid, nickname, count(userid) as killer_count, round(avg(winpercentage),0) as avg_win, round(avg(winearn),1) as avg_earn
    FROM plsport_playsport._medal_fire_basketball_int
    group by userid, nickname) as a
order by a.killer_count desc, a.avg_win desc, a.avg_earn desc;

# 候選名單(亞棒殺手-國際)
create table plsport_playsport._medal_fire_baseball_int_ok engine = myisam
select * 
from (
    SELECT userid, nickname, count(userid) as killer_count, round(avg(winpercentage),0) as avg_win, round(avg(winearn),1) as avg_earn
    FROM plsport_playsport._medal_fire_baseball_int
    group by userid, nickname) as a
order by a.killer_count desc, a.avg_win desc, a.avg_earn desc;

# 候選名單(亞棒殺手-運彩)
create table plsport_playsport._medal_fire_baseball_twn_ok engine = myisam
select * 
from (
    SELECT userid, nickname, count(userid) as killer_count, round(avg(winpercentage),0) as avg_win, round(avg(winearn),1) as avg_earn
    FROM plsport_playsport._medal_fire_baseball_twn
    group by userid, nickname) as a
order by a.killer_count desc, a.avg_win desc, a.avg_earn desc;


# 禁售名單
# 本尊
create table plsport_playsport._block_list1 engine = myisam
SELECT master_userid as userid 
FROM plsport_playsport.sell_deny
where date(time) between '2014-09-07' and '2014-09-21';
# 分身
insert ignore into plsport_playsport._block_list1 
SELECT slave_userid as userid FROM plsport_playsport.sell_deny;
# 本尊+分身 then remove duplicate userid
create table plsport_playsport._block_list engine = myisam
SELECT userid
FROM plsport_playsport._block_list1
group by userid;

drop table plsport_playsport._block_list1;

# 候選名單(亞棒殺手-國際)
SELECT * 
FROM plsport_playsport._medal_fire_baseball_int_ok a left join plsport_playsport._block_list b on a.userid = b.userid
where b.userid is null;

# 候選名單(亞棒殺手-運彩)
SELECT * 
FROM plsport_playsport._medal_fire_baseball_twn_ok a left join plsport_playsport._block_list b on a.userid = b.userid
where b.userid is null;

# 候選名單(亞籃殺手)
SELECT * 
FROM plsport_playsport._medal_fire_basketball_int_ok a left join plsport_playsport._block_list b on a.userid = b.userid
where b.userid is null;




# =================================================================================================
# 任務: 發文推點擊偵測 [新建] (靜怡)
# 
# 說明
# 目的：了解發文內的兩個推按鍵點擊狀況
# 
# 內容
# - 偵測時間：8/28~9/1
# - 資料表紀錄在 資料庫中的 go_top_or_latest_log
# - 上面的推文值是 pushit_top，下面的推文值是 pushit_bottom
# - 報告需求：100人中有多少比列會點擊
# - 報告時間：9/4
# =================================================================================================

create table actionlog._action_201409_05 engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201409_05;

# 主要資料(1) 8月
create table actionlog._forumdetail_click engine = myisam
SELECT * FROM actionlog._action_201408
where userid <> ''
and date(time) between '2014-08-22' and '2014-08-31'
and uri like '%forumdetail%';
# 主要資料(2) 9月
insert ignore into actionlog._forumdetail_click
SELECT * FROM actionlog._action_201409_05
where userid <> ''
and date(time) between '2014-09-01' and '2014-09-05'
and uri like '%forumdetail%';

# 每天有在看文章內頁的人數
select b.d, count(b.userid) as user_count
from (
    select a.d, a.userid, count(userid) as c
    from (
        SELECT userid, uri, date(time) as d 
        FROM actionlog._forumdetail_click) as a
    group by a.d, a.userid) as b
group by b.d;

# 每天各點擊的情況統計(要自行更換以下行為代碼)
select b.d, count(b.userid) as user_count
from (
    select a.d, a.userid, a.click, count(userid) as c
    from (
        SELECT userid, click, date(log_time) as d
        FROM plsport_playsport.go_top_or_latest_log
        where userid <> ''
        and click = 'pushit_top' #<-替換這個
         ) as a
    group by a.d, a.userid, a.click) as b
group by b.d;

# #latest
# #top
# pushit_bottom
# pushit_top



# =================================================================================================
# 任務: 2014/09儲值優惠活動-成效分析 [新建] (柔雅) 2014-09-16
# 
# TO: eddy
# 
# 9月儲值優惠活動已結束，以下幾項數據，煩請你提供分析
# 
# 活動期間:9/9 12:00- 9/10 12:00
# 1.活動期間的業績總額(總儲值金額)
# 2.活動參與人數
# 3.金額分佈: 每個價格有多少筆數、有多少人購買該價格
# 4.網站廣告點及成效分析(已開任務)
# 5.三個月後，分析有得到優惠的消費者的arpu，是否較沒有得到優惠的使用者高
# (可以參考4/1號的任務)
# 
# 先完成1-4項，第5項三個月後再報告，
# 
# 完成日期，在麻煩你押個時間給我，感謝!
# =================================================================================================

# 購買預測
SELECT sum(amount)
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between '2014-09-09 12:00:00' and '2014-09-10 11:59:59';

# 儲值噱幣
SELECT sum(amount)
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and date between '2014-09-09 12:00:00' and '2014-09-10 11:59:59'
and amount > 998;

# 購買預測-前後幾天
select a.d, sum(amount) as spent
from (
    SELECT userid, amount, date(date) as d
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1
    and date(date) between '2014-08-31' and '2014-09-15') as a
group by a.d;

# 儲值噱幣-前後幾天
select a.d, sum(amount) as spent
from (
    SELECT userid, amount, date(date) as d
    FROM plsport_playsport.pcash_log
    where payed = 1 and type in (3,4)
    and date(date) between '2014-08-31' and '2014-09-15') as a
group by a.d;

# 儲值噱幣
SELECT userid, count(amount) as redeem_count, sum(amount) as redeem_total
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and amount > 998
and date between '2014-09-09 12:00:00' and '2014-09-10 11:59:59'
group by userid;

create table actionlog.action_201409_activity_php engine = myisam
SELECT * FROM actionlog.action_201409_14
where uri like '%action=buypcash%';

SELECT * FROM actionlog.action_201409_activity_php
order by id desc;

create table actionlog.action_201409_activity_php_1 engine = myisam
SELECT userid, uri, time, 
       (case when (locate('from=',uri)=0) then '' else substr(uri,locate('from=',uri)+5, length(uri)) end) as p
FROM actionlog.action_201409_activity_php;


# 柔雅2014-09-19補充的需求
select a.payway, a.platform_type, sum(a.price) as revenue #收益金額
from (
    SELECT userid, createon, ordernumber, price, payway, create_from, platform_type 
    FROM plsport_playsport.order_data
    where createon between '2014-09-09 12:00:00' and '2014-09-10 11:59:59'
    and sellconfirm = 1
    and create_from = 8) as a
group by a.payway, a.platform_type;

select a.payway, a.platform_type, count(a.price) as revenue #付款人數
from (
    SELECT userid, createon, ordernumber, price, payway, create_from, platform_type 
    FROM plsport_playsport.order_data
    where createon between '2014-09-09 12:00:00' and '2014-09-10 11:59:59'
    and sellconfirm = 1
    and create_from = 8) as a
group by a.payway, a.platform_type;


#-----------------------------------------------------
# to EDDY
#
# 麻煩你提供  9/9 12:00-9/10 12:00  與 4/1 0:00-24:00，
# 這兩個時段內的儲值金額分佈，
# 目地:想比較，活動時間不同，是否對活動的成效有影響。
# 煩請在下週大會之前完成，在大會上要報告。
#-----------------------------------------------------

# (1)
create table plsport_playsport._order_data_first_discount engine = myisam
SELECT userid, createon, price 
FROM plsport_playsport.order_data
where payway in (1,2,3,4,5,6)
and sellconfirm = 1
and date(createon) between '2014-03-30' and '2014-04-05';

create table plsport_playsport._order_data_second_discount engine = myisam
SELECT userid, createon, price 
FROM plsport_playsport.order_data
where payway in (1,2,3,4,5,6)
and sellconfirm = 1
and date(createon) between '2014-09-07' and '2014-09-13';

select a.d, a.h, sum(a.price) as redeem
from (
    SELECT userid, date(createon) as d, hour(createon) as h, price 
    FROM plsport_playsport._order_data_first_discount) a
group by a.d, a.h;

select a.d, a.h, sum(a.price) as redeem
from (
    SELECT userid, date(createon) as d, hour(createon) as h, price 
    FROM plsport_playsport._order_data_second_discount) a
group by a.d, a.h;




# =================================================================================================
# 任務: [201407-B-3]強化討論區回文功能-測試名單撈取 [新建] (靜怡)
# 
# 說明
# 提供討論區回文測試名單
#  
# 負責人：Eddy
# 
# 內容
# 條件
# -D1~D5
# - 時間區間：一個月
# 
# -欄位：暱稱、ID、分群、討論區PV、電腦與手機使用比率、最近登入時間、居住地、發回文數、推數
# =================================================================================================

create table actionlog.action_201408_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201408
where uri like '%forum%';

create table actionlog.action_201409_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201409
where uri like '%forum%';

create table actionlog.action_201410_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_20141012
where uri like '%forum%';


create table actionlog.action_forum engine = myisam
SELECT * 
FROM actionlog.action_201409_forum
where userid <> '';

insert ignore into actionlog.action_forum 
select * from actionlog.action_201410_forum
where userid  <> '';

create table actionlog.action_forum_1 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as platform_type
FROM actionlog.action_forum
where date(time) between '2014-09-11' and  '2014-10-12'
and substr(uri,1,6) = '/forum';

drop table actionlog.action_201408_forum;
drop table actionlog.action_201409_forum;
drop table actionlog.action_201410_forum;
drop table actionlog.action_forum;

# 區間設定在between '2014-08-14' and  '2014-09-14'

# (1) 討論區pv
create table actionlog.action_forum_pv engine = myisam 
SELECT userid, count(uri) as forum_pv 
FROM actionlog.action_forum_1
group by userid;

# (2) 討論區使用裝置佔比
create table actionlog.action_forum_device_pv engine = myisam
select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
from (
    SELECT userid, (case when (platform_type = 'pc') then 1 else 0 end) as pc, 
                   (case when (platform_type = 'mobile') then 1 else 0 end) as mobile
    FROM actionlog.action_forum_1) as a
group by a.userid;

create table actionlog.action_forum_device_pv_1 engine = myisam
SELECT userid, pc, mobile, round((pc/(pc+mobile)),2) as pc_p, round((mobile/(pc+mobile)),2) as mobile_p
FROM actionlog.action_forum_device_pv;

drop table actionlog.action_forum_device_pv;
rename table actionlog.action_forum_device_pv_1 to actionlog.action_forum_device_pv;

# (3) po文數
create table plsport_playsport._post_count engine = myisam 
select a.postuser as userid, count(a.subjectid) as post
from (
    SELECT subjectid, postuser, posttime 
    FROM plsport_playsport.forum
    where date(posttime) between '2014-09-11' and '2014-10-12') as a
group by a.postuser;

# (4) 回文數
create table plsport_playsport._reply_count engine = myisam
SELECT userid, count(subjectid) as reply
FROM plsport_playsport.forumcontent
where date(postdate) between '2014-09-11' and '2014-10-12'
group by userid;

# (5) 推數
create table plsport_playsport._like_count engine = myisam
SELECT userid, count(subject_id) as like_c
FROM plsport_playsport.forum_like
where date(create_date) between '2014-09-11' and '2014-10-12'
group by userid;

# (6) 最後一次登入
create table plsport_playsport._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
group by userid;

# (7) 居住地
# 找code line 1708: _city_info_ok_with_chinese

    ALTER TABLE actionlog.action_forum_pv CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
    ALTER TABLE actionlog.action_forum_device_pv CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
    ALTER TABLE plsport_playsport._like_count CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
    ALTER TABLE plsport_playsport._reply_count CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

    ALTER TABLE actionlog.action_forum_pv ADD INDEX (`userid`);
    ALTER TABLE actionlog.action_forum_device_pv ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._post_count ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._reply_count ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._like_count ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);


create table plsport_playsport._list_1 engine = myisam
select c.userid, c.nickname, c.forum_pv, d.pc, d.mobile, d.pc_p, d.mobile
from (
    SELECT a.userid, b.nickname, a.forum_pv
    FROM actionlog.action_forum_pv a left join plsport_playsport.member b on a.userid = b.userid) as c
    left join actionlog.action_forum_device_pv as d on c.userid = d.userid;

create table plsport_playsport._list_2 engine = myisam
SELECT a.userid, a.nickname, b.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p
FROM plsport_playsport._list_1 a left join user_cluster.cluster_with_real_userid b on a.userid = b.userid;

    ALTER TABLE plsport_playsport._list_2 ADD INDEX (`userid`);

create table plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, b.last_time_login
FROM plsport_playsport._list_2 a left join plsport_playsport._last_time_login b on a.userid = b.userid;

    ALTER TABLE plsport_playsport._list_3 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);

create table plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, b.city1
FROM plsport_playsport._list_3 a left join plsport_playsport._city_info_ok_with_chinese b on a.userid = b.userid;


create table plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, a.city1, b.post 
FROM plsport_playsport._list_4 a left join plsport_playsport._post_count b on a.userid = b.userid;

create table plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, a.city1, a.post, b.reply
FROM plsport_playsport._list_5 a left join plsport_playsport._reply_count b on a.userid = b.userid;

create table plsport_playsport._list_7 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, a.city1, a.post, a.reply, b.like_c
FROM plsport_playsport._list_6 a left join plsport_playsport._like_count b on a.userid = b.userid;

drop table plsport_playsport._list_1, plsport_playsport._list_2, plsport_playsport._list_3;
drop table plsport_playsport._list_4, plsport_playsport._list_5, plsport_playsport._list_6;

# 名單
SELECT * FROM plsport_playsport._list_7;

# =================================================================================================
# 任務: [201408-A-4]開發回文推功能-推數級距統計 [新建] (靜怡)
# 
# 說明
#  
# 目的：了解推數狀況，訂定發回文推數的級距
#  
# 內容
# - 統計站上推數佔比，如獲得10推文章佔站上多少比例
# - 統計時間：請EDDY設定
# =================================================================================================

create table plsport_playsport._forum engine = myisam
SELECT subjectid, allianceid, postuser, posttime, year(posttime) as y, replycount, pushcount 
FROM plsport_playsport.forum
where allianceid in (1,2,3,4,6,9,91)
order by posttime desc;

SELECT y, allianceid, count(subjectid) as post_count
FROM plsport_playsport._forum
where y >2012
group by y, allianceid;

SELECT y, allianceid, count(subjectid) as post_count
FROM plsport_playsport._forum
where y > 2012
and pushcount > 35
group by y, allianceid;


# =================================================================================================
# 任務: 討論區升級數據 [新建] (學文) 2014-09-22
# 
# 麻煩您撈取
# 
# 1.近一年的文章推數及回覆數的分佈
# 2.分析文篇數的分布(以寫過分析文的人為對象)
# 3.以寫過分析文的人為對象中，被選為最讚分析文次數的分布，以及成為優質分析王次數的分布
# 4.亮單文篇數的分布(以發表過的人為對象)
# 5.live文篇數的分布(以發表過的人為對象)
# =================================================================================================

create table plsport_playsport._forum engine = myisam
SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount
FROM plsport_playsport.forum
where date(posttime) between '2013-09-13' and '2014-09-15'
order by posttime desc;

        create table plsport_playsport._forum engine = myisam
        SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount
        FROM plsport_playsport.forum
        where date(posttime) between '2014-08-15' and '2014-09-15'
        order by posttime desc;

# 回文數的分佈
create table plsport_playsport._forum_replycount_one_month engine = myisam
SELECT replycount, count(subjectid) as c 
FROM plsport_playsport._forum
group by replycount;

# 推文數的分佈
create table plsport_playsport._forum_pushocunt_one_month engine = myisam
SELECT pushcount, count(subjectid) as c 
FROM plsport_playsport._forum
group by pushcount;

    select 'pushcount', 'c' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_pushocunt_one_month.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_pushocunt_one_month);

    select 'pushcount', 'c' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_pushocunt_one_year.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_pushocunt_one_year);

    select 'replycount', 'c' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_replycount_one_month.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_replycount_one_month);

    select 'replycount', 'c' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_replycount_one_year.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_replycount_one_year);

# (學文)
# 分析文的篇數是捉forum裡的gametype=1
# 最讚分析文是analysis_king
# 優質分析王是honorboard的honortype=5 (另外, 條件也是上月入選過12次最讚分析文, 當月就會當選優質分析王)

create table plsport_playsport._forum_alltime_analysis_post engine = myisam
SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount 
FROM plsport_playsport.forum
where gametype = 1;

# (1)分析文的篇數人數分佈 - 此表之後再自已匯出.csv
create table plsport_playsport._forum_alltime_analysis_post_user engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum_alltime_analysis_post
where postuser <> ''
group by postuser;

# (2)最讚分析文統計
create table plsport_playsport._analysis_king_count engine = myisam
SELECT userid, count(subjectid) as c
FROM plsport_playsport.analysis_king
group by userid;

# (3)優質分析王統計
create table plsport_playsport._permuin_analysis_king_count engine = myisam
SELECT userid, count(id) as c
FROM plsport_playsport.honorboard
where honortype = 5 #榮玉榜的記錄
group by userid;

# (4)亮單文統計
create table plsport_playsport._forum_alltime_showoff_post engine = myisam
select a.postuser, count(a.subjectid) as c
from (
    SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount 
    FROM plsport_playsport.forum
    where gametype = 3) as a #亮單文
group by a.postuser;

# (5)Live文統計
create table plsport_playsport._forum_alltime_live_post engine = myisam
select a.postuser, count(a.subjectid) as c
from (
    SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount 
    FROM plsport_playsport.forum
    where gametype = 2) as a #Live文
group by a.postuser;

create table plsport_playsport._forum_alltime_post engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum
group by postuser;


# 任務: 討論區升級數據 [新建] 2014-09-26 補充 (學文)
# to eddy
# 1.表a 近一年的回文數分布，轉換成人數(暫不做) (依原來做法改成1個月的)
# 2.表b 近一年的推文數分布，轉換成人數(暫不做) (依原來做法改成1個月的)
# 3.回文數(不用做) 、推文數(不用做)、貼文數、亮單文數、live文數，資料區間抓近一個月(用forum做, 依文章列表的資訊做的)
# 4.一個人會去按別人推的推數分布，近一個月(用forumcontent做, 依個人的行為) done
# 5.一個人會去回覆文章的回覆數分布，近一個月(用forum_like做, 依個人的行為) done 
# ps.　( 第345點，也都是以人數（非文章篇數）的方式呈現）

# _forumcontent
# _forum_like
# 以上2個表已經篩好區間'2013-09-13' and '2014-09-15'

create table plsport_playsport._forumcontent engine = myisam
SELECT subjectid, userid, postdate 
FROM plsport_playsport.forumcontent;

create table plsport_playsport._forum_like engine = myisam
SELECT subject_id, userid, create_date 
FROM plsport_playsport.forum_like;

create table plsport_playsport._reply_count_list engine = myisam
SELECT userid, count(subjectid) as reply_count 
FROM plsport_playsport._forumcontent
group by userid;

create table plsport_playsport._like_count_list engine = myisam
SELECT userid, count(subject_id) as like_count 
FROM plsport_playsport._forum_like
group by userid;

    select 'userid', 'reply_count' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_reply_count_list.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._reply_count_list);

    select 'userid', 'like_count' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_like_count_list.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._like_count_list);

create table plsport_playsport._forum engine = myisam
SELECT * FROM plsport_playsport.forum
where date(postTime) between '2014-08-15' and '2014-09-15';

create table plsport_playsport._forumcontent engine = myisam
SELECT * FROM plsport_playsport.forumcontent
where date(postdate) between '2014-08-15' and '2014-09-15';

create table plsport_playsport._forum_like engine = myisam
SELECT * FROM plsport_playsport.forum_like
where date(create_date) between '2014-08-15' and '2014-09-15';


# 貼文
create table plsport_playsport._forum_1_post_user engine = myisam
SELECT postuser, count(subjectid) as c
FROM plsport_playsport._forum
group by postuser;

# 亮單文
create table plsport_playsport._forum_1_showoff_user engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum
where gametype = 3
group by postuser;

# Live文
create table plsport_playsport._forum_1_live_user engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum
where gametype = 2
group by postuser;


    select 'postuser', 'c' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_1_post_user.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_1_post_user);

    select 'postuser', 'c' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_1_showoff_user.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_1_showoff_user);

    select 'postuser', 'c' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_1_live_user.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_1_live_user);


# =================================================================================================
# 購買後推廌專區 - 第三階段優化 ( 顯示運彩盤推薦) 2014-09-29 (阿達)
# 
# 測試時間：9/3 ~ 9/23
# 1. 提供測試名單
# 2. 測試報告
#    觀察指標為購買預測營業額、各區塊點擊/購買數 (分成殺手、非殺手)
# =================================================================================================

# 區間從9/3~9/28
create table plsport_playsport._list_1 engine = myisam
select (b.id%20)+1 as g, a.buyerid, a.buy_date, a.buy_price, a.position
from (
    SELECT buyerid, buy_date, buy_price, position 
    FROM plsport_playsport._predict_buyer_with_cons
    where date(buy_date) between '2014-09-03' and '2014-09-28') as a left join plsport_playsport.member b on a.buyerid = b.userid
where substr(a.position,1,3) = 'BRC'; #購買後推廌專區

# 分出實驗組和對照組
create table plsport_playsport._list_2 engine = myisam
SELECT (case when (g in (8,9,10,11,12,13,14)) then 'a' else 'b' end) as g, buyerid, buy_date, buy_price, position 
FROM plsport_playsport._list_1;

# 購買後推廌專區 - 各位置的收益
SELECT g, position, sum(buy_price) as revenue 
FROM plsport_playsport._list_2
group by g, position;

# 誰在購買後推廌專區消費
create table plsport_playsport._list_3_who_buy_brc engine = myisam
SELECT g, buyerid as userid, sum(buy_price) as BRC_revenue 
FROM plsport_playsport._list_2
group by g, buyerid;

# 所有人的消費
create table plsport_playsport._list_3_everyone_buy engine = myisam
SELECT buyerid, buy_date, sum(buy_price) as revenue 
FROM plsport_playsport._predict_buyer_with_cons
where date(buy_date) between '2014-09-03' and '2014-09-28'
group by buyerid;

# 在購買後推廌專區消費的人的所有消費_最後名單
create table plsport_playsport._list_4 engine = myisam
SELECT a.g as abtest, a.userid, a.BRC_revenue, b.revenue 
FROM plsport_playsport._list_3_who_buy_brc a left join plsport_playsport._list_3_everyone_buy b on a.userid = b.buyerid;

# 撈出所有brc的點擊log
create table actionlog.action_201409_28_rp_brc engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201409_28
where date(time) between '2014-09-03' and '2014-09-28'
and userid <> ''
and uri like '%rp=BRC%';

create table actionlog.action_201409_28_rp_brc_1 engine = myisam
SELECT userid, uri, time, substr(uri,locate('&rp=',uri)+4,length(uri)) as p
FROM actionlog.action_201409_28_rp_brc;

ALTER TABLE `action_201409_28_rp_brc_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog.action_201409_28_rp_brc_2 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.p
FROM actionlog.action_201409_28_rp_brc_1 a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog.action_201409_28_rp_brc_3 engine = myisam
SELECT (case when (g in (8,9,10,11,12,13,14)) then 'a' else 'b' end) as g, userid, uri, time , p
FROM actionlog.action_201409_28_rp_brc_2;

SELECT g, p, count(userid) as c 
FROM actionlog.action_201409_28_rp_brc_3
group by g, p;


# =================================================================================================
# 麻煩你協助撈取，2014年目前達到以下儲值金額，的人數有多少人: (柔雅) 2014-09-29
# 
# 1. 一萬5千元
# 2. 2萬、3萬、4萬、5萬、6萬、7萬、8萬、9萬、10萬
# 3.12萬、13萬、15萬
# 4.2014目前99.9%，那7個人的各別儲值金額
# =================================================================================================

create table plsport_playsport._order_data_2014 engine = myisam
SELECT userid, createon, price
FROM plsport_playsport.order_data
where payway in (1,2,3,4,5,6)
and sellconfirm = 1
and year(createon) = 2014;

create table plsport_playsport._order_data_2014_1 engine = myisam
SELECT userid, sum(price) as total_redeem 
FROM plsport_playsport._order_data_2014
group by userid;

SELECT count(userid)
FROM plsport_playsport._order_data_2014_1
where total_redeem >= 150000 ; # 一直更換此數字就可以了

select a.d, a.h, sum(a.price) as redeem
from (
    SELECT userid, date(createon) as d, hour(createon) as h, price 
    FROM plsport_playsport._order_data_first_discount) a
group by a.d, a.h;

select a.h, sum(a.price) as redeem
from (
    SELECT userid, date(createon) as d, hour(createon) as h, price 
    FROM plsport_playsport.order_data
    where payway in (1,2,3,4,5,6)
    and sellconfirm = 1
    and date(createon) between '2014-08-01' and '2014-09-28') as a
group by a.h;


# =================================================================================================
# 任務: [201403-D-21]購牌專區改版-購買人數ABtesting報告 [新建] (靜怡)
# 
# 說明
# 目的：了解購買人數是否吸引使用者
# 目標：提升整體業績
# 內容
#  
# - 測試時間：9/15~10/5
# - 使用兩個版本，原版(A)與原版加上購買人數(B)
# - 設定測試組別
# - 觀察指標：整體業績
# - 報告時間：10/9
# =================================================================================================

create table plsport_playsport._predict_buyer_with_cons_edited engine = myisam
SELECT buyerid, buy_date, buy_price, position 
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-09-15 15:00:00' and '2014-10-08 23:59:59';

create table plsport_playsport._predict_buyer_with_cons_edited_1 engine = myisam
SELECT (b.id%20)+1 as g, a.buyerid, a.buy_date, a.buy_price, a.position 
FROM plsport_playsport._predict_buyer_with_cons_edited a left join plsport_playsport.member b on a.buyerid = b.userid;

create table plsport_playsport._predict_buyer_with_cons_edited_2 engine = myisam
SELECT (case when (g>14) then 'a' else 'b' end) as abtest, buyerid as userid, buy_date, buy_price, position
FROM plsport_playsport._predict_buyer_with_cons_edited_1;

create table plsport_playsport._predict_buyer_with_cons_edited_3 engine = myisam
select a.abtest, a.userid, a.buy_date, a.buy_price, a.position, a.p
from (
    SELECT abtest, userid, buy_date, buy_price, position, substr(position,1,5) as p
    FROM plsport_playsport._predict_buyer_with_cons_edited_2) as a
where a.p in ('BZ_MF','BZ_SK');

create table plsport_playsport._list_1 engine = myisam
SELECT abtest, userid, sum(buy_price) as spent 
FROM plsport_playsport._predict_buyer_with_cons_edited_3
group by abtest, userid;

create table plsport_playsport._list_1_1 engine = myisam
SELECT userid, sum(buy_price) as all_spent 
FROM plsport_playsport._predict_buyer_with_cons_edited_2
group by userid;

create table plsport_playsport._list_2 engine = myisam
SELECT a.abtest, a.userid, a.spent, b.all_spent 
FROM plsport_playsport._list_1 a left join plsport_playsport._list_1_1 b on a.userid = b.userid;

    select 'abtest', 'userid', 'spent', 'all_spent' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_list_2.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._list_2);


# =================================================================================================
# 任務: [201409-A-2] NBA、冰球即時比分版型調整 - 測試名單 [新建] 2014-10-14 (阿達)
# 
# 內容
# 1. 版型測試名單
# 資料區間：10/5 ~ 10/12
# 條件：使用NBA即時比分網頁版 pv前50%使用者
# 欄位：帳號、暱稱、使用天數、pv及全站佔比( NBA即時比分)、pv及全站佔比( MLB即時比分)、
# 手機/電腦使用比率、是否已填寫問券(資料表 questionnaire_livescoreTemplate_answer )
# =================================================================================================

create table actionlog._actionlog_livescore engine = myisam 
SELECT userid, uri, time, platform_type 
FROM actionlog.action_20141012
where date(time) between '2014-10-05' and '2014-10-12'
and uri like '%/livescore.php%'
and userid <> '';

create table actionlog._actionlog_livescore_1 engine = myisam
select a.userid, a.uri, (case when (locate('&',a.p)=0) then a.p
                              else substr(a.p,1,locate('&',a.p)-1) end) as p, a.time, a.platform_type
from (
    SELECT userid, uri, substr(uri,locate('aid',uri)+4,length(uri)) as p, time, platform_type 
    FROM actionlog._actionlog_livescore) as a;

create table actionlog._actionlog_livescore_2 engine = myisam
SELECT userid, uri, (case when (p in ('1#','vescore.php')) then 1 else p end) as p, time, 
                    (case when (platform_type < 2) then 'desktop' else 'mobile' end) as platform 
FROM actionlog._actionlog_livescore_1;

create table actionlog._actionlog_livescore_3 engine = myisam
SELECT a.userid, a.uri, b.alliancename, a.time, a.platform 
FROM actionlog._actionlog_livescore_2 a left join plsport_playsport.alliance b on a.p = b.allianceid;

# (1)看即時比分的天數
create table actionlog._actionlog_livescore_3_usage_daycount_all engine = myisam
select b.userid, count(b.d) as d_count_all
from (
    select a.userid, a.d, count(userid) as c
    from (
        SELECT userid, uri, alliancename as alli_name, date(time) as d, platform 
        FROM actionlog._actionlog_livescore_3) as a
    group by a.userid, a.d) as b
group by b.userid;

# (2)看即時比分的天數-NBA
create table actionlog._actionlog_livescore_3_usage_daycount_nba engine = myisam
select b.userid, count(b.d) as d_count_nba
from (
    select a.userid, a.d, count(a.userid ) as c
    from (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        where alliancename = 'NBA') as a
    group by a.userid, a.d) as b
group by b.userid;

# (3)看即時比分的天數-MLB
create table actionlog._actionlog_livescore_3_usage_daycount_mlb engine = myisam
select b.userid, count(b.d) as d_count_mlb
from (
    select a.userid, a.d, count(a.userid) as c
    from (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        where alliancename = 'MLB') as a
    group by a.userid, a.d) as b
group by b.userid;

# (4)使用裝置的比例
create table actionlog._actionlog_livescore_3_pv_precentage engine = myisam
select c.userid, c.desktop_pv, c.mobile_pv, round((c.desktop_pv/(c.desktop_pv+c.mobile_pv)),3) as desktop_p,
                                            round((c.mobile_pv/(c.desktop_pv+c.mobile_pv)),3) as mobile_p
from (
    select b.userid, sum(b.desktop_pv) as desktop_pv, sum(b.mobile_pv) as mobile_pv
    from (
        select a.userid, (case when (a.platform='desktop') then c else 0 end) as desktop_pv,
                         (case when (a.platform='mobile')  then c else 0 end) as mobile_pv
        from (
            SELECT userid, platform, count(userid) as c 
            FROM actionlog._actionlog_livescore_3
            group by userid, platform) as a) as b
    group by b.userid) as c;

create table actionlog._actionlog_livescore_3_nba_pv engine = myisam
SELECT userid, count(userid) as nba_pv
FROM actionlog._actionlog_livescore_3
where alliancename = 'NBA'
group by userid;

        ALTER TABLE `_actionlog_livescore_3_nba_pv` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog._actionlog_livescore_3_mlb_pv engine = myisam
SELECT userid, count(userid) as mlb_pv
FROM actionlog._actionlog_livescore_3
where alliancename = 'MLB'
group by userid;

        ALTER TABLE `_actionlog_livescore_3_mlb_pv` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._list_1 engine = myisam
SELECT c.userid, c.d_count_all, c.d_count_nba, d.d_count_mlb
from (
    SELECT a.userid, a.d_count_all, b.d_count_nba
    FROM actionlog._actionlog_livescore_3_usage_daycount_all a left join actionlog._actionlog_livescore_3_usage_daycount_nba b on a.userid = b.userid) as c
    left join actionlog._actionlog_livescore_3_usage_daycount_mlb as d on c.userid = d.userid;

        ALTER TABLE `_list_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._list_2 engine = myisam
SELECT a.userid, b.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb 
FROM plsport_playsport._list_1 a left join plsport_playsport.member b on a.userid = b.userid;

        ALTER TABLE `_actionlog_livescore_3_pv_precentage` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, b.desktop_pv, b.mobile_pv, b.desktop_p, b.mobile_p
FROM plsport_playsport._list_2 a left join actionlog._actionlog_livescore_3_pv_precentage b on a.userid = b.userid;

create table plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, b.nba_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p 
FROM plsport_playsport._list_3 a left join actionlog._actionlog_livescore_3_nba_pv b on a.userid = b.userid;

create table plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, a.nba_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p, 
       (case when (b.write_time is not null) then 'yes' else '' end) as anwsered
FROM plsport_playsport._list_4 a left join plsport_playsport.questionnaire_livescoretemplate_answer b on a.userid = b.userid;

create table plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, a.nba_pv, b.mlb_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p, a.anwsered 
FROM plsport_playsport._list_5 a left join actionlog._actionlog_livescore_3_mlb_pv b on a.userid = b.userid;

create table plsport_playsport._list_7 engine = myisam
SELECT * FROM plsport_playsport._list_6
where nba_pv > 5;

# 最後名單
    select 'userid', 'nickname', 'd_count_all', 'd_count_nba', 'd_count_mlb', 'nba_pv', 'mlb_pv', 'desktop_pv', 'mobile_pv', 'desktop_p', 'mobile_p', 'anwsered' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_list_7.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._list_7);


# =================================================================================================
# 任務: [201408-A-4]開發回文推功能-發文推ABtesting [新建] 2014-10-14 (靜怡)
# 
# 說明
#  
# 了解移除發文上方的推按鍵，是否會對推數有影響
# 內容
# - 測試時間：10/13~10/23
# - 設定測試組別
# - 觀察指標：發文推數
# - 報告時間：11/4
# =================================================================================================

# 檢查程序 2014-10-15
# ---------------------------------------------------------------------
SELECT * 
FROM plsport_playsport.go_top_or_latest_log
order by id desc;
# 看起來go_top_or_latest_log已經沒有在運作了, 最後一天到9月2日
# 2014-10-14下午已經又打開了

create table plsport_playsport._go_top_or_latest_log engine = myisam
SELECT * FROM plsport_playsport.go_top_or_latest_log
where month(log_time) = 10 ; # 只檢查10月份的

# 檢查表 (實驗組為: 1,2,3,4,5,6,7,8,9,10)
select c.g, c.click, count(c.userid) as c
from (
    SELECT (b.id%20)+1 as g, a.userid, a.click, a.log_time 
    FROM plsport_playsport._go_top_or_latest_log a left join plsport_playsport.member b on a.userid = b.userid) as c
group by c.g, c.click;
# ---------------------------------------------------------------------

# abtesting報告 2014-11-03

create table plsport_playsport._go_top_or_latest_log engine = myisam
SELECT * 
FROM plsport_playsport.go_top_or_latest_log
where date(log_time) between '2014-10-13' and '2014-10-23'
order by id ;

create table plsport_playsport._go_top_or_latest_log_1 engine = myisam
SELECT userid, click, count(userid) as click_count 
FROM plsport_playsport._go_top_or_latest_log
group by userid, click;

create table plsport_playsport._go_top_or_latest_log_2 engine = myisam
select (case when (c.g<11) then 'a' else 'b' end) as abtest, c.userid, c.click, c.click_count
from (
    SELECT (b.id%20)+1 as g, a.userid, a.click, a.click_count
    FROM plsport_playsport._go_top_or_latest_log_1 a left join plsport_playsport.member b on a.userid = b.userid) as c;

# 查詢按推的人數
SELECT abtest, click, sum(click_count)  
FROM plsport_playsport._go_top_or_latest_log_2
group by abtest, click;

select a.abtest, count(a.userid) as c
from (
    SELECT abtest, userid, count(click) as c 
    FROM plsport_playsport._go_top_or_latest_log_2
    group by abtest, userid) as a
group by a.abtest;

create table plsport_playsport._go_top_or_latest_log_3 engine = myisam
SELECT abtest, userid, sum(click_count) as c   
FROM plsport_playsport._go_top_or_latest_log_2
group by abtest, userid;

# 輸出txt給R作abtesting
SELECT 'abtest', 'userid', 'c' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_go_top_or_latest_log_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._go_top_or_latest_log_3);


        create table actionlog._forumdetail engine = myisam
        SELECT userid, uri, time
        FROM actionlog.action_20141025
        where uri like '%forumdetail.php%'
        and time between '2014-10-14 14:32:53' and '2014-10-23 10:00:00'
        and userid <> '';

        create table actionlog._forumdetail_1 engine = myisam
        SELECT userid, count(uri) as c 
        FROM actionlog._forumdetail
        group by userid;

        ALTER TABLE `_forumdetail_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

        create table actionlog._forumdetail_2 engine = myisam
        SELECT (b.id%20)+1 as g, a.userid, a.c
        FROM actionlog._forumdetail_1 a left join plsport_playsport.member b on a.userid = b.userid;

        create table actionlog._forumdetail_3 engine = myisam
        SELECT (case when (g<11) then 'a' else 'b' end) as abtest, userid, c 
        FROM actionlog._forumdetail_2;

        SELECT abtest, count(userid) as c
        FROM actionlog._forumdetail_3
        group by abtest;


# =================================================================================================
# 任務: [201409-A-4] NBA、冰球即時比分版型調整 - 問卷報告 [新建] 2014-10-15 (阿達)
# 
# 報告問卷結果
# 10/16 版型測試問卷 
# 報告
# 
# 1. 版型測試問卷
# 資料表：questionnaire_livescoreTemplate_answer
# 問卷範例
#       a. 第一題
#       - 題目為複選，但若使用者填寫"沒意見"，則無法勾選其他選項
#       - 報告需排除今年看 NBA即時比分低於15天的使用者
#       b. 第三題
#       - 題目為單選
#       - 需排除今年6~9月看 MLB即時比分低於15天的使用者
#       註：問卷結果統計
# =================================================================================================

create table actionlog._actionlog_livescore engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201401 where uri like '%/livescore.php%' and userid <> '';

insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201402 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201403 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201404 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201405 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201406 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201407 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201408 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201409 where uri like '%/livescore.php%' and userid <> '';
insert ignore into actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_20141012 where uri like '%/livescore.php%' and userid <> '';

create table actionlog._actionlog_livescore_1 engine = myisam
select a.userid, a.uri, (case when (locate('&',a.p)=0) then a.p
                              else substr(a.p,1,locate('&',a.p)-1) end) as p, a.time, a.platform_type
from (
    SELECT userid, uri, substr(uri,locate('aid',uri)+4,length(uri)) as p, time, platform_type 
    FROM actionlog._actionlog_livescore) as a;

create table actionlog._actionlog_livescore_2 engine = myisam
SELECT userid, uri, (case when (p in ('1#','vescore.php')) then 1 else p end) as p, time, 
                    (case when (platform_type < 2) then 'desktop' else 'mobile' end) as platform 
FROM actionlog._actionlog_livescore_1;

create table actionlog._actionlog_livescore_watch_nba_day_count engine = myisam
select b.userid, count(b.d) as watch_nba_day_count
from (
    select a.userid, a.d, count(a.userid) as c
    from (
        SELECT userid, date(time) as d
        FROM actionlog._actionlog_livescore_2
        where p = 3) as a # NBA
    group by a.userid, a.d) as b
group by b.userid;

create table actionlog._actionlog_livescore_watch_mlb_day_count engine = myisam
select b.userid, count(b.d) as watch_mlb_day_count
from (
    select a.userid, a.d, count(a.userid) as c
    from (
        SELECT userid, date(time) as d
        FROM actionlog._actionlog_livescore_2
        where month(time) in (6,7,8,9) # 今年6~9月
        and p = 1) as a # MLB
    group by a.userid, a.d) as b
group by b.userid;

create table plsport_playsport._question_answer engine = myisam
SELECT userid, write_time as t, spend_minute as mins, question01 as q1, question02 as q2, question03 as q3, question04 as q4
FROM plsport_playsport.questionnaire_livescoretemplate_answer
order by write_time desc;

create table plsport_playsport._question_answer_1 engine = myisam
select c.userid, c.t, c.mins, c.q1, c.q2, c.q3, c.q4, c.watch_nba_day_count, d.watch_mlb_day_count
from (
    SELECT a.userid, a.t, a.mins, a.q1, a.q2, a.q3, a.q4, b.watch_nba_day_count
    FROM plsport_playsport._question_answer a left join actionlog._actionlog_livescore_watch_nba_day_count b on a.userid = b.userid) as c
    left join actionlog._actionlog_livescore_watch_mlb_day_count as d on c.userid = d.userid;

create table plsport_playsport._question_answer_2 engine = myisam
SELECT userid, t, mins, q1,
                       (case when (q1 like '%1%') then 1 else 0 end) as a1, 
                       (case when (q1 like '%2%') then 1 else 0 end) as a2,
                       (case when (q1 like '%3%') then 1 else 0 end) as a3,
                       (case when (q1 like '%4%') then 1 else 0 end) as a4,
                       (case when (q1 like '%5%') then 1 else 0 end) as a5,
                        q2, q3,
                       (case when (q3 like '%1%') then 1 else 0 end) as b1, 
                       (case when (q3 like '%2%') then 1 else 0 end) as b2, 
                       (case when (q3 like '%3%') then 1 else 0 end) as b3,
                       q4, watch_nba_day_count, watch_mlb_day_count 
FROM plsport_playsport._question_answer_1;

        update plsport_playsport._question_answer_2 SET q2 = TRIM(TRAILING '\\' FROM q2);
        update plsport_playsport._question_answer_2 SET q2 = TRIM(TRAILING ' ' FROM q2);
        update plsport_playsport._question_answer_2 set q2 = replace(q2, ' ','');
        update plsport_playsport._question_answer_2 set q2 = replace(q2, '\\','');
        update plsport_playsport._question_answer_2 set q2 = replace(q2, '\n','');
        update plsport_playsport._question_answer_2 set q2 = replace(q2, '\r','');
        update plsport_playsport._question_answer_2 set q2 = replace(q2, '\t','');
        update plsport_playsport._question_answer_2 set q4 = replace(q4, ' ','');
        update plsport_playsport._question_answer_2 set q4 = replace(q4, '\\','');
        update plsport_playsport._question_answer_2 set q4 = replace(q4, '\n','');
        update plsport_playsport._question_answer_2 set q4 = replace(q4, '\r','');
        update plsport_playsport._question_answer_2 set q4 = replace(q4, '\t','');

# 整理後的問券
    select 'userid', 't', 'mins', 'q1', 'a1', 'a2', 'a3', 'a4', 'a5', 'q2', 'q3', 'b1', 'b2', 'b3', 'q4', 'nba', 'mlb' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_question_answer_2.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._question_answer_2);


# =================================================================================================
# 任務: [201409-C-1] 足球即時比分 - 使用者研究 [新建] 2014-10-17 (阿達)
# 
# 說明
#   研究站上足球使用者比例，作為足球即時比分開發排程依據
#   負責人：Eddy
#   時間：10/21 (二)
# 報告內容
#   時間：2014/9/7 ~ 10/4 (共四周)
#   統計項目：每週分別有多少比例的使用者瀏覽過足球、MLB、日棒討論區
# =================================================================================================

# 撈出討論區的log
create table actionlog._action_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201409
where substr(uri,1,6) = '/forum'
and userid <> '';

insert ignore into actionlog._action_forum 
SELECT userid, uri, time, platform_type
FROM actionlog.action_20141015
where substr(uri,1,6) = '/forum'
and userid <> '';

create table actionlog._action_forum_1 engine = myisam
SELECT userid, uri, time, platform_type as pf, 
       (case when (locate('allianceid',uri)=0) then '' else substr(uri,locate('allianceid',uri)+11,length(uri)) end) as alli
FROM actionlog._action_forum;

create table actionlog._action_forum_2 engine = myisam
SELECT userid, uri, time, pf, (case when (locate('&',alli)=0) then '' else substr(alli,1,locate('&',alli)-1) end) as alli
FROM actionlog._action_forum_1;

create table actionlog._action_forum_3 engine = myisam
SELECT userid, uri, time, pf, alli, 
       (case when (locate('subjectid=',uri)=0) then '' else substr(uri,locate('subjectid=',uri)+10,length(uri)) end) as subid
FROM actionlog._action_forum_2;

create table actionlog._action_forum_4 engine = myisam
SELECT userid, uri, time, pf, alli, (case when (locate('&',subid)=0) then '' else substr(subid,1,locate('&',subid)-1) end) as subid
FROM actionlog._action_forum_3;

create table plsport_playsport._forum_allianceid
SELECT subjectid, allianceid, postuser, posttime 
FROM plsport_playsport.forum
where year(posttime) = 2014
order by posttime desc;

        #要手動把subid格式換成char(30)
        ALTER TABLE actionlog._action_forum_4 ADD INDEX (`subid`);
        ALTER TABLE plsport_playsport._forum_allianceid ADD INDEX (`subjectid`);
        ALTER TABLE actionlog._action_forum_4 CHANGE `subid` `subid` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._forum_allianceid CHANGE `subjectid` `subjectid` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog._action_forum_5 engine = myisam
SELECT a.userid, a.uri, a.time, a.pf, a.alli, a.subid, b.allianceid
FROM actionlog._action_forum_4 a left join plsport_playsport._forum_allianceid b on a.subid = b.subjectid;

create table actionlog._action_forum_6 engine = myisam
SELECT userid, uri, time, pf, alli, subid, (case when (allianceid is null) then '' else allianceid end) as allianceid
FROM actionlog._action_forum_5;

create table actionlog._action_forum_7 engine = myisam
SELECT userid, uri, time, pf, alli, subid, allianceid, concat(alli,allianceid) as alli1 
FROM actionlog._action_forum_6;

create table actionlog._action_forum_8 engine = myisam
SELECT userid, uri, date(time) as d, pf, alli, subid, allianceid, alli1 
FROM actionlog._action_forum_7
where alli1 not in ('',0);

create table actionlog._action_forum_8_week1 engine = myisam
SELECT * FROM actionlog._action_forum_8 where d between '2014-09-07' and '2014-09-13';
create table actionlog._action_forum_8_week2 engine = myisam
SELECT * FROM actionlog._action_forum_8 where d between '2014-09-14' and '2014-09-20';
create table actionlog._action_forum_8_week3 engine = myisam
SELECT * FROM actionlog._action_forum_8 where d between '2014-09-21' and '2014-09-27';
create table actionlog._action_forum_8_week4 engine = myisam
SELECT * FROM actionlog._action_forum_8 where d between '2014-09-28' and '2014-10-04';
create table actionlog._action_forum_8_week5 engine = myisam
SELECT * FROM actionlog._action_forum_8 where d between '2014-10-05' and '2014-10-11';

# (1) 討論區總觀看使用者數
select count(a.userid) 
from (
    SELECT userid FROM actionlog._action_forum_8_week5 # 改week?
    group by userid) as a;

# (2) 特定看版觀看使用者數
select count(a.userid) 
from (
    SELECT userid FROM actionlog._action_forum_8_week5 # 改week?
    where alli1=91 # 改聯盟
    group by userid) as a;


# =================================================================================================
# 任務: 預測人數分析 [新建]
# 說明
# 分析預測人數降低的原因
# 負責人：Eddy
# 時間：10/22(三)
#  
# 分析內容
# 1. 手機、平板、電腦的預測轉換率
# 目的：了解是不是裝置影響預測意願
#  
# 2. 殺手人數
# 目的：了解有沒有因為預測人數降低，導致殺手人數變少
# 說明：比對2013,2014年的莊家殺手、單場殺手人數
# 時間：2013,2014/4~9
# 聯盟：MLB、日棒、中職、韓棒
# 盤口：國際、運彩盤
#  
# 3. 預測天數
# 目的：了解重度預測者的人數消長，判斷流失的預測者是否為重度預測者
# 說明：預測天數大於18天的使用者共有多少人，佔*總體預測者的比例
#          註：總體預測者為當月於該聯盟有預測的使用者
# 時間：2013,2014/7 ~9月
# 聯盟：MLB、日棒
# 盤口：國際盤
# 
# 4. 新舊會員比例
# 目的：判斷是否需改善新會員預測說明、挽救原重度預測者
# 說明：有預測的使用者中，加入會員的時間分布
# 時間：2014/7~9月
# 聯盟：全部
# 盤口：全部
# =================================================================================================

# 1.在GA就可以觀察
# 2.殺手人數
# 匯入medel_fire和single_killer

create table plsport_playsport._medal_fire engine = myisam
SELECT * FROM plsport_playsport.medal_fire
where allianceid in (1,2,6,9) # MLB、日棒、中職、韓棒
and vol > 81;

create table plsport_playsport._single_killer engine = myisam
SELECT * FROM plsport_playsport.single_killer
where allianceid in (1,2,6,9) # MLB、日棒、中職、韓棒
and vol > 27;

# <^^^^^^^^^^^^^^^^^^^^^^
# 不小心都刪掉了......QQ
# <vvvvvvvvvvvvvvvvvvvvvv

create table plsport_playsport._prediction_201405 engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth, createday 
FROM prediction.p_201405
where allianceid in (1,2);

create table plsport_playsport._prediction_201405_month engine = myisam
SELECT userid, allianceid, mode, createmonth
FROM plsport_playsport._prediction_201405
group by userid, allianceid, mode, createmonth;

SELECT allianceid, mode, createmonth, count(userid) as user_count 
FROM plsport_playsport._prediction_201405_month
group by allianceid, mode, createmonth;

create table plsport_playsport._prediction_201405_day engine = myisam
SELECT userid, allianceid, mode, createday 
FROM plsport_playsport._prediction_201405
group by userid, allianceid, mode, createday;

create table plsport_playsport._prediction_201405_day1 engine = myisam
SELECT userid, allianceid, mode, count(userid) as day_count 
FROM plsport_playsport._prediction_201405_day
group by userid, allianceid, mode;

SELECT allianceid, mode, count(userid) as user_count 
FROM plsport_playsport._prediction_201405_day1
where day_count>19
group by allianceid, mode;


# 4
create table plsport_playsport._prediction_mlb engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201402 where allianceid = 1;

insert ignore into plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201403 where allianceid = 1;
insert ignore into plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201404 where allianceid = 1;
insert ignore into plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201405 where allianceid = 1;
insert ignore into plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201406 where allianceid = 1;
insert ignore into plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201407 where allianceid = 1;
insert ignore into plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201408 where allianceid = 1;
insert ignore into plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201409 where allianceid = 1;

create table plsport_playsport._prediction_mlb_1 engine = myisam
SELECT userid, mode, m, min(d) as d 
FROM plsport_playsport._prediction_mlb
group by userid, mode, m;

SELECT mode, m, count(userid)  
FROM plsport_playsport._prediction_mlb_1
group by mode, m;

ALTER TABLE `_prediction_mlb_1` CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._prediction_mlb_2 engine = myisam
SELECT a.userid, a.mode, a.m, a.d, date(b.createon) as join_d
FROM plsport_playsport._prediction_mlb_1 a left join plsport_playsport.member b on a.userid = b.userid;

ALTER TABLE `_prediction_mlb_2` CHANGE `d` `d` DATE NULL DEFAULT NULL;

create table plsport_playsport._prediction_mlb_3 engine = myisam
SELECT userid, mode, m, d, join_d, round((datediff(d,join_d)/30),0) as dif
FROM plsport_playsport._prediction_mlb_2;


create table plsport_playsport._prediction_mlb_4 engine = myisam
SELECT userid, mode, m, (case when (dif<7) then '6'
                              when (dif<13) then '12'
                              when (dif<19) then '18'
                              when (dif<23) then '24'
                              when (dif<29) then '30'
                              when (dif<35) then '36' 
                              else '37' end) as dif
FROM plsport_playsport._prediction_mlb_3;

# 4-日棒
create table plsport_playsport._prediction_jpb engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201402 where allianceid = 2;

insert ignore into plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201403 where allianceid = 2;
insert ignore into plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201404 where allianceid = 2;
insert ignore into plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201405 where allianceid = 2;
insert ignore into plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201406 where allianceid = 2;
insert ignore into plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201407 where allianceid = 2;
insert ignore into plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201408 where allianceid = 2;
insert ignore into plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201409 where allianceid = 2;

create table plsport_playsport._prediction_jpb_1 engine = myisam
SELECT userid, mode, m, min(d) as d 
FROM plsport_playsport._prediction_jpb
group by userid, mode, m;

SELECT mode, m, count(userid)  
FROM plsport_playsport._prediction_jpb_1
group by mode, m;

ALTER TABLE `_prediction_jpb_1` CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._prediction_jpb_2 engine = myisam
SELECT a.userid, a.mode, a.m, a.d, date(b.createon) as join_d
FROM plsport_playsport._prediction_jpb_1 a left join plsport_playsport.member b on a.userid = b.userid;

ALTER TABLE `_prediction_jpb_2` CHANGE `d` `d` DATE NULL DEFAULT NULL;

create table plsport_playsport._prediction_jpb_3 engine = myisam
SELECT userid, mode, m, d, join_d, round((datediff(d,join_d)/30),0) as dif
FROM plsport_playsport._prediction_jpb_2;


create table plsport_playsport._prediction_jpb_4 engine = myisam
SELECT userid, mode, m, (case when (dif<7) then '6'
                              when (dif<13) then '12'
                              when (dif<19) then '18'
                              when (dif<23) then '24'
                              when (dif<29) then '30'
                              when (dif<35) then '36' 
                              else '37' end) as dif
FROM plsport_playsport._prediction_jpb_3;

SELECT m, mode, dif, count(userid) as user_count 
FROM plsport_playsport._prediction_jpb_4
group by m, mode, dif;


# 4-所有聯盟
create table plsport_playsport._prediction_all engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201402;

insert ignore into plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201403;
insert ignore into plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201404;
insert ignore into plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201405;
insert ignore into plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201406;
insert ignore into plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201407;
insert ignore into plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201408;
insert ignore into plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, createon, createmonth as m, createday as d 
FROM prediction.p_201409;

create table plsport_playsport._prediction_all_1 engine = myisam
SELECT userid, mode, m, min(d) as d 
FROM plsport_playsport._prediction_all
group by userid, mode, m;

SELECT mode, m, count(userid)  
FROM plsport_playsport._prediction_jpb_1
group by mode, m;

ALTER TABLE `_prediction_all_1` CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._prediction_all_2 engine = myisam
SELECT a.userid, a.mode, a.m, a.d, date(b.createon) as join_d
FROM plsport_playsport._prediction_all_1 a left join plsport_playsport.member b on a.userid = b.userid;

ALTER TABLE `_prediction_all_2` CHANGE `d` `d` DATE NULL DEFAULT NULL;

create table plsport_playsport._prediction_all_3 engine = myisam
SELECT userid, mode, m, d, join_d, round((datediff(d,join_d)/30),0) as dif
FROM plsport_playsport._prediction_all_2;


create table plsport_playsport._prediction_all_4 engine = myisam
SELECT userid, mode, m, (case when (dif<7) then '6'
                              when (dif<13) then '12'
                              when (dif<19) then '18'
                              when (dif<23) then '24'
                              when (dif<29) then '30'
                              when (dif<35) then '36' 
                              else '37' end) as dif
FROM plsport_playsport._prediction_all_3;

SELECT m, mode, dif, count(userid) as user_count 
FROM plsport_playsport._prediction_all_4
group by m, mode, dif;


# =================================================================================================
# 任務: VIP優惠成本損失估算 [新建]
# 煩請你協助估算，這些VIP得到這些優惠後，
# 
# 我們的成本會損失多少?
# 
# 有三個等級的VIP、中級與高級各有兩個版本。
# 
# 文件請看這。https://docs.google.com/a/playsport.cc/document/d/1M5v67mwETuInndUVzCyHC-35QoFuv-_SMuzwjZcZWMI/edit
# 
# 再麻煩你10/20告知結果!感謝!
# =================================================================================================

create table plsport_playsport._order_data_2014 engine = myisam
SELECT userid, createon, ordernumber, price, payway  
FROM plsport_playsport.order_data
where sellconfirm = 1
and payway in (1,2,3,4,5,6)
and year(createon) = 2014
order by id desc;

create table plsport_playsport._order_data_2014_1 engine = myisam
SELECT userid, createon, ordernumber, payway, price, 
       (case when (price < 229) then 199
             when (price < 804) then 699
             when (price < 1149) then 999 else price end) as raw_price
FROM plsport_playsport._order_data_2014;

create table plsport_playsport._user_total_paid_in_2014 engine = myisam
SELECT userid, sum(price) as total_paid 
FROM plsport_playsport._order_data_2014_1
group by userid;

        ALTER TABLE plsport_playsport._user_total_paid_in_2014 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._order_data_2014_1 ADD INDEX (`userid`);

create table plsport_playsport._order_data_2014_2 engine = myisam
SELECT a.userid, a.createon, a.ordernumber, a.payway, a.price, a.raw_price, b.total_paid  
FROM plsport_playsport._order_data_2014_1 a left join plsport_playsport._user_total_paid_in_2014 b on a.userid = b.userid;

create table plsport_playsport._order_data_2014_3 engine = myisam
SELECT userid, createon, ordernumber, payway, price, raw_price, total_paid, 
       (case when (total_paid > 99999) then 'svip'
             when (total_paid > 49999 and total_paid < 100000) then 'vvip'
             when (total_paid > 19999 and total_paid < 50000) then 'vip' else 'none' end) as lv
FROM plsport_playsport._order_data_2014_2;

create table plsport_playsport._order_data_2014_4 engine = myisam
SELECT * FROM plsport_playsport._order_data_2014_3
where lv <> 'none';

create table plsport_playsport._order_data_2014_5 engine = myisam
select a.userid, sum(a.p_199) as p_199, sum(a.p_699) as p_699, sum(a.p_999) as p_999, sum(a.p_1999) as p_1999,
                 sum(a.p_3999) as p_3999, sum(a.p_8888) as p_8888, sum(a.p_16888) as p_16888, a.lv
from (
    SELECT userid, createon, 
           (case when (raw_price = 199) then 1 else 0 end) as p_199,
           (case when (raw_price = 699) then 1 else 0 end) as p_699,
           (case when (raw_price = 999) then 1 else 0 end) as p_999,
           (case when (raw_price = 1999) then 1 else 0 end) as p_1999,
           (case when (raw_price = 3999) then 1 else 0 end) as p_3999,
           (case when (raw_price = 8888) then 1 else 0 end) as p_8888,
           (case when (raw_price = 16888) then 1 else 0 end) as p_16888, lv 
    FROM plsport_playsport._order_data_2014_4) as a
group by a.userid;

create table plsport_playsport._order_data_2014_6 engine = myisam
SELECT a.userid, a.p_199, a.p_699, a.p_999, a.p_1999, a.p_3999, a.p_8888, a.p_16888, a.lv, b.total_paid 
FROM plsport_playsport._order_data_2014_5 a left join plsport_playsport._user_total_paid_in_2014 b on a.userid = b.userid;

    # 輸出
    select 'userid', 'p_199', 'p_699', 'p_999', 'p_1999', 'p_3999', 'p_8888', 'p_16888', 'lv', 'total_paid' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_2014_6.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._order_data_2014_6);


# =================================================================================================
# 任務: [201410-A-1] NBA即時比分訪談 - 電訪名單 [新建] 2014-10-28 (阿達) 和6457的任務類似
# 撈使用者名單供電訪用
# 時間：
# 10/29  電訪名單
# 內容
# 1. 電訪名單
# 資料區間：10/5 ~ 10/25
# 條件：使用NBA即時比分網頁版 pv前50%使用者(註1)
# 欄位：帳號、暱稱、使用天數、NBA即時比分 pv及全站佔比(註2)、NHL即時比分 pv及全站佔比、手機/電腦使用比率
# 備註：
# 1.  前50%指的是跟全站使用者相比
# 2. 全站佔比指的是跟全站使用者相比
# =================================================================================================

create table actionlog._actionlog_livescore engine = myisam 
SELECT userid, uri, time, platform_type 
FROM actionlog.action_20141025
where date(time) between '2014-10-05' and '2014-10-25'
and uri like '%/livescore.php%'
and userid <> '';

create table actionlog._actionlog_livescore_1 engine = myisam
select a.userid, a.uri, (case when (locate('&',a.p)=0) then a.p
                              else substr(a.p,1,locate('&',a.p)-1) end) as p, a.time, a.platform_type
from (
    SELECT userid, uri, substr(uri,locate('aid',uri)+4,length(uri)) as p, time, platform_type 
    FROM actionlog._actionlog_livescore) as a;

create table actionlog._actionlog_livescore_2 engine = myisam
SELECT userid, uri, (case when (p in ('1#','vescore.php')) then 1 else p end) as p, time, 
                    (case when (platform_type < 2) then 'desktop' else 'mobile' end) as platform 
FROM actionlog._actionlog_livescore_1;

create table actionlog._actionlog_livescore_3 engine = myisam
SELECT a.userid, a.uri, b.alliancename, a.time, a.platform 
FROM actionlog._actionlog_livescore_2 a left join plsport_playsport.alliance b on a.p = b.allianceid;

# (1)看即時比分的天數
create table actionlog._actionlog_livescore_3_usage_daycount_all engine = myisam
select b.userid, count(b.d) as d_count_all
from (
    select a.userid, a.d, count(userid) as c
    from (
        SELECT userid, uri, alliancename as alli_name, date(time) as d, platform 
        FROM actionlog._actionlog_livescore_3) as a
    group by a.userid, a.d) as b
group by b.userid;

# (2)看即時比分的天數-NBA
create table actionlog._actionlog_livescore_3_usage_daycount_nba engine = myisam
select b.userid, count(b.d) as d_count_nba
from (
    select a.userid, a.d, count(a.userid ) as c
    from (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        where alliancename = 'NBA') as a
    group by a.userid, a.d) as b
group by b.userid;

# (3)看即時比分的天數-NHL冰球
create table actionlog._actionlog_livescore_3_usage_daycount_nhl engine = myisam
select b.userid, count(b.d) as d_count_nhl
from (
    select a.userid, a.d, count(a.userid) as c
    from (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        where alliancename = '冰球') as a
    group by a.userid, a.d) as b
group by b.userid;

# (4)使用裝置的比例
create table actionlog._actionlog_livescore_3_pv_precentage engine = myisam
select c.userid, c.desktop_pv, c.mobile_pv, round((c.desktop_pv/(c.desktop_pv+c.mobile_pv)),3) as desktop_p,
                                            round((c.mobile_pv/(c.desktop_pv+c.mobile_pv)),3) as mobile_p
from (
    select b.userid, sum(b.desktop_pv) as desktop_pv, sum(b.mobile_pv) as mobile_pv
    from (
        select a.userid, (case when (a.platform='desktop') then c else 0 end) as desktop_pv,
                         (case when (a.platform='mobile')  then c else 0 end) as mobile_pv
        from (
            SELECT userid, platform, count(userid) as c 
            FROM actionlog._actionlog_livescore_3
            group by userid, platform) as a) as b
    group by b.userid) as c;

create table actionlog._actionlog_livescore_3_nba_pv engine = myisam
SELECT userid, count(userid) as nba_pv
FROM actionlog._actionlog_livescore_3
where alliancename = 'NBA'
group by userid;

        ALTER TABLE `_actionlog_livescore_3_nba_pv` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog._actionlog_livescore_3_nhl_pv engine = myisam
SELECT userid, count(userid) as nhl_pv
FROM actionlog._actionlog_livescore_3
where alliancename = '冰球'
group by userid;

        ALTER TABLE `_actionlog_livescore_3_nhl_pv` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

use plsport_playsport;

# (1)
create table plsport_playsport._list_1 engine = myisam
SELECT c.userid, c.d_count_all, c.d_count_nba, d.d_count_nhl
from (
    SELECT a.userid, a.d_count_all, b.d_count_nba
    FROM actionlog._actionlog_livescore_3_usage_daycount_all a left join actionlog._actionlog_livescore_3_usage_daycount_nba b on a.userid = b.userid) as c
    left join actionlog._actionlog_livescore_3_usage_daycount_nhl as d on c.userid = d.userid;

        ALTER TABLE `_list_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

# (2)
create table plsport_playsport._list_2 engine = myisam
SELECT a.userid, b.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl 
FROM plsport_playsport._list_1 a left join plsport_playsport.member b on a.userid = b.userid;

        ALTER TABLE actionlog._actionlog_livescore_3_pv_precentage CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl, b.desktop_pv, b.mobile_pv, b.desktop_p, b.mobile_p
FROM plsport_playsport._list_2 a left join actionlog._actionlog_livescore_3_pv_precentage b on a.userid = b.userid;

create table plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl, b.nba_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p 
FROM plsport_playsport._list_3 a left join actionlog._actionlog_livescore_3_nba_pv b on a.userid = b.userid;

create table plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl, a.nba_pv, b.nhl_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p
FROM plsport_playsport._list_4 a left join actionlog._actionlog_livescore_3_nhl_pv b on a.userid = b.userid;

create table plsport_playsport._list_6 engine = myisam
SELECT * FROM plsport_playsport._list_5
where nba_pv is not null;

# 最後名單
    select 'userid', 'nickname', 'd_count_all', 'd_count_nba', 'd_count_nhl', 'nba_pv', 'nhl_pv', 'desktop_pv', 'mobile_pv', 'desktop_p', 'mobile_p' union (
    SELECT * 
    into outfile 'C:/Users/1-7_ASUS/Desktop/_list_6.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._list_6);


# =================================================================================================
# 任務: [201406-A-4] 個人預測頁左下欄位改成戰績 - MVP測試名單 [新建] 2014-10-29 (阿達)
# 提供此任務 MVP測試名單
# 負責人：Eddy
# 時間：
# 10/29(三) 初稿測試名單
# 內容
#  
# 1. 初稿測試名單
# a. 消費者
#    時間：近三個月
#    條件：1. 儲值金額前 50%  2. 點選個人戰績勝率頁pv前50%
#    欄位：帳號、暱稱、近三個月儲值金額、近三個月個人戰績勝率頁 pv
# b. 殺手
#    時間：2014年至今
#    條件：當過2次以上殺手
#    欄位：帳號、暱稱、2014年殺手次數、近三個月個人戰績勝率頁 pv
# =================================================================================================

# 先撈出戰績勝率頁的action_log
create table actionlog._visit_member_records_all engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201407 where uri like '%visit_member.php?action=records&type=all%' and userid <> '';

insert ignore into actionlog._visit_member_records_all SELECT userid, uri, time, platform_type 
FROM actionlog.action_201408 where uri like '%visit_member.php?action=records&type=all%' and userid <> '';
insert ignore into actionlog._visit_member_records_all SELECT userid, uri, time, platform_type 
FROM actionlog.action_201409 where uri like '%visit_member.php?action=records&type=all%' and userid <> '';
insert ignore into actionlog._visit_member_records_all SELECT userid, uri, time, platform_type 
FROM actionlog.action_20141025 where uri like '%visit_member.php?action=records&type=all%' and userid <> '';

create table actionlog._visit_member_records_all_in_three_month engine = myisam 
SELECT *
FROM actionlog._visit_member_records_all
where time between subdate(now(),95) and now(); # 近三個月

create table actionlog._visit_member_records_all_everyone_pv engine = myisam 
SELECT userid, count(userid) as record_pv 
FROM actionlog._visit_member_records_all_in_three_month
group by userid;

# 當莊殺次數
create table plsport_playsport._medal_fire_count engine = myisam
select a.userid, a.nickname, count(userid) as medal_fire_count
from (
    SELECT id, vol, userid, nickname, allianceid, alliancename, winpercentage, winearn 
    FROM plsport_playsport.medal_fire
    where vol > 107) as a # 莊殺108期(含)是2014年的期數
group by a.userid;

# 當單殺次數
create table plsport_playsport._single_killer_count engine = myisam
select a.userid, a.nickname, count(userid) as single_killer_count
from (
    SELECT * 
    FROM plsport_playsport.single_killer
    where vol > 39) as a # 單殺40期(含)之後是2014年的期數
group by a.userid;

# 近3個月的儲值
create table plsport_playsport._redeem_in_three_month engine = myisam
select a.userid, sum(a.price) as redeem_in_three_month
from (
    SELECT userid, createon, ordernumber, price, payway
    FROM plsport_playsport.order_data
    where sellconfirm = 1
    and payway in (1,2,3,4,5,6)
    and createon between subdate(now(),95) and now()) as a # 近三個月
group by a.userid;

# 最近一次登入
create table plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
group by userid;

# 1
create table plsport_playsport._list_1 engine = myisam
SELECT a.userid, b.nickname, a.record_pv 
FROM actionlog._visit_member_records_all_everyone_pv a left join plsport_playsport.member b on a.userid = b.userid;
# 2
create table plsport_playsport._list_2 engine = myisam
select c.userid, c.nickname, c.record_pv, c.medal_fire_count, d.single_killer_count
from (
    SELECT a.userid, a.nickname, a.record_pv, b.medal_fire_count
    FROM plsport_playsport._list_1 a left join plsport_playsport._medal_fire_count b on a.userid = b.userid) as c 
    left join plsport_playsport._single_killer_count as d on c.userid = d.userid;
# 3
create table plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.record_pv, a.medal_fire_count, a.single_killer_count, b.redeem_in_three_month  
FROM plsport_playsport._list_2 a left join plsport_playsport._redeem_in_three_month b on a.userid = b.userid;
# 4
create table plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.record_pv, a.medal_fire_count, a.single_killer_count, a.redeem_in_three_month, date(b.last_signin) as last_signin
FROM plsport_playsport._list_3 a left join plsport_playsport._last_signin b on a.userid = b.userid;

# 輸出txt
SELECT 'userid', 'nickname', 'record_pv', 'mdeal_fire', 'single_killer', 'redeem', 'last_signin' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_list_4.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_4);


# =================================================================================================
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3729&projectId=11
# 任務: [201407-B-4]強化討論區回文功能-手機回文介面ABtesting [新建]
# 手機回文abtesting 檢查 2014-10-31 (靜怡)
# 需匯入:
#   (1)member
#   (2)forumcontent
#   (3)abtesting_forum_reply_enhanced
# =================================================================================================
create table plsport_playsport._forumcontent engine = myisam
SELECT * FROM plsport_playsport.forumcontent
where articleid > 11200000;

        ALTER TABLE plsport_playsport._forumcontent ADD INDEX (`articleid`);
        ALTER TABLE plsport_playsport.abtesting_forum_reply_enhanced ADD INDEX (`articleid`);

create table plsport_playsport._forumcontent_with_post_method engine = myisam
SELECT a.articleid, a.subjectid, a.userid, a.contenttype, a.postdate, b.post_from
FROM plsport_playsport._forumcontent a left join plsport_playsport.abtesting_forum_reply_enhanced b on a.articleid = b.articleid
where post_from is not null
order by a.articleid;

create table plsport_playsport._forumcontent_with_post_method_1 engine = myisam
select (case when (c.g>10) then 'a' else 'b' end) as abtest, c.g, c.articleid, c.subjectid, c.userid, c.contenttype, c.postdate, c.post_from
from (
    SELECT (b.id%20)+1 as g, a.articleid, a.subjectid, a.userid, a.contenttype, a.postdate, a.post_from
    FROM plsport_playsport._forumcontent_with_post_method a left join plsport_playsport.member b on a.userid = b.userid) as c;

# 檢查
SELECT abtest, post_from, count(userid) as c 
FROM plsport_playsport._forumcontent_with_post_method_1
group by abtest, post_from;


# add new line test 1